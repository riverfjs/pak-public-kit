local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local BigMapModuleEvent = require("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local UMG_ComboBox_C = _G.NRCPanelBase:Extend("UMG_ComboBox_C")

function UMG_ComboBox_C:OnConstruct()
  self.CommonDropDownListData = nil
  self:OnAddEventListener()
  self.bShowList = false
  self.module = _G.NRCModuleManager:GetModule("CommonPopUpModule")
end

function UMG_ComboBox_C:OnActive()
end

function UMG_ComboBox_C:OnDeactive()
end

function UMG_ComboBox_C:OnAddEventListener()
  if self.Btn_ComboBox then
    _G.NRCEventCenter:RegisterEvent("UMG_ComboBox_C", self, NRCGlobalEvent.OnComboBoxSelectChanged, self.SelectItem)
    self:AddButtonListener(self.Btn_ComboBox, self.OnBtnComboBoxClicked)
  end
  if self.ScreeningBtn then
    self:AddButtonListener(self.ScreeningBtn.btnLevelUp, self.OnScreeningBtnClicked)
  end
  if self.ScreeningBtn_1 then
    self:AddButtonListener(self.ScreeningBtn_1.btnLevelUp, self.OnBtnComboBoxClicked)
  end
  if self.SortingBtn then
    self:AddButtonListener(self.SortingBtn.btnLevelUp, self.OnSortingBtnClicked)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_ComboBox_C", self, BigMapModuleEvent.ExcludeUmgPanelEvent, self.ExcludeUmgPanel)
end

function UMG_ComboBox_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnComboBoxSelectChanged, self.SelectItem)
  _G.NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.ExcludeUmgPanelEvent, self.ExcludeUmgPanel)
end

function UMG_ComboBox_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_ComboBox_C:SetPanelInfo(CommonDropDownListData)
  self.CommonDropDownListData = CommonDropDownListData
  if self.Btn_ComboBox then
    if self.CommonDropDownListData.DropDownListInfo then
      if self.NRCSwitcher_1 then
        self.NRCSwitcher_1:SetActiveWidgetIndex(0)
      end
      if self.ScreeningBtn_1 then
        self.ScreeningBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.Btn_ComboBox:SetVisibility(UE4.ESlateVisibility.Visible)
      if self.CommonDropDownListData.ComType then
        if self.CommonDropDownListData.DropDownListIndex then
          self:SetShowList(self.CommonDropDownListData.DropDownListInfo, self.CommonDropDownListData.DropDownListIndex, self.CommonDropDownListData.ComType)
        else
          self:SetShowList(self.CommonDropDownListData.DropDownListInfo, 1, self.CommonDropDownListData.ComType)
        end
      elseif self.CommonDropDownListData.DropDownListIndex then
        self:SetShowList(self.CommonDropDownListData.DropDownListInfo, self.CommonDropDownListData.DropDownListIndex, nil)
      else
        self:SetShowList(self.CommonDropDownListData.DropDownListInfo, 1, nil)
      end
      if self.Text then
        if self.CommonDropDownListData.DropDownListText then
          self.Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Text:SetText(self.CommonDropDownListData.DropDownListText)
        else
          self.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      if self.Icon then
        if self.CommonDropDownListData.DropDownListIcon then
          self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Icon:SetPath(self.CommonDropDownListData.DropDownListIcon)
        else
          self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    else
      if self.CommonDropDownListData.Btn_MidHandler then
        if self.NRCSwitcher_1 then
          if self.CommonDropDownListData.IsComboBox then
            self.NRCSwitcher_1:SetActiveWidgetIndex(0)
          else
            self.NRCSwitcher_1:SetActiveWidgetIndex(1)
          end
        end
        if self.ScreeningBtn_1 then
          self.ScreeningBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
        end
        self.Btn_ComboBox:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        if self.NRCSwitcher_1 then
          self.NRCSwitcher_1:SetActiveWidgetIndex(0)
        end
        if self.ScreeningBtn_1 then
          self.ScreeningBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        self.Btn_ComboBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.RedDot then
        self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  if self.ScreeningBtn then
    if self.CommonDropDownListData.Btn_LeftHandler then
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.SortingBtn then
    if self.CommonDropDownListData.Btn_RightHandler then
      self.SortingBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.SortingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ComboBox_C:SetComboText(text)
  if self.Text then
    if text then
      self.Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text:SetText(text)
    else
      self.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ComboBox_C:OnItemSelectedTextChange(selectIndex)
  for i = 1, self.ComboBox_Popup.List_title:GetItemCount() do
    local item = self.ComboBox_Popup.List_title:GetItemByIndex(i - 1)
    if i == selectIndex then
      item:OnItemSelectedTextChange(true)
    else
      item:OnItemSelectedTextChange(false)
    end
  end
end

function UMG_ComboBox_C:SetShowList(data, index, ComType)
  if ComType then
    self.ComType = ComType
    if self.RedDot then
      self.RedDot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.ComType == CommonBtnEnum.ComboBoxType.BigMap then
        self.RedDot:SetupKey(244)
        local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_WORLD_MAP_NEW)
        if self.module.HiddenRedPointList then
          for i, OldHiddenRedPoint in ipairs(self.module.HiddenRedPointList) do
            _G.NRCModeManager:DoCmd(RedPointModuleCmd.RecoverPointData, 243, {OldHiddenRedPoint})
          end
        else
          self.module.HiddenRedPointList = {}
        end
        local curHiddenRedPointList = {}
        if redDotData then
          local keys = {}
          for i in pairs(redDotData) do
            table.insert(keys, i)
          end
          table.sort(keys, function(a, b)
            return b < a
          end)
          for _, l in ipairs(keys) do
            local find = false
            for k, v in pairs(data) do
              if tonumber(redDotData[l]) == v.mapRedDotExtraKey then
                find = true
                break
              end
            end
            if not find then
              table.insert(curHiddenRedPointList, tonumber(redDotData[l]))
            end
          end
        end
        if #self.module.HiddenRedPointList > 0 then
          for i, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
            _G.NRCModeManager:DoCmd(RedPointModuleCmd.InvalidPointData, 243, {NewHiddenRedPoint})
          end
          for i, OldHiddenRedPoint in ipairs(self.module.HiddenRedPointList) do
            local find = false
            for _, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
              if OldHiddenRedPoint == NewHiddenRedPoint then
                find = true
                break
              end
            end
            if not find then
              _G.NRCModeManager:DoCmd(RedPointModuleCmd.RecoverPointData, 243, {OldHiddenRedPoint})
            end
          end
        else
          for _, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
            _G.NRCModeManager:DoCmd(RedPointModuleCmd.InvalidPointData, 243, {NewHiddenRedPoint})
          end
        end
        self.module.HiddenRedPointList = curHiddenRedPointList
      elseif self.ComType == CommonBtnEnum.ComboBoxType.MagicManual then
        self.RedDot:SetupKey(167)
      elseif self.ComType == CommonBtnEnum.ComboBoxType.InheritanceReplacePet then
        self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif self.ComType == CommonBtnEnum.ComboBoxType.Bag then
      elseif self.ComType == CommonBtnEnum.ComboBoxType.HomePlantGuard then
      elseif self.ComType == CommonBtnEnum.ComboBoxType.PetFeeding then
      elseif self.ComType == CommonBtnEnum.ComboBoxType.GorgeousMedal then
      elseif self.ComType == CommonBtnEnum.ComboBoxType.CertificationActivity then
      else
        self.RedDot:SetupKey(244)
      end
    end
  elseif self.RedDot then
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.uiData = data
  local showIndex = index - 1
  if self.ComboBox_Popup.SetListTitle then
    self.ComboBox_Popup:SetListTitle(data)
  else
    self.ComboBox_Popup.List_title:InitList(data)
  end
  if showIndex >= 0 and self.ComboBox_Popup.List_title:GetItemByIndex(showIndex) then
    if self.ComboBox_Popup.SelectListItem then
      self.ComboBox_Popup:SelectListItem(showIndex)
    else
      self.ComboBox_Popup.List_title:SelectItemByIndex(showIndex)
    end
  end
  for i = 1, self.ComboBox_Popup.List_title:GetItemCount() do
    local item = self.ComboBox_Popup.List_title:GetItemByIndex(i - 1)
    if self.Text then
      item.normalTextColor = self.Text.ColorAndOpacity
    end
  end
end

function UMG_ComboBox_C:UpdateData(data)
  self.uiData = data
  if self.ComboBox_Popup.SetListTitle then
    self.ComboBox_Popup:SetListTitle(data)
  else
    self.ComboBox_Popup.List_title:InitList(data)
  end
end

function UMG_ComboBox_C:ExcludeUmgPanel(name)
  if "UMG_ComboBox" ~= name then
    self:SetPopupVisible(false)
  end
end

function UMG_ComboBox_C:SelectItem(index, dataList)
  if self.uiData ~= dataList then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40003001, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  local showData = self.uiData[index]
  self.Text:SetText(showData.name)
  self:SetPopupVisible(false)
  if BigMapModuleCmd then
    _G.NRCModeManager:DoCmd(BigMapModuleCmd.CloseMapRightPanel)
  end
end

function UMG_ComboBox_C:OnComboBtnClicked()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ComboBox_C:OnBtnComboBoxClicked")
  if BagModuleCmd then
    _G.NRCModuleManager:DoCmd(BagModuleCmd.ShowCloseBtnPanel)
  end
  local bShowList = not self.bShowList
  if bShowList then
    _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.ExcludeUmgPanelEvent, "UMG_ComboBox")
  end
  self:SetPopupVisible(bShowList)
end

function UMG_ComboBox_C:OnBtnComboBoxClicked()
  if not self.CommonDropDownListData then
    Log.Warning("\230\178\161\230\156\137\232\174\190\231\189\174CommonDropDownListData\239\188\140\230\151\160\230\179\149\228\189\191\231\148\168\228\184\139\230\139\137\230\161\134\229\138\159\232\131\189")
    return
  end
  if self.CommonDropDownListData.DropDownListInfo then
    self:OnComboBtnClicked()
  elseif self.CommonDropDownListData and self.CommonDropDownListData.Call and self.CommonDropDownListData.Btn_MidHandler then
    self.CommonDropDownListData.Btn_MidHandler(self.CommonDropDownListData.Call)
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ComboBox_C:OnBtnComboBoxClicked")
  end
end

function UMG_ComboBox_C:OnScreeningBtnClicked()
  if self.CommonDropDownListData and self.CommonDropDownListData.Call and self.CommonDropDownListData.Btn_LeftHandler then
    self.CommonDropDownListData.Btn_LeftHandler(self.CommonDropDownListData.Call)
    _G.NRCAudioManager:PlaySound2DAuto(1288, "UMG_ComboBox_C:OnScreeningBtnClicked")
  end
end

function UMG_ComboBox_C:OnSortingBtnClicked()
  if self.CommonDropDownListData and self.CommonDropDownListData.Call and self.CommonDropDownListData.Btn_RightHandler then
    self.CommonDropDownListData.Btn_RightHandler(self.CommonDropDownListData.Call)
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ComboBox_C:OnSortingBtnClicked")
  end
end

function UMG_ComboBox_C:ShowOrHideBtnLeft(_IsShow, bNeedCollapsed)
  if self.ScreeningBtn then
    if _IsShow then
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif bNeedCollapsed then
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_ComboBox_C:ShowOrHideBtnMid(_IsShow)
  if self.CanvasPanel then
    if _IsShow then
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_ComboBox_C:ShowOrHideComboBox(_IsShow)
  if self.CanvasPanel_0 then
    if _IsShow then
      self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_ComboBox_C:SetScreeningBtnIcon(Path)
  if self.ScreeningBtn then
    self.ScreeningBtn:SetPath(Path, Path, Path)
  end
end

function UMG_ComboBox_C:ShowOrHideBtnRight(_IsShow, bNeedCollapsed)
  if self.SortingBtn then
    if _IsShow then
      self.SortingBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif bNeedCollapsed then
      self.SortingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.SortingBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_ComboBox_C:SetPopupVisible(bShow)
  if self.bShowList == bShow then
    return
  end
  if bShow then
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.Arrow then
      self.Arrow:SetRenderScale(UE4.FVector2D(-1, -1))
    end
    self:PlayAnimation(self.In)
  else
    if self.Arrow then
      self.Arrow:SetRenderScale(UE4.FVector2D(-1, 1))
    end
    self:PlayAnimation(self.Out)
  end
  self.bShowList = bShow
  if self.OnPopupVisibilityChanged then
    self.OnPopupVisibilityChanged(bShow)
  end
end

function UMG_ComboBox_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_ComboBox_C
