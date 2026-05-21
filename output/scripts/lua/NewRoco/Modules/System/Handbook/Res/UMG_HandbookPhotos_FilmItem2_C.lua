local Base = require("NewRoco.Modules.System.TakePhotos.Res.UMG_TakePhotos_FilmItem_C")
local UMG_HandbookPhotos_FilmItem2_C = Base:Extend("UMG_HandbookPhotos_FilmItem2_C")

function UMG_HandbookPhotos_FilmItem2_C:OnItemUpdate(_data, datalist, index)
  Base.OnItemUpdate(self, _data, datalist, index)
  if _data.bLocalFile == true then
    self.CloudMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.CloudMark:SetPath(self.pet_handbook_local.AssetPathName)
  elseif _data.bLocalFile == false then
    self.CloudMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.CloudMark:SetPath(self.pet_handbook_cloud.AssetPathName)
  else
    self.CloudMark:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

return UMG_HandbookPhotos_FilmItem2_C
