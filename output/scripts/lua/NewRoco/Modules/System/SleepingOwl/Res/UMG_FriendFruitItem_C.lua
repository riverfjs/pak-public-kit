local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FriendFruitItem_C = Base:Extend("UMG_FriendFruitItem_C")

function UMG_FriendFruitItem_C:OnConstruct()
end

function UMG_FriendFruitItem_C:OnDestruct()
end

function UMG_FriendFruitItem_C:OnItemUpdate(_data, datalist, index)
  local cruTime = _G.ZoneServer:GetServerTime() / 1000
  if _data.fruit_id and 0 ~= _data.fruit_id then
    self.data = _data
    self.NRCImage_37:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Item:SetVisibility(UE4.ESlateVisibility.Visible)
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.data.fruit_id)
    self.Item:SetPath(NRCUtils:FormatConfIconPath(bagItemConf.icon, _G.UIIconPath.BagItemPath))
    if cruTime - _data.fruit_active_timestamp < 0 or cruTime - _data.slot_active_timestamp < 0 then
      self.CD:SetVisibility(UE4.ESlateVisibility.Visible)
      self.HourglassWidget:SetActiveWidgetIndex(1)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif cruTime - _data.slot_active_timestamp < 0 then
    self.CD:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Item_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_37:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HourglassWidget:SetActiveWidgetIndex(0)
  end
end

function UMG_FriendFruitItem_C:OnItemSelected(_bSelected)
  if _bSelected and self.data and 0 ~= self.data.fruit_id then
    local FruitContent = {}
    FruitContent.BagItem = {}
    FruitContent.BagItem.id = self.data.fruit_id
    FruitContent.BagItem.fruit_active_timestamp = self.data.fruit_active_timestamp
    _G.NRCModeManager:DoCmd(_G.SleepingOwlModuleCmd.OpenOwlFruitTipsPanel, FruitContent)
  end
end

return UMG_FriendFruitItem_C
