local NRCCachedScrollView = NRCUmgClass:Extend("NRCCachedScrollView")

function NRCCachedScrollView:Initialize()
  self.ListDatas = nil
end

function NRCCachedScrollView:InitList(ListDatas, ForceNoCreate)
  ListDatas = ListDatas or {}
  self.ListDatas = ListDatas
  if ForceNoCreate then
    self:RefreshAllItems()
    return
  end
  self:SetItemCount(#self.ListDatas)
end

function NRCCachedScrollView:GetDataByIndex(Index)
  if self.ListDatas and Index and Index >= 0 then
    return self.ListDatas[Index + 1]
  end
  return nil
end

function NRCCachedScrollView:GetIndexByData(DataValue, Predicate)
  if self.ListDatas and DataValue then
    for Index, ItemData in ipairs(self.ListDatas) do
      if Predicate then
        if Predicate(DataValue, ItemData) then
          return Index - 1
        end
      elseif ItemData == DataValue then
        return Index - 1
      end
    end
  end
  return nil
end

function NRCCachedScrollView:InsertDataAt(Index, ItemData)
  if not self.ListDatas then
    self.ListDatas = {}
  end
  local SafeIndex = Index
  if SafeIndex < 0 then
    SafeIndex = 0
  elseif SafeIndex > #self.ListDatas then
    SafeIndex = #self.ListDatas
  end
  table.insert(self.ListDatas, SafeIndex + 1, ItemData)
  self:ClearItems(true)
  self:SetItemCount(#self.ListDatas)
end

function NRCCachedScrollView:AppendData(ItemData)
  if not self.ListDatas then
    self.ListDatas = {}
  end
  local Index = #self.ListDatas
  table.insert(self.ListDatas, ItemData)
  self:AppendItem()
  return Index
end

function NRCCachedScrollView:RemoveDataAt(Index)
  if not self.ListDatas then
    return nil
  end
  if nil == Index or Index < 0 or Index >= #self.ListDatas then
    return nil
  end
  local Removed = table.remove(self.ListDatas, Index + 1)
  self:RemoveItemAt(Index)
  return Removed
end

function NRCCachedScrollView:ClearList(NeedRecycle)
  if self.ListDatas then
    self.ListDatas = {}
  end
  if nil == NeedRecycle then
    NeedRecycle = true
  end
  self:ClearItems(NeedRecycle)
end

function NRCCachedScrollView:NotifyItemClick(Index, ScrollChoose)
  if nil == ScrollChoose then
    ScrollChoose = false
  end
  self:NotifyItemClickByIndex(Index, ScrollChoose)
end

function NRCCachedScrollView:ForeachItemData(Callback)
  if self.ListDatas and Callback then
    for _, ItemData in ipairs(self.ListDatas) do
      Callback(ItemData)
    end
  end
end

return NRCCachedScrollView
