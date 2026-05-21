local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local Base = ActorComponent
local ScaleTransformComponent = Base:Extend("ScaleTransformComponent")

function ScaleTransformComponent:Ctor()
end

function ScaleTransformComponent:Attach(owner)
  Base.Attach(self, owner)
  self.BeginTime = nil
  self.LerpTime = nil
  self.OriginScale = 1
  self.TargetScale = nil
  self.UseBornPt = false
end

function ScaleTransformComponent:SetCustomScale(Scale, LerpTime, UseBornPt, NeedFixPos)
  local OwnerView = self:GetOwnerView()
  if not OwnerView then
    Log.Warning("ScaleTransformComponent: OwnerView is nil, cannot get current scale")
    return
  end
  if OwnerView.GetNpcScale then
    self.OriginScale = OwnerView:GetNpcScale()
  else
    self.OriginScale = OwnerView:GetActorScale3D().X
  end
  if LerpTime and LerpTime > 0 then
    self.owner:ScheduleNextTick(0)
    self.BeginTime = os.msTime()
    self.LerpTime = LerpTime * 1000
    self.UseBornPt = UseBornPt
    self.NeedFixPos = NeedFixPos
    self.TargetScale = Scale
    if math.abs(self.TargetScale - self.OriginScale) > 1.0E-5 then
      self:PlayChangeSkill()
    end
  else
    self.UseBornPt = UseBornPt
    self.NeedFixPos = NeedFixPos
    self.TargetScale = Scale
    if math.abs(self.TargetScale - self.OriginScale) < 1.0E-5 then
      return
    end
    self:LerpFinish()
  end
end

function ScaleTransformComponent:SetCustomScaleInner(Scale)
  local owner = self:GetOwner()
  local ownerView = self:GetOwnerView()
  if not owner or not ownerView then
    Log.Warning("ScaleTransformComponent:SetCustomScaleInner failed because of lose ownerView", Scale)
    return
  end
  local OldHalfHeight = self.owner:GetHalfHeight()
  if ownerView and ownerView.SetNpcScale then
    ownerView:SetNpcScale(Scale)
  end
  if self.NeedFixPos then
    local pos
    if self.UseBornPt then
      pos = owner:GetFixedCoordinate(ownerView)
    else
      pos = owner:GetActorLocation()
      pos.z = pos.z - OldHalfHeight + owner:GetHalfHeight()
    end
    if pos then
      ownerView:Abs_K2_SetActorLocation_WithoutHit(pos, false, false)
    else
      Log.Warning("ScaleTransformComponent:SetCustomScaleInner NPC\228\189\141\231\189\174\239\188\140\228\189\141\231\189\174\228\191\174\230\173\163\229\164\177\232\180\165")
    end
  end
end

function ScaleTransformComponent:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.TargetScale and self.LerpTime and self.BeginTime and self.TargetScale > 0 then
    local CurrentTime = os.msTime()
    local DeltaTime = CurrentTime - self.BeginTime
    if DeltaTime > self.LerpTime then
      self:LerpFinish()
    else
      self:LerpUpdate(DeltaTime)
    end
  end
end

function ScaleTransformComponent:LerpUpdate(DeltaTime)
  if not self.LerpTime or self.LerpTime <= 0 then
    return
  end
  local alpha = math.min(DeltaTime / self.LerpTime, 1)
  local CurrentScale = self.OriginScale + (self.TargetScale - self.OriginScale) * alpha
  self:SetCustomScaleInner(CurrentScale)
  self.owner:ScheduleNextTick(0)
end

function ScaleTransformComponent:LerpFinish()
  if not self.TargetScale or self.TargetScale < 0 then
    return
  end
  self:SetCustomScaleInner(self.TargetScale)
  self.OriginScale = self.TargetScale
  self.TargetScale = nil
  self.LerpTime = nil
  self.UseBornPt = false
end

local ChangeSizeSkill = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Suofang/G6_Scene_Pet_Suofang.G6_Scene_Pet_Suofang'"

function ScaleTransformComponent:PlayChangeSkill()
  local ownerView = self:GetOwnerView()
  local skillProxy = RocoSkillProxy.Create(ChangeSizeSkill, ownerView.RocoSkill, _G.PriorityEnum.Active_Player_Action)
  skillProxy:SetCaster(ownerView)
  skillProxy:SetPassive(true)
  skillProxy:SetForcePlayPassive(true)
  skillProxy:PlaySkill()
end

return ScaleTransformComponent
