local Base = require("NewRoco.Modules.Core.NPC.Actions.PlayerActions.PlayerActionBase")
local PlayerActionAcceptInvite = Base:Extend("PlayerActionAcceptInvite")

function PlayerActionAcceptInvite:Execute()
  if not self.Owner then
    return
  end
  local Player = self.Owner.owner
  local LocPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local InviteComponent = LocPlayer:GetComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
  if InviteComponent then
    InviteComponent:InviteAcceptOnlyOption(Player:GetLogicId())
  end
end

return PlayerActionAcceptInvite
