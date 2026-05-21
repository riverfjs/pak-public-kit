local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local StatusSyncComponent = Base:Extend("StatusSyncComponent")

function StatusSyncComponent:Ctor()
  self._statusDic = {}
  self._shouldWaitRecover = true
  self._preStatusList = {}
end

function StatusSyncComponent:Attach(owner)
  Base.Attach(self, owner)
  self:PrintStatus()
  self._statusTable = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SCENE_PLAYER_STATUS_MATRIX):GetAllDatas()
end

function StatusSyncComponent:OnSetViewObj()
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.RecoverAllStatus)
end

function StatusSyncComponent:OnReceiveSyncAction(act)
  for _, info in pairs(act.sync_status_info_list) do
    local status = info.status
    local subStatus = info.sub_status and info.sub_status or 1
    local opCode = info.op_code
    local params = info.custom_status_param or {}
    if 36 == status or 37 == status then
      Log.Error("[TogetherTeleport] HandStatus Receive:", status, opCode)
    end
    if #self._preStatusList > 0 then
      local checksum = self:StatusCheckSum(status, subStatus, opCode, params)
      if checksum == self._preStatusList[1].checksum then
        table.remove(self._preStatusList, 1)
        Log.Debug("StatusSyncComponent:PreChangeStatus Cache Hit", status, subStatus, opCode, params)
    end
    else
      self:ChangeServerData(info, status, subStatus, opCode, params)
      if not self._shouldWaitRecover then
        if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD then
          self:ApplyStatus(status, subStatus, opCode, params)
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
          if info.is_normal_remove then
            self:RemoveStatus(status, subStatus, opCode, params)
          else
            self:ClearStatus(status, subStatus, opCode, params)
          end
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH then
          self:RefreshStatus(status, subStatus, opCode, params)
        end
      end
    end
  end
end

function StatusSyncComponent:ChangeServerData(act, status, subStatus, opCode, params)
  local serverInfo = self.owner.serverData.avatar_status
  if serverInfo.status_list == nil then
    self.owner.serverData.avatar_status = {
      status_list = {},
      sub_status_list = {},
      avatar_status_params = {}
    }
    serverInfo = self.owner.serverData.avatar_status
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD then
    for index, value in ipairs(serverInfo.status_list) do
      if value == status then
        serverInfo.sub_status_list[index] = subStatus
        serverInfo.avatar_status_params[index] = params
        return
      end
    end
    table.insert(serverInfo.status_list, status)
    table.insert(serverInfo.sub_status_list, subStatus)
    table.insert(serverInfo.avatar_status_params, params)
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
    for index, value in ipairs(serverInfo.status_list) do
      if value == status then
        table.remove(serverInfo.status_list, index)
        table.remove(serverInfo.sub_status_list, index)
        table.remove(serverInfo.avatar_status_params, index)
        return
      end
    end
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH then
    for index, value in ipairs(serverInfo.status_list) do
      if value == status then
        local merge_tables = function(A, B)
          for k, v in pairs(B) do
            if type(v) == "table" and type(A[k]) == "table" then
              merge_tables(A[k], v)
            else
              A[k] = v
            end
          end
        end
        merge_tables(serverInfo.avatar_status_params[index], params)
        return
      end
    end
  end
end

function StatusSyncComponent:PreApplyStatus(status, subStatus)
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    return localPlayer.statusComponent:PreApplyStatusFor3P(status, subStatus, self._statusDic)
  end
  return false
end

function StatusSyncComponent:ApplyStatus(status, subStatus, opCode, ...)
  if not self._statusDic[status] then
    self._statusDic[status] = 0
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM and opCode ~= ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  end
  self._statusDic[status] = subStatus
  self.owner:SendEvent(PlayerModuleEvent.ON_APPLY_STATUS, status, subStatus, opCode, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, subStatus, opCode, ...)
  self:PrintStatus()
end

function StatusSyncComponent:RemoveStatus(status, subStatus, opCode, ...)
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  local originStatusValue = self._statusDic[status] or 0
  if originStatusValue <= 0 then
    return
  end
  self._statusDic[status] = nil
  self.owner:SendEvent(PlayerModuleEvent.ON_REMOVE_STATUS, status, originStatusValue, opCode, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, originStatusValue, opCode, ...)
  self:PrintStatus()
end

function StatusSyncComponent:ClearStatus(status, subStatus, opCode, ...)
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  local originStatusValue = self._statusDic[status] or 0
  if originStatusValue <= 0 then
    return
  end
  self._statusDic[status] = nil
  self.owner:SendEvent(PlayerModuleEvent.ON_CLEAR_STATUS, status, originStatusValue, opCode, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, originStatusValue, opCode, ...)
  self:PrintStatus()
end

function StatusSyncComponent:RefreshStatus(status, subStatus, opCode, ...)
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH
  local originStatusValue = self._statusDic[status] or 0
  if originStatusValue <= 0 then
    return
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_REFRESH, status, originStatusValue, opCode, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, originStatusValue, opCode, ...)
  self:PrintStatus()
end

function StatusSyncComponent:HasStatus(status)
  if not self._statusDic then
    return false
  end
  local statusValue = self._statusDic[status]
  if not statusValue or statusValue <= 0 then
    return false
  end
  return true
end

function StatusSyncComponent:HasAnyStatus(...)
  local args = {
    ...
  }
  for _, v in pairs(args) do
    if self:HasStatus(v) then
      return true
    end
  end
  return false
end

function StatusSyncComponent:ClearAll()
  local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  for k, v in pairs(self._statusDic) do
    local status = k
    local subStatus = self._statusDic[status]
    self._statusDic[status] = 0
    self.owner:SendEvent(PlayerModuleEvent.ON_REMOVE_STATUS, status, subStatus, opCode)
    self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, subStatus, opCode)
  end
end

function StatusSyncComponent:RecoverAllStatus()
  if self._shouldWaitRecover then
    local serverInfo = self.owner.serverData.avatar_status
    local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER
    if serverInfo.status_list and serverInfo.sub_status_list then
      local postStatusList = {}
      for index, value in ipairs(serverInfo.status_list) do
        if self:CheckHasRequire(value) then
          table.insert(postStatusList, value)
        else
          self:ApplyStatus(value, serverInfo.sub_status_list[index], opCode, serverInfo.avatar_status_params[index])
        end
      end
      if #postStatusList > 0 then
        for index, value in ipairs(postStatusList) do
          self:ApplyStatus(value, 1, opCode)
        end
      end
    end
    self._shouldWaitRecover = false
    self.owner:SendEvent(PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH)
  end
end

function StatusSyncComponent:RecoverAllStatus_KeepModel(NewServerData)
  self._shouldWaitRecover = true
  local serverInfo = NewServerData.avatar_status
  local serverStatus = serverInfo.status_list or {}
  local serverSubStatus = serverInfo.sub_status_list or {}
  local serverStatusParams = serverInfo.avatar_status_params
  local clearStatus = {}
  for k, v in pairs(self._statusDic) do
    if not table.contains(serverStatus, k) then
      table.insert(clearStatus, k)
    elseif k == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
      local subStatusIndex = table.indexOf(serverStatus, k)
      local statusParam = serverStatusParams[subStatusIndex]
      local localStatusParam = self:GetCustomParams(k)
      local serverGid = statusParam.ride_param.ride_pet_gid or 0
      local localGid = localStatusParam.ride_param.ride_pet_gid or 0
      if serverGid == localGid and statusParam.ride_param.double_ride_2p_id == localStatusParam.ride_param.double_ride_2p_id then
      else
        table.insert(clearStatus, k)
      end
    end
  end
  for k, v in pairs(clearStatus) do
    self:RemoveStatus(v)
  end
  self._serverDataWhileRecover = NewServerData.avatar_status
  local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  if serverInfo.status_list and serverInfo.sub_status_list then
    local postStatusList = {}
    for index, value in ipairs(serverInfo.status_list) do
      if (0 == self._statusDic[value] or self._statusDic[value] == nil) and not self:ShouldSkipRecover(value) then
        if self:CheckHasRequire(value) then
          table.insert(postStatusList, value)
        else
          self:ApplyStatus(value, serverInfo.sub_status_list[index], opCode, serverInfo.avatar_status_params[index])
        end
      end
    end
    if #postStatusList > 0 then
      for index, value in ipairs(postStatusList) do
        self:ApplyStatus(value, 1, opCode)
      end
    end
  end
  self._serverDataWhileRecover = nil
  self._shouldWaitRecover = false
  self.owner:SendEvent(PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH)
end

function StatusSyncComponent:ShouldSkipRecover(status)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE and self:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND, ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    return true
  end
  return false
end

function StatusSyncComponent:CheckHasRequire(status)
  local config = self:GetScenePlayerStatusMatrix(status)
  if not config then
    return false
  end
  for _, v in pairs(self._statusTable) do
    local statusConf = v
    local opCode = config.op_code[statusConf.status_type]
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REQUIRE and not self:HasStatus(statusConf.status_type) then
      return true
    end
  end
  return false
end

function StatusSyncComponent:Destroy()
  self:ClearAll()
  if self.owner then
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.RecoverAllStatus)
  end
end

function StatusSyncComponent:PrintStatus()
  if false then
    Log.Debug("\229\144\140\230\173\165\231\142\169\229\174\182\231\138\182\230\128\129\232\176\131\232\175\149")
    Log.Dump(self.owner.serverData.avatar_status)
  end
end

function StatusSyncComponent:GetScenePlayerStatusMatrix(status)
  for k, v in pairs(self._statusTable) do
    if v.status_type == status then
      return v
    end
  end
end

function StatusSyncComponent:GetCustomParams(status)
  if self._serverDataWhileRecover then
    for index, value in ipairs(self._serverDataWhileRecover.status_list) do
      if value == status then
        return self._serverDataWhileRecover.avatar_status_params[index]
      end
    end
  end
  local serverInfo = self.owner.serverData.avatar_status
  if serverInfo.status_list then
    for index, value in ipairs(serverInfo.status_list) do
      if value == status then
        return serverInfo.avatar_status_params[index]
      end
    end
  end
  return nil
end

function StatusSyncComponent:OnLogicStatusChange(ChangeInfo)
  if not ChangeInfo then
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRANSFORM then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      self.owner.serverData.avatar_status.end_transform_time = _G.ZoneServer:GetServerTime()
    end
    return
  end
end

function StatusSyncComponent:PreChangeStatus(status, subStatus, opCode, params, ...)
  local checksum = self:StatusCheckSum(status, subStatus, opCode, params)
  if checksum then
    table.insert(self._preStatusList, {
      checksum = checksum,
      status = status,
      subStatus = subStatus,
      opCode = opCode,
      params = params,
      remain_time = 10000
    })
    self:EnableTick(true)
    Log.Debug("StatusSyncComponent:PreChangeStatus", status, subStatus, opCode, params)
  else
    Log.Error("StatusSyncComponent:PreChangeStatus checksum is nil")
    return false
  end
  self:ChangeServerData(nil, status, subStatus, opCode, params)
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD then
    self:ApplyStatus(status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, params)
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
    self:RemoveStatus(status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE, params)
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH then
    self:RefreshStatus(status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, params)
  end
end

function StatusSyncComponent:ClearPreStatusList()
  Log.Debug("StatusSyncComponent:ClearPreStatusList")
  self._preStatusList = {}
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    local customParams = self:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if customParams and localPlayer.serverData.base.actor_id == customParams.ride_param.double_ride_1p_id then
      Log.Debug("StatusSyncComponent:PreChangeStatus Clear RideAll")
      self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    end
  end
  if self:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    local customParams = self:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
    if customParams and localPlayer.serverData.base.logic_id == customParams.player_interact_param.player_uin1 then
      Log.Debug("StatusSyncComponent:PreChangeStatus Clear HandInHand")
      self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
    end
  end
end

function StatusSyncComponent:StatusCheckSum(status, subStatus, opCode, params)
  if not params or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
    return (status or 0) * 1.0E7 + (subStatus or 0) * 1000000.0 + (opCode or 0) * 100000.0
  end
  return (status or 0) * 1.0E7 + (subStatus or 0) * 1000000.0 + (opCode or 0) * 100000.0 + self:table_checksum(params)
end

function StatusSyncComponent:table_checksum(tbl)
  local _serialize = function(t)
    local parts = {}
    for k, v in pairs(t) do
      if type(v) == "table" then
        table.insert(parts, k .. "{" .. _serialize(v) .. "}")
      else
        table.insert(parts, k .. ":" .. tostring(v))
      end
    end
    table.sort(parts)
    return table.concat(parts, "|")
  end
  local serialized = _serialize(tbl)
  local toNum = serialized:byte(1, -1)
  if nil == toNum then
    return 0
  end
  return string.format("%x", toNum % 4.294967296E9)
end

function StatusSyncComponent:OnTick(DeltaTime)
  if 0 == #self._preStatusList then
    self:EnableTick(false)
    return
  end
  local NeedClear = false
  for k, v in pairs(self._preStatusList) do
    v.remain_time = v.remain_time - DeltaTime
    if v.remain_time <= 0 then
      NeedClear = true
    end
  end
  if NeedClear then
    Log.Error("StatusSyncComponent \233\162\132\232\161\168\230\188\148\232\182\133\230\151\182\239\188\1403P\229\188\130\229\184\184")
    self:ClearPreStatusList()
  end
end

function StatusSyncComponent:EnableTick(Enable)
  if self._isTickEnabled == nil or self._isTickEnabled ~= Enable then
    self._isTickEnabled = Enable
    if Enable then
    else
    end
  end
end

return StatusSyncComponent
