local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ElfParadiseEventReviewItem1_C = Base:Extend("UMG_Activity_ElfParadiseEventReviewItem1_C")

function UMG_Activity_ElfParadiseEventReviewItem1_C:OnConstruct()
end

function UMG_Activity_ElfParadiseEventReviewItem1_C:OnDestruct()
end

function UMG_Activity_ElfParadiseEventReviewItem1_C:OnItemUpdate(_data, datalist, index)
  self.Num = _data
  if self.Num and self.Num > 0 then
    if 1 == index then
      self.TextDetails:SetText(string.format(LuaText.pet_trip_41, self.Num))
    elseif 2 == index then
      self.TextDetails:SetText(string.format(LuaText.pet_trip_42, self.Num))
    elseif 3 == index then
      self.TextDetails:SetText(string.format(LuaText.pet_trip_43, self.Num))
    end
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfParadiseEventReviewItem1_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ElfParadiseEventReviewItem1_C:OnDeactive()
end

return UMG_Activity_ElfParadiseEventReviewItem1_C
