local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PassiveSkillRegistry = require("NewRoco.Modules.Core.Scene.Component.RidePet.RidePetPassiveSkillRegistry")
local RemotePlayerRidePetPassiveSkillComponent = Base:Extend("RemotePlayerRidePetPassiveSkillComponent")
local ViewToComponentMap = {}

function RemotePlayerRidePetPassiveSkillComponent:Attach(owner)
  Base.Attach(self, owner)
  self._passive_skills = {}
  self._typed_passive_skill = {}
  local pass_skill_list = self.owner.rideConfig.passive_skill
  for i = 1, #pass_skill_list do
    local passiveSkillId = pass_skill_list[i]
    local passiveSkillConfig = DataConfigManager:GetRidePassiveSkill(passiveSkillId)
    if passiveSkillConfig then
      local passive_skill
      if self:IsEnvPassiveSkill(passiveSkillConfig) then
        passive_skill = self._typed_passive_skill[passiveSkillConfig.type]
        if not passive_skill then
          passive_skill = PassiveSkillRegistry.Get(self.owner, passiveSkillConfig)
          table.insert(self._passive_skills, passive_skill)
          self._typed_passive_skill[passiveSkillConfig.type] = passive_skill
        end
        passive_skill:ParseConfig(passiveSkillConfig)
      else
        passive_skill = PassiveSkillRegistry.Get(self.owner, passiveSkillConfig)
        table.insert(self._passive_skills, passive_skill)
      end
    end
  end
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
end

function RemotePlayerRidePetPassiveSkillComponent:IsEnvPassiveSkill(config)
  return config and (config.type == ProtoEnum.RidePetPassiveSkillType.RPPST_Terrain or config.type == ProtoEnum.RidePetPassiveSkillType.RPPST_Weather)
end

function RemotePlayerRidePetPassiveSkillComponent:OnPetStatusChanged(status, value, pet)
  if status == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE and value > 0 and not self._in_ride then
    self:OnStartRide()
  elseif self._in_ride then
    self:OnStopRide()
  end
end

function RemotePlayerRidePetPassiveSkillComponent:OnStartRide()
  self._in_ride = true
  for i, v in ipairs(self._passive_skills) do
    v:Start()
  end
end

function RemotePlayerRidePetPassiveSkillComponent:OnStopRide()
  self._in_ride = false
  for i, v in ipairs(self._passive_skills) do
    v:Stop()
  end
end

function RemotePlayerRidePetPassiveSkillComponent:OnRideSuccess()
  if self._in_ride then
    for i, v in ipairs(self._passive_skills) do
      if v.TryPlayEffect then
        v:TryPlayEffect()
      end
    end
  end
  if UE.UObject.IsValid(self.viewObj) and self.viewObj ~= self.owner.viewObj then
    self.viewObj.MovementModeChangedDelegate:Remove(self.viewObj, self.OnMovementModeUpdate)
    ViewToComponentMap[self.viewObj] = nil
  end
  self.viewObj = self.owner.viewObj
  local viewObj = self.owner.viewObj
  if UE.UObject.IsValid(viewObj) then
    ViewToComponentMap[viewObj] = self
    viewObj.MovementModeChangedDelegate:Add(viewObj, self.OnMovementModeUpdate)
  end
end

function RemotePlayerRidePetPassiveSkillComponent:OnMovementModeUpdate(character, preMoveMode, preCustomMode)
  local component = ViewToComponentMap[character]
  if component then
    component.owner:SendEvent(PlayerModuleEvent.ON_RIDE_MOVE_MODE_CHANGE)
  end
end

function RemotePlayerRidePetPassiveSkillComponent:DeAttach()
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj.MovementModeChangedDelegate:Remove(self.viewObj, self.OnMovementModeUpdate)
  end
  if self.viewObj then
    ViewToComponentMap[self.viewObj] = nil
    self.viewObj = nil
  end
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
  self._passive_skills = nil
  self._typed_passive_skill = nil
  Base.DeAttach(self)
end

function RemotePlayerRidePetPassiveSkillComponent:OnSetDoubleRide2P(isOnPet, player2P)
  for _, v in ipairs(self._passive_skills) do
    if v.OnSetDoubleRide2P then
      v:OnSetDoubleRide2P(isOnPet, player2P)
    end
  end
end

return RemotePlayerRidePetPassiveSkillComponent
