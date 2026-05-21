local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Closet_Item1_C = Base:Extend("UMG_Closet_Item1_C")

function UMG_Closet_Item1_C:OnConstruct()
end

function UMG_Closet_Item1_C:OnDestruct()
  self:UnLoadRes()
end

function UMG_Closet_Item1_C:OnItemUpdate(_data, datalist, index)
  self.bEnableSound = true
  self.uiData = _data
  self.parent = _data.ownedPanel
  self:UpdateItemInfo()
end

function UMG_Closet_Item1_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    if not self.uiData then
      Log.Warning("UMG_Closet_Item1_C:OnItemSelected uiData is nil, skip")
      return
    end
    if self.bEnableSound then
      _G.NRCAudioManager:PlaySound2DAuto(40110003, "UMG_Closet_Item1_C:OnItemSelected")
    end
    self:PlayAnimation(self.Select)
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.uiData.salonConfId)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, salonItemConf.type, self.uiData.salonConfId, salonItemConf.texture_id, true)
    if self.parent and self.parent.UpdateTitlesAndCurrentDetailId then
      local itemName = salonItemConf and salonItemConf.name or ""
      self.parent:UpdateTitlesAndCurrentDetailId(itemName, nil, nil, true)
      self.parent:UpdateGorgeousMagicBtnVisible(false)
    end
  else
    self:PlayAnimation(self.UnSelect)
  end
end

function UMG_Closet_Item1_C:OnDeactive()
end

function UMG_Closet_Item1_C:UpdateItemInfo()
  if self.uiData.lockState == false then
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.uiData.salonConfId)
  local dynamicMaterial = self.icon:GetDynamicMaterial()
  if dynamicMaterial and salonItemConf then
    local textureObj = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetColorBGResByColorType, salonItemConf.colour_type)
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
    if nil == textureObj and self.uiData.isOther then
      self.dynamicMaterial = dynamicMaterial
      self.bgColor = bgColor
      self.PartternColor = PartternColor
      self.salonItemConf = salonItemConf
      self:SetColorByType(salonItemConf.colour_type)
    end
  end
end

function UMG_Closet_Item1_C:SetColorByType(colorType)
  self:UnLoadRes()
  local path = ""
  if colorType == Enum.HairColours.HC_PURE then
    path = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_black.T_UI_black'"
  elseif colorType == Enum.HairColours.HC_GRADIENT then
    path = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color1.T_UI_Closet_Color1'"
  elseif colorType == Enum.HairColours.HC_HIGHLIGHT then
    path = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color2.T_UI_Closet_Color2'"
  end
  if "" == path then
    return
  end
  self.Request = _G.NRCResourceManager:LoadResAsync(self, path, 255, 0, self.OnResLoadComplete, self.OnResLoadFailed)
end

function UMG_Closet_Item1_C:OnResLoadComplete(req, Texture2D)
  self.dynamicMaterial:SetTextureParameterValue("Pattern", Texture2D)
  self.dynamicMaterial:SetVectorParameterValue("BGColor", UE4.UNRCStatics.HexToLinearColor(self.bgColor))
  if self.salonItemConf.colour_type ~= Enum.HairColours.HC_PURE then
    self.dynamicMaterial:SetVectorParameterValue("PartternColor", UE4.UNRCStatics.HexToLinearColor(self.PartternColor))
  end
end

function UMG_Closet_Item1_C:OnResLoadFailed(Request, Message)
  Log.Warning("\229\138\160\232\189\189\232\181\132\230\186\144\229\164\177\232\180\165", Message)
  _G.NRCResourceManager:UnLoadRes(Request)
end

function UMG_Closet_Item1_C:UnLoadRes()
  if self.Request then
    _G.NRCResourceManager:UnLoadRes(self.Request)
    self.Request = nil
  end
end

function UMG_Closet_Item1_C:SetEnableSound(bEnableSound)
  self.bEnableSound = bEnableSound
end

function UMG_Closet_Item1_C:OpItem(index, ...)
end

return UMG_Closet_Item1_C
