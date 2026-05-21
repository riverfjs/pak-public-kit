local AppearanceUtils = {}

function AppearanceUtils:GetSuitGradeColor(suitGrade)
  local color = "ffffffff"
  local qualityGrade = 0
  if suitGrade == Enum.SuitGrade.SG_DAILY then
    color = "5fb5d5ff"
    qualityGrade = 3
  elseif suitGrade == Enum.SuitGrade.SG_UNIFORM or suitGrade == Enum.SuitGrade.SG_UNIBOND then
    color = "9b73f8ff"
    qualityGrade = 4
  elseif suitGrade == Enum.SuitGrade.SG_BOND then
    color = "f8a955ff"
    qualityGrade = 5
  end
  return color, qualityGrade
end

function AppearanceUtils.GetPIKAQualityPath(quality)
  if 0 == quality then
  elseif 1 == quality then
    return UEPath.PIKA_QUALITY_1
  elseif 2 == quality then
    return UEPath.PIKA_QUALITY_2
  elseif 3 == quality then
    return UEPath.PIKA_QUALITY_3
  elseif 4 == quality then
    return UEPath.PIKA_QUALITY_4
  elseif 5 == quality then
    return UEPath.PIKA_QUALITY_5
  elseif 6 == quality then
    return UEPath.PIKA_QUALITY_Gorgeous_Selected
  end
  return UEPath.PIKA_QUALITY_1
end

function AppearanceUtils:GetPIKABackgroundPath(bHasGorgeous)
  if bHasGorgeous then
    return UEPath.PIKA_QUALITY_Gorgeous
  else
    return UEPath.PIKA_Unselected_Background
  end
end

function AppearanceUtils.GetSuitQuality(suitQuality)
  if suitQuality == Enum.SuitGrade.SG_DAILY then
    return 3
  elseif suitQuality == Enum.SuitGrade.SG_UNIFORM or suitQuality == Enum.SuitGrade.SG_UNIBOND then
    return 4
  elseif suitQuality == Enum.SuitGrade.SG_BOND then
    return 5
  end
  return 3
end

function AppearanceUtils:GetPetIconById(id)
  return string.format("/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/%s.%s", id, id)
end

function AppearanceUtils.GetFashionLabelSortPriority(targetLabelType, DataStoreTable)
  if not targetLabelType then
    return math.maxinteger
  end
  DataStoreTable = DataStoreTable or {}
  if table.isEmpty(DataStoreTable) then
    local config = _G.DataConfigManager:GetRoleGlobalConfig("fashion_label_sort")
    if config and config.numList then
      for priority, labelType in ipairs(config.numList) do
        DataStoreTable[labelType] = priority
      end
    end
  end
  return DataStoreTable and DataStoreTable[targetLabelType] or math.maxinteger
end

function AppearanceUtils.GetWardrobeIconPath(fashionItems)
  local dressIconPath
  if fashionItems and #fashionItems > 0 then
    for k, v in ipairs(fashionItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItem = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItem and (fashionItem.type == _G.Enum.FashionLabelType.FLT_DRESSES or fashionItem.type == _G.Enum.FashionLabelType.FLT_TOPS) then
          dressIconPath = fashionItem.icon
          break
        end
      end
    end
    if not dressIconPath then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if 1 == player.gender then
        dressIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/10700001.10700001'"
      else
        dressIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/20700001.20700001'"
      end
    end
  end
  return dressIconPath
end

function AppearanceUtils.GetWardrobeGlassInfo(fashionItems)
  local dressGlassInfo
  local isGlassItem = false
  if fashionItems and #fashionItems > 0 then
    for k, v in ipairs(fashionItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItem = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItem and (fashionItem.type == _G.Enum.FashionLabelType.FLT_DRESSES or fashionItem.type == _G.Enum.FashionLabelType.FLT_TOPS) then
          dressGlassInfo = v.wearing_glass
          if dressGlassInfo then
            isGlassItem = true
          end
        elseif fashionItem and fashionItem.type == _G.Enum.FashionLabelType.FLT_HATS and not dressGlassInfo then
          dressGlassInfo = v.wearing_glass
          if dressGlassInfo then
            isGlassItem = true
          end
        end
      end
    end
  end
  return isGlassItem, dressGlassInfo
end

function AppearanceUtils.CheckIsGlassItem(item_id)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo then
    local ownedItemInfo = fashionInfo.owned_item_info
    for _, item in pairs(ownedItemInfo or {}) do
      if item and item.item_id == item_id then
        if item.unlocked_glass and #item.unlocked_glass > 0 then
          return true
        end
        if item.claimable_glass and #item.claimable_glass > 0 then
          return true
        end
        break
      end
    end
  end
  return false
end

AppearanceUtils.FashionTypeToTagField = {
  [_G.Enum.FashionLabelType.FLT_TOPS] = "fashion_tops_tag",
  [_G.Enum.FashionLabelType.FLT_RINGS] = "fashion_rings_tag",
  [_G.Enum.FashionLabelType.FLT_BOTTOMS] = "fashion_bottoms_tag",
  [_G.Enum.FashionLabelType.FLT_SHOES] = "fashion_shoes_tag",
  [_G.Enum.FashionLabelType.FLT_SOCKS] = "fashion_socks_tag"
}
AppearanceUtils.AllTagFields = {
  "fashion_tops_tag",
  "fashion_rings_tag",
  "fashion_bottoms_tag",
  "fashion_shoes_tag",
  "fashion_socks_tag"
}
AppearanceUtils.TagFieldToFashionType = {
  fashion_tops_tag = _G.Enum.FashionLabelType.FLT_TOPS,
  fashion_rings_tag = _G.Enum.FashionLabelType.FLT_RINGS,
  fashion_bottoms_tag = _G.Enum.FashionLabelType.FLT_BOTTOMS,
  fashion_shoes_tag = _G.Enum.FashionLabelType.FLT_SHOES,
  fashion_socks_tag = _G.Enum.FashionLabelType.FLT_SOCKS
}

function AppearanceUtils.BuildTagMapFromConf(fashionItemConf)
  if not fashionItemConf then
    return {}
  end
  local tagMap = {}
  local itemType = fashionItemConf.type
  if itemType == _G.Enum.FashionLabelType.FLT_DRESSES then
    if fashionItemConf.fashion_tops_tag and fashionItemConf.fashion_tops_tag > 0 then
      tagMap.fashion_tops_tag = fashionItemConf.fashion_tops_tag
    end
    if fashionItemConf.fashion_bottoms_tag and fashionItemConf.fashion_bottoms_tag > 0 then
      tagMap.fashion_bottoms_tag = fashionItemConf.fashion_bottoms_tag
    end
  else
    local field = AppearanceUtils.FashionTypeToTagField[itemType]
    if field and fashionItemConf[field] and fashionItemConf[field] > 0 then
      tagMap[field] = fashionItemConf[field]
    end
  end
  return tagMap
end

function AppearanceUtils.BuildTagArrayFromConf(fashionItemConf)
  if not fashionItemConf then
    return nil
  end
  local itemType = fashionItemConf.type
  if itemType == _G.Enum.FashionLabelType.FLT_RINGS then
    return {
      fashionItemConf.fashion_rings_tag
    }
  elseif itemType == _G.Enum.FashionLabelType.FLT_TOPS then
    return {
      fashionItemConf.fashion_tops_tag
    }
  elseif itemType == _G.Enum.FashionLabelType.FLT_DRESSES then
    return {
      fashionItemConf.fashion_tops_tag,
      fashionItemConf.fashion_bottoms_tag
    }
  elseif itemType == _G.Enum.FashionLabelType.FLT_BOTTOMS then
    return {
      fashionItemConf.fashion_bottoms_tag
    }
  elseif itemType == _G.Enum.FashionLabelType.FLT_SHOES then
    return {
      fashionItemConf.fashion_shoes_tag
    }
  elseif itemType == _G.Enum.FashionLabelType.FLT_SOCKS then
    return {
      fashionItemConf.fashion_socks_tag
    }
  end
  return nil
end

function AppearanceUtils.BuildTagMapFromAppearData(fashionType, tagArray)
  if not tagArray then
    return {}
  end
  local tagMap = {}
  if fashionType == _G.Enum.FashionLabelType.FLT_DRESSES then
    if tagArray[1] and tagArray[1] > 0 then
      tagMap.fashion_tops_tag = tagArray[1]
    end
    if tagArray[2] and tagArray[2] > 0 then
      tagMap.fashion_bottoms_tag = tagArray[2]
    end
  else
    local field = AppearanceUtils.FashionTypeToTagField[fashionType]
    if field and tagArray[1] and tagArray[1] > 0 then
      tagMap[field] = tagArray[1]
    end
  end
  return tagMap
end

function AppearanceUtils.CheckTagConflict(tagMapA, tagMapB)
  if not tagMapA or not tagMapB then
    return false
  end
  local conflictConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_CONFLICTTAG_CONF):GetAllDatas()
  if not conflictConf then
    return false
  end
  for _, rule in pairs(conflictConf) do
    local aMatchFields = {}
    local bMatchFields = {}
    for _, field in ipairs(AppearanceUtils.AllTagFields) do
      local ruleVal = rule[field]
      if ruleVal and ruleVal > 0 then
        if tagMapA[field] and tagMapA[field] == ruleVal then
          aMatchFields[field] = true
        end
        if tagMapB[field] and tagMapB[field] == ruleVal then
          bMatchFields[field] = true
        end
      end
    end
    for aField, _ in pairs(aMatchFields) do
      for bField, _ in pairs(bMatchFields) do
        if aField ~= bField then
          return true
        end
      end
    end
  end
  return false
end

function AppearanceUtils.GetConflictingTagEntries(tagMap)
  local result = {}
  if not tagMap then
    return result
  end
  local conflictConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FASHION_CONFLICTTAG_CONF):GetAllDatas()
  if not conflictConf then
    return result
  end
  for _, rule in pairs(conflictConf) do
    local matchedFields = {}
    for _, field in ipairs(AppearanceUtils.AllTagFields) do
      local ruleVal = rule[field]
      if ruleVal and ruleVal > 0 and tagMap[field] and tagMap[field] == ruleVal then
        matchedFields[field] = true
      end
    end
    if next(matchedFields) then
      for _, field in ipairs(AppearanceUtils.AllTagFields) do
        local ruleVal = rule[field]
        if ruleVal and ruleVal > 0 and not matchedFields[field] then
          local fType = AppearanceUtils.TagFieldToFashionType[field]
          if fType then
            table.insert(result, {
              field = field,
              fashionType = fType,
              tagValue = ruleVal
            })
          end
        end
      end
    end
  end
  return result
end

function AppearanceUtils.GetAvatarEnumFromFashionId(fashionId)
  if not fashionId or fashionId < 10000000 then
    return nil
  end
  local base = fashionId > 99999999 and 1000000000 or 10000000
  return math.floor(fashionId / (base / 100) % 100)
end

AppearanceUtils.BodyTypeConflictMap = nil

function AppearanceUtils.InitBodyTypeConflictMap()
  if AppearanceUtils.BodyTypeConflictMap then
    return
  end
  local BT = UE4.EAvatarBodyType
  AppearanceUtils.BodyTypeConflictMap = {
    [BT.Hat] = {
      ConflictBodyTypes = {
        BT.Wh,
        BT.Wa
      },
      CacheBodyTypes = {}
    },
    [BT.Wh] = {
      ConflictBodyTypes = {
        BT.Hat,
        BT.Heads,
        BT.Hg,
        BT.Hp,
        BT.Hair
      },
      CacheBodyTypes = {
        BT.Hair
      }
    },
    [BT.Wa] = {
      ConflictBodyTypes = {
        BT.Hat,
        BT.Heads,
        BT.Hg,
        BT.Hp,
        BT.Hair
      },
      CacheBodyTypes = {
        BT.Hair
      }
    },
    [BT.Heads] = {
      ConflictBodyTypes = {
        BT.Wh,
        BT.Wa
      },
      CacheBodyTypes = {}
    },
    [BT.Masks] = {
      ConflictBodyTypes = {
        BT.Hp
      },
      CacheBodyTypes = {}
    },
    [BT.Faces] = {
      ConflictBodyTypes = {
        BT.Hp
      },
      CacheBodyTypes = {}
    },
    [BT.Hair] = {
      ConflictBodyTypes = {
        BT.Hg,
        BT.Hp,
        BT.Wh,
        BT.Wa
      },
      CacheBodyTypes = {}
    },
    [BT.Hg] = {
      ConflictBodyTypes = {
        BT.Hair,
        BT.Wh
      },
      CacheBodyTypes = {
        BT.Heads,
        BT.Hair
      }
    },
    [BT.Hp] = {
      ConflictBodyTypes = {
        BT.Masks,
        BT.Faces,
        BT.Hair,
        BT.Wh
      },
      CacheBodyTypes = {
        BT.Heads,
        BT.Masks,
        BT.Faces,
        BT.Hair
      }
    }
  }
end

function AppearanceUtils.GetConflictBodyTypes(bodyType)
  if not AppearanceUtils.BodyTypeConflictMap then
    AppearanceUtils.InitBodyTypeConflictMap()
  end
  if not AppearanceUtils.BodyTypeConflictMap then
    return nil
  end
  local entry = AppearanceUtils.BodyTypeConflictMap[bodyType]
  if entry then
    return entry.ConflictBodyTypes
  end
  return nil
end

function AppearanceUtils.GetCacheBodyTypes(bodyType)
  if not AppearanceUtils.BodyTypeConflictMap then
    AppearanceUtils.InitBodyTypeConflictMap()
  end
  if not AppearanceUtils.BodyTypeConflictMap then
    return nil
  end
  local entry = AppearanceUtils.BodyTypeConflictMap[bodyType]
  if entry then
    return entry.CacheBodyTypes
  end
  return nil
end

function AppearanceUtils.IsBodyTypeConflict(bodyTypeA, bodyTypeB)
  local conflicts = AppearanceUtils.GetConflictBodyTypes(bodyTypeA)
  if not conflicts then
    return false
  end
  for _, v in ipairs(conflicts) do
    if v == bodyTypeB then
      return true
    end
  end
  return false
end

function AppearanceUtils.IsFashionConflictWithBodyType(fashionId, targetBodyType)
  local avatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(fashionId)
  if not avatarEnum then
    return false
  end
  return AppearanceUtils.IsBodyTypeConflict(targetBodyType, avatarEnum)
end

function AppearanceUtils.GetConflictFashionTypesForItem(fashionId)
  local avatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(fashionId)
  if not avatarEnum then
    return nil
  end
  local conflicts = AppearanceUtils.GetConflictBodyTypes(avatarEnum)
  if not conflicts or 0 == #conflicts then
    return nil
  end
  local result = {}
  local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
  for _, conflictBodyType in ipairs(conflicts) do
    local _, configEnum = UIUtils.GetConfigEnumByAvatarEnum(conflictBodyType, 0)
    if configEnum then
      result[configEnum] = true
    end
  end
  if not next(result) then
    return nil
  end
  return result
end

return AppearanceUtils
