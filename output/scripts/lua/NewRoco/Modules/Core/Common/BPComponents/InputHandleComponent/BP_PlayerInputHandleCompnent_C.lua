local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RolePlayModuleCmd = require("NewRoco.Modules.System.RolePlay.RolePlayModuleCmd")
require("UnLuaEx")
local BP_PlayerInputHandleCompnent_C = NRCClass()

function BP_PlayerInputHandleCompnent_C:Ctor()
end

function BP_PlayerInputHandleCompnent_C:ReceiveBeginPlay()
  self.Overridden.ReceiveBeginPlay(self)
  self.playerController = self:GetOwner():GetController()
end

function BP_PlayerInputHandleCompnent_C:OnPlayerAccelerate()
  local pawn = self:GetOwner()
  pawn.ShiftSprint = not pawn.ShiftSprint
end

function BP_PlayerInputHandleCompnent_C:CastAbility(ability)
  local abilityComponent = self:GetOwner().sceneCharacter.abilityComponent
  abilityComponent:CastAbility(ability)
  return true
end

function BP_PlayerInputHandleCompnent_C:StopAbility(ability)
  local abilityComponent = self:GetOwner().sceneCharacter.abilityComponent
  abilityComponent:StopAbility(false)
  return true
end

function BP_PlayerInputHandleCompnent_C:TouchMove(dir, value)
  local ueCtrl = self.playerController
  if ueCtrl then
    local x = dir.X
    local y = ueCtrl:IsSideView() and 0 or dir.Y
    self:UpdateDirection()
    local direction = -self.forward * y + self.right * x
    self:Move(direction, value)
  end
  return true
end

function BP_PlayerInputHandleCompnent_C:MoveForward(value)
  local ueCtrl = self.playerController
  if not ueCtrl or ueCtrl:IsSideView() then
    return false
  end
  if 0 ~= value then
    self:UpdateDirection()
    local direction = self.forward
    self:Move(direction, value)
  end
  return true
end

function BP_PlayerInputHandleCompnent_C:MoveRight(value)
  if 0 ~= value then
    self:UpdateDirection()
    local direction = self.right
    self:Move(direction, value)
  end
  return true
end

function BP_PlayerInputHandleCompnent_C:UpdateDirection()
  local actor = self:GetOwner()
  if actor.CharacterMovement:IsClimbing() then
    self.forward = UE4.FVector(1, 0, 0)
    self.right = UE4.FVector(0, 1, 0)
    return
  end
  local ueCtrl = self.playerController
  local Rotation = ueCtrl:GetControlRotation()
  if ueCtrl.Aiming then
    Rotation = ueCtrl.PlayerCameraManager:GetCameraRotation()
  end
  if self:GetOwner().CharacterMovement.bCheatFlying then
    Rotation:Set(Rotation.Pitch, Rotation.Yaw, 0)
  else
    Rotation:Set(0, Rotation.Yaw, 0)
  end
  self.forward = Rotation:ToVector()
  self.right = Rotation:GetRightVector()
end

function BP_PlayerInputHandleCompnent_C:Move(dir, axis)
  if self:GetOwner().IsFlailLanding then
    return
  end
  if _G.NRCModuleManager:IsModuleActive("RolePlayModule") and _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.PreventJoystickFalseInterrupt) then
    return
  end
  local player = self:GetOwner().sceneCharacter
  if player then
    local inputComponent = player.inputComponent
    if inputComponent:GetInputEnable() then
      local movementComponent = player.movementComponent
      if movementComponent then
        if movementComponent:IsMoving() == false then
          self:UpdateDirection()
        end
        movementComponent:ApplyMoveInput(dir, axis)
      end
    end
  end
end

function BP_PlayerInputHandleCompnent_C:Turn(Value, IgnorMouse)
  local player = self:GetOwner().sceneCharacter
  if player and player.inputComponent and player.inputComponent:GetCameraControlEnable() then
    self.Overridden.Turn(self, Value, IgnorMouse)
  end
  return false
end

function BP_PlayerInputHandleCompnent_C:LookUp(Value, IgnorMouse)
  local player = self:GetOwner().sceneCharacter
  if player and player.inputComponent and player.inputComponent:GetCameraControlEnable() then
    self.Overridden.LookUp(self, Value, IgnorMouse)
  end
  return false
end

return BP_PlayerInputHandleCompnent_C
