local HomePlane = Class("HomePlane")

function HomePlane:Ctor(WorldCenter, RoomId, PlaneId, Min, Max, Rotator, InvalidAreas, PlaneMasterId)
  self.WorldCenter = WorldCenter
  self.RoomId = RoomId
  self.PlaneId = PlaneId
  self.Min = Min
  self.Max = Max
  self.InvalidAreas = InvalidAreas
  self.PlaneMasterId = PlaneMasterId
  self.Rotator = Rotator
  self.LocalMin = nil
  self.LocalMax = nil
  self.LocalInvalidAreas = {}
  self.bVisible = false
  self.PropsDataSet = {}
  self.NoDependencyProps = {}
  self.bCellDirty = true
  self.CellGraph = nil
  self.CellGraphIndices = nil
  self:InternalLocalMinMax()
  self:InternalLocalInvalidAreas()
  self:DebugDraw()
end

function HomePlane:SetVisible(bVisible, bForce)
  HomeIndoorSandbox:LogInfo("[Visibility] HomePlane:SetVisible", bVisible, self.bVisible, "Force:", bForce)
  if bVisible ~= self.bVisible or bForce then
    self.bVisible = bVisible
    for Data, Actor in pairs(self.PropsDataSet) do
      if UE.UObject.IsValid(Actor) then
        Actor:SetVisible(bVisible)
      end
    end
  end
end

function HomePlane:SetPropsCameraCollisionEnabled(bEnabled)
  for Data, Actor in pairs(self.PropsDataSet) do
    if UE.UObject.IsValid(Actor) then
      Actor:SetCameraCollisionEnabled(bEnabled)
    end
  end
end

function HomePlane:DebugDraw()
  if self:IsWall() then
    return
  end
  if not HomeIndoorSandbox.Utils.EnableDebugDraw then
    return
  end
  local VerifyMin, VerifyMax = HomeIndoorSandbox.Utils.FBox_TransformBy(self:Abs_GetTransform(), self.LocalMin, self.LocalMax)
  self:DrawDebugBox(VerifyMin, VerifyMax, FVectorZero, UE4.FLinearColor(0, 1, 0, 1), 6, true)
  for i, InvalidArea in ipairs(self.LocalInvalidAreas) do
    VerifyMin, VerifyMax = HomeIndoorSandbox.Utils.FBox_TransformBy(self:Abs_GetTransform(), InvalidArea.Min, InvalidArea.Max)
    self:DrawDebugBox(VerifyMin, VerifyMax, UE.FVector(0, 0, i), UE4.FLinearColor(math.random(), 0, math.random(), 1))
  end
end

function HomePlane:DrawDebugBox(Min, Max, Up, Color, Thickness, bEnableExtent, Duration)
  if not HomeIndoorSandbox.Utils.EnableDebugDraw then
    return
  end
  local RightVector = UE.UKismetMathLibrary.GetRightVector(self.Rotator)
  local ForwardVector = UE.UKismetMathLibrary.GetForwardVector(self.Rotator)
  local MinToMax = Max - Min
  local Y = RightVector
  local X = ForwardVector
  if MinToMax:Dot(RightVector) < 0 then
    Y = -RightVector
  end
  if MinToMax:Dot(ForwardVector) < 0 then
    X = -ForwardVector
  end
  X = UE.UKismetMathLibrary.ProjectVectorOnToVector(MinToMax, X)
  Y = UE.UKismetMathLibrary.ProjectVectorOnToVector(MinToMax, Y)
  local T0 = Min + X
  local T1 = Min + Y
  self:DrawDebugLine(Min, T0, Up, Color, Thickness, Duration)
  self:DrawDebugLine(T0, Max, Up, Color, Thickness, Duration)
  self:DrawDebugLine(Min, T1, Up, Color, Thickness, Duration)
  self:DrawDebugLine(T1, Max, Up, Color, Thickness, Duration)
  if bEnableExtent then
    self:DrawDebugLine(Min, Max, Up, Color, Thickness, Duration)
  end
end

function HomePlane:DrawDebugLine(P0, P1, Up, Color, Thickness, Duration)
  UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), P0 + Up, P1 + Up, Color, Duration or 1000, Thickness or 5)
end

function HomePlane:DrawDebugArrow(P0, P1, Up, Color, Thickness, Duration, ArrowSize)
  UE4.UKismetSystemLibrary.Abs_DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), P0 + Up, P1 + Up, ArrowSize or 5, Color, Duration or 1000, Thickness or 5)
end

function HomePlane:DrawDebugProps(DesiredLocalLocation, Width, Length, RotFlag)
  if not HomeIndoorSandbox.Utils.EnableDebugDraw then
    return
  end
  if 1 == RotFlag % 2 then
    local W = Width
    Width = Length
    Length = W
  end
  Width = HomeIndoorSandbox.Utils.CELL_SIZE * Width
  Length = HomeIndoorSandbox.Utils.CELL_SIZE * Length
  local DesiredWorldLocation = self:Abs_GetTransform():TransformPosition(DesiredLocalLocation)
  local RightVector = UE.UKismetMathLibrary.GetRightVector(self.Rotator)
  local ForwardVector = UE.UKismetMathLibrary.GetForwardVector(self.Rotator)
  local UpVector = UE.UKismetMathLibrary.GetUpVector(self.Rotator)
  local PropsRightVec = RightVector * Width / 2
  local PropsForwardVec = ForwardVector * Length / 2
  local T0 = DesiredWorldLocation + PropsRightVec + PropsForwardVec
  local T1 = DesiredWorldLocation + PropsRightVec - PropsForwardVec
  local T2 = DesiredWorldLocation - PropsRightVec - PropsForwardVec
  local T3 = DesiredWorldLocation - PropsRightVec + PropsForwardVec
  local Yellow = UE.FLinearColor(1, 1, 0, 1)
  self:DrawDebugLine(T0, T1, UpVector, Yellow, 5, 3)
  self:DrawDebugLine(T1, T2, UpVector, Yellow, 5, 3)
  self:DrawDebugLine(T2, T3, UpVector, Yellow, 5, 3)
  self:DrawDebugLine(T3, T0, UpVector, Yellow, 5, 3)
end

function HomePlane:DrawDebugGeneratePlane(PropsActor)
  local Min, Max = PropsActor:GetLocalGenPlaneMinMax()
  if Min then
    Min = PropsActor:Abs_GetTransform():TransformPosition(Min)
    Max = PropsActor:Abs_GetTransform():TransformPosition(Max)
    local Rotator = PropsActor:K2_GetActorRotation()
    local RightVector = UE.UKismetMathLibrary.GetRightVector(Rotator)
    local ForwardVector = UE.UKismetMathLibrary.GetForwardVector(Rotator)
    local MinToMax = Max - Min
    local Y = RightVector
    local X = ForwardVector
    if MinToMax:Dot(RightVector) < 0 then
      Y = -RightVector
    end
    if MinToMax:Dot(ForwardVector) < 0 then
      X = -ForwardVector
    end
    X = UE.UKismetMathLibrary.ProjectVectorOnToVector(MinToMax, X)
    Y = UE.UKismetMathLibrary.ProjectVectorOnToVector(MinToMax, Y)
    local T0 = Min + X
    local T1 = Min + Y
    local Up = UE.FVector(0, 0, 20)
    local Color = UE.FLinearColor(0, 1, 0, 1)
    self:DrawDebugLine(Min, T0, Up, Color, 3, 3)
    self:DrawDebugLine(T0, Max, Up, Color, 3, 3)
    self:DrawDebugLine(Min, T1, Up, Color, 3, 3)
    self:DrawDebugLine(T1, Max, Up, Color, 3, 3)
    local CellSize = HomeIndoorSandbox.Utils.CELL_SIZE
    local TmpX = UE.FVector(X.X, 0, 0)
    while CellSize < X.X do
      X.X = X.X - CellSize
      T0 = Min + X
      T1 = T0 + Y
      self:DrawDebugLine(T0, T1, Up, Color, 3, 3)
    end
    while CellSize < Y.Y do
      Y.Y = Y.Y - CellSize
      T1 = Min + Y
      T0 = T1 + TmpX
      self:DrawDebugLine(T0, T1, Up, Color, 3, 3)
    end
  end
end

function HomePlane:IsWall()
  if math.abs(self.Min.Z - self.Max.Z) > 5 then
    return true
  end
  return false
end

function HomePlane:InternalLocalMinMax()
  local Min, Max = HomeIndoorSandbox.Utils.FBox_InverseTransformBy(self:Abs_GetTransform(), self.Min, self.Max)
  self.LocalMin = Min
  self.LocalMax = Max
end

function HomePlane:InternalLocalInvalidAreas()
  local Transform = self:Abs_GetTransform()
  local F = HomeIndoorSandbox.Utils.FBox_InverseTransformBy
  for i, InvalidArea in ipairs(self.InvalidAreas) do
    local Min, Max = F(Transform, InvalidArea.Min, InvalidArea.Max)
    self.LocalInvalidAreas[i] = {Min = Min, Max = Max}
  end
end

function HomePlane:Abs_GetTransform()
  if not self.Transform then
    local World = UE4Helper.GetCurrentWorld()
    if World and UE.UObject.IsValid(World) then
      local Location = self.Min
      self.Transform = UE.FTransform(self.Rotator:ToQuat(), Location, FVectorOne)
    end
  end
  assert(self.Transform, "cannot found Abs_GetTransform, maybe world is invalid!")
  return self.Transform
end

function HomePlane:GetUpVector()
  return UE.UKismetMathLibrary.GetUpVector(self.Rotator)
end

function HomePlane:JudgePlacePropsInWorld(WorldLocation, Width, Length, RotFlag, LocalMin, LocalMax, bIgnoreInvalidArea)
  local TestLocalLocation = self:Abs_GetTransform():InverseTransformPosition(WorldLocation)
  return self:JudgePlaceProps(TestLocalLocation, Width, Length, RotFlag or 0, LocalMin or self.LocalMin, LocalMax or self.LocalMax, bIgnoreInvalidArea)
end

function HomePlane:JudgePlaceProps(TestLocalLocation, Width, Length, RotFlag, LocalMin, LocalMax, bIgnoreInvalidArea)
  assert(Width > 0 and Length > 0)
  local Sandbox = HomeIndoorSandbox
  if 1 == RotFlag % 2 then
    local W = Width
    Width = Length
    Length = W
  end
  local X, Y = Sandbox.Utils.AdjustBoxInPlane(TestLocalLocation, Width, Length, LocalMin, LocalMax)
  local NewLocation = UE.FVector(X, Y, 0)
  if not bIgnoreInvalidArea then
    Width = Width * Sandbox.Utils.CELL_SIZE
    Length = Length * Sandbox.Utils.CELL_SIZE
    local JudgeAABBCollision = Sandbox.Utils.JudgeAABBCollision
    for i, InvalidArea in ipairs(self.LocalInvalidAreas) do
      local bCollision = JudgeAABBCollision(NewLocation, Width, Length, InvalidArea.Min, InvalidArea.Max)
      if bCollision then
        return false, NewLocation, string.format("collision to box(%s, %s), point(%s)(%s), width(%s), length(%s), plane(%s, %s), reason:%s", InvalidArea.Min, InvalidArea.Max, TestLocalLocation, NewLocation, Width, Length, LocalMin, LocalMax, Reason)
      end
    end
  end
  return true, NewLocation
end

function HomePlane:AdjustPropsResolveCollision(TestLocalLocation, Width, Length, RotFlag, LocalMin, LocalMax, IterNum)
  local Sandbox = HomeIndoorSandbox
  if 1 == RotFlag % 2 then
    local W = Width
    Width = Length
    Length = W
  end
  local X, Y = Sandbox.Utils.AdjustBoxInPlane(TestLocalLocation, Width, Length, LocalMin, LocalMax)
  IterNum = IterNum or 3
  local WidthCm = Width * Sandbox.Utils.CELL_SIZE
  local LengthCm = Length * Sandbox.Utils.CELL_SIZE
  local JudgeAABBCollisionWithResolve = Sandbox.Utils.JudgeAABBCollisionWithResolve
  local AdjustLineInPlane = Sandbox.Utils.AdjustLineInPlane
  for i = 1, IterNum do
    local bAnyCollision = false
    for j, InvalidArea in ipairs(self.LocalInvalidAreas) do
      local bCollision, ResolveX, ResolveY = JudgeAABBCollisionWithResolve(X, Y, WidthCm, LengthCm, InvalidArea.Min, InvalidArea.Max)
      if bCollision then
        bAnyCollision = true
        X = AdjustLineInPlane(ResolveX, Length, LocalMin.X, LocalMax.X)
        Y = AdjustLineInPlane(ResolveY, Width, LocalMin.Y, LocalMax.Y)
      end
    end
    if not bAnyCollision then
      return UE.FVector(X, Y, 0)
    end
  end
  return UE.FVector(X, Y, 0)
end

function HomePlane:InternalUpdatePropsAttachParent(PropsActor, ParentActor, DesiredWorldLocation, ExtraHeight)
  local PropsData = PropsActor.PropsData
  local Width, Length = PropsActor.PropsData:GetSizeConfig()
  local PlacePlaneMin, PlacePlaneMax = ParentActor:GetLocalGenPlaneMinMax()
  local InputLocalLocation = ParentActor:Abs_GetTransform():InverseTransformPosition(DesiredWorldLocation)
  local ParentRotFlag = ParentActor.PropsData.RotFlag
  local RotFlag = 0
  if ParentRotFlag % 2 ~= PropsData.RotFlag % 2 then
    RotFlag = 1
  end
  local _, NewLocalLocationInProps = self:JudgePlaceProps(InputLocalLocation, Width, Length, RotFlag, PlacePlaneMin, PlacePlaneMax, true)
  NewLocalLocationInProps.Z = (ExtraHeight or 0) + PlacePlaneMin.Z
  PropsActor:K2_AttachToActor(ParentActor, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  PropsActor:K2_SetActorRelativeLocation(NewLocalLocationInProps, false, nil, false)
  PropsActor.RealtimeLocalLocation = NewLocalLocationInProps
  local Transform = self:Abs_GetTransform()
  local TargetWorldRotation = Transform:TransformRotation(HomeIndoorSandbox.Utils.GetRotationByFlag(PropsData.RotFlag))
  local ChildPropsRelativeRotation = ParentActor:Abs_GetTransform():InverseTransformRotation(TargetWorldRotation)
  if PropsActor.OnPreMove then
    PropsActor:OnPreMove()
  end
  PropsActor:K2_SetActorRelativeRotation(ChildPropsRelativeRotation:ToRotator(), false, nil, false)
  if PropsActor.OnPostMove then
    PropsActor:OnPostMove()
  end
end

function HomePlane:InternalUpdateProps(PropsActor, DesiredWorldLocation, HeightOffset, bIgnoreInvalidArea)
  local PropsData = PropsActor.PropsData
  local Width, Length = PropsData:GetSizeConfig()
  local bInRange, NewLocalLocation = self:JudgePlacePropsInWorld(DesiredWorldLocation, Width, Length, PropsData.RotFlag, nil, nil, bIgnoreInvalidArea)
  if not bInRange then
    return false
  end
  local Transform = self:Abs_GetTransform()
  NewLocalLocation.Z = HeightOffset or 0
  local TargetWorldLocation = Transform:TransformPosition(NewLocalLocation)
  local TargetWorldRotation = Transform:TransformRotation(HomeIndoorSandbox.Utils.GetRotationByFlag(PropsData.RotFlag))
  if PropsActor.OnPreMove then
    PropsActor:OnPreMove()
  end
  PropsActor:Abs_K2_SetActorLocationAndRotation_WithoutHit(TargetWorldLocation, TargetWorldRotation:ToRotator())
  if PropsActor.OnPostMove then
    PropsActor:OnPostMove()
  end
  PropsActor.RealtimeLocalLocation = NewLocalLocation
  return true
end

function HomePlane:LoadPlaceProps(PropsActor)
  HomeIndoorSandbox:LogInfo("[Visibility] HomePlane:LoadPlaceProps", PropsActor, self.bVisible, "Room:", self.RoomId)
  PropsActor:SetVisible(self.bVisible)
  local PropsData = PropsActor.PropsData
  if PropsData.RealtimeParentPropsData then
    local ParentActor = PropsData:ResolveParentPropsActor()
    if not HomeIndoorSandbox:Ensure(ParentActor, "cannot found parent", PropsData.Id, PropsData.RealtimeParentPropsData.Id) then
      return false
    end
    self:InternalUpdatePropsAttachParent(PropsActor, ParentActor, PropsData.Location)
  else
    if not self:InternalUpdateProps(PropsActor, PropsData.Location) then
      return false
    end
    if not self:JudgePlaceEnabled(PropsActor, true) then
      return false
    end
  end
  self:MoveTo(PropsActor.PropsData, PropsActor)
  return true
end

function HomePlane:EditPlaceProps(PropsActor)
  local PropsData = PropsActor.PropsData
  local TestLocalLocation = PropsData.TempLocalLocation
  local DesiredWorldLocation = self:Abs_GetTransform():TransformPosition(TestLocalLocation)
  if PropsData.RealtimeParentPropsData then
    local ParentActor = PropsData:ResolveParentPropsActor()
    if not HomeIndoorSandbox:Ensure(ParentActor, "cannot found parent", PropsData.Id, PropsData.RealtimeParentPropsData.Id) then
      return false
    end
    self:InternalUpdatePropsAttachParent(PropsActor, ParentActor, DesiredWorldLocation)
  else
    if not self:InternalUpdateProps(PropsActor, DesiredWorldLocation, nil, true) then
      return false
    end
    if HomeIndoorSandbox.Utils.EnableDebugDraw then
      self:DrawDebugGeneratePlane(PropsActor)
    end
  end
  self:MoveTo(PropsData, PropsActor)
  return true
end

function HomePlane:MovePlaceProps(PropsActor, DesiredWorldLocation, ParentPropsData)
  local PropsData = PropsActor.PropsData
  if not PropsData then
    return false
  end
  PropsActor:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  if ParentPropsData then
    local ParentActor = ParentPropsData:ResolvePropsActor()
    if not ParentActor then
      return false
    end
    self:InternalUpdatePropsAttachParent(PropsActor, ParentActor, DesiredWorldLocation, HomeIndoorSandbox.Utils.SELECT_HEIGHT)
  elseif not self:InternalUpdateProps(PropsActor, DesiredWorldLocation, HomeIndoorSandbox.Utils.SELECT_HEIGHT, true) then
    return false
  end
  PropsData.RealtimeParentPropsData = ParentPropsData
  PropsData.RealtimePlane:MoveFrom(PropsData)
  self:MoveTo(PropsData, PropsActor)
  return true
end

function HomePlane:RotatePlaceProps(PropsActor)
  local PropsData = PropsActor.PropsData
  local Width, Length = PropsData:GetSizeConfig()
  local DeltaOffset
  if Width ~= Length then
    local DeltaY = 0
    local DeltaX = 0
    local bLength = 0 ~= Length & 1
    local bWidth = 0 ~= Width & 1
    if bLength ~= bWidth then
      if Width < Length then
        DeltaY = HomeIndoorSandbox.Utils.CELL_SIZE / 2.0
      else
        DeltaX = HomeIndoorSandbox.Utils.CELL_SIZE / 2.0
      end
    end
    DeltaOffset = UE4.FVector(DeltaX, DeltaY, 0)
    PropsActor:K2_AddActorLocalOffset(DeltaOffset, false, nil, false)
  end
  PropsActor:K2_AddActorLocalRotation(HomeIndoorSandbox.Utils.ROTATOR_ONCE, false, nil, false)
  if DeltaOffset then
    PropsActor:K2_AddActorLocalOffset(-DeltaOffset, false, nil, false)
  end
  PropsData:ChangeRotation()
  local DesiredWorldLocation = PropsActor:Abs_K2_GetActorLocation()
  local ParentPropsData = PropsData.RealtimeParentPropsData
  if not ParentPropsData and DeltaOffset then
    local TestLocalLocation = self:Abs_GetTransform():InverseTransformPosition(DesiredWorldLocation)
    local NewLocalLocation = self:AdjustPropsResolveCollision(TestLocalLocation, Width, Length, PropsData.RotFlag, self.LocalMin, self.LocalMax)
    if NewLocalLocation then
      DesiredWorldLocation = self:Abs_GetTransform():TransformPosition(NewLocalLocation)
    else
      HomeIndoorSandbox:LogWarn("resolve collision failed", TestLocalLocation, Width, Length, PropsData.RotFlag)
    end
  end
  local bPlaceSuccessAfterMove = self:MovePlaceProps(PropsActor, DesiredWorldLocation, ParentPropsData)
  return bPlaceSuccessAfterMove
end

function HomePlane:ClearPlaneProps(RoomData)
  for PropsData, PropsActor in pairs(self.PropsDataSet) do
    self:MoveFrom(PropsData)
    PropsData:OnPreRelease()
    if not RoomData or not RoomData:HasPropsData(PropsData) then
      if UE4.UObject.IsValid(PropsActor) then
        PropsActor:K2_DestroyActor()
      end
    elseif UE4.UObject.IsValid(PropsActor) then
      PropsActor:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
      HomeIndoorSandbox.ResMgr:RecyclePropsActor(PropsData, PropsActor)
    end
  end
  HomeIndoorSandbox:Ensure(not next(self.PropsDataSet))
  HomeIndoorSandbox:Ensure(not next(self.NoDependencyProps))
end

function HomePlane:RemoveProps(PropsData)
  local PropsActor = self.PropsDataSet[PropsData]
  if PropsActor then
    self:MoveFrom(PropsData)
    PropsData:OnPreRelease()
    PropsActor:K2_DestroyActor()
  end
end

function HomePlane:MoveFrom(PropsData)
  HomeIndoorSandbox:Ensure(PropsData and self.PropsDataSet[PropsData], "no in plane", PropsData and PropsData.Id)
  self.PropsDataSet[PropsData] = nil
  PropsData.RealtimePlane = nil
  self.NoDependencyProps[PropsData] = nil
end

function HomePlane:MoveTo(PropsData, PropsActor)
  HomeIndoorSandbox:Ensure(PropsData and self.PropsDataSet[PropsData] ~= PropsActor, "already in plane", PropsData and PropsData.Id)
  self.PropsDataSet[PropsData] = PropsActor
  PropsData.RealtimePlane = self
  if not PropsData.RealtimeParentPropsData then
    self.NoDependencyProps[PropsData] = PropsActor
  end
end

function HomePlane:JudgePlaceEnabled(PropsActor, bIgnoreInvalidAreas)
  local PropsData = PropsActor.PropsData
  local PropsWidth, PropsLength = PropsData:GetSizeConfig()
  if PropsData.RealtimeParentPropsData then
    local ParentActor = PropsActor:GetAttachParentActor()
    local ParentProps = PropsData:ResolveParentPropsActor()
    if not self:InternalJudgeInclude(PropsActor, ParentProps, PropsWidth, PropsLength) then
      return false
    end
    if HomeIndoorSandbox:Ensure(ParentProps == ParentActor, "cannot found parent actor") then
      local ParentPropsData = PropsData.RealtimeParentPropsData
      local ParentRotFlag = ParentPropsData.RotFlag
      local ChildActors = PropsData.RealtimeParentPropsData:ResolveSubPropsActorArray()
      for _, TestPropsActor in tpairs(ChildActors) do
        if TestPropsActor ~= PropsActor and TestPropsActor.PropsData and self:InternalJudgeCollision(TestPropsActor, PropsActor, ParentRotFlag) then
          return false
        end
      end
      return true
    end
  else
    for TestPropsData, TestPropsActor in pairs(self.NoDependencyProps) do
      if TestPropsActor ~= PropsActor and self:InternalJudgeCollision(TestPropsActor, PropsActor, 0, true) then
        return false
      end
    end
    if not bIgnoreInvalidAreas then
      local Sandbox = HomeIndoorSandbox
      if 1 == PropsData.RotFlag % 2 then
        local W = PropsWidth
        PropsWidth = PropsLength
        PropsLength = W
      end
      PropsWidth = PropsWidth * Sandbox.Utils.CELL_SIZE
      PropsLength = PropsLength * Sandbox.Utils.CELL_SIZE
      local JudgeAABBCollision = Sandbox.Utils.JudgeAABBCollision
      local RealtimeLocalLocation = PropsActor.RealtimeLocalLocation
      for i, InvalidArea in ipairs(self.LocalInvalidAreas) do
        local bCollision = JudgeAABBCollision(RealtimeLocalLocation, PropsWidth, PropsLength, InvalidArea.Min, InvalidArea.Max)
        if bCollision then
          return false
        end
      end
    end
    return true
  end
  return false
end

local function GE(a, b, tolerance)
  tolerance = tolerance or 0.01
  return b < a or tolerance > math.abs(a - b)
end

local function LE(a, b, tolerance)
  tolerance = tolerance or 0.01
  return a < b or tolerance > math.abs(a - b)
end

function HomePlane:InternalJudgeInclude(PropsActor, ParentProps, Width, Length)
  local GenMin, GenMax = ParentProps:GetLocalGenPlaneMinMax()
  local HalfCellSize = HomeIndoorSandbox.Utils.HALF_CELL_SIZE
  local RelativeLocation = PropsActor.RealtimeLocalLocation
  local PropsData = PropsActor.PropsData
  local ParentPropsData = ParentProps.PropsData
  local ParentRotFlag = ParentPropsData.RotFlag
  if ParentRotFlag % 2 ~= PropsData.RotFlag % 2 then
    local W = Width
    Width = Length
    Length = W
  end
  local HalfWidth = HalfCellSize * Width
  local HalfLength = HalfCellSize * Length
  return LE(RelativeLocation.X + HalfLength, GenMax.X) and LE(RelativeLocation.Y + HalfWidth, GenMax.Y) and GE(RelativeLocation.X - HalfLength, GenMin.X) and GE(RelativeLocation.Y - HalfWidth, GenMin.Y)
end

function HomePlane:InternalJudgeCollision(A, B, ParentRotFlag, bEnableTypeCollision)
  if bEnableTypeCollision then
    local TypeA = A.PropsData:GetTypeEnum()
    local TypeB = B.PropsData:GetTypeEnum()
    if TypeA ~= TypeB and (TypeA == Enum.FurnitureType.FT_CARPET or TypeB == Enum.FurnitureType.FT_CARPET) then
      return false
    end
  end
  ParentRotFlag = ParentRotFlag or 0
  local AW, AL = A.PropsData:GetSizeConfig()
  local BW, BL = B.PropsData:GetSizeConfig()
  local PA = A.RealtimeLocalLocation
  local PB = B.RealtimeLocalLocation
  local HalfCellSize = HomeIndoorSandbox.Utils.HALF_CELL_SIZE
  if A.PropsData.RotFlag % 2 ~= ParentRotFlag % 2 then
    local W = AW
    AW = AL
    AL = W
  end
  if B.PropsData.RotFlag % 2 ~= ParentRotFlag % 2 then
    local W = BW
    BW = BL
    BL = W
  end
  AW = HalfCellSize * AW
  BW = HalfCellSize * BW
  AL = HalfCellSize * AL
  BL = HalfCellSize * BL
  local AMinX = PA.X - AL
  local AMaxX = PA.X + AL
  local BMinX = PB.X - BL
  local BMaxX = PB.X + BL
  local AMinY = PA.Y - AW
  local AMaxY = PA.Y + AW
  local BMinY = PB.Y - BW
  local BMaxY = PB.Y + BW
  if GE(AMinX, BMaxX) then
    return false
  end
  if GE(BMinX, AMaxX) then
    return false
  end
  if GE(AMinY, BMaxY) then
    return false
  end
  if GE(BMinY, AMaxY) then
    return false
  end
  return true
end

function HomePlane:QueryPropsEdgeValidCell(PropsData)
  local LocalP = self:InternalQueryPropsEdgeValidCell(PropsData)
  if LocalP then
    local WorldP = self:LPosToAbsPos(LocalP)
    return WorldP
  end
end

function HomePlane:DebugCells()
  local Graph = self:GetCellGraphInformation()
  for X, Line in pairs(Graph) do
    for Y, Cell in pairs(Line) do
      local Xt = (X + 0.5) * HomeIndoorSandbox.Utils.CELL_SIZE
      local Yt = (Y + 0.5) * HomeIndoorSandbox.Utils.CELL_SIZE
      local LocalP = self.LocalMin + UE.FVector(Xt, Yt, 0)
      local WorldP = self:Abs_GetTransform():TransformPosition(LocalP)
      local Color = UE.FLinearColor(0, 1, 0)
      if 2 == Cell then
        Color = UE.FLinearColor(1, 0, 0)
      elseif 1 == Cell then
        Color = UE.FLinearColor(1, 1, 0)
      elseif 3 == Cell then
        Color = UE.FLinearColor(0, 0, 1)
      end
      self:DrawDebugArrow(WorldP, WorldP + UE.FVector(0, 0, 40), FVectorUp, Color, 10, 10, 10)
    end
  end
end

function HomePlane:MarkRuntimeGraphDirty()
  HomeIndoorSandbox:LogDebug("plane dirty:", self.PlaneId, self.PlaneMasterId)
  self.bCellDirty = true
end

function HomePlane:GetCellGraphInformation()
  if self.bCellDirty then
    local Graph, Indices = HomeIndoorSandbox.Utils.BuildFloorGraphByData(self)
    self.CellGraph = Graph
    self.CellGraphIndices = Indices
    self.bCellDirty = false
  end
  return self.CellGraph, self.CellGraphIndices
end

function HomePlane:CellToLPos(X, Y)
  local CELL_SIZE = HomeIndoorSandbox.Utils.CELL_SIZE
  local PlaneMin = self.LocalMin
  local Xt = (X + 0.5) * CELL_SIZE
  local Yt = (Y + 0.5) * CELL_SIZE
  local P = PlaneMin + UE.FVector(Xt, Yt, 0)
  return P
end

function HomePlane:LPosToCell(LocalPos)
  local CELL_SIZE = HomeIndoorSandbox.Utils.CELL_SIZE
  local PlaneMin = self.LocalMin
  local offset = LocalPos - PlaneMin
  local X = math.floor(offset.X / CELL_SIZE)
  local Y = math.floor(offset.Y / CELL_SIZE)
  return X, Y
end

function HomePlane:LPosToAbsPos(LocalP)
  return self:Abs_GetTransform():TransformPosition(LocalP)
end

function HomePlane:AbsPosToLPos(AbsP)
  return self:Abs_GetTransform():InverseTransformPosition(AbsP)
end

function HomePlane:InternalQueryPropsEdgeValidCellXY(PropsData)
  local Graph, Indices = self:GetCellGraphInformation()
  local PropsRange = Indices[PropsData.Id]
  if not PropsRange then
    return
  end
  local X0, X1, Y0, Y1 = PropsRange[1], PropsRange[2], PropsRange[3], PropsRange[4]
  for X = X0, X1 do
    for Y = Y0, Y1 do
      local Cell = Graph[X][Y]
      if not HomeIndoorSandbox:Ensure(1 == Cell, "logical error") then
        return nil
      end
    end
  end
  
  local function Judge(X, Y)
    local Line = Graph[X]
    if Line then
      local Cell = Line[Y]
      if Cell and 0 == Cell and 0 ~= X and 0 ~= Y then
        return true
      end
    end
    return false
  end
  
  for X = X0, X1 do
    local Y = Y1 + 1
    if Judge(X, Y) then
      return X, Y
    end
  end
  for X = X0, X1 do
    local Y = Y0 - 1
    if Judge(X, Y) then
      return X, Y
    end
  end
  for Y = Y0 - 1, Y1 + 1 do
    local X = X0 - 1
    if Judge(X, Y) then
      return X, Y
    end
  end
  for Y = Y0 - 1, Y1 + 1 do
    local X = X1 + 1
    if Judge(X, Y) then
      return X, Y
    end
  end
end

function HomePlane:InternalQueryPropsEdgeValidCell(PropsData)
  local X, Y = self:InternalQueryPropsEdgeValidCellXY(PropsData)
  if X and Y then
    return self:CellToLPos(X, Y)
  end
end

local directions = {
  {dx = 1, dy = 0},
  {dx = -1, dy = 0},
  {dx = 0, dy = 1},
  {dx = 0, dy = -1}
}
local DEBUG_RANDOM_WALK = false

function HomePlane:InternalQueryRandomReachableCellXY(PropsData, step_min, step_max)
  local start_x, start_y = self:InternalQueryPropsEdgeValidCellXY(PropsData)
  if not start_x or not start_y then
    return
  end
  local Graph, Indices = self:GetCellGraphInformation()
  if not Graph[start_x] or not Graph[start_x][start_y] then
    return
  end
  local cur_x, cur_y = start_x, start_y
  local steps = math.random(step_min, step_max)
  local valid_neighbors = {}
  local neighbor_weight = {}
  local total_weight = 0
  local direction_streak = 10
  local last_direction = {dx = 0, dy = 0}
  for i = 1, steps do
    table.clear(valid_neighbors)
    table.clear(neighbor_weight)
    total_weight = 0
    for _, dir in ipairs(directions) do
      local nx = cur_x + dir.dx
      local ny = cur_y + dir.dy
      if Graph[nx] and 0 == Graph[nx][ny] then
        local weight = 1
        if last_direction and dir.dx == last_direction.dx and dir.dy == last_direction.dy then
          weight = weight + direction_streak
        end
        table.insert(valid_neighbors, nx)
        table.insert(valid_neighbors, ny)
        table.insert(neighbor_weight, weight)
        total_weight = total_weight + weight
      end
    end
    if 0 == #valid_neighbors then
      break
    end
    local rand_weight = math.random(total_weight)
    local rand_index = 1
    local weight_sum = 0
    for idx, weight in ipairs(neighbor_weight) do
      weight_sum = weight_sum + weight
      if rand_weight <= weight_sum then
        rand_index = idx
        break
      end
    end
    local new_x, new_y = valid_neighbors[rand_index * 2 - 1], valid_neighbors[rand_index * 2]
    local dx, dy = new_x - cur_x, new_y - cur_y
    if last_direction and dx == last_direction.dx and dy == last_direction.dy then
    else
      last_direction.dx = dx
      last_direction.dy = dy
    end
    if DEBUG_RANDOM_WALK then
      local from = self:LPosToAbsPos(self:CellToLPos(cur_x, cur_y))
      local to = self:LPosToAbsPos(self:CellToLPos(new_x, new_y))
      local colorIntensity = 0.5 + 0.5 * (i % 50) / 50.0
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), from + FVectorUp * (50 + i * 0.1), to + FVectorUp * (50 + i * 0.1), UE4.FLinearColor(colorIntensity, colorIntensity, 0, 1.0), 30, 1)
    end
    cur_x, cur_y = new_x, new_y
  end
  return cur_x, cur_y
end

function HomePlane:QueryRandomReachableCell(PropsData, step_min, step_max)
  local X, Y = self:InternalQueryRandomReachableCellXY(PropsData, step_min, step_max)
  if X and Y then
    local LocalP = self:CellToLPos(X, Y)
    return LocalP and self:LPosToAbsPos(LocalP) or nil
  end
end

function HomePlane:IndicatePosToCell(AbsPos)
  local LocalP = self:AbsPosToLPos(AbsPos)
  local X, Y = self:LPosToCell(LocalP)
  if X > 0 and Y > 0 then
    local Graph, _ = self:GetCellGraphInformation()
    local Line = Graph and Graph[X]
    if Line then
      return Line[Y] or 2
    end
  end
  return 2
end

return HomePlane
