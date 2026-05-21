local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local LoginModuleEvent = require("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local PlayVideoAction = require("NewRoco.Modules.System.LoginModule.Actions.PlayVideoAction")
local DoCmdAction = require("NewRoco.Modules.System.LoginModule.Actions.DoCmdAction")
local SwitchLevelAction = require("NewRoco.Modules.System.LoginModule.Actions.SwitchLevelAction")
local PopWindowAction = require("NewRoco.Modules.System.LoginModule.Actions.PopWindowAction")
local PopWarningAction = require("NewRoco.Modules.System.LoginModule.Actions.PopWarningAction")
local ShowPanelAction = require("NewRoco.Modules.System.LoginModule.Actions.ShowPanelAction")
local CheckConditionAction = require("NewRoco.Modules.System.LoginModule.Actions.CheckConditionAction")
local PSOInitAction = require("NewRoco.Modules.System.LoginModule.Actions.PSOInitAction")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local FINISHED = "FINISHED"

local function InstantiateUpdateFsm()
  local UpdateFsm = Fsm("UpdateFsm")
  local PlayBGMState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.PlayBGMState)
  local OpenUpVideoState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.OpenUpVideoState)
  local CloudVideoState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.CloudVideoState)
  local UpdateFailedState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.UpdateFailedState)
  local UpdateState = UpdateFsm:CreateComposedState(LoginEnum.StateNames.UpdateState)
  local CheckUpdateState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckUpdateState)
  local CheckPreDownloadState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckPreDownloadState)
  local ResVerifyState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.ResVerifyState)
  local CheckPatchUpdateState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckPatchUpdateState)
  local CheckIfDeviceBlockedState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckIfDeviceBlockedState)
  local PCCheckIfDeviceBlockedState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.PCCheckIfDeviceBlockedState)
  local CheckPreDownloadBasePaksState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckPreDownloadBasePaksState)
  local PreDownloadBasePaksState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.PreDownloadBasePaksState)
  local CheckEarlyContentUpdateState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckEarlyContentUpdateState)
  local PufferNoWifiNoticeState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.PufferNoWifiNoticeState)
  local PufferContinueDownloadState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.PufferContinueDownloadState)
  local CheckBaseResUpdateState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.CheckBaseResUpdateState)
  local MountDownloadedPakState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.MountDownloadedPakState)
  local UpdateInterruptState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.UpdateInterruptState)
  local WaitForAllProgressEndState = UpdateState:CreateChildBurstState(LoginEnum.StateNames.WaitForAllProgressEndState)
  local UpdateAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.UpdateAppState)
  local UpdateIOSAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.UpdateIOSAppState)
  local UpdateAndroidAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.UpdateAndroidAppState)
  local UpdateOpenHarmonyAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.UpdateOpenHarmonyAppState)
  local ConfirmUpdateIOSAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.ConfirmUpdateIOSAppState)
  local ConfirmUpdateAndroidAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.ConfirmUpdateAndroidAppState)
  local ConfirmUpdateOpenHarmonyAppState = UpdateState:CreateChildSequentialState(LoginEnum.StateNames.ConfirmUpdateOpenHarmonyAppState)
  local EndState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.UpdateEndState)
  local CloseAppState = UpdateFsm:CreateBurstState(LoginEnum.StateNames.CloseAppState)
  OpenUpVideoState:AddAction(CheckConditionAction("CheckSkipVideos", {
    Condition = LoginEnum.Conditions.SkipVideos,
    Success = FINISHED
  }))
  OpenUpVideoState:AddAction(DoCmdAction("OpenVideoUI", {
    Cmd = UpdateUIModuleCmd.OpenMainPanel,
    FinishEvent = LoginModuleEvent.UIOpened,
    Arguments = {true}
  }))
  OpenUpVideoState:AddAction(DoCmdAction("FadeOutBlackScreenPreTencentOpenVideo", {
    Cmd = UpdateUIModuleCmd.ShowBlackBackground,
    DoAfterFinish = 1,
    Arguments = {0}
  }))
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    OpenUpVideoState:AddAction(CheckConditionAction("CheckBackFromBigWorld", {
      Condition = LoginEnum.Conditions.CheckBackFromBigWorld,
      Success = FINISHED
    }))
    OpenUpVideoState:AddAction(PlayVideoAction("PlayMoreFunOpenUpVideo", {
      path = UEPath.FULL_OPENING,
      bLoop = false,
      bPlayAndContinue = false
    }))
  end
  OpenUpVideoState:AddTransitionToState(FINISHED, PlayBGMState)
  PlayBGMState:AddAction(ShowPanelAction("OpenUI", {
    PanelName = LoginEnum.PanelNames.PreNRCPanel,
    TurnOn = true,
    FinishEvent = LoginModuleEvent.UIOpened
  }))
  PlayBGMState:AddAction(DoCmdAction("PlayBGM", {
    Cmd = UpdateUIModuleCmd.PlayBGM,
    bDoAndContinue = true
  }))
  PlayBGMState:AddTransitionToState(FINISHED, CloudVideoState)
  CloudVideoState:AddAction(PlayVideoAction("PlayVideoList", {
    path = UEPath.LOGIN_CLOUD_LOOP,
    StartVideoListMode = true,
    bPlayAndContinue = true
  }))
  CloudVideoState:AddAction(DoCmdAction("WaitForVideoReady", {
    Cmd = UpdateUIModuleCmd.WaitForVideoReady,
    FinishEvent = LoginModuleEvent.VideoReady
  }))
  CloudVideoState:AddAction(DoCmdAction("PauseVideoList", {
    Cmd = UpdateUIModuleCmd.PauseVideoList,
    bDoAndContinue = true
  }))
  CloudVideoState:AddTransitionToState(FINISHED, UpdateState)
  UpdateFailedState:AddAction(DoCmdAction("PopupErrorTipsDialog", {
    Cmd = UpdateUIModuleCmd.PopupErrorTipsDialog
  }))
  UpdateFailedState:AddTransitionToState(LoginModuleEvent.RetryUpdate, UpdateState)
  UpdateFailedState:AddTransitionToState(LoginModuleEvent.RetryEarlyContentUpdate, CheckEarlyContentUpdateState)
  UpdateFailedState:AddTransitionToState(LoginModuleEvent.RetryEarlyContentWithBaseUpdate, CheckPreDownloadBasePaksState)
  UpdateFailedState:AddTransitionToState(LoginModuleEvent.RetryBaseUpdate, CheckBaseResUpdateState)
  UpdateState:AddTransitionToState(LoginModuleEvent.RetryUpdate, UpdateState)
  UpdateState:AddTransitionToState(LoginModuleEvent.RetryEarlyContentUpdate, CheckEarlyContentUpdateState)
  UpdateState:AddTransitionToState(LoginModuleEvent.RetryEarlyContentWithBaseUpdate, CheckPreDownloadBasePaksState)
  UpdateState:AddTransitionToState(LoginModuleEvent.RetryBaseUpdate, CheckBaseResUpdateState)
  UpdateState:AddTransitionToState(LoginModuleEvent.UpdateError, UpdateFailedState)
  UpdateState:AddTransitionToState(LoginModuleEvent.PopUpWindowCancel, CloseAppState)
  UpdateState:AddTransitionToState(LoginModuleEvent.UpdateInterrupted, UpdateInterruptState)
  UpdateState:AddTransitionToState(LoginModuleEvent.UpdateSuspend, UpdateInterruptState)
  UpdateInterruptState:AddAction(DoCmdAction("CancelUpdates", {
    Cmd = UpdateUIModuleCmd.CancelUpdates,
    bDoAndContinue = true
  }))
  UpdateInterruptState:AddTransitionToState(FINISHED, UpdateState)
  CheckUpdateState:AddAction(ShowPanelAction("OpenUI", {
    PanelName = LoginEnum.PanelNames.PreNRCPanel,
    TurnOn = true,
    FinishEvent = LoginModuleEvent.UIOpened
  }))
  CheckUpdateState:AddAction(CheckConditionAction("SkipUpdateOnLocalBuild", {
    Condition = LoginEnum.Conditions.IsFullPackage,
    Success = LoginModuleEvent.SkipUpdate
  }))
  CheckUpdateState:AddAction(CheckConditionAction("SkipUpdateOnPC", {
    Condition = LoginEnum.Conditions.SkipUpdate,
    Success = LoginModuleEvent.SkipUpdate
  }))
  CheckUpdateState:AddAction(DoCmdAction("DownloadUpdateConfig", {
    Cmd = UpdateUIModuleCmd.DownloadUpdateConfig,
    FinishEvent = LoginModuleEvent.DownloadUpdateConfigDone
  }))
  CheckUpdateState:AddAction(DoCmdAction("DownloadCloudGameConfig", {
    Cmd = UpdateUIModuleCmd.DownloadCloudGameConfig,
    FinishEvent = LoginModuleEvent.DownloadCloudGameConfigDone
  }))
  CheckUpdateState:AddAction(DoCmdAction("CheckIfEnableBackgroundDownload", {
    Cmd = UpdateUIModuleCmd.CheckIfEnableBackgroundDownload,
    FinishEvent = LoginModuleEvent.RequestPermissionDone
  }))
  CheckUpdateState:AddAction(DoCmdAction("CheckIfAppUpdateIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfAppUpdateIsNeeded,
    FinishEvent = LoginModuleEvent.NoNewVersion
  }))
  CheckUpdateState:AddAction(DoCmdAction("CheckIfDolphinResUpdateIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfResUpdateIsNeeded,
    FinishEvent = LoginModuleEvent.UpdateDone
  }))
  CheckUpdateState:AddTransitionToState(LoginModuleEvent.SkipUpdate, PCCheckIfDeviceBlockedState)
  CheckUpdateState:AddTransitionToState(FINISHED, CheckPreDownloadState)
  CheckUpdateState:AddTransitionToState(LoginModuleEvent.AppNeedUpdate, UpdateAppState)
  CheckPreDownloadState:AddAction(DoCmdAction("CheckLocalPreDownloadConfig", {
    Cmd = UpdateUIModuleCmd.CheckLocalPreDownloadConfig,
    FinishEvent = LoginModuleEvent.LocalPreDownloadConfigCheckDone
  }))
  CheckPreDownloadState:AddTransitionToState(FINISHED, ResVerifyState)
  CheckPreDownloadState:AddTransitionToState(LoginModuleEvent.LocalPreDownloadConfigCheckFailed, ResVerifyState)
  ResVerifyState:AddAction(DoCmdAction("ResHashCheck", {
    Cmd = UpdateUIModuleCmd.ResHashCheck
  }))
  ResVerifyState:AddTransitionToState(LoginModuleEvent.ResVerifySuccess, CheckPatchUpdateState)
  ResVerifyState:AddTransitionToState(LoginModuleEvent.ResVerifyFailed, UpdateState)
  CheckPatchUpdateState:AddAction(DoCmdAction("CheckIfPatchDownloadIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfPatchDownloadIsNeeded
  }))
  CheckPatchUpdateState:AddTransitionToState(LoginModuleEvent.PatchUpdateDone, CheckIfDeviceBlockedState)
  CheckPatchUpdateState:AddTransitionToState(LoginModuleEvent.PufferNoWifi, PufferNoWifiNoticeState)
  CheckIfDeviceBlockedState:AddAction(DoCmdAction("CheckIfDeviceBlocked", {
    Cmd = UpdateUIModuleCmd.CheckIfDeviceBlocked
  }))
  CheckIfDeviceBlockedState:AddTransitionToState(LoginModuleEvent.DeviceCheckPassed, CheckPreDownloadBasePaksState)
  PCCheckIfDeviceBlockedState:AddAction(DoCmdAction("CheckIfDeviceBlocked", {
    Cmd = UpdateUIModuleCmd.CheckIfDeviceBlocked
  }))
  PCCheckIfDeviceBlockedState:AddTransitionToState(LoginModuleEvent.DeviceCheckPassed, WaitForAllProgressEndState)
  CheckPreDownloadBasePaksState:AddAction(DoCmdAction("CheckIfPreDownloadBasePaksIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfPreDownloadBasePaksIsNeeded
  }))
  CheckPreDownloadBasePaksState:AddTransitionToState(LoginModuleEvent.DisablePreDownloadBasePaks, CheckEarlyContentUpdateState)
  CheckPreDownloadBasePaksState:AddTransitionToState(LoginModuleEvent.EnablePreDownloadBasePaks, PreDownloadBasePaksState)
  PreDownloadBasePaksState:AddAction(DoCmdAction("StartPreDownloadBasePaks", {
    Cmd = UpdateUIModuleCmd.StartPreDownloadBasePaks
  }))
  PreDownloadBasePaksState:AddTransitionToState(LoginModuleEvent.PreDownloadBasePaksDone, WaitForAllProgressEndState)
  PreDownloadBasePaksState:AddTransitionToState(LoginModuleEvent.PufferNoWifi, PufferNoWifiNoticeState)
  CheckEarlyContentUpdateState:AddAction(DoCmdAction("CheckIfEarlyContentDownloadIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfEarlyContentDownloadIsNeeded
  }))
  CheckEarlyContentUpdateState:AddTransitionToState(LoginModuleEvent.EarlyContentUpdateDone, CheckBaseResUpdateState)
  CheckEarlyContentUpdateState:AddTransitionToState(LoginModuleEvent.PufferNoWifi, PufferNoWifiNoticeState)
  CheckBaseResUpdateState:AddAction(DoCmdAction("CheckIfBaseResDownloadIsNeeded", {
    Cmd = UpdateUIModuleCmd.CheckIfBaseResDownloadIsNeeded
  }))
  CheckBaseResUpdateState:AddTransitionToState(LoginModuleEvent.BaseResDownloadDone, MountDownloadedPakState)
  CheckBaseResUpdateState:AddTransitionToState(LoginModuleEvent.DownloadBaseResAfterLogin, WaitForAllProgressEndState)
  CheckBaseResUpdateState:AddTransitionToState(LoginModuleEvent.PufferNoWifi, PufferNoWifiNoticeState)
  PufferNoWifiNoticeState:AddAction(DoCmdAction("PufferOpenNoWifiNoticeDialog", {
    Cmd = UpdateUIModuleCmd.PufferOpenNoWifiNoticeDialog
  }))
  PufferNoWifiNoticeState:AddTransitionToState(LoginModuleEvent.ContinuePufferUpdate, PufferContinueDownloadState)
  PufferContinueDownloadState:AddAction(DoCmdAction("PufferResumeDownload", {
    Cmd = UpdateUIModuleCmd.PufferResumeDownload
  }))
  PufferContinueDownloadState:AddTransitionToState(LoginModuleEvent.PufferNoWifi, PufferNoWifiNoticeState)
  PufferContinueDownloadState:AddTransitionToState(LoginModuleEvent.PatchUpdateDone, CheckIfDeviceBlockedState)
  PufferContinueDownloadState:AddTransitionToState(LoginModuleEvent.PreDownloadBasePaksDone, WaitForAllProgressEndState)
  PufferContinueDownloadState:AddTransitionToState(LoginModuleEvent.EarlyContentUpdateDone, CheckBaseResUpdateState)
  PufferContinueDownloadState:AddTransitionToState(LoginModuleEvent.BaseResDownloadDone, MountDownloadedPakState)
  MountDownloadedPakState:AddAction(DoCmdAction("MountDownloadedPaks", {
    Cmd = UpdateUIModuleCmd.MountDownloadedPaks,
    FinishEvent = LoginModuleEvent.MountDownloadedPakDone
  }))
  MountDownloadedPakState:AddTransitionToState(FINISHED, WaitForAllProgressEndState)
  WaitForAllProgressEndState:AddAction(DoCmdAction("WaitForAllProgressEnd", {
    Cmd = UpdateUIModuleCmd.WaitForAllProgressEnd,
    FinishEvent = UpdateUIModuleEvent.AllUpdateProgressEnd
  }))
  WaitForAllProgressEndState:AddAction(DoCmdAction("CheckIfNeedRestratApp", {
    Cmd = UpdateUIModuleCmd.CheckIfNeedRestratApp,
    FinishEvent = UpdateUIModuleEvent.NoNeedToRestartApp
  }))
  WaitForAllProgressEndState:AddAction(DoCmdAction("DownloadPreDownloadConfig", {
    Cmd = UpdateUIModuleCmd.DownloadPreDownloadConfig,
    FinishEvent = LoginModuleEvent.DownloadPreDownloadConfigDone
  }))
  WaitForAllProgressEndState:AddAction(DoCmdAction("InitPreDownloadPufferTask", {
    Cmd = UpdateUIModuleCmd.InitPreDownloadPufferTask,
    FinishEvent = LoginModuleEvent.DownloadPreDownloadConfigDone
  }))
  WaitForAllProgressEndState:AddTransitionToState(FINISHED, EndState)
  UpdateAppState:AddAction(CheckConditionAction("CheckIOSSystem", {
    Condition = LoginEnum.Conditions.IsOnIOS,
    Success = LoginModuleEvent.GoUpdateIOSApp
  }))
  UpdateAppState:AddAction(CheckConditionAction("CheckOpenHarmonySystem", {
    Condition = LoginEnum.Conditions.IsOnOpenHarmony,
    Success = LoginModuleEvent.GoUpdateOpenHarmonyApp
  }))
  UpdateAppState:AddTransitionToState(LoginModuleEvent.GoUpdateIOSApp, ConfirmUpdateIOSAppState)
  UpdateAppState:AddTransitionToState(LoginModuleEvent.GoUpdateOpenHarmonyApp, ConfirmUpdateOpenHarmonyAppState)
  UpdateAppState:AddTransitionToState(FINISHED, ConfirmUpdateAndroidAppState)
  ConfirmUpdateIOSAppState:AddAction(PopWindowAction("GotoAppStore", {
    Title = LuaText.updatefsm_1,
    Content = LuaText.updatefsm_2,
    OnlyConfirm = true,
    BtnRight = LuaText.umg_login_new_3
  }))
  ConfirmUpdateIOSAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowConfirm, UpdateIOSAppState)
  ConfirmUpdateIOSAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowCancel, CloseAppState)
  UpdateIOSAppState:AddAction(DoCmdAction("UpdateIOSApp", {
    Cmd = UpdateUIModuleCmd.UpdateIOSApp,
    bDoAndContinue = true
  }))
  UpdateIOSAppState:AddTransitionToState(FINISHED, ConfirmUpdateIOSAppState)
  ConfirmUpdateOpenHarmonyAppState:AddAction(PopWindowAction("GotoOpenHarmonyStore", {
    Title = LuaText.updatefsm_1,
    Content = LuaText.updatefsm_4,
    OnlyConfirm = true,
    BtnRight = LuaText.umg_login_new_3
  }))
  ConfirmUpdateOpenHarmonyAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowConfirm, UpdateOpenHarmonyAppState)
  ConfirmUpdateOpenHarmonyAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowCancel, CloseAppState)
  UpdateOpenHarmonyAppState:AddAction(DoCmdAction("UpdateOpenHarmonyApp", {
    Cmd = UpdateUIModuleCmd.UpdateOpenHarmonyApp,
    bDoAndContinue = true
  }))
  UpdateOpenHarmonyAppState:AddTransitionToState(FINISHED, ConfirmUpdateOpenHarmonyAppState)
  ConfirmUpdateAndroidAppState:AddAction(PopWindowAction("ConfirmInstallApk", {
    Title = LuaText.updatefsm_1,
    Content = LuaText.updateuimodule_39,
    BtnLeft = LuaText.updateuimodule_42,
    BtnRight = LuaText.updateuimodule_41
  }))
  ConfirmUpdateAndroidAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowConfirm, UpdateAndroidAppState)
  ConfirmUpdateAndroidAppState:AddTransitionToState(LoginModuleEvent.PopUpWindowCancel, CloseAppState)
  ConfirmUpdateAndroidAppState:AddTransitionToState(FINISHED, UpdateAndroidAppState)
  UpdateAndroidAppState:AddAction(DoCmdAction("UpdateAndroidApp", {
    Cmd = UpdateUIModuleCmd.UpdateAndroidApp
  }))
  UpdateAndroidAppState:AddTransitionToState(FINISHED, ConfirmUpdateAndroidAppState)
  EndState:AddAction(ShowPanelAction("CloseUI", {
    PanelName = LoginEnum.PanelNames.PreNRCPanel,
    TurnOn = false
  }))
  EndState:AddAction(SwitchLevelAction("OpenLoginLevel", {Level = "Login"}))
  EndState:AddAction(DoCmdAction("EnterLoginMode", {
    Cmd = UpdateUIModuleCmd.EnterLoginMode,
    bDoAndContinue = true
  }))
  CloseAppState:AddAction(DoCmdAction("CloseApp", {
    Cmd = UpdateUIModuleCmd.CloseApp
  }))
  UpdateFsm:SetInitState(OpenUpVideoState)
  return UpdateFsm
end

return InstantiateUpdateFsm
