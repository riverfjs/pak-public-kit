local Base = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Base")
local PassiveSkill_Resonance = Base:Extend("PassiveSkill_Resonance")

function PassiveSkill_Resonance:Ctor(owner, config)
  Base.Ctor(self, owner, config)
  local radius = tonumber(config.param_1)
  self.radiusSquared = radius * radius
  self.AnimName = tostring(config.param_3)
end

function PassiveSkill_Resonance:OnSetViewObj()
  local player = self.owner.owner
  if player then
    local resonanceComp = player.ResonanceComponent
    if resonanceComp then
      resonanceComp:ActivateByPassiveSkill(self.radiusSquared, self.AnimName, true)
    end
  end
end

function PassiveSkill_Resonance:OnSetDoubleRide2P(isOnPet, player2P)
  if player2P then
    local resonanceComp = player2P.ResonanceComponent
    if resonanceComp then
      if player2P.isLocal then
        resonanceComp:ActivateByPassiveSkill(self.radiusSquared, self.AnimName, isOnPet)
      else
        resonanceComp:ActivateByPassiveSkill(nil, self.AnimName, isOnPet)
      end
    end
  end
end

function PassiveSkill_Resonance:Stop()
  local player = self.owner.owner
  if player then
    local resonanceComp = player.ResonanceComponent
    if resonanceComp then
      resonanceComp:ActivateByPassiveSkill()
    end
  end
end

function PassiveSkill_Resonance:TryPlayEffect()
  local player = self.owner.owner
  if player then
    local resonanceComp = player.ResonanceComponent
    if resonanceComp then
      resonanceComp:ActivateByPassiveSkill(nil, self.AnimName, true)
    end
  end
end

return PassiveSkill_Resonance
