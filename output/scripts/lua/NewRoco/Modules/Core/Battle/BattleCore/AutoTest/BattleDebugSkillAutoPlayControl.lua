local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local BattleDebugSkillAutoPlayControl = NRCClass:Extend()
local Phase = {
  Idle = 0,
  StartPlay = 1,
  WaitCurrentBattleFinish = 2,
  EnterTestBattle = 3,
  InBattle = 4,
  TestOver = 5,
  WaitBattleOverEvent = 6,
  WaitBattleFinish = 7,
  Complete = 8
}
local BattleSubPhase = {
  WaitPrepareBattleOver = 1,
  RoundLoop = 2,
  SubComplete = 3
}

function BattleDebugSkillAutoPlayControl:Ctor()
  Log.Debug("BattleDebugSkillAutoPlayControl:Ctor")
  local battleManager = _G.BattleManager
  local battleRuntimeData = battleManager and battleManager.battleRuntimeData
  local battleDebugControl = battleRuntimeData and battleRuntimeData.battleDebugControl
  local BattleDebugControl = require("NewRoco.Modules.System.BattleUI.Res.BattleDebugger.BattleDebugControl")
  if not battleDebugControl then
    battleDebugControl = BattleDebugControl()
    if battleRuntimeData then
      battleRuntimeData.battleDebugControl = battleDebugControl
    end
  end
  self.battleDebugControl = battleDebugControl
  self.context = nil
  self.battleDebugControl:SetTestData()
  NRCEventCenter:RegisterEvent("BattleDebugSkillAutoPlayControl", self, TaskModuleEvent.BattleOver, self.OnLeaveBattle)
  _G.UpdateManager:Register(self)
end

function BattleDebugSkillAutoPlayControl:Dctor()
  Log.Debug("BattleDebugSkillAutoPlayControl:Dctor")
  self:Stop()
  _G.UpdateManager:UnRegister(self)
  _G.BattleEventCenter:UnBind(self)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.BattleOver, self.OnLeaveBattle)
end

function BattleDebugSkillAutoPlayControl:Enqueue(fileName)
  local context = self.context
  if not context then
    context = {
      phase = Phase.Idle,
      fileNameQueue = {},
      battleContext = nil,
      waitBattleFinishTimeoutDelayId = nil
    }
    self.context = context
  end
  local fileNameQueue = context.fileNameQueue or {}
  table.insert(fileNameQueue, fileName)
  Log.Debug(string.format("BattleDebugSkillAutoPlayControl:Enqueue fileName=%s, queueSize=%d", tostring(fileName), #fileNameQueue))
  self:TryStartNext()
end

function BattleDebugSkillAutoPlayControl:Stop()
  local context = self.context
  if not context then
    return
  end
  local battleContext = context and context.battleContext
  if battleContext then
    self:CancelBattleContextDelays(battleContext)
  end
  local waitDelayId = context and context.waitBattleFinishTimeoutDelayId
  if waitDelayId then
    _G.DelayManager:CancelDelayById(waitDelayId)
  end
  _G.BattleEventCenter:UnBind(self)
  self.context = nil
  Log.Debug("BattleDebugSkillAutoPlayControl:Stop \228\188\154\232\175\157\229\183\178\229\129\156\230\173\162")
end

function BattleDebugSkillAutoPlayControl:IsIdle()
  local context = self.context
  local phase = context and context.phase
  return nil == context or phase == Phase.Idle
end

function BattleDebugSkillAutoPlayControl:GetPendingCount()
  local context = self.context
  local fileNameQueue = context and context.fileNameQueue or {}
  return #fileNameQueue
end

function BattleDebugSkillAutoPlayControl:GetCurrentPhase()
  local context = self.context
  local phase = context and context.phase
  return phase
end

function BattleDebugSkillAutoPlayControl:GetCurrentFileName()
  local context = self.context
  local battleContext = context and context.battleContext
  local fileName = battleContext and battleContext.fileName
  return fileName
end

function BattleDebugSkillAutoPlayControl:TryStartNext()
  local context = self.context
  local phase = context and context.phase
  if phase ~= Phase.Idle then
    return
  end
  local fileNameQueue = context and context.fileNameQueue or {}
  if 0 == #fileNameQueue then
    return
  end
  context.phase = Phase.StartPlay
  self:HandleNextPhase(context)
end

function BattleDebugSkillAutoPlayControl:HandleNextPhase(context)
  local phase = context and context.phase
  if phase == Phase.Idle then
  elseif phase == Phase.StartPlay then
    self:HandleStartPlay(context)
  elseif phase == Phase.WaitCurrentBattleFinish then
  elseif phase == Phase.EnterTestBattle then
    self:HandleEnterTestBattle(context)
  elseif phase == Phase.InBattle then
  elseif phase == Phase.TestOver then
    self:HandleTestOver(context)
  elseif phase == Phase.WaitBattleOverEvent then
  elseif phase == Phase.WaitBattleFinish then
  elseif phase == Phase.Complete then
    self:HandleComplete(context)
  end
end

function BattleDebugSkillAutoPlayControl:HandleStartPlay(context)
  local phase = context and context.phase
  if not context or phase ~= Phase.StartPlay then
    return
  end
  local fileNameQueue = context.fileNameQueue or {}
  local fileName = table.remove(fileNameQueue, 1)
  local configData = BattleDebugSkillAutoPlayControl.LoadAutoPlayConfigFromSaved(fileName)
  Log.Debug(string.format("BattleDebugSkillAutoPlayControl:HandleStartPlay fileName=%s", tostring(fileName)))
  local battleContext = {
    fileName = fileName,
    configData = configData,
    subPhase = BattleSubPhase.WaitPrepareBattleOver,
    currentRoundIndex = 0,
    isPaused = false,
    isRoundPlaying = false,
    currentPlaySpeed = 1,
    replayExitDelayId = nil,
    playRoundDelayId = nil,
    addTeamPetDelayId = nil,
    ok = true,
    errorMessage = nil
  }
  context.battleContext = battleContext
  if not configData then
    battleContext.ok = false
    battleContext.errorMessage = string.format("BattleDebugSkillAutoPlayControl:HandleStartPlay configData is nil, fileName=%s", tostring(fileName))
    context.phase = Phase.Complete
    self:HandleNextPhase(context)
    return
  end
  local battleManager = _G.BattleManager
  local isInBattle = battleManager and battleManager:IsInBattle()
  if isInBattle then
    context.phase = Phase.WaitCurrentBattleFinish
  else
    context.phase = Phase.EnterTestBattle
  end
  self:HandleNextPhase(context)
end

function BattleDebugSkillAutoPlayControl:HandleEnterTestBattle(context)
  local phase = context and context.phase
  if not context or phase ~= Phase.EnterTestBattle then
    return
  end
  local battleContext = context.battleContext
  local enterBattleParam = self:GetEnterBattleParam(battleContext)
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_START, BattleEvent.PrepareBattleOver, BattleEvent.Replay_Exit, BattleEvent.Replay_Pause, BattleEvent.Replay_Resume, BattleEvent.Replay_Fast, BattleEvent.Replay_Slow, BattleEvent.Replay_Redo, BattleEvent.Replay_Undo)
  local battleDebugControl = self.battleDebugControl
  if battleDebugControl then
    battleDebugControl.isInAutoPlaySkill = true
    battleDebugControl:EnterDebugBattle(enterBattleParam)
  end
  context.phase = Phase.InBattle
  Log.Debug("BattleDebugSkillAutoPlayControl:HandleEnterTestBattle \229\183\178\232\191\155\229\133\165\230\181\139\232\175\149\230\136\152\230\150\151")
end

function BattleDebugSkillAutoPlayControl:HandleTestOver(context)
  local phase = context and context.phase
  if not context or phase ~= Phase.TestOver then
    return
  end
  local battleContext = context and context.battleContext
  if battleContext then
    self:CancelBattleContextDelays(battleContext)
  end
  Log.Debug("BattleDebugSkillAutoPlayControl:HandleTestOver \229\143\145\233\128\129 BattleEndReq")
  local req = _G.ProtoMessage:newZoneGmBattleEndReq()
  req.battle_result = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_BATTLE_END_REQ, req, self, self.OnBattleEndRsp)
  context.phase = Phase.WaitBattleOverEvent
  context.waitBattleFinishTimeoutDelayId = _G.DelayManager:DelaySeconds(10, self.OnWaitBattleFinishTimeout, self, context)
end

function BattleDebugSkillAutoPlayControl:OnWaitBattleFinishTimeout(context)
  local phase = context and context.phase
  if context then
    context.waitBattleFinishTimeoutDelayId = nil
  end
  if context and (phase == Phase.WaitBattleOverEvent or phase == Phase.WaitBattleFinish) then
    Log.Error(string.format("BattleDebugSkillAutoPlayControl: \232\182\133\230\151\182\239\188\136phase=%s\239\188\137\239\188\140\229\188\186\229\136\182 Complete", tostring(phase)))
    local battleContext = context.battleContext
    if battleContext then
      battleContext.ok = false
      battleContext.errorMessage = string.format("BattleDebugSkillAutoPlayControl:OnWaitBattleFinishTimeout phase=%s", tostring(phase))
    end
    context.phase = Phase.Complete
    self:HandleNextPhase(context)
  end
end

function BattleDebugSkillAutoPlayControl:HandleComplete(context)
  local phase = context and context.phase
  if not context or phase ~= Phase.Complete then
    return
  end
  local waitDelayId = context.waitBattleFinishTimeoutDelayId
  if waitDelayId then
    _G.DelayManager:CancelDelayById(waitDelayId)
    context.waitBattleFinishTimeoutDelayId = nil
  end
  _G.BattleEventCenter:UnBind(self)
  local battleContext = context.battleContext
  if battleContext then
    self:CancelBattleContextDelays(battleContext)
    context.battleContext = nil
  end
  local ok = battleContext and battleContext.ok
  local errorMessage = battleContext and battleContext.errorMessage
  if false == ok then
    Log.Error(string.format("[BattleDebugSkillAutoPlayControl] \229\141\149\232\189\174\229\188\130\229\184\184\229\174\140\230\136\144: %s", tostring(errorMessage)))
  else
    Log.Debug("BattleDebugSkillAutoPlayControl:HandleComplete \229\141\149\232\189\174\229\174\140\230\136\144\239\188\140\229\155\158\229\136\176 Idle")
  end
  context.phase = Phase.Idle
  self:TryStartNext()
end

function BattleDebugSkillAutoPlayControl:OnTick(DeltaTime)
  local context = self.context
  local phase = context and context.phase
  if phase == Phase.WaitCurrentBattleFinish or phase == Phase.WaitBattleFinish then
    local battleManager = _G.BattleManager
    local isInBattle = battleManager and battleManager:IsInBattle()
    if not isInBattle then
      if phase == Phase.WaitCurrentBattleFinish then
        context.phase = Phase.EnterTestBattle
      elseif phase == Phase.WaitBattleFinish then
        context.phase = Phase.Complete
      end
      self:HandleNextPhase(context)
    end
  end
end

function BattleDebugSkillAutoPlayControl:OnLeaveBattle()
  Log.Debug("BattleDebugSkillAutoPlayControl:OnLeaveBattle")
  local battleDebugControl = self.battleDebugControl
  if battleDebugControl then
    battleDebugControl.isInAutoPlaySkill = false
  end
  _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), 1.0)
  local context = self.context
  local phase = context and context.phase
  if not context then
    return
  end
  if phase == Phase.WaitBattleOverEvent or phase == Phase.TestOver or phase == Phase.InBattle then
    if phase == Phase.InBattle or phase == Phase.TestOver then
      local battleContext = context.battleContext
      if battleContext then
        battleContext.ok = false
        battleContext.errorMessage = string.format("BattleDebugSkillAutoPlayControl:OnLeaveBattle \230\136\152\230\150\151\229\188\130\229\184\184\231\187\147\230\157\159\239\188\140\229\189\147\229\137\141 phase=%s", tostring(phase))
      end
    end
    context.phase = Phase.WaitBattleFinish
    self:HandleNextPhase(context)
  end
end

function BattleDebugSkillAutoPlayControl:OnBattleEndRsp()
  Log.Debug("BattleDebugSkillAutoPlayControl:OnBattleEndRsp")
end

function BattleDebugSkillAutoPlayControl:OnBattleEvent(eventName, ...)
  local context = self.context
  local phase = context and context.phase
  if phase ~= Phase.InBattle then
    return
  end
  local battleContext = context and context.battleContext
  if not battleContext then
    return
  end
  if eventName == BattleEvent.ROUND_START then
    self:OnRoundStart()
  elseif eventName == BattleEvent.PrepareBattleOver then
    self:OnPrepareBattleOver()
  elseif eventName == BattleEvent.Replay_Exit then
    self:OnReplayExit()
  elseif eventName == BattleEvent.Replay_Pause then
    self:OnReplayPause()
  elseif eventName == BattleEvent.Replay_Resume then
    self:OnReplayResume()
  elseif eventName == BattleEvent.Replay_Fast then
    self:OnReplayFast()
  elseif eventName == BattleEvent.Replay_Slow then
    self:OnReplaySlow()
  elseif eventName == BattleEvent.Replay_Redo then
    self:OnReplayRoundRedo()
  elseif eventName == BattleEvent.Replay_Undo then
    self:OnReplayRoundUndo()
  end
end

function BattleDebugSkillAutoPlayControl:OnPrepareBattleOver()
  local context = self.context
  local battleContext = context and context.battleContext
  local subPhase = battleContext and battleContext.subPhase
  if not battleContext or subPhase ~= BattleSubPhase.WaitPrepareBattleOver then
    return
  end
  battleContext.subPhase = BattleSubPhase.RoundLoop
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.BattleMainSetOpacity, 0)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Open_ReplayPanel)
end

function BattleDebugSkillAutoPlayControl:OnRoundStart()
  local context = self.context
  local battleContext = context and context.battleContext
  if not battleContext then
    return
  end
  local subPhase = battleContext.subPhase
  if subPhase ~= BattleSubPhase.RoundLoop then
    return
  end
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.BattleMainSetOpacity, 0)
  if not self:IsTeamPetAlive() then
    local battleDebugControl = self.battleDebugControl
    local canAutoSupply = battleDebugControl and battleDebugControl:CheckCanAutoSupplyPet()
    if canAutoSupply then
      _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, "\229\174\160\231\137\169\230\136\152\232\180\165\239\188\140\232\135\170\229\138\168\232\161\165\229\174\160\228\184\173...")
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, "\229\174\160\231\137\169\230\136\152\232\180\165\239\188\140\229\183\178\230\151\160\229\143\175\228\187\165\232\161\165\229\133\133\231\154\132\229\174\160\231\137\169\239\188\140\231\130\185\229\135\187\229\143\179\228\184\138\232\167\146 x \233\128\128\229\135\186")
    end
    return
  end
  battleContext.isRoundPlaying = false
  local currentRoundIndex = battleContext.currentRoundIndex or 0
  local nextRoundDataIndex = currentRoundIndex + 1
  local configData = battleContext.configData
  local roundData = configData and configData.roundData or {}
  local totalRounds = #roundData
  if nextRoundDataIndex > totalRounds then
    _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, "\230\138\128\232\131\189\229\183\178\229\133\168\233\131\168\230\146\173\230\148\190\229\174\140\230\136\144\239\188\140\229\141\179\229\176\134\233\128\128\229\135\186\239\188\140\230\136\150\231\155\180\230\142\165\231\130\185\229\135\187\229\143\179\228\184\138\232\167\146 x \233\128\128\229\135\186")
    local replayExitDelayId = battleContext.replayExitDelayId
    if replayExitDelayId then
      _G.DelayManager:CancelDelayById(replayExitDelayId)
    end
    battleContext.replayExitDelayId = _G.DelayManager:DelaySeconds(1, self.OnReplayExitTimeout, self, battleContext)
  else
    local isPaused = battleContext.isPaused
    if isPaused then
      _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, string.format("\229\183\178\230\154\130\229\129\156\239\188\140\228\184\139\228\184\128\229\155\158\229\144\136\230\152\175\231\172\172 %d \229\155\158\229\144\136, \230\128\187\229\155\158\229\144\136\230\149\176\228\184\186: %d", nextRoundDataIndex, totalRounds))
    else
      battleContext.currentRoundIndex = nextRoundDataIndex
      local roundParam = self:PrepareRoundParam(battleContext)
      _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, string.format("\231\172\172 %d \229\155\158\229\144\136\229\141\179\229\176\134\229\188\128\229\167\139, \230\128\187\229\155\158\229\144\136\230\149\176\228\184\186: %d", battleContext.currentRoundIndex, totalRounds))
      local playRoundDelayId = battleContext.playRoundDelayId
      if playRoundDelayId then
        _G.DelayManager:CancelDelayById(playRoundDelayId)
      end
      battleContext.pendingRoundParam = roundParam
      battleContext.playRoundDelayId = _G.DelayManager:DelaySeconds(1, self.OnPlayRoundDelay, self, battleContext)
    end
  end
end

function BattleDebugSkillAutoPlayControl:OnReplayExitTimeout(battleContext)
  if battleContext then
    battleContext.replayExitDelayId = nil
  end
  local context = self.context
  local currentBattleContext = context and context.battleContext
  if battleContext ~= currentBattleContext then
    return
  end
  self:OnReplayExit()
end

function BattleDebugSkillAutoPlayControl:OnPlayRoundDelay(battleContext)
  if not battleContext then
    return
  end
  battleContext.playRoundDelayId = nil
  local context = self.context
  local phase = context and context.phase
  if phase ~= Phase.InBattle then
    return
  end
  local subPhase = battleContext.subPhase
  if subPhase ~= BattleSubPhase.RoundLoop then
    return
  end
  battleContext.isRoundPlaying = true
  local currentRoundIndex = battleContext.currentRoundIndex or 0
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshRoundIdxUI, currentRoundIndex)
  local roundParam = battleContext.pendingRoundParam
  battleContext.pendingRoundParam = nil
  if roundParam then
    self:PlayRound(roundParam)
  end
end

function BattleDebugSkillAutoPlayControl:OnReplayExit()
  local context = self.context
  local phase = context and context.phase
  if not context or phase ~= Phase.InBattle then
    return
  end
  local battleContext = context and context.battleContext
  if not battleContext then
    return
  end
  battleContext.subPhase = BattleSubPhase.SubComplete
  self:OnBattleContextComplete()
end

function BattleDebugSkillAutoPlayControl:OnBattleContextComplete()
  local context = self.context
  local phase = context and context.phase
  if not context or phase ~= Phase.InBattle then
    return
  end
  local battleContext = context and context.battleContext
  if battleContext then
    self:CancelBattleContextDelays(battleContext)
  end
  context.phase = Phase.TestOver
  self:HandleNextPhase(context)
end

function BattleDebugSkillAutoPlayControl:OnReplayPause()
  local context = self.context
  local battleContext = context and context.battleContext
  if not battleContext then
    return
  end
  local subPhase = battleContext.subPhase
  if subPhase == BattleSubPhase.SubComplete then
    return
  end
  battleContext.isPaused = true
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshPauseUi, true)
end

function BattleDebugSkillAutoPlayControl:OnReplayResume()
  local context = self.context
  local battleContext = context and context.battleContext
  if not battleContext then
    return
  end
  battleContext.isPaused = false
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshPauseUi, false)
  local isRoundPlaying = battleContext.isRoundPlaying
  if not isRoundPlaying then
    self:OnRoundStart()
  end
end

function BattleDebugSkillAutoPlayControl:OnReplayFast()
  local context = self.context
  local battleContext = context and context.battleContext
  local currentPlaySpeed = battleContext and battleContext.currentPlaySpeed
  if not battleContext or not currentPlaySpeed then
    return
  end
  if currentPlaySpeed == BattleConst.Replay.ReplaySpeedFastNormal then
    battleContext.currentPlaySpeed = BattleConst.Replay.ReplaySpeedFast
  elseif currentPlaySpeed == BattleConst.Replay.ReplaySpeedSlow then
    battleContext.currentPlaySpeed = BattleConst.Replay.ReplaySpeedFastNormal
  end
  _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), battleContext.currentPlaySpeed)
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshPlaySpeedUi, battleContext.currentPlaySpeed)
end

function BattleDebugSkillAutoPlayControl:OnReplaySlow()
  local context = self.context
  local battleContext = context and context.battleContext
  local currentPlaySpeed = battleContext and battleContext.currentPlaySpeed
  if not battleContext or not currentPlaySpeed then
    return
  end
  if currentPlaySpeed == BattleConst.Replay.ReplaySpeedFastNormal then
    battleContext.currentPlaySpeed = BattleConst.Replay.ReplaySpeedSlow
  elseif currentPlaySpeed == BattleConst.Replay.ReplaySpeedFast then
    battleContext.currentPlaySpeed = BattleConst.Replay.ReplaySpeedFastNormal
  end
  _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), battleContext.currentPlaySpeed)
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshPlaySpeedUi, battleContext.currentPlaySpeed)
end

function BattleDebugSkillAutoPlayControl:OnReplayRoundUndo()
  local context = self.context
  local battleContext = context and context.battleContext
  local isRoundPlaying = battleContext and battleContext.isRoundPlaying
  local currentRoundIndex = battleContext and battleContext.currentRoundIndex or 0
  if not battleContext or not isRoundPlaying then
    return
  end
  if currentRoundIndex >= 1 then
    battleContext.currentRoundIndex = currentRoundIndex - 1
    _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, string.format("\230\173\163\229\156\168\232\189\172\232\183\179\239\188\140\228\184\139\228\184\128\229\155\158\229\144\136\230\152\175\231\172\172 %d \229\155\158\229\144\136", battleContext.currentRoundIndex + 1))
  end
end

function BattleDebugSkillAutoPlayControl:OnReplayRoundRedo()
  local context = self.context
  local battleContext = context and context.battleContext
  local isRoundPlaying = battleContext and battleContext.isRoundPlaying
  local currentRoundIndex = battleContext and battleContext.currentRoundIndex or 0
  if not battleContext or not isRoundPlaying then
    return
  end
  local configData = battleContext.configData
  local roundData = configData and configData.roundData or {}
  local totalRounds = #roundData
  if currentRoundIndex <= totalRounds then
    battleContext.currentRoundIndex = currentRoundIndex + 1
    _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, string.format("\230\173\163\229\156\168\232\189\172\232\183\179\239\188\140\228\184\139\228\184\128\229\155\158\229\144\136\230\152\175\231\172\172 %d \229\155\158\229\144\136", battleContext.currentRoundIndex + 1))
  end
end

function BattleDebugSkillAutoPlayControl:PrepareRoundParam(battleContext)
  local configData = battleContext and battleContext.configData
  local roundData = configData and configData.roundData or {}
  local currentRoundIndex = battleContext and battleContext.currentRoundIndex or 0
  local roundDataItem = roundData[currentRoundIndex]
  local battleManager = _G.BattleManager
  local battlePawnManager = battleManager and battleManager.battlePawnManager
  local teamPet = battlePawnManager and battlePawnManager:GetPetByPos(BattleEnum.Team.ENUM_TEAM, 1)
  local enemyPet = battlePawnManager and battlePawnManager:GetPetByPos(BattleEnum.Team.ENUM_ENEMY, 1)
  local petGuid = teamPet and teamPet.guid
  local enemyPetGuid = enemyPet and enemyPet.guid
  local battlePlayer = battlePawnManager and battlePawnManager:GetPlayerMyTeam()
  local deck = battlePlayer and battlePlayer.deck
  local cards = deck and deck.cards or {}
  local teamPetConfigId = configData and configData.teamPetConfigId
  if teamPetConfigId then
    for i, card in ipairs(cards) do
      local cardConfig = card and card.config
      local cardConfigId = cardConfig and cardConfig.id
      if cardConfigId == teamPetConfigId then
        petGuid = card.guid
      end
    end
  end
  local teamPlayerData = roundDataItem and roundDataItem.teamPlayer
  local teamPlayerSkillId = teamPlayerData and teamPlayerData.skillId
  local enemyPlayerData = roundDataItem and roundDataItem.enemyPlayer
  local enemyPlayerSkillId = enemyPlayerData and enemyPlayerData.skillId
  local roundParam = {}
  roundParam.playerMagicCMDs = {}
  roundParam.teamCMDs = {}
  local teamSkillInfo = {}
  teamSkillInfo[1] = {
    team = BattleEnum.Team.ENUM_TEAM,
    pos = 1,
    petGuid = petGuid,
    skillTargetId = enemyPetGuid,
    playOrder = 1,
    skillId = teamPlayerSkillId,
    attackCount = 1,
    isKill = false
  }
  table.insert(roundParam.teamCMDs, teamSkillInfo)
  roundParam.enemyCMDs = {}
  local enemySkillInfo = {}
  enemySkillInfo[1] = {
    team = BattleEnum.Team.ENUM_ENEMY,
    pos = 1,
    petGuid = enemyPetGuid,
    skillTargetId = petGuid,
    playOrder = 1,
    skillId = enemyPlayerSkillId,
    attackCount = 1,
    isKill = false
  }
  table.insert(roundParam.enemyCMDs, enemySkillInfo)
  return roundParam
end

function BattleDebugSkillAutoPlayControl:PlayRound(roundParam)
  local context = self.context
  local battleContext = context and context.battleContext
  local currentRoundIndex = battleContext and battleContext.currentRoundIndex or 0
  local configData = battleContext and battleContext.configData
  local roundData = configData and configData.roundData or {}
  local totalRounds = #roundData
  local teamCMDs = roundParam and roundParam.teamCMDs or {}
  local firstTeamCMD = teamCMDs[1]
  local firstTeamSkill = firstTeamCMD and firstTeamCMD[1]
  local teamSkillId = firstTeamSkill and firstTeamSkill.skillId
  local enemyCMDs = roundParam and roundParam.enemyCMDs or {}
  local firstEnemyCMD = enemyCMDs[1]
  local firstEnemySkill = firstEnemyCMD and firstEnemyCMD[1]
  local enemySkillId = firstEnemySkill and firstEnemySkill.skillId
  local tipString = string.format("\229\189\147\229\137\141\230\152\175\231\172\172 %d \229\155\158\229\144\136\239\188\140\230\173\163\229\156\168\230\181\139\232\175\149\230\138\128\232\131\189: \230\136\145\230\150\185 %s  \230\149\140\230\150\185 %s, \230\128\187\229\155\158\229\144\136\230\149\176\228\184\186: %d", currentRoundIndex, tostring(teamSkillId), tostring(enemySkillId), totalRounds)
  Log.Debug(string.format("BattleDebugSkillAutoPlayControl:PlayRound %s", tipString))
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshBottomSkillText, tipString)
  local battleDebugControl = self.battleDebugControl
  if battleDebugControl then
    battleDebugControl:RoundStart(roundParam)
  end
end

function BattleDebugSkillAutoPlayControl:IsTeamPetAlive()
  local battleManager = _G.BattleManager
  local battlePawnManager = battleManager and battleManager.battlePawnManager
  local teamPet = battlePawnManager and battlePawnManager:GetPetByPos(BattleEnum.Team.ENUM_TEAM, 1)
  return nil ~= teamPet
end

function BattleDebugSkillAutoPlayControl:CancelBattleContextDelays(battleContext)
  local delayId = battleContext and battleContext.addTeamPetDelayId
  if delayId then
    _G.DelayManager:CancelDelayById(delayId)
    battleContext.addTeamPetDelayId = nil
  end
  delayId = battleContext and battleContext.replayExitDelayId
  if delayId then
    _G.DelayManager:CancelDelayById(delayId)
    battleContext.replayExitDelayId = nil
  end
  delayId = battleContext and battleContext.playRoundDelayId
  if delayId then
    _G.DelayManager:CancelDelayById(delayId)
    battleContext.playRoundDelayId = nil
  end
end

function BattleDebugSkillAutoPlayControl.LoadAutoPlayConfigFromSaved(fileName)
  local data = JsonUtils.LoadSaved(fileName, {})
  if next(data) == nil then
    return nil
  end
  return data
end

function BattleDebugSkillAutoPlayControl:GetEnterBattleParam(battleContext)
  local configData = battleContext and battleContext.configData
  local teamPetConfigId = configData and configData.teamPetConfigId
  local enemyMonsterConfigId = configData and configData.enemyMonsterConfigId
  local enemyNpcConfigId = configData and configData.enemyNpcConfigId
  local enterBattleParam = {}
  local playerTeam = {}
  local playerTeamPlayer1 = {}
  playerTeamPlayer1.playerSex = 1
  playerTeamPlayer1.fashion_suit = 0
  local playerTeamPet1 = self:GetTeamPet(teamPetConfigId)
  playerTeam.player1 = playerTeamPlayer1
  playerTeam.pet1 = playerTeamPet1
  local enemyTeam = {}
  local enemyNpc = self:GetNpc(enemyNpcConfigId)
  local enemyTeamPlayer1 = {}
  enemyTeamPlayer1.playerSex = 1
  enemyTeamPlayer1.useNpc = true
  enemyTeamPlayer1.npcName = enemyNpc
  local enemyTeamPet1 = self:GetEnemyPet(enemyMonsterConfigId)
  enemyTeam.player1 = enemyTeamPlayer1
  enemyTeam.pet1 = enemyTeamPet1
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local PlayerLocation = player.viewObj:Abs_K2_GetActorLocation()
  PlayerLocation.Z = PlayerLocation.Z - player:GetHalfHeight()
  local battlePos = {}
  battlePos.x = math.floor(PlayerLocation.X)
  battlePos.y = math.floor(PlayerLocation.Y)
  battlePos.z = math.floor(PlayerLocation.Z)
  enterBattleParam.name = ""
  enterBattleParam.battleType = 1
  enterBattleParam.battlePosTempName = "\232\191\155\233\153\132\232\191\145\230\136\152\230\150\151"
  enterBattleParam.battlePos = battlePos
  enterBattleParam.isShowHP = true
  enterBattleParam.player_team = playerTeam
  enterBattleParam.enemy_team = enemyTeam
  return enterBattleParam
end

function BattleDebugSkillAutoPlayControl:GetTeamPet(petInfoString)
  local battleDebugControl = self.battleDebugControl
  local allPetList = battleDebugControl and battleDebugControl:GetAllPetList() or {}
  petInfoString = tostring(petInfoString or "")
  local petInfoStringLower = string.lower(petInfoString)
  if not string.IsNilOrEmpty(petInfoStringLower) then
    for i, v in pairs(allPetList) do
      if v:find(petInfoStringLower) then
        return v
      end
    end
  end
  return string.lower("[9999999]\230\151\160\230\149\140\233\184\173\229\144\137\229\144\137(\230\181\139\232\175\149\231\148\168) BP_Com_YaJiJi1_001")
end

function BattleDebugSkillAutoPlayControl:GetEnemyPet(monsterInfoString)
  local battleDebugControl = self.battleDebugControl
  local allMonsterList = battleDebugControl and battleDebugControl:GetAllMonsterList() or {}
  monsterInfoString = tostring(monsterInfoString or "")
  local monsterInfoStringLower = string.lower(monsterInfoString)
  if not string.IsNilOrEmpty(monsterInfoStringLower) then
    for i, v in pairs(allMonsterList) do
      if v:find(monsterInfoStringLower) then
        return v
      end
    end
  end
  return string.lower("[9999999]\230\151\160\230\149\140\233\184\173\229\144\137\229\144\137(\230\181\139\232\175\149\231\148\168) BP_Com_YaJiJi1_001")
end

function BattleDebugSkillAutoPlayControl:GetNpc(npcInfoString)
  local battleDebugControl = self.battleDebugControl
  local allNpcList = battleDebugControl and battleDebugControl:GetAllNpcList() or {}
  npcInfoString = tostring(npcInfoString or "")
  local npcInfoStringLower = string.lower(npcInfoString)
  if not string.IsNilOrEmpty(npcInfoStringLower) then
    for i, v in pairs(allNpcList) do
      if v:find(npcInfoStringLower) then
        return v
      end
    end
  end
  return string.lower("[17015]\232\183\175\230\152\147\230\150\175 BP_Battle_NPC_01101")
end

local _instance

function BattleDebugSkillAutoPlayControl.GetInstance()
  if not _instance then
    _instance = BattleDebugSkillAutoPlayControl()
  end
  return _instance
end

return BattleDebugSkillAutoPlayControl
