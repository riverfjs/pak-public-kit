local CameraUtils = require("NewRoco.Modules.System.Camera.CameraUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueConst = require("NewRoco.Modules.System.Dialogue.DialogueConst")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local CameraHolder = require("NewRoco.Modules.System.Camera.CameraHolder")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local CameraModule = NRCModuleBase:Extend("CameraModule")

function CameraModule:OnConstruct()
  _G.CameraModuleCmd = reload("NewRoco.Modules.System.Camera.CameraModuleCmd")
  self.data = self:SetData("CameraModuleData", "NewRoco.Modules.System.Camera.CameraModuleData")
  self.CameraHolder = CameraHolder()
  self.BattleSkillCamera = nil
  self.BattleSkillCameraMesh = nil
  self.bTickCamera = false
  self.bCameraOnUse = false
  self.CameraTickFunction = nil
  self.InternalCameraMotions = {
    BlendToBigWorldCamera = "BlendToBigWorldCamera",
    HorizontalMoveCamera = "HorizontalMoveCamera"
  }
  self.CameraSetterMap = {}
  self.CameraSetterMap[Enum.NpcInteractCameraType.NIC_1] = self.SetCloseUpCamera
  self.CameraSetterMap[Enum.NpcInteractCameraType.NIC_2] = self.SetOverShoulderCamera
  self.CameraSetterMap[Enum.NpcInteractCameraType.NIC_3] = self.SetDoubleUpCamera
  self.CameraSetterMap[Enum.NpcInteractCameraType.NIC_4] = self.SetFreeCamera
  self.CameraSetterMap[Enum.NpcInteractCameraType.NIC_SKILL] = self.SetSkillCamera
  self.CameraTickerMap = {}
  self.CameraTickerMap[Enum.NpcInteractCameraMoveType.CAMERA_MOVE_ROUNDED] = self.CameraMoveRounded
  self.CameraTickerMap[Enum.NpcInteractCameraMoveType.CAMERA_MOVE_ROTATED] = self.CameraMoveRotated
  self.CameraTickerMap[Enum.NpcInteractCameraMoveType.CAMERA_MOVE_PARALLEL] = self.CameraMoveParallel
  self.CameraTickerMap[Enum.NpcInteractCameraMoveType.CAMERA_MOVE_LINE] = self.CameraMoveLine
  self.CameraTickerMap[Enum.NpcInteractCameraMoveType.CAMERA_MOVE_PATH] = self.CameraMovePath
  self.CameraTickerMap[self.InternalCameraMotions.BlendToBigWorldCamera] = self.CameraMoveBlendToBigWorld
  self.CameraTickerMap[self.InternalCameraMotions.HorizontalMoveCamera] = self.CameraMoveHorizontal
end

function CameraModule:CreateCameraMotionInfo()
  return {
    InitCameraTransform = nil,
    TargetCameraTransform = nil,
    CameraForwardVector = nil,
    CameraRightVector = nil,
    CameraMoveValue = nil,
    CameraMoveTime = nil,
    NonStoppableByObstacle = false,
    bSkipIfBlock = false,
    CameraMotionType = Enum.NpcInteractCameraMoveType.CAMERA_MOVE_NULL
  }
end

function CameraModule:CreateCameraRequestConfig()
  return {
    CameraType = Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_NONE,
    MainTarget = nil,
    SubTarget = nil,
    Param1 = nil,
    Param2 = nil,
    Param3 = nil,
    Param4 = nil,
    CustomTickFunction = nil,
    bTickCameraInModule = false,
    bResetCameraOnRequestEnd = false,
    CameraUser = nil,
    Callback = nil,
    NpcTarget = nil,
    CallbackCaller = nil,
    BlendTime = 0,
    BlendType = Enum.CameraBlendType.CBT_NONE
  }
end

function CameraModule:OnOpenMainPanel(RefugeId, Action)
end

function CameraModule:OnActive()
  self.OnTick = nil
  if not self.SplineManager then
    self.SplineManager = UE4Helper.GetCurrentWorld():Abs_SpawnActor(_G.NRCBigWorldPreloader:Get("CAM_SplineManger"), UE4.FTransform(UE4.FQuat(0, 0, 0, 1), UE4.FVector(0, 0, 500)), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if self.SplineManager then
      self.SplineManagerRef = UnLua.Ref(self.SplineManager)
    end
  end
end

function CameraModule:GetActiveCamera()
  return self.ActiveCamera
end

function CameraModule:PrepareBlendingToBigWorldCamera(Time)
  local MotionInfo = self:FillCameraMotionInfo(self.InternalCameraMotions.BlendToBigWorldCamera)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CameraManager = Player:GetUEController().playerCameraManager
  local Location = CameraManager.CameraLocation
  local Rotation = CameraManager.CameraRotation
  local BlendPosition = SceneUtils.ConvertRelativeToAbsolute(Location)
  MotionInfo.TargetCameraTransform = UE4.FTransform()
  MotionInfo.TargetCameraTransform.Translation = BlendPosition
  MotionInfo.TargetCameraTransform.Rotation = Rotation:ToQuat()
  MotionInfo.NonStoppableByObstacle = true
  MotionInfo.CameraMoveTime = Time or 5
  self:StartCameraMotion(MotionInfo)
end

function CameraModule:OverlapRocoCameraWithBigWorldCamera()
  local CameraComponent = self:_EnsuredGetCameraComponent()
  if not CameraComponent then
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CameraManager = Player:GetUEController().playerCameraManager
  local CameraManagerTransform = CameraManager:Abs_GetTransform()
  CameraComponent:K2_SetWorldTransform(CameraManagerTransform)
end

function CameraModule:EndCameraMotion()
  self:OnCameraMotionDone()
end

function CameraModule:InitReferences(bDontReset)
  self.Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not self.Player then
    Log.Error("Fail to get player")
    return
  end
  self.Controller = self.Player:GetUEController()
  if not self.Controller then
    Log.Error("Fail to get controller")
    return
  end
  self.SpringArm = self.Controller.BP_RocoCameraControlComponent:GetSpringArmComponent()
  if not self.SpringArm then
    Log.Error("Fail to get SpringArm")
    return
  end
  if not bDontReset then
    self:ResetAndRecordSpringArmOffsets()
  end
end

function CameraModule:ClearReferences()
  self.Player = nil
  self.Controller = nil
  self.SpringArm = nil
  self.ActiveCamera = nil
  self.SkillClass = nil
  self.SavedViewTarget = nil
  self.SkillObj = nil
end

function CameraModule:_EnsuredGetController()
  if self.Controller and UE.UObject.IsValid(self.Controller) then
    return self.Controller
  else
    self:InitReferences()
    return self.Controller
  end
end

function CameraModule:_EnsuredGetSpringArm()
  if self.SpringArm and UE.UObject.IsValid(self.SpringArm) then
    return self.SpringArm
  else
    self:InitReferences()
    return self.SpringArm
  end
end

function CameraModule:_EnsuredGetCamera()
  if self.Controller and UE.UObject.IsValid(self.Controller) then
    return self.Controller.CameraActor
  else
    self:InitReferences()
    return self.Controller.CameraActor
  end
end

function CameraModule:_EnsuredGetCameraComponent()
  local CameraActor = self.CameraHolder:GetCurrentCamera()
  CameraActor = CameraActor or self:_EnsuredGetCamera()
  local comp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
  if comp then
    return comp
  else
    Log.Error("Controller reference missing")
  end
end

function CameraModule:_EnsuredRequestRocoCamera(CameraRequestConfig)
  local Controller = self:_EnsuredGetController()
  if not Controller then
    return
  end
  local BlendTime = CameraRequestConfig and CameraRequestConfig.BlendTime or 0.0
  if BlendTime > 0 then
    local main_camera = self.CameraHolder and self.CameraHolder:GetMainCamera()
    if main_camera and Controller.PlayerCameraManager then
      main_camera:K2_SetActorTransform(UE4.FTransform(Controller.PlayerCameraManager:GetCameraRotation():ToQuat(), Controller.PlayerCameraManager:GetCameraLocation()), false, nil, false)
    end
    if main_camera and not Controller:IsCurrentViewTarget(main_camera) then
      Controller:SetViewTargetWithBlend(main_camera, 0.0, UE4.EViewTargetBlendFunction.VTBlend_Linear, 0.0)
    end
  end
  local CameraActor = Controller and Controller.CameraActor
  if not Controller:IsCurrentViewTarget(CameraActor) then
    local BlendType = CameraRequestConfig and CameraRequestConfig.BlendType and self:ConvertCameraBlendType(CameraRequestConfig.BlendType)
    local BlendExp = CameraRequestConfig and CameraRequestConfig.BlendExp
    Controller:RequestRocoCamera(BlendTime, BlendType, BlendExp)
  end
end

function CameraModule:RequestDefaultCameraOfType(CameraType, Target, Caller, Callback)
  local config = self:CreateCameraRequestConfig()
  config.CameraType = CameraType
  config.MainTarget = Target
  config.CameraUser = Caller
  config.Callback = Callback
  self:RequestCamera(config)
end

function CameraModule:RequestCamera(CameraRequestConfig)
  if not CameraRequestConfig then
    Log.Error("Requesting camera with no config !")
    return
  end
  if self.bCameraOnUse then
    if CameraRequestConfig.CameraUser ~= self.CameraRequestConfig.CameraUser then
      Log.Error("Camera is in use")
      return
    end
    self.FirstCameraFromTheUser = false
  else
    self.bCameraOnUse = true
    self:InitReferences()
    self.FirstCameraFromTheUser = true
  end
  self:StopCameraMotion()
  self.CameraRequestConfig = CameraRequestConfig
  self:SetUpCamera(self.CameraRequestConfig)
  if self.CameraRequestConfig.bTickCameraInModule then
    self.OnTick = self.DoOnTick
    self:StartCameraMotion()
  elseif self.CameraRequestConfig.bSetUpAndFinish then
    self:FinishRequest()
  end
end

function CameraModule:SetUpCamera(CameraRequestConfig)
  local CameraSetterFunction = self.CameraSetterMap[CameraRequestConfig.CameraType]
  if CameraSetterFunction then
    if self.CameraRequestConfig.CameraType ~= Enum.NpcInteractCameraType.NIC_SKILL then
      self:StopCameraSkillPlaying()
    end
    CameraSetterFunction(self, CameraRequestConfig)
  else
    Log.Warning("not valid camera enum in config")
  end
end

function CameraModule:FillCameraMotionInfo(MotionType)
  local ResultInfo = self:CreateCameraMotionInfo()
  ResultInfo.CameraMotionType = MotionType
  self:InitReferences(true)
  local CameraComponent = self:_EnsuredGetCameraComponent()
  ResultInfo.CameraForwardVector = CameraComponent:GetForwardVector()
  ResultInfo.CameraRightVector = CameraComponent:GetRightVector()
  ResultInfo.InitCameraTransform = CameraComponent:Abs_K2_GetComponentToWorld()
  ResultInfo.TargetCameraTransform = ResultInfo.InitCameraTransform
  return ResultInfo
end

function CameraModule:StartCameraMotion(MotionInfo)
  Log.Debug("StartCameraMotion")
  if MotionInfo then
    self:StopCameraMotion()
    self:InitCameraMotion()
    self.CameraMotionInfo = MotionInfo
    self.OnTick = self.CameraTickerMap[MotionInfo.CameraMotionType]
    UpdateManager:Register(self)
    self:CheckRegisterReconnect()
  else
    self:OnCameraMotionDone()
  end
end

function CameraModule:CheckRegisterReconnect()
  if self.ReconnectRegistered then
    return
  else
    self.ReconnectRegistered = true
    NRCEventCenter:RegisterEvent("CameraModule", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  end
end

function CameraModule:CheckUnRegisterReconnect()
  if self.ReconnectRegistered then
    self.ReconnectRegistered = false
    NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  else
    return
  end
end

function CameraModule:OnConnected(errorCode)
  self:Log("OnConnected", errorCode)
  if 0 == errorCode then
    self:OnCameraMotionDone()
  end
end

function CameraModule:OnCameraMotionDone()
  self:StopCameraTicking()
  self:CheckUnRegisterReconnect()
  if self.CameraMotionInfo then
    self.CameraMotionInfo = nil
  elseif self.CameraRequestConfig then
    self:FinishRequest()
  end
end

function CameraModule:FinishRequest()
  if self.CameraRequestConfig.Callback then
    self.CameraRequestConfig.Callback(self.CameraRequestConfig.CallbackCaller)
  else
    Log.Debug("Camera request finished with no callback")
  end
  self.bTickCamera = false
  self.CameraTickFunction = nil
  self:StopCameraTicking()
end

function CameraModule:StopCameraTicking()
  UpdateManager:UnRegister(self)
  self.OnTick = nil
end

function CameraModule:_ReturnToOutSideCamera()
  if _G.BattleManager.isInBattle then
    _G.BattleManager.vBattleField.battleCameraManager:BindCamera()
    return
  else
    self:_EnsuredGetController():ReleaseRocoCamera(0, 0, 0, true)
    return
  end
end

function CameraModule:ReturnCamera(Returner)
  local controller = self:_EnsuredGetController()
  if not controller then
    Log.Error("CameraModule:ReturnCamera: no controller")
    return
  end
  if not controller.PlayerCameraManager then
    Log.Error("CameraModule:ReturnCamera: PlayerCameraManager is nil")
    return
  end
  controller.PlayerCameraManager:UseBigWorldCamera(true)
  self:OnCameraMotionDone()
  if self.bCameraOnUse then
    if self.CameraRequestConfig.CameraUser == Returner then
      self:OnCameraMotionDone()
      self:ReturnSpringArmOffsets()
      self:StopCameraSkillPlaying()
      self:ChangeBackToSavedCamera()
      self:CleanUpBattleSkillCamera()
      self.bCameraOnUse = false
      table.clear(self.CameraRequestConfig)
      self.CameraRequestConfig = nil
    else
      Log.Warning("returning from other user")
    end
    self.bCameraOnUse = false
  end
  self:_ReturnToOutSideCamera()
  self:ClearReferences()
end

function CameraModule:ForceReturnCamera()
  Log.Error("Not implemented...")
  return
end

function CameraModule:ResetAndRecordSpringArmOffsets()
  local SpringArm = self:_EnsuredGetSpringArm()
  if not SpringArm then
    return
  end
  self.CacheSpringArmTargetOffset = UE4.FVector(SpringArm.TargetOffset)
  self.CacheSpringArmSocketOffset = UE4.FVector(SpringArm.SocketOffset)
  SpringArm:SetTargetOffset(UE4.FVector(), true)
  SpringArm.SocketOffset = UE4.FVector()
end

function CameraModule:ReturnSpringArmOffsets()
  local SpringArm = self:_EnsuredGetSpringArm()
  SpringArm:SetTargetOffset(self.CacheSpringArmTargetOffset)
  SpringArm.SocketOffset = self.CacheSpringArmSocketOffset
  SpringArm.bDoCollisionTest = true
  self.CacheSpringArmTargetOffset = nil
  self.CacheSpringArmSocketOffset = nil
end

function CameraModule:InitSpringArm(Center, Length, Rotation)
  local SpringArm = self:_EnsuredGetSpringArm()
  SpringArm.bUsePawnControlRotation = true
  SpringArm.bDoCollisionTest = false
  SpringArm.CameraRotationLagSpeed = 0
  SpringArm:Abs_K2_SetWorldLocation(Center, false, nil, true)
  SpringArm:K2_SetRelativeRotation(UE4.FRotator(0, 0, 0), false, nil, true)
  SpringArm:SetArmLength(Length, true)
  self:_EnsuredGetController():SetControlRotation(Rotation)
  SpringArm.isDialogCamera = true
  SpringArm:SetFinalTargetOffset(UE4.FVector())
  SpringArm:SetTargetOffset(UE4.FVector())
  SpringArm.constOffset = UE4.FVector()
  self:_EnsuredGetController().BP_RocoCameraControlComponent:EnableLag(false)
end

function CameraModule:RotateSpringArmAroundCamera(InDeltaPitch, Constants, CameraComponentLocation, InitSpringArmLength, InitControlRotation)
  local CurrentDirection = Constants.Center - CameraComponentLocation
  CurrentDirection:Normalize()
  local CurrentSpringArmLength = InitSpringArmLength
  local HelperVector = UE4.FVector(CurrentDirection.X, CurrentDirection.Y, CurrentDirection.Z - 100)
  local axis = CurrentDirection:Cross(HelperVector)
  local RotateDown = UE4.UKismetMathLibrary.RotatorFromAxisAndAngle(axis, InDeltaPitch)
  local RotatedDirection = RotateDown:RotateVector(CurrentDirection)
  local NewSpringArmLength = 1
  if 0 ~= RotatedDirection.X then
    NewSpringArmLength = CurrentSpringArmLength * CurrentDirection.X / RotatedDirection.X
  elseif 0 ~= RotatedDirection.Y then
    NewSpringArmLength = CurrentSpringArmLength * CurrentDirection.Y / RotatedDirection.Y
  else
    Log.Error("CameraModule: \228\184\187\230\172\161\231\155\174\230\160\135\231\150\145\228\188\188\228\184\186\229\144\140\228\184\128\228\184\170\239\188\140\229\133\136\230\163\128\230\159\165\233\133\141\231\189\174\239\188\140\230\178\161\233\151\174\233\162\152\231\154\132\232\175\157\229\176\177\230\137\190\229\188\128\229\143\145 ", RotateDown, CurrentDirection)
  end
  local Zoffset = NewSpringArmLength * RotatedDirection.Z - CurrentSpringArmLength * CurrentDirection.Z or 0
  local NewSpringArmOrigin = UE4.FVector(Constants.Center.X or 0, Constants.Center.Y or 0, Constants.Center.Z + Zoffset or 0)
  local ControllerRotation = InitControlRotation
  ControllerRotation.Pitch = ControllerRotation.Pitch + InDeltaPitch
  local NewSpringArmDirection = NewSpringArmOrigin - CameraComponentLocation
  local NewControlRotation = NewSpringArmDirection:ToRotator()
  local SpringArmLengthMultiplier = 1
  if self.CameraRequestConfig.SpringArmLengthMultiplier and 0 ~= self.CameraRequestConfig.SpringArmLengthMultiplier or self.CameraRequestConfig.Param2 and 0 ~= self.CameraRequestConfig.Param2 then
    SpringArmLengthMultiplier = self.CameraRequestConfig.SpringArmLengthMultiplier or tonumber(self.CameraRequestConfig.Param2) or 1
  end
  local PitchOffset = 0
  if self.CameraRequestConfig.PitchOffset or self.CameraRequestConfig.Param3 then
    PitchOffset = 0 - (self.CameraRequestConfig.PitchOffset or tonumber(self.CameraRequestConfig.Param3))
  end
  NewControlRotation.Pitch = NewControlRotation.Pitch + PitchOffset
  self:InitSpringArm(NewSpringArmOrigin, NewSpringArmLength * SpringArmLengthMultiplier, NewControlRotation)
end

function CameraModule:DoOnTick()
  if not self.bCameraOnUse then
    return
  end
  if not self.CameraRequestConfig.bTickCameraInModule then
    return
  elseif self.CameraRequestConfig.bTickCameraInModule then
    self.CameraTickFunction(self:GetActiveCamera())
  elseif self.CameraMotionMap and self.CameraMotionMap[self.CameraMotionRequestInfo.CameraType] then
    self.CameraMotionMap[self.CameraMotionRequestInfo.CameraType](self:GetActiveCamera())
  end
end

function CameraModule:_GenerateConstantTable(Config)
  local ConstantTable = {
    MainToSubOffset = 0,
    TargetDistance = 0,
    HorizontalFOV = 0,
    VerticalFOV = 0,
    MainTargetNeckLocation = 0,
    SubTargetNeckLocation = 0,
    Center = nil,
    CameraFacingLeft = true
  }
  
  local function _GetNeckLocation(InCharacter)
    local View = DialogueUtils.ExtraActorView(InCharacter)
    local meshComp
    if not View then
      return InCharacter:GetActorLocation()
    end
    meshComp = View.Mesh
    if not meshComp then
      local Comps = View:K2_GetComponentsByClass(UE.UMeshComponent)
      for _, comp in tpairs(Comps) do
        if comp:ComponentHasTag("IgnoreInMat") then
        elseif comp:IsA(UE.UMeshComponent) then
        elseif comp.SkeletalMesh or comp.StaticMesh then
          meshComp = comp
          break
        end
      end
    end
    if not meshComp then
      return InCharacter:GetActorLocation()
    else
      local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
      local socketNameBody = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
      local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
      local posBody = meshComp:Abs_GetSocketLocation(socketNameBody)
      local NeckPos = (posHead + posBody) / 2
      local HalfHeight = InCharacter:GetHalfHeight()
      if HalfHeight < 1 and meshComp.SkeletalMesh then
        HalfHeight = meshComp.SkeletalMesh:GetImportedBounds().BoxExtent.Y
      end
      if HalfHeight > 1 then
        NeckPos = View:Abs_K2_GetActorLocation()
        NeckPos.Z = posBody.Z + HalfHeight * 0.5
      end
      return NeckPos
    end
  end
  
  if Config.SubTarget then
    ConstantTable.SubTargetNeckLocation = _GetNeckLocation(Config.SubTarget)
  end
  if Config.MainTarget then
    ConstantTable.MainTargetNeckLocation = _GetNeckLocation(Config.MainTarget)
  end
  if Config.MainTarget and Config.SubTarget then
    local offset = ConstantTable.SubTargetNeckLocation - ConstantTable.MainTargetNeckLocation
    ConstantTable.MainToSubOffset = offset
    ConstantTable.TargetDistance = math.sqrt(offset:Dot(offset))
    ConstantTable.Center = offset / 2 + ConstantTable.MainTargetNeckLocation
  end
  local CameraComponent = self:_EnsuredGetCameraComponent()
  ConstantTable.HorizontalFOV = CameraComponent.FieldOfView
  ConstantTable.VerticalFOV = math.asin(math.sin(math.rad(CameraComponent.FieldOfView)) / CameraComponent.AspectRatio) * 57.2958
  return ConstantTable
end

function CameraModule:DecideMainSubFromParam(reverse)
  local function SetMainAndSub(Main, Sub)
    if reverse then
      self.CameraRequestConfig.MainTarget = Sub or self.CameraRequestConfig.MainTarget
      
      self.CameraRequestConfig.SubTarget = Main or self.CameraRequestConfig.SubTarget
    else
      self.CameraRequestConfig.MainTarget = Main or self.CameraRequestConfig.SubTarget
      self.CameraRequestConfig.SubTarget = Sub or self.CameraRequestConfig.MainTarget
    end
  end
  
  if (not self.CameraRequestConfig.TargetActorID2nd or 0 == self.CameraRequestConfig.TargetActorID2nd) and (not self.CameraRequestConfig.Param4 or 0 == self.CameraRequestConfig.Param4) or (not self.CameraRequestConfig.TargetActorID or 0 == self.CameraRequestConfig.TargetActorID) and self.CameraRequestConfig.Param1 == nil then
    local bMainIsPlayer = -1 == self.CameraRequestConfig.TargetActorID or self.CameraRequestConfig.Param1 == "-1"
    if bMainIsPlayer then
      SetMainAndSub(self.CameraRequestConfig.PlayerTarget, self.CameraRequestConfig.NpcTarget)
    else
      SetMainAndSub(self.CameraRequestConfig.NpcTarget, self.CameraRequestConfig.PlayerTarget)
    end
  else
    local Target = self.CameraRequestConfig.TargetActorID or tonumber(self.CameraRequestConfig.Param1)
    local NpcId = self.CameraRequestConfig.TargetActorID2nd or tonumber(self.CameraRequestConfig.Param4)
    local Actor = DialogueUtils.GrabActor(NpcId, self.CameraRequestConfig.fsm)
    if not Actor then
      Log.Error("\233\149\156\229\164\180\230\151\160\230\179\149\230\137\190\229\136\176Npc: ", NpcId, ",\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\227\128\130\229\143\175\232\131\189\230\152\175id\230\156\137\232\175\175\230\136\150Npc\230\178\161\231\148\159\230\136\144")
      SetMainAndSub(self.CameraRequestConfig.PlayerTarget, self.CameraRequestConfig.NpcTarget)
      return
    end
    if -3 == Target then
      SetMainAndSub(Actor, self.CameraRequestConfig.NpcTarget)
    elseif -4 == Target then
      SetMainAndSub(self.CameraRequestConfig.NpcTarget, Actor)
    elseif -1 == Target then
      SetMainAndSub(self.CameraRequestConfig.PlayerTarget, Actor)
    elseif -2 == Target then
      SetMainAndSub(Actor, self.CameraRequestConfig.PlayerTarget)
    else
      Log.Error("\231\155\174\230\160\135\229\143\130\230\149\176\233\157\158\230\179\149", Target)
    end
  end
end

function CameraModule:RequestRocoCameraAndInit()
  Log.Debug("RequestRocoCameraAndInit")
  local Controller = self:_EnsuredGetController()
  local Location = Controller.PlayerCameraManager.CameraLocation
  local Rotation = Controller.PlayerCameraManager.CameraRotation
  self:_EnsuredGetCamera():K2_SetActorLocationAndRotation(Location, Rotation, false, nil, true)
  self:_EnsuredGetController():RequestRocoCamera(0)
end

function CameraModule:SetCloseUpCamera()
  local inputComponent = self.CameraRequestConfig.InputComponent or self.CameraRequestConfig.PlayerTarget.inputComponent
  if inputComponent then
    inputComponent:SetCameraControlEnable(self.CameraRequestConfig.CameraUser or self, false)
  end
  self:DecideMainSubFromParam()
  self.Debug = false
  local Constants = self:_GenerateConstantTable(self.CameraRequestConfig)
  local CameraInitLocation = self:_EnsuredGetController().PlayerCameraManager:GetCameraLocation()
  CameraInitLocation = SceneUtils.ConvertRelativeToAbsolute(CameraInitLocation)
  self:_EnsuredRequestRocoCamera(self.CameraRequestConfig)
  local DefaultZoffset = 0
  local bIsMainTargetAtLeft = CameraUtils.IsMainTargetAtLeft(CameraInitLocation, self.CameraRequestConfig.MainTarget:GetActorLocation(), self.CameraRequestConfig.SubTarget:GetActorLocation())
  if self.CameraRequestConfig.PlayerTarget == self.CameraRequestConfig.MainTarget then
  else
    DefaultZoffset = -15
  end
  local HorizontalOffset = UE4.FVector(Constants.MainToSubOffset.X, Constants.MainToSubOffset.Y, 0)
  local SpringArmOrigin = HorizontalOffset * 0.25 + Constants.MainTargetNeckLocation
  local Distance = math.sqrt(HorizontalOffset:Dot(HorizontalOffset))
  SpringArmOrigin.Z = Constants.MainTargetNeckLocation.Z
  local MainToOrigin = Constants.MainTargetNeckLocation - SpringArmOrigin
  local SpringArmRotation = MainToOrigin:ToRotator()
  if self.CameraRequestConfig.YawOffset or self.CameraRequestConfig.Param2 then
    local YawOffset = self.CameraRequestConfig.YawOffset or tonumber(self.CameraRequestConfig.Param2)
    if bIsMainTargetAtLeft then
      YawOffset = 0 - YawOffset
    end
    SpringArmRotation.Yaw = SpringArmRotation.Yaw + YawOffset
  end
  if self.CameraRequestConfig.ZOffset or self.CameraRequestConfig.Param3 then
    local CameraZOffset = self.CameraRequestConfig.ZOffset or tonumber(self.CameraRequestConfig.Param3)
    SpringArmOrigin.Z = SpringArmOrigin.Z + CameraZOffset
  end
  SpringArmOrigin.Z = SpringArmOrigin.Z + DefaultZoffset
  local SpringArmLengthMultiplier = 1.0
  self:InitSpringArm(SpringArmOrigin, 0.56 * Distance * SpringArmLengthMultiplier, SpringArmRotation)
end

function CameraModule:SetDoubleUpCamera()
  local inputComponent = self.CameraRequestConfig.InputComponent or self.CameraRequestConfig.PlayerTarget.inputComponent
  if inputComponent then
    inputComponent:SetCameraControlEnable(self.CameraRequestConfig.CameraUser or self, false)
  end
  self:DecideMainSubFromParam()
  local Constants = self:_GenerateConstantTable(self.CameraRequestConfig)
  local SpringArmLengthMultiplier = 1
  local PitchOffset = -5
  local CameraInitLocation = self:_EnsuredGetController().PlayerCameraManager:GetCameraLocation()
  self:_EnsuredRequestRocoCamera(self.CameraRequestConfig)
  CameraInitLocation = SceneUtils.ConvertRelativeToAbsolute(CameraInitLocation)
  local bIsMainTargetAtLeft = CameraUtils.IsMainTargetAtLeft(CameraInitLocation, self.CameraRequestConfig.MainTarget:GetActorLocation(), self.CameraRequestConfig.SubTarget:GetActorLocation())
  local SpringArmDirection
  if bIsMainTargetAtLeft then
    local HelpVector = UE4.FVector(Constants.MainToSubOffset.X, Constants.MainToSubOffset.Y, Constants.MainToSubOffset.Z - 100)
    local Norm = Constants.MainToSubOffset:Cross(HelpVector)
    Norm:Normalize()
    SpringArmDirection = Norm
  else
    local HelpVector = UE4.FVector(Constants.MainToSubOffset.X, Constants.MainToSubOffset.Y, Constants.MainToSubOffset.Z + 100)
    local Norm = Constants.MainToSubOffset:Cross(HelpVector)
    Norm:Normalize()
    SpringArmDirection = Norm
  end
  local SpringArmLength = 1.5 * Constants.TargetDistance / math.tan(math.rad(Constants.HorizontalFOV) / 2)
  local InitSpringArmDirection = Constants.Center - Constants.MainTargetNeckLocation
  local InitControlRotation = InitSpringArmDirection:ToRotator()
  if self.CameraRequestConfig.SpringArmLengthMultiplier and 0 ~= self.CameraRequestConfig.SpringArmLengthMultiplier or self.CameraRequestConfig.Param2 and 0 ~= self.CameraRequestConfig.Param2 then
    SpringArmLengthMultiplier = self.CameraRequestConfig.SpringArmLengthMultiplier or tonumber(self.CameraRequestConfig.Param2) or 1
  end
  if self.CameraRequestConfig.PitchOffset or self.CameraRequestConfig.Param3 then
    PitchOffset = PitchOffset - (self.CameraRequestConfig.PitchOffset or tonumber(self.CameraRequestConfig.Param3))
  end
  InitControlRotation.Yaw = SpringArmDirection:ToRotator().Yaw
  InitControlRotation.Pitch = InitControlRotation.Pitch + PitchOffset
  local OneThirdFOVRotation = math.atan(0.3333333333333333 * math.tan(math.rad(Constants.VerticalFOV) / 2)) * 57.2958
  local InitControlDirection = InitControlRotation:ToVector()
  local CameraComponentLocation = Constants.Center - InitControlDirection * SpringArmLength
  if DialogueConst.DoubleUpCameraZoffset then
    CameraComponentLocation.Z = CameraComponentLocation.Z - DialogueConst.DoubleUpCameraZoffset
  else
    CameraComponentLocation.Z = CameraComponentLocation.Z - 50
  end
  self:RotateSpringArmAroundCamera(OneThirdFOVRotation, Constants, CameraComponentLocation, SpringArmLength, InitControlRotation)
end

function CameraModule:SetOverShoulderCamera()
  local inputComponent = self.CameraRequestConfig.InputComponent or self.CameraRequestConfig.PlayerTarget.inputComponent
  if inputComponent then
    inputComponent:SetCameraControlEnable(self.CameraRequestConfig.CameraUser or self, false)
  end
  local CameraInitLocation = self:_EnsuredGetController().PlayerCameraManager:GetCameraLocation()
  self:_EnsuredRequestRocoCamera(self.CameraRequestConfig)
  self:DecideMainSubFromParam(true)
  local CameraComponent = self:_EnsuredGetCameraComponent()
  if DialogueConst.FOV then
    CameraComponent:SetFieldOfView(DialogueConst.FOV)
  end
  local Constants = self:_GenerateConstantTable(self.CameraRequestConfig)
  Constants.Center.Z = Constants.Center.Z
  CameraInitLocation = SceneUtils.ConvertRelativeToAbsolute(CameraInitLocation)
  self.Debug = false
  local bIsMainTargetAtLeft = CameraUtils.IsMainTargetAtLeft(CameraInitLocation, self.CameraRequestConfig.MainTarget:GetActorLocation(), self.CameraRequestConfig.SubTarget:GetActorLocation())
  local MainToCameraToMidAngle = math.atan(math.tan(math.rad(Constants.HorizontalFOV / 2)) / 5)
  local SubToCameraToMidAngle = math.atan(math.tan(math.rad(1.1 * Constants.HorizontalFOV / 2)) / 10)
  local CircleCenterMain, RMain = CameraUtils.GetXYPlaneCircle(Constants.MainTargetNeckLocation, Constants.Center, MainToCameraToMidAngle)
  local CircleCenterSub, RSub = CameraUtils.GetXYPlaneCircle(Constants.Center, Constants.SubTargetNeckLocation, SubToCameraToMidAngle)
  local CircleCenterOffset = CircleCenterSub - CircleCenterMain
  local CircleCenterDistance = math.sqrt(CircleCenterOffset:Dot(CircleCenterOffset))
  CircleCenterOffset:Normalize()
  local Center2D = UE4.FVector2D(Constants.Center.X, Constants.Center.Y)
  local TriangleArea = CameraUtils.GetTriangleArea(Center2D, CircleCenterMain, CircleCenterSub)
  local ProjectionLength = 2 * TriangleArea / CircleCenterDistance
  local CenterOffsetOrthogonalDirection = UE4.FVector2D(CircleCenterOffset.Y, -CircleCenterOffset.X)
  local HorizontalSpringArmLength = 2 * math.abs(ProjectionLength)
  local MainToSub2D = UE4.FVector2D(Constants.MainToSubOffset.X, Constants.MainToSubOffset.Y)
  MainToSub2D:Normalize()
  local HorizontalSpringArmRotation = math.acos(math.abs(MainToSub2D:Dot(CenterOffsetOrthogonalDirection))) * 57.2958
  local InitSpringArmDirection = Constants.Center - Constants.MainTargetNeckLocation
  local InitControlRotation = InitSpringArmDirection:ToRotator()
  local TargetZoffset = 30 + Constants.MainTargetNeckLocation.Z - Constants.Center.Z
  local InitPitch = math.atan(TargetZoffset / HorizontalSpringArmLength) * 57.2958
  local InitSpringArmLength = HorizontalSpringArmLength / math.cos(math.abs(math.rad(InitPitch)))
  if not bIsMainTargetAtLeft then
    InitControlRotation.Yaw = InitControlRotation.Yaw - HorizontalSpringArmRotation
  else
    InitControlRotation.Yaw = InitControlRotation.Yaw + HorizontalSpringArmRotation
  end
  InitControlRotation.Pitch = 0 - InitPitch
  local OneThirdFOVRotation = math.atan(0.3333333333333333 * math.tan(math.rad(Constants.VerticalFOV) / 2)) * 57.2958
  local InitControlDirection = InitControlRotation:ToVector()
  local CameraComponentLocation = Constants.Center - InitControlDirection * InitSpringArmLength
  self:RotateSpringArmAroundCamera(OneThirdFOVRotation, Constants, CameraComponentLocation, InitSpringArmLength, InitControlRotation)
end

function CameraModule:SaveCurrentCamera(InCamera)
  self.SavedViewTarget = InCamera
end

function CameraModule:SetSkillCamera()
  local CameraPresetId = math.round(self.CameraRequestConfig.Param2)
  if not CameraPresetId then
    Log.Error("No Camera preset id passed in")
    self:FinishRequest()
    return
  end
  local SkillCameraConf = _G.DataConfigManager:GetCameraConf(CameraPresetId)
  if not SkillCameraConf then
    Log.Error("Camera conf invalid: ", CameraPresetId)
    self:FinishRequest()
    return
  end
  if not SkillCameraConf.skill_camera_path then
    Log.Error("No Camera skill path passed in")
    self:FinishRequest()
    return
  end
  if 1 == SkillCameraConf.interact_camera_param3 then
    self.CameraRequestConfig.bSetUpAndFinish = false
  end
  local mainTarget = DialogueUtils.GrabActorView(self.CameraRequestConfig.TargetActorID or tonumber(self.CameraRequestConfig.Param1), self.CameraRequestConfig.fsm)
  if not mainTarget then
    self:FinishRequest()
    return
  end
  local SkillComp = mainTarget.RocoSkill
  local SkillObj = RocoSkillProxy.Create(SkillCameraConf.skill_camera_path, SkillComp)
  if not SkillObj then
    self:FinishRequest()
    return
  end
  if _G.BattleManager.isInBattle then
    self:SaveCurrentCamera(_G.BattleManager.vBattleField.battleCameraManager.PCGCam)
  end
  local HideActors = {}
  local HideActorParam = SkillCameraConf.interact_camera_param1
  if not string.IsNilOrEmpty(HideActorParam) then
    local Splat = string.split(HideActorParam, ";")
    for _, StringID in ipairs(Splat) do
      local ID = tonumber(StringID)
      if ID then
        local Actor = DialogueUtils.GrabActorView(ID, self.CameraRequestConfig.fsm)
        if Actor then
          table.insert(HideActors, Actor)
        else
          Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150\230\156\137\230\149\136\231\154\132Actor", StringID, ID)
        end
      else
        Log.Debug("\229\161\171\229\133\165\231\154\132\229\143\130\230\149\176", StringID, "\230\151\160\230\179\149\232\167\163\230\158\144\228\184\186\229\173\151\231\172\166\228\184\178")
      end
    end
  end
  SkillObj:SetCaster(mainTarget)
  SkillObj:SetTargets(HideActors)
  SkillObj:RegisterEventCallback("End", self, self.OnSkillCameraEnd)
  SkillObj:RegisterEventCallback("PreEnd", self, self.OnSkillCameraEnd)
  SkillObj:RegisterEventCallback("PreEndAnim", self, self.OnSkillCameraEnd)
  SkillObj:RegisterEventCallback("PreStart", self, self.OnSkillCameraPreStart)
  SkillObj:SetAdditions("bSetupAndFinish", self.CameraRequestConfig.bSetUpAndFinish)
  SkillObj:SetAdditions("CameraType", self.CameraRequestConfig.CameraType)
  self.SkillComp = SkillComp
  self.SkillComp:StopCurrentSkill()
  SkillObj:PlaySkill()
end

function CameraModule:OnSkillCameraPreStart(Name, SkillObject)
  self.SkillObj = SkillObject
end

function CameraModule:OnSkillCameraEnd(Name, SkillObject)
  if not SkillObject then
    Log.Error("CameraModule:OnSkillCameraEnd can't find valid skill object")
    return
  end
  if not self or not self.SkillObj then
    Log.Error("CameraModule:OnSkillCameraEnd can't find self skill object")
    return
  end
  local Blackboard = self.SkillObj.Blackboard
  if Blackboard then
    Blackboard:SetValueAsObject("RocoCameraActor", nil)
    local CamActor = Blackboard:GetValueAsObject("camActor_0001")
    local SkeletalMeshActor = Blackboard:GetValueAsObject("camActor_0001_SA")
    if CamActor ~= self.BattleSkillCamera and SkeletalMeshActor ~= self.BattleSkillCameraMesh then
      self:CleanUpBattleSkillCamera()
    end
    self.BattleSkillCamera = CamActor
    self.BattleSkillCameraMesh = SkeletalMeshActor
    Blackboard:SetValueAsObject("camActor_0001", nil)
    Blackboard:SetValueAsObject("camActor_0001_SA", nil)
  end
  if self.CameraRequestConfig and self.CameraRequestConfig.CameraType ~= Enum.NpcInteractCameraType.NIC_SKILL then
    Log.Error("ChangeBackToSavedCamera", table.getKeyName(Enum.NpcInteractCameraType, self.CameraRequestConfig.CameraType))
    self:ChangeBackToSavedCamera()
  end
  local bSetupAndFinish = self.SkillObj:GetAddition("bSetupAndFinish")
  if not bSetupAndFinish then
    self:FinishRequest()
  end
end

function CameraModule:ChangeBackToSavedCamera()
  if self.SavedViewTarget then
    if _G.BattleManager.isInBattle then
      _G.BattleManager.vBattleField.battleCameraManager:BindCamera()
    else
      self:_EnsuredGetController():SetViewTargetWithBlend(self.SavedViewTarget)
    end
    self.SavedViewTarget = nil
  else
    Log.Warning("no saved view target")
  end
end

function CameraModule:CleanUpBattleSkillCamera()
  if self.BattleSkillCamera and UE.UObject.IsValid(self.BattleSkillCamera) then
    Log.Debug("\230\184\133\231\144\134\230\136\152\230\150\151\228\184\173\229\175\185\232\175\157\233\149\156\229\164\180", UE.UObject.GetName(self.BattleSkillCamera))
    self.BattleSkillCamera:K2_DestroyActor()
  end
  self.BattleSkillCamera = nil
  if self.BattleSkillCameraMesh and UE.UObject.IsValid(self.BattleSkillCameraMesh) then
    Log.Debug("\230\184\133\231\144\134\230\136\152\230\150\151\228\184\173\229\175\185\232\175\157\233\149\156\229\164\180", UE.UObject.GetName(self.BattleSkillCameraMesh))
    self.BattleSkillCameraMesh:K2_DestroyActor()
  end
  self.BattleSkillCameraMesh = nil
end

function CameraModule:OnSkillCameraLoadFailed()
  Log.Error("skill camera load fail")
end

local DrawCamera = false

function CameraModule:SetFreeCamera()
  local inputComponent = self.CameraRequestConfig.InputComponent or self.CameraRequestConfig.PlayerTarget.inputComponent
  if inputComponent then
    inputComponent:SetCameraControlEnable(self.CameraRequestConfig.CameraUser or self, false)
  end
  local Camera = self.CameraHolder:GetNextCamera()
  local CameraComp = Camera.CameraComponent
  local Param4Parts = string.split(self.CameraRequestConfig.Param4 or "", ";")
  local FOV = self.CameraRequestConfig.FOV or tonumber(Param4Parts[1]) or 90
  local TargetActorID = self.CameraRequestConfig.TargetActorID or self.CameraRequestConfig.Param2
  local ActorTrans, _, TargetActor = DialogueUtils.GrabActorTransform(TargetActorID, self.CameraRequestConfig.fsm)
  if not ActorTrans then
    TargetActor = self.CameraRequestConfig.NpcTarget
    ActorView = DialogueUtils.ExtraActorView(TargetActor)
    if ActorView then
      ActorTrans = ActorView:GetTransform()
    end
  end
  if TargetActor and TargetActor.DialogueTimelineTransformCache then
    ActorTrans = TargetActor.DialogueTimelineTransformCache
  end
  local CameraTransform
  local HasValidLocation = self.CameraRequestConfig.RelativeLocation and not UE.FVector.IsNearlyZero(self.CameraRequestConfig.RelativeLocation, 0.01)
  local HasValidRotation = self.CameraRequestConfig.RelativeRotation and not UE.FRotator.IsNearlyZero(self.CameraRequestConfig.RelativeRotation, 0.001)
  if ActorTrans and HasValidLocation and HasValidRotation then
    local Rot = UE.FRotator(self.CameraRequestConfig.RelativeRotation.Pitch, self.CameraRequestConfig.RelativeRotation.Yaw, self.CameraRequestConfig.RelativeRotation.Roll)
    local Loc = UE.FVector(self.CameraRequestConfig.RelativeLocation.X, self.CameraRequestConfig.RelativeLocation.Y, self.CameraRequestConfig.RelativeLocation.Z)
    local RelativeTransform = UE.FTransform(Rot:ToQuat(), Loc)
    CameraTransform = RelativeTransform * ActorTrans
  elseif string.IsNilOrEmpty(self.CameraRequestConfig.Param1) then
    CameraTransform = self.CameraHolder:GetCurrentViewTransform()
  elseif ActorTrans then
    local Param1Parts = string.split(self.CameraRequestConfig.Param1 or "", ";")
    local X = tonumber(Param1Parts[1]) or 0
    local Y = tonumber(Param1Parts[2]) or 0
    local Z = tonumber(Param1Parts[3]) or 0
    local Roll = tonumber(Param1Parts[4]) or 0
    local Pitch = tonumber(Param1Parts[5]) or 0
    local Yaw = tonumber(Param1Parts[6]) or 0
    local Rot = UE.FRotator(Pitch, Yaw, Roll)
    local Loc = UE.FVector(X, Y, Z)
    local RelativeTransform = UE.FTransform(Rot:ToQuat(), Loc)
    CameraTransform = RelativeTransform * ActorTrans
  else
    CameraTransform = self.CameraHolder:GetCurrentViewTransform()
  end
  if CameraTransform then
    Camera:K2_SetActorTransform(CameraTransform, false, nil, false)
    CameraComp:ResetRelativeTransform()
  end
  CameraComp.FieldOfView = FOV
  local BlendType = self:ConvertCameraBlendType(self.CameraRequestConfig.BlendType)
  local BlendTime = self.CameraRequestConfig.BlendTime
  if BlendType == UE.EViewTargetBlendFunction.VTBlend_MAX then
    BlendTime = 0
  end
  self.CameraHolder:Activate(BlendTime, BlendType, self.CameraRequestConfig.BlendExp)
end

function CameraModule:ConvertCameraBlendType(BlendType)
  if BlendType == Enum.CameraBlendType.CBT_NONE then
    return UE.EViewTargetBlendFunction.VTBlend_Cubic
  elseif BlendType == Enum.CameraBlendType.CBT_LINEAR then
    return UE.EViewTargetBlendFunction.VTBlend_Linear
  elseif BlendType == Enum.CameraBlendType.CBT_CUBIC then
    return UE.EViewTargetBlendFunction.VTBlend_Cubic
  elseif BlendType == Enum.CameraBlendType.CBT_EASE_IN then
    return UE.EViewTargetBlendFunction.VTBlend_EaseIn
  elseif BlendType == Enum.CameraBlendType.CBT_EASE_OUT then
    return UE.EViewTargetBlendFunction.VTBlend_EaseOut
  elseif BlendType == Enum.CameraBlendType.CBT_EASE_IN_OUT then
    return UE.EViewTargetBlendFunction.VTBlend_EaseInOut
  else
    return UE.EViewTargetBlendFunction.VTBlend_MAX
  end
end

function CameraModule:OnDeactive()
  self:DeleteSplineManager()
end

function CameraModule:DeleteSplineManager()
  if UE.UObject.IsValid(self.SplineManager) and self.SplineManager then
    if self.SplineManager.K2_DestroyActor then
      self.SplineManager:K2_DestroyActor()
    end
    self.SplineManager = nil
    self.SplineManagerRef = nil
  end
end

function CameraModule:OnDestruct()
end

function CameraModule:StopCameraSkillPlaying()
  if not self.SkillComp then
    Log.Debug("No CameraSkill Playing")
    return
  end
  if not UE.UObject.IsValid(self.SkillComp) then
    return
  end
  self.SkillComp:StopCurrentSkill()
end

function CameraModule:CameraMoveBlendToBigWorld(DeltaTime)
  local bEndOnThisTick = not self:UpdateMotionTimeAndValidate(DeltaTime)
  if self:IsCameraMotionValid() then
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local NextTransform = self:CalculateNextMotionTransform()
    if self:CheckIfCameraHitObstacles(NextTransform) then
      self.CameraBlocked = true
    else
      local CurrentRotation = CameraComponent:K2_GetComponentRotation()
      local NextRotation = NextTransform.Rotation:ToRotator()
      NextRotation.Roll = CurrentRotation.Roll
      CameraComponent:Abs_K2_SetWorldLocation(NextTransform.Translation, false, nil, true)
      CameraComponent:K2_SetWorldRotation(NextRotation, false, nil, true)
      self.PrevLoc = NextTransform
    end
  end
  if bEndOnThisTick then
    self:OnCameraMotionDone()
    return
  end
end

function CameraModule:CameraMoveRounded(DeltaTime)
  if not self:UpdateMotionTimeAndValidate(DeltaTime) then
    self:OnCameraMotionDone()
    return
  end
  local CameraComponent = self:_EnsuredGetCameraComponent()
  local SpringArm = self:_EnsuredGetSpringArm()
  local HasValidCameraHolder = self.CameraHolder and self.CameraHolder:GetCurrentCamera()
  if not (CameraComponent and SpringArm) or HasValidCameraHolder then
    Log.Error("\230\178\161\230\156\137SpringArm\231\154\132\233\149\156\229\164\180\229\166\130NIC_4(\232\135\170\231\148\177\233\149\156\229\164\180)\230\151\160\230\179\149\228\189\191\231\148\168NpcInteractCameraMoveType.CAMERA_MOVE_ROUNDED")
    self:OnCameraMotionDone()
    return
  end
  if self:IsCameraMotionValid() then
    local SpringArmLocation = SpringArm:Abs_K2_GetComponentLocation()
    local CameraToSpringArm = SpringArmLocation - CameraComponent:Abs_K2_GetComponentLocation()
    local RotationValue = UE.UKismetMathLibrary.Ease(0, self.CameraMotionInfo.CameraRotationValue, self.MotionProgressPercent, 6, 2)
    if self.CameraMotionInfo.CameraRotationAxis == nil then
      self.CameraMotionInfo.CameraRotationAxis = UE4Helper.UpVector
      Log.Error("CameraRotationAxis empty\239\188\129\239\188\129\239\188\129")
    end
    if nil == RotationValue then
      RotationValue = 0
      Log.Error("RotationValue empty\239\188\129\239\188\129\239\188\129")
    end
    local RotatedCameraToSpringArm = CameraToSpringArm:RotateAngleAxis(RotationValue, self.CameraMotionInfo.CameraRotationAxis)
    if not RotatedCameraToSpringArm then
      Log.Error("Cameramodule:RotatedCameraToSpringArm is empty!!!!!!!!!!!!!!!")
      return
    end
    if not self.CameraMotionInfo.InitCameraTransform.Translation then
      Log.Error("Cameramodule:InitCameraTransform.Translation is empty!!!!!!!!!!!!!!!")
      return
    end
    local NextLocation = self.CameraMotionInfo.InitCameraTransform.Translation + RotatedCameraToSpringArm - CameraToSpringArm
    if self:CheckIfCameraHitObstacles(NextLocation, true) then
      self.CameraBlocked = true
    else
      CameraComponent:Abs_K2_SetWorldLocation(self.CameraMotionInfo.InitCameraTransform.Translation + RotatedCameraToSpringArm - CameraToSpringArm, false, nil, true)
      local TargetViewLocation = SpringArmLocation
      local TempRot = UE.UKismetMathLibrary.FindLookAtRotation(self.CameraMotionInfo.InitCameraTransform.Translation + RotatedCameraToSpringArm - CameraToSpringArm, TargetViewLocation)
      CameraComponent:K2_SetWorldRotation(TempRot, false, nil, true)
      self.PrevLoc = NextLocation
    end
  end
end

function CameraModule:CameraMovePath(DeltaTime)
  local bEndOnThisTick = not self:UpdateMotionTimeAndValidate(DeltaTime)
  if self:IsCameraMotionValid() then
    if self.SplineManager and not self.SplineManager:HasSpline() then
      self:DeleteSplineManager()
      self.SplineManager = UE4Helper.GetCurrentWorld():Abs_SpawnActor(_G.NRCBigWorldPreloader:Get("CAM_SplineManger"), UE4.FTransform(UE4.FQuat(0, 0, 0, 1), UE4.FVector(0, 0, 500)), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
      self.SplineManagerRef = UnLua.Ref(self.SplineManager)
    end
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local PathConfig = DataConfigManager:GetCameraPath(self.CameraMotionInfo.CustomConfig.AreaId, true)
    local NextLocation, NextRotation
    if PathConfig then
      NextLocation, NextRotation = self:PathMoveCalculateNextMotionTransformByPathConfig(PathConfig, self.CameraMotionInfo.CustomConfig.bReverse)
    else
      local AreaConfig = DataConfigManager:GetAreaConf(self.CameraMotionInfo.CustomConfig.AreaId)
      NextLocation, NextRotation = self:PathMoveCalculateNextMotionTransform(AreaConfig, self.CameraMotionInfo.CustomConfig.bReverse)
    end
    local NextTransform = UE4.FTransform()
    NextTransform.Translation = NextLocation
    NextTransform.Rotation = NextRotation:ToQuat()
    if self:CheckIfCameraHitObstacles(NextLocation) then
      self.CameraBlocked = true
    else
      if 0 == self.CameraMotionInfo.CustomConfig.FocusNpcId[1] then
        if self:SetCameraFocusOnForward(NextTransform) then
          CameraComponent:Abs_K2_SetWorldLocation(NextLocation, false, nil, true)
        end
      else
        local NpcConfig = _G.DataConfigManager:GetNpcRefreshContentConf(self.CameraMotionInfo.CustomConfig.FocusNpcId[1])
        if NpcConfig and 0 ~= NpcConfig.refresh_param then
          CameraComponent:Abs_K2_SetWorldLocation(NextLocation, false, nil, true)
          self:SetCameraFocusOnNpc(NpcConfig)
        elseif self:SetCameraFocusOnForward(NextTransform) then
          CameraComponent:Abs_K2_SetWorldLocation(NextLocation, false, nil, true)
        end
      end
      self.PrevLoc = NextTransform
    end
  end
  if bEndOnThisTick then
    self:OnCameraMotionDone()
    return
  end
end

function CameraModule:PathMoveCalculateNextMotionTransform(AreaConf, bReverse)
  if not AreaConf then
    Log.Error("CameraModule:PathMoveCalculateNextMotionTransform:Area Conf empty")
    return
  end
  local Progress = self.MotionProgressPercent
  if bReverse then
    Progress = 1 - self.MotionProgressPercent
  end
  return self.SplineManager:GetNextLocation(AreaConf, self.MotionProgressPercent)
end

function CameraModule:PathMoveCalculateNextMotionTransformByPathConfig(PathConfig, bReverse)
  if not PathConfig then
    Log.Error("CameraModule:PathMoveCalculateNextMotionTransform:Area Conf empty")
    return
  end
  local Progress = self.MotionProgressPercent
  if bReverse then
    Progress = 1 - self.MotionProgressPercent
  end
  return self.SplineManager:GetNextLocationByCameraPath(PathConfig, self.MotionProgressPercent)
end

function CameraModule:SetCameraFocusOnNpc(NpcConfig)
  local AreaConf = _G.DataConfigManager:GetAreaConf(NpcConfig.refresh_param)
  local pos = AreaConf.pos[1].position_xyz
  local NpcLocation = UE4.FVector(pos[1], pos[2], pos[3])
  local CameraComponent = self:_EnsuredGetCameraComponent()
  local CameraLocation = CameraComponent:Abs_K2_GetComponentToWorld().Translation
  CameraComponent:K2_SetWorldRotation(UE4.UKismetMathLibrary.FindLookAtRotation(CameraLocation, NpcLocation), false, nil, true)
end

function CameraModule:SetCameraFocusOnForward(NextLocation)
  local CameraComponent = self:_EnsuredGetCameraComponent()
  local Result = NextLocation.Rotation
  if 1 == self.MotionProgressPercent then
    return true
  end
  CameraComponent:K2_SetWorldRotation(Result:ToRotator(), false, nil, true)
  return true
end

function CameraModule:GetProgressWithOffset()
  return self.MotionProgressPercent + self.MotionProgressOffset
end

function CameraModule:CameraMoveLine(DeltaTime)
  if not self:UpdateMotionTimeAndValidate(DeltaTime) then
    self:OnCameraMotionDone()
    return
  end
  if self:IsCameraMotionValid() and self.CameraMotionInfo.CustomConfig then
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local NextLocation = self:CalculateNextMotionTransform(self.CameraMotionInfo.CustomConfig.bReverse)
    if self:CheckIfCameraHitObstacles(NextLocation) then
      self.CameraBlocked = true
    else
      CameraComponent:Abs_K2_SetWorldLocation(NextLocation.Translation, false, nil, true)
      if 0 == self.CameraMotionInfo.CustomConfig.FocusNpcId[1] then
        self:SetCameraFocusOnForward(NextLocation)
      else
        local NpcConfig = _G.DataConfigManager:GetNpcRefreshContentConf(self.CameraMotionInfo.CustomConfig.FocusNpcId[1])
        if NpcConfig and 0 ~= NpcConfig.refresh_param then
          self:SetCameraFocusOnNpc(NpcConfig)
        else
          self:SetCameraFocusOnForward(NextLocation)
        end
      end
      self.PrevLoc = NextLocation
    end
  end
end

function CameraModule:CameraMoveHorizontal(DeltaTime)
  if not self:UpdateMotionTimeAndValidate(DeltaTime) then
  end
  if self:IsCameraMotionValid() then
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local NextLocation = self:CalculateNextMotionTransform()
    if self:CheckIfCameraHitObstacles(NextLocation, true) then
      self.CameraBlocked = true
    else
      self.PrevLoc = NextLocation
      CameraComponent:Abs_K2_SetWorldLocation(NextLocation.Translation, false, nil, true)
    end
  end
end

function CameraModule:CameraMoveRotated(DeltaTime)
  if not self:UpdateMotionTimeAndValidate(DeltaTime) then
    self:OnCameraMotionDone()
    return
  end
  if self:IsCameraMotionValid() then
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local NextLocation = self:CalculateNextMotionTransform()
    if self:CheckIfCameraHitObstacles(NextLocation) then
      self.CameraBlocked = true
    else
      self.PrevLoc = NextLocation
      CameraComponent:Abs_K2_SetWorldLocation(NextLocation.Translation, false, nil, true)
      CameraComponent:K2_SetWorldRotation(NextLocation.Rotation:ToRotator(), false, nil, true)
    end
  end
end

function CameraModule:CameraMoveParallel(DeltaTime)
  if not self:UpdateMotionTimeAndValidate(DeltaTime) then
    self:OnCameraMotionDone()
    return
  end
  if self:IsCameraMotionValid() then
    local CameraComponent = self:_EnsuredGetCameraComponent()
    local NextLocation = self:CalculateNextMotionTransform()
    if self:CheckIfCameraHitObstacles(NextLocation) then
      self.CameraBlocked = true
    else
      self.PrevLoc = NextLocation
      CameraComponent:Abs_K2_SetWorldLocation(NextLocation.Translation, false, nil, false)
      CameraComponent:K2_SetWorldRotation(NextLocation.Rotation:ToRotator(), false, nil, false)
    end
  end
end

function CameraModule:UpdateMotionTimeAndValidate(DeltaTime)
  self.motionTime = self.motionTime + DeltaTime
  self.MotionProgressPercent = self.motionTime / self.CameraMotionInfo.CameraMoveTime
  if self.MotionProgressPercent >= 1 then
    self.MotionProgressPercent = 1
    return false
  else
    return true
  end
end

function CameraModule:CalculateNextMotionTransform(bReverse)
  local ProgressToUse = self.MotionProgressPercent or 0
  if bReverse then
    ProgressToUse = 1 - self.MotionProgressPercent
  end
  ProgressToUse = math.clamp(ProgressToUse, 0, 1)
  return UE.UKismetMathLibrary.TEase(self.CameraMotionInfo.InitCameraTransform, self.CameraMotionInfo.TargetCameraTransform, ProgressToUse, 6, 2)
end

function CameraModule:StopCameraMotion()
  self.CameraMotionInfo = nil
  self.OnTick = nil
  self:StopCameraTicking()
end

function CameraModule:InitCameraMotion()
  self.motionTime = 0
  self.CameraBlocked = false
  self.PrevLoc = nil
  self.MotionProgressOffset = 0
end

function CameraModule:IsCameraMotionValid()
  if self.CameraBlocked then
    return false
  elseif self.CameraMotionInfo and (self.CameraMotionInfo.TargetCameraTransform or self.CameraMotionInfo.CustomConfig) and (self.MotionProgressPercent or 0) <= 1 then
    return true
  end
end

function CameraModule:CheckIfCameraHitObstacles(NextLocation, ParameterAsVector)
  if self.CameraMotionInfo and self.CameraMotionInfo.NonStoppableByObstacle and not self.CameraMotionInfo.bSkipIfBlock then
    return false
  end
  if self.PrevLoc then
    local TestPrevTranslation, TestNextTranslation
    if ParameterAsVector then
      TestPrevTranslation = self.PrevLoc
      TestNextTranslation = NextLocation
    else
      TestPrevTranslation = self.PrevLoc.Translation
      TestNextTranslation = NextLocation.Translation
    end
    local Hit = UE4.UKismetSystemLibrary.Abs_SphereTraceSingle(UE4Helper.GetCurrentWorld(), TestPrevTranslation, TestNextTranslation, 30, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, true, nil)
    if Hit.Actor then
      local Namo = Hit.Actor:GetName()
      if Namo then
        local thing1 = string.find(Namo, "Rock")
        local thing5 = string.find(Namo, "Floor")
        local thing2 = string.find(Namo, "Foliage")
        local thing3 = string.find(Namo, "Landscape")
        local thing4 = string.find(Namo, "Tree")
        local thing6 = string.find(Namo, "SM_Stlmt")
        if thing1 and thing1 >= 0 or thing2 and thing2 >= 0 or thing3 and thing3 >= 0 or thing4 and thing4 >= 0 or thing5 and thing5 >= 0 or thing6 and thing6 >= 0 then
          return true
        end
      end
    end
  end
  return false
end

function CameraModule:GetCameraHolder()
  return self.CameraHolder
end

function CameraModule:RequestCameraDOF(bEnable, Scale, FocalDistance, FocalRegion, NearTransitionRegion, FarTransitionRegion)
  if not self.CameraHolder then
    return
  end
  if self.DOFEnable == bEnable and false == bEnable then
    return
  elseif self.DOFEnable == bEnable and true == bEnable and self.DOFScale == Scale and self.DOFFocalDistance == FocalDistance and self.DOFFocalRegion == FocalRegion and self.DOFNearTransitionRegion == NearTransitionRegion and self.DOFFarTransitionRegion == FarTransitionRegion then
    return
  end
  self.DOFEnable = bEnable
  self.DOFScale = Scale
  self.DOFFocalDistance = FocalDistance
  self.DOFFocalRegion = FocalRegion
  self.DOFNearTransitionRegion = NearTransitionRegion
  self.DOFFarTransitionRegion = FarTransitionRegion
  for _, CameraComponent in ipairs({
    self.CameraHolder:GetMainComponent(),
    self.CameraHolder:GetBackUpComponent()
  }) do
    if CameraComponent then
      if not bEnable then
        CameraComponent.PostProcessSettings.bOverride_MobileHQGaussian = false
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldFocalDistance = false
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldScale = false
      else
        Scale = Scale or 1.0
        FocalDistance = FocalDistance or 0.0
        FocalRegion = FocalRegion or 0.0
        NearTransitionRegion = NearTransitionRegion or 0.0
        FarTransitionRegion = FarTransitionRegion or 0.0
        CameraComponent.PostProcessSettings.bOverride_MobileHQGaussian = true
        CameraComponent.PostProcessSettings.bMobileHQGaussian = true
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldScale = true
        CameraComponent.PostProcessSettings.DepthOfFieldScale = Scale
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldFocalDistance = true
        CameraComponent.PostProcessSettings.DepthOfFieldFocalDistance = FocalDistance
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldFocalRegion = true
        CameraComponent.PostProcessSettings.DepthOfFieldFocalRegion = FocalRegion
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldNearTransitionRegion = true
        CameraComponent.PostProcessSettings.DepthOfFieldNearTransitionRegion = NearTransitionRegion
        CameraComponent.PostProcessSettings.bOverride_DepthOfFieldFarTransitionRegion = true
        CameraComponent.PostProcessSettings.DepthOfFieldFarTransitionRegion = FarTransitionRegion
      end
    end
  end
end

return CameraModule
