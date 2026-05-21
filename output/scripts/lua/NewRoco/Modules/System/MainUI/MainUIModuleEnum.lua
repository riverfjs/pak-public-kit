local MainUIModuleEnum = {}
MainUIModuleEnum.MainUIChooseType = {
  ITEM = 0,
  PET = 1,
  MAGIC = 2
}
MainUIModuleEnum.MainUICameraState = {
  Normal = 0,
  PlayerInfo = 1,
  LevelUpRewards = 2,
  State = 3,
  BagUiZoom = 4,
  TaskUiZoom = 5,
  PetUiZoom = 6,
  BookUiZoom = 7,
  PvPUiZoom = 8,
  MapUiZoom = 9,
  EmailUiZoom = 10,
  SetUiZoom = 11
}
MainUIModuleEnum.SubPanelOpenType = {
  NoneUI = 0,
  BattleUI = 1,
  TaskUI = 2,
  MapUI = 3,
  HandbookUI = 4,
  PetUI = 5,
  BagUI = 6,
  PreDownload = 7
}
MainUIModuleEnum.MainUILuopanState = {
  Start = 1,
  Idle = 2,
  End = 3
}
MainUIModuleEnum.MainUILuopanIdleState = {NormalIdle = 1, PanelIdle = 2}
MainUIModuleEnum.ShowAimJoystick = {Throw = 0, Ability = 1}
MainUIModuleEnum.DisableHudOpSource = {
  EmptyHudEle = 2,
  GlobalForbid = 4,
  LobbyMainOpen = 8,
  Dialogue = 16,
  SuitPerform = 32,
  PlayerInVisible = 64,
  EnterNpcShop = 128,
  Cinematic = 256
}
MainUIModuleEnum.RewardTipsDisableReason = {TakePhoto = 2, System = 4}
MainUIModuleEnum.PlayerHudState = {
  Normal = 0,
  Perform = 2,
  Fight = 4,
  Fighting = 8,
  AFK = 16,
  Observing = 32,
  NpcInteraction = 64,
  FullScreen = 128
}
MainUIModuleEnum.FunctionID = {
  NoneUI = 0,
  BattleUI = 1,
  TaskUI = 2,
  MapUI = 3,
  HandbookUI = 4,
  PetUI = 5,
  BagUI = 6,
  ShopUI = 7,
  FashionMallUI = 8,
  BattlePassUI = 9,
  ActivityUI = 10,
  FriendUI = 11,
  RoleCardUI = 12,
  MailUI = 13,
  TeachingUI = 14,
  SeasonIntegration = 15
}
MainUIModuleEnum.AbilityBtnBlockReason = {
  Any = 0,
  InDoubleRide = 1,
  TaskPetFollow = 2
}
MainUIModuleEnum.CompassOpenType = {
  COMPASS_3D = 1,
  COMPASS_2D_NO_PLAYER = 2,
  COMPASS_2D_WITH_PLAYER = 3,
  COMPASS_2D_IGNORE_PLAYER = 4
}
MainUIModuleEnum.MainUIPanelType = {
  None = 0,
  LobbyMain = 1,
  LobbyMainLocal = 2,
  RogueLobbyMain = 3
}
MainUIModuleEnum.MinimapOrCompassState = {
  Normal = 1,
  Hidden = 2,
  Hidden_Exposed = 3,
  Hidden_Attacked = 4
}
return MainUIModuleEnum
