local ShowHideBase = require("NewRoco.Modules.Core.NPC.ShowHide.ShowHideBase")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = ShowHideBase
local WorldCombatShowHide = Base:Extend("WorldCombatShowHide")

function WorldCombatShowHide:GetReason()
  return NPCModuleEnum.NpcReasonFlags.WORLD_COMBAT_HIDDEN
end

function WorldCombatShowHide:CheckShouldHide(npc)
  if not npc:IsAThrownPet() then
    return false
  end
  local playerId = npc:GetCreatorID()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local localPlayerId = localPlayer and localPlayer:GetServerId() or 0
  if not localPlayerId or 0 == localPlayerId then
    return false
  end
  if localPlayerId == playerId then
    return false
  end
  local ownerPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, playerId)
  if not ownerPlayer then
    return false
  end
  local ownerPlayerUin = ownerPlayer:GetLogicId()
  if _G.DataModelMgr.PlayerDataModel:IsVisitor(ownerPlayerUin) then
    return false
  end
  return true
end

function WorldCombatShowHide:CheckShouldShow(npc)
  return true
end

return WorldCombatShowHide
