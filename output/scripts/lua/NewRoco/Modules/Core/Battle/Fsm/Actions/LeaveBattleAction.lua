local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Base = BattleActionBase
local LeaveBattleAction = Base:Extend("LeaveBattleAction")
FsmUtils.MergeMembers(Base, LeaveBattleAction, nil)

function LeaveBattleAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.SkillFinished = false
  self.ServerResponded = false
end

function LeaveBattleAction:OnEnter()
  _G.BattleEventCenter:Bind(self, BattleEvent.GetBattleFinish)
  self.ActionFinish = false
  self.isSceneTreesShow = false
  self.needShowSceneTrees = false
  local battleExitParam = _G.BattleManager.battleRuntimeData.battleExitParam
  if BattleUtils.IsPve() or BattleUtils.IsSkipRecycleBall() or BattleUtils.EndBattleByNpc() then
    BattleExitHelper.ClearFinishSeamlessFlag()
    BattleExitHelper.SetFinishPveSeamless()
    self:Finish()
  elseif BattleExitHelper.IsFinishSeamless() and not BattleUtils.ContainTaskPerformControl(Enum.TaskBattlePerformanceControl.TBPC_EXIT_SKIP) then
    self.SkillFinished = false
    self.ServerResponded = false
    self.needShowSceneTrees = true
    BattleExitHelper.ClearFinishSeamlessFlag()
    BattleExitHelper.SetFinishHandleSeamless()
    if BattleUtils.IsSpecialNoPc() then
      self.fsm:SendEvent(BattleEvent.EnterPureBlackOut)
      return
    end
    if BattleUtils.CheckIsPlayerPetsAllDead() then
      self.fsm:SendEvent(BattleEvent.EnterPureBlackOut)
      return
    end
    local pets = battleExitParam.lastHitPets
    local Caster = battleExitParam.lastHitKiller
    battleExitParam.lastHitPets = nil
    battleExitParam.lastHitKiller = nil
    BattleExitHelper.PlayExitSkill(Caster, pets and pets[1], self, self.OnSkillFinish, self.SendRoundFlowFinish, self.OnSkillPostStart, BattleManager.EnterBattleStateBit ~= BattleEnum.EnterBattleState.Default)
  else
    self:Finish()
  end
end

function LeaveBattleAction:SendRoundFlowFinish()
  local Flows = self:GetProperty("Flows")
  local Req
  if Flows then
    Req = BattleNetManager:CreateBattleRoundFlowFinishReq(Flows.seq_num)
  else
    Log.Error("zgx \228\184\165\233\135\141\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129  RoundFlowFinish \230\178\161\230\156\137 \229\186\143\229\136\151\229\143\183")
    Req = ProtoMessage:newZoneBattleRoundFlowFinishReq()
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_FLOW_FINISH_REQ, Req, self, self.OnNetRsp, true, true)
end

function LeaveBattleAction:OnSkillPostStart()
  self:ShowSceneTrees()
end

function LeaveBattleAction:ShowSceneTrees()
  if not self.needShowSceneTrees then
    return
  end
  if self.isSceneTreesShow then
    return
  end
  self.isSceneTreesShow = true
  local ShowSceneTreesDelegate = self:GetProperty(BattleConst.FsmVarNames.ShowSceneTreesDelegate)
  if ShowSceneTreesDelegate then
    ShowSceneTreesDelegate:Invoke()
  end
end

function LeaveBattleAction:OnNetRsp()
  self.ServerResponded = true
  self:CheckFinish()
end

function LeaveBattleAction:OnSkillFinish()
  if not self.ActionFinish then
    self.SkillFinished = true
    if _G.BattleManager.battleRuntimeData.battleSettleData.data then
      self.ServerResponded = true
    end
    self:CheckFinish()
  end
end

function LeaveBattleAction:CheckFinish()
  if not self.ServerResponded then
    return
  end
  if not self.SkillFinished then
    return
  end
  Log.Debug("All Finished, Leave!")
  self.SkillFinished = false
  self.ServerResponded = false
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, false)
  self.fsm:SendEvent(BattleEvent.ExitBattle)
end

function LeaveBattleAction:OnFinish()
  self.ActionFinish = true
  _G.BattleManager.battlePawnManager:HideAll(false)
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, false)
  self:ShowSceneTrees()
end

function LeaveBattleAction:OnExit()
  self.ActionFinish = true
end

function LeaveBattleAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.GetBattleFinish then
    self:OnNetRsp()
    return true
  end
end

return LeaveBattleAction
