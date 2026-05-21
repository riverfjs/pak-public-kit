local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
_G.SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local PlayerModuleNetCenter = NRCClass:Extend("PlayerModuleNetCenter")

function PlayerModuleNetCenter:Ctor(module)
  NRCClass.Ctor(self)
  self._playerModule = module
  self._bornPos = nil
  self._bornRot = nil
  self:AddListener()
end

function PlayerModuleNetCenter:AddListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self.OnEnterScene)
  _G.NRCEventCenter:RegisterEvent("PlayerModuleNetCenter", self, SceneEvent.OnTeleportNotify, self.OnSwitchSceneNotify)
  _G.NRCEventCenter:RegisterEvent("PlayerModuleNetCenter", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
end

function PlayerModuleNetCenter:RemoveListener()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self.OnEnterScene)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.OnSwitchSceneNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
end

function PlayerModuleNetCenter:Destroy()
  self._playerModule = nil
  self.playerInfoDic = nil
  self.roleInfo = nil
  self.roleList = nil
  self:RemoveListener()
end

function PlayerModuleNetCenter:OnEnterScene(rsp)
  Log.Debug("PlayerModuleNetCenter:OnEnterScene")
  if 0 == rsp.ret_info.ret_code then
    self:InitMapData(rsp.self_info.avatar)
  end
end

function PlayerModuleNetCenter:OnSwitchSceneNotify(rsp)
  Log.Debug("PlayerModuleNetCenter:OnSwitchSceneNotify")
  self:InitMapData(rsp.self_info.avatar, rsp.teleport_reason)
end

function PlayerModuleNetCenter:InitMapData(avatarInfo, reason)
  self.FirstEnter = true
  local bornPt = avatarInfo.base.pt
  local pos = bornPt.pos
  if 0 == pos.x and 0 == pos.y and 0 == pos.z then
    Log.Warning("PlayerModuleNetCenter:OnSwitchScene bornPos is (0,0,0)")
  end
  Log.Dump(pos, 9, "PlayerModuleNetCenter:OnEnterScene bornPt.pos")
  self._bornPos = SceneUtils.ServerPos2PlayerPos(pos)
  Log.Debug("[SceneLocalPlayer] platform_actor_id = ", avatarInfo.base.platform_actor_id)
  self._bornRot = SceneUtils.ServerPos2ClientRotator(bornPt.dir)
  Log.Debug("Born angle " .. tostring(self._bornRot.Yaw))
  self._bornReason = reason
  self.playerInfoDic = {}
  self._sceneId2ServerId = {}
  self.roleInfo = avatarInfo
  self:AddPlayer(self.roleInfo)
end

function PlayerModuleNetCenter:OnPlayerInfoChanged(players)
  if not players then
    return
  end
  for i, v in ipairs(players) do
    self:UpdatePlayer(v)
  end
  self._playerModule:DispatchEvent(PlayerModuleEvent.ON_PLAYER_INFO_CHANGED, players)
end

function PlayerModuleNetCenter:AddPlayer(playerInfo)
  if self.playerInfoDic ~= nil then
    self.playerInfoDic[playerInfo.base.actor_id] = playerInfo
  end
end

function PlayerModuleNetCenter:RemovePlayer(id)
  if self.playerInfoDic then
    self.playerInfoDic[id] = nil
  end
end

function PlayerModuleNetCenter:UpdatePlayer(playerInfo)
  if self.playerInfoDic then
    self.playerInfoDic[playerInfo.base.actor_id] = playerInfo
  end
end

function PlayerModuleNetCenter:OnPlayerMoved(action)
  self._playerModule:DispatchEvent(PlayerModuleEvent.ON_PLAYER_MOVE, action)
end

function PlayerModuleNetCenter:OnPlayerTeleport(to_pt)
end

function PlayerModuleNetCenter:OnScenePerformNotify(action)
  self._playerModule:DispatchEvent(PlayerModuleEvent.ON_PLAYER_PERFORM, action)
end

function PlayerModuleNetCenter:GetAllPlayer()
  return self.playerInfoDic
end

function PlayerModuleNetCenter:HasFlag(id)
  if self.flags then
    for i, v in ipairs(self.flags) do
      if v == id then
        return true
      end
    end
  end
  return false
end

function PlayerModuleNetCenter:SyncStatus(status, subStatus, opCode, clearFlag, customParam)
  if not GlobalConfig.SyncPlayerStatus then
    return
  end
  local player = self._playerModule.playerModuleData.localPlayer
  local statusReq = ProtoMessage.newZoneSceneSyncPlayerStatusReq()
  statusReq.status = status
  statusReq.sub_status = subStatus
  statusReq.op_code = opCode
  statusReq.time_stamp = _G.ZoneServer:GetServerTime()
  statusReq.custom_status_param = customParam
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
    statusReq.is_normal_remove = not clearFlag
  end
end

function PlayerModuleNetCenter:SyncStatusRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Debug("PlayerModuleNetCenter: sync status failed")
    return
  end
end

function PlayerModuleNetCenter:SyncStatusList(sync_status_info_list)
  if not GlobalConfig.SyncPlayerStatus then
    return
  end
  local player = self._playerModule.playerModuleData.localPlayer
  local statusReq = ProtoMessage.newZoneSceneSyncPlayerStatusReq()
  statusReq.time_stamp = _G.ZoneServer:GetServerTime()
  if self.failedSyncStatus then
    statusReq.sync_status_info_list = self.failedSyncStatus
    self.failedSyncStatus = nil
  end
  if sync_status_info_list then
    for _, v in ipairs(sync_status_info_list) do
      local statusInfo = v
      if 36 == statusInfo.status or 37 == statusInfo.status then
        Log.Error("[TogetherTeleport] HandStatus Send:", statusInfo.status, statusInfo.op_code)
      end
      table.insert(statusReq.sync_status_info_list, v)
    end
  end
  local sendSuccess = ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SYNC_PLAYER_STATUS_REQ, statusReq)
  if not sendSuccess then
    if not self.failedSyncStatus then
      self.failedSyncStatus = {}
    end
    for _, v in ipairs(statusReq.sync_status_info_list) do
      table.insert(self.failedSyncStatus, v)
    end
  elseif self._needSendMoveReq then
    self._needSendMoveReq = false
    player.movementComponent:SendMoveReq(true, false)
  end
end

function PlayerModuleNetCenter:SyncStatusRspList(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Debug("PlayerModuleNetCenter: sync status failed")
    return
  end
end

function PlayerModuleNetCenter:OnEnterSceneFinishNtyAckCallBack(notify, isReconnecting, isEnteringCell)
  if self.failedSyncStatus then
    self:SyncStatusList()
  end
end

function PlayerModuleNetCenter:SyncBasicMovement(basicMovementID, need_start_cost)
  local player = self._playerModule.playerModuleData.localPlayer
end

return PlayerModuleNetCenter
