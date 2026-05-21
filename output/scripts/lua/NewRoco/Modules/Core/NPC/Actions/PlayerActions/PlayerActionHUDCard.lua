local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local Base = require("NewRoco.Modules.Core.NPC.Actions.PlayerActions.PlayerActionBase")
local PlayerActionHUDCard = Base:Extend("PlayerActionHUDCard")

function PlayerActionHUDCard:Execute()
  if not self.Owner then
    return
  end
  Base.Execute(self)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenStudentCardPanel, self.Owner.owner.serverData, FriendEnum.AdminFriendType.Others, FriendEnum.Source.Scene, FriendEnum.SELECT_TAB.FaceToFaceInteraction, nil, nil, nil, self)
end

function PlayerActionHUDCard:ShouldShowOnUI()
  local option = self.Owner
  if not option then
    return false
  end
  local player = option.owner
  if not player then
    return false
  end
  if player:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OBSERVING) then
    return false
  end
  return true
end

function PlayerActionHUDCard:HasLocalPerform()
  return true
end

return PlayerActionHUDCard
