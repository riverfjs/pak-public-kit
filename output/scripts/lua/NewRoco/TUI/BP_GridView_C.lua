local BP_GridView_C = NRCUmgClass:Extend("BP_GridView_C")

function BP_GridView_C:Ctor()
  self._listDatas = nil
  self._itemData = nil
  self._selectedItem = nil
  self._selectedItemIndex = -1
  self._bMultipleChoice = false
  self.tempOpItem = nil
  self._selectedIndices = {}
  self._selectedItems = {}
end

function BP_GridView_C:SetCustomData(customData)
  self._customData = customData
end

function BP_GridView_C:InitGridView(_itemDatas)
  if not _itemDatas then
    return
  end
  self._listDatas = _itemDatas
  local count = #self._listDatas
  self:SetItemCount(count)
  self:Init()
end

function BP_GridView_C:GetSelectedItem()
  if self._bMultipleChoice then
    return self._selectedItems
  end
  return self._selectedItem
end

function BP_GridView_C:GetSelectedIndex()
  if self._bMultipleChoice then
    return self._selectedIndices
  end
  return self._selectedItemIndex
end

function BP_GridView_C:HandleItemSelected(item, index)
  if self._itemCanSelectChecker then
    local canClick = self._itemCanSelectChecker(item, index)
    if not canClick then
      return
    end
  end
  self._selectedItemIndex = index
  if item.clickable then
    if self._bMultipleChoice == false then
      if self._selectedItem and UE4.UObject.IsValid(self._selectedItem) and self._selectedItem ~= item then
        self._selectedItem:OnItemSelected(false)
      end
      self._selectedItem = item
      if self._selectedItem then
        Log.Debug("BP_GridView_C:HandleItemSelected1", index)
        self:OnChildItemClick(item, index)
      end
    else
      self:OnChildItemClick(item, index)
    end
  end
end

function BP_GridView_C:SetMultipleChoice(bool)
  self._bMultipleChoice = bool
end

function BP_GridView_C:GetMultipleChoice()
  return self._bMultipleChoice
end

function BP_GridView_C:SetItemCanSelectChecker(funChecker, funSelf)
  self._itemCanSelectChecker = _G.MakeWeakFunctor(funSelf, funChecker)
end

function BP_GridView_C:SetItemCanClickChecker(funChecker, funSelf)
  self._itemCanClickChecker = _G.MakeWeakFunctor(funSelf, funChecker)
end

function BP_GridView_C:OnChildItemClick(item, index, userClick)
  if self._itemCanClickChecker then
    local canClick = self._itemCanClickChecker(item, index, userClick)
    if not canClick then
      return
    end
  end
  if item.clickable then
    item:OnItemClicked(true)
    if item.selectable then
      item.isSelected = not item.isSelected
      if self._bMultipleChoice == false then
        if self._selectedItem and self._selectedItem ~= item then
          self._selectedItem:SetSelectItem(item)
          item:SetSelectFalseItem(self._selectedItem)
          self._selectedItem.isSelected = not self._selectedItem.isSelected
          self._selectedItem:OnItemSelected(false, nil, userClick)
        end
        if self._selectedItem and self._selectedItem == item then
          item:SetSelectFalseItem(self._selectedItem)
        end
        if item.BroadcastOnClicked then
          item:BroadcastOnClicked()
        end
        self._selectedItem = item
        self._selectedItemIndex = index
        self._selectedItem:OnItemSelected(true, nil, userClick)
      elseif item.isSelected then
        self._selectedItem = item
        self._selectedItemIndex = index
        self._selectedItems[index + 1] = item
        self._selectedIndices[index + 1] = index
        self._selectedItems[index + 1]:OnItemSelected(item.isSelected)
      else
        if self._selectedItem == item then
          self._selectedItem = nil
          self._selectedItemIndex = -1
        end
        self._selectedItems[index + 1] = nil
        self._selectedIndices[index + 1] = nil
        item:OnItemSelected(item.isSelected, nil, userClick)
      end
    end
  else
    item:OnItemClicked(false)
  end
end

function BP_GridView_C:Destruct()
  self._listDatas = nil
  self._itemData = nil
  self._selectedItem = nil
  self.tempOpItem = nil
  self:ReleaseForce()
end

function BP_GridView_C:ClearSelection()
  if self._bMultipleChoice then
    for index, _ in pairs(self._selectedIndices) do
      self:DeselectItemByIndex(index)
    end
  elseif self._selectedItem then
    self._selectedItem.isSelected = false
    if UE4.UObject.IsValid(self._selectedItem) then
      self._selectedItem:OnItemSelected(false)
    end
    self._selectedItem = nil
    self._selectedItemIndex = -1
  end
end

function BP_GridView_C:DeselectItemByIndex(index)
  if not self._bMultipleChoice then
    return
  end
  if index < 1 or index > #self._listDatas then
    Log.Warning("DeselectItemByIndex invalid index:" .. tostring(index))
    return
  end
  local item = self:GetItemByIndex(index - 1)
  if item and self._selectedIndices[index] then
    item.isSelected = false
    item:OnItemSelected(false)
    if self._selectedItem == self._selectedItems[index] then
      self._selectedItem = nil
      self._selectedItemIndex = -1
    end
    self._selectedIndices[index] = nil
    self._selectedItems[index] = nil
    Log.Debug("Item deselected at index:", index)
  end
end

function BP_GridView_C:IsItemIndexSelected(index)
  return self._selectedItemIndex + 1 == index
end

function BP_GridView_C:IsHaveItemIndexSelected()
  return self._selectedItemIndex >= 0
end

function BP_GridView_C:SetItemClickAble(clickable)
  local itemCount = self:GetItemCount()
  for i = 1, itemCount do
    local itemData = self:GetItemByIndex(i - 1)
    if itemData then
      itemData.clickable = clickable
    end
  end
end

function BP_GridView_C:SetItemClickAbleByIndex(clickable, index)
  local itemData = self:GetItemByIndex(index - 1)
  if itemData then
    itemData.clickable = clickable
  end
end

function BP_GridView_C:GetIndexByData(_data, _compareFunc)
  if self._listDatas and _data then
    for _index, _value in ipairs(self._listDatas) do
      if _compareFunc then
        if _compareFunc(_data, _value) then
          return _index
        end
      elseif _value == _data then
        return _index
      end
    end
  end
end

function BP_GridView_C:GetDataByIndex(index)
  if self._listDatas and index > 0 then
    return self._listDatas[index]
  end
end

function BP_GridView_C:OpItemByIndex(index, opType, ...)
  self.tempOpItem = self:GetItemByIndex(index - 1)
  if self.tempOpItem then
    return self.tempOpItem:OpItem(opType, ...)
  end
end

function BP_GridView_C:SetMsgHandler(handler)
  self.msgHandler = handler
end

function BP_GridView_C:OnMsg(msg, ...)
  local msgHandler = self.msgHandler
  if msgHandler then
    local handler = msgHandler[msg]
    if handler then
      handler(...)
    end
  end
end

return BP_GridView_C
