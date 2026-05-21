local AppearanceModuleData = _G.NRCData:Extend("AppearanceModuleData")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local _FashionMallPopUpRecordFileName = "NrcFashionMallPopUpRecord"
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")

function AppearanceModuleData:Ctor()
  NRCData.Ctor(self)
  self.curAppearChooseType = _G.Enum.FashionLabelType.FLT_SUIT
  self.curAppearChooseSubType = _G.Enum.FashionLabelType.FLT_SUIT
  self.curBeautyChooseType = _G.Enum.SalonLabelType.SLT_BEGIN
  self.curBeautyChooseSubType = _G.Enum.SalonLabelType.SLT_BEGIN
  self.onlyShowOwned = false
  self.bOpenCamping = false
  self.bShowDecorators = true
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  self.lastSelectedWardrobeIndex = 0
  self.lastValidSelectedWardrobeIndex = 0
  if fashionInfo and fashionInfo.current_wardrobe_index then
    self.lastSelectedWardrobeIndex = fashionInfo.current_wardrobe_index + 1
    self.lastValidSelectedWardrobeIndex = self.lastSelectedWardrobeIndex
  end
  if fashionInfo then
    self.curWardrobeData = fashionInfo.wardrobe_data
  end
  self.SavedAppearData = {}
  self.SavedBeautyData = {}
  self.TempAppearData = nil
  self.TempBeautyData = nil
  self.SuitComponentData = {}
  self:_InitSuitComponentData(fashionInfo)
  self.AppearShopItemList = nil
  self.BeautyShopItemList = nil
  self.FashionIdToGoodsIdMap = {}
  self.SalonIdToGoodsIdMap = {}
  self.BagItemIdToGoodsIdMap = {}
  self.SuitIdToGoodsIdMap = {}
  self.ColorIndexToColorIdMap = {}
  self.UIColorIndexToColorIdMap = {}
  self.PathToFashionIdMap = {}
  self.PathToSalonIdMap = {}
  self.EnumToFashionTabMap = {}
  self.TabToSubType = {}
  self.fashionIdToSuitIdMap = {}
  self.levelUpFashionIdToSuitIdMap = {}
  self.levelUpSalonIdToSuitIdMap = {}
  self.bondIdToSuitId = {}
  self.giftIdToPackageIdMap = {}
  self.AvatarSalonIdToSalonIds = {}
  self.FashionMallPopUpRecord = {}
  self.AllSuitInPackage = {}
  self.packageIdToGoodsIdMap = {}
  self.goodsIdToPackageIdMap = {}
  self.suitIdToExchangeGoodsMap = {}
  self.suitIdToExchangeVoucherMap = {}
  self.currentBPSuitIdSet = {}
  self.bIsBuyItem = false
  self.closetTabTypeList = {}
  self.closetTabMap = {}
  self.CloseTabFashionMap = {}
  self.CloseTabConfigMap = {}
  self.fashionFreeList = nil
  self.salonFreeList = nil
  self.fashionHasList = nil
  self.salonHasList = nil
  self.canChangeWardrobeIndex = true
  self.IsWorldReloading = false
  self.IsFirstOpen = false
  self.InitBodyPath = {}
  self.curSelectedColorIndex = {
    0,
    0,
    0,
    0,
    0,
    0
  }
  self.StartTime = 0
  self.EndTime = 1
  self.AvatarPlayerRotationAngle = nil
  self.IsClockwiseRotation = false
  self.AvatarPlayerRotation = UE4.FRotator()
  self.InitialSuitBottomCache = {}
  self._suitWearIdCache = nil
  self.AvatarPlayerRotation_Yaw = nil
  self.AvatarPlayerRotation_InitializeYaw = nil
  self.FrontAndBackRotation_Yaw = nil
  self.CurrentFashionLabelTyp = nil
  self.IsRotation = false
  self.rotationContexts = {}
  self.PlayAnimStartTime = 0
  self.PlayAnimEndTime = 6
  self.PlayMoZhangIdleTime = 0
  self.IsPlayAnim = false
  self.TempHairData = {}
  self.ActionName = {
    "HZLookHead",
    "HZLookFoot",
    "HZLookBack",
    "HZLookBody",
    "HZLookHand",
    "HZMoZhangLoop"
  }
  self.ChoosePreSuitType = 13
  self.curTryOnItemInfo = {
    type = _G.Enum.GoodsType.GT_NONE,
    id = 0
  }
  self.NPCActionOpenShop = nil
  self.closetSuitList = {}
  self.closetFashionListByType = {}
  self.closetSalonListByType = {}
  self.bChooseClosetFashionTab = true
  self.closetChooseTabType = -1
  self.closetChooseOutterTab = -1
  self.allClothShopInfoMap = {}
  self.CardRevealedState = {}
  self.closetAvatarTransform = nil
  self.fashionBondLastTab = nil
  self.suitItemIdToTimeTokenDic = {}
  self.itemIdToTimeTokenDic = {}
  self.OwnedGlassItemTabList = nil
  self.curSelectItemInfo = nil
  self.curSelectedItemGlassMap = {}
  self.savedItemGlassMap = nil
  self.curTopExclusionPanel = AppearanceModuleEnum.ExclusionPanelType.None
end

function AppearanceModuleData:SetCurTopExclusionPanel(panelType)
  self.curTopExclusionPanel = panelType
end

function AppearanceModuleData:GetCurTopExclusionPanel()
  return self.curTopExclusionPanel
end

function AppearanceModuleData:SetAppearChooseType(type)
  self.curAppearChooseType = type
end

function AppearanceModuleData:SetAppearChooseSubType(type)
  self.curAppearChooseSubType = type
end

function AppearanceModuleData:SetBeautyChooseType(type)
  self.curBeautyChooseType = type
end

function AppearanceModuleData:SetBeautyChooseSubType(type)
  self.curBeautyChooseSubType = type
end

function AppearanceModuleData:SetAppearShopItemList(itemList)
  self.AppearShopItemList = itemList
end

function AppearanceModuleData:SetBeautyShopItemList(itemList)
  self.BeautyShopItemList = itemList
end

function AppearanceModuleData:SetCurWardrobeData(wardrobeData)
end

function AppearanceModuleData:SetTempHairData(itemType, itemId, salonGoodsId, colorIndex)
  if self.TempHairData and #self.TempHairData > 0 then
    self.TempHairData[1].SalonId = itemId
    self.TempHairData[1].SalonGoodsId = salonGoodsId
    self.TempHairData[1].SalonColorIndex = colorIndex
  else
    table.insert(self.TempHairData, {
      SalonType = itemType,
      SalonId = itemId,
      SalonGoodsId = salonGoodsId,
      SalonColorIndex = colorIndex
    })
  end
end

function AppearanceModuleData:GetAppearanceList(chooseType, bHas)
  local showList = {}
  local showHas = false
  if showHas then
  else
    for i = 1, #self.AppearShopItemList do
      local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.AppearShopItemList[i].goods_id)
      table.insert(showList, {
        FashionId = fashionGoodsConf.item_id
      })
    end
  end
  return showList
end

function AppearanceModuleData:SaveCurAppearChooseInfo()
end

function AppearanceModuleData:TempCurAppearChooseInfo(itemType, itemId, fashionGoodsId, bChoosed, tag, glassInfo)
  local itemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
  if itemConf then
    itemType = itemConf.type
  end
  local hasType = false
  if self.TempAppearData == nil then
    self.TempAppearData = {}
    if bChoosed then
      table.insert(self.TempAppearData, {
        FashionType = itemType,
        FashionId = itemId,
        FashionGoodsId = fashionGoodsId,
        tag = tag,
        glassInfo = glassInfo
      })
    end
  elseif bChoosed then
    for i = 1, #self.TempAppearData do
      if self.TempAppearData[i].FashionType == itemType then
        self.TempAppearData[i].FashionId = itemId
        self.TempAppearData[i].FashionGoodsId = fashionGoodsId
        self.TempAppearData[i].tag = tag
        self.TempAppearData[i].glassInfo = glassInfo
        hasType = true
      end
    end
    if false == hasType then
      table.insert(self.TempAppearData, {
        FashionType = itemType,
        FashionId = itemId,
        FashionGoodsId = fashionGoodsId,
        tag = tag,
        glassInfo = glassInfo
      })
    end
    self:RemoveConflictFashionItem(itemType, tag)
  else
    for i = 1, #self.TempAppearData do
      if self.TempAppearData[i].FashionType == itemType then
        table.remove(self.TempAppearData, i)
        break
      end
    end
  end
  table.sort(self.TempAppearData, function(a, b)
    return a.FashionType < b.FashionType
  end)
  self._suitWearIdCache = nil
end

function AppearanceModuleData:TempCurBeautyChooseInfo(itemType, itemId, salonGoodsId, colorIndex, bChoosed)
  local hasType = false
  if self.TempBeautyData == nil then
    self.TempBeautyData = {}
    table.insert(self.TempBeautyData, {
      SalonType = itemType,
      SalonId = itemId,
      SalonGoodsId = salonGoodsId,
      SalonColorIndex = colorIndex
    })
  else
    for i = 1, #self.TempBeautyData do
      if self.TempBeautyData[i].SalonType == itemType then
        self.TempBeautyData[i].SalonId = itemId
        self.TempBeautyData[i].SalonGoodsId = salonGoodsId
        self.TempBeautyData[i].SalonColorIndex = colorIndex
        hasType = true
      end
    end
    if false == hasType then
      table.insert(self.TempBeautyData, {
        SalonType = itemType,
        SalonId = itemId,
        SalonGoodsId = salonGoodsId,
        SalonColorIndex = colorIndex
      })
    end
  end
  self._suitWearIdCache = nil
end

function AppearanceModuleData:GetBeautyList(chooseType)
end

function AppearanceModuleData:SumAppearCostMoney()
  local diamondCost = 0
  local coinCost = 0
  if self.TempAppearData ~= nil then
    for i = 1, #self.TempAppearData do
      local hasOwned = self.module:OnCmdChsueckHasOwned(_G.Enum.GoodsType.GT_FASHION, self.TempAppearData[i].FashionId)
      if not hasOwned then
        local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.TempAppearData[i].FashionGoodsId)
        if fashionGoodsConf and fashionGoodsConf.price_goods_type == Enum.GoodsType.GT_VITEM then
          if fashionGoodsConf.price_goods_id == _G.Enum.VisualItem.VI_DIAMOND then
            diamondCost = diamondCost + fashionGoodsConf.origin_price
          elseif fashionGoodsConf.price_goods_id == _G.Enum.VisualItem.VI_COIN then
            coinCost = coinCost + fashionGoodsConf.origin_price
          end
        end
      end
    end
  end
  return diamondCost, coinCost
end

function AppearanceModuleData:ClearDataOnAppearClosed()
  self.TempAppearData = nil
  self._suitWearIdCache = nil
  self.AppearShopItemList = nil
  self.onlyShowOwned = false
end

function AppearanceModuleData:ClearDataOnBeautyClosed()
  self.TempBeautyData = nil
  self.BeautyShopItemList = nil
end

function AppearanceModuleData:BuildCurrentBPSuitMap()
  self.currentBPSuitIdSet = {}
  local currentBPId
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local allBPConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_CONF)
  if allBPConfList then
    local allBPDatas = allBPConfList:GetAllDatas()
    for _, bpConf in pairs(allBPDatas or {}) do
      if bpConf.open_time and bpConf.close_time then
        local openTimeStamp = ActivityUtils.ToTimestamp(bpConf.open_time) * 1000
        local closeTimeStamp = ActivityUtils.ToTimestamp(bpConf.close_time) * 1000
        if svrTime >= openTimeStamp and svrTime < closeTimeStamp then
          currentBPId = bpConf.id
          break
        end
      end
    end
  end
  if not currentBPId then
    return
  end
  local rewardIdSet = {}
  local passRewardTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_REWARD_CONF)
  if not passRewardTable then
    return
  end
  local allPassRewardDatas = passRewardTable:GetAllDatas()
  if not allPassRewardDatas then
    return
  end
  for _, passRewardConf in pairs(allPassRewardDatas) do
    if passRewardConf.bp_id == currentBPId then
      if passRewardConf.male_free_reward_id and passRewardConf.male_free_reward_id > 0 then
        rewardIdSet[passRewardConf.male_free_reward_id] = true
      end
      if passRewardConf.female_free_reward_id and passRewardConf.female_free_reward_id > 0 then
        rewardIdSet[passRewardConf.female_free_reward_id] = true
      end
      if passRewardConf.male_paid_reward_id and passRewardConf.male_paid_reward_id > 0 then
        rewardIdSet[passRewardConf.male_paid_reward_id] = true
      end
      if passRewardConf.female_paid_reward_id and passRewardConf.female_paid_reward_id > 0 then
        rewardIdSet[passRewardConf.female_paid_reward_id] = true
      end
    end
  end
  for rewardId, _ in pairs(rewardIdSet) do
    local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
    if rewardConf and rewardConf.RewardItem then
      for _, rewardItem in ipairs(rewardConf.RewardItem) do
        if rewardItem.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
          self.currentBPSuitIdSet[rewardItem.Id] = true
        elseif rewardItem.Type == _G.Enum.GoodsType.GT_FASHION then
          local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(rewardItem.Id)
          if fashionItemConf and fashionItemConf.suits_id then
            local suitId = tonumber(fashionItemConf.suits_id)
            if suitId and suitId > 0 then
              self.currentBPSuitIdSet[suitId] = true
            end
          end
        end
      end
    end
  end
end

function AppearanceModuleData:BuildFashionIdToGoodsIdMap()
  local fashionGoodsTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NORMAL_SHOP_CONF)
  local fashionGoodsData = fashionGoodsTable:GetAllDatas()
  self.FashionIdToGoodsIdMap = {}
  if fashionGoodsData then
    for _, conf in pairs(fashionGoodsData) do
      if conf.Type == _G.Enum.GoodsType.GT_FASHION or conf.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
        self.FashionIdToGoodsIdMap[conf.item_id] = conf
      end
      if conf.Type == _G.Enum.GoodsType.GT_FASHION_PACKAGE then
        self.packageIdToGoodsIdMap[conf.item_id] = conf.id
        self.goodsIdToPackageIdMap[conf.id] = conf.item_id
        if conf.gift_list and #conf.gift_list then
          for k, v in ipairs(conf.gift_list) do
            self.giftIdToPackageIdMap[v] = conf.item_id
          end
        end
      end
    end
  end
end

function AppearanceModuleData:BuildSalonIdToGoodsIdMap()
  local fashionGoodsTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NORMAL_SHOP_CONF)
  local fashionGoodsData = fashionGoodsTable:GetAllDatas()
  self.SalonIdToGoodsIdMap = {}
  for _, conf in pairs(fashionGoodsData) do
    if conf.Type == _G.Enum.GoodsType.GT_SALON then
      self.SalonIdToGoodsIdMap[conf.item_id] = conf
    end
    if conf.Type == _G.Enum.GoodsType.GT_BAGITEM then
      self.BagItemIdToGoodsIdMap[conf.item_id] = conf
    end
  end
end

function AppearanceModuleData:BuildColorIndexToColorIdMap()
  local colorTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CHANGE_COLOUR_CONF)
  local colorData = colorTable:GetAllDatas()
  self.ColorIndexToColorIdMap = {}
  for _, conf in pairs(colorData) do
    self.ColorIndexToColorIdMap[conf.rank_value] = conf
  end
end

function AppearanceModuleData:BuildUIColorIndexToColorMap()
  local colorTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CHANGE_COLOUR_CONF)
  local colorData = colorTable:GetAllDatas()
  self.UIColorIndexToColorIdMap = {}
  for _, conf in pairs(colorData) do
    self.UIColorIndexToColorIdMap[conf.ui_value] = conf
  end
end

function AppearanceModuleData:BuildPathToFashionIdMap()
  local fashionItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_ITEM_CONF)
  local fashionItemData = fashionItemTable:GetAllDatas()
  self.PathToFashionIdMap = {}
  for _, conf in pairs(fashionItemData) do
    self.PathToFashionIdMap[conf.model] = conf
  end
end

function AppearanceModuleData:BuildPathToSalonIdMap()
  local salonItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SALON_ITEM_CONF)
  local salonItemData = salonItemTable:GetAllDatas()
  self.PathToSalonIdMap = {}
  for _, conf in pairs(salonItemData) do
    if conf.model then
      self.PathToSalonIdMap[conf.model] = conf
    end
  end
end

function AppearanceModuleData:BuildEnumToFashionTabMap()
  local fashionTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_TAB_CONF)
  local fashionTabTable = fashionTabConf:GetAllDatas()
  self.EnumToFashionTabMap = {}
  for _, conf in pairs(fashionTabTable) do
    if conf.use_FashionLabelType then
      self.EnumToFashionTabMap[conf.use_FashionLabelType] = conf
      if conf.fathertab then
        local fatherTab = tonumber(conf.fathertab)
        if fatherTab > 0 and conf.subrank_value > 0 then
          if self.TabToSubType[fatherTab] == nil then
            self.TabToSubType[fatherTab] = {}
          end
          table.insert(self.TabToSubType[fatherTab], {
            rankValue = conf.subrank_value,
            tabConfId = _
          })
        end
      end
    end
  end
end

function AppearanceModuleData:BuildClosetTabMap()
  local closetTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
  local closetTabTable = closetTabConf:GetAllDatas()
  for k, conf in pairs(closetTabTable) do
    local bFashion = false
    local labelType = conf.use_FashionLabelType
    if conf.use_FashionLabelType and conf.use_FashionLabelType >= 0 then
      bFashion = true
    else
      labelType = conf.use_SalonLabelType
    end
    if conf.rank_value > 0 then
      self.closetTabTypeList[conf.rank_value] = {
        bFashion = bFashion,
        LabelType = labelType,
        tabConfId = k
      }
    end
    if not string.IsNilOrEmpty(conf.fathertab) and conf.subrank_value > 0 then
      local fatherTab = tonumber(conf.fathertab)
      if self.closetTabMap[fatherTab] == nil then
        self.closetTabMap[fatherTab] = {}
      end
      table.insert(self.closetTabMap[fatherTab], {
        bFashion = bFashion,
        LabelType = labelType,
        rankValue = conf.subrank_value,
        tabConfId = k
      })
    end
    self.CloseTabFashionMap[conf.use_FashionLabelType] = conf.icon
    if conf.use_FashionLabelType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
      self.CloseTabConfigMap[conf.use_FashionLabelType] = conf
    end
  end
  Log.Dump(self.closetTabMap, 4, "AppearanceModuleData:BuildClosetTabMap")
  Log.Dump(self.closetTabTypeList, 4, "AppearanceModuleData:BuildClosetTabMap11")
end

function AppearanceModuleData:GetItemPartType(goodsType, itemId)
  if goodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    return _G.Enum.FashionLabelType.FLT_SUIT
  elseif goodsType == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionItemConf then
      return fashionItemConf.type
    end
    Log.Error("AppearanceModuleData:GetItemPartType: fashionGoodsConf is not valid", itemId)
    return _G.Enum.FashionLabelType.FLT_BEGIN
  elseif goodsType == _G.Enum.GoodsType.GT_CARD_SKIN then
    return _G.Enum.FashionLabelType.FLT_CARDSKIN
  else
    Log.Error("AppearanceModuleData:GetItemPartType: goodsType is not valid", goodsType)
    return _G.Enum.FashionLabelType.FLT_BEGIN
  end
end

function AppearanceModuleData:GetItemIconPathByItemType(itemType)
  local Conf = self.CloseTabConfigMap[itemType]
  if Conf then
    local IconPath = Conf.icon
    if Conf.rank_value > 0 then
      IconPath = Conf.shop_icon
    end
    return IconPath
  end
  return nil
end

function AppearanceModuleData:BuildAllClothShopInfoMap()
  local suitConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_SUITS_CONF)
  local suitTable = suitConf:GetAllDatas()
  local visited = {}
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, 103)
end

function AppearanceModuleData:GetSubTypeFromFashionTabId(tabId)
  if self.TabToSubType[tabId] then
    return self.TabToSubType[tabId]
  else
    return nil
  end
end

function AppearanceModuleData:GetInitBodyPath()
  local defaultSuitClass
  if self.module.player.gender == Enum.ESexValue.SEX_MALE then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  else
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  if not defaultSuitClass then
    Log.Error("AppearanceModuleData:GetInitBodyPath defaultSuitClass is nil, gender:", self.module.player.gender)
    return
  end
  local BPDefaultSuitConfig = defaultSuitClass:GetDefaultObject()
  local bodyPath = BPDefaultSuitConfig.BodyPaths:ToTable()
  local salonPath = BPDefaultSuitConfig.SalonParams:ToTable()
  self.InitBodyPath = bodyPath
end

function AppearanceModuleData:SetFreeItemList()
  local fashionFreeList = {}
  local salonFreeList = {}
  local fashionItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_ITEM_CONF)
  local fashionItemData = fashionItemTable:GetAllDatas()
  for k, v in pairs(fashionItemData) do
    if v.is_free_item and (self.module.player.gender == v.gender or v.gender == Enum.ESexValue.SEX_NOT_SEL) then
      table.insert(fashionFreeList, k)
    end
  end
  local salonItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SALON_ITEM_CONF)
  local salonItemData = salonItemTable:GetAllDatas()
  for k, v in pairs(salonItemData) do
    if v.is_free_item and (self.module.player.gender == v.gender or v.gender == Enum.ESexValue.SEX_NOT_SEL) then
      table.insert(salonFreeList, k)
    end
  end
  self.fashionFreeList = fashionFreeList
  self.salonFreeList = salonFreeList
end

function AppearanceModuleData:SetHasItemList()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local hasFashionList
  if fashionInfo then
    hasFashionList = fashionInfo.owned_item_info
  else
    Log.Error("AppearanceModuleData hasFashionList is nil")
  end
  local returnFashionList = {}
  if hasFashionList and #hasFashionList > 0 then
    for i = 1, #hasFashionList do
      table.insert(returnFashionList, hasFashionList[i].item_id)
    end
  end
  for i = 1, #self.fashionFreeList do
    table.insert(returnFashionList, self.fashionFreeList[i])
  end
  self.fashionHasList = returnFashionList
end

function AppearanceModuleData:SetHasSalonList()
  local salonInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerSalonInfo()
  local hasSalonList
  if salonInfo then
    hasSalonList = salonInfo.item_owned_id
  end
  local returnSalonList = {}
  if hasSalonList and #hasSalonList > 0 then
    for i = 1, #hasSalonList do
      table.insert(returnSalonList, hasSalonList[i])
    end
  end
  for i = 1, #self.salonFreeList do
    table.insert(returnSalonList, self.salonFreeList[i])
  end
  self.salonHasList = returnSalonList
end

function AppearanceModuleData:FilterHasAndInitFashion()
  local filterList = {}
  self.module:GetTempDataFromAvatar()
  if self.TempAppearData and #self.TempAppearData > 0 then
    for i = 1, #self.TempAppearData do
      local hasOwned = false
      for k, v in ipairs(self.fashionHasList) do
        if self.TempAppearData[i].FashionId == v then
          hasOwned = true
          break
        end
      end
      if false == hasOwned then
        table.insert(filterList, self.TempAppearData[i])
      end
    end
  end
  return filterList
end

function AppearanceModuleData:FilterHasAndInitSalon()
  local filterList = {}
  self.module:GetTempDataFromAvatar()
  if self.TempBeautyData and #self.TempBeautyData > 0 then
    for i = 1, #self.TempBeautyData do
      local hasOwned = false
      for k, v in ipairs(self.salonHasList) do
        if self.TempBeautyData[i].SalonId == v then
          hasOwned = true
          break
        end
      end
      if false == hasOwned then
        table.insert(filterList, self.TempBeautyData[i])
      end
    end
  end
  return filterList
end

function AppearanceModuleData:GetFashionFreeWand()
  for k, v in ipairs(self.fashionFreeList) do
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
    if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
      return v
    end
  end
  return 0
end

function AppearanceModuleData:GetCurSelectWardrobeIndex()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if not fashionInfo then
    return 1
  end
  return (fashionInfo.current_wardrobe_index or 0) + 1
end

function AppearanceModuleData:GetWardrobeDataByIndex(index, showname)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if not fashionInfo then
    return nil
  end
  local wardrobeData = fashionInfo.wardrobe_data
  if wardrobeData and index <= #wardrobeData then
    if showname then
      if wardrobeData[index] and wardrobeData[index].name ~= nil then
        return wardrobeData[index].name
      else
        return LuaText.umg_appearance_suititem_1 .. index
      end
    elseif wardrobeData[index] then
      return wardrobeData[index].wearing_item, wardrobeData[index].salon_item_wear_id
    else
      return nil
    end
  else
    return nil
  end
end

function AppearanceModuleData:GetFashionOwnedBySuitId(suitId)
  local suitFashionOwned = {}
  local suitFashionNotOwned = {}
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  local suitFashionIds = suitConf.item_id
  if suitFashionIds and #suitFashionIds > 0 then
    for k, v in ipairs(suitFashionIds) do
      local hasOwned = self.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, v)
      if hasOwned then
        table.insert(suitFashionOwned, v)
      else
        table.insert(suitFashionNotOwned, v)
      end
    end
  end
  return suitFashionOwned, suitFashionNotOwned
end

function AppearanceModuleData:CheckSuitEffect(fashionIds1, bShowTips, bCheckOwned)
  local showTips = bShowTips
  local suitTable = {}
  local effectSuitIds = {}
  local fashionIds = fashionIds1
  if fashionIds and #fashionIds > 0 then
  else
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo then
      if 0 ~= fashionInfo.suit_id then
        fashionIds = self:GetFashionIDsBySuitID(fashionInfo.suit_id)
      elseif fashionInfo.wardrobe_data and fashionInfo.wardrobe_data[fashionInfo.current_wardrobe_index + 1] then
        local fashionItems = fashionInfo.wardrobe_data[fashionInfo.current_wardrobe_index + 1].wearing_item
        fashionIds = {}
        for _, v in pairs(fashionItems or {}) do
          table.insert(fashionIds, v.wearing_item_id)
        end
      end
    else
      Log.Error("AppearanceModuleData:CheckSuitEffect fashionInfo is nil")
    end
  end
  if fashionIds and #fashionIds > 0 then
    for k, v in ipairs(fashionIds) do
      local itemId
      if type(v) == "number" then
        itemId = v
      elseif "table" == type(v) then
        itemId = v.wearing_item_id
      end
      local hasOwned = true
      if bCheckOwned then
        hasOwned = self.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, itemId)
      end
      if itemId > 0 and hasOwned then
        local suitsId = self.fashionIdToSuitIdMap[itemId]
        if suitsId then
          if suitTable[suitsId] then
            suitTable[suitsId] = suitTable[suitsId] + 1
          else
            suitTable[suitsId] = {}
            suitTable[suitsId] = 1
          end
        end
      end
    end
    for k, v in pairs(suitTable) do
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(tonumber(k))
      local suitEffectIds = suitConf.effect_item_id
      if v < #suitEffectIds then
      else
        local sameNum = 0
        for _, val in ipairs(suitEffectIds) do
          for i = 1, #fashionIds do
            if type(fashionIds[i]) == "number" then
              if fashionIds[i] == val then
                sameNum = sameNum + 1
              end
            elseif type("table" == fashionIds[i]) and fashionIds[i].wearing_item_id == val then
              sameNum = sameNum + 1
            end
          end
        end
        if sameNum == #suitEffectIds then
          if bShowTips then
            local tip = _G.DataConfigManager:GetLocalizationConf("fashion_suits_effect_text").msg
            local fullTip = string.format(tip, suitConf.name)
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, fullTip)
          end
          table.insert(effectSuitIds, k)
        else
        end
      end
    end
  end
  return effectSuitIds
end

function AppearanceModuleData:GetFashionIDsBySuitID(suit_id)
  local suitData = _G.DataConfigManager:GetFashionSuitsConf(suit_id)
  if suitData then
    local fashionIDs = suitData.item_id
    return fashionIDs
  end
  return nil
end

function AppearanceModuleData:GetFashionTabConfByEnum(enum)
  return self.EnumToFashionTabMap[enum]
end

function AppearanceModuleData:GetCurSuitPvPInfo(suitId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local suitInfo = fashionInfo.suit_info
  if suitInfo and #suitInfo > 0 then
    for k, v in ipairs(suitInfo) do
      if v.suit_id == suitId then
        return v.petbase_pvp_win_num or 0
      end
    end
  end
  return 0
end

function AppearanceModuleData:SetOpenNpcShopType(type)
  self.OpenNpcShopType = type
end

function AppearanceModuleData:GetOpenNpcShopType()
  return self.OpenNpcShopType
end

function AppearanceModuleData:BuildFashionIdToSuitIdMap()
  local fashionSuitsData = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_SUITS_CONF):GetAllDatas()
  for k, suitConf in pairs(fashionSuitsData) do
    for i = 1, #suitConf.item_id do
      local fashionId = suitConf.item_id[i]
      if self.fashionIdToSuitIdMap[fashionId] == nil then
        self.fashionIdToSuitIdMap[fashionId] = {}
      end
      self.fashionIdToSuitIdMap[fashionId] = k
    end
    if suitConf.bond_id and 0 ~= suitConf.bond_id and (not suitConf.suits_original_id or 0 == suitConf.suits_original_id) then
      if not self.bondIdToSuitId[suitConf.gender] then
        self.bondIdToSuitId[suitConf.gender] = {}
      end
      self.bondIdToSuitId[suitConf.gender][suitConf.bond_id] = suitConf.id
    end
    for i = 1, #suitConf.lv_up_closet do
      local item = suitConf.lv_up_closet[i]
      if item then
        if item.lv_item_type == _G.Enum.GoodsType.GT_FASHION then
          self.levelUpFashionIdToSuitIdMap[item.lv_item_id] = suitConf.id
        elseif item.lv_item_type == _G.Enum.GoodsType.GT_SALON then
          self.levelUpSalonIdToSuitIdMap[item.lv_item_id] = suitConf.id
        end
      end
    end
  end
end

function AppearanceModuleData:BuildTimeTokenDic()
  local RedPointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetRedPointSplitPointDataByKeyAndReason, 407, _G.Enum.RedPointReason.RPR_FASHION_SUIT)
  self.suitItemIdToTimeTokenDic = {}
  if RedPointData then
    for _, data in ipairs(RedPointData) do
      self.suitItemIdToTimeTokenDic[tonumber(data[1])] = true
    end
  end
  RedPointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetRedPointSplitPointDataByKeyAndReason, 408, _G.Enum.RedPointReason.RPR_FASHION_ITEM)
  self.itemIdToTimeTokenDic = {}
  if RedPointData then
    for _, data in ipairs(RedPointData) do
      self.itemIdToTimeTokenDic[tonumber(data[1])] = true
    end
  end
end

function AppearanceModuleData:CollectAllPIKAShopActivity()
  local activityConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ACTIVITY_CONF):GetAllDatas()
  self.PIKAShopActivityId = {}
  if activityConfTable then
    for k, activityConf in pairs(activityConfTable) do
      if activityConf.activity_type == Enum.ActivityType.ATP_PIKA then
        table.insert(self.PIKAShopActivityId, activityConf.id)
      end
    end
  end
end

function AppearanceModuleData:InitClosetShowItemList()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, player.gender)
  local initSelectSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialSelectedSuitId, player.gender)
  local initSuitIdMap = {}
  if initSuitIds then
    for k, v in ipairs(initSuitIds) do
      initSuitIdMap[v] = true
    end
  end
  local fashionSuitTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_SUITS_CONF):GetAllDatas()
  if self.closetFashionListByType[Enum.FashionLabelType.FLT_SUIT] == nil then
    self.closetFashionListByType[Enum.FashionLabelType.FLT_SUIT] = {}
  end
  local upgradeSuitId = {}
  for k, v in pairs(fashionSuitTable) do
    if initSuitIdMap[v.id] and v.id ~= initSelectSuitId then
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 407, v.id, true)
    elseif player.gender == v.gender or v.gender == _G.Enum.ESexValue.SEX_NOT_SEL then
      table.insert(self.closetFashionListByType[Enum.FashionLabelType.FLT_SUIT], k)
      for k1, v1 in ipairs(v.lv_up_closet) do
        if v1.lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
          table.insert(upgradeSuitId, v1.lv_item_id)
        end
      end
    end
  end
  local fashionItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_ITEM_CONF):GetAllDatas()
  for k, v in pairs(fashionItemTable) do
    local conf = _G.DataConfigManager:GetItemTransConf(k, true)
    if conf and v.suits_id ~= initSelectSuitId then
    else
      if nil == self.closetFashionListByType[v.type] then
        self.closetFashionListByType[v.type] = {}
      end
      if player.gender == v.gender or v.gender == _G.Enum.ESexValue.SEX_NOT_SEL then
        table.insert(self.closetFashionListByType[v.type], k)
      end
    end
  end
  local salonItemTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SALON_ITEM_CONF):GetAllDatas()
  local salonItemArr = {}
  for k, conf in pairs(salonItemTable) do
    table.insert(salonItemArr, conf)
  end
  table.stableSort(salonItemArr, function(a, b)
    return a.id < b.id
  end)
  for k, conf in ipairs(salonItemArr) do
    if nil == self.AvatarSalonIdToSalonIds[conf.avatar_id] then
      self.AvatarSalonIdToSalonIds[conf.avatar_id] = {}
    end
    table.insert(self.AvatarSalonIdToSalonIds[conf.avatar_id], conf.id)
  end
  for key, val in pairs(self.AvatarSalonIdToSalonIds) do
    if val and #val > 0 then
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(val[1])
      if nil == self.closetSalonListByType[salonItemConf.type] then
        self.closetSalonListByType[salonItemConf.type] = {}
      end
      if player.gender == salonItemConf.gender or salonItemConf.gender == _G.Enum.ESexValue.SEX_NOT_SEL then
        table.insert(self.closetSalonListByType[salonItemConf.type], val)
      end
    end
  end
  Log.Dump(self.closetSalonListByType, 3, "AppearanceModuleData:InitClosetShowItemList")
end

function AppearanceModuleData:CheckSuitTime(suitId, count)
  count = count or 0
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if suitConf and suitConf.activity_time and not string.IsNilOrEmpty(suitConf.activity_time) then
    local activityStartTime = ActivityUtils.ToTimestamp(suitConf.activity_time) * 1000
    if svrTime < activityStartTime then
      return false
    end
  end
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  if fashionGoodsConf then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
    if goodsShopConf then
      if goodsShopConf.enable then
        if goodsShopConf.enable_time then
          local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
          if svrTime >= startTimeStamp then
            return true
          end
        else
          return true
        end
      end
      if goodsShopConf.fashion_random_shop and goodsShopConf.fashion_random_shop.enable then
        local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.enable_time) * 1000
        local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.disable_time) * 1000
        if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
          return true
        end
      end
    end
    local exchangeGoodsId = self.suitIdToExchangeGoodsMap and self.suitIdToExchangeGoodsMap[suitId]
    if exchangeGoodsId then
      local exchangeGoodsConf = _G.DataConfigManager:GetNormalShopConf(exchangeGoodsId)
      if exchangeGoodsConf and exchangeGoodsConf.enable then
        local startTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.enable_time) * 1000
        if svrTime > startTimeStamp then
          return true
        end
      end
    end
    if self.currentBPSuitIdSet and self.currentBPSuitIdSet[suitId] then
      return true
    end
    return false
  else
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    if suitConf and suitConf.suits_original_id and 0 ~= suitConf.suits_original_id then
      if suitConf.color_suits_launch == _G.Enum.FashionColorSuitsLaunch.FCSL_NORMALSUITS then
        if count < 1 then
          return self:CheckSuitTime(suitConf.suits_original_id, count + 1)
        else
          Log.Error("\229\135\186\231\142\176\230\173\187\229\190\170\231\142\175\229\143\175\232\131\189\239\188\140\232\175\183\232\129\148\231\179\187elbertwu\239\188\140suitId: ", suitId)
          return false
        end
      elseif suitConf.color_suits_launch == _G.Enum.FashionColorSuitsLaunch.FCSL_SEASONSTART and suitConf.season_id and 0 ~= suitConf.season_id then
        local seasonConf = _G.DataConfigManager:GetSeasonConf(suitConf.season_id)
        if seasonConf then
          local startTimeStamp = ActivityUtils.ToTimestamp(seasonConf.start_time) * 1000
          local endTimeStamp = ActivityUtils.ToTimestamp(seasonConf.end_time) * 1000
          if svrTime >= endTimeStamp or svrTime > startTimeStamp and svrTime < endTimeStamp then
            return true
          else
            return false
          end
        end
      end
    end
  end
  return true
end

function AppearanceModuleData:CheckSuitAtMonthlyShop(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  if fashionGoodsConf then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
    if goodsShopConf and goodsShopConf.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
        return true, AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
      end
    end
  end
  return false
end

function AppearanceModuleData:CheckSuitAtRandomShop(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  if fashionGoodsConf then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
    if goodsShopConf and goodsShopConf.fashion_random_shop and goodsShopConf.fashion_random_shop.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
        return true, AppearanceModuleEnum.FashionMallShopId.RANDOM_FASHION
      end
    end
  end
  return false
end

function AppearanceModuleData:CheckSuitAtExchangeShop(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local exchangeGoodsId = self.suitIdToExchangeGoodsMap[suitId]
  if exchangeGoodsId then
    local exchangeGoodsConf = _G.DataConfigManager:GetNormalShopConf(exchangeGoodsId)
    if exchangeGoodsConf and exchangeGoodsConf.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == svrTime) then
        return true, AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION
      end
    end
  end
end

function AppearanceModuleData:CheckSuitAtShopGiftOrMonthlyShop_Old(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  if fashionGoodsConf then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
    if goodsShopConf and goodsShopConf.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime > endTimeStamp or 0 == svrTime) then
        return true, AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
      end
    end
  end
  local exchangeGoodsId = self.suitIdToExchangeGoodsMap[suitId]
  if exchangeGoodsId then
    local exchangeGoodsConf = _G.DataConfigManager:GetNormalShopConf(exchangeGoodsId)
    if exchangeGoodsConf and exchangeGoodsConf.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime > endTimeStamp or 0 == svrTime) then
        return true, AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION
      end
    end
  end
  return false
end

function AppearanceModuleData:GetSuitState(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  local hasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, suitId)
  if hasSuit then
    return AppearanceModuleEnum.SuitState.Obtained
  end
  if fashionGoodsConf then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
    if goodsShopConf then
      do
        local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
        local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
        if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
          return AppearanceModuleEnum.SuitState.OnShelf
        end
      end
      if goodsShopConf.fashion_random_shop and goodsShopConf.fashion_random_shop.enable then
        local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.enable_time) * 1000
        local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.fashion_random_shop.disable_time) * 1000
        if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
          return AppearanceModuleEnum.SuitState.OnShelf
        end
      end
      local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
      if endTimeStamp > 0 and svrTime > endTimeStamp then
        return AppearanceModuleEnum.SuitState.OffShelf
      end
      if svrTime < startTimeStamp then
        return AppearanceModuleEnum.SuitState.NotOnShelf
      end
      return AppearanceModuleEnum.SuitState.NotPurchasable
    end
  end
  return AppearanceModuleEnum.SuitState.NotOnShelf
end

function AppearanceModuleData:GetNormalShopConfBySuitId(suitId)
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[suitId]
  if fashionGoodsConf then
    return _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
  end
  return nil
end

function AppearanceModuleData:GetNormalShopConfByFashionId(itemId)
  local fashionGoodsConf = self.FashionIdToGoodsIdMap[itemId]
  if fashionGoodsConf then
    return _G.DataConfigManager:GetNormalShopConf(fashionGoodsConf.id)
  end
  return nil
end

function AppearanceModuleData:GetClosetShowItemList(bFashion, typeEnum)
  if bFashion then
    local showFashionList = {}
    if self.closetFashionListByType[typeEnum] and #self.closetFashionListByType[typeEnum] > 0 then
      for k, v in ipairs(self.closetFashionListByType[typeEnum]) do
        if typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
          local hasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, v)
          if self:CheckSuitTime(v) or hasSuit then
            table.insert(showFashionList, v)
          end
        else
          local bOwned = self.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, v)
          if bOwned then
            table.insert(showFashionList, v)
          end
        end
      end
    end
    return showFashionList
  else
    local showSalonList = {}
    if self.closetSalonListByType[typeEnum] and #self.closetSalonListByType[typeEnum] > 0 then
      for k, v in ipairs(self.closetSalonListByType[typeEnum]) do
        local subList = {}
        for key, confId in ipairs(v) do
          local bOwned = self.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_SALON, confId)
          if bOwned then
            table.insert(subList, confId)
          end
        end
        if subList and #subList > 0 then
          table.insert(showSalonList, subList)
        end
      end
    end
    return showSalonList
  end
end

function AppearanceModuleData:GetWearIdByType(bFashion, typeEnum)
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bFashion then
    local fashionWear = self.TempAppearData
    if fashionWear and #fashionWear > 0 then
      if typeEnum ~= _G.Enum.FashionLabelType.FLT_SUIT then
        for k, v in ipairs(fashionWear) do
          if v.FashionId > 0 and v.FashionType == typeEnum then
            return v.FashionId
          end
        end
      else
        if self._suitWearIdCache ~= nil then
          return self._suitWearIdCache
        end
        local firstItem = fashionWear[1]
        local belongSuitId = self.fashionIdToSuitIdMap[firstItem.FashionId]
        if not belongSuitId or 0 == belongSuitId then
          self._suitWearIdCache = 0
          return 0
        end
        local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, player.gender)
        local initSuitIdSet = {}
        if initSuitIds then
          for _, id in ipairs(initSuitIds) do
            initSuitIdSet[id] = true
          end
        end
        local allFromInitialSuit = true
        local wearCountExcludeWand = 0
        for _, wearItem in ipairs(fashionWear) do
          if wearItem.FashionId > 0 and wearItem.FashionType ~= _G.Enum.FashionLabelType.FLT_WAND then
            wearCountExcludeWand = wearCountExcludeWand + 1
            local wearBelongSuitId = self.fashionIdToSuitIdMap[wearItem.FashionId]
            if not wearBelongSuitId or not initSuitIdSet[wearBelongSuitId] then
              allFromInitialSuit = false
              break
            end
          end
        end
        if allFromInitialSuit then
          local initSelectSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialSelectedSuitId, player.gender)
          local initSuitConf = _G.DataConfigManager:GetFashionSuitsConf(initSelectSuitId, true)
          if initSuitConf and initSuitConf.item_id then
            local initSuitItemCountExcludeWand = 0
            for _, itemId in ipairs(initSuitConf.item_id) do
              local itemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
              if itemConf and itemConf.type ~= _G.Enum.FashionLabelType.FLT_WAND then
                initSuitItemCountExcludeWand = initSuitItemCountExcludeWand + 1
              end
            end
            if wearCountExcludeWand == initSuitItemCountExcludeWand then
              self._suitWearIdCache = initSelectSuitId
              return initSelectSuitId
            end
          end
        end
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(belongSuitId, true)
        if suitConf then
          for k, v in ipairs(suitConf.item_id) do
            local bFound = false
            for k1, v1 in ipairs(fashionWear) do
              if v1.FashionId == v then
                bFound = true
                break
              end
            end
            if not bFound then
              self._suitWearIdCache = 0
              return 0
            end
          end
          local beautyWear = self.TempBeautyData
          local playerFashion = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
          local index = 0
          if playerFashion and playerFashion.suit_info then
            for k, v in ipairs(playerFashion.suit_info) do
              if v.suit_id == belongSuitId then
                index = k
                break
              end
            end
            if 0 ~= index and playerFashion.suit_info[index].components_is_worn then
              for k, v in ipairs(playerFashion.suit_info[index].components_is_worn) do
                local bFound = false
                if suitConf.lv_up_closet and suitConf.lv_up_closet[v + 1] then
                  local itemId = suitConf.lv_up_closet[v + 1].lv_item_id
                  if suitConf.lv_up_closet[v + 1].lv_item_type == _G.Enum.GoodsType.GT_FASHION then
                    for k1, v1 in ipairs(fashionWear) do
                      if v1.FashionId == itemId then
                        bFound = true
                        break
                      end
                    end
                  elseif suitConf.lv_up_closet[v + 1].lv_item_type == _G.Enum.GoodsType.GT_SALON then
                    if beautyWear and #beautyWear > 0 then
                      for k1, v1 in ipairs(beautyWear) do
                        if itemId == v1.SalonId then
                          bFound = true
                          break
                        end
                      end
                    end
                  elseif suitConf.lv_up_closet[v + 1].lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
                    bFound = true
                  end
                end
                if not bFound then
                  self._suitWearIdCache = 0
                  return 0
                end
              end
            end
          end
          self._suitWearIdCache = belongSuitId
          return belongSuitId
        else
          self._suitWearIdCache = 0
          return 0
        end
      end
    end
  else
    local salonWear = self.TempBeautyData
    if salonWear and #salonWear > 0 then
      for k, v in ipairs(salonWear) do
        if v.SalonId > 0 and v.SalonType == typeEnum then
          return v.SalonId
        end
      end
    end
  end
  return 0
end

function AppearanceModuleData:SetInitialSuitBottomCache(gender, suitId)
  if not self.InitialSuitBottomCache then
    self.InitialSuitBottomCache = {}
  end
  self.InitialSuitBottomCache[gender] = suitId
end

function AppearanceModuleData:GetInitialSuitBottomCache(gender)
  if not self.InitialSuitBottomCache then
    return nil
  end
  return self.InitialSuitBottomCache[gender]
end

function AppearanceModuleData:GetInitialSuitIdByFashionId(fashionId, gender)
  local belongSuitId = self.fashionIdToSuitIdMap[fashionId]
  if not belongSuitId or 0 == belongSuitId then
    return nil
  end
  local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, gender)
  if initSuitIds then
    for _, id in ipairs(initSuitIds) do
      if id == belongSuitId then
        return belongSuitId
      end
    end
  end
  return nil
end

function AppearanceModuleData:GetInitialSuitIconByCurBottom(displayedSuitId)
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local gender = player.gender
  local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, gender)
  if not initSuitIds then
    return nil
  end
  local initSuitIdSet = {}
  for _, id in ipairs(initSuitIds) do
    initSuitIdSet[id] = true
  end
  if not initSuitIdSet[displayedSuitId] then
    return nil
  end
  if self.TempAppearData then
    for _, wearItem in ipairs(self.TempAppearData) do
      if wearItem.FashionId > 0 then
        local wearItemConf = _G.DataConfigManager:GetFashionItemConf(wearItem.FashionId, true)
        if wearItemConf and wearItemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS then
          local wearBelongSuitId = self.fashionIdToSuitIdMap[wearItem.FashionId]
          if wearBelongSuitId and initSuitIdSet[wearBelongSuitId] and wearBelongSuitId ~= displayedSuitId then
            local suitConf = _G.DataConfigManager:GetFashionSuitsConf(wearBelongSuitId, true)
            if suitConf then
              return suitConf.suits_icon
            end
          end
          break
        end
      end
    end
  end
  return nil
end

function AppearanceModuleData:SetSuitWearComponent(suitId, bFashion, componentId)
  if not suitId then
    return
  end
  if not self.SuitComponentData[suitId] then
    self.SuitComponentData[suitId] = {}
  end
  table.insert(self.SuitComponentData[suitId], {bFashion = bFashion, id = componentId})
end

function AppearanceModuleData:RemoveWearComponentFromSuit(suitId, bFashion, componentId)
  if not suitId or not self.SuitComponentData[suitId] then
    return
  end
  local index = 0
  for k, v in ipairs(self.SuitComponentData[suitId]) do
    if v.id == componentId and v.bFashion == bFashion then
      index = k
      break
    end
  end
  if 0 ~= index then
    table.remove(self.SuitComponentData[suitId], index)
  end
end

function AppearanceModuleData:LoadFashionMallPopUpRecord()
  self.FashionMallPopUpRecord = JsonUtils.LoadSaved(_FashionMallPopUpRecordFileName, {}) or {}
end

function AppearanceModuleData:SaveFashionMallPopUpRecord()
  return JsonUtils.DumpSaved(_FashionMallPopUpRecordFileName, self.FashionMallPopUpRecord)
end

function AppearanceModuleData:_InitSuitComponentData(fashionData)
  if not fashionData then
    return
  end
  local suitsInfos = fashionData.suit_info
  if suitsInfos and #suitsInfos > 0 then
    for k, v in pairs(suitsInfos) do
      if not self.SuitComponentData[v.suit_id] then
        self.SuitComponentData[v.suit_id] = {}
      end
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v.suit_id)
      if suitConf and v.components_is_worn then
        for k1, v1 in pairs(v.components_is_worn) do
          v1 = v1 + 1
          if suitConf.lv_up_closet and #suitConf.lv_up_closet > 0 and suitConf.lv_up_closet[v1] then
            local lvItemType = suitConf.lv_up_closet[v1].lv_item_type
            if lvItemType ~= _G.Enum.GoodsType.GT_FASHION_SUITS then
              local bFashion = lvItemType == _G.Enum.GoodsType.GT_FASHION
              local id = suitConf.lv_up_closet[v1].lv_item_id
              table.insert(self.SuitComponentData[v.suit_id], {bFashion = bFashion, id = id})
            end
          end
        end
      end
    end
  end
end

function AppearanceModuleData:BuildPackageToAllSuitMap()
  local fashionSuitTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_SUITS_CONF)
  if not fashionSuitTable then
    return
  end
  local allFashionSuitData = fashionSuitTable:GetAllDatas()
  if not allFashionSuitData then
    return
  end
  for key, data in pairs(allFashionSuitData) do
    local packageId = data and data.package_id
    if nil ~= packageId and 0 ~= packageId then
      if nil == self.AllSuitInPackage[packageId] then
        self.AllSuitInPackage[packageId] = {}
      end
      table.insert(self.AllSuitInPackage[packageId], key)
    end
  end
end

function AppearanceModuleData:BuildSuitIdToExchangeGoodsMap(exchangeShopId)
  exchangeShopId = exchangeShopId or 8070
  self.suitIdToExchangeGoodsMap = {}
  self.suitIdToExchangeVoucherMap = {}
  local shopConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NORMAL_SHOP_CONF)
  if not shopConfTable then
    Log.Warning("AppearanceModuleData:BuildSuitIdToExchangeGoodsMap NORMAL_SHOP_CONF not found")
    return
  end
  local allShopConf = shopConfTable:GetAllDatas()
  if not allShopConf then
    return
  end
  for goodsId, goodsConf in pairs(allShopConf) do
    if goodsConf.shop_id == exchangeShopId and goodsConf.enable and goodsConf.Type == _G.Enum.GoodsType.GT_REWARD then
      local rewardConf = _G.DataConfigManager:GetRewardConf(goodsConf.item_id)
      if rewardConf and rewardConf.RewardItem then
        for _, rewardItem in ipairs(rewardConf.RewardItem) do
          if rewardItem.Type == _G.Enum.GoodsType.GT_BAGITEM then
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewardItem.Id)
            if bagItemConf and bagItemConf.item_behavior and #bagItemConf.item_behavior > 0 then
              local behavior = bagItemConf.item_behavior[1]
              if behavior and behavior.use_action == _G.Enum.ItemBehavior.IB_GET_AWARD and behavior.ratio and #behavior.ratio > 0 then
                local suitRewardId = behavior.ratio[1]
                local suitRewardConf = _G.DataConfigManager:GetRewardConf(suitRewardId)
                if suitRewardConf and suitRewardConf.RewardItem then
                  for _, suitRewardItem in ipairs(suitRewardConf.RewardItem) do
                    if suitRewardItem.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
                      self.suitIdToExchangeGoodsMap[suitRewardItem.Id] = goodsId
                      self.suitIdToExchangeVoucherMap[suitRewardItem.Id] = rewardItem.Id
                      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitRewardItem.Id)
                      if suitConf and suitConf.package_id and 0 ~= suitConf.package_id then
                        if not self.goodsIdToPackageIdMap[goodsId] then
                          self.goodsIdToPackageIdMap[goodsId] = {}
                        end
                        table.insert(self.goodsIdToPackageIdMap[goodsId], suitConf.package_id)
                      end
                      Log.Info(string.format("AppearanceModuleData:BuildSuitIdToExchangeGoodsMap suitId=%d -> goodsId=%d, voucherId=%d", suitRewardItem.Id, goodsId, rewardItem.Id))
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

function AppearanceModuleData:GetExchangeGoodsIdBySuitId(suitId)
  return self.suitIdToExchangeGoodsMap and self.suitIdToExchangeGoodsMap[suitId]
end

function AppearanceModuleData:GetExchangeVoucherIdBySuitId(suitId)
  return self.suitIdToExchangeVoucherMap and self.suitIdToExchangeVoucherMap[suitId]
end

function AppearanceModuleData:GetSuitIdByExchangeVoucherId(voucherId)
  if not self.suitIdToExchangeVoucherMap then
    return nil
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    for suitId, vId in pairs(self.suitIdToExchangeVoucherMap) do
      if vId == voucherId then
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
        if suitConf and suitConf.gender == player.gender then
          return suitId
        end
      end
    end
  end
  return nil
end

function AppearanceModuleData:GetPackageIdByGoodsId(goodsId)
  if not self.goodsIdToPackageIdMap then
    return nil
  end
  local value = self.goodsIdToPackageIdMap[goodsId]
  if not value then
    return nil
  end
  if type(value) == "number" then
    return value
  end
  if type(value) == "table" then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      for _, pkgId in ipairs(value) do
        local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId)
        if fashionPackageConf and fashionPackageConf.gender == player.gender then
          return pkgId
        end
      end
    end
    return value[1]
  end
  return nil
end

function AppearanceModuleData:RemoveConflictFashionItem(newFashionType, tag)
  local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
  if newFashionType == _G.Enum.FashionLabelType.FLT_TOPS or newFashionType == _G.Enum.FashionLabelType.FLT_BOTTOMS then
    for i = 1, #self.TempAppearData do
      if self.TempAppearData[i].FashionType == Enum.FashionLabelType.FLT_DRESSES then
        table.remove(self.TempAppearData, i)
        break
      end
    end
  elseif newFashionType == _G.Enum.FashionLabelType.FLT_DRESSES then
    for i = #self.TempAppearData, 1, -1 do
      if self.TempAppearData[i].FashionType == Enum.FashionLabelType.FLT_TOPS or self.TempAppearData[i].FashionType == Enum.FashionLabelType.FLT_BOTTOMS then
        table.remove(self.TempAppearData, i)
      end
    end
  end
  local newFashionId
  for i = 1, #self.TempAppearData do
    if self.TempAppearData[i].FashionType == newFashionType then
      newFashionId = self.TempAppearData[i].FashionId
      break
    end
  end
  if newFashionId then
    local newAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(newFashionId)
    if newAvatarEnum then
      local conflictBodyTypes = AppearanceUtils.GetConflictBodyTypes(newAvatarEnum)
      if conflictBodyTypes and #conflictBodyTypes > 0 then
        for i = #self.TempAppearData, 1, -1 do
          local data = self.TempAppearData[i]
          if data.FashionId ~= newFashionId then
            local existAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(data.FashionId)
            if existAvatarEnum then
              for _, conflictType in ipairs(conflictBodyTypes) do
                if existAvatarEnum == conflictType then
                  table.remove(self.TempAppearData, i)
                  break
                end
              end
            end
          end
        end
      end
    end
  end
  local newTagMap = AppearanceUtils.BuildTagMapFromAppearData(newFashionType, tag)
  if not next(newTagMap) then
    return
  end
  local conflictEntries = AppearanceUtils.GetConflictingTagEntries(newTagMap)
  if 0 == #conflictEntries then
    return
  end
  local conflictLookup = {}
  for _, entry in ipairs(conflictEntries) do
    local key = tostring(entry.fashionType) .. "_" .. tostring(entry.tagValue)
    conflictLookup[key] = entry.field
  end
  for i = #self.TempAppearData, 1, -1 do
    local data = self.TempAppearData[i]
    if data.tag then
      local existTagMap = AppearanceUtils.BuildTagMapFromAppearData(data.FashionType, data.tag)
      for field, tagVal in pairs(existTagMap) do
        local fType = AppearanceUtils.TagFieldToFashionType[field]
        if fType then
          local key = tostring(fType) .. "_" .. tostring(tagVal)
          if conflictLookup[key] then
            table.remove(self.TempAppearData, i)
            break
          end
        end
      end
    end
  end
end

return AppearanceModuleData
