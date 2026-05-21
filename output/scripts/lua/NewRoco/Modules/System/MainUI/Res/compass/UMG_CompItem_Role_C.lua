local Base = require("NewRoco.Modules.System.MainUI.Res.compass.CompItemNpcBase")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_CompItem_Role_C = Base:Extend("UMG_CompItem_Role_C")

function UMG_CompItem_Role_C:SetCornerIcon(WorldMapConfig)
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if WorldMapConfig.npcicon_corner_unlock and bigMapModule then
    self.Crown:SetPath(self:GetCornerPath(WorldMapConfig.npcicon_corner_unlock))
    self.Crown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if WorldMapConfig.npcicon_color_unlock then
    local color = WorldMapConfig.npcicon_color_unlock .. "FF"
    self.Department:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
    self.Department:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Department:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompItem_Role_C:SetIconPath(Path)
  BigMapUtils.SetupDottedEdgeImage(self, self.NRCIcon, Path)
end

function UMG_CompItem_Role_C:SetNpcIconPath(iconPath)
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if iconPath then
    local isBagItem = false
    if self.uiData.NpcConfig and self.uiData.NpcConfig and self.uiData.NpcConfig.traverse_data_param and self.uiData.NpcConfig.traverse_data_type == Enum.Traverse_Data_Type.TDT_BAGITEM then
      local bagItem_conf = self.uiData.NpcConfig and _G.DataConfigManager:GetBagItemConf(self.uiData.NpcConfig.traverse_data_param[1])
      if bagItem_conf then
        isBagItem = true
        self:SetIconPath(iconPath)
        return
      end
    end
    if self.uiData.state then
      if self.uiData.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
        self.iconPath = iconPath
        self:SetUnFoundIcon()
      elseif not self.uiData.isFound then
        self:SetIconPath(iconPath)
        self.Icon_Mask:SetPath(iconPath)
        self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self:SetIconPath(iconPath)
      end
    else
      self:SetIconPath(iconPath)
    end
  end
end

function UMG_CompItem_Role_C:SetUnFoundIcon()
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local materialPath = "MaterialInstanceConstant'/Game/NewRoco/Modules/System/TeamBattle/Res/MI_UI_Silhouettew.MI_UI_Silhouettew'"
  self.NRCIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
  self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
end

function UMG_CompItem_Role_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset then
    self.NRCIcon.MaterialInstance = asset
    self.NRCIcon:SetBrushFromMaterial(asset)
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadImageResSucc, nil, nil)
  end
end

function UMG_CompItem_Role_C:OnLoadIconMaterialFail()
  if self.iconPath ~= "" then
    self:SetIconPath(self.iconPath)
  end
end

function UMG_CompItem_Role_C:OnLoadImageResSucc(req, asset)
  local material = self.NRCIcon:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", asset)
end

return UMG_CompItem_Role_C
