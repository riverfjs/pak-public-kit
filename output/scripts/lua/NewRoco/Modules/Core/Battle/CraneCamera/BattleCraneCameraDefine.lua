local BattleCraneCameraDefine = {}
BattleCraneCameraDefine.HotReloadType = {
  Full
}
BattleCraneCameraDefine.TargetType = {
  TeamPet = 1,
  EnemyPet = 2,
  TeamPlayer = 3,
  EnemyPlayer = 4,
  TeamPet1 = 5,
  TeamPet2 = 6,
  EnemyPet1 = 7,
  EnemyPet2 = 8,
  TeamPet3 = 9,
  EnemyPet3 = 10,
  TeamPet4 = 11,
  EnemyPet4 = 12,
  MySelfPet = 13
}
BattleCraneCameraDefine.InputParam = {
  Slope = 1,
  TeamPetHeight = 2,
  EnemyPetHeight = 3,
  PetHeightRatio = 4,
  DirectPitchAngle = 5,
  Slope2 = 6,
  TeamPet1Pet2HeightRatio = 7
}
BattleCraneCameraDefine.OutputParam = {
  PitchAngle = 1,
  YawAngle = 2,
  RollAngle = 3,
  TargetPointHeight = 4,
  SpringArmLength = 5,
  FOV = 6,
  PointRatio = 7
}
BattleCraneCameraDefine.CameraJsonGlobalName = "BattleCraneCamera_Settings_Global"
BattleCraneCameraDefine.CameraJsonCfg = {
  [UE4.EBattleCameraTags.PlayerCatch] = "BattleCraneCamera_Settings_PlayerCatch",
  [UE4.EBattleCameraTags.PlayerEscape] = "BattleCraneCamera_Settings_PlayerEscape",
  [UE4.EBattleCameraTags.PlayerItemToTeam] = "BattleCraneCamera_Settings_PlayerItemToTeam",
  [UE4.EBattleCameraTags.PlayerItemToEnemy] = "BattleCraneCamera_Settings_PlayerItemToEnemy",
  [UE4.EBattleCameraTags.PlayerChange] = "BattleCraneCamera_Settings_PlayerChange",
  [UE4.EBattleCameraTags.PlayerPet] = "BattleCraneCamera_Settings_PlayerPet",
  [UE4.EBattleCameraTags.PlayerPetMult1] = "BattleCraneCamera_Settings_PlayerPetMult1",
  [UE4.EBattleCameraTags.PlayerPetMult2] = "BattleCraneCamera_Settings_PlayerPetMult2",
  [UE4.EBattleCameraTags.PlayerSkill] = "BattleCraneCamera_Settings_PlayerSkill",
  [UE4.EBattleCameraTags.PlayerSkillMult] = "BattleCraneCamera_Settings_PlayerSkillMult",
  [UE4.EBattleCameraTags.SpecialToTeam] = "BattleCraneCamera_Settings_SpecialToTeam",
  [UE4.EBattleCameraTags.SpecialToEnemy] = "BattleCraneCamera_Settings_SpecialToEnemy",
  [UE4.EBattleCameraTags.TeamFight_PlayerPet] = "BattleCraneCamera_Settings_TeamFight_PlayerPet",
  [UE4.EBattleCameraTags.TeamFight_PlayerSkill] = "BattleCraneCamera_Settings_TeamFight_PlayerSkill",
  [UE4.EBattleCameraTags.TeamFight_PlayerSkillMult] = "BattleCraneCamera_Settings_TeamFight_PlayerSkillMult",
  [UE4.EBattleCameraTags.TeamFight_PlayerItemToTeam] = "BattleCraneCamera_Settings_TeamFight_PlayerItemToTeam",
  [UE4.EBattleCameraTags.TeamFight_PlayerCatch] = "BattleCraneCamera_Settings_TeamFight_Catch",
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerPet] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerPet",
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerSkill] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerSkill",
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerSkillMult] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerSkill",
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerItemToTeam] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerItemToTeam",
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerCatch] = "BattleCraneCamera_Settings_LegenderyTeamFight_Catch",
  [UE4.EBattleCameraTags.LegenderyTeamFight_Player_QuicklyCatch] = "BattleCraneCamera_Settings_LegenderyTeamFight_QuicklyCatch",
  [UE4.EBattleCameraTags.PlayerChange2V2] = "BattleCraneCamera_Settings_2V2_PlayerChange",
  [UE4.EBattleCameraTags.PlayerMagic] = "BattleCraneCamera_Settings_PlayerMagic",
  [UE4.EBattleCameraTags.PlayerMagicMulti] = "BattleCraneCamera_Settings_PlayerMagicMult",
  [UE4.EBattleCameraTags.PlayerNpcAssistSelectSkill] = "BattleCraneCamera_Settings_Ally2V2_SelectSkill",
  [UE4.EBattleCameraTags.PlayerNpcAssistSwitchPet] = "BattleCraneCamera_Settings_Ally2V2_SwtichPet",
  [UE4.EBattleCameraTags.PlayerNpcAssistSelectItem] = "BattleCraneCamera_Settings_Ally2V2_SelectItem",
  [UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill] = "BattleCraneCamera_Settings_Ally2V2_PerformSkill",
  [UE4.EBattleCameraTags.A1FBSSelectSkill] = "BattleCraneCamera_Settings_A1FB_P1_SelectSkill",
  [UE4.EBattleCameraTags.A1FBSelectItem] = "BattleCraneCamera_Settings_A1FB_P1_SelectItem",
  [UE4.EBattleCameraTags.A1FBPerformSkill] = "BattleCraneCamera_Settings_A1FB_P1_PerformSkill",
  [UE4.EBattleCameraTags.A1FBSSelectSkill_Pet1] = "BattleCraneCamera_Settings_A1FB_P1_SelectSkill_Pet1",
  [UE4.EBattleCameraTags.A1FBSSelectSkill_Pet2] = "BattleCraneCamera_Settings_A1FB_P1_SelectSkill_Pet2",
  [UE4.EBattleCameraTags.A1FBSSelectSkill_Pet3] = "BattleCraneCamera_Settings_A1FB_P1_SelectSkill_Pet3",
  [UE4.EBattleCameraTags.A1FBPerformSkillP2] = "BattleCraneCamera_Settings_A1FB_P2_PerformSkill",
  [UE4.EBattleCameraTags.A1FBSSelectSkillP2_Pet1] = "BattleCraneCamera_Settings_A1FB_P2_SelectSkill",
  [UE4.EBattleCameraTags.A1FBSPlayerMagicP1] = "BattleCraneCamera_Settings_A1FB_P1_SelectTarget_Ally",
  [UE4.EBattleCameraTags.A1FBSPlayerMagicYaSe] = "BattleCraneCamera_Settings_A1FB_P1_SelectTarget_Enemy",
  [UE4.EBattleCameraTags.AdditionalSkills] = "BattleCraneCamera_Settings_AdditionalSkills_PlayerPet",
  [UE4.EBattleCameraTags.TeamFight_PlayerEscape] = "BattleCraneCamera_Settings_TeamFight_PlayerEscape",
  [UE4.EBattleCameraTags.B1FBPerformSkillP1] = "BattleCraneCamera_Settings_B1FB_P1_PerformSkill",
  [UE4.EBattleCameraTags.B1FBSSelectSkillP1_Pet1] = "BattleCraneCamera_Settings_B1FB_P1_SelectSkill",
  [UE4.EBattleCameraTags.B1FBSelectItem] = "BattleCraneCamera_Settings_B1FB_P1_SelectItem",
  [UE4.EBattleCameraTags.B1FBSP1_ChangePet] = "BattleCraneCamera_Settings_B1FB_ChangePet",
  [UE4.EBattleCameraTags.B1FBPerformSkillP2] = "BattleCraneCamera_Settings_B1FB_P2_PerformSkill",
  [UE4.EBattleCameraTags.B1FBSSelectSkillP2_Pet1] = "BattleCraneCamera_Settings_B1FB_P2_SelectSkill",
  [UE4.EBattleCameraTags.B1FBPerformSkillP3] = "BattleCraneCamera_Settings_B1FB_P3_PerformSkill",
  [UE4.EBattleCameraTags.B1FBSSelectSkillP3_Pet1] = "BattleCraneCamera_Settings_B1FB_P3_SelectSkill",
  [UE4.EBattleCameraTags.B1FBSP3_MasterSkill] = "BattleCraneCamera_Settings_B1FB_P3_CloseUp",
  [UE4.EBattleCameraTags.OneVsAll_SelectSkill_Pet1] = "BattleCraneCamera_Settings_PlayerPetMult1",
  [UE4.EBattleCameraTags.OneVsAll_SelectSkill_Pet2] = "BattleCraneCamera_Settings_PlayerPetMult2",
  [UE4.EBattleCameraTags.OneVsAll_PerformSkill] = "BattleCraneCamera_Settings_PlayerSkill",
  [UE4.EBattleCameraTags.OneVsAll_PlayerItem] = "BattleCraneCamera_Settings_PlayerItemToTeam",
  [UE4.EBattleCameraTags.OneVsAll_PlayerChangePet] = "BattleCraneCamera_Settings_PlayerChange",
  [UE4.EBattleCameraTags.OneVsAll_PlayerCatch] = "BattleCraneCamera_Settings_PlayerCatch",
  [UE4.EBattleCameraTags.TerritoryTrial_SelectSkill_Pet1] = "BattleCraneCamera_Settings_TerritoryTrial_PlayerPetMult1",
  [UE4.EBattleCameraTags.TerritoryTrial_SelectSkill_Pet2] = "BattleCraneCamera_Settings_TerritoryTrial_PlayerPetMult2",
  [UE4.EBattleCameraTags.TerritoryTrial_PerformSkill] = "BattleCraneCamera_Settings_TerritoryTrial_PlayerSkill",
  [UE4.EBattleCameraTags.TerritoryTrial_PlayerItem] = "BattleCraneCamera_Settings_TerritoryTrial_PlayerItemToTeam",
  [UE4.EBattleCameraTags.TerritoryTrial_PlayerChangePet] = "BattleCraneCamera_Settings_TerritoryTrial_PlayerChange"
}
BattleCraneCameraDefine.CameraJsonTeamFightCfg = {
  [UE4.EBattleCameraTags.PlayerPet] = "BattleCraneCamera_Settings_TeamFight_PlayerPet",
  [UE4.EBattleCameraTags.PlayerPetMult1] = "BattleCraneCamera_Settings_TeamFight_PlayerPet",
  [UE4.EBattleCameraTags.PlayerSkill] = "BattleCraneCamera_Settings_TeamFight_PlayerSkill",
  [UE4.EBattleCameraTags.PlayerSkillMult] = "BattleCraneCamera_Settings_TeamFight_PlayerSkillMult",
  [UE4.EBattleCameraTags.PlayerItemToTeam] = "BattleCraneCamera_Settings_TeamFight_PlayerItemToTeam",
  [UE4.EBattleCameraTags.PlayerCatch] = "BattleCraneCamera_Settings_TeamFight_Catch"
}
BattleCraneCameraDefine.CameraJsonLegendaryTeamFightCfg = {
  [UE4.EBattleCameraTags.PlayerPet] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerPet",
  [UE4.EBattleCameraTags.PlayerPetMult1] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerPet",
  [UE4.EBattleCameraTags.PlayerSkill] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerSkill",
  [UE4.EBattleCameraTags.PlayerSkillMult] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerSkillMult",
  [UE4.EBattleCameraTags.PlayerItemToTeam] = "BattleCraneCamera_Settings_LegenderyTeamFight_PlayerItemToTeam",
  [UE4.EBattleCameraTags.PlayerCatch] = "BattleCraneCamera_Settings_LegenderyTeamFight_Catch"
}
BattleCraneCameraDefine.CameraJsonOnePlayerTwoPetCfg = {
  [UE4.EBattleCameraTags.PlayerChange] = "BattleCraneCamera_Settings_2V2_PlayerChange"
}
BattleCraneCameraDefine.CameraJsonAdditionalSkills = {
  [UE4.EBattleCameraTags.PlayerPet] = "BattleCraneCamera_Settings_AdditionalSkills_PlayerPet"
}
BattleCraneCameraDefine.GeneralParameters = {CameraCollisionRadius = 65}
BattleCraneCameraDefine.PetStandState = {
  None = 0,
  Left = 1,
  Origin = 2
}
BattleCraneCameraDefine.CameraCurves = {
  [UE4.EViewTargetBlendFunction.VTBlend_Linear] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_Linear.CurveVTBlend_Linear",
  [UE4.EViewTargetBlendFunction.VTBlend_Cubic] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_Cubic.CurveVTBlend_Cubic",
  [UE4.EViewTargetBlendFunction.VTBlend_EaseIn] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_EaseIn.CurveVTBlend_EaseIn",
  [UE4.EViewTargetBlendFunction.VTBlend_EaseOut] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_EaseOut.CurveVTBlend_EaseOut",
  [UE4.EViewTargetBlendFunction.VTBlend_EaseInOut] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_EaseInOut.CurveVTBlend_EaseInOut",
  [UE4.EViewTargetBlendFunction.VTBlend_MAX] = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CurveVTBlend_MAX.CurveVTBlend_MAX"
}
BattleCraneCameraDefine.ControllerCameraTagFilter = {
  [UE4.EBattleCameraTags.PlayerSkill] = 1,
  [UE4.EBattleCameraTags.PlayerSkillMult] = 1,
  [UE4.EBattleCameraTags.TeamFight_PlayerSkill] = 1,
  [UE4.EBattleCameraTags.TeamFight_PlayerSkillMult] = 1,
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerSkill] = 1,
  [UE4.EBattleCameraTags.LegenderyTeamFight_PlayerSkillMult] = 1,
  [UE4.EBattleCameraTags.LegenderyTeamFight_Player_QuicklyCatch] = 1
}
BattleCraneCameraDefine.DefaultCameraCurve = "/Game/NewRoco/Modules/Core/Battle/Camera/CraneCamCurve/CraneCameraDefaultCurve.CraneCameraDefaultCurve"
BattleCraneCameraDefine.BumpCollisionParam = {
  IsOpen = false,
  pitch = -5,
  Height = 20,
  IsDebugLine = true
}
BattleCraneCameraDefine.CameraMode = {
  default = 0,
  additionalSkills = 1,
  teamBattle = 2,
  legendaryTeamFight = 3,
  onePlayerTwoPet = 4
}
BattleCraneCameraDefine.CameraModeJson = {
  [BattleCraneCameraDefine.CameraMode.default] = BattleCraneCameraDefine.CameraJsonCfg,
  [BattleCraneCameraDefine.CameraMode.additionalSkills] = BattleCraneCameraDefine.CameraJsonAdditionalSkills,
  [BattleCraneCameraDefine.CameraMode.teamBattle] = BattleCraneCameraDefine.CameraJsonTeamFightCfg,
  [BattleCraneCameraDefine.CameraMode.legendaryTeamFight] = BattleCraneCameraDefine.CameraJsonLegendaryTeamFightCfg,
  [BattleCraneCameraDefine.CameraMode.onePlayerTwoPet] = BattleCraneCameraDefine.CameraJsonOnePlayerTwoPetCfg
}
return BattleCraneCameraDefine
