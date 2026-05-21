local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Nourish_BigMapTips_Item_C = Base:Extend("UMG_Nourish_BigMapTips_Item_C")

function UMG_Nourish_BigMapTips_Item_C:OnConstruct()
end

function UMG_Nourish_BigMapTips_Item_C:OnDestruct()
end

function UMG_Nourish_BigMapTips_Item_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self:UpdateInfo()
end

function UMG_Nourish_BigMapTips_Item_C:OnItemSelected(_bSelected)
end

function UMG_Nourish_BigMapTips_Item_C:UpdateInfo()
  local state = 0
  if self.uiData and self.uiData.state then
    state = self.uiData.state - 1
  else
    return
  end
  self.NRCSwitcher_51:SetActiveWidgetIndex(state)
  self.Attr:SetVisibility(self.uiData.state == _G.Enum.PetHandbookStatus.PHS_NOT_FOUND and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  if self.uiData.state == _G.Enum.PetHandbookStatus.PHS_NOT_FOUND then
    self.Name:SetText("???")
  else
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.uiData.petBaseConfId)
    local name = petBaseConf.name
    self.Name:SetText(name)
    self:ShowTypeIcons(petBaseConf)
  end
end

function UMG_Nourish_BigMapTips_Item_C:ShowTypeIcons(petBaseConf)
  local commonAttrData = {}
  local unit_type = petBaseConf.unit_type
  for i = 1, 2 do
    local petType = unit_type and unit_type[i]
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        table.insert(commonAttrData, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  self.Attr:InitGridView(commonAttrData)
end

function UMG_Nourish_BigMapTips_Item_C:OnDeactive()
end

return UMG_Nourish_BigMapTips_Item_C
