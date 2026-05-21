local Singleton = _G.Singleton
local NRCProfilerLog = Singleton:Extend("NRCProfilerLog")

function NRCProfilerLog:Ctor(name)
  self.name = name or "NRCProfilerLog"
  Singleton.Ctor(self, self.name)
  self.isEnable = true
  self.clickTime = {}
  self.startTime = {}
  self.endTime = {}
  self.openTime = {}
  self.telePortStartTime = 0
  self.telePortEndTime = 0
  self.telePortStartPos = _G.FVectorZero
  self.telePortEndPos = _G.FVectorZero
  self.teleDis = 0
  self.panelClickStartTime = {}
  self.panelClickEndTime = {}
  self.panelLoadStartTime = {}
  self.panelLoadEndTime = {}
  self.panelCreateStartTime = {}
  self.panelCreateEndTime = {}
  self.panelAddToViewportStartTime = {}
  self.panelAddToViewportEndTime = {}
  self.protoReqTime = {}
  self.protoRspTime = {}
  self.panelConstructStartTime = {}
  self.panelConstructEndTime = {}
  self.panelOpenAnimStartTime = {}
  self.panelOpenAnimEndTime = {}
  self.panelActiveStartTime = {}
  self.panelActiveEndTime = {}
  self.panelDestructStartTime = {}
  self.panelDestructEndTime = {}
  self.panelRequireStartTime = {}
  self.panelRequireEndTime = {}
  self.panelPreloadStartTime = {}
  self.panelPreloadEndTime = {}
  self.ExportData = {}
  self.stringFormatTotalCostTotalUs = 0
  self.stringFormatTotalCostMaxUs = 0
  self.stringFormatTotalCostCount = 0
  self.sumSubUMGTime = 0
  self.sumNoSubUMGTime = 0
  self.sumIdx = {
    1,
    1,
    1,
    1,
    0,
    0,
    1,
    0,
    0,
    1,
    1
  }
end

function NRCProfilerLog:Free()
  Singleton.Free(self)
end

NRCProfilerLog.OpenPanelStage = {
  Click = 1,
  Load = 2,
  Create = 3,
  AddToViewport = 4,
  Proto = 5,
  Construct = 6,
  Active = 7,
  Anim = 8,
  Destruct = 9,
  Resource = 10,
  PreloadRes = 11
}

function NRCProfilerLog:DumpSumTimeLog()
  Log.Error("UMG_SubUMG" .. self.sumSubUMGTime)
  Log.Error("UMG_NoSubUMG" .. self.sumNoSubUMGTime)
  self.sumSubUMGTime = 0
  self.sumNoSubUMGTime = 0
end

function NRCProfilerLog:NRCPanelProfilerLog(open, start, panelName)
  if self:IsStopProfiler() or nil == panelName then
    return
  end
  if nil == self.startTime[panelName] then
    self.startTime[panelName] = 0
  end
  if nil == self.endTime[panelName] then
    self.endTime[panelName] = 0
  end
  if open then
    if start then
      Log.Debug(string.format("[NRCPanelProfilerLog] [%s] \230\137\147\229\188\128\233\157\162\230\157\191:", panelName))
      self.startTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      self.endTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      local delta = math.floor(self.endTime[panelName] - self.startTime[panelName])
      self.openTime[panelName] = delta / 1000.0
      Log.Debug(string.format("[NRCPanelProfilerLog] [%s] \230\137\147\229\188\128\233\157\162\230\157\191\232\128\151\230\151\182:\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
    end
  elseif start then
    Log.Debug(string.format("[NRCPanelProfilerLog] [%s] \229\133\179\233\151\173\233\157\162\230\157\191:", panelName))
    self.startTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
  else
    self.endTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    local delta = math.floor(self.endTime[panelName] - self.startTime[panelName])
    Log.Debug(string.format("[NRCPanelProfilerLog] [%s] \229\133\179\233\151\173\233\157\162\230\157\191\232\128\151\230\151\182:\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
    self.startTime[panelName] = nil
    self.endTime[panelName] = nil
  end
end

function NRCProfilerLog:NRCClickBtn(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelClickStartTime[panelName] == nil then
        self.panelClickStartTime[panelName] = {}
      end
      self.panelClickStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelClickEndTime[panelName] then
        self.panelClickEndTime[panelName] = {}
      end
      self.panelClickEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelClickStartTime[panelName] then
        local delta = self.panelClickEndTime[panelName] - self.panelClickStartTime[panelName]
        Log.Debug(string.format("[NRCPanelLoadProfilerLog] [%s] \233\157\162\230\157\191Click\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self.clickTime[panelName] = delta
        self:SaveCSVData(self.OpenPanelStage.Click, panelName, delta / 1000.0)
      end
      self.panelClickStartTime[panelName] = nil
      self.panelClickEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCTeleportProfilerLog(start, startPos, endPos)
  if self:IsStopProfiler() then
    return
  end
  if start then
    self.telePortStartTime = UE4.UNRCStatics.GetMilliSeconds()
    self.telePortStartPos = startPos
    self.telePortEndPos = endPos
    self.teleDis = UE4.FVector.Dist(startPos, endPos)
    Log.Debug(string.format("[NRCTeleMoveProfilerLog] [StartPos:%f %f %f EndPos:%f %f %f Distance:%f] \229\188\128\229\167\139\228\188\160\233\128\129", startPos.X, startPos.Y, startPos.Z, endPos.X, endPos.Y, endPos.Z, self.teleDis))
  else
    self.telePortEndTime = UE4.UNRCStatics.GetMilliSeconds()
    local delta = math.floor(self.telePortEndTime - self.telePortStartTime)
    Log.Debug(string.format("[NRCTeleMoveProfilerLog] [StartPos:%f %f %f EndPos:%f %f %f Distance:%f] \231\187\147\230\157\159\228\188\160\233\128\129 \232\128\151\230\151\182\227\128\144%d ms\227\128\145", self.telePortStartPos.X, self.telePortStartPos.Y, self.telePortStartPos.Z, self.telePortEndPos.X, self.telePortEndPos.Y, self.telePortEndPos.Z, self.teleDis, delta))
  end
end

function NRCProfilerLog:AutoStopClick(panelName)
  if self.panelClickStartTime[panelName] and not self.panelClickEndTime[panelName] then
    self:NRCClickBtn(false, panelName)
  end
end

function NRCProfilerLog:NRCPanelLoad(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  self:AutoStopClick(panelName)
  if panelName then
    if bStart then
      if self.panelLoadStartTime[panelName] == nil then
        self.panelLoadStartTime[panelName] = {}
      end
      self.panelLoadStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelLoadEndTime[panelName] then
        self.panelLoadEndTime[panelName] = {}
      end
      self.panelLoadEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelLoadStartTime[panelName] then
        local delta = self.panelLoadEndTime[panelName] - self.panelLoadStartTime[panelName]
        Log.Debug(string.format("[NRCPanelLoadProfilerLog] [%s] \233\157\162\230\157\191AsyncLoad\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Load, panelName, delta / 1000.0)
      end
      self.panelLoadStartTime[panelName] = nil
      self.panelLoadEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelCreate(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelCreateStartTime[panelName] == nil then
        self.panelCreateStartTime[panelName] = {}
      end
      self.panelCreateStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelCreateEndTime[panelName] then
        self.panelCreateEndTime[panelName] = {}
      end
      self.panelCreateEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelCreateStartTime[panelName] then
        local delta = self.panelCreateEndTime[panelName] - self.panelCreateStartTime[panelName]
        Log.Debug(string.format("[NRCPanelCreateProfilerLog] [%s] \233\157\162\230\157\191Create\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Create, panelName, delta / 1000.0)
      end
      self.panelCreateStartTime[panelName] = nil
      self.panelCreateEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelAddToViewport(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelAddToViewportStartTime[panelName] == nil then
        self.panelAddToViewportStartTime[panelName] = {}
      end
      self.panelAddToViewportStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelAddToViewportEndTime[panelName] then
        self.panelAddToViewportEndTime[panelName] = {}
      end
      self.panelAddToViewportEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelAddToViewportStartTime[panelName] then
        local delta = self.panelAddToViewportEndTime[panelName] - self.panelAddToViewportStartTime[panelName]
        Log.Debug(string.format("[NRCPanelAddToViewportProfilerLog] [%s] \233\157\162\230\157\191AddToViewport\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.AddToViewport, panelName, delta / 1000.0)
        if "SubUMGTest" == panelName then
          self.sumSubUMGTime = self.sumSubUMGTime + delta / 1000.0
        elseif "NoSubUMGTest" == panelName then
          self.sumNoSubUMGTime = self.sumNoSubUMGTime + delta / 1000.0
        end
      end
      self.panelLoadStartTime[panelName] = nil
      self.panelLoadEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCProtoReqAndRspInterval(protocolID, bReq, panelName)
  if self:IsStopProfiler() then
    return
  end
  local messageName = ProtoCMD:GetMessageName(protocolID)
  if bReq then
    if self.protoReqTime[protocolID] == nil then
      self.protoReqTime[protocolID] = {}
    end
    self.protoReqTime[protocolID] = UE4.UNRCStatics.GetTimestampMicroseconds()
  else
    if nil == self.protoRspTime[protocolID] then
      self.protoRspTime[protocolID] = {}
    end
    self.protoRspTime[protocolID] = UE4.UNRCStatics.GetTimestampMicroseconds()
    if self.protoReqTime[protocolID] then
      local delta = math.floor(self.protoRspTime[protocolID] - self.protoReqTime[protocolID])
      Log.Debug(string.format("[NRCPanelProtoProfilerLog] [%s] ProtoRsp-\229\144\142\229\143\176\229\155\158\229\140\133\230\151\182\233\149\191:\227\128\144%f ms\227\128\145", messageName, delta / 1000.0))
      self:SaveCSVData(self.OpenPanelStage.Proto, panelName, delta / 1000.0)
    end
    self.protoReqTime[protocolID] = nil
    self.protoRspTime[protocolID] = nil
  end
end

function NRCProfilerLog:NRCPanelConstruct(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelConstructStartTime[panelName] == nil then
        self.panelConstructStartTime[panelName] = {}
      end
      self.panelConstructStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelConstructEndTime[panelName] then
        self.panelConstructEndTime[panelName] = {}
      end
      self.panelConstructEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelConstructStartTime[panelName] then
        local delta = self.panelConstructEndTime[panelName] - self.panelConstructStartTime[panelName]
        Log.Debug(string.format("[NRCPanelConstructProfilerLog] [%s] \233\157\162\230\157\191Construct\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Construct, panelName, delta / 1000.0)
      end
      self.panelConstructStartTime[panelName] = nil
      self.panelConstructEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelOpenAnimation(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelOpenAnimStartTime[panelName] == nil then
        self.panelOpenAnimStartTime[panelName] = {}
      end
      self.panelOpenAnimStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelOpenAnimEndTime[panelName] then
        self.panelOpenAnimEndTime[panelName] = {}
      end
      self.panelOpenAnimEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelOpenAnimStartTime[panelName] then
        local delta = self.panelOpenAnimEndTime[panelName] - self.panelOpenAnimStartTime[panelName]
        Log.Debug(string.format("[NRCPanelOpenAnimProfilerLog] [%s] \233\157\162\230\157\191OpenAnimation\232\128\151\230\151\182: \227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Anim, panelName, delta / 1000.0)
      end
      self.panelOpenAnimStartTime[panelName] = nil
      self.panelOpenAnimEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelActive(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelActiveStartTime[panelName] == nil then
        self.panelActiveStartTime[panelName] = {}
      end
      self.panelActiveStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelActiveEndTime[panelName] then
        self.panelActiveEndTime[panelName] = {}
      end
      self.panelActiveEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelActiveStartTime[panelName] then
        local delta = self.panelActiveEndTime[panelName] - self.panelActiveStartTime[panelName]
        Log.Debug(string.format("[NRCPanelActiveProfilerLog] [%s] \233\157\162\230\157\191Active\232\128\151\230\151\182\239\188\154\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Active, panelName, delta / 1000.0)
      end
      self.panelActiveStartTime[panelName] = nil
      self.panelActiveEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelRequireRes(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelRequireStartTime[panelName] == nil then
        self.panelRequireStartTime[panelName] = {}
      end
      self.panelRequireStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelRequireEndTime[panelName] then
        self.panelRequireEndTime[panelName] = {}
      end
      self.panelRequireEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelRequireStartTime[panelName] then
        local delta = self.panelRequireEndTime[panelName] - self.panelRequireStartTime[panelName]
        Log.Debug(string.format("[NRCPanelRequireResProfilerLog] [%s] \233\157\162\230\157\191\229\138\160\232\189\189\232\181\132\230\186\144\232\128\151\230\151\182\239\188\154\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Resource, panelName, delta / 1000.0)
      end
      self.panelRequireStartTime[panelName] = nil
      self.panelRequireEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelPreloadRes(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelPreloadStartTime[panelName] == nil then
        self.panelPreloadStartTime[panelName] = {}
      end
      self.panelPreloadStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelPreloadEndTime[panelName] then
        self.panelPreloadEndTime[panelName] = {}
      end
      self.panelPreloadEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelPreloadStartTime[panelName] then
        local delta = self.panelPreloadEndTime[panelName] - self.panelPreloadStartTime[panelName]
        Log.Debug(string.format("[NRCPanelRequireResProfilerLog] [%s] \233\157\162\230\157\191\233\162\132\229\138\160\232\189\189\232\181\132\230\186\144\232\128\151\230\151\182\239\188\154\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.PreloadRes, panelName, delta / 1000.0)
      end
      self.panelPreloadStartTime[panelName] = nil
      self.panelPreloadEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:NRCPanelDestruct(bStart, panelName)
  if self:IsStopProfiler() then
    return
  end
  if panelName then
    if bStart then
      if self.panelDestructStartTime[panelName] == nil then
        self.panelDestructStartTime[panelName] = {}
      end
      self.panelDestructStartTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
    else
      if nil == self.panelDestructEndTime[panelName] then
        self.panelDestructEndTime[panelName] = {}
      end
      self.panelDestructEndTime[panelName] = UE4.UNRCStatics.GetTimestampMicroseconds()
      if self.panelDestructStartTime[panelName] then
        local delta = self.panelDestructEndTime[panelName] - self.panelDestructStartTime[panelName]
        Log.Debug(string.format("[NRCPanelDestructProfilerLog] [%s] \233\157\162\230\157\191Destruct\232\128\151\230\151\182\239\188\154\227\128\144%f ms\227\128\145", panelName, delta / 1000.0))
        self:SaveCSVData(self.OpenPanelStage.Destruct, panelName, delta / 1000.0)
      end
      self.panelDestructStartTime[panelName] = nil
      self.panelDestructEndTime[panelName] = nil
    end
  end
end

function NRCProfilerLog:SaveCSVData(stage, panelName, mSeconds)
  if self:IsStopProfiler() then
    return
  end
  if self.ExportData[panelName] == nil then
    self.ExportData[panelName] = {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    }
  end
  self.ExportData[panelName][stage] = mSeconds
end

function NRCProfilerLog:ExportCSVData()
  if self:IsStopProfiler() then
    return
  end
  local ExportData = {
    "Click(ms)",
    "AsyncLoad(ms)",
    "Create(ms)",
    "AddToViewport(ms)",
    "ProtoRsp(ms)",
    "Construct(ms)",
    "Active(ms)",
    "Anim(ms)",
    "Destruct(ms)",
    "Res(ms)",
    "Preload(ms)",
    "Total(ms)"
  }
  local filePath = ""
  if _G.RocoEnv.IS_EDITOR then
    filePath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(UE4.UBlueprintPathsLibrary.ProjectSavedDir()) .. "NRCProfilerLogOpenPanel.csv"
  else
    filePath = UE4.UBlueprintPathsLibrary.ProjectSavedDir() .. "NRCProfilerLogOpenPanel.csv"
  end
  local headLine = ""
  for k, v in ipairs(ExportData) do
    headLine = headLine .. "," .. string.format("%q", tostring(v))
  end
  local content = headLine .. "\n"
  for PanelName, row in pairs(self.ExportData) do
    local line = tostring(PanelName) .. ","
    local sum = 0
    for j, val in ipairs(row) do
      if self.sumIdx[j] and 1 == self.sumIdx[j] then
        sum = sum + val
      end
      line = line .. string.format("%q", tostring(val))
      line = line .. ","
      Log.Debug("show me ::::", line, sum, val)
    end
    local delta = self.openTime[PanelName]
    if delta then
      local clickTime = row[NRCProfilerLog.OpenPanelStage.Click]
      if clickTime then
        delta = delta + clickTime
      end
      local resDelta = row[NRCProfilerLog.OpenPanelStage.Resource]
      if resDelta then
        delta = delta + resDelta
      end
      line = line .. delta .. ","
    else
      line = line .. "Nil" .. ","
    end
    line = line .. "\n"
    content = content .. line
  end
  UE4.UNRCStatics.WriteToFile(filePath, content)
  self:DumpStringFormatExtraCost()
end

function NRCProfilerLog:ClearCSVData()
  self.ExportData = {}
  self.stringFormatTotalCostTotalUs = 0
  self.stringFormatTotalCostMaxUs = 0
  self.stringFormatTotalCostCount = 0
end

function NRCProfilerLog:RecordStringFormatCost(totalUs)
  if self:IsStopProfiler() then
    return
  end
  if not totalUs or totalUs <= 0 then
    return
  end
  self.stringFormatTotalCostTotalUs = (self.stringFormatTotalCostTotalUs or 0) + totalUs
  self.stringFormatTotalCostCount = (self.stringFormatTotalCostCount or 0) + 1
  if totalUs > (self.stringFormatTotalCostMaxUs or 0) then
    self.stringFormatTotalCostMaxUs = totalUs
  end
end

function NRCProfilerLog:DumpStringFormatExtraCost()
  local totalCount = self.stringFormatTotalCostCount or 0
  local totalTotalUs = self.stringFormatTotalCostTotalUs or 0
  local totalMaxUs = self.stringFormatTotalCostMaxUs or 0
  local totalAvgUs = totalCount > 0 and totalTotalUs / totalCount or 0
  Log.Debug(string._raw_format("[NRCStringFormatProfilerLog] " .. "total_calls=%d total=%.3fms avg=%.2fus max=%.2fus", totalCount, totalTotalUs / 1000.0, totalAvgUs, totalMaxUs))
end

function NRCProfilerLog:IsStopProfiler()
  return not self.isEnable or not _G.GlobalConfig.bShowProfilerLog
end

return NRCProfilerLog
