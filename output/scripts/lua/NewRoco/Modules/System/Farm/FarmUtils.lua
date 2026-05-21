local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local FloatingText2DComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.FloatingText2DComponent")
local LAND_VISIBLE_DIST = 4000
local FarmModuleOpStrDict = {
  [FarmModuleEnum.OptionType.None] = "\230\151\160",
  [FarmModuleEnum.OptionType.Sowing] = "\230\146\173\231\167\141",
  [FarmModuleEnum.OptionType.Harvesting] = "\230\148\182\232\142\183",
  [FarmModuleEnum.OptionType.Watering] = "\230\181\135\230\176\180",
  [FarmModuleEnum.OptionType.Fertilizing] = "\230\150\189\232\130\165",
  [FarmModuleEnum.OptionType.Stealing] = "\229\129\183\229\143\150",
  [FarmModuleEnum.OptionType.Removing] = "\231\167\187\233\153\164"
}
local FarmUtils = {}

function FarmUtils.IsModuleEnable()
  return _G.GlobalConfig.ENABLE_HOME
end

function FarmUtils.GetPlayer()
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  return Player
end

function FarmUtils.GetLandOpStr(op)
  return FarmModuleOpStrDict[op] or "\230\156\170\231\159\165"
end

function FarmUtils.GetLandInfo(id)
  if not FarmUtils.IsModuleEnable() then
    return
  end
  local Player = FarmUtils.GetPlayer()
  if not Player then
    Log.Error("FarmUtils.GetLandInfo Can't find local player")
    return
  end
  if not (Player.serverData and Player.serverData.home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1] and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list) or not Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list[id] then
    return
  end
  local landInfo = Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list[id]
  return landInfo
end

function FarmUtils.IsLocalPlayerStealExpelled(player)
  if not FarmUtils.IsModuleEnable() then
    return false
  end
  local Player = player or FarmUtils.GetPlayer()
  if not Player then
    Log.Error("FarmUtils.IsLocalPlayerStealExpelled Can't find player")
    return false
  end
  if not (Player.serverData and Player.serverData.home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1]) or not Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].steal_expel then
    return false
  end
  if FarmUtils.IsCurrentHomeOwner() then
    return false
  end
  local playerId = player:GetServerId()
  local conf = _G.DataConfigManager:GetHomeGlobalConfig("home_plant_steal_attack_CD")
  local maxExpelTime = conf and conf.num or 3600
  for _, expelInfo in pairs(Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].steal_expel) do
    if playerId == expelInfo.avatar_id and _G.ZoneServer:GetServerTime() / 1000 <= expelInfo.expel_time + maxExpelTime then
      return true
    end
  end
  return false
end

function FarmUtils.GetPlantGrowTimeInfo(id)
  local landInfo = FarmUtils.GetLandInfo(id)
  if not landInfo then
    return
  end
  local ret = {}
  ret.startTime = landInfo.plant_time
  ret.endTime = landInfo.plant_rip_time
  local curTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  ret.growTime = ret.endTime - curTime
  return ret
end

function FarmUtils.GetPlantGrowConfByLandId(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return
  end
  return _G.DataConfigManager:GetPlantGrowConf(landInfo.plant_seed_id)
end

function FarmUtils.IsLandWatering(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if landInfo.plant_water_time > 0 and landInfo.plant_water_time + FarmUtils.GetWateringContinueMaxTime(id, landInfo) > math.floor(_G.ZoneServer:GetServerTime() / 1000) then
    return true
  end
  return false
end

function FarmUtils.IsLandFertilizing(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if landInfo.plant_harvest_num > 0 then
    return false
  end
  if landInfo.plant_manure_time > 0 then
    local growConf = FarmUtils.GetPlantGrowConfByLandId(id, landInfo)
    if not growConf then
      return false
    end
    local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
    if not growGrade then
      return false
    end
    local FertilizingCd = growGrade.manure_cd
    if FertilizingCd > _G.ZoneServer:GetServerTime() / 1000 - landInfo.plant_manure_time then
      return true
    end
  end
  return false
end

function FarmUtils.IsLandHarvest(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  local plant_num = landInfo.plant_harvest_num
  local growId = landInfo.plant_seed_id
  if not growId or 0 == growId then
    return false
  end
  local growConf = _G.DataConfigManager:GetPlantGrowConf(growId)
  if not growConf then
    Log.Error("FarmUtils:IsLandHarvest Can't find growConf", growId)
    return false
  end
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  if not growGrade then
    return false
  end
  if plant_num >= growGrade.plant_harvest_standard then
    return true
  end
  return false
end

function FarmUtils.IsLandUnlock(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 ~= landInfo.plant_id then
    return true
  end
  return false
end

function FarmUtils.IsLandUnoccupied(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return true
  end
  return false
end

function FarmUtils.IsLandReadyToGrow(id, sourceLandInfo)
  local info = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not info then
    return FarmModuleEnum.GrowCheckResult.Other
  end
  if not FarmUtils.IsLandUnlock(id, info) then
    return FarmModuleEnum.GrowCheckResult.Locked
  end
  if not FarmUtils.IsLandUnoccupied(id, info) then
    return FarmModuleEnum.GrowCheckResult.Occupied
  end
  return FarmModuleEnum.GrowCheckResult.Pass
end

function FarmUtils.IsLandOptionTypeAvailable(optionType, id, sourceLandInfo, isStrict)
  if optionType == FarmModuleEnum.OptionType.Sowing then
    return FarmUtils.IsLandSowingAvailable(id, sourceLandInfo)
  elseif optionType == FarmModuleEnum.OptionType.Harvesting then
    return FarmUtils.IsLandHarvestingAvailable(id, sourceLandInfo)
  elseif optionType == FarmModuleEnum.OptionType.Watering then
    return FarmUtils.IsLandWateringAvailable(id, sourceLandInfo)
  elseif optionType == FarmModuleEnum.OptionType.Fertilizing then
    return FarmUtils.IsLandFertilizingAvailable(id, sourceLandInfo)
  elseif optionType == FarmModuleEnum.OptionType.Stealing then
    return FarmUtils.IsLandStealingAvailable(id, sourceLandInfo, isStrict)
  elseif optionType == FarmModuleEnum.OptionType.Removing then
    return FarmUtils.IsLandRemovingAvailable(id, sourceLandInfo)
  else
    return false
  end
end

function FarmUtils.IsLandWateringAvailable(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return false
  end
  if landInfo.plant_harvest_num > 0 then
    return false
  end
  if landInfo.plant_water_time > 0 then
    local waterCD = FarmUtils.GetWateringCD(id, landInfo)
    if waterCD > _G.ZoneServer:GetServerTime() / 1000 - landInfo.plant_water_time then
      return false
    end
  end
  return true
end

function FarmUtils.IsLandFertilizingAvailable(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return false
  end
  if landInfo.plant_harvest_num > 0 then
    return false
  end
  if landInfo.plant_water_time > 0 then
    local waterCD = FarmUtils.GetWateringCD(id, landInfo)
    if waterCD < _G.ZoneServer:GetServerTime() / 1000 - landInfo.plant_water_time then
      return false
    end
  else
    return false
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(id, landInfo)
  if not growConf then
    return false
  end
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  if not growGrade then
    return false
  end
  local FertilizingCd = growGrade.manure_cd
  if FertilizingCd < _G.ZoneServer:GetServerTime() / 1000 - landInfo.plant_manure_time then
    return true
  end
  return false
end

function FarmUtils.IsLandHarvestingAvailable(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return false
  end
  if not FarmUtils.IsCurrentHomeOwner() then
    return false
  end
  if landInfo.plant_harvest_num > 0 then
    return true
  end
  return false
end

function FarmUtils.IsLandStealingAvailable(id, sourceLandInfo, isStrict)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return false
  end
  if FarmUtils.IsCurrentHomeOwner() then
    return false
  end
  if landInfo.plant_harvest_num > 0 then
    if not isStrict then
      return true
    elseif landInfo.plant_can_steal_account > 0 then
      local bLocalPlayerReachStealLimit = FarmUtils.IsLocalPlayerReachStealLimit()
      local plantCanStealAccount = landInfo.plant_can_steal_account or 0
      local plantStealAccount = landInfo.plant_steal_account or 0
      local bStealAble = not bLocalPlayerReachStealLimit and plantCanStealAccount > plantStealAccount
      if bStealAble then
        local bHadSteal = false
        local bTooMuchTimes = false
        if landInfo.plant_steal_players then
          local stealTimesLimit = 10
          local config = _G.DataConfigManager:GetHomeGlobalConfig("plant_steal_same_plant_role_max")
          if config and config.num then
            stealTimesLimit = config.num
          end
          bTooMuchTimes = stealTimesLimit <= #landInfo.plant_steal_players
          if not bTooMuchTimes then
            local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
            for idx1, playerUinHadSteal in ipairs(landInfo.plant_steal_players) do
              if myUin == playerUinHadSteal then
                bHadSteal = true
                break
              end
            end
          end
        end
        bStealAble = bStealAble and not bTooMuchTimes and not bHadSteal
      end
      if bStealAble then
        return true
      end
    end
  end
  return false
end

function FarmUtils.IsLandRemovingAvailable(id, sourceLandInfo, isStrict)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if not FarmUtils.IsLandUnlock(id, landInfo) then
    return false
  end
  if not FarmUtils.IsCurrentHomeOwner() then
    return false
  end
  if landInfo.plant_seed_id and 0 ~= landInfo.plant_seed_id and 0 == landInfo.plant_harvest_num and 0 == landInfo.plant_harvest_id then
    return true
  end
  return false
end

function FarmUtils.IsLandSowingAvailable(id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if not landInfo then
    return false
  end
  if not FarmUtils.IsLandUnlock(id, landInfo) then
    return false
  end
  if not FarmUtils.IsCurrentHomeOwner() then
    return false
  end
  if 0 == landInfo.plant_seed_id then
    return true
  end
  return false
end

function FarmUtils.IsFarmCollectAvailable(sourceLandInfo, isStrict)
  for id = 1, 15 do
    if FarmUtils.IsLandHarvestingAvailable(id, sourceLandInfo) then
      return true
    elseif FarmUtils.IsLandStealingAvailable(id, sourceLandInfo, isStrict) then
      return true
    end
  end
  return false
end

function FarmUtils.IsFarmBoardUnlockValid()
  if not FarmUtils.IsModuleUnlock() then
    return false
  end
  local num = _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetAvailableUnlockFarmLandNum)
  num = num or 0
  if num > 0 then
    return true
  end
  return false
end

function FarmUtils.GetPlantName(plant_seed_id, plant_tab_id)
  local growConf = _G.DataConfigManager:GetPlantGrowConf(plant_seed_id)
  if nil == growConf then
    return ""
  end
  local growGrade = growConf.plant_grow_grade[plant_tab_id]
  if not growGrade then
    return ""
  end
  for _, v in pairs(growGrade.plant_grow) do
    if v.plant_stage == _G.Enum.PlantStage.FS_RIPE then
      local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(v.plant_npc_refresh_id)
      if nil == refreshConf then
        return ""
      end
      local npcConf = _G.DataConfigManager:GetNpcConf(refreshConf.npc_id)
      if nil == npcConf then
        return ""
      end
      return npcConf.name
    end
  end
end

function FarmUtils.GetLandNPC(id)
  return _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetLandNPC, id)
end

function FarmUtils.IsModuleUnlock()
  return FarmUtils.IsModuleEnable() and _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_PLANT_LAND)
end

function FarmUtils.GetFarmVisibleDist()
  return LAND_VISIBLE_DIST
end

function FarmUtils.GetOriginTransform()
  local initialGlobalConf = _G.DataConfigManager:GetHomeGlobalConfig("plant_initial_coord")
  if not initialGlobalConf then
    Log.Error("FarmUtils.GetOriginTransform plant_initial_coord not found")
    return nil, nil
  end
  local areaConf = _G.DataConfigManager:GetAreaConf(initialGlobalConf.num)
  if not areaConf then
    Log.Error("FarmUtils.GetOriginTransform areaConf not found", initialGlobalConf.num)
    return nil, nil
  end
  local originLocation = UE.FVector(areaConf.pos[1].position_xyz[1], areaConf.pos[1].position_xyz[2], areaConf.pos[1].position_xyz[3])
  local originRotation = UE4.FRotator(areaConf.pos[1].rotation_xyz[2], areaConf.pos[1].rotation_xyz[3], areaConf.pos[1].rotation_xyz[1])
  return originLocation, originRotation
end

function FarmUtils.IsPlayerInCropNpcLand(npc)
  if not npc:IsFarmCropNpc() then
    return false
  end
  return npc.serverData.npc_base.home_plant_land_id == _G.NRCModuleManager:DoCmd(_G.FarmModuleCmd.GetCurrentStandingLandId)
end

function FarmUtils.IsStandingOnLand(land_id)
  return land_id == _G.NRCModuleManager:DoCmd(_G.FarmModuleCmd.GetCurrentStandingLandId)
end

function FarmUtils.GetPlantGrowFullTime(land_id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(land_id)
  if not landInfo then
    return
  end
  if not (landInfo.plant_rip_cfg_time and 0 ~= landInfo.plant_rip_cfg_time and landInfo.plant_time) or 0 == landInfo.plant_time then
    return
  end
  return landInfo.plant_rip_cfg_time - landInfo.plant_time
end

function FarmUtils.GetWateringReduceTimeCurrent(land_id)
  local landInfo = FarmUtils.GetLandInfo(land_id)
  if not landInfo then
    return
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(land_id, landInfo)
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  if not growConf then
    Log.Error("FarmUtils.GetWateringReduceTimeCurrent cannot find growConf: ")
    return 0
  end
  if not growGrade then
    Log.Error("FarmUtils.GetWateringReduceTimeCurrent cannot find growGrade: ", landInfo.plant_tab_id)
    return 0
  end
  return math.min((_G.ZoneServer:GetServerTime() / 1000 - landInfo.plant_water_time) / (growGrade.water_continue_max_time_para / 1000000), FarmUtils.GetWateringReduceTimeMax(land_id, landInfo))
end

function FarmUtils.GetWateringReduceTimeMax(land_id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(land_id)
  local growTime = FarmUtils.GetPlantGrowFullTime(land_id, landInfo)
  if not growTime then
    return
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(land_id, landInfo)
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  return growTime * growGrade.water_reduce_plant_grow_time_para / 1000000
end

function FarmUtils.GetWateringContinueMaxTime(land_id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(land_id)
  local growTime = FarmUtils.GetPlantGrowFullTime(land_id, landInfo)
  if not growTime then
    return
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(land_id, landInfo)
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  return growTime * growGrade.water_reduce_plant_grow_time_para / 1000000 * growGrade.water_continue_max_time_para / 1000000
end

function FarmUtils.GetWateringCD(land_id, sourceLandInfo)
  local landInfo = sourceLandInfo or FarmUtils.GetLandInfo(land_id)
  local growTime = FarmUtils.GetPlantGrowFullTime(land_id, landInfo)
  if not growTime then
    return
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(land_id, landInfo)
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  return growTime * growGrade.water_reduce_plant_grow_time_para / 1000000 * growGrade.water_continue_max_time_para / 1000000 * growGrade.water_reduce_limit_percent_para / 1000000
end

function FarmUtils.ExecuteFarmNPCOption(optionType, id, isPet)
  local landInfo = FarmUtils.GetLandInfo(id)
  if not landInfo then
    Log.Error("FarmUtils.ExecuteOption landInfo not found", id)
    return
  end
  local npcID = landInfo.plant_actor_id
  local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcID)
  if not npc or not npc.InteractionComponent then
    Log.Error("FarmUtils.ExecuteOption npc not found", npcID)
    return
  end
  if not FarmUtils.PreCheckFarmNPCOption(optionType) then
    Log.Error("FarmUtils.PreCheckFarmNPCOption failed", optionType)
    return
  end
  for _, option in pairs(npc.InteractionComponent._options) do
    if option:IsOptionEnable(true) and FarmUtils.IsOptionByFarmEnumType(optionType, option.config, isPet) then
      Log.Debug("FarmUtils.ExecuteFarmNPCOption option", optionType, option.config.id)
      option:OnOptionAction()
      return
    end
  end
  Log.Error("ExecuteFarmNPCOption option not found ", optionType, id, isPet)
end

function FarmUtils.GetFarmOwnerId()
  local info = FarmUtils.GetCurrentWorldHomeInfo()
  return info and info.home_owner_id
end

function FarmUtils.PreCheckFarmNPCOption(optionType)
  if optionType == FarmModuleEnum.OptionType.Stealing then
    local homeOwnerId = FarmUtils.GetFarmOwnerId()
    local localUin = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    if localUin == homeOwnerId then
      return true
    end
    if not _G.DataModelMgr.PlayerDataModel:IsFriend(homeOwnerId) then
      local msg = _G.LuaText[string.format("Error_Code_50517")]
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
      return false
    end
  elseif optionType == FarmModuleEnum.OptionType.Sowing then
    local seed_Id, tabId = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetEquipSeed)
    tabId = tabId or 1
    if 0 == seed_Id then
      local msg = _G.LuaText[string.format("seed_plant_empty")]
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
      return false
    else
      local ownNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
      local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(seed_Id)
      if plantGrowConf then
        local growGrade = plantGrowConf.plant_grow_grade[tabId]
        if growGrade and ownNum < growGrade.plant_vitem_value then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Error_Code_50521)
          return false
        end
      end
    end
  end
  return true
end

function FarmUtils.IsOptionByFarmEnumType(optionType, config, isPet)
  if optionType == FarmModuleEnum.OptionType.Watering then
    return isPet and config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_WATER or config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_ROLE_WATER
  end
  if optionType == FarmModuleEnum.OptionType.Fertilizing then
    return isPet and config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_MANURE or config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_ROLE_MANURE
  end
  if optionType == FarmModuleEnum.OptionType.Harvesting then
    return config.action.action_type == _G.Enum.ActionType.ACT_HOME_OWNER_PICK
  end
  if optionType == FarmModuleEnum.OptionType.Stealing then
    return config.action.action_type == _G.Enum.ActionType.ACT_HOME_VISITOR_PICK
  end
  if optionType == FarmModuleEnum.OptionType.Sowing then
    return config.action.action_type == _G.Enum.ActionType.ACT_HOME_OWNER_PLANT
  end
  if optionType == FarmModuleEnum.OptionType.Removing then
    return config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_SEEDLING_MOVALCK
  end
end

function FarmUtils.GetFarmOptionType(option)
  if not (option and option.config) or not option.config.action then
    return nil
  end
  if option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_WATER or option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_ROLE_WATER then
    return FarmModuleEnum.OptionType.Watering
  elseif option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_MANURE or option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_ROLE_MANURE then
    return FarmModuleEnum.OptionType.Fertilizing
  elseif option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_OWNER_PICK then
    return FarmModuleEnum.OptionType.Harvesting
  elseif option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_VISITOR_PICK then
    return FarmModuleEnum.OptionType.Stealing
  elseif option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_OWNER_PLANT then
    return FarmModuleEnum.OptionType.Sowing
  elseif option.config.action.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_SEEDLING_MOVALCK then
    return FarmModuleEnum.OptionType.Removing
  end
  return nil
end

function FarmUtils.GetTxtByTime(time)
  local day = math.floor(time / 86400)
  local hour = math.floor((time - day * 86400) / 3600)
  local min = math.floor((time - day * 86400 - hour * 3600) / 60)
  local sec = math.floor(time % 60)
  local context_d = _G.LuaText.clear_plant_confirm_text_d
  local context_h = _G.LuaText.clear_plant_confirm_text_h
  local context_m = _G.LuaText.clear_plant_confirm_text_m
  local context_s = _G.LuaText.clear_plant_confirm_text_s
  context_d = day > 0 and string.format(context_d, tostring(day)) or ""
  context_h = hour > 0 and string.format(context_h, tostring(hour)) or ""
  context_m = min > 0 and string.format(context_m, tostring(min)) or ""
  context_s = sec > 0 and string.format(context_s, tostring(sec)) or ""
  return string.format("%s%s%s%s", context_d, context_h, context_m, context_s)
end

function FarmUtils.IsHomeOwner(player)
  if not player.serverData or not player.serverData.home_basic_info then
    return false
  end
  if player.serverData.home_basic_info.target_home_info then
    return player.serverData.home_basic_info.target_home_info.home_owner_id == player.serverData.base.logic_id
  else
    return player.serverData.home_basic_info.my_home_info.home_owner_id == player.serverData.base.logic_id
  end
end

function FarmUtils.IsCurrentHomeOwner()
  local player = FarmUtils.GetPlayer()
  if not player then
    return false
  end
  return FarmUtils.IsHomeOwner(player)
end

function FarmUtils.GetCurrentWorldHomeInfo()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  if player.serverData and player.serverData.home_basic_info then
    return player.serverData.home_basic_info.target_home_info or player.serverData.home_basic_info.my_home_info
  end
end

function FarmUtils.GetLandOptionStatus(id, sourceLandInfo, isStrict)
  local info = sourceLandInfo or FarmUtils.GetLandInfo(id)
  if FarmUtils.IsLandWateringAvailable(id, info) then
    return FarmModuleEnum.OptionType.Watering
  elseif FarmUtils.IsLandFertilizingAvailable(id, info) then
    return FarmModuleEnum.OptionType.Fertilizing
  elseif FarmUtils.IsLandStealingAvailable(id, info, isStrict) then
    return FarmModuleEnum.OptionType.Stealing
  elseif FarmUtils.IsLandHarvestingAvailable(id, info) then
    return FarmModuleEnum.OptionType.Harvesting
  elseif FarmUtils.IsLandSowingAvailable(id, info) then
    return FarmModuleEnum.OptionType.Sowing
  else
    return FarmModuleEnum.OptionType.None
  end
end

function FarmUtils.GetAllLandAvailable(check_fn)
  if not check_fn then
    Log.Error("FarmUtils.GetAllLandAvailable check_fn is nil")
    return
  end
  if not FarmUtils.IsModuleEnable() then
    return
  end
  local Player = FarmUtils.GetPlayer()
  if not Player then
    Log.Error("FarmUtils.GetAnyLandAvailable Can't find local player")
    return
  end
  if not (Player.serverData and Player.serverData.home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list and Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1]) or not Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list then
    return
  end
  local Result = {}
  _G.MakeWeakTable(Result)
  for id = 1, 15 do
    local info = Player.serverData.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list[id]
    if info and check_fn(id, info) then
      table.insert(Result, info)
    end
  end
  return 0 ~= #Result and Result or nil
end

function FarmUtils.GetNearestLandAvailable(check_fn, pos, maxDist)
  local candidates = FarmUtils.GetAllLandAvailable(check_fn)
  if not candidates or not pos then
    return
  end
  local npcDict = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  if not npcDict then
    return
  end
  local nearest
  local nearestDist = maxDist or math.huge
  for _, candidate in pairs(candidates) do
    local npc = npcDict[candidate.plant_actor_id]
    if npc then
      local landPos = npc.landPos
      if landPos then
        local dist = landPos:Dist(pos)
        if nearestDist > dist then
          nearest = candidate
          nearestDist = dist
        end
      end
    end
  end
  return nearest
end

function FarmUtils.ExtraPlantDisplayInfo(homeInfo, bCheckSteal)
  local plantDisplayInfos = {}
  local homePlantList
  if homeInfo and homeInfo.home_plant_info and homeInfo.home_plant_info.home_plant_land_list and homeInfo.home_plant_info.home_plant_land_list[1] and homeInfo.home_plant_info.home_plant_land_list[1].home_plant_list then
    homePlantList = homeInfo.home_plant_info.home_plant_land_list[1].home_plant_list
  elseif homeInfo and homeInfo.home_plant_info and homeInfo.home_plant_info.cell_home_plant_info and homeInfo.home_plant_info.cell_home_plant_info.home_plant_land_list and homeInfo.home_plant_info.cell_home_plant_info.home_plant_land_list[1] and homeInfo.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list then
    homePlantList = homeInfo.home_plant_info.cell_home_plant_info.home_plant_land_list[1].plant_list
  end
  if not homePlantList then
    return plantDisplayInfos
  end
  local bLocalPlayerReachStealLimit = FarmUtils.IsLocalPlayerReachStealLimit()
  for idx, plantBriefInfo in ipairs(homePlantList) do
    if plantBriefInfo.plant_seed_id and plantBriefInfo.plant_id and plantBriefInfo.plant_rip_time and plantBriefInfo.plant_state and 0 ~= plantBriefInfo.plant_seed_id then
      local plantDisplayInfo = {}
      plantDisplayInfo.landId = plantBriefInfo.plant_id
      plantDisplayInfo.plantSeedId = plantBriefInfo.plant_seed_id
      plantDisplayInfo.plantSeedTabLevel = plantBriefInfo.plant_tab_id
      plantDisplayInfo.plantRipTime = plantBriefInfo.plant_rip_time
      local currentServerTimeStamp = (_G.ZoneServer:GetServerTime() or 0) / 1000
      local bGrowFinish = plantBriefInfo.plant_state == _G.ProtoEnum.PlantStage.FS_RIPE or plantBriefInfo.plant_state == _G.ProtoEnum.PlantStage.FS_SEEDING and plantBriefInfo.plant_rip_time - currentServerTimeStamp <= 0
      plantDisplayInfo.bGrowFinish = bGrowFinish
      local bStealAble
      if bCheckSteal then
        local canStealAccount = false
        if bGrowFinish then
          if plantBriefInfo.plant_state == _G.ProtoEnum.PlantStage.FS_SEEDING then
            canStealAccount = true
          else
            local plantCanStealAccount = plantBriefInfo.plant_can_steal_account or 0
            local plantStealAccount = plantBriefInfo.plant_steal_account or 0
            canStealAccount = plantCanStealAccount > plantStealAccount
          end
        end
        bStealAble = not bLocalPlayerReachStealLimit and canStealAccount
        if bStealAble then
          local bHadSteal = false
          local bTooMuchTimes = false
          if plantBriefInfo.plant_steal_players then
            local stealTimesLimit = 10
            local config = _G.DataConfigManager:GetHomeGlobalConfig("plant_steal_same_plant_role_max")
            if config and config.num then
              stealTimesLimit = config.num
            end
            bTooMuchTimes = stealTimesLimit <= #plantBriefInfo.plant_steal_players
            if not bTooMuchTimes then
              local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
              for idx1, playerUinHadSteal in ipairs(plantBriefInfo.plant_steal_players) do
                if myUin == playerUinHadSteal then
                  bHadSteal = true
                  break
                end
              end
            end
          end
          bStealAble = bStealAble and not bTooMuchTimes and not bHadSteal
        end
      end
      plantDisplayInfo.bStealAble = bStealAble
      table.insert(plantDisplayInfos, plantDisplayInfo)
    end
  end
  return plantDisplayInfos
end

function FarmUtils.GetSeedGrowInfo(seedId, keepUnitCount, bWithFinalStr, SeedTabLevel)
  local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(seedId)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(seedId)
  if nil == plantGrowConf or nil == bagItemConf or not SeedTabLevel then
    return
  end
  local plantGrowGrade = plantGrowConf.plant_grow_grade[SeedTabLevel]
  if not plantGrowGrade then
    return
  end
  local growTimeSecond = 0
  if plantGrowGrade.plant_grow and #plantGrowGrade.plant_grow > 0 then
    for idx, growStage in ipairs(plantGrowGrade.plant_grow) do
      local stageTimeSecond = growStage.plant_stage_time or 0
      growTimeSecond = growTimeSecond + stageTimeSecond
    end
  end
  local minNum = 0
  local maxNum = 0
  if plantGrowGrade.plant_reap_num and #plantGrowGrade.plant_reap_num > 0 then
    minNum = plantGrowGrade.plant_reap_num[1]
    maxNum = plantGrowGrade.plant_reap_num[#plantGrowGrade.plant_reap_num]
  end
  local timeStr, outputStr
  if bWithFinalStr then
    timeStr = FarmUtils.GenerateTimeStr(growTimeSecond, keepUnitCount or 0)
    outputStr = string.format(LuaText.seed_item_grow_yields_value, minNum, maxNum)
  end
  return growTimeSecond, minNum, maxNum, timeStr, outputStr
end

function FarmUtils.GenerateTimeStr(timeSecond, keepUnitCount)
  if type(timeSecond) ~= "number" or timeSecond < 0 then
    return
  end
  timeSecond = math.floor(timeSecond)
  keepUnitCount = keepUnitCount or 0
  keepUnitCount = keepUnitCount - 1
  local originalFmtStr = LuaText.seed_item_grow_time_value
  local allToShowGroupLength = {}
  local allTimeData = {}
  local timeData = {}
  local groupLength = 0
  local day = math.floor(timeSecond / 86400)
  table.insert(timeData, day)
  if 0 ~= day then
    groupLength = groupLength + 1
    if 0 == keepUnitCount then
      timeSecond = 0
    else
      timeSecond = timeSecond - day * 86400
      keepUnitCount = keepUnitCount - 1
    end
  else
    table.insert(allToShowGroupLength, groupLength)
    groupLength = 0
    table.insert(allTimeData, timeData)
    timeData = {}
  end
  local hour = math.floor(timeSecond / 3600)
  table.insert(timeData, hour)
  if 0 ~= hour then
    groupLength = groupLength + 1
    if 0 == keepUnitCount then
      timeSecond = 0
    else
      timeSecond = timeSecond - hour * 3600
      keepUnitCount = keepUnitCount - 1
    end
  else
    table.insert(allToShowGroupLength, groupLength)
    groupLength = 0
    table.insert(allTimeData, timeData)
    timeData = {}
  end
  local min = math.floor(timeSecond / 60)
  table.insert(timeData, min)
  if 0 ~= min then
    groupLength = groupLength + 1
    if 0 == keepUnitCount then
      timeSecond = 0
    else
      timeSecond = timeSecond - min * 60
      keepUnitCount = keepUnitCount - 1
    end
  else
    table.insert(allToShowGroupLength, groupLength)
    groupLength = 0
    table.insert(allTimeData, timeData)
    timeData = {}
  end
  table.insert(timeData, timeSecond)
  if 0 ~= timeSecond then
    groupLength = groupLength + 1
    if 0 == keepUnitCount then
      timeSecond = 0
    else
      timeSecond = 0
      keepUnitCount = keepUnitCount - 1
    end
  else
    table.insert(allToShowGroupLength, groupLength)
    groupLength = 0
    table.insert(allTimeData, timeData)
    timeData = {}
  end
  table.insert(allToShowGroupLength, groupLength)
  groupLength = 0
  table.insert(allTimeData, timeData)
  timeData = {}
  local segmentStartCharIndex = {}
  local strLen = string.len(originalFmtStr)
  local leftIdx, rightIdx = string.find(originalFmtStr, "%%d")
  while leftIdx do
    table.insert(segmentStartCharIndex, leftIdx)
    leftIdx, rightIdx = string.find(originalFmtStr, "%%d", leftIdx + 1)
  end
  table.insert(segmentStartCharIndex, strLen + 1)
  local resultStr
  local segmentIdx = 1
  for groupIdx, validGroupLength in ipairs(allToShowGroupLength) do
    if 0 ~= validGroupLength then
      local ss = table.unpack(allTimeData[groupIdx])
      if resultStr then
        resultStr = resultStr .. string.format(string.sub(originalFmtStr, segmentStartCharIndex[segmentIdx], segmentStartCharIndex[segmentIdx + validGroupLength] - 1), table.unpack(allTimeData[groupIdx]))
      else
        resultStr = string.format(string.sub(originalFmtStr, segmentStartCharIndex[segmentIdx], segmentStartCharIndex[segmentIdx + validGroupLength] - 1), table.unpack(allTimeData[groupIdx]))
      end
      segmentIdx = segmentIdx + validGroupLength
    end
    segmentIdx = segmentIdx + 1
  end
  return resultStr
end

function FarmUtils.MergePlantDisplayInfo(plantDisplayInfos, bOnlyMergeGrowthFinish)
  if not plantDisplayInfos then
    return {}
  end
  
  local function Comparator(infoA, infoB)
    if nil == infoA then
      return false
    end
    if nil == infoB then
      return true
    end
    if infoA.bStealAble == infoB.bStealAble then
      if infoA.plantSeedId == infoB.plantSeedId then
        return infoA.plantRipTime < infoB.plantRipTime
      else
        return infoA.plantSeedId < infoB.plantSeedId
      end
    else
      return infoA.bStealAble
    end
  end
  
  if bOnlyMergeGrowthFinish then
    table.sort(plantDisplayInfos, Comparator)
    local lastValidInfoIdx = 0
    local length = #plantDisplayInfos
    for checkingIdx = 1, length do
      if plantDisplayInfos[lastValidInfoIdx] then
        local bKeepInfo = plantDisplayInfos[lastValidInfoIdx].plantSeedId ~= plantDisplayInfos[checkingIdx].plantSeedId or not plantDisplayInfos[lastValidInfoIdx].bGrowFinish or not plantDisplayInfos[checkingIdx].bGrowFinish
        if bKeepInfo then
          if lastValidInfoIdx + 1 ~= checkingIdx then
            local tmp = plantDisplayInfos[lastValidInfoIdx + 1]
            plantDisplayInfos[lastValidInfoIdx + 1] = plantDisplayInfos[checkingIdx]
            plantDisplayInfos[checkingIdx] = tmp
          end
          lastValidInfoIdx = lastValidInfoIdx + 1
        end
      else
        lastValidInfoIdx = checkingIdx
      end
    end
    for i = 1, length - lastValidInfoIdx do
      table.remove(plantDisplayInfos)
    end
  else
    local candidateInfo = {}
    local candidateCount = 0
    for idx, plantDisplayInfo in ipairs(plantDisplayInfos) do
      if Comparator(plantDisplayInfo, candidateInfo[plantDisplayInfo.plantSeedId]) then
        if candidateInfo[plantDisplayInfo.plantSeedId] == nil then
          candidateCount = candidateCount + 1
        end
        candidateInfo[plantDisplayInfo.plantSeedId] = plantDisplayInfo
      end
    end
    table.sort(plantDisplayInfos, function(infoA, infoB)
      if candidateInfo[infoA.plantSeedId] == infoA and candidateInfo[infoB.plantSeedId] == infoB then
        return Comparator(infoA, infoB)
      else
        return candidateInfo[infoA.plantSeedId] == infoA
      end
    end)
    local pendingRemoveCount = #plantDisplayInfos - candidateCount
    for i = 1, pendingRemoveCount do
      table.remove(plantDisplayInfos)
    end
  end
  return plantDisplayInfos
end

function FarmUtils.IsLocalPlayerReachStealLimit()
  local Player = FarmUtils.GetPlayer()
  if not Player then
    return true
  end
  local limit = 0
  local config = _G.DataConfigManager:GetHomeGlobalConfig("plant_steal_num_max")
  if config then
    limit = config.num
  end
  if Player.serverData and Player.serverData.home_plant_info and Player.serverData.home_plant_info.actor_plant_data and Player.serverData.home_plant_info.actor_plant_data.steal_cnt then
    return limit <= Player.serverData.home_plant_info.actor_plant_data.steal_cnt
  else
    return false
  end
  return true
end

function FarmUtils.AddFloatingText(LandID, ReduceTime)
  if not LandID or not ReduceTime then
    return
  end
  local Target = FarmUtils.GetLandNPC(LandID)
  if not Target then
    return
  end
  local Comp = Target:EnsureComponent(FloatingText2DComponent)
  local FmtTimeStr = FarmUtils.GenerateTimeStr(ReduceTime, 2)
  if FmtTimeStr then
    Comp:AddFloatingText("-" .. FmtTimeStr, true)
  else
    Log.Error("\231\186\179\229\176\188\239\188\140\233\156\128\232\166\129\230\181\135\230\176\180\233\163\152\229\173\151\228\189\134\230\152\175\231\156\139\232\181\183\230\157\165\230\181\135\230\176\180\233\163\152\229\173\151\230\151\182\233\149\191\228\184\141\229\144\136\231\144\134\239\188\140\230\152\175\228\184\141\230\152\175\229\144\140\230\173\165\230\133\162\228\186\134", ReduceTime)
  end
end

function FarmUtils.IsOptionStandingLandSame(option)
  if option:IsFarmOption() then
    local landInfo = option:GetOwnerFarmlandInfo()
    local landId = landInfo and landInfo.plant_id or -1
    local playerStandingLandId = _G.NRCModuleManager:DoCmd(_G.FarmModuleCmd.GetCurrentStandingLandId)
    return landId == playerStandingLandId
  end
  return false
end

function FarmUtils.IsPlayerHasCurrentAction()
  local Player = FarmUtils.GetPlayer()
  if Player and Player.interactionComponent then
    return Player.interactionComponent:HasInteractingAction()
  end
  return false
end

function FarmUtils.FixPlantNPCCoordinate(landId)
  local landInfo = FarmUtils.GetLandInfo(landId)
  if 0 == landId then
    return
  end
  if not landInfo then
    Log.Debug("FarmUtils.FixPlantNPCCoordinate landInfo not found", landId)
    return
  end
  local npcID = landInfo.plant_actor_id
  if 0 == npcID then
    return
  end
  local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcID)
  if not npc or not npc.viewObj then
    Log.Debug("FarmUtils.FixPlantNPCCoordinate npc not found", npcID)
    return
  end
  local landNPC = FarmUtils.GetLandNPC(landId)
  if not landNPC or not landNPC.viewObj then
    Log.Debug("Utils.FixPlantNPCCoordinate landNPC not found", landId)
    return
  end
  local conf = _G.DataConfigManager:GetHomeGlobalConfig("plant_rise_height")
  local heightOffset = conf.num or 18
  local pos = landNPC:GetActorLocation()
  pos.z = pos.z + heightOffset
  npc:SetActorLocation(pos)
end

return FarmUtils
