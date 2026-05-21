local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local TaskTrackItem = require("NewRoco.Modules.Core.Task.TaskTrackItem")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = TaskTrackItem
local WildTrackItem = Base:Extend("WildTrackItem")
local MarkInvalidReason = {
  [0] = "Invalid",
  [1] = "Player not found",
  [2] = "Task is finished",
  [3] = "npc viewObj is hidden",
  [4] = "ExtraTrackingInfo not found",
  [5] = "ExtraTrackingInfo.guide_list not found",
  [6] = "SceneModule not found",
  [7] = "NearestActor not found",
  [8] = "OnDestroy"
}
local CheckRange = 3000
local CheckDistSquared2D = CheckRange * CheckRange

function WildTrackItem:Ctor(config, info, go, TaskObject, Index)
  self.LastShowTime = 0
  self.bNeedShowTips = false
  self.bLastNeedShowTips = false
  self.ServerTrackPos = UE4.FVector(0, 0, 0)
  Base.Ctor(self, config, info, go, TaskObject, Index)
end

function WildTrackItem:OnTick(DeltaTime)
  Base.OnTick(self, DeltaTime)
  self.LastShowTime = self.LastShowTime + DeltaTime
  if self.bNeedShowTips and self.LastShowTime > 20 then
    self.LastShowTime = 0
    self.bNeedShowTips = false
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_trace_wild_special, nil, nil, 5)
    Log.Debug("WildTrackItem:OnTick ", self.TaskInfo.id)
  end
end

function WildTrackItem:FindNPC()
  self.bLastNeedShowTips = self.bNeedShowTips
  self.bNeedShowTips = false
  local Player = self:UpdatePlayerPosCache()
  if not Player then
    self:MarkInvalid(MarkInvalidReason[1])
    return
  end
  local Finished = self.TaskObject:CheckConditionDone(self.go_index)
  if Finished then
    self:MarkInvalid(MarkInvalidReason[2])
    return
  end
  local HasTargetNPC = false
  if self:NeedRegisterFinder() then
    if not self:IsRegisteredFinder() then
      self:RegisterFinder()
    end
    local npcs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetTopKNPC, self.FinderRef)
    if (not npcs or not (#npcs > 0)) and self.GoType == Enum.TaskGoActionType.TGAT_NPC_PRIORITY then
      npcs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetTopKNPC, self.FinderRef2)
    end
    if npcs and #npcs > 0 then
      local npc = npcs[1]
      if npc then
        local NeedTrack = false
        local serverData = npc and npc.serverData
        local base = serverData and serverData.base
        local actor_id = base and base.actor_id
        if not self.LastTrackNpcId or actor_id and actor_id == self.LastTrackNpcId then
        else
          self:ClearTrackedNPC()
        end
        self.LastTrackNpcId = actor_id
        if self.TaskObject:IsTrack() then
          NeedTrack = true
        end
        npc:SetTracked(NeedTrack)
      end
      HasTargetNPC = true
      if npc.viewObj and npc.viewObj.resourceLoaded then
        local pos = npc:GetActorLocation()
        self.Position.X = pos.X
        self.Position.Y = pos.Y
        self.Valid = true
        self.MinimapValid = true
        self.TargetInSameScene = true
        self.TargetInSameSceneGroup = true
        local UpdateSign = false
        local DistRatio = npc.squaredDis2LocalIgnoreZ / 4000000
        self.TargetZ = self:ApplyViewOffset(pos.Z, npc, 1)
        local DeltaZ = math.abs(self.Position.Z - pos.Z)
        if DistRatio <= 1 then
          self:UpdatePosition(self.Position.X, self.Position.Y, self.TargetZ)
        elseif DistRatio > 1 and DistRatio < 16 then
          local Alpha = 1 - math.clamp((DistRatio - 1) / 15, 0, 1)
          self.Position.Z = (1 - Alpha) * self.Position.Z + self.TargetZ * Alpha
          UpdateSign = true
        elseif 0 == self.Position.Z or DeltaZ > 2000 then
          self.Position.Z = pos.Z
          UpdateSign = true
        end
        if not self.TaskObject:IsTrack() then
          local CloseThreshold = 10
          if self.TargetZ and self.Position and CloseThreshold >= math.abs(self.Position.Z - self.TargetZ) then
            self:StopTick()
          end
        end
        if not npc:GetVisible() then
          self:MarkInvalid(MarkInvalidReason[3])
        else
          self:UpdateDirectionSign()
          self:UpdateDistance()
          npc:ScheduleNextTick(0.1)
          self:CheckNPCOptions(npc)
        end
        return
      end
    elseif UE4.UKismetMathLibrary.VSizeSquared(self.ServerTrackPos) > 1 then
      local Dist3D = Player:GetActorLocationFrameCache():DistSquared(self.ServerTrackPos)
      if Dist3D <= CheckDistSquared2D then
        self.bNeedShowTips = true
        if not self.bLastNeedShowTips then
          self.LastShowTime = 0
        end
      end
    end
  elseif self:IsRegisteredFinder() then
    self:UnRegisterFinder()
  end
  local ExtraTrackingInfo = self:GetExtraTrackingInfo()
  if not ExtraTrackingInfo then
    self:MarkInvalid(MarkInvalidReason[4])
    return
  end
  if not ExtraTrackingInfo.guide_list or 0 == #ExtraTrackingInfo.guide_list then
    self:MarkInvalid(MarkInvalidReason[5])
    return
  end
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    self:MarkInvalid(MarkInvalidReason[6])
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
    if InSameScene and self:ConstValidByGuide(guide_info) then
      DoCompare = true
    elseif not InSameScene then
      if #ExtraTrackingInfo.guide_list > 1 then
        if guide_info.target_res_cfg_id and guide_info.target_res_cfg_id == CurrentMapID then
          DoCompare = true
        else
          DoCompare = false
        end
      else
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
    self:MarkInvalid(MarkInvalidReason[7])
    return
  end
  local Pos = self:GetGuidePos(NearestActor)
  local ConfID = self:GetGuideNpcID(NearestActor)
  local NPCConf = ConfID and _G.DataConfigManager:GetNpcConf(ConfID, true)
  local DefaultHeight = 100
  if NPCConf then
    DefaultHeight = NPCConf.trace_icon_offset
    local Model = _G.DataConfigManager:GetModelConf(NPCConf.model_conf, true)
    if Model then
      DefaultHeight = DefaultHeight + 2 * ((Model.capsule_halfheight or 0) * (Model.model_scale or 0)) * 1.0E-5
    end
  end
  self:UpdatePosition(Pos.x, Pos.y, Pos.z + DefaultHeight)
  self:UpdateDistance()
  self:UpdateDirectionSign()
  self.TargetSceneID = NearestActor.dest_scene_cfg_id or -1
  self.TargetSceneResID = NearestActor.dest_res_cfg_id or -1
  if self:DistSquared2D(Player:GetActorLocationFrameCache(), self.ServerTrackPos) > CheckDistSquared2D then
    self.Valid = true
    self.MinimapValid = true
  end
  if not self.TaskObject:IsTrack() then
    local CloseThreshold = 10
    if self.Position and CloseThreshold >= math.abs(self.Position.Z - (Pos.z + DefaultHeight)) then
      self:StopTick()
    end
  end
  local InDungeon = _G.DataModelMgr.PlayerDataModel:IsInDungeon()
  if self.WasInDungeon ~= InDungeon or self.TargetInSameScene ~= HasAnyInSameScene or self.TargetInSameSceneGroup ~= HasAnyInSameGroup or self.CurrentSceneID ~= CurrentMapID then
    self.WasInDungeon = InDungeon
    self.TargetInSameScene = HasAnyInSameScene
    self.TargetInSameSceneGroup = HasAnyInSameGroup
    self.CurrentSceneID = CurrentMapID
    self.ShouldSendEvent = true
  end
  if not self.TargetInSameScene and InDungeon then
    self.Valid = false
    self.MinimapValid = false
  end
  if not self.ServerTrackPos then
    self.ServerTrackPos = UE4.FVector(0, 0, 0)
  end
  if NearestActor.dest_res_cfg_id == CurrentMapID then
    self.ServerTrackPos.X = NearestActor.dest_pos.x
    self.ServerTrackPos.Y = NearestActor.dest_pos.y
    self.ServerTrackPos.Z = NearestActor.dest_pos.z
  elseif NearestActor.target_res_cfg_id == CurrentMapID then
    self.ServerTrackPos.X = NearestActor.target_pos.x
    self.ServerTrackPos.Y = NearestActor.target_pos.y
    self.ServerTrackPos.Z = NearestActor.target_pos.z
  else
    self.ServerTrackPos.X = 0
    self.ServerTrackPos.Y = 0
    self.ServerTrackPos.Z = 0
  end
end

return WildTrackItem
