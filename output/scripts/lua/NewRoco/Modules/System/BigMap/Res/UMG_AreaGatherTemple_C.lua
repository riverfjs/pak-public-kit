local UMG_AreaGatherTemple_C = _G.NRCPanelBase:Extend("UMG_AreaGatherTemple_C")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local TextWidgetRangeScaler = reload("NewRoco.Modules.System.BigMap.Res.TextWidgetRangeScaler")

function UMG_AreaGatherTemple_C:OnConstruct()
  self.btnLookArea.OnClicked:Add(self, self.OnBtnLookAreaClick)
  self.TextWidgetRangeScalers = {
    {
      TextWidgetRangeScaler(self.areaName2_1),
      TextWidgetRangeScaler(self.RocoText_1),
      TextWidgetRangeScaler(self.areaName2),
      TextWidgetRangeScaler(self.RocoText)
    },
    {
      TextWidgetRangeScaler(self.areaName1_1),
      TextWidgetRangeScaler(self.RocoText_3),
      TextWidgetRangeScaler(self.areaName1),
      TextWidgetRangeScaler(self.RocoText_2)
    },
    {
      TextWidgetRangeScaler(self.areaName1_2),
      TextWidgetRangeScaler(self.RocoText_4),
      TextWidgetRangeScaler(self.areaName3),
      TextWidgetRangeScaler(self.RocoText_5)
    },
    {
      TextWidgetRangeScaler(self.areaName1_3),
      TextWidgetRangeScaler(self.RocoText_6),
      TextWidgetRangeScaler(self.areaName4),
      TextWidgetRangeScaler(self.RocoText_7)
    },
    {
      TextWidgetRangeScaler(self.areaName5),
      TextWidgetRangeScaler(self.areaName5_1)
    },
    ChangeScale = function(self, showLevel, scale, scaleRatio)
      if showLevel > 0 and showLevel <= 5 then
        local scalers = self[showLevel]
        for i = 1, #scalers do
          local scaler = scalers[i]
          scaler:ChangeScale(scale, scaleRatio)
        end
      end
    end
  }
end

function UMG_AreaGatherTemple_C:OnDestruct()
  self.btnLookArea.OnClicked:Remove(self, self.OnBtnLookAreaClick)
  self.uiData = nil
  self.TextWidgetRangeScalers = nil
end

function UMG_AreaGatherTemple_C:SetData(_data)
  self.uiData = _data
  self.curMapShowLevel = 0
  self:UpdatePanel()
  if _data and _data.config then
    if _data.config.element_show_scale then
      local fontScale = _data.config.element_show_scale
      self.infoSwitcher:SetActiveWidgetIndex(fontScale - 1)
      self.scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(_data.config.element_show_scale)
      self.maxScale = self.scaleConf.max_scale / 100
      self.minScale = self.scaleConf.min_scale / 100
    end
    if _data.config.zone_name_roco then
      self.RocoText:SetText(_data.config.zone_name_roco)
      self.RocoText_1:SetText(_data.config.zone_name_roco)
      self.RocoText_2:SetText(_data.config.zone_name_roco)
      self.RocoText_3:SetText(_data.config.zone_name_roco)
      self.RocoText_4:SetText(_data.config.zone_name_roco)
      self.RocoText_5:SetText(_data.config.zone_name_roco)
      self.RocoText_6:SetText(_data.config.zone_name_roco)
      self.RocoText_7:SetText(_data.config.zone_name_roco)
    end
  end
end

function UMG_AreaGatherTemple_C:GetData()
  return self.uiData
end

function UMG_AreaGatherTemple_C:UpdatePanel()
  self:SetEngNameVisible(false)
  local uiData = self.uiData
  if uiData and uiData.config then
    self.areaName1:SetText(uiData.config.zone_name)
    self.areaName1_1:SetText(uiData.config.zone_name)
    self.areaName2:SetText(uiData.config.zone_name)
    self.areaName2_1:SetText(uiData.config.zone_name)
    self.areaName3:SetText(uiData.config.zone_name)
    self.areaName1_2:SetText(uiData.config.zone_name)
    self.areaName4:SetText(uiData.config.zone_name)
    self.areaName1_3:SetText(uiData.config.zone_name)
    self.areaName5:SetText(uiData.config.zone_name)
    self.areaName5_1:SetText(uiData.config.zone_name)
  else
    self.areaName1:SetText("")
    self.areaName2:SetText("")
    self.areaName3:SetText("")
    self.areaName4:SetText("")
    self.areaName5:SetText("")
  end
  self:UpdateCollectionRate()
end

function UMG_AreaGatherTemple_C:UpdateMapShowLevel(_level, _scale, _scaleRatio)
  self.curMapShowLevel = _level
  local uiData = self.uiData
  if uiData.config.element_show_scale and self.maxScale and self.minScale then
    if _level < self.maxScale and _level >= self.minScale or 1 == _level and 1.0 == self.maxScale then
      self.TextWidgetRangeScalers:ChangeScale(uiData.config.element_show_scale, _scale, _scaleRatio)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.Panel_GatherTemple then
    local fixed_scale = math.max(0, math.min(1, 1 / _scale))
    self.Panel_GatherTemple:SetRenderScale(UE4.FVector2D(fixed_scale, fixed_scale))
  end
end

function UMG_AreaGatherTemple_C:UpdateCollectionRate()
  local uiData = self.uiData
  if uiData and uiData.config and 1 == uiData.config.name_scale then
    self.areaGatherPercent:SetText(string.format(LuaText.umg_areagathertemple_1, uiData.collectionRate or 0))
  end
end

function UMG_AreaGatherTemple_C:RefreshGatherInfo()
  if self.uiData.config.camp_refresh_id > 0 then
    local campRefreshId = self.uiData.config.camp_refresh_id
    local x, y = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetPetGatherRate, campRefreshId)
    local text = string.format(_G.DataConfigManager:GetLocalizationConf("worldmap_area_exploration").msg, x, y)
    if x == y then
      self.RocoText_5:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("D56C1FFF"))
    end
    self:SetGatherVisible()
    local isTravel = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetIsTravelMap)
    text = isTravel and "" or text
    self.RocoText:SetText(text)
    self.RocoText_1:SetText(text)
    self.RocoText_2:SetText(text)
    self.RocoText_3:SetText(text)
    self.RocoText_4:SetText(text)
    self.RocoText_5:SetText(text)
    self.RocoText_6:SetText(text)
    self.RocoText_7:SetText(text)
  end
end

function UMG_AreaGatherTemple_C:SetEngNameVisible(bVisible)
  if bVisible then
    self.RocoText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_6:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RocoText_7:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.RocoText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RocoText_7:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_AreaGatherTemple_C:SetGatherVisible()
  self:SetEngNameVisible(true)
end

function UMG_AreaGatherTemple_C:SetShowButton(_show)
  if _show then
    self.btnLookArea:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.btnLookArea:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_AreaGatherTemple_C:SetShowCollectionRate(_show)
  if _show then
    self.areaGatherPercent:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.areaGatherPercent:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_AreaGatherTemple_C:OnBtnLookAreaClick()
  local BigMapModule = NRCModuleManager:GetModule("BigMapModule")
  if BigMapModule then
    BigMapModule:DispatchEvent(BigMapModuleEvent.ShowSpriteBookEvent, self.uiData)
  end
end

function UMG_AreaGatherTemple_C:PlayShowAnimation(_show)
  if _show then
    self:PlayAnimation(self.aniOpen)
  else
    self:PlayAnimation(self.aniClose)
  end
end

return UMG_AreaGatherTemple_C
