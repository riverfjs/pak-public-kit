local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local VitalityUtil = require("NewRoco.Modules.Core.Scene.Component.Vitality.VitalityUtil")
local STATE = {
  None = 1,
  Climbing = 2,
  CDing = 3
}
local COOL_DOWN = 1
local ClimbComponent = Base:Extend("ClimbComponent")

function ClimbComponent:Attach(owner)
  Base.Attach(self, owner)
  self.owner:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChanged)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_MANIPULATE_CAMERA, self.OnManipulateCamera)
  local isClimbing = self.owner.viewObj.CharacterMovement:IsClimbing()
  if isClimbing then
    self._state = STATE.Climbing
  else
    self._state = STATE.None
  end
  self._cdLeft = 0
  self.AdjustCameraCD = 2
  self.basic_movement_conf = DataConfigManager:GetRideBasicMovement(5)
  self.owner:SendEvent(PlayerModuleEvent.ON_UPDATE_VITALITY_COST, ProtoEnum.WorldPlayerStatusType.WPST_CLIMB, 5)
  local abilityHelper = AbilityHelperManager.GetHelper(AbilityID.CLIMB)
  self.climb_disable_env_config = abilityHelper.config.disable_env
  self.normalLeafHideDistance = _G.DataConfigManager:GetGlobalConfigByKeyType("normalleaf_hidden_distance", _G.DataConfigManager.ConfigTableId.MAP_GLOBAL_CONFIG).num
  self.climbLeafHideDistance = _G.DataConfigManager:GetGlobalConfigByKeyType("climbleaf_hidden_distance", _G.DataConfigManager.ConfigTableId.MAP_GLOBAL_CONFIG).num
  UE4.UNRCStatics.SetLeafHideDistance(self.normalLeafHideDistance)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_VITALITY_OVER, self.OnVitalityOver)
end

function ClimbComponent:OnVitalityOver()
  if self._state == STATE.Climbing then
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
    self._cdLeft = COOL_DOWN
    self._state = STATE.CDing
  end
end

function ClimbComponent:Update(deltaTime)
  if self.owner.viewObj == nil then
    return
  end
  if self._state == STATE.Climbing then
    if self.lastCanClimbDown ~= false then
      self.owner:SendEvent(PlayerModuleEvent.ON_CLIMB_DOWN, false)
      self.lastCanClimbDown = false
    end
    if self.owner.viewObj.CharacterMovement:IsClimbUpLedge() then
      self.owner.movementComponent:SetIsMoving(true, "ClimbSync")
    end
  elseif self._state == STATE.CDing then
    if self._cdLeft > 0 then
      self._cdLeft = self._cdLeft - deltaTime
    else
      self._state = STATE.None
    end
  else
    local canClimbDown = self.owner.viewObj.CharacterMovement.bWantsToClimbDown
    local EnvDisable = false
    if self.climb_disable_env_config then
      local disable_env = 0
      for _, v in pairs(self.climb_disable_env_config) do
        disable_env = disable_env | v
      end
      local isEnvMask = DataModelMgr.PlayerDataModel.envMask & disable_env
      if isEnvMask > 0 then
        EnvDisable = true
      end
    end
    if self.lastCanClimbDown ~= canClimbDown and not EnvDisable then
      self.owner:SendEvent(PlayerModuleEvent.ON_CLIMB_DOWN, canClimbDown)
      self.lastCanClimbDown = canClimbDown
    end
  end
end

function ClimbComponent:OnMovementModeChanged(PreMoveMode, CurMoveMode, PreCustomMode, CurCustomMode)
  if CurCustomMode == UE4.ERocoCustomMovementMode.MOVE_Climbing then
    self._state = STATE.Climbing
    local player = self.owner
    player.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
    player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
    UE4.UNRCStatics.SetLeafHideDistance(self.climbLeafHideDistance)
    self:AdjustCamera()
    self.owner.movementComponent:SetIsMoving(false, "ClimbSync")
  else
    if CurMoveMode == UE4.EMovementMode.MOVE_Falling and PreCustomMode == UE4.ERocoCustomMovementMode.MOVE_Climbing then
      UE4.UNRCStatics.SetLeafHideDistance(self.climbLeafHideDistance)
    else
      UE4.UNRCStatics.SetLeafHideDistance(self.normalLeafHideDistance)
    end
    if self._state == STATE.Climbing then
      self._cdLeft = COOL_DOWN
      self._state = STATE.CDing
    end
    self.owner.movementComponent:SetIsMoving(false, "ClimbSync")
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB_DASH)
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
  end
end

function ClimbComponent:HasMove()
  local player = self.owner.viewObj
  return player.CharacterMovement.Velocity:Size() > 0
end

function ClimbComponent:IsInCD()
  return self._state == STATE.CDing
end

function ClimbComponent:CanClimb()
  if self:IsInCD() then
    return false, "In CD"
  end
  if self.basic_movement_conf then
    local minStartVitality = self.basic_movement_conf.vitality_cost.min_start or 0
    if not self.owner.vitalityComponent:IsVitalityEnough(minStartVitality) then
      return false, "Less Vitality"
    end
  end
  if self.owner.viewObj.AimState then
    return false, "AimState"
  end
  if self.climb_disable_env_config then
    local disable_env = 0
    for _, v in pairs(self.climb_disable_env_config) do
      disable_env = disable_env | v
    end
    local isEnvMask = DataModelMgr.PlayerDataModel.envMask & disable_env
    if isEnvMask > 0 then
      return false, "EnvMask"
    end
  end
  local player = self.owner
  local success, overrideValues, opCode = player.statusComponent:PreApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
  if not success then
    return false, "Status Conflict"
  end
  return success, ""
end

function ClimbComponent:AdjustCamera()
  local controller = self.owner:GetUEController()
  local cameraManager = controller.PlayerCameraManager
  local cameraDirection = cameraManager:GetCameraRotation():ToVector()
  local ClimbDirection = self.owner.viewObj:GetActorUpVector()
  local dot = cameraDirection:Dot(ClimbDirection)
  if dot < -0.5 then
  end
end

function ClimbComponent:OnManipulateCamera()
  self.AdjustCameraCD = 2
end

return ClimbComponent
