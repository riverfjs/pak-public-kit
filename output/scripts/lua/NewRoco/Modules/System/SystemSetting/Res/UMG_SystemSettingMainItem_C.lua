local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_SystemSettingMainItem_C = Base:Extend("UMG_SystemSettingMainItem_C")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")

function UMG_SystemSettingMainItem_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_SystemSettingMainItem_C:OnDestruct()
  self:RemoveAllButtonListener()
  if self.bAddListener then
    _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.OpenSelectionMenu, self.OpenSelectionMenu)
  end
  if self.Timer then
    _G.TimerManager:RemoveTimer(self.Timer)
    self.Timer = nil
  end
end

function UMG_SystemSettingMainItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.caller = _data.Call
  self.index = index
  if _data.CloseAnnotationBtn then
    self.CloseAnnotationBtn = _data.CloseAnnotationBtn
  end
  if not self.bAddListener then
    if _data.CloseSelectionBtn then
      self:AddButtonListener(_data.CloseSelectionBtn, self.CloseSelection)
    end
    if _data.CloseAnnotationBtn then
      self:AddButtonListener(_data.CloseAnnotationBtn, self.CloseDetailsText)
    end
    _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_Item_C", self, SystemSettingModuleEvent.OpenSelectionMenu, self.OpenSelectionMenu)
    self.bAddListener = true
  end
  self:InitInfo()
end

function UMG_SystemSettingMainItem_C:OnItemSelected(_bSelected)
  self.uiData.Call:OnHitTestBgBtn()
end

function UMG_SystemSettingMainItem_C:OnDeactive()
end

function UMG_SystemSettingMainItem_C:OnAddEventListener()
  if self.SettingBtn then
    self:AddButtonListener(self.SettingBtn.btnLevelUp, self.OnSettingBtnClicked)
  end
  if self.BtnDetails then
    self:AddButtonListener(self.BtnDetails.btnLevelUp, self.ShowDetailsText)
  end
  if self.Slider then
    self.Slider.OnValueChanged:Add(self, self.OnSliderValueChanged)
  end
end

function UMG_SystemSettingMainItem_C:InitInfo()
  if self.uiData.itemTitle then
    self.Title:SetText(self.uiData.itemTitle)
  end
  if self.uiData.bNeedDescribe then
    self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Visible)
    self.DetailTips.Title:SetText(self.uiData.describeText)
  else
    self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DetailTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.uiData.itemName then
    self.Name:SetText(self.uiData.itemName)
    self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.uiData.itemType then
    self.Switcher:SetActiveWidgetIndex(self.uiData.itemType - 1)
  end
  if self.uiData.DropDownListInfo and self.uiData.DropDownListKey and self.uiData.Call then
    self.DropDownList:InitUI(self)
    self.DropDownList:SetKeyAndOptions(self.uiData.DropDownListKey, self.uiData.DropDownListInfo, self.uiData.DropDownListExtraKey)
    if self.uiData.DropDownListSelectValue then
      self.DropDownList:SetSelectedValue(self.uiData.DropDownListSelectValue)
    end
  end
  if self.uiData.settingBtnText then
    self.SettingBtn:SetBtnText(self.uiData.settingBtnText)
  end
  if self.uiData.bNeedSettingBtnIcon then
    self.SettingBtn.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.SettingBtn.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.uiData.switchBtnListInfo and self.uiData.switchBtnListKey and self.uiData.Call then
    for i = 1, #self.uiData.switchBtnListInfo do
      local item = self.uiData.switchBtnListInfo[i]
      item.Parent = self
    end
    if not self.uiData.bIsBanRefreshSwitchBtnList then
      self.SwitchBtnList:InitGridView(self.uiData.switchBtnListInfo)
      self.SwitchBtnList:SelectItemByIndex(self.uiData.switchBtnListKey)
    end
    for i = 1, self.SwitchBtnList:GetItemCount() do
      local item = self.SwitchBtnList:GetItemByIndex(i - 1)
      if item.bIsFirstSelect then
        item.bIsFirstSelect = false
        item.Text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#c4c2b3"))
      end
    end
  end
  if self.uiData.countDownTimeStamp then
    self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local statusStamp = self.uiData.countDownTimeStamp
    local currentTime = _G.ZoneServer:GetServerTime() / 1000
    if currentTime - statusStamp >= 0 then
      self.leftTime = 259200 - (currentTime - statusStamp)
      if self.leftTime > 0 then
        self:SetTimeText(self.leftTime)
        if self.Timer then
          _G.TimerManager:RemoveTimer(self.Timer)
          self.Timer = nil
        end
        self.Timer = _G.TimerManager:CreateTimer(self, "UMG_SystemSettingMainItem_C", self.leftTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
      else
        if statusStamp <= 0 then
          Log.Error("\228\188\160\229\133\165\231\154\132\229\128\146\232\174\161\230\151\182\230\151\182\233\151\180\230\136\179\229\188\130\229\184\184!!!")
        end
        self.Time:SetText("00:00:00")
      end
    end
  else
    self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.uiData.IsHideBtn then
    self.SettingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SettingBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_SystemSettingMainItem_C:SetTimeText(leftTime)
  local hour = math.floor(leftTime / 3600)
  local minute = math.floor((leftTime - 3600 * hour) / 60)
  local sec = math.floor(leftTime - 3600 * hour - 60 * minute)
  self.Time:SetText(string.format("%02d:%02d:%02d)", hour, minute, sec))
end

function UMG_SystemSettingMainItem_C:OnTimerUpdate()
  local statusStamp = 0
  if self.uiData.isSecondaryPasswordCountdown then
    local passwordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
    if passwordInfo and passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
      statusStamp = passwordInfo.status_timestamp
    end
  end
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  if currentTime - statusStamp > 0 then
    self.leftTime = 259200 - (currentTime - statusStamp)
    if self.leftTime > 0 then
      self:SetTimeText(self.leftTime)
    end
  end
end

function UMG_SystemSettingMainItem_C:OnTimerEnd()
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, ProtoEnum.SecondaryPasswordStatus.SPS_Unset, 0, 0)
end

function UMG_SystemSettingMainItem_C:DisableClick()
  self.uiData.Call:DisableClick()
end

function UMG_SystemSettingMainItem_C:OnSliderValueChanged(value)
  if self.uiData.Call and self.uiData.sliderHandler then
    self.uiData.sliderHandler(self.uiData.Call, math.floor(value), self.Slider, self.Text, self.Progress)
  end
end

function UMG_SystemSettingMainItem_C:ShowDropDownListCallback(DropDownList)
  local selectValue = self.DropDownList:GetSelectedValue()
  local index = self:FindOptionIndexByValue(selectValue)
  if self.DropDownList.IsOpenMenu then
    self.DropDownList:ScrollToSelectOption(index)
  end
  self.caller:ShowDropDownListCallback(DropDownList)
end

function UMG_SystemSettingMainItem_C:FindOptionIndexByValue(value)
  for index, option in ipairs(self.uiData.DropDownListInfo) do
    if option.Value == value then
      return index
    end
  end
  return 1
end

function UMG_SystemSettingMainItem_C:SetNameText(text)
  if self.Name then
    self.Name:SetText(text)
    self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SystemSettingMainItem_C:ShowDetailsText()
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_SystemSettingMain_Item_C:ShowDetailsText")
  self.CloseAnnotationBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self.DetailTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.bShowDetails = true
  self.caller:ScrollToItemOnDetailTipsShow(self.index, self.uiData.parentList)
end

function UMG_SystemSettingMainItem_C:CloseDetailsText()
  if self.bShowDetails then
    _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_SystemSettingMain_Item_C:CloseDetailsText")
    self.CloseAnnotationBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DetailTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bShowDetails = false
end

function UMG_SystemSettingMainItem_C:CloseSelection()
  if self.DropDownList.IsOpenMenu then
    self.DropDownList:OnShowBtnClick()
  end
end

function UMG_SystemSettingMainItem_C:OpenSelectionMenu(DropDownList)
  if DropDownList and self.DropDownList ~= DropDownList then
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_SystemSettingMainItem_C:SetSettingBtnHandler(settingBtnHandler)
  if settingBtnHandler and self.uiData.Call and self.uiData.settingBtnHandler then
    self.uiData.settingBtnHandler = settingBtnHandler
  end
end

function UMG_SystemSettingMainItem_C:SelectSwitchBtnListByIndex(index)
  if self.SwitchBtnList then
    self.SwitchBtnList:SelectItemByIndex(index)
  end
end

function UMG_SystemSettingMainItem_C:SwitchBtnListSelected()
  if self.SwitchBtnList then
    for i = 1, self.SwitchBtnList:GetItemCount() do
      local item = self.SwitchBtnList:GetItemByIndex(i - 1)
      if item.bSelected == false then
        self.SwitchBtnList:SelectItemByIndex(i - 1)
        break
      end
    end
  end
end

function UMG_SystemSettingMainItem_C:IsSwtichBtnSelected(index)
  local switchBtn = self.SwitchBtnList:GetItemByIndex(index)
  return switchBtn.bSelected
end

function UMG_SystemSettingMainItem_C:RefreshSwitchBtnState(index)
  local selectItem = self.SwitchBtnList:GetItemByIndex(index)
  if not selectItem.bSelected and self.SwitchBtnList then
    for i = 1, self.SwitchBtnList:GetItemCount() do
      local item = self.SwitchBtnList:GetItemByIndex(i - 1)
      if item.bSelected then
        item.bSelected = false
        item:PlayAnimationReverse(item.Select_In)
      else
        item.bSelected = true
        item.SelectBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        item:PlayAnimation(item.Select_In)
      end
    end
  end
end

function UMG_SystemSettingMainItem_C:RefreshSwitchBtnList(keyIndex)
  if self.uiData.switchBtnListInfo and keyIndex and self.uiData.Call then
    for i = 1, #self.uiData.switchBtnListInfo do
      local item = self.uiData.switchBtnListInfo[i]
      item.Parent = self
    end
    self.SwitchBtnList:InitGridView(self.uiData.switchBtnListInfo)
    self.SwitchBtnList:SelectItemByIndex(keyIndex)
    for i = 1, self.SwitchBtnList:GetItemCount() do
      local item = self.SwitchBtnList:GetItemByIndex(i - 1)
      if item.bIsFirstSelect then
        item.bIsFirstSelect = false
        item.Text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#c4c2b3"))
      end
    end
  end
end

function UMG_SystemSettingMainItem_C:OnSettingBtnClicked()
  if self.uiData.Call and self.uiData.settingBtnHandler then
    self.uiData.settingBtnHandler(self.uiData.Call)
  end
end

function UMG_SystemSettingMainItem_C:SetTitle(text)
  if text then
    self.Title:SetText(text)
    self.Title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Title:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SystemSettingMainItem_C:UpdatePhoneArea(data)
  if data.settingBtnText then
    self.uiData.settingBtnText = data.settingBtnText
    self.SettingBtn:SetBtnText(self.uiData.settingBtnText)
  end
  if data.itemName then
    self.uiData.itemName = data.itemName
    self.Name:SetText(self.uiData.itemName)
    self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.uiData.IsHideBtn = data.IsHideBtn
  if self.uiData.IsHideBtn then
    self.SettingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SettingBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_SystemSettingMainItem_C:SetDisableGreyState(bDisable)
  if bDisable then
    self.DropDownList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Title:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605eFF"))
    self.DropDownList:SetDisableGrey(true)
  else
    self.DropDownList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Title:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F3EDDFFF"))
    self.DropDownList:SetDisableGrey(false)
  end
end

return UMG_SystemSettingMainItem_C
