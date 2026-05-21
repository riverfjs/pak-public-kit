local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionQueryInteractableFarmLand = Base:Extend("LuaActionQueryActableFarmLand")
LuaActionQueryInteractableFarmLand.Interval = 1.0
local PLANT_PET_WATER_DISTANCE, PLANT_PET_MANURE_DISTANCE, PLANT_PET_PICK_DISTANCE

local function InitDistanceParameters()
  if PLANT_PET_WATER_DISTANCE then
    return
  end
  local Conf
  Conf = _G.DataConfigManager:GetHomeGlobalConfig("plant_pet_water_distance", false)
  PLANT_PET_WATER_DISTANCE = Conf and Conf.num or 2500
  Conf = _G.DataConfigManager:GetHomeGlobalConfig("plant_pet_manure_distance", false)
  PLANT_PET_MANURE_DISTANCE = Conf and Conf.num or 2500
  Conf = _G.DataConfigManager:GetHomeGlobalConfig("plant_pet_pick_distance", false)
  PLANT_PET_PICK_DISTANCE = Conf and Conf.num or 2500
end

function LuaActionQueryInteractableFarmLand:OnStart(AIController, ...)
  local owner = AIController
  local npc = owner.Npc
  local enableFarm = false
  if FarmUtils.IsCurrentHomeOwner() then
    enableFarm = npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD)
  end
  if not enableFarm and npc:IsAThrownPet() then
    local OwnerPlayerId = npc.serverData and npc.serverData.base.owner_id or 0
    local ownerPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, OwnerPlayerId)
    if ownerPlayer and ownerPlayer.isLocal then
      enableFarm = true
    end
  end
  if not enableFarm then
    return self:Finish(false)
  end
  local resultLandInfo
  InitDistanceParameters()
  local isUnitTypeWater = npc:ContainsUnitType(Enum.SkillDamType.SDT_WATER)
  local isUnitTypeGrass = npc:ContainsUnitType(Enum.SkillDamType.SDT_GRASS)
  local skipHarvest = self.SkipHarvest and self.SkipHarvest:GetValue(owner)
  local pos = npc:GetActorLocation()
  local npcDict = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  if pos and npcDict then
    resultLandInfo = FarmUtils.GetNearestLandAvailable(function(i, l)
      local plant_npc = npcDict[l.plant_actor_id]
      if plant_npc then
        local dist = plant_npc.landPos:Dist(pos)
        return isUnitTypeWater and dist < PLANT_PET_WATER_DISTANCE and FarmUtils.IsLandWateringAvailable(i, l) or isUnitTypeGrass and dist < PLANT_PET_MANURE_DISTANCE and FarmUtils.IsLandFertilizingAvailable(i, l) or not skipHarvest and dist < PLANT_PET_PICK_DISTANCE and FarmUtils.IsLandHarvestingAvailable(i, l)
      else
        return false
      end
    end, pos)
  end
  if resultLandInfo then
    local actor_id = resultLandInfo.plant_actor_id
    local landNpc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, actor_id)
    if not landNpc then
      Log.ErrorFormat("LuaActionQueryInteractableFarmLand:OnStart: landNpc not found, actor_id=", actor_id)
    end
    self.ResultObject:SetValue(owner, landNpc)
    return self:Finish(true)
  end
  return self:Finish(false)
end

return LuaActionQueryInteractableFarmLand
