local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TerritoryTrial_RewardPreviewItem_C = Base:Extend("UMG_Activity_TerritoryTrial_RewardPreviewItem_C")

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnConstruct()
  self:AddButtonListener(self.Btn6.btnLevelUp, self.GetReward)
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnDestruct()
  self:RemoveButtonListener(self.Btn6.btnLevelUp)
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  if _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
    self.NRCSwitcher_1:SetActiveWidgetIndex(2)
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.Text:SetText(_data.desc_text)
  local rewardItem = _G.DataConfigManager:GetRewardConf(_data.reward_id).RewardItem
  local rewardData = {}
  for _, v in ipairs(rewardItem) do
    local data = _G.NRCCommonItemIconData()
    data.itemType = v.Type
    data.itemId = v.Id
    data.itemNum = v.Count
    data.bShowNum = true
    table.insert(rewardData, data)
  end
  local sortRewardData = self:SortItem(rewardData)
  self.NRCGridView_95:InitGridView(sortRewardData)
  self.Btn6:SetRedDotExtraKey(215, {
    _data.activity_id,
    _data.reward_id
  })
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:SortItem(RewardsList)
  local SortRewardsList = {}
  for i, Reward in ipairs(RewardsList) do
    Reward.Sort = 0
    Reward.Conf = nil
    if Reward.itemType == _G.ProtoEnum.GoodsType.GT_VITEM then
      Reward.Conf = _G.DataConfigManager:GetVisualItemConf(Reward.itemId)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
      end
    elseif Reward.itemType == _G.ProtoEnum.GoodsType.GT_PET then
      Reward.Conf = _G.DataConfigManager:GetPetbaseConf(Reward.itemId)
      Reward.Sort = 0
    elseif Reward.itemType == _G.ProtoEnum.GoodsType.GT_BAGITEM then
      Reward.Conf = _G.DataConfigManager:GetBagItemConf(Reward.itemId)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
      end
    end
  end
  SortRewardsList = RewardsList
  table.sort(SortRewardsList, function(a, b)
    if a.Sort < b.Sort then
      return a.Sort < b.Sort
    elseif a.Sort == b.Sort then
      local ANewSort = a.itemId
      local BNewSort = b.itemId
      if a.itemType == _G.ProtoEnum.GoodsType.GT_VITEM then
        ANewSort = ANewSort + 9999999
      elseif b.itemType == _G.ProtoEnum.GoodsType.GT_VITEM then
        BNewSort = BNewSort + 9999999
      end
      return ANewSort < BNewSort
    end
  end)
  return SortRewardsList
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:GetReward()
  local req = _G.ProtoMessage:newZoneChallengeStarRewardReq()
  req.activity_id = self.uiData.activity_id
  req.star_num = self.uiData.point_required
  self.uiData.parent:SetRewardId(self.uiData.reward_id)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_STAR_REWARD_REQ, req, self, self.OnRewardGet)
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnRewardGet(rsp)
  if 0 == rsp.ret_info.ret_code then
    local rewardData = _G.DataConfigManager:GetRewardConf(self.uiData.parent:GetRewardId()).RewardItem
    local popupInitData = {}
    for i = 1, #rewardData do
      local popupData = _G.ProtoMessage:newGoodsItem()
      popupData.id = rewardData[i].Id
      popupData.num = rewardData[i].Count
      popupData.type = rewardData[i].Type
      table.insert(popupInitData, popupData)
    end
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
  end
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_TerritoryTrial_RewardPreviewItem_C:OnDeactive()
end

return UMG_Activity_TerritoryTrial_RewardPreviewItem_C
