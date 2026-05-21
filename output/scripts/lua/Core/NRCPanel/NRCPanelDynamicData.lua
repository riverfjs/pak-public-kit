local Class = _G.MakeSimpleClass
local NRCPanelDynamicData = Class("NRCPanelDynamicData")
NRCPanelDynamicData:SetMemberCount(2)

function NRCPanelDynamicData:Ctor()
end

function NRCPanelDynamicData:SetOpenCallback(caller, func, ...)
  self.OnOpenCallback = _G.MakeWeakFunctor(caller, func, ...)
  return self
end

function NRCPanelDynamicData:SetCloseCallback(caller, func, ...)
  self.OnCloseCallback = _G.MakeWeakFunctor(caller, func, ...)
  return self
end

function NRCPanelDynamicData:TriggerOpen(panelData)
  local OnOpenCallback = self.OnOpenCallback
  if OnOpenCallback then
    local ok, msg = pcall(OnOpenCallback, panelData)
    if not ok then
      Log.Error(msg)
    end
    OnOpenCallback = nil
  end
end

function NRCPanelDynamicData:TriggerClose(panelData)
  local OnCloseCallback = self.OnCloseCallback
  if OnCloseCallback then
    local ok, msg = pcall(OnCloseCallback, panelData)
    if not ok then
      Log.Error(msg)
    end
    OnCloseCallback = nil
  end
end

function NRCPanelDynamicData:GetModifiedPanelLayerType()
  return self.modifiedPanelLayerType
end

function NRCPanelDynamicData:SetModifiedPanelLayerType(modifiedLayerType)
  self.modifiedPanelLayerType = modifiedLayerType
  return self
end

return NRCPanelDynamicData
