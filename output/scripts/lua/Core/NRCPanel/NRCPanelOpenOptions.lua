local NRCPanelOpenOptions_Instance = {}
NRCPanelOpenOptions_Instance.__index = NRCPanelOpenOptions_Instance

function NRCPanelOpenOptions_Instance:SetPriority(p)
  self.priority = p
  return self
end

function NRCPanelOpenOptions_Instance:SetOpenStrategy(p)
  self.openStrategy = p
  return self
end

function NRCPanelOpenOptions_Instance:SetRefreshOpeningArgs(p)
  self.refreshOpeningArgs = p
  return self
end

local NRCPanelOpenOptions = {}

function NRCPanelOpenOptions.New()
  return setmetatable({__isPanelOpenOptions = true}, NRCPanelOpenOptions_Instance)
end

return NRCPanelOpenOptions
