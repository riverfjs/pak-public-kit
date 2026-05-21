local TipEnum = {}
TipEnum.TipObjectType = {
  None = 0,
  Reward = 1,
  NewPet = 2,
  PetLevelUp = 3,
  PetNewSkill = 4,
  MainPetTips = 5,
  TaskComplete = 6,
  TaskAccept = 7,
  TaskUpdate = 8,
  RechargeUseCount = 9,
  IncreaseUseCount = 10,
  AmplifyUseEffect = 11,
  PetEvolution = 12,
  LeaderFight = 13,
  HandbookChange = 14,
  MiracleExchange = 15,
  PetBallCatchAward = 17,
  StampsChange = 19,
  DungeonStateCompleted = 20,
  DungeonRunning = 21,
  DungeonCompleted = 22,
  LobbyDownTips = 23,
  TopHudTips = 24,
  HandbookTopic = 25,
  LobbyRegionPreUpdate = 26,
  RolePlayGetTips = 28,
  NPCRosterTips = 29,
  LegendaryTaskUnlockTips = 30,
  MusicCollectUnlockTips = 31,
  MonthlyCardDailyRewardTips = 32,
  TaskSummary = 33,
  TaskReturnReward = 34,
  TeachingUnlockTips = 35,
  PetCertification = 36,
  ReceiveBPGiftTips = 37,
  SeasonBeginsTips = 38,
  ActivityCommonOpenTips = 39
}
TipEnum.NewFlagType = {
  None = 0,
  Yellow = 1,
  Blue = 2,
  White = 3
}
TipEnum.TitleType = {
  None = 0,
  Catch = 1,
  Battle = 2,
  Task = 3,
  Report = 4
}
TipEnum.Title = {
  [TipEnum.TitleType.None] = LuaText.tipenum_1,
  [TipEnum.TitleType.Catch] = LuaText.tipenum_2,
  [TipEnum.TitleType.Battle] = LuaText.tipenum_3,
  [TipEnum.TitleType.Task] = LuaText.tipenum_4,
  [TipEnum.TitleType.Report] = LuaText.tipenum_5
}
TipEnum.MainPetTipsType = {
  None = 0,
  Exp = 1,
  Level = 2,
  Skill = 3,
  Energy = 4,
  Medal = 5
}
TipEnum.TopHudTipsType = {
  None = 0,
  ZoneTips = 1,
  ExpTips = 2,
  FunUnlockTips = 3,
  MagicTips = 4,
  BreakThroughTips = 5,
  TaskTips = 6,
  CommonTips = 7,
  ActivityTips = 8,
  EnterHomeZoneTips = 9,
  HomeAddExpTips = 10,
  HomeRoomExpandTips = 11,
  CatchPetTips = 12,
  PetCertification = 13
}
TipEnum.LobbyDownTipsType = {BookPrompt = 0, PassAccomplish = 1}
TipEnum.PropTipsType = {GoodsItem = 1, PlayerAddExp = 2}
TipEnum.TipDisplayArea = {
  Top = 1,
  Bottom = 2,
  Left = 3,
  Right = 4,
  Center = 5
}
TipEnum.TipStatus = {
  Init = 0,
  Caching = 1,
  Distributing = 2,
  Blocking = 3,
  OnDisplay = 4,
  Expired = 5
}
TipEnum.TipsPauseReason = {
  UserSetting = 1,
  MainUIClose = 2,
  HasFullWindow = 4,
  LoadingUIOpen = 8,
  RolePlayUIOpen = 16,
  TakePhoto = 32,
  ConfirmTeleportTip = 64,
  GlobalBlack = 128,
  GlobalWhite = 256,
  Video = 512,
  OpenMainMapSelectUI = 1024,
  StrongGuide = 2048,
  ExchangeVisitsHint = 4096,
  RelationTreeUIOpen = 8192,
  DungeonReward = 16384,
  MagicReplay = 32768,
  PreparationPanel = 65536,
  SceneRunTest = 131072
}
TipEnum.OpenPetTipsType = {
  None = 0,
  PetMainPanel = 1,
  PetWareHouse = 2,
  HomePet = 3,
  HomePlantGuard = 4,
  InheritancePet = 5,
  FakePetData = 6
}
return TipEnum
