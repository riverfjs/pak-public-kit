local BattlePerformGroup = _G.MakeSimpleClass("BattlePerformGroup")

function BattlePerformGroup:Ctor(group_id)
  self.GroupNodes = {}
  self.GroupId = group_id
  self.IsPerforming = false
  self.IsPerformed = false
  self.NeedPerformNodeCount = 0
  self.IsCompleteCallBack = false
  self.WillTriggerNodes = {}
  self.CurTriggerNode = nil
  self.IsFinalize = false
  self.d_TriggerNext = nil
  self.IsProcessCounter = false
  self.StartRecordExecIdx = false
  self.RecordMinExecIdx = -1
  self.IsBlockByServerExecute = false
end

function BattlePerformGroup:Reset()
  self.GroupNodes = {}
  self.OwnerCluster = nil
  self.HeadNode = nil
  self.IsPerforming = false
  self.IsPerformed = false
  self.NeedPerformNodeCount = 0
  self.IsCompleteCallBack = false
  self.WillTriggerNodes = {}
  self.CurTriggerNode = nil
  self.IsProcessCounter = false
  self.IsBlockByServerExecute = false
  self.d_TriggerNext = _G.DelayManager:CancelDelayByIdEx(self.d_TriggerNext)
  self.StartRecordExecIdx = false
  self.RecordMinExecIdx = -1
end

function BattlePerformGroup:AddNode(PerformNode)
  if PerformNode and not table.contains(self.GroupNodes, PerformNode) then
    PerformNode.OwnerGroup = self
    table.insert(self.GroupNodes, PerformNode)
    if PerformNode:IsGroupHead() or not self.HeadNode then
      self.HeadNode = PerformNode
    end
    PerformNode:SetGroupID(self.GroupId)
    self.NeedPerformNodeCount = self.NeedPerformNodeCount + 1
    if self.OwnerCluster then
      for _, v in ipairs(self.OwnerCluster.FriendlyClusters) do
        if table.contains(v.keepOrderClusters, self.OwnerCluster) then
          v:AddNodeInServerExecuteQueue(PerformNode)
        end
      end
    end
  end
end

function BattlePerformGroup:RemoveNode(PerformNode)
  if PerformNode and PerformNode ~= self.HeadNode and not PerformNode:IsGroupHead() and table.contains(self.GroupNodes, PerformNode) then
    PerformNode.OwnerGroup = nil
    table.removeValue(self.GroupNodes, PerformNode)
    self.NeedPerformNodeCount = self.NeedPerformNodeCount - 1
    if self.OwnerCluster then
      for _, v in ipairs(self.OwnerCluster.FriendlyClusters) do
        if table.contains(v.keepOrderClusters, self.OwnerCluster) then
          v:RemoveNodeInServerExecuteQueue(PerformNode)
        end
      end
    end
  end
end

function BattlePerformGroup:Play()
  if not self.IsPerforming and not self.IsPerformed then
    self.IsPerforming = true
    self.IsPerformed = false
    BattlePerformDebug.DebugGroupStart(self)
    self.OwnerCluster:RemoveNodeInServerExecuteQueue(self.HeadNode)
    self:TriggerNodesByCastMoment(ProtoEnum.Buffbasetrigger_type.OnBeforeAttack)
  end
end

function BattlePerformGroup:GetWillTriggerNodesByExecId(ExecId, LimitType)
  local triggerNodes = {}
  for _, n in ipairs(self.GroupNodes) do
    if (nil == LimitType or n.performNodeType == LimitType) and n ~= self.HeadNode and n:IsValidToPerformByExecId(self.GroupId, ExecId) then
      table.insert(triggerNodes, n)
    end
  end
  return triggerNodes
end

function BattlePerformGroup:GetWillTriggerNodesByCastMoment(castMoment, LimitType)
  local triggerNodes = {}
  for _, n in ipairs(self.GroupNodes) do
    if (nil == LimitType or n.performNodeType == LimitType) and n ~= self.HeadNode and n:IsValidToPerform(self.GroupId, castMoment) then
      table.insert(triggerNodes, n)
    end
  end
  return triggerNodes
end

function BattlePerformGroup:StartRecord()
  self.StartRecordExecIdx = true
  self.RecordMinExecIdx = -1
end

function BattlePerformGroup:StopRecord()
  self.StartRecordExecIdx = false
end

function BattlePerformGroup:AddNodesToTriggerByExecId(ExecId, LimitType)
  local triggerNodes = self:GetWillTriggerNodesByExecId(ExecId, LimitType)
  local triggerGroupNodes = self.OwnerCluster:GetWillTriggerGroupsByExecId(self, ExecId, LimitType)
  for i = 1, #triggerNodes do
    triggerNodes[i].isWaitTrigger = true
    table.insert(self.WillTriggerNodes, triggerNodes[i])
    if self.StartRecordExecIdx and (-1 == self.RecordMinExecIdx or self.RecordMinExecIdx > triggerNodes[i]:GetExecIdx()) then
      self.RecordMinExecIdx = triggerNodes[i]:GetExecIdx()
    end
  end
  for i = 1, #triggerGroupNodes do
    triggerGroupNodes[i].isWaitTrigger = true
    table.insert(self.WillTriggerNodes, triggerGroupNodes[i])
    if self.StartRecordExecIdx and (-1 == self.RecordMinExecIdx or self.RecordMinExecIdx > triggerGroupNodes[i]:GetExecIdx()) then
      self.RecordMinExecIdx = triggerGroupNodes[i]:GetExecIdx()
    end
  end
  table.sort(self.WillTriggerNodes, function(a, b)
    return a:GetExecIdx() < b:GetExecIdx()
  end)
end

function BattlePerformGroup:TriggerNodesByCastMoment(castMoment, LimitType)
  local triggerNodes = self:GetWillTriggerNodesByCastMoment(castMoment, LimitType)
  local triggerGroupNodes = self.OwnerCluster:GetWillTriggerGroupsByCastMoment(self, castMoment, LimitType)
  for i = 1, #triggerNodes do
    triggerNodes[i].isWaitTrigger = true
    table.insert(self.WillTriggerNodes, triggerNodes[i])
    if self.StartRecordExecIdx and (-1 == self.RecordMinExecIdx or self.RecordMinExecIdx > triggerNodes[i]:GetExecIdx()) then
      self.RecordMinExecIdx = triggerNodes[i]:GetExecIdx()
    end
  end
  for i = 1, #triggerGroupNodes do
    triggerGroupNodes[i].isWaitTrigger = true
    table.insert(self.WillTriggerNodes, triggerGroupNodes[i])
    if self.StartRecordExecIdx and (-1 == self.RecordMinExecIdx or self.RecordMinExecIdx > triggerGroupNodes[i]:GetExecIdx()) then
      self.RecordMinExecIdx = triggerGroupNodes[i]:GetExecIdx()
    end
  end
  table.sort(self.WillTriggerNodes, function(a, b)
    return a:GetExecIdx() < b:GetExecIdx()
  end)
  self:TriggerNext()
end

function BattlePerformGroup:TriggerNext()
  if self.IsFinalize then
    return
  end
  if self.OwnerCluster and not self.OwnerCluster.performPlayer:CanTriggerNext() then
    _G.DelayManager:CancelDelayByIdEx(self.d_TriggerNext)
    self.d_TriggerNext = DelayManager:DelayFrames(1, function()
      self.d_TriggerNext = nil
      self:TriggerNext()
    end)
    return
  end
  if not self.CurTriggerNode and not self.IsFinalize then
    if #self.WillTriggerNodes > 0 then
      if self.OwnerCluster:CheckCanPlayNode(self.WillTriggerNodes[1]) then
        self.IsBlockByServerExecute = false
        self.CurTriggerNode = self.WillTriggerNodes[1]
        table.remove(self.WillTriggerNodes, 1)
        if self.CurTriggerNode.OwnerGroup == self then
          self:PlayNode(self.CurTriggerNode)
        else
          self.OwnerCluster:PlayGroupDelay(self.CurTriggerNode.OwnerGroup)
        end
      else
        self.OwnerCluster:AddNodeInServerExecuteQueue(self.WillTriggerNodes[1])
        self.IsBlockByServerExecute = true
      end
    elseif not self.HeadNode:IsPerformed() and not self.HeadNode:IsPerforming() then
      self:PlayNode(self.HeadNode)
    else
      self:CheckGroupOver()
    end
  end
end

function BattlePerformGroup:PlayNode(node)
  if node and node.OwnerGroup == self then
    local _, err, _ = tcallForBattle(node, node.Play, false)
    if err then
      local errorMsg = string.format("zgx\233\152\178\229\141\161\230\173\187\239\188\154%s \232\138\130\231\130\185\230\146\173\230\148\190\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129\239\188\129\229\188\186\229\136\182\232\183\179\232\191\135\232\138\130\231\130\185\232\161\168\230\188\148\239\188\129\239\188\129\239\188\129 ErrorInfo:%s", node:GetProfilerInfo(), err)
      Log.Error(errorMsg)
      BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
      self.HeadNode:ForceDonePerform()
    end
  else
    self:CheckGroupOver()
  end
end

function BattlePerformGroup:TryTriggerNextAfterNodeComplete(node)
  if self.CurTriggerNode and self.CurTriggerNode == node then
    self.CurTriggerNode = nil
    self:TriggerNext()
  end
end

function BattlePerformGroup:AutoTriggerAllNodes()
  self:TriggerNodesByCastMoment(ProtoEnum.Buffbasetrigger_type.Immediatyly)
end

function BattlePerformGroup:NodeCompleteCallBack(overNode)
  if not self.IsFinalize then
    if not overNode.IsCompleteCallBack then
      overNode.IsCompleteCallBack = true
      self.NeedPerformNodeCount = self.NeedPerformNodeCount - 1
    end
    if overNode == self.HeadNode then
      self:AutoTriggerAllNodes()
    else
      self:TryTriggerNextAfterNodeComplete(overNode)
    end
    if not self:CheckGroupOver() then
      self:CheckGroupStuck()
    end
    for _, v in ipairs(self.OwnerCluster.FriendlyClusters) do
      if table.contains(v.keepOrderClusters, self.OwnerCluster) then
        v:RemoveNodeInServerExecuteQueue(overNode)
      end
    end
    self.OwnerCluster:RemoveNodeInServerExecuteQueue(overNode)
  end
end

function BattlePerformGroup:CheckGroupStuck()
  if not self.HeadNode.isPerforming and not self.CurTriggerNode and not self.IsBlockByServerExecute and not self.d_TriggerNext then
    self:ForcePlayNext()
  end
end

function BattlePerformGroup:ForcePlayNext()
  if #self.WillTriggerNodes > 0 then
    local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140BattlePerformGroup\231\154\132\233\128\187\232\190\145\233\148\153\232\175\175\239\188\140\229\135\186\231\142\176trigger\233\152\159\229\136\151\228\184\173\230\150\173\231\154\132\230\131\133\229\134\181\239\188\129"
    Log.Error(errorMsg)
    BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
    self:TriggerNext()
  else
    local forceNode
    for _, v in ipairs(self.GroupNodes) do
      if not v.isPerforming and not v.isPerformed then
        if not forceNode then
          forceNode = v
        elseif v:GetExecIdx() < forceNode:GetExecIdx() then
          forceNode = v
        end
      end
    end
    if forceNode then
      local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\231\142\176\229\156\168\229\188\186\229\136\182\230\146\173\230\148\190\229\144\140\228\184\128\228\184\170Group\228\184\139\231\154\132\229\133\182\228\187\150\232\138\130\231\130\185:" .. forceNode:GetNodeIdx()
      Log.Error(errorMsg)
      BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
      self:PlayNode(forceNode)
    else
      local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\229\143\175\232\131\189\230\149\176\230\141\174\231\187\159\232\174\161\233\148\153\232\175\175,\231\142\176\229\156\168\229\188\186\229\136\182\231\187\147\230\157\159Group :" .. (self.NeedPerformNodeCount or "nil!!")
      Log.Error(errorMsg)
      BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
      self:PlayComplete()
    end
  end
end

function BattlePerformGroup:CheckGroupOver()
  if 0 == self.NeedPerformNodeCount and 0 == #self.WillTriggerNodes and not self.CurTriggerNode then
    self:PlayComplete()
    return true
  end
  return false
end

function BattlePerformGroup:PlayComplete()
  if self.IsPerforming and not self.IsPerformed then
    self.IsPerforming = false
    self.IsPerformed = true
    BattlePerformDebug.DebugGroupStop(self)
    self.OwnerCluster:GroupCompleteCallBack(self)
  end
end

function BattlePerformGroup:DoFinalize()
  self.IsFinalize = true
  self.WillTriggerNodes = {}
  if self.GroupNodes then
    for _, node in ipairs(self.GroupNodes) do
      if node.isPerforming then
        node:PlayComplete()
      end
    end
  end
  self.d_TriggerNext = _G.DelayManager:CancelDelayByIdEx(self.d_TriggerNext)
end

function BattlePerformGroup:PrintAllNodeState()
  for k, v in pairs(self.GroupNodes) do
    if not v.isPerformed then
      Log.Error(v:GetNodeIdx(), v.isPerformed)
    end
  end
end

return BattlePerformGroup
