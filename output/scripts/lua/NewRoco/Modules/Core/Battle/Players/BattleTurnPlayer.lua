local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePerformPlayer = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformPlayer")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local DelaySafeCaller = require("NewRoco.Modules.Core.Battle.Common.DelaySafeCaller")
local BattleManager, PawnManager
local BattleTurnPlayer = NRCClass()

function BattleTurnPlayer:Ctor()
  self.delaySafeCaller = DelaySafeCaller()
  self.isFinished = true
  self.DelayKey = 0
  self.ArriveTimeOutThreshold = false
  BattleManager = _G.BattleManager
  PawnManager = _G.BattleManager.battlePawnManager
  self.performPlayer = BattlePerformPlayer(self)
  BattlePiecesManager:Init(self.performPlayer)
end

function BattleTurnPlayer:RunFlows(Cmd, settleInfo, owner, callback, isMySelfPerform, npc_delay)
  self.isFinished = false
  self.IsCurrentCmdFinish = false
  self.Index = 0
  self.Cmd = Cmd
  self.SettleInfo = settleInfo
  self.CompleteCallbackOwner = owner
  self.CompleteCallback = callback
  self.IsMySelfPerform = isMySelfPerform
  self.performPlayer.IsFinalize = false
  self:SetArriveTimeOut(false)
  if self.SettleInfo then
    self.SettleInfo.result = self.SettleInfo.result or 0
  end
  self:Complete(0)
  if isMySelfPerform and not npc_delay then
    self:AdjustCamera()
  end
  self:CollectSkillInfo()
end

function BattleTurnPlayer:SetArriveTimeOut(value)
  self.ArriveTimeOutThreshold = value
end

function BattleTurnPlayer:GetArriveTimeOut()
  return self.ArriveTimeOutThreshold
end

function BattleTurnPlayer:CollectSkillInfo()
  local skillList = {}
  local buffList = {}
  if _G.BattleManager.battleRuntimeData.battleDebugControl and self.Cmd.perform_info then
    for i = 1, #self.Cmd.perform_info do
      local performInfo = self.Cmd.perform_info[i]
      if performInfo.type == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
        local skillID = performInfo.skill_cast.skill_id
        skillList[skillID] = self:CollectSkill(skillID)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
        local skillID = performInfo.combo_skill_cast.skill_id
        skillList[skillID] = self:CollectSkill(skillID)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
        local buff_change = performInfo.buff_change
        local RealBuffID = buff_change.buff_id
        buffList[RealBuffID] = self:CollectBuff(RealBuffID, buff_change.type)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
        local buff_trigger = performInfo.buff_trigger
        local RealBuffID = buff_trigger.buff_id
        buffList[RealBuffID] = self:CollectBuff(RealBuffID, buff_trigger.perform_type)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
        local effect_id = performInfo.effect_trigger.effect_id
        local effect = _G.DataConfigManager:GetEffectConf(effect_id)
        if effect and effect.effect_order == Enum.EffectType.ET_ANIMATION and effect.effect_param and effect.effect_param[1] and effect.effect_param[1].params then
          local resId = effect.effect_param[1].params[1] or 0
          local SkillResConf = DataConfigManager:GetSkillResConf(resId, true)
          if SkillResConf then
            local resPath = SkillResConf.res_id
            if resPath then
              buffList[effect_id] = resPath
            end
          end
        end
      end
    end
  end
  BattleEventCenter:Dispatch(BattlePerformEvent.TurnPlayStart, skillList, buffList)
end

function BattleTurnPlayer:CollectSkill(skillID)
  local skillConf = SkillUtils.GetSkillConf(skillID)
  local skillResChange = _G.DataConfigManager:GetSkillResChangeConf(SkillUtils.CheckSkillId(skillID), true)
  if skillResChange then
    return skillConf.name .. "_" .. skillResChange.res_id
  else
    return skillConf.name .. "_" .. skillConf.res_id
  end
end

function BattleTurnPlayer:CollectBuff(RealBuffID, perform_type)
  local buffResPath, isExist = SkillUtils.GetBuffResID(RealBuffID, perform_type)
  if isExist then
    return buffResPath
  end
end

function BattleTurnPlayer:AdjustCamera()
  if BattleUtils.IsFinalBattleP1() then
    for i, v in ipairs(self.Cmd.perform_info) do
      if v.ai_perform and v.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEVEL_SEQUENCE then
        return
      end
    end
  end
  local First = self.Cmd.perform_info[1]
  if First then
    if First.use_item then
      return
    elseif First.catch_pet_info then
      return
    end
  end
  local CameraMng = BattleManager.vBattleField.battleCameraManager
  if CameraMng then
    if CameraMng:IsMultiplayer() and not BattleUtils.IsTeam() then
      CameraMng:CalcPos(nil, nil, true)
    else
      CameraMng:CalcPos()
    end
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(BattleConst.Show.SkillCameraTime, true, nil, nil, nil)
  end
end

function BattleTurnPlayer:Start(cmd)
  Log.Trace("BattleTurnPlayer Start:")
  if cmd.perform_info == nil then
    self:Complete(0)
    return
  end
  self:HandlePerformCmd(cmd)
end

function BattleTurnPlayer:Complete(deltaTime, BreakFlow)
  deltaTime = deltaTime or 0
  BreakFlow = BreakFlow or false
  if 0 == deltaTime then
    self:SetFinish(BreakFlow)
  else
    self:SafeDelaySeconds("d_DelaySetFinish", deltaTime, self.DelaySetFinish, self, self.DelayKey)
  end
end

function BattleTurnPlayer:DelaySetFinish(delayKey)
  if self.DelayKey == delayKey then
    self:SetFinish()
  end
end

function BattleTurnPlayer:SkillComplete(BreakFlow)
  self:Complete(0, BreakFlow)
end

function BattleTurnPlayer:SetFinish(BreakFlow)
  if self.IsCurrentCmdFinish then
    self:FireFinishCallback()
  else
    self:SafeDelayFrames("d_DelayStart", 1, self.DelayStart, self, self.Cmd, self.DelayKey)
  end
end

function BattleTurnPlayer:DelayStart(cmd, delayKey)
  if self.DelayKey == delayKey then
    self:Start(cmd)
  else
    Log.Error("BattleTurnPlayer DelayStart DelayKey not match", self.DelayKey, delayKey)
  end
end

function BattleTurnPlayer:OnRoundEnd()
  Log.Debug("BattleTurnPlayer DispatchPerformCallback")
  BattleEventCenter:Dispatch(BattlePerformEvent.TurnPlayComplete)
end

function BattleTurnPlayer:FireFinishCallback()
  if self.SettleInfo then
    _G.BattleManager.battleRuntimeData.battleExitParam:SetLastTurnSettleResult(self.SettleInfo.result)
  end
  self:ShouldLeave()
  self:OnRoundEnd()
  self:SafeCancelAllDelay()
  self.performPlayer:DisableUpdate()
  self.performPlayer:Clear()
  self.isFinished = true
  local Callback = self.CompleteCallback
  local Owner = self.CompleteCallbackOwner
  self.CompleteCallbackOwner = nil
  self.CompleteCallback = nil
  if Callback then
    Callback(Owner)
  end
end

function BattleTurnPlayer:DoFinalize()
  self:SafeCancelAllDelay()
  if self.performPlayer then
    self.performPlayer:DoFinalize()
    self.performPlayer:Clear()
  end
end

function BattleTurnPlayer:SafeCancelAllDelay()
  self.DelayKey = self.DelayKey + 1
  self.delaySafeCaller:SafeCancelAllDelay()
end

function BattleTurnPlayer:HandlePerformComplete()
  self.IsCurrentCmdFinish = true
  self:Complete(0)
end

function BattleTurnPlayer:HandlePerformCmd(cmd)
  self.performPlayer:PreProcess(cmd)
end

function BattleTurnPlayer:ShouldLeave()
  if self:ShouldCatchLeave() then
    if self.SettleInfo and 0 ~= self.SettleInfo.result then
      self:CatchLeave()
    end
    return true
  end
  if self:ShouldEscape() then
    self:EscapeLeave()
    return true
  end
  if self:ShouldBattleFinished() then
    if BattleUtils.IsWorldLeaderFight() then
      if BattleManager.battlePawnManager:IsSkipWorldLeaderSeamless() then
        return false
      elseif not BattleUtils.ContainTaskPerformControl(Enum.TaskBattlePerformanceControl.TBPC_EXIT_BLACK) then
        self:ExitBattle(BattleEnum.Team.ENUM_TEAM)
      end
    elseif self.SettleInfo and self.SettleInfo.result ~= ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_LOSE and self.SettleInfo.result ~= ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_LOSE_HP and not BattleUtils.ContainTaskPerformControl(Enum.TaskBattlePerformanceControl.TBPC_EXIT_BLACK) then
      self:ExitBattle(BattleEnum.Team.ENUM_TEAM)
    end
    return true
  end
  return false
end

function BattleTurnPlayer:ShouldCatchLeave()
  return _G.BattleManager.battleRuntimeData.battleExitParam.IsCatchSuccess
end

function BattleTurnPlayer:CatchLeave()
  BattleExitHelper.SetCatchExitBattle()
end

function BattleTurnPlayer:ShouldEscape()
end

function BattleTurnPlayer:EscapeLeave()
  BattleExitHelper.SetEnemyEscape(self.Caster, nil)
end

function BattleTurnPlayer:ShouldBattleFinished()
  if not self.Cmd then
    return true
  end
  return self.Cmd.is_battle_finished
end

function BattleTurnPlayer:ExitBattle(team)
  Log.Debug("BattleStreamLog  ExitBattleInPerform")
  BattleExitHelper.SetSeamlessExitBattle(_G.BattleManager.battlePawnManager:GetInFieldPet(team), nil)
end

function BattleTurnPlayer:OnActionAquireFromPool()
  if self.performPlayer then
    self.performPlayer:EnableUpdate()
  end
end

function BattleTurnPlayer:OnActionReleaseToPool()
  self.Cmd = nil
  self.SettleInfo = nil
  self:SafeCancelAllDelay()
  if self.performPlayer then
    self.performPlayer:DisableUpdate()
  end
end

function BattleTurnPlayer:DestroyPerformPlayer()
  self:SafeCancelAllDelay()
  if self.performPlayer then
    self.performPlayer:DoFinalize()
    self.performPlayer:Clear()
    self.performPlayer = nil
  end
end

function BattleTurnPlayer:SafeDelaySeconds(idName, ...)
  self.delaySafeCaller:SafeDelaySeconds(idName, ...)
end

function BattleTurnPlayer:SafeDelayFrames(idName, ...)
  self.delaySafeCaller:SafeDelayFrames(idName, ...)
end

function BattleTurnPlayer:SafeCancelDelayById(idName)
  self.delaySafeCaller:SafeCancelDelayById(idName)
end

function BattleTurnPlayer:SafeFindDelayById(idName)
  return self.delaySafeCaller:SafeFindDelayById(idName)
end

return BattleTurnPlayer
