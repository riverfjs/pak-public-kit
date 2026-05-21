local UMG_Activity_CollegeCamp_C = _G.NRCPanelBase:Extend("UMG_Activity_CollegeCamp_C")

function UMG_Activity_CollegeCamp_C:OnConstruct()
  self:SetChildViews(self.CollegeCamp_Item, self.CollegeCamp_Item_1, self.CollegeCamp_Item_2, self.CollegeCamp_Item_3)
  self.items = {
    self.CollegeCamp_Item,
    self.CollegeCamp_Item_1,
    self.CollegeCamp_Item_2,
    self.CollegeCamp_Item_3
  }
  self:AddButtonListener(self.BtnClose, self.OnClickCancel)
  self:AddButtonListener(self.ConfirmBtn.btnLevelUp, self.OnClickOk)
  self:AddButtonListener(self.CancelBtn.btnLevelUp, self.OnClickCancel)
end

function UMG_Activity_CollegeCamp_C:OnActive(data)
  self.data = data
  self:SetDesc(data.defaultTips)
  if not string.IsNilOrEmpty(data.leftBtnText) then
    self.CancelBtn:SetBtnText(data.leftBtnText)
  end
  if not string.IsNilOrEmpty(data.rightBtnText) then
    self.ConfirmBtn:SetBtnText(data.rightBtnText)
    self.ConfirmGrayBtn:SetBtnText(data.rightBtnText)
  end
  local items = self.items
  for i, item in ipairs(items) do
    local entry = data.itemData and data.itemData[i]
    if entry then
      item:SetImage(entry.imagePath)
      item:SetRewards(entry.rewards)
      item:SetLocked(entry.isLocked, entry.lockDesc)
      item:SetCollected(entry.isCollected)
      item:SetDisableChoose(entry.disableChoose)
      item:SetClickCallback(_G.MakeWeakFunctor(self, self.OnSelectItem, i, entry))
      local hasExtraData = not string.IsNilOrEmpty(entry.extraDataIcon) or not string.IsNilOrEmpty(entry.extraDataDesc)
      item:SetExtraInfo(hasExtraData, entry.extraDataIcon, entry.extraDataDesc)
    else
      item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(40007007, "UMG_Activity_CollegeCamp_C:OnActive")
end

function UMG_Activity_CollegeCamp_C:SetDesc(desc)
  if string.IsNilOrEmpty(desc) then
    self.CanvasHint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CanvasHint:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Desc:SetText(desc)
  end
end

function UMG_Activity_CollegeCamp_C:OnPcClose()
  self:OnClickCancel()
end

function UMG_Activity_CollegeCamp_C:OnClickOk()
  local data = self.data
  if data and data.cxt then
    data.cxt:SetCallbackOkOnly(self, self.OnConfirmClickOk)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, data.cxt)
  else
    self:OnConfirmClickOk()
  end
end

function UMG_Activity_CollegeCamp_C:OnConfirmClickOk()
  local data = self.data
  if data and data.clickOkCallback then
    local curSelectItemIndex = self.selectItemIndex
    local selectItem = curSelectItemIndex and data.itemData and data.itemData[curSelectItemIndex]
    if selectItem then
      data.clickOkCallback(selectItem)
    end
  end
  self:OnClose()
end

function UMG_Activity_CollegeCamp_C:OnClickCancel()
  self:OnClose()
end

function UMG_Activity_CollegeCamp_C:OnSelectItem(itemIndex, itemInfo)
  local curSelectItemIndex = self.selectItemIndex
  if curSelectItemIndex == itemIndex then
    return
  end
  local itemInst = self.items[itemIndex]
  if itemInst then
    self.selectItemIndex = itemIndex
    if itemInfo then
      self:SetDesc(itemInfo.selectTips)
    end
    if itemInfo and itemInfo.isLocked then
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    end
    local preSelectItem = self.items[curSelectItemIndex]
    if preSelectItem then
      preSelectItem:SetSelected(false)
    end
    itemInst:SetSelected(true)
  end
end

return UMG_Activity_CollegeCamp_C
