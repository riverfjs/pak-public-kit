local Class = _G.MakeSimpleClass
local ResObject = require("NewRoco.Utils.ResObject")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local EventDispatcher = require("Common.EventDispatcher")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local DistanceLimitConfig = _G.DataConfigManager:GetTaskGlobalConfig("light_min_visible_distance").numList
local TaskLimit = _G.DataConfigManager:GetTaskGlobalConfig("light_scale_task").numList
local SkipFrame = 3
local FinderRegisterDistance = 10000
local FinderUnregisterDistance = 11000
local FinderRegisterDistanceSquared = FinderRegisterDistance * FinderRegisterDistance
local FinderUnregisterDistanceSquared = FinderUnregisterDistance * FinderUnregisterDistance
local ScaleLimit = {
  min = TaskLimit[1] or 100,
  max = TaskLimit[2] or 1000,
  mult = TaskLimit[3] or 10
}
local DistanceLimit = {
  DistanceLimitConfig[1] * DistanceLimitConfig[1] * 10000.0,
  DistanceLimitConfig[2] * DistanceLimitConfig[2] * 10000.0
}
local TrackTime = _G.DataConfigManager:GetTaskGlobalConfig("hud_force_track_time")
TrackTime = TrackTime and TrackTime.num or 30
TrackTime = TrackTime * 1000.0
local DirRange = _G.DataConfigManager:GetMapGlobalConfig("min_divide_range").num
DirRange = DirRange * DirRange
local HighAngle = _G.DataConfigManager:GetMapGlobalConfig("high_divide_angle").num
local LowAngle = HighAngle + 90
local HighCos = math.cos(math.rad(HighAngle))
local LowCos = math.cos(math.rad(LowAngle))
local PlayerPosCache
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
local TaskTrackItem = Class("TaskTrackItem")
EventDispatcher.BindClass(TaskTrackItem)
TaskTrackItem:SetMemberCount(64)

function TaskTrackItem:PreCtor()
  self.AnimIndex = -1
  self.Position = UE4.FVector()
  self.frameCount = 0
  self.ShouldSendEvent = false
  self.Valid = false
  self.WasLocal = false
  self.Synchronized = false
  self.TargetInSameScene = true
  self.TargetInSameSceneGroup = true
  self.TargetSceneID = -1
  self.TargetSceneResID = -1
  self.CurrentSceneID = -1
  self.WasInDungeon = false
  self.DistanceToPlayer = -1
  self.DirectionSign = ""
  self.SpecialType = ""
  self.FocusShine = false
  self.FocusTime = 0
  self.HasNPCReported = false
  self.HasOptionReported = false
  self.TargetNotFoundStartTime = -1
  self.TargetOptionNotFoundStartTime = -1
  self.FinderRef = ""
  self.FinderRef2 = ""
  self.MinimapValid = false
  self.HumanLikeNpcHeightOffset = 0
  self.NonHumanNpcHeightOffset = 0
  self.OtherNpcHeightOffset = 0
  self.CumulativeDeltaTime = 0
end

function TaskTrackItem:Ctor(config, info, go, TaskObject, index)
  EventDispatcher():Attach(self)
  self.go_index = index
  self.TaskConfig = config
  self.TaskInfo = info
  self.GoCondition = go
  self.GoType = go.type
  self.GoData1 = self.GoCondition.data1 or {}
  self.GoData2 = self.GoCondition.data2 or {}
  self.TaskObject = TaskObject
  self.State = nil
  self.LastTrackNpcId = nil
  self.ScenePosList = {}
  self.MapID = 0
  self.DestMapID = 0
  self.TargetMapID = 0
  self.CurrentNpc = nil
  if info.is_track then
    self:Focus(true)
    _G.UpdateManager:Register(self)
    self.AnimIndex = 0
  else
    self.AnimIndex = -1
  end
  self:InitArea()
  NRCEventCenter:RegisterEvent("TaskTrackItem", self, TaskModuleEvent.ON_TASK_TRACK_READY, self.OnTaskTrackReady)
  self:OnTaskTrackReady()
  Log.Debug("TaskTrackItem:Ctor %d", self.TaskInfo.id, info.is_track)
end

function TaskTrackItem:Destroy()
  Log.Debug("TaskTrackItem:Destroy %d", self.TaskInfo.id)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.ON_TASK_TRACK_READY, self.OnTaskTrackReady)
  EventDispatcher.Detach(self)
  _G.UpdateManager:UnRegister(self)
  self:UnRegisterFinder()
  if self.LastTrackNpcId then
    local last_npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.LastTrackNpcId)
    if last_npc then
      last_npc:SetTracked(false)
    end
    self.LastTrackNpcId = nil
  end
  self:RemoveBeam()
  self.GoData1 = nil
  self.GoData2 = nil
  self:MarkInvalid(MarkInvalidReason[8])
end

function TaskTrackItem:GetSearcher()
  local Searcher
  if self.GoType == Enum.TaskGoActionType.TGAT_BASE_NPC then
    Searcher = self.ConstValidFunc
  elseif self.TaskObject.Config.task_class == Enum.TaskClassType.TCT_CAMPAIGN then
    Searcher = self.ConstValidCampaignFunc
    self.SpecialType = "TreasureDig"
  elseif self.GoType == Enum.TaskGoActionType.TGAT_CONTENT or self.GoType == Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
    Searcher = self.ConstValidContentFunc
  elseif self.GoType == Enum.TaskGoActionType.TGAT_WILD_CREATURE then
    if self.GoData1 and #self.GoData1 > 0 then
      Searcher = self.ConstValidFunc
    elseif self.GoData2 and #self.GoData2 > 0 then
      Searcher = self.ConstValidData2ContentFunc
    end
  end
  return Searcher
end

local pairs = _G.pairs

function TaskTrackItem:ConstValidFunc(npc)
  if not self.GoData1 then
    return false
  end
  return table.contains(self.GoData1, npc.config.id)
end

function TaskTrackItem:ConstValidCampaignFunc(npc)
  if self.TaskObject.Config.task_class ~= Enum.TaskClassType.TCT_CAMPAIGN then
    return false
  end
end

function TaskTrackItem:ConstValidContentFunc(npc)
  if not self.GoData1 then
    return false
  end
  local Data = npc.serverData
  local NPCBase = Data and Data.npc_base
  local Content = NPCBase and NPCBase.npc_content_cfg_id or 0
  if 0 == Content then
    return false
  end
  return table.contains(self.GoData1, Content)
end

function TaskTrackItem:ConstValidData2ContentFunc(npc)
  if not self.GoData2 then
    return false
  end
  local Data = npc.serverData
  local NPCBase = Data and Data.npc_base
  local Content = NPCBase and NPCBase.npc_content_cfg_id or 0
  if 0 == Content then
    return false
  end
  return table.contains(self.GoData2, Content)
end

function TaskTrackItem:ConstValidPriorityData1For1(npc)
  if not self.GoData1 then
    return false
  end
  return self.GoData1[2] == npc.config.id
end

function TaskTrackItem:ConstValidPriorityData1For2(npc)
  if not self.GoData1 then
    return false
  end
  local Data = npc.serverData
  local NPCBase = Data and Data.npc_base
  local Content = NPCBase and NPCBase.npc_content_cfg_id or 0
  if 0 == Content then
    return false
  end
  return self.GoData1[2] == Content
end

function TaskTrackItem:ConstValidPriorityData2For1(npc)
  if not self.GoData2 then
    return false
  end
  return self.GoData2[2] == npc.config.id
end

function TaskTrackItem:ConstValidPriorityData2For2(npc)
  if not self.GoData2 then
    return false
  end
  local Data = npc.serverData
  local NPCBase = Data and Data.npc_base
  local Content = NPCBase and NPCBase.npc_content_cfg_id or 0
  if 0 == Content then
    return false
  end
  return self.GoData2[2] == Content
end

function TaskTrackItem:ConstValidByInfo(Info)
  if not self.GoData1 then
    return false
  end
  local ID
  if self.GoCondition.type == Enum.TaskGoActionType.TGAT_CONTENT or self.GoCondition.type == Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
    ID = Info.npc.npc_base.npc_content_cfg_id
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_BASE_NPC then
    ID = Info.npc.npc_base.npc_cfg_id
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_NPC_PRIORITY then
    if self.GoData1 then
      if 1 == self.GoData1[1] then
        ID = Info.npc.npc_base.npc_cfg_id
      else
        ID = Info.npc.npc_base.npc_content_cfg_id
      end
      return self.GoData1[2] == ID
    else
      if 1 == self.GoData2[1] then
        ID = Info.npc.npc_base.npc_cfg_id
      else
        ID = Info.npc.npc_base.npc_content_cfg_id
      end
      return self.GoData2[2] == ID
    end
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_WILD_CREATURE then
    if self.GoData1 and #self.GoData1 > 0 then
      ID = Info.npc.npc_base.npc_cfg_id
    elseif self.GoData2 and #self.GoData2 > 0 then
      ID = Info.npc.npc_base.npc_content_cfg_id
      return table.contains(self.GoData2, ID)
    end
  end
  if not ID then
    return false
  end
  return table.contains(self.GoData1, ID)
end

function TaskTrackItem:ConstValidByGuide(Guide)
  local ID
  if self.GoCondition.type == Enum.TaskGoActionType.TGAT_CONTENT or self.GoCondition.type == Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
    ID = self:GetGuideRefreshContentID(Guide)
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_BASE_NPC then
    ID = self:GetGuideNpcID(Guide)
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_NPC_PRIORITY then
    if self.GoData1 then
      if 1 == self.GoData1[1] then
        ID = self:GetGuideNpcID(Guide)
      else
        ID = self:GetGuideRefreshContentID(Guide)
      end
      if table.contains(self.GoData1, ID) then
        return self.GoData1[2] == ID
      elseif self.GoData2 then
        if 1 == self.GoData2[1] then
          ID = self:GetGuideNpcID(Guide)
        else
          ID = self:GetGuideRefreshContentID(Guide)
        end
        return self.GoData2[2] == ID
      end
    elseif self.GoData2 then
      if 1 == self.GoData2[1] then
        ID = self:GetGuideNpcID(Guide)
      else
        ID = self:GetGuideRefreshContentID(Guide)
      end
      return self.GoData2[2] == ID
    end
  elseif self.GoCondition.type == Enum.TaskGoActionType.TGAT_WILD_CREATURE then
    if self.GoData1 and #self.GoData1 > 0 then
      ID = self:GetGuideNpcID(Guide)
    elseif self.GoData2 and #self.GoData2 > 0 then
      ID = self:GetGuideRefreshContentID(Guide)
      return table.contains(self.GoData2, ID)
    end
  end
  if not ID then
    return false
  end
  if not self.GoData1 then
    return false
  end
  return table.contains(self.GoData1, ID)
end

function TaskTrackItem:AdjustValidFunc(npc)
  if self.GoCondition.type == Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
    return true
  end
  if npc.hideTrackMark then
    return false
  end
  if not self.GoCondition.disable_force_track then
    return true
  end
  local Options = npc.InteractionComponent and npc.InteractionComponent._options
  if not Options then
    return false
  end
  for _, o in pairs(Options) do
    if o:IsOptionEnable() then
      return true
    end
  end
  return false
end

function TaskTrackItem:UpdateNPCTrackStatus(npc, LogPrefix)
  if not npc then
    return
  end
  LogPrefix = LogPrefix or "TaskTrackItem:FindNPC"
  local NeedTrack = false
  local serverData = npc.serverData
  local base = serverData and serverData.base
  local actor_id = base and base.actor_id
  if not self.LastTrackNpcId or actor_id and actor_id == self.LastTrackNpcId then
  else
    Log.Debug(LogPrefix, "LastTrackNpcId:", self.LastTrackNpcId, "actor_id:", actor_id)
    self:ClearTrackedNPC()
  end
  self.LastTrackNpcId = actor_id
  if self.TaskObject:IsTrack() and npc:GetVisible() then
    NeedTrack = true
  end
  npc:SetTracked(NeedTrack)
end

function TaskTrackItem:UpdateNPCPositionAndStatus(npc)
  if not (npc and npc.viewObj) or not npc.viewObj.resourceLoaded then
    return false
  end
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
  return true
end

function TaskTrackItem:RestoreTrackingHud()
  local npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetTopKNPC, self)
  if npcs and #npcs > 0 then
    local npc = npcs[1]
    if npc.PetHUDComponent and npc.PetHUDComponent:HasNpcHud() then
      npc.PetHUDComponent:EndTracking(true)
    end
  end
end

function TaskTrackItem:ApplyViewOffset(BaseZ, npc, alpha)
  if not npc then
    return
  end
  local Offset = 0
  if npc.PetHUDComponent and npc.PetHUDComponent:HasNpcHud() then
    Offset = npc.PetHUDComponent:GetRelativeHeight() + npc:GetScaledHalfHeight()
  else
    local View = npc.viewObj
    if View then
      if View.GetHalfHeight then
        Offset = self.OtherNpcHeightOffset + View:GetHalfHeight()
      elseif View.GetBottomAndTop then
        local OriginZ, ExtentZ = View:GetBottomAndTop()
        local check = true
        if 0 == OriginZ and 0 == ExtentZ then
          check = false
        end
        if check then
          Offset = self.OtherNpcHeightOffset + (OriginZ + ExtentZ - BaseZ)
        end
      end
    end
  end
  if _G.GlobalConfig.TaskIconHeightOverride then
    Offset = Offset + _G.GlobalConfig.TaskIconHeightOverride
  elseif npc and npc.config then
    Offset = Offset + (npc.config.trace_icon_offset or 0)
  end
  return BaseZ + Offset * alpha
end

function TaskTrackItem:UpdatePlayerPosCache()
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    PlayerPosCache = nil
    return nil
  end
  PlayerPosCache = Player:GetActorLocationFrameCache()
  return Player
end

function TaskTrackItem:FindNPC()
  local Player = self:UpdatePlayerPosCache()
  if not Player then
    self:MarkInvalid(MarkInvalidReason[1])
    return
  end
  if self.TaskObject.Config.task_class == Enum.TaskClassType.TCT_CAMPAIGN then
    if self.TaskObject.StaticPosition then
      self.Valid = self.TaskObject.UseStaticPosition
      self.MinimapValid = self.TaskObject.UseStaticPosition
      self.TargetInSameScene = true
      self.TargetInSameSceneGroup = true
      self.Position.X = self.TaskObject.StaticPosition.x
      self.Position.Y = self.TaskObject.StaticPosition.y
      self.Position.Z = self.TaskObject.StaticPosition.z + 200
      self:UpdateDirectionSign()
      self:UpdateDistance()
      if not self.TaskObject:IsTrack() then
        self:StopTick()
      end
    end
    return
  end
  local GuideActor = self.TaskObject and self.TaskObject:GetGuideActor()
  if GuideActor and not GuideActor.bHasReachEnd then
    if GuideActor.bIsMoving then
      self.Valid = false
      self.MinimapValid = false
      self.TargetInSameScene = true
      self.TargetInSameSceneGroup = true
    else
      self.Valid = true
      self.MinimapValid = true
      self.TargetInSameScene = true
      self.TargetInSameSceneGroup = true
      local BallPos = GuideActor:GetBallLocation()
      self.Position.X = BallPos.X
      self.Position.Y = BallPos.Y
      self.Position.Z = BallPos.Z + 200
      self:UpdateDirectionSign()
      self:UpdateDistance()
      if not self.TaskObject:IsTrack() then
        self:StopTick()
      end
    end
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
        self.CurrentNpc = npc
        self:UpdateNPCTrackStatus(npc, "TaskTrackItem:FindNPC")
      end
      HasTargetNPC = true
      if self:UpdateNPCPositionAndStatus(npc) then
        return
      end
    elseif self.CurrentNpc and self.CurrentNpc.viewObj and self.CurrentNpc.viewObj.resourceLoaded then
      Log.Debug("TaskTrackItem:FindNPC: CurrentNpc Exist")
      local npc = self.CurrentNpc
      if npc then
        self:UpdateNPCTrackStatus(npc, "TaskTrackItem:FindNPC")
      end
      HasTargetNPC = true
      if self:UpdateNPCPositionAndStatus(npc) then
        return
      end
    else
      self.CurrentNpc = nil
      if self.LastTrackNpcId then
        Log.Debug("TaskTrackItem:FindNPC: ClearTrackedNPC")
        self:ClearTrackedNPC()
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
  self.Valid = true
  self.MinimapValid = true
  if not self.TaskObject:IsTrack() then
    local CloseThreshold = 10
    if self.Position and CloseThreshold >= math.abs(self.Position.Z - (Pos.z + DefaultHeight)) then
      self:StopTick()
    end
  end
  local InDungeon = _G.DataModelMgr.PlayerDataModel:IsInDungeon()
  local DungeonID = _G.DataModelMgr.PlayerDataModel:GetDungeonID()
  if self.WasInDungeon ~= InDungeon or self.TargetInSameScene ~= HasAnyInSameScene or self.TargetInSameSceneGroup ~= HasAnyInSameGroup or self.CurrentSceneID ~= CurrentMapID then
    self.WasInDungeon = InDungeon
    self.TargetInSameScene = HasAnyInSameScene
    self.TargetInSameSceneGroup = HasAnyInSameGroup
    self.CurrentSceneID = CurrentMapID
    self.ShouldSendEvent = true
  end
  if not self.TargetInSameScene and DungeonID > 0 then
    local Dungeon = _G.DataConfigManager:GetDungeonConf(DungeonID)
    if Dungeon and Dungeon.hide_tag ~= Enum.HideTagType.HD_SPEC_TASK then
      self.Valid = false
      self.MinimapValid = false
    end
  end
  local NeedReport = false
  if self.IsOnline then
    NeedReport = self:IsOnline()
  end
  NeedReport = NeedReport and not HasTargetNPC
  NeedReport = NeedReport and nil ~= NearestActor
  NeedReport = NeedReport and nil ~= NearestDist and NearestDist <= 4000000.0
  NeedReport = NeedReport and not self.HasNPCReported
  NeedReport = NeedReport and self.TargetInSameScene
  NeedReport = NeedReport and self.Valid
  NeedReport = NeedReport and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetShouldFindNPC)
  if NeedReport then
    local Now = os.msTime()
    if self.TargetNotFoundStartTime < 0 then
      self.TargetNotFoundStartTime = Now
    else
      local Delta = Now - self.TargetNotFoundStartTime
      if Delta > 10000.0 then
        self:ReportNPCNotFound(NearestActor)
        self.TargetNotFoundStartTime = Now
      end
    end
  else
    self.TargetNotFoundStartTime = -1
  end
end

function TaskTrackItem:IsOnline()
  local State = _G.ZoneServer:GetOnlineState()
  return State and State == OnlineState.EnteredCell
end

function TaskTrackItem:ReportNPCNotFound(NearestActor)
  local RefreshContentID = self:GetGuideRefreshContentID(NearestActor)
  Log.Error("\229\174\162\230\136\183\231\171\17510\231\167\146\233\146\159\229\134\133\230\178\161\230\156\137\230\148\182\229\136\176\232\191\153\228\184\170NPC\231\154\132\230\182\136\230\129\175\239\188\140\229\188\186\229\136\182\232\175\183\230\177\130\229\144\142\229\143\176...", RefreshContentID)
  local Req = _G.ProtoMessage:newZoneTryInstantiateNpcReq()
  Req.content_cfg_id = RefreshContentID
  Req.taskid = self.TaskInfo.id or 0
  Req.traceidx = math.min(self.go_index - 1 or 0, 0)
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_TRY_INSTANTIATE_NPC_REQ, Req, self, self.OnNPCReported, false, false)
end

function TaskTrackItem:OnNPCReported(rsp)
  self.HasNPCReported = true
end

function TaskTrackItem:CheckNPCOptions(npc)
  if not self:IsOnline() then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  if self.HasOptionReported then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  if not npc then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  if npc.isDestroy then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  local InterComp = npc.InteractionComponent
  if not InterComp then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  local Options = InterComp:GetAllOptions()
  if not Options then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  local Index, Option = next(Options)
  if Index and Option then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  local NPCLocation = npc:GetActorLocation()
  if not NPCLocation then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  local Dist = PlayerPosCache:DistSquared2D(NPCLocation)
  if Dist > 4000000.0 then
    self.TargetOptionNotFoundStartTime = -1
    return
  end
  if self.TargetOptionNotFoundStartTime < 0 then
    self.TargetOptionNotFoundStartTime = os.msTime()
    return
  end
  local Now = os.msTime()
  local DeltaTime = Now - self.TargetOptionNotFoundStartTime
  if DeltaTime < 10000.0 then
    return
  end
  self:ReportOptionNotFound(npc)
  self.TargetOptionNotFoundStartTime = Now
end

function TaskTrackItem:ReportOptionNotFound(npc)
  if not npc then
    return
  end
  if not self.TaskInfo or 0 == self.TaskInfo.id then
    return
  end
  Log.Error("\229\174\162\230\136\183\231\171\17510\231\167\146\233\146\159\229\134\133\230\178\161\230\156\137\230\148\182\229\136\176\232\191\153\228\184\170NPC\232\186\171\228\184\138\228\187\187\228\189\149\229\143\175\231\148\168\231\154\132Option\239\188\140\229\188\186\229\136\182\232\175\183\230\177\130\229\144\142\229\143\176...", npc:DebugNPCNameAndID())
  local Req = _G.ProtoMessage:newZoneTryInstantiateNpcReq()
  Req.taskid = self.TaskInfo.id or 0
  Req.traceidx = math.min(self.go_index - 1 or 0, 0)
  Req.npc_objid = npc:GetServerId()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_TRY_INSTANTIATE_NPC_REQ, Req, self, self.OnOptionReported, false, false)
end

function TaskTrackItem:OnOptionReported(rsp)
  self.HasOptionReported = true
end

function TaskTrackItem:UpdateNotTrackPosition()
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return false
  end
  local CurrentMapID = SceneModule.mapResId
  local Pos = self.ScenePosList[CurrentMapID]
  if Pos then
    self.Valid = true
    self:MarkSynced()
    self.Position.X = Pos.X
    self.Position.Y = Pos.Y
    self.Position.Z = Pos.Z
  end
end

function TaskTrackItem:UpdatePosition(X, Y, Z)
  self.Position.X = X
  self.Position.Y = Y
  local DeltaZ = math.abs(Z - self.Position.Z)
  if 0 == self.Position.Z or DeltaZ > 2000 then
    self.Position.Z = Z
  else
    self.Position.Z = LuaMathUtils.FInterpTo(self.Position.Z, Z, self.CumulativeDeltaTime, 10)
  end
end

function TaskTrackItem:UpdateDirectionSign()
  if not PlayerPosCache then
    self.DirectionSign = ""
    return
  end
  local Dist3D = PlayerPosCache:DistSquared(self.Position)
  if Dist3D < DirRange then
    self.DirectionSign = ""
    return
  end
  local Direction = self.Position - PlayerPosCache
  local Cos = Direction.Z / Direction:Size()
  if Cos > HighCos then
    self.DirectionSign = "\226\150\178"
  elseif Cos < LowCos then
    self.DirectionSign = "\226\150\188"
  else
    self.DirectionSign = ""
  end
end

function TaskTrackItem:UpdateDistance()
  local NewDist
  if PlayerPosCache then
    NewDist = PlayerPosCache:DistSquared(self.Position)
  else
    NewDist = -1
  end
  if self.DistanceToPlayer == NewDist then
    return
  end
  local WasValid = self.DistanceToPlayer >= 0
  local Valid = NewDist >= 0
  NewDist = Valid and math.sqrt(NewDist) or NewDist
  local OldDist = self.DistanceToPlayer
  self.DistanceToPlayer = NewDist
  if WasValid and not Valid then
    self:SendEvent(TaskModuleEvent.ON_TRACK_DISTANCE_INVALID, self)
  elseif not WasValid and Valid then
    self:SendEvent(TaskModuleEvent.ON_TRACK_DISTANCE_VALID, self)
  end
  OldDist = math.round(OldDist / 100)
  NewDist = math.round(NewDist / 100)
  if Valid and OldDist ~= NewDist then
    self:SendEvent(TaskModuleEvent.ON_TRACK_DISTANCE_CHANGE, self, NewDist)
  end
end

function TaskTrackItem:ClearTrackedNPC()
  if not self.LastTrackNpcId then
    return
  end
  local last_npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.LastTrackNpcId)
  if last_npc then
    last_npc:SetTracked(false)
  end
  self.LastTrackNpcId = nil
end

function TaskTrackItem:MarkInvalid(Reason)
  if _G.GlobalConfig.bIsShowFindNpcLog and Reason then
    Log.Debug("TaskTrackItem:MarkInvalid ", Reason, self.TaskInfo.id)
  end
  self.Valid = false
  self.MinimapValid = false
  self.TargetSceneID = -1
  self.TargetSceneResID = -1
  self.TargetInSameScene = false
  self.DirectionSign = ""
  self:UpdateDistance(-1)
  self.TargetNotFoundStartTime = -1
  self.TargetOptionNotFoundStartTime = -1
  self:ClearTrackedNPC()
end

function TaskTrackItem:CheckSendEvent()
  if not self.ShouldSendEvent then
    return
  end
  self.ShouldSendEvent = false
  self:SendEvent(TaskModuleEvent.ON_UPDATE_TRACK, self)
end

function TaskTrackItem:GetExtraTrackingInfo()
  local Module = self.TaskObject.Module
  if not Module then
    return nil
  end
  return Module.ExtraTrackingInfo[self.TaskObject.Info.id]
end

function TaskTrackItem:DistSquared2D(a, b)
  if not a or not b then
    return math.maxinteger
  end
  local X = (a.X or a.x) - (b.X or b.x)
  local Y = (a.Y or a.y) - (b.Y or b.y)
  return X * X + Y * Y
end

function TaskTrackItem:OnTick(DeltaTime)
  self.CumulativeDeltaTime = self.CumulativeDeltaTime + DeltaTime
  if 0 == self.frameCount % SkipFrame then
    local WasValid = self.Valid
    self:FindNPC()
    self:UpdateBeam()
    self.ShouldSendEvent = self.ShouldSendEvent or WasValid ~= self.Valid
    self:CheckSendEvent()
    self.CumulativeDeltaTime = 0
    if not self.TaskObject:IsTrack() then
      self:StopTick()
    end
  end
  self.frameCount = self.frameCount + 1
  if self.frameCount >= SkipFrame then
    self.frameCount = 0
  end
end

function TaskTrackItem:SpawnSpline()
  self.TaskObject:GetGuideActor(true)
end

function TaskTrackItem:NeedBeam()
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return false
  end
  if 0 == SceneModule.mapID then
    return false
  end
  if _G.BattleNetManager.isInBattle then
    return false
  end
  if not self.Valid then
    return false
  end
  local GuideActor = self.TaskObject and self.TaskObject:GetGuideActor()
  if GuideActor and not GuideActor.bHasReachEnd then
    return false
  end
  if not self.Synchronized then
    return false
  end
  if not self.TaskInfo.is_trace then
    return false
  end
  if not self.TaskInfo.is_track then
    local ParentTask = self.TaskObject.TrackParentTask
    if ParentTask then
      if not ParentTask.Info.is_track then
        return false
      end
    else
      return false
    end
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return false
  end
  local HasDialogue = TaskUtils.HasDialogue()
  if HasDialogue then
    return false
  end
  if _G.CinematicModuleCmd and _G.NRCModeManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) then
    return false
  end
  local AllCond = _G.FunctionBanManager:GetPlayerConditions()
  if AllCond[Enum.PlayerConditionType.PCT_WORLD_COMBATING] then
    return false
  end
  local Distance = self:DistSquared2D(player:GetActorLocationFrameCache(), self.Position)
  return Distance >= DistanceLimit[1] and Distance <= DistanceLimit[2]
end

function TaskTrackItem:UpdateBeam()
  local NeedBeam = self:NeedBeam() and self:NeedTrackInMiniGame()
  local HasBeam = self.Beam and self.Beam:IsValid()
  if NeedBeam then
    if not HasBeam then
      if not self.Res then
        self.Res = ResObject.MakeUClass("/Game/ArtRes/Effects/Particle/Res/Scene/BP_TaskTrackBeam.BP_TaskTrackBeam")
      end
      local BeamClass = self.Res:Get()
      if not BeamClass then
        return
      end
      self.Res:Release()
      self.Res = nil
      self.Beam = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(BeamClass, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, ScaleLimit)
      self.BeamRef = self.Beam and UnLua.Ref(self.Beam)
    end
    if self.Beam then
      self.Beam:Abs_K2_SetActorLocation_WithoutHit(self:GetPosition(), false, false)
    end
  elseif HasBeam then
    self:RemoveBeam()
  end
end

function TaskTrackItem:NeedTrackInMiniGame()
  local bIsNeedShow = true
  if _G.MiniGameModuleCmd and _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsPlaying) then
    bIsNeedShow = false
    local MiniGameModule = _G.NRCModuleManager:GetModule("MiniGameModule")
    if MiniGameModule then
      local MiniGameConfigID = MiniGameModule.ConfigId
      local RuleConf = _G.DataConfigManager:GetMinigameRuleConf(MiniGameConfigID)
      if RuleConf then
        bIsNeedShow = RuleConf.show_target
      end
    end
  end
  return bIsNeedShow
end

function TaskTrackItem:RemoveBeam()
  if self.Res then
    self.Res:Release()
    self.Res = nil
  end
  if not UE4.UObject.IsValid(self.Beam) then
    return
  end
  self.Beam:K2_DestroyActor()
  self.Beam = nil
  self.BeamRef = nil
end

function TaskTrackItem:OnDeactivate()
end

function TaskTrackItem:HasDisplayText()
  if self.TargetInSameSceneGroup then
    if not self.Valid then
      return false
    end
    return true
  else
    if self.WasInDungeon then
      return false
    end
    return true
  end
end

function TaskTrackItem:GetDisplayText()
  if self.TargetInSameSceneGroup then
    local ShowText = self.GoCondition.show_text
    if string.IsNilOrEmpty(ShowText) then
      return self:GetDistanceText()
    else
      return ShowText
    end
  elseif string.IsNilOrEmpty(self.GoCondition.show_text) or string.IsNilOrEmpty(self.GoCondition.text) then
    local SceneConf = _G.DataConfigManager:GetSceneResConf(self.TargetSceneResID, true)
    if SceneConf then
      return string.format(LuaText.umg_tasktrackgoalitem_1, SceneConf.scene_res_name)
    else
      return string.format("\230\151\160\230\179\149\232\142\183\229\143\150\229\144\136\231\144\134\231\154\132\229\156\186\230\153\175\233\133\141\231\189\174,%s", self.TargetSceneResID)
    end
  else
    return self.GoCondition.show_text
  end
end

local DistanceHint = LuaText.distance_hint

function TaskTrackItem:GetDistanceText()
  if not self.Valid then
    return ""
  end
  return string.format(DistanceHint, "", math.round(self.DistanceToPlayer / 100))
end

function TaskTrackItem:InitArea()
  if self.GoType ~= _G.ProtoEnum.TaskGoActionType.TGAT_AREA then
    return
  end
  local AreaConf = _G.DataConfigManager:GetAreaConf(self.GoData1[1])
  if not AreaConf then
    return
  end
  if AreaConf.is_point_list then
    if AreaConf.is_point_list ~= _G.ProtoEnum.AreaType.AREAT_POLYGON then
      return
    end
  else
    rawset(AreaConf, "is_point_list", 0)
  end
  local X = 0
  local Y = 0
  local Z = 0
  for _, p in ipairs(AreaConf.pos) do
    X = X + p.position_xyz[1]
    Y = Y + p.position_xyz[2]
    Z = Z + p.position_xyz[3]
  end
  local Num = #AreaConf.pos
  self.Position.X = X / Num
  self.Position.Y = Y / Num
  self.Position.Z = Z / Num
  self.Valid = true
  self.MinimapValid = true
end

function TaskTrackItem:UpdateTaskInfo(taskInfo)
  if taskInfo and self.TaskInfo.id == taskInfo.id then
    self.TaskInfo = taskInfo
  end
  if self.TaskObject:IsTrack() then
    self:Focus(true)
    self.AnimIndex = 0
    self:StartTick()
  end
end

function TaskTrackItem:GetPosition()
  if self.Valid and self.Synchronized then
    return self.Position
  else
    return nil
  end
end

function TaskTrackItem:MarkSynced()
  self.Synchronized = true
end

function TaskTrackItem:Focus(Force)
  Force = Force or false
  if not Force and not self.Valid then
    return
  end
  if not self.FocusShine then
    self.FocusTime = os.msTime()
  end
  self.FocusShine = true
end

function TaskTrackItem:ShouldForceShow()
  if self.FocusShine then
    return true
  end
  local Now = os.msTime()
  local Last = self.FocusTime
  local Diff = Now - Last
  return Diff < TrackTime
end

function TaskTrackItem:DrawFlipbook(Canvas, Flipbook, Position, Color, Rotation, DeltaTime)
  if self.AnimIndex < 0 then
    return
  end
  if self.AnimIndex >= Flipbook:GetTotalDuration() then
    self.AnimIndex = -1
    return
  end
  local Sprite = Flipbook:GetSpriteAtTime(self.AnimIndex)
  if not Sprite then
    return
  end
  if not Sprite.SourceTexture then
    return
  end
  local Texture = Sprite.SourceTexture:Get()
  if Texture then
    local TextureSize = UE4.FVector2D(Texture:Blueprint_GetSizeX(), Texture:Blueprint_GetSizeY())
    local Size = Sprite.SourceDimension
    local CoordPos = Sprite.SourceUV / TextureSize
    local CoordSize = Sprite.SourceDimension / TextureSize
    Canvas:K2_DrawTexture(Texture, Position - Size / 2, Size, CoordPos, CoordSize, Color, 2, Rotation)
  end
  self.AnimIndex = self.AnimIndex + DeltaTime
end

function TaskTrackItem:StartTick()
  _G.UpdateManager:Register(self)
end

function TaskTrackItem:StopTick()
  _G.UpdateManager:UnRegister(self)
  self:UpdateBeam()
  local Finished = self.TaskObject:CheckConditionDone(self.go_index)
  if Finished then
    self:MarkInvalid(MarkInvalidReason[2])
  end
  self:UnRegisterFinder()
end

function TaskTrackItem:GetGuidePos(GuideInfo)
  if nil == GuideInfo then
    local Pos = {
      x = 0,
      y = 0,
      z = 0
    }
    return Pos
  end
  local Pos = GuideInfo.dest_pos
  if GuideInfo.target_pos and self:SizeSquared(GuideInfo.target_pos) > 0.01 then
    Pos = GuideInfo.target_pos
  end
  return Pos
end

function TaskTrackItem:GetGuideNpcID(GuidInfo)
  if nil == GuidInfo then
    return 0
  end
  if GuidInfo.target_npc_id and GuidInfo.target_npc_id > 0 then
    return GuidInfo.target_npc_id
  end
  return GuidInfo.dest_npc_id
end

function TaskTrackItem:GetGuideRefreshContentID(GuideInfo)
  if nil == GuideInfo then
    return 0
  end
  if GuideInfo.target_refresh_content_id and GuideInfo.target_refresh_content_id > 0 then
    return GuideInfo.target_refresh_content_id
  end
  return GuideInfo.dest_refresh_content_id
end

function TaskTrackItem:OnTaskTrackReady()
  self.ScenePosList = {}
  self:RefreshScenePosList()
  if PlayerPosCache and self.Position:SizeSquared() < 0.01 then
    self:FindNPC()
  end
  if not self.TaskObject:IsTrack() then
    self:UpdateNotTrackPosition()
  end
  self:SendEvent(TaskModuleEvent.ON_TASK_TRACK_SCENE_NPC_REFRESH, self)
end

function TaskTrackItem:RefreshScenePosList()
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
    if InSameScene and self:ConstValidByGuide(guide_info) then
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

function TaskTrackItem:SizeSquared(Vector)
  if nil == Vector then
    return 0
  end
  if nil == Vector.x then
    Vector.x = 0
  end
  if nil == Vector.y then
    Vector.y = 0
  end
  if nil == Vector.z then
    Vector.z = 0
  end
  return Vector.x * Vector.x + Vector.y * Vector.y + Vector.z * Vector.z
end

function TaskTrackItem:DistSizeSquared2D(VectorA, VectorB)
  if nil == VectorA or nil == VectorB then
    return 0
  end
  if nil == VectorA.X then
    VectorA.X = 0
  end
  if nil == VectorA.Y then
    VectorA.Y = 0
  end
  if nil == VectorB.X then
    VectorB.X = 0
  end
  if nil == VectorB.Y then
    VectorB.Y = 0
  end
  local DX = VectorA.X - VectorB.X
  local DY = VectorA.Y - VectorB.Y
  return DX * DX + DY * DY
end

function TaskTrackItem:UpdateScenePosList(InPosition, InSceneID)
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return
  end
  local SceneID = InSceneID
  if nil == InSceneID or 0 == InSceneID then
    return
  end
  local Finished = self.TaskObject:CheckConditionDone(self.go_index)
  if Finished then
    return
  end
  if InPosition then
    self.ScenePosList[SceneID] = InPosition
  end
end

function TaskTrackItem:GetPosBySceneID(SceneID)
  return self.ScenePosList[SceneID]
end

function TaskTrackItem:GetTargetPosition()
  if self.Valid then
    return self.Position
  end
  return nil
end

function TaskTrackItem:CompareSceneNpcFunc(NpcA, NpcB)
  if nil == NpcA or nil == NpcB then
    return false
  end
  if NpcA:GetVisible() == false then
    return false
  end
  if NpcB:GetVisible() == false then
    return true
  end
  local DistA = NpcA.squaredDis2LocalIgnoreZ or 1000000
  local DistB = NpcB.squaredDis2LocalIgnoreZ or 1000000
  return DistA < DistB
end

function TaskTrackItem:GetMinimapValid()
  return self.MinimapValid
end

function TaskTrackItem:IsCheckConditionDone(GoIndex)
  if not self.TaskObject then
    return false
  end
  local Finished = self.TaskObject:CheckConditionDone(GoIndex)
  return Finished
end

function TaskTrackItem:RegisterFinder()
  self.FinderRef = string.format("Tracker_%d_%d_%d", self.TaskInfo.id, self.go_index, 1)
  local Searcher = self:GetSearcher()
  if Searcher then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RegisterTopKFinder, self.FinderRef, 1, self, Searcher, self, self.AdjustValidFunc, self, self.CompareSceneNpcFunc)
  elseif self.GoType == Enum.TaskGoActionType.TGAT_NPC_PRIORITY then
    self.FinderRef2 = string.format("Tracker_%d_%d_%d", self.TaskInfo.id, self.go_index, 2)
    if #self.GoData1 >= 2 then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RegisterTopKFinder, self.FinderRef, 1, self, 1 == self.GoData1[1] and self.ConstValidPriorityData1For1 or self.ConstValidPriorityData1For2, self, self.AdjustValidFunc)
    end
    if #self.GoData2 >= 2 then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RegisterTopKFinder, self.FinderRef2, 1, self, 1 == self.GoData2[1] and self.ConstValidPriorityData2For1 or self.ConstValidPriorityData2For2, self, self.AdjustValidFunc)
    end
  end
  self.bIsRegisteredFinder = true
end

function TaskTrackItem:UnRegisterFinder()
  if self.FinderRef then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.UnRegisterTopKFinder, self.FinderRef)
    self.FinderRef = nil
  end
  if self.FinderRef2 then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.UnRegisterTopKFinder, self.FinderRef2)
    self.FinderRef2 = nil
  end
  self.bIsRegisteredFinder = false
end

function TaskTrackItem:IsRegisteredFinder()
  return self.bIsRegisteredFinder
end

function TaskTrackItem:NeedRegisterFinder()
  if self.TaskObject:IsTrack() then
    return true
  end
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return false
  end
  local CurrentMapID = SceneModule.mapResId
  local Pos = self.ScenePosList[CurrentMapID]
  if Pos then
    self:UpdatePlayerPosCache()
    local DistSquared = self:DistSizeSquared2D(PlayerPosCache, Pos)
    if self:IsRegisteredFinder() then
      return DistSquared < FinderUnregisterDistanceSquared
    else
      return DistSquared < FinderRegisterDistanceSquared
    end
  end
  return false
end

return TaskTrackItem
