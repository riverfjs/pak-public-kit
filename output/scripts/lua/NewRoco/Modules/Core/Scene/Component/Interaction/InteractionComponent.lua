local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local NpcOption = require("NewRoco.Modules.Core.NPC.Executors.NpcOption")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ActionUtils = require("NewRoco.Modules.Core.NPC.Actions.ActionUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local PetActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PetActionFactory")
local PowerDashActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PowerDashAction.PowerDashActionFactory")
local PetActionCommon = require("NewRoco.Modules.Core.NPC.Actions.PetActions.PetActionCommon")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local Enum = require("Data.Config.Enum")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local pairs = _ENV.pairs
local ipairs = _ENV.ipairs
local NORMAL_PET_ACTIONS = {
  [Enum.ActionType.ACT_PETCOLLOBJ_AWARD] = true,
  [Enum.ActionType.ACT_PETCOLLOBJ_BAGITEM] = true
}
local NPC_MARK_STATE = {
  UnInited = -1,
  Destroy = 0,
  Hide = 1,
  Show = 2
}
local EFailedReason = {
  Success = 0,
  DefaultFailed = 1,
  CanTriggerInteractionFailed = 2,
  PetCreatorFailed = 3
}
local petBondIconDistance
local InteractionComponent = Base:Extend("InteractionComponent")
InteractionComponent:SetMemberCount(16)

function InteractionComponent:PreCtor()
  Base.PreCtor(self)
  self.config = nil
  self._options = {}
  self._checkOptions = {}
  self._highestManualPriority = -1
  self.needStatusNotify = false
  self.isInOverlapArea = false
  self.Valid3DOptions = false
  self.ValidSenseOptions = false
  self.ValidHomeIndoorOptions = false
  self.ValidPetBondOptions = false
  self.DisableFlag = 0
  self.DisableFlagTemp = 0
  self.markState = NPC_MARK_STATE.UnInited
  self.bShouldShowMark = true
end

function InteractionComponent:Attach(owner)
  Base.Attach(self, owner)
  self.config = self.owner.config
  self:InitOptions(owner.serverData)
  local CanInteract = not _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_OPTION, false, false)
  if CanInteract then
    self:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.FUNCTION_BAN, false)
  else
    self:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.FUNCTION_BAN, false)
  end
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_OPTION, self, self.OnFunctionStateChanged)
  if self.config.monster_hit_type == Enum.MonsterHitType.MHT_Break then
    self.owner:AddEventListener(self, NPCModuleEvent.BE_ATTACKED, self.OnBeAttacked)
  end
  self.owner:AddEventListener(self, NPCModuleEvent.OnPetStatusChange, self.OnPetStatusChanged)
end

local CombinedInfosCache = {}

local function GetCombinedInfos(ServerData)
  table.clear(CombinedInfosCache)
  local InteractionData = ServerData and ServerData.npc_interact
  if not InteractionData then
    return nil
  end
  local PlayerID = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
  local SharedInfo = InteractionData.option_infos
  local OtherInfo = InteractionData.visitor_only_option_infos
  local MyInfo
  if OtherInfo then
    for _, VisitorInfo in ipairs(OtherInfo) do
      if VisitorInfo.visitor_id == PlayerID then
        MyInfo = VisitorInfo.option_infos
        break
      end
    end
  end
  if SharedInfo then
    for _, Info in ipairs(SharedInfo) do
      CombinedInfosCache[Info.option_id] = Info
    end
  end
  if MyInfo then
    for _, Info in ipairs(MyInfo) do
      CombinedInfosCache[Info.option_id] = Info
    end
  end
  return CombinedInfosCache
end

local function CheckOwnerIsValid(AvatarID)
  if not AvatarID then
    return true
  end
  if 0 == AvatarID then
    return true
  end
  local PlayerID = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
  return AvatarID == PlayerID
end

function InteractionComponent:UpdateData(ServerData, isReconnect)
  Base.UpdateData(self, ServerData)
  local TotalInfo = GetCombinedInfos(ServerData)
  if not TotalInfo then
    self:UpdateCachedOptions()
    return
  end
  local newOpts = {}
  for OptionID, OptionInfo in pairs(TotalInfo) do
    local option = self._options[OptionID]
    if option then
      local oldEnable = option:IsOptionEnable()
      option:UpdateData(OptionInfo, isReconnect)
      local newEnable = option:IsOptionEnable()
      self:Inter_OptionEnableChange(oldEnable, newEnable, option)
    else
      self:Inter_AddOption(OptionID, OptionInfo)
    end
    newOpts[OptionID] = true
  end
  local needRemove = {}
  for id, option in pairs(self._options) do
    if not newOpts[id] then
      table.insert(needRemove, id)
    end
  end
  for _, id in pairs(needRemove) do
    self:Inter_RemoveOption(id)
  end
  if isReconnect then
    self.DisableFlagTemp = 0
    self:UpdateInteractionEnable()
  else
    self:UpdateCachedOptions()
  end
end

function InteractionComponent:DeAttach()
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_OPTION, self, self.OnFunctionStateChanged)
  if self.config.monster_hit_type == Enum.MonsterHitType.MHT_Break then
    self.owner:RemoveEventListener(self, NPCModuleEvent.BE_ATTACKED, self.OnBeAttacked)
  end
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnPetStatusChange, self.OnPetStatusChanged)
  if self.markShowDistance then
    Log.Debug("InteractionComponent:DeAttach: remove markShowDistance", self.owner:DebugNPCNameAndID(), self.markShowDistance)
    if self.owner.viewObj and UE4.UObject.IsValid(self.owner.viewObj) then
      self.owner.viewObj:RemoveCustomTickDistance(self.markShowDistance)
    end
    self.markShowDistance = nil
    self:DestroyMark()
  end
end

function InteractionComponent:Destroy()
  if self.markShowDistance then
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnNpcMarkDestroy, self.owner)
  end
  self:LeaveAllCheckOptions()
  table.clear(self._checkOptions)
  for _, v in pairs(self._options) do
    if v:HasArea() then
      v:UnregisterArea()
    end
    v:Destroy()
  end
  table.clear(self._options)
  self.Valid3DOptions = false
  self.ValidSenseOptions = false
  self.ValidHomeIndoorOptions = false
  self.ValidPetBondOptions = false
  Base.Destroy(self)
end

function InteractionComponent:InitOptions(serverData)
  self.serverData = serverData
  local TotalInfo = GetCombinedInfos(serverData)
  if not TotalInfo or not next(TotalInfo) then
    return
  end
  for OptionID, OptionInfo in pairs(TotalInfo) do
    local Conf = _G.DataConfigManager:GetNpcOptionConf(OptionInfo.option_id)
    if Conf then
      self._options[OptionID] = NpcOption(self.owner, OptionInfo)
    else
      Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176NPC\233\128\137\233\161\185\233\133\141\231\189\174", OptionInfo.option_id)
    end
  end
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:CalcCheckOpts()
  local manualOpts = {}
  for _, v in pairs(self._options) do
    if not v:IsOptionEnable() then
    else
      local interactType = v:GetInteractType()
      if v:HasArea() then
        v:RegisterArea()
      elseif v:IsManual() then
        table.insert(manualOpts, v)
        self._highestManualPriority = math.max(self._highestManualPriority, v:GetPriority())
      elseif v:IsAuto() then
        self._checkOptions[v.optionInfo.option_id] = v
      elseif interactType == _G.Enum.InteractType.IT_COMPASS then
        self._checkOptions[v.optionInfo.option_id] = v
      elseif interactType == _G.Enum.InteractType.IT_EMOTE then
        self._checkOptions[v.optionInfo.option_id] = v
      end
    end
  end
  local validManualOpts, priority = self:GetAndResetHighestPriorityOptions(manualOpts)
  for _, v in pairs(validManualOpts) do
    self._checkOptions[v.optionInfo.option_id] = v
  end
  self._highestManualPriority = priority
  local ID, Option = next(self._checkOptions)
  if not ID and not Option then
    self._highestManualPriority = -1
  end
  self.owner:SendEvent(NPCModuleEvent.OnInteractingChanged, self:HasAnyInteractingOption())
end

function InteractionComponent:OnSetViewObj()
  for _, v in pairs(self._options) do
    v:OnSetViewObj()
  end
  self:UpdateCachedOptions()
end

function InteractionComponent:OnAddOptionAction(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self:Inter_AddOption(action.opt_info.option_id, action.opt_info)
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:Inter_AddOption(id, optionInfo)
  local Conf = _G.DataConfigManager:GetNpcOptionConf(optionInfo.option_id)
  if not Conf then
    Log.Error("\230\183\187\229\138\160NPC\233\128\137\233\161\185\229\164\177\232\180\165\239\188\140\230\137\190\228\184\141\229\136\176\233\133\141\231\189\174", optionInfo.option_id)
    return
  end
  local option = NpcOption(self.owner, optionInfo)
  self._options[id] = option
  if option:IsOptionEnable() then
    self:StartCheckOption(option)
  end
  self:BroadcastOptionChanged(option)
end

function InteractionComponent:StartCheckOption(option)
  if not option then
    return
  end
  if option:HasArea() then
    option:RegisterArea()
    return
  end
  local InteractType = option:GetInteractType()
  local ID = option:GetID()
  local Priority = option:GetPriority()
  if option:IsAuto() or InteractType == Enum.InteractType.IT_COMPASS or InteractType == Enum.InteractType.IT_EMOTE then
    self._checkOptions[ID] = option
  elseif option:IsManual() then
    if Priority == self._highestManualPriority then
      self._checkOptions[ID] = option
    elseif Priority > self._highestManualPriority then
      self:OnHighPriorityOptionActive(ID, option)
    end
  end
  self.owner:SendEvent(NPCModuleEvent.OnInteractingChanged, self:HasAnyInteractingOption())
end

function InteractionComponent:StopCheckOption(option)
  if not option then
    return
  end
  if option:HasArea() then
    option:UnregisterArea()
    return
  end
  local ID = option:GetID()
  self._checkOptions[ID] = nil
  if option.inActionArea then
    option:OnPlayerLeaveActionArea()
    option.inActionArea = false
  end
  if option:IsManual() and option:GetPriority() >= self._highestManualPriority then
    self:CalcCheckOpts()
  end
end

function InteractionComponent:OnHighPriorityOptionActive(id, option)
  self:ClearManualOption()
  self._checkOptions[id] = option
  self._highestManualPriority = option:GetPriority()
end

function InteractionComponent:OnRemoveOptionAction(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self:Inter_RemoveOption(action.option_id)
  self:UpdateCachedOptions()
end

function InteractionComponent:Inter_RemoveOption(id)
  Log.DebugFormat("[InteractCompRemoveOption]NpcInfo: %s;    OptionID: %d", self.owner:DebugNPCNameAndID(), id)
  local Option = self._options[id]
  if not Option then
    Log.Error("\229\136\160\233\153\164Option\231\154\132\230\151\182\229\128\153\239\188\140Option\228\184\141\229\173\152\229\156\168\239\188\129", id, self.owner:DebugNPCNameAndID())
    return
  end
  self:BroadcastOptionChanged(Option)
  self._options[id] = nil
  self:StopCheckOption(Option)
  Option:Destroy()
  if 0 == table.len(self._options) then
    self._highestManualPriority = -1
  end
end

function InteractionComponent:OnOptionsChange(action, Tag, BaseData)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  Log.Debug("InteractionComponent:OnOptionsChange", action.option_id)
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    local oldEnable = option:IsOptionEnable()
    option:OnOptionChange(action, Tag, BaseData)
    local newEnable = option:IsOptionEnable()
    self:Inter_OptionEnableChange(oldEnable, newEnable, option)
    self:UpdateCachedOptions()
    self:BroadcastOptionChanged(option)
  else
    local DialogueModule = NRCModuleManager:GetModule("DialogueModule")
    if DialogueModule.HasDialogue then
      Log.Error("OnOptionChange\228\189\134\230\152\175Option\228\184\141\229\173\152\229\156\168!\229\175\185\232\175\157\228\184\173\233\129\135\229\136\176\232\191\153\231\167\141\230\131\133\229\134\181\230\156\137\229\143\175\232\131\189\229\175\188\232\135\180\229\175\185\232\175\157\229\141\161\230\173\187!", self.owner:DebugNPCNameAndID(), action.option_id)
    end
  end
end

function InteractionComponent:OnOptionEnableChange(option, old_enable, new_enable)
  if old_enable == new_enable then
    return
  end
  if option then
    self:Inter_OptionEnableChange(old_enable, new_enable, option)
  end
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:Inter_OptionEnableChange(oldEnable, newEnable, option)
  if oldEnable and not newEnable then
    self:StopCheckOption(option)
  elseif not oldEnable and newEnable then
    self:StartCheckOption(option)
  end
end

function InteractionComponent:OnSelectionInfoChange(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    option:OnNpcDialogSelectInfoChange(action)
  end
end

function InteractionComponent:OnAddStoryFlag(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    option:OnAddStoryFlags(action)
  else
    Log.DebugFormat("Can't find option %d when adding story flags", action.option_id)
  end
end

function InteractionComponent:OnRemoveStoryFlag(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    option:OnRemoveStoryFlags(action)
  else
    Log.DebugFormat("Can't find option %d when remove story flags", action.option_id)
  end
end

function InteractionComponent:OnAddSelectAction(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    option:OnAddSelectAction(action)
  else
    Log.DebugFormat("Can't find option %d when add selects", action.option_id)
  end
end

function InteractionComponent:OnRemoveSelectAction(action)
  if not CheckOwnerIsValid(action.avatar_id) then
    return
  end
  self.needStatusNotify = false
  local option = self._options[action.option_id]
  if option then
    option:OnRemoveSelectAction(action)
  else
    Log.DebugFormat("Can't find option %d when remove selects", action.option_id)
  end
end

function InteractionComponent:CalcSquareDis(pos1, pos2)
  local subx = pos1.X - pos2.X
  local suby = pos1.Y - pos2.Y
  local subz = pos1.Z - pos2.Z
  return subx * subx + suby * suby + subz * subz
end

function InteractionComponent:SubVec2D(pos1, pos2)
  local subx = pos1.X - pos2.X
  local suby = pos1.Y - pos2.Y
  return UE4.FVector(subx, suby, 0)
end

function InteractionComponent:GetAndResetHighestPriorityOptions(options)
  local ans = {}
  local highestPriority = -1
  for _, v in pairs(options) do
    if v:IsOptionEnable() then
      if highestPriority < v:GetPriority() then
        for _, lower in pairs(ans) do
          if lower.inActionArea then
            lower.inActionArea = false
            lower:OnPlayerLeaveActionArea()
          end
        end
        ans = {v}
        highestPriority = v:GetPriority()
      elseif v:GetPriority() == highestPriority then
        table.insert(ans, v)
      end
    end
  end
  return ans, highestPriority
end

function InteractionComponent:OnPlayerTeleportStart()
  self:LeaveAllCheckOptions()
end

function InteractionComponent:UpdateByDistance(deltaTime)
  if not self.owner:CanInteract() then
    return
  end
  local PlayerRadiusDiff = self.owner.module:GetPlayerRadiusDiff()
  local PlayerInteractStateCache = self.owner.module:GetPlayerInteractStateCache()
  local RolePlayerBehaviorID = self.owner.module:GetRolePlayBehaviorID()
  local Player2NpcHeightDiff = self.owner.PlayerHeightDiff
  local RequestEarlyTick = false
  for option_id, option in pairs(self._checkOptions) do
    local interactType = option:GetInteractType()
    local ConfigSquareDis, ConfigDis = option:GetSquaredDistance()
    local playerSquareDis = self.owner.squaredDis2LocalIgnoreZ
    if PlayerRadiusDiff > 0 then
      ConfigSquareDis = PlayerRadiusDiff + ConfigDis
      ConfigSquareDis = ConfigSquareDis * ConfigSquareDis
      ConfigDis = ConfigDis + PlayerRadiusDiff
    end
    local max_update_distance = 0
    if interactType == Enum.InteractType.IT_AUTO or interactType == Enum.InteractType.IT_MANUAL or interactType == Enum.InteractType.IT_EMOTE or interactType == Enum.InteractType.IT_SCENE_SIT or interactType == Enum.InteractType.IT_HOME_GRID or interactType == Enum.InteractType.IT_AUTOMANUAL then
      max_update_distance = math.max(max_update_distance, ConfigSquareDis)
    end
    if interactType == _G.Enum.InteractType.IT_MANUAL_BOND then
      if nil == petBondIconDistance then
        local petBondIconDistanceConf = _G.DataConfigManager:GetNpcGlobalConfig("pet_bond_icon_distance")
        petBondIconDistance = petBondIconDistanceConf and petBondIconDistanceConf.num or 4000
        petBondIconDistance = petBondIconDistance * 1.2
        petBondIconDistance = petBondIconDistance * petBondIconDistance
      end
      max_update_distance = math.max(max_update_distance, petBondIconDistance)
    end
    if playerSquareDis < max_update_distance then
      RequestEarlyTick = true
    end
    local UseStrict = option:IsAuto()
    local ShouldInteract = option:IsOptionEnable(UseStrict)
    if ShouldInteract then
      local IsInHeightArea = true
      local OptionHeight = option.config.option_hight
      if OptionHeight and 0 ~= OptionHeight then
        IsInHeightArea = Player2NpcHeightDiff < OptionHeight
      else
        IsInHeightArea = Player2NpcHeightDiff < ConfigDis
      end
      ShouldInteract = IsInHeightArea
    end
    if ShouldInteract then
      if interactType == Enum.InteractType.IT_HOME_GRID then
        ShouldInteract = option:InHomeFurnitureGrid()
      elseif option.inActionArea then
        local SquaredLeaveDis, LeaveDis = option:GetSquaredLeaveDistance()
        if PlayerRadiusDiff > 0 then
          LeaveDis = LeaveDis + PlayerRadiusDiff
          SquaredLeaveDis = LeaveDis * LeaveDis
        end
        local IsInOuterArea = playerSquareDis < SquaredLeaveDis
        if self.owner:IsFarmCropNpc() and IsInOuterArea then
          IsInOuterArea = FarmUtils.IsPlayerInCropNpcLand(self.owner)
        end
        ShouldInteract = IsInOuterArea
      else
        local IsInnerArea = playerSquareDis < ConfigSquareDis
        if self.owner:IsFarmCropNpc() and IsInnerArea then
          IsInnerArea = FarmUtils.IsPlayerInCropNpcLand(self.owner)
        end
        ShouldInteract = IsInnerArea
      end
    end
    if ShouldInteract then
      local _, IsPlayerInNpcView = self:InSpecificAngleValid(option)
      ShouldInteract = IsPlayerInNpcView
    end
    if ShouldInteract then
      local IsNpcInPlayerView = self:IsInPlayerForward(option)
      ShouldInteract = IsNpcInPlayerView
    end
    ShouldInteract = ShouldInteract and not option:IsInteractBanState(PlayerInteractStateCache)
    if ShouldInteract and option:IsFarmOption() then
      local landInfo = option:GetOwnerFarmlandInfo()
      if landInfo and landInfo.plant_id then
        ShouldInteract = FarmUtils.IsLandOptionTypeAvailable(FarmUtils.GetFarmOptionType(option), landInfo.plant_id, nil, false)
      else
        ShouldInteract = false
      end
      if FarmUtils.IsPlayerHasCurrentAction() then
        ShouldInteract = false
      end
    end
    if ShouldInteract and 720000013 == option_id then
      local blackList = option.config and option.config.logic_status_blacklist
      for blackListStatus in pairs(blackList) do
        if self.owner:IsLogicStatus(blackListStatus) then
          ShouldInteract = false
          break
        end
      end
    end
    if 150001 == option_id then
      option.playerSquareDis = playerSquareDis
    end
    if ShouldInteract and option.inActionArea then
      option:OnOptionStay(RolePlayerBehaviorID)
    elseif ShouldInteract and not option.inActionArea then
      option:OnOptionEnter(RolePlayerBehaviorID)
    else
      if not ShouldInteract and option.inActionArea then
        option:OnOptionLeave()
      else
      end
    end
    RequestEarlyTick = RequestEarlyTick or ShouldInteract or option.inActionArea
  end
  if RequestEarlyTick then
    self.owner:ScheduleNextTick(0.1)
  end
  self:UpdateMarkStateByDistance()
end

function InteractionComponent:InSpecificAngleValid(option)
  local playerLocation = self.owner.PlayerPosCache
  local option_effective_angle = option.config.option_effective_angle
  if option_effective_angle and #option_effective_angle >= 2 then
    local minAngle = option_effective_angle[1]
    local maxAngle = option_effective_angle[2]
    return ThrowUtils.CheckActionEffectInAnglesForward(self.owner, playerLocation, minAngle, maxAngle)
  end
  local option_Z_effective_angle = option.config.option_Z_effective_angle
  if option_Z_effective_angle and 0 ~= option_Z_effective_angle then
    local ZAngle = option_Z_effective_angle
    return ThrowUtils.CheckActionEffectInAnglesVertical(self.owner, playerLocation, ZAngle)
  end
  return nil, true
end

function InteractionComponent:IsInPlayerForward(Option)
  local Rotation = Option.config.vision_range
  if 0 == Rotation then
    return true
  elseif self.owner.PlayerForwardDotCache and self.owner.PlayerForwardDotCache > Option.PlayerViewRotationCos then
    return true
  end
  return false
end

function InteractionComponent:GetMainAction()
  local choose
  for _, v in pairs(self._options) do
    if v:IsOptionEnable() then
      if not choose then
        choose = v
      elseif v:GetPriority() > choose:GetPriority() then
        choose = v
      elseif v:GetPriority() == choose:GetPriority() and v.config.id < choose.config.id then
        choose = v
      end
    end
  end
  return choose
end

function InteractionComponent:GetActiveBattleAction()
  local choose
  for _, v in pairs(self._options) do
    if v:IsBattleAction() and v:IsOptionEnable() then
      if not choose then
        choose = v
      elseif v:GetPriority() > choose:GetPriority() then
        choose = v
      elseif v:GetPriority() == choose:GetPriority() and v.config.id < choose.config.id then
        choose = v
      end
    end
  end
  return choose
end

function InteractionComponent:GetFirstOption()
  for _, v in pairs(self._options) do
    return v
  end
  return nil
end

function InteractionComponent:OnPlayerLeaveActionArea()
  self.isInOverlapArea = false
end

function InteractionComponent:OnPlayerEnterActionArea()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
    return
  end
  self.isInOverlapArea = true
  if self.owner.canTriggerInteraction then
    for _, v in pairs(self._options) do
      if 0 == v.config.option_radius and v:IsAuto() and not v.inActionArea and not v:NeedStatusNotify() then
        v:OnOptionAction()
        v.inActionArea = true
      end
    end
  else
    Log.Debug("InteractionComponent:OnPlayerEnterActionArea \229\183\178\232\162\171\231\166\129\231\148\168\228\186\164\228\186\146", self.DisableFlag, self.DisableFlagTemp)
  end
end

function InteractionComponent:SubmitBattleOption(Session, WeakPoint)
  if not Session then
    Log.Error("[NpcAction] InteractionComponent:SubMitBattleOption Session is nil")
    return false
  end
  if _G.GlobalConfig.DisableBattle then
    Log.Debug("[NpcAction] InteractionComponent:SubMitBattleOption \229\183\178\232\162\171\231\166\129\231\148\168\230\136\152\230\150\151", Session.SeqID)
    return false
  end
  if not self.owner.canTriggerInteraction then
    Log.DebugFormat("[NpcAction] InteractionComponent:SubMitBattleOption \229\183\178\232\162\171\231\166\129\231\148\168\228\186\164\228\186\146", Session.SeqID)
    return false
  end
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("[NpcAction] InteractionComponent:SubMitBattleOption player is nil", Session.SeqID)
    return false
  end
  if player:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
    Log.Debug("[NpcAction] \231\142\169\229\174\182\233\128\187\232\190\145\231\138\182\230\128\129\228\184\141\232\131\189\230\136\152\230\150\151")
    return false
  end
  local logicStatusComponent = self.owner and self.owner.LogicStatusComponent
  if logicStatusComponent then
    local hasStatus, _, _ = logicStatusComponent:GetStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    if hasStatus then
      Log.Debug("[NpcAction] NPC\233\128\187\232\190\145\231\138\182\230\128\129\228\184\141\232\131\189\230\136\152\230\150\151")
      return false
    end
  end
  if NpcOption:NeedStatusNotify() then
    Log.Debug("[NpcAction] \231\173\137\229\190\133\228\184\138\228\184\128\230\157\161\228\186\164\228\186\146\229\155\158\229\140\133\239\188\140\228\184\141\232\131\189\232\191\155\230\136\152")
    return false
  end
  player.PlayerThrowInteractionComponent:SubmitBattle(Session, self.owner, WeakPoint)
  return true
end

function InteractionComponent:OnSubmitBattle(rsp)
end

function InteractionComponent:CanBattle()
  local result, reason = self:CanBattleWithReason()
  return result
end

function InteractionComponent:CanBattleWithReason()
  if not self.owner.canTriggerInteraction then
    return false, EFailedReason.CanTriggerInteractionFailed
  end
  if not self:DoCheckCanBattle_PetCreator() then
    return false, EFailedReason.PetCreatorFailed
  end
  for _, v in pairs(self._options) do
    if v:IsOptionEnable(true) and not v:NeedStatusNotify() then
      local PetActionType = v.config.pet_action.action_type or Enum.ActionType.ACT_NONE
      if PetActionType == Enum.ActionType.ACT_BATTLE then
        return true, 0, EFailedReason.Success
      elseif PetActionType == Enum.ActionType.ACT_TOUCHBATTLE then
        return true, 0, EFailedReason.Success
      elseif PetActionType == Enum.ActionType.ACT_BOX_BATTLE then
        return true, 0, EFailedReason.Success
      end
    end
  end
  return false, EFailedReason.DefaultFailed
end

function InteractionComponent:CanBattleWithBox()
  for _, v in pairs(self._options) do
    if v.optionInfo and v.optionInfo.enabled then
      local PetActionType = v.config.pet_action.action_type or Enum.ActionType.ACT_NONE
      if PetActionType == Enum.ActionType.ACT_BOX_BATTLE then
        return true, 0, EFailedReason.Success
      end
    end
  end
  return false, EFailedReason.DefaultFailed
end

function InteractionComponent:DoCheckCanBattle_PetCreator()
  local bBossType = self.config and self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS
  if bBossType then
    return true
  end
  local bHighValue = UIUtils.CheckIsHighValuePet(self)
  if not bHighValue then
    return true
  end
  if not self.serverData.npc_base.create_avatar_id then
    return true
  end
  local player_uin = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if player_uin == self.serverData.npc_base.create_avatar_id then
    return true
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local other_uin = player:GetAnotherTogetherMovePlayerUin()
  if other_uin and other_uin == self.serverData.npc_base.create_avatar_id then
    return true
  end
  return false
end

function InteractionComponent:TryShowBattleFailedTips(reason)
  if reason == EFailedReason.PetCreatorFailed then
    local tip, ownerName = UIUtils.GetHighValuePetTipsAndOwnerName(self.serverData)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    return tip
  end
end

function InteractionComponent:CanBattleMaxRangeSquared()
  if not self.owner.canTriggerInteraction then
    return 0
  end
  local maxFightRange = 0
  for _, v in pairs(self._options) do
    if v:IsOptionEnable(true) and not v:NeedStatusNotify() then
      local PetActionType = v.config.pet_action.action_type or Enum.ActionType.ACT_NONE
      if PetActionType == Enum.ActionType.ACT_NONE then
        local actionType = v.config.action.action_type
        if actionType == Enum.ActionType.ACT_BATTLE and maxFightRange < v.config.pet_fight_radius then
          maxFightRange = v.config.pet_fight_radius
        end
        if actionType == Enum.ActionType.ACT_TOUCHBATTLE and maxFightRange < v.config.pet_fight_radius then
          maxFightRange = v.config.pet_fight_radius
        end
        if actionType == Enum.ActionType.ACT_BOX_BATTLE and maxFightRange < v.config.pet_fight_radius then
          maxFightRange = v.config.pet_fight_radius
        end
      elseif PetActionType == Enum.ActionType.ACT_BATTLE and maxFightRange < v.config.pet_fight_radius then
        maxFightRange = v.config.pet_fight_radius
      elseif PetActionType == Enum.ActionType.ACT_TOUCHBATTLE and maxFightRange < v.config.pet_fight_radius then
        maxFightRange = v.config.pet_fight_radius
      elseif PetActionType == Enum.ActionType.ACT_BOX_BATTLE and maxFightRange < v.config.pet_fight_radius then
        maxFightRange = v.config.pet_fight_radius
      end
    end
  end
  return maxFightRange * maxFightRange
end

function InteractionComponent:GetBattleOption()
  if not self.owner.canTriggerInteraction then
    return nil
  end
  for _, v in pairs(self._options) do
    if v:IsOptionEnable() and not v:NeedStatusNotify() then
      local PetActionType = v.config.pet_action.action_type or Enum.ActionType.ACT_NONE
      if PetActionType == Enum.ActionType.ACT_NONE then
        local actionType = v.config.action.action_type
        if actionType == Enum.ActionType.ACT_BATTLE then
          return v
        end
        if actionType == Enum.ActionType.ACT_TOUCHBATTLE then
          return v
        end
        if actionType == Enum.ActionType.ACT_BOX_BATTLE then
          return v
        end
      elseif PetActionType == Enum.ActionType.ACT_BATTLE then
        return v
      elseif PetActionType == Enum.ActionType.ACT_TOUCHBATTLE then
        return v
      elseif PetActionType == Enum.ActionType.ACT_BOX_BATTLE then
        return v
      end
    end
  end
  return nil
end

function InteractionComponent:CanCatch()
  if not self.owner.canTriggerInteraction then
    return false
  end
  local throwInteractType = self.owner:GetThrowInteractType()
  if throwInteractType ~= _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
    return false
  end
  for _, v in pairs(self._options) do
    local actionType = v.config.action.action_type
    if actionType == Enum.ActionType.ACT_BATTLE then
      return true
    end
  end
  return false
end

function InteractionComponent:CollectByType(inCollectType)
  if not self.owner.canTriggerInteraction then
    return false
  end
  self:CollectActiveConfigs()
  for _, v in pairs(self._options) do
    if v.config.pet_ride_type == inCollectType and v:IsOptionEnable(true) and not v:NeedStatusNotify() and not self:IsOptionBanned(v) and v.OnOptionAction then
      v:OnOptionAction()
      return true
    end
  end
  return false
end

local BannedList = {}
local AllowList = {}
local ActionTypeList = {}

function InteractionComponent:IsOptionBanned(Option)
  local OptionID = Option.config.id
  local ActionType = Option.config.action and Option.config.action.action_type
  self:CheckBanStatus(OptionID, ActionType)
end

function InteractionComponent:CheckBanStatus(OptionID, ActionType)
  if next(BannedList) then
    if BannedList[OptionID] then
      Log.Debug("NpcOption:CheckOptionIDBanned OptionID:", OptionID, " is in BannedList - BANNED")
      return true
    elseif next(ActionTypeList) then
      if not ActionTypeList[ActionType] then
        Log.Debug("NpcOption:CheckOptionIDBanned OptionID:", OptionID, " ActionType:", ActionType, " not allowed when BannedList exists - BANNED")
        return true
      else
        return false
      end
    else
      return false
    end
  end
  if next(AllowList) then
    if AllowList[OptionID] then
      return false
    elseif next(ActionTypeList) then
      if not ActionTypeList[ActionType] then
        Log.Debug("NpcOption:CheckOptionIDBanned OptionID:", OptionID, " not in AllowList and ActionType:", ActionType, " not allowed - BANNED")
        return true
      else
        return false
      end
    else
      Log.Debug("NpcOption:CheckOptionIDBanned OptionID:", OptionID, " not in AllowList and no ActionType restriction - BANNED")
      return true
    end
  end
  if next(ActionTypeList) then
    if not ActionTypeList[ActionType] then
      Log.Debug("NpcOption:CheckOptionIDBanned OptionID:", OptionID, " ActionType:", ActionType, " not in ActionTypeList - BANNED")
      return true
    else
      return false
    end
  end
  return false
end

function InteractionComponent:CollectActiveConfigs()
  table.clear(BannedList)
  table.clear(AllowList)
  table.clear(ActionTypeList)
  local Conds = _G.FunctionBanManager:GetConditionCounterDic()
  for Key, Count in pairs(Conds) do
    if Count and Count > 0 then
      local Conf = _G.DataConfigManager:GetHidePlayerManualOptionConf(Key, true)
      if Conf then
        for _, v in ipairs(Conf.banned_list or {}) do
          BannedList[v] = true
        end
        for _, v in ipairs(Conf.allowed_list or {}) do
          AllowList[v] = true
        end
        for _, v in ipairs(Conf.allow_list or {}) do
          if v.allowed_list then
            ActionTypeList[v.allowed_list] = true
          end
        end
      end
    end
  end
end

function InteractionComponent:GetPowerDashOption()
  if not self.owner.canTriggerInteraction then
    return nil
  end
  local Found
  for _, v in pairs(self._options) do
    local Conf = v.config
    if not Conf then
    else
      local PowerDashType = Conf.pet_power_dash_action and Conf.pet_power_dash_action.action_type
      if not PowerDashType then
      elseif not PowerDashActionFactory.Registry[PowerDashType] then
      elseif not v:IsOptionEnable(true) then
      elseif v:NeedStatusNotify() then
      else
        Found = v
        break
      end
    end
  end
  return Found
end

function InteractionComponent:GetRandomOption()
  for _, v in pairs(self._options) do
    local actionType = v.config.pet_action.action_type
    if actionType == Enum.ActionType.ACT_TRIG_RAND_PET_INTERACT then
      return v
    end
  end
  return nil
end

function InteractionComponent:GetOptionByID(ID)
  return self._options[ID]
end

function InteractionComponent:GetPetOption(PetData, bDontCheckDerived)
  local NormalOption, SpecialAction
  for _, v in pairs(self._options) do
    local actionType = v.config.pet_action.action_type
    local PetAction = v:EnsurePetAction()
    if PetAction and not bDontCheckDerived then
      PetAction = PetAction:GetDerivedAction(PetData)
    end
    if PetAction and not SpecialAction and PetAction:IsEnabled() then
      if PetAction:IsExecuting() then
        if PetAction:InstanceOf(PetActionCommon) then
          SpecialAction = PetActionFactory:Get(v, true)
        end
        if not SpecialAction and self.owner.Watch then
          Log.Error(self.owner:DebugNPCNameAndID(), "\230\151\160\230\179\149\229\188\128\229\144\175\228\186\164\228\186\146", v.config.pet_action.action_type)
          Log.Error(self.owner:DebugNPCNameAndID(), "\230\151\160\230\179\149\229\188\128\229\144\175\228\186\164\228\186\146", PetAction:IsEnabled() and "Action\229\143\175\231\148\168" or "Action\228\184\141\229\143\175\231\148\168", PetAction:IsExecuting() and "\230\137\167\232\161\140\228\184\173" or "\230\156\170\230\137\167\232\161\140")
        end
      else
        SpecialAction = PetAction
      end
    end
    if v:IsOptionEnable(true) and not NormalOption and NORMAL_PET_ACTIONS[actionType] then
      NormalOption = v
    end
    if NormalOption and SpecialAction then
      break
    end
  end
  return NormalOption, SpecialAction
end

function InteractionComponent:CanInteractWithPet(baseConf)
  local MyFeatures = self.config.interactable_feature
  if nil == MyFeatures or 0 == #MyFeatures then
    return true
  end
  local OtherFeatures = baseConf.ecology_feature
  if nil == OtherFeatures or 0 == #OtherFeatures then
    return true
  end
  for _, mFeature in ipairs(MyFeatures) do
    for _, oFeature in ipairs(OtherFeatures) do
      if mFeature == oFeature then
        return true
      end
    end
  end
  return false
end

function InteractionComponent:InteractWithNpc(source)
  if not self.owner.canTriggerInteraction then
    return
  end
  for _, option in pairs(self._options) do
    local PetAction = option:EnsureWildAction()
    if PetAction then
      if PetAction then
        local PetData = self:CreatePetDataFromSceneNpc(source)
        if PetData then
          PetAction = PetAction:GetDerivedAction(PetData)
        end
      end
      if PetAction then
        if PetAction:IsEnabled() and not PetAction:IsExecuting() then
          PetAction:SetNextSubmissionMode(ActionUtils.ActionSubmissionMode.SceneNpc)
          PetAction:Execute(source)
          return
        elseif self.owner.Watch then
          Log.Error(self.owner:DebugNPCNameAndID(), "\230\151\160\230\179\149\229\188\128\229\144\175\228\186\164\228\186\146", option.config.pet_action.action_type)
        end
      end
    end
  end
end

function InteractionComponent:OnBeAttacked(other)
  self:InteractWithNpc(other)
end

function InteractionComponent:CreatePetDataFromSceneNpc(npc)
  local npcConf = npc.config
  local svrData = npc.serverData
  if not svrData then
    return nil
  end
  local petBase
  if npcConf.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
    petBase = _G.DataConfigManager:GetPetbaseConf(npcConf.traverse_data_param[1] or 0, true)
  end
  if not petBase then
    return nil
  end
  local PetData = ProtoMessage:newPetData()
  PetData.gid = 0
  PetData.conf_id = 0
  PetData.name = npcConf.name
  PetData.nature = svrData.npc_base.nature
  PetData.gender = svrData.base.gender
  PetData.exp = 0
  PetData.level = svrData.base.lv
  PetData.ball_id = 0
  PetData.base_conf_id = npcConf.traverse_data_param[1]
  PetData.evolution_stage = ProtoEnum.PetEvolutionState.EM_EVOLUTION_ADDED
  PetData.pet_status_flags = 0
  PetData.height = svrData.npc_base.height
  PetData.weight = svrData.npc_base.weight
  PetData.classis = petBase.pet_classis_id
  PetData.classis_name = ""
  PetData.last_breakthrough_lv = 0
  PetData.add_time = 0
  PetData.energy = 10
  PetData.can_submit = false
  PetData.is_first_catch = false
  PetData.catch_status = 0
  PetData.catch_lv = 0
  PetData.catch_base_id = nil
  PetData.mutation_type = 0
  PetData.catch_ai_status = 0
  return PetData
end

function InteractionComponent:OnFunctionStateChanged(newBanState, functionType)
  if functionType ~= Enum.PlayerFunctionBanType.PFBT_OPTION then
    return
  end
  self:SetInteractionEnable(not newBanState, NPCModuleEnum.NpcInteractDisableFlag.FUNCTION_BAN, false)
end

function InteractionComponent:SetInteractionEnable(Enable, Flag, Temp)
  if nil == Flag then
    Flag = 0
  end
  if nil == Temp then
    Temp = true
  end
  if Enable then
    if Temp then
      self.DisableFlagTemp = self.DisableFlagTemp & ~(1 << Flag)
    else
      self.DisableFlag = self.DisableFlag & ~(1 << Flag)
    end
  elseif Temp then
    self.DisableFlagTemp = self.DisableFlagTemp | 1 << Flag
  else
    self.DisableFlag = self.DisableFlag | 1 << Flag
  end
  self:UpdateInteractionEnable()
end

function InteractionComponent:UpdateInteractionEnable()
  local Disable = 0 ~= self.DisableFlagTemp or 0 ~= self.DisableFlag
  local Changed = false
  if self.owner.canTriggerInteraction ~= not Disable then
    Changed = true
  end
  if Disable then
    self:TryDisableInteractionInner()
  else
    self:TryEnableInteractionInner()
  end
  if Changed then
    self.owner:SendEvent(NPCModuleEvent.OnInteractionEnableChanged, self.owner, not Disable)
  end
end

function InteractionComponent:TryDisableInteraction()
  self:SetInteractionEnable(false)
end

function InteractionComponent:TryEnableInteraction()
  self:SetInteractionEnable(true)
end

function InteractionComponent:TryDisableInteractionInner()
  self.owner.canTriggerInteraction = false
  for _, v in pairs(self._options) do
    if v.inActionArea then
      v.inActionArea = false
      v:OnPlayerLeaveActionArea()
    end
  end
  self:UpdateCachedOptions()
end

function InteractionComponent:TryEnableInteractionInner()
  self.owner.canTriggerInteraction = true
  if true == self.isInOverlapArea then
    self:UpdateByDistance(0)
  end
  self:UpdateCachedOptions()
end

function InteractionComponent:GetAllOptions()
  return self._options
end

function InteractionComponent:GetOptionByInteractType(InteractionType)
  for _, option in pairs(self._options) do
    if option.config.npc_interact_type == InteractionType then
      return option
    end
  end
end

function InteractionComponent:UpdateSenseOptions()
  if self.ValidSenseOptions then
    table.clear(self.ValidSenseOptions)
  end
  if self.owner:IsHidden() then
    return nil
  end
  for _, option in pairs(self._options) do
    if option.config.npc_interact_type ~= Enum.InteractType.IT_COMPASS then
    else
      local Conf = option:GetCompassConf()
      if not Conf then
      else
        if Conf.action.action_style_type == Enum.CompassResponse.CR_KNOSTELE_QUIT then
          if option.optionInfo.succ_exec_times > 0 then
            goto lbl_75
          end
        elseif Conf.action.action_style_type == Enum.CompassResponse.CR_KNOSTELE_ENTER and option.optionInfo.succ_exec_times > 0 then
          goto lbl_75
        end
        if not option:IsOptionEnable() then
        elseif option:IsDisableByOnlineMode() then
        else
          if not self.ValidSenseOptions then
            self.ValidSenseOptions = {}
          end
          table.insert(self.ValidSenseOptions, option)
        end
      end
    end
    ::lbl_75::
  end
end

function InteractionComponent:GetValidSenseOption()
  if not self.ValidSenseOptions or 0 == #self.ValidSenseOptions then
    return nil
  end
  local squared_dis = self.owner.squaredDis2Local
  for _, option in ipairs(self.ValidSenseOptions) do
    local maxInteractDist, _ = NPCLuaUtils.GetSenseInfo(option)
    if squared_dis < maxInteractDist then
      return option
    end
  end
  return nil
end

function InteractionComponent:UpdateHomeOptions()
  if self.ValidHomeIndoorOptions then
    table.clear(self.ValidHomeIndoorOptions)
  end
  for _, option in pairs(self._options) do
    if option.config.npc_interact_type ~= Enum.InteractType.IT_HOME_PET_FEED and option.config.npc_interact_type ~= Enum.InteractType.IT_HOME_PET_REWARD and option.config.npc_interact_type ~= Enum.InteractType.IT_HOME_PET_STEAL or not option:IsOptionEnable() then
    elseif option:IsDisableByOnlineMode() then
    else
      if not self.ValidHomeIndoorOptions then
        self.ValidHomeIndoorOptions = {}
      end
      table.insert(self.ValidHomeIndoorOptions, option)
    end
  end
end

function InteractionComponent:GetValidHomeOptions()
  local optionList = {}
  if not self.ValidHomeIndoorOptions or 0 == #self.ValidHomeIndoorOptions then
    return optionList
  end
  for _, option in ipairs(self.ValidHomeIndoorOptions) do
    if option:IsOptionEnable(true) then
      table.insert(optionList, option)
    end
  end
  return optionList
end

function InteractionComponent:Update3DOptions()
  if self.Valid3DOptions then
    table.clear(self.Valid3DOptions)
  end
  if not self.owner:CanInteract() then
    return
  end
  for _, option in pairs(self._options) do
    local InteractType = option:GetInteractType()
    if InteractType ~= Enum.InteractType.IT_3DUI and InteractType ~= Enum.InteractType.IT_PLANT_SEED and InteractType ~= Enum.InteractType.IT_PLANT_GET then
    elseif not option:IsOptionEnable() then
    else
      if not self.Valid3DOptions then
        self.Valid3DOptions = {}
      end
      table.insert(self.Valid3DOptions, option)
    end
  end
end

function InteractionComponent:GetValid3DOption()
  if not self.Valid3DOptions or 0 == #self.Valid3DOptions then
    return nil
  end
  local squared_dis = self.owner.squaredDis2Local
  local IsFarmCropNpc = self.owner:IsFarmCropNpc()
  local IsPlayerInCropNpcLand = FarmUtils.IsPlayerInCropNpcLand(self.owner)
  for _, option in ipairs(self.Valid3DOptions) do
    local InteractType = option:GetInteractType()
    if (InteractType == Enum.InteractType.IT_PLANT_SEED or InteractType == Enum.InteractType.IT_PLANT_GET) and (not IsFarmCropNpc or not IsPlayerInCropNpcLand) then
    else
      local SquaredDist = option:GetSquaredDistance()
      if squared_dis < SquaredDist then
        return option
      end
    end
  end
  return nil
end

function InteractionComponent:UpdatePetBondOptions()
  if self.ValidPetBondOptions then
    table.clear(self.ValidPetBondOptions)
  end
  if not self.owner:CanInteract() then
    return
  end
  for _, option in pairs(self._options) do
    if option.config.npc_interact_type ~= Enum.InteractType.IT_MANUAL_BOND then
    elseif not option:IsOptionEnable() then
    else
      if not self.ValidPetBondOptions then
        self.ValidPetBondOptions = {}
      end
      table.insert(self.ValidPetBondOptions, option)
    end
  end
end

function InteractionComponent:GetValidPetBondOption()
  if not self.ValidPetBondOptions or 0 == #self.ValidPetBondOptions then
    return nil
  end
  for _, option in ipairs(self.ValidPetBondOptions) do
    return option
  end
  return nil
end

function InteractionComponent:BroadcastOptionChanged(option)
  local luaObj = self.owner.luaObj
  if luaObj then
    luaObj:OnNpcOptionChange(option)
  end
end

function InteractionComponent:ClearManualOption()
  for ID, Option in pairs(self._checkOptions) do
    if Option.inActionArea then
      Option.inActionArea = false
      Option:OnPlayerLeaveActionArea()
    end
    if Option:IsManual() then
      self._checkOptions[ID] = nil
    end
  end
end

function InteractionComponent:LeaveAllCheckOptions()
  for _, Option in pairs(self._checkOptions) do
    if Option.inActionArea then
      Option.inActionArea = false
      Option:OnPlayerLeaveActionArea()
    end
  end
end

function InteractionComponent:RefreshOptions()
  if self.owner:GetVisible() then
    self:UpdateByDistance(0)
  else
    self:LeaveAllCheckOptions()
  end
  self:UpdateCachedOptions()
end

function InteractionComponent:OnEnterVisit()
  self:OnPlayerTeleportStart()
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:OnLeaveVisit()
  self:OnPlayerTeleportStart()
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:OnHomeVisitChange()
  self:OnPlayerTeleportStart()
  self:CalcCheckOpts()
  self:UpdateCachedOptions()
end

function InteractionComponent:OnPetStatusChanged()
  self:UpdateCachedOptions()
end

function InteractionComponent:UpdateCachedOptions()
  self:UpdateSenseOptions()
  self:Update3DOptions()
  self:UpdateHomeOptions()
  self:UpdatePetBondOptions()
  self:UpdateMarkShowDistance()
end

function InteractionComponent:NotifyBeginActionParams(Action, Tag, BaseData)
  if not CheckOwnerIsValid(Action.avatar_id) then
    return
  end
  Log.Debug("InteractionComponent:NotifyBeginActionParams")
  local Option = self._options[Action.option_id]
  if Option then
    if Option:IsOptionEnable() then
      Option:NotifyBeginActionParams(Action, Tag, BaseData)
    end
  else
    local DialogueModule = NRCModuleManager:GetModule("DialogueModule")
    if DialogueModule.HasDialogue then
      Log.Error("amonsu:InteractionComponent:NotifyBeginActionParams\228\184\173Option\228\184\141\229\173\152\229\156\168!", self.owner:DebugNPCNameAndID(), Action.option_id)
    end
  end
end

function InteractionComponent:UpdateMarkShowDistance()
  local owner = self.owner
  if not owner then
    return
  end
  local distance = 0
  if owner:CanInteract() then
    for _, v in pairs(self._options) do
      if not v:IsOptionEnable() then
      elseif v.config.npc_interact_type == Enum.InteractType.IT_NONE then
      elseif v.config and v.config.npc_interaction_show_distance and v.config.npc_interaction_show_distance > 0 then
        distance = math.max(distance, v.config.npc_interaction_show_distance)
      end
    end
  end
  local viewObj = self.owner.viewObj
  if distance <= 0 then
    if self.markShowDistance then
      Log.Debug("InteractionComponent:UpdateMarkShowDistance: remove markShowDistance", owner:DebugNPCNameAndID(), self.markShowDistance)
      self:RemoveCustomTickDistance(viewObj, self.markShowDistance)
      self.markShowDistance = nil
      self:DestroyMark()
    end
  elseif self.markShowDistance == nil then
    self.markShowDistance = distance
    self:AddCustomTickDistance(viewObj, distance)
    Log.Debug("InteractionComponent:UpdateMarkShowDistance: init markShowDistance", owner:DebugNPCNameAndID(), self.markShowDistance)
  else
    if distance <= self.markShowDistance then
      return
    end
    Log.Debug("InteractionComponent:UpdateMarkShowDistance: update markShowDistance", owner:DebugNPCNameAndID(), self.markShowDistance, distance)
    self:RemoveCustomTickDistance(viewObj, self.markShowDistance)
    self:AddCustomTickDistance(viewObj, distance)
    self.markShowDistance = distance
  end
end

function InteractionComponent:AddCustomTickDistance(actor, distance)
  if not actor or not UE4.UObject.IsValid(actor) then
    return
  end
  if not actor.AddCustomTickDistance then
    Log.Warning("InteractionComponent:AddCustomTickDistance function not existed", UE4.UKismetSystemLibrary.GetDisplayName(actor), distance)
    return
  end
  actor:AddCustomTickDistance(distance)
end

function InteractionComponent:RemoveCustomTickDistance(actor, distance)
  if not actor or not UE4.UObject.IsValid(actor) then
    return
  end
  if not actor.RemoveCustomTickDistance then
    Log.Warning("InteractionComponent:RemoveCustomTickDistance function not existed", UE4.UKismetSystemLibrary.GetDisplayName(actor), distance)
    return
  end
  actor:RemoveCustomTickDistance(distance)
end

function InteractionComponent:SetMarkShouldShow(bNewState)
  self.bShouldShowMark = bNewState
end

function InteractionComponent:GetShouldShowMark()
  return self.bShouldShowMark
end

local bShouldCacheShownNpc = true
local npcShownCached = {}

function InteractionComponent:UpdateMarkStateByDistance()
  if self.markShowDistance == nil or self.markShowDistance <= 0 then
    return
  end
  local distance = self.owner.squaredDis2Local
  if distance <= self.markShowDistance ^ 2 then
    if self.markState ~= NPC_MARK_STATE.Show then
      Log.Debug("InteractionComponent:UpdateMarkShowState Show", self.owner:DebugNPCNameAndID(), distance, self.markShowDistance)
      _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnNpcMarkShow, self.owner)
      self.markState = NPC_MARK_STATE.Show
      if bShouldCacheShownNpc then
        npcShownCached[self.owner] = true
      end
      return
    end
  elseif distance > (self.markShowDistance * 2) ^ 2 then
    if self.markState ~= NPC_MARK_STATE.Destroy then
      self:DestroyMark(distance)
      return
    end
  elseif self.markState ~= NPC_MARK_STATE.Hide then
    Log.Debug("InteractionComponent:UpdateMarkShowState Hide", self.owner:DebugNPCNameAndID(), distance, self.markShowDistance)
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnNpcMarkHide, self.owner)
    self.markState = NPC_MARK_STATE.Hide
    return
  end
end

function InteractionComponent:DestroyMark(distance)
  Log.Debug("InteractionComponent:UpdateMarkShowState Destroy", self.owner:DebugNPCNameAndID(), distance, self.markShowDistance)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnNpcMarkDestroy, self.owner)
  self.markState = NPC_MARK_STATE.Destroy
  if bShouldCacheShownNpc then
    npcShownCached[self.owner] = nil
  end
end

function InteractionComponent.SetShouldCacheShownNpc(bShould, bClear)
  bShouldCacheShownNpc = bShould
  if bClear then
    npcShownCached = {}
  end
end

function InteractionComponent.GetCachedShownNpc()
  return npcShownCached
end

function InteractionComponent:HasAnyInteractingOption()
  return next(self._checkOptions) ~= nil
end

return InteractionComponent
