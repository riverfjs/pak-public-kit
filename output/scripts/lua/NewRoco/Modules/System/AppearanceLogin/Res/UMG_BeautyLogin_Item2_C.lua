local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_BeautyLogin_Item2_C = Base:Extend("UMG_BeautyLogin_Item2_C")

function UMG_BeautyLogin_Item2_C:OnConstruct()
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.UnSelect)
end

function UMG_BeautyLogin_Item2_C:OnDestruct()
end

function UMG_BeautyLogin_Item2_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self:UpdateItemInfo()
end

function UMG_BeautyLogin_Item2_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local ret = Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_BeautyLogin_Item2_C:OnTouchEnded")
  return ret
end

function UMG_BeautyLogin_Item2_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    if self.uiData == nil then
      return
    end
    self:PlayAnimation(self.Select)
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.uiData)
    _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.SetAvatarSalon, salonItemConf.avatar_id, salonItemConf.texture_id)
  else
    self:PlayAnimation(self.UnSelect)
  end
end

function UMG_BeautyLogin_Item2_C:OnDeactive()
end

function UMG_BeautyLogin_Item2_C:UpdateItemInfo()
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.uiData)
  local dynamicMaterial = self.icon:GetDynamicMaterial()
  if dynamicMaterial then
    local textureObj = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetColorBGResByColorType, salonItemConf.colour_type)
    local bgColor, PartternColor
    local colorList = salonItemConf.colour_id
    if salonItemConf.colour_type == Enum.HairColours.HC_PURE then
      if colorList and #colorList > 0 then
        bgColor = colorList[1]
        PartternColor = colorList[1]
      end
    elseif salonItemConf.colour_type == Enum.HairColours.HC_GRADIENT then
      if colorList and #colorList > 1 then
        bgColor = colorList[1]
        PartternColor = colorList[2]
      end
    elseif salonItemConf.colour_type == Enum.HairColours.HC_HIGHLIGHT and colorList and #colorList > 1 then
      bgColor = colorList[1]
      PartternColor = colorList[2]
    end
    if textureObj then
      dynamicMaterial:SetTextureParameterValue("Pattern", textureObj)
      dynamicMaterial:SetVectorParameterValue("BGColor", UE4.UNRCStatics.HexToLinearColor(bgColor))
      if salonItemConf.colour_type ~= Enum.HairColours.HC_PURE then
        dynamicMaterial:SetVectorParameterValue("PartternColor", UE4.UNRCStatics.HexToLinearColor(PartternColor))
      end
    end
  end
end

return UMG_BeautyLogin_Item2_C
