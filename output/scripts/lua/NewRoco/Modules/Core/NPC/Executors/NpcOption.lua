local Class = _G.MakeSimpleClass
local DummyTable = require("Common.DummyTable")
local BubbleType = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleType")
local NPCActionFactory = require("NewRoco.Modules.Core.NPC.Actions.NPCActionFactory")
local PetActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PetActionFactory")
local MagicActionFactory = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionFactory")
local PowerDashActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PowerDashAction.PowerDashActionFactory")
local StaticAreaConfArea = require("NewRoco.Modules.Core.Scene.Common.StaticAreaConfArea")
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local NpcOptionEvent = require("NewRoco.Modules.Core.NPC.Executors.NpcOptionEvent")
local NavigationComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.NavigationComponent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local EventDispatcher = require("Common.EventDispatcher")
local EnvSystemModuleEvent = require("NewRoco.Modules.System.EnvSystem.EnvSystemModuleEvent")
local TimeUtils = require("NewRoco.Modules.System.EnvSystem.TimeUtils")
local PowerDashActionEvent = require("NewRoco.Modules.Core.NPC.Actions.PowerDashAction.PowerDashActionEvent")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local HomeUtils = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NoPetForbidActions = {
  ProtoEnum.ActionType.ACT_BATTLE,
  ProtoEnum.ActionType.ACT_ENTER_CAMP,
  ProtoEnum.ActionType.ACT_OPEN_CHAPTER
}
local ActionsNotShowForHomeVisit = {
  Enum.ActionType.ACT_PICKEGG_HOME
}
local needStatusNotify = false
local EmoteParamCacheDict = {}

local function PreprocessOptionInfo(info)
  info.enabled = info.enabled or false
  info.executable_times = info.executable_times or -1
  info.succ_exec_times = info.succ_exec_times or 0
  info.first_dialog_id = info.first_dialog_id or 0
end

local NpcOption = Class("NpcOption")
EventDispatcher.BindClass(NpcOption)
NpcOption:SetMemberCount(26)

function NpcOption:PreCtor()
  self.optionDistanceSquared = -1
  self.OptionDistance = -1
  self.OptionDistanceLeaveSquared = -1
  self.OptionDistanceLeave = -1
  self.configRotationCos = 0
  self.PlayerViewRotationCos = 0
  self.disable_by_custom_condition = false
  self.RunningDashAction = false
  self.bAutoCollected = false
  self.executeTimes = 0
  self.inActionArea = false
  self.DetectArea = false
  self.bInteractUIAdded = nil
  self.bSelected = nil
  self.isWaitingForRsp = false
  self.CurrentAction = false
  self.CurrentPetAction = false
  self.CurrentWildAction = false
  self.CurrentMagicActions = DummyTable
  self.CachedBeginActions = DummyTable
  self.ridePetGidBeforeInteract = 0
  self.needRestoreRide = false
  self.DelayActionHandler = -1
end

function NpcOption:Ctor(owner, optionInfo)
  EventDispatcher():Attach(self)
  PreprocessOptionInfo(optionInfo)
  self.owner = owner
  self.optionInfo = optionInfo
  self.config = _G.DataConfigManager:GetNpcOptionConf(optionInfo.option_id)
  if not self.config then
    Log.Error("\230\137\190\228\184\141\229\136\176 npc \233\128\137\233\161\185\233\133\141\231\189\174:", optionInfo.option_id)
  end
  local show_option_rotation = math.clamp(self.config.show_option_rotation, 0, 360)
  self.configRotationCos = math.cos(math.rad(show_option_rotation / 2 or 0))
  local PlayerViewRotation = math.clamp(self.config.vision_range, 0, 360)
  self.PlayerViewRotationCos = math.cos(math.rad(PlayerViewRotation / 2 or 0))
  if optionInfo.enabled then
    self.CurrentAction = NPCActionFactory:TryPostInitAction(self, self.config.action, self.optionInfo.cur_action_info, self.owner)
  else
    self.CurrentAction = false
  end
  self.CurrentPetAction = false
  self.CurrentWildAction = false
  self.CachedDialogueForbidState = nil
  local EnableCondition = self:GetEnableCondition()
  if EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_WEATHER or EnableCondition == _G.Enum.OptionVisibleCondition.DISABLE_CONDITION_WEATHER then
    local envSystem = _G.NRCModuleManager:GetModule("EnvSystemModule")
    envSystem:RegisterEvent(self, EnvSystemModuleEvent.WeatherChangeEvent, self.OnConditionChange)
    self:UpdateCustomDisable()
  elseif EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_TIME then
    self.time_req_arr = {}
    local times = string.split(self.config.option_enable_condition_param, ";")
    for i, time in ipairs(times) do
      local req = _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.RegisterTimeCallback, nil, TimeUtils.ParseTimeSpan(time), true, self.OnConditionChange, self)
      table.insert(self.time_req_arr, req)
    end
    self:UpdateCustomDisable()
  elseif EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_OPTION_TYPE then
    local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
    _G.NRCEventCenter:RegisterEvent("NPCModuelInterComp", self, NPCModuleEvent.OnHomePetInfoChanged, self.OnConditionChange)
    local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
    if homeModule then
      local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
      homeModule:RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.OnConditionChange)
      homeModule:RegisterEvent(self, HomeModuleEvent.OnEquipFoodChange, self.OnConditionChange)
      homeModule:RegisterEvent(self, HomeModuleEvent.OnInteractingItemChange, self.OnConditionChange)
      homeModule:RegisterEvent(self, HomeModuleEvent.OnReEnterHomeMap, self.OnConditionChange)
    end
    self:UpdateCustomDisable()
  end
  if self.config.npc_interact_condition == Enum.InteractConditionType.INTERACT_COND_NPC_CREATOR_AND_TOGETHER then
    self:RegisterTogetherMoveEvents()
  end
end

function NpcOption:GetExecuteTimes()
  return math.max(self.executeTimes, self.optionInfo.succ_exec_times)
end

function NpcOption:RegisterTogetherMoveEvents()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_HANDINHAND, self.OnTogetherMoveStateChange)
  end
end

function NpcOption:UnregisterTogetherMoveEvents()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_HANDINHAND, self.OnTogetherMoveStateChange)
  end
end

function NpcOption:OnTogetherMoveStateChange(isTogether)
  Log.Debug("NpcOption:OnTogetherMoveStateChange \231\137\181\230\137\139\231\138\182\230\128\129\229\143\145\231\148\159\229\143\152\229\140\150", isTogether, self.config.id)
  if self.owner then
    local interactionComponent = self.owner.InteractionComponent
    if interactionComponent then
      interactionComponent:CalcCheckOpts()
    end
  end
end

function NpcOption:IncreaseExecuteTimes()
  local OldTimes = self.executeTimes
  self.executeTimes = OldTimes + 1
  local Type = self:GetInteractType()
  if Type ~= Enum.InteractType.IT_AUTOMANUAL then
    return
  end
  self.inActionArea = false
  if 0 == OldTimes and self.executeTimes >= 1 then
    self:ClearDistanceCache()
  end
end

function NpcOption:GetInteractType()
  return self.config.npc_interact_type
end

function NpcOption:GetID()
  return self.config.id
end

function NpcOption:IsAuto()
  local Type = self:GetInteractType()
  if Type == Enum.InteractType.IT_AUTO then
    return true
  elseif Type == Enum.InteractType.IT_AUTOMANUAL then
    return 0 == self:GetExecuteTimes()
  end
  return false
end

function NpcOption:IsManual()
  local Type = self:GetInteractType()
  if Type == Enum.InteractType.IT_MANUAL then
    return true
  elseif Type == Enum.InteractType.IT_AUTOMANUAL then
    return self:GetExecuteTimes() > 0
  elseif Type == Enum.InteractType.IT_SCENE_SIT then
    return true
  elseif Type == Enum.InteractType.IT_HOME_GRID then
    return true
  elseif Type == _G.Enum.InteractType.IT_MANUAL_BOND then
    return true
  elseif Type == _G.Enum.InteractType.IT_HOME_PET_FEED or Type == _G.Enum.InteractType.IT_HOME_PET_REWARD or Type == _G.Enum.InteractType.IT_HOME_PET_STEAL then
    return true
  end
  return false
end

function NpcOption:IsPetBond()
  local Type = self:GetInteractType()
  if Type == _G.Enum.InteractType.IT_MANUAL_BOND then
    return true
  end
  return false
end

function NpcOption:HasArea()
  return self.config.option_area and 0 ~= self.config.option_area
end

function NpcOption:RegisterArea()
  if self.DetectArea then
    return
  end
  local ActorID = self.owner:GetServerId()
  local OptionID = self:GetID()
  self.DetectArea = StaticAreaConfArea.MakeWithAreaConf(string.format("NpcOption_%u_%d", ActorID, OptionID), self.config.option_area, self)
  self.DetectArea:StartDetect()
  Log.DebugFormat("start detect area %s", self.DetectArea:GetUniqueName())
end

function NpcOption:UnregisterArea()
  if not self.DetectArea then
    return false
  end
  Log.DebugFormat("stop detect area %s", self.DetectArea:GetUniqueName())
  self.DetectArea:StopDetect()
  self.DetectArea:Destroy()
  self.DetectArea = false
end

function NpcOption:InArea()
  if not self.DetectArea then
    return false
  end
  return self.DetectArea:InArea()
end

function NpcOption:ShouldShowOnUI()
  if not self:IsManual() then
    return false
  end
  if self.config.action == nil then
    return false
  end
  local ActionType = self.config.action.action_type
  if nil == ActionType then
    return false
  end
  if ActionType == Enum.ActionType.ACT_NONE then
    return false
  end
  if self.CurrentAction and self.CurrentAction.bInteracting then
    return false
  end
  if not _G.DataModelMgr.PlayerDataModel:HasPet() then
    if table.contains(NoPetForbidActions, ActionType) then
      return false
    end
    if ActionType == ProtoEnum.ActionType.ACT_DIALOG then
      if nil == self.CachedDialogueForbidState then
        local DialogueID = tonumber(self.config.action.action_param1) or 0
        self.CachedDialogueForbidState = DialogueUtils.CheckDialogueContainActions(DialogueID, NoPetForbidActions)
      end
      if self.CachedDialogueForbidState then
        return false
      end
    end
  end
  if not self.owner:GetVisible() then
    return false
  end
  local EnableCondition = self:GetEnableCondition()
  if EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_OPTION_TYPE and self.disable_by_custom_condition then
    return false
  end
  return true
end

function NpcOption:Destroy()
  if self.CurrentPetAction then
    self.CurrentPetAction:Destroy()
    self.CurrentPetAction = false
  end
  if self.CurrentWildAction then
    self.CurrentWildAction:Destroy()
    self.CurrentWildAction = false
  end
  if self.CurrentAction then
    self.CurrentAction:Destroy()
    self.CurrentAction = nil
  end
  if self._StayToFireId then
    _G.DelayManager:CancelDelayById(self._StayToFireId)
    self._StayToFireId = nil
  end
  if self.time_req_arr then
    for i, req in ipairs(self.time_req_arr) do
      _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.UnRegisterTimeCallback, req)
    end
  end
  self:SendEvent(NpcOptionEvent.Destroy, self)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.RemoveNPCInteract, self)
  local envSystem = _G.NRCModuleManager:GetModule("EnvSystemModule")
  if envSystem then
    envSystem:UnRegisterEvent(self, EnvSystemModuleEvent.WeatherChangeEvent)
  end
  local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.OnHomePetInfoChanged, self.OnConditionChange)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEquipFoodChange)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnInteractingItemChange)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnReEnterHomeMap)
  end
  self:UnregisterTogetherMoveEvents()
  if self.DelayActionHandler > 0 then
    _G.DelayManager:CancelDelayById(self.DelayActionHandler)
    self.DelayActionHandler = -1
  end
  EventDispatcher.Detach(self)
end

function NpcOption:OnSetViewObj()
  if self.owner.luaObj and self.owner.luaObj.InitActStatus then
    self.owner.luaObj:InitActStatus(self.optionInfo)
  end
end

function NpcOption:InternalIsDisableByOnlineMode(Value)
  if Value == Enum.OnlineVisitProcess.OVP_ONLY_NPC_CREATOR then
    return not self.owner:IsControlledByPlayer()
  end
  return _G.DataModelMgr.PlayerDataModel:IsOnlineProcessDisable(Value)
end

function NpcOption:IsDisableByOnlineMode()
  return self:InternalIsDisableByOnlineMode(self.config.online_process)
end

function NpcOption:IsDisableByOnlineModeUI()
  if not self:InternalIsDisableByOnlineMode(self.config.online_process) then
    return false
  end
  if not self.config.online_hidden_forbid_options then
    return false
  end
  return 1 == self.config.online_hidden_forbid_options
end

function NpcOption:IsDisableByOnlineModePetAction()
  if self.config.online_process_pet and 0 ~= self.config.online_process_pet then
    return self:InternalIsDisableByOnlineMode(self.config.online_process_pet)
  else
    return self:InternalIsDisableByOnlineMode(self.config.online_process)
  end
end

function NpcOption:IsDisableByOnlineModeMagicAction()
  if self.config.online_process_magic and 0 ~= self.config.online_process_magic then
    return self:InternalIsDisableByOnlineMode(self.config.online_process_magic)
  else
    return self:InternalIsDisableByOnlineMode(self.config.online_process)
  end
end

function NpcOption:CheckIsOwnerAndPartner()
  if self.config.npc_interact_condition == Enum.InteractConditionType.INTERACT_COND_NPC_CREATOR_AND_TOGETHER then
    if self.owner:IsControlledByPlayer() then
      return true
    end
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not localPlayer then
      return false
    end
    if not localPlayer:IsInTogetherMove() then
      return false
    end
    local anotherPlayer = localPlayer:GetAnotherTogetherMovePlayer()
    if not anotherPlayer then
      return false
    end
    local creatorID = self.owner:GetCreatorID()
    if not creatorID then
      return false
    end
    local anotherPlayerUin = anotherPlayer.serverData and anotherPlayer.serverData.base and anotherPlayer.serverData.base.actor_id
    return anotherPlayerUin == creatorID
  end
  return true
end

function NpcOption:IsOptionEnable(strict)
  if not self.optionInfo.enabled then
    return false
  end
  if 0 == self.optionInfo.executable_times then
    return false
  end
  if self.disable_by_custom_condition then
    return false
  end
  if not self:CheckIsOwnerAndPartner() then
    return false
  end
  if self.optionInfo.whitelist_uins and 0 ~= #self.optionInfo.whitelist_uins then
    local CurUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    for _, uin in ipairs(self.optionInfo.whitelist_uins) do
      if uin == CurUin then
        return true
      end
    end
    return false
  end
  if self.optionInfo.blacklist_uins and 0 ~= #self.optionInfo.blacklist_uins then
    local CurUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    for _, uin in ipairs(self.optionInfo.blacklist_uins) do
      if uin == CurUin then
        return false
      end
    end
    return true
  end
  if strict then
    return not self:IsDisableByOnlineMode()
  else
    return not self:IsDisableByOnlineModeUI()
  end
end

function NpcOption:GetEnableCondition()
  local option_enable_condition = self.config.option_enable_condition
  if not option_enable_condition then
    return _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_NONE
  end
  return option_enable_condition
end

function NpcOption:UpdateCustomDisable()
  local EnableCondition = self:GetEnableCondition()
  if EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_TIME then
    local current_time = _G.NRCModeManager:DoCmd(_G.EnvSystemModuleCmd.GetCurrentTime)
    local times = string.split(self.config.option_enable_condition_param, ";")
    self.disable_by_custom_condition = not TimeUtils.IsTimeBetween(current_time, TimeUtils.ParseTimeSpan(times[1]), TimeUtils.ParseTimeSpan(times[2]))
  elseif EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_WEATHER and self.config.option_enable_condition_param then
    local current_weather = _G.NRCModeManager:DoCmd(_G.EnvSystemModuleCmd.GetCurrentWeatherType)
    local all_enable_weather_type = string.split(self.config.option_enable_condition_param, ";")
    local enableOption = false
    for idx, weatherType in ipairs(all_enable_weather_type) do
      if current_weather == tonumber(weatherType) then
        enableOption = true
        break
      end
    end
    self.disable_by_custom_condition = not enableOption
    Log.Debug("NpcOption:UpdateCustomDisable ENABLE_CONDITION_WEATHER ", current_weather, self.config.option_enable_condition_param)
  elseif EnableCondition == _G.Enum.OptionVisibleCondition.DISABLE_CONDITION_WEATHER and self.config.option_enable_condition_param then
    local current_weather = _G.NRCModeManager:DoCmd(_G.EnvSystemModuleCmd.GetCurrentWeatherType)
    local all_disable_weather_type = string.split(self.config.option_enable_condition_param, ";")
    local disableOption = false
    for idx, weatherType in ipairs(all_disable_weather_type) do
      if current_weather == tonumber(weatherType) then
        disableOption = true
        break
      end
    end
    self.disable_by_custom_condition = disableOption
    Log.Debug("NpcOption:UpdateCustomDisable DISABLE_CONDITION_WEATHER ", current_weather, self.config.option_enable_condition_param)
  elseif EnableCondition == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_OPTION_TYPE then
    if not _G.HomeIndoorSandbox then
      return
    end
    if self.config.npc_interact_type == _G.Enum.InteractType.IT_HOME_PET_FEED then
      if _G.HomeIndoorSandbox:InOtherHomeIndoor() then
        self.disable_by_custom_condition = true
      end
      return
    end
    if self.config.npc_interact_type == _G.Enum.InteractType.IT_HOME_PET_STEAL then
      if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor() then
        if self.owner.serverData and self.owner.serverData.home_pet then
          local ownerPetGid = self.owner.serverData.home_pet.home_pet_info.pet_gid
          if ownerPetGid and HomeUtils.IsPetHasBeenSteal(ownerPetGid) then
            self.disable_by_custom_condition = true
          else
            self.disable_by_custom_condition = false
          end
        end
      else
        self.disable_by_custom_condition = true
      end
      return
    end
    if self.config.npc_interact_type == _G.Enum.InteractType.IT_HOME_PET_REWARD then
      if _G.HomeIndoorSandbox:InLocalMasterIndoor() then
        self.disable_by_custom_condition = false
      else
        self.disable_by_custom_condition = true
      end
    end
    local actionType = self:GetActionType()
    if table.contains(ActionsNotShowForHomeVisit, actionType) and _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor() then
      self.disable_by_custom_condition = true
    end
  end
end

function NpcOption:OnConditionChange()
  local old_enable = self:IsOptionEnable()
  self:UpdateCustomDisable()
  local new_enable = self:IsOptionEnable()
  if old_enable ~= new_enable then
    if not new_enable then
      self:OnPlayerLeaveActionArea()
    end
    self.owner.InteractionComponent:OnOptionEnableChange(self, old_enable, new_enable)
  end
end

function NpcOption:UpdateData(info, isReconnect)
  Log.Debug("NpcOption:UpdateData")
  self:SetNeedStatusNotify(false)
  self.isWaitingForRsp = false
  self.inActionArea = false
  if self.DetectArea and self.DetectArea.ResetPlayerInArea then
    self.DetectArea:ResetPlayerInArea()
  end
  self:UpdateCurrentAction(info.cur_action_info, isReconnect)
  PreprocessOptionInfo(info)
  self.optionInfo = info
  if self.optionInfo.cur_action_info then
    self.optionInfo.select_infos = self.optionInfo.cur_action_info.select_infos
  end
  if self.owner.luaObj and self.owner.luaObj.UpdateActStatus then
    self.owner.luaObj:UpdateActStatus(self.optionInfo)
  end
  if not self:IsOptionEnable() or isReconnect then
    Log.Debug("NpcOption:UpdateData\229\175\188\232\135\180actionleave", isReconnect, self:IsOptionEnable(), self.config.id)
    self:OnPlayerLeaveActionArea()
  end
end

function NpcOption:CanInteractSameTime()
  return (self.config.online_process_same_time or 0) == _G.Enum.OnlineVisitProcessCoop.OVPC_PROCESS_MULTY
end

function NpcOption:OnOptionChange(action, Tag, BaseData)
  Log.DebugFormat("optionstatechange;%d;%s", self.config.id, action.enabled and "open" or "close")
  self:SetNeedStatusNotify(false)
  local OldTimes = self.executeTimes
  self.optionInfo.enabled = action.enabled or false
  self.optionInfo.executable_times = action.executable_times or -1
  self.optionInfo.succ_exec_times = action.succ_exec_times or 0
  self.optionInfo.first_dialog_id = action.first_dialog_id or 0
  self.executeTimes = action.succ_exec_times or 0
  if 0 == OldTimes and self.executeTimes >= 1 then
    self:ClearDistanceCache()
  end
  if not self:IsOptionEnable() then
    Log.Debug("NpcOption:option change\229\175\188\232\135\180actionleave")
    self:OnPlayerLeaveActionArea()
  end
  if action.act_info then
    self.optionInfo.select_infos = action.act_info.select_infos
    self:UpdateCurrentAction(action.act_info, false, action.ineteracting_avatar_id)
    self:NotifyBeginActionParams(action.act_info, Tag, BaseData)
  end
  if self.owner.luaObj and self.owner.luaObj.UpdateActStatus then
    self.owner.luaObj:UpdateActStatus(self.optionInfo, Tag, BaseData)
  end
  local HeadComp = self.owner:GetHeadLookAtComponent()
  local CanRotate = self.owner.CanRotation and self.owner:CanRotation()
  local CanInteractSameTime = self.CanInteractSameTime and self:CanInteractSameTime()
  local ownerIsBoss = self.owner.config.genre == Enum.ClientNpcType.CNT_PETBOSS
  local npcActionConf = _G.DataConfigManager:GetNpcActionConf(self.config.action.action_type, true)
  local ActionCanRotate = true
  if npcActionConf then
    ActionCanRotate = not npcActionConf.disable_sync_rotate
  end
  if CanRotate and ActionCanRotate and not CanInteractSameTime and action.ineteracting_avatar_id and HeadComp and not ownerIsBoss then
    local localUin = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.ineteracting_avatar_id)
    local local_player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local another_player = local_player and local_player:GetAnotherTogetherMovePlayer()
    if action.ineteracting_avatar_id ~= localUin and (not (local_player:IsTogetherMove2P() and another_player) or another_player:GetServerId() ~= action.ineteracting_avatar_id) and player then
      DialogueUtils.StopTurn(self.owner)
      HeadComp:SetAutoLookAtParam(UE4.ELookAtParamType.Body, player.viewObj)
      HeadComp:ActiveAutoLookAt(true, nil, true)
      HeadComp:EnableManualOverride()
    end
  end
  self:SendEvent(NpcOptionEvent.OptionChange, self, action, BaseData)
end

function NpcOption:UpdateCurrentAction(NewAction, Reconnect, InteractingAvatarID)
  local OldAction = self.optionInfo.cur_action_info
  self.optionInfo.cur_action_info = NewAction
  if self.CurrentAction then
    self.CurrentAction:UpdateInfo(NewAction, Reconnect, InteractingAvatarID)
  end
  if self.CurrentPetAction then
    self.CurrentPetAction:UpdateInfo(NewAction)
  end
  if self.CurrentWildAction then
    self.CurrentWildAction:UpdateInfo(NewAction)
  end
  self:SendEvent(NpcOptionEvent.OptionActionChange, self, OldAction, NewAction, Reconnect)
end

function NpcOption:OnNpcDialogSelectInfoChange(action)
  local TargetInfo = action.select_info
  if not self.optionInfo.select_infos then
    self.optionInfo.select_infos = {}
  end
  for i, info in ipairs(self.optionInfo.select_infos) do
    if info.select_id == TargetInfo.select_id then
      self.optionInfo.select_infos[i] = TargetInfo
      break
    end
  end
  self:SendEvent(NpcOptionEvent.DialogSelectChange, self, action)
end

function NpcOption:OnAddStoryFlags(action)
  Log.Debug("Story Flag Updated", action.actor_id, action.option_id)
  if not self.optionInfo.story_flags then
    self.optionInfo.story_flags = {}
  end
  for _, flag in ipairs(action.story_flags) do
    if not table.contains(self.optionInfo.story_flags, flag) then
      table.insert(self.optionInfo.story_flags, flag)
    end
  end
  self:SendEvent(NpcOptionEvent.AddStoryFlag, self, action)
end

function NpcOption:OnRemoveStoryFlags(action)
  Log.Debug("Story Flag Removed", action.actor_id, action.option_id)
  local LocalFlags = self.optionInfo.story_flags
  if not LocalFlags then
    LocalFlags = {}
    self.optionInfo.story_flags = LocalFlags
  end
  for _, flag in ipairs(action.story_flags) do
    for i = #LocalFlags, 1, -1 do
      if LocalFlags[i] == flag then
        table.remove(LocalFlags, i)
        break
      end
    end
  end
  self:SendEvent(NpcOptionEvent.RemoveStoryFlag, self, action)
end

function NpcOption:OnAddSelectAction(action)
  Log.Debug("Npc Option Select Added", action.actor_id, action.option_id)
  local ServerSelects = action.select_infos
  local LocalSelects = self.optionInfo.select_infos
  if not LocalSelects then
    LocalSelects = {}
    self.optionInfo.select_infos = LocalSelects
  end
  for i, s in ipairs(ServerSelects) do
    local Found = false
    for j, l in ipairs(LocalSelects) do
      if s.select_id == l.select_id then
        LocalSelects[j] = s
        Found = true
        Log.DebugFormat("Select %d Updated(%d)", s.select_id, s.dialog_id)
        break
      end
    end
    if not Found then
      Log.DebugFormat("Select %d Added(%d)", s.select_id, s.dialog_id)
      table.insert(LocalSelects, s)
    end
  end
  self:SendEvent(NpcOptionEvent.AddSelect, self, action)
end

function NpcOption:OnRemoveSelectAction(action)
  Log.Debug("Npc Option Select Removed", action.actor_id, action.option_id)
  local ServerSelects = action.select_ids
  local LocalSelects = self.optionInfo.select_infos
  if not LocalSelects then
    LocalSelects = {}
    self.optionInfo.select_infos = LocalSelects
  end
  for _, s in ipairs(ServerSelects) do
    for j = #LocalSelects, 1, -1 do
      if LocalSelects[j].select_id == s then
        Log.DebugFormat("Select %d removed", s)
        table.remove(LocalSelects, j)
        break
      end
    end
  end
  self:SendEvent(NpcOptionEvent.RemoveSelect, self, action)
end

function NpcOption:OnOptionStay()
  local InteractType = self:GetInteractType()
  if InteractType == Enum.InteractType.IT_HOME_GRID then
    if not self:InHomeFurnitureGrid() then
      self:OnOptionLeave()
    end
  elseif InteractType == Enum.InteractType.IT_SCENE_SIT and not self:CanSitSceneSeat() then
    self:OnOptionLeave()
  end
end

function NpcOption:OnOptionEnter(BehaviorID)
  local Module = self.owner.module
  if not Module then
    return self:OnOptionLeave()
  end
  local InteractType = self:GetInteractType()
  if self:IsAuto() then
    if not self:NeedStatusNotify() then
      self.inActionArea = true
      self:OnOptionAction()
    end
  elseif InteractType == Enum.InteractType.IT_SCENE_SIT then
    if self:CanSitSceneSeat() then
      self.inActionArea = true
      self:OnPlayerEnterActionArea()
    end
  elseif self:IsManual() then
    self.inActionArea = true
    self:OnPlayerEnterActionArea()
  elseif InteractType == Enum.InteractType.IT_EMOTE then
    local RolePlayerBehaviorID = BehaviorID or Module:GetRolePlayBehaviorID()
    local optionId = self.optionInfo.option_id
    local cache = EmoteParamCacheDict[optionId]
    if not cache then
      cache = {}
      if self.config.interact_param1 then
        local paramArray = string.split(tostring(self.config.interact_param1), ";")
        for _, idStr in ipairs(paramArray) do
          local id = tonumber(idStr)
          if id then
            cache[id] = true
          end
        end
      end
      EmoteParamCacheDict[optionId] = cache
    end
    if cache[RolePlayerBehaviorID] then
      self.inActionArea = true
      self:OnOptionAction()
    end
  elseif InteractType == Enum.InteractType.IT_STAY and self.config.interact_param1 then
    self.inActionArea = true
    if self._StayToFireId then
      _G.DelayManager:CancelDelayById(self._StayToFireId)
      self._StayToFireId = nil
    end
    self._StayToFireId = _G.DelayManager:DelaySeconds(tonumber(self.config.interact_param1) / 1000, self.OnOptionAction, self)
  end
  return self.inActionArea
end

function NpcOption:OnOptionLeave()
  self:OnPlayerLeaveActionArea()
  if self._StayToFireId then
    _G.DelayManager:CancelDelayById(self._StayToFireId)
    self._StayToFireId = nil
  end
  self.inActionArea = false
  return self.inActionArea
end

function NpcOption:OnPlayerEnterActionArea()
  Log.Debug("NpcOption:OnPlayerEnterActionArea", self.config and self.config.id or "\230\178\161\230\156\137ID", self:ShouldShowOnUI(), self:IsOptionEnable(), self.owner.canTriggerInteraction, self.owner:DebugNPCNameAndID())
  if self:ShouldShowOnUI() and self:IsOptionEnable() and self.owner.canTriggerInteraction then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.AddNPCInteract, self)
    self.bInteractUIAdded = true
  end
end

function NpcOption:OnPlayerLeaveActionArea()
  Log.Debug("NpcOption:OnPlayerLeaveActionArea", self.config and self.config.id or "\230\178\161\230\156\137ID", self.owner:DebugNPCNameAndID())
  if self.CurrentAction then
    self.CurrentAction:OnPlayerLeaveActionArea()
  end
  if self.bInteractUIAdded then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.RemoveNPCInteract, self)
    self.bInteractUIAdded = false
  end
end

function NpcOption:NeedStatusNotify()
  if SceneUtils.debugForceNpcOptionInvalid then
    return false
  end
  return needStatusNotify
end

function NpcOption:SetNeedStatusNotify(need)
  if need ~= needStatusNotify then
    Log.Debug("NpcOption:SetNeedStatusNotify", need)
  end
  needStatusNotify = need
end

function NpcOption:OnOptionAction()
  if not self.owner then
    Log.Error("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] Option\231\154\132Owner\229\183\178\231\187\143\228\184\141\229\173\152\229\156\168\228\186\134\227\128\130\229\129\156\230\173\162\228\186\164\228\186\146", self.config and self.config.id)
    return
  end
  if self.owner.isDestroy then
    Log.Error("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] Option\231\154\132Owner\229\135\134\229\164\135\232\166\129\232\162\171\229\136\160\233\153\164\228\186\134\239\188\140\228\184\141\229\133\129\232\174\184\229\188\128\229\167\139\230\150\176\231\154\132\228\186\164\228\186\146", self.config and self.config.id)
    return
  end
  if not _G.DataModelMgr.PlayerDataModel:HasPet() then
    local ActionType = self.config.action and self.config.action.action_type
    if ActionType and table.contains(NoPetForbidActions, ActionType) then
      Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] \230\178\161\230\156\137\231\178\190\231\129\181\239\188\140Option\231\166\129\230\173\162\230\137\167\232\161\140", self.config and self.config.id)
      return
    end
  end
  if self:IsFarmOption() then
    local optionType = FarmUtils.GetFarmOptionType(self)
    if optionType == FarmModuleEnum.OptionType.Sowing and not FarmUtils.PreCheckFarmNPCOption(optionType) then
      Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] FarmOption\232\162\171\230\139\146\231\187\157\230\137\167\232\161\140", self.config and self.config.id)
      return
    end
  end
  if not self.config.excute_delay or 0 == self.config.excute_delay then
    self:Inter_OnNpcAction()
  else
    if self.DelayActionHandler > 0 then
      _G.DelayManager:CancelDelayById(self.DelayActionHandler)
      self.DelayActionHandler = -1
    end
    self.DelayActionHandler = _G.DelayManager:DelaySeconds(1.0 * self.config.excute_delay / 1000, self.Inter_OnNpcAction, self)
  end
end

function NpcOption:Inter_OnNpcAction()
  self:EnsureAction()
  if self.CurrentAction then
    if self.owner.Watch then
      Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] will call OnNpcAction", self.config and self.config.id)
    end
    if not self.CurrentAction:OnNpcAction() then
      self.inActionArea = false
      Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] Action\232\167\137\229\190\151\232\135\170\229\183\177\228\184\141\232\131\189\230\137\167\232\161\140", self.config and self.config.id)
      return
    end
  end
  if self.CurrentPetAction and self.CurrentPetAction:IsExecuting() then
    self.inActionArea = false
    Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] \230\173\163\229\156\168\230\137\167\232\161\140PetAction\239\188\140\228\184\141\232\131\189\229\129\154\230\153\174\233\128\154\228\186\164\228\186\146", self.config and self.config.id)
    return
  end
  if not self.CurrentAction.SkipSubmit then
    if self:NeedStatusNotify() and not SceneUtils.debugForceNpcOptionInvalid then
      Log.Warning("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] NpcOption:Inter_OnNpcAction \233\156\128\232\166\129\231\173\137\229\190\133\228\184\138\230\172\161\228\186\164\228\186\146\229\141\143\232\174\174\230\156\141\229\138\161\229\153\168\229\155\158\229\140\133", self.config and self.config.id)
      return
    end
  else
    Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] NpcOption:Inter_OnNpcAction \228\184\141\233\156\128\232\166\129\230\143\144\228\186\164\230\156\141\229\138\161\229\153\168", self.config and self.config.id)
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_INTERACTING) and (self.config.online_process_same_time or 0) == _G.Enum.OnlineVisitProcessCoop.OVPC_PROCESS_SOLE then
    if self.config.npc_interact_type ~= _G.Enum.InteractType.IT_AUTO then
      local showTip = _G.LuaText.Error_Code_50135
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, showTip)
    end
    return
  end
  if self:IsDisableByOnlineMode() then
    if self.config.npc_interact_type == _G.Enum.InteractType.IT_AUTO then
      if self.config.id == 19000001 then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.transform_fanying_fail)
      end
      return
    end
    local showTip = ""
    if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      showTip = _G.LuaText.Error_Code_2161
    else
      showTip = _G.LuaText.Error_Code_2162
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, showTip)
    return
  end
  self:SetNeedStatusNotify(self.CurrentAction:IfActionNeedStatusNotify())
  self:PreInteract()
end

function NpcOption:PreInteract()
  Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] NpcOption:PreInteract", self.config and self.config.id)
  if self:IsActionValid() then
    local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local NavComp = localPlayer:EnsureComponent(NavigationComponent)
    local FixDistance = self.config.fix_distance
    if 1 == self.config.enablefix_distance or 3 == self.config.enablefix_distance then
      FixDistance = self.config.fix_distance
    elseif 2 == self.config.enablefix_distance or 5 == self.config.enablefix_distance then
      FixDistance = -1
    elseif 4 == self.config.enablefix_distance then
      local IsFacePlay = self.owner:IsFacePlay(localPlayer.serverData.base.actor_id)
      local HasStarItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100701)
      if HasStarItem and not IsFacePlay then
        FixDistance = -1
      end
    end
    if self.config.break_holdhands then
      localPlayer:StopLink()
    end
    self:RecordRideStateBeforeInteract(localPlayer)
    if self.CurrentAction and self.CurrentAction.IsRideBeforeBattle then
      NavComp:StartNavigate(Enum.UnmountType.UT_NO, self.config.enablefix_distance, FixDistance, self.config.fix_rotation, self.owner, self, self.OnNavResult)
    else
      NavComp:StartNavigate(self.config.unmount_type, self.config.enablefix_distance, FixDistance, self.config.fix_rotation, self.owner, self, self.OnNavResult)
    end
  else
    local BagItemId = self.config.npc_interact_condition_param[1]
    local BagItemConf = DataConfigManager:GetBagItemConf(BagItemId)
    local showTip = string.format(LuaText.hint_not_enough_items, BagItemConf.name)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, showTip)
    if self.CurrentAction then
      self.CurrentAction:RestIsSelectBtnBySubmitError(self.CurrentAction.Config.action_type)
    end
    self:SetNeedStatusNotify(false)
  end
end

function NpcOption:RecordRideStateBeforeInteract(localPlayer)
  self.ridePetGidBeforeInteract = 0
  self.needRestoreRide = false
  if not self.config.unmount_type or self.config.unmount_type == Enum.UnmountType.UT_NO then
    return
  end
  if self.CurrentAction and self.CurrentAction.IsRideBeforeBattle then
    return
  end
  if not localPlayer.viewObj or not UE.UObject.IsValid(localPlayer.viewObj) then
    return
  end
  local rideComponent = localPlayer.viewObj.BP_RideComponent
  if not rideComponent then
    return
  end
  local ridePet = rideComponent.RidePet
  local scenePet = rideComponent.ScenePet
  if ridePet and scenePet and localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    if localPlayer:IsInTogetherMove() then
      Log.Debug("NpcOption:RecordRideStateBeforeInteract \231\142\169\229\174\182\229\164\132\228\186\142\229\143\140\228\186\186\233\170\145\228\185\152\231\138\182\230\128\129\239\188\140\228\184\141\232\174\176\229\189\149\233\170\145\228\185\152\231\138\182\230\128\129")
      return
    end
    local petGid = scenePet.gid or 0
    if petGid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Wild or petGid == -ProtoEnum.SceneRideAllCustomGid.SRCG_MiniGame then
      Log.Debug("NpcOption:RecordRideStateBeforeInteract \228\184\180\230\151\182\233\170\145\228\185\152\228\184\141\232\174\176\229\189\149")
      return
    end
    if petGid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Friend then
      Log.Debug("NpcOption:RecordRideStateBeforeInteract \229\165\189\229\143\139\231\178\190\231\129\181\233\170\145\228\185\152\228\184\141\232\174\176\229\189\149")
      return
    end
    self.ridePetGidBeforeInteract = petGid
    self.needRestoreRide = true
    Log.Debug(string.format("NpcOption:RecordRideStateBeforeInteract \232\174\176\229\189\149\233\170\145\228\185\152\231\138\182\230\128\129, PetGID=%d", self.ridePetGidBeforeInteract))
  end
end

function NpcOption:RestoreRideStateAfterInteract()
  if not self.needRestoreRide or self.ridePetGidBeforeInteract <= 0 then
    return
  end
  Log.Debug(string.format("NpcOption:RestoreRideStateAfterInteract \229\176\157\232\175\149\230\129\162\229\164\141\233\170\145\228\185\152, PetGID=%d", self.ridePetGidBeforeInteract))
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not (localPlayer and localPlayer.viewObj) or not UE.UObject.IsValid(localPlayer.viewObj) then
    Log.Warning("NpcOption:RestoreRideStateAfterInteract \230\156\172\229\156\176\231\142\169\229\174\182\228\184\141\229\173\152\229\156\168\239\188\140\230\151\160\230\179\149\230\129\162\229\164\141\233\170\145\228\185\152")
    self:ClearRideRestoreState()
    return
  end
  if localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    Log.Debug("NpcOption:RestoreRideStateAfterInteract \231\142\169\229\174\182\229\183\178\231\187\143\229\156\168\233\170\145\228\185\152\228\184\173\239\188\140\228\184\141\233\156\128\232\166\129\230\129\162\229\164\141")
    self:ClearRideRestoreState()
    return
  end
  if localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    Log.Debug("NpcOption:RestoreRideStateAfterInteract \231\142\169\229\174\182\229\143\152\229\189\162\228\184\173\239\188\140\228\184\141\233\156\128\232\166\129\230\129\162\229\164\141")
    self:ClearRideRestoreState()
    return
  end
  if localPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN) then
    Log.Debug("NpcOption:RestoreRideStateAfterInteract \231\142\169\229\174\182\229\157\144\228\184\139\228\184\173\239\188\140\228\184\141\233\156\128\232\166\129\230\129\162\229\164\141")
    self:ClearRideRestoreState()
    return
  end
  local savedPetGid = self.ridePetGidBeforeInteract
  self:ClearRideRestoreState()
  self.RestoreRideTimer = _G.DelayManager:DelayFrames(3, function()
    self.RestoreRideTimer = nil
    if not localPlayer or not UE.UObject.IsValid(localPlayer.viewObj) then
      Log.Warning("NpcOption:RestoreRideStateAfterInteract \229\187\182\232\191\159\230\129\162\229\164\141\230\151\182\231\142\169\229\174\182\229\175\185\232\177\161\229\183\178\229\164\177\230\149\136")
      return
    end
    if localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      Log.Debug("NpcOption:RestoreRideStateAfterInteract \229\187\182\232\191\159\230\129\162\229\164\141\230\151\182\229\143\145\231\142\176\229\183\178\229\156\168\233\170\145\228\185\152\228\184\173\239\188\140\232\183\179\232\191\135")
      return
    end
    local scenePet = localPlayer:GetPetByGid(savedPetGid)
    if not scenePet then
      Log.Warning(string.format("NpcOption:RestoreRideStateAfterInteract \230\137\190\228\184\141\229\136\176\229\174\160\231\137\169\229\175\185\232\177\161, PetGID=%d", savedPetGid))
      return
    end
    local rideHelper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL)
    if rideHelper then
      rideHelper:HandleStatus(localPlayer, scenePet)
      Log.Debug(string.format("NpcOption:RestoreRideStateAfterInteract \229\183\178\229\187\182\232\191\159\230\129\162\229\164\141\233\170\145\228\185\152, PetGID=%d", savedPetGid))
    else
      Log.Error("NpcOption:RestoreRideStateAfterInteract \230\151\160\230\179\149\232\142\183\229\143\150\233\170\145\228\185\152Helper")
    end
  end)
end

function NpcOption:ClearRideRestoreTimer()
  if self.RestoreRideTimer then
    _G.DelayManager:CancelDelayById(self.RestoreRideTimer)
    self.RestoreRideTimer = nil
  end
end

function NpcOption:ClearRideRestoreState()
  self:ClearRideRestoreTimer()
  self.ridePetGidBeforeInteract = 0
  self.needRestoreRide = false
end

function NpcOption:OnNavResult(Success)
  if SceneUtils.debugForceNpcOptionInvalid then
    Success = false
  end
  if 4 == self.config.enablefix_distance then
    if not Success then
      self:BoxInteractFailed()
    end
    self:Execute()
    return
  end
  if not Success then
    Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] \229\175\187\232\183\175\229\164\177\232\180\165", self.config and self.config.id)
    self:SetNeedStatusNotify(false)
    return
  end
  if self.CurrentPetAction and self.CurrentPetAction:IsExecuting() then
    Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] PetAction\230\173\163\229\156\168\230\137\167\232\161\140\228\184\173", self.config and self.config.id)
    self:SetNeedStatusNotify(false)
    return
  end
  self:Execute()
end

function NpcOption:LockPlayerAndBattle()
  Log.Debug("NpcOption:LockPlayerAndBattle")
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer:StopDash()
  local NavComp = localPlayer:EnsureComponent(NavigationComponent)
  NavComp:LockPlayerAndBattle()
  localPlayer:Stop()
  local View = localPlayer.viewObj
  if View then
    View.CharacterMovement:ConsumeInputVector()
    View.CharacterMovement:ConsumeInputVector()
    View.CharacterMovement.Acceleration = UE4.FVector(0, 0, 0)
    localPlayer.movementComponent:SetSyncMove(false)
    View.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    localPlayer:SetCharacterMovementTickEnable(self, false)
  end
end

function NpcOption:UnLockPlayerAndBattle()
  Log.Debug("NpcOption:UnLockPlayerAndBattle")
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local NavComp = localPlayer:EnsureComponent(NavigationComponent)
  NavComp:UnLockPlayerAndBattle()
  local View = localPlayer.viewObj
  if View then
    View.CharacterMovement:ConsumeInputVector()
    View.CharacterMovement:ConsumeInputVector()
    View.CharacterMovement.Acceleration = UE4.FVector(0, 0, 0)
    View.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    localPlayer.movementComponent:SetSyncMove(true)
    localPlayer:SetCharacterMovementTickEnable(self, true)
  end
end

function NpcOption:Execute()
  Log.Debug("[NPC\228\186\164\228\186\146\230\137\167\232\161\140\230\151\165\229\191\151] NpcOption:Execute", self.config and self.config.id, self.isWaitingForRsp)
  if self.isWaitingForRsp then
    return
  end
  local BubbleComp = self.owner.BubbleComponent
  if BubbleComp then
    BubbleComp:Stop(BubbleType.Special)
  end
  if self.CurrentAction then
    local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if self.CurrentAction.shouldSync then
      self.CurrentAction:SyncAction()
    end
    self.CurrentAction:Execute(localPlayer.serverData and localPlayer.serverData.base.actor_id or 0, true)
  end
end

function NpcOption:GetValidationAmount()
  if not self.config.npc_interact_condition_param then
    Log.Error("\229\144\175\231\148\168\228\186\134\230\160\161\233\170\140\229\141\180\230\178\161\230\156\137\233\133\141\231\189\174\229\143\130\230\149\176")
    return 0
  end
  if #self.config.npc_interact_condition_param <= 1 then
    return 0
  end
  local Index = math.clamp(#self.config.npc_interact_condition_param - self.optionInfo.executable_times + 1, 2, #self.config.npc_interact_condition_param)
  return self.config.npc_interact_condition_param[Index]
end

function NpcOption:NeedsValidation()
  if self.config.npc_interact_condition == Enum.InteractConditionType.INTERACT_COND_COMMON_DEMANDS then
    return true
  else
    return false
  end
end

function NpcOption:IsFarmOption()
  if self.owner.serverData and self.owner.serverData.npc_base and self.owner.serverData.npc_base.home_plant_land_id and 0 ~= self.owner.serverData.npc_base.home_plant_land_id then
    return true
  else
    return false
  end
end

function NpcOption:IsActionValid()
  local Bar = self:GetValidationAmount()
  if Bar > 0 then
    local BagItemId = self.config.npc_interact_condition_param[1]
    local itemData = NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, BagItemId)
    if itemData and Bar <= itemData.num then
      self.Validated = true
    else
      self.Validated = false
    end
  else
    self.Validated = true
  end
  return self.Validated
end

function NpcOption:GetPriority()
  return self.config.option_priority
end

function NpcOption:GetThrowTargetNpcInfo()
  local info = _G.ProtoMessage:newThrowTargetNpcInfo()
  info.npc_id = self.owner.serverData.base.actor_id
  info.npc_conf_id = self.owner.config.id
  info.option_id = self.optionInfo.option_id
  return info
end

function NpcOption:GetActionType()
  return self.config.action.action_type
end

function NpcOption:GetValidationInfo()
  return self:IsActionValid(), self:GetValidationAmount(), self.config.npc_interact_condition_param[1]
end

function NpcOption:GetPetActionType()
  return self.config.pet_action.action_type
end

function NpcOption:IsBattleAction()
  local action_type = self:GetActionType() or _G.Enum.ActionType.ACT_NONE
  if action_type == _G.Enum.ActionType.ACT_BATTLE then
    return true
  end
  local pet_action_type = self:GetPetActionType() or _G.Enum.ActionType.ACT_NONE
  if pet_action_type == _G.Enum.ActionType.ACT_BATTLE then
    return true
  end
  return false
end

function NpcOption:GetCompassConf()
  if not self.CompassConf then
    self.CompassConf = _G.DataConfigManager:GetNpcCompassOption(self.config.id)
  end
  return self.CompassConf
end

local ExtraDistConf = _G.DataConfigManager:GetNpcGlobalConfig("auto_cal_option_distance")
local ExtraDist = ExtraDistConf and ExtraDistConf.num or 50

function NpcOption:GetSquaredDistance()
  if self.optionDistanceSquared >= 0 then
    return self.optionDistanceSquared, self.OptionDistance
  end
  local Dist = 0
  local Type = self:GetInteractType()
  local FirstTimeAuto = Type == Enum.InteractType.IT_AUTOMANUAL and self:IsAuto()
  if FirstTimeAuto then
    Dist = tonumber(self.config.interact_param1) or 0
  end
  if 0 == Dist then
    Dist = self.config.option_radius
  end
  if Dist > 0 then
    self.OptionDistance = Dist
    self.optionDistanceSquared = Dist * Dist
    return self.optionDistanceSquared, self.OptionDistance
  end
  local Owner = self.owner
  local OwnerView = Owner and Owner.viewObj
  if not OwnerView or not UE.UObject.IsValid(OwnerView) then
    return 1, 1
  end
  local Root = OwnerView:K2_GetRootComponent()
  if not Root or not UE.UObject.IsValid(Root) then
    return 1, 1
  end
  if not Root:IsA(UE.UCapsuleComponent) then
    self.OptionDistance = Dist
    self.optionDistanceSquared = Dist * Dist
    return self.optionDistanceSquared, self.OptionDistance
  end
  local Radius = Root:GetScaledCapsuleRadius()
  Radius = Radius + ExtraDist
  self.OptionDistance = Radius
  self.optionDistanceSquared = Radius * Radius
  return self.optionDistanceSquared, self.OptionDistance
end

function NpcOption:ClearDistanceCache()
  self.optionDistanceSquared = -1
  self.OptionDistance = -1
end

function NpcOption:GetSquaredLeaveDistance()
  if self.OptionDistanceLeaveSquared >= 0 then
    return self.OptionDistanceLeaveSquared, self.OptionDistance
  end
  local Dist = self.config.cancel_option_radius
  if Dist > 0 then
    self.OptionDistanceLeaveSquared = Dist * Dist
    self.OptionDistance = Dist
    return self.OptionDistanceLeaveSquared, self.OptionDistance
  end
  self.OptionDistanceLeaveSquared, self.OptionDistance = self:GetSquaredDistance()
  return self.OptionDistanceLeaveSquared, self.OptionDistance
end

function NpcOption:BoxInteractFailed()
  local LocalPlayer = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Capsule = LocalPlayer.viewObj:K2_GetRootComponent()
  local Config = self.config
  local ProjectPos = self.owner.viewObj:GetInterPos(LocalPlayer:GetActorLocation(), Config.enablefix_distance, Config.fix_distance, Config.fix_rotation, Capsule:GetScaledCapsuleRadius())
  local IsFacePlay = self.owner:IsFacePlay(LocalPlayer.serverData.base.actor_id)
  local HasStarItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100701)
  print("+amonsu=======PreBoxInteract=====", HasStarItem, IsFacePlay)
  if not HasStarItem or HasStarItem and IsFacePlay then
    self:TeleportLocalPlayerForBox(ProjectPos)
  end
end

function NpcOption:TeleportLocalPlayerForBox(ProjectPos)
  local LocalPlayer = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Exclude = {}
  local Players = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  if Players then
    for _, Player in pairs(Players) do
      if Player.viewObj then
        table.insert(Exclude, Player.viewObj)
      end
    end
  end
  if LocalPlayer and UE.UObject.IsValid(LocalPlayer.viewObj) then
    local bLanded = LocalPlayer.viewObj.CharacterMovement:Abs_Land(ProjectPos)
    if bLanded then
      local LandPos = LocalPlayer:GetActorLocation()
      if SceneUtils.debugInterNavTargetPoint then
        UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), LandPos, 20, 4, UE4.FLinearColor(0, 1, 0, 1), 50, 2)
      end
      local PlayerController = LocalPlayer:GetUEController()
      PlayerController:ReleaseRocoCamera()
    end
  end
end

function NpcOption:NotifyBeginActionParams(Action, Tag, BaseData)
  if self.CachedBeginActions == DummyTable then
    self.CachedBeginActions = {}
  end
  self.CachedBeginActions[Action.act_type] = Action
  self:SendEvent(NpcOptionEvent.NotifyBeginActionParams, self, Action)
end

function NpcOption:GetBeginActionParams(ActionType)
  return self.CachedBeginActions[ActionType]
end

function NpcOption:RemoveBeginActionParams(ActionType)
  self.CachedBeginActions[ActionType] = nil
end

function NpcOption:SendPowerDashReq(Skill, DashCaster)
  if self.RunningDashAction then
    Log.Error("\233\135\141\229\164\141\230\137\167\232\161\140")
    return
  end
  local ActionInstance = PowerDashActionFactory:Get(self, self.config.pet_power_dash_action)
  if not ActionInstance then
    return nil
  end
  self.RunningDashAction = ActionInstance
  ActionInstance:Execute(Skill, DashCaster)
  ActionInstance:AddEventListener(self, PowerDashActionEvent.OnFinish, self.OnPowerDashActionFinish)
  return ActionInstance
end

function NpcOption:OnPowerDashActionFinish(Action, Success)
  if self.RunningDashAction == Action then
    self.RunningDashAction:RemoveEventListener(self, PowerDashActionEvent.OnFinish, self.OnPowerDashActionFinish)
    self.RunningDashAction = nil
  end
end

function NpcOption:SendPowerDashInfoSync(DashPlayer, DashCaster)
  if not UE.UObject.IsValid(DashCaster) then
    return
  end
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  req.operation.operator_type = 2
  req.operation.operator_id = DashPlayer:GetServerId()
  req.operation.npc_action_info.action_status = NPCModuleEnum.ActionStatus.Begin
  req.operation.npc_action_info.operation_target_id = self.owner:GetServerId()
  req.operation.npc_action_info.option_id = self.config.id
  local Position = DashCaster:Abs_K2_GetActorLocation()
  req.operation.npc_action_info.operator_location.pos.x = math.floor(Position.X)
  req.operation.npc_action_info.operator_location.pos.y = math.floor(Position.Y)
  req.operation.npc_action_info.operator_location.pos.z = math.floor(Position.Z)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
end

function NpcOption:HasAutoCollected()
  return self.bAutoCollected
end

function NpcOption:SendAutoCollectReq(Player)
  Log.DebugFormat("Try Auto Collect %s", self.owner and self.owner:DebugNPCNameAndID() or "\230\156\170\231\159\165Owner")
  self:SetNeedStatusNotify(true)
  self.bAutoCollected = true
  local req = _G.ProtoMessage:newZoneSceneNpcNextActReq()
  req.option_id = self.config.id
  req.npc_id = self.owner:GetServerId()
  req.first_act = true
  req.battle_radius = _G.BattleConst.Define.BattleFieldRange
  req.npc_pt = self.owner:GetServerPoint()
  if Player then
    req.avatar_pt = Player:GetServerPoint()
    local PlayerView = Player.viewObj
    if PlayerView then
      local RideComp = PlayerView and PlayerView.BP_RideComponent
      local Pet = RideComp and RideComp.ScenePet
      if Pet then
        req.ride_id = Pet.gid
      end
    end
  end
  req.data1 = _G.BattleConst.Define.BattleFieldRange
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, req, self, self.OnAutoCollectCallback)
end

function NpcOption:OnAutoCollectCallback(rsp)
  self:SetNeedStatusNotify(false)
end

function NpcOption:GetOwnerId()
  local serverData = self.owner and self.owner.serverData
  local base = serverData and serverData.base
  local actor_id = base and base.actor_id
  return actor_id
end

function NpcOption:GetOwnerFarmlandInfo()
  local serverData = self.owner and self.owner.serverData
  local base = serverData and serverData.npc_base
  local land_id = base and base.home_plant_land_id
  if not land_id or 0 == land_id then
    return
  end
  local landInfo = FarmUtils.GetLandInfo(land_id)
  return landInfo
end

function NpcOption:IsInteractBanState(PlayerState)
  if PlayerState == Enum.LocationInteractionBanType.STA_BEGIN then
    return false
  end
  local NpcTag
  if not NpcTag then
    local LocationTag = self.config and self.config.LocationTag
    if LocationTag and 0 ~= LocationTag then
      NpcTag = LocationTag
    end
  end
  local serverData = self.owner and self.owner.serverData
  local NpcBase = serverData and serverData.npc_base
  if not NpcTag then
    local npc_content_cfg_id = NpcBase and NpcBase.npc_content_cfg_id
    if npc_content_cfg_id and 0 ~= npc_content_cfg_id then
      local RefreshContentConf = _G.DataConfigManager:GetNpcRefreshContentConf(npc_content_cfg_id)
      local LocationTag = RefreshContentConf and RefreshContentConf.LocationTag
      if LocationTag and 0 ~= LocationTag then
        NpcTag = LocationTag
      end
    end
  end
  if not NpcTag then
    local npc_cfg_id = NpcBase and NpcBase.npc_cfg_id
    if npc_cfg_id and 0 ~= npc_cfg_id then
      local NpcConf = _G.DataConfigManager:GetNpcConf(npc_cfg_id)
      local LocationTag = NpcConf and NpcConf.LocationTag
      if LocationTag and 0 ~= LocationTag then
        NpcTag = LocationTag
      end
    end
  end
  local InteractBanConf = _G.DataConfigManager:GetLocationInteractBan(NpcTag or Enum.LocationTag.LC_LAND)
  local locaion_interact_ban_list = InteractBanConf and InteractBanConf.locaion_interact_ban_list
  if locaion_interact_ban_list then
    local BanList = locaion_interact_ban_list[PlayerState + 1]
    if BanList then
      return BanList.location_interact_ban
    end
  end
  return false
end

function NpcOption:GetActionConf()
  return self.config.action
end

function NpcOption:EnsureAction()
  if not self.CurrentAction then
    self.CurrentAction = NPCActionFactory:Get(self, self.config.action, self.optionInfo.cur_action_info)
  end
  return self.CurrentAction
end

function NpcOption:GetPetActionConf()
  local ActionConf = self.config.pet_action
  if PetActionFactory:IsSupportedAction(ActionConf.action_type) then
    return ActionConf
  else
    return nil
  end
end

function NpcOption:EnsurePetAction()
  if not self.CurrentPetAction then
    self.CurrentPetAction = PetActionFactory:Get(self, true)
  end
  return self.CurrentPetAction
end

function NpcOption:GetWildActionConf()
  local ActionConf = self.config.wild_action
  if PetActionFactory:IsSupportedAction(ActionConf.action_type) then
    return ActionConf
  else
    return nil
  end
end

function NpcOption:EnsureWildAction()
  if not self.CurrentWildAction then
    self.CurrentWildAction = PetActionFactory:GetForWild(self, true)
  end
  return self.CurrentWildAction
end

function NpcOption:EnsureMagicActions()
  if self.CurrentMagicActions == DummyTable and self.config.magic_interact_id and 0 ~= self.config.magic_interact_id then
    local MagicInteractConf = _G.DataConfigManager:GetMagicInteractConf(self.config.magic_interact_id)
    for _, value in ipairs(MagicInteractConf.action_struct) do
      local MagicAction = MagicActionFactory:Get(self, value)
      if MagicAction then
        if self.CurrentMagicActions == DummyTable then
          self.CurrentMagicActions = {}
        end
        table.insert(self.CurrentMagicActions, MagicAction)
      else
        Log.Error("\229\174\162\230\136\183\231\171\175\229\144\140\229\173\166\229\176\154\230\156\170\229\174\158\231\142\176", table.getKeyName(Enum.ActionType, value.action_type), value.action_type)
      end
    end
  end
  return self.CurrentMagicActions
end

function NpcOption:CanSitSceneSeat()
  local Owner = self.owner
  local OwnerView = Owner and Owner.viewObj
  if not OwnerView or not UE.UObject.IsValid(OwnerView) then
    return false
  end
  local SeatSlot = self.config.action.action_param1
  if not self.SeatIdx then
    self.SeatIdx = tonumber(string.match(SeatSlot, "Seat_(%d+)"))
    if self.config.action.action_type == Enum.ActionType.ACT_SIT and (not OwnerView.StaticMesh or not OwnerView.StaticMesh:DoesSocketExist(SeatSlot)) then
      return false
    end
  end
  if not self.SeatIdx then
    return false
  end
  if not Owner.serverData then
    return false
  end
  if not Owner.serverData.npc_interact then
    return true
  end
  if not Owner.serverData.npc_interact.seat_info then
    return true
  end
  local SeatInfo = Owner.serverData.npc_interact.seat_info.seat_info
  if SeatInfo then
    for i, Info in ipairs(SeatInfo) do
      if Info.seat_idx + 1 == self.SeatIdx then
        if 0 ~= Info.interact_avatar_id then
          return false
        end
        break
      end
    end
  end
  return true
end

function NpcOption:InHomeFurnitureGrid()
  local Owner = self.owner
  local FurnitureID = Owner and Owner.FurnitureID
  if not FurnitureID then
    return
  end
  local FurnitureView = Owner.viewObj
  if not FurnitureView then
    return
  end
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local ExitIndex = HomeUtils.FindValidExitPosForSeat(Owner, FurnitureView)
  if not ExitIndex or -1 == ExitIndex then
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local PlayerPos = Player:GetActorLocation()
  if not HomeUtils.PlayerInInteractArea(PlayerPos, Owner) then
    return
  end
  if HomeUtils.CanSitDownOnSeat(PlayerPos, Owner, FurnitureView, AvailableData) then
    return true
  end
end

function NpcOption:CheckOptionIsBan(showBanMsg)
  local isBan = false
  local systemControlId = self.config and self.config.system_control_id
  if systemControlId and 0 ~= systemControlId then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, systemControlId, showBanMsg)
  end
  return isBan
end

function NpcOption:IsPetOption()
  return self.owner.IsPet and self.owner:IsPet()
end

function NpcOption:SetPetBondOptionActive(bActive)
  if self:IsPetBond() then
    self.owner:SetPetBondActive(bActive)
  end
end

function NpcOption:SetHomeOptionActive(bActive)
  if self:GetEnableCondition() == _G.Enum.OptionVisibleCondition.ENABLE_CONDITION_OPTION_TYPE then
    self.owner:SetHomeOptionActive(bActive)
  end
end

function NpcOption:IsHomeSound2dOption()
  return self:GetActionType() == _G.Enum.ActionType.ACT_FURNITURE_CHANGE_BGM
end

function NpcOption:IsHomeViewArtOption()
  return self:GetActionType() == _G.Enum.ActionType.ACT_VIEW_WALL_ART
end

return NpcOption
