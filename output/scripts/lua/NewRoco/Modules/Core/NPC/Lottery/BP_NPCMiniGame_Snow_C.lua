local Base = require("NewRoco.Modules.Core.NPC.Lottery.BP_MiniGameAutoInteractNpcBase")
local BP_NPCMiniGame_Snow_C = Base:Extend("BP_NPCMiniGame_Snow_C")

function BP_NPCMiniGame_Snow_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.lastTime = nil
  self.bounceSpeedMax = 1000
  self.bounceSpeedMin = 0
  self.bounceTimeMax = 6
  self.bounceTimeCount = 0
  self.lastCheckTime = 0
end

local function BuildOrthonormalBasis(N)
  local a = math.abs(N.Z) < 0.999 and UE4.FVector(0, 0, 1) or UE4.FVector(1, 0, 0)
  local T = UE4.UKismetMathLibrary.Cross_VectorVector(a, N)
  T:Normalize()
  local B = UE4.UKismetMathLibrary.Cross_VectorVector(N, T)
  B:Normalize()
  return T, B
end

local function RandRange(a, b)
  return a + (b - a) * math.random()
end

local function RandomDirInConeBand(N, minDeg, maxDeg)
  local T, B = BuildOrthonormalBasis(N)
  local theta = math.rad(RandRange(minDeg, maxDeg))
  local phi = RandRange(0, 2 * math.pi)
  local ct = math.cos(theta)
  local st = math.sin(theta)
  local Dir = N * ct + (T * math.cos(phi) + B * math.sin(phi)) * st
  Dir:Normalize()
  return Dir
end

function BP_NPCMiniGame_Snow_C:ReceiveHit(MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
  if self.lastTime and os.msTime() - self.lastTime < 200 then
    return
  end
  if not self.Sphere then
    return
  end
  self.lastTime = os.msTime()
  local CurrentVelocity = self.Sphere:GetPhysicsLinearVelocity()
  local CurrentSpeed = CurrentVelocity:Size()
  local Dir = RandomDirInConeBand(_G.UE4Helper.UpVector, 70, 80)
  Dir.Z = Dir.Z * 4
  self.bounceTimeCount = self.bounceTimeCount + 1
  local alpha = math.max(1 - self.bounceTimeCount / self.bounceTimeMax, 0)
  local minSpeed = self.bounceSpeedMin + (self.bounceSpeedMax - self.bounceSpeedMin) * alpha
  local NewSpeed = math.max(CurrentSpeed, minSpeed)
  local NewVelocity = Dir * NewSpeed
  self.Sphere:SetPhysicsLinearVelocity(NewVelocity)
  if NewVelocity and NewVelocity.Z > 100 then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(30100201, self, "MiniGameSnow")
  end
  if NewSpeed < 1 then
    self:OnDropStop()
  end
end

function BP_NPCMiniGame_Snow_C:OnDropStop()
  local Comp = self:K2_GetRootComponent()
  if Comp then
    Comp:SetSimulatePhysics(false)
  end
end

function BP_NPCMiniGame_Snow_C:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if not self.sceneCharacter then
    return
  end
  self.sceneCharacter:ScheduleNextTick(0.5)
  local Now = UE.UNRCStatics.GetUTCTimestampMS()
  if self.lastCheckTime > 0 and Now - self.lastCheckTime < 1000 then
    return
  end
  self.lastCheckTime = Now
  local serverData = self.sceneCharacter.serverData
  local BornTime = (serverData.base.born_time or 0) * 1000
  local ServerTime = _G.ZoneServer:GetServerTime()
  local ExistTime = ServerTime - BornTime
  local SurviveTime = (self.SurviveTime or 10) * 1000
  if ExistTime > SurviveTime then
    local interactionComp = self.sceneCharacter.InteractionComponent
    local option = interactionComp and interactionComp:GetMainAction()
    if option then
      option:OnOptionAction()
    end
  end
end

return BP_NPCMiniGame_Snow_C
