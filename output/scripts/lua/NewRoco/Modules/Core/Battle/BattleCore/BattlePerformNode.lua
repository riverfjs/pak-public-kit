local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformNodeBase")
local BattleTimeoutCounter = require("NewRoco.Modules.Core.Battle.Common.BattleTimeoutCounter")
local BattlePerformNode = Base:Extend("BattlePerformNode")
BattlePerformNode.ForceDonePerformReason = {
  Error = "\232\161\168\230\188\148\229\135\186\233\148\153\239\188\140\229\188\186\229\136\182\231\187\147\230\157\159",
  Timeout = "\232\182\133\230\151\182\239\188\140\229\188\186\229\136\182\231\187\147\230\157\159",
  NetTimeout = "\231\189\145\231\187\156\232\182\133\230\151\182\239\188\140\229\188\186\229\136\182\231\187\147\230\157\159",
  NoCastMoment = "\230\178\161\230\156\137\232\161\168\230\188\148\230\151\182\233\151\180\231\130\185"
}

function BattlePerformNode:Ctor(performPlayer)
  self.timeoutCounter = BattleTimeoutCounter.Get("BattlePerformNodeTimeCounter")
  self:ResetData()
  Base.Ctor(self, performPlayer)
end

function BattlePerformNode:ResetData()
  Base.ResetData(self)
  self.isPerformed = false
  self.isPerforming = false
  self.isWaitTrigger = false
  self.IsTimeout = false
  self.PerformTimeSinceBegin = 0
  self.PerformGameTimeSinceBegin = 0
  self.TimeoutDuration = 60
  self.timeoutCounter:Stop()
  self.isTriggeredBeforeNodeCastmoment = false
  self.OwnerGroup = nil
  self.IsCompleteCallBack = false
  self.LastCast = nil
  self.IsPerformOver = false
  self.IsLogicOver = false
end

function BattlePerformNode:IsValidToPerform(groupID, castMoment)
  if not self:IsPerforming() and not self:IsPerformed() and not self:IsWaitTrigger() and self:IsMatchToPerform(groupID, castMoment) then
    return true
  end
  return false
end

function BattlePerformNode:IsValidToPerformByExecId(groupID, ExecId)
  if not self:IsPerforming() and not self:IsPerformed() and not self:IsWaitTrigger() and (self:IsMatchHeadGroupRef(groupID) or self:IsMatchGroup(groupID)) and ExecId > self:GetExecIdx() then
    return true
  end
  return false
end

function BattlePerformNode:IsMatchToPerform(groupID, castMoment)
  if self:IsGroupHead() then
    if castMoment == ProtoEnum.Buffbasetrigger_type.Immediatyly and self:IsMatchGroup(groupID) or (self:IsMatchCastMoment(castMoment) or castMoment == ProtoEnum.Buffbasetrigger_type.Immediatyly) and (self:IsMatchHeadGroupRef(groupID) or self:IsMatchGroup(groupID)) then
      return true
    end
  elseif (self:IsMatchCastMoment(castMoment) or castMoment == ProtoEnum.Buffbasetrigger_type.Immediatyly) and (castMoment == ProtoEnum.Buffbasetrigger_type.OnRoundEnd or self:IsMatchGroup(groupID)) then
    return true
  end
  return false
end

function BattlePerformNode:BeforePlayNotifyGroupHeadNode()
  local GroupHead = self:GetGroupHead()
  if GroupHead ~= self then
    GroupHead:OnBeforeChildNodePlay(self)
  elseif self:GetGroupRef() then
    local cluster = self:GetOwnerCluster()
    local group = cluster and cluster:GetGroupById(self:GetGroupRef())
    if group then
      group.HeadNode:OnBeforeChildNodePlay(self)
    end
  end
end

function BattlePerformNode:Play()
  if not self:IsPerforming() and not self:IsPerformed() then
    self:BeforePlayNotifyGroupHeadNode()
    self.PerformTimeSinceBegin = self.performPlayer.curMsTime
    self.PerformGameTimeSinceBegin = UE4.UGameplayStatics.GetTimeSeconds(UE4Helper.GetCurrentWorld())
    BattlePerformDebug.DebugNodeDoPerform(self)
    self.isPerforming = true
    self.isWaitTrigger = false
    self.performPlayer.FrameStartNodeNum = self.performPlayer.FrameStartNodeNum + 1
    self.performPlayer.CurTriggerNumber = self.performPlayer.CurTriggerNumber + 1
    if _G.GlobalConfig.FastPlay then
      self.IsFastPlay = true
    end
    if self:GetLogicCastMoment() == Base.LogicCastType.ON_PLAYING or self.IsFastPlay then
      self:DoLogic()
    end
    self:DoPerform()
  end
end

function BattlePerformNode:DoPerform()
  if not self.IsPerformOver then
    self.timeoutCounter:Start(self.TimeoutDuration, self, self.OnTimeoutHandle, self.OnTimeoutHandle, true)
    local performHandler
    if self.IsFastPlay then
      performHandler = self.performFastHandler
    else
      performHandler = self.performHandler
    end
    if performHandler[self.performNodeType] then
      self:StopCameraShake()
      performHandler[self.performNodeType](self, self.performInfo)
    else
      self:PerformComplete()
    end
  end
end

function BattlePerformNode:StopCameraShake()
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera and battleCraneCamera:IsCanRotate() then
    battleCraneCamera:StopShake(true)
  end
end

function BattlePerformNode:DoLogic()
  if not self.IsLogicOver then
    BattlePerformDebug.DebugNodeLogicPerform(self)
    self.dataCenter:DoWrite(self.performInfo)
    self:LogicComplete()
  end
end

function BattlePerformNode:DispatchPerformCallback(castMoment, LimitType)
  Log.Debug("BattlePerformNode DispatchPerformCallback", self:GetCastMomentToString())
  if self:IsGroupHead() then
    self.performPlayer:PerformNodeCallback(self, castMoment, LimitType)
    self.OwnerGroup:TriggerNodesByCastMoment(castMoment, LimitType)
  end
  self.LastCast = castMoment
end

function BattlePerformNode:DispatchPerformComplete()
  self.performPlayer:PerformComplete(self)
end

function BattlePerformNode:PerformComplete()
  self.IsPerformOver = true
  if self.IsLogicOver then
    self:PlayComplete()
  else
    self:DoLogic()
  end
end

function BattlePerformNode:LogicComplete()
  self.IsLogicOver = true
  self:ProcessAllEnergyQueue()
  if self.IsPerformOver then
    self:PlayComplete()
  end
end

function BattlePerformNode:OnBeforeChildNodePlay(childNode)
  if not self.isPerforming then
    return
  end
  if self:GetLogicCastMoment() == Base.LogicCastType.ON_BE_COUNTER and childNode:GetExecIdx() > self:GetExecIdx() then
    childNode:DoLogic()
  end
end

function BattlePerformNode:PlayComplete()
  if self.isPerforming then
    self:DoLogic()
    self:DispatchPerformCallback(ProtoEnum.Buffbasetrigger_type.OnAfterAttack)
    self.timeoutCounter:Stop()
    self.isPerformed = true
    self.isPerforming = false
    BattlePerformDebug.DebugNodeCompletePerform(self)
    self.OwnerGroup:NodeCompleteCallBack(self)
    if _G.BattleAutoTest.IsAutoBattle then
      _G.BattleEventCenter:Dispatch(BattleEvent.ROUND_STATE_SELECT)
    end
    self.performPlayer.CurTriggerNumber = 0
  end
end

function BattlePerformNode:ForceDonePerform(reason)
  if reason then
    Log.Error(reason, self:GetNodeIdx())
    local errorMsg = string.format("\233\152\178\229\141\161\230\173\187\239\188\154\232\138\130\231\130\185\232\162\171\229\188\186\229\136\182\232\183\179\232\191\135\239\188\129%s ,\230\151\182\233\151\180:%s, %d %s ", reason, BattleUtils.GetLocalDebugTime(), self:GetNodeIdx(), self:GetProfilerInfo())
    BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
  end
  self:PlayComplete()
end

function BattlePerformNode:SetPerformData(key, value)
  self.performInfo[key] = value
end

function BattlePerformNode:OnTickTimeout(deltaTime)
  if not self.isPerformed and self.isPerforming then
    self.timeoutCounter:OnTick(deltaTime)
  end
end

function BattlePerformNode:OnTimeoutHandle()
  self:ForceDonePerform(BattlePerformNode.ForceDonePerformReason.Timeout .. self.TimeoutDuration)
end

function BattlePerformNode:GetPerformRemainingTime()
  if not self.isPerformed and self.isPerforming then
    return self.timeoutCounter:GetRemainTime()
  end
  return 0
end

function BattlePerformNode:AddTimeoutDuration(value)
  self.timeoutCounter:AddTimeoutValue(value)
end

function BattlePerformNode:GetExecIdx()
  return self:GetInfo().exec_index
end

function BattlePerformNode:IsUnPerform()
  return not self.isPerformed and not self.isPerforming
end

function BattlePerformNode:IsPerformed()
  return self.isPerformed
end

function BattlePerformNode:IsPerforming()
  return self.isPerforming
end

function BattlePerformNode:IsWaitTrigger()
  return self.isWaitTrigger
end

function BattlePerformNode:GetOwnerCluster()
  if self.OwnerGroup then
    return self.OwnerGroup.OwnerCluster
  end
end

function BattlePerformNode:GetGroupNodes()
  if self.OwnerGroup then
    return self.OwnerGroup.GroupNodes
  end
  return {}
end

function BattlePerformNode:GetGroupHead()
  if self.OwnerGroup then
    return self.OwnerGroup.HeadNode
  end
  return self
end

return BattlePerformNode
