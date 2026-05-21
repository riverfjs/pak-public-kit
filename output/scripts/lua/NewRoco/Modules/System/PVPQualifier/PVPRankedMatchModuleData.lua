local PVPRankedMatchModuleData = _G.NRCData:Extend("PVPRankedMatchModuleData")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local PVPRankedMatchModuleEnum = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local ProtoMessage = require("Data.PB.ProtoMessage")
local PetUtils = require("NewRoco.Utils.PetUtils")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local kSaveGameSlotName = "PVPRankedMatchModuleDataSaveGameSlot"

function PVPRankedMatchModuleData:Ctor()
  NRCData.Ctor(self)
  self:InitSaveGame()
  self.OpenTeamType = _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4
  local RankTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PVP_RANK_CONF)
  self.MaxRankStar = RankTable:GetDataCount()
  self:InitPvpRandomPetRewardData()
  self:InitRankGrades(RankTable)
  self:InitRandomPetMap()
  self:InitSeasonRecordData()
end

function PVPRankedMatchModuleData:OnDestruct()
  self:ReleaseSaveGame()
  self.lastZonePvpInfoQueryRspTime = 0
end

function PVPRankedMatchModuleData:InitSaveGame()
  self.saveDataCache = nil
  self.saveDataProxy = NewObject(UE.UAsyncSaveGameHandle, UE4.UNRCPlatformGameInstance.GetInstance(), kSaveGameSlotName)
  self.saveDataProxyRef = UnLua.Ref(self.saveDataProxy)
  self.saveDataProxy.Completed:Add(self.saveDataProxy, function(proxy, saveData, bSuccess)
    Log.Debug("PVPRankedMatchModuleData saveDataProxy loaded. caller=", proxy, ", saveData=", saveData, ", bSuccess=", bSuccess)
    if not (bSuccess and saveData) or not UE.UObject.IsValid(saveData) then
      Log.Debug("PVPRankedMatchModuleData saveDataProxy loaded but failed or saveData is nil or invalid.")
      return
    end
    self:ApplySaveDataCacheToSaveGame()
  end)
  self.saveDataProxy:AsyncLoadByRawClassPath(_G.UEPath.BP_PVPRankedMatchModuleSaveGame, kSaveGameSlotName)
end

function PVPRankedMatchModuleData:ApplySaveDataCacheToSaveGame(saveData)
  Log.Debug("PVPRankedMatchModuleData saveData loaded and try apply cache data.")
  if self.saveDataCache then
    for k, v in pairs(self.saveDataCache) do
      Log.Debug("PVPRankedMatchModuleData saveData loaded and applied cache data. key=", k, ", value=", v)
      saveData:SetTimestamp(k, v)
    end
    self.saveDataCache = nil
  end
end

function PVPRankedMatchModuleData:GetSaveData()
  return self.saveDataProxy and self.saveDataProxy.SaveGameObject
end

function PVPRankedMatchModuleData:ReleaseSaveGame()
  local saveData = self:GetSaveData()
  if saveData then
    UE4.UGameplayStatics.SaveGameToSlot(saveData, kSaveGameSlotName, 0)
  end
  self.saveDataProxy = nil
  self.saveDataProxyRef = nil
  self.saveDataCache = nil
end

function PVPRankedMatchModuleData:GetPVPQualifierTeamType()
  return self.OpenTeamType
end

function PVPRankedMatchModuleData:SetPvpHisQueryData(rsp)
  self.HistoryData = {}
  if rsp.his then
    for index = #rsp.his, 1, -1 do
      local data = rsp.his[index]
      table.insert(self.HistoryData, data)
    end
  end
  self.WinCount = rsp.win_count
  self.LoseCount = rsp.lose_count
end

function PVPRankedMatchModuleData:GetPvpHisQueryData()
  return self.HistoryData
end

function PVPRankedMatchModuleData:GetPvpHistoryWinLoseCount()
  return self.WinCount, self.LoseCount
end

function PVPRankedMatchModuleData:DebugDumpPvpInfoQueryData(bEnable)
  self.__debugDumpPvpInfoQueryData = bEnable
end

function PVPRankedMatchModuleData:DebugSeasonId(id)
  self.__debugSeasonId = id
end

function PVPRankedMatchModuleData:SetPvpInfoQueryData(rsp)
  if self.__debugDumpPvpInfoQueryData then
    Log.Dump(rsp, 10, "xxxxx:ZonePvpInfoQueryRsp")
  end
  self.lastZonePvpInfoQueryRspTime = os.time()
  self.pvpSeasonData = {}
  local seasonData = self.pvpSeasonData
  seasonData.seasonId = rsp.season_id
  self.pvpSeasonId = rsp.season_id
  seasonData.seasonStep = rsp.step
  seasonData.stepFinishTime = rsp.step_finish_ut
  seasonData.pvpRankStar = PVPRankedMatchModuleUtils.CorrectionRankStar(rsp.pvp_rank_star)
  seasonData.pvpRankOrder = rsp.pvp_rank_order
  seasonData.starReward = rsp.star_reward
  seasonData.weekReward = rsp.week_reward
  seasonData.weekRefreshTime = rsp.week_refresh_ut
  seasonData.weekWinCount = rsp.week_win_count
  seasonData.weekWinCountRequired = rsp.week_win_count_required
  local trialPet = rsp.trial_pet or _G.RankMatchTrialPet
  if trialPet then
    _G.RankMatchTrialPet = trialPet
    seasonData.trial_pet = trialPet
    self:SetTrailPetMap(trialPet.pets)
  end
  seasonData.pvp_week_benefit = rsp.pvp_week_benefit
  seasonData.top_master = rsp.top_master
  if seasonData.top_master then
    seasonData.top_master.type = seasonData.top_master.type or ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE
    seasonData.top_master.prev_type = seasonData.top_master.prev_type or ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE
    seasonData.top_master.next_type = seasonData.top_master.next_type or ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE
  end
  seasonData.prev_season_star = rsp.prev_season_star
  seasonData.daily_first_win_time = rsp.daily_first_win_time
end

function PVPRankedMatchModuleData:CheckPvpSeasonData()
  if not self.pvpSeasonData then
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq)
    Log.Error("PVP\230\142\146\228\189\141\232\181\155\232\181\155\229\173\163\230\149\176\230\141\174\229\188\130\229\184\184\239\188\140\230\163\128\230\181\139OnCmdZonePvpInfoQueryReq\230\152\175\229\144\166\232\191\148\229\155\158\230\173\163\231\161\174\230\149\176\230\141\174")
    return false
  end
  return true
end

function PVPRankedMatchModuleData:IsZonePvpInfoQueryRspExceed()
  if self.lastZonePvpInfoQueryRspTime then
    local now = os.time()
    if now - self.lastZonePvpInfoQueryRspTime < 5 then
      return false
    end
  end
  return true
end

function PVPRankedMatchModuleData:GetCurSeasonId()
  local seasonId
  local __debugSeasonId = self.__debugSeasonId
  local pvpSeasonData = self.pvpSeasonData
  local pvpSeasonDataSeasonId = pvpSeasonData and pvpSeasonData.seasonId
  local pvpSeasonId = self.pvpSeasonId
  if __debugSeasonId and __debugSeasonId > 0 then
    seasonId = __debugSeasonId
  elseif pvpSeasonDataSeasonId then
    seasonId = pvpSeasonDataSeasonId
  elseif pvpSeasonId then
    seasonId = pvpSeasonId
  end
  return seasonId
end

function PVPRankedMatchModuleData:GetCurSeasonStep()
  if not self:CheckPvpSeasonData() then
    return -1
  end
  return self.pvpSeasonData.seasonStep
end

function PVPRankedMatchModuleData:IsSeasonStepSettle()
  local step = self:GetCurSeasonStep()
  return step == ProtoEnum.PVP_RANK_STEP.STEP_SETTLE
end

function PVPRankedMatchModuleData:GetCurStepFinishTime()
  if not self:CheckPvpSeasonData() then
    return -1
  end
  return self.pvpSeasonData.stepFinishTime
end

function PVPRankedMatchModuleData:GetCurPvpRankStar()
  if not self:CheckPvpSeasonData() then
    return -1
  end
  return self.pvpSeasonData.pvpRankStar
end

function PVPRankedMatchModuleData:GetCurPvpRankOrder()
  if not self:CheckPvpSeasonData() then
    return -1
  end
  return self.pvpSeasonData.pvpRankOrder
end

function PVPRankedMatchModuleData:GetCurStarReward()
  if not self:CheckPvpSeasonData() then
    return nil
  end
  return self.pvpSeasonData.starReward
end

function PVPRankedMatchModuleData:GetStarRewardById(rewardId)
  if not self.pvpSeasonData or not self.pvpSeasonData.starReward then
    return nil
  end
  for _, reward in pairs(self.pvpSeasonData.starReward) do
    if rewardId == reward.reward_id then
      return reward
    end
  end
  return nil
end

function PVPRankedMatchModuleData:GetCurWeekReward()
  if not self:CheckPvpSeasonData() then
    return nil
  end
  return self.pvpSeasonData.weekReward
end

function PVPRankedMatchModuleData:GetCurWeekRefreshTime()
  if not self:CheckPvpSeasonData() then
    return
  end
  return self.pvpSeasonData.weekRefreshTime
end

function PVPRankedMatchModuleData:GetCurWeekWinCount()
  if not self:CheckPvpSeasonData() then
    return 0, 0
  end
  return self.pvpSeasonData.weekWinCount, self.pvpSeasonData.weekWinCountRequired
end

function PVPRankedMatchModuleData:GetCurWeekWinCountRequired()
  if not self:CheckPvpSeasonData() then
    return
  end
  return self.pvpSeasonData.weekWinCountRequired
end

function PVPRankedMatchModuleData:GetPvpWeekBenefit()
  return self:CheckPvpSeasonData() and self.pvpSeasonData.pvp_week_benefit
end

function PVPRankedMatchModuleData:GetTopMaster()
  local module = NRCModuleManager:GetModule("PVPRankedMatchModule")
  if module and module.__debugTopMasterPrev and module.__debugTopMasterCur and module.__debugTopMasterNext then
    return {
      prev_type = module.__debugTopMasterPrev,
      type = module.__debugTopMasterCur,
      next_type = module.__debugTopMasterNext
    }
  end
  if self.pvpSeasonData and self.pvpSeasonData.top_master then
    return self.pvpSeasonData.top_master
  else
    return {
      type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE,
      prev_type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE,
      next_type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE
    }
  end
end

function PVPRankedMatchModuleData:GetPrevSeasonRankStar()
  if not self:CheckPvpSeasonData() then
    return
  end
  local star = self.pvpSeasonData.prev_season_star or 1
  local module = NRCModuleManager:GetModule("PVPRankedMatchModule")
  if module and module.__debugSeasonOpenPrevStarNum and module.__debugSeasonOpenPrevStarNum > 0 then
    star = module.__debugSeasonOpenPrevStarNum
  end
  return PVPRankedMatchModuleUtils.CorrectionRankStar(star)
end

function PVPRankedMatchModuleData:GetDailyFirstWinTime()
  return self:CheckPvpSeasonData() and self.pvpSeasonData.daily_first_win_time or 0
end

function PVPRankedMatchModuleData:UpdateOneWeekReward(Rewards)
  if not self.pvpSeasonData.weekReward then
    self.pvpSeasonData.weekReward = {}
  end
  if not Rewards then
    return
  end
  for _, newReward in pairs(Rewards) do
    for index, Reward in pairs(self.pvpSeasonData.weekReward) do
      if newReward.id == Reward.id then
        self.pvpSeasonData.weekReward[index] = newReward
        break
      end
    end
  end
end

function PVPRankedMatchModuleData:UpdateStarReward(rewards)
  if not self.pvpSeasonData.starReward then
    self.pvpSeasonData.starReward = {}
  end
  if not rewards then
    return
  end
  local newRewardMap = {}
  for _, newReward in pairs(rewards) do
    newRewardMap[newReward.id] = newReward
  end
  for index, reward in pairs(self.pvpSeasonData.starReward) do
    local newReward = newRewardMap[reward.id]
    if newReward then
      self.pvpSeasonData.starReward[index] = newReward
    end
  end
end

function PVPRankedMatchModuleData:GetMaxRankStar()
  return self.MaxRankStar
end

function PVPRankedMatchModuleData:SetTrailPetMap(pets)
  self.TrialPetMap = {}
  if pets then
    for _, petData in pairs(pets) do
      self.TrialPetMap[petData.gid] = petData
    end
  end
end

function PVPRankedMatchModuleData:IsTrailPet(petGid)
  if self.TrialPetMap and self.TrialPetMap[petGid] then
    return true, self.TrialPetMap[petGid]
  else
    return false
  end
end

function PVPRankedMatchModuleData:GetTrialPets()
  if self.pvpSeasonData and self.pvpSeasonData.trial_pet then
    return self.pvpSeasonData.trial_pet.pets
  end
end

function PVPRankedMatchModuleData:GetTrialPetBrief()
  if self.pvpSeasonData and self.pvpSeasonData.trial_pet then
    return self.pvpSeasonData.trial_pet.brief
  end
  return nil
end

function PVPRankedMatchModuleData:GetTrialPetBriefRefreshTime()
  if self.pvpSeasonData and self.pvpSeasonData.trial_pet then
    return self.pvpSeasonData.trial_pet.brief.refresh_time
  else
    Log.Error("\232\175\149\231\148\168\231\178\190\231\129\181\230\149\176\230\141\174\229\188\130\229\184\184 self.pvpSeasonData=", self.pvpSeasonData)
    if self.pvpSeasonData then
      Log.Error("\232\175\149\231\148\168\231\178\190\231\129\181\230\149\176\230\141\174\229\188\130\229\184\184 self.pvpSeasonData.trial_pet=", self.pvpSeasonData.trial_pet, "\229\133\168\229\177\128\232\175\149\231\148\168\231\178\190\231\129\181\230\149\176\230\141\174=", _G.RankMatchTrialPet)
    end
  end
  return 0
end

function PVPRankedMatchModuleData:GetRandomPets(option)
  option = option and option or {}
  local inTeamGidDic = option and option.inTeamGidDic or {}
  local allRandomPets = {}
  local RandomPetMap = self.RandomPetMap or {}
  for gid, petData in pairs(RandomPetMap) do
    table.insert(allRandomPets, petData)
  end
  local randomPets = {}
  randomPets = allRandomPets
  if option.removeInTeamGid then
    local randomPetsRemoveInTeamGid = {}
    for i, petData in ipairs(randomPets) do
      if inTeamGidDic[petData.gid] then
      else
        table.insert(randomPetsRemoveInTeamGid, petData)
      end
    end
    randomPets = randomPetsRemoveInTeamGid
  end
  if option.removeSameBloodPetData then
    local bPreferNonTeam = option.preferNonTeamPetInSameBlood
    local uniqueSkillDamTypeMap = {}
    for i, petData in ipairs(randomPets) do
      local typeInfo = petData and petData.type
      local typeInfoParam = typeInfo and typeInfo.param
      local skillDamType = typeInfoParam
      if skillDamType then
        local existing = uniqueSkillDamTypeMap[skillDamType]
        if not existing then
          uniqueSkillDamTypeMap[skillDamType] = petData
        elseif bPreferNonTeam then
          local existingGid = existing and existing.gid
          local petDataGid = petData and petData.gid
          local existingInTeam = existingGid and nil ~= inTeamGidDic[existingGid]
          local currentInTeam = petDataGid and nil ~= inTeamGidDic[petDataGid]
          if existingInTeam and not currentInTeam then
            uniqueSkillDamTypeMap[skillDamType] = petData
          end
        end
      end
    end
    local uniqueBloodList = {}
    for skillDamType, petData in pairs(uniqueSkillDamTypeMap) do
      table.insert(uniqueBloodList, petData)
    end
    randomPets = uniqueBloodList
  end
  table.sort(randomPets, function(petDataA, petDataB)
    local typeInfoA = petDataA and petDataA.type
    local typeInfoParamA = typeInfoA and typeInfoA.param
    local skillDamTypeA = typeInfoParamA
    local typeInfoB = petDataB and petDataB.type
    local typeInfoParamB = typeInfoB and typeInfoB.param
    local skillDamTypeB = typeInfoParamB
    return skillDamTypeA < skillDamTypeB
  end)
  return randomPets
end

function PVPRankedMatchModuleData:InitRandomPetMap()
  local randomPetSkillDamTypeCountList = {
    [0] = BattleConst.MaxPureRandomPetCount + 1,
    [Enum.SkillDamType.SDT_COMMON] = 1,
    [Enum.SkillDamType.SDT_GRASS] = 1,
    [Enum.SkillDamType.SDT_FIRE] = 1,
    [Enum.SkillDamType.SDT_WATER] = 1,
    [Enum.SkillDamType.SDT_LIGHT] = 1,
    [Enum.SkillDamType.SDT_STONE] = 1,
    [Enum.SkillDamType.SDT_ICE] = 1,
    [Enum.SkillDamType.SDT_DRAGON] = 1,
    [Enum.SkillDamType.SDT_ELECTRIC] = 1,
    [Enum.SkillDamType.SDT_TOXIC] = 1,
    [Enum.SkillDamType.SDT_INSECT] = 1,
    [Enum.SkillDamType.SDT_FIGHT] = 1,
    [Enum.SkillDamType.SDT_WING] = 1,
    [Enum.SkillDamType.SDT_MOE] = 1,
    [Enum.SkillDamType.SDT_GHOST] = 1,
    [Enum.SkillDamType.SDT_DEMON] = 1,
    [Enum.SkillDamType.SDT_MECHANIC] = 1,
    [Enum.SkillDamType.SDT_PHANTOM] = 1
  }
  self.RandomPetMap = {}
  local randomPetGuid = BattleConst.RandomPetGidStart
  local commonRandomPetBaseConfId = PetUtils.GetRandomPetBaseConfIdFromSkillDamType(ProtoEnum.SkillDamType.SDT_COMMON)
  local commonRandomPetBaseConf = _G.DataConfigManager:GetPetbaseConf(commonRandomPetBaseConfId, true)
  local commonRandomPetBaseConfPetName = commonRandomPetBaseConf and commonRandomPetBaseConf.name or ""
  for skillDamType, count in pairs(randomPetSkillDamTypeCountList) do
    for i = 1, count do
      randomPetGuid = randomPetGuid + 1
      local randomPetData = ProtoMessage:newPetData()
      randomPetData.type.type = ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM
      randomPetData.type.param = skillDamType
      randomPetData.gid = randomPetGuid
      randomPetData.name = commonRandomPetBaseConfPetName
      self.RandomPetMap[randomPetGuid] = randomPetData
    end
  end
end

function PVPRankedMatchModuleData:IsRandomPet(petGid)
  local randomPet = self.RandomPetMap and self.RandomPetMap[petGid]
  if randomPet then
    return true, randomPet
  else
    return false
  end
end

function PVPRankedMatchModuleData:GetAnyRandomPetGid(option)
  option = option and option or {}
  option.skillDamType = option.skillDamType and option.skillDamType or 0
  option.inTeamGidDic = option.inTeamGidDic and option.inTeamGidDic or {}
  local resGid
  for gid, petData in pairs(self.RandomPetMap) do
    if option.filterSameSkillDamType then
      local bloodType = petData and petData.blood_id
      local typeInfo = petData and petData.type
      local typeInfoType = typeInfo and typeInfo.type
      local skillDamType = typeInfo and typeInfo.param
      if option.skillDamType ~= skillDamType then
    end
    elseif option.filterNotInTeam and option.inTeamGidDic[gid] then
    else
      resGid = gid
    end
  end
  return resGid
end

function PVPRankedMatchModuleData:InitPvpRandomPetRewardData()
  self.RandomPetRewordIndexMap = {}
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PVP_RANDOM_PET_REWARD_CONF)
  local cfgDataList = cfgTable:GetAllDatas()
  for i, conf in ipairs(cfgDataList) do
    local random_pet = conf.random_pet or 0
    local random_type_pet = conf.random_type_pet or 0
    if not self.RandomPetRewordIndexMap[random_pet] then
      self.RandomPetRewordIndexMap[random_pet] = {}
    end
    self.RandomPetRewordIndexMap[random_pet][random_type_pet] = conf
  end
end

function PVPRankedMatchModuleData:InitRankGrades(RankTable)
  local groupedDatas = {}
  local allDatas = RankTable:GetAllDatas()
  for k, data in pairs(allDatas) do
    local key = data.name_only
    local group = groupedDatas[key]
    if nil == group then
      local newGroup = {
        key = key,
        grade = 0,
        datasInGrade = {}
      }
      groupedDatas[key] = newGroup
      group = newGroup
    end
    table.insert(group.datasInGrade, data)
  end
  local sortedGroups = {}
  for _, group in pairs(groupedDatas) do
    table.sort(group.datasInGrade, function(a, b)
      return a.ID < b.ID
    end)
    table.insert(sortedGroups, group)
  end
  table.sort(sortedGroups, function(a, b)
    return a.datasInGrade[1].ID < b.datasInGrade[1].ID
  end)
  for i, group in ipairs(sortedGroups) do
    group.grade = i
  end
  local m = {}
  local maxStarNum = 1
  for _, group in ipairs(sortedGroups) do
    for _, data in ipairs(group.datasInGrade) do
      local starNum = data.ID
      local grade = {
        grade = group.grade,
        star_num = data.star_num,
        star_total = data.star_total
      }
      m[starNum] = grade
      maxStarNum = math.max(maxStarNum, starNum)
    end
  end
  for i = 1, maxStarNum do
    if not m[i] then
      Log.Error("PVP\230\142\146\228\189\141\232\181\155\230\174\181\228\189\141\233\133\141\231\189\174\232\161\168(PVP_RANK_CONF)\229\173\152\229\156\168\231\169\186\231\188\186\230\152\159\230\152\159\230\149\176:", i)
    end
  end
  self.RankGradesMap = m
end

function PVPRankedMatchModuleData:GetRankGrade(curStarNum)
  if self.RankGradesMap then
    local grade = self.RankGradesMap[curStarNum]
    if grade then
      return grade
    end
  end
  local dummy_grade = {
    grade = 1,
    star_num = 1,
    star_total = 1
  }
  return dummy_grade
end

local SpineAnimConfig = NRCClass("SpineAnimConfig")

function SpineAnimConfig:Ctor(show, out, loop, upgrade, downgrade)
  self.show = show
  self.out = out
  self.loop = loop
  self.upgrade = upgrade
  self.downgrade = downgrade
end

local GradingAnimConf = {
  SpineAnimConfig("A_1_In", "A_1_Out", "A_1_loop", "A_1_up", nil),
  SpineAnimConfig("A_2_In", "A_2_Out", "A_2_loop", "A_2_up", "A_2-1"),
  SpineAnimConfig("A_3_In", "A_3_Out", "A_3_loop", "A_3_up", "A_3-2"),
  SpineAnimConfig("A_4_In", "A_4_Out", "A_4_loop", "A_4_up", "A_4-3"),
  SpineAnimConfig("A_5_In", "A_5_Out", "A_5_loop", "A_5_up_A-B", "A_5-4"),
  SpineAnimConfig("B_1_In", "B_1_Out", "B_1_loop", "B_1_up", nil),
  SpineAnimConfig("B_2_In", "B_2_Out", "B_2_loop", "B_2_up", "B_2-1"),
  SpineAnimConfig("B_3_In", "B_3_Out", "B_3_loop", "B_3_up", "B_3-2"),
  SpineAnimConfig("B_4_In", "B_4_Out", "B_4_loop", "B_4_up", "B_4-3"),
  SpineAnimConfig("B_5_In", "B_5_Out", "B_5_loop", "B_5_up_B-C", "B_5-4"),
  SpineAnimConfig("C_1_In", "C_1_Out", "C_1_loop", "C_1_up", nil),
  SpineAnimConfig("C_2_In", "C_2_Out", "C_2_loop", "C_2_up", "C_2-1"),
  SpineAnimConfig("C_3_In", "C_3_Out", "C_3_loop", "C_3_up", "C_3-2"),
  SpineAnimConfig("C_4_In", "C_4_Out", "C_4_loop", "C_4_up", "C_4-3"),
  SpineAnimConfig("C_5_In", "C_5_Out", "C_5_loop", "C_5_up_C-D", "C_5-4"),
  SpineAnimConfig("D_1_In", "D_1_Out", "D_1_loop", "D_1_up", nil),
  SpineAnimConfig("D_2_In", "D_2_Out", "D_2_loop", "D_2_up", "D_2-1"),
  SpineAnimConfig("D_3_In", "D_3_Out", "D_3_loop", "D_3_up", "D_3-2"),
  SpineAnimConfig("D_4_In", "D_4_Out", "D_4_loop", "D_4_up", "D_4-3"),
  SpineAnimConfig("D_5_In", "D_5_Out", "D_5_loop", "D_5_up_D-E", "D_5-4"),
  SpineAnimConfig("E_1_In", "E_1_Out", "E_1_loop", "E_1_up", nil),
  SpineAnimConfig("E_2_In", "E_2_Out", "E_2_loop", "E_2_up", "E_2-1"),
  SpineAnimConfig("E_3_In", "E_3_Out", "E_3_loop", "E_3_up", "E_3-2"),
  SpineAnimConfig("E_4_In", "E_4_Out", "E_4_loop", "E_4_up", "E_4-3"),
  SpineAnimConfig("E_5_In", "E_5_Out", "E_5_loop", "E_5_up_E-F", "E_5-4"),
  SpineAnimConfig("F_1_In", "F_1_Out", "F_1_loop", "F_1_up", nil),
  SpineAnimConfig("F_2_In", "F_2_Out", "F_2_loop", "F_2_up", "F_2-1"),
  SpineAnimConfig("F_3_In", "F_3_Out", "F_3_loop", "F_3_up", "F_3-2"),
  SpineAnimConfig("F_4_In", "F_4_Out", "F_4_loop", "F_4_up", "F_4-3"),
  SpineAnimConfig("F_5_In", "F_5_Out", "F_5_loop", "F_5_up_F-G", "F_5-4"),
  SpineAnimConfig("G_1_In", "G_1_Out", "G_1_loop", "G_1_up", nil)
}

function PVPRankedMatchModuleData:GetGradingAnimConfig(newStarNum, bTopMaster, bDanGrading)
  local grade = self:GetRankGrade(newStarNum)
  local conf = GradingAnimConf[grade.grade]
  if grade.grade == #GradingAnimConf and bTopMaster then
    if bDanGrading then
      conf = SpineAnimConfig("G_2_In", nil, "G_2_loop", nil, nil)
    else
      conf = SpineAnimConfig("G_2_In", nil, "G_2_loop", nil, "G_2-1")
    end
  end
  return conf
end

function PVPRankedMatchModuleData:GetTimestamp(name)
  local saveData = self:GetSaveData()
  if saveData then
    return saveData:GetTimestamp(name)
  elseif self.saveDataCache then
    return self.saveDataCache[name] or 0
  end
  return 0
end

function PVPRankedMatchModuleData:SetTimestamp(name, timeStamp)
  local saveData = self:GetSaveData()
  if saveData then
    saveData:SetTimestamp(name, timeStamp)
    UE4.UGameplayStatics.SaveGameToSlot(saveData, kSaveGameSlotName, 0)
  else
    if not self.saveDataCache then
      self.saveDataCache = {}
    end
    self.saveDataCache[name] = timeStamp
  end
end

function PVPRankedMatchModuleData:HasPvpSeasonData()
  return self.pvpSeasonData ~= nil
end

function PVPRankedMatchModuleData:InitSeasonRecordData()
  local season_table = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PVP_RANK_SEASON_CONF)
  local all_data = season_table:GetAllDatas()
  local valid_seasons = {}
  local begin_season_start_time = 0
  local begin_season_id = 0
  for id, season_data in pairs(all_data) do
    local timestamp = PVPRankedMatchModuleUtils.GetTimestampFromTimeStr(season_data.start_time)
    if timestamp > 0 then
      table.insert(valid_seasons, {id = id, timestamp = timestamp})
      if season_data.begin_season then
        begin_season_start_time = timestamp
        begin_season_id = id
      end
    else
      Log.Info("PVP\233\133\141\231\189\174\232\181\155\229\173\163\230\149\176\230\141\174\229\188\130\229\184\184\239\188\140\230\163\128\230\159\165id\228\184\186", id, "\231\154\132\232\181\155\229\173\163\229\188\128\229\167\139\230\151\182\233\151\180\233\133\141\231\189\174")
    end
  end
  self.first_season_start_time = begin_season_start_time
  self.first_season_id = begin_season_id
  table.sort(valid_seasons, function(a, b)
    return a.timestamp > b.timestamp
  end)
  self.valid_seasons = valid_seasons
  self:GetSortSeasonDatas()
end

function PVPRankedMatchModuleData:GetSortSeasonDatas()
  local cur_timestamp = _G.ZoneServer:GetServerTime() / 1000
  local sort_seasons = {}
  if self.first_season_start_time > 0 then
    for _, season_data in pairs(self.valid_seasons) do
      if season_data.timestamp >= self.first_season_start_time and cur_timestamp >= season_data.timestamp then
        table.insert(sort_seasons, season_data.id)
      end
    end
  end
  self.sort_seasons = sort_seasons
  local sort_season_datas = {}
  for _, id in pairs(self.sort_seasons) do
    local season_data = _G.DataConfigManager:GetPvpRankSeasonConf(id)
    if season_data then
      table.insert(sort_season_datas, {
        name = season_data.name,
        isHideRedDot = true,
        ComType = CommonBtnEnum.ComboBoxType.SeasonRecord,
        text_color = UE4.UNRCStatics.HexToSlateColor("C4C3B6"),
        id = id,
        start_time = season_data.start_time,
        end_time = season_data.end_time2
      })
    end
  end
  return sort_season_datas
end

function PVPRankedMatchModuleData:GetFirstSeasonId()
  return self.first_season_id
end

function PVPRankedMatchModuleData:GetPrevSeasonId(seasonId)
  local prev_id = self.first_season_id
  for i = 1, #self.sort_seasons do
    local id = self.sort_seasons[i]
    if id == seasonId then
      break
    end
    prev_id = id
  end
  return prev_id
end

function PVPRankedMatchModuleData:ClearRankMatchData()
  self.pvpSeasonData = nil
  self.TrialPetMap = nil
end

return PVPRankedMatchModuleData
