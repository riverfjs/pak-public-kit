local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIStatistics = {
  LastReportTime = 0,
  LastError = nil,
  LastValidationResult = nil,
  Data = {
    Validation = {
      Total = 0,
      Success = 0,
      Fail = 0,
      Duration = 0
    },
    Cache = {
      Hit = 0,
      Miss = 0,
      Evict = 0,
      Total = 0,
      ByTypeName = {}
    },
    Provider = {ConfigCount = 0, QueryCount = 0},
    Error = {Total = 0, Critical = 0},
    Performance = {
      Operations = 0,
      ByOperationType = {},
      ByTypeName = {}
    }
  }
}

local function ResetStatisticsData(self)
  self.Data = {
    Validation = {
      Total = 0,
      Success = 0,
      Fail = 0,
      Duration = 0
    },
    Cache = {
      Hit = 0,
      Miss = 0,
      Evict = 0,
      Total = 0,
      ByTypeName = {}
    },
    Provider = {ConfigCount = 0, QueryCount = 0},
    Error = {Total = 0, Critical = 0},
    Performance = {
      Operations = 0,
      ByOperationType = {},
      ByTypeName = {}
    }
  }
  self.LastError = nil
  self.LastValidationResult = nil
  if RTTISettings:Get("Statistics.EnableCollection") then
    self.Data.History = {}
    self.Data.ErrorMessages = {}
    self.Data.ErrorEntries = {}
    self.Data.LastReportTime = os.time()
  end
end

function RTTIStatistics:Initialize()
  self.LastReportTime = os.time()
  ResetStatisticsData(self)
end

function RTTIStatistics:RecordOperation(OperationType, Details)
  self.Data.Performance.Operations = self.Data.Performance.Operations + 1
  local FinalOperationType = OperationType or "Unknown"
  local Duration = RTTIBase.IsValidTableValue(Details) and RTTIBase.IsValidNumberValue(Details.Duration) and Details.Duration or 0
  local ByOperationType = self.Data.Performance.ByOperationType
  if RTTIBase.IsValidTableValue(ByOperationType) then
    local Entry = ByOperationType[FinalOperationType]
    if not Entry then
      Entry = {Count = 0, Duration = 0}
      ByOperationType[FinalOperationType] = Entry
    end
    Entry.Count = Entry.Count + 1
    Entry.Duration = Entry.Duration + Duration
  end
  if RTTIBase.IsValidTableValue(Details) and RTTIBase.IsValidStringValue(Details.TypeName) then
    local ByTypeName = self.Data.Performance.ByTypeName
    if RTTIBase.IsValidTableValue(ByTypeName) then
      local Entry = ByTypeName[Details.TypeName]
      if not Entry then
        Entry = {Count = 0, Duration = 0}
        ByTypeName[Details.TypeName] = Entry
      end
      Entry.Count = Entry.Count + 1
      Entry.Duration = Entry.Duration + Duration
    end
  end
  self:CheckAutoReport()
  if RTTISettings:Get("Statistics.EnableCollection") and self.Data.History then
    local HistoryEntry = {
      Type = FinalOperationType,
      Details = Details or {},
      Timestamp = os.time()
    }
    table.insert(self.Data.History, HistoryEntry)
    local MaxSize = RTTISettings:Get("Statistics.MaxHistorySize", 1000)
    if MaxSize < #self.Data.History then
      table.remove(self.Data.History, 1)
    end
  end
end

function RTTIStatistics:RecordValidation(Success, Duration)
  local Validation = self.Data.Validation
  Validation.Total = Validation.Total + 1
  if Success then
    Validation.Success = Validation.Success + 1
  else
    Validation.Fail = Validation.Fail + 1
  end
  Validation.Duration = Validation.Duration + (Duration or 0)
end

function RTTIStatistics:RecordCacheHit(TypeName)
  self.Data.Cache.Hit = self.Data.Cache.Hit + 1
  if RTTIBase.IsValidStringValue(TypeName) and RTTIBase.IsValidTableValue(self.Data.Cache.ByTypeName) then
    local Entry = self.Data.Cache.ByTypeName[TypeName]
    if not Entry then
      Entry = {
        Hit = 0,
        Miss = 0,
        Evict = 0,
        Total = 0
      }
      self.Data.Cache.ByTypeName[TypeName] = Entry
    end
    Entry.Hit = Entry.Hit + 1
  end
end

function RTTIStatistics:RecordCacheMiss(TypeName)
  self.Data.Cache.Miss = self.Data.Cache.Miss + 1
  if RTTIBase.IsValidStringValue(TypeName) and RTTIBase.IsValidTableValue(self.Data.Cache.ByTypeName) then
    local Entry = self.Data.Cache.ByTypeName[TypeName]
    if not Entry then
      Entry = {
        Hit = 0,
        Miss = 0,
        Evict = 0,
        Total = 0
      }
      self.Data.Cache.ByTypeName[TypeName] = Entry
    end
    Entry.Miss = Entry.Miss + 1
  end
end

function RTTIStatistics:RecordCacheEviction(TypeName)
  self.Data.Cache.Evict = self.Data.Cache.Evict + 1
  if RTTIBase.IsValidStringValue(TypeName) and RTTIBase.IsValidTableValue(self.Data.Cache.ByTypeName) then
    local Entry = self.Data.Cache.ByTypeName[TypeName]
    if not Entry then
      Entry = {
        Hit = 0,
        Miss = 0,
        Evict = 0,
        Total = 0
      }
      self.Data.Cache.ByTypeName[TypeName] = Entry
    end
    Entry.Evict = Entry.Evict + 1
  end
end

function RTTIStatistics:RecordCacheAddEntry(TypeName)
  self.Data.Cache.Total = self.Data.Cache.Total + 1
  if RTTIBase.IsValidStringValue(TypeName) and RTTIBase.IsValidTableValue(self.Data.Cache.ByTypeName) then
    local Entry = self.Data.Cache.ByTypeName[TypeName]
    if not Entry then
      Entry = {
        Hit = 0,
        Miss = 0,
        Evict = 0,
        Total = 0
      }
      self.Data.Cache.ByTypeName[TypeName] = Entry
    end
    Entry.Total = Entry.Total + 1
  end
end

function RTTIStatistics:RecordCachRemoveEntry(TypeName)
  self.Data.Cache.Total = self.Data.Cache.Total - 1
  if RTTIBase.IsValidStringValue(TypeName) and RTTIBase.IsValidTableValue(self.Data.Cache.ByTypeName) then
    local Entry = self.Data.Cache.ByTypeName[TypeName]
    if not Entry then
      Entry = {
        Hit = 0,
        Miss = 0,
        Evict = 0,
        Total = 0
      }
      self.Data.Cache.ByTypeName[TypeName] = Entry
    end
    Entry.Total = Entry.Total - 1
  end
end

function RTTIStatistics:RecordProviderRegister()
  self.Data.Provider.ConfigCount = self.Data.Provider.ConfigCount + 1
end

function RTTIStatistics:RecordProviderQuery()
  self.Data.Provider.QueryCount = self.Data.Provider.QueryCount + 1
end

function RTTIStatistics:RecordError(IsCritical, MessageFormat, ...)
  self.Data.Error.Total = self.Data.Error.Total + 1
  if IsCritical then
    self.Data.Error.Critical = self.Data.Error.Critical + 1
  end
  local Success, ErrorMessage = pcall(string.format, MessageFormat or "", ...)
  if not Success then
    ErrorMessage = tostring(MessageFormat)
  end
  self.LastError = {
    Timestamp = os.time(),
    IsCritical = IsCritical and true or false,
    Message = ErrorMessage or ""
  }
  if RTTISettings:Get("Statistics.EnableCollection") then
    if self.Data.ErrorMessages then
      table.insert(self.Data.ErrorMessages, ErrorMessage)
    end
    if self.Data.ErrorEntries then
      table.insert(self.Data.ErrorEntries, RTTIBase.DeepCopy(self.LastError))
      local MaxErrorEntries = RTTISettings:Get("Statistics.MaxErrorEntries", 200)
      if MaxErrorEntries < #self.Data.ErrorEntries then
        table.remove(self.Data.ErrorEntries, 1)
      end
    end
  end
end

function RTTIStatistics:GetLastError()
  return self.LastError and RTTIBase.DeepCopy(self.LastError) or nil
end

function RTTIStatistics:GetRecentErrors(Count)
  Count = Count or 10
  local Result = {}
  if not RTTISettings:Get("Statistics.EnableCollection") or not self.Data.ErrorEntries then
    return Result
  end
  for Index = #self.Data.ErrorEntries, 1, -1 do
    table.insert(Result, RTTIBase.DeepCopy(self.Data.ErrorEntries[Index]))
    if Count <= #Result then
      break
    end
  end
  return Result
end

function RTTIStatistics:SetLastValidationResult(ValidationResult)
  if type(ValidationResult) ~= "table" then
    return
  end
  self.LastValidationResult = {
    Timestamp = os.time(),
    TypeName = ValidationResult.TypeName,
    Success = ValidationResult.Success and true or false,
    Errors = RTTIBase.DeepCopy(ValidationResult.Errors or {})
  }
end

function RTTIStatistics:GetLastValidationResult()
  return self.LastValidationResult and RTTIBase.DeepCopy(self.LastValidationResult) or nil
end

function RTTIStatistics:GetReport()
  return RTTIBase.DeepCopy(self.Data)
end

function RTTIStatistics:ExportStats(Format)
  local Report = self:GetReport()
  if "summary" == Format then
    return string.format("Validation: %d/%d success, Cache Hit/Miss/Evict=%d/%d/%d", Report.Validation.Success, Report.Validation.Total, Report.Cache.Hit, Report.Cache.Miss, Report.Cache.Evict)
  elseif "json" == Format then
    local Encode = function(TableData)
      if type(TableData) ~= "table" then
        if type(TableData) == "string" then
          return string.format("\"%s\"", TableData)
        end
        return tostring(TableData)
      end
      local Parts = {}
      for Key, Value in pairs(TableData) do
        table.insert(Parts, string.format("\"%s\":%s", tostring(Key), Encode(Value)))
      end
      return "{" .. table.concat(Parts, ",") .. "}"
    end
    return Encode(Report)
  end
  return Report
end

function RTTIStatistics:Reset()
  ResetStatisticsData(self)
  self.LastReportTime = os.time()
end

function RTTIStatistics:CheckAutoReport()
  local ReportInterval = RTTISettings:Get("Statistics.ReportInterval")
  if not ReportInterval or ReportInterval <= 0 then
    return
  end
  local CurrentTime = os.time()
  local TimeSinceLastReport = CurrentTime - self.LastReportTime
  if ReportInterval <= TimeSinceLastReport then
    self:GenerateAutoReport()
    self.LastReportTime = CurrentTime
  end
end

function RTTIStatistics:GenerateAutoReport()
  local Report = self:GetReport()
  local Summary = {
    Timestamp = os.time(),
    ValidationSummary = {
      TotalOperations = Report.Validation.Total,
      SuccessRate = Report.Validation.Total > 0 and string.format("%.2f%%", Report.Validation.Success / Report.Validation.Total * 100) or "N/A",
      AverageDuration = Report.Validation.Total > 0 and string.format("%.4fs", Report.Validation.Duration / Report.Validation.Total) or "N/A"
    },
    CacheSummary = {
      HitRate = Report.Cache.Hit + Report.Cache.Miss > 0 and string.format("%.2f%%", Report.Cache.Hit / (Report.Cache.Hit + Report.Cache.Miss) * 100) or "N/A",
      TotalOperations = Report.Cache.Hit + Report.Cache.Miss,
      EvictionCount = Report.Cache.Evict
    },
    Provider = {
      ConfigCount = Report.Provider.ConfigCount,
      QueryCount = Report.Provider.QueryCount,
      AvgQueryPerConfig = Report.Provider.ConfigCount > 0 and string.format("%.2f", Report.Provider.QueryCount / Report.Provider.ConfigCount) or "N/A"
    },
    PerformanceSummary = {
      TotalOperations = Report.Performance.Operations,
      ErrorRate = Report.Performance.Operations > 0 and string.format("%.2f%%", Report.Error.Total / Report.Performance.Operations * 100) or "N/A"
    }
  }
  if RTTISettings:Get("Statistics.EnableCollection") and self.Data.History then
    table.insert(self.Data.History, {
      Type = "AutoReport",
      Details = Summary,
      Timestamp = os.time()
    })
  end
  return Summary
end

function RTTIStatistics:GetRecentReports(Count)
  Count = Count or 1
  local Reports = {}
  if RTTISettings:Get("Statistics.EnableCollection") and self.Data.History then
    for Index = #self.Data.History, 1, -1 do
      local Entry = self.Data.History[Index]
      if Entry.Type == "AutoReport" then
        table.insert(Reports, Entry)
        if Count <= #Reports then
          break
        end
      end
    end
  end
  return Reports
end

return RTTIStatistics
