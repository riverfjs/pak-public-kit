local NPCModuleEnum = {}
NPCModuleEnum.InteractType = {
  PLAYER = 1,
  PET_BULL_RUSH = 2,
  STAR_HIT = 3
}
NPCModuleEnum.HudPoolType = {
  PetHud = "UMG_Hud_Pet"
}
local SkillDamType = Enum.SkillDamType
NPCModuleEnum.UnLockSkillPathMap = {
  [SkillDamType.SDT_NONE] = "",
  [SkillDamType.SDT_COMMON] = "G6_XBJH_Com",
  [SkillDamType.SDT_GRASS] = "G6_XBJH_Gra",
  [SkillDamType.SDT_FIRE] = "G6_XBJH_Fir",
  [SkillDamType.SDT_WATER] = "G6_XBJH_Wat",
  [SkillDamType.SDT_LIGHT] = "G6_XBJH_Lig",
  [SkillDamType.SDT_EARTH] = "",
  [SkillDamType.SDT_STONE] = "G6_XBJH_Ear",
  [SkillDamType.SDT_ICE] = "G6_XBJH_Ice",
  [SkillDamType.SDT_DRAGON] = "G6_XBJH_Dra",
  [SkillDamType.SDT_ELECTRIC] = "G6_XBJH_Ele",
  [SkillDamType.SDT_TOXIC] = "G6_XBJH_Poi",
  [SkillDamType.SDT_INSECT] = "G6_XBJH_Wor",
  [SkillDamType.SDT_FIGHT] = "G6_XBJH_Mar",
  [SkillDamType.SDT_WING] = "G6_XBJH_Win",
  [SkillDamType.SDT_MOE] = "G6_XBJH_Cut",
  [SkillDamType.SDT_GHOST] = "G6_XBJH_Gho",
  [SkillDamType.SDT_DEMON] = "G6_XBJH_Dem",
  [SkillDamType.SDT_MECHANIC] = "G6_XBJH_Iron",
  [SkillDamType.SDT_PHANTOM] = "G6_XBJH_Cha"
}
local WeatherType = Enum.WeatherType
NPCModuleEnum.RainMoaiSkillMap = {
  [WeatherType.WT_LIGHTRAIN] = "G6_QYQ_Wat",
  [WeatherType.WT_HEAVYRAIN] = "G6_QYQ_Wat",
  [WeatherType.WT_SANDSTORM] = "G6_QYQ_Ear",
  [WeatherType.WT_FOGGY] = "G6_QYQ_Poi",
  [WeatherType.WT_SNOW] = "G6_QYQ_ICE"
}
NPCModuleEnum.WeatherToSkillDamType = {
  [WeatherType.WT_LIGHTRAIN] = SkillDamType.SDT_INVALID,
  [WeatherType.WT_HEAVYRAIN] = SkillDamType.SDT_WATER,
  [WeatherType.WT_SANDSTORM] = SkillDamType.SDT_STONE,
  [WeatherType.WT_FOGGY] = SkillDamType.SDT_TOXIC,
  [WeatherType.WT_SNOW] = SkillDamType.SDT_ICE
}
NPCModuleEnum.ActionStatus = {
  FixCoord = 1,
  Begin = 2,
  End = 3
}
NPCModuleEnum.SenseTypeEnum = {
  NoSense = 1,
  TotalSense = 2,
  InteractableSense = 3
}
NPCModuleEnum.NpcReasonFlags = {
  ANY = 0,
  BATTLE = 1,
  DIALOGUE = 2,
  CINEMATIC = 3,
  HIDDEN = 4,
  SERVER = 5,
  PERCEPTION = 6,
  CALL_OUT = 7,
  PET_NUM_LIMIT = 8,
  MINI_GAME = 9,
  OVERLAP_AWARE = 10,
  AI = 11,
  BORN_DIE = 12,
  EXPLODE = 13,
  LIGHT_MAGIC = 14,
  ATTACHING = 15,
  NIGHTMARE = 16,
  LAUNCH_CHARACTER = 17,
  NOT_OWNER = 18,
  WORLD_COMBAT_HIDDEN = 19,
  AI_MOVING = 20,
  LEGENDARY_BATTLE = 21,
  SERVER_TASK = 22,
  SERVER_DIALOGUE = 23,
  SERVER_OTHER = 24,
  HOME_EDIT_FLAG = 25,
  CPP = 26,
  PARENT = 27,
  MagicCreationPerform = 28,
  BattleOutside = 29,
  CampingFire = 30,
  SKILL_DEFAULT = 31,
  GUARD_SPHERE = 32,
  TAKE_PHOTO = 33,
  MAGIC_REPLAY = 34,
  EDITOR_DEFAULT = 35,
  ROLEPLAY_FREE_PLACE = 36,
  SUIT_PERFORM = 37
}
NPCModuleEnum.ServerNpcReasonMasks = 1 << NPCModuleEnum.NpcReasonFlags.SERVER | 1 << NPCModuleEnum.NpcReasonFlags.SERVER_TASK | 1 << NPCModuleEnum.NpcReasonFlags.SERVER_DIALOGUE | 1 << NPCModuleEnum.NpcReasonFlags.SERVER_OTHER
NPCModuleEnum.NpcInteractDisableFlag = {
  ANY = 0,
  PET_HARVEST = 1,
  PICK_BY_PLAYER = 2,
  BORN_DIE = 3,
  WAIT_CATCH_RSP = 4,
  WAIT_CATCH_PERFORM = 5,
  FUNCTION_BAN = 6,
  MESSAGE_BAN = 7,
  WORLD_COMBAT = 8,
  HIDDEN_COMP = 9,
  ROLEPLAY = 10,
  NPC_IS_BUSY = 11
}
NPCModuleEnum.PetBondActiveReason = {
  ANY = 0,
  OPTION = 1,
  PET_INTERACT_TREE = 2
}
return NPCModuleEnum
