local HomeTaskMgr = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeTaskMgr")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local HomePropsService = Class("HomePropsService")

function HomePropsService:Ctor()
  self.TaskMgr = HomeTaskMgr()
  self.RoomLoadingTasks = {}
  self.RoomDynamicSpawnTasks = {}
  self.LoadFailedRoomProps = {}
  self.RoomLoadingFlags = {}
  self.RoomTaskManagers = {}
end

function HomePropsService:OnExitHome()
  self.TaskMgr:CleanAllTasks()
  for i, v in pairs(self.RoomTaskManagers) do
    v:CleanAllTasks()
  end
  self.RoomLoadingTasks = {}
  self.RoomDynamicSpawnTasks = {}
  self.LoadFailedRoomProps = {}
  self.RoomLoadingFlags = {}
  self.RoomTaskManagers = {}
end

function HomePropsService:GetOrCreateRoomTaskManager(RoomId)
  local Mgr = self.RoomTaskManagers[RoomId]
  if not Mgr then
    Mgr = HomeTaskMgr()
    self.RoomTaskManagers[RoomId] = Mgr
  end
  return Mgr
end

function HomePropsService:LoadRoomProps(RoomId, bInitialize)
  local RoomTaskManager = self:GetOrCreateRoomTaskManager(RoomId)
  RoomTaskManager:CleanAllTasks()
  self.LoadFailedRoomProps[RoomId] = nil
  local RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId)
  local OnPropsResLoadFailed = FPartial(self.OnPropsResLoadFailed, self)
  if RoomData then
    local NoDependency = RoomData:GetNoDependencyPropsDataList()
    local NoDependencyTaskModuleList = {}
    for i, PropsData in ipairs(NoDependency) do
      table.insert(NoDependencyTaskModuleList, {
        RoomTaskManager.TaskModules.LoadPropsTask,
        PropsData,
        RoomId,
        OnPropsResLoadFailed
      })
    end
    local Dependency = RoomData:GetDependencyPropsDataList()
    local DependencyTaskModuleList = {}
    for i, PropsData in ipairs(Dependency) do
      table.insert(DependencyTaskModuleList, {
        RoomTaskManager.TaskModules.LoadPropsTask,
        PropsData,
        RoomId,
        OnPropsResLoadFailed
      })
    end
    RoomTaskManager:EnQueTask(RoomTaskManager.TaskModules.AsyncTask, NoDependencyTaskModuleList)
    self.RoomLoadingFlags[RoomId] = true
    self.RoomLoadingTasks[RoomId] = RoomTaskManager:EnQueTaskWithFeedback(RoomTaskManager.TaskModules.AsyncTask, FPartial(self.OnRoomLoadFinish, self, RoomId, bInitialize), DependencyTaskModuleList)
  end
end

function HomePropsService:OnRoomLoadFinish(RoomId, bInitialize)
  self.RoomLoadingFlags[RoomId] = nil
  if bInitialize and RoomId == HomeIndoorSandbox.World:GetPlayerRoomId() and not HomeIndoorSandbox.HomeEditServ:InEditMode() then
    HomeIndoorSandbox.World.Controller:CondStartResolveObstacle()
  end
  if not next(self.RoomLoadingFlags) and HomeIndoorSandbox:InLocalMasterIndoor() then
    local NeedResaveRooms = {}
    local Rooms = HomeIndoorSandbox.World.Rooms
    for LoadedRoomId, Room in pairs(Rooms) do
      local FailedProps = self.LoadFailedRoomProps[LoadedRoomId]
      local RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(LoadedRoomId)
      if FailedProps and next(FailedProps) then
        for PropsId, PropsData in pairs(FailedProps) do
          RoomData:RemovePropsData(PropsData)
        end
        table.insert(NeedResaveRooms, LoadedRoomId)
      end
      self.LoadFailedRoomProps[LoadedRoomId] = nil
    end
    
    local function DoForceSaved()
      self.OnFailedUploading = false
      if NeedResaveRooms and next(NeedResaveRooms) then
        local function OnUploadFinish(bSuccess)
          self.OnFailedUploading = false
          
          HomeIndoorSandbox:LogWarn("ForceSave Finish", bSuccess)
        end
        
        HomeIndoorSandbox:LogWarn("ForceSave Begin")
        self.OnFailedUploading = self.TaskMgr:EnQueTaskWithFeedback(HomeIndoorSandbox.TaskMgr.TaskModules.ProtoSendTask, OnUploadFinish, "ReqUploadRooms", NeedResaveRooms, true)
      end
    end
    
    DoForceSaved()
  end
  if HomeIndoorSandbox:InOtherHomeIndoor() and RoomId == HomeIndoorSandbox.World:GetPlayerRoomId() then
    HomeIndoorSandbox.Module:LandPos_All3pPlayers(true)
  end
end

function HomePropsService:IsRoomEstablished(RoomId)
  if self.OnFailedUploading then
    HomeIndoorSandbox:LogWarn("wait for server confirm ...")
    HomeIndoorSandbox:DebugTips("\230\173\163\229\156\168\229\141\184\228\184\139\230\145\134\230\148\190\229\164\177\232\180\165\231\154\132\230\145\134\228\187\182\229\136\176\230\156\141\229\138\161\229\153\168\239\188\140\231\173\137\229\190\133\230\156\141\229\138\161\229\153\168\229\147\141\229\186\148")
    return
  end
  local SpawnTask = self.RoomDynamicSpawnTasks[RoomId]
  if SpawnTask and not SpawnTask:IsFinish() then
    return
  end
  local Task = self.RoomLoadingTasks[RoomId]
  local LoadingFinish = not Task or Task:IsFinish()
  if not LoadingFinish then
    return
  end
  local ConfirmFinish = HomeIndoorSandbox.HomeEditServ:IsConfirmEstablished(RoomId)
  if not ConfirmFinish then
    return
  end
  return true
end

function HomePropsService:OnPostLoad(RoomId, PropsActor, PropsData)
  local WorldRoom = HomeIndoorSandbox.World:GetRoomById(RoomId)
  local RoomPlane = WorldRoom:GetPlaneByActorId(PropsData.PlaneMasterId)
  local Failed = false
  local EditPlaceInvalid = false
  if not HomeIndoorSandbox:Ensure(RoomPlane, "cannot found room plane by actor id", RoomId, PropsData.PlaneMasterId) then
    Failed = true
  else
    PropsData:OnPrePlaceProps(PropsActor)
    if PropsData.bTempData then
      if not HomeIndoorSandbox:Ensure(RoomPlane:EditPlaceProps(PropsActor), "spawn but cannot place temp", RoomId, PropsData.Id, RoomPlane.PlaneId) then
        Failed = true
        EditPlaceInvalid = true
      end
    elseif not HomeIndoorSandbox:Ensure(RoomPlane:LoadPlaceProps(PropsActor), "spawn but cannot place", RoomId, PropsData.Id, RoomPlane.PlaneId) then
      Failed = true
    end
  end
  if Failed then
    PropsData:OnPreRelease()
    PropsActor:K2_DestroyActor()
    HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId):RemovePropsData(PropsData)
    if not PropsData.bTempData then
      local FailedProps = self.LoadFailedRoomProps[RoomId]
      if not FailedProps then
        FailedProps = {}
        self.LoadFailedRoomProps[RoomId] = FailedProps
      end
      FailedProps[PropsData.Id] = PropsData
    end
  end
  if PropsData.bTempData then
    HomeIndoorSandbox.HomeEditServ:OnPostLoad(PropsData, PropsActor, Failed, EditPlaceInvalid)
  end
  if not Failed then
    PropsData:OnPostLoad(PropsActor)
  end
end

function HomePropsService:OnPropsResLoadFailed(PropsData)
  if PropsData.bTempData then
    HomeIndoorSandbox.HomeEditServ:OnPropsResLoadFailed(PropsData)
  else
    local RoomId = PropsData.RoomId
    PropsData:OnPreRelease()
    HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId):RemovePropsData(PropsData)
    local FailedProps = self.LoadFailedRoomProps[RoomId]
    if not FailedProps then
      FailedProps = {}
      self.LoadFailedRoomProps[RoomId] = FailedProps
    end
    FailedProps[PropsData.Id] = PropsData
  end
end

function HomePropsService:DoDynamicSpawnProps(RoomId, PropsData)
  local SpawnTask = self.RoomDynamicSpawnTasks[RoomId]
  if SpawnTask and not SpawnTask:IsFinish() then
    return false
  end
  local RoomTaskManager = self:GetOrCreateRoomTaskManager(RoomId)
  self.RoomDynamicSpawnTasks[RoomId] = RoomTaskManager:EnQueTask(RoomTaskManager.TaskModules.AsyncTask, {
    {
      RoomTaskManager.TaskModules.LoadPropsTask,
      PropsData,
      RoomId
    }
  }, FPartial(self.OnDynamicSpawnTaskFinish, self, RoomId))
  return true
end

function HomePropsService:OnDynamicSpawnTaskFinish(RoomId, TaskMap)
  if self.RoomDynamicSpawnTasks[RoomId] then
    self.RoomDynamicSpawnTasks[RoomId].PropsActor = TaskMap[1].Worker and TaskMap[1].Worker.PropsActor
  end
end

function HomePropsService:GetRoomDynamicSpawnTask(RoomId)
  return self.RoomDynamicSpawnTasks[RoomId]
end

function HomePropsService:StopRoomDynamicSpawnTask(RoomId)
  local Task = self.RoomDynamicSpawnTasks[RoomId]
  if Task then
    Task:NotifyFinish()
    self.RoomDynamicSpawnTasks[RoomId] = nil
  end
end

function HomePropsService:SaveRoomProps(RoomId)
  local WorldRoom = HomeIndoorSandbox.World:GetRoomById(RoomId)
  local WorldData = HomeIndoorSandbox.Server.WorldData
  local RoomData = WorldData:GetRoomData(RoomId)
  RoomData:ClearRoomPropsData()
  for PlaneId, Plane in pairs(WorldRoom.HomePlanes) do
    for PropsData, _ in pairs(Plane.PropsDataSet) do
      if not PropsData.bTempData and (not PropsData.RealtimeParentPropsData or not PropsData.RealtimeParentPropsData.bTempData) then
        PropsData:Save()
        RoomData:AddPropsData(PropsData)
      end
    end
  end
  self:ReloadRoomProps(RoomId)
end

function HomePropsService:RecoverRoomProps(RoomId)
  for i, PropsData in ipairs(HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId):GetPropsDataList()) do
    PropsData:Recover()
  end
  self:ReloadRoomProps(RoomId)
end

function HomePropsService:ClearRoomProps(RoomId)
  local RoomTaskManager = self.RoomTaskManagers[RoomId]
  if RoomTaskManager then
    RoomTaskManager:CleanAllTasks()
  end
  local WorldRoom = HomeIndoorSandbox.World:GetRoomById(RoomId)
  WorldRoom:ClearRoomProps()
end

function HomePropsService:ReloadRoomProps(RoomId, bInitialized)
  local WorldRoom = HomeIndoorSandbox.World:GetRoomById(RoomId)
  WorldRoom:ClearRoomProps()
  self:LoadRoomProps(RoomId, bInitialized)
end

function HomePropsService:CondLoadRoom(RoomId)
  local Task = self.RoomLoadingTasks[RoomId]
  if Task and Task:IsFinish() then
    return
  end
  self:LoadRoomProps(RoomId)
end

function HomePropsService:UnloadPackUpProps(PropsData)
  local ChildActors = PropsData:ResolveSubPropsActorArray()
  if ChildActors then
    for _, Child in tpairs(ChildActors) do
      if Child.PropsData then
        self:UnloadPackUpProps(Child.PropsData)
      end
    end
  end
  local RoomId = PropsData.RoomId
  local WorldRoom = HomeIndoorSandbox.World:GetRoomById(RoomId)
  local WorldPlane = WorldRoom:GetPlaneByActorId(PropsData.RealtimePlane.PlaneMasterId)
  WorldPlane:RemoveProps(PropsData)
  HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId):RemovePropsData(PropsData)
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    local Data = HomeIndoorSandbox.Module:GetData()
    Data:OnEditingFurnitureRecycle(PropsData)
  end
end

function HomePropsService:ResolveLookAtPropsBestTransform(PropsData, CameraParams)
  if not PropsData then
    return
  end
  if not CameraParams then
    Log.Error("ResolveLookAtPropsBestTransform  CameraPara is nil")
    return
  end
  local Props = PropsData:ResolvePropsActor()
  if not Props then
    return
  end
  if PropsData:GetTypeEnum() == Enum.FurnitureType.FT_WALL_DECORATION then
    return
  end
  local LookAtPitchAngle = DEBUG_FURNITURE_LOOK_ANGLE or CameraParams[1] or 30
  local RelativeLookDistanceParam = DEBUG_FURNITURE_LOOK_PROJ_DIS or CameraParams[2] or 300
  local RelativeLookHeightParam = math.tan(math.rad(LookAtPitchAngle)) * RelativeLookDistanceParam
  local Forward = Props:GetActorForwardVector()
  local Right = Props:GetActorRightVector()
  local DirList = {
    Forward,
    Right,
    -Forward,
    -Right
  }
  local Location = Props:Abs_K2_GetActorLocation()
  local Pos = Location + FVectorUp * 50
  local Dis = RelativeLookDistanceParam + 80
  local BestDir = UE.FVector(0, 0, 0)
  if BestDir:IsNearlyZero(0.01) then
    local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local Controller = Player:GetUEController()
    local CamLoc = Controller.PlayerCameraManager:Abs_GetCameraLocation()
    BestDir = CamLoc - Pos
    BestDir.Z = 0
  end
  BestDir:Normalize()
  local TargetRotation = (-BestDir):ToRotator()
  local Dir = TargetRotation:ToVector()
  local TargetLocation = Pos - Dir * RelativeLookDistanceParam + FVectorUp * RelativeLookHeightParam
  local TargetRot = UE4.UKismetMathLibrary.FindLookAtRotation(TargetLocation, Pos)
  TargetRotation = TargetRot:ToQuat()
  local Transform = UE.FTransform(TargetRotation, TargetLocation, FVectorOne)
  if HomeIndoorSandbox.Utils.EnableDebugDraw then
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), TargetLocation, Pos, UE.FLinearColor(0, 1, 0, 1), 30, 5)
  end
  HomeIndoorSandbox:LogDebug("TargetRotation:", TargetRot)
  HomeIndoorSandbox:LogDebug("TargetLocation:", TargetLocation)
  return Transform
end

function HomePropsService:GetPropsDataById(Id)
  return HomeIndoorSandbox.Server.WorldData.HomeFurnitureGuidSet[Id]
end

function HomePropsService:GetCameraParamsByPropsData(PropsData)
  return PropsData and PropsData.Conf and PropsData.Conf.furniture_interface_camera or {}
end

function HomePropsService:RequestPropsCamera(PropsData, bKeepCollision)
  if self.DelayCameraEstablish then
    DelayManager:CancelDelayById(self.DelayCameraEstablish)
    self.DelayCameraEstablish = nil
  end
  if not PropsData then
    HomeIndoorSandbox.Module:DispatchEvent(HomeModuleEvent.OnFurnitureCamPrepared)
    return
  end
  local CameraParams = self:GetCameraParamsByPropsData(PropsData)
  local Transform = self:ResolveLookAtPropsBestTransform(PropsData, CameraParams)
  if not Transform then
    HomeIndoorSandbox.Module:DispatchEvent(HomeModuleEvent.OnFurnitureCamPrepared)
    return
  end
  HomeIndoorSandbox.World.HomeEditEnv:SpawnFurnitureCamera(function(Cam)
    if not Cam then
      HomeIndoorSandbox.Module:DispatchEvent(HomeModuleEvent.OnFurnitureCamPrepared)
      return
    end
    local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local Controller = Player:GetUEController()
    Cam:Abs_K2_SetActorLocationAndRotation(Transform.Translation, Transform.Rotation:ToRotator(), false, nil, true)
    local Arm = Cam.SpringArm
    Arm.SocketOffset.Y = DEBUG_FURNITURE_LOOK_OFFSET_Y or CameraParams[3] or 0
    Arm.SocketOffset.Z = DEBUG_FURNITURE_LOOK_OFFSET_Z or CameraParams[4] or 0
    if Controller.PlayerCameraManager.CameraHited then
      HomeIndoorSandbox.Module:DispatchEvent(HomeModuleEvent.OnFurnitureCamPrepared)
      return
    end
    local LerpTime = (CameraParams[5] or 500) / 1000
    self.FurnitureCameraViewTarget = Cam
    self.CurrentCameraParams = CameraParams
    Controller.PlayerCameraManager:UseBigWorldCamera(false)
    Controller:SetViewTargetWithBlend(Cam, LerpTime, UE4.EViewTargetBlendFunction.VTBlend_Cubic, 2, true)
    self.DelayCameraEstablish = DelayManager:DelaySeconds(LerpTime, function()
      self.DelayCameraEstablish = nil
      HomeIndoorSandbox.Module:DispatchEvent(HomeModuleEvent.OnFurnitureCamPrepared)
    end)
  end)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player:SetVisible(false, bKeepCollision)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  PropsData:ResolvePropsActor():SetVisible(true)
  return true
end

function HomePropsService:ReleasePropsCamera()
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  if UE4.UObject.IsValid(Controller) and Controller:GetViewTarget() == self.FurnitureCameraViewTarget and self.CurrentCameraParams then
    Controller.PlayerCameraManager:UseBigWorldCamera(true)
    Controller.PlayerCameraManager.blendBackImmediately = true
    Controller:SetViewTargetWithBlend(Controller, (self.CurrentCameraParams[6] or 500) / 1000, UE4.EViewTargetBlendFunction.VTBlend_Cubic, 2, true)
  end
  Player:SetVisible(true)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false)
end

return HomePropsService
