local BattleActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleActionBase")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ActivityModuleCmd = require("NewRoco.Modules.System.Activity.ActivityModuleCmd")
local RocoSkillLuaCustomEvent = require("NewRoco.Utils.RocoSkillLuaCustomEvent")
local Base = BattleActionBase
local BattleTerritoryTrialShowResultUiAction = Base:Extend("BattleTerritoryTrialShowResultUiAction")

function BattleTerritoryTrialShowResultUiAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function BattleTerritoryTrialShowResultUiAction:OnEnter()
  if not BattleUtils.IsTerritoryTrialBattle() then
    self:Finish()
    return
  end
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
  self.ShowPlayer = self.BattleManager.battlePawnManager.TeamatePlayer
  local skillPath = BattleConst.TerritoryTrial.WinOver
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBuffInfo)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ClosePVPValueNumberPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OnShowBatleResult)
  _G.BattleEventCenter:Bind(self, BattleEvent.CLICKED_Result_Close, BattleEvent.OnSkillResLoaded, BattleEvent.TERRITORY_TRIAL_AGAIN)
  self.SkillComponent = self.BattleManager.vBattleField.battleFieldActor.Skill
  self.skillResList = {skillPath}
  self.loadedSkillResCount = 0
  self:LaunchAsyncTask(function(noUncheckedError, msgOrResult)
  end)
end

function BattleTerritoryTrialShowResultUiAction:AsyncTask()
  a.wait(BattleTerritoryTrialShowResultUiAction.LoadSkillTask(self))
  self.loadSkillTaskCallback = nil
  local status, messageOrEvent, skill = a.wait(BattleTerritoryTrialShowResultUiAction.PlayOverSkillTask(self))
  if not status then
    Log.Error("BattleTerritoryTrialShowResultUiAction:AsyncTask", messageOrEvent)
  end
  if BattleUtils.IsReplayMode() then
    a.wait(au.DelaySeconds(3))
    _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
  end
end

local function LoadSkillTask(self, callback)
  self.loadSkillTaskCallback = callback
  _G.BattleSkillManager:PreLoadRes(self.skillResList, true)
end

BattleTerritoryTrialShowResultUiAction.LoadSkillTask = a.wrap(LoadSkillTask)

local function PlayOverSkillTask(self, callback)
  if not self.ShowPlayer then
    callback(false, "ShowPlayer is nil")
    return
  end
  local skillPath = self.skillResList[1]
  local skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    callback(false, string.format("Failed to load skill class %s", skillPath))
    return
  end
  self.ShowPlayer:ShowPlayer()
  local skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  local Characters = {}
  Characters[BattleConst.CharacterIndex.Player1] = self.ShowPlayer.model
  skill:RegisterEventCallback("End", nil, function(event, internalSkill)
    callback(true, event, internalSkill)
    self:OnSkillEnd(event, internalSkill)
  end)
  skill:RegisterEventCallback("PreEnd", nil, function(event, internalSkill)
    callback(true, event, internalSkill)
    self:OnSkillEnd(event, internalSkill)
  end)
  skill:RegisterEventCallback("Start", self, function(event, internalSkill)
    self:SkillStart(event, internalSkill)
    callback(true, event, internalSkill)
  end)
  skill:RegisterEventCallback(RocoSkillLuaCustomEvent.StartFailed, self, function(event, internalSkill)
    callback(false, "skill start failed")
  end)
  skill:RegisterEventCallback(RocoSkillLuaCustomEvent.Interrupt, self, function(event, internalSkill)
    callback(false, "skill interrupt")
  end)
  local blackboard = skill:GetBlackboard()
  if blackboard and UE.UObject.IsValid(blackboard) then
    if self.ShowPlayer.roleInfo.base.sex == _G.ProtoEnum.ESexValue.SEX_MALE then
      blackboard:SetValueAsString("PC1", "PC1")
    else
      blackboard:SetValueAsString("PC2", "PC2")
    end
  end
  skill:SetCharacters(Characters)
  skill.BattleGenderType = self.ShowPlayer.roleInfo.base.sex
  skill:SetCaster(self.ShowPlayer.model)
  local skillStartResult = self.SkillComponent:PlaySkill(skill)
  if skillStartResult ~= UE.ESkillStartResult.Success then
    callback(false, "skill start result is not success")
  end
end

BattleTerritoryTrialShowResultUiAction.PlayOverSkillTask = a.wrap(PlayOverSkillTask)

function BattleTerritoryTrialShowResultUiAction:SkillStart(Event, Skill)
  self:AdjustPlayer()
  local battleRuntimeData = _G.BattleManager.battleRuntimeData
  local resultUiState = battleRuntimeData and battleRuntimeData.resultUiState
  local prevHighestScore = resultUiState and resultUiState.prevHighestTerritoryTrialScore
  local highestScore = BattleUtils.GetCurrentBattleTerritoryHighestScore()
  local runtimeData = _G.BattleManager.battleRuntimeData
  local battleSettleData = runtimeData and runtimeData.battleSettleData
  local finishNotify = battleSettleData and battleSettleData.data
  local settleInfo = finishNotify and finishNotify.settle_info
  local trialSettleInfo = settleInfo and settleInfo.trial_settle_info
  local props = {}
  props.isShow = true
  props.trialSettleInfo = trialSettleInfo
  props.prevHistoryMaxAward = prevHighestScore
  props.historyMaxAward = highestScore
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetTerritoryTrialSettlementResultState, props)
end

function BattleTerritoryTrialShowResultUiAction:AdjustPlayer()
  local player = self.ShowPlayer.model
  if player and player.GetHalfHeight then
    local HalfHeight = player:GetHalfHeight()
    local pos = player:Abs_K2_GetActorLocation()
    if pos then
      local groundPoint = LineTraceUtils.GetPointValidLocationByLine(pos, HalfHeight) or pos
      local newLocation = UE4.FVector(groundPoint.X, groundPoint.Y, groundPoint.Z + HalfHeight)
      player:Abs_K2_SetActorLocation_WithoutHit(newLocation)
    end
  end
end

function BattleTerritoryTrialShowResultUiAction:OnSkillEnd(Event, Skill)
  self.skillOver = true
  local Blackboard = Skill:GetBlackboard()
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
end

function BattleTerritoryTrialShowResultUiAction:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattleTerritoryTrialShowResultUiAction:CloseResult()
  self.fsm:Resume()
  self:Finish()
end

function BattleTerritoryTrialShowResultUiAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePVPResultPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseNpcBattleFailure)
  local props = {}
  props.isShow = false
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetTerritoryTrialSettlementResultState, props)
  self.BattleManager = nil
  self.SkillComponent = nil
  self.loadSkillTaskCallback = nil
end

function BattleTerritoryTrialShowResultUiAction:OnSkillResLoaded(eventName, resPath)
  for i = 1, #self.skillResList do
    if resPath == self.skillResList[i] then
      self.loadedSkillResCount = self.loadedSkillResCount + 1
    end
  end
  if self.loadedSkillResCount == #self.skillResList and self.loadSkillTaskCallback then
    self.loadSkillTaskCallback()
  end
end

function BattleTerritoryTrialShowResultUiAction:OnTryAgain()
  self.fsm:SendEvent(BattleEvent.EnterTerritoryTrialAgain)
  self:CloseResult()
end

function BattleTerritoryTrialShowResultUiAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.CLICKED_Result_Close then
    self.fsm:SendEvent(BattleEvent.EnterNormalOver)
    self:CloseResult()
    return true
  end
  if eventName == BattleEvent.TERRITORY_TRIAL_AGAIN then
    self:OnTryAgain()
    return true
  end
  if eventName == BattleEvent.OnSkillResLoaded then
    self:OnSkillResLoaded(eventName, ...)
    return true
  end
end

return BattleTerritoryTrialShowResultUiAction
