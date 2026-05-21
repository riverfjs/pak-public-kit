local Base = require("NewRoco.AI.BehaviorTree.LuaParams.LuaParamBase")
local LuaParamType = require("NewRoco.AI.BehaviorTree.LuaParams.LuaParamType")
local LuaObjectParam = Base:Extend("LuaObjectParam")

function LuaObjectParam:Ctor(enableMFBT)
  Base.Ctor(self, enableMFBT)
  self.type = LuaParamType.Object
end

function LuaObjectParam:GetValue(AIController)
  if not self.useBlackboardKey then
    return self.value
  end
  if not AIController then
    return nil
  end
  if AIController.GetBlackboardValue then
    return AIController:GetBlackboardValue(self.key, self.isMFBTEnable)
  end
  if AIController.LocalGlobalConfig.BTreeUseLuaBlackboard then
    local Value = AIController.LuaBTBlackboard[self.key]
    if nil ~= Value then
      return Value
    else
      return nil
    end
  elseif self.isMFBTEnable then
    local object = AIController:GetMfbbObject(self.key)
    return object and object:IsA(UE.APawn) and object.sceneCharacter
  else
    return AIController.Blackboard:GetValueAsObject(self.key)
  end
end

function LuaObjectParam:SetValue(AIController, Value)
  if not self.useBlackboardKey then
    local NpcName = "nil"
    if AIController and AIController.Npc then
      NpcName = AIController.Npc.config.name
    end
    Log.WarningFormat("LuaParam: Cant Set Value For Not BlackboardType, Name:%s, NpcName:%s", tostring(self.paramName), NpcName)
    return
  end
  if not AIController then
    return Log.Trace("LuaParam: Invalid ai controller")
  end
  if AIController.LocalGlobalConfig.BTreeUseLuaBlackboard then
    AIController.LuaBTBlackboard[self.key] = Value
  end
  if self.isMFBTEnable then
    if AIController.LocalGlobalConfig.MFBTUpdateBlackboardValueToCpp then
      if Value then
        AIController:SetBlackboardObjectInCPP(self.key, Value.viewObj, self.isMFBTEnable)
      else
        AIController:SetBlackboardObjectInCPP(self.key, nil, self.isMFBTEnable)
      end
    end
  elseif not AIController.LocalGlobalConfig.BTreeUseLuaBlackboard or AIController.LocalGlobalConfig.BTreeDebugCppBlackboard then
    AIController.Blackboard:SetValueAsObject(self.key, Value)
  end
end

function LuaObjectParam:SetValueById(AIController, actorId)
  if not self.useBlackboardKey then
    local NpcName = "nil"
    if AIController and AIController.Npc then
      NpcName = AIController.Npc.config.name
    end
    Log.WarningFormat("LuaParam: Cant Set Value For Not BlackboardType, Name:%s, NpcName:%s", tostring(self.paramName), NpcName)
    return
  end
  if not AIController then
    return Log.Trace("LuaParam: Invalid ai controller")
  end
  if self.isMFBTEnable then
    AIController:SetMfbbObjectId(self.key, actorId or 0)
  end
end

function LuaObjectParam:GetType()
  return LuaParamType.Object
end

return LuaObjectParam
