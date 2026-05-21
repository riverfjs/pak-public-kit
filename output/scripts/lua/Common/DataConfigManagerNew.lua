require("UnLuaEx")
local Base = require("Common.DataConfigManager")
local IS_EDITOR = _G.RocoEnv.IS_EDITOR
local DataConfigManagerNew = Base:Extend()

local function BinDataTable_Iterator(binTable)
  local index = 0
  local dataCount = binTable and binTable:GetDataCount() or 0
  return function()
    index = index + 1
    if index <= dataCount then
      return index, binTable:GetDataByIndex(index)
    end
  end
end

local BinDataTable_MT = {
  __ipairs = function(binTable)
    return BinDataTable_Iterator(binTable)
  end,
  __pairs = function(binTable)
    return BinDataTable_Iterator(binTable)
  end,
  DumpAll = function(binTable)
    local dumpTable = {}
    local allDatas = binTable and binTable:GetAllDatas()
    if allDatas then
      for _key, _binEntry in pairs(allDatas) do
        dumpTable[_key] = _G.BinDataUtils.BinDataUnboxing(_binEntry, true)
      end
    end
    return dumpTable
  end,
  CheckIsSameWithLuaConfig = function(binTable)
    local luaConfigT = require(string.format("Data.Config.%s", binTable.name)):GetAllDatas()
    local binConfigT = binTable:DumpAll()
    local compareTable
    
    function compareTable(t1, t2, path)
      path = path or ""
      local differences = {}
      for k, v in pairs(t1) do
        local v2 = t2[k]
        local currentPath = path .. "/" .. tostring(k)
        if type(v) == "table" and type(v2) == "table" then
          local subDifferences = compareTable(v, v2, currentPath)
          for _, diff in ipairs(subDifferences) do
            table.insert(differences, diff)
          end
        elseif v2 ~= v then
          table.insert(differences, {
            path = currentPath,
            lua = v,
            bin = v2
          })
        end
      end
      return differences
    end
    
    return compareTable(luaConfigT, binConfigT)
  end
}
BinDataTable_MT.__index = BinDataTable_MT

function DataConfigManagerNew:InitTableInfo()
  Base.InitTableInfo(self)
  local CacheData = UE4.NRCLuaUtils.CreateTable(0, 32768)
  _G.BinDataCache = _G.MakeWeakTable(CacheData)
  local binDataConfig = UE.FBinDataConfig()
  binDataConfig.BinStructToLuaAsTable = true
  binDataConfig.BinPropertyCacheMode = UE.EBinDataCacheMode.WeakValue
  UE4.FBinDataUtils.SetBinDataConfig(binDataConfig)
  if RocoEnv.IS_EDITOR and _G.NRCEditorEntranceEnable then
    self.BinDataManager = NewObject(UE.UBinDataManager, UE4.UNRCStatics.GetCurrentWorldInSkillEditor(), "BinDataManager", "Common.BinDataManager")
  else
    self.BinDataManager = NewObject(UE.UBinDataManager, UE4.UNRCPlatformGameInstance.GetInstance(), "BinDataManager", "Common.BinDataManager")
  end
  self.BinDataManager_Ref = UnLua.Ref(self.BinDataManager)
  _G.RebindIndex(self.BinDataManager)
  UE4.FBinDataReader.SetUsingBinDataManager(self.BinDataManager)
  if self.__configTableInfo then
    local ScriptDir = UE4.UNRCStatics.ProjectScriptDir()
    local BinDataDirectory = "Data/Bin/BinData/"
    if self.BinDataManager.IsCompressedBinDataEnabled and self.BinDataManager:IsCompressedBinDataEnabled() then
      BinDataDirectory = "Data/Bin/BinDataCompressed/"
    end
    for _, _conf in pairs(self.__configTableInfo) do
      local binName = _conf and _conf.name
      if binName then
        local binPath = string.format("%s%s.bytes", BinDataDirectory, binName)
        local binConf = string.format("Data/Bin/BinConf/%s.non", binName)
        self.BinDataManager:RegisterBinData(binName, binPath, binConf, ScriptDir)
      end
    end
    self:ChangeLanguage("dev_CN")
    if RocoEnv.IS_EDITOR then
      self:PreLoadBinData()
    end
  end
end

function DataConfigManagerNew:PreLoadBinData()
  Log.Debug("[DataConfigManagerNew.PreLoadBinData]")
  local bFreezePreLoad = false
  if not bFreezePreLoad then
    local filterTables = {"LOC_FILE"}
    for _, _conf in pairs(self.__configTableInfo) do
      local binName = _conf and _conf.name
      if binName and not table.contains(filterTables, binName) then
        self.BinDataManager:LoadBinData(binName, true)
      end
    end
  end
end

function DataConfigManagerNew:GetTable(_tableId)
  if _G.GlobalConfig.DisableBinData then
    return Base.GetTable(self, _tableId)
  end
  if not _tableId or 0 == _tableId then
    return nil
  end
  local dataTables = self.__dataTables
  local cfgTable = dataTables[_tableId]
  if not cfgTable then
    local tblInfo = self.__configTableInfo[_tableId]
    if tblInfo then
      self.BinDataManager:LoadBinData(tblInfo.name, false)
      local binDataTable = {
        name = tblInfo.name,
        binDataMgr = self.BinDataManager,
        hasIndex = self.BinDataManager:IsTableDataHasKey(tblInfo.name),
        dataCacheWithKey = _G.MakeWeakTable(),
        dataCacheWithIndex = _G.MakeWeakTable(),
        GetAllDatas = function(binTable)
          local dataMgr = binTable.binDataMgr
          local allDatasCache = binTable.allDatasCache
          if allDatasCache and allDatasCache.allDatas then
            return allDatasCache.allDatas
          end
          if dataMgr then
            local allDatas = dataMgr:GetBinDataAll(binTable.name)
            binTable.allDatasCache = binTable.allDatasCache or MakeWeakTable()
            binTable.allDatasCache.allDatas = allDatas
            return allDatas
          end
        end,
        GetData = function(binTable, keyValue)
          if IS_EDITOR then
            if binTable.editor_discard and binTable.editor_discard[keyValue] then
              return nil
            end
            if binTable.editor_override and binTable.editor_override[keyValue] then
              return binTable.editor_override[keyValue]
            end
          end
          if binTable.hasIndex then
            return binTable:GetDataByKey(keyValue)
          end
          return binTable:GetDataByIndex(keyValue)
        end,
        GetDataByKey = function(binTable, keyValue)
          if not keyValue then
            return
          end
          local dataCache = binTable.dataCacheWithKey
          if dataCache then
            local cache = dataCache[keyValue]
            if cache then
              return cache
            end
          end
          local dataMgr = binTable.binDataMgr
          if dataMgr then
            local data = dataMgr:GetBinDataByKey(binTable.name, keyValue)
            if data and dataCache then
              dataCache[keyValue] = data
            end
            return data
          end
        end,
        GetDataByIndex = function(binTable, index)
          if not index then
            return
          end
          if type(index) == "number" and index > 0 then
            local dataCache = binTable.dataCacheWithIndex
            if dataCache then
              local cache = dataCache[index]
              if cache then
                return cache
              end
            end
            local dataMgr = binTable.binDataMgr
            if dataMgr then
              local data = dataMgr:GetBinDataByIndex(binTable.name, index)
              if data and dataCache then
                dataCache[index] = data
              end
              return data
            end
          end
        end,
        GetDataCount = function(binTable)
          local dataMgr = binTable.binDataMgr
          if dataMgr then
            return dataMgr:GetBinDataCount(binTable.name)
          end
        end,
        HasKey = function(binTable, keyValue)
          if not keyValue then
            return
          end
          local dataMgr = binTable.binDataMgr
          if dataMgr then
            return dataMgr:GetTableDataIndex(binTable.name, keyValue) > 0
          end
        end,
        SaveData = function(binTable, key, value)
          if not IS_EDITOR then
            Log.Error("SaveData\229\143\170\232\131\189\229\156\168Editor\231\142\175\229\162\131\228\184\139\228\189\191\231\148\168\239\188\129\239\188\129")
            return
          end
          if not binTable.editor_override then
            binTable.editor_override = {}
          end
          binTable.editor_override[key] = value
        end,
        InsertData = function(binTable, key, value)
          if not IS_EDITOR then
            Log.Error("InsertData\229\143\170\232\131\189\229\156\168Editor\231\142\175\229\162\131\228\184\139\228\189\191\231\148\168\239\188\129\239\188\129")
            return false
          end
          if binTable:GetData(key) then
            return false
          end
          if binTable.editor_discard then
            binTable.editor_discard[key] = nil
          end
          binTable:SaveData(key, value)
          return true
        end,
        DeleteData = function(binTable, key)
          if not IS_EDITOR then
            Log.Error("DeleteData\229\143\170\232\131\189\229\156\168Editor\231\142\175\229\162\131\228\184\139\228\189\191\231\148\168\239\188\129\239\188\129")
            return false
          end
          if not binTable:GetData(key) then
            return false
          end
          if not binTable.editor_discard then
            binTable.editor_discard = {}
          end
          binTable.editor_discard[key] = true
          return true
        end
      }
      setmetatable(binDataTable, BinDataTable_MT)
      cfgTable = binDataTable
      dataTables[_tableId] = cfgTable
    end
  end
  return cfgTable
end

function DataConfigManagerNew:ValidAllData()
  if _G.GlobalConfig.DisableBinData then
    return {}
  end
  local result = {}
  for _, _tableId in pairs(self.ConfigTableId) do
    local binTable = self:GetTable(_tableId)
    local differences = binTable:CheckIsSameWithLuaConfig()
    if #differences > 0 then
      result[binTable.name] = differences
    end
  end
  return result
end

function DataConfigManagerNew:ChangeLanguage(language)
  UE4.FBinDataUtils.ClearConfigCache()
  local ScriptDir = UE4.UNRCStatics.ProjectScriptDir()
  local BinLocalizePath = string.format("Data/Bin/BinLocalize/%s", language)
  if self.BinDataManager then
    return self.BinDataManager:SetLocalizationFilePath(BinLocalizePath, ScriptDir)
  end
end

function DataConfigManagerNew:ReloadTable(TableName)
  local tableId = self.ConfigTableId[TableName]
  if not tableId then
    Log.Error("[DataConfigManagerNew:ReloadTable] Invalid Table Name: ", TableName)
    return false
  end
  local cfgTable = self.__dataTables[tableId]
  if cfgTable then
    local tblInfo = self.__configTableInfo[tableId]
    if tblInfo then
      if cfgTable.dataCacheWithKey then
        cfgTable.dataCacheWithKey = nil
        cfgTable.dataCacheWithKey = _G.MakeWeakTable()
        Log.Debug("[DataConfigManagerNew:ReloadTable] Clear dataCacheWithKey")
      end
      if cfgTable.dataCacheWithIndex then
        cfgTable.dataCacheWithIndex = nil
        cfgTable.dataCacheWithIndex = _G.MakeWeakTable()
        Log.Debug("[DataConfigManagerNew:ReloadTable] Clear dataCacheWithIndex")
      end
      self.BinDataManager:LoadBinData(tblInfo.name, false, true)
      Log.Debug("[DataConfigManagerNew:ReloadTable] Reload Config Table: ", tblInfo.name)
    else
      Log.Error("[DataConfigManagerNew:ReloadTable] Reload Config Table Failed: ", tableId)
      return false
    end
  else
    self.BinDataManager:LoadBinData(TableName, false, true)
    Log.Warning("[DataConfigManagerNew:ReloadTable] has not been loaded, reload bin data : ", TableName)
  end
  return true
end

function DataConfigManagerNew:PrintLoadedConfigTables()
  for id, _ in pairs(self.__dataTables) do
    local tblName = self.__configTableInfo[id].name
    Log.Debug("[DataConfigManagerNew:PrintLoadedConfigTables] Loaded Table Name: ", tblName)
  end
end

return DataConfigManagerNew
