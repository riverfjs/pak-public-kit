local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionKnockScaredBox = Base:Extend("NPCActionKnockScaredBox")

function NPCActionKnockScaredBox:GetDialogueId()
  if not self.Config then
    return
  end
  local param1 = self.Config.action_param1
  if param1 then
    return tonumber(param1)
  end
  return
end

function NPCActionKnockScaredBox:Execute(playerId, needSendReq)
  self:BeginKnock()
  Base.Execute(self, playerId, needSendReq)
  Base.Finish(self, true)
end

function NPCActionKnockScaredBox:IfActionNeedStatusNotify()
  return false
end

function NPCActionKnockScaredBox:OnPlayerLeaveActionArea()
  self:EndKnock()
end

function NPCActionKnockScaredBox:BeginKnock()
  _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.S2_OpenKnockBoxMessage, self:GetOwnerNPC(), self:GetDialogueId())
end

function NPCActionKnockScaredBox:EndKnock()
  _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.S2_CloseKnockBoxMessage, self:GetOwnerNPC(), self:GetDialogueId())
end

return NPCActionKnockScaredBox
