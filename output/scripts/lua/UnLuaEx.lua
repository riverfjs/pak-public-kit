UE4 = UE
local setmetatable = _ENV.setmetatable
local setmetatable2 = _ENV.setmetatable2
local str_sub = string.sub
local rawget = _G.rawget
local rawset = _G.rawset
local rawequal = _G.rawequal
local type = _G.type
local getmetatable = _G.getmetatable
local getmetatable2 = _G.getmetatable2
local require = _G.require
local NewObject = _G.NewObject
local GetUProperty = _ENV.GetUProperty
local SetUProperty = _ENV.SetUProperty
local LuaClassIndex = _ENV.LuaClassIndex
local UnluaClass = UnLua.Class
local LuaClassIndexLuaOnly = _ENV.LuaClassIndexLuaOnly

local function RebindIndex(target)
  local mt = getmetatable(target)
  mt.__index = LuaClassIndex
  mt.__newindex = LuaClassNewIndex
  setmetatable(target, mt)
end

_NotExist = _NotExist or {}
local NotExist = _NotExist

local function Index(t, k)
  local mt = getmetatable(t)
  local super = mt
  while super do
    local v = rawget(super, k)
    if nil ~= v and not rawequal(v, NotExist) then
      rawset(t, k, v)
      return v
    end
    super = rawget(super, "Super")
  end
  local p = mt[k]
  if nil ~= p then
    if "userdata" == type(p) then
      return GetUProperty(t, p)
    elseif "function" == type(p) then
      rawset(t, k, p)
    elseif rawequal(p, NotExist) then
      return nil
    end
  else
    rawset(mt, k, NotExist)
  end
  return p
end

local function NewIndex(t, k, v)
  local mt = getmetatable(t)
  local p = mt[k]
  if "userdata" == type(p) then
    return SetUProperty(t, p, v)
  end
  rawset(t, k, v)
end

function CopyFromClass(class, target)
  local k = next(class)
  while k do
    local v = rawget(class, k)
    local vt = rawget(target, k)
    if not vt then
      rawset(target, k, v)
    end
    k = next(class, k)
  end
end

function CopyFromSuper(super, target)
  local mt = super
  while mt do
    CopyFromClass(mt, target)
    mt = rawget(mt, "Super")
  end
end

local function BuildClassFunc(inst, ...)
  local newCla = BuildClass(className, inst)
  if newCla.Ctor then
    newCla:Ctor(...)
  end
  return newCla
end

local originProtoClass = {
  __call = function(self, ...)
    return BuildClassFunc(self, ...)
  end,
  __tostring = function(self, ...)
    return LuaClassToString(self) or ""
  end
}

local function ExtendFunc(parentClass, claName)
  return Class(claName, parentClass)
end

local function EmptyFunc()
end

local function InitializeFunc(self, ...)
  RebindIndex(self)
  if self.__Ctor then
    self:__Ctor()
  end
  if self.Ctor then
    self:Ctor(...)
  end
  if self.Initialize then
    self:Initialize(...)
  end
end

local function InitializeFuncWithoutRebind(self, ...)
  if self.__Ctor then
    self:__Ctor()
  end
  if self.Ctor then
    self:Ctor(...)
  end
  if self.Initialize then
    self:Initialize(...)
  end
end

local function DctorFunction(self)
  local __Dctor = LuaClassIndexLuaOnly(self, "__Dctor")
  if __Dctor then
    __Dctor(self)
  end
end

local function SubclassFunc(self, superclass)
  local super = self.Super
  while super do
    if super == superclass then
      return true
    end
    super = super.Super
  end
  return false
end

local function InstanceOfFunc(self, fromclass)
  return self.class == fromclass or self.class:SubclassOf(fromclass)
end

local function GetInstanceFunc(self)
  return self.class
end

function BuildClass(className, super_class)
  local instance = UnluaClass()
  instance.class = instance
  instance.Super = super_class
  instance.Extend = ExtendFunc
  instance.className = className
  instance.name = className
  instance.Initialize = EmptyFunc
  instance.__Initialize = InitializeFunc
  instance.SubclassOf = SubclassFunc
  instance.InstanceOf = InstanceOfFunc
  instance.__call = BuildClassFunc
  instance.__index = instance
  instance.__gc = DctorFunction
  if super_class and "table" == type(super_class) then
    setmetatable(instance, super_class)
    setmetatable2(instance, super_class)
  else
    setmetatable(instance, originProtoClass)
    setmetatable2(instance, originProtoClass)
  end
  return instance
end

local function CallClass(className, super_name)
  local super_class
  if nil ~= super_name then
    if "string" == type(super_name) then
      super_class = require(super_name)
    else
      super_class = super_name
    end
  end
  return BuildClass(className, super_class)
end

local Class = {
  IsClass = function(t)
    return not not t.__CLASS
  end,
  IsInstance = function(t)
    return not not t.__INSTANCE
  end
}
setmetatable(Class, {
  __call = function(_, ...)
    return CallClass(...)
  end
})
_G.print = print
_G.Class = Class
_G.NotExist = NotExist
_G.FilterTypeLst = {"TArray"}
_G.BuildVirtualClass = BuildVirtualClass
_G.RebindIndex = RebindIndex
local IS_SHIPPING = _G.RocoEnv.IS_SHIPPING
local SimpleClassOptimization = true
local CopyOrRecurse = false
local AutoAdjustPreAllocSize = true
local MakeSimpleClass
local WithPool = _G.RocoEnv.IS_EDITOR
local ClassPool = {}
local FromPool, ToPool
AutoAdjustPreAllocSize = AutoAdjustPreAllocSize and UE.NRCLuaUtils.GetHashSize ~= nil

local function ExtendSimpleClass(InParentKlass, SubClassName, PoolSize)
  local SubClass = MakeSimpleClass(SubClassName, InParentKlass, PoolSize)
  return SubClass
end

local function DefaultPreCtorFunc(Instance, ...)
end

local function DefaultSetPreAllocSizeFunc(Klass, Size)
  local Parent = Klass.Super
  local ParentSize = Parent and Parent.PreAllocSize or 4
  local Total = ParentSize + Size
  Klass.PreAllocSize = Total
end

local function MakeInstance(InKlass, ...)
  local Instance = table.new(0, InKlass.PreAllocSize)
  local PreCtor = InKlass.PreCtor or DefaultPreCtorFunc
  PreCtor(Instance, ...)
  Instance = setmetatable(Instance, InKlass)
  InitializeFuncWithoutRebind(Instance, ...)
  return Instance
end

local function DestructInstance(Instance)
  if Instance and Instance.__Dctor then
    Instance:__Dctor()
  end
  local Klass = Instance.class
  if WithPool and Klass.UsePool then
    ToPool(Instance)
  end
end

local function CheckAdjustPreAllocMem(InKlass, Instance)
  if not InKlass.autoIncreasePreAllocSize then
    return
  end
  local HashSize = UE.NRCLuaUtils.GetHashSize(Instance)
  HashSize = 1 << HashSize - 1
  if HashSize <= InKlass.PreAllocSize then
    return
  end
  if not IS_SHIPPING then
    if InKlass.className == "Unknown" then
      Log.Error("Update HashSize", InKlass.className, HashSize, InKlass.PreAllocSize)
    else
      Log.Debug("Update HashSize", InKlass.className, HashSize, InKlass.PreAllocSize)
    end
  end
  InKlass.PreAllocSize = HashSize
  InKlass.autoIncreasePreAllocSize = false
end

local function MakeAndAnalyzeInstance(InKlass, ...)
  local Instance = MakeInstance(InKlass, ...)
  CheckAdjustPreAllocMem(InKlass, Instance)
  return Instance
end

local CallableFunc = AutoAdjustPreAllocSize and MakeAndAnalyzeInstance or MakeInstance

local function CallableWithPool(InKlass, ...)
  if WithPool and InKlass.UsePool then
    return FromPool(InKlass, ...)
  else
    return CallableFunc(InKlass, ...)
  end
end

local CallableMetatable = {__call = CallableWithPool}

function FromPool(Klass, ...)
  local Pool = ClassPool[Klass]
  if Pool and next(Pool) then
    local Instance = table.remove(Pool)
    local PreCtor = Klass.PreCtor or DefaultPreCtorFunc
    PreCtor(Instance, ...)
    setmetatable(Instance, Klass)
    InitializeFuncWithoutRebind(Instance, ...)
    return Instance
  else
    return CallableFunc(Klass, ...)
  end
end

function ToPool(Instance)
  local Klass = Instance.class
  if not Klass then
    return
  end
  if not Klass.UsePool then
    return
  end
  if not Klass.PoolSize or Klass.PoolSize <= 0 then
    return
  end
  local Pool = ClassPool[Klass]
  if not Pool then
    Pool = table.new(Klass.PoolSize, 0)
    ClassPool[Klass] = Pool
  end
  local PoolSize = #Pool
  if PoolSize > Klass.PoolSize then
    Log.Warning("[ClassPool] Instance count is larger than PoolSize, discard", Klass.className, PoolSize)
    return
  end
  setmetatable(Instance, nil)
  table.reset(Instance)
  Pool[PoolSize + 1] = Instance
end

function MakeSimpleClass(Name, Parent, PoolSize)
  local Klass = table.new(0, 16)
  if Parent and CopyOrRecurse then
    table.copy(Parent, Klass, true)
  end
  Klass.class = Klass
  Klass.name = Name or "Unknown"
  Klass.className = Name or "Unknown"
  Klass.Super = Parent
  Klass.InstanceOf = InstanceOfFunc
  Klass.SubclassOf = SubclassFunc
  Klass.Extend = ExtendSimpleClass
  Klass.__index = Klass
  Klass.__gc = DestructInstance
  Klass.autoIncreasePreAllocSize = AutoAdjustPreAllocSize
  Klass.PreAllocSize = 4
  Klass.SetMemberCount = DefaultSetPreAllocSizeFunc
  Klass.UsePool = PoolSize and true or Parent and Parent.UsePool or false
  Klass.PoolSize = PoolSize and PoolSize or Parent and Parent.PoolSize or 16
  if Parent and not CopyOrRecurse then
    setmetatable(Klass, {__call = CallableWithPool, __index = Parent})
  else
    setmetatable(Klass, CallableMetatable)
  end
  return Klass
end

if SimpleClassOptimization then
  _G.MakeSimpleClass = MakeSimpleClass
else
  _G.MakeSimpleClass = Class
end
