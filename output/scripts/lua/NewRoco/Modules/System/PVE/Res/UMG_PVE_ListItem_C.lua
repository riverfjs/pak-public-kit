local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PVE_ListItem_C = Base:Extend("UMG_PVE_ListItem_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")

function UMG_PVE_ListItem_C:OnConstruct()
  self.TipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PVE_ListItem_C:OnDestruct()
  self.petData = nil
end

function UMG_PVE_ListItem_C:OnItemUpdate(_data, datalist, index)
  self.petData = _data
  if not _data then
    return
  end
  if self.ItemIcon and _data.base_conf_id then
    self.ItemIcon:SetIconPathAndMaterial(_data.base_conf_id, _data.mutation_type, _data.glass_info)
  end
  if self.NumText then
    self.NumText:SetText(tostring(_data.level or 0))
  end
  self:SetSelect(false)
  local selectedGid = self:GetParentCustomData()
  self.TagIcon_1:SetVisibility(selectedGid and selectedGid == _data.gid and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PVE_ListItem_C:OpItem(type)
  local selectedGid = self:GetParentCustomData()
  if self.petData then
    self.TagIcon_1:SetVisibility(selectedGid and selectedGid == self.petData.gid and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVE_ListItem_C:OnItemSelected(bSelected)
  self:SetSelect(bSelected)
  if bSelected and self.petData then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.DispatchEvent, PVEModuleEvent.SelectPvePet, self.petData)
  end
end

function UMG_PVE_ListItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PVE_ListItem_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PVE_ListItem_C:SetSelect(bSelected)
  if self.bSelected == bSelected then
    return
  end
  local bInit = self.bSelected == nil
  self.bSelected = bSelected
  if bInit then
    self:PlayAnimation(bSelected and self.select or self.normal)
  else
    self:PlayAnimation(bSelected and self.select or self.change2)
  end
end

function UMG_PVE_ListItem_C:OnDeactive()
end

return UMG_PVE_ListItem_C
