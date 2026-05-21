local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local Base = ActorComponent
local OverlapAwareVisibilityComponent = Base:Extend("OverlapAwareVisibilityComponent")

function OverlapAwareVisibilityComponent:Ctor()
  self.needCheck = false
  self.additionalOffset = 0
  self.DistanceThreshold = 10000
  self.sqrDistanceThreshold = 100000000
end

function OverlapAwareVisibilityComponent:Attach(owner)
  Base.Attach(self, owner)
  if owner.viewObj and owner.viewObj.resourceLoaded then
    self:OnResourceLoaded()
  end
end

local PLAYER_WIDTH = 35
local PLAYER_HEIGHT_THRESHOLD_SQR = 160000

function OverlapAwareVisibilityComponent:OnResourceLoaded()
  local view = self.owner.viewObj
  if not view then
    Log.Error("OverlapAwareVisibilityComponent:OnResourceLoaded view is nil")
    return
  end
  if view.bSkipOverlapCheck then
    return
  end
  if view:IsA(UE.ANPCBaseCharacter) then
    local capsuleRadius = view.CapsuleComponent:GetScaledCapsuleRadius()
    if 0 ~= capsuleRadius then
      local rad = capsuleRadius + PLAYER_WIDTH
      self.DistanceThreshold = rad
      self.sqrDistanceThreshold = rad * rad
      self:CheckOutBound(self.owner.squaredDis2LocalIgnoreZ, self.owner.squaredDis2Local)
      return
    end
  end
  local Origin, Extend = UE.UNRCStatics.GetActorDefaultCollidingBounds(view)
  local rad = Extend:Size() / 2 + PLAYER_WIDTH
  self.DistanceThreshold = rad
  self.sqrDistanceThreshold = rad * rad
  self:CheckOutBound(self.owner.squaredDis2LocalIgnoreZ, self.owner.squaredDis2Local)
end

function OverlapAwareVisibilityComponent:ComputeDistanceThreshold()
  local view = self.owner.viewObj
  if not view or not UE.UObject.IsValid(view) then
    return PLAYER_WIDTH
  end
  if view:IsA(UE.ANPCBaseCharacter) then
    local capsuleRadius = view.CapsuleComponent:GetScaledCapsuleRadius()
    if 0 ~= capsuleRadius then
      local rad = capsuleRadius + PLAYER_WIDTH
      self.DistanceThreshold = rad
      self.sqrDistanceThreshold = rad * rad
      return rad
    end
  end
  local Origin, Extend = UE.UNRCStatics.GetActorDefaultCollidingBounds(view)
  local rad = Extend:Size() / 2 + PLAYER_WIDTH
  self.DistanceThreshold = rad
  self.sqrDistanceThreshold = rad * rad
  return rad
end

function OverlapAwareVisibilityComponent:OnInvisible()
end

function OverlapAwareVisibilityComponent:OnDistanceOptimize(sqrDistanceIgnoreZ, viewDotValue, sqrDistance, distanceRatio)
  self:CheckOutBound(sqrDistanceIgnoreZ, sqrDistance)
end

function OverlapAwareVisibilityComponent:CheckOutBound(currentSqrDistanceIgnoreZ, currentSqrDistance)
  if not self.needCheck then
    return
  end
  if self:IsOutBound(currentSqrDistanceIgnoreZ) or currentSqrDistance - currentSqrDistanceIgnoreZ > PLAYER_HEIGHT_THRESHOLD_SQR then
    self:RemoveHiddenFlag()
    self.needCheck = false
  end
end

local DummyArray = UE.TArray(UE.AActor)

function OverlapAwareVisibilityComponent:ResolveNPCOverlap(overlapProcessingType, additionalOffset, precision)
  if not overlapProcessingType then
    return
  end
  if overlapProcessingType == _G.Enum.OverLapProcessingType.OLPT_NONE then
    return
  elseif overlapProcessingType == _G.Enum.OverLapProcessingType.OLPT_HIDE then
    self:CheckInBoundAndMarkHidden(true, false, false, additionalOffset, precision)
  elseif overlapProcessingType == _G.Enum.OverLapProcessingType.OLPT_OVERLAP then
    self:CheckInBoundAndMarkHidden(true, true, false, additionalOffset, precision)
  elseif overlapProcessingType == _G.Enum.OverLapProcessingType.OLPT_MOVE then
    self:PushLocalPlayer()
  end
end

function OverlapAwareVisibilityComponent:PushLocalPlayer()
  local deltaDist = self:ComputeDistanceThreshold()
  if not self:IsOutBound(self.owner.squaredDis2Local) then
    Log.Debug("[NpcAOI] overlapAwareComp is In bound", self.owner:DebugNPCNameAndID(), "deltaDist=", deltaDist)
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local statusComponent = localPlayer and localPlayer.statusComponent
    local isHandInHand2P = statusComponent and statusComponent:HasAnyStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) or false
    if localPlayer and UE.UObject.IsValid(localPlayer.viewObj) and not isHandInHand2P then
      localPlayer:ToSafePos(deltaDist)
      localPlayer:ForceSendMoveReq(true, nil)
    end
  end
end

function OverlapAwareVisibilityComponent:CheckInBoundAndMarkHidden(force, skipVis, skipCol, additionalOffset, precision)
  if not force and (0 == self.owner.hiddenFlag or self.owner.viewObj and not self.owner.viewObj.bHidden) then
    return
  end
  if not self.owner.viewObj or self.owner.viewObj.bSkipOverlapCheck then
    return
  end
  local newRad = (additionalOffset or 0) + self.DistanceThreshold
  self.sqrDistanceThreshold = newRad * newRad
  if precision then
    local view = self.owner.viewObj
    if view:IsA(UE.ANPCBaseCharacter) then
      local RootPrim = view:K2_GetRootComponent()
      local radius, halfHeight = RootPrim:GetScaledCapsuleSize()
      local success = UE.UKismetSystemLibrary.CapsuleOverlapActors(view, view:K2_GetActorLocation(), radius, halfHeight, {
        UE.EObjectTypeQuery.Character
      }, nil, nil, DummyArray)
      if success then
        self:MarkHiddenFlag(skipVis, skipCol)
        self.needCheck = true
      end
      return
    end
  end
  if not self:IsOutBound(self.owner.squaredDis2LocalIgnoreZ) then
    self:MarkHiddenFlag(skipVis, skipCol)
    self.needCheck = true
  end
end

function OverlapAwareVisibilityComponent:IsOutBound(sqrDistance)
  return sqrDistance > self.sqrDistanceThreshold
end

function OverlapAwareVisibilityComponent:MarkHiddenFlag(skipVis, skipCol)
  if not skipVis then
    self.owner:SetHidden(true, 10)
  end
  if not skipCol then
    self.owner:SetCollisionDisable(true, 10)
  end
end

function OverlapAwareVisibilityComponent:RemoveHiddenFlag()
  self.owner:SetHidden(false, 10)
  self.owner:SetCollisionDisable(false, 10)
end

return OverlapAwareVisibilityComponent
