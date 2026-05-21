local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatus_SkillBase")
local AbnormalStatus_Illusionist = Base:Extend("AbnormalStatus_Illusionist")

function AbnormalStatus_Illusionist:Ctor(owner)
  Base.Ctor(self, owner)
  self.skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Avatar/Staff/AbnormalEffect/G6_Avatar_Ecology_Illusionist01_Loop.G6_Avatar_Ecology_Illusionist01_Loop'"
end

return AbnormalStatus_Illusionist
