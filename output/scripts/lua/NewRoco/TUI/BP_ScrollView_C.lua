local BP_ScrollView_C = NRCUmgClass:Extend("BP_ScrollView_C")

function BP_ScrollView_C:Construct()
  self._datas = nil
  self._selectedItem = nil
  self._selectedItemIndex = 0
  self.OnItemSelected = nil
  self._caller = nil
  self.pageNum = 1
  self._pageOriDatas = nil
  self.OnPageSubItemSelected = nil
  self._itemDic = {}
end

function BP_ScrollView_C:SetPageNum(pageNum)
  self.pageNum = pageNum
end

function BP_ScrollView_C:IsPageModeEnable()
  if self.pageNum ~= nil and self.pageNum > 1 then
    return true
  end
  return false
end

function BP_ScrollView_C:SetDatasUnShow(datas)
  for i = 1, #self._itemDic do
    if self._itemDic[i] ~= nil and datas ~= nils then
      self._itemDic[i]:SetDataUnShow(datas)
    end
  end
end

function BP_ScrollView_C:SetDatas(datas)
  if not datas then
    return
  end
  local count = 0
  if self:IsPageModeEnable() then
    local pageDataList = {}
    local pageCount = math.ceil(#datas / self.pageNum)
    for i = 1, pageCount do
      local pageData = {}
      table.insert(pageDataList, pageData)
      local index = (i - 1) * self.pageNum + 1
      while index <= i * self.pageNum and index <= #datas do
        table.insert(pageData, datas[index])
        index = index + 1
      end
    end
    self._pageOriDatas = datas
    self._datas = pageDataList
    count = #self._datas
  else
    self._datas = datas
    count = #self._datas
  end
  self:SetItemCount(count)
end

function BP_ScrollView_C:GetItemCount()
  return #self._datas
end

function BP_ScrollView_C:InitList(datas)
  if not datas then
    return
  end
  local count = 0
  if self:IsPageModeEnable() then
    local pageDataList = {}
    local pageCount = math.ceil(#datas / self.pageNum)
    for i = 1, pageCount do
      local pageData = {}
      table.insert(pageDataList, pageData)
      local index = (i - 1) * self.pageNum + 1
      while index <= i * self.pageNum and index <= #datas do
        table.insert(pageData, datas[index])
        index = index + 1
      end
    end
    self._pageOriDatas = datas
    self._datas = pageDataList
    count = #self._datas
  else
    self._datas = datas
    count = #self._datas
  end
  self:SetItemCount(count)
end

function BP_ScrollView_C:SetCaller(caller)
  self._caller = caller
end

function BP_ScrollView_C:OnItemTouchStart(item, index, pageSubItem, pageSubIndex)
end

function BP_ScrollView_C:OnItemClick(item, index, pageSubItem, pageSubIndex)
  if self._selectedItem and self._selectedItem ~= item then
    self._selectedItem:OnSelectionChange(false)
  end
  self._selectedItem = item
  self._selectedItemIndex = index
  self._selectedItem:OnSelectionChange(true)
  if self.OnItemSelected then
    tcall(self._caller, self.OnItemSelected, self._selectedItem, index)
  end
  if self:IsPageModeEnable() and pageSubItem and pageSubIndex and self.OnPageSubItemSelected then
    tcall(self._caller, self.OnPageSubItemSelected, pageSubItem, self.pageNum * (index - 1) + pageSubIndex)
  end
end

function BP_ScrollView_C:HandleOverallTouchEnd(items)
  for idx = 1, items:Length() do
    local item = items:Get(idx)
    if item.OnOverallTouchEnd then
      item:OnOverallTouchEnd()
    end
  end
end

function BP_ScrollView_C:HandleSpawnItem(item, index)
  if item.SetData then
    item:SetScrollView(self)
    item:SetIndex(index)
    item:SetData(self._datas[index])
    if not self._itemDic then
      self._itemDic = {}
    end
    self._itemDic[index] = item
    if self._selectedItemIndex == index then
      item:OnSelectionChange(true)
      self._selectedItem = item
      if self.OnItemSelected then
        tcall(self._caller, self.OnItemSelected, self._selectedItem, index)
      end
    else
      item:OnSelectionChange(false)
    end
  end
end

function BP_ScrollView_C:HandleItemSelected(item, index)
  self._selectedItemIndex = index
  if self._selectedItem and self._selectedItem.OnSelectionChange then
    self._selectedItem:OnSelectionChange(false)
  end
  self._selectedItem = item
  if self._selectedItem and self._selectedItem.OnSelectionChange then
    if self._selectedItem.BroadcastOnClicked then
      self._selectedItem:BroadcastOnClicked()
    end
    self._selectedItem:OnSelectionChange(true)
  end
  if self.OnItemSelected then
    tcall(self._caller, self.OnItemSelected, self._selectedItem, index)
  end
end

function BP_ScrollView_C:HandleDespawnItem(item, index)
  if item.OnDespawn then
    item:OnDespawn()
    item:SetScrollView(nil)
    self._itemDic[index] = nil
  end
end

function BP_ScrollView_C:ClearSelection()
  if self._selectedItem then
    self._selectedItem:OnSelectionChange(false)
    self._selectedItem = nil
    self._selectedItemIndex = -1
  end
end

function BP_ScrollView_C:UnBind()
  self._caller = nil
  self.OnItemSelected = nil
  self._selectedItem = nil
  self._itemDic = {}
end

return BP_ScrollView_C
