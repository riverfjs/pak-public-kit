local StatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.StatusComponent")
local Base = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerBase")
local InputComp = require("NewRoco.Modules.Core.Scene.Component.Input.InputComponent")
local ThrowManagementComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.ThrowManagementComponent")
local FadeComponent = require("NewRoco.Modules.Core.Scene.Component.Fade.FadeComponent")
local SceneLocalPlayerSimple = Base:Extend("SceneLocalPlayerSimple")

function SceneLocalPlayerSimple:Ctor(module)
  Base.Ctor(self, module)
end

function SceneLocalPlayerSimple:InitComponent()
  Base.InitComponent(self)
  self.statusComponent = StatusComponent()
  self:AddComponent(self.statusComponent)
  self.inputComponent = InputComp()
  self:AddComponent(self.inputComponent)
  self:EnsureComponent(ThrowManagementComponent)
  self:EnsureComponent(FadeComponent)
end

function SceneLocalPlayerSimple:GetControlPawnCapsuleSize()
  local View = self.viewObj
  local RideComp = View and View.BP_RideComponent
  local RidePet = RideComp and RideComp.RidePet
  if not RidePet then
    local Capsule = View.CapsuleComponent
    return Capsule:GetScaledCapsuleHalfHeight(), Capsule:GetScaledCapsuleRadius()
  end
  local Scale = RidePet:GetActorScale3D().X
  local PetCapsule = RidePet.CapsuleComponent
  return Scale * PetCapsule:GetUnscaledCapsuleHalfHeight(), Scale * PetCapsule:GetUnscaledCapsuleRadius()
end

function SceneLocalPlayerSimple:ToggleRootMotion(enable)
end

function SceneLocalPlayerSimple:DumpCriticalVariables()
  Log.Warning("==========================================================================================")
  Log.WarningFormat("InputComponent: %s", self.inputComponent._inputSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._cameraControlSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._moveSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._ignoreMoveInputSwitch)
  Log.Warning("============================LocalPlayer Critical Variables=================================")
end

return SceneLocalPlayerSimple
