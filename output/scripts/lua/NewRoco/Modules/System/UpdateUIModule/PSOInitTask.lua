local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local UpdateStageLocalText = require("NewRoco.Modules.System.UpdateUIModule.UpdateStageLocalText")
local PSOInitTask = NRCClass("PSOInitTask")

function PSOInitTask:Init()
  Log.Debug("PSOInitTask:Init")
  self.name = "PSOInitTask"
  self.bInit = false
  self.bIsPrecompiling = false
  self.TotalCount = 0
  self.RemainCount = 0
  self.Timeout = 30
  self.RunningTime = 0
  _G.UpdateManager:Register(self)
end

function PSOInitTask:StartInitPSO()
  Log.Debug("PSOInitTask:StartInitPSO")
  if self.bInit then
    Log.Error("PSOInitTask:StartInitPSO already initialized")
    return
  end
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.OnPSOWarmUpBegin)
  self:OnPSOWarmUpBegin()
  self:Init()
  self.bInit = true
  self:ChangeProgress(0, LuaText.psoinitaction_1)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnShaderBeginPrecompile, self.OnBeginCompile)
  _G.DelayManager:DelaySeconds(1, self.EnablePSO, self)
end

function PSOInitTask:IsInited()
  return self.bInit
end

function PSOInitTask:EnablePSO()
  if UE.UNRCStatics.GetCurrentRHIName() == "D3D11" then
    Log.Warning("PSOInitTask:EnablePSO D3D11 \228\184\141\230\148\175\230\140\129\233\162\132\231\131\173PSOCache")
    self:Finish()
    return
  end
  local version = JsonUtils.LoadSaved("PSOVersion", {})
  local PSOFiles = UE.UNRCStatics.ListFiles(UE4.UBlueprintPathsLibrary.ProjectSavedDir() .. "PipelineCaches", "*.upipelinecache")
  local PSOFilesTable = PSOFiles:ToTable()
  self.PSOHash = nil
  for Index, Path in ipairs(PSOFilesTable) do
    local FileName = UE.UBlueprintPathsLibrary.GetBaseFilename(Path, true) .. ".upipelinecache"
    Log.Warning("PSOInitTask:EnablePSO : ", Path, FileName)
    self.PSOHash = UE.UResVerifyConfigStatics.GetFileHashFromResVerifyConfig(FileName)
    if not string.IsNilOrEmpty(self.PSOHash) then
      Log.Debug("PSOPatch Hash : ", self.PSOHash or "nil")
      break
    end
  end
  if not self.PSOHash then
    local ContentPipelineCachePath = UE.UHotUpdateUtils.GetContentPipelineCachePath()
    local PSOHash, bGetSuccess = UE.UHotUpdateUtils.TryGetResFileHash(ContentPipelineCachePath)
    if bGetSuccess then
      self.PSOHash = PSOHash
    else
      Log.Error("PSOInitTask:EnablePSO \230\151\160\230\179\149\232\142\183\229\143\150PSOHash")
    end
  end
  self.PSOPrecompilingReason = ""
  local OSVersion = UE4.UNRCStatics.GetOSVersion()
  local CurrentPrecompileMask = UE.UNRCStatics.GetPrecompileMask()
  Log.Debug("[PSO] Get OSVersion : ", OSVersion)
  Log.Debug("[PSO] Get PSOHash : ", self.PSOHash or "nil")
  Log.Debug("[PSO] Get Precompile Mask: ", string.format("%s -> %s", version.PrecompileMask, CurrentPrecompileMask))
  local bNeedToReWarmUp = false
  if version.SystemVersion ~= OSVersion then
    self.PSOPrecompilingReason = string.format(" APM System_Driven %s -> %s", version.SystemVersion, OSVersion)
    self:ReportPrecompilingReason("OSVersion", self.PSOPrecompilingReason)
    Log.Warning("PSOInitTask:EnablePSO \231\137\136\230\156\172\228\184\141\229\140\185\233\133\141 \233\156\128\232\166\129\233\135\141\230\150\176\233\162\132\231\131\173", self.PSOPrecompilingReason)
    bNeedToReWarmUp = true
    self.CombinedPrecompileMask = CurrentPrecompileMask
  elseif not (self.PSOHash and version.Hash) or version.Hash ~= self.PSOHash then
    self.PSOPrecompilingReason = string.format(" APM PSOHash %s -> %s", version.Hash or "nil", self.PSOHash or "nil")
    self:ReportPrecompilingReason("PSOVersion", self.PSOPrecompilingReason)
    Log.Warning("PSOInitTask:EnablePSO \231\137\136\230\156\172\228\184\141\229\140\185\233\133\141 \233\156\128\232\166\129\233\135\141\230\150\176\233\162\132\231\131\173", self.PSOPrecompilingReason)
    bNeedToReWarmUp = true
    self.CombinedPrecompileMask = CurrentPrecompileMask
  else
    local bQualityChanged = false
    self.CombinedPrecompileMask = 0
    local BinaryCacheSize = UE4.UNRCStatics.GetBinaryProgramSize()
    if 0 == BinaryCacheSize or nil == version.PrecompileMask then
      bNeedToReWarmUp = true
      self.CombinedPrecompileMask = CurrentPrecompileMask
    elseif 0 ~= version.PrecompileMask then
      local bPrecompileOnHigerQuality = UE4.UKismetSystemLibrary.GetConsoleVariableBoolValue("PSO.PrecompileOnHigherQuality")
      Log.Warning("PSOInitTask:EnablePSO bPrecompileOnHigerQuality", bPrecompileOnHigerQuality)
      bQualityChanged = CurrentPrecompileMask & version.PrecompileMask ~= CurrentPrecompileMask
      if bQualityChanged and bPrecompileOnHigerQuality then
        self.CombinedPrecompileMask = version.PrecompileMask | CurrentPrecompileMask
        bNeedToReWarmUp = true
      else
        self.CombinedPrecompileMask = version.PrecompileMask
      end
    end
    if bNeedToReWarmUp then
      self.PSOPrecompilingReason = string.format(" APM Quality %s | %s -> %s", version.PrecompileMask, CurrentPrecompileMask, self.CombinedPrecompileMask)
      self:ReportPrecompilingReason("Quality", self.PSOPrecompilingReason)
      Log.Warning("PSOInitTask:EnablePSO \231\137\136\230\156\172\228\184\141\229\140\185\233\133\141 \233\156\128\232\166\129\233\135\141\230\150\176\233\162\132\231\131\173", self.PSOPrecompilingReason)
    end
  end
  if bNeedToReWarmUp then
    if RocoEnv.PLATFORM_IOS then
      UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.MetalCacheMinSizeInMB 1024")
    elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
      UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.GGLCacheMinSizeInMB 1024")
    elseif RocoEnv.PLATFORM_WINDOWS then
      UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.D3D12CacheMinSizeInMB 1024")
    end
  elseif RocoEnv.PLATFORM_IOS then
    UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.MetalCacheMinSizeInMB 1")
  elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
    UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.GGLCacheMinSizeInMB 1")
  elseif RocoEnv.PLATFORM_WINDOWS then
    UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.D3D12CacheMinSizeInMB 1")
  end
  UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.Enabled 1")
  UE.UNRCStatics.ReloadShaderPipelineCache()
  UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.BatchTime 100")
  UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.BatchSize 1")
  UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.SetBatchMode Fast")
  Log.PrintScreenMsg("r.ShaderPipelineCache.SetBatchMode Fast")
  local RemainCount = UE.UNRCStatics.GetShaderPrecompileRemainingTasks()
  if 0 == RemainCount then
    Log.Debug("\228\184\141\231\148\168\233\162\132\231\131\173\231\157\128\232\137\178\229\153\168")
    self:Finish()
    return false
  end
end

function PSOInitTask:ReportPrecompilingReason(Key, Reason)
  if not _G.RocoEnv.IS_EDITOR and Key and Reason then
    UE.UNRCStatics.ReportPrecompilingReason(Key, Reason)
  end
end

function PSOInitTask:OnBeginCompile(Count)
  self.TotalCount = Count
  local RemainCount = UE.UNRCStatics.GetShaderPrecompileRemainingTasks()
  if 0 == RemainCount then
    Log.Debug("\228\184\141\231\148\168\233\162\132\231\131\173\231\157\128\232\137\178\229\153\168")
    self:Finish()
    return
  end
  self.NumExpiredPSO = UE.UNRCStatics.GetNumExpiredPSO()
  if not _G.RocoEnv.IS_EDITOR then
    UE.UNRCStatics.ReportPrecompilingReason("", "")
  end
  JsonUtils.DumpSaved("PSOVersion", {
    SystemVersion = UE4.UNRCStatics.GetOSVersion(),
    Hash = "0"
  })
  if nil ~= RemainCount then
    Log.PrintScreenMsg("OnBeginCompile %d", RemainCount)
  end
  self.bIsPrecompiling = true
  self.Timeout = self.TotalCount * 10
  self.RemainCount = self.TotalCount
end

function PSOInitTask:Finish()
  _G.UpdateManager:UnRegister(self)
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.OnPSOWarmUpEnd)
  self:OnPSOWarmUpEnd()
  UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.SetBatchMode Background")
  Log.PrintScreenMsg("r.ShaderPipelineCache.SetBatchMode Background")
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnShaderBeginPrecompile, self.OnBeginCompile)
  self.bIsPrecompiling = false
  if not _G.RocoEnv.IS_EDITOR then
    UE.UNRCStatics.ReportPrecompilingCompleted()
  end
end

function PSOInitTask:OnTick(DeltaTime)
  if not self.bIsPrecompiling then
    return
  end
  if not self:CheckTimeOut(DeltaTime) then
    return
  end
  self.RemainCount = UE.UNRCStatics.GetShaderPrecompileRemainingTasks()
  if 0 == self.RemainCount and UE.UNRCStatics.IsRHIShaderPipelineCacheReady() then
    Log.PrintScreenMsg("\233\162\132\231\131\173\231\157\128\232\137\178\229\153\168\229\174\140\230\136\144 %d", self.TotalCount)
    Log.Warning("PSOInitTask:OnTick PSOHash : ", self.PSOHash)
    JsonUtils.DumpSaved("PSOVersion", {
      SystemVersion = UE4.UNRCStatics.GetOSVersion(),
      Hash = self.PSOHash,
      PrecompileMask = self.CombinedPrecompileMask
    })
    self:ChangeProgress(1, LuaText.psoinitaction_3)
    self:Finish()
  else
    Log.Debug("\230\173\163\229\156\168\233\162\132\231\131\173\231\157\128\232\137\178\229\153\168", self.RemainCount)
    local RemainPercent = 1 - self.RemainCount / self.TotalCount
    if RemainPercent > 0.99 then
      RemainPercent = 0.99
    end
    local msg
    if _G.AppMain:GetFormalPipeline() then
      msg = string.format(UpdateStageLocalText.PSOWarmUp, self.TotalCount - self.RemainCount, self.TotalCount)
    else
      msg = string.format("\230\173\163\229\156\168\233\162\132\231\131\173\231\157\128\232\137\178\229\153\168\227\128\130 \229\183\178\233\162\132\231\131\173(%d)/\229\164\177\230\149\136(%d)/%d ", self.TotalCount - self.RemainCount, self.NumExpiredPSO, self.TotalCount)
    end
    self:ChangeProgress(RemainPercent, msg)
  end
end

function PSOInitTask:ChangeProgress(Progress, Msg)
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.OnPSOWarmUpProgress, Progress, Msg)
end

function PSOInitTask:CheckTimeOut(DeltaTime)
  self.RunningTime = self.RunningTime + DeltaTime
  if self.RunningTime > self.Timeout then
    Log.Error("PSOInitTask:CheckTimeOut \232\182\133\230\151\182")
    self:Finish()
    return false
  end
  return true
end

function PSOInitTask:OnPSOWarmUpBegin()
  self.PSOStartTime = os.time()
  _G.GEMPostManager:GEMPostStepEvent("PSOAndDownloadStart")
end

function PSOInitTask:OnPSOWarmUpEnd()
  if self.PSOStartTime == nil then
    Log.Error("PSOInitTask:OnPSOWarmUpEnd PSOStartTime is nil")
    return
  end
  local PSOCostTime = os.time() - self.PSOStartTime
  self.PSOStartTime = nil
  _G.GEMPostManager:GEMPostStepEvent("PSOEnd", PSOCostTime)
end

return PSOInitTask
