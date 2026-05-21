local NRCCommonItemIconData = NRCClass:Extend("NRCCommonItemIconData")

function NRCCommonItemIconData:Ctor()
  NRCClass.Ctor(self)
  self.itemType = 0
  self.itemId = 0
  self.itemNum = 0
  self.BagNum = 0
  self.ConsumeNum = 0
  self.id = 0
  self.type = 0
  self.bShowNum = false
  self.bShowTip = false
  self.bShowGetTag = false
  self.bShowTaskTag = false
  self.bShowFirstVictory = false
  self.IsDoCmd = false
  self.DoCmd = nil
  self.Key = nil
  self.extraKey = nil
  self.reward_reason = nil
  self.IsBPlaySound = false
  self.openTipsSoundId = nil
  self.IsCanClick = true
  self.checkIsEnough = nil
  self.IsShowPetbase = false
  self.IsPetBall = false
  self.bEnableLongClick = false
  self.bGray = false
  self.titleText = nil
  self.rightBtnCountdown = nil
end

function NRCCommonItemIconData:FromGoodsItem(item)
  local rewardsTable = {}
  for k, v in ipairs(item) do
    local rewards = NRCCommonItemIconData()
    rewards.itemType = v.type
    rewards.itemId = v.id
    rewards.itemNum = v.num
    rewards.bShowNum = true
    if rewards.itemType == _G.Enum.GoodsType.GT_RP_BEHAVIOR then
      rewards.bShowTip = false
    else
      rewards.bShowTip = true
    end
    rewards.reward_reason = v.reward_reason
    rewards.IsShowPetbase = v.IsShowPetbase
    rewards.id = v.id
    rewards.type = v.type
    rewards.bag_item = v.bag_item
    if v.reward_reason and v.reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_MAIL_REWARD then
      rewards.showDefaultIconWhenConfigError = true
    end
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

return NRCCommonItemIconData
