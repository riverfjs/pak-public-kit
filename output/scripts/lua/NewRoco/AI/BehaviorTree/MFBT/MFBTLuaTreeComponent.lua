local LuaParamBase = require("NewRoco.AI.BehaviorTree.LuaParams.LuaParamBase")
local LuaIntParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaIntParam")
local LuaFloatParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaFloatParam")
local LuaBoolParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaBoolParam")
local LuaStringParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaStringParam")
local LuaRotatorParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaRotatorParam")
local LuaVectorParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaVectorParam")
local LuaObjectParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaObjectParam")
local LuaEnumParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaEnumParam")
local MFBTLuaNodeData = Class("MFBTLuaNodeData")

function MFBTLuaNodeData:Ctor()
  self.paramNames = {}
end

local MFBTLuaTreeData = Class("MFBTLuaTreeData")

function MFBTLuaTreeData:Ctor()
  self.nodeDataTable = {}
end

local MFBTLuaTreeWrapper = Class("MFBTLuaTreeWrapper")

function MFBTLuaTreeWrapper:Ctor()
  self.nodeTable = {}
end

local MFBTLuaTreeComponent = Class("MFBTLuaTreeComponent")
local _localUE4 = UE4
local _localStrFormat = string.format
local MFBTLuaNodeRegistry = {
  [_localUE4.ERocoBTNodeType.Task] = require("NewRoco.AI.BehaviorTree.MFBT.NodeBase.MFBTLuaNode_TaskBase"),
  [_localUE4.ERocoBTNodeType.Service] = require("NewRoco.AI.BehaviorTree.MFBT.NodeBase.MFBTLuaNode_ServiceBase"),
  [_localUE4.ERocoBTNodeType.Decorator] = require("NewRoco.AI.BehaviorTree.MFBT.NodeBase.MFBTLuaNode_DecoratorBase")
}

function MFBTLuaTreeComponent:Ctor(ownerCtrl)
  self.ownerController = ownerCtrl
end

function MFBTLuaTreeComponent:GetNode(subTreeID, nodeExeID)
  if self.wrapperTable and self.wrapperTable[subTreeID] ~= nil then
    return self.wrapperTable[subTreeID].nodeTable[nodeExeID]
  end
  return nil
end

function MFBTLuaTreeComponent:GetNodeData(subTreeID, nodeExeID)
  if self.dataTable and self.dataTable[subTreeID] ~= nil then
    return self.dataTable[subTreeID].nodeDataTable[nodeExeID]
  end
  return nil
end

function MFBTLuaTreeComponent:GetOwnerController()
  return self.ownerController
end

function MFBTLuaTreeComponent:GetOwnerActor()
  if self.ownerController then
    return self.ownerController.Npc
  end
  return nil
end

function MFBTLuaTreeComponent:OnTreeInit()
  self.wrapperTable = {}
  self.dataTable = {}
end

function MFBTLuaTreeComponent:OnTreeDestroy()
  self:ClearStatus()
end

function MFBTLuaTreeComponent:ClearStatus()
  self.wrapperTable = nil
  self.dataTable = nil
end

function MFBTLuaTreeComponent:OnNodeInstanceCreated(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
  local tree = self:GetSubTreeById(SubtreeID, true)
  if tree.nodeTable[NodeExeID] ~= nil then
    Log.Warning("[MFBTLog] OnNodeInstanceCreated tree.NodeTable[NodeExeID] ~= nil ", SubtreeID, NodeExeID)
    tree.nodeTable[NodeExeID] = nil
  end
  local nodeClass = MFBTLuaNodeRegistry[NodeType]
  if nil == nodeClass then
    Log.Error("[MFBTLog] OnNodeInstanceCreated nodeClass == nil ", NodeType)
    return
  end
  local nodeInstance = nodeClass()
  nodeInstance.ActionName = LuaActionName
  nodeInstance.NodeExeID = NodeExeID
  nodeInstance.ParentTreeID = SubtreeID
  nodeInstance.MFBTLuaComponent = self
  tree.nodeTable[NodeExeID] = nodeInstance
  local clone = true
  local template = _G.MFBTTemplate:GetTree(TreeName)
  if nil == template then
    template = _G.MFBTTemplate:CreateTree(TreeName, MFBTLuaTreeData())
  end
  local createNodeData = template.nodeDataTable[NodeExeID]
  if nil == createNodeData then
    clone = false
    createNodeData = MFBTLuaNodeData()
    self.currentCreateNodeData = createNodeData
  end
  self.dataTable[SubtreeID].nodeDataTable[NodeExeID] = createNodeData
  return clone
end

function MFBTLuaTreeComponent:OnNodeInstanceCreateFinished(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
  local template = _G.MFBTTemplate:GetTree(TreeName)
  template.nodeDataTable[NodeExeID] = self.currentCreateNodeData
  self.currentCreateNodeData = nil
end

function MFBTLuaTreeComponent:OnParamCreateInt(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaIntParam(true), IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:OnParamCreateFloat(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaFloatParam(true), IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:OnParamCreateBool(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaBoolParam(true), IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:OnParamCreateString(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaStringParam(true), IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:OnParamCreateQuaternion(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  local instance = self:CommonCreateParam(LuaRotatorParam(true), IsArray, ParamName, UE4.FQuat(Value.X, Value.Y, Value.Z, Value.W), IsUseBlackboard, BlackboardKey)
  if instance and instance.value then
    instance.value = instance.value:ToRotator()
  end
end

function MFBTLuaTreeComponent:OnParamCreateVector(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaVectorParam(true), IsArray, ParamName, UE4.FVector(Value.X, Value.Y, Value.Z), IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:OnParamCreateObject(IsArray, ParamName, IsUseBlackboard, BlackboardKey)
  self:CommonCreateParam(LuaObjectParam(true), IsArray, ParamName, nil, IsUseBlackboard, BlackboardKey)
end

function MFBTLuaTreeComponent:CommonCreateParam(ParamInstance, IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  local curNodeData = self.currentCreateNodeData
  if not curNodeData then
    return
  end
  self:CopyParamValue(ParamInstance, ParamName, Value, IsUseBlackboard, BlackboardKey)
  if IsArray then
    self:CreateArrayIfNil(ParamName)
    table.insert(curNodeData[ParamName], ParamInstance)
  elseif self:CheckParamNil(curNodeData, ParamName) then
    curNodeData[ParamName] = ParamInstance
    table.insert(curNodeData.paramNames, ParamName)
  end
  return ParamInstance
end

function MFBTLuaTreeComponent:CreateArrayIfNil(ParamName)
  local curNodeData = self.currentCreateNodeData
  if nil == curNodeData[ParamName] then
    curNodeData[ParamName] = {}
    table.insert(curNodeData.paramNames, ParamName)
  end
end

function MFBTLuaTreeComponent:CheckParamNil(curNodeData, ParamName)
  if nil == curNodeData[ParamName] then
    return true
  else
    Log.Warning(_localStrFormat("[MFBTLog] param exist paramName:%s", ParamName))
    return false
  end
end

function MFBTLuaTreeComponent:CopyParamValue(target, ParamName, Value, IsUseBlackboard, BlackboardKey)
  target.paramName = ParamName
  target.useBlackboardKey = IsUseBlackboard
  target.key = BlackboardKey
  target.value = Value
end

function MFBTLuaTreeComponent:OnBTTaskStart(SubtreeID, NodeExeID, LuaFileName)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnTaskStart then
    node:OnTaskStart()
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTTaskStart Failed at %d, %d: %s", SubtreeID, NodeExeID, LuaFileName)
  end
end

function MFBTLuaTreeComponent:OnBTTaskTick(SubtreeID, NodeExeID, LuaFileName, Deltatime)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnTaskTick then
    node:OnTaskTick(Deltatime)
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTTaskTick Failed at %d, %d: %s", SubtreeID, NodeExeID, LuaFileName)
  end
end

function MFBTLuaTreeComponent:OnBTTaskInterrupt(SubtreeID, NodeExeID, ...)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnTaskEnd then
    node:OnTaskEnd(...)
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTTaskInterrupt Failed at %d, %d", SubtreeID, NodeExeID)
  end
end

function MFBTLuaTreeComponent:OnBTServiceStart(SubtreeID, NodeExeID, LuaFileName, ...)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnServiceStart then
    node:OnServiceStart(...)
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTServiceStart Failed at %d, %d: %s", SubtreeID, NodeExeID, LuaFileName)
  end
end

function MFBTLuaTreeComponent:OnBTServiceTick(SubtreeID, NodeExeID, LuaFileName, Deltatime)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnServiceTick then
    node:OnServiceTick(Deltatime)
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTServiceTick Failed at %d, %d: %s", SubtreeID, NodeExeID, LuaFileName)
  end
end

function MFBTLuaTreeComponent:OnBTServiceEnd(SubtreeID, NodeExeID, ...)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.OnServiceEnd then
    node:OnServiceEnd(...)
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTServiceEnd Failed at %d, %d", SubtreeID, NodeExeID)
  end
end

function MFBTLuaTreeComponent:OnBTDecoratorCalc(SubtreeID, NodeExeID, LuaFileName)
  local node = self:GetNode(SubtreeID, NodeExeID)
  if node and node.PerformConditionCheck then
    return node:PerformConditionCheck()
  else
    Log.PrintScreenMsg("[MFBT]  MFBTLuaTreeComponent:OnBTDecoratorCalc Failed at %d, %d: %s", SubtreeID, NodeExeID, LuaFileName)
  end
  return false
end

function MFBTLuaTreeComponent:GetSubTreeById(treeId, autoGenerated)
  if not self.wrapperTable then
    Log.Warning("MFBTLuaTreeComponent:GetSubTreeById wrapperTable is nil")
    self.wrapperTable = {}
    self.dataTable = {}
  end
  local ret = self.wrapperTable[treeId]
  if nil == ret and autoGenerated then
    self.wrapperTable[treeId] = MFBTLuaTreeWrapper()
    self.dataTable[treeId] = MFBTLuaTreeData()
    ret = self.wrapperTable[treeId]
  end
  return ret
end

return MFBTLuaTreeComponent
