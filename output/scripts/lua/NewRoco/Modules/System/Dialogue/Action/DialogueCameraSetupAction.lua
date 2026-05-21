local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueConst = require("NewRoco.Modules.System.Dialogue.DialogueConst")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueCameraSetupAction = Base:Extend("DialogueCameraSetupAction")
FsmUtils.MergeMembers(Base, DialogueCameraSetupAction, {
  {name = "TargetNPC", type = "var"},
  {
    name = "TargetPetBp",
    type = "var"
  },
  {
    name = "DialogueConf",
    type = "var"
  },
  {
    name = "ParentModule",
    type = "var"
  },
  {
    name = "CameraSetting",
    type = "var"
  },
  {
    name = "TargetValue",
    type = "var"
  },
  {
    name = "SideOfTarget",
    type = "var"
  },
  {
    name = "SideOfCamera",
    type = "var"
  },
  {name = "Center", type = "var"}
})
DialogueCameraSetupAction.ConstantTable = {
  FOV = 90,
  HA = 0,
  RA = 0,
  HB = 0,
  RB = 0,
  CoorHA = UE4.FVector(),
  CoorHB = UE4.FVector(),
  Dh = 0,
  D3 = 0,
  H3 = 0,
  R3 = 0,
  CoorH3 = UE4.FVector()
}
DialogueCameraSetupAction.DetectionSettings = {near = 3000, far = 25000}

function DialogueCameraSetupAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.FinishDelayHandler = -1
  self.CameraChangeDelayHandler = -1
end

function DialogueCameraSetupAction:IsNormalInteraction(type)
  return type == Enum.NpcInteractCameraType.NIC_SIDECHESTSHOT or type == Enum.NpcInteractCameraType.NIC_MIDSYMMETRY or type == Enum.NpcInteractCameraType.NIC_OVERSHOULDER or type == Enum.NpcInteractCameraType.NIC_OBJECTIVESHOT
end

function DialogueCameraSetupAction:ApplySpringArm(springArmLength, Offset, MidPoint, Offsetter, Sub, Mainsub, Side, bUseOneThird)
  self.debug = false
  local cameraLerpTime = DialogueConst.EnterTime
  local ControllerTmp = DialogueUtils.GetController(self.Player)
  if self.CameraSetting.camera_switch_type == Enum.CameraSwitchType.CAMST_INSTANT or self.CameraSetting.camera_switch_type == Enum.CameraSwitchType.CAMST_BLACK or DialogueConst.ModifyOverShoulder then
    cameraLerpTime = 0
    if ControllerTmp then
      ControllerTmp.BP_RocoCameraControlComponent:EnableLag(false)
    end
  elseif ControllerTmp then
    ControllerTmp.BP_RocoCameraControlComponent:EnableLag(true)
  end
  local SpringArm = DialogueUtils.GetPlayerSpringArm(self.Player)
  local SpringArmLocation
  local SpringArmChannel = 0
  local SpringArmRadius = 0
  local SpringArmOffset, Center
  local TargMain = Mainsub or self.Player
  local Targ = Sub or self.TargetNPC
  if SpringArm then
    local meshComp = TargMain.viewObj:GetComponentByClass(UE4.UMeshComponent)
    local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
    local socketNameBody = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
    local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
    local posBody = meshComp:Abs_GetSocketLocation(socketNameBody)
    local TargInner = Targ
    local TargHalfH = 0
    if TargInner.GetHalfHeight then
      TargHalfH = TargInner:GetHalfHeight()
    end
    if Targ.viewObj then
      TargInner = Targ.viewObj
    end
    if 0 == TargHalfH then
      TargHalfH = self.ConstantTable.H3 * 0.5
    end
    local meshComp2 = TargInner:GetComponentByClass(UE4.UMeshComponent)
    local NeckPos2
    if meshComp2 then
      local posHead2 = meshComp2:Abs_GetSocketLocation(socketNameHead)
      local posBody2 = meshComp2:Abs_GetSocketLocation(socketNameBody)
      NeckPos2 = (posHead2 + posBody2) / 2
      if posHead2 == posBody2 then
        NeckPos2 = TargInner:Abs_K2_GetActorLocation()
        NeckPos2.Z = TargHalfH * 0.5 + NeckPos2.Z
      end
    else
      NeckPos2 = self.ConstantTable.CoorH3
    end
    local NeckPos = (posHead + posBody) / 2
    if MidPoint then
      SpringArm:Abs_K2_SetWorldLocation((NeckPos + NeckPos2) / 2, false, nil, false)
      SpringArm:K2_SetRelativeRotation(UE4.FRotator(0, 0, 0))
      Center = (NeckPos + NeckPos2) / 2
      local IgnoreZPlayer = UE4.FVector(NeckPos.X, NeckPos.Y, Center.Z)
      local IgnoreZTarget = UE4.FVector(NeckPos2.X, NeckPos2.Y, Center.Z)
      local PerpVec = IgnoreZPlayer - IgnoreZTarget
      self.ZDiffObj = NeckPos2.Z - NeckPos.Z
      PerpVec = UE4.FVector(PerpVec.Y, -PerpVec.X, PerpVec.Z)
      PerpVec:Normalize()
      if Offsetter then
        local Neck = NeckPos
        if Targ == Offsetter then
          Neck = NeckPos2
        end
        local Adjustment = Neck.Z - Center.Z
        Offset.Z = Offset.Z + Adjustment
      end
      if self.ObjSide then
        self.ParentModule.MoveDir = 1
        if self.ObjSide < 0 then
          PerpVec = PerpVec * -1
          self.ParentModule.MoveDir = -1
        end
      elseif self.SideKam >= 0 then
        PerpVec = PerpVec * -1
      end
      self.Centre = Center
      if self.debug then
        UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), NeckPos, 10, 10, UE4.FLinearColor(1, 0, 0, 1), 25, 2)
        UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), NeckPos2, 10, 10, UE4.FLinearColor(0, 1, 0, 1), 25, 2)
        UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), Center, 10, 10, UE4.FLinearColor(0, 0, 1, 1), 25, 2)
        UE4.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), IgnoreZPlayer, IgnoreZTarget, UE4.FLinearColor(1, 0, 1, 1), 25, 5)
        UE4.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), Center, Center + PerpVec * 30, UE4.FLinearColor(1, 1, 1, 1), 25, 5)
      end
      local Controller = DialogueUtils.GetController(self.Player)
      Controller:SetControlRotation(PerpVec:ToRotator())
    else
      SpringArm:Abs_K2_SetWorldLocation(NeckPos, false, nil, false)
      if self.debug then
        UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), NeckPos, 10, 10, UE4.FLinearColor(1, 0, 0, 1), 25, 2)
      end
    end
    SpringArm.ProbeChannel = DialogueConst.DefaultCameraChannel
    self.springArmLength = springArmLength
    if 0 == cameraLerpTime then
      SpringArm:SetArmLength(springArmLength, true)
      SpringArm.CameraRotationLagSpeed = 0
    else
      SpringArm:SetArmLength(springArmLength, false)
      local speed = _G.DataConfigManager:GetGlobalConfigByKeyType("camera_angle_speed", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str
      SpringArm.CameraRotationLagSpeed = tonumber(speed)
    end
    if Targ.DebugNPCNameAndID then
      SpringArm.DialogStateType = string.format("[DialogueCameraSetupAction:OnEnter] %s", Targ:DebugNPCNameAndID())
    end
    Offset = Offset or UE4.FVector()
    local OffsetSize = Offset:Size2D()
    if OffsetSize >= 800 then
      Log.Debug("Target NPC Location", tostring(Targ:GetActorLocation()))
      Log.Debug("Player Location", tostring(self.Player:GetActorLocation()))
      Log.Error("\229\137\167\230\131\133\231\155\184\230\156\186\229\135\186\233\148\153\229\149\166\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129")
    else
      if 0 == cameraLerpTime then
        SpringArm:SetTargetOffset(Offset, true)
      else
        SpringArm:SetTargetOffset(Offset, false)
      end
      SpringArm:SetLerpTime(cameraLerpTime, DialogueConst.CameraEase)
    end
    SpringArm.isDialogCamera = true
    SpringArm:SetFinalTargetOffset(Offset)
    SpringArm.constOffset = Offset
    SpringArmLocation = SpringArm:Abs_K2_GetComponentLocation()
    SpringArmOffset = Offset
    SpringArmChannel = SpringArm.ProbeChannel
    SpringArmRadius = SpringArm.ProbeSize
  else
    Log.Error("Can't find player's spring arm")
    return
  end
  SpringArm.SocketOffset = UE4.FVector(0, 0, 0)
  local Controller = DialogueUtils.GetController(self.Player)
  if Controller then
    if not self.ParentModule:CheckUICamera() then
      local savedTargetView = Controller.PlayerCameraManager.ViewTarget.Target
      self.ParentModule:SetSavedTargetView(self.fsm, savedTargetView)
    else
      self:SetPlayerVisible(self.Player, true)
      local savedTargetView = self.ParentModule:GetSavedTargetView(self.fsm)
      self:ChangeCamera(savedTargetView, cameraLerpTime, nil, Controller, self.DestructUICamera)
      self.ParentModule:SetUICamera(nil)
    end
    if not MidPoint then
      local StandDir = DialogueUtils.GetDirection(self.Player, Targ)
      if not StandDir then
        Log.Error("Can't calculate stand direction")
        self:Finish()
        return
      end
      local ControlDir = Controller:GetControlRotation()
      if DialogueConst.ModifyOverShoulder then
        if DialogueConst.SetTargetAsShoulderMain then
          ControlDir = DialogueUtils.GetOverShoulderRotation(self.Player, Targ, self.springArmLength, SpringArmOffset + SpringArmLocation)
        else
          ControlDir = DialogueUtils.GetOverShoulderRotation(Targ, self.Player, self.springArmLength, SpringArmOffset + SpringArmLocation)
        end
      else
        ControlDir = DialogueUtils.AdjustControlDirection(ControlDir, StandDir)
      end
      if ControlDir then
        Controller:SetControlRotation(ControlDir)
      end
    end
  else
    Log.Error("Can't find player's controller")
  end
end

function DialogueCameraSetupAction:isEqualLastCamera()
  local PrevSetting = self.ParentModule.LastSetting
  if PrevSetting and self.Player == self.ParentModule.LastPlayer and self.TargetNPC == self.ParentModule.LastTarget and 1 == self.CameraSetting.CameraNumber and PrevSetting.interact_camera_type == self.CameraSetting.interact_camera_type and tonumber(PrevSetting.interact_camera_param1) == tonumber(self.CameraSetting.interact_camera_param1) and PrevSetting.interact_camera_param2 == self.CameraSetting.interact_camera_param2 and PrevSetting.interact_camera_param3 == self.CameraSetting.interact_camera_param3 then
    return true
  end
  return false
end

function DialogueCameraSetupAction:OnEnter()
  Log.Debug("DialogueCameraSetupAction:OnEnter")
  self:InjectProperties()
  self.bLegacyCameraChanged = false
  self.bInBattle = self:GetProperty("bInBattle")
  self.bUseBattleCamera = self:GetProperty("bUseBattleCamera")
  if self.bInBattle and self.bUseBattleCamera then
    self:Finish()
    return
  end
  self.FirstEnterOri = true
  self.FirstEnterAll = true
  if not self.CameraSetting then
    Log.Error("No valid Camera Setting found")
    self:Finish()
    return
  end
  if self.bInBattle and not self.bUseBattleCamera then
    if self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_UI then
      self:UICamera()
      self:Finish()
      return
    elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NIC_SKILL then
      local Config = NRCModuleManager:DoCmd(CameraModuleCmd.CreateCameraRequestConfig)
      Config.PlayerTarget = DialogueUtils.GrabActor(-1, self.fsm)
      Config.NpcTarget = DialogueUtils.GrabActor(-2, self.fsm)
      Config.Param1 = self.CameraSetting.interact_camera_param1
      Config.Param2 = self.CameraSetting.interact_camera_param2
      Config.Param3 = self.CameraSetting.interact_camera_param3
      Config.Param4 = self.CameraSetting.interact_camera_param4
      Config.bTickCameraInModule = false
      Config.CameraType = self.CameraSetting.interact_camera_type
      Config.CameraUser = self.ParentModule
      Config.CallbackCaller = self
      Config.Callback = self.Finish
      Config.fsm = self.fsm
      Config.bSetUpAndFinish = true
      NRCModuleManager:DoCmd(CameraModuleCmd.RequestCamera, Config)
      return
    end
  end
  if not self.CameraSetting.interact_camera_type then
    self:Finish()
    return
  elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_NONE then
    self:Finish()
    return
  elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_NORMAL then
    self:Finish()
    return
  elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_CAMPING then
    self:Finish()
    return
  end
  self.Player = DialogueUtils.GetPlayer()
  if not self.Player then
    Log.Error("No valid player found")
    self:Finish()
    return
  end
  self.Hero = DialogueUtils.GetHero()
  if not self.Player then
    Log.Error("No valid hero found")
    self:Finish()
    return
  end
  self.TargetNPC = self:GetActor(-2)
  if not self.TargetNPC then
    self:Finish()
    return
  end
  local View = DialogueUtils.ExtraActorView(self.TargetNPC)
  if not View then
    self:Finish()
    return
  end
  local controller = self:GetController()
  if not controller then
    self:Finish()
    return
  end
  local springArm = controller.BP_RocoCameraControlComponent:GetSpringArmComponent()
  if not springArm then
    self:Finish()
    return
  end
  local playerBP = DialogueUtils.ExtraActorView(self.Player)
  if self:isEqualLastCamera() then
    local lastMotion
    if 1 == self.CameraSetting.CameraNumber then
      lastMotion = self.ParentModule.LastConf.camera2_motion_type
    else
      lastMotion = self.DialogueConf.camera_motion_type
    end
    if lastMotion then
      self:Finish()
      return
    end
  end
  if controller.PlayerCameraManager then
    if self.FirstEnterOri then
      local KamLoc = controller.PlayerCameraManager:Abs_K2_GetActorLocation()
      local PlayLoc = playerBP:Abs_K2_GetActorLocation()
      local TempKamLoc = UE4.FVector(KamLoc.X, KamLoc.Y, KamLoc.Z - 42)
      local Part1 = KamLoc - PlayLoc
      local Part2 = TempKamLoc - PlayLoc
      local Norm = Part1:Cross(Part2)
      Norm:Normalize()
      self.LocalPlane = UE4.UKismetMathLibrary.MakePlaneFromPointAndNormal(KamLoc, Norm)
      local TarPos = View:Abs_K2_GetActorLocation()
      self.SideTarOri = self.LocalPlane.X * TarPos.X + self.LocalPlane.Y * TarPos.Y + self.LocalPlane.Z * TarPos.Z - self.LocalPlane.W
      local TarLoc = View:Abs_K2_GetActorLocation()
      local TarKamLoc = UE4.FVector(KamLoc.X, KamLoc.Y, KamLoc.Z - 42)
      local Part12 = TarLoc - PlayLoc
      local Part22 = TarKamLoc - PlayLoc
      local Norm2 = Part12:Cross(Part22)
      Norm:Normalize()
      self.LocalPlane2 = UE4.UKismetMathLibrary.MakePlaneFromPointAndNormal(TarLoc, Norm2)
      local KamPos = controller.PlayerCameraManager:Abs_K2_GetActorLocation()
      self.SideKamOri = self.LocalPlane2.X * KamPos.X + self.LocalPlane2.Y * KamPos.Y + self.LocalPlane2.Z * KamPos.Z - self.LocalPlane2.W
      self.FirstEnterOri = false
      self.ParentModule.SideKam = self.SideKamOri
      self.ParentModule.SideTar = self.SideTarOri
    else
      self.SideKamOri = self.ParentModule.SideKam
      self.SideTarOri = self.ParentModule.SideTar
    end
    self.SideKam = self.SideKamOri
    self.SideTar = self.SideTarOri
    if not self.SideKam then
      self.SideKam = self:GetProperty("SideOfCamera")
    else
      self:SetProperty("SideOfCamera", self.SideKam)
    end
    if not self.SideTar then
      self.SideTar = self:GetProperty("SideOfTarget")
    else
      self:SetProperty("SideOfTarget", self.SideTar)
    end
  end
  self:SetProperty("Center", nil)
  if self.ParentModule.CameraParent then
    local CameraActor = DialogueUtils.GetController(self.Player).CameraActor
    if CameraActor then
      local CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
      CameraComp:K2_AttachTo(self.ParentModule.CameraParent)
      self.ParentModule.CameraParent = nil
    end
  end
  controller:SetFadeEnable(false)
  self.ObjSide = nil
  springArm.bDoDialogCollisionTest = true
  self:SetProperty("TargetValue", self.CameraSetting.interact_camera_param1)
  if self:IsNormalInteraction(self.CameraSetting.interact_camera_type) then
    if controller then
      controller:RequestRocoCamera()
    end
    self.ParentModule.MoveDir = nil
    if self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NIC_SIDECHESTSHOT then
    elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NIC_OVERSHOULDER then
    elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NIC_MIDSYMMETRY then
    elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NIC_OBJECTIVESHOT then
    end
    self:Finish()
  elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_INTERACT_CAMERA_UI then
    if controller then
      controller:RequestRocoCamera()
    end
    self:UICamera()
    self:Finish()
  elseif self.CameraSetting.interact_camera_type == Enum.NpcInteractCameraType.NPC_CUSTOM_OFFSET_CAMERA then
    if controller then
      controller:RequestRocoCamera()
    end
    self:OffsetCamera()
    self:Finish()
  else
    local Config = NRCModuleManager:DoCmd(CameraModuleCmd.CreateCameraRequestConfig)
    Config.NpcTarget = self.TargetNPC
    Config.PlayerTarget = self.Player
    Config.Param1 = self.CameraSetting.interact_camera_param1
    Config.Param2 = self.CameraSetting.interact_camera_param2
    Config.Param3 = self.CameraSetting.interact_camera_param3
    Config.Param4 = self.CameraSetting.interact_camera_param4
    Config.bTickCameraInModule = false
    Config.CameraType = self.CameraSetting.interact_camera_type
    Config.CameraUser = self.ParentModule
    Config.CallbackCaller = self
    Config.bSetUpAndFinish = true
    Config.Callback = self.Finish
    Config.fsm = self.fsm
    if self.DialogueConf.camera_switch_type == Enum.CameraSwitchType.CAMST_NORMAL then
      Config.BlendTime = 0.5
    else
      Config.BlendTime = 0
    end
    NRCModuleManager:DoCmd(CameraModuleCmd.RequestCamera, Config)
  end
end

function DialogueCameraSetupAction:OnCampingEnd(Event, Skill)
  self:Finish()
end

function DialogueCameraSetupAction:OverShoulderCamera(param1, param2, param3)
  self.bLegacyCameraChanged = true
  self.Player.inputComponent:SetCameraControlEnable(self.ParentModule, false)
  local Param1 = param1 or tonumber(self.CameraSetting.interact_camera_param1)
  local UseNpcShoulder = true
  local Param2 = param2 or self.CameraSetting.interact_camera_param2 or 1
  local Param3 = 20
  local Param4 = self.CameraSetting.interact_camera_param4
  local Success = self:CalcConstants(self.Player, self.TargetNPC)
  if not Success then
    return
  end
  local beta = 0
  local Length = 0
  local gamma = 0
  local PrimaryTarget = self.Player
  local Offsetter = self.TargetNPC
  local View = DialogueUtils.ExtraActorView(self.TargetNPC)
  local DistanceBetwix = self.Player.viewObj:Abs_K2_GetActorLocation():Dist(View:Abs_K2_GetActorLocation())
  Length = 3 * Param2 * self.ConstantTable.RB + 0.75 * DistanceBetwix
  beta = math.asin(0.32 / self.ConstantTable.Dh * 3 * Param2 * (self.ConstantTable.RA + 0.16)) * 180 / math.pi - 71.6
  gamma = -math.atan(((self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB - (self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA)) / 2 + Param3) / (0.5 * self.ConstantTable.Dh + Length)) * 180 / math.pi
  local delta = Param3
  if -2 == Param1 then
    UseNpcShoulder = false
    PrimaryTarget = self.TargetNPC
    Offsetter = self.Player
    Length = 3 * Param2 * self.ConstantTable.RA + 0.75 * DistanceBetwix
    gamma = -math.atan(((self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA - (self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB)) / 2 + Param3) / (0.5 * self.ConstantTable.Dh + Length)) * 180 / math.pi
    beta = math.asin(0.32 / self.ConstantTable.Dh * 3 * Param2 * (self.ConstantTable.RB + 0.16)) * 180 / math.pi - 71.6
  end
  self.SideTar = self.SideTar or 1
  local Side = DialogueUtils.SettingsEnum.A
  if self.TargetNPC == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.A
  elseif self.TargetNPC == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.A
  end
  local alpha = 0
  if Side == DialogueUtils.SettingsEnum.A then
    beta = -beta
  elseif Side == DialogueUtils.SettingsEnum.B then
  end
  local Offset = UE4.FVector(0, 0, delta)
  self:ApplySpringArm(Length, Offset, true, Offsetter, nil, nil, nil, true)
  local Controller = DialogueUtils.GetController(self.Player)
  local CompRoter = Controller:GetControlRotation()
  CompRoter.Yaw = CompRoter.Yaw + beta
  Controller:SetControlRotation(CompRoter)
  local Debugging = false
  local ChangeFocusToOneThird = true
  if ChangeFocusToOneThird then
    local CameraActor = Controller.CameraActor
    local SpringArm = DialogueUtils.GetPlayerSpringArm(self.Player)
    local camComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    local HorizontalFOV = math.asin(math.sin(camComp.FieldOfView) / camComp.AspectRatio)
    local OneThirdFOVRotation = math.atan(0.3333333333333333 * math.tan(HorizontalFOV / 2)) * 57.2958
    local CurrentSpringArmLocation = self.Centre
    SpringArm:SetArmLength(Length)
    local LocationOffset = CurrentSpringArmLocation - camComp:Abs_K2_GetComponentLocation()
    if Debugging then
      Log.Error("CurrentSpringArmLocation: " .. tostring(CurrentSpringArmLocation))
    end
    LocationOffset:Normalize()
    local DirectionVector = LocationOffset
    local HelperVector = UE4.FVector(DirectionVector.X, DirectionVector.Y, DirectionVector.Z - 100)
    local axis = DirectionVector:Cross(HelperVector)
    local RotateDown = UE4.UKismetMathLibrary.RotatorFromAxisAndAngle(axis, -OneThirdFOVRotation)
    local NewDirection = RotateDown:RotateVector(DirectionVector)
    CompRoter.Pitch = CompRoter.Pitch - OneThirdFOVRotation
    local NewLength = Length * DirectionVector.X / NewDirection.X
    if Debugging then
      Log.Error("OldDirection vector: " .. tostring(DirectionVector))
      Log.Error("NewDirection vector: " .. tostring(NewDirection))
      Log.Error("NewLength: " .. tostring(NewLength))
      Log.Error("Length: " .. tostring(Length))
    end
    local z = math.abs(Length * DirectionVector.Z - NewLength * NewDirection.Z)
    SpringArm:SetArmLength(NewLength)
    local NewSpringArmOrigin = UE4.FVector(self.Centre.X, self.Centre.Y, self.Centre.Z - z)
    SpringArm:Abs_K2_SetWorldLocation(NewSpringArmOrigin, false, nil, false)
    Controller:SetControlRotation(CompRoter)
    if Debugging then
      Log.Error("Center" .. tostring(self.Centre))
      Log.Error("NewSpringArmOrigin: " .. tostring(NewSpringArmOrigin))
    end
    SpringArm:SetArmLength(NewLength, true)
    if UseNpcShoulder then
      camComp:K2_SetRelativeRotation(UE4.FRotator(gamma, alpha, 0))
    else
      camComp:K2_SetRelativeRotation(UE4.FRotator(gamma - OneThirdFOVRotation / 2 + 1, alpha, 0))
    end
    local CameraForward = camComp:GetForwardVector()
    local AngleOffset = math.deg(math.acos(CameraForward:Dot(NewDirection)))
    local CameraActorForward = CameraActor:GetActorForwardVector()
    if Debugging then
    end
    SpringArm.CameraRotationLagSpeed = 0
  end
end

function DialogueCameraSetupAction:GetController()
  return DialogueUtils.GetController(self.Player)
end

function DialogueCameraSetupAction:ObjectiveCamera()
  self.bLegacyCameraChanged = true
  self.Player.inputComponent:SetCameraControlEnable(self.ParentModule, false)
  local Param1 = tonumber(self.CameraSetting.interact_camera_param1)
  local Param2 = self.CameraSetting.interact_camera_param2
  local Param3 = self.CameraSetting.interact_camera_param3
  local PlayLoc = self.Player.viewObj:Abs_K2_GetActorLocation()
  local ActorType = 20075
  local RangeRad = DialogueCameraSetupAction.DetectionSettings.near
  ActorType = Param1
  local ActorName = self.CameraSetting.interact_camera_param1
  local ActorName2 = "nada"
  local ActorName3 = "nada"
  local ActorName4 = "nada"
  local ActorFound
  if 1 == ActorType then
    ActorName = "Statue"
    ActorName2 = "Tree"
    ActorName4 = "Flower"
  end
  if not ActorType or 1 == ActorType then
    if not ActorType then
      RangeRad = DialogueCameraSetupAction.DetectionSettings.far
    end
    local Actors, Results = UE4.UKismetSystemLibrary.Abs_SphereOverlapActors(UE4Helper.GetCurrentWorld(), PlayLoc, RangeRad, nil, nil, nil)
    for i = 1, Actors:Length() do
      local Namo = Actors:Get(i):GetName()
      if Actors:Get(i).Overridden then
        Namo = Actors:Get(i).Overridden.GetName(Actors:Get(i))
      end
      if Namo then
        local foundIdx = string.find(Namo, ActorName)
        local foundIdx2 = string.find(Namo, ActorName2)
        local foundIdx3 = string.find(Namo, ActorName3)
        local foundIdx4 = string.find(Namo, ActorName4)
        if foundIdx and foundIdx >= 0 or foundIdx2 and foundIdx2 >= 0 or foundIdx3 and foundIdx3 >= 0 or foundIdx4 and foundIdx4 >= 0 then
          ActorFound = Actors:Get(i)
          break
        end
      end
    end
  else
    RangeRad = DialogueCameraSetupAction.DetectionSettings.far
    local Actors, Results = UE4.UNRCStatics.SphereOverlapActors(UE4Helper.GetCurrentWorld(), self.Player.viewObj:K2_GetActorLocation(), RangeRad, nil, nil)
    for i = 1, Actors:Length() do
      local SC = Actors:Get(i).sceneCharacter
      if SC and SC.config and ActorType == SC.config.id then
        ActorFound = SC
        break
      end
    end
  end
  if ActorFound then
    local Success = self:CalcConstants(self.Player, self.TargetNPC, ActorFound)
    if not Success then
      self:Finish()
      return
    end
  else
    if self.ParentModule.LastSetting then
      local PrevConfer = self.ParentModule.LastSetting
      if PrevConfer.interact_camera_type == Enum.NpcInteractCameraType.NIC_OVERSHOULDER then
        self:Finish()
        return
      end
    end
    self:OverShoulderCamera(-1, 0.5, 0)
    self:Finish()
    return
  end
  local TarPos
  if ActorFound.viewObj then
    TarPos = ActorFound.viewObj:Abs_K2_GetActorLocation()
  else
    TarPos = ActorFound:Abs_K2_GetActorLocation()
  end
  local controller = DialogueUtils.GetController(self.Player)
  if controller.PlayerCameraManager then
    local KamLoc = controller.PlayerCameraManager:Abs_K2_GetActorLocation()
    local TempKamLoc = UE4.FVector(KamLoc.X, KamLoc.Y, KamLoc.Z - 42)
    local Part1 = KamLoc - PlayLoc
    local Part2 = TempKamLoc - PlayLoc
    local Norm = Part1:Cross(Part2)
    Norm:Normalize()
    self.LocalPlane = UE4.UKismetMathLibrary.MakePlaneFromPointAndNormal(KamLoc, Norm)
    self.SideTarAll = self.LocalPlane.X * TarPos.X + self.LocalPlane.Y * TarPos.Y + self.LocalPlane.Z * TarPos.Z - self.LocalPlane.W
    local TarKamLoc = UE4.FVector(KamLoc.X, KamLoc.Y, KamLoc.Z - 42)
    local Part12 = TarPos - PlayLoc
    local Part22 = TarKamLoc - PlayLoc
    local Norm2 = Part12:Cross(Part22)
    Norm:Normalize()
    self.LocalPlane2 = UE4.UKismetMathLibrary.MakePlaneFromPointAndNormal(TarPos, Norm2)
    local KamPos = controller.PlayerCameraManager:Abs_K2_GetActorLocation()
    self.SideKamAll = self.LocalPlane2.X * KamPos.X + self.LocalPlane2.Y * KamPos.Y + self.LocalPlane2.Z * KamPos.Z - self.LocalPlane2.W
    self.FirstEnterAll = false
    self.SideKam = self.SideKamAll
    self.SideTar = self.SideTarAll
    if self.SideKam then
      self:SetProperty("SideOfCamera", self.SideKam)
    else
      self.SideKam = self:GetProperty("SideOfCamera")
    end
    if self.SideTar then
      self:SetProperty("SideOfTarget", self.SideTar)
    else
      self.SideTar = self:GetProperty("SideOfTarget")
    end
  end
  if Param2 <= 0 then
    Param2 = 1
  end
  local beta = 0
  local Length = 0
  local gamma = 0
  local PrimaryTarget = self.Player
  local Other = self.TargetNPC
  local View = DialogueUtils.ExtraActorView(Other)
  local DistanceBetwix = self.Player.viewObj:Abs_K2_GetActorLocation():Dist(TarPos)
  Length = 3 * Param2 * self.ConstantTable.R3 + 0.5 * DistanceBetwix + self.ConstantTable.R3 * 3
  gamma = math.atan(((self.ConstantTable.CoorH3.Z - 0.25 * self.ConstantTable.H3 - (self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA)) / 2 - Param3) / (0.75 * DistanceBetwix + Length)) * 180 / math.pi
  local delta = Param3
  local Dist = View:Abs_K2_GetActorLocation():Dist(TarPos)
  if DistanceBetwix < Dist then
    DistanceBetwix = Dist
    PrimaryTarget = self.TargetNPC
    Other = self.Player
    gamma = math.atan(((self.ConstantTable.CoorH3.Z - 0.25 * self.ConstantTable.H3 - (self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB)) / 2 - Param3) / (0.75 * DistanceBetwix + Length)) * 180 / math.pi
  end
  if controller.PlayerCameraManager then
    local OtherLoc = Other.viewObj:Abs_K2_GetActorLocation()
    local ActLoc = ActorFound:Abs_K2_GetActorLocation()
    local PrimLoc = PrimaryTarget.viewObj:Abs_K2_GetActorLocation()
    local TempPrimLoc = UE4.FVector(PrimLoc.X, PrimLoc.Y, PrimLoc.Z - 42)
    local Part1 = PrimLoc - OtherLoc
    local Part2 = TempPrimLoc - OtherLoc
    local Norm = Part1:Cross(Part2)
    Norm:Normalize()
    self.LocalPlane = UE4.UKismetMathLibrary.MakePlaneFromPointAndNormal(PrimLoc, Norm)
    self.ObjSide = self.LocalPlane.X * ActLoc.X + self.LocalPlane.Y * ActLoc.Y + self.LocalPlane.Z * ActLoc.Z - self.LocalPlane.W
  end
  beta = 90 - math.atan(2 * self.ConstantTable.R3 / (0.5 * DistanceBetwix)) * 180 / math.pi
  local Side = DialogueUtils.SettingsEnum.A
  if self.TargetNPC == PrimaryTarget and self.ObjSide <= 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.TargetNPC == PrimaryTarget and self.ObjSide > 0 then
    Side = DialogueUtils.SettingsEnum.A
  elseif self.Player == PrimaryTarget and self.ObjSide <= 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.ObjSide > 0 then
    Side = DialogueUtils.SettingsEnum.A
  end
  local alpha = 0
  if Side == DialogueUtils.SettingsEnum.A then
  elseif Side == DialogueUtils.SettingsEnum.B then
    beta = -beta
  end
  local Offset = UE4.FVector(0, 0, delta)
  self:ApplySpringArm(Length, Offset, true, ActorFound, ActorFound, PrimaryTarget, Side)
  local Controller = DialogueUtils.GetController(self.Player)
  local CompRoter = Controller:GetControlRotation()
  CompRoter.Yaw = CompRoter.Yaw + beta
  Controller:SetControlRotation(CompRoter)
  local CameraActor = DialogueUtils.GetController(self.Player).CameraActor
  if CameraActor then
    local CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    local SPComp = CameraActor:GetComponentByClass(UE4.URocoSpringArmComponent)
    local CameraPos
    if controller.PlayerCameraManager then
      CameraPos = controller.PlayerCameraManager:Abs_K2_GetActorLocation()
    end
    local hypo = SPComp.TargetArmLength
    local fauxCameraPos = SPComp:Abs_K2_GetComponentLocation() + SPComp.TargetOffset + Controller:GetControlRotation():ToVector() * hypo * -1
    local Hits = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(UE4Helper.GetCurrentWorld(), self.Centre, fauxCameraPos, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, true, nil)
    for i = 1, Hits:Length() do
      local Hit = Hits:Get(i)
      if Hit.Actor then
        local Namo = Hit.Actor:GetName()
        if Namo then
          local thing1 = string.find(Namo, "Rock")
          local thing2 = string.find(Namo, "Foliage")
          local thing3 = string.find(Namo, "Landscape")
          local thing4 = string.find(Namo, "Tree")
          if thing1 and thing1 >= 0 or thing2 and thing2 >= 0 or thing3 and thing3 >= 0 or thing4 and thing4 >= 0 then
            fauxCameraPos = SPComp:Abs_K2_GetComponentLocation() + SPComp.TargetOffset + Controller:GetControlRotation():ToVector() * Hit.Distance * -1
            break
          end
        end
      end
    end
    self:SetProperty("Center", self.Centre)
    local Rotter = UE.UKismetMathLibrary.FindLookAtRotation(fauxCameraPos, self.Centre)
    self.ParentModule.CameraParent = CameraComp:GetAttachParent()
    CameraComp:DetachFromParent(true)
    CameraComp:Abs_K2_SetWorldLocation(fauxCameraPos, false, nil, false)
    CameraComp:K2_SetWorldRotation(Rotter, false, nil, false)
    if self.debug then
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), fauxCameraPos, self.Centre, UE4.FLinearColor(0.5, 0.5, 0, 1), 25, 22)
    end
  end
end

function DialogueCameraSetupAction:SymmetricalCamera()
  self.bLegacyCameraChanged = true
  self.Player.inputComponent:SetCameraControlEnable(self.ParentModule, false)
  local Param1 = tonumber(self.CameraSetting.interact_camera_param1)
  local Param2 = self.CameraSetting.interact_camera_param2
  local Param3 = self.CameraSetting.interact_camera_param3
  local Success = self:CalcConstants(self.Player, self.TargetNPC)
  if not Success then
    return
  end
  local PrimaryTarget = self.Player
  local delta = self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA - (self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB)
  if -2 == Param1 then
    PrimaryTarget = self.TargetNPC
    delta = self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB - (self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA)
  end
  self.SideTar = self.SideTar or 1
  local Side = DialogueUtils.SettingsEnum.A
  if self.TargetNPC == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.A
  elseif self.TargetNPC == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.A
  end
  if Param3 <= 0 then
    Param3 = 0
  end
  local alpha = 0
  local Length = self.ConstantTable.Dh * 1.5
  local gamma = Param2
  delta = delta / 2 + Param3
  if Side == DialogueUtils.SettingsEnum.A then
  elseif Side == DialogueUtils.SettingsEnum.B then
  end
  local Offset = UE4.FVector(0, 0, delta)
  self:ApplySpringArm(Length, Offset, true)
  local CameraActor = DialogueUtils.GetController(self.Player).CameraActor
  if CameraActor then
    local CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    CameraComp:K2_SetRelativeRotation(UE4.FRotator(gamma, alpha, 0))
  end
end

function DialogueCameraSetupAction:SideChestCamera()
  self.bLegacyCameraChanged = true
  self.Player.inputComponent:SetCameraControlEnable(self.ParentModule, false)
  local Param1 = tonumber(self.CameraSetting.interact_camera_param1)
  local Param2 = self.CameraSetting.interact_camera_param2 or 0
  local Param3 = self.CameraSetting.interact_camera_param3 or 0
  local Success = self:CalcConstants(self.Player, self.TargetNPC)
  if not Success then
    return
  end
  local PrimaryTarget = self.Player
  local delta = self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA - (self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB) + Param3 + 30
  if -2 == Param1 then
    PrimaryTarget = self.TargetNPC
    delta = self.ConstantTable.CoorHB.Z - 0.25 * self.ConstantTable.HB - (self.ConstantTable.CoorHA.Z - 0.25 * self.ConstantTable.HA) + Param3
  end
  self.SideTar = self.SideTar or 1
  local Side = DialogueUtils.SettingsEnum.A
  if self.TargetNPC == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.A
  elseif self.TargetNPC == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar <= 0 then
    Side = DialogueUtils.SettingsEnum.B
  elseif self.Player == PrimaryTarget and self.SideTar > 0 then
    Side = DialogueUtils.SettingsEnum.A
  end
  local ConstantA = 32
  if Param2 <= 0 then
    Param2 = 1
  end
  local alpha = 0
  local Length = self.ConstantTable.Dh * math.sin(math.pi / 180 * ConstantA) / Param2
  local gamma = 0
  delta = delta / 2
  if Side == DialogueUtils.SettingsEnum.A then
    alpha = ConstantA
  elseif Side == DialogueUtils.SettingsEnum.B then
    alpha = -ConstantA
  end
  local Offset = UE4.FVector(0, 0, delta)
  self:ApplySpringArm(Length, Offset, true)
  local CameraActor = DialogueUtils.GetController(self.Player).CameraActor
  if CameraActor then
    local CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    CameraComp:K2_SetRelativeRotation(UE4.FRotator(gamma, alpha, 0))
  end
end

function DialogueCameraSetupAction:NormalCamera()
  local springArmLength = DialogueConst.SpringArmLengthBaseDefault
  local distance = DialogueUtils.CalcActorDistance(self.TargetNPC, self.Player)
  self.distance = distance
  if not distance then
    springArmLength = DialogueConst.SpringArmLengthBaseDefault
  else
    springArmLength = DialogueConst.SpringArmLengthBaseDefault + DialogueConst.SpringArmLengthFactorDefault * distance
  end
  self:ApplySpringArm(springArmLength, DialogueUtils.CalcSpringArmOffsetFromPosition(self.TargetNPC, self.Player))
  self.bLegacyCameraChanged = true
end

function DialogueCameraSetupAction:OffsetCamera()
  self.bLegacyCameraChanged = true
  local cameraLerpTime = DialogueConst.EnterTime
  local ControllerTmp = DialogueUtils.GetController(self.Player)
  ControllerTmp:ChangeRocoCameraFadeRange(250, 300)
  if self.CameraSetting.camera_switch_type == Enum.CameraSwitchType.CAMST_INSTANT or DialogueConst.ModifyOverShoulder then
    cameraLerpTime = 0
    if ControllerTmp then
      ControllerTmp.BP_RocoCameraControlComponent:EnableLag(false)
    end
  elseif ControllerTmp then
    ControllerTmp.BP_RocoCameraControlComponent:EnableLag(true)
  end
  local savedTargetView = self.ParentModule:GetSavedTargetView(self.fsm)
  if not savedTargetView then
    local Controller = DialogueUtils.GetController(self.Player)
    self.savedTargetView = Controller.PlayerCameraManager.ViewTarget.Target
    self.ParentModule:SetSavedTargetView(self.fsm, self.savedTargetView)
  end
  local CamKonf = _G.DataConfigManager:GetCustomcameraConf(tonumber(self.CameraSetting.interact_camera_param1))
  local RotOffsetX = 0
  local RotOffsetY = -30
  local RotOffsetZ = 0
  if CamKonf then
    RotOffsetX = CamKonf.ROT_OFFSET_Y or 0
    RotOffsetY = CamKonf.ROT_OFFSET_Z or -30
    RotOffsetZ = CamKonf.ROT_OFFSET_X or 0
  end
  local RotOffset = UE.FRotator(RotOffsetX, RotOffsetY, RotOffsetZ)
  local Forward = (self.Player.viewObj:K2_GetActorRotation() + RotOffset):ToVector()
  local PosOffsetX = 0
  local PosOffsetY = 50
  local PosOffsetZ = 30
  if CamKonf then
    PosOffsetX = CamKonf.POS_OFFSET_X or 0
    PosOffsetY = CamKonf.POS_OFFSET_Y or 50
    PosOffsetZ = CamKonf.POS_OFFSET_Z or 70
  end
  local PlayerRight = self.Player.viewObj:GetActorRightVector()
  local PlayerForward = self.Player.viewObj:GetActorForwardVector()
  local PosOffset = UE.FVector(0, 0, 0)
  PosOffset = PosOffset + PlayerForward * PosOffsetX + PlayerRight * PosOffsetY
  PosOffset.Z = PosOffsetZ + PosOffset.Z
  local DistanceOffset = 200
  if CamKonf then
    DistanceOffset = CamKonf.DIST or 200
  end
  if self.ParentModule:CheckUICamera() then
    self.camera_ui = self.ParentModule.data.CameraUI
    NRCModeManager:DoCmd(DialogueModuleCmd.SetUICameraState, true)
  else
    self:ConstructUICamera(self.Player.viewObj:Abs_GetTransform(), 50, 2.15, false)
  end
  local cameraComp = self.camera_ui:GetComponentByClass(UE4.UCameraComponent)
  self:SetCameraDOF(cameraComp, 0, false)
  local LocLoc = self.Player.viewObj:Abs_K2_GetActorLocation() + PosOffset + Forward * -1 * DistanceOffset
  self.camRot = UE.UKismetMathLibrary.FindLookAtRotation(LocLoc, self.Player.viewObj:Abs_K2_GetActorLocation() + PosOffset)
  self.camTransform = UE4.UKismetMathLibrary.MakeTransform(LocLoc, self.camRot, UE4.FVector(1, 1, 1))
  self.camera_ui:Abs_K2_SetActorTransform_WithoutHit(self.camTransform)
  local Controller = DialogueUtils.GetController(self.Player)
  if Controller then
    self.ParentModule:SetUICamera(self.camera_ui)
    self:ChangeCamera(self.camera_ui, cameraLerpTime, nil, Controller, nil)
  end
end

function DialogueCameraSetupAction:UICamera()
  local cameraLerpTime = DialogueConst.EnterTime
  self.bLegacyCameraChanged = true
  local Controller, TargetNpcBp
  Controller = DialogueUtils.GetController(self.Player)
  TargetNpcBp = DialogueUtils.ExtraActorView(self.TargetNPC)
  if not Controller or not TargetNpcBp then
    Log.Error("DialogueCameraSetupAction:UICamera controller or npc nil")
    return
  end
  Controller:ChangeRocoCameraFadeRange(250, 300)
  if self.CameraSetting.camera_switch_type == Enum.CameraSwitchType.CAMST_INSTANT or DialogueConst.ModifyOverShoulder then
    cameraLerpTime = 0
    if Controller then
      Controller.BP_RocoCameraControlComponent:EnableLag(false)
    end
  elseif Controller then
    Controller.BP_RocoCameraControlComponent:EnableLag(true)
  end
  local savedTargetView = self.ParentModule:GetSavedTargetView(self.fsm)
  if not savedTargetView then
    self.savedTargetView = Controller:GetViewTarget()
    self.ParentModule:SetSavedTargetView(self.fsm, self.savedTargetView)
  end
  local pos = TargetNpcBp:Abs_GetTransform().Translation
  local forwardVec
  if TargetNpcBp.GetRealForwardVector ~= nil then
    forwardVec = TargetNpcBp:GetRealForwardVector()
  else
    forwardVec = TargetNpcBp:GetForwardVector()
  end
  local upVec = UE4.FVector(0, 0, 1)
  local rightVec = -UE4.UKismetMathLibrary.Cross_VectorVector(upVec, forwardVec)
  rightVec = UE4.UKismetMathLibrary.Normal(rightVec)
  local distZ = tonumber(self.CameraSetting.interact_camera_param1) or 0
  local distX = tonumber(self.CameraSetting.interact_camera_param2) or 0
  local distY = tonumber(self.CameraSetting.interact_camera_param3) or 0
  local offset = forwardVec * distZ + rightVec * distX + upVec * distY
  pos = pos + offset
  local BattleLoc = TargetNpcBp:Abs_GetTransform()
  BattleLoc.Translation = pos
  if self.ParentModule:CheckUICamera() then
    self.camera_ui = self.ParentModule.data.CameraUI
    NRCModeManager:DoCmd(DialogueModuleCmd.SetUICameraState, true)
  else
    self:ConstructUICamera(BattleLoc, 50, 2.15, false)
  end
  local Param4 = tonumber(self.CameraSetting.interact_camera_param4) or 0
  local cameraComp = self.camera_ui:GetComponentByClass(UE4.UCameraComponent)
  if Param4 > 0 then
    self:SetCameraDOF(cameraComp, Param4, true)
  elseif Param4 < 0 then
    self:SetCameraDOF(cameraComp, 0, false)
  else
    self:SetCameraDOF(cameraComp, distZ, true)
  end
  if self.bInBattle then
    if self.CameraSetting.ui_camera_focus_socketname then
      local meshComp = TargetNpcBp:GetComponentByClass(UE4.USkeletalMeshComponent)
      local socketLocation = meshComp:Abs_GetSocketLocation(self.CameraSetting.ui_camera_focus_socketname)
      offset = socketLocation - pos
      self.camRot = offset:ToRotator()
    else
      self.camRot = (UE4.FVector(0, 0, 0) - offset):ToRotator()
    end
  else
    self.camRot = UE4.UKismetMathLibrary.MakeRotFromX(forwardVec * -1.0)
  end
  self.camTransform = UE4.UKismetMathLibrary.MakeTransform(pos, self.camRot, UE4.FVector(1, 1, 1))
  self.camera_ui:Abs_K2_SetActorTransform_WithoutHit(self.camTransform)
  if Controller then
    self.ParentModule:SetUICamera(self.camera_ui)
    self:ChangeCamera(self.camera_ui, cameraLerpTime, nil, Controller, nil)
  end
  if not self.bInBattle then
    self:SetPlayerVisible(self.Hero, false)
  end
end

function DialogueCameraSetupAction:Finish()
  local bInBattle = self:GetProperty("bInBattle")
  local bUseBattleCamera = self:GetProperty("bUseBattleCamera")
  if bInBattle and bUseBattleCamera then
    Base.Finish(self)
    return
  else
    self.ParentModule.LastPlayer = self.Player
    self.ParentModule.LastTarget = self.TargetNPC
    self.ParentModule.LastConf = self.DialogueConf
    self.ParentModule.LastSetting = self.CameraSetting
    self.ParentModule.FirstEnter = false
    if self.DialogueConf.camera_switch_type == Enum.CameraSwitchType.CAMST_NORMAL then
      local KamLerpTime = DialogueConst.EnterTime
      self:ClearDelayHandle()
      self.FinishDelayHandler = _G.DelayManager:DelaySeconds(KamLerpTime, Base.Finish, self)
    else
      Base.Finish(self)
    end
  end
end

function DialogueCameraSetupAction:CalcConstants(Player, Target, Target2)
  local SholderA, SholderB, Sholder3
  if Player and Player.viewObj then
    local meshComp = Player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
    if not meshComp then
      self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
      return false
    end
    local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
    local socketNameBody = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
    local pos = Player.viewObj:Abs_K2_GetActorLocation()
    local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
    local posBody = meshComp:Abs_GetSocketLocation(socketNameBody)
    local Dist = posHead:DistSquared(posBody)
    Log.Debug("\230\152\190\231\164\186\232\167\166\229\143\145\229\164\180-\232\130\169\232\183\157\231\166\187", Dist)
    if Dist < 100 then
      SholderA = UE4.FVector(pos.X, pos.Y, pos.Z)
      posHead = UE4.FVector(SholderA.X, SholderA.Y, SholderA.Z)
      SholderA.Z = SholderA.Z + Player:GetHalfHeight() * 0.5
      posHead.Z = posHead.Z + Player:GetHalfHeight()
    else
      SholderA = (posHead + posBody) / 2
    end
    local SkelMesh = meshComp.SkeletalMesh
    if SkelMesh then
      local Xfactor = SkelMesh:GetImportedBounds().BoxExtent.X
      local Yfactor = SkelMesh:GetImportedBounds().BoxExtent.Y
      local SquareFactor = Xfactor * Xfactor + Yfactor * Yfactor
      self.ConstantTable.RA = math.sqrt(SquareFactor) / 2
      self.ConstantTable.HA = SkelMesh:GetImportedBounds().BoxExtent.Z
    end
    self.ConstantTable.CoorHA = posHead
    self.PlayerSholderHeight = SholderA
  end
  if Target and Target.viewObj then
    local meshComp = Target.viewObj:GetComponentByClass(UE.UMeshComponent)
    if not meshComp then
      Log.Error("\229\157\143\229\149\166\239\188\129\239\188\129", UE.UObject.GetName(Target.viewObj), "\229\176\177\230\178\161\230\156\137Mesh\239\188\129\239\188\129\239\188\129", self.DialogueConf and self.DialogueConf.id or "nil")
      return false
    end
    local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
    local socketNameBody = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
    local pos = Target.viewObj:Abs_K2_GetActorLocation()
    local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
    local posBody = meshComp:Abs_GetSocketLocation(socketNameBody)
    SholderB = (posHead + posBody) / 2
    if posHead == posBody then
      SholderB = UE4.FVector(pos.X, pos.Y, pos.Z)
      posHead = UE4.FVector(SholderB.X, SholderB.Y, SholderB.Z)
      SholderB.Z = SholderB.Z + Target:GetHalfHeight() * 0.5
      posHead.Z = posHead.Z + Target:GetHalfHeight()
    end
    if meshComp:IsA(UE.USkeletalMeshComponent) then
      local SkelMesh = meshComp.SkeletalMesh
      if SkelMesh then
        local Bounds = SkelMesh:GetImportedBounds()
        local Extent = Bounds.BoxExtent
        local Xfactor = Extent.X
        local Yfactor = Extent.Y
        local SquareFactor = Xfactor * Xfactor + Yfactor * Yfactor
        self.ConstantTable.RB = math.sqrt(SquareFactor) / 2
        self.ConstantTable.HB = Extent.Z
      else
        Log.Error("No skeletal mesh")
      end
    elseif meshComp:IsA(UE.UStaticMeshComponent) then
      local Mesh = meshComp.StaticMesh
      if Mesh then
        local Bounds = Mesh:GetBounds()
        local Extent = Bounds.BoxExtent
        local Xfactor = Extent.X
        local Yfactor = Extent.Y
        local SquareFactor = Xfactor * Xfactor + Yfactor * Yfactor
        self.ConstantTable.RB = math.sqrt(SquareFactor) / 2
        self.ConstantTable.HB = Extent.Z
      else
        Log.Error("No static mesh")
      end
    else
      Log.Error("mesh component not supported")
    end
    self.ConstantTable.CoorHB = posHead
    self.NpcSholderHeight = SholderB
  end
  if SholderA and SholderB then
    self.ConstantTable.Dh = SholderA:Dist(SholderB)
  end
  if Target2 then
    local Target2Inner = Target2
    if Target2.viewObj then
      Target2Inner = Target2.viewObj
    end
    local meshComp = Target2Inner:GetComponentByClass(UE4.USkeletalMeshComponent)
    local StatComp = Target2Inner:GetComponentByClass(UE4.UStaticMeshComponent)
    local pos = Target2Inner:Abs_K2_GetActorLocation()
    if meshComp then
      local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
      local socketNameBody = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
      local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
      local posBody = meshComp:Abs_GetSocketLocation(socketNameBody)
      local SkelMesh = meshComp.SkeletalMesh
      if SkelMesh then
        local Xfactor = SkelMesh:GetImportedBounds().BoxExtent.X
        local Yfactor = SkelMesh:GetImportedBounds().BoxExtent.Y
        local SquareFactor = Xfactor * Xfactor + Yfactor * Yfactor
        self.ConstantTable.R3 = math.sqrt(SquareFactor) / 2
        self.ConstantTable.H3 = SkelMesh:GetImportedBounds().BoxExtent.Z
        if posHead == posBody then
          posHead = UE4.FVector(pos.X, pos.Y, pos.Z)
          posHead.Z = posHead.Z + self.ConstantTable.H3 / 2
        end
      end
      self.ConstantTable.CoorH3 = posHead
    elseif StatComp then
      local StatMesh = StatComp.StaticMesh
      if StatMesh then
        local BoxExtent = StatMesh:GetBounds().BoxExtent * Target2Inner:GetActorScale3D()
        local Xfactor = BoxExtent.X
        local Yfactor = BoxExtent.Y
        local SquareFactor = Xfactor * Xfactor + Yfactor * Yfactor
        self.ConstantTable.R3 = math.sqrt(SquareFactor) / 2
        pos.Z = pos.Z + BoxExtent.Z * 2
        self.ConstantTable.H3 = BoxExtent.Z * 2
        self.ConstantTable.CoorH3 = pos
      end
    end
    Sholder3 = self.ConstantTable.CoorH3
  end
  if SholderA and Sholder3 then
    self.ConstantTable.D3 = SholderA:Dist(Sholder3)
  end
  Log.Dump(self.ConstantTable, 3, "ConstantTableDump")
  return true
end

function DialogueCameraSetupAction:DrawDebugLines(SpringArmLocation, SpringArmOffset, OriginalControlDir, FixedControlDir, SpringArmChannel, SpringArmRadius)
  if not DialogueConst.DrawDebugLines then
    return
  end
  if not SpringArmLocation then
    return
  end
  if not SpringArmOffset then
    return
  end
  if not OriginalControlDir then
    return
  end
  if not FixedControlDir then
    return
  end
  if 0 == SpringArmRadius then
    return
  end
  if 0 == SpringArmChannel then
    return
  end
  if not self.distance then
    return
  end
  local SpringArmLength = DialogueConst.SpringArmLengthBaseDefault + DialogueConst.SpringArmLengthFactorDefault * self.distance
  if not SpringArmLength then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  if not World then
    return
  end
  local WHITE = UE4.FLinearColor(1.0, 1.0, 1.0, 1.0)
  local BLUE = UE4.FLinearColor(0.0, 0.0, 1.0, 1.0)
  local GREEN = UE4.FLinearColor(0.0, 1.0, 0.0, 1.0)
  local DARK_GREEN = GREEN * 0.5
  local RED = UE4.FLinearColor(1.0, 0.0, 0.0, 1.0)
  local DARK_RED = RED * 0.5
  local Center = SpringArmLocation + SpringArmOffset
  UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(World, SpringArmLocation, 20.0, 8, WHITE, 30.0)
  UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(World, Center, 20.0, 8, BLUE, 30.0)
  self:VisualizeSpringArm(World, Center, FixedControlDir, SpringArmLength, SpringArmChannel, SpringArmRadius, RED, DARK_RED)
end

function DialogueCameraSetupAction:VisualizeSpringArm(World, Center, Dir, Length, Channel, Radius, Color1, Color2)
  local End = Center - Dir:ToVector() * Length
  local Hit, Sweep = self:Sweep(World, Channel, Radius, Center, End)
  UE4.UKismetSystemLibrary.Abs_DrawDebugLine(World, Center, Sweep, Color1, 30.0, 1)
  if Hit then
    Log.Error("sweeep", Sweep)
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(World, Sweep, Radius, 8, Color2, 30.0)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(World, Sweep, End, Color2, 30.0, 2)
  end
end

function DialogueCameraSetupAction:Sweep(World, Channel, Radius, From, To)
  local Player = DialogueUtils.GetPlayer()
  local PlayerView = Player and Player.viewObj
  if not PlayerView then
    return
  end
  local Hit = UE4.FHitResult()
  UE4.UKismetSystemLibrary.SphereTraceSingle(World, From, To, Radius, Channel, false, {PlayerView}, 0, Hit, true)
  if Hit.bBlockingHit then
    return true, Hit.Location
  else
    return false, To
  end
end

function DialogueCameraSetupAction:ChangeCamera(Camera, DeltaTime, BlendFunc, controller, Callback)
  DeltaTime = DeltaTime or 0
  BlendFunc = BlendFunc or UE4.EViewTargetBlendFunction.VTBlend_EaseOut
  controller:SetViewTargetWithBlend(Camera, DeltaTime, BlendFunc, 2)
  if Callback then
    self:ClearCameraChangeDelayHandler()
    self.CameraChangeDelayHandler = _G.DelayManager:DelaySeconds(DeltaTime, Callback, self)
  end
end

function DialogueCameraSetupAction:ConstructUICamera(transform, fieldOfView, aspectRatio, bConstrainAspectRatio)
  local UICameraClass = _G.NRCBigWorldPreloader:Get("DialogueUICamera")
  self.camera_ui = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UICameraClass, transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.camera_uiRef = UnLua.Ref(self.camera_ui)
  local camComp = self.camera_ui:GetComponentByClass(UE4.UCameraComponent)
  camComp.FieldOfView = fieldOfView
  camComp.AspectRatio = aspectRatio
  camComp.bConstrainAspectRatio = bConstrainAspectRatio
  local View = DialogueUtils.ExtraActorView(self.TargetNPC)
  local captureComp = self.camera_ui:GetComponentByClass(UE4.USceneCaptureComponent2D)
  captureComp.FOVAngle = fieldOfView
  captureComp.showOnlyActors:Add(View)
  UE4.UNRCStatics.ChangeTextureToMatchScreen(captureComp.TextureTarget, UE4Helper.GetCurrentWorld(), 0)
end

function DialogueCameraSetupAction:DestructUICamera()
  if not self.camera_ui then
    return
  end
  self.camera_ui:K2_DestroyActor()
  self.camera_ui = nil
  self.camera_uiRef = nil
end

function DialogueCameraSetupAction:SetCameraDOF(camComp, focalDistance, on)
  if not camComp then
    return
  end
  local settings = camComp.PostProcessSettings
  settings.bOverride_DepthOfFieldScale = on
  settings.bOverride_DepthOfFieldFocalDistance = on
  settings.bOverride_DepthOfFieldFarTransitionRegion = on
  settings.bOverride_DepthOfFieldNearTransitionRegion = on
  settings.bOverride_DepthOfFieldFarBlurSize = on
  settings.bOverride_DepthOfFieldNearBlurSize = on
  settings.DepthOfFieldScale = 1
  settings.DepthOfFieldFarTransitionRegion = 500
  settings.DepthOfFieldNearTransitionRegion = 300
  settings.DepthOfFieldFarBlurSize = 10
  settings.DepthOfFieldNearBlurSize = 10
  settings.DepthOfFieldFocalDistance = focalDistance
end

function DialogueCameraSetupAction:SetPlayerVisible(player, isVisible)
  player:SetVisible(isVisible)
end

function DialogueCameraSetupAction:ClearCachedUObjectRefs()
  self.PlayerBp = nil
  self.Controller = nil
  self.TargetNpcBp = nil
  self.SpringArm = nil
end

function DialogueCameraSetupAction:ClearDelayHandle()
  if self.FinishDelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self.FinishDelayHandler)
  end
  self.FinishDelayHandler = -1
end

function DialogueCameraSetupAction:ClearCameraChangeDelayHandler()
  if self.CameraChangeDelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self.CameraChangeDelayHandler)
  end
  self.CameraChangeDelayHandler = -1
end

function DialogueCameraSetupAction:OnFinish()
  if self.bLegacyCameraChanged then
    _G.NRCModuleManager:DoCmd(CameraModuleCmd.StopCameraSkillPlaying)
  end
  self:ClearCachedUObjectRefs()
  self:ClearDelayHandle()
  self:ClearCameraChangeDelayHandler()
end

function DialogueCameraSetupAction:OnExit()
  self:ClearCachedUObjectRefs()
  self:ClearDelayHandle()
  self:ClearCameraChangeDelayHandler()
end

return DialogueCameraSetupAction
