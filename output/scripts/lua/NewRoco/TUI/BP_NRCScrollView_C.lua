local BP_NRCScrollView_C = NRCUmgClass:Extend("BP_NRCScrollView_C")

function BP_NRCScrollView_C:Initialize()
  self:Ctor()
end

function BP_NRCScrollView_C:Ctor()
  NRCUmgClass.Ctor(self)
  self._listDatas = nil
  self._itemData = nil
  self._itemRef = {}
  self._selectedItem = nil
  self._selectedItemIndex = 0
  self.tempOpItem = nil
  self._bMultipleChoice = false
  self._selectedIndices = {}
  self._selectedItems = {}
  self:Construct()
end

function BP_NRCScrollView_C:Construct()
end

function BP_NRCScrollView_C:SetCustomData(customData)
  self._customData = customData
end

function BP_NRCScrollView_C:InitList(_itemDatas, bForceNoCreate)
  if not _itemDatas then
    Log.Error("BP_NRCScrollView_C:InitList itemData is nil")
    return
  end
  self._itemData = nil
  self._itemRef = {}
  self._selectedItem = nil
  self._selectedItemIndex = 0
  self._selectedIndices = {}
  self._selectedItems = {}
  if _itemDatas and #_itemDatas > 200 and self.bRecycle == false then
    Log.Error("\232\175\183\230\163\128\230\159\165\228\184\128\228\184\139\231\187\132\228\187\182Recycle\230\152\175\229\144\166\230\178\161\229\139\190\233\128\137\228\187\165\229\143\138\229\136\157\229\167\139\229\140\150\230\149\176\230\141\174\230\152\175\229\144\166\230\173\163\231\161\174\239\188\140\233\152\178\230\173\162object\232\191\135\229\164\154crash")
    return
  end
  self._listDatas = _itemDatas
  self:SetItemCount(#self._listDatas)
  if bForceNoCreate then
    self:UpdateList(self._listDatas, -1)
  else
    self:PreCreatePanel()
  end
  for i = 1, #self._listDatas do
    local item = self:GetItemByIndex(i - 1)
    if item and item.SetData then
      item:SetData(self._listDatas[i])
    end
    if item and item.SetIndex then
      item:SetIndex(i)
    end
    table.insert(self._itemRef, item)
    if item and item.OnItemSelected and self._bMultipleChoice then
      local ueIndex = i - 1
      if self._selectedIndices[i] == ueIndex then
        item.isSelected = true
        item:OnItemSelected(true, true)
      end
    end
  end
  if self.bRecycle == true and false == self.bUsePageController then
    local panel = self:GetChildAt(0)
    if panel then
      local subPanel = panel:GetChildAt(0)
      if subPanel then
        subPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  end
end

function BP_NRCScrollView_C:UpdateList(itemData, index)
  if index > 0 then
    self._listDatas[index] = itemData
    self:RefreshItemByIndex(index - 1)
  else
    self._listDatas = itemData
    for i = 1, #self._listDatas do
      self:RefreshItemByIndex(i - 1)
    end
  end
end

function BP_NRCScrollView_C:AddOrRemoveItem(bAdd, index, itemData, bAnim)
  if bAnim then
    if bAdd then
      if self._listDatas == nil then
        self._listDatas = {}
      end
      self:SetItemCount(#self._listDatas)
      self:AddOrRemoveCPP(bAdd, index)
      local ItemTemplate = self:GetItemByIndex(index - 1)
      if ItemTemplate then
        ItemTemplate:AddOrRemove(bAdd, bAnim)
      else
        Log.Error("ItemTemplate\230\137\190\228\184\141\229\136\176,\229\143\175\232\131\189\228\184\139\230\160\135\230\156\137\233\151\174\233\162\152", index, self:GetItemCount())
      end
    else
      local ItemTemplate = self:GetItemByIndex(index - 1)
      ItemTemplate:AddOrRemove(bAdd, bAnim)
    end
  elseif bAdd then
  else
    local ItemTemplate = self:GetItemByIndex(index - 1)
    table.remove(self._listDatas, index)
    ItemTemplate:AddOrRemove(bAdd, bAnim)
    self:AddOrRemoveCPP(bAdd, index)
  end
end

function BP_NRCScrollView_C:AddOrRemoveItemEx(bAdd, index, itemData)
  if self._listDatas == nil then
    self._listDatas = {}
  end
  if bAdd then
    if nil ~= itemData and self._listDatas[index] ~= itemData then
      table.insert(self._listDatas, index, itemData)
    end
    local targetCount = #self._listDatas
    local currentCount = targetCount
    if self.GetItemCount then
      currentCount = self:GetItemCount()
    end
    self:SetItemCount(targetCount)
    if targetCount > currentCount then
      self:AddOrRemoveCPP(true, index)
    end
    if self.RefreshItemByIndex then
      self:RefreshItemByIndex(index - 1)
    end
    local ItemTemplate = self:GetItemByIndex(index - 1)
    if ItemTemplate and ItemTemplate.AddOrRemove then
      ItemTemplate:AddOrRemove(true, false)
    end
    return
  end
  local ItemTemplate = self:GetItemByIndex(index - 1)
  if self._listDatas and index > 0 and index <= #self._listDatas then
    table.remove(self._listDatas, index)
  end
  if ItemTemplate and ItemTemplate.AddOrRemove then
    ItemTemplate:AddOrRemove(false, false)
  end
  self:AddOrRemoveCPP(false, index)
end

function BP_NRCScrollView_C:GetItemCountEx()
  return self._listDatas and #self._listDatas or 0
end

function BP_NRCScrollView_C:HandleItemSelected(item, index, bScrolled)
  if not item.clickable then
    return
  end
  if self._bMultipleChoice then
    local luaIndex = index + 1
    if item.OnItemSelected and self._selectedIndices[luaIndex] == index then
      item.isSelected = true
      item:OnItemSelected(true, bScrolled)
    end
    return
  end
  if self._selectedItem and self._selectedItem ~= item and UE4.UObject.IsValid(self._selectedItem) then
    if self._selectedItem._index == self._selectedItemIndex then
      self._selectedItem:OnItemSelected(false, bScrolled)
    elseif self._selectedItem._index ~= self._selectedItemIndex and not self._bMultipleChoice then
      self._selectedItem:OnItemSelected(false, bScrolled)
    end
  end
  self._selectedItemIndex = index + 1
  self.CurSelectedIndex = index
  self._selectedItem = item
  if self._selectedItem and UE4.UObject.IsValid(self._selectedItem) then
    self._selectedItem:OnItemSelected(true, bScrolled)
    if self._itemSelectedCallback then
      self._itemSelectedCallback(item, index)
    end
  end
end

function BP_NRCScrollView_C:HandleItemDespawned(item, index)
  if item.OnDespawn then
    item:OnDespawn()
  end
  if item.OnItemSelected and self._bMultipleChoice then
    item.isSelected = false
    item:OnItemSelected(false, true)
  end
end

function BP_NRCScrollView_C:HandleItemSpawned(item, index)
  if item.OnItemSelected then
    if self._bMultipleChoice then
      local luaIndex = index + 1
      local selected = self._selectedIndices[luaIndex] == index
      item.isSelected = selected
      item:OnItemSelected(selected, true)
    elseif self.CurSelectedIndex == index then
      self:HandleItemSelected(item, index, true)
    end
  end
  if item.OnSpawn then
    item:OnSpawn()
  end
end

function BP_NRCScrollView_C:OnVisibleRangeChanged(newFirstVisibleIndex, newLastVisibleIndex, oldFirstVisibleIndex, oldLastVisibleIndex)
  if self._onVisibleRangeChangedCallback then
    self._onVisibleRangeChangedCallback(newFirstVisibleIndex, newLastVisibleIndex, oldFirstVisibleIndex, oldLastVisibleIndex)
  end
end

function BP_NRCScrollView_C:SetOnVisibleRangeChangedCallback(funCallback, funSelf)
  self._onVisibleRangeChangedCallback = _G.MakeWeakFunctor(funSelf, funCallback)
end

function BP_NRCScrollView_C:OnScrollingEnded(SnappedIndex)
  if self._onScrollingEndedCallback then
    self._onScrollingEndedCallback(SnappedIndex)
  end
end

function BP_NRCScrollView_C:SetOnScrollingEndedCallback(funCallback, funSelf)
  self._onScrollingEndedCallback = _G.MakeWeakFunctor(funSelf, funCallback)
end

function BP_NRCScrollView_C:GetSelectedItem()
  if self._bMultipleChoice then
    return self._selectedItems
  end
  return self._selectedItem
end

function BP_NRCScrollView_C:SetItemCanClickChecker(funChecker, funSelf)
  self._itemCanClickChecker = _G.MakeWeakFunctor(funSelf, funChecker)
end

function BP_NRCScrollView_C:OnChildItemClick(item, index, userClick)
  if self._itemCanClickChecker then
    local canClick = self._itemCanClickChecker(item, index, userClick)
    if not canClick then
      return
    end
  end
  if item and item.clickable then
    if self._bMultipleChoice then
      local luaIndex = index + 1
      item:OnItemClicked(true)
      if item.selectable then
        item.isSelected = not item.isSelected
        if item.isSelected then
          self._selectedItem = item
          self._selectedItemIndex = luaIndex
          self.CurSelectedIndex = index
          self._selectedItems[luaIndex] = item
          self._selectedIndices[luaIndex] = index
          item:OnItemSelected(true)
        else
          if self._selectedItem == item then
            self._selectedItem = nil
            self._selectedItemIndex = 0
          end
          self._selectedItems[luaIndex] = nil
          self._selectedIndices[luaIndex] = nil
          item:OnItemSelected(false)
        end
      end
      if self._itemSelectedCallback then
        self._itemSelectedCallback(item, index, userClick)
      end
      return
    end
    if self._selectedItem and UE4.UObject.IsValid(self._selectedItem) and self._selectedItem ~= item and self._selectedItem._index == self._selectedItemIndex then
      self._selectedItem:OnItemSelected(false)
    end
    self._selectedItem = item
    self._selectedItemIndex = index + 1
    self.CurSelectedIndex = index
    if self._selectedItem.BroadcastOnClicked then
      self._selectedItem:BroadcastOnClicked()
    end
    self._selectedItem:OnItemSelected(true)
    if self._itemSelectedCallback then
      self._itemSelectedCallback(item, index, userClick)
    end
  end
end

function BP_NRCScrollView_C:SetItemSelectedCallback(funCallback, funSelf)
  self._itemSelectedCallback = _G.MakeWeakFunctor(funSelf, funCallback)
end

function BP_NRCScrollView_C:Destruct()
  self._itemRef = {}
  self.tempOpItem = nil
  self:TempDoDestruct()
  self:ReleaseForce()
end

function BP_NRCScrollView_C:ClearSelection()
  if self._bMultipleChoice then
    for luaIndex, ueIndex in pairs(self._selectedIndices) do
      local tempItem = self:GetItemByIndex(ueIndex)
      if tempItem and UE4.UObject.IsValid(tempItem) then
        tempItem.isSelected = false
        tempItem:OnItemSelected(false)
      end
      self._selectedItems[luaIndex] = nil
      self._selectedIndices[luaIndex] = nil
    end
    self._selectedItem = nil
    self._selectedItemIndex = 0
    self.CurSelectedIndex = -1
    return
  end
  if self._selectedItem then
    local tempItem = self:GetItemByIndex(self.CurSelectedIndex)
    if tempItem and UE4.UObject.IsValid(tempItem) then
      tempItem:OnItemSelected(false)
    end
    if UE4.UObject.IsValid(self._selectedItem) then
      self._selectedItem:OnItemSelected(false)
    end
    self._selectedItem = nil
    self._selectedItemIndex = 0
    self.CurSelectedIndex = -1
  end
end

function BP_NRCScrollView_C:DeselectItemByIndex(index)
  if not index or index <= 0 then
    return
  end
  if self._bMultipleChoice then
    local ueIndex = self._selectedIndices[index]
    if nil == ueIndex then
      return
    end
    local tempItem = self:GetItemByIndex(ueIndex)
    if tempItem and UE4.UObject.IsValid(tempItem) then
      tempItem.isSelected = false
      tempItem:OnItemSelected(false)
    end
    self._selectedItems[index] = nil
    self._selectedIndices[index] = nil
    if self._selectedItemIndex == index then
      self._selectedItem = nil
      self._selectedItemIndex = 0
      self.CurSelectedIndex = -1
    end
    return
  end
  if self._selectedItemIndex ~= index then
    return
  end
  local ueIndex = index - 1
  local tempItem = self:GetItemByIndex(ueIndex)
  if tempItem and UE4.UObject.IsValid(tempItem) then
    tempItem:OnItemSelected(false)
  end
  if self._selectedItem and UE4.UObject.IsValid(self._selectedItem) then
    self._selectedItem:OnItemSelected(false)
  end
  self._selectedItem = nil
  self._selectedItemIndex = 0
  self.CurSelectedIndex = -1
end

function BP_NRCScrollView_C:IsItemIndexSelected(index)
  if self._selectedItemIndex == index then
    return true
  else
    return false
  end
end

function BP_NRCScrollView_C:GetItems()
  local ResList = {}
  for i = 1, self.itemCount do
    ResList[i] = self:GetItemByIndex(i - 1)
  end
  return ResList
end

function BP_NRCScrollView_C:GetSelectedIndex()
  if self._bMultipleChoice then
    return self._selectedIndices
  end
  return self._selectedItemIndex
end

function BP_NRCScrollView_C:GetIndexByData(_data, _compareFunc)
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

function BP_NRCScrollView_C:GetDataByIndex(index)
  if self._listDatas and index > 0 then
    return self._listDatas[index]
  end
end

function BP_NRCScrollView_C:SetItemClickAble(clickable)
  if self._listDatas then
    for i = 1, #self._listDatas do
      local itemData = self:GetItemByIndex(i - 1)
      if itemData then
        itemData.clickable = clickable
      end
    end
  end
end

function BP_NRCScrollView_C:SetItemClickAbleByIndex(clickable, index)
  local itemData = self:GetItemByIndex(index - 1)
  if itemData then
    itemData.clickable = clickable
  end
end

function BP_NRCScrollView_C:OpItemByIndex(index, opType, ...)
  self.tempOpItem = self:GetItemByIndex(index - 1)
  if self.tempOpItem then
    return self.tempOpItem:OpItem(opType, ...)
  end
end

function BP_NRCScrollView_C:SetMsgHandler(handler)
  self.msgHandler = handler
end

function BP_NRCScrollView_C:OnMsg(msg, ...)
  local msgHandler = self.msgHandler
  if msgHandler then
    local handler = msgHandler[msg]
    if handler then
      handler(...)
    end
  end
end

function BP_NRCScrollView_C:SetMultipleChoice(bool)
  self._bMultipleChoice = bool
end

function BP_NRCScrollView_C:GetScrollViewLength()
  return #self._listDatas
end

return BP_NRCScrollView_C
