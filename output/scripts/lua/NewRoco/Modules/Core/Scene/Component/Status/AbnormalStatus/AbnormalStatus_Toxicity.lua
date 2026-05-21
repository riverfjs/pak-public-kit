local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatus_SkillBase")
local AbnormalStatus_Toxicity = Base:Extend("AbnormalStatus_Toxicity")

function AbnormalStatus_Toxicity:Ctor(owner)
  Base.Ctor(self, owner)
  self.skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Avatar/Staff/AbnormalEffect/G6_Avatar_Ecology_Toxicity01_Loop.G6_Avatar_Ecology_Toxicity01_Loop'"
end

return AbnormalStatus_Toxicity
