local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local StatusComponent = Base:Extend("StatusComponent")

function StatusComponent:Ctor()
  if PlayerModuleCmd then
    local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and player.statusComponent then
      Log.Error("\233\135\141\229\164\141\230\183\187\229\138\160statusComponent\239\188\140\228\184\187\232\167\146\229\135\186\231\142\176\228\184\165\233\135\141\233\148\153\232\175\175\239\188\140\232\175\183\232\129\148\231\179\187minotxu\229\145\138\231\159\165\232\167\166\229\143\145\230\131\133\229\189\162")
    end
  end
  self._statusDic = {}
  self._statusParams = {}
  self:BuildRequiredStatusTable()
  self._cachePreApplyStatus = {}
end

function StatusComponent:BuildRequiredStatusTable()
  self._requiredStatus = {}
  self._linkedStatus = {}
  self._statusToConfigIndex = {}
  self._waittingRemove = {}
  self._statusTable = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SCENE_PLAYER_STATUS_MATRIX):GetAllDatas()
  for id, v in ipairs(self._statusTable) do
    local status = v.status_type
    for i, opCode in ipairs(v.op_code) do
      if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REQUIRE then
        if not self._requiredStatus[status] then
          self._requiredStatus[status] = {}
        end
        local requireStatus = self._statusTable[i].status_type
        if not self._linkedStatus[requireStatus] then
          self._linkedStatus[requireStatus] = {}
        end
        table.insert(self._requiredStatus[status], requireStatus)
        table.insert(self._linkedStatus[requireStatus], status)
      end
    end
    self._statusToConfigIndex[status] = id
  end
end

function StatusComponent:Attach(owner)
  Log.Trace("LocalPlayer StatusComponent Attach")
  Base.Attach(self, owner)
  if _G.SceneEvent then
    _G.NRCEventCenter:RegisterEvent("StatusComponent", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinish)
    _G.NRCEventCenter:RegisterEvent("StatusComponent", self, _G.SceneEvent.OnPreTeleportNotify, self.OnPreTeleportNotify)
  end
  self._isConnected = true
  if self:IsInTogetherTeleport() then
    Log.Error("[TogetherTeleport] StatusComponent:Attach Skip Recover ServerStatus")
    self.statusRecovered = false
    NRCModuleManager:DoCmd(PlayerModuleCmd.ClearCachedStatusChange)
    return
  end
  local serverInfo = not owner.serverData or owner.serverData.avatar_status and owner.serverData.avatar_status.status_list or owner.serverData.status_info
  if serverInfo then
    NRCModuleManager:DoCmd(PlayerModuleCmd.ClearCachedStatusChange)
    self._shouldWaitRecover = true
    self:FixStatusWhileReConnect(true)
  end
  if self.owner.viewObj then
    local moveComponent = self.owner.viewObj:GetMovementComponent()
    self:InitMovementModeStatus(moveComponent.MovementMode, moveComponent.CustomMovementMode)
  end
  self.owner:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChange)
  self.statusRecovered = true
end

function StatusComponent:IsInTogetherTeleport()
  if GlobalConfig.DebugTogetherTelInfo then
    return true
  end
  local hasTeleportStatus = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_TELEPORT_TOGETHER)
  return hasTeleportStatus
end

function StatusComponent:GetTogetherPlayerUin()
  local relationInteract = self.owner.serverData.relation_interact
  if relationInteract.uin1p and relationInteract.uin2p then
    local selfUin = self.owner:GetLogicId()
    if selfUin == relationInteract.uin1p then
      return relationInteract.uin2p
    elseif selfUin == relationInteract.uin2p then
      return relationInteract.uin1p
    end
  end
  return 0
end

function StatusComponent:OnEnterSceneFinish(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  if self:IsInTogetherTeleport() then
    Log.Error("[TogetherTeleport] StatusComponent:OnEnterSceneFinish RestoreTogether")
    self:RestoreTogether()
    return
  end
  if self._restoreTogether then
    self:InterruptRestoreTogether()
  end
end

function StatusComponent:RestoreTogether()
  self._restoreTogether = true
  local serverStatusList = self.owner.serverData and self.owner.serverData.avatar_status and self.owner.serverData.avatar_status.status_list
  if serverStatusList then
    for i, v in ipairs(serverStatusList) do
      self:SyncStatus(v, 0, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE, true)
    end
  end
  for k, v in pairs(self._statusDic) do
    self:ClearStatus(k)
  end
  self._statusDic = {}
  self._statusParams = {}
  if not self.statusRecovered then
    self.owner:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChange)
  end
  if self.owner.viewObj then
    local moveComponent = self.owner.viewObj:GetMovementComponent()
    self:InitMovementModeStatus(moveComponent.MovementMode, moveComponent.CustomMovementMode)
  end
  local relationInteract = self.owner.serverData.relation_interact
  if GlobalConfig.DebugTogetherTelInfo then
    relationInteract = ProtoMessage:newActorInfo_RelationInteract()
    relationInteract.status = GlobalConfig.DebugTogetherTelInfo.status
    relationInteract.type = GlobalConfig.DebugTogetherTelInfo.type
    relationInteract.uin1p = GlobalConfig.DebugTogetherTelInfo.uin1p
    relationInteract.uin2p = GlobalConfig.DebugTogetherTelInfo.uin2p
  end
  if relationInteract then
    local custom_params = ProtoMessage.newPlayerStatusCustomParams()
    custom_params.player_interact_param.interact_id = nil
    custom_params.player_interact_param.player_uin1 = relationInteract.uin1p
    custom_params.player_interact_param.player_uin2 = relationInteract.uin2p
    local handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
    if self.owner:GetLogicId() ~= relationInteract.uin1p then
      handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
    end
    self:ApplyStatus(handStatus, nil, nil, custom_params)
    if not self:HasStatus(handStatus) then
      self:ReportRestoreTogetherResult(false)
    end
  else
    Log.Error("[TogetherTeleport] StatusComponent:RestoreTogether relationInteract is nil")
    self:ReportRestoreTogetherResult(false)
  end
end

function StatusComponent:InterruptRestoreTogether()
  if self._restoreTogether then
    Log.Error("[TogetherTeleport] StatusComponent:InterruptRestoreTogether")
    self._restoreTogether = false
    self.owner.InviteComponent:RevertRestore()
  end
end

function StatusComponent:ReportRestoreTogetherResult(success)
  self._restoreTogether = false
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
  Log.ErrorFormat("[TogetherTeleport] %d ReportRestoreTogetherResult %s", self.owner:GetLogicId(), success)
  local req = ProtoMessage:newZoneSceneTogetherTeleportConfirmReq()
  req.together_recover = success
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TOGETHER_TELEPORT_CONFIRM_REQ, req, self, self.OnReportRestoreTogetherResult, false, false)
end

function StatusComponent:OnReportRestoreTogetherResult(rsp)
  if not rsp.ret_info.ret_code or 0 ~= rsp.ret_info.ret_code then
    Log.Error("[TogetherTeleport] StatusComponent:OnReportRestoreTogetherResult Error")
  end
end

function StatusComponent:DeAttach()
  Log.Trace("LocalPlayer StatusComponent DeAttach")
  self.owner:RemoveEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChange)
  if _G.SceneEvent then
    _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinish)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnPreTeleportNotify, self.OnPreTeleportNotify)
  end
  Base.DeAttach(self)
end

function StatusComponent:ApplyStatus(status, opCode, subStatus, customParam, ...)
  if self._shouldWaitRecover then
    Log.Error("StatusComponent:ApplyStatus While Waitting Recover")
    return
  end
  subStatus = subStatus or 1
  self:ClearCachePreApplyStatus()
  local canApply, overrideValues, opCodePre = self:PreApplyStatus(status, subStatus)
  if not canApply then
    Log.DebugFormat("StatusComponent:ApplyStatus can not apply %s, reason %s", StatusUtils.StatusToString(status), StatusUtils.OpCodeToString(opCodePre))
    return
  end
  self._pendingStatus = status
  self._pendingSubStatus = subStatus
  local expectedAfterClearStatusCount = table.size(self._statusDic)
  if overrideValues then
    expectedAfterClearStatusCount = expectedAfterClearStatusCount - #overrideValues
    for _, v in pairs(overrideValues) do
      self.owner:SendEvent(PlayerModuleEvent.ON_PENDING_STATUS, status, v.status, subStatus)
      self:ClearStatus(v.status, v.option)
    end
  end
  local afterClearStatusCount = #self._statusDic
  if afterClearStatusCount ~= expectedAfterClearStatusCount then
    local afterCanApply, _, _ = self:PreApplyStatus(status, subStatus)
    if not afterCanApply then
      Log.DebugFormat("StatusComponent:ApplyStatus can not apply %s, reason %s", StatusUtils.StatusToString(status), StatusUtils.OpCodeToString(opCodePre))
      return
    end
  end
  self:ClearCachePreApplyStatus()
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  self:ApplyStatusInternal(status, opCode, subStatus, customParam, ...)
  self._pendingStatus = nil
  self._pendingSubStatus = nil
end

function StatusComponent:ApplyStatusInternal(status, opCode, subStatus, customParam, ...)
  subStatus = subStatus or 1
  self._statusDic[status] = subStatus
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  local tempParam = customParam
  if tempParam and type(tempParam) ~= "table" then
    tempParam = nil
  end
  self:SyncStatus(status, subStatus, opCode, nil, tempParam)
  self._statusParams[status] = tempParam
  local statusValue = self._statusDic[status]
  self.owner:SendEvent(PlayerModuleEvent.ON_APPLY_STATUS, status, statusValue, opCode, customParam, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, statusValue, opCode, customParam, ...)
end

function StatusComponent:ApplyStatusInternalLocal(status, opCode, subStatus, customParam, ...)
  subStatus = subStatus or 1
  self._statusDic[status] = subStatus
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  local tempParam = customParam
  if tempParam and type(tempParam) ~= "table" then
    tempParam = nil
  end
  self._statusParams[status] = tempParam
  local statusValue = self._statusDic[status]
  self.owner:SendEvent(PlayerModuleEvent.ON_APPLY_STATUS, status, statusValue, opCode, customParam, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, statusValue, opCode, customParam, ...)
end

function StatusComponent:PreApplyStatus(status, subStatus)
  subStatus = subStatus or 1
  local overrideStatus = {}
  local originSubStatus = self._statusDic[status]
  if originSubStatus and originSubStatus ~= subStatus then
    table.insert(overrideStatus, {
      status = status,
      option = ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE,
      subStatus = self._statusDic[status]
    })
    return true, overrideStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  end
  local cacheResult = self._cachePreApplyStatus[status]
  if cacheResult then
    return cacheResult.canApply, cacheResult.overrideStatus, cacheResult.opCode
  end
  local requiredStatus = self._requiredStatus[status]
  if requiredStatus then
    for i, v in ipairs(requiredStatus) do
      if not self:HasStatus(v) then
        if GlobalConfig.DebugStatusInfo then
          local debugStr = string.format("\230\151\160\230\179\149\230\183\187\229\138\160\231\138\182\230\128\129 %s, \229\155\160\228\184\186\230\178\161\230\156\137\228\187\150\233\156\128\232\166\129\231\154\132\229\137\141\231\189\174\231\138\182\230\128\129 %s \229\173\152\229\156\168", StatusUtils.StatusToString(status), StatusUtils.StatusToString(v))
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, debugStr)
        end
        self:CachePreApplyStatus(status, false, nil, ProtoEnum.WPST_OpCode.WPST_OPCODE_BLOCK)
        return false, nil, ProtoEnum.WPST_OpCode.WPST_OPCODE_BLOCK
      end
    end
  end
  for k, v in pairs(self._statusDic) do
    if not v or v <= 0 then
    else
      local statusConf = self:GetScenePlayerStatusMatrix(status)
      if statusConf then
        local statusIndex = self._statusToConfigIndex[k]
        local opCode = statusConf.op_code[statusIndex]
        if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_BLOCK or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_NONE then
          if GlobalConfig.DebugStatusInfo then
            local debugStr = string.format("\230\151\160\230\179\149\230\183\187\229\138\160\231\138\182\230\128\129 %s, \229\155\160\228\184\186\230\156\137\233\152\187\230\173\162\228\187\150\231\154\132\231\138\182\230\128\129 %s \229\173\152\229\156\168 , \230\147\141\228\189\156\231\160\129\230\152\175 %s", StatusUtils.StatusToString(status), StatusUtils.StatusToString(statusConf.status_type), StatusUtils.OpCodeToString(opCode))
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, debugStr)
          end
          self:CachePreApplyStatus(status, false, nil, opCode)
          return false, nil, opCode
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE then
          table.insert(overrideStatus, {
            status = k,
            option = opCode,
            subStatus = nil
          })
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
          table.insert(overrideStatus, {
            status = k,
            option = opCode,
            subStatus = nil
          })
        end
      end
    end
  end
  self:CachePreApplyStatus(status, true, overrideStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD)
  return true, overrideStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
end

function StatusComponent:PreApplyStatusFor3P(status, subStatus, statusDic)
  if not statusDic then
    return false
  end
  subStatus = subStatus or 1
  local overrideStatus = {}
  local originSubStatus = statusDic[status]
  if originSubStatus and originSubStatus ~= subStatus then
    table.insert(overrideStatus, {
      status = status,
      option = ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE,
      subStatus = statusDic[status]
    })
    return true, overrideStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
  end
  local requiredStatus = self._requiredStatus[status]
  if requiredStatus then
    for i, v in ipairs(requiredStatus) do
      if not statusDic[v] > 0 then
        return false, nil, ProtoEnum.WPST_OpCode.WPST_OPCODE_BLOCK
      end
    end
  end
  for k, v in pairs(statusDic) do
    if not v or v <= 0 then
    else
      local statusConf = self:GetScenePlayerStatusMatrix(status)
      if statusConf then
        local statusIndex = self._statusToConfigIndex[k]
        local opCode = statusConf.op_code[statusIndex]
        if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_BLOCK or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_NONE then
          return false, nil, opCode
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE then
          table.insert(overrideStatus, {
            status = k,
            option = opCode,
            subStatus = nil
          })
        elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
          table.insert(overrideStatus, {
            status = k,
            option = opCode,
            subStatus = nil
          })
        end
      end
    end
  end
  return true, overrideStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
end

function StatusComponent:CachePreApplyStatus(status, canApply, overrideStatus, opCode)
  local cacheResult = {}
  cacheResult.canApply = canApply
  cacheResult.overrideStatus = overrideStatus
  cacheResult.opCode = opCode
  self._cachePreApplyStatus[status] = cacheResult
end

function StatusComponent:ClearCachePreApplyStatus()
  self._cachePreApplyStatus = {}
end

function StatusComponent:RemoveStatus(status, opCode, subStatus, ...)
  if self._shouldWaitRecover and not self._recovering then
    Log.Error("StatusComponent:RemoveStatus While Waitting Recover")
    return
  end
  local originStatusValue = self._statusDic[status] or 0
  if originStatusValue <= 0 or subStatus and 0 ~= subStatus and subStatus ~= originStatusValue then
    return
  end
  self:ClearCachePreApplyStatus()
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  self:PreRemoveStatus(status, opCode)
  local oldSubStatus = self._statusDic[status]
  self._statusDic[status] = nil
  self._statusParams[status] = nil
  self:SyncStatus(status, subStatus, opCode)
  self.owner:SendEvent(PlayerModuleEvent.ON_REMOVE_STATUS, status, oldSubStatus, opCode, ...)
  self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, oldSubStatus, opCode, ...)
end

function StatusComponent:PreRemoveStatus(status, opCode, subStatus)
  subStatus = subStatus or 1
  local preRemoveStatus = self._linkedStatus[status]
  self._waittingRemove[status] = 1
  if preRemoveStatus then
    for _, v in ipairs(preRemoveStatus) do
      self:ClearStatus(v, opCode)
    end
  end
  self._waittingRemove[status] = nil
end

function StatusComponent:HasStatus(status, subStatus)
  if status == self._pendingStatus and subStatus == self._pendingSubStatus then
    return true
  end
  local statusValue = self._statusDic[status]
  if not statusValue or statusValue <= 0 then
    return false
  end
  if nil ~= subStatus and self._statusDic[status] ~= subStatus then
    return false
  end
  return true
end

function StatusComponent:HasAnyStatus(...)
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

function StatusComponent:HasAnyStatusExclude(...)
  local excludeStatus = {
    ...
  }
  for _status, _statusValue in pairs(self._statusDic) do
    if _statusValue and _statusValue > 0 and not table.contains(excludeStatus, _status) then
      return true
    end
  end
  return false
end

function StatusComponent:ClearStatus(status, opCode, subStatus)
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  local statusValue = self._statusDic[status] or 0
  if statusValue > 0 then
    if nil ~= subStatus and subStatus ~= self._statusDic[status] then
      return
    end
    self:ClearCachePreApplyStatus()
    self:PreRemoveStatus(status, opCode)
    subStatus = self._statusDic[status]
    self._statusDic[status] = nil
    self._statusParams[status] = nil
    self:SyncStatus(status, subStatus, opCode, true)
    self.owner:SendEvent(PlayerModuleEvent.ON_CLEAR_STATUS, status, subStatus, opCode)
    self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, subStatus, opCode)
  end
end

function StatusComponent:ClearStatusLocal(status, opCode, subStatus)
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
  local statusValue = self._statusDic[status] or 0
  if statusValue > 0 then
    if nil ~= subStatus and subStatus ~= self._statusDic[status] then
      return
    end
    self:ClearCachePreApplyStatus()
    self:PreRemoveStatus(status, opCode)
    subStatus = self._statusDic[status]
    self._statusDic[status] = nil
    self._statusParams[status] = nil
    self.owner:SendEvent(PlayerModuleEvent.ON_CLEAR_STATUS, status, subStatus, opCode)
    self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, subStatus, opCode)
  end
end

function StatusComponent:RefreshStatus(status, subStatus, opCode, customParams)
  if not self:HasStatus(status) then
    return
  end
  opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH
  self._statusParams[status] = customParams
  local synsParams = {}
  table.deepCopy(customParams, synsParams)
  self:SyncStatus(status, subStatus, opCode, nil, synsParams)
end

function StatusComponent:OnMovementModeChange(PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  if self._recovering then
    return
  end
  if PrevMovementMode == UE4.EMovementMode.MOVE_Swimming then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
  elseif PrevMovementMode == UE4.EMovementMode.MOVE_Falling then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
  elseif PrevMovementMode == UE4.EMovementMode.MOVE_Walking or PrevCustomMode == UE4.EMovementMode.MOVE_NavWalking then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED)
  elseif PrevMovementMode == UE4.EMovementMode.MOVE_Custom and PrevCustomMode == UE4.ERocoCustomMovementMode.MOVE_Climbing then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB_DASH)
  end
  if PrevMovementMode == UE4.EMovementMode.MOVE_Custom and PrevCustomMode == UE4.ERocoCustomMovementMode.MOVE_Sliping then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING)
  end
  if PrevMovementMode == UE4.EMovementMode.MOVE_Custom and PrevCustomMode == UE4.ERocoCustomMovementMode.MOVE_Mantling then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MANTLE)
  end
  if NewMovementMode == UE4.EMovementMode.MOVE_Swimming then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
  elseif NewMovementMode == UE4.EMovementMode.MOVE_Falling then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
  elseif NewMovementMode == UE4.EMovementMode.MOVE_Walking or NewMovementMode == UE4.EMovementMode.MOVE_NavWalking then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED)
  elseif NewMovementMode == UE4.EMovementMode.MOVE_Custom then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED)
  end
  if NewMovementMode == UE4.EMovementMode.MOVE_Custom and NewCustomMode == UE4.ERocoCustomMovementMode.MOVE_Sliping then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING)
  else
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING)
  end
  if NewMovementMode == UE4.EMovementMode.MOVE_Custom and NewCustomMode == UE4.ERocoCustomMovementMode.MOVE_Mantling then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_MANTLE, nil, self.owner.viewObj.CharacterMovement.MantleType + 1)
  else
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MANTLE)
  end
  if NewMovementMode == UE4.EMovementMode.MOVE_None then
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED)
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING)
    self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MANTLE)
  end
end

function StatusComponent:ResetViewObjMovementStatus()
  if self.owner.viewObj then
    local moveComponent = self.owner.viewObj:GetMovementComponent()
    self:InitMovementModeStatus(moveComponent.MovementMode, moveComponent.CustomMovementMode)
  else
    Log.Error("StatusComponent:ResetViewObjMovementStatus no viewObj")
  end
end

function StatusComponent:InitMovementModeStatus(MovementMode, CustomMode)
  local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER
  if MovementMode == UE4.EMovementMode.MOVE_Swimming then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING, opCode)
  elseif MovementMode == UE4.EMovementMode.MOVE_Falling then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING, opCode)
  elseif MovementMode == UE4.EMovementMode.MOVE_Walking or MovementMode == UE4.EMovementMode.MOVE_NavWalking then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED, opCode)
  end
  if MovementMode == UE4.EMovementMode.MOVE_Custom and CustomMode == UE4.ERocoCustomMovementMode.MOVE_Sliping then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING, opCode)
  end
  if MovementMode == UE4.EMovementMode.MOVE_Custom and CustomMode == UE4.ERocoCustomMovementMode.MOVE_Climbing then
    self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB, opCode)
  end
end

function StatusComponent:ClearAll()
  for k, v in pairs(self._statusDic) do
    local oldSubStatus = self._statusDic[k]
    self._statusDic[k] = 0
    self._statusParams[k] = {}
    local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
    self.owner:SendEvent(PlayerModuleEvent.ON_CLEAR_STATUS, k, oldSubStatus, opCode)
    self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, k, oldSubStatus, opCode)
  end
  self._statusDic = {}
  self._statusParams = {}
end

function StatusComponent:Destroy()
  self:ClearAll()
  self:ClearCachePreApplyStatus()
end

function StatusComponent:OnDisConnect()
  Log.Debug("StatusComponent DisConnect")
  self._isConnected = false
  for k, v in pairs(self._statusDic) do
    if k ~= ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
      self:ClearStatusLocal(k)
    end
  end
end

function StatusComponent:OnReConnect()
  Log.Error("StatusComponent:OnReConnect")
  self._isConnected = true
  self._shouldWaitRecover = true
  NRCModuleManager:DoCmd(PlayerModuleCmd.ClearCachedStatusChange)
  self:RecoverAllStatus()
  if self.owner.viewObj then
    local moveComponent = self.owner.viewObj:GetMovementComponent()
    self:InitMovementModeStatus(moveComponent.MovementMode, moveComponent.CustomMovementMode)
  end
  local logicStatusComponent = self.owner:EnsureComponent(LogicStatusComponent)
  if logicStatusComponent then
    local hasDoubleRideGuestStatus, _, _ = logicStatusComponent:GetStatus(ProtoEnum.SpaceActorLogicStatus.SALS_DOUBLE_RIDE_GUEST)
    if hasDoubleRideGuestStatus then
      _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_DOUBLE_RIDE_GUEST)
    else
      _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_DOUBLE_RIDE_GUEST)
    end
  end
  if not self.owner:IsInTogetherMove() and self.owner.InviteComponent then
    Log.Error("StatusComponent:OnReConnect InviteComponent RevertRestore")
    self.owner.InviteComponent:RevertRestore()
  end
end

function StatusComponent:IsMovementStatus(status)
  return status == ProtoEnum.WorldPlayerStatusType.WPST_LANDED or status == ProtoEnum.WorldPlayerStatusType.WPST_SLIDING or status == ProtoEnum.WorldPlayerStatusType.WPST_UNRIDE
end

function StatusComponent:SyncStatus(status, subStatus, opCode, clearFlag, customParam)
  if not self._isFixStatus and (not self._isConnected or self._recover_clearing) then
    return
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER then
    return
  end
  if self:IsMovementStatus(status) then
    return
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
    return
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH and status == ProtoEnum.WorldPlayerStatusType.WPST_FASHION_SUITS then
    return
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD then
    NRCModuleManager:DoCmd(PlayerModuleCmd.SyncLocalPlayerStatus, status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, nil, customParam)
    return
  end
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH then
    NRCModuleManager:DoCmd(PlayerModuleCmd.SyncLocalPlayerStatus, status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, nil, customParam)
    return
  end
  NRCModuleManager:DoCmd(PlayerModuleCmd.SyncLocalPlayerStatus, status, subStatus, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE, clearFlag, customParam)
end

function StatusComponent:RecoverAllStatus()
  if self.owner.serverData then
    Log.Warning("\230\156\172\229\156\176\231\142\169\229\174\182 \231\138\182\230\128\129\230\129\162\229\164\141")
    self._recovering = true
    Log.Dump(self.owner.serverData.avatar_status, 5, "RecoverAllStatus")
    if self._shouldWaitRecover then
      local serverInfo = self.owner.serverData.avatar_status
      self:FixStatusWhileReConnect()
      local serverStatus = serverInfo.status_list or {}
      local serverSubStatus = serverInfo.sub_status_list or {}
      local serverStatusParams = serverInfo.avatar_status_params
      self._recover_clearing = true
      local ignoreStatus = {}
      
      local function RemoveLocalStatus()
        local clearStatus = {}
        for k, v in pairs(self._statusDic) do
          if not table.contains(serverStatus, k) then
            table.insert(clearStatus, k)
          elseif k == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
            local subStatusIndex = table.indexOf(serverStatus, k)
            local statusParam = serverStatusParams[subStatusIndex]
            local localStatusParam = self._statusParams[k]
            if statusParam.ride_param.ride_pet_gid == localStatusParam.ride_param.ride_pet_gid and statusParam.ride_param.double_ride_2p_id == localStatusParam.ride_param.double_ride_2p_id then
              ignoreStatus[subStatusIndex] = serverStatus[subStatusIndex]
            else
              table.insert(clearStatus, k)
            end
          else
            table.insert(clearStatus, k)
          end
        end
        if 0 == #clearStatus then
          return true
        end
        for k, v in pairs(clearStatus) do
          self:ClearStatusLocal(v)
        end
        return false
      end
      
      if not RemoveLocalStatus() then
        RemoveLocalStatus()
      end
      self._recover_clearing = false
      local opCode = ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER
      if serverStatus and serverSubStatus then
        local postStatusList = {}
        for index, value in ipairs(serverStatus) do
          if ignoreStatus[index] then
          elseif self:CheckHasRequire(value) then
            table.insert(postStatusList, value)
          elseif not self:IsMovementStatus(value) then
            self:ApplyStatusInternalLocal(value, opCode, serverSubStatus[index], serverStatusParams[index])
            if value == ProtoEnum.WorldPlayerStatusType.WPST_CLIMB then
              self.owner.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
              self.owner.viewObj.CharacterMovement:TryClimbWhileOffClimbPet(0)
            end
          end
        end
        if #postStatusList > 0 then
          for index, value in ipairs(postStatusList) do
            self:ApplyStatusInternalLocal(value, opCode, 1)
          end
        end
      end
      self._shouldWaitRecover = false
      self.owner:SendEvent(PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH)
    end
    self._recovering = false
  end
  self.owner._bearing = false
  self.owner:LandPos(self.owner.viewObj:Abs_K2_GetActorLocation())
end

function StatusComponent:FixStatusWhileReConnect(isFirstAttach)
  if not self.owner or not self.owner.serverData then
    Log.Error("\231\138\182\230\128\129\231\179\187\231\187\159\233\135\141\229\187\186\229\136\157\229\167\139\231\159\169\233\152\181\229\164\177\232\180\165\239\188\140\230\151\160serverData")
    return
  end
  self._isFixStatus = true
  local serverInfo = self.owner.serverData.avatar_status
  serverInfo.status_list = serverInfo.status_list or {}
  serverInfo.sub_status_list = serverInfo.sub_status_list or {}
  serverInfo.avatar_status_params = serverInfo.avatar_status_params or {}
  
  local function serverHasStatus(targetStatus)
    for index, v in ipairs(serverInfo.status_list) do
      if v == targetStatus then
        return index
      end
    end
    return -1
  end
  
  local FixOptionList = {}
  if isFirstAttach then
    local hasTransform = false
    for index, value in ipairs(serverInfo.status_list) do
      local shouldRemove = true
      if value == ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM then
        hasTransform = true
        shouldRemove = false
      end
      if value == ProtoEnum.WorldPlayerStatusType.WPST_DEATH then
        shouldRemove = false
      end
      if value == ProtoEnum.WorldPlayerStatusType.WPST_BATTLE then
        shouldRemove = false
      end
      if value == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
        local params = serverInfo.avatar_status_params[index]
        if params.ride_param.ride_pet_gid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Friend then
          shouldRemove = true
        end
        if params.ride_param.ride_move_mode == ProtoEnum.SceneRideAllType.SRAT_GROUND or params.ride_param.ride_move_mode == ProtoEnum.SceneRideAllType.SRAT_SWIM then
          shouldRemove = false
        else
          hasTransform = hasTransform or serverHasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) > -1
          if hasTransform then
            shouldRemove = false
          end
        end
      end
      if shouldRemove then
        table.insert(FixOptionList, {
          value,
          serverInfo.sub_status_list[index],
          ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
        })
      end
    end
  end
  local LogicStatusList = self.owner.serverData.status_info
  local isDeath = false
  local isBattle = false
  local isTransform = false
  for _, v in ipairs(LogicStatusList) do
    if v.status == ProtoEnum.SpaceActorLogicStatus.SALE_REVIVE then
      isDeath = true
    end
    if v.status == ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING then
      isBattle = true
    end
    if v.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRANSFORM then
      isTransform = v.extra_data
    end
  end
  local hasDeath = false
  local hasBattle = false
  local hasTransform = false
  for index, value in ipairs(serverInfo.status_list) do
    if value == ProtoEnum.WorldPlayerStatusType.WPST_DEATH then
      hasDeath = true
      if not isDeath then
        table.insert(FixOptionList, {
          ProtoEnum.WorldPlayerStatusType.WPST_DEATH,
          1,
          ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
        })
      end
    end
    if value == ProtoEnum.WorldPlayerStatusType.WPST_BATTLE then
      hasBattle = true
      if not isBattle then
        table.insert(FixOptionList, {
          ProtoEnum.WorldPlayerStatusType.WPST_BATTLE,
          1,
          ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
        })
      end
    end
    if value == ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM then
      hasTransform = true
      if not isTransform then
        table.insert(FixOptionList, {
          ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM,
          1,
          ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE
        })
      end
    end
  end
  if isDeath and not hasDeath then
    table.insert(FixOptionList, {
      ProtoEnum.WorldPlayerStatusType.WPST_DEATH,
      1,
      ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
    })
  end
  if isBattle and not hasBattle then
    table.insert(FixOptionList, {
      ProtoEnum.WorldPlayerStatusType.WPST_BATTLE,
      1,
      ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD
    })
  end
  if isTransform and not hasTransform then
    Log.Debug("\233\156\128\232\166\129\230\129\162\229\164\141\229\143\152\229\189\162\231\138\182\230\128\129\239\188\129\239\188\129\239\188\129\239\188\129")
    table.insert(FixOptionList, {
      ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM,
      1,
      ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD,
      {
        transform_param = {
          transform_cfg_id = isTransform.transform_cfg_id
        }
      }
    })
  end
  for _, FixOption in ipairs(FixOptionList) do
    Log.Debug("[StatusComponent] fix player status:", FixOption[1], FixOption[2], FixOption[3])
    self:ChangeServerData(nil, FixOption[1], FixOption[2], FixOption[3], FixOption[4])
    self:SyncStatus(FixOption[1], FixOption[2], FixOption[3], nil, FixOption[4])
  end
  local RideIndex = serverHasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if RideIndex > -1 then
    local params = serverInfo.avatar_status_params[RideIndex]
    if params.ride_param.double_ride_2p_id ~= nil and params.ride_param.double_ride_2p_id >= 0 then
      params.ride_param.double_ride_2p_id = 0
      self:SyncStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, nil, params)
    end
  end
  self._isFixStatus = false
end

function StatusComponent:CheckHasRequire(status)
  local requiredStatus = self._requiredStatus[status]
  if requiredStatus then
    for i, v in ipairs(requiredStatus) do
      if not self:HasStatus(v) then
        return true
      end
    end
  end
  return false
end

function StatusComponent:GetScenePlayerStatusMatrix(status)
  local configIndex = self._statusToConfigIndex[status]
  return self._statusTable[configIndex]
end

function StatusComponent:OnReceiveSyncAction(act)
  for _, info in pairs(act.sync_status_info_list) do
    local opCode = info.op_code
    local params = info.custom_status_param
    local status = info.status
    local subStatus = 1
    if info.sub_status and info.sub_status > 0 then
      subStatus = info.sub_status
    end
    self:ChangeServerData(info, status, subStatus, opCode, params)
    if self._shouldWaitRecover then
      return
    end
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD then
      self:ApplyStatus(status, opCode, subStatus, params)
    end
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
      self:RemoveStatus(status, opCode, subStatus, params)
    end
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH and status == ProtoEnum.WorldPlayerStatusType.WPST_FASHION_SUITS then
      self:ApplyStatus(status, opCode, subStatus, params)
    end
    if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REFRESH and status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
      opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH
      local originStatusValue = self._statusDic[status] or 0
      if originStatusValue <= 0 then
        return
      end
      opCode = opCode or ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH
      self._statusParams[status] = params
      self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_REFRESH, status, originStatusValue, opCode)
      self.owner:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, originStatusValue, opCode)
    end
  end
end

function StatusComponent:GetCustomParams(status)
  return self._statusParams[status]
end

function StatusComponent:ChangeServerData(act, status, subStatus, opCode, params)
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

function StatusComponent:OnLogicStatusChange(ChangeInfo)
  if not ChangeInfo then
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALE_REVIVE then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
    end
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_BATTLE)
    end
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRANSFORM then
    Log.Debug("\229\143\152\229\189\162\231\138\182\230\128\129\229\143\152\230\155\180\239\188\129\239\188\129\239\188\129\239\188\129")
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD then
      self:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, 1, {
        transform_param = {
          transform_cfg_id = ChangeInfo.changed_status.extra_data.transform_cfg_id
        }
      })
      if not self:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
        local req = _G.ProtoMessage:newZoneSceneCancelPlayerTransformReq()
        req.cancel_reason = ProtoEnum.PlayerTransformCancelReason.PTCR_STATUS_BAN
        _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CANCEL_PLAYER_TRANSFORM_REQ, req, true, false)
      end
    end
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      local customParams = self:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
      customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
      if not customParams.transform_param then
        customParams.transform_param = ProtoMessage:newPlayerTransformStatusParams()
      end
      customParams.transform_param.cancel_reason = ChangeInfo.changed_status.extra_data.transform_end_reason
      self:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
      self:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE, 1, {
        transform_param = {
          cancel_reason = ChangeInfo.changed_status.extra_data.transform_end_reason
        }
      })
      self.owner.serverData.avatar_status.end_transform_time = _G.ZoneServer:GetServerTime()
    end
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_WAIT_FOR_OTHERS then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD then
      self.owner:OnWaitForOtherStatus(true)
      _G.FunctionBanManager:AddPlayerConditionType(_G.Enum.PlayerConditionType.PCT_WAIT_FOR_OTHERS)
    elseif ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      self.owner:OnWaitForOtherStatus(false)
      _G.FunctionBanManager:RemovePlayerConditionType(_G.Enum.PlayerConditionType.PCT_WAIT_FOR_OTHERS)
    end
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_TELEPORT_TOGETHER then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD then
      Log.Error("[TogetherTeleport] StatusComponent:OnLogicStatusChange Add SALS_TELEPORT_TOGETHER")
      if self._restoreTogether then
        self:InterruptRestoreTogether()
      end
    elseif ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      Log.Error("[TogetherTeleport] StatusComponent:OnLogicStatusChange REMOVE SALS_TELEPORT_TOGETHER")
      if self._restoreTogether then
        self:InterruptRestoreTogether()
      end
    end
    return
  end
  if ChangeInfo.changed_status.status == ProtoEnum.SpaceActorLogicStatus.SALS_DOUBLE_RIDE_GUEST then
    if ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD then
      _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_DOUBLE_RIDE_GUEST)
    elseif ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
      _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_DOUBLE_RIDE_GUEST)
    end
    return
  end
end

function StatusComponent:OnPreTeleportNotify()
  local scene = NRCModuleManager:GetModule("SceneModule")
  if not scene or scene.bNoLoadingTeleport then
    return
  end
  self.owner:StopRide()
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
end

return StatusComponent
