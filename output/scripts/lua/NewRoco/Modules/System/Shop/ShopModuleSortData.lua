local ShopModuleSortData = {}

function ShopModuleSortData:ProcessShopGoodsDataOptimized(goodsDataList, shopId)
  local itemListInfo = {}
  local playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  if goodsDataList and #goodsDataList > 0 then
    for _, goodsData in ipairs(goodsDataList) do
      if goodsData.goods_id ~= nil then
        local goodsConf = _G.DataConfigManager:GetNormalShopConf(goodsData.goods_id)
        if goodsConf then
          local goodsInfo = self:CalculateGoodsAttributes(goodsData, goodsConf, playerLevel, shopId, goodsDataList)
          if goodsInfo then
            table.insert(itemListInfo, goodsInfo)
          end
        else
          Log.Warning("ShopModuleSortData:ProcessShopGoodsDataOptimized", "goodsConf is nil, goodsData.goods_id: ", goodsData.goods_id)
        end
      else
        Log.Warning("ShopModuleSortData:ProcessShopGoodsDataOptimized", "goodsData.goods_id is nil")
      end
    end
    self:SortGoodsByOriginalLogic(itemListInfo)
  end
  return itemListInfo
end

function ShopModuleSortData:CalculateGoodsAttributes(goodsData, goodsConf, playerLevel, shopId, goodsDataList)
  local canBuy, limitBuyType = self:CheckBuyCondition(goodsData, goodsConf, playerLevel, goodsDataList)
  local quality = self:CalculateGoodsQuality(goodsConf)
  local positionPriority = self:CalculatePositionPriority(goodsConf, goodsData)
  local sortScore = self:CalculateSortScoreExact(canBuy, quality, positionPriority, limitBuyType, goodsConf, goodsData)
  if goodsData.limit_buy_num == nil then
    Log.Warning("ShopModuleSortData:CalculateGoodsAttributes", "goodsData.limit_buy_num is nil")
    goodsData.limit_buy_num = 0
  end
  if nil == goodsData.buy_num then
    Log.Warning("ShopModuleSortData:CalculateGoodsAttributes", "goodsData.buy_num is nil")
    goodsData.buy_num = 0
  end
  if nil == goodsData.next_refresh_time then
    Log.Info("ShopModuleSortData:CalculateGoodsAttributes", "goodsData.next_refresh_time is nil")
    goodsData.next_refresh_time = 0
  end
  return {
    shopItemId = goodsData.goods_id or 0,
    shopLibId = goodsData.goods_shop_id or 0,
    boughtNum = goodsData.buy_num or 0,
    selectedNum = 0,
    last_refresh_time = goodsData.last_refresh_time or 0,
    selectedState = false,
    next_refresh_time = goodsData.next_refresh_time or 0,
    disable_time = goodsData.disable_time or 0,
    canBuy = canBuy,
    limitBuyType = limitBuyType,
    PurchaseLimit = 0 ~= goodsData.limit_buy_num,
    showMoneyCost = {
      0,
      0,
      0
    },
    quality = quality,
    positionPriority = positionPriority,
    sortScore = sortScore,
    category = self:GetGoodsCategory(canBuy, limitBuyType, goodsConf),
    originalGoodsData = goodsData,
    originalGoodsConf = goodsConf,
    shopId = shopId
  }
end

function ShopModuleSortData:CheckBuyCondition(goodsData, goodsConf, playerLevel, goodsDataList)
  local canBuy = false
  local limitBuyType = 0
  local limitBuyParam
  local hasStock = goodsData.limit_buy_num > goodsData.buy_num or 0 == goodsData.limit_buy_num
  if goodsData.limit_buy_num > 0 and goodsData.buy_num >= goodsData.limit_buy_num then
    if goodsConf.hidden_after_purchase and 1 == goodsConf.hidden_after_purchase then
      return false, 0
    else
      return false, 2
    end
  end
  Log.Info("ShopModuleSortData:CheckBuyCondition buy_cond_type", goodsConf.buy_cond_type, goodsConf.buy_cond_param, goodsData.goods_id)
  if (goodsConf.buy_cond_type == Enum.BuyLimited.BL_NONE or goodsConf.buy_cond_type == nil) and hasStock then
    canBuy = true
    limitBuyType = 0
  elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_PLAYER_LEVEL and hasStock then
    local limitLevel = tonumber(goodsConf.buy_cond_param)
    if playerLevel >= limitLevel then
      canBuy = true
    else
      Log.Info("ShopModuleSortData:CheckBuyCondition playerLevel < limitLevel,goodsData.goods_id:", playerLevel, limitLevel, goodsData.goods_id)
    end
    limitBuyParam = limitLevel
    limitBuyType = 1
  elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_PLAYER_BP_LEVEL and hasStock then
    local limitLevel = tonumber(goodsConf.buy_cond_param)
    local battlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
    if battlePassInfo then
      local bpLevel = battlePassInfo.exp_info.level or 0
      if limitLevel <= bpLevel then
        canBuy = true
      else
        Log.Info("ShopModuleSortData:CheckBuyCondition bpLevel < limitLevel,goodsData.goods_id:", bpLevel, limitLevel, goodsData.goods_id)
      end
    else
      Log.Info("ShopModuleSortData:CheckBuyCondition battlePassInfo is nil,goodsData.goods_id:", goodsData.goods_id)
    end
    limitBuyParam = limitLevel
    limitBuyType = 1
  elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_YK_MAX_DAYS and hasStock then
    canBuy = true
    limitBuyType = 1
  elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_WORLD_LEVEL and hasStock then
    local playerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    local limitWorldLevel = tonumber(goodsConf.buy_cond_param)
    if playerWorldLevel >= limitWorldLevel then
      canBuy = true
    else
      Log.Info("ShopModuleSortData:CheckBuyCondition playerWorldLevel < limitWorldLevel,goodsData.goods_id:", playerWorldLevel, limitWorldLevel, goodsData.goods_id)
    end
    limitBuyParam = limitWorldLevel
    limitBuyType = 1
  elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_SOLDOUT and hasStock then
    local param1 = tonumber(goodsConf.buy_cond_param) or 0
    local allSoldOut = true
    if 1 == param1 then
      local requiredGoodsIds = goodsConf.buy_cond_param1 or {}
      if type(requiredGoodsIds) == "table" then
        for _, requiredGoodsId in ipairs(requiredGoodsIds) do
          local found = false
          for _, otherGoodsData in ipairs(goodsDataList) do
            if otherGoodsData.goods_id == requiredGoodsId then
              found = true
              local isSoldOut = otherGoodsData.limit_buy_num > 0 and otherGoodsData.buy_num >= otherGoodsData.limit_buy_num
              Log.Info("ShopModuleSortData:CheckBuyCondition", "requiredGoodsId", requiredGoodsId, "isSoldOut", isSoldOut)
              if not isSoldOut then
                allSoldOut = false
                break
              end
            end
          end
          Log.Info("ShopModuleSortData:CheckBuyCondition", "found", found)
          if not found then
            allSoldOut = false
            break
          end
        end
      end
    else
      for _, otherGoodsData in ipairs(goodsDataList) do
        if otherGoodsData.goods_id ~= goodsData.goods_id then
          local isSoldOut = otherGoodsData.limit_buy_num > 0 and otherGoodsData.buy_num >= otherGoodsData.limit_buy_num
          Log.Info("ShopModuleSortData:CheckBuyCondition", "otherGoodsData.goods_id", otherGoodsData.goods_id, "isSoldOut", isSoldOut)
          if not isSoldOut then
            allSoldOut = false
            break
          end
        end
      end
    end
    Log.Info("ShopModuleSortData:CheckBuyCondition", "allSoldOut", allSoldOut)
    if allSoldOut then
      canBuy = true
    end
    limitBuyType = 3
  end
  return canBuy, limitBuyType, limitBuyParam
end

function ShopModuleSortData:CalculateGoodsQuality(goodsConf)
  local quality = 1
  if goodsConf.background then
    if goodsConf.background == UEPath.SHOP_QUALITY_5 then
      quality = 5
    elseif goodsConf.background == UEPath.SHOP_QUALITY_4 then
      quality = 4
    elseif goodsConf.background == UEPath.SHOP_QUALITY_3 then
      quality = 3
    elseif goodsConf.background == UEPath.SHOP_QUALITY_2 then
      quality = 2
    elseif goodsConf.background == UEPath.SHOP_QUALITY_1 then
      quality = 1
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    if bagItemConf then
      quality = bagItemConf.item_quality
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_REWARD then
    local rewardConf = _G.DataConfigManager:GetRewardConf(goodsConf.item_id)
    if rewardConf and rewardConf.RewardItem then
      quality = 2
      for _, rewardItem in ipairs(rewardConf.RewardItem) do
        if rewardItem.Type == Enum.GoodsType.GT_BAGITEM then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewardItem.Id)
          if bagItemConf and quality <= bagItemConf.item_quality then
            quality = bagItemConf.item_quality
          end
        end
      end
    end
  end
  return quality
end

function ShopModuleSortData:CalculatePositionPriority(goodsConf, goodsData)
  local positionPriority = 0
  if goodsConf.shop_pos and goodsConf.shop_pos > 0 then
    positionPriority = 10000 - goodsConf.shop_pos
  else
    positionPriority = 0
  end
  return positionPriority
end

function ShopModuleSortData:CalculateSortScoreExact(canBuy, quality, positionPriority, limitBuyType, goodsConf, goodsData)
  local score = 0
  local category = self:GetGoodsCategory(canBuy, limitBuyType, goodsConf)
  if 1 == category then
    if goodsConf.shop_pos and goodsConf.shop_pos > 0 then
      score = score + 10000000
    else
      score = score + 9000000
    end
  elseif 2 == category then
    if goodsConf.shop_pos and goodsConf.shop_pos > 0 then
      score = score + 8000000
    else
      score = score + 7000000
    end
  elseif 3 == category then
    if goodsConf.shop_pos and goodsConf.shop_pos > 0 then
      score = score + 6000000
    else
      score = score + 5000000
    end
  end
  if goodsConf.shop_pos and goodsConf.shop_pos > 0 then
    score = score + (100000 - goodsConf.shop_pos * 1000)
  end
  if not goodsConf.shop_pos or not (goodsConf.shop_pos > 0) then
    score = score + quality * 10000
  else
    score = score + quality * 100
  end
  score = score + limitBuyType * 1000
  if goodsData.limit_buy_num and goodsData.limit_buy_num > 0 then
    score = score + 100
  end
  return score
end

function ShopModuleSortData:GetGoodsCategory(canBuy, limitBuyType, goodsConf)
  if canBuy then
    return 1
  elseif 1 == limitBuyType then
    return 2
  elseif 2 == limitBuyType then
    return 3
  else
    return 4
  end
end

function ShopModuleSortData:SortGoodsByOriginalLogic(itemListInfo)
  table.sort(itemListInfo, function(a, b)
    if a.sortScore ~= b.sortScore then
      return a.sortScore > b.sortScore
    end
    return a.shopItemId < b.shopItemId
  end)
end

return ShopModuleSortData
