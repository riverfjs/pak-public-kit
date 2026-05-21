local NRCPanelEnum = {}
NRCPanelEnum.PanelTypeEnum = {
  PANEL_3DUI1 = 1,
  PANEL_3DUI2 = 2,
  PANEL_POPUP_UNTRANS = 3,
  PANEL_POPUP_TRANS = 4,
  PANEL_HALFSCREEN = 5,
  PANEL_FULLSCREEN = 6
}
NRCPanelEnum.PanelStatus = {
  Init = 1,
  ReadyToOpen = 2,
  Visible = 3,
  ReadyToClose = 4,
  Closed = 5
}
NRCPanelEnum.OpenFailedReason = {RspError = 1}
NRCPanelEnum.PanelDisableReason = {
  None = 0,
  Default = 1,
  LayerCtrl = 2,
  WaitTogetherPlayer = 4
}
NRCPanelEnum.NRCPanelOpenStrategy = {
  Default = 0,
  ForceCloseFirst = 1,
  BringToFront = 2
}
NRCPanelEnum.PanelOpenResult = {
  Success = 0,
  Error = -1,
  NotAllowed = -2,
  Opening = -3,
  Opened = -4,
  BringToFront = -5
}
return NRCPanelEnum
