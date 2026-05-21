local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_Handbook_CollectRewards_Item_C = _G.NRCPanelBase:Extend("UMG_Handbook_CollectRewards_Item_C")

function UMG_Handbook_CollectRewards_Item_C:OnConstruct()
end

function UMG_Handbook_CollectRewards_Item_C:OnActive(_data, _index)
  self.uiData = _data
  self.index = _index
  self:InitRedData(_index)
  self.Number:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Button:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_27:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Number:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC860FF"))
  self.Number_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC860FF"))
  self:ChangStyle()
  if not self.uiData.State and self.uiData.IsCanReceive then
    self.NRCImage:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_sitiao_yes_png.img_sitiao_yes_png'")
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Normal)
  elseif self.uiData.State and self.uiData.IsCanReceive then
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Number:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Number_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Number_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("B28C3CFF"))
    self:PlayAnimation(self.Received)
  elseif not self.uiData.State and not self.uiData.IsCanReceive then
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Normal)
  end
  self:updateItemInfo()
end

function UMG_Handbook_CollectRewards_Item_C:ChangStyle()
  local areaId = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookId)
  local areaHandbookConf = _G.DataConfigManager:GetAreaHandbook(areaId)
  if areaHandbookConf then
    if areaHandbookConf.not_collect_node_res then
      self.NRCImage_1:SetPath(areaHandbookConf.not_collect_node_res)
    end
    if areaHandbookConf.not_collect_node_bar then
      self.NRCImage:SetPath(areaHandbookConf.not_collect_node_bar)
    end
    if areaHandbookConf.collect_node_res then
      self.NRCImage_65:SetPath(areaHandbookConf.collect_node_res)
    end
  end
end

function UMG_Handbook_CollectRewards_Item_C:CloseTips()
  if not self.IsPlayPopUpIn then
    return
  end
  self:PlayAnimation(self.PopUps_Out)
  self.IsPlayPopUpIn = false
end

function UMG_Handbook_CollectRewards_Item_C:ShowTips(dataList)
  if not self.IsPlayPopUpIn then
    self:PlayAnimation(self.PopUps_In)
  end
  self.IsPlayPopUpIn = true
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_LevelUpRewards_C:OnAwardListItemSelected")
  self.CanvasPanel_27:SetVisibility(UE4.ESlateVisibility.Visible)
  self.List:InitGridView(dataList)
end

function UMG_Handbook_CollectRewards_Item_C:OnTouchEnded(MyGeometry, InTouchEvent)
  self:OnClick()
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Handbook_CollectRewards_Item_C:ClickTips()
  local dataList = {}
  local rewardType
  for i = 1, #self.uiData.Data.handbook_reward do
    local reward = self.uiData.Data.handbook_reward[i]
    if reward.handbook_reward_type == _G.Enum.GoodsType.GT_BAGITEM then
      rewardType = _G.Enum.PetHandbookAward.AWARD_ITEM
    elseif reward.handbook_reward_type == _G.Enum.GoodsType.GT_VITEM then
      rewardType = _G.Enum.PetHandbookAward.AWARD_VITEM
    end
    table.insert(dataList, {
      id = reward.handbook_reward_id,
      type = rewardType,
      num = reward.handbook_reward_number,
      itemType = reward.handbook_reward_type,
      bMask = self.uiData.State
    })
  end
  if self.CanvasPanel_27:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:CloseTips()
  else
    self:ShowTips(dataList)
  end
  self.IsClickReceive = false
  _G.NRCModuleManager:GetModule("HandbookModule"):DispatchEvent(HandbookModuleEvent.OnCollectRewardsClickIndex, self.index)
end

function UMG_Handbook_CollectRewards_Item_C:OnClick()
  if self:IsAnimationPlaying(self.Receive) then
    return
  end
  local isOtherItemPlayingReceive = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetDisableRewardAnimationState)
  if not isOtherItemPlayingReceive and not self.uiData.State and self.uiData.IsCanReceive then
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.Receive)
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetDisableRewardAnimationState, true)
  else
    self:ClickTips()
  end
end

function UMG_Handbook_CollectRewards_Item_C:InitRedData(index)
  local idx = tostring(index - 1)
  self.Dot:CancelPlayLoopAnim()
  self.Dot:EnableAnimation()
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 0, 1)
  self.Dot:SetupKey(redId, {idx})
end

function UMG_Handbook_CollectRewards_Item_C:updateItemInfo()
  self.Number:SetText(self.uiData.Data.handbook_number)
  self.Number_1:SetText(self.uiData.Data.handbook_number)
end

function UMG_Handbook_CollectRewards_Item_C:getQuality(quality)
  self.BGColor:SetVisibility(UE4.ESlateVisibility.Visible)
  if 0 == quality then
    self.BGColor:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UMG_Handbook_CollectRewards_Item_C:OnAnimationFinished(anim)
  if anim == self.PopUps_Out then
    self.CanvasPanel_27:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.Receive then
    if self.uiData then
      _G.NRCModeManager:DoCmd(HandbookModuleCmd.GetHandbookAward, self.uiData.Idx, self.index)
    end
  elseif anim == self.Normal then
  end
end

return UMG_Handbook_CollectRewards_Item_C
