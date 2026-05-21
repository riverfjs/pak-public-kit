local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local MagicReplayFsm = require("NewRoco.Modules.System.MagicReplay.MagicReplayFsm")
local MagicSequenceMgr = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSequenceMgr")
local MagicSeqForReplay = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSeqForReplay")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local MIN_RECORD_TIME = 2
local MagicReplayModule = NRCModuleBase:Extend("MagicReplayModule")

function MagicReplayModule:OnConstruct()
  self.data = self:SetData("MagicReplayModule", "NewRoco.Modules.System.MagicReplay.MagicReplayModuleData")
  self.Fsm = nil
  self.FsmStack = {}
  self.HasMagicReplay = false
  self.CachedActions = {}
  self.FirstEnter = true
  self.recordingTime = 0
  self.magicSeqMgr = MagicSequenceMgr()
  self:AddEventListener()
  self:RegPanel("RecordPanel", "/Game/NewRoco/Modules/System/MagicReplay/Res/UMG_ShootVideoPanel", _G.Enum.UILayerType.UI_LAYER_MAIN, nil, nil, nil, false)
  self:RegPanel("ReplayPanel", "/Game/NewRoco/Modules/System/MagicReplay/Res/UMG_WatchVideoToolbar", _G.Enum.UILayerType.UI_LAYER_MAIN, nil, nil, nil, false)
end

function MagicReplayModule:OnDestruct()
  self:RemoveEventListener()
end

function MagicReplayModule:OnActive()
  self.maxRecordingTime = MagicReplayUtils.GetRecordingMaxTime()
  self.sendStopRecordTimer = 0
  self.uploadCheckTimer = 0
end

function MagicReplayModule:OnDeactive()
end

function MagicReplayModule:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinish)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, MagicReplayModuleEvent.OnMagicSeqPlayerSpawned, self.OnMagicSeqPlayerSpawned)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.OnMagicSeqNpcSpawned)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, _G.SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_REC_BREAK_OFF, self, self.CheckShouldSwitchRecordState)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH_BREAK_OFF, self, self.CheckShouldSwitchReplayState)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, FriendModuleEvent.OnEnterVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:RegisterEvent("MagicReplayModule", self, FriendModuleEvent.OnLeaveVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBagChange)
  self.magicSeqMgr:AddEventListener()
end

function MagicReplayModule:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.OnMagicSeqPlayerSpawned, self.OnMagicSeqPlayerSpawned)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.OnMagicSeqNpcSpawned)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_REC_BREAK_OFF, self, self.CheckShouldSwitchRecordState)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH_BREAK_OFF, self, self.CheckShouldSwitchReplayState)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBagChange)
  self.magicSeqMgr:RemoveEventListener()
end

function MagicReplayModule:CreateNewFsm(CreationFunction)
  local NewFsm = CreationFunction()
  table.insert(self.FsmStack, NewFsm)
  return NewFsm
end

function MagicReplayModule:GetFrontFsm()
  if #self.FsmStack < 1 then
    return nil
  else
    return self.FsmStack[#self.FsmStack]
  end
end

function MagicReplayModule:RemoveFrontFsm()
  if #self.FsmStack < 1 then
    return false
  else
    local Fsm = table.remove(self.FsmStack, #self.FsmStack)
    if Fsm and self.data.SavedTargetView then
      self.data.SavedTargetView[Fsm] = nil
    end
    local NextFsm = self:GetFrontFsm()
    return NextFsm
  end
end

function MagicReplayModule:RemoveFsm(fsm)
  if not fsm then
    return
  end
  return table.removeValue(self.FsmStack, fsm)
end

function MagicReplayModule:MakeFsmFront(fsm)
  if not table.contains(self.FsmStack, fsm) then
    Log.Error("MagicReplayModule:\231\138\182\230\128\129\230\156\186Stack\229\157\143\228\186\134...")
    return false
  end
  table.removeValue(self.FsmStack, fsm)
  table.insert(self.FsmStack, fsm)
  self.Fsm = self:GetFrontFsm()
  return true
end

function MagicReplayModule:OnStartFsm(opType, Option)
  self.isSubmitEnd = false
  self:SetHasMagicReplay(true)
  if not self.Fsm then
    self.Fsm = self:CreateNewFsm(MagicReplayFsm)
    self.Fsm:SetProperty("ParentModule", self)
    self.Fsm:SetProperty("CurrentOption", Option)
    self.Fsm:SetProperty("bIsReconnect", false)
    self.Fsm:Play()
  else
    self.Fsm:Play()
  end
  self.Fsm:SetProperty("OpType", opType)
end

function MagicReplayModule:ShutDownAllFsm()
  local HasMagicReplayToClose = false
  while self.Fsm do
    self.Fsm:SetProperty("bIsReconnect", true)
    if self.Fsm.active then
      HasMagicReplayToClose = true
    end
    self:ShutDownCurrentFsm()
  end
end

function MagicReplayModule:GetMagicAlive()
  if self.Fsm then
    return true
  else
    return false
  end
end

function MagicReplayModule:ShutDownCurrentFsm()
  Log.Debug("MagicReplayModule:ShutDownCurrentFsm")
  self:SetHasMagicReplay(false)
  if not self.Fsm then
    return
  end
  self.Fsm:Resume()
  self.Fsm:SendEvent(MagicReplayModuleEvent.EnterEndState, self)
  self:RemoveFrontFsm()
  self.Fsm = self:GetFrontFsm()
  if self:CheckHasActiveFsm() then
    self:SetHasMagicReplay(true)
  end
end

function MagicReplayModule:OnEnterRecordState()
  Log.Debug("MagicReplayModule:OnEnterRecordState")
  if self.Fsm then
    self.Fsm:SendEvent(MagicReplayModuleEvent.EnterRecordState)
  end
  self:DispatchEvent(MagicReplayModuleEvent.EnterRecordState)
end

function MagicReplayModule:OnEnterReplayState()
  Log.Debug("MagicReplayModule:OnEnterReplayState")
  if self.Fsm then
    self.Fsm:SendEvent(MagicReplayModuleEvent.EnterReplayState)
  end
  self:DispatchEvent(MagicReplayModuleEvent.EnterReplayState)
end

function MagicReplayModule:OnEnterPreviewState(strMessage)
  Log.Debug("MagicReplayModule:OnEnterPreviewState")
  if not string.IsNilOrEmpty(strMessage) then
    local param = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
    if param then
      param.strMessage = strMessage
    end
  end
  if self.Fsm then
    self.Fsm:SendEvent(MagicReplayModuleEvent.EnterPreviewState)
  end
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.EnterPreviewState)
end

function MagicReplayModule:OnEnterShareState()
  Log.Debug("MagicReplayModule:OnEnterShareState")
  if self.Fsm then
    self.Fsm:SendEvent(MagicReplayModuleEvent.EnterShareState)
  end
  self:DispatchEvent(MagicReplayModuleEvent.EnterShareState)
end

function MagicReplayModule:OnEnterShareVideoState()
  Log.Debug("MagicReplayModule:OnEnterShareVideoState")
  if not self.magicSeqMgr or not self.magicSeqMgr:CanReplay() then
    Log.Error("MagicReplayModule:OnEnterShareVideoState, magicSeqMgr is nil or can not replay during cd")
    return
  end
  if self.Fsm then
    self.Fsm:SendEvent(MagicReplayModuleEvent.EnterShareVideoState)
  end
  self:DispatchEvent(MagicReplayModuleEvent.EnterShareVideoState)
end

function MagicReplayModule:OnSwitchRecordState()
  if self.Fsm then
    if self.Fsm:GetActiveStateName() == "RecordProcessState" then
      if self.recordingTime and self.recordingTime > MIN_RECORD_TIME then
        _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnManualStopRecord)
      end
    elseif self.Fsm:GetActiveStateName() == "RecordPrepareState" then
      self.Fsm:SendEvent(MagicReplayModuleEvent.EnterRecordProcessState)
    end
  end
end

function MagicReplayModule:GetCurrentOpType()
  if not self.Fsm then
    return MagicReplayModuleEnum.ModuleOpType.Other
  else
    return self.Fsm:GetProperty("OpType") or MagicReplayModuleEnum.ModuleOpType.Other
  end
end

function MagicReplayModule:GetCurrentFsmState()
  if not self.Fsm then
    return MagicReplayModuleEnum.FsmStateType.Other
  elseif self.Fsm:GetActiveStateName() == "RecordPrepareState" then
    return MagicReplayModuleEnum.FsmStateType.RecordPrepare
  elseif self.Fsm:GetActiveStateName() == "RecordProcessState" then
    return MagicReplayModuleEnum.FsmStateType.RecordProcess
  elseif self.Fsm:GetActiveStateName() == "PreviewPrepareState" then
    return MagicReplayModuleEnum.FsmStateType.PreviewPrepare
  elseif self.Fsm:GetActiveStateName() == "PreviewProcessState" then
    return MagicReplayModuleEnum.FsmStateType.PreviewProcess
  elseif self.Fsm:GetActiveStateName() == "ShareState" then
    return MagicReplayModuleEnum.FsmStateType.Share
  elseif self.Fsm:GetActiveStateName() == "ReplayPrepareState" then
    return MagicReplayModuleEnum.FsmStateType.ReplayPrepare
  elseif self.Fsm:GetActiveStateName() == "ReplayProcessState" then
    return MagicReplayModuleEnum.FsmStateType.ReplayProcess
  elseif self.Fsm:GetActiveStateName() == "ReplayIdleState" then
    return MagicReplayModuleEnum.FsmStateType.ReplayIdle
  else
    return MagicReplayModuleEnum.FsmStateType.Other
  end
end

function MagicReplayModule:StartMagicReplay(opType)
  Log.Trace("MagicReplayModule:StartMagicReplay")
  if self.Fsm then
    self:ShutDownAllFsm()
  end
  if opType == MagicReplayModuleEnum.ModuleOpType.Record then
    local bBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_REC_BREAK_OFF, true)
    if bBan then
      Log.Debug("MagicReplayModule:StartMagicReplay: PFBT_MARK_VIDEO_REC_BREAK_OFF")
      self:ClearRecordNPC()
      return
    end
  elseif opType == MagicReplayModuleEnum.ModuleOpType.Replay then
    local bBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH_BREAK_OFF, true)
    if bBan then
      Log.Debug("MagicReplayModule:StartMagicReplay: PFBT_MARK_VIDEO_WATCH_BREAK_OFF")
      return
    end
  end
  self:OnStartFsm(opType, nil)
  self.Fsm:SetProperty("ReplayNpcId", self.data.replayNpcId or 0)
end

function MagicReplayModule:StopMagicReplay()
  Log.Trace("MagicReplayModule:StopMagicReplay")
  self:ShutDownAllFsm()
end

function MagicReplayModule:CheckHasActiveFsm()
  return self.Fsm and self.Fsm.active
end

function MagicReplayModule:SetHasMagicReplay(HasMagicReplay)
  self.HasMagicReplay = HasMagicReplay
end

function MagicReplayModule:StartReplayProcess()
  Log.Debug("MagicReplayModule:StartReplayProcess")
  if self.magicSeqMgr:CanReplay() then
    _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.StartReplayProcess)
    self:OnEnterReplayState()
  end
end

function MagicReplayModule:StopReplayProcess()
  Log.Debug("MagicReplayModule:StopReplayProcess")
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.StopReplayProcess)
end

function MagicReplayModule:OnPlayerDead()
  self:InterruptMagicReplay()
end

function MagicReplayModule:OnEnterOrLeaveVisit()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record then
    local tipTxt = _G.DataConfigManager:GetLocalizationConf("mark_video_stop_tips")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipTxt and tipTxt.msg or "")
  end
  self:InterruptMagicReplay()
end

function MagicReplayModule:InterruptMagicReplay()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record then
  elseif self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Preview then
  elseif self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Share then
  elseif self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Replay then
  end
  self:ClearMagicReplayNpc()
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicReplayInterrupt)
  self:StopMagicReplay()
end

function MagicReplayModule:LeaveMagicReplayArea()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record then
    local tipTxt = _G.DataConfigManager:GetLocalizationConf("mark_video_stop_tips")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipTxt and tipTxt.msg or "")
  end
  self:DispatchEvent(MagicReplayModuleEvent.OnLeaveMagicReplayArea)
  self:InterruptMagicReplay()
end

function MagicReplayModule:ClearMagicReplayNpc()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Preview or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Share then
    self:ClearRecordNPC()
  else
  end
end

function MagicReplayModule:OnReconnect()
  self.isNetRecording = false
  self:InterruptMagicReplay()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
end

function MagicReplayModule:OnRecordSeqInterrupt()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record then
    local tipTxt = _G.DataConfigManager:GetLocalizationConf("mark_video_stop_in_accident")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipTxt and tipTxt.msg or "")
  end
  self:InterruptMagicReplay()
end

function MagicReplayModule:CheckShouldSwitchRecordState(newState, functionType, reason)
  if newState and (self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Preview or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Share) then
    if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record then
      local tipTxt = _G.DataConfigManager:GetLocalizationConf("mark_video_stop_tips")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipTxt and tipTxt.msg or "")
    end
    self:InterruptMagicReplay()
  else
  end
end

function MagicReplayModule:CheckShouldSwitchReplayState(newState, functionType, reason)
  if newState and self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Replay then
    self:InterruptMagicReplay()
  else
  end
end

function MagicReplayModule:ClearRecordNPC()
  local param = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if param and param.npc_id then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, param.npc_id, param.markType)
  end
end

function MagicReplayModule:ClearReplayNPC()
  local _, npc_id = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetReplayFeedDetail)
  if npc_id then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, npc_id, ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO)
  end
end

function MagicReplayModule:GetRecordNPC()
  local param = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if param and param.npc_id then
    local npc = _G.NRCModeManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFakeId, param.npc_id)
    return npc
  end
  return nil
end

function MagicReplayModule:GetReplayNPC()
  local _, npc_id = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetReplayFeedDetail)
  if npc_id then
    local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npc_id)
    return npc
  end
  return nil
end

function MagicReplayModule:GetInteractNPC()
  if self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Record or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Preview or self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Share then
    return self:GetRecordNPC()
  elseif self:GetCurrentOpType() == MagicReplayModuleEnum.ModuleOpType.Replay then
    return self:GetReplayNPC()
  end
  return nil
end

function MagicReplayModule:PlaySeqTargetEmergeEffect(target, isPlayer, isRidePet, isChangeSuit)
  local interactNpc = self:GetInteractNPC()
  if interactNpc then
    interactNpc.viewObj:PlaySeqTargetEmergeEffect(target, isPlayer, isRidePet, isChangeSuit)
  end
end

function MagicReplayModule:OnMagicSeqNpcSpawned(target, isRidePet)
  self:PlaySeqTargetEmergeEffect(target, nil, isRidePet, nil)
end

function MagicReplayModule:OnMagicSeqPlayerSpawned(target, isChangeSuit)
  self:PlaySeqTargetEmergeEffect(target, true, nil, isChangeSuit)
end

function MagicReplayModule:SetReplayFeedDetail(param, recNpcId)
  self.data.replayFeedDetail = param
  self.data.replayNpcId = recNpcId
end

function MagicReplayModule:GetReplayFeedDetail()
  return self.data.replayFeedDetail, self.data.replayNpcId
end

function MagicReplayModule:SetRecordFeedInitInfo(param)
  self.data.recordFeedInitInfo = param
end

function MagicReplayModule:GetRecordFeedInitInfo()
  return self.data.recordFeedInitInfo
end

function MagicReplayModule:SetRecordDetailInfo(param)
end

function MagicReplayModule:GetRecordDetailInfo()
end

function MagicReplayModule:OnTick(deltaTime)
  if self:IsNetRecording() and self.recordingTime then
    self.recordingTime = self.recordingTime + deltaTime
    if not self.maxRecordingTime then
      self.maxRecordingTime = MagicReplayUtils.GetRecordingMaxTime()
    end
    if self.recordingTime >= self.maxRecordingTime then
      _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnRecordTimeOut)
    end
  end
  self.magicSeqMgr:OnTick(deltaTime)
  if not self.sendStopRecordTimer then
    self.sendStopRecordTimer = 0
  end
  if self.sendStopRecordTimer >= 0 then
    self.sendStopRecordTimer = self.sendStopRecordTimer - deltaTime
  end
  if not self.uploadCheckTimer then
    self.uploadCheckTimer = 0
  end
  if self.uploadCheckTimer >= 0 then
    self.uploadCheckTimer = self.uploadCheckTimer - deltaTime
  end
  local fileList = self:GetUploadFileList()
  if not fileList or not fileList.file_list then
    self.uploadCheckTimer = 0
    return
  end
  local uploadTimeOut = false
  for k, v in pairs(fileList.file_list) do
    if v.expire_timestamp + 5 < math.floor(_G.ZoneServer:GetServerTime() / 1000) then
      uploadTimeOut = true
      break
    end
  end
  if uploadTimeOut then
    if self.uploadCheckTimer <= 0 then
      self.uploadCheckTimer = 300
      self:SyncUploadFileListReq()
    end
  else
    self.uploadCheckTimer = 0
  end
end

function MagicReplayModule:GetRecordingTime()
  return self.recordingTime or 0
end

function MagicReplayModule:SendStartRecordReq(caller, callback)
  if self:IsNetRecording() then
    Log.Debug("MagicReplayModule:SendStartRecordReq recording=true!")
    return
  end
  Log.Debug("MagicReplayModule:SendStartRecordReq")
  self.startRecordCaller = caller
  self.startRecordCallback = callback
  local req = ProtoMessage:newZoneFeedVideoBeginReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_VIDEO_BEGIN_REQ, req, self, self.OnStartRecordRsp)
end

function MagicReplayModule:OnStartRecordRsp(rsp)
  Log.Debug("MagicReplayModule:OnStartRecordRsp")
  if rsp and rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
    local Desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Desc)
  end
end

function MagicReplayModule:SendStopRecordReq(caller, callback)
  if not self:IsNetRecording() then
    Log.Debug("MagicReplayModule:SendStopRecordReq recording=false!")
    return
  end
  if self.sendStopRecordTimer > 0 then
    Log.Debug("MagicReplayModule:SendStopRecordReq already send stop record request", self.sendStopRecordTimer)
    return
  else
    self.sendStopRecordTimer = 5
  end
  Log.Debug("MagicReplayModule:SendStopRecordReq")
  self.stopRecordCaller = caller
  self.stopRecordCallback = callback
  local req = ProtoMessage:newZoneFeedVideoEndReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_VIDEO_END_REQ, req, self, self.OnStopRecordRsp)
end

function MagicReplayModule:OnStopRecordRsp(rsp)
  Log.Debug("MagicReplayModule:OnStopRecordRsp")
  if rsp and rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
    local Desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Desc)
  end
  self.sendStopRecordTimer = 0
end

function MagicReplayModule:OnVideoRecordNotify(notify)
  Log.Debug("MagicReplayModule:OnVideoRecordNotify:", notify.actor_id, notify.start_or_end)
  if notify.start_or_end then
    self.isNetRecording = true
    self.recordingTime = 0
    if self.startRecordCallback and self.startRecordCaller then
      self.startRecordCallback(self.startRecordCaller, notify)
    end
    self:DispatchEvent(MagicReplayModuleEvent.OnReceiveStartRecordNotify, notify)
    if not self.magicSeqMgr:OnRecordStart(notify) then
      self:OnRecordSeqInterrupt()
    end
  else
    self.isNetRecording = false
    if self.stopRecordCallback and self.stopRecordCaller then
      self.stopRecordCallback(self.stopRecordCaller, notify)
    end
    self:DispatchEvent(MagicReplayModuleEvent.OnReceiveStopRecordNotify, notify)
    self.magicSeqMgr:OnRecordEnd(notify)
  end
end

function MagicReplayModule:IsNetRecording()
  return self.isNetRecording
end

function MagicReplayModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, enablePcEsc, autoSetDesiredCursor)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = enablePcEsc or false
  registerData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(registerData)
end

function MagicReplayModule:OpenRecordPanel()
  if not self:HasPanel("RecordPanel") then
    local args = {}
    if self.Fsm then
      args.StateName = self.Fsm:GetActiveStateName()
    end
    self:OpenPanel("RecordPanel", args)
  else
    Log.Warning("\229\183\178\231\187\143\229\173\152\229\156\168RecordPanel")
  end
end

function MagicReplayModule:CloseRecordPanel()
  if not self:HasPanel("RecordPanel") then
    Log.Warning("\229\183\178\231\187\143\228\184\141\229\173\152\229\156\168RecordPanel")
  else
    self:ClosePanel("RecordPanel")
  end
end

function MagicReplayModule:OpenReplayPanel(feedDetail)
  if not self:HasPanel("ReplayPanel") then
    self:OpenPanel("ReplayPanel", feedDetail)
  else
    Log.Warning("\229\183\178\231\187\143\229\173\152\229\156\168ReplayPanel")
  end
end

function MagicReplayModule:CloseReplayPanel()
  self:ClosePanel("ReplayPanel")
end

function MagicReplayModule:OpenToolExitButtonPopup(type)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  if type == MagicReplayModuleEnum.ModuleOpType.Record then
    CommonPopUpData.ContentText = _G.LuaText.mark_video_rec_give_up
    CommonPopUpData.TitleText = _G.LuaText.mark_video_recording_title
  elseif type == MagicReplayModuleEnum.ModuleOpType.Preview then
    CommonPopUpData.ContentText = _G.LuaText.mark_video_rec_give_up
    CommonPopUpData.TitleText = _G.LuaText.mark_video_recording_title
  else
    return
  end
  CommonPopUpData.Btn_LeftText = _G.LuaText.CANCEL
  CommonPopUpData.Btn_RightText = _G.LuaText.umg_bag_11
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.OnToolExitButtonAffirm
  CommonPopUpData.Btn_LeftHandler = self.OnToolExitButtonCancel
  CommonPopUpData.Btn_CloseHandler = self.OnToolExitButtonCancel
  CommonPopUpData.ClosePanelHandler = self.OnToolExitButtonCancel
  CommonPopUpData.OnTickHandler = self.OnToolExitButtonTick
  self.ToolUIExitPopupEnabled = true
  self.ToolUIExitPopupCloseTrigger = false
  _G.NRCModeManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:SetJoystickEnabled(false)
  end
end

function MagicReplayModule:CloseToolExitButtonPopup()
  self:OnToolExitButtonCancel()
end

function MagicReplayModule:OnToolExitButtonAffirm()
  self.ToolUIExitPopupEnabled = false
  self:InterruptMagicReplay()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
end

function MagicReplayModule:OnToolExitButtonCancel()
  self.ToolUIExitPopupEnabled = false
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
end

function MagicReplayModule:OnToolExitButtonTick(CommonPopUpData, umg)
  if not self.ToolUIExitPopupEnabled and not self.ToolUIExitPopupCloseTrigger then
    self.ToolUIExitPopupCloseTrigger = true
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
    umg:OnBtnClose()
  end
end

function MagicReplayModule:OpenToolRestartButtonPopup()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  CommonPopUpData.ContentText = _G.LuaText.mark_video_record_again
  CommonPopUpData.TitleText = _G.LuaText.mark_video_recording_title
  CommonPopUpData.Btn_LeftText = _G.LuaText.CANCEL
  CommonPopUpData.Btn_RightText = _G.LuaText.umg_bag_11
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.OnToolRestartButtonAffirm
  CommonPopUpData.Btn_LeftHandler = self.OnToolRestartButtonCancel
  CommonPopUpData.Btn_CloseHandler = self.OnToolRestartButtonCancel
  CommonPopUpData.ClosePanelHandler = self.OnToolRestartButtonCancel
  CommonPopUpData.OnTickHandler = self.OnToolRestartButtonTick
  self.ToolUIRestartPopupEnabled = true
  self.ToolUIRestartPopupCloseTrigger = false
  _G.NRCModeManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:SetJoystickEnabled(false)
  end
end

function MagicReplayModule:CloseToolRestartButtonPopup()
  self:OnToolRestartButtonCancel()
end

function MagicReplayModule:OnToolRestartButtonAffirm()
  self.ToolUIRestartPopupEnabled = false
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OnEnterRecordState)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
end

function MagicReplayModule:OnToolRestartButtonCancel()
  self.ToolUIRestartPopupEnabled = false
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
end

function MagicReplayModule:OnToolRestartButtonTick(CommonPopUpData, umg)
  if not self.ToolUIRestartPopupEnabled and not self.ToolUIRestartPopupCloseTrigger then
    self.ToolUIRestartPopupCloseTrigger = true
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.RefreshJoystick)
    umg:OnBtnClose()
  end
end

function MagicReplayModule:SyncUploadFileListReq()
  local req = _G.ProtoMessage:newZoneFeedGetCtrlDataReq()
  req.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FEED_GET_CTRL_DATA_REQ, req, self, self.SyncUploadFileListRsp)
end

function MagicReplayModule:SyncUploadFileListRsp(rsp)
  if not (rsp and rsp.ret_info) or not rsp.data then
    Log.Error("MagicReplayModule:OnSyncFileListRsp nil rsp data")
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("MagicReplayModule:OnProcessFileListRsp failed with ret code error : ", rsp.ret_info.ret_code)
    return
  else
    local info = rsp.data.video_upload_info
    self:UpdateUploadFileList(info)
    if self.waitCreateList == nil then
      self.waitCreateList = {}
    end
    if rsp.data.video_upload_info and rsp.data.video_upload_info.file_list then
      for i = 1, #rsp.data.video_upload_info.file_list do
        local fileInfo = rsp.data.video_upload_info.file_list[i]
        self.waitCreateList[fileInfo.file_name] = {
          file_name = fileInfo.file_name,
          content = fileInfo.content,
          create_pos = fileInfo.create_pos,
          sub_type = fileInfo.sub_type
        }
        self:ReqUploadReplay(fileInfo.upload_url, fileInfo.file_name, self, self.OnUploadComplete)
      end
    end
  end
end

function MagicReplayModule:OnBagChange(GoodsChangeItems)
  if GoodsChangeItems then
    local numList = _G.DataConfigManager:GetGlobalConfig("mark_video_item_demand").numList
    if 2 == #numList then
      local itemID = numList[1]
      for _, v in ipairs(GoodsChangeItems) do
        if v.bag_item and v.bag_item.id == itemID then
          self.bagItemNum = v.bag_item.num
          self:CalculateModifiedBagItemValue()
          Log.Info("MagicReplayModule:OnBagChange bagItemNum ", self.bagItemNum)
          break
        end
      end
    end
  end
end

function MagicReplayModule:CalculateModifiedBagItemValue()
  local modifyValue = 0
  if self.data.uploadInfo and self.data.uploadInfo.file_list then
    local uploadNum = #self.data.uploadInfo.file_list
    modifyValue = modifyValue - uploadNum
  end
  local numList = _G.DataConfigManager:GetGlobalConfig("mark_video_item_demand").numList
  if 2 == #numList then
    local itemID = numList[1]
    local needNum = numList[2]
    local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, itemID)
    if itemData and itemData.num and itemData.num > 0 and self.bagItemNum == nil then
      self.bagItemNum = itemData.num
    end
    if itemData and self.bagItemNum then
      local oldValue = self.bagItemNum
      local newValue = self.bagItemNum + modifyValue * needNum
      itemData.num = newValue
      Log.Info("MagicReplayModule:CalculateModifiedBagItemValue Video \233\162\132\230\137\163\233\153\164\232\131\140\229\140\133\228\184\173\231\149\153\229\189\177\233\129\147\229\133\183 oldValue newValue modify", oldValue, newValue, modifyValue)
    end
  end
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo)
end

function MagicReplayModule:UpdateUploadFileList(info)
  self.data.uploadInfo = info
  Log.Dump(info, 4, "MagicReplayModule:UpdateUploadFileList")
  self:CalculateModifiedBagItemValue()
  if self.data.uploadInfo and self.data.uploadInfo.expired_file_list then
    local expiredNum = #self.data.uploadInfo.expired_file_list
    if expiredNum > 0 then
      local tips = _G.DataConfigManager:GetLocalizationConf("mark_video_item_disk").msg
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
      for _, expiredInfo in pairs(self.data.uploadInfo.expired_file_list) do
        local file_name = expiredInfo.file_name
        local npc_id = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFileName, file_name)
        if npc_id then
          _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, npc_id, ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO)
        end
      end
    end
  end
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.UpdateUploadFileList)
end

function MagicReplayModule:GetUploadFileList()
  return self.data.uploadInfo
end

function MagicReplayModule:GetCurrentClientFileUploadInfo(filterTime, filterDevice)
  local fileList = self:GetUploadFileList()
  if not fileList or not fileList.file_list then
    return
  end
  local uploadingList = {}
  for k, v in pairs(fileList.file_list) do
    if filterDevice and v.file_name and not self.magicSeqMgr:IsSeqExists(v.file_name) then
    elseif filterTime and v.expire_timestamp < math.floor(_G.ZoneServer:GetServerTime() / 1000) then
    else
      table.insert(uploadingList, v)
    end
  end
  return uploadingList
end

function MagicReplayModule:OnEnterSceneFinish()
  self:SyncUploadFileListReq()
end

function MagicReplayModule:OnPlaceMagicReplay(content, create_pos, npc_id, rsp)
  if not self:SaveMagicSeqRecord() then
    return
  end
  self:ReqUploadReplay(rsp.upload_url, rsp.file_name, self, self.OnUploadComplete)
  _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.AddVideoToList, rsp.file_name, npc_id)
  self:UpdateUploadFileList(rsp.video_upload_info)
  local file_name = rsp.file_name
  if self.waitCreateList == nil then
    self.waitCreateList = {}
  end
  self.waitCreateList[file_name] = {
    file_name = file_name,
    content = content,
    create_pos = create_pos,
    npc_id = npc_id
  }
end

function MagicReplayModule:OnUploadComplete(file_name, bSuccess)
  if not (bSuccess and self.waitCreateList) or not self.waitCreateList[file_name] then
    Log.Error("[MagicSequence] OnUploadComplete failed", file_name, bSuccess, self.waitCreateList)
    return
  end
  local CurRecord = self:GetCurMagicSeqForRecord()
  if CurRecord and CurRecord.fileName == file_name then
    local reqMsg = _G.ProtoMessage:newZoneFeedVideoCreateReq()
    reqMsg.content = self.waitCreateList[file_name].content
    reqMsg.create_pos = self.waitCreateList[file_name].create_pos
    reqMsg.file_name = self.waitCreateList[file_name].file_name
    reqMsg.file_md5 = CurRecord.fileMD5
    reqMsg.base_info = CurRecord.baseInfo
    reqMsg.base_info_md5 = CurRecord.baseInfoMD5
    reqMsg.sub_type = self.waitCreateList[file_name].sub_type
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_VIDEO_CREATE_REQ, reqMsg, self, self.OnFeedVideoCreateRsp, nil, false)
  elseif self.magicSeqMgr:IsSeqExists(file_name) then
    local seqForReplay = MagicSeqForReplay(file_name, self.waitCreateList[file_name].create_pos)
    if seqForReplay:ReadFromFile() then
      local reqMsg = _G.ProtoMessage:newZoneFeedVideoCreateReq()
      reqMsg.content = self.waitCreateList[file_name].content
      reqMsg.create_pos = self.waitCreateList[file_name].create_pos
      reqMsg.file_name = self.waitCreateList[file_name].file_name
      reqMsg.file_md5 = seqForReplay.fileMD5
      reqMsg.base_info = seqForReplay.baseInfo
      reqMsg.base_info_md5 = seqForReplay.baseInfoMD5
      reqMsg.sub_type = self.waitCreateList[file_name].sub_type
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_VIDEO_CREATE_REQ, reqMsg, self, self.OnFeedVideoCreateRsp, nil, false)
    else
      Log.Error("[MagicSequence] OnUploadComplete but read from file failed, ", file_name)
    end
  else
    Log.Error("[MagicSequence] OnUploadComplete but file not exists, ", file_name)
  end
end

function MagicReplayModule:OnFeedVideoCreateRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ClearRecordNPC()
    self:SyncUploadFileListReq()
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local contenText = string.format(banConfig.str, uin, ban_time, rsp.ban_info.ban_reason)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    return
  end
  if 0 == rsp.ret_info.ret_code then
    local file_name = rsp.feed_video_info.file_name
    if self.waitCreateList[file_name] then
      if not self.waitCreateList[file_name].npc_id then
        self.waitCreateList[file_name].npc_id = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFileName, file_name)
      end
      _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.AddLocalNpcToList, rsp.feed_info, self.waitCreateList[file_name].npc_id, file_name)
      self:UpdateUploadFileList(rsp.video_upload_info)
      self.waitCreateList[file_name] = nil
      Log.Debug("[MagicSequence] OnFeedVideoCreateRsp, ret_code = 0", file_name)
    end
  else
    Log.Error("[MagicSequence] OnFeedVideoCreateRsp", rsp.ret_info.ret_code)
  end
end

function MagicReplayModule:ReqUploadReplay(uploadUrl, fileName, caller, callback)
  self.magicSeqMgr:ReqUploadMagicSeq(uploadUrl, fileName, caller, callback)
end

function MagicReplayModule:ReqDownloadReplay(feedVideoInfo, caller, callback)
  self.magicSeqMgr:ReqDownloadMagicSeq(feedVideoInfo, caller, callback)
end

function MagicReplayModule:GetProtoRecordMask(protocolName)
  local conf = self.magicSeqMgr:GetVideoProtocolConf(protocolName)
  if conf then
    return conf.mask_type
  end
  return _G.ProtoEnum.SpacePlayActionMask.SPAM_NONE
end

function MagicReplayModule:PreProcessReplayPb(protocolID, playActName, bytes, msgSize, decodedMsg)
  return self.magicSeqMgr:PreProcessReplayPb(protocolID, playActName, bytes, msgSize, decodedMsg)
end

function MagicReplayModule:ReceiveRecordPb(protocolID, playActName, bytes, msgSize, decodedMsg, receiveTimeMS)
  if not self.magicSeqMgr:ReceiveRecordPb(protocolID, playActName, bytes, msgSize, decodedMsg, receiveTimeMS) then
    self:OnRecordSeqInterrupt()
  end
end

function MagicReplayModule:SaveMagicSeqRecord()
  if not self.magicSeqMgr:SaveMagicSeqRecord() then
    self:OnRecordSeqInterrupt()
    return false
  end
  return true
end

function MagicReplayModule:GetCurMagicSeqForRecord()
  return self.magicSeqMgr.curMagicSeqForRecord
end

function MagicReplayModule:StartReplay(fileName, createPos, baseInfoMd5, fileMd5)
  return self.magicSeqMgr:StartReplay(fileName, createPos, baseInfoMd5, fileMd5)
end

function MagicReplayModule:StopReplay()
  self.magicSeqMgr:StopReplay()
end

function MagicReplayModule:StartPreview()
  self.magicSeqMgr:StartPreview()
end

function MagicReplayModule:StopPreview()
  self.magicSeqMgr:StopPreview()
end

function MagicReplayModule:SetMainMagicActorId(actorId)
  if nil == actorId then
    self.data.mainMagicActorId = nil
    Log.Debug("[MagicSequence][Mgr] SetMainMagicActorId to nil")
  elseif nil == self.data.mainMagicActorId then
    self.data.mainMagicActorId = actorId
    Log.Debug("[MagicSequence][Mgr] SetMainMagicActorId", self.data.mainMagicActorId)
  end
end

function MagicReplayModule:GetMainMagicActorId()
  return self.data.mainMagicActorId
end

function MagicReplayModule:GetCurSeqForReplay()
  return self.magicSeqMgr:GetCurSeqForReplay()
end

function MagicReplayModule:GetCurSeqForRecord()
  return self.magicSeqMgr:GetCurSeqForRecord()
end

function MagicReplayModule:SetReplaySeqInfo()
  self.data.replaySeqInfo = {}
  local seq = self:GetCurSeqForReplay()
  if seq then
    self.data.replaySeqInfo.seq = seq
    self.data.replaySeqInfo.time = seq:GetDuration()
  end
end

function MagicReplayModule:GetReplaySeqInfo()
  return self.data.replaySeqInfo
end

function MagicReplayModule:GetReplaySeqCurrentTime()
  local seq = self:GetCurSeqForReplay()
  if seq then
    return seq:GetPlayProgress()
  end
  return 0
end

function MagicReplayModule:HasFreeDiskSpace()
  return self.magicSeqMgr:HasFreeDiskSpace()
end

function MagicReplayModule:GetCurrentShareVideoName()
  return "MRShareVideo"
end

function MagicReplayModule:GMSwitchDebugReplay(isDebugReplay, fileName)
  if self.magicSeqMgr then
    self.magicSeqMgr:GMSwitchDebugReplay(isDebugReplay, fileName)
  end
end

return MagicReplayModule
