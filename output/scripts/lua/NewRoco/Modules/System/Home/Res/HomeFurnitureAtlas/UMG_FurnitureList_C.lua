local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FurnitureList_C = Base:Extend("UMG_FurnitureList_C")

function UMG_FurnitureList_C:OnConstruct()
  local Config = DataConfigManager:GetLocalizationConf("furniture_build_unlock_tag")
  if Config and Config.msg then
    self.UnlockText:SetText(Config.msg)
  end
end

function UMG_FurnitureList_C:OnDestruct()
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_FurnitureList_C:OnItemUpdate(_data, datalist, index)
  self.itemIndex = index
  self.itemData = _data
  local head = self._parent:GetFirstIndex()
  local viewIndex = 0
  local CostNum = _data.ExchangeConf and _data.ExchangeConf.cost_item[1].cost_goods_num
  self.Title:SetText(string.format("%d", CostNum))
  self.Icon:SetPath(_data.FurnitureItemConf.icon)
  if not self.IconInitialized then
    self.IconInitialized = true
    local id = _data.ExchangeConf and _data.ExchangeConf.cost_item[1].cost_goods_id[1]
    local conf = _G.DataConfigManager:GetVisualItemConf(id, true)
    self.Item:SetPath(conf and conf.iconPath)
  end
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  self:PlayAnimation(self.normal)
  self.DelayId = DelayManager:DelayFrames(viewIndex, function()
    self.DelayId = nil
    self:PlayAnimation(self.In_1)
  end)
  self:InternalRefreshCreateStatus()
end

function UMG_FurnitureList_C:InternalRefreshCreateStatus()
  if self.itemData and self.itemData.ScrollingCreateLocked == nil and self.itemData.RefreshSelfCreateCondStatus then
    self.itemData.RefreshSelfCreateCondStatus(self.itemData)
  end
  local Quality = (self.itemData.BagItemConf or {}).item_quality
  local Color = HomeIndoorSandbox.Enum.GetItemQualityColor(Quality)
  self.QualityColor:SetColorAndOpacity(Color)
  local ColorBgPath = HomeIndoorSandbox.Enum.GetItemQualityBgImgPath(Quality)
  self.Selected:SetPath(ColorBgPath)
  if self.itemData.ScrollingCreateLocked then
    self.Unlockable:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Unlockable:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.itemData.ScrollingCreateCondLocked or self.itemData.ScrollingRoomLevelLocked then
    self.Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_FurnitureList_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:StopAnimation(self.normal)
    self:PlayAnimation(self.change)
  else
    self:StopAnimation(self.change)
    self:PlayAnimation(self.normal)
  end
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_FurnitureList_C:OnItemSelected")
    if self._parent.OnFurnitureItemClicked then
      self._parent.OnFurnitureItemClicked(self.itemData, self.itemIndex)
    end
  end
end

function UMG_FurnitureList_C:OnDeactive()
end

return UMG_FurnitureList_C
