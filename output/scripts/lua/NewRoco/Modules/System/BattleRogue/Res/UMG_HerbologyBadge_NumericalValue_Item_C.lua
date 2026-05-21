local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HerbologyBadge_NumericalValue_Item_C = Base:Extend("UMG_HerbologyBadge_NumericalValue_Item_C")

function UMG_HerbologyBadge_NumericalValue_Item_C:OnConstruct()
end

function UMG_HerbologyBadge_NumericalValue_Item_C:OnDestruct()
end

function UMG_HerbologyBadge_NumericalValue_Item_C:OnItemUpdate(_data, datalist, index)
  if not _data then
    return
  end
  if _data.text then
    self.attriNameTxt:SetText(_data.text)
  end
  if _data.value then
    self.numTxt:SetText(tostring(_data.value))
  end
  if _data.bShowIcon and _data.iconPath then
    self.imageAttriIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.imageAttriIcon:SetPath(_data.iconPath)
  else
    self.imageAttriIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_NumericalValue_Item_C:OnItemSelected(_bSelected)
end

function UMG_HerbologyBadge_NumericalValue_Item_C:OnDeactive()
end

return UMG_HerbologyBadge_NumericalValue_Item_C
