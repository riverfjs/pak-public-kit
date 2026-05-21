require("UnLuaEx")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local MagicAbilityBaseHelper = require("NewRoco.Modules.Core.Scene.Component.Ability.Helper.Magic.MagicAbilityBaseHelper")
local WorldCombatSkillComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local BP_PlayerController_C = NRCClass:Extend("BP_PlayerController_C")

function BP_PlayerController_C:Destruct()
end

function BP_PlayerController_C:ReceiveTick(DeltaSeconds)
  if RocoEnv.IS_EDITOR and self.CurrentMouseCursor ~= self.DefaultMouseCursor then
    self.CurrentMouseCursor = self.DefaultMouseCursor
  end
end

function BP_PlayerController_C:ReceiveBeginPlay()
  Log.Debug("BP_PlayerController begin play")
  self.Overridden.ReceiveBeginPlay(self)
  self.Unclickables = {}
  WeakTable(self.Unclickables)
  self.KeyDict = {}
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_Eject")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "ChangeUAV")
  ScenePlayerInputManager.PlayerContronBeginPlay()
end

function BP_PlayerController_C:ChangeUAV()
  if _G.App.BanOpenUAV then
    return
  end
  self.CameraActor:ChangeUAV()
end

function BP_PlayerController_C:ReceiveEndPlay()
  Log.Debug("BP_PlayerController end play")
  local localPlayer = _G.PlayerModuleCmd and _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnStatusRemove)
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnStatusRemove)
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE_RAW, self.OnPlayerHpChanged)
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ROLE_HP_MAX_CHANGE_RAW, self.OnPlayerMaxHpChanged)
    localPlayer:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusChanged)
  end
end

function BP_PlayerController_C:ReceiveDestroyed()
  if self.BP_RocoCameraControlComponent then
    self.BP_RocoCameraControlComponent:RemoveEventListener()
  end
  self.Overridden.ReceiveDestroyed(self)
end

function BP_PlayerController_C:OnCreateLocalPlayer()
  Log.Debug("BP_PlayerController OnCreateLocalPlayer")
  self._playerModule = NRCModuleManager:GetModule("PlayerModule")
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    self._inputComponent = localPlayer.inputComponent
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnStatusRemove)
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnStatusRemove)
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE_RAW, self.OnPlayerHpChanged)
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_ROLE_HP_MAX_CHANGE_RAW, self.OnPlayerMaxHpChanged)
    localPlayer:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusChanged)
    local statusComp = localPlayer.statusComponent
    if statusComp and statusComp._statusParams then
      local all_status = {}
      for status, param in pairs(statusComp._statusParams) do
        all_status[status] = self:GatherParamByStatus(status, param)
      end
      self:ResetDotsStatus(all_status)
    end
    local roleHpComp = localPlayer.roleHPComponent
    if roleHpComp then
      self._cachedHp = roleHpComp:GetRoleHP()
      self._cachedMaxHp = roleHpComp:GetMaxVRoleHP()
      self:SetDotsPlayerHp(self._cachedHp, self._cachedMaxHp)
    end
    self:OnLogicStatusChanged(localPlayer)
  else
    Log.Debug("BP_PlayerController GetPlayer failed")
  end
  if self.BP_RocoCameraControlComponent then
    self.BP_RocoCameraControlComponent:Attach()
  end
  self.PlayerCameraManager:Attach()
end

function BP_PlayerController_C:OnStatusApply(status, statusValue, opCode, customParam, ...)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseCompass, true)
  end
  self:SetDotsStatus(status, true, self:GatherParamByStatus(status, customParam))
end

function BP_PlayerController_C:GatherParamByStatus(_status, _customParam)
  if not _customParam then
    return 0
  end
  if _status == Enum.WorldPlayerStatusType.WPST_MAGIC then
    return _customParam.throw_aim_param and _customParam.throw_aim_param.magic_conf_id or 0
  elseif _status == Enum.WorldPlayerStatusType.WPST_TRANSFORM then
    return _customParam.transform_param and _customParam.transform_param.transform_cfg_id or 0
  elseif _status == Enum.WorldPlayerStatusType.WPST_RIDEALL then
    return _customParam.ride_param and _customParam.ride_param.ride_pet_id or 0
  elseif _status == Enum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local skillId = _customParam.ride_skill_param.skill_id
    local SkillConf = _G.DataConfigManager:GetRideBasicMovement(skillId, true)
    if nil == SkillConf then
      return 0
    end
    return SkillConf.active_type or 0
  elseif _status == Enum.WorldPlayerStatusType.WPST_FASHION_SUITS then
    return _customParam.ai_param or 0
  end
  return 0
end

function BP_PlayerController_C:OnStatusRemove(status, value, type)
  if nil == status then
    Log.Error("BP_PlayerController_C:OnStatusRemove status is nil, \230\128\142\228\185\136\228\188\154\229\145\162\239\188\129\239\188\129")
    return
  end
  self:SetDotsStatus(status, false, 0)
end

function BP_PlayerController_C:OnPlayerHpChanged(hp)
  self._cachedHp = hp
  self:SetDotsPlayerHp(hp, self._cachedMaxHp)
end

function BP_PlayerController_C:OnPlayerMaxHpChanged(maxHp)
  self._cachedHp = maxHp
  self._cachedMaxHp = maxHp
  self:SetDotsPlayerHp(maxHp, maxHp)
end

function BP_PlayerController_C:OnLogicStatusChanged(owner, changeInfo)
  if changeInfo then
    if _G.AIDefines.DotsPlayerSalsNeedsToCopy[changeInfo.changed_status.status] then
      if changeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD or changeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_UPDATE then
        local statusInfo = changeInfo.changed_status
        local payload = {
          [statusInfo.status] = statusInfo.extra_data and statusInfo.extra_data.ai_param or 0
        }
        self:SetDotsLogicStatus(payload, 1)
      elseif changeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
        self:SetDotsLogicStatus({
          [changeInfo.changed_status.status] = 0
        }, 2)
      end
    end
  else
    local LogicStatusComp = owner and owner.LogicStatusComponent
    if not LogicStatusComp then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      LogicStatusComp = player.LogicStatusComponent
    end
    if LogicStatusComp then
      local all_status = {}
      for _, info in ipairs(LogicStatusComp.StatusInfo) do
        if _G.AIDefines.DotsPlayerSalsNeedsToCopy[info.status] then
          all_status[info.status] = info.extra_data and info.extra_data.ai_param or 0
        end
      end
      self:SetDotsLogicStatus(all_status, 0)
    end
  end
end

function BP_PlayerController_C:ClickUnclickable()
  for k, v in pairs(self.Unclickables) do
    if k and v then
      v(k, self.ClickPos)
    end
  end
end

function BP_PlayerController_C:RmvUnclickable(user)
  self.Unclickables[user] = nil
end

function BP_PlayerController_C:ClearUnclickable()
  self.Unclickables = {}
end

function BP_PlayerController_C:AddUnclickable(user, func)
  self.Unclickables[user] = func
end

function BP_PlayerController_C:ResetCamera()
  local rotator = self.Pawn:K2_GetActorRotation()
  rotator.Pitch = -20
  rotator.Roll = 0
  self:SetControlRotation(rotator)
end

function BP_PlayerController_C:SetAutoMVT(AutoManage)
  self.bAutoManageActiveCameraTarget = AutoManage
  Log.Debug("SetAutoManageActiveCameraTarget " .. tostring(AutoManage))
end

function BP_PlayerController_C:DebugPanelManagement(IsOpen)
  if _G.AppMain:HasDebug() then
    _G.NRCModeManager:DoCmd(_G.DebugModuleCmd.OpenOrClosePanel, IsOpen)
  end
end

function BP_PlayerController_C:DebugSpawnNpc(npcId, location, yaw, skillId)
  Log.Debug("BP_PlayerController_C:DebugSpawnNpc", npcId, location, yaw, skillId)
  local SkillDebugNpc = require("NewRoco.Modules.Core.Scene.Actor.SkillDebugNpc")
  local npcConf = _G.DataConfigManager:GetNpcConf(npcId)
  if not npcConf then
    Log.Error("BP_PlayerController_C:DebugSpawnNpc. Given NpcId cannot get npc config!", npcId, location, yaw, skillId)
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerPos = Player:GetActorLocationFrameCache()
  local playerYaw = Player:GetActorRotationFrameCache():ToRotator().Yaw
  local transform = UE4.FTransform(UE4.FRotator(0, yaw or playerYaw, 0):ToQuat(), playerPos)
  local npc = SkillDebugNpc.CreateNpc(nil, Player.viewObj, npcConf, nil, transform, nil, nil)
  local halfHeight = npc:GetScaledHalfHeight()
  local finalPos = location
  if not finalPos or finalPos == UE4.FVector(0, 0, 0) then
    finalPos = playerPos + Player:GetActorRotationFrameCache():ToRotator():ToVector() * 500
  end
  finalPos = SceneUtils.GetPosInLand(finalPos, halfHeight, halfHeight * 2, halfHeight * 10, {
    Player.viewObj
  }, {}, nil, true, true, true) or finalPos
  npc:SetActorLocation(finalPos)
  local debugInfo = "[WorldCombatDebugInfo]:\n"
  debugInfo = string.format([[
%s ActorId: %d, NpcId: %d,
Location: %s,
Yaw: %f, SkillId: %d]], debugInfo, npc.ActorId, npcId, finalPos, yaw, skillId)
  local World = Player.viewObj:GetWorld()
  UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, UE.FVector(0, 0, halfHeight + 50), debugInfo, npc.viewObj, UE4.FLinearColor(1, 1, 0, 1), -1)
  if skillId and skillId > 0 then
    npc:EnsureComponent(WorldCombatSkillComponent):TryCastSkill(skillId, Player, playerPos, true)
  end
end

function BP_PlayerController_C:DebugCastSkill(actorId, skillId, targetId, creatureSkillId, recycleUse, cycleIntervalTime, skillRange)
  Log.Debug("BP_PlayerController_C:DebugCastSkill", actorId, skillId, targetId)
  local SkillDebugNpc = require("NewRoco.Modules.Core.Scene.Actor.SkillDebugNpc")
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local npc = SkillDebugNpc.GetNpcByActorId(actorId)
  if not npc then
    Log.Error("BP_PlayerController_C:DebugCastSkill npc not found!!!")
    return
  end
  local target = SkillDebugNpc.GetNpcByActorId(targetId) or Player
  local targetPos = target:GetActorLocation()
  local skillStart = skillRange and skillRange[1] or skillId
  local skillEnd = skillRange and skillRange[2] or skillId
  cycleIntervalTime = cycleIntervalTime or 10
  npc:FaceTo(target.viewObj)
  npc.initDebugPos = npc:GetActorLocation()
  SceneUtils:DebugOpenCollision(npc.viewObj)
  SceneUtils:DebugOpenCollision(target.viewObj)
  npc:ClearTimers()
  local maxCycle = 0
  if recycleUse then
    maxCycle = 100
  end
  local idx = 0
  for i = 0, maxCycle do
    local WorldCombatSkillEvent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillEvent")
    for skillIdTemp = skillStart, skillEnd do
      local delayTimer = _G.DelayManager:DelaySeconds(cycleIntervalTime * idx, function()
        npc:EnsureComponent(WorldCombatSkillComponent):TryCastSkill(skillIdTemp, target, targetPos, true, {creatureSkillId = creatureSkillId})
        if not npc:HasListener(npc, WorldCombatSkillEvent.SKILL_CAST_END, npc.OnDebugSkillEnd) then
          npc:AddEventListener(npc, WorldCombatSkillEvent.SKILL_CAST_END, npc.OnDebugSkillEnd)
        end
        npc.currDebugSkillId = skillIdTemp
        local debugInfo = "[WorldCombatDebugInfo]:\n"
        debugInfo = string.format([[
%s ActorId: %d, NpcId: %d,
Location: %s,
Yaw: %f, SkillId: %d]], debugInfo, npc.ActorId, npc.config.id, npc:GetActorLocation(), npc:GetActorRotation().Yaw, skillIdTemp)
        local World = Player.viewObj:GetWorld()
        UE.UNRCStatics.RemoveDebugTextByActor(npc.viewObj)
        UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, UE.FVector(0, 0, npc:GetScaledHalfHeight() + 50), debugInfo, npc.viewObj, UE4.FLinearColor(1, 1, 0, 1), -1)
      end)
      table.insert(npc.timerIds, delayTimer)
      idx = idx + 1
    end
  end
end

function BP_PlayerController_C:DebugDestroyNpc(actorId)
  local SkillDebugNpc = require("NewRoco.Modules.Core.Scene.Actor.SkillDebugNpc")
  local npc = SkillDebugNpc.GetNpcByActorId(actorId)
  if not npc then
    Log.Error("BP_PlayerController_C:DebugDestroyNpc npc not found!!!")
    return
  end
  UE.UNRCStatics.RemoveDebugTextByActor(npc.viewObj)
  SkillDebugNpc.RemoveNpc(npc)
end

function BP_PlayerController_C:GetShortcutKey(_Key, IsPressed)
  local Key = _Key
  if IsPressed then
    table.insert(self.KeyDict, Key)
    if not RocoEnv.IS_SHIPPING then
      local DebugModule = _G.NRCModuleManager:GetModule("DebugModule")
      if DebugModule then
        _G.NRCModeManager:DoCmd(_G.DebugModuleCmd.ShortcutKeyMatching, self.KeyDict)
      end
    end
  else
    for i, v in ipairs(self.KeyDict) do
      if v == Key then
        table.remove(self.KeyDict, i)
      end
    end
  end
end

function BP_PlayerController_C:RequestRocoCamera(BlendTime, BlendFunc, BlendExp)
  BlendTime = BlendTime or 0
  BlendFunc = BlendFunc or UE4.EViewTargetBlendFunction.VTBlend_Linear
  BlendExp = BlendExp or 0
  self.PlayerCameraManager:UseBigWorldCamera(false)
  self:SetViewTargetWithBlend(self.CameraActor, BlendTime, BlendFunc, BlendExp)
  self.CameraActor:K2_DetachFromActor(UE4.EDetachmentRule.KeepWorld, UE4.EDetachmentRule.KeepWorld, UE4.EDetachmentRule.KeepWorld)
  local KamComp = self.CameraActor:GetComponentByClass(UE4.UCameraComponent)
  KamComp:ResetRelativeTransform()
  return self.CameraActor
end

function BP_PlayerController_C:ChangeToCustomCamera(CustomCamera, BlendTime, BlendFunc, BlendExp, BlockOutgoing)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  BlendTime = BlendTime or 0
  BlendFunc = BlendFunc or UE4.EViewTargetBlendFunction.VTBlend_Linear
  BlendExp = BlendExp or 0
  if UE4.UObject.IsValid(self.PlayerCameraManager) then
    self.PlayerCameraManager:UseBigWorldCamera(false)
  else
    Log.Error("BP_PlayerController_C:ChangeToCustomCamera PlayerCameraManager is nil")
  end
  self:SetViewTargetWithBlend(CustomCamera, BlendTime, BlendFunc, BlendExp, BlockOutgoing)
end

function BP_PlayerController_C:ReleaseRocoCamera(BlendTime, BlendFunc, BlendExp, BlendBackImmediately)
  BlendTime = BlendTime or 0
  BlendFunc = BlendFunc or UE4.EViewTargetBlendFunction.VTBlend_Linear
  BlendExp = BlendExp or 0
  self.PlayerCameraManager:UseBigWorldCamera(true)
  if BlendBackImmediately then
    self.PlayerCameraManager.blendBackImmediately = true
  end
  self:SetViewTargetWithBlend(self, BlendTime, BlendFunc, BlendExp)
  if self.CameraActor then
    self.CameraActor:K2_AttachToActor(self.Pawn, nil, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, false)
  end
end

function BP_PlayerController_C:ChangeRocoCameraFadeRange(minDis, maxDis)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.PlayerCameraManager.CommonFadeMinDistance = minDis or 100
  self.PlayerCameraManager.CommonFadeMaxDistance = maxDis or 150
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.FadeComponent:SetFadeRange(minDis, maxDis)
end

function BP_PlayerController_C:SetFadeEnable(enable)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if not self.PlayerCameraManager or not UE4.UObject.IsValid(self.PlayerCameraManager) then
    return
  end
  Log.Debug("BP_PlayerController_C:SetFadeEnable ", enable)
  self.PlayerCameraManager.bEnableCommonFade = enable
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.FadeComponent:EnableCommonFade(enable)
end

function BP_PlayerController_C:ResetCtrlRotation(ResetSpeed, ErrorTolerance, RotationOverride)
  self.BP_RocoCameraControlComponent:OnResetRotation(ResetSpeed, ErrorTolerance, RotationOverride)
end

function BP_PlayerController_C:StopResetCtrlRotation()
  self.BP_RocoCameraControlComponent:OnStopResetRotation()
end

function BP_PlayerController_C:SetUICameraState(UIState)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.PlayerCameraManager == nil then
    return
  end
  self.PlayerCameraManager:SetUIStat(UIState)
end

function BP_PlayerController_C:BlueprintInputAxisEvent(name, value)
  ScenePlayerInputManager.BlueprintInputAxisEvent(name, value)
end

function BP_PlayerController_C:BlueprintInputActionEvent(name, type)
  ScenePlayerInputManager.BlueprintInputActionEvent(name, type)
end

function BP_PlayerController_C:MoveInputActionEvent(actionName, actionValue)
  if 0 ~= actionValue then
    local dir = "MoveRight" == actionName and {X = 1, Y = 0} or {X = 0, Y = -1}
    if self._playerModule then
      self._playerModule:DispatchEvent(PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, dir, actionValue)
    end
  end
end

function BP_PlayerController_C:BlueprintSetPCModeEvent(isPCMode)
  NRCEventCenter:DispatchEvent("OnSetPCMode", isPCMode)
end

function BP_PlayerController_C:OnLuaLostFocus()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:SendEvent(PlayerModuleEvent.ON_LOST_FOCUS)
  end
end

function BP_PlayerController_C:BlueprintPreNonAxisInput(actionName, key, inputEvent)
  if self._playerModule then
    self._playerModule:DispatchEvent(PlayerModuleEvent.ON_INPUT_KEY, actionName, key, inputEvent)
  end
end

function BP_PlayerController_C:BlueprintPreAxisInput(actionName)
  if self._playerModule then
    self._playerModule:DispatchEvent(PlayerModuleEvent.ON_INPUT_AXIS, actionName)
  end
end

function BP_PlayerController_C:SetIsSideView(isSideView)
  if self.bIsSIdeView == isSideView then
    return
  end
  self.bIsSideView = isSideView
  if self.bIsSideView then
    local Rot = UE4.FRotator()
    Rot.Yaw = 180
    Rot.Pitch = 5
    self:SetControlRotation(Rot)
    if self.PlayerCameraManager then
      self.PlayerCameraManager:BeginSideView()
    end
  elseif self.PlayerCameraManager then
    self.PlayerCameraManager:LeaveSideView()
  end
end

function BP_PlayerController_C:IsSideView()
  return self.bIsSideView
end

function BP_PlayerController_C:IsCameraControlDisabled()
  if self:IsSideView() then
    return true
  end
  return false
end

return BP_PlayerController_C
