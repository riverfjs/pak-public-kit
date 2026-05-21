local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionDrawPoint = Base:Extend("LuaActionDrawPoint")

function LuaActionDrawPoint:OnStart(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  self.controller = owner
  if not self.Target then
    Log.Error("LuaActionDrawPoint Error: Target is nil")
    self:Finish(false)
    return
  end
  local targetType = self.Target:GetType()
  local targetPoint
  if targetType == LuaParamType.Object then
    local targetObj = self.Target:GetValue(owner)
    if targetObj then
      targetPoint = targetObj.viewObj:GetActorLocation()
    else
      Log.Warning("LuaActionDrawPoint: Invalid Object! " .. self.Target.key)
      self:Finish(false)
      return
    end
  elseif targetType == LuaParamType.Vector then
    targetPoint = self.Target:GetValue(owner)
  else
    Log.Error("LuaActionDrawPoint: UnSupported Target Param Type")
    self:Finish(false)
    return
  end
  if not targetPoint then
    Log.Error("LuaActionDrawPoint: Failed to get target point")
    self:Finish(false)
    return
  end
  self.targetPoint = targetPoint
  self.drawSize = self.Size and self.Size:GetValue(owner) or 100
  self.drawDuration = self.Duration and self.Duration:GetValue(owner) or 5
  self.drawThickness = self.Thickness and self.Thickness:GetValue(owner) or 2
  self.drawTimer = 0
  self:DrawDebugPoint(0.1)
  self:StartDebug()
end

function LuaActionDrawPoint:DrawDebugPoint(deltaTime)
  if not self.targetPoint then
    return
  end
  local redColor = UE4.FLinearColor(1, 0, 0, 1)
  UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), self.targetPoint, self.drawSize, 12, redColor, deltaTime or 0.1, self.drawThickness)
end

function LuaActionDrawPoint:OnInterrupt(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  if GlobalConfig.DebugLuaBTree then
    Log.Debug("LuaActionDrawPoint: Interrupted")
  end
  self:Finish(false)
end

function LuaActionDrawPoint:OnEnd(AIController, ...)
  self.controller = nil
  self.targetPoint = nil
  self.drawTimer = nil
  self.drawDuration = nil
  self.drawSize = nil
  self.drawThickness = nil
end

local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")

function LuaActionDrawPoint:StartDebug()
  a.task(function()
    while true do
      if not self.targetPoint then
        self:Finish(false)
        return
      end
      local deltaTime = UE4.UGameplayStatics.GetWorldDeltaSeconds(self.controller:GetWorld())
      self.drawTimer = self.drawTimer + deltaTime
      self:DrawDebugPoint(deltaTime)
      if self.drawTimer >= self.drawDuration then
        self:Finish(true)
        return
      end
      a.wait(au.NextTick())
    end
  end)()
end

return LuaActionDrawPoint
