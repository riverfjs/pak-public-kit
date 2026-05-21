local HomeRoom = require("NewRoco/Modules/System/Home/IndoorSandbox/Scene/HomeRoom")
local HomeController = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeController")
local HomeEditEnv = require("NewRoco/Modules/System/Home/IndoorSandbox/Scene/HomeEditEnv")
local EnvVolumeProxy = require("NewRoco/Modules/System/Home/IndoorSandbox/Proxy/EnvVolumeProxy")
local EnvLightProxy = require("NewRoco/Modules/System/Home/IndoorSandbox/Proxy/EnvLightProxy")
local STATIC_ACTOR_ARRAY = UE.TArray(UE.AActor)
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local HomeWorld = Class("HomeWorld")

function HomeWorld:Ctor()
  self.bOfflineConfigInitialized = false
  self.RoomLevelInfoMaps = {}
  self.Rooms = {}
  self.Controller = HomeController(self)
  self.HomeEditEnv = HomeEditEnv(self)
  self.StyleBakedInfo = {}
  self.StyleLightInfo = {}
  self.DefaultStructBuildingLightingChannels = UE.FLightingChannels()
  self.DefaultLightParams = {}
  self.EvnSystemVolumeActors = nil
  self.LightActors = nil
  self.RoomTags = {
    "livingroom",
    "room1",
    "room2",
    "basement",
    "room3"
  }
  self.RoomId2Volume = nil
  self.RoomId2Lights = nil
  self.VolumeProxyMap = {}
  self.LightProxyMap = {}
  self.bLoadingEstablished = false
end

function HomeWorld:GetRoomById(RoomId)
  return self.Rooms[RoomId]
end

function HomeWorld:GetStyleBakedInfoByMainSubType(Main, Sub)
  local Subs = self.StyleBakedInfo[Main or -1]
  if Subs then
    return Subs[Sub or -1]
  end
end

function HomeWorld:GetStyleLightInfoByStyleId(StyleId)
  return self.StyleLightInfo[StyleId]
end

function HomeWorld:GetStyleEnvSystemSettingByStyleId(StyleId, RoomId)
  local Info = self:GetStyleLightInfoByStyleId(StyleId)
  if Info then
    local RoomStyleTOD = Info.RoomIdOverrideEnvSystemSetting[RoomId]
    local RoomStyleTODLow = Info.RoomIdOverrideEnvSystemSettingLow[RoomId]
    if RoomStyleTOD then
      if RoomStyleTODLow then
        return RoomStyleTOD, RoomStyleTODLow
      else
        return RoomStyleTOD
      end
    elseif RoomStyleTODLow then
      RoomStyleTOD = self.HomeAssetRegistry.InteriorFinishConfig.DefaultEnvSystemSetting:Find(RoomId)
      return RoomStyleTOD, RoomStyleTODLow
    else
      RoomStyleTOD = self.HomeAssetRegistry.InteriorFinishConfig.DefaultEnvSystemSetting:Find(RoomId)
      RoomStyleTODLow = self.HomeAssetRegistry.InteriorFinishConfig.DefaultEnvSystemSettingLow:Find(RoomId)
      return RoomStyleTOD, RoomStyleTODLow
    end
  end
end

function HomeWorld:GetStyleEnvLightSettingByStyleId(StyleId, RoomId, bDisableUseDefault)
  local Info = self:GetStyleLightInfoByStyleId(StyleId)
  if Info then
    local LightParams = Info.LightParams
    local LightParam = LightParams[RoomId]
    if not LightParam and not bDisableUseDefault then
      LightParam = self.DefaultLightParams[RoomId]
    end
    return LightParam
  end
end

function HomeWorld:GetEnvVolumeProxyList(RoomId)
  return self.RoomId2Volume[RoomId]
end

function HomeWorld:Instantiate(HomeInfo)
  if not self.LogTickTimer then
    self.LogTickTimer = TimerManager:CreateTimer(self, "HomeWorld", math.maxinteger, self.OnLowTick, nil, 0.1)
  else
    HomeIndoorSandbox:Ensure(false, "logical error")
  end
  if not HomeIndoorSandbox:Ensure(not self.bWorldInstantiated, "duplicate instantiate world, logical error") then
    return
  end
  self:ConditionCreateStreamingHelper()
  self.WorldCenter = UE4.FVector(self.UEWorld:GetWorldOriginX(), self.UEWorld:GetWorldOriginY(), self.UEWorld:GetWorldOriginZ())
  HomeIndoorSandbox:LogWarn("WorldCenter:", self.WorldCenter)
  self.bWorldInstantiated = true
  self:ProcWorldSync(HomeInfo)
end

function HomeWorld:ProcWorldSync(HomeInfo)
  HomeIndoorSandbox:LogWarn("ProcWorldSync", HomeInfo and HomeInfo.room_level)
  if HomeIndoorSandbox.Utils.EnableDebugDraw then
    UE4.UKismetSystemLibrary.FlushPersistentDebugLines(self.UEWorld)
  end
  self.bLoadingEstablished = false
  HomeIndoorSandbox.Server:OnNotifyHomeInfo(HomeInfo)
  self:InstantiateHomePlanes()
  self:InitProcStreamLevelActors()
  self:InstantiateRoomProps()
  self:InstantiateLights()
  self:OnWorldEstablished()
end

function HomeWorld:IsLoadEstablished()
  return self.bLoadingEstablished
end

function HomeWorld:OnWorldEstablished()
  HomeIndoorSandbox:LogDebug("OnWorldEstablished")
  self.bLoadingEstablished = true
  for Rid, Room in pairs(self.Rooms) do
    for k, v in pairs(Room.AllDecoActors) do
      k:OnInitializedByWorld()
    end
  end
end

function HomeWorld:InitProcStreamLevelActors()
  self:PreloadHomeWorld(HomeIndoorSandbox.Server.WorldData.RoomLevel, "NoPreload")
  UE.UGameplayStatics.GetAllActorsOfClass(self.UEWorld, UE.ANRCHomeBuildingStructActor, STATIC_ACTOR_ARRAY)
  for i, v in tpairs(STATIC_ACTOR_ARRAY) do
    self:OnIndoorHardDecoActorSpawned(v)
  end
end

local ACTOR_ARRAY = UE.TArray(UE.AActor)

function HomeWorld:CollectLightSettings()
  UE4.FCycleCounter.Start("HomeWorld:CollectLightSettings")
  local VolumeClass = UE.AEnvSystemVolume
  local LightClass = UE.AEnvLightActorBase
  local CurrentWorld = UE4Helper.GetCurrentWorld()
  local Volumes = {}
  local Lights = {}
  for i, Tag in pairs(self.RoomTags) do
    UE.UGameplayStatics.GetAllActorsOfClassWithTag(CurrentWorld, VolumeClass, Tag, ACTOR_ARRAY)
    Volumes[Tag] = ACTOR_ARRAY:ToTable()
  end
  for i, Tag in pairs(self.RoomTags) do
    UE.UGameplayStatics.GetAllActorsOfClassWithTag(CurrentWorld, LightClass, Tag, ACTOR_ARRAY)
    Lights[Tag] = ACTOR_ARRAY:ToTable()
  end
  UE4.FCycleCounter.Stop()
  ACTOR_ARRAY:Resize(0)
  self.EvnSystemVolumeActors = Volumes
  self.LightActors = Lights
end

function HomeWorld:InstantiateLights()
  self:InternalInstantiateLights()
end

function HomeWorld:InternalInstantiateLights()
  self:CollectLightSettings()
  local Rank = HomeIndoorSandbox.Server.WorldData.RoomLevel
  local LevelPaths = self.RankLevelToRoomId[Rank]
  local RoomId2Volume = {}
  local RoomId2Lights = {}
  for LevelPath, RoomId in pairs(LevelPaths) do
    if not RoomId2Volume[RoomId] then
      for Tag, Volumes in pairs(self.EvnSystemVolumeActors) do
        if string.find(LevelPath, Tag) then
          RoomId2Volume[RoomId] = Volumes
          for i, v in pairs(Volumes) do
            if not v.CollectDefault then
              Volumes[i] = EnvVolumeProxy(v, RoomId)
            end
          end
        end
      end
    end
    if not RoomId2Lights[RoomId] then
      for Tag, Lights in pairs(self.LightActors) do
        if string.find(LevelPath, Tag) then
          RoomId2Lights[RoomId] = Lights
          for i, v in pairs(Lights) do
            if not v.CollectDefault then
              Lights[i] = EnvLightProxy(v, RoomId)
            end
          end
        end
      end
    end
  end
  self.RoomId2Volume = RoomId2Volume
  self.RoomId2Lights = RoomId2Lights
  for RoomId, Room in pairs(self.Rooms) do
    self:ApplyRoomLightSettings(RoomId)
  end
  self:RefreshEvnVisibility()
end

function HomeWorld:ApplyRoomLightSettings(RoomId)
  local Volumes = self.RoomId2Volume[RoomId]
  local Lights = self.RoomId2Lights[RoomId]
  HomeIndoorSandbox.HomeLightServ:ApplyRoomLightSettingsByDecoration(RoomId, Volumes, Lights)
end

function HomeWorld:JudgeRoomLightVisible(RoomId)
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    return RoomId == HomeIndoorSandbox.HomeEditServ.EditRoomId
  else
    return RoomId == self:GetPlayerRoomId() or self:IsRoomOpened(RoomId) and (self.LastDoorRoomId and self.LastDoorRoomId == RoomId or self.LastDoorOtherRoomId and self.LastDoorOtherRoomId == RoomId)
  end
end

function HomeWorld:RefreshLightVisibility()
  if self.RoomId2Lights then
    for Id, Lights in pairs(self.RoomId2Lights) do
      for _, Light in pairs(Lights) do
        local Visible = self:JudgeRoomLightVisible(Id)
        if Light:IsThemeLight() then
          Light:SetActorHiddenInGame(Id ~= self.PlayerRoomId or not Visible)
        else
          HomeIndoorSandbox:LogDebug("RefreshLightVisibility Room Light", Id, Visible)
          Light:SetActorHiddenInGame(not Visible)
        end
      end
    end
  end
end

function HomeWorld:RefreshEvnVisibility()
  local RoomId = self:GetPlayerRoomId()
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    RoomId = HomeIndoorSandbox.HomeEditServ.EditRoomId
  end
  if self.RoomId2Volume then
    for Id, Volumes in pairs(self.RoomId2Volume) do
      for _, Volume in pairs(Volumes) do
        local Visible = self:JudgeRoomLightVisible(Id)
        Volume:SetActorHiddenInGame(not Visible)
        Volume:PostChanged()
      end
    end
  end
  self:RefreshLightVisibility()
end

function HomeWorld:PreloadHomeWorld(Rank, From, bDisablePlaneProcess)
  if not Rank or Rank <= 0 then
    HomeIndoorSandbox:Ensure(false, "Invalid room level", Rank)
    return
  end
  if self.PreloadingRank and self.PreloadingRank == Rank then
    HomeIndoorSandbox:LogWarn("Ignore preload", Rank)
    return
  end
  if self.bRegisterDecoActorSpawned then
    self.bRegisterDecoActorSpawned = false
    HomeIndoorSandbox:UnRegisterEvent(HomeIndoorSandbox.Event.OnIndoorHardDecoActorSpawned, self)
  end
  self.bLoadingEstablished = false
  self:ConditionCreateStreamingHelper()
  HomeIndoorSandbox:LogWarn("PreloadHomeWorld", Rank, From, self.UEWorld)
  self.PreloadingRank = Rank
  self.RoomOpenFlags = {}
  self.StreamingHelper:SwitchToRank(Rank, self.UEWorld)
  UE4.UNRCStatics.BlockTillLevelLoadCompleted(self.UEWorld)
  UE4.UNRCStatics.BlockTillLevelStreamingCompleted(self.UEWorld)
  if not bDisablePlaneProcess then
    self.bRegisterDecoActorSpawned = true
    HomeIndoorSandbox:RegisterEvent(HomeIndoorSandbox.Event.OnIndoorHardDecoActorSpawned, self, self.OnIndoorHardDecoActorSpawned)
  end
end

function HomeWorld:ConditionCreateStreamingHelper()
  if self.StreamingHelper and self.UEWorld and (not UE.UObject.IsValid(self.StreamingHelper) or not UE.UObject.IsValid(self.UEWorld)) then
    self.StreamingHelper = nil
    self.UEWorld = nil
  end
  if not self.StreamingHelper then
    self.UEWorld = UE4Helper.GetCurrentWorld()
    self.StreamingHelper = NewObject(UE.UNRCHomeLevelStreamingHelper, self.UEWorld)
    self.StreamingHelperRef = UnLua.Ref(self.StreamingHelper)
    self.StreamingHelper:Init(self.UEWorld)
  end
  self:InitHomeBakedOfflineConfig()
end

function HomeWorld:ReLoadWorldSync()
  self.bLoadingEstablished = false
  if HomeIndoorSandbox.Utils.EnableDebugDraw then
    UE4.UKismetSystemLibrary.FlushPersistentDebugLines(self.UEWorld)
  end
  self:InstantiateHomePlanes()
  self:InitProcStreamLevelActors()
  self:InstantiateRoomProps()
  self:InstantiateLights()
  self:OnWorldEstablished()
end

function HomeWorld:InternalReloadFully(HomeInfo)
  self:ProcWorldSync(HomeInfo)
end

function HomeWorld:InternalReloadDynamicRoom(RoomData)
  local TempFlags = RoomData.TempFlags
  if TempFlags.bPropsChanged then
    HomeIndoorSandbox:LogInfo("ReloadRoomProps", RoomData.RoomId)
    HomeIndoorSandbox.HomePropsServ:ReloadRoomProps(RoomData.RoomId, true)
  end
  if TempFlags.bDecosChanged then
    HomeIndoorSandbox:LogInfo("ReloadRoomDeco", RoomData.RoomId)
    HomeIndoorSandbox.HomeDecoServ:ReloadRoomDeco(RoomData.RoomId)
  end
end

function HomeWorld:ReloadWorldLayoutConditionally(RoomLayoutInfo)
  local ChangeRoomDataList = HomeIndoorSandbox.Server.WorldData:CompareUpdateLayout(RoomLayoutInfo)
  if ChangeRoomDataList and next(ChangeRoomDataList) then
    for _, ChangeRoomData in pairs(ChangeRoomDataList) do
      self:InternalReloadDynamicRoom(ChangeRoomData)
    end
  end
  HomeIndoorSandbox.Server.WorldData:RefreshComfortValue()
end

function HomeWorld:ReloadCacheWorldLayoutConditionally()
  local RoomLayoutInfo = HomeIndoorSandbox.Server.WorldData.RawRoomLayoutInfo
  self:ReloadWorldLayoutConditionally(RoomLayoutInfo)
end

function HomeWorld:ReloadWorldConditionally(HomeInfo)
  if not HomeInfo then
    return
  end
  if not HomeIndoorSandbox:InHomeIndoor() then
    HomeIndoorSandbox:Ensure(false, "!!!! LOGICAL ERROR !!!!")
    return
  end
  local bSameMaster = HomeInfo.home_owner_id == HomeIndoorSandbox.Server.MasterId
  if not bSameMaster then
    self:InternalReloadFully(HomeInfo)
    HomeIndoorSandbox.HomeAIServ:OnReloadHome()
    HomeIndoorSandbox.HomeAIServ:RefreshPairRelationship(HomeInfo.lay_egg_couple)
    HomeIndoorSandbox.EnterMapServ:RefreshFunctionBanInPlace()
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnReEnterHomeMap)
    return
  end
  local bSameLevel = HomeInfo.room_level == HomeIndoorSandbox.Server.WorldData.RoomLevel
  if not bSameLevel then
    self:InternalReloadFully(HomeInfo)
    return
  end
  local ChangeRoomDataList = HomeIndoorSandbox.Server.WorldData:CompareUpdateHomeInfo(HomeInfo)
  if ChangeRoomDataList and next(ChangeRoomDataList) then
    for _, ChangeRoomData in pairs(ChangeRoomDataList) do
      self:InternalReloadDynamicRoom(ChangeRoomData)
    end
  end
  HomeIndoorSandbox.Server.WorldData:RefreshComfortValue()
  HomeIndoorSandbox.HomeAIServ:RefreshPairRelationship(HomeInfo.lay_egg_couple)
end

function HomeWorld:SetEditEnvironmentEnabled(bEnable)
  return self.HomeEditEnv:SetEditEnvironmentEnabled(bEnable)
end

function HomeWorld:OnIndoorHardDecoActorSpawned(HardDecoActor)
  if not HomeIndoorSandbox:Ensure(self.bWorldInstantiated, "actor not in home world", HardDecoActor:GetActorId()) then
    return
  end
  if -1 == HardDecoActor.Rank then
    local LivingRoom = self.Rooms[1]
    if LivingRoom then
      HomeIndoorSandbox.HomeDecoServ:LoadHardDeco(HardDecoActor, 1)
    end
    return
  end
  local RoomId = HardDecoActor:GetBelongRoomId()
  local Room = self.Rooms[RoomId]
  if HomeIndoorSandbox:Ensure(Room, "cannot found room", RoomId) then
    Room:JoinHardDecoActor(HardDecoActor)
    local OtherRoomId = HardDecoActor:GetOtherRoomId()
    if 0 ~= OtherRoomId and OtherRoomId ~= RoomId then
      local OtherRoom = self.Rooms[OtherRoomId]
      if OtherRoom then
        OtherRoom:LinkDecoActor(HardDecoActor)
      end
    end
    HomeIndoorSandbox.HomeDecoServ:LoadHardDeco(HardDecoActor, RoomId)
  else
    HomeIndoorSandbox:Ensure(false, HardDecoActor:GetName())
  end
  HardDecoActor:OnInitializedByRoom()
end

function HomeWorld:InstantiateRoomProps()
  for Rid, _ in pairs(self.Rooms) do
    HomeIndoorSandbox.HomePropsServ:ReloadRoomProps(Rid, true)
  end
  self:RefreshRoomVisibility()
end

function HomeWorld:RefreshRoomVisibility()
  HomeIndoorSandbox:LogInfo("[Visibility] HomeWorld:RefreshRoomVisibility")
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    local EditRoomId = HomeIndoorSandbox.HomeEditServ.EditRoomId
    for Rid, Room in pairs(self.Rooms) do
      Room:SyncLinkVisible(false, EditRoomId)
    end
    for Rid, Room in pairs(self.Rooms) do
      Room:SetVisible(Rid == EditRoomId)
    end
    local Room = self.Rooms[EditRoomId]
    if Room then
      Room:SyncLinkVisible(true)
    end
  else
    local PlayerRoomId = self:GetPlayerRoomId()
    if not PlayerRoomId then
      return
    end
    for Rid, Room in pairs(self.Rooms) do
      Room:SetStaticVisible(true)
      Room:SetDynamicVisible(Rid == PlayerRoomId or self:IsRoomOpened(Rid))
    end
  end
  self:RefreshEvnVisibility()
end

function HomeWorld:GetPlayerRoomId()
  return self.PlayerRoomId
end

function HomeWorld:InstantiateHomePlanes()
  for RoomId, Room in pairs(self.Rooms) do
    HomeIndoorSandbox.HomePropsServ:ClearRoomProps(RoomId)
    Room:Destroy()
  end
  self.Rooms = {}
  self.MinRoomId = 99
  self.MaxRoomId = 0
  local Rank = HomeIndoorSandbox.Server.WorldData.RoomLevel
  for RoomId, RoomLevelInfo in pairs(self.RoomLevelInfoMaps) do
    local Room = HomeRoom(RoomId, self)
    local RankLevels = RoomLevelInfo.RankLevels
    local RoomInfo = RankLevels[Rank]
    if RoomInfo then
      self.MinRoomId = math.min(RoomId, self.MinRoomId)
      self.MaxRoomId = math.max(RoomId, self.MaxRoomId)
      HomeIndoorSandbox:LogInfo("create room", RoomId, "rank", Rank, "name", RoomLevelInfo.Name)
      RoomInfo.RoomId = RoomId
      RoomInfo.Name = RoomLevelInfo.Name
      Room:Instantiate(RoomInfo, self.WorldCenter)
      self.Rooms[RoomId] = Room
    end
  end
end

function HomeWorld:HideCurrRoomFurniture(bHide)
  local RoomId = self:GetPlayerRoomId()
  local Room = self:GetRoomById(RoomId)
  if Room then
    Room:SetDynamicVisible(not bHide)
  end
end

function HomeWorld:InitHomeBakedOfflineConfig()
  if self.bOfflineConfigInitialized then
    return
  end
  self.bOfflineConfigInitialized = true
  self.HomeAssetRegistry = UE4.UObject.Load(HomeIndoorSandbox.Enum.AssetRegistry)
  self.HomeAssetRegistryRef = UnLua.Ref(self.HomeAssetRegistry)
  local Msg1 = "\228\187\142\233\157\162\230\157\191\228\184\173\230\137\190\228\184\141\229\136\176\228\187\187\228\189\149\231\161\172\232\163\133actor"
  local Msg2 = "\228\187\142\229\156\186\230\153\175\228\184\173\229\143\145\231\142\176actor\229\177\158\228\186\142\229\164\154\228\184\170\233\157\162\230\157\191"
  local RoomLevelInfoMaps = self.RoomLevelInfoMaps
  local GUID_STR = UE.UKismetGuidLibrary.Conv_GuidToString
  local EditSpaceConfig = self.HomeAssetRegistry.LevelConfig.EditSpaceConfig
  self.RankLevelToRoomId = {}
  self.MaxRank = 0
  for _, EditSpace in tpairs(EditSpaceConfig) do
    local RoomId = EditSpace.SpaceID
    local RoomLevelInfoMap = {
      RoomId = RoomId,
      Name = EditSpace.SpaceName,
      RankLevels = {}
    }
    RoomLevelInfoMaps[RoomId] = RoomLevelInfoMap
    local ViewpointLoc = EditSpace.ViewpointLoc
    local ViewpointRot = EditSpace.ViewpointRot
    ViewpointLoc = UE.FVector(ViewpointLoc.X, ViewpointLoc.Y, ViewpointLoc.Z)
    ViewpointRot = UE.FRotator(ViewpointRot.Pitch, ViewpointRot.Yaw, 0)
    local RankLevelConfigs = EditSpace.RankLevelConfigs
    for _, RankLevel in tpairs(RankLevelConfigs) do
      local RoomLevelInfo = {
        RoomId = RoomId,
        Rank = 0,
        Planes = {},
        Levels = {},
        PlaneMap = {},
        PlaneIdToActorIds = {},
        ActorIdToPlaneId = {},
        ViewpointLoc = ViewpointLoc,
        ViewpointRot = ViewpointRot
      }
      local Rank = RankLevel.Rank
      RoomLevelInfoMap.RankLevels[Rank] = RoomLevelInfo
      RoomLevelInfo.Rank = Rank
      self.MaxRank = math.max(self.MaxRank, Rank)
      HomeIndoorSandbox:LogInfo("load room level info", RoomId, Rank)
      for _, LevelPath in tpairs(RankLevel.LevelPath) do
        HomeIndoorSandbox:LogInfo("level:", LevelPath)
        RoomLevelInfo.Levels[LevelPath] = true
        local LevelRooms = self.RankLevelToRoomId[Rank]
        if not LevelRooms then
          LevelRooms = {}
          self.RankLevelToRoomId[Rank] = LevelRooms
        end
        if LevelRooms[LevelPath] then
          HomeIndoorSandbox:LogWarn("\229\189\147\229\137\141\231\173\137\231\186\167\228\184\139\232\191\153\228\184\170\229\133\179\229\141\161\229\177\158\228\186\142\229\164\154\228\184\170\230\136\191\233\151\180\239\188\154", LevelPath, Rank, "room:", LevelRooms[LevelPath], RoomId)
        end
        LevelRooms[LevelPath] = RoomId
      end
      local PlaneIdToActorIds = RoomLevelInfo.PlaneIdToActorIds
      local ActorIdToPlaneId = RoomLevelInfo.ActorIdToPlaneId
      for ActorGuid, PlaneGuid in pairs(RankLevel.ActorToPlaneMap) do
        local PlaneId = GUID_STR(PlaneGuid)
        local ActorId = GUID_STR(ActorGuid)
        local ActorIds = PlaneIdToActorIds[PlaneId]
        if not ActorIds then
          ActorIds = {}
          PlaneIdToActorIds[PlaneId] = ActorIds
        end
        table.insert(ActorIds, ActorId)
        if HomeIndoorSandbox:Ensure(not ActorIdToPlaneId[ActorId], Msg2, "room:", RoomId, Rank, "actor:", ActorId, "plane:", PlaneId) then
          ActorIdToPlaneId[ActorId] = PlaneId
        end
        HomeIndoorSandbox:LogDebug("actor:", ActorId, "plane:", PlaneId, "room:", RoomId, "rank:", Rank)
      end
      for PlaneGuid, Area in pairs(RankLevel.PlaneData) do
        local PlaneId = GUID_STR(PlaneGuid)
        local ActorIds = PlaneIdToActorIds[PlaneId]
        if HomeIndoorSandbox:Ensure(ActorIds, Msg1, PlaneId) then
          local PlaneMasterId = ActorIds[1]
          local PlaneMin = Area.AreaVolume.Min
          local PlaneMax = Area.AreaVolume.Max
          local Rotator = Area.Normal
          local InvalidAreas = {}
          local PlaneInfo = {
            PlaneId = PlaneId,
            PlaneMin = UE.FVector(PlaneMin.X, PlaneMin.Y, PlaneMin.Z),
            PlaneMax = UE.FVector(PlaneMax.X, PlaneMax.Y, PlaneMax.Z),
            Rotator = UE.FRotator(Rotator.Pitch, Rotator.Yaw, Rotator.Roll),
            PlaneMasterId = PlaneMasterId,
            InvalidAreas = InvalidAreas,
            bIsGround = false
          }
          local UpVector = UE4.UKismetMathLibrary.GetUpVector(PlaneInfo.Rotator)
          if math.abs(UpVector.Z - 1) < 0.1 then
            PlaneInfo.bIsGround = true
          end
          local Extent = PlaneInfo.PlaneMax - PlaneInfo.PlaneMin
          if PlaneInfo.bIsGround then
            if not (math.abs(Extent.Z) <= 1) then
              HomeIndoorSandbox:Ensure(false, "\232\191\153\228\184\170\233\157\162\230\157\191\231\154\132min,max\230\140\135\229\135\186\228\184\141\230\152\175\229\156\176\233\157\162\239\188\140\230\156\137\229\143\175\232\131\189\230\156\157\229\144\145\233\148\153\228\186\134\239\188\140\230\156\157\229\144\145\239\188\154", PlaneInfo.Rotator, "min:", PlaneInfo.PlaneMin, "max:", PlaneInfo.PlaneMax, "\230\136\191\233\151\180\239\188\154", RoomId, "\231\173\137\231\186\167\239\188\154", Rank, "\233\157\162\230\157\191Id\239\188\154", PlaneId)
            end
          elseif not (math.abs(Extent.X) <= 1) and not (math.abs(Extent.Y) <= 1) then
            HomeIndoorSandbox:Ensure(false, "\232\191\153\228\184\170\233\157\162\230\157\191\231\154\132min,max\230\140\135\229\135\186\228\184\141\230\152\175\229\162\153\233\157\162\239\188\140\230\156\137\229\143\175\232\131\189\230\156\157\229\144\145\233\148\153\228\186\134\239\188\140\230\156\157\229\144\145\239\188\154", PlaneInfo.Rotator, "min:", PlaneInfo.PlaneMin, "max:", PlaneInfo.PlaneMax, "\230\136\191\233\151\180\239\188\154", RoomId, "\231\173\137\231\186\167\239\188\154", Rank, "\233\157\162\230\157\191Id\239\188\154", PlaneId)
          end
          HomeIndoorSandbox:LogInfo("\230\156\157\229\144\145\239\188\154", Area.Normal, "min:", PlaneMin, "max:", PlaneMax, "\230\136\191\233\151\180\239\188\154", RoomId, "\231\173\137\231\186\167\239\188\154", Rank, "\233\157\162\230\157\191Id\239\188\154", PlaneId)
          for i, InvalidBox in tpairs(Area.InvalidAreas) do
            local Min = InvalidBox.Min
            local Max = InvalidBox.Max
            table.insert(InvalidAreas, {
              Min = UE.FVector(Min.X, Min.Y, Min.Z),
              Max = UE.FVector(Max.X, Max.Y, Max.Z)
            })
          end
          table.insert(RoomLevelInfo.Planes, PlaneInfo)
          RoomLevelInfo.PlaneMap[PlaneInfo.PlaneId] = PlaneInfo
        end
      end
    end
  end
  self.StyleBakedInfo = {}
  if self.HomeAssetRegistry then
    local AllInteriorFinishConfig = self.HomeAssetRegistry.InteriorFinishConfig
    if AllInteriorFinishConfig then
      local InteriorFinishConfigMap = AllInteriorFinishConfig.InteriorFinishConfig
      local InteriorFinishConfigTable = InteriorFinishConfigMap:ToTable()
      for StyleId, StyleConf in pairs(InteriorFinishConfigTable) do
        local StyleFinishConf = StyleConf.InteriorFinishConfig
        local StyleFinishConfTable = StyleFinishConf:ToTable()
        for MainType, PartConf in pairs(StyleFinishConfTable) do
          if 0 ~= MainType then
            local SubTypeConf = self.StyleBakedInfo[MainType]
            if not SubTypeConf then
              SubTypeConf = {}
              self.StyleBakedInfo[MainType] = SubTypeConf
            end
            local PartMeshConfigTable = PartConf.PartMeshConfig:ToTable()
            for SubType, BakedMeshConf in pairs(PartMeshConfigTable) do
              local MeshPath = BakedMeshConf.MeshPath
              if MeshPath then
                MeshPath = UE.UNRCStatics.GetSoftObjPath(MeshPath)
              else
                MeshPath = ""
              end
              local MatPathArr = BakedMeshConf.MatPathArr
              local MatPathArray = UE.TArray("")
              if MatPathArr then
                for i, MathSoftObj in tpairs(MatPathArr) do
                  local Path = UE.UNRCStatics.GetSoftObjPath(MathSoftObj)
                  MatPathArray:Add(Path)
                end
              end
              local SubTypeStyle = SubTypeConf[SubType]
              if not SubTypeStyle then
                SubTypeStyle = {}
                SubTypeConf[SubType] = SubTypeStyle
              end
              SubTypeStyle[StyleId] = {
                StyleId = StyleId,
                MainType = MainType,
                SubType = SubType,
                MeshPath = MeshPath,
                MaterialPaths = MatPathArray
              }
              if not _G.RocoEnv.IS_SHIPPING then
                SubTypeStyle[StyleId].MaterialsDebugInfo = table.concat(MatPathArray:ToTable(), "|")
                HomeIndoorSandbox:LogInfo("InteriorFinish baked info:", StyleId, MainType, SubType, MeshPath, SubTypeStyle[StyleId].MaterialsDebugInfo)
              end
            end
          end
        end
        local EnvSystemSettingMap = StyleConf.EnvSystemSetting
        local EnvSystemSettingTable = EnvSystemSettingMap:ToTable()
        local RoomIdOverrideEnvSystemSetting = {}
        for RoomId, EnvSystemSetting in pairs(EnvSystemSettingTable) do
          if 0 == RoomId then
            Log.Error("Cannot setting room id 0 env system settings, styleId=", StyleId)
          else
            RoomIdOverrideEnvSystemSetting[RoomId] = EnvSystemSetting
          end
        end
        local EnvSystemSettingLowMap = StyleConf.EnvSystemSettingLow
        local EnvSystemSettingLowTable = EnvSystemSettingLowMap:ToTable()
        local RoomIdOverrideEnvSystemSettingLow = {}
        for RoomId, EnvSystemSetting in pairs(EnvSystemSettingLowTable) do
          if 0 == RoomId then
            Log.Error("Cannot setting room id 0 env system settings low, styleId=", StyleId)
          else
            RoomIdOverrideEnvSystemSettingLow[RoomId] = EnvSystemSetting
          end
        end
        local LightRawParam = StyleConf.LightParam:ToTable()
        local LightParams = {}
        for SpaceId, v in pairs(LightRawParam) do
          local LightParam = {}
          LightParam.Name = v.Name
          LightParam.Location = UE.FVector(v.Location.X, v.Location.Y, v.Location.Z)
          LightParam.Rotation = UE.FRotator(v.Rotation.Pitch, v.Rotation.Yaw, v.Rotation.Roll)
          LightParam.Intensity = v.Intensity
          LightParam.LightColor = UE.FColor(v.LightColor.R, v.LightColor.G, v.LightColor.B, v.LightColor.A)
          LightParam.AttenuationRadius = v.AttenuationRadius
          LightParam.InnerConeAngle = v.InnerConeAngle
          LightParam.OuterConeAngle = v.OuterConeAngle
          LightParams[SpaceId] = LightParam
        end
        self.StyleLightInfo[StyleId] = {
          RoomIdOverrideEnvSystemSetting = RoomIdOverrideEnvSystemSetting,
          RoomIdOverrideEnvSystemSettingLow = RoomIdOverrideEnvSystemSettingLow,
          LightParams = LightParams
        }
      end
      local Channels = AllInteriorFinishConfig.DefaultLightingChannels
      self.DefaultStructBuildingLightingChannels.bChannel0 = Channels.bChannel0
      self.DefaultStructBuildingLightingChannels.bChannel1 = Channels.bChannel1
      self.DefaultStructBuildingLightingChannels.bChannel2 = Channels.bChannel2
      self.DefaultStructBuildingLightingChannels.bChannel3 = Channels.bChannel3
      self.DefaultStructBuildingLightingChannels.bChannel4 = Channels.bChannel4
      self.DefaultStructBuildingLightingChannels.bChannel5 = Channels.bChannel5
      local DefaultLightParam = AllInteriorFinishConfig.DefaultLightParam:ToTable()
      local LightParams = {}
      for SpaceId, v in pairs(DefaultLightParam) do
        local LightParam = {}
        LightParam.Name = v.Name
        LightParam.Location = UE.FVector(v.Location.X, v.Location.Y, v.Location.Z)
        LightParam.Rotation = UE.FRotator(v.Rotation.Pitch, v.Rotation.Yaw, v.Rotation.Roll)
        LightParam.Intensity = v.Intensity
        LightParam.LightColor = UE.FColor(v.LightColor.R, v.LightColor.G, v.LightColor.B, v.LightColor.A)
        LightParam.AttenuationRadius = v.AttenuationRadius
        LightParam.InnerConeAngle = v.InnerConeAngle
        LightParam.OuterConeAngle = v.OuterConeAngle
        LightParams[SpaceId] = LightParam
      end
      self.DefaultLightParams = LightParams
    end
  end
end

function HomeWorld:OnLowTick()
  if HomeIndoorSandbox:InHomeIndoor() then
    local RoomId = HomeIndoorSandbox.Utils.ProjectJudgeRoom()
    if RoomId and RoomId ~= self.PlayerRoomId then
      local bFirstEnter = self.PlayerRoomId == nil
      local PrevRoomId = self.PlayerRoomId
      self.PlayerRoomId = RoomId
      HomeIndoorSandbox:LogWarn("player room id changed", RoomId)
      if bFirstEnter then
        self:RefreshRoomVisibility()
        HomeIndoorSandbox.Module:TryDisablePlayerSafePanelAfterFloorEstablished()
      else
        self:SignalPlayerTeleportFrom(PrevRoomId)
        self:SignalPlayerTeleportTo(self.PlayerRoomId)
        self:RefreshEvnVisibility()
      end
    end
  end
end

function HomeWorld:Destroy()
  TimerManager:RemoveTimer(self.LogTickTimer)
  self.LogTickTimer = nil
  self.HomeEditEnv:OnExitHome()
  self.Controller:OnExitHome()
  if UE.UObject.IsValid(self.UEWorld) and UE.UObject.IsValid(self.StreamingHelper) then
    self.StreamingHelper:UnInit(self.UEWorld)
  end
  self.StreamingHelper = nil
  self.StreamingHelperRef = nil
  self.UEWorld = nil
  self.bWorldInstantiated = false
  self.PlayerRoomId = nil
  for i, Room in ipairs(self.Rooms) do
    Room:Destroy()
  end
  self.Rooms = {}
  self.PreloadingRank = nil
  self.EvnSystemVolumeActors = nil
  self.LightActors = nil
  self.RoomId2Volume = nil
  self.RoomId2Lights = nil
  self.RoomOpenFlags = nil
  if self.bRegisterDecoActorSpawned then
    self.bRegisterDecoActorSpawned = false
    HomeIndoorSandbox:UnRegisterEvent(HomeIndoorSandbox.Event.OnIndoorHardDecoActorSpawned, self)
  end
  self.bLoadingEstablished = false
end

function HomeWorld:MarkWorldPlaneDirty()
  for i, room in pairs(self.Rooms) do
    room:MarkRoomPlaneDirty()
  end
end

function HomeWorld:TestPlayerLandPosIsValid(DesiredPos, FurnitureView)
  local bCanStepOn = HomeIndoorSandbox.Utils.CapsuleTraceValidPos(DesiredPos, 1, FurnitureView)
  return bCanStepOn
end

function HomeWorld:SignalPlayerTeleportTo(TargetRoomId)
  if not TargetRoomId then
    return
  end
  local Room = self:GetRoomById(TargetRoomId)
  if not Room then
    return
  end
  Room:SetDynamicVisible(true)
  self:RefreshHomeRoomTheme()
end

function HomeWorld:SignalPlayerTeleportFrom(SourceRoomId)
  if not self:IsRoomOpened(SourceRoomId) then
    HomeIndoorSandbox:LogDebug("SignalDoor Closed, teleport from", SourceRoomId)
    self:GetRoomById(SourceRoomId):SetDynamicVisible(false)
  end
end

function HomeWorld:InternalMarkRoomOpenFlag(RoomId, bOpen, ReasonRoomId)
  if not RoomId or 0 == RoomId then
    return
  end
  local Flags = self.RoomOpenFlags[RoomId]
  Flags = Flags or 0
  if bOpen then
    Flags = Flags | 1 << ReasonRoomId
  else
    Flags = Flags & ~(1 << ReasonRoomId)
  end
  self.RoomOpenFlags[RoomId] = Flags
end

function HomeWorld:IsRoomOpened(RoomId)
  return 0 ~= (self.RoomOpenFlags[RoomId] or 0)
end

function HomeWorld:SignalDoorClosed(DoorActor)
  if not self:IsLoadEstablished() then
    HomeIndoorSandbox:Ensure(false, "logical error")
    return
  end
  local DoorRoomId = DoorActor:GetBelongRoomId()
  local OtherRoomId = DoorActor:GetOtherRoomId()
  HomeIndoorSandbox:LogDebug("SignalDoor Closed", DoorActor, DoorRoomId)
  self:InternalMarkRoomOpenFlag(DoorRoomId, false, DoorRoomId)
  self:InternalMarkRoomOpenFlag(OtherRoomId, false, DoorRoomId)
  self:RefreshEvnVisibility()
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    return
  end
  local Room = self:GetRoomById(DoorRoomId)
  if not Room then
    return
  end
  if DoorRoomId == self.PlayerRoomId then
    Room:SetDynamicVisible(true)
    local OtherRoom = self:GetRoomById(DoorActor:GetOtherRoomId())
    if OtherRoom then
      OtherRoom:SetDynamicVisible(false)
    end
  else
    Room:SetDynamicVisible(false)
  end
end

function HomeWorld:SignalDoorTrigger(DoorActor, Trigger)
  local DoorRoomId = DoorActor:GetBelongRoomId()
  local OtherRoomId = DoorActor:GetOtherRoomId()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local bTriggerByLocalPlayer = Trigger and Trigger == (localPlayer and localPlayer.viewObj)
  if bTriggerByLocalPlayer then
    self.LastDoorRoomId = DoorRoomId
    self.LastDoorOtherRoomId = OtherRoomId
  end
end

function HomeWorld:SignalDoorOpened(DoorActor, Trigger)
  if not self:IsLoadEstablished() then
    HomeIndoorSandbox:Ensure(false, "logical error")
    return
  end
  local DoorRoomId = DoorActor:GetBelongRoomId()
  local OtherRoomId = DoorActor:GetOtherRoomId()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local bTriggerByLocalPlayer = Trigger and Trigger == (localPlayer and localPlayer.viewObj)
  if bTriggerByLocalPlayer then
    self.LastDoorRoomId = DoorRoomId
    self.LastDoorOtherRoomId = OtherRoomId
  end
  HomeIndoorSandbox:LogDebug("SignalDoor Opened", DoorActor, DoorRoomId, Trigger)
  self:InternalMarkRoomOpenFlag(DoorRoomId, true, DoorRoomId)
  self:InternalMarkRoomOpenFlag(OtherRoomId, true, DoorRoomId)
  if bTriggerByLocalPlayer then
    self:RefreshEvnVisibility()
  end
  if HomeIndoorSandbox.HomeEditServ:InEditMode() then
    return
  end
  local Room = self:GetRoomById(DoorRoomId)
  if Room then
    Room:SetDynamicVisible(true)
  end
  local OtherRoom = self:GetRoomById(DoorActor:GetOtherRoomId())
  if OtherRoom then
    OtherRoom:SetDynamicVisible(true)
  end
end

function HomeWorld:ToggleCameraCollisionEnabled(bEnabled)
  for Id, Room in pairs(self.Rooms) do
    Room:SetStaticCameraCollisionEnabled(bEnabled)
    Room:SetPropsCameraCollisionEnabled(bEnabled)
  end
end

function HomeWorld:IfNeedControlNpcVisibilityByHome(Npc)
  if Npc and Npc.config and Npc.config.id then
    return HomeIndoorSandbox.Module.data:IfNeedIgnoreNpcDuringEditingHome(Npc.config.id)
  end
  return false
end

function HomeWorld:RefreshControlNpcVisibility()
  local bInEditMode = HomeIndoorSandbox.HomeEditServ:InEditMode()
  local EditRoomId = HomeIndoorSandbox.HomeEditServ.EditRoomId
  local Npcs = NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcsByFilter, self, self.IfNeedControlNpcVisibilityByHome)
  if Npcs then
    for k, v in pairs(Npcs) do
      local bNeedHide = bInEditMode and 1 ~= EditRoomId
      v:SetVisibleForReason(not bNeedHide, NPCModuleEnum.NpcReasonFlags.HOME_EDIT_FLAG)
    end
  end
end

function HomeWorld:ToggleGroundFurnitureCameraCollision(bEnable)
  HomeIndoorSandbox:LogDebug("ToggleGroundFurnitureCameraCollision", bEnable)
  local RoomId = self:GetPlayerRoomId()
  local Room = RoomId and self:GetRoomById(RoomId)
  if Room then
    for k, v in pairs(Room.HomePlanes) do
      if not v:IsWall() then
        for Props, Actor in pairs(v.PropsDataSet) do
          Actor:SetCameraCollisionEnabled(bEnable)
        end
      end
    end
  end
end

function HomeWorld:RefreshHomeRoomTheme()
  local RoomId = self:GetPlayerRoomId()
end

return HomeWorld
