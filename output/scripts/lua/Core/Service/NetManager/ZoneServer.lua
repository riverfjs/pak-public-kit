local Delegate = require("Utils.Delegate")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local ZoneServerGCloud = require("Core.Service.NetManager.ZoneServerGCloud")
local ZoneServerKickOut = require("Core.Service.NetManager.ZoneServerKickOut")
local ProtocolChecker = require("Core.Service.NetManager.ProtocolChecker")
local ProtocolStat = require("Core.Service.NetManager.ProtocolStat")
local LuaSerialize = require("serialize")
local Class = _G.MakeSimpleClass
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local PROTOCOL_TIMEOUT_TIME = 15000
local ENABLE_NORMAL_PROTOCOL_TIMEOUT = false
local GUARD_CHECK_INTERVAL = 3000
local ProtocolEvent = Class("ProtocolEvent")
ProtocolEvent:SetMemberCount(12)

function ProtocolEvent:PreCtor()
  self.seqID = 0
  self.reqCmdID = 0
  self.reqMsg = nil
  self.target = nil
  self.handler = nil
  self.bBlockCmd = false
  self.bIgnoreErrorTip = false
  self.sendTime = 0
  self.deltaTime = 0
  self.bWaitingUI = false
  self.bLog = false
  self.bDropByServer = false
  self.delayTimeOfWaitingUI = nil
end

local ZoneServer = _G.Singleton:Extend("ZoneServer")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")

function ZoneServer:Ctor()
  self.bInit = false
  self.connectID = 0
  self.connectType = UE4.ENetConnectType.TCP
  self.protocolEventDic = {}
  self.seqEventArray = {}
  self.bPause = false
  self.PauseReason = {}
  self.PostHandleDelegate = Delegate()
  self.IgnoreErrorCMDs = {
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SET_NPC_POS_RSP] = {50024, -1},
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_RSP] = {
      50104,
      50079,
      ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_CATCH_FORBID
    },
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CREATE_SCENE_PET_RSP] = {50104},
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_RSP] = {50104},
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPCS_INTERACT_RSP] = {50104},
    [ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP] = {
      ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ACTIVITY_NOT_FOUNT
    },
    [ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SYNC_PLAYER_STATUS_RSP] = {1083}
  }
  self.BlockCMD = {
    ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_EXCHANGE_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_BUY_GOODS_BY_MIDAS_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_QUERY_BALANCE_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_SHOP_BUY_ITEM_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_LIST_BY_PAGE_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_SHOP_EXCHANGE_REQ
  }
  self.SvrBlockCMD = {
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_BEAST_JOIN_VISIT_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_USE_BAG_ITEM_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_MAIL_GET_ATTACHMENT_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_CONFIRM_REVIVE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_TASK_STATE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_MATCH_START_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_CREATE_BATTLE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_TELEPORT_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_TELEPORT_TO_NPC_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_VISUAL_ITEM_UPGRADE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_CAMP_LEVEL_UP_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SUBMIT_PET_FROM_BACKPACK_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SHOP_BUY_ITEM_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_RECEIVE_OWL_REFUGE_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_GET_HANDBOOK_TOPIC_AWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_MIRACLE_CHANGE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_BATTLE_PASS_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_CREATE_SCENE_PET_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_REWARD_ADVENTURE_CHAPTER_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_COMPLETE_PET_TRAVEL_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_CATCH_BALL_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_BEAST_START_MATCH_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_PET_CATCH_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_DISPOSABLE_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_GET_PVP_RANK_WEEK_TASK_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_GET_PVP_RANK_SEASON_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_BATTLE_PASS_THEME_PK_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_GP_CONTEST_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_CONDITION_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_SHINY_PET_DAY_PETAL_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_SHINY_PET_DAY_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_TREASURE_HUNT_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_CHALLENGE_STAR_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_START_PET_TRAVEL_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SET_PLAYER_NAME_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_SAVE_ROOM_LAYOUT_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_QUERY_LEVEL_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_CLAIM_LEVEL_REWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_START_EXPAND_ROOM_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_FINISH_EXPAND_ROOM_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_RENAME_ROOM_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_ENTER_EDIT_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_ENTER_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_LEAVE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_GET_VIST_HISTORY_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_GET_VISITOR_INFO_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PLANT_SEED_COMPOUND_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PLANT_SEED_EQUIP_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_SCENE_HOME_PLANT_CROP_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_WAREHOUSE_DECOMPOSITION_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_WAREHOUSE_BUILD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_PLACE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_UNPLACE_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_LOAD_FOOD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_REPLACE_FOOD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_UNLOAD_FOOD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_FEED_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_FEED_CANCEL_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_STEAL_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_FETCH_AWARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_GUARD_REQ,
    ProtoEnum.ZoneSvrCmd.ZONE_HOME_PET_FOOD_COMPOUND_REQ
  }
  self.UrgentCMD = {
    ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY_ACK,
    ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY,
    ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_DATA_REQ,
    ProtoCMD.ZoneSvrCmd.ZONE_GET_COS_UPLOAD_URL_REQ
  }
  self.ZoneServerGCloud = ZoneServerGCloud()
  self.ZoneServerKickOut = ZoneServerKickOut()
  self.onlineState = OnlineState.Logouted
  self.preOnlineState = OnlineState.Logouted
  self.disOnlineState = OnlineState.Logouted
  self.ProtocolChecker = ProtocolChecker()
  self.bDebugSpaceAct = false
  self.bNotSkipAnyProtocolLog = false
  self.waitingUIReason = {}
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.WillEnterBackground)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnHasEnteredForeground)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.Shutdown, self.OnShutdown)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoginModuleEvent.UpdateDone, self.OnUpdateDone)
  self.serverTimeZone = 0
  self.ProtocolStatDict = {}
  self.lastGuardCheckTime = 0
  self.bSendClientEnterSceneFinishNty = false
end

function ZoneServer:WillEnterBackground()
  Log.Debug("[ZoneServer][NetMsg] AppMain.OnApplicationWillEnterBackground")
end

function ZoneServer:OnHasEnteredForeground()
  Log.Debug("[ZoneServer][NetMsg] AppMain.OnApplicationHasEnteredForeground")
end

function ZoneServer:OnUpdateDone()
  _G.NRCNetworkManager:ReloadNetworkLuaState(self.connectID)
end

function ZoneServer:Init()
  Log.Debug("[ZoneServer] Init")
  if not self.bInit then
    _G.NRCNetworkManager:CreateConnector(self.connectID, self.connectType)
    _G.NRCNetworkManager:AddAllProtocolListener(self.connectID, "ZoneServer", self, self.ReceiveProtocolEvent)
    self.ZoneServerGCloud:Init()
    self.ZoneServerKickOut:Init()
    _G.UpdateManager:Register(self)
    for k, v in pairs(_G.ProtoCMD.MessageMap) do
      _G.NRCNetworkManager:SetCmdIdNameMap(self.connectID, k, v)
    end
    AppId = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.GCloudSettings", "AppId")
    Log.Debug("AppId : ", AppId)
    _G.NRCNetworkManager:SetAppId(self.connectID, AppId)
    self:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_LOCK_CLIENT_CMD_NOTIFY, self.OnZoneLockClientCmdNotify)
    self.bSendClientEnterSceneFinishNty = false
    self.bInit = true
  end
  _G.NRCEventCenter:RegisterEvent("ZoneServer", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
end

function ZoneServer:OnShutdown()
  Log.Debug("ZoneServer:OnShutdown")
  _G.NRCNetworkManager:RemoveAllProtocolListener(self.connectID, "ZoneServer")
  _G.NRCNetworkManager:ClearValidServerIdAndTime(self.connectID)
  self:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_LOCK_CLIENT_CMD_NOTIFY, self.OnZoneLockClientCmdNotify)
  self.bSendClientEnterSceneFinishNty = false
  self.ZoneServerKickOut:OnShutdown()
  self.ZoneServerGCloud:OnShutdown()
  _G.NRCNetworkManager:DestroyConnector(self.connectID)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
end

function ZoneServer:OnDisconnect()
  self.bSendClientEnterSceneFinishNty = false
end

function ZoneServer:SetOnlineState(newOnlineState)
  if newOnlineState ~= self.onlineState then
    self.preOnlineState = self.onlineState
    self.onlineState = newOnlineState
    Log.Debug("[ZoneServer][NetMsg] SetOnlineState", OnlineState.ToString(self.preOnlineState), "->", OnlineState.ToString(self.onlineState))
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.OnOnlineStateChanged, self.preOnlineState, self.onlineState, self.disOnlineState)
  end
end

function ZoneServer:GetOnlineState()
  return self.onlineState
end

function ZoneServer:GetPreOnlineState()
  return self.preOnlineState
end

function ZoneServer:GetDisOnlineState()
  return self.disOnlineState
end

function ZoneServer:SetDisOnlineState()
  if self.onlineState == OnlineState.EnteringCell or self.onlineState == OnlineState.SwitchingCell or self.onlineState == OnlineState.EnteredCell then
    self.disOnlineState = OnlineState.EnteredCell
  else
    self.disOnlineState = OnlineState.Logined
  end
end

function ZoneServer:GetOnlineStateName(InOnlineState)
  if InOnlineState then
    return OnlineState.ToString(InOnlineState)
  end
  return OnlineState.ToString(self.onlineState)
end

function ZoneServer:SetUserAccountInfo(openId, accessToken)
  Log.Debug("[ZoneServer] SetUserAccountInfo", openId, accessToken)
  _G.NRCNetworkManager:SetUserAccountInfo(self.connectID, openId, accessToken)
end

function ZoneServer:Connect(typeid, zoneid, ipOrDomain, port, encryptMethod, keyMakingMethod, authType, authChannel, clbIpStrArr)
  Log.Debug("[ZoneServer] Connect", typeid, zoneid, ipOrDomain, port, encryptMethod, keyMakingMethod, authType, authChannel, clbIpStrArr)
  if not self:IsConnected() then
    if not self:IsConnecting() then
      self.seqEventArray = {}
      local clbIpUE4StrArr = UE.TArray("")
      if clbIpStrArr and #clbIpStrArr > 0 then
        for _, v in ipairs(clbIpStrArr) do
          clbIpUE4StrArr:Add(v)
        end
      end
      _G.NRCNetworkManager:ConnectToZone(self.connectID, typeid, zoneid, 0, ipOrDomain, port, keyMakingMethod or 0, encryptMethod or 0, authType, authChannel, clbIpUE4StrArr)
      _G.ZoneServer:OpenWaitingUI("ConnectToZone", LuaText.NET_CONNECTING)
    else
      Log.Warning("[ZoneServer] Connect self:IsConnecting() = true")
    end
  else
    Log.Warning("[ZoneServer] Connect self:IsConnected() = true")
  end
end

function ZoneServer:DisConnect(bIgnoreDialogue, bReconnect)
  bIgnoreDialogue = bIgnoreDialogue or false
  bReconnect = bReconnect or false
  Log.Debug("[ZoneServer] DisConnect", bIgnoreDialogue, bReconnect)
  if self:IsConnected() then
    self.seqEventArray = {}
    self.ZoneServerGCloud.bIgnoreDisconnectDialogue = bIgnoreDialogue
    self.ZoneServerGCloud.bReconnectAfterDisconnect = bReconnect
    _G.NRCNetworkManager:DisConnect(self.connectID)
  end
end

function ZoneServer:IsConnected()
  local ConnectState = self:GetConnectState()
  if ConnectState == UE4.ENetConnectState.CONNECTED then
    return true
  end
  return false
end

function ZoneServer:IsConnecting()
  local ConnectState = self:GetConnectState()
  if ConnectState == UE4.ENetConnectState.CONNECTING then
    return true
  end
  return false
end

function ZoneServer:GetConnectState()
  return _G.NRCNetworkManager:GetConnectState(self.connectID)
end

function ZoneServer:ReConnect()
  self.ZoneServerGCloud:ReConnect()
end

function ZoneServer:AddProtocolListener(caller, pid, callback)
  if not self.protocolEventDic then
    Log.Error("[ZoneServer] AddProtocolListener, protocolEventDic is not ready", pid)
    return
  end
  if not caller then
    Log.Error("[ZoneServer] AddProtocolListener no caller", pid, callback)
    return
  end
  if not pid then
    Log.Error("[ZoneServer] AddProtocolListener no pid", caller, pid)
    return
  end
  if not callback then
    Log.Error("[ZoneServer] AddProtocolListener no callback", caller, pid)
    return
  end
  Log.Debug("[ZoneServer] AddProtocolListener", pid, ProtoCMD:GetMessageName(pid))
  local event = ProtocolEvent()
  event.target = caller
  event.handler = callback
  if self.protocolEventDic[pid] == nil then
    self.protocolEventDic[pid] = {}
  end
  table.insert(self.protocolEventDic[pid], event)
end

function ZoneServer:RemoveProtocolListener(caller, pid, callback)
  Log.Debug("[ZoneServer] RemoveProtocolListener", pid, ProtoCMD:GetMessageName(pid))
  if self.protocolEventDic ~= nil and self.protocolEventDic[pid] ~= nil then
    local index = 0
    for i = 1, #self.protocolEventDic[pid] do
      local event = self.protocolEventDic[pid][i]
      if event.target == caller and event.handler == callback then
        index = i
      end
    end
    if 0 ~= index then
      table.remove(self.protocolEventDic[pid], index)
    end
  end
end

function ZoneServer:RemoveProtocolListenerByCaller(caller)
  Log.Debug("[ZoneServer] RemoveProtocolListenerByCaller", caller)
  for key, value in pairs(self.protocolEventDic) do
    local toRemoveList = {}
    for i = 1, #value do
      if value[i].target == caller then
        table.insert(toRemoveList, i)
      end
    end
    for i = #toRemoveList, 1 do
      table.remove(value, toRemoveList[i])
    end
  end
  local toRemoveList = {}
  for i = 1, #self.seqEventArray do
    if self.seqEventArray[i].target == caller then
      table.insert(toRemoveList, i)
    end
  end
  for i = #toRemoveList, 1 do
    table.remove(self.seqEventArray, toRemoveList[i])
  end
end

function ZoneServer:Send(reqCmdID, reqMsg, needRespond)
  local messageName = _G.ProtoCMD:GetMessageName(reqCmdID)
  if not reqMsg or not messageName then
    Log.Error("[ZoneServer][NetMsg] Send invalid message", reqCmdID, messageName)
    return false
  end
  needRespond = needRespond or false
  if not self:IsConnected() then
    Log.Debug("[ZoneServer][NetMsg] Send no connecting", reqCmdID, messageName)
    return false
  end
  local bUrgent = self:IsUrgentCMD(reqCmdID)
  if not self.ProtocolChecker:CanSendCMD(reqCmdID, self.onlineState) then
    return false
  end
  local data = _G.ProtoMgr:Encode(reqCmdID, reqMsg)
  if not data then
    Log.Error("[ZoneServer][NetMsg] Req format is invalid, can not serialize")
    return false
  end
  local msgSize = string.len(data)
  local mockSeqId = self:MockSend(reqCmdID, reqMsg)
  if nil == mockSeqId then
    _G.NRCSDKManager:ReportExtraCrashData(UE4.ECrashDataReporterType.NetRecv, reqCmdID)
    local seqID = 0
    if bUrgent then
      seqID = _G.NRCNetworkManager:SendUrgent(self.connectID, reqCmdID, data, msgSize, false, false)
    else
      seqID = _G.NRCNetworkManager:Send(self.connectID, reqCmdID, data, msgSize, false, false)
    end
    if 0 == seqID then
      Log.Error("[ZoneServer][NetMsg] SendWithHandler error, seqID = 0, messageName = ", messageName)
      return false
    end
  end
  if not self:SkipPrintUnConcernProtocol(reqCmdID) then
    Log.DebugFormat("[ZoneServer][NetMsg] Send %s(%d), msgSize(%d), bBlock(%d), bUrgent(%d), UpStreamLocked(%d), GFrameNumber(%d)", messageName, reqCmdID, msgSize, 0, bUrgent and 1 or 0, self:IsUpstreamLocked() and 1 or 0, UE4.UNRCStatics.GetCurGFrameNumber())
  end
  if reqCmdID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY then
    self.bSendClientEnterSceneFinishNty = true
  end
  return true
end

function ZoneServer:SendWithHandler(reqCmdID, reqMsg, caller, rspHandler, needModal, ignoreErrorTip, delayTimeOfWaitingUI, failHandler)
  local messageName = _G.ProtoCMD:GetMessageName(reqCmdID)
  if not reqMsg or not messageName then
    Log.Error("[ZoneServer][NetMsg] SendWithHandler invalid message", reqCmdID, messageName)
    return false
  end
  if not rspHandler then
    Log.Error("[ZoneServer][NetMsg] SendWithHandler with invalid rspHandler, use Send()", reqCmdID, messageName)
    return false
  end
  if not self:IsConnected() then
    Log.Debug("[ZoneServer][NetMsg] SendWithHandler no connecting", reqCmdID, messageName)
    if failHandler then
      _G.tcall(caller, failHandler, reqCmdID, reqMsg)
    end
    return false
  end
  local bUrgent = self:IsUrgentCMD(reqCmdID)
  if not self.ProtocolChecker:CanSendCMD(reqCmdID, self.onlineState) then
    if failHandler then
      _G.tcall(caller, failHandler, reqCmdID, reqMsg)
    end
    return false
  end
  if nil == needModal then
    needModal = false
  end
  local bBlockCmd = self:IsBlockCMD(reqCmdID)
  local data = _G.ProtoMgr:Encode(reqCmdID, reqMsg)
  if not data then
    Log.Error("[ZoneServer][NetMsg] SendWithHandler Req format is invalid, can not serialize", messageName)
    if failHandler then
      _G.tcall(caller, failHandler, reqCmdID, reqMsg)
    end
    return false
  end
  local msgSize = string.len(data)
  local seqID = 0
  local mockSeqId = self:MockSend(reqCmdID, reqMsg)
  if nil == mockSeqId then
    _G.NRCSDKManager:ReportExtraCrashData(UE4.ECrashDataReporterType.NetRecv, reqCmdID)
    if bUrgent then
      seqID = _G.NRCNetworkManager:SendUrgent(self.connectID, reqCmdID, data, msgSize, bBlockCmd, true)
    else
      seqID = _G.NRCNetworkManager:Send(self.connectID, reqCmdID, data, msgSize, bBlockCmd, true)
    end
    if 0 == seqID then
      Log.Error("[ZoneServer][NetMsg] SendWithHandler error, seqID = 0, messageName=", messageName)
      if failHandler then
        _G.tcall(caller, failHandler, reqCmdID, reqMsg)
      end
      return false
    end
  else
    seqID = mockSeqId
  end
  local event = ProtocolEvent()
  event.seqID = seqID
  event.reqCmdID = reqCmdID
  event.reqMsg = reqMsg
  event.target = caller
  event.handler = rspHandler
  event.bBlockCmd = bBlockCmd
  event.bIgnoreErrorTip = ignoreErrorTip
  event.sendTime = os.msTime()
  event.bWaitingUI = needModal
  event.bLog = false
  event.delayTimeOfWaitingUI = delayTimeOfWaitingUI
  self.seqEventArray[seqID] = event
  if event.bWaitingUI and 0 == event.delayTimeOfWaitingUI then
    self:OpenWaitingUI("SeqBlockEvent", nil, 0)
  end
  if not self:SkipPrintUnConcernProtocol(reqCmdID) then
    Log.DebugFormat("[ZoneServer][NetMsg] SendWithHandler %s(%d), msgSize(%d), seqId(%d), bBlock(%d), bUrgent(%d), UpStreamLocked(%d), GFrameNumber(%d)", messageName, reqCmdID, msgSize, seqID, bBlockCmd and 1 or 0, bUrgent and 1 or 0, self:IsUpstreamLocked() and 1 or 0, UE4.UNRCStatics.GetCurGFrameNumber())
  end
  return true
end

function ZoneServer:MockSend(reqCmdID, reqMsg)
  if _G.RocoEnv.IS_EDITOR and self.MockCallback ~= nil then
    return self.MockCallback.callback(self.MockCallback.caller, reqCmdID, reqMsg)
  end
  return nil
end

function ZoneServer:ReceiveProtocolEvent(connectID, seqID, protocolID, bytes, msgSize, receiveTimeMS, bLocalMsg)
  local messageName = ProtoCMD:GetMessageName(protocolID)
  if messageName then
    if self.bSendClientEnterSceneFinishNty and protocolID ~= _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK then
      if not _G.RocoEnv.IS_SHIPPING then
        Log.Error("[ZoneServer][NetMsg] Must receive ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK, but receive", messageName)
      end
      self.bSendClientEnterSceneFinishNty = false
    end
    _G.NRCSDKManager:ReportExtraCrashData(UE4.ECrashDataReporterType.NetRecv, protocolID)
    local rspMsg
    if RocoEnv.DECODE_PB_MULTI_THREAD then
      local rspRawData, rspRawDataSize = bytes:GetRawData()
      rspMsg = LuaSerialize.unpack(rspRawData, rspRawDataSize)
    else
      rspMsg = bytes:Decode(messageName)
    end
    if not rspMsg then
      Log.Error("[ZoneServer][NetMsg] ReceiveProtocolEvent Can not deserialize rsp", protocolID)
      return
    end
    local elapsedTime = UE4.UNRCStatics.GetTimestampMS() - receiveTimeMS
    local bPreventBroadcast = false
    local recordMask = _G.ProtoEnum.SpacePlayActionMask.SPAM_NONE
    if _G.NRCModuleManager:IsModuleActive("MagicReplayModule") then
      if bLocalMsg then
        local playActName = ""
        _, playActName = self:GetMessageNameOfPlayerActs(protocolID, rspMsg)
        local bPreProcessSuccess = true
        bPreProcessSuccess, rspMsg = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.PreProcessReplayPb, protocolID, playActName, bytes, msgSize, rspMsg)
        if not bPreProcessSuccess then
          bPreventBroadcast = true
        end
      else
        local playActName = ""
        if _G.MagicReplayModuleCmd and _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.IsNetRecording) then
          if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
            local notify = rspMsg
            if notify.space_base_data and notify.space_base_data.mask ~= nil then
              recordMask = notify.space_base_data.mask
            end
            _, playActName = self:GetMessageNameOfPlayerActs(protocolID, rspMsg)
            if "client_move" == playActName and notify.space_base_data then
              local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
              local localPlayerActorId
              if localPlayer then
                localPlayerActorId = localPlayer.serverData.base.actor_id
              end
              if localPlayerActorId and 0 ~= localPlayerActorId and notify.space_base_data.operator_obj_id == localPlayerActorId then
                recordMask = _G.ProtoEnum.SpacePlayActionMask.SPAM_ONLY_FOR_RECORD
              else
                recordMask = _G.ProtoEnum.SpacePlayActionMask.SPAM_NONE
              end
            end
          else
            recordMask = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetProtoRecordMask, messageName)
          end
          if recordMask == _G.ProtoEnum.SpacePlayActionMask.SPAM_ONLY_FOR_RECORD or recordMask == _G.ProtoEnum.SpacePlayActionMask.SPAM_RECORD_AND_PROCESS then
            _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.ReceiveRecordPb, protocolID, playActName, bytes:GetIntactData(), msgSize, rspMsg, receiveTimeMS)
          end
        end
        if recordMask == _G.ProtoEnum.SpacePlayActionMask.SPAM_ONLY_FOR_RECORD then
          bPreventBroadcast = true
        end
      end
    end
    if not self:SkipPrintUnConcernProtocol(protocolID) then
      if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY or protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_BATCH_NOTIFY then
        if not _G.RocoEnv.IS_SHIPPING then
          self:DebugZoneScenePlayActsNotify(protocolID, messageName, elapsedTime, seqID, msgSize, rspMsg, receiveTimeMS, bLocalMsg)
        end
      else
        Log.DebugFormat("[ZoneServer][NetMsg] Receive %s(%d),elapsedTime(%d),seqID(%d),msgSize(%d),recordMask(%d),ReceiveTime(%s:%d),bLocalMsg(%d),GFrameNumber(%d)", messageName, protocolID, elapsedTime, seqID, msgSize, recordMask, os.date("!%H:%M:%S", math.round(receiveTimeMS / 1000)), receiveTimeMS % 1000, bLocalMsg and 1 or 0, UE4.UNRCStatics.GetCurGFrameNumber())
      end
    end
    if not bPreventBroadcast then
      self:BroadcastProcotolEvent(seqID, protocolID, rspMsg)
    end
  else
    Log.Error("[ZoneServer][NetMsg] ReceiveProtocolEvent unknow protocol ID", protocolID)
  end
end

function ZoneServer:BroadcastProcotolEvent(seqID, protocolID, rspMsg)
  local showRetTips = true
  local RetCodes = self.IgnoreErrorCMDs[protocolID]
  if RetCodes and rspMsg.ret_info then
    local RetCode = rspMsg.ret_info.ret_code or 0
    if table.contains(RetCodes, RetCode) then
      showRetTips = false
      Log.Debug("[ZoneServer] Ignore Error Protocol ID", protocolID, RetCode)
    end
  end
  self:PreHandleMsg(rspMsg, protocolID)
  local seqEvent = self.seqEventArray[seqID]
  if nil ~= seqEvent then
    if seqEvent.bIgnoreErrorTip then
      showRetTips = false
    end
    _G.tcall(seqEvent.target, seqEvent.handler, rspMsg, seqEvent.reqMsg)
    self.seqEventArray[seqID] = nil
  end
  if nil ~= self.protocolEventDic[protocolID] then
    for i = 1, #self.protocolEventDic[protocolID] do
      local event = self.protocolEventDic[protocolID][i]
      if event then
        _G.tcall(event.target, event.handler, rspMsg, event.reqMsg)
        if event.bIgnoreErrorTip then
          showRetTips = false
        end
      else
        Log.Error("[ZoneServer]BroadcastProcotolEvent event is nil ,protocolID=", protocolID)
      end
    end
  end
  self:PostHandleMsg(showRetTips, rspMsg, protocolID, seqID)
end

function ZoneServer:PreHandleMsg(rsp, CmdID)
  local info = rsp.ret_info
  local GoodsChange = info and info.goods_change_info
  if GoodsChange and GoodsChange.bag_data_vesion and 0 ~= GoodsChange.bag_data_vesion then
    local BagModule = NRCModuleManager:GetModule("BagModule")
    if BagModule then
      BagModule:SetBagItemInfoVersion(GoodsChange.bag_data_vesion)
    end
  end
  if GoodsChange and GoodsChange.pet_data_vesion and 0 ~= GoodsChange.pet_data_vesion and _G.DataModelMgr.PlayerDataModel then
    _G.DataModelMgr.PlayerDataModel:SetPetInfoVersion(GoodsChange.pet_data_vesion)
  end
  if _G.DataModelMgr.PlayerDataModel and GoodsChange and GoodsChange.changes then
    _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.CheckMainPetTips, GoodsChange.changes)
  end
  local GoodsChangeItems = GoodsChange and GoodsChange.changes
  if GoodsChangeItems then
    for _, GoodsChangeItem in ipairs(GoodsChangeItems) do
      local ItemType = GoodsChangeItem.type
      if ItemType == ProtoEnum.GoodsType.GT_VITEM then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_VITEM, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_BAGITEM then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, GoodsChangeItem, CmdID, GoodsChangeItems)
      elseif ItemType == ProtoEnum.GoodsType.GT_REWARD then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_REWARD, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_PET then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_HANDBOOK then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_TEAMINFO then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_PET_EN then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET_EN, GoodsChangeItem, CmdID)
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET_DATACHANGE, GoodsChangeItem)
      elseif ItemType == ProtoEnum.GoodsType.GT_BACKPACK then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_BACKPACK, GoodsChangeItem.backpack_info, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_BAG_BACKPACK then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_BAG_BACKPACK, GoodsChangeItem.bag_backpack_info, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_RP_BEHAVIOR then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_RP_BEHAVIOR, GoodsChangeItem, CmdID)
      elseif ItemType == ProtoEnum.GoodsType.GT_PETEXP or ItemType == ProtoEnum.GoodsType.GT_PET_HP then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PET_DATACHANGE, GoodsChangeItem)
      elseif ItemType == ProtoEnum.GoodsType.GT_MEDAL then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_MEDAL, GoodsChangeItem)
      elseif ItemType == _G.ProtoEnum.GoodsType.GT_PETBOX_BOX_INFO then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PETBOX_BOX_INFO, GoodsChangeItem, CmdID)
      elseif ItemType == _G.ProtoEnum.GoodsType.GT_PETBOX_PET_CHANGE then
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GoodChangeTypeEnum.GT_PETBOX_PET_PET_CHANGE, GoodsChangeItem, CmdID)
      end
    end
  end
  local GoodsReward = info and info.goods_reward
  if GoodsReward and GoodsReward.rewards then
    for _, GoodsRewardItem in ipairs(GoodsReward.rewards) do
      if GoodsRewardItem.type == ProtoEnum.GoodsType.GT_PET then
        _G.DataModelMgr.PlayerDataModel:ShowPetTips(GoodsRewardItem, CmdID)
      end
    end
  end
end

function ZoneServer:PostHandleMsg(showRetTips, rspMsg, CmdID, seqID)
  self.PostHandleDelegate:Invoke(showRetTips, rspMsg, CmdID, seqID)
  local info = rspMsg.ret_info
  if not info then
    return
  end
  if not _G.DonntPopErrorRetMessageBox and showRetTips and info.ret_code and 0 ~= info.ret_code then
    if info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_DUNGEON_COND_FAIL then
      if NRCModuleManager:GetModule("InstanceModule").FailEnterDungeon == "0" and rspMsg.fail_dungeon_ret then
        for k, v in pairs(rspMsg.fail_dungeon_ret) do
          self:OpenDialog(LuaText.TIPS, LuaText["Error_Code_" .. v], LuaText.OK, nil, DialogContext.Mode.OK, nil)
        end
      end
    elseif CmdID ~= ProtoCMD.ZoneSvrCmd.ZONE_SCENE_APPLY_VISIT_RESULT_NOTIFY and not self:IgnoreErrorCode(info.ret_code) then
      Log.Error("\229\141\143\232\174\174\232\191\148\229\155\158\233\148\153\232\175\175\231\160\129", ProtoCMD:GetMessageName(CmdID), info.ret_code)
      local Key = string.format("Error_Code_%d", info.ret_code)
      local ErrorText = _G.DataConfigManager:GetLocalizationConf(Key, true)
      ErrorText = ErrorText and ErrorText.msg
      if nil == ErrorText then
        local notCfgDes = string.format("%s(%d)", _G.LocalText.NetErrorDefault, info.ret_code)
        if RocoEnv.IS_SHIPPING or not RocoEnv.IS_EDITOR then
          ErrorText = notCfgDes
        else
          local ErrorCodeDesc = require("Data.PB.ErrorCodeDesc")
          ErrorText = ErrorCodeDesc[info.ret_code] or notCfgDes
        end
      end
      if RocoEnv.IS_EDITOR then
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, ErrorText .. [[

(]] .. ProtoCMD:GetMessageName(CmdID) .. " ret_code=" .. info.ret_code .. ")")
      else
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, ErrorText)
      end
    end
  end
  if info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PAY_TOKEN_INVALID then
    Log.Debug("CallRelogin with cmdID: " .. CmdID)
    _G.NRCSDKManager:CallReLogin(info.ret_code)
  end
  local Count = 0
  if info and info.goods_reward and info.goods_reward.rewards then
    for i = #info.goods_reward.rewards, 1, -1 do
      local reward = info.goods_reward.rewards[i]
      if reward then
        if reward.tag == ProtoEnum.GoodsDsiplayTag.NARMAL_SHOW then
          Count = Count + 1
        end
        if reward.tag == Enum.RewardTag.RTA_ACTIVITY and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_ACTIVITY_DROP then
          Count = Count + 1
        end
        if reward.tag == Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
          Count = Count + 1
        end
      end
    end
  end
  if 0 ~= Count and info and info.goods_reward and info.goods_reward.rewards then
    local RewardList = {}
    for k, v in ipairs(info.goods_reward.rewards) do
      if v.type == Enum.GoodsType.GT_FASHION then
        table.insert(RewardList, v.id)
      end
    end
    _G.DataModelMgr.PlayerDataModel:SetPlayerFashionOwnedTask(RewardList)
    if rspMsg and rspMsg.reward_source == _G.ProtoEnum.FlowModule.FLOW_MODULE_PET and rspMsg.flow_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_GIFT_GIVING then
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ProcessRetInfo, CmdID, table.deepCopy(rspMsg.ret_info), false)
    end
  end
end

function ZoneServer:IgnoreErrorCode(retCode)
  local ret = false
  ret = retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PLAYER_IN_WORLD_COMBAT_AREA
  ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PLAYER_OUT_WORLD_COMBAT_AREA
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_EXIT_EXCHANG_EGG
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_IN_WAIT_FOR_SCENESVR_STARTUP
  ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NO_SUITABLE_CELL_NODE
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_DUNGEON_RECOVERING
  ret = ret or retCode == ProtoEnum.MOBA_RET.BattleErr.ERR_BATTLE_CATCH_BALL_CAN_NOT_USE
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_SCE_PWD_WAIT
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ACTIVITY_PET_CERT_ALREADY_IN_PAST
  ret = ret or retCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_HIGH_VALUE_PET_CATCH_NEED_FRIEND_TIMES
  if _G.RocoEnv.IS_SHIPPING then
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NPC_NOT_FOUND
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NPC_CFG_NOT_FOUND
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_AVATAR_BEHAVIOR_STATUS_REPEAT_ADD
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_AVATAR_BEHAVIOR_STATUS_NOT_EXIST
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_BUFF_BAN_SUB_ROLE
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_SYNC_PLAYER_BEHAVIOR_STATUS_INVALID
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_INTERACT_FAIL_AVATAR_PRE_TELEPORT
    ret = ret or retCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_INTERACT_FAIL_AVATAR_TELEPORTING
  end
  if _G.GlobalConfig.bShouldShowRevivePointInfo then
    ret = ret or retCode == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_NOT_FOUND
  end
  ret = ret or retCode == ProtoEnum.MOBA_RET.HttpsvrErr.ERR_HTTPSVR_NETBAR_AUTH_ERROR
  return ret
end

function ZoneServer:OpenWaitingUI(reason, tips, delayTime)
  self.waitingUIReason[reason] = true
  if not _G.NRCModuleManager:DoCmd(LoadingUIModuleCmd.IsWaitingUIEnabled) then
    _G.NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenWaitingUI, tips, delayTime)
    Log.Debug("[WaitingUI]ZoneServer:OpenWaitingUI Really!", reason, tips, delayTime)
  end
end

function ZoneServer:CloseWaitingUI(reason)
  if not self.waitingUIReason[reason] then
    return
  end
  self.waitingUIReason[reason] = nil
  local bHasWaitingUI = false
  for _, v in pairs(self.waitingUIReason) do
    if v then
      bHasWaitingUI = true
      break
    end
  end
  local bIsPanelOpened = _G.NRCModuleManager:DoCmd(LoadingUIModuleCmd.IsWaitingUIEnabled)
  local bIsPanelOpening = _G.NRCModuleManager:DoCmd(LoadingUIModuleCmd.IsWaitingUIOpening)
  if not bHasWaitingUI and (bIsPanelOpened or bIsPanelOpening) then
    _G.NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseWaitingUI)
    Log.Debug("[WaitingUI]ZoneServer:CloseWaitingUI Really!", reason)
  end
end

function ZoneServer:OnNormalProtocolTimeOut(seqEvent)
  local content = ""
  if _G.RocoEnv.IS_SHIPPING then
    content = string.format("%s(to:%d)", _G.LocalText.NetErrorDefault, seqEvent.reqCmdID)
  else
    content = string.format(LuaText.PROTOCOL_TIMEOUT, seqEvent.reqCmdID, _G.ProtoCMD:GetMessageName(seqEvent.reqCmdID))
  end
  if ENABLE_NORMAL_PROTOCOL_TIMEOUT then
    self:DisConnect(true, true)
  end
  if seqEvent and not seqEvent.bLog then
    Log.Error("[ZoneServer][NetMsg] OnNormalProtocolTimeOut:", _G.ProtoCMD:GetMessageName(seqEvent.reqCmdID), seqEvent.reqCmdID, seqEvent.seqID)
    seqEvent.bLog = true
  end
end

function ZoneServer:OnBlockProtocolTimeOut(seqEvent)
  local content = ""
  if _G.RocoEnv.IS_SHIPPING then
    content = string.format("%s(to:%d)", _G.LocalText.NetErrorDefault, seqEvent.reqCmdID)
  else
    content = string.format(LuaText.PROTOCOL_TIMEOUT, seqEvent.reqCmdID, ProtoCMD:GetMessageName(seqEvent.reqCmdID))
  end
  self:DisConnect(true, false)
  self:OpenDialog(LuaText.TIPS, content, LuaText.RETRY, LuaText.BACK, DialogContext.Mode.OK_CANCEL, self.OnDialogResult, ProtoCMD:GetMessageName(seqEvent.reqCmdID))
  if seqEvent and not seqEvent.bLog then
    Log.Error("[ZoneServer][NetMsg] OnBlockProtocolTimeOut", _G.ProtoCMD:GetMessageName(seqEvent.reqCmdID), seqEvent.reqCmdID, seqEvent.seqID)
    seqEvent.bLog = true
  end
  if not _G.RocoEnv.IS_EDITOR then
    _G.NRCSDKManager:CrashSightReportExceptionWithReason(string.format("%s TimeOut", _G.ProtoCMD:GetMessageName(seqEvent.reqCmdID)), "Lua Exception", "")
  end
end

function ZoneServer:GetCurServerInfo(seqId)
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  if not OnlineModule then
    return ""
  end
  local Data = OnlineModule.data
  if not Data then
    return ""
  end
  local PlayerUin = 0
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel:GetPlayerInfo() then
    PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  end
  return string.format("%s:%d %s(%d), seqId=%d", Data.serverName, Data.port, Data.userName, PlayerUin or 0, seqId or 0)
end

function ZoneServer:OpenDialog(title, content, btnOk, btnCancle, mode, callback, debugInfo, bDisconnect)
  Log.Debug("[ZoneServer] OpenDialog", title, content, btnOk, btnCancle, mode, callback, debugInfo)
  local Ctx = DialogContext()
  Ctx:SetTitle(title):SetContent(content):SetMode(mode):SetCallback(self, callback):SetCloseOnCancel(true):SetButtonText(btnOk, btnCancle):SetDebugInfo(debugInfo)
  Log.Debug("[ZoneServer] Ctx", Ctx.content)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenOnlyForNetworkDialog, Ctx)
end

function ZoneServer:OnDialogResult(result)
  self.ZoneServerGCloud:OnDialogResult(result)
end

function ZoneServer:SkipPrintUnConcernProtocol(protocolID)
  if self.bNotSkipAnyProtocolLog then
    return false
  end
  if protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SET_NPC_POS_RSP or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOVE_REQ or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOVE_RSP or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAYER_ACT_NTY_REQ or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAYER_ACT_NTY_RSP or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SYNC_STAMINA_REQ or protocolID == ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SYNC_STAMINA_RSP then
    return true
  else
    return false
  end
end

function ZoneServer:Pause(reason)
  self.bPause = true
  reason = reason or "Other"
  Log.Debug("[ZoneServer][NetMsg] Pause", reason)
  if not table.contains(self.PauseReason, reason) then
    table.insert(self.PauseReason, reason)
  end
  _G.NRCNetworkManager:Pause(self.connectID)
end

function ZoneServer:Resume(reason)
  reason = reason or "Other"
  Log.Debug("[ZoneServer][NetMsg] Resume", reason)
  table.removeValue(self.PauseReason, reason)
  if #self.PauseReason > 0 then
    return
  end
  self.bPause = false
  _G.NRCNetworkManager:Resume(self.connectID)
end

function ZoneServer:ClearAllPause()
  Log.Debug("[ZoneServer][NetMsg] ClearAllPause")
  self.PauseReason = {}
  _G.NRCNetworkManager:Resume(self.connectID)
end

function ZoneServer:IsPausedBy(reason)
  return table.contains(self.PauseReason, reason)
end

function ZoneServer:OnTick(deltaTime)
  if not self.bPause then
    local anySeqEvent
    local bHasWaitingUI = false
    for seqId, seqEvent in pairs(self.seqEventArray) do
      local CurOnlineState = self:GetOnlineState()
      if CurOnlineState == OnlineState.EnteringCell or CurOnlineState == OnlineState.SwitchingCell then
        seqEvent.deltaTime = seqEvent.deltaTime + deltaTime
      else
        local deltaTimeMS = os.msTime() - seqEvent.sendTime - 1000 * seqEvent.deltaTime
        if deltaTimeMS > PROTOCOL_TIMEOUT_TIME then
          if seqEvent.bBlockCmd then
            self:OnBlockProtocolTimeOut(seqEvent)
          else
            self:OnNormalProtocolTimeOut(seqEvent)
          end
          self.seqEventArray[seqId] = nil
        elseif not bHasWaitingUI and not anySeqEvent and seqEvent and seqEvent.bWaitingUI then
          anySeqEvent = seqEvent
          bHasWaitingUI = bHasWaitingUI or seqEvent.bWaitingUI
        end
      end
    end
    if anySeqEvent and bHasWaitingUI then
      self:OpenWaitingUI("SeqBlockEvent", "", anySeqEvent.delayTimeOfWaitingUI)
    else
      self:CloseWaitingUI("SeqBlockEvent")
    end
  end
  self.ZoneServerGCloud:OnTick(deltaTime)
  local bHasLoading = _G.LoadingUIModuleCmd and _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.HasAnyLoadingUI)
  if self.ZoneServerGCloud:ShouldShowReconnectingUI() and not bHasLoading then
    self:OpenWaitingUI("Reconnecting", LuaText.NET_CONNECTING, 0)
  else
    self:CloseWaitingUI("Reconnecting")
  end
  self:GuardCheck()
end

function ZoneServer:IsBlockCMD(InCMD)
  for _, Cmd in ipairs(self.BlockCMD) do
    if InCMD == Cmd then
      return true
    end
  end
  return false
end

function ZoneServer:IsUrgentCMD(InCMD)
  for _, Cmd in ipairs(self.UrgentCMD) do
    if InCMD == Cmd then
      return true
    end
  end
  return false
end

function ZoneServer:GetServerTime()
  return _G.NRCNetworkManager:GetServerTime(self.connectID)
end

function ZoneServer:SetServerTimeOnlyForInit(initServerTime)
  return _G.NRCNetworkManager:SetServerTimeOnlyForInit(self.connectID, initServerTime)
end

function ZoneServer:SetServerTimeZoneOffset(serverTimeZone)
  self.serverTimeZone = serverTimeZone
end

function ZoneServer:GetServerTimeZoneOffset()
  return self.serverTimeZone
end

function ZoneServer:LockUpstream(bLock, bNoEvent)
  local bOldLock = self:IsUpstreamLocked()
  if bOldLock ~= bLock then
    Log.Debug("[ZoneServer][NetMsg]LockUpstream:", bLock, bNoEvent)
    if not bNoEvent then
      if bLock then
        _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetBeforeLockUpstream)
      else
        _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetBeforeUnLockUpstream)
      end
    end
    _G.NRCNetworkManager:LockUpstream(self.connectID, bLock)
    if not bNoEvent then
      if bLock then
        _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetAfterLockUpstream)
      else
        _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetAfterUnLockUpstream)
      end
    end
  end
end

function ZoneServer:IsUpstreamLocked()
  return _G.NRCNetworkManager:IsUpstreamLocked(self.connectID)
end

function ZoneServer:CanSendNetworkCmd()
  if not self:IsConnected() then
    return false
  end
  if self:IsUpstreamLocked() then
    return false
  end
  return true
end

function ZoneServer:IsEnteredCell()
  return self:CanSendNetworkCmd() and self.onlineState == OnlineState.EnteredCell
end

function ZoneServer:IsEnteringOrSwitchingCell()
  return self.onlineState == OnlineState.EnteringCell or self.onlineState == OnlineState.SwitchingCell
end

function ZoneServer:IsEnteringCell()
  return self.onlineState == OnlineState.EnteringCell
end

function ZoneServer:IsSwitchingCell()
  return self.onlineState == OnlineState.SwitchingCell
end

function ZoneServer:GetTConndRTT()
  if self:IsConnected() then
    return _G.NRCNetworkManager:GetTConndRTT(self.connectID)
  end
  return 999
end

function ZoneServer:OnZoneLockClientCmdNotify(notify)
  local cmdId = notify.cmd_id
  local seqId = notify.msg_idx
  Log.Debug("[ZoneServer][NetMsg] OnZoneLockClientCmdNotify", _G.ProtoCMD:GetMessageName(cmdId), seqId)
  if not _G.RocoEnv.IS_EDITOR then
    _G.NRCSDKManager:CrashSightReportExceptionWithReason(string.format("%s DropByServer", _G.ProtoCMD:GetMessageName(cmdId)), "Lua Exception", "")
  end
  if seqId and self.seqEventArray and self.seqEventArray[seqId] then
    self.seqEventArray[seqId].bDropByServer = true
  end
end

function ZoneServer:DebugZoneScenePlayActsNotify(protocolID, messageName, elapsedTime, seqID, msgSize, rspMsg, receiveTimeMS, bLocalMsg)
  local function DebugActs(notify)
    if notify and notify.acts and #notify.acts > 0 then
      local Actions = notify.acts
      
      local strActs = ""
      for i = 1, #Actions do
        local act = Actions[i]
        for k, _ in pairs(act) do
          strActs = strActs .. k .. ","
          if "client_move" == k then
            local sendTimeMS = act.client_move.time_stamp
            local curTimeMS = self:GetServerTime()
            local lag = curTimeMS - sendTimeMS - elapsedTime
            self:DebugClientMoveLag(lag)
          end
        end
      end
      local recordMask = 0
      if notify.space_base_data then
        recordMask = notify.space_base_data.mask or 0
      end
      Log.DebugFormat("[ZoneServer][NetMsg] Receive %s(%d),elapsedTime(%d),seqID(%d),msgSize(%d),PlayActs(%s),recordMask(%d),ReceiveTime(%s:%d),bLocalMsg(%d),GFrameNumber(%d)", messageName, protocolID, elapsedTime, seqID, msgSize, strActs, recordMask, os.date("!%H:%M:%S", math.round(receiveTimeMS / 1000)), receiveTimeMS % 1000, bLocalMsg and 1 or 0, UE4.UNRCStatics.GetCurGFrameNumber())
    end
  end
  
  if self.bDebugSpaceAct or _G.RocoEnv.IS_EDITOR then
    if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
      DebugActs(rspMsg)
      return true
    elseif protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_BATCH_NOTIFY then
      if rspMsg and rspMsg.acts and #rspMsg.acts > 0 then
        for i = 1, #rspMsg.acts do
          local act = rspMsg.acts[i]
          DebugActs(act)
        end
      end
      return true
    end
  end
  return false
end

function ZoneServer:DebugClientMoveLag(newLag)
  if not self.LagQueue then
    self.LagQueue = _G.Queue(200)
  end
  self.LagQueue:Enqueue(newLag)
  if self.LagQueue:Size() > 200 then
    self.LagQueue:Dequeue()
  end
end

function ZoneServer:GetDebugAvgClientMoveLag()
  if not self.LagQueue or 0 == self.LagQueue:Size() then
    return 0, 0
  end
  local sum = 0
  for _, lag in self.LagQueue:pairs() do
    sum = sum + lag
  end
  return math.round(sum / self.LagQueue:Size()), self.LagQueue:Size()
end

function ZoneServer:GetMessageNameOfPlayerActs(protocolID, notify)
  if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
    local protocolName = _G.ProtoCMD:GetMessageName(protocolID)
    local extraName
    if protocolName and notify and notify.acts and #notify.acts > 0 then
      local Actions = notify.acts
      for i = 1, #Actions do
        local act = Actions[i]
        for k, _ in pairs(act) do
          extraName = k
          break
        end
      end
    end
    if extraName then
      return protocolName, extraName
    end
  end
  return nil, nil
end

function ZoneServer:DebugStatProtocolFreq(protocolID, protocolName, rspMsg, receiveTimeMS)
  if not string.find(protocolName, "^.Next.Zone") then
    return
  end
  if string.find(protocolName, "Gm") or string.find(protocolName, "Debug") then
    return
  end
  local extraName
  if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
    local notify = rspMsg
    if notify and notify.acts and #notify.acts > 0 then
      local Actions = notify.acts
      for i = 1, #Actions do
        local act = Actions[i]
        for k, _ in pairs(act) do
          extraName = k
          break
        end
      end
    end
  end
  if extraName and string.find(extraName, "debug") then
    return
  end
  if not self.ProtocolStatDict then
    self.ProtocolStatDict = {}
  end
  local statKey = ProtocolStat.GetKey(protocolName, extraName)
  if statKey then
    local stat = self.ProtocolStatDict[statKey]
    if not stat then
      stat = ProtocolStat(protocolID, protocolName, extraName, self, self.OnDebugWarnProtocolFreq)
      self.ProtocolStatDict[statKey] = stat
    end
    stat:Stat(receiveTimeMS)
  end
end

function ZoneServer:OnDebugWarnProtocolFreq(statKey, freq, maxWarnFreq, maxFreqRecorded)
  local content = string.format("%s high freq!", statKey)
  if not _G.RocoEnv.IS_EDITOR then
    _G.NRCSDKManager:CrashSightReportExceptionWithReason(content, "Lua Exception", "")
  end
end

function ZoneServer:GuardCheck()
  local elapsedTime = os.msTime() - self.lastGuardCheckTime
  if elapsedTime > GUARD_CHECK_INTERVAL then
    if self:IsEnteredCell() and self:IsUpstreamLocked() then
      Log.Error("[ZoneServer][NetMsg] GuardCheck, Upstream locked when entered cell!")
      self:LockUpstream(false)
      if not _G.RocoEnv.IS_EDITOR then
        _G.NRCSDKManager:CrashSightReportExceptionWithReason("Upstream locked when entered cell!", "Lua Exception", "")
      end
    end
    self.lastGuardCheckTime = os.msTime()
  end
end

return ZoneServer
