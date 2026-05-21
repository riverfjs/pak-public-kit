local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local Base = require("NewRoco.Modules.Core.NPC.Actions.PlayerActions.PlayerActionBase")
local PlayerActionAcceptBlessingInvite = Base:Extend("PlayerActionAcceptBlessingInvite")

function PlayerActionAcceptBlessingInvite:Execute()
  if not self.Owner then
    return
  end
  local pet_npc_id = self.Owner.custom_params and self.Owner.custom_params.picked_pet_npc_id
  local pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pet_npc_id)
  if not pet then
    local pet_gid = self.Owner.custom_params and self.Owner.custom_params.picked_pet_gid or 0
    local pet_data = _G.DataModelMgr.PlayerDataModel:GetPetByGid(pet_gid)
    local pet_name = pet_data.config and pet_data.config.name or ""
    local refuse_info = string.format(_G.LuaText.interactiontree_cifu_pet_busy_out, pet_name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, refuse_info)
    return
  end
  if pet.ThrowSession and pet.ThrowSession.Status ~= ThrowSessionStatusEnum.PostInteract then
    local refuse_info = string.format(_G.LuaText.interactiontree_cifu_pet_busy_out, pet.serverData.base.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, refuse_info)
    return
  end
  local Player = self.Owner.owner
  local petLocation = pet:GetActorLocation()
  local playerLocation = Player:GetActorLocation()
  local distance = _G.DataConfigManager:GetGlobalConfigNumByKey("interactiontree_cifu_distance", 1000)
  local realDistance = UE4.UKismetMathLibrary.Vector_Distance(petLocation, playerLocation)
  if distance < realDistance then
    local refuse_info = string.format(_G.LuaText.interactiontree_cifu_pet_distance_out, pet.serverData.base.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, refuse_info)
    return
  end
  local LocPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local inviteComponent = LocPlayer:GetComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
  if inviteComponent then
    inviteComponent:InviteAcceptOnlyOption(Player:GetLogicId())
  end
end

return PlayerActionAcceptBlessingInvite
