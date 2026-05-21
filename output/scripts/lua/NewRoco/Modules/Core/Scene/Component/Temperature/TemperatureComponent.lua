local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local TemperatureEnum = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureEnum")
local TemperatureUtils = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureUtils")
local CivilCalculator = require("NewRoco.Modules.Core.Scene.Common.CivilCalculator")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local CinematicModuleEvent = reload("NewRoco.Modules.Core.Cinematic.CinematicModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local TemperatureComponent = Base:Extend("TemperatureComponent")
local _INTERVAL_TIME = 0.5
local _SYNC_INTERVAL = 3
local _HOT_TEMP_UP = 100
local _HOT_TEMP_DOWN = 70
local _COLD_TEMP_UP = 30
local _COLD_TEMP_DOWN = 0
local _TEMP_ALT_FACTOR = 15
local _TEMP_ALT_STD = 12000
local _Humanities_FACTOR1 = 2
local _Humanities_FACTOR2 = 22

function TemperatureComponent:Attach(owner)
  Base.Attach(self, owner)
  self.bSyncTemp = false
  self.preC = 30
  self.c = 30
  self.bt = 0
  self.k = 50
  self.ForceUpdateToken = 0
  if not self.owner.isLocal then
    self.enabled = false
    return
  end
  self.InitGlobalConf()
  self.enabled = true
  self:AddForceUpdateToken()
  self.isPaused = false
  self.deltaTimeAcc = 0
  self.syncDltaTimeAcc = 0
  self.civilCalculator = CivilCalculator()
  self.body_temp_final_val = 0
  self.reach_final_time = 0
  self.bValidReachFinalTime = false
  self.curState = TemperatureEnum.BodyState.INIT
  self.isGMSurface = false
  self.surfaceDebugValue = 20
  self.isDebug = false
  self.isGMBt = false
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.LoadMapStart, self.OnDead)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.PlayerBornFinish, self.OnRecover)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.PlayerTeleportStart, self.OnStartTeleport)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_BODYTEM, self, self.OnFunctionStateChanged)
  local Ban, _ = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_BODYTEM, false, false)
  self.isPaused = Ban
end

function TemperatureComponent:DeAttach()
  self:OnDead()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.LoadMapStart, self.OnDead)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.PlayerBornFinish, self.OnRecover)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.PlayerTeleportStart, self.OnStartTeleport)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_BODYTEM, self, self.OnFunctionStateChanged)
  Base.DeAttach(self)
end

function TemperatureComponent:InitGlobalConf()
  local cfg
  cfg = _G.DataConfigManager:GetGlobalConfig("hot_temp")
  _HOT_TEMP_DOWN = cfg and cfg.numList[1] or _HOT_TEMP_DOWN
  _HOT_TEMP_UP = cfg and cfg.numList[2] or _HOT_TEMP_UP
  cfg = _G.DataConfigManager:GetGlobalConfig("cold_temp")
  _COLD_TEMP_DOWN = cfg and cfg.numList[1] or _COLD_TEMP_DOWN
  _COLD_TEMP_UP = cfg and cfg.numList[2] or _COLD_TEMP_UP
  cfg = _G.DataConfigManager:GetGlobalConfig("temp_altitude_factor")
  _TEMP_ALT_FACTOR = cfg and cfg.num or _TEMP_ALT_FACTOR
  _TEMP_ALT_FACTOR = _TEMP_ALT_FACTOR / 10000
  cfg = _G.DataConfigManager:GetGlobalConfig("temp_altitude_standard")
  _TEMP_ALT_STD = cfg and cfg.num or _TEMP_ALT_STD
  cfg = _G.DataConfigManager:GetGlobalConfig("temp_humanities_factor1")
  _Humanities_FACTOR1 = cfg and cfg.num or _Humanities_FACTOR1
  cfg = _G.DataConfigManager:GetGlobalConfig("temp_humanities_factor2")
  _Humanities_FACTOR2 = cfg and cfg.num or _Humanities_FACTOR2
  Log.Debug("TemperatureComponent:InitGlobalConf", _HOT_TEMP_DOWN, _COLD_TEMP_UP, _TEMP_ALT_FACTOR, _TEMP_ALT_STD)
end

function TemperatureComponent:OnDead()
  Log.Debug("TemperatureComponent:OnDead")
  self.body_temp_final_val = 0
  self.reach_final_time = 0
  self.bValidReachFinalTime = false
  self.bSyncTemp = false
  self.owner:SetTemperature(50)
  self:CalculateBt(0.01)
  self.bIsDead = true
  self.owner:SendEvent(PlayerModuleEvent.ON_BODY_TEMP_CHANGED, self.bt, 0, 0, true)
  self:AddForceUpdateToken()
end

function TemperatureComponent:OnStartTeleport()
  self:UpdateBodyTempUI(50)
  self:AddForceUpdateToken()
end

function TemperatureComponent:OnRecover()
  Log.Debug("TemperatureComponent:OnRecover")
  self.bIsDead = false
  self:AddForceUpdateToken()
end

function TemperatureComponent:OnReborn()
  Log.Debug("TemperatureComponent:OnReborn")
  self.bIsDead = false
  self:AddForceUpdateToken()
end

function TemperatureComponent:Update(deltaTime)
  if not self.owner.isLocal then
    return
  end
  if _G.BattleManager.isInBattle or self.owner.isTeleporting or self.isPaused or self.bIsDead then
    self.reach_final_time = self.reach_final_time + deltaTime
    if not self.isPaused then
      self.owner:SetTemperature(50)
    end
    return
  end
  if 0 == self.owner.serverData.attrs.hp then
    return
  end
  self:CalculateBt(deltaTime)
end

function TemperatureComponent:CheckNeedSyncTempImmediately()
  local preC = self.preC
  local c = self.c
  return preC < _COLD_TEMP_UP and c >= _COLD_TEMP_UP or preC >= _COLD_TEMP_UP and c < _COLD_TEMP_UP or preC < _HOT_TEMP_DOWN and c >= _HOT_TEMP_DOWN or preC >= _HOT_TEMP_DOWN and c < _HOT_TEMP_DOWN
end

function TemperatureComponent:OnRecBodyTempNofity(notify)
  Log.Debug("TemperatureComponent:OnRecBodyTempNofity", notify.body_temp_final_val, notify.reach_final_time, self.body_temp_final_val, self.reach_final_time, self.bt)
  if self.isGMBt then
    return
  end
  if self.bIsDead then
    Log.Error("\232\167\146\232\137\178\229\183\178\231\187\143\230\173\187\228\186\161\239\188\140\228\184\141\229\164\132\231\144\134\233\162\157\229\164\150\231\154\132\230\184\169\229\186\166Notify")
    return
  end
  if notify.body_temp_final_val ~= self.body_temp_final_val or notify.reach_final_time ~= self.reach_final_time then
    if self.isDebug then
      Log.Error("TemperatureComponent:OnRecBodyTempNofity new bt process", notify.body_temp_final_val, notify.reach_final_time, self.body_temp_final_val, self.reach_final_time)
    end
    self:AddForceUpdateToken()
  end
  self.body_temp_final_val = notify.body_temp_final_val
  self.reach_final_time = notify.reach_final_time
  if not self.bValidReachFinalTime then
    self:AddForceUpdateToken()
  end
  self.bValidReachFinalTime = true
  self.c = notify.nature_temp or 31
  self.owner:SetTemperature(self.c)
  if self.isDebug then
    Log.ErrorFormat("#C=%d BT=%.2f, \231\187\136\229\128\188=%d, \229\136\176\232\190\190\230\151\182\233\151\180=%s %s", self.c, self.bt, self.body_temp_final_val, os.date("%Y-%m-%d %H:%M:%S", math.floor(self.reach_final_time)), self.isPaused and "Paused" or "Running")
  end
end

function TemperatureComponent:GetCurSurfaceTemperature()
  local k = 0
  if not self.isGMSurface then
    local curSurface
    if self.owner.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
      curSurface = UE4.EPhysicalSurface.SurfaceType2
    elseif self.owner.viewObj.MoveFXComponent then
      curSurface = self.owner.viewObj.MoveFXComponent.CurSurface
    end
    if curSurface then
      local curSurfaceName = TemperatureUtils.GetSurfaceTypeName(curSurface)
      k = TemperatureUtils.GetSurfaceTemperature(curSurfaceName)
    end
  else
    k = self.surfaceDebugValue
  end
  return k
end

function TemperatureComponent:SetBodyTempDirect(BodyTemp)
  Log.Debug("TemperatureComponent:SetBodyTempDirect", BodyTemp, self.bt, self.bIsDead, self.body_temp_final_val, self.bSyncTemp)
  if self.isGMBt then
    return
  end
  if self.bIsDead then
    Log.Error("\232\167\146\232\137\178\229\183\178\231\187\143\230\173\187\228\186\161\239\188\140\228\184\141\229\164\132\231\144\134\233\162\157\229\164\150\231\154\132\230\184\169\229\186\166Notify")
    return
  end
  if self.bSyncTemp then
    return
  end
  local TimeDiff = self:GetTimeDiff()
  if self.isDebug then
    Log.Error("\231\155\180\230\142\165\230\155\180\230\150\176Bt", BodyTemp, TimeDiff, self.body_temp_final_val)
  end
  self:AddForceUpdateToken()
  self:UpdateBodyTemp(BodyTemp, TimeDiff, self.body_temp_final_val)
  self.bSyncTemp = true
end

function TemperatureComponent:UpdateBodyTemp(BodyTemp, DiffTime, FinalBodyTemp)
  self.bt = BodyTemp
  if not self.bValidReachFinalTime then
    return
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_BODY_TEMP_CHANGED, self.bt, DiffTime, FinalBodyTemp, self:FlushUpdateToken())
  self:UpdateBodyTempUI(BodyTemp)
end

function TemperatureComponent:GetTimeDiff()
  local CurrentTime = _G.ZoneServer:GetServerTime() / 1000
  local diffTime = self.reach_final_time - CurrentTime
  return diffTime
end

function TemperatureComponent:CalculateBt(deltaTime)
  local diffTime = self:GetTimeDiff()
  if nil == diffTime then
    return
  end
  if self.bt == self.body_temp_final_val and diffTime <= 0 and not self:FlushUpdateToken(true) then
    return
  end
  local previousBt = self.bt
  if diffTime <= 0 or deltaTime >= diffTime then
    self.bt = self.body_temp_final_val
  else
    local diffBt = self.body_temp_final_val - self.bt
    self.bt = self.bt + diffBt / diffTime * deltaTime
  end
  local BtJustReachFinalValue = previousBt ~= self.bt and self.bt == self.body_temp_final_val
  if BtJustReachFinalValue then
    self:AddForceUpdateToken()
  end
  self:UpdateBodyTemp(self.bt, diffTime, self.body_temp_final_val)
  if self.bt == self.body_temp_final_val then
    self:UpdateBodyTempUI(self.bt)
  end
end

function TemperatureComponent:UpdateBodyTempUI(BodyTemp)
  local newState = TemperatureEnum.BodyState.NORMAL
  if BodyTemp >= TemperatureEnum.BT.MAX then
    newState = TemperatureEnum.BodyState.HOT
  elseif BodyTemp <= TemperatureEnum.BT.MIN then
    newState = TemperatureEnum.BodyState.COLD
  end
  self:ShowOrHideUiByState(self.curState, newState)
  self.curState = newState
end

function TemperatureComponent:ShowOrHideUiByState(curState, newState)
  if curState == newState then
    return
  end
  Log.Debug("State Changed", table.getKeyName(TemperatureEnum.BodyState, curState), table.getKeyName(TemperatureEnum.BodyState, newState))
  if _G.MainUIModuleCmd then
  end
end

function TemperatureComponent:GetTempC()
  return self.c
end

function TemperatureComponent:GetTempBt()
  return self.bt
end

function TemperatureComponent:OnReceiveServerData(temp)
  Log.Debug("TemperatureComponent:OnReceiveServerData", self.c, temp)
  self.c = temp
  self.owner:SetTemperature(temp)
end

function TemperatureComponent:OnFunctionStateChanged(newState, fuctionType)
  Log.Debug("TemperatureComponent:OnFunctionStateChanged", newState)
  self.isPaused = newState
end

function TemperatureComponent:OnReconnectFinish()
  self:AddForceUpdateToken()
end

function TemperatureComponent:AddForceUpdateToken()
  if self.isDebug then
    Log.Error("TemperatureComponent:AddForceUpdateToken", self.ForceUpdateToken)
  end
  self.ForceUpdateToken = self.ForceUpdateToken + 1
end

function TemperatureComponent:FlushUpdateToken(bJustQuery)
  local currentTokenNum = self.ForceUpdateToken
  if not bJustQuery then
    if self.isDebug and currentTokenNum > 0 then
      Log.Error("TemperatureComponent:FlushUpdateToken", currentTokenNum)
    end
    self.ForceUpdateToken = 0
  end
  return currentTokenNum > 0
end

return TemperatureComponent
