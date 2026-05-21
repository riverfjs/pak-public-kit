local EventDispatcher = require("Common.EventDispatcher")
local DeviceUtils = {}
DeviceUtils.ImageQuality = nil
DeviceUtils.FrameQuality = nil
DeviceUtils.MemoryQuality = nil
DeviceUtils.ResolutionX = nil
DeviceUtils.ResolutionY = nil
DeviceUtils.Low = 0
DeviceUtils.Mid = 2
DeviceUtils.High = 4
DeviceUtils.Epic = 6
if not DeviceUtils.EventDispatcher then
  DeviceUtils.EventDispatcher = EventDispatcher()
end

function DeviceUtils.GetCurrentDeviceLevel()
  local deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
  if not deviceLevel or deviceLevel < 0 then
    deviceLevel = DeviceUtils.Epic
  end
  return deviceLevel
end

function DeviceUtils.OptimizeNameLabel()
  local deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
  if not deviceLevel or deviceLevel < 0 then
    deviceLevel = DeviceUtils.Epic
  end
  return deviceLevel < DeviceUtils.Mid
end

function DeviceUtils.IsMemorylimit()
  local memorylimit = false
  if RocoEnv.PLATFORM == "PLATFORM_IOS" then
    memorylimit = UE4.UNRCQualityLibrary.GetNRCDeviceMemory() < 2.51
  elseif RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    memorylimit = UE4.UNRCQualityLibrary.GetDeviceMemory() + 1 < 3.51
  else
    memorylimit = UE4.UNRCQualityLibrary.GetDeviceMemory() < 6
    return memorylimit
  end
  return memorylimit
end

DeviceUtils.bSkipDeviceLimit = false
DeviceUtils.bCDNOperated = false
DeviceUtils.bClosePCEnv = false
DeviceUtils.bClosePCOSVersionCheck = false
DeviceUtils.bClosePCIntel1314Check = false
DeviceUtils.bClosePCGPUDriverCheck = false

function DeviceUtils.RunCDNOperate()
  Log.Debug("DeviceUtils.RunCDNOperate")
  local cdnItems = UE4.UNRCQualityLibrary.GetServerCDNDeviceList(UE4.ENRCDeviceCDNType.Operate)
  for idx = 1, cdnItems:Length() do
    local cdnItem = cdnItems:Get(idx)
    cdnItem = string.lower(cdnItem)
    cdnItem = string.gsub(cdnItem, "\r", "")
    Log.Debug("DeviceUtils.RunCDNOperate item", cdnItem)
    if string.find(cdnItem, "closepcenv", 1, true) then
      Log.Debug("closepcenv")
      DeviceUtils.bClosePCEnv = true
    elseif string.find(cdnItem, "closepcosversion", 1, true) then
      Log.Debug("closepcosversion")
      DeviceUtils.bClosePCOSVersionCheck = true
    elseif string.find(cdnItem, "closepcintel1314", 1, true) then
      Log.Debug("closepcintel1314")
      DeviceUtils.bClosePCIntel1314Check = true
    elseif string.find(cdnItem, "closepcgpudriver", 1, true) then
      Log.Debug("closepcgpudriver")
      DeviceUtils.bClosePCGPUDriverCheck = true
    elseif string.find(cdnItem, "closeinsalwaysshader", 1, true) then
      Log.Debug("closeinsalwaysshader")
      UE4.UNRCStatics.ExecConsoleCommand("g.GCSISInsAlwaysBuffer 0")
    elseif string.find(cdnItem, "closecachepcenv", 1, true) then
      Log.Debug("closecachepcenv")
      UE4.UNRCQualityLibrary.SetDetailInfoNeedPCEnv(0)
    elseif string.find(cdnItem, "cldncsis:", 1, true) then
      local cpuBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
      local toFindStr = string.format("cldncsis:%s###", cpuBrand)
      if string.find(cdnItem, toFindStr, 1, true) then
        UE4.UNRCStatics.ExecConsoleCommand("g.GCloseInstanceByEnterQueue 1")
      end
    elseif string.find(cdnItem, "cldnalwaysbuffer:", 1, true) then
      local cpuBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
      local toFindStr = string.format("cldnalwaysbuffer:%s###", cpuBrand)
      if string.find(cdnItem, toFindStr, 1, true) then
        UE4.UNRCStatics.ExecConsoleCommand("g.GCSISInsAlwaysBuffer 0")
      end
    elseif string.find(cdnItem, "opdnalwaysbuffer:", 1, true) then
      local cpuBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
      local toFindStr = string.format("opdnalwaysbuffer:%s###", cpuBrand)
      if string.find(cdnItem, toFindStr, 1, true) then
        UE4.UNRCStatics.ExecConsoleCommand("g.GCSISInsAlwaysBuffer 1")
      end
    end
  end
  DeviceUtils.bCDNOperated = true
end

function DeviceUtils.RunEnvConfig()
  Log.Debug("DeviceUtils.RunEnvConfig")
  local bSimulator, simuName = _G.NRCSDKManager:IsSimulator()
  if bSimulator then
    UE4.UNRCSimulatorStatics.RunConfigQualityAll()
    UE4.UNRCSimulatorStatics.RunConfigForCurrentQuality()
    if 2 == UE4.UNRCQualityLibrary.GetDeviceLevel() then
      local OriDefaultImageQuality = UE4.UNRCQualityLibrary.GetDefaultImageQuality()
      UE4.UNRCQualityLibrary.SetSimulateDeviceLevel(3)
      if UE4.UNRCEngineQualityLibrary.GetImageQuality() == OriDefaultImageQuality then
        Log.Debug("RunCDNOperate Simulator ResetAllToDefault")
        UE4.UNRCQualityLibrary.ResetAllToDefault()
      end
    end
  end
end

function DeviceUtils.IsDeviceInBlackListCDN()
  if DeviceUtils.bSkipDeviceLimit or UE4.UNRCQualityLibrary.GetSkipDeviceLimitCache() then
    return false
  end
  local blackList = UE4.UNRCQualityLibrary.GetServerCDNDeviceList(UE4.ENRCDeviceCDNType.BlackList)
  local cpuBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
  local gpuBrand = UE4.UNRCQualityLibrary.GetGPUBrand()
  cpuBrand = string.lower(cpuBrand)
  gpuBrand = string.lower(gpuBrand)
  local cpuBlack = false
  local gpuBlack = false
  for idx = 1, blackList:Length() do
    local cdnItem = blackList:Get(idx)
    cdnItem = string.lower(cdnItem)
    cdnItem = string.gsub(cdnItem, "\r", "")
    if string.find(cdnItem, "---l---a---u---", 1, true) and _G.AppMain:HasLaunchParams() then
      return false
    end
    if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
      local cp_pos = string.find(cdnItem, "bcp:")
      local gp_pos = string.find(cdnItem, "bgp:")
      if cp_pos and gp_pos and gp_pos > 1 then
        local item_cpu = string.sub(cdnItem, cp_pos + 4, gp_pos - 1)
        local item_gpu = string.sub(cdnItem, gp_pos + 4)
        if string.find(cpuBrand, item_cpu, 1, true) and string.find(gpuBrand, item_gpu, 1, true) then
          return true
        end
      elseif gp_pos then
        local item_gpu = string.sub(cdnItem, gp_pos + 4)
        if string.find(gpuBrand, item_gpu, 1, true) then
          gpuBlack = true
        end
      elseif cp_pos then
        local item_cpu = string.sub(cdnItem, cp_pos + 4)
        if string.find(cpuBrand, item_cpu, 1, true) then
          cpuBlack = true
        end
      end
    else
      local toFindStr = string.format("%s###", cpuBrand)
      if string.find(cdnItem, toFindStr, 1, true) then
        return true
      end
    end
    if cpuBlack or gpuBlack then
      break
    end
  end
  if cpuBlack or gpuBlack then
    return true
  else
    return false
  end
end

function DeviceUtils.IsDeviceInWhiteListCDN()
  local whiteList = UE4.UNRCQualityLibrary.GetServerCDNDeviceList(UE4.ENRCDeviceCDNType.WhiteList)
  local cpuBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
  local gpuBrand = UE4.UNRCQualityLibrary.GetGPUBrand()
  cpuBrand = string.lower(cpuBrand)
  gpuBrand = string.lower(gpuBrand)
  local cpuPass = false
  local gpuPass = false
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    cpuPass = true
  end
  local bSimulator, simuName = _G.NRCSDKManager:IsSimulator()
  for idx = 1, whiteList:Length() do
    local whiteitem = whiteList:Get(idx)
    whiteitem = string.lower(whiteitem)
    whiteitem = string.gsub(whiteitem, "\r", "")
    if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
      if string.find(whiteitem, "---a---l---l---", 1, true) then
        local memorylimit = UE4.UNRCQualityLibrary.GetDeviceMemory() < 6
        if not memorylimit then
          return true
        end
      elseif string.find(whiteitem, "---l---a---u---", 1, true) and _G.AppMain:HasLaunchParams() then
        return true
      end
      local cp_pos = string.find(whiteitem, "cp:")
      local gp_pos = string.find(whiteitem, "gp:")
      if cp_pos and gp_pos and gp_pos > 1 then
        local white_cpu = string.sub(whiteitem, cp_pos + 3, gp_pos - 1)
        local white_gpu = string.sub(whiteitem, gp_pos + 3)
        if string.find(cpuBrand, white_cpu, 1, true) and string.find(gpuBrand, white_gpu, 1, true) then
          return true
        end
      elseif gp_pos then
        local white_gpu = string.sub(whiteitem, gp_pos + 3)
        if string.find(gpuBrand, white_gpu, 1, true) then
          gpuPass = true
        end
      elseif cp_pos then
        local white_cpu = string.sub(whiteitem, cp_pos + 3)
        if string.find(cpuBrand, white_cpu, 1, true) then
          cpuPass = true
        end
      end
    else
      if not bSimulator and string.find(whiteitem, cpuBrand, 1, true) then
        if not UE4.UNRCPlatformStatics.IsLimitImageQualityForOldDriver() then
          local whiteLevel
          if string.find(whiteitem, "2:", 1, true) then
            whiteLevel = 2
          elseif string.find(whiteitem, "3:", 1, true) then
            whiteLevel = 3
          elseif string.find(whiteitem, "4:", 1, true) then
            whiteLevel = 4
          elseif string.find(whiteitem, "5:", 1, true) then
            whiteLevel = 5
          end
          if nil ~= whiteLevel then
            Log.Debug("ChangeDefaultLevel", whiteLevel)
            if UE4.UNRCQualityLibrary.GetDeviceLevel() ~= whiteLevel then
              local OriDefaultImageQuality = UE4.UNRCQualityLibrary.GetDefaultImageQuality()
              UE4.UNRCQualityLibrary.SetSimulateDeviceLevel(whiteLevel)
              if UE4.UNRCEngineQualityLibrary.GetImageQuality() == OriDefaultImageQuality then
                Log.Debug("ResetAllToDefault")
                UE4.UNRCQualityLibrary.ResetAllToDefault()
              end
            end
          end
        end
        return true
      end
      if not bSimulator then
        if string.find(whiteitem, "---a---l---l---", 1, true) then
          local memorylimit = DeviceUtils.IsMemorylimit()
          if not memorylimit then
            return true
          end
        elseif string.find(whiteitem, "---l---a---u---", 1, true) and _G.AppMain:HasLaunchParams() then
          return true
        end
      elseif string.find(whiteitem, "---s---i---m---", 1, true) then
        return true
      end
    end
    if cpuPass and gpuPass then
      break
    end
  end
  if cpuPass and gpuPass then
    return true
  else
    return false
  end
end

function DeviceUtils.IsDeviceInWhiteList()
  if DeviceUtils.bSkipDeviceLimit or UE4.UNRCQualityLibrary.GetSkipDeviceLimitCache() then
    return true
  end
  local deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    return true
  elseif RocoEnv.PLATFORM == "PLATFORM_IOS" then
    return true
  else
    local score = UE4.UNRCQualityLibrary.GetDeviceScore()
    return deviceLevel > 2 or score > 329 or score < 0
  end
end

function DeviceUtils.IsDeviceInBlackList()
  if DeviceUtils.bSkipDeviceLimit or UE4.UNRCQualityLibrary.GetSkipDeviceLimitCache() then
    return false
  end
  if UE4.UNRCQualityLibrary.GetSimulateDeviceLevel() < -1 then
    return true
  end
  local bSimulator, simuName = _G.NRCSDKManager:IsSimulator()
  if bSimulator and simuName then
    simuName = string.lower(simuName)
    if not string.find(simuName, "tencent", 1, true) then
      return false
    end
  end
  local memorylimit = DeviceUtils.IsMemorylimit()
  return UE4.UNRCQualityLibrary.IsDeviceInBlackList() or memorylimit
end

function DeviceUtils.IsIntegratedGraphics()
  return UE4.UNRCQualityLibrary.IsIntegratedGraphics()
end

function DeviceUtils.GetDeviceDetailInfo()
  local level = UE4.UNRCQualityLibrary.GetDeviceLevel()
  local detail = UE4.UNRCQualityLibrary.GetDeviceDetail()
  local score = UE4.UNRCQualityLibrary.GetDeviceScore()
  local IsLocalWhite, IsLocalBlack
  if DeviceUtils.IsDeviceInWhiteList() then
    IsLocalWhite = 1
  else
    IsLocalWhite = 0
  end
  if DeviceUtils.IsDeviceInBlackList() then
    IsLocalBlack = 1
  else
    IsLocalBlack = 0
  end
  local IsCDNWhite, IsCDNBlack
  if DeviceUtils.IsDeviceInWhiteListCDN() then
    IsCDNWhite = 1
  else
    IsCDNWhite = 0
  end
  if DeviceUtils.IsDeviceInBlackListCDN() then
    IsCDNBlack = 1
  else
    IsCDNBlack = 0
  end
  local IsPad
  if UE4.UNRCQualityLibrary.IsPad() then
    IsPad = 1
  else
    IsPad = 0
  end
  local IsIntegratedGraphics
  if DeviceUtils.IsIntegratedGraphics() then
    IsIntegratedGraphics = 1
  else
    IsIntegratedGraphics = 0
  end
  local IsSimulator, simuName = _G.NRCSDKManager:IsSimulator()
  if IsSimulator then
    IsSimulator = 1
  else
    IsSimulator = 0
  end
  local IsDriverLimit
  if UE4.UNRCPlatformStatics.IsLimitImageQualityForOldDriver() then
    IsDriverLimit = 1
  else
    IsDriverLimit = 0
  end
  local EnvInfo = ""
  if (not (not DeviceUtils.bCDNOperated or DeviceUtils.bClosePCEnv) or UE4.UNRCQualityLibrary.GetDetailInfoNeedPCEnv() > 0) and RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    local IsWinVersionLimit
    if UE4.UNRCPlatformStatics.IsWindowsOSVersionLimit() then
      IsWinVersionLimit = 1
    else
      IsWinVersionLimit = 0
    end
    local IsIntel1314KShrinkRisk
    if UE4.UNRCPlatformStatics.IsIntel1314KShrinkRisk() then
      IsIntel1314KShrinkRisk = 1
    else
      IsIntel1314KShrinkRisk = 0
    end
    local MicrocodeVersion = UE4.UNRCPlatformStatics.GetMicrocodeVersion()
    local IsWindowsGPUDriverVersionLimit
    if UE4.UNRCPlatformStatics.IsWindowsGPUDriverVersionLimit() then
      IsWindowsGPUDriverVersionLimit = 1
    else
      IsWindowsGPUDriverVersionLimit = 0
    end
    local GPUDriverVersion = UE4.UNRCQualityLibrary.GetGPUDriverVersion()
    EnvInfo = string.format("IsWinVersionLimit:%d IsIntel1314KShrinkRisk:%d MicrocodeVersion:0x%X IsWindowsGPUDriverVersionLimit:%d GPUDriverVersion:%s", IsWinVersionLimit, IsIntel1314KShrinkRisk, MicrocodeVersion, IsWindowsGPUDriverVersionLimit, GPUDriverVersion)
  end
  local ans = string.format([[
%s
 score:%f IsPad:%d localWhite:%d localBlack:%d CDNWhite:%d CDNBlack:%d ig:%d
CurLevel:%d IsSimulator:%d(%s) IsDriverLimit:%d %s]], detail, score, IsPad, IsLocalWhite, IsLocalBlack, IsCDNWhite, IsCDNBlack, IsIntegratedGraphics, level, IsSimulator, simuName, IsDriverLimit, EnvInfo)
  return ans
end

return DeviceUtils
