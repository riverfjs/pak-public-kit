local BattleEnum = {}
BattleEnum.Team = {
  ENUM_TEAM = 1,
  ENUM_ENEMY = 2,
  ENUM_OBSERVER = 3
}
BattleEnum.Operation = {
  ENUM_NONE = -1,
  ENUM_ESCAPE = 0,
  ENUM_ITEM = 1,
  ENUM_CATCH = 2,
  ENUM_CHANGE = 3,
  ENUM_SKILL = 4,
  ENUM_SURRENDER = 5,
  ENUM_PLAYERSKILL = 6,
  ENUM_STEPAWAY = 7,
  ENUM_GIVEUP = 8
}
BattleEnum.SelectMarkerType = {
  ENUM_NONE = 0,
  ENUM_MYSELF = 1,
  ENUM_ALLY = 2,
  ENUM_OTHER_ALLY = 3,
  ENUM_ENEMY = 4,
  ENUM_ALL = 5,
  ENUM_ENEMY_SAME_POS = 6,
  ENUM_MYSELF_ALLY = 7
}
BattleEnum.TypeRestraint = {
  ENUM_NONE = -1,
  ENUM_NORMAL = 0,
  ENUM_RESTRAINT = 1,
  ENUM_RESTRAINT_DOUBLE = 2,
  ENUM_WEAK = 3,
  ENUM_WEAK_DOUBLE = 4
}
BattleEnum.SpeedCompare = {
  ENUM_NOTSURE = 0,
  ENUM_FASTER = 1,
  ENUM_SLOWER = 2
}
BattleEnum.ReservesPetState = {
  Appeared = 1,
  NotAppeared = 2,
  NotExist = 3
}
BattleEnum.WidgetType = {
  ENUM_CHANGE_PET_PANEL = 1,
  ENUM_SKILL_PANEL = 2,
  ENUM_BAGPACK_BALLS = 4,
  Enum_ALL = 9999
}
BattleEnum.InfoPopupType = {
  SummonPet = 1,
  UseSkill = 2,
  PetRest = 3,
  PlainText = 4,
  PetStatus = 5,
  PetRunAwayCondition = 6,
  UseBuff = 7,
  UseEffect = 8,
  UseSpEnergy = 9,
  WaitingOther = 10,
  EnemyEscape = 11,
  PVPNoOp = 12,
  Sleeping = 13,
  WakeUp = 14,
  IsBacking = 16,
  IsNotBacking = 17,
  IsDrill = 18,
  IsStopDrill = 19,
  IsStatic = 20,
  IsStopStatic = 21,
  IsMimic = 22,
  IsStopMimic = 23,
  IsStun = 24,
  IsStopStun = 25,
  UseSkillCountered = 26,
  IsCatchDrill = 27,
  IsCatchStatic = 28,
  IsCatchMimic = 29,
  CheerPetEnter = 30,
  PetJoin1VN = 31,
  CheerPetEscape = 32,
  IsStopLeaderStun = 33,
  IsThunder = 34,
  TeamCatch = 35
}
BattleEnum.PopupShowType = {
  Normal = 0,
  IsCritical = 1,
  IsRestraint = 2,
  IsRestrainted = 4,
  IsHeal = 8
}
BattleEnum.StateNames = {
  PvePreInit = "PvePreInit",
  WildPreInitState = "WildPreInitState",
  PvpPreInit = "PvpPreInit",
  BeastPreInit = "BeastPreInit",
  Init = "Init",
  NormalEnter = "NormalEnter",
  SeamlessEnter = "SeamlessEnter",
  NearbyEnter = "NearbyEnter",
  PveNearbyEnter = "PveNearbyEnter",
  NearbyReconnectEnter = "NearbyReconnectEnter",
  LeaderEnter = "LeaderEnter",
  LeaderReconnectEnter = "LeaderReconnectEnter",
  ThrowBallEnter = "ThrowBallEnter",
  ThrowBallReconnectEnter = "ThrowBallReconnectEnter",
  PVEEnter = "PVEEnter",
  PVPEnter = "PVPEnter",
  PVPReconnectEnter = "PVPReconnectEnter",
  NpcChallengeEnter = "NpcChallengeEnter",
  NpcChallengeReconnectEnter = "NpcChallengeReconnectEnter",
  WeeklyChallengeEnter = "WeeklyChallengeEnter",
  WeeklyChallengeReconnectEnter = "WeeklyChallengeReconnectEnter",
  TrainBattleEnter = "TrainBattleEnter",
  TrainBattleReconnectEnter = "TrainBattleReconnectEnter",
  TrainBattleOver = "TrainBattleOver",
  TeamBloodEnter = "TeamBloodEnter",
  TeamBloodReconnectEnter = "TeamBloodReconnectEnter",
  TeamBeastEnter = "TeamBeastEnter",
  TeamBeastReconnectEnter = "TeamBeastReconnectEnter",
  FinalBattleEnter = "FinalBattleEnter",
  FinalBattleReconnectEnter = "FinalBattleReconnectEnter",
  FinalBattleToP2 = "FinalBattleToP2",
  FinalBattleOver = "FinalBattleOver",
  B1FinalBattleP1Enter = "B1FinalBattleP1Enter",
  B1FinalBattleP1ReconnectEnter = "B1FinalBattleP1ReconnectEnter",
  B1FinalBattleP1ToP2 = "B1FinalBattleP1ToP2",
  B1FinalBattleP2ToP3 = "B1FinalBattleP2ToP3",
  B1FinalBattleP3FinalSkill = "B1FinalBattleP3FinalSkill",
  B1FinalBattleOver = "B1FinalBattleOver",
  FinalBattleEnterSpeedUp = "FinalBattleEnterSpeedUp",
  RoleShow = "RoleShow",
  ThrowBallRoleShow = "ThrowBallRoleShow",
  LeaderRoleShow = "LeaderRoleShow",
  WorldLeaderRoleShow = "WorldLeaderRoleShow",
  Standby = "Standby",
  PrePlay = "PrePlay",
  SwapSelect = "SwapSelect",
  SelectRidPet = "SelectRidPet",
  EvolutionSelect = "EvolutionSelect",
  NpcAutoEscapeSelect = "NpcAutoEscapeSelect",
  SwapPlay = "SwapPlay",
  RoundSelect = "RoundSelect",
  StartInstant = "StartInstant",
  RoundPlay = "RoundPlay",
  CatchSuccess = "CatchSuccess",
  EnemyEscape = "EnemyEscape",
  EnemyNpcEscape = "EnemyNpcEscape",
  NormalOver = "NormalOver",
  DirectOver = "DirectOver",
  FailOver = "FailOver",
  SeamlessOver = "SeamlessOver",
  WorldLeaderSeamlessOver = "WorldLeaderSeamlessOver",
  WorldLeaderRunAwayState = "WorldLeaderRunAwayState",
  Destroy = "Destroy",
  EnterPerform = "EnterPerform",
  EnterNoPC = "EnterNoPC",
  EnterLeaderPerform = "EnterLeaderPerform",
  PVERoleShow = "PVERoleShow",
  PVESpecialDelayRoleShowState = "PVESpecialDelayRoleShowState",
  PVPRoleShow = "PVPRoleShow",
  LeaveBattlePureBlackOut = "LeaveBattlePureBlackOut",
  WaitingOther = "WaitingOther",
  PVPOver = "PVPOver",
  PVPRankOver = "PVPRankOver",
  TeamBloodBattleOver = "TeamBloodBattleOver",
  TeamBattleCatch = "TeamBattleCatch",
  TeamBeastBattleOver = "TeamBeastBattleOver",
  TeamBeastBattleCatch = "TeamBeastBattleCatch",
  TeamBeastDefeatState = "TeamBeastDefeatState",
  PlayerSkillEscape = "PlayerSkillEscape",
  RevertTeamBattleState = "RevertTeamBattleState",
  ReBuildBattleFieldState = "ReBuildBattleFieldState",
  PVESpecialDelayEnterState = "PVESpecialDelayEnterState",
  PvpPlayerPerform = "PvpPlayerPerform",
  NpcChallengeOver = "NpcChallengeOver",
  TerritoryTrialOver = "TerritoryTrialOver",
  TerritoryTrialAgain = "TerritoryTrialAgain",
  WaitOtherLoad = "WaitOtherLoad",
  WeeklyChallengeOver = "WeeklyChallengeOver",
  WeeklyChallengeAgain = "WeeklyChallengeAgain"
}
BattleEnum.WaitStates = {
  "Standby",
  "WaitingOther"
}
BattleEnum.AtomicStates = {
  "Init",
  "NormalEnter",
  "SeamlessEnter",
  "EnterPerform",
  "RoleShow",
  "ThrowBallRoleShow",
  "PVPRoleShow",
  "PVERoleShow",
  "PrePlay",
  "SwapPlay",
  "RoundPlay",
  "EnemyEscape",
  "StartInstant",
  "NearbyReconnectEnter",
  "NearbyEnter",
  "LeaderEnter",
  "LeaderReconnectEnter",
  "ThrowBallEnter",
  "ThrowBallReconnectEnter",
  "PVPEnter",
  "PVPReconnectEnter",
  "TeamBattleCatch",
  "TeamBloodEnter",
  "TeamBloodReconnectEnter",
  "RevertTeamBattleState",
  "ReBuildBattleFieldState",
  "TeamBeastEnter",
  "TeamBeastReconnectEnter",
  "TeamBeastBattleCatch",
  "FinalBattleEnter",
  "PvePreInit",
  "WeeklyChallengeEnter",
  "WeeklyChallengeReconnectEnter",
  "TrainBattleEnter",
  "TrainBattleReconnectEnter",
  "TrainBattleOver",
  "BeastPreInit",
  "PvpPreInit",
  "FinalBattlePreInitState",
  "WorldLeaderRoleShow",
  "WildPreInitState",
  "B1FinalBattleP1Enter",
  "FinalBattleEnterSpeedUp",
  "TerritoryTrialOver",
  "TerritoryTrialAgain",
  "B1FinalBattleP1ToP2",
  "B1FinalBattleP2ToP3",
  "FinalBattleToP2",
  "FinalBattleReconnectEnter",
  "PveNearbyEnter"
}
BattleEnum.DestroyStates = {
  "NormalOver",
  "Destroy",
  "PlayerSkillEscape",
  "FailOver",
  "DirectOver",
  "WorldLeaderRunAwayState",
  "WeeklyChallengeAgain"
}
BattleEnum.RoundStateNames = {
  SkillState = "SkillState",
  SwapState = "SwapState",
  CatchState = "CatchState",
  PlayerSkillState = "PlayerSkillState",
  ItemState = "ItemState",
  EscapeState = "EscapeState",
  NoneState = "NoneState",
  SurrenderState = "SurrenderState",
  StepAwayState = "StepAwayState",
  GiveUpState = "GiveUpState"
}
BattleEnum.InstantBattleState = {
  InstantPlay = "InstantPlay"
}
BattleEnum.PerformNodeType = {
  Skill = "Skill",
  Buff = "Buff",
  BuffChange = "BuffChange",
  Effect = "Effect"
}
BattleEnum.ResCacheMode = {
  LowMemeory = 1,
  MiddleMemory = 2,
  HighMemory = 3
}
BattleEnum.BattleMode = {
  Normal = 1,
  Replay = 2,
  Observer = 3
}
BattleEnum.SubBattleType = {
  Single = 1,
  MultiPlayer = 2,
  MultiPet = 3
}
BattleEnum.SkillFailToCastReason = {
  Other = 1,
  IsBan = 2,
  LackHealth = 3,
  CD = 4,
  LackPP = 5,
  LackEnergy = 6,
  IsFeverBan = 7,
  IsLegendaryBan = 8,
  IsTeamBan = 9,
  IsSeal = 10
}
BattleEnum.SkillPanelExButtonState = {
  Other = 1,
  Idle = 2,
  RoleHp = 3
}
BattleEnum.PerformCmdValidCheckResult = {
  Success = 1,
  RefDeadLoop = 2,
  GroupIdxJump = 3,
  UnexpectedCM0 = 4
}
BattleEnum.PlayerSkillPhase = {
  NoSkill = 1,
  TryToActive = 2,
  TryToPetActive = 3,
  WaitingToPerform = 4
}
BattleEnum.CheerPetPerformState = {
  BeAttack = 1,
  AttackOther = 2,
  BeCatch = 3
}
BattleEnum.DeepWaterSwimState = {
  None = 0,
  WillIdle = 1,
  Idle = 2,
  Jumping = 3,
  JumpEnd = 4
}
BattleEnum.ContactEnterType = {
  None = 0,
  PetHit = 1,
  PlayerHit = 2,
  HitTogether = 3
}
BattleEnum.LeaderStunState = {
  Normal = 0,
  OneStar = 1,
  TwoStar = 2,
  ThreeStar = 3,
  FourStar = 4
}
BattleEnum.NpcAssistType = {
  None = 0,
  WithNpc = 1,
  WithPet = 2,
  Max = 4
}
BattleEnum.UmgBattleRoundStartDisplayType = {
  None = -1,
  RestRound = 0,
  CountDown = 1,
  Max = 2
}
BattleEnum.MainWindowHideAllType = {
  Default = 0,
  Custom = 1,
  RoundPlay = 2,
  TeamEnterCatch = 3,
  RebuildBattleField = 4
}
BattleEnum.HpLevelType = {
  None = -1,
  Red = 0,
  Yellow = 1,
  Green = 2,
  Max = 3
}
BattleEnum.CheckAppearanceMode = {NoLimit = 1, LimitByBattleMode = 2}
BattleEnum.CheerEnemyPosType = {OneVsN = 1, TerritoryTrial = 2}
BattleEnum.ShowBlackScreenReason = {
  Default = 0,
  NormalEnterBattle = 1,
  RestartEnterBattle = 2,
  ExitBattle = 3
}
BattleEnum.DiePerformType = {Default = 0, WithStun = 1}
BattleEnum.BloodItemRule = {
  Default = 0,
  DiMo = 1,
  BossPet = 2
}
BattleEnum.EnterBattleState = {
  Default = 0,
  InSky = 1,
  InSwim = 2
}
BattleEnum.BattleLodModel = {
  Auto = 0,
  Lod0 = 1,
  Lod1 = 2,
  Lod2 = 3,
  Lod3 = 4,
  Lod4 = 5
}
BattleEnum.RunAwayType = {
  TeamBeastNoCatch = 1,
  ClickEscape = 2,
  ClickGiveUp = 3,
  NoFsm = 4,
  NoCardInfo = 5,
  Debug = 6,
  Abandon = 7
}
return BattleEnum
