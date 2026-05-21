local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionBlessing = Base:Extend("NPCActionBlessing")

function NPCActionBlessing:Ctor(Owner, Config, Info, View)
  Base.Ctor(self, Owner, Config, Info, View)
end

function NPCActionBlessing:Execute(playerId, needSendReq)
  local pet = self:GetOwnerNPC()
  local AvatarID = pet.serverData.npc_base.create_avatar_id
  Base.Execute(self, playerId, false)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, AvatarID)
  if not player then
    self:Finish()
    return
  end
  local PlayerUin = player.serverData and player.serverData.base and player.serverData.base.logic_id or 0
  if _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(PlayerUin) then
    local Text = _G.DataConfigManager:GetLocalizationConf("open_relation_player_on_the_balcklist").msg
    if Text then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    end
    return
  end
  local throwSession = pet and pet.ThrowSession
  if throwSession and not throwSession:IsPostInteract() then
    local refuse_info = string.format(_G.LuaText.interactiontree_cifu_req_busy, pet.serverData.base.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, refuse_info)
    return
  end
  local Param = {PetInfo = pet, AvatarID = AvatarID}
  _G.NRCModuleManager:DoCmd(RelationTreeCmd.OpenPetRelationCover, PlayerUin, Param, self)
  _G.NRCModuleManager:DoCmd(RelationTreeCmd.RelationTreeSendTLog, 0, nil)
end

return NPCActionBlessing
