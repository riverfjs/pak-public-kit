local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PropOptions_C = Base:Extend("UMG_PropOptions_C")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")

function UMG_PropOptions_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnRolePlayPropsBanStateChanged, self.OnRolePlayPropsBanStateChanged)
end

function UMG_PropOptions_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRolePlayPropsBanStateChanged, self.OnRolePlayPropsBanStateChanged)
end

function UMG_PropOptions_C:IsValidItem()
  return self.data and self.data.type and not not self.data.value
end

function UMG_PropOptions_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.keyIndex = 0 == index % 6 and 6 or index % 6
  if not self:IsValidItem() then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  self.Text_PCKey:SetText(self.keyIndex)
  self:StopAllAnimations()
  self:PlayAnimation(self.Normal)
  local propId = self.data and self.data.value or 0
  local conf = _G.DataConfigManager:GetRoleplayPropConf(propId, true)
  if conf then
    self.NumText:SetText(conf.name_text)
    self.ItemIcon:SetPath(conf.icon_path)
    self.ItemIcon_Mask:SetPath(conf.icon_path)
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_PCKey:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NumText:SetText("")
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local bBanned = _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.IsRolePlayPropBanned, propId)
  bBanned = bBanned or _G.NRCModuleManager:DoCmd(_G.AreaAndZoneModuleCmd.CheckRolePlayPropsIsBan, propId)
  self:UpdatePropBanState(bBanned)
end

function UMG_PropOptions_C:OnItemSelected(_bSelected)
  if not self.data or not self.data.value then
    return
  end
  self:StopAllAnimations()
  self.bSelected = _bSelected
  if _bSelected then
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnPropPlacementSelectItem, self.keyIndex)
    self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Change_1)
  else
    self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Change_2)
  end
end

function UMG_PropOptions_C:OnRolePlayPropsBanStateChanged(id, bBanned)
  local propId = self.data and self.data.value or 0
  if propId ~= id then
    return
  end
  Log.Debug("UMG_PropOptions_C:OnRolePlayPropsBanStateChanged", propId, bBanned)
  self:UpdatePropBanState(bBanned)
end

function UMG_PropOptions_C:UpdatePropBanState(bBanned)
  if bBanned then
    self.CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemIcon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemIcon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PropOptions_C
