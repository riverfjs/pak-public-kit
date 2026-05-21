local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.Helper.Magic.MagicAbilityBaseHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_COMMENT_MESSAGE_TRACE

local function CheckIfBan(showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  return isBan
end

local MessageAbilityHelper = Base:Extend("MessageAbilityHelper")

function MessageAbilityHelper:Ctor(abilityConfig)
  Base.Ctor(self, abilityConfig)
  self._buffName = "PrepareMessageBuff"
  self.story = false
  self.SystemBan = false
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdd)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_REMOVED, self.OnStoryFlagRemove)
  local storyFlags = _G.DataModelMgr.PlayerDataModel:GetStoryFlags()
  for _, storyFlag in pairs(storyFlags) do
    local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(storyFlag, true)
    if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
      self.story = true
      break
    end
  end
  self.functionBanUIController = FunctionBanUIController()
  do
    local functionBanUIController = self.functionBanUIController
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnSystemControlChangeHandler, self, -1)
    end
    functionBanUIController:Activate()
  end
end

function MessageAbilityHelper:OnSystemControlChangeHandler(tabIndex, funcId, bHide)
  if funcId == FunctionEntranceMain then
    local isBan = bHide or CheckIfBan(false)
    self.SystemBan = isBan
  end
end

function MessageAbilityHelper:OnStoryFlagAdd(flag, bIsHomeOwner)
  if bIsHomeOwner then
    return
  end
  local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(flag, true)
  if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
    self.story = true
  end
end

function MessageAbilityHelper:OnStoryFlagRemove(flag, bIsHomeOwner)
  if bIsHomeOwner then
    return
  end
  local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(flag, true)
  if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
    self.story = false
  end
end

function MessageAbilityHelper:CanCastAbility(caster)
  local result = Base.CanCastAbility(self, caster)
  if result ~= AbilityErrorCode.NO_ERROR then
    return result
  end
  if self.story then
    return AbilityErrorCode.STORY_BAN
  end
  if self.SystemBan then
    return AbilityErrorCode.SYSTEM_BAN
  end
  if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.IsPlaying) then
    return AbilityErrorCode.GAME_BAN
  end
  return result
end

return MessageAbilityHelper
