local UMG_NpcInfo_MerchantNPC_C = _G.NRCPanelBase:Extend("UMG_NpcInfo_MerchantNPC_C")

function UMG_NpcInfo_MerchantNPC_C:OnConstruct()
end

function UMG_NpcInfo_MerchantNPC_C:OnDestruct()
end

function UMG_NpcInfo_MerchantNPC_C:OnActive()
end

function UMG_NpcInfo_MerchantNPC_C:OnDeactive()
end

function UMG_NpcInfo_MerchantNPC_C:OnAddEventListener()
end

function UMG_NpcInfo_MerchantNPC_C:OnEnable(hasConsumptionCount, isOnlineMode, title, desc, titleIcon)
  print("\230\137\147\229\188\128Merchant Panel")
  self.SizeBox:SetVisibility(UE4.ESlateVisibility.Visible)
  self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Node_2:SetPath(titleIcon)
  if isOnlineMode then
    self.SizeBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if false == hasConsumptionCount then
    self.SizeBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.hasConsumptionCount = hasConsumptionCount
  self.npcName_6:SetText(title)
  self.npcDesc_4:SetText(desc)
end

function UMG_NpcInfo_MerchantNPC_C:OnDisable()
  print("\229\133\179\233\151\173Merchant Panel")
end

function UMG_NpcInfo_MerchantNPC_C:UpdateAsyncResource(totalConsume, nextRewardRemaining, costIconPath, hasReward, itemList, numText, hasNextLevelReward)
  self.ConsumeText_2:SetText(totalConsume)
  self.ConsumeText_3:SetText(nextRewardRemaining)
  self.CostIcon_2:SetPath(costIconPath)
  self.NumText_1:SetText(numText)
  if false == hasReward then
    self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  if not hasNextLevelReward then
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif false ~= self.hasConsumptionCount then
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self.DungeonAwardList_1:InitGridView(itemList)
  self.itemList = itemList
end

function UMG_NpcInfo_MerchantNPC_C:ShowDefault()
  self.SizeBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SizeBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_NpcInfo_MerchantNPC_C:UpdateCardItem(share_form_item)
  for _, item in ipairs(self.itemList) do
    if item.cardId then
      for _, v in ipairs(share_form_item) do
        if item.cardId == v.id then
          if item.limit_buy_num > item.buy_num then
            local canBuyCount = item.limit_buy_num - item.buy_num
            item.topLabelText = "\233\153\144\233\135\143"
            item.bShowNum = true
            item.itemNum = canBuyCount
          else
            item.topLabelText = "\229\148\174\231\189\132"
          end
        end
      end
    end
  end
  self.DungeonAwardList_1:InitGridView(self.itemList)
end

return UMG_NpcInfo_MerchantNPC_C
