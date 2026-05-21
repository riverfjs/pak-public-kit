local NRCCommonPopUpData = NRCClass:Extend("NRCCommonPopUpData")

function NRCCommonPopUpData:Ctor()
  NRCClass.Ctor(self)
  self.BlackMask = true
  self.FullScreen_Close = true
  self.btnClose = true
  self.TitleIcon = nil
  self.TitleText = nil
  self.Desc = nil
  self.ContentText = nil
  self.RemindSwitch = nil
  self.Btn_RightTitle = false
  self.Btn_LeftHandler = nil
  self.Btn_RightHandler = nil
  self.ClosePanelHandler = nil
  self.CloseBtnSound = nil
  self.PopUpType = nil
  self.Call = nil
  self.HideBtn = false
  self.ItemList = nil
  self.PopUpOpenHandler = nil
  self.PopUpHandler = nil
  self.bPlayBtnSound = true
  self.bUseContentText1 = nil
  self.SkipCloseAnim = false
  self.ContentTextOnRichTextClickHandle = nil
  self.CountdownTime = nil
end

return NRCCommonPopUpData
