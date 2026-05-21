local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginModuleEvent = require("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local CommonUtils = {}
local GAME_MATRIX_TYPE_H5 = "H5"
local GAME_MATRIX_TYPE_APP = "APP"

function CommonUtils.IsGameCloudEnv()
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.PLATFORM_ANDROID then
    return false
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    return false
  end
  local GameMatrixMgr = GameInstance:GetGameMatrixMgr()
  if not GameMatrixMgr then
    return false
  end
  Log.Debug("[CommonUtils.IsGameCloudEnv] --->")
  return GameMatrixMgr:IsCloudGameEnv()
end

function CommonUtils.GetGameMatrixMgrWithCheck()
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.PLATFORM_ANDROID then
    return nil
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    return nil
  end
  local GameMatrixMgr = GameInstance:GetGameMatrixMgr()
  if not GameMatrixMgr then
    return nil
  end
  if not GameMatrixMgr:IsCloudGameEnv() then
    return nil
  end
  return GameMatrixMgr
end

function CommonUtils.IsH5GameCloudEnv()
  local GameMatrixMgr = CommonUtils.GetGameMatrixMgrWithCheck()
  if not GameMatrixMgr then
    return false
  end
  Log.Debug("[CommonUtils.IsH5GameCloudEnv] --->", GameMatrixMgr:GetClientType())
  return GameMatrixMgr:GetClientType() == GAME_MATRIX_TYPE_H5
end

function CommonUtils.IsAppGameCloudEnv()
  local GameMatrixMgr = CommonUtils.GetGameMatrixMgrWithCheck()
  if not GameMatrixMgr then
    return false
  end
  Log.Debug("[CommonUtils.IsH5GameCloudEnv] --->", GameMatrixMgr:GetClientType())
  return GameMatrixMgr:GetClientType() == GAME_MATRIX_TYPE_APP
end

function CommonUtils.SendClientEventToCGSDK(Message)
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.PLATFORM_ANDROID then
    return
  end
  Log.Debug("[CommonUtils.SendClientEventToCGSDK]", Message)
  local GameMatrixMgr = CommonUtils.GetGameMatrixMgrWithCheck()
  if not GameMatrixMgr then
    return
  end
  GameMatrixMgr:SendClientEvent(Message)
end

function CommonUtils.IsPrelaunchMode()
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.PLATFORM_ANDROID then
    return false
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    return false
  end
  return GameInstance:IsPrelaunchMode()
end

function CommonUtils.OnPrelaunchModeLogin()
  Log.Debug("[CommonUtils.OnPrelaunchModeLogin]")
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PrelaunchReadyDone)
end

function CommonUtils.OnFanJiNFCDiscover(NfcData, NfcBid, NfcPid)
  Log.Debug("[CommonUtils.OnFanJiNFCDiscover]", NfcData, NfcBid, NfcPid)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "NFC Success:" .. NfcBid, nil, nil, 2)
end

function CommonUtils.OnFanJiNFCDiscoverFailed(ErrorCode, ErrorMsg)
  Log.Debug("[CommonUtils.OnFanJiNFCDiscoverFailed]", ErrorCode, ErrorMsg)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "NFC Failed:" .. ErrorCode, nil, nil, 2)
end

function CommonUtils.CheckIOSMiniApp()
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.PLATFORM_ANDROID then
    return
  end
  Log.Debug("[CommonUtils.CheckIOSMiniApp] ")
  local GameMatrixMgr = CommonUtils.GetGameMatrixMgrWithCheck()
  if not GameMatrixMgr then
    return
  end
  return GameMatrixMgr:CheckIOSMiniApp()
end

return CommonUtils
