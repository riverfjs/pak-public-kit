local NRCCachedItem = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.NRCCachedItem")
local UMG_FieldItem_C = NRCCachedItem:Extend("UMG_FieldItem_C")

function UMG_FieldItem_C:OnAcquiredFromCache(OwnerView)
  if self.UMG_FieldName.Active then
    self.UMG_FieldName:Active()
  end
  if self.UMG_FieldValue.Active then
    self.UMG_FieldValue:Active()
  end
end

function UMG_FieldItem_C:OnRecycledToCache(OwnerView)
  if self.UMG_FieldName.Deactive then
    self.UMG_FieldName:Deactive()
  end
  if self.UMG_FieldValue.Deactive then
    self.UMG_FieldValue:Deactive()
  end
end

function UMG_FieldItem_C:OnItemUpdate(Data, OwnerView, Index)
  if Data.RTTI == nil then
    return
  elseif nil == Data.RTTI.TypeInfo or nil == Data.RTTI.FieldInfo then
    return
  end
  if nil == Data.Record then
    return
  end
  if self.UMG_FieldName.RefreshData then
    self.UMG_FieldName:RefreshData(Data)
  end
  if self.UMG_FieldValue.RefreshData then
    self.UMG_FieldValue:RefreshData(Data)
  end
end

return UMG_FieldItem_C
