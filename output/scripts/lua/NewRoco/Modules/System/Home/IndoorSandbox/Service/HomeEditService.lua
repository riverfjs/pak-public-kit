local HomeTaskMgr = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeTaskMgr")
local HomeEnum = require("NewRoco/Modules/System/Home/HomeEnum")
local HomeEditContext = require("NewRoco.Modules.System.Home.IndoorSandbox.Data.HomeEditContext")
local HomeEditService = Class("HomeEditService")

function HomeEditService:Ctor()
  self.RoomEditFlag = {}
  self.RoomConfirmFlags = {}
  self.EditRoomId = 0
  self.EditTaskMgr = HomeTaskMgr()
  self.EditExpiredTime = os.time()
  self.PublishExpiredTime = os.time()
  self.EditingPropsDataManagerMap = {}
  self.EditContext = HomeEditContext(self)
  self.EditContext:RegisterPropsOperation("VisibilityCollisionChannel", FPartial(self.ProcessPropsVisibilityChannel, self))
end

function HomeEditService:OnExitHome()
  self.RoomConfirmFlags = {}
  self.bPendingEnterEditMode = false
end

function HomeEditService:Enter()
  self.bPlatformEnableSDOC = UE.UNRCStatics.GetConsoleVarInt32("r.Mobile.AllowSDOC")
  UE.UNRCStatics.ExecConsoleCommand("r.Mobile.AllowSDOC 0")
  self.RoomEditFlag = {}
  self.EditRoomId = 0
  self.ThePreviewDecoData = nil
  HomeIndoorSandbox.HomeEditServ:SwitchToEditRoom(HomeIndoorSandbox.World:GetPlayerRoomId())
  HomeIndoorSandbox.World:ToggleCameraCollisionEnabled(false)
  HomeIndoorSandbox.World:RefreshControlNpcVisibility()
  self.EditContext:OnActivate()
end

function HomeEditService:Exit()
  if self.bPlatformEnableSDOC then
    UE.UNRCStatics.ExecConsoleCommand("r.Mobile.AllowSDOC 1")
  else
    UE.UNRCStatics.ExecConsoleCommand("r.Mobile.AllowSDOC 0")
  end
  local EditRoomId = self.EditRoomId
  self:DiscardAllEdit()
  self.RoomEditFlag = {}
  self.EditRoomId = 0
  self.ThePreviewDecoData = nil
  HomeIndoorSandbox.World:RefreshRoomVisibility()
  HomeIndoorSandbox.World:ToggleCameraCollisionEnabled(true)
  HomeIndoorSandbox.World:RefreshControlNpcVisibility()
  self.EditContext:OnDeactivate(EditRoomId)
end

function HomeEditService:InEditMode()
  return 0 ~= self.EditRoomId
end

function HomeEditService:TryCreateItemInfo(FurnitureData, ScreenPos)
  self.EditCreateItemInfoScreenPos = ScreenPos
  local FurnitureItemConf = FurnitureData.FurnitureItemConf
  if HomeIndoorSandbox:Ensure(FurnitureItemConf, "cannot found furniture item conf") then
    local ModelPath = FurnitureItemConf.model
    if not ModelPath or "" == ModelPath then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_ESTABLISH)
      return false
    end
    local RoomId = self.EditRoomId
    if not HomeIndoorSandbox.HomePropsServ:IsRoomEstablished(RoomId) then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_ESTABLISH)
      return false
    end
    if self.TheSelectedPropsActor then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_EDIT_ONLY_ONE)
      return false
    end
    local RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId)
    if not RoomData then
      HomeIndoorSandbox:Ensure(false, "Invalid Room", RoomId)
      return
    end
    local Count = RoomData:GetPropsCount()
    if Count >= DataConfigManager:GetHomeGlobalConfig("furniture_num_max").num then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_MAX_NUM)
      return false
    end
    local CanPlace, HomePlane, WorldPosition, ParentPropsData, CameraDirection = HomeIndoorSandbox.Utils.ProjectileProps(FurnitureItemConf, ScreenPos)
    if CanPlace then
      local LeftDir = UE.FVector(0, -1, 0)
      local Dot = FVectorUp:Dot(CameraDirection)
      if math.abs(Dot - 1) > 0.01 then
        LeftDir = FVectorUp:Cross(CameraDirection)
        LeftDir:Normalize()
      end
      if self:TryDynamicSpawnRoomProps(WorldPosition, LeftDir:ToRotator(), FurnitureItemConf, FurnitureData, HomePlane, ParentPropsData) then
      end
    else
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PROJECTILE_FAILED)
    end
  else
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_NO_CONF)
  end
end

function HomeEditService:TryCreateDecoInfo(FurnitureData)
  local InteriorFinishConf = FurnitureData.InteriorFinishConf
  if HomeIndoorSandbox:Ensure(InteriorFinishConf, "cannot found interior finish conf") then
    local WorldRoom = self:GetEditRoom()
    if not WorldRoom then
      return
    end
    local RoomData = WorldRoom:GetRoomData()
    local DecoData = RoomData:GetDecoDataById(InteriorFinishConf.id)
    if DecoData then
      HomeIndoorSandbox:DebugTips("\229\183\178\231\187\143\229\156\168\228\189\191\231\148\168\228\186\134")
      return
    end
    DecoData = RoomData:CreateDynamicDecoDataByConfig(InteriorFinishConf, FurnitureData.BagItem.gid or -1)
    local CurComfortValue = RoomData:CalcDecoComfortValue()
    RoomData:AddDecoData(DecoData)
    local NewComfortValue = RoomData:CalcDecoComfortValue()
    self.ThePreviewDecoData = DecoData
    HomeIndoorSandbox.HomeDecoServ:LoadRoomDecoByMainType(self.EditRoomId, DecoData:GetConfigMainType())
    HomeIndoorSandbox.HomeLightServ:ApplyRoomLightSettingsByConfig(self.EditRoomId, DecoData.ConfId)
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnEditDecoFinished, self.ThePreviewDecoData, NewComfortValue - CurComfortValue)
  end
end

function HomeEditService:TryDynamicSpawnRoomProps(WorldPosition, WorldRotation, Config, FurnitureData, HomePlane, ParentPropsData)
  local RoomId = self.EditRoomId
  if ParentPropsData and not ParentPropsData:ResolvePropsActor() then
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED)
    return false
  end
  if Config.id ~= FurnitureData.BagItem.id then
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED)
    return false
  end
  if (FurnitureData.RemainingNum or 0) <= 0 then
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED)
    return false
  end
  local RoomPlane = HomePlane
  if Config.type == Enum.FurnitureType.FT_WALL_DECORATION then
    WorldRotation = nil
    if RoomPlane and not RoomPlane:IsWall() then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_ONLY_WALL)
      return false
    end
  elseif RoomPlane and RoomPlane:IsWall() then
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_ONLY_GROUND)
    return false
  end
  HomeIndoorSandbox:Ensure(RoomPlane, "cannot found plane in room", RoomId)
  if RoomPlane and not HomeIndoorSandbox:Ensure(RoomPlane.RoomId == RoomId, "need room's plane", RoomId, "but belong to", RoomId) then
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_OTHER_ROOM_HOME_PLANE)
    return false
  end
  if RoomPlane then
    local bEnable, NewLocalLocation = RoomPlane:JudgePlacePropsInWorld(WorldPosition, Config.cell_width, Config.cell_length)
    if bEnable then
      RoomPlane:DrawDebugProps(NewLocalLocation, Config.cell_width, Config.cell_length, 0, Config.place_cell_width, Config.place_cell_length)
      local RoomData = HomeIndoorSandbox.Server.WorldData:GetOrCreateRoomData(RoomId)
      local PropsData = RoomData:CreateDynamicPropsDataByConfig(Config, FurnitureData, RoomPlane, NewLocalLocation, ParentPropsData, WorldRotation)
      if HomeIndoorSandbox:Ensure(PropsData, "cannot create props data", Config.id, FurnitureData.BagItem.gid) then
        return HomeIndoorSandbox.HomePropsServ:DoDynamicSpawnProps(RoomId, PropsData)
      else
        self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_GUID)
      end
    else
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.SPAWN_FAILED_BY_INVALID_AREA)
    end
  else
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_NO_HOME_PLANE)
  end
  return false
end

function HomeEditService:OnPostLoad(PropsData, PropsActor, bFailed, bEditPlaneAreaInvalid)
  if bFailed then
    if bEditPlaneAreaInvalid then
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.SPAWN_FAILED_BY_INVALID_AREA, PropsData)
    else
      self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.SPAWN_FAILED, PropsData)
    end
  else
    self:InternalPlaceEditProps(PropsActor)
    self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.SPAWN_SUCCESS, PropsData)
  end
end

function HomeEditService:OnPropsResLoadFailed(PropsData)
  self:NotifyEditSpawnPropsStatus(HomeEnum.EnmEditPropsStatus.LOAD_FAILED, PropsData)
end

function HomeEditService:DisplayTipsBySpawnStatus(Status)
  if Status == HomeEnum.EnmEditPropsStatus.PROJECTILE_FAILED then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_placement_error)
  elseif Status == HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_MAX_NUM then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.furniture_num_max)
  elseif Status == HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_ESTABLISH then
  elseif Status == HomeEnum.EnmEditPropsStatus.PRE_CHECK_FAILED_EDIT_ONLY_ONE then
  elseif Status ~= HomeEnum.EnmEditPropsStatus.SPAWN_SUCCESS then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_placement_error)
  end
end

function HomeEditService:NotifyEditSpawnPropsStatus(Status, PropsData)
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnEditPropsStatusChanged, Status, PropsData)
  if not self.EditCreateItemInfoScreenPos then
    self:DisplayTipsBySpawnStatus(Status)
  end
end

function HomeEditService:TrySelectProps(ScreenPos, TouchRequirePropsData, bDisableSelectAnchorOffset)
  local TargetPropsActor
  HomeIndoorSandbox:LogDebug("ScreenPos=", ScreenPos)
  if not TouchRequirePropsData then
    if not HomeIndoorSandbox.HomePropsServ:IsRoomEstablished(self.EditRoomId) then
      return
    end
    local bEnable, ProjectilePropsActor = HomeIndoorSandbox.Utils.ProjectilePropsSelector(ScreenPos, self.TheSelectedPropsActor)
    if not bEnable then
      return
    end
    if not ProjectilePropsActor or ProjectilePropsActor.PropsData.RoomId ~= self.EditRoomId then
      return
    end
    TargetPropsActor = ProjectilePropsActor
  else
    TargetPropsActor = TouchRequirePropsData:ResolvePropsActor()
    if not TargetPropsActor or TargetPropsActor.PropsData ~= TouchRequirePropsData then
      HomeIndoorSandbox:Ensure(false, "logical error, require", TouchRequirePropsData, "but got", TargetPropsActor and TargetPropsActor.PropsData)
      return
    end
  end
  self.bStopSelectionMovement = false
  self:InternalSelectEditProps(TargetPropsActor, ScreenPos, TouchRequirePropsData, bDisableSelectAnchorOffset)
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnPlacedPropsSelected)
  return true
end

function HomeEditService:InternalSelectEditProps(ProjectilePropsActor, ScreenPos, TouchRequirePropsData, bDisableSelectAnchorOffset)
  self.TheSelectedPropsActor = ProjectilePropsActor
  self.TheSelectedPropsActor:SetIsSelected(true, TouchRequirePropsData or not ScreenPos)
  self.TheSelectedPropsScreenOffset = UE.FVector2D(0, 0)
  if ScreenPos and not bDisableSelectAnchorOffset then
    self.TheSelectedPropsScreenOffset = HomeIndoorSandbox.Utils.ProjectilePropsToScreen(self.TheSelectedPropsActor:Abs_K2_GetActorLocation()) - ScreenPos
  end
  local PlaceStatus = HomeIndoorSandbox.World.HomeEditEnv:ReqUsePlaceStatus()
  local Width, Length = ProjectilePropsActor.PropsData:GetSizeConfig()
  local PropsTransform = ProjectilePropsActor:Abs_GetTransform()
  local CellSizeScale = HomeIndoorSandbox.Utils.CELL_SIZE / 100
  PropsTransform.Scale3D = UE4.FVector(Length * CellSizeScale, Width * CellSizeScale, 1)
  PlaceStatus:Abs_K2_SetActorTransform_WithoutHit(PropsTransform)
  PlaceStatus:K2_AttachToActor(ProjectilePropsActor, nil, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, false)
  PlaceStatus:K2_AddActorLocalOffset(HomeIndoorSandbox.Utils.STATUS_ALIGN_OFFSET, false, nil, false)
  self:InternalUpdatePlaceStatus(not ScreenPos or not ProjectilePropsActor.PropsData.bTempData)
  HomeIndoorSandbox:LogDebug("ScreenPos= Offset=", self.TheSelectedPropsScreenOffset)
end

function HomeEditService:InternalPlaceEditProps(PropsActor)
  HomeIndoorSandbox:Ensure(PropsActor)
  self:InternalSelectEditProps(PropsActor)
end

function HomeEditService:InternalUpdatePlaceStatus(bMoveEnable)
  local bPlaceEnabled = bMoveEnable and self.TheSelectedPropsActor.PropsData.RealtimePlane:JudgePlaceEnabled(self.TheSelectedPropsActor)
  local PlaceStatus = HomeIndoorSandbox.World.HomeEditEnv:ReqUsePlaceStatus()
  PlaceStatus:SetPlaceEnabled(bPlaceEnabled)
  self.TheSelectedPropsActor.PropsData.bTempData = not bPlaceEnabled
  if bPlaceEnabled then
    self.TheSelectedPropsActor:SetHighLightOutlineColor(HomeEnum.Color_PlaceEnabled)
  else
    self.TheSelectedPropsActor:SetHighLightOutlineColor(HomeEnum.Color_PlaceDisabled)
  end
end

function HomeEditService:MoveSelectedProps(ScreenPos)
  if self.bStopSelectionMovement then
    return
  end
  if not self.TheSelectedPropsActor then
    return
  end
  local DesiredScreenPos = self.TheSelectedPropsScreenOffset + ScreenPos
  local PropsData = self.TheSelectedPropsActor.PropsData
  local FurnitureItemConf = PropsData.Conf
  local bEnable, HomePlane, WorldLocation, ParentPropsData = HomeIndoorSandbox.Utils.ProjectileProps(FurnitureItemConf, DesiredScreenPos, self.TheSelectedPropsActor)
  if bEnable then
    self.TheSelectedPropsActor:UseSpringArm(true)
    local RoomPlane = HomePlane
    if RoomPlane and RoomPlane.RoomId == self.EditRoomId then
      local bMoveEnable = RoomPlane:MovePlaceProps(self.TheSelectedPropsActor, WorldLocation, ParentPropsData)
      if bMoveEnable then
        self:InternalUpdatePlaceStatus(bMoveEnable)
      end
    end
  end
end

function HomeEditService:StopSelectProps()
  self.bStopSelectionMovement = true
  if self.TheSelectedPropsActor then
  end
end

function HomeEditService:InternalStopEditProps()
  if self.TheSelectedPropsActor then
    self.TheSelectedPropsActor:SetIsSelected(false)
    self.TheSelectedPropsActor = nil
  end
  self.bStopSelectionMovement = true
  HomeIndoorSandbox.World.HomeEditEnv:RecyclePlaceStatus()
end

function HomeEditService:RotationLatestProps()
  if self.TheSelectedPropsActor then
    local PropsData = self.TheSelectedPropsActor.PropsData
    local RoomPlane = PropsData.RealtimePlane
    local bPlaceSuccessAfterRotation = RoomPlane:RotatePlaceProps(self.TheSelectedPropsActor)
    self:InternalUpdatePlaceStatus(bPlaceSuccessAfterRotation)
  end
end

function HomeEditService:UnloadPackUpProps()
  if self.TheSelectedPropsActor then
    local PropsData = self.TheSelectedPropsActor.PropsData
    local AnyDynamicNpc = PropsData:AnyDynamicNpc()
    if AnyDynamicNpc then
      self:CancelPlaceProps()
      HomeIndoorSandbox:LogWarn("cannot unload furniture during edit:", PropsData.Id)
      HomeIndoorSandbox.HomeTipsServ:ShowUnloadPetFurnitureMessageBox()
      return
    end
    self:OnStopEditPropsActor()
    HomeIndoorSandbox.HomePropsServ:UnloadPackUpProps(PropsData)
    HomeIndoorSandbox.HomeTipsServ:ShowUnloadSucceedTips()
    self.RoomEditFlag[self.EditRoomId] = true
    HomeIndoorSandbox.World:GetRoomById(self.EditRoomId):MarkRoomPlaneDirty()
  end
end

function HomeEditService:UnLoadAllProps()
  if HomeIndoorSandbox:Ensure(not self.TheSelectedPropsActor, "selecting props, cannot unload all props by manager") and 0 ~= self.EditRoomId then
    local RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(self.EditRoomId)
    local PropsList = RoomData:GetNoDependencyPropsDataList()
    for i = #PropsList, 1, -1 do
      self:UnloadPackUpSpecifyProps(PropsList[i], true)
    end
    self.RoomEditFlag[self.EditRoomId] = true
    HomeIndoorSandbox.World:GetRoomById(self.EditRoomId):MarkRoomPlaneDirty()
  end
end

function HomeEditService:UnloadPackUpSpecifyProps(PropsData, bDisableMessageBox)
  if HomeIndoorSandbox:Ensure(not self.TheSelectedPropsActor, "selecting props, cannot unload props by manager") then
    local AnyDynamicNpc = PropsData:AnyDynamicNpc()
    if AnyDynamicNpc then
      HomeIndoorSandbox:LogWarn("cannot unload furniture:", PropsData.Id)
      if not bDisableMessageBox then
        HomeIndoorSandbox.HomeTipsServ:ShowUnloadPetFurnitureMessageBox()
      end
      return
    end
    HomeIndoorSandbox.HomePropsServ:UnloadPackUpProps(PropsData)
    HomeIndoorSandbox.HomeTipsServ:ShowUnloadSucceedTips()
    self.RoomEditFlag[self.EditRoomId] = true
  end
end

function HomeEditService:CancelPlaceProps()
  if self.TheSelectedPropsActor then
    self:OnStopEditPropsActor()
    self:RecoverRoomProps(self.EditRoomId)
  else
    self:OnStopEditPropsActor()
  end
end

function HomeEditService:ConfirmPlaceProps()
  if self.TheSelectedPropsActor then
    self:OnStopEditPropsActor()
    self:SaveRoomProps(self.EditRoomId)
    self.RoomEditFlag[self.EditRoomId] = true
    HomeIndoorSandbox.World:GetRoomById(self.EditRoomId):MarkRoomPlaneDirty()
  else
    self:OnStopEditPropsActor()
  end
end

function HomeEditService:ConfirmDecorate()
  if self.ThePreviewDecoData then
    HomeIndoorSandbox.Module.data:OnEditingApplyInteriorFinish(self.ThePreviewDecoData)
    self.ThePreviewDecoData = nil
    self:SaveRoomDeco(self.EditRoomId)
    self.RoomEditFlag[self.EditRoomId] = true
  end
end

function HomeEditService:CancelDecorate()
  if self.ThePreviewDecoData then
    self.ThePreviewDecoData = nil
    self:RecoverRoomDeco(self.EditRoomId)
  end
end

function HomeEditService:GetEditTask()
  return HomeIndoorSandbox.HomePropsServ:GetRoomDynamicSpawnTask(self.EditRoomId)
end

function HomeEditService:GetEditRoom()
  return HomeIndoorSandbox.World:GetRoomById(self.EditRoomId)
end

function HomeEditService:GetEditPropsActor()
  local Task = self:GetEditTask()
  if Task and Task:IsFinish() then
    return Task.PropsActor
  end
end

function HomeEditService:OnStopEditPropsActor()
  HomeIndoorSandbox.HomePropsServ:StopRoomDynamicSpawnTask(self.EditRoomId)
  self:InternalStopEditProps()
end

function HomeEditService:SwitchToEditRoom(RoomId)
  if self.EditRoomId == RoomId then
    return false
  end
  local Task = self:GetEditTask()
  if Task and not Task:IsFinish() then
    return false
  end
  if self.TheSelectedPropsActor then
    return false
  end
  if self.ThePreviewDecoData then
    return false
  end
  local Room = HomeIndoorSandbox.World:GetRoomById(RoomId)
  if not HomeIndoorSandbox:Ensure(Room, "cannot found room", RoomId) then
    return false
  end
  local ViewportLoc, ViewportRot, EditPointLoc, SpringArmLength, EditSocketOffset, EditViewportErr = Room:GetViewportInfo()
  if EditViewportErr then
    if _G.RocoEnv.IS_EDITOR then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, EditViewportErr)
    end
    return false
  end
  local OldRoomId = self.EditRoomId
  self.EditRoomId = RoomId
  HomeIndoorSandbox.World.HomeEditEnv:ReqUseControlCam(ViewportLoc, ViewportRot, EditPointLoc, SpringArmLength, EditSocketOffset)
  self:PostAdjustControlPawnLocation()
  local EditRoomInfo = self:GetEditRoom().RoomInfo
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.RefreshEditRoom, EditRoomInfo)
  HomeIndoorSandbox.HomePropsServ:CondLoadRoom(RoomId)
  HomeIndoorSandbox.World:RefreshRoomVisibility()
  HomeIndoorSandbox.World:RefreshControlNpcVisibility()
  self.EditContext:OnToggleRoom(OldRoomId, self.EditRoomId)
  return true
end

function HomeEditService:SwitchNextEditRoom()
  local RoomId = self.EditRoomId + 1
  if RoomId > HomeIndoorSandbox.World.MaxRoomId then
    RoomId = HomeIndoorSandbox.World.MinRoomId
  end
  self:SwitchToEditRoom(RoomId)
end

function HomeEditService:SwitchPrevEditRoom()
  local RoomId = self.EditRoomId - 1
  if RoomId < HomeIndoorSandbox.World.MinRoomId then
    RoomId = HomeIndoorSandbox.World.MaxRoomId
  end
  self:SwitchToEditRoom(RoomId)
end

function HomeEditService:PostAdjustControlPawnLocation()
  local ControlPawn = HomeIndoorSandbox.World.HomeEditEnv.ControlPawn
  local Bounds = self:GetEditRoomBounds()
  if ControlPawn and Bounds then
    local ControlRadius = HomeIndoorSandbox.World.HomeEditEnv.ControlRadius
    local Range = Bounds.Range
    local DesiredLoc = ControlPawn:Abs_K2_GetActorLocation()
    if Range > 2 * ControlRadius then
      if DesiredLoc.X < Bounds.Min.X + ControlRadius then
        DesiredLoc.X = Bounds.Min.X + ControlRadius
      end
      if DesiredLoc.X > Bounds.Max.X - ControlRadius then
        DesiredLoc.X = Bounds.Max.X - ControlRadius
      end
      if DesiredLoc.Y < Bounds.Min.Y + ControlRadius then
        DesiredLoc.Y = Bounds.Min.Y + ControlRadius
      end
      if DesiredLoc.Y > Bounds.Max.Y - ControlRadius then
        DesiredLoc.Y = Bounds.Max.Y - ControlRadius
      end
    else
      DesiredLoc = Bounds.Center
    end
    ControlPawn:Abs_K2_SetActorLocation(DesiredLoc, false, nil, false)
  end
end

function HomeEditService:GetEditRoomBounds()
  local Room = HomeIndoorSandbox.World:GetRoomById(self.EditRoomId)
  if Room then
    return Room.Bounds
  end
end

function HomeEditService:SaveAllRoom()
  if self.RoomEditFlag[self.EditRoomId] then
    self.RoomEditFlag[self.EditRoomId] = nil
    self:SaveRoomProps(self.EditRoomId)
    self:SaveRoomDeco(self.EditRoomId)
  end
  for RoomId, _ in pairs(self.RoomEditFlag) do
    self:SaveRoomProps(RoomId)
    self:SaveRoomDeco(RoomId)
  end
  self.RoomEditFlag = {}
end

function HomeEditService:RecoverAllRoom(bHasEditingProps, bHasEditingDecos, Callback)
  local NeedUploadRooms = {}
  if self.RoomEditFlag[self.EditRoomId] then
    self.RoomEditFlag[self.EditRoomId] = nil
    self:RecoverRoomProps(self.EditRoomId)
    self:RecoverRoomDeco(self.EditRoomId)
    table.insert(NeedUploadRooms, self.EditRoomId)
  else
    if bHasEditingProps then
      self:RecoverRoomProps(self.EditRoomId)
    end
    if bHasEditingDecos then
      self:RecoverRoomDeco(self.EditRoomId)
    end
  end
  for RoomId, _ in pairs(self.RoomEditFlag) do
    self:RecoverRoomProps(RoomId)
    self:RecoverRoomDeco(RoomId)
    table.insert(NeedUploadRooms, RoomId)
  end
  self.RoomEditFlag = {}
  if #NeedUploadRooms > 0 then
    self:ReqUploadRooms(NeedUploadRooms, Callback)
    self:StartEditCountDown()
  end
end

function HomeEditService:IsViolation()
  return HomeIndoorSandbox.Server.WorldData:IsViolation()
end

function HomeEditService:IfNeedUpload()
  return next(self.RoomEditFlag) and not next(self.RoomConfirmFlags)
end

function HomeEditService:HasEditDirty()
  return next(self.RoomEditFlag) or self.TheSelectedPropsActor or self.ThePreviewDecoData
end

function HomeEditService:UploadAllEditManually(Callback)
  if not self:InEditMode() then
    Callback(false, false)
    return
  end
  if not self:IfNeedUpload() then
    if self:IsViolation() and not next(self.RoomConfirmFlags) then
      HomeIndoorSandbox.HomeTipsServ:TryProcessHomeViolationDuringEditing()
    end
    Callback(false, false)
    return
  end
  local bHasEditingProps = self.TheSelectedPropsActor
  local bHasEditingDecos = self.ThePreviewDecoData
  self:OnStopEditPropsActor()
  self:RecoverAllRoom(bHasEditingProps, bHasEditingDecos, function(bSuccess)
    Callback(bSuccess, true)
  end)
  self.ThePreviewDecoData = nil
end

function HomeEditService:DiscardAllEdit()
  local bHasEditingProps = self.TheSelectedPropsActor
  local bHasEditingDecos = self.ThePreviewDecoData
  self:OnStopEditPropsActor()
  HomeIndoorSandbox.World:ReloadCacheWorldLayoutConditionally()
  local TempFlags = (HomeIndoorSandbox.Server.WorldData:GetRoomData(self.EditRoomId) or {}).TempFlags or {}
  if not TempFlags.bPropsChanged and bHasEditingProps then
    self:RecoverRoomProps(self.EditRoomId)
  end
  if not TempFlags.bDecosChanged and bHasEditingDecos then
    self:RecoverRoomDeco(self.EditRoomId)
  end
end

function HomeEditService:StartEditCountDown()
  local cdConf = DataConfigManager:GetHomeGlobalConfig("home_decoration_cd")
  self.EditExpiredTime = os.time() + (cdConf and cdConf.num or 0)
end

function HomeEditService:IsInEditCountDown()
  if os.time() < self.EditExpiredTime then
    HomeIndoorSandbox:DebugTips("\230\173\163\229\156\168\229\134\183\229\141\180\228\184\173...")
    return true
  end
  return false
end

function HomeEditService:StartPublishCountDown()
  local cdConf = DataConfigManager:GetHomeGlobalConfig("home_layout_release_CD")
  self.PublishExpiredTime = os.time() + (cdConf and cdConf.num or 0)
end

function HomeEditService:IsInPublishCountDown()
  if os.time() < self.PublishExpiredTime then
    HomeIndoorSandbox:DebugTips("\230\173\163\229\156\168\229\143\145\229\184\131\229\134\183\229\141\180\228\184\173...")
    return true
  end
  return false
end

function HomeEditService:ReqUploadRooms(NeedUploadRooms, Callback)
  for i, RoomId in ipairs(NeedUploadRooms) do
    if self.RoomConfirmFlags[RoomId] then
      HomeIndoorSandbox:Ensure(false, "logical error, upload duplicated room", RoomId)
    end
    HomeIndoorSandbox:LogInfo("upload room", RoomId)
    self.RoomConfirmFlags[RoomId] = true
  end
  local Serialize = HomeIndoorSandbox.Server.WorldData:Serialize()
  self.EditTaskMgr:EnQueTaskWithFeedback(HomeIndoorSandbox.TaskMgr.TaskModules.ProtoSendTask, FPartial(self.OnResUploadRooms, self, Callback, NeedUploadRooms), "ReqUploadRooms", NeedUploadRooms, false, Serialize)
end

function HomeEditService:OnResUploadRooms(Callback, NeedUploadRooms, bSuccess)
  for _, RoomId in ipairs(NeedUploadRooms) do
    self.RoomConfirmFlags[RoomId] = nil
  end
  if Callback then
    Callback(bSuccess)
  end
end

function HomeEditService:IsConfirmEstablished(RoomId)
  local Flag = self.RoomConfirmFlags[RoomId]
  if not Flag then
    return true
  end
  return false
end

function HomeEditService:RecoverRoomProps(RoomId)
  return HomeIndoorSandbox.HomePropsServ:RecoverRoomProps(RoomId)
end

function HomeEditService:RecoverRoomDeco(RoomId)
  return HomeIndoorSandbox.HomeDecoServ:RecoverRoomDeco(RoomId)
end

function HomeEditService:SaveRoomProps(RoomId)
  return HomeIndoorSandbox.HomePropsServ:SaveRoomProps(RoomId)
end

function HomeEditService:SaveRoomDeco(RoomId)
  return HomeIndoorSandbox.HomeDecoServ:SaveRoomDeco(RoomId)
end

function HomeEditService:ReqEnterEditMode()
  if self:InEditMode() then
    return
  end
  if self.bPendingEnterEditMode then
    HomeIndoorSandbox:LogWarn("[EDIT] bPendingEnterEditMode")
    return
  end
  HomeIndoorSandbox:LogInfo("ReqEnterEditMode")
  self.bPendingEnterEditMode = true
  self:OnInternalReqEnterEditMode()
end

function HomeEditService:OnEnterScene()
  self.bPendingEnterEditMode = false
end

function HomeEditService:OnInternalReqEnterEditMode()
  local function OnResEnterEditMode(bSuccess)
    return self:OnResEnterEditMode(bSuccess)
  end
  
  HomeIndoorSandbox.Server:ReqEnterEditMode(OnResEnterEditMode)
end

function HomeEditService:OnResEnterEditMode(bSuccess)
  if not self.bPendingEnterEditMode then
    HomeIndoorSandbox:LogWarn("[EDIT] not bPendingEnterEditMode")
    return
  end
  if not bSuccess then
    self.bPendingEnterEditMode = false
    HomeIndoorSandbox:LogWarn("enter edit mode but server forbid")
    return
  end
  if not HomeIndoorSandbox:InHomeIndoor() then
    self.bPendingEnterEditMode = false
    HomeIndoorSandbox:LogWarn("enter edit mode but not in home")
    return
  end
  Log.Debug("HomeEditService:OnResEnterEditMode", bSuccess)
  if HomeIndoorSandbox.Module:InPanelOpenForbiddenStatus() then
    return
  end
  HomeIndoorSandbox.Module:StartTransitionUI(function()
    if HomeIndoorSandbox:InLocalMasterIndoor() and self.bPendingEnterEditMode and HomeIndoorSandbox.World.HomeEditEnv:PreEnterCheck() then
      self.bPendingEnterEditMode = false
      HomeIndoorSandbox.Module:StopTransitionUI()
      HomeIndoorSandbox.Module:GetData():EvalCollectBagFurnitureItemInfo()
      HomeIndoorSandbox.World.Controller:OnEnter()
      HomeIndoorSandbox.Module:OpenPanel("Home")
    else
      self.bPendingEnterEditMode = false
      HomeIndoorSandbox.Module:StopTransitionUI()
    end
  end)
end

function HomeEditService:ReqExitEdit()
  if not self:InEditMode() then
    return
  end
  self.bPendingEnterEditMode = false
  HomeIndoorSandbox.World.Controller:OnExit()
  HomeIndoorSandbox.TaskMgr:EnQueTask(HomeIndoorSandbox.TaskMgr.TaskModules.ProtoSendTask, "ReqExitEditMode")
end

function HomeEditService:ToggleExpandPropsData(PropsData)
  if not PropsData then
    return
  end
  PropsData.bExpandedInManager = not PropsData.bExpandedInManager
  self.EditingPropsDataManagerMap[PropsData] = true
end

function HomeEditService:SetExpandPropsDataSelectedInManager(PropsData, bSelect)
  if not PropsData then
    return
  end
  PropsData.bInManagerSelected = bSelect
  self.EditingPropsDataManagerMap[PropsData] = true
end

function HomeEditService:ResetPropsDataInManager()
  if next(self.EditingPropsDataManagerMap) then
    for PropsData, _ in pairs(self.EditingPropsDataManagerMap) do
      PropsData.bExpandedInManager = false
      PropsData.bInManagerSelected = nil
    end
    self.EditingPropsDataManagerMap = {}
  end
end

function HomeEditService:ProcessPropsVisibilityChannel(PropsData, bInEditMode)
  HomeIndoorSandbox:LogDebug("ProcessPropsVisibilityChannel", PropsData:GetName(), PropsData.PropsActor, bInEditMode)
  if not PropsData.PropsActor then
    return
  end
  if bInEditMode then
    PropsData.PropsActor:SetVisibilityChannel(UE.ECollisionResponse.ECR_Overlap)
  else
    PropsData.PropsActor:SetVisibilityChannel(UE.ECollisionResponse.ECR_Block)
  end
end

return HomeEditService
