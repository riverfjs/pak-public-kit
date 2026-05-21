local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local NPCShopUtils = {}

function NPCShopUtils:GetAdjustGoodConf(goodsId, shopId)
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  if shopConf then
    if shopConf.shop_type == _G.Enum.ShopType.ST_RANDOM_SHOP then
      local goodsConf = _G.DataConfigManager:GetRandomGoodsConf(goodsId)
      if goodsConf then
        return goodsConf
      end
    else
      local goodsConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
      if goodsConf then
        return goodsConf
      end
    end
  end
  return nil
end

function NPCShopUtils:GetGoodsCurrencyTypeAndId(shopId, goodsId)
  local goodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId)
  if not goodsData then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyTypeAndId", "goodsData not found", shopId, goodsId)
    return nil
  end
  local priceInfo = goodsData.real_price
  if not priceInfo then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyTypeAndId", "priceInfo not found", shopId, goodsId)
    return nil
  end
  return priceInfo.goods_type, priceInfo.goods_id
end

function NPCShopUtils:GetGoodsCurrencyIconPath(shopId, goodsId, bNeedSmallIcon)
  local goodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId)
  if not goodsData then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "goodsData not found", shopId, goodsId)
    return nil, nil
  end
  local priceInfo = goodsData.real_price
  if not priceInfo then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "priceInfo not found", shopId, goodsId)
    return nil, nil
  end
  local goodsType = priceInfo.goods_type
  if not goodsType then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "goodsType not found", shopId, goodsId)
    return nil, nil
  end
  return self:GetGoodsCurrencyIconByType(goodsType, priceInfo.goods_id, bNeedSmallIcon)
end

function NPCShopUtils:GetGoodsCurrencyIconByType(goodsType, goodsId, bNeedSmallIcon)
  if goodsType == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsId)
    if vItemConf then
      if bNeedSmallIcon then
        return vItemConf.iconPath, vItemConf.displayName
      else
        return vItemConf.bigIcon, vItemConf.displayName
      end
    else
      Log.Warning("NPCShopUtils:GetGoodsCurrencyIconByType", "vItemConf not found", goodsType, goodsId)
    end
  elseif goodsType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsId)
    if bagItemConf then
      return bagItemConf.icon, bagItemConf.name
    else
      Log.Warning("NPCShopUtils:GetGoodsCurrencyIconByType", "bagItemConf not found", goodsType, goodsId)
    end
  end
  return nil, nil
end

function NPCShopUtils:GetGoodsCurrencyNum(shopId, goodsId)
  local goodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId)
  if not goodsData then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "goodsData not found", shopId, goodsId)
    local goodsConf = self:GetAdjustGoodConf(goodsId, shopId)
    if goodsConf then
      local GoodsType, GoodsId = goodsConf.price_goods_type, goodsConf.price_goods_id
      if GoodsType and GoodsId then
        return self:GetGoodsCurrencyNumByType(GoodsType, GoodsId)
      end
    end
    return 0
  end
  local priceInfo = goodsData.real_price
  if not priceInfo then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "priceInfo not found", shopId, goodsId)
    return 0
  end
  local goodsType = priceInfo.goods_type
  if not goodsType then
    Log.Warning("NPCShopUtils:GetGoodsCurrencyIconPath", "goodsType not found", shopId, goodsId)
    return 0
  end
  if goodsType == _G.Enum.GoodsType.GT_VITEM then
    local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(priceInfo.goods_id)
    if nil == num then
      return 0
    end
    return num
  elseif goodsType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, priceInfo.goods_id)
    if bagItem and bagItem.num then
      return bagItem.num
    else
      Log.Warning("NPCShopUtils:GetGoodsCurrencyNum", "bagItem not found", shopId, goodsId)
      return 0
    end
  end
  return 0
end

function NPCShopUtils:GetClientGoodsPrice(shopId, goodsId)
  local goodsConf = self:GetAdjustGoodConf(goodsId, shopId)
  if not goodsConf then
    Log.Warning("NPCShopUtils:GetClientGoodsPrice", "goodsConf not found", shopId, goodsId)
    return nil
  end
  return goodsConf.price_goods_type, goodsConf.price_goods_id
end

function NPCShopUtils:GetGoodsCurrencyNumByType(goodsType, goodsId)
  if not goodsType or not goodsId then
    return 0
  end
  if goodsType == _G.Enum.GoodsType.GT_VITEM then
    local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(goodsId)
    if nil == num then
      return 0
    end
    return num
  elseif goodsType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, goodsId)
    if bagItem and bagItem.num then
      return bagItem.num
    else
      Log.Warning("NPCShopUtils:GetGoodsCurrencyNumByType invalid param", goodsType, goodsId)
      return 0
    end
  end
  return 0
end

function NPCShopUtils:GetRewardIconAndQuality(Type, id)
  if Type == Enum.GoodsType.GT_BAGITEM then
    local bagitemconf = _G.DataConfigManager:GetBagItemConf(id)
    if not bagitemconf then
      return nil, nil
    end
    return bagitemconf.big_icon, bagitemconf.item_quality
  elseif Type == Enum.GoodsType.GT_VITEM then
    local Vitemconf = _G.DataConfigManager:GetVisualItemConf(id)
    if not Vitemconf then
      return nil, nil
    end
    return Vitemconf.bigIcon, Vitemconf.item_quality
  elseif Type == Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(id)
    if cardSkinConf then
      return string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path), cardSkinConf.card_quality
    end
  elseif Type == Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(id)
    if GetCardIconConf then
      return string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path), GetCardIconConf.card_quality
    end
  elseif Type == Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(id)
    if CardLabelConf then
      return CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH, CardLabelConf.card_quality
    end
  elseif Type == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(id)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      return fashionConf.suits_icon, grade
    end
  elseif Type == Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(id)
    if fashionConf then
      return fashionConf.icon, fashionConf.item_quality
    end
  elseif Type == Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(id)
    if salonConf then
      return salonConf.icon, salonConf.item_quality
    end
  elseif Type == Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(id)
    if shareConf then
      return shareConf.item_icon, shareConf.item_quality
    end
  elseif Type == Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(id)
    if itemConf then
      return itemConf.icon_path, 5
    end
  elseif Type == Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(id)
    if ChatEmojiConf then
      return ChatEmojiConf.emoji_goods_icon, ChatEmojiConf.card_quality
    end
  elseif Type == Enum.GoodsType.GT_FASHION_PACKAGE then
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(id)
    if fashionPackageConf then
      return nil, 5
    end
  elseif Type == Enum.GoodsType.GT_FASHION_BOND then
    local FashionBondConf = _G.DataConfigManager:GetFashionBondConf(id)
    if FashionBondConf then
      return FashionBondConf.fashion_bond_icon, 5
    end
  end
end

return NPCShopUtils
