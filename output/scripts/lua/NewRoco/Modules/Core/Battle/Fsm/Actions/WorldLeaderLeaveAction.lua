local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local WorldLeaderLeaveAction = Base:Extend("WorldLeaderLeaveAction")
FsmUtils.MergeMembers(Base, WorldLeaderLeaveAction, nil)

function WorldLeaderLeaveAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientAnimAction)
end

function WorldLeaderLeaveAction:OnEnter()
  _G.BattleEventCenter:Bind(self, BattleEvent.GetBattleFinish, BattleEvent.BATTLE_STATE_SETTLEMENT)
  self.SkillFinished = false
  self.ServerResponded = false
  self.ShowHPTips = false
  self.TryOpenRoleHpDefeatedTip = false
  self.GotoExit = false
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideMain)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
  self:ShowPlayer()
  self.Result = BattleUtils.IsBattleWin(BattleManager.battleRuntimeData.battleExitParam:GetLastTurnSettleResult())
  if self.Result then
    BattlePiecesManager:Play("NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecesWorldLeaderSuccessPerform", self, self.OnSkillFinish)
  else
    BattlePiecesManager:Play("NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecesWorldLeaderFailPerform", self, self.OnSkillFinish)
  end
  if BattleManager.battleRuntimeData.battleSettleData.IsReceiveFinish then
    self:OpenRoleHpDefeatedTip()
    self:OnNetRsp()
  else
    BattleExitHelper.ClearFinishSeamlessFlag()
    BattleExitHelper.SetFinishHandleSeamless()
    self:SendRoundFlowFinish()
  end
end

function WorldLeaderLeaveAction:ShowPlayer()
  local player = BattleManager.battlePawnManager.TeamatePlayer
  if player and UE4.UObject.IsValid(player.model) then
    player.model:BreakFadeCallback()
    player.model:PlayGradualChangeFade(1, 0, 0)
    player:ShowPlayer()
  end
end

function WorldLeaderLeaveAction:SendRoundFlowFinish()
  local Flows = self:GetProperty("Flows")
  local Req
  if Flows then
    Req = BattleNetManager:CreateBattleRoundFlowFinishReq(Flows.seq_num)
  else
    Log.Warning("zgx no Flows")
    Req = ProtoMessage:newZoneBattleRoundFlowFinishReq()
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_FLOW_FINISH_REQ, Req, self, self.OnNetRsp, true, true)
end

function WorldLeaderLeaveAction:OpenRoleHpDefeatedTip()
  if self.TryOpenRoleHpDefeatedTip then
    return
  end
  self.TryOpenRoleHpDefeatedTip = true
  local player = BattleManager.battlePawnManager.TeamatePlayer
  local finishNotify = BattleManager.battleRuntimeData.battleSettleData.data
  if player and finishNotify then
    local settleInfo = finishNotify.settle_info.battler_info or {}
    local battlerInfo
    for i, v in ipairs(settleInfo) do
      if v.id == player.guid then
        battlerInfo = v
        break
      end
    end
    if not self.Result and battlerInfo and battlerInfo.hp then
      local changeHp = battlerInfo.hp - player.roleInfo.base.hp
      if changeHp >= 0 then
        self.ShowHPTips = true
        self:CheckFinish()
        return
      end
      local asyncData = {
        player = player,
        isLast = true,
        isShowLetter = true
      }
      asyncData.black_hp_result = player.roleInfo.base.black_hp
      asyncData.hp_result = battlerInfo.hp
      asyncData.hp_change = changeHp
      asyncData.tips_key = "worldcombat_exit_tips"
      _G.NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenRoleHpDefeatedTipPanel)
      self:SafeDelaySeconds("d_Finish", BattleConst.Show.PveRoleHpShowTimeOnRunAway, self.CloseHpDefeatedTip, self)
      return
    end
  end
  self.ShowHPTips = true
  self:CheckFinish()
end

function WorldLeaderLeaveAction:CloseHpDefeatedTip()
  self.ServerResponded = true
  _G.NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel)
  self:CheckFinish()
end

function WorldLeaderLeaveAction:OnNetRsp()
  self.ServerResponded = true
  self:CheckFinish()
end

function WorldLeaderLeaveAction:OnSkillFinish()
  self.SkillFinished = true
  if _G.BattleManager.battleRuntimeData.battleSettleData.data then
    self.ServerResponded = true
  end
  self:CheckFinish()
end

function WorldLeaderLeaveAction:CheckFinish()
  if not self.ServerResponded then
    return false
  end
  if not self.SkillFinished then
    return false
  end
  if not self.ShowHPTips then
    return false
  end
  self.SkillFinished = false
  self.ServerResponded = false
  self.ShowHPTips = false
  self:ToExit()
  return true
end

function WorldLeaderLeaveAction:ToExit()
  if not self.GotoExit then
    _G.NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel)
    self.GotoExit = true
    self.fsm:SendEvent(BattleEvent.ExitBattle)
  end
end

function WorldLeaderLeaveAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  self:ToExit()
end

function WorldLeaderLeaveAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.GetBattleFinish then
    self:OnNetRsp()
    return true
  elseif eventName == BattleEvent.BATTLE_STATE_SETTLEMENT then
    self:OpenRoleHpDefeatedTip()
    return true
  end
end

return WorldLeaderLeaveAction
