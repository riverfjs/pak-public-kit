local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

local function OnSvrRspHandle(_rspWrapper, _protoData)
  if _rspWrapper and _rspWrapper.handler then
    _rspWrapper.handler(_protoData, _rspWrapper.reqMsg, _rspWrapper.customData)
  end
end

local ActivityUtils = {}
local TimezoneOffset = -1

function ActivityUtils.RemoveElements(_arrayData, _conditionFun, _conditionFunThis, ...)
  local removeFlag = false
  local conditionFunctor = _G.MakeWeakFunctor(_conditionFunThis, _conditionFun)
  if _arrayData and conditionFunctor then
    local index = #_arrayData
    while index > 0 do
      if conditionFunctor(_arrayData[index], ...) then
        table.remove(_arrayData, index)
        removeFlag = true
      end
      index = index - 1
    end
  end
  return removeFlag
end

function ActivityUtils.ShallowCopyElements(_arrayData)
  if _arrayData then
    local clone = {}
    for _, _value in ipairs(_arrayData) do
      table.insert(clone, _value)
    end
    return clone
  end
end

function ActivityUtils.GetActivityGlobalConfig(key)
  return _G.DataConfigManager:GetActivityGlobalConfig(key)
end

function ActivityUtils.OpenUrl(url, screen_type, useRawUrl)
  local isEncodeUrl = not useRawUrl
  if isEncodeUrl and _G.OnlineModuleCmd then
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel == Enum.CliLoginChannel.CLC_NONE then
      isEncodeUrl = false
    end
  end
  if not RocoEnv.IS_SHIPPING then
    Log.Error("[DEV] OpenUrl", url, screen_type, isEncodeUrl)
  end
  if isEncodeUrl and url:find("?") ~= nil then
    url = UE4.UWebViewStatics.GetEncodeURL(url)
  end
  local extraJson = ""
  if not screen_type then
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
      extraJson = "{\"isEmbedWebView\":true, \"withDialog\":true}"
      screen_type = 2
    else
      extraJson = "{\"isEmbedWebView\":true,\"webview_window_scale\":0.7,\"withDialog\":true}"
      screen_type = 1
    end
  end
  UE4.UWebViewStatics.OpenURL(url, screen_type, false, isEncodeUrl, extraJson, false)
end

function ActivityUtils.CreateActivityActivateParameter()
  local activateParameter = {}
  activateParameter.serverTime = ActivityUtils.GetSvrTimestamp()
  activateParameter.playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  activateParameter.magicianLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  return activateParameter
end

function ActivityUtils.GetSvrTimestamp()
  local serverTime = _G.ZoneServer:GetServerTime() or 0
  return math.floor(serverTime / 1000)
end

function ActivityUtils.ToTimestamp(_dateTimeStr)
  if not string.IsNilOrEmpty(_dateTimeStr) then
    local dateTime, success = UE4.UKismetMathLibrary.DateTimeFromString(_dateTimeStr)
    if success and dateTime then
      return UE4.UNRCStatics.ToTimestamp(dateTime) - 28800
    end
  end
  return 0
end

function ActivityUtils.GetTodayTimestamp(timeStr)
  if not timeStr or "" == timeStr then
    return 0
  end
  local hour, minute, second = string.match(timeStr, "^(%d%d):(%d%d):(%d%d)$")
  if not hour then
    hour, minute = string.match(timeStr, "^(%d%d):(%d%d)$")
    second = "00"
  end
  if not hour or not minute then
    Log.Error("GetCorrectTimestamp: \230\151\182\233\151\180\230\160\188\229\188\143\233\148\153\232\175\175:", timeStr)
    return 0
  end
  local hourNum = tonumber(hour)
  local minuteNum = tonumber(minute)
  local secondNum = tonumber(second)
  if hourNum < 0 or hourNum > 23 or minuteNum < 0 or minuteNum > 59 or secondNum < 0 or secondNum > 59 then
    Log.Error("GetCorrectTimestamp: \230\151\182\233\151\180\232\140\131\229\155\180\233\148\153\232\175\175:", timeStr)
    return 0
  end
  local serverTime = _G.ZoneServer:GetServerTime() / 1000
  local todayStartTime = serverTime - serverTime % 86400
  return todayStartTime + hourNum * 3600 + minuteNum * 60 + secondNum
end

function ActivityUtils.ToTimestampByDays(_dateTimeStr, ContinuousDays)
  if not string.IsNilOrEmpty(_dateTimeStr) and not string.IsNilOrEmpty(ContinuousDays) then
    local timeStamp = ActivityUtils.ToTimestamp(_dateTimeStr)
    local TimeData = string.split(ContinuousDays, " ")
    if TimeData and #TimeData > 0 then
      local Days = tonumber(TimeData[1])
      local HourTimeStr = TimeData[2]
      local Hours = string.split(HourTimeStr, ":")
      if Hours and #Hours > 0 then
        local Hour = tonumber(Hours[1])
        local Minute = tonumber(Hours[2])
        local Second = tonumber(Hours[3])
        timeStamp = timeStamp + Hour * 3600 + Minute * 60 + Second + Days * 24 * 3600
      end
    end
    return timeStamp
  end
  return 0
end

function ActivityUtils.ToTimeDetailData(_timestamp)
  if TimezoneOffset < 0 then
    local now = UE4.UNRCStatics.GetTimestampMS()
    local utcNow = UE4.UNRCStatics.GetUTCTimestampMS()
    TimezoneOffset = math.floor((now - utcNow) / 1000)
  end
  local dateTime = UE4.UNRCStatics.FromTimestamp((_timestamp or 0) + TimezoneOffset)
  local ret = {}
  ret.year, ret.month, ret.day, ret.hour, ret.minute, ret.second, ret.millisecond = UE4.UKismetMathLibrary.BreakDateTime(dateTime)
  return ret
end

function ActivityUtils.GetTimeFormatStr(_seconds)
  if _seconds > 0 then
    local day = _seconds // 86400
    local hour = (_seconds - 86400 * day) // 3600
    local minute = (_seconds - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      return string.format(_G.LuaText.activity_RTS1, day, hour)
    elseif hour > 0 or minute > 0 then
      return string.format(_G.LuaText.activity_RTS2, hour, minute)
    else
      return _G.LuaText.activity_RTS3
    end
  else
    return _G.LuaText.activity_expired_show_tip
  end
end

function ActivityUtils.CheckGoodsItemGenderMatch(_itemType, _itemId)
  local requireGender
  if _itemType == Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(_itemId, true)
    if fashionItemConf then
      requireGender = fashionItemConf.gender
    end
  elseif _itemType == Enum.GoodsType.GT_SALON then
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(_itemId, true)
    if salonItemConf then
      requireGender = salonItemConf.gender
    end
  elseif _itemType == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionSuitsConf = _G.DataConfigManager:GetFashionSuitsConf(_itemId, true)
    if fashionSuitsConf then
      requireGender = fashionSuitsConf.gender
    end
  end
  if requireGender then
    local isMale = _G.DataModelMgr.PlayerDataModel:IsMale()
    if requireGender == Enum.ESexValue.SEX_MALE then
      return isMale
    elseif requireGender == Enum.ESexValue.SEX_FEMALE then
      return not isMale
    end
  end
  return true
end

function ActivityUtils.GetItemIconAndQuality(itemType, itemId, useBigIcon)
  local itemIcon = ""
  local itemQuality = 0
  local itemName = ""
  if itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(itemId)
    if vItemsConf then
      itemIcon = _G.NRCUtils:FormatConfIconPath(useBigIcon and vItemsConf.bigIcon or vItemsConf.iconPath, _G.UIIconPath.BagItemPath)
      itemQuality = vItemsConf.item_quality
      itemName = vItemsConf.displayName
    end
  elseif itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
    if bagItemConf then
      itemIcon = _G.NRCUtils:FormatConfIconPath(useBigIcon and bagItemConf.big_icon or bagItemConf.icon, _G.UIIconPath.BagItemPath)
      itemQuality = bagItemConf.item_quality
      itemName = bagItemConf.name
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemId)
    if cardSkinConf then
      itemIcon = string.format(_G.UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      itemQuality = cardSkinConf.card_quality
      itemName = cardSkinConf.skin_resource_name
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(itemId)
    if cardIconConf then
      itemIcon = string.format("%s%s.%s'", _G.UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
      itemQuality = cardIconConf.card_quality
      itemName = cardIconConf.icon_resource_name
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local cardLabelConf = _G.DataConfigManager:GetCardLabelConf(itemId)
    if cardLabelConf then
      itemIcon = cardLabelConf.label_icon or _G.UEPath.CARD_LABEL_PATH
      itemQuality = cardLabelConf.card_quality
      itemName = cardLabelConf.label_name
    end
  elseif itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if fashionConf then
      itemIcon = useBigIcon and fashionConf.suits_icon_big or fashionConf.suits_icon
      itemQuality = fashionConf.suit_grade
      itemName = fashionConf.name
    end
  elseif itemType == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionItemConf then
      itemIcon = fashionItemConf.icon
      itemQuality = fashionItemConf.item_quality
      itemName = fashionItemConf.name
    end
  elseif itemType == _G.Enum.GoodsType.GT_SALON then
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if salonItemConf then
      itemIcon = salonItemConf.icon
      itemQuality = salonItemConf.item_quality
      itemName = salonItemConf.name
    end
  elseif itemType == _G.Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(itemId)
    if ChatEmojiConf then
      itemIcon = ChatEmojiConf.emoji_goods_icon
      itemQuality = ChatEmojiConf.card_quality
      itemName = ChatEmojiConf.emoji_resource_name
    end
  end
  return itemIcon, itemQuality, itemName
end

function ActivityUtils.GetActivityRewardData(_rewardId, _parseReward, _useBigIcon)
  local activityRewardData = {}
  activityRewardData.rewardId = _rewardId or 0
  activityRewardData.itemType = 0
  activityRewardData.itemId = 0
  activityRewardData.itemNum = 0
  activityRewardData.itemQuality = 0
  activityRewardData.itemName = ""
  local rewardConf = _rewardId and _G.DataConfigManager:GetRewardConf(_rewardId)
  if rewardConf then
    local rewardItemUseToShow
    if #rewardConf.RewardItem > 1 then
      if string.IsNilOrEmpty(rewardConf.Icon) then
        rewardItemUseToShow = rewardConf.RewardItem[1]
      end
      for _, rewardItem in ipairs(rewardConf.RewardItem) do
        if ActivityUtils.CheckGoodsItemGenderMatch(rewardItem.Type, rewardItem.Id) then
          rewardItemUseToShow = rewardItem
          break
        end
      end
    else
      rewardItemUseToShow = rewardConf.RewardItem[1]
    end
    if rewardItemUseToShow then
      activityRewardData.itemType = rewardItemUseToShow.Type
      activityRewardData.itemId = rewardItemUseToShow.Id
      activityRewardData.itemNum = rewardItemUseToShow.Count
      if _parseReward then
        activityRewardData.showIcon, activityRewardData.itemQuality, activityRewardData.itemName = ActivityUtils.GetItemIconAndQuality(rewardItemUseToShow.Type, rewardItemUseToShow.Id, _useBigIcon)
      end
    else
      activityRewardData.itemType = Enum.GoodsType.GT_REWARD
      activityRewardData.itemId = _rewardId
      activityRewardData.itemNum = 1
      activityRewardData.itemQuality = 0
      activityRewardData.showIcon = rewardConf.Icon
      local rewardItem = rewardConf.RewardItem[1]
      if rewardItem then
        activityRewardData.showIcon, activityRewardData.itemQuality, activityRewardData.itemName = ActivityUtils.GetItemIconAndQuality(rewardItem.Type, rewardItem.Id, _useBigIcon)
      end
    end
    if not string.IsNilOrEmpty(rewardConf.Icon) then
      activityRewardData.showIcon = rewardConf.Icon
    end
  end
  return activityRewardData
end

function ActivityUtils.ParseActivityRewardData(itemType, itemId, itemNum, useBigIcon)
  local activityRewardData = {}
  if itemType == _G.Enum.GoodsType.GT_REWARD then
    activityRewardData = ActivityUtils.GetActivityRewardData(itemId, true, useBigIcon)
    if itemNum and itemNum > 1 then
      activityRewardData.itemNum = activityRewardData.itemNum * itemNum
    end
  else
    activityRewardData.rewardId = 0
    activityRewardData.itemType = itemType or 0
    activityRewardData.itemId = itemId or 0
    activityRewardData.itemNum = itemNum or 0
    activityRewardData.showIcon, activityRewardData.itemQuality, activityRewardData.itemName = ActivityUtils.GetItemIconAndQuality(itemType, itemId, useBigIcon)
  end
  return activityRewardData
end

function ActivityUtils.ShowRewardTips(_rewardId)
  if not _rewardId or 0 == _rewardId then
    return
  end
  local activityRewardData = ActivityUtils.GetActivityRewardData(_rewardId, false)
  if activityRewardData then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, activityRewardData.itemId, activityRewardData.itemType)
  end
end

function ActivityUtils.ShowRewardPreview(_rewardId)
  if not _rewardId or 0 == _rewardId then
    return
  end
  local rewardItems = {}
  local rewardCfg = _G.DataConfigManager:GetRewardConf(_rewardId)
  if rewardCfg then
    for _, rewardItem in ipairs(rewardCfg.RewardItem) do
      local item = {}
      item.itemType = rewardItem.Type
      item.itemId = rewardItem.Id
      item.itemNum = rewardItem.Count
      item.bShowNum = true
      item.bShowTip = true
      table.insert(rewardItems, item)
    end
  end
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenCommonRewardPreviewPanel, rewardItems)
end

function ActivityUtils.ShowRewardChoose(retInfo, bDontShow)
  if not retInfo or not retInfo.goods_change_info then
    return false
  end
  for _, changeItem in ipairs(retInfo.goods_change_info.changes or {}) do
    if changeItem.bag_item and changeItem.type == _G.Enum.GoodsType.GT_BAGITEM then
      local bagItemCfg = _G.DataConfigManager:GetBagItemConf(changeItem.id)
      local useAction = bagItemCfg and bagItemCfg.item_behavior and bagItemCfg.item_behavior[1] and bagItemCfg.item_behavior[1].use_action
      if useAction == _G.Enum.ItemBehavior.IB_CHOOSE_ITEMS then
        if not bDontShow then
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenChooseItemPanel, changeItem.bag_item, bagItemCfg.item_behavior[1].ratio)
        end
        return true
      end
    end
  end
  return false
end

function ActivityUtils.ShowRewardGetTips(_rewardId, _retInfo)
  local rewardsList = {}
  local retRewards = _retInfo and _retInfo.goods_reward and _retInfo.goods_reward.rewards
  if retRewards and #retRewards > 0 then
    for _, reward in ipairs(retRewards) do
      local rewardsItemData = {}
      rewardsItemData.type = reward.type
      rewardsItemData.id = reward.id
      rewardsItemData.num = reward.num
      table.insert(rewardsList, rewardsItemData)
    end
  elseif _rewardId and 0 ~= _rewardId then
    local rewardConf = _G.DataConfigManager:GetRewardConf(_rewardId)
    if rewardConf then
      for _, rewardItem in ipairs(rewardConf.RewardItem) do
        if ActivityUtils.CheckGoodsItemGenderMatch(rewardItem.Type, rewardItem.Id) then
          local rewardsItemData = {}
          rewardsItemData.type = rewardItem.Type
          rewardsItemData.id = rewardItem.Id
          rewardsItemData.num = rewardItem.Count
          table.insert(rewardsList, rewardsItemData)
        end
      end
    end
  end
  if #rewardsList > 0 then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardsList, "")
  end
end

function ActivityUtils.SetRewardItemQuality(_qualityCtrl, _itemQuality)
  if not _qualityCtrl then
    return
  end
  if 0 == _itemQuality then
  elseif 1 == _itemQuality then
    _qualityCtrl:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(_G.UEPath.Color_QUALITY_1))
  elseif 2 == _itemQuality then
    _qualityCtrl:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(_G.UEPath.Color_QUALITY_2))
  elseif 3 == _itemQuality then
    _qualityCtrl:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(_G.UEPath.Color_QUALITY_3))
  elseif 4 == _itemQuality then
    _qualityCtrl:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(_G.UEPath.Color_QUALITY_4))
  elseif 5 == _itemQuality then
    _qualityCtrl:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(_G.UEPath.Color_QUALITY_5))
  end
end

function ActivityUtils.ShowActivityExpiredTips()
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
end

function ActivityUtils.SendMsgToSvr(_reqCmd, _reqMsg, _rspCaller, _rspHandler, _customData)
  if _rspHandler then
    local rspWrapper = {}
    rspWrapper.handler = _G.MakeWeakFunctor(_rspCaller, _rspHandler)
    rspWrapper.reqMsg = _reqMsg
    rspWrapper.customData = _customData
    return _G.ZoneServer:SendWithHandler(_reqCmd, _reqMsg, rspWrapper, OnSvrRspHandle, true)
  else
    return _G.ZoneServer:Send(_reqCmd, _reqMsg)
  end
end

function ActivityUtils.DispatchEvent(eventName, ...)
  local ActivityModule = NRCModuleManager:GetModule("ActivityModule")
  if ActivityModule then
    ActivityModule:DispatchEvent(eventName, ...)
  end
end

function ActivityUtils.CreatePetDetailPanelShowData(petBaseId, includeEvolutions, mutationType)
  if petBaseId and 0 ~= petBaseId then
    local showData = {}
    showData.petBaseId = petBaseId
    showData.petList = {}
    local petBaseData = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if includeEvolutions and petBaseData then
      local petEvoID = tonumber(petBaseData.pet_evolution_id[1])
      if petEvoID then
        local petEvoConf = _G.DataConfigManager:GetPetEvolutionConf(petEvoID)
        if petEvoConf then
          for _, v in pairs(petEvoConf.evolution_chain) do
            table.insert(showData.petList, {
              base_conf_id = v.petbase_id,
              mutation_type = mutationType
            })
          end
        end
      end
    end
    if #showData.petList <= 0 then
      table.insert(showData.petList, {base_conf_id = petBaseId, mutation_type = mutationType})
    end
    local skillConf = _G.DataConfigManager:GetLevelSkillConf(petBaseData and petBaseData.level_skill_id or petBaseId)
    if skillConf then
      showData.skills = {}
      for _, val in pairs(skillConf.level) do
        table.insert(showData.skills, val.param)
      end
    end
    return showData
  end
end

function ActivityUtils.CreateActivityItemBaseDataForList(_parentView, _rawDataList)
  if not _rawDataList then
    return {}
  end
  if not _parentView then
    Log.ErrorFormat("must set valid parent view!!")
    return {}
  end
  local itemDataList = {}
  for _, _rawDataItem in ipairs(_rawDataList) do
    local itemData = {}
    itemData.parent = _parentView
    itemData.customData = _rawDataItem
    table.insert(itemDataList, itemData)
  end
  return itemDataList
end

function ActivityUtils.GetTabRedPoint(mainTabId)
  local tabRedPointIds = {
    301,
    302,
    303
  }
  if mainTabId > 0 and mainTabId <= #tabRedPointIds then
    return tabRedPointIds[mainTabId]
  end
  Log.ErrorFormat("\229\136\134\233\161\181[%d]\231\188\186\229\176\145\229\175\185\229\186\148\231\154\132\233\161\181\231\173\190\230\160\143\231\186\162\231\130\185\233\133\141\231\189\174!", mainTabId)
end

function ActivityUtils.AdjustCtrlSize(ctrl, sizeConf, elementCnt)
  if not (ctrl and sizeConf) or not elementCnt then
    return
  end
  local ctrlDesiredWidth
  if elementCnt > 0 and elementCnt <= #sizeConf then
    ctrlDesiredWidth = sizeConf[elementCnt]
  elseif elementCnt > #sizeConf then
    ctrlDesiredWidth = sizeConf[#sizeConf]
  end
  if ctrlDesiredWidth then
    local ctrlSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(ctrl)
    if ctrlSlot then
      local ctrlSize = ctrlSlot:GetSize()
      ctrlSize.X = ctrlDesiredWidth
      ctrlSlot:SetSize(ctrlSize)
    end
  end
end

function ActivityUtils.AdjustCtrlAutoSize(ctrl, autoSize, desiredWidth, desiredHeight)
  if not ctrl then
    return
  end
  local ctrlSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(ctrl)
  if ctrlSlot then
    if autoSize then
      ctrlSlot:SetAutoSize(true)
    else
      ctrlSlot:SetAutoSize(false)
      if desiredWidth or desiredHeight then
        local ctrlSize = ctrlSlot:GetSize()
        if desiredWidth then
          ctrlSize.X = desiredWidth
        end
        if desiredHeight then
          ctrlSize.Y = desiredHeight
        end
        ctrlSlot:SetSize(ctrlSize)
      end
    end
  end
end

function ActivityUtils.GetPlayerSelectSpecFlowerSeedDataById(flowerSeedId)
  local retSeedData = {}
  local level = 0
  local seedConf = _G.DataConfigManager:GetActivitySpecFlowerSeedConf(flowerSeedId)
  if seedConf then
    retSeedData.seedConf = seedConf
    if seedConf.enum_pet_evo == Enum.SpecFlowerSeedPetId.SFSPI_PET_BASE_ID then
      retSeedData.petBaseId = seedConf.pet_evo_param
    else
      local petEvolutionConf = _G.DataConfigManager:GetPetEvolutionConf(seedConf.pet_evo_param)
      if petEvolutionConf then
        local seedStar = 0
        if seedConf.enum_star == Enum.SpecFlowerSeedStar.SFSS_FIXED_STAR then
          seedStar = seedConf.star_param
        else
          seedStar = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() + 1
        end
        local petLevel = seedConf.activity_team_battle_star_level[seedStar] or 0
        for _, _evolutionChain in ipairs(petEvolutionConf.evolution_chain) do
          if petLevel < _evolutionChain.level then
            break
          end
          retSeedData.petBaseId = _evolutionChain.petbase_id
        end
        level = petLevel
      end
    end
  end
  return retSeedData, level
end

function ActivityUtils.GetPetBloodIdByShinyWeekendConf(_shinyWeekEndConf)
  if not _shinyWeekEndConf then
    return
  end
  return ActivityUtils.GetPetBloodIdBySeedId(_shinyWeekEndConf.seed_id)
end

function ActivityUtils.GetPetBloodIdBySeedId(seedId)
  local seedConf = seedId and _G.DataConfigManager:GetActivitySpecFlowerSeedConf(seedId)
  if not seedConf then
    return
  end
  local npcRefreshGroup = _G.DataConfigManager:GetNpcRefreshGroupConf(seedConf.refresh_group_id)
  if not npcRefreshGroup then
    return
  end
  local npcRefreshContent = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshGroup.content_id[1])
  if not npcRefreshContent then
    return
  end
  local petGlobalConf = _G.DataConfigManager:GetPetGlobalConfig("team_battle_npc_blood_" .. npcRefreshContent.npc_id)
  return petGlobalConf and petGlobalConf.numList and petGlobalConf.numList[2]
end

function ActivityUtils.GetPetNatureIdBySeedId(seedId)
  local seedConf = seedId and _G.DataConfigManager:GetActivitySpecFlowerSeedConf(seedId)
  if seedConf then
    local petInfoConf = _G.DataConfigManager:GetPetInfoConf(seedConf.pet_info_id)
    local natureIds = petInfoConf and petInfoConf.nature_id
    if natureIds and #natureIds > 0 then
      return natureIds[1]
    end
  end
end

function ActivityUtils.ShowPetNatureTips(natureId, petBaseId)
  if not natureId then
    return
  end
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpendblockerTips, {base_conf_id = petBaseId, natrueId = natureId}, _G.Enum.GoodsType.GT_PET)
end

function ActivityUtils.CreatePetCommonAttrListData(unitTypes, bloodId, bloodFirst, petData)
  local petAttrTable = {}
  if unitTypes then
    for _, _type in ipairs(unitTypes) do
      local typeInfo = _G.DataConfigManager:GetTypeDictionary(_type)
      if typeInfo then
        local petAttr = {}
        petAttr.Name = typeInfo.short_name
        petAttr.Path = typeInfo.type_icon
        petAttr.petData = petData
        petAttr.ShowTips = nil ~= petData
        table.insert(petAttrTable, petAttr)
      end
    end
  end
  if bloodId and 0 ~= bloodId then
    local bloodConf = _G.DataConfigManager:GetPetBloodConf(bloodId)
    if bloodConf then
      local petAttr = {}
      petAttr.Name = bloodConf.blood_name
      petAttr.Path = bloodConf.icon
      petAttr.petData = petData
      petAttr.IsBlood = true
      petAttr.ShowTips = nil ~= petData
      if petData then
        petData.blood_id = bloodId
      end
      if bloodFirst then
        table.insert(petAttrTable, 1, petAttr)
      else
        table.insert(petAttrTable, petAttr)
      end
    end
  end
  return petAttrTable
end

function ActivityUtils.SendTLogActivityAction(activityId, baseId, actionType, actionFlag)
  if not (activityId and baseId and actionType) or string.IsNilOrEmpty(actionFlag) then
    return
  end
  local lastChar = actionFlag:sub(-1)
  if "0" ~= lastChar and "1" ~= lastChar then
    Log.ErrorFormat("SendTLogActivityAction failed! activityId=%d, baseId=%d, actionType=%d, actionFlag=%s", activityId, baseId, actionType, actionFlag)
    return
  end
  local key = "ActivityAction"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local actionIdStr = string.format("%d%d%s", activityId, baseId, actionFlag)
  local analysisFlag = tonumber(lastChar)
  local value = string.format("%s|%s|%d|%d|%d|%s|%d", key, roleDataStr, activityId, baseId, actionType, actionIdStr, analysisFlag)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function ActivityUtils.SendTLogActivityButtonAction(activityId, buttonId)
  if not activityId or not buttonId then
    return
  end
  local key = "ActivityButtonInteraction"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local value = string.format("%s|%s|%d|%d", key, roleDataStr, activityId, buttonId)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

ActivityUtils.SendTLogActivityInteractionHandles = {}
ActivityUtils.SendTLogActivityInteractionActions = {}
ActivityUtils.SendTLogActivityInteractionThreshold = 1

function ActivityUtils.SendTLogActivityInteraction(activityId, baseId, actionType, tabId, count)
  count = count or 1
  if not (activityId and baseId and actionType and tabId) or count <= 0 then
    return
  end
  local tabIdStr = tostring(tabId)
  local IdentifyKey = string.format("%d|%d|%d|%s", activityId, baseId, actionType, tabIdStr)
  if ActivityUtils.SendTLogActivityInteractionHandles[IdentifyKey] then
    ActivityUtils.SendTLogActivityInteractionActions[IdentifyKey] = (ActivityUtils.SendTLogActivityInteractionActions[IdentifyKey] or 0) + count
  else
    ActivityUtils.SendTLogActivityInteractionActions[IdentifyKey] = count
    ActivityUtils.SendTLogActivityInteractionHandles[IdentifyKey] = DelayManager:DelaySeconds(1, function()
      local BatchCount = ActivityUtils.SendTLogActivityInteractionActions[IdentifyKey]
      ActivityUtils.SendTLogActivityInteractionActions[IdentifyKey] = nil
      ActivityUtils.SendTLogActivityInteractionHandles[IdentifyKey] = nil
      ActivityUtils.InternalSendTLogActivityInteraction(IdentifyKey, BatchCount)
    end)
  end
end

function ActivityUtils.InternalSendTLogActivityInteraction(IdentifyKey, count)
  Log.Debug("SendTLogActivityInteraction batch", IdentifyKey, count)
  local key = "ActivityInteraction"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local value = string.format("%s|%s|%s|%d", key, roleDataStr, IdentifyKey, tostring(count))
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function ActivityUtils.GetNPCChallengeEventSchedule(conf)
  local MaxSchedule = 0
  local battle_Set = conf.battle_set
  local NpcChallengeConfList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_CHALLENGE_CONF):GetAllDatas()
  for i, battleId in pairs(battle_Set) do
    for j, NpcChallengeConf in pairs(NpcChallengeConfList) do
      if battleId == NpcChallengeConf.module_id then
        MaxSchedule = MaxSchedule + 1
      end
    end
  end
  return MaxSchedule
end

function ActivityUtils.GetBossChallengeEventSchedule(conf)
  local MaxSchedule = 0
  local battle_Set = conf.battle_set
  local NpcChallengeConfList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BOSS_CHALLENGE_CONF):GetAllDatas()
  for i, battleId in pairs(battle_Set) do
    for j, NpcChallengeConf in pairs(NpcChallengeConfList) do
      if battleId == NpcChallengeConf.id then
        MaxSchedule = MaxSchedule + 1
      end
    end
  end
  return MaxSchedule
end

function ActivityUtils.GetNPCChallengeEventStarNum(conf)
  local MaxStarNum = 0
  for i, star in ipairs(conf.star_reward) do
    if MaxStarNum < star.star_required then
      MaxStarNum = star.star_required
    end
  end
  return MaxStarNum
end

function ActivityUtils.GetFinishNPCChallengeEventSchedule(npc_challenge_data, _IsTargets)
  local FinishSchedule = 0
  if npc_challenge_data then
    local NpcChallengeData = npc_challenge_data
    for i, module in ipairs(NpcChallengeData.modules) do
      for j, level in ipairs(module.levels) do
        if _IsTargets and level.targets and #level.targets > 0 then
          for k, _ in ipairs(level.targets) do
            if _.is_finish then
              FinishSchedule = FinishSchedule + 1
            end
          end
        end
      end
    end
  end
  return FinishSchedule
end

function ActivityUtils.GetFinishBossChallengeEventSchedule(boss_challenge_data, _IsTargets)
  local FinishSchedule = 0
  if boss_challenge_data then
    local BossChallengeData = boss_challenge_data
    for i, level in ipairs(BossChallengeData.levels) do
      if _IsTargets and level.targets and #level.targets > 0 then
        for k, _ in ipairs(level.targets) do
          if _.is_finish then
            FinishSchedule = FinishSchedule + 1
          end
        end
      end
    end
  end
  return FinishSchedule
end

function ActivityUtils.RequestTracePet(petBaseIdList, activityInst)
  if not petBaseIdList or #petBaseIdList <= 0 then
    return
  end
  local trackNpcIds = table.new(#petBaseIdList, 0)
  for _, petBaseId in ipairs(petBaseIdList) do
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if petBaseConf and petBaseConf.pet_track_npc_id then
      for _, npcId in ipairs(petBaseConf.pet_track_npc_id) do
        table.insert(trackNpcIds, npcId)
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendZoneNpcTraceQueryReq, trackNpcIds)
  if activityInst then
    activityInst:AddActivityExpiredCallback("RequestTracePet", nil, function()
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendZoneNpcTraceQueryReq, trackNpcIds, true)
    end)
  end
end

function ActivityUtils.RequestTracePetWithContentIds(firstTrackContentIds, petBaseIdList, activityInst)
  if firstTrackContentIds and #firstTrackContentIds > 0 then
    _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendZoneSelectTrackContentsReq, firstTrackContentIds, petBaseIdList)
    if activityInst then
      activityInst:AddActivityExpiredCallback("RequestTracePetWithContentIds", nil, function()
        _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendZoneSelectTrackContentsReq, firstTrackContentIds, petBaseIdList, true)
      end)
    end
  else
    ActivityUtils.RequestTracePet(petBaseIdList, activityInst)
  end
end

function ActivityUtils.OpenWorldMap(worldMapId, failedTips, scaleValue)
  if not worldMapId or 0 == worldMapId then
    return
  end
  local worldMapConf = _G.DataConfigManager:GetWorldMapConf(worldMapId)
  if worldMapConf then
    ActivityUtils.OpenWorldMapByRefreshId(worldMapConf.npc_refresh_ids, failedTips, scaleValue)
  end
end

function ActivityUtils.OpenWorldMapByRefreshId(refreshIds, failedTips, scaleValue)
  local success = false
  if refreshIds then
    for _, refreshId in pairs(refreshIds) do
      local npcData = 0 ~= refreshId and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, refreshId)
      local ShouldShow = npcData and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OnCmdCheckShouldShowNpc, npcData)
      if npcData and (ShouldShow or npcData.worldMapConf and npcData.worldMapConf.is_hide_init) then
        local scaleSlider
        if scaleValue then
          if type(scaleValue) == "string" and not string.IsNilOrEmpty(scaleValue) then
            scaleSlider = tonumber(scaleValue)
          elseif type(scaleValue) == "number" then
            scaleSlider = scaleValue
          end
        end
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap, {scaleSliderValue = scaleSlider, centerNPCRefreshId = refreshId})
        success = true
        break
      end
    end
  end
  if not success then
    if not string.IsNilOrEmpty(failedTips) then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, failedTips)
    else
      Log.Info("ActivityUtils.OpenWorldMapByRefreshId failed! refreshIds=", refreshIds and table.concat(refreshIds, ",") or "nil")
    end
  end
end

function ActivityUtils.IsWorldMapTargetExist(worldMapId)
  if not worldMapId or 0 == worldMapId then
    return false
  end
  local worldMapConf = _G.DataConfigManager:GetWorldMapConf(worldMapId)
  if worldMapConf then
    return ActivityUtils.IsWorldMapTargetExistByRefreshId(worldMapConf.npc_refresh_ids)
  end
  return false
end

function ActivityUtils.IsWorldMapTargetExistByRefreshId(refreshIds)
  if refreshIds then
    for _, refreshId in pairs(refreshIds) do
      local npcData = 0 ~= refreshId and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, refreshId)
      if npcData then
        return true
      end
    end
  end
  return false
end

function ActivityUtils.OpenActivityRecommendTaskList(activityInst)
  if activityInst then
    local recommendTaskQuery = activityInst:GetRecommendTaskQueryHandler()
    if recommendTaskQuery and not recommendTaskQuery:CheckAllTaskDone() then
      local showTaskList = recommendTaskQuery:GetTaskListByStatus(ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN) or {}
      if #showTaskList <= 0 then
        local taskList = recommendTaskQuery:GetTaskList()
        if taskList and #taskList > 0 then
          table.insert(showTaskList, taskList[1])
        end
      end
      local data = {}
      data.title = _G.LuaText.activity_unfinished_task_tips_title
      data.desc = activityInst:GetRecommendTaskUnfinishedTips()
      if not activityInst:IsUnlockAdvance() then
        data.leftBtnText = _G.LuaText.activity_unfinished_task_tips_cancel
        data.rightBtnText = _G.LuaText.activity_unfinished_task_tips_continue
      end
      data.clickOkCallback = _G.MakeWeakFunctor(activityInst, activityInst.ReqActivityUnlockAdvance)
      data.taskStatusData = {}
      for _, taskId in ipairs(showTaskList) do
        data.taskStatusData[taskId] = recommendTaskQuery:GetTaskStatus(taskId)
      end
      _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenRecommendTaskPanel, showTaskList, data)
      return true
    end
  end
end

function ActivityUtils.SetTraceTask(taskId, failedTips)
  local taskObj = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.getTaskByID, taskId)
  if taskObj and taskObj.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.OnSetTraceTaskInfo, taskId, true)
    return true
  end
  if not string.IsNilOrEmpty(failedTips) then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, failedTips)
  end
end

function ActivityUtils.TraceTaskParagraph(taskId, openTaskPanel)
  local taskConf = taskId and _G.DataConfigManager:GetTaskConf(taskId, true)
  if taskConf then
    if openTaskPanel then
      _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.TraceParagraphOpenTaskPanel, taskConf.paragraph_id)
    else
      _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.TraceParagraphByID, taskConf.paragraph_id)
    end
  end
end

function ActivityUtils.GetActivityOptionData(id)
  local config = id and _G.DataConfigManager:GetActivityOptionConf(id, true)
  if not config then
    Log.Error("ActivityUtils.GetActivityOptionData: config not found! id=", id)
    return
  end
  return config.option_type, config.option_param1
end

function ActivityUtils.DoActivityOptionCmd(id)
  local config = id and _G.DataConfigManager:GetActivityOptionConf(id, true)
  if not config then
    Log.Error("ActivityUtils.DoActivityOptionCmd: config not found! id=", id)
    return
  end
  local optionType = config.option_type
  local param2 = config.option_param2
  local param3 = config.option_param3
  local param4 = config.option_param4
  local param5 = config.option_param5
  if optionType == Enum.ActivityOptionType.AOT_CMD then
    local function ParameterFormatter(_param)
      if not string.IsNilOrEmpty(_param) and string.find(_param, ";") then
        return string.split(_param, ";")
      end
      return _param
    end
    
    _G.NRCModuleManager:DoCmd(param2, ParameterFormatter(param3), ParameterFormatter(param4))
  elseif optionType == Enum.ActivityOptionType.AOT_WEBSITE then
    local param4_num = tonumber(param4)
    ActivityUtils.OpenUrl(param2, tonumber(param3), not param4_num or 0 == param4_num)
  elseif optionType == Enum.ActivityOptionType.AOT_WORLD_MAP then
    local failedTips = _G.DataModelMgr.PlayerDataModel:IsVisitState() and param5 or param3
    ActivityUtils.OpenWorldMap(tonumber(param2), failedTips, param4)
  elseif optionType == Enum.ActivityOptionType.AOT_WORLD_MAP_REFRESHID then
    local refreshIds = {}
    for str in string.gmatch(param2, "[^;]+") do
      table.insert(refreshIds, tonumber(str))
    end
    local failedTips = _G.DataModelMgr.PlayerDataModel:IsVisitState() and param5 or param3
    ActivityUtils.OpenWorldMapByRefreshId(refreshIds, failedTips, param4)
  elseif optionType == Enum.ActivityOptionType.AOT_RELAY_PAGE then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenActivityRelayPage, tonumber(param2))
  end
end

function ActivityUtils.GetSprintFormatText(num)
  local tenthousandText = LuaText.spring_festival_ten_thousand
  local millionText = LuaText.spring_festival_hundred_million
  if num >= 10000 and num < 100000000 then
    return string.format(tenthousandText, math.floor(num / 10000))
  elseif num >= 100000000 then
    return string.format(millionText, num / 100000000)
  else
    return tostring(num)
  end
end

function ActivityUtils:SetQuality(widget, quality)
  if not widget then
    return
  end
  if 0 == quality then
  elseif 1 == quality then
    widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function ActivityUtils.GetCdnImageByActivityConf(activityConfId, callback)
  local activityConf = _G.DataConfigManager:GetActivityConf(activityConfId)
  if activityConf and not string.IsNilOrEmpty(activityConf.cdn_bg) then
    local cdnLink = activityConf.cdn_bg
    if string.IsNilOrEmpty(cdnLink) then
      return
    end
    local fileName = "temp.png"
    local lastSlashIndex = string.find(cdnLink, "/[^/]*$")
    if lastSlashIndex then
      fileName = string.sub(cdnLink, lastSlashIndex + 1)
    end
    if not string.EndsWith(fileName, ".png") then
      fileName = fileName .. ".png"
    end
    local path = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "ActivityResource",
      fileName
    })
    path = UE.UNRCStatics.ConvertToAbsolutePath(path, true)
    if UE.UBlueprintPathsLibrary.FileExists(path) then
      callback(true, path)
      return
    end
    local dirPath = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "ActivityResource"
    })
    if not UE.UNRCStatics.DirectoryExists(dirPath) then
      Log.Error("TempVideos not exits")
      UE.UNRCStatics.MakeDirectory(dirPath)
    end
    local httpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
    local httpServiceRef = UnLua.Ref(httpService)
    if httpService then
      httpService:ResetHeaders()
      httpService:ResetFields()
      httpService:SetUrl(cdnLink)
      httpService:SetVerb("GET")
      httpService:Request({
        httpService,
        function(service, status)
          if status == UE.EHttpServiceStatus.RspSuccess then
            Log.Debug("ActivityUtils.GetCdnImageByActivityConf success")
            local contentType = httpService:GetResponseHeader("Content-Type")
            if string.StartsWith(contentType, "image/") then
              service:SaveToFile(path)
              callback(true, path)
            else
              Log.Error("invalid Content-Type")
              callback(false, nil)
            end
          else
            Log.Error("ActivityUtils.GetCdnImageByActivityConf failed")
            callback(false, nil)
          end
        end
      })
    end
  end
end

function ActivityUtils.IsActivityMonitorEventOnline(targetMonitorEvent)
  for i, onlineMonitorEventType in ipairs(ActivityEnum.OnlineActivityMonitorEvent) do
    if targetMonitorEvent == onlineMonitorEventType then
      return true
    end
  end
  return false
end

return ActivityUtils
