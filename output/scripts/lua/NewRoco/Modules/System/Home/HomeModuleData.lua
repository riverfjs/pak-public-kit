local HomeModuleData = _G.NRCData:Extend("HomeModuleData")
local JsonUtils = require("Common.JsonUtils")
local LastProcessingFoodIdFileName = "NrcHomeLastFoodProcessingInfo"

function HomeModuleData:Ctor()
  self.SelectModeTabIndex = nil
  self.SelectTypeTabIndex = nil
  self.SetSelectItemIndex = nil
  self.EquippingSeed = 0
  self.EquippingSeedTabLevel = 1
  self.EquippingFood = nil
  self.bMeshEstablished = false
  self.canSendFriendReq = true
  NRCData.Ctor(self)
  self.ItemList = {}
  self.FirstTabs = {}
  self.TabIdToFurnitureDataList = {}
  self.FurnitureItemDataMap = {}
  self.DefaultInteriorFinishConfList = {}
  self.FurnitureAtlasInfo = {}
  self.FurnitureAtlasNum = 0
  self:InitHomeDefaultInteriorFinish()
  self:InitHomeTabs()
  self:InitHomeTasks()
  self:InitHomeStats()
  self:InitHomeMagicBan()
  self:InitFurnitureHandBook()
  self:InitGlobalConfigs()
  self:InitFunctionBan()
  self.HomePetList = {}
  self.pairNestAndPet = {}
  self.placedInteractiveFurniture = {}
  self.NPCActionOpenGuard = nil
  self.HomePlantGuardPetGid = nil
  self.allFoodProductionInfo = nil
  self.LastFoodProcessingId = 0
end

function HomeModuleData:InitFunctionBan()
  self.FarmMainUIIcons = {}
  self.OtherHomeMainUIIcons = {}
  self.LocalHomeMainUIIcons = {}
  local Config = DataConfigManager:GetHomeGlobalConfig("home_main_UI", true)
  if Config then
    Log.Debug("home_main_UI", Config.str)
    local banTypeNames = string.split(Config.str, ";")
    for i, banTypeName in ipairs(banTypeNames) do
      local funcEnum = Enum.FunctionEntrance[banTypeName]
      if funcEnum then
        self.LocalHomeMainUIIcons[funcEnum] = true
      end
    end
  end
  Config = DataConfigManager:GetHomeGlobalConfig("visit_home_main_UI", true)
  if Config then
    Log.Debug("visit_home_main_UI", Config.str)
    local banTypeNames = string.split(Config.str, ";")
    for i, banTypeName in ipairs(banTypeNames) do
      local funcEnum = Enum.FunctionEntrance[banTypeName]
      if funcEnum then
        self.OtherHomeMainUIIcons[funcEnum] = true
      end
    end
  end
  Config = DataConfigManager:GetHomeGlobalConfig("plant_main_UI", true)
  if Config then
    Log.Debug("plant_main_UI", Config.str)
    local banTypeNames = string.split(Config.str, ";")
    for i, banTypeName in ipairs(banTypeNames) do
      local funcEnum = Enum.FunctionEntrance[banTypeName]
      if funcEnum then
        self.FarmMainUIIcons[funcEnum] = true
      end
    end
  end
end

function HomeModuleData:InitGlobalConfigs()
  self.editingHomeIgnoreNpcIdMap = {}
  local Config = DataConfigManager:GetHomeGlobalConfig("HOME_EDITTING_SHOW_NPCS", true)
  local numList = Config and Config.numList
  if numList then
    for i, v in pairs(numList) do
      self.editingHomeIgnoreNpcIdMap[v] = true
    end
  end
end

function HomeModuleData:IfNeedIgnoreNpcDuringEditingHome(NpcConfId)
  return self.editingHomeIgnoreNpcIdMap[NpcConfId]
end

function HomeModuleData:InitHomeStats()
  self.TotalRoomCount = 0
  local ROOM_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ROOM_CONF):GetAllDatas()
  for i, v in pairs(ROOM_CONF) do
    self.TotalRoomCount = self.TotalRoomCount + 1
  end
  self.TotalFurnitureTypeCnt = 0
  local FURNITURE_ITEM_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.FURNITURE_HANDBOOK_CONF):GetAllDatas()
  for i, v in pairs(FURNITURE_ITEM_CONF) do
    self.TotalFurnitureTypeCnt = self.TotalFurnitureTypeCnt + 1
  end
end

function HomeModuleData:InitHomeMagicBan()
  local Conf = DataConfigManager:GetHomeGlobalConfig("scene_magic_ban")
  if Conf then
    local banTypeNames = string.split(Conf.str, ";")
    local banTypes = {}
    for i, v in pairs(banTypeNames) do
      banTypes[Enum.SceneMagicType[v]] = true
    end
    self.MagicBanTypes = banTypes
  end
end

function HomeModuleData:InitHomeTasks()
  self.ExpandParagraphTasks = {}
  local HOME_USED_BY_TASK_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.HOME_USED_BY_TASK_CONF):GetAllDatas()
  for k, v in pairs(HOME_USED_BY_TASK_CONF) do
    for i, taskID in ipairs(v.task_id) do
      Log.Debug("[HomeModuleData] InitHomeTasks paragraph_id: Home Used", k, " task id:", taskID)
      local taskConf = _G.DataConfigManager:GetTaskConf(taskID)
      if taskConf then
        if not self.ExpandParagraphTasks[k] then
          self.ExpandParagraphTasks[k] = {}
        end
        table.insert(self.ExpandParagraphTasks[k], taskConf)
      end
    end
  end
  self.ExpandParagraphTaskInfos = {}
end

function HomeModuleData:InitFurnitureHandBook()
  self.FurnitureAtlasInfo = {}
  self.FurnitureAtlasNum = 0
  local FurnitureAtlasInfo = self.FurnitureAtlasInfo
  local HANDBOOK_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.FURNITURE_HANDBOOK_CONF):GetAllDatas()
  local cur_time = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  for _, conf in pairs(HANDBOOK_CONF) do
    if not string.IsNilOrEmpty(conf.open_time) then
      local dateTime, success = UE4.UKismetMathLibrary.DateTimeFromString(conf.open_time)
      if success and dateTime then
        local open_time = UE4.UNRCStatics.ToTimestamp(dateTime) - 28800
        if cur_time >= open_time then
          local furnitureData = {
            id = conf.id,
            reward_status = 1
          }
          FurnitureAtlasInfo[conf.id] = furnitureData
          self.FurnitureAtlasNum = self.FurnitureAtlasNum + 1
        end
      end
    end
  end
end

function HomeModuleData:GetFurnitureAtlasNum()
  return self.FurnitureAtlasNum
end

function HomeModuleData:GetAllFoodProductionInfo()
  if not self.allFoodProductionInfo then
    self:InitAllFoodProductionInfo()
  end
  return self.allFoodProductionInfo
end

function HomeModuleData:InitAllFoodProductionInfo()
  self.allFoodProductionInfo = {}
  local allExchangeConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.EXCHANGE_CONF)
  for i, v in pairs(allExchangeConf) do
    if v.use_type == Enum.ExchangeUseType.EUT_PROCESSING_PRODUCTS and v.get_item and v.get_item[1] then
      local foodProductionInfo = {}
      foodProductionInfo.foodItemId = v.get_item[1].get_goods_id
      foodProductionInfo.foodItemType = v.get_item[1].get_goods_type
      foodProductionInfo.unlockType = v.unlock_type
      foodProductionInfo.unlockParam = v.unlock_data
      foodProductionInfo.exchangeId = v.id
      foodProductionInfo.exchangeTimeUp = v.exchange_time_upper_limit
      foodProductionInfo.cost_item = self:DeepCopyCostItem(v.cost_item)
      foodProductionInfo.homePetFeedConf = _G.DataConfigManager:GetHomePetFeedConf(v.get_item[1].get_goods_id)
      table.insert(self.allFoodProductionInfo, foodProductionInfo)
    end
  end
end

function HomeModuleData:GetLastProcessingFoodId()
  if not self.LastFoodProcessingId then
    self.LastFoodProcessingId = JsonUtils.LoadSaved(LastProcessingFoodIdFileName, 0) or 0
  end
  return self.LastFoodProcessingId
end

function HomeModuleData:SaveLastProcessingFoodId(LastFoodProcessingId)
  self.LastFoodProcessingId = LastFoodProcessingId
  return JsonUtils.DumpSaved(LastProcessingFoodIdFileName, self.LastFoodProcessingId)
end

function HomeModuleData:DeepCopyCostItem(source)
  if not source then
    return {}
  end
  local result = {}
  for i, costItem in ipairs(source) do
    local copiedItem = {
      cost_goods_type = costItem.cost_goods_type,
      cost_goods_num = costItem.cost_goods_num
    }
    if costItem.cost_goods_id and #costItem.cost_goods_id > 0 then
      copiedItem.cost_goods_id = {}
      for j, goodsId in ipairs(costItem.cost_goods_id) do
        copiedItem.cost_goods_id[j] = goodsId
      end
    else
      copiedItem.cost_goods_id = nil
    end
    table.insert(result, copiedItem)
  end
  return result
end

function HomeModuleData:GetExpandParagraphTasks(RoomConf)
  if RoomConf and RoomConf.task then
    return self.ExpandParagraphTasks[RoomConf.task]
  end
end

function HomeModuleData:UpdateExpandTask(TaskParagraphId, TaskInfoList)
  self.ExpandParagraphTaskInfos[TaskParagraphId] = TaskInfoList
end

function HomeModuleData:IfExpandParagraphTaskCompleted(Task)
  local List = self.ExpandParagraphTaskInfos[Task.paragraph_id]
  if not List then
    return false
  end
  for i, v in ipairs(List) do
    if v.id == Task.id then
      local bFinish = v.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
      return bFinish, v
    end
  end
  return false
end

function HomeModuleData:InitHomeDefaultInteriorFinish()
  local INTERIOR_FINISH_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.INTERIOR_FINISH_CONF):GetAllDatas()
  for k, v in pairs(INTERIOR_FINISH_CONF) do
    if v.is_initial then
      table.insert(self.DefaultInteriorFinishConfList, v)
    end
  end
end

function HomeModuleData:GetDefaultInteriorFinishConfList()
  return self.DefaultInteriorFinishConfList
end

function HomeModuleData:GetCreationFirstTabIdList()
  return self.AllFurnitureFirstTabs
end

function HomeModuleData:InitHomeTabs()
  local function SortById(a, b)
    return a.id < b.id
  end
  
  self.FirstTabs = {}
  self.FirstTabMap = {}
  self.SecondToFirstTabMap = {}
  local FURNITURE_CLASSIFICATION_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FURNITURE_CLASSIFICATION_CONF):GetAllDatas()
  for k, v in pairs(FURNITURE_CLASSIFICATION_CONF) do
    if v.is_first_tab then
      table.insert(self.FirstTabs, v)
      self.FirstTabMap[k] = v
      for i2, v2 in ipairs(v.sec_tab_array) do
        self.SecondToFirstTabMap[v2] = k
      end
    end
  end
  table.sort(self.FirstTabs, SortById)
  local FURNITURE_ITEM_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FURNITURE_ITEM_CONF):GetAllDatas()
  local INTERIOR_FINISH_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.INTERIOR_FINISH_CONF):GetAllDatas()
  self.TabIdToFurnitureDataList = {}
  local AllFurnitureFirstTabSet = {}
  self.AllFurnitureFirstTabs = {}
  for k, v in pairs(FURNITURE_ITEM_CONF) do
    if v.classification then
      local Data = {FurnitureItemConf = v}
      local FirstTabId = self.FirstTabMap[v.classification] and v.classification or self.SecondToFirstTabMap[v.classification]
      if FirstTabId then
        local AllDataListByFirstTab = self.TabIdToFurnitureDataList[FirstTabId]
        if not AllDataListByFirstTab then
          AllDataListByFirstTab = {}
          self.TabIdToFurnitureDataList[FirstTabId] = AllDataListByFirstTab
        end
        self.FurnitureItemDataMap[k] = Data
        table.insert(AllDataListByFirstTab, Data)
        if not AllFurnitureFirstTabSet[FirstTabId] then
          AllFurnitureFirstTabSet[FirstTabId] = true
          table.insert(self.AllFurnitureFirstTabs, FirstTabId)
        end
      end
      if self.SecondToFirstTabMap[v.classification] then
        local DataList = self.TabIdToFurnitureDataList[v.classification]
        if not DataList then
          DataList = {}
          self.TabIdToFurnitureDataList[v.classification] = DataList
        end
        table.insert(DataList, Data)
      end
      self.FurnitureItemDataMap[k] = Data
    end
  end
  table.sort(self.AllFurnitureFirstTabs, function(a, b)
    return a < b
  end)
  for k, v in pairs(INTERIOR_FINISH_CONF) do
    if v.classification then
      local Data = {InteriorFinishConf = v}
      local FirstTabId = self.FirstTabMap[v.classification] and v.classification or self.SecondToFirstTabMap[v.classification]
      if FirstTabId then
        local AllDataListByFirstTab = self.TabIdToFurnitureDataList[FirstTabId]
        if not AllDataListByFirstTab then
          AllDataListByFirstTab = {}
          self.TabIdToFurnitureDataList[FirstTabId] = AllDataListByFirstTab
        end
        self.FurnitureItemDataMap[k] = Data
        table.insert(AllDataListByFirstTab, Data)
      end
      if self.SecondToFirstTabMap[v.classification] then
        local DataList = self.TabIdToFurnitureDataList[v.classification]
        if not DataList then
          DataList = {}
          self.TabIdToFurnitureDataList[v.classification] = DataList
        end
        self.FurnitureItemDataMap[k] = Data
        table.insert(DataList, Data)
      end
    end
  end
  
  local function SortByFurnitureData(a, b)
    if a.FurnitureItemConf and not b.FurnitureItemConf then
      return true
    end
    if not a.FurnitureItemConf and b.FurnitureItemConf then
      return false
    end
    if a.FurnitureItemConf and b.FurnitureItemConf then
      return a.FurnitureItemConf.id < b.FurnitureItemConf.id
    else
      return a.InteriorFinishConf.id < b.InteriorFinishConf.id
    end
  end
  
  for TabId, DataList in pairs(self.TabIdToFurnitureDataList) do
    table.sort(DataList, SortByFurnitureData)
  end
end

function HomeModuleData:GetFirstTabId(TabId)
  if TabId and self.FirstTabMap and self.SecondToFirstTabMap then
    return self.FirstTabMap[TabId] and TabId or self.SecondToFirstTabMap[TabId]
  end
end

function HomeModuleData:EvalCollectBagFurnitureItemInfo()
  for Id, Data in pairs(self.FurnitureItemDataMap) do
    if ENABLE_LOCAL_HOME_SERVER then
      Data.BagItem = {id = Id}
      Data.RemainingNum = 3
    else
      Data.BagItem = nil
      Data.RemainingNum = 0
    end
  end
  local BagData = NRCModuleManager:GetModule("BagModule"):GetData()
  if not BagData then
    HomeIndoorSandbox:Ensure(false, "bag module initialized failed 1")
    return
  end
  local BagInfo = BagData.BagInfo
  if not BagInfo then
    HomeIndoorSandbox:Ensure(false, "bag module initialized failed 2")
    return
  end
  if not BagInfo.item_list then
    HomeIndoorSandbox:Ensure(false, "bag module initialized failed 3")
    return
  end
  for i, item_type in ipairs(BagInfo.item_list) do
    if item_type.type == ProtoEnum.BagItemType.BI_FURNITURE and item_type.items then
      for _, BagItem in ipairs(item_type.items) do
        local FurnitureData = self.FurnitureItemDataMap[BagItem.id]
        if not FurnitureData then
          HomeIndoorSandbox:Ensure(false, "found bag item, not in FURNITURE_ITEM_CONF or INTERIOR_FINISH_CONF", BagItem.id)
        else
          FurnitureData.BagItem = BagItem
          FurnitureData.RemainingNum = BagItem.num
        end
      end
    end
  end
  return true
end

function HomeModuleData:GetFirstTabList()
  return self.FirstTabs
end

function HomeModuleData:GetFurnitureListByTabId(TabId)
  local DataList = self.TabIdToFurnitureDataList[TabId] or {}
  if 0 == #DataList then
    HomeIndoorSandbox:Ensure(false, "cannot found any data in tab", TabId)
  end
  return DataList
end

function HomeModuleData:GetFurnitureDataByConf(Conf)
  if Conf then
    return self.FurnitureItemDataMap[Conf.id]
  end
end

function HomeModuleData:GetFurnitureDataByConfId(ConfId)
  if ConfId then
    return self.FurnitureItemDataMap[ConfId]
  end
end

function HomeModuleData:InternalStatsByFurnitureChanged()
  HomeIndoorSandbox:LogInfo("[furniture] comfort ->", HomeIndoorSandbox.Server.WorldData.HomeComfortLevel)
  self:DispatchEvent(HomeIndoorSandbox.Event.OnInternalComfortChanged)
end

function HomeModuleData:OnEditingFurnitureRecycle(PropsData)
  local FurnitureData = self:GetFurnitureDataByConfId(PropsData.ConfId)
  if FurnitureData then
    if not FurnitureData.BagItem then
      FurnitureData.BagItem = {
        gid = PropsData.ItemGid,
        id = PropsData.ConfId
      }
    end
    FurnitureData.RemainingNum = FurnitureData.RemainingNum + 1
    HomeIndoorSandbox.Server.WorldData.HomeComfortLevel = HomeIndoorSandbox.Server.WorldData.HomeComfortLevel - (FurnitureData.FurnitureItemConf.comfort or 0)
    HomeIndoorSandbox:LogInfo("[furniture] recycle furniture, remaining num ->", FurnitureData.RemainingNum)
    self:InternalStatsByFurnitureChanged()
  else
    HomeIndoorSandbox:Ensure(false, "invalid, cannot found furniture data by conf id", PropsData.ConfId, PropsData.id, PropsData.ItemGid)
  end
end

function HomeModuleData:OnEditingFurniturePlaced(PropsData, FurnitureData)
  if FurnitureData then
    FurnitureData.RemainingNum = FurnitureData.RemainingNum - 1
    HomeIndoorSandbox.Server.WorldData.HomeComfortLevel = HomeIndoorSandbox.Server.WorldData.HomeComfortLevel + (FurnitureData.FurnitureItemConf.comfort or 0)
    HomeIndoorSandbox:LogInfo("[furniture] placed furniture, remaining num ->", FurnitureData.RemainingNum)
    self:InternalStatsByFurnitureChanged()
  else
    HomeIndoorSandbox:Ensure(false, "invalid, cannot found furniture data by conf id", PropsData.ConfId, PropsData.id, PropsData.ItemGid)
  end
end

function HomeModuleData:OnEditingCancelApplyInterior(DecoData)
  if DecoData then
    HomeIndoorSandbox.Server.WorldData.HomeComfortLevel = HomeIndoorSandbox.Server.WorldData.HomeComfortLevel - (DecoData:GetComfortVal() or 0)
    self:InternalStatsByFurnitureChanged()
  end
end

function HomeModuleData:OnEditingApplyInteriorFinish(DecoData)
  if DecoData then
    HomeIndoorSandbox.Server.WorldData.HomeComfortLevel = HomeIndoorSandbox.Server.WorldData.HomeComfortLevel + (DecoData:GetComfortVal() or 0)
    self:InternalStatsByFurnitureChanged()
  end
end

function HomeModuleData:GetItemList()
  return self.ItemList
end

function HomeModuleData:SetSelectModeTabIndex(_SelectModeTabIndex)
  self.SelectModeTabIndex = _SelectModeTabIndex
end

function HomeModuleData:GetSelectModeTabIndex()
  return self.SelectModeTabIndex
end

function HomeModuleData:SetSelectTypeTabIndex(_SelectTypeTabIndex)
  self.SelectTypeTabIndex = _SelectTypeTabIndex
end

function HomeModuleData:GetSelectTypeTabIndex()
  return self.SelectTypeTabIndex
end

function HomeModuleData:SetSelectItemIndex(index)
  self.SetSelectItemIndex = index
end

function HomeModuleData:SetPlacedInteractiveFurniture(furnitureId, furnitureData)
  if not furnitureId then
    Log.Error("invalid furnitureData when SetPlacedInteractiveFurniture")
    return
  end
  self.placedInteractiveFurniture[furnitureId] = furnitureData
end

function HomeModuleData:GetPlacedInteractiveFurniture(furnitureId)
  if not furnitureId then
    return nil
  end
  return self.placedInteractiveFurniture[furnitureId]
end

function HomeModuleData:UpdatePairNestAndPet(nestId, homePetInfo)
  if not nestId then
    Log.Error("UpdatePairNestAndPet with invalid nestId or actorId:", nestId)
    return
  end
  self.pairNestAndPet[nestId] = homePetInfo
end

function HomeModuleData:GetPairNestAndPet(NestID)
  if nil == NestID or not table.containsKey(self.pairNestAndPet, NestID) then
    return nil
  end
  return self.pairNestAndPet[NestID]
end

function HomeModuleData:UpdateNestInHome(NestData)
  if not NestData then
    return
  end
end

function HomeModuleData:UpdateHomePetInfo(homePetInfo, bAdd)
  if not homePetInfo then
    return
  end
  if bAdd then
    if table.len(self.HomePetList) > 0 then
      for i = 1, table.len(self.HomePetList) do
        if self.HomePetList[i].base.actor_id == homePetInfo.base.actor_id then
          self.HomePetList[i] = homePetInfo
          return
        end
      end
    end
    table.insert(self.HomePetList, homePetInfo)
  else
    for k, v in ipairs(self.HomePetList) do
      if v.home_pet.home_pet_info.pet_gid and v.home_pet.home_pet_info.pet_gid == homePetInfo.home_pet.home_pet_info.pet_gid then
        table.remove(self.HomePetList, k)
        return
      end
    end
  end
end

function HomeModuleData:GetHomePetInfo(petGid)
  if not petGid then
    return self.HomePetList
  end
  if petGid and #self.HomePetList > 0 then
    for _, v in ipairs(self.HomePetList) do
      if v.home_pet.home_pet_info and v.home_pet.home_pet_info.pet_gid == petGid then
        return v
      end
    end
  end
  return nil
end

return HomeModuleData
