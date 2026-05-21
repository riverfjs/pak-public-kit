local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Base = BattleActionBase
local BeastPlayEnterPerform = Base:Extend("BeastPlayEnterPerform")
FsmUtils.MergeMembers(Base, BeastPlayEnterPerform, {})
local SkillNameIndex = {
  FourClip = 1,
  CallOut = 2,
  ChangeCameraToBattle = 3
}

function BeastPlayEnterPerform:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientTurnPlayAction)
end

function BeastPlayEnterPerform:OnEnter()
  self.SkillObj = nil
  self.fourClipSkillOject = nil
  self.WillEnterCatch = false
  BattleManager:PlayBattleBGM()
  if BattleUtils.IsEnterCatchInTeamBattle() then
    self.WillEnterCatch = true
    self:Finish()
  else
    self:InitData()
    self:PlaySkill()
  end
end

function BeastPlayEnterPerform:InitData()
  self.EnterSkillState = 0
  self.Boss = _G.BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
end

function BeastPlayEnterPerform:ShowOrHideBattlePawn(isVisible)
  local pawnManager = _G.BattleManager.battlePawnManager
  for i, v in ipairs(pawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)) do
    if v.player and v.player.model then
      if isVisible then
        v.player:ShowPlayer()
      else
        v.player:HidePlayer()
      end
    end
    if #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          if isVisible then
            p:ShowPet()
          else
            p:HidePet()
          end
        end
      end
    end
  end
  for i, v in ipairs(pawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)) do
    if v.player and v.player.model then
      if isVisible then
        v.player:ShowPlayer()
      else
        v.player:HidePlayer()
      end
    end
    if #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          if isVisible then
            p:ShowPet()
          else
            p:HidePet()
          end
        end
      end
    end
  end
end

function BeastPlayEnterPerform:FourClipStart()
  local levelSequencePlayer = self.fsm:GetProperty("BeastLevelPlayer", nil)
  if levelSequencePlayer then
    levelSequencePlayer:Stop()
    self.fsm:SetProperty("BeastLevelPlayer", nil)
  end
  self:ShowOrHideBattlePawn(true)
end

function BeastPlayEnterPerform.DoGetLimitedScreenSizeRatio(screenSizeRatio)
  if RocoEnv.IS_EDITOR then
    return screenSizeRatio
  else
    local GNRCBorderHorizontalRatio = 2.39
    local GNRCBorderVerticalRatio = 0.75
    local limitedScreenSizeRatio = math.min(math.max(screenSizeRatio, 1 / GNRCBorderVerticalRatio), GNRCBorderHorizontalRatio)
    return limitedScreenSizeRatio
  end
end

function BeastPlayEnterPerform.GetViewportAdaptFactor()
  local size = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  local screenSize = size / scale
  local screenSizeRatio = screenSize.X / screenSize.Y
  local limitedScreenSizeRatio = BeastPlayEnterPerform.DoGetLimitedScreenSizeRatio(screenSizeRatio)
  local factor = limitedScreenSizeRatio * 1080 / 2340
  Log.DebugFormat("[rtSizeX] factor=%f, size.X=%f, size.Y=%f, scale=%f, screenSize.X=%f, screenSize.Y=%f, ratio(raw)=%f, ratio(limited)=%f", factor, size.X, size.Y, scale, screenSize.X, screenSize.Y, screenSizeRatio, limitedScreenSizeRatio)
  Log.DebugFormat("[rtSizeX] factor(raw)=%f", screenSizeRatio * 1080 / 2340)
  return factor
end

function BeastPlayEnterPerform.DoGetViewportRTSize(imageWidth)
  local size = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  local screenSize = size / scale
  local screenSizeRatio = screenSize.X / screenSize.Y
  local standardTUIRatio = 2.1666666666666665
  local rtSizeX = 0.25
  local limitedScreenSizeRatio = BeastPlayEnterPerform.DoGetLimitedScreenSizeRatio(screenSizeRatio)
  if standardTUIRatio <= limitedScreenSizeRatio then
    local screenX = limitedScreenSizeRatio * 1080
    rtSizeX = imageWidth / screenX
  else
    local screenY = 2340 / limitedScreenSizeRatio
    rtSizeX = imageWidth / (2340 * (1080 / screenY))
  end
  Log.DebugFormat("[rtSizeX] imageWidth=%f, size.X=%f, size.Y=%f, scale=%f, screenSize.X=%f, screenSize.Y=%f, ratio(raw)=%f, ratio(limited)=%f, rtSizeX=%f", imageWidth, size.X, size.Y, scale, screenSize.X, screenSize.Y, screenSizeRatio, limitedScreenSizeRatio, rtSizeX)
  return rtSizeX
end

function BeastPlayEnterPerform:InitEnterHud()
  self.FourEnterHud = self.fsm:GetProperty("BeastHud", nil)
  if not self.FourEnterHud or not UE4.UObject.IsValid(self.FourEnterHud) then
    Log.Error("zgx FourEnter is nil!!")
    self.fsm:SetProperty("BeastHud", nil)
    self.fsm:SetProperty("BeastHudRef", nil)
    return
  end
  self.fsm:SetProperty("BeastHud", nil)
  local ImageWidth = 580
  local FourImage = {
    self.FourEnterHud.ImageOne,
    self.FourEnterHud.ImageTwo,
    self.FourEnterHud.ImageThree,
    self.FourEnterHud.ImageFour
  }
  self.PlayerWidthRatio = {}
  if self.FourEnterHud then
    for _, v in ipairs(FourImage) do
      ImageWidth = v.Slot.LayoutData.Offsets.Right
      local rtSizeX = BeastPlayEnterPerform.DoGetViewportRTSize(ImageWidth)
      Log.Debug("[rtSizeX]", "index", _, "ImageWidth:", ImageWidth, "rtSizeX", rtSizeX)
      table.insert(self.PlayerWidthRatio, rtSizeX)
    end
  else
    self.PlayerWidthRatio = {
      0.25,
      0.25,
      0.25,
      0.25
    }
  end
  local teams = BattleManager.battlePawnManager.AllPlayerTeam
  local NameText = {
    self.FourEnterHud.TextNameOne,
    self.FourEnterHud.TextNameTwo,
    self.FourEnterHud.TextNameThree,
    self.FourEnterHud.TextNameFour
  }
  local TitleText = {
    self.FourEnterHud.TextPositionOne,
    self.FourEnterHud.TextPositionTwo,
    self.FourEnterHud.TextPositionThree,
    self.FourEnterHud.TextPositionFour
  }
  for i, v in ipairs(teams) do
    if NameText[i] and NameText[i].SetText then
      NameText[i]:SetText(v.player.roleInfo.base.name)
    else
      Log.Error("zgx NameText is nil!! index", i)
    end
    if TitleText[i] and TitleText[i].SetText then
      local text
      if v.player.roleInfo.role_addi_info.appearance_info then
        if v.player.roleInfo.role_addi_info.appearance_info.card_label_first_selected > 0 and v.player.roleInfo.role_addi_info.appearance_info.card_label_last_selected > 0 then
          local card_label_first_conf = _G.DataConfigManager:GetCardLabelConf(v.player.roleInfo.role_addi_info.appearance_info.card_label_first_selected)
          local card_label_last_conf = _G.DataConfigManager:GetCardLabelConf(v.player.roleInfo.role_addi_info.appearance_info.card_label_last_selected)
          if card_label_first_conf and card_label_last_conf then
            text = string.format("%s%s", card_label_first_conf.label_text, card_label_last_conf.label_text)
          end
        elseif v.player.roleInfo.role_addi_info.appearance_info.npc_title then
          text = v.player.roleInfo.role_addi_info.appearance_info.npc_title
        end
      end
      if text then
        TitleText[i]:SetText(text)
      else
        TitleText[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      Log.Error("lsr TitleText is nil!! index", i)
    end
  end
  self.FourEnterHud:AddToViewport()
  self.FourEnterHud:PlayAnimation(self.FourEnterHud.Start)
end

function BeastPlayEnterPerform:PlaySkill(name, skill)
  if not self.active then
    return
  end
  if self.EnterSkillState == SkillNameIndex.FourClip - 1 then
    self:SafeDelayFrames("d_CloseTransformLoadingUI", 2, function()
      NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
    end)
    self:InitEnterHud()
  end
  if not skill or skill == self.SkillObj then
    self.SkillObj = nil
    self.EnterSkillState = self.EnterSkillState + 1
    if self.EnterSkillState <= #BattleConst.TeamBeastEnterSkill then
      local TeamatePlayer = _G.BattleManager.battlePawnManager.TeamatePlayer
      if not TeamatePlayer or not TeamatePlayer.model then
        Log.Warning("There is no model in my player !!!")
        self:PlaySkill()
        return
      end
      local skillComponent = TeamatePlayer.model.RocoSkill
      if not skillComponent then
        Log.Warning("There is no RocoSkill in my player !!!")
        self:PlaySkill()
        return
      end
      local skillPath = BattleConst.TeamBeastEnterSkill[self.EnterSkillState]
      local MyCastObject = CastSkillObject.FromSkillResID(skillPath)
      if MyCastObject then
        MyCastObject:SetCallbackOwner(self)
        MyCastObject:SetCaster(TeamatePlayer.model)
        if self.EnterSkillState == SkillNameIndex.CallOut then
          MyCastObject:AddBlackStringValue("IsCommon", "IsCommon")
          MyCastObject:SetExtraEvents({
            ActionStart = self.RevertPlayer
          })
        elseif self.EnterSkillState == SkillNameIndex.FourClip then
          MyCastObject:SetExtraEvents({
            ActionStart = self.FourClipStart
          })
        end
        MyCastObject:SetTargetPets({
          self.Boss
        })
        MyCastObject:SetIsPassive(true)
        MyCastObject:SetCharacters(BattleManager.battlePawnManager:GetAllPawnActorForSkill())
        MyCastObject:SetCompleteCallback(self.PlaySkill)
        self:SetBallPathForCast(MyCastObject)
        local _, skill = BattleSkillManager:PrepareSkill(self.Boss, skillComponent, MyCastObject)
        if not skill then
          Log.WarningFormat("Can't find or load skill object %s %s", MyCastObject.ResID)
          self:PlaySkill()
          return
        end
        if self.EnterSkillState == SkillNameIndex.FourClip then
          self:AdaptFourScreen(skill)
          self.fourClipSkillOject = skill
        end
        self.SkillObj = skill
        skillComponent:PlaySkill(skill)
      else
        Log.Error("zgx res is vaild!!", skillPath)
        self:PlaySkill()
      end
    else
      self:Finish()
    end
  end
end

function BeastPlayEnterPerform:AdaptFourScreen(skill)
  local actions = skill:GetAllActions()
  local index = 1
  for i = 1, actions:Length() do
    local action = actions:Get(i)
    if action:IsA(UE4.URocoCameraCurveAction) and action.SceneCaptureSetting.bUseSceneCapture and action.SceneCaptureSetting.bUseViewportSize then
      if self.PlayerWidthRatio then
        action.SceneCaptureSetting.ViewportRTSize.X = self.PlayerWidthRatio[index] or 0.25
      else
        action.SceneCaptureSetting.ViewportRTSize.X = 0.25
      end
      index = index + 1
    end
  end
end

function BeastPlayEnterPerform:CloseFourEnterHud()
  if UE.UObject.IsValid(self.FourEnterHud) then
    self.FourEnterHud:RemoveFromViewport()
    self.FourEnterHud:Destruct()
    self.FourEnterHud = nil
    if self.fourClipSkillOject then
      local caster = self.fourClipSkillOject:GetCaster()
      if UE.UObject.IsValid(caster) and UE.UObject.IsValid(caster.RocoSkill) then
        caster.RocoSkill:CancelSkill(self.fourClipSkillOject, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
      self.fourClipSkillOject = nil
    end
  end
  self.fsm:SetProperty("BeastHudRef", nil)
  UE4Helper.SetEnableWorldRendering(true, true)
end

function BeastPlayEnterPerform:RevertPlayer(name, skill)
  self:CloseFourEnterHud()
  if BattleManager.vBattleField.battleCraneCamera then
    BattleManager.vBattleField.battleCraneCamera:ChangeToPlayerPet(0)
  end
  BattleUtils.ShowAndResetPlayer()
end

function BeastPlayEnterPerform:SetBallPathForCast(skill)
  local pets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  if #pets > 0 then
    local ballAddPath = {
      "None",
      "None",
      "None",
      "None"
    }
    local ballAddLinkActor = {}
    for i = 1, #pets do
      local petData = pets[i].card.petInfo.battle_common_pet_info
      ballAddPath[i] = BattleUtils.GetPetBallPath(petData)
      ballAddLinkActor[i] = pets[i].model
      local effectBlackboard = "Normal"
      if petData.ball_id and 0 ~= petData.ball_id then
        local BallConfig = _G.DataConfigManager:GetBallConf(petData.ball_id)
        if BallConfig then
          effectBlackboard = BallConfig.catch_effect_blackboard or "Normal"
        end
      end
      BattleUtils.SetParticleKeyForCastSkillObject(pets[i].model, skill, effectBlackboard)
      BattleUtils.SetParticleKeyForCastSkillObject(pets[i].model, skill, pets[i].card.medalBlackBoard)
      BattleUtils.SetParticleKeyForCastSkillObject(pets[i].player.model, skill, effectBlackboard)
    end
    skill:SetDynamicData({
      BallPath = "None",
      BallAdditionalPaths = ballAddPath,
      BallAddLinkActors = ballAddLinkActor
    })
  end
end

function BeastPlayEnterPerform:OnFinish()
  self.Boss = nil
  self.SkillObj = nil
  self.fourClipSkillOject = nil
  if not self.WillEnterCatch then
    NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
  end
  self:CloseFourEnterHud()
end

return BeastPlayEnterPerform
