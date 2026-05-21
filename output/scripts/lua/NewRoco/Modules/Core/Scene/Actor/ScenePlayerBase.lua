local Base = require("NewRoco.Modules.Core.Scene.Actor.SceneCharacter")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local BuffComponent = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuffComponent")
local StatComponent = require("NewRoco.Modules.Core.Scene.Component.Stat.StatComponent")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local AppearanceUIUtils = require("NewRoco.Utils.UIUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local PlayerCompassComponent = require("NewRoco.Modules.Core.Scene.Component.PlayerShow.PlayerCompassComponent")
local PlayerAttackedInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PlayerAttackedInteractionComponent")
local AFKComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.AFKComponent")
local PlayerHomeInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Home.PlayerHomeInteractionComponent")
local PlayerToyComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PlayerToyComponent")
local FarmComponent = require("NewRoco.Modules.Core.Scene.Component.Home.Farm.FarmComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local ChatBubbleComponent = require("NewRoco.Modules.Core.Scene.Component.ChatBubble.ChatBubbleComponent")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local ActionPosePlayer = require("NewRoco.Modules.System.TakePhotos.Helper.ActionPosePlayer")
local EmojiPlayer = require("NewRoco.Modules.System.TakePhotos.Helper.EmojiPlayer")
local ScenePlayerBase = Base:Extend("ScenePlayerBase")
ScenePlayerBase:SetMemberCount(32)

function ScenePlayerBase:PreCtor(module)
  Base.PreCtor(self, module)
  self._cachedTemperature = nil
  self.StatusChecker = nil
  self.LastUpdateTime = 0
  self.collisionFlag = 0
  self.uin = 0
  self.avatarLoaded = false
  self.bFirstAvatarLoadComplete = false
  self.PlayerLoc = nil
  self.PlayerRot = nil
  self.EmojiPlayer = EmojiPlayer(self)
  self.PosePlayer = ActionPosePlayer(self)
end

function ScenePlayerBase:Destroy()
  if self.AvatarID and UE.UObject.IsValid(self.avatarSystem) then
    self.avatarSystem:StopSwitchAvatarSuit(self.AvatarID)
    self.AvatarID = nil
  end
  self.EmojiPlayer:OnDestruct()
  self.PosePlayer:OnDestruct()
  self:SendEvent(PlayerModuleEvent.ON_PLAYER_DESTROY, self)
  _G.NRCEventCenter:DispatchEvent(PlayerModuleEvent.ON_PLAYER_DESTROY, self)
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.BP_RideComponent and self.viewObj.BP_RideComponent.RidePet then
    self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    self.viewObj.BP_RideComponent:StopRide()
    if self.viewObj.BP_RideComponent.RidePet then
      self.viewObj.BP_RideComponent.RidePet:K2_DestroyActor()
    end
  end
  if UE.UObject.IsValid(self.viewObj) and not self.isLocal then
    self.viewObj.AvatarComponent:UnInitAvatar()
  end
  self.statusComponent:ClearAll()
  Base.Destroy(self)
end

function ScenePlayerBase:DestroyModel()
  if not self.isLocal and UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetNetRole(UE4.ENetRole.ROLE_None)
    self.viewObj.CharacterMovement.bForceClientNetMode = false
  end
  Base.DestroyModel(self)
end

function ScenePlayerBase:SetViewObj(ViewObj)
  Base.SetViewObj(self, ViewObj)
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.UPDATE_PLAYER_TAG, ViewObj)
end

function ScenePlayerBase:InitActor(url, pos, rotation)
  Base.InitActor(self, url, pos, rotation)
  if not self.isLocal then
    local viewObj = self.viewObj
    if UE.UObject.IsValid(viewObj) then
      if viewObj.SetActorId then
        viewObj:SetActorId(self:GetServerId())
      end
      viewObj:SetNetRole(UE4.ENetRole.ROLE_SimulatedProxy)
      viewObj.CharacterMovement.bForceClientNetMode = true
      viewObj.CharacterMovement.bNetworkSkipProxyPredictionOnNetUpdate = true
      viewObj.CharacterMovement.NetworkSmoothingMode = UE4.ENetworkSmoothingMode.Exponential
      viewObj.CharacterMovement.NetworkMaxSmoothUpdateDistance = 512
      viewObj.CharacterMovement.NetworkNoSmoothUpdateDistance = 780
      viewObj.CharacterMovement.NetworkSimulatedSmoothLocationTime = 0.2
      viewObj.CharacterMovement.NetworkSimulatedSmoothRotationTime = 0.1
      viewObj.bSimGravityDisabled = true
    end
  end
  if self.isLocal then
    _G.NRCAudioManager:SetEmitterSwitch("Player", "Host", self.viewObj)
  else
    _G.NRCAudioManager:SetEmitterSwitch("Player", "Else", self.viewObj)
  end
end

function ScenePlayerBase:UpdateServerData(ServerData)
  self.serverData = ServerData
end

function ScenePlayerBase:InitComponent()
  self.buffComponent = BuffComponent()
  self:AddComponent(self.buffComponent)
  self.statComponent = StatComponent()
  self:AddComponent(self.statComponent)
  self:EnsureComponent(AFKComponent)
  self.playerHomeInteractionComponent = PlayerHomeInteractionComponent()
  self:AddComponent(self.playerHomeInteractionComponent)
  self.playerToyComponent = PlayerToyComponent()
  self:AddComponent(self.playerToyComponent)
  self.playerAttackedInteractionComponent = PlayerAttackedInteractionComponent()
  if not self.isLocal then
    self:EnsureComponent(PlayerCompassComponent)
    self:EnsureComponent(ChatBubbleComponent)
  end
  if _G.GlobalConfig.ENABLE_HOME and not NRCEnv:IsCreatePlayerMode() then
    self:EnsureComponent(FarmComponent)
  end
  self:AddComponent(self.playerAttackedInteractionComponent)
  Base.InitComponent(self)
end

function ScenePlayerBase:GetPoolKey()
  return UEPath.BP_Player
end

function ScenePlayerBase:OnVisible()
  Base.OnVisible(self)
end

function ScenePlayerBase:OnInvisible()
  Base.OnInvisible(self)
end

function ScenePlayerBase:RandomPosNearBy(srcPos, size)
  local pos = UE4.FVector()
  pos.X = srcPos.X + math.random(-size, size)
  pos.Y = srcPos.Y + math.random(-size, size)
  pos.Z = srcPos.Z
  return pos
end

function ScenePlayerBase:HasMoveInput()
  return self.movementComponent:HasMoveInput()
end

function ScenePlayerBase:OnLanded()
  self:SendEvent(PlayerModuleEvent.ON_PLAYER_LANDED)
  if self.statusComponent then
    self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
  end
end

function ScenePlayerBase:OnWillLand()
end

function ScenePlayerBase:StopRide(DisablePerform, OnFinished)
  if UE.UObject.IsValid(self.viewObj) then
    local rideComp = self.viewObj.BP_RideComponent
    if rideComp and rideComp:IsInDoubleRide() then
      rideComp:TryChangeToLink()
    end
  end
  local NeedCallOnFinished = true
  if DisablePerform then
    self.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_UNRIDE)
    self.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_UNRIDE)
  else
    local canApply, overrideValues, opCode = self.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_UNRIDE, 1)
    if overrideValues then
      for _, v in pairs(overrideValues) do
        self.statusComponent:RemoveStatus(v.status)
      end
      local ability = self.abilityComponent._currentAbility
      if OnFinished and ability and ability:IsCasting() then
        ability.onFinished = OnFinished
        NeedCallOnFinished = false
      end
    end
  end
  if NeedCallOnFinished and OnFinished then
    OnFinished()
  end
end

function ScenePlayerBase:StopDash()
  self.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_DASHING)
end

function ScenePlayerBase:OnDestroyedByEngine()
  Base.OnDestroyedByEngine(self)
  if self.serverData then
    Log.Warning("OnDestroyed by engine, id =  ", self.serverData.base.actor_id)
    NRCModuleManager:DoCmd(PlayerModuleCmd.ON_PLAYER_DISAPPEAR, self.serverData.base.actor_id)
  end
end

function ScenePlayerBase:OnPlayerTeleport(to_pt)
end

function ScenePlayerBase:GetActorLocation()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj.CharacterMovement.UpdatedComponent:Abs_K2_GetComponentLocation()
  end
  return UE4.FVector(0, 0, 0)
end

function ScenePlayerBase:GetActorRotation()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj.CharacterMovement.UpdatedComponent:K2_GetComponentRotation()
  end
  return UE4.FRotator(0, 0, 0)
end

function ScenePlayerBase:SetActorLocation(pos)
  if not pos then
    Log.Error("\231\142\169\229\174\182\228\188\160\229\133\165\228\189\141\231\189\174\228\184\186nil")
    return
  end
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet:Abs_K2_SetActorLocation(pos, false, nil, false)
        return
      end
    end
    self.viewObj.CharacterMovement.UpdatedComponent:Abs_K2_SetWorldLocation(pos, false, nil, false)
  end
end

function ScenePlayerBase:SetActorRotation(rotate)
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet:K2_SetActorRotation(rotate, false)
        return
      end
    end
    self.viewObj.CharacterMovement.UpdatedComponent:K2_SetWorldRotation(rotate, false, nil, false)
  end
end

function ScenePlayerBase:SetCharacterGender(gender)
  Log.Debug("SetCharacterGender ", gender)
  local playerBP = self.viewObj
  if not playerBP then
    return
  end
  self.viewObj.Male = 1 == gender
  self.viewObj.Gender = gender
  if 2 == gender then
    _G.NRCAudioManager:SetEmitterSwitch("Player_Gender", "Female", self.viewObj)
  end
  local fashionItems = self:GetFashionItems()
  if self.gender ~= gender then
    if playerBP.MoveFxComponent then
      playerBP.MoveFxComponent.IsFemale = 2 == gender
    end
    local isLocalMode = NRCEnv:IsLocalMode()
    self.gender = gender
    if 2 == gender then
      local oldMesh = playerBP.Mesh.SkeletalMesh
      if oldMesh then
        oldMesh:Release()
      end
      local animClassPath = self.isLocal and UEPath.ABP_PLAYER_FEMALE or UEPath.ABP_PLAYER_FEMALE_OTHER
      playerBP.Mesh:SetAnimClass(_G.NRCBigWorldPreloader:Get(animClassPath))
      playerBP.AnimComponent:InitAnimInstance()
      playerBP.AnimComponent:SetAnimConfig(_G.NRCBigWorldPreloader:Get(UEPath.ANIM_CONFIG_FEMALE))
      playerBP.CharacterMovement.LedgeClimbMontage = _G.NRCBigWorldPreloader:Get(UEPath.LEDGE_CLIMB_MONTAGE_FEMALE)
      playerBP.CharacterMovement.JumpOutMontage = _G.NRCBigWorldPreloader:Get(UEPath.JUMP_OUT_MONTAGE_FEMALE)
      playerBP.CharacterMovement.ClimbDownMontage = _G.NRCBigWorldPreloader:Get(UEPath.CLIMB_DOWN_MONTAGE_FEMALE)
      local salonIds = {}
      if not isLocalMode then
        salonIds = self:GetSalonIds()
      end
      self:SetDefaultSuit(playerBP.Mesh, self.gender, fashionItems, salonIds)
    else
      local oldMesh = playerBP.Mesh.SkeletalMesh
      if oldMesh then
        oldMesh:Release()
      end
      local animClassPath = self.isLocal and UEPath.ABP_PLAYER_MALE or UEPath.ABP_PLAYER_MALE_OTHER
      playerBP.Mesh:SetAnimClass(_G.NRCBigWorldPreloader:Get(animClassPath))
      playerBP.AnimComponent:InitAnimInstance()
      playerBP.AnimComponent:SetAnimConfig(_G.NRCBigWorldPreloader:Get(UEPath.ANIM_CONFIG_MALE))
      playerBP.CharacterMovement.LedgeClimbMontage = _G.NRCBigWorldPreloader:Get(UEPath.LEDGE_CLIMB_MONTAGE_MALE)
      playerBP.CharacterMovement.JumpOutMontage = _G.NRCBigWorldPreloader:Get(UEPath.JUMP_OUT_MONTAGE_MALE)
      playerBP.CharacterMovement.ClimbDownMontage = _G.NRCBigWorldPreloader:Get(UEPath.LEDGE_CLIMB_MONTAGE_FEMALE)
      local salonIds = {}
      if not isLocalMode then
        salonIds = self:GetSalonIds()
      end
      self:SetDefaultSuit(playerBP.Mesh, self.gender, fashionItems, salonIds)
    end
  end
end

function ScenePlayerBase:SetDefaultSuit(playerMesh, gender, fashionItems, salonIds, dontChangeMeshComp)
  local defaultSuitClass
  self.avatarLoaded = false
  local isLocalMode = NRCEnv:IsLocalMode()
  if 2 == gender then
    if isLocalMode then
      defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE_EDITOR)
    else
      defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
    end
  elseif isLocalMode then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE_EDITOR)
  else
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  if not isLocalMode then
    if salonIds and #salonIds > 0 then
      local salonWearIds = {}
      for k, v in ipairs(salonIds) do
        if v.item_wear_id and 0 ~= v.item_wear_id then
          local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
          if salonItemConf then
            if salonItemConf.avatar_id then
              local avatarId = salonItemConf.avatar_id
              if salonItemConf.texture_id then
                local colorId = salonItemConf.texture_id
                local fullSalonId = self:GetFullSalonId(avatarId, colorId)
                table.insert(salonWearIds, fullSalonId)
              end
            end
          else
            Log.Error("\230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\231\154\132salon\233\133\141\231\189\174", v.item_wear_id)
          end
        end
      end
      defaultSuitObj:SetSalons(salonWearIds)
    end
    if fashionItems and #fashionItems > 0 then
      for k, v in pairs(fashionItems) do
        if v and 0 ~= v.wearing_item_id then
          local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
          if fashionItemConf then
            local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
            local glassId = 0
            if v.wearing_glass and v.wearing_glass.glass_type ~= _G.Enum.GlassType.GT_NULL and 0 ~= v.wearing_item_id then
              glassId = AppearanceUIUtils.GetGlassInfoId(v.wearing_glass)
            end
            if bBodyType then
              defaultSuitObj:SetBody(v.wearing_item_id, glassId)
            else
              defaultSuitObj:SetBody(v.wearing_item_id, glassId)
            end
          else
            Log.Error("fashion\228\184\141\229\173\152\229\156\168")
          end
        end
      end
    end
  end
  self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  local playerType = self.viewObj:GetSignCharacterType()
  local loadPriority = _G.PriorityEnum.Other_Player_Avatar
  if playerType ~= UE.ESignCharacterType.Player then
    loadPriority = _G.PriorityEnum.Local_Player_Avatar
  end
  if self.isLocal or dontChangeMeshComp then
    if self.avatarSystem.OnSwitchAvatarSuitComplete then
      if self.OnAvatarCompleteFunction then
        self.avatarSystem.OnSwitchAvatarSuitComplete:Remove(self.avatarSystem, self.OnAvatarCompleteFunction)
      end
      
      function self.OnAvatarCompleteFunction(system, ID)
        self:OnAvatarCallback(ID, true)
      end
      
      self.avatarSystem.OnSwitchAvatarSuitComplete:Add(self.avatarSystem, self.OnAvatarCompleteFunction)
    end
    self.AvatarID = self.avatarSystem:StartSwitchAvatarSuit(playerMesh, defaultSuitObj, loadPriority)
  else
    local avatarComponent = self.viewObj.AvatarComponent
    if self.OnAvatarCompleteFunction2 then
      avatarComponent.OnSwitchAvatarSuitComplete:Remove(self.avatarSystem, self.OnAvatarCompleteFunction2)
    end
    
    function self.OnAvatarCompleteFunction2(ID)
      self:OnAvatarCallback(ID, false)
    end
    
    avatarComponent.OnSwitchAvatarSuitComplete:Add(self.avatarSystem, self.OnAvatarCompleteFunction2)
    avatarComponent:InitAvatar(defaultSuitObj, loadPriority)
  end
end

function ScenePlayerBase:OnAvatarCallback(ID, isLocal)
  if isLocal then
    if ID == self.AvatarID then
      self.avatarSystem.OnSwitchAvatarSuitComplete:Remove(self.avatarSystem, self.OnAvatarCompleteFunction)
    else
      return
    end
  elseif UE.UObject.IsValid(self.viewObj) then
    self.viewObj.AvatarComponent.OnSwitchAvatarSuitComplete:Remove(self.avatarSystem, self.OnAvatarCompleteFunction2)
  end
  if not UE.UObject.IsValid(self.viewObj) then
    Log.Error("Avatar\229\138\160\232\189\189\229\174\140\230\136\144\230\151\182\239\188\140\228\184\187\232\167\146\229\183\178\232\162\171\233\148\128\230\175\129")
    return
  end
  self:OnAvatarComplete()
  self:SendEvent(PlayerModuleEvent.ON_AVATAR_READY)
  if _G.MagicReplayModuleCmd and self:IsMagicReplayActor() then
    _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqPlayerSpawned, self.viewObj, self.bFirstAvatarLoadComplete)
  end
  if not self.bFirstAvatarLoadComplete then
    self.bFirstAvatarLoadComplete = true
  end
end

function ScenePlayerBase:OnAvatarComplete()
  self.avatarLoaded = true
  self:SetLightChannel()
end

function ScenePlayerBase:GetFullSalonId(configId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = configId * 100 + colorIndex
  return fullSalonId
end

function ScenePlayerBase:IsSwimming()
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        return ridePet.CharacterMovement:IsSwimming()
      end
    end
    return self.viewObj.CharacterMovement:IsSwimming()
  end
  return false
end

function ScenePlayerBase:SetVisible(Visible, KeepCollision, PlayerOnly, KeepMoveComp)
  if UE.UObject.IsValid(self.viewObj) then
    if not KeepMoveComp then
      self:SetCharacterMovementTickEnable(self, Visible, "SetVisible")
    end
    if not KeepCollision then
      self.viewObj:SetActorEnableCollision(Visible)
    end
    if not PlayerOnly and self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet:SetActorHiddenInGame(not Visible)
        if not KeepMoveComp then
          ridePet.CharacterMovement:SetComponentTickEnabled(Visible)
        end
        if not KeepCollision then
          ridePet:SetActorEnableCollision(Visible)
        end
      end
    end
    if self.viewObj.BP_PlayerLightComponent then
      self.viewObj.BP_PlayerLightComponent:SetVisibility(Visible)
    end
  end
  if self.hudComponent then
    self.hudComponent:SetHeadWidgetRenderStatus(Visible, MainUIModuleEnum.DisableHudOpSource.PlayerInVisible)
  end
  self:SetSwimFxVisible(Visible, "PlayerVisible")
  Base.SetVisible(self, Visible)
end

function ScenePlayerBase:SetSwimFxVisible(visible, flag)
  if not UE.UObject.IsValid(self.viewObj) then
    return
  end
  Log.DebugFormat("ScenePlayerBase:SetSwimFxVisible %s Reason %s", visible and "true" or "false", flag)
  local isSwimming = self.viewObj.CharacterMovement:IsSwimming()
  if isSwimming then
    self.viewObj.MoveFXComponent:SetVisible(visible)
  end
  if self.viewObj.BP_RideComponent then
    local ridePet = self.viewObj.BP_RideComponent.RidePet
    if ridePet then
      if visible then
        if ridePet and ridePet.RocoMoveFx and ridePet.RocoMoveFx.PauseMoveFx then
          ridePet.RocoMoveFx:ReStartMoveFx()
        end
      else
        ridePet.RocoMoveFx:PauseMoveFx()
      end
    end
  end
end

function ScenePlayerBase:SetViewVisible(Visible, PlayerOnly)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj.Mesh:SetVisibility(Visible, false)
    self.viewObj.AvatarComponent:SetDecoratorVisible(Visible)
    if self.viewObj.MoveFxComponent.SetVisible then
      self.viewObj.MoveFxComponent:SetVisible(Visible)
    end
    if not PlayerOnly and self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet.Mesh:SetVisibility(Visible, false)
      end
    end
  end
end

function ScenePlayerBase:SetTemperature(Temperature)
  if Temperature and (self._cachedTemperature == nil or self._cachedTemperature ~= Temperature) and UE.UObject.IsValid(self.viewObj) then
    self.viewObj.Temperature = Temperature
    self._cachedTemperature = Temperature
  end
end

function ScenePlayerBase:OnDead()
  if self.components then
    local items = self.components:Items()
    for _, v in ipairs(items) do
      if v.enabled and v.OnDead then
        v:OnDead()
      end
    end
  end
end

function ScenePlayerBase:OnReborn()
  if self.components then
    local items = self.components:Items()
    for _, v in ipairs(items) do
      if v.enabled and v.OnReborn then
        v:OnReborn()
      end
    end
  end
end

function ScenePlayerBase:SetCustomDepth(Depth)
  if UE.UObject.IsValid(self.viewObj) then
    local MeshComp = self.viewObj.Mesh
    if nil == Depth then
      MeshComp:SetRenderCustomDepth(false)
      MeshComp:SetCustomDepthStencilValue(0)
    else
      MeshComp:SetRenderCustomDepth(true)
      MeshComp:SetCustomDepthStencilValue(Depth)
    end
  else
    Log.Warning("no view object...")
  end
end

function ScenePlayerBase:InitPetInfoMap()
  Log.Debug("Init Pet Info Map")
  self.petInfoMap = {}
  local scene_pet_info = self.serverData and self.serverData.scene_pet_info
  local pet_infos = scene_pet_info and scene_pet_info.pet_infos
  if pet_infos then
    for _, pet_info in ipairs(pet_infos or {}) do
      self.petInfoMap[pet_info.gid] = pet_info
    end
  end
end

function ScenePlayerBase:EnsurePetInfoMap()
  if self.petInfoMap == nil then
    self:InitPetInfoMap()
  end
end

function ScenePlayerBase:GetActorLocationFrameCache()
  if not UE.UObject.IsValid(self.viewObj) then
    return _G.FVectorZero
  end
  return self.viewObj:K2_GetActorLocation()
end

function ScenePlayerBase:SetPlayerFashionWearData(wearingItems)
  self.serverData.wearing_item = wearingItems
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if wearingItems and #wearingItems > 0 then
    local hasWand = false
    for k, v in ipairs(wearingItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
          hasWand = true
          player:ChangeDefaultWand(v.wearing_item_id)
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnWandChanged)
          break
        end
      end
    end
    if false == hasWand then
      local defaultWandId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetFashionFreeWand)
      player:ChangeDefaultWand(defaultWandId)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnWandChanged)
    end
  end
end

function ScenePlayerBase:SetPlayerSalonWearData(salonInfo)
  self.serverData.salon_item_wear_data = salonInfo
end

function ScenePlayerBase:GetSalonIds()
  if not self.serverData or not self.serverData.salon_item_wear_data then
    return nil
  end
  return self.serverData.salon_item_wear_data
end

function ScenePlayerBase:GetFashionItems()
  if not self.serverData or not self.serverData.wearing_item then
    return nil
  end
  return self.serverData.wearing_item
end

function ScenePlayerBase:GetWearIdByType(bFashion, type)
  if bFashion then
    local fashionItems = self:GetFashionItems()
    if fashionItems then
      for k, v in ipairs(fashionItems) do
        if v and v.wearing_item_id > 0 then
          local fashionConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
          if fashionConf and fashionConf.type == type then
            return v.wearing_item_id
          end
        end
      end
    end
  else
    local salonIds = self:GetSalonIds()
    if salonIds then
      for k, v in ipairs(salonIds) do
        if v > 0 then
          local salonConf = _G.DataConfigManager:GetSalonItemConf(v)
          if salonConf and salonConf.type == type then
            return v
          end
        end
      end
    end
  end
  return 0
end

function ScenePlayerBase:GetServerId()
  if self.serverData and self.serverData.base then
    return self.serverData.base.actor_id
  end
  return 0
end

function ScenePlayerBase:PlayPostBattleCollectEffect(SkillPath, SkillTarget)
  if not self.StatusChecker then
    self.StatusChecker = StatusCheckerGroup({
      StatusCheckerEnum.Battle
    }, Log.LOG_LEVEL.ELogDebug)
  end
  self.StatusChecker:Check(self, self.InternalPlayCollectEffect, SkillPath, SkillTarget)
end

function ScenePlayerBase:InternalPlayCollectEffect(SkillPath, SkillTarget)
  local View = self.viewObj
  if not UE.UObject.IsValid(View) then
    return
  end
  local SkillComp = View.RocoSkill
  if not UE.UObject.IsValid(SkillComp) then
    return
  end
  local Skill = RocoSkillProxy.Create(SkillPath, SkillComp, PriorityEnum.Active_Player_Action)
  if not Skill then
    Log.Error("Failed to load skill")
    return
  end
  Skill:SetPassive(true)
  Skill:SetCaster(View)
  if nil == SkillTarget then
    Skill:SetTargets({View})
  else
    Skill:SetTargets({SkillTarget})
  end
  Skill:PlaySkill()
end

function ScenePlayerBase:SetLastUpdateTime(InTime)
  self.LastUpdateTime = InTime
end

function ScenePlayerBase:GetLastUpdateTime()
  return self.LastUpdateTime
end

function ScenePlayerBase:SetUin(Uin)
  self.uin = Uin
end

function ScenePlayerBase:GetUin()
  return self.uin
end

function ScenePlayerBase:GetLogicId()
  if self.serverData and self.serverData.base then
    return self.serverData.base.logic_id
  end
  return 0
end

function ScenePlayerBase:SetLightChannel()
  if UE.UObject.IsValid(self.viewObj) then
    if self.isLocal then
      UE4.UNRCStatics.SetSixLightingChannels(self.viewObj, true, false, true, false, false, false, false)
    else
      UE4.UNRCStatics.SetSixLightingChannels(self.viewObj, true, false, true, false, true, false, false)
    end
  end
end

function ScenePlayerBase:OnReConnect(bLight)
  self.PlayerLoc = nil
  self.PlayerRot = nil
  Base.OnReConnect(self, bLight)
end

function ScenePlayerBase:GetCurWandId()
  if self._OverrideWandId then
    return self._OverrideWandId
  end
  local WandId = _G.AppearanceModuleCmd and _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId, self.serverData)
  WandId = WandId or 32500101
  return WandId
end

function ScenePlayerBase:GetWandConf(WandId)
  local WandConf = _G.DataConfigManager:GetFashionWandConf(WandId, true)
  return WandConf
end

function ScenePlayerBase:GetCurWandConf()
  local WandId = self:GetCurWandId()
  return self:GetWandConf(WandId)
end

function ScenePlayerBase:GetCurWandPath()
  local WandData = self:GetCurWandConf()
  local wand_path = WandData.WandMesh
  return wand_path
end

function ScenePlayerBase:GetCurWandDataByMagicType(type)
  local WandConf = self:GetCurWandConf()
  if WandConf then
    local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    local magic_id = WandConf.magic_list[type]
    if nil == magic_id or 0 == magic_id then
      magic_id = 1
    end
    if self._OverrideMagic and self._OverrideMagic[type] then
      magic_id = self._OverrideMagic[type]
    end
    local AvatarConfig = avatarSystem:GetAvatarConfig()
    local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magic_id, type)
    local returnRow
    if type == ProtoEnum.SceneMagicType.SMT_STAR then
      returnRow = UE.FAvatarWandInfo_Star()
    elseif type == ProtoEnum.SceneMagicType.SMT_WIND then
      returnRow = UE.FAvatarWandInfo_Wind()
    elseif type == ProtoEnum.SceneMagicType.SMT_CREATE then
      returnRow = UE.FAvatarWandInfo_Create()
    elseif type == ProtoEnum.SceneMagicType.SMT_LIQUEFY then
      returnRow = UE.FAvatarWandInfo_Transform()
    elseif type == ProtoEnum.SceneMagicType.SMT_LIGHT then
      returnRow = UE.FAvatarWandInfo_Light()
    elseif type == ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE then
      returnRow = UE.FAvatarWandInfo_Message()
    elseif type == ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO then
      returnRow = UE.FAvatarWandInfo_Video()
    end
    UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(type), RowKey, returnRow)
    return returnRow
  end
end

function ScenePlayerBase:OnVisibleChanged(Visible, Reason)
  if self.PlayerCompassComponent then
    self.PlayerCompassComponent:OnViewObjVisibleChanged(Visible, Reason)
  end
  if self.hudComponent then
    self.hudComponent:SetHeadWidgetRenderStatus(Visible, MainUIModuleEnum.DisableHudOpSource.PlayerInVisible)
  end
  self:SetSwimFxVisible(Visible, "PlayerVisible")
  if not Visible then
    self:BreakSuitRelax()
  end
  self:SendEvent(PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, Visible)
end

function ScenePlayerBase:PlaySuitRelax(skillId, petBaseId, petServerId, mutationType, glassInfo, nature, ball_id)
  if self.abilityComponent:IsSuitPerforming() then
    Log.Debug("ScenePlayer:PlaySuitRelax: SuitPerforming ")
    return
  end
  if UE.UObject.IsValid(self.viewObj) then
    local inVisible = self.viewObj:GetActorHidden()
    if inVisible then
      if self.isLocal then
        self.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
      end
      Log.Debug("ScenePlayer:PlaySuitRelax: inVisible return ")
      return
    end
  end
  self.abilityComponent:StartSuitPerform(skillId, petBaseId, petServerId, mutationType, glassInfo, nature, ball_id)
end

function ScenePlayerBase:BreakSuitRelax()
  if self.abilityComponent and self.abilityComponent:IsSuitPerforming() then
    self.abilityComponent:StopSuitPerform()
    if UE.UObject.IsValid(self.viewObj) then
      local animIns = self.viewObj.AnimComponent
      if animIns then
        animIns:StopAllMontage()
      end
    end
  end
end

function ScenePlayerBase:IsLoadingAvatar()
  return not self.avatarLoaded
end

function ScenePlayerBase:IsLoadingRidePet()
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.BP_RideComponent then
    return self.viewObj.BP_RideComponent.bIsLoading
  end
  return false
end

function ScenePlayerBase:IsStatusRecovering()
  if self.statusComponent then
    return self.statusComponent._shouldWaitRecover
  end
  return false
end

function ScenePlayerBase:StopTransformStatus()
  if self.buffComponent then
    local Transformbuff = self.buffComponent:GetBuff("Transform_Buff")
    if Transformbuff then
      Transformbuff:OnLocalTrasnformFailed()
    end
  end
end

function ScenePlayerBase:SetCollisionDisable(disable, flag)
  flag = flag or 0
  if disable then
    self.collisionFlag = self.collisionFlag | 1 << flag
  else
    self.collisionFlag = self.collisionFlag & ~(1 << flag)
  end
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetActorEnableCollision(0 == self.collisionFlag)
  end
end

function ScenePlayerBase:DumpCollisionFlag()
  local binStr = ""
  while self.collisionFlag > 0 do
    local rest = self.collisionFlag % 2
    binStr = rest .. binStr
    self.collisionFlag = (self.collisionFlag - rest) / 2
  end
  Log.DebugFormat("CollisionFlag: %s", binStr)
end

function ScenePlayerBase:ToSafePos(range)
  if UE.UObject.IsValid(self.viewObj) then
    local escapeFunc = self.viewObj.CharacterMovement.FindPosAround
    if escapeFunc then
      local updatedComponent = self.viewObj.CharacterMovement.UpdatedComponent
      local originPos = updatedComponent:K2_GetComponentLocation()
      if not range or 0 == range then
        range = 150
      end
      local safePos = escapeFunc(self.viewObj.CharacterMovement, originPos, range)
      Log.DebugFormat("ScenePlayerBase:ToSafePos %s", safePos)
      self.viewObj.CharacterMovement.UpdatedComponent:K2_SetWorldLocation(safePos, false, nil, false)
    else
      Log.DebugFormat("ScenePlayerBase:ToSafePos Native MovementComponent Doesn't Support ToSafePos")
    end
  end
end

function ScenePlayerBase:CheckPlayerInSeat()
  if not self.serverData or not self.serverData.avatar_interact then
    return
  end
  local PlayerSitInfo = self.serverData.avatar_interact.sit_info
  if not PlayerSitInfo then
    return
  end
  local SeatNpcID = PlayerSitInfo.sit_npc_id
  if SeatNpcID and 0 ~= SeatNpcID then
    local SeatNPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, SeatNpcID)
    if not SeatNPC or not UE.UObject.IsValid(SeatNPC.viewObj) then
      return
    end
    if not SeatNPC.serverData then
      return
    end
    if not SeatNPC.serverData.npc_interact then
      return
    end
    local SeatInfo = SeatNPC.serverData.npc_interact.seat_info
    if not SeatInfo then
      return
    end
    if SeatNpcID == SeatNPC.serverData.base.actor_id then
      local SeatIdx = PlayerSitInfo.seat_idx + 1
      if HomeIndoorSandbox:InHomeIndoor() then
        local FurnitureID = SeatNPC.FurnitureID
        if not FurnitureID then
          return
        end
        local FurnitureView = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetFurnitureView, FurnitureID)
        if not FurnitureView then
          return
        end
        local SeatConf = _G.DataConfigManager:GetSeatConf(SeatNPC.config.id)
        if not SeatConf then
          return
        end
        HomeUtils.PlayerSitToHomeSeat(self, FurnitureView, SeatIdx, SeatConf.is_home_lie)
      else
        local Conf = _G.DataConfigManager:GetRoleplayPropConf(SeatNPC.config.id)
        if not Conf then
          return
        end
        local SpecialG6 = Conf["special_start_" .. SeatIdx]
        local SeatSlot = string.format("seat_%s", SeatIdx)
        self.playerToyComponent:PlayerSitToSceneSeat(SeatNPC, SeatSlot, SpecialG6, nil, Conf.scene_sit_blur_type)
      end
    end
  end
end

function ScenePlayerBase:CheckPlayerInBox()
  if not self:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX) then
    return
  end
  if not self.serverData or not self.serverData.roleplay_prop_info and not not self.serverData.roleplay_prop_info.entered_prop_info then
    return
  end
  local PropInfo = self.serverData.roleplay_prop_info.entered_prop_info
  local BoxNPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, PropInfo.entered_npc_id)
  if not BoxNPC then
    return
  end
  self:SetVisible(false)
end

function ScenePlayerBase:SetLink(isLink, reason)
  self:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, isLink, reason)
end

function ScenePlayerBase:IsInTogetherMove()
  if self.statusComponent and (self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND) or self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)) then
    return true
  end
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.BP_RideComponent then
    return self.viewObj.BP_RideComponent:IsInDoubleRide()
  end
  return false
end

function ScenePlayerBase:IsTogetherMove2P()
  if self.statusComponent and self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    return true
  end
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.BP_RideComponent then
    return self.viewObj.BP_RideComponent.bIsDoubleRide2p
  end
  return false
end

function ScenePlayerBase:IsInStartTransforming()
  if self.buffComponent and self.buffComponent:HasBuff("Transform_Buff") then
    local transformBuff = self.buffComponent:GetBuff("Transform_Buff")
    if transformBuff and transformBuff._isInStartPerform then
      return transformBuff._isInStartPerform
    end
  end
  return false
end

function ScenePlayerBase:IsInEndTransforming()
  if self.buffComponent and self.buffComponent:HasBuff("Transform_Buff") then
    local transformBuff = self.buffComponent:GetBuff("Transform_Buff")
    if transformBuff and transformBuff.IsInEndPerform then
      return transformBuff:IsInEndPerform()
    end
  end
  return false
end

function ScenePlayerBase:GetAnotherTogetherMovePlayer()
  if self.statusComponent then
    if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      local customParams = self.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      if customParams and 0 ~= customParams.ride_param.double_ride_2p_id and customParams.ride_param.double_ride_2p_id ~= nil then
        local id_1p = customParams.ride_param.double_ride_1p_id
        local id_2p = customParams.ride_param.double_ride_2p_id
        local other_id = id_1p
        if self.serverData.base.actor_id == id_1p then
          other_id = id_2p
        end
        return _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, other_id)
      end
    end
    local handStatus
    if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND) then
      handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
    end
    if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
      handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
    end
    if handStatus then
      local customParams = self.statusComponent:GetCustomParams(handStatus)
      if customParams then
        local id_1p = customParams.player_interact_param.player_uin1
        local id_2p = customParams.player_interact_param.player_uin2
        local other_id = id_1p
        if self.serverData.base.logic_id == id_1p then
          other_id = id_2p
        end
        return _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, other_id)
      end
    end
  end
end

function ScenePlayerBase:GetAnotherTogetherMovePlayerUin()
  local player = self:GetAnotherTogetherMovePlayer()
  if player then
    return player:GetUin()
  end
  return nil
end

function ScenePlayerBase:GetRidePetBP()
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent and self.viewObj.BP_RideComponent.RidePet then
      return self.viewObj.BP_RideComponent.RidePet
    end
    local OtherPlayer = self:GetAnotherTogetherMovePlayer()
    if OtherPlayer and UE.UObject.IsValid(OtherPlayer.viewObj) and OtherPlayer.viewObj.BP_RideComponent and OtherPlayer.viewObj.BP_RideComponent.RidePet then
      return OtherPlayer.viewObj.BP_RideComponent.RidePet
    end
  end
end

function ScenePlayerBase:GetRidePetLua()
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent and self.viewObj.BP_RideComponent.ScenePet then
      return self.viewObj.BP_RideComponent.ScenePet
    end
    local OtherPlayer = self:GetAnotherTogetherMovePlayer()
    if OtherPlayer and UE.UObject.IsValid(OtherPlayer.viewObj) and OtherPlayer.viewObj.BP_RideComponent and OtherPlayer.viewObj.BP_RideComponent.ScenePet then
      return OtherPlayer.viewObj.BP_RideComponent.ScenePet
    end
  end
end

function ScenePlayerBase:GetRideComponent()
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.BP_RideComponent and self.viewObj.BP_RideComponent.ScenePet then
      return self.viewObj.BP_RideComponent
    end
    local OtherPlayer = self:GetAnotherTogetherMovePlayer()
    if OtherPlayer and UE.UObject.IsValid(OtherPlayer.viewObj) and OtherPlayer.viewObj.BP_RideComponent and OtherPlayer.viewObj.BP_RideComponent.ScenePet then
      return OtherPlayer.viewObj.BP_RideComponent
    end
  end
end

function ScenePlayerBase:UnLinkHand(LinkReason)
  LinkReason = LinkReason or PlayerModuleEvent.LinkReasonFlags.ANY
  Log.Debug("UnLinkHand", self:GetServerId(), table.getKeyName(PlayerModuleEvent.LinkReasonFlags, LinkReason))
  self:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, false, LinkReason)
end

function ScenePlayerBase:ReLinkHand(LinkReason)
  LinkReason = LinkReason or PlayerModuleEvent.LinkReasonFlags.ANY
  Log.Debug("ReLinkHand", self:GetServerId(), table.getKeyName(PlayerModuleEvent.LinkReasonFlags, LinkReason))
  self:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, true, LinkReason)
end

function ScenePlayerBase:RecordPlayerPos()
  self.PlayerRot = self:GetActorRotation()
  self.PlayerLoc = self:GetActorLocation()
  if self.PlayerLoc then
    Log.Debug("\228\189\141\231\189\174\230\129\162\229\164\141\230\151\165\229\191\151: RecordPlayerPos", self.isLocal, self.PlayerLoc.X, self.PlayerLoc.Y, self.PlayerLoc.Z)
  end
end

function ScenePlayerBase:RecoverPlayerPos(RecoverLimit)
  if not self.PlayerLoc or not self.PlayerRot then
    self.PlayerLoc = nil
    self.PlayerRot = nil
    return
  end
  if nil == RecoverLimit then
    RecoverLimit = 500
  end
  local CurrentLoc = self:GetActorLocation()
  local RecoverDist = UE4.FVector.Dist(self.PlayerLoc, CurrentLoc)
  if RecoverLimit < RecoverDist then
    self.PlayerLoc = nil
    self.PlayerRot = nil
    Log.Warning("\228\189\141\231\189\174\230\129\162\229\164\141\230\151\165\229\191\151: \232\183\157\231\166\187\232\182\133\232\183\157\239\188\140\230\151\160\230\179\149\230\129\162\229\164\141\228\189\141\231\189\174", RecoverDist)
    return
  end
  self:SetActorLocation(self.PlayerLoc)
  self:SetActorRotation(self.PlayerRot)
  if self.PlayerLoc then
    Log.Debug("\228\189\141\231\189\174\230\129\162\229\164\141\230\151\165\229\191\151: RecoverPlayerPos", RecoverDist, self.isLocal, self.PlayerLoc.X, self.PlayerLoc.Y, self.PlayerLoc.Z)
  end
  self.PlayerLoc = nil
  self.PlayerRot = nil
end

function ScenePlayerBase:ForgetPlayerPos()
  self.PlayerLoc = nil
  self.PlayerRot = nil
end

function ScenePlayerBase:PausePlayerMovement(caller, isPaused, flag)
  if UE.UObject.IsValid(self.viewObj) then
    self:SetCharacterMovementTickEnable(self, not isPaused)
    if self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet.CharacterMovement:SetComponentTickEnabled(not isPaused)
      end
    end
  end
end

function ScenePlayerBase:SetCharacterMovementTickEnable(caller, enable, flag)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj.CharacterMovement:SetComponentTickEnabled(enable)
  end
end

function ScenePlayerBase:CastG6AbilityAsync(skillPath, caster, characters, targets, isPassive)
  local selfCaster = self.viewObj
  local skillComponent = selfCaster.RocoSkill
  local skillProxy = RocoSkillProxy.Create(skillPath, skillComponent, PriorityEnum.Active_Player_CastSkill)
  if not skillProxy then
    return
  end
  local priority = self.isLocal and _G.PriorityEnum.Local_Player_Logic or _G.PriorityEnum.Other_Player_Logic
  caster = caster or selfCaster
  characters = characters or {}
  targets = targets or {}
  isPassive = isPassive or false
  skillProxy.Priority = priority
  skillProxy:SetCaster(caster)
  skillProxy:SetCharacters(characters)
  skillProxy:SetTargets(targets)
  skillProxy:SetPassive(isPassive)
  skillProxy:SetForcePlayPassive(isPassive)
  skillProxy:PlaySkill()
  return skillProxy
end

function ScenePlayerBase:SetHeadLookAtActorIfOverride(TargetActor, Immediately, NeedTurnBody)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if not HeadLookAtComponent then
    Log.Error("HeadLookAtComponent is nil")
    return
  end
  local Priority = UE4.ELookAtPriority.TakePhoto
  if TargetActor then
    HeadLookAtComponent:EnableManualOverride(Priority)
    HeadLookAtComponent:SetAutoLookAtParam(UE4.ELookAtParamType.Target, TargetActor, nil, nil, nil, nil, nil, Priority)
    HeadLookAtComponent:ActiveAutoLookAt(Immediately, "locator_head", nil, not NeedTurnBody, true)
  else
    HeadLookAtComponent:DisableManualOverride(Immediately, Priority)
  end
end

function ScenePlayerBase:CanPlayIdlePerform()
  if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF) then
    return false
  end
  local viewObj = self.viewObj
  if UE.UObject.IsValid(viewObj) and viewObj.bActiveIdle then
    return false
  end
  if viewObj.AnimComponent and not self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX) and viewObj.AnimComponent:IsAnyAnimPlaying() then
    return false
  end
  if not self.LogicStatusComponent:GetStatus(Enum.SpaceActorLogicStatus.SALS_PLAYER_IDLE) and not self.LogicStatusComponent:GetStatus(Enum.SpaceActorLogicStatus.SALS_PLAYER_AFK) then
    return false
  end
  return true
end

function ScenePlayerBase:IsDead()
  return self.statusComponent and self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
end

function ScenePlayerBase:Land()
  if UE.UObject.IsValid(self.viewObj) then
    local bLanded = self.viewObj.CharacterMovement:Abs_Land(self:GetActorLocation())
  end
end

function ScenePlayerBase:OnFallOff()
  if self.FallOffHandle then
    return
  end
  self.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLOFF)
  self.FallOffHandle = DelayManager:DelaySeconds(1.5, function()
    self.FallOffHandle = nil
    self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLOFF)
  end)
end

function ScenePlayerBase:LandPos(pos)
  local PlatformActorID = self.serverData.base.platform_actor_id or 0
  if 0 == PlatformActorID then
    if self.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL) or self.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_CLIMB) then
      Log.Debug("[SceneLocalPlayer]   OnPlayerBorn Skip Land When Ride or Climb")
    else
      if UE.UObject.IsValid(self.viewObj) then
        local bLanded = self.viewObj.CharacterMovement:Abs_Land(pos)
        if not bLanded then
          Log.Debug("[SceneLocalPlayer]   OnPlayerBorn LandPos Failed", pos)
          return false
        end
      end
      Log.Debug("[SceneLocalPlayer] platform_actor_id = 0, OnPlayerBorn LandPos ", pos, PlatformActorID)
      return true
    end
  else
    Log.Debug("[SceneLocalPlayer]   OnPlayerBorn LandPos PlatformActorID", PlatformActorID)
  end
  return false
end

return ScenePlayerBase
