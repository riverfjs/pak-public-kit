local SystemSettingModule = NRCModuleBase:Extend("SystemSettingModule")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local SystemSettingEnum = require("NewRoco.Modules.System.SystemSetting.SystemSettingEnum")
local JsonUtils = require("Common.JsonUtils")
local TimeoutEventListener = require("Common.TimeoutEventListener")
local _CustomKeyMappingConfigFilename = "NrcCustomKeyMapping"
local _SleepConfigFilename = "NrcSleepConfig"
local _DLSSConfigFilename = "NrcDLSSConfig"

function SystemSettingModule:OnConstruct()
  _G.SystemSettingModuleCmd = reload("NewRoco.Modules.System.SystemSetting.SystemSettingModuleCmd")
  self.data = self:SetData("SystemSettingModuleData", "NewRoco.Modules.System.SystemSetting.SystemSettingModuleData")
  self.EventListener = TimeoutEventListener()
  self:InitSleepModeParams()
end

function SystemSettingModule:OnActive()
  self:RegPanel("SystemSettingMain", "UMG_SystemSettingMain", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", "Out", true)
  self:RegPanel("BindMobilePhone", "UMG_BindMobilePhone", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("KeyStrokeDetectPanel", "UMG_KeystrokeCollision", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, true)
  self:RegPanel("UMG_PrivilegeAuthorizationPopUp", "UMG_PrivilegeAuthorizationPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UnBindMobilePhoneTipsPanel", "UMG_Unbinding", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UMG_CloudMessageManagementPopUp", "UMG_CloudMessageManagementPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UMG_PersonalInformationManagement", "UMG_PersonalInformationManagement", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SleepPanel", "UMG_SystemSetting_Standby", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SecondaryPasswordSet", "UMG_SecondaryPasswordSet", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SecondaryPasswordModify", "UMG_SecondaryPasswordModify", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SecondaryPasswordVerify", "UMG_SecondaryPasswordVerify", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SecondaryPasswordCancel", "UMG_SecondaryPasswordCancel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("SecondaryPasswordCancelForceDisable", "UMG_SecondaryPasswordCancelForceDisable", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenMainPanel, self.OnOpenMainPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.EnableMainPanel, self.EnableMainPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.PreLoadMainPanel, self.PreLoadMainPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.CloseMainPanel, self.OnCloseMainPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ApplyConfig, self.OnApplyConfig)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ApplyDLSSSettings, self.ApplyDLSSSettings)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ApplyFrameGenerateSettings, self.ApplyFrameGenerateSettings)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenBindPhonePanel, self.OnCmdOpenBindPhonePanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqGetPhoneBindCode, self.OnCmdReqGetPhoneBindCode)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqBindPhoneNum, self.OnCmdReqBindPhoneNum)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqGetMobileBindInfo, self.OnCmdReqGetMobileBindInfo)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenUnBindMobilePhoneTipsPanel, self.OnCmdOpenUnBindMobilePhoneTipsPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenPersonalInformationManagement, self.OnCmdOpenPersonalInformationManagement)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, self.OnCmdReqModifyPlayerSettings)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqQueryPlayerSettings, self.OnCmdReqQueryPlayerSettings)
  self:RegisterCmd(_G.SystemSettingModuleCmd.RefreshNotificationList, self.OnCmdRefreshNotificationList)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetPlayerSettings, self.OnCmdGetPlayerSettings)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ChangeCustomKeyMapping, self.OnCmdChangeCustomKeyMapping)
  self:RegisterCmd(_G.SystemSettingModuleCmd.SwitchTwoCustomKeyMapping, self.OnCmdSwitchTwoCustomKeyMapping)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetMappingKeyUIName, self.OnCmdGetMappingKeyUIName)
  self:RegisterCmd(_G.SystemSettingModuleCmd.FullyApplyUserCustomKeyMapping, self.OnCmdFullyApplyUserCustomKeyMapping)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenKeyStrokeDetectPanel, self.OnCmdOpenKeyStrokeDetectPanel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetButtonSettingMappingKey, self.OnCmdGetButtonSettingMappingKey)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetKeyUIName, self.OnCmdGetKeyUIName)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetAllowFriendWatchBattle, self.GetAllowFriendWatchBattle)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ClosePrivilegeAuthorizationPopUp, self.OnCmdClosePrivilegeAuthorizationPopUp)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenPrivilegeAuthorizationPopUp, self.OnCmdOpenPrivilegeAuthorizationPopUp)
  self:RegisterCmd(_G.SystemSettingModuleCmd.CheckUserSubscribeInfo, self.OnCmdCheckUserSubscribeInfo)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqGetUserSubscribeTplInfo, self.OnCmdReqGetUserSubscribeTplInfo)
  self:RegisterCmd(_G.SystemSettingModuleCmd.RefreshSecondaryList, self.OnCmdRefreshSecondaryList)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenCloudMessageManagementPopUp, self.OnOpenCloudMessageManagementPopUp)
  self:RegisterCmd(_G.SystemSettingModuleCmd.CloseCloudMessageManagementPopUp, self.OnCloseCloudMessageManagementPopUp)
  self:RegisterCmd(_G.SystemSettingModuleCmd.CheckSecondaryPassword, self.CheckSecondaryPassword)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ReqSecondaryPasswordGetInfo, self.ReqSecondaryPasswordGetInfo)
  self:RegisterCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo, self.GetSecondaryPasswordInfo)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, self.OnSecondaryPasswordStatusChange)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordSet, self.OpenSecondaryPasswordSet)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordModify, self.OpenSecondaryPasswordModify)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordVerify, self.OpenSecondaryPasswordVerify)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancel, self.OpenSecondaryPasswordCancel)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ForgetSecondaryPassword, self.ForgetSecondaryPassword)
  self:RegisterCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancelForceDisable, self.OpenSecondaryPasswordCancelForceDisable)
  self:RegisterCmd(_G.SystemSettingModuleCmd.EncryptInputText, self.EncryptInputText)
  self:RegisterCmd(_G.SystemSettingModuleCmd.SwitchSleepModeOnEditor, self.SwitchSleepModeOnEditor)
  self:RegisterCmd(_G.SystemSettingModuleCmd.SwitchSleepMode, self.SwitchSleepMode)
  self:RegisterCmd(_G.SystemSettingModuleCmd.QuitSleepMode, self.QuitSleepMode)
  self:RegisterCmd(_G.SystemSettingModuleCmd.EnterSleepModeOnDebug, self.EnterSleepModeOnDebug)
  self:RegisterCmd(_G.SystemSettingModuleCmd.ChangePlayerName, self.ChangePlayerName)
  _G.NRCEventCenter:RegisterEvent("SystemSettingModule", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnScreenTouchEnd)
  _G.NRCEventCenter:RegisterEvent("SystemSettingModule", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnScreenTouchStart)
  self.data:BuildButtonTypeToButtonSettingConfMap()
  self.data:BuildKeyUINameMap()
  self.data:LoadUserCustomKeyMapping()
  self:OnCmdFullyApplyUserCustomKeyMapping()
  self:OnCmdReqQueryPlayerSettings()
  self:ReqSecondaryPasswordGetInfo()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_UNSET_NOTIFY, self.OnSecondaryPasswordUnsetNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_NEED_CHECK_NOTIFY, self.OnSecondaryPasswordNeedCheckNotify)
end

function SystemSettingModule:RegPanel(name, path, layer, openAnimName, closeAnimName, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = "/Game/NewRoco/Modules/System/SystemSetting/Res/" .. path
  registerData.panelLayer = layer
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function SystemSettingModule:InitSleepModeParams()
  self._sleepIntervalSeconds = 600
  local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
  local needSave = false
  local interval = sleepConfig.sleepIntervalSeconds
  if type(interval) == "number" then
    if interval < 0 then
      interval = 0
      sleepConfig.sleepIntervalSeconds = 0
      needSave = true
    end
    self._sleepIntervalSeconds = interval
  else
    sleepConfig.sleepIntervalSeconds = self._sleepIntervalSeconds
    needSave = true
  end
  local restored = false
  if sleepConfig.inSleep == true then
    local savedFrameQuality = sleepConfig.savedFrameQuality
    local savedBrightness = sleepConfig.savedBrightness
    if nil ~= savedFrameQuality then
      local ok = pcall(function()
        UE4.UNRCQualityLibrary.SetFrameQuality(savedFrameQuality)
      end)
      restored = restored or ok
    end
    if nil ~= savedBrightness and not restored then
      restored = ok
    end
    if restored then
      sleepConfig.inSleep = false
      sleepConfig.savedFrameQuality = nil
      sleepConfig.savedBrightness = nil
      sleepConfig.targetFrameQuality = nil
      sleepConfig.targetBrightness = nil
      needSave = true
    end
  end
  if needSave then
    JsonUtils.DumpSaved(_SleepConfigFilename, sleepConfig)
  end
end

function SystemSettingModule:InitAudioConfig()
end

function SystemSettingModule:OnOpenMainPanel()
  local reqParamList = _G.NRCPanelOpenReqData()
  reqParamList.cmdId = _G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ
  reqParamList.reqClass = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
  reqParamList.ignoreErrorTip = false
  reqParamList.needModal = false
  reqParamList.Caller = self
  self:OpenPanel("SystemSettingMain", 0, reqParamList)
end

function SystemSettingModule:EnableMainPanel()
  local panel = self:GetPanel("SystemSettingMain")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function SystemSettingModule:PreLoadMainPanel()
  self:PreLoadPanel("SystemSettingMain")
end

function SystemSettingModule:OnCloseMainPanel()
  self:ClosePanel("SystemSettingMain")
end

function SystemSettingModule:OnOpenCloudMessageManagementPopUp()
  self:OpenPanel("UMG_CloudMessageManagementPopUp")
end

function SystemSettingModule:OnCloseCloudMessageManagementPopUp()
  self:ClosePanel("UMG_CloudMessageManagementPopUp")
end

function SystemSettingModule:OnApplyConfig(key, value, extraKey)
  Log.Debug("SystemSettingModule:OnApplyConfig", key, value, extraKey)
  _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.ConfigApplied, key, value)
  if "Resoluction" == key then
    UE4.UNRCQualityLibrary.SetPCResolutionByIndex(value)
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.ChangeResolution)
    return
  elseif "FPS" == key then
    UE4.UNRCQualityLibrary.SetFrameQuality(value)
  elseif "GraphicsAPI" == key then
    if 0 == value then
      UE4.UNRCQualityLibrary.SetPreferD3D12(false)
    elseif 1 == value then
      UE4.UNRCQualityLibrary.SetPreferD3D12(true)
    end
    local msg = _G.DataConfigManager:GetLocalizationConf("setting_restart_the_client").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
  elseif "SleepSetting" == key then
    local seconds = 600
    if 0 == value then
      seconds = 600
    elseif 1 == value then
      seconds = 1200
    elseif 2 == value then
      seconds = 1800
    elseif 3 == value then
      seconds = 0
    end
    self._sleepIntervalSeconds = seconds
    local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
    sleepConfig.sleepIntervalSeconds = seconds
    JsonUtils.DumpSaved(_SleepConfigFilename, sleepConfig)
  elseif "MobileResolution" == key then
    UE4.UNRCQualityLibrary.SetMobileResolutionQuality(value)
  elseif "ImageQuality" == key then
    if value ~= UE4.ENRCImageQuality.Custom then
      local msg = _G.DataConfigManager:GetLocalizationConf("setting_switch_the_image").msg
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
      local panel = self:GetPanel("SystemSettingMain")
      if panel then
        panel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      end
    end
    if self._imageQualityTimerId then
      _G.DelayManager:CancelDelayById(self._imageQualityTimerId)
      self._imageQualityTimerId = nil
    end
    self._imageQualityTimerId = _G.DelayManager:DelaySeconds(0.26, function()
      self._imageQualityTimerId = nil
      local panel = self:GetPanel("SystemSettingMain")
      if panel then
        panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      UE4.UNRCQualityLibrary.SetImageQuality(value, true)
      local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
      if _G.UE4Helper.IsPCMode() then
        if DLSSConfig.Type and 2 == DLSSConfig.Type then
          DLSSConfig.AntiAliasing = 1
        else
          DLSSConfig.AntiAliasing = 0
        end
      else
        DLSSConfig.AntiAliasing = 0
      end
      JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
      _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.RefreshDropDownList, nil, nil, nil, true)
    end)
  elseif "PlayerSettings" == key then
    local newPlayerSettings = value
    if nil == newPlayerSettings then
      self.data.playerSettings = nil
    else
      Log.Dump(newPlayerSettings, 99, "SystemSettingModule:OnApplyConfig PlayerSettings")
      if not self.data.playerSettings then
        self.data.playerSettings = {}
      end
      if newPlayerSettings.user_subsribe then
        self.data.playerSettings.userSubscribe = newPlayerSettings.user_subsribe
      end
      if newPlayerSettings.pvp then
        self.data.playerSettings.pvp = newPlayerSettings.pvp
      end
    end
  elseif "DLSS" == key then
    if extraKey then
      if "Type" == extraKey then
        local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
        local bHasTypeChange = DLSSConfig.Type ~= value
        if bHasTypeChange then
          DLSSConfig.Graphic = 1
        end
        if 2 == value then
          UE4.UNRCStatics.ExecConsoleCommand("r.MobileMSAA 1")
          DLSSConfig.AntiAliasing = 1
        end
        if 2 == DLSSConfig.Type and 0 == value then
          DLSSConfig.AntiAliasing = 0
          local antiAliasLevel = UE4.UNRCQualityLibrary.GetGroupQualityLevel("AntiAliasingQuality")
          UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Custom)
          UE4.UNRCQualityLibrary.SetGroupQualityLevel("AntiAliasingQuality", antiAliasLevel)
        end
        DLSSConfig.Type = value
        JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
        self:ApplyDLSSSettings()
      elseif "Graphic" == extraKey then
        local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
        DLSSConfig.Graphic = value
        JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
        self:ApplyDLSSSettings()
      elseif "FrameGenerate" == extraKey then
        local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
        DLSSConfig.FrameGenerate = value
        JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
        self:ApplyFrameGenerateSettings(value)
      end
    end
  elseif "joystickMode" == key then
  elseif "propPlaceMode" == key then
  else
    UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Custom)
    UE4.UNRCQualityLibrary.SetGroupQualityLevel(key, value)
  end
  if "ImageQuality" ~= key and "PlayerSettings" ~= key then
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.RefreshDropDownList, key, value, extraKey)
  end
end

function SystemSettingModule:ApplyDLSSSettings()
  local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
  local DLSSSelectIndex = DLSSConfig.Type or 0
  if 0 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 100")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 0")
    DLSSConfig.Graphic = 0
    JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
  elseif 1 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 100")
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 1")
  elseif 2 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 1")
  end
  local DLSSSelectIndex1 = DLSSConfig.Graphic or 1
  if 0 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality -1")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 50")
    end
  elseif 1 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality 0")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 57")
    end
  elseif 2 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality 1")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 67")
    end
  end
end

function SystemSettingModule:ApplyFrameGenerateSettings(value)
  if 0 == value then
    UE4.UNRCStatics.ExecConsoleCommand("r.Upscale.CombineInSlate 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FI.Enabled 0")
  elseif 1 == value then
    UE4.UNRCStatics.ExecConsoleCommand("r.Upscale.CombineInSlate 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FI.Enabled 1")
  end
end

function SystemSettingModule:OnRelogin()
end

function SystemSettingModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnScreenTouchEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnScreenTouchStart)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_UNSET_NOTIFY, self.OnSecondaryPasswordUnsetNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_NEED_CHECK_NOTIFY, self.OnSecondaryPasswordNeedCheckNotify)
end

function SystemSettingModule:OnDestruct()
end

function SystemSettingModule:OnCmdReqGetMobileBindInfo(isOpenSystemPanel)
  Log.Debug("SystemSettingModule:OnCmdCheckBindPhoneState==\229\143\145\233\128\129\230\156\141\229\138\161\231\171\175\232\142\183\229\143\150\230\137\139\230\156\186\231\187\145\229\174\154\231\138\182\230\128\129")
  self.data.BindPhoneSettingData = isOpenSystemPanel
  local req = _G.ProtoMessage:newZoneGetMobileBindInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_MOBILE_BIND_INFO_REQ, req, self, self.RspGetMobileBindInfo, false, true)
  self.IsCanShowError = true
  self.EventListener:StartGlobalEventListener(2, "OnCmdReqGetMobileBindInfo", self, "OnCmdReqGetMobileBindInfo", self.ShowBindPhoneAreaDefault)
end

function SystemSettingModule:RspGetMobileBindInfo(rsp)
  Log.Debug("SystemSettingModule:RspGetMobileBindInfo==\228\187\142\230\156\141\229\138\161\231\171\175\232\142\183\229\143\150\230\137\139\230\156\186\231\187\145\229\174\154\231\138\182\230\128\129\229\155\158\232\176\131")
  self.EventListener:Stop()
  if 0 == rsp.ret_info.ret_code then
    self.IsCanShowError = false
    if self.data.BindPhoneSettingData then
      local phoneInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMobileBindInfo()
      if phoneInfo then
        phoneInfo.mobile_num = rsp.local_mobile_num
      else
        phoneInfo = {
          mobile_num = rsp.local_mobile_num
        }
      end
      _G.DataModelMgr.PlayerDataModel:SetPlayerMobileBindInfo(phoneInfo)
      local panel = self:GetPanel("SystemSettingMain")
      if panel then
        panel:ShowBindPhoneArea(true)
      end
      self.data.BindPhoneSettingData = false
    else
      local data = {
        bind = rsp.bind_use_sms_with_btn,
        unbind1 = rsp.unbind,
        unbind2 = rsp.unbind_channel_confirmation,
        unbind3 = rsp.unbind_channel_result,
        unbind2_allScene = rsp.unbind_game_confirmation,
        unbind3_allScene = rsp.unbind_game_result
      }
      self.data:SetBindPhoneDesc(data)
      if 1 == rsp.bind_flag then
        _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenBindPhonePanel, self.data.BindMobilePhoneEnum.BIND)
      elseif 0 == rsp.bind_flag then
        _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenUnBindMobilePhoneTipsPanel, rsp.mask_mobile_num)
      end
      _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.UnLockGetBindPhoneInfoReq)
    end
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    self:ShowBindPhoneAreaDefault(desc)
  end
end

function SystemSettingModule:ShowBindPhoneAreaDefault(desc)
  if not self.IsCanShowError then
    return
  end
  self.IsCanShowError = false
  if self.data.BindPhoneSettingData then
    local panel = self:GetPanel("SystemSettingMain")
    if panel then
      panel:ShowBindPhoneArea(false)
    end
  else
    local errorDesc
    if type(desc) == "string" then
      errorDesc = desc
    else
      errorDesc = LuaText.Error_Code_2451
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, errorDesc, nil, nil, 1)
  end
  _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.UnLockGetBindPhoneInfoReq)
end

function SystemSettingModule:OnCmdOpenBindPhonePanel(showType, data)
  if self:HasPanel("BindMobilePhone") then
    local panel = self:GetPanel("BindMobilePhone")
    panel:DoClose()
  end
  self:OpenPanel("BindMobilePhone", showType, data)
end

function SystemSettingModule:OnCmdOpenUnBindMobilePhoneTipsPanel(phoneNum)
  if self:HasPanel("UnBindMobilePhoneTipsPanel") then
    local panel = self:GetPanel("UnBindMobilePhoneTipsPanel")
    panel:DoClose()
  end
  self:OpenPanel("UnBindMobilePhoneTipsPanel", phoneNum)
end

function SystemSettingModule:OnCmdOpenPersonalInformationManagement()
  if self:HasPanel("UMG_PersonalInformationManagement") then
    local panel = self:GetPanel("UMG_PersonalInformationManagement")
    panel:DoClose()
  end
  self:OpenPanel("UMG_PersonalInformationManagement")
end

function SystemSettingModule:OnCmdReqGetPhoneBindCode(phoneNum)
  Log.Debug("SystemSettingModule:OnCmdReqGetPhoneBindCode==\229\143\145\233\128\129\230\156\141\229\138\161\231\171\175\232\142\183\229\143\150\233\170\140\232\175\129\231\160\129")
  local req = _G.ProtoMessage:newZoneGetMobileVeriCodeReq()
  req.mobile_num = phoneNum
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_MOBILE_VERI_CODE_REQ, req, self, self.RspGetPhoneBindCode, false, true)
end

function SystemSettingModule:RspGetPhoneBindCode(rsp)
  Log.Debug("SystemSettingModule:RspGetPhoneBindCode==\228\187\142\230\156\141\229\138\161\231\171\175\232\142\183\229\143\150\233\170\140\232\175\129\231\160\129\229\190\151\229\155\158\232\176\131")
  if 0 == rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:SetPlayerMobileBindInfo(rsp.mobile_bind_info)
    if self:HasPanel("BindMobilePhone") then
      local panel = self:GetPanel("BindMobilePhone")
      panel:SetCanGetCode(true)
      panel:UpdateUIByGetCode()
    end
  else
    if self:HasPanel("BindMobilePhone") then
      local panel = self:GetPanel("BindMobilePhone")
      panel:SetCanGetCode(true)
    end
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

function SystemSettingModule:OnCmdReqBindPhoneNum(operateType, phoneNum, code, unbindAllScenes)
  Log.Debug("SystemSettingModule:OnCmdReqBindPhoneNum==\229\143\145\233\128\129\230\156\141\229\138\161\231\171\175\231\187\145\229\174\154/\232\167\163\231\187\145\230\137\139\230\156\186\229\143\183")
  local req = _G.ProtoMessage:newZoneMobileOpReq()
  req.op_type = operateType
  req.mobile_num = phoneNum
  req.veri_code = code
  req.unbind_all_scenes = unbindAllScenes
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MOBILE_OP_REQ, req, self, self.RspBindPhoneNum, false, true)
end

function SystemSettingModule:RspBindPhoneNum(rsp)
  Log.Debug("SystemSettingModule:RspBindPhoneNum==\228\187\142\230\156\141\229\138\161\231\171\175\232\142\183\229\143\150\231\187\145\229\174\154/\232\167\163\231\187\145\230\137\139\230\156\186\229\143\183\230\152\175\229\144\166\230\136\144\229\138\159")
  if 0 == rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:SetPlayerMobileBindInfo(rsp.mobile_bind_info)
    if self:HasPanel("SystemSettingMain") then
      local panel = self:GetPanel("SystemSettingMain")
      panel:ShowBindPhoneText()
    end
    if rsp.mobile_bind_info.mobile_num then
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenBindPhonePanel, self.data.BindMobilePhoneEnum.BIND_SUCCESS)
    else
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenBindPhonePanel, self.data.BindMobilePhoneEnum.UNBIND_SUCCESS)
    end
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

function SystemSettingModule:OnCmdReqModifyPlayerSettings(newPlayerSettings)
  if NRCEnv:IsCreatePlayerMode() then
    return
  end
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  if newPlayerSettings.userSubscribe then
    req.settings.user_subsribe = newPlayerSettings.userSubscribe
  end
  if newPlayerSettings.pvp then
    req.settings.pvp = newPlayerSettings.pvp
  end
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  local onlineModuleData = OnlineModule.data
  local serverName
  if onlineModuleData then
    serverName = onlineModuleData.serverName
  end
  local isAvailableServer = true
  if serverName then
  end
  if isAvailableServer then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnModifyPlayerSettingsRsp, false, true)
  else
    local a = require("Common.Coroutine.async")
    local au = require("Common.Coroutine.async_util")
    au.Launch(a.task(function()
      a.wait(au.DelaySeconds(0.2))
      self:OnModifyPlayerSettingsRsp({
        ret_info = {ret_code = 0}
      })
    end), function()
    end)
  end
end

function SystemSettingModule:OnModifyPlayerSettingsRsp(rsp)
  Log.Debug("SystemSettingModule:OnModifyPlayerSettingsRsp")
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\155\180\230\150\176\231\148\168\230\136\183\232\174\190\231\189\174\229\164\177\232\180\165")
    Log.Error("\230\155\180\230\150\176\231\148\168\230\136\183\232\174\190\231\189\174\229\164\177\232\180\165", table.tostring(rsp))
    if self:HasPanel("SystemSettingMain") then
      local panel = self:GetPanel("SystemSettingMain")
      panel:RefreshDropDownList()
      panel:SetUpNotificationList()
    end
  else
    self:OnCmdReqQueryPlayerSettings()
  end
end

function SystemSettingModule:OnCmdRefreshNotificationList()
  if self:HasPanel("SystemSettingMain") then
    local panel = self:GetPanel("SystemSettingMain")
    panel:RefreshNotificationList()
  end
end

function SystemSettingModule:OnCmdReqQueryPlayerSettings()
  local req = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ, req, self, self.OnQueryPlayerSettingsRsp, false, true)
end

function SystemSettingModule:OnQueryPlayerSettingsRsp(rsp)
  Log.Debug("SystemSettingModule:OnQueryPlayerSettingsRsp")
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\159\165\232\175\162\231\142\169\229\174\182\232\174\190\231\189\174\229\164\177\232\180\165", table.tostring(rsp))
  else
    self:OnApplyConfig("PlayerSettings", rsp.settings)
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.PlayerSettingUpdate)
  end
end

function SystemSettingModule:OnCmdGetPlayerSettings()
  if not self.data.playerSettings then
    return nil
  end
  local playerSettings = {}
  table.copy(self.data.playerSettings, playerSettings)
  return playerSettings
end

function SystemSettingModule:IsKeyMappable(targetKeyName, targetKeyCode)
  if self.data.UnMappableKeyName == nil then
    return true
  end
  if nil ~= self.data.UnMappableKeyCode and targetKeyCode == self.data.UnMappableKeyCode then
    return false, "Menu"
  end
  for idx, _unMappableKeyName in ipairs(self.data.UnMappableKeyName) do
    if targetKeyName == _unMappableKeyName then
      return false, _unMappableKeyName
    end
  end
  return true
end

function SystemSettingModule:GetPendingChangeButtonSettingData(buttonSettingId)
  local targetButtonSettingConf = _G.DataConfigManager:GetButtonSettingConf(buttonSettingId)
  if nil == targetButtonSettingConf then
    return nil
  end
  if not targetButtonSettingConf.button_ischangeable then
    Log.Error("\232\191\153\228\184\170\232\135\170\229\174\154\228\185\137\233\133\141\231\189\174\233\161\185\228\184\141\229\133\129\232\174\184\228\191\174\230\148\185!", buttonSettingId)
    return nil
  end
  local targetButtonType = targetButtonSettingConf.button_type
  local targetButtonIds = targetButtonSettingConf.numList
  if nil == targetButtonType or nil == self.data.ButtonTypeToButtonSettingConf or nil == self.data.ButtonTypeToButtonSettingConf[targetButtonType] or nil == self.data.UserCustomKeyMapping or type(targetButtonIds) ~= "table" or 0 == #targetButtonIds then
    return nil
  end
  return targetButtonType, targetButtonIds
end

function SystemSettingModule:OnCmdChangeCustomKeyMapping(targetButtonSettingId, newKeyName, keyCode)
  local bMappable, unMappableKeyName = self:IsKeyMappable(newKeyName, keyCode)
  if not bMappable then
    return SystemSettingEnum.CustomKeyMapRetCode.UnMappableKeyError, unMappableKeyName
  end
  local targetButtonType, targetButtonIds = self:GetPendingChangeButtonSettingData(targetButtonSettingId)
  if nil == targetButtonType or nil == targetButtonIds then
    return SystemSettingEnum.CustomKeyMapRetCode.DefaultError
  end
  if newKeyName == self:OnCmdGetButtonSettingMappingKey(targetButtonSettingId) then
    return SystemSettingEnum.CustomKeyMapRetCode.Success
  end
  local allButtonSettingConf = self.data.ButtonTypeToButtonSettingConf[targetButtonType]
  for idx, _buttonSettingConf in ipairs(allButtonSettingConf) do
    local buttonIds = _buttonSettingConf.numList
    if type(buttonIds) == "table" and #buttonIds > 0 then
      for idx1, buttonId in ipairs(buttonIds) do
        if newKeyName == self.data.UserCustomKeyMapping[buttonId] then
          return SystemSettingEnum.CustomKeyMapRetCode.ConflictError, _buttonSettingConf.id, buttonId
        end
      end
    end
  end
  local ModifyAction = {}
  local bModifyIsEmpty = true
  for idx, targetButtonId in ipairs(targetButtonIds) do
    local targetButtonConf = _G.DataConfigManager:GetDefaultButtonConf(targetButtonId)
    if targetButtonConf and targetButtonConf.button_action then
      ModifyAction[targetButtonConf.button_action] = newKeyName
      bModifyIsEmpty = false
    end
  end
  if bModifyIsEmpty then
    return SystemSettingEnum.CustomKeyMapRetCode.DefaultError
  end
  for idx, targetButtonId in ipairs(targetButtonIds) do
    self.data.UserCustomKeyMapping[targetButtonId] = newKeyName
  end
  _G.NRCModuleManager:DoCmd(EnhancedInputModuleCmd.ApplyUserModifiedKeyMappings, ModifyAction)
  local bSaveSuccess = JsonUtils.DumpSaved(_CustomKeyMappingConfigFilename, self.data.UserCustomKeyMapping)
  if not bSaveSuccess then
    return SystemSettingEnum.CustomKeyMapRetCode.SaveError
  end
  return SystemSettingEnum.CustomKeyMapRetCode.Success
end

function SystemSettingModule:OnCmdSwitchTwoCustomKeyMapping(buttonSettingId1, buttonSettingId2)
  local targetButtonType1, targetButtonIds1 = self:GetPendingChangeButtonSettingData(buttonSettingId1)
  local targetButtonType2, targetButtonIds2 = self:GetPendingChangeButtonSettingData(buttonSettingId2)
  if nil == targetButtonType1 or nil == targetButtonIds1 or nil == targetButtonType2 or nil == targetButtonIds2 then
    return SystemSettingEnum.CustomKeyMapRetCode.DefaultError
  end
  local keyName1 = self.data.UserCustomKeyMapping[targetButtonIds1[1]]
  local keyName2 = self.data.UserCustomKeyMapping[targetButtonIds2[1]]
  local ModifyAction = {}
  local bModifyIsEmpty = true
  for idx, targetButtonId in ipairs(targetButtonIds1) do
    local targetButtonConf = _G.DataConfigManager:GetDefaultButtonConf(targetButtonId)
    if targetButtonConf and targetButtonConf.button_action then
      ModifyAction[targetButtonConf.button_action] = keyName2
      bModifyIsEmpty = false
    end
  end
  for idx, targetButtonId in ipairs(targetButtonIds2) do
    local targetButtonConf = _G.DataConfigManager:GetDefaultButtonConf(targetButtonId)
    if targetButtonConf and targetButtonConf.button_action then
      ModifyAction[targetButtonConf.button_action] = keyName1
      bModifyIsEmpty = false
    end
  end
  if bModifyIsEmpty then
    return SystemSettingEnum.CustomKeyMapRetCode.DefaultError
  end
  _G.NRCModuleManager:DoCmd(EnhancedInputModuleCmd.ApplyUserModifiedKeyMappings, ModifyAction)
  for idx, targetButtonId in ipairs(targetButtonIds1) do
    self.data.UserCustomKeyMapping[targetButtonId] = keyName2
  end
  for idx, targetButtonId in ipairs(targetButtonIds2) do
    self.data.UserCustomKeyMapping[targetButtonId] = keyName1
  end
  local bSaveSuccess = JsonUtils.DumpSaved(_CustomKeyMappingConfigFilename, self.data.UserCustomKeyMapping)
  if not bSaveSuccess then
    return SystemSettingEnum.CustomKeyMapRetCode.SaveError
  end
  return SystemSettingEnum.CustomKeyMapRetCode.Success
end

function SystemSettingModule:OnCmdFullyApplyUserCustomKeyMapping(bResetToDefault)
  local defaultButtonConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.DEFAULT_BUTTON_CONF)
  if nil == defaultButtonConf then
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168", _G.DataConfigManager.ConfigTableId.DEFAULT_BUTTON_CONF)
    return
  end
  local buttonSettingConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BUTTON_SETTING_CONF)
  if nil == buttonSettingConf then
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168", _G.DataConfigManager.ConfigTableId.BUTTON_SETTING_CONF)
    return
  end
  local buttonIdToButtonSettingId = {}
  local allButtonSettingConf = buttonSettingConf:GetAllDatas()
  for _, conf in pairs(allButtonSettingConf) do
    if conf.numList and #conf.numList > 0 then
      buttonIdToButtonSettingId[conf.numList[1]] = conf.id
    end
  end
  local resetMakeSenseButtonSettingIds = {}
  local defaultKeyMapping = self.data:LoadDefaultKeyMapping()
  local PrevCustomKeyMapping
  if bResetToDefault then
    PrevCustomKeyMapping = self.data.UserCustomKeyMapping
    self.data.UserCustomKeyMapping = defaultKeyMapping
  end
  local userCustomKeyMapping = self.data.UserCustomKeyMapping
  if type(userCustomKeyMapping) ~= "table" then
    return
  end
  local ModifyAction = {}
  local allDefaultButtonConf = defaultButtonConf:GetAllDatas()
  for _, conf in pairs(allDefaultButtonConf) do
    if conf.button_action then
      ModifyAction[conf.button_action] = userCustomKeyMapping[conf.id]
      if bResetToDefault and PrevCustomKeyMapping and defaultKeyMapping[conf.id] ~= PrevCustomKeyMapping[conf.id] and buttonIdToButtonSettingId[conf.id] then
        resetMakeSenseButtonSettingIds[buttonIdToButtonSettingId[conf.id]] = true
      end
    end
  end
  if bResetToDefault then
    local bSaveSuccess = JsonUtils.DumpSaved(_CustomKeyMappingConfigFilename, self.data.UserCustomKeyMapping)
    self:DispatchEvent(SystemSettingModuleEvent.UpdateCustomMappingUI, nil, nil, resetMakeSenseButtonSettingIds)
  end
  _G.NRCModuleManager:DoCmd(EnhancedInputModuleCmd.ApplyUserModifiedKeyMappings, ModifyAction)
end

function SystemSettingModule:OnCmdGetMappingKeyUIName(_actionName)
  local keyName = _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.GetMappingKey, _actionName)
  if keyName and self.data and self.data.KeyUINameMap and self.data.KeyUIImage then
    return self.data.KeyUINameMap[keyName] or "", self.data.KeyUIImage[keyName] or ""
  end
  return "", ""
end

function SystemSettingModule:OnCmdOpenKeyStrokeDetectPanel(...)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SETTING_BUTTON_SETTING, true)
  if isBan then
    return
  end
  self:OpenPanel("KeyStrokeDetectPanel", ...)
end

function SystemSettingModule:OnCmdOpenPrivilegeAuthorizationPopUp(...)
  self:OpenPanel("UMG_PrivilegeAuthorizationPopUp", ...)
end

function SystemSettingModule:OnCmdClosePrivilegeAuthorizationPopUp()
  self:ClosePanel("UMG_PrivilegeAuthorizationPopUp")
end

function SystemSettingModule:OnCmdGetButtonSettingMappingKey(buttonSettingId, bWithKeyUIName)
  local buttonSettingConf = _G.DataConfigManager:GetButtonSettingConf(buttonSettingId)
  if nil == buttonSettingConf then
    return
  end
  local buttonIds = buttonSettingConf.numList
  if type(buttonIds) ~= "table" or #buttonIds <= 0 then
    return
  end
  if nil == self.data.UserCustomKeyMapping then
    return
  end
  local keyName = self.data.UserCustomKeyMapping[buttonIds[1]]
  if bWithKeyUIName then
    return keyName, self.data.KeyUINameMap[keyName], self.data.KeyUIImage[keyName]
  else
    return keyName
  end
end

function SystemSettingModule:GetAllowFriendWatchBattle()
  local data = self.data
  local playerSettings = data and data.playerSettings
  local pvp = playerSettings and playerSettings.pvp
  local observe_battle = pvp and pvp.observe_battle
  local deny = observe_battle and observe_battle.deny
  local allow = not deny
  return allow
end

function SystemSettingModule:OnCmdGetKeyUIName(keyName)
  local keyUIName = ""
  local keyUIImage = ""
  if not string.IsNilOrEmpty(keyName) and self.data then
    keyUIName = self.data.KeyUINameMap[keyName]
    keyUIImage = self.data.KeyUIImage[keyName]
  end
  return keyUIName, keyUIImage
end

function SystemSettingModule:OnCmdCheckUserSubscribeInfo(userSubscribeType)
  if not self.data.playerSettings then
    return false
  end
  if not self.data.playerSettings.userSubscribe then
    return false
  end
  if userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_HATCH_EGG then
    return self.data.playerSettings.userSubscribe.hatch_egg
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_TRAVEL then
    return self.data.playerSettings.userSubscribe.travel
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_DEBRIS_FULL then
    return self.data.playerSettings.userSubscribe.debris_full
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_NEW_ACTIVITY then
    return self.data.playerSettings.userSubscribe.new_activity
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_BATTLE then
    return self.data.playerSettings.userSubscribe.friend_battle
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_EXCHANGE_EGG then
    return self.data.playerSettings.userSubscribe.exchange_egg
  elseif userSubscribeType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_VISIT then
    return self.data.playerSettings.userSubscribe.friend_visit
  end
  return false
end

function SystemSettingModule:OnCmdReqGetUserSubscribeTplInfo(tpl_type_list, need_openlink)
  local req = _G.ProtoMessage:newZoneGetUserSubscribeTplInfoReq()
  req.tpl_type_list = tpl_type_list
  req.need_openlink = need_openlink or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_USER_SUBSCRIBE_TPL_INFO_REQ, req, self, self.RspGetUserSubscribeTplInfo, false, false)
end

function SystemSettingModule:OnCmdRefreshSecondaryList()
  if self:HasPanel("SystemSettingMain") then
    local panel = self:GetPanel("SystemSettingMain")
    panel:RefreshSecondaryList()
  end
end

function SystemSettingModule:RspGetUserSubscribeTplInfo(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(SystemSettingModuleEvent.GetUserSubscribeTplInfo, rsp)
  end
end

function SystemSettingModule:OnScreenTouchStart()
  if _G.RocoEnv.IS_EDITOR and not self.data.bEnableSleepModeOnEditor then
    return
  end
  if not _G.GlobalConfig.DebugEnableSleepMode then
    return
  end
  self:QuitSleepMode()
  if self._sleepTimerId then
    _G.DelayManager:CancelDelayById(self._sleepTimerId)
  end
end

function SystemSettingModule:OnScreenTouchEnd()
  if _G.RocoEnv.IS_EDITOR and not self.data.bEnableSleepModeOnEditor then
    return
  end
  if not _G.GlobalConfig.DebugEnableSleepMode then
    return
  end
  if UE4Helper and UE4Helper.IsPCMode and UE4Helper.IsPCMode() then
    return
  end
  self:StartSleepCountdown()
end

function SystemSettingModule:EnterSleepMode()
  if not _G.DataModelMgr.PlayerDataModel:HasStoryFlag(9905) then
    return
  end
  if UE4Helper and UE4Helper.IsPCMode and UE4Helper.IsPCMode() then
    return
  end
  if self._isInSleepMode then
    return
  end
  self._isInSleepMode = true
  if self._savedFrameQuality == nil then
    self._savedFrameQuality = UE4.UNRCQualityLibrary.GetFrameQuality()
  end
  if nil == self._savedBrightness then
    self._savedBrightness = UE4.UNRCQualityLibrary.GetSceneColorIntensity()
  end
  local targetFrameQuality = UE4.ENRCFrameQuality.Low
  local targetBrightness = 0.1
  self:OpenPanel("SleepPanel", targetFrameQuality, targetBrightness, self._savedFrameQuality, self._savedBrightness)
  local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
  sleepConfig.inSleep = true
  sleepConfig.sleepIntervalSeconds = self._sleepIntervalSeconds or 600
  sleepConfig.savedFrameQuality = self._savedFrameQuality
  sleepConfig.savedBrightness = self._savedBrightness
  sleepConfig.targetFrameQuality = targetFrameQuality
  sleepConfig.targetBrightness = targetBrightness
  JsonUtils.DumpSaved(_SleepConfigFilename, sleepConfig)
  _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.EnterSleepMode)
end

function SystemSettingModule:QuitSleepMode()
  Log.Info("SystemSettingModule:QuitSleepMode \233\128\128\229\135\186\229\190\133\230\156\186")
  self:ClosePanel("SleepPanel")
  if not self._isInSleepMode then
    return
  end
  self._isInSleepMode = false
  Log.Info(string.format("SystemSettingModule:QuitSleepMode \230\129\162\229\164\141\228\185\139\229\137\141\232\174\190\231\189\174 %s %s", self._savedFrameQuality, self._savedBrightness))
  if self._savedFrameQuality ~= nil then
    pcall(function()
      UE4.UNRCQualityLibrary.SetFrameQuality(self._savedFrameQuality)
    end)
    self._savedFrameQuality = nil
  end
  if self._savedBrightness ~= nil then
    self._savedBrightness = nil
  end
  local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
  local needSave = false
  if nil ~= sleepConfig.inSleep then
    sleepConfig.inSleep = nil
    needSave = true
  end
  if nil ~= sleepConfig.savedFrameQuality then
    sleepConfig.savedFrameQuality = nil
    needSave = true
  end
  if nil ~= sleepConfig.savedBrightness then
    sleepConfig.savedBrightness = nil
    needSave = true
  end
  if nil ~= sleepConfig.targetFrameQuality then
    sleepConfig.targetFrameQuality = nil
    needSave = true
  end
  if nil ~= sleepConfig.targetBrightness then
    sleepConfig.targetBrightness = nil
    needSave = true
  end
  local interval = sleepConfig.sleepIntervalSeconds
  if type(interval) ~= "number" then
    sleepConfig.sleepIntervalSeconds = self._sleepIntervalSeconds or 600
    needSave = true
  elseif interval < 0 then
    sleepConfig.sleepIntervalSeconds = 0
    needSave = true
  end
  if needSave then
    JsonUtils.DumpSaved(_SleepConfigFilename, sleepConfig)
  end
  _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.QuitSleepMode)
end

function SystemSettingModule:SwitchSleepModeOnEditor()
  self.data.bEnableSleepModeOnEditor = not self.data.bEnableSleepModeOnEditor
  Log.Warning(string.format("\229\189\147\229\137\141\231\188\150\232\190\145\229\153\168\228\184\139\229\190\133\230\156\186\231\138\182\230\128\129\239\188\154%s\239\188\140\230\128\187\229\188\128\229\133\179\239\188\154%s", self.data.bEnableSleepModeOnEditor, _G.GlobalConfig.DebugEnableSleepMode))
  if self._sleepTimerId then
    _G.DelayManager:CancelDelayById(self._sleepTimerId)
    self._sleepTimerId = nil
  end
  if _G.RocoEnv.IS_EDITOR and self.data.bEnableSleepModeOnEditor and _G.GlobalConfig.DebugEnableSleepMode then
    self:StartSleepCountdown()
  end
end

function SystemSettingModule:SwitchSleepMode()
  if self._sleepTimerId then
    _G.DelayManager:CancelDelayById(self._sleepTimerId)
    self._sleepTimerId = nil
  end
  if not _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.DebugEnableSleepMode then
    self:StartSleepCountdown()
  end
end

function SystemSettingModule:StartSleepCountdown()
  if self._sleepTimerId then
    _G.DelayManager:CancelDelayById(self._sleepTimerId)
    self._sleepTimerId = nil
  end
  if not _G.DataModelMgr.PlayerDataModel:HasStoryFlag(9905) then
    return
  end
  local interval = self._sleepIntervalSeconds or 600
  if interval and interval > 0 then
    self._sleepTimerId = _G.DelayManager:DelaySeconds(interval, function()
      self._sleepTimerId = nil
      if self:CheckCanEnterSleepMode() then
        self:EnterSleepMode()
      else
        self:StartSleepCountdown()
      end
    end)
  end
end

function SystemSettingModule:CheckCanEnterSleepMode()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local SALS = _G.ProtoEnum and _G.ProtoEnum.SpaceActorLogicStatus
  if not (player and SALS) or not player.IsLogicStatus then
    Log.Info("\232\191\155\229\133\165\229\190\133\230\156\186\229\164\177\232\180\165\239\188\140\229\142\159\229\155\160\239\188\154player\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\230\152\175player.IsLogicStatus\228\184\141\229\173\152\229\156\168")
    return false
  end
  for _, st in ipairs(self.data.sleepModeBlockers) do
    if st and player:IsLogicStatus(st) then
      Log.Info(string.format("\232\191\155\229\133\165\229\190\133\230\156\186\229\164\177\232\180\165\239\188\140\229\142\159\229\155\160\239\188\154\232\167\166\229\143\145blocker id, %s", st))
      return false
    end
  end
  if player:IsLogicStatus(SALS.SALS_PLAYER_AFK) or player:IsLogicStatus(SALS.SALS_NORMAL) then
    Log.Info("\232\191\155\229\133\165\229\190\133\230\156\186\230\136\144\229\138\159")
    return true
  end
  Log.Info("\232\191\155\229\133\165\229\190\133\230\156\186\229\164\177\232\180\165\239\188\140\229\142\159\229\155\160\239\188\154\232\153\189\231\132\182\228\184\141\229\156\168blocker\228\184\173\230\139\166\230\136\170\239\188\140\228\189\134\230\152\175\231\142\169\229\174\182\231\138\182\230\128\129\228\184\141\228\184\186AFK\230\136\150\232\128\133\230\152\175NORMAL")
  return false
end

function SystemSettingModule:EnterSleepModeOnDebug()
  if self._isInSleepMode then
    return
  end
  self._isInSleepMode = true
  if self._sleepTimerId then
    _G.DelayManager:CancelDelayById(self._sleepTimerId)
    self._sleepTimerId = nil
  end
  if nil == self._savedFrameQuality then
    self._savedFrameQuality = UE4.UNRCQualityLibrary.GetFrameQuality()
  end
  if nil == self._savedBrightness then
    self._savedBrightness = UE4.UNRCQualityLibrary.GetSceneColorIntensity()
  end
  local targetFrameQuality = UE4.ENRCFrameQuality.Low
  local targetBrightness = 0.1
  self:OpenPanel("SleepPanel", targetFrameQuality, targetBrightness, self._savedFrameQuality, self._savedBrightness)
  local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
  sleepConfig.inSleep = true
  sleepConfig.sleepIntervalSeconds = self._sleepIntervalSeconds or 600
  sleepConfig.savedFrameQuality = self._savedFrameQuality
  sleepConfig.savedBrightness = self._savedBrightness
  sleepConfig.targetFrameQuality = targetFrameQuality
  sleepConfig.targetBrightness = targetBrightness
  JsonUtils.DumpSaved(_SleepConfigFilename, sleepConfig)
end

function SystemSettingModule:ChangePlayerName()
  local panel = self:GetPanel("UMG_PersonalInformationManagement")
  if panel then
    panel:ChangePlayerName()
  end
end

function SystemSettingModule:ReqSecondaryPasswordGetInfo()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordGetInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_GET_INFO_REQ, reqMsg, self, self.OnSecondaryPasswordGetInfoRsp, nil, false)
end

function SystemSettingModule:OnSecondaryPasswordGetInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Info("SystemSettingModule:OnSecondaryPasswordGetInfoRsp new", rsp.status, rsp.status_timestamp, rsp.default_free)
    if self.passwordInfo then
      Log.Info("SystemSettingModule:OnSecondaryPasswordGetInfoRsp old", self.passwordInfo.status, self.passwordInfo.status_timestamp, self.passwordInfo.default_free)
      _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.passwordInfo.status, rsp.status)
    end
    self.passwordInfo = rsp
  end
end

function SystemSettingModule:GetSecondaryPasswordInfo()
  return self.passwordInfo
end

function SystemSettingModule:OnSecondaryPasswordStatusChange(status, status_timestamp, default_free)
  Log.Info("SystemSettingModule:OnSecondaryPasswordStatusChange new", status, status_timestamp, default_free)
  if self.passwordInfo then
    Log.Info("SystemSettingModule:OnSecondaryPasswordStatusChange old", self.passwordInfo.status, self.passwordInfo.status_timestamp, self.passwordInfo.default_free)
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.passwordInfo.status, status)
  end
  self.passwordInfo.status = status
  self.passwordInfo.status_timestamp = status_timestamp
  self.passwordInfo.default_free = default_free
end

function SystemSettingModule:OnSecondaryPasswordUnsetNotify(rsp)
  self:OpenSecondaryPasswordGoSettingPopUp()
end

function SystemSettingModule:OnSecondaryPasswordNeedCheckNotify(rsp)
  self:CheckSecondaryPassword()
end

function SystemSettingModule:CheckSecondaryPassword()
  local unlockLevel = _G.DataConfigManager:GetActivityGlobalConfig("secondary_password_unlocks_level_restriction").num
  local playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  if unlockLevel > playerLevel then
    return true
  end
  if self.passwordInfo then
    if self.passwordInfo.status ~= ProtoEnum.SecondaryPasswordStatus.SPS_Free then
      self:OpenPanel("SecondaryPasswordVerify")
      return false
    else
      return true
    end
  else
    Log.Error("SystemSettingModule:CheckSecondaryPassword passwordInfo is nil")
    return false
  end
end

function SystemSettingModule:OpenSecondaryPasswordSet()
  self:OpenPanel("SecondaryPasswordSet")
end

function SystemSettingModule:OpenSecondaryPasswordModify()
  self:OpenPanel("SecondaryPasswordModify")
end

function SystemSettingModule:OpenSecondaryPasswordVerify()
  self:OpenPanel("SecondaryPasswordVerify")
end

function SystemSettingModule:OpenSecondaryPasswordCancel()
  self:OpenPanel("SecondaryPasswordCancel")
end

function SystemSettingModule:OpenSecondaryPasswordCancelForceDisable()
  self:OpenPanel("SecondaryPasswordCancelForceDisable")
end

function SystemSettingModule:ForgetSecondaryPassword()
  local function OnClickConfirm()
    if self.passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_force_close_success)
      
      return
    end
    local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordForceDisableReq()
    reqMsg.action_type = ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_DISABLE
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_FORCE_DISABLE_REQ, reqMsg, self, self.OnSecondaryPasswordForceDisableRsp, nil, false)
  end
  
  local commonPopUpModule = _G.NRCModuleManager:GetModule("CommonPopUpModule")
  if commonPopUpModule:HasPanel("Common_Remind") then
    local panel = commonPopUpModule:GetPanel("Common_Remind")
    if panel then
      panel:DoClose()
    end
  end
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Call = self
  popUpData.TitleText = LuaText.secondary_pwd_force_close_screen_title
  popUpData.Btn_LeftText = LuaText.CANCEL
  popUpData.Btn_RightText = LuaText.secondary_pwd_force_close_button_tips
  popUpData.RemindSwitch = 0
  popUpData.ContentText = LuaText.secondary_pwd_force_close_screen_text
  popUpData.Btn_RightHandler = OnClickConfirm
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function SystemSettingModule:OnSecondaryPasswordForceDisableRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.action_type == ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_DISABLE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_force_close_success)
    self:OnSecondaryPasswordStatusChange(rsp.status, rsp.status_timestamp, rsp.default_free)
    if not self:HasPanel("SystemSettingMain") and not self:IsPanelInOpening("SystemSettingMain") then
      local reqParamList = _G.NRCPanelOpenReqData()
      reqParamList.cmdId = _G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ
      reqParamList.reqClass = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
      reqParamList.ignoreErrorTip = false
      reqParamList.needModal = false
      reqParamList.Caller = self
      self:OpenPanel("SystemSettingMain", 5, reqParamList)
    end
  end
end

function SystemSettingModule:OpenSecondaryPasswordGoSettingPopUp()
  local function OpenSystemSetting()
    local reqParamList = _G.NRCPanelOpenReqData()
    
    reqParamList.cmdId = _G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ
    reqParamList.reqClass = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
    reqParamList.ignoreErrorTip = false
    reqParamList.needModal = false
    reqParamList.Caller = self
    self:OpenPanel("SystemSettingMain", 5, reqParamList)
  end
  
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Call = self
  popUpData.Btn_LeftText = LuaText.secondary_pwd_unset_status
  popUpData.Btn_RightText = LuaText.secondary_pwd_unset_button
  popUpData.RemindSwitch = 0
  popUpData.ContentText = LuaText.secondary_pwd_unset_setting_tips
  popUpData.Btn_RightHandler = OpenSystemSetting
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function SystemSettingModule:EncryptInputText(inputText, authInfo)
  if nil == authInfo then
    return
  end
  local public_key_md5 = UE.UNRCStatics.HashStringMD5(authInfo.public_key)
  if public_key_md5 == authInfo.public_key_md5 then
    local hashInputText = UE.UNRCStatics.HashStringMD5(authInfo.salting .. "_" .. inputText)
    local ciphertext = UE.UNRCStatics.RSAPublicEncrypt(authInfo.sequence .. "_" .. hashInputText, authInfo.public_key)
    return ciphertext
  else
    Log.Error("SystemSettingModule:EncryptInputTex public_key md5 \228\184\141\228\184\128\232\135\180\239\188\129")
  end
end

return SystemSettingModule
