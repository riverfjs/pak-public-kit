local Class = _G.MakeSimpleClass
local FsmVar = require("NewRoco.Modules.Core.Fsm.FsmVar")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local FsmBaseObject = Class("FsmBaseObject", nil, 128)
FsmBaseObject:SetMemberCount(2)

function FsmBaseObject:Ctor(name, properties)
  self.name = name
  self.properties = properties
end

function FsmBaseObject:SetName(name)
  self.name = name
  return self
end

function FsmBaseObject:GetName()
  return self.name
end

function FsmBaseObject:SetProperties(NewProperties)
  self.properties = NewProperties
  return self
end

function FsmBaseObject:GetProperties()
  return self.properties
end

function FsmBaseObject:GetProperty(name, default)
  local Property = FsmUtils.GetProperty(self, name, default)
  return FsmVar.Resolve(Property, default)
end

function FsmBaseObject:SetProperty(name, value)
  local Property = FsmUtils.GetProperty(self, name)
  if Property and type(Property) == "table" and Property.InstanceOf and Property:InstanceOf(FsmVar) then
    Property:Set(value)
    return
  end
  FsmUtils.SetProperty(self, name, value)
end

function FsmBaseObject:CreateVar(name, value)
  self:SetProperty(name, value)
  return FsmVar.CreateVar(name, self.properties)
end

function FsmBaseObject:SetAsVar(VarObject, name)
  if not VarObject then
    return
  end
  if string.IsNilOrEmpty(name) then
    return
  end
  if VarObject:InstanceOf(FsmVar) then
    return
  end
  VarObject:SetAsVar(name, VarObject.properties)
end

function FsmBaseObject:Log(...)
  local name = rawget(self, "name")
  name = name or "Nameless"
  local out = string.format("[%s]", name)
  Log.Debug(out, ...)
end

return FsmBaseObject
