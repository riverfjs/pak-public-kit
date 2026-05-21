local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local HomeUtils = {}
HomeUtils.EnableDebugDraw = ENABLE_HOME_DEBUG_DRAW
HomeUtils.EnableDebugCreationScale = _G.RocoEnv.IS_EDITOR
HomeUtils.SELECT_HEIGHT = 20
HomeUtils.SELECT_LOCAL_OFFSET = UE.FVector(0, 0, HomeUtils.SELECT_HEIGHT)
HomeUtils.STATUS_ALIGN_OFFSET = UE.FVector(0, 0, -3)
HomeUtils.CELL_SIZE = 40
HomeUtils.HALF_CELL_SIZE = HomeUtils.CELL_SIZE / 2
HomeUtils.ROTATOR_ANGLE_ONCE = 90
HomeUtils.ROTATOR_ONCE = UE.FRotator(0, HomeUtils.ROTATOR_ANGLE_ONCE, 0)
HomeUtils.RotFlagToRotationMap = {
  [0] = UE.FRotator(0, 0, 0):ToQuat(),
  [1] = UE.FRotator(0, 90, 0):ToQuat(),
  [2] = UE.FRotator(0, 180, 0):ToQuat(),
  [3] = UE.FRotator(0, 270, 0):ToQuat()
}

local function GE(a, b, tolerance)
  tolerance = tolerance or 0.01
  return b < a or tolerance > math.abs(a - b)
end

local function EQ(a, b, tolerance)
  tolerance = tolerance or 0.01
  return a == b or tolerance > math.abs(a - b)
end

HomeUtils.GE = GE

function HomeUtils.AdjustBoxInPlane(LocalPosition, Width, Length, PlaneLocalMin, PlaneLocalMax)
  local NewX = HomeUtils.AdjustLineInPlane(LocalPosition.X, Length, PlaneLocalMin.X, PlaneLocalMax.X)
  local NewY = HomeUtils.AdjustLineInPlane(LocalPosition.Y, Width, PlaneLocalMin.Y, PlaneLocalMax.Y)
  return NewX, NewY
end

function HomeUtils.AdjustLineInPlane(Value, Range, Min, Max)
  local Offset = Value - Min
  local HalfRange = Range / 2 * HomeUtils.CELL_SIZE
  local Cell = math.floor(Offset / HomeUtils.CELL_SIZE)
  if 0 == Range % 2 then
    local Padding = Offset - Cell * HomeUtils.CELL_SIZE
    if Padding > HomeUtils.HALF_CELL_SIZE then
      Cell = Cell + 1
    end
    Offset = Cell * HomeUtils.CELL_SIZE
  else
    Offset = Cell * HomeUtils.CELL_SIZE + HomeUtils.HALF_CELL_SIZE
  end
  local LeftOffset = Offset - HalfRange
  if LeftOffset < 0 then
    Offset = HalfRange
  end
  local RightOffset = Offset + HalfRange
  local MinMaxRange = Max - Min
  if RightOffset > MinMaxRange then
    Offset = MinMaxRange - HalfRange
  end
  return Min + Offset
end

function HomeUtils.GetRotationByFlag(Flag)
  return HomeUtils.RotFlagToRotationMap[Flag % 4]
end

function HomeUtils.FBox_InverseTransformBy(Transform, Min, Max)
  local LocalMin = Transform:InverseTransformPositionNoScale(Min)
  local LocalMax = Transform:InverseTransformPositionNoScale(Max)
  local MinX = math.min(LocalMin.X, LocalMax.X)
  local MinY = math.min(LocalMin.Y, LocalMax.Y)
  local MinZ = math.min(LocalMin.Z, LocalMax.Z)
  local MaxX = math.max(LocalMin.X, LocalMax.X)
  local MaxY = math.max(LocalMin.Y, LocalMax.Y)
  local MaxZ = math.max(LocalMin.Z, LocalMax.Z)
  local MinPoint = UE4.FVector(MinX, MinY, MinZ)
  local MaxPoint = UE4.FVector(MaxX, MaxY, MaxZ)
  LocalMin = MinPoint
  LocalMax = MaxPoint
  return LocalMin, LocalMax
end

function HomeUtils.FBox_TransformBy(Transform, LocalMin, LocalMax)
  local WorldMin = Transform:TransformPositionNoScale(LocalMin)
  local WorldMax = Transform:TransformPositionNoScale(LocalMax)
  local MinX = math.min(WorldMin.X, WorldMax.X)
  local MinY = math.min(WorldMin.Y, WorldMax.Y)
  local MinZ = math.min(WorldMin.Z, WorldMax.Z)
  local MaxX = math.max(WorldMin.X, WorldMax.X)
  local MaxY = math.max(WorldMin.Y, WorldMax.Y)
  local MaxZ = math.max(WorldMin.Z, WorldMax.Z)
  local MinPoint = UE4.FVector(MinX, MinY, MinZ)
  local MaxPoint = UE4.FVector(MaxX, MaxY, MaxZ)
  WorldMin = MinPoint
  WorldMax = MaxPoint
  return WorldMin, WorldMax
end

function HomeUtils.JudgeAABBCollision(Location, Width, Length, Min, Max)
  if GE(Location.X - Length / 2, Max.X, 5) then
    return false
  end
  if GE(Location.Y - Width / 2, Max.Y, 5) then
    return false
  end
  if GE(Min.X, Location.X + Length / 2, 5) then
    return false
  end
  if GE(Min.Y, Location.Y + Width / 2, 5) then
    return false
  end
  return true
end

function HomeUtils.JudgeAABBCollisionWithResolve(X, Y, Width, Length, Min, Max)
  local bXCollision = false
  local bYCollision = false
  if GE(X - Length / 2, Max.X, 5) then
    return false
  else
    bXCollision = true
  end
  if GE(Min.X, X + Length / 2, 5) then
    return false
  else
    bXCollision = true
  end
  if GE(Y - Width / 2, Max.Y, 5) then
    return false
  else
    bYCollision = true
  end
  if GE(Min.Y, Y + Width / 2, 5) then
    return false
  else
    bYCollision = true
  end
  local DeltaX = bXCollision and HomeUtils.GetAlignValueInRange(X, Length, Min.X, Max.X) or 0
  local DeltaY = bYCollision and HomeUtils.GetAlignValueInRange(Y, Width, Min.Y, Max.Y) or 0
  if math.abs(DeltaX) < math.abs(DeltaY) then
    DeltaY = 0
  else
    DeltaX = 0
  end
  return true, X + DeltaX, Y + DeltaY
end

function HomeUtils.GetAlignValueInRange(Value, Range, Min, Max)
  Range = Range / 2
  local Offset = Min - (Value + Range)
  local Offset2 = Max - (Value - Range)
  if math.abs(Offset) < math.abs(Offset2) then
    return HomeUtils.GetAlignValue(Offset)
  else
    return HomeUtils.GetAlignValue(Offset2)
  end
end

function HomeUtils.GetAlignValue(Offset)
  local AbsOffset = math.abs(Offset)
  local Slice = math.floor(AbsOffset / HomeUtils.CELL_SIZE)
  if not EQ(Slice * HomeUtils.CELL_SIZE, AbsOffset, 5) then
    if Offset > 0 then
      Offset = (Slice + 1) * HomeUtils.CELL_SIZE
    else
      Offset = -(Slice + 1) * HomeUtils.CELL_SIZE
    end
  end
  return Offset
end

function HomeUtils.ProjectileNearPlane(Pos, Dir, Distance)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  local BegPos = Pos
  local EndPos = Pos + Dir * Distance
  local ObjectTypes = {
    UE.EObjectTypeQuery.WorldStatic,
    UE.EObjectTypeQuery.Visibility
  }
  local HitResults, bHit
  HitResults, bHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(Controller, BegPos, EndPos, ObjectTypes, false, {}, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 5)
  if bHit then
    for _, HitResult in tpairs(HitResults) do
      local Actor = HitResult.Actor
      if Actor and Actor.IsPlacePlane and Actor:IsPlacePlane() then
        return HitResult.Distance
      end
    end
  end
  return Distance
end

function HomeUtils.ProjectileProps(FurnitureItemConf, ScreenPos, MovingPropsActor)
  if not ScreenPos then
    local WinSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
    ScreenPos = WinSize / 2
  end
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  local CamLoc, CamDir = Controller:Abs_DeprojectScreenPositionToWorld(ScreenPos.X, ScreenPos.Y)
  local End = CamLoc + CamDir * 5000
  local ObjectTypes = {
    UE.EObjectTypeQuery.WorldStatic,
    UE.EObjectTypeQuery.Visibility
  }
  local ObjectsToIgnores = {
    Player.viewObj
  }
  local HitResults, bHit
  HitResults, bHit = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(Controller, CamLoc, End, UE.ETraceTypeQuery.Visibility, false, ObjectsToIgnores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 10)
  if bHit or HitResults and HitResults:Num() > 0 then
    local ParentPropsData
    for _, HitResult in tpairs(HitResults) do
      local Actor = HitResult.Actor
      if not Actor or Actor.bHidden then
      elseif Actor.PropsData then
        if FurnitureItemConf.type ~= Enum.FurnitureType.FT_SMALL_OENAMENT then
        elseif Actor.PropsData.RealtimeParentPropsData then
          goto lbl_151
        else
          local Min, Max = Actor:GetLocalGenPlaneMinMax()
          if Min and Max then
            ParentPropsData = Actor.PropsData
          end
        end
      else
        if Actor.IsPlacePlane and Actor:IsPlacePlane() then
          local HomePlane = Actor:GetHomePlane()
          if not HomePlane then
          else
            local bWallPlane = HomePlane:IsWall()
            local bWallProps = FurnitureItemConf.type == Enum.FurnitureType.FT_WALL_DECORATION
            if bWallPlane ~= bWallProps then
            else
              local Location = HitResult.Location
              local HitLocation = UE.FVector(Location.X, Location.Y, Location.Z)
              return true, HomePlane, HitLocation, ParentPropsData, CamDir
            end
          end
        else
        end
      end
      ::lbl_151::
    end
    if MovingPropsActor then
      if FurnitureItemConf.type == Enum.FurnitureType.FT_WALL_DECORATION then
        local HomePlane = MovingPropsActor.PropsData.RealtimePlane
        local Original = MovingPropsActor:Abs_K2_GetActorLocation()
        local Normal = MovingPropsActor:GetActorUpVector()
        local T, Intersection = UE.UKismetMathLibrary.LinePlaneIntersection_OriginNormal(CamLoc, End, Original, Normal)
        local NearProjectPoint = Intersection
        return true, HomePlane, NearProjectPoint, ParentPropsData or MovingPropsActor.PropsData.RealtimeParentPropsData, CamDir
      else
        local DesiredTraceClosestActor, DesiredTraceClosestHitPos
        for _, HitResult in tpairs(HitResults) do
          local Actor = HitResult.Actor
          if Actor and Actor.IsFloor and not Actor:IsFloor() then
            DesiredTraceClosestActor = Actor
            DesiredTraceClosestHitPos = HitResult.ImpactPoint
            break
          end
        end
        if DesiredTraceClosestActor then
          local Normal = DesiredTraceClosestActor:GetNormalByRoomId(MovingPropsActor.PropsData.RoomId)
          if not Normal then
            return false
          end
          local HomePlane = MovingPropsActor.PropsData.RealtimePlane
          local Original = DesiredTraceClosestHitPos
          local DotVal = Normal:Dot(CamDir)
          if DotVal > 0 then
            return false
          end
          local T, Intersection, bInteract = UE.UKismetMathLibrary.LinePlaneIntersection_OriginNormal(CamLoc, End, Original, Normal)
          local NearProjectPoint = Intersection
          if bInteract then
            return true, HomePlane, NearProjectPoint, ParentPropsData or MovingPropsActor.PropsData.RealtimeParentPropsData, CamDir
          end
        end
      end
    end
  end
end

function HomeUtils.ProjectJudgeRoom()
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player or type(Player) ~= "table" then
    return
  end
  local PlayerLocation = Player.viewObj:Abs_K2_GetActorLocation()
  local Controller = Player:GetUEController()
  local End = PlayerLocation - FVectorUp * 1000
  local ObjectTypes = {
    UE.EObjectTypeQuery.WorldStatic,
    UE.EObjectTypeQuery.WorldDynamic
  }
  local ObjectsToIgnores = {
    Player.viewObj
  }
  local HitResults, bHit
  HitResults, bHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(Controller, PlayerLocation, End, ObjectTypes, false, ObjectsToIgnores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 1)
  if bHit then
    for _, HitResult in tpairs(HitResults) do
      if HitResult.Actor.IsPlacePlane and HitResult.Component and HitResult.Component.StaticMesh then
        return HitResult.Actor:GetBelongRoomId()
      end
    end
  end
end

function HomeUtils.ProjectilePropsSelector(ScreenPos, DesiredEditProps)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  local CamLoc, CamDir = Controller:Abs_DeprojectScreenPositionToWorld(ScreenPos.X, ScreenPos.Y)
  local End = CamLoc + CamDir * 5000
  local ObjectsToIgnores = {
    Player.viewObj
  }
  local HitResults, bHit
  HitResults, bHit = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(Controller, CamLoc, End, UE.ETraceTypeQuery.Visibility, false, ObjectsToIgnores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 10)
  if bHit or HitResults and HitResults:Num() > 0 then
    if DesiredEditProps then
      for _, HitResult in tpairs(HitResults) do
        local Actor = HitResult.Actor
        if Actor == DesiredEditProps then
          return true, Actor
        end
      end
    else
      for _, HitResult in tpairs(HitResults) do
        local Actor = HitResult.Actor
        if Actor.PropsData then
          return true, Actor
        end
      end
    end
  end
  return false
end

function HomeUtils.ProjectilePropsToScreen(WorldPos)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  local ScreenPos = UE.FVector2D(0, 0)
  UE.UGameplayStatics.Abs_ProjectWorldToScreen(Controller, WorldPos, ScreenPos, false, true)
  return ScreenPos
end

function HomeUtils.NewGuid_UInt64(ExcludeSet)
  for i = 1, 1000 do
    local NewGuid = UE.UKismetGuidLibrary.NewGuid()
    local UniqueID = NewGuid.A << 32 | NewGuid.B
    if not ExcludeSet[UniqueID] then
      return UniqueID
    end
  end
  HomeIndoorSandbox:Ensure(false, "NewGuid_UInt64 failed")
end

local FLOOR_MAIN_TYPE_LIST = {
  UE.ENRCHomeInteriorFinishType.IFT_FLOOR
}
local WALL_MAIN_TYPE_LIST = {}
for i = UE.ENRCHomeInteriorFinishType.IFT_NONE, UE.ENRCHomeInteriorFinishType.IFT_MAX - 1 do
  table.insert(WALL_MAIN_TYPE_LIST, i)
end

function HomeUtils.GetSceneMainTypeListByConfigMainType(MainType)
  if MainType == Enum.InteriorFinishType.IFT_FLOOR then
    return FLOOR_MAIN_TYPE_LIST
  else
    return WALL_MAIN_TYPE_LIST
  end
end

function HomeUtils.GetConfigMainTypeBySceneMainType(MainType)
  if MainType == UE.ENRCHomeInteriorFinishType.IFT_FLOOR then
    return Enum.InteriorFinishType.IFT_FLOOR
  end
  return Enum.InteriorFinishType.IFT_WALL
end

function HomeUtils.GetSceneStyleIdByConfId(InteriorFinishConfId)
  return InteriorFinishConfId // 100 % 10000
end

function HomeUtils.LerpFov(PrevFov, TargetFov, DeltaTime)
  if DeltaTime > 0.0166 then
    local FovSpeed = (TargetFov - PrevFov) / DeltaTime
    local LerpTarget = PrevFov
    local RemainingTime = DeltaTime
    while RemainingTime > 1.0E-4 do
      local LerpDt = math.min(RemainingTime, 0.0166)
      LerpTarget = LerpTarget + FovSpeed * LerpDt
      RemainingTime = RemainingTime - LerpDt
      local f = math.clamp(LerpDt * 10, 0, 1)
      TargetFov = LerpTarget * f + (1 - f) * PrevFov
      PrevFov = TargetFov
    end
  else
    local f = math.clamp(DeltaTime * 10, 0, 1)
    TargetFov = TargetFov * f + (1 - f) * PrevFov
  end
  return TargetFov
end

function HomeUtils.CalcLocalMinMaxByBox(PlaneTransform, WorldLocation, Width, Length, WorldRotator)
  local LocalRotation = PlaneTransform:InverseTransformRotation(WorldRotator:ToQuat()):ToRotator()
  if LocalRotation.Yaw < 0 then
    LocalRotation.Yaw = LocalRotation.Yaw + 360
  end
  local RotFlag = math.floor(LocalRotation.Yaw / 90 + 0.5)
  local LocalLocation = PlaneTransform:InverseTransformPosition(WorldLocation)
  if 1 == RotFlag % 2 then
    local W = Width
    Width = Length
    Length = W
  end
  local HalfCellSize = HomeUtils.HALF_CELL_SIZE
  local Extent = UE.FVector(Length * HalfCellSize, Width * HalfCellSize, 0)
  local Max = LocalLocation + Extent
  local Min = LocalLocation - Extent
  return Min, Max
end

function HomeUtils.BuildFloorGraphByData(HomePlane)
  local RoomId = HomePlane.RoomId
  local RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId)
  if RoomData then
    local Graph = {}
    local PlaneMin = HomePlane.LocalMin
    local PlaneMax = HomePlane.LocalMax
    local SIZE = HomeUtils.CELL_SIZE
    
    local function GetRangeInGraph(Min, Max)
      local n = 0
      local m = 0
      if Max <= 5 then
        return 0, 0
      else
        m = math.floor(Max / SIZE)
        if not EQ(m * SIZE, Max, 5) then
          m = m + 1
        end
      end
      if Min > 5 then
        n = math.floor(Min / SIZE)
        if not EQ(n * SIZE, Min, 5) then
          n = n + 1
        end
      end
      return n, m - 1
    end
    
    local function InsertBox(Min, Max, Tag)
      local OffsetMin = Min - PlaneMin
      local OffsetMax = Max - PlaneMin
      local X0, X1 = GetRangeInGraph(OffsetMin.X, OffsetMax.X)
      local Y0, Y1 = GetRangeInGraph(OffsetMin.Y, OffsetMax.Y)
      for X = X0, X1 do
        for Y = Y0, Y1 do
          if not Graph[X] then
            Graph[X] = {}
          end
          Graph[X][Y] = Tag
        end
      end
      return X0, X1, Y0, Y1
    end
    
    InsertBox(PlaneMin, PlaneMax, 0)
    local EdgeCellCount = 2
    if #Graph > EdgeCellCount + 1 and #Graph[1] > EdgeCellCount + 1 then
      InsertBox(PlaneMin, UE.FVector(PlaneMin.X + EdgeCellCount * SIZE, PlaneMax.Y, 0), 3)
      InsertBox(PlaneMin, UE.FVector(PlaneMax.X, PlaneMin.Y + EdgeCellCount * SIZE, 0), 3)
      InsertBox(UE.FVector(PlaneMax.X - EdgeCellCount * SIZE, PlaneMin.Y, 0), PlaneMax, 3)
      InsertBox(UE.FVector(PlaneMin.X, PlaneMax.Y - EdgeCellCount * SIZE, 0), PlaneMax, 3)
    end
    for i, v in pairs(HomePlane.LocalInvalidAreas) do
      InsertBox(v.Min, v.Max, 2)
    end
    local PlaneTransform = HomePlane:Abs_GetTransform()
    local PropsId2PlaneGridInfo = {}
    for i, v in pairs(RoomData.NoDependencyPropsDataList) do
      if v.PlaneMasterId == HomePlane.PlaneMasterId and v:GetTypeEnum() ~= Enum.FurnitureType.FT_CARPET then
        if v:IsValidConfig() then
          local Width, Length = v:GetSizeConfig()
          local Min, Max = HomeUtils.CalcLocalMinMaxByBox(PlaneTransform, v.Location, Width, Length, v.Rotator)
          local X0, X1, Y0, Y1 = InsertBox(Min, Max, 1)
          PropsId2PlaneGridInfo[v.Id] = {
            X0,
            X1,
            Y0,
            Y1
          }
          Log.Debug("CalcLocalMinMaxByBox", v.Location, Width, Length, Min, Max, X0, X1, Y0, Y1)
        else
          Log.Error("Invalid furniture conf", v.ConfId)
        end
      end
    end
    return Graph, PropsId2PlaneGridInfo
  end
end

function HomeUtils.DeepEquals(a, b, visited, comparator, ignoreNil)
  if nil == a then
    a = {}
  end
  if nil == b then
    b = {}
  end
  visited = visited or {}
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    if comparator and type(comparator) == "function" then
      return comparator(a, b)
    end
    return a == b
  end
  if visited[a] and visited[a] == b then
    return true
  end
  visited[a] = b
  for k, v in pairs(a) do
    if (not ignoreNil or not ignoreNil[k]) and not HomeUtils.DeepEquals(v, b[k], visited, comparator and type(comparator) == "table" and comparator[k] or comparator, ignoreNil) then
      return false
    end
  end
  for k, v in pairs(b) do
    if (not ignoreNil or not ignoreNil[k]) and nil == a[k] then
      return false
    end
  end
  return true
end

local NORMALS = {
  [UE.ENRCHomeBuildingFaceType.Up] = UE.FVector(0, 0, 1),
  [UE.ENRCHomeBuildingFaceType.Down] = UE.FVector(0, 0, -1),
  [UE.ENRCHomeBuildingFaceType.Left] = UE.FVector(0, 1, 0),
  [UE.ENRCHomeBuildingFaceType.Right] = UE.FVector(0, -1, 0),
  [UE.ENRCHomeBuildingFaceType.Forward] = UE.FVector(1, 0, 0),
  [UE.ENRCHomeBuildingFaceType.Backward] = UE.FVector(-1, 0, 0)
}

function HomeUtils.GetFaceNormalByType(FaceType)
  return NORMALS and NORMALS[FaceType]
end

function HomeUtils.CapsuleTraceObstacleObjects(DesiredPos, AdditionExtentRadius)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player or not Player.viewObj then
    return {}
  end
  local CapsuleComponent = Player.viewObj.CapsuleComponent
  local PlayerLocation = DesiredPos or Player:GetActorLocation()
  local ObstacleExtent = 0
  local ObstacleRadius = CapsuleComponent:GetScaledCapsuleRadius() + ObstacleExtent + (AdditionExtentRadius or -10)
  local ObstacleOffset = UE4.FVector(0, 0, ObstacleExtent)
  local ObstacleHeight = CapsuleComponent:GetScaledCapsuleHalfHeight() + ObstacleExtent
  local ObstacleTypes = {
    UE.EObjectTypeQuery.WorldDynamic
  }
  local UnderOffset = UE4.FVector(0, 0, 0)
  local HitResults, bHit = UE.UKismetSystemLibrary.Abs_CapsuleTraceMultiForObjects(UE4Helper.GetCurrentWorld(), PlayerLocation + ObstacleOffset, PlayerLocation + UnderOffset, ObstacleRadius, ObstacleHeight, ObstacleTypes, false, {
    Player.viewObj
  }, HomeUtils.EnableDebugDraw and UE4.EDrawDebugTrace.ForOneFrame or UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 1)
  local IgnoreObstacles = {}
  local IgnoreFurnitureList = {}
  if bHit or HitResults and HitResults:Num() > 0 then
    for _, HitResult in tpairs(HitResults) do
      local PropsActor = HitResult.Actor
      if PropsActor.PropsData then
        if PropsActor.PropsData:GetTypeEnum() ~= Enum.FurnitureType.FT_CARPET then
          IgnoreObstacles[PropsActor] = true
        else
          table.insert(IgnoreFurnitureList, PropsActor)
        end
      end
    end
  end
  return IgnoreObstacles
end

function HomeUtils.CapsuleTraceValidPos(DesiredPos, AdditionExtentRadius, FurnitureView)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player or not Player.viewObj then
    return false
  end
  local CapsuleComponent = Player.viewObj.CapsuleComponent
  local PlayerLocation = DesiredPos or Player:GetActorLocation()
  local ObstacleExtent = 10
  local MoreHalfHeight = 25
  local ObstacleRadius = CapsuleComponent:GetScaledCapsuleRadius() + ObstacleExtent + (AdditionExtentRadius or -10)
  local ObstacleOffset = UE4.FVector(0, 0, ObstacleExtent)
  local ObstacleHeight = CapsuleComponent:GetScaledCapsuleHalfHeight() + ObstacleExtent + MoreHalfHeight
  local ObstacleTypes = {
    UE.EObjectTypeQuery.Character,
    UE.EObjectTypeQuery.Pawn,
    UE.EObjectTypeQuery.WorldDynamic,
    UE.EObjectTypeQuery.WorldStatic
  }
  local UnderOffset = UE4.FVector(0, 0, 0)
  ObstacleOffset = UE4.FVector(0, 0, 50)
  UnderOffset = UE4.FVector(0, 0, -50)
  local OutComponents = UE.TArray(UE.UMeshComponent)
  UE.UKismetSystemLibrary.Abs_CapsuleOverlapComponents(UE4Helper.GetCurrentWorld(), PlayerLocation + UnderOffset, ObstacleRadius, ObstacleHeight, ObstacleTypes, UE.UMeshComponent, {
    Player.viewObj,
    FurnitureView
  }, OutComponents)
  local bHasFloor = false
  for i, Component in tpairs(OutComponents) do
    local Actor = Component:GetOwner()
    if Actor and Actor then
      if Actor.PropsData and Actor.PropsData:GetTypeEnum() ~= Enum.FurnitureType.FT_CARPET then
        HomeIndoorSandbox:LogDebug("Collision Props", Actor:GetName(), PlayerLocation)
        return false
      end
      if Actor.IsFloor then
        if not Actor:IsFloor() then
          HomeIndoorSandbox:LogDebug("Collision Building", Actor:GetName(), PlayerLocation)
          return false
        else
          bHasFloor = true
        end
      end
    end
  end
  return bHasFloor
end

function HomeUtils.EqualsObstacleObjects(A, B)
  if A == B then
    return true
  end
  if not A or not B then
    return false
  end
  for k, v in pairs(A) do
    if B[k] then
      B[k] = nil
      A[k] = nil
    end
  end
  if not next(A) and not next(B) then
    return true
  end
  return false
end

function HomeUtils.ShouldAiTreatLikeFriendByPlayer(player)
  if not player then
    return false
  end
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox.HomeAIServ then
    local AIServ = _G.HomeIndoorSandbox.HomeAIServ
    if player.isLocal then
      return AIServ.InFriendsHome or AIServ.InMyHome
    elseif AIServ.MasterUid == player:GetLogicId() then
      return true
    end
  end
  return false
end

function HomeUtils.GetPropDataById(Guid)
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox.Server then
    local ServerData = _G.HomeIndoorSandbox.Server.WorldData
    if ServerData then
      for _, room in pairs(ServerData.RoomDataMap) do
        local prop = room.PropsDataMap[Guid]
        if prop then
          return prop
        end
      end
    end
  end
  return nil
end

function HomeUtils.GetHomePetAdditionalInfo(gid)
  local homePetList = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo)
  if not homePetList or 0 == #homePetList then
    Log.Error("No pet in home now")
    return nil
  end
  local additionalInfo = {}
  for _, npcInfo in ipairs(homePetList) do
    if npcInfo.home_pet and gid == npcInfo.home_pet.home_pet_info.pet_gid then
      additionalInfo = {
        name = npcInfo.home_pet and npcInfo.home_pet.home_pet_info.name or "",
        base_conf_id = npcInfo.home_pet and npcInfo.home_pet.home_pet_info.pet_cfg_id or 0,
        mutation_type = npcInfo.npc_base and npcInfo.npc_base.mutation_type or 0,
        glass_info = npcInfo.npc_base and npcInfo.npc_base.glass_info or nil,
        gender = npcInfo.base and npcInfo.base.gender or 1
      }
      break
    end
  end
  return additionalInfo
end

function HomeUtils.GetDisplayHomePetInfo(homeInfo)
  local homePetInfos = {}
  local playerHomeInfos = {}
  local minRemainRate = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_left_steal_max").num / 10000
  
  local function couldGetOrSteal(singlePetInfo)
    if not singlePetInfo.awards_info or not singlePetInfo.awards_info.goods_infos then
      return false
    end
    if HomeIndoorSandbox:InLocalMasterIndoor() then
      if singlePetInfo.awards_info.goods_infos and #singlePetInfo.awards_info.goods_infos > 0 then
        for _, goodInfo in ipairs(singlePetInfo.awards_info.goods_infos) do
          if goodInfo.goods_num > 0 then
            return true
          end
        end
      end
      return false
    elseif HomeIndoorSandbox:InOtherHomeIndoor() then
      if singlePetInfo.awards_info.goods_infos and #singlePetInfo.awards_info.goods_infos > 0 then
        for _, goodInfo in ipairs(singlePetInfo.awards_info.goods_infos) do
          if goodInfo.goods_num > goodInfo.goods_total_num * minRemainRate then
            return true
          end
        end
      end
      return false
    end
  end
  
  if homeInfo and homeInfo.home_pets and #homeInfo.home_pets > 0 then
    playerHomeInfos = homeInfo.home_pets
    for _, v in ipairs(playerHomeInfos) do
      if v and v.home_pet_info and v.home_pet_info.status ~= _G.ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD then
        table.insert(homePetInfos, {
          pet_gid = v.home_pet_info.pet_gid,
          furniture_guid = v.home_pet_info.furniture_guid,
          status = v.home_pet_info.status,
          feed_info = v.home_pet_info.feed_info,
          awards_info = v.home_pet_info.awards_info,
          bShowRedPoint = v.can_steal,
          have_egg = v.have_egg,
          mutation_type = v.display_info and v.display_info.mutation_type or nil,
          glass_info = v.display_info and v.display_info.glass_info or nil,
          base_conf_id = v.display_info and v.display_info.base_conf_id or nil
        })
      end
    end
  elseif homeInfo and "table" == type(homeInfo) and #homeInfo > 0 then
    for _, v in ipairs(homeInfo) do
      if v and v.home_pet and v.home_pet.home_pet_info.status ~= _G.ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD then
        table.insert(homePetInfos, {
          pet_gid = v.home_pet.home_pet_info.pet_gid,
          furniture_guid = v.home_pet.home_pet_info.furniture_guid,
          status = v.home_pet.home_pet_info.status,
          feed_info = v.home_pet.home_pet_info.feed_info,
          awards_info = v.home_pet.home_pet_info.awards_info,
          bShowRedPoint = couldGetOrSteal(v.home_pet.home_pet_info),
          mutation_type = v.npc_base.mutation_type,
          glass_info = v.npc_base.glass_info,
          base_conf_id = v.home_pet.home_pet_info.pet_cfg_id
        })
      end
    end
  end
  return homePetInfos
end

function HomeUtils.GetHomePetTimer(feedInfo)
  if not feedInfo then
    return nil
  end
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  local beginTime = feedInfo.begin_time / 1000 / 1000
  local costTime = feedInfo.time_cost / 1000 / 1000
  local remainTime = costTime - (curTime - beginTime)
  local remainDay, remainHour, remainMinute, remainSec = 0
  if remainTime >= 0 then
    remainDay = math.floor(remainTime // 86400)
    remainHour = math.floor((remainTime - remainDay * 86400) // 3600)
    remainMinute = math.floor((remainTime - remainDay * 86400 - remainHour * 3600) // 60)
    remainSec = math.floor(remainTime - remainDay * 86400 - remainHour * 3600 - remainMinute * 60)
  end
  return {
    remainDay,
    remainHour,
    remainMinute,
    remainSec
  }
end

function HomeUtils.PlayerInInteractArea(PlayerPos, FurnitureNPC)
  local SenseExtent = FurnitureNPC.SenseExtent
  if next(SenseExtent) then
    for Pos, Extent in pairs(SenseExtent) do
      if UE.UKismetMathLibrary.IsPointInBox(PlayerPos, Pos, Extent) then
        if FurnitureNPC.SenseDisable[Pos] then
          return
        end
        local ResultArray = UE.TArray(UE.AActor)
        local Result = UE.UKismetSystemLibrary.Abs_BoxOverlapActors(_G.UE4Helper.GetCurrentWorld(), Pos, Extent, nil, nil, {
          FurnitureNPC.viewObj
        }, ResultArray)
        if Result and ResultArray:Length() > 0 then
          for _, Actor in tpairs(ResultArray) do
            if Actor.PropsData then
              FurnitureNPC.SenseDisable[Pos] = true
              return false
            end
          end
        end
        FurnitureNPC.SenseDisable[Pos] = false
        return true
      end
    end
  end
end

function HomeUtils.CanSitDownOnSeat(PlayerPos, FurnitureNpc, FurnitureView, AvailableData)
  local SeatIdx = HomeUtils.FindNearestSeatIndex(PlayerPos, FurnitureView, AvailableData)
  if not SeatIdx then
    return
  end
  local SeatInfo = FurnitureNpc.serverData.npc_interact.seat_info
  if SeatInfo and SeatInfo.seat_info and SeatInfo.seat_info[SeatIdx] then
    return 0 == SeatInfo.seat_info[SeatIdx].interact_avatar_id
  end
  return true
end

function HomeUtils.FindNearestSeatIndex(PlayerPos, FurnitureView, AvailableData)
  local WorldTransform = FurnitureView:Abs_GetTransform()
  if not WorldTransform then
    return
  end
  local SeatWorldPos, Distance, MinDistance, SeatIdx
  for i, Data in tpairs(AvailableData) do
    SeatWorldPos = WorldTransform:TransformPositionNoScale(Data.Location)
    Distance = UE4.UKismetMathLibrary.Vector_Distance2DSquared(SeatWorldPos, PlayerPos)
    if not MinDistance then
      MinDistance = Distance
      SeatIdx = i
    elseif Distance < MinDistance then
      MinDistance = Distance
      SeatIdx = i
    end
  end
  if SeatIdx then
    return SeatIdx
  end
end

function HomeUtils.PlayerSitToHomeSeat(Player, FurnitureView, Index, bIsBed)
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local WorldTransform = FurnitureView:Abs_GetTransform()
  if not WorldTransform then
    return
  end
  local Data = AvailableData:Get(Index)
  if not Data then
    return
  end
  local Position = WorldTransform:TransformPositionNoScale(Data.Location)
  local Direction = WorldTransform:TransformRotation(Data.Rotation:ToQuat()):GetForwardVector()
  Direction.Z = 0
  Direction:Normalize()
  local FloorHeight = Data.Location.Z
  if Player and Player.playerHomeInteractionComponent then
    HomeIndoorSandbox.World:ToggleGroundFurnitureCameraCollision(false)
    if bIsBed then
      Player.playerHomeInteractionComponent:StartLie(Position, Direction)
    else
      Player.playerHomeInteractionComponent:StartSit(Position, Direction, FloorHeight)
    end
  end
end

function HomeUtils.PlayerLeaveHomeSeat(Player, FurnitureView, ExitIndex, bIsBed)
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local ExitData = InteractData.ExitData
  if not ExitData then
    return
  end
  local WorldTransform = FurnitureView:Abs_GetTransform()
  if not WorldTransform then
    return
  end
  local Data = ExitData:Get(ExitIndex)
  if not Data then
    return
  end
  local Position = WorldTransform:TransformPositionNoScale(Data.Location)
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local SitIndex = Player.serverData.avatar_interact.sit_info.seat_idx
  local SitData = AvailableData:Get(SitIndex + 1)
  local SitPos = WorldTransform:TransformPositionNoScale(SitData.Location)
  local Direction = Position - SitPos
  Direction.Z = 0
  Direction:Normalize()
  if Player and Player.playerHomeInteractionComponent then
    HomeIndoorSandbox.World:ToggleGroundFurnitureCameraCollision(true)
    if bIsBed then
      HomeIndoorSandbox:LogDebug("HOME INTERACT EndLie", Position)
      Player.playerHomeInteractionComponent:EndLie(Position, Direction)
    else
      local FloorHeight = SitData.Location.Z
      HomeIndoorSandbox:LogDebug("HOME INTERACT EndSit", SitPos)
      Player.playerHomeInteractionComponent:EndSit(SitPos, Direction, FloorHeight)
    end
  end
end

function HomeUtils.PlayerChangeHomeSeat(Player, FurnitureView, Index)
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local WorldTransform = FurnitureView:Abs_GetTransform()
  if not WorldTransform then
    return
  end
  local Data = AvailableData:Get(Index)
  if not Data then
    return
  end
  local Position = WorldTransform:TransformPositionNoScale(Data.Location)
  if Player and Player.playerHomeInteractionComponent then
    Player.playerHomeInteractionComponent:ChangeLiePosition(Position)
  end
end

function HomeUtils.FindValidExitPosForSeat(FurnitureNPC, FurnitureView)
  local ValidPoint = FurnitureNPC.ValidExitPoint
  if ValidPoint then
    return ValidPoint
  end
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local ExitData = InteractData.ExitData
  if not ExitData then
    return
  end
  local WorldTransform = FurnitureView:Abs_GetTransform()
  if not WorldTransform then
    return
  end
  for i, _Data in tpairs(ExitData) do
    local Pos = WorldTransform:TransformPositionNoScale(_Data.Location)
    if _G.HomeIndoorSandbox.World:TestPlayerLandPosIsValid(Pos, FurnitureView) then
      HomeIndoorSandbox:LogDebug("HOME INTERACT TestPlayerLandPosIsValid", Pos)
      FurnitureNPC.ValidExitPoint = i
      break
    end
    FurnitureNPC.ValidExitPoint = -1
  end
  return FurnitureNPC.ValidExitPoint
end

function HomeUtils.PlayerInterruptSceneSeat(Player, bIsBed)
  if Player and Player.playerHomeInteractionComponent then
    HomeIndoorSandbox.World:ToggleGroundFurnitureCameraCollision(true)
    if bIsBed then
      Player.playerHomeInteractionComponent:InterruptLie()
    else
      Player.playerHomeInteractionComponent:InterruptSit()
    end
  end
end

function HomeUtils.IsPetHasBeenSteal(petGid)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.serverData then
    local petStealList = player.serverData.steal_home_info and player.serverData.steal_home_info.steal_of_home_pets
    if petStealList and type(petStealList) == "table" and #petStealList > 0 then
      for _, stealPetInfo in ipairs(petStealList) do
        if stealPetInfo.pet_gid and stealPetInfo.pet_gid == petGid then
          return true
        end
      end
    end
  end
  return false
end

function HomeUtils.EnsureHomeNpcComponents(SceneNpc, Furniture)
  if not SceneNpc then
    return
  end
  if not HomeIndoorSandbox then
    return
  end
  local actorId = SceneNpc.serverData.base.actor_id
  local furniture = Furniture or HomeIndoorSandbox.Server.WorldData:GetFurnitureByNpcId(actorId)
  if not furniture then
    return
  end
  Log.Debug("EnsureHomeNpcComponents", actorId, furniture.RoomId, furniture.Id)
  SceneNpc:EnsureComponent(HomeNpcInfoComponent, actorId, furniture.Id)
end

return HomeUtils
