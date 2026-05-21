local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local ProtoEnum = require("Data.PB.ProtoEnum")
local Enum = require("Data.Config.Enum")
local BattleConst = {}
BattleConst.CharacterIndex = {
  Player1 = 0,
  Player2 = 1,
  Player3 = 2,
  Player4 = 3,
  Player_Pet1 = 4,
  Player_Pet2 = 5,
  Player_Pet3 = 6,
  Player_Pet4 = 7,
  Enemy1 = 8,
  Enemy2 = 9,
  Enemy3 = 10,
  Enemy4 = 11,
  Enemy_Pet1 = 12,
  Enemy_Pet2 = 13,
  Enemy_Pet3 = 14,
  Enemy_Pet4 = 15
}
BattleConst.NPCOverBlendCamTime = 1
BattleConst.FindBattleCenterByClient = false
BattleConst.IsEnableArtSkillCam = true
BattleConst.IsOpenPlayerSkill = true
BattleConst.PET_MAX_EQUIP_SKILL_NUM = 4
BattleConst.DeepWaterHeight = 200
BattleConst.EnableSkyBattle = false
BattleConst.SkyPlatformHeight = 2500
BattleConst.ForceShowIdle = false
BattleConst.ForceShowSkillPrediction = true
BattleConst.CanBattleEverywhere = false
BattleConst.ForceWaterBattle = false
BattleConst.MoveToLegalLocationWhenBlock = true
BattleConst.PlayerFollowPet = true
BattleConst.AntiStuckMode = false
BattleConst.DonntHideTree = false
BattleConst.debugCloseHideScene = false
BattleConst.bUseBattleFieldMulity = true
BattleConst.BattleFadeSpeed = 10
BattleConst.AcceptanceRadius = 50
BattleConst.NpcAssistFadeTraceRadius = 150
BattleConst.NpcAssistFadeTraceShowDebugLine = false
BattleConst.EnableOpenSkillPredictionTips = false
BattleConst.EnterAnimName = {
  "Shock",
  "Anger",
  "Happy",
  "SleepStand",
  "Fear",
  "Alert",
  "DrillLoop",
  "StaticLoop",
  "Happy",
  "HideEnd",
  "Shock",
  "Stun",
  [20] = "Stun",
  [21] = "Stun",
  [22] = "Stun",
  [23] = "Stun"
}
BattleConst.BattleDepthCam = "/Game/NewRoco/Modules/Core/Battle/BattleDepthCam/BP_BattleDepthCam.BP_BattleDepthCam_C"
BattleConst.BattleCharacterMaskCamera = "/Game/NewRoco/Modules/Core/Battle/Camera/BP_BattleCharacterMaskCamera.BP_BattleCharacterMaskCamera_C"
BattleConst.CounterSkillPreFx = "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Nor_YDJ001.G6_Nor_YDJ001_C"
BattleConst.CounterSkillPreNpc = "/Game/ArtRes/Effects/G6Skill/NPC/G6_NPC_World_YingDui.G6_NPC_World_YingDui_C"
BattleConst.BPBall = "/Game/NewRoco/Modules/Core/NPC/PetBall/BP_NPCItemPetBall_A001.BP_NPCItemPetBall_A001_C"
BattleConst.BallPaths = {
  Default = "Blueprint'/Game/NewRoco/Modules/Core/NPC/PetBall/BP_NPCItemFairyBall_001.BP_NPCItemFairyBall_001_C'",
  None = "BattleConst.BallPaths.NoBall"
}
BattleConst.MimicRemove = "/Game/ArtRes/Effects/G6Skill/Pet_Hide/NiZong_HuanHua_End.NiZong_HuanHua_End_C"
BattleConst.BattleCrowdOnLookerPath = "Blueprint'/Game/NewRoco/Modules/Core/Battle/NPC/BP_BattleCrowdOnLooker.BP_BattleCrowdOnLooker_C'"
BattleConst.PetStateOverrideAnimName = {
  DrillLoop = "DrillLoop",
  StaticLoop = "StaticLoop",
  StunLoop = "Stun"
}
BattleConst.Define = {
  BattleFieldRange = 1500,
  FindNearbyEnemyMaxRange = 30000,
  BattleStandBPCla = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/Pet_In_Fight.Pet_In_Fight_C",
  BattleStandBackBPCla = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/Pet_In_FightBack.Pet_In_FightBack",
  ThrowBallAirEnterBPCla = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/Pet_In_Fight_ThrowBall_Air.Pet_In_Fight_ThrowBall_Air_C",
  ThrowBallGroundEnterBPCla = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/LongInFight_Ground.LongInFight_Ground_C",
  PveNPCLeaveBattleWin = "/Game/ArtRes/Effects/G6Skill/Chuzhandou/Player_Win_PVE_Happy.Player_Win_PVE_Happy_C",
  PveNPCLeaveBattleLose = "/Game/ArtRes/Effects/G6Skill/PVE/PVE_Fight_Lose.PVE_Fight_Lose_C",
  LeaderBattleShowTime = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/ShouLing",
  SleepResID = "/Game/ArtRes/Effects/G6Skill/Buff/BattleSleep",
  StunResID = "/Game/ArtRes/Effects/G6Skill/Buff/20040034",
  ThrowFrontEnterFirst = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_front_01",
  ThrowFrontEnterSecond = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_front_02",
  ThrowFrontEnterThree = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_front_03",
  ThrowBackEnterFirst = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_back_01",
  ThrowBackEnterSecond = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_back_02",
  ThrowBackEnterThree = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_back_03",
  NPCEnter = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/G6_WorldBattle_NPC",
  BattlePetRotationErrorCheck = 1,
  CATCH_SKILL_BATTLE = "/Game/ArtRes/Effects/G6Skill/Buzhuo/BuZhuo",
  CATCH_SKILL_BATTLE_LOW_RATE = "/Game/ArtRes/Effects/G6Skill/Buzhuo/BuZhuo_Lose",
  CATCH_SKILL_BATTLE_TEAM_BLOOD = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_BuZhuo",
  CATCH_SKILL_BATTLE_HUI_XIN = "/Game/ArtRes/Effects/G6Skill/Buzhuo/BuZhuo_HuiXin",
  CATCH_SKILL = "/Game/ArtRes/Effects/G6Skill/Buzhuo/G6_BuZhuo_All.G6_BuZhuo_All_C",
  LeaderHitShow = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_JinZhan_01",
  LeaderBattleEnterShow = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_ZhuanChang",
  LeaderBattleEnterShow1 = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_ZhuanChang01"
}
BattleConst.HideObjectParam = {
  DonntHideSizeX = 2000,
  DonntHideSizeY = 2000,
  DonntHideSizeZ = 2000,
  DonntHideVolume = 1000000000,
  HideGrassDist = 2000,
  ExitBattleShowGrassDist = 200
}
BattleConst.BattleTypeToBattleFieldRangeMultiplier = {
  [ProtoEnum.BattleType.BT_INVALID] = 1,
  [ProtoEnum.BattleType.BT_TERRITORY_TRIAL] = 2
}
BattleConst.BattleStand = {
  CameraID1 = "camActor_0001",
  CameraID1_SA = "camActor_0001_SA",
  CameraID2 = "camActor_0002",
  CameraID2_SA = "camActor_0002_SA",
  CameraRoot = "camActorRoot"
}
BattleConst.BattleThrowBallEnter = {
  CameraID1 = "camActor_0001",
  CameraID1_SA = "camActor_0001_SA",
  CameraID2 = "camActor_0002",
  CameraID2_SA = "camActor_0002_SA"
}
BattleConst.Show = {
  BattlePlayStageDelayTime = 0.5,
  CounterRestartLastSkillDelayFrame = 50,
  CounterSkillTimeDilation = 0.05,
  InterruptSkillTimeDilation = 0.01,
  ZeroTimeDilation = 1.0E-5,
  HitTimeDilation = 0.12,
  HitTimeDilationTime = 0.72,
  RestoreCameraBlendTime = 0,
  PlayerToPetCameraBlendTIme = 0.5,
  SkillCameraTime = 0.5,
  BattlePetRelaxDuration = 0.1,
  IdleHudHintTime = 3,
  PveRoleHpShowTime = 0.2,
  PveRoleHpShowTimeOnRunAway = 1,
  PveRoleHpShineTime = 1,
  RoleHpCriticalShowTime = 1,
  RoleHpDefeatTipShowTime = 3,
  PetHpDelayChangeTimeOnAttackHit = 0.55
}
BattleConst.DynamicBattle = {
  PlayerMinMovementLength = 200,
  WaitPlayerTranslationTime = 0.1,
  WaitPlayerRotationTime = 0.5,
  PlayerMaxMovementSpeed = 4000
}
BattleConst.MultiplayerBattle = {ComboAttackDelay = 1}
BattleConst.ACAnimNamePlayer = {BattleRun = "Run"}
BattleConst.AnimNamePlayer_Idle = {Idle = "Stand2"}
BattleConst.PlayerShow = {
  Cam = "camActor_0002",
  Cam_SA = "camActor_0002_SA"
}
BattleConst.ModelOffset = {TipTimeOffsetZ = -20, SelectorMarker3dOffsetZ = -20}
BattleConst.InPlace = {
  SkillOne = "/Game/ArtRes/Effects/G6Skill/Yuchong/780001_2",
  SkillTwo = "/Game/ArtRes/Effects/G6Skill/Yuchong/780001_3",
  PetAnim = "Born",
  PetAnimRate = 0.05,
  PetAnimStart = 0.86667,
  PetAnimEnd = 1.84,
  PetAnimBlendIn = 0,
  PetAnimBlendOut = 0.5,
  PetAnimLoop = -1,
  BGFX = "DefaultAnimationMesh_1",
  Cam1 = "camActor_0001",
  Cam1_SA = "camActor_0001_SA",
  Cam3 = "camActor_0003",
  Cam3_SA = "camActor_0003_SA",
  SlideOut = "Yuchong_Out",
  SlideIn = "Yuchong_In",
  Start = "Start",
  Hide = "Hide",
  End = "End",
  Enter = "EnterBattle",
  AirTime = 0.5
}
BattleConst.SkillID = {
  PlayerShow = 791101,
  EnemyShow = 791001,
  PlayerChangePet = 791102,
  CmdStageCameraShow = 0,
  PlayStageCameraShow = 0,
  PlayStageAttackCameraShow = 0,
  PlayStageAttackResetCameraShow = 0,
  PlayStageBuffCameraShow = 0,
  PlayStageBuffResetCameraShow = 0,
  FocusCatchPetCameraShow = 0,
  FocusCatchPetResetCameraShow = 0,
  RecallPet = 791214,
  PetDead = 791215,
  PetDeadWithPlayer = 791212,
  PetDeadWithPlayerTeam = 791211,
  PetDeadWithPlayerEnemy = 791212,
  CatchPetSucc = 791201,
  CatchPetFailed = 791205,
  SettlementWin = 791216,
  SettlementLose = 791217,
  HighlightBag = 791227,
  LeaveBattleField = 791233,
  PlayerLose = 791334,
  IdleSkillID = 700013,
  RoleEnergySkillID = 700014,
  PetChangeModel = 791335,
  PetChangeModelNoEffect = 791336
}
BattleConst.SkillObjData = {
  DamageType = {
    Key = "DamageType",
    TYPE_NORMAL = 1,
    TYPE_RESTRAINT = 2,
    TYPE_RESIST = 3
  },
  DefaultBlackboardParam = {
    MultiAtkFirstPass = "SegFirstPass",
    MultiAtkLoop = "SegLoop",
    MultiAtkEnd = "SegEnd"
  }
}
BattleConst.BuffId = {
  LeaderStun0 = 20040032,
  LeaderStun1 = 20040030,
  LeaderStun2 = 20040031,
  LeaderStun3 = 20040033,
  LeaderStun4 = 20040034,
  LeaderStunBaseId = 2004003,
  DeadBombBuff = 20380140
}
BattleConst.EnemyRecallPet = "/Game/ArtRes/Effects/G6Skill/huishou/CallBack_HuanChong_Enemy"
BattleConst.PetDeadBlowAway = "/Game/ArtRes/Effects/G6Skill/Jineng/G6_win_CF_20480010"
BattleConst.PetDeadBomb = "/Game/ArtRes/Effects/G6Skill/Jineng/G6_None"
BattleConst.PetDeadFinalBattle = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Battle_CW_Exit"
BattleConst.PetDeadNoPc = "/Game/ArtRes/Effects/G6Skill/huishou/CallBack_Monster_Lose_NoPC"
BattleConst.PetDeadWithStun = "/Game/ArtRes/Effects/G6Skill/huishou/CallBack_Monster_Lose_Stun.CallBack_Monster_Lose_Stun_C"
BattleConst.PetDeadWithStunNoBall = "/Game/ArtRes/Effects/G6Skill/huishou/CallBack_Monster_Lose_Stun_2.CallBack_Monster_Lose_Stun_2_C"
BattleConst.NightmarePetDeadWithStun = "/Game/ArtRes/Effects/G6Skill/huishou/CallBack_Monster_Lose_Stun_3.CallBack_Monster_Lose_Stun_3_C"
BattleConst.FinalBattleBossDieBeforeBlackScreenTimeSpan = 1
BattleConst.EnemyDeadFinalBattleBlackScreen = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Btatt_BlackCam"
BattleConst.EnemyDeadFinalBattleBlackFadeOut = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Btatt_BlackCam_End"
BattleConst.FinalBattleBossDieBlackScreenTimeSpan = 1
BattleConst.FinalBattleBossDieBeforeBulletTimeSpan = 0
BattleConst.FinalBattleBossDieBulletTimeSpan = 1
BattleConst.FinalBattleBossDieBulletTimeCurve = "/Game/NewRoco/Modules/Core/Battle/Curve/FinalBattleBossDieBulletTimeCurve.FinalBattleBossDieBulletTimeCurve"
BattleConst.AttackHitSpeedCurve = "/Game/NewRoco/Modules/Core/Battle/Curve/CF_ComboPlayRae.CF_ComboPlayRae"
BattleConst.BattlePlayerLeaveBattleFadeOut = "/Game/ArtRes/Effects/G6Skill/PVE/PVE_NPC_Xray"
BattleConst.TeamBloodPerEnterBattle = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_1"
BattleConst.TeamBloodEnterSkill = {
  "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_2",
  "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_3",
  "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_5",
  "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_5_1",
  "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_6"
}
BattleConst.TeamBloodBeDefeated = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_7.G6_XueMai_TeamBattle_7_C"
BattleConst.TeamBloodBossEffect = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_9.G6_XueMai_TeamBattle_9_C"
BattleConst.TeamBloodCatchSuccess = "/Game/ArtRes/Effects/G6Skill/Buzhuo/G6_BuZhuo_Win_Cam.G6_BuZhuo_Win_Cam_C"
BattleConst.TeamBeastEnterSkill = {
  "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_3",
  "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_CallOut"
}
BattleConst.TeamBeastPerEnterBattle = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_Transmit_Battle"
BattleConst.TeamBeastBeStun = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_5"
BattleConst.TeamBeastBeDefeated = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_Die_LiAo3"
BattleConst.TeamBeastAfterBeDefeated = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_6_Hit3"
BattleConst.TeamBeastBeSPColor1 = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_7.G6_ShenShou_TeamBattle_7_C"
BattleConst.TeamBeastBeSPColor2 = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_8"
BattleConst.TeamBeastDegrade = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_tuihua.G6_ShenShou_tuihua_C"
BattleConst.TeamBattleBalance = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_Balance_1.G6_XueMai_TeamBattle_Balance_1_C"
BattleConst.TeamBattleBalanceLens = "/Game/ArtRes/Effects/G6Skill/XueMai/G6_XueMai_TeamBattle_Balance_2.G6_XueMai_TeamBattle_Balance_2_C"
BattleConst.TeamBeastShiny = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_XuancaiYibian.G6_ShenShou_XuancaiYibian_C"
BattleConst.WorldLeaderFailExit = {
  "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_End_01",
  "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_End_02"
}
BattleConst.WorldLeaderSuccessExit = {
  "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_End_Die_Yes",
  "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_End_Die_02"
}
BattleConst.WorldLeaderDie = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_BossBattle_End_Die_01"
BattleConst.WorldLeaderEnterReward = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/G6_Scene_BossBattle_Jipo.G6_Scene_BossBattle_Jipo"
BattleConst.TeamPerEnterFarBattle = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_TeamBattle_01"
BattleConst.BloodTeamEnterFarBattle = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ChuanSong"
BattleConst.BuffOrderGroup = 15
BattleConst.UIInfoSettings = {DescSpecialPatternEnv = "@ENV", DescSpecialPatternAcs = "@ACS"}
BattleConst.SoundId = {
  BattleLoading = 1018,
  CloseLoading = 1220002136,
  RecallPet = 1020
}
BattleConst.ComPassSkill = {
  ComPassLoop = "/Game/ArtRes/Effects/G6Skill/DaojuUse/DaoJu_ZhuJueMoFa_DaoJu_ZJ"
}
BattleConst.Highlight = {
  PetStart = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226.791226_C",
  PetLoopOne = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226_1",
  PetLoopTwo = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226_1"
}
BattleConst.HighlightLoop = {
  PetStart = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226_ALL.791226_ALL_C"
}
BattleConst.PetTransparentNames = {
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/791229",
  LoopOne = "/Game/ArtRes/Effects/G6Skill/Zhiling/791229_1",
  LoopTwo = "/Game/ArtRes/Effects/G6Skill/Zhiling/791229_2"
}
BattleConst.ZhaoHuan = "/Game/ArtRes/Effects/G6Skill/zhaohuan/1_DR_ZhaoHuan.1_DR_ZhaoHuan_C"
BattleConst.NpcAssistZhaoHuan = "/Game/ArtRes/Effects/G6Skill/zhaohuan/2V2_ZhaoHuan_NPC_06101.2V2_ZhaoHuan_NPC_06101_C"
BattleConst.HuanChong = "/Game/ArtRes/Effects/G6Skill/zhaohuan/1_DR_HuanChong"
BattleConst.TeamNpcHuanChong = "/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_NPC_CallOut"
BattleConst.NoBallHuanChong = "/Game/ArtRes/Effects/G6Skill/zhaohuan/G6_Effect"
BattleConst.NPCHuanChong = "/Game/ArtRes/Effects/G6Skill/PVE/PVE_Fight_HuanCong_ZhuZhan.PVE_Fight_HuanCong_ZhuZhan_C"
BattleConst.EnemyZhaoHuan = "/Game/ArtRes/Effects/G6Skill/PVP/NPC_Fight_Start_3"
BattleConst.EnemyHuanChong = "/Game/ArtRes/Effects/G6Skill/PVE/PVE_Fight_HuanCong_Enemy"
BattleConst.FinalBattleHuanChong = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Battle_CW_Relay"
BattleConst.FinalBattleP2Debut = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Debut"
BattleConst.FinalBattleOverSeq1 = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ08/JQ08_CS05_a/JQ08_CS05_a_Master.JQ08_CS05_a_Master"
BattleConst.FinalBattleOverSeq2 = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ08/JQ08_CS05_b/JQ08_CS05_b_Master.JQ08_CS05_b_Master"
BattleConst.FinalBattleP1EnterSeq = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ08/JQ08_CS05_2/JQ08_CS05_2_010.JQ08_CS05_2_010"
BattleConst.FinalBattleP1EnterG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_CS05_2.G6_A1_CS05_2_C"
BattleConst.FinalBattleP1ToP2Seq = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ08/JQ08_CS06/JQ08_CS06_Master.JQ08_CS06_Master"
BattleConst.FinalBattleP1ToP2G6 = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_CS06.G6_A1_CS06"
BattleConst.B1P1EnterSequence = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ11/JQ11_CS21/JQ11_CS21_Master.JQ11_CS21_Master"
BattleConst.B1P1EnterG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_PC_Start"
BattleConst.B1P1EnterG6Reconnect = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_PC_Start_Reconnect"
BattleConst.B1P1EnemyDeadG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_PC_Die"
BattleConst.B1P1EnemyCallOutG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_PC_BossCallOut"
BattleConst.B1P1EndG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_PC_End"
BattleConst.B1BallBlackboardKey = "B1BallBP"
BattleConst.B1P2EnterSequence = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ11/JQ11_CS22/JQ11_CS22_Master.JQ11_CS22_Master"
BattleConst.B1P2EnterG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_FLY_Start"
BattleConst.B1P3TwoPetCamG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_2Pet_Cam.G6_B1_Battle_2Pet_Cam_C"
BattleConst.B1P3EnterG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_4V1_Start"
BattleConst.B1P3EvolutionG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_Evolution_Anim01_FLY"
BattleConst.B1P3BossDeadG6 = "/Game/ArtRes/Effects/G6Skill/Jineng/B1/G6_B1_Battle_4V1_End"
BattleConst.B1P3OverSequence = "/Game/ArtRes/AnimSequence/Sequence/Plot/JQ/JQ11/JQ11_CS22/JQ11_CS22_Master.JQ11_CS22_Master"
BattleConst.FocusPet = "/Game/ArtRes/Effects/G6Skill/PVE/FocusPet.FocusPet_C"
BattleConst.PerFormComPassSkill = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {},
    Start = BattleConst.ComPassSkill.ComPassLoop
  }
}
BattleConst.PetHighlight = {
  IsPassive = true,
  Sequence = {
    States = {
      [BattleConst.Highlight.PetStart] = {
        Next = BattleConst.Highlight.PetLoopOne
      },
      [BattleConst.Highlight.PetLoopOne] = {
        Next = BattleConst.Highlight.PetLoopTwo
      },
      [BattleConst.Highlight.PetLoopTwo] = {
        Next = BattleConst.Highlight.PetLoopOne
      }
    },
    Start = BattleConst.Highlight.PetStart
  }
}
BattleConst.PetHighlightLoop = {
  IsPassive = true,
  Sequence = {
    States = {
      [BattleConst.HighlightLoop.PetStart] = {
        Next = BattleConst.HighlightLoop.PetStart
      }
    },
    Start = BattleConst.HighlightLoop.PetStart
  }
}
BattleConst.PetTransparent = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.PetTransparentNames.Start] = {
        Next = BattleConst.PetTransparentNames.LoopOne
      },
      [BattleConst.PetTransparentNames.LoopOne] = {
        Next = BattleConst.PetTransparentNames.LoopTwo
      },
      [BattleConst.PetTransparentNames.LoopTwo] = {
        Next = BattleConst.PetTransparentNames.LoopOne
      }
    },
    Start = BattleConst.PetTransparentNames.Start
  }
}
BattleConst.BagHighlightNames = {
  BagStart = "/Game/ArtRes/Effects/G6Skill/Zhiling/791227",
  BagLoopOne = "/Game/ArtRes/Effects/G6Skill/Zhiling/791227_1",
  BagLoopTwo = "/Game/ArtRes/Effects/G6Skill/Zhiling/791227_2"
}
BattleConst.BagHighlight = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.BagHighlightNames.BagStart] = {
        Next = BattleConst.BagHighlightNames.BagLoopOne
      },
      [BattleConst.BagHighlightNames.BagLoopOne] = {
        Next = BattleConst.BagHighlightNames.BagLoopTwo
      },
      [BattleConst.BagHighlightNames.BagLoopTwo] = {
        Next = BattleConst.BagHighlightNames.BagLoopOne
      }
    },
    Start = BattleConst.BagHighlightNames.BagStart
  }
}
BattleConst.DarkSceneNames = {
  StartDark = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark",
  EndDark = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_3",
  DarkLoopOne = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_1",
  DarkLoopTwo = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_1"
}
BattleConst.DarkScene = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    Start = BattleConst.DarkSceneNames.StartDark,
    End = BattleConst.DarkSceneNames.EndDark,
    States = {
      [BattleConst.DarkSceneNames.StartDark] = {}
    }
  }
}
BattleConst.CharacterDarkNames = {
  StartDark = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_4",
  EndDark = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_7",
  DarkLoopOne = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_5",
  DarkLoopTwo = "/Game/ArtRes/Effects/G6Skill/Zhiling/791226Dark_5"
}
BattleConst.CharacterDark = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    Start = BattleConst.CharacterDarkNames.StartDark,
    End = BattleConst.CharacterDarkNames.EndDark,
    States = {
      [BattleConst.CharacterDarkNames.StartDark] = {}
    }
  }
}
BattleConst.TakeBallNames = {
  Name = "_ID_AUTOGENERATE_BALL0",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/791232",
  SwapBall = "/Game/ArtRes/Effects/G6Skill/Zhiling/791232_1"
}
BattleConst.TakeBallNoBlendNames = {
  Name = "_ID_AUTOGENERATE_BALL0",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/791232_n",
  SwapBall = "/Game/ArtRes/Effects/G6Skill/Zhiling/791232_1"
}
BattleConst.TakeBall = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.TakeBallNames.Start] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeBallNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.TakeBallNames.SwapBall] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeBallNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.TakeBallNames.Start
  }
}
BattleConst.TakeBallNoBlend = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.TakeBallNoBlendNames.Start] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeBallNoBlendNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.TakeBallNoBlendNames.SwapBall] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeBallNoBlendNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.TakeBallNoBlendNames.Start
  }
}
BattleConst.TakeItemNames = {
  Name = "_ID_AUTOGENERATE_ITEM",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/item_start",
  SwapItem = "/Game/ArtRes/Effects/G6Skill/Zhiling/item_swap"
}
BattleConst.TakeItem = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.TakeItemNames.Start] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeItemNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.TakeItemNames.SwapItem] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeItemNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.TakeItemNames.Start
  }
}
BattleConst.TakeItemFromCompassNames = {
  Name = "_ID_AUTOGENERATE_ITEM",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/item_daoju",
  SwapItem = "/Game/ArtRes/Effects/G6Skill/Zhiling/item_swap"
}
BattleConst.TakeItemCamera = {
  Name = "_ID_AUTOGENERATE_ITEM",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/DaoJu_Loop.DaoJu_Loop_C",
  AngleFactor = 20,
  LocationUpper = -215,
  AngleUpper = 39,
  LocationLower = 65,
  AngleLower = -8
}
BattleConst.CatchPetCamera = {
  Name = "_ID_AUTOGENERATE_ITEM",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/BuZhuo_Loop.BuZhuo_Loop_C",
  AngleFactor = 20,
  LocationUpper = -157,
  AngleUpper = 25,
  LocationLower = 25.4,
  AngleLower = -6
}
BattleConst.TakeItemFromCompass = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.TakeItemFromCompassNames.Start] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeItemFromCompassNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.TakeItemFromCompassNames.SwapItem] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeItemFromCompassNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.TakeItemFromCompassNames.Start
  }
}
BattleConst.TakeCompassNames = {
  Name = "_ID_AUTOGENERATE_ITEM",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/Compass_start",
  SwapItem = "/Game/ArtRes/Effects/G6Skill/Zhiling/Compass_swap"
}
BattleConst.TakeCompass = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.TakeCompassNames.Start] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeCompassNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.TakeCompassNames.SwapItem] = {
        SaveVars = {
          Item = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.TakeCompassNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.TakeCompassNames.Start
  }
}
BattleConst.CatchPetNames = {
  Name = "_ID_AUTOGENERATE_BALL0",
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/791233_0",
  SwapBall = "/Game/ArtRes/Effects/G6Skill/Zhiling/791233_1"
}
BattleConst.CatchPet = {
  IsPassive = true,
  Sequence = {
    IsPassive = true,
    States = {
      [BattleConst.CatchPetNames.Start] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.CatchPetNames.Name,
            Keep = true
          }
        }
      },
      [BattleConst.CatchPetNames.SwapBall] = {
        SaveVars = {
          Ball = {
            Trigger = {
              "End",
              "Interrupt",
              "Bind"
            },
            Name = BattleConst.CatchPetNames.Name,
            Keep = true
          }
        }
      }
    },
    Start = BattleConst.CatchPetNames.Start
  }
}
BattleConst.RunAwayNames = {
  Start = "/Game/ArtRes/Effects/G6Skill/Zhiling/791231"
}
BattleConst.RunAway = {
  Sequence = {
    States = {
      [BattleConst.RunAwayNames.Start] = {}
    },
    Start = BattleConst.RunAwayNames.Start
  }
}
BattleConst.CameraTransTime = 0.5
BattleConst.HandheldShake = "/Game/NewRoco/Modules/Core/Battle/BP_HandheldShake.BP_HandheldShake_C"
BattleConst.HandheldWaterShake = "/Game/NewRoco/Modules/Core/Battle/BP_HandheldShake_Water.BP_HandheldShake_Water_C"
BattleConst.UI = {
  UMG_Battle_DamageGeneral = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_General.UMG_Battle_Popup_General_C",
  UMG_Battle_HealNumber = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_HealNumber",
  UMG_Battle_Miss = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_Miss",
  UMG_Battle_BuffEffectDown = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_Buff_GJJD",
  UMG_Battle_BuffEffectUp = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_Buff_WFTG.UMG_Battle_Popup_Buff_WFTG_C",
  UMG_Battle_Common_1 = "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_BuffCommon_1.UMG_Battle_Popup_BuffCommon_1_C",
  UMG_Battle_Buff = "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_Buff.UMG_Battle_Buff_C",
  UMG_Battle_Card = "/Game/NewRoco/Modules/System/BattleUI/Res/PlayerDeck/UMG_Battle_DeckCard",
  UMG_Battle_EnergyTrack = "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_EnergyTrack.UMG_Battle_EnergyTrack",
  UMG_Battle_SpEnergy_FlyTrack = "/Game/NewRoco/Modules/System/BattleUI/Res/Skill/UMG_Battle_SpEnergy_FlyTrack",
  UMG_Battle_Skill_Prediction = "/Game/NewRoco/Modules/System/BattleUI/Res/Hints/UMG_Hints_Fighting"
}
BattleConst.PlayerTurnAnim = {
  [BattleEnum.Operation.ENUM_CATCH] = {
    [BattleEnum.Operation.ENUM_ITEM] = "BuzhuoToDaoju",
    [BattleEnum.Operation.ENUM_CHANGE] = "BuzhuoToHuangChong"
  },
  [BattleEnum.Operation.ENUM_ITEM] = {
    [BattleEnum.Operation.ENUM_CHANGE] = "DaojuToHuanChong",
    [BattleEnum.Operation.ENUM_CATCH] = "DaojuToBuzhuo"
  },
  [BattleEnum.Operation.ENUM_CHANGE] = {
    [BattleEnum.Operation.ENUM_CATCH] = "HuanChongToBuzhuo",
    [BattleEnum.Operation.ENUM_ITEM] = "HuanChongToDaoju"
  }
}
BattleConst.PlayerFinalAnim = {
  [BattleEnum.Operation.ENUM_CATCH] = "BuZhuoLoop",
  [BattleEnum.Operation.ENUM_ITEM] = "DaoJuLoop",
  [BattleEnum.Operation.ENUM_CHANGE] = "HuanChongLoop"
}
BattleConst.BattleFieldActorPath = "/Game/NewRoco/Modules/Core/Battle/BP_BattleFieldActor"
BattleConst.NumToText = "\228\184\128\228\186\140\228\184\137\229\155\155\228\186\148\229\133\173\228\184\131\229\133\171\228\185\157\229\141\129"
BattleConst.EnemyEscape = {
  SkillPath = "/Game/ArtRes/Effects/G6Skill/Pet_Escape/Pet_Escape.Pet_Escape_C",
  SkillPathNpc1 = "/Game/ArtRes/Effects/G6Skill/Chuzhandou/NPC_Fight_Lose_1.NPC_Fight_Lose_1_C",
  SkillPathNpc2 = "/Game/ArtRes/Effects/G6Skill/Chuzhandou/NPC_Fight_Lose_2.NPC_Fight_Lose_2_C",
  ThunderSkillPath = "/Game/ArtRes/Effects/G6Skill/Pet_Escape/Pet_Escape.Pet_Escape_C",
  DivingSkillPath = "/Game/ArtRes/Effects/G6Skill/Pet_Escape/Pet_Escape.Pet_Escape_C"
}
BattleConst.NpcAutoEscapeSkillDebug = 1
BattleConst.UseItem = {
  SkillPath = "/Game/ArtRes/Effects/G6Skill/DaojuUse/DaoJuUse"
}
BattleConst.PveEnter = {
  TwoPlayerSkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_FightStart_Player.PVP_FightStart_Player_C",
  TwoEnemySkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_FightStart_Enemy.PVP_FightStart_Enemy_C",
  OneEnemyPetAppearanceCallout = "/Game/ArtRes/Effects/G6Skill/PVP/NPC_Fight_Start_Pet"
}
BattleConst.PvPEnter = {
  TwoPlayerSkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_FightStart_Player.PVP_FightStart_Player_C",
  TwoEnemySkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_FightStart_Enemy.PVP_FightStart_Enemy_C",
  TwoPlayerPetSkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_Start_PlayerPet.PVP_Fight_Start_PlayerPet_C",
  TwoEnemyPetSkill_C = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_Start_EnemyPet.PVP_Fight_Start_EnemyPet_C"
}
BattleConst.PvpPlayerPerform = {
  [1] = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_WanSha.PVP_Fight_WanSha_C",
  [2] = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_YingDui.PVP_Fight_YingDui_C",
  [3] = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_LianSha.PVP_Fight_LianSha_C",
  [4] = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_JueZhan.PVP_Fight_JueZhan_C"
}
BattleConst.PVPPrepareEnter = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_Entry.PVP_Fight_Entry_C"
BattleConst.WaterBattleEffect = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Skill/Common/NS_BF_Water_CJ_Smoke.NS_BF_Water_CJ_Smoke'"
BattleConst.PVPOver = "/Game/ArtRes/Effects/G6Skill/PVP/PVP_Fight_Win.PVP_Fight_Win"
BattleConst.PVPWinOver = "/Game/ArtRes/Effects/G6Skill/UI/G6_UI_JieSuan"
BattleConst.PVPLoseOver = "/Game/ArtRes/Effects/G6Skill/UI/G6_UI_JieSuanEnemy"
BattleConst.LeaderChallengeWinOver = "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_Dare_Win.G6_Dare_Win_C"
BattleConst.LeaderChallengeLoseOver = "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_Dare_Lose.G6_Dare_Lose_C"
BattleConst.LeaderChallengeMuBuStart = "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_Dare_MuBu_Start.G6_Dare_MuBu_Start_C"
BattleConst.Replay = {
  ReplaySpeedFast = 2,
  ReplaySpeedFastNormal = 1,
  ReplaySpeedSlow = 0.5
}
BattleConst.Evolution = {
  PetEvolutionWait = "/Game/ArtRes/Effects/G6Skill/Evolution/G6_Evolution_Wait.G6_Evolution_Wait",
  PetEvolutionAnim = "/Game/ArtRes/Effects/G6Skill/Evolution/EvolutionAnim",
  PetEvolutionAnimCenter = "/Game/ArtRes/Effects/G6Skill/Evolution/EvolutionAnim_Center.EvolutionAnim_Center_C",
  PetEvolutionAnimWorldStart = "/Game/ArtRes/Effects/G6Skill/Evolution/EvolutionAnimWorld_Start.EvolutionAnimWorld_Start",
  PetEvolutionAnimWorldEnd = "/Game/ArtRes/Effects/G6Skill/Evolution/G6_Evolution_Anim01_Battle.G6_Evolution_Anim01_Battle"
}
BattleConst.SpEnergy = {
  WeatherSrcPath = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Common/CP_ShiNeng_Sky_01.CP_ShiNeng_Sky_01'",
  GroundSrcPath = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Common/CP_ShiNeng_GD_01.CP_ShiNeng_GD_01'",
  AttackSrcPath = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Common/CP_ShiNeng_Enemy_01.CP_ShiNeng_Enemy_01'",
  PetSrcPath = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Common/CP_ShiNeng_Pet_01.CP_ShiNeng_Pet_01'",
  TriggerSkillPathTmp = "/Game/ArtRes/Effects/G6Skill/Jineng/fire_SN_hit.fire_SN_hit",
  SpEnergyElementMax = 6
}
BattleConst.ItemOperationMaterial = {
  Material_1 = "/Game/ArtRes/Effects/Texture/UI/Material/MI_UI_LXY_041.MI_UI_LXY_041",
  Material_2 = "/Game/ArtRes/Effects/Texture/UI/Material/MI_UI_LXY_045.MI_UI_LXY_045",
  Material_3 = "/Game/ArtRes/Effects/Texture/UI/Material/MI_UI_LXY_046.MI_UI_LXY_046"
}
BattleConst.ItemOperationSprite = {
  Sprite_1 = "/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_chongwutouxiangkuangkong_png.img_chongwutouxiangkuangkong_png",
  Sprite_2 = "/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_chongwutouxiangkuangkong1_png.img_chongwutouxiangkuangkong1_png",
  Sprite_3 = "/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_chongwutouxiangkuangkong2_png.img_chongwutouxiangkuangkong2_png"
}
BattleConst.BattleFieldValidCheck = {
  zLineUnderWaterCheckRange = 3500,
  zLineSweepRange = 500,
  LineTraceMaxLength = 1000
}
BattleConst.SpEnergyElementMax = 6
BattleConst.OverrideCatchRate = -1
BattleConst.ItemLongPressThreshold = 0.2
BattleConst.CmToSkillEventDict = {
  [ProtoEnum.Buffbasetrigger_type.OnHit] = "TriggerBeHit"
}
BattleConst.NightmareMutationChangeEventName = "TriggerMutationChange"
BattleConst.SkillSelectSettings = {
  SingleTargetSelectorExistingTime = 1,
  WaitSelectorUIAnimTimeAOE = 0.4,
  WaitSelectorUIAnimTime = 0.2
}
BattleConst.OperationSelectSettings = {ChangeOperateBlendTime = 0.0}
BattleConst.DebugFlags = {ShowPetHP = false}
BattleConst.ChangePetEffect = "/Game/ArtRes/Effects/G6Skill/Battle/G6_ChangePet_Fx.G6_ChangePet_Fx_C"
BattleConst.SleepBuffBaseId = 990107
BattleConst.WaterBattleReflection = "/Game/NewRoco/Modules/Core/Battle/BP_WaterBattleReflection.BP_WaterBattleReflection_C"
BattleConst.TeamBattleFlower = 10016
BattleConst.CheerPetEscapeSkill = "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Ele_7110050_SDB.G6_Ele_7110050_SDB"
BattleConst.PlayerSkillEscapeSelfOut = "/Game/ArtRes/Effects/G6Skill/Jineng/Magic/G6_Magic_Run_World.G6_Magic_Run_World"
BattleConst.CheerPetPerformConfig = {
  [Enum.SubstituteCharacter.SC_NORMAL] = {
    [BattleEnum.CheerPetPerformState.BeAttack] = "Sad",
    [BattleEnum.CheerPetPerformState.AttackOther] = "Happy",
    [BattleEnum.CheerPetPerformState.BeCatch] = "Stun"
  },
  [Enum.SubstituteCharacter.SC_POSITIVE] = {
    [BattleEnum.CheerPetPerformState.BeAttack] = "Shock",
    [BattleEnum.CheerPetPerformState.AttackOther] = "Show",
    [BattleEnum.CheerPetPerformState.BeCatch] = "Anger"
  },
  [Enum.SubstituteCharacter.SC_NEGATIVE] = {
    [BattleEnum.CheerPetPerformState.BeAttack] = "Fear",
    [BattleEnum.CheerPetPerformState.AttackOther] = "Relax",
    [BattleEnum.CheerPetPerformState.BeCatch] = "Alert"
  }
}
BattleConst.BattlePlayerPetLock = "/Game/ArtRes/Effects/G6Skill/DaojuUse/DaoJu_ZhuJueMoFa_DaoJu_CW.DaoJu_ZhuJueMoFa_DaoJu_CW_C"
BattleConst.SurpriseBoxShieldBreak = {
  MutationsSkillPath = "/Game/ArtRes/Effects/G6Skill/S2/G6_JXHZ_Prize.G6_JXHZ_Prize_C",
  SeasonPetSkillPath = "/Game/ArtRes/Effects/G6Skill/S2/G6_JXHZ_CallOut.G6_JXHZ_CallOut_C",
  NormalPetSkillPath = "/Game/ArtRes/Effects/G6Skill/S2/G6_JXHZ_CallOut_Com.G6_JXHZ_CallOut_Com_C"
}
BattleConst.BloodType2AttrType = {
  5,
  0,
  4,
  6,
  3,
  7,
  11,
  16,
  12,
  13,
  1,
  14,
  8,
  15,
  9,
  2,
  17,
  10
}
BattleConst.BattleSkipCamera = "BattleSkipCamera"
BattleConst.BattleSkipCameraAS = "BattleSkipCameraAS"
BattleConst.BuffIconShowType = {
  None = 0,
  WorldUI = 1,
  ScreenBtn = 2,
  ScreenBtnAndUI = 3
}
BattleConst.BP_BattleEQSRunner_C = "/Game/NewRoco/Modules/Core/Battle/AI/BP_BattleEQSRunner.BP_BattleEQSRunner_C"
BattleConst.AI_BattlePetJumpToLocation_C = "/Game/ArtRes/Effects/G6Skill/Pet_In_Fight/AI_BattlePetJumpToLocation.AI_BattlePetJumpToLocation_C"
BattleConst.BattleSearchElliptic = "/Game/NewRoco/Modules/Core/Battle/AI/BattleSearchEllipticPosEQS.BattleSearchEllipticPosEQS"
BattleConst.MimicHeadIcon = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_weizhi__png.img_weizhi__png'"
BattleConst.RandomPetHeadIcon = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_jingling_png.img_jingling_png'"
BattleConst.RandomPetTypeIcon = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_wenhao5_png.img_wenhao5_png'"
BattleConst.NormalPetDeckCardIcon = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_qiu_png.img_qiu_png'"
BattleConst.RandomPetDeckCardIcon = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_qiu_wenhao_png.img_qiu_wenhao_png'"
BattleConst.NormalDeadPetDeckCardIcon = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_qiu4_png.img_qiu4_png'"
BattleConst.RandomDeadPetDeckCardIcon = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_qiu_wenhao1_png.img_qiu_wenhao1_png'"
BattleConst.TrialPetTypeIcon = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_shiyong_png.img_shiyong_png'"
BattleConst.FantasticBackgroundPathDefaultSquare = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_qiyijinngkuang_png.img_qiyijinngkuang_png'"
BattleConst.FantasticBackgroundPathDefaultStrip = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_tanchukuang_png.img_tanchukuang_png'"
BattleConst.Human_Male = 1010001
BattleConst.Human_Female = 1010002
BattleConst.RandomPetModelConfId = 20067
BattleConst.FantasticBackgroundPathsS1 = {
  squareNm3 = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_qiyijinngkuang_png.img_qiyijinngkuang_png'",
  stripNm3 = "Texture2D'/Game/NewRoco/Modules/System/BattleUI/Raw/Texture/img_qiyijinngkuang.img_qiyijinngkuang'",
  cloudNm3 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_LSC_02.MI_UI_LSC_02'",
  cloudNm5 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_LSC_01.MI_UI_LSC_01'",
  cloudNor4 = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_LSC_08.T_UI_LSC_08'",
  cloudNor4Mask = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_LSC_10.T_UI_LSC_10'",
  cloudNor4MaskUTiling = 0.8,
  cloudNor4MaskVTiling = 0.5,
  cloudNor4MaskUSpeed = -0.01,
  cloudNor4MaskVSpeed = 0.01,
  cloudNor5 = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_LSC_07.T_UI_LSC_07'",
  dataAssetPath = "PrimaryDataAsset'/Game/NewRoco/Modules/System/PVPQualifier/Res/SeasonSkill/PDA_SeasonSkillUiConfiguration_S1.PDA_SeasonSkillUiConfiguration_S1'"
}
BattleConst.FantasticBackgroundPathsS2 = {
  squareNm3 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_ZAY_010.MI_UI_ZAY_010'",
  stripNm3 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_ZAY_011.MI_UI_ZAY_011'",
  cloudNm3 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_ZAY_007.MI_UI_ZAY_007'",
  cloudNm5 = "Material'/Game/ArtRes/UI/Effects/Materials/MI_UI_ZAY_006.MI_UI_ZAY_006'",
  cloudNor4 = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_ZAY_007.T_UI_ZAY_007'",
  cloudNor4Mask = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_ZAY_009.T_UI_ZAY_009'",
  cloudNor4MaskUTiling = 1.85,
  cloudNor4MaskVTiling = 1.0,
  cloudNor4MaskUSpeed = -0.035,
  cloudNor4MaskVSpeed = 0.035,
  cloudNor5 = "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_ZAY_006.T_UI_ZAY_006'",
  dataAssetPath = "PrimaryDataAsset'/Game/NewRoco/Modules/System/PVPQualifier/Res/SeasonSkill/PDA_SeasonSkillUiConfiguration_S2.PDA_SeasonSkillUiConfiguration_S2'"
}
BattleConst.FantasticBackgroundPathsDefaults = {
  [1] = BattleConst.FantasticBackgroundPathsS1,
  [2] = BattleConst.FantasticBackgroundPathsS2
}
BattleConst.EffectAnimation = {
  EnergyRecovery = 1001,
  ChangeToCute = 1002,
  KeepWarning = 1003,
  Resurrection = 1004
}
BattleConst.DeckCardState = {
  None = 1,
  Living = 2,
  Dead = 3
}
BattleConst.ReservesPetsMax = 5
BattleConst.FsmVarNames = {
  HideScenePetDelegate = "HideScenePetDelegate",
  HideSceneTreesDelegate = "HideSceneTreesDelegate",
  ShowSceneTreesDelegate = "ShowSceneTreesDelegate",
  ShowBlackScreenReasons = "ShowBlackScreenReasons"
}
BattleConst.GrassChangeTypes = {
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass04/SM_EnvGraGra_Grass04_a.SM_EnvGraGra_Grass04_a",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_f_Masked.SM_EnvGraGra_Grass06_f_Masked"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass04/SM_EnvGraGra_Grass04_a.SM_EnvGraGra_Grass04_f",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_f_Masked.SM_EnvGraGra_Grass06_f_Masked"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass04/SM_EnvGraGra_Grass04_a.SM_EnvGraGra_Grass04_g",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_f_Masked.SM_EnvGraGra_Grass06_f_Masked"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass04/SM_EnvGraGra_Grass04_a.SM_EnvGraGra_Grass04_h",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_f_Masked.SM_EnvGraGra_Grass06_f_Masked"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_d_Masked.SM_EnvGraGra_Grass06_d_Masked",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Grass/Grass06/SM_EnvGraGra_Grass06_f_Masked.SM_EnvGraGra_Grass06_f_Masked"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b_1.SM_EnvHumBush_03_b_1",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b_Combat.SM_EnvHumBush_03_b_Combat"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b_2.SM_EnvHumBush_03_b_2",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b_Combat.SM_EnvHumBush_03_b_Combat"
  },
  {
    sourceSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b.SM_EnvHumBush_03_b",
    targetSmPath = "/Game/ArtRes/Asset/Environment/Plant/Bush/Human/SM_EnvHumBush_03_b_Combat.SM_EnvHumBush_03_b_Combat"
  }
}
BattleConst.HpBarColor = {
  Normal = {
    Red = "#AF3D3EFF",
    Yellow = "#FCB641FF",
    Green = "#73C615FF"
  },
  Add = "#9CFF49FF",
  Sub = {
    Red = "#782223FF",
    Yellow = "#916d27FF",
    Green = "#487111FF"
  }
}
BattleConst.DamageTypeColor = {
  [Enum.SkillDamType.SDT_INVALID] = "#FFFFFFFF",
  [Enum.SkillDamType.SDT_NONE] = "#FFFFFFFF",
  [Enum.SkillDamType.SDT_COMMON] = "#84A3BBFF",
  [Enum.SkillDamType.SDT_GRASS] = "#58A239FF",
  [Enum.SkillDamType.SDT_FIRE] = "#E3725CFF",
  [Enum.SkillDamType.SDT_WATER] = "#68A0FBFF",
  [Enum.SkillDamType.SDT_LIGHT] = "#D4B23BFF",
  [Enum.SkillDamType.SDT_EARTH] = "#AC6561FF",
  [Enum.SkillDamType.SDT_STONE] = "#BA7C4AFF",
  [Enum.SkillDamType.SDT_ICE] = "#65E1FFFF",
  [Enum.SkillDamType.SDT_DRAGON] = "#62C1A9FF",
  [Enum.SkillDamType.SDT_ELECTRIC] = "#FAC534FF",
  [Enum.SkillDamType.SDT_TOXIC] = "#B269DCFF",
  [Enum.SkillDamType.SDT_INSECT] = "#7FB22AFF",
  [Enum.SkillDamType.SDT_FIGHT] = "#C75943FF",
  [Enum.SkillDamType.SDT_WING] = "#60D0CDFF",
  [Enum.SkillDamType.SDT_MOE] = "#E73670FF",
  [Enum.SkillDamType.SDT_GHOST] = "#677BD2FF",
  [Enum.SkillDamType.SDT_DEMON] = "#927DDEFF",
  [Enum.SkillDamType.SDT_MECHANIC] = "#7085A4FF",
  [Enum.SkillDamType.SDT_PHANTOM] = "#9FAFFDFF",
  [Enum.SkillDamType.SDT_RELAX] = "#FFFFFFFF"
}
BattleConst.EffectTypeColor = {
  [-1] = "#F5EFE2FF",
  [0] = "#58A400FF",
  [1] = "#F5EFE2FF",
  [2] = "#C6494CFF"
}
BattleConst.ChangeSkillPositionParams = {
  TimeBeforeAnimation = 0.5,
  SkillGoOutTime = 0.5,
  TimeBetweenGoOutAndMoving = 0.1,
  SkillMovingSpeedMultiplier = 1.25,
  TimeBetweenMovingAndGoBack = 0.25,
  SkillGaBackTime = 1,
  SkillGaBackAmp = 1,
  SkillGaBackPeriod = 0.8,
  SkillGoOutAudioId = 1505,
  SkillMovingAudioId = 1506,
  SkillGoBackAudioId = 1507,
  SkillChange2AudioId = 1508
}
BattleConst.BattleEnergyViewBackgroundSpritePaths = {
  Normal = "/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_nengliangshuliang2_png.img_nengliangshuliang2_png",
  Low = "/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/Combat/Frames/img_nengliangshuliang_red_png.img_nengliangshuliang_red_png"
}
BattleConst.BattleEnergyViewColor = {
  TextNormal = "#F4EEE1FF",
  TextRed = "#C7494AFF",
  StarWhite = "#F4EEE1FF",
  StarYellow = "#FFC65FFF",
  BackgroundRed = "#6A1A1AFF",
  BackgroundGrey = "#3D3D3DFF",
  StarPurple = "#FF39ABFF"
}
BattleConst.BattleZoomPhoneSpeed = 10
BattleConst.BattleZoomDefaultSpeed = 0.05
BattleConst.BattleZoomMin = -1
BattleConst.BattleZoomMax = 1
BattleConst.BattleCrowdNpc = {
  ActorScale = 8,
  RandomOffsetRangeH = 10,
  RandomOffsetRangeV = 2
}
BattleConst.MonsterIsNightmareValueToMutationDiffType = {
  [0] = _G.Enum.MutationDiffType.MDT_NONE,
  [1] = _G.Enum.MutationDiffType.MDT_CHAOS_THREE,
  [2] = _G.Enum.MutationDiffType.MDT_CHAOS_TWO
}
BattleConst.UpdateFootDelta = 0.3
BattleConst.GetEnergySkill = "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Nor_nlhj_200004.G6_Nor_nlhj_200004_C"
BattleConst.YajijiPath = "Blueprint'/Game/ArtRes/BP/Pets/Com_YaJiJi1_001/BP_Com_YaJiJi1_001.BP_Com_YaJiJi1_001_C'"
BattleConst.EnterFocusSalsToAiStatusMap = {
  [Enum.SpaceActorLogicStatus.SALS_DRILL] = Enum.BattleAIStatus.BAS_DRILL,
  [Enum.SpaceActorLogicStatus.SALS_STATIC] = Enum.BattleAIStatus.BAS_STATIC,
  [Enum.SpaceActorLogicStatus.SALS_MIMIC] = Enum.BattleAIStatus.BAS_MIMIC,
  [Enum.SpaceActorLogicStatus.SALS_MIMIC_OPTION] = Enum.BattleAIStatus.BAS_MIMIC_OPTION,
  [Enum.SpaceActorLogicStatus.SALS_HIDE] = Enum.BattleAIStatus.BAS_HIDE,
  [Enum.SpaceActorLogicStatus.SALS_GHOST] = Enum.BattleAIStatus.BAS_GHOST,
  [Enum.SpaceActorLogicStatus.SALS_THUNDER] = Enum.BattleAIStatus.BAS_THUNDER,
  [Enum.SpaceActorLogicStatus.SALS_DIVING] = Enum.BattleAIStatus.BAS_DIVING,
  [Enum.SpaceActorLogicStatus.SALS_FISHJUMP] = Enum.BattleAIStatus.BAS_FISHJUMP,
  [Enum.SpaceActorLogicStatus.SALS_TRAIL] = Enum.BattleAIStatus.BAS_TRAIL,
  [Enum.SpaceActorLogicStatus.SALS_FALLING] = Enum.BattleAIStatus.BAS_FALLING,
  [Enum.SpaceActorLogicStatus.SALS_NIGHTMARE_ELITE] = Enum.BattleAIStatus.BAS_NIGHTMARE,
  [Enum.SpaceActorLogicStatus.SALS_NIGHTMARE_KEEP] = Enum.BattleAIStatus.BAS_NIGHTMARE_KEEP
}
BattleConst.RandomPetGidStart = 3221225472
BattleConst.MaxPureRandomPetCount = 6
BattleConst.AllowRandomPetTeamTypeMap = {
  [Enum.PlayerTeamType.PTT_PVP_BATTLE_4] = true,
  [Enum.PlayerTeamType.PTT_PVP_BATTLE_5] = true
}
BattleConst.TerritoryTrial = {}
BattleConst.TerritoryTrial.PetPosToClientStandPos = {
  [3] = 1,
  [4] = 2,
  [5] = 4,
  [6] = 5,
  [7] = 3
}
BattleConst.TerritoryTrial.WinOver = "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_Dare_Win.G6_Dare_Win_C"
BattleConst.TerritoryTrial.CommonBagToPrepare = "/Game/ArtRes/Effects/G6Skill/SceneEffect/LingDi/G6_LingDi_CW.G6_LingDi_CW_C"
BattleConst.TerritoryTrial.BossPrepareToBattle = "/Game/ArtRes/Effects/G6Skill/SceneEffect/LingDi/G6_LingDi_Boss.G6_LingDi_Boss_C"
BattleConst.BallOperationScrollToAnotherPageThreshold = 60
BattleConst.PvpQualifierOpenRankCheckValueToBattleType = {
  [true] = ProtoEnum.BattleType.BT_PVP_RANK,
  [false] = ProtoEnum.BattleType.BT_PVP_SRANDARD
}
BattleConst.PvpScoreCoinType = _G.Enum.VisualItem.VI_COIN
BattleConst.PvpScoreItemType = _G.Enum.VisualItem.VI_PVP_SCORE_1
BattleConst.PvpDefaultShopId = 2006
BattleConst.NoAnimStatus = {
  ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING,
  ProtoEnum.WorldPlayerStatusType.WPST_FALLING,
  ProtoEnum.WorldPlayerStatusType.WPST_SLIDING,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDE_DASHING,
  ProtoEnum.WorldPlayerStatusType.WPST_DEATH,
  ProtoEnum.WorldPlayerStatusType.WPST_CLIMB,
  ProtoEnum.WorldPlayerStatusType.WPST_CLIMB_DASH,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY,
  ProtoEnum.WorldPlayerStatusType.WPST_MANTLE,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_JUMP
}
BattleConst.NightMareShieldHeadIconMatPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_BlackMagic.MI_UI_BlackMagic'"
BattleConst.NightMareHeadIconMatPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_InnerLine.MI_UI_InnerLine'"
BattleConst.PvpShowResultUiSkillActorBlackboardKeyList = {"AxeN", "AxeF"}
BattleConst.ImcBattleName = "IMC_Battle"
BattleConst.BattleSwitchConfigActionNames = {
  "BattleB1P1SwitchToP2Action",
  "BattleB1P2SwitchToP3Action"
}
BattleConst.BattleVictoryUiMaskStencilValue = 7
return BattleConst
