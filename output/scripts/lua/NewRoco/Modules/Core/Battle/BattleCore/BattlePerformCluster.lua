local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local PriorityQueue = require("Utils.PriorityQueue")
local BattlePerformCluster = NRCClass:Extend("BattlePerformCluster")

function BattlePerformCluster:Ctor(performPlayer)
  self.ClusterGroups = {}
  self.performPlayer = performPlayer
  self.NeedPerformGroupCount = 0
  self.IsPerforming = false
  self.IsPerformed = false
  self.IsCompleteCallBack = false
  self.IsFinalize = false
  self.FriendlyClusters = {}
  self.keepOrderClusters = {}
  self.ServerExecuteQueue = PriorityQueue()
  self.ClusterStartTime = performPlayer.roundStartTime
end

function BattlePerformCluster:Reset()
  self.ClusterGroups = nil
  self.performPlayer = nil
  self.HeadGroup = nil
  self.IsPerforming = false
  self.IsPerformed = false
  self.IsCompleteCallBack = false
  self.FriendlyClusters = {}
  self.keepOrderClusters = {}
  self.ServerExecuteQueue:Clear()
  self.groupDelayID = _G.DelayManager:CancelDelayByIdEx(self.groupDelayID)
  self.d_PlayGroup = _G.DelayManager:CancelDelayByIdEx(self.d_PlayGroup)
end

function BattlePerformCluster:AddKeepServerOrderCluster(cluster)
  if not cluster then
    return
  end
  if cluster == self then
    return
  end
  if table.contains(self.keepOrderClusters, cluster) then
    return
  end
  table.insert(self.keepOrderClusters, cluster)
  cluster:AddOrRemoveFriendlyCluster(self, true)
  self:AddClusterInServerExecuteQueue(cluster)
end

function BattlePerformCluster:RemoveKeepServerOrderCluster(cluster)
  if not cluster then
    return
  end
  if not table.contains(self.keepOrderClusters, cluster) then
    return
  end
  table.removeValue(self.keepOrderClusters, cluster)
  cluster:AddOrRemoveFriendlyCluster(self, false)
  if #cluster.keepOrderClusters > 0 then
    self:RemoveClusterInServerExecuteQueue(cluster)
  else
    self.ServerExecuteQueue:Clear()
  end
end

function BattlePerformCluster:AddOrRemoveFriendlyCluster(cluster, isAdd)
  if not cluster then
    return
  end
  if isAdd then
    if table.contains(self.FriendlyClusters, cluster) then
      return
    end
    table.insert(self.FriendlyClusters, cluster)
  else
    table.removeValue(self.FriendlyClusters, cluster)
  end
end

function BattlePerformCluster:AddGroup(PerformGroup, changeRef, RefValue)
  if PerformGroup and not table.contains(self.ClusterGroups, PerformGroup) then
    PerformGroup.OwnerCluster = self
    table.insert(self.ClusterGroups, PerformGroup)
    if not PerformGroup.HeadNode:GetGroupRef() or PerformGroup.HeadNode:IsCopeSkill() then
      self.HeadGroup = PerformGroup
    end
    if changeRef and self.HeadGroup then
      RefValue = RefValue or self.HeadGroup.GroupId
      if not self:GetGroupById(RefValue) then
        Log.Error("zgx BattlePerformCluster:AddGroup", "RefValue is not exist")
        RefValue = self.HeadGroup.GroupId
      end
      PerformGroup.HeadNode:SetGroupRef(RefValue)
    end
    self.NeedPerformGroupCount = self.NeedPerformGroupCount + 1
    for i = 1, #PerformGroup.GroupNodes do
      PerformGroup.GroupNodes[i].ClusterId = self.ClusterId
    end
    for _, v in ipairs(self.FriendlyClusters) do
      if table.contains(v.keepOrderClusters, self) then
        v:AddGroupInServerExecuteQueue(PerformGroup)
      end
    end
  end
end

function BattlePerformCluster:RemoveGroup(PerformGroup)
  if PerformGroup and table.contains(self.ClusterGroups, PerformGroup) then
    PerformGroup.OwnerCluster = nil
    table.removeValue(self.ClusterGroups, PerformGroup)
    self.NeedPerformGroupCount = self.NeedPerformGroupCount - 1
    for i = 1, #PerformGroup.GroupNodes do
      PerformGroup.GroupNodes[i].ClusterId = -1
    end
    for _, v in ipairs(self.FriendlyClusters) do
      if table.contains(v.keepOrderClusters, self) then
        v:RemoveGroupInServerExecuteQueue(PerformGroup)
      end
    end
  end
end

function BattlePerformCluster:GetGroupById(groupId)
  if groupId then
    for _, v in ipairs(self.ClusterGroups) do
      if v.GroupId == groupId then
        return v
      end
    end
  end
end

function BattlePerformCluster:GetNeedPerformNodeNumber()
  local TriggerNodeNumber = 0
  for _, v in ipairs(self.ClusterGroups) do
    TriggerNodeNumber = TriggerNodeNumber + v.NeedPerformNodeCount
  end
  return TriggerNodeNumber
end

function BattlePerformCluster:Play(deltaTime, deltaFrames)
  if not self.IsPerforming and not self.IsPerformed then
    self.ClusterStartTime = os.msTime()
    self.IsPerforming = true
    self.IsPerformed = false
    BattlePerformDebug.DebugClusterStart(self)
    self.performPlayer.performingClusterCount = self.performPlayer.performingClusterCount + 1
    if self.NeedPerformGroupCount > 0 then
      local nextClusterNode = self.HeadGroup.HeadNode
      local castmoment = nextClusterNode:GetCastMoment()
      if castmoment == ProtoEnum.Buffbasetrigger_type.OnCounterEnd then
        deltaFrames = BattleConst.Show.CounterRestartLastSkillDelayFrame
      end
      Log.Debug("zgx BattlePerformCluster PlayCluster", "cid:", self.performPlayer.performClusterIdxCur, "clen:", #self.performPlayer.PerformClusterLst, "nodeidx:", nextClusterNode:GetNodeIdx())
      if deltaFrames then
        _G.DelayManager:CancelDelayByIdEx(self.d_PlayGroup)
        self.d_PlayGroup = _G.DelayManager:DelayFrames(deltaFrames, self.PlayGroup, self, self.HeadGroup)
      elseif deltaTime > 0 then
        _G.DelayManager:CancelDelayByIdEx(self.d_PlayGroup)
        self.d_PlayGroup = _G.DelayManager:DelaySeconds(deltaTime, self.PlayGroup, self, self.HeadGroup)
      else
        self:PlayGroupDelay(self.HeadGroup)
      end
    else
      Log.Error("zgx error cluster is empty!!", "cid:", self.performPlayer.performClusterIdxCur, "clen:", #self.performPlayer.PerformClusterLst)
      self:PlayComplete()
    end
  end
end

function BattlePerformCluster:PlayGroupDelay(group)
  if group.OwnerCluster == self then
    self.groupDelayID = DelayManager:DelayFrames(1, function()
      self.groupDelayID = nil
      if self.IsFinalize then
        return
      end
      group:Play()
    end)
  end
end

function BattlePerformCluster:PlayGroup(group)
  if self.IsFinalize then
    return
  end
  if group.OwnerCluster == self then
    group:Play()
  end
end

function BattlePerformCluster:GetWillTriggerGroupsByExecId(group, ExecId, LimitType)
  local triggerNodes = {}
  for _, n in ipairs(self.ClusterGroups) do
    if (nil == LimitType or n.HeadNode.performNodeType == LimitType) and n ~= group and n.HeadNode:IsValidToPerformByExecId(group.GroupId, ExecId) then
      table.insert(triggerNodes, n.HeadNode)
    end
  end
  return triggerNodes
end

function BattlePerformCluster:GetWillTriggerGroupsByCastMoment(group, castMoment, LimitType)
  local triggerNodes = {}
  for _, n in ipairs(self.ClusterGroups) do
    if (nil == LimitType or n.HeadNode.performNodeType == LimitType) and n ~= group and n.HeadNode:IsValidToPerform(group.GroupId, castMoment) then
      table.insert(triggerNodes, n.HeadNode)
    end
  end
  return triggerNodes
end

function BattlePerformCluster:GroupCompleteCallBack(overGroup)
  if not self.IsFinalize then
    if not overGroup.IsCompleteCallBack then
      overGroup.IsCompleteCallBack = true
      self.NeedPerformGroupCount = self.NeedPerformGroupCount - 1
    end
    if 0 == self.NeedPerformGroupCount then
      self:PlayComplete()
    else
      local refGroup = self:GetGroupById(overGroup.HeadNode:GetGroupRef())
      if refGroup and refGroup.IsPerforming then
        refGroup:TryTriggerNextAfterNodeComplete(overGroup.HeadNode)
      else
        self:CheckGroupStuck()
      end
    end
  end
end

function BattlePerformCluster:CheckGroupStuck()
  for _, v in ipairs(self.ClusterGroups) do
    if v.IsPerforming then
      return
    end
  end
  self:ForcePlayNext()
end

function BattlePerformCluster:ForcePlayNext()
  local forceGroup
  for _, v in ipairs(self.ClusterGroups) do
    if not v.IsPerforming and not v.IsPerformed then
      if not forceGroup then
        forceGroup = v
      elseif v.HeadNode:GetExecIdx() < forceGroup.HeadNode:GetExecIdx() then
        forceGroup = v
      end
    end
  end
  if forceGroup then
    local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\231\142\176\229\156\168\229\188\186\229\136\182\230\146\173\230\148\190\229\144\140\228\184\128\228\184\170Cluster\228\184\139\231\154\132\229\133\182\228\187\150group:" .. forceGroup.GroupId
    Log.Error(errorMsg)
    BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
    self:PlayGroupDelay(forceGroup)
  else
    local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\229\143\175\232\131\189\230\149\176\230\141\174\231\187\159\232\174\161\233\148\153\232\175\175,\231\142\176\229\156\168\229\188\186\229\136\182\231\187\147\230\157\159Cluster" .. self.NeedPerformGroupCount
    Log.Error(errorMsg)
    BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
    self:PlayComplete()
  end
end

function BattlePerformCluster:PlayComplete()
  if self.IsPerforming and not self.IsPerformed then
    self.IsPerforming = false
    self.IsPerformed = true
    BattlePerformDebug.DebugClusterStop(self)
    self.performPlayer:ClusterCompleteCallBack(self)
  end
end

function BattlePerformCluster:DoFinalize()
  self.IsFinalize = true
  if self.ClusterGroups then
    for _, group in ipairs(self.ClusterGroups) do
      if group.IsPerforming then
        group:DoFinalize()
      end
    end
  end
  self.d_PlayGroup = _G.DelayManager:CancelDelayByIdEx(self.d_PlayGroup)
end

function BattlePerformCluster:AddClusterInServerExecuteQueue(cluster)
  if 0 == #self.keepOrderClusters then
    return
  end
  if not cluster then
    return
  end
  if not cluster.HeadGroup then
    return
  end
  for _, group in ipairs(cluster.ClusterGroups or {}) do
    self:AddGroupInServerExecuteQueue(group)
  end
end

function BattlePerformCluster:AddGroupInServerExecuteQueue(group)
  if 0 == #self.keepOrderClusters then
    return
  end
  if not group then
    return
  end
  if not group.OwnerCluster then
    return
  end
  for _, node in ipairs(group.GroupNodes or {}) do
    if not node.isPerformed then
      self:AddNodeInServerExecuteQueue(node)
    end
  end
end

function BattlePerformCluster:AddNodeInServerExecuteQueue(node)
  if 0 == #self.keepOrderClusters then
    return
  end
  if not node then
    return
  end
  local nodeExecIdx = node:GetExecIdx()
  if not self.ServerExecuteQueue:Contains(nodeExecIdx) then
    self.ServerExecuteQueue:EnQueue(nodeExecIdx)
  end
end

function BattlePerformCluster:RemoveClusterInServerExecuteQueue(cluster)
  if not cluster then
    return
  end
  if not cluster.HeadGroup then
    return
  end
  for _, group in ipairs(cluster.ClusterGroups or {}) do
    self:RemoveGroupInServerExecuteQueue(group)
  end
end

function BattlePerformCluster:RemoveGroupInServerExecuteQueue(group)
  if not group then
    return
  end
  for _, node in ipairs(group.GroupNodes or {}) do
    self:RemoveNodeInServerExecuteQueue(node)
  end
end

function BattlePerformCluster:RemoveNodeInServerExecuteQueue(node)
  if 0 == #self.keepOrderClusters then
    return
  end
  if not node then
    return
  end
  local nodeExecIdx = node:GetExecIdx()
  local top = self.ServerExecuteQueue:GetTop()
  self.ServerExecuteQueue:Remove(nodeExecIdx)
  if top == nodeExecIdx then
    for _, group in ipairs(self.ClusterGroups) do
      if group.IsBlockByServerExecute then
        group:TriggerNext()
      end
    end
  end
end

function BattlePerformCluster:CheckCanPlayNode(node)
  if self.ServerExecuteQueue:Size() <= 0 then
    return true
  end
  if not node then
    return true
  end
  if self.HeadGroup then
    local clusterHead = self.HeadGroup.HeadNode
    if clusterHead and (node == clusterHead or clusterHead:IsUnPerform()) then
      return true
    end
  end
  local topExecIdx = self.ServerExecuteQueue:GetTop()
  if topExecIdx < node:GetExecIdx() then
    if self:CheckDeadLockForExecIdx(topExecIdx) then
      Log.Error("zgx Has DeadLock!!!!")
      return true
    end
    return false
  end
  return true
end

function BattlePerformCluster:CheckDeadLockForExecIdx(ExecIdx)
  local targetNode = self.performPlayer:GetNodeByExecId(ExecIdx)
  if not targetNode then
    return true
  end
  local Visited = {self}
  local NextCluster = targetNode.OwnerGroup and targetNode.OwnerGroup.OwnerCluster
  while NextCluster do
    if table.contains(Visited, NextCluster) then
      return true
    end
    table.insert(Visited, NextCluster)
    local HeadGroup = NextCluster.HeadGroup
    if HeadGroup then
      if HeadGroup.IsPerforming then
        for _, group in ipairs(NextCluster.ClusterGroups) do
          if group.IsBlockByServerExecute then
            return true
          end
        end
        return false
      else
        local refGroupId = HeadGroup.HeadNode and HeadGroup.HeadNode:GetGroupRef()
        if refGroupId then
          local refGroup = self.performPlayer:GetGroupData(refGroupId)
          if refGroup then
            NextCluster = refGroup.OwnerCluster
          else
            return true
          end
        else
          return true
        end
      end
    else
      return true
    end
  end
  return true
end

function BattlePerformCluster:CheckBlockByServerExecute()
  if self.ClusterGroups then
    for _, group in ipairs(self.ClusterGroups) do
      if group.IsBlockByServerExecute then
        return true
      end
    end
  end
  return false
end

function BattlePerformCluster:AddNodesToTriggerByExecIdForKeepOrderCluster(ExecId, LimitType)
  if self.keepOrderClusters then
    for _, cluster in ipairs(self.keepOrderClusters) do
      if cluster.HeadGroup.IsPerforming then
        cluster.HeadGroup:AddNodesToTriggerByExecId(ExecId, LimitType)
        cluster.HeadGroup:TriggerNext()
      end
    end
  end
end

return BattlePerformCluster
