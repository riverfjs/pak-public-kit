local SystemSettingEnum = require("NewRoco.Modules.System.SystemSetting.SystemSettingEnum")
local JsonUtils = require("Common.JsonUtils")
local _CustomKeyMappingConfigFilename = "NrcCustomKeyMapping"
local SystemSettingModuleData = _G.NRCData:Extend("SystemSettingModuleData")
SystemSettingModuleData.BindMobilePhoneEnum = {
  BIND = 0,
  UNBIND = 1,
  BIND_SUCCESS = 2,
  UNBIND_SUCCESS = 3
}
SystemSettingModuleData.BindMobileOperateEnum = {BIND = 0, UNBIND = 1}
SystemSettingModuleData.CodeLimitLen = 6
SystemSettingModuleData.PhoneLimitLen = 11

function SystemSettingModuleData:Ctor()
  NRCData.Ctor(self)
  self.BindPhoneSettingData = nil
  self:InitConfig()
end

function SystemSettingModuleData:InitConfig()
  self.GraphicConfig = {
    Resoluction = {
      Name = LuaText.systemsettingmoduledata_1,
      Options = {
        {Name = "2520x1134", Value = 1134},
        {Name = "2400x1080", Value = 1080},
        {Name = "2000x900", Value = 900}
      }
    },
    FPS = {
      Name = LuaText.systemsettingmoduledata_2,
      Options = {
        {
          Name = LuaText.systemsettingmoduledata_4,
          Value = UE4.ENRCFrameQuality.Low,
          Type = SystemSettingEnum.Type.Fps,
          bPC = false
        },
        {
          Name = LuaText.systemsettingmoduledata_5,
          Value = UE4.ENRCFrameQuality.Medium,
          Type = SystemSettingEnum.Type.Fps,
          bPC = nil
        },
        {
          Name = LuaText.systemsettingmoduledata_6,
          Value = UE4.ENRCFrameQuality.High,
          Type = SystemSettingEnum.Type.Fps,
          bPC = nil
        },
        {
          Name = LuaText.systemsettingmoduledata_16,
          Value = UE4.ENRCFrameQuality.Super,
          Type = SystemSettingEnum.Type.Fps,
          bPC = nil
        },
        {
          Name = LuaText.systemsettingmoduledata_7,
          Value = UE4.ENRCFrameQuality.Ultra,
          Type = SystemSettingEnum.Type.Fps,
          bPC = nil
        },
        {
          Name = LuaText.systemsettingmoduledata_15,
          Value = UE4.ENRCFrameQuality.Epic,
          Type = SystemSettingEnum.Type.Fps,
          bPC = false
        },
        {
          Name = LuaText.setting_image_rate_nolimit,
          Value = UE4.ENRCFrameQuality.Unlimit,
          Type = SystemSettingEnum.Type.Fps,
          bPC = true
        }
      }
    },
    MobileResolution = {
      Name = LuaText.setting_image_resolution_ratio,
      Options = {
        {
          Name = LuaText.systemsettingmoduledata_4,
          Value = UE4.ENRCMobileResolutionQuality.UI720L1,
          Type = SystemSettingEnum.Type.MobileResolution
        },
        {
          Name = LuaText.systemsettingmoduledata_5,
          Value = UE4.ENRCMobileResolutionQuality.UI1080L3,
          Type = SystemSettingEnum.Type.MobileResolution
        },
        {
          Name = LuaText.systemsettingmoduledata_6,
          Value = UE4.ENRCMobileResolutionQuality.UI1080L4,
          Type = SystemSettingEnum.Type.MobileResolution
        }
      }
    },
    ImageQuality = {
      Name = LuaText.systemsettingmoduledata_13,
      Options = {
        {
          Name = LuaText.systemsettingmoduledata_4,
          Value = UE4.ENRCImageQuality.Low,
          ConfigValue = {
            FPS = 1,
            ShadowQuality = 1,
            FoliageQuality = 1,
            PostProcessQuality = 1,
            TextureQuality = 1,
            SceneDetailQuality = 1,
            EffectsQuality = 1,
            CloudQuality = 1
          }
        },
        {
          Name = LuaText.systemsettingmoduledata_5,
          Value = UE4.ENRCImageQuality.Medium,
          ConfigValue = {
            FPS = 1,
            ShadowQuality = 2,
            FoliageQuality = 2,
            PostProcessQuality = 2,
            TextureQuality = 2,
            SceneDetailQuality = 2,
            EffectsQuality = 2,
            CloudQuality = 2
          }
        },
        {
          Name = LuaText.systemsettingmoduledata_6,
          Value = UE4.ENRCImageQuality.High,
          ConfigValue = {
            FPS = 2,
            ShadowQuality = 3,
            FoliageQuality = 3,
            PostProcessQuality = 3,
            TextureQuality = 3,
            SceneDetailQuality = 3,
            EffectsQuality = 3,
            CloudQuality = 3
          }
        },
        {
          Name = LuaText.systemsettingmoduledata_16,
          Value = UE4.ENRCImageQuality.Epic,
          ConfigValue = {
            FPS = 2,
            ShadowQuality = 4,
            FoliageQuality = 4,
            PostProcessQuality = 4,
            TextureQuality = 4,
            SceneDetailQuality = 4,
            EffectsQuality = 4,
            CloudQuality = 4
          }
        },
        {
          Name = LuaText.systemsettingmoduledata_15,
          Value = UE4.ENRCImageQuality.QualityNum
        },
        {
          Name = LuaText.systemsettingmoduledata_14,
          Value = UE4.ENRCImageQuality.Custom
        }
      }
    },
    EffectsQuality = {
      Name = LuaText.setting_image_special_effect_quality,
      Options = {
        {
          Name = LuaText.systemsettingmoduledata_4,
          Value = 0
        },
        {
          Name = LuaText.systemsettingmoduledata_5,
          Value = 1
        },
        {
          Name = LuaText.systemsettingmoduledata_6,
          Value = 2
        }
      }
    },
    ReflectionQuality = {
      Name = LuaText.setting_image_seflection_quality,
      Options = {
        {
          Name = LuaText.setting_image_close,
          Value = 0
        },
        {
          Name = LuaText.setting_image_open,
          Value = 2
        }
      }
    },
    VsyncQuality = {
      Options = {
        {
          Name = LuaText.setting_image_close,
          Value = 0
        },
        {
          Name = LuaText.setting_image_open,
          Value = 2
        }
      }
    }
  }
  local groups = {
    "ShadowQuality",
    "FoliageQuality",
    "PostProcessQuality",
    "TextureQuality",
    "SceneDetailQuality",
    "EffectsQuality",
    "CloudQuality",
    "ReflectionQuality"
  }
  for _, group in pairs(groups) do
    Log.Debug("SystemSettingModuleData:InitConfig group", group)
    local group_config = _G.DataConfigManager:GetQualityMappingConf(group)
    if group_config then
      local last_local_index = -1
      if not self.GraphicConfig[group] then
        self.GraphicConfig[group] = {}
      end
      self.GraphicConfig[group].Options = {}
      for i = 0, 3 do
        local local_index = group_config.Qualities[2 + i + 1].QualityPriority
        Log.Debug("SystemSettingModuleData:InitConfig i, local_index last_local_index", i, local_index, last_local_index)
        if local_index ~= last_local_index then
          last_local_index = local_index
          local local_conf = _G.DataConfigManager:GetQualityLocalizationConf(local_index)
          if local_conf then
            local shadow_name = LuaText[local_conf.key]
            local item = {Name = shadow_name, Value = i}
            table.insert(self.GraphicConfig[group].Options, item)
            Log.Debug("SystemSettingModuleData:InitConfig add Name=", shadow_name, " Value=", i)
          else
            Log.Error("local_conf nil")
          end
        end
      end
    else
      Log.Error("group_config nil")
    end
  end
  self.PrivacyConfig = {
    TabIcon = {
      Name = "tab\229\155\190\230\160\135",
      Options = {
        {
          Name = "\230\152\190\231\164\186\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_IMG,
          Icon2Path = UEPath.SYSTEM_SET_IMG_SELECTED,
          TabType = 1
        },
        {
          Name = "\233\149\156\229\164\180\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_LENS,
          Icon2Path = UEPath.SYSTEM_SET_LENS_SELECTED,
          TabType = 2
        },
        {
          Name = "\229\163\176\233\159\179\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_SOUND,
          Icon2Path = UEPath.SYSTEM_SET_SOUND_SELECTED,
          TabType = 3
        },
        {
          Name = "\231\148\168\230\136\183\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_USER_ACCOUNT,
          Icon2Path = UEPath.SYSTEM_SET_USER_ACCOUNT_SELECTED,
          TabType = 4
        },
        {
          Name = "\233\154\144\231\167\129\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_PRIVACY,
          Icon2Path = UEPath.SYSTEM_SET_PRIVACY_SELECTED,
          TabType = 5
        },
        {
          Name = "\228\184\139\232\189\189\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_DOWNLOAD,
          Icon2Path = UEPath.SYSTEM_SET_DOWNLOAD_SELECTED,
          TabType = 6
        },
        {
          Name = "\230\140\137\233\148\174\232\174\190\231\189\174",
          Icon1Path = UEPath.SYSTEM_SET_KEY_MAPPING,
          Icon2Path = UEPath.SYSTEM_SET_KEY_MAPPING_SELECTED,
          TabType = 7
        }
      }
    }
  }
  self.PlayerConfig = {
    WatchFriendBattleSetting = {
      Name = "\232\167\130\230\136\152\232\174\190\231\189\174",
      Options = {
        {Name = "\229\133\129\232\174\184", Value = 1},
        {Name = "\231\166\129\230\173\162", Value = 0}
      }
    }
  }
  self.playerSettings = nil
  self.UnMappableKeyName = {
    "None",
    "NumLock",
    "ScrollLock",
    "Pause",
    "LeftAlt"
  }
  self.UnMappableKeyCode = 93
  self.bEnableSleepModeOnEditor = false
  self.bEnableSleepMode = true
  local SALS = _G.ProtoEnum and _G.ProtoEnum.SpaceActorLogicStatus
  self.sleepModeBlockers = {
    SALS.SALS_FIGHTING,
    SALS.SALS_RIDING,
    SALS.SALS_BANFIGHTING,
    SALS.SALS_PLAY_CG,
    SALS.SALS_OPEN_UI_FULL_SCENE,
    SALS.SALS_OPEN_UI_NOT_FULL_SCENE,
    SALS.SALS_OPEN_UI,
    SALS.SALS_LOGIN,
    SALS.SALS_TELEPORT,
    SALS.SALE_REVIVE,
    SALS.SALS_MATCHING,
    SALS.SALS_PVP_FIGHTING,
    SALS.SALS_PET_INTERACTING,
    SALS.SALS_MAGIC_INTERACTING,
    SALS.SALS_NPCS_INTERACTING,
    SALS.SALS_MINI_GAME,
    SALS.SALS_UNINTERRUPTIBLE_INTERACTING,
    SALS.SALS_VISITING,
    SALS.SALS_WORLD_COMBAT,
    SALS.SALS_WORLD_COMBAT_LEAVING,
    SALS.SALS_CHANGE_EGG,
    SALS.SALS_PK_PREPARE,
    SALS.SALS_INVITE,
    SALS.SALS_PLAYER_INTERACT_INVITE,
    SALS.SALS_DOUBLE_RIDE_GUEST,
    SALS.SALS_OPEN_LOBBY_MAIN_INNER,
    SALS.SALS_STATIC_SCENE_NOPK,
    SALS.SALS_STATIC_SCENE_TYPEA,
    SALS.SALS_STATIC_SCENE_TYPEB,
    SALS.SALS_STATIC_SCENE_TYPEC,
    SALS.SALS_STATIC_SCENE_TYPED,
    SALS.SALS_TAKE_PHOTO_HANDHELD,
    SALS.SALS_TAKE_PHOTO_TRIPOD_CAMERA,
    SALS.SALS_TAKE_PHOTO_TRIPOD_WORLD,
    SALS.SALS_ROOM_EXPAND_FINISH,
    SALS.SALS_ROOM_EXPAND_ING,
    SALS.SALS_NEWPLAYER_GUIDE_BLACKMASK,
    SALS.SALS_NEWPLAYER_GUIDE,
    SALS.SALS_ROOM_EDTING,
    SALS.SALS_VISIT_HOME,
    SALS.SALS_HOLD_HANDS_LEADER,
    SALS.SALS_HOLD_HANDS_GUEST,
    SALS.SALS_MSG_INPUT,
    SALS.SALS_OPEN_PLAYER_RELATIONSHIP_TREE,
    SALS.SALS_WAIT_FOR_OTHERS,
    SALS.SALS_TELEPORT_TOGETHER
  }
end

function SystemSettingModuleData:GetGraphicConfigByKey(key)
  return self.GraphicConfig[key]
end

function SystemSettingModuleData:GetPrivacyConfigByKey(key)
  return self.PrivacyConfig[key]
end

function SystemSettingModuleData:GetPlayerConfigByKey(key)
  return self.PlayerConfig[key]
end

function SystemSettingModuleData:GetEncryptPhoneNum(phoneNum)
  local len = #phoneNum
  local maskStr = string.rep("*", 4)
  return phoneNum:sub(1, 3) .. maskStr .. phoneNum:sub(len - 3)
end

function SystemSettingModuleData:BuildButtonTypeToButtonSettingConfMap()
  self.ButtonTypeToButtonSettingConf = {}
  local buttonSettingConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BUTTON_SETTING_CONF)
  if nil == buttonSettingConf then
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168", _G.DataConfigManager.ConfigTableId.BUTTON_SETTING_CONF)
    return
  end
  local allButtonSettingConf = buttonSettingConf:GetAllDatas()
  for _, conf in pairs(allButtonSettingConf) do
    if conf.button_type then
      local allButtonConf = self.ButtonTypeToButtonSettingConf[conf.button_type]
      if nil == allButtonConf then
        allButtonConf = {}
      end
      table.insert(allButtonConf, conf)
      self.ButtonTypeToButtonSettingConf[conf.button_type] = allButtonConf
    end
  end
end

function SystemSettingModuleData:LoadUserCustomKeyMapping(bForceLoadDefaultMapping)
  if nil == bForceLoadDefaultMapping then
    bForceLoadDefaultMapping = false
  end
  local customKeyMapping = JsonUtils.LoadSaved(_CustomKeyMappingConfigFilename, {})
  local NoValidUserCustomKeyMapping = 0 == #customKeyMapping
  if bForceLoadDefaultMapping or NoValidUserCustomKeyMapping then
    self.UserCustomKeyMapping = self:LoadDefaultKeyMapping() or {}
  else
    self.UserCustomKeyMapping = customKeyMapping
  end
end

function SystemSettingModuleData:LoadDefaultKeyMapping()
  local defaultButtonConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.DEFAULT_BUTTON_CONF)
  if nil == defaultButtonConf then
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168", _G.DataConfigManager.ConfigTableId.DEFAULT_BUTTON_CONF)
    return
  end
  local keyMapping = {}
  local allDefaultButtonConf = defaultButtonConf:GetAllDatas()
  for _, conf in pairs(allDefaultButtonConf) do
    keyMapping[conf.id] = conf.default_button
  end
  return keyMapping
end

function SystemSettingModuleData:BuildKeyUINameMap()
  local uiKeyNameConvertConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.UI_KEYNAME_CONVERT)
  if nil == uiKeyNameConvertConf then
    Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168", _G.DataConfigManager.ConfigTableId.UI_KEYNAME_CONVERT)
    return
  end
  self.KeyUINameMap = {}
  self.KeyUIImage = {}
  local allUIKeyNameConvertConf = uiKeyNameConvertConf:GetAllDatas()
  for _, conf in pairs(allUIKeyNameConvertConf) do
    if conf.UE_button_name then
      if not string.IsNilOrEmpty(conf.UI_button_name) then
        local targetString = self:ExtraTargetString(conf.UI_button_name)
        self.KeyUINameMap[conf.UE_button_name] = targetString
      elseif conf.UI_button_path then
        self.KeyUIImage[conf.UE_button_name] = conf.UI_button_path
      end
    end
  end
end

function SystemSettingModuleData:ExtraTargetString(originalString)
  return string.gmatch(originalString, "{([^{}]*)}")() or originalString
end

function SystemSettingModuleData:SetBindPhoneDesc(data)
  self.BindPhoneDescData = data
end

function SystemSettingModuleData:GetBindPhoneDesc()
  return self.BindPhoneDescData
end

return SystemSettingModuleData
