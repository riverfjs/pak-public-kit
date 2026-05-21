local ThumbnailScrollPool = Class("ThumbnailScrollPool")

function ThumbnailScrollPool:Ctor(Manager)
  self.Manager = Manager
end

function ThumbnailScrollPool:InitThumbnailSlots()
  self.ThumbnailSlots = {}
  self.ScrollWindowsRangeBegin = 0
  self.ScrollWindowsRangeEnd = 0
end

function ThumbnailScrollPool:ReleaseThumbnailSlots()
  if not self.ThumbnailSlots then
    return
  end
  for HashKey, Slots in pairs(self.ThumbnailSlots) do
    for i, Slot in pairs(Slots) do
      if Slot.ThumbnailTexture then
        if UE.UObject.IsValid(Slot.ThumbnailTexture) then
          Log.Debug("[TakePhoto] destroy thumbnail texture", Slot.ThumbnailTexture:GetName(), Slot.ThumbnailTexture:Blueprint_GetSizeX(), Slot.ThumbnailTexture:Blueprint_GetSizeY())
          UnLua.Unref(Slot.ThumbnailTexture)
        end
        Slot.ThumbnailTexture = nil
        Slot.ThumbnailTextureRef = nil
      end
    end
  end
  self.ThumbnailSlots = nil
end

function ThumbnailScrollPool:UpdateThumbnailScrollRange(From, To)
  local bChanged = false
  local ScrollWindowsRangeBegin = self.ScrollWindowsRangeBegin
  local ScrollWindowsRangeEnd = self.ScrollWindowsRangeEnd
  if From ~= self.ScrollWindowsRangeBegin or self.ScrollWindowsRangeEnd ~= To then
    bChanged = true
  end
  self.ScrollWindowsRangeBegin = From
  self.ScrollWindowsRangeEnd = To
  return bChanged, ScrollWindowsRangeBegin, ScrollWindowsRangeEnd
end

function ThumbnailScrollPool:AddTextureReadyDelegate(Brief, Caller, Func)
  if not Brief then
    return
  end
  local File = self.Manager:GetFileByBrief(Brief)
  if not File then
    return
  end
  if not File.bValid then
    File.OnValidDataLoaded:Add(Caller, Func)
  end
end

function ThumbnailScrollPool:RemoveTextureReadyDelegate(Brief, Caller, Func)
  if not Brief then
    return
  end
  local File = self.Manager:GetFileByBrief(Brief)
  if not File then
    return
  end
  File.OnValidDataLoaded:Remove(Caller, Func)
end

function ThumbnailScrollPool:GetThumbnailTexture(Brief, LuaSlotIndex)
  if not Brief then
    return
  end
  local File = self.Manager:GetFileByBrief(Brief)
  if not File then
    return
  end
  if not File.bValid then
    File:AsyncLoadResource()
    return
  end
  local SlotIndex = LuaSlotIndex - 1
  if SlotIndex < self.ScrollWindowsRangeBegin or SlotIndex > self.ScrollWindowsRangeEnd then
    return
  end
  if not self.ThumbnailSlots then
    return
  end
  local Width = File.ReadonlyFileWidth
  local Height = File.ReadonlyFileHeight
  local ThumbnailHashKey = string.format("Thumbnail_%d_%d", Width, Height)
  local Slots = self.ThumbnailSlots[ThumbnailHashKey]
  local DesiredFreeSlot
  if not Slots then
    Slots = {}
    self.ThumbnailSlots[ThumbnailHashKey] = Slots
  else
    DesiredFreeSlot = Slots[SlotIndex]
    if not DesiredFreeSlot then
      for SlotId, Slot in pairs(Slots) do
        if Slot.Index < self.ScrollWindowsRangeBegin or Slot.Index > self.ScrollWindowsRangeEnd then
          DesiredFreeSlot = Slot
          Slots[SlotId] = nil
          Slots[SlotIndex] = Slot
          Slot.Index = SlotIndex
          break
        end
      end
    else
      assert(DesiredFreeSlot.Index == SlotIndex)
    end
  end
  if not DesiredFreeSlot then
    DesiredFreeSlot = {
      Index = SlotIndex,
      Brief = nil,
      ThumbnailTexture = nil,
      ThumbnailTextureRef = nil
    }
    Slots[SlotIndex] = DesiredFreeSlot
  end
  local ThumbnailTexture = DesiredFreeSlot.ThumbnailTexture
  if not ThumbnailTexture then
    ThumbnailTexture = File:CreateUpdatedTexture2D("TakePhoto_")
    if ThumbnailTexture then
      DesiredFreeSlot.ThumbnailTexture = ThumbnailTexture
      DesiredFreeSlot.ThumbnailTextureRef = UnLua.Ref(ThumbnailTexture)
      Log.Debug("[TakePhoto] create thumbnail texture", ThumbnailTexture:GetName(), ThumbnailHashKey, "SlotNum:", SlotIndex)
    else
      Log.Error("[TakePhoto] Invalid!!!")
    end
  elseif DesiredFreeSlot.Brief ~= Brief then
    File:UpdateTexture(ThumbnailTexture)
  end
  DesiredFreeSlot.Brief = Brief
  return ThumbnailTexture
end

return ThumbnailScrollPool
