local AbilityErrorCode = {
  NO_ERROR = 0,
  CAN_NOT_FIND_ABILITY = 1,
  VITALITY_NOT_ENOUGH = 2,
  ABILITY_IS_CASTING = 3,
  IN_COOLDOWN = 4,
  NO_MOVE_INPUT = 5,
  HIGHER_PRIORITY_ABILITY_IS_CASTING = 6,
  INPUT_DISABLED = 7,
  INSUFFICIENT_LEVEL = 8,
  NO_CASTER = 9,
  BAG_ITEM_NOT_ENOUGH = 10,
  DUNGEON_BAN = 11,
  NOT_CASTTYPE = 12,
  HOME_FORBID = 13,
  VISIT_BAN = 14,
  TASK_AREA_BAN = 15,
  FUNC_BAN = 16,
  STORY_BAN = 17,
  HAND_IN_HAND_BAN = 18,
  SYSTEM_BAN = 19,
  GAME_BAN = 20,
  CASTING_SCENE_MAGIC = 21,
  TASK_LOCK = 22,
  VIDEO_BAN = 23,
  AREA_BAN = 24,
  ToString = function(errorCode)
    if 0 == errorCode then
      return "NO_ERROR"
    elseif 1 == errorCode then
      return "CAN_NOT_FIND_ABILITY"
    elseif 2 == errorCode then
      return "VITALITY_NOT_ENOUGH"
    elseif 3 == errorCode then
      return "ABILITY_IS_CASTING"
    elseif 4 == errorCode then
      return "IN_COOLDOWN"
    elseif 5 == errorCode then
      return "NO_MOVE_INPUT"
    elseif 6 == errorCode then
      return "HIGHER_PRIORITY_ABILITY_IS_CASTING"
    elseif 7 == errorCode then
      return "INPUT_DISABLED"
    elseif 8 == errorCode then
      return "INSUFFICIENT_LEVEL"
    elseif 9 == errorCode then
      return "NO_CASTER"
    elseif 10 == errorCode then
      return "BAG_ITEM_NOT_ENOUGH"
    elseif 11 == errorCode then
      return "DUNGEON_BAN"
    elseif 12 == errorCode then
      return "NOT_CASTTYPE"
    elseif 14 == errorCode then
      return "VISIT_BAN"
    elseif 15 == errorCode then
      return "TASK_AREA_BAN"
    elseif 16 == errorCode then
      return "FUNC_BAN"
    elseif 17 == errorCode then
      return "STORY_BAN"
    elseif 18 == errorCode then
      return "HAND_IN_HAND_BAN"
    elseif 19 == errorCode then
      return "SYSTEM_BAN"
    elseif 20 == errorCode then
      return "GAME_BAN"
    elseif 21 == errorCode then
      return "CASTING_SCENE_MAGIC"
    elseif 22 == errorCode then
      return "TASK_LOCK"
    elseif 23 == errorCode then
      return "VIDEO_BAN"
    elseif 24 == errorCode then
      return "AREA_BAN"
    end
  end
}
return AbilityErrorCode
