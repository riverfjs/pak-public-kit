local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local BagModuleEnum = require("NewRoco.Modules.System.Bag.BagModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModuleData = _G.NRCData:Extend("BagModuleData")
BagModuleData.CustomEnum = {
  SKILL_MACHINE = 0,
  OPTIONAL_TREASUREBOX = 1,
  PetToSKILL_MACHINE = 2
}
BagModuleData.CharacterPanelEnum = {
  PetCharacterTips = "PetCharacterTips",
  PetCharacterPopUp = "PetCharacterPopUp",
  PetAttributePopUp = "PetAttributePopUp",
  BagTips = "BagTips",
  BagBright = "BagBright",
  TalentPopup = "TalentPopup",
  TalentChange = "TalentChange",
  BagBlood = "BagBlood",
  BagBloodPopup = "BagBloodPopup",
  BagBloodChange = "BagBloodChange"
}
BagModuleData.PurificationEnum = {
  SELECT = 0,
  USE = 1,
  SUCCESS = 2
}

function BagModuleData:Ctor()
  NRCData.Ctor(self)
  self.BagInfo = nil
  self.TypeTable = {
    1001,
    1002,
    1003,
    1004,
    1005,
    1006,
    1007,
    1008,
    1009,
    1010
  }
  self.curSelectedItemData = nil
  self.curEquipItemData = {}
  self.curSortList = {}
  self.curItemType = 0
  self.changeEquipItemGid = 0
  self.changeEquipItemFlag = 0
  self.SortIndex = _G.Enum.Sequence.SEQUENCE_DEFAULT
  self.SortSelectIndex = 1
  self.curEquipMagicData = nil
  self.curEquipProtagonistMagicData = nil
  self.IsFirstOpenPanel = true
  self.FirstOpenPanelId = -1
  self.displayMode = BagModuleEnum.DisplayMode.Zone
  self.curSelectedItemDataBattle = 0
  self.BXItemList = {}
  self.itemIdMap = {}
  self.itemGidMap = {}
  self.itemLableTypeMap = {}
  self.EquipBallList = nil
  self.ChangeBallSelectedItem = nil
  self.curSelectedPetSkillItemData = nil
  self.IsFirstAcquisitionMagic = false
  self.CurEquipBallIdxList = nil
  self.AllSortSelectIndex = {}
  self.Canfilter = true
  self.FilterPetList = {}
  self.FilterPetCondition = {}
  self.FilterDepartCondition = {}
  self.FilterClassifyCondition = {}
  self.PetCharacterItem = nil
  self.GoodPetNature = nil
  self.BadPetNature = nil
  self.IsGoodAttributePopUp = false
  self.AttributeNumText = ""
  self.PetTalentItem = nil
  self.ChangeTalentIndex = nil
  self.ChangeTalent = nil
  self.ChangeTalentType = nil
  self.ResultTalentType = nil
  self.PetBloodItem = nil
  self.ChangeBlood = nil
  self.CacheHatchEggItem = nil
  self.curEvolutionarySelectedItem = nil
  self.MedalBondConfList = {}
  self.giftVoucherData = nil
  self.IsInitEquipBall = false
  self.IsRemoteGetLastBall = false
  self.TabSortList = {}
  self:InitializeConf()
  self.BallCollectList = {}
  self:OnZoneGetBagItemIdFlagReq()
end

function BagModuleData:ClearPopUpPanelData()
  self.PetCharacterItem = nil
  self.GoodPetNature = nil
  self.BadPetNature = nil
  self.IsGoodAttributePopUp = false
  self.AttributeNumText = ""
  self.PetTalentItem = nil
  self.ChangeTalentIndex = nil
  self.ChangeTalent = nil
  self.ChangeTalentType = nil
  self.ResultTalentType = nil
  self.ChangeBlood = nil
  self.PetBloodItem = nil
end

function BagModuleData:SetBagInfo(BagInfo)
  self.EquipBallList = {}
  self.BagInfo = self:FilterBagInfo(BagInfo)
  local curEquipItem
  if self.BagInfo.bag_backpack and self.BagInfo.bag_backpack.ball_list then
    self:SetEquipBallList(self.BagInfo.bag_backpack.ball_list)
  elseif self.CurEquipBallIdxList == nil then
    self.CurEquipBallIdxList = {}
  end
  local useBallList = {}
  for i = 1, #self.BagInfo.item_list do
    if nil ~= self.BagInfo.item_list[i].items then
      for j = 1, #self.BagInfo.item_list[i].items do
        local itemInfo = self.BagInfo.item_list[i].items[j]
        if self.BagInfo.item_list[i].type == _G.Enum.BagItemType.BI_PET_BALL then
          if not itemInfo.bag_item_flags then
            itemInfo.bag_item_flags = 1
          end
          local ballConf = _G.DataConfigManager:GetBallConf(itemInfo.id)
          if ballConf and ballConf.bigworld_catch ~= false then
            table.insert(self.EquipBallList, itemInfo)
            table.insert(useBallList, {
              gid = itemInfo.gid,
              idx = j - 1
            })
            if itemInfo.num > 0 and self.BagInfo.item_list[i].type == _G.Enum.BagItemType.BI_PET_BALL and 9 == itemInfo.bag_item_flags then
              curEquipItem = itemInfo
            end
          end
        elseif itemInfo.bag_item_flags and 0 ~= itemInfo.bag_item_flags & ProtoEnum.BagItemFlag.SEED_EQUIPPED then
          _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.SetEquipSeedDirectly, itemInfo.id, false, itemInfo.level)
        elseif itemInfo.bag_item_flags and 0 ~= itemInfo.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED then
          _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, itemInfo.id, itemInfo.num)
        end
        if nil == itemInfo.conf then
          local itemConf = _G.DataConfigManager:GetBagItemConf(itemInfo.id)
          if itemConf then
            itemInfo.conf = itemConf
          end
        end
      end
    end
  end
  self:RebuildItemIndexMaps()
  NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateBag)
  if not self.IsInitEquipBall then
    self.IsInitEquipBall = true
    if curEquipItem then
      self:SetCurEquipItem(curEquipItem)
    else
      local hasBall = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckHadUseBall)
      if hasBall then
        self.IsRemoteGetLastBall = true
        _G.DataModelMgr.RemoteStorage:Get("EquipBallId", ".Next.LastEquipBall", self, self.OnGetLastEquipBallRemote)
      else
        self:SetCurEquipItem(curEquipItem)
      end
    end
  elseif not self.IsRemoteGetLastBall then
    self:SetCurEquipItem(curEquipItem)
  end
  if self.BagInfo.bag_backpack then
    self.BagInfo.bag_backpack.ball_list = useBallList
  end
  self.BagInfo.equipped_ball_num = #useBallList
  self:PreLoadAllBallRes()
end

function BagModuleData:OnGetLastEquipBallRemote(data)
  if data.EquipBallId then
    local ballConf = _G.DataConfigManager:GetBallConf(data.EquipBallId)
    if ballConf and ballConf.bigworld_catch ~= false then
      local LastEquipData = {
        id = data.EquipBallId,
        num = 0,
        type = _G.Enum.BagItemType.BI_PET_BALL,
        conf = ballConf
      }
      self:SetCurEquipItem(LastEquipData)
    else
      self:SetCurEquipItem(nil)
    end
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, true)
  else
    self:SetCurEquipItem(nil)
  end
  self.IsRemoteGetLastBall = false
end

function BagModuleData:RebuildItemIndexMaps()
  self.itemIdMap = {}
  self.itemGidMap = {}
  self.itemLableTypeMap = {}
  if not self.BagInfo or not self.BagInfo.item_list then
    return
  end
  for i, item_type in ipairs(self.BagInfo.item_list) do
    if item_type.items then
      for _, item in ipairs(item_type.items) do
        if item then
          if item.conf == nil then
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(item.id)
            if bagItemConf then
              item.conf = bagItemConf
            end
          end
          self:UpdateItemIndexMaps(item, false)
        end
      end
    end
  end
end

function BagModuleData:RemoveFromItemIdMap(item)
  if not item.id or not self.itemIdMap[item.id] then
    return
  end
  local id_data = self.itemIdMap[item.id]
  if not id_data then
    return
  end
  if id_data.items then
    for i = #id_data.items, 1, -1 do
      if id_data.items[i] == item or id_data.items[i].gid == item.gid then
        table.remove(id_data.items, i)
      end
    end
    if 0 == #id_data.items then
      self.itemIdMap[item.id] = nil
    elseif 1 == #id_data.items then
      self.itemIdMap[item.id] = id_data.items[1]
    end
  elseif id_data == item or id_data.gid == item.gid then
    self.itemIdMap[item.id] = nil
  end
end

function BagModuleData:AddOrUpdateItemIdMap(item)
  if not item.id then
    return
  end
  local existing = self.itemIdMap[item.id]
  if not existing then
    self.itemIdMap[item.id] = item
  elseif existing.items then
    local found = false
    for i, existing_item in ipairs(existing.items) do
      if existing_item.gid == item.gid then
        existing.items[i] = item
        found = true
        break
      end
    end
    if not found and item.gid then
      table.insert(existing.items, item)
    end
  elseif existing.gid == item.gid then
    self.itemIdMap[item.id] = item
  elseif item.gid then
    self.itemIdMap[item.id] = {
      items = {existing, item}
    }
  end
end

function BagModuleData:RemoveFromLableTypeMap(item)
  if not (item.gid and item.conf) or not item.conf.lable_type then
    return
  end
  local lable_type = item.conf.lable_type
  local lable_data = self.itemLableTypeMap[lable_type]
  if not lable_data then
    return
  end
  local idx = lable_data.gid_index[item.gid]
  if not idx then
    return
  end
  local last_idx = #lable_data.items
  if idx ~= last_idx then
    local last_item = lable_data.items[last_idx]
    lable_data.items[idx] = last_item
    if last_item.gid then
      lable_data.gid_index[last_item.gid] = idx
    end
  end
  table.remove(lable_data.items, last_idx)
  lable_data.gid_index[item.gid] = nil
  if 0 == #lable_data.items then
    self.itemLableTypeMap[lable_type] = nil
  end
end

function BagModuleData:AddOrUpdateLableTypeMap(item)
  if not (item.gid and item.conf) or not item.conf.lable_type then
    return
  end
  local lable_type = item.conf.lable_type
  if not self.itemLableTypeMap[lable_type] then
    self.itemLableTypeMap[lable_type] = {
      items = {},
      gid_index = {}
    }
  end
  local lable_data = self.itemLableTypeMap[lable_type]
  if lable_data.gid_index[item.gid] then
    local idx = lable_data.gid_index[item.gid]
    lable_data.items[idx] = item
  else
    table.insert(lable_data.items, item)
    lable_data.gid_index[item.gid] = #lable_data.items
  end
end

function BagModuleData:UpdateItemIndexMaps(item, is_remove)
  if not item then
    return
  end
  if not is_remove and item.conf == nil then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(item.id)
    if bagItemConf then
      item.conf = bagItemConf
    end
  end
  if is_remove then
    self:RemoveFromItemIdMap(item)
    if item.gid then
      self.itemGidMap[item.gid] = nil
    end
    self:RemoveFromLableTypeMap(item)
  else
    self:AddOrUpdateItemIdMap(item)
    if item.gid then
      self.itemGidMap[item.gid] = item
    end
    self:AddOrUpdateLableTypeMap(item)
  end
end

function BagModuleData:FilterBagInfo(BagInfo)
  local filterBaginfo = BagInfo
  for i = 1, #filterBaginfo.item_list do
    local removeList = {}
    if filterBaginfo.item_list[i].items ~= nil then
      for j = 1, #filterBaginfo.item_list[i].items do
        local itemInfo = filterBaginfo.item_list[i].items[j]
        itemInfo.FromBag = true
        local itemId = itemInfo.id
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
        if itemInfo.num <= 0 then
          table.insert(removeList, j)
        end
      end
    end
    for j = #removeList, 1, -1 do
      table.remove(filterBaginfo.item_list[i].items, removeList[j])
      table.remove(removeList, j)
    end
  end
  return filterBaginfo
end

function BagModuleData:SetSkillStoneFilter(filterList, condition)
  self.Canfilter = true
  self.FilterPetList = filterList
  self.FilterPetCondition = condition.FilterPetCondition
  self.FilterDepartCondition = condition.FilterDepartCondition
  self.FilterClassifyCondition = condition.FilterClassifyCondition
end

function BagModuleData:ClearSkillStoneFilter()
  self.FilterPetList = {}
  self.FilterPetCondition = {}
  self.FilterDepartCondition = {}
  self.FilterClassifyCondition = {}
  self.SortSelectIndex = 1
  self.AllSortSelectIndex = {}
end

function BagModuleData:SetTableSortSelectIndex(bagItemType, sortIndex)
  self.AllSortSelectIndex[bagItemType] = sortIndex
end

function BagModuleData:GetTableSortSelectIndex(bagItemType)
  if self.AllSortSelectIndex[bagItemType] then
    return self.AllSortSelectIndex[bagItemType]
  else
    self.AllSortSelectIndex[bagItemType] = 1
    return 1
  end
end

function BagModuleData:GetBagInfo()
  return self.BagInfo
end

function BagModuleData:SetCurSelectedItemData(itemData)
  self.curSelectedItemData = itemData
end

function BagModuleData:GetCurSelectedItemData()
  return self.curSelectedItemData
end

function BagModuleData:SetCurSelectedPetSkillItemData(itemData)
  self.curSelectedPetSkillItemData = itemData
end

function BagModuleData:GetCurSelectedPetSkillItemData()
  return self.curSelectedPetSkillItemData
end

function BagModuleData:GetBXItemList()
  return self.BXItemList
end

function BagModuleData:SetBXItemList(list)
  self.BXItemList = list
end

function BagModuleData:SetCurEquipItem(itemData)
  self.curEquipItemData = itemData
end

function BagModuleData:GetCurEquipItem()
  return self.curEquipItemData
end

function BagModuleData:SetCurEquipMagicData(itemData, bSetThrow)
  self:Log("[MAGIC] BagModuleData:SetCurEquipMagicData", itemData and itemData.id, bSetThrow, self.IsFirstAcquisitionMagic)
  self.curEquipMagicData = itemData
  if not self.IsFirstAcquisitionMagic then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipMagicItemInfo, bSetThrow)
  end
  if self.IsFirstAcquisitionMagic and bSetThrow and itemData then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, itemData)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
  end
end

function BagModuleData:GetCurEquipMagicData()
  return self.curEquipMagicData
end

function BagModuleData:SetCurEquipProtagonistMagicData(_curEquipProtagonistMagicData)
  self.curEquipProtagonistMagicData = _curEquipProtagonistMagicData
end

function BagModuleData:GetCurEquipProtagonistMagicData()
  return self.curEquipProtagonistMagicData
end

function BagModuleData:GetvItemNum(vItemType)
  return _G.DataModelMgr.PlayerDataModel:GetVItemCount(vItemType)
end

function BagModuleData:GetItemFlag(gid)
end

function BagModuleData:SetCurSortList(sortList)
  self.curSortList = sortList or {
    Enum.Sequence.SEQUENCE_DEFAULT,
    Enum.Sequence.SEQUENCE_QUALITY_DOWN
  }
end

function BagModuleData:GetCurSortList()
  return self.curSortList
end

function BagModuleData:SetCurItemType(curItemType)
  self.curItemType = curItemType
end

function BagModuleData:GetCurItemType()
  return self.curItemType or 1
end

function BagModuleData:SetChangeEquipItemGidnFlag(gid, flag)
  self.changeEquipItemGid = gid
  self.changeEquipItemFlag = flag
end

function BagModuleData:GetChangeEquipItemGid()
  return self.changeEquipItemGid
end

function BagModuleData:GetChangeEquipItemFlag()
  return self.changeEquipItemFlag
end

function BagModuleData:UpdateBagItemData(newItem, cmd)
  if not self.BagInfo then
    return
  end
  local itemConf = _G.DataConfigManager:GetBagItemConf(newItem.bag_item.id)
  if not itemConf then
    return
  end
  local typeItems = self:GetBagItemArrByType(itemConf.type)
  local found = false
  if typeItems and #typeItems > 0 then
    for i, k in ipairs(typeItems) do
      if k.gid == newItem.bag_item.gid then
        local Old = typeItems[i]
        local New = newItem.bag_item
        if Old.can_charge and New.can_charge then
          if Old.effect_value and New.effect_value and Old.effect_value < New.effect_value then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, TipObject.FromAmplifyUseEffect(New, Old.effect_value, newItem.id), cmd)
          end
          if Old.max_use_cnt and New.max_use_cnt and Old.max_use_cnt < New.max_use_cnt then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, TipObject.FromIncreaseUseCount(New, Old.max_use_cnt, newItem.id), cmd)
          end
          if Old.remain_use_cnt and New.remain_use_cnt and Old.remain_use_cnt < New.remain_use_cnt then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, TipObject.FromRecharge(New, Old.remain_use_cnt, newItem.id), cmd)
          end
        end
        typeItems[i] = New
        found = true
        if 0 == newItem.num then
          self:UpdateItemIndexMaps(Old, true)
          table.remove(typeItems, i)
          NRCEventCenter:DispatchEvent(BagModuleEvent.BagItemUpdate, newItem.id)
          do return end
          break
        end
        self:UpdateItemIndexMaps(New, false)
        break
      end
    end
  end
  if not found and newItem.bag_item and newItem.bag_item.num > 0 then
    table.insert(typeItems, newItem.bag_item)
    self:UpdateItemIndexMaps(newItem.bag_item, false)
  end
  local bagItem = self:GetBagItemByGID(newItem.gid)
  if bagItem then
    NRCEventCenter:DispatchEvent(BagModuleEvent.BagItemUpdate, newItem.id)
  else
    NRCEventCenter:DispatchEvent(BagModuleEvent.BagItemAdd, newItem.id)
  end
end

function BagModuleData:GetBagItemByID(id)
  if not self.BagInfo then
    return nil
  end
  if not self.BagInfo.item_list then
    return nil
  end
  local id_data = self.itemIdMap[id]
  if not id_data then
    return nil
  end
  if id_data.items then
    if #id_data.items > 0 then
      local count = 0
      local itemData
      for _, item in ipairs(id_data.items) do
        if not itemData then
          itemData = {}
          table.copy(item, itemData)
        end
        count = count + item.num
      end
      if itemData then
        itemData.num = count
        return itemData
      end
    end
  else
    return id_data
  end
  return nil
end

function BagModuleData:GetMedalListAndWearMedalByPetGid(Gid)
  Log.Warning("BagModuleData:GetMedalListAndWearMedalByPetGid \229\183\178\229\186\159\229\188\131\239\188\140\232\175\183\228\189\191\231\148\168 PlayerDataModel:GetMedalListAndWearMedalByPetGid")
  return _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(Gid)
end

function BagModuleData:UpdateBagItemNumByID(ID, Num)
  if not self.BagInfo then
    return
  end
  if not self.BagInfo.item_list then
    return
  end
  local ItemList = self.BagInfo.item_list
  for i = #ItemList, 1, -1 do
    if ItemList[i].items then
      for j = #ItemList[i].items, 1, -1 do
        if ItemList[i].items[j] and ItemList[i].items[j].id == ID then
          local item = ItemList[i].items[j]
          item.num = Num
          if 0 == Num then
            self:UpdateItemIndexMaps(item, true)
            table.remove(ItemList[i].items, j)
          else
            self:UpdateItemIndexMaps(item, false)
          end
        end
      end
    end
  end
end

function BagModuleData:GetCanFeedItem()
  if not self.BagInfo then
    return self:GetDefaultFeedItem()
  end
  if not self.BagInfo.item_list then
    return self:GetDefaultFeedItem()
  end
  local bagItem = {}
  local BagItemList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  for i, List in pairs(BagItemList) do
    if self:ItemConditionPass(List.item_behavior) then
      local IsHasItem = false
      for k, item_type in ipairs(self.BagInfo.item_list) do
        if item_type.items then
          for _, item in ipairs(item_type.items) do
            if item and item.id == List.id then
              IsHasItem = true
              local IsHasNum = false
              if item.num > 0 then
                IsHasNum = true
              end
              table.insert(bagItem, {
                itemConf = List,
                Item = item,
                IsHasNum = IsHasNum,
                num = item.num
              })
              break
            end
          end
        end
      end
      if not IsHasItem then
        table.insert(bagItem, {
          itemConf = List,
          IsHasNum = false,
          num = 0
        })
      end
    end
  end
  table.sort(bagItem, function(a, b)
    if a.itemConf.sort_id < b.itemConf.sort_id then
      return a.itemConf.sort_id < b.itemConf.sort_id
    end
  end)
  return bagItem
end

function BagModuleData:GetDefaultFeedItem()
  local bagItem = {}
  local BagItemList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  for i, List in pairs(BagItemList) do
    if self:ItemConditionPass(List.item_behavior) then
      table.insert(bagItem, {
        itemConf = List,
        IsHasNum = false,
        num = 0
      })
    end
  end
  table.sort(bagItem, function(a, b)
    if a.itemConf.sort_id < b.itemConf.sort_id then
      return a.itemConf.sort_id < b.itemConf.sort_id
    end
  end)
  return bagItem
end

function BagModuleData:ItemConditionPass(item_behavior)
  if not item_behavior then
    return false
  end
  for i, item in ipairs(item_behavior) do
    local UseAction = item.use_action
    if UseAction == Enum.ItemBehavior.IB_ADD_PET_EXP then
      return true
    end
  end
  return false
end

function BagModuleData:SetBagItemDataByID(ItemInfo)
  if not self.BagInfo then
    return
  end
  if not self.BagInfo.item_list then
    return
  end
  for i, item_type in ipairs(self.BagInfo.item_list) do
    if item_type.items then
      for j, item in ipairs(item_type.items) do
        if item and item.gid == ItemInfo.gid then
          self:UpdateItemIndexMaps(item, true)
          item_type.items[j] = ItemInfo
          self:UpdateItemIndexMaps(ItemInfo, false)
          return
        end
      end
    end
  end
end

function BagModuleData:GetBagItemByGID(gid)
  if not self.BagInfo then
    return nil
  end
  return self.itemGidMap[gid]
end

function BagModuleData:SetEquipBallList(ballList)
  self.CurEquipBallIdxList = ballList
end

function BagModuleData:GetEquipBallInfo(gid)
  if self.CurEquipBallIdxList then
    for i = 1, #self.CurEquipBallIdxList do
      if gid == self.CurEquipBallIdxList[i].gid then
        return self.CurEquipBallIdxList
      end
    end
  end
  return nil
end

function BagModuleData:GetEquipBallIndex(gid)
  if self.CurEquipBallIdxList then
    for i = 1, #self.CurEquipBallIdxList do
      if gid == self.CurEquipBallIdxList[i].gid then
        return self.CurEquipBallIdxList[i].idx
      end
    end
  end
  return nil
end

function BagModuleData:SortEquipBall(ballList)
  table.sort(ballList, function(a, b)
    return self:GetBagEquipSortIndex(a.gid) < self:GetBagEquipSortIndex(b.gid)
  end)
  return ballList
end

function BagModuleData:GetBagEquipSortIndex(gid)
  if self.CurEquipBallIdxList == nil then
    return 999
  end
  for i = 1, #self.CurEquipBallIdxList do
    if gid == self.CurEquipBallIdxList[i].gid then
      return self.CurEquipBallIdxList[i].idx
    end
  end
  return 999
end

function BagModuleData:GetBagItemArrByType(type)
  if not self.BagInfo then
    return nil
  end
  local length = #self.BagInfo.item_list
  for i = 1, length do
    if self.BagInfo.item_list[i].type == type then
      if not self.BagInfo.item_list[i].items then
        self.BagInfo.item_list[i].items = {}
      end
      return self.BagInfo.item_list[i].items
    end
  end
  local TypeList = ProtoMessage:newBagItemTypeList()
  TypeList.type = type
  table.insert(self.BagInfo.item_list, TypeList)
  return TypeList.items
end

function BagModuleData:GetSortTypesByItemType(itemType)
  for i = 1, #self.TypeTable do
    if self.TypeTable[i] then
      local TypeInfo = _G.DataConfigManager:GetItemLableTypeConf(self.TypeTable[i])
      if TypeInfo.lable_type == itemType then
        return TypeInfo.sequence
      end
    end
  end
  return {
    Enum.Sequence.SEQUENCE_DEFAULT,
    Enum.Sequence.SEQUENCE_QUALITY_DOWN
  }
end

function BagModuleData:SortItemList(itemType, SortType)
  self.SortIndex = SortType
  local itemList = self:GetBagItemArrByType(itemType)
  if SortType == _G.Enum.Sequence.SEQUENCE_DEFAULT then
    return self:SortDefault(itemList, itemType)
  elseif SortType == _G.Enum.Sequence.SEQUENCE_QUALITY_UP then
    return self:SortQualityUp(itemList, itemType)
  elseif SortType == _G.Enum.Sequence.SEQUENCE_QUALITY_DOWN then
    return self:SortQualityDown(itemList, itemType)
  end
end

function BagModuleData:InitFurnitureBagData()
  self._FurnitureDecomposeSelectNums = {}
  self._FurnitureDecomposeSelectItem = {}
  self._bInFurnitureDecomposeMode = false
end

function BagModuleData:ResetFurnitureFilterTabMap()
  self._FurnitureFilterTabMap = nil
  self._FurnitureDisplayNumInTabDecompose = nil
  self._FurnitureDisplayNumInTab = nil
end

function BagModuleData:HasFurnitureFilters()
  return self._FurnitureFilterTabMap and next(self._FurnitureFilterTabMap)
end

function BagModuleData:SetFurnitureFilterTabMap(TabMap)
  self._FurnitureFilterTabMap = {}
  if TabMap then
    for k, v in pairs(TabMap) do
      if v then
        self._FurnitureFilterTabMap[k] = v
      end
    end
  end
end

function BagModuleData:GetDecomposeRequestBody(bIncludeItem)
  local Req = ProtoMessage:newZoneHomeWarehouseDecompositionReq()
  Req.target_list = {}
  if self._FurnitureDecomposeSelectNums then
    for k, v in pairs(self._FurnitureDecomposeSelectNums) do
      local item = self._FurnitureDecomposeSelectItem[k]
      if item then
        local Info = {
          gid = item.gid,
          num = v
        }
        if bIncludeItem then
          Info.item = item
        end
        table.insert(Req.target_list, Info)
      end
    end
  end
  return Req
end

function BagModuleData:GetDecomposeReturnItemInfos()
  local RewardItemList = {}
  local ItemInfos = {}
  if not self._FurnitureDecomposeSelectItem then
    Log.Error("BagModuleData _FurnitureDecomposeSelectItem is nil")
    return RewardItemList
  end
  for Gid, Item in pairs(self._FurnitureDecomposeSelectItem) do
    local Num = self._FurnitureDecomposeSelectNums[Gid]
    local Conf = DataConfigManager:GetFurnitureItemConf(Item.id)
    if Conf then
      local PerItemRewardConf = Conf and Conf.Furniture_reward and DataConfigManager:GetRewardConf(Conf.Furniture_reward)
      local Items = PerItemRewardConf.RewardItem
      if Items then
        for i, RewardItem in ipairs(Items) do
          local Count = Num * RewardItem.Count
          local Data = ItemInfos[RewardItem.Id]
          if not Data then
            Data = {
              itemType = RewardItem.Type,
              itemId = RewardItem.Id,
              itemNum = Count,
              bShowNum = true,
              bShowGetTag = false,
              IsCanClick = true
            }
            table.insert(RewardItemList, Data)
            ItemInfos[RewardItem.Id] = Data
          else
            Data.itemNum = Data.itemNum + Count
          end
        end
      end
    end
  end
  return RewardItemList
end

function BagModuleData:GetFurnitureFilterTabMap()
  return self._FurnitureFilterTabMap
end

function BagModuleData:countFurnitureDisplayNumInTab(dataStoreTable, targetBagItem, HomeModuleData)
  if not dataStoreTable or not targetBagItem then
    return
  end
  local ItemConf = _G.DataConfigManager:GetFurnitureItemConf(targetBagItem.id, true)
  ItemConf = ItemConf or _G.DataConfigManager:GetInteriorFinishConf(targetBagItem.id)
  local TabId = ItemConf and HomeModuleData and ItemConf.classification
  local firstTabId = HomeModuleData:GetFirstTabId(TabId)
  if TabId and firstTabId then
    if nil == dataStoreTable[TabId] then
      dataStoreTable[TabId] = 0
    end
    if nil == dataStoreTable[firstTabId] then
      dataStoreTable[firstTabId] = 0
    end
    dataStoreTable[TabId] = dataStoreTable[TabId] + 1
    if firstTabId ~= TabId then
      dataStoreTable[firstTabId] = dataStoreTable[firstTabId] + 1
    end
  end
end

function BagModuleData:GetFurnitureDisplayNumInTab()
  return self._FurnitureDisplayNumInTab
end

function BagModuleData:GetFurnitureDisplayNumInTabDecompose()
  return self._FurnitureDisplayNumInTabDecompose
end

function BagModuleData:GetTotalDecomposeNum()
  local Num = 0
  if self._FurnitureDecomposeSelectNums then
    for k, v in pairs(self._FurnitureDecomposeSelectNums) do
      Num = Num + v
    end
  end
  return Num
end

function BagModuleData:HasFurnitureDecomposeItems()
  return self._FurnitureDecomposeSelectNums and next(self._FurnitureDecomposeSelectNums)
end

function BagModuleData:InFurnitureDecomposeMode()
  return self._bInFurnitureDecomposeMode
end

function BagModuleData:SetFurnitureDecomposeMode(bDecomposeMode)
  if not self._bInFurnitureDecomposeMode and bDecomposeMode then
    self:SetCurSelectedItemData(nil)
  end
  self._bInFurnitureDecomposeMode = bDecomposeMode
end

function BagModuleData:SelectFurnitureForDecompose(Item, num)
  local itemGid = Item and Item.gid
  num = num or 1
  if itemGid and self._FurnitureDecomposeSelectNums then
    if not self._FurnitureDecomposeSelectNums[itemGid] then
      self._FurnitureDecomposeSelectNums[itemGid] = 0
    end
    local v = num + self._FurnitureDecomposeSelectNums[itemGid]
    v = math.clamp(v, 0, Item.num)
    self._FurnitureDecomposeSelectNums[itemGid] = v
    if 0 == v then
      self._FurnitureDecomposeSelectItem[itemGid] = nil
    else
      self._FurnitureDecomposeSelectItem[itemGid] = Item
    end
    return self._FurnitureDecomposeSelectNums[itemGid]
  end
  return 0
end

function BagModuleData:GetFurnitureDecomposeNum(Item)
  local itemGid = Item and Item.gid
  if itemGid and self._FurnitureDecomposeSelectNums then
    local v = self._FurnitureDecomposeSelectNums[itemGid] or 0
    if v > Item.num then
      v = Item.num
      self._FurnitureDecomposeSelectNums[itemGid] = v
      if 0 == v then
        self._FurnitureDecomposeSelectItem[itemGid] = nil
      else
        self._FurnitureDecomposeSelectItem[itemGid] = Item
      end
    end
    return v
  end
  return 0
end

function BagModuleData:SortItemListByLableType(itemType, SortType, IsFilterBag)
  self:SetTabSortListSortType(itemType, SortType)
  self.SortIndex = SortType or _G.Enum.Sequence.SEQUENCE_DEFAULT
  local itemList = self:GetBagItemByLableType(itemType, IsFilterBag)
  itemList = self:ProcessFruitItemList(itemType, itemList)
  local list = {}
  local IsReversalSort = self:GetTabSortIsReversalSort(itemType)
  if SortType == _G.Enum.Sequence.SEQUENCE_DEFAULT then
    if IsReversalSort then
      list = self:ReversalSortDefault(itemList, itemType)
    else
      list = self:SortDefault(itemList, itemType)
    end
  elseif SortType == _G.Enum.Sequence.SEQUENCE_QUALITY_UP then
    if IsReversalSort then
      list = self:ReversalSortQualityUp(itemList, itemType)
    else
      list = self:SortQualityUp(itemList, itemType)
    end
  elseif SortType == _G.Enum.Sequence.SEQUENCE_QUALITY_DOWN then
    if IsReversalSort then
      if itemType == _G.Enum.ItemLableType.ILT_PET_EGG then
        list = self:ReversalSortEggQualityDown(itemList, itemType)
      else
        list = self:ReversalSortQualityDown(itemList, itemType)
      end
    elseif itemType == _G.Enum.ItemLableType.ILT_PET_EGG then
      list = self:SortEggQualityDown(itemList, itemType)
    else
      list = self:SortQualityDown(itemList, itemType)
    end
  elseif SortType == _G.Enum.Sequence.SEQUENCE_TIME_DOWN then
    list = self:SortTimeDown(itemList, itemType, IsReversalSort)
  end
  return list
end

function BagModuleData:ProcessFruitItemList(itemType, itemList)
  if itemType == _G.Enum.ItemLableType.ILT_PET_FRUIT then
    local fruitDic = {}
    local fruitCdDic = {}
    local deepCopylist = table.deepCopy(itemList, deepCopylist, true)
    local fruitList = {}
    for i = 1, #deepCopylist do
      local itemId = deepCopylist[i].id
      local conf = _G.DataConfigManager:GetBagItemConf(itemId)
      deepCopylist[i].conf = conf
      local fruitTimestamp = deepCopylist[i].fruit_active_timestamp
      local isNotCd = _G.NRCModuleManager:DoCmd(_G.SleepingOwlModuleCmd.OnGetFruitCd, fruitTimestamp)
      if isNotCd then
        if fruitDic[itemId] then
          fruitDic[itemId].num = fruitDic[itemId].num + 1
        else
          fruitDic[itemId] = deepCopylist[i]
        end
      elseif not fruitCdDic[fruitTimestamp] then
        fruitCdDic[fruitTimestamp] = {}
        fruitCdDic[fruitTimestamp][itemId] = deepCopylist[i]
      elseif not fruitCdDic[fruitTimestamp][itemId] then
        fruitCdDic[fruitTimestamp][itemId] = deepCopylist[i]
      else
        fruitCdDic[fruitTimestamp][itemId].num = fruitCdDic[fruitTimestamp][itemId].num + 1
      end
    end
    for _, TimestampFruits in pairs(fruitCdDic) do
      for _, value in pairs(TimestampFruits) do
        table.insert(fruitList, value)
      end
    end
    for key, value in pairs(fruitDic) do
      table.insert(fruitList, value)
    end
    if #fruitList > 0 then
      return fruitList
    end
  end
  return itemList
end

function BagModuleData:IsRemoveEggItem(item)
  if item.type == _G.ProtoEnum.BagItemType.BI_PET_EGG then
    local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
    for k = 1, #backpackEggList do
      local eggInfo = backpackEggList[k]
      if eggInfo.gid == item.gid then
        return true
      end
    end
  end
  return false
end

function BagModuleData:SortDefault(itemList, itemType)
  local showList = {}
  local bagItemConfDic = table.new(0, #itemList)
  local ballConfDic = table.new(0, #itemList)
  if itemList then
    for i, item in pairs(itemList) do
      local conf = item.conf or item.itemInfo.conf
      if conf and 1 == conf.can_see and self:IsRemoveEggItem(item) == false then
        bagItemConfDic[conf.id] = conf
        table.insert(showList, item)
        if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
          ballConfDic[conf.id] = _G.DataConfigManager:GetBallConf(conf.id)
        end
      end
    end
    if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
      table.sort(showList, function(l1, l2)
        local ballConf_1 = ballConfDic[l1.id or l1.itemInfo.id]
        local ballConf_2 = ballConfDic[l2.id or l2.itemInfo.id]
        if ballConf_1 and ballConf_2 then
          return ballConf_1.ball_list_priority < ballConf_2.ball_list_priority
        else
          local BagItemConf_1 = l1.conf or l1.itemInfo.conf
          local BagItemConf_2 = l2.conf or l2.itemInfo.conf
          return BagItemConf_1.sort_id < BagItemConf_2.sort_id
        end
      end)
      return self:OnGetBallSortList(showList)
    else
      table.sort(showList, function(l1, l2)
        local BagItemConf_1 = bagItemConfDic[l1.id]
        local BagItemConf_2 = bagItemConfDic[l2.id]
        return BagItemConf_1.sort_id < BagItemConf_2.sort_id
      end)
      return showList
    end
  end
end

function BagModuleData:ReversalSortDefault(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  local ballConfDic = table.new(0, #itemList)
  for i, item in pairs(itemList) do
    local conf = _G.DataConfigManager:GetBagItemConf(item.id)
    if 1 == conf.can_see and self:IsRemoveEggItem(item) == false then
      bagConfDic[conf.id] = conf
      table.insert(showList, item)
      if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
        ballConfDic[conf.id] = _G.DataConfigManager:GetBallConf(conf.id)
      end
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    table.sort(showList, function(l1, l2)
      local ballConf_1 = ballConfDic[l1.id]
      local ballConf_2 = ballConfDic[l2.id]
      if ballConf_1 and ballConf_2 then
        return ballConf_1.ball_list_priority > ballConf_2.ball_list_priority
      else
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id > BagItemConf_2.sort_id
      end
    end)
    return self:OnGetBallSortList(showList)
  else
    table.sort(showList, function(l1, l2)
      local BagItemConf_1 = bagConfDic[l1.id]
      local BagItemConf_2 = bagConfDic[l2.id]
      return BagItemConf_1.sort_id > BagItemConf_2.sort_id
    end)
    return showList
  end
end

function BagModuleData:SortQualityUp(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id < BagItemConf_2.sort_id
      else
        return l1.quality < l2.quality
      end
    end)
  else
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id < BagItemConf_2.sort_id
      else
        return l1.quality < l2.quality
      end
    end)
  end
  return showList
end

function BagModuleData:ReversalSortQualityUp(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id > BagItemConf_2.sort_id
      else
        return l1.quality > l2.quality
      end
    end)
  else
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id > BagItemConf_2.sort_id
      else
        return l1.quality > l2.quality
      end
    end)
  end
  return showList
end

function BagModuleData:SortQualityDown(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id > BagItemConf_2.sort_id
      else
        return l1.quality > l2.quality
      end
    end)
    return self:OnGetBallSortList(showList)
  else
    table.sort(showList, function(l1, l2)
      local l1Quality = l1.quality
      local l2Quality = l2.quality
      if l1.egg_data and l1.egg_data.precious_egg_type and l1.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
        l1Quality = 5
      end
      if l2.egg_data and l2.egg_data.precious_egg_type and l2.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
        l2Quality = 5
      end
      if l1Quality == l2Quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id > BagItemConf_2.sort_id
      else
        return l1Quality > l2Quality
      end
    end)
    return showList
  end
end

function BagModuleData:ReversalSortQualityDown(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    table.sort(showList, function(l1, l2)
      if l1.quality == l2.quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id < BagItemConf_2.sort_id
      else
        return l1.quality < l2.quality
      end
    end)
    return self:OnGetBallSortList(showList)
  else
    table.sort(showList, function(l1, l2)
      local l1Quality = l1.quality
      local l2Quality = l2.quality
      if l1.egg_data and l1.egg_data.precious_egg_type and l1.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
        l1Quality = 5
      end
      if l2.egg_data and l2.egg_data.precious_egg_type and l2.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
        l2Quality = 5
      end
      if l1Quality == l2Quality then
        local BagItemConf_1 = bagConfDic[l1.id]
        local BagItemConf_2 = bagConfDic[l2.id]
        return BagItemConf_1.sort_id < BagItemConf_2.sort_id
      else
        return l1Quality < l2Quality
      end
    end)
    return showList
  end
end

function BagModuleData:GetEggTypeSortDic()
  if self.eggTypeSortDic == nil then
    self.eggTypeSortDic = {}
    local confs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.EGG_TYPE_CONF)
    if confs then
      local eggTypeConfs = confs:GetAllDatas()
      for i, v in pairs(eggTypeConfs) do
        self.eggTypeSortDic[v.precious_egg_type] = v.display_order
      end
    end
  end
  return self.eggTypeSortDic
end

function BagModuleData:SortEggQualityDown(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  local petEggConfigDic = table.new(0, #itemList)
  local eggTypeSortDic = self:GetEggTypeSortDic()
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
      local petEggConfigType, petEggConfig = PetUtils.GetPetEggConfigTypeByGID(itemList[i].gid)
      local eggType = petEggConfig and petEggConfig.precious_egg_type or _G.Enum.PreciousEggType.PET_NONE
      petEggConfigDic[itemList[i].gid] = {PetEggConfigType = petEggConfigType, EggType = eggType}
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_PET_EGG then
    table.sort(showList, function(l1, l2)
      local l1Quality = l1.quality
      local l2Quality = l2.quality
      local l1PetEggConfigType = petEggConfigDic[l1.gid].PetEggConfigType
      local l2PetEggConfigType = petEggConfigDic[l2.gid].PetEggConfigType
      local l1EggType = l1.egg_data and l1.egg_data.precious_egg_type
      local l2EggType = l2.egg_data and l2.egg_data.precious_egg_type
      if nil == l1EggType and l1PetEggConfigType then
        l1EggType = petEggConfigDic[l1.gid].EggType
      end
      if nil == l2EggType and l2PetEggConfigType then
        l2EggType = petEggConfigDic[l2.gid].EggType
      end
      if l1EggType == _G.Enum.PreciousEggType.PET_PRECIOUS then
        l1Quality = 5
      end
      if l2EggType == _G.Enum.PreciousEggType.PET_PRECIOUS then
        l2Quality = 5
      end
      local l1TypeSort = eggTypeSortDic[l1EggType] or 9999999
      local l2TypeSort = eggTypeSortDic[l2EggType] or 9999999
      if l1TypeSort == l2TypeSort then
        if l1Quality == l2Quality then
          local BagItemConf_1 = bagConfDic[l1.id]
          local BagItemConf_2 = bagConfDic[l2.id]
          if BagItemConf_1.sort_id == BagItemConf_2.sort_id then
            return l1.update_time > l2.update_time
          else
            return BagItemConf_1.sort_id < BagItemConf_2.sort_id
          end
        else
          return l1Quality > l2Quality
        end
      else
        return l1TypeSort < l2TypeSort
      end
    end)
  end
  return showList
end

function BagModuleData:ReversalSortEggQualityDown(itemList, itemType)
  local showList = {}
  local bagConfDic = table.new(0, #itemList)
  local petEggConfigDic = table.new(0, #itemList)
  local eggTypeSortDic = self:GetEggTypeSortDic()
  for i = 1, #itemList do
    local qualityList
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      qualityList = {
        quality = bagItemConf.item_quality
      }
      itemList[i].quality = bagItemConf.item_quality
      table.insert(showList, itemList[i])
      bagConfDic[bagItemConf.id] = bagItemConf
      local petEggConfigType, petEggConfig = PetUtils.GetPetEggConfigTypeByGID(itemList[i].gid)
      local eggType = petEggConfig and petEggConfig.precious_egg_type or _G.Enum.PreciousEggType.PET_NONE
      petEggConfigDic[itemList[i].gid] = {PetEggConfigType = petEggConfigType, EggType = eggType}
    end
  end
  if itemType == _G.Enum.ItemLableType.ILT_PET_EGG then
    table.sort(showList, function(l1, l2)
      local l1Quality = l1.quality
      local l2Quality = l2.quality
      local l1PetEggConfigType = petEggConfigDic[l1.gid].PetEggConfigType
      local l2PetEggConfigType = petEggConfigDic[l2.gid].PetEggConfigType
      local l1EggType = l1.egg_data and l1.egg_data.precious_egg_type
      local l2EggType = l2.egg_data and l2.egg_data.precious_egg_type
      if nil == l1EggType and l1PetEggConfigType then
        l1EggType = petEggConfigDic[l1.gid].EggType
      end
      if nil == l2EggType and l2PetEggConfigType then
        l2EggType = petEggConfigDic[l2.gid].EggType
      end
      if l1EggType == _G.Enum.PreciousEggType.PET_PRECIOUS then
        l1Quality = 5
      end
      if l2EggType == _G.Enum.PreciousEggType.PET_PRECIOUS then
        l2Quality = 5
      end
      local l1TypeSort = eggTypeSortDic[l1EggType] or 9999999
      local l2TypeSort = eggTypeSortDic[l2EggType] or 9999999
      if l1TypeSort == l2TypeSort then
        if l1Quality == l2Quality then
          local BagItemConf_1 = bagConfDic[l1.id]
          local BagItemConf_2 = bagConfDic[l2.id]
          if BagItemConf_1.sort_id == BagItemConf_2.sort_id then
            return l1.update_time < l2.update_time
          else
            return BagItemConf_1.sort_id > BagItemConf_2.sort_id
          end
        else
          return l1Quality < l2Quality
        end
      else
        return l1TypeSort > l2TypeSort
      end
    end)
  end
  return showList
end

function BagModuleData:SortTimeDown(itemList, itemType, isReversalSort)
  local showList = {}
  for i = 1, #itemList do
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
    if 1 == bagItemConf.can_see and self:IsRemoveEggItem(itemList[i]) == false then
      table.insert(showList, itemList[i])
    end
  end
  table.sort(showList, function(l1, l2)
    if not isReversalSort then
      return l1.update_time > l2.update_time
    else
      return l1.update_time < l2.update_time
    end
  end)
  return showList
end

function BagModuleData:GetBagItemTypeNumByType(type)
  local items = self:GetBagItemArrByType(type)
  return #items
end

function BagModuleData:GetBagItemNumByType(type)
  local items = self:GetBagItemArrByType(type)
  local num = 0
  if nil ~= items then
    for k, v in pairs(items) do
      if not self:IsRemoveEggItem(v) then
        num = num + v.num
      end
    end
  end
  return num
end

function BagModuleData:GetBagItemNumInBagByType(type)
  local items = self:GetBagItemArrByType(type)
  local num = 0
  if nil ~= items then
    for k, v in pairs(items) do
      local can_see = true
      if v.conf then
        can_see = v.conf and 1 == v.conf.can_see or false
      end
      if not self:IsRemoveEggItem(v) and can_see then
        num = num + v.num
      end
    end
  end
  return num
end

function BagModuleData:GetSortType(itemTypeID)
  local sortConf = _G.DataConfigManager:GetItemLableTypeConf(itemTypeID)
end

function BagModuleData:UseAction(actionType)
end

function BagModuleData:GetBagItemByLableType(lable_type, IsFilterBag)
  if not self.BagInfo then
    return nil, -1
  end
  if not self.BagInfo.item_list then
    return nil, -1
  end
  local lable_data = self.itemLableTypeMap[lable_type]
  local bagItem = lable_data and lable_data.items and table.new(#lable_data.items) or {}
  if lable_data and lable_data.items then
    for _, item in ipairs(lable_data.items) do
      if item then
        item.IsFirstOpenPanel = self.IsFirstOpenPanel
        item.FirstOpenPanelId = self.FirstOpenPanelId
        table.insert(bagItem, item)
      end
    end
  end
  if lable_type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
    if self.Canfilter then
      self.Canfilter = false
      local isFilter = #self.FilterPetCondition > 0 or #self.FilterDepartCondition > 0 or #self.FilterClassifyCondition > 0
      bagItem = PetUtils.FilterPet(self.FilterPetCondition, bagItem)
      bagItem = PetUtils.FilterDepart(self.FilterDepartCondition, bagItem)
      bagItem = PetUtils.FilterClassify(self.FilterClassifyCondition, bagItem)
      self.PetFilters = bagItem
    else
      return self.PetFilters
    end
  end
  if lable_type == Enum.ItemLableType.ILT_FURNITURE then
    self._FurnitureDisplayNumInTab = {}
    self._FurnitureDisplayNumInTabDecompose = {}
    local bInFurnitureDecomposeMode = self:InFurnitureDecomposeMode()
    local HomeData = NRCModuleManager:GetModule("HomeModule"):GetData()
    for i = #bagItem, 1, -1 do
      local item = bagItem[i]
      local bRemoveThisItem = false
      self:countFurnitureDisplayNumInTab(self._FurnitureDisplayNumInTab, item, HomeData)
      local ItemConf = _G.DataConfigManager:GetFurnitureItemConf(item.id, true)
      local bDontShowInDecomposeMode = not ItemConf or ItemConf and ItemConf.Ban_Recycle ~= true
      if bDontShowInDecomposeMode then
        if bInFurnitureDecomposeMode then
          bRemoveThisItem = true
        end
      else
        self:countFurnitureDisplayNumInTab(self._FurnitureDisplayNumInTabDecompose, item, HomeData)
      end
      ItemConf = ItemConf or _G.DataConfigManager:GetInteriorFinishConf(item.id)
      if self._FurnitureFilterTabMap and next(self._FurnitureFilterTabMap) then
        local TabId = ItemConf and HomeData and ItemConf.classification
        local bFilterToShow = false
        if TabId then
          bFilterToShow = self._FurnitureFilterTabMap[TabId]
          if not bFilterToShow then
            local firstTabId = HomeData:GetFirstTabId(TabId)
            if firstTabId then
              bFilterToShow = self._FurnitureFilterTabMap[firstTabId]
            end
          end
        end
        if not TabId then
          bRemoveThisItem = true
        elseif not bFilterToShow then
          bRemoveThisItem = true
        end
      end
      if bRemoveThisItem then
        table.remove(bagItem, i)
      end
    end
  end
  return bagItem
end

function BagModuleData:GetBagEggItemWithoutHathcing()
  local AllEggItemList = self:GetBagItemByLableType(_G.Enum.ItemLableType.ILT_PET_EGG)
  local RetList = {}
  for _, EggItem in pairs(AllEggItemList or {}) do
    if EggItem and not self:IsRemoveEggItem(EggItem) then
      table.insert(RetList, EggItem)
    end
  end
  return RetList
end

function BagModuleData:SetIsFirstOpenPanel(_IsFirstOpenPanel)
  self.IsFirstOpenPanel = _IsFirstOpenPanel
end

function BagModuleData:SetFirstOpenPanelId(ID)
  self.FirstOpenPanelId = ID
end

function BagModuleData:GetFirstOpenPanelId()
  return self.FirstOpenPanelId
end

function BagModuleData:GetIsFirstOpenPanel()
  return self.IsFirstOpenPanel
end

function BagModuleData:SetDisplayMode(displayMode)
  self.displayMode = displayMode
end

function BagModuleData:GetDisplayMode()
  return self.displayMode
end

function BagModuleData:SetCurSelectedItemDataBattle(data)
  self.curSelectedItemDataBattle = data
end

function BagModuleData:GetCurSelectedItemDataBattle()
  return self.curSelectedItemDataBattle
end

function BagModuleData:GetEquipedPlayerSkill()
  local PlayerSkill = self:GetBagItemByLableType(Enum.ItemLableType.ILT_PLAYERSKILL)
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  for i, _PlayerSkill in ipairs(PlayerSkill) do
    if teamInfo and teamInfo.teams and teamInfo.teams[teamInfo.main_team_idx + 1] and _PlayerSkill.gid == teamInfo.teams[teamInfo.main_team_idx + 1].role_magic_gid then
      return _PlayerSkill
    end
  end
  return nil
end

function BagModuleData:SetEvolutionarySelectedItem(itemData)
  self.curEvolutionarySelectedItem = itemData
end

function BagModuleData:GetEvolutionarySelectedItem()
  return self.curEvolutionarySelectedItem
end

function BagModuleData:InitializeConf()
  local MedalBondConfList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MEDAL_BOND_CONF):GetAllDatas()
  for i, MedalBondConf in pairs(MedalBondConfList) do
    if not self.MedalBondConfList[MedalBondConf.medal_id] then
      self.MedalBondConfList[MedalBondConf.medal_id] = {}
    end
    for j, PetBaseId in pairs(MedalBondConf.petbase_id) do
      table.insert(self.MedalBondConfList[MedalBondConf.medal_id], PetBaseId)
    end
  end
end

function BagModuleData:GetMedalPetList(MedalConf)
  local PetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  local PetDataList = {}
  if MedalConf.medal_type == Enum.MedalType.MT_BOND then
    if self.MedalBondConfList[MedalConf.id] and #self.MedalBondConfList[MedalConf.id] > 0 then
      for i, Pet in ipairs(PetList) do
        for j, BaseId in ipairs(self.MedalBondConfList[MedalConf.id]) do
          if Pet.base_conf_id == BaseId then
            table.insert(PetDataList, Pet)
          end
        end
      end
    end
  else
    PetDataList = PetList
  end
  return PetDataList
end

function BagModuleData:GetNoEquipmentMedalPet(PetDataList, MedalConf)
  local PetList = {}
  for i, PetData in ipairs(PetDataList) do
    local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(PetData.gid)
    local IsEquipment = false
    if MedalList then
      for j, Medal in ipairs(MedalList) do
        if Medal.conf_id == MedalConf.id then
          IsEquipment = true
          break
        end
      end
    end
    if not IsEquipment then
      table.insert(PetList, PetData)
    end
  end
  return PetList
end

function BagModuleData:SetGiftVoucherData(giftVoucherData)
  self.giftVoucherData = giftVoucherData
end

function BagModuleData:GetGiftVoucherData()
  return self.giftVoucherData
end

function BagModuleData:HasGiftVoucherData()
  return self.giftVoucherData ~= nil
end

function BagModuleData:GetGiftVoucherItemId()
  if self.giftVoucherData and self.giftVoucherData.bagItemConf then
    return self.giftVoucherData.bagItemConf.id
  end
  return nil
end

function BagModuleData:GetGiftVoucherGid()
  if self.giftVoucherData then
    return self.giftVoucherData.gid
  end
  return nil
end

function BagModuleData:GetGiftVoucherExpireStatus()
  if self.giftVoucherData then
    return self.giftVoucherData.expireStatus
  end
  return nil
end

function BagModuleData:CalculateExpireTimeDifference(expireTimeStr)
  if not expireTimeStr or "" == expireTimeStr then
    return 0
  end
  local year, month, day, hour, minute, second = expireTimeStr:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  if not year then
    Log.Error("\230\151\182\233\151\180\230\160\188\229\188\143\233\148\153\232\175\175: " .. expireTimeStr)
    return 0
  end
  local expireTimestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(minute),
    sec = tonumber(second)
  })
  local currentTimestamp = _G.ZoneServer:GetServerTime() / 1000
  local timeDifference = expireTimestamp - currentTimestamp
  local hoursDifference = timeDifference / 3600
  return hoursDifference
end

function BagModuleData:CheckItemExpireStatus(bagItem, expireThreshold)
  if not (bagItem and bagItem.expire_time) or bagItem.expire_time == "" then
    Log.Info("BagModuleData:CheckItemExpireStatus bagItem is nil or expire_time is nil")
    return {
      isExpired = false,
      isNearExpire = false,
      hoursRemaining = 0
    }
  end
  local thresholdHours = expireThreshold and expireThreshold.num or 24
  local hoursRemaining = self:CalculateExpireTimeDifference(bagItem.expire_time)
  return {
    isExpired = hoursRemaining <= 0,
    isNearExpire = hoursRemaining > 0 and thresholdHours > hoursRemaining,
    hoursRemaining = hoursRemaining
  }
end

function BagModuleData:GetPlayerThrowBallList()
  local worldUseList = self:GetBagItemByLableType(_G.Enum.ItemLableType.ILT_USEFUL_ITEM)
  worldUseList = worldUseList or self.EquipBallList
  if not worldUseList or 0 == #worldUseList then
    return {}
  end
  local ballList = table.new(#worldUseList)
  for _, v in ipairs(worldUseList) do
    if v.type == _G.Enum.BagItemType.BI_PET_BALL then
      local ballConf = _G.DataConfigManager:GetBallConf(v.id)
      if ballConf and ballConf.bigworld_catch ~= false and v.num > 0 then
        v.bag_item_flags = 1
        v.ball_list_priority = ballConf.ball_list_priority
        table.insert(ballList, v)
      end
    end
  end
  table.sort(ballList, function(a, b)
    local priorityA = a.ball_list_priority
    local priorityB = b.ball_list_priority
    if priorityA and priorityB then
      return priorityA < priorityB
    end
  end)
  return ballList
end

function BagModuleData:UpdateEquipItemNum(num)
  self.curEquipItemData.num = num
end

function BagModuleData:ResetSortRule()
  self.SortSelectIndex = 1
  self.AllSortSelectIndex = {}
  self.SortIndex = _G.Enum.Sequence.SEQUENCE_DEFAULT
  self.TabSortList = {}
end

function BagModuleData:OnZoneGetBagItemIdFlagReq()
  local req = _G.ProtoMessage:newZoneGetBagItemIdFlagReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_ITEM_ID_FLAG_REQ, req, self, self.OnZoneGetBagItemIdFlagRsp, false)
end

function BagModuleData:OnZoneGetBagItemIdFlagRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.bag_item_id_flags and rsp.bag_item_id_flags.bag_flag_items then
      self:SaveBallCollectList(rsp.bag_item_id_flags.bag_flag_items)
    else
      self.BallCollectMap = {}
      self.BallCollectList = {}
    end
  else
    self.BallCollectMap = nil
    self.BallCollectList = nil
  end
end

function BagModuleData:SaveBallCollectList(bag_flag_items)
  self.BallCollectList = bag_flag_items
  self.BallCollectMap = {}
  if self.BallCollectList then
    for index, value in pairs(self.BallCollectList) do
      if value.items then
        for _, v in ipairs(value.items) do
          self.BallCollectMap[v.id] = index
        end
      end
    end
  end
end

function BagModuleData:OnCheckBallIsCollectOptimization(ballId)
  if self.BallCollectMap and self.BallCollectMap[ballId] then
    local index = self.BallCollectMap[ballId]
    local v = self.BallCollectList[index]
    if v.items then
      for _, v1 in ipairs(v.items) do
        if v1.id == ballId and v1.flag == ProtoEnum.BagItemIdFlag.PET_BALL_COLLECTED then
          return true
        end
      end
    end
  end
  return false
end

function BagModuleData:OnGetBallSortList(showList)
  local resultList = {}
  local collectList = {}
  local normalList = {}
  for _, v in ipairs(showList) do
    if self:OnCheckBallIsCollectOptimization(v.id or v.itemInfo.id) then
      table.insert(collectList, v)
    else
      table.insert(normalList, v)
    end
  end
  table.move(collectList, 1, #collectList, 1, resultList)
  table.move(normalList, 1, #normalList, #resultList + 1, resultList)
  return resultList
end

function BagModuleData:OnGetBallNormalSortList(itemList)
  return self:SortDefault(itemList, _G.Enum.ItemLableType.ILT_USEFUL_ITEM)
end

function BagModuleData:SetTabSortListSortType(itemType, SortType)
  if not self.TabSortList then
    self.TabSortList = {}
  end
  if self.TabSortList[itemType] then
    self.TabSortList[itemType].SortType = SortType
  else
    self.TabSortList[itemType] = {SortType = SortType, IsReversalSort = false}
  end
end

function BagModuleData:SetTabSortListIsReversalSort(itemType, IsReversalSort)
  if not self.TabSortList then
    self.TabSortList = {}
  end
  if self.TabSortList[itemType] then
    self.TabSortList[itemType].IsReversalSort = IsReversalSort
  else
    self.TabSortList[itemType] = {
      SortType = self.curSortList[self.SortSelectIndex],
      IsReversalSort = false
    }
  end
end

function BagModuleData:GetTabSortType(itemType)
  if self.TabSortList and self.TabSortList[itemType] and self.TabSortList[itemType].SortType then
    return self.TabSortList[itemType].SortType
  else
    return self.curSortList[self.SortSelectIndex]
  end
end

function BagModuleData:GetTabSortIsReversalSort(itemType)
  if self.TabSortList and self.TabSortList[itemType] then
    return self.TabSortList[itemType].IsReversalSort
  else
    return false
  end
end

function BagModuleData:PreLoadAllBallRes()
  if self.EquipBallList then
    for _, item in ipairs(self.EquipBallList) do
      _G.NRCModuleManager:DoCmd(NPCModuleCmd.CreateAllBall, item.id)
    end
  end
end

return BagModuleData
