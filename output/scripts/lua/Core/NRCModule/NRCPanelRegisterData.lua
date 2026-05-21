local NRCPanelRegisterData = NRCClass:Extend("NRCPanelRegisterData")
NRCPanelRegisterData.PanelCacheType = {}
NRCPanelRegisterData.PanelCacheType.DonntCache = 1
NRCPanelRegisterData.PanelCacheType.LoadAndCache = 2
NRCPanelRegisterData.PanelCacheType.PreCache = 3

function NRCPanelRegisterData:Ctor()
  NRCClass.Ctor(self)
  self.panelName = nil
  self.panelPath = nil
  self.panelMode = nil
  self.enableMask = true
  self.enableTouchMask = true
  self.isSingleTouchPanel = false
  self.touchCount = 1
  self.panelTouchClose = true
  self.panelCacheType = NRCPanelRegisterData.PanelCacheType.DonntCache
  self.panelLayer = Enum.UILayerType.UI_LAYER_POPUP
  self.noCloseBehind = false
  self.module = nil
  self.customDisableRendering = false
  self.panelType = 0
  self.openReqParam = nil
  self.openAnimName = nil
  self.NeedCapture = false
  self.OpenCmd = nil
  self.closeAnimName = nil
  self.NeedRes = nil
  self.isSelectBtn = 0
  self.enablePcEsc = true
  self.closeGCWeight = 10
  self.autoSetDesiredCursor = nil
  self.panelStaticConf = nil
  self.customDisableGC = false
end

function NRCPanelRegisterData:IsPreCache()
  return self.panelCacheType == NRCPanelRegisterData.PanelCacheType.PreCache
end

function NRCPanelRegisterData:SetFullSpeedDesired(isFullSpeed)
  self.isFullSpeedDesired = isFullSpeed
  return self
end

function NRCPanelRegisterData:SetEnableTouchMask(enableTouchMask)
  self.enableTouchMask = enableTouchMask
  return self
end

function NRCPanelRegisterData:SetManualClosedPopPanel(manualClosedPopPanel)
  self.manualClosedPopPanel = manualClosedPopPanel
  return self
end

function NRCPanelRegisterData:IsDesiredDisableWorldRendering()
  if self.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and not self.customDisableRendering then
    local panelType = self.panelType
    if 0 == panelType or panelType == _G.NRCPanelEnum.PanelTypeEnum.PANEL_3DUI2 or panelType == _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_UNTRANS or panelType == _G.NRCPanelEnum.PanelTypeEnum.PANEL_FULLSCREEN then
      return true
    end
  end
  return false
end

return NRCPanelRegisterData
