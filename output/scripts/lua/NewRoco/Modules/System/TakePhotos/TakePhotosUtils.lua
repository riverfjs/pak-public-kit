local TakePhotosUtils = {}
TakePhotosUtils.SYNC_REQ = _G.ProtoMessage:newZoneClientOperationReq()

function TakePhotosUtils.ToggleCameraFromWorldToTripod(TripodActor)
  Log.Info("[TakePhoto] ToggleCameraFromWorldToTripod:", TripodActor)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local controller = player:GetUEController()
  controller:ChangeToCustomCamera(TripodActor)
  TakePhotosUtils.ResetTripodCameraView(TripodActor)
  player:GetUEController():SetFadeEnable(false)
end

function TakePhotosUtils.ToggleTripodStatus(bClear)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bClear then
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD)
  else
    player.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD)
  end
end

function TakePhotosUtils.OnAvatarReadyIn1PMode()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:SetVisible(false, true, true, true)
  if UE.UObject.IsValid(player.viewObj) then
    player.viewObj.CharacterMovement.bUseControllerDesiredRotation = true
  end
end

local TakePhotoHiddenPlayerDelayId

function TakePhotosUtils.ToggleCameraFromWorldTo1P()
  Log.Info("[TakePhoto] ToggleCameraFromWorldTo1P")
  if TakePhotoHiddenPlayerDelayId then
    DelayManager:CancelDelayById(TakePhotoHiddenPlayerDelayId)
    TakePhotoHiddenPlayerDelayId = nil
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraMgr = player:GetUEController().playerCameraManager
  if not cameraMgr then
    return
  end
  if UE.UObject.IsValid(player.viewObj) then
    player.viewObj:SetHiddenMask(true, UE.EPlayerForceHiddenType.TakePhoto)
    if player.viewObj.BP_RideComponent then
      local ridePet = player.viewObj.BP_RideComponent.RidePet
      if ridePet then
        ridePet:SetHiddenMask(false, UE.EPlayerForceHiddenType.TakePhoto)
      end
    end
    player.viewObj.CharacterMovement.bUseControllerDesiredRotation = true
    player.viewObj:SetEightDirectionMoveEnable(true)
  end
  cameraMgr.FirstPersonView = true
  TakePhotosUtils.Reset1PCameraView()
  player.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO)
  TakePhotosUtils.HideOverlapPlayers()
  if _G.RocoEnv.IS_EDITOR and _G.TakePhotoEditorTools then
    _G.TakePhotoEditorTools.Get():Apply1PCameraOffset()
  end
  player:GetUEController():SetFadeEnable(false)
end

function TakePhotosUtils.HideOverlapPlayers()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.viewObj and player.viewObj.ActionArea then
    local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    local customParams = player.statusComponent:GetCustomParams(statusId)
    local TempArray = UE.TArray(UE.AActor)
    player.viewObj.ActionArea:GetOverlappingActors(TempArray, UE.ARocoPlayerBase)
    for _, v in tpairs(TempArray) do
      if v and v.sceneCharacter then
        local scenePlayer = v.sceneCharacter
        if not scenePlayer.isLocal then
          local otherCharacter = scenePlayer
          if customParams and customParams.ride_param and 0 ~= (customParams.ride_param.double_ride_1p_id or 0) and customParams.ride_param.double_ride_1p_id == otherCharacter.serverData.base.actor_id then
            local dist = (otherCharacter.viewObj.Mesh:Abs_K2_GetComponentLocation() - player.viewObj.Mesh:Abs_K2_GetComponentLocation()):Size()
            if dist > 35 then
          end
          elseif customParams and customParams.ride_param and 0 ~= (customParams.ride_param.double_ride_2p_id or 0) and customParams.ride_param.double_ride_2p_id == otherCharacter.serverData.base.actor_id then
          elseif otherCharacter:IsTogetherMove2P() and otherCharacter:GetAnotherTogetherMovePlayer() == player then
          else
            local bPlayerOnly = false
            local otherCustomParams = otherCharacter.statusComponent:GetCustomParams(statusId)
            if otherCustomParams and otherCustomParams.ride_param and (0 ~= (otherCustomParams.ride_param.double_ride_1p_id or 0) or 0 ~= (otherCustomParams.ride_param.double_ride_2p_id or 0)) then
              bPlayerOnly = true
            end
            scenePlayer:SetVisible(false, true, bPlayerOnly, true)
          end
        end
      end
    end
  end
end

function TakePhotosUtils.ToggleCameraFromWorldToSelfie(CameraActor)
  Log.Info("[TakePhoto] ToggleCameraFromWorldToSelfie:", CameraActor)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local controller = player:GetUEController()
  controller:ChangeToCustomCamera(CameraActor)
  TakePhotosUtils.ResetSelfieCameraView(CameraActor)
  player:GetUEController():SetFadeEnable(false)
end

function TakePhotosUtils.ToggleSelfieStatus(bEnable)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bEnable then
    player.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF)
  else
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF)
  end
end

function TakePhotosUtils.ResetSelfieCameraView(CameraActor, InitTransform)
  Log.Info("[TakePhoto] ResetSelfieCameraView")
  if InitTransform and UE.UObject.IsValid(CameraActor) then
    CameraActor:Abs_K2_SetActorTransform_WithoutHit(InitTransform)
  end
  local fov = TakePhotosEnum.TPGlobalNum("takephoto_myself_FOV_initial", 90)
  TakePhotosUtils.ChaneFOV(fov)
end

function TakePhotosUtils.ExistCameraFromSelfieToWorld()
  Log.Info("[TakePhoto] ExistCameraFromSelfieToWorld")
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local controller = player:GetUEController()
  if not controller or not UE.UObject.IsValid(controller) then
    return
  end
  controller:ReleaseRocoCamera(0, 0, 0, true)
  player:GetUEController():SetFadeEnable(true)
end

function TakePhotosUtils.ExistCameraFrom1PToWorld(bExitTakePhoto)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraMgr = player:GetUEController().playerCameraManager
  if not cameraMgr then
    Log.Error("[TakePhoto] cannot found player manager")
    return
  end
  if bExitTakePhoto then
    TakePhotoHiddenPlayerDelayId = DelayManager:DelayFrames(2, function()
      TakePhotoHiddenPlayerDelayId = nil
      if UE.UObject.IsValid(player.viewObj) then
        player.viewObj:SetHiddenMask(false, UE.EPlayerForceHiddenType.TakePhoto)
      end
    end)
  else
    player.viewObj:SetHiddenMask(false, UE.EPlayerForceHiddenType.TakePhoto)
  end
  player.viewObj.CharacterMovement.bUseControllerDesiredRotation = false
  player.viewObj:SetEightDirectionMoveEnable(false)
  cameraMgr.FirstPersonView = false
  player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO)
  TakePhotosUtils.ShowOverlapPlayers()
  if bExitTakePhoto then
  end
  player:GetUEController():SetFadeEnable(true)
end

function TakePhotosUtils.ShowOverlapPlayers()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.viewObj and player.viewObj.ActionArea then
    local TempArray = UE.TArray(UE.AActor)
    player.viewObj.ActionArea:GetOverlappingActors(TempArray, UE.ARocoPlayerBase)
    for _, v in tpairs(TempArray) do
      if v and v.sceneCharacter then
        local scenePlayer = v.sceneCharacter
        if not scenePlayer.isLocal then
          scenePlayer:SetVisible(true, true, true, true)
        end
      end
    end
  end
end

function TakePhotosUtils.ExistCameraFromTripodToWorld()
  Log.Info("[TakePhoto] ExistCameraFromTripodToWorld")
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local controller = player:GetUEController()
  controller:ReleaseRocoCamera(0, 0, 0, true)
  player:GetUEController():SetFadeEnable(true)
end

function TakePhotosUtils.Reset1PCameraView()
  local fov = TakePhotosEnum.TPGlobalNum("takephoto_hand_camera_fov", 90)
  TakePhotosUtils.ChaneFOV(fov)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local rotation = player.viewObj:K2_GetActorRotation()
    local controlRotation = player.ueController:GetControlRotation()
    rotation.Pitch = 0
    rotation.Roll = 0
    player.ueController:SetControlRotation(rotation)
  end
end

function TakePhotosUtils.ResetTripodCameraView(TripodActor, InitTransform)
  Log.Info("[TakePhoto] ResetTripodCameraView")
  if InitTransform and UE.UObject.IsValid(TripodActor) then
    TripodActor:Abs_K2_SetActorTransform_WithoutHit(InitTransform)
  end
  local fov = TakePhotosEnum.TPGlobalNum("takephoto_mount_camera_fov", 90)
  TakePhotosUtils.ChaneFOV(fov)
end

function TakePhotosUtils.ChaneFOV(InFOV)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraMgr = player:GetUEController().playerCameraManager
  if not cameraMgr then
    return
  end
  cameraMgr.FOV = InFOV
end

function TakePhotosUtils.ChangeRoll(InRoll)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local controller = player:GetUEController()
  if not controller or not UE.UObject.IsValid(controller) then
    return
  end
  local cameraMgr = player:GetUEController().playerCameraManager
  if not cameraMgr then
    return
  end
  cameraMgr.TakePhotoModifier.Roll = -InRoll
end

function TakePhotosUtils.DisableTakePhotoFilter(CurrentFilterConf)
  Log.Debug("[TakePhoto] DisableTakePhotoFilter", CurrentFilterConf.name)
end

function TakePhotosUtils.EnableTakePhotoFilter(DesiredFilterConf)
  Log.Debug("[TakePhoto] EnableTakePhotoFilter", DesiredFilterConf.name)
end

function TakePhotosUtils.EnablePlayerEmoji(Player, EmojiConf, DesiredAnimResource)
  Log.Debug("[TakePhoto] EnablePlayerEmoji", EmojiConf.name, DesiredAnimResource)
  local Success = TakePhotosUtils.PlayAnim(Player, DesiredAnimResource, true)
  if Player.isLocal and Success then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ApplyTPEmojiBehavior, EmojiConf, UE.EDotsStatusType.Start, Player)
    local req = TakePhotosUtils.SYNC_REQ
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_PHOTO_ANIM
    req.operation.operator_id = Player:GetServerId()
    if UE.UObject.IsValid(Player.viewObj) then
      req.operation.photo_info.is_mirror = Player.viewObj.LeftHandCamera
    end
    req.operation.photo_info.is_end = false
    req.operation.photo_info.photo_emoji_id = EmojiConf.id
    req.operation.photo_info.photo_pose_id = nil
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  end
  return Success
end

function TakePhotosUtils.DisablePlayerEmoji(Player, EmojiConf, CurrentAnimResource)
  Log.Debug("[TakePhoto] DisablePlayerEmoji", EmojiConf.name)
  TakePhotosUtils.StopAnim(Player, CurrentAnimResource, true)
  if Player.isLocal then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ApplyTPEmojiBehavior, EmojiConf, UE.EDotsStatusType.Abort, Player)
    local req = TakePhotosUtils.SYNC_REQ
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_PHOTO_ANIM
    req.operation.operator_id = Player:GetServerId()
    req.operation.photo_info.is_end = true
    req.operation.photo_info.photo_emoji_id = EmojiConf.id
    req.operation.photo_info.photo_pose_id = nil
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  end
end

function TakePhotosUtils.PlayAnim(Player, Anim, bAdditive)
  if not Anim or not UE.UObject.IsValid(Anim) then
    Log.Error("[TakePhoto] invalid animation")
    return
  end
  local ViewObj = Player.viewObj
  if not ViewObj or not UE.UObject.IsValid(ViewObj) then
    Log.Error("[TakePhoto] invalid player")
    return
  end
  local AnimComponent = ViewObj:GetAnimComponent()
  if not AnimComponent then
    Log.Error("[TakePhoto] invalid anim component")
    return
  end
  local Len = 0
  if bAdditive then
    Len = AnimComponent:PlayAdditiveAnim(Anim, 1, 0, -1)
  else
    Len = AnimComponent:PlayAnim(Anim, 1, 0, -1, 0, 1, 0, nil)
  end
  Log.Debug("[TakePhoto] start play", Anim, Len)
  return Len > 0
end

function TakePhotosUtils.PlaySelfPhotoAnim(Player, Anim)
  if not Anim or not UE.UObject.IsValid(Anim) then
    Log.Error("[TakePhoto] invalid animation")
    return
  end
  local ViewObj = Player.viewObj
  if not ViewObj or not UE.UObject.IsValid(ViewObj) then
    Log.Error("[TakePhoto] invalid player")
    return
  end
  local AnimInstance = ViewObj.Mesh:GetAnimInstance()
  if not UE.UObject.IsValid(AnimInstance) then
    Log.Error("[TakePhoto] invalid AnimInstance")
    return
  end
  local QSAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("PlayerQS")
  QSAnimInstance:PlaySlotAnimation(Anim, "UpperBody", 0.15, 0.15, 1, 10000000)
  ViewObj.HasCustomSelfPhotoPose = true
end

function TakePhotosUtils.StopSelfPhotoAnim(Player, Anim)
  if not Anim or not UE.UObject.IsValid(Anim) then
    Log.Error("[TakePhoto] invalid animation")
    return
  end
  local ViewObj = Player.viewObj
  if not ViewObj or not UE.UObject.IsValid(ViewObj) then
    Log.Error("[TakePhoto] invalid player")
    return
  end
  local AnimInstance = ViewObj.Mesh:GetAnimInstance()
  if not UE.UObject.IsValid(AnimInstance) then
    Log.Error("[TakePhoto] invalid AnimInstance")
    return
  end
  local QSAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("PlayerQS")
  QSAnimInstance:StopSlotAnimation(0, "UpperBody")
  ViewObj.HasCustomSelfPhotoPose = false
end

function TakePhotosUtils.StopAnim(Player, Anim, bAdditive)
  if not Anim or not UE.UObject.IsValid(Anim) then
    Log.Error("[TakePhoto] invalid animation")
    return
  end
  local ViewObj = Player.viewObj
  if not ViewObj or not UE.UObject.IsValid(ViewObj) then
    Log.Error("[TakePhoto] invalid player")
    return
  end
  local AnimComponent = ViewObj:GetAnimComponent()
  if not AnimComponent then
    Log.Error("[TakePhoto] invalid anim component")
    return
  end
  Log.Debug("[TakePhoto] stop play", Anim)
  if bAdditive then
    AnimComponent:StopAdditiveAnim(Anim, 0)
  else
    AnimComponent:StopAnim(Anim, 0, nil)
  end
end

function TakePhotosUtils.EnablePlayerPoseAction(Player, PoseConf, DesiredAnimResource)
  Log.Debug("[TakePhoto] EnablePlayerPoseAction", PoseConf.name, DesiredAnimResource)
  TakePhotosUtils.PlaySelfPhotoAnim(Player, DesiredAnimResource)
  if Player.isLocal then
    local req = TakePhotosUtils.SYNC_REQ
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_PHOTO_ANIM
    req.operation.operator_id = Player:GetServerId()
    if UE.UObject.IsValid(Player.viewObj) then
      req.operation.photo_info.is_mirror = Player.viewObj.LeftHandCamera
    end
    req.operation.photo_info.is_end = false
    req.operation.photo_info.photo_emoji_id = nil
    req.operation.photo_info.photo_pose_id = PoseConf.id
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  end
end

function TakePhotosUtils.DisablePlayerPoseAction(Player, PoseConf, CurrentAnimResource)
  Log.Debug("[TakePhoto] DisablePlayerPoseAction", PoseConf.name, CurrentAnimResource)
  TakePhotosUtils.StopSelfPhotoAnim(Player, CurrentAnimResource)
  if Player.isLocal then
    local req = TakePhotosUtils.SYNC_REQ
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_PHOTO_ANIM
    req.operation.operator_id = Player:GetServerId()
    req.operation.photo_info.is_end = true
    req.operation.photo_info.photo_emoji_id = nil
    req.operation.photo_info.photo_pose_id = PoseConf.id
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  end
end

function TakePhotosUtils.ChangeFashionWardrobe(Index, Mode)
  Log.Warning("[TakePhoto] Use fashion wardrobe index", Index)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnWardrobeIndexChanged, Index, true)
end

function TakePhotosUtils.SetRideFirstPersonViewOffset(offsetX, offsetY, offsetZ)
  if not TakePhotosUtils.TempFVector then
    TakePhotosUtils.TempFVector = UE.FVector()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if UE.UObject.IsValid(player.viewObj) and player.viewObj.BP_RideComponent then
    local ridePet = player:GetRidePetBP()
    if ridePet then
      TakePhotosUtils.TempFVector.X = offsetX
      TakePhotosUtils.TempFVector.Y = offsetY
      TakePhotosUtils.TempFVector.Z = offsetZ
      ridePet.EyesViewPointOffset = TakePhotosUtils.TempFVector
    end
  end
end

function TakePhotosUtils.GetEnvActor()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if EnvSys then
    local CurEnvActor = EnvSys:GetEnvActor()
    return CurEnvActor
  end
end

function TakePhotosUtils.ChangePostProgressFocalScale(Value)
  local EnvActor = TakePhotosUtils.GetEnvActor()
  if EnvActor then
    local Scale = EnvActor.PostProcess.Settings.DepthOfFieldScale
    local bEnable = Value > 0.001 or Scale > 0.001
    EnvActor.PostProcess.Settings.bOverride_MobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bOverride_StableMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bStableMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bOverride_DepthOfFieldScale = bEnable
    EnvActor.PostProcess.Settings.DepthOfFieldScale = Value
  end
end

function TakePhotosUtils.ChangePostProgressFocalRegion(Value)
  local EnvActor = TakePhotosUtils.GetEnvActor()
  if EnvActor then
    local Region = EnvActor.PostProcess.Settings.DepthOfFieldFocalRegion
    local bEnable = Value > 0.001 or Region > 0.001
    EnvActor.PostProcess.Settings.bOverride_MobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bOverride_StableMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bStableMobileHQGaussian = bEnable
    EnvActor.PostProcess.Settings.bOverride_DepthOfFieldFocalRegion = bEnable
    EnvActor.PostProcess.Settings.DepthOfFieldFocalRegion = Value
  end
end

function TakePhotosUtils.ResetPostProgressFocalRegion()
  local EnvActor = TakePhotosUtils.GetEnvActor()
  if EnvActor then
    EnvActor.PostProcess.Settings.bOverride_MobileHQGaussian = false
    EnvActor.PostProcess.Settings.bMobileHQGaussian = false
    EnvActor.PostProcess.Settings.bOverride_StableMobileHQGaussian = false
    EnvActor.PostProcess.Settings.bStableMobileHQGaussian = false
    EnvActor.PostProcess.Settings.bOverride_DepthOfFieldFocalRegion = false
    EnvActor.PostProcess.Settings.DepthOfFieldFocalRegion = 0
    EnvActor.PostProcess.Settings.bOverride_DepthOfFieldScale = false
    EnvActor.PostProcess.Settings.DepthOfFieldScale = 0
  end
end

function TakePhotosUtils.ReportPhoto(uin, mini_photo_url, photo_url, activity_id)
  Log.Debug("ReportPhoto", uin, mini_photo_url, photo_url, activity_id)
  if not uin or string.IsNilOrEmpty(mini_photo_url) or string.IsNilOrEmpty(photo_url) then
    return
  end
  activity_id = activity_id or 0
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  local season_id = seasonInfo and seasonInfo.season_id or 0
  local PhotoDisplayUtils = require("NewRoco.Modules.System.TakePhotos.Common.PhotoDisplayUtils")
  local miniPicName = PhotoDisplayUtils.ParseActivityPhotoParams(mini_photo_url)
  local picName = PhotoDisplayUtils.ParseActivityPhotoParams(photo_url)
  local reportData = {}
  reportData.uin = uin
  reportData.business_data = {}
  reportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE
  reportData.business_data.report_entrance = 2
  reportData.business_data.pic_url_array = {mini_photo_url, photo_url}
  reportData.business_data.callback = "{\"image_thumbnail\":\"" .. miniPicName .. "\",\"image_FS\":\"" .. picName .. "\",\"event_id\":" .. activity_id .. ",\"season_id\":" .. season_id .. "}"
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendReport, reportData)
end

function TakePhotosUtils.LoadResources(Caller, ResourcePaths, OnSuccess)
  local Sessions = {}
  local Resources = {}
  for i, Path in ipairs(ResourcePaths) do
    local function _OnSuc(_, Req, Res)
      Sessions[i] = nil
      
      Resources[i] = Res
      Log.Debug("TakePhotosUtils LoadResource Finish", i, Path)
      if not next(Sessions) then
        OnSuccess(Caller, Resources)
      end
    end
    
    local function _OnFailed()
      Sessions[i] = nil
    end
    
    Log.Debug("TakePhotosUtils LoadResource", i, Path)
    Sessions[i] = _G.NRCResourceManager:LoadResAsync(Caller, Path, 255, 0, _OnSuc, _OnFailed, nil, _OnFailed)
  end
  
  local function OnRecycle()
    for i, Session in pairs(Sessions) do
      _G.NRCResourceManager:UnLoadRes(Session)
    end
  end
  
  return OnRecycle
end

function TakePhotosUtils.ReplaceCameraTexture(SkeletalMesh, ScenePlayer)
  local MeshPath = ""
  local MaterialPath = ""
  local ResourcePaths = {}
  local Resources = {}
  local ConfigId = TakePhotosUtils.GetPlayerCameraAppearanceId(ScenePlayer)
  local Config = _G.DataConfigManager:GetCameraSkinConf(ConfigId, true)
  if Config then
    MeshPath = Config.skin_model_path or ""
    MaterialPath = Config.skin_path or "MaterialInstanceConstant'/Game/ArtRes/Asset/Environment/SAnimation/SM_Game_Camera_01/MI_Game_Camera_01.MI_Game_Camera_01'"
    if "" ~= MeshPath then
      table.insert(ResourcePaths, MeshPath)
      Resources.Mesh = #ResourcePaths
    end
    if "" ~= MaterialPath then
      table.insert(ResourcePaths, MaterialPath)
      Resources.Material = #ResourcePaths
    end
  end
  
  local function OnLoadSuccess(_, Assets)
    local Mesh = Assets[Resources.Mesh]
    local Material = Assets[Resources.Material]
    if not UE.UObject.IsValid(SkeletalMesh) then
      Log.Error("[TakePhoto] Invalid SkeletalMesh", SkeletalMesh)
      return
    end
    if Mesh and UE.UObject.IsValid(Mesh) then
      SkeletalMesh:SetSkeletalMesh(Mesh, false)
    elseif "" ~= MeshPath then
      Log.Error("[TakePhoto] Invalid Mesh", Mesh, MeshPath)
    end
    if Material and UE.UObject.IsValid(Material) then
      SkeletalMesh:SetMaterial(0, Material)
    elseif "" ~= MaterialPath then
      Log.Error("[TakePhoto] Invalid Material", Material, MaterialPath)
    end
  end
  
  local OnRecycle = TakePhotosUtils.LoadResources(ScenePlayer, ResourcePaths, OnLoadSuccess)
  return OnRecycle
end

function TakePhotosUtils.GetPlayerCameraAppearanceId(ScenePlayer)
  local CameraInfo = ScenePlayer and ScenePlayer.serverData and ScenePlayer.serverData.camera_info
  return CameraInfo and CameraInfo.skin_id or 1
end

function AddPathToTable(inTable, path)
  if string.IsNilOrEmpty(path) or "" == path or type(inTable) ~= "table" then
    return
  end
  table.insert(inTable, path)
end

function TakePhotosUtils.LoadCameraAppearance(contextObj, cameraAppearanceId, CameraBpPath, OnLoadSuccess, OnLoadFail)
  local assetPaths = {}
  AddPathToTable(assetPaths, CameraBpPath)
  if cameraAppearanceId > 0 then
    local meshPath, materialPath, texturePath = TakePhotosUtils.GetCustomCameraAppearancePathsById(cameraAppearanceId)
    AddPathToTable(assetPaths, meshPath)
    AddPathToTable(assetPaths, materialPath)
    AddPathToTable(assetPaths, texturePath)
  end
  local sessionId = _G.PlayerResourceManager:LoadResources_PlayerPerform_List(contextObj, assetPaths, false, OnLoadSuccess, OnLoadFail)
  Log.Debug("[TakePhoto] LoadCameraAppearance", cameraAppearanceId, CameraBpPath, sessionId)
  return sessionId
end

function TakePhotosUtils.GetCustomCameraAppearancePathsById(cameraAppearanceId)
  if not cameraAppearanceId then
    Log.Error("[TakePhoto] GetCustomCameraAppearancePathsById invalid cameraAppearanceId", cameraAppearanceId)
    return nil, nil, nil
  end
  local meshPath = "SkeletalMesh'/Game/ArtRes/Asset/Environment/SAnimation/SM_Game_Camera_01/SM_Game_Camera_01_Skin.SM_Game_Camera_01_Skin'"
  local materialPath = "MaterialInstanceConstant'/Game/ArtRes/Asset/Environment/SAnimation/SM_Game_Camera_01/MI_Game_Camera_01.MI_Game_Camera_01'"
  local texturePath
  local Config = _G.DataConfigManager:GetCameraSkinConf(cameraAppearanceId, true)
  if Config then
    meshPath = Config.skin_model_path or meshPath
    materialPath = Config.skin_path or materialPath
  end
  Log.Debug("[TakePhoto] GetCustomCameraAppearancePathsById", cameraAppearanceId, tostring(meshPath), tostring(materialPath), tostring(texturePath))
  return meshPath, materialPath, texturePath
end

function TakePhotosUtils.SetCameraAppearance(inCameraActor, inSkeletalMeshComponent, loadedAssets)
  if nil == loadedAssets or 0 == #loadedAssets then
    Log.Error("[TakePhoto] SetCameraAppearance invalid loadedAssets")
    return
  end
  Log.Debug("[TakePhoto] assets count: ", #loadedAssets)
  for _, v in ipairs(loadedAssets) do
    Log.Debug("[TakePhoto] SetCameraAppearance assets type: ", v:GetName())
  end
  local bpActor, material, texture, mesh
  for _, asset in ipairs(loadedAssets) do
    if asset:IsA(UE4.UBlueprintGeneratedClass) then
      bpActor = asset
      Log.Debug("[TakePhoto] SetCameraAppearance bpActor is ", bpActor)
    elseif asset:IsA(UE4.UMaterialInstanceConstant) then
      material = asset
      Log.Debug("[TakePhoto] SetCameraAppearance material is ", material)
    elseif asset:IsA(UE4.UTexture2D) then
      texture = asset
      Log.Debug("[TakePhoto] SetCameraAppearance texture is ", texture)
    elseif asset:IsA(UE4.USkeletalMesh) then
      mesh = asset
      Log.Debug("[TakePhoto] SetCameraAppearance mesh is ", mesh)
    end
  end
  local cameraActor = inCameraActor or _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(bpActor, UE.FTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  if nil == cameraActor then
    Log.Error("[TakePhoto] SetCameraAppearance failed to spawn camera actor")
    return
  end
  local skeletalMeshComponent = inSkeletalMeshComponent or cameraActor.SkeletalMesh
  if nil == skeletalMeshComponent then
    Log.Error("[TakePhoto] SetCameraAppearance skeletalMeshComponent is nil")
    return
  end
  if nil ~= mesh then
    skeletalMeshComponent:SetSkeletalMesh(mesh)
  end
  if nil ~= material then
    skeletalMeshComponent:SetMaterial(0, material)
  else
    material = skeletalMeshComponent:GetMaterial(0)
  end
  if nil ~= texture then
    material:SetTextureParameterValue("Texture", texture)
  end
  return cameraActor
end

return TakePhotosUtils
