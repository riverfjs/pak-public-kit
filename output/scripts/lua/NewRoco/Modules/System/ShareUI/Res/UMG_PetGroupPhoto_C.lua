local UMG_PetGroupPhoto_C = _G.NRCPanelBase:Extend("UMG_PetGroupPhoto_C")

function UMG_PetGroupPhoto_C:OnDestruct()
  self.SeasonalGroupPhoto.OnLoadPanelCallbackDelegate:Remove(self, self.OnLoadWidgetCallback)
end

function UMG_PetGroupPhoto_C:LoadSeasonPhoto()
  if self.data and self.data.seasonId then
    local seasonHandbookConf = _G.DataConfigManager:GetSeasonHandbookConf(self.data.seasonId)
    if seasonHandbookConf then
      local path = seasonHandbookConf.share_umg_path
      local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(path)
      if softClassPath then
        self.SeasonalGroupPhoto.OnLoadPanelCallbackDelegate:Remove(self, self.OnLoadWidgetCallback)
        self.SeasonalGroupPhoto.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
        self.SeasonalGroupPhoto:SetWidgetClass(softClassPath)
        self.SeasonalGroupPhoto:LoadPanel(nil)
      end
    end
  end
end

function UMG_PetGroupPhoto_C:OnLoadWidgetCallback()
  local photoPanel = self.SeasonalGroupPhoto:GetPanel()
  if photoPanel then
    photoPanel:InitPanel()
  end
end

function UMG_PetGroupPhoto_C:UpdateFontOutline(text, color)
  if text and color then
    local font = text.Font
    font.OutlineSettings.OutlineColor = UE4.UNRCStatics.HexToSlateColor(color)
    text:SetFont(font)
  end
end

function UMG_PetGroupPhoto_C:InitPanel(data)
  self.data = data.photoData
  self:LoadSeasonPhoto()
  self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PetBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  if uin and roleName then
    self.NameText:SetText(roleName)
    self.UID:SetText(string.format("UID:%d", uin))
  end
  if self.data.seasonId and self.data.petType then
    local seasonHandbookConf = _G.DataConfigManager:GetSeasonHandbookConf(self.data.seasonId)
    if seasonHandbookConf then
      local petBgPath = seasonHandbookConf.small_bg_res
      self.Bg:SetPath(petBgPath)
      local color = seasonHandbookConf.bg_title_color
      if color and "" ~= color then
        local seasonColor = string.format("%sff", color)
        self.NameText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(seasonColor))
        self.UID:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(seasonColor))
        self.NRCText_35:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(seasonColor))
        self.NRCText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(seasonColor))
        self.CollectionQuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(seasonColor))
      end
      local outlineColor = seasonHandbookConf.bg_title_outline_color
      if outlineColor and "" ~= outlineColor then
        local seasonOutlineColor = string.format("%sff", outlineColor)
        self:UpdateFontOutline(self.NRCText, seasonOutlineColor)
        self:UpdateFontOutline(self.CollectionQuantityText, seasonOutlineColor)
        self:UpdateFontOutline(self.NRCText_35, seasonOutlineColor)
      end
      local nameOutlineColor = seasonHandbookConf.bg_name_outline_color
      if nameOutlineColor and "" ~= nameOutlineColor then
        local seasonNameOutlineColor = string.format("%sff", nameOutlineColor)
        self:UpdateFontOutline(self.NameText, seasonNameOutlineColor)
      end
    end
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.data.seasonId)
    if seasonConf then
      local seasonName = seasonConf.s_title_subtitle
      local id = seasonConf.id
      local icon = seasonConf.handbook_photo_icon
      if seasonName and id and icon then
        self.NRCText_35:SetText(string.format("S%d:%s", id, seasonName))
        self.Icon:SetPath(icon)
      end
    end
    local str
    if self.data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
      str = LuaText.handbook_share_photo_text_1
    elseif self.data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING then
      str = LuaText.handbook_share_photo_text_2
    elseif self.data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING then
      str = LuaText.handbook_share_photo_text_3
    end
    local totalNum, collectNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, self.data.seasonId, self.data.petType)
    if str and totalNum and collectNum then
      self.NRCText:SetText(str)
      self.CollectionQuantityText:SetText(string.format("%d/%d", collectNum, totalNum))
    end
  end
end

return UMG_PetGroupPhoto_C
