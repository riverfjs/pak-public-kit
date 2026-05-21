local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local DelaySafeCaller = require("NewRoco.Modules.Core.Battle.Common.DelaySafeCaller")
local BattleTimeoutCounter = require("NewRoco.Modules.Core.Battle.Common.BattleTimeoutCounter")
local Base = FsmAction
local BattleActionBase = Base:Extend("BattleActionBase")
BattleActionBase.DefaultTimeoutValue = 10000
BattleActionBase.PrepareResTimeoutValue = 5000
BattleActionBase.AnimTimeoutValue = 20000
BattleActionBase.PlayerSelectTime = 60000
BattleActionBase.WaitOtherTime = 9999999
BattleActionBase.MaxTimeoutValue = 9999999999
BattleActionBase.PerformTimeoutValue = 400
BattleActionBase.SkipPerformProgressThreshold = 0.8
BattleActionBase.PerformAITimeoutValue = 200
BattleActionBase.ActionType = {
  BaseAction = {
    name = "BaseAction",
    value = BattleActionBase.DefaultTimeoutValue,
    enableTimeout = true
  },
  ClientLoadResAction = {
    name = "ClientLoadResAction",
    value = BattleActionBase.PrepareResTimeoutValue,
    enableTimeout = true
  },
  ClientSkipableAction = {
    name = "ClientSkipableAction",
    value = BattleActionBase.DefaultTimeoutValue,
    enableTimeout = true
  },
  ClientUnSkipableAction = {
    name = "ClientUnSkipableAction",
    value = BattleActionBase.MaxTimeoutValue,
    enableTimeout = false
  },
  ClientAnimAction = {
    name = "ClientAnimAction",
    value = BattleActionBase.AnimTimeoutValue,
    enableTimeout = false
  },
  ClientSeqAction = {
    name = "ClientSeqAction",
    value = BattleActionBase.MaxTimeoutValue,
    enableTimeout = false
  },
  ClientTurnPlayAction = {
    name = "ClientTurnPlayAction",
    value = BattleActionBase.MaxTimeoutValue,
    enableTimeout = false
  },
  ClientPlayerSelectAction = {
    name = "ClientPlayerSelectAction",
    value = BattleActionBase.MaxTimeoutValue,
    enableTimeout = false
  },
  ClientLimmitedPlayerSelectAction = {
    name = "ClientPlayerSelectAction",
    value = BattleActionBase.PlayerSelectTime,
    enableTimeout = true
  },
  ServerReqAction = {
    name = "ServerReqAction",
    value = BattleActionBase.DefaultTimeoutValue,
    enableTimeout = true
  },
  ServerWaitingAction = {
    name = "ServerWaitingAction",
    value = BattleActionBase.DefaultTimeoutValue,
    enableTimeout = true
  },
  WatingOtherPlayerSelectAction = {
    name = "WatingOtherPlayerSelectAction",
    value = BattleActionBase.WaitOtherTime,
    enableTimeout = false
  }
}
FsmUtils.MergeMembers(Base, BattleActionBase, {})

function BattleActionBase:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.delaySafeCaller = DelaySafeCaller()
  self.desiredJumpEvent = nil
  self.enterTime = nil
  self.finishTime = nil
  self.useTimecounter = true
  if self.useTimecounter then
    self.timeoutCounter = BattleTimeoutCounter.Get(name)
    self.timeoutCounter:Start(self.timeoutValue, self, self.OnTimeoutHandle, self.OnTimeoutHandle)
  end
  self.timeout = BattleActionBase.MaxTimeoutValue
  self.totalBackgroundTime = 0
  self.enterBackgroundTime = 0
  self.isActionInForeground = false
  self:SetActionType(BattleActionBase.ActionType.ClientSkipableAction)
  self.originSafeExitFunc = self.SafeExit
  self.isTimeout = false
end

function BattleActionBase:DoEnter()
  self.delaySafeCaller:Reuse()
  if self:IsResetBattleFieldActionType(self.actionType) then
    self.SafeExit = self.SafeExitUnSkipable
  end
  Log.Debug("[Battle]", self.name, "DoEnter::", self:GetActionTypeName())
  self.isTimeout = false
  self.enterTime = os.msTime()
  self.totalBackgroundTime = 0
  self.isActionInForeground = true
  if not self.useTimecounter then
    NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnApplicationWillEnterBackground)
    NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnApplicationHasEnteredForeground)
  end
  self:SafeCall(Base.DoEnter, "DoEnter")
end

function BattleActionBase:OnApplicationWillEnterBackground()
  self.enterBackgroundTime = os.msTime()
  self.isActionInForeground = false
  Log.Info("BattleActionBase:OnApplicationWillEnterBackground", self.name, self.enterBackgroundTime, self.isActionInForeground)
end

function BattleActionBase:OnApplicationHasEnteredForeground()
  self.enterForegroundTime = os.msTime()
  local deltaBackgroundTime = self.enterForegroundTime - self.enterBackgroundTime
  self.totalBackgroundTime = self.totalBackgroundTime + deltaBackgroundTime
  self.isActionInForeground = true
  Log.Info("BattleActionBase:OnApplicationHasEnteredForeground", self.name, self.enterBackgroundTime, self.enterForegroundTime, deltaBackgroundTime, self.totalBackgroundTime, self.isActionInForeground)
end

function BattleActionBase:DoExit()
  self.delaySafeCaller:Reset()
  self:SafeCall(Base.DoExit, "DoExit")
  if not self.useTimecounter then
    NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnApplicationWillEnterBackground)
    NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnApplicationHasEnteredForeground)
  else
    self:ReleaseTimeoutCounter()
  end
end

function BattleActionBase:Finish()
  self.delaySafeCaller:Reset()
  self.finishTime = os.msTime()
  self.isActionInForeground = false
  self:ReleaseTimeoutCounter()
  Base.Finish(self)
end

function BattleActionBase:ReleaseTimeoutCounter()
  if self.useTimecounter and self.timeoutCounter then
    self.timeoutCounter:Stop()
    self.timeoutCounter = nil
  end
end

function BattleActionBase:DoFinalize()
  self.delaySafeCaller:Reset()
  self:SafeCall(Base.DoFinalize, "DoFinalize")
end

function BattleActionBase:LaunchAsyncTask(callback)
  if type(callback) ~= "function" then
    function callback()
    end
  end
  au.LaunchWithTimeout(a.sync(self.AsyncTask)(self), self:GetTimeoutValue() / 1000, function(noUncheckedError, msgOrResult)
    if noUncheckedError then
      Log.Debug(string.format("%s:LaunchAsyncTask completed", self.name))
      callback(noUncheckedError, msgOrResult)
    else
      local errorMessage = msgOrResult
      Log.Error(self.name, errorMessage)
      self:SafeExit()
      BattleReplayCachePool:UploadBattleDataTOCrashSight(string.format("%s:%s", self.name, errorMessage))
    end
  end)
end

function BattleActionBase:LaunchAsyncTaskAndFinish()
  au.LaunchWithTimeout(a.sync(self.AsyncTask)(self), self:GetTimeoutValue() / 1000, function(noUncheckedError, msgOrResult)
    if noUncheckedError then
      Log.Debug(string.format("%s:LaunchAsyncTask completed", self.name))
      self:Finish()
    else
      local errorMessage = msgOrResult
      Log.Error(self.name, errorMessage)
      self:SafeExit()
      BattleReplayCachePool:UploadBattleDataTOCrashSight(string.format("%s:%s", self.name, errorMessage))
    end
  end)
end

function BattleActionBase:LaunchAsyncTaskAndDoNext(callback, caller)
  au.LaunchWithTimeout(a.sync(self.AsyncTask)(self), self:GetTimeoutValue() / 1000, function(noUncheckedError, msgOrResult)
    if noUncheckedError then
      Log.Debug(string.format("%s:LaunchAsyncTask completed", self.name))
      callback(caller)
    else
      local errorMessage = msgOrResult
      Log.Error(self.name, errorMessage)
      self:SafeExit()
      BattleReplayCachePool:UploadBattleDataTOCrashSight(string.format("%s:%s", self.name, errorMessage))
    end
  end)
end

function BattleActionBase:AsyncTask()
end

function BattleActionBase:SetActionType(t)
  if t and BattleActionBase.ActionType[t.name] then
    self.actionType = t
    self:SetTimeoutValueByActionType()
    if not t.enableTimeout then
      self.timeoutCounter:Stop()
    else
    end
  else
    Log.Error("BattleActionBase SetActionType:invalid type!", t and t.name or "UnknowType")
  end
end

function BattleActionBase:SafeExit()
  self:Finish()
end

function BattleActionBase:SafeExitUnSkipable()
  self:TryResetBattleField()
  self.isTimeout = false
end

function BattleActionBase:SetTimeoutValue(value)
  self.timeoutValue = value
  Log.Debug("[Battle]SetTimeoutValue:", self.timeoutValue, self.name)
end

function BattleActionBase:SetTimeoutValueBySkillObj(SkillObject)
  if not SkillObject then
    Log.Error("BattleActionBase SetTimeoutValueBySkillObj SkillObject is nil")
    return
  end
  self.timeoutValue = SkillObject:GetLength() + 3
  Log.Debug("SetTimeoutValue:", self.timeoutValue, self.name)
end

function BattleActionBase:SetTimeoutValueByActionType()
  if self.actionType then
    self.timeoutValue = self.actionType.value
    if RocoEnv.IS_EDITOR and self.actionType.name == BattleActionBase.ActionType.ClientLoadResAction.name then
      self.timeoutValue = self.timeoutValue * 20
    end
    if self.useTimecounter then
      self.timeoutCounter:ResetTimeoutValue(self.timeoutValue)
    end
    self.timeout = BattleActionBase.MaxTimeoutValue
  else
    Log.Error("BattleActionBase SetTimeoutValueByActionType timeoutValue is nil")
  end
end

function BattleActionBase:GetTimeoutValue()
  if self.timeoutValue == nil then
    self:SetTimeoutValueByActionType()
  end
  return self.timeoutValue
end

function BattleActionBase:GetActionTypeName()
  if self.actionType then
    return self.actionType.name
  end
  return "Unknow"
end

function BattleActionBase:IsResetBattleFieldActionType(actionType)
  if actionType == BattleActionBase.ActionType.ClientUnSkipableAction or self.actionType == BattleActionBase.ActionType.ClientPlayerSelectAction or self.actionType == BattleActionBase.ActionType.ServerWaitingAction then
    return true
  end
  return false
end

function BattleActionBase:TryResetBattleField()
  Log.Warning("[Battle]", self.name, "\230\173\163\229\156\168\232\167\166\229\143\145\229\174\137\229\133\168\233\135\141\231\189\174\230\136\152\229\156\186\233\128\187\232\190\145")
  _G.ZoneServer:DisConnect(true, true)
  self.isTimeout = false
end

function BattleActionBase:ReportError(title, content, btnOk, btnCancle, mode, callback, debugInfo)
  Log.Debug("[Battle][BattleActionBase] ReportError", title, content, btnOk, btnCancle, mode, callback, debugInfo)
  local Ctx = DialogContext()
  Ctx:SetTitle(title):SetContent(content):SetMode(mode):SetCallback(self, callback):SetCloseOnCancel(true):SetButtonText(btnOk, btnCancle):SetDebugInfo(debugInfo)
  Log.Debug("[Battle][BattleActionBase] Ctx", Ctx.content)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function BattleActionBase:IsTimeout()
  if RocoEnv.IS_EDITOR then
    return false
  end
  if self.useTimecounter then
    return self.timeoutCounter:IsTimeout()
  else
    local costTime = os.msTime() - self.enterTime
    if costTime > self:GetTimeoutValue() + self.totalBackgroundTime then
      Log.Warning("[Battle]BattleActionBase IsTimeout:", self.name, os.msTime(), self.enterTime, os.msTime() - self.enterTime, costTime, self.totalBackgroundTime)
      return true
    end
  end
  return false
end

local function LoadResAsyncTask(resPath, callback)
  _G.BattleResourceManager:LoadResAsync(nil, resPath, function(caller, resource)
    callback(true, resource)
  end, function(caller, request, errorMessage)
    callback(false, errorMessage)
  end, nil, nil, nil, PriorityEnum.Passive_Battle_NPC)
end

BattleActionBase.LoadResAsyncTask = a.wrap(LoadResAsyncTask)

function BattleActionBase:OnTimeoutHandle()
  self:TriggerTimeoutExit()
end

function BattleActionBase:OnTick(DeltaTime)
  if not self.useTimecounter and self.isActionInForeground and not self.isTimeout and self:IsTimeout() then
    self:TriggerTimeoutExit()
  end
end

function BattleActionBase:TriggerTimeoutExit()
  if RocoEnv.IS_EDITOR then
    Log.Error("[Battle]\230\179\168\230\132\143\239\188\154", self.name, "\229\155\160\228\184\186\232\182\133\230\151\182\232\162\171\229\188\186\229\136\182\233\128\128\229\135\186")
  else
    Log.Warning("[Battle]\230\179\168\230\132\143\239\188\154", self.name, "\229\155\160\228\184\186\232\182\133\230\151\182\232\162\171\229\188\186\229\136\182\233\128\128\229\135\186")
  end
  self:SafeExit()
  self.isTimeout = true
end

function BattleActionBase:SafeCall(func, tips)
  local _, err, _ = tcallForBattle(nil, func, self)
  if err then
    local errorMsg = string.format("\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\140%s %s\229\155\160\228\184\186\230\138\165\233\148\153\229\183\178\231\187\143\232\162\171\232\183\179\232\191\135\232\161\168\230\188\148\239\188\129 ErrorInfo:%s", self.name, tips, err)
    Log.Warning(errorMsg)
    self:SafeExit()
    BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
  end
end

function BattleActionBase:SafeDelaySeconds(idName, ...)
  self.delaySafeCaller:SafeDelaySeconds(idName, ...)
end

function BattleActionBase:SafeDelayFrames(idName, ...)
  self.delaySafeCaller:SafeDelayFrames(idName, ...)
end

function BattleActionBase:SafeCancelDelayById(idName)
  self.delaySafeCaller:SafeCancelDelayById(idName)
end

function BattleActionBase:SafeFindDelayById(idName)
  return self.delaySafeCaller:SafeFindDelayById(idName)
end

function BattleActionBase:CheckIsAsync()
  return self:GetProperty("IsAsync")
end

return BattleActionBase
