local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local HomeTaskMgr = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeTaskMgr")
local HomeController = Class("HomeController")
HomeController.EnmInputFlags = {
  Rotation = 1,
  Movement = 2,
  Selection = 4,
  AutoCamera = 8,
  ResetEnd = 1073741824
}
local ZERO_DIR = UE.FVector2D(0, 0)

function HomeController:Ctor(World)
  self.World = World
  self.AroundSp = 2
  self.MoveSped = 20
  self.InputFlags = 0
  self.MovementInputVec = UE.FVector(0, 0, 0)
  self.DeltaRotator = UE.FRotator(0, 0, 0)
  self.TaskMgr = HomeTaskMgr()
  self.BasicFOVConfig = (DataConfigManager:GetHomeGlobalConfig("home_edit_FOV_initial") or {}).num or 80
  self.MinFovScale = ((DataConfigManager:GetHomeGlobalConfig("home_edit_FOV_change_min") or {}).num or 8000) / 10000.0
  self.MaxFovScale = ((DataConfigManager:GetHomeGlobalConfig("home_edit_FOV_change_max") or {}).num or 12000) / 10000.0
  self.ConfigWheelSlice = _G.DataConfigManager:GetGlobalConfigByKeyType("mouse_wheel_scroll_camera_scale", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  self.BasicFOV = self.BasicFOVConfig
  self.WheelNum = 0
end

function HomeController:OnExitHome()
  self:StopResolveObstacle()
end

function HomeController:OnEnter()
  local Sandbox = HomeIndoorSandbox
  Sandbox:RegisterEvent(Sandbox.Event.OnTouchCameraStart, self, self.OnTouchCameraStart)
  Sandbox:RegisterEvent(Sandbox.Event.OnTouchCameraEnd, self, self.OnTouchCameraEnd)
  Sandbox:RegisterEvent(Sandbox.Event.OnTurnCamera, self, self.OnInputTurn)
  self.Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputMoveStart)
  playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END, self.OnInputMoveEnd)
  playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE, self.OnInputMove)
  Sandbox:RegisterEvent(Sandbox.Event.OnPcMovementInput, self, self.OnPcInputMovement)
  self.YawInput = 0
  self.PitchInp = 0
  self.MovementInputVec.X = 0
  self.MovementInputVec.Y = 0
  self.MovementInputVec.Z = 0
  Sandbox.World:SetEditEnvironmentEnabled(true)
  self.Player.inputComponent:SetInputEnable(self, false)
  self.Player.inputComponent:SetCameraControlEnable(self, false)
  Sandbox.HomeEditServ:Enter()
  self.HomeEditEnv = Sandbox.World.HomeEditEnv
  self.ControlCam = Sandbox.World.HomeEditEnv.ControlCam
  self.ControlPawn = Sandbox.World.HomeEditEnv.ControlPawn
  if self.Player.viewObj and UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.Home)
  end
  self.PlayerCameraManager = self.Player:GetUEController().playerCameraManager
  self.OldMovementMode = self.Player.viewObj.CharacterMovement.MovementMode
  self.Player.viewObj.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_None)
  HomeIndoorSandbox:LogDebug("OnEnter MovementMode:", self.OldMovementMode)
  self:StopResolveObstacle()
  self:StartCulling()
  self.MinFov = self.BasicFOV * self.MinFovScale
  self.MaxFov = self.BasicFOV * self.MaxFovScale
  self.WheelNum = (self.BasicFOV - self.MinFov) / (self.MaxFov - self.MinFov) * self.ConfigWheelSlice
  self.MoveFighter = nil
  self.FovFighter1 = 0
  self.FovFighter2 = 1
  self.bFighterFovControl = false
  _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_EDITING_HOME)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  self.PcMovementInput = nil
  self.IsPcMode = UE4Helper.IsPCMode()
  self.CameraSelectThreshold = 0.25
  UE.UNRCStatics.ExecConsoleCommand("r.Shadow.LLSC.CheckInterval 0")
  UpdateManager:Register(self)
  NRCModuleManager:DoCmd(MainUIModuleCmd.SetGlobalPetHUDEnabled, false)
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnEnterHomeEditMode)
  self.BeforeRuntimeLayoutVersion = HomeIndoorSandbox.Server.WorldData.RuntimeLayoutVersion
end

function HomeController:OnExit()
  UpdateManager:UnRegister(self)
  NRCModuleManager:DoCmd(MainUIModuleCmd.SetGlobalPetHUDEnabled, true)
  local Sandbox = HomeIndoorSandbox
  if self.Player.viewObj and UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj:SetHiddenMask(false, UE4.EPlayerForceHiddenType.Home)
  end
  self.Player.inputComponent:SetInputEnable(self, true)
  self.Player.inputComponent:SetCameraControlEnable(self, true)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false)
  Sandbox.HomeEditServ:Exit()
  Sandbox.World:SetEditEnvironmentEnabled(false)
  Sandbox:UnRegisterEvent(Sandbox.Event.OnTouchCameraStart, self)
  Sandbox:UnRegisterEvent(Sandbox.Event.OnTouchCameraEnd, self)
  Sandbox:UnRegisterEvent(Sandbox.Event.OnTurnCamera, self)
  Sandbox:UnRegisterEvent(Sandbox.Event.OnPcMovementInput, self)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE)
  playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END)
  playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START)
  self.ControlCam = nil
  self.ControlPawn = nil
  if self.BeforeRuntimeLayoutVersion ~= HomeIndoorSandbox.Server.WorldData.RuntimeLayoutVersion then
    self:CondStartResolveObstacle()
  end
  if UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj.CharacterMovement:SetMovementMode(self.OldMovementMode)
  end
  self.Player = nil
  self.EvaluateObstacleObjects = nil
  self:StopCulling()
  self.EnmInputFlags = 0
  self.ThisFrameWheelUp = false
  self.ThisFrameWheelUp = false
  self.WheelNum = 0
  _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_EDITING_HOME)
  UE.UNRCStatics.ExecConsoleCommand("r.Shadow.LLSC.CheckInterval 45")
  self:DetachPanelForControl()
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnExitHomeEditMode)
end

function HomeController:AttachPanelForControl(HomeMain)
  self.HomeMain = HomeMain
end

function HomeController:DetachPanelForControl()
  self.HomeMain = nil
end

function HomeController:StopResolveObstacle()
  self.ResolveObstacleTask = nil
  self.TaskMgr:CleanAllTasks()
end

function HomeController:CaptureObstacleObjects()
  self.EvaluateObstacleObjects = HomeIndoorSandbox.Utils.CapsuleTraceObstacleObjects()
end

function HomeController:LandPos()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and UE.UObject.IsValid(player.viewObj) and player.ueController and UE.UObject.IsValid(player.ueController) then
    player:LandPos(player.viewObj:Abs_K2_GetActorLocation())
  end
end

function HomeController:CondStartResolveObstacle()
  if self.ResolveObstacleTask and not self.ResolveObstacleTask:IsFinish() then
    return
  end
  if self.EvaluateObstacleObjects then
    local ObstacleObjects = HomeIndoorSandbox.Utils.CapsuleTraceObstacleObjects()
    if HomeIndoorSandbox.Utils.EqualsObstacleObjects(ObstacleObjects, self.EvaluateObstacleObjects) then
      return
    end
  end
  self.ResolveObstacleTask = self.TaskMgr:EnQueTaskWithFeedback(self.TaskMgr.TaskModules.ResolveObstacleTask, FPartial(self.OnStopResolveObstacle, self))
end

function HomeController:OnStopResolveObstacle()
  self.ResolveObstacleTask = nil
end

function HomeController:TrySelectPropsByPressing(TouchIdx, PropsData)
  local locationX, locationY, bPressed = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(TouchIdx)
  if bPressed then
    local ScreenPos = HomeIndoorSandbox.HomeEditServ.EditCreateItemInfoScreenPos
    local bEnable = HomeIndoorSandbox.HomeEditServ:TrySelectProps(ScreenPos, PropsData, true)
    if bEnable then
      self:SetInputFlag(HomeController.EnmInputFlags.Selection, true)
      self:ResetMovement()
    else
      self:SetInputFlag(HomeController.EnmInputFlags.Selection, false)
    end
  end
end

function HomeController:TryUnSelectPropsByPressing()
  if self:HasInputFlag(HomeController.EnmInputFlags.Selection) then
    self:SetInputFlag(HomeController.EnmInputFlags.Selection, false)
    HomeIndoorSandbox.HomeEditServ:StopSelectProps()
  end
end

function HomeController:TryMovePropsByPressing(ScreenPos)
  HomeIndoorSandbox.HomeEditServ:MoveSelectedProps(ScreenPos)
end

function HomeController:AdjustScreenPos(ScreenPos)
  local BorderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
  local BorderHeight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
  return UE.FVector2D(ScreenPos.X + BorderWidth, ScreenPos.Y + BorderHeight)
end

function HomeController:OnTouchCameraStart(ScreenPos)
  HomeIndoorSandbox:LogInfo("OnTouchCameraStart")
  self.ScreenMousePos = self:AdjustScreenPos(ScreenPos)
  local SelectedActor = HomeIndoorSandbox.HomeEditServ.TheSelectedPropsActor
  local bEnable, ProjectActor = HomeIndoorSandbox.Utils.ProjectilePropsSelector(self.ScreenMousePos, SelectedActor)
  if bEnable and SelectedActor then
    self:InternalSelectByCamera(SelectedActor.PropsData)
  end
  self.PreSelectedActor = ProjectActor
  self.TouchCameraStartTimestamp = os.time()
end

function HomeController:InternalSelectByCamera(TargetPropsData)
  local bEnable = HomeIndoorSandbox.HomeEditServ:TrySelectProps(self.ScreenMousePos, TargetPropsData)
  if bEnable then
    self:SetInputFlag(HomeController.EnmInputFlags.Selection, true)
    self:ResetMovement()
  else
    self:SetInputFlag(HomeController.EnmInputFlags.Selection, false)
  end
end

function HomeController:OnTouchCameraEnd(ScreenPos)
  HomeIndoorSandbox:LogInfo("OnTouchCameraEnd")
  if self.PreSelectedActor and not self:HasInputFlag(HomeController.EnmInputFlags.Selection) and os.time() <= self.TouchCameraStartTimestamp + self.CameraSelectThreshold then
    local bEnable = HomeIndoorSandbox.Utils.ProjectilePropsSelector(self:AdjustScreenPos(ScreenPos), self.PreSelectedActor)
    if bEnable then
      _G.NRCAudioManager:PlaySound2DAuto(41401004, "HomeController:OnTouchCameraEnd")
      self:InternalSelectByCamera()
    end
  end
  self:SetInputFlag(HomeController.EnmInputFlags.Rotation, false)
  if self:HasInputFlag(HomeController.EnmInputFlags.Selection) then
    self:SetInputFlag(HomeController.EnmInputFlags.Selection, false)
    HomeIndoorSandbox.HomeEditServ:StopSelectProps()
  end
end

function HomeController:OnInputTurn(Dir, ScreenPos)
  self.ScreenMousePos = self:AdjustScreenPos(ScreenPos)
  if not self:HasInputFlag(HomeController.EnmInputFlags.Selection) then
    self.YawInput = self.YawInput + Dir.X * self.AroundSp
    self.PitchInp = self.PitchInp - Dir.Y * self.AroundSp * 1.5
    self:SetInputFlag(HomeController.EnmInputFlags.Rotation, true)
  else
    self.YawInput = 0
    self.PitchInp = 0
    HomeIndoorSandbox.HomeEditServ:MoveSelectedProps(self.ScreenMousePos)
  end
end

function HomeController:HasInputFlag(Flag)
  return 0 ~= self.InputFlags & Flag
end

function HomeController:SetInputFlag(Flag, bEnable)
  if bEnable then
    self.InputFlags = self.InputFlags | Flag
  else
    self.InputFlags = self.InputFlags & ~Flag
  end
end

function HomeController:OnInputMoveStart(bJoystick, bInputJoystick, Fighter)
  if RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if bJoystick then
    if bInputJoystick then
      self.MoveFighter = Fighter
    else
      self.MoveFighter = nil
    end
    self:UpdateFighters()
  end
end

function HomeController:UpdateFighters()
  if 0 == self.MoveFighter then
    self.FovFighter1 = 1
    self.FovFighter2 = 2
  elseif 1 == self.MoveFighter then
    self.FovFighter1 = 0
    self.FovFighter2 = 2
  elseif 2 == self.MoveFighter then
    self.FovFighter1 = 0
    self.FovFighter2 = 1
  else
    self.FovFighter1 = 0
    self.FovFighter2 = 1
  end
end

function HomeController:ResetMovement(bFromMoveEnd)
  if not self:HasInputFlag(HomeController.EnmInputFlags.Movement) and self.ControlPawn and UE.UObject.IsValid(self.ControlPawn) then
    HomeIndoorSandbox:LogDebug("HomeController ResetMovement", self.ControlPawn:GetMovementComponent().Velocity, bFromMoveEnd)
    self.ControlPawn:GetMovementComponent().Velocity = FVectorZero
    self.ControlPawn:GetMovementComponent().GravityScale = 0
    self.ControlPawn:GetMovementComponent():StopMovementImmediately()
    self.ControlPawn:SetActorTickEnabled(false)
  end
end

function HomeController:OnInputMoveEnd(bJoystick)
  HomeIndoorSandbox:LogDebug("HomeController OnInputMoveEnd", bJoystick)
  self:SetInputFlag(HomeController.EnmInputFlags.Movement, false)
  self:ResetMovement(true)
  if bJoystick then
    self.MoveFighter = nil
    self:UpdateFighters()
  end
end

function HomeController:OnInputMove(Dir, Axis)
  self.MovementInputVec.X = self.MovementInputVec.X - Dir.Y * self.MoveSped * Axis
  self.MovementInputVec.Y = self.MovementInputVec.Y + Dir.X * self.MoveSped * Axis
  self:SetInputFlag(HomeController.EnmInputFlags.Movement, true)
end

function HomeController:OnPcInputMovement(Dir)
  if self.PcMovementInput == nil then
    self.PcMovementInput = ZERO_DIR
  end
  self.PcMovementInput = self.PcMovementInput + Dir
  self.HasPcMovement = true
end

function HomeController:OnPCFOVInputUp()
  self.ThisFrameWheelUp = true
end

function HomeController:OnPCFOVInputDown()
  self.ThisFrameWheelDown = true
end

function HomeController:ToggleToWallCamera()
  self.DesiredAutoCameraPitch = -1
  self.CameraPitchLerpPercent = 0
  self:SetInputFlag(HomeController.EnmInputFlags.AutoCamera, true)
end

function HomeController:ToggleToGroundCamera()
  self.DesiredAutoCameraPitch = -45
  self.CameraPitchLerpPercent = 0
  self:SetInputFlag(HomeController.EnmInputFlags.AutoCamera, true)
end

function HomeController:HasInput()
  local Flags = self.InputFlags
  return 0 ~= Flags & HomeController.EnmInputFlags.Movement or 0 ~= Flags & HomeController.EnmInputFlags.Rotation
end

if RocoEnv.PLATFORM_WINDOWS then
  function HomeController:EvalTickFov(Dt)
    if self.ThisFrameWheelUp then
      self.ThisFrameWheelUp = false
      
      if self.WheelNum > 0 then
        self.WheelNum = self.WheelNum - 0.5
      end
    end
    if self.ThisFrameWheelDown then
      self.ThisFrameWheelDown = false
      if self.WheelNum < self.ConfigWheelSlice then
        self.WheelNum = self.WheelNum + 0.5
      end
    end
    local Percent = self.WheelNum / self.ConfigWheelSlice
    local desiredFov = Percent * (self.MaxFov - self.MinFov) + self.MinFov
    self:TickFOV(Dt, desiredFov)
  end
else
  function HomeController:EvalTickFov(Dt)
    local locationX0, locationY0, bPressed0 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(self.FovFighter1)
    
    local locationX1, locationY1, bPressed1 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(self.FovFighter2)
    if bPressed0 and bPressed1 and (not (self.HomeMain and self.HomeMain.enableView) or self.HomeMain.FurnitureTouchPlace:IfPosInFurnitureListBounds(locationX0, locationY0) or self.HomeMain.FurnitureTouchPlace:IfPosInFurnitureListBounds(locationX1, locationY1)) then
      bPressed0 = false
      bPressed1 = false
    end
    if bPressed0 and bPressed1 then
      local dx = locationX1 - locationX0
      local dy = locationY1 - locationY0
      local Pixels = UE.FVector2D(dx, dy):Size()
      if not self.bFighterFovControl then
        self.bFighterFovControl = true
        self._FromFOV = HomeIndoorSandbox.World.HomeEditEnv:GetFOV()
        self._FromDIS = Pixels
      else
        local dtPixels = Pixels - self._FromDIS
        local dtZoomFov = dtPixels * -0.1
        local zoomFov = self._FromFOV + dtZoomFov
        self:TickFOV(Dt, zoomFov)
      end
    elseif self.bFighterFovControl then
      self.bFighterFovControl = false
    end
    if self.bFighterFovControl then
      self.PitchInp = 0
      self.YawInput = 0
    end
  end
end

function HomeController:TickFOV(Dt, DesiredFOV)
  local TargetFov = math.clamp(DesiredFOV, self.MinFov, self.MaxFov)
  local PrevFov = HomeIndoorSandbox.World.HomeEditEnv:GetFOV()
  local LerpFov = HomeIndoorSandbox.Utils.LerpFov(PrevFov, TargetFov, Dt)
  HomeIndoorSandbox.World.HomeEditEnv:ModifyFOV(LerpFov)
end

function HomeController:StartCulling()
  self.CullingActors = {}
end

function HomeController:StopCulling()
  for Actor, _ in pairs(self.CullingActors) do
    Actor:SetBeCull(false)
  end
  self.CullingActors = {}
end

function HomeController:TickCulling()
  local EditRoomId = HomeIndoorSandbox.HomeEditServ.EditRoomId
  if 0 == EditRoomId then
    return
  end
  for Actor, _ in pairs(self.CullingActors) do
    self.CullingActors[Actor] = false
  end
  local CameraRotation = self.PlayerCameraManager:GetCameraRotation()
  local CameraDir = UE4.UKismetMathLibrary.GetForwardVector(CameraRotation)
  local Room = HomeIndoorSandbox.World:GetRoomById(EditRoomId)
  local StaticActors = Room.AllDecoActors
  for StaticActor, Id in pairs(StaticActors) do
    if StaticActor:IsValid() then
      local Normal = StaticActor:GetNormalByRoomId(EditRoomId)
      if Normal then
        local Dot = Normal:Dot(CameraDir)
        if Dot >= 0.17 then
          self.CullingActors[StaticActor] = true
        end
      end
    else
      self.CullingActors[StaticActor] = nil
      StaticActors[Id] = nil
    end
  end
  for StaticActor, Id in pairs(Room.LinkDecoActors) do
    if StaticActor:IsValid() then
      local Normal = StaticActor:GetNormalByRoomId(EditRoomId)
      if Normal then
        local Dot = Normal:Dot(CameraDir)
        if Dot >= 0.17 then
          self.CullingActors[StaticActor] = true
        end
      end
    else
      self.CullingActors[StaticActor] = nil
    end
  end
  for Actor, Cull in pairs(self.CullingActors) do
    Actor:SetBeCull(Cull)
    if not Cull then
      self.CullingActors[Actor] = nil
    end
  end
end

function HomeController:OnTick(Dt)
  if self.IsPcMode and self.PcMovementInput ~= nil then
    if self.PcMovementInput == ZERO_DIR and self.HasPcMovement then
      self:OnInputMoveEnd(true)
      self.HasPcMovement = false
    elseif self.HasPcMovement then
      self.PcMovementInput:Normalize()
      self:OnInputMove(self.PcMovementInput, 1)
      self.PcMovementInput = ZERO_DIR
    end
  end
  self:TickCulling()
  self:EvalTickFov(Dt)
  local Flag = self.InputFlags
  if Flag == HomeController.EnmInputFlags.ResetEnd then
    HomeIndoorSandbox.HomeEditServ:PostAdjustControlPawnLocation()
    return
  end
  if 0 == Flag then
    self:SetInputFlag(HomeController.EnmInputFlags.ResetEnd, true)
    self:ResetMovement()
    return
  end
  if not self:HasInputFlag(HomeController.EnmInputFlags.Rotation) then
    if self:HasInputFlag(HomeController.EnmInputFlags.AutoCamera) then
      self.CameraPitchLerpPercent = self.CameraPitchLerpPercent + 5 * Dt
      if self.CameraPitchLerpPercent > 1 or self.HomeEditEnv:ModifyControlCamPitch(self.DesiredAutoCameraPitch, self.CameraPitchLerpPercent) then
        self:SetInputFlag(HomeController.EnmInputFlags.AutoCamera, false)
      end
      self:ResetMovement()
      return
    end
  else
    self:SetInputFlag(HomeController.EnmInputFlags.AutoCamera, false)
  end
  if not self:HasInput() then
    self:ResetMovement()
    return
  end
  if not self.ControlCam then
    self:ResetMovement()
    return
  end
  local DeltaYaw = self.YawInput
  local DeltaPitch = self.PitchInp
  self.DeltaRotator.Pitch = DeltaPitch
  self.DeltaRotator.Yaw = DeltaYaw
  local DesiredRotator = self.ControlCam:K2_GetActorRotation()
  DesiredRotator = DesiredRotator + self.DeltaRotator
  DesiredRotator.Pitch = math.clamp(DesiredRotator.Pitch, -80, 30)
  DesiredRotator.Roll = 0
  self.PitchInp = 0
  self.YawInput = 0
  local DesiredMovement = DesiredRotator:RotateVector(self.MovementInputVec)
  self.MovementInputVec.X = 0
  self.MovementInputVec.Y = 0
  self.MovementInputVec.Z = 0
  DesiredMovement.Z = 0
  self.ControlCam:K2_SetActorRotation(DesiredRotator, false)
  self.ControlPawn:GetMovementComponent().Velocity = DesiredMovement * 50
  HomeIndoorSandbox.HomeEditServ:PostAdjustControlPawnLocation()
  self.ControlPawn:SetActorTickEnabled(true)
end

function HomeController:SpawnPlaceProps(FurnitureData, ScreenPos)
  HomeIndoorSandbox.HomeEditServ:TryCreateItemInfo(FurnitureData, ScreenPos)
end

function HomeController:SpawnDecoration(FurnitureData)
  HomeIndoorSandbox.HomeEditServ:TryCreateDecoInfo(FurnitureData)
end

function HomeController:UnLoadAllProps()
  HomeIndoorSandbox.HomeEditServ:UnLoadAllProps()
end

function HomeController:UnloadPackUpProps()
  HomeIndoorSandbox.HomeEditServ:UnloadPackUpProps()
end

function HomeController:UnloadPackUpSpecifyProps(PropsData)
  HomeIndoorSandbox.HomeEditServ:UnloadPackUpSpecifyProps(PropsData)
end

function HomeController:RotationPropsOnce()
  HomeIndoorSandbox.HomeEditServ:RotationLatestProps()
end

function HomeController:CancelByUser()
  if HomeIndoorSandbox.HomeEditServ.ThePreviewDecoData then
    HomeIndoorSandbox.HomeEditServ:CancelDecorate()
  else
    HomeIndoorSandbox.HomeEditServ:CancelPlaceProps()
  end
end

function HomeController:ConfirmByUser()
  if HomeIndoorSandbox.HomeEditServ.ThePreviewDecoData then
    HomeIndoorSandbox.HomeEditServ:ConfirmDecorate()
  else
    HomeIndoorSandbox.HomeEditServ:ConfirmPlaceProps()
  end
end

function HomeController:SwitchNextEditRoom()
  HomeIndoorSandbox.HomeEditServ:SwitchNextEditRoom()
end

function HomeController:SwitchPrevEditRoom()
  HomeIndoorSandbox.HomeEditServ:SwitchPrevEditRoom()
end

function HomeController:ReqUpgradeHome()
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    return
  end
  return HomeIndoorSandbox.UpgradeServ:ReqUpgradeHome()
end

function HomeController:ReqEnterEditMainPanel()
  if not self:JudgeIfCanEnterEditMode() then
    return
  end
  HomeIndoorSandbox.HomeEditServ:ReqEnterEditMode()
end

function HomeController:ReqExitEdit()
  HomeIndoorSandbox.HomeEditServ:ReqExitEdit()
end

function HomeController:JudgeIfCanEnterEditMode()
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    HomeIndoorSandbox:LogWarn("[EDIT] already in edit mode")
    return false
  end
  if not HomeIndoorSandbox.Server:IsLocalMaster() then
    HomeIndoorSandbox:DebugTips("\233\157\158\232\135\170\229\183\177\229\174\182\229\155\173")
    HomeIndoorSandbox:LogWarn("[EDIT] not in local home")
    return false
  end
  if not HomeIndoorSandbox.UpgradeServ:IsUpgradeEstablished() then
    HomeIndoorSandbox:DebugTips("\229\141\135\231\186\167\228\184\173")
    HomeIndoorSandbox:LogWarn("[EDIT] upgrading")
    return false
  end
  if FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_EDIT_HOME, true, true) then
    HomeIndoorSandbox:LogWarn("[EDIT] function ban")
    return false
  end
  local PawnResource = HomeIndoorSandbox.ResMgr:TryGetResource(HomeIndoorSandbox.Define.ControlPawnClassPath, true)
  local PropsStatusResource = HomeIndoorSandbox.ResMgr:TryGetResource(HomeIndoorSandbox.Define.PropsStatusClassPath, true)
  if not PawnResource or not PropsStatusResource then
    HomeIndoorSandbox:Ensure(false, "wait for loading resource")
    return
  end
  if HomeIndoorSandbox.HomeEditServ:IsInEditCountDown() then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.home_edit_cd)
    return
  end
  if not HomeIndoorSandbox.World:GetPlayerRoomId() then
    HomeIndoorSandbox:DebugTips("\231\142\169\229\174\182\230\178\161\230\156\137\228\189\141\231\189\174")
    HomeIndoorSandbox:LogWarn("[EDIT] not play room id")
    return
  end
  return true
end

function HomeController:OnTypeTabToggled(bIsWall, bIsDefault)
  if bIsDefault then
    return
  end
  if bIsWall then
    self:ToggleToWallCamera()
  else
    self:ToggleToGroundCamera()
  end
end

function HomeController:EnterFurnitureCreation(ProtoData, ExtraInfo)
  HomeIndoorSandbox.HomeCreationServ:EnterFurnitureCreation(ProtoData, ExtraInfo)
end

return HomeController
