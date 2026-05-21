local Base = require("NewRoco.Modules.Core.Scene.Component.HeadLookAt.HeadLookAtComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local HeadLookAtLocalComponent = Base:Extend("HeadLookAtLocalComponent")

function HeadLookAtLocalComponent:ReceiveBeginPlay()
  self.banLookAtPlayerStatus = {}
  local wpst_conf = DataConfigManager:GetAllByTableID(DataConfigManager.ConfigTableId.SCENE_STATUS_WPST_CONF)
  if wpst_conf then
    for k, v in pairs(wpst_conf) do
      if v.look_at_block_list then
        self.banLookAtPlayerStatus[k] = false
      end
    end
  end
  self.banLookAtLogictatus = {}
  self.forceLookAtLogicStatus = {}
  local sals_conf = DataConfigManager:GetAllByTableID(DataConfigManager.ConfigTableId.SCENE_STATUS_SALS_CONF)
  if sals_conf then
    for k, v in pairs(sals_conf) do
      if v.look_at_block_sals_list then
        self.banLookAtLogictatus[k] = false
      end
      if v.force_look_with_relation_tree then
        self.forceLookAtLogicStatus[k] = false
      end
    end
  end
  self.isMultiSeat = {}
  local seat_conf = DataConfigManager:GetAllByTableID(DataConfigManager.ConfigTableId.SEAT_CONF)
  if seat_conf then
    for k, v in pairs(seat_conf) do
      self.isMultiSeat[k] = v.seat_num > 1
    end
  end
end

function HeadLookAtLocalComponent:SetPlayer(LocalPlayer)
  if LocalPlayer then
    self.player = LocalPlayer
    LocalPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    LocalPlayer:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusChanged)
  end
end

function HeadLookAtLocalComponent:ReceiveEndPlay(EndPlayReason)
  self.Overridden.ReceiveEndPlay(self, EndPlayReason)
  if self.player then
    self.player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    self.player:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusChanged)
  end
end

function HeadLookAtLocalComponent:OnPlayerStatusChanged(status, _, opCode, ...)
  if self.banLookAtPlayerStatus[status] ~= nil then
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER then
      if self.banLookAtPlayerStatus[status] == false then
        self.banLookAtPlayerStatus[status] = true
        self.CurBanStatus = self.CurBanStatus + 1
      end
    elseif (opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE) and self.banLookAtPlayerStatus[status] == true then
      self.banLookAtPlayerStatus[status] = false
      self.CurBanStatus = self.CurBanStatus - 1
    end
  end
end

function HeadLookAtLocalComponent:OnLogicStatusChanged(player, ChangeInfo)
  if player ~= self.player then
    return
  end
  if ChangeInfo then
    local newStatus = ChangeInfo.changed_status.status
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD then
      if self.banLookAtLogictatus[newStatus] == false then
        self.banLookAtLogictatus[newStatus] = true
        self.CurBanStatus = self.CurBanStatus + 1
      end
      if false == self.forceLookAtLogicStatus[newStatus] then
        self.forceLookAtLogicStatus[newStatus] = true
        self.CurForceStatus = self.CurForceStatus + 1
      end
    elseif ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      if self.banLookAtLogictatus[newStatus] == true then
        self.banLookAtLogictatus[newStatus] = false
        self.CurBanStatus = self.CurBanStatus - 1
      end
      if true == self.forceLookAtLogicStatus[newStatus] then
        self.forceLookAtLogicStatus[newStatus] = false
        self.CurForceStatus = self.CurForceStatus - 1
      end
    end
  else
    local LogicStatusComp = player and player.LogicStatusComponent
    if LogicStatusComp then
      for k, v in pairs(self.banLookAtLogictatus) do
        if v then
          self.banLookAtLogictatus[k] = false
          self.CurBanStatus = self.CurBanStatus - 1
        end
      end
      for k, _ in pairs(self.forceLookAtLogicStatus) do
        self.forceLookAtLogicStatus[k] = false
      end
      self.CurForceStatus = 0
      for _, info in ipairs(LogicStatusComp.StatusInfo) do
        if self.banLookAtLogictatus[info.status] == false then
          self.banLookAtLogictatus[info.status] = true
          self.CurBanStatus = self.CurBanStatus + 1
        end
        if false == self.forceLookAtLogicStatus[info.status] then
          self.forceLookAtLogicStatus[info.status] = true
          self.CurForceStatus = self.CurForceStatus + 1
        end
      end
    end
  end
  if self.CurForceStatus > 0 then
    self.PendingLookAtTarget:Set(UE4.ELookAtMode.HardLock + 1, self.PendingLookAtTarget:Get(UE4.ELookAtMode.SoftLock + 1))
  else
    self.PendingLookAtTarget:Set(UE4.ELookAtMode.HardLock + 1, nil)
  end
end

function HeadLookAtLocalComponent:LuaGetSeatInfo()
  local Result = UE4.FSeatInfo()
  if self.player then
    local SeatID
    local serverData = self.player.serverData
    if serverData then
      local avatar = serverData.avatar_interact
      if avatar then
        local sit_info = avatar.sit_info
        if sit_info then
          SeatID = sit_info.sit_npc_id
        end
      end
    end
    local npcModule = NRCModuleManager:GetModule("NPCModule")
    local SeatNPC = npcModule and npcModule:GetNpcByServerID(SeatID)
    Result.bInSeat = nil ~= SeatNPC
    Result.SeatID = SeatID or 0
    if SeatNPC then
      local SeatCfgID = SeatNPC.serverData.npc_base.npc_cfg_id
      Result.bIsMultiSeat = self.isMultiSeat[SeatCfgID]
    end
  end
  return Result
end

function HeadLookAtLocalComponent:LuaFindNearByPlayersWithSameSeat(SeatID, RadiusSquared)
  local Result = UE4.TArray(UE4.AActor)
  local localUin = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
  local allPlayers = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_ALL_PLAYER)
  if not allPlayers then
    return Result
  end
  for _, v in pairs(allPlayers) do
    local player = v
    if not player or player:GetServerId() == localUin then
    elseif player.squaredDis2Local and RadiusSquared < player.squaredDis2Local then
    elseif player.serverData and player.serverData.avatar_interact and player.serverData.avatar_interact.sit_info and player.serverData.avatar_interact.sit_info.sit_npc_id == SeatID then
    elseif UE.UObject.IsValid(player.viewObj) then
      Result:Add(player.viewObj)
    end
  end
  return Result
end

function HeadLookAtLocalComponent:LuaFindNearByPlayers(RadiusSquared)
  local Result = UE4.TArray(UE.AActor)
  local localUin = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
  local allPlayers = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_ALL_PLAYER)
  if not allPlayers then
    return Result
  end
  for _, v in pairs(allPlayers) do
    local player = v
    if not player or player:GetServerId() == localUin then
    elseif player.squaredDis2Local and RadiusSquared < player.squaredDis2Local then
    elseif UE.UObject.IsValid(player.viewObj) then
      Result:Add(player.viewObj)
    end
  end
  return Result
end

function HeadLookAtLocalComponent:LuaFindNearByNPCs(RadiusSquared)
  local Result = UE4.TArray(UE.AActor)
  local nearbyNPCs = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcsByFilter, nil, function(NPC)
    return NPC and NPC:IsHuman() and NPC.viewObj and NPC.squaredDis2Local < RadiusSquared
  end)
  for _, v in pairs(nearbyNPCs) do
    Result:Add(v.viewObj)
  end
  return Result
end

function HeadLookAtLocalComponent:OnInteractionLookAt(Target, bIsLeave)
  if bIsLeave then
    if self.PendingLookAtTarget:Get(UE4.ELookAtMode.InteractionLock + 1) == Target then
      self.PendingLookAtTarget:Set(UE4.ELookAtMode.InteractionLock + 1, nil)
    end
  else
    self.PendingLookAtTarget:Set(UE4.ELookAtMode.InteractionLock + 1, Target)
  end
end

function HeadLookAtLocalComponent:OnRelationTreeTargetChanged(Target)
  self.PendingLookAtTarget:Set(UE4.ELookAtMode.SoftLock + 1, Target)
  if nil == Target then
    self.PendingLookAtTarget:Set(UE4.ELookAtMode.HardLock + 1, nil)
  elseif self.CurForceStatus > 0 then
    self.PendingLookAtTarget:Set(UE4.ELookAtMode.HardLock + 1, self.PendingLookAtTarget:Get(UE4.ELookAtMode.SoftLock + 1))
  end
end

function HeadLookAtLocalComponent:LuaSendSwitchLookAtTargetSyncData(bForce, bManualOverride)
  self.player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not self.player then
    return
  end
  local actor
  if not bManualOverride then
    actor = self:GetLookAtTarget()
  end
  local currentTarget = UE.UObject.IsValid(actor) and actor.sceneCharacter or nil
  if not bForce and currentTarget == self.syncTarget then
    return
  end
  self.syncTarget = currentTarget
  local req = _G.ProtoMessage:newZoneSceneSwitchLookAtTargetReq()
  req.actor_id = self.player:GetServerId()
  if currentTarget then
    local id = currentTarget:GetServerId()
    req.target_actor_id = id
    local sceneModule = NRCModuleManager:GetModule("SceneModule")
    req.enable = sceneModule and sceneModule:CheckIsPlayer(id)
  else
    req.enable = false
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SWITCH_LOOK_AT_TARGET_REQ, req)
end

return HeadLookAtLocalComponent
