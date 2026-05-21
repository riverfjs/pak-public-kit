local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local BattleClientBranchActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleClientBranchActionBase")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local Base = BattleClientBranchActionBase
local BattlePVPShowResultUI = Base:Extend("BattlePVPShowResultUI")

function BattlePVPShowResultUI:Ctor(...)
  Base.Ctor(self, ...)
  self.module = _G.NRCModuleManager:GetModule("BattleUIModule")
end

function BattlePVPShowResultUI:OnEnter()
  if BattleUtils.IsLeaderChallenge() or BattleUtils.IsNpcChallenge() then
    self:Finish()
    return
  end
  self.LoadSkillOver = nil
  self.skillOver = false
  self.BattleManager = _G.BattleManager
  self.fsm:Pause()
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for _, v in pairs(pets) do
    v:HidePet()
  end
  for i, battleNpc in ipairs(_G.BattleManager.battlePawnManager.battleNpcList) do
    battleNpc:HideNpc()
  end
  BattleUtils.HideAllPlayerChatBubbles()
  self.WinPlayer = self.BattleManager.battlePawnManager.EnemyPlayer
  self.LosePlayer = self.BattleManager.battlePawnManager.TeamatePlayer
  if self.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin() then
    self.WinPlayer = self.BattleManager.battlePawnManager.TeamatePlayer
    self.LosePlayer = self.BattleManager.battlePawnManager.EnemyPlayer
  end
  if not self.WinPlayer or not self.LosePlayer then
    self:CloseResult()
    return
  end
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBuffInfo)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ClosePVPValueNumberPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OnShowBatleResult)
  _G.BattleEventCenter:Bind(self, BattleEvent.CLICKED_Result_Close, BattleEvent.PET_SPAWNED)
  self.SkillComponent = self.BattleManager.vBattleField.battleFieldActor.Skill
  local LastHitBaseId = self.WinPlayer.FashionData.LastHitPetBaseId
  local LastHitGID = self.WinPlayer.FashionData.LastHitGID
  local LastHitPetCard = self.BattleManager.battlePawnManager:GetCardByCommonGuid(self.WinPlayer.teamEnm, LastHitGID)
  local skillPath
  local isTriggerSuit = false
  local preBaseId = -1
  if LastHitPetCard then
    preBaseId = LastHitPetCard.petBaseConf.id
    isTriggerSuit = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
    if not isTriggerSuit then
      if preBaseId ~= LastHitBaseId then
        LastHitPetCard:RefreshByBaseConf(LastHitBaseId)
      end
      isTriggerSuit = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
    else
      LastHitBaseId = preBaseId
    end
    skillPath = LastHitPetCard.AppearancePath:GetPVPOver()
  else
    skillPath, isTriggerSuit = self.WinPlayer.FashionData:GetPVPOver()
  end
  self.NeedWaitLoadPet = false
  if isTriggerSuit then
    self.winPet = _G.BattleManager.battlePawnManager:GetFirstPet(self.WinPlayer.teamEnm)
    local winCard
    if not self.winPet then
      winCard = LastHitPetCard or self.WinPlayer.deck.cards[1]
      if winCard then
        winCard.pos = 1
        winCard.posInField = 1
        self.NeedWaitLoadPet = true
      end
    elseif self.winPet.card.petBaseConf.id ~= LastHitBaseId then
      self.NeedWaitLoadPet = true
      winCard = self.winPet.card
      self.winPet:OnRecall()
    elseif LastHitGID == self.winPet.card.petInfo.battle_common_pet_info.gid and LastHitBaseId ~= preBaseId then
      self.NeedWaitLoadPet = true
      winCard = self.winPet.card
      self.winPet:OnRecall()
    end
    if self.NeedWaitLoadPet then
      winCard:RefreshByBaseConf(LastHitBaseId)
      winCard:SetInBattleField(true)
      self.winPet = BattleManager.battlePawnManager:PawnPet(self.WinPlayer.teamEnm, self.WinPlayer.team, winCard, self.WinPlayer, nil, true)
    end
  end
  self.skillResPath = skillPath
  self.loadedSkillResCount = 0
  self:LaunchAsyncTask(function(noUncheckedError, msgOrResult)
  end)
end

function BattlePVPShowResultUI:AsyncTask()
  a.wait(BattlePVPShowResultUI.LoadSkillTask(self))
  self.loadSkillTaskCallback = nil
  local status, res1, res2 = a.wait(BattlePVPShowResultUI.PlayOverSkillTask(self))
  local event, skill
  if status then
    event = res1
    skill = res2
  else
    local errorMessage = res1
    Log.Error("BattlePVPShowResultUI:AsyncTask PlayOverSkill error", errorMessage)
    return
  end
  self:OnSkillEnd(event, skill)
  if BattleUtils.IsReplayMode() then
    a.wait(au.DelaySeconds(3))
    _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
  end
end

local function LoadSkillTask(self, callback)
  self.loadSkillTaskCallback = callback
  BattleResourceManager:LoadClassAsync(self, self.skillResPath, self.OnSkillResLoaded, self.OnSkillFinish)
end

BattlePVPShowResultUI.LoadSkillTask = a.wrap(LoadSkillTask)

function BattlePVPShowResultUI:OnPawnNewPetFinish(pet)
  if self.winPet == pet then
    self.winPet:SetScale(1)
    self.winPet:HidePet()
    self.winPet:PinOnTheGround()
    self.NeedWaitLoadPet = false
    if self.LoadSkillClass and not self.NeedWaitLoadPet and self.loadSkillTaskCallback then
      self.loadSkillTaskCallback()
    end
  end
end

local function PlayOverSkillTask(self, callback)
  if not self.WinPlayer or not self.LosePlayer then
    callback(false, "WinPlayer or LosePlayer is nil")
    return
  end
  if not self.SkillComponent then
    callback(false, "SkillComponent is nil")
    return
  end
  local skillClass = self.LoadSkillClass
  if not skillClass then
    callback(false, string.format("Failed to load skill class %s", self.skillResPath))
    return
  end
  self.WinPlayer:ShowPlayer()
  self.LosePlayer:ShowPlayer()
  local skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  local Characters = self.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  if Characters[BattleConst.CharacterIndex.Player1] and Characters[BattleConst.CharacterIndex.Player1] ~= self.WinPlayer.model then
    for i = BattleConst.CharacterIndex.Player1, BattleConst.CharacterIndex.Player_Pet4 do
      local cache = Characters[i]
      Characters[i] = Characters[i + BattleConst.CharacterIndex.Player_Pet4 + 1]
      Characters[i + BattleConst.CharacterIndex.Player_Pet4 + 1] = cache
    end
  end
  if self.winPet then
    self.winPet:ShowPet(false)
    self.winPet:SetIKEnable(false)
    Characters[BattleConst.CharacterIndex.Player_Pet1] = self.winPet.model
    if self.winPet.model and self.winPet.model.mesh then
      self.winPet.model.mesh.BoundsScale = 20
      self.winPet.model.mesh.bNRCUseFixedSkelBounds = false
    end
    self.winPet.card.IgnoreAnimCheck = true
  end
  skill:RegisterEventCallback("End", nil, function(event, internalSkill)
    if self.winPet then
      self.winPet.card.IgnoreAnimCheck = false
    end
    callback(true, event, internalSkill)
  end)
  skill:RegisterEventCallback("PreEnd", nil, function(event, internalSkill)
    callback(true, event, internalSkill)
  end)
  local hasOpenUiEvent = _G.SkillUtils.SkillObjHasLuaEvent(skill, UE4.ERocoSkillLuaEventType.OpenUI)
  if not hasOpenUiEvent then
    self:OpenUI()
  end
  skill:RegisterEventCallback("Start", self, self.SkillStart)
  skill:RegisterEventCallback("OpenUI", self, self.OpenUI)
  skill:SetCharacters(Characters)
  skill.BattleGenderType = self.WinPlayer.roleInfo.base.sex
  skill:SetCaster(self.WinPlayer.model)
  if self.WinPlayer.model and self.WinPlayer.model.mesh then
    self.WinPlayer.model.mesh.BoundsScale = 20
    self.WinPlayer.model.mesh.bNRCUseFixedSkelBounds = false
  end
  if self.winPet then
    skill:SetTargets({
      self.winPet.model
    })
  else
    skill:SetTargets({
      self.LosePlayer.model
    })
  end
  self.SkillComponent:LoadAndPlaySkill(skill)
end

function BattlePVPShowResultUI:OpenUI()
  self.isOpenedUI = true
  if BattleUtils.IsPvp() then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattlePVPResultPanel, _G.BattleManager.battleRuntimeData.battleSettleData.data)
  elseif BattleUtils.IsNpcChallenge() then
    if _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin() then
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattlePVPResultPanel, _G.BattleManager.battleRuntimeData.battleSettleData.data)
    else
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenNpcBattleFailure, _G.BattleManager.battleRuntimeData.battleSettleData.data)
    end
  end
end

BattlePVPShowResultUI.PlayOverSkillTask = a.wrap(PlayOverSkillTask)

function BattlePVPShowResultUI:SkillStart(Event, Skill)
  if not self.active then
    Log.Debug("zgx BattlePVPShowResultUI is finished")
    return
  end
  self:AdjustPlayer()
  self:SafeDelayFrames("d_AdjustPlayer", 2, self.AdjustPlayer, self)
  self:SafeDelayFrames("d_InitCharacterMaskCamera", 2, self.InitUiMaskActors, self, Skill)
end

function BattlePVPShowResultUI:AdjustPlayer()
  if not self.active then
    return
  end
  if not self.WinPlayer or not self.LosePlayer then
    return
  end
  local player = self.WinPlayer.model
  local enemy = self.LosePlayer.model
  local player = {
    player or {},
    enemy or {}
  }
  for _, v in pairs(player) do
    if v and v.GetHalfHeight then
      local HalfHeight = v:GetHalfHeight()
      local pos = v:Abs_K2_GetActorLocation()
      if pos then
        local groundPoint = LineTraceUtils.GetPointValidLocationByLine(pos, HalfHeight) or pos
        local newLocation = UE4.FVector(groundPoint.X, groundPoint.Y, groundPoint.Z + HalfHeight)
        v:Abs_K2_SetActorLocation_WithoutHit(newLocation)
      end
    end
  end
end

function BattlePVPShowResultUI:InitUiMaskActors(skill)
  local Blackboard = UE.UObject.IsValid(skill) and skill:GetBlackboard()
  local winPlayer = self.WinPlayer
  local winPlayerModel = winPlayer and winPlayer.model
  local winPet = self.winPet
  local winPetModel = winPet and winPet.model
  local actorList = {}
  if UE.UObject.IsValid(winPlayerModel) then
    table.insert(actorList, winPlayerModel)
    local AvatarDecorator = winPlayerModel and winPlayerModel.AvatarDecorator
    if UE.UObject.IsValid(AvatarDecorator) then
      local decoratorArray = AvatarDecorator:GetDecorators()
      local decoratorList = decoratorArray:ToTable()
      for j, decorator in ipairs(decoratorList) do
        if UE.UObject.IsValid(decorator) then
          table.insert(actorList, decorator)
        end
      end
    end
  end
  if UE.UObject.IsValid(winPetModel) then
    table.insert(actorList, winPetModel)
  end
  if UE.UObject.IsValid(Blackboard) then
    local pvpShowResultUiSkillActorBlackboardKeyList = BattleConst and BattleConst.PvpShowResultUiSkillActorBlackboardKeyList or {}
    for i, key in ipairs(pvpShowResultUiSkillActorBlackboardKeyList) do
      local object = Blackboard:GetValueAsObject(key)
      if UE.UObject.IsValid(object) and object:IsA(UE.AActor) then
        local actor = object
        table.insert(actorList, actor)
      end
    end
  end
  for i, actor in ipairs(actorList) do
    NPCLuaUtils.SetCustomDepth(actor, BattleConst.BattleVictoryUiMaskStencilValue)
  end
end

function BattlePVPShowResultUI:OnSkillEnd(Event, Skill)
  if not self.active then
    Log.Debug("zgx BattlePVPShowResultUI is finished")
    return
  end
  if not self.isOpenedUI then
    self:OpenUI()
  end
  self.skillOver = true
  local Blackboard = Skill:GetBlackboard()
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
end

function BattlePVPShowResultUI:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattlePVPShowResultUI:CloseResult()
  self.fsm:Resume()
  self:Finish()
end

function BattlePVPShowResultUI:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePVPResultPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseNpcBattleFailure)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePVPDanGradingPanel)
  self.BattleManager = nil
  self.SkillComponent = nil
  self.WinPlayer = nil
  self.LosePlayer = nil
  self.loadSkillTaskCallback = nil
end

function BattlePVPShowResultUI:OnSkillResLoaded(modelClass)
  self.LoadSkillClass = modelClass
  if not self.NeedWaitLoadPet and self.loadSkillTaskCallback then
    self.loadSkillTaskCallback()
  end
end

function BattlePVPShowResultUI:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.CLICKED_Result_Close then
    self:CloseResult()
    return true
  end
  if eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
  end
end

return BattlePVPShowResultUI
