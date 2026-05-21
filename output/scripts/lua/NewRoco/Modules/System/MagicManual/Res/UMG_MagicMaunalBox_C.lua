local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local UMG_MagicMaunalBox_C = _G.NRCPanelBase:Extend("UMG_MagicMaunalBox_C")

function UMG_MagicMaunalBox_C:OnConstruct()
  self.bShowList = false
  NRCEventCenter:RegisterEvent("UMG_MagicMaunalBox_C", self, MagicManualModuleEvent.OnMagicManualComBoxItemSelect, self.OnMagicManualComBoxItemSelect)
end

function UMG_MagicMaunalBox_C:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, MagicManualModuleEvent.OnMagicManualComBoxItemSelect, self.OnMagicManualComBoxItemSelect)
end

function UMG_MagicMaunalBox_C:OnMagicManualComBoxItemSelect(Index)
  if #self.ListInfo > 1 then
    for i, v in ipairs(self.ListInfo) do
      if i ~= Index then
        local item = self.ComboBox_Popup["Box" .. i]
        if item and item.MainPlotList then
          item.MainPlotList:ClearSelection()
        end
      end
    end
  end
end

function UMG_MagicMaunalBox_C:SetMagicManualComBoxItemBg(Normal, Select, SeasonBg, SeasonSelectBg, TextColor)
  if self.ListInfo then
    for i, v in ipairs(self.ListInfo) do
      local item = self.ComboBox_Popup["Box" .. i]
      if item and item.MainPlotList then
        local boxItemCount = item.MainPlotList:GetItemCount()
        for j = 1, boxItemCount do
          local boxItem = item.MainPlotList:GetItemByIndex(j - 1)
          if boxItem then
            boxItem:SetMagicManualComBoxItemBg(Normal, Select, SeasonBg, SeasonSelectBg, TextColor)
          end
        end
      end
    end
  end
end

function UMG_MagicMaunalBox_C:SetPanelInfo(CommonDropDownListData)
  if CommonDropDownListData then
    self.ListInfo = CommonDropDownListData.DropDownListInfo
    for i = 1, 2 do
      if i > #self.ListInfo then
        self.ComboBox_Popup["Box" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.ComboBox_Popup["Box" .. i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.ComboBox_Popup["Box" .. i]:OnItemUpdate(self.ListInfo[i])
      end
    end
    if CommonDropDownListData.DropDownListIndex then
      self.ComboBox_Popup["Box" .. CommonDropDownListData.DropDownListIndex]:OnItemSelected(true)
    end
  end
end

function UMG_MagicMaunalBox_C:OnComboBtnClicked()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  local bShowList = not self.bShowList
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ComboBox_C:OnBtnComboBoxClicked")
  self:SetPopupVisible(bShowList)
end

function UMG_MagicMaunalBox_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicMaunalBox_C:SetPopupVisible(bShow)
  if self.bShowList == bShow then
    return
  end
  if bShow then
    _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_MagicMaunalBox_C:SetPopupVisible")
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
  else
    if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      self.bShowList = bShow
      if self.OnPopupVisibilityChanged then
        self.OnPopupVisibilityChanged(bShow)
      end
      return
    end
    _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_MagicMaunalBox_C:SetPopupVisible")
    self:PlayAnimation(self.Out)
  end
  self.bShowList = bShow
  if self.OnPopupVisibilityChanged then
    self.OnPopupVisibilityChanged(bShow)
  end
end

function UMG_MagicMaunalBox_C:OnAddEventListener()
end

return UMG_MagicMaunalBox_C
