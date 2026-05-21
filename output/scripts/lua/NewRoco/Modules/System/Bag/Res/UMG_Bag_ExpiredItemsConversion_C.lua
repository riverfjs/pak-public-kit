local BagModuleUtils = require("NewRoco.Modules.System.Bag.BagModuleUtils")
local UMG_Bag_ExpiredItemsConversion_C = _G.NRCPanelBase:Extend("UMG_Bag_ExpiredItemsConversion_C")

function UMG_Bag_ExpiredItemsConversion_C:OnConstruct(_data)
  self:SetChildViews(self.PopUp1)
end

function UMG_Bag_ExpiredItemsConversion_C:OnActive(_beforeConvertList, _afterConvertList, expireGidList, goods_rewards)
  self:InitData(_beforeConvertList, _afterConvertList, expireGidList)
  self.goods_rewards = goods_rewards
  self:OnAddEventListener()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400007, "UMG_Bag_ExpiredItemsConversion_C:OnActive")
end

function UMG_Bag_ExpiredItemsConversion_C:OnPcClose()
  Log.Debug("UMG_Bag_ExpiredItemsConversion_C:OnPcClose")
  self:closePanel()
end

function UMG_Bag_ExpiredItemsConversion_C:InitData(_beforeConvertList, _afterConvertList, expireGidList)
  self.expireGidList = expireGidList
  local beforeConvertList = _beforeConvertList
  local afterConvertList = _afterConvertList
  beforeConvertList = self:SortItem(beforeConvertList)
  afterConvertList = self:SortItem(afterConvertList)
  self.GridView1:InitList(beforeConvertList)
  self.GridView2:InitList(afterConvertList)
end

function UMG_Bag_ExpiredItemsConversion_C:SortItem(RewardsList)
  local SortRewardsList = {}
  for i, Reward in ipairs(RewardsList) do
    Reward.Sort = 0
    Reward.Conf = nil
    Reward.Quality = 0
    if Reward.itemType == _G.ProtoEnum.GoodsType.GT_VITEM then
      Reward.Conf = _G.DataConfigManager:GetVisualItemConf(Reward.itemId)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
        Reward.Quality = Reward.Conf.item_quality
      end
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_PET then
      Reward.Conf = _G.DataConfigManager:GetPetbaseConf(Reward.itemId)
      Reward.Sort = 0
      Reward.Quality = 0
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_BAGITEM then
      Reward.Conf = _G.DataConfigManager:GetBagItemConf(Reward.itemId)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
        Reward.Quality = Reward.Conf.item_quality
      end
    end
  end
  SortRewardsList = RewardsList
  table.sort(SortRewardsList, function(a, b)
    if a.Quality ~= b.Quality then
      return a.Quality > b.Quality
    end
    if a.Sort < b.Sort then
      return a.Sort < b.Sort
    elseif a.Sort == b.Sort then
      local ANewSort = a.itemId
      local BNewSort = b.itemId
      if a.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        ANewSort = ANewSort + 9999999
      elseif b.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        BNewSort = BNewSort + 9999999
      end
      return ANewSort < BNewSort
    end
  end)
  return SortRewardsList
end

function UMG_Bag_ExpiredItemsConversion_C:OnDestruct()
  if self.goods_rewards and self.goods_rewards.rewards and #self.goods_rewards.rewards > 0 then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.goods_rewards.rewards)
  end
end

function UMG_Bag_ExpiredItemsConversion_C:closePanel()
  if self.expireGidList and #self.expireGidList > 0 then
    _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.ZoneBagItemExpireCheckReq, self.expireGidList)
    self.expireGidList = nil
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40007009, "UMG_Bag_ExpiredItemsConversion_C:closePanel")
  self:DoClose()
end

function UMG_Bag_ExpiredItemsConversion_C:OnAddEventListener()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.closePanel
  CommonPopUpData.Desc = LuaText.item_expired
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp1:SetPanelInfo(CommonPopUpData)
end

return UMG_Bag_ExpiredItemsConversion_C
