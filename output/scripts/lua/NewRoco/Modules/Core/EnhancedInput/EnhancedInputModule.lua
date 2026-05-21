local EnhancedInputModule = NRCModuleBase:Extend("EnhancedInputModule")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local EnhancedInputMappingContext = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputMappingContext")

function EnhancedInputModule:OnConstruct()
  self.data = self:SetData("EnhancedInputModuleData", "NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleData")
  self.activeMappingContext = {}
  self.applyInputMappingContext = {}
  self.addInputMappingContext = {}
end

function EnhancedInputModule:OnDestruct()
end

function EnhancedInputModule:OnActive()
  if not self:EnableEnhancedInput() then
    return
  end
  self.data:InitData()
  _G.NRCEventCenter:RegisterEvent("EnhancedInputModule", self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.OnPostLoadMapWithWorld)
  UE4Helper.InitCursorFlag()
end

function EnhancedInputModule:OnDeactive()
end

function EnhancedInputModule:EnableEnhancedInput()
  return RocoEnv.PLATFORM == "PLATFORM_WINDOWS"
end

function EnhancedInputModule:ChangePlayerControlBindKeys()
  local mappingContext = EnhancedInputMappingContext("IMC_PlayerControll")
  if mappingContext and mappingContext:IsMappingContextEnable() then
    mappingContext:DisableAutoRelease()
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
    mappingContext:BindAction("LookUpRate")
    mappingContext:BindAction("MouseMoveX")
    mappingContext:BindAction("MouseMoveY")
    mappingContext:BindAction("LookUp")
    mappingContext:BindAction("Turn")
    mappingContext:BindAction("TurnRate")
    mappingContext:BindAction("MouseMove")
    mappingContext:BindAction("IA_MouseWheelDown")
    mappingContext:BindAction("IA_MouseWheelUp")
  end
end

function EnhancedInputModule:OnPostLoadMapWithWorld()
  self:ChangePlayerControlBindKeys()
end

function EnhancedInputModule:OnShutdown()
  NRCModuleBase.OnShutdown(self)
  for _, mappingContext in pairs(self.activeMappingContext) do
    mappingContext:Release()
  end
  self.activeMappingContext = {}
end

function EnhancedInputModule:GetMappingKey(_actionName)
  return self.data:GetMappingKey(_actionName)
end

function EnhancedInputModule:_AddBlockingIMC(mappingContext, priority, name)
  priority = priority or 0
  if self.addInputMappingContext[name] then
    UE.UNRCEnhancedInputHelper.AddInputMappingContext(mappingContext, priority)
    return true
  end
  Log.Debug("[EnhancedInputModule] AddInputMappingContext: %s, priority: %d", name, priority)
  self.addInputMappingContext[name] = true
  local imcMaxNum = #self.applyInputMappingContext
  local lastTopImcName = self.applyInputMappingContext[imcMaxNum] and self.applyInputMappingContext[imcMaxNum].imcName
  table.insert(self.applyInputMappingContext, {imcName = name, priority = priority})
  imcMaxNum = imcMaxNum + 1
  for k, v in ipairs(self.applyInputMappingContext) do
    v.insertOrder = k
  end
  table.sort(self.applyInputMappingContext, function(a, b)
    return a.priority < b.priority or a.priority == b.priority and a.insertOrder < b.insertOrder
  end)
  local newTopImcName = self.applyInputMappingContext[imcMaxNum].imcName
  if lastTopImcName and lastTopImcName ~= newTopImcName and "IMC_MainUIDefault" == lastTopImcName then
    _G.NRCEventCenter:DispatchEvent(EnhancedInputModuleEvent.TopBlockImcChange, lastTopImcName, newTopImcName)
  end
  UE.UNRCEnhancedInputHelper.AddInputMappingContext(mappingContext, priority)
  return true
end

function EnhancedInputModule:EnhancedInputHelperAddInputMappingContext(mappingContext, priority)
  if not RocoEnv.PLATFORM_WINDOWS then
    return false
  end
  if not UE.UObject.IsValid(mappingContext) then
    Log.Debug("EnhancedInputModule:EnhancedInputHelperAddInputMappingContext: mappingContext is nil or invalid")
    return false
  end
  local name = mappingContext:GetName()
  if "IMC_Block" == name then
    Log.Warning("EnhancedInputModule:EnhancedInputHelperAddInputMappingContext: \231\166\129\230\173\162\233\128\154\232\191\135\230\173\164\230\150\185\230\179\149\230\183\187\229\138\160 IMC_Block\239\188\140\232\175\183\228\189\191\231\148\168 AddBlockIMC API")
    return false
  end
  local isBlock = mappingContext.bBlock
  if not isBlock then
    UE.UNRCEnhancedInputHelper.AddInputMappingContext(mappingContext, priority)
    return true
  end
  return self:_AddBlockingIMC(mappingContext, priority, name)
end

function EnhancedInputModule:_RemoveBlockingIMC(name)
  self.addInputMappingContext[name] = nil
  Log.Debug("[EnhancedInputModule] RemoveInputMappingContext: %s", name)
  for k, v in ipairs(self.applyInputMappingContext) do
    if v.imcName == name then
      table.remove(self.applyInputMappingContext, k)
      break
    end
  end
end

function EnhancedInputModule:EnhancedInputHelperRemoveInputMappingContext(mappingContext)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if mappingContext then
    local name = mappingContext:GetName()
    if "IMC_Block" == name then
      Log.Warning("EnhancedInputModule:EnhancedInputHelperRemoveInputMappingContext: \231\166\129\230\173\162\233\128\154\232\191\135\230\173\164\230\150\185\230\179\149\231\167\187\233\153\164 IMC_Block\239\188\140\232\175\183\228\189\191\231\148\168 RemoveBlockIMC API")
      return
    end
    local isBlock = mappingContext.bBlock
    if isBlock then
      self:_RemoveBlockingIMC(name)
    end
    UE.UNRCEnhancedInputHelper.RemoveInputMappingContext(mappingContext)
  end
end

function EnhancedInputModule:AddInputMappingContext(_contextName, _override, _priority)
  if not _contextName or not self:EnableEnhancedInput() then
    return
  end
  local mappingContext = self.activeMappingContext[_contextName]
  if mappingContext and _override then
    mappingContext:Release()
    mappingContext = nil
  end
  if not mappingContext then
    mappingContext = EnhancedInputMappingContext(_contextName)
    mappingContext:EnableInputMappingContext(_priority)
    self.activeMappingContext[_contextName] = mappingContext
  end
  return mappingContext
end

function EnhancedInputModule:BlockPCInput(caller, priority)
  if not caller then
    Log.Error("Unable block PC Input without caller")
    return
  end
  if not RocoEnv.PLATFORM_WINDOWS then
    return false
  end
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_Block")
  if not imc then
    Log.Error("EnhancedInputModule:BlockPCInput: IMC_Block not found")
    return false
  end
  local name = imc:GetName()
  local success = self:_AddBlockingIMC(imc, priority, name)
  if success then
    self.blockImcCaller = caller.name or "default"
  end
  return success
end

function EnhancedInputModule:UnBlockPCInput(caller)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  local unblockImcCaller = caller and caller.name or ""
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_Block")
  if imc then
    local name = imc:GetName()
    self:_RemoveBlockingIMC(name)
    UE.UNRCEnhancedInputHelper.RemoveInputMappingContext(imc)
  end
  if self.blockImcCaller ~= unblockImcCaller then
    Log.WarningFormat("UnBlockPCInput(%s) caller mismatch Block(%s) caller", unblockImcCaller, self.blockImcCaller)
  end
  self.blockImcCaller = nil
end

function EnhancedInputModule:GetInputMappingContext(_contextName)
  if not _contextName or not self:EnableEnhancedInput() then
    return
  end
  return self.activeMappingContext[_contextName]
end

function EnhancedInputModule:RemoveInputMappingContext(_contextName)
  if not _contextName or not self:EnableEnhancedInput() then
    return
  end
  local mappingContext = self.activeMappingContext[_contextName]
  if mappingContext then
    mappingContext:Release()
    self.activeMappingContext[_contextName] = nil
  end
end

function EnhancedInputModule:ApplyUserModifiedKeyMappings(_keyMappings)
  if not _keyMappings then
    return
  end
  self.data:ApplyUserModifiedKeyMappings(_keyMappings)
  for _, _mappingContext in pairs(self.activeMappingContext) do
    _mappingContext:ChangeKeys(_keyMappings)
  end
  _G.NRCEventCenter:DispatchEvent(EnhancedInputModuleEvent.KeyMappingsChanged)
end

function EnhancedInputModule:DumpEnhancedInputDetail()
  local debugContextData = {}
  for _, contextData in pairs(self.applyInputMappingContext or {}) do
    local debugItem = {}
    debugItem.priority = contextData.priority
    debugItem.contextName = contextData.imcName
    local mappingContext = self.activeMappingContext and self.activeMappingContext[debugItem.contextName]
    if mappingContext then
      local _debugData = mappingContext:GetDebugData() or {}
      debugItem.isActive = _debugData.isActive
      debugItem.bindActions = _debugData.bindActions
    end
    table.insert(debugContextData, debugItem)
  end
  local DebugData = {
    ["\231\148\159\230\149\136\228\184\173\231\154\132\233\148\174\231\155\152\230\152\160\229\176\132\228\191\161\230\129\175"] = debugContextData
  }
  return DebugData
end

return EnhancedInputModule
