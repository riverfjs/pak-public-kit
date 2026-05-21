local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local TaskTrackItem = require("NewRoco.Modules.Core.Task.TaskTrackItem")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = TaskTrackItem
local ReachPointTrackItem = Base:Extend("ReachPointTrackItem")
local MarkInvalidReason = {
  [0] = "Invalid",
  [1] = "bConfigCorrect is false",
  [2] = "SceneModule is not found",
  [3] = "SceneID is not correct",
  [4] = "PlayerPos is not found"
}

function ReachPointTrackItem:Ctor(config, info, go, TaskObject, Index)
  self.TaskObject = TaskObject
  local Location = self.TaskObject.Config.task_special_structure_area
  if not Location or #Location < 4 then
    self.bConfigCorrect = false
    return
  end
  self.CorrectSceneID = Location[1] or 0
  self.CorrectPosX = Location[2] or 0
  self.CorrectPosY = Location[3] or 0
  self.CorrectPosZ = Location[4] or 0
  self.bConfigCorrect = true
  Base.Ctor(self, config, info, go, TaskObject, Index)
end

function ReachPointTrackItem:FindNPC()
  if not self.bConfigCorrect then
    self:MarkInvalid(MarkInvalidReason[1])
    return
  end
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    self:MarkInvalid(MarkInvalidReason[2])
    return
  end
  local SceneID = SceneUtils.GetSceneID()
  if SceneID ~= self.CorrectSceneID then
    self:MarkInvalid(MarkInvalidReason[3])
    return
  end
  if not self:UpdatePlayerPosCache() then
    self:MarkInvalid(MarkInvalidReason[4])
    return
  end
  self:UpdatePosition(self.CorrectPosX, self.CorrectPosY, self.CorrectPosZ)
  self:UpdateDirectionSign()
  self:UpdateDistance()
  self.Valid = true
  self.MinimapValid = true
  if not self.TaskObject:IsTrack() then
    self:StopTick()
  end
end

return ReachPointTrackItem
