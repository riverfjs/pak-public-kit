local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Timer = require("Utils.Timer")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local Enum = require("Data.Config.Enum")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local UMG_Battle_HPBar_C = _G.NRCViewBase:Extend("UMG_Battle_HPBar_C")
local nameColorBoundary = _G.DataConfigManager:GetPetGlobalConfig("pet_level_boundary").num

function UMG_Battle_HPBar_C:OnConstruct()
  self:OnActive()
end

function UMG_Battle_HPBar_C:OnActive()
  self.curHp = 0
  self.maxHp = 1
  self.battleManager = _G.BattleManager
  self.currentCatchBallValue = 0
  self.maxCatchBallValue = 10000
  self.hpLength = 235
  self.catchBallTimer = Timer()
  self.catchBallEnable = false
  self.energyBar = nil
  self.bResetLv = true
  self.catchBallId = 100002
  self.curBallCatchValue = 0
  self.bIsMimic = false
  self.currentPetType1 = 0
  self.currentPetType2 = 0
  self:AddListeners()
  self.attrChangeStarList1 = {
    self.Star1_1,
    self.Star2_1,
    self.Star3_1,
    self.Star4_1,
    self.Star5_1,
    self.Fx_Attr_light
  }
  self.attrChangeStarList2 = {
    self.Star1,
    self.Star2,
    self.Star3,
    self.Star4,
    self.Star5,
    self.Fx_Attr1_light
  }
  self.props = {}
  if self.AttrButton then
    self.AttrButton.OnClicked:Add(self, self.OnPetInfoShow)
  end
  self.Battle_Hp:ReceiveProps({
    AnimStateChangeCallbackOwner = self,
    AnimStateChangeCallback = self.HandleBattleHpAnimStateChange
  })
  self.TouchButton.OnClicked:Add(self, self.OnPetInfoShow)
end

function UMG_Battle_HPBar_C:WaitingRecycle()
  self.Battle_Hp:WaitingRecycle()
  self:RemoveListeners()
end

function UMG_Battle_HPBar_C:OnDestruct()
  if not self.battleManager then
    return
  end
  if self.battlePet then
    self.battlePet = nil
  end
  if self.catchBallTimer then
    self.catchBallTimer:Clear()
    self.catchBallTimer = nil
  end
  self.energyBar = nil
  self.battleManager = nil
  self.props = nil
  self:RemoveListeners()
end

function UMG_Battle_HPBar_C:ReceiveProps(props)
  self.props = props
end

function UMG_Battle_HPBar_C:CheckBattlePetIsDie()
  if not self.battlePet or not self.battlePet.card then
    return false
  end
  if self.bIsNone and not self:IsAnyAnimPerforming() then
    self.Battle_Hp:PlayerLeave()
    return true
  end
  return false
end

function UMG_Battle_HPBar_C:ClearTimer()
  self.Battle_Hp:ClearTimer()
  self.catchBallTimer:Clear()
end

function UMG_Battle_HPBar_C:AddListeners()
  if self.Btn_Buff then
    self.Btn_Buff.OnClicked:Add(self, self.OnBtnBuff)
  end
  BattleEventCenter:Bind(self, BattlePerformEvent.ChangeCatchThreshold, BattleEvent.PET_CATCH_CHANGED, BattleEvent.ROUND_START, BattleEvent.DIRECT_UPDATE_UI, BattleEvent.PET_TYPES_CHANGED, BattleEvent.PetSelectSkill, BattleEvent.LeaveSkillRound, BattleEvent.OnBallChanged, BattlePerformEvent.FinalBattleNameVisible, BattlePerformEvent.BuffTriggerOnHit, BattleEvent.MutationChange)
end

function UMG_Battle_HPBar_C:RemoveListeners()
  if self.Btn_Buff then
    self.Btn_Buff.OnClicked:Remove(self, self.OnBtnBuff)
  end
  if self.AttrButton then
    self.AttrButton.OnClicked:Remove(self, self.OnPetInfoShow)
  end
  BattleEventCenter:UnBind(self)
end

function UMG_Battle_HPBar_C:Tick(geometry, deltaTime)
  self.catchBallTimer:Update(deltaTime)
end

function UMG_Battle_HPBar_C:OnRoundStart()
  if self.battlePet then
    self:SetTypes()
  end
end

function UMG_Battle_HPBar_C:OnCatchChange(petId, threshold, bImmediate)
  if self.battlePet and petId == self.battlePet.guid then
    self:SetCatchBallValue(threshold, bImmediate, false)
  end
end

function UMG_Battle_HPBar_C:OnBattleEvent(eventName, ...)
  if eventName == BattlePerformEvent.ChangeCatchThreshold then
    local petId, resultValue = ...
    if self.battlePet and self.battlePet.guid == petId then
      self:SetCatchBallValue(resultValue, true, false)
    end
    return true
  elseif eventName == BattleEvent.PET_CATCH_CHANGED then
    self:OnCatchChange(...)
    return true
  elseif eventName == BattleEvent.ROUND_START then
    self:OnRoundStart()
    self:CheckBtnBuff()
    return true
  elseif eventName == BattleEvent.DIRECT_UPDATE_UI then
    local ignoreOptions = (...)
    if ignoreOptions and ignoreOptions.ignoreHp and self.battlePet and self.battlePet.guid and ignoreOptions.ignoreHp[self.battlePet.guid] then
      return true
    end
    self:OnRoundStart()
    return true
  elseif eventName == BattleEvent.PET_TYPES_CHANGED then
    self:OnTypesChange(...)
    return true
  elseif eventName == BattleEvent.PetSelectSkill then
    self:PetStartSkill(...)
    return true
  elseif eventName == BattleEvent.LeaveSkillRound then
    self:HideLight(...)
    return true
  elseif eventName == BattleEvent.OnBallChanged then
    self:SetCurSelectedBallId(...)
    return true
  elseif eventName == BattlePerformEvent.FinalBattleNameVisible then
    self:CheckFinalBattleNameVisible(...)
    self:RemoveFinalBattleNameUI()
    return true
  elseif eventName == BattlePerformEvent.BuffTriggerOnHit then
    local target_id, buff_type, buff_id = ...
    if self.battlePet and self.battlePet.guid == target_id then
      self:HandleBuffOnHit(target_id, buff_type)
    end
    return true
  elseif eventName == BattleEvent.MutationChange then
    self:HandleMutationChange(...)
  end
end

function UMG_Battle_HPBar_C:SetCurSelectedBallId(ballId)
  self.catchBallId = ballId
  local ballConf = _G.DataConfigManager:GetBallConf(ballId)
  if ballConf then
    local catchThreshold = math.min(10000, self.curBallCatchValue * ballConf.ball_prob / self.maxCatchBallValue)
    self:SetCatchBallValue(catchThreshold, false, true)
  end
end

function UMG_Battle_HPBar_C:OnBtnBuff()
  local buffId = BattleManager:GetBattleBuffId()
  if buffId then
    _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleBuffTips, buffId, self.battlePet)
  end
end

function UMG_Battle_HPBar_C:CheckBtnBuff()
  if not self.Btn_Buff then
    return
  end
  if not self.battlePet or self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return
  end
  local buffId = BattleManager:GetBattleBuffId()
  if buffId then
    self.Btn_Buff:SetVisibility(UE4.ESlateVisibility.Visible)
    local ruleConf = _G.DataConfigManager:GetBattleRuleConf(buffId)
    self.SkillIcon:SetPath(ruleConf.icon)
  else
    self.Btn_Buff:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_HPBar_C:CalLimitPos(widget)
  self.Battle_Hp:CalLimitPos(widget)
end

function UMG_Battle_HPBar_C:InitView(battlePet)
  if battlePet and not battlePet.destroyed then
    self.Battle_Hp:InitView(battlePet)
    self.bIsNone = false
    self.shouldHide = false
    self:SetPetInfo(battlePet, battlePet.card)
    self:ClearTimer()
    self:InitCatchBallLevel()
    if battlePet.card.petInfo and battlePet.card.petInfo.battle_inside_pet_info.catch_info then
      self:SetCatchBallValue(battlePet.card.petInfo.battle_inside_pet_info.catch_info.initial_threshold, true, false)
    end
  end
end

function UMG_Battle_HPBar_C:SetPetInfo(battlePet, card)
  self.battlePet = battlePet
  self.shouldPlayerLeave = false
  self.TxtLevel:SetText(string.format(LuaText.umg_petskilltemple2_1, card.lv))
  if battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    self:SetLvTextColor(card.lv)
  end
  self:DelayFrames(1, self.ResetLv, self)
  local txtLevelPos = self.TxtLevel.RenderTransform.Translation
  Log.Debug("UMG_Battle_HPBar_C txtLevelPos:", txtLevelPos)
  if self.battlePet.card.petState:GetMimic() then
    self.bIsMimic = true
    self.Unknown:SetRenderOpacity(1)
    self.TheElves_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.HeadIcon then
      self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.TxtPetName:SetText("???")
    self:SafeCall(self.CanvasPanel_130, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  elseif self.battlePet.card.petState:GetSurpriseBox() then
    self.Unknown:SetRenderOpacity(0)
    self.bIsMimic = false
    self:SetHeadIconMutation(card, true)
    self.TxtPetName:SetText(card.name)
    self.name = card.name
    self:SafeCall(self.CanvasPanel_130, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Unknown:SetRenderOpacity(0)
    self.bIsMimic = false
    self:SetHeadIconMutation(card, true)
    self.TxtPetName:SetText(card.name)
    self.name = card.name
    self:SafeCall(self.CanvasPanel_130, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:SetTypes()
  self:DisableCatchBallIcon()
  local PetData = self.battlePet.card.petInfo.battle_common_pet_info
  local gender = PetData.gender
  if 1 == gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 2 == gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateFinalBattleNameUI()
  self:ForceLayoutPrepass()
end

function UMG_Battle_HPBar_C:SetLvTextColor(petLv)
  local subLevel = 0
  local worldLevel = (_G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0) + 1
  if not _G.DataConfigManager:GetWorldLevelConf(worldLevel) then
    return
  end
  local pet_level_limit = _G.DataConfigManager:GetWorldLevelConf(worldLevel).pet_level_limit
  subLevel = petLv - pet_level_limit
  if subLevel > nameColorBoundary then
    local fColor = UE4.UNRCStatics.HexToSlateColor("#c12a2a")
    self.TxtLevel:SetColorAndOpacity(fColor)
  elseif subLevel > 0 and subLevel <= nameColorBoundary then
    local fColor = UE4.UNRCStatics.HexToSlateColor("#e77d00")
    self.TxtLevel:SetColorAndOpacity(fColor)
  else
    local fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
    self.TxtLevel:SetColorAndOpacity(fColor)
  end
end

function UMG_Battle_HPBar_C:SwitchToNormalBattle()
  self.Battle_Hp:SwitchToNormalBattle(false)
end

function UMG_Battle_HPBar_C:SwitchToLeaderBattle()
  self.Battle_Hp:SwitchToLeaderBattle(true)
end

function UMG_Battle_HPBar_C:ResetLv()
  if self.Visibility ~= UE4.ESlateVisibility.Collapsed and self.TxtLevel and self.LevelBG then
    self.bResetLv = false
    local sizeX = self.TxtLevel:GetDesiredSize().X * 4
    local vec = self.LevelBG:GetDesiredSize()
    if sizeX > vec.X then
      local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.LevelBG)
      vec.X = sizeX
      slot:SetSize(vec)
    end
  else
    self.bResetLv = true
  end
end

function UMG_Battle_HPBar_C:AssignEnergyBar(energyBar)
  self.energyBar = energyBar
  self.Battle_Hp:AssignEnergyBar(energyBar)
end

function UMG_Battle_HPBar_C:RefreshHp()
  self.Battle_Hp:RefreshHp()
end

function UMG_Battle_HPBar_C:InitCatchBallLevel()
  local catchBallLevel = self.battlePet.card.petInfo.battle_common_pet_info.conf_id
  local catchInfo = _G.DataConfigManager:GetMonsterCatchConf(catchBallLevel, true)
  if catchInfo then
    self:SetCatchBallLevel(catchInfo.Catch_Ball_level)
  end
end

function UMG_Battle_HPBar_C:SetCatchBallLevel(catchBallLevel)
  self.CatchBallIcon:SetCatchBallLevel(catchBallLevel)
end

function UMG_Battle_HPBar_C:Show(visibility)
  self.shouldHide = false
  self:SetVisibility(visibility)
  if not self.bFirstShow then
    self.bFirstShow = true
    self.CatchBallIcon:TurnToShining(true)
    if self.battlePet and self.battlePet.card.petInfo.battle_inside_pet_info.catch_info then
      self:SetCatchBallValue(self.battlePet.card.petInfo.battle_inside_pet_info.catch_info.threshold or 0, false, false)
    end
    self.catchBallTimer:After(1.0, function()
      self:UpdateCatchBall(false, self.curHp / self.maxHp)
    end)
  end
  if self.bResetLv then
    self:DelayFrames(1, self.ResetLv, self)
  end
  if self.bIsLight then
    self:PlayAnimation(self.BigAndLight)
  end
  self.Battle_Hp:InitNightMareHPUI()
end

function UMG_Battle_HPBar_C:SetCatchBallValue(threshold, bImmediate, bChangeBall)
  if not self.catchBallEnable then
    return
  end
  if not threshold then
    Log.Warning("Wrong Param for CatchBall")
    return
  end
  local targetValue = threshold
  if targetValue == self.currentCatchBallValue then
    return
  end
  local targetPercent = targetValue / self.maxCatchBallValue
  local currentPercent = self.currentCatchBallValue / self.maxCatchBallValue
  if false == bChangeBall then
    self.curBallCatchValue = targetValue
  end
  if bImmediate then
    self.CatchBallIcon.Slot:SetPosition(UE4.FVector2D(self.hpLength * targetPercent, 0))
    self.currentCatchBallValue = targetValue
    self:UpdateCatchBall(bImmediate, self.curHp / self.maxHp)
  else
    local newData = {percent = currentPercent}
    self.CatchBallIcon:TurnToShining(false)
    self.bFirstShow = true
    self.catchBallTimer:Tween(1, newData, {percent = targetPercent}, "out-quart")
    self.catchBallTimer:During(1, function()
      self.CatchBallIcon.Slot:SetPosition(UE4.FVector2D(self.hpLength * newData.percent, 0))
      self.currentCatchBallValue = newData.percent * self.maxCatchBallValue
    end, function()
      self.CatchBallIcon.Slot:SetPosition(UE4.FVector2D(self.hpLength * targetPercent, 0))
      self.currentCatchBallValue = targetValue
      self:UpdateCatchBall(bImmediate, self.curHp / self.maxHp)
    end)
  end
end

function UMG_Battle_HPBar_C:UpdateCatchBall(bImmediate, newPercent)
  if not self.catchBallEnable then
    return
  end
  local catchBallPercent = self.currentCatchBallValue / self.maxCatchBallValue
  if newPercent > catchBallPercent then
    self.CatchBallIcon:TurnToNormal(bImmediate)
  else
    self.CatchBallIcon:TurnToShining(bImmediate)
  end
end

function UMG_Battle_HPBar_C:EnableCatchBallIcon()
  self.CatchBallIcon:SetVisibility(UE4.ESlateVisibility.Visible)
  self.catchBallEnable = true
end

function UMG_Battle_HPBar_C:DisableCatchBallIcon()
  self.CatchBallIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.catchBallEnable = false
end

function UMG_Battle_HPBar_C:OnTypesChange(guid)
  if self.battlePet and self.battlePet.guid == guid then
    self:SetTypes()
  end
end

function UMG_Battle_HPBar_C:PetStartSkill(pet)
  if not self.battleManager then
    return
  end
  if self.battleManager.battleRuntimeData:GetSubBattleType() == BattleEnum.SubBattleType.Single then
    self:HideLight()
    return
  end
  if self.battlePet and self.battlePet == pet then
    if not self.bIsLight then
      self.bIsLight = true
      self:PlayAnimation(self.BigAndLight)
    end
  else
    self:HideLight()
  end
end

function UMG_Battle_HPBar_C:HideLight()
  self.bIsLight = false
  if self:IsAnimationPlaying(self.Vloop) then
    self:StopAnimation(self.Vloop)
    self:PlayAnimation(self.Vclose)
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Battle_HPBar_C:OpenPetTips()
  local base_conf_id
  if self.battlePet and self.battlePet.card and self.battlePet.card.petBaseConf then
    base_conf_id = self.battlePet.card.petBaseConf.id
  end
  local extra_sdt
  if self.battlePet and self.battlePet.card and self.battlePet.card.petInfo and self.battlePet.card.petInfo.battle_inside_pet_info then
    extra_sdt = self.battlePet.card.petInfo.battle_inside_pet_info.extra_sdt
  end
  if self.battlePet and self.battlePet.card and base_conf_id and extra_sdt then
    local data = {
      cardData = self.battlePet.card,
      petData = {base_conf_id = base_conf_id, extra_sdt = extra_sdt}
    }
    _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleChangePetConfirmPanel, data)
  else
    Log.Warning("UMG_Battle_HPBar_C:OnPetInfoShow battlepet is invalid")
  end
end

function UMG_Battle_HPBar_C:SetTypes()
  local card = self.battlePet.card
  local IsSurpriseBox
  if card.petState then
    IsSurpriseBox = card.petState:GetSurpriseBox()
  end
  if BattleUtils.IsPartialShow(card) or IsSurpriseBox then
    self.Attr1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.PetTypeBg1 and self.PetTypeBg2 then
      self.PetTypeBg1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    local petTypes = card:GetPetType()
    if petTypes then
      for i = 1, 6 do
        local petType = petTypes[i]
        if petType and petType > 0 then
          local conf = _G.DataConfigManager:GetTypeDictionary(petType)
          if i <= #petTypes and petType > 1 and conf then
            self["Attr" .. i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            if self["PetTypeBg" .. i] then
              self["PetTypeBg" .. i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            end
            local iconPath = conf.type_icon
            self["Attr" .. i]:SetPath(iconPath)
          else
            self["Attr" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
            if self["PetTypeBg" .. i] then
              self["PetTypeBg" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
            end
          end
          self:PlayAttrChangeAnimation(i, petType)
        end
      end
    else
      if card.petBaseConf.unit_type[1] then
        self.Attr1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if self.PetTypeBg1 and self.PetTypeBg2 then
          self.PetTypeBg1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        local iconPath = _G.DataConfigManager:GetTypeDictionary(card.petBaseConf.unit_type[1]).type_icon
        self.Attr1:SetPath(iconPath)
      else
        self.Attr1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if self.PetTypeBg1 then
          self.PetTypeBg1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      if card.petBaseConf.unit_type[2] then
        self.Attr2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if self.PetTypeBg2 then
          self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        local iconPath = _G.DataConfigManager:GetTypeDictionary(card.petBaseConf.unit_type[2]).type_icon
        self.Attr2:SetPath(iconPath)
      else
        self.Attr2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if self.PetTypeBg2 then
          self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      self:PlayAttrChangeAnimation(1, card.petBaseConf.unit_type[1])
      self:PlayAttrChangeAnimation(2, card.petBaseConf.unit_type[2])
      self.Attr3:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Attr4:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Attr5:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Attr6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_HPBar_C:PlayerLeave(isPlayerLeaveGame)
  self.shouldPlayerLeave = true
  if isPlayerLeaveGame and self.Battle_Hp.StopAndCancelAllSetHpContext then
    self.Battle_Hp:StopAndCancelAllSetHpContext()
    self.battlePet = nil
    self.Battle_Hp:PlayerLeave()
    return
  end
  self:UpdatePlayerLeave()
end

function UMG_Battle_HPBar_C:UpdatePlayerLeave()
  if self.shouldPlayerLeave and not self:IsAnyAnimPerforming() then
    self.battlePet = nil
    self.Battle_Hp:PlayerLeave()
  end
end

function UMG_Battle_HPBar_C:PetNone()
  self.bIsNone = true
  self:DisableCatchBallIcon()
end

function UMG_Battle_HPBar_C:OnAnimationFinished(Animation)
  if Animation == self.BigAndLight then
    if self.bIsLight then
      self:PlayAnimation(self.Vloop, 0, 0)
    end
  elseif Animation == self.Vclose and not self.bIsLight then
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Battle_HPBar_C:IsShowHP(pet)
  return pet.teamEnm ~= BattleEnum.Team.ENUM_ENEMY or BattleConst.DebugFlags.ShowPetHP
end

function UMG_Battle_HPBar_C:OnPetInfoShow()
  if self.battlePet then
    local data = {
      cardData = self.battlePet.card,
      petData = {
        base_conf_id = self.battlePet.card.petBaseConf.id,
        extra_sdt = self.battlePet.card.petInfo.battle_inside_pet_info.extra_sdt
      }
    }
    _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleChangePetConfirmPanel, data)
  else
    Log.Warning("UMG_Battle_HPBar_C:OnPetInfoShow battlepet is invalid")
  end
end

function UMG_Battle_HPBar_C:OnPetInfoUpdate()
  if self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.UpdateChangePetConfirm3, self.battlePet.card)
  else
    NRCModuleManager:DoCmd(BattleUIModuleCmd.UpdateChangePetConfirm, self.battlePet.card)
  end
end

function UMG_Battle_HPBar_C:OnPetInfoClose()
  if not self.battlePet then
    return
  end
  if self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.HideChangePetConfirm3, true, true)
  else
    NRCModuleManager:DoCmd(BattleUIModuleCmd.HideChangePetConfirm, true, true)
  end
end

function UMG_Battle_HPBar_C:RemoveFinalBattleNameUI()
  if not BattleUtils.IsFinalBattle() then
    return
  end
  local show = false
  if self.battlePet and self.battlePet.buffComponent then
    local buffs = self.battlePet.buffComponent.buffs
    if buffs then
      for i, buff in ipairs(buffs) do
        if BuffUtils.IsNameInvisibleBuff(buff.id) and buff.stack > 0 then
          self.TxtPetName:SetRenderOpacity(0)
          show = true
          self.battlePet.card.isNameVisible = false
        end
      end
    end
  end
  if false == show then
    self.TxtPetName:SetRenderOpacity(1)
  end
end

function UMG_Battle_HPBar_C:UpdateFinalBattleNameUI()
  if not BattleUtils.IsFinalBattle() then
    return
  end
  local show = false
  if self.battlePet and self.battlePet.buffComponent then
    local buffs = self.battlePet.buffComponent.buffs
    if buffs then
      for i, buff in ipairs(buffs) do
        if BuffUtils.IsNameInvisibleBuff(buff.id) and buff.stack > 0 then
          self.TxtPetName:SetRenderOpacity(0)
          if self.NameMask then
            self.NameMask:LoadPanel(nil, self.name, true)
          end
          show = true
          self.battlePet.card.isNameVisible = false
        end
      end
    end
  end
  if false == show then
    self.TxtPetName:SetRenderOpacity(1)
    if self.NameMask then
      self.NameMask:UnLoadPanel(false)
    end
  end
end

function UMG_Battle_HPBar_C:CheckFinalBattleNameVisible(petID)
  if self.battlePet and petID == self.battlePet.guid then
    if self.NameMask then
      local panel = self.NameMask:GetPanel()
      if panel then
        panel:NameVisible()
      end
    end
    self.battlePet.card.isNameVisible = true
  end
end

function UMG_Battle_HPBar_C:PlayAttrChangeAnimation(index, currentValue)
  local previousValue = self["currentPetType" .. index]
  previousValue = previousValue or 0
  currentValue = currentValue or 0
  if currentValue > 1 and previousValue ~= currentValue then
    local type = currentValue
    local colorHex = BattleConst.DamageTypeColor[type]
    if 1 == index then
      for i, star in ipairs(self.attrChangeStarList1) do
        star.Brush.TintColor = UE4.UNRCStatics.HexToSlateColor(colorHex)
      end
      self:PlayAnimation(self.Attr_change)
    end
    if 2 == index then
      for i, star in ipairs(self.attrChangeStarList2) do
        star.Brush.TintColor = UE4.UNRCStatics.HexToSlateColor(colorHex)
      end
      self:PlayAnimation(self.Attr1_change)
    end
  end
  self["currentPetType" .. index] = currentValue
end

function UMG_Battle_HPBar_C:HandleBuffOnHit(petId, buff_type)
  if buff_type == Enum.BuffType.BFT_O_TWEENTYSEVEN then
    self:PlayAnimation(self.Buff_hp)
  end
  if buff_type == Enum.BuffType.BFT_O_TWEENTYEIGHT then
    if self.Headicon_buff then
      self.Headicon_buff:SetPath(self.headIconPath)
    end
    self:PlayAnimation(self.Buff_head)
  end
end

function UMG_Battle_HPBar_C:DelayHide()
  self:CancelDelayHide()
  self:DelaySeconds(2, self.HideSelf, self)
end

function UMG_Battle_HPBar_C:CancelDelayHide()
  self:CancelDelayByFunc(self.HideSelf)
end

function UMG_Battle_HPBar_C:HideSelf()
  if UE.UObject.IsValid(self) then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_HPBar_C:TryHide()
  self.shouldHide = true
  self:UpdateHide()
end

function UMG_Battle_HPBar_C:UpdateHide()
  if self.shouldHide and not self:IsAnyAnimPerforming() and UE.UObject.IsValid(self) then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_HPBar_C:IsAnyAnimPerforming()
  local isMainWindowIsPlayCloseInfo = false
  local mainWindow = self.props and self.props.mainWindow
  if UE.UObject.IsValid(mainWindow) then
    isMainWindowIsPlayCloseInfo = mainWindow:IsAnimationPlaying(mainWindow.closeInfo)
  end
  return self.Battle_Hp:IsPerformingAnim() or isMainWindowIsPlayCloseInfo
end

function UMG_Battle_HPBar_C:HandleBattleHpAnimStateChange()
  self:CheckBattlePetIsDie()
  self:UpdateHide()
  self:UpdatePlayerLeave()
end

function UMG_Battle_HPBar_C:SetHeadIconMutation(card, forceShow)
  if forceShow then
    self.TheElves_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.HeadIcon then
      self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  local uiParam = self.TheElves_1:PrepareUIParam(card.petInfo.battle_inside_pet_info)
  if self.HeadIcon then
    local flag
    flag, self.headIconPath = self.HeadIcon:SetIconPathAndMaterial(card.petBaseConf.id, card.petInfo.battle_common_pet_info.mutation_type, card.petInfo.battle_common_pet_info.glass_info, nil, uiParam)
  end
  self.TheElves_1:SetIconPathAndMaterial(card.petBaseConf.id, card.petInfo.battle_common_pet_info.mutation_type, card.petInfo.battle_common_pet_info.glass_info, nil, uiParam)
end

function UMG_Battle_HPBar_C:HandleMutationChange(base_conf_id)
  if self.battlePet and self.battlePet.card and self.battlePet.card.petBaseConf and base_conf_id == self.battlePet.card.petBaseConf.id then
    local card = self.battlePet.card
    self:SetHeadIconMutation(card)
  end
end

return UMG_Battle_HPBar_C
