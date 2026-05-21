local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_BackflowContractManualAwardItem_C = Base:Extend("UMG_Activity_BackflowContractManualAwardItem_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_BackflowContractManualAwardItem_C:OnConstruct()
end

function UMG_Activity_BackflowContractManualAwardItem_C:OnDestruct()
end

function UMG_Activity_BackflowContractManualAwardItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  local itemIcon, itemQuality = ActivityUtils.GetItemIconAndQuality(_data.itemType, _data.itemId)
  self.icon:SetPath(itemIcon)
  if 0 == itemQuality then
  elseif 1 == itemQuality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_1)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == itemQuality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_2)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == itemQuality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_3)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == itemQuality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_4)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == itemQuality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_5)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
  if _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
    self.lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
    if self.BlackMask:GetVisibility() == UE4.ESlateVisibility.Collapsed and not _data.bStageScroll then
      self.BlackMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Reward_get)
    else
      self.BlackMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.BlackMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.redPointReward:SetupKey(475, {
    _data.activity_id,
    _data.bp_level,
    _data.item_index
  })
  self.txtLV:SetText(string.format(_G.LuaText.report_ratio, tostring(_data.itemCount)))
end

function UMG_Activity_BackflowContractManualAwardItem_C:OnItemSelected(_bSelected)
  if self.data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TryGetBPReward)
  else
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.data.itemId, self.data.itemType)
  end
end

return UMG_Activity_BackflowContractManualAwardItem_C
