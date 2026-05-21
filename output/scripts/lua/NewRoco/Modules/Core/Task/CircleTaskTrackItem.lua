local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TaskTrackItem = require("NewRoco.Modules.Core.Task.TaskTrackItem")
local Base = TaskTrackItem
local CircleTaskTrackItem = Base:Extend("CircleTaskTrackItem")

function CircleTaskTrackItem:Ctor(config, info, go, TaskObject, Index)
  self.Range = go.data2[1] or 3000
  self.RangeSquared = self.Range * self.Range
  self.HintText = go.show_text or LuaText.task_arrived
  self.HasArrived = false
  Base.Ctor(self, config, info, go, TaskObject, Index)
end

function CircleTaskTrackItem:FindNPC()
  Base.FindNPC(self)
  if not self.Valid then
    return
  end
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local PlayerPos = Player:GetActorLocationFrameCache()
  local DistanceToTarget = UE.FVector.DistSquared2D(PlayerPos, self.Position)
  if type(self.RangeSquared) ~= "number" then
    Log.Error("CircleTaskTrackItem RangeSquared is not number")
    return
  end
  if type(DistanceToTarget) ~= "number" then
    Log.Error("CircleTaskTrackItem DistanceToTarget is not number")
    return
  end
  local Arrived = DistanceToTarget < self.RangeSquared and self.TargetInSameScene
  if Arrived and self.HasArrived then
    self.Valid = false
  elseif Arrived and not self.HasArrived then
    self.Valid = false
    self.HasArrived = Arrived
    self.ShouldSendEvent = true
  elseif not Arrived and not self.HasArrived then
  elseif not Arrived and self.HasArrived then
    self.HasArrived = Arrived
    self.ShouldSendEvent = true
  end
end

function CircleTaskTrackItem:HasDisplayText()
  if self.HasArrived then
    return true
  end
  return Base.HasDisplayText(self)
end

function CircleTaskTrackItem:GetDisplayText()
  if self.HasArrived then
    return self.HintText
  end
  return Base.GetDisplayText(self)
end

return CircleTaskTrackItem
