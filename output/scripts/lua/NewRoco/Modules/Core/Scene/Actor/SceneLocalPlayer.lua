local Base = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerBase")
local InputComp = require("NewRoco.Modules.Core.Scene.Component.Input.InputComponent")
local AbilityComp = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityComponent")
local PlayerInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PlayerInteractionComponent")
local MovementComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.MovementComponent")
local FSMComponent = require("NewRoco.Modules.Core.Scene.Component.FSM.Player.PlayerFSMComponent")
local StatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.StatusComponent")
local StatComponent = require("NewRoco.Modules.Core.Scene.Component.Stat.StatComponent")
local VitalityComponent = require("NewRoco.Modules.Core.Scene.Component.Vitality.VitalityComponentNew")
local RoleHPComponent = require("NewRoco.Modules.Core.Scene.Component.RoleHP.RoleHPComponent")
local TeleportComponent = require("NewRoco.Modules.Core.Scene.Component.RoleHP.TeleportComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ScenePlayerFsmEnum = require("NewRoco.Modules.Core.Scene.Component.FSM.Player.PlayerFsmEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local PlayerThrowInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PlayerThrowInteractionComponent")
local AuraComponent = require("NewRoco.Modules.Core.Scene.Component.Aura.AuraComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TemperatureComponent = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureComponent")
local ThrowManagementComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.ThrowManagementComponent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local CrouchComponent = require("NewRoco.Modules.Core.Scene.Component.CrouchComponent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PetSensingComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetSensingComponent")
local PetSensingActivelyComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetSensingActivelyComponent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local ClimbComponent = require("NewRoco.Modules.Core.Scene.Component.ClimbComponent")
local SummonPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SummonPetComponent")
local FadeComponent = require("NewRoco.Modules.Core.Scene.Component.Fade.FadeComponent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local NPCPressureComponent = require("NewRoco.Modules.Core.Scene.Component.NPCPressureComponent")
local RolePlayComponent = require("NewRoco.Modules.Core.Scene.Component.RolePlay.RolePlayComponent")
local Player2PlayerInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.Player2PlayerInteractionComponent")
local CaveComponent = require("NewRoco.Modules.Core.Scene.Component.Cave.CaveComponent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local PlayerModuleEnum = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEnum")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local DeviceEvent = require("NewRoco.Modules.Core.App.DeviceEvent")
local OwlStarStorageComponent = require("NewRoco.Modules.Core.Scene.Component.OwlStarNotification.OwlStarStorageComponent")
local SocialComponent = require("NewRoco.Modules.Core.Scene.Component.Social.SocialComponent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local InviteComponent = require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent")
local SyncSqrDistance = 40000
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local RideFriendPetBuff = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerRideFriendPetBuff")
local TakePhotoComponent = require("NewRoco.Modules.Core.Scene.Component.TakePhoto.TakePhotoComponent")
local BitSwitch = require("Utils.BitSwitch")
local StringCache = require("Utils.StringCache")
local TogetherSyncComponent = require("NewRoco.Modules.Core.Scene.Component.TogetherSync.TogetherSyncComponent")
local CatchRecordComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchRecordComponent")
local StoryFlagModuleEvent = require("NewRoco.Modules.System.StoryFlag.StoryFlagModuleEvent")
local HUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.LocalPlayerHUDComponent")
local AbnormalStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusComponent")
local ResonanceComponent = require("NewRoco.Modules.Core.Scene.Component.ResonanceComponent")
local SceneLocalPlayer = Base:Extend("SceneLocalPlayer")
SceneLocalPlayer:SetMemberCount(32)

function SceneLocalPlayer:PreCtor(module)
  Base.PreCtor(self, module)
  self.AddBloodChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel
  })
  self.AddEnergyChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel
  })
  self.AddRoleHPChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.FullScreen,
    StatusCheckerEnum.Catch,
    StatusCheckerEnum.Loading,
    StatusCheckerEnum.AlchemyIdle
  }, Log.LOG_LEVEL.ELogInfo, "AddRoleHPChecker")
  self.ReduceRoleHPChecker = StatusCheckerGroup({
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.FullScreen
  })
  self.AddRoleHPMaxChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.FullScreen,
    StatusCheckerEnum.Loading,
    StatusCheckerEnum.AlchemyIdle
  }, Log.LOG_LEVEL.ELogInfo, "AddRoleHPMaxChecker")
  self.AddBattleEndEnergyChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel
  })
  self.AddCathPetChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel
  })
  self.AddLobbyDownTipsChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel,
    StatusCheckerEnum.Catch,
    StatusCheckerEnum.Cinematic
  }, Log.LOG_LEVEL.ELogDebug, "AddLobbyDownTipsChecker")
  self.VisitorTeleportChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.FullScreen,
    StatusCheckerEnum.Loading
  })
  self.isLocal = true
  self.cachePlayerTransform = UE4.FTransform()
  self.cachePlayerTranslation = UE4.FVector()
  self.cachePlayerRotation = UE4.FQuat()
  self.cachePlayerScale = UE4.FVector(1, 1, 1)
  self.cacheCameraRotation = UE4.FRotator()
  self.visibleZoneNum = 0
  self.visibleCircleNum = 0
  self._bornPos = nil
end

function SceneLocalPlayer:Ctor(module)
  Base.Ctor(self, module)
  self:BindUPlayer()
  self:AddListener()
  self:HandleEnvMask()
  self:PreLoadAsset()
  self:GetUEController().PlayerCameraManager:RefreshPCCameraRotateSetting()
end

function SceneLocalPlayer:AddListener()
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.PostLoadMapWithWorld)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, DialogueModuleEvent.DialogueStarted, self.OnDialogueStart)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.DeleteRelationTreeRequestHUD)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, RelationTreeEvent.RELATION_UPDATE_MYREQUES, self.DeleteRelationTreeRequestHUD)
  _G.NRCEventCenter:RegisterEvent("SceneLocalPlayer", self, RelationTreeEvent.UPDATE_RELATION_BUBBLE_DIS, self.UpdateMyRelationTreeRequestByDis)
  DeviceUtils.EventDispatcher:AddEventListener(self, DeviceEvent.OnQualityChange, self.OnQualityChange)
  self:AddEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.HandleEnvMask)
end

function SceneLocalPlayer:RemoveListener()
  self:RemoveEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.HandleEnvMask)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.PostLoadMapWithWorld)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueStarted, self.OnDialogueStart)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_UPDATE_MYREQUES, self.DeleteRelationTreeRequestHUD)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.DeleteRelationTreeRequestHUD)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.UPDATE_RELATION_BUBBLE_DIS, self.UpdateMyRelationTreeRequestByDis)
  DeviceUtils.EventDispatcher:RemoveEventListener(self, DeviceEvent.OnQualityChange, self.OnQualityChange)
  local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule and MainUIModule:HasPanel("LobbyMain") then
    local LobbyMain = MainUIModule:GetPanel("LobbyMain")
    LobbyMain:UnBindPlayerWorldPlayerStatusChange()
  end
end

function SceneLocalPlayer:Destroy()
  self:RemoveListener()
  Base.Destroy(self)
end

function SceneLocalPlayer:OnDestroyedByEngine()
  self:RemoveListener()
  self:RemoveAllComponent()
  Base.OnDestroyedByEngine(self)
end

function SceneLocalPlayer:BindUPlayer()
  self._localPlayer = UE4.UNRCPlatformGameInstance.GetInstance():GetDefaultPlayer()
  self.ueController = self._localPlayer.PlayerController
  Log.Debug("SceneLocalPlayer:BindUPlayer ueController= ", self.ueController and self.ueController:GetName() or "nil")
  self:SetViewObj(self.ueController.Pawn)
  Log.Debug("SceneLocalPlayer:BindUPlayer ueController.Pawn= ", self.viewObj and self.viewObj:GetName() or "nil")
  if self.ueController.BP_RocoCameraControlComponent then
    self.ueController.BP_RocoCameraControlComponent:AddEventListener()
  end
  if self.serverData then
    self:RemoveAllComponent()
    self:InitComponent()
  end
  local bHasLoading = _G.LoadingUIModuleCmd and _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.HasAnyLoadingUI)
  if bHasLoading then
    self:SetCharacterMovementTickEnable(self, false, "SceneLocalPlayer-BindUPlayer-HasLoading")
  end
  self:OnQualityChange()
  self:UpdateRelationTreeRequestHUD()
  if _G.AppMain:HasDebug() and NRCModuleManager:DoCmd(DebugModuleCmd.CheckIsInPhotoEditorMode) then
    self.viewObj.CharacterMovement.GravityScale = 0
    self:SetViewVisible(false)
  end
end

function SceneLocalPlayer:OnQualityChange()
  if UE.UObject.IsValid(self.viewObj) and DeviceUtils.ImageQuality then
    local forcedLod = 1
    if DeviceUtils.ImageQuality < 3 then
      forcedLod = 2
    end
    Log.DebugFormat("SceneLocalPlayer OnQualityChange ImageQuality(%d) ForcedLod(%d)", DeviceUtils.ImageQuality, forcedLod)
    self.viewObj.Mesh.ForcedLodModel = forcedLod
  else
    Log.DebugFormat("SceneLocalPlayer OnQualityChange SetForcedLod Failed")
  end
end

function SceneLocalPlayer:GetUEController()
  return self.ueController
end

function SceneLocalPlayer:PostLoadMapWithWorld(World)
  UE4Helper.PrintScreenMsg("SceneLocalPlayer rebind player")
  self:BindUPlayer()
end

function SceneLocalPlayer:Update(DeltaTime)
  Base.Update(self, DeltaTime)
  self:UpdateCachePlayerTransform()
  self:UpdateCacheCameraRotation()
  if not BattleManager:IsInBattle() then
    self:UpdatePlayerPet(DeltaTime)
  end
end

function SceneLocalPlayer:UpdatePlayerPet(DeltaTime)
  if not UE.UObject.IsValid(self.viewObj) then
    return
  end
  local pets = DataModelMgr.PlayerDataModel.pets
  if pets then
    for k, pet in pairs(pets) do
      pet:Update(DeltaTime)
    end
  end
end

function SceneLocalPlayer:SetHeadLookAtActor(TargetActor)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent then
    if GlobalConfig.LookAtLog then
      Log.Debug("SceneLocalPlayer:SetHeadLookAtActor", TargetActor and UE.UObject.IsValid(TargetActor) and TargetActor:GetName())
    end
    HeadLookAtComponent:ResetAutoLookAt()
    if TargetActor then
      HeadLookAtComponent:SetAutoLookAtParam(UE4.ELookAtParamType.Target, TargetActor)
    end
  end
end

function SceneLocalPlayer:OnInteractionLookAt(Target, bIsLeave)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent then
    HeadLookAtComponent:OnInteractionLookAt(Target, bIsLeave)
  end
end

function SceneLocalPlayer:OnRelationTreeTargetChanged(Target)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent then
    HeadLookAtComponent:OnRelationTreeTargetChanged(Target)
  end
end

function SceneLocalPlayer:OnDisConnect()
  if DataModelMgr.PlayerDataModel.pets then
    for k, v in pairs(DataModelMgr.PlayerDataModel.pets) do
      if v and not v:IsInRide() then
        DataModelMgr.PlayerDataModel.pets[k] = nil
      end
    end
  end
  Base.OnDisConnect(self)
end

function SceneLocalPlayer:SetViewObj(ViewObj)
  Base.SetViewObj(self, ViewObj)
  if ViewObj and 0 ~= self.BuffSpeedScale and 1 ~= self.BuffSpeedScale then
    ViewObj.CustomTimeDilation = self.BuffSpeedScale
  end
end

function SceneLocalPlayer:InitData(config, serverData)
  self.isTeleporting = false
  self.config = config
  self.serverData = serverData
  self:InitComponent()
  DataModelMgr.PlayerDataModel:RebindPlayerPetOwner(self)
end

function SceneLocalPlayer:UpdateServerData(ServerData)
  Base.UpdateServerData(self, ServerData)
  if self.vitalityComponent then
    self.vitalityComponent:SyncVitality(ServerData)
  end
end

function SceneLocalPlayer:GetPetByGid(gid)
  if gid then
    return DataModelMgr.PlayerDataModel:GetPetByGid(gid)
  end
  return nil
end

function SceneLocalPlayer:OnLeaveBattle()
  if self.viewObj.BP_RideComponent then
    local ridePet = self.viewObj.BP_RideComponent.RidePet
    if ridePet then
      ridePet.RocoMoveFx:ReStartMoveFx()
    end
  end
  local isSwimming = self.viewObj.CharacterMovement:IsSwimming()
  if isSwimming then
    self.viewObj.MoveFXComponent:SetVisible(true)
  end
end

function SceneLocalPlayer:OnEnterBattle()
  Log.Debug("SceneLocalPlayer:OnEnterBattle")
  local bloodHud = self.viewObj.BloodWidget:GetUserWidgetObject()
  if bloodHud and bloodHud.ResetEffect then
    bloodHud:ResetEffect()
  else
    Log.Warning("no bloodHud")
  end
  self:SetSwimFxVisible(false, "EnterBattle")
end

function SceneLocalPlayer:CheckLandLoaded(timeOutTime)
  if timeOutTime then
    self.waitLandLoadTime = timeOutTime
  else
    self.waitLandLoadTime = 0
  end
  self:_DoCheckLandLoaded()
end

function SceneLocalPlayer:_DoCheckLandLoaded()
  local landPos = SceneUtils.GetPosInLand(self:GetActorLocation(), self:GetHalfHeight())
  if landPos then
    self:OnPlayerTeleportEnd()
  else
    Log.Debug("SceneLocalPlayer:_DoCheckLandLoaded false")
    if self.waitLandLoadTime > 10 then
      self:OnPlayerTeleportEnd()
    else
      self.waitLandLoadTime = self.waitLandLoadTime + 0.1
      _G.DelayManager:DelaySeconds(0.1, self._DoCheckLandLoaded, self)
    end
  end
end

function SceneLocalPlayer:WaitTilStreamingDone(pos, waitTime)
  local streamingLoading = UE4.UNRCStatics.StreamingLevelIsLoading(_G.UE4Helper.GetCurrentWorld())
  if not waitTime then
    pos.Z = pos.Z + 1
    waitTime = 0
  end
  Base.SetActorLocation(self, pos)
  if not streamingLoading or waitTime > 100 then
    Log.Error("Waited for level streaming for " .. tostring(waitTime))
    self:SetActorLocation(pos)
    UE4Helper.SetEnableWorldRendering(true)
    self.viewObj.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Walking)
    self:SetCharacterMovementTickEnable(self, true)
    Log.Debug("SceneLocalPlayer:WaitTilStreamingDone CharacterMovement:SetComponentTickEnabled(true)!")
    self.viewObj:SetActorTickEnabled(true)
    NRCEventCenter:DispatchEvent(SceneEvent.OnVisibleLevelLoaded)
    SceneUtils.debugCloseNPCModuleTick = false
    self.isTeleporting = false
    NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportFinish)
    UE4.UNRCBattleFieldDataManager.Update(false)
  else
    _G.DelayManager:DelaySeconds(1, function()
      self:WaitTilStreamingDone(pos, waitTime + 1)
    end, self)
  end
end

function SceneLocalPlayer:TeleportAndWaitForLevelLoaded(pos)
  if not pos then
    return
  end
  SceneUtils.debugCloseNPCModuleTick = true
  Log.Debug("[SceneLocalPlayer]   TeleportAndWaitForLevelLoaded", pos)
  self.viewObj.CharacterMovement:SetMovementMode(UE4.EMovementMode.Move_None)
  UE4Helper.SetEnableWorldRendering(false)
  local curLocation = self.viewObj:Abs_K2_GetActorLocation()
  local distance = UE4.FVector.DistSquared(curLocation, pos)
  local isTeleport = distance > 1000000
  local rocoCameraControlComponent = self.ueController.BP_RocoCameraControlComponent
  local adjustCameraLag = isTeleport and rocoCameraControlComponent
  if adjustCameraLag then
    rocoCameraControlComponent:EnableLag(false)
  end
  Base.SetActorLocation(self, pos)
  UE4.UNRCStatics.UpdateStreamingState(_G.UE4Helper.GetCurrentWorld())
  self:WaitTilStreamingDone(pos)
  rocoCameraControlComponent:UpdateCameraPosition()
  if adjustCameraLag then
    rocoCameraControlComponent:EnableLag(true)
  end
end

function SceneLocalPlayer:OnLoadingUIOpen()
  self:DisablePlayerTick(self, "OnLoadingUIOpen")
end

function SceneLocalPlayer:OnLoadingUIClose()
  if _G.CinematicModuleCmd then
    local Playing = _G.NRCModuleManager:DoCmd(_G.CinematicModuleCmd.IsPlaying)
    if Playing then
      return
    end
  end
  self:EnablePlayerTick(self)
end

function SceneLocalPlayer:EnablePlayerTick(caller)
  Log.Debug("SceneLocalPlayer EnablePlayerTick")
  self:SetCharacterMovementTickEnable(caller, true)
  self.viewObj:SetActorTickEnabled(true)
  if self.viewObj.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_None then
    self.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking, UE.ERocoCustomMovementMode.MOVE_N)
  end
  self.vitalityComponent:SetEnable(true)
end

function SceneLocalPlayer:DisablePlayerTick(caller, flag)
  Log.Debug("SceneLocalPlayer DisablePlayerTick")
  self:SetCharacterMovementTickEnable(caller, false, flag)
  self.viewObj:SetActorTickEnabled(false)
  self.vitalityComponent:SetEnable(false)
end

function SceneLocalPlayer:PausePlayerMovement(caller, isPaused, flag)
  if not caller then
    Log.Error("Unable to call PausePlayerMovement without caller")
    return
  end
  self:SetCharacterMovementTickEnable(caller, not isPaused, flag)
  if self.viewObj.BP_RideComponent then
    local ridePet = self.viewObj.BP_RideComponent.RidePet
    if not ridePet and self.viewObj.CharacterMovement.MovementMode == UE.EMovementMode.Move_None then
      self.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking, UE.ERocoCustomMovementMode.MOVE_N)
    end
  end
end

function SceneLocalPlayer:OnPlayerBorn(pos, isReconnect)
  Log.Debug("[SceneLocalPlayer]   OnPlayerBorn Start", pos, isReconnect)
  self:SetCharacterMovementTickEnable(self, false, "OnPlayerBorn")
  self.viewObj:SetActorTickEnabled(false)
  self._bearing = true
  self._bornPos = pos
  self:SetActorLocation(pos)
  self.viewObj.CharacterMovement:ConsumeInputVector()
  self.viewObj.CharacterMovement:StopMovementImmediately()
  if not NRCEnv:IsLocalMode() and self.statusComponent and (not self.statusComponent._isConnected or self.statusComponent._recovering or self.statusComponent._shouldWaitRecover) then
  else
    self._bearing = false
    if self:LandPos(pos) then
      Log.Debug("[SceneLocalPlayer] OnPlayerBorn Set CharacterMovementTick(true) after LandPos successfully.")
      self:SetCharacterMovementTickEnable(self, true, "OnPlayerBorn")
    end
  end
  NRCEventCenter:DispatchEvent(SceneEvent.OnVisibleLevelLoaded)
  self.viewObj:SetActorTickEnabled(true)
  self.isTeleporting = false
  NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportFinish)
  UE4.UNRCBattleFieldDataManager.Update(false)
end

function SceneLocalPlayer:Abs_SpawnPlaneUnderPlayer(location)
  local curLocation = location
  local BP_Plane = UE4.UClass.Load("/Game/Game/NRC/GameMode/AutoTest/BP_Plane.BP_Plane")
  local trans = UE4.FTransform()
  local translation = UE4.FVector()
  translation = curLocation
  translation.z = translation.z - 86
  trans.Translation = translation
  UE4Helper.GetCurrentWorld():Abs_SpawnActor(BP_Plane, trans)
end

function SceneLocalPlayer:OnPlayerTeleport(to_pt)
  Log.Debug("[SceneLocalPlayer]   OnPlayerTeleport [%f,%f,%f]", to_pt.pos.x, to_pt.pos.y, to_pt.pos.z)
  NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 1)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportPreStart)
  self:StopRide(true)
  self:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
  _G.ZoneServer:Pause()
  self.isTeleporting = true
  NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportStart)
  _G.DelayManager:DelaySeconds(0.6, self.TeleportBegin, self, to_pt)
end

function SceneLocalPlayer:TeleportBegin(to_pt)
  NRCModuleManager:DoCmd(MainUIModuleCmd.ClosePanelLobbyMain)
  local serverPos = to_pt.pos
  local dirZ = 0.0
  if to_pt.dir and to_pt.dir.z then
    dirZ = to_pt.dir.z
  end
  local serverRot = UE4.FRotator(0, (dirZ or 0.0) / 10.0, 0)
  local newPos = UE4.FVector(serverPos.x, serverPos.y, (serverPos.z or 0) + 100)
  local oldPos = self:GetActorLocation()
  _G.NRCProfilerLog:NRCTeleportProfilerLog(true, oldPos, newPos)
  if self.viewObj and UE4.UObject.IsValid(self.viewObj) then
    self.viewObj.Mesh:SetEnableGravity(false)
    self:SetCharacterMovementTickEnable(self, false, "TeleportBegin")
    self.viewObj:SetActorTickEnabled(false)
    if UE.UObject.IsValid(self.ueController) then
      self.ueController:SetViewTargetWithBlend(self.viewObj, 0, UE4.EViewTargetBlendFunction.VTBlend_EaseOut, 2)
      self.ueController:SetControlRotation(serverRot)
    end
  end
  self:SetActorLocation(newPos)
  self:SetActorRotation(serverRot)
  self.lastPos = newPos
  self.waitLandLoadTime = 0
  _G.DelayManager:DelaySeconds(2.0, self.OnPlayerTeleportEnd, self)
end

function SceneLocalPlayer:OnPlayerTeleportEnd()
  Log.Debug("SceneLocalPlayer:OnPlayerTeleportEnd")
  if self.viewObj and UE4.UObject.IsValid(self.viewObj) then
    self.viewObj.Mesh:SetEnableGravity(true)
    self:SetCharacterMovementTickEnable(self, true)
    self.viewObj.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Falling, 0)
    self:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
    self.viewObj:SetActorTickEnabled(true)
  end
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.PlayerTeleportLoad)
  _G.DelayManager:DelaySeconds(2, self.OnPlayerTeleportEndEffect, self)
end

function SceneLocalPlayer:OnPlayerTeleportEndEffect()
  NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 1)
  _G.DelayManager:DelaySeconds(1, self.PostTeleport, self)
end

function SceneLocalPlayer:PostTeleport()
  local Reason = self.module.playerModuleNetCenter._bornReason
  if not Reason or Reason ~= ProtoEnum.TeleportReason.ENUM.MINIGAME then
    NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  end
  _G.ZoneServer:Resume()
  self.isTeleporting = false
  NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportFinish)
  UE4.UNRCBattleFieldDataManager.Update(false)
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.TransEffect)
  if not self.viewObj then
    Log.Error("Viewobj is nil, please check")
    return
  end
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\228\188\160\233\128\129\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  Log.Debug("SceneLocalPlayer:CheckLandLoaded play teleport effect")
  self.viewObj.RocoSkill:PlaySkill(skillObj)
  _G.NRCAudioManager:PlaySound2DAuto(1099, "BP_NPCStoneHouse:PlayUnlockEffect")
  _G.NRCProfilerLog:NRCTeleportProfilerLog(false)
end

function SceneLocalPlayer:SetActorLocation(pos)
  if not pos then
    return
  end
  if not UE.UObject.IsValid(self.viewObj) then
    Log.Error("SceneLocalPlayer:SetActorLocation \230\156\172\229\156\176\231\142\169\229\174\182\232\174\190\231\189\174 Actor \228\189\141\231\189\174\230\151\182 viewObj \230\151\160\230\149\136\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  if _G.ZoneServer.ZoneServerGCloud:IsReconnecting() and self.viewObj then
    self.viewObj.CapsuleComponent:SetGenerateOverlapEvents(true)
  end
  Log.Debug("zgx [SceneLocalPlayer]   SetActorLocation", pos)
  local curLocation = self.viewObj:Abs_K2_GetActorLocation()
  local distance = UE4.FVector.DistSquared(curLocation, pos)
  local isTeleport = distance > 1000000
  local rocoCameraControlComponent = self.ueController.BP_RocoCameraControlComponent
  local adjustCameraLag = isTeleport and rocoCameraControlComponent
  if adjustCameraLag then
    rocoCameraControlComponent:EnableLag(false)
  end
  UE4.UNRCStatics.ChangeLevelStreamingMode(1)
  Base.SetActorLocation(self, pos)
  rocoCameraControlComponent:UpdateCameraPosition()
  local gameWorld = UE4Helper.GetCurrentWorld()
  if not NRCEnv:IsLocalMode() then
    if _G.NRCModuleManager:GetModule("MiniGameModule") and _G.MiniGameModuleCmd then
      local NeedPlayNightmareAction = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.NeedPlayNightmareAction)
      if not NeedPlayNightmareAction then
        if gameWorld then
          Log.Debug("[SceneLocalPlayer]   SetActorLocation BlockTillLevelStreamingCompleted start")
          UE4.UNRCStatics.BlockTillLevelStreamingCompleted(gameWorld)
          Log.Debug("[SceneLocalPlayer]   SetActorLocation BlockTillLevelStreamingCompleted end")
        else
          Log.Debug("[SceneLocalPlayer]   SetActorLocation Ignore BlockTillLevelStreamingComleted not GameWorld")
        end
      else
        Log.Debug("[SceneLocalPlayer]   SetActorLocation Ignore BlockTillLevelStreamingComleted ")
      end
    end
  else
    Log.Debug("[SceneLocalPlayer]   SetActorLocation BlockTillLevelStreamingCompleted start 2")
    if gameWorld then
      UE4.UNRCStatics.BlockTillLevelStreamingCompleted(gameWorld)
    else
      Log.Debug("[SceneLocalPlayer]   SetActorLocation Ignore BlockTillLevelStreamingComleted not GameWorld 2")
    end
    Log.Debug("[SceneLocalPlayer]   SetActorLocation BlockTillLevelStreamingCompleted end 2")
  end
  UE4.UNRCBattleFieldDataManager.Update(false)
  UE4.UNRCStatics.ChangeLevelStreamingMode(0)
  if adjustCameraLag then
    rocoCameraControlComponent:EnableLag(true)
  end
  if _G.GlobalConfig.MemoryAutoTest then
    self:Abs_SpawnPlaneUnderPlayer(pos)
  end
end

function SceneLocalPlayer:SetActorRotation(rotate)
  Base.SetActorRotation(self, rotate)
  self.movementComponent:SetIsMovingTagOnce("SetActorRotation")
end

function SceneLocalPlayer:InterPlayBloodAddEffect(notify)
  Log.Debug("SceneLocalPlayer:InterPlayBloodAddEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.BloodEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\229\138\160\232\161\128\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetTargets({
    self.viewObj
  })
  skillObj:RegisterEventCallback("End", self, self.OnPlayBloodAddEffectEnd)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
  if not notify.total_change_hp then
    Log.Warning("ZonePlayerPetHpChangeNotify total_change_hp\229\173\151\230\174\181\228\184\186\231\169\186")
    notify.total_change_hp = -666
  end
  self:InterPlayBloodUIEffect(notify)
  NRCEventCenter:DispatchEvent(SceneEvent.ON_PLAY_PET_ADD_BLOOD_FX)
end

function SceneLocalPlayer:InterPlayBloodUIEffect(notify)
  local bloodHud = self.viewObj.BloodWidget:GetUserWidgetObject()
  if bloodHud then
    if bloodHud.PlayEffect then
      bloodHud:PlayEffect(notify.total_change_hp)
    else
      Log.Error("Effect Not found", bloodHud:GetName())
    end
  else
    Log.Error("Hud not found")
  end
end

function SceneLocalPlayer:PlayBloodAddEffect(notify)
  Log.Debug("SceneLocalPlayer:PlayBloodAddEffect")
  if not self.viewObj then
    Log.Error("SceneLocalPlayer:PlayBloodAddEffect \230\156\172\229\156\176\231\142\169\229\174\182\230\146\173\230\148\190\229\138\160\232\161\128\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewObj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  self.cachedAddBlood = notify
  self.AddBloodChecker:Check(self, self.InternalPlayBloodAddEffect)
end

function SceneLocalPlayer:InternalPlayBloodAddEffect()
  self:InterPlayBloodAddEffect(self.cachedAddBlood)
  self.cachedAddBlood = nil
end

function SceneLocalPlayer:PlayEnergyAddEffect(notify)
  self.cachedAddEnergy = notify
  self.AddEnergyChecker:Check(self, self.InternalPlayAddEnergyEffect)
end

function SceneLocalPlayer:InternalPlayAddEnergyEffect()
  _G.NRCEventCenter:DispatchEvent(SceneEvent.ON_PLAY_ADD_ENERGY_FX, self.cachedAddEnergy)
  self.cachedAddEnergy = nil
end

function SceneLocalPlayer:AddPlayCathPetEffect(event_info)
  self.cachedCathPet = event_info
  self.AddCathPetChecker:Check(self, self.InternalCathPetEffect)
end

function SceneLocalPlayer:InternalCathPetEffect()
  if self.cachedCathPet.bonus_event_pool_cfg_id == nil then
    return
  end
  local bonusType = self.cachedCathPet.bonus_type
  local bUseContainerConf = self:GetCatchTipsTypeInBonusContainerConf(bonusType)
  local cfgId = self.cachedCathPet.bonus_event_pool_cfg_id
  local cfg
  if bUseContainerConf then
    cfg = _G.DataConfigManager:GetBonusContainerConf(cfgId, true)
  else
    cfg = _G.DataConfigManager:GetBonusEventPoolConf(cfgId, true)
  end
  if cfg then
    local soundId = cfg.sound_id
    local time = _G.DataConfigManager:GetGlobalConfigByKeyType("season_continuous_catch_tips_duration", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num / 1000
    if nil == cfg.show_text_type or cfg.show_text_type == "" then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(soundId, "SceneLocalPlayer:InternalCathPetEffect")
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, cfg.show_text, 0, nil, time)
    else
      local Data = {
        soundId = cfg.sound_id,
        umgName = cfg.show_text_type,
        text = cfg.show_text,
        showTime = time
      }
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.OnShowContinuousCatchTip, Data)
    end
    _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.PlayBonusCatchEffect)
  else
    Log.Warning("SceneLocalPlayer:InternalCathPetEffect cfg is nil", bonusType, cfgId)
  end
  self.cachedCathPet = nil
end

function SceneLocalPlayer:GetCatchTipsTypeInBonusContainerConf(type)
  if not type then
    return false
  end
  local conf = _G.DataConfigManager:GetSeasonGlobalConfig(13, true)
  if not conf then
    return false
  end
  local nums = conf.numList
  if not nums then
    return false
  end
  for _, value in pairs(nums) do
    if value == type then
      return true
    end
  end
  return false
end

function SceneLocalPlayer:AddLobbyDownTipsEffect(tipsInfo)
  if self.cachedDownTips == nil then
    self.cachedDownTips = {}
  end
  table.insert(self.cachedDownTips, tipsInfo)
  self.AddLobbyDownTipsChecker:Check(self, self.InternalShowLobbyDownTips)
end

function SceneLocalPlayer:InternalShowLobbyDownTips()
  if self.cachedDownTips == nil or 0 == #self.cachedDownTips then
    return
  end
  for i = 1, #self.cachedDownTips do
    local TipsType = self.cachedDownTips[i].TipsType
    local TipsData = self.cachedDownTips[i].TipsData
    local CmdID = self.cachedDownTips[i].CmdID
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ShowPropTips, TipObject.FormLobbyDownTips(TipsType, TipsData), CmdID)
  end
  self.cachedDownTips = nil
end

function SceneLocalPlayer:AddBattleFinishChecker(notify)
  self.cachedBattleEndEnergy = notify
  self.AddBattleEndEnergyChecker:Check(self, self.InternalPlayAddBattleFinishCheckerEffect)
end

function SceneLocalPlayer:InternalPlayAddBattleFinishCheckerEffect()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnFinshBattleUpdatePetData, self.cachedBattleEndEnergy)
  self.cachedBattleEndEnergy = nil
end

function SceneLocalPlayer:PlayLevelUpEffect()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local levelUpEffect = UE4.UObject.Load(_G.UEPath.BP_LevelUp)
  local playerPos = localPlayer:GetActorLocation()
  UE4.UGameplayStatics.Abs_SpawnEmitterAtLocation(_G.UE4Helper.GetCurrentWorld(), levelUpEffect, playerPos)
  Log.Debug("SceneLocalPlayer:PlayLevelUpEffect")
end

function SceneLocalPlayer:PlayAddRoleHpEffect(AttrTag)
  Log.Debug("SceneLocalPlayer:PlayAddRoleHpEffect")
  if not self.viewObj then
    Log.Error("SceneLocalPlayer:PlayAddRoleHpEffect \230\156\172\229\156\176\231\142\169\229\174\182\230\146\173\230\148\190\229\138\160\232\161\128\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewObj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  if AttrTag == ProtoEnum.AttrPresentTag.ENUM.AIAddHp then
    Log.Debug("SceneLocalPlayer:PlayAIAddRoleHpEffect")
    local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.RoleHPEffect_AIADD)
    local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
    if not skillObj then
      Log.Error("\231\142\169\229\174\182\229\138\160\232\161\128\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
      return
    end
    skillObj:SetPassive(true)
    skillObj:SetCaster(self.viewObj)
    self.viewObj.RocoSkill:PlaySkill(skillObj)
    local tempHp = self.serverData.attrs.hp_temporary or 0
    self:SendEvent(PlayerModuleEvent.ON_ROLE_HP_CHANGE, self.serverData.attrs.hp + tempHp, tempHp)
  else
    self.AddRoleHPChecker:Check(self, self.InternalAddRoleHPEffect)
  end
end

function SceneLocalPlayer:PlayReduceRoleHpEffect()
  Log.Debug("SceneLocalPlayer:PlayReduceRoleHpEffect")
  if not self.viewObj then
    Log.Error("SceneLocalPlayer:PlayReduceRoleHpEffect \230\156\172\229\156\176\231\142\169\229\174\182\230\146\173\230\148\190\230\137\163\232\161\128\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewObj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  self.ReduceRoleHPChecker:Check(self, self.InternalReduceRoleHPEffect)
end

function SceneLocalPlayer:PlayAddRoleHpMaxEffect()
  Log.Debug("SceneLocalPlayer:PlayAddRoleHpMaxEffect")
  if not self.viewObj then
    Log.Error("SceneLocalPlayer:PlayAddRoleHpMaxEffect \230\156\172\229\156\176\231\142\169\229\174\182\230\146\173\230\148\190\229\138\160\232\161\128\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewObj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  self.AddRoleHPMaxChecker:Check(self, self.InternalAddRoleHPMaxEffect)
end

function SceneLocalPlayer:InternalAddRoleHPEffect()
  Log.Debug("SceneLocalPlayer:InternalAddRoleHPEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.RoleHPEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\229\138\160\232\161\128\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
  local tempHp = self.serverData.attrs.hp_temporary or 0
  self:SendEvent(PlayerModuleEvent.ON_ROLE_HP_CHANGE, self.serverData.attrs.hp + tempHp, tempHp)
end

function SceneLocalPlayer:InternalReduceRoleHPEffect()
  Log.Debug("SceneLocalPlayer:InternalReduceRoleHPEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.ReduceHPEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\230\137\163\232\161\128\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
end

function SceneLocalPlayer:InternalAddRoleHPMaxEffect()
  Log.Debug("SceneLocalPlayer:InternalAddRoleHPEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.RoleHPMaxEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\229\138\160\232\161\128\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  skillObj:RegisterRawCallback(self, self.OnRoleHPMaxSkillEvent)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
end

function SceneLocalPlayer:PlayVisitorTeleportEffect()
  if self:IsInTogetherMove() then
    return
  end
  Log.Debug("SceneLocalPlayer:PlayVisitorTeleportEffect")
  if not self.viewObj then
    Log.Error("SceneLocalPlayer:PlayVisitorTeleportEffect \231\142\169\229\174\182\230\146\173\230\148\190\228\188\160\233\128\129\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewobj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  self.VisitorTeleportChecker:Check(self, self.InternalVisitorTeleportEffect)
end

function SceneLocalPlayer:InternalVisitorTeleportEffect()
  Log.Debug("SceneLocalPlayer:InternalVisitorTeleportEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.PlayerAppearEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\228\188\160\233\128\129\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
end

function SceneLocalPlayer:OnRoleHPMaxSkillEvent(event)
  if "AddRoleHP" == event then
    local tempHP = self.serverData.attrs.hp_temporary or 0
    local newRoleHpMax = math.max(self.serverData.attrs.hp_max, tempHP + self.serverData.attrs.hp)
    self:SendEvent(PlayerModuleEvent.ON_ROLE_HP_MAX_CHANGE, newRoleHpMax, tempHP, self.serverData.attrs.hp_max)
    self.roleHPComponent._uiMax = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLE_HP_MAX)
    self:PlayAddRoleHpEffect()
    self.roleHPComponent.inAddMax = false
  end
  if "End" == event and _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_ROLE_HP_MAX) > self.roleHPComponent._uiMax then
    DelayManager:DelaySeconds(0.5, function()
      self:PlayAddRoleHpMaxEffect()
    end)
  end
end

function SceneLocalPlayer:CheckPosAndNotifyNPCModule(disSquared)
end

function SceneLocalPlayer:Check2SyncPos()
  if self.serverData == nil then
    return
  end
  if nil == self.lastPos then
    self.lastPos = self:GetActorLocation()
  else
    local curPos = self:GetActorLocation()
    local deltaSquared = UE4.FVector.DistSquared(curPos, self.lastPos)
    if deltaSquared > SyncSqrDistance then
      local targetPos = SceneUtils.ClientPos2ServerPos(curPos)
      local req = ProtoMessage:newZoneSceneMoveReq()
      req.to_pos.x = targetPos.x
      req.to_pos.y = targetPos.y
      req.to_pos.z = targetPos.z
      self.lastPos = curPos
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOVE_REQ, req, self, self.OnMoveRsp, false, false)
    else
      self.moveDeltaSqr = deltaSquared
    end
  end
end

function SceneLocalPlayer:OnMoveRsp(rsp)
end

function SceneLocalPlayer:InitComponent()
  self.statusComponent = StatusComponent()
  self:AddComponent(self.statusComponent)
  Base.InitComponent(self)
  self.inputComponent = InputComp()
  self:AddComponent(self.inputComponent)
  self.interactionComponent = PlayerInteractionComponent()
  self:AddComponent(self.interactionComponent)
  self.vitalityComponent = VitalityComponent()
  self:AddComponent(self.vitalityComponent)
  self.roleHPComponent = RoleHPComponent()
  self:AddComponent(self.roleHPComponent)
  self.teleportComponent = TeleportComponent()
  self:AddComponent(self.teleportComponent)
  self.movementComponent = MovementComponent()
  self:AddComponent(self.movementComponent)
  self.LocalPlayerHUDComponent = HUDComponent()
  self:AddComponent(self.LocalPlayerHUDComponent)
  self:EnsureComponent(ThrowManagementComponent)
  self.abilityComponent = AbilityComp()
  self:AddComponent(self.abilityComponent)
  self:EnsureComponent(PlayerThrowInteractionComponent)
  self:EnsureComponent(AuraComponent)
  self:EnsureComponent(CrouchComponent)
  self:EnsureComponent(PetSensingComponent)
  self:EnsureComponent(PetSensingActivelyComponent)
  self:EnsureComponent(ClimbComponent)
  self:EnsureComponent(SummonPetComponent)
  self:EnsureComponent(FadeComponent)
  if _G.GlobalConfig.bNPCPressureTest then
    self:EnsureComponent(NPCPressureComponent)
  end
  self:EnsureComponent(RolePlayComponent)
  self:EnsureComponent(Player2PlayerInteractionComponent)
  if not NRCEnv:IsLocalMode() then
    self:EnsureComponent(TemperatureComponent)
    self:EnsureComponent(CaveComponent)
    self:EnsureComponent(InviteComponent)
  end
  self.owlStarStorageComponent = self:EnsureComponent(OwlStarStorageComponent)
  self.socialComponent = self:EnsureComponent(SocialComponent)
  self:EnsureComponent(TogetherSyncComponent)
  self:EnsureComponent(CatchRecordComponent)
  self:EnsureComponent(AbnormalStatusComponent)
  self:EnsureComponent(ResonanceComponent)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent then
    HeadLookAtComponent:SetPlayer(self)
  end
end

function SceneLocalPlayer:UpdateCachePlayerTransform()
  if self.viewObj then
    self:GetActorTransformInplace(self.cachePlayerTransform, self.cachePlayerTranslation, self.cachePlayerRotation, self.cachePlayerScale)
  end
end

function SceneLocalPlayer:GetActorTransformFrameCache()
  if self.cachePlayerTransform then
    return self.cachePlayerTransform
  end
  return UE4.FTransform()
end

function SceneLocalPlayer:GetActorLocationFrameCache()
  if self.cachePlayerTranslation then
    return self.cachePlayerTranslation
  end
  return UE4.FVector(0, 0, 0)
end

function SceneLocalPlayer:GetActorRotationFrameCache()
  if self.cachePlayerRotation then
    return self.cachePlayerRotation
  end
  return UE4.FQuat()
end

function SceneLocalPlayer:UpdateCacheCameraRotation()
  if UE.UObject.IsValid(self.ueController) and self.ueController.PlayerCameraManager then
    UE4.UNRCStatics.K2_GetActorRotationInplace(self.ueController.PlayerCameraManager, self.cacheCameraRotation)
  end
end

function SceneLocalPlayer:GetCameraRotationYFrameCache()
  if self.cacheCameraRotation then
    return self.cacheCameraRotation.Yaw
  end
  return 0
end

function SceneLocalPlayer:GetServerId()
  if self.serverData and self.serverData.base then
    return self.serverData.base.actor_id
  end
  return 0
end

function SceneLocalPlayer:SetCharacterGender(gender)
  Base.SetCharacterGender(self, gender)
  GlobalConfig.CharacterIndex = gender
  self.viewObj:SetGender(gender)
  self:UpdateShoesSoundSwitch()
end

function SceneLocalPlayer:RestoreViewTarget(blendTime, blendFunc, blendExp, lockOutgoing)
  if self.ueController then
    self.ueController:SetViewTargetWithBlend(self.ueController.CameraActor, blendTime, blendFunc, blendExp, lockOutgoing)
  end
end

function SceneLocalPlayer:StopRide(DisablePerform, OnFinished)
  Base.StopRide(self, DisablePerform, OnFinished)
  if DisablePerform and self.ueController and self.ueController.PlayerCameraManager then
    self.ueController.PlayerCameraManager:Reset(false)
  end
end

function SceneLocalPlayer:OnDialogueStart()
  self.movementComponent:SetEnable(false)
end

function SceneLocalPlayer:OnDialogueEnded()
  self.movementComponent:SetEnable(true)
end

function SceneLocalPlayer:ToggleRootMotion(enable)
  local playerBP = self.viewObj
  if playerBP then
    playerBP.UseRMLocomotion = enable
    playerBP.bUseRMLocomotion = enable
  end
end

function SceneLocalPlayer:HandleEnvMask()
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  if not self.viewObj then
    return
  end
  local envMask = DataModelMgr.PlayerDataModel.envMask
  if envMask == ProtoEnum.SceneAbilityDisableCode.SADC_DUNGEON or envMask == ProtoEnum.SceneAbilityDisableCode.SADC_INDOOR then
    self.viewObj.BP_SceneFxComponent:Stop()
  else
    self.viewObj.BP_SceneFxComponent:Start()
  end
end

function SceneLocalPlayer:Land()
  if UE.UObject.IsValid(self.viewObj) then
    local bLanded = self.viewObj.CharacterMovement:Abs_Land(self:GetActorLocation())
    if not bLanded then
      Log.Debug("SceneLocalPlayer:Land Failed")
    end
  end
end

function SceneLocalPlayer:CanLazySyncMove()
  if self:IsInTogetherMove() then
    return false
  end
  local inVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if inVisit then
    return false
  end
  if self.visibleZoneNum > 0 or self.visibleCircleNum > 0 then
    return false
  end
  if _G.NRCModuleManager:IsModuleActive("MagicReplayModule") and _G.MagicReplayModuleCmd and _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.IsNetRecording) then
    return false
  end
  local npcModule = _G.NRCModuleManager:GetModule("NPCModule")
  if _G.WorldCombatModuleCmd and npcModule then
    local bInWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInWorldCombat)
    local serverAICount = npcModule:GetServerAICount()
    if bInWorldCombat or serverAICount > 0 then
      return false
    end
  end
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InHomeIndoor() or _G.FarmModuleCmd and _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
    return false
  end
  return true
end

function SceneLocalPlayer:OnAvatarComplete()
  self.FadeComponent:ForceUpdate()
  self.statusComponent:RecoverAllStatus()
  self.statusComponent:ResetViewObjMovementStatus()
  if _G.AppearanceModuleCmd then
    self:ChangeDefaultWand(_G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId, self.serverData))
  end
  Base.OnAvatarComplete(self)
end

function SceneLocalPlayer:GetControlPawnCapsuleSize()
  local View = self.viewObj
  local RideComp = View and View.BP_RideComponent
  local RidePet = RideComp and RideComp.RidePet
  if not UE.UObject.IsValid(RidePet) then
    local Capsule = View.CapsuleComponent
    if not Capsule or not UE.UObject.IsValid(Capsule) then
      return 86, 45
    end
    return Capsule:GetScaledCapsuleHalfHeight(), Capsule:GetScaledCapsuleRadius()
  end
  local Scale = RidePet:GetActorScale3D().X
  local PetCapsule = RidePet.CapsuleComponent
  return Scale * PetCapsule:GetUnscaledCapsuleHalfHeight(), Scale * PetCapsule:GetUnscaledCapsuleRadius()
end

function SceneLocalPlayer:PreLoadAsset()
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.TransEffect)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.BloodEffect)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.RoleHPEffect_AIADD)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.RoleHPEffect)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.ReduceHPEffect)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.RoleHPMaxEffect)
  NPCLuaUtils.PreLoad(UEPath.PLAYER_EFFECT.PlayerAppearEffect)
  self._defaultWand = "SkeletalMesh'/Game/ArtRes/AnimSequence/Human/PC/PC3/Avatar/Mw/32500101/SKM_PC3_Mw_32500101.SKM_PC3_Mw_32500101'"
  NPCLuaUtils.PreLoad(self._defaultWand, PriorityEnum.Local_Player_Logic)
end

function SceneLocalPlayer:ChangeDefaultWand(ID)
  if type(ID) ~= "number" then
    return
  end
  local wandConf = self:GetWandConf(ID)
  if wandConf and wandConf.WandMesh ~= "" then
    self._defaultWand = string.format("%s%s%s", "SkeletalMesh'", wandConf.WandMesh, "'")
    NPCLuaUtils.PreLoad(self._defaultWand, PriorityEnum.Local_Player_Logic)
  end
end

function SceneLocalPlayer:ModifyMoveSpeedByBuff(SpeedRate)
  Base.ModifyMoveSpeedByBuff(self, SpeedRate)
  if self.viewObj then
    self.viewObj.CustomTimeDilation = SpeedRate
  end
end

function SceneLocalPlayer:OnReConnect(bLight)
  Base.OnReConnect(self, bLight)
  self:InitPetInfoMap()
  _G.DataModelMgr.PlayerDataModel:ResetPetFriendRideState()
  self:SendEvent(PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE)
end

function SceneLocalPlayer:LandOnActor(actorViewObj)
  if actorViewObj and actorViewObj.sceneCharacter then
    local bornPt = self.serverData.base.pt.pos
    local startPos = SceneUtils.ServerPos2ClientPos(bornPt)
    startPos.Z = startPos.Z + 80
    Log.Debug("[SceneLocalPlayer][LandOnActor] Start:", self:GetActorLocation(), bornPt.x, bornPt.y, bornPt.z, actorViewObj:GetName(), "platform_actor_id", actorViewObj.sceneCharacter.serverData.base.actor_id)
    if UE.UObject.IsValid(self.viewObj) then
      local LandPos, HitActor = self.viewObj.CharacterMovement:Abs_GetLandOnActorPos(startPos)
      Log.Debug("[SceneLocalPlayer][LandOnActor] Abs_GetLandOnActorPos:", LandPos, HitActor and HitActor:GetName() or "nil", "platform_actor_id")
      if HitActor and UE.UObject.IsValid(HitActor) and HitActor == actorViewObj then
        Log.Debug("[SceneLocalPlayer][LandOnActor], Find a new position on Actor ", LandPos, "platform_actor_id", actorViewObj.sceneCharacter.serverData.base.actor_id)
        Base.SetActorLocation(self, LandPos)
        self:ForceSendMoveReq(false, actorViewObj.sceneCharacter.serverData.base.actor_id)
      end
    end
  end
end

function SceneLocalPlayer:LandPos(pos)
  return Base.LandPos(self, pos)
end

function SceneLocalPlayer:ForceSendMoveReq(bIgnorePlatformActor, platform_actor_id)
  if _G.BattleManager and _G.BattleManager:IsInBattle() then
    return
  end
  if self.isLocal and self.movementComponent then
    self.movementComponent:SendMoveReqImmediately(bIgnorePlatformActor, platform_actor_id)
  end
end

function SceneLocalPlayer:UpdateShoesSoundSwitch()
  local switchName = "Default"
  if UE.UObject.IsValid(self.viewObj) then
    local shoesId = self:GetWearIdByType(true, Enum.FashionLabelType.FLT_SHOES)
    if shoesId then
      local shoesConf = _G.DataConfigManager:GetFashionItemConf(shoesId)
      if shoesConf then
        local shoesType = shoesConf.shoes_type
        if shoesType == Enum.ShoesSoundEffect.SSE_HEEL then
          switchName = "Heel"
        elseif shoesType == Enum.ShoesSoundEffect.SSE_IRON then
          switchName = "Iron"
        elseif shoesType == Enum.ShoesSoundEffect.SSE_SLIPPER then
          switchName = "Slipper"
        else
          switchName = "Default"
        end
      else
        switchName = "Foot"
      end
    else
      switchName = "Foot"
    end
  end
  self.viewObj.ShoesSoundName = switchName
end

function SceneLocalPlayer:AddOwlStarInfo(owlStarInfo)
  Log.Info("SceneLocalPlayer:AddOwlStarInfo ", owlStarInfo.npc_obj_id, owlStarInfo.npc_cfg_id)
  self.owlStarStorageComponent:AddOwlStarInfo(owlStarInfo)
end

function SceneLocalPlayer:RemoveOwlStarInfo(npc_obj_id, npc_cfg_id)
  Log.Info("SceneLocalPlayer:RemoveOwlStarBornPointInfo ", npc_obj_id, npc_cfg_id)
  self.owlStarStorageComponent:RemoveOwlStarInfo(npc_obj_id, npc_cfg_id)
end

function SceneLocalPlayer:UpdateOwlStarDistanceState(npc_obj_id, npc_cfg_id, in_distance_range)
  Log.Info("SceneLocalPlayer:UpdateOwlStarBornPointDistanceState ", npc_obj_id, npc_cfg_id, in_distance_range)
  return self.owlStarStorageComponent:UpdateOwlStarDistanceState(npc_obj_id, npc_cfg_id, in_distance_range)
end

function SceneLocalPlayer:GetOwlStarInfos()
  return self.owlStarStorageComponent:GetOwlStarInfos()
end

function SceneLocalPlayer:GetPlayerHomeInfo(isSelf)
  if not self.serverData or not self.serverData.home_basic_info then
    return nil
  end
  if not isSelf then
    return self.serverData.home_basic_info.target_home_info or self.serverData.home_basic_info.my_home_info
  else
    return self.serverData.home_basic_info.my_home_info
  end
end

function SceneLocalPlayer:ClearTaskAreaCache()
  self.taskAreaRideAllBanType = {}
  self.taskAreaRideAllBanTaskIds = {}
end

function SceneLocalPlayer:CheckTaskAreaRideAllBanType()
  if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    local rideComponent = self.viewObj.BP_RideComponent
    if rideComponent and rideComponent.ScenePet and rideComponent.RidePet then
      local petID = rideComponent.ScenePet.config and rideComponent.ScenePet.config.id or 0
      if petID and 0 ~= petID then
        local isBanRide = false
        local MovementList = DataConfigManager:GetAllRidePet(petID).basic_movement_list
        for _, MovementId in pairs(MovementList) do
          local MoveConf = DataConfigManager:GetRideBasicMovement(MovementId)
          if self.taskAreaRideAllBanType[MoveConf.move_type] then
            isBanRide = true
            break
          end
        end
        if isBanRide then
          if rideComponent.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_FLY then
            rideComponent.RidePet.CharacterMovement:SetMovementParamByName(6, "bLazyMode", "true")
          elseif 0 == rideComponent.RideMoveType and rideComponent.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Falling then
            rideComponent.DelayStopRide = true
          else
            self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
          end
        end
      end
    end
  end
end

function SceneLocalPlayer:EnterTaskArea(taskID)
  Log.Debug("[SceneLocalPlayer]EnterTaskArea", taskID)
  if taskID and 0 ~= taskID then
    local taskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_STATE_CONF):GetAllDatas()
    if taskConf then
      local taskData = taskConf[taskID]
      Log.Debug("[SceneLocalPlayer]EnterTaskArea", taskID, taskData)
      if taskData then
        self.taskAreaRideAllBanType = self.taskAreaRideAllBanType or {}
        if taskData.rideall_ban_type then
          for _, v in ipairs(taskData.rideall_ban_type) do
            Log.Debug("[SceneLocalPlayer]EnterTaskArea", taskID, v)
            self.taskAreaRideAllBanType[v] = self.taskAreaRideAllBanType[v] and self.taskAreaRideAllBanType[v] + 1 or 1
          end
          self.taskAreaRideAllBanTaskIds = self.taskAreaRideAllBanTaskIds or {}
          table.insert(self.taskAreaRideAllBanTaskIds, taskID)
        end
        self:CheckTaskAreaRideAllBanType()
      end
    end
  end
end

function SceneLocalPlayer:LeaveTaskArea(taskID)
  if taskID and 0 ~= taskID then
    local taskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_STATE_CONF):GetAllDatas()
    if taskConf then
      local taskData = taskConf[taskID]
      if taskData then
        self.taskAreaRideAllBanType = self.taskAreaRideAllBanType or {}
        if taskData.rideall_ban_type then
          for _, v in ipairs(taskData.rideall_ban_type) do
            if self.taskAreaRideAllBanType[v] then
              if 1 == self.taskAreaRideAllBanType[v] then
                self.taskAreaRideAllBanType[v] = nil
              else
                self.taskAreaRideAllBanType[v] = self.taskAreaRideAllBanType[v] - 1
              end
            end
          end
          if self.taskAreaRideAllBanTaskIds then
            for i, id in ipairs(self.taskAreaRideAllBanTaskIds) do
              if id == taskID then
                table.remove(self.taskAreaRideAllBanTaskIds, i)
                break
              end
            end
          end
        end
      end
    end
  end
end

function SceneLocalPlayer:GetTaskAreaRideAllBanTips()
  if self.taskAreaRideAllBanTaskIds then
    local taskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_STATE_CONF):GetAllDatas()
    if taskConf then
      for _, taskID in ipairs(self.taskAreaRideAllBanTaskIds) do
        local taskData = taskConf[taskID]
        if taskData and taskData.rideall_ban_tips and taskData.rideall_ban_tips ~= "" then
          return taskData.rideall_ban_tips
        end
      end
    end
  end
  return nil
end

function SceneLocalPlayer:ShowTaskAreaRideAllBanTips()
  local tips = self:GetTaskAreaRideAllBanTips()
  if tips then
    NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[tips])
  end
end

function SceneLocalPlayer:DeleteRelationTreeRequestHUD(IsDelete)
  if IsDelete then
    local HeadWidget = self.viewObj.LocalHeadWidget:GetUserWidgetObject()
    HeadWidget:ClearOldData()
  else
    self:UpdateRelationTreeRequestHUD()
  end
end

function SceneLocalPlayer:UpdateRelationTreeRequestHUD()
  if self.viewObj and self.viewObj.LocalHeadWidget then
    local HeadWidget = self.viewObj.LocalHeadWidget:GetUserWidgetObject()
    if HeadWidget then
      local RelationTreeModule = _G.NRCModuleManager:GetModule("RelationTreeModule")
      if nil ~= RelationTreeModule then
        local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
        local TargetActionID = self.InviteComponent and self.InviteComponent.TargetActionId
        if MyRequest then
          HeadWidget:ShowPanelByType("RoleRelationTree", {RelationTreeType = MyRequest, ActionID = nil})
        elseif TargetActionID then
          HeadWidget:ShowPanelByType("RoleRelationTree", {RelationTreeType = nil, ActionID = TargetActionID})
        else
          HeadWidget:UnVisibileRelationTree()
        end
      end
    else
      Log.Error("HeadWidget-HUD not found")
    end
  end
end

function SceneLocalPlayer:UpdateMyRelationTreeRequestByDis(IsInDis, playerUin)
  local HeadWidget = self.viewObj.LocalHeadWidget:GetUserWidgetObject()
  local CurRequestPlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
  local InviteTargetUin = self.InviteComponent and self.InviteComponent.TargetUin
  if playerUin == CurRequestPlayerUin then
    if not IsInDis then
      HeadWidget:UnVisibileRelationTree()
    else
      self:UpdateRelationTreeRequestHUD()
    end
  elseif playerUin == InviteTargetUin then
    if not IsInDis then
      HeadWidget:UnVisibileRelationTree()
    else
      self:UpdateRelationTreeRequestHUD()
    end
  end
end

function SceneLocalPlayer:OnLinkMove(MoveVector)
  if not self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    Log.Debug("SceneLocalPlayer OnLinkMove return : No Link Status")
    return
  end
  local curServerTime = _G.ZoneServer:GetServerTime()
  self._lastTravelTogetherTime = self._lastTravelTogetherTime or 0
  if curServerTime - self._lastTravelTogetherTime > 500 then
    local req = ProtoMessage:newZoneSceneRelationTravelTogetherSyncReq()
    req.pos_diff = SceneUtils.ClientPos2ServerPos(MoveVector, 10000)
    self._lastTravelTogetherTime = curServerTime
    _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_TRAVEL_TOGETHER_SYNC_REQ, req, false)
  end
end

function SceneLocalPlayer:OnLinkBreak(OtherPlayer)
  self.InviteComponent:InteractCancel()
end

function SceneLocalPlayer:StopLink()
  local StatusComp = self.statusComponent
  if StatusComp then
    StatusComp:RemoveStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
    StatusComp:RemoveStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
  end
end

function SceneLocalPlayer:OnWaitForOtherStatus(isAdd)
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if isAdd then
    local waitTime = _G.DataConfigManager:GetBattleGlobalConfig("syn_battle_end_waiting_time", true).num or 10
    mainUIModule:OpenPanel("WaitTogetherPanel", BattleEnum.UmgBattleRoundStartDisplayType.CountDown, waitTime, 0)
    mainUIModule:DisablePanel("LobbyMain", _G.NRCPanelEnum.PanelDisableReason.WaitTogetherPlayer)
    self:PausePlayerMovement(self, true, "OnWaitForOtherStatus")
  else
    mainUIModule:ClosePanel("WaitTogetherPanel")
    mainUIModule:EnablePanel("LobbyMain", _G.NRCPanelEnum.PanelDisableReason.WaitTogetherPlayer)
    self:PausePlayerMovement(self, false, "OnWaitForOtherStatus")
  end
end

function SceneLocalPlayer:RideFriendPet(npc, petData)
  self.buffComponent:AddBuff(RideFriendPetBuff.BuffName, RideFriendPetBuff, self, npc, petData)
end

function SceneLocalPlayer:PlayTogetherFx(FxID)
  if not self.serverData then
    return
  end
  local ViewObj = self.viewObj
  if ViewObj and ViewObj:PlayTogetherFx(FxID) then
    local req = _G.ProtoMessage:newZoneClientOperationReq()
    req.operation.operator_id = self.serverData.base.actor_id
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_TOGETHER_FX
    req.operation.player_perform_info.idle_perform_id = FxID
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  end
end

function SceneLocalPlayer:SetCharacterMovementTickEnable(caller, enable, flag)
  if self._bearing then
    Log.ErrorFormat("Unable to call SetCharacterMovementTickEnable during bearing")
    return
  end
  if not caller then
    Log.ErrorFormat("Unable to call SetCharacterMovementTickEnable without caller")
    return
  end
  local label = flag or caller.name or StringCache.intern("default")
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetCharacterMovementTickEnabled(enable, label)
    if self.viewObj.BP_RideComponent then
      local ridePet = self.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet.CharacterMovement:SetComponentTickEnabled(enable)
      end
    end
  end
end

function SceneLocalPlayer:DumpCriticalVariables()
  Log.Warning("====================================================================================================")
  Log.WarningFormat("InputComponent: %s", self.inputComponent._inputSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._cameraControlSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._moveSwitch)
  Log.WarningFormat("InputComponent: %s", self.inputComponent._ignoreMoveInputSwitch)
  Log.WarningFormat("MovementComponent: _isBanned(%s)", self.movementComponent._isBanned and "true" or "false")
  if UE.UObject.IsValid(self.viewObj) then
    Log.WarningFormat("CharacterMovement: %s", self.viewObj._characterMoveTickSwitch)
  end
  if UE4Helper.IsPCMode() then
    local enhancedInputModule = NRCModuleManager:GetModule("EnhancedInputModule")
    if not enhancedInputModule then
      return
    end
    local IMCStack = {}
    for k, v in pairs(enhancedInputModule.activeMappingContext) do
      table.insert(IMCStack, k)
    end
    Log.WarningFormat("IMC Stack: %s , %s", table.concat(IMCStack, ","), enhancedInputModule.blockImcCaller and string.format("IMC_Block(%s)", enhancedInputModule.blockImcCaller) or "")
  end
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  Log.WarningFormat("playerModule %s, %s", playerModule._hideAllPlayer, playerModule._hideNotVisitPlayer)
  Log.Warning("=============================LocalPlayer Critical Variables========================================")
end

return SceneLocalPlayer
