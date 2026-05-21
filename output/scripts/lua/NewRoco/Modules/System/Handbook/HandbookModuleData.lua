local PetUtils = require("NewRoco.Utils.PetUtils")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local HandbookModuleEnum = reload("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local HandbookModuleData = _G.NRCData:Extend("HandbookModuleData")

function HandbookModuleData:Ctor()
  NRCData.Ctor(self)
  self.HandbookInfo = nil
  self.SelectPetData = nil
  self.SortMode = {
    {SortNum = 1, IsCanSort = true},
    {SortNum = 2, IsCanSort = true}
  }
  self.ChildSize_Y = 0
  self.IsStarted = false
  self.StartedIndex = 0
  self.SortIndex = _G.Enum.HandbookSequenceDefault.HSD_SEQUENCE_LEVEL_DOWN - 1
  self.isascendingorder = false
  local HandBookConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK)
  if HandBookConf then
    self.petHandbook = HandBookConf:GetAllDatas()
  else
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168,\230\159\165\231\156\139\229\142\159\229\155\160")
  end
  self.areaHandbookConfs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.AREA_HANDBOOK):GetAllDatas()
  local EvoConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_EVOLUTION_CONF)
  if EvoConf then
    self.EvoConfs = EvoConf:GetAllDatas()
  end
  self.icon = {}
  self.icon[1] = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_xing_png.img_xing_png'"
  self.icon[2] = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_yue_png.img_yue_png'"
  self.icon[3] = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_taiyang_png.img_taiyang_png'"
  self.icon[4] = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_taiyang1_png.img_taiyang1_png'"
  self.CommonCurIcon = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_gailv_png.img_gailv_png"
  self.ExpIcon = "PaperSprite'/Game/NewRoco/Modules/System/Handbook/Raw/Common/Images/Frames/img_mofajingyan_png.img_mofajingyan_png"
  self.SelectIndex = 0
  self.SelectSubIndex = 0
  self.SelectSubForce = false
  self.myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  self.HandbookLeftSortIndex = JsonUtils.LoadSaved(string.format("HandbookSortSaved/Handbook_Sort_State_%s", self.myUin), 2)
  self.HandbookLeftReversal = false
  self.SelectListItemUI = nil
  self.PetVisualParam = nil
  self.CurHandbookAreaId = 1
  self.CurHandbookAreaType = _G.Enum.AreaHandbookType.AHT_KINGDOM
  self.CollectedCount = 0
  self.HaveDiscoveredCount = 0
  self.CacheLeftHandbookList = nil
  self.HandbookCoverDic = {}
  self.HandbookStatDic = {}
  self.HandBookRewardStates = {}
  self.HandbookTopicDataDic = {}
  self.CacheNumberSortList = nil
  self.ReverseCacheNumberSortList = nil
  self.CacheTaskSortList = nil
  self.ReverseCacheTaskSortList = nil
  self:InitData()
  self:CreatPetHandbookMainDataDic()
  self.curSelectedSeasonPhotoType = ProtoEnum.PetHandbookSeasonPetType.PHSPT_NONE
  self.curSelectedSeason = 0
  self.curSelectedSeasonHandbookData = {
    type = HandbookModuleEnum.SeasonHandbookTable.Handbook,
    id = 1
  }
end

local function getUnfinishedTaskCount(id, handbookDic)
  local handbookInfo = handbookDic[id]
  local conf = handbookInfo.HandBookConf
  if handbookInfo.Collection == nil then
    return 0
  end
  local count = 0
  for i = 1, #handbookInfo.Collection.topic_list do
    local topic = handbookInfo.Collection.topic_list[i]
    local isGetAward = topic.get_award or false
    local finish_cnt = 0
    local max_cnt = 0
    local topic_id = topic.topic_id
    for j = 1, #conf.pet_topic do
      if conf.pet_topic[j].topic_id == topic_id then
        max_cnt = conf.pet_topic[j].topic_cnt or 0
        finish_cnt = topic.finish_cnt or 0
        break
      end
    end
    if not isGetAward and finish_cnt > 0 and max_cnt <= finish_cnt then
      count = count + 1
    end
  end
  return count
end

local function getFinishedTaskCount(id, handbookDic)
  local handbookInfo = handbookDic[id]
  local conf = handbookInfo.HandBookConf
  if handbookInfo.Collection == nil then
    return 0
  end
  local topic_list = handbookInfo.Collection.topic_list
  local count = 0
  for i = 1, #topic_list do
    local finish_cnt = 0
    local max_cnt = 0
    if conf and i <= #conf.pet_topic and conf.pet_topic[i].topic_cnt then
      max_cnt = conf.pet_topic[i].topic_cnt
    end
    if topic_list and i <= #topic_list then
      finish_cnt = topic_list[i].finish_cnt or 0
    end
    if max_cnt > 0 and max_cnt <= finish_cnt then
      count = count + 1
    end
  end
  return count
end

local function getTaskCount(id, handbookDic)
  local handbookInfo = handbookDic[id]
  if handbookInfo.Collection == nil then
    return 0
  end
  return #handbookInfo.Collection.topic_list or 0
end

function HandbookModuleData:GetHandbookTaskFinishCountById(handbookId)
  if handbookId then
    local UnfinishedTaskCount = getUnfinishedTaskCount(handbookId, self.HandBookMainDataDic)
    local TaskCount = getTaskCount(handbookId, self.HandBookMainDataDic)
    local FinishedTaskCount = getFinishedTaskCount(handbookId, self.HandBookMainDataDic)
    return UnfinishedTaskCount, FinishedTaskCount, TaskCount
  end
  return 0, 0, 0
end

function HandbookModuleData:GetIconPath(petId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petId)
  local petModuleCof = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  local iconPath = NRCUtils:FormatConfIconPath(petModuleCof.icon, _G.UIIconPath.HeadIconPath)
  return iconPath
end

function HandbookModuleData:SetHandbookInfo()
  self.SelectIndex = 0
  self.SelectPetData = {}
  if 0 == self.SortIndex then
    self.isascendingorder = false
  elseif 1 == self.SortIndex then
    self.isascendingorder = true
  end
end

function HandbookModuleData:SetSortIndex(_index)
  self.HandbookLeftSortIndex = _index
  JsonUtils.DumpSaved(string.format("HandbookSortSaved/Handbook_Sort_State_%s", self.myUin), _index)
end

function HandbookModuleData:InitData()
  self.AccessHandbookPetBaseData = {}
  self.HandbookInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  self.HandbookAwardConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_HANDBOOK_REWARD):GetAllDatas()
  if self.HandbookInfo.handbook then
    local curAreaInfo = self:GetCurAreaHandbookInfo()
    if curAreaInfo then
      self.CollectedCount = curAreaInfo.collect_coll_num
      self.HaveDiscoveredCount = curAreaInfo.found_coll_num
    end
  end
  self:InitopicDatas()
end

function HandbookModuleData:CreatPetHandbookMainDataDic()
  local petHandbookConf = self.petHandbook
  local PetHandBookDic = {}
  if self.HandbookInfo.handbook == nil or nil == self.HandbookInfo.handbook.record_collection then
    self.HandBookMainDataDic = PetHandBookDic
    return PetHandBookDic
  end
  local HandbookInfo = self.HandbookInfo.handbook.record_collection
  for k, HandbookConf in pairs(petHandbookConf) do
    for j, Collection in pairs(HandbookInfo) do
      if HandbookConf.id == Collection.handbook_id then
        local upIndex = HandbookConf.id - 1
        local downIndex = HandbookConf.id + 1
        PetHandBookDic[HandbookConf.id] = self:CreatPetHandbookInfo(HandbookConf, Collection)
        if upIndex > 0 and nil == PetHandBookDic[upIndex] then
          PetHandBookDic[upIndex] = self:CreatPetHandbookInfo(petHandbookConf[upIndex], nil)
        end
        if downIndex <= #self.petHandbook and nil == PetHandBookDic[downIndex] then
          PetHandBookDic[downIndex] = self:CreatPetHandbookInfo(petHandbookConf[downIndex], nil)
        end
      end
    end
  end
  self.HandBookMainDataDic = PetHandBookDic
  return PetHandBookDic
end

function HandbookModuleData:UpdatePetHandBookMainDataDic(_rsp)
  if self.HandbookInfo and _rsp.area_hb_change_info then
    for i = 1, #_rsp.area_hb_change_info do
      local areaRspInfo = _rsp.area_hb_change_info[i]
      for key, areaInfo in pairs(self.HandbookInfo.handbook.area_hb_infos) do
        if areaInfo.area_hb_type == areaRspInfo.hb_area_type then
          self.HandbookInfo.handbook.area_hb_infos[key].found_coll_num = areaRspInfo.curr_found_coll_num
          self.HandbookInfo.handbook.area_hb_infos[key].collect_coll_num = areaRspInfo.curr_collect_coll_num
          if self.CurHandbookAreaType == areaRspInfo.hb_area_type then
            self.CollectedCount = areaRspInfo.curr_collect_coll_num
            self.HaveDiscoveredCount = areaRspInfo.curr_found_coll_num
          end
        end
      end
    end
  end
  local recordCollection = _rsp.record_coll
  local handbookConf = _G.DataConfigManager:GetPetHandbook(recordCollection.handbook_id)
  self.HandBookMainDataDic[recordCollection.handbook_id] = self:CreatPetHandbookInfo(handbookConf, recordCollection)
  local upIndex = recordCollection.handbook_id - 1
  local downIndex = recordCollection.handbook_id + 1
  if upIndex > 0 and self.HandBookMainDataDic[upIndex] == nil then
    self.HandBookMainDataDic[upIndex] = self:CreatPetHandbookInfo(self.petHandbook[upIndex], nil)
  end
  if downIndex <= #self.petHandbook and self.HandBookMainDataDic[downIndex] == nil then
    self.HandBookMainDataDic[downIndex] = self:CreatPetHandbookInfo(self.petHandbook[downIndex], nil)
  end
end

function HandbookModuleData:ReverseCurBookId()
  self.CurHandbookAreaId = 1
  self.CurHandbookAreaType = _G.Enum.AreaHandbookType.AHT_KINGDOM
  self.curSelectedSeasonHandbookData = {
    type = HandbookModuleEnum.SeasonHandbookTable.Handbook,
    id = 1
  }
end

function HandbookModuleData:IsShowShiningIcon(record)
  if nil == record or nil == record.catch_mutation or 0 == #record.catch_mutation then
    return false
  end
  local isShiningGlass = false
  local isShiningChaos = false
  local isShining = false
  local isHadNormalForm = false
  for i = 1, #record.catch_mutation do
    local mutation = record.catch_mutation[i]
    if PetUtils.CheckIsShiningGlass(mutation) then
      isShiningGlass = true
    elseif PetUtils.CheckIsShiningChaos(mutation) then
      isShiningChaos = true
      isHadNormalForm = true
    elseif mutation == _G.Enum.MutationDiffType.MDT_SHINING then
      isShining = true
    elseif mutation == _G.Enum.MutationDiffType.MDT_NONE or mutation == _G.Enum.MutationDiffType.MDT_GLASS then
      isHadNormalForm = true
    elseif PetUtils.CheckIsCHAOS(mutation) then
      isHadNormalForm = true
    end
  end
  if (isShiningGlass or isShining or isShiningChaos) and false == isHadNormalForm then
    return true
  end
  return false
end

function HandbookModuleData:CreateCacheNumberSortList()
  if self.CacheNumberSortList == nil then
    self.CacheNumberSortList = {}
    for _, handbookInfo in pairs(self.HandBookMainDataDic) do
      local defaultInfo
      local collection = handbookInfo.Collection
      for j, recordInfo in pairs(handbookInfo.Records) do
        local handbookName = _G.DataConfigManager:GetPetbaseConf(recordInfo.PetBaseId).name
        local IconPath = recordInfo.IconPath
        local info = {}
        info.HandbookId = handbookInfo.HandbookId
        info.PetBaseId = recordInfo.PetBaseId
        info.IsShowRed = handbookInfo.IsShowRed
        info.HandbookNumber = handbookInfo.HandbookNumber
        info.SelectMaxIndex = handbookInfo.SelectMaxIndex
        info.PetBaseConf = recordInfo.PetBaseConf
        info.HandbookPetIcon = recordInfo.HandbookPetIcon
        info.PetName = handbookName
        local status
        if collection and collection.record then
          for _, record in pairs(collection.record) do
            if record.pet_base_id == info.PetBaseId then
              status = record.status
              break
            end
          end
        end
        info.State = status or recordInfo.State
        info.IconPath = IconPath
        info.AddTime = recordInfo.AddTime
        info.IsShowShiningIcon = recordInfo.IsShowShiningIcon
        if nil == defaultInfo then
          defaultInfo = info
        elseif info.State == defaultInfo.State then
          if self:GetConfSequence(handbookInfo.HandBookConf, info.PetBaseId) < self:GetConfSequence(handbookInfo.HandBookConf, defaultInfo.PetBaseId) then
            defaultInfo = info
          end
        elseif info.State > defaultInfo.State then
          defaultInfo = info
        end
      end
      if nil ~= defaultInfo then
        defaultInfo.UnfinishedTaskCount = getUnfinishedTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        defaultInfo.TaskCount = getTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        defaultInfo.FinishedTaskCount = getFinishedTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        table.insert(self.CacheNumberSortList, defaultInfo)
      end
    end
  end
  table.sort(self.CacheNumberSortList, function(a, b)
    return a.HandbookId < b.HandbookId
  end)
  return self.CacheNumberSortList
end

function HandbookModuleData:CreateCacheTaskSortList()
  if self.CacheTaskSortList == nil then
    self.CacheTaskSortList = {}
    for _, handbookInfo in pairs(self.HandBookMainDataDic) do
      local defaultInfo
      for i, recordInfo in pairs(handbookInfo.Records) do
        local handbookName = _G.DataConfigManager:GetPetbaseConf(recordInfo.PetBaseId).name
        local IconPath = recordInfo.IconPath
        local info = {}
        info.State = recordInfo.State
        if recordInfo.State ~= _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
          info.HandbookId = handbookInfo.HandbookId
          info.PetBaseId = recordInfo.PetBaseId
          info.IsShowRed = handbookInfo.IsShowRed
          info.SelectMaxIndex = handbookInfo.SelectMaxIndex
          info.HandbookNumber = handbookInfo.HandbookNumber
          info.PetBaseConf = recordInfo.PetBaseConf
          info.HandbookPetIcon = recordInfo.HandbookPetIcon
          info.PetName = handbookName
          info.State = recordInfo.State
          info.IconPath = IconPath
          info.AddTime = recordInfo.AddTime
          info.IsShowShiningIcon = recordInfo.IsShowShiningIcon
          if nil == defaultInfo then
            defaultInfo = info
          elseif info.State == defaultInfo.State then
            if self:GetHandbookPetBaseIdSortIndex(info.HandbookId, info.PetBaseId) < self:GetHandbookPetBaseIdSortIndex(defaultInfo.HandbookId, defaultInfo.PetBaseId) then
              defaultInfo = info
            end
          elseif info.State > defaultInfo.State then
            defaultInfo = info
          end
        end
      end
      if nil ~= defaultInfo then
        defaultInfo.UnfinishedTaskCount = getUnfinishedTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        defaultInfo.TaskCount = getTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        defaultInfo.FinishedTaskCount = getFinishedTaskCount(defaultInfo.HandbookId, self.HandBookMainDataDic)
        table.insert(self.CacheTaskSortList, defaultInfo)
      end
    end
  end
  table.sort(self.CacheTaskSortList, function(a, b)
    if a.State == b.State then
      if a.UnfinishedTaskCount == b.UnfinishedTaskCount then
        if a.TaskCount - a.FinishedTaskCount == b.TaskCount - b.FinishedTaskCount then
          return a.HandbookId < b.HandbookId
        else
          return a.TaskCount - a.FinishedTaskCount < b.TaskCount - b.FinishedTaskCount
        end
      else
        return a.UnfinishedTaskCount > b.UnfinishedTaskCount
      end
    else
      return a.State > b.State
    end
  end)
  return self.CacheTaskSortList
end

function HandbookModuleData:ClearCacheSortList()
  self.CacheNumberSortList = nil
  self.ReverseCacheNumberSortList = nil
  self.CacheTaskSortList = nil
  self.ReverseCacheTaskSortList = nil
end

function HandbookModuleData:GetLeftNumberSortList(_reversal)
  self:CreateCacheNumberSortList()
  if _reversal then
    if self.ReverseCacheNumberSortList then
      return self.ReverseCacheNumberSortList
    else
      self.ReverseCacheNumberSortList = {}
      for i, v in pairs(self.CacheNumberSortList) do
        table.insert(self.ReverseCacheNumberSortList, v)
      end
      self.ReverseCacheNumberSortList = self:Reverse(self.ReverseCacheNumberSortList)
      return self.ReverseCacheNumberSortList
    end
  else
    return self.CacheNumberSortList
  end
end

function HandbookModuleData:GetLeftTaskSortList(_reverse)
  self:CreateCacheTaskSortList()
  if _reverse then
    if self.ReverseCacheTaskSortList then
      return self.ReverseCacheTaskSortList
    else
      self.ReverseCacheTaskSortList = {}
      for i, v in pairs(self.CacheTaskSortList) do
        table.insert(self.ReverseCacheTaskSortList, v)
      end
      table.sort(self.ReverseCacheTaskSortList, function(a, b)
        if a.State == b.State then
          if a.UnfinishedTaskCount == b.UnfinishedTaskCount then
            if a.TaskCount - a.FinishedTaskCount == b.TaskCount - b.FinishedTaskCount then
              return a.HandbookId < b.HandbookId
            else
              return a.TaskCount - a.FinishedTaskCount > b.TaskCount - b.FinishedTaskCount
            end
          else
            return a.UnfinishedTaskCount < b.UnfinishedTaskCount
          end
        else
          return a.State < b.State
        end
      end)
      return self.ReverseCacheTaskSortList
    end
  else
    return self.CacheTaskSortList
  end
end

function HandbookModuleData:GetHandbookPetBaseIdSortIndex(handbookId, petBaseId)
  local handbookConf = _G.DataConfigManager:GetPetHandbook(handbookId)
  if handbookConf and handbookConf.include_petbase_id then
    for i = 1, #handbookConf.include_petbase_id do
      if petBaseId == handbookConf.include_petbase_id[i].petbase_id[1] then
        return i
      end
    end
  end
  return 999
end

function HandbookModuleData:Reverse(_dataList)
  for i = 0, (#_dataList - 1) / 2 do
    local temp = _dataList[i + 1]
    _dataList[i + 1] = _dataList[#_dataList - i]
    _dataList[#_dataList - i] = temp
  end
  return _dataList
end

function HandbookModuleData:UpdatePetHandbookSortLeftList()
  local sortType = self.HandbookLeftSortIndex
  local reversal = self.HandbookLeftReversal
  local petHandbookList = {}
  if sortType == _G.Enum.HandbookSequenceDefault.HSD_SEQUENCE_NUMBER_UP then
    petHandbookList = self:GetLeftNumberSortList(reversal)
  else
    petHandbookList = self:GetLeftTaskSortList(reversal)
  end
  local list = self:ExtractAreaHandBookList(petHandbookList)
  self.CacheLeftHandbookList = list
  return list, sortType
end

function HandbookModuleData:CreatPetHandbookInfo(_Handbook, _Collection)
  local handbookConf = _Handbook
  local Collection = _Collection
  local petBookInfo = {}
  petBookInfo.HandbookId = handbookConf.id
  petBookInfo.HandbookNumber = string.format("%03d", handbookConf.id)
  petBookInfo.HandbookName = handbookConf.name
  petBookInfo.HandBookConf = handbookConf
  petBookInfo.SelectMaxIndex = 1
  petBookInfo.Collection = Collection
  petBookInfo.Records = {}
  petBookInfo.State = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
  petBookInfo.IsShowRed = false
  if handbookConf.include_petbase_id then
    for i = 1, #handbookConf.include_petbase_id do
      if handbookConf.include_petbase_id[i].petbase_id then
        local petbase_id = handbookConf.include_petbase_id[i].petbase_id[1]
        petBookInfo.Records[petbase_id] = self:CreatPetRecordInfo(petbase_id, nil)
      end
    end
  else
    for i = 1, #handbookConf.pet_id do
      if handbookConf.pet_id[i] then
        local petbase_id = handbookConf.pet_id[i]
        petBookInfo.Records[petbase_id] = self:CreatPetRecordInfo(petbase_id, nil)
      end
    end
  end
  if Collection then
    petBookInfo.State = Collection.status
    if Collection.record then
      petBookInfo.SelectMaxIndex = #Collection.record
      table.sort(Collection.record, function(a, b)
        if a.status == b.status then
          return self:GetConfSequence(handbookConf, a.pet_base_id) < self:GetConfSequence(handbookConf, b.pet_base_id)
        else
          return a.status > b.status
        end
      end)
      for _, record in pairs(Collection.record) do
        petBookInfo.Records[record.pet_base_id] = self:CreatPetRecordInfo(record.pet_base_id, record)
      end
    else
      Log.Error("HandbookModuleData record is nil")
    end
  end
  return petBookInfo
end

function HandbookModuleData:GetConfSequence(handbook, petbaseId)
  for i = 1, #handbook.include_petbase_id do
    if handbook.include_petbase_id[i].petbase_id then
      for j = 1, #handbook.include_petbase_id[i].petbase_id do
        local petid = handbook.include_petbase_id[i].petbase_id[j]
        if petbaseId == petid then
          return i
        end
      end
    end
  end
  return 1
end

function HandbookModuleData:CreatPetRecordInfo(_baseId, _record)
  local recordInfo = {}
  if nil ~= _record then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_record.pet_base_id)
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    recordInfo.PetBaseId = _record.pet_base_id
    recordInfo.Record = _record
    recordInfo.IsShowShiningIcon = self:IsShowShiningIcon(_record)
    recordInfo.PetBaseConf = petBaseConf
    recordInfo.HandbookPetIcon = modelConf
    recordInfo.IconPath = self:GetIconPath(_record.pet_base_id)
    recordInfo.AddTime = _record.add_time
    recordInfo.State = _record.status
  else
    local pet_base_id = _baseId
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(pet_base_id)
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    recordInfo.PetBaseId = pet_base_id
    recordInfo.PetBaseConf = petBaseConf
    recordInfo.HandbookPetIcon = modelConf
    recordInfo.IconPath = self:GetIconPath(pet_base_id)
    recordInfo.AddTime = 0
    recordInfo.State = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
  end
  return recordInfo
end

function HandbookModuleData:SetSelectPetData(_PetData)
  if _PetData and _PetData.HandbookId then
    self.SelectPetData = self.HandBookMainDataDic[_PetData.HandbookId]
  end
end

function HandbookModuleData:CheckTopicAllRedPoint()
  local showRedPoint = false
  for _, v in pairs(self.HandBookMainDataDic) do
    showRedPoint = showRedPoint or v.IsShowRed
    if showRedPoint then
      break
    end
  end
  return showRedPoint
end

function HandbookModuleData:CheckAwardRedPoint()
  local showRedPoint = false
  local isCollectAll = true
  self:GetHandBookRewardStates()
  local curAwardConf = {}
  for i, v in pairs(self.HandbookAwardConf) do
    local awardConf = v
    if awardConf.belong_area_handbook == self.CurHandbookAreaType then
      table.insert(curAwardConf, awardConf)
    end
  end
  table.sort(curAwardConf, function(a, b)
    return a.handbook_number < b.handbook_number
  end)
  for i = 1, #curAwardConf do
    local awardConf = curAwardConf[i]
    if self.HandBookRewardStates[self.CurHandbookAreaType] and self.HandBookRewardStates[self.CurHandbookAreaType][i] == false and awardConf.handbook_number and self.CollectedCount and awardConf.handbook_number <= self.CollectedCount then
      showRedPoint = true
      break
    end
  end
  local curRewardStates = self.HandBookRewardStates[self.CurHandbookAreaType]
  if curRewardStates then
    for i = 1, #curRewardStates do
      if false == curRewardStates[i] then
        isCollectAll = false
        break
      end
    end
  end
  return showRedPoint, isCollectAll
end

function HandbookModuleData:GetAreaHandBookList(AreaId)
  local bookList = {}
  for key, HandbookData in pairs(self.HandBookMainDataDic) do
    local bookConf = HandbookData.HandBookConf
    if bookConf and bookConf.belong_area_handbook then
      for i = 1, #bookConf.belong_area_handbook do
        local areaId = bookConf.belong_area_handbook[i]
        if AreaId == areaId then
          table.insert(bookList, HandbookData)
        end
      end
    end
  end
  return bookList
end

function HandbookModuleData:ExtractAreaHandBookList(List)
  local bookList = {}
  for key, HandbookData in pairs(List) do
    local bookConf = _G.DataConfigManager:GetPetHandbook(HandbookData.HandbookId)
    if bookConf and bookConf.belong_area_handbook then
      for i = 1, #bookConf.belong_area_handbook do
        local areaId = bookConf.belong_area_handbook[i]
        if self.CurHandbookAreaId == areaId then
          table.insert(bookList, HandbookData)
        end
      end
    end
  end
  return bookList
end

function HandbookModuleData:ChangeAreaHandbookInfo()
  local AreaHandBookConf = _G.DataConfigManager:GetAreaHandbook(self.CurHandbookAreaId)
  local areaHandbookType = self.CurHandbookAreaType
  if AreaHandBookConf then
    areaHandbookType = AreaHandBookConf.area_handbook_type
  end
  if self.HandbookInfo.handbook then
    local curAreaInfo
    for key, areaInfo in pairs(self.HandbookInfo.handbook.area_hb_infos) do
      if areaInfo.area_hb_type == areaHandbookType then
        curAreaInfo = areaInfo
        break
      end
    end
    if curAreaInfo then
      self.CollectedCount = curAreaInfo.collect_coll_num
      self.HaveDiscoveredCount = curAreaInfo.found_coll_num
    end
  end
end

function HandbookModuleData:GetCurAreaHandbookEnum()
  return self.CurHandbookAreaType
end

function HandbookModuleData:GetPetHandBookData(_handbookId)
  if self.HandBookMainDataDic and self.HandBookMainDataDic[_handbookId] then
    return self.HandBookMainDataDic[_handbookId]
  else
    return nil
  end
end

function HandbookModuleData:GetPetHandBookRecordData(_handbookId, _petBaseId)
  if self.HandBookMainDataDic and self.HandBookMainDataDic[_handbookId] and self.HandBookMainDataDic[_handbookId].Records[_petBaseId] then
    return self.HandBookMainDataDic[_handbookId].Records[_petBaseId]
  else
    return nil
  end
end

function HandbookModuleData:GetPetHandbookCurrentProgressTaskReward(_petBaseId)
  return nil, 0, 0
end

function HandbookModuleData:GetPetHandBookRecordIndex(_handbookId, _petBaseId)
  local records = self.HandBookMainDataDic[_handbookId].Records
  local index = 0
  if self.HandBookMainDataDic[_handbookId].Collection then
    local record = self.HandBookMainDataDic[_handbookId].Collection.record
    for key, value in pairs(record) do
      index = index + 1
      if value.pet_base_id == _petBaseId then
        return index
      end
    end
  end
  for key, value in pairs(records) do
    index = index + 1
    if key == _petBaseId then
      return index
    end
  end
  return index
end

function HandbookModuleData:GetPetHandBookState(_petBaseId)
  for i, handbookInfo in pairs(self.HandBookMainDataDic) do
    if handbookInfo.Records and handbookInfo.Records[_petBaseId] ~= nil then
      return handbookInfo.Records[_petBaseId].State
    end
  end
  return _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
end

function HandbookModuleData:GetPetState(_petBaseId)
  for i, handbookInfo in pairs(self.HandBookMainDataDic) do
    if handbookInfo.Records[_petBaseId] ~= nil then
      return handbookInfo.Records[_petBaseId].State
    end
  end
  for _, handbookInfo in pairs(self.HandBookMainDataDic) do
    for _, records in pairs(handbookInfo.Records) do
      if records.Record and records.Record.boss_status and #records.Record.boss_status > 0 then
        for _, boosStatus in pairs(records.Record.boss_status) do
          if boosStatus.boss_base_id == _petBaseId then
            return boosStatus.status
          end
        end
      end
    end
  end
  return _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
end

function HandbookModuleData:GetPetHandBookRecord(_petBaseId)
  for i, handbookInfo in pairs(self.HandBookMainDataDic) do
    if handbookInfo.Records[_petBaseId] ~= nil then
      return handbookInfo.Records[_petBaseId].State
    end
  end
  return _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
end

function HandbookModuleData:InitHandBookRewardStates()
  if self.HandBookRewardStates[self.CurHandbookAreaType] == nil then
    local areaInfo = self:GetCurAreaHandbookInfo()
    if areaInfo then
      self.HandBookRewardStates[self.CurHandbookAreaType] = areaInfo.award_get_list
    end
  end
end

function HandbookModuleData:GetHandBookRewardStates()
  self:InitHandBookRewardStates()
  return self.HandBookRewardStates[self.CurHandbookAreaType]
end

function HandbookModuleData:SetHandBookRewardStates(_index, state)
  self:InitHandBookRewardStates()
  self.HandBookRewardStates[self.CurHandbookAreaType][_index] = state
end

function HandbookModuleData:GetCurAreaHandbookInfo()
  if self.HandbookInfo.handbook and self.HandbookInfo.handbook.area_hb_infos then
    for key, areaInfo in pairs(self.HandbookInfo.handbook.area_hb_infos) do
      if areaInfo.area_hb_type == self.CurHandbookAreaType then
        return areaInfo
      end
    end
  end
end

function HandbookModuleData:GetAreaHandbookInfo(type)
  if self.HandbookInfo.handbook and self.HandbookInfo.handbook.area_hb_infos then
    for key, areaInfo in pairs(self.HandbookInfo.handbook.area_hb_infos) do
      if areaInfo.area_hb_type == type then
        return areaInfo
      end
    end
  end
end

function HandbookModuleData:GetHandbookCoverInfos()
  local count = 0
  local coverInfos = {}
  local petHandbookList = {}
  local sortType = self.HandbookLeftSortIndex
  if sortType == _G.Enum.HandbookSequenceDefault.HSD_SEQUENCE_NUMBER_UP then
    petHandbookList = self:GetLeftNumberSortList(false)
  else
    petHandbookList = self:GetLeftTaskSortList(false)
  end
  local handbookList = self:ExtractAreaHandBookList(petHandbookList)
  for i, v in pairs(handbookList) do
    if 6 == count then
      break
    end
    if v.State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      local isAdd = true
      if 0 == getUnfinishedTaskCount(v.HandbookId, self.HandBookMainDataDic) then
        isAdd = false
      end
      local bookData = v
      local info = {}
      info.handbook_id = bookData.HandbookId
      info.rotate_angle = math.random(-20, 20)
      info.pet_base_id = bookData.PetBaseId
      info.state = bookData.State
      info.iconPath = bookData.IconPath
      if isAdd then
        table.insert(coverInfos, info)
        count = count + 1
      end
    end
  end
  return coverInfos
end

function HandbookModuleData:GetSelectPetData()
  return self.SelectPetData
end

function HandbookModuleData:SetSelectLeftListItemUI(_ItemUI)
  self.SelectListItemUI = _ItemUI
end

function HandbookModuleData:GetSelectLefListItemUI()
  return self.SelectListItemUI
end

function HandbookModuleData:GetSortIndex()
  return self.SortIndex
end

function HandbookModuleData:Setisascendingorder()
  self.isascendingorder = not self.isascendingorder
end

function HandbookModuleData:Getisascendingorder()
  return self.isascendingorder
end

function HandbookModuleData:SetSelectIndex(_index)
  self.SelectIndex = _index
end

function HandbookModuleData:GetSelectIndex()
  return self.SelectIndex
end

function HandbookModuleData:SetSubSelectIndex(_index)
  self.SelectSubIndex = _index
end

function HandbookModuleData:GetSubSelectIndex()
  return self.SelectSubIndex
end

function HandbookModuleData:GetSelectSubForce()
  return self.SelectSubForce
end

function HandbookModuleData:SetSelectSubForce(_subForce)
  self.SelectSubForce = _subForce
end

function HandbookModuleData:SetChildSize_Y(_ChildSize_Y)
  self.ChildSize_Y = _ChildSize_Y
end

function HandbookModuleData:GetChildSize_Y()
  return self.ChildSize_Y
end

function HandbookModuleData:SetIsStart(_IsStart)
  self.IsStarted = _IsStart
end

function HandbookModuleData:GetIsStart()
  return self.IsStarted
end

function HandbookModuleData:SetStartIndex(StartIndex)
  self.StartedIndex = StartIndex
end

function HandbookModuleData:GetStartIndex()
  return self.StartedIndex
end

function HandbookModuleData:InitopicDatas()
  local petInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local record_collection = petInfo and petInfo.handbook and petInfo.handbook.record_collection
  if record_collection then
    for _, _recordColl in ipairs(record_collection) do
      if _recordColl.handbook_id then
        self:SetHandbookTopicData(_recordColl)
      end
    end
  end
end

function HandbookModuleData:SetHandbookTopicData(collection, petbaseId)
  if self.HandbookTopicDataDic[collection.handbook_id] == nil then
    self.HandbookTopicDataDic[collection.handbook_id] = {}
  end
  local changeTopicDatas = {}
  local handbookConf = _G.DataConfigManager:GetPetHandbook(collection.handbook_id)
  if handbookConf then
    for i, topicInfo in pairs(collection.topic_list) do
      local topicId = topicInfo.topic_id or nil
      if topicId then
        if topicInfo.finish_cnt > 0 then
          if self.HandbookTopicDataDic[collection.handbook_id][topicId] == nil then
            local changeTopicData = self:CreateChangeTopicData(handbookConf, petbaseId, topicInfo)
            if changeTopicData and changeTopicData.finish_cnt > 0 then
              table.insert(changeTopicDatas, changeTopicData)
            end
          else
            local lastTopic = self.HandbookTopicDataDic[collection.handbook_id][topicId]
            if lastTopic and lastTopic.finish_cnt ~= topicInfo.finish_cnt then
              local changeTopicData = self:CreateChangeTopicData(handbookConf, petbaseId, topicInfo)
              if changeTopicData and changeTopicData.finish_cnt > 0 and changeTopicData.finish_cnt <= topicInfo.finish_cnt then
                table.insert(changeTopicDatas, changeTopicData)
              end
            end
          end
        end
        self.HandbookTopicDataDic[collection.handbook_id][topicId] = topicInfo
      end
    end
  end
  return changeTopicDatas
end

function HandbookModuleData:CreateChangeTopicData(handbookConf, baseId, topicInfo)
  if not (handbookConf and topicInfo) or not topicInfo.topic_id then
    Log.Error("handbookConf or topicInfo is nil", handbookConf.id, baseId, topicInfo.topic_id)
    return nil
  end
  local topicConf
  for i = 1, #handbookConf.pet_topic do
    if handbookConf.pet_topic[i].topic_id == topicInfo.topic_id then
      topicConf = handbookConf.pet_topic[i]
    end
  end
  if not topicConf then
    Log.Error("topicConf is nil")
    return nil
  end
  local finish_cnt = topicInfo.finish_cnt or 0
  local changeTopicData = {}
  changeTopicData.handbook_id = handbookConf.id
  changeTopicData.petbase_id = baseId
  changeTopicData.topicConf = topicConf
  changeTopicData.topic_id = topicInfo.topic_id
  changeTopicData.max_cnt = 0
  if topicConf and topicConf.topic_cnt then
    changeTopicData.max_cnt = topicConf.topic_cnt
  end
  if finish_cnt > changeTopicData.max_cnt then
    finish_cnt = changeTopicData.max_cnt
  end
  changeTopicData.finish_cnt = finish_cnt
  changeTopicData.topic_type = topicInfo.topic_type
  return changeTopicData
end

function HandbookModuleData:SetHandbookTopicAwardState(bookId, topicId, value)
  if self.HandbookTopicDataDic[bookId][topicId] then
    self.HandbookTopicDataDic[bookId][topicId].get_award = value
  end
end

function HandbookModuleData:GetHandbookTopicAwardState(bookId, topicId, value)
  if self.HandbookTopicDataDic[bookId][topicId] then
    return self.HandbookTopicDataDic[bookId][topicId].get_award
  end
  return false
end

function HandbookModuleData:GetHandbookTopicData(id)
  return self.CurHandbookTopicInfo[id]
end

function HandbookModuleData:SetPetVisualParam(_PetVisualParam)
  self.PetVisualParam = _PetVisualParam
end

function HandbookModuleData:GetPetVisualParam()
  return self.PetVisualParam
end

function HandbookModuleData:GetAccessHandbookData()
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule and playerModule.playerInfo and playerModule.playerInfo.handbook_info then
    if playerModule.playerInfo.handbook_info.handbook_records == nil then
      return self.AccessHandbookPetBaseData
    end
    local HandbookPetInfos = playerModule.playerInfo.handbook_info.handbook_records
    for i = 1, #HandbookPetInfos do
      local petBaseId = HandbookPetInfos[i].pet_base_id
      self.AccessHandbookPetBaseData[petBaseId] = HandbookPetInfos[i]
    end
  end
  return self.AccessHandbookPetBaseData
end

function HandbookModuleData:ChangeAccessHandbookData(handbookRecord)
  self.AccessHandbookPetBaseData = self:GetAccessHandbookData()
  for key, record in pairs(handbookRecord) do
    local petbaseId = record.pet_base_id
    self.AccessHandbookPetBaseData[petbaseId] = record
  end
end

function HandbookModuleData:SearchHandbook(text, listDatas, lastSelectIndex)
  local results = {}
  local isConf = false
  if self.petHandbook then
    for i = 1, #self.petHandbook do
      local handbookConf = self.petHandbook[i]
      local handbookid = tonumber(text)
      if handbookid then
        if handbookid == handbookConf.id then
          isConf = true
        end
      else
        local handbookName = handbookConf.name
        if string.find(handbookName:lower(), text:lower(), 1, true) then
          isConf = true
        end
      end
    end
  end
  if listDatas then
    for key, handbookInfo in ipairs(listDatas) do
      local handbookid = tonumber(text)
      if handbookid then
        if handbookid == handbookInfo.HandbookId then
          table.insert(results, {
            idx = key,
            bookId = handbookInfo.HandbookId,
            recordIdx = 1
          })
        end
      elseif handbookInfo.State ~= _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
        local bookData = self.HandBookMainDataDic[handbookInfo.HandbookId]
        local records = bookData.Collection.record
        for i = 1, #records do
          local baseId = records[i].pet_base_id
          local conf = _G.DataConfigManager:GetPetbaseConf(baseId)
          if conf and conf.name then
            local handbookName = conf.name
            if string.find(handbookName:lower(), text:lower(), 1, true) then
              table.insert(results, {
                idx = key,
                bookId = handbookInfo.HandbookId,
                recordIdx = i
              })
              break
            end
          end
        end
      end
    end
    if #results > 0 then
      local closest = results[1]
      if #results > 1 then
        local minDiff = math.abs(results[1].idx - lastSelectIndex)
        for i = 2, #results do
          local currentDiff = math.abs(results[i].idx - lastSelectIndex)
          if minDiff > currentDiff then
            minDiff = currentDiff
            closest = results[i]
          end
        end
      end
      self:DispatchEvent(HandbookModuleEvent.OnSearchHandbook, closest)
    elseif isConf then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.hb_search_error2)
    else
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.hb_search_error2)
    end
  end
end

function HandbookModuleData:SetHandbookStatDic(petBaseId, stats)
  if self.HandbookStatDic == nil then
    self.HandbookStatDic = {}
  end
  self.HandbookStatDic[petBaseId] = stats
end

function HandbookModuleData:GetHandbookStatData(petBaseId)
  if self.HandbookStatDic == nil then
    self.HandbookStatDic = {}
  end
  return self.HandbookStatDic[petBaseId]
end

function HandbookModuleData:ClearHandbookStatData()
  table.clear(self.HandbookStatDic)
end

function HandbookModuleData:CheckEvoPetbaseIdInHandbook(petbaseId)
  local evoDataGroupList = {}
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  if nil == petbaseConf or nil == petbaseConf.pet_evolution_id or nil == petbaseConf.pet_evolution_id[1] then
    Log.Error(petbaseId, "petbaseconf error")
    return false
  end
  local evoId = petbaseConf.pet_evolution_id[1]
  local handbookEvoGroup = self.EvoConfs[evoId] and self.EvoConfs[evoId].handbook_evolution_group or 0
  if 0 == handbookEvoGroup then
    Log.Error(petbaseId, evoId, "evoconf not handbook_evolution_group")
    return false
  end
  for i, v in pairs(self.EvoConfs) do
    if v.handbook_evolution_group == handbookEvoGroup then
      table.insert(evoDataGroupList, v)
    end
  end
  for _, evoConf in pairs(evoDataGroupList) do
    for _, chain in pairs(evoConf.evolution_chain) do
      if self:GetPetHandBookState(chain.petbase_id) == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
        return true
      end
    end
  end
  return false
end

function HandbookModuleData:CheckItemInHandbook(itemId)
  local itemConf = _G.DataConfigManager:GetBagItemConf(itemId)
  local petName = ""
  local isHaveBook = false
  if itemConf then
    local itemType = itemConf.type
    local petId
    if itemType == _G.Enum.BagItemType.BI_PET_EGG then
      for i = 1, #itemConf.item_behavior do
        if itemConf.item_behavior[i].use_action == _G.Enum.ItemBehavior.IB_PET_EGG_HATCH then
          petId = itemConf.item_behavior[i].ratio[1]
          break
        end
      end
      if not petId or 0 == petId then
        Log.Error(itemId, itemConf.name .. " not found peconf_id")
        return nil
      end
      local petConf = _G.DataConfigManager:GetPetConf(petId)
      if petConf then
        local petbaseId = petConf.base_id
        if petbaseId then
          isHaveBook = self:CheckEvoPetbaseIdInHandbook(petbaseId)
          petName = _G.DataConfigManager:GetPetConf(petId).name
        end
      end
    elseif itemType == _G.Enum.BagItemType.BI_PET_FRUIT then
      local fruitConf = _G.DataConfigManager:GetOwlPetFruitConf(itemId)
      if nil == fruitConf or nil == fruitConf.pet_refresh then
        return false
      end
      for i = 1, #fruitConf.pet_refresh do
        local npc_id = fruitConf.pet_refresh[i].npc_id
        if isHaveBook then
          break
        end
        for j = 1, #npc_id do
          local id = npc_id[j]
          local npcConf = _G.DataConfigManager:GetNpcConf(id)
          if npcConf and npcConf.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE then
            local baseId = npcConf.traverse_data_param[1]
            isHaveBook = self:CheckEvoPetbaseIdInHandbook(baseId)
            if isHaveBook then
              local fristId = self:GetEvolutionFristId(baseId)
              if nil == fristId or 0 == fristId then
                fristId = baseId
              end
              petName = _G.DataConfigManager:GetPetbaseConf(fristId).name
              break
            end
          end
        end
      end
    end
    local isCustomGlassEgg = false
    if petId then
      local PetEggConfID = petId
      local PetEggConf = _G.DataConfigManager:GetPetEggConf(PetEggConfID)
      if PetEggConf and PetEggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
        isCustomGlassEgg = true
      end
    end
    if itemConf.known_name and itemConf.known_description then
      if isCustomGlassEgg then
        return isHaveBook, string.format(itemConf.known_name, petName), string.format(itemConf.known_description, petName, petName)
      else
        return isHaveBook, string.format(itemConf.known_name, petName), string.format(itemConf.known_description, petName)
      end
    end
  else
    return isHaveBook, "", ""
  end
end

function HandbookModuleData:GetEvolutionFristId(petBaseId)
  local evoId = _G.DataConfigManager:GetPetbaseConf(petBaseId).pet_evolution_id[1]
  local petEvoConf = _G.DataConfigManager:GetPetEvolutionConf(evoId)
  if not petEvoConf then
    Log.Error(evoId, "PetEvolutionConf not found evoId")
    return 0
  end
  local evoChains = petEvoConf.evolution_chain
  for i = 1, #evoChains do
    if 1 == evoChains[i].stage then
      return evoChains[i].petbase_id
    end
  end
  return 0
end

function HandbookModuleData:GetPetHandbookRecordDataByPetBaseID(petBaseID)
  local handbookID = self:GetHandbookId(petBaseID)
  if handbookID and petBaseID then
    local recordData = self:GetPetHandBookRecordData(handbookID, petBaseID)
    if recordData then
      return recordData
    end
  end
  return nil
end

function HandbookModuleData:GetPetHandbookRecordByPetBaseID(petBaseID)
  local handbookID = self:GetHandbookId(petBaseID)
  if handbookID and petBaseID and self.HandBookMainDataDic[handbookID] and self.HandBookMainDataDic[handbookID].Collection then
    local record = self.HandBookMainDataDic[handbookID].Collection.record
    for i, value in pairs(record or {}) do
      if value.pet_base_id == petBaseID then
        return record[i]
      end
    end
  end
  return nil
end

function HandbookModuleData:GetHandbookId(pet_base_id)
  local handbookId
  if pet_base_id then
    if not self.handbookConfs then
      self.handbookConfs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK):GetAllDatas()
    end
    for _, handbookConf in ipairs(self.handbookConfs or {}) do
      for i = 1, #handbookConf.include_petbase_id do
        local petbaseId = handbookConf.include_petbase_id[i].petbase_id[1]
        if petbaseId == pet_base_id then
          return handbookConf.id
        end
      end
    end
  end
  return handbookId
end

function HandbookModuleData:GetHandbookCollectedPetsNum()
  local areaInfo = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAreaHandbookInfo, Enum.AreaHandbookType.AHT_KINGDOM)
  if areaInfo then
    return areaInfo.collect_coll_num
  end
  return 0
end

function HandbookModuleData:GetAllFilterData()
  local filterData = {}
  local curBookList = self.CacheLeftHandbookList
  for _, itemData in pairs(curBookList) do
    local handbookData = self.HandBookMainDataDic[itemData.HandbookId]
    if handbookData.State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      for _, v in pairs(handbookData.Records) do
        if v.State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
          local data = {}
          data.handbookId = handbookData.HandbookId
          data.filterData = {
            petbase_id = v.PetBaseId
          }
          table.insert(filterData, data)
        end
      end
    end
  end
  return filterData
end

function HandbookModuleData:CheckHandbookSeasonIsGotReward(seasonId, petType)
  local seasonInfo
  if self.HandbookInfo and self.HandbookInfo.handbook then
    for _, info in pairs(self.HandbookInfo.handbook.season_info or {}) do
      if info.season_id == seasonId then
        seasonInfo = info
        break
      end
    end
  end
  if seasonInfo then
    local gotReward = seasonInfo.getted_reward
    local hasFlag = 0 ~= gotReward & 1 << petType
    return hasFlag
  end
  return false
end

function HandbookModuleData:CheckHandbookSeasonAwardState(seasonId)
  local checkTypes = {
    ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW,
    ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING,
    ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING
  }
  local allClaimed = true
  for _, petType in ipairs(checkTypes) do
    local isGotReward = self:CheckHandbookSeasonIsGotReward(seasonId, petType)
    if not isGotReward then
      allClaimed = false
      local _, collectedNum, rewardNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, seasonId, petType)
      if collectedNum and rewardNum and collectedNum == rewardNum then
        return HandbookModuleEnum.SeasonHandbookAwardState.NotClaimed
      end
    end
  end
  if allClaimed then
    return HandbookModuleEnum.SeasonHandbookAwardState.Claimed
  else
    return HandbookModuleEnum.SeasonHandbookAwardState.NotReached
  end
end

function HandbookModuleData:UpdateHandbookSeasonIsGotReward(seasonId, petType)
  if self.HandbookInfo and self.HandbookInfo.handbook then
    if not self.HandbookInfo.handbook.season_info then
      self.HandbookInfo.handbook.season_info = {}
    end
    local isFound = false
    for _, info in pairs(self.HandbookInfo.handbook.season_info or {}) do
      if info.season_id == seasonId then
        isFound = true
        info.getted_reward = info.getted_reward | 1 << petType
        break
      end
    end
    if not isFound then
      local temp = {
        season_id = seasonId,
        getted_reward = 1 << petType
      }
      table.insert(self.HandbookInfo.handbook.season_info, temp)
    end
  end
end

return HandbookModuleData
