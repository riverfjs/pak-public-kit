local UMG_CommonPopUp_C = _G.NRCViewBase:Extend("UMG_CommonPopUp_C")
local CLICK_INTERVAL = 1

function UMG_CommonPopUp_C:OnConstruct()
  self.Mask = {}
  if self.BlackMask then
    table.insert(self.Mask, self.BlackMask)
  end
  if self.Bg_1 then
    table.insert(self.Mask, self.Bg_1)
  end
  if #self.Mask > 0 then
    self.bgProxy = _G.NRCModuleManager:DoCmd(TUIModuleCmd.PushBlackBackgroundWidgets, self.Mask)
  end
  self.IsLock = false
  self.HasPlaySoundIn = false
  self.LastClickTime = {}
  self:OnAddEventListener()
  if self:GetAnimByIndex(0) then
    self:LoadAnimation(0)
  end
  if self.Btn_Right_GrayState then
    self.Btn_Right_GrayState:SetBtnText(LuaText.umg_bag_popup_2)
    self.Btn_Right_GrayState:SetShowOrHideSuo(false)
  end
  self.TimerID = nil
end

function UMG_CommonPopUp_C:OnDestruct()
  if self.bgProxy then
    _G.NRCModuleManager:DoCmd(TUIModuleCmd.PopBlackBackgroundWidgets, self.bgProxy)
  end
  if self.TimerID then
    _G.TimerManager:RemoveTimer(self.TimerID)
    self.TimerID = nil
  end
end

function UMG_CommonPopUp_C:OnActive()
end

function UMG_CommonPopUp_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_CommonPopUp_C:OnDeactive()
end

function UMG_CommonPopUp_C:PlaySoundIn()
  if self.CommonPopUpData.PopUpType and 2 == self.CommonPopUpData.PopUpType then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400007, "UMG_CommonPopUp_C:PlaySoundIn")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400009, "UMG_CommonPopUp_C:PlaySoundIn")
  end
end

function UMG_CommonPopUp_C:PlaySoundOut()
  if self.CommonPopUpData.PopUpType and 2 == self.CommonPopUpData.PopUpType then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400008, "UMG_CommonPopUp_C:PlaySoundOut")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400010, "UMG_CommonPopUp_C:PlaySoundOut")
  end
end

function UMG_CommonPopUp_C:OnAddEventListener()
  self:AddButtonListener(self.FullScreen_Close, self.OnFullScreen_Close)
  if self.Btn_Left then
    self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnBtn_Left)
  end
  if self.Btn_Right then
    self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnBtn_Right)
  end
  if self.Btn_Right_GrayState then
    self:AddButtonListener(self.Btn_Right_GrayState.btnLevelUp, self.OnBtn_Right_GrayState)
  end
  if self.Btn_Right_GrayState2 then
    self:AddButtonListener(self.Btn_Right_GrayState2.btnLevelUp, self.OnBtn_Right_GrayState2)
  end
  self:AddButtonListener(self.btnClose.btnClose, self.OnBtnClose)
end

function UMG_CommonPopUp_C:SetPanelInfo(CommonPopUpData)
  self.CommonPopUpData = CommonPopUpData
  self:ShowOrHideBtnLeft(not self.CommonPopUpData.HideBtn)
  self:ShowOrHideBtnRight(not self.CommonPopUpData.HideBtn)
  if self.BlackMask then
    if self.CommonPopUpData.BlackMask then
      self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BlackMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.FullScreen_Close then
    if self.CommonPopUpData.FullScreen_Close then
      self.FullScreen_Close:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.FullScreen_Close:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.TitleIcon then
    if self.CommonPopUpData.TitleIcon then
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TitleIcon:SetPath(self.CommonPopUpData.TitleIcon)
      if self.ItemSwitcher then
        self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.ItemSwitcher:SetActiveWidgetIndex(0)
      end
    else
      if self.ItemSwitcher then
        self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ItemSwitcher:SetActiveWidgetIndex(0)
      end
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.TitleText and self.CommonPopUpData.TitleText then
    self.TitleText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TitleText:SetText(self.CommonPopUpData.TitleText)
  else
  end
  if self.Desc and self.textBG then
    if self.CommonPopUpData.Desc then
      self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.textBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Desc:SetText(self.CommonPopUpData.Desc)
    else
      self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.textBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.btnClose then
    if self.CommonPopUpData.btnClose then
      self.btnClose:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.Btn_Right then
    if self.CommonPopUpData.Btn_RightTitle then
      self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CommonPopUpData.Btn_RightText then
      self.Btn_Right:SetBtnText(self.CommonPopUpData.Btn_RightText)
    end
  end
  if self.Btn_Left and self.CommonPopUpData.Btn_LeftText then
    self.Btn_Left:SetBtnText(self.CommonPopUpData.Btn_LeftText)
  end
  if self.Btn_Right_GrayState and self.CommonPopUpData.Btn_Right_GrayState_Text then
    self:SetBtnRightGrayStateText(self.CommonPopUpData.Btn_Right_GrayState_Text)
  end
  if self.Btn_Right_GrayState2 and self.CommonPopUpData.Btn_Right_GrayState2_Text then
    self.Btn_Right_GrayState2:SetBtnText(self.CommonPopUpData.Btn_Right_GrayState2_Text)
  end
  if not self.HasPlaySoundIn then
    self.HasPlaySoundIn = true
    self:PlaySoundIn()
  end
end

function UMG_CommonPopUp_C:SetRightBtnTitleTextAndIconShow(bIsShow, TitleInfo)
  if self.Btn_Right and self.Btn_Right.TitleCanvas then
    if bIsShow then
      self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if TitleInfo then
        self.Btn_Right:SetTitleTextAndIcon(TitleInfo.MoneyIcon, TitleInfo.QuantityText, TitleInfo.SystemIcon, TitleInfo.ShowTime, TitleInfo.TitleText, TitleInfo.DescText, TitleInfo.MoneyIcon1, TitleInfo.Color)
      end
    else
      self.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetRightGrayState2TitleTextAndIconShow(bIsShow, TitleInfo)
  if self.Btn_Right_GrayState2 and self.Btn_Right_GrayState2.TitleCanvas then
    if bIsShow then
      self.Btn_Right_GrayState2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if TitleInfo then
        self.Btn_Right_GrayState2:SetTitleTextAndIcon(TitleInfo.MoneyIcon, TitleInfo.QuantityText, TitleInfo.SystemIcon, TitleInfo.ShowTime, TitleInfo.TitleText, TitleInfo.DescText, TitleInfo.Color)
      end
    else
      self.Btn_Right_GrayState2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:ShowOrHideRightGrayState2(_IsShow)
  if self.Btn_Right_GrayState2 then
    if _IsShow then
      self.Btn_Right_GrayState2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Btn_Right_GrayState2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetRightBtnCountdown(CountdownTimer)
  if self.TimerID then
    _G.TimerManager:RemoveTimer(self.TimerID)
    self.TimerID = nil
  end
  if CountdownTimer > 0 and self.Btn_Right and self.Btn_Right_GrayState then
    self.Btn_Right_GrayState:SetBtnText(LuaText.general_confirm .. "(" .. CountdownTimer .. ")")
    self.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TimerID = _G.TimerManager:CreateTimer(self, "UMG_CommonPopUp_C:SetRightBtnCountdown", CountdownTimer + 1, function()
      CountdownTimer = CountdownTimer - 1
      if CountdownTimer > 0 then
        self.Btn_Right_GrayState:SetBtnText(LuaText.general_confirm .. "(" .. CountdownTimer .. ")")
      else
        self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end, nil, 1)
  end
end

function UMG_CommonPopUp_C:SetBtnLeftRedDot(key, extraKey)
  if self.Btn_Left and self.Btn_Left.RedDot then
    self.Btn_Left.RedDot:SetupKey(key, extraKey)
  end
end

function UMG_CommonPopUp_C:SetBtnRightRedDot(key, extraKey)
  if self.Btn_Right and self.Btn_Right.RedDot then
    self.Btn_Right.RedDot:SetupKey(key, extraKey)
  end
end

function UMG_CommonPopUp_C:ShowOrHideBtnLeft(_IsShow)
  if self.Btn_Left then
    if _IsShow then
      self.Btn_Left:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:ShowOrHideBtnRight(_IsShow)
  if self.Btn_Right then
    if _IsShow then
      self.Btn_Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetTitleIconInfo(TitleIcon)
  if self.TitleIcon then
    if TitleIcon then
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TitleIcon:SetPath(TitleIcon)
      if self.ItemSwitcher then
        self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.ItemSwitcher:SetActiveWidgetIndex(0)
      end
    else
      if self.ItemSwitcher then
        self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ItemSwitcher:SetActiveWidgetIndex(0)
      end
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetTitleTextInfo(TitleText)
  if self.TitleText then
    if TitleText then
      self.TitleText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TitleText:SetText(TitleText)
    else
      self.TitleText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetDescInfo(Desc)
  if self.Desc and self.textBG then
    if Desc then
      self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.textBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Desc:SetText(Desc)
    else
      self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.textBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetBtnLeftText(BtnText)
  if self.Btn_Left then
    self.Btn_Left:SetBtnText(BtnText)
  end
end

function UMG_CommonPopUp_C:SetBtnRightText(BtnText)
  if self.Btn_Right then
    self.Btn_Right:SetBtnText(BtnText)
  end
end

function UMG_CommonPopUp_C:SetBtnRightGrayStateText(BtnText)
  if self.Btn_Right_GrayState then
    self.Btn_Right_GrayState:SetBtnText(BtnText)
  end
end

function UMG_CommonPopUp_C:SetLeftBtnIconInfo(BtnMoneyIcon, BtnMoneyText)
  if self.Btn_Left then
    self.Btn_Left:SetTitleTextAndIcon(BtnMoneyIcon, BtnMoneyText)
  end
end

function UMG_CommonPopUp_C:SetRightBtnIconInfo(BtnMoneyIcon, BtnMoneyText)
  if self.Btn_Right then
    self.Btn_Right:SetTitleTextAndIcon(BtnMoneyIcon, BtnMoneyText)
  end
end

function UMG_CommonPopUp_C:SetBtnLeftHandler(BtnLeftHandler)
  if BtnLeftHandler and self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_LeftHandler then
    self.CommonPopUpData.Btn_LeftHandler = BtnLeftHandler
  end
end

function UMG_CommonPopUp_C:SetBtnRightHandler(BtnRightHandler)
  if BtnRightHandler and self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightHandler then
    self.CommonPopUpData.Btn_RightHandler = BtnRightHandler
  end
end

function UMG_CommonPopUp_C:SetBtnRightGrayStatHandler(BtnRightGrayStatHandler)
  if BtnRightGrayStatHandler and self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightGrayStatHandler then
    self.CommonPopUpData.Btn_RightGrayStatHandler = BtnRightGrayStatHandler
  end
end

function UMG_CommonPopUp_C:OnFullScreen_Close()
  if not self:CheckAndRecordClick("FullScreen_Close") then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.ClosePanelHandler and not self.IsLock then
    self:SetLock(true)
    self:PlaySoundOut()
    self.CommonPopUpData.ClosePanelHandler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:OnBtn_Left()
  if not self:CheckAndRecordClick("Btn_Left") then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_LeftHandler then
    self.CommonPopUpData.Btn_LeftHandler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:OnBtn_Right()
  if not self:CheckAndRecordClick("Btn_Right") then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightHandler then
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.CommonPopUpRightBtn)
    self.CommonPopUpData.Btn_RightHandler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:OnBtn_Right_GrayState()
  if not self:CheckAndRecordClick("Btn_Right_GrayState") then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightGrayStatHandler then
    self.CommonPopUpData.Btn_RightGrayStatHandler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:OnBtn_Right_GrayState2()
  if not self:CheckAndRecordClick("Btn_Right_GrayState2") then
    return
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_RightGrayState2Handler then
    self.CommonPopUpData.Btn_RightGrayState2Handler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:SetBtnRightGrayState(Show)
  if self.Btn_Right_GrayState then
    if Show then
      self.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CommonPopUp_C:SetBtnRightEnableState(Enable)
  if self.Btn_Right then
    self.Btn_Right:SetVisibility(Enable and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
  if self.Btn_Right_GrayState then
    self.Btn_Right_GrayState:SetVisibility(Enable and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  end
end

function UMG_CommonPopUp_C:SetBtnRightEnableStateNew(Enable)
  if Enable then
    self.Btn_Right.HideAnim = true
    self.Btn_Right.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
  else
    self.Btn_Right.HideAnim = true
    self.Btn_Right.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
  end
end

function UMG_CommonPopUp_C:OnBtnClose()
  if not self:CheckAndRecordClick("BtnClose") then
    return
  end
  if self:GetAnimByIndex(2) and not self.CommonPopUpData.SkipCloseAnim then
    self:LoadAnimation(2)
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.ClosePanelHandler and not self.IsLock then
    self:SetLock(true)
    if self.CommonPopUpData.CloseBtnSound then
      local soundId = self.CommonPopUpData.CloseBtnSound
      _G.NRCAudioManager:PlaySound2DAuto(soundId, "UMG_CommonPopUp_C:OnBtnClose")
    end
    self:PlaySoundOut()
    self.CommonPopUpData.ClosePanelHandler(self.CommonPopUpData.Call)
  end
end

function UMG_CommonPopUp_C:SetLock(_IsLock)
  self.IsLock = _IsLock
end

function UMG_CommonPopUp_C:SetDecColor(Desc)
  local Text = string.format("<span color=\"#d56c1f\">%s</>", Desc)
  self:SetDescInfo(Text)
end

function UMG_CommonPopUp_C:CheckAndRecordClick(btnName)
  local currentTime = _G.UpdateManager.Timestamp
  if self.LastClickTime[btnName] and currentTime - self.LastClickTime[btnName] < CLICK_INTERVAL then
    return false
  end
  self.LastClickTime[btnName] = currentTime
  return true
end

return UMG_CommonPopUp_C
