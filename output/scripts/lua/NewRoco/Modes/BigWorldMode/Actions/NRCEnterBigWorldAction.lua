local NRCModeAction = require("Core.NRCMode.NRCModeAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local NRCEnterBigWorldAction = NRCModeAction:Extend("NRCEnterBigWorldAction")

function NRCEnterBigWorldAction:Ctor(name, properties)
  NRCModeAction.Ctor(self, name, properties)
end

function NRCEnterBigWorldAction:OnEnter()
  Log.Debug("[NRCEnterBigWorldAction] OnEnter")
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    SceneModule._isMainUIReady = false
  end
  self:BeginOpenPanelLobbyMain()
end

function NRCEnterBigWorldAction:BeginOpenPanelLobbyMain()
  Log.Debug("[NRCEnterBigWorldAction] BeginOpenPanelLobbyMain")
  if not _G.GlobalConfig.DisableSystemModule then
    NRCModeManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  end
  BattleNetManager:StartHandleCache()
  local Pass = false
  local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    if MainUIModule:HasAnyMainUIShowing() then
      Pass = true
    else
      self:Log("\228\184\187\231\149\140\233\157\162\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\141\229\143\175\232\167\129")
    end
  else
    self:Log("\228\184\187\231\149\140\233\157\162\230\168\161\229\157\151\228\184\141\229\173\152\229\156\168")
    if _G.GlobalConfig.DisableSystemModule then
      NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 0, true)
      NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 0)
    end
  end
  if not _G.GlobalConfig.DisableSystemModule and not _G.GlobalConfig.DisableNPCModule then
    if Pass then
      self:OnLobbyMainReady()
    else
      NRCEventCenter:RegisterEvent("NRCEnterBigWorldAction", self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
      NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 0.8)
    end
  end
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    SceneModule._isMainUIReady = Pass
  end
end

function NRCEnterBigWorldAction:OnExit()
  Log.Debug("NRCEnterBigWorldAction:OnExit")
  NRCModuleManager:PreloadModulePanel()
  _G.NRCPanelBlocker:Init()
end

function NRCEnterBigWorldAction:OnLobbyMainReady()
  Log.Debug("[NRCEnterBigWorldAction] OnLobbyMainReady")
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
  self.NRCEnterBigWorldActionTimer = _G.TimerManager:CreateTimer(self, "NRCEnterBigWorldActionTimer", 0.5, nil, self.OnTimerComplete, 9999)
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    SceneModule._isMainUIReady = true
  end
end

function NRCEnterBigWorldAction:OnTimerComplete()
  Log.Debug("[NRCEnterBigWorldAction] OnTimerComplete")
  _G.TimerManager:RemoveTimer(self.NRCEnterBigWorldActionTimer)
  self:OnMapLoaded()
end

function NRCEnterBigWorldAction:OnMapLoaded()
  Log.Debug("[NRCEnterBigWorldAction] OnTimerComplete")
  UE.UNRCStatics.ExecConsoleCommand("s.AsyncLoadingTimeLimit 5", nil)
  UE.UNRCStatics.ExecConsoleCommand("s.MaxCallbackTimeCost 5", nil)
  if UE4.UNRCStatics.IsAutoTesting() then
    local debugModule = NRCModuleManager:GetModule("DebugModule")
    debugModule:StartMainPlayerAutoMove()
  end
  self:Finish()
end

return NRCEnterBigWorldAction
