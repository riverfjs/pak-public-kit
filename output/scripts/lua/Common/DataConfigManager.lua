local Base = require("Common.Singleton.Singleton")
local DataConfigManager = Base:Extend()

function DataConfigManager:Ctor(name)
  self.name = name or "DataConfigManager"
  Base.Ctor(self, self.name)
  self:InitTableInfo()
  self.__dataTables = {}
end

function DataConfigManager:Free()
  self.__dataTables = {}
  Base.Free(self)
end

function DataConfigManager:GetTable(_tableId)
  if not _tableId or 0 == _tableId then
    return nil
  end
  local dataTables = self.__dataTables
  local cfgTable = dataTables[_tableId]
  if not cfgTable then
    local tblInfo = self.__configTableInfo[_tableId]
    if tblInfo then
      local fileName = string.format("Data.Config.%s", tblInfo.name)
      if _G.isEnableTinyIO == true then
        fileName = string.format("Data.tinyio_Config.%s", tblInfo.name)
        Log.WarningFormat("Using TinyIO table=[%s]", tblInfo.name)
      end
      cfgTable = require(fileName)
      if cfgTable then
        dataTables[_tableId] = cfgTable
      end
    end
  end
  return cfgTable
end

function DataConfigManager:GetData(_tableId, _key, _ignoreLog)
  local cfgTable = self:GetTable(_tableId)
  if not cfgTable then
    Log.ErrorFormat("GetData Error: confs tableId=[%d] is nil", _tableId)
    return nil
  end
  local cfg = cfgTable:GetData(_key)
  if not cfg and not _ignoreLog then
    local tblInfo = self.__configTableInfo[_tableId]
    Log.ErrorFormat("GetData Error: table=[%s], key=[%s] not found", tblInfo.name, tostring(_key))
    self:PopFatalError(tblInfo.name, _key)
  end
  return cfg
end

function DataConfigManager:GetAllByName(TableName)
  local TableID = self.ConfigTableId[TableName]
  if not TableID then
    Log.Error("can't find table id with name", TableName)
    return nil
  end
  return self:GetAllByTableID(TableID)
end

function DataConfigManager:GetAllByTableID(TableID)
  if 0 == TableID or nil == TableID then
    Log.Error("table id can't be nil or 0")
    return nil
  end
  local ConfTable = self:GetTable(TableID)
  if not ConfTable then
    Log.Error("can't find data with given table id", TableID, self.__configTableInfo[TableID])
    return nil
  end
  local RawConfs = ConfTable:GetAllDatas()
  if not RawConfs then
    Log.Error("can't find data from conf table", TableID, self.__configTableInfo[TableID])
  end
  return RawConfs
end

local EnableFatalError = false

function DataConfigManager:ToggleFatalError(Enable)
  EnableFatalError = Enable
end

function DataConfigManager:PopFatalError(TableName, Key)
  if not EnableFatalError then
    return
  end
  if _G.RocoEnv.IS_SHIPPING then
    return
  end
  if not _G.TipsModuleCmd then
    return
  end
  local Message = debug.traceback("", 3)
  local Errors = string.split(Message, "\n")
  local NewLines = {}
  for i = 3, 6 do
    if Errors[i] then
      table.insert(NewLines, Errors[i])
    else
      break
    end
  end
  local Shorten = table.concat(NewLines, "\n")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Ctx = DialogContext()
  Ctx:SetTitle("\233\157\158Shipping\231\137\136\230\156\172\228\184\147\229\177\158\228\184\165\233\135\141\233\148\153\232\175\175\230\143\144\231\164\186")
  Ctx:SetContent(string.format("\229\156\168\232\175\187\229\143\150\233\133\141\231\189\174%s\231\154\132\230\151\182\229\128\153\230\151\160\230\179\149\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132Key/ID:%s\n\228\187\165\228\184\139\230\152\175\232\176\131\229\160\134\230\160\136\239\188\140\232\175\183\231\173\150\229\136\146\229\146\140\229\188\128\229\143\145\229\144\140\229\173\166\228\184\128\232\181\183\230\142\146\230\159\165\239\188\140\232\176\162\232\176\162\239\188\129\n%s", TableName, tostring(Key), Shorten))
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetButtonText("\230\136\145\229\183\178\231\159\165\230\153\147\233\163\142\233\153\169", "\229\129\156\230\173\162\230\184\184\230\136\143")
  Ctx:SetCallback(nil, function(OK)
    UE.UNRCStatics.QuitGame()
  end)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function DataConfigManager:InitTableInfo()
  local configTableId = {
    CHINA_BENCHMARK_DEVICE_CONF = 1,
    PC_LEVEL_CPU_AMD_CONF = 2,
    PC_LEVEL_CPU_INTEL_CONF = 3,
    PC_LEVEL_GPU_AMD_CONF = 4,
    PC_LEVEL_GPU_NVIDIA_CONF = 5,
    WORLD_BENCHMARK_DEVICE_CONF = 6,
    BASIC_QUALITY_CONFIG_CONF = 7,
    OVERRIDE_QUALITY_CONF = 8,
    QUALITY_DEFAULT_CONF = 9,
    QUALITY_GROUP_SETTING_CONF = 10,
    QUALITY_LOCALIZATION_CONF = 11,
    QUALITY_MAPPING_CONF = 12,
    ACTIVITY_COMMON_SHOW_CONF = 13,
    ACTIVITY_CONDITION_GROUP_CONF = 14,
    ACTIVITY_CONDITION_REWARD_CONF = 15,
    ACTIVITY_CONF = 16,
    ACTIVITY_DROP_CONF = 17,
    ACTIVITY_DROP_METHOD_CONF = 18,
    ACTIVITY_FACTION_CONF = 19,
    ACTIVITY_FLOWER_APPEAR_CONF = 20,
    ACTIVITY_FLOWER_TASK_CONF = 21,
    ACTIVITY_GOODS_CONF = 22,
    ACTIVITY_INHERITANCE_CONF = 23,
    ACTIVITY_INVITE_REGISTER_CONF = 24,
    ACTIVITY_MAINTAB_CONF = 25,
    ACTIVITY_MIX_CONF = 26,
    ACTIVITY_PET_CATCH_CONF = 27,
    ACTIVITY_PET_CERTIFICATION = 28,
    ACTIVITY_PET_COLLECTION_CONF = 29,
    ACTIVITY_PET_PARTNER_CONF = 30,
    ACTIVITY_PET_PHOTO = 31,
    ACTIVITY_PET_RAISE_CONF = 32,
    ACTIVITY_PET_RAISE_TASK_CONF = 33,
    ACTIVITY_PET_TRIP_CONF = 34,
    ACTIVITY_PIKA_CONF = 35,
    ACTIVITY_PLAYER_CO_CREATION = 36,
    ACTIVITY_PREHEAT_CONF = 37,
    ACTIVITY_RELAY_PAGE = 38,
    ACTIVITY_REWARD_BY_STAGE_CONF = 39,
    ACTIVITY_SHINY_WEEKEND_CONF = 40,
    ACTIVITY_SHOP_CONF = 41,
    ACTIVITY_SPECIAL_CONF = 42,
    ACTIVITY_SPEC_FLOWER_SEED_CONF = 43,
    ACTIVITY_SPRING_FESTIVAL_CONF = 44,
    ACTIVITY_TLOG_CONF = 45,
    ACTIVITY_TRACK_CONDITION_CONF = 46,
    ACTIVITY_TREASURE_HUNT_CONF = 47,
    ACTIVITY_UP_CONF = 48,
    ACTIVITY_WEBSITE_PART_CONF = 49,
    ACTIVITY_WEEKEND_CHALLENGE_CONF = 50,
    ACTIVITY_WISH_LOTTER_AWARD = 51,
    ACT_LIMITTIME_APPEAR = 52,
    BOSS_CHALLENGE_EVENT_CONF = 53,
    LEGENDARY_BATTLE_EVENT = 54,
    LEGENDARY_CHALLENGE_CONF = 55,
    NPC_CHALLENGE_EVENT_CONF = 56,
    SECONDARY_TAB_CONF = 57,
    TAKEPHOTO_COMPETITION_CONF = 58,
    TERRITORY_TRIAL_CONF = 59,
    WEEKEND_CHALLENGE_GROUP_CONF = 60,
    WEEKLY_CHALLENGE_EVENT_CONF = 61,
    ACTIVITY_OPTION_CONF = 62,
    ACTIVITY_SPECIAL_TXT_CONF = 63,
    ACTIVITY_TASK_GO_CONF = 64,
    SPEC_BATTLE_UI = 65,
    ACTIVITY_GLOBAL_CHALLENGE = 66,
    ACTIVITY_GLOBAL_CHALLENGE_SIGN = 67,
    ACTIVITY_PET_TRIP_RULE = 68,
    ACTIVITY_SIGN_REWARD = 69,
    ACTIVITY_STAGE_REWARD_CONF = 70,
    PET_INFORMATION_CONF = 71,
    PRE_DOWNLOAD_CONF = 72,
    ACTIVITY_RECALLBP_CONF = 73,
    ACTIVITY_RECALL_CLASS_CONF = 74,
    ACTIVITY_RECALL_CONF = 75,
    ACTIVITY_RECALL_PET_CONF = 76,
    ACTIVITY_RECALL_STARLIGHTBUFF = 77,
    ACTIVITY_UMG_RULE_CONF = 78,
    COMPETITION_RULE_CONF = 79,
    CONTESTANT_REWARD_CONF = 80,
    JUDGE_REWARD_CONF = 81,
    ADVENTURE_CONF = 82,
    DAILY_TASK_REWARD_CONF = 83,
    REGION_CONF = 84,
    AI_BATTLE_RESULT_BEHAVIOR = 85,
    AI_BATTLE_RESULT_CONF = 86,
    NRC_AI_BB_INITIATE_CONF = 87,
    NRC_AI_BB_INPUT_CONF = 88,
    NRC_AI_BB_INSTANCE_CONF = 89,
    NRC_AI_BB_NAME_DEFINE_CONF = 90,
    NRC_AI_BEHAVIOR_CONF = 91,
    NRC_AI_BEHAVIOR_GROUP_CONF = 92,
    NRC_AI_CONE_MODER_CONF = 93,
    NRC_AI_FSM_COND_CONF = 94,
    NRC_AI_FSM_STATE_CONF = 95,
    NRC_AI_FSM_STRUCTURE_CONF = 96,
    NRC_AI_GAMEPLAY_STATETRANS_CONF = 97,
    NRC_AI_GAMEPLAY_STATE_CONF = 98,
    NRC_AI_GAMEPLAY_TAG_CONF = 99,
    NRC_AI_GLOBAL_CONFIG_CONF = 100,
    NRC_AI_GROUP_INFO_CONF = 101,
    NRC_AI_MUTUAL_EXCLUSION_CONF = 102,
    NRC_AI_OVERWRITE_BEHAVIOR_CONF = 103,
    NRC_AI_PERCEPTION_AUDIO_CONF = 104,
    NRC_AI_PERCEPTION_MODER_CONF = 105,
    NRC_AI_PERCEPTION_VISUAL_CONF = 106,
    NRC_AI_PERFORM_POOL_CONF = 107,
    NRC_AI_PERFORM_SKILL_CONF = 108,
    NRC_AI_RELATION_SCHEMA_CONF = 109,
    NRC_AI_SENSE_CONE_CONF = 110,
    NRC_AI_SENSE_EVENT_CONF = 111,
    NRC_AI_WORLD_COMBAT_SKILL_CONF = 112,
    NRC_AI_WORLD_EVENT_CONF = 113,
    NRC_GROUP_AI_BASIC_INFO_CONF = 114,
    NRC_GROUP_AI_BEHAVIOR_CONF = 115,
    NRC_GROUP_AI_DISMISS_CONF = 116,
    NRC_GROUP_AI_DYNAMIC_EVENT_CONF = 117,
    NRC_GROUP_AI_EVENT_CONF = 118,
    NRC_GROUP_AI_MOVE_CONF = 119,
    NRC_GROUP_AI_ROLE_TYPE_CONF = 120,
    NRC_GROUP_AI_STATION_CONF = 121,
    NRC_HOME_AI_CONF = 122,
    ALL_RIDE_PET = 123,
    ALL_RIDE_UI_CONF = 124,
    RIDE_ANIMATION = 125,
    RIDE_BASIC_MOVEMENT = 126,
    RIDE_EFFECTS = 127,
    RIDE_PASSIVE_SKILL = 128,
    RIDE_SOCKET = 129,
    RIDE_SOCKET_EXPORT = 130,
    ANIM_CONF = 131,
    ANIM_ID_CONF = 132,
    ANIM_MOTION_CURVE_CONF = 133,
    AREA_CHECK_CONF = 134,
    AREA_CONF = 135,
    AREA_FUNC_CONF = 136,
    AREA_GROUP_CONF = 137,
    AREA_SCENEOBJ_CONF = 138,
    AREA_TAG_CONF = 139,
    AREA_TRIG_CONF = 140,
    AREA_UI_CONF = 141,
    AREA_VISIBLE_CONF = 142,
    AREA_WEATHER_CONF = 143,
    AUDIO_CAVE_CONF = 144,
    AUDIO_FUBEN_CONF = 145,
    AUDIO_LENGTH_CONF = 146,
    AUDIO_MODEL_CONF = 147,
    AUDIO_NATURE_CONF = 148,
    PET_HOME_LIMIT_CONF = 149,
    PET_NAME_MAP_CONF = 150,
    BATTLE_USED_BY_TASK_CONF = 151,
    DIALOGUE_ONLY_OPTION_CONF = 152,
    DIALOGUE_USED_BY_TASK_CONF = 153,
    FUNCTION_BAN_SPECIAL_NPC_CONF = 154,
    HABITAT_CONF = 155,
    HOME_USED_BY_TASK_CONF = 156,
    MOVIE_USED_BY_TASK_CONF = 157,
    OPTION_USED_BY_TASK_CONF = 158,
    PETBASE_USED_BY_FASHION_BOND = 159,
    SEQUENCE_USED_BY_TASK_CONF = 160,
    BAG_ITEM_CONF = 161,
    BAG_ITEM_SEQUENCE = 162,
    BAG_ITEM_TYPE_CONF = 163,
    BAG_PET_GIFT_EFFECT_CONF = 164,
    BATTLE_ITEM_CONF = 165,
    ITEM_LABLE_TYPE_CONF = 166,
    PET_CARRYON_ITEM = 167,
    PET_CARRYON_UPGRADE = 168,
    PLAYER_MAGIC_CONF = 169,
    THROW_FUNC_CONF = 170,
    BALL_ACT = 171,
    BALL_CONF = 172,
    BALL_FORBID_CAPTURE = 173,
    AI_MODEL_WARM_CONF = 174,
    AONE_FINAL_BATTLE_PETSLIST_CONF = 175,
    BATTLE_CONF = 176,
    BATTLE_RULE_CONF = 177,
    BATTLE_TYPE_CONF = 178,
    BATTLE_PASS_CONF = 179,
    BATTLE_PASS_GIFT_CONF = 180,
    BATTLE_PASS_REWARD_CONF = 181,
    BATTLE_PASS_TASK_MODULE_CONF = 182,
    BATTLE_PASS_THEME_CONF = 183,
    BATTLE_PASS_UI_COLOR = 184,
    BATTLE_PASS_UI_THEME = 185,
    BATTLE_GUIDE_CONF = 186,
    COMBAT_MECHANISM_BATTLE_CONF = 187,
    COMBAT_MECHANISM_TEACH_CONF = 188,
    TYPE_ADVANTAGE_BATTLE_CONF = 189,
    TYPE_ADVANTAGE_TEACH_CONF = 190,
    BEHAVIOR_CONF = 191,
    BST_CONF = 192,
    WORLD_BUFF_CONF = 193,
    CAMERA_CONF = 194,
    CAMERA_MOVE_LITE = 195,
    CAMERA_PATH = 196,
    CAMP_CONF = 197,
    CAMP_CONTENT_NPC_CONF = 198,
    CAMP_LEVELUP_CONF = 199,
    CAMP_PET_REPORT_CONF = 200,
    PET_FRUIT_CONF = 201,
    PET_SETTLED_BONUS_CONF = 202,
    REPORT_COIN_RATIO_CONF = 203,
    TRAVEL_SEQUENCE_CONF = 204,
    BOSS_CHALLENGE_CONF = 205,
    CHEER_POINT_CONF = 206,
    NPC_CHALLENGE_CONF = 207,
    TERRITORY_TRIAL_CHALLENGE_CONF = 208,
    WEEKLY_CHALLENGE_CONF = 209,
    WEEKLY_PHOTO_CONF = 210,
    CHAT_EMOJI_CONF = 211,
    CLIENT_PUBLIC_CMD = 212,
    CLIMB_CHAPTER_CONF = 213,
    STAGE_CONF = 214,
    COLLEGE_SELECTION_CONF = 215,
    TASK_DATA_GUARD_CONF = 216,
    ACTION_RESULT_TYPE_CONF = 217,
    CUSTOMCAMERA_CONF = 218,
    DIALOGUE_CONF = 219,
    DIALOGUE_ORDER_CONF = 220,
    FUNCTION_STORY_FLAG_CONF = 221,
    PERFORM_CONF = 222,
    SELECT_CONF = 223,
    DUNGEON_CONF = 224,
    DUNGEON_STAGE = 225,
    IMPORTANT_HIGH_VALUE_CONF = 226,
    IMPORTANT_ITEM_CONF = 227,
    IMPORTANT_OUTPUT_PATH_CONF = 228,
    IMPORTANT_PET_MUTATION_CONF = 229,
    EMOTION_CONF = 230,
    ITEM_UNLOCK_MAP_CONF = 231,
    EXCHANGE_CONF = 232,
    EXCHANGE_GOODS_CONF = 233,
    EXCHANGE_TIME_LIMIT_CONF = 234,
    WISH_EXCHANGE_CONF = 235,
    BOND_TAB_CONF = 236,
    BOND_TINT_CONF = 237,
    CHANGE_COLOUR_CONF = 238,
    CLOSET_TAB_CONF = 239,
    FASHION_BAGCHARM_CONF = 240,
    FASHION_BOND_CONF = 241,
    FASHION_CONFLICTTAG_CONF = 242,
    FASHION_DRESSFORM_CONF = 243,
    FASHION_ITEM_CONF = 244,
    FASHION_PACKAGE_CONF = 245,
    FASHION_PERFORM_CONF = 246,
    FASHION_SUITS_CONF = 247,
    FASHION_TAB_CONF = 248,
    FASHION_VI_CONF = 249,
    FASHION_WAND_CONF = 250,
    HEADWEAR_HAIR_CONF = 251,
    HEADWEAR_OFFSET_CONF = 252,
    HEADWEAR_TYPE_CONF = 253,
    ITEM_TRANS_CONF = 254,
    PRIVILEGE_RIDE_CONF = 255,
    PRIVILEGE_WAND_CONF = 256,
    SALON_ITEM_CONF = 257,
    SALON_TAB_CONF = 258,
    FIX_DATA_EVOLUTION_ERROR = 259,
    EXCHANGE_NORMAL_FILTER_CONF = 260,
    HANDBOOK_FILTER_CONF = 261,
    HOME_FILTER_CONF = 262,
    PET_FILTER_CONF = 263,
    SKILLMACHINE_FILTER_CONF = 264,
    SKILL_FILTER_CONF = 265,
    TRAVEL_FILTER_CONF = 266,
    NPC_FOLLOW_CONF = 267,
    NPC_FOLLOW_TALK_CONF = 268,
    FRIEND_RECOMMEND_CONF = 269,
    BAN_ACTION_CONF = 270,
    BAN_NPC_CONF = 271,
    FUNCTION_BAN_CONF = 272,
    FUNCTION_BAN_SCENE_RES_CONF = 273,
    HIDE_PLAYER_MANUAL_OPTION_CONF = 274,
    SYSTEM_RED_POINT_BAN_CONF = 275,
    UI_BAN_CONF = 276,
    UI_ENTER_BAN_CONF = 277,
    COLOR_RANDOM_CONF = 278,
    GLASS_TYPE_CONF = 279,
    HIDDEN_GLASS_CONF = 280,
    PARTICLE_RANDOM_CONF = 281,
    ACTIVITY_GLOBAL_CONFIG = 282,
    ANTI_CHEAT_GLOBAL_CONFIG = 283,
    ATTR_GLOBAL_CONFIG = 284,
    BATTLE_GLOBAL_CONFIG = 285,
    BP_GLOBAL_CONFIG = 286,
    CHALLENGE_GLOBAL_CONF = 287,
    DAILY_GLOBAL_CONFIG = 288,
    FRIEND_GLOBAL_CONFIG = 289,
    GLOBAL_CONFIG = 290,
    HOME_GLOBAL_CONFIG = 291,
    LEGENDARY_GLOBAL_CONFIG = 292,
    LLM_GLOBAL_CONFIG = 293,
    MAP_GLOBAL_CONFIG = 294,
    NPC_GLOBAL_CONFIG = 295,
    ONLINE_GLOBAL_CONFIG = 296,
    PAYMENT_GLOBAL_CONFIG = 297,
    PET_GLOBAL_CONFIG = 298,
    ROGUE_CHALLENGE_GLOBAL_CONFIG = 299,
    ROLE_GLOBAL_CONFIG = 300,
    SEASON_GLOBAL_CONFIG = 301,
    TAKEPHOTO_GLOBAL_CONFIG = 302,
    TASK_GLOBAL_CONFIG = 303,
    GM_AI_GROUP_CONF = 304,
    GM_BUTTON_CONF = 305,
    GM_COMMAND_CONF = 306,
    GM_GROUP_CONF = 307,
    GM_MAINTAB_CONF = 308,
    GM_SERVER_CMD_CONF = 309,
    GM_SUBTAB_CONF = 310,
    GRASS_TRIAL_CHAPTER_CONF = 311,
    GRASS_TRIAL_CONF = 312,
    GRASS_TRIAL_EFFECT_CONF = 313,
    GRASS_TRIAL_EVENT_CONF = 314,
    GUIDE_ANIMATION_IGNORE_CONF = 315,
    GUIDE_BANNER_CONF = 316,
    GUIDE_BUTTON_CONF = 317,
    GUIDE_CTRL_CONF = 318,
    GUIDE_DRAG_CONF = 319,
    GUIDE_FOCUS_CONF = 320,
    GUIDE_IA_CONF = 321,
    GUIDE_PANEL_CONF = 322,
    HINT_LEVEL = 323,
    FURNITURE_CLASSIFICATION_CONF = 324,
    FURNITURE_EFFECT_CONF = 325,
    FURNITURE_HANDBOOK_CONF = 326,
    FURNITURE_ITEM_CONF = 327,
    FURNITURE_VERSION_CONF = 328,
    HOME_COMFORT_CONF = 329,
    HOME_LEVEL_CONF = 330,
    HOME_PET_FEED_CONF = 331,
    HOME_PET_LAY_EGG_RATE_CONF = 332,
    INTERIOR_FINISH_CONF = 333,
    PLANT_GROW_CONF = 334,
    PLANT_GROW_STAGE_CONF = 335,
    PLANT_LAND_COORDINATE_CONF = 336,
    PLANT_TAB_CONF = 337,
    ROOM_CONF = 338,
    IOS_RATING_POPUP_CONF = 339,
    LINE_CONF = 340,
    LLM_PET_BEHAVIOR_CONF = 341,
    LLM_PET_NATURE_CONF = 342,
    LOADING_TIPS_CONF = 343,
    PVP_MATCH_TIPS_CONF = 344,
    LOCALIZATION_CONF = 345,
    SUB_EVENTS_CONF = 346,
    SUB_TPLS_CONF = 347,
    ALL_DIALOGUE_EN = 348,
    TASK_DIALOGUE_EN = 349,
    LOTTERY_RESULT_PAGE_CONF = 350,
    LOTTERY_REWARD_CONF = 351,
    MAGE_CONF = 352,
    MAGE_HELP_CONF = 353,
    MAGE_INFO_CONF = 354,
    MAGE_REST_CONF = 355,
    MAGIC_BASE_CONF = 356,
    MAGIC_INTERACT_CONF = 357,
    MAGIC_TRANSFORM_CONF = 358,
    STAR_MAGIC_CONF = 359,
    CALLBACK_MAIL_CONF = 360,
    MAIL_CONF = 361,
    NOTICE_CONF = 362,
    MALL_CONF = 363,
    MALL_RAND_CONF = 364,
    MALL_STORE_CONF = 365,
    MARK_FAKE_MAGIC_MESSAGE_CONF = 366,
    MARK_GAMEPLAY_CONF = 367,
    MARK_MESSAGE_CHILD_CONF = 368,
    MARK_MESSAGE_LIFE_TIME_CONF = 369,
    MARK_VIDEO_PROTOCOL = 370,
    MEDAL_BOND_CONF = 371,
    MEDAL_CONF = 372,
    MEDAL_TASK_CONF = 373,
    TEXT_EXP_CONF = 374,
    MEGAMAP_CLASS_NAME_CONF = 375,
    MEGAMAP_CONF = 376,
    MEGAMAP_GATHERING_CONF = 377,
    MEGAMAP_MAP_CONF = 378,
    MEGAMAP_OVERLAP_CONF = 379,
    MEGAMAP_REFRESH_BLACKLIST = 380,
    MEGAMAP_SPEED_CONF = 381,
    MINIGAME_CONF = 382,
    MINIGAME_RULE_CONF = 383,
    MODEL_COLLISION_CONF = 384,
    MODEL_CONF = 385,
    MODEL_MAT_CONF = 386,
    MODEL_SOCKET_CONF = 387,
    BLOOD_MONSTER_SKILLBANK_CONF = 388,
    CATCH_CONDITION_CONF = 389,
    ESCAPE_INFO_CONF = 390,
    MONSTER_CATCH_CONF = 391,
    MONSTER_CONF = 392,
    MONSTER_GROWTH_CONF = 393,
    MONSTER_SKILLBANK_CONF = 394,
    SPECIAL_MOVE_CONF = 395,
    MUSIC_APPLY_LIST_CONF = 396,
    MUSIC_CONF = 397,
    MUSIC_FREEMIUM_CONF = 398,
    MUSIC_TYPE_CONF = 399,
    NIGHTMARE_ELITE_CONF = 400,
    SEASON_ELITE_CONF = 401,
    AI_WORD_CONF = 402,
    BATTLE_RANDOM_CONF = 403,
    LOCATION_INTERACT_BAN = 404,
    NPC_ACTION_CONF = 405,
    NPC_ACTOR_POOL_CONF = 406,
    NPC_AURA_CONF = 407,
    NPC_AURA_EFFECT_CONF = 408,
    NPC_COMPASS_OPTION = 409,
    NPC_CONF = 410,
    NPC_OPTION_CONF = 411,
    NPC_PEER_CONF = 412,
    NPC_REACTION_CONF = 413,
    PET_INTERACTION_COMPLEX = 414,
    PET_INTERACTION_CONF = 415,
    TASK_NPC = 416,
    NPC_COMB_OPTION_CONF = 417,
    NPC_COMB_RESULT_CONF = 418,
    NPC_PENDANT_CONF = 419,
    BONUS_CONTAINER_CONF = 420,
    BONUS_EVENT_POOL_CONF = 421,
    BONUS_SHINING_STG_CONF = 422,
    BONUS_SPE_EVENT_POOL_CONF = 423,
    NPC_REFRESH_BONUS_CONF = 424,
    NPC_REFRESH_CONTENT_CONF = 425,
    NPC_REFRESH_GROUP_CONF = 426,
    NPC_REFRESH_RULE_CONF = 427,
    NPC_REFRESH_TIME_CONF = 428,
    NPC_SERVER_REFRESH_CONF = 429,
    REFRESH_COND_CONF = 430,
    WEIGHT_GROUP_CONF = 431,
    OPERATION_MAIL = 432,
    OWL_CONTENT_NPC_CONF = 433,
    OWL_PET_FRUIT_CONF = 434,
    OWL_SANCTUARY_CONF = 435,
    PARAGRAPH_PACKAGE_ORDER_CONF = 436,
    PARAGRAPH_VO_CONF = 437,
    AREA_HANDBOOK = 438,
    BASE_POINT_CONF = 439,
    BREAK_ITEM_CONF = 440,
    BREAK_NUMBER_CONF = 441,
    BREAK_REWARD_CONF = 442,
    CRYSTAL_CONF = 443,
    EGG_TYPE_CONF = 444,
    EVOLUTION_ACTION_DATA = 445,
    EVOLUTION_LEVEL_DATA = 446,
    GROW_LEVEL_CONF = 447,
    INSPIRE_LEVEL_CONF = 448,
    LEVEL_GET_FIX_CONF = 449,
    LEVEL_SKILL_CONF = 450,
    NATURE_CONF = 451,
    OVERLEVEL_RATIO_EXP = 452,
    PETBASE_CONF = 453,
    PETFREE_CONF = 454,
    PETPAGE_BLACKLIST = 455,
    PET_ACTION_CLOSE_EXP_CONF = 456,
    PET_BAG_SEQUENCE = 457,
    PET_BLOOD_CONF = 458,
    PET_BOND = 459,
    PET_BOND_COUNT = 460,
    PET_CLASSIS_CONF = 461,
    PET_CLOSE_LEVEL_EFFECT_CONF = 462,
    PET_CONF = 463,
    PET_EFFORTS_LEVEL = 464,
    PET_EGG_CONF = 465,
    PET_EGG_WAY_TO_PROB_CONF = 466,
    PET_EVOLUTION_CONF = 467,
    PET_FEATURE_RAND = 468,
    PET_FREE_REWARD_CONF = 469,
    PET_HABIT_CONF = 470,
    PET_HANDBOOK = 471,
    PET_HANDBOOK_REWARD = 472,
    PET_HANDBOOK_SEQUENCE = 473,
    PET_LEVEL_CONF = 474,
    PET_LIKE_ELEMENT_CONF = 475,
    PET_MARK_CONF = 476,
    PET_REPORT_SCORE_CONF = 477,
    PET_SCENE_ABILITY_GANZHI = 478,
    PET_SHOW_SPEED_CONF = 479,
    PET_TALENT_CONF = 480,
    PET_TALENT_RANDOM_CONF = 481,
    PET_TOPIC_TYPE_CONF = 482,
    PET_UI_CAMERA_CONF = 483,
    SEASON_HANDBOOK_CONF = 484,
    SKILL_COLOR_CONF = 485,
    SKILL_RANDOM_CONF = 486,
    SKILL_SEQUENCE_CONF = 487,
    SUBMIT_PET_CONF = 488,
    UNCOMMAND_PET_SKILL_CONF = 489,
    PET_INFO_CONF = 490,
    PET_RANDOM_EGG_CONF = 491,
    PET_PARTNER_DATA = 492,
    PET_ROLLBACK_CONF = 493,
    POINT_CONF = 494,
    PLATFORM_PRIVILEGES = 495,
    PROTO_CMD_SEQ_CONF = 496,
    PET_TYPE_SCORE_CONF = 497,
    PVP_AWARD_CONF = 498,
    PVP_BATTLE_SCORE_CONF = 499,
    PVP_CONF = 500,
    PVP_RANDOM_PET_LIBRARY_CONF = 501,
    PVP_RANDOM_PET_REWARD_CONF = 502,
    PVP_RANDOM_SKILL_LIBRARY_CONF = 503,
    PVP_RANDOM_SKILL_LIST_CONF = 504,
    PVP_RANK_CONF = 505,
    PVP_RANK_PLAYER_POLL_CONF = 506,
    PVP_RANK_RANDOM_PET_CONF = 507,
    PVP_RANK_ROBOT_CARD_ICON_CONF = 508,
    PVP_RANK_ROBOT_NAME_CONF = 509,
    PVP_RANK_ROBOT_PLAYER_CONF = 510,
    PVP_RANK_SEASON_CONF = 511,
    PVP_RANK_TRIAL_PET_CONF = 512,
    PVP_RANK_TRIAL_PET_LIBRARY_CONF = 513,
    PVP_RANK_WEEK_TASK_CONF = 514,
    PVP_ROBOT_CONF = 515,
    PVP_WAREHOUSE_CONF = 516,
    TOP_MASTER_CONF = 517,
    RANKBOARD_CONF = 518,
    READ_CONF = 519,
    REACALL_CONF = 520,
    REACALL_LIST_CONF = 521,
    REACALL_TREMS_CONF = 522,
    RED_POINT_CONF = 523,
    INTERACTIONTREE_CONF = 524,
    RELATIONTREE_ANIM_CONF = 525,
    RELATIONTREE_BASIC_CONF = 526,
    RELATIONTREE_CONF = 527,
    RESOURCE_CONF = 528,
    LOTTERY_POOL_CONF = 529,
    LOTTERY_POOL_REWARD_CONF = 530,
    REWARD_CONF = 531,
    REWARD_TAG = 532,
    REWARD_WEIGHT_CHANGE_CONF = 533,
    EVENT_BASE_CONF = 534,
    EVENT_COMBINE_CONF = 535,
    ROGUE_LEVEL_CONF = 536,
    UPGRADE_CONF = 537,
    BOTTLE_TIMES_CONF = 538,
    BOTTLE_VOLUME_CONF = 539,
    HP_MAX_CONF = 540,
    POWER_MAX_CONF = 541,
    ROLE_EXP_CONF = 542,
    ROLE_STAR_NPCLEVEL_CHANGE_CONF = 543,
    ROLE_WORLD_LEVEL_MAP_CONF = 544,
    WORLD_LEVEL_CONF = 545,
    CARD_ADVENTURE_RECORD_CONF = 546,
    CARD_ICON_CONF = 547,
    CARD_LABEL_CONF = 548,
    CARD_MODULE_CONF = 549,
    CARD_SKIN_CONF = 550,
    EQS_BOX_EXPORT = 551,
    PET_BEHAVIOR_REACTION_CONF = 552,
    ROLEPLAY_BEHAVIOR_CONF = 553,
    ROLEPLAY_PROP_CONF = 554,
    ROLEPLAY_SORT_CONF = 555,
    SCENE_AWARD_CONF = 556,
    SCENE_CONF = 557,
    SCENE_OBJECT_AWARD = 558,
    SCENE_OBJECT_CONF = 559,
    SCENE_RES_CONF = 560,
    SCENE_UPGRADE_VERSION_CONF = 561,
    SCENE_ABILITY_ASCENDING_CONF = 562,
    SCENE_ABILITY_CONF = 563,
    SCENE_ABILITY_DASH_CONF = 564,
    SCENE_ABILITY_FLYING_CONF = 565,
    SCENE_ABILITY_RIDING_CONF = 566,
    SCENE_ABILITY_SLIDING_CONF = 567,
    SCENE_ABILITY_THROW_CONF = 568,
    SCENE_PLAYER_STATUS_MATRIX = 569,
    VITALITY_CONF = 570,
    SCENE_EFFECT_CONF = 571,
    ABNORMAL_STATUS_CONF = 572,
    SCENE_STATUS_SALS_CONF = 573,
    SCENE_STATUS_WPST_CONF = 574,
    SEASON_BATTLE_RULE_CONF = 575,
    SEASON_CONF = 576,
    SEASON_GROWTH_CONF = 577,
    SEASON_ITEM_CONF = 578,
    SEASON_LEGENDARY_BATTLE_EVENT = 579,
    SEASON_PART_CONF = 580,
    SEASON_PETBASE = 581,
    SEASON_PET_CATCH_REWARD_CONF = 582,
    SEASON_PVE_BASE_CONF = 583,
    SEASON_SKILL = 584,
    SEASON_TALENT_CONF = 585,
    SEASON_ADVENTURE_BADGE_LEVEL = 586,
    SEASON_ADVENTURE_CHAPTER = 587,
    SEASON_ADVENTURE_CONF = 588,
    SEASON_ADVENTURE_UI = 589,
    BONUSCATCH_REFRESH_RULE_CONF = 590,
    SEASON_BONUSCATCH_BOX_CONF = 591,
    SEASON_BONUSCATCH_EFFECTS_CONF = 592,
    SEASON_BONUSCATCH_LIMIT_CONF = 593,
    SEASON_BONUSCATCH_SEC_OPT_CONF = 594,
    SEASON_PET_EFFECTS_CONF = 595,
    SEASON_FOCUS_UMG_CONF = 596,
    SEASON_TIPS_NEW_PET_CONF = 597,
    SEASON_TIPS_PVP_CONF = 598,
    SEASON_TIPS_TAB_CONF = 599,
    SEASON_TIPS_TXT_CONF = 600,
    SEASON_TPT_COMMON_CONF = 601,
    SEAT_CONF = 602,
    SECOND_TIER_PASSWORD_CONF = 603,
    MOVIE_CONF = 604,
    SEQUENCE_CONF = 605,
    SUBTITLE_CONF = 606,
    RPC_LOSS_RATE_CONF = 607,
    BUTTON_SETTING_CONF = 608,
    DEFAULT_BUTTON_CONF = 609,
    RESOLUTION_CONF = 610,
    UI_KEYNAME_CONVERT = 611,
    PET_SHARE_ITEM_CONF = 612,
    QQ_ARK_SHARE_CONF = 613,
    SHARE_BASE_CONF = 614,
    SHARE_CONF = 615,
    SHARE_PART_CONF = 616,
    SHARE_REWARD_CONF = 617,
    GOODS_RETURN_CONF = 618,
    MALL_FRAME_CONF = 619,
    MALL_MONTHLY_PASS_REWARD = 620,
    NORMAL_SHOP_CONF = 621,
    RANDOM_GOODS_CONF = 622,
    RANDOM_SHOP_CONF = 623,
    SHOP_BAN_CONF = 624,
    SHOP_CONF = 625,
    SHOP_TOTAL_CONSUMPTION_CONF = 626,
    ATTRIBUTE_CONF = 627,
    BUFFBASE_CONF = 628,
    BUFF_CONF = 629,
    BUFF_TYPE = 630,
    DESC_NOTE_CONF = 631,
    EFFECT_ANIMATION = 632,
    EFFECT_CONF = 633,
    ENTERBATTLE_BUFF_PRIORITY = 634,
    FIELD_LAYER_CONF = 635,
    PREATTACK_SKILL = 636,
    RES_BGS_TIME_CONF = 637,
    RES_BUFF_TIME_CONF = 638,
    RES_SKILL_TIME_CONF = 639,
    SKILLFULLY_EXCHANGE_CONF = 640,
    SKILLSPECIAL_CONF = 641,
    SKILL_CONF = 642,
    SKILL_INTERACT_CONF = 643,
    SKILL_RES_CHANGE_CONF = 644,
    SKILL_RES_CONF = 645,
    SKILL_TAG = 646,
    SKILL_TIME_CONF = 647,
    SKILL_UI_DES = 648,
    TYPE_DICTIONARY = 649,
    SLIDE_CONF = 650,
    BOTTLE_CONF = 651,
    FRUIT_TREE_CONF = 652,
    FRUIT_TREE_RULE_CONF = 653,
    WIND_GRASS = 654,
    SPLINE_CONF = 655,
    LEGENDARY_BATTLE_AWARD = 656,
    STAR_AWARD_CONF = 657,
    TEAM_BATTLE_AWARD = 658,
    ACTCONTROLCONFIG = 659,
    CHANNELCONTROLCONFIG = 660,
    SYSTEMCONTROLCONFIG = 661,
    CAMERA_SKIN_CONF = 662,
    TAKE_PHOTO_EMOJI_CONF = 663,
    TAKE_PHOTO_FILTER_CONF = 664,
    TAKE_PHOTO_POSE_CONF = 665,
    CHAPTER_CONF = 666,
    GP_CONTEST_CONF = 667,
    GUIDE_CONF = 668,
    MESSAGE_CONF = 669,
    PARAGRAPH_CONF = 670,
    STORY_BGM_CONF = 671,
    SUB_TASK_CONF = 672,
    TALE_BLOOD_MAGIC_CONF = 673,
    TALE_NIGHTMARE_CONF = 674,
    TALE_NOTEBOOK_KELI_CONF = 675,
    TASK_CONF = 676,
    TASK_ITEM = 677,
    TASK_MODULE_CONF = 678,
    TASK_PET_PARAM_CONF = 679,
    TASK_STATE_CONF = 680,
    TASK_STYLE_CONF = 681,
    TASK_SUMMARY = 682,
    TASK_SWITCH_CONF = 683,
    TASK_TOKEN_CONF = 684,
    TRACK_NUMBER = 685,
    UNIT_CONF = 686,
    TEACH_CONF = 687,
    TEACH_TAB_CONF = 688,
    SCENE_ENTER_EXIT = 689,
    TELEPORT_CONF = 690,
    TELEPORT_LOADING_CONF = 691,
    TELEPORT_RULES_CONF = 692,
    ENV_TAG_CONF = 693,
    TEST_RECHARGE_AMOUNT_CONF = 694,
    TITLE_CONF = 695,
    TREASURE_ITEM_CONF = 696,
    SPE_REFRESH_TRIG_CONF = 697,
    UI_COMPASS = 698,
    UI_CONF = 699,
    UI_LOBBY_MAIN_COMPASS = 700,
    UI_RECONNECT = 701,
    BALLTLEPASS_AWARDMAIN_CONF = 702,
    BATTLEPASS_PURCHASE_CONF = 703,
    UMG_DIALOG_CONF = 704,
    UMG_STATIC_CONF = 705,
    VIDEO_SUBTITLES_CONF = 706,
    VISUAL_ITEM_CONF = 707,
    PET_WAREHOUSE_CONF = 708,
    TIDY_SEQUENCE_TYPE = 709,
    WAREHOUSE_COLLECT_MARK = 710,
    WATER_MARK_CONTROL_CONF = 711,
    WATER_MARK_LOCALIZATION_CONF = 712,
    WATER_MARK_WHITE_LIST_CONF = 713,
    TOD_CONF = 714,
    WEATHER_CONF = 715,
    ACTION_ANIM_BONE_TRANSFORM_INFO = 716,
    BLOCK_CONF = 717,
    BOSS_SKILLS_MAP_CONF = 718,
    CURVE_DETAIL_INFO = 719,
    SKILL_ANIM_SOCKETS_INFO = 720,
    WEAKNESS_CONF = 721,
    WORLD_COMBAT_CONF = 722,
    WORLD_COMBAT_SKILL_CONF = 723,
    WORLD_COMBAT_SKILL_CURVE_CONF = 724,
    LAYERED_WORLD_MAP_CONF = 725,
    MAP_INFO_BAR_CONF = 726,
    WORLD_EXPLORING_STATISTIC_CONF = 727,
    WORLD_MAP_ACTIVITY_CONF = 728,
    WORLD_MAP_AREA_GUIDE = 729,
    WORLD_MAP_BLOCK_CONF = 730,
    WORLD_MAP_CHALLENGE_CONF = 731,
    WORLD_MAP_CONF = 732,
    WORLD_MAP_DEFAULT_TRACK = 733,
    WORLD_MAP_GLOBAL_CONF = 734,
    WORLD_MAP_SCALE_CONF = 735,
    WORLD_ZONE_CONF = 736,
    ZONE_EFFECT_CONF = 737
  }
  local configTableInfo = {
    [1] = {
      name = "CHINA_BENCHMARK_DEVICE_CONF"
    },
    [2] = {
      name = "PC_LEVEL_CPU_AMD_CONF"
    },
    [3] = {
      name = "PC_LEVEL_CPU_INTEL_CONF"
    },
    [4] = {
      name = "PC_LEVEL_GPU_AMD_CONF"
    },
    [5] = {
      name = "PC_LEVEL_GPU_NVIDIA_CONF"
    },
    [6] = {
      name = "WORLD_BENCHMARK_DEVICE_CONF"
    },
    [7] = {
      name = "BASIC_QUALITY_CONFIG_CONF"
    },
    [8] = {
      name = "OVERRIDE_QUALITY_CONF"
    },
    [9] = {
      name = "QUALITY_DEFAULT_CONF"
    },
    [10] = {
      name = "QUALITY_GROUP_SETTING_CONF"
    },
    [11] = {
      name = "QUALITY_LOCALIZATION_CONF"
    },
    [12] = {
      name = "QUALITY_MAPPING_CONF"
    },
    [13] = {
      name = "ACTIVITY_COMMON_SHOW_CONF"
    },
    [14] = {
      name = "ACTIVITY_CONDITION_GROUP_CONF"
    },
    [15] = {
      name = "ACTIVITY_CONDITION_REWARD_CONF"
    },
    [16] = {
      name = "ACTIVITY_CONF"
    },
    [17] = {
      name = "ACTIVITY_DROP_CONF"
    },
    [18] = {
      name = "ACTIVITY_DROP_METHOD_CONF"
    },
    [19] = {
      name = "ACTIVITY_FACTION_CONF"
    },
    [20] = {
      name = "ACTIVITY_FLOWER_APPEAR_CONF"
    },
    [21] = {
      name = "ACTIVITY_FLOWER_TASK_CONF"
    },
    [22] = {
      name = "ACTIVITY_GOODS_CONF"
    },
    [23] = {
      name = "ACTIVITY_INHERITANCE_CONF"
    },
    [24] = {
      name = "ACTIVITY_INVITE_REGISTER_CONF"
    },
    [25] = {
      name = "ACTIVITY_MAINTAB_CONF"
    },
    [26] = {
      name = "ACTIVITY_MIX_CONF"
    },
    [27] = {
      name = "ACTIVITY_PET_CATCH_CONF"
    },
    [28] = {
      name = "ACTIVITY_PET_CERTIFICATION"
    },
    [29] = {
      name = "ACTIVITY_PET_COLLECTION_CONF"
    },
    [30] = {
      name = "ACTIVITY_PET_PARTNER_CONF"
    },
    [31] = {
      name = "ACTIVITY_PET_PHOTO"
    },
    [32] = {
      name = "ACTIVITY_PET_RAISE_CONF"
    },
    [33] = {
      name = "ACTIVITY_PET_RAISE_TASK_CONF"
    },
    [34] = {
      name = "ACTIVITY_PET_TRIP_CONF"
    },
    [35] = {
      name = "ACTIVITY_PIKA_CONF"
    },
    [36] = {
      name = "ACTIVITY_PLAYER_CO_CREATION"
    },
    [37] = {
      name = "ACTIVITY_PREHEAT_CONF"
    },
    [38] = {
      name = "ACTIVITY_RELAY_PAGE"
    },
    [39] = {
      name = "ACTIVITY_REWARD_BY_STAGE_CONF"
    },
    [40] = {
      name = "ACTIVITY_SHINY_WEEKEND_CONF"
    },
    [41] = {
      name = "ACTIVITY_SHOP_CONF"
    },
    [42] = {
      name = "ACTIVITY_SPECIAL_CONF"
    },
    [43] = {
      name = "ACTIVITY_SPEC_FLOWER_SEED_CONF"
    },
    [44] = {
      name = "ACTIVITY_SPRING_FESTIVAL_CONF"
    },
    [45] = {
      name = "ACTIVITY_TLOG_CONF"
    },
    [46] = {
      name = "ACTIVITY_TRACK_CONDITION_CONF"
    },
    [47] = {
      name = "ACTIVITY_TREASURE_HUNT_CONF"
    },
    [48] = {
      name = "ACTIVITY_UP_CONF"
    },
    [49] = {
      name = "ACTIVITY_WEBSITE_PART_CONF"
    },
    [50] = {
      name = "ACTIVITY_WEEKEND_CHALLENGE_CONF"
    },
    [51] = {
      name = "ACTIVITY_WISH_LOTTER_AWARD"
    },
    [52] = {
      name = "ACT_LIMITTIME_APPEAR"
    },
    [53] = {
      name = "BOSS_CHALLENGE_EVENT_CONF"
    },
    [54] = {
      name = "LEGENDARY_BATTLE_EVENT"
    },
    [55] = {
      name = "LEGENDARY_CHALLENGE_CONF"
    },
    [56] = {
      name = "NPC_CHALLENGE_EVENT_CONF"
    },
    [57] = {
      name = "SECONDARY_TAB_CONF"
    },
    [58] = {
      name = "TAKEPHOTO_COMPETITION_CONF"
    },
    [59] = {
      name = "TERRITORY_TRIAL_CONF"
    },
    [60] = {
      name = "WEEKEND_CHALLENGE_GROUP_CONF"
    },
    [61] = {
      name = "WEEKLY_CHALLENGE_EVENT_CONF"
    },
    [62] = {
      name = "ACTIVITY_OPTION_CONF"
    },
    [63] = {
      name = "ACTIVITY_SPECIAL_TXT_CONF"
    },
    [64] = {
      name = "ACTIVITY_TASK_GO_CONF"
    },
    [65] = {
      name = "SPEC_BATTLE_UI"
    },
    [66] = {
      name = "ACTIVITY_GLOBAL_CHALLENGE"
    },
    [67] = {
      name = "ACTIVITY_GLOBAL_CHALLENGE_SIGN"
    },
    [68] = {
      name = "ACTIVITY_PET_TRIP_RULE"
    },
    [69] = {
      name = "ACTIVITY_SIGN_REWARD"
    },
    [70] = {
      name = "ACTIVITY_STAGE_REWARD_CONF"
    },
    [71] = {
      name = "PET_INFORMATION_CONF"
    },
    [72] = {
      name = "PRE_DOWNLOAD_CONF"
    },
    [73] = {
      name = "ACTIVITY_RECALLBP_CONF"
    },
    [74] = {
      name = "ACTIVITY_RECALL_CLASS_CONF"
    },
    [75] = {
      name = "ACTIVITY_RECALL_CONF"
    },
    [76] = {
      name = "ACTIVITY_RECALL_PET_CONF"
    },
    [77] = {
      name = "ACTIVITY_RECALL_STARLIGHTBUFF"
    },
    [78] = {
      name = "ACTIVITY_UMG_RULE_CONF"
    },
    [79] = {
      name = "COMPETITION_RULE_CONF"
    },
    [80] = {
      name = "CONTESTANT_REWARD_CONF"
    },
    [81] = {
      name = "JUDGE_REWARD_CONF"
    },
    [82] = {
      name = "ADVENTURE_CONF"
    },
    [83] = {
      name = "DAILY_TASK_REWARD_CONF"
    },
    [84] = {
      name = "REGION_CONF"
    },
    [85] = {
      name = "AI_BATTLE_RESULT_BEHAVIOR"
    },
    [86] = {
      name = "AI_BATTLE_RESULT_CONF"
    },
    [87] = {
      name = "NRC_AI_BB_INITIATE_CONF"
    },
    [88] = {
      name = "NRC_AI_BB_INPUT_CONF"
    },
    [89] = {
      name = "NRC_AI_BB_INSTANCE_CONF"
    },
    [90] = {
      name = "NRC_AI_BB_NAME_DEFINE_CONF"
    },
    [91] = {
      name = "NRC_AI_BEHAVIOR_CONF"
    },
    [92] = {
      name = "NRC_AI_BEHAVIOR_GROUP_CONF"
    },
    [93] = {
      name = "NRC_AI_CONE_MODER_CONF"
    },
    [94] = {
      name = "NRC_AI_FSM_COND_CONF"
    },
    [95] = {
      name = "NRC_AI_FSM_STATE_CONF"
    },
    [96] = {
      name = "NRC_AI_FSM_STRUCTURE_CONF"
    },
    [97] = {
      name = "NRC_AI_GAMEPLAY_STATETRANS_CONF"
    },
    [98] = {
      name = "NRC_AI_GAMEPLAY_STATE_CONF"
    },
    [99] = {
      name = "NRC_AI_GAMEPLAY_TAG_CONF"
    },
    [100] = {
      name = "NRC_AI_GLOBAL_CONFIG_CONF"
    },
    [101] = {
      name = "NRC_AI_GROUP_INFO_CONF"
    },
    [102] = {
      name = "NRC_AI_MUTUAL_EXCLUSION_CONF"
    },
    [103] = {
      name = "NRC_AI_OVERWRITE_BEHAVIOR_CONF"
    },
    [104] = {
      name = "NRC_AI_PERCEPTION_AUDIO_CONF"
    },
    [105] = {
      name = "NRC_AI_PERCEPTION_MODER_CONF"
    },
    [106] = {
      name = "NRC_AI_PERCEPTION_VISUAL_CONF"
    },
    [107] = {
      name = "NRC_AI_PERFORM_POOL_CONF"
    },
    [108] = {
      name = "NRC_AI_PERFORM_SKILL_CONF"
    },
    [109] = {
      name = "NRC_AI_RELATION_SCHEMA_CONF"
    },
    [110] = {
      name = "NRC_AI_SENSE_CONE_CONF"
    },
    [111] = {
      name = "NRC_AI_SENSE_EVENT_CONF"
    },
    [112] = {
      name = "NRC_AI_WORLD_COMBAT_SKILL_CONF"
    },
    [113] = {
      name = "NRC_AI_WORLD_EVENT_CONF"
    },
    [114] = {
      name = "NRC_GROUP_AI_BASIC_INFO_CONF"
    },
    [115] = {
      name = "NRC_GROUP_AI_BEHAVIOR_CONF"
    },
    [116] = {
      name = "NRC_GROUP_AI_DISMISS_CONF"
    },
    [117] = {
      name = "NRC_GROUP_AI_DYNAMIC_EVENT_CONF"
    },
    [118] = {
      name = "NRC_GROUP_AI_EVENT_CONF"
    },
    [119] = {
      name = "NRC_GROUP_AI_MOVE_CONF"
    },
    [120] = {
      name = "NRC_GROUP_AI_ROLE_TYPE_CONF"
    },
    [121] = {
      name = "NRC_GROUP_AI_STATION_CONF"
    },
    [122] = {
      name = "NRC_HOME_AI_CONF"
    },
    [123] = {
      name = "ALL_RIDE_PET"
    },
    [124] = {
      name = "ALL_RIDE_UI_CONF"
    },
    [125] = {
      name = "RIDE_ANIMATION"
    },
    [126] = {
      name = "RIDE_BASIC_MOVEMENT"
    },
    [127] = {
      name = "RIDE_EFFECTS"
    },
    [128] = {
      name = "RIDE_PASSIVE_SKILL"
    },
    [129] = {
      name = "RIDE_SOCKET"
    },
    [130] = {
      name = "RIDE_SOCKET_EXPORT"
    },
    [131] = {name = "ANIM_CONF"},
    [132] = {
      name = "ANIM_ID_CONF"
    },
    [133] = {
      name = "ANIM_MOTION_CURVE_CONF"
    },
    [134] = {
      name = "AREA_CHECK_CONF"
    },
    [135] = {name = "AREA_CONF"},
    [136] = {
      name = "AREA_FUNC_CONF"
    },
    [137] = {
      name = "AREA_GROUP_CONF"
    },
    [138] = {
      name = "AREA_SCENEOBJ_CONF"
    },
    [139] = {
      name = "AREA_TAG_CONF"
    },
    [140] = {
      name = "AREA_TRIG_CONF"
    },
    [141] = {
      name = "AREA_UI_CONF"
    },
    [142] = {
      name = "AREA_VISIBLE_CONF"
    },
    [143] = {
      name = "AREA_WEATHER_CONF"
    },
    [144] = {
      name = "AUDIO_CAVE_CONF"
    },
    [145] = {
      name = "AUDIO_FUBEN_CONF"
    },
    [146] = {
      name = "AUDIO_LENGTH_CONF"
    },
    [147] = {
      name = "AUDIO_MODEL_CONF"
    },
    [148] = {
      name = "AUDIO_NATURE_CONF"
    },
    [149] = {
      name = "PET_HOME_LIMIT_CONF"
    },
    [150] = {
      name = "PET_NAME_MAP_CONF"
    },
    [151] = {
      name = "BATTLE_USED_BY_TASK_CONF"
    },
    [152] = {
      name = "DIALOGUE_ONLY_OPTION_CONF"
    },
    [153] = {
      name = "DIALOGUE_USED_BY_TASK_CONF"
    },
    [154] = {
      name = "FUNCTION_BAN_SPECIAL_NPC_CONF"
    },
    [155] = {
      name = "HABITAT_CONF"
    },
    [156] = {
      name = "HOME_USED_BY_TASK_CONF"
    },
    [157] = {
      name = "MOVIE_USED_BY_TASK_CONF"
    },
    [158] = {
      name = "OPTION_USED_BY_TASK_CONF"
    },
    [159] = {
      name = "PETBASE_USED_BY_FASHION_BOND"
    },
    [160] = {
      name = "SEQUENCE_USED_BY_TASK_CONF"
    },
    [161] = {
      name = "BAG_ITEM_CONF"
    },
    [162] = {
      name = "BAG_ITEM_SEQUENCE"
    },
    [163] = {
      name = "BAG_ITEM_TYPE_CONF"
    },
    [164] = {
      name = "BAG_PET_GIFT_EFFECT_CONF"
    },
    [165] = {
      name = "BATTLE_ITEM_CONF"
    },
    [166] = {
      name = "ITEM_LABLE_TYPE_CONF"
    },
    [167] = {
      name = "PET_CARRYON_ITEM"
    },
    [168] = {
      name = "PET_CARRYON_UPGRADE"
    },
    [169] = {
      name = "PLAYER_MAGIC_CONF"
    },
    [170] = {
      name = "THROW_FUNC_CONF"
    },
    [171] = {name = "BALL_ACT"},
    [172] = {name = "BALL_CONF"},
    [173] = {
      name = "BALL_FORBID_CAPTURE"
    },
    [174] = {
      name = "AI_MODEL_WARM_CONF"
    },
    [175] = {
      name = "AONE_FINAL_BATTLE_PETSLIST_CONF"
    },
    [176] = {
      name = "BATTLE_CONF"
    },
    [177] = {
      name = "BATTLE_RULE_CONF"
    },
    [178] = {
      name = "BATTLE_TYPE_CONF"
    },
    [179] = {
      name = "BATTLE_PASS_CONF"
    },
    [180] = {
      name = "BATTLE_PASS_GIFT_CONF"
    },
    [181] = {
      name = "BATTLE_PASS_REWARD_CONF"
    },
    [182] = {
      name = "BATTLE_PASS_TASK_MODULE_CONF"
    },
    [183] = {
      name = "BATTLE_PASS_THEME_CONF"
    },
    [184] = {
      name = "BATTLE_PASS_UI_COLOR"
    },
    [185] = {
      name = "BATTLE_PASS_UI_THEME"
    },
    [186] = {
      name = "BATTLE_GUIDE_CONF"
    },
    [187] = {
      name = "COMBAT_MECHANISM_BATTLE_CONF"
    },
    [188] = {
      name = "COMBAT_MECHANISM_TEACH_CONF"
    },
    [189] = {
      name = "TYPE_ADVANTAGE_BATTLE_CONF"
    },
    [190] = {
      name = "TYPE_ADVANTAGE_TEACH_CONF"
    },
    [191] = {
      name = "BEHAVIOR_CONF"
    },
    [192] = {name = "BST_CONF"},
    [193] = {
      name = "WORLD_BUFF_CONF"
    },
    [194] = {
      name = "CAMERA_CONF"
    },
    [195] = {
      name = "CAMERA_MOVE_LITE"
    },
    [196] = {
      name = "CAMERA_PATH"
    },
    [197] = {name = "CAMP_CONF"},
    [198] = {
      name = "CAMP_CONTENT_NPC_CONF"
    },
    [199] = {
      name = "CAMP_LEVELUP_CONF"
    },
    [200] = {
      name = "CAMP_PET_REPORT_CONF"
    },
    [201] = {
      name = "PET_FRUIT_CONF"
    },
    [202] = {
      name = "PET_SETTLED_BONUS_CONF"
    },
    [203] = {
      name = "REPORT_COIN_RATIO_CONF"
    },
    [204] = {
      name = "TRAVEL_SEQUENCE_CONF"
    },
    [205] = {
      name = "BOSS_CHALLENGE_CONF"
    },
    [206] = {
      name = "CHEER_POINT_CONF"
    },
    [207] = {
      name = "NPC_CHALLENGE_CONF"
    },
    [208] = {
      name = "TERRITORY_TRIAL_CHALLENGE_CONF"
    },
    [209] = {
      name = "WEEKLY_CHALLENGE_CONF"
    },
    [210] = {
      name = "WEEKLY_PHOTO_CONF"
    },
    [211] = {
      name = "CHAT_EMOJI_CONF"
    },
    [212] = {
      name = "CLIENT_PUBLIC_CMD"
    },
    [213] = {
      name = "CLIMB_CHAPTER_CONF"
    },
    [214] = {name = "STAGE_CONF"},
    [215] = {
      name = "COLLEGE_SELECTION_CONF"
    },
    [216] = {
      name = "TASK_DATA_GUARD_CONF"
    },
    [217] = {
      name = "ACTION_RESULT_TYPE_CONF"
    },
    [218] = {
      name = "CUSTOMCAMERA_CONF"
    },
    [219] = {
      name = "DIALOGUE_CONF"
    },
    [220] = {
      name = "DIALOGUE_ORDER_CONF"
    },
    [221] = {
      name = "FUNCTION_STORY_FLAG_CONF"
    },
    [222] = {
      name = "PERFORM_CONF"
    },
    [223] = {
      name = "SELECT_CONF"
    },
    [224] = {
      name = "DUNGEON_CONF"
    },
    [225] = {
      name = "DUNGEON_STAGE"
    },
    [226] = {
      name = "IMPORTANT_HIGH_VALUE_CONF"
    },
    [227] = {
      name = "IMPORTANT_ITEM_CONF"
    },
    [228] = {
      name = "IMPORTANT_OUTPUT_PATH_CONF"
    },
    [229] = {
      name = "IMPORTANT_PET_MUTATION_CONF"
    },
    [230] = {
      name = "EMOTION_CONF"
    },
    [231] = {
      name = "ITEM_UNLOCK_MAP_CONF"
    },
    [232] = {
      name = "EXCHANGE_CONF"
    },
    [233] = {
      name = "EXCHANGE_GOODS_CONF"
    },
    [234] = {
      name = "EXCHANGE_TIME_LIMIT_CONF"
    },
    [235] = {
      name = "WISH_EXCHANGE_CONF"
    },
    [236] = {
      name = "BOND_TAB_CONF"
    },
    [237] = {
      name = "BOND_TINT_CONF"
    },
    [238] = {
      name = "CHANGE_COLOUR_CONF"
    },
    [239] = {
      name = "CLOSET_TAB_CONF"
    },
    [240] = {
      name = "FASHION_BAGCHARM_CONF"
    },
    [241] = {
      name = "FASHION_BOND_CONF"
    },
    [242] = {
      name = "FASHION_CONFLICTTAG_CONF"
    },
    [243] = {
      name = "FASHION_DRESSFORM_CONF"
    },
    [244] = {
      name = "FASHION_ITEM_CONF"
    },
    [245] = {
      name = "FASHION_PACKAGE_CONF"
    },
    [246] = {
      name = "FASHION_PERFORM_CONF"
    },
    [247] = {
      name = "FASHION_SUITS_CONF"
    },
    [248] = {
      name = "FASHION_TAB_CONF"
    },
    [249] = {
      name = "FASHION_VI_CONF"
    },
    [250] = {
      name = "FASHION_WAND_CONF"
    },
    [251] = {
      name = "HEADWEAR_HAIR_CONF"
    },
    [252] = {
      name = "HEADWEAR_OFFSET_CONF"
    },
    [253] = {
      name = "HEADWEAR_TYPE_CONF"
    },
    [254] = {
      name = "ITEM_TRANS_CONF"
    },
    [255] = {
      name = "PRIVILEGE_RIDE_CONF"
    },
    [256] = {
      name = "PRIVILEGE_WAND_CONF"
    },
    [257] = {
      name = "SALON_ITEM_CONF"
    },
    [258] = {
      name = "SALON_TAB_CONF"
    },
    [259] = {
      name = "FIX_DATA_EVOLUTION_ERROR"
    },
    [260] = {
      name = "EXCHANGE_NORMAL_FILTER_CONF"
    },
    [261] = {
      name = "HANDBOOK_FILTER_CONF"
    },
    [262] = {
      name = "HOME_FILTER_CONF"
    },
    [263] = {
      name = "PET_FILTER_CONF"
    },
    [264] = {
      name = "SKILLMACHINE_FILTER_CONF"
    },
    [265] = {
      name = "SKILL_FILTER_CONF"
    },
    [266] = {
      name = "TRAVEL_FILTER_CONF"
    },
    [267] = {
      name = "NPC_FOLLOW_CONF"
    },
    [268] = {
      name = "NPC_FOLLOW_TALK_CONF"
    },
    [269] = {
      name = "FRIEND_RECOMMEND_CONF"
    },
    [270] = {
      name = "BAN_ACTION_CONF"
    },
    [271] = {
      name = "BAN_NPC_CONF"
    },
    [272] = {
      name = "FUNCTION_BAN_CONF"
    },
    [273] = {
      name = "FUNCTION_BAN_SCENE_RES_CONF"
    },
    [274] = {
      name = "HIDE_PLAYER_MANUAL_OPTION_CONF"
    },
    [275] = {
      name = "SYSTEM_RED_POINT_BAN_CONF"
    },
    [276] = {
      name = "UI_BAN_CONF"
    },
    [277] = {
      name = "UI_ENTER_BAN_CONF"
    },
    [278] = {
      name = "COLOR_RANDOM_CONF"
    },
    [279] = {
      name = "GLASS_TYPE_CONF"
    },
    [280] = {
      name = "HIDDEN_GLASS_CONF"
    },
    [281] = {
      name = "PARTICLE_RANDOM_CONF"
    },
    [282] = {
      name = "ACTIVITY_GLOBAL_CONFIG"
    },
    [283] = {
      name = "ANTI_CHEAT_GLOBAL_CONFIG"
    },
    [284] = {
      name = "ATTR_GLOBAL_CONFIG"
    },
    [285] = {
      name = "BATTLE_GLOBAL_CONFIG"
    },
    [286] = {
      name = "BP_GLOBAL_CONFIG"
    },
    [287] = {
      name = "CHALLENGE_GLOBAL_CONF"
    },
    [288] = {
      name = "DAILY_GLOBAL_CONFIG"
    },
    [289] = {
      name = "FRIEND_GLOBAL_CONFIG"
    },
    [290] = {
      name = "GLOBAL_CONFIG"
    },
    [291] = {
      name = "HOME_GLOBAL_CONFIG"
    },
    [292] = {
      name = "LEGENDARY_GLOBAL_CONFIG"
    },
    [293] = {
      name = "LLM_GLOBAL_CONFIG"
    },
    [294] = {
      name = "MAP_GLOBAL_CONFIG"
    },
    [295] = {
      name = "NPC_GLOBAL_CONFIG"
    },
    [296] = {
      name = "ONLINE_GLOBAL_CONFIG"
    },
    [297] = {
      name = "PAYMENT_GLOBAL_CONFIG"
    },
    [298] = {
      name = "PET_GLOBAL_CONFIG"
    },
    [299] = {
      name = "ROGUE_CHALLENGE_GLOBAL_CONFIG"
    },
    [300] = {
      name = "ROLE_GLOBAL_CONFIG"
    },
    [301] = {
      name = "SEASON_GLOBAL_CONFIG"
    },
    [302] = {
      name = "TAKEPHOTO_GLOBAL_CONFIG"
    },
    [303] = {
      name = "TASK_GLOBAL_CONFIG"
    },
    [304] = {
      name = "GM_AI_GROUP_CONF"
    },
    [305] = {
      name = "GM_BUTTON_CONF"
    },
    [306] = {
      name = "GM_COMMAND_CONF"
    },
    [307] = {
      name = "GM_GROUP_CONF"
    },
    [308] = {
      name = "GM_MAINTAB_CONF"
    },
    [309] = {
      name = "GM_SERVER_CMD_CONF"
    },
    [310] = {
      name = "GM_SUBTAB_CONF"
    },
    [311] = {
      name = "GRASS_TRIAL_CHAPTER_CONF"
    },
    [312] = {
      name = "GRASS_TRIAL_CONF"
    },
    [313] = {
      name = "GRASS_TRIAL_EFFECT_CONF"
    },
    [314] = {
      name = "GRASS_TRIAL_EVENT_CONF"
    },
    [315] = {
      name = "GUIDE_ANIMATION_IGNORE_CONF"
    },
    [316] = {
      name = "GUIDE_BANNER_CONF"
    },
    [317] = {
      name = "GUIDE_BUTTON_CONF"
    },
    [318] = {
      name = "GUIDE_CTRL_CONF"
    },
    [319] = {
      name = "GUIDE_DRAG_CONF"
    },
    [320] = {
      name = "GUIDE_FOCUS_CONF"
    },
    [321] = {
      name = "GUIDE_IA_CONF"
    },
    [322] = {
      name = "GUIDE_PANEL_CONF"
    },
    [323] = {name = "HINT_LEVEL"},
    [324] = {
      name = "FURNITURE_CLASSIFICATION_CONF"
    },
    [325] = {
      name = "FURNITURE_EFFECT_CONF"
    },
    [326] = {
      name = "FURNITURE_HANDBOOK_CONF"
    },
    [327] = {
      name = "FURNITURE_ITEM_CONF"
    },
    [328] = {
      name = "FURNITURE_VERSION_CONF"
    },
    [329] = {
      name = "HOME_COMFORT_CONF"
    },
    [330] = {
      name = "HOME_LEVEL_CONF"
    },
    [331] = {
      name = "HOME_PET_FEED_CONF"
    },
    [332] = {
      name = "HOME_PET_LAY_EGG_RATE_CONF"
    },
    [333] = {
      name = "INTERIOR_FINISH_CONF"
    },
    [334] = {
      name = "PLANT_GROW_CONF"
    },
    [335] = {
      name = "PLANT_GROW_STAGE_CONF"
    },
    [336] = {
      name = "PLANT_LAND_COORDINATE_CONF"
    },
    [337] = {
      name = "PLANT_TAB_CONF"
    },
    [338] = {name = "ROOM_CONF"},
    [339] = {
      name = "IOS_RATING_POPUP_CONF"
    },
    [340] = {name = "LINE_CONF"},
    [341] = {
      name = "LLM_PET_BEHAVIOR_CONF"
    },
    [342] = {
      name = "LLM_PET_NATURE_CONF"
    },
    [343] = {
      name = "LOADING_TIPS_CONF"
    },
    [344] = {
      name = "PVP_MATCH_TIPS_CONF"
    },
    [345] = {
      name = "LOCALIZATION_CONF"
    },
    [346] = {
      name = "SUB_EVENTS_CONF"
    },
    [347] = {
      name = "SUB_TPLS_CONF"
    },
    [348] = {
      name = "ALL_DIALOGUE_EN"
    },
    [349] = {
      name = "TASK_DIALOGUE_EN"
    },
    [350] = {
      name = "LOTTERY_RESULT_PAGE_CONF"
    },
    [351] = {
      name = "LOTTERY_REWARD_CONF"
    },
    [352] = {name = "MAGE_CONF"},
    [353] = {
      name = "MAGE_HELP_CONF"
    },
    [354] = {
      name = "MAGE_INFO_CONF"
    },
    [355] = {
      name = "MAGE_REST_CONF"
    },
    [356] = {
      name = "MAGIC_BASE_CONF"
    },
    [357] = {
      name = "MAGIC_INTERACT_CONF"
    },
    [358] = {
      name = "MAGIC_TRANSFORM_CONF"
    },
    [359] = {
      name = "STAR_MAGIC_CONF"
    },
    [360] = {
      name = "CALLBACK_MAIL_CONF"
    },
    [361] = {name = "MAIL_CONF"},
    [362] = {
      name = "NOTICE_CONF"
    },
    [363] = {name = "MALL_CONF"},
    [364] = {
      name = "MALL_RAND_CONF"
    },
    [365] = {
      name = "MALL_STORE_CONF"
    },
    [366] = {
      name = "MARK_FAKE_MAGIC_MESSAGE_CONF"
    },
    [367] = {
      name = "MARK_GAMEPLAY_CONF"
    },
    [368] = {
      name = "MARK_MESSAGE_CHILD_CONF"
    },
    [369] = {
      name = "MARK_MESSAGE_LIFE_TIME_CONF"
    },
    [370] = {
      name = "MARK_VIDEO_PROTOCOL"
    },
    [371] = {
      name = "MEDAL_BOND_CONF"
    },
    [372] = {name = "MEDAL_CONF"},
    [373] = {
      name = "MEDAL_TASK_CONF"
    },
    [374] = {
      name = "TEXT_EXP_CONF"
    },
    [375] = {
      name = "MEGAMAP_CLASS_NAME_CONF"
    },
    [376] = {
      name = "MEGAMAP_CONF"
    },
    [377] = {
      name = "MEGAMAP_GATHERING_CONF"
    },
    [378] = {
      name = "MEGAMAP_MAP_CONF"
    },
    [379] = {
      name = "MEGAMAP_OVERLAP_CONF"
    },
    [380] = {
      name = "MEGAMAP_REFRESH_BLACKLIST"
    },
    [381] = {
      name = "MEGAMAP_SPEED_CONF"
    },
    [382] = {
      name = "MINIGAME_CONF"
    },
    [383] = {
      name = "MINIGAME_RULE_CONF"
    },
    [384] = {
      name = "MODEL_COLLISION_CONF"
    },
    [385] = {name = "MODEL_CONF"},
    [386] = {
      name = "MODEL_MAT_CONF"
    },
    [387] = {
      name = "MODEL_SOCKET_CONF"
    },
    [388] = {
      name = "BLOOD_MONSTER_SKILLBANK_CONF"
    },
    [389] = {
      name = "CATCH_CONDITION_CONF"
    },
    [390] = {
      name = "ESCAPE_INFO_CONF"
    },
    [391] = {
      name = "MONSTER_CATCH_CONF"
    },
    [392] = {
      name = "MONSTER_CONF"
    },
    [393] = {
      name = "MONSTER_GROWTH_CONF"
    },
    [394] = {
      name = "MONSTER_SKILLBANK_CONF"
    },
    [395] = {
      name = "SPECIAL_MOVE_CONF"
    },
    [396] = {
      name = "MUSIC_APPLY_LIST_CONF"
    },
    [397] = {name = "MUSIC_CONF"},
    [398] = {
      name = "MUSIC_FREEMIUM_CONF"
    },
    [399] = {
      name = "MUSIC_TYPE_CONF"
    },
    [400] = {
      name = "NIGHTMARE_ELITE_CONF"
    },
    [401] = {
      name = "SEASON_ELITE_CONF"
    },
    [402] = {
      name = "AI_WORD_CONF"
    },
    [403] = {
      name = "BATTLE_RANDOM_CONF"
    },
    [404] = {
      name = "LOCATION_INTERACT_BAN"
    },
    [405] = {
      name = "NPC_ACTION_CONF"
    },
    [406] = {
      name = "NPC_ACTOR_POOL_CONF"
    },
    [407] = {
      name = "NPC_AURA_CONF"
    },
    [408] = {
      name = "NPC_AURA_EFFECT_CONF"
    },
    [409] = {
      name = "NPC_COMPASS_OPTION"
    },
    [410] = {name = "NPC_CONF"},
    [411] = {
      name = "NPC_OPTION_CONF"
    },
    [412] = {
      name = "NPC_PEER_CONF"
    },
    [413] = {
      name = "NPC_REACTION_CONF"
    },
    [414] = {
      name = "PET_INTERACTION_COMPLEX"
    },
    [415] = {
      name = "PET_INTERACTION_CONF"
    },
    [416] = {name = "TASK_NPC"},
    [417] = {
      name = "NPC_COMB_OPTION_CONF"
    },
    [418] = {
      name = "NPC_COMB_RESULT_CONF"
    },
    [419] = {
      name = "NPC_PENDANT_CONF"
    },
    [420] = {
      name = "BONUS_CONTAINER_CONF"
    },
    [421] = {
      name = "BONUS_EVENT_POOL_CONF"
    },
    [422] = {
      name = "BONUS_SHINING_STG_CONF"
    },
    [423] = {
      name = "BONUS_SPE_EVENT_POOL_CONF"
    },
    [424] = {
      name = "NPC_REFRESH_BONUS_CONF"
    },
    [425] = {
      name = "NPC_REFRESH_CONTENT_CONF"
    },
    [426] = {
      name = "NPC_REFRESH_GROUP_CONF"
    },
    [427] = {
      name = "NPC_REFRESH_RULE_CONF"
    },
    [428] = {
      name = "NPC_REFRESH_TIME_CONF"
    },
    [429] = {
      name = "NPC_SERVER_REFRESH_CONF"
    },
    [430] = {
      name = "REFRESH_COND_CONF"
    },
    [431] = {
      name = "WEIGHT_GROUP_CONF"
    },
    [432] = {
      name = "OPERATION_MAIL"
    },
    [433] = {
      name = "OWL_CONTENT_NPC_CONF"
    },
    [434] = {
      name = "OWL_PET_FRUIT_CONF"
    },
    [435] = {
      name = "OWL_SANCTUARY_CONF"
    },
    [436] = {
      name = "PARAGRAPH_PACKAGE_ORDER_CONF"
    },
    [437] = {
      name = "PARAGRAPH_VO_CONF"
    },
    [438] = {
      name = "AREA_HANDBOOK"
    },
    [439] = {
      name = "BASE_POINT_CONF"
    },
    [440] = {
      name = "BREAK_ITEM_CONF"
    },
    [441] = {
      name = "BREAK_NUMBER_CONF"
    },
    [442] = {
      name = "BREAK_REWARD_CONF"
    },
    [443] = {
      name = "CRYSTAL_CONF"
    },
    [444] = {
      name = "EGG_TYPE_CONF"
    },
    [445] = {
      name = "EVOLUTION_ACTION_DATA"
    },
    [446] = {
      name = "EVOLUTION_LEVEL_DATA"
    },
    [447] = {
      name = "GROW_LEVEL_CONF"
    },
    [448] = {
      name = "INSPIRE_LEVEL_CONF"
    },
    [449] = {
      name = "LEVEL_GET_FIX_CONF"
    },
    [450] = {
      name = "LEVEL_SKILL_CONF"
    },
    [451] = {
      name = "NATURE_CONF"
    },
    [452] = {
      name = "OVERLEVEL_RATIO_EXP"
    },
    [453] = {
      name = "PETBASE_CONF"
    },
    [454] = {
      name = "PETFREE_CONF"
    },
    [455] = {
      name = "PETPAGE_BLACKLIST"
    },
    [456] = {
      name = "PET_ACTION_CLOSE_EXP_CONF"
    },
    [457] = {
      name = "PET_BAG_SEQUENCE"
    },
    [458] = {
      name = "PET_BLOOD_CONF"
    },
    [459] = {name = "PET_BOND"},
    [460] = {
      name = "PET_BOND_COUNT"
    },
    [461] = {
      name = "PET_CLASSIS_CONF"
    },
    [462] = {
      name = "PET_CLOSE_LEVEL_EFFECT_CONF"
    },
    [463] = {name = "PET_CONF"},
    [464] = {
      name = "PET_EFFORTS_LEVEL"
    },
    [465] = {
      name = "PET_EGG_CONF"
    },
    [466] = {
      name = "PET_EGG_WAY_TO_PROB_CONF"
    },
    [467] = {
      name = "PET_EVOLUTION_CONF"
    },
    [468] = {
      name = "PET_FEATURE_RAND"
    },
    [469] = {
      name = "PET_FREE_REWARD_CONF"
    },
    [470] = {
      name = "PET_HABIT_CONF"
    },
    [471] = {
      name = "PET_HANDBOOK"
    },
    [472] = {
      name = "PET_HANDBOOK_REWARD"
    },
    [473] = {
      name = "PET_HANDBOOK_SEQUENCE"
    },
    [474] = {
      name = "PET_LEVEL_CONF"
    },
    [475] = {
      name = "PET_LIKE_ELEMENT_CONF"
    },
    [476] = {
      name = "PET_MARK_CONF"
    },
    [477] = {
      name = "PET_REPORT_SCORE_CONF"
    },
    [478] = {
      name = "PET_SCENE_ABILITY_GANZHI"
    },
    [479] = {
      name = "PET_SHOW_SPEED_CONF"
    },
    [480] = {
      name = "PET_TALENT_CONF"
    },
    [481] = {
      name = "PET_TALENT_RANDOM_CONF"
    },
    [482] = {
      name = "PET_TOPIC_TYPE_CONF"
    },
    [483] = {
      name = "PET_UI_CAMERA_CONF"
    },
    [484] = {
      name = "SEASON_HANDBOOK_CONF"
    },
    [485] = {
      name = "SKILL_COLOR_CONF"
    },
    [486] = {
      name = "SKILL_RANDOM_CONF"
    },
    [487] = {
      name = "SKILL_SEQUENCE_CONF"
    },
    [488] = {
      name = "SUBMIT_PET_CONF"
    },
    [489] = {
      name = "UNCOMMAND_PET_SKILL_CONF"
    },
    [490] = {
      name = "PET_INFO_CONF"
    },
    [491] = {
      name = "PET_RANDOM_EGG_CONF"
    },
    [492] = {
      name = "PET_PARTNER_DATA"
    },
    [493] = {
      name = "PET_ROLLBACK_CONF"
    },
    [494] = {name = "POINT_CONF"},
    [495] = {
      name = "PLATFORM_PRIVILEGES"
    },
    [496] = {
      name = "PROTO_CMD_SEQ_CONF"
    },
    [497] = {
      name = "PET_TYPE_SCORE_CONF"
    },
    [498] = {
      name = "PVP_AWARD_CONF"
    },
    [499] = {
      name = "PVP_BATTLE_SCORE_CONF"
    },
    [500] = {name = "PVP_CONF"},
    [501] = {
      name = "PVP_RANDOM_PET_LIBRARY_CONF"
    },
    [502] = {
      name = "PVP_RANDOM_PET_REWARD_CONF"
    },
    [503] = {
      name = "PVP_RANDOM_SKILL_LIBRARY_CONF"
    },
    [504] = {
      name = "PVP_RANDOM_SKILL_LIST_CONF"
    },
    [505] = {
      name = "PVP_RANK_CONF"
    },
    [506] = {
      name = "PVP_RANK_PLAYER_POLL_CONF"
    },
    [507] = {
      name = "PVP_RANK_RANDOM_PET_CONF"
    },
    [508] = {
      name = "PVP_RANK_ROBOT_CARD_ICON_CONF"
    },
    [509] = {
      name = "PVP_RANK_ROBOT_NAME_CONF"
    },
    [510] = {
      name = "PVP_RANK_ROBOT_PLAYER_CONF"
    },
    [511] = {
      name = "PVP_RANK_SEASON_CONF"
    },
    [512] = {
      name = "PVP_RANK_TRIAL_PET_CONF"
    },
    [513] = {
      name = "PVP_RANK_TRIAL_PET_LIBRARY_CONF"
    },
    [514] = {
      name = "PVP_RANK_WEEK_TASK_CONF"
    },
    [515] = {
      name = "PVP_ROBOT_CONF"
    },
    [516] = {
      name = "PVP_WAREHOUSE_CONF"
    },
    [517] = {
      name = "TOP_MASTER_CONF"
    },
    [518] = {
      name = "RANKBOARD_CONF"
    },
    [519] = {name = "READ_CONF"},
    [520] = {
      name = "REACALL_CONF"
    },
    [521] = {
      name = "REACALL_LIST_CONF"
    },
    [522] = {
      name = "REACALL_TREMS_CONF"
    },
    [523] = {
      name = "RED_POINT_CONF"
    },
    [524] = {
      name = "INTERACTIONTREE_CONF"
    },
    [525] = {
      name = "RELATIONTREE_ANIM_CONF"
    },
    [526] = {
      name = "RELATIONTREE_BASIC_CONF"
    },
    [527] = {
      name = "RELATIONTREE_CONF"
    },
    [528] = {
      name = "RESOURCE_CONF"
    },
    [529] = {
      name = "LOTTERY_POOL_CONF"
    },
    [530] = {
      name = "LOTTERY_POOL_REWARD_CONF"
    },
    [531] = {
      name = "REWARD_CONF"
    },
    [532] = {name = "REWARD_TAG"},
    [533] = {
      name = "REWARD_WEIGHT_CHANGE_CONF"
    },
    [534] = {
      name = "EVENT_BASE_CONF"
    },
    [535] = {
      name = "EVENT_COMBINE_CONF"
    },
    [536] = {
      name = "ROGUE_LEVEL_CONF"
    },
    [537] = {
      name = "UPGRADE_CONF"
    },
    [538] = {
      name = "BOTTLE_TIMES_CONF"
    },
    [539] = {
      name = "BOTTLE_VOLUME_CONF"
    },
    [540] = {
      name = "HP_MAX_CONF"
    },
    [541] = {
      name = "POWER_MAX_CONF"
    },
    [542] = {
      name = "ROLE_EXP_CONF"
    },
    [543] = {
      name = "ROLE_STAR_NPCLEVEL_CHANGE_CONF"
    },
    [544] = {
      name = "ROLE_WORLD_LEVEL_MAP_CONF"
    },
    [545] = {
      name = "WORLD_LEVEL_CONF"
    },
    [546] = {
      name = "CARD_ADVENTURE_RECORD_CONF"
    },
    [547] = {
      name = "CARD_ICON_CONF"
    },
    [548] = {
      name = "CARD_LABEL_CONF"
    },
    [549] = {
      name = "CARD_MODULE_CONF"
    },
    [550] = {
      name = "CARD_SKIN_CONF"
    },
    [551] = {
      name = "EQS_BOX_EXPORT"
    },
    [552] = {
      name = "PET_BEHAVIOR_REACTION_CONF"
    },
    [553] = {
      name = "ROLEPLAY_BEHAVIOR_CONF"
    },
    [554] = {
      name = "ROLEPLAY_PROP_CONF"
    },
    [555] = {
      name = "ROLEPLAY_SORT_CONF"
    },
    [556] = {
      name = "SCENE_AWARD_CONF"
    },
    [557] = {name = "SCENE_CONF"},
    [558] = {
      name = "SCENE_OBJECT_AWARD"
    },
    [559] = {
      name = "SCENE_OBJECT_CONF"
    },
    [560] = {
      name = "SCENE_RES_CONF"
    },
    [561] = {
      name = "SCENE_UPGRADE_VERSION_CONF"
    },
    [562] = {
      name = "SCENE_ABILITY_ASCENDING_CONF"
    },
    [563] = {
      name = "SCENE_ABILITY_CONF"
    },
    [564] = {
      name = "SCENE_ABILITY_DASH_CONF"
    },
    [565] = {
      name = "SCENE_ABILITY_FLYING_CONF"
    },
    [566] = {
      name = "SCENE_ABILITY_RIDING_CONF"
    },
    [567] = {
      name = "SCENE_ABILITY_SLIDING_CONF"
    },
    [568] = {
      name = "SCENE_ABILITY_THROW_CONF"
    },
    [569] = {
      name = "SCENE_PLAYER_STATUS_MATRIX"
    },
    [570] = {
      name = "VITALITY_CONF"
    },
    [571] = {
      name = "SCENE_EFFECT_CONF"
    },
    [572] = {
      name = "ABNORMAL_STATUS_CONF"
    },
    [573] = {
      name = "SCENE_STATUS_SALS_CONF"
    },
    [574] = {
      name = "SCENE_STATUS_WPST_CONF"
    },
    [575] = {
      name = "SEASON_BATTLE_RULE_CONF"
    },
    [576] = {
      name = "SEASON_CONF"
    },
    [577] = {
      name = "SEASON_GROWTH_CONF"
    },
    [578] = {
      name = "SEASON_ITEM_CONF"
    },
    [579] = {
      name = "SEASON_LEGENDARY_BATTLE_EVENT"
    },
    [580] = {
      name = "SEASON_PART_CONF"
    },
    [581] = {
      name = "SEASON_PETBASE"
    },
    [582] = {
      name = "SEASON_PET_CATCH_REWARD_CONF"
    },
    [583] = {
      name = "SEASON_PVE_BASE_CONF"
    },
    [584] = {
      name = "SEASON_SKILL"
    },
    [585] = {
      name = "SEASON_TALENT_CONF"
    },
    [586] = {
      name = "SEASON_ADVENTURE_BADGE_LEVEL"
    },
    [587] = {
      name = "SEASON_ADVENTURE_CHAPTER"
    },
    [588] = {
      name = "SEASON_ADVENTURE_CONF"
    },
    [589] = {
      name = "SEASON_ADVENTURE_UI"
    },
    [590] = {
      name = "BONUSCATCH_REFRESH_RULE_CONF"
    },
    [591] = {
      name = "SEASON_BONUSCATCH_BOX_CONF"
    },
    [592] = {
      name = "SEASON_BONUSCATCH_EFFECTS_CONF"
    },
    [593] = {
      name = "SEASON_BONUSCATCH_LIMIT_CONF"
    },
    [594] = {
      name = "SEASON_BONUSCATCH_SEC_OPT_CONF"
    },
    [595] = {
      name = "SEASON_PET_EFFECTS_CONF"
    },
    [596] = {
      name = "SEASON_FOCUS_UMG_CONF"
    },
    [597] = {
      name = "SEASON_TIPS_NEW_PET_CONF"
    },
    [598] = {
      name = "SEASON_TIPS_PVP_CONF"
    },
    [599] = {
      name = "SEASON_TIPS_TAB_CONF"
    },
    [600] = {
      name = "SEASON_TIPS_TXT_CONF"
    },
    [601] = {
      name = "SEASON_TPT_COMMON_CONF"
    },
    [602] = {name = "SEAT_CONF"},
    [603] = {
      name = "SECOND_TIER_PASSWORD_CONF"
    },
    [604] = {name = "MOVIE_CONF"},
    [605] = {
      name = "SEQUENCE_CONF"
    },
    [606] = {
      name = "SUBTITLE_CONF"
    },
    [607] = {
      name = "RPC_LOSS_RATE_CONF"
    },
    [608] = {
      name = "BUTTON_SETTING_CONF"
    },
    [609] = {
      name = "DEFAULT_BUTTON_CONF"
    },
    [610] = {
      name = "RESOLUTION_CONF"
    },
    [611] = {
      name = "UI_KEYNAME_CONVERT"
    },
    [612] = {
      name = "PET_SHARE_ITEM_CONF"
    },
    [613] = {
      name = "QQ_ARK_SHARE_CONF"
    },
    [614] = {
      name = "SHARE_BASE_CONF"
    },
    [615] = {name = "SHARE_CONF"},
    [616] = {
      name = "SHARE_PART_CONF"
    },
    [617] = {
      name = "SHARE_REWARD_CONF"
    },
    [618] = {
      name = "GOODS_RETURN_CONF"
    },
    [619] = {
      name = "MALL_FRAME_CONF"
    },
    [620] = {
      name = "MALL_MONTHLY_PASS_REWARD"
    },
    [621] = {
      name = "NORMAL_SHOP_CONF"
    },
    [622] = {
      name = "RANDOM_GOODS_CONF"
    },
    [623] = {
      name = "RANDOM_SHOP_CONF"
    },
    [624] = {
      name = "SHOP_BAN_CONF"
    },
    [625] = {name = "SHOP_CONF"},
    [626] = {
      name = "SHOP_TOTAL_CONSUMPTION_CONF"
    },
    [627] = {
      name = "ATTRIBUTE_CONF"
    },
    [628] = {
      name = "BUFFBASE_CONF"
    },
    [629] = {name = "BUFF_CONF"},
    [630] = {name = "BUFF_TYPE"},
    [631] = {
      name = "DESC_NOTE_CONF"
    },
    [632] = {
      name = "EFFECT_ANIMATION"
    },
    [633] = {
      name = "EFFECT_CONF"
    },
    [634] = {
      name = "ENTERBATTLE_BUFF_PRIORITY"
    },
    [635] = {
      name = "FIELD_LAYER_CONF"
    },
    [636] = {
      name = "PREATTACK_SKILL"
    },
    [637] = {
      name = "RES_BGS_TIME_CONF"
    },
    [638] = {
      name = "RES_BUFF_TIME_CONF"
    },
    [639] = {
      name = "RES_SKILL_TIME_CONF"
    },
    [640] = {
      name = "SKILLFULLY_EXCHANGE_CONF"
    },
    [641] = {
      name = "SKILLSPECIAL_CONF"
    },
    [642] = {name = "SKILL_CONF"},
    [643] = {
      name = "SKILL_INTERACT_CONF"
    },
    [644] = {
      name = "SKILL_RES_CHANGE_CONF"
    },
    [645] = {
      name = "SKILL_RES_CONF"
    },
    [646] = {name = "SKILL_TAG"},
    [647] = {
      name = "SKILL_TIME_CONF"
    },
    [648] = {
      name = "SKILL_UI_DES"
    },
    [649] = {
      name = "TYPE_DICTIONARY"
    },
    [650] = {name = "SLIDE_CONF"},
    [651] = {
      name = "BOTTLE_CONF"
    },
    [652] = {
      name = "FRUIT_TREE_CONF"
    },
    [653] = {
      name = "FRUIT_TREE_RULE_CONF"
    },
    [654] = {name = "WIND_GRASS"},
    [655] = {
      name = "SPLINE_CONF"
    },
    [656] = {
      name = "LEGENDARY_BATTLE_AWARD"
    },
    [657] = {
      name = "STAR_AWARD_CONF"
    },
    [658] = {
      name = "TEAM_BATTLE_AWARD"
    },
    [659] = {
      name = "ACTCONTROLCONFIG"
    },
    [660] = {
      name = "CHANNELCONTROLCONFIG"
    },
    [661] = {
      name = "SYSTEMCONTROLCONFIG"
    },
    [662] = {
      name = "CAMERA_SKIN_CONF"
    },
    [663] = {
      name = "TAKE_PHOTO_EMOJI_CONF"
    },
    [664] = {
      name = "TAKE_PHOTO_FILTER_CONF"
    },
    [665] = {
      name = "TAKE_PHOTO_POSE_CONF"
    },
    [666] = {
      name = "CHAPTER_CONF"
    },
    [667] = {
      name = "GP_CONTEST_CONF"
    },
    [668] = {name = "GUIDE_CONF"},
    [669] = {
      name = "MESSAGE_CONF"
    },
    [670] = {
      name = "PARAGRAPH_CONF"
    },
    [671] = {
      name = "STORY_BGM_CONF"
    },
    [672] = {
      name = "SUB_TASK_CONF"
    },
    [673] = {
      name = "TALE_BLOOD_MAGIC_CONF"
    },
    [674] = {
      name = "TALE_NIGHTMARE_CONF"
    },
    [675] = {
      name = "TALE_NOTEBOOK_KELI_CONF"
    },
    [676] = {name = "TASK_CONF"},
    [677] = {name = "TASK_ITEM"},
    [678] = {
      name = "TASK_MODULE_CONF"
    },
    [679] = {
      name = "TASK_PET_PARAM_CONF"
    },
    [680] = {
      name = "TASK_STATE_CONF"
    },
    [681] = {
      name = "TASK_STYLE_CONF"
    },
    [682] = {
      name = "TASK_SUMMARY"
    },
    [683] = {
      name = "TASK_SWITCH_CONF"
    },
    [684] = {
      name = "TASK_TOKEN_CONF"
    },
    [685] = {
      name = "TRACK_NUMBER"
    },
    [686] = {name = "UNIT_CONF"},
    [687] = {name = "TEACH_CONF"},
    [688] = {
      name = "TEACH_TAB_CONF"
    },
    [689] = {
      name = "SCENE_ENTER_EXIT"
    },
    [690] = {
      name = "TELEPORT_CONF"
    },
    [691] = {
      name = "TELEPORT_LOADING_CONF"
    },
    [692] = {
      name = "TELEPORT_RULES_CONF"
    },
    [693] = {
      name = "ENV_TAG_CONF"
    },
    [694] = {
      name = "TEST_RECHARGE_AMOUNT_CONF"
    },
    [695] = {name = "TITLE_CONF"},
    [696] = {
      name = "TREASURE_ITEM_CONF"
    },
    [697] = {
      name = "SPE_REFRESH_TRIG_CONF"
    },
    [698] = {name = "UI_COMPASS"},
    [699] = {name = "UI_CONF"},
    [700] = {
      name = "UI_LOBBY_MAIN_COMPASS"
    },
    [701] = {
      name = "UI_RECONNECT"
    },
    [702] = {
      name = "BALLTLEPASS_AWARDMAIN_CONF"
    },
    [703] = {
      name = "BATTLEPASS_PURCHASE_CONF"
    },
    [704] = {
      name = "UMG_DIALOG_CONF"
    },
    [705] = {
      name = "UMG_STATIC_CONF"
    },
    [706] = {
      name = "VIDEO_SUBTITLES_CONF"
    },
    [707] = {
      name = "VISUAL_ITEM_CONF"
    },
    [708] = {
      name = "PET_WAREHOUSE_CONF"
    },
    [709] = {
      name = "TIDY_SEQUENCE_TYPE"
    },
    [710] = {
      name = "WAREHOUSE_COLLECT_MARK"
    },
    [711] = {
      name = "WATER_MARK_CONTROL_CONF"
    },
    [712] = {
      name = "WATER_MARK_LOCALIZATION_CONF"
    },
    [713] = {
      name = "WATER_MARK_WHITE_LIST_CONF"
    },
    [714] = {name = "TOD_CONF"},
    [715] = {
      name = "WEATHER_CONF"
    },
    [716] = {
      name = "ACTION_ANIM_BONE_TRANSFORM_INFO"
    },
    [717] = {name = "BLOCK_CONF"},
    [718] = {
      name = "BOSS_SKILLS_MAP_CONF"
    },
    [719] = {
      name = "CURVE_DETAIL_INFO"
    },
    [720] = {
      name = "SKILL_ANIM_SOCKETS_INFO"
    },
    [721] = {
      name = "WEAKNESS_CONF"
    },
    [722] = {
      name = "WORLD_COMBAT_CONF"
    },
    [723] = {
      name = "WORLD_COMBAT_SKILL_CONF"
    },
    [724] = {
      name = "WORLD_COMBAT_SKILL_CURVE_CONF"
    },
    [725] = {
      name = "LAYERED_WORLD_MAP_CONF"
    },
    [726] = {
      name = "MAP_INFO_BAR_CONF"
    },
    [727] = {
      name = "WORLD_EXPLORING_STATISTIC_CONF"
    },
    [728] = {
      name = "WORLD_MAP_ACTIVITY_CONF"
    },
    [729] = {
      name = "WORLD_MAP_AREA_GUIDE"
    },
    [730] = {
      name = "WORLD_MAP_BLOCK_CONF"
    },
    [731] = {
      name = "WORLD_MAP_CHALLENGE_CONF"
    },
    [732] = {
      name = "WORLD_MAP_CONF"
    },
    [733] = {
      name = "WORLD_MAP_DEFAULT_TRACK"
    },
    [734] = {
      name = "WORLD_MAP_GLOBAL_CONF"
    },
    [735] = {
      name = "WORLD_MAP_SCALE_CONF"
    },
    [736] = {
      name = "WORLD_ZONE_CONF"
    },
    [737] = {
      name = "ZONE_EFFECT_CONF"
    }
  }
  self.ConfigTableId = configTableId
  self.__configTableInfo = configTableInfo
end

function DataConfigManager:GetChinaBenchmarkDeviceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHINA_BENCHMARK_DEVICE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPcLevelCpuAmdConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PC_LEVEL_CPU_AMD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPcLevelCpuIntelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PC_LEVEL_CPU_INTEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPcLevelGpuAmdConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PC_LEVEL_GPU_AMD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPcLevelGpuNvidiaConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PC_LEVEL_GPU_NVIDIA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldBenchmarkDeviceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_BENCHMARK_DEVICE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBasicQualityConfigConf(_name, _ignoreLog)
  return self:GetData(self.ConfigTableId.BASIC_QUALITY_CONFIG_CONF, _name, _ignoreLog)
end

function DataConfigManager:GetOverrideQualityConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OVERRIDE_QUALITY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetQualityDefaultConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.QUALITY_DEFAULT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetQualityGroupSettingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.QUALITY_GROUP_SETTING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetQualityLocalizationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.QUALITY_LOCALIZATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetQualityMappingConf(_name, _ignoreLog)
  return self:GetData(self.ConfigTableId.QUALITY_MAPPING_CONF, _name, _ignoreLog)
end

function DataConfigManager:GetActivityCommonShowConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_COMMON_SHOW_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityConditionGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_CONDITION_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityConditionRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_CONDITION_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityDropConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_DROP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityDropMethodConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_DROP_METHOD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityFactionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_FACTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityFlowerAppearConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_FLOWER_APPEAR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityFlowerTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_FLOWER_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityGoodsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_GOODS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityInheritanceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_INHERITANCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityInviteRegisterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_INVITE_REGISTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityMaintabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_MAINTAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityMixConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_MIX_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetCatchConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_CATCH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetCertification(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_CERTIFICATION, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetCollectionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_COLLECTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetPartnerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_PARTNER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetPhoto(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_PHOTO, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetRaiseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_RAISE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetRaiseTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_RAISE_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetTripConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_TRIP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPikaConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PIKA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPlayerCoCreation(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PLAYER_CO_CREATION, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPreheatConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PREHEAT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRelayPage(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RELAY_PAGE, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRewardByStageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_REWARD_BY_STAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityShinyWeekendConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SHINY_WEEKEND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityShopConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SHOP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivitySpecialConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SPECIAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivitySpecFlowerSeedConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SPEC_FLOWER_SEED_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivitySpringFestivalConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SPRING_FESTIVAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityTlogConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_TLOG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityTrackConditionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_TRACK_CONDITION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityTreasureHuntConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_TREASURE_HUNT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityUpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_UP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityWebsitePartConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_WEBSITE_PART_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityWeekendChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_WEEKEND_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityWishLotterAward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_WISH_LOTTER_AWARD, _id, _ignoreLog)
end

function DataConfigManager:GetActLimittimeAppear(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACT_LIMITTIME_APPEAR, _id, _ignoreLog)
end

function DataConfigManager:GetBossChallengeEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOSS_CHALLENGE_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLegendaryBattleEvent(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEGENDARY_BATTLE_EVENT, _id, _ignoreLog)
end

function DataConfigManager:GetLegendaryChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEGENDARY_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcChallengeEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_CHALLENGE_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSecondaryTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SECONDARY_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTakephotoCompetitionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TAKEPHOTO_COMPETITION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTerritoryTrialConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TERRITORY_TRIAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeekendChallengeGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEEKEND_CHALLENGE_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeeklyChallengeEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEEKLY_CHALLENGE_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityOptionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_OPTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivitySpecialTxtConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SPECIAL_TXT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityTaskGoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_TASK_GO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSpecBattleUi(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SPEC_BATTLE_UI, _id, _ignoreLog)
end

function DataConfigManager:GetActivityGlobalChallenge(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_GLOBAL_CHALLENGE, _id, _ignoreLog)
end

function DataConfigManager:GetActivityGlobalChallengeSign(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_GLOBAL_CHALLENGE_SIGN, _id, _ignoreLog)
end

function DataConfigManager:GetActivityPetTripRule(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_PET_TRIP_RULE, _id, _ignoreLog)
end

function DataConfigManager:GetActivitySignReward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_SIGN_REWARD, _id, _ignoreLog)
end

function DataConfigManager:GetActivityStageRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_STAGE_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetInformationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_INFORMATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPreDownloadConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PRE_DOWNLOAD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRecallbpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RECALLBP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRecallClassConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RECALL_CLASS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRecallConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RECALL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRecallPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RECALL_PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityRecallStarlightbuff(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_RECALL_STARLIGHTBUFF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityUmgRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_UMG_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCompetitionRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.COMPETITION_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetContestantRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CONTESTANT_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetJudgeRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.JUDGE_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAdventureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ADVENTURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDailyTaskRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DAILY_TASK_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRegionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REGION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAiBattleResultBehavior(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AI_BATTLE_RESULT_BEHAVIOR, _id, _ignoreLog)
end

function DataConfigManager:GetAiBattleResultConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AI_BATTLE_RESULT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBbInitiateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BB_INITIATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBbInputConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BB_INPUT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBbInstanceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BB_INSTANCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBbNameDefineConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BB_NAME_DEFINE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiBehaviorGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_BEHAVIOR_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiConeModerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_CONE_MODER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiFsmCondConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_FSM_COND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiFsmStateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_FSM_STATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiFsmStructureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_FSM_STRUCTURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiGameplayStatetransConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_GAMEPLAY_STATETRANS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiGameplayStateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_GAMEPLAY_STATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiGameplayTagConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_GAMEPLAY_TAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiGlobalConfigConf(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_GLOBAL_CONFIG_CONF, _key, _ignoreLog)
end

function DataConfigManager:GetNrcAiGroupInfoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_GROUP_INFO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiMutualExclusionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_MUTUAL_EXCLUSION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiOverwriteBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_OVERWRITE_BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiPerceptionAudioConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_PERCEPTION_AUDIO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiPerceptionModerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_PERCEPTION_MODER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiPerceptionVisualConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_PERCEPTION_VISUAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiPerformPoolConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_PERFORM_POOL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiPerformSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_PERFORM_SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiRelationSchemaConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_RELATION_SCHEMA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiSenseConeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_SENSE_CONE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiSenseEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_SENSE_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiWorldCombatSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_WORLD_COMBAT_SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcAiWorldEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_AI_WORLD_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiBasicInfoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_BASIC_INFO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiDismissConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_DISMISS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiDynamicEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_DYNAMIC_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiMoveConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_MOVE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiRoleTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_ROLE_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcGroupAiStationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_GROUP_AI_STATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNrcHomeAiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NRC_HOME_AI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAllRidePet(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ALL_RIDE_PET, _id, _ignoreLog)
end

function DataConfigManager:GetAllRideUiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ALL_RIDE_UI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRideAnimation(_anim_name, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_ANIMATION, _anim_name, _ignoreLog)
end

function DataConfigManager:GetRideBasicMovement(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_BASIC_MOVEMENT, _id, _ignoreLog)
end

function DataConfigManager:GetRideEffects(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_EFFECTS, _id, _ignoreLog)
end

function DataConfigManager:GetRidePassiveSkill(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_PASSIVE_SKILL, _id, _ignoreLog)
end

function DataConfigManager:GetRideSocket(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_SOCKET, _id, _ignoreLog)
end

function DataConfigManager:GetRideSocketExport(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RIDE_SOCKET_EXPORT, _id, _ignoreLog)
end

function DataConfigManager:GetAnimConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ANIM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAnimIdConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ANIM_ID_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAnimMotionCurveConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ANIM_MOTION_CURVE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaCheckConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_CHECK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaFuncConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_FUNC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaSceneobjConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_SCENEOBJ_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaTagConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_TAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaTrigConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_TRIG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaUiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_UI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaVisibleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_VISIBLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaWeatherConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_WEATHER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAudioCaveConf(_cave_name, _ignoreLog)
  return self:GetData(self.ConfigTableId.AUDIO_CAVE_CONF, _cave_name, _ignoreLog)
end

function DataConfigManager:GetAudioFubenConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AUDIO_FUBEN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAudioLengthConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AUDIO_LENGTH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAudioModelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AUDIO_MODEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAudioNatureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AUDIO_NATURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetHomeLimitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_HOME_LIMIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetNameMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_NAME_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattleUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDialogueOnlyOptionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DIALOGUE_ONLY_OPTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDialogueUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DIALOGUE_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFunctionBanSpecialNpcConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FUNCTION_BAN_SPECIAL_NPC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHabitatConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HABITAT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomeUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMovieUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MOVIE_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetOptionUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OPTION_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetbaseUsedByFashionBond(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PETBASE_USED_BY_FASHION_BOND, _id, _ignoreLog)
end

function DataConfigManager:GetSequenceUsedByTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEQUENCE_USED_BY_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBagItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAG_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBagItemSequence(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAG_ITEM_SEQUENCE, _id, _ignoreLog)
end

function DataConfigManager:GetBagItemTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAG_ITEM_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBagPetGiftEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAG_PET_GIFT_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattleItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetItemLableTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ITEM_LABLE_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetCarryonItem(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_CARRYON_ITEM, _id, _ignoreLog)
end

function DataConfigManager:GetPetCarryonUpgrade(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_CARRYON_UPGRADE, _id, _ignoreLog)
end

function DataConfigManager:GetPlayerMagicConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLAYER_MAGIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetThrowFuncConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.THROW_FUNC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBallAct(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BALL_ACT, _id, _ignoreLog)
end

function DataConfigManager:GetBallConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BALL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBallForbidCapture(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BALL_FORBID_CAPTURE, _id, _ignoreLog)
end

function DataConfigManager:GetAiModelWarmConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AI_MODEL_WARM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAoneFinalBattlePetslistConf(_ID, _ignoreLog)
  return self:GetData(self.ConfigTableId.AONE_FINAL_BATTLE_PETSLIST_CONF, _ID, _ignoreLog)
end

function DataConfigManager:GetBattleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattleRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattleTypeConf(_ID, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_TYPE_CONF, _ID, _ignoreLog)
end

function DataConfigManager:GetBattlePassConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassGiftConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_GIFT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassTaskModuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_TASK_MODULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassThemeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_THEME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassUiColor(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_UI_COLOR, _id, _ignoreLog)
end

function DataConfigManager:GetBattlePassUiTheme(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_PASS_UI_THEME, _id, _ignoreLog)
end

function DataConfigManager:GetBattleGuideConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_GUIDE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCombatMechanismBattleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.COMBAT_MECHANISM_BATTLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCombatMechanismTeachConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.COMBAT_MECHANISM_TEACH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTypeAdvantageBattleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TYPE_ADVANTAGE_BATTLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTypeAdvantageTeachConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TYPE_ADVANTAGE_TEACH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBstConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldBuffConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_BUFF_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCameraConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMERA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCameraMoveLite(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMERA_MOVE_LITE, _id, _ignoreLog)
end

function DataConfigManager:GetCameraPath(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMERA_PATH, _id, _ignoreLog)
end

function DataConfigManager:GetCampConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCampContentNpcConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMP_CONTENT_NPC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCampLevelupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMP_LEVELUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCampPetReportConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMP_PET_REPORT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetFruitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_FRUIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetSettledBonusConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_SETTLED_BONUS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetReportCoinRatioConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REPORT_COIN_RATIO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTravelSequenceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TRAVEL_SEQUENCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBossChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOSS_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCheerPointConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHEER_POINT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTerritoryTrialChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TERRITORY_TRIAL_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeeklyChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEEKLY_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeeklyPhotoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEEKLY_PHOTO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetChatEmojiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHAT_EMOJI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetClientPublicCmd(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CLIENT_PUBLIC_CMD, _id, _ignoreLog)
end

function DataConfigManager:GetClimbChapterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CLIMB_CHAPTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetStageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.STAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCollegeSelectionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.COLLEGE_SELECTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskDataGuardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_DATA_GUARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActionResultTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTION_RESULT_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCustomcameraConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CUSTOMCAMERA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDialogueConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DIALOGUE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDialogueOrderConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DIALOGUE_ORDER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFunctionStoryFlagConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FUNCTION_STORY_FLAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPerformConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PERFORM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSelectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SELECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDungeonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DUNGEON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDungeonStage(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DUNGEON_STAGE, _id, _ignoreLog)
end

function DataConfigManager:GetImportantHighValueConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.IMPORTANT_HIGH_VALUE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetImportantItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.IMPORTANT_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetImportantOutputPathConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.IMPORTANT_OUTPUT_PATH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetImportantPetMutationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.IMPORTANT_PET_MUTATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEmotionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EMOTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetItemUnlockMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ITEM_UNLOCK_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetExchangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EXCHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetExchangeGoodsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EXCHANGE_GOODS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetExchangeTimeLimitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EXCHANGE_TIME_LIMIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWishExchangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WISH_EXCHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBondTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOND_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBondTintConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOND_TINT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetChangeColourConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHANGE_COLOUR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetClosetTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CLOSET_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionBagcharmConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_BAGCHARM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionBondConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_BOND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionConflicttagConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_CONFLICTTAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionDressformConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_DRESSFORM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionPackageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_PACKAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionPerformConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_PERFORM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionSuitsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_SUITS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionViConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_VI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFashionWandConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FASHION_WAND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHeadwearHairConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HEADWEAR_HAIR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHeadwearOffsetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HEADWEAR_OFFSET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHeadwearTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HEADWEAR_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetItemTransConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ITEM_TRANS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPrivilegeRideConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PRIVILEGE_RIDE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPrivilegeWandConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PRIVILEGE_WAND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSalonItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SALON_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSalonTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SALON_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFixDataEvolutionError(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FIX_DATA_EVOLUTION_ERROR, _id, _ignoreLog)
end

function DataConfigManager:GetExchangeNormalFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EXCHANGE_NORMAL_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHandbookFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HANDBOOK_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomeFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillmachineFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILLMACHINE_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTravelFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TRAVEL_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcFollowConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_FOLLOW_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcFollowTalkConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_FOLLOW_TALK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFriendRecommendConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FRIEND_RECOMMEND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBanActionConf(_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAN_ACTION_CONF, _type, _ignoreLog)
end

function DataConfigManager:GetBanNpcConf(_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.BAN_NPC_CONF, _type, _ignoreLog)
end

function DataConfigManager:GetFunctionBanConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FUNCTION_BAN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFunctionBanSceneResConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FUNCTION_BAN_SCENE_RES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHidePlayerManualOptionConf(_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.HIDE_PLAYER_MANUAL_OPTION_CONF, _type, _ignoreLog)
end

function DataConfigManager:GetSystemRedPointBanConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SYSTEM_RED_POINT_BAN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUiBanConf(_ui_ban_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_BAN_CONF, _ui_ban_id, _ignoreLog)
end

function DataConfigManager:GetUiEnterBanConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_ENTER_BAN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetColorRandomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.COLOR_RANDOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGlassTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GLASS_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHiddenGlassConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HIDDEN_GLASS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetParticleRandomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PARTICLE_RANDOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetActivityGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTIVITY_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetAntiCheatGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ANTI_CHEAT_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetAttrGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.ATTR_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetBattleGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetBpGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BP_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetChallengeGlobalConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHALLENGE_GLOBAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDailyGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DAILY_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetFriendGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.FRIEND_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetHomeGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetLegendaryGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEGENDARY_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetLlmGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.LLM_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetMapGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAP_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetNpcGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetOnlineGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ONLINE_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetPaymentGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.PAYMENT_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetPetGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetRogueChallengeGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROGUE_CHALLENGE_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetRoleGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLE_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetSeasonGlobalConfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_GLOBAL_CONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetTakephotoGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.TAKEPHOTO_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetTaskGlobalConfig(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_GLOBAL_CONFIG, _key, _ignoreLog)
end

function DataConfigManager:GetGmAiGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_AI_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmButtonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_BUTTON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmCommandConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_COMMAND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmMaintabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_MAINTAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmServerCmdConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_SERVER_CMD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGmSubtabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GM_SUBTAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGrassTrialChapterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GRASS_TRIAL_CHAPTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGrassTrialConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GRASS_TRIAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGrassTrialEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GRASS_TRIAL_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGrassTrialEventConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GRASS_TRIAL_EVENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideAnimationIgnoreConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_ANIMATION_IGNORE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideBannerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_BANNER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideButtonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_BUTTON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideCtrlConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_CTRL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideDragConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_DRAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideFocusConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_FOCUS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideIaConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_IA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuidePanelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_PANEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHintLevel(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HINT_LEVEL, _id, _ignoreLog)
end

function DataConfigManager:GetFurnitureClassificationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FURNITURE_CLASSIFICATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFurnitureEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FURNITURE_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFurnitureHandbookConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FURNITURE_HANDBOOK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFurnitureItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FURNITURE_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFurnitureVersionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FURNITURE_VERSION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomeComfortConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_COMFORT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomeLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomePetFeedConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_PET_FEED_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHomePetLayEggRateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HOME_PET_LAY_EGG_RATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetInteriorFinishConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.INTERIOR_FINISH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPlantGrowConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLANT_GROW_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPlantGrowStageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLANT_GROW_STAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPlantLandCoordinateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLANT_LAND_COORDINATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPlantTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLANT_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetIosRatingPopupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.IOS_RATING_POPUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLineConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LINE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLlmPetBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LLM_PET_BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLlmPetNatureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LLM_PET_NATURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLoadingTipsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOADING_TIPS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpMatchTipsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_MATCH_TIPS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLocalizationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOCALIZATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSubEventsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SUB_EVENTS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSubTplsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SUB_TPLS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAllDialogueEn(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ALL_DIALOGUE_EN, _id, _ignoreLog)
end

function DataConfigManager:GetTaskDialogueEn(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_DIALOGUE_EN, _id, _ignoreLog)
end

function DataConfigManager:GetLotteryResultPageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOTTERY_RESULT_PAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLotteryRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOTTERY_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMageHelpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGE_HELP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMageInfoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGE_INFO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMageRestConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGE_REST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMagicBaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGIC_BASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMagicInteractConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGIC_INTERACT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMagicTransformConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAGIC_TRANSFORM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetStarMagicConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.STAR_MAGIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCallbackMailConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CALLBACK_MAIL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMailConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAIL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNoticeConf(_notice_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NOTICE_CONF, _notice_id, _ignoreLog)
end

function DataConfigManager:GetMallConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MALL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMallRandConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MALL_RAND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMallStoreConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MALL_STORE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMarkFakeMagicMessageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MARK_FAKE_MAGIC_MESSAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMarkGameplayConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MARK_GAMEPLAY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMarkMessageChildConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MARK_MESSAGE_CHILD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMarkMessageLifeTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MARK_MESSAGE_LIFE_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMarkVideoProtocol(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MARK_VIDEO_PROTOCOL, _id, _ignoreLog)
end

function DataConfigManager:GetMedalBondConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEDAL_BOND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMedalConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEDAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMedalTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEDAL_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTextExpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TEXT_EXP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapClassNameConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_CLASS_NAME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapGatheringConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_GATHERING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapOverlapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_OVERLAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapRefreshBlacklist(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_REFRESH_BLACKLIST, _id, _ignoreLog)
end

function DataConfigManager:GetMegamapSpeedConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MEGAMAP_SPEED_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMinigameConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MINIGAME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMinigameRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MINIGAME_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetModelCollisionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MODEL_COLLISION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetModelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MODEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetModelMatConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MODEL_MAT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetModelSocketConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MODEL_SOCKET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBloodMonsterSkillbankConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BLOOD_MONSTER_SKILLBANK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCatchConditionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CATCH_CONDITION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEscapeInfoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ESCAPE_INFO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMonsterCatchConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MONSTER_CATCH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMonsterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MONSTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMonsterGrowthConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MONSTER_GROWTH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMonsterSkillbankConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MONSTER_SKILLBANK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSpecialMoveConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SPECIAL_MOVE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMusicApplyListConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MUSIC_APPLY_LIST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMusicConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MUSIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMusicFreemiumConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MUSIC_FREEMIUM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMusicTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MUSIC_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNightmareEliteConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NIGHTMARE_ELITE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonEliteConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ELITE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAiWordConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AI_WORD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattleRandomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLE_RANDOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLocationInteractBan(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOCATION_INTERACT_BAN, _id, _ignoreLog)
end

function DataConfigManager:GetNpcActionConf(_action_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_ACTION_CONF, _action_type, _ignoreLog)
end

function DataConfigManager:GetNpcActorPoolConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_ACTOR_POOL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcAuraConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_AURA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcAuraEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_AURA_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcCompassOption(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_COMPASS_OPTION, _id, _ignoreLog)
end

function DataConfigManager:GetNpcConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcOptionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_OPTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcPeerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_PEER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcReactionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REACTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetInteractionComplex(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_INTERACTION_COMPLEX, _id, _ignoreLog)
end

function DataConfigManager:GetPetInteractionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_INTERACTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskNpc(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_NPC, _id, _ignoreLog)
end

function DataConfigManager:GetNpcCombOptionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_COMB_OPTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcCombResultConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_COMB_RESULT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcPendantConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_PENDANT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBonusContainerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BONUS_CONTAINER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBonusEventPoolConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BONUS_EVENT_POOL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBonusShiningStgConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BONUS_SHINING_STG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBonusSpeEventPoolConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BONUS_SPE_EVENT_POOL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcRefreshBonusConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REFRESH_BONUS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcRefreshContentConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REFRESH_CONTENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcRefreshGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REFRESH_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcRefreshRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REFRESH_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcRefreshTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_REFRESH_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNpcServerRefreshConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NPC_SERVER_REFRESH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRefreshCondConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REFRESH_COND_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeightGroupConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEIGHT_GROUP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetOperationMail(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OPERATION_MAIL, _id, _ignoreLog)
end

function DataConfigManager:GetOwlContentNpcConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OWL_CONTENT_NPC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetOwlPetFruitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OWL_PET_FRUIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetOwlSanctuaryConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OWL_SANCTUARY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetParagraphPackageOrderConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PARAGRAPH_PACKAGE_ORDER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetParagraphVoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PARAGRAPH_VO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAreaHandbook(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.AREA_HANDBOOK, _id, _ignoreLog)
end

function DataConfigManager:GetBasePointConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BASE_POINT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBreakItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BREAK_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBreakNumberConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BREAK_NUMBER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBreakRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BREAK_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCrystalConf(_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.CRYSTAL_CONF, _type, _ignoreLog)
end

function DataConfigManager:GetEggTypeConf(_ID, _ignoreLog)
  return self:GetData(self.ConfigTableId.EGG_TYPE_CONF, _ID, _ignoreLog)
end

function DataConfigManager:GetEvolutionActionData(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EVOLUTION_ACTION_DATA, _id, _ignoreLog)
end

function DataConfigManager:GetEvolutionLevelData(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EVOLUTION_LEVEL_DATA, _id, _ignoreLog)
end

function DataConfigManager:GetGrowLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GROW_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetInspireLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.INSPIRE_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLevelGetFixConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEVEL_GET_FIX_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLevelSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEVEL_SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetNatureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NATURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetOverlevelRatioExp(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.OVERLEVEL_RATIO_EXP, _id, _ignoreLog)
end

function DataConfigManager:GetPetbaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PETBASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetfreeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PETFREE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetpageBlacklist(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PETPAGE_BLACKLIST, _id, _ignoreLog)
end

function DataConfigManager:GetPetActionCloseExpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_ACTION_CLOSE_EXP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetBagSequence(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_BAG_SEQUENCE, _id, _ignoreLog)
end

function DataConfigManager:GetPetBloodConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_BLOOD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetBond(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_BOND, _id, _ignoreLog)
end

function DataConfigManager:GetPetBondCount(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_BOND_COUNT, _id, _ignoreLog)
end

function DataConfigManager:GetPetClassisConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_CLASSIS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetCloseLevelEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_CLOSE_LEVEL_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetEffortsLevel(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_EFFORTS_LEVEL, _id, _ignoreLog)
end

function DataConfigManager:GetPetEggConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_EGG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetEggWayToProbConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_EGG_WAY_TO_PROB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetEvolutionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_EVOLUTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetFeatureRand(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_FEATURE_RAND, _id, _ignoreLog)
end

function DataConfigManager:GetPetFreeRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_FREE_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetHabitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_HABIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetHandbook(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_HANDBOOK, _id, _ignoreLog)
end

function DataConfigManager:GetPetHandbookReward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_HANDBOOK_REWARD, _id, _ignoreLog)
end

function DataConfigManager:GetPetHandbookSequence(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_HANDBOOK_SEQUENCE, _id, _ignoreLog)
end

function DataConfigManager:GetPetLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetLikeElementConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_LIKE_ELEMENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetMarkConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_MARK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetReportScoreConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_REPORT_SCORE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetSceneAbilityGanzhi(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_SCENE_ABILITY_GANZHI, _id, _ignoreLog)
end

function DataConfigManager:GetPetShowSpeedConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_SHOW_SPEED_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetTalentConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_TALENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetTalentRandomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_TALENT_RANDOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetTopicTypeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_TOPIC_TYPE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetUiCameraConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_UI_CAMERA_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonHandbookConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_HANDBOOK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillColorConf(_unit_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_COLOR_CONF, _unit_type, _ignoreLog)
end

function DataConfigManager:GetSkillRandomConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_RANDOM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillSequenceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_SEQUENCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSubmitPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SUBMIT_PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUncommandPetSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UNCOMMAND_PET_SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetInfoConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_INFO_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetRandomEggConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_RANDOM_EGG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetPartnerData(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_PARTNER_DATA, _id, _ignoreLog)
end

function DataConfigManager:GetPetRollbackConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_ROLLBACK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPointConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.POINT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPlatformPrivileges(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PLATFORM_PRIVILEGES, _id, _ignoreLog)
end

function DataConfigManager:GetProtoCmdSeqConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PROTO_CMD_SEQ_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetTypeScoreConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_TYPE_SCORE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpAwardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_AWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpBattleScoreConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_BATTLE_SCORE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRandomPetLibraryConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANDOM_PET_LIBRARY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRandomPetRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANDOM_PET_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRandomSkillLibraryConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANDOM_SKILL_LIBRARY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRandomSkillListConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANDOM_SKILL_LIST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankPlayerPollConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_PLAYER_POLL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankRandomPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_RANDOM_PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankRobotCardIconConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_ROBOT_CARD_ICON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankRobotNameConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_ROBOT_NAME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankRobotPlayerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_ROBOT_PLAYER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankSeasonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_SEASON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankTrialPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_TRIAL_PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankTrialPetLibraryConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_TRIAL_PET_LIBRARY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRankWeekTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_RANK_WEEK_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpRobotConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_ROBOT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPvpWarehouseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PVP_WAREHOUSE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTopMasterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TOP_MASTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRankboardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RANKBOARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetReadConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.READ_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetReacallConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REACALL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetReacallListConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REACALL_LIST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetReacallTremsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REACALL_TREMS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRedPointConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RED_POINT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetInteractiontreeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.INTERACTIONTREE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRelationtreeAnimConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RELATIONTREE_ANIM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRelationtreeBasicConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RELATIONTREE_BASIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRelationtreeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RELATIONTREE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetResourceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RESOURCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLotteryPoolConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOTTERY_POOL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLotteryPoolRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LOTTERY_POOL_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRewardTag(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REWARD_TAG, _id, _ignoreLog)
end

function DataConfigManager:GetRewardWeightChangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.REWARD_WEIGHT_CHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEventBaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EVENT_BASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEventCombineConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EVENT_COMBINE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRogueLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROGUE_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUpgradeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UPGRADE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBottleTimesConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOTTLE_TIMES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBottleVolumeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOTTLE_VOLUME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetHpMaxConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.HP_MAX_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPowerMaxConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.POWER_MAX_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleExpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLE_EXP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleStarNpclevelChangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLE_STAR_NPCLEVEL_CHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleWorldLevelMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLE_WORLD_LEVEL_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldLevelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_LEVEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCardAdventureRecordConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CARD_ADVENTURE_RECORD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCardIconConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CARD_ICON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCardLabelConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CARD_LABEL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCardModuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CARD_MODULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCardSkinConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CARD_SKIN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEqsBoxExport(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EQS_BOX_EXPORT, _id, _ignoreLog)
end

function DataConfigManager:GetPetBehaviorReactionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_BEHAVIOR_REACTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleplayBehaviorConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLEPLAY_BEHAVIOR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleplayPropConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLEPLAY_PROP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRoleplaySortConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ROLEPLAY_SORT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAwardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_AWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneObjectAward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_OBJECT_AWARD, _id, _ignoreLog)
end

function DataConfigManager:GetSceneObjectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_OBJECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneResConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_RES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneUpgradeVersionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_UPGRADE_VERSION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityAscendingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_ASCENDING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityDashConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_DASH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityFlyingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_FLYING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityRidingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_RIDING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilitySlidingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_SLIDING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneAbilityThrowConf(_throw_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ABILITY_THROW_CONF, _throw_type, _ignoreLog)
end

function DataConfigManager:GetScenePlayerStatusMatrix(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_PLAYER_STATUS_MATRIX, _id, _ignoreLog)
end

function DataConfigManager:GetVitalityConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.VITALITY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAbnormalStatusConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ABNORMAL_STATUS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneStatusSalsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_STATUS_SALS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneStatusWpstConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_STATUS_WPST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonBattleRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_BATTLE_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonGrowthConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_GROWTH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonLegendaryBattleEvent(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonPartConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_PART_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonPetbase(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_PETBASE, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonPetCatchRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_PET_CATCH_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonPveBaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_PVE_BASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonSkill(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_SKILL, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTalentConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TALENT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonAdventureBadgeLevel(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ADVENTURE_BADGE_LEVEL, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonAdventureChapter(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ADVENTURE_CHAPTER, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonAdventureConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ADVENTURE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonAdventureUi(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_ADVENTURE_UI, _id, _ignoreLog)
end

function DataConfigManager:GetBonuscatchRefreshRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BONUSCATCH_REFRESH_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonBonuscatchBoxConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_BONUSCATCH_BOX_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonBonuscatchEffectsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_BONUSCATCH_EFFECTS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonBonuscatchLimitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_BONUSCATCH_LIMIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonBonuscatchSecOptConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_BONUSCATCH_SEC_OPT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonPetEffectsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_PET_EFFECTS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonFocusUmgConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_FOCUS_UMG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTipsNewPetConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TIPS_NEW_PET_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTipsPvpConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TIPS_PVP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTipsTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TIPS_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTipsTxtConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TIPS_TXT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeasonTptCommonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEASON_TPT_COMMON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSeatConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEAT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSecondTierPasswordConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SECOND_TIER_PASSWORD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMovieConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MOVIE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSequenceConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SEQUENCE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSubtitleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SUBTITLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRpcLossRateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RPC_LOSS_RATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetButtonSettingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BUTTON_SETTING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetDefaultButtonConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DEFAULT_BUTTON_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetResolutionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RESOLUTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUiKeynameConvert(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_KEYNAME_CONVERT, _id, _ignoreLog)
end

function DataConfigManager:GetPetShareItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_SHARE_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetQqArkShareConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.QQ_ARK_SHARE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShareBaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHARE_BASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShareConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHARE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSharePartConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHARE_PART_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShareRewardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHARE_REWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGoodsReturnConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GOODS_RETURN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMallFrameConf(_shop_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MALL_FRAME_CONF, _shop_id, _ignoreLog)
end

function DataConfigManager:GetMallMonthlyPassReward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MALL_MONTHLY_PASS_REWARD, _id, _ignoreLog)
end

function DataConfigManager:GetNormalShopConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.NORMAL_SHOP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRandomGoodsConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RANDOM_GOODS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetRandomShopConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RANDOM_SHOP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShopBanConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHOP_BAN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShopConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHOP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetShopTotalConsumptionConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SHOP_TOTAL_CONSUMPTION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetAttributeConf(_attribute, _ignoreLog)
  return self:GetData(self.ConfigTableId.ATTRIBUTE_CONF, _attribute, _ignoreLog)
end

function DataConfigManager:GetBuffbaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BUFFBASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBuffConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BUFF_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBuffType(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BUFF_TYPE, _id, _ignoreLog)
end

function DataConfigManager:GetDescNoteConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.DESC_NOTE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEffectAnimation(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EFFECT_ANIMATION, _id, _ignoreLog)
end

function DataConfigManager:GetEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.EFFECT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEnterbattleBuffPriority(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ENTERBATTLE_BUFF_PRIORITY, _id, _ignoreLog)
end

function DataConfigManager:GetFieldLayerConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FIELD_LAYER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPreattackSkill(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PREATTACK_SKILL, _id, _ignoreLog)
end

function DataConfigManager:GetResBgsTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RES_BGS_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetResBuffTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RES_BUFF_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetResSkillTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.RES_SKILL_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillfullyExchangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILLFULLY_EXCHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillspecialConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILLSPECIAL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillInteractConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_INTERACT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillResChangeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_RES_CHANGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillResConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_RES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillTag(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_TAG, _id, _ignoreLog)
end

function DataConfigManager:GetSkillTimeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_TIME_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSkillUiDes(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_UI_DES, _id, _ignoreLog)
end

function DataConfigManager:GetTypeDictionary(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TYPE_DICTIONARY, _id, _ignoreLog)
end

function DataConfigManager:GetSlideConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SLIDE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBottleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOTTLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFruitTreeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FRUIT_TREE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetFruitTreeRuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.FRUIT_TREE_RULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWindGrass(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WIND_GRASS, _id, _ignoreLog)
end

function DataConfigManager:GetSplineConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SPLINE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLegendaryBattleAward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LEGENDARY_BATTLE_AWARD, _id, _ignoreLog)
end

function DataConfigManager:GetStarAwardConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.STAR_AWARD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTeamBattleAward(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TEAM_BATTLE_AWARD, _id, _ignoreLog)
end

function DataConfigManager:GetActcontrolconfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTCONTROLCONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetChannelcontrolconfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHANNELCONTROLCONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetSystemcontrolconfig(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SYSTEMCONTROLCONFIG, _id, _ignoreLog)
end

function DataConfigManager:GetCameraSkinConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CAMERA_SKIN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTakePhotoEmojiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TAKE_PHOTO_EMOJI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTakePhotoFilterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TAKE_PHOTO_FILTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTakePhotoPoseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TAKE_PHOTO_POSE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetChapterConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CHAPTER_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGpContestConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GP_CONTEST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetGuideConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.GUIDE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMessageConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MESSAGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetParagraphConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PARAGRAPH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetStoryBgmConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.STORY_BGM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSubTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SUB_TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaleBloodMagicConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TALE_BLOOD_MAGIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaleNightmareConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TALE_NIGHTMARE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaleNotebookKeliConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TALE_NOTEBOOK_KELI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskItem(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_ITEM, _id, _ignoreLog)
end

function DataConfigManager:GetTaskModuleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_MODULE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskPetParamConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_PET_PARAM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskStateConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_STATE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskStyleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_STYLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskSummary(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_SUMMARY, _id, _ignoreLog)
end

function DataConfigManager:GetTaskSwitchConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_SWITCH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTaskTokenConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TASK_TOKEN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTrackNumber(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TRACK_NUMBER, _id, _ignoreLog)
end

function DataConfigManager:GetUnitConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UNIT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTeachConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TEACH_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTeachTabConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TEACH_TAB_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSceneEnterExit(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SCENE_ENTER_EXIT, _id, _ignoreLog)
end

function DataConfigManager:GetTeleportConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TELEPORT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTeleportLoadingConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TELEPORT_LOADING_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTeleportRulesConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TELEPORT_RULES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetEnvTagConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ENV_TAG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTestRechargeAmountConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TEST_RECHARGE_AMOUNT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTitleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TITLE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTreasureItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TREASURE_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetSpeRefreshTrigConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SPE_REFRESH_TRIG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUiCompass(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_COMPASS, _id, _ignoreLog)
end

function DataConfigManager:GetUiConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUiLobbyMainCompass(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_LOBBY_MAIN_COMPASS, _id, _ignoreLog)
end

function DataConfigManager:GetUiReconnect(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UI_RECONNECT, _id, _ignoreLog)
end

function DataConfigManager:GetBalltlepassAwardmainConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BALLTLEPASS_AWARDMAIN_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBattlepassPurchaseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BATTLEPASS_PURCHASE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUmgDialogConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UMG_DIALOG_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetUmgStaticConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.UMG_STATIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetVideoSubtitlesConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.VIDEO_SUBTITLES_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetVisualItemConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.VISUAL_ITEM_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetPetWarehouseConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.PET_WAREHOUSE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTidySequenceType(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TIDY_SEQUENCE_TYPE, _id, _ignoreLog)
end

function DataConfigManager:GetWarehouseCollectMark(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WAREHOUSE_COLLECT_MARK, _id, _ignoreLog)
end

function DataConfigManager:GetWaterMarkControlConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WATER_MARK_CONTROL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWaterMarkLocalizationConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WATER_MARK_LOCALIZATION_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWaterMarkWhiteListConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WATER_MARK_WHITE_LIST_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetTodConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.TOD_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWeatherConf(_weather_type, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEATHER_CONF, _weather_type, _ignoreLog)
end

function DataConfigManager:GetActionAnimBoneTransformInfo(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ACTION_ANIM_BONE_TRANSFORM_INFO, _id, _ignoreLog)
end

function DataConfigManager:GetBlockConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BLOCK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetBossSkillsMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.BOSS_SKILLS_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetCurveDetailInfo(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.CURVE_DETAIL_INFO, _id, _ignoreLog)
end

function DataConfigManager:GetSkillAnimSocketsInfo(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.SKILL_ANIM_SOCKETS_INFO, _id, _ignoreLog)
end

function DataConfigManager:GetWeaknessConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WEAKNESS_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldCombatConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_COMBAT_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldCombatSkillConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_COMBAT_SKILL_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldCombatSkillCurveConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_COMBAT_SKILL_CURVE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetLayeredWorldMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.LAYERED_WORLD_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetMapInfoBarConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.MAP_INFO_BAR_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldExploringStatisticConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_EXPLORING_STATISTIC_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapActivityConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_ACTIVITY_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapAreaGuide(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_AREA_GUIDE, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapBlockConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_BLOCK_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapChallengeConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_CHALLENGE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapDefaultTrack(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_DEFAULT_TRACK, _id, _ignoreLog)
end

function DataConfigManager:GetWorldMapGlobalConf(_key, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_GLOBAL_CONF, _key, _ignoreLog)
end

function DataConfigManager:GetWorldMapScaleConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_MAP_SCALE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetWorldZoneConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.WORLD_ZONE_CONF, _id, _ignoreLog)
end

function DataConfigManager:GetZoneEffectConf(_id, _ignoreLog)
  return self:GetData(self.ConfigTableId.ZONE_EFFECT_CONF, _id, _ignoreLog)
end

return DataConfigManager
