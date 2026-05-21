local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_BX_Template_C = Base:Extend("UMG_BX_Template_C")

function UMG_BX_Template_C:OnConstruct()
  self.itemId = nil
end

function UMG_BX_Template_C:OnDestruct()
end

function UMG_BX_Template_C:OnItemUpdate(_data, datalist, index)
  if _data then
    self.eggData = _data.egg_data
    local item = {
      Id = _data.id,
      Count = 0
    }
    if self.eggData and 0 ~= self.eggData.conf_id and self.eggData.precious_egg_type and self.eggData.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
      item = {
        Id = _data.id,
        Count = 0,
        Quality = 5
      }
    elseif self.eggData and 0 == self.eggData.conf_id and self.eggData.random_egg_conf then
      local randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(self.eggData.random_egg_conf)
      if randomEggConf and randomEggConf.precious_egg_type and randomEggConf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
        item = {
          Id = _data.id,
          Count = 0,
          Quality = 5
        }
      end
    end
    self.Data = item
  end
  self.index = index
  self:InitPanel()
end

function UMG_BX_Template_C:InitPanel()
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.Data.Id)
  self.NumText:SetText(self.Data.Count)
  self:SetIcon(BagItemConf.icon)
  if self.Data.Quality then
    self:SetQuality(self.Data.Quality)
  else
    self:SetQuality(BagItemConf.item_quality)
  end
  self:SetSelectedVisible(false)
end

function UMG_BX_Template_C:SetParent(_Parent)
  self.Parent = _Parent
end

function UMG_BX_Template_C:OnItemSelected(Selected)
  self:SetSelectedVisible(Selected)
  if Selected then
    self.Parent:SelectChange(true, self.Data, self.index)
  else
  end
end

function UMG_BX_Template_C:SetSelectedVisible(visible)
  if visible then
    self.Selected:SetVisibility(UE4.ESlateVisibility.visible)
  else
    self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BX_Template_C:OnDeactive()
end

function UMG_BX_Template_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_BX_Template_C:SetIcon(icon_path)
  if self.eggData then
    self.IconSwitcher:SetActiveWidgetIndex(1)
    self.PetEggIcon:SetEggIcon(self.eggData, icon_path)
    return
  end
  self.IconSwitcher:SetActiveWidgetIndex(0)
  self.ItemIcon:SetPath(icon_path)
end

return UMG_BX_Template_C
