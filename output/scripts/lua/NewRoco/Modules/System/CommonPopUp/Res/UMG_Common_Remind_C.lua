local UMG_Common_Remind_C = _G.NRCPanelBase:Extend("UMG_Common_Remind_C")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")

function UMG_Common_Remind_C:OnConstruct()
  self.CommonPopUpData = nil
  self.clickLeft = false
  self.clickRight = false
  self:OnAddEventListener()
end

function UMG_Common_Remind_C:OnDestruct()
  if self.TimerID then
    _G.TimerManager:RemoveTimer(self.TimerID)
    self.TimerID = nil
  end
end

function UMG_Common_Remind_C:OnActive(_param)
  self.clickLeft = false
  self.clickRight = false
  self.CommonPopUpData = _param
  self:SetPanelInfo()
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.OnTickHandler then
  else
    UpdateManager:UnRegister(self)
  end
  self:LoadAnimation(0)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400007, "UMG_Dialog_C:OnActive")
end

function UMG_Common_Remind_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.WINDOW_ACTIVATION_CHANGED, self.OnWindowActivationChanged)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Common_Remind_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnBtnLeft)
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnBtnRight)
  self:AddButtonListener(self.Btn_GrayState.btnLevelUp, self.OnBtnGrayState)
  self:AddButtonListener(self.FullScreen_Close, self.OnFullScreen_Close)
  self:AddButtonListener(self.btnClose.btnClose, self.OnBtnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_KeystrokeCollision_C", self, _G.NRCGlobalEvent.WINDOW_ACTIVATION_CHANGED, self.OnWindowActivationChanged)
  if self.ContentText and self.ContentText.OnRichTextClick then
    self:AddDelegateListener(self.ContentText.OnRichTextClick, self.OnContentTextRichTextClick)
  end
  if self.ContentText_1 and self.ContentText_1.OnRichTextClick then
    self:AddDelegateListener(self.ContentText_1.OnRichTextClick, self.OnContentTextRichTextClick)
  end
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Common_Remind_C:OnContentTextRichTextClick(key)
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.ContentText and self.CommonPopUpData.ContentTextOnRichTextClickHandle then
    self.CommonPopUpData.ContentTextOnRichTextClickHandle(self.CommonPopUpData.Call, key)
  end
end

function UMG_Common_Remind_C:SetPanelInfo()
  if self.FullScreen_Close then
    if self.CommonPopUpData and self.CommonPopUpData.FullScreen_Close then
      self.FullScreen_Close:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.FullScreen_Close:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.CommonPopUpData and self.CommonPopUpData.TitleText then
    self.TitleText:SetText(self.CommonPopUpData.TitleText)
    self.TitleText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TitleText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CommonPopUpData and self.CommonPopUpData.RemindSwitch then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_1:SetActiveWidgetIndex(self.CommonPopUpData.RemindSwitch)
  else
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateContext()
  if self.CommonPopUpData and self.CommonPopUpData.Btn_RightTitle then
    self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local TitleInfo = self.CommonPopUpData.Btn_RightTitle
    self.Btn_Right:SetTitleTextAndIcon(TitleInfo.MoneyIcon, TitleInfo.QuantityText, TitleInfo.SystemIcon, TitleInfo.ShowTime, TitleInfo.TitleText, TitleInfo.DescText, TitleInfo.MoneyIcon1, TitleInfo.Color)
  else
    self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CommonPopUpData and self.CommonPopUpData.Btn_RightText then
    self.Btn_Right:SetBtnText(self.CommonPopUpData.Btn_RightText)
    self.Btn_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CommonPopUpData and self.CommonPopUpData.Btn_GrayStateTitle then
    self.Btn_GrayState.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local TitleInfo = self.CommonPopUpData.Btn_GrayStateTitle
    self.Btn_GrayState:SetTitleTextAndIcon(TitleInfo.MoneyIcon, TitleInfo.QuantityText, TitleInfo.SystemIcon, TitleInfo.ShowTime, TitleInfo.TitleText, TitleInfo.DescText, TitleInfo.Color)
  else
    self.Btn_GrayState.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CommonPopUpData and self.CommonPopUpData.Btn_GrayStateText then
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_GrayState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_GrayState:SetBtnText(self.CommonPopUpData.Btn_GrayStateText)
  end
  if self.CommonPopUpData and self.CommonPopUpData.Btn_LeftText then
    self.Btn_Left:SetBtnText(self.CommonPopUpData.Btn_LeftText)
  end
  if self.CommonPopUpData and self.CommonPopUpData.HideBtn then
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CommonPopUpData.MoneyInfo and #self.CommonPopUpData.MoneyInfo > 0 then
    self.MoneyBtn:InitGridView(self.CommonPopUpData.MoneyInfo)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.CommonPopUpData.CountdownTime then
    self:SetRightBtnCountdown(self.CommonPopUpData.CountdownTime)
  end
end

function UMG_Common_Remind_C:UpdateContext()
  if self.CommonPopUpData and self.CommonPopUpData.ContentText then
    if self.ContentText_1 then
      self.ContentText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ContentText then
      self.ContentText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ContentText_3 then
      self.ContentText_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ContentText_1 and self.CommonPopUpData.bUseContentText1 then
      self.ContentText_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ContentText_1:SetText(self.CommonPopUpData.ContentText)
    elseif self.ContentText_3 and self.CommonPopUpData.bUseContentTextLeft then
      self.ContentText_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ContentText_3:SetText(self.CommonPopUpData.ContentText)
    else
      self.ContentText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ContentText:SetText(self.CommonPopUpData.ContentText)
    end
  else
    if self.ContentText then
      self.ContentText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ContentText_1 then
      self.ContentText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ContentText_3 then
      self.ContentText_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Common_Remind_C:OnPcClose()
  self:OnFullScreen_Close()
end

function UMG_Common_Remind_C:OnBtnLeft()
  if self.clickLeft then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_LeftHandler then
    self.CommonPopUpData.Btn_LeftHandler(self.CommonPopUpData.Call)
  end
  if self.CommonPopUpData and self.CommonPopUpData.bPlayBtnSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  end
  self.clickLeft = true
  self:LoadAnimation(2)
end

function UMG_Common_Remind_C:OnBtnRight()
  if self.clickRight then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightHandler then
    self.CommonPopUpData.Btn_RightHandler(self.CommonPopUpData.Call)
  end
  if self.CommonPopUpData and self.CommonPopUpData.bPlayBtnSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Dialog_C:OnClickOkButton")
  end
  self.clickRight = true
  self:LoadAnimation(2)
end

function UMG_Common_Remind_C:OnBtnGrayState()
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_GrayStateHandler then
    self.CommonPopUpData.Btn_GrayStateHandler(self.CommonPopUpData.Call)
  end
  if self.CommonPopUpData and self.CommonPopUpData.bPlayBtnSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Dialog_C:OnBtnGrayState")
  end
end

function UMG_Common_Remind_C:OnFullScreen_Close()
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.ClosePanelHandler then
    self.CommonPopUpData.ClosePanelHandler(self.CommonPopUpData.Call)
  end
  if self.CommonPopUpData and self.CommonPopUpData.bPlayBtnSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  end
  self:LoadAnimation(2)
end

function UMG_Common_Remind_C:OnWindowActivationChanged(bActivate)
  if bActivate then
    if self:HasAnyUserFocus() then
      return
    else
      self:SetFocus()
    end
  end
end

function UMG_Common_Remind_C:OnBtnClose()
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_CloseHandler then
    self.CommonPopUpData.Btn_CloseHandler(self.CommonPopUpData.Call)
  end
  if self.CommonPopUpData and self.CommonPopUpData.bPlayBtnSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  end
  self:LoadAnimation(2)
end

function UMG_Common_Remind_C:OnClose()
  self.clickLeft = false
  self.clickRight = false
  _G.NRCAudioManager:PlaySound2DAuto(41401008, "UMG_Common_Remind_C:OnFullScreen_Close")
  self:DoClose()
end

function UMG_Common_Remind_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.PopUpOpenHandler then
      self.CommonPopUpData.PopUpOpenHandler(self.CommonPopUpData.Call)
    end
    if self.clickRight then
      if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.PopUpHandler then
        self.CommonPopUpData.PopUpHandler(self.CommonPopUpData.Call)
      end
      self.clickRight = false
    end
    self:OnClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Common_Remind_C:OnTick()
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.OnTickHandler then
    self.CommonPopUpData.OnTickHandler(self.CommonPopUpData.Call, self.CommonPopUpData, self)
  end
end

function UMG_Common_Remind_C:OnPlayerDataUpdate()
  self:RefreshMoneyList()
end

function UMG_Common_Remind_C:RefreshMoneyList()
  for i = 1, self.MoneyBtn:GetItemCount() do
    self.MoneyBtn:GetItemByIndex(i - 1):RefreshMoneyNum()
  end
end

function UMG_Common_Remind_C:SetRightBtnCountdown(CountdownTimer)
  if self.TimerID then
    _G.TimerManager:RemoveTimer(self.TimerID)
    self.TimerID = nil
  end
  if CountdownTimer > 0 and self.Btn_Right and self.Btn_GrayState then
    local confirmText = self.CommonPopUpData.Btn_GrayStateText or LuaText.general_confirm
    self.Btn_GrayState:SetBtnText(confirmText .. "(" .. CountdownTimer .. ")")
    self.Btn_GrayState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TimerID = _G.TimerManager:CreateTimer(self, "UMG_Common_Remind_C:SetRightBtnCountdown", CountdownTimer + 1, function()
      CountdownTimer = CountdownTimer - 1
      if CountdownTimer > 0 then
        self.Btn_GrayState:SetBtnText(confirmText .. "(" .. CountdownTimer .. ")")
      else
        self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Btn_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end, nil, 1)
  end
end

return UMG_Common_Remind_C
