local WidgetPerformanceTier = {}
local PerformanceTierEnum = {Small = 0, Big = 1}

function WidgetPerformanceTier.GetTier()
  return WidgetPerformanceTier.WidgetPerformanceTierDict
end

WidgetPerformanceTier.WidgetPerformanceTierDict = {
  PhotoHistoryUI = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  Chat_Main = {
    PerformanceTierEnum.Small,
    "Small"
  },
  MapRightPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetRightPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Roster = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HandbookTrophy = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_PhotoFrame = {
    PerformanceTierEnum.Small,
    "Small"
  },
  MainBigMap = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetHatchingPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  TakePhotosMainUI = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetInfoMain = {
    PerformanceTierEnum.Big,
    "Big",
    "WorldView"
  },
  MagicBook = {
    PerformanceTierEnum.Small,
    "Small"
  },
  NPCShop = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  BattlePurchasePanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  TalkingBboutBubbles_Panel2 = {
    PerformanceTierEnum.Small,
    "Small"
  },
  AppearanceCloset = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  MagicManualMainPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  QuickChatBubble = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HandbookCover = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  UMG_PhotoFrame_Open = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattlePassAwardMain = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattlePassSelectPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HandbookMain = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  UMG_Activity_SevenDay = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HandbookSubject = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetBagPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  TaskMainPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  RolePlayMainPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ActivityMainPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  FriendRequest = {
    PerformanceTierEnum.Small,
    "Small"
  },
  SeasonalCombinationBagShop = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  LobbyMainInner = {
    PerformanceTierEnum.Small,
    "Small"
  },
  CardChangeBackground = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  LevelMain = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Friend = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  AppearanceTryOn = {
    PerformanceTierEnum.Big,
    "Big",
    "WorldView"
  },
  MusicSetting = {
    PerformanceTierEnum.Small,
    "Small"
  },
  MusicCollectionPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  SystemSettingMain = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  EmailMainPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  BagMain = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  StudentCard = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  ItemRewardsPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  TeachingManual = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  CardEditingComponent = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Shop = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  FashionMallConfirm = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  MagicVideoDetails = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ChangeCardLabel = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  Friend_ApplyFor_Blacklist = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HomeFurnitureAtlasMain = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetWarehousePanelMain = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetReportParticulars = {
    PerformanceTierEnum.Small,
    "Small"
  },
  NPCShopConfirm = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetReportReminder = {
    PerformanceTierEnum.Small,
    "Small"
  },
  SeedBag = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PreWarInformation = {
    PerformanceTierEnum.Small,
    "Small"
  },
  RelationTree = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetReport = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  FoodProcessingPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  MagicMessageCommentPopUp = {
    PerformanceTierEnum.Small,
    "Small"
  },
  AlchemyPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  LegendaryBattleMatchPanel = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  CreateMagicMessage = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PlantGuardPetChoosing = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HomeVisitPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  MagicalStudy = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  HomeLevelRewardPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HomeFurnitureCreation = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  Home = {
    PerformanceTierEnum.Small,
    "Small"
  },
  FriendFurniturePopup = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ConfirmTeleportTips = {
    PerformanceTierEnum.Small,
    "Small"
  },
  TailorShop = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetTeamManagement = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattlePVPResult = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  BattleRunAwayTip = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattleEntryHud = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  HudPerceptionPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetTeamReplace = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  BattlePveRoleHpPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattlePopUpTips = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PVPValueNumber = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PVPQualifier = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PVP_Prepare = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  BattlePvpHintPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  BattleMain = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PVPHistoricalRecord = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PVPDailyChallenge = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetBloodlineMagic = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PVPFirstReward = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetTeamPanel = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  PVPDanGrading = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  CandidateTips = {
    PerformanceTierEnum.Small,
    "Small"
  },
  DistrictMapGuide = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetDetailedInfo = {
    PerformanceTierEnum.Small,
    "Small"
  },
  PetLevelUp = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ShareCameraPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ShareOverlay = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ShopBuyTips = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  UMG_Activity_LegendaryBattle = {
    PerformanceTierEnum.Small,
    "Small"
  },
  SeasonIntegrationPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  SeasonIntegrationPopUp = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_Activity_PetPeer = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  StarlightPhoto = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView",
    "Pets"
  },
  UnlockInvitationPopup = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  RelationTreeEggBag = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  NPCShopConfirmNew = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  ShowMagicMessage = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_PhotoCropping = {
    PerformanceTierEnum.Small,
    "Small"
  },
  InstanceModuleEnterPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  NPCShopPlantSell = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  Friend_Report = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Friend_HomeEntrance = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Friend_Wold = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_LongDialog = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  PetRelationTree = {
    PerformanceTierEnum.Small,
    "Small",
    "RT"
  },
  SleepingOwlFruit = {
    PerformanceTierEnum.Small,
    "Small"
  },
  DialogueOverlay = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_ErrorPanel = {
    PerformanceTierEnum.Small,
    "Small"
  },
  SimpleUseList = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ShareTeam = {
    PerformanceTierEnum.Small,
    "Small"
  },
  UMG_Dialog = {
    PerformanceTierEnum.Small,
    "Small"
  },
  NewPetBag = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HomePetFoodPocket = {
    PerformanceTierEnum.Small,
    "Small"
  },
  HomePetChoosing = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  TeachingUnlockTips = {
    PerformanceTierEnum.Small,
    "Small"
  },
  StarlightShowDown = {
    PerformanceTierEnum.Big,
    "Big",
    "RT",
    "WorldView"
  },
  TeamEdit = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ResetNotification = {
    PerformanceTierEnum.Small,
    "Small"
  },
  RewardClaim = {
    PerformanceTierEnum.Small,
    "Small"
  },
  ShareUIPanel = {
    PerformanceTierEnum.Big,
    "Big",
    "WorldView"
  },
  NewPetBag = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Task_Mail = {
    PerformanceTierEnum.Small,
    "Small"
  },
  Friend_Remark = {
    PerformanceTierEnum.Small,
    "Small"
  }
}
return WidgetPerformanceTier
