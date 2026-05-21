local ActivityModule = NRCModuleBase:Extend("ActivityModule")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local NpcChallengeHandler = require("NewRoco.Modules.System.Activity.ActivityObject.NpcChallengeHandler")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")

function ActivityModule:OnConstruct()
  _G.ActivityModuleCmd = reload("NewRoco.Modules.System.Activity.ActivityModuleCmd")
  self.data = self:SetData("ActivityModuleData", "NewRoco.Modules.System.Activity.ActivityModuleData")
  self.activityObjectClass = {}
  self.webViewListener = nil
  self.initSyncSvrData = false
  self.npcChallengeHandler = NpcChallengeHandler()
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_REWARD_BY_STAGE, "NewRoco.Modules.System.Activity.ActivityObject.StageActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_WEBSITE_PART, "NewRoco.Modules.System.Activity.ActivityObject.WebSiteActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_GOODS, "NewRoco.Modules.System.Activity.ActivityObject.WebSiteActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_LEGENDARY_BATTLE_EVENT, "NewRoco.Modules.System.Activity.ActivityObject.LegendaryBattleActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_LIMITED_FLOWER_SEED, "NewRoco.Modules.System.Activity.ActivityObject.LimitedFlowerSeedActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_CATCH, "NewRoco.Modules.System.Activity.ActivityObject.PetCatchActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SHINY_WEEKEND_PREVIEW, "NewRoco.Modules.System.Activity.ActivityObject.ShinyWeekendActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SHINY_WEEKEND_START, "NewRoco.Modules.System.Activity.ActivityObject.ShinyWeekendActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_TREASURE_HUNT, "NewRoco.Modules.System.Activity.ActivityObject.TreasureHuntActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SECONDARY_TAB_EVENT, "NewRoco.Modules.System.Activity.ActivityObject.CyclicalChallengeActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT, "NewRoco.Modules.System.Activity.ActivityObject.NPCChallengeEventActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT, "NewRoco.Modules.System.Activity.ActivityObject.BossChallengeEventActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_CONDITION_REWARD, "NewRoco.Modules.System.Activity.ActivityObject.ConditionRewardActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PIKA, "NewRoco.Modules.System.Activity.ActivityObject.PikaActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_UP, "NewRoco.Modules.System.Activity.ActivityObject.HatchingActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_FLOWER_APPEAR_HARD, "NewRoco.Modules.System.Activity.ActivityObject.FlowerAppearHardActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT, "NewRoco.Modules.System.Activity.ActivityObject.WeeklyChallengeEventActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_COLLECTION, "NewRoco.Modules.System.Activity.ActivityObject.PetCollectActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_COMMON_SHOW, "NewRoco.Modules.System.Activity.ActivityObject.CommonShowActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_LIMITTIME_APPEAR, "NewRoco.Modules.System.Activity.ActivityObject.LimitTimeAppearActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_INHERITANCE, "NewRoco.Modules.System.Activity.ActivityObject.PetInheritanceActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_DROP, "NewRoco.Modules.System.Activity.ActivityObject.SpecificTimeActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SHOP, "NewRoco.Modules.System.Activity.ActivityObject.ActivityShopActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_TRACK_CONDITION, "NewRoco.Modules.System.Activity.ActivityObject.TrackConditionActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_MIX, "NewRoco.Modules.System.Activity.ActivityObject.MixActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_CONDITION_GROUP_REWARD, "NewRoco.Modules.System.Activity.ActivityObject.NoviceAchievementActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PLAYER_CO_CREATION_PREVIEW, "NewRoco.Modules.System.Activity.ActivityObject.CoCreationPreviewActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PLAYER_CO_CREATION_START, "NewRoco.Modules.System.Activity.ActivityObject.CoCreationStartActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_WEEKEND_CHALLENGE, "NewRoco.Modules.System.Activity.ActivityObject.WeekendChallengeActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_PARTNER, "NewRoco.Modules.System.Activity.ActivityObject.PetPartnerInheritObject")
  self:BindActivityObject(Enum.ActivityType.ATP_INVITE_REGISTER, "NewRoco.Modules.System.Activity.ActivityObject.InviteRegisterActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SPRING_FESTIVAL, "NewRoco.Modules.System.Activity.ActivityObject.SpringFestivalActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PREHEAT, "NewRoco.Modules.System.Activity.ActivityObject.PreHeatActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_BASE_MIX, "NewRoco.Modules.System.Activity.ActivityObject.BaseMixActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_SIGN_REWARD, "NewRoco.Modules.System.Activity.ActivityObject.PeriodicLoginActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_GLOBAL_CHALLENGE, "NewRoco.Modules.System.Activity.ActivityObject.GlobalChallengeActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_TERRITORY_TRIAL, "NewRoco.Modules.System.Activity.ActivityObject.TerritoryTrialActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_CERTIFICATION, "NewRoco.Modules.System.Activity.ActivityObject.CertificationActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_RECALL_BP, "NewRoco.Modules.System.Activity.ActivityObject.RecallBPActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_RECALL_STARLIGHT, "NewRoco.Modules.System.Activity.ActivityObject.RecallStarLightActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_ACTIVITY_RECALL, "NewRoco.Modules.System.Activity.ActivityObject.RecallMainActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_PHOTO, "NewRoco.Modules.System.Activity.ActivityObject.TakePhotoPetIdentifyActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_LEGENDARY_CHALLENGE, "NewRoco.Modules.System.Activity.ActivityObject.LegendaryChallengeActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION, "NewRoco.Modules.System.Activity.ActivityObject.TakePhotoCompetitionActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PET_TRIP, "NewRoco.Modules.System.Activity.ActivityObject.PetTripActivityObject")
  self:BindActivityObject(Enum.ActivityType.ATP_PRE_DOWNLOAD, "NewRoco.Modules.System.Activity.ActivityObject.PreDownloadActivityObject")
  self:RegPanel("ActivityMainPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_ActivityMainPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In", "Out", nil, true)
  self:RegPanel("ActivityQRCode", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_QRCode", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self:RegPanel("ActivityPhotographPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Photograph", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ActivityPetCatchReward", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PetCatch_Reward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "open", "close", true)
  self:RegPanel("LimitedFlowerHandbook", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PetSurvey", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Open", "Close")
  self:RegPanel("LimitedFlowerPetSelect", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PetSelect", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ActivityLimitedFlowerHint", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Hint", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "open", "close")
  self:RegPanel("ActivityLimitedFlowerParticipation", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Participation", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("PastActivity", "/Game/NewRoco/Modules/System/Activity/Res/UMG_PastActivity", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In")
  self:RegPanel("PastActivityHearsay", "/Game/NewRoco/Modules/System/Activity/Res/UMG_PastActivity_Hearsay", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("ActivityTreasureSpot", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TreasureSpot", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("Activity_FashionMall", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_FashionMall", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ActivityElfCollectionTips", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfCollection_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ReplacePetPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_ReplacePet", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In")
  self:RegPanel("ActivityCollect", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Collect", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ActivityAbuReward", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_AbuReward", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("RecommendedTaskPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_RecommendedTask", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("CollegeCampPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_CollegeCamp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("CampExperienceCardPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_StudyAbroadExperienceCard", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "Initial_In", "Initial_Out", true)
  self:RegPanel("ThisWeekClassSchedulePanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_ThisWeekClassSchedule", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("CollegeRankingPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_CollegeRanking", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TipsCollectionAtlases", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Tips_CollectionAtlases", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("InvitationRecord", "/Game/NewRoco/Modules/System/Activity/Res/UMG_InvitationRecord", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("ActivityReview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Review", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("PeerTask", "/Game/NewRoco/Modules/System/Activity/Res/UMG_PeerTask", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PlayeSWork", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PlayeSWork", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ChallengeDifficultyPanel", "/Game/NewRoco/Modules/System/OpenairChallenge/Res/UMG_DetailsOpenairChallenge", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true, "In", "Out", true)
  self:RegPanel("CommonRewardPreview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Preheat_Reward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("CommonFashionRewardSelect", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_FashionAward_AwardSelect", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In_0", "Out_0", true)
  self:RegPanel("SelectPartnerPetPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PetPeer_Selection", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, true)
  self:RegPanel("UMG_KingCelebrationHomepage", "/Game/NewRoco/Modules/System/Activity/Res/UMG_KingCelebrationHomepage", _G.Enum.UILayerType.UI_LAYER_POPUP, nil)
  self:RegPanel("SeasonPreheating_RecordBook", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_SeasonPreheating_RecordBook", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("WeekendLoginGiftPopUp", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_WeekendLoginGiftPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", nil, true)
  self:RegPanel("SelectionOfBranchColleges", "/Game/NewRoco/Modules/System/Activity/Res/UMG_SelectionOfBranchColleges", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("OrdinaryReward", "/Game/NewRoco/Modules/System/Activity/Res/UMG_OrdinaryReward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PredestinedEvidence", "/Game/NewRoco/Modules/System/Activity/Res/UMG_PredestinedEvidence", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TerritoryTrialInformation", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TerritoryTrial_LevelInformation", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TerritoryTrialRewardPreview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TerritoryTrial_RewardPreview", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("CertificationBlessingMain", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_SeasonPetCertification_BlessingMain", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "close", true)
  self:RegPanel("BlessingPetDetailPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_SeasonPetCertification_BlessingPetDetailPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("BackflowPetSelect", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_BackflowPetSelect", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In", "Out", false)
  self:RegPanel("ContractManualShopTips", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_BackflowContractManualShopTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PikaFashionSurvey_ToPhoto", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PikaFashionSurvey_ToPhoto", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("FreeHuggersPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_FreeHuggers", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("FreeHuggersCardPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_FreeHuggers_Card", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ActivityCommonOpenTipsPanel", "", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ElfParadiseSelect", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfParadiseSelect", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ElfParadiseRewards", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfParadiseRewards", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ElfAdventure", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfAdventure", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ElfAdventureBg", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfAdventure_BG2", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("ElfAdventureTravelLog", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfAdventureTravelLog", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ElfParadiseEventReview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ElfParadiseEventReview", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ObservationNotesPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ObservationNotes", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AICoachUserProtocol", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ShiningWeekendAICoach", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ObservationNotesPhotoPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ObservationNotes_Photo", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("SurveyTasksPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_SurveyTasks", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("TakePhotoCompetition_ClaimReward", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_ClaimReward", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("TakePhotoCompetition_Vote", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_Vote", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TakePhotoCompetition_Rankings", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_Rankings", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In", "Out", true)
  self:RegPanel("TakePhotoCompetition_PreviousReview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_PreviousReview", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In", "Out", true)
  self:RegPanel("TakePhotoCompetition_RewardPreview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_RewardPreview", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TakePhotoCompetition_BigPhoto", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_BigPhoto.UMG_Activity_TakePhotoCompetition_BigPhoto", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("TakePhotoCompetition_SubmissionReward", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_TakePhotoCompetition_RaffleTicket", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ChallengeProgressRewardPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PersonalChallenge.UMG_Activity_PersonalChallenge", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "In", "Out", true)
  self:RegPanel("ObservationNotesDetailsPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_ObservationNotes_Details.UMG_Activity_ObservationNotes_Details", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PreDownloadPopupPanel", "/Game/NewRoco/Modules/System/Activity/Res/UMG_PreDownloadPopup.UMG_PreDownloadPopup", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
end

function ActivityModule:OnActive()
  self:InitActivityData()
  self:OnOpenLotteryResultPanelByLoginData()
  _G.NRCEventCenter:RegisterEvent("ActivityModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.InitActivityData)
  _G.NRCEventCenter:RegisterEvent("ActivityModule", self, _G.SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  _G.NRCEventCenter:RegisterEvent("ActivityModule", self, FunctionBanModuleEvent.OnShieldingActivitiesChange, self.SetShieldingActivities)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_INFO_RSP, self.OnZoneGetPlayerActivityInfoRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP, self.OnZoneGetPlayerActivityDataRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NEW_ACTIVITY_REWARD_NOTIFY, self.OnZonePlayerNewActivityRewardNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PLAYER_ACTIVITY_PART_REWARD_NTY, self.OnZoneAddPlayerActivityPartRewardNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ACTIVITY_DATA_CHANGE_NTY, self.OnZonePlayerActivityDataChangeNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_LOTTERY_REWARD_RESULT_NOTIFY, self.OnPlayerLotteryRewardConfirmItemNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NPC_CHALLENGE_BATTLE_CHANGE_NTY, self.OnZoneNpcChallengeBattleChangeNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NPC_LOTTERY_GOODS_REWARD_NOTIFY, self.OnZonePlayerNpcLotteryGoodsRewardNotify)
  _G.NRCEventCenter:RegisterEvent("ActivityModule", self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  _G.NRCEventCenter:RegisterEvent("ActivityModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, self, self.OnFunctionBanUpdated)
  self:RefreshPandoraActivity()
end

function ActivityModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.InitActivityData)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnShieldingActivitiesChange, self.SetShieldingActivities)
  _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_INFO_RSP, self.OnZoneGetPlayerActivityInfoRsp)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP, self.OnZoneGetPlayerActivityDataRsp)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NEW_ACTIVITY_REWARD_NOTIFY, self.OnZonePlayerNewActivityRewardNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PLAYER_ACTIVITY_PART_REWARD_NTY, self.OnZoneAddPlayerActivityPartRewardNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ACTIVITY_DATA_CHANGE_NTY, self.OnZonePlayerActivityDataChangeNty)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_LOTTERY_REWARD_RESULT_NOTIFY, self.OnPlayerLotteryRewardConfirmItemNty)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, self, self.OnFunctionBanUpdated)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function ActivityModule:OnDestruct()
end

function ActivityModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, enablePcEsc, autoSetDesiredCursor)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = enablePcEsc or false
  registerData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(registerData)
end

function ActivityModule:BindActivityObject(_type, _activityObject)
  self.activityObjectClass[_type] = _activityObject
end

function ActivityModule:InitActivityData()
  self.data:Init()
  if not self.initSyncSvrData then
    local req = _G.ProtoMessage:newZoneGetPlayerActivityInfoReq()
    self.initSyncSvrData = _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_INFO_REQ, req)
  end
end

function ActivityModule:OnLoadMapStart()
  self:ClosePanel("ActivityMainPanel")
end

function ActivityModule:OnReconnectFinish()
  local req = _G.ProtoMessage:newZoneGetPlayerActivityInfoReq()
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_INFO_REQ, req)
  local needHandlerObjects = table.copy(self.data.availableInSvrActiveActivities)
  local displayActivities = self.data:GetDisplayActivities()
  if displayActivities then
    for _, _activityInst in ipairs(displayActivities) do
      local _activityId = _activityInst:GetActivityId()
      if not needHandlerObjects[_activityId] then
        needHandlerObjects[_activityId] = _activityInst
      end
    end
  end
  for _, _activityInst in pairs(needHandlerObjects) do
    if not _activityInst:OnReconnectFinish() then
      local attachView = _activityInst:GetAttachView()
      if attachView and UE4.UObject.IsValid(attachView) then
        _activityInst:ReqGetPlayerActivityData()
      end
    end
  end
  if self:HasPanel("PreDownloadPopupPanel") then
    self:ClosePanel("PreDownloadPopupPanel")
  end
end

function ActivityModule:OnPlayerTeleportStart()
  if self:HasPanel("ActivityMainPanel") then
    self:ClosePanel("ActivityMainPanel")
  end
end

function ActivityModule:OnWebViewOptNotify(webViewRet)
  if not self.webViewListener then
    return
  end
  if webViewRet.msgType == NRCSDKManagerEnum.WebViewMsgType.CloseWebViewURL then
    self.webViewListener(webViewRet)
    self.webViewListener = nil
  end
end

function ActivityModule:OpenMainPanel(_activityType, _activityId, _openSource)
  if "nil" == _activityType then
    _activityType = nil
  end
  _activityType = tonumber(_activityType)
  _activityId = tonumber(_activityId)
  
  local function OpenFailedProcess()
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").ACTIVITY
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    if _openSource == ActivityEnum.MainPanelOpenSource.LobbyMainInner then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    end
  end
  
  if self:HasPanel("ActivityMainPanel") then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
    self:DispatchEvent(ActivityModuleEvent.OnSelectedActivityByOpenCmd)
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_ACTIVITY)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_ACTIVITY)
  if isBan or isHide then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip7)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
    end
    OpenFailedProcess()
    return
  end
  local req = _G.ProtoMessage:newZoneGetPlayerActivityInfoReq()
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_INFO_REQ, req)
  self.data:RefreshActivities()
  if _activityType or _activityId then
    local Inst = _activityId and self:GetActivityInstById(_activityId)
    if not Inst and _activityType then
      local InstList = self:GetActivityInstByType(_activityType)
      if InstList then
        Inst = InstList[1]
      end
    end
    if not Inst then
      if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip7)
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
      end
      OpenFailedProcess()
      return
    end
  end
  if self.data:HasDisplayActivities() then
    local openResult = self:OpenPanel("ActivityMainPanel", _activityType, _activityId, _openSource, _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
    if 0 ~= openResult then
      OpenFailedProcess()
    end
  else
    OpenFailedProcess()
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip7)
    end
    Log.Error("\229\189\147\229\137\141\230\178\161\230\156\137\230\180\187\229\138\168\233\161\185\231\155\174\239\188\140\230\137\147\229\188\128\229\164\177\232\180\165!")
  end
end

function ActivityModule:CloseMainPanel()
  if self:HasPanel("ActivityMainPanel") then
    self:ClosePanel("ActivityMainPanel")
  end
end

function ActivityModule:EnableMainPanel()
  local panel = self:GetPanel("ActivityMainPanel")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function ActivityModule:PreLoadMainPanel()
  self:PreLoadPanel("ActivityMainPanel", 10)
end

function ActivityModule:PreLoadDownloadActivityPanel()
  self:PreLoadPanel("PreDownloadPopupPanel")
end

function ActivityModule:SetShieldingActivities(activities)
  self.data:ShieldingActivities(activities)
end

function ActivityModule:GetLoginDays()
  local data = self.data
  return data.login_days or 0
end

function ActivityModule:GetActivityLoginDays()
  local data = self.data
  if data.login_history and data.login_history.history_data then
    return data.login_history.history_data
  end
end

function ActivityModule:OpenQCodePanel(_imagePath, _onClose, ...)
  if self:HasPanel("ActivityQRCode") then
    return
  end
  self:OpenPanel("ActivityQRCode", _imagePath, _onClose, ...)
end

function ActivityModule:OpenPhotographPanel(imagePath)
  self:OpenPanel("ActivityPhotographPanel", imagePath)
end

function ActivityModule:OpenPetCatchReward(_activityInst)
  if self:HasPanel("ActivityPetCatchReward") then
    return
  end
  self:OpenPanel("ActivityPetCatchReward", _activityInst)
end

function ActivityModule:OpenKingCelebrationHomepage(_activityInst)
  if self:HasPanel("UMG_KingCelebrationHomepage") then
    return
  end
  self:OpenPanel("UMG_KingCelebrationHomepage", _activityInst)
end

function ActivityModule:CreateActivityObject(_activityConf, _activitySource, ...)
  local classPath
  if _activityConf then
    classPath = self.activityObjectClass and self.activityObjectClass[_activityConf.activity_type]
    if string.IsNilOrEmpty(classPath) then
      classPath = "NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase"
    end
  elseif _activitySource == ActivityEnum.ActivitySource.Svr then
    classPath = "NewRoco.Modules.System.Activity.ActivityObject.UnknownActivityObject"
  elseif _activitySource == ActivityEnum.ActivitySource.Pandora then
    classPath = "NewRoco.Modules.System.Activity.ActivityObject.PandoraActivityObject"
  end
  if not string.IsNilOrEmpty(classPath) then
    local cls = require(classPath)
    local inst = cls(_activityConf, ...)
    inst:SetEventDispatcher(self.eventDispatcher)
    return inst
  end
end

function ActivityModule:GetDisplayActivities(_uniqueData)
  local displayActivities = self.data:GetDisplayActivities()
  return _uniqueData and ActivityUtils.ShallowCopyElements(displayActivities) or displayActivities
end

function ActivityModule:GetActivityInstById(_activityId, includeSvrAvailableOnly)
  return self.data:GetDisplayActivityInstById(_activityId, includeSvrAvailableOnly)
end

function ActivityModule:GetActivityInstByType(_activityType, includeSvrAvailableOnly)
  return self.data:GetDisplayActivityInstByType(_activityType, includeSvrAvailableOnly)
end

function ActivityModule:RegisterActivityUrlCloseHandle(_callback, _caller)
  self.webViewListener = _G.MakeWeakFunctor(_caller, _callback)
end

function ActivityModule:OpenLimitedFlowerSelectPet(_activityInst)
  self:OpenPanel("LimitedFlowerPetSelect", _activityInst)
end

function ActivityModule:OpenLimitedFlowerHandbook(_activityInst)
  if _activityInst or _G.GlobalConfig.DebugOpenUI then
    self:OpenPanel("LimitedFlowerHandbook", _activityInst)
  end
end

function ActivityModule:OpenActivityLimitedFlowerHint(_activityInst, FlowerSendId, _IsSelectOther)
  self:OpenPanel("ActivityLimitedFlowerHint", _activityInst, FlowerSendId, _IsSelectOther)
end

function ActivityModule:OpenActivityLimitedFlowerParticipation(_activityInst)
  self:OpenPanel("ActivityLimitedFlowerParticipation", _activityInst)
end

function ActivityModule:OpenPastActivity(_activityInst)
  if self:HasPanel("PastActivity") then
    return
  end
  self:OpenPanel("PastActivity", _activityInst)
end

function ActivityModule:OpenPastActivityHearsay(_tips)
  if self:HasPanel("PastActivityHearsay") then
    return
  end
  self:OpenPanel("PastActivityHearsay", _tips)
end

function ActivityModule:CloseActivityTreasureSpot(_tips)
  if not self:HasPanel("ActivityTreasureSpot") then
    return
  end
  self:ClosePanel("ActivityTreasureSpot", _tips)
end

function ActivityModule:OpenActivityTreasureSpot(_activityObject)
  if self:HasPanel("ActivityTreasureSpot") then
    return
  end
  self:OpenPanel("ActivityTreasureSpot", _activityObject)
end

function ActivityModule:OpenReplacePetPanel(activityInst, partId)
  if not activityInst then
    return
  end
  local petDataList = activityInst:GetInheritancePetList(partId)
  if petDataList and #petDataList > 0 then
    self:OpenPanel("ReplacePetPanel", petDataList, activityInst, partId)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.INHERITANCE_7)
  end
end

function ActivityModule:UploadLocalActivity(activitySource, activityData)
  local activityInst = self:CreateActivityObject(nil, activitySource, activityData)
  if activityInst then
    return self.data:UploadLocalActivity(activityInst)
  else
    Log.Error("ActivityModule:UploadLocalActivity: create activityInst failed.", activitySource)
  end
end

function ActivityModule:OpenRecommendTaskPanel(taskList, data)
  if not taskList or #taskList <= 0 then
    return
  end
  self:OpenPanel("RecommendedTaskPanel", taskList, data)
end

function ActivityModule:OpenCampSelectPanel(data)
  self:OpenPanel("CollegeCampPanel", data)
end

function ActivityModule:OpenThisWeekClassSchedulePanel()
  local activities = self:GetActivityInstByType(Enum.ActivityType.ATP_MIX)
  if not activities or #activities <= 0 then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Activity_CollegeGlory_disabled_tips)
    return
  end
  self:OpenPanel("ThisWeekClassSchedulePanel", activities[1], _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
end

function ActivityModule:OpenCollegeRankingPanel()
  local activities = self:GetActivityInstByType(Enum.ActivityType.ATP_MIX)
  if not activities or #activities <= 0 then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.OpenCMD_FalseTips)
    return
  end
  local activityInst = activities[1]
  activityInst:SendZoneActivityFactionRankReq()
  self:OpenPanel("CollegeRankingPanel", activityInst)
end

function ActivityModule:OpenActivityRelayPage(id)
  local relayPage = _G.DataConfigManager:GetActivityRelayPage(id, true)
  if not relayPage then
    Log.Error("[ActivityModule:OpenActivityRelayPage]: relayPage not found!", id)
    return
  end
  local svrTimestamp = ActivityUtils.GetSvrTimestamp()
  local uiData = {}
  uiData.defaultTips = relayPage.select_des
  uiData.leftBtnText = _G.LuaText.Activity_CollegeGlory_Cancel
  uiData.rightBtnText = _G.LuaText.Activity_CollegeGlory_Go
  uiData.itemData = {}
  for _, v in ipairs(relayPage.relay_part_group or {}) do
    local uiItemTimestamp = ActivityUtils.ToTimestamp(v.unlock_time)
    local uiItem = {}
    uiItem.imagePath = v.img
    uiItem.isLocked = svrTimestamp < uiItemTimestamp
    if uiItem.isLocked then
      uiItem.disableChoose = true
      local timeDetailData = ActivityUtils.ToTimeDetailData(uiItemTimestamp)
      uiItem.lockDesc = string.format(_G.LuaText.Activity_CollegeGlory_UnlockTime, timeDetailData.year, timeDetailData.month, timeDetailData.day, timeDetailData.hour, timeDetailData.minute)
    elseif v.faction_type and 0 ~= v.faction_type then
      local isFactionAvailable = false
      local MixActivities = self:GetActivityInstByType(Enum.ActivityType.ATP_MIX, true)
      for _, mixObj in ipairs(MixActivities) do
        if mixObj:GetSelectFaction() == v.faction_type or mixObj:GetFactionFinishedTimestamp(v.faction_type) then
          isFactionAvailable = true
          break
        end
      end
      if not isFactionAvailable then
        uiItem.isLocked = true
        uiItem.disableChoose = true
        uiItem.lockDesc = v.faction_unlock_tips
      end
    end
    uiItem.customData = v
    local npcChallengeObject = self.npcChallengeHandler:GetChallengeItem(v.spec_battle_ui_id)
    if npcChallengeObject and npcChallengeObject:IsAllBattleFinished() then
      uiItem.isCollected = true
    end
    if v.reward_show and 0 ~= v.reward_show then
      local rewardConf = _G.DataConfigManager:GetRewardConf(v.reward_show)
      if rewardConf then
        uiItem.rewards = {}
        for _, rewardItem in ipairs(rewardConf.RewardItem) do
          local rewardData = {}
          rewardData.itemType = rewardItem.Type
          rewardData.itemId = rewardItem.Id
          rewardData.itemNum = rewardItem.Count
          table.insert(uiItem.rewards, rewardData)
        end
      end
    end
    table.insert(uiData.itemData, uiItem)
  end
  uiData.clickOkCallback = _G.MakeWeakFunctor(nil, function(_item)
    local customData = _item and _item.customData
    if customData then
      ActivityUtils.DoActivityOptionCmd(customData.option_id)
    end
  end)
  self:OpenCampSelectPanel(uiData)
end

function ActivityModule:OpenCampExperienceCardPanel(activityId, finishFactionItems)
  if self:HasPanel("CampExperienceCardPanel") then
    return
  end
  local activityInst = activityId and self.data:GetOrCreateActivityInst(activityId)
  if activityInst then
    local factionCfg = activityInst:GetFactionConf()
    if factionCfg then
      self:OpenPanel("CampExperienceCardPanel", factionCfg, finishFactionItems)
    end
  end
end

function ActivityModule:GetNpcChallengeHandler()
  return self.npcChallengeHandler
end

function ActivityModule:OpenNpcChallengeDifficultySelectPanel(id, ...)
  local cfg = _G.DataConfigManager:GetSpecBattleUi(id, true)
  if not cfg then
    Log.Error("[ActivityModule:OpenNpcChallengeDifficultySelectPanel]: cfg not found!", id)
    return
  end
  self:OpenPanel("ChallengeDifficultyPanel", cfg, ...)
end

function ActivityModule:OpenCommonRewardPreviewPanel(items)
  self:OpenPanel("CommonRewardPreview", items)
end

function ActivityModule:OpenCommonFashionRewardSelectPanel(bagItem, treasureCfg)
  if bagItem then
    self:OpenPanel("CommonFashionRewardSelect", bagItem, treasureCfg)
  end
end

function ActivityModule:OpenSeasonPreheatingRecordBookPanel(itemObject)
  self:OpenPanel("SeasonPreheating_RecordBook", itemObject)
end

function ActivityModule:OpenActivityPopupPanel(activityId, panelName)
  local activityInst = self:GetActivityInstById(tonumber(activityId), true)
  if not activityInst then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_unopen_track_tips)
    return
  end
  if not string.IsNilOrEmpty(panelName) then
    self:OpenPanel(panelName, activityInst)
  else
    self:LogError("ActivityModule:OpenActivityPopupPanel: panelName is nil or empty.")
  end
end

function ActivityModule:OpenSelectionOfBranchCollegesPanel(NPCAction)
  self:OpenPanel("SelectionOfBranchColleges", NPCAction)
end

function ActivityModule:OnZoneGetPlayerActivityInfoRsp(_protoData)
  Log.Dump(_protoData, 9, "OnZoneGetPlayerActivityInfoRsp")
  if _protoData and 0 == _protoData.ret_info.ret_code then
    local data = self.data
    data.login_days = _protoData.login_days
    data.login_history = _protoData.login_history
    self.data:SvrUpdateActivities(_protoData.activity_brief_info, _protoData.activity_id)
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnActivityObjectsUpdateFinish)
  end
end

function ActivityModule:OnZoneGetPlayerActivityDataRsp(_protoData)
  if _protoData and 0 == _protoData.ret_info.ret_code then
    Log.Info("OnZoneGetPlayerActivityDataRsp:", _protoData.activity_data.activity_id)
    self.data:SvrUpdateActivityData(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP, _protoData.activity_data.activity_id, _protoData.activity_data)
  else
    Log.Error("OnZoneGetPlayerActivityDataRsp: failed.", _protoData and _protoData.ret_info.ret_code)
  end
end

function ActivityModule:OnZonePlayerNewActivityRewardNotify(_protoData)
  if _protoData then
    self.data:SvrUpdateActivityData(_G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NEW_ACTIVITY_REWARD_NOTIFY, _protoData.activity_id, _protoData)
  end
end

function ActivityModule:OnZoneAddPlayerActivityPartRewardNotify(_protoData)
  if _protoData then
    self.data:SvrUpdateActivityData(_G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PLAYER_ACTIVITY_PART_REWARD_NTY, _protoData.activity_id, _protoData.activity_part_id)
  end
end

function ActivityModule:OnZonePlayerActivityDataChangeNty(_protoData)
  if _protoData then
    local activityId = _protoData.activity_data.activity_id
    local available = not _protoData.activity_data.expired
    Log.Info("OnZonePlayerActivityDataChangeNty:", activityId, available)
    self.data:SvrUpdateActivityStatus(activityId, available)
    if available then
      self.data:SvrUpdateActivityData(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP, activityId, _protoData.activity_data)
    end
  end
end

function ActivityModule:OnPlayerLotteryRewardConfirmItemNty(_protoData)
  if _protoData and _protoData.ret_info and 0 == _protoData.ret_info.ret_code then
    local lottery_data = {}
    lottery_data.lottery_item = _protoData.lottery_item
    lottery_data.trans_id = _protoData.trans_id
    lottery_data.lottery_result = _protoData.lottery_result
    table.insert(self.data.LotteryResultList, lottery_data)
    self:OnCmdOpenLotteryResultPanel()
  else
    Log.Error("ZoneLotteryRewardResultNotify Data Error")
  end
end

function ActivityModule:OnZoneNpcChallengeBattleChangeNty(_protoData)
  if _protoData then
    self.npcChallengeHandler:AddOrRefreshChallengeItem(_protoData.npc_challenge_item)
  end
end

function ActivityModule:OnCmdSelectCyclicalChallengeTab(CyclicalChallengeItemObject)
  self:DispatchEvent(ActivityModuleEvent.SelectCyclicalChallengeTabEvent, CyclicalChallengeItemObject)
end

function ActivityModule:OnCmdGetDisplayingFashionMallActivity()
  local allDisplayActivities = self:GetDisplayActivities()
  if nil == allDisplayActivities then
    return nil
  end
  for key, activityInstance in pairs(allDisplayActivities) do
    if activityInstance:GetActivityType() == Enum.ActivityType.ATP_PIKA then
      return activityInstance:GetActivityId()
    end
  end
end

function ActivityModule:OpenActivityPanelTestUI(umg_path)
  self:OpenPanel("ActivityMainPanel", umg_path)
end

function ActivityModule:OpenActivitySurvey()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Survey.UMG_Activity_Survey_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityAttention()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Attention.UMG_Activity_Attention_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityWaitingDuck()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_WaitingDuck.UMG_Activity_WaitingDuck_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityGrassSystem()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_GrassSystem.UMG_Activity_GrassSystem_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityQualificationFission()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_QualificationFission.UMG_Activity_QualificationFission_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityRiverSystem()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_RiverSystem.UMG_Activity_RiverSystem_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivitySummaryRecall()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_SummaryRecall.UMG_Activity_SummaryRecall_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityLimitedFlowerSeed()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_LimitedFlowerSeed.UMG_Activity_LimitedFlowerSeed_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityWingSystem()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_WingSystem.UMG_Activity_WingSystem_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityPetCatch()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_PetCatch.UMG_Activity_PetCatch_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityHeterochrome()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Heterochrome.UMG_Activity_Heterochrome_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityDigForTreasure()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_DigForTreasure.UMG_Activity_DigForTreasure_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityFashionMall()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_FashionMall.UMG_Activity_FashionMall_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OpenActivityHatching()
  local umg_path = "WidgetBlueprint'/Game/NewRoco/Modules/System/Activity/Res/UMG_Activity_Hatching.UMG_Activity_Hatching_C'"
  self:OpenActivityPanelTestUI(umg_path)
end

function ActivityModule:OnCmdOpenActivityElfCollectionTips(petBaseId, trailParam)
  self:OpenPanel("ActivityElfCollectionTips", petBaseId, trailParam)
end

function ActivityModule:OnCmdOpenActivityElfCollectionAwardTips(data)
  self:OpenPanel("FreeHuggersPanel", data)
end

function ActivityModule:OnCmdActivityExpiredCloseAwardTips()
  if self:HasPanel("FreeHuggersPanel") then
    local panel = self:GetPanel("FreeHuggersPanel")
    panel:ActivityExpiredClosePanel()
  end
end

function ActivityModule:OnCmdOpenLotteryResultPanel()
  if self:HasPanel("ActivityAbuReward") then
    return
  end
  local resultList = self.data.LotteryResultList
  if resultList and #resultList > 0 then
    self:OpenPanel("ActivityAbuReward", resultList[1])
    table.remove(resultList, 1)
  end
end

function ActivityModule:OnLogin(isLogin)
  self:OnOpenLotteryResultPanelByLoginData()
end

function ActivityModule:OnOpenLotteryResultPanelByLoginData()
  if not self.showResult then
    local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
    if playerInfo and playerInfo.lottery_confirm and playerInfo.lottery_confirm.item_list and #playerInfo.lottery_confirm.item_list > 0 then
      self.data.LotteryResultList = playerInfo.lottery_confirm.item_list
      self:OnCmdOpenLotteryResultPanel()
      self.showResult = true
    end
  end
end

function ActivityModule:OnCmdOpenSelectPartnerPetPanel(panelData)
  if self:HasPanel("SelectPartnerPetPanel") then
    return
  end
  self:OpenPanel("SelectPartnerPetPanel", panelData)
end

function ActivityModule:RefreshPandoraActivity()
  local GameletImpl = require("Core.Service.Pandora.GameletImpl")
  if GameletImpl.PandoraActivityObj and not table.isEmpty(GameletImpl.PandoraActivityObjs) then
    for _, activityObj in ipairs(GameletImpl.PandoraActivityObjs) do
      self:UploadLocalActivity(ActivityEnum.ActivitySource.Pandora, activityObj)
    end
    table.clear(GameletImpl.PandoraActivityObjs)
  end
end

function ActivityModule:OnCmdOpenActivityCollectPanel(...)
  self:OpenPanel("ActivityCollect", ...)
end

function ActivityModule:OnCmdOpenTipsCollectionAtlasesPanel(...)
  self:OpenPanel("TipsCollectionAtlases", ...)
end

function ActivityModule:OnCmdOpenInvitationRecord(activity_id)
  local req = _G.ProtoMessage:newZoneGetInviteUserListReq()
  req.activity_id = activity_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_INVITE_USER_LIST_REQ, req, self, self.OpenInvitationRecord)
end

function ActivityModule:OpenInvitationRecord(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:OpenPanel("InvitationRecord", rsp.invited_users)
  end
end

function ActivityModule:OnCmdOpenActivityReview(coCreationData)
  self.coCreationData = coCreationData
  local req = _G.ProtoMessage:newZoneGetPlayerActivityHistoryDataReq()
  req.activity_type = ProtoEnum.ActivityType.ATP_PLAYER_CO_CREATION_START
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_HISTORY_DATA_REQ, req, self, self.OnGetHistoryActivityData, false, true)
end

function ActivityModule:OnGetHistoryActivityData(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local activityData = {}
    local allData = {}
    if rsp.activity_data then
      allData = rsp.activity_data
    end
    if self.coCreationData.co_creation_data then
      self.coCreationData.co_creation_data.bIsStart = true
      table.insert(allData, self.coCreationData)
    end
    for _, v in ipairs(allData) do
      local base_id = _G.DataConfigManager:GetActivityConf(v.activity_id).base_id[1]
      local activityNum = _G.DataConfigManager:GetActivityPlayerCoCreation(base_id).activity_number
      activityData[activityNum] = {
        co_creation_data = v.co_creation_data,
        base_id = base_id,
        activity_id = v.activity_id
      }
    end
    self:OpenPanel("ActivityReview", activityData)
    self.coCreationData = nil
  end
end

function ActivityModule:OnCmdOpenPeerTask(...)
  self:OpenPanel("PeerTask", ...)
end

function ActivityModule:OnCmdGetSpecificTimeActivityReward(type)
  local rewardList = {}
  local ActiveObjectList = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_DROP, true)
  if ActiveObjectList and #ActiveObjectList > 0 then
    if #ActiveObjectList > 1 then
      table.sort(ActiveObjectList, function(a, b)
        return a:GetActivityStartTime() > b:GetActivityStartTime()
      end)
    end
    for i, v in ipairs(ActiveObjectList) do
      local conditions1 = v:IsInProgress()
      local conditions2, dropMethodId = v:CanShowDropReward(type or _G.Enum.ActivityDropShowArea.ADSA_NONE)
      if conditions1 and conditions2 and dropMethodId then
        local dropMetConf = _G.DataConfigManager:GetActivityDropMethodConf(dropMethodId, true)
        if dropMetConf then
          local reward = {
            itemId = dropMetConf.drop_show_goods_id,
            itemType = dropMetConf.drop_show_goods_type,
            bShowNum = false,
            bShowTip = true,
            topLabelText = LuaText.ShinyWeekend_ActivityReward_tip
          }
          table.insert(rewardList, reward)
          break
        end
      end
    end
  else
    Log.Debug("ActivityModule:OnCmdGetSpecificTimeActivityReward: No ActiveObjectList")
  end
  return rewardList
end

function ActivityModule:OnCmdOpenPlayeSWork(activity_id)
  local req = _G.ProtoMessage:newZoneActivityGetCoCreationEmojReq()
  req.activity_id = activity_id
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_GET_CO_CREATION_EMOJ_REQ, req, self, self.OpenPlayeSWork, false, true)
end

function ActivityModule:OpenPlayeSWork(rsp)
  local panel = self:GetPanel("ActivityReview")
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local base_id, activity_id = panel:GetCurBaseActivityId()
    self:OpenPanel("PlayeSWork", base_id, activity_id, rsp)
  end
  panel:OpenPlayeSWorkFinish()
end

function ActivityModule:OnCmdOpenOrdinaryReward(rewardData)
  self:OpenPanel("OrdinaryReward", rewardData)
end

function ActivityModule:OnCmdOpenPredestinedEvidence(madelData)
  self:OpenPanel("PredestinedEvidence", madelData)
end

function ActivityModule:OnCmdOpenTerritoryTrialInformation(information)
  self:OpenPanel("TerritoryTrialInformation", information)
end

function ActivityModule:OnCmdOpenTerritoryTrialRewardPreview(rewardData)
  self:OpenPanel("TerritoryTrialRewardPreview", rewardData)
end

function ActivityModule:OnCmdOpenCertificationBlessingMain(OpenAction)
  self:OpenPanel("CertificationBlessingMain", OpenAction)
end

function ActivityModule:OnCmdOpenBlessingPetDetailPanel(petInfo, parent, closeCallback)
  self:OpenPanel("BlessingPetDetailPanel", petInfo, parent, closeCallback)
end

function ActivityModule:OnCmdOpenPikaFashionSurveyToPhoto(parent)
  self:OpenPanel("PikaFashionSurvey_ToPhoto", parent)
end

function ActivityModule:OnCmdTakeReward(ActivityId, SubActivityId, Params, Callback, bAutoDisplayTips)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ
  local Req = ProtoMessage:newZoneActivityCommonRewardsReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  Req.activity_id = ActivityId
  Req.activity_sub_id = SubActivityId
  Req.params = Params
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    local RetCode = _protoData.ret_info and _protoData.ret_info.ret_code
    bSuccess = 0 == RetCode
    Callback(bSuccess, _protoData)
    if bSuccess and bAutoDisplayTips and (_protoData.ret_info.goods_reward or {}).rewards then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, _protoData.ret_info.goods_reward.rewards, "")
    end
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(bSuccess)
  end
end

function ActivityModule:OnCmdOpenFreeHuggersCardPanel(data)
  self:OpenPanel("FreeHuggersCardPanel", data)
end

function ActivityModule:OpenBackflowPetSelect(pet_ids, activityId)
  self:OpenPanel("BackflowPetSelect", pet_ids, activityId)
end

function ActivityModule:OpenContractManualShopTips(activity_id)
  self:OpenPanel("ContractManualShopTips", activity_id)
end

function ActivityModule:OnCmdCheckPetCollectIsFinish(activityId)
  if not activityId then
    return false
  end
  local petCollectConf = _G.DataConfigManager:GetActivityPetCollectionConf(activityId)
  if petCollectConf and petCollectConf.pet_group then
    local petGroup = petCollectConf.pet_group
    local maxNum = 0
    if petGroup then
      maxNum = #petGroup
    end
    local curNum = 0
    local activityObject = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstById, activityId)
    if activityObject and activityObject.returnActivityData and activityObject.returnActivityData.pet_collection_data then
      local petCollectData = activityObject.returnActivityData.pet_collection_data
      local collectPetList = petCollectData.collection_pet
      if collectPetList then
        curNum = #collectPetList
      end
    end
    return curNum == maxNum
  end
  return false
end

function ActivityModule:OnCmdCheckActivityExpired(activityId)
  local activityObject = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstById, activityId)
  if activityObject then
    if activityObject.status == ActivityEnum.ActivityStatus.Expired then
      return true
    end
  else
    return true
  end
  return false
end

local CommonOpenTipState = {}
CommonOpenTipState.WaitDependency = 1
CommonOpenTipState.PendingActive = 2
CommonOpenTipState.Active = 3
CommonOpenTipState.PerformSuccess = 4
CommonOpenTipState.ServerRspConfirm = 5
local CommonOpenTipStateBitNum = {}
CommonOpenTipStateBitNum.StateSpaceHolder = 7
CommonOpenTipStateBitNum.Debug = 8
local CommonOpenTipStateSpaceMask = (1 << CommonOpenTipStateBitNum.StateSpaceHolder + 1) - 1

local function ResetState(OriginalValue, newState)
  OriginalValue = OriginalValue or 0
  newState = newState or 0
  return (OriginalValue & ~CommonOpenTipStateSpaceMask) + newState
end

function ActivityModule:OnCmdTryShowActivityCommonOpenTips(activityId, specificTipObject, bDebugCommonOpenTips, ReCheckDependency)
  Log.Debug("ActivityModule:OnCmdTryShowActivityCommonOpenTips", activityId, specificTipObject, bDebugCommonOpenTips)
  if not activityId then
    return
  end
  local activityConf = _G.DataConfigManager:GetActivityConf(activityId)
  if not activityConf or not activityConf.popup_path then
    return
  end
  if specificTipObject and specificTipObject.customData and not bDebugCommonOpenTips then
    bDebugCommonOpenTips = specificTipObject.customData.bDebug
  end
  if not bDebugCommonOpenTips then
    local bAnyConfirmPopPlayed = false
    local activityInst = self:GetActivityInstById(activityId)
    if activityInst then
      local bPopupPlayed = activityInst:GetPopupPlayed()
      if nil ~= bPopupPlayed and bPopupPlayed then
        bAnyConfirmPopPlayed = true
        if specificTipObject then
          Log.Dump(specificTipObject, 4, "ActivityModule:OnCmdTryShowActivityCommonOpenTips_1")
        end
        return
      end
    end
    if not bAnyConfirmPopPlayed then
      local activityBriefInfo = self.data.svrActivityBriefInfo[activityId]
      if activityBriefInfo and activityBriefInfo.popup_played then
        bAnyConfirmPopPlayed = true
        if specificTipObject then
          Log.Dump(specificTipObject, 4, "ActivityModule:OnCmdTryShowActivityCommonOpenTips_2")
        end
        return
      end
    end
  end
  local currentState = self.data._CommonOpenTipState[activityId] or 0
  local currentStatePure = currentState & CommonOpenTipStateSpaceMask
  local currentStateBase = currentState & ~CommonOpenTipStateSpaceMask
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, false, false, false)
  if specificTipObject then
    if Ban then
      self.data._CommonOpenTipState[activityId] = currentStateBase + CommonOpenTipState.WaitDependency
      specificTipObject:MarkFinished()
    else
      self:DoShowActivityCommonOpenTips(specificTipObject)
    end
  else
    if 0 ~= currentStatePure and currentStatePure < CommonOpenTipState.ServerRspConfirm then
      local bShouldReCheckDependency = ReCheckDependency and currentStatePure == CommonOpenTipState.WaitDependency
      Log.Debug("ActivityModule:OnCmdTryShowActivityCommonOpenTips ", activityId, self.data._CommonOpenTipState[activityId], bShouldReCheckDependency)
      if not bShouldReCheckDependency then
        return
      end
    end
    if bDebugCommonOpenTips then
      currentStateBase = currentStateBase | 1 << CommonOpenTipStateBitNum.Debug
    else
      currentStateBase = currentStateBase & ~(1 << CommonOpenTipStateBitNum.Debug)
    end
    if Ban then
      self.data._CommonOpenTipState[activityId] = currentStateBase + CommonOpenTipState.WaitDependency
    else
      local tipObject = TipObject.CreateActivityCommonOpenTips(activityId, bDebugCommonOpenTips)
      self.data._CommonOpenTipState[activityId] = currentStateBase + CommonOpenTipState.PendingActive
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, tipObject)
    end
  end
end

function ActivityModule:DoShowActivityCommonOpenTips(tip)
  if not tip then
    return
  end
  local activityId = tip.customData and tip.customData.activityId
  if activityId then
    local activityConf = _G.DataConfigManager:GetActivityConf(activityId)
    if activityConf and activityConf.popup_path then
      local umgPath = string.format("/Game/NewRoco/Modules/System/Activity/Res/%s", activityConf.popup_path)
      local panelData = self:GetPanelData("ActivityCommonOpenTipsPanel")
      panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(umgPath)
      self.data._CommonOpenTipState[activityId] = ResetState(self.data._CommonOpenTipState[activityId], CommonOpenTipState.Active)
      self:OpenPanel("ActivityCommonOpenTipsPanel", tip)
      return
    end
  end
  tip:MarkFinished()
end

function ActivityModule:OnActivityPopUpPlayedRsp(rsp)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code and rsp.activity_id then
    Log.Debug("ActivityModule:OnActivityPopUpPlayedRsp", rsp.activity_id, self.data._CommonOpenTipState[rsp.activity_id])
    self.data:SvrUpdateActivityData(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_POPUP_PLAYED_RSP, rsp.activity_id)
    self.data._CommonOpenTipState[rsp.activity_id] = ResetState(self.data._CommonOpenTipState[rsp.activity_id], CommonOpenTipState.ServerRspConfirm)
  end
end

function ActivityModule:OnFunctionBanUpdated(newState, functionType, reason)
  if not newState then
    for activityId, state in pairs(self.data._CommonOpenTipState) do
      local statePure = state & CommonOpenTipStateSpaceMask
      if statePure == CommonOpenTipState.WaitDependency then
        local bDebugCommonOpenTips = 0 ~= state & 1 << CommonOpenTipStateBitNum.Debug
        self:OnCmdTryShowActivityCommonOpenTips(activityId, nil, bDebugCommonOpenTips, true)
      end
    end
  end
end

function ActivityModule:MarkActivityCommonOpenTipsPerform(bPerformSuccess, activityId)
  if not activityId then
    return
  end
  local currentState = self.data._CommonOpenTipState[activityId]
  if not currentState then
    return
  end
  local currentStatePure = currentState & CommonOpenTipStateSpaceMask
  Log.Debug("ActivityModule:MarkActivityCommonOpenTipsPerform", currentState, bPerformSuccess, activityId)
  if bPerformSuccess then
    if currentStatePure < CommonOpenTipState.PerformSuccess then
      self.data._CommonOpenTipState[activityId] = ResetState(self.data._CommonOpenTipState[activityId], CommonOpenTipState.PerformSuccess)
      local bDebugCommonOpenTips = 0 ~= currentState & 1 << CommonOpenTipStateBitNum.Debug
      if not bDebugCommonOpenTips then
        local req = _G.ProtoMessage:newZoneActivityPopupPlayedReq()
        req.activity_id = activityId
        _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_POPUP_PLAYED_REQ, req, self, self.OnActivityPopUpPlayedRsp, false, false)
      else
        self.data._CommonOpenTipState[activityId] = ResetState(self.data._CommonOpenTipState[activityId], CommonOpenTipState.ServerRspConfirm)
      end
    end
  else
    self.data._CommonOpenTipState[activityId] = nil
  end
end

function ActivityModule:OnOpenAICoachProtocolPanel()
  self:OpenPanel("AICoachUserProtocol")
end

function ActivityModule:OnCmdOpenObservationNotesPanel()
  self:OpenPanel("ObservationNotesPanel")
end

function ActivityModule:OnCmdOpenObservationNotesPhotoPanel(info_id)
  self:OpenPanel("ObservationNotesPhotoPanel", info_id)
end

function ActivityModule:OnCmdOpenObservationNotesInfoPanel(data)
  if self:HasPanel("ObservationNotesPanel") then
    local panel = self:GetPanel("ObservationNotesPanel")
    panel:SwitchPanel(1, data)
  end
end

function ActivityModule:OnCmdOpenSurveyTasksPanel(taskData)
  self:OpenPanel("SurveyTasksPanel", taskData)
end

function ActivityModule:OnCmdOpenElfParadiseSelect(activity_id)
  local req = _G.ProtoMessage:newZoneActivityPetTripGetWishChoiceCountReq()
  req.activity_id = activity_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_GET_WISH_CHOICE_COUNT_REQ, req, self, self.OpenElfParadiseSelect)
end

function ActivityModule:OpenElfParadiseSelect(rsp)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self:OpenPanel("ElfParadiseSelect", rsp.wish_choice_counts)
  end
end

function ActivityModule:OnCmdOpenElfParadiseRewards()
  self:OpenPanel("ElfParadiseRewards")
end

function ActivityModule:OnCmdOpenElfAdventure(taskData)
  self:OpenPanel("ElfAdventureBg")
  self:OpenPanel("ElfAdventure", taskData)
end

function ActivityModule:OnElfAdventureBgAnimClose()
  if self:HasPanel("ElfAdventure") then
    local panel = self:GetPanel("ElfAdventure")
    panel:PlayInAnimation()
  end
end

function ActivityModule:OnCmdOpenElfAdventureTravelLog()
  self:OpenPanel("ElfAdventureTravelLog")
end

function ActivityModule:OnCmdOpenElfParadiseEventReview(lottery_records)
  self:OpenPanel("ElfParadiseEventReview", lottery_records)
end

function ActivityModule:OpenTakePhotoCompetitionVotePanel(activityInst)
  if not activityInst then
    return
  end
  self:OpenPanel("TakePhotoCompetition_Vote", activityInst)
end

function ActivityModule:OpenTakePhotoCompetitionVoteRewardPanel(activityInst)
  if not activityInst then
    return
  end
  self:OpenPanel("TakePhotoCompetition_ClaimReward", activityInst)
end

function ActivityModule:OpenTakePhotoCompetitionRankingsPanel(activityInst)
  if not activityInst then
    return
  end
  local cfg = activityInst:GetCurrentPhaseConf()
  if cfg then
    local rankDataObject = activityInst:GetRankDataObject(cfg.id, false)
    rankDataObject:MarkAllRankDataDirty()
    rankDataObject:PrefetchPlayerRankData(true)
    local prefetching = rankDataObject:PrefetchAllRankData(true)
    self:OpenPanel("TakePhotoCompetition_Rankings", activityInst, rankDataObject, prefetching)
  else
    Log.Error("ActivityModule:OpenTakePhotoCompetitionRankingsPanel", activityInst:GetActivityId(), "no cfg")
  end
end

function ActivityModule:OpenTakePhotoCompetitionPreviousReviewPanel(activityInst)
  if not activityInst then
    return
  end
  local pastPhaseIds = activityInst:GetPastPhases()
  if pastPhaseIds and #pastPhaseIds > 0 then
    local defaultRankDataObject = activityInst:GetRankDataObject(pastPhaseIds[1], false)
    defaultRankDataObject:PrefetchPlayerRankData(false)
    local prefetching = defaultRankDataObject:PrefetchAllRankData(false)
    self:OpenPanel("TakePhotoCompetition_PreviousReview", activityInst, pastPhaseIds, prefetching)
  else
    Log.Error("ActivityModule:OpenTakePhotoCompetitionPreviousReviewPanel", activityInst:GetActivityId(), "no past phase")
  end
end

function ActivityModule:OpenTakePhotoCompetitionRewardPreview()
  self:OpenPanel("TakePhotoCompetition_RewardPreview")
end

function ActivityModule:OpenTakePhotoCompetitionBigPhoto(DisplayData)
  if not DisplayData then
    local ActivityObjectList = self:GetActivityInstByType(Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
    local ActivityObject = ActivityObjectList and ActivityObjectList[1]
    if ActivityObject then
      DisplayData = {}
      local ActivityData = ActivityObject:GetActivityData()
      if ActivityData.phases then
        for i = #ActivityData.phases, 1, -1 do
          local Phase = ActivityData.phases[i]
          if Phase.phase_id == ActivityData.current_phase_id then
            local Url = Phase.photo_url
            local Md5 = Phase.photo_md5
            DisplayData.Url = Url
            DisplayData.Md5 = Md5
            break
          end
        end
      end
    end
  end
  if not DisplayData then
    Log.Error("OpenTakePhotoCompetitionBigPhoto Invalid DisplayData")
    return
  end
  self:OpenPanel("TakePhotoCompetition_BigPhoto", DisplayData)
end

function ActivityModule:OpenTakePhotoCompetitionSubmissionReward(rsp)
  self:OpenPanel("TakePhotoCompetition_SubmissionReward", rsp)
end

function ActivityModule:GetActivityAnimFlag(activityId)
  local targetActivityId
  if type(activityId) == "number" then
    targetActivityId = tostring(activityId)
  else
    targetActivityId = activityId
  end
  if not self.data.activityAnimFlag then
    self.data:LoadActivityAnimFlag()
    if not self.data.activityAnimFlag then
      return
    end
  end
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if not playerUin then
    return
  end
  local strPlayerUin = tostring(playerUin)
  local curPlayerActivityAnimFlag = self.data.activityAnimFlag[strPlayerUin]
  return curPlayerActivityAnimFlag and not not curPlayerActivityAnimFlag[targetActivityId]
end

function ActivityModule:MarkActivityAnimFlag(activityId, bSetTrue)
  local targetActivityId
  if type(activityId) == "number" then
    targetActivityId = tostring(activityId)
  else
    targetActivityId = activityId
  end
  if not self.data.activityAnimFlag then
    self.data:LoadActivityAnimFlag()
    if not self.data.activityAnimFlag then
      return
    end
  end
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if not playerUin then
    return
  end
  local strPlayerUin = tostring(playerUin)
  local curPlayerActivityAnimFlag = self.data.activityAnimFlag[strPlayerUin]
  if not curPlayerActivityAnimFlag then
    self.data.activityAnimFlag[strPlayerUin] = {}
    curPlayerActivityAnimFlag = self.data.activityAnimFlag[strPlayerUin]
  end
  if bSetTrue then
    curPlayerActivityAnimFlag[targetActivityId] = true
  else
    curPlayerActivityAnimFlag[targetActivityId] = nil
  end
  self.data:SaveActivityAnimFlag()
end

function ActivityModule:OnCmdOpenChallengeProgressRewardPanel(...)
  self:OpenPanel("ChallengeProgressRewardPanel", ...)
end

function ActivityModule:OnCmdIsPetInCurTripInfo(pet_gid)
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    local activityData = PetTripActivityInst[1]:GetActivityData()
    if activityData and activityData.cur_pet_trip_info and #activityData.cur_pet_trip_info > 0 then
      for _, tripInfo in ipairs(activityData.cur_pet_trip_info) do
        if tripInfo.pet_gid == pet_gid then
          return true
        end
      end
    end
  end
  return false
end

function ActivityModule:OnCmdOpenObservationNotesDetailsPanel(storyData)
  self:OpenPanel("ObservationNotesDetailsPanel", storyData)
end

function ActivityModule:OnCmdOpenPreDownloadPopupPanel(_activityInst)
  self:OpenPanel("PreDownloadPopupPanel", _activityInst)
end

function ActivityModule:OnZonePlayerNpcLotteryGoodsRewardNotify(notify)
  local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, notify.npc_id)
  if not npc or not npc.viewObj then
    return
  end
  if notify.ret_info.ret_code and 0 ~= notify.ret_info.ret_code then
    return
  end
  
  local function showRewardAction(bIsShowReward)
    if bIsShowReward and notify.ret_info.goods_reward and notify.ret_info.goods_reward.rewards and #notify.ret_info.goods_reward.rewards > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(notify.ret_info.goods_reward.rewards))
    end
  end
  
  if 0 == notify.pool_reward_id then
    showRewardAction(true)
    return
  end
  local lotteryConf = _G.DataConfigManager:GetLotteryPoolRewardConf(notify.pool_reward_id)
  if not lotteryConf then
    return
  end
  if string.IsNilOrEmpty(lotteryConf.reward_skill_blueprint) then
    showRewardAction(lotteryConf.is_reward_pop)
    return
  end
  local skillComp = npc.viewObj.RocoSkill
  local skill = RocoSkillProxy.Create(lotteryConf.reward_skill_blueprint, skillComp)
  if not skill then
    Log.Error("\230\137\190\228\184\141\229\136\176Skill\239\188\154lotteryConf.reward_skill_blueprint")
    showRewardAction(lotteryConf.is_reward_pop)
    return
  end
  skill:SetCaster(npc.viewObj)
  skill:SetTargets({
    npc.viewObj
  })
  skill:RegisterEventCallback("End", self, function()
    npc.InteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.ANY, true)
    showRewardAction(lotteryConf.is_reward_pop)
  end)
  npc.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.ANY, true)
  skill:PlaySkill()
end

function ActivityModule:OnEnterOrLeaveDropActivityArea(notify)
  local activityIns = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, notify.activity_id, true)
  if not activityIns or not activityIns:IsInProgress() then
    Log.Debug("ActivityModule:OnEnterOrLeaveDropActivityArea activityIns is nil or not in progress", notify.activity_id, notify.action_type)
    return
  end
  if 0 == notify.action_type then
    local title = ""
    local subTitle = ""
    local PlayerZoneArray = _G.NRCModeManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneArray)
    if PlayerZoneArray and PlayerZoneArray._items and #PlayerZoneArray._items > 0 then
      for k, areaInfo in ipairs(PlayerZoneArray._items) do
        local areaFuncId = areaInfo.id
        local areaFuncConf = DataConfigManager:GetAreaFuncConf(areaFuncId)
        if areaFuncConf and areaFuncConf.broadcast_type == Enum.AreaBroadcastType.ABT_ACTIVITY then
          title = areaFuncConf.name
          local worldMapActivityConf = NRCModuleManager:DoCmd(BigMapModuleCmd.GetWorldMapActivityConfByAreaFuncId, areaFuncId)
          if worldMapActivityConf then
            subTitle = worldMapActivityConf.activity_name
          end
          local text = string.format("%s_%s", title, subTitle)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowActivityZoneTip, text)
        end
      end
    end
  end
  Log.Debug("====================SpecificTimeActivityObject:OnEnterOrLeaveDropActivityArea", notify.action_type)
end

return ActivityModule
