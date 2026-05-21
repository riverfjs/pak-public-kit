local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleData = _G.NRCData:Extend("PetUIModuleData")
PetUIModuleData.CustomEnum = {BloodPulseTips = 1, BlockerTips = 2}

function PetUIModuleData:Ctor()
  NRCData.Ctor(self)
  self.skillNewStateData = {}
  self.Playeruin = 1001
  self.IsEnableChange = false
  self.PetSortIndex = _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN
  self.NPCActionOpenPetWarehouse = nil
  self.chooseTypeListTemporary = {}
  self.chooseTypeList = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {},
    GetTimeFilter = {}
  }
  self.chooseTypeList1 = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {},
    GetTimeFilter = {}
  }
  self.chooseTypeListTeamReplace = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListHomePetFeeding = {
    GenderFilter = {},
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListHomePlantGuard = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListWeeklyChallenge = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListPetInheritance = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListPetPartnerActivity = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListCertification = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.chooseTypeListBattleRogue = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {}
  }
  self.OpenPanelPetData = nil
  self.CulCanEvo = false
  self.CulCanBreakThrough = false
  self.CulEvoId = 0
  self.OpenPanelIndex = 1
  self.OpenPanelSkill = false
  self.OpenPanelAttribute = false
  self.EggFinshOpenAttribute = false
  self.RandomPetBonusPanelState = {}
  self.OpenPanelPetBag = false
  self.OpenPanelSelectBagGid = 0
  self.IsRevertMainPanel = true
  self.OpenTips = nil
  self.LearnSkill = nil
  self.bPetWarehouseTipBtnEnable = true
  self.IsOnClickChooseType = false
  self.OpenTeamType = _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
  self.SelectPetIndex = nil
  self.SelectMenuIndex = 1
  self.SelectImpressionIndex = 0
  _G.PetLog = false
  self.EvoTargetCfgId = 0
  self.PetVisualParam = nil
  self.IsPlayPetSkill = false
  self.PetGid = nil
  self.PetBagOpenState = nil
  self.PetSkillListState = 0
  self.PetShareAlchemyData = {}
  self.EnterPetPanelType = nil
  self.MirrorPetDataList = {}
  self:ResetFriendPetTeamData()
  self.PetSkillsData = {}
  self.IsOpenPetBag = false
  self.IsQualifying = false
  self.IsShareRecordVideo = false
  self.isHideUnlockSkill = nil
  self.PetReportData = nil
  self.SpecialPetData = nil
  self.SubmitPetReward = 0
  self.teamType = nil
  self.selTeamIdx = nil
  self.AssumptionEquipSkill = {}
  self.PetFriendInfo = nil
  self.ShiningWeekendTeamData = nil
  self.ShiningWeekendTeamOpenIndex = nil
  self.AICoachRecommendTeamUIData = {}
  self.BalancedPetDataForPvpMap = {}
  self.PetGidListThatWaitingForQueryBalanceData = {}
  self.isQueryingBalancePetData = false
  self.selectBoxIndex = 0
  self.LeaderItemList = {}
  self.LeaderPetList = {}
  self.AllLeaderBeforePetConfigMap = {}
  self.SelectLeaderItem = nil
  self:SetLeaderItemInfo()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_FRIEND_GET_MIRROR_PET_DATA_RSP, self.SetMirrorPetDataList)
  self.bOpenPetBoxPanel = false
end

function PetUIModuleData:SetLeaderItemInfo()
  local LeaderItemList = {}
  local BagItemConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  if BagItemConf then
    for i, Item in pairs(BagItemConf) do
      if Item.type == Enum.BagItemType.BI_BOSS_EVO then
        table.insert(LeaderItemList, Item)
      end
    end
  end
  table.sort(LeaderItemList, function(a, b)
    return a.sort_id < b.sort_id
  end)
  self.LeaderItemList = LeaderItemList
  local LeaderPetList = {}
  local AllLeaderBeforePetConfigMap = {}
  local PetBaseConfigs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PETBASE_CONF):GetAllDatas()
  if PetBaseConfigs then
    for i, PetBaseConfig in pairs(PetBaseConfigs) do
      if PetBaseConfig.bosspetbase_rule == BattleEnum.BloodItemRule.BossPet and PetBaseConfig.bosspetbase_rule_param and #PetBaseConfig.bosspetbase_rule_param > 0 then
        if not LeaderPetList[PetBaseConfig.bosspetbase_rule_param[1]] then
          LeaderPetList[PetBaseConfig.bosspetbase_rule_param[1]] = {}
        end
        if PetBaseConfig.bosspetbase_id then
          local BossPetBaseConfig = PetBaseConfigs[PetBaseConfig.bosspetbase_id]
          if BossPetBaseConfig then
            table.insert(LeaderPetList[PetBaseConfig.bosspetbase_rule_param[1]], BossPetBaseConfig)
          end
        end
        if AllLeaderBeforePetConfigMap[PetBaseConfig.bosspetbase_id] == nil then
          AllLeaderBeforePetConfigMap[PetBaseConfig.bosspetbase_id] = {}
        end
        table.insert(AllLeaderBeforePetConfigMap[PetBaseConfig.bosspetbase_id], PetBaseConfig)
      end
    end
  end
  self.LeaderPetList = LeaderPetList
  self.AllLeaderBeforePetConfigMap = AllLeaderBeforePetConfigMap
end

function PetUIModuleData:CachePetBaseConf()
  if not self.petConfs then
    local dataTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PETBASE_CONF)
    self.petConfs = dataTable:GetAllDatas()
  end
end

function PetUIModuleData:ClearPetBaseConf()
end

function PetUIModuleData:GetPetBaseConf()
  return self.petConfs
end

function PetUIModuleData:SetEnableChange(_EnableChange)
  self.IsEnableChange = _EnableChange
end

function PetUIModuleData:GetEnableChange()
  return self.IsEnableChange
end

function PetUIModuleData:SetPetSortIndex(_index)
  self.PetSortIndex = _index
end

function PetUIModuleData:GetPetSortIndex()
  return self.PetSortIndex
end

function PetUIModuleData:GetPetUiMenuIndex()
  return self.SelectMenuIndex
end

function PetUIModuleData:SetPetUiMenuIndex(index)
  self.SelectMenuIndex = index
end

function PetUIModuleData:Init(Playeruin)
  self.Playeruin = Playeruin
  local fileName = "petskillnews" .. self.Playeruin
  if not self.skillNewStateData then
    self.skillNewStateData = {}
  end
end

function PetUIModuleData:SaveSkillData()
  local fileName = "petskillnews" .. self.Playeruin
  JsonUtils.DumpSaved(fileName, self.skillNewStateData)
end

function PetUIModuleData:SetPetsSKillNewData(pets)
  return
end

function PetUIModuleData:SetOnePet(petData)
  local pet = petData
  local skillNewDate = self:SetSkillNewDataWithGid(pet.gid)
  if not skillNewDate then
    local recorddatas = self:GetPetHandbookDataList(pet.base_conf_id)
    skillNewDate = {
      gid = pet.gid,
      oldlevel = pet.level,
      records = recorddatas,
      newSkillids = {}
    }
    table.insert(self.skillNewStateData, skillNewDate)
  else
    local hashanbook = self:SetHanBooknewSkillId(skillNewDate, petData)
    local hasnorskill = self:SetNorNewSkillId(skillNewDate, petData)
    if hashanbook or hasnorskill then
      self:SaveSkillData()
    end
  end
end

function PetUIModuleData:SetSkillNewDataWithGid(gid)
  for i = 1, #self.skillNewStateData do
    local item = self.skillNewStateData[i]
    if item.gid == gid then
      return item
    end
  end
  return nil
end

function PetUIModuleData:SetNorNewSkillId(skillNewDate, petData)
  local oldlv = skillNewDate.oldlevel
  local newSkill = false
  if petData and oldlv < petData.level then
    local skillids = {}
    for i = 1, #petData.skill.skill_data do
      local skilldata = petData.skill.skill_data[i]
      if skilldata.unlock_need_lv and oldlv < skilldata.unlock_need_lv and skilldata.unlock_need_lv <= petData.level then
        table.insert(skillids, skilldata.id)
      end
    end
    skillNewDate.oldlevel = petData.level
    for i = 1, #skillids do
      local has = self:GetSkillIsNewWithSkillNewData(skillNewDate, skillids[i])
      if not has then
        newSkill = true
        table.insert(skillNewDate.newSkillids, skillids[i])
      end
    end
  end
  return newSkill
end

function PetUIModuleData:SetHanBooknewSkillId(skillNewDate, petData)
  local evoids = PetUtils.GetEvoListIDs(petData.base_conf_id)
  local newSkill = false
  if not skillNewDate.records then
    skillNewDate.records = {}
  end
  for i = 1, #evoids do
    local baseid = evoids[i]
    local data = self:GetRecordSkillData(skillNewDate, baseid)
    if not data then
      data = {}
      data.baseid = baseid
      data.study_lv = 0
      table.insert(skillNewDate.records, data)
    end
    local hasnewskill = self:GetHanBooknewSkillIdOne(skillNewDate, data)
    if hasnewskill then
      newSkill = true
    end
  end
  return newSkill
end

function PetUIModuleData:GetRecordSkillData(skillNewDate, baseid)
  for i = 1, #skillNewDate.records do
    local item = skillNewDate.records[i]
    if baseid == item.baseid then
      return item
    end
  end
end

function PetUIModuleData:GetHanBooknewSkillIdOne(skillNewDate, data)
  local oldlv = data.study_lv
  local newSkill = false
  local record = self:GetPetHandbookData(data.baseid)
  if record and record.study_lv and oldlv and oldlv < record.study_lv then
    local skillids = self:GetAwardInfoSkill(data.baseid, oldlv, record.study_lv)
    data.study_lv = record.study_lv
    if not skillids then
      return
    end
    for i = 1, #skillids do
      local has = self:GetSkillIsNewWithSkillNewData(skillNewDate, skillids[i])
      if not has then
        newSkill = true
        table.insert(skillNewDate.newSkillids, skillids[i])
      end
    end
  end
  return newSkill
end

function PetUIModuleData:GetPetHandbookDataList(petbaseid)
  local evoids = PetUtils.GetEvoListIDs(petbaseid)
  local recorddatas = {}
  for i = 1, #evoids do
    local baseid = evoids[i]
    local record = self:GetPetHandbookData(baseid)
    local data = {}
    data.baseid = baseid
    if record then
      data.study_lv = record.study_lv
    else
      data.study_lv = 0
    end
    table.insert(recorddatas, data)
  end
  return recorddatas
end

function PetUIModuleData:GetPetHandbookData(petbaseid)
  local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if petinfo.handbook.record_collection then
    for i = 1, #petinfo.handbook.record_collection do
      local records = petinfo.handbook.record_collection[i].record
      if not records then
      else
        for j = 1, #records do
          local record = records[j]
          if record.pet_base_id == petbaseid then
            return record
          end
        end
      end
    end
  end
  return nil
end

function PetUIModuleData:GetAwardInfoSkill(base_conf_id, oldLv, newlv)
  local study_lv = newlv
  local PetHandbook = _G.DataConfigManager:GetPetHandbook(base_conf_id)
  local skills = {}
  if PetHandbook then
    local pet_handbook = PetHandbook.pet_handbook
    for i, PetAwardList in ipairs(pet_handbook) do
      local award_data = PetAwardList.award_data
      if oldLv < i and i <= study_lv and PetAwardList.award_type == _G.Enum.PetHandbookAward.AWARD_SKILL then
        table.insert(skills, award_data[1])
      end
    end
  end
  return skills
end

function PetUIModuleData:RemovePetnewSkillData(petData)
  local removeGid = {}
  for i, pet in pairs(self.skillNewStateData) do
    if pet then
      local data = self:GetHasPet(petData, pet.gid)
      if not data then
        table.insert(removeGid, pet.gid)
      end
    end
  end
  for i = 1, #removeGid do
    self:RemovePetnewSkillPet(removeGid[i])
  end
end

function PetUIModuleData:RemovePetnewSkillPet(gid)
  for i, pet in pairs(self.skillNewStateData) do
    if pet and pet.gid == gid then
      table.remove(self.skillNewStateData, i)
      return true
    end
  end
end

function PetUIModuleData:GetHasPet(petData, gid)
  for i = 1, #petData do
    if petData[i].gid == gid then
      return petData[i]
    end
  end
  return nil
end

function PetUIModuleData:RemoveSkillIsNew(gid, skillID)
  local skillnewdata = self:SetSkillNewDataWithGid(gid)
  if skillnewdata then
    for i = 1, #skillnewdata.newSkillids do
      if skillnewdata.newSkillids[i] == skillID then
        table.remove(skillnewdata.newSkillids, i)
        self:SaveSkillData()
        return true
      end
    end
  end
  return false
end

function PetUIModuleData:GetSkillIsNew(gid, skillID)
  local skillnewdata = self:SetSkillNewDataWithGid(gid)
  if skillnewdata then
    for i = 1, #skillnewdata.newSkillids do
      if skillnewdata.newSkillids[i] == skillID then
        return true
      end
    end
  end
  return false
end

function PetUIModuleData:GetSkillIsNewWithSkillNewData(skillnewdata, skillID)
  if skillnewdata then
    for i = 1, #skillnewdata.newSkillids do
      if skillnewdata.newSkillids[i] == skillID then
        return true
      end
    end
  end
  return false
end

function PetUIModuleData:GetSkillsHasNew(gid)
  local skillnewdata = self:SetSkillNewDataWithGid(gid)
  if skillnewdata and #skillnewdata.newSkillids > 0 then
    return true
  end
  return false
end

function PetUIModuleData:SetCurSelectItemDataInHatchingRightPanel(Data)
  self.CurSelectItemDataInHatchingRightPanel = Data
end

function PetUIModuleData:GetCurSelectItemDataInHatchingRightPanel()
  return self.CurSelectItemDataInHatchingRightPanel
end

function PetUIModuleData:ParseZonePetTeamFriendGetListRsp(rsp)
  if not rsp then
    Log.Error("PetUIModuleData:ParseZonePetTeamFriendGetListRsp rsp is nil")
    return
  end
  local hasResult = rsp.pet_team_info and #rsp.pet_team_info > 0
  if 0 == rsp.req_page then
    if rsp.filter and rsp.filter ~= "" and not hasResult then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_search_empty_team)
      Log.Debug("PetUIModuleData:ParseZonePetTeamFriendGetListRsp filter %s has no result", rsp.filter)
      return
    else
      self:ResetFriendPetTeamData()
    end
  end
  self.FriendPetTeamResultInfo.TotalPageCount = rsp.total_page
  self.FriendPetTeamResultInfo.ReqPageIndex = rsp.req_page
  self.FriendPetTeamResultInfo.TeamType = rsp.team_type
  self.FriendPetTeamResultInfo.Filter = rsp.filter or ""
  if not self.FriendPetTeamResultInfo.FriendPetTeamInfoDic then
    self.FriendPetTeamResultInfo.FriendPetTeamInfoDic = {}
  end
  if not self.FriendPetTeamResultInfo.FriendPetTeamInfoList then
    self.FriendPetTeamResultInfo.FriendPetTeamInfoList = {}
  end
  if not self.FriendPetTeamResultInfo.FriendPetDataTwoDic then
    self.FriendPetTeamResultInfo.FriendPetDataTwoDic = {}
  end
  if rsp.pet_team_info then
    for _, petTeamInfo in pairs(rsp.pet_team_info) do
      local petTeamList = petTeamInfo.teams or {}
      for _, petTeam in ipairs(petTeamList) do
        _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdDistributeGidForRandomPetInPetTeam, petTeam)
      end
    end
    for _, petTeamInfo in pairs(rsp.pet_team_info) do
      if self.FriendPetTeamResultInfo.FriendPetTeamInfoDic[petTeamInfo.friend_uin] then
        Log.ErrorFormat("PetUIModuleData:ParseZonePetTeamFriendGetListRsp info.friend_uin %d already exists", petTeamInfo.friend_uin)
      else
        self.FriendPetTeamResultInfo.FriendPetTeamInfoDic[petTeamInfo.friend_uin] = petTeamInfo
        table.insert(self.FriendPetTeamResultInfo.FriendPetTeamInfoList, petTeamInfo)
        local friendPetDataDic = {}
        self.FriendPetTeamResultInfo.FriendPetDataTwoDic[petTeamInfo.friend_uin] = friendPetDataDic
        if not petTeamInfo.pets or 0 == #petTeamInfo.pets then
          Log.ErrorFormat("PetUIModuleData:ParseZonePetTeamFriendGetListRsp petTeamInfo.friend_uin %d has no pets", petTeamInfo.friend_uin)
        else
          for _, petData in pairs(petTeamInfo.pets) do
            if not friendPetDataDic[petData.gid] then
              friendPetDataDic[petData.gid] = petData
            else
              Log.ErrorFormat("PetUIModuleData:ParseZonePetTeamFriendGetListRsp petData.gid %d already exists for friend_uin %d", petData.gid, petTeamInfo.friend_uin)
            end
          end
        end
      end
    end
  end
end

function PetUIModuleData:IsFriendPetTeamSearching()
  return self.FriendPetTeamResultInfo and self.FriendPetTeamResultInfo.Filter and self.FriendPetTeamResultInfo.Filter ~= ""
end

function PetUIModuleData:ResetFriendPetTeamData()
  self.FriendPetTeamResultInfo = {}
  self.FriendPetTeamResultInfo.TotalPageCount = 0
  self.FriendPetTeamResultInfo.ReqPageIndex = 0
  self.FriendPetTeamResultInfo.TeamType = _G.ProtoEnum.PlayerTeamType.PTT_INVALID
  self.FriendPetTeamResultInfo.Filter = ""
  self.FriendPetTeamResultInfo.FriendPetTeamInfoDic = {}
  self.FriendPetTeamResultInfo.FriendPetTeamInfoList = {}
  self.FriendPetTeamResultInfo.FriendPetDataTwoDic = {}
  self.ExpectedFriendTeamReqIndex = 0
end

function PetUIModuleData:SetMirrorPetDataList(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.MirrorPetDataList = {}
    local mirror_pet_data = rsp.mirror_pet_data
    if mirror_pet_data and #mirror_pet_data > 0 then
      for i, v in ipairs(mirror_pet_data) do
        self.MirrorPetDataList[v.gid] = v
      end
    end
  end
end

function PetUIModuleData:GetMirrorPetDataByGid(petGid)
  return self.MirrorPetDataList[petGid]
end

function PetUIModuleData:GetPetDataByFriendUinAndPetGid(friendUin, petGid)
  if not friendUin or not petGid then
    Log.Error("PetUIModuleData:GetPetDataByFriendUin friendUin is nil or petGid is nil")
    return nil
  end
  if not self.FriendPetTeamResultInfo.FriendPetDataTwoDic[friendUin] then
    Log.ErrorFormat("PetUIModuleData:GetPetDataByFriendUin friendUin %d not found", friendUin)
    return nil
  end
  local dic = self.FriendPetTeamResultInfo.FriendPetDataTwoDic[friendUin]
  if dic[petGid] then
    return dic[petGid]
  end
  local hasPet, trialPetData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, petGid)
  local isRandomPet, randomPetData
  isRandomPet, randomPetData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
  if hasPet and trialPetData then
    return trialPetData
  elseif isRandomPet and randomPetData then
    local typeInfo = randomPetData and randomPetData.type
    local skillDamType = typeInfo and typeInfo.param
    local petBaseConfId = PetUtils.GetRandomPetBaseConfIdFromSkillDamType(skillDamType)
    local nextRandomPetData = {}
    table.copy(randomPetData, nextRandomPetData)
    nextRandomPetData.base_conf_id = petBaseConfId
    return nextRandomPetData
  else
    Log.ErrorFormat("PetUIModuleData:GetPetDataByFriendUinAndPetGid isTrialPet true but not found for petGid %d, friendUin %d", petGid, friendUin)
    return nil
  end
end

function PetUIModuleData:GetSortedFriendPetTeamList()
  local petTeamList = {}
  for _, info in pairs(self.FriendPetTeamResultInfo.FriendPetTeamInfoList) do
    if info and info.teams then
      for _, petTeamItem in pairs(info.teams) do
        if table.isNotEmpty(petTeamItem) and self:IsPetTeamValid(info.friend_uin, petTeamItem) then
          local petTeamData = {}
          petTeamData.friendUin = info.friend_uin
          petTeamData.friendName = info.friend_name
          petTeamData.friendLevel = info.friend_level
          petTeamData.cardIconSelected = info.friend_card_icon_selected
          petTeamData.petTeam = petTeamItem
          petTeamData.friend_is_mirror_unlocked = info.friend_is_mirror_unlocked
          petTeamData.TeamType = self.FriendPetTeamResultInfo.TeamType
          table.insert(petTeamList, petTeamData)
        end
      end
    end
  end
  return petTeamList
end

function PetUIModuleData:IsPetTeamValid(friendUin, petTeam)
  if not (petTeam and petTeam.pet_infos) or 0 == #petTeam.pet_infos then
    return false
  end
  for _, pet in pairs(petTeam.pet_infos) do
    local petInfo = pet
    local petData = self:GetPetDataByFriendUinAndPetGid(friendUin, petInfo.pet_gid)
    if not petData then
      Log.WarningFormat("PetUIModuleData:IsPetTeamValid petData not found for friendUin %d, petGid %s", friendUin, tostring(petInfo.pet_gid))
      return false
    end
    if not _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id) then
      Log.Warning("PetUIModuleData:IsPetTeamValid pet base_conf_id %s not found", tostring(pet.base_conf_id))
      return false
    end
  end
  return true
end

function PetUIModuleData:GetFriendPetTeamResultInfo()
  return self.FriendPetTeamResultInfo
end

function PetUIModuleData:SetExpectedFriendTeamReqIndex(index)
  self.ExpectedFriendTeamReqIndex = index
end

function PetUIModuleData:GetExpectedFriendTeamReqIndex()
  return self.ExpectedFriendTeamReqIndex
end

function PetUIModuleData:GetThresholdCountForPageReq()
  return 4
end

function PetUIModuleData:GetSelectImpressionIndex()
  return self.SelectImpressionIndex
end

function PetUIModuleData:SetSelectImpressionIndex(index)
  self.SelectImpressionIndex = index
end

function PetUIModuleData:SetPetVisualParam(_PetVisualParam)
  self.PetVisualParam = _PetVisualParam
end

function PetUIModuleData:GetPetVisualParam()
  return self.PetVisualParam
end

function PetUIModuleData:SetPetReportParamInfo(_PetReportParamInfo)
  self.PetReportParamInfo = _PetReportParamInfo
end

function PetUIModuleData:GetPetReportParamInfo()
  return self.PetReportParamInfo
end

function PetUIModuleData:SetIsPlayPetSkill(_IsPlayPetSkill)
  self.IsPlayPetSkill = _IsPlayPetSkill
end

function PetUIModuleData:GetIsPlayPetSkill()
  return self.IsPlayPetSkill
end

function PetUIModuleData:SetEnterPetPanelType(_EnterPetPanelType)
  self.EnterPetPanelType = _EnterPetPanelType
end

function PetUIModuleData:GetEnterPetPanelType()
  return self.EnterPetPanelType
end

function PetUIModuleData:SetPetSkillsData(PetGid, Skills)
  if not PetGid then
    return
  end
  self.PetSkillsData[PetGid] = Skills
end

function PetUIModuleData:GetPetSkillsData(PetGid)
  return self.PetSkillsData[PetGid]
end

function PetUIModuleData:GetPetEquipInfos(PetGid)
  local skillList = self:GetPetSkillsData(PetGid)
  local equip_infos
  if skillList then
    equip_infos = {}
    for index, skillId in pairs(skillList) do
      table.insert(equip_infos, {id = skillId, pos = index})
    end
  end
  return equip_infos
end

function PetUIModuleData:ClearPetSkillsData()
  self.PetSkillsData = {}
end

function PetUIModuleData:ClearBalancedPetDataForPvp()
  self.BalancedPetDataForPvpMap = {}
end

function PetUIModuleData:SetFriendInfoToPetMain(FriendInfo)
  self.PetFriendInfo = FriendInfo
end

function PetUIModuleData:GetFriendInfoToPetMain()
  return self.PetFriendInfo
end

function PetUIModuleData:RefreshEditorPetTeamCache(teamType, selTeamIdx)
  self.teamType = teamType
  self.selTeamIdx = selTeamIdx
end

function PetUIModuleData:SetRecommendPetTeamList(recommend_pet_team)
  self.ShiningWeekendTeamData = recommend_pet_team
end

function PetUIModuleData:GetRecommendPetTeamList()
  return self.ShiningWeekendTeamData
end

function PetUIModuleData:SetShiningWeekendTeamOpenIndex(index)
  self.ShiningWeekendTeamOpenIndex = index
end

function PetUIModuleData:GetShiningWeekendTeamName()
  return self.AICoachRecommendTeamUIData.teamData and self.AICoachRecommendTeamUIData.teamData.team_name or self.ShiningWeekendTeamData[self.ShiningWeekendTeamOpenIndex].team_name
end

function PetUIModuleData:SetAICoachRecommendTeamUIData(data)
  self.AICoachRecommendTeamUIData = data
end

function PetUIModuleData:GetAICoachRecommendTeamUIData()
  return self.AICoachRecommendTeamUIData
end

function PetUIModuleData:GetAICoachRecommendTeam()
  local aiTeamData
  local aiPlayerName = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_player_name", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
  local aiTeamName = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_team_name", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
  for i, v in pairs(self.ShiningWeekendTeamData) do
    if v.player_name == aiPlayerName and v.team_name == aiTeamName then
      aiTeamData = v
      break
    end
  end
  return aiTeamData
end

function PetUIModuleData:GetLeaderItemList()
  return self.LeaderItemList
end

function PetUIModuleData:GetLeaderPetList()
  return self.LeaderPetList
end

function PetUIModuleData:GetAllLeaderBeforePetConfigMap()
  return self.AllLeaderBeforePetConfigMap
end

function PetUIModuleData:SetSelectLeaderItem(_SelectLeaderItem)
  self.SelectLeaderItem = _SelectLeaderItem
end

function PetUIModuleData:GetSelectLeaderItem()
  return self.SelectLeaderItem
end

function PetUIModuleData:GetAssumptionEquipSkill(petGid)
  return self.AssumptionEquipSkill[petGid]
end

function PetUIModuleData:SetAssumptionEquipSkill(petGid, AssumptionEquipSkill)
  if not petGid then
    self.AssumptionEquipSkill = {}
    return false
  end
  if not self.AssumptionEquipSkill[petGid] then
    self.AssumptionEquipSkill = {}
    self.AssumptionEquipSkill[petGid] = AssumptionEquipSkill and table.deepCopy(AssumptionEquipSkill) or nil
    return true
  end
  
  local function isTableEqual(t1, t2)
    if t1 == t2 then
      return true
    end
    if not t1 or not t2 then
      return false
    end
    for k, v in pairs(t1) do
      if t2[k] ~= v then
        return false
      end
    end
    for k, v in pairs(t2) do
      if t1[k] ~= v then
        return false
      end
    end
    return true
  end
  
  local isEqual = isTableEqual(self.AssumptionEquipSkill[petGid], AssumptionEquipSkill)
  if not isEqual then
    if AssumptionEquipSkill then
      self.AssumptionEquipSkill[petGid] = table.deepCopy(AssumptionEquipSkill)
    else
      self.AssumptionEquipSkill[petGid] = nil
    end
  end
  return not isEqual
end

return PetUIModuleData
