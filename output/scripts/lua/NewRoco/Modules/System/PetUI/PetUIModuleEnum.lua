local PetUIModuleEnum = {}
PetUIModuleEnum.PanelId = {LEFT_PANEL = 1, PET_BAG = 2}
PetUIModuleEnum.OpenPetRateType = {Certification = 1, StriveLevel = 2}
PetUIModuleEnum.AddExpType = {
  PetExp = 1,
  HpExp = 2,
  AtkExp = 3,
  SpAtkExp = 4,
  DefExp = 5,
  SpDefExp = 6,
  SpeedExp = 7
}
PetUIModuleEnum.OpenSortType = {
  WareHouse = 1,
  WareHouseFree = 2,
  TeamReplace = 3,
  NeedModuleCatch = 4,
  HomePetFeeding = 5,
  HomePlantGuard = 6,
  WeeklyChallengeBattle = 7,
  PetInheritance = 8,
  PetPartnerActivity = 9,
  CertificationActivity = 10,
  BattleRogue = 11
}
PetUIModuleEnum.EnterType = {
  PetAltar = 0,
  PvpPetTeamUmg = 1,
  PetInheritance = 2,
  WeeklyChallengeBattle = 3,
  HerbologyBadge = 4
}
PetUIModuleEnum.AddAutomaticallyType = {
  NuLL = 0,
  Add = 1,
  Reduce = 2
}
PetUIModuleEnum.MedalOperationType = {
  Wear = 0,
  dropoff = 1,
  replace = 2
}
PetUIModuleEnum.ModifyPetMode = {SingleEdit = 0, QuickEdit = 1}
PetUIModuleEnum.OpenTeamReplaceType = {PetTeam = 0, PvpQualifier = 1}
PetUIModuleEnum.PetTeamShowType = {
  Normal = 0,
  HidePetsUis = 1,
  HideUis = 2
}
PetUIModuleEnum.PetTitleListShowType = {
  NameSet = 0,
  ShareTeam = 1,
  LoadTeam = 2
}
PetUIModuleEnum.CommonPetDetailsShowType = {Normal = 0, PvpRank = 1}
PetUIModuleEnum.PetTeamShareReviseType = {
  None = 0,
  Talent = 1,
  Nature = 2,
  Blood = 3,
  Pet = 4,
  Skill = 5,
  Magic = 6
}
PetUIModuleEnum.PetHatchingRightPanelDisplayMode = {
  None = 0,
  SelectEgg = 1,
  SelectPetBall = 2,
  SelectColor = 3,
  IncubationProgress = 4
}
PetUIModuleEnum.PetHatchingRightPanelCloseReasonType = {None = 0, UsedIncubationProgressItem = 1}
PetUIModuleEnum.HatchingPanelCommonAddSubtractPanelUpdateReasonType = {None = 0, HatchSecsUpdate = 1}
PetUIModuleEnum.PetEggConfigType = {
  None = 0,
  NormalEgg = 1,
  BlessingEgg = 2,
  RandomEgg = 3
}
PetUIModuleEnum.PetEggAppearanceType = {
  None = 0,
  VisiblyGlass = 1,
  VisiblyShining = 2,
  VisiblyGlassAndShining = 3,
  Chaos = 4,
  CustomGlass = 5
}
PetUIModuleEnum.PetSkillOperationType = {
  None = 0,
  Exchange = 1,
  Replacement = 2
}
PetUIModuleEnum.MainPetTemplateOpType = {
  All = 0,
  RecycleState = 1,
  Lock = 2,
  DiedState = 3,
  FriendRideState = 4,
  updateThrowPetSelect = 5,
  ForceClearTips = 6
}
PetUIModuleEnum.MainPetTemplateOpReasonType = {None = 0, LobbyMainUIShow = 1}
PetUIModuleEnum.PetGrowUpType = {
  None = 0,
  WaitToGrowUp = 1,
  WaitToBreakThrough = 2,
  WaitToInspire = 3,
  Max = 4
}
PetUIModuleEnum.PetFreeCaptivePanelStateType = {None = 0, IncludeCanTraceBackPet = 1}
PetUIModuleEnum.ReleaseTipsOpenType = {
  None = 0,
  Free = 1,
  TraceBack = 2
}
PetUIModuleEnum.PetFreeReasonType = {
  None = 0,
  FreeInFreeMode = 1,
  DragToFree = 2
}
PetUIModuleEnum.PetCommonHandleCheckType = {
  None = 0,
  Free = 1,
  TraceBack = 2
}
PetUIModuleEnum.PetDataUpdateReason = {
  None = 0,
  LevelUp = 1,
  GrowUp = 2,
  BreakThrough = 3,
  Inspire = 4,
  Evolve = 5,
  TalentChange = 6,
  Free = 7,
  TraceBack = 8
}
PetUIModuleEnum.PortableBagSelectItemType = {
  None = 0,
  TeamItem = 1,
  PageItem = 2
}
PetUIModuleEnum.PetEquipSkillType = {
  PetBag = 1,
  PvpTeam = 2,
  Assumption = 3,
  StarlightDuel = 4,
  HerbologyBadge = 5
}
PetUIModuleEnum.CommonListItemPet1Anim = {
  In = 1,
  Out = 2,
  Normal = 3
}
return PetUIModuleEnum
