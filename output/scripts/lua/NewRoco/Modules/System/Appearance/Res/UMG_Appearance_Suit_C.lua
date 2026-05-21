local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local UMG_Appearance_Suit_C = _G.NRCPanelBase:Extend("UMG_Appearance_Suit_C")

function UMG_Appearance_Suit_C:OnConstruct()
  self.ViewSuit_List = nil
  self.ShowSuitList = false
  self:OnAddEventListener()
  self.ClickTime = 0
  self.CanClickItem = true
  self.DelayTime = _G.DataConfigManager:GetGlobalConfigByKeyType("waiguan_world_colddowntime", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  _G.UpdateManager:Register(self)
  self.ScrollPageController:SetPageChangeHandler(self.OnPageChangeHandle, self)
  self._firstOpenSuitList = false
  self.bIsInit = true
end

function UMG_Appearance_Suit_C:OnActive(fashionInfo, bLobbyMain)
  self.bLobbyMain = bLobbyMain
  if self.bLobbyMain then
    self.An2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Return:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShowSuitList = true
  else
    self.An2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Return:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ShowSuitList = false
  end
  self:UpdateList(fashionInfo, true)
  if bLobbyMain then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenWorldWardrobe, true)
  end
end

function UMG_Appearance_Suit_C:InitPanel(parent)
  self.parent = parent
end

function UMG_Appearance_Suit_C:OnDeactive()
  _G.UpdateManager:UnRegister(self)
end

function UMG_Appearance_Suit_C:OnAddEventListener()
  self:AddButtonListener(self.Return.btnLevelUp, self.OnSuitBtnClicked)
  self.Return.btnLevelUp.OnPressed:Add(self, self.OnClickBtnPressed)
  self.Return.btnLevelUp.OnReleased:Add(self, self.OnClickBtnReleased)
  self:AddButtonListener(self.CloseSuitBtn, self.OnCloseSuitBtnClicked)
  self:AddButtonListener(self.Btn_CloseSuit, self.OnSuitBtnClicked)
end

function UMG_Appearance_Suit_C:UpdateList(fashionInfo, bClicked, _IsPlaySound, isRefreshNewIcon, selectedIndex)
  local curSelectedIndex = self.Suit_List._selectedItemIndex
  if not fashionInfo then
    return
  end
  local click = bClicked and bClicked or true
  local curIndex = fashionInfo.current_wardrobe_index
  if selectedIndex then
    curIndex = selectedIndex - 1
  end
  local suitData = {}
  if fashionInfo.wardrobe_data then
    for k, v in ipairs(fashionInfo.wardrobe_data) do
      table.insert(suitData, {
        fashion_data = v,
        current_wardrobe_data_index = curIndex,
        bLobbyMain = self.bLobbyMain,
        Clicked = click,
        IsPlaySound = _IsPlaySound,
        parent = self
      })
    end
  end
  self.ViewSuit_List = suitData
  self.ScrollPageController:SetValidItemTotalNum(#suitData)
  self:SetScrollToPage(curIndex)
  self:SetShowDots()
  if self.bIsInit then
    self.Suit_List:InitList(suitData)
    self.bIsInit = false
  else
    for i = 0, self.Suit_List:GetItemCount() - 1 do
      local item = self.Suit_List:GetItemByIndex(i)
      if item then
        item:OnItemUpdate(suitData[i + 1], suitData, i + 1)
      end
    end
  end
  if not self.startClickFlag then
    self.startClickFlag = true
    self:SetWardrobeIndex(curIndex)
  end
  if bClicked then
    self:SetWardrobeIndex(curIndex)
  end
  if isRefreshNewIcon then
    local item = self.Suit_List:GetItemByIndex(curIndex)
    if curSelectedIndex ~= curIndex + 1 then
      item:PlayAnimation(item.Rename_In)
    end
  end
  self:SetPlaySoundState(true)
end

function UMG_Appearance_Suit_C:SetPlaySoundState(_IsPlaySound)
  for i, ViewSuit in ipairs(self.ViewSuit_List) do
    local Item = self.Suit_List:GetItemByIndex(i - 1)
    Item:SetPlaySoundState(_IsPlaySound)
  end
end

function UMG_Appearance_Suit_C:SetWardrobeIndex(index)
  self.Suit_List:SelectItemByIndex(index)
  self._lastSetSuitListSelectIndex = index
end

function UMG_Appearance_Suit_C:OnDestruct()
  if self.bLobbyMain then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenWorldWardrobe, false)
  end
end

function UMG_Appearance_Suit_C:OnSuitBtnClicked()
  self.ShowSuitList = not self.ShowSuitList
  if self.ShowSuitList then
    _G.NRCAudioManager:PlaySound2DAuto(40008025, "UMG_Appearance_Suit_C:OnSuitBtnClicked1")
    self:PlayAnimation(self.In)
    self.BlackCover:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_CloseSuit:SetVisibility(UE4.ESlateVisibility.Visible)
    self.An2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self._firstOpenSuitList == false and self._lastSetSuitListSelectIndex then
      self:SetWardrobeIndex(self._lastSetSuitListSelectIndex)
      self._firstOpenSuitList = true
    end
    self.NotExpanded2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.parent then
      self.parent:OnSuitButtonClicked(true)
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(40002002, "UMG_Appearance_Suit_C:OnSuitBtnClicked2")
    self:PlayAnimation(self.Out)
    self.BlackCover:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_CloseSuit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NotExpanded2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.parent then
      self.parent:OnSuitButtonClicked(false)
    end
  end
end

function UMG_Appearance_Suit_C:OnClickBtnPressed()
  self:PlayAnimation(self.Btn_Press)
end

function UMG_Appearance_Suit_C:OnClickBtnReleased()
  self:PlayAnimation(self.Btn_Recover)
end

function UMG_Appearance_Suit_C:OnCloseSuitBtnClicked()
  self.BlackCover:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Appearance_Suit_C:ClosePanel()
  self:DoClose()
end

function UMG_Appearance_Suit_C:SetShowDots()
  local pageNum = self.ScrollPageController:GetTotalPageNum()
  if pageNum > 1 then
    self.HorizontalBox_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.HorizontalBox_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Appearance_Suit_C:SetScrollToPage(_curIndex)
  if nil == _curIndex then
    return
  end
  if _curIndex < 5 then
    self.ScrollPageController:ScrollToPage(0, 0.1)
  else
    self.ScrollPageController:ScrollToPage(1, 0.1)
  end
end

function UMG_Appearance_Suit_C:OnPageChangeHandle(_page)
  if 0 ~= _page then
    self.NRCImage_158:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
    self.NRCImage_20:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#929086FF"))
  else
    self.NRCImage_158:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#929086FF"))
    self.NRCImage_20:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
  end
end

function UMG_Appearance_Suit_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self.An2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Appearance_Suit_C:UpdateSuitBtnIconOnSelection(iconPath)
  if string.IsNilOrEmpty(iconPath) then
    self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.icon:SetPathWithSuccessAndFailedCallBack(iconPath, {
      self,
      self.OnIconSetPathSuccess
    }, {
      self,
      self.OnIconSetPathFailed
    })
  end
end

function UMG_Appearance_Suit_C:OnIconSetPathSuccess()
  self.icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Appearance_Suit_C:OnIconSetPathFailed()
  self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_Appearance_Suit_C
