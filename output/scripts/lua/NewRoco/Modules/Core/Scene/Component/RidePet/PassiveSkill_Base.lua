local PassiveSkill_Base = Class()

function PassiveSkill_Base:Ctor(owner, config)
  self.owner = owner
  self.config = config
end

function PassiveSkill_Base:OnSetViewObj()
end

function PassiveSkill_Base:OnSetDoubleRide2P(isOnPet, player2P)
end

function PassiveSkill_Base:Start()
end

function PassiveSkill_Base:Update(deltaTime)
end

function PassiveSkill_Base:Stop()
end

return PassiveSkill_Base
