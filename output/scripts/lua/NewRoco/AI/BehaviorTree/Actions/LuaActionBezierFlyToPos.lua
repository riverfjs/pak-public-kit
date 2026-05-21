local BezierFlyComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.BezierFlyComponent")
local AIDefines = require("NewRoco.AI.AIDefines")
local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionBezierFlyToPos = Base:Extend("LuaActionBezierFly")
local STUCK_CHECK_INTERVAL = 0.5
local STUCK_THRESHOLD_DIST = 1.0
local STUCK_TIMEOUT = 3.0

function LuaActionBezierFlyToPos:OnStart(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  local anchorPos = self.AnchorPos:GetValue(owner)
  local ctrl1LengthFactor = self.Ctrl1LengthFactor:GetValue(owner)
  local ctrl2Pitch = self.Ctrl2Pitch:GetValue(owner)
  local ctrl2Rotate = self.Ctrl2Rotate:GetValue(owner)
  local ctrl2LengthFactor = self.Ctrl2LengthFactor:GetValue(owner)
  local selfPos = owner.Npc:GetActorLocation()
  local selfFwd = owner.Npc:GetForwardVector()
  local anchorDistance = UE4.UKismetMathLibrary.Vector_Distance(selfPos, anchorPos)
  local anchorDir = anchorPos - selfPos
  local ctrl1Pos = UE4.UKismetMathLibrary.Add_VectorVector(selfFwd * (anchorDistance * ctrl1LengthFactor), selfPos)
  local _ctrl2Fwd = UE4.UKismetMathLibrary.Multiply_VectorFloat(anchorDir, -1)
  _ctrl2Fwd.Z = 0
  _ctrl2Fwd:Normalize()
  local _ctrl2Up = UE4.FVector(0, 0, 1)
  local _ctrl2Rgt = _ctrl2Fwd:RotateAngleAxis(90, _G.UE4Helper.UpVector)
  _ctrl2Fwd = _ctrl2Fwd:RotateAngleAxis(ctrl2Pitch, _ctrl2Rgt)
  _ctrl2Up = _ctrl2Up:RotateAngleAxis(ctrl2Pitch, _ctrl2Rgt)
  local ctrl2Dir = _ctrl2Fwd:RotateAngleAxis(ctrl2Rotate, _ctrl2Up)
  ctrl2Dir:Normalize()
  local ctrl2Pos = UE4.UKismetMathLibrary.Add_VectorVector(ctrl2Dir * (anchorDistance * ctrl2LengthFactor), anchorPos)
  local continuous = self.ContinuousFly and self.ContinuousFly:GetValue(owner) or false
  if continuous then
    owner.Npc:Stop()
  end
  local bezComp = owner.Npc:EnsureComponent(BezierFlyComponent)
  if not bezComp then
    return self:Finish(false)
  end
  bezComp:ContinuousFly(continuous)
  selfPos.Z = selfPos.Z - owner.Npc:GetHalfHeight()
  bezComp:StartFly(selfFwd, selfPos, ctrl1Pos, ctrl2Pos, anchorPos, 20, self, self.FlyEnd)
  self.d_StuckAccumTime = 0
  self.d_StuckLastPos = owner.Npc:GetActorLocation()
  self:StartStuckCheck(owner.Npc)
end

function LuaActionBezierFlyToPos:StartStuckCheck(npc)
  self:StopStuckCheck()
  self.d_StuckCheck = DelayManager:DelaySeconds(STUCK_CHECK_INTERVAL, self.OnStuckCheck, self, npc)
end

function LuaActionBezierFlyToPos:StopStuckCheck()
  if self.d_StuckCheck then
    DelayManager:CancelDelayById(self.d_StuckCheck)
    self.d_StuckCheck = nil
  end
end

function LuaActionBezierFlyToPos:OnStuckCheck(npc)
  self.d_StuckCheck = nil
  if not npc or npc.isDestroy then
    return
  end
  local curPos = npc:GetActorLocation()
  local dist = UE4.UKismetMathLibrary.Vector_Distance(curPos, self.d_StuckLastPos)
  if dist < STUCK_THRESHOLD_DIST then
    self.d_StuckAccumTime = self.d_StuckAccumTime + STUCK_CHECK_INTERVAL
    if self.d_StuckAccumTime >= STUCK_TIMEOUT then
      self:StopStuckCheck()
      if npc.BezierFlyComponent then
        npc.BezierFlyComponent:AbortFly()
      end
      self:Finish(false)
      return
    end
  else
    self.d_StuckAccumTime = 0
    self.d_StuckLastPos = curPos
  end
  self:StartStuckCheck(npc)
end

function LuaActionBezierFlyToPos:FlyEnd(result)
  self:StopStuckCheck()
  if AIDefines.ActionResult.Ok(result) then
    self:Finish(true)
  else
    self:Finish(false)
  end
end

function LuaActionBezierFlyToPos:OnInterrupt(AIController, ...)
  local owner = AIController
  local bezComp = owner.Npc.BezierFlyComponent
  if not bezComp then
    return
  end
  if self.ContinuousFly and self.ContinuousFly:GetValue(owner) then
  else
    bezComp:ContinuousFly(false)
  end
  self:StopStuckCheck()
  bezComp:AbortFly()
end

return LuaActionBezierFlyToPos
