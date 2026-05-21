local NRCCachedItem = NRCUmgClass:Extend("NRCCachedItem")

function NRCCachedItem:Initialize()
  self:Construct()
end

function NRCCachedItem:Construct()
  self.ButtonListenerMap = {}
end

function NRCCachedItem:AcquiredFromCache(OwnerView)
  self.Selected = false
  self:OnAcquiredFromCache(OwnerView)
end

function NRCCachedItem:RecycledToCache(OwnerView)
  self:OnRecycledToCache(OwnerView)
  self:RemoveAllButtonListeners()
end

function NRCCachedItem:ItemUpdate(OwnerView, Index)
  local Data
  if OwnerView and OwnerView.GetDataByIndex then
    Data = OwnerView:GetDataByIndex(Index)
  end
  self:OnItemUpdate(Data, OwnerView, Index)
end

function NRCCachedItem:ItemClick(OwnerView, Index, ScrollChoose)
  self:OnItemClick(OwnerView, Index, ScrollChoose)
end

function NRCCachedItem:ItemSelected(OwnerView, Index, Selected, ScrollChoose)
  self.Selected = Selected
  self:OnItemSelected(OwnerView, Index, Selected, ScrollChoose)
end

function NRCCachedItem:OnAcquiredFromCache(OwnerView)
end

function NRCCachedItem:OnRecycledToCache(OwnerView)
end

function NRCCachedItem:OnItemUpdate(Data, OwnerView, Index)
end

function NRCCachedItem:OnItemClick(OwnerView, Index, ScrollChoose)
end

function NRCCachedItem:OnItemSelected(OwnerView, Index, Selected, ScrollChoose)
end

function NRCCachedItem:AddButtonListener(Button, Handler)
  if not Button then
    return
  end
  if not Handler then
    return
  end
  if self.ButtonListenerMap[Button] then
    return
  end
  Button.OnClicked:Add(self, Handler)
  self.ButtonListenerMap[Button] = Handler
end

function NRCCachedItem:RemoveButtonListener(Button)
  if not Button then
    return
  end
  local Handler = self.ButtonListenerMap[Button]
  if Handler then
    Button.OnClicked:Remove(self, Handler)
    self.ButtonListenerMap[Button] = nil
  end
end

function NRCCachedItem:RemoveAllButtonListeners()
  if not self.ButtonListenerMap then
    return
  end
  for Button, _ in pairs(self.ButtonListenerMap) do
    self:RemoveButtonListener(Button)
  end
end

return NRCCachedItem
