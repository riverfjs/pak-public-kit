local TakePhotosModeBasic = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeBasic")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local TripodControl = require("NewRoco.Modules.System.TakePhotos.Controller.TripodControl")
local TakePhotosModeTripod = TakePhotosModeBasic:Extend("TakePhotosModeTripod")
local EnmTripodStatus = {
  None = 0,
  WaitCreated = 1,
  WaitDeleted = 2,
  Created = 17,
  Deleted = 18,
  WaitNpc = 3
}

function TakePhotosModeTripod:OnConstruct()
  self.TripodStatus = EnmTripodStatus.None
  self.RefreshContentId = 41000000
  self.dataCacheNetPoint = nil
  self.bInScreenZoomControl = false
  self.NpcId = 0
  self.TripodNpc = nil
  self.TripodControl = TripodControl(self)
  self.bRollControlEnabled = false
end

function TakePhotosModeTripod:InstantiateCamera()
  self:NotifyServerCreateCamera()
end

function TakePhotosModeTripod:HasCameraEntered()
  return self.TripodStatus == EnmTripodStatus.Created
end

function TakePhotosModeTripod:NotifyServerCreateCamera()
  local ContentId = self.RefreshContentId
  local OpType = ProtoEnum.ControllableNpcOpType.CNOT_CREATE
  local Point = ProtoMessage:newPoint()
  local Pos = self.TripodControl.TripodSpawnTransform.Translation
  local Rot = self.TripodControl.TripodSpawnTransform.Rotation:ToRotator()
  local Yaw = Rot.Yaw
  if Yaw < 0 then
    Yaw = 360 + Yaw
  end
  local Pitch = Rot.Pitch
  if Pitch < 0 then
    Pitch = 360 + Pitch
  end
  Point.pos.x = math.round(Pos.X)
  Point.pos.y = math.round(Pos.Y)
  Point.pos.z = math.round(Pos.Z)
  Point.dir.z = math.round(Yaw * 10)
  Point.dir.x = math.round(0)
  Point.dir.y = math.round(Pitch * 10)
  self.dataCacheNetPoint = Point
  self.TripodStatus = EnmTripodStatus.WaitCreated
  
  local function OnCreateRsp(Req, Rsp)
    self.NpcId = Rsp and Rsp.npc_id or 0
    Log.Debug("[TakePhoto] OnCreateRsp", Rsp and Rsp.ret_info.ret_code, "status=", self.TripodStatus, "npc=", self.NpcId)
    if self.TripodStatus ~= EnmTripodStatus.WaitCreated then
      if 0 ~= self.NpcId then
        if self.TripodStatus == EnmTripodStatus.WaitDeleted then
          self:NotifyServerDeleteCamera()
        end
      else
        self.TripodStatus = EnmTripodStatus.Deleted
      end
      return
    end
    if 0 == self.NpcId then
      NRCModuleManager:DoCmd(TakePhotosModuleCmd.TryExitTakePhotoByTripodDestroyed)
      return
    end
    self.TripodStatus = EnmTripodStatus.WaitNpc
    self:ConditionReferenceTripodNpc()
  end
  
  Log.Debug("[TakePhoto] ReqCreate")
  NRCModuleManager:DoCmd(NPCModuleCmd.ReqControlNpc, ContentId, OpType, Point, OnCreateRsp)
end

function TakePhotosModeTripod:OnEnterSceneFinish()
  if self.TripodStatus == EnmTripodStatus.WaitDeleted then
    self:NotifyServerDeleteCamera()
  end
end

function TakePhotosModeTripod:NotifyServerDeleteCamera()
  assert(self.TripodStatus == EnmTripodStatus.WaitDeleted)
  if 0 == self.NpcId or not NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.NpcId) then
    self.TripodStatus = EnmTripodStatus.Deleted
    Log.Warning("[TakePhoto] notify server delete, but client cannot found npc, ignore request, npc=", self.NpcId)
    return
  end
  local ContentId = self.RefreshContentId
  local OpType = ProtoEnum.ControllableNpcOpType.CNOT_DELETE
  
  local function OnDeleteRsp(Req, Rsp)
    Log.Debug("[TakePhoto] OnDeleteRsp", Rsp and Rsp.ret_info.ret_code, "status=", self.TripodStatus)
    if self.TripodStatus ~= EnmTripodStatus.WaitDeleted then
      return
    end
    if Rsp then
      self.TripodStatus = EnmTripodStatus.Deleted
    end
    local bSuccess = Rsp and 0 == Rsp.ret_info.ret_code
    if not bSuccess then
      Log.Error("[TakePhoto] delete camera failed, err code=", Rsp and Rsp.ret_info.ret_code)
    end
  end
  
  if 0 ~= self.NpcId then
    Log.Debug("[TakePhoto] ReqDelete", self.NpcId)
    _G.NRCAudioManager:PlaySound2DAuto(41500109, "TakePhotosModeTripod:NotifyServerDeleteCamera")
    NRCModuleManager:DoCmd(NPCModuleCmd.ReqControlNpc, ContentId, OpType, nil, OnDeleteRsp, self.NpcId)
  else
    Log.Error("[TakePhoto] notify server delete camera, but cannot found npc id")
  end
end

function TakePhotosModeTripod:NotifyTakePhotoFlash()
  if 0 ~= self.NpcId then
    local function OnTakePhotoFlash(Req, Rsp)
      Log.Debug("[TakePhoto] sync photo flash request finish", Rsp and Rsp.ret_info and Rsp.ret_info.ret_code)
    end
    
    local ContentId = self.RefreshContentId
    local OpType = _G.ProtoEnum.ControllableNpcOpType.CNOT_ACTION
    NRCModuleManager:DoCmd(NPCModuleCmd.ReqControlNpc, ContentId, OpType, nil, OnTakePhotoFlash, self.NpcId)
  end
end

function TakePhotosModeTripod:ConditionReferenceTripodNpc()
  local Npc = self.NpcId and NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.NpcId)
  if 0 ~= self.NpcId and not Npc then
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local LocalActorId = localPlayer.serverData.base.actor_id
    Npc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByFilter, nil, function(v)
      local NpcRefreshId = v.serverData.npc_base.npc_content_cfg_id
      if NpcRefreshId == self.RefreshContentId then
        local AvatarId = v.serverData.npc_base.create_avatar_id
        if AvatarId == LocalActorId then
          return true
        end
      end
    end)
    if Npc then
      self.NpcId = Npc.serverData.base.actor_id
      Log.Debug("[TakePhoto] Found client npc", self.NpcId)
    end
  end
  if Npc then
    Log.Debug("[TakePhoto] Found Npc", self.NpcId)
    if Npc.viewObj and UE.UObject.IsValid(Npc.viewObj) then
      self.TripodNpc = Npc and Npc.viewObj
    else
      Log.Debug("[TakePhoto] Wait for npc view create")
    end
  end
  if self.TripodNpc and self.TripodStatus == EnmTripodStatus.WaitNpc then
    self.TripodStatus = EnmTripodStatus.Created
    Log.Debug("[TakePhoto] Transit Camera To Npc", self.NpcId, "fov=", self.SavedFov)
    self.TripodNpc.SceneCaptureComponent2D.FOVAngle = self.SavedFov
    self.TripodNpc.SceneCaptureComponent2D.bCaptureEveryFrame = false
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local cameraMgr = player:GetUEController().playerCameraManager
    cameraMgr.FOV = self.SavedFov
    self:InitControllerRotation()
    TakePhotosUtils.ToggleCameraFromWorldToTripod(self.TripodNpc)
    TakePhotosUtils.ToggleTripodStatus()
    self:OnRollInputChanged(self:GetSettings().CameraRollProgress:GetValue())
    self.TripodNpc:SetAudioPlayEnabled(false)
    self.TripodNpc:StartOverlap()
    return true
  end
end

function TakePhotosModeTripod:OnTick(Dt)
  if self.TripodStatus == EnmTripodStatus.WaitNpc then
    self:ConditionReferenceTripodNpc()
  end
  self.TripodControl:OnTick(Dt)
  if self.TripodNpc then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    player.ueController:SetControlRotation(self.TripodNpc:K2_GetActorRotation())
    local curCamActor = player.ueController:GetViewTarget()
    if curCamActor ~= self.TripodNpc then
      Log.Warning("[TakePhoto] camera changed, exit take photo")
      NRCModuleManager:DoCmd(TakePhotosModuleCmd.ExitTakePhotos)
    end
    if self.bPendingEnableTripodLag then
      self.bPendingEnableTripodLag = false
      self.TripodNpc.RocoSpringArm.CameraRotationLagSpeed = 10
    end
  end
  self:TickCamera(Dt)
end

function TakePhotosModeTripod:IsCameraCleaned()
  if self.TripodStatus ~= EnmTripodStatus.None and self.TripodStatus ~= EnmTripodStatus.Deleted then
    Log.Warning("[TakePhoto] wait server to clean, status=", self.TripodStatus)
    return false
  else
    local Npc = 0 ~= self.NpcId and NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.NpcId)
    if Npc and Npc.notDestroyFlag then
      Log.Warning("[TakePhoto] wait client to clean, status=", self.TripodStatus)
      return false
    end
  end
  return true
end

function TakePhotosModeTripod:OnClean(bNeedHideImmediately)
  self:SetRollControlEnabled(false)
  self.SavedFov = self:GetBaseFov()
  if bNeedHideImmediately and self.TripodNpc and UE.UObject.IsValid(self.TripodNpc) then
    self.TripodNpc:SetHiddenMask(true, UE4.EPlayerForceHiddenType.TakePhoto)
    self.TripodNpc:SetCollisionEnable(false)
  end
  self.TripodNpc = nil
  if self.TripodStatus == EnmTripodStatus.WaitCreated then
    self.TripodStatus = EnmTripodStatus.WaitDeleted
  else
    self.TripodStatus = EnmTripodStatus.WaitDeleted
    self:NotifyServerDeleteCamera()
  end
  TakePhotosUtils.ToggleTripodStatus(true)
end

function TakePhotosModeTripod:GetSettings()
  return self.TripodControl:GetSettings()
end

function TakePhotosModeTripod:SetRollControlEnabled(bEnabled)
  if self.bRollControlEnabled ~= bEnabled then
    if bEnabled then
      self:GetSettings().CameraRollProgress.OnValueChanged:Add(self, self.OnRollInputChanged)
    else
      self:GetSettings().CameraRollProgress.OnValueChanged:Remove(self, self.OnRollInputChanged)
    end
  end
end

function TakePhotosModeTripod:OnRollInputChanged(Value)
  self.TripodControl:ChangeRoll(-Value)
end

function TakePhotosModeTripod:BeginExitCamera()
  self.bPendingEnableTripodLag = false
  TakePhotosUtils.ExistCameraFromTripodToWorld()
  if self.TripodNpc and UE.UObject.IsValid(self.TripodNpc) then
    self.TripodNpc:SetAudioPlayEnabled(true)
    self.TripodNpc:EndOverlap()
  end
end

function TakePhotosModeTripod:BeginEnterCamera()
  if self.Mgr:IsWorldMode() then
    if LuaText.takephoto_tripod_camera_tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_tripod_camera_tips, nil, nil, self.Mgr.ToggleTipsSeconds)
    end
    self:InitControllerRotation()
    TakePhotosUtils.ToggleCameraFromWorldToTripod(self.TripodNpc)
    self.TripodNpc:SetAudioPlayEnabled(false)
    self.TripodNpc:StartOverlap()
  elseif not self.Mgr:IsTripodMode() then
    if LuaText.takephoto_open_tripod_camera_tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_tripod_camera_tips, nil, nil, self.Mgr.ToggleTipsSeconds)
    end
    self:InstantiateCamera()
    self:SetRollControlEnabled(true)
  else
    Log.Error("Logical Error!!!")
  end
end

function TakePhotosModeTripod:InitControllerRotation()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.originalControlRotation = player.ueController:GetControlRotation()
end

function TakePhotosModeTripod:RecoverControlRotation()
  if self.originalControlRotation then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if UE.UObject.IsValid(player.ueController) then
      player.ueController:SetControlRotation(self.originalControlRotation)
    end
    self.originalControlRotation = nil
  end
end

function TakePhotosModeTripod:AttachIgnoreActors(IgnoreActors)
  if self.Mgr:IsSelfieMode() then
    local Camera = self.Mgr.CurrMode:GetCamera()
    if Camera and UE.UObject.IsValid(Camera) then
      table.insert(IgnoreActors, Camera)
    end
  end
end

function TakePhotosModeTripod:GetCamera()
  return self.TripodNpc
end

function TakePhotosModeTripod:PreCheck()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not (player and player.viewObj) or not UE.UObject.IsValid(player.viewObj) then
    return false
  end
  if self.Mgr:Is1PMode() or self.Mgr:IsSelfieMode() then
    if not self:IsCameraCleaned() then
      Log.Warning("[TakePhoto] wait server to clean")
      return false
    end
    self.NpcId = 0
    local BP_RideComponent = player.viewObj and player.viewObj.BP_RideComponent
    if BP_RideComponent then
      local ridePet = BP_RideComponent.RidePet
      if ridePet and not ridePet.CharacterMovement:IsMovingOnGround() then
        return false
      end
    end
  end
  if player then
    local canApply, overrideValues, opCode = player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_TAKE_PHOTO)
    if not canApply then
      return false
    end
  end
  if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
    return false
  end
  if self.Mgr:IsWorldMode() then
    return true
  end
  local bBan, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, true, true)
  if bBan then
    return false, "" ~= Msg
  end
  if not self.TripodControl:TryLocTripodSpawnTransform() then
    return false
  end
  return true
end

function TakePhotosModeTripod:IfThinkNpcDestroyedEffect()
  return self.TripodStatus ~= EnmTripodStatus.WaitDeleted and self.TripodStatus ~= EnmTripodStatus.Deleted
end

function TakePhotosModeTripod:GetRenderTarget2D()
  if not self.TripodStatus == EnmTripodStatus.Created then
    return
  end
  if not self.TripodNpc or not UE.UObject.IsValid(self.TripodNpc) then
    return
  end
  local RT = NRCModuleManager:GetModule("TakePhotosModule").data:RequestRT()
  local SceneCaptureComponent2D = self.TripodNpc.SceneCaptureComponent2D
  UE4.UNRCStatics.SetCapturePostProcessing(SceneCaptureComponent2D)
  SceneCaptureComponent2D.FOVAngle = self.SavedFov
  SceneCaptureComponent2D.bDisableFlipCopyGLES = true
  UE.UPlatformImageLibrary.CaptureSceneFinalImmediately(SceneCaptureComponent2D, RT)
  self:NotifyTakePhotoFlash()
  return RT
end

function TakePhotosModeTripod:IsDelayTakePhotosEnabled()
  return true
end

function TakePhotosModeTripod:GetPlayerConditionType()
  return Enum.PlayerConditionType.PCT_TAKE_PHOTO_TRIPOD_CAMERA
end

function TakePhotosModeTripod:OnEnter()
  self.World = UE4Helper.GetCurrentWorld()
  self.Overlaps = {}
  self.OverlapCache = UE4.TArray(UE.AActor)
  TakePhotosModeBasic.OnEnter(self)
  self.bInScreenZoomControl = false
  self.TimeHandle = TimerManager:CreateTimer(self, "TakePhotosModeTripod", math.maxinteger, self.OnLowTick, nil, 0.33)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
  end
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", true)
    MainUIModule:DispatchEvent(MainUIModuleEvent.ReqShowHideAbilitySlotByReason, "Jump", false, "TakePhotoTripodMode")
  end
  self:BeginEnterCamera()
end

function TakePhotosModeTripod:OnExit(bExitTakingPhoto, Context)
  TakePhotosModeBasic.OnExit(self)
  TimerManager:RemoveTimer(self.TimeHandle)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
  end
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", false)
    MainUIModule:DispatchEvent(MainUIModuleEvent.ReqShowHideAbilitySlotByReason, "Jump", true, "TakePhotoTripodMode")
  end
  local bNeedClean = bExitTakingPhoto or Context and Context.ToMode and Context.ToMode ~= self.Mgr.TakePhotosModeWorld
  self:BeginExitCamera()
  if bNeedClean then
    self:OnClean(Context and Context.ToMode == self.Mgr.TakePhotosModeSelfie)
  end
  self:RecoverControlRotation()
  self:ResetOverlaps()
end

function TakePhotosModeTripod:ResetCameraView()
  self.SavedFov = self:GetBaseFov()
  if self.TripodNpc and UE.UObject.IsValid(self.TripodNpc) then
    if not self.bPendingEnableTripodLag then
      self.bPendingEnableTripodLag = true
      self.TripodLagSpeed = self.TripodNpc.RocoSpringArm.CameraRotationLagSpeed
      self.TripodNpc.RocoSpringArm.CameraRotationLagSpeed = 9999999
    end
    TakePhotosUtils.ResetTripodCameraView(self.TripodNpc, self.TripodControl.TripodSpawnTransform)
  end
end

function TakePhotosModeTripod:CanOperation()
  if not self.TripodNpc or not UE.UObject.IsValid(self.TripodNpc) then
    return false
  end
  return true
end

function TakePhotosModeTripod:IncTripodHeight()
  if not self:CanOperation() then
    return
  end
  self.TripodControl:MoveUp()
end

function TakePhotosModeTripod:MoveTripodLeft()
  if not self:CanOperation() then
    return
  end
  self.TripodControl:MoveLeft()
end

function TakePhotosModeTripod:MoveTripodRight()
  if not self:CanOperation() then
    return
  end
  self.TripodControl:MoveRight()
end

function TakePhotosModeTripod:DecTripodHeight()
  if not self:CanOperation() then
    return
  end
  self.TripodControl:MoveDown()
end

function TakePhotosModeTripod:OnInputTurn(dir)
  if not UE.UObject.IsValid(self.TripodNpc) then
    return
  end
  if self.bInScreenZoomControl then
    return
  end
  if not self:CanOperation() then
    return
  end
  self.TripodControl:ApplyRotation(dir)
end

function TakePhotosModeTripod:OnLowTick()
  self:BroadcastStubTripodTransform()
end

function TakePhotosModeTripod:BroadcastStubTripodTransform()
  if not UE.UObject.IsValid(self.TripodNpc) then
    return
  end
  if 0 == self.NpcId then
    return
  end
  local Transform = self.TripodNpc:Abs_GetTransform()
  local Pos = Transform.Translation
  local Rot = Transform.Rotation:ToRotator()
  local Yaw = Rot.Yaw
  if Yaw < 0 then
    Yaw = 360 + Yaw
  end
  local Pitch = Rot.Pitch
  if Pitch < 0 then
    Pitch = 360 + Pitch
  end
  local Roll = Rot.Roll
  if Roll < 0 then
    Roll = 360 + Roll
  end
  local Point = ProtoMessage:newPoint()
  Point.pos.x = math.round(Pos.X)
  Point.pos.y = math.round(Pos.Y)
  Point.pos.z = math.round(Pos.Z)
  Point.dir.z = math.round(Yaw * 10)
  Point.dir.x = math.round(Roll * 10)
  Point.dir.y = math.round(Pitch * 10)
  if self.dataCacheNetPoint then
    local bChanged = math.abs(Point.pos.x - self.dataCacheNetPoint.pos.x) > 0 or math.abs(Point.pos.y - self.dataCacheNetPoint.pos.y) > 0 or math.abs(Point.pos.z - self.dataCacheNetPoint.pos.z) > 0 or math.abs(Point.dir.z - self.dataCacheNetPoint.dir.z) > 0 or math.abs(Point.dir.x - self.dataCacheNetPoint.dir.x) > 0 or math.abs(Point.dir.y - self.dataCacheNetPoint.dir.y) > 0
    if not bChanged then
      return
    end
  end
  self.dataCacheNetPoint = Point
  local ContentId = self.RefreshContentId
  local OpType = ProtoEnum.ControllableNpcOpType.CNOT_CHANGE_DIR
  NRCModuleManager:DoCmd(NPCModuleCmd.ReqControlNpc, ContentId, OpType, Point, nil, self.NpcId)
end

function TakePhotosModeTripod:GetBaseFov()
  return TakePhotosEnum.TPGlobalNum("takephoto_mount_camera_fov", 90)
end

function TakePhotosModeTripod:IsEnablePlayerLookLensFeature()
  return true
end

function TakePhotosModeTripod:TickCamera(Dt)
  if not self.Overlaps then
    return
  end
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local playerView = localPlayer.viewObj
  if not playerView or not UE.UObject.IsValid(playerView) then
    return
  end
  for Overlap, _ in pairs(self.Overlaps) do
    self.Overlaps[Overlap] = 0
  end
  local ObjectTypes = {
    UE.EObjectTypeQuery.Pawn
  }
  local CachedResults = self.OverlapCache
  local PlayerLocation = localPlayer:GetUEController().PlayerCameraManager:GetCameraLocation()
  local Success = UE.UNRCStatics.SphereOverlapActors(self.World, PlayerLocation, 11, ObjectTypes, {
    localPlayer.viewObj
  }, CachedResults)
  if not Success then
    CachedResults:Clear()
  end
  for i, Overlap in tpairs(CachedResults) do
    self.Overlaps[Overlap] = 1
  end
  for Overlap, Alpha in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, Alpha)
    if 0 == Alpha then
      self.Overlaps[Overlap] = nil
    end
  end
end

function TakePhotosModeTripod:InternalEnabledAlpha(Overlap, Alpha)
  if not UE.UObject.IsValid(Overlap) then
    return
  end
  local bVisible = 0 == Alpha
  if Overlap.sceneCharacter and Overlap.sceneCharacter.isLocal ~= nil then
  else
    local SceneCharacter = Overlap.sceneCharacter
    if SceneCharacter then
      if SceneCharacter.SetVisibleForTakePhoto then
        SceneCharacter:SetVisibleForTakePhoto(bVisible)
      end
    elseif Overlap.SetMeshAlpha then
      Overlap:SetMeshAlpha(Alpha)
    end
  end
end

function TakePhotosModeTripod:ResetOverlaps()
  for Overlap, _ in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, 0)
  end
  self.Overlaps = nil
  self.World = nil
end

return TakePhotosModeTripod
