local NRCCachedItem = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.NRCCachedItem")
local UMG_OptionItem_C = NRCCachedItem:Extend("UMG_OptionItem_C")

function UMG_OptionItem_C:OnItemUpdate(Data, OwnerView, Index)
  self.Text:SetText(Data)
end

return UMG_OptionItem_C
