local SceneAttackEnum = {}
SceneAttackEnum.AimType = {
  None = 1,
  Simple = 2,
  Laser = 3,
  Ground = 4
}
SceneAttackEnum.ActionType = {
  None = 1,
  NearbyHit = 2,
  Laser = 3,
  FireSkill = 4,
  WaterSkill = 5,
  Crush = 6,
  FixPos = 7,
  FixPosImme = 8
}
SceneAttackEnum.PlayerAttackPerformType = {
  PAPT_Light = 1,
  PAPT_Heavy = 2,
  PAPT_Normal = 3,
  PAPT_None = 1000
}
return SceneAttackEnum
