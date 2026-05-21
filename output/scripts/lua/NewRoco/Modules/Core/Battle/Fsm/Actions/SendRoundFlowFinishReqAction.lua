local ProtoMessage = require("Data.PB.ProtoMessage")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local SendRoundFlowFinishReqAction = BattleActionBase:Extend("SendRoundFlowFinishReqAction")
FsmUtils.MergeMembers(BattleActionBase, SendRoundFlowFinishReqAction, {
  {name = "Flows", type = "table"},
  {
    name = "BattleState",
    type = "number"
  },
  {
    name = "IsFromRoundStart",
    type = "boolean"
  }
})

function SendRoundFlowFinishReqAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ServerReqAction)
end

function SendRoundFlowFinishReqAction:OnEnter()
  local IsFromRoundStart = self:GetProperty("IsFromRoundStart") or false
  if IsFromRoundStart then
    self:Finish()
    return
  end
  if BattleUtils.IsFinalBattleP2() then
    local isBattle = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.battle_brief.battle_state > 0
    if not isBattle then
      self.fsm:SendEvent(BattleEvent.EnterNormalOver)
      return
    end
  end
  if not BattleUtils.IsPvp() and not BattleUtils.IsNpcChallenge() and not BattleUtils.IsLeaderChallenge() and BattleExitHelper.IsFinishSeamless() and not BattleUtils.IsTerritoryTrialBattle() and not BattleUtils.IsFinalBattle() and not BattleUtils.IsWeeklyChallenge() and not BattleUtils.IsB1FinalBattle() and not BattleUtils.IsTrainBattle() then
    if BattleUtils.IsWorldLeaderFight() then
      self.fsm:SendEvent(BattleEvent.EnterWorldLeaderSeamlessOver)
    else
      self.fsm:SendEvent(BattleEvent.EnterSeamlessOver)
    end
  else
    BattleManager:PreChangeCameraOnRoundPlayFinish()
    local Flows = self:GetProperty("Flows")
    local BattleState = self:GetProperty("BattleState")
    if BattleManager.battleRuntimeData:IsFBWaitRoundFlowFinishRSP() then
      local req = BattleNetManager:CreateBattleRoundFlowFinishReq()
      if Flows then
        req.seq_num = Flows.seq_num
      else
        Log.Error("zgx \228\184\165\233\135\141\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129  RoundFlowFinish \230\178\161\230\156\137 \229\186\143\229\136\151\229\143\183")
      end
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_FLOW_FINISH_REQ, req, self, self.OnRsp, false, true)
      _G.BattleEventCenter:Bind(self, BattleEvent.ON_RECEIVE_BATTLE_ENTER)
    else
      if Flows then
        BattleNetManager:SendBattleRoundFlowFinishReq(Flows.seq_num, BattleState)
      else
        Log.Error("zgx \228\184\165\233\135\141\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129  RoundFlowFinish \230\178\161\230\156\137 \229\186\143\229\136\151\229\143\183")
        BattleNetManager:SendBattleRoundFlowFinishReq()
      end
      self:Finish()
    end
  end
end

function SendRoundFlowFinishReqAction:OnRsp(rsp)
  if BattleUtils.IsFinalBattle() then
    BattleManager.battleRuntimeData:SetFBP1ToP2State(nil)
    local removeInfo = {
      {
        _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY,
        true
      },
      {
        _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY,
        false,
        function(notify)
          local performNotify = notify and notify.notify
          if performNotify and notify.notifyCmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY then
            for i, v in ipairs(performNotify.perform_cmd.perform_info) do
              if v.ai_perform and v.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEVEL_SEQUENCE then
                return true
              end
            end
          end
          return false
        end
      }
    }
    BattleNetManager:RemoveNotifyByCMD(removeInfo)
  end
  self:Finish()
end

function SendRoundFlowFinishReqAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.ON_RECEIVE_BATTLE_ENTER and BattleManager.battleRuntimeData:IsFBWaitRoundFlowFinishRSP() then
    BattleLog.Debug("SendRoundFlowFinishReqAction:OnBattleEvent ")
    local Flows = self:GetProperty("Flows")
    local req = BattleNetManager:CreateBattleRoundFlowFinishReq()
    if Flows then
      req.seq_num = Flows.seq_num
    else
      Log.Error("zgx \228\184\165\233\135\141\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129  RoundFlowFinish \230\178\161\230\156\137 \229\186\143\229\136\151\229\143\183")
    end
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_FLOW_FINISH_REQ, req, self, self.OnRsp, false, true)
  end
end

function SendRoundFlowFinishReqAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
end

return SendRoundFlowFinishReqAction
