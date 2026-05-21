local MissileComponent = require("NewRoco.Modules.Core.Scene.Component.Missile.MissileComponent")
local MissileUtils = require("NewRoco.Modules.Core.Missile.MissileUtils")
local Base = MissileComponent
local CurveMissileComponent = Base:Extend("CurveMissileComponent")
MissileUtils:RegisterComponent(Enum.MissileType.FLY_WITH_CURVE, CurveMissileComponent)

function CurveMissileComponent:Ctor()
  Base.Ctor(self)
end

function CurveMissileComponent:OnLaunch()
  Base.OnLaunch(self)
  self.launchedDuration = 0
  self.totalDuration = 0
  self.startTransform = self.owner:GetActorTransform()
  self.endTransform = UE.FTransform(UE.FQuat(), self.targetPos)
  if not self.missileAction then
    Log.Debug("CurveMissileComponent:Update: missileAction is nil")
    return
  end
  self.totalDuration = self.data.CurveFlyTime or self.missileAction:PrepareCurveData(self.startTransform, self.endTransform)
end

function CurveMissileComponent:Update(deltaTime)
  Base.Update(self, deltaTime)
  if not UE.UObject.IsValid(self.missileAction) then
    Log.Debug("CurveMissileComponent:Update: missileAction is invalid")
    return
  end
  local alpha = 0 == self.totalDuration and 0 or self.launchedDuration / self.totalDuration
  local deGrade = self.missileAction.CurveParam and self.totalDuration <= self.missileAction.CurveParam.MinTime or false
  self.missileAction:UpdateCurveMissile(self.owner.viewObj, alpha, self.startTransform or UE.FTransform(), self.endTransform or UE.FTransform(), deGrade)
  local deltaTimeScale = 1
  self.launchedDuration = self.launchedDuration + deltaTime * deltaTimeScale
  Log.Debug("CurveMissileComponent:Update:", self.launchedDuration, self.totalDuration, deltaTimeScale, alpha)
end

return CurveMissileComponent
