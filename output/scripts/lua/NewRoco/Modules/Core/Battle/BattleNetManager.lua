local Singleton = _G.Singleton
local EventDispatcher = require("Common.EventDispatcher")
local ProtoCMD = require("Data.PB.ProtoCMD")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleModuleData = require("NewRoco.Modules.Core.Battle.BattleModuleData")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger")
local Base = Singleton
local BattleNetManager = Singleton:Extend("BattleNetManager")

function BattleNetManager:Ctor(name)
  Log.Debug("BattleNetManager:Ctor")
  self.name = name or "BattleNetManager"
  Base.Ctor(self, self.name)
  EventDispatcher():Attach(self)
  self.canHandleCache = false
  self.timeInterval = 0.04
  self.MainControlTimer = nil
  self.cachedBattleNotify = nil
  self.isStopHandle = false
  self.isInit = false
  self.wl_req_id = 0
  self.max_err_req_id = 0
end

function BattleNetManager:GetNotifyCache()
  local tempCachedBattleNotify = DataModelMgr.LoginNotifyModel:GetCache("Battle") or {}
  Log.Debug("BattleNetManager GetNotifyCache:", #self.cachedBattleNotify, table.tostring(self.cachedBattleNotify))
  for i = 1, #tempCachedBattleNotify do
    local item = tempCachedBattleNotify[i]
    self:CacheNotify(item.notifyCmdId, item.notify)
  end
end

function BattleNetManager:Init()
  self.isInit = true
  self.isStopHandle = false
  self.battleServer = _G.ZoneServer
  self:UnRegistBattleNotify()
  self:RegistBattleNotify()
  self:GetNotifyCache()
end

function BattleNetManager:Clear()
  self.isStopHandle = false
end

function BattleNetManager:ShutDown()
  self.isInit = false
  self:UnRegistBattleNotify()
  self.MainControlTimer = nil
  self.cachedBattleNotify = {}
  self.cmdHandlerDict = {}
  self.canHandleCache = false
end

function BattleNetManager:Free()
  Base.Free(self)
  self:UnRegistBattleNotify()
  self:RemoveAllListeners()
end

function BattleNetManager:AddNotifyListener(cmdID, callbackFunc)
  self.battleServer:AddProtocolListener(self, cmdID, callbackFunc)
end

function BattleNetManager:RegistBattleNotify()
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MATCH_NOTIFY, self.MatchNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PK_INFO_NOTIFY, self.OpenPVP_PreparePanel)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY, self.ZoneBattleEnterNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY, self.ZoneBattlePrePlayNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_NOTIFY, self.BattleLoadFinishNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY, self.ZoneBattleRoundStartNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY, self.ZoneBattleCmdSyncNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY, self.ZoneBattleInstantPerformNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY, self.ZoneBattlePerformStartNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CHANGE_AUTO_CMD_NOTIFY, self.BattleChangeAutoCmdNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY, self.BattlePlayerLeaveNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY, self.ZoneBattleFinishNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FORCE_FINISH_NOTIFY, self.ZoneBattleForceFinishNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_AI_SELECT_SKILL_NOTIFY, self.ZoneBattleAiSelectSkillNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_EMOJI_NOTIFY, self.ZoneBattleEmojiNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PK_AGAIN_NOTIFY, self.ZoneBattlePkAgainNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PVP_PERFORM_START_NOTIFY, self.ZoneBattlePvpPerformStartNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_CHANGE_NOTIFY, self.ZoneBattleObserverChangeNotify)
  self:AddNotifyListener(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_KICKED_OUT_NOTIFY, self.ZoneBattleObserverKickedOutNotify)
  NRCEventCenter:RegisterEvent("BattleNetManager", self, _G.NRCGlobalEvent.ON_LOGIN, self.OnReciviceLogin)
end

function BattleNetManager:UnRegistBattleNotify()
  if not self.isInit then
    return
  end
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MATCH_NOTIFY, self.MatchNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PK_INFO_NOTIFY, self.OpenPVP_PreparePanel)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY, self.ZoneBattleEnterNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY, self.ZoneBattlePrePlayNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_NOTIFY, self.BattleLoadFinishNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY, self.ZoneBattleRoundStartNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY, self.ZoneBattleCmdSyncNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY, self.ZoneBattleInstantPerformNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY, self.ZoneBattlePerformStartNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CHANGE_AUTO_CMD_NOTIFY, self.BattleChangeAutoCmdNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY, self.BattlePlayerLeaveNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY, self.ZoneBattleFinishNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FORCE_FINISH_NOTIFY, self.ZoneBattleForceFinishNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_AI_SELECT_SKILL_NOTIFY, self.ZoneBattleAiSelectSkillNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_EMOJI_NOTIFY, self.ZoneBattleEmojiNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PK_AGAIN_NOTIFY, self.ZoneBattlePkAgainNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PVP_PERFORM_START_NOTIFY, self.ZoneBattlePvpPerformStartNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_CHANGE_NOTIFY, self.ZoneBattleObserverChangeNotify)
  self.battleServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_KICKED_OUT_NOTIFY, self.ZoneBattleObserverKickedOutNotify)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_LOGIN, self.OnReciviceLogin)
end

function BattleNetManager:OnReciviceLogin(isRelogin)
end

function BattleNetManager:SendBattleLoadFinishReq(req, caller, rspHandler)
  local pos_info, battle_center, battle_radius = BattleManager.battleRuntimeData:ConstructSendFlowFinishData()
  local validObserverPointIndexList = BattleManager.battleRuntimeData:GetValidObserverPointIndexList()
  req.pos_info = pos_info
  req.battle_center = battle_center
  req.battle_radius = battle_radius
  req.observe_available_pos = validObserverPointIndexList
  if rspHandler then
    self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_REQ, req, caller, rspHandler, true, true)
  else
    self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_REQ, req)
  end
end

function BattleNetManager:BuildBattleCmdPushbackReq()
  local req = _G.ProtoMessage:newZoneBattleCmdPushbackReq()
  self.wl_req_id = self.wl_req_id + 1
  req.wl_req_id = self.wl_req_id
  req.max_err_req_id = self.max_err_req_id
  req.feature_data = _G.NRCSDKManager:GetLightFeaturePacket()
  Log.Debug("BattleNetManager:BuildBattleCmdPushbackReq:", req.wl_req_id, req.max_err_req_id)
  return req
end

function BattleNetManager:GetWlReqID()
  return self.wl_req_id
end

function BattleNetManager:SendBattleCmdPushbackReq(req, caller, rspHandler)
  local function LocalRspHandler(t, rsp)
    if rsp.max_err_req_id and self.max_err_req_id < rsp.max_err_req_id then
      self.max_err_req_id = rsp.max_err_req_id
    end
    if rsp.ret_info.ret_code == 30001 or rsp.ret_info.ret_code == 2112 then
    else
      rspHandler(t, rsp)
    end
  end
  
  return self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_PUSHBACK_REQ, req, caller, LocalRspHandler)
end

function BattleNetManager:SendBattleNpcEscapeConfirmReq(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_NPC_ESCAPE_CONFIRM_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendBattleCmdPopbackReq(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_POPBACK_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendBattleRoundFlowFinishReq(seqNumber, state)
  Log.Debug("Round perform finished...")
  self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_FLOW_FINISH_REQ, self:CreateBattleRoundFlowFinishReq(seqNumber, state))
end

function BattleNetManager:CreateBattleRoundFlowFinishReq(seqNumber, state)
  Log.Debug("ZoneBattleRoundFlowFinishReq SendBattleRoundFlowFinishReq")
  local req = _G.ProtoMessage:newZoneBattleRoundFlowFinishReq()
  local pos_info, battle_center, battle_radius = BattleManager.battleRuntimeData:ConstructSendFlowFinishData()
  req.pos_info = pos_info
  req.battle_center.x = battle_center.x
  req.battle_center.y = battle_center.y
  req.battle_center.z = battle_center.z
  req.battle_radius = battle_radius
  req.state = state or ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_NULL
  req.seq_num = tonumber(seqNumber) or 0
  return req
end

function BattleNetManager:SendBattleSupplyPetReq(req)
  self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_SUPPLY_PET_REQ, req)
end

function BattleNetManager:SendBattleSupplyPetReqWithHandle(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_SUPPLY_PET_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendEscapeReq(runAwayType)
  local req = _G.ProtoMessage:newZoneBattlePlayerRunawayReq()
  req.runaway_type = runAwayType or 0
  return self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PLAYER_RUNAWAY_REQ, req)
end

function BattleNetManager:SendEscapeReqWithHandle(caller, rspHandler, runAwayType)
  local req = _G.ProtoMessage:newZoneBattlePlayerRunawayReq()
  req.runaway_type = runAwayType or 0
  return self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PLAYER_RUNAWAY_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendBattleChangeAutoCmdReq(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CHANGE_AUTO_CMD_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendBattlePlayerExitReq()
  local req = _G.ProtoMessage:newZoneBattlePlayerExitReq()
  req.battle_id = _G.BattleManager.battleRuntimeData:GetBattleID()
  self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PLAYER_EXIT_REQ, req)
end

function BattleNetManager:SendCatchPet(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CATCH_MONSTER_REQ, req, caller, rspHandler)
end

function BattleNetManager:SendBattleShowEmo(req, caller, rspHandler)
  self.battleServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_EMOJI_REQ, req, caller, rspHandler)
end

function BattleNetManager:MatchNotify(notify)
  if _G.BattleManager.isInBattle then
    return
  end
  if BattleUtils.HasBattleLoading() then
    return
  end
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ReceiveStartMatch, notify)
end

function BattleNetManager:ZoneBattleEnterNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattleEnterNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY, notify)
  _G.BattleEventCenter:Dispatch(BattleEvent.ON_RECEIVE_BATTLE_ENTER)
end

function BattleNetManager:ZoneBattlePrePlayNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattlePrePlayNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY, notify)
end

function BattleNetManager:BattleLoadFinishNotify(notify)
  Log.Trace("BattleNetManager:BattleLoadFinishNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleRoundStartNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattleRoundStartNotify")
  if BattleUtils.CheckCmdNeedPerform(notify) then
    local performNotify = _G.ProtoMessage:newZoneBattlePerformStartNotify()
    performNotify.perform_cmd = notify.perform_cmd or {}
    performNotify.ret_info = notify.ret_info
    performNotify.perform_cmd.IsFromRoundStart = true
    notify.perform_cmd = {
      seq_num = performNotify.perform_cmd.seq_num
    }
    self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY, performNotify)
  end
  if notify and notify.state_info.round > 1 then
    self:SetIsJumpAiPerform()
  end
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY, notify)
end

function BattleNetManager:SetIsJumpAiPerform()
  if not _G.BattleManager.stateFsm then
    return
  end
  local activeStateName = _G.BattleManager.stateFsm:GetActiveStateName()
  local needJump = activeStateName == BattleEnum.StateNames.RoundPlay or activeStateName == BattleEnum.StateNames.PrePlay
  if needJump then
    _G.BattleManager.battleRuntimeData:SetIsJumpAiPerform(true)
    _G.BattleEventCenter:Dispatch(BattleEvent.WAIT_PERFORM_END)
  end
end

function BattleNetManager:ZoneBattleCmdSyncNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleCmdSyncNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleInstantPerformNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattleInstantPerformNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY, notify)
end

function BattleNetManager:ZoneBattlePerformStartNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattlePerformStartNotify")
  if notify then
    local currentRound = _G.BattleManager:GetCurRound()
    if currentRound < notify.perform_cmd.round then
      self:SetIsJumpAiPerform()
    end
  end
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY, notify)
end

function BattleNetManager:ZoneBattlePvpPerformStartNotify(notify)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(notify)
  Log.Trace("BattleNetManager:ZoneBattlePvpPerformStartNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PVP_PERFORM_START_NOTIFY, notify)
end

function BattleNetManager:BattleChangeAutoCmdNotify(notify)
  Log.Trace("BattleNetManager:BattleChangeAutoCmdNotify")
end

function BattleNetManager:BattlePlayerLeaveNotify(notify)
  Log.Trace("BattleNetManager:BattlePlayerLeaveNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleForceFinishNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleForceFinishNotify")
  if _G.BattleManager and (_G.BattleManager.isInBattle or _G.BattleManager.stateFsm) then
    _G.ZoneServer:Pause("Battle")
    _G.BattleManager.IsReadyForExit = true
    if not self:IsInDestroyProcessNext(_G.BattleManager.stateFsm) then
      self:SendEvent(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FORCE_FINISH_NOTIFY, notify)
    else
      self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FORCE_FINISH_NOTIFY, notify)
    end
  end
end

function BattleNetManager:ZoneBattleFinishNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleFinishNotify")
  if _G.BattleManager and _G.BattleManager.isInBattle then
    _G.BattleManager.IsReadyForExit = true
  end
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleAiSelectSkillNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleAiSelectSkillNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_AI_SELECT_SKILL_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleEmojiNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleAiSelectSkillNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_EMOJI_NOTIFY, notify)
end

function BattleNetManager:ZoneBattlePkAgainNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleAiSelectSkillNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PK_AGAIN_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleObserverChangeNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleObserverChangeNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_CHANGE_NOTIFY, notify)
end

function BattleNetManager:ZoneBattleObserverKickedOutNotify(notify)
  Log.Trace("BattleNetManager:ZoneBattleObserverKickedOutNotify")
  self:CacheNotify(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_KICKED_OUT_NOTIFY, notify)
end

function BattleNetManager:RefreshReceiveSeqNum(notify)
  if not notify then
    return
  end
  if notify.seq_num then
    BattleManager:SetReceiveSeqNumber(notify.seq_num)
    return
  end
  if notify.perform_cmd and notify.perform_cmd.seq_num then
    BattleManager:SetReceiveSeqNumber(notify.perform_cmd.seq_num)
    return
  end
  if notify.data_seq_num then
    BattleManager:SetReceiveSeqNumber(notify.data_seq_num)
    return
  end
end

function BattleNetManager:CacheNotify(notifyCmdId, notify)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SaveBattleNotify, notifyCmdId)
  self:RefreshReceiveSeqNum(notify)
  Log.Debug("BattleNetManager CacheNotify:", ProtoCMD:GetMessageName(notifyCmdId))
  if notifyCmdId == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
    self:ClearCachedNotify()
  end
  local item = {}
  item.notifyCmdId = notifyCmdId
  item.notify = notify
  table.insert(self.cachedBattleNotify, item)
  if not RocoEnv.IS_SHIPPING then
    BattleReplayCachePool:Push(notifyCmdId, notify)
  end
  BattleReplayCachePool:RecordBattleOp(notifyCmdId, notify)
  Log.Debug("BattleNetManager:CacheNotify cmdID:", string.format("0x%x", notifyCmdId), ProtoCMD:GetMessageName(notifyCmdId))
  if self.MainControlTimer == nil then
    self.MainControlTimer = _G.TimerManager:CreateTimer(self, "MainControlTimer", math.huge, self.ProcessMainProcess, nil, self.timeInterval)
  else
    self.MainControlTimer:Restart()
  end
end

function BattleNetManager:StartHandleCache()
  self.canHandleCache = true
end

function BattleNetManager:ProcessMainProcess(...)
  if not self.canHandleCache then
    Log.Debug("BattleNetManager ProcessMainProcess fail")
    return
  end
  if 0 == #self.cachedBattleNotify then
    Log.Debug("BattleNetManager ProcessMainProcess stop")
    self.MainControlTimer:Stop()
    return
  end
  local module = BattleUtils.GetSceneModule()
  if not module then
    return
  end
  local mapID = module:GetCurrentMapId()
  if nil == mapID or 0 == mapID then
    return
  end
  local fsm = _G.BattleManager.stateFsm
  if fsm and self:IsInDestroyProcessNext(fsm) then
    Log.Warning("BattleNetManager ProcessMainProcess do BattleManager is destroy")
    return
  end
  if BattleUtils.HasFastLoading() then
    return
  end
  if not BattleUtils.IsBattleFieldLevelReady() then
    Log.Warning("BattleNetManager battlefield level is not ready, try to reload...")
    local battleModule = NRCModuleManager:GetModule("BattleModule")
    if battleModule and battleModule.data and battleModule.data.battleFieldLevelLoadingState == BattleModuleData.BattleFieldLoadingState.ERROR then
      _G.NRCModuleManager:DoCmd(BattleModuleCmd.LoadBattleFieldLevel, function(ok, errorMessage)
        if not ok then
          Log.Error("BattleNetManager failed to load battle field level:", errorMessage)
        end
      end)
    end
    return
  end
  if BattleUtils.HasBattleLoading() and BattleUtils.CheckIsBlockNotifyWhenLoading(self.cachedBattleNotify[1].notifyCmdId) and not BattleUtils.IsSpecialDelayPve() then
    return
  end
  self:ExecuteCachedNotify()
end

function BattleNetManager:ClearCachedNotify()
  self.cachedBattleNotify = {}
end

function BattleNetManager:RemoveNotifyByCMD(removeInfo)
  if not removeInfo or 0 == #removeInfo then
    return
  end
  if 0 == #self.cachedBattleNotify then
    return
  end
  for k, ri in ipairs(removeInfo) do
    local cmd = ri[1]
    if cmd then
      local hasKeep = false
      for i = #self.cachedBattleNotify, 1, -1 do
        local notify = self.cachedBattleNotify[i]
        local checkRemove = true
        if ri[3] then
          checkRemove = ri[3](notify)
        end
        if cmd == notify.notifyCmdId and checkRemove then
          if ri[2] and not hasKeep then
            hasKeep = true
          else
            table.remove(self.cachedBattleNotify, i)
          end
        end
      end
    end
  end
end

function BattleNetManager:IsValid(info)
  return info and 0 ~= info.battle_id
end

function BattleNetManager:StopHandleNotify(reason)
  self.isStopHandle = true
  Log.Warning("BattleNetManager.StopHandleNotify  reason is ", reason)
end

function BattleNetManager:StartHandleNotify(reason)
  self.isStopHandle = false
  Log.Warning("BattleNetManager.StartHandleNotify  reason is ", reason)
end

function BattleNetManager:ExecuteCachedNotify()
  if self.isStopHandle then
    return
  end
  local currentNotify = self.cachedBattleNotify[1]
  local keyStr = currentNotify.notifyCmdId
  local fsm = _G.BattleManager.stateFsm
  if keyStr == _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
    self:HandleBattleEnterNotify(currentNotify.notify)
    return
  elseif keyStr == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MATCH_NOTIFY then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ReceiveStartMatch, currentNotify.notify)
  else
    if not fsm then
      BattleManager:ResetBattleState(currentNotify)
      self:ClearCachedNotify()
      self:SendEscapeReq(BattleEnum.RunAwayType.NoFsm)
      return
    end
    if not self:IsReadyToProcessNext(fsm) then
      Log.DebugFormat("Battle not ready, will wait... ")
      return
    end
  end
  local msg = currentNotify.notify
  table.remove(self.cachedBattleNotify, 1)
  Log.Debug("BattleStreamLog Sending BattleNetManagerEvent", keyStr)
  self:SendEvent(keyStr, msg)
end

function BattleNetManager:HandleBattleEnterNotify(notify)
  local fsm = _G.BattleManager.stateFsm
  local newInfo = notify.init_info
  local keyStr = ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY
  _G.BattleManager.battleRuntimeData.finalBattleData = notify.init_info.final_battle
  if not fsm then
    if self:IsValid(newInfo) then
      table.remove(self.cachedBattleNotify, 1)
      self:SendEvent(keyStr, notify)
    else
      table.remove(self.cachedBattleNotify, 1)
    end
    return
  end
  local oldInfo = BattleUtils.GetBattleInitInfo()
  if self:IsValid(oldInfo) and self:IsValid(newInfo) and tonumber(oldInfo.battle_id) == tonumber(newInfo.battle_id) then
    if not (BattleManager:CheckSeqNumber(notify.data_seq_num) and not (BattleManager.serverRound < notify.round) and BattleUtils.CheckBattleFieldState(newInfo)) or _G.BattleManager.stateFsm:GetActiveStateName() == BattleEnum.StateNames.FinalBattleToP2 then
      if self:IsReadyToProcessNext(fsm) then
        table.remove(self.cachedBattleNotify, 1)
        _G.BattleManager:SetSeqNumber(notify.data_seq_num)
        _G.BattleManager.battleInfoManager:Clear()
        _G.BattleManager.battleRuntimeData.battleType = notify.battle_mode
        _G.BattleManager.battleRuntimeData:SetBattleInitInfo(notify)
        _G.BattleManager:SetPotentialTaskID(notify)
        fsm:SendEvent(BattleEvent.EnterRebuildBattleField)
      end
      return
    else
      local shouldSkip = false
      local activeStateName = fsm:GetActiveStateName()
      local nextState = fsm:GetNextStateName()
      if not table.contains(BattleEnum.WaitStates, activeStateName) and not table.contains(BattleEnum.WaitStates, nextState) then
        Log.Debug("already in battle, skip...", fsm:GetActiveStateName(), newInfo.battle_state)
        shouldSkip = true
      end
      if newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_PLAY then
        table.remove(self.cachedBattleNotify, 1)
        local seqNumber = BattleUtils.GetServerWaitRoundSeqByNotify(BattleManager.battlePawnManager.TeamatePlayer, notify)
        self:SendBattleRoundFlowFinishReq(seqNumber, newInfo.battle_state)
        Log.Debug("ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_PLAY")
      elseif newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_PRE_PLAY then
        table.remove(self.cachedBattleNotify, 1)
        if not shouldSkip then
          local seqNumber = BattleUtils.GetServerWaitRoundSeqByNotify(BattleManager.battlePawnManager.TeamatePlayer, notify)
          self:SendBattleRoundFlowFinishReq(seqNumber, newInfo.battle_state)
          Log.Debug("ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_PRE_PLAY")
        end
      elseif newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_MONSTER_EX_MOVE then
        table.remove(self.cachedBattleNotify, 1)
        if not shouldSkip then
          local seqNumber = BattleUtils.GetServerWaitRoundSeqByNotify(BattleManager.battlePawnManager.TeamatePlayer, notify)
          self:SendBattleRoundFlowFinishReq(seqNumber, newInfo.battle_state)
          Log.Debug("ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_MONSTER_EX_MOVE")
        end
      elseif newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_WAIT_LOAD then
        table.remove(self.cachedBattleNotify, 1)
        if not shouldSkip then
          self:SendBattleLoadFinishReq(ProtoMessage:newZoneBattleLoadFinishReq())
        end
      elseif newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_NPC_AI then
        table.remove(self.cachedBattleNotify, 1)
        if not shouldSkip then
          self:SendBattleLoadFinishReq(ProtoMessage:newZoneBattleLoadFinishReq())
        end
      elseif newInfo.battle_state == ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_ROUND_SELECT_PET then
        table.remove(self.cachedBattleNotify, 1)
        if not shouldSkip then
          BattleUtils.ShowPvpWaitSupplyPetTips()
        end
      else
        local RoundStartNotify = BattleUtils.GenerateRoundStartNotify(notify)
        if RoundStartNotify then
          _G.BattleEventCenter:Dispatch(BattleEvent.ReconnetBattle_RoundStrart)
          Log.Debug("Fake round start notify")
          _G.BattleManager.battleInfoManager:Clear()
          table.remove(self.cachedBattleNotify, 1)
          self:ZoneBattleRoundStartNotify(RoundStartNotify)
        elseif shouldSkip then
          table.remove(self.cachedBattleNotify, 1)
        else
          Log.Error("zgx \230\150\173\231\186\191\233\135\141\232\191\158\229\143\145\231\148\159\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129\239\188\129state \228\184\186", newInfo.battle_state)
          table.remove(self.cachedBattleNotify, 1)
          _G.BattleManager.battleInfoManager:Clear()
          _G.BattleManager.battleRuntimeData:SetBattleInitInfo(notify)
          _G.BattleManager:SetPotentialTaskID(notify)
          fsm:SendEvent(BattleEvent.EnterRebuildBattleField)
        end
      end
    end
  else
    Log.Error("Quit old battle first")
    fsm:SendEvent(BattleEvent.EnterNormalOver)
  end
end

function BattleNetManager:IsReadyToProcessNext(fsm)
  local ready = false
  if fsm then
    local activeStateName = fsm:GetActiveStateName()
    local nextState = fsm:GetNextStateName()
    ready = not table.contains(BattleEnum.AtomicStates, activeStateName) and not table.contains(BattleEnum.AtomicStates, nextState)
  end
  return ready
end

function BattleNetManager:IsInDestroyProcessNext(fsm)
  local isDestroy = false
  if fsm then
    local activeStateName = fsm:GetActiveStateName()
    local nextState = fsm:GetNextStateName()
    isDestroy = table.contains(BattleEnum.DestroyStates, activeStateName) or table.contains(BattleEnum.DestroyStates, nextState)
  end
  return isDestroy
end

function BattleNetManager:__toString()
  return "BattleNetManager" .. tostring(self)
end

function BattleNetManager:SendStepAwayReq()
  local req = _G.ProtoMessage:newZoneBattleTempLeaveBeastReq()
  self.battleServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_TEMP_LEAVE_BEAST_REQ, req)
end

function BattleNetManager:OpenPVP_PreparePanel(notify)
  NRCModeManager:DoCmd(BattleUIModuleCmd.EnterPVP)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePvpHintPanel)
  local PVPPreparePanelState = NRCModuleManager:DoCmd(BattleUIModuleCmd.GetPVP_PreparePanelState)
  if false == PVPPreparePanelState and notify.pk_info.enemy then
    if 0 == notify.pk_info.pvp_id and self.PVPDelayData then
      self.PVPDelayData.Notify = notify
    else
      NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenPVP_PreparePanel, notify)
    end
  end
  if notify.pk_info.enemy_cancel then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.pvp_fight_exit_desc, nil, nil, 3)
  end
  if notify.pk_info.self_state == ProtoEnum.PlayerPkState.PPS_NONE then
    if 0 == notify.pk_info.pvp_id then
      self:ClearPVPDelay()
    end
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePVP_PreparePanel)
  end
end

function BattleNetManager:OpenPVP_PreparePanelByCache()
  if self.PVPDelayData then
    local Notify = self.PVPDelayData.Notify
    self:ClearPVPDelay()
    if Notify then
      self:OpenPVP_PreparePanel(Notify)
    end
  end
end

function BattleNetManager:DelayOpenPVP()
  self:ClearPVPDelay()
  self.PVPDelayData = {}
  self.PVPDelayData.TimerID = _G.DelayManager:DelaySeconds(15, self.OpenPVP_PreparePanelByCache, self)
end

function BattleNetManager:ClearPVPDelay()
  if self.PVPDelayData then
    _G.DelayManager:CancelDelayById(self.PVPDelayData.TimerID)
    self.PVPDelayData = nil
  end
end

return BattleNetManager
