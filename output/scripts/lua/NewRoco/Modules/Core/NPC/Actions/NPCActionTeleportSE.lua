local NPCActionTeleportSuitcase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionTeleportSuitcase")
local Base = NPCActionTeleportSuitcase
local NPCActionTeleportSE = Base:Extend("NPCActionTeleportSE")

function NPCActionTeleportSE:GetSkillPath()
  local Player = self:GetPlayer()
  local SkillPath = self.Config.action_param2 or "/Game/ArtRes/Effects/G6Skill/ScenePlay/G6_JumpInBox.G6_JumpInBox"
  if self.bIsDoubleJump then
    self.Player2P = Player:GetAnotherTogetherMovePlayer()
    if self.Player2P then
      self.Player2PPos = self.Player2P:GetActorLocation()
      SkillPath = self.Config.action_param3 or "/Game/ArtRes/Effects/G6Skill/ScenePlay/G6_JumpInBox_2P.G6_JumpInBox_2P"
    end
  end
  return SkillPath
end

return NPCActionTeleportSE
