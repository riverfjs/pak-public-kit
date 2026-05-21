local BP_NRCItemBase_C = NRCUmgClass:Extend("BP_NRCItemBase_C")

function BP_NRCItemBase_C:UpdateItem(GridView, index)
  self._parent = GridView
  self._data = GridView._listDatas
  self._index = index
  if self._data then
    self:OnUpdate(self._data[index], self._data, index)
  end
end

function BP_NRCItemBase_C:OnUpdate(_data, datalist, index)
  self._index = index
  self._itemData = _data
  if self.OnItemUpdate then
    self:OnItemUpdate(self._itemData, datalist, index)
  end
end

function BP_NRCItemBase_C:OnItemClick(index)
  if self.OnClick and self._index == index and self.ParentView.Object == self.touchParent then
    self.isSelected = true
    self:OnClick()
  elseif self.UnClick and self._index ~= index then
    self.isSelected = false
  end
  self:OnItemSelected(self.isSelected)
end

function BP_NRCItemBase_C:AddButtonListener(btn, handler)
  if not self:SafeCheck() then
    return
  end
  if not btn then
    self:LogError("btn\228\184\141\229\173\152\229\156\168\239\188\140\230\179\168\229\134\140\230\140\137\233\146\174\229\164\177\232\180\165")
    return
  end
  if not self.viewbuttonEventDict[btn] then
    btn.OnClicked:Add(self, handler)
    self.viewbuttonEventDict[btn] = handler
  else
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141\230\179\168\229\134\140Button\228\186\139\228\187\182:", self.viewbuttonEventDict[btn])
  end
end

function BP_NRCItemBase_C:RemoveButtonListener(btn)
  if not self:SafeCheck() then
    return
  end
  if self.viewbuttonEventDict[btn] then
    btn.OnClicked:Remove(self, self.viewbuttonEventDict[btn])
    self.viewbuttonEventDict[btn] = nil
  else
  end
end

function BP_NRCItemBase_C:RemoveAllButtonListener()
  if not self:SafeCheck() then
    return
  end
  for btn, handlerWrap in pairs(self.viewbuttonEventDict) do
    self:RemoveButtonListener(btn)
  end
end

function BP_NRCItemBase_C:SafeCheck()
  if not self.viewbuttonEventDict then
    Log.Error("\232\175\183\229\139\191\232\166\134\231\155\150Construct\229\135\189\230\149\176\239\188\140\231\187\159\228\184\128\228\189\191\231\148\168OnConstruct")
    return false
  end
  return true
end

function BP_NRCItemBase_C:OnItemSelected(bSelected, bScrollChoose, bUserClick)
  if bSelected and self.OnClick then
    self:OnClick()
  else
  end
end

function BP_NRCItemBase_C:OnItemClicked(bClicked)
end

function BP_NRCItemBase_C:SetClickable(bool)
  Log.Debug("BP_NRCItemBase_C:SetClickable", bool)
  self.clickable = bool
end

function BP_NRCItemBase_C:SetSelectable(bool)
  self.selectable = bool
end

function BP_NRCItemBase_C:OpItem(opType, ...)
  Log.Error("BP_NRCItemBase_C:OpItem", opType)
end

function BP_NRCItemBase_C:Construct(_itemDatas)
  self.viewbuttonEventDict = {}
  WeakTable(self.viewbuttonEventDict)
  self.isDestruct = false
  self.isSelected = false
  self.touchParent = nil
  self.clickable = true
  self.selectable = true
  self.selectItem = nil
  self.selectFalseItem = nil
  local BindLuaCallBack = self.BindLuaCallBack
  if BindLuaCallBack then
    BindLuaCallBack(self, {
      self,
      self.UpdateItem
    })
  else
    Log.ErrorFormat("BP_NRCItemBase_C:Construct %s is not a UNRCItemBase widget!", self.name or "Unkonwn")
  end
  if self.OnConstruct then
    self:OnConstruct()
  end
end

function BP_NRCItemBase_C:OnConstruct()
end

function BP_NRCItemBase_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if self._index and self._index > 0 then
    self.StartIndex = self._index
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function BP_NRCItemBase_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if self.ParentView then
    if self._index then
      if self._index > 0 and self.StartIndex and self.StartIndex > 0 and self.StartIndex == self._index then
        self.ParentView:OnChildItemClick(self, self._index - 1, true)
      end
    else
      self.ParentView:OnChildItemClick(self, nil, true)
    end
  end
  self.StartIndex = nil
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function BP_NRCItemBase_C:OnMouseCaptureLost(CaptureLostEvent)
  if self.ParentView and self.ParentView.OnTouchEnded then
    self.ParentView:OnTouchEnd()
  end
end

function BP_NRCItemBase_C:SetSelectItem(Item)
  self.selectItem = Item
end

function BP_NRCItemBase_C:SetSelectFalseItem(Item)
  self.selectFalseItem = Item
end

function BP_NRCItemBase_C:GetSelectItem()
  return self.selectItem
end

function BP_NRCItemBase_C:GetSelectFalseItem()
  return self.selectFalseItem
end

function BP_NRCItemBase_C:AddOrRemove(bAdd, anim)
end

function BP_NRCItemBase_C:DestroyItem()
  if nil == self then
    Log.Debug("BP_NRCItemBase_C:DestroyItem self is nil")
    return
  end
  if self.isDestruct == false then
    if self.OnDestruct then
      self:OnDestruct()
    end
    self._parent = nil
    self._data = nil
    self.ParentView = nil
    self.selectItem = nil
    self.selectFalseItem = nil
    self.StartIndex = nil
    self.isDestruct = true
    self:RemoveAllButtonListener()
  end
end

function BP_NRCItemBase_C:Destruct()
  if self.OnDestruct then
    self:OnDestruct()
  end
end

function BP_NRCItemBase_C:OnDestruct()
end

function BP_NRCItemBase_C:GetGuidanceCustomListIndex()
  return self._index
end

function BP_NRCItemBase_C:GetParentCustomData()
  local parent = self.ParentView
  if parent and UE4.UObject.IsValid(parent) then
    return parent._customData
  end
end

function BP_NRCItemBase_C:BroadcastMsg(msg, ...)
  local parent = self.ParentView
  if parent and UE4.UObject.IsValid(parent) then
    parent:OnMsg(msg, ...)
  end
end

return BP_NRCItemBase_C
