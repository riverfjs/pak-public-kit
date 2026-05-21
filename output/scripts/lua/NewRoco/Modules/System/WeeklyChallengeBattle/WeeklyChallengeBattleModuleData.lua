local WeeklyChallengeBattleModuleData = _G.NRCData:Extend("WeeklyChallengeBattleModuleData")
local WeeklyChallengeBattleModuleEnum = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEnum")
local JsonUtils = require("Common.JsonUtils")
local _CurrentWeeklyBattleTeamConfigFilename = "WeeklyBattleConfig"

function WeeklyChallengeBattleModuleData:Ctor()
  NRCData.Ctor(self)
  self.currentActivityId = nil
  self.CurrentTeamPetList = {
    {},
    {},
    {},
    {},
    {},
    {}
  }
  self.PetResetInfo = {}
  self.PetResetLevel = 0
  self.PetResetGrow = 0
  self.PetResetWorkHard = 0
  self.bIsNeedBalance = false
  self.CurrentTeamSkill = 0
  self.bIsInit = false
  self.FirstDebutPet = {}
  self.AllUsablePetGids = {}
  self.AllPetBalancedDataMap = {}
  self.PendingQueryPetGids = {}
  self.IsQueryingAllPetBalanceData = false
end

function WeeklyChallengeBattleModuleData:FetchCurrentEventId()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return
  end
  self.currentActivityId = WeeklyChallengeEventActivityObject[1]:GetActivityId()
end

function WeeklyChallengeBattleModuleData:RefetchTeamList()
  self.CurrentTeamPetList = self:_LoadCacheTeamList()
end

function WeeklyChallengeBattleModuleData:_LoadCacheTeamList()
  local playerTeam = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  if not (playerTeam and playerTeam.teams) or 0 == #playerTeam.teams then
    return {
      {},
      {},
      {},
      {},
      {},
      {}
    }
  end
  local bIsDirty = false
  local result = {}
  if playerTeam.teams[1].pet_infos then
    for k, v in ipairs(playerTeam.teams[1].pet_infos) do
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.pet_gid)
      if self:_IsThisWeekCatchPet(petData) then
        table.insert(result, petData)
      else
        bIsDirty = true
      end
    end
  end
  if #result < 6 then
    for i = 0, 6 do
      table.insert(result, {})
      if #result >= 6 then
        break
      end
    end
  end
  return result, bIsDirty
end

function WeeklyChallengeBattleModuleData:_LoadCacheSkill()
  local playerTeam = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  if not (playerTeam and playerTeam.teams) or 0 == #playerTeam.teams then
    return 0
  end
  if playerTeam.teams[1].role_magic_gid then
    return playerTeam.teams[1].role_magic_gid
  end
  return 0
end

function WeeklyChallengeBattleModuleData:_IsThisWeekCatchPet(petData)
  if not petData or type(petData.add_time) ~= "number" then
    return false
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return false
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    return false
  end
  local eventConf = _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  if not eventConf or type(eventConf.start_time) ~= "string" then
    return false
  end
  local TimeUtils = require("NewRoco.Modules.System.EnvSystem.TimeUtils")
  local startTimestamp = TimeUtils.ToTimeStamp(eventConf.start_time)
  if 0 == startTimestamp then
    Log.Error("WeeklyChallengeBattleModuleData:_IsThisWeekCatchPet: Failed to parse start_time:", eventConf.start_time)
    return false
  end
  return startTimestamp < petData.add_time
end

function WeeklyChallengeBattleModuleData:GetCurrentTeamPetList()
  if not self.bIsInit then
    local bIsDirty = false
    self.bIsInit = true
    self.CurrentTeamSkill = self:_LoadCacheSkill()
    self.CurrentTeamPetList, bIsDirty = self:_LoadCacheTeamList()
    if bIsDirty then
      self.CurrentTeamSkill = 0
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendSaveTeamReq)
    end
  end
  return self.CurrentTeamPetList
end

function WeeklyChallengeBattleModuleData:GetCurrentTeamSkill()
  if not self.bIsInit then
    local bIsDirty = false
    self.bIsInit = true
    self.CurrentTeamSkill = self:_LoadCacheSkill()
    self.CurrentTeamPetList, bIsDirty = self:_LoadCacheTeamList()
    if bIsDirty then
      self.CurrentTeamSkill = 0
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendSaveTeamReq)
    end
  end
  return self.CurrentTeamSkill
end

function WeeklyChallengeBattleModuleData:GetFirstDebutPetGid()
  if self.FirstDebutPet then
    return self.FirstDebutPet.gid
  else
    Log.Error("WeeklyChallengeBattleModuleData  guid is nil")
    return nil
  end
end

function WeeklyChallengeBattleModuleData:AddPetToTeam(petData, position)
  for k, v in ipairs(self.CurrentTeamPetList) do
    if petData.gid == v.gid and v.gid and 0 ~= v.gid then
      Log.Error(string.format("WeeklyChallengeBattleModuleData:AddPetToTeam \229\176\157\232\175\149\229\144\145\233\152\159\228\188\141\228\184\173\229\138\160\229\133\165\231\155\184\229\144\140\231\154\132\229\174\160\231\137\169 gid %d position %d", petData.gid, position))
      return
    end
  end
  if position < 1 or position > 6 then
    return
  end
  if not petData.gid then
    return
  end
  if self.CurrentTeamPetList[position].gid then
    self:RemovePetFromTeam(self.CurrentTeamPetList[position].gid)
  end
  Log.Info(string.format("WeeklyChallengeBattleModuleData:AddPetToTeam \229\144\145\233\152\159\228\188\141\229\138\160\229\133\165\230\150\176\229\174\160\231\137\169 gid %d, position %d", petData.gid, position))
  self.CurrentTeamPetList[position] = petData
end

function WeeklyChallengeBattleModuleData:RemovePetFromTeam(petGid)
  for k, v in ipairs(self.CurrentTeamPetList) do
    if v.gid and petGid == v.gid and 0 ~= v.gid then
      Log.Info(string.format("WeeklyChallengeBattleModuleData:RemovePetFromTeam \231\167\187\233\153\164\229\174\160\231\137\169 %d, %d", petGid, k))
      self.CurrentTeamPetList[k] = {}
    end
  end
end

function WeeklyChallengeBattleModuleData:UpdatePetData(newPetData)
  if not newPetData then
    Log.Error("WeeklyChallengeBattleModuleData newPetData is nil")
    return
  end
  local index = 0
  for k, v in ipairs(self.CurrentTeamPetList) do
    if v.gid == newPetData.gid then
      index = k
      break
    end
  end
  if index > 0 and index <= 6 then
    self.CurrentTeamPetList[index] = newPetData
  end
end

function WeeklyChallengeBattleModuleData:GetAllUsablePetGids()
  return self.AllUsablePetGids
end

function WeeklyChallengeBattleModuleData:GetPetBalancedDataByGid(gid)
  if not self.bIsNeedBalance then
    return _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
  end
  return self.AllPetBalancedDataMap[gid]
end

function WeeklyChallengeBattleModuleData:IsAllPetBalancedDataReady()
  return not self.IsQueryingAllPetBalanceData and 0 == #self.PendingQueryPetGids
end

function WeeklyChallengeBattleModuleData:ClearAllPetBalancedDataCache()
  self.AllUsablePetGids = {}
  self.AllPetBalancedDataMap = {}
  self.PendingQueryPetGids = {}
  self.IsQueryingAllPetBalanceData = false
end

return WeeklyChallengeBattleModuleData
