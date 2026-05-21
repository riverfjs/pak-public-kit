local DataModelBase = require("Data.Global.DataModelBase")
local PlayerDataModel = DataModelBase:Extend("PlayerDataModel")
local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local PetUtils = require("NewRoco.Utils.PetUtils")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local JsonUtils = require("Common.JsonUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")

function PlayerDataModel:Ctor()
  DataModelBase.Ctor(self)
  self.playerInfo = nil
  self.loginData = nil
  self.DataModelMgr = _G.DataModelMgr
  self.SelfStoryFlagsMap = nil
  self.SelfStoryFlagsMapCount = 0
  self.HomeOwnerStoryFlagsMap = nil
  self.HomeOwnerStoryFlagsMapCount = 0
  self.LastSelfStoryFlagsConsistencyErrorMsTime = -1
  self.LastHomeOwnerStoryFlagsMapConsistencyErrorMsTime = -1
  self.CachePool = {}
  self:RegisterNotify()
  self.envMask = 0
  self.ban_type = {}
  self.ban_ride_sockets = {}
  self.ban_ride_sockets_mask = 0
  self.AvatarDefaultSuitObj = nil
  self.PetInfoPage = 1
  self.WaitGetPetInfoRspSuccess = false
  self.player_had_items = {}
  self.PanelMusicList = {}
  self.briefFriendInfoDic = {}
  self.visitList = {}
  self.FeedInfo = nil
  local RoleExpConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ROLE_EXP_CONF):GetAllDatas()
  self.MaxLevel = RoleExpConf[#RoleExpConf].id
  self.privilegeInfo = {}
  self.petGidMap = {}
  self.petBaseIdMap = {}
  self.hasBoxVacancyCache = nil
  self.TotalFashionCount = self:GetTotalExcelCount(_G.DataConfigManager.ConfigTableId.FASHION_ITEM_CONF)
  self.TotalCollectCount = self:GetTotalExcelCount(_G.DataConfigManager.ConfigTableId.PET_HANDBOOK)
  self.starlightInfo = nil
end

function PlayerDataModel:RegisterNotify()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SYNC_NOTIFY, self.OnNet_PlayerSyncNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAYER_VISIT_INFO_SYNC_NOTIFY, self.OnVisitPlayerInfoSyncNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_CHANGE_NOTIFY, self.SetOnlineVisitorChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PET_HP_CHANGE_NOTIFY, self.OnNet_PlayerPetHpChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_GUIDE_BOOK_NOTIFY, self.OnGuidBookChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_STORY_FLAG_CHANGE_NOTIFY, self.OnStoryFlagChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_MULTI_STORY_FLAG_CHANGE_NOTIFY, self.OnMultiStoryFlagChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY, self.OnBattleHandbookChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY, self.OnBattleInstantPerformNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_DIAMOND_BUY_STAR_TIMES_NOTIFY, self.BuyDiamondCountChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_VISIT_REMAIN_CATCH_TIMES_NOTIFY, self.OnVisitRemainCatchTimesNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PVP_HISTORY_DATA_NOTIFY, self.OnPVPHistoryDataNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_HOME_INFO_CHANGE_NOTIFY, self.OnZoneHomeInfoChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_FEED_INFO_NOTIFY, self.SetFeedInfo)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_DAILY_LIMIT_NOTIFY, self.OnZoneDailyLimitNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_START_UP_PRIVILEGE_INFO_NOTIFY, self.OnUpdatePrivilegeInfoNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_CHAT_EMOJI_ITEM_CHANGE_NOTIFY, self.OnZoneChatEmojiItemChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_WATER_MARK_CHANGE_NOTIFY, self.OnZoneClientWaterMarkChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SYS_FUNC_BANNED_NOTIFY, self.OnZoneSceneSysFuncBannedNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_STAR_LIGHT_INFO_NOTIFY, self.OnStarlightChangeNotify)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_VITEM, self.OnVItemChangedHandler)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPetDatChangedHandler)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET_DATACHANGE, self.OnPetExpChanged)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_BACKPACK, self.OnBackpackChangeHandler)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, TipsModuleEvent.Tips_LobbyRegionPreUpdate, self.ResolveCache)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_RP_BEHAVIOR, self.SetRolePlayList)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, NPCModuleEvent.OnOwlStarInfoCreate, self.OnOwlStarInfoCreate)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, NPCModuleEvent.OnOwlStarInfoDestroy, self.OnOwlStarInfoDestroy)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, NPCModuleEvent.OnOwlStarInfoUpdateDistanceState, self.OnOwlStarInfoUpdateDistanceState)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, BagModuleEvent.GoodChangeTypeEnum.GT_MEDAL, self.OnMedalDataChange)
  _G.NRCEventCenter:RegisterEvent("PlayerDataModel", self, FriendModuleEvent.OnVisitorLeaved, self.OnVisitorLeaved)
end

function PlayerDataModel:OnStarlightChangeNotify(rsp)
  self.starlightInfo = rsp
end

function PlayerDataModel:RemoveStarlightListener()
  self.starlightInfo = nil
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_STAR_LIGHT_INFO_NOTIFY, self.OnStarlightChangeNotify)
end

function PlayerDataModel:GetVItemCount(VItemID)
  if self.loginData and self.loginData.player_info and self.loginData.player_info.brief_info and self.loginData.player_info.brief_info.vitem_info and self.loginData.player_info.brief_info.vitem_info.vitem_list then
    return self.loginData.player_info.brief_info.vitem_info.vitem_list[VItemID + 1]
  end
end

function PlayerDataModel:GetBuyDiamondCount()
  return self.loginData.player_info.misc_info.diamond_buy_star_times
end

function PlayerDataModel:SetFeedInfo(rsp)
  self.FeedInfo = rsp
end

function PlayerDataModel:GetFeedInfo()
  if self.FeedInfo then
    local FeedInfo = self.FeedInfo
    self.FeedInfo = nil
    return FeedInfo
  end
  return nil
end

function PlayerDataModel:SetBuyDiamondCount(num)
  if self.loginData then
    self.loginData.player_info.misc_info.diamond_buy_star_times = num
  end
end

function PlayerDataModel:GetEquipMagicItemGid()
  if self.loginData then
    return self.loginData.player_info.misc_info.cur_selected_magic_item_gid
  end
  return -1
end

function PlayerDataModel:OnVisitorLeaved(uin)
  local PlayerUin = self:GetPlayerUin()
  if uin == PlayerUin then
    for i, PlayerFruit in pairs(self.cachedOwlSanctuaryInfo) do
      if PlayerFruit.uin ~= uin then
        self.cachedOwlSanctuaryInfo[i] = nil
      end
    end
  else
    for i, PlayerFruit in pairs(self.cachedOwlSanctuaryInfo) do
      if PlayerFruit.uin == uin then
        self.cachedOwlSanctuaryInfo[i] = nil
      end
    end
  end
end

function PlayerDataModel:SetNavigationMode(Mode)
  self.playerInfo.common_info.navigation_mode_type = Mode
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.NAVIGATION_MODE_UPDATE, self.playerInfo.common_info.navigation_mode_type)
  local req = _G.ProtoMessage:newZoneSetNavigationModeTypeReq()
  req.mode_type = Mode
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_NAVIGATION_MODE_TYPE_REQ, req, self, self.GetNavigationModeTypeRsp)
end

function PlayerDataModel:GetNavigationModeTypeRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("GetNavigationModeTypeRsp_Code" .. rsp.ret_info.ret_code)
  end
end

function PlayerDataModel:GetNavigationMode()
  Log.Debug(self.playerInfo.common_info.navigation_mode_type, "PlayerDataModel:GetNavigationMode")
  if self:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAIN_MAP_SELECT_UI) or self.playerInfo.common_info.navigation_mode_type and self.playerInfo.common_info.navigation_mode_type ~= ProtoEnum.NavigationModeType.NMT_MINIMAP then
    return self.playerInfo.common_info.navigation_mode_type or ProtoEnum.NavigationModeType.NMT_MINIMAP
  else
    return ProtoEnum.NavigationModeType.NMT_MINIMAP
  end
end

function PlayerDataModel:GetPlayerInfo()
  return self.playerInfo
end

function PlayerDataModel:GetPlayerPetInfo()
  if self.playerInfo == nil then
    Log.ErrorFormat("PlayerDataModel:GetPlayerPetInfo playerInfo is nil ")
    return {}
  end
  local petInfo = self.playerInfo.pet_info
  if not petInfo or type(petInfo) ~= "table" then
    Log.ErrorFormat("PlayerDataModel:GetPlayerPetInfo petInfo is nil or not a table")
    return {}
  end
  return petInfo
end

function PlayerDataModel:HasPet()
  local DataList = self:GetPetData()
  if not DataList then
    return false
  end
  return #DataList > 0
end

function PlayerDataModel:GetEmojiBagInfo()
  return self.playerInfo.emoji_bag_info and self.playerInfo.emoji_bag_info.emoji_list
end

function PlayerDataModel:GetPlayerPetTeamInfo()
  local petTeamInfo = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  return petTeamInfo
end

function PlayerDataModel:GetPlayerMainPetTeam()
  local teamInfo = self:GetPlayerPetTeamInfo()
  if teamInfo then
    local mainTeamIndex = (teamInfo.main_team_idx or 0) + 1
    return teamInfo.teams[mainTeamIndex]
  end
  return nil
end

function PlayerDataModel:GetPlayerPetTeamInfoByTeamType(TeamType)
  local petTeamInfo = PetUtils.PlayerPetInfoGetTeamInfo(self.playerInfo.pet_info, TeamType)
  if not petTeamInfo then
    petTeamInfo = {}
    petTeamInfo.main_team_idx = 0
    petTeamInfo.teams = {}
    for index = 1, 8 do
      petTeamInfo.teams[index] = {}
    end
    petTeamInfo.team_type = TeamType
  end
  return petTeamInfo
end

function PlayerDataModel:UpdatePlayerPetTeamInfoByTeamType(teamType, teamInfo)
  if self.playerInfo and self.playerInfo.pet_info and self.playerInfo.pet_info.team_infos then
    for i, team_info in pairs(self.playerInfo.pet_info.team_infos) do
      if team_info.team_type == teamType then
        team_info = teamInfo
      end
    end
  end
end

function PlayerDataModel:GetPlayerWorldLevel()
  return self:GetVItemCount(_G.ProtoEnum.VisualItem.VI_WORLD_LEVEL) or 0
end

function PlayerDataModel:GetPlayerPvPPetTeamInfo()
  local petTeamInfo = PetUtils.PlayerPetInfoGetTeamInfo(self.playerInfo.pet_info, Enum.PlayerTeamType.PTT_PVP_BATTLE_1)
  return petTeamInfo
end

function PlayerDataModel:GetPlayerGuide_BooksInfo()
  return self.playerInfo.world_map_info.guide_books
end

function PlayerDataModel:GetPlayerMarkInfo()
  return self.playerInfo.world_map_info.mark_info_list
end

function PlayerDataModel:SetPlayerMarkInfo(_mark_info_list)
  self.playerInfo.world_map_info.mark_info_list = _mark_info_list
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.MAP_MARK_CHANGE)
end

function PlayerDataModel:SetPlayerBigWorldPetTeamMainIndex(team_Index)
  if team_Index < 0 then
    return
  end
  for index = 1, #self.playerInfo.pet_info.team_infos do
    if self.playerInfo.pet_info.team_infos[index].team_type == _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD then
      self.playerInfo.pet_info.team_infos[index].main_team_idx = team_Index
      return
    end
  end
end

function PlayerDataModel:GetPetDataAndTeamIndexByGid(_gid)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local teamIndex, gid
  local retPets = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      gid = PetUtils.PetTeamGetPetGidList(team)
      if gid then
        for index, v in ipairs(gid) do
          if v == _gid then
            teamIndex = i
            local petData = self:GetPetDataByGid(_gid)
            return index, petData
          end
        end
      end
    end
  end
  return nil
end

function PlayerDataModel:SetPlayerPvPPetTeamInfo(teamInfo)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdDistributeGidForRandomPetInPetTeamInfo, teamInfo)
  for index = 1, #self.playerInfo.pet_info.team_infos do
    if self.playerInfo.pet_info.team_infos[index].team_type == teamInfo.team_type then
      self.playerInfo.pet_info.team_infos[index] = teamInfo
      return
    end
  end
end

function PlayerDataModel:GetBattleTeamIndex()
  local teamInfo = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  return teamInfo.main_team_idx
end

function PlayerDataModel:GetPlayerUin()
  if self and self.playerInfo and self.playerInfo.brief_info then
    return self.playerInfo.brief_info.uin
  end
  return nil
end

function PlayerDataModel:GetPlayerMobileBindInfo()
  return self.playerInfo.brief_info.additional_data.mobile_bind_info
end

function PlayerDataModel:SetPlayerMobileBindInfo(info)
  self.playerInfo.brief_info.additional_data.mobile_bind_info = info
end

function PlayerDataModel:GetBattlePetGid()
  if not self.playerInfo then
    Log.Error("PlayerDataModel:GetBattlePetGid playerInfo Is None!!!!")
    return {}
  end
  local petInfo = self.playerInfo.pet_info
  if not petInfo then
    Log.Error("PlayerDataModel:GetBattlePetGid playerInfo.pet_info Is None!!!!")
    return {}
  end
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local gid
  if PetTeams and PetTeams.teams then
    for i, team in ipairs(PetTeams.teams) do
      if PetTeams.main_team_idx + 1 == i then
        gid = PetUtils.PetTeamGetPetGidList(team)
      end
    end
    if nil == gid then
      Log.Error("playerInfo.pet_info.team_info \230\137\190\228\184\141\229\136\176\228\184\138\229\156\186\229\174\160\231\137\169\231\188\150\233\152\159\239\188\140\232\175\183\230\163\128\230\159\165\229\144\142\229\143\176\229\143\145\228\184\139\230\157\165\231\154\132\230\149\176\230\141\174")
      return {}
    end
    return gid
  else
    Log.Error("playerInfo.pet_info.team_info\228\184\141\229\143\175\228\184\186\231\169\186\239\188\140\232\175\183\230\163\128\230\159\165\229\144\142\229\143\176\228\184\139\229\143\145\228\184\139\230\157\165\231\154\132\230\149\176\230\141\174")
    return {}
  end
end

function PlayerDataModel:IsBackpackFull()
  return false
end

function PlayerDataModel:IsInBackpack(pet_gid, BackpackInfo, SkipCheckTemporarilyStore)
  if BackpackInfo then
    if BackpackInfo.pet_gid == nil then
      return false
    end
    for index, item in ipairs(BackpackInfo.pet_gid) do
      if item == pet_gid then
        return true
      end
    end
    return false
  end
  if self.playerInfo.pet_info and self.playerInfo.pet_info.backpack_info and self.playerInfo.pet_info.backpack_info.boxes then
    for _, box in pairs(self.playerInfo.pet_info.backpack_info.boxes or {}) do
      if box then
        for _, gid in ipairs(box.pet_gid or {}) do
          if gid == pet_gid then
            if SkipCheckTemporarilyStore then
              if index > (self.playerInfo.pet_info.backpack_info.pet_bag_space_quantity or 0) then
                return true
              end
            else
              return true
            end
          end
        end
      end
    end
    return false
  end
end

function PlayerDataModel:GetPlayerBattlePetGid()
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local gid
  if PetTeams then
    for i, v in ipairs(PetTeams.teams) do
      if PetTeams.main_team_idx + 1 == i then
        gid = v
      end
    end
  end
  return gid
end

function PlayerDataModel:GetPlayerBattlePetInfo(Team_Index)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local gid
  local retPets = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      local mainIndex = Team_Index or PetTeams.main_team_idx or 0
      if mainIndex + 1 == i then
        gid = PetUtils.PetTeamGetPetGidList(team)
      end
    end
    if gid then
      for i, v in ipairs(gid) do
        local petData = self:GetPetDataByGid(v)
        table.insert(retPets, petData)
      end
    end
  end
  return retPets
end

function PlayerDataModel:GetPlayerBattlePetInfoByTeamType(TeamType)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(TeamType)
  local gid
  local retPets = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      local mainIndex = PetTeams.main_team_idx or 0
      if mainIndex + 1 == i then
        gid = PetUtils.PetTeamGetPetGidList(team)
      end
    end
    if gid then
      for i, v in ipairs(gid) do
        local petData = self:GetPetDataByGid(v)
        table.insert(retPets, petData)
      end
    end
  end
  return retPets
end

function PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(_gid)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local teamIndex = -1
  local gid
  local retPets = {}
  local petInTeamIndex
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      gid = PetUtils.PetTeamGetPetGidList(team)
      if gid then
        for j, v in ipairs(gid) do
          if v == _gid then
            teamIndex = i
            petInTeamIndex = j
            break
          end
        end
      end
      if teamIndex >= 0 then
        break
      end
    end
  end
  return teamIndex == PetTeams.main_team_idx + 1, teamIndex - 1, petInTeamIndex
end

function PlayerDataModel:GetPlayerBattleTeamIndexByGid(_gid)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local teamIndex, gid
  local retPets = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      gid = PetUtils.PetTeamGetPetGidList(team)
      if gid then
        for _, v in ipairs(gid) do
          if v == _gid then
            teamIndex = i
            return teamIndex
          end
        end
      end
    end
  end
  return teamIndex
end

function PlayerDataModel:GetPlayerBackpackPetInfo()
  local backpackPets = {}
  if not (self.playerInfo.pet_info and self.playerInfo.pet_info.backpack_info) or not self.playerInfo.pet_info.backpack_info.boxes then
    return backpackPets
  end
  for _, box in pairs(self.playerInfo.pet_info.backpack_info.boxes or {}) do
    if box then
      for _, gid in pairs(box.pet_gid or {}) do
        if 0 ~= gid then
          local petData = self:GetPetDataByGid(gid)
          if petData and not BattleUtils.GetBit(petData.pet_status_flags, 1) then
            table.insert(backpackPets, petData)
          end
        end
      end
    end
  end
  return backpackPets
end

function PlayerDataModel:GetPlayerTemporarilyStoreBackpackPetInfo()
  self:GetPlayerBackpackPetInfo()
end

function PlayerDataModel:GetPlayerBackpackEggInfo()
  local backpackEggs = {}
  if not (self.playerInfo.pet_info and self.playerInfo.pet_info.backpack_info) or not self.playerInfo.pet_info.backpack_info.egg_gid then
    return backpackEggs
  end
  for i, gid in ipairs(self.playerInfo.pet_info.backpack_info.egg_gid) do
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, gid)
    if bagItem and bagItem.type == _G.ProtoEnum.BagItemType.BI_PET_EGG then
      local eggData = bagItem.egg_data
      table.insert(backpackEggs, {
        gid = gid,
        findTime = bagItem.update_time or 0,
        eggData = eggData,
        bagItem = bagItem
      })
    end
  end
  return backpackEggs
end

function PlayerDataModel:GetPetSubmitNum()
  local submitNum = 0
  local pet_info = self.playerInfo and self.playerInfo.pet_info
  local pet_data_array = pet_info and pet_info.pet_data
  if pet_data_array then
    for _, pet_data in ipairs(pet_data_array) do
      if pet_data.can_submit then
        submitNum = submitNum + 1
      end
    end
  end
  return submitNum
end

function PlayerDataModel:GetPlayerHousePetInfo()
  local posArray = self.playerInfo.pet_info.bag_pos_gid or {1, 2}
  local pets = self.playerInfo.pet_info.pet_data
  local retPets = {}
  for _, v in ipairs(pets) do
    local isExchange = v.pet_status_flags and v.pet_status_flags & ProtoEnum.PetStatusFlag.MIRACLE_CHANGING > 0
    if not table.contains(posArray, v.gid) and not isExchange then
      table.insert(retPets, v)
    end
  end
  return retPets
end

function PlayerDataModel:GetPlayerBattlePetNum()
  local BattlePetNum = 0
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local gid
  local retPets = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      gid = PetUtils.PetTeamGetPetGidList(team)
      if gid then
        BattlePetNum = BattlePetNum + #gid
      end
    end
  end
  return BattlePetNum
end

function PlayerDataModel:GetPlayerHousePetNum()
  local housePets = self:GetPlayerHousePetInfo()
  return #housePets
end

function PlayerDataModel:GetThrowItemInfo()
  return self.playerInfo.misc_info
end

function PlayerDataModel:RefreshThrowItemInfo(_type, _gid)
  if self.playerInfo.misc_info.cur_selected_throw_item == nil then
    self.playerInfo.misc_info.cur_selected_throw_item = {}
  end
  self.playerInfo.misc_info.cur_selected_throw_item.cur_selected_gid = _gid
  self.playerInfo.misc_info.cur_selected_throw_item.cur_selected_throw_type = _type + 1
  if _type == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    self.playerInfo.misc_info.cur_selected_magic_item_gid = _gid
  end
end

function PlayerDataModel:GetPlayerName()
  if self.playerInfo and self.playerInfo.brief_info then
    return self.playerInfo.brief_info.name
  end
end

function PlayerDataModel:GetPlayerHeadIcon()
  return self.playerInfo.brief_info.additional_data.card_brief_info.card_icon_selected
end

function PlayerDataModel:IsMale()
  return self.playerInfo and self.playerInfo.brief_info.sex == _G.ProtoEnum.ESexValue.SEX_MALE
end

function PlayerDataModel:GetPlayerLevel()
  return self:GetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLE_LEVEL) or 0
end

function PlayerDataModel:GetGameTime()
  return self.playerInfo.common_info.in_game_time or 0, self.loginClock or os.clock()
end

function PlayerDataModel:GetIsStartServerAI()
  return self.playerInfo.common_info and self.playerInfo.common_info.start_server_ai and self.playerInfo.common_info.start_server_ai or false
end

function PlayerDataModel:GetPlayerExpInfo()
  local curExp = self:GetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLEEXP)
  local level = self:GetPlayerLevel()
  local maxExp = -1
  local expCfg = _G.DataConfigManager:GetRoleExpConf(level)
  if expCfg and expCfg.need_exp and expCfg.need_exp > 0 then
    maxExp = expCfg.need_exp
  end
  return curExp, maxExp
end

function PlayerDataModel:GetPetCatchInfo(baseId)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  if petInfo.catch_info then
    for i, k in ipairs(petInfo.catch_info) do
      if k.pet_base_id == baseId then
        return k
      end
    end
  end
  return nil
end

function PlayerDataModel:UpdatePetCatchInfo(PetBaseID, Success)
  if 0 == PetBaseID then
    Log.Error("PlayerDataModel:UpdatePetCatchInfo PetBaseID\228\184\1860")
    return
  end
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    Log.Error("\231\142\169\229\174\182\232\186\171\228\184\138\230\178\161\230\156\137PetCatchInfo")
    return
  end
  local Info = self:GetPetCatchInfo(PetBaseID)
  if not Info then
    Info = ProtoMessage:newPetCatchInfo()
    if not petInfo.catch_info then
      petInfo.catch_info = {}
    end
    table.insert(petInfo.catch_info, Info)
  end
  Info.pet_base_id = PetBaseID
  if Success then
    Info.success_count = (Info.success_count or 0) + 1
  else
    Info.fail_count = (Info.fail_count or 0) + 1
  end
end

function PlayerDataModel:UpdatePetInHomeIndoor(petGid, isInHome)
  if not petGid then
    Log.Error("invalid petGid UpdatePetInHomeInfo")
    return
  end
  local playerPetData = self:GetPetDataByGid(petGid)
  if playerPetData then
    playerPetData.business_identity = isInHome and _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET or _G.ProtoEnum.PetBusinessIdentity.PBI_NONE
  end
end

function PlayerDataModel:GetChallengeData(ActivityType)
  self.playerInfo.svr_data_info.activity_info = {}
  self.playerInfo.svr_data_info.activity_info.activity_data = {
    {
      activity_type = ProtoEnum.ActivityType.ATP_NPC_CHALLENGE_EVENT,
      npc_challenge_data = {
        event_id = 1300001,
        activity_id = 1300001,
        perfect_level_id = 1001,
        modules = {
          {
            levels = {
              {
                is_finish = true,
                challenge_id = 1001,
                take_times = 1,
                targets = {
                  {is_finish = true},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              },
              {
                is_finish = true,
                challenge_id = 1002,
                take_times = 5,
                targets = {
                  {is_finish = true},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              },
              {
                is_finish = false,
                challenge_id = 1003,
                take_times = 7,
                targets = {
                  {is_finish = false},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              }
            }
          },
          {
            levels = {
              {
                is_finish = true,
                challenge_id = 1004,
                take_times = 1,
                targets = {
                  {is_finish = true},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              },
              {
                is_finish = true,
                challenge_id = 1005,
                take_times = 5,
                targets = {
                  {is_finish = true},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              },
              {
                is_finish = true,
                challenge_id = 1006,
                take_times = 5,
                targets = {
                  {is_finish = true},
                  {is_finish = true},
                  {is_finish = true}
                },
                finish_reward_id = 88000101
              }
            }
          }
        },
        rewards = {
          {
            star_required_num = 3,
            state = 1,
            reward_id = 88000101
          },
          {
            star_required_num = 6,
            state = 2,
            reward_id = 88000102
          },
          {
            star_required_num = 9,
            state = 2,
            reward_id = 88000103
          },
          {
            star_required_num = 12,
            state = 2,
            reward_id = 88000104
          },
          {
            star_required_num = 15,
            state = 3,
            reward_id = 88000105
          }
        }
      }
    },
    {
      activity_type = ProtoEnum.ActivityType.ATP_BOSS_CHALLENGE_EVENT,
      activity_id = 1400001,
      boss_challenge_data = {
        event_id = 1400001,
        levels = {
          {
            is_finish = true,
            take_times = 1,
            targets = {
              {is_finish = true},
              {is_finish = true},
              {is_finish = true}
            },
            finish_reward_id = 88000101,
            challenge_id = 1001
          },
          {
            is_finish = false,
            take_times = 3,
            targets = {
              {is_finish = true},
              {is_finish = true},
              {is_finish = true}
            },
            finish_reward_id = 88000101,
            challenge_id = 1002
          },
          {
            is_finish = false,
            take_times = 2,
            targets = {
              {is_finish = true},
              {is_finish = true},
              {is_finish = false}
            },
            finish_reward_id = 88000101,
            challenge_id = 1003
          },
          {
            is_finish = false,
            take_times = 2,
            targets = {
              {is_finish = true},
              {is_finish = true},
              {is_finish = true}
            },
            finish_reward_id = 88000101,
            challenge_id = 1004
          }
        },
        rewards = {
          {
            star_required_num = 1,
            state = 1,
            reward_id = 88000101
          },
          {
            star_required_num = 2,
            state = 1,
            reward_id = 88000102
          },
          {
            star_required_num = 3,
            state = 2,
            reward_id = 88000103
          },
          {
            star_required_num = 4,
            state = 3,
            reward_id = 88000104
          }
        }
      }
    }
  }
  local activity_data = self.playerInfo.svr_data_info.activity_info.activity_data
  for i, activity in ipairs(activity_data) do
    if ActivityType == activity.activity_type then
      if ActivityType == ProtoEnum.ActivityType.ATP_NPC_CHALLENGE_EVENT then
        return activity.npc_challenge_data, activity
      elseif ActivityType == ProtoEnum.ActivityType.ATP_BOSS_CHALLENGE_EVENT then
        return activity.boss_challenge_data, activity
      end
    end
  end
  return nil
end

function PlayerDataModel:UpdateChallengeData(star_required_num, activity_id, ActivityType)
  local activity_data = self.playerInfo.svr_data_info.activity_info.activity_data
  for i, activity in ipairs(activity_data) do
    if activity.activity_id == activity_id then
      local rewards
      if ActivityType == ProtoEnum.ActivityType.ATP_NPC_CHALLENGE_EVENT then
        rewards = activity.npc_challenge_data.rewards
      elseif ActivityType == ProtoEnum.ActivityType.ATP_BOSS_CHALLENGE_EVENT then
        rewards = activity.boss_challenge_data.rewards
      end
      for j, reward in ipairs(rewards) do
        if reward.star_required_num == star_required_num then
          reward.state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
          return
        end
      end
    end
  end
end

function PlayerDataModel:GetPetData()
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  return petInfo.pet_data
end

function PlayerDataModel:GetPetDataByGid(gid, isMirror)
  if _G.PVPRankedMatchModuleCmd then
    local isTrialPet, trialPetData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, gid)
    if isTrialPet then
      return trialPetData
    end
    local isRandomPet, randomPetData
    isRandomPet, randomPetData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, gid)
    if isRandomPet then
      return randomPetData
    end
  end
  if _G.PetUIModuleCmd and isMirror then
    local MirrorPetData = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetMirrorPetDataByGid, gid)
    if MirrorPetData then
      return MirrorPetData
    end
  end
  return self.petGidMap[gid]
end

function PlayerDataModel:GetPetHandbookDataWithTypeFilter(petTypeFilterList)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return {}
  end
  if not petInfo.handbook.record_collection then
    return {}
  end
  local handbookDataList = {}
  for _, record in ipairs(petInfo.handbook.record_collection) do
    if not record.record or 0 == #record.record then
    else
      for _, recordData in ipairs(record.record) do
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(recordData.pet_base_id)
        if not petBaseConf then
          Log.Error("PlayerDataModel:GetPetHandbookData petBaseConf is nil, pet_base_id: " .. recordData.pet_base_id)
        else
          local mainPetType = petBaseConf.unit_type and petBaseConf.unit_type[1]
          if not mainPetType then
            Log.Error("PlayerDataModel:GetPetHandbookData petBaseConf.unit_type is nil, pet_base_id: " .. recordData.pet_base_id)
          else
            if petTypeFilterList and #petTypeFilterList > 0 then
              local isMatchType = false
              if table.contains(petTypeFilterList, mainPetType) then
                isMatchType = true
              end
              if not isMatchType then
            end
            else
              local isNormalType = false
              local isShiningType = false
              local isOtherType = false
              local shiningMutationType = 0
              if recordData.catch_mutation then
                for i = 1, #recordData.catch_mutation do
                  local type = recordData.catch_mutation[i]
                  if type == _G.Enum.MutationDiffType.MDT_NONE then
                    isNormalType = true
                  elseif PetMutationUtils.GetMutationValue(type, _G.Enum.MutationDiffType.MDT_SHINING) then
                    isShiningType = true
                    shiningMutationType = type
                  else
                    isOtherType = true
                  end
                end
              end
              if isShiningType then
                local handbookData = {
                  pet_base_id = recordData.pet_base_id,
                  mutation_type = shiningMutationType,
                  skill_dam_type = mainPetType,
                  handbook_id = record.handbook_id
                }
                table.insert(handbookDataList, handbookData)
              end
              if isNormalType or isOtherType then
                local handbookData = {
                  pet_base_id = recordData.pet_base_id,
                  mutation_type = _G.Enum.MutationDiffType.MDT_NONE,
                  skill_dam_type = mainPetType,
                  handbook_id = record.handbook_id
                }
                table.insert(handbookDataList, handbookData)
              end
            end
          end
        end
      end
    end
  end
  return handbookDataList
end

function PlayerDataModel:GetPetTypeListFromPetHandbook()
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return {}
  end
  if not petInfo.handbook.record_collection then
    return {}
  end
  local typeList = {}
  for _, record in ipairs(petInfo.handbook.record_collection) do
    if not record.record or 0 == #record.record then
    else
      for _, recordData in ipairs(record.record) do
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(recordData.pet_base_id)
        if not petBaseConf then
          Log.Error("PlayerDataModel:GetPetHandbookTypeList petBaseConf is nil, pet_base_id: " .. recordData.pet_base_id)
        else
          local mainPetType = petBaseConf.unit_type and petBaseConf.unit_type[1]
          if not mainPetType then
            Log.Error("PlayerDataModel:GetPetHandbookTypeList petBaseConf.unit_type is nil, pet_base_id: " .. recordData.pet_base_id)
          elseif not table.contains(typeList, mainPetType) then
            table.insert(typeList, mainPetType)
          end
        end
      end
    end
  end
  return typeList
end

function PlayerDataModel:GetPetDataByDepartment(PetType)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  local recordList = {}
  local PetDataList = {}
  if petInfo.handbook.record_collection and #petInfo.handbook.record_collection > 0 then
    for i, record in ipairs(petInfo.handbook.record_collection) do
      local HandBookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, record.handbook_id)
      if HandBookData.Records then
        for j, HandBook in pairs(HandBookData.Records) do
          local petDataList = self:GetPetDataListByPetBaseId(HandBook.PetBaseId)
          if petDataList then
            for _, petData in ipairs(petDataList) do
              local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
              if PetBaseConf and PetBaseConf.unit_type and #PetBaseConf.unit_type > 0 then
                for k, Type in ipairs(PetBaseConf.unit_type) do
                  if PetType == Type then
                    if 2 ~= #PetBaseConf.unit_type or not self:IsFavoriteThirdPet(petData, PetType) then
                      if petData.mutation_type == _G.Enum.MutationDiffType.MDT_NONE then
                        if recordList[petData.base_conf_id] then
                          if not recordList[petData.base_conf_id].IsNormal then
                            table.insert(PetDataList, petData)
                            recordList[petData.base_conf_id].IsNormal = true
                          end
                          break
                        end
                        table.insert(PetDataList, petData)
                        recordList[petData.base_conf_id] = {}
                        recordList[petData.base_conf_id].IsNormal = true
                        break
                      end
                      if PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsCHAOS(petData.mutation_type) then
                        if recordList[petData.base_conf_id] then
                          if not recordList[petData.base_conf_id].IsShine then
                            table.insert(PetDataList, petData)
                            recordList[petData.base_conf_id].IsShine = true
                          end
                          break
                        end
                        table.insert(PetDataList, petData)
                        recordList[petData.base_conf_id] = {}
                        recordList[petData.base_conf_id].IsShine = true
                      end
                    end
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  return PetDataList
end

function PlayerDataModel:IsFavoriteThirdPet(PetData, PetType)
  local PlayerCardBriefInfo = self.playerInfo.brief_info.additional_data and self.playerInfo.brief_info.additional_data.card_brief_info
  if PlayerCardBriefInfo.card_favorite_pet_info and #PlayerCardBriefInfo.card_favorite_pet_info > 0 then
    for i, favorite_pet in ipairs(PlayerCardBriefInfo.card_favorite_pet_info) do
      if PetData.base_conf_id == favorite_pet.pet_base_id and favorite_pet.skill_dam_type ~= PetType then
        return true
      end
    end
  end
  return false
end

function PlayerDataModel:GetHandbookInfoByPetBaseId(baseId)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  if petInfo.handbook then
    if petInfo.handbook.records then
      for _, bookInfo in ipairs(petInfo.handbook.records) do
        if baseId == bookInfo.pet_base_id then
          return bookInfo
        end
      end
    end
    if petInfo.handbook.record_collection then
      for _, bookInfo in ipairs(petInfo.handbook.record_collection) do
        if bookInfo.record then
          for _, recordData in ipairs(bookInfo.record) do
            if baseId == recordData.pet_base_id then
              return bookInfo
            end
          end
        else
          Log.Error("PlayerDataModel:GetHandbookInfoByPetBaseId==\229\189\147\229\137\141\231\178\190\231\129\181\230\178\161\230\156\137\229\155\190\233\137\180\230\149\176\230\141\174==handbookId \228\184\186 ", bookInfo.handbook_id)
        end
      end
    end
  end
  return nil
end

function PlayerDataModel:IsAssignStoryFlags(story_flags)
  return self:HasStoryFlag(story_flags)
end

function PlayerDataModel:IsUseSelfStoryFlag(story_flags)
  if not self.playerInfo then
    return true
  end
  if self:IsVisitState() then
    if self:IsVisitOwner() then
      return true
    end
    local StoryConf = _G.DataConfigManager:GetFunctionStoryFlagConf(story_flags, true)
    if StoryConf then
      return not StoryConf.apply_to_visitor
    end
  end
  return true
end

function PlayerDataModel:CompassShouldAppear()
  if self.playerInfo.story_flag_info and self.playerInfo.story_flag_info.story_flags then
    for _, item in ipairs(self.playerInfo.story_flag_info.story_flags) do
      if 9999 == item then
        return true
      end
    end
  end
  return false
end

function PlayerDataModel:GetPetDataByPetBaseId(baseId)
  local pet_data = self.petBaseIdMap[baseId]
  if not pet_data then
    return nil
  end
  if pet_data.gid then
    return pet_data
  elseif pet_data[1] then
    return pet_data[1]
  end
  return nil
end

function PlayerDataModel:GetPetDatasByPetBaseId(baseId)
  local pet_data = self.petBaseIdMap[baseId]
  if not pet_data then
    return {}
  end
  if pet_data.gid then
    return {pet_data}
  end
  return pet_data
end

function PlayerDataModel:IsOwnPetByPetBaseId(baseId)
  return self.petBaseIdMap[baseId] ~= nil
end

function PlayerDataModel:_SetVItemCount(VItemID, count, updateFlag)
  if not self.loginData then
    return
  end
  local preValue = self.loginData.player_info.brief_info.vitem_info.vitem_list[VItemID + 1]
  self.loginData.player_info.brief_info.vitem_info.vitem_list[VItemID + 1] = count
  if updateFlag and preValue and preValue ~= count then
    if VItemID == _G.Enum.VisualItem.VI_ROLEEXP or VItemID == _G.Enum.VisualItem.VI_ROLE_LEVEL then
      local tipExpData = {}
      tipExpData.frameCnt = _G.UpdateManager.FrameCnt
      if VItemID == _G.Enum.VisualItem.VI_ROLE_LEVEL then
        tipExpData.oldLevel = preValue
        tipExpData.newLevel = count
        tipExpData.oldExp = self:GetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLEEXP)
        tipExpData.newExp = tipExpData.oldExp
        tipExpData.addExp = 0
      else
        tipExpData.oldExp = preValue
        tipExpData.newExp = count
        tipExpData.addExp = count - preValue
        tipExpData.oldLevel = self:GetVItemCount(_G.Enum.VisualItem.VI_ROLE_LEVEL)
        tipExpData.newLevel = tipExpData.oldLevel
      end
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateAddExpPropTip(tipExpData))
      if tipExpData.oldLevel ~= self.MaxLevel then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowExpUpTip, TipObject.CreateExpChangeTip(tipExpData))
      end
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.PLAYER_EXP_CHANGED)
    elseif VItemID == _G.Enum.VisualItem.VI_DIAMOND or VItemID == _G.Enum.VisualItem.VI_BRAVE_STAR then
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, VItemID)
    elseif VItemID == _G.Enum.VisualItem.VI_GP then
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.ON_VITEM_GP_CHANGED, preValue, count)
    end
  end
end

function PlayerDataModel:SetPlayerInfo(playerInfo)
  self.playerInfo = playerInfo
  self:InitSelfStoryFlagsMap(playerInfo and playerInfo.story_flag_info and playerInfo.story_flag_info.story_flags)
  self.privilegeInfo = playerInfo and playerInfo.start_up_privilege_info
  self:RebuildPetIndexMaps()
  if RedPointModuleCmd then
    NRCModuleManager:DoCmd(RedPointModuleCmd.UseRedPointDataInit)
  end
  self.PetInfoPage = 1
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_DATA)
  self:RefreshPlayerPet()
  self:RefreshPlayerOnlineVisitState()
  if self:IsMale() then
    _G.NRCAudioManager:SetGlobalSwitch("Player_Gender", "Male")
  else
    _G.NRCAudioManager:SetGlobalSwitch("Player_Gender", "Female")
  end
  if self.playerInfo and self.playerInfo.common_info and self.playerInfo.common_info.navigation_mode_type then
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.NAVIGATION_MODE_UPDATE, self.playerInfo.common_info.navigation_mode_type, true)
  end
  self:SaveVideoData()
end

function PlayerDataModel:SaveVideoData()
  local VideoData = {}
  local sex = 1
  if self:IsMale() then
    sex = 1
  else
    sex = 2
  end
  local skin = 1
  if self:IsBlackMan() then
    skin = 2
  end
  table.insert(VideoData, sex)
  table.insert(VideoData, skin)
  JsonUtils.DumpSaved("VideoData", VideoData)
end

function PlayerDataModel:IsBlackMan()
  if self.playerInfo.svr_data_info and self.playerInfo.svr_data_info.appearance_info and self.playerInfo.svr_data_info.appearance_info.salon_info then
    local wearDataList = self.playerInfo.svr_data_info.appearance_info.salon_info.item_wear_data
    if wearDataList then
      for _, wearData in pairs(wearDataList) do
        if wearData.item_wear_id == 156 then
          return true
        end
      end
    end
  end
  return false
end

function PlayerDataModel:SetLoginData(loginData)
  self.loginData = loginData
  if loginData then
    self:SetPlayerInfo(loginData.player_info)
    self.loginClock = os.clock()
  end
end

function PlayerDataModel:TryGetPetInfo()
  if not self.WaitGetPetInfoRspSuccess then
    self.PetInfoPage = 1
    self.PetInfoVersion = nil
    self:GetPetInfoByPageReq()
    self:RefreshPlayerPet()
  end
end

function PlayerDataModel:OnEnterSceneFinishNtyAckCallBack(notify, isReconnecting, isEnteringCell)
  if isEnteringCell or isReconnecting then
    self.PetInfoPage = 1
    self.PetInfoVersion = nil
    self:GetPetInfoByPageReq()
    self:RefreshPlayerPet()
  end
  self:InvalidateOwlSanctuaryInfoCache()
  if self.bIsShouldSendOutOfStuckReq then
    self.bIsShouldSendOutOfStuckReq = false
    local req = ProtoMessage:newZoneSceneUnstuckTeleportReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_UNSTUCK_TELEPORT_REQ, req, self, self.OutOfStuckRsp)
    Log.Debug("PlayerDataModel:OnEnterSceneFinishNtyAck SendOutOfStuckReq")
  end
end

function PlayerDataModel:OnBriefFriendListReq()
  Log.Debug("PlayerDataModel:OnBriefFriendListReq start")
  local req = _G.ProtoMessage:newZoneFriendGetBriefFriendListReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_BRIEF_FRIEND_LIST_REQ, req, self, self.OnBriefFriendListRsp)
end

function PlayerDataModel:OnBriefFriendListRsp(Rsp)
  Log.DebugFormat("PlayerDataModel:OnBriefFriendListRsp, ret_code = %d", Rsp.ret_info.ret_code)
  if 0 == Rsp.ret_info.ret_code then
    self:SetBriefFriendInfoList(Rsp.friend_list)
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ON_FETCH_PLAYER_FRIEND)
    local req = _G.ProtoMessage:newZoneChatSyncOfflineRedPointReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_SYNC_OFFLINE_RED_POINT_REQ, req, self, self.OnSyncChatOfflineRedPointRsp)
    Log.Debug("[PlayerDataModel:SyncChatOfflineRedPoint] Send sync request")
  end
end

function PlayerDataModel:OnSyncChatOfflineRedPointRsp(rsp)
  if rsp then
    Log.Debug("[PlayerDataModel:OnSyncChatOfflineRedPointRsp] Receive sync response")
  end
end

function PlayerDataModel:AddOrRemoveBriefFriend(IsAdd, Uin, BriefFriendInfo)
  if IsAdd then
    if not BriefFriendInfo then
      Log.ErrorFormat("PlayerDataModel:AddOrRemoveBriefFriend, BriefFriendInfo is nil, Uin = %d", Uin)
      return
    end
    self.briefFriendInfoDic[Uin] = BriefFriendInfo
  else
    if not self.briefFriendInfoDic[Uin] then
      return
    end
    self.briefFriendInfoDic[Uin] = nil
  end
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, IsAdd, Uin)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin)
  if player and UE.UObject.IsValid(player.viewObj) then
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.UPDATE_PLAYER_TAG, player.viewObj)
  end
end

function PlayerDataModel:SetBriefFriendInfoList(_BriefFriendInfoList)
  self.briefFriendInfoDic = {}
  if not _BriefFriendInfoList or #_BriefFriendInfoList <= 0 then
    Log.Debug("PlayerDataModel:SetBriefFriendList, _BriefFriendInfoList is nil or empty")
    return
  end
  for i, v in ipairs(_BriefFriendInfoList) do
    self.briefFriendInfoDic[v.uin] = v
  end
  Log.Debug("PlayerDataModel:SetBriefFriendList", #_BriefFriendInfoList)
end

function PlayerDataModel:IsFriend(playerUin)
  if self.briefFriendInfoDic[playerUin] then
    return true
  else
    return false
  end
end

function PlayerDataModel:UpdateFriendBriefInfoWithNote(playerUin, _note)
  if not playerUin or not _note then
    Log.Error("PlayerDataModel:UpdateBriefFriendNickName, parameter playerUin or note is nil")
    return
  end
  local briefFriendInfo = self:GetBriefFriendInfoByUin(playerUin)
  if not briefFriendInfo then
    Log.ErrorFormat("PlayerDataModel:UpdateBriefFriendNickName, briefFriendInfo is nil, playerUin = %d", playerUin)
    return
  end
  briefFriendInfo.note = _note
end

function PlayerDataModel:UpdateFriendBriefInfoWithPinnedTime(playerUin, _pinned_time)
  if not playerUin or not _pinned_time then
    Log.Error("PlayerDataModel:UpdateBriefFriendPinnedTime, playerUin or _pinned_time is nil")
    return
  end
  local briefFriendInfo = self:GetBriefFriendInfoByUin(playerUin)
  if not briefFriendInfo then
    Log.ErrorFormat("PlayerDataModel:UpdateBriefFriendPinnedTime, briefFriendInfo is nil, playerUin = %d", playerUin)
    return
  end
  briefFriendInfo.pinned_time = _pinned_time
end

function PlayerDataModel:GetBriefFriendInfoByUin(playerUin)
  if not playerUin then
    Log.Error("PlayerDataModel:GetBriefFriendInfoByUin, playerUin is nil")
    return nil
  end
  if self.briefFriendInfoDic[playerUin] then
    return self.briefFriendInfoDic[playerUin]
  else
    return nil
  end
end

function PlayerDataModel:GetFriendNoteByUin(playerUin)
  local briefFriendInfo = self:GetBriefFriendInfoByUin(playerUin)
  if briefFriendInfo then
    return briefFriendInfo.note or ""
  else
    return ""
  end
end

function PlayerDataModel:GetPetInfoByPageReq()
  self.WaitGetPetInfoRspSuccess = false
  if not self.PetInfoPage then
    self.PetInfoPage = 1
  end
  local req = _G.ProtoMessage:newZoneGetPetInfoByPageReq()
  req.page = self.PetInfoPage
  if self.PetInfoVersion then
    req.version = self.PetInfoVersion
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PET_INFO_BY_PAGE_REQ, req, self, self.GetPetInfoByPageRsp)
end

function PlayerDataModel:SetPetInfoVersion(Version)
  self.PetInfoVersion = Version
end

function PlayerDataModel:GetPetInfoByPageRsp(Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", Rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
    return
  else
    if Rsp.version and 0 ~= Rsp.version then
      self.PetInfoVersion = Rsp.version
    end
    if Rsp.no_new_data and 0 ~= Rsp.no_new_data then
      return
    end
    if Rsp.pet_info and Rsp.pet_info.pet_data then
      local PetInfo = Rsp.pet_info.pet_data
      for i = 1, #PetInfo do
        local HasData = false
        for j, v in pairs(self.playerInfo.pet_info.pet_data) do
          if v.gid == PetInfo[i].gid then
            self.playerInfo.pet_info.pet_data[j] = PetInfo[i]
            HasData = true
            break
          end
        end
        if not HasData then
          table.insert(self.playerInfo.pet_info.pet_data, PetInfo[i])
        end
      end
      Log.Debug(Rsp.req_page, "\231\178\190\231\129\181\230\149\176\230\141\174\230\139\137\229\143\150")
      if Rsp.req_page >= Rsp.total_page then
        self.WaitGetPetInfoRspSuccess = true
        Log.Debug("\231\178\190\231\129\181\230\149\176\230\141\174\230\139\137\229\143\150\229\174\140\230\136\144")
        Log.Debug(#self.playerInfo.pet_info.pet_data, "PlayerDataModel:GetPetInfoByPageRsp")
        self:RebuildPetIndexMaps()
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET)
        self.PetInfoPage = 1
        return
      else
        self.PetInfoPage = Rsp.req_page + 1
        self:GetPetInfoByPageReq()
      end
    end
  end
end

function PlayerDataModel:UpdateFollowPet(gid)
  self.playerInfo.pet_info.fellow_gid = gid
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_FOLLOW_PET, gid)
end

function PlayerDataModel:UpdateCatchInfo(newCatchInfo)
  self.playerInfo.pet_info.catch_info = newCatchInfo
end

function PlayerDataModel:OnNet_PlayerSyncNotify(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.sync_info.level then
      self:_SetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLE_LEVEL, rsp.sync_info.level)
      if not self.playerInfo then
        Log.Debug("\231\172\172\228\184\128\230\172\161\229\136\155\232\167\146\230\151\182\230\151\160\232\167\146\232\137\178\230\149\176\230\141\174")
        return
      end
      self.playerInfo.brief_info.level = rsp.sync_info.level
    end
    if rsp.sync_info.exp then
      self:_SetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLEEXP, rsp.sync_info.exp)
    end
    if rsp.sync_info.world_level then
      self:_SetVItemCount(_G.ProtoEnum.VisualItem.VI_WORLD_LEVEL, rsp.sync_info.world_level)
      self.playerInfo.brief_info.additional_data.world_level = rsp.sync_info.world_level
    end
    if rsp.sync_info.vitem_info then
      self.loginData.player_info.brief_info.vitem_info.vitem_list = rsp.sync_info.vitem_info.vitem_list
    end
    if rsp.sync_info.icon_id then
      self.playerInfo.brief_info.additional_data.player_icon_id = rsp.sync_info.icon_id
    end
    if rsp.sync_info.sex then
      self.playerInfo.brief_info.sex = rsp.sync_info.sex
    end
    if rsp.sync_info.name then
      self.playerInfo.brief_info.name = rsp.sync_info.name
    end
    self.playerInfo.common_info.in_dungeon_id = rsp.sync_info.in_dungeon_id
    self.playerInfo.common_info.select_pet_conf_id = rsp.sync_info.select_pet_conf_id
    self.playerInfo.common_info.pet_select_region_id = rsp.sync_info.pet_select_region_id
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_DATA)
  end
end

function PlayerDataModel:OnVisitPlayerInfoSyncNotify(rsp)
  Log.Trace(rsp.online_visit_owner, "PlayerDataModel:OnVisitPlayerInfoSyncNotify")
  if rsp.online_visit_owner then
    local oldOwner = self.playerInfo.common_info.online_visit_owner
    local newOwner = rsp.online_visit_owner
    self.playerInfo.common_info.online_visit_owner = rsp.online_visit_owner
    if oldOwner and 0 ~= oldOwner and oldOwner ~= newOwner then
      self:ClearHomeOwnerStoryFlag()
    end
    Log.Debug("PlayerDataModel:OnVisitPlayerInfoSyncNotify", oldOwner, newOwner)
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.VISIT_OWNER_CHANGED, oldOwner, newOwner, rsp.first_enter_visiting)
    self:RefreshPlayerOnlineVisitState()
  end
end

function PlayerDataModel:RefreshPlayerOnlineVisitState()
  local curOwner = self.playerInfo and self.playerInfo.common_info.online_visit_owner or 0
  if 0 ~= curOwner then
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_VISITING)
  else
    _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_VISITING)
  end
end

function PlayerDataModel:OnZoneHomeInfoChangeNotify(nty)
  self.playerInfo.common_info.home_owner_uin = nty.home_owner_uin
  self.playerInfo.common_info.is_home_visiting = nty.is_home_visiting
  self.playerInfo.common_info.is_online_visiting_home = nty.is_online_visiting_home
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.ON_HOME_VISIT_INFO_CHANGED)
end

function PlayerDataModel:OnZoneDailyLimitNotify(Notify)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Notify.tips)
end

function PlayerDataModel:OnSetVisitPermissionSetting(permission_type)
  if permission_type then
    self.playerInfo.common_info.visit_permission_setting = permission_type
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.VISIT_PERMISSION_CHANGED, permission_type)
  end
end

function PlayerDataModel:GetVisitPermissionType()
  return self.playerInfo.common_info.visit_permission_setting or ProtoEnum.VisitPermissionSettingType.VPST_JOIN_AFTER_AGREE
end

function PlayerDataModel:SetOnlineVisitorChangeNotify(_notify)
  if _notify.visitors then
    Log.Error(#_notify.visitors, "VisitorChangeNum")
  end
  Log.Dump(_notify, 6, "PlayerDataModel:SetOnlineVisitorChangeNotify")
  local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
  if FriendModule then
    FriendModule:SetOnlineVisitorChangeNotify(_notify)
    return
  end
  self.visitList = _notify.visitors
end

function PlayerDataModel:IsVisitor(uin)
  local visitList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  local visitorList = visitList or self.visitList
  if not visitorList then
    return false
  end
  for _, visitor in ipairs(visitorList) do
    if visitor.uin == uin then
      return true
    end
  end
  return false
end

function PlayerDataModel:OnNet_PlayerPetHpChangeNotify(rsp)
  if rsp.pet_info then
    for k, petHpInfo in ipairs(rsp.pet_info) do
      local pet_gid = petHpInfo.pet_gid or -1
      local pet_curr_hp = petHpInfo.pet_curr_hp or 0
      local pet_max_hp = petHpInfo.pet_max_hp or 0
      local petData = self:GetPetDataByGid(pet_gid)
      if petData then
        if petData.attribute_new_info then
          local type = _G.ProtoEnum.AttributeType
          local addi_attr = petData.attribute_new_info.addi_attr_data
          if addi_attr then
            local PetAdditional = petData.attribute_new_info.addi_attr_data
            for i, attr in ipairs(PetAdditional) do
              if attr.type == type.AT_HPMAX then
                attr.addi_attr = pet_max_hp
              elseif attr.type == type.AT_HPCUR then
                attr.addi_attr = pet_curr_hp
              end
            end
          end
          _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 2, petData)
        end
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_PET_HP, petData)
      end
    end
  end
end

function PlayerDataModel:OnPlayerPetInfoChange(_petData)
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_PET_HP, _petData)
end

function PlayerDataModel:OnGuidBookChangeNotify(rsp)
  local PlayerInfo = self:GetPlayerInfo()
  if not PlayerInfo then
    return nil
  end
  if 1 == rsp.type then
    if PlayerInfo.world_map_info.guide_books == nil then
      PlayerInfo.world_map_info.guide_books = {}
    end
    table.insert(PlayerInfo.world_map_info.guide_books, rsp.book_data)
  else
    for i, bookInfo in ipairs(PlayerInfo.world_map_info.guide_books) do
      if rsp.book_id == bookInfo.id then
        PlayerInfo.world_map_info.guide_books[i] = rsp.book_data
        if rsp.book_data.stamps and #rsp.book_data.stamps > 0 then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, TipObject.FormStamps(rsp), ProtoCMD.ZoneSvrCmd.ZONE_SCENE_GUIDE_BOOK_NOTIFY)
        end
      end
    end
  end
end

function PlayerDataModel:OnStoryFlagChangeNotify(rsp)
  local PlayerInfo = self:GetPlayerInfo()
  if not PlayerInfo then
    return nil
  end
  if not PlayerInfo.story_flag_info then
    PlayerInfo.story_flag_info = {}
  end
  if not PlayerInfo.story_flag_info.story_flags then
    PlayerInfo.story_flag_info.story_flags = {}
  end
  if rsp.change_type == ProtoEnum.StoryFlagChangeType.ENUM.Add then
    for _, StoryFlag in ipairs(PlayerInfo.story_flag_info.story_flags) do
      if rsp.change_val == StoryFlag then
        return
      end
    end
    table.insert(PlayerInfo.story_flag_info.story_flags, rsp.change_val)
    self:AddToSelfStoryFlagsMap(rsp.change_val)
    Log.DebugFormat("PlayerDataModel:OnStoryFlagChangeNotify after Add StoryFlag %d, listCount = %d, mapCount = %d", rsp.change_val, #PlayerInfo.story_flag_info.story_flags, self.SelfStoryFlagsMapCount)
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, rsp.change_val)
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, rsp.change_val)
  elseif rsp.change_type == ProtoEnum.StoryFlagChangeType.ENUM.Delete then
    for index, StoryFlag in ipairs(PlayerInfo.story_flag_info.story_flags) do
      if rsp.change_val == StoryFlag then
        table.remove(PlayerInfo.story_flag_info.story_flags, index)
        self:RemoveFromSelfStoryFlagsMap(rsp.change_val)
        Log.DebugFormat("PlayerDataModel:OnStoryFlagChangeNotify after Remove StoryFlag %d, listCount = %d, mapCount = %d", rsp.change_val, #PlayerInfo.story_flag_info.story_flags, self.SelfStoryFlagsMapCount)
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_REMOVED, rsp.change_val)
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, rsp.change_val)
        return
      end
    end
  end
end

function PlayerDataModel:OnMultiStoryFlagChangeNotify(rsp)
  local single_notify = _G.ProtoMessage:newZonePlayerStoryFlagChangeNotify()
  for index, change_val in ipairs(rsp.change_val) do
    single_notify.change_type = rsp.change_type
    single_notify.change_val = change_val
    single_notify.version = rsp.version
    self:OnStoryFlagChangeNotify(single_notify)
  end
end

function PlayerDataModel:UpdateHomeOwnerStoryFlags(Rep)
  if not Rep.visit_owner_story_flags then
    return
  end
  if not self.HomeOwnerStoryFlags then
    self.HomeOwnerStoryFlags = Rep.visit_owner_story_flags or {}
    self:InitHomeOwnerStoryFlagsMap(self.HomeOwnerStoryFlags)
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.ON_HOME_OWNER_STORY_FLAG_CHANGED, true)
    return
  end
  local OldFlags = self.HomeOwnerStoryFlags or {}
  self.HomeOwnerStoryFlags = Rep.visit_owner_story_flags or {}
  self:InitHomeOwnerStoryFlagsMap(self.HomeOwnerStoryFlags)
  local OldSet = {}
  for _, Flag in ipairs(OldFlags) do
    OldSet[Flag] = true
  end
  local NewSet = {}
  for _, Flag in ipairs(self.HomeOwnerStoryFlags) do
    NewSet[Flag] = true
  end
  for _, Flag in ipairs(self.HomeOwnerStoryFlags) do
    if not OldSet[Flag] then
      Log.Debug("PlayerDataModel:UpdateHomeOwnerStoryFlags Add:", Flag)
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, Flag, true)
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, Flag, true)
    end
  end
  for _, Flag in ipairs(OldFlags) do
    if not NewSet[Flag] then
      Log.Debug("PlayerDataModel:UpdateHomeOwnerStoryFlags Remove:", Flag)
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_REMOVED, Flag)
      self:SendEvent(ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, Flag, true)
    end
  end
end

function PlayerDataModel:ShouldSendOutOfStuckReq(bHomeOwner)
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if LocalPlayer and UE.UObject.IsValid(LocalPlayer.viewObj) then
    local ActorLoc = LocalPlayer:GetActorLocationFrameCache()
    Log.Debug("PlayerDataModel:ShouldSendOutOfStuckReq", ActorLoc.X, ActorLoc.Y, ActorLoc.Z)
    local CheckList = {}
    local RawConfs = _G.DataConfigManager:GetAllByName("FUNCTION_STORY_FLAG_CONF")
    for ID, Conf in pairs(RawConfs) do
      local Location = Conf.unreachable_range or {}
      local SceneID = tonumber(Location[1]) or 0
      local CurrentSceneID = SceneUtils.GetSceneID()
      if SceneID == CurrentSceneID then
        local Radius = tonumber(Conf.range_data) or 0
        if Radius > 0 then
          local LocationX = tonumber(Location[2]) or 0
          local LocationY = tonumber(Location[3]) or 0
          local LocationZ = tonumber(Location[4]) or 0
          local LevelPos = UE4.FVector(LocationX, LocationY, LocationZ)
          local RadiusSquared = Radius * Radius
          local Squared = UE.FVector.DistSquared(ActorLoc, LevelPos)
          if RadiusSquared >= Squared then
            table.insert(CheckList, ID)
          end
        end
      end
    end
    local StoryFlags = self:GetStoryFlags()
    if bHomeOwner then
      StoryFlags = self:GetHomeOwnerStoryFlags()
    end
    for _, Flag in ipairs(CheckList) do
      for _, StoryFlag in ipairs(StoryFlags) do
        if Flag == StoryFlag then
          return true
        end
      end
    end
  end
  return false
end

function PlayerDataModel:OnBattleHandbookChangeNotify(notify)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  if not notify.ret_info then
    return
  end
  local BattlePetChangeInfo = notify.ret_info.goods_change_info
  if BattlePetChangeInfo.changes and #BattlePetChangeInfo.changes > 0 then
    local changes = BattlePetChangeInfo.changes
    for i, change in ipairs(changes) do
      if changes.handbook_record then
        table.insert(petInfo.handbook.records, changes.handbook_record)
      end
    end
  end
  local PerFormInfo = notify.perform_cmd.perform_info
  if PerFormInfo and #PerFormInfo > 0 then
    for i, PerForm in ipairs(PerFormInfo) do
      if PerForm.type == ProtoEnum.BattlePerformType.BPT_CATCH_PET and PerForm.sync_data and PerForm.sync_data.role_sync_info and #PerForm.sync_data.role_sync_info > 0 then
        local syncInfo = PerForm.sync_data.role_sync_info[1]
        if syncInfo.role_uin == self:GetPlayerUin() then
          _G.NRCModuleManager:DoCmd(BagModuleCmd.UpdateBagItemNumByID, PerForm.catch_pet_info.ball_id, PerForm.sync_data.role_sync_info[1].item_num)
        end
      end
    end
  end
end

function PlayerDataModel:OnBattleInstantPerformNotify(notify)
  _G.BattleManager:CheckBattleDataUpdate(notify.perform_cmd)
  BattleEventCenter:Dispatch(BattleEvent.UI_INSTANT_UPDATE_ITEM)
  local PerFormInfo = notify.perform_cmd.perform_info
  if PerFormInfo and #PerFormInfo > 0 then
    for i, PerForm in ipairs(PerFormInfo) do
      if PerForm.type == ProtoEnum.BattlePerformType.BPT_CATCH_PET and PerForm.sync_data and PerForm.sync_data.role_sync_info and #PerForm.sync_data.role_sync_info > 0 then
        local syncInfo = PerForm.sync_data.role_sync_info[1]
        if syncInfo.role_uin == self:GetPlayerUin() then
          _G.NRCModuleManager:DoCmd(BagModuleCmd.UpdateBagItemNumByID, PerForm.catch_pet_info.ball_id, PerForm.sync_data.role_sync_info[1].item_num)
        end
      end
    end
  end
end

function PlayerDataModel:BuyDiamondCountChangeNotify(notify)
  self:SetBuyDiamondCount(notify.buy_times)
  if self.loginData then
    self:SendEvent(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA)
  end
end

function PlayerDataModel:OnVItemChangedHandler(item)
  Log.Debug("VItemChange")
  if item.op == ProtoEnum.OpType.OT_SET or item.op == nil and nil ~= self.loginData then
    self:_SetVItemCount(item.id, item.num, true)
  end
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, _G.Enum.GoodsType.GT_VITEM)
end

function PlayerDataModel:OnPetDatChangedHandler(item, CmdID)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  local CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.None
  if not petInfo.pet_data then
    petInfo.pet_data = {}
    if item.pet_data then
      self:AddPetData(item.pet_data)
    end
  else
    for i, k in ipairs(petInfo.pet_data) do
      if item.pet_data and k.gid == item.pet_data.gid then
        if item.num <= 0 then
          self:UpdatePetIndexMaps(k, true)
          table.remove(petInfo.pet_data, i)
          CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.Free
          goto lbl_172
        end
        do
          local Old = petInfo.pet_data[i]
          local New = item.pet_data
          self:SetPetData(New, i)
          if Old.level ~= New.level then
            self:AddToCachePool(CmdID, TipObject.FromPetLevelUp(New, PetUtils.GetNewSkillDatas(Old, New), New.level - Old.level))
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.LevelUp
          end
          if Old.base_conf_id ~= New.base_conf_id then
            self:AddToCachePool(CmdID, TipObject.FromPetEvolution(New, Old))
            self:SendEvent(ENUM_PLAYER_DATA_EVENT.PET_EVOLUTION, New, Old)
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.Evolve
          end
          if Old.talent_rank ~= New.talent_rank then
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.TalentChange
          end
          if Old.last_breakthrough_lv == New.last_breakthrough_lv and Old.grow_times ~= New.grow_times then
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.GrowUp
          end
          if Old.last_breakthrough_lv ~= New.last_breakthrough_lv then
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.BreakThrough
          end
          if self:CheckPetIsTraceBack(Old, New) then
            CurPetDataUpdateReasonType = PetUIModuleEnum.PetDataUpdateReason.TraceBack
          end
          if Old.pet_status_flags ~= New.pet_status_flags then
            self:SendEvent(ENUM_PLAYER_DATA_EVENT.PET_FLAG_CHANGE, New, Old)
            if item.change_reason == ProtoEnum.FlowReason.FLOW_REASON_MIRACLE_CHANGE_TIMEOUT then
              self:AddToCachePool(CmdID, TipObject.FromMiracleExchange(New, item.change_reason))
            end
          end
        end
        goto lbl_172
      end
    end
    if item.type == ProtoEnum.GoodsType.GT_PET then
      self:AddPetData(item.pet_data)
    elseif item.type == ProtoEnum.GoodsType.GT_TEAMINFO then
      local teamInfo = item.team_info
      PetUtils.PlayerPetInfoSetTeamInfo(petInfo, teamInfo, teamInfo.team_type)
    end
  end
  ::lbl_172::
  if self.PetDataChangeItemList == nil then
    self.PetDataChangeItemList = {}
  end
  if item.pet_data and item.pet_data.gid then
    table.insert(self.PetDataChangeItemList, {
      PetGID = item.pet_data.gid,
      PetDataUpdateReasonType = CurPetDataUpdateReasonType
    })
  end
  if not self.delayRefreshPlayerPetId then
    self.delayRefreshPlayerPetId = _G.DelayManager:DelayFrames(1, self.DelayRefreshPlayerPet, self)
  end
end

function PlayerDataModel:CheckPetIsTraceBack(OldPetData, NewPetData)
  local IsTraceBack = false
  local OldTraceBackTime, NewTraceBackTime
  if OldPetData.key_experience and OldPetData.key_experience.backtrack_record_info and OldPetData.key_experience.backtrack_record_info.last_backtrack_time then
    OldTraceBackTime = OldPetData.key_experience.backtrack_record_info.last_backtrack_time
  end
  if NewPetData.key_experience and NewPetData.key_experience.backtrack_record_info and NewPetData.key_experience.backtrack_record_info.last_backtrack_time then
    NewTraceBackTime = NewPetData.key_experience.backtrack_record_info.last_backtrack_time
  end
  if nil == OldTraceBackTime and nil ~= NewTraceBackTime then
    IsTraceBack = true
  elseif nil ~= OldTraceBackTime and nil ~= NewTraceBackTime then
    IsTraceBack = OldTraceBackTime < NewTraceBackTime
  end
  return IsTraceBack
end

function PlayerDataModel:OnPetExpChanged(item)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo or not item then
    return nil
  end
  if not petInfo.pet_data then
    Log.Debug("\230\178\161\230\156\137\229\174\160\231\137\169\228\184\141\229\143\175\232\131\189\228\188\154\229\135\186\231\142\176\229\174\160\231\137\169\231\187\143\233\170\140\229\128\188\229\143\152\229\140\150\231\154\132\230\131\133\229\134\181")
    return nil
  end
  local ChangePetData = {}
  for i, k in ipairs(petInfo.pet_data) do
    if k.gid == item.gid then
      local PetData = petInfo.pet_data[i]
      if item.type == ProtoEnum.GoodsType.GT_PETEXP then
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.PET_EXP_CHANGED, PetData)
        PetData.exp = item.num
        ChangePetData.pet_data = PetData
        break
      end
      if item.type ~= ProtoEnum.GoodsType.GT_PET_HP then
        goto lbl_51
      end
      do break end
      ::lbl_51::
      if item.type == ProtoEnum.GoodsType.GT_PET_EN then
        PetData.energy = item.num
        ChangePetData.pet_data = PetData
      end
      break
    end
  end
  if not self.delayRefreshPlayerPetId then
    self.delayRefreshPlayerPetId = _G.DelayManager:DelayFrames(1, self.DelayRefreshPlayerPet, self)
  end
  if not ChangePetData or ChangePetData.pet_data then
  end
end

function PlayerDataModel:DelayRefreshPlayerPet()
  if self.delayRefreshPlayerPetId then
    _G.DelayManager:CancelDelayById(self.delayRefreshPlayerPetId)
  end
  self.delayRefreshPlayerPetId = nil
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, _G.Enum.GoodsType.GT_PET, self.PetDataChangeItemList)
  self.PetDataChangeItemList = nil
  self:RefreshPlayerPet()
end

function PlayerDataModel:OnBackpackChangeHandler(backpackInfo)
  self.playerInfo.pet_info.backpack_info = backpackInfo
  self.hasBoxVacancyCache = nil
end

function PlayerDataModel:GetPlayerVisitOwnerUin()
  return self.playerInfo.common_info.online_visit_owner
end

function PlayerDataModel:GetIsTraceByBag()
  return self.IsTraceByBag
end

function PlayerDataModel:SetIsTraceByBag(IsTraceByBag)
  self.IsTraceByBag = IsTraceByBag
end

function PlayerDataModel:IsTraceVisitNotOwnerBan()
  if self.IsTraceByBag then
    return false
  end
  if self:IsVisitState() and not self:IsVisitOwner() then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Track_ban_online)
    return true
  end
  return false
end

function PlayerDataModel:IsHomeVisitState()
  if self.playerInfo.common_info.is_home_visiting then
    return true
  else
    return false
  end
end

function PlayerDataModel:IsHomeVisitOwner()
  return self.playerInfo.common_info.home_owner_uin == self.playerInfo.brief_info.uin
end

function PlayerDataModel:IsVisitState()
  if self.playerInfo.common_info.online_visit_owner and 0 ~= self.playerInfo.common_info.online_visit_owner then
    return true
  else
    return false
  end
end

function PlayerDataModel:IsCurrentWorldOwner()
  if self:IsVisitState() and not self:IsVisitOwner() then
    return false
  else
    return true
  end
end

function PlayerDataModel:IsOnlineProcessDisable(online_process)
  online_process = online_process or 0
  if self:IsHomeVisitState() then
    if online_process == _G.Enum.OnlineVisitProcess.OVP_BOTH then
      return false
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_BOTH_FORBIDED then
      if _G.DataModelMgr.PlayerDataModel:IsHomeVisitState() then
        return true
      else
        return false
      end
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_OWNER then
      if _G.DataModelMgr.PlayerDataModel:IsHomeVisitState() and not _G.DataModelMgr.PlayerDataModel:IsHomeVisitOwner() then
        return true
      else
        return false
      end
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_NONE then
      return true
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_NPC_CREATOR then
      return true
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_GUEST then
      if _G.DataModelMgr.PlayerDataModel:IsHomeVisitState() and not _G.DataModelMgr.PlayerDataModel:IsHomeVisitOwner() then
        return false
      else
        return true
      end
    end
  else
    if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      if online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_GUEST then
        Log.Debug("\231\166\129\231\148\168: \229\142\159\229\155\160\230\152\175\233\157\158\232\129\148\231\189\145\231\138\182\230\128\129")
        return true
      end
      return false
    end
    if online_process == _G.Enum.OnlineVisitProcess.OVP_BOTH then
      return false
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_BOTH_FORBIDED then
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        Log.Debug("\231\166\129\231\148\168: \229\142\159\229\155\160\230\152\175\232\129\148\231\189\145\231\138\182\230\128\129\229\133\168\233\131\168\231\166\129\231\148\168")
        return true
      else
        return false
      end
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_OWNER then
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
        Log.Debug("\231\166\129\231\148\168: \229\142\159\229\155\160\230\152\175\232\129\148\231\189\145\231\138\182\230\128\129\228\184\148\228\184\141\230\152\175\230\136\191\228\184\187")
        return true
      else
        return false
      end
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_NONE then
      return true
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_NPC_CREATOR then
      return true
    elseif online_process == _G.Enum.OnlineVisitProcess.OVP_ONLY_GUEST then
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
        return false
      else
        return true
      end
    end
  end
  Log.Error("\232\129\148\230\156\186\230\139\166\230\136\170\231\179\187\231\187\159\233\133\141\233\148\153\228\186\134\230\136\150\232\128\133\229\138\159\232\131\189\228\184\141\229\133\168", online_process)
  return true
end

function PlayerDataModel:IsVisitOwner()
  return self.playerInfo.common_info.online_visit_owner == self.playerInfo.brief_info.uin
end

function PlayerDataModel:BattleDisabled()
  return false
end

function PlayerDataModel:ShowPetTips(item, CmdID)
  if item.pet_data and _G.MainUIModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenMainUIDownTips, 0, item.pet_data, CmdID)
  end
end

function PlayerDataModel:SetHandbookInfo(_records)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  if not _records or #_records <= 0 then
    return
  end
  for i, v in ipairs(_records) do
    table.insert(petInfo.handbook.records, v)
  end
end

function PlayerDataModel:OnPetFree(_pet_gid)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  if not petInfo.pet_data then
    petInfo.pet_data = {}
  end
  self:RefreshPlayerPet()
end

function PlayerDataModel:IsFirstLogin()
  return _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.playerInfo and (0 == _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex or _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex == nil)
end

function PlayerDataModel:CancelFirstLoginState()
end

function PlayerDataModel:AddToCachePool(CmdID, Tip)
  local Pool = self.CachePool[CmdID]
  if not Pool then
    Pool = {}
    self.CachePool[CmdID] = Pool
  end
  table.insert(Pool, Tip)
end

function PlayerDataModel:ResolveCache(CmdID, Coordinator)
  local Pool = self.CachePool[CmdID]
  if not Pool then
    return
  end
  for _, Tip in ipairs(Pool) do
    Coordinator:AddTip(Tip, CmdID)
  end
  table.clear(Pool)
end

function PlayerDataModel:RefreshPet(petData)
  if not petData then
    return
  end
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  local localPlayer = playerModule and playerModule:GetLocalPlayer()
  if localPlayer then
    local petGid = petData.gid
    local petBaseId = petData.base_conf_id
    local isInMainTeam = false
    local teamInfo = self:GetPlayerPetTeamInfo()
    if teamInfo and teamInfo.main_team_idx then
      local mainTeam = teamInfo.teams[teamInfo.main_team_idx + 1]
      if mainTeam and mainTeam.pet_infos then
        for i = 1, #mainTeam.pet_infos do
          local pet = mainTeam.pet_infos[i]
          if pet.pet_gid == petGid then
            isInMainTeam = true
            break
          end
        end
      end
    end
    self.pets = self.pets or {}
    local existingPet = self.pets[petGid]
    if not existingPet then
      local pet = ScenePlayerPet(playerModule, petBaseId, petGid, localPlayer, nil, isInMainTeam)
      self.pets[petGid] = pet
    else
      existingPet:RefreshData(playerModule, petBaseId, petGid, localPlayer, isInMainTeam)
    end
  end
end

function PlayerDataModel:OnPetMainTeamChanged(CurMainTeamIndex)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:OnPetMainTeamChanged(CurMainTeamIndex)
  end
  self:RefreshPlayerPet()
end

function PlayerDataModel:GetPetByGid(gid)
  local petData = self:GetPetDataByGid(gid)
  local pet = self.pets and self.pets[gid]
  if not pet and petData then
    self:RefreshPet(petData)
  end
  if self.pets and self.pets[gid] then
    pet = self.pets[gid]
  end
  return pet
end

function PlayerDataModel:ResetPetFriendRideState()
  for id, pet in pairs(self.pets) do
    if pet then
      pet.rideFriendUin = nil
    end
  end
end

function PlayerDataModel:GetPetByBaseId(baseId)
  local petData = self:GetPetDataByPetBaseId(baseId)
  if petData then
    if self.delayRefreshPlayerPetId then
      self:RefreshPet(petData)
    end
    local pet = self.pets and self.pets[petData.gid]
    return pet
  end
end

function PlayerDataModel:RefreshPlayerPet()
  self.pets = self.pets or {}
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  local localPlayer = playerModule and playerModule:GetLocalPlayer()
  if not localPlayer then
    return
  end
  local teamPetData = {}
  local isMainTeamPet = {}
  local teamInfo = self:GetPlayerPetTeamInfo()
  if teamInfo and teamInfo.teams and #teamInfo.teams > 0 then
    for team_idx, v in ipairs(teamInfo.teams) do
      local isInMainTeam = teamInfo.main_team_idx == team_idx - 1
      local teamPets = v
      if teamPets and teamPets.pet_infos then
        for i = 1, #teamPets.pet_infos do
          local pet = teamPets.pet_infos[i]
          local petData = self:GetPetDataByGid(pet.pet_gid)
          if petData then
            table.insert(teamPetData, petData)
            table.insert(isMainTeamPet, isInMainTeam)
          end
        end
      end
    end
  end
  local currentPetGids = {}
  for i, v in ipairs(teamPetData) do
    local petData = v
    local petGid = petData.gid
    local petBaseId = petData.base_conf_id
    currentPetGids[petGid] = true
    local existingPet = self.pets[petGid]
    if not existingPet then
      local pet = ScenePlayerPet(playerModule, petBaseId, petGid, localPlayer, nil, isMainTeamPet[i])
      self.pets[petGid] = pet
    else
      existingPet:RefreshData(playerModule, petBaseId, petGid, localPlayer, isMainTeamPet[i])
    end
  end
  for k, pet in pairs(self.pets) do
    if not currentPetGids[k] then
      pet:Destroy()
      self.pets[k] = nil
    end
  end
end

function PlayerDataModel:RebindPlayerPetOwner(owner)
  if self.pets then
    for _, v in pairs(self.pets) do
      v.owner = owner
    end
  end
end

function PlayerDataModel:SetPetNewState(_PetData)
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    return nil
  end
  for i, pet in ipairs(petInfo.pet_data) do
    if pet.gid == _PetData.gid then
      pet.pet_status_flags = 0
    end
  end
end

function PlayerDataModel:GetPlayerBondInfo()
  if self.playerInfo.svr_data_info.appearance_info == nil then
    self.playerInfo.svr_data_info.appearance_info = {}
    self.playerInfo.svr_data_info.appearance_info.fashion_bond_info = {
      fashion_bond_item = {}
    }
  end
  return self.playerInfo.svr_data_info.appearance_info.fashion_bond_info or {
    fashion_bond_item = {}
  }
end

function PlayerDataModel:UpdatePlayerBondInfo(bondInfos, isdeduct)
  local fashionBondItems = self.playerInfo.svr_data_info.appearance_info.fashion_bond_info and self.playerInfo.svr_data_info.appearance_info.fashion_bond_info.fashion_bond_item or nil
  if nil == fashionBondItems then
    if not self.playerInfo.svr_data_info.appearance_info.fashion_bond_info then
      self.playerInfo.svr_data_info.appearance_info.fashion_bond_info = {}
    end
    self.playerInfo.svr_data_info.appearance_info.fashion_bond_info.fashion_bond_item = {}
    fashionBondItems = self.playerInfo.svr_data_info.appearance_info.fashion_bond_info.fashion_bond_item
  end
  if fashionBondItems then
    local HaveList = {}
    if bondInfos and #bondInfos > 0 then
      if #fashionBondItems > 0 then
        for k, v in ipairs(fashionBondItems) do
          for key, value in ipairs(bondInfos) do
            if v.id == value.id then
              HaveList[v.id] = true
              v.pet_tree_interacted = value.pet_tree_interacted
              v.color_suit_state = value.color_suit_state
            end
          end
        end
      end
      for k, v in ipairs(bondInfos) do
        if not isdeduct then
          if not HaveList[v.id] then
            table.insert(fashionBondItems, v)
          end
        elseif #fashionBondItems > 0 then
          for index, info in pairs(fashionBondItems) do
            if info.id == v.id then
              table.remove(fashionBondItems, index)
            end
          end
        end
      end
      _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.UPDATE_PLAYER_BOND_INFO)
    end
  end
end

function PlayerDataModel:GetPlayerFashionInfo()
  if self.playerInfo.svr_data_info.appearance_info == nil then
    self.playerInfo.svr_data_info.appearance_info = {}
    self.playerInfo.svr_data_info.appearance_info.fashion_info = {
      suit_info = {}
    }
  end
  if self.playerInfo.svr_data_info.appearance_info and nil == self.playerInfo.svr_data_info.appearance_info.fashion_info then
    self.playerInfo.svr_data_info.appearance_info.fashion_info = {
      suit_info = {}
    }
  end
  return self.playerInfo.svr_data_info.appearance_info.fashion_info
end

function PlayerDataModel:UpdatePlayerSuitInfo(suitInfo)
  local fashionInfo = self:GetPlayerFashionInfo()
  if fashionInfo and suitInfo then
    for _, v in pairs(fashionInfo.suit_info or {}) do
      if v.suit_id == suitInfo.suit_id then
        v.petbase_pvp_win_num = suitInfo.petbase_pvp_win_num
        return
      end
    end
    if not fashionInfo.suit_info then
      fashionInfo.suit_info = {}
    end
    table.insert(fashionInfo.suit_info, suitInfo)
  end
end

function PlayerDataModel:SetPlayerAppearanceInfo(appearanceInfo)
  self.playerInfo.svr_data_info.appearance_info = appearanceInfo
end

function PlayerDataModel:SetPlayerFashionInfo(fashionInfo, suitID)
  local playerFashionInfo = self.playerInfo.svr_data_info.appearance_info.fashion_info
  if 0 ~= suitID then
    playerFashionInfo.suit_id = suitID
    playerFashionInfo.current_wardrobe_index = -1
    return
  end
  if fashionInfo.current_wardrobe_index then
    playerFashionInfo.current_wardrobe_index = fashionInfo.current_wardrobe_index
  end
  if fashionInfo.wardrobe_data then
    playerFashionInfo.wardrobe_data = fashionInfo.wardrobe_data
  end
  if fashionInfo.owned_item_info then
    playerFashionInfo.owned_item_info = fashionInfo.owned_item_info
  end
  if 0 ~= fashionInfo.suit_id then
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:UpdateShoesSoundSwitch()
  end
end

function PlayerDataModel:SetPlayerFashionWardrobeInfo(wardrobeIndex, wardrobeData)
  local playerFashionInfo = self.playerInfo.svr_data_info.appearance_info.fashion_info
  if wardrobeIndex >= 0 then
    if not playerFashionInfo.wardrobe_data then
      for i = 1, 10 do
        playerFashionInfo.wardrobe_data[i] = {}
      end
    end
    if playerFashionInfo.wardrobe_data[wardrobeIndex] == nil then
      playerFashionInfo.wardrobe_data[wardrobeIndex] = {}
    end
    playerFashionInfo.current_wardrobe_index = wardrobeIndex - 1
    playerFashionInfo.wardrobe_data[wardrobeIndex] = wardrobeData
    playerFashionInfo.suit_id = 0
  end
end

function PlayerDataModel:SetPlayerFashionIds(FashionIds)
  self.playerInfo.common_info.appearance_info.fashion_data.wardrobe_data.fashion_id = FashionIds
end

function PlayerDataModel:SetPlayerSalonInfo(salonInfo)
  self.playerInfo.svr_data_info.appearance_info.salon_info = salonInfo
end

function PlayerDataModel:GetPlayerSalonInfo()
  return self.playerInfo.svr_data_info.appearance_info.salon_info
end

function PlayerDataModel:GetPlayerOwnedFashion()
  return self.playerInfo.svr_data_info.appearance_info.fashion_info.owned_item_info
end

function PlayerDataModel:GetPlayerOwnedSalon()
  return self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id
end

function PlayerDataModel:AddPlayerOwnedFashionInfo(fashionInfo, isdeduct)
  if fashionInfo and #fashionInfo > 0 then
    local fashionData = self.playerInfo.svr_data_info.appearance_info.fashion_info
    for k, v in ipairs(fashionInfo) do
      if fashionData.owned_item_info == nil then
        fashionData.owned_item_info = {}
      end
      if not isdeduct then
        local temp = {item_id = v}
        table.insert(fashionData.owned_item_info, temp)
      elseif #fashionData.owned_item_info > 0 then
        for index, info in pairs(fashionData.owned_item_info) do
          if info.item_id == v then
            table.remove(fashionData.owned_item_info, index)
          end
        end
      end
    end
  end
end

function PlayerDataModel:AddPlayerOwnedSalonInfo(salonInfo, isdeduct)
  for k, v in ipairs(salonInfo) do
    if self.playerInfo.svr_data_info.appearance_info.salon_info == nil then
      self.playerInfo.svr_data_info.appearance_info.salon_info = {}
    end
    if nil == self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id then
      self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id = {}
    end
    if not isdeduct then
      table.insert(self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id, v)
    elseif #self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id > 0 then
      for index, id in pairs(self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id) do
        if v == id then
          table.remove(self.playerInfo.svr_data_info.appearance_info.salon_info.item_owned_id, index)
        end
      end
    end
  end
end

function PlayerDataModel:SetPlayerFashionOwnedTask(rewardList)
end

function PlayerDataModel:SetDefaultSuitByData(gender, fashionIds, salonIds)
  local defaultSuitClass, playerPath
  if 2 == gender then
    if NRCEnv:IsLocalMode() then
      defaultSuitClass = UE4.UClass.ResolveClass("/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2_Editor.BP_DefaultSuit_PC2_Editor")
    else
      defaultSuitClass = UE4.UClass.ResolveClass("/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2.BP_DefaultSuit_PC2")
    end
    playerPath = UEPath.DEFAULT_AVATAR_PLAYER_FEMALE
  else
    if NRCEnv:IsLocalMode() then
      defaultSuitClass = UE4.UClass.ResolveClass("/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1_Editor.BP_DefaultSuit_PC1_Editor")
    else
      defaultSuitClass = UE4.UClass.ResolveClass("/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1.BP_DefaultSuit_PC1")
    end
    playerPath = UEPath.DEFAULT_AVATAR_PLAYER_MALE
  end
  local defaultSuitObj
  if self.AvatarDefaultSuitObj then
    defaultSuitObj = self.AvatarDefaultSuitObj
  else
    defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
    self.AvatarDefaultSuitObj = defaultSuitObj
    self.AvatarDefaultSuitObj_Ref = UnLua.Ref(self.AvatarDefaultSuitObj)
  end
  if salonIds and #salonIds > 0 then
    for k, v in ipairs(salonIds) do
      if v.salon_item_id then
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.salon_item_id)
        if salonItemConf then
          local salonColorIndex = _G.DataConfigManager:GetChangeColourConf(v.salon_color_id)
          if salonColorIndex then
            local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumSalon(salonItemConf.type)
            if bBodyType then
              defaultSuitObj:SetBodyPath(avatarEnum, salonItemConf.model)
              if salonItemConf.change_bp then
                defaultSuitObj:SetSalonPath(salonItemConf.change_bp, salonColorIndex.rank_value)
              end
            else
              defaultSuitObj:SetSalonPath(salonItemConf.change_bp, salonColorIndex.rank_value)
            end
          else
            Log.Error("\230\137\190\228\184\141\229\136\176\233\133\141\231\189\174\232\161\168\230\149\176\230\141\174")
          end
        else
          Log.Error("salon\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
  if fashionIds and #fashionIds > 0 then
    for k, v in ipairs(fashionIds) do
      if 0 ~= v then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        if fashionItemConf then
          local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
          if bBodyType then
            defaultSuitObj:SetBodyPath(avatarEnum, fashionItemConf.model)
          else
            defaultSuitObj:SetDecoratorPath(avatarEnum, fashionItemConf.model)
          end
          if fashionItemConf.change_bp then
            defaultSuitObj:SetSalonPath(fashionItemConf.change_bp, 0)
          end
        else
          Log.Error("fashion\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
end

function PlayerDataModel:SetDataByDefaultSuit()
  if self.AvatarDefaultSuitObj then
    local defaultSuitObj = self.AvatarDefaultSuitObj
  end
end

function PlayerDataModel:CheckStoryFlagsMapConsistency(bIsSelf)
  local MapCount, ListCount
  if bIsSelf then
    MapCount = self.SelfStoryFlagsMap and self.SelfStoryFlagsMapCount or 0
    local Flags = self:GetStoryFlags()
    ListCount = Flags and #Flags or 0
  else
    MapCount = self.HomeOwnerStoryFlagsMap and self.HomeOwnerStoryFlagsMapCount or 0
    local Flags = self.HomeOwnerStoryFlags
    ListCount = Flags and #Flags or 0
  end
  if MapCount ~= ListCount then
    local LastErrorMsTime
    if bIsSelf then
      LastErrorMsTime = self.LastSelfStoryFlagsConsistencyErrorMsTime
    else
      LastErrorMsTime = self.LastHomeOwnerStoryFlagsMapConsistencyErrorMsTime
    end
    local CurMsTime = os.msTime()
    if LastErrorMsTime < CurMsTime then
      if bIsSelf then
        self.LastSelfStoryFlagsConsistencyErrorMsTime = CurMsTime + 1000
      else
        self.LastHomeOwnerStoryFlagsMapConsistencyErrorMsTime = CurMsTime + 1000
      end
      if _G.RocoEnv.IS_SHIPPING then
        local LogLevel = Log.GetLogLevel()
        if LogLevel <= Log.LOG_LEVEL.ELogWarn then
          local ShippingMapName = bIsSelf and "Self" or "HomeOwner"
          local ShippingErrorMsg = string.format("[PlayerDataModel] %s StoryFlag\230\149\176\233\135\143\228\184\141\228\184\128\232\135\180! MapCount=%d, ListCount=%d", ShippingMapName, MapCount, ListCount)
          Log.Warning(ShippingErrorMsg)
        end
      else
        local MapName = bIsSelf and "Self" or "HomeOwner"
        local ErrorMsg = string.format("[PlayerDataModel] %s StoryFlag\230\149\176\233\135\143\228\184\141\228\184\128\232\135\180! MapCount=%d, ListCount=%d", MapName, MapCount, ListCount)
        Log.Error(ErrorMsg)
        local Ctx = _G.DialogContext()
        Ctx:SetTitle("\233\157\158Shipping\231\137\136\230\156\172\228\184\147\229\177\158\228\184\165\233\135\141\233\148\153\232\175\175\230\143\144\231\164\186")
        Ctx:SetContent(ErrorMsg .. "\n\232\175\183\229\176\134\230\173\164\230\136\170\229\155\190\229\143\145\231\187\153\229\174\162\230\136\183\231\171\175\229\188\128\229\143\145\230\142\146\230\159\165\239\188\140\229\185\182\230\143\144\228\190\155\229\174\162\230\136\183\231\171\175\230\151\165\229\191\151\239\188\140\232\176\162\232\176\162\239\188\129")
        Ctx:SetMode(_G.DialogContext.Mode.OK)
        Ctx:SetButtonText("\229\129\156\230\173\162\230\184\184\230\136\143", "\229\129\156\230\173\162\230\184\184\230\136\143")
        Ctx:SetCallback(nil, function()
          UE.UNRCStatics.QuitGame()
        end)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
      end
    end
    return false
  end
  return true
end

function PlayerDataModel:HasStoryFlag(Flag)
  if not Flag then
    return false
  end
  if self:IsUseSelfStoryFlag(Flag) then
    if self:CheckStoryFlagsMapConsistency(true) then
      return self.SelfStoryFlagsMap and self.SelfStoryFlagsMap[Flag] == true or false
    end
    local Flags = self:GetStoryFlags()
    return Flags and table.include(Flags, Flag) or false
  end
  if self:CheckStoryFlagsMapConsistency(false) then
    return self.HomeOwnerStoryFlagsMap and true == self.HomeOwnerStoryFlagsMap[Flag] or false
  end
  local Flags = self.HomeOwnerStoryFlags
  return Flags and table.include(Flags, Flag) or false
end

function PlayerDataModel:GetStoryFlags()
  local Info = self.playerInfo
  if not Info then
    return nil
  end
  if not Info.story_flag_info then
    Info.story_flag_info = ProtoMessage:newPlayerStoryFlagInfo()
  end
  return Info.story_flag_info.story_flags
end

function PlayerDataModel:InitSelfStoryFlagsMap(Flags)
  self.SelfStoryFlagsMap = {}
  self.SelfStoryFlagsMapCount = 0
  local listCount = 0
  if Flags then
    for _, Flag in ipairs(Flags) do
      self.SelfStoryFlagsMap[Flag] = true
      self.SelfStoryFlagsMapCount = self.SelfStoryFlagsMapCount + 1
    end
    listCount = #Flags
  end
  Log.DebugFormat("PlayerDataModel:InitSelfStoryFlagsMap initialized! MapCount=%d, ListCount=%d", self.SelfStoryFlagsMapCount, listCount)
end

function PlayerDataModel:AddToSelfStoryFlagsMap(Flag)
  if not self.SelfStoryFlagsMap then
    self.SelfStoryFlagsMap = {}
  end
  if not self.SelfStoryFlagsMap[Flag] then
    self.SelfStoryFlagsMap[Flag] = true
    self.SelfStoryFlagsMapCount = self.SelfStoryFlagsMapCount + 1
  elseif _G.RocoEnv.IS_SHIPPING then
    Log.WarningFormat("[PlayerDataModel:_AddToSelfStoryFlagsMap] \229\176\157\232\175\149\230\183\187\229\138\160\229\183\178\229\173\152\229\156\168\231\154\132Flag\229\136\176SelfStoryFlagsMap! Flag=%d", Flag)
  else
    Log.ErrorFormat("[PlayerDataModel:_AddToSelfStoryFlagsMap] \229\176\157\232\175\149\230\183\187\229\138\160\229\183\178\229\173\152\229\156\168\231\154\132Flag\229\136\176SelfStoryFlagsMap! Flag=%d", Flag)
  end
end

function PlayerDataModel:RemoveFromSelfStoryFlagsMap(Flag)
  if not self.SelfStoryFlagsMap then
    self.SelfStoryFlagsMap = {}
  end
  if self.SelfStoryFlagsMap[Flag] then
    self.SelfStoryFlagsMap[Flag] = nil
    self.SelfStoryFlagsMapCount = self.SelfStoryFlagsMapCount - 1
  elseif _G.RocoEnv.IS_SHIPPING then
    Log.WarningFormat("[PlayerDataModel:_RemoveFromSelfStoryFlagsMap] \229\176\157\232\175\149\229\136\160\233\153\164\228\184\141\229\173\152\229\156\168\231\154\132Flag\228\187\142SelfStoryFlagsMap! Flag=%d", Flag)
  else
    Log.ErrorFormat("[PlayerDataModel:_RemoveFromSelfStoryFlagsMap] \229\176\157\232\175\149\229\136\160\233\153\164\228\184\141\229\173\152\229\156\168\231\154\132Flag\228\187\142SelfStoryFlagsMap! Flag=%d", Flag)
  end
end

function PlayerDataModel:GetHomeOwnerStoryFlags()
  return self.HomeOwnerStoryFlags or {}
end

function PlayerDataModel:InitHomeOwnerStoryFlagsMap(Flags)
  self.HomeOwnerStoryFlagsMap = {}
  self.HomeOwnerStoryFlagsMapCount = 0
  if Flags then
    for _, Flag in ipairs(Flags) do
      self.HomeOwnerStoryFlagsMap[Flag] = true
      self.HomeOwnerStoryFlagsMapCount = self.HomeOwnerStoryFlagsMapCount + 1
    end
  end
  Log.DebugFormat("PlayerDataModel:InitHomeOwnerStoryFlagsMap initialized! MapCount=%d, ListCount=%d", self.HomeOwnerStoryFlagsMapCount, Flags and #Flags or 0)
end

function PlayerDataModel:ClearHomeOwnerStoryFlag()
  Log.Debug("PlayerDataModel:ClearHomeOwnerStoryFlag")
  self.HomeOwnerStoryFlags = nil
  self.HomeOwnerStoryFlagsMap = nil
  self.HomeOwnerStoryFlagsMapCount = 0
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.ON_HOME_OWNER_STORY_FLAG_CHANGED, false)
  if self:ShouldSendOutOfStuckReq() then
    self.bIsShouldSendOutOfStuckReq = true
    Log.Debug("PlayerDataModel:ClearHomeOwnerStoryFlag SendStuckReq")
  end
end

function PlayerDataModel:OutOfStuckRsp(rsp)
  Log.Debug("PlayerDataModel:OutOfStuckRsp RspReceived")
  if 0 ~= rsp.ret_info.ret_code then
    Log.Debug("PlayerDataModel:OutOfStuckRsp RspFailed", rsp.ret_info.ret_code)
    return
  end
end

function PlayerDataModel:IsInDungeon()
  return self:GetDungeonID() > 0
end

function PlayerDataModel:GetDungeonID()
  local PlayerInfo = self:GetPlayerInfo()
  if not PlayerInfo then
    return 0
  end
  local CommonInfo = PlayerInfo and PlayerInfo.common_info
  if not CommonInfo then
    return 0
  end
  local DungeonIDs = CommonInfo and CommonInfo.in_dungeon_id
  if not DungeonIDs or 0 == #DungeonIDs then
    return 0
  end
  return DungeonIDs[1]
end

function PlayerDataModel:GetRedPointInfo()
  local info = self.playerInfo
  if not info then
    return nil
  end
  if info.red_point_info == nil then
    return
  end
  if nil == info.red_point_info.group_info then
    info.red_point_info.group_info = {}
  end
  return info.red_point_info.group_info
end

function PlayerDataModel:GetIsTeamPetByGid(PetGid)
  local petTeam = self:GetPlayerBattlePetGid()
  if petTeam then
    local petInfo = PetUtils.PetTeamFindPetInfoByIndex(petTeam, PetGid)
    if petInfo then
      return true
    end
  end
  return false
end

function PlayerDataModel:GetIsMainTeamPetByGid(PetGid)
  local PetTeams = self:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  if PetTeams then
    for i, petTeam in ipairs(PetTeams.teams) do
      if petTeam then
        local petInfo = PetUtils.PetTeamFindPetInfoByIndex(petTeam, PetGid)
        if petInfo then
          return true
        end
      end
    end
  end
  return false
end

function PlayerDataModel:GetPetBondById(gid)
  local pet = self:GetPetByGid(gid)
  local pet_bond = _G.DataConfigManager:GetPetBond(pet.config.pet_bond_id)
  return pet_bond
end

function PlayerDataModel:GetInteractQuantity(player_id, gid)
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, player_id)
  local scene_pet_info = localPlayer.serverData.scene_pet_info
  if scene_pet_info then
    return 0, math.maxinteger
  end
  local pet_infos = scene_pet_info
  if pet_infos then
    for _, pet_info in ipairs(pet_infos) do
      if pet_info.gid == gid then
        return pet_info.interact_quantity or 0, pet_info.interact_quantity_threshold or 0
      end
    end
  end
  return 0, math.maxinteger
end

function PlayerDataModel:CheckNeedAlarmByGid(player_id, gid)
  do return false end
  local pet_bond = self:GetPetBondById(gid)
  local interact_quantity, interact_quantity_threshold = self:GetInteractQuantity(gid)
  local interact_percent = pet_bond.maximum_factor / 100
  local quantity_percent = interact_quantity / interact_quantity_threshold
  return interact_percent <= quantity_percent or true
end

function PlayerDataModel:SetCardBriefInfo(card_brief_info)
  self.playerInfo.brief_info.additional_data.card_brief_info = card_brief_info
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.ON_CARD_INFO_CHANGED)
end

function PlayerDataModel:GetCardBriefInfo()
  return self.playerInfo.brief_info.additional_data.card_brief_info
end

function PlayerDataModel:GetPlayerCardInfo()
  return self.playerInfo.svr_data_info.card_info
end

function PlayerDataModel:SetPlayerCardInfo(_PlayerCardInfo)
  self.playerInfo.svr_data_info.card_info = _PlayerCardInfo
end

function PlayerDataModel:SetPlayerCardFavoritePetInfo(_card_favorite_pet_info)
  if self.playerInfo.brief_info.additional_data.card_brief_info then
    self.playerInfo.brief_info.additional_data.card_brief_info.card_favorite_pet_info = _card_favorite_pet_info
  end
end

function PlayerDataModel:UpdatePlayerIAvatarData(AvatarData)
  if AvatarData.card_icon_selected then
    self.playerInfo.brief_info.additional_data.card_brief_info.card_icon_selected = AvatarData.card_icon_selected
  end
end

function PlayerDataModel:SetCardAppearanceInfo(CardAppearanceInfo)
  self.playerInfo.brief_info.additional_data.card_brief_info.card_appearance_info = CardAppearanceInfo
end

function PlayerDataModel:SetPlayerOpenid(name)
  Log.Debug("PlayerDataModel:SetPlayerOpenid", name)
  self.playerInfo.brief_info.name = name
  self.playerInfo.brief_info.home_brief_info.home_name = name
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.serverData then
    if player.serverData.brief_info and player.serverData.brief_info.home_brief_info then
      player.serverData.brief_info.home_brief_info.home_name = name
    end
    if player.serverData.home_basic_info and player.serverData.home_basic_info.my_home_info then
      player.serverData.home_basic_info.my_home_info.home_name = name
    end
  end
end

function PlayerDataModel:UpdatePlayerSkinData(AvatarData)
  if AvatarData.card_appearance_info and AvatarData.card_appearance_info.card_skin_selected then
    self.playerInfo.brief_info.additional_data.card_brief_info.card_appearance_info.card_skin_selected = AvatarData.card_appearance_info.card_skin_selected
  end
end

function PlayerDataModel:UpdatePlayerSignatureData(AvatarData)
  if AvatarData.card_signature then
    self.playerInfo.brief_info.additional_data.card_brief_info.card_signature = AvatarData.card_signature
    return self.playerInfo.brief_info.additional_data
  end
end

function PlayerDataModel:UpdatePlayerLabelData(_Data)
  if _Data then
    self.playerInfo.brief_info.additional_data.card_brief_info.card_label_first_selected = _Data.card_label_first_selected
    self.playerInfo.brief_info.additional_data.card_brief_info.card_label_last_selected = _Data.card_label_last_selected
    return self.playerInfo.brief_info.additional_data
  end
end

function PlayerDataModel:GetWorldMapActorInfo()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local worldMapInfo = player.serverData.world_map_info
    return worldMapInfo
  end
end

function PlayerDataModel:GetMagicCreateNpcInfo()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local magicCreateNpcInfo = player.serverData.magic_create_npc_info or {}
  return magicCreateNpcInfo
end

function PlayerDataModel:UpdateNewUnlockMapInfo(unLockId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("PlayerDataModel:UpdateNewUnlockMapInfo player is not available")
    return
  end
  local unLockList = player.serverData.world_map_info.unlocked_world_map_block_cfg_ids
  local hasId = false
  if unLockList and #unLockList > 0 then
    for k, val in ipairs(unLockList) do
      if val == unLockId then
        hasId = true
        break
      end
    end
  end
  if not hasId then
    table.insert(unLockList, unLockId)
  end
end

function PlayerDataModel:UpdateWorldMapActorInfo(entryInfo, IsDel)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("PlayerDataModel:UpdateWorldMapActorInfo player is not available")
    return
  end
  local playerMapEntryInfos = player.serverData.world_map_info.entries.entry_infos
  local bHasEntryId = false
  local Pos = 1
  if nil == playerMapEntryInfos then
    Log.Debug("\229\156\176\229\155\190\230\149\176\230\141\174\228\184\186\231\169\186")
    return
  end
  if #playerMapEntryInfos > 0 then
    for i = 1, #playerMapEntryInfos do
      if playerMapEntryInfos[i].entry_id == entryInfo.entry_id then
        playerMapEntryInfos[i] = entryInfo
        bHasEntryId = true
        Pos = i
        break
      end
    end
  end
  if false == bHasEntryId then
    table.insert(playerMapEntryInfos, entryInfo)
  elseif IsDel then
    table.remove(playerMapEntryInfos, Pos)
  end
end

function PlayerDataModel:UpdateMagicCreateNpcInfo(npcInfo, bDel)
  if not npcInfo then
    Log.Error("PlayerDataModel:UpdateWorldMapActorInfo npcInfo is not available")
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("PlayerDataModel:UpdateWorldMapActorInfo player is not available")
    return
  end
  if not player.serverData.magic_create_npc_info then
    player.serverData.magic_create_npc_info = ProtoMessage:newActorInfo_MagicCreateNpc()
  end
  local magicCreateNpcInfos = player.serverData.magic_create_npc_info or {}
  local bHasEntryId = false
  local Pos = 1
  if magicCreateNpcInfos.magic_create_npcs and #magicCreateNpcInfos.magic_create_npcs > 0 then
    for i = 1, #magicCreateNpcInfos.magic_create_npcs do
      if magicCreateNpcInfos.magic_create_npcs[i].npc_obj_id == npcInfo.npc_obj_id then
        magicCreateNpcInfos.magic_create_npcs[i] = npcInfo
        bHasEntryId = true
        Pos = i
        break
      end
    end
  end
  if false == bHasEntryId then
    if not bDel then
      if magicCreateNpcInfos.magic_create_npcs == nil then
        magicCreateNpcInfos.magic_create_npcs = {}
      end
      table.insert(magicCreateNpcInfos.magic_create_npcs, npcInfo)
    end
  elseif bDel then
    table.remove(magicCreateNpcInfos.magic_create_npcs, Pos)
  end
end

PlayerDataModel.cachedOwlSanctuaryInfo = nil
PlayerDataModel.owlSanctuaryInfoDirty = true

function PlayerDataModel:InvalidateOwlSanctuaryInfoCache()
  self.owlSanctuaryInfoDirty = true
  self.cachedOwlSanctuaryInfo = nil
end

function PlayerDataModel:RebuildOwlSanctuaryInfoCache()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return nil
  end
  local owlSanctuaryNpcInfo = player.serverData.uin_owl_sanctuary_info
  if nil == owlSanctuaryNpcInfo or nil == owlSanctuaryNpcInfo[1] or nil == owlSanctuaryNpcInfo[1].owl_sanctuarys then
    local info = ProtoMessage:newActorInfo_AOwlSanctuary()
    info.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local info_table = {}
    table.insert(info_table, info)
    self.cachedOwlSanctuaryInfo = info_table
    self.owlSanctuaryInfoDirty = false
    return self.cachedOwlSanctuaryInfo
  end
  local convertedInfo = {}
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myInfo = ProtoMessage:newActorInfo_AOwlSanctuary()
  myInfo.uin = myUin
  myInfo.owl_sanctuarys = {}
  local visitorInfoMap = {}
  for _, owlSanctuary in ipairs(owlSanctuaryNpcInfo[1].owl_sanctuarys) do
    if owlSanctuary.fruit_info then
      if owlSanctuary.fruit_info.fruit_data and #owlSanctuary.fruit_info.fruit_data > 0 then
        local myOwlSanctuaryInfo = ProtoMessage:newAvatarOwlSanctuaryInfo()
        myOwlSanctuaryInfo.npc_content_id = owlSanctuary.npc_content_id
        myOwlSanctuaryInfo.is_upgrade = owlSanctuary.is_upgrade
        local npc_pos = {
          x = 0,
          y = 0,
          z = 0
        }
        local npc_pos_Param_Conf = _G.DataConfigManager:GetNpcRefreshContentConf(owlSanctuary.npc_content_id)
        if npc_pos_Param_Conf and npc_pos_Param_Conf.refresh_param then
          local RefreshType = npc_pos_Param_Conf.refresh_type
          local ObjectConf
          if RefreshType == _G.Enum.RefreshType.RFT_AREA then
            ObjectConf = _G.DataConfigManager:GetAreaConf(npc_pos_Param_Conf.refresh_param)
            if ObjectConf and ObjectConf.pos and ObjectConf.pos[1] then
              local pos = ObjectConf.pos[1].position_xyz
              if pos then
                npc_pos.x = pos[1]
                npc_pos.y = pos[2]
                npc_pos.z = pos[3]
              end
            end
          elseif RefreshType == _G.Enum.RefreshType.RFT_BYTAGID then
            ObjectConf = _G.DataConfigManager:GetSceneObjectConf(npc_pos_Param_Conf.refresh_param)
            if ObjectConf then
              local pos = ObjectConf.position_xyz
              if pos then
                npc_pos.x = pos[1]
                npc_pos.y = pos[2]
                npc_pos.z = pos[3]
              end
            end
          end
        end
        if owlSanctuary.detect_info and next(owlSanctuary.detect_info) then
          myOwlSanctuaryInfo.is_detected = owlSanctuary.detect_info.is_detected
        else
          myOwlSanctuaryInfo.is_detected = false
        end
        myOwlSanctuaryInfo.npc_pos = npc_pos
        myOwlSanctuaryInfo.fruit_brief_infos = {}
        for key, fruitData in ipairs(owlSanctuary.fruit_info.fruit_data) do
          local briefInfo = ProtoMessage:newOwlSanctuaryFruitBriefInfo()
          briefInfo.fruit_id = fruitData.fruit_id or 0
          briefInfo.npc_id = fruitData.npc_ids or {}
          briefInfo.fruit_active_timestamp = fruitData.fruit_active_timestamp
          briefInfo.slot_active_timestamp = fruitData.slot_active_timestamp
          briefInfo.fruit_gid = fruitData.fruit_gid
          briefInfo.is_active = fruitData.is_active
          myOwlSanctuaryInfo.fruit_brief_infos[key] = briefInfo
        end
        table.insert(myInfo.owl_sanctuarys, myOwlSanctuaryInfo)
      end
      if owlSanctuary.fruit_info.visitor_fruit_data then
        for _, visitorData in ipairs(owlSanctuary.fruit_info.visitor_fruit_data) do
          local visitorUin = visitorData.uin
          if visitorUin and visitorData.fruit_data and #visitorData.fruit_data > 0 then
            if not visitorInfoMap[visitorUin] then
              local visitorInfo = ProtoMessage:newActorInfo_AOwlSanctuary()
              visitorInfo.uin = visitorUin
              visitorInfo.owl_sanctuarys = {}
              visitorInfoMap[visitorUin] = visitorInfo
            end
            local visitorOwlSanctuaryInfo = ProtoMessage:newAvatarOwlSanctuaryInfo()
            visitorOwlSanctuaryInfo.npc_content_id = owlSanctuary.npc_content_id
            visitorOwlSanctuaryInfo.is_upgrade = owlSanctuary.is_upgrade
            local npc_pos = {
              x = 0,
              y = 0,
              z = 0
            }
            local npc_pos_Param_Conf = _G.DataConfigManager:GetNpcRefreshContentConf(owlSanctuary.npc_content_id)
            if npc_pos_Param_Conf and npc_pos_Param_Conf.refresh_param then
              local ObjectConf
              if npc_pos_Param_Conf.refresh_type == _G.Enum.RefreshType.RFT_AREA then
                ObjectConf = _G.DataConfigManager:GetAreaConf(npc_pos_Param_Conf.refresh_param)
                if ObjectConf and ObjectConf.pos and ObjectConf.pos[1] then
                  local pos = ObjectConf.pos[1].position_xyz
                  if pos then
                    npc_pos.x = pos[1]
                    npc_pos.y = pos[2]
                    npc_pos.z = pos[3]
                  end
                end
              elseif npc_pos_Param_Conf.refresh_type == _G.Enum.RefreshType.RFT_BYTAGID then
                ObjectConf = _G.DataConfigManager:GetSceneObjectConf(npc_pos_Param_Conf.refresh_param)
                if ObjectConf and ObjectConf.position_xyz then
                  npc_pos.x = ObjectConf.position_xyz[1]
                  npc_pos.y = ObjectConf.position_xyz[2]
                  npc_pos.z = ObjectConf.position_xyz[3]
                end
              end
            end
            if owlSanctuary.detect_info and next(owlSanctuary.detect_info) and owlSanctuary.detect_info.visitor_detect_info and next(owlSanctuary.detect_info.visitor_detect_info) then
              local VisDetInfo = owlSanctuary.detect_info.visitor_detect_info
              local flag = true
              for _, visitorDetectInfo in ipairs(VisDetInfo) do
                if visitorDetectInfo.uin == visitorUin then
                  visitorOwlSanctuaryInfo.is_detected = visitorDetectInfo.is_detected
                  flag = false
                  break
                end
              end
              if flag then
                visitorOwlSanctuaryInfo.is_detected = false
              end
            end
            visitorOwlSanctuaryInfo.npc_pos = npc_pos
            visitorOwlSanctuaryInfo.fruit_brief_infos = {}
            for key, fruitData in ipairs(visitorData.fruit_data) do
              local briefInfo = ProtoMessage:newOwlSanctuaryFruitBriefInfo()
              briefInfo.fruit_id = fruitData.fruit_id or 0
              briefInfo.npc_id = fruitData.npc_ids or {}
              briefInfo.fruit_active_timestamp = fruitData.fruit_active_timestamp
              briefInfo.slot_active_timestamp = fruitData.slot_active_timestamp
              briefInfo.fruit_gid = fruitData.fruit_gid
              briefInfo.is_active = fruitData.is_active
              visitorOwlSanctuaryInfo.fruit_brief_infos[key] = briefInfo
            end
            table.insert(visitorInfoMap[visitorUin].owl_sanctuarys, visitorOwlSanctuaryInfo)
          end
        end
      end
    end
  end
  table.insert(convertedInfo, myInfo)
  for _, visitorInfo in pairs(visitorInfoMap) do
    table.insert(convertedInfo, visitorInfo)
  end
  self.cachedOwlSanctuaryInfo = convertedInfo
  self.owlSanctuaryInfoDirty = false
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.RECONNECT_UPDATEOWL)
  return convertedInfo
end

function PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
  if not self.owlSanctuaryInfoDirty and self.cachedOwlSanctuaryInfo then
    for _, info in pairs(self.cachedOwlSanctuaryInfo) do
      if next(info.owl_sanctuarys) then
        return self.cachedOwlSanctuaryInfo
      end
    end
  end
  return self:RebuildOwlSanctuaryInfoCache()
end

function PlayerDataModel:GetOwlSanctuaryNpcInfo()
  local owlSanctuaryNpcInfo = self:GetAllPlayerOwlSanctuaryNpcInfo()
  if not owlSanctuaryNpcInfo or next(owlSanctuaryNpcInfo) == nil then
    return nil
  end
  for _, info in pairs(owlSanctuaryNpcInfo) do
    if info and info.uin and info.uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
      return info
    end
  end
  return nil
end

function PlayerDataModel:RefreshPetGidAndNum(gids, totalNum)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player or not player.serverData then
    return
  end
  if not player.serverData.steal_home_info then
    player.serverData.steal_home_info = ProtoMessage:newStealHomeInfo()
  end
  player.serverData.steal_home_info.total_steal_num = totalNum
  if player.serverData.steal_home_info.steal_of_home_pets then
    table.clear(player.serverData.steal_home_info.steal_of_home_pets)
  end
  if nil == gids or table.isEmpty(gids) then
    return
  end
  for _, gid in ipairs(gids) do
    local newStealPet = ProtoMessage:newStealHomePetInfo()
    newStealPet.pet_gid = gid
    if not player.serverData.steal_home_info.steal_of_home_pets then
      player.serverData.steal_home_info.steal_of_home_pets = {}
    end
    table.insert(player.serverData.steal_home_info.steal_of_home_pets, newStealPet)
  end
end

function PlayerDataModel:UpdateStealHomePetInfo(petGid)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player.serverData.steal_home_info then
    player.serverData.steal_home_info = ProtoMessage:newStealHomeInfo()
  end
  if not player.serverData.steal_home_info.steal_of_home_pets then
    player.serverData.steal_home_info.steal_of_home_pets = {}
  end
  for _, stealPet in ipairs(player.serverData.steal_home_info.steal_of_home_pets) do
    if stealPet.pet_gid == petGid then
      return
    end
  end
  local newStealPet = ProtoMessage:newStealHomePetInfo()
  newStealPet.pet_gid = petGid
  table.insert(player.serverData.steal_home_info.steal_of_home_pets, newStealPet)
end

function PlayerDataModel:UpdateOwlSanctuaryNpcInfo(newDetectedSanctuaryInfo, targetUin, targetContentId)
  if not newDetectedSanctuaryInfo then
    Log.Error("PlayerDataModel:UpdateOwlSanctuaryNpcInfo newDetectedSanctuaryInfo is not available")
    return
  end
  local uin = targetUin or self:GetPlayerUin()
  local contentId = targetContentId or newDetectedSanctuaryInfo.npc_content_id
  if not uin or not contentId then
    Log.Error("PlayerDataModel:UpdateOwlSanctuaryNpcInfo Invalid uin or contentId", uin, contentId)
    return
  end
  if not targetUin or targetUin == self:GetPlayerUin() then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not player then
      Log.Error("PlayerDataModel:UpdateOwlSanctuaryNpcInfo player is not available")
      return
    end
    local allOwlSanctuaryInfo = self:GetOwlSanctuaryNpcInfo()
    if not allOwlSanctuaryInfo or not allOwlSanctuaryInfo.owl_sanctuarys then
      return
    end
    local bNewAdd = true
    for idx, owlSanctuaryInfo in ipairs(allOwlSanctuaryInfo.owl_sanctuarys) do
      if owlSanctuaryInfo.npc_content_id == contentId then
        allOwlSanctuaryInfo.owl_sanctuarys[idx] = newDetectedSanctuaryInfo
        bNewAdd = false
        break
      end
    end
    if bNewAdd then
      table.insert(allOwlSanctuaryInfo.owl_sanctuarys, newDetectedSanctuaryInfo)
    end
  end
  if self.cachedOwlSanctuaryByContentId and self.cachedOwlSanctuaryByUin then
    self.cachedOwlSanctuaryByContentId[contentId] = self.cachedOwlSanctuaryByContentId[contentId] or {}
    self.cachedOwlSanctuaryByContentId[contentId][uin] = newDetectedSanctuaryInfo
    self.cachedOwlSanctuaryByUin[uin] = self.cachedOwlSanctuaryByUin[uin] or {}
    self.cachedOwlSanctuaryByUin[uin][contentId] = newDetectedSanctuaryInfo
  else
    self:InvalidateOwlSanctuaryInfoCache()
  end
end

function PlayerDataModel:UpdateOwlSanctuaryFruitInfo(npcContentId, newOwlSanctuaryFruitBriefInfo, targetUin, is_upgrade, DetectedInfo)
  if nil == npcContentId or nil == newOwlSanctuaryFruitBriefInfo then
    Log.Error("PlayerDataModel:UpdateOwlSanctuaryFruitInfo Invalid param", npcContentId, newOwlSanctuaryFruitBriefInfo)
    return
  end
  local uin = targetUin or self:GetPlayerUin()
  if not uin then
    Log.Error("PlayerDataModel:UpdateOwlSanctuaryFruitInfo Invalid uin")
    return
  end
  local targetAvatarOwlSanctuaryInfo
  if not targetUin or targetUin == self:GetPlayerUin() then
    local allOwlSanctuaryNpcInfo = self:GetOwlSanctuaryNpcInfo()
    if nil == allOwlSanctuaryNpcInfo or nil == allOwlSanctuaryNpcInfo.owl_sanctuarys then
      return
    end
    for idx1, owlSanctuaryNpcInfo in ipairs(allOwlSanctuaryNpcInfo.owl_sanctuarys) do
      if owlSanctuaryNpcInfo.npc_content_id == npcContentId then
        owlSanctuaryNpcInfo.is_upgrade = is_upgrade
        owlSanctuaryNpcInfo.fruit_brief_infos = newOwlSanctuaryFruitBriefInfo
        owlSanctuaryNpcInfo.is_detected = DetectedInfo.is_detected
        targetAvatarOwlSanctuaryInfo = owlSanctuaryNpcInfo
        break
      end
    end
    if nil == targetAvatarOwlSanctuaryInfo then
      local npc_pos = {
        x = 0,
        y = 0,
        z = 0
      }
      local npc_pos_Param_Conf = _G.DataConfigManager:GetNpcRefreshContentConf(npcContentId)
      if npc_pos_Param_Conf and npc_pos_Param_Conf.refresh_param then
        local ObjectConf = _G.DataConfigManager:GetSceneObjectConf(npc_pos_Param_Conf.refresh_param)
        if ObjectConf and ObjectConf.position_xyz then
          npc_pos.x = ObjectConf.position_xyz[1]
          npc_pos.y = ObjectConf.position_xyz[2]
          npc_pos.z = ObjectConf.position_xyz[3]
        end
      end
      targetAvatarOwlSanctuaryInfo = {
        npc_content_id = npcContentId,
        is_upgrade = is_upgrade,
        fruit_brief_infos = newOwlSanctuaryFruitBriefInfo,
        npc_pos = npc_pos,
        is_detected = DetectedInfo.is_detected
      }
      table.insert(allOwlSanctuaryNpcInfo.owl_sanctuarys, targetAvatarOwlSanctuaryInfo)
      return targetAvatarOwlSanctuaryInfo
    end
    targetAvatarOwlSanctuaryInfo.is_upgrade = is_upgrade
    targetAvatarOwlSanctuaryInfo.fruit_brief_infos = newOwlSanctuaryFruitBriefInfo
    targetAvatarOwlSanctuaryInfo.is_detected = DetectedInfo.is_detected
  else
    local allOwlSanctuaryNpcInfo = self:GetAllPlayerOwlSanctuaryNpcInfo()
    if nil == allOwlSanctuaryNpcInfo or nil == next(allOwlSanctuaryNpcInfo) then
      return
    end
    for idx1, owlSanctuaryNpcInfo in ipairs(allOwlSanctuaryNpcInfo) do
      if owlSanctuaryNpcInfo and owlSanctuaryNpcInfo.uin == targetUin then
        local GetFlag = false
        for idx2, owlSanctuaryNpcInfo2 in ipairs(owlSanctuaryNpcInfo.owl_sanctuarys) do
          if owlSanctuaryNpcInfo2.npc_content_id == npcContentId then
            owlSanctuaryNpcInfo2.is_upgrade = is_upgrade
            owlSanctuaryNpcInfo2.fruit_brief_infos = newOwlSanctuaryFruitBriefInfo
            owlSanctuaryNpcInfo2.is_detected = DetectedInfo.is_detected
            targetAvatarOwlSanctuaryInfo = owlSanctuaryNpcInfo2
            GetFlag = true
            break
          end
        end
        if not GetFlag then
          local owlSanctuaryNpcInfo2 = {
            npc_content_id = npcContentId,
            is_upgrade = is_upgrade,
            fruit_brief_infos = newOwlSanctuaryFruitBriefInfo,
            is_detected = DetectedInfo.is_detected
          }
          targetAvatarOwlSanctuaryInfo = owlSanctuaryNpcInfo2
          table.insert(owlSanctuaryNpcInfo.owl_sanctuarys, owlSanctuaryNpcInfo2)
        end
      end
    end
    if nil == targetAvatarOwlSanctuaryInfo then
      targetAvatarOwlSanctuaryInfo = {
        npc_content_id = npcContentId,
        is_upgrade = is_upgrade,
        fruit_brief_infos = newOwlSanctuaryFruitBriefInfo,
        is_detected = DetectedInfo.is_detected
      }
      local info = ProtoMessage:newActorInfo_AOwlSanctuary()
      info.owl_sanctuarys = info.owl_sanctuarys or {}
      table.insert(info.owl_sanctuarys, targetAvatarOwlSanctuaryInfo)
      info.uin = targetUin
      table.insert(allOwlSanctuaryNpcInfo, info)
      return targetAvatarOwlSanctuaryInfo
    else
      targetAvatarOwlSanctuaryInfo.is_upgrade = is_upgrade
      targetAvatarOwlSanctuaryInfo.fruit_brief_infos = newOwlSanctuaryFruitBriefInfo
      targetAvatarOwlSanctuaryInfo.is_detected = DetectedInfo.is_detected
    end
  end
  return targetAvatarOwlSanctuaryInfo
end

function PlayerDataModel:GetMapMarkInfos()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("PlayerDataModel:UpdateWorldMapActorInfo player is not available")
    return
  end
  local playerMapEntryInfos = player.serverData.world_map_info.entries.entry_infos
  local entryInfos = {}
  for i = 1, #playerMapEntryInfos do
    if playerMapEntryInfos[i].entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.Mark then
      table.insert(entryInfos, playerMapEntryInfos[i].mark_entry_info)
    end
  end
  return entryInfos
end

function PlayerDataModel:UpdateWorldMapMarkEntryInfo(mark_entry, IsDel)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("PlayerDataModel:UpdateWorldMapActorInfo player is not available")
    return
  end
  local playerMapEntryInfos = player.serverData.world_map_info.entries.entry_infos
  local bHasEntryId = false
  local Pos = 1
  for i = 1, #playerMapEntryInfos do
    if playerMapEntryInfos[i].entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.Mark and playerMapEntryInfos[i].mark_entry_info.mark_id == mark_entry.mark_id then
      playerMapEntryInfos[i].mark_entry_info = mark_entry
      bHasEntryId = true
      Pos = i
      break
    end
  end
  if false == bHasEntryId then
    table.insert(playerMapEntryInfos, {
      entry_type = _G.ProtoEnum.WorldMapEntryType.ENUM.Mark,
      mark_entry_info = mark_entry
    })
  elseif IsDel then
    table.remove(playerMapEntryInfos, Pos)
  end
end

function PlayerDataModel:GetRolePlayList()
  if self.loginData then
    return self.loginData.player_info.misc_info.player_rp_behavior_list
  end
end

function PlayerDataModel:GetUsingRolePlayList()
  if self.loginData then
    return self.loginData.player_info.misc_info.player_rp_behavior_using_list or {}
  end
  return {}
end

function PlayerDataModel:SetUsingRolePlayList(List)
  if self.loginData then
    self.loginData.player_info.misc_info.player_rp_behavior_using_list = List or {}
  end
end

function PlayerDataModel:SetRolePlayList(_GoodsChangeItem)
  if self.loginData then
    if not self.loginData.player_info.misc_info.player_rp_behavior_list then
      self.loginData.player_info.misc_info.player_rp_behavior_list = {}
    end
    if not table.contains(self.loginData.player_info.misc_info.player_rp_behavior_list, _GoodsChangeItem.id) then
      table.insert(self.loginData.player_info.misc_info.player_rp_behavior_list, _GoodsChangeItem.id)
    end
  end
end

function PlayerDataModel:ADDPlayerMusicInfo(MusicId)
  if self.playerInfo.music_info and self.playerInfo.music_info.music_id_list and #self.playerInfo.music_info.music_id_list then
    local musicList = self.playerInfo.music_info.music_id_list
    for i, v in pairs(musicList) do
      if v == MusicId then
        return
      end
    end
    table.insert(self.playerInfo.music_info.music_id_list, MusicId)
  else
    local music_info = {
      music_id_list = {MusicId}
    }
    self.playerInfo.music_info = music_info
  end
end

function PlayerDataModel:GetPlayerMusicInfo()
  return self.playerInfo.music_info
end

function PlayerDataModel:ShowPlayerMusicIcon()
  return self.playerInfo.music_info and self.playerInfo.music_info.music_id_list and #self.playerInfo.music_info.music_id_list > 0
end

function PlayerDataModel:ShowPlayerMusicIcon()
  return self.playerInfo.music_info and self.playerInfo.music_info.music_id_list and #self.playerInfo.music_info.music_id_list > 0
end

function PlayerDataModel:ClearPanelMusicList()
  if self.PanelMusicList and #self.PanelMusicList > 0 then
    table.clear(self.PanelMusicList)
    self.PanelMusicList = {}
    _G.NRCAudioManager:BatchSetState("UI_Music;None")
  end
end

function PlayerDataModel:GetPlayerSettingData()
  if self.loginData and self.loginData.player_info and self.loginData.player_info.brief_info and self.loginData.player_info.brief_info.additional_data then
    return self.loginData.player_info.brief_info.additional_data.setting_brief_info
  end
end

function PlayerDataModel:GetStateGroupByApplyEnum(ApplyTypeEnum, ApplyEnum)
  if self.playerInfo and self.playerInfo.music_info and self.playerInfo.music_info.apply_list then
    local ApplyId
    local ApplyListConf = _G.DataConfigManager:GetAllByName("MUSIC_APPLY_LIST_CONF")
    for i, v in pairs(ApplyListConf) do
      if v.interface_type == ApplyEnum and v.list_type == ApplyTypeEnum then
        ApplyId = v.id
        break
      end
    end
    local ApplyList = self.playerInfo.music_info.apply_list
    for i, v in pairs(ApplyList) do
      if v.apply_list_id == ApplyId then
        local musicConf = _G.DataConfigManager:GetMusicConf(v.music_id)
        if musicConf.music_type == Enum.MusicType.MT_WEBGAME then
          return "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Web;" .. musicConf.StateGroup_State
        elseif musicConf.music_type == Enum.MusicType.MT_MOBILE then
          return "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Mobile;" .. musicConf.StateGroup_State
        end
      end
    end
  end
  return nil
end

function PlayerDataModel:HasPanelMusic(ApplyEnum)
  if self.PanelMusicList and #self.PanelMusicList then
    for i, v in pairs(self.PanelMusicList) do
      if v == ApplyEnum then
        return true
      end
    end
  end
  return false
end

function PlayerDataModel:AddPanelMusic(ApplyTypeEnum, ApplyEnum)
  if self:HasPanelMusic(ApplyEnum) then
    return
  end
  table.insert(self.PanelMusicList, ApplyEnum)
  local CloseUIBgmState = true
  if self.playerInfo and self.playerInfo.music_info and self.playerInfo.music_info.apply_list then
    local ApplyId
    local ApplyListConf = _G.DataConfigManager:GetAllByName("MUSIC_APPLY_LIST_CONF")
    for i, v in pairs(ApplyListConf) do
      if v.interface_type == ApplyEnum and v.list_type == ApplyTypeEnum then
        ApplyId = v.id
        break
      end
    end
    local ApplyList = self.playerInfo.music_info.apply_list
    for i, v in pairs(ApplyList) do
      if v.apply_list_id == ApplyId then
        local musicConf = _G.DataConfigManager:GetMusicConf(v.music_id)
        if musicConf.music_type == Enum.MusicType.MT_WEBGAME or musicConf.music_type == Enum.MusicType.MT_MOBILE then
          CloseUIBgmState = false
          break
        end
      end
    end
  end
  if CloseUIBgmState then
    _G.NRCAudioManager:BatchSetState("UI_Music;None")
  end
end

function PlayerDataModel:RemovePanelMusic(ApplyTypeEnum, ApplyEnum, CustomPlayMusic)
  if self.PanelMusicList and #self.PanelMusicList > 0 then
    for j, k in pairs(self.PanelMusicList) do
      if k == ApplyEnum then
        table.remove(self.PanelMusicList, j)
        break
      end
      if j == #self.PanelMusicList then
        Log.Error("\230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\231\149\140\233\157\162\231\154\132music")
      end
    end
    if CustomPlayMusic then
      return
    end
    local StateGroup = "UI_Music;None"
    if self.PanelMusicList and #self.PanelMusicList > 0 then
      local applyType = self.PanelMusicList[#self.PanelMusicList]
      StateGroup = MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, applyType)
    end
    _G.NRCAudioManager:BatchSetState(StateGroup)
  elseif not CustomPlayMusic then
    _G.NRCAudioManager:BatchSetState("UI_Music;None")
  end
end

function PlayerDataModel:SetPlayerMusicApplyInfo(MusicApplyInfo)
  local MusicId = MusicApplyInfo.music_id
  local ApplyId = MusicApplyInfo.apply_list_id
  if ApplyId then
    local NewApplyInfo = _G.ProtoMessage:newMusicApplyInfo()
    NewApplyInfo.music_id = MusicId
    NewApplyInfo.apply_list_id = ApplyId
    local RemoveIndex
    local IsFind = false
    if self.playerInfo.music_info.apply_list then
      for k, ApplyInfo in pairs(self.playerInfo.music_info.apply_list) do
        if ApplyInfo.music_id == MusicId and ApplyId == ApplyInfo.apply_list_id then
          return
        end
        if ApplyInfo.music_id == MusicId then
          IsFind = true
        end
        if ApplyInfo.apply_list_id == ApplyId then
          RemoveIndex = k
        end
      end
    else
      self.playerInfo.music_info.apply_list = {}
    end
    if RemoveIndex then
      table.remove(self.playerInfo.music_info.apply_list, RemoveIndex)
    end
    if not IsFind then
      table.insert(self.playerInfo.music_info.apply_list, NewApplyInfo)
    else
      for k, ApplyInfo in pairs(self.playerInfo.music_info.apply_list) do
        if ApplyInfo.music_id == NewApplyInfo.music_id then
          self.playerInfo.music_info.apply_list[k] = NewApplyInfo
          break
        end
      end
    end
  elseif self.playerInfo.music_info.apply_list then
    local RemoveIndex
    for k, ApplyInfo in pairs(self.playerInfo.music_info.apply_list) do
      if ApplyInfo.music_id == MusicId then
        RemoveIndex = k
      end
    end
    if RemoveIndex then
      table.remove(self.playerInfo.music_info.apply_list, RemoveIndex)
    end
  end
end

function PlayerDataModel:OnZoneGoodsRewardNotify(notify)
  local goods_reward = notify.ret_info and notify.ret_info.goods_reward
  local RewardList = goods_reward and goods_reward.rewards or {}
  Log.DebugFormat("PlayerDataModel:OnZoneGoodsRewardNotify")
  Log.Dump(notify, 6, "OnZoneGoodsRewardNotify:")
  local firstRewards = {}
  local secondRewards = {}
  local leaderFightExtraRewards = {}
  local ActivityDropReward = {}
  local LeaderEvoItemRewards = {}
  local Items = {}
  for i, reward in ipairs(RewardList) do
    if 0 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_AWARD_USE_STAR then
      local IsLeaderEvoItem = false
      if reward.id and reward.type == _G.Enum.GoodsType.GT_BAGITEM then
        local BagItemConf = _G.DataConfigManager:GetBagItemConf(reward.id)
        if BagItemConf then
          IsLeaderEvoItem = BagItemConf.type == _G.Enum.BagItemType.BI_BOSS_EVO
        end
      end
      if IsLeaderEvoItem then
        table.insert(LeaderEvoItemRewards, reward)
      else
        table.insert(firstRewards, reward)
      end
    elseif 6 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_AWARD_USE_STAR then
      table.insert(secondRewards, reward)
    elseif 0 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_LEADER_FIGHT_EXTRA_REWARD then
      table.insert(leaderFightExtraRewards, reward)
    elseif reward.tag == Enum.RewardTag.RTA_ACTIVITY and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_ACTIVITY_DROP then
      table.insert(ActivityDropReward, reward)
    end
  end
  if notify.flow_reason == ProtoEnum.FlowReason.FLOW_REASON_PET_HOME_LAY then
    local goods_change_info = notify.ret_info and notify.ret_info.goods_change_info
    local changes = goods_change_info and goods_change_info.changes
    if changes then
      for _, change in pairs(changes) do
        local reward = change
        reward.itemId = reward.gid
        table.insert(firstRewards, reward)
      end
    end
  end
  
  local function Sorter(a, b)
    if a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
      local vItemConfA = _G.DataConfigManager:GetVisualItemConf(a.id)
      local vItemConfB = _G.DataConfigManager:GetVisualItemConf(b.id)
      return vItemConfA.sort_id < vItemConfB.sort_id
    elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
      local BagItemConfA = _G.DataConfigManager:GetBagItemConf(a.id)
      local BagItemConfB = _G.DataConfigManager:GetBagItemConf(b.id)
      return BagItemConfA.sort_id < BagItemConfB.sort_id
    elseif a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
      return true
    elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
      return false
    else
      return a.id < b.id
    end
  end
  
  table.sort(firstRewards, Sorter)
  table.sort(leaderFightExtraRewards, Sorter)
  table.sort(secondRewards, Sorter)
  table.move(LeaderEvoItemRewards, 1, #LeaderEvoItemRewards, #Items + 1, Items)
  table.move(ActivityDropReward, 1, #ActivityDropReward, #Items + 1, Items)
  table.move(firstRewards, 1, #firstRewards, #Items + 1, Items)
  table.move(leaderFightExtraRewards, 1, #leaderFightExtraRewards, #Items + 1, Items)
  table.move(secondRewards, 1, #secondRewards, #Items + 1, Items)
  if #Items > #ActivityDropReward then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, Items, LuaText.emailmodule_1, nil, true, nil, true)
  end
end

function PlayerDataModel:OnVisitRemainCatchTimesNotify(notify)
  if self.playerInfo and self.playerInfo.pet_info then
    if notify.is_glass then
      self.playerInfo.pet_info.visit_remain_shiny_catch_times = notify.remain_times
    else
      self.playerInfo.pet_info.visit_remain_catch_times = 1
    end
    if self.delayRefreshUIHandle then
      _G.DelayManager:CancelDelayById(self.delayRefreshUIHandle)
      self.delayRefreshUIHandle = nil
    end
    self.delayRefreshUIHandle = DelayManager:DelaySeconds(2, function()
      self.delayRefreshUIHandle = nil
      _G.BattleEventCenter:Dispatch(BattleEvent.RefreshVisitCatch)
    end)
  end
end

function PlayerDataModel:OnPVPHistoryDataNotify(Notify)
  if Notify then
    self:SetPVPStats(Notify.pvp_his_cli)
  end
end

function PlayerDataModel:SetPVPStats(NewStats)
  self.playerInfo.pvp_his_cli = NewStats
end

function PlayerDataModel:GetPVPStats()
  return self.playerInfo.pvp_his_cli
end

function PlayerDataModel:GetPetDataListByPetBaseId(baseId)
  local pet_data = self.petBaseIdMap[baseId]
  if not pet_data then
    return {}
  end
  if pet_data.gid then
    return {pet_data}
  elseif pet_data[1] then
    return pet_data
  else
    return {}
  end
end

function PlayerDataModel:RemoveFromPetBaseIdMap(pet)
  if not pet.base_conf_id or not self.petBaseIdMap[pet.base_conf_id] then
    return
  end
  local base_data = self.petBaseIdMap[pet.base_conf_id]
  if nil == base_data then
    return
  end
  if base_data.gid then
    if base_data.gid == pet.gid then
      self.petBaseIdMap[pet.base_conf_id] = nil
    end
  else
    for i = #base_data, 1, -1 do
      if base_data[i].gid == pet.gid then
        table.remove(base_data, i)
      end
    end
    if 0 == #base_data then
      self.petBaseIdMap[pet.base_conf_id] = nil
    elseif 1 == #base_data then
      self.petBaseIdMap[pet.base_conf_id] = base_data[1]
    end
  end
end

function PlayerDataModel:AddOrUpdatePetBaseIdMap(petData)
  if not petData.base_conf_id then
    return
  end
  if not petData.gid then
    Log.Error("PlayerDataModel:AddOrUpdatePetBaseIdMap - pet must have gid, base_conf_id=" .. tostring(petData.base_conf_id))
    return
  end
  local existing = self.petBaseIdMap[petData.base_conf_id]
  if not existing then
    self.petBaseIdMap[petData.base_conf_id] = petData
  elseif existing.gid then
    if existing.gid == petData.gid then
      self.petBaseIdMap[petData.base_conf_id] = petData
    else
      self.petBaseIdMap[petData.base_conf_id] = {existing, petData}
    end
  else
    local found = false
    for i, existing_pet in ipairs(existing) do
      if existing_pet.gid == petData.gid then
        existing[i] = petData
        found = true
        break
      end
    end
    if not found then
      table.insert(existing, petData)
    end
  end
end

function PlayerDataModel:UpdatePetIndexMaps(pet, is_remove)
  if not pet then
    return
  end
  if is_remove then
    if pet.gid then
      self.petGidMap[pet.gid] = nil
    end
    self:RemoveFromPetBaseIdMap(pet)
  else
    if pet.gid then
      self.petGidMap[pet.gid] = pet
    end
    self:AddOrUpdatePetBaseIdMap(pet)
  end
end

function PlayerDataModel:RebuildPetIndexMaps()
  self.petGidMap = {}
  self.petBaseIdMap = {}
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo or not petInfo.pet_data then
    return
  end
  for _, pet in ipairs(petInfo.pet_data) do
    if pet then
      self:UpdatePetIndexMaps(pet, false)
    end
  end
end

function PlayerDataModel:AddPetData(newPetData)
  if not newPetData or not newPetData.gid then
    Log.Error("PlayerDataModel:AddPetData - Invalid newPetData or missing gid")
    return false
  end
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo then
    Log.Error("PlayerDataModel:AddPetData - No petInfo")
    return false
  end
  if not petInfo.pet_data then
    petInfo.pet_data = {}
  end
  if self.petGidMap and self.petGidMap[newPetData.gid] then
    Log.Error("PlayerDataModel:AddPetData - Pet already exists, gid=" .. tostring(newPetData.gid))
    return false
  end
  table.insert(petInfo.pet_data, newPetData)
  self:UpdatePetIndexMaps(newPetData, false)
  return true
end

function PlayerDataModel:SetPetData(newPetData, petIndex)
  if not newPetData or not newPetData.gid then
    Log.Error("PlayerDataModel:SetPetData - Invalid newPetData or missing gid")
    return false
  end
  local petInfo = self:GetPlayerPetInfo()
  if not petInfo or not petInfo.pet_data then
    Log.Error("PlayerDataModel:SetPetData - No pet_data")
    return false
  end
  if petIndex then
    petInfo.pet_data[petIndex] = newPetData
    self:UpdatePetIndexMaps(newPetData, false)
    return true
  end
  for i, pet in ipairs(petInfo.pet_data) do
    if pet.gid == newPetData.gid then
      petInfo.pet_data[i] = newPetData
      self:UpdatePetIndexMaps(newPetData, false)
      return true
    end
  end
  Log.Error("PlayerDataModel:SetPetData - Pet not found, gid=" .. tostring(newPetData.gid))
  return false
end

function PlayerDataModel:OnOwlStarInfoCreate(owlStarInfo)
  Log.Info("PlayerDataModel:OnOwlStarBornPointCreate ", owlStarInfo.npc_obj_id, owlStarInfo.npc_cfg_id)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:AddOwlStarInfo(owlStarInfo)
  end
  if _G.NRCModuleManager:IsModuleActive("BigMapModule") then
    _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.OnOwlStarInfoCreate, owlStarInfo)
  end
end

function PlayerDataModel:OnOwlStarInfoDestroy(npc_obj_id, npc_cfg_id)
  Log.Info("PlayerDataModel:OnOwlStarInfoDestroy ", npc_obj_id, npc_cfg_id)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:RemoveOwlStarInfo(npc_obj_id, npc_cfg_id)
  end
  if _G.NRCModuleManager:IsModuleActive("BigMapModule") then
    _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.OnOwlStarInfoDestroy, npc_obj_id, npc_cfg_id)
  end
end

function PlayerDataModel:OnOwlStarInfoUpdateDistanceState(npc_obj_id, npc_cfg_id, in_distance_range)
  Log.Info("PlayerDataModel:OnOwlStarInfoUpdateDistanceState ", npc_obj_id, npc_cfg_id, in_distance_range)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local owlStarInfo
  if player then
    owlStarInfo = player:UpdateOwlStarDistanceState(npc_obj_id, npc_cfg_id, in_distance_range)
  end
  if _G.NRCModuleManager:IsModuleActive("BigMapModule") then
    _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.OnOwlStarInfoUpdate, owlStarInfo)
  end
end

function PlayerDataModel:GetOwlStarInfos()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    return player:GetOwlStarInfos()
  end
  return nil
end

function PlayerDataModel:OnServerCreateGP(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("PlayerDataModel:OnServerCreateGP==create gp fail!!!")
  end
end

function PlayerDataModel:OnAddOrRemoveBlackInfo(optiontype, uin, blocktime)
  if optiontype == _G.ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.ADD then
    if not self:CheckHasBlackByPlayerUin(uin) then
      local blackInfo = self:GetPlayerBlackInfo()
      blackInfo = blackInfo or {}
      if not blackInfo.black_list then
        blackInfo.black_list = {}
      end
      if blackInfo and blackInfo.black_list then
        local blockvalue = {black_uin = uin, block_time = blocktime}
        table.insert(blackInfo.black_list, blockvalue)
        if not self.playerInfo then
          self.playerInfo = {}
        end
        if not self.playerInfo.black_info then
          self.playerInfo.black_info = {}
        end
        self.playerInfo.black_info = blackInfo
      end
    else
      local blackInfo = self:GetPlayerBlackInfo()
      if blackInfo and blackInfo.black_list then
        for index, blackValue in ipairs(blackInfo.black_list) do
          if blackValue.black_uin == uin then
            blackValue.block_time = blocktime
            return
          end
        end
      end
    end
  else
    local blackInfo = self:GetPlayerBlackInfo()
    if blackInfo and blackInfo.black_list then
      for index, blackValue in ipairs(blackInfo.black_list) do
        if blackValue.black_uin == uin then
          table.remove(blackInfo.black_list, index)
          return
        end
      end
    end
  end
end

function PlayerDataModel:GetPlayerBlackInfo()
  if self.playerInfo == nil then
    Log.ErrorFormat("PlayerDataModel:GetPlayerBlackInfo playerInfo is nil ")
    return {}
  end
  local blackInfo = self.playerInfo.black_info
  if not blackInfo or type(blackInfo) ~= "table" then
    Log.ErrorFormat("PlayerDataModel:GetPlayerBlackInfo blackInfo is nil or not a table")
    return {}
  end
  return self.playerInfo.black_info
end

function PlayerDataModel:CheckHasBlackByPlayerUin(blackUin)
  local blackInfo = self:GetPlayerBlackInfo()
  if blackInfo and blackInfo.black_list then
    for _, blackValue in ipairs(blackInfo.black_list) do
      if blackValue.black_uin == blackUin then
        return true
      end
    end
  end
  return false
end

function PlayerDataModel:OnZoneClientWaterMarkChangeNotify(notify)
  if self.playerInfo then
    self.playerInfo.client_water_mark_info = notify.client_water_mark_info
  end
  local UpdateUIModule = _G.NRCModuleManager:GetModule("UpdateUIModule")
  if UpdateUIModule then
    UpdateUIModule:UpdateWaterMark(notify)
  end
end

function PlayerDataModel:OnZoneSceneSysFuncBannedNotify(notify)
  if notify.ban_info then
    if notify.ban_info.func_id and notify.ban_info.func_id == Enum.FunctionEntrance.FE_CHARGE then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.CloseMainPanel)
    elseif notify.ban_info.func_id and notify.ban_info.func_id == Enum.FunctionEntrance.FE_MAIL then
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.CloseMainPanel)
    end
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = notify.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", notify.ban_info.ban_time)
    local reasonStr = notify.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    dialogContext.panelName = "UMG_Dialog_IdIp"
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function PlayerDataModel:OnZoneChatEmojiItemChangeNotify(notify)
  if self.playerInfo.emoji_bag_info and self.playerInfo.emoji_bag_info.emoji_list then
  else
    self.playerInfo.emoji_bag_info = {}
    self.playerInfo.emoji_bag_info.emoji_list = {}
  end
  local change_list = notify.emoji_item_change_list or {}
  for i, v in ipairs(change_list) do
    if v.op_type == ProtoEnum.OpType.OT_ADD then
      table.insert(self.playerInfo.emoji_bag_info.emoji_list, v.emoji_item)
    end
    if v.op_type == ProtoEnum.OpType.OT_SET then
      for index, item in ipairs(self.playerInfo.emoji_bag_info.emoji_list) do
        if item.emoji_id == v.emoji_item.emoji_id then
          self.playerInfo.emoji_bag_info.emoji_list[index] = v.emoji_item
          break
        end
      end
    end
    if v.op_type == ProtoEnum.OpType.OT_SUB then
      for index, item in ipairs(self.playerInfo.emoji_bag_info.emoji_list) do
        if item.emoji_id == v.emoji_item.emoji_id then
          table.removeKey(self.playerInfo.emoji_bag_info.emoji_list, index)
          break
        end
      end
    end
  end
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_EMODATA)
end

function PlayerDataModel:OnUpdatePrivilegeInfoNotify(notify)
  Log.Debug("PlayerModule:OnUpdatePrivilegeInfoNotify", notify.start_up_privilege_info_cli)
  self.privilegeInfo = {}
  if notify.start_up_privilege_info_cli then
    self:SetPlayerPrivilegeInfo(notify.start_up_privilege_info_cli)
  else
    self.privilegeInfo.cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.PLAYER_PRIVILEGE_STATE)
  end
end

function PlayerDataModel:SetPlayerPrivilegeInfo(PlayerPrivilegeInfo)
  self.privilegeInfo = PlayerPrivilegeInfo
  local IsHavePrivilege = false
  if self.privilegeInfo.cli_startup_channel and self.privilegeInfo.cli_startup_channel ~= Enum.CliStartUpChannel.CSUC_NONE then
    local svrTimeStamp = ActivityUtils.GetSvrTimestamp()
    if self.privilegeInfo.cli_startup_day and svrTimeStamp >= self.privilegeInfo.cli_startup_day and svrTimeStamp - self.privilegeInfo.cli_startup_day < 86400 then
      if not self.privilegeInfo.is_first_startup or self.privilegeInfo.is_first_startup > 0 then
      end
      IsHavePrivilege = true
    else
      IsHavePrivilege = false
    end
  else
    IsHavePrivilege = false
  end
  if not IsHavePrivilege then
    self.privilegeInfo.cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
  end
  self:SendEvent(ENUM_PLAYER_DATA_EVENT.PLAYER_PRIVILEGE_STATE)
end

function PlayerDataModel:GetPlayerPrivilege()
  if self.privilegeInfo then
    if self.privilegeInfo.cli_startup_channel and self.privilegeInfo.cli_startup_channel ~= Enum.CliStartUpChannel.CSUC_NONE then
      local svrTimeStamp = ActivityUtils.GetSvrTimestamp()
      if self.privilegeInfo.cli_startup_day and svrTimeStamp >= self.privilegeInfo.cli_startup_day and svrTimeStamp - self.privilegeInfo.cli_startup_day <= 86400 then
        return true
      else
        self.privilegeInfo.cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
        self:SendEvent(ENUM_PLAYER_DATA_EVENT.PLAYER_PRIVILEGE_STATE)
      end
    end
  else
    self.privilegeInfo = {}
    self.privilegeInfo.cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
  end
  return false
end

function PlayerDataModel:GetPlayerPrivilegeData()
  return self.privilegeInfo
end

function PlayerDataModel:GetPetWarehouseBoxInfos()
  if self.playerInfo and self.playerInfo.pet_info.backpack_info then
    return self.playerInfo.pet_info.backpack_info.boxes
  end
  return {}
end

function PlayerDataModel:CreateTestDatas()
  if self.playerInfo and self.playerInfo.pet_info.backpack_info then
    if not self.playerInfo.pet_info.backpack_info.boxes then
      self.playerInfo.pet_info.backpack_info.boxes = {}
      self.playerInfo.pet_info.backpack_info.last_open_box_id = 1
    end
    local cfgs = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetAllWarehousConfigs)
    for i = 1, 15 do
      local cfg = cfgs[i]
      if cfg then
        local petbox = {
          box_id = cfg.id,
          pos = i,
          mark_type = i % 5,
          pet_gid = 0 == i % 2 and self.playerInfo.pet_info.backpack_info.pet_gid or {},
          vacancy_num = 5
        }
        table.insert(self.playerInfo.pet_info.backpack_info.boxes, petbox)
        table.sort(self.playerInfo.pet_info.backpack_info.boxes, function(a, b)
          return a.box_id < b.box_id
        end)
      end
    end
    return self.playerInfo.pet_info.backpack_info.boxes
  end
  return {}
end

function PlayerDataModel:GetPetWarehouseBoxPetDatas(box_id)
  local backpackPets = {}
  if not (self.playerInfo.pet_info and self.playerInfo.pet_info.backpack_info) or not self.playerInfo.pet_info.backpack_info.boxes then
    return backpackPets
  end
  for _, boxInfo in ipairs(self.playerInfo.pet_info.backpack_info.boxes) do
    if box_id == boxInfo.box_id then
      for i = 1, #boxInfo.pet_gid do
        local gid = boxInfo.pet_gid[i]
        if 0 == gid then
          table.insert(backpackPets, {})
        else
          table.insert(backpackPets, self:GetPetDataByGid(gid))
        end
      end
    end
  end
  return backpackPets
end

function PlayerDataModel:OnUpdatePetWarehouseBoxInfo(box_info)
  if not self.playerInfo or not self.playerInfo.pet_info then
    return
  end
  if not self.playerInfo.pet_info.backpack_info then
    self.playerInfo.pet_info.backpack_info = {}
  end
  if not self.playerInfo.pet_info.backpack_info.boxes then
    self.playerInfo.pet_info.backpack_info.boxes = {}
  end
  local isHave = false
  for i, boxInfo in ipairs(self.playerInfo.pet_info.backpack_info.boxes) do
    if boxInfo.box_id == box_info.box_id then
      isHave = true
      self.playerInfo.pet_info.backpack_info.boxes[i] = box_info
      break
    end
  end
  if not isHave then
    table.insert(self.playerInfo.pet_info.backpack_info.boxes, box_info)
  end
  self.hasBoxVacancyCache = nil
end

function PlayerDataModel:OnUpdateBoxPet(petChange)
  if not petChange.is_in_team then
    local boxInfos = self:GetPetWarehouseBoxInfos()
    for _, boxInfo in pairs(boxInfos) do
      if boxInfo.box_id == petChange.id then
        local changePetIdx = petChange.pos
        if boxInfo.pet_gid and changePetIdx <= #boxInfo.pet_gid then
          boxInfo.pet_gid[changePetIdx] = petChange.pet_gid
          self.hasBoxVacancyCache = nil
        end
      end
    end
  end
end

function PlayerDataModel:HasPetVacancy()
  if self.hasBoxVacancyCache == nil then
    self.hasBoxVacancyCache = false
    if self.playerInfo and self.playerInfo.pet_info and self.playerInfo.pet_info.backpack_info and self.playerInfo.pet_info.backpack_info.boxes then
      for _, box in ipairs(self.playerInfo.pet_info.backpack_info.boxes) do
        if box.pet_gid then
          for _, gid in ipairs(box.pet_gid) do
            if 0 == gid then
              self.hasBoxVacancyCache = true
              break
            end
          end
        end
        if self.hasBoxVacancyCache then
          break
        end
      end
    end
  end
  if self.hasBoxVacancyCache then
    return true
  end
  local mainTeam = self:GetPlayerMainPetTeam()
  if mainTeam and mainTeam.pet_infos and #mainTeam.pet_infos < 6 then
    return true
  end
  return false
end

function PlayerDataModel:UpdateLastOpenBoxID(last_box_id)
  if not self.playerInfo or not self.playerInfo.pet_info then
    return
  end
  if not self.playerInfo.pet_info.backpack_info then
    self.playerInfo.pet_info.backpack_info = {}
  end
  self.playerInfo.pet_info.backpack_info.last_open_box_id = last_box_id
end

function PlayerDataModel:GetShiningOrGlassPetCount()
  if not (self.playerInfo and self.playerInfo.pet_info) or not self.playerInfo.pet_info.pet_data then
    return 0, 0
  end
  local shiningPetCount = 0
  local glassPetCount = 0
  local petDataList = self.playerInfo.pet_info.pet_data
  for _, petData in ipairs(petDataList) do
    local mutationType = petData.mutation_type
    if 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_SHINING then
      shiningPetCount = shiningPetCount + 1
    end
    if 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_GLASS then
      glassPetCount = glassPetCount + 1
    end
  end
  return shiningPetCount, glassPetCount
end

function PlayerDataModel:GetTotalExcelCount(tableId)
  local allData = _G.DataConfigManager:GetAllByTableID(tableId)
  local count = 0
  for i, fashion in pairs(allData) do
    count = count + 1
  end
  return count
end

function PlayerDataModel:GetPetMedalInfo()
  if self.playerInfo and self.playerInfo.pet_info then
    return self.playerInfo.pet_info.pet_medal_info
  end
  return nil
end

function PlayerDataModel:GetMedalTypeByPetMedal(medal)
  if not medal or not medal.conf_id then
    return nil
  end
  local petMedalInfo = self:GetPetMedalInfo()
  if not petMedalInfo or not petMedalInfo.collection then
    return nil
  end
  for _, record in pairs(petMedalInfo.collection) do
    if record and record.medal_conf_id == medal.conf_id then
      return record.medal_type
    end
  end
  local medalConf = _G.DataConfigManager:GetMedalConf(medal.conf_id)
  if medalConf then
    return medalConf.medal_type
  end
  return nil
end

function PlayerDataModel:OnMedalDataChange(item)
  if item.medal and item.medal.detail then
    local petMedalInfo = self:GetPetMedalInfo()
    if petMedalInfo then
      if not petMedalInfo.collection then
        petMedalInfo.collection = {}
      end
      local petMedalRecords = petMedalInfo.collection
      local medalDetail = item.medal.detail
      local conf_id = item.medal.conf_id
      local hash_id = item.medal.hash_id
      local targetRecord
      for _, record in pairs(petMedalRecords) do
        if record and record.medal_conf_id == conf_id then
          targetRecord = record
          break
        end
      end
      if targetRecord then
        local targetBucket
        if not targetRecord.buckets then
          targetRecord.buckets = {}
        end
        for _, bucket in pairs(targetRecord.buckets or {}) do
          if bucket.hash_id == hash_id then
            targetBucket = bucket
            break
          end
        end
        if not targetBucket then
          targetBucket = {
            hash_id = hash_id,
            detail_list = {}
          }
          table.insert(targetRecord.buckets, targetBucket)
        end
        local bFound = false
        if not targetBucket.detail_list then
          targetBucket.detail_list = {}
        end
        for i, _medalDetail in pairs(targetBucket.detail_list or {}) do
          if medalDetail.owner_id == _medalDetail.owner_id then
            bFound = true
            if item.op ~= ProtoEnum.OpType.OT_SUB then
              do
                local medalConf = _G.DataConfigManager:GetMedalConf(targetRecord.medal_conf_id)
                if medalConf and medalDetail.complete_cnt ~= _medalDetail.complete_cnt and medalDetail.complete_cnt <= medalConf.repeat_get_award[1].count then
                  local medal = self:CreateMedalData(medalDetail, targetRecord.medal_conf_id, targetRecord.medal_type)
                  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.PetMedalUpdate, medal, BagModuleEnum.AcquireType.CountChange)
                end
                targetBucket.detail_list[i] = medalDetail
              end
              break
            end
            targetBucket.detail_list[i] = nil
            break
          end
        end
        if not bFound and item.op ~= ProtoEnum.OpType.OT_SUB then
          local medal = self:CreateMedalData(medalDetail, targetRecord.medal_conf_id, targetRecord.medal_type)
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.PetMedalUpdate, medal, BagModuleEnum.AcquireType.First)
          table.insert(targetBucket.detail_list, medalDetail)
        end
      elseif item.op ~= ProtoEnum.OpType.OT_SUB then
        local medalConf = _G.DataConfigManager:GetMedalConf(conf_id)
        local medal_type = medalConf and medalConf.medal_type or 0
        local newRecord = {
          medal_conf_id = conf_id,
          medal_type = medal_type,
          buckets = {
            {
              hash_id = hash_id,
              detail_list = {medalDetail}
            }
          }
        }
        table.insert(petMedalRecords, newRecord)
        local medal = self:CreateMedalData(medalDetail, conf_id, medal_type)
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.PetMedalUpdate, medal, BagModuleEnum.AcquireType.First)
      end
    end
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetWearMedalEvent)
  end
end

function PlayerDataModel:GetMedalInfoByItem(item)
  if not (item and item.medal) or not item.medal.detail then
    return nil
  end
  local petMedalInfo = self:GetPetMedalInfo()
  if not petMedalInfo or not petMedalInfo.collection then
    return nil
  end
  local conf_id = item.medal.conf_id
  local hash_id = item.medal.hash_id
  local medalDetail = item.medal.detail
  for _, record in pairs(petMedalInfo.collection) do
    if record and record.medal_conf_id == conf_id then
      for _, bucket in pairs(record.buckets or {}) do
        if bucket and bucket.hash_id == hash_id then
          for _, detail in pairs(bucket.detail_list or {}) do
            if detail and detail.owner_id == medalDetail.owner_id then
              return false, detail.complete_cnt
            end
          end
        end
      end
    end
  end
  return true, nil
end

function PlayerDataModel:GetMedalListAndWearMedalByPetGid(gid)
  local medalList = {}
  local wearMedal
  local petMedalInfo = self:GetPetMedalInfo()
  if not petMedalInfo then
    return nil, nil
  end
  local petMedalRecords = petMedalInfo.collection
  if not petMedalRecords then
    return nil, nil
  end
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
  local petBaseConf, petEvolutionConf
  if petData and petData.base_conf_id then
    petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
    if petBaseConf and petBaseConf.pet_evolution_id and petBaseConf.pet_evolution_id[1] then
      petEvolutionConf = _G.DataConfigManager:GetPetEvolutionConf(petBaseConf.pet_evolution_id[1])
    end
  end
  for _, record in pairs(petMedalRecords) do
    if record and record.buckets then
      for _, bucket in pairs(record.buckets) do
        if bucket and bucket.detail_list then
          for _, detail in pairs(bucket.detail_list) do
            if detail.wear_pet_gid == gid and detail.is_wear then
              wearMedal = self:CreateMedalData(detail, record.medal_conf_id, record.medal_type)
            end
            local canAddToMedalList = false
            if record.medal_type == _G.Enum.MedalType.MT_IND then
              if detail.owner_id and detail.owner_id == gid then
                canAddToMedalList = true
              end
            elseif record.medal_type == _G.Enum.MedalType.MT_SPECIES then
              if detail.owner_id and petEvolutionConf and petEvolutionConf.evolution_group == detail.owner_id then
                canAddToMedalList = true
              end
            elseif record.medal_type == _G.Enum.MedalType.MT_BOND then
              local medalBondConf = _G.DataConfigManager:GetMedalBondConf(detail.owner_id)
              if petBaseConf and medalBondConf then
                for _, petBaseId in ipairs(medalBondConf.petbase_id) do
                  if petBaseId == petBaseConf.id then
                    canAddToMedalList = true
                    break
                  end
                end
              end
            end
            if canAddToMedalList then
              local medal = self:CreateMedalData(detail, record.medal_conf_id, record.medal_type)
              table.insert(medalList, medal)
            end
          end
        end
      end
    end
  end
  if #medalList > 0 then
    table.sort(medalList, function(a, b)
      if a.add_time and b.add_time and a.add_time ~= b.add_time then
        return a.add_time > b.add_time
      else
        return a.conf_id < b.conf_id
      end
    end)
    return medalList, wearMedal
  else
    return nil, wearMedal
  end
end

function PlayerDataModel:CreateMedalData(medal_detail, conf_id, medal_type)
  if medal_detail then
    local medalData = {
      conf_id = conf_id,
      medal_type = medal_type,
      owner_id = medal_detail.owner_id,
      add_time = medal_detail.add_time,
      is_wear = medal_detail.is_wear,
      complete_cnt = medal_detail.complete_cnt,
      obtain_pet_gid = medal_detail.obtain_pet_gid,
      obtain_pet_name = medal_detail.obtain_pet_name,
      wear_pet_gid = medal_detail.wear_pet_gid,
      ext_data = medal_detail.ext_data
    }
    return medalData
  end
  return nil
end

function PlayerDataModel:GetFashionBondItem(bondId)
  local bondItems
  if self.playerInfo.svr_data_info and self.playerInfo.svr_data_info.appearance_info and self.playerInfo.svr_data_info.appearance_info.fashion_bond_info then
    bondItems = self.playerInfo.svr_data_info.appearance_info.fashion_bond_info.fashion_bond_item
  end
  if bondItems and #bondItems > 0 then
    for k, v in ipairs(bondItems) do
      if v.id == bondId then
        return v
      end
    end
  end
  return nil
end

function PlayerDataModel:UpdateFashionBondColorSuitState(bondId, newState)
  local bondItems
  if self.playerInfo.svr_data_info and self.playerInfo.svr_data_info.appearance_info and self.playerInfo.svr_data_info.appearance_info.fashion_bond_info then
    bondItems = self.playerInfo.svr_data_info.appearance_info.fashion_bond_info.fashion_bond_item
  end
  if bondItems and #bondItems > 0 then
    for k, v in ipairs(bondItems) do
      if v.id == bondId then
        v.color_suit_state = newState
      end
    end
  end
end

function PlayerDataModel:GetPlayerPetTaskInfo()
  if self.playerInfo and self.playerInfo.pet_info and self.playerInfo.pet_info.pet_task_info then
    return self.playerInfo.pet_info.pet_task_info.together_task
  end
  return nil
end

function PlayerDataModel:UpdatePetStatusFlag(Gid, NewFlag)
  local CurPetData = self:GetPetDataByGid(Gid)
  local OldFlag = CurPetData and CurPetData.pet_status_flags
  if OldFlag and OldFlag ~= NewFlag then
    self.petGidMap[Gid].pet_status_flags = NewFlag
    self:SendEvent(ENUM_PLAYER_DATA_EVENT.PET_FLAG_CHANGE, self.petGidMap[Gid], OldFlag)
  end
end

return PlayerDataModel
