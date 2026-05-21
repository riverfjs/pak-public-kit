local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local OnlineConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
local HUDComponent = Base:Extend("HUDComponent")
HUDComponent:SetMemberCount(8)

local function GetRoleGlobalConfigNumDefault(key, defaultValue)
  local value = defaultValue or 0
  local config = _G.DataConfigManager:GetRoleGlobalConfig(key)
  value = config and config.num or value
  return value
end

local MAX_TICK_DELTA = 1
local TICK_INTERVAL = 0.5
local ticked_frame_cnt = 0
local NAME_SHOW_DIST = GetRoleGlobalConfigNumDefault("role_scene_name_view_distance")
local NAME_SHOW_DIST_SQR = NAME_SHOW_DIST * NAME_SHOW_DIST
local FIGHTING_IMAGE_SHOW_DIST = GetRoleGlobalConfigNumDefault("role_scene_battle_view_distance")
local FIGHTING_IMAGE_SHOW_DIST_SQR = FIGHTING_IMAGE_SHOW_DIST * FIGHTING_IMAGE_SHOW_DIST
local RELATION_IMAGE_SHOW_DIST = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_icon_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local RELATION_IMAGE_SHOW_DIST_SQR = RELATION_IMAGE_SHOW_DIST * RELATION_IMAGE_SHOW_DIST
local AFK_SHOW_DIST = GetRoleGlobalConfigNumDefault("afk_icon_display_distance")
local AFK_SHOW_DIST_SQR = AFK_SHOW_DIST * AFK_SHOW_DIST
local NEW_PLAYER_STATE_SHOW_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("head_info_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local NEW_PLAYER_STATE_SHOW_DISTANCE_SQR = NEW_PLAYER_STATE_SHOW_DISTANCE * NEW_PLAYER_STATE_SHOW_DISTANCE

function HUDComponent:PreCtor()
  Base.PreCtor(self)
  self._playerHeadHud = nil
  self.isFriend = false
  self.isVisitor = false
  self._headWidgetTrans = nil
  self._headHudRenderDisableOpSource = nil
  self._tickTotalTime = 0
end

function HUDComponent:OnSetViewObj()
  local viewObj = self.owner.viewObj
  if viewObj then
    local headWidget = viewObj.HeadWidget
    if headWidget then
      self._playerHeadHud = headWidget:GetUserWidgetObject()
      self._playerHeadHud:CheckVisible()
      self._headWidgetTrans = headWidget:GetRelativeTransform()
      local PlayerUin = self.owner and self.owner.serverData.base.logic_id or 0
      self.isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(PlayerUin)
      local disableOpSource = (self._headHudRenderDisableOpSource or 0) | (_G.GlobalConfig.DisableAllPlayerHud or 0)
      if disableOpSource and 0 ~= disableOpSource then
        headWidget:SetRenderStatus(false, disableOpSource)
      end
    end
  end
end

function HUDComponent:SetHudName(name)
  if self._playerHeadHud then
    self._playerHeadHud:SetName(name)
    local isShowName = not string.IsNilOrEmpty(name) and (self.isFriend or self.isVisitor)
    if self.config and self.config.show_name_type == Enum.NpcNameType.NNT_HIDE then
      isShowName = false
    end
    if self.owner and self.owner.serverData and self.owner.serverData.is_magic_replay and MagicReplayUtils.IsMarkVideoNameShowEnabled() then
      isShowName = true
    end
    self:SetNameVisible(isShowName)
    local isShowRecallIcon = false
    local player_tags = self.owner.serverData.avatar_status.player_tags
    if player_tags then
      for _, tag in ipairs(player_tags) do
        if tag == _G.ProtoEnum.PlayerTag.PT_RECALL then
          isShowRecallIcon = true
        end
      end
    end
    self._playerHeadHud:SetReturnIconVisible(isShowRecallIcon)
    local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
    if nil ~= FriendModule then
      local VisitList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      if nil ~= VisitList then
        self:SetVisitNumberFromList(VisitList)
      end
    end
    if self.owner then
      local bInFighting = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
      local bInObserving = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OBSERVING)
      self:SetState(MainUIModuleEnum.PlayerHudState.Observing, bInObserving)
      if bInObserving then
        self:SetFightingState(false)
      else
        self:SetFightingState(bInFighting)
      end
      local bInAFK = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_PLAYER_AFK)
      self:SetState(MainUIModuleEnum.PlayerHudState.AFK, bInAFK)
      if not bInFighting and not bInAFK then
        local RelationTreeModule = _G.NRCModuleManager:GetModule("RelationTreeModule")
        if nil ~= RelationTreeModule then
          local OherRelationRequestEnumType = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin)
          self:SetRelationTreeInteraction(OherRelationRequestEnumType)
        end
      end
      local bIsFullScreen = self:IsFullScreenState()
      local bIsInteraction = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_PLAYER_NPC)
      self:SetState(MainUIModuleEnum.PlayerHudState.FullScreen, bIsFullScreen)
      self:SetState(MainUIModuleEnum.PlayerHudState.NpcInteraction, bIsInteraction)
    end
  end
end

function HUDComponent:SetNameVisible(visible)
  if self._playerHeadHud then
    self._playerHeadHud:SetNameVisible(visible)
  end
end

function HUDComponent:SetState(state, active)
  if self._playerHeadHud then
    self._playerHeadHud:SetRoleState(state, active)
  end
end

function HUDComponent:SetFightingState(_inFighting)
  if self._playerHeadHud then
    self._playerHeadHud:SetFightingState(_inFighting)
  end
end

function HUDComponent:SetRelationTreeInteraction(OherRelationRequestEnumType, ActionID)
  if self._playerHeadHud then
    self._playerHeadHud:SetRelationTreeState(OherRelationRequestEnumType, ActionID)
  end
end

function HUDComponent:SetVisitNumber(_number)
  if self._playerHeadHud then
    self.isVisitor = _number and _number > 0
    self._playerHeadHud:SetVisitNumber(_number)
  end
end

function HUDComponent:Perform(type, data)
  if self._playerHeadHud then
    local duration = _G.DataConfigManager:GetGlobalConfigByKeyType("catch_icon_display_time", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG).num
    self._playerHeadHud:ShowPerform(type, data, duration)
  end
end

function HUDComponent:SetVisible(visible)
  if _G.HUDComponentDisabled then
    return
  end
  if self._playerHeadHud then
    self._playerHeadHud:SetVisible(visible)
  end
end

function HUDComponent:SetHeadWidgetRenderStatus(enable, opSource)
  local disableOpSource = self._headHudRenderDisableOpSource or 0
  if enable then
    disableOpSource = disableOpSource & ~opSource
  else
    disableOpSource = disableOpSource | opSource
  end
  self._headHudRenderDisableOpSource = disableOpSource
  local viewObj = self.owner.viewObj
  if viewObj and UE.UObject.IsValid(viewObj) then
    local headWidget = viewObj.HeadWidget
    if headWidget and UE.UObject.IsValid(headWidget) then
      headWidget:SetRenderStatus(enable, opSource)
    end
  end
end

function HUDComponent:AdjustHudBeforeDoubleRiding(addOffset)
end

local DefaultOffset = UE.FVector(0, 0, 60)
local HeadTransformCache = UE4.FTransform()
local TempHitResult = UE4.FHitResult()

function HUDComponent:AdjustHudAfterDoubleRiding(addOffset)
  UE.UNRCCharacterUtils.AdjustHeadWidgetOffset(self.owner.viewObj, addOffset or DefaultOffset, HeadTransformCache, "Bip001-Head")
  self._debugHeadPos = HeadTransformCache.Translation
end

function HUDComponent:RestoreHudAfterDoubleRiding()
  self._debugHeadPos = nil
  if not self._headWidgetTrans then
    return
  end
  local viewObj = self.owner.viewObj
  if not viewObj or not UE.UObject.IsValid(viewObj) then
    return
  end
  local playerHeadWidget = viewObj.HeadWidget
  if not playerHeadWidget or not UE.UObject.IsValid(playerHeadWidget) then
    return
  end
  playerHeadWidget:AdjustTransform(self._headWidgetTrans, UE.EAdjustTransformType.Relative_Transform)
end

function HUDComponent:AdjustOffset()
  if not self._playerHeadHud then
    return
  end
  local rideComponent = self.owner.viewObj.BP_RideComponent
  local rideMeshHeight = -999999
  local rideCapsuleHeight = -999999
  local playerHeight = self.owner.viewObj.Mesh:K2_GetComponentLocation().Z + 188
  if rideComponent.ScenePet and rideComponent.RidePet then
    local Translation = UE4.FVector()
    local Extent = UE4.FVector()
    UE4.UKismetSystemLibrary.GetComponentBounds(rideComponent.RidePet.Mesh, Translation, Extent, 0)
    rideMeshHeight = Translation.Z + Extent.Z + 15
    rideCapsuleHeight = rideComponent.RidePet:K2_GetActorLocation().Z + 100
    playerHeight = rideComponent.RidePet.Mesh:GetSocketLocation(rideComponent.RideSocketName).Z + 120
  end
  local widget = self.owner.viewObj.HeadWidget
  local newLocation = widget:K2_GetComponentLocation()
  newLocation.Z = math.max(rideMeshHeight, rideCapsuleHeight, playerHeight)
  widget:K2_SetWorldLocation(newLocation, false, nil, false)
end

function HUDComponent:Attach(owner)
  Base.Attach(self, owner)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  self.owner:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, RelationTreeEvent.UPDATE_OTHERREQUEST_PLAYER_CHANGE, self.OnLogicRelationTreeUpdated)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, RelationTreeEvent.DELETE_OTHERREQUEST_PLAYER, self.OnLogicRelationTreeUpdated)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, self.OnRelationBubbleChangeYellow)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.OnUpdateFriendRelationship)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, _G.NRCGlobalEvent.ON_FETCH_PLAYER_FRIEND, self.OnUpdateFriendRelationship)
  _G.NRCEventCenter:RegisterEvent("HUDComponent", self, MainUIModuleEvent.OnPlayerTagsChange, self.OnPlayerTagsChange)
end

function HUDComponent:DeAttach()
  Base.DeAttach(self)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.UPDATE_OTHERREQUEST_PLAYER_CHANGE, self.OnLogicRelationTreeUpdated)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.DELETE_OTHERREQUEST_PLAYER, self.OnLogicRelationTreeUpdated)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, self.OnRelationBubbleChangeYellow)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.OnUpdateFriendRelationship)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_FETCH_PLAYER_FRIEND, self.OnUpdateFriendRelationship)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnPlayerTagsChange, self.OnPlayerTagsChange)
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
end

function HUDComponent:OnVisitorChanged(_notify)
  if nil ~= _notify then
    local visitors = _notify.visitors
    self:SetVisitNumberFromList(visitors)
  end
end

function HUDComponent:SetVisitNumberFromList(visitors)
  if nil ~= visitors and #visitors > 0 then
    local Player = self.owner
    local PlayerUin = Player.serverData.base.logic_id
    local VisitCount = #visitors
    local Index = 0
    for i = 1, VisitCount do
      if PlayerUin == visitors[i].uin then
        Index = i
        break
      end
    end
    if Index > 0 then
      self:SetVisitNumber(Index)
    end
  else
    self:SetVisitNumber(0)
  end
end

function HUDComponent:OnLogicStatusUpdated()
  if self.owner then
    local bInFighting = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    local bInObserving = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OBSERVING)
    self:SetState(MainUIModuleEnum.PlayerHudState.Observing, bInObserving)
    if bInObserving then
      self:SetFightingState(false)
    else
      self:SetFightingState(bInFighting)
    end
    local bIsFullScreen = self:IsFullScreenState()
    local bIsInteraction = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_PLAYER_NPC)
    self:SetState(MainUIModuleEnum.PlayerHudState.FullScreen, bIsFullScreen)
    self:SetState(MainUIModuleEnum.PlayerHudState.NpcInteraction, bIsInteraction)
  end
end

function HUDComponent:IsFullScreenState()
  local bIsFullScreen = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OPEN_UI_FULL_SCENE)
  local extraState = not self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OPEN_LOBBY_MAIN_INNER) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) or self.owner.statusComponent and self.owner.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN)
  bIsFullScreen = bIsFullScreen or extraState
  return bIsFullScreen
end

function HUDComponent:OnLogicRelationTreeUpdated()
  if self.owner then
    local RelationTreeModule = _G.NRCModuleManager:GetModule("RelationTreeModule")
    if nil ~= RelationTreeModule then
      local Player = self.owner
      local PlayerUin = Player.serverData.base.logic_id
      local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      local ActionID = LocalPlayer and LocalPlayer.InviteComponent:GetInviterActionID(PlayerUin)
      if ActionID then
        self:SetRelationTreeInteraction(nil, ActionID)
      else
        local OherRelationRequestEnumType = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, PlayerUin)
        self:SetRelationTreeInteraction(OherRelationRequestEnumType)
      end
    end
  end
end

function HUDComponent:OnRelationBubbleChangeYellow(IsYellow, TargetPlayerUin, IsRelation)
  if not self._playerHeadHud then
    return
  end
  local Player = self.owner
  local PlayerUin = Player.serverData.base.logic_id
  if PlayerUin ~= TargetPlayerUin then
    return
  end
  if IsYellow then
    local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local ActionID = LocalPlayer and LocalPlayer.InviteComponent:GetInviterActionID(TargetPlayerUin)
    local OherRelationRequestEnumType = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, TargetPlayerUin)
    if IsRelation and OherRelationRequestEnumType then
      if self._playerHeadHud then
        self._playerHeadHud:SetRelationTreeImgBGYellow(IsYellow)
      end
    elseif not IsRelation and ActionID and self._playerHeadHud then
      self._playerHeadHud:SetRelationTreeImgBGYellow(IsYellow)
    end
  elseif self._playerHeadHud then
    self._playerHeadHud:SetRelationTreeImgBGYellow(IsYellow)
  end
end

function HUDComponent:OnUpdateFriendRelationship()
  local PlayerUin = self.owner and self.owner.serverData.base.logic_id or 0
  self.isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(PlayerUin)
  self:Update(MAX_TICK_DELTA)
end

function HUDComponent:Update(deltaTime)
  if _G.HUDComponentDisabled then
    self._playerHeadHud:SetVisible(false)
    return
  end
  if not self._onlineNameShowDistSqr then
    local ONLINE_NAME_SHOW_DIST = 1000
    for i = 1, #OnlineConf do
      if OnlineConf[i].key == "online_number_name_show_distance" then
        ONLINE_NAME_SHOW_DIST = OnlineConf[i].num
        break
      end
    end
    self._onlineNameShowDistSqr = ONLINE_NAME_SHOW_DIST * ONLINE_NAME_SHOW_DIST
  end
  local totalTickTime = (self._tickTotalTime or 0) + deltaTime
  self._tickTotalTime = totalTickTime
  if totalTickTime < TICK_INTERVAL then
    return
  end
  local curFameCnt = _G.UpdateManager.FrameCnt
  if curFameCnt <= ticked_frame_cnt and totalTickTime < MAX_TICK_DELTA then
    return
  end
  self._tickTotalTime = 0
  ticked_frame_cnt = curFameCnt
  local owner = self.owner
  if owner and UE.UObject.IsValid(self._playerHeadHud) then
    local squaredDis2Local = owner:CalSquaredDis2Local()
    local isInOnlineMode = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    local nameShowDistSqr = isInOnlineMode and self._onlineNameShowDistSqr or NAME_SHOW_DIST_SQR
    if squaredDis2Local > nameShowDistSqr then
      self._playerHeadHud:SetNameVisible(false)
    elseif self.isFriend or self.isVisitor then
      self._playerHeadHud:SetNameVisible(true)
    elseif owner.serverData and self.owner.serverData.is_magic_replay and MagicReplayUtils.IsMarkVideoNameShowEnabled() then
      self._playerHeadHud:SetNameVisible(true)
    else
      self._playerHeadHud:SetNameVisible(false)
    end
    if squaredDis2Local > NEW_PLAYER_STATE_SHOW_DISTANCE_SQR then
      self._playerHeadHud:SetRoleStateVisible(MainUIModuleEnum.PlayerHudState.Fighting | MainUIModuleEnum.PlayerHudState.NpcInteraction | MainUIModuleEnum.PlayerHudState.FullScreen, false)
    else
      self._playerHeadHud:SetRoleStateVisible(MainUIModuleEnum.PlayerHudState.Fighting | MainUIModuleEnum.PlayerHudState.NpcInteraction | MainUIModuleEnum.PlayerHudState.FullScreen, true)
    end
    if squaredDis2Local > RELATION_IMAGE_SHOW_DIST_SQR then
      self._playerHeadHud:SetRelationTreeVisible(false)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_DIS, false, owner.serverData.base.logic_id)
    else
      self:OnLogicRelationTreeUpdated()
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_DIS, true, owner.serverData.base.logic_id)
    end
    if self.owner.AFKComponent then
      self.owner.AFKComponent:OnDistanceUpdate(squaredDis2Local <= NEW_PLAYER_STATE_SHOW_DISTANCE_SQR)
    end
  end
end

function HUDComponent:OnPlayerTagsChange(actor_id, player_tags)
  if self.owner.serverData.base.actor_id == actor_id then
    self.owner.serverData.avatar_status.player_tags = player_tags
    local isShowRecallIcon = false
    if player_tags then
      for _, tag in ipairs(player_tags) do
        if tag == _G.ProtoEnum.PlayerTag.PT_RECALL then
          isShowRecallIcon = true
        end
      end
    end
    self._playerHeadHud:SetReturnIconVisible(isShowRecallIcon)
  end
end

return HUDComponent
