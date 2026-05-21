local BigMapModuleEvent = require("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local UMG_Map_Magic_C = _G.NRCViewBase:Extend("UMG_Map_Magic_C")

function UMG_Map_Magic_C:OnActive()
end

function UMG_Map_Magic_C:OnDeactive()
end

function UMG_Map_Magic_C:OnAddEventListener()
  self:RegisterEvent(self, BigMapModuleEvent.UpdateCampFruitInfo, self.OnUpdateCampFruitInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Map_Magic_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
end

function UMG_Map_Magic_C:OnConstruct()
  self.mapShowPetList = {}
  self.HasRsp = true
  self.PetList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnAddEventListener()
end

function UMG_Map_Magic_C:OnReConnect()
  if not self.HasRsp then
  end
end

function UMG_Map_Magic_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
end

function UMG_Map_Magic_C:UpdateInfo(_npcInfo, bOwlSanctuary)
  if nil == bOwlSanctuary then
    bOwlSanctuary = false
  end
  self.npcInfo = _npcInfo
  self.bOwlSanctuary = bOwlSanctuary
  local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(_npcInfo.world_map_cfg_id)
  if worldMapCfg then
    self.describe:SetText(worldMapCfg.worldmap_npc_des or "")
  end
  self.CanvasPanel_39:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if bOwlSanctuary then
    local allPlayerFruitInfo = {}
    local TempAllPlayerFruitInfo = _G.DataModelMgr.PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
    if nil == TempAllPlayerFruitInfo or nil == next(TempAllPlayerFruitInfo) then
      self.UnLockSwitcher:SetActiveWidgetIndex(1)
      return
    else
      for _, OwlSanctuary in pairs(TempAllPlayerFruitInfo) do
        local uin = OwlSanctuary.uin
        for _, OwlSanctuaryInfo in pairs(OwlSanctuary.owl_sanctuarys) do
          local FruitInfo = ProtoMessage:newSpaceAct_OwlSanctuaryFruitInfoUpdate()
          FruitInfo.owl_content_id = OwlSanctuaryInfo.npc_content_id
          FruitInfo.fruit_infos = {}
          if nil ~= next(OwlSanctuaryInfo.fruit_brief_infos) then
            for key, value in ipairs(OwlSanctuaryInfo.fruit_brief_infos) do
              FruitInfo.fruit_infos[key] = value
            end
          end
          FruitInfo.uin = uin
          allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] = allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] or {}
          allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id][uin] = FruitInfo
        end
      end
    end
    local sortedPlayerArrays = {}
    for owl_content_id, OwlSanctuaryFruitInfo in pairs(allPlayerFruitInfo) do
      for uin, FruitInfo in pairs(OwlSanctuaryFruitInfo) do
        local visitIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, uin) or nil
        FruitInfo.visit_index = visitIndex
      end
      local playerArray = {}
      for uin, FruitInfo in pairs(OwlSanctuaryFruitInfo) do
        table.insert(playerArray, {uin = uin, fruitInfo = FruitInfo})
      end
      table.sort(playerArray, function(a, b)
        local visitIndexA = a.fruitInfo.visit_index
        local visitIndexB = b.fruitInfo.visit_index
        if nil == visitIndexA and nil ~= visitIndexB then
          return false
        elseif nil ~= visitIndexA and nil == visitIndexB then
          return true
        elseif nil == visitIndexA and nil == visitIndexB then
          return false
        else
          return visitIndexA < visitIndexB
        end
      end)
      sortedPlayerArrays[owl_content_id] = playerArray
    end
    local targetOwlContentId = self.npcInfo.npc_refresh_id
    local hasAnyFruitInfo = false
    local simulateCampFruitNpcInfo = ProtoMessage:newCampFruitNpcInfo()
    local simulateOwlSanctuaryFruitNpcInfo = ProtoMessage:newOwlSanctuaryFruitNpcInfo()
    simulateOwlSanctuaryFruitNpcInfo.owl_sanctuary_content_id = targetOwlContentId
    simulateOwlSanctuaryFruitNpcInfo.NpcInfo = {}
    local sortedPlayerArray = sortedPlayerArrays[targetOwlContentId]
    local tempNpcIds = {}
    if sortedPlayerArray then
      for v, playerData in pairs(sortedPlayerArray) do
        local owlSanctuaryFruitInfo = playerData.fruitInfo
        local FruitUin = playerData.uin
        hasAnyFruitInfo = true
        if owlSanctuaryFruitInfo.fruit_infos then
          for _, fruitBriefInfo in pairs(owlSanctuaryFruitInfo.fruit_infos) do
            if 0 ~= fruitBriefInfo.fruit_id then
              if fruitBriefInfo.npc_id == nil or 0 == #fruitBriefInfo.npc_id then
                local petBaseId = _G.NRCModuleManager:DoCmd(SleepingOwlModuleCmd.GetPetbaseIdByFruitId, fruitBriefInfo.fruit_id, owlSanctuaryFruitInfo.owl_content_id)
                local petBaseConf = DataConfigManager:GetPetbaseConf(petBaseId, true)
                if petBaseConf and petBaseConf.npc_id then
                  local info = {
                    pet_base_id = petBaseId,
                    npc_id = petBaseConf.npc_id,
                    uin = FruitUin,
                    fruit_active_timestamp = fruitBriefInfo.fruit_active_timestamp,
                    slot_active_timestamp = fruitBriefInfo.slot_active_timestamp
                  }
                  table.insert(tempNpcIds, info)
                end
              else
                local info = {
                  pet_base_id = 0,
                  npc_id = fruitBriefInfo.npc_id[1],
                  uin = FruitUin,
                  fruit_active_timestamp = fruitBriefInfo.fruit_active_timestamp,
                  slot_active_timestamp = fruitBriefInfo.slot_active_timestamp
                }
                table.insert(tempNpcIds, info)
              end
            else
              local info = {
                pet_base_id = 0,
                npc_id = 0,
                uin = FruitUin,
                fruit_active_timestamp = fruitBriefInfo.fruit_active_timestamp or 0,
                slot_active_timestamp = fruitBriefInfo.slot_active_timestamp or 0
              }
              table.insert(tempNpcIds, info)
            end
          end
        end
      end
    end
    local owlSanctuaryConf = DataConfigManager:GetOwlSanctuaryConf(self.npcInfo.npc_refresh_id)
    if nil == owlSanctuaryConf then
      return
    end
    local SlotNum = owlSanctuaryConf.slot_num
    local sortedNpcIds = {}
    for groupStart = 1, #tempNpcIds, SlotNum do
      local groupEnd = math.min(groupStart + SlotNum - 1, #tempNpcIds)
      local group = {}
      for i = groupStart, groupEnd do
        table.insert(group, tempNpcIds[i])
      end
      table.sort(group, function(a, b)
        local aId = type(a) == "table" and a.npc_id or a
        local bId = type(b) == "table" and b.npc_id or b
        if 0 == aId and 0 ~= bId then
          return false
        elseif 0 ~= aId and 0 == bId then
          return true
        else
          if a.pet_base_id and b.pet_base_id and 0 ~= a.pet_base_id and 0 ~= b.pet_base_id then
            return a.pet_base_id < b.pet_base_id
          end
          return false
        end
      end)
      for _, npcId in pairs(group) do
        table.insert(sortedNpcIds, npcId)
      end
    end
    for _, npcInfo in pairs(sortedNpcIds) do
      if "table" == type(npcInfo) then
        table.insert(simulateOwlSanctuaryFruitNpcInfo.NpcInfo, npcInfo)
      end
    end
    if not hasAnyFruitInfo then
      self.UnLockSwitcher:SetActiveWidgetIndex(1)
      return
    end
    table.insert(simulateCampFruitNpcInfo.owl_sanctuary_fruit_npc_info, simulateOwlSanctuaryFruitNpcInfo)
    if owlSanctuaryConf and owlSanctuaryConf.advantage_type and #owlSanctuaryConf.advantage_type > 0 then
      self.CanvasPanel_39:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.GoodAndBad:OnActive(owlSanctuaryConf.advantage_type)
    else
      self.CanvasPanel_39:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:OnShowPetList(simulateCampFruitNpcInfo, true)
  else
    local CampingInfo = _G.DataConfigManager:GetCampConf(_npcInfo.npc_refresh_id)
    if nil == CampingInfo then
      return
    end
    local AreaInfo = _G.DataConfigManager:GetAreaFuncConf(CampingInfo.area_id)
    self.CampingInfo = CampingInfo
    self.Place_Names:SetText(AreaInfo.name)
    if _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if not Player:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_DUNGEON) then
        if self.module then
          local CampFruitNpcInfo = self.module.data:GetCampFruitNpcInfoByCampcontentId(_npcInfo.npc_refresh_id)
          self:OnShowPetList(CampFruitNpcInfo, false)
        end
      else
        self.fruitDatas = {}
        self.UnLockSwitcher:SetActiveWidgetIndex(1)
      end
    else
      self.UnLockSwitcher:SetActiveWidgetIndex(1)
    end
  end
end

function UMG_Map_Magic_C:OnShowPetList(npcInfo, IsOwlSanctuary)
  self.fruitNpcIds = {}
  if npcInfo and npcInfo.owl_sanctuary_fruit_npc_info then
    local owlFruitNpcInfos = npcInfo.owl_sanctuary_fruit_npc_info
    if owlFruitNpcInfos then
      for i = 1, #owlFruitNpcInfos do
        local owlFruitNpcInfo = owlFruitNpcInfos[i]
        if owlFruitNpcInfo.npc_id then
          for j = 1, #owlFruitNpcInfo.NpcInfo do
            table.insert(self.fruitNpcIds, owlFruitNpcInfo.NpcInfo[j])
          end
        end
      end
    end
  end
  self:GetPetInfo(self.npcInfo, IsOwlSanctuary)
end

function UMG_Map_Magic_C:CreatPetItemData(petBaseId, npcID, isFruit, bOwlSanctuary, index, fruitActiveTimestamp, slotActiveTimestamp, FruitUin)
  if bOwlSanctuary then
    return {
      bOwlSanctuary = bOwlSanctuary,
      isFruit = isFruit,
      petBaseId = 0,
      fruit_active_timestamp = fruitActiveTimestamp,
      slot_active_timestamp = slotActiveTimestamp,
      fruit_uin = FruitUin
    }
  end
  local data = {}
  local evoDatas = {}
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if not petbaseConf then
    Log.Error("petbaseConf is nil ")
    return
  end
  local evoId = petbaseConf.pet_evolution_id[1]
  local evoConf = _G.DataConfigManager:GetPetEvolutionConf(evoId)
  local evoIds = {}
  if nil == evoConf then
    Log.Error("id:", evoId, "\229\156\168PetEvolutionConf\228\184\173\230\178\161\230\156\137\233\133\141\231\189\174")
    return
  else
    local evoInfos = evoConf.evolution_chain
    for i = 1, #evoInfos do
      table.insert(evoIds, evoInfos[i].petbase_id)
    end
  end
  local isVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local isVisitOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
  for i = 1, #evoIds do
    local baseId = evoIds[i]
    local evoData = {}
    evoData.petBaseConfId = baseId
    if isVisitState and false == isVisitOwner then
      local accessHandbookPetDic = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAccessHandbookData)
      local record = accessHandbookPetDic and accessHandbookPetDic[baseId] or nil
      if record then
        evoData.state = record.status
      else
        evoData.state = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
      end
    else
      evoData.state = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetState, baseId)
    end
    local FirstStageBaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
    evoData.handbookId = FirstStageBaseConf.pictorial_book_id
    if 1 == FirstStageBaseConf.stage then
      data.FirstStageBaseConf = baseId
    end
    table.insert(evoDatas, evoData)
  end
  data.evoDatas = evoDatas
  data.petBaseConfId = petBaseId
  data.handbookId = _G.DataConfigManager:GetPetbaseConf(petBaseId).pictorial_book_id
  data.npcId = npcID
  data.CampId = self.npcInfo.npc_refresh_id
  data.isFruit = isFruit and 1 or 0
  data.index = index
  data.fruit_active_timestamp = fruitActiveTimestamp
  data.slot_active_timestamp = slotActiveTimestamp
  data.fruit_uin = FruitUin
  return data
end

function UMG_Map_Magic_C:GetPetInfo(_npcInfo, IsOwlSanctuary)
  local mapShowPetList = {}
  self.UnLockSwitcher:SetActiveWidgetIndex(0)
  if not self.bOwlSanctuary then
    local npcRefreshContentDatas = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetAllRefreshContentConfs)
    for k, npcRefreshContentData in pairs(npcRefreshContentDatas) do
      if npcRefreshContentData.belong_camp == _npcInfo.npc_refresh_id then
        local npcID = npcRefreshContentData.npc_id
        local npcInfoDatas = _G.DataConfigManager:GetNpcConf(npcID)
        if npcInfoDatas.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE then
          local petBaseId = npcInfoDatas.traverse_data_param[1]
          if not self:HasPetBaseId(petBaseId, mapShowPetList) and self:ShowInNPCInfoList(npcRefreshContentData.id) then
            local itemData = self:CreatPetItemData(petBaseId, npcID)
            if itemData then
              table.insert(mapShowPetList, itemData)
            end
          end
        end
      end
    end
  end
  self:SetFruitNpcDatas(mapShowPetList, IsOwlSanctuary)
  if #mapShowPetList > 0 then
    self.CanvasPanel_36:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasPanel_36:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    for _, v in ipairs(mapShowPetList) do
      local visIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, v.fruit_uin) or 0
      v.visIndex = visIndex
    end
  end
  self:SortData(mapShowPetList, function(a, b)
    if 1 == a.isFruit and 1 ~= b.isFruit then
      return true
    end
    if 1 == b.isFruit and 1 ~= a.isFruit then
      return false
    end
    if a.visIndex ~= b.visIndex then
      return a.visIndex < b.visIndex
    end
    local a_id = a.petBaseConfId or a.petBaseId
    local b_id = b.petBaseConfId or b.petBaseId
    if 0 == b_id then
      return true
    end
    if 0 == a_id then
      return false
    end
    return a_id < b_id
  end, 1, #mapShowPetList)
  self.PetList:InitGridView(mapShowPetList)
  self.PetList:SetVisibility(UE4.ESlateVisibility.Visible)
  self.mapShowPetList = mapShowPetList
end

function UMG_Map_Magic_C:SortData(data, func, start, stop)
  if stop <= start then
    return
  end
  local baseItem = data[start]
  local left = start
  local right = stop
  local bRight = true
  while left < right do
    if bRight then
      if not func(baseItem, data[right]) then
        data[left] = data[right]
        left = left + 1
        bRight = false
      else
        right = right - 1
      end
    elseif not func(data[left], baseItem) then
      data[right] = data[left]
      right = right - 1
      bRight = true
    else
      left = left + 1
    end
  end
  data[left] = baseItem
  self:SortData(data, func, start, left - 1)
  self:SortData(data, func, left + 1, stop)
end

function UMG_Map_Magic_C:SetFruitNpcDatas(mapShowPetList, IsOwlSanctuary)
  local fruitNpcCount = 0
  local newFruitItems = {}
  if self.fruitNpcIds and #self.fruitNpcIds > 0 then
    for i, NpcInfo in pairs(self.fruitNpcIds) do
      if type(i) == "number" then
        local FruitUin = NpcInfo.uin
        local npcid = NpcInfo.npc_id
        if type(npcid) == "table" then
          if next(npcid) then
            npcid = npcid[1]
          else
            npcid = 0
          end
        end
        if 0 ~= npcid then
          local npcId = npcid
          local npcInfoDatas = _G.DataConfigManager:GetNpcConf(npcId)
          if npcInfoDatas and npcInfoDatas.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE then
            local baseId = npcInfoDatas.traverse_data_param[1]
            local petBaseId = self:GetFirstStageBaseId(baseId)
            local bNotHasPetBaseId = self.bOwlSanctuary or not self:HasPetBaseId(petBaseId, mapShowPetList)
            local fruitActiveTimestamp = NpcInfo.fruit_active_timestamp
            local slotActiveTimestamp = NpcInfo.slot_active_timestamp
            if bNotHasPetBaseId then
              local HasFruit = false
              if IsOwlSanctuary then
                local itemData = self:CreatPetItemData(petBaseId, npcId, 1, nil, nil, fruitActiveTimestamp, slotActiveTimestamp, FruitUin)
                if itemData then
                  table.insert(mapShowPetList, itemData)
                end
              else
                newFruitItems[i] = newFruitItems[i] or {}
                HasFruit = self:HasFruitInfo(petBaseId, newFruitItems, FruitUin)
                if not HasFruit then
                  local itemData = self:CreatPetItemData(petBaseId, npcId, 1, nil, nil, fruitActiveTimestamp, slotActiveTimestamp, FruitUin)
                  if itemData then
                    table.insert(newFruitItems[i], itemData)
                  end
                end
              end
              if not HasFruit then
                fruitNpcCount = fruitNpcCount + 1
              end
            else
              for j = 1, #mapShowPetList do
                if self:GetFirstStageBaseId(mapShowPetList[j].petBaseConfId) == petBaseId then
                  mapShowPetList[j].isFruit = 1
                  local item = table.remove(mapShowPetList, j)
                  item.fruit_active_timestamp = fruitActiveTimestamp
                  item.slot_active_timestamp = slotActiveTimestamp
                  item.fruit_uin = FruitUin
                  table.insert(mapShowPetList, 1, item)
                  fruitNpcCount = fruitNpcCount + 1
                end
              end
            end
          end
        elseif 0 == NpcInfo.npc_id and IsOwlSanctuary then
          local itemData = self:CreatPetItemData(nil, nil, 1, true, nil, NpcInfo.fruit_active_timestamp, NpcInfo.slot_active_timestamp, FruitUin)
          if itemData then
            table.insert(mapShowPetList, itemData)
          end
          fruitNpcCount = fruitNpcCount + 1
        end
      end
    end
  end
  if not IsOwlSanctuary then
    local indices = {}
    for index, _ in pairs(newFruitItems) do
      if type(index) == "number" then
        table.insert(indices, index)
      end
    end
    table.sort(indices, function(a, b)
      return b < a
    end)
    for _, i in ipairs(indices) do
      local fruitItems = newFruitItems[i]
      if fruitItems and next(fruitItems) ~= nil then
        for k = #fruitItems, 1, -1 do
          if nil ~= fruitItems[k] then
            table.insert(mapShowPetList, 1, fruitItems[k])
          end
        end
      end
    end
  end
  if self.bOwlSanctuary and self.npcInfo and self.npcInfo.npc_refresh_id then
    local owlSanctuaryConf = DataConfigManager:GetOwlSanctuaryConf(self.npcInfo.npc_refresh_id)
    if nil == owlSanctuaryConf then
      return
    end
    for i = fruitNpcCount, owlSanctuaryConf.slot_num - 1 do
      table.insert(mapShowPetList, self:CreatPetItemData(nil, nil, 1, true, self.npcInfo.uin))
    end
  end
end

function UMG_Map_Magic_C:HasFruitInfo(petBaseId, newFruitItems, FruitUin)
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if not BaseConf then
    return false
  end
  local bookid = BaseConf.pictorial_book_id
  if 0 == bookid then
    return true
  end
  if next(newFruitItems) == nil then
    return false
  end
  for _, item in pairs(newFruitItems) do
    if type(item) == "table" then
      for _, entry in pairs(item) do
        local evoDatas = entry and entry.evoDatas
        if evoDatas and entry.fruit_uin == FruitUin then
          for _, evoDataK in pairs(evoDatas) do
            if evoDataK and evoDataK.petBaseConfId == petBaseId then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function UMG_Map_Magic_C:GetFirstStageBaseId(baseId)
  return self.module.data:GetFirstStageBaseId(baseId)
end

function UMG_Map_Magic_C:HasPetBaseId(baseId, table)
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
  if not BaseConf then
    return false
  end
  local bookid = BaseConf.pictorial_book_id
  if 0 == bookid then
    return true
  end
  if 0 == #table then
    return false
  end
  for i = 1, #table do
    local evoDatas = table[i].evoDatas or {}
    for j = 1, #evoDatas do
      if evoDatas[j].petBaseConfId == baseId then
        return true
      end
    end
  end
  return false
end

function UMG_Map_Magic_C:GetPetNum()
  return self.mapShowPetList and #self.mapShowPetList or 0
end

function UMG_Map_Magic_C:BuildRefreshContentIdToRulesMap()
  local ruleTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NPC_REFRESH_RULE_CONF)
  local ruleConfs = ruleTable:GetAllDatas()
  self.ContentIdToRuleMap = {}
  for _, conf in pairs(ruleConfs) do
    for _, content in ipairs(conf.contents) do
      self.ContentIdToRuleMap[content.content_id] = conf
    end
  end
end

function UMG_Map_Magic_C:GetContentIdToRuleMap()
  if self.ContentIdToRuleMap == nil then
    self:BuildRefreshContentIdToRulesMap()
  end
  return self.ContentIdToRuleMap
end

function UMG_Map_Magic_C:ShowInNPCInfoList(npcContentId)
  self:GetContentIdToRuleMap()
  local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local ruleCfg = self.ContentIdToRuleMap[npcContentId]
  if nil == ruleCfg then
    return true
  end
  if #ruleCfg.condition > 0 and ruleCfg.condition[1].condition_type == _G.Enum.TriggerConditionType.TRCT_ROLE_LEVEL then
    local lvLimit = string.split(ruleCfg.condition[1].condition_param, ";")
    if 2 == #lvLimit then
      if playerLv >= tonumber(lvLimit[1]) and playerLv <= tonumber(lvLimit[2]) then
        return true
      else
        return false
      end
    elseif playerLv >= tonumber(lvLimit[1]) then
      return true
    else
      return false
    end
  else
  end
  return true
end

function UMG_Map_Magic_C:OnUpdateCampFruitInfo(npcInfo)
  if self.bOwlSanctuary then
    return
  end
  self:OnShowPetList(npcInfo, false)
end

return UMG_Map_Magic_C
