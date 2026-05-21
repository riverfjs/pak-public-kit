local NRCPanelBase = require("NewRoco.TUI.BP_NRCItemBase_C")
local Base = NRCPanelBase
local UMG_Handbook_tab_C = Base:Extend("UMG_Handbook_tab_C")

function UMG_Handbook_tab_C:OnItemUpdate(_data, datalist, index)
  if _data then
    self.type = _data.type
    self.parent = _data.parent
  end
  self:InitPanel()
end

function UMG_Handbook_tab_C:InitPanel()
  if self.type then
    local desc
    if self.type == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
      desc = LuaText.season_photo_text_1
    elseif self.type == ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING then
      desc = LuaText.season_photo_text_2
    elseif self.type == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING then
      desc = LuaText.season_photo_text_3
    end
    if desc then
      self.Title:SetText(desc)
    end
  end
end

function UMG_Handbook_tab_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:PlayAnimation(self.Press)
    if self.parent then
      self.parent:OnChangeSelectedPhotoType(self.type)
    end
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Handbook_tab_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Handbook_tab_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_Handbook_tab_C
