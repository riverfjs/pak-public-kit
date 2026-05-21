local UMG_TapTap_PopUp_C = _G.NRCPanelBase:Extend("UMG_TapTap_PopUp_C")

function UMG_TapTap_PopUp_C:OnActive()
  Log.Debug("[UMG_TapTap_PopUp_C:OnActive]")
  self.TitleText:SetText(_G.LuaText.taptap_rating_title)
  self.ContentText:SetText(_G.LuaText.taptap_rating_txt)
  self.BtnUse:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_Left.Title_1:SetText(_G.LuaText.CANCEL)
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnClickLeftBtn)
  self.BtnClose:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_Right.Title_1:SetText(_G.LuaText.TASK_GOTO)
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnClickRightBtn)
end

function UMG_TapTap_PopUp_C:OnDeactive()
end

function UMG_TapTap_PopUp_C:OnAddEventListener()
end

function UMG_TapTap_PopUp_C:OnClickLeftBtn()
  Log.Debug("[UMG_TapTap_PopUp_C:OnClickLeftBtn]")
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:OnClose()
end

function UMG_TapTap_PopUp_C:OnClickRightBtn()
  Log.Debug("[UMG_TapTap_PopUp_C:OnClickRightBtn]")
  UE4.UTapTapUtils.NRCTapTapOpenReview()
end

return UMG_TapTap_PopUp_C
