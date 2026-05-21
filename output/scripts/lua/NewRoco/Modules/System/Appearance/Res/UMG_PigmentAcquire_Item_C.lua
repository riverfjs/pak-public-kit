local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PigmentAcquire_Item_C = Base:Extend("UMG_PigmentAcquire_Item_C")

function UMG_PigmentAcquire_Item_C:OnConstruct()
end

function UMG_PigmentAcquire_Item_C:OnDestruct()
end

function UMG_PigmentAcquire_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data.data or {}
  self.petData = _data.petData
  if self.data.glass then
    if self.data.glass.glass_type == _G.Enum.GlassType.GT_HIDDEN then
      self:ShowHiddenGlassInfo()
    else
      self:ShowNormalGlassInfo()
    end
  end
  self:SetPetIcon()
end

function UMG_PigmentAcquire_Item_C:ShowNormalGlassInfo()
  self.Switcher:SetActiveWidgetIndex(0)
  local shineColorId = self.data.glass.glass_value
  self.ParticleIndex, shineColorId = PetUtils.GetShineDataValue(shineColorId, 20)
  self.MatchIndex, shineColorId = PetUtils.GetShineDataValue(shineColorId, 0)
  if self.MatchIndex and 0 ~= self.MatchIndex then
    local matchConf = _G.DataConfigManager:GetColorRandomConf(self.MatchIndex)
    if not matchConf then
      return
    end
    if matchConf.ui_color_1 then
      local color1 = matchConf.ui_color_1 .. "FF"
      self.NRCImage_A:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color1))
    end
    if matchConf.ui_color_2 then
      local color2 = matchConf.ui_color_2 .. "FF"
      self.NRCImage_B:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color2))
    end
  end
  if self.ParticleIndex and 0 ~= self.ParticleIndex then
    local particleBigIconRes = _G.DataConfigManager:GetParticleRandomConf(self.ParticleIndex).particle_big_icon
    if particleBigIconRes then
      self.Image_Icon:SetPath(particleBigIconRes)
    end
  end
end

function UMG_PigmentAcquire_Item_C:ShowHiddenGlassInfo()
  self.Switcher:SetActiveWidgetIndex(1)
  local path = self:GetHiddenGlassTipsPic()
  if "" ~= path then
    self.Image_Icon_3:SetPath(path)
  end
end

function UMG_PigmentAcquire_Item_C:GetHiddenGlassTipsPic()
  if self.data and self.data.glass then
    local HiddenGlassID = self.data.glass.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf and HiddenGlassConf.glass_tips_pic then
        return HiddenGlassConf.glass_tips_pic
      end
    end
  end
  return ""
end

function UMG_PigmentAcquire_Item_C:SetPetIcon()
  if self.petData then
    self.ColorfulHeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  elseif self.data.show_gid then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.show_gid)
    if PetData then
      self.ColorfulHeadIcon:SetIconPathAndMaterial(PetData.base_conf_id, PetData.mutation_type, PetData.glass_info)
    end
  else
    local itemConf = _G.DataConfigManager:GetFashionItemConf(self.data.fashion_item_id)
    if itemConf and itemConf.suits_id then
      local suitId = tonumber(itemConf.suits_id)
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
      if suitConf and suitConf.petbase_id and suitConf.petbase_id[1] then
        local petBaseId = suitConf.petbase_id[1]
        local mutation_type = _G.Enum.MutationDiffType.MDT_GLASS
        if suitConf.suits_original_id > 0 then
          mutation_type = _G.Enum.MutationDiffType.MDT_GLASS + _G.Enum.MutationDiffType.MDT_SHINING
        end
        self.ColorfulHeadIcon:SetIconPathAndMaterial(petBaseId, mutation_type, self.data.glass)
      end
    end
  end
end

function UMG_PigmentAcquire_Item_C:OnItemSelected(_bSelected)
end

function UMG_PigmentAcquire_Item_C:OnDeactive()
end

return UMG_PigmentAcquire_Item_C
