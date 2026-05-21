local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineCameraDOFState = Base:Extend("DialogueTimelineCameraDOFState")
FsmUtils.MergeMembers(Base, DialogueTimelineCameraDOFState, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -101,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  },
  {
    name = "Keys",
    default = {},
    display_name = "\229\133\179\233\148\174\229\184\167"
  }
})
local bDebug = false

function DialogueTimelineCameraDOFState:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

local function SortDOFAction(a, b)
  return a.StartTime < b.StartTime
end

function DialogueTimelineCameraDOFState:OnEnter()
  Base.OnEnter(self)
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  if not self.Keys or 0 == #self.Keys then
    self:Finish()
    return
  end
  table.sort(self.Keys, SortDOFAction)
  for index = 2, #self.Keys do
    if self.Keys[index].KeepLast then
      local CurKey = self.Keys[index]
      local LastKey = self.Keys[index - 1]
      CurKey.Scale = LastKey.Scale
      CurKey.FocalActorID0 = LastKey.FocalActorID0
      CurKey.FocalActorID1 = LastKey.FocalActorID1
      CurKey.FocalActorID2 = LastKey.FocalActorID2
      CurKey.FocalRegionMargin = LastKey.FocalRegionMargin
      CurKey.OutFocalActorID0 = LastKey.OutFocalActorID0
      CurKey.OutFocalActorID1 = LastKey.OutFocalActorID1
      CurKey.OutFocalActorID2 = LastKey.OutFocalActorID2
      CurKey.OutFocalActorID3 = LastKey.OutFocalActorID3
      CurKey.OutFocalActorID4 = LastKey.OutFocalActorID4
      CurKey.OutFocalActorID5 = LastKey.OutFocalActorID5
      CurKey.OutFocalRegionMargin = LastKey.OutFocalRegionMargin
      CurKey.CustomFocalDistance = LastKey.CustomFocalDistance
      CurKey.CustomFocalRegion = LastKey.CustomFocalRegion
      CurKey.CustomNearTransitionRegion = LastKey.CustomNearTransitionRegion
      CurKey.CustomFarTransitionRegion = LastKey.CustomFarTransitionRegion
    end
  end
  self.CurActionIndex = 0
  self:OnTick(0.0)
end

function DialogueTimelineCameraDOFState:CalcActorToCameraDistance(ActorID, CameraLocation, CameraForward)
  if 0 ~= ActorID then
    local Actor = self:GetActor(ActorID)
    local View = DialogueUtils.ExtraActorView(Actor)
    if View then
      local Capsule = View:K2_GetRootComponent():Cast(UE4.UCapsuleComponent)
      if Capsule then
        local ActorToCamera = (Capsule:K2_GetComponentLocation() - CameraLocation):Dot(CameraForward)
        local CosTheta = math.clamp(math.abs(Capsule:GetUpVector():Dot(CameraForward)), 0.0, 1.0)
        local HalfRegion = CosTheta * Capsule:GetScaledCapsuleHalfHeight_WithoutHemisphere() + math.sqrt(1 - CosTheta * CosTheta) * Capsule:GetScaledCapsuleRadius()
        local Near = ActorToCamera - HalfRegion
        local Far = ActorToCamera + HalfRegion
        if bDebug then
          Log.DebugFormat("DialogueTimelineCameraDOFState:CalcActorToCameraDistance, camera to actor [%d][%s] near = %f, far = %f", ActorID, View:GetName(), Near, Far)
        end
        return Near, Far
      else
        local BoundingCenter = UE4.FVector()
        local BoundingExtend = UE4.FVector()
        View:GetActorBounds(false, BoundingCenter, BoundingExtend, false)
        local ActorToCamera = (BoundingCenter - CameraLocation):Dot(CameraForward)
        local HalfRegion = math.abs(UE4.FVector(BoundingExtend.X, 0, 0):Dot(CameraForward)) + math.abs(UE4.FVector(0, BoundingExtend.Y, 0):Dot(CameraForward)) + math.abs(UE4.FVector(0, 0, BoundingExtend.Z):Dot(CameraForward))
        local Near = ActorToCamera - HalfRegion
        local Far = ActorToCamera + HalfRegion
        if bDebug then
          Log.DebugFormat("DialogueTimelineCameraDOFState:CalcActorToCameraDistance, camera to actor [%d][%s] near = %f, far = %f", ActorID, View:GetName(), Near, Far)
        end
        return Near, Far
      end
    end
  end
  return nil, nil
end

function DialogueTimelineCameraDOFState:CalcDOFParamsFromKey(Key)
  if not self.CameraHolder then
    return
  end
  local CameraLocation = self.CameraHolder:GetCurrentViewTransform().Translation
  local CameraForward = self.CameraHolder:GetCurrentViewTransform():TransformVectorNoScale(UE4.FVector(1, 0, 0))
  local NearFocalDistance = math.maxinteger
  local FarFocalDistance = -math.maxinteger
  for _, ActorID in ipairs({
    Key.FocalActorID0,
    Key.FocalActorID1,
    Key.FocalActorID2
  }) do
    local Near, Far = self:CalcActorToCameraDistance(ActorID, CameraLocation, CameraForward)
    if Near and Far then
      NearFocalDistance = math.min(NearFocalDistance, Near)
      FarFocalDistance = math.max(FarFocalDistance, Far)
    end
  end
  if NearFocalDistance <= FarFocalDistance then
    NearFocalDistance = NearFocalDistance - Key.FocalRegionMargin
    FarFocalDistance = FarFocalDistance + Key.FocalRegionMargin
  else
    NearFocalDistance = Key.CustomFocalDistance
    FarFocalDistance = Key.CustomFocalDistance + Key.CustomFocalRegion
  end
  if bDebug then
    Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, camera to focal actor distance union for key at [%f], near = %f, far = %f", Key.StartTime, NearFocalDistance, FarFocalDistance)
  end
  NearFocalDistance = math.max(0, NearFocalDistance)
  FarFocalDistance = math.max(FarFocalDistance, NearFocalDistance)
  local NearOutFocalDistance = -math.maxinteger
  local FarOutFocalDistance = math.maxinteger
  local NearOutFocalDistanceUpdated = false
  local FarOutFocalDistanceUpdated = false
  for _, ActorID in ipairs({
    Key.OutFocalActorID0,
    Key.OutFocalActorID1,
    Key.OutFocalActorID2,
    Key.OutFocalActorID3,
    Key.OutFocalActorID4,
    Key.OutFocalActorID5
  }) do
    local Near, Far = self:CalcActorToCameraDistance(ActorID, CameraLocation, CameraForward)
    if not (Near and Far) or FarOutFocalDistance <= Near then
    elseif FarOutFocalDistance > Near and FarFocalDistance <= Near then
      if bDebug then
        Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, key at [%f], because out focal actor [%d], update far out of focus distance from %f to %f", Key.StartTime, ActorID, FarOutFocalDistance, Near)
      end
      FarOutFocalDistance = Near
      FarOutFocalDistanceUpdated = true
    elseif NearFocalDistance >= Far and NearOutFocalDistance < Far then
      if bDebug then
        Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, key at [%f], because out focal actor [%d], update near out of focus distance from %f to %f", Key.StartTime, ActorID, NearOutFocalDistance, Far)
      end
      NearOutFocalDistance = Far
      NearOutFocalDistanceUpdated = true
    elseif Far <= NearOutFocalDistance then
    else
      if NearFocalDistance > Near then
        if bDebug then
          Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, key at [%f], because out focal actor [%d], update near out of focus distance from %f to %f", Key.StartTime, ActorID, NearOutFocalDistance, NearFocalDistance)
        end
        NearOutFocalDistance = NearFocalDistance
        NearOutFocalDistanceUpdated = true
      end
      if FarFocalDistance < Far then
        if bDebug then
          Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, key at [%f], because out focal actor [%d], update far out of focus distance from %f to %f", Key.StartTime, ActorID, FarOutFocalDistance, FarFocalDistance)
        end
        FarOutFocalDistance = FarFocalDistance
        FarOutFocalDistanceUpdated = true
      end
    end
  end
  if not NearOutFocalDistanceUpdated then
    NearOutFocalDistance = NearFocalDistance - Key.CustomNearTransitionRegion
  end
  if not FarOutFocalDistanceUpdated then
    FarOutFocalDistance = FarFocalDistance + Key.CustomFarTransitionRegion
  end
  local FocalDistance = NearFocalDistance
  local FocalRegion = FarFocalDistance - NearFocalDistance
  FocalDistance = math.max(0, FocalDistance)
  FocalRegion = math.max(0, FocalRegion)
  local NearTransitionRegion = math.max(NearFocalDistance - NearOutFocalDistance, 0)
  local FarTransitionRegion = math.max(FarOutFocalDistance - FarFocalDistance, 0)
  if bDebug then
    Log.DebugFormat("DialogueTimelineCameraDOFState:CalcDOFParamsFromKey, final, key at [%f], FocalDistance = %f, FocalRegion = %f, NearTransition = %f, FarTransition = %f", Key.StartTime, FocalDistance, FocalRegion, NearTransitionRegion, FarTransitionRegion)
  end
  return Key.Scale, FocalDistance, FocalRegion, NearTransitionRegion, FarTransitionRegion
end

function DialogueTimelineCameraDOFState:OnTick(DeltaTime, bTickToEnd)
  self.CameraHolder = nil
  self.CameraHolder = _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.GetCameraHolder)
  if self.CameraHolder == nil then
    return
  end
  local CurTimelineTime = self.state.execTime
  while self.CurActionIndex < #self.Keys and (0 == self.CurActionIndex or CurTimelineTime >= self.Keys[self.CurActionIndex + 1].StartTime) do
    self.CurActionIndex = self.CurActionIndex + 1
  end
  if bTickToEnd then
    self.CurActionIndex = #self.Keys
  end
  local KeyA = self.Keys[self.CurActionIndex]
  if KeyA.Stop then
    _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.RequestCameraDOF, false)
    return
  end
  local Scale, FocalDistance, FocalRegion, NearTransitionRegion, FarTransitionRegion = self:CalcDOFParamsFromKey(KeyA)
  if self.CurActionIndex < #self.Keys then
    local KeyB = self.Keys[self.CurActionIndex + 1]
    if not KeyB.KeepLast then
      local Alpha = math.clamp((CurTimelineTime - KeyA.StartTime) / math.max(KeyB.StartTime - KeyA.StartTime, 1.0E-4), 0.0, 1.0)
      local ScaleB, FocalDistanceB, FocalRegionB, NearTransitionRegionB, FarTransitionRegionB = self:CalcDOFParamsFromKey(KeyB)
      if bDebug then
        Log.DebugFormat("DialogueTimelineCameraDOFState:OnTick, Lerp Value at [%f] and [%f], Alpha = %f", KeyA.StartTime, KeyB.StartTime, Alpha)
      end
      Scale = (1 - Alpha) * Scale + Alpha * ScaleB
      FocalDistance = (1 - Alpha) * FocalDistance + Alpha * FocalDistanceB
      FocalRegion = (1 - Alpha) * FocalRegion + Alpha * FocalRegionB
      NearTransitionRegion = (1 - Alpha) * NearTransitionRegion + Alpha * NearTransitionRegionB
      FarTransitionRegion = (1 - Alpha) * FarTransitionRegion + Alpha * FarTransitionRegionB
    end
  end
  _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.RequestCameraDOF, true, Scale, FocalDistance, FocalRegion, NearTransitionRegion, FarTransitionRegion)
  if bDebug then
    local CameraLocation = self.CameraHolder:GetCurrentViewTransform().Translation
    local CameraForward = self.CameraHolder:GetCurrentViewTransform():TransformVectorNoScale(UE4.FVector(1, 0, 0))
    local ColorFocal = UE.FLinearColor(1, 0, 0, 1)
    UE.UKismetSystemLibrary.DrawDebugArrow(self.CameraHolder:GetMainCamera(), CameraLocation + CameraForward * FocalDistance, CameraLocation + CameraForward * (FocalDistance + FocalRegion), 4, ColorFocal, DeltaTime, 3)
    UE.UKismetSystemLibrary.DrawDebugString(self.CameraHolder:GetMainCamera(), CameraLocation + CameraForward * (FocalDistance + 0.5 * FocalRegion), "FocalRegion", nil, ColorFocal, 0)
    local ColorOutFocal = UE.FLinearColor(0, 0, 1, 1)
    UE.UKismetSystemLibrary.DrawDebugArrow(self.CameraHolder:GetMainCamera(), CameraLocation, CameraLocation + CameraForward * (FocalDistance - NearTransitionRegion), 4, ColorOutFocal, DeltaTime, 3)
    UE.UKismetSystemLibrary.DrawDebugString(self.CameraHolder:GetMainCamera(), CameraLocation + CameraForward * (0.5 * (FocalDistance - NearTransitionRegion)), "NearOutFocalRegion", nil, ColorOutFocal, 0)
    UE.UKismetSystemLibrary.DrawDebugArrow(self.CameraHolder:GetMainCamera(), CameraLocation + CameraForward * (FocalDistance + FocalRegion + FarTransitionRegion), CameraLocation + CameraForward * (FocalDistance + FocalRegion + FarTransitionRegion + 1000), 4, ColorOutFocal, DeltaTime, 3)
    UE.UKismetSystemLibrary.DrawDebugString(self.CameraHolder:GetMainCamera(), CameraLocation + CameraForward * (FocalDistance + FocalRegion + FarTransitionRegion + 500), "FarOutFocalRegion", nil, ColorOutFocal, 0)
  end
end

function DialogueTimelineCameraDOFState:OnFinish()
  if self.CurActionIndex < #self.Keys then
    self:OnTick(0.0, true)
  end
  Base.OnFinish(self)
end

return DialogueTimelineCameraDOFState
