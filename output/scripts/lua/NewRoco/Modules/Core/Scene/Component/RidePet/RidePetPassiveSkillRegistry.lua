local RidePetPassiveSkillRegistry = {
  [Enum.RidePetPassiveSkillType.RPPST_Temperature] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Temperature"),
  [Enum.RidePetPassiveSkillType.RPPST_Perception] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Perception"),
  [Enum.RidePetPassiveSkillType.RPPST_Terrain] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Terrain"),
  [Enum.RidePetPassiveSkillType.RPPST_Weather] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Weather"),
  [Enum.RidePetPassiveSkillType.RPPST_AutoCollect] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_AutoCollect"),
  [Enum.RidePetPassiveSkillType.RPPST_Resonance] = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Resonance")
}

function RidePetPassiveSkillRegistry.Get(owner, config)
  local klass = RidePetPassiveSkillRegistry[config.type]
  if not klass then
    return nil
  end
  return klass(owner, config)
end

return RidePetPassiveSkillRegistry
