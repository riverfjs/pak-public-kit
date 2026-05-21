local UMG_AutoBattleTestPanel_C = _G.NRCPanelBase:Extend("UMG_AutoBattleTestPanel_C")

function UMG_AutoBattleTestPanel_C:OnActive()
  self.IsPress = false
  self:OnAddEventListener()
  self:InitDefaultInput()
end

function UMG_AutoBattleTestPanel_C:OnDeactive()
end

function UMG_AutoBattleTestPanel_C:OnAddEventListener()
  self.NRCButton_157.OnClicked:Add(self, self.OnClickDownloadBattleData)
  self.NRCButton.OnClicked:Add(self, self.OnClickPlayAutoBattle)
  self.NRCButton_1.OnClicked:Add(self, self.OnClickOneKeyFinish)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnClickCloseBtn)
end

function UMG_AutoBattleTestPanel_C:InitDefaultInput()
  local endTime = os.date("%Y-%m-%d-%H-%M-%S")
  local startTimeMs = os.time() - 259200
  local startTime = os.date("%Y-%m-%d-%H-%M-%S", startTimeMs)
  self.InputTextName_1:SetText(startTime)
  self.InputTextName_2:SetText(endTime)
  self.InputTextName:SetText("2")
end

function UMG_AutoBattleTestPanel_C:OnClickDownloadBattleData()
  if self.IsPress then
    return
  end
  self.IsPress = true
  
  local function Execute()
    local command = self:GetExecuteCommand()
    if not command then
      self.IsPress = false
      return
    end
    local status, _ = os.execute(command)
    if status then
      local num = self:GetDownloadBattleDataCount()
      local test = string.format("\228\184\139\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174\230\136\144\229\138\159\239\188\140\230\136\152\230\150\151\230\149\176\230\141\174\229\183\178\228\184\139\232\189\189\229\136\176AutoBattle\228\184\173\239\188\140\229\133\177\228\184\139\232\189\189%d\230\136\152\230\150\151\230\149\176\230\141\174", num)
      self:ShowTips(test, UE4.UNRCStatics.HexToSlateColor("#ffff00ff"))
    else
      self:ShowTips("\228\184\139\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\140\232\175\183\230\163\128\230\159\165python\232\132\154\230\156\172", UE4.UNRCStatics.HexToSlateColor("#ff0000ff"))
    end
    self.IsPress = false
  end
  
  self:ShowTips("\229\188\128\229\167\139\228\184\139\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174\227\128\130\227\128\130\227\128\130", UE4.UNRCStatics.HexToSlateColor("#ffff00ff"), Execute, 1)
end

function UMG_AutoBattleTestPanel_C:OnClickPlayAutoBattle()
  if self.IsPress then
    return
  end
  self.IsPress = true
  
  local function Execute()
    _G.BattleAutoTest:StartAutoPlayBattleRecords("")
    self.IsPress = false
    self:DoClose()
  end
  
  self:ShowTips("\229\188\128\229\167\139\230\146\173\230\148\190\230\136\152\230\150\151\230\149\176\230\141\174\227\128\130\227\128\130\227\128\130", UE4.UNRCStatics.HexToSlateColor("#ffff00ff"), Execute, 1)
end

function UMG_AutoBattleTestPanel_C:OnClickOneKeyFinish()
  if self.IsPress then
    return
  end
  self.IsPress = true
  
  local function Execute()
    local command = self:GetExecuteCommand()
    if not command then
      self.IsPress = false
      return
    end
    local status, _ = os.execute(command)
    if status then
      _G.BattleAutoTest:StartAutoPlayBattleRecords("")
      self.IsPress = false
      self:DoClose()
    else
      self:ShowTips("\228\184\139\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\140\232\175\183\230\163\128\230\159\165python\232\132\154\230\156\172", UE4.UNRCStatics.HexToSlateColor("#ff0000ff"))
    end
    self.IsPress = false
  end
  
  self:ShowTips("\229\188\128\229\167\139\228\184\128\233\148\174\230\137\167\232\161\140\227\128\130\227\128\130\227\128\130", UE4.UNRCStatics.HexToSlateColor("#ffff00ff"), Execute, 1)
end

function UMG_AutoBattleTestPanel_C:GetExecuteCommand()
  local platformId = tonumber(self.InputTextName:GetText())
  local startTime = self:GetInputTimestamp(self.InputTextName_1:GetText())
  local endTime = self:GetInputTimestamp(self.InputTextName_2:GetText())
  if 1 ~= platformId and 2 ~= platformId and 10 ~= platformId then
    self:ShowTips("\229\185\179\229\143\176\232\190\147\229\133\165\231\188\150\229\143\183\230\156\137\232\175\175", UE4.UNRCStatics.HexToSlateColor("#ff0000ff"))
    return
  end
  if startTime > endTime then
    self:ShowTips("\232\181\183\229\167\139\230\151\182\233\151\180\232\166\129\229\176\143\228\186\142\231\187\147\230\157\159\230\151\182\233\151\180", UE4.UNRCStatics.HexToSlateColor("#ff0000ff"))
    return
  end
  local engineDir = UE.UNRCStatics.ConvertToAbsolutePath(UE.UBlueprintPathsLibrary.EngineDir(), false)
  local pythonDir = string.format("%sBinaries/ThirdParty/Python3/Win64/python.exe", engineDir)
  Log.Debug("UMG_AutoBattleTestPanel_C:GetExecuteCommand==engineDir==", pythonDir)
  local absPath1 = UE.UNRCStatics.ConvertToAbsolutePath(UE4.UBlueprintPathsLibrary.ProjectDir(), false)
  local script_path = string.format("%sTools/Python3Tools/DownloadBattleCrashRecords/download_record.py", absPath1)
  Log.Debug("UMG_AutoBattleTestPanel_C:GetExecuteCommand==script_path==", script_path)
  local absPath2 = UE.UNRCStatics.ConvertToAbsolutePath(UE4.UBlueprintPathsLibrary.ProjectSavedDir(), false)
  local downloadDir = string.format("%sAutoBattle", absPath2)
  Log.Debug("UMG_AutoBattleTestPanel_C:GetExecuteCommand==downloadDir==", downloadDir)
  return string.format("%s %s %d %d %d %s", pythonDir, script_path, platformId, startTime, endTime, downloadDir)
end

function UMG_AutoBattleTestPanel_C:GetInputTimestamp(timeStr)
  local year, month, day, hour, minute, second = timeStr:match("(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)")
  local date_table = os.date("*t", os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    minute = tonumber(minute),
    second = tonumber(second)
  }))
  local timestamp = os.time(date_table) * 1000
  return timestamp
end

function UMG_AutoBattleTestPanel_C:GetDownloadBattleDataCount()
  local num = 0
  local File = string.format("%sAutoBattle/%s.txt", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "AutoPlayBattleRecords")
  File = UE.UNRCStatics.ConvertToAbsolutePath(File, false)
  Log.Debug("UMG_AutoBattleTestPanel_C:GetDownloadBattleDataCount==File==", File)
  local result, success = UE4.UNRCStatics.LoadToString(File)
  if success then
    local commandString = string.Split(result, "\n")
    if commandString then
      num = #commandString - 2
    end
  end
  return num
end

function UMG_AutoBattleTestPanel_C:ShowTips(content, color, cb, time)
  self.Tip:SetText(content)
  self.Tip:SetColorAndOpacity(color)
  if cb then
    self.DelayHandle = self:DelaySeconds(time, cb, self)
  end
end

function UMG_AutoBattleTestPanel_C:OnCancelDelayHandle()
  if self.DelayHandle then
    self:CancelDelayByID(self.DelayHandle)
    self.DelayHandle = nil
  end
end

function UMG_AutoBattleTestPanel_C:OnClickCloseBtn()
  self:OnCancelDelayHandle()
  self:DoClose()
end

return UMG_AutoBattleTestPanel_C
