local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local TaskTrackItem = require("NewRoco.Modules.Core.Task.TaskTrackItem")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local Base = TaskTrackItem
local PointTaskTrackItem = Base:Extend("PointTaskTrackItem")
local MarkInvalidReason = {
  [0] = "Invalid",
  [1] = "ExtraTrackingInfo is nil",
  [2] = "ExtraTrackingInfo.guide_list is nil",
  [3] = "SceneModule is nil",
  [4] = "ExtraTrackingInfo.guide_list[1] is nil",
  [5] = "PlayerPosCache is nil"
}

function PointTaskTrackItem:Ctor(config, info, go, TaskObject, Index)
  Base.Ctor(self, config, info, go, TaskObject, Index)
end

function PointTaskTrackItem:FindNPC()
  local ExtraTrackingInfo = self:GetExtraTrackingInfo()
  if not ExtraTrackingInfo then
    self:MarkInvalid(MarkInvalidReason[1])
    return
  end
  if not ExtraTrackingInfo.guide_list or 0 == #ExtraTrackingInfo.guide_list then
    self:MarkInvalid(MarkInvalidReason[2])
    return
  end
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    self:MarkInvalid(MarkInvalidReason[3])
    return
  end
  local FirstItem = ExtraTrackingInfo.guide_list[1]
  if not FirstItem then
    self:MarkInvalid(MarkInvalidReason[4])
    return
  end
  if not self:UpdatePlayerPosCache() then
    self:MarkInvalid(MarkInvalidReason[5])
    return
  end
  local CurrentMapID = SceneModule.mapResId
  local CurrentSceneResConf = _G.DataConfigManager:GetSceneResConf(CurrentMapID)
  local CurrentSceneGroup = CurrentSceneResConf and CurrentSceneResConf.task_scene_group or 0
  local DestSceneConf = _G.DataConfigManager:GetSceneResConf(FirstItem.dest_res_cfg_id)
  local DestSceneGroup = DestSceneConf and DestSceneConf.task_scene_group or 0
  local InSameSceneGroup = CurrentSceneGroup == DestSceneGroup
  self.TargetInSameSceneGroup = InSameSceneGroup
  self.TargetSceneResID = FirstItem.dest_res_cfg_id
  if not InSameSceneGroup then
    self.Valid = false
    self.MinimapValid = false
    return
  end
  local DungeonID = _G.DataModelMgr.PlayerDataModel:GetDungeonID()
  self.TargetInSameScene = DestSceneConf.id == CurrentSceneResConf.id
  if not self.TargetInSameScene and DungeonID > 0 then
    local Dungeon = _G.DataConfigManager:GetDungeonConf(DungeonID)
    if Dungeon and Dungeon.hide_tag ~= Enum.HideTagType.HD_SPEC_TASK then
      self.Valid = false
      self.MinimapValid = false
    end
  end
  local Pos = self:GetGuidePos(FirstItem)
  self:UpdatePosition(Pos.x, Pos.y, Pos.z)
  self:UpdateDirectionSign()
  self:UpdateDistance()
  self.Valid = true
  self.MinimapValid = true
  if not self.TaskObject:IsTrack() then
    self:StopTick()
  end
end

function PointTaskTrackItem:RefreshScenePosList()
  self.MapID = 0
  self.DestMapID = 0
  self.TargetMapID = 0
  local Player = self:UpdatePlayerPosCache()
  if not Player then
    self:MarkInvalid(MarkInvalidReason[1])
    return
  end
  local ExtraTrackingInfo = self:GetExtraTrackingInfo()
  if not ExtraTrackingInfo then
    return
  end
  if not ExtraTrackingInfo.guide_list or 0 == #ExtraTrackingInfo.guide_list then
    return
  end
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return
  end
  local HasAnyInSameScene = false
  local HasAnyInSameGroup = false
  local NearestActor, NearestDist
  local CurrentMapID = SceneModule.mapResId
  local CurrentSceneResConf = _G.DataConfigManager:GetSceneResConf(CurrentMapID)
  local CurrentSceneGroup = CurrentSceneResConf and CurrentSceneResConf.task_scene_group or 0
  for _, guide_info in pairs(ExtraTrackingInfo.guide_list) do
    local DoCompare = false
    local DestSceneConf = _G.DataConfigManager:GetSceneResConf(guide_info.dest_res_cfg_id)
    local DestSceneGroup = DestSceneConf and DestSceneConf.task_scene_group or 0
    local InSameSceneGroup = CurrentSceneGroup == DestSceneGroup
    local InSameScene = CurrentMapID == guide_info.dest_res_cfg_id
    if InSameScene then
      DoCompare = true
    elseif not InSameScene then
      local GuideFinished = self.TaskObject:CheckConditionDone(guide_info.go_index + 1)
      if not GuideFinished then
        DoCompare = true
      end
    end
    if InSameScene then
      HasAnyInSameScene = true
    end
    if InSameSceneGroup then
      HasAnyInSameGroup = true
    end
    if DoCompare then
      local Pos = self:GetGuidePos(guide_info)
      local CurrentDist = self:DistSquared2D(Player:GetActorLocationFrameCache(), Pos)
      if not NearestDist or NearestDist > CurrentDist then
        NearestActor = guide_info
        NearestDist = CurrentDist
      end
    end
  end
  if not NearestActor then
    return
  end
  if NearestActor.map_res_cfg_id and NearestActor.map_res_cfg_id > 0 then
    self.MapID = NearestActor.map_res_cfg_id
    local ScenePos = {}
    ScenePos.X = NearestActor.map_pos.x
    ScenePos.Y = NearestActor.map_pos.y
    ScenePos.Z = NearestActor.map_pos.z
    self:UpdateScenePosList(ScenePos, NearestActor.map_res_cfg_id)
  end
  if NearestActor.dest_res_cfg_id and NearestActor.dest_res_cfg_id > 0 then
    self.DestMapID = NearestActor.dest_res_cfg_id
    local ScenePos = {}
    ScenePos.X = NearestActor.dest_pos.x
    ScenePos.Y = NearestActor.dest_pos.y
    ScenePos.Z = NearestActor.dest_pos.z
    self:UpdateScenePosList(ScenePos, NearestActor.dest_res_cfg_id)
  end
  if NearestActor.target_res_cfg_id and NearestActor.target_res_cfg_id > 0 then
    self.TargetMapID = NearestActor.target_res_cfg_id
    local ScenePos = {}
    ScenePos.X = NearestActor.target_pos.x
    ScenePos.Y = NearestActor.target_pos.y
    ScenePos.Z = NearestActor.target_pos.z
    self:UpdateScenePosList(ScenePos, NearestActor.target_res_cfg_id)
  end
end

return PointTaskTrackItem
