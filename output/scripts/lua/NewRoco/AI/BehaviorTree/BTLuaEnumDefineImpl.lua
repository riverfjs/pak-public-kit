local BattleNpcPetFilterTarget = {
  Current = 0,
  BattlePet_1 = 1,
  BattlePet_2 = 2,
  BattlePet_3 = 3,
  BattlePet_4 = 4
}
local BattleNpcPetFilterEfficient = {
  None = 0,
  MaxEfficient = 1,
  MinEfficient = 2,
  Max2Pet = 3
}
local BattleNpcPetFilterAttackFactor = {
  None = 100,
  SRT_x8 = 3,
  SRT_x4 = 2,
  SRT_x2 = 1,
  SRT_x1 = 0,
  SRT_x0_5 = -1,
  SRT_x0_25 = -2,
  SRT_x0_125 = -3
}
local BattleNpcPetFilterLocation = {
  None = 0,
  LOC_OFF_FIELD = 1,
  LOC_ON_FIELD = 2
}
local BattleNpcChangePetMode = {
  None = 0,
  PetID = 1,
  BattleID = 2,
  Filtered = 3
}
local PlayAnimationBlockingType = {
  None = 0,
  Begin = 1,
  LoopOnce = 2,
  Forever = 3
}
local NavFilterSettingType = {Inclusive = 0, Exclusive = 1}
local BattleChangeEnemyType = {PlayerEnemy = 0, PlayerMate = 1}
local BattleBuffOperator = {Add = 0, Remove = 1}
local BattleBuffTarget = {
  All_My = 0,
  All_Enemy = 1,
  Self = 2,
  Target = 3
}
local BattleTimerMode = {
  StartNew = 0,
  Reset = 1,
  Operate = 2
}
local BattleTimerOp = {Pause = 0, Resume = 1}
local BattleModifyPetListMode = {Add = 1, Remove = 2}
local EnumQueryBuffStackTarget = {Self = 0, CurTarget = 1}
local EnumQueryBuffStackBy = {
  Id = 0,
  Type = 1,
  Cover_Id = 2,
  Buff_Group_Sign = 3
}
local EnumBattleSkillFilterEventFilterType = {
  None = 0,
  Restraint = 1,
  Restrainted = 2
}
local EnumBattleSelectTargetRange = {
  Enemy = 0,
  Allay = 1,
  Both = 2
}
local EnumBattleSelectTargetMode = {
  Energy_max = 1,
  Energy_min = 2,
  HPRate_max = 3,
  HPRate_min = 4,
  HPNum_max = 5,
  HPNum_min = 6,
  Damage_max_available = 7,
  Pos_1 = 8,
  Pos_2 = 9,
  Pos_3 = 10,
  Pos_4 = 11
}
local EnumCheckSkillEventTargetSide = {
  Self = 0,
  SideA = 1,
  SideB = 2
}
local EnumCheckSkillEventTargetPos = {
  Self = 0,
  Pos1 = 1,
  Pos2 = 2,
  Pos3 = 3,
  Pos4 = 4
}
local EnumGetFollowPetType = {
  Nearest = 0,
  LastSpawn = 1,
  Random = 2
}
local EnumGetHomePetType = {
  NearestToPlayer = 0,
  NearestToSelf = 1,
  LastSpawn = 2,
  Random = 3
}
local EnumSearchPlayerType = {
  Nearest = 0,
  Furthest = 1,
  Random = 2
}
local EnumBehaviorProtectionMode = {
  Fsm = 1,
  Overwrite = 2,
  FsmAndOverWrite = 3,
  Group = 4
}
local EnumRandomPosWalkableStrategy = {
  None = 0,
  ToSelf = 1,
  ToTarget = 2,
  Both = 3,
  OnNav = 4
}
local EnumObtainPOIPointSelectType = {Random = 0, Sequence = 1}
local ReplaceBehavior = {
  Exit = 0,
  KeepOriginalMode = 1,
  UseQuadrantFollow = 2,
  UseChainFollow = 3
}
local EnumModifyFriendlinessMode = {
  Delta = 0,
  Set = 1,
  Steal = 2
}
local ECaptureRefreshFilterType = {SameHabitatGroup = 1, SameEvolutionChain = 2}
local ECaptureRefreshStatType = {
  TotalCaptureAttempts = 1,
  TotalCaptureSuccess = 2,
  TotalCaptureFailure = 3,
  CurrentNpcCount = 4,
  TotalRefreshableCount = 5
}
local EGetCatchInfoMethod = {FromHabitat = 0, FromEvochain = 1}
local EGetCatchInfoNumberType = {
  TotalCaptureAttempts = 0,
  TotalCaptureSuccess = 1,
  TotalCaptureFailure = 2,
  CurrentNpcCount = 3,
  TotalRefreshableCount = 4
}
local ESearchHabitatNpcType = {
  Specific = 0,
  Nearest = 1,
  SecondNearest = 2
}
local ESvrSkillFilterSelfDamageType = {
  None = 0,
  Self = 1,
  Other = 2
}
