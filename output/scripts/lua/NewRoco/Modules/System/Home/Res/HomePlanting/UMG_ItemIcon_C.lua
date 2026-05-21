local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_ItemIcon_C = Base:Extend("UMG_ItemIcon_C")

function UMG_ItemIcon_C:OnConstruct()
  self._selected = false
end

function UMG_ItemIcon_C:OnDestruct()
end

function UMG_ItemIcon_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self:RefreshUI()
end

function UMG_ItemIcon_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_ItemIcon_C:OnItemSelected")
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_ItemIcon_C:OnDespawn()
  self:StopAnimation(self.change1)
  self:StopAnimation(self.change2)
  self:PlayAnimation(self.normal, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
end

function UMG_ItemIcon_C:OnItemSelected(_bSelected, bScrollSelect)
  local myUIData = self.uiData
  if not myUIData then
    return
  end
  local caller = myUIData.caller
  local callback = myUIData.callback
  if _bSelected then
    self.RedDot:EraseRedPoint()
  end
  local bOnParentPanelActiveScope = false
  if _bSelected and caller and callback then
    bOnParentPanelActiveScope = callback(caller, myUIData.Id, _bSelected)
  end
  if not bScrollSelect then
    if self._selected ~= _bSelected then
      if _bSelected then
        if bOnParentPanelActiveScope then
          self:StopAnimation(self.normal)
          self:StopAnimation(self.change2)
          self:PlayAnimation(self.change1, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
        else
          self:PlayAnimation(self.change1)
        end
      else
        self:StopAnimation(self.change1)
        self:StopAnimation(self.change2)
        self:PlayAnimation(self.normal, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
      end
    end
  elseif _bSelected then
    self:PlayAnimation(self.change1, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
  else
    self:PlayAnimation(self.change2)
  end
  self._selected = _bSelected
end

function UMG_ItemIcon_C:OnDeactive()
end

function UMG_ItemIcon_C:RefreshUI()
  if self.uiData == nil or nil == self.uiData.Id then
    return
  end
  self:SetInfo()
end

function UMG_ItemIcon_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_1)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_2)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_3)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_4)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_5)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_ItemIcon_C:SetInfo()
  local _data = self.uiData
  local bagItemConf = DataConfigManager:GetBagItemConf(_data.Id)
  local timeStr = ""
  self.Quantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if _data.itemType == _G.Enum.BagItemType.BI_HOME_PET_FEED then
    if _data.needTime then
      local need_hour = math.floor(_data.needTime // 60)
      if need_hour >= 1 then
        timeStr = string.format(LuaText.clear_plant_confirm_text_h, need_hour)
      else
        timeStr = string.format(LuaText.clear_plant_confirm_text_m, _data.needTime)
      end
    end
  else
    local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(_data.Id)
    if not bagItemConf or not plantGrowConf then
      return
    end
    self.RedDot:SetupKey(345, _data.Id)
    self.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetQuality(bagItemConf.item_quality)
  self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Icon:SetPath(bagItemConf.big_icon)
  if not string.IsNilOrEmpty(timeStr) then
    self.Text_Quantity:SetText(timeStr)
  end
  if _data.bEquipping then
    self.Equipment:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:StopAnimation(self.normal)
    self:StopAnimation(self.change2)
    self:PlayAnimation(self.change1, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
  else
    self.Equipment:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:StopAnimation(self.change1)
    self:StopAnimation(self.change2)
    self:PlayAnimation(self.normal, 0, 1, UE4.EUMGSequencePlayMode.Forward, 5)
  end
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_ItemIcon_C:SetProperty(propertyTable)
  if type(propertyTable) ~= "table" then
    return
  end
  for k, v in pairs(propertyTable) do
    self.uiData[k] = v
  end
end

function UMG_ItemIcon_C:ApplyProperty()
  self:RefreshUI()
end

return UMG_ItemIcon_C
