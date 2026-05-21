local Super = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeTask")
local ResolveObstacleTask = Super:Extend("ResolveObstacleTask")

function ResolveObstacleTask:Ctor()
  Super.Ctor(self)
  self.IgnoreObstaclePropsActors = {}
  self.UEWorld = UE4Helper.GetCurrentWorld()
  self.Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CapsuleComponent = self.Player and self.Player.viewObj.CapsuleComponent
  if not CapsuleComponent then
    self:NotifyFinish()
    return
  end
  self.ObstacleRadius = CapsuleComponent:GetScaledCapsuleRadius()
  self.ObstacleHeight = CapsuleComponent:GetScaledCapsuleHalfHeight()
  self.ObstacleOffsetStart = UE4.FVector(0, 0, 10 + self.ObstacleHeight)
  self.ObstacleOffsetEnd = UE4.FVector(0, 0, self.ObstacleHeight * 1.5)
  self.ObstacleHeight = self.ObstacleHeight * 2
  self.EnableDebugDraw = HomeIndoorSandbox.Utils.EnableDebugDraw
  self:Resolve()
end

function ResolveObstacleTask:OnClean()
  for k, v in pairs(self.IgnoreObstaclePropsActors) do
    if UE.UObject.IsValid(k) then
      k:SetObstacleEnabled(true)
    end
  end
end

function ResolveObstacleTask:OnStart()
  self:Resolve()
end

function ResolveObstacleTask:OnUpdate()
  self:Resolve()
end

function ResolveObstacleTask:Resolve()
  local PlayerLocation = self.Player:GetActorLocation()
  local Radius = self.ObstacleRadius
  if self.Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    local Pet = self.Player.viewObj.BP_RideComponent.RidePet
    if Pet then
      local CapsuleComponent = Pet.CapsuleComponent
      if CapsuleComponent then
        local Width = CapsuleComponent:GetScaledCapsuleRadius()
        Radius = Radius + Width
      end
    end
  end
  local OutComponents = UE.TArray(UE.UMeshComponent)
  UE.UKismetSystemLibrary.Abs_CapsuleOverlapComponents(self.UEWorld, PlayerLocation + self.ObstacleOffsetEnd, Radius, self.ObstacleHeight, {
    UE.EObjectTypeQuery.WorldDynamic,
    UE.EObjectTypeQuery.WorldStatic
  }, UE.UMeshComponent, {
    self.Player.viewObj
  }, OutComponents)
  local PropsList
  for i, Component in tpairs(OutComponents) do
    local Actor = Component:GetOwner()
    if Actor.PropsData then
      PropsList = PropsList or {}
      table.insert(PropsList, Actor)
    end
  end
  if not PropsList then
    self:NotifyFinish()
    return
  end
  local IgnoreObstacles = {}
  for _, PropsActor in pairs(PropsList) do
    if PropsActor.PropsData then
      IgnoreObstacles[PropsActor] = true
      PropsActor:SetObstacleEnabled(false)
    end
  end
  for PropsActor, v in pairs(self.IgnoreObstaclePropsActors) do
    if not IgnoreObstacles[PropsActor] and UE.UObject.IsValid(PropsActor) then
      PropsActor:SetObstacleEnabled(true)
    end
  end
  self.IgnoreObstaclePropsActors = IgnoreObstacles
  if not next(IgnoreObstacles) then
    self:NotifyFinish()
  end
end

return ResolveObstacleTask
