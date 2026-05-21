local BattleActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleActionBase")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoMessage = require("Data.PB.ProtoMessage")
local Base = BattleActionBase
local BattleTerritoryTrialSendAgain = Base:Extend("BattleTerritoryTrialSendAgain")
local Phase = {
  StartWaitForBattleFinish = 1,
  WaitingForBattleFinish = 2,
  SendNextActReq = 3,
  WaitingForNextActRsp = 4,
  NextActRsp = 5,
  Complete = 6
}

function BattleTerritoryTrialSendAgain:Ctor()
  Base.Ctor(self)
end

function BattleTerritoryTrialSendAgain:OnEnter()
  _G.UpdateManager:Register(self)
  local battleManager = _G.BattleManager
  local battleRuntimeData = battleManager and battleManager.battleRuntimeData
  local restartInfo = battleRuntimeData and battleRuntimeData:GetRestartInfo()
  if battleRuntimeData then
    battleRuntimeData:ClearRestartInfo()
  end
  local context = {}
  context.restartInfo = restartInfo
  context.phase = Phase.StartWaitForBattleFinish
  self.context = context
  self:HandleNextPhase(context)
end

function BattleTerritoryTrialSendAgain:OnNextActRsp(rsp)
  local context = self.context
  local phase = context and context.phase
  if context and phase == Phase.WaitingForNextActRsp then
    context.sceneNpcNextActRsp = rsp
    context.phase = Phase.NextActRsp
    self:HandleNextPhase(context)
  else
    Log.Error("BattleTerritoryTrialSendAgain receive rsp but we are not waiting for rsp now")
  end
end

function BattleTerritoryTrialSendAgain:OnNextActRspTimeout()
  local context = self.context
  local phase = context and context.phase
  if context then
    context.waitNextActRspDelayId = nil
  end
  if context and phase == Phase.WaitingForNextActRsp then
    context.phase = Phase.NextActRsp
    self:HandleNextPhase(context)
  end
end

function BattleTerritoryTrialSendAgain:OnTick(DeltaTime)
  local context = self.context
  local phase = context and context.phase
  if phase == Phase.WaitingForBattleFinish then
    local battleManager = _G.BattleManager
    local isInBattle = battleManager and battleManager:IsInBattle()
    if not isInBattle and context then
      context.phase = Phase.SendNextActReq
      self:HandleNextPhase(context)
    end
  end
end

function BattleTerritoryTrialSendAgain:OnFinish()
  _G.UpdateManager:UnRegister(self)
  local context = self.context
  local safeDelayId = context and context.waitNextActRspDelayId
  if safeDelayId then
    _G.DelayManager:CancelDelayById(safeDelayId)
  end
  safeDelayId = context and context.waitBattleFinishDelayId
  if safeDelayId then
    _G.DelayManager:CancelDelayById(safeDelayId)
  end
  local ok = context and context.ok
  if not ok then
    local errorMessage = context and context.errorMessage
    Log.Error("[BattleTerritoryTrialSendAgain] flow is not success", errorMessage)
    local closeReasonList = {
      BattleEnum.ShowBlackScreenReason.RestartEnterBattle
    }
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseLoading, {closeReasonList = closeReasonList})
  end
  self.context = nil
end

function BattleTerritoryTrialSendAgain:HandleWaitForBattleFinish(context)
  local phase = context and context.phase
  if context and phase == Phase.StartWaitForBattleFinish then
    local waitBattleFinishDelayId = _G.DelayManager:DelaySeconds(5, self.OnWaitBattleFinishTimeout, self)
    context.waitBattleFinishDelayId = waitBattleFinishDelayId
    context.phase = Phase.WaitingForBattleFinish
    self:HandleNextPhase(context)
  end
end

function BattleTerritoryTrialSendAgain:HandleSendNextActReq(context)
  local phase = context and context.phase
  if context and phase == Phase.SendNextActReq then
    local restartInfo = context and context.restartInfo
    local npcId = restartInfo and restartInfo.npcId
    local optionId = restartInfo and restartInfo.optionId
    local req = ProtoMessage:newZoneSceneNpcNextActReq()
    req.npc_id = npcId
    req.option_id = optionId
    req.first_act = true
    req.battle_radius = BattleConst.Define.BattleFieldRange
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, req, self, self.OnNextActRsp, true, false)
    local waitNextActRspDelayId = _G.DelayManager:DelaySeconds(5, self.OnNextActRspTimeout, self)
    context.phase = Phase.WaitingForNextActRsp
    context.waitNextActRspDelayId = waitNextActRspDelayId
    self:HandleNextPhase(context)
  end
end

function BattleTerritoryTrialSendAgain:OnWaitBattleFinishTimeout()
  local context = self.context
  local phase = context and context.phase
  if context then
    context.waitBattleFinishDelayId = nil
  end
  if context and phase == Phase.WaitingForBattleFinish then
    context.phase = Phase.Complete
    context.ok = false
    context.errorMessage = "BattleTerritoryTrialSendAgain:WaitBattleFinishTimeout"
    self:HandleNextPhase(context)
  end
end

function BattleTerritoryTrialSendAgain:HandleNextActRsp(context)
  if not context then
    return
  end
  local sceneNpcNextActRsp = context and context.sceneNpcNextActRsp
  local retInfo = sceneNpcNextActRsp and sceneNpcNextActRsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 == retCode then
    context.ok = true
  else
    if retCode then
      context.errorMessage = string.format("BattleTerritoryTrialSendAgain:OnBattleRsp ret code %s", tostring(retCode))
    else
      context.errorMessage = "BattleTerritoryTrialSendAgain:WaitNextActRspTimeout"
    end
    context.ok = false
  end
  context.phase = Phase.Complete
  self:HandleNextPhase(context)
end

function BattleTerritoryTrialSendAgain:HandleNextPhase(context)
  local phase = context and context.phase
  if phase == Phase.StartWaitForBattleFinish then
    self:HandleWaitForBattleFinish(context)
  elseif phase == Phase.WaitingForBattleFinish then
  elseif phase == Phase.SendNextActReq then
    self:HandleSendNextActReq(context)
  elseif phase == Phase.WaitingForNextActRsp then
  elseif phase == Phase.NextActRsp then
    self:HandleNextActRsp(context)
  elseif phase == Phase.Complete then
    self:Finish()
  end
end

return BattleTerritoryTrialSendAgain
