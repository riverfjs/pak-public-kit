local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local UMG_ClaimRewardList_C = Base:Extend("UMG_ClaimRewardList_C")

function UMG_ClaimRewardList_C:OnConstruct()
  self.isRewardTaken = false
  self:OnAddEventListener()
end

function UMG_ClaimRewardList_C:OnDestruct()
end

function UMG_ClaimRewardList_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self:SetUpInfos()
end

function UMG_ClaimRewardList_C:SetUpInfos()
  local text = self.uiData.rewardInfo.total_consumption_num
  self.ItemNum:SetText(text)
  self.ItemNum1:SetText(LuaText.total_consumption)
  self.isRewardTaken = self.uiData.isRewardTaken
  local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(self.uiData.price_goods_type, self.uiData.price_goods_id)
  self.CostIcon:SetPath(iconPath)
  if self.uiData.isRewardTaken == true then
    self.TaskProgress:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Btn6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Mask:SetRenderOpacity(1)
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Seal:SetRenderOpacity(1)
    self.Seal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self.uiData.isRewardTaken == false and self.uiData.total_consume_num < self.uiData.rewardInfo.total_consumption_num then
    self.UMG_Btn6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TaskProgress:SetText(_G.DataConfigManager:GetLocalizationConf("task_in_progress").msg)
    self.TaskProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Seal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.uiData.isRewardTaken == false and self.uiData.total_consume_num >= self.uiData.rewardInfo.total_consumption_num then
    self.UMG_Btn6:SetRedDotKey(290, {
      self.uiData.shopId
    })
    self.UMG_Btn6.Title_1:SetText(_G.DataConfigManager:GetLocalizationConf("TASK_TAKE").msg)
    self.TaskProgress:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Normal)
  end
  local rewardList = _G.DataConfigManager:GetRewardConf(self.uiData.rewardInfo.reward_id).RewardItem
  self.rewardTipList = self:SetRewardTipList(rewardList)
  local rewardItemList = self:SetRewardList(rewardList)
  self.NRCGridView_98:InitGridView(rewardItemList)
  if self.uiData.isRewardTaken == true then
    self:ChangeListItemAlreadyReceived(true)
  end
end

function UMG_ClaimRewardList_C:SetRewardList(itemInfo)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.itemNum = v.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

function UMG_ClaimRewardList_C:SetRewardTipList(itemInfo)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = {}
    rewards.first_get = false
    rewards.id = v.Id
    rewards.num = v.Count
    rewards.reward_reason = ProtoEnum.FlowReason.FLOW_REASON_MALL_BUY
    rewards.tag = 0
    rewards.type = v.Type
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

function UMG_ClaimRewardList_C:OnItemSelected(_bSelected)
end

function UMG_ClaimRewardList_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_Btn6.btnLevelUp, self.OnBtnCollectRewardClick)
end

function UMG_ClaimRewardList_C:OnBtnCollectRewardClick()
  if not self.isRewardTaken then
    self.isRewardTaken = true
    local req = _G.ProtoMessage:newZoneReceiveShopTotalConsumptionRewardReq()
    req.shop_id = self.uiData.shopId
    req.reward_level = self.uiData.rewardInfo.total_consumption_level
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_SHOP_TOTAL_CONSUMPTION_REWARD_REQ, req, self, self.GetReceiveShopTotalConsumptionRewardRsp, false, false)
  end
end

function UMG_ClaimRewardList_C:GetReceiveShopTotalConsumptionRewardRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:ChangeListItemAlreadyReceived(true)
    local req = _G.ProtoMessage:newZoneShopGetInfoReq()
    req.shop_id = self.uiData.shopId
    local reqShopData = {
      shopId = self.uiData.shopId,
      Caller = self,
      rspHandler = self.GetStoreListRsp,
      needModal = false,
      ignoreErrorTip = false,
      reqTag = "UMG_ClaimRewardList_C:GetReceiveShopTotalConsumptionRewardRsp"
    }
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
    _G.NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.RefreshHasCountAfterClaimReward)
    self:PlayAnimation(self.Get)
  end
end

function UMG_ClaimRewardList_C:ChangeListItemAlreadyReceived(bIsReceived)
  for i = 1, self.NRCGridView_98:GetItemCount() do
    local item = self.NRCGridView_98:GetItemByIndex(i - 1)
    item:SetAlreadyReceived(bIsReceived)
  end
end

function UMG_ClaimRewardList_C:GetStoreListRsp(_rsp)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.RefreshNPCShopPanel, _rsp)
end

function UMG_ClaimRewardList_C:OnAnimationFinished(anim)
  if anim == self.Get then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.RefreshClaimRewardPanel)
    local msg = _G.DataConfigManager:GetLocalizationConf("get_report_reward").msg
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.rewardTipList, msg)
  end
end

function UMG_ClaimRewardList_C:OnDeactive()
end

return UMG_ClaimRewardList_C
