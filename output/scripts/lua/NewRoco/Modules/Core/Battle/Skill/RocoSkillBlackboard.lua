_G.NRCClass = require("Core.NRCClass")
local RocoSkillBlackboard = NRCClass()

function RocoSkillBlackboard:Ctor()
  self:Clear()
end

function RocoSkillBlackboard:Set(Params)
  if not Params then
    return
  end
  if Params.Caster then
    self.Caster = Params.Caster
  end
  if Params.BallAdditionalPaths then
    self.BallAdditionalPaths = Params.BallAdditionalPaths
  end
  if Params.BallAdditionalResGroup then
    self.BallAdditionalResGroup = Params.BallAdditionalResGroup
  end
  if Params.BallAddLinkActors then
    self.BallAddLinkActors = Params.BallAddLinkActors
  end
  if Params.Characters then
    self.Characters = Params.Characters
  end
  if Params.Targets then
    self.Targets = Params.Targets
  end
  if Params.BallPath then
    self.BallPath = Params.BallPath
  end
  if Params.BallResGroup then
    self.BallResGroup = Params.BallResGroup
  end
  if Params.ItemPath then
    self.ItemPath = Params.ItemPath
  end
  if Params.Settings then
    self.Settings = Params.Settings
  end
  if Params.CounterActor then
    self.CounterActor = Params.CounterActor
  end
  if Params.BeCounterActor then
    self.BeCounterActor = Params.BeCounterActor
  end
end

function RocoSkillBlackboard:SetAdditions(K, V)
  self.Additions[K] = V
end

function RocoSkillBlackboard:Clear()
  self.Caster = nil
  self.Targets = nil
  self.Characters = nil
  self.BallPath = nil
  self.BallResGroup = nil
  self.Settings = nil
  self.Power = 0
  self.ReduceHP = 0
  self.IsRestraint = false
  self.IsRestrained = false
  self.Additions = {}
  self.BallAdditionalPaths = {}
  self.BallAdditionalResGroup = {}
  self.BallAddLinkActors = {}
  self.SelectLocations = {}
  self.CounterActor = nil
  self.BeCounterActor = nil
end

return RocoSkillBlackboard
