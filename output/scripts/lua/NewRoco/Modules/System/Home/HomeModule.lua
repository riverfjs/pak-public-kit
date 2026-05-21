local HomeModule = NRCModuleBase:Extend("HomeModule")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local PetStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusComponent")
local HomePetAttributeComponent = require("NewRoco.Modules.System.Home.HomePetFeed.HomePetAttributeComponent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local HomeEnum = require("NewRoco.Modules.System.Home.HomeEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local FunctionBanEnum = require("NewRoco.Modules.System.FunctionBan.FunctionBanEnum")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")

function HomeModule:OnConstruct()
  _G.HomeModuleCmd = reload("NewRoco.Modules.System.Home.HomeModuleCmd")
  self.data = self:SetData("HomeModuleData", "NewRoco.Modules.System.Home.HomeModuleData")
  local regData = self:RegPanel("Home", "UMG_HomeMain_New", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  regData.touchCount = 2
  self:RegPanel("HomeCutBlackScreen", "UMG_HomeCutBlackScreen", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("HomeChangeRoomName", "UMG_ChangeName", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("HomeExpandPanel", "UMG_ExpandRoomPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In_Dialogue", nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomeLevelRewardPanel", "UMG_LevelRewardPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomeFurnitureCreation", "UMG_FurnitureCreation", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomeComfortLevelTips", "UMG_ComfortLevelTips", _G.Enum.UILayerType.UI_LAYER_POPUP, "Appear")
  self:RegPanel("HomeVisitPanel", "HomeVisit/UMG_HomeVisitPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, "In")
  self:RegPanel("HomeCreationSuccess", "UMG_BuildSuccess", _G.Enum.UILayerType.UI_LAYER_POPUP, "In")
  self:RegPanel("HomeBlackBarAnimation", "UMG_BlackBarAnimation", _G.Enum.UILayerType.UI_LAYER_POPUP, "In")
  self:RegPanel("HomeBuildCutscenes", "UMG_BuildCutscenes", _G.Enum.UILayerType.UI_LAYER_TOP_MSG, "In")
  self:RegPanel("HomeVideo", nil, _G.Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, nil, false, "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleVideo.UMG_BattleVideo")
  self:RegPanel("HomeExpansionFinishTips", nil, _G.Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, nil, false, "/Game/NewRoco/Modules/System/TipsModule/Res/Tips/UMG_ExpansionTips.UMG_ExpansionTips")
  self:RegPanel("HomePetChoosing", "HomeFeeding/UMG_Home_PetCheckIn", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomePetFeed", "HomeFeeding/UMG_Home_Feed", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomePetDetail", "HomeFeeding/UMG_Home_Property", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_HALFSCREEN)
  self:RegPanel("SeedBag", "HomePlanting/UMG_PlantSeedsPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("HomePetFoodPocket", "HomeFeeding/UMG_Cooking_Equip", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PlantGuardPetChoosing", "HomePlanting/UMG_PlantProtectionMain", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("PlantGuardPetDetail", "HomePlanting/UMG_ProtectionPetDetailsPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("HomeFurnitureAtlasMain", "HomeFurnitureAtlas/UMG_FurnitureAtlasPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", "Out")
  self:RegPanel("FriendFurniturePopup", "HomeFurnitureAtlas/UMG_FriendFurniture", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FoodProcessingPanel", "FoodProcessing/UMG_FoodProcessingPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_POPUP_TRANS)
  self:RegPanel("HomeownerWaitConfirmation", "UMG_EnterHome_HomeownerWaitConfirmation", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("FurnitureFilterPanel", "HomeFurnitureAtlas/UMG_FurnitureAtlasScreening", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FurniturePhotoView", "UMG_ViewPhoto", _G.Enum.UILayerType.UI_LAYER_POPUP)
end

function HomeModule:OnActive()
  _G.HomeIndoorSandbox = _G.CreateSingleton("HomeIndoorSandbox", "NewRoco/Modules/System/Home/IndoorSandbox/HomeIndoorSandbox")
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, SceneEvent.LoadMapStart, self.OnSceneLeave)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, SceneEvent.BeforeLandPos, self.OnSceneLoaded)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnected)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReconnectStart)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, FunctionBanModuleEvent.OnSystemFuncBlockingTypeChange, self.OnSystemFuncBlockingTypeChangeHandler)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, NPCModuleEvent.On_NPC_Create, self.OnNpcCreate)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, NPCModuleEvent.On_NPC_LEAVE, self.OnNpcLeave)
  _G.NRCEventCenter:RegisterEvent("HomeModule", self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.OnReLoginUpdatePet)
  self:RegisterEvent(self, HomeModuleEvent.OnEnterHomeEstablished, self.OnHomeEstablish)
  self:RegisterEvent(self, HomeModuleEvent.OnHomeRoomLayoutChanged, self.OnHomeRoomLayoutChanged)
  if _G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_ACCESS_INFO_NOTIFY then
    _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_ACCESS_INFO_NOTIFY, self.OnZoneHomeAccessInfoNotify)
  end
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_UPDATE_NOTIFY, self.OnZoneSceneHomeTeamUpdateNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_INVITE_NOTIFY, self.OnZoneSceneHomeTeamInviteNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_ENTER_NOTIFY, self.OnZoneSceneHomeTeamEnterNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_ENTER_CHECK_RESULT_NOTIFY, self.OnZoneSceneHomeTeamEnterCheckResultNotify)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_HOME_VISIT_INFO_CHANGED, self.OnHomeVisitInfoChanged)
end

function HomeModule:OnNpcCreate(npc)
  if npc and npc.serverData.home_pet and npc.serverData.home_pet.home_pet_info and npc.serverData.home_pet.home_pet_info.pet_cfg_id then
    if npc.serverData.home_pet.home_pet_info.status ~= ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD then
      Log.Dump(npc.serverData.home_pet.home_pet_info, 5, "HomeModule OnNpcCreate ")
      self:OnInternalHomePetChanged(true, npc.serverData)
    else
      self:OnInternalGuardPetChange(true, npc.serverData)
    end
  end
end

function HomeModule:OnNpcLeave(npc)
  if npc and npc.serverData.home_pet and npc.serverData.home_pet.home_pet_info and npc.serverData.home_pet.home_pet_info.pet_cfg_id then
    if npc.serverData.home_pet.home_pet_info.status ~= ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD then
      Log.Dump(npc.serverData.home_pet.home_pet_info, 5, "HomeModule OnNpcLeave ")
      self:OnInternalHomePetChanged(false, npc.serverData)
    else
      self:OnInternalGuardPetChange(false, npc.serverData)
    end
  end
end

function HomeModule:HasMagicBanned(MagicType)
  if HomeIndoorSandbox:InHomeIndoor() then
    local MagicBanTypes = (self.data or {}).MagicBanTypes
    return MagicType and MagicBanTypes and MagicBanTypes and MagicBanTypes[MagicType]
  end
  return false
end

function HomeModule:OnInternalHomePetChanged(bEnter, npcInfo)
  self.data:UpdateHomePetInfo(npcInfo, bEnter)
  self:DispatchEvent(HomeModuleEvent.HomePetStatusChanged, npcInfo, bEnter)
  if npcInfo.home_pet and npcInfo.home_pet.home_pet_info.pet_cfg_id then
    if BigMapModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, npcInfo, bEnter and _G.Enum.MapModuleDataUpdateReason.HOME_PET_ENTER or _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE)
    end
    if bEnter and not self.data.bMeshEstablished then
      local npc = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, npcInfo.base.actor_id)
      if npc and npc.AIComponent then
        npc.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.HOME_LOAD)
      end
    end
  end
end

function HomeModule:OnInternalGuardPetChange(bEnter, npcInfo)
  if not npcInfo then
    return
  end
  Log.Dump(npcInfo.home_pet.home_pet_info, 5, "HomeModule OnInternalGuardPetChange ")
  if bEnter then
    self.data.HomePlantGuardPetInfo = npcInfo
  elseif self.data.HomePlantGuardPetInfo.base.actor_id == npcInfo.base.actor_id then
    self.data.HomePlantGuardPetInfo = nil
  end
end

function HomeModule:GetHomePlantGuardPetInfo()
  return self.data.HomePlantGuardPetInfo
end

function HomeModule:OnHomeEstablish()
  self.data.bMeshEstablished = true
  local npcInfoList = self.data:GetHomePetInfo()
  if not npcInfoList or 0 == #npcInfoList then
    return
  end
  local npcList = {}
  for _, v in ipairs(npcInfoList) do
    local npc = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, v.base.actor_id)
    if npc then
      table.insert(npcList, npc)
    end
  end
  for _, npc in ipairs(npcList) do
    if npc and npc.AIComponent then
      npc.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.HOME_LOAD)
    end
  end
end

function HomeModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnSceneLeave)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.BeforeLandPos, self.OnSceneLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnected)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReconnectStart)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnSystemFuncBlockingTypeChange, self.OnSystemFuncBlockingTypeChangeHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_Create, self.OnNpcCreate)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNpcLeave)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.OnReLoginUpdatePet)
  self:UnRegisterEvent(HomeModuleEvent.OnEnterHomeEstablished, self.OnHomeEstablish)
  self:UnRegisterEvent(HomeModuleEvent.OnHomeRoomLayoutChanged, self.OnHomeRoomLayoutChanged)
  if _G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_ACCESS_INFO_NOTIFY then
    _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_ACCESS_INFO_NOTIFY, self.OnZoneHomeAccessInfoNotify)
  end
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_UPDATE_NOTIFY, self.OnZoneSceneHomeTeamUpdateNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_INVITE_NOTIFY, self.OnZoneSceneHomeTeamInviteNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_ENTER_NOTIFY, self.OnZoneSceneHomeTeamEnterNotify)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_HOME_VISIT_INFO_CHANGED, self.OnHomeVisitInfoChanged)
end

local TopKFurnitureEmptyCache = {}

function HomeModule:GetTopKFurniture(k, ignoreZ)
  if not self.data or not self.data.placedInteractiveFurniture then
    table.clear(TopKFurnitureEmptyCache)
    return TopKFurnitureEmptyCache
  end
  local furnitureList = {}
  for furnitureId, furniture in pairs(self.data.placedInteractiveFurniture) do
    if furniture and furniture.viewObj then
      if furniture.CalSquaredDis2Local then
        furniture:CalSquaredDis2Local()
      end
      table.insert(furnitureList, furniture)
    end
  end
  if k >= #furnitureList then
    return furnitureList
  end
  table.sort(furnitureList, function(a, b)
    local distA = ignoreZ and (a.squaredDis2LocalIgnoreZ or a.squaredDis2Local or 9.0E9) or a.squaredDis2Local or 9.0E9
    local distB = ignoreZ and (b.squaredDis2LocalIgnoreZ or b.squaredDis2Local or 9.0E9) or b.squaredDis2Local or 9.0E9
    return distA < distB
  end)
  local result = {}
  for i = 1, math.min(k, #furnitureList) do
    result[i] = furnitureList[i]
  end
  return result
end

local NPCKlassName = {FurnitureNPC = true, HomeSceneNPC = true}

function HomeModule:OnTick(deltaTime)
  local state = _G.ZoneServer:GetOnlineState()
  if state == OnlineState.EnteredCell then
    if not self.data then
      return
    end
    for _, furnitureNpc in pairs(self.data.placedInteractiveFurniture) do
      if furnitureNpc and NPCKlassName[furnitureNpc.className] then
        furnitureNpc:UpdateByDistance(deltaTime)
      end
    end
  end
  if _G.GlobalConfig.bShouldShowGMPetLayEggArea then
    self:DrawPetLayEggArea()
  end
end

function HomeModule:OnConnected()
  HomeIndoorSandbox:LogWarn("OnConnected")
  self:CloseEditPanels()
end

function HomeModule:OnDisconnected()
  self.bRequiredForceEnterEditPanel = false
  self:ClosePanel("HomeFurnitureCreation")
  if self:HasPanel("PlantGuardPetChoosing") then
    self:ClosePanel("PlantGuardPetChoosing")
  end
end

function HomeModule:OnInteractFurnitureEnter(guid, furnitureObj)
  if not guid or not furnitureObj then
    return
  end
  if not self.data:GetPlacedInteractiveFurniture(guid) then
    self.data:SetPlacedInteractiveFurniture(guid, furnitureObj)
    if not self.data:GetPairNestAndPet(guid) then
      local homePetList = self.data:GetHomePetInfo()
      if homePetList then
        for _, petInfo in ipairs(homePetList) do
          if petInfo.home_pet.home_pet_info.furniture_guid == guid then
            self.data:UpdatePairNestAndPet(guid, petInfo)
          end
        end
      end
    end
  else
    Log.Error("furniture guid duplicate")
    return
  end
  for _, v in ipairs(self.data.placedInteractiveFurniture) do
    if v.QueryCurrentStatus then
      v:QueryCurrentStatus()
    end
  end
end

function HomeModule:OnInteractFurnitureLeave(guid)
  if not guid then
    return
  end
  self.data:SetPlacedInteractiveFurniture(guid, nil)
end

function HomeModule:OnCmdGetInteractiveFurniture()
  return self.data.placedInteractiveFurniture
end

function HomeModule:OnSceneLeave(_, bReconnecting, Id)
  local Module = NRCModuleManager:GetModule("SceneModule")
  if Module then
    local MapResId = Module:GetCurrentMapResId()
    if 30001 ~= MapResId then
      HomeIndoorSandbox:LogWarn("OnMapLeave", Id, MapResId)
      self:TryExitHomeIndoor()
    end
  end
  self:CloseHomeownerWaitConfirmationPanel()
end

function HomeModule:TryExitHomeIndoor()
  if HomeIndoorSandbox:InHomeIndoor() then
    HomeIndoorSandbox:LogWarn("ExitHomeIndoor")
    HomeIndoorSandbox:ReqExitHome(true)
  end
end

function HomeModule:TryDisablePlayerSafePanelAfterFloorEstablished()
  self:DispatchEvent(HomeModuleEvent.OnEnterHomeEstablished)
end

function HomeModule:OnSceneLoaded(bReconnecting)
  local Module = NRCModuleManager:GetModule("SceneModule")
  if Module then
    local MapResId = Module:GetCurrentMapResId()
    if 10003 ~= MapResId then
      HomeIndoorSandbox:LogWarn("Mark big world home room level removed, ( load plot )", bReconnecting, self.LoadedBigWorldHomeRoomLevel)
      self.LoadedBigWorldHomeRoomLevel = nil
    end
    if 30001 == MapResId then
      local notify = Module:GetCurrentZoneSceneTeleportNotify()
      HomeIndoorSandbox:LogWarn("OnSceneLoaded", bReconnecting, notify.home_room_level)
      HomeIndoorSandbox.World:PreloadHomeWorld(notify.home_room_level, "ZoneSceneTeleportNotify", true)
    else
      self:TryLoadHomePlotStreamingLevel("OnSceneLoaded")
    end
  end
end

function HomeModule:TryLoadHomePlotStreamingLevel(Reason)
  local Module = NRCModuleManager:GetModule("SceneModule")
  if not Module then
    return
  end
  local MapId = Module:GetCurrentMapResId()
  if 10003 == MapId then
    local RoleInfo = NRCModuleManager:GetModule("PlayerModule").playerModuleNetCenter.roleInfo
    local BriefInfo = RoleInfo and (not RoleInfo.home_basic_info or RoleInfo.home_basic_info.target_home_info or RoleInfo.home_basic_info.my_home_info)
    local RoomLevel = BriefInfo and BriefInfo.room_level or 0
    local ZoneSceneTeleportNotify = Module:GetCurrentZoneSceneTeleportNotify()
    if RoomLevel < ZoneSceneTeleportNotify.home_room_level then
      HomeIndoorSandbox:LogWarn("unbelievable", ZoneSceneTeleportNotify.home_room_level, RoomLevel)
      Log.Dump(RoleInfo.home_basic_info, 10, "ROLE_HOME_BASIC")
      RoomLevel = ZoneSceneTeleportNotify.home_room_level
    end
    local Conf = DataConfigManager:GetHomeGlobalConfig("home_bigworld_level_" .. RoomLevel)
    if Conf and Conf.str then
      local bLevelDirty = self.LoadedBigWorldHomeRoomLevel ~= Conf.str
      if bLevelDirty then
        HomeIndoorSandbox:LogDebug("[deprecated] load plot streaming room", RoomLevel, Conf.str, Reason)
        if self.LoadedBigWorldHomeRoomLevel then
        end
        self.LoadedBigWorldHomeRoomLevel = Conf.str
      end
    else
      HomeIndoorSandbox:Ensure(false, "cannot found invalid plot streaming room", RoomLevel)
    end
  end
end

function HomeModule:OnEnterSceneFinishNtyAck(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  self.bNeedLandPosAll3pPlayers = false
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, false)
  local Module = NRCModuleManager:GetModule("SceneModule")
  if Module then
    local MapResId = Module:GetCurrentMapResId()
    if 30001 == MapResId then
      local bInHomeIndoor = HomeIndoorSandbox:InHomeIndoor()
      HomeIndoorSandbox.HomeEditServ:OnEnterScene()
      HomeIndoorSandbox:LogWarn("OnEnterSceneFinishNtyAck", bInHomeIndoor, (notify and notify.home_info).room_level, isReconnecting, isEnteringCell, preMapId, mapID)
      Log.Dump(notify.home_info, 10, "HOME_INFO")
      if bInHomeIndoor then
        HomeIndoorSandbox.World:ReloadWorldConditionally(notify.home_info)
      else
        HomeIndoorSandbox:ReqEnterHomeScene(notify.home_info)
      end
      for _, v in ipairs(self.data.placedInteractiveFurniture) do
        if v.QueryCurrentStatus then
          v:QueryCurrentStatus()
        end
      end
      if not isReconnecting then
        _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
        _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
        HomeIndoorSandbox.HomeTipsServ:ShowEnterHomeZoneTip()
      end
      HomeIndoorSandbox.HomeTipsServ:CheckEnterPublishFailedDuringVisiting()
    elseif 10003 == MapResId then
      _G.GlobalConfig.bShouldUseGMPetCounterPercentage = false
      if _G.AppMain:HasDebug() then
        _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.ClearGMPetCounterPercentage)
      end
    end
  end
end

function HomeModule:OnHomeRoomLayoutChanged(RoomData)
  HomeIndoorSandbox:LogDebug("OnHomeRoomLayoutChanged", RoomData)
  if HomeIndoorSandbox:InHomeIndoor() then
    HomeIndoorSandbox.HomeAIServ:UpdatePOIs(RoomData)
  end
end

function HomeModule:OnZoneHomeAccessInfoNotify(Notify)
  HomeIndoorSandbox.HomeTipsServ:TryProcessHomeBanNotify(Notify.access_info)
end

function HomeModule:OnHomeBasicInfoChangeNotify(action)
  Log.Dump(action.home_basic_info, 10, "HOME_INFO CHANGED")
  if not action.home_basic_info then
    return
  end
  local SelfHomeInfo = action.home_basic_info.my_home_info or {}
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.serverData.base.logic_id == SelfHomeInfo.home_owner_id then
    local src_home_info = SelfHomeInfo
    local dst_home_info = player.serverData.home_basic_info.my_home_info
    local old_home_level = dst_home_info and dst_home_info.home_level or 0
    local new_home_level = src_home_info and src_home_info.home_level or 0
    if src_home_info then
      if not dst_home_info then
        dst_home_info = {}
        player.serverData.home_basic_info.my_home_info = dst_home_info
      end
      for k, v in pairs(src_home_info) do
        dst_home_info[k] = v
      end
    else
      player.serverData.home_basic_info.my_home_info = src_home_info
    end
    src_home_info = action.home_basic_info.target_home_info
    dst_home_info = player.serverData.home_basic_info.target_home_info
    if src_home_info then
      if not dst_home_info then
        dst_home_info = {}
        player.serverData.home_basic_info.target_home_info = dst_home_info
      end
      for k, v in pairs(src_home_info) do
        dst_home_info[k] = v
      end
    else
      player.serverData.home_basic_info.target_home_info = src_home_info
    end
    if old_home_level ~= new_home_level and NRCModuleManager:DoCmd(FarmModuleCmd.OnCmdGetIsInFarm) then
      local Data = {
        newExp = 0,
        newLevel = new_home_level,
        oldExp = 0,
        oldLevel = old_home_level,
        addExp = 0,
        targetMaxExp = 0
      }
      HomeIndoorSandbox.HomeTipsServ:ShowAddExpTip(Data)
    end
    NRCModuleManager:DoCmd(FarmModuleCmd.OnHomeBasicInfoChangeNotify, action)
  end
  self:TryLoadHomePlotStreamingLevel("InfoChanged")
  if ENABLE_LOCAL_HOME_SERVER then
    return
  end
  local Reason = action.home_basic_info.reason
  if HomeIndoorSandbox:InLocalMasterIndoor() then
    if SelfHomeInfo.home_owner_id == HomeIndoorSandbox.Server.MasterId then
      local HomeLevel = HomeIndoorSandbox.Server.WorldData.HomeLevel or 0
      local HomeExp = HomeIndoorSandbox.Server.WorldData.HomeExp or 0
      local NewHomeLevel = SelfHomeInfo.home_level or 0
      local NewHomeExp = SelfHomeInfo.home_experience or 0
      HomeIndoorSandbox.Server.WorldData.HomeLevel = NewHomeLevel
      HomeIndoorSandbox.Server.WorldData.HomeExp = NewHomeExp
      HomeIndoorSandbox.Server.WorldData.HomeComfortLevel = SelfHomeInfo.home_comfort_level
      HomeIndoorSandbox.Server.WorldData.HomeAccessInfo = SelfHomeInfo.access_info
      HomeIndoorSandbox.Server.WorldData.RoomExpansionInfo = SelfHomeInfo.room_expansion_info
      if HomeLevel ~= NewHomeLevel or HomeExp ~= NewHomeExp then
        local CurLeveBaseConf = DataConfigManager:GetHomeLevelConf(HomeLevel, true)
        local NewHomeLevelBaseConf = DataConfigManager:GetHomeLevelConf(NewHomeLevel, true)
        NewHomeExp = NewHomeExp - (NewHomeLevelBaseConf and NewHomeLevelBaseConf.need_exp or 0)
        HomeExp = HomeExp - (CurLeveBaseConf and CurLeveBaseConf.need_exp or 0)
        local Data = {
          newExp = NewHomeExp,
          newLevel = NewHomeLevel,
          oldExp = HomeExp,
          oldLevel = HomeLevel,
          addExp = 0,
          targetMaxExp = 0
        }
        if HomeLevel == NewHomeLevel then
          Data.addExp = NewHomeExp - HomeExp
        end
        local NewHomeLevelConf = DataConfigManager:GetHomeLevelConf(NewHomeLevel + 1, true)
        local NeedExp = NewHomeLevelConf and NewHomeLevelConf.need_exp or NewHomeLevelBaseConf.need_exp
        Data.targetMaxExp = NeedExp - (NewHomeLevelBaseConf and NewHomeLevelBaseConf.need_exp or 0)
        if HomeLevel ~= NewHomeLevel or NewHomeLevelConf then
          HomeIndoorSandbox.HomeTipsServ:ShowAddExpTip(Data)
        end
      end
      local Status = HomeIndoorSandbox.Server:GetExpansionStatus(SelfHomeInfo.room_expansion_info, SelfHomeInfo.room_level)
      if Status == HomeIndoorSandbox.Enum.EnmExpandStatus.None and SelfHomeInfo.room_level == HomeIndoorSandbox.Server.WorldData.RoomLevel then
        local RoomConf = DataConfigManager:GetRoomConf(HomeIndoorSandbox.Server.WorldData.RoomLevel + 1, true)
        if RoomConf and NewHomeLevel >= RoomConf.home_level and HomeLevel ~= NewHomeLevel then
          HomeIndoorSandbox.HomeTipsServ:ShowStartExpandTip()
        end
      end
      if Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_LAYOUT_ROLLBACK then
        HomeIndoorSandbox.World:ReloadWorldConditionally(SelfHomeInfo)
      elseif Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_PLACE_PET_CHANGED then
        HomeIndoorSandbox.Server.WorldData:UpdateFurnitureBindingInfo(SelfHomeInfo)
      end
      if HomeLevel ~= NewHomeLevel then
        HomeIndoorSandbox:DispatchEvent(HomeModuleEvent.OnVisitingRoomLevelChanged, NewHomeLevel)
      end
    else
      HomeIndoorSandbox:Ensure(false, "\230\136\145\231\154\132\229\174\182\229\155\173\230\149\176\230\141\174\232\162\171\232\176\129\228\191\174\230\148\185\228\186\134\239\188\159\239\188\159\239\188\159", HomeIndoorSandbox.Server.MasterId, SelfHomeInfo.home_owner_id)
    end
    HomeIndoorSandbox.HomeTipsServ:CheckEnterPublishFailedDuringVisiting(SelfHomeInfo, Reason)
    HomeIndoorSandbox.HomeAIServ:RefreshPairRelationship(SelfHomeInfo.lay_egg_couple)
  elseif HomeIndoorSandbox:InHomeIndoor() then
    local MasterId = HomeIndoorSandbox.Server.MasterId
    if MasterId == SelfHomeInfo.home_owner_id and SelfHomeInfo.access_info then
      local is_violation = (SelfHomeInfo.access_info.violation_info or {}).is_violation
      local is_banned = (SelfHomeInfo.access_info.ban_info or {}).is_banned
      if is_violation or is_banned then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
        return
      end
    end
    HomeIndoorSandbox.HomeAIServ:RefreshPairRelationship(SelfHomeInfo.lay_egg_couple)
    if Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_LAYOUT_ROLLBACK or Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_LAYOUT_CHANGED or Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_LAYOUT_CLEAR then
      if MasterId == SelfHomeInfo.home_owner_id then
        self:InternalNotifyReloadHomeIndoor(SelfHomeInfo)
      else
        HomeIndoorSandbox:Ensure(false, "\230\136\145\229\156\168\231\154\132\229\174\182\229\155\173\230\149\176\230\141\174\232\162\171\232\176\129\228\191\174\230\148\185\228\186\134\239\188\159\239\188\159\239\188\159", MasterId, SelfHomeInfo.home_owner_id)
      end
    end
  elseif _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
    local is_banned = (SelfHomeInfo.access_info.ban_info or {}).is_banned
    local is_violation = (SelfHomeInfo.access_info.violation_info or {}).is_violation
    local is_local = SelfHomeInfo.home_owner_id == _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if is_banned then
      if is_local then
        HomeIndoorSandbox.HomeTipsServ:TryProcessHomeBanNotify(SelfHomeInfo.access_info)
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
      end
    elseif is_violation and not is_local then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
    end
  end
end

function HomeModule:OnHomeBasicVisitorEnterHomeNotify(Notify)
  HomeIndoorSandbox:LogDebug("OnHomeBasicVisitorEnterHomeNotify", Notify.name, Notify.actor_id)
  self:DispatchEvent(HomeIndoorSandbox.Event.OnHomeBasicVisitorEnterHomeNotify, Notify)
  if Notify.is_home_owner and HomeIndoorSandbox:InOtherHomeIndoor() then
    HomeIndoorSandbox.HomeTipsServ:CheckAndShowMasterEditNotify()
    HomeIndoorSandbox.HomeTipsServ:ShowHomeMasterComingTips(Notify.name)
  elseif not Notify.is_home_owner and HomeIndoorSandbox:InOtherHomeIndoor() then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Notify.actor_id)
    if not player or not player.isLocal then
      HomeIndoorSandbox.HomeTipsServ:ShowHomeGuestComingTips(Notify.name)
    end
  elseif (HomeIndoorSandbox:InLocalMasterIndoor() or self:InLocalMasterFarm()) and not Notify.is_home_owner then
    HomeIndoorSandbox.HomeTipsServ:ShowHomeGuestComingTips(Notify.name)
  end
  local enteringPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Notify.actor_id)
  local bEnteringPlayerNotLocal = not enteringPlayer or not enteringPlayer.isLocal
  if bEnteringPlayerNotLocal and HomeIndoorSandbox:InHomeIndoor() then
    self:ProcessVisitorComeIn()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Notify.actor_id)
  if player then
    NRCModuleManager:DoCmd(PlayerModuleCmd.SetWaitToPlayVisitorAppearEffect, player.serverData.base.logic_id)
    HomeIndoorSandbox:LogDebug("OnHomeBasicVisitorEnterHomeNotify player need effect", Notify.actor_id, player.serverData.base.logic_id)
  end
end

function HomeModule:OnHomeBasicVisitorLeavingHomeNotify(Notify)
  HomeIndoorSandbox:LogDebug("OnHomeBasicVisitorLeavingHomeNotify", Notify.name, Notify.actor_id, Notify.is_home_owner)
  self:DispatchEvent(HomeIndoorSandbox.Event.OnHomeBasicVisitorLeavingHomeNotify, Notify)
  if Notify.is_home_owner and HomeIndoorSandbox:InOtherHomeIndoor() then
    HomeIndoorSandbox.HomeTipsServ:ShowHomeMasterLeavingTips(Notify.name)
  elseif not Notify.is_home_owner and HomeIndoorSandbox:InOtherHomeIndoor() then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Notify.actor_id)
    if not player or not player.isLocal then
      HomeIndoorSandbox.HomeTipsServ:ShowHomeGuestLeavingTips(Notify.name)
    end
  elseif (HomeIndoorSandbox:InLocalMasterIndoor() or self:InLocalMasterFarm()) and not Notify.is_home_owner then
    HomeIndoorSandbox.HomeTipsServ:ShowHomeGuestLeavingTips(Notify.name)
  end
end

function HomeModule:InLocalMasterFarm()
  return _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) and FarmUtils.IsCurrentHomeOwner()
end

function HomeModule:InHome()
  return _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) or HomeIndoorSandbox:InHomeIndoor()
end

function HomeModule:InOtherHome()
  return _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) and not FarmUtils.IsCurrentHomeOwner() or HomeIndoorSandbox:InOtherHomeIndoor()
end

function HomeModule:InMyHome()
  return self:InLocalMasterFarm() or HomeIndoorSandbox:InLocalMasterIndoor()
end

function HomeModule:LandPos_All3pPlayers(bEvalReloadCondition)
  HomeIndoorSandbox:LogDebug("LandPos_All3pPlayers()", bEvalReloadCondition)
  if bEvalReloadCondition and not self.bNeedLandPosAll3pPlayers then
    return
  end
  self.bNeedLandPosAll3pPlayers = false
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local PlayerList = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  for _, player in ipairs(PlayerList) do
    if player ~= LocalPlayer then
      player:LandPos(player:GetActorLocation())
    end
  end
end

function HomeModule:InternalNotifyReloadHomeIndoor(HomeInfo)
  local HomeName = HomeIndoorSandbox.Server.WorldData.HomeName
  local Title = LuaText.TIPS
  local Content = LuaText.home_reloading_tips
  local Context = _G.DialogContext()
  local CountDown = DataConfigManager:GetHomeGlobalConfig("home_reloading_auto_confirm_time").num
  Context:SetTitle(Title):SetContent(Content):SetMode(_G.DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.onlinemodule_11, nil):SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1):SetCountdown(_G.DialogContext.Mode.OK, CountDown):SetCallback(nil, function(OK)
    if OK then
      self:StartTransitionUI(function()
        self.bNeedLandPosAll3pPlayers = true
        HomeIndoorSandbox.World:ReloadWorldConditionally(HomeInfo)
        self.StopTransitionUIDelay = DelayManager:DelaySeconds(1, function()
          self.StopTransitionUIDelay = nil
          self:StopTransitionUI()
        end)
      end)
    else
      self:ReqLeavePlayerHomeIndoor()
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function HomeModule:OnOpenPanel(PanelData)
end

function HomeModule:OnClosePanel(PanelData)
  if PanelData.panelName == "Home" then
    self.bRequiredForceEnterEditPanel = false
    HomeIndoorSandbox.World.Controller:ReqExitEdit()
  elseif self.bRequiredForceEnterEditPanel then
    self.bRequiredForceEnterEditPanel = false
    HomeIndoorSandbox:LogWarn("try enter editor panel wait", PanelData.panelName, "closed")
    self:OpenHomeMainPanel(true)
  end
end

function HomeModule:InPanelOpenForbiddenStatus()
  if NRCPanelManager:IsLoadingPanel("HomeModule", "HomeFurnitureAtlasMain") then
    HomeIndoorSandbox:LogWarn("IsLoadingPanel HomeFurnitureAtlasMain")
    return true
  end
  if NRCPanelManager:IsLoadingPanel("HomeModule", "Home") then
    HomeIndoorSandbox:LogWarn("IsLoadingPanel Home")
    return true
  end
  if self:HasPanel("HomeFurnitureAtlasMain") then
    HomeIndoorSandbox:LogWarn("HasPanel HomeFurnitureAtlasMain")
    return true
  end
  if self:HasPanel("Home") then
    HomeIndoorSandbox:LogWarn("HasPanel Home")
    return true
  end
  return false
end

function HomeModule:OpenHomeMainPanel(bForce)
  if _G.GlobalConfig.DebugOpenUI then
    self:OpenPanel("Home")
    return
  end
  if _G.ZoneServer:IsUpstreamLocked() then
    return
  end
  if self:InPanelOpenForbiddenStatus() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "HomeModule:OpenHomeMainPanel")
  HomeIndoorSandbox.World.Controller:ReqEnterEditMainPanel()
  self.bRequiredForceEnterEditPanel = bForce and not HomeIndoorSandbox.HomeEditServ.bPendingEnterEditMode
  if not self.bRequiredForceEnterEditPanel then
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  end
  if HomeIndoorSandbox.HomeEditServ.bPendingEnterEditMode then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, true)
  end
end

function HomeModule:StartTransitionUI(OnFadeInFinish, OnFadeOutFinish)
  if self.StopTransitionUIDelay then
    DelayManager:CancelDelayById(self.StopTransitionUIDelay)
    self.StopTransitionUIDelay = nil
  end
  self:OpenPanel("HomeCutBlackScreen", OnFadeInFinish, OnFadeOutFinish)
end

function HomeModule:StopTransitionUI(bImmediately)
  if self.StopTransitionUIDelay then
    DelayManager:CancelDelayById(self.StopTransitionUIDelay)
    self.StopTransitionUIDelay = nil
  end
  if bImmediately then
    self:ClosePanel("HomeCutBlackScreen")
  elseif self:HasPanel("HomeCutBlackScreen") then
    local Panel = self:GetPanel("HomeCutBlackScreen")
    if Panel then
      Panel:DoFadeOut()
    end
  else
    self:ClosePanel("HomeCutBlackScreen")
  end
end

function HomeModule:IsHomeExpandEstablished()
  return HomeIndoorSandbox.Server.WorldData:GetExpansionStatus() == HomeIndoorSandbox.Enum.EnmExpandStatus.ExpandEstablished
end

function HomeModule:OpenHomeExpandPanel(Callback)
  Callback = Callback or HomeIndoorSandbox.DummyFunction
  if not HomeIndoorSandbox:InLocalMasterIndoor() then
    Callback(false)
    return
  end
  if self:IsHomeExpandEstablished() then
    if HomeIndoorSandbox.World.Controller:ReqUpgradeHome() then
      HomeIndoorSandbox:DebugTips("\232\175\183\230\177\130\230\137\169\229\187\186\229\174\140\230\136\144")
    end
    Callback(false)
    return
  end
  if not DataConfigManager:GetRoomConf(HomeIndoorSandbox.Server.WorldData.RoomLevel + 1, true) then
    HomeIndoorSandbox:DebugTips("\229\183\178\231\187\143\232\190\190\229\136\176\228\186\134\230\156\128\229\164\167\231\173\137\231\186\167\239\188\140\230\151\160\230\179\149\229\134\141\232\191\155\232\161\140\230\137\169\229\187\186")
    Callback(false)
    return
  end
  HomeIndoorSandbox.Server:ReqTaskInfoForExpandRoom(function(bSuccess)
    if not bSuccess then
      Callback(false)
      return
    end
    if not HomeIndoorSandbox:InLocalMasterIndoor() then
      Callback(false)
      return
    end
    self:OpenPanel("HomeExpandPanel")
    local bOpenSuccess = self:IsPanelInOpening("HomeExpandPanel")
    Callback(bOpenSuccess)
  end)
end

function HomeModule:OpenHomeVisitHistoryPanel()
  self:PreLoadPanel("HomeVisitPanel")
  HomeIndoorSandbox.Server:ReqHomeVisitHistoryInfo(function(bSuccess)
    if bSuccess then
      self:OpenPanel("HomeVisitPanel")
    end
  end)
end

function HomeModule:OpenHomeFurnitureExchangePanel(ProtoData, ExtraInfo)
  HomeIndoorSandbox.World.Controller:EnterFurnitureCreation(ProtoData, ExtraInfo)
end

function HomeModule:OpenHomeFurnitureCreationResult(FurnitureConf, SpawnedActor, FurnitureSpawnTrans)
  self:OpenPanel("HomeCreationSuccess", FurnitureConf, SpawnedActor, FurnitureSpawnTrans)
end

function HomeModule:OpenHomeLevelRewardPanel(InProtoData)
  if _G.GlobalConfig.DebugOpenUI then
    self:OpenPanel("HomeLevelRewardPanel")
    return
  end
  if InProtoData then
    self:OpenPanel("HomeLevelRewardPanel", InProtoData)
    return
  end
  HomeIndoorSandbox.Server:ReqHomeLeveRewardInfos(function(bSuccess, protoData)
    if bSuccess then
      self:OpenPanel("HomeLevelRewardPanel", protoData)
    end
  end)
end

function HomeModule:OpenHomeChangeRoomNamePanel(RoomId, OnChanged)
  self:OpenPanel("HomeChangeRoomName", RoomId, OnChanged)
end

function HomeModule:ReqEnterPlayerHomeIndoor(PlayUin, Callback, OnSuccess, OnFailed, bDisableReqToEnterHome, TargetHomeSceneType, worldMapConfId)
  local Tips
  local Title = LuaText.TIPS
  local OkBtnText = LuaText.YES
  local NoBtnText = LuaText.NO
  local OkBtnClickFunc, NoBtnClickFunc, NullClickFunc, CloseBtnClickFunc
  local _PlayUin = PlayUin
  local _Callback = Callback
  local _OnSuccess = OnSuccess
  local _OnFailed = OnFailed
  local _bDisableReqToEnterHome = bDisableReqToEnterHome
  local _TargetHomeSceneType = TargetHomeSceneType
  local _worldMapConfId = worldMapConfId
  
  local function EnterHome()
    if not _bDisableReqToEnterHome then
      _G.HomeIndoorSandbox.Server:ReqEnterHomeIndoor(_Callback, _PlayUin, _TargetHomeSceneType, _worldMapConfId)
    end
    if _OnSuccess then
      _OnSuccess()
    end
  end
  
  local function HomeownerWaitConfirmation()
    if _OnFailed then
      _OnFailed()
    end
    local reason = TargetHomeSceneType == ProtoEnum.ZoneSceneHomeEnterReq.HomeSceneType.HomeSceneType_Plant and ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT or ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME
    _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSendZoneSceneHomeTeamCreateReq, reason, _worldMapConfId)
  end
  
  NullClickFunc = _OnFailed
  CloseBtnClickFunc = _OnFailed
  local homeOwnershipStatus = self:GetPlayerHomeOwnershipStatus(_PlayUin)
  if homeOwnershipStatus == HomeEnum.HomeOwnershipStatus.OnLineOwnerSelf then
    bDisableReqToEnterHome = false
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if visitorList and #visitorList > 1 then
      Title = LuaText.oline_owner_enter_home_tips_title
      Tips = LuaText.oline_owner_enter_home_tips_text
      OkBtnText = LuaText.oline_owner_enter_home_button_yes
      NoBtnText = LuaText.oline_owner_enter_home_button_no
      OkBtnClickFunc = HomeownerWaitConfirmation
      NoBtnClickFunc = EnterHome
    else
      Title = LuaText.owner_enter_home_tips_title
      Tips = LuaText.owner_enter_home_tips_text
      OkBtnClickFunc = EnterHome
      NoBtnClickFunc = _OnFailed
    end
  elseif homeOwnershipStatus == HomeEnum.HomeOwnershipStatus.OnLineOwnerOther then
    Title = LuaText.owner_enter_home_tips_title
    local Name = self:GetOnLinePlayerName(_PlayUin)
    Tips = string.format(LuaText.owner_enter_friends_home_tips_text, Name)
    OkBtnClickFunc = EnterHome
    NoBtnClickFunc = _OnFailed
  elseif homeOwnershipStatus == HomeEnum.HomeOwnershipStatus.OnLineMemberOther then
    local Name = self:GetOnLinePlayerName(_PlayUin)
    Title = LuaText.visitor_enter_home_tips_title
    Tips = string.format(LuaText.visitor_enter_home_tips_text, Name)
    OkBtnClickFunc = EnterHome
    NoBtnClickFunc = _OnFailed
  elseif homeOwnershipStatus == HomeEnum.HomeOwnershipStatus.OffLineSelf or homeOwnershipStatus == HomeEnum.HomeOwnershipStatus.OffLineOther then
    if EnterHome then
      EnterHome()
    end
    return true
  end
  local Ctx = _G.DialogContext()
  Ctx:SetTitle(Title)
  Ctx:SetContent(Tips)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetButtonText(OkBtnText, NoBtnText)
  Ctx:SetForceEnableFullScreenBtn()
  Ctx:SetCancelAnyway(true)
  Ctx:SetCallback(self, function(_, IsOK, CancelType)
    if IsOK then
      if OkBtnClickFunc then
        OkBtnClickFunc()
      end
    elseif CancelType == CommonBtnEnum.DialogCancelType.BtnClickType then
      if NoBtnClickFunc then
        NoBtnClickFunc()
      end
    elseif CancelType == CommonBtnEnum.DialogCancelType.NullClickType then
      if NullClickFunc then
        NullClickFunc()
      end
    elseif CancelType == CommonBtnEnum.DialogCancelType.CloseClickType then
      if CloseBtnClickFunc then
        CloseBtnClickFunc()
      end
    elseif NullClickFunc then
      NullClickFunc()
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function HomeModule:ReqLeavePlayerHomeIndoor(Callback)
  self:OnZoneSceneHomeTeamQueryReq(function()
    HomeIndoorSandbox.Server:ReqExitHome(Callback)
  end)
end

function HomeModule:OpenHomeComfortLevelTips()
  self:OpenPanel("HomeComfortLevelTips")
end

function HomeModule:CloseEditPanels()
  self:ClosePanel("Home")
  self:ClosePanel("HomeCutBlackScreen")
  self:ClosePanel("HomeChangeRoomName")
  self:ClosePanel("HomeExpandPanel")
  self:ClosePanel("HomeLevelRewardPanel")
end

function HomeModule:UnLoadAllProps()
  HomeIndoorSandbox.World.Controller:UnLoadAllProps()
end

function HomeModule:UnloadPackUpProps()
  HomeIndoorSandbox.World.Controller:UnloadPackUpProps()
end

function HomeModule:UnloadPackUpSpecifyProps(PropsData)
  HomeIndoorSandbox.World.Controller:UnloadPackUpSpecifyProps(PropsData)
end

function HomeModule:ApplyFurnitureData(FurnitureData, ScreenPos)
  if FurnitureData then
    self:DispatchEvent(HomeModuleEvent.ApplyFurnitureData, FurnitureData)
    if FurnitureData.FurnitureItemConf then
      HomeIndoorSandbox.World.Controller:SpawnPlaceProps(FurnitureData, ScreenPos)
    elseif FurnitureData.InteriorFinishConf then
      HomeIndoorSandbox.World.Controller:SpawnDecoration(FurnitureData)
    end
  end
end

function HomeModule:SwitchNextEditRoom()
  HomeIndoorSandbox.World.Controller:SwitchNextEditRoom()
end

function HomeModule:SwitchPrevEditRoom()
  HomeIndoorSandbox.World.Controller:SwitchPrevEditRoom()
end

function HomeModule:NotifyCancelOperation()
  HomeIndoorSandbox.World.Controller:CancelByUser()
end

function HomeModule:NotifyConfirmOperation()
  HomeIndoorSandbox.World.Controller:ConfirmByUser()
end

function HomeModule:NotifyRotationOperation()
  HomeIndoorSandbox.World.Controller:RotationPropsOnce()
end

function HomeModule:GetEditRoomInfo()
  local Room = HomeIndoorSandbox.HomeEditServ:GetEditRoom()
  if Room then
    return Room.RoomInfo
  end
end

function HomeModule:RegPanel(name, path, layer, openAnimName, closeAnimName, panelType, enablePcEsc, externalPath)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = externalPath or string.format("/Game/NewRoco/Modules/System/Home/Res/%s", path)
  registerData.panelLayer = layer
  registerData.panelType = panelType or 0
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  if nil == enablePcEsc then
    enablePcEsc = true
  end
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
  return registerData
end

function HomeModule:OnCmdOpenPanel(panelName, bOpen, ...)
  if not panelName then
    return
  end
  local panelData = self:GetPanelData(panelName)
  if not panelData then
    return
  end
  if bOpen then
    self:OpenPanel(panelName, ...)
  else
    self:ClosePanel(panelName)
  end
end

function HomeModule:OnCollectReward()
end

function HomeModule:GetPairNestAndPet(nestId)
  if nestId then
    return self.data:GetPairNestAndPet(nestId)
  end
end

function HomeModule:UpdatePairNestAndPet(nestId, petInfo)
  if not nestId then
    return
  end
  self.data:UpdatePairNestAndPet(nestId, petInfo)
end

function HomeModule:OnGetPetIsInHome(gid)
  if HomeIndoorSandbox and HomeIndoorSandbox:InHomeIndoor() then
    local homePetList = self.data:GetHomePetInfo()
    if homePetList then
      for _, homePet in ipairs(homePetList) do
        if homePet.home_pet and homePet.home_pet.home_pet_info.pet_gid == gid then
          return true
        end
      end
    end
  else
    local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
    if not playerInfo or not playerInfo.pet_info then
      return false
    end
    for _, petData in ipairs(playerInfo.pet_info.pet_data) do
      if petData.gid == gid then
        return petData.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET
      end
    end
  end
  return false
end

function HomeModule:OnGetHomePetInfo(petGid)
  if not petGid then
    return self.data.HomePetList
  end
  return self.data:GetHomePetInfo(petGid)
end

function HomeModule:DebugOpenHomePetChoosingTest()
  self:OpenPanel("HomePetChoosing")
end

function HomeModule:DebugHomeFurnitureCreationTest()
  self:OpenPanel("HomeFurnitureCreation")
end

function HomeModule:DebugHomeExpandPanelTest()
  self:OpenPanel("HomeExpandPanel")
end

function HomeModule:DebugHomeLevelRewardPanelTest()
  self:OpenPanel("HomeLevelRewardPanel")
end

function HomeModule:DebugSeedBagTest()
  self:OpenPanel("SeedBag")
end

function HomeModule:DebugHomeVisitPanelTest()
  self:OpenPanel("HomeVisitPanel")
end

local home_check_in_spawn_offset_z

local function GetHomeCheckInSpawnOffsetZ()
  if not home_check_in_spawn_offset_z then
    local conf = _G.DataConfigManager:GetHomeGlobalConfig("home_check_in_spawn_offset_z", true)
    home_check_in_spawn_offset_z = conf and conf.num or 60
  end
  return home_check_in_spawn_offset_z
end

function HomeModule:OnConfirmPet(gid, furnitureId)
  local currentInteractNest = self.data:GetPlacedInteractiveFurniture(furnitureId)
  if not currentInteractNest or not currentInteractNest.viewObj then
    Log.Error("no valid interact nest when spawn pet on nest")
    return
  end
  local nestAbsLoc = currentInteractNest.viewObj:Abs_K2_GetActorLocation()
  local placeReq = _G.ProtoMessage:newZoneHomePetPlaceReq()
  placeReq.pet_gid = gid
  placeReq.furniture_guid = furnitureId
  placeReq.born_pt.pos = ProtoMessage:newPosition()
  placeReq.born_pt.pos.x = math.floor(nestAbsLoc.X)
  placeReq.born_pt.pos.y = math.floor(nestAbsLoc.Y)
  placeReq.born_pt.pos.z = math.floor(nestAbsLoc.Z + GetHomeCheckInSpawnOffsetZ())
  placeReq.born_pt.dir.x = 0
  placeReq.born_pt.dir.y = 0
  placeReq.born_pt.dir.z = 0
  Log.DebugFormat("[HomeModule:OnConfirmPet] Ready to check in. pet_gid=%d furniture_guid=%d pos=(%d,%d,%d)", gid or 0, furnitureId or 0, placeReq.born_pt.pos.x or 0, placeReq.born_pt.pos.y or 0, placeReq.born_pt.pos.z or 0)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_PLACE_REQ, placeReq, self, self.OnPetPlaceRsp, false, true)
end

function HomeModule:OnPetPlaceRsp(rsp)
  Log.Dump(rsp, 3, "ZoneHomePetPlaceReq")
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self:OnCmdOpenPanel("HomePetChoosing", false)
    _G.DataModelMgr.PlayerDataModel:UpdatePetInHomeIndoor(rsp.home_pet_info.pet_gid, true)
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(rsp.home_pet_info.pet_gid)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format("%s" .. LuaText.home_pet_check_in_success, nil ~= petData and petData.name or ""))
  end
end

function HomeModule:OnReCyclePet(furnitureId)
  local currentInteractNest = self.data:GetPlacedInteractiveFurniture(furnitureId)
  if not currentInteractNest then
    Log.Error("no valid interact nest when spawn pet on nest")
    return
  end
  local pairPet = self.data:GetPairNestAndPet(furnitureId)
  if not pairPet or not pairPet.base.actor_id then
    Log.Error("no valid interact nest when spawn pet on nest")
    return
  end
  local req = ProtoMessage:newZoneHomePetUnplaceReq()
  req.pet_unplace_info_list = {
    {
      furniture_guid = furnitureId,
      npc_obj_id = pairPet.base.actor_id
    }
  }
  local homePetActorInfo = self:GetPairNestAndPet(currentInteractNest.furnitureId)
  if homePetActorInfo then
    local recycleTips = LuaText.home_pet_take_back_text_1
    if homePetActorInfo.base.actor_id then
      local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, homePetActorInfo.base.actor_id)
      if not npc then
        return
      end
      if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_HOLD_EGG) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_egg_pick_first)
        return
      end
      if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
        recycleTips = LuaText.home_pet_take_back_text_4
      end
    end
    local context = DialogContext()
    local pairPetData
    if homePetActorInfo.home_pet and homePetActorInfo.home_pet.home_pet_info then
      pairPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(homePetActorInfo.home_pet.home_pet_info.pet_gid)
    end
    context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(recycleTips, pairPetData and pairPetData.name or "")):SetMode(DialogContext.Mode.OK_CANCEL):SetToppingIconType(0):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel):SetCallbackOkOnly(self, function(this, result)
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_UNPLACE_REQ, req, self, self.OnPetRecycleRsp, false, true)
    end)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, context)
  end
end

function HomeModule:OnPetRecycleRsp(rsp)
  Log.Dump(rsp, 3, "OnReCyclePet")
  local home_pet_info = not rsp.home_pet_info and rsp.home_pet_info_list and rsp.home_pet_info_list[1]
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local petName = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(home_pet_info.pet_gid).name
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.home_pet_take_back_text_2, petName))
    local furnitureId = home_pet_info.furniture_guid
    local emptyNpcInfo = ProtoMessage:newActorInfo_Npc()
    local petFurniture = self.data:GetPlacedInteractiveFurniture(furnitureId)
    self.data:UpdatePairNestAndPet(furnitureId, emptyNpcInfo)
    self:DispatchEvent(HomeModuleEvent.OnPetRecycle, petFurniture)
    local homePetList = self.data:GetHomePetInfo()
    for _, v in ipairs(homePetList) do
      if home_pet_info.pet_gid == v.home_pet.home_pet_info.pet_gid then
        self.data:UpdateHomePetInfo(v, false)
      end
    end
    _G.DataModelMgr.PlayerDataModel:UpdatePetInHomeIndoor(home_pet_info.pet_gid, false)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PET_STATUS_ERROR and home_pet_info and home_pet_info.pet_gid then
    local npcInfo = self:OnGetHomePetInfo(home_pet_info.pet_gid)
    if npcInfo and npcInfo.base.actor_id then
      local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcInfo.base.actor_id)
      if not npc then
        return
      end
      if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) or npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_pet_take_back_text_3)
      end
    end
  end
end

function HomeModule:OnFoodProcessAdd(rewards)
  if not rewards or type(rewards) ~= "table" or 0 == #rewards then
    return
  end
  for _, item in ipairs(rewards) do
    if item.id == self.data.EquippingFood then
      self.data.EquippingFoodNum = self.data.EquippingFoodNum + item.num
      self:DispatchEvent(HomeModuleEvent.OnEquipFoodChange, true, self.data.EquippingFood, self.data.EquippingFoodNum)
      break
    end
  end
end

function HomeModule:OnCmdEquipFood(itemId)
  local pendingEquipItemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, itemId)
  if pendingEquipItemData then
    local req = ProtoMessage:newZoneHomePetLoadFoodReq()
    req.item_gid = pendingEquipItemData.gid
    req.item_conf_id = pendingEquipItemData.id
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_LOAD_FOOD_REQ, req, self, self.OnEquipFoodRsp, false, true)
  end
end

function HomeModule:OnEquipFoodRsp(rsp)
  Log.Dump(rsp, 3, "OnEquipFoodRsp")
  if 0 == rsp.ret_info.ret_code then
    if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
      local changes = rsp.ret_info.goods_change_info.changes
      for _, change in ipairs(changes) do
        if change.bag_item.bag_item_flags and 0 ~= change.bag_item.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED then
          self:OnCmdSetEquipFoodIdAndNum(change.bag_item.id, change.bag_item.num)
        end
      end
    end
  else
    self:OnCmdSetEquipFoodIdAndNum(nil, 0)
  end
end

function HomeModule:OnCmdSetEquipFoodIdAndNum(equipFoodId, num)
  self.data.EquippingFood = equipFoodId
  self.data.EquippingFoodNum = num
  self:DispatchEvent(HomeModuleEvent.OnEquipFoodChange, num > 0 or false, equipFoodId, num)
end

function HomeModule:OnCmdGetEquipFoodIdAndNum()
  return self.data.EquippingFood, self.data.EquippingFoodNum
end

function HomeModule:OnCmdUnLoadFood(itemId)
  local pendingEquipItemData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemId)
  if pendingEquipItemData then
    local req = ProtoMessage:newZoneHomePetUnloadFoodReq()
    req.item_gid = pendingEquipItemData.gid
    req.item_conf_id = pendingEquipItemData.id
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_UNLOAD_FOOD_REQ, req, self, self.OnUnloadFoodRsp, false, true)
  end
end

function HomeModule:OnUnloadFoodRsp(rsp)
  Log.Dump(rsp, 3, "OnUnloadFoodRsp")
  if 0 == rsp.ret_info.ret_code then
    local equipId, equipNum = self:OnCmdGetEquipFoodIdAndNum()
    self:OnCmdSetEquipFoodIdAndNum(nil, 0)
  end
end

function HomeModule:OnCmdReplaceFood(itemId)
  local pendingEquipItemData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemId)
  local oldItemId, _ = self:OnCmdGetEquipFoodIdAndNum()
  local oldPendingEquipItemData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, oldItemId)
  if oldPendingEquipItemData and pendingEquipItemData then
    local req = ProtoMessage:newZoneHomePetReplaceFoodReq()
    req.old_item_gid = oldPendingEquipItemData.gid
    req.old_item_conf_id = oldPendingEquipItemData.id
    req.new_item_gid = pendingEquipItemData.gid
    req.new_item_conf_id = pendingEquipItemData.id
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_REPLACE_FOOD_REQ, req, self, self.OnReplaceFoodRsp, false, true)
  end
end

function HomeModule:OnReplaceFoodRsp(rsp)
  Log.Dump(rsp, 3, "HomeModule OnReplaceFoodRsp")
  if 0 == rsp.ret_info.ret_code then
    if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
      local changes = rsp.ret_info.goods_change_info.changes
      for _, change in ipairs(changes) do
        if change.bag_item.bag_item_flags and 0 ~= change.bag_item.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED then
          self:OnCmdSetEquipFoodIdAndNum(change.bag_item.id, change.bag_item.num)
        end
      end
    end
  else
    self:OnCmdSetEquipFoodIdAndNum(nil, 0)
  end
end

function HomeModule:OnCmdUpdatePetCollect(partnerMark)
  if self:HasPanel("HomePetChoosing") then
    local panel = self:GetPanel("HomePetChoosing")
    if panel then
      panel:UpdateCollect(partnerMark)
    end
  end
  if self:HasPanel("HomePetDetail") then
    local propertyPanel = self:GetPanel("HomePetDetail")
    if propertyPanel then
      propertyPanel:UpdateCollect(partnerMark)
    end
  end
end

function HomeModule:OnInteractWithHomePet(action, tag, baseData)
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor() then
    _G.DataModelMgr.PlayerDataModel:RefreshPetGidAndNum(action.home_pet_gids, action.total_steal_num)
    if action.interact_type == _G.ProtoEnum.SpaceAct_HomeInteractNotify.InteractType.ACTION_CROSS_DAY_RESET then
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, nil, _G.Enum.MapModuleDataUpdateReason.HOME_PET_TRIGGER_NUM_LIMIT)
    elseif action.interact_type == _G.ProtoEnum.SpaceAct_HomeInteractNotify.InteractType.ACTION_UPDATE_STEAL_INFO then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      local stealHomeInfo = player.serverData.steal_home_info
      stealHomeInfo = stealHomeInfo or {
        total_steal_num = 0,
        steal_of_home_pets = {}
      }
      if action.home_pet_gids and type(action.home_pet_gids) == "table" then
        local oldPetGids = player.serverData.steal_home_info.steal_of_home_pets
        for _, oldPet in ipairs(oldPetGids) do
          if not table.contains(action.home_pet_gids) then
            local npc = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo, oldPet)
            if npc then
              _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, npc, _G.Enum.MapModuleDataUpdateReason.HOME_PET_REFRESH_PRODUCTION)
            end
          end
        end
      end
      if action.total_steal_num then
        local totalStealMax = _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max") and _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max").num or 99999
        if totalStealMax <= action.total_steal_num then
          _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, nil, _G.Enum.MapModuleDataUpdateReason.HOME_PET_TRIGGER_NUM_LIMIT)
        end
      end
    end
  end
end

function HomeModule:OnCmdOpenSeedBagPanel(...)
  if not self:HasOwnSeedBag() then
    return
  end
  self:OpenPanel("SeedBag", ...)
end

function HomeModule:OnCmdOpenSeedCraftPanel(specificSeedItemId)
end

function HomeModule:OnCmdSendSeedExchangeReq(seedId, exchangeNum)
  local req = _G.ProtoMessage:newZoneHomePlantSeedCompoundReq()
  req.seed_id = seedId
  req.seed_num = exchangeNum
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PLANT_SEED_COMPOUND_REQ, req, self, self.OnSeedExchangeRsp, false, true)
end

function HomeModule:OnSeedExchangeRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    if _rsp.ret_info.goods_reward and _rsp.ret_info.goods_reward.rewards then
      local rewards = _rsp.ret_info.goods_reward.rewards
      if rewards[1] then
        self:DispatchEvent(HomeModuleEvent.OnSeedCraftSuccess, rewards[1].id)
      end
      local itemInfos = {}
      for _, v in ipairs(rewards) do
        local itemId = v.id
        local itemText = tostring(v.num)
        table.insert(itemInfos, {
          itemId = itemId,
          itemText = itemText,
          id = itemId,
          num = v.num,
          type = v.type,
          reward_reason = v.reward_reason
        })
      end
      if #itemInfos > 0 then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos, nil, nil, nil, nil, nil, true)
      end
    end
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function HomeModule:OnCmdSendSetEquipSeed(seedId, seedTabLevel)
  if not self:HasOwnSeedBag() then
    return
  end
  if not seedId then
    return
  end
  local equippingSeedId, equippingSeedTabLevel = self:OnCmdGetEquipSeed()
  local pendingEquipSeedItemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, seedId)
  if seedId > 0 and not pendingEquipSeedItemData then
    Log.Error("\229\176\157\232\175\149\232\163\133\229\164\135\228\184\128\228\184\170\228\184\141\229\173\152\229\156\168\232\131\140\229\140\133\230\149\176\230\141\174\231\154\132\231\167\141\229\173\144", seedId)
    return
  end
  if pendingEquipSeedItemData and (not seedTabLevel or seedTabLevel <= 0 or seedId == equippingSeedId and seedTabLevel == equippingSeedTabLevel) then
    return
  end
  local req = _G.ProtoMessage:newZoneHomePlantSeedEquipReq()
  if equippingSeedId and equippingSeedId > 0 and equippingSeedId ~= seedId then
    local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, equippingSeedId)
    if itemData then
      local unEquipModifyInfo = ProtoMessage:newHomePlantSeedModifyInfo()
      unEquipModifyInfo.gid = itemData.gid
      unEquipModifyInfo.item_conf_id = itemData.id
      unEquipModifyInfo.bag_item_flags = (itemData.bag_item_flags or 0) & ~ProtoEnum.BagItemFlag.SEED_EQUIPPED
      table.insert(req.modify_info, unEquipModifyInfo)
    end
  end
  if pendingEquipSeedItemData then
    local EquipModifyInfo = ProtoMessage:newHomePlantSeedModifyInfo()
    EquipModifyInfo.gid = pendingEquipSeedItemData.gid
    EquipModifyInfo.item_conf_id = pendingEquipSeedItemData.id
    EquipModifyInfo.bag_item_flags = (pendingEquipSeedItemData.bag_item_flags or 0) | ProtoEnum.BagItemFlag.SEED_EQUIPPED
    EquipModifyInfo.plant_tab = seedTabLevel
    table.insert(req.modify_info, EquipModifyInfo)
  end
  if 0 == #req.modify_info then
    return
  end
  if _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PLANT_SEED_EQUIP_REQ, req, self, self.OnEquipSeedRsp, false, true) then
  end
end

function HomeModule:OnEquipSeedRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
      local changes = rsp.ret_info.goods_change_info.changes
      local bHasEquipFlag = false
      for i, change in ipairs(changes) do
        if change.bag_item and change.bag_item.bag_item_flags and 0 ~= change.bag_item.bag_item_flags & ProtoEnum.BagItemFlag.SEED_EQUIPPED then
          if bHasEquipFlag then
            Log.Error("HomeModule:OnEquipSeedRsp, \230\159\144\230\172\161\231\167\141\229\173\144\232\163\133\229\164\135\230\182\136\230\129\175\228\184\173\229\175\185\228\184\164\228\184\170\231\167\141\229\173\144\232\191\155\232\161\140\228\186\134\232\163\133\229\164\135\228\184\173\231\154\132\230\160\135\232\174\176\239\188\159\239\188\159\239\188\159")
          end
          bHasEquipFlag = true
          local newSeedTabLevel = change.bag_item.level or 1
          self:OnCmdSetEquipSeedDirectly(change.id, true, newSeedTabLevel)
          local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(change.id, true)
          local seedTabName = ""
          if plantGrowConf and plantGrowConf.plant_tab and plantGrowConf.plant_tab[newSeedTabLevel] then
            local plantTabConf = _G.DataConfigManager:GetPlantTabConf(plantGrowConf.plant_tab[newSeedTabLevel], true)
            if plantTabConf and plantTabConf.name then
              seedTabName = plantTabConf.name
            end
          end
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(change.id, true)
          if bagItemConf and LuaText.seed_select_equip_tips then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.seed_select_equip_tips, seedTabName, bagItemConf.name))
          end
        end
      end
      if not bHasEquipFlag then
        if self.data.EquippingSeed and self.data.EquippingSeed > 0 then
          local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(self.data.EquippingSeed, true)
          local seedTabName = ""
          if plantGrowConf and plantGrowConf.plant_tab and plantGrowConf.plant_tab[self.data.EquippingSeedTabLevel] then
            local plantTabConf = _G.DataConfigManager:GetPlantTabConf(plantGrowConf.plant_tab[self.data.EquippingSeedTabLevel], true)
            if plantTabConf and plantTabConf.name then
              seedTabName = plantTabConf.name
            end
          end
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.data.EquippingSeed, true)
          if bagItemConf and LuaText.seed_select_equip_tips then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.seed_select_not_equip_tips, seedTabName, bagItemConf.name))
          end
        end
        self:OnCmdSetEquipSeedDirectly(0, true)
      end
    end
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function HomeModule:OnCmdSendSeedCropReq(landId, seedId)
  if not landId or not seedId then
    return
  end
  local seedGID = 0
  if seedId > 0 then
    local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, seedId)
    if itemData then
      seedGID = itemData.gid
    end
  end
  if 0 == seedGID then
    return
  end
  local ownNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
  local plantGrowConf = DataConfigManager:GetPlantGrowConf(seedId)
  local bOwnEnoughMoney = false
  if plantGrowConf and plantGrowConf.plant_vitem_value then
    bOwnEnoughMoney = ownNum >= plantGrowConf.plant_vitem_value
  end
  if not bOwnEnoughMoney then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.plant_no_seed_money)
    return
  end
  local req = _G.ProtoMessage:newZoneSceneHomePlantCropReq()
  req.land_id = landId
  req.seed_gid = seedGID
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_PLANT_CROP_REQ, req, self, self.OnSeedCropRsp, false, true)
end

function HomeModule:OnSeedCropRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function HomeModule:OnCmdGetEquipSeed()
  return self.data.EquippingSeed or 0, self.data.EquippingSeedTabLevel or 1
end

function HomeModule:OnCmdGenerateSeedTipsInfo(seedId, keepUnitCount, seedTabLevel)
  local totalGrowTimeCostSecond, minNum, maxNum, timeStr, outputStr = FarmUtils.GetSeedGrowInfo(seedId, keepUnitCount, true, seedTabLevel or 1)
  return timeStr or "", outputStr or "", totalGrowTimeCostSecond, minNum, maxNum
end

function HomeModule:OnCmdSetEquipSeedDirectly(seedId, bServerDriven, seedTabLevel)
  seedTabLevel = seedTabLevel or 1
  local equippingSeedId, equippingSeedTabLevel = self:OnCmdGetEquipSeed()
  if seedId and seedId > 0 then
    if seedId == equippingSeedId and seedTabLevel == equippingSeedTabLevel then
      return
    end
  elseif seedId == equippingSeedId then
    return
  end
  local unEquipSeed = self.data.EquippingSeed
  self.data.EquippingSeed = seedId
  self.data.EquippingSeedTabLevel = seedTabLevel
  self:DispatchEvent(HomeModuleEvent.OnEquipSeedChange, unEquipSeed, seedId, bServerDriven, seedTabLevel)
end

function HomeModule:OnHomePetStatusChange(actorId, furnitureId, actorInfo_npc)
  if #self.data.HomePetList <= 0 then
    return
  end
  for _, homePet in pairs(self.data.HomePetList) do
    if homePet and homePet.serverData.base.actor_id == actorId then
      homePet:UpdateData(actorInfo_npc)
    end
  end
end

function HomeModule:OnRolePlayAffectHomePet(fromPlayer, npcId, fixVal)
  local npc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, npcId or 0)
  if npc then
    local AttrComp = npc:EnsureComponent(HomePetAttributeComponent)
    AttrComp:ModifyFriendliness(fromPlayer, fixVal)
  else
    Log.Debug("HomeModule:OnRolePlayAffectHomePet, npc not found", npcId)
  end
end

function HomeModule:IsHomeMasterByPlayerId(playerId)
  if not _G.HomeIndoorSandbox then
    return false
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, playerId)
  if not player then
    return false
  end
  local uin = player.serverData.base.logic_id
  return uin == _G.HomeIndoorSandbox.Server.MasterId
end

function HomeModule:OnCmdCloseFurnitureAtlasPanel()
  self:ClosePanel("HomeFurnitureAtlasMain")
end

function HomeModule:OnCmdOpenFriendFurniture(friendsData, totalFriendNum)
  self:OpenPanel("FriendFurniturePopup", friendsData, totalFriendNum)
end

function HomeModule:OnCmdCloseFriendFurniture()
  self:ClosePanel("FriendFurniturePopup")
end

function HomeModule:OnCmdOpenFurnitureAtlasPanel()
  local bool, _ = self:HasPanel("HomeFurnitureAtlasMain")
  if bool then
    return
  end
  local req = ProtoMessage:newZoneHomeGetUnlockedFurnitureInfoReq()
  if _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_GET_UNLOCKED_FURNITURE_INFO_REQ, req, self, self.OnUnlockedFurnitureInfoRsp, false, true) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, true)
  end
end

function HomeModule:OnUnlockedFurnitureInfoRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local FurnitureAtlasInfo = self.data.FurnitureAtlasInfo
    if rsp.unlocked_furniture_info and rsp.unlocked_furniture_info.handbook_list then
      for _, v in pairs(rsp.unlocked_furniture_info.handbook_list) do
        local handBookId = v.handbook_id
        local furnitureData = FurnitureAtlasInfo[handBookId]
        if furnitureData then
          furnitureData.unlock_time = v.unlock_timestamp
          if v.reward_received then
            furnitureData.reward_status = 3
          else
            furnitureData.reward_status = 2
          end
        else
          FurnitureAtlasInfo[handBookId] = {
            id = handBookId,
            unlock_time = v.unlock_timestamp
          }
          if v.reward_received then
            FurnitureAtlasInfo[handBookId].reward_status = 3
          else
            FurnitureAtlasInfo[handBookId].reward_status = 2
          end
          self.data.FurnitureAtlasNum = self.data.FurnitureAtlasNum + 1
        end
      end
    end
    if HomeIndoorSandbox.HomeEditServ.bPendingEnterEditMode then
      HomeIndoorSandbox:LogWarn("bPendingEnterEditMode")
      return true
    end
    if self:InPanelOpenForbiddenStatus() then
      return
    end
    self:OpenPanel("HomeFurnitureAtlasMain", self.data.FurnitureAtlasInfo)
  else
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, false)
  end
end

function HomeModule:ResetFriendReq()
  self.data.canSendFriendReq = true
end

function HomeModule:ChangeFurnitureAtlas()
  if self:HasPanel("HomeFurnitureAtlasMain") then
    local panel = self:GetPanel("HomeFurnitureAtlasMain")
    panel.bShowTestUMG = not panel.bShowTestUMG
    panel:OpenDebugPanel()
    if panel.bShowTestUMG then
      panel:InitSlider(panel.handbook_id)
    end
  end
end

function HomeModule:OnCmdSendPlantPetGuardReq(bGuard, petGid)
  if bGuard and (not petGid or petGid <= 0) then
    return
  end
  local req = _G.ProtoMessage:newZoneHomePetGuardReq()
  if bGuard then
    table.insert(req.pet_guard_pids, petGid)
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_GUARD_REQ, req, self, self.OnPlantPetGuardRsp, false, true)
end

function HomeModule:OnPlantPetGuardRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local newHomePlantGuardPetGid = 0
    if _rsp.pet_guard_pids and _rsp.pet_guard_pids[1] then
      newHomePlantGuardPetGid = _rsp.pet_guard_pids[1]
    end
    self.data.HomePlantGuardPetGid = newHomePlantGuardPetGid
    self:DispatchEvent(HomeModuleEvent.HomePlantGuardUpdate, self.data.HomePlantGuardPetGid)
    _G.NRCEventCenter:DispatchEvent(HomeModuleEvent.HomePlantGuardJustConfirm, self.data.HomePlantGuardPetGid)
    if 0 == self.data.HomePlantGuardPetGid then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.plant_no_guard_pet_tips)
    else
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.HomePlantGuardPetGid)
      if petData and petData.name then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.plant_guard_pet_tips, petData.name))
      end
    end
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function HomeModule:OnCmdGetHomePlantGuardPetGid()
  if self.data.HomePlantGuardPetGid == nil then
    self.data.HomePlantGuardPetGid = self:GrabHomePlantGuardPetFromPlayerData()
  end
  return self.data.HomePlantGuardPetGid or 0
end

function HomeModule:OnReconnectStart()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  self:CloseHomeownerWaitConfirmationPanel()
end

function HomeModule:OnReconnectFinish()
  if self.data.placedInteractiveFurniture then
    for _, furniture in ipairs(self.data.placedInteractiveFurniture) do
      if furniture.QueryCurrentStatus then
        furniture:QueryCurrentStatus()
      end
    end
  end
  local bool, v = self:HasPanel("HomePetChoosing")
  if bool then
    self:ClosePanel("HomePetChoosing")
  end
  local FoodProcessingPanel, v2 = self:HasPanel("FoodProcessingPanel")
  if FoodProcessingPanel then
    self:ClosePanel("FoodProcessingPanel")
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_HOME)
  if isBan then
    self:ShowQuitDialogForBlocking()
  end
end

function HomeModule:GrabHomePlantGuardPetFromPlayerData()
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
  if not playerInfo or not playerInfo.pet_info then
    return 0
  end
  for idx, petData in ipairs(playerInfo.pet_info.pet_data) do
    if petData and petData.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_GUARD then
      return petData.gid
    end
  end
  return 0
end

function HomeModule:HasOwnSeedBag(bDontShowTips)
  local config = _G.DataConfigManager:GetHomeGlobalConfig("plant_seed_bagitem_id")
  if not config then
    return false
  end
  local seedBagItemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, config.num or 0)
  local bOwn = seedBagItemData and seedBagItemData.num and seedBagItemData.num > 0
  if not bOwn and not bDontShowTips then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[string.format("Error_Code_%d", ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SEED_BAGITEM_NOT_EXIST)])
  end
  return bOwn
end

function HomeModule:IsInHomeScene()
  return (SceneUtils.GetSceneID() or 0) == 301
end

function HomeModule:OnActorPlantDataUpdate(action)
  if action and action.actor_plant_data then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and player.serverData then
      if not player.serverData.home_plant_info then
        player.serverData.home_plant_info = ProtoMessage:newActorInfo_HomePlantInfo()
      end
      player.serverData.home_plant_info.actor_plant_data = action.actor_plant_data
    end
  end
end

function HomeModule:OnCmdAddPlayerStealCount()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.serverData then
    if not player.serverData.home_plant_info then
      player.serverData.home_plant_info = ProtoMessage:newActorInfo_HomePlantInfo()
    end
    if not player.serverData.home_plant_info.actor_plant_data then
      player.serverData.home_plant_info.actor_plant_data = ProtoMessage:newActorPlantData()
    end
    if not player.serverData.home_plant_info.actor_plant_data.steal_cnt then
      player.serverData.home_plant_info.actor_plant_data.steal_cnt = 0
    end
    player.serverData.home_plant_info.actor_plant_data.steal_cnt = player.serverData.home_plant_info.actor_plant_data.steal_cnt + 1
  end
end

function HomeModule:OpenFoodProcessingPanel()
  self:OpenPanel("FoodProcessingPanel")
end

function HomeModule:GetAllFoodProductionInfo()
  return self.data:GetAllFoodProductionInfo()
end

function HomeModule:GetLastProcessingFoodId()
  return self.data:GetLastProcessingFoodId()
end

function HomeModule:IsOpenHomeFunction()
  return _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_HOME_START)
end

function HomeModule:OnCmdSendZoneHomePetFoodCompoundReq(foodConfId, productionNum, costItemIdList)
  self.data:SaveLastProcessingFoodId(foodConfId)
end

function HomeModule:OnSystemFuncBlockingTypeChangeHandler(funcId, entranceBlockingType)
  if funcId ~= Enum.FunctionEntrance.FE_HOME or entranceBlockingType == FunctionBanEnum.EntranceBlockingType.None then
    return
  end
  self:ShowQuitDialogForBlocking()
end

function HomeModule:ShowQuitDialogForBlocking()
  if self.isShowQuitDialogForBlocking then
    return
  end
  if _G.HomeIndoorSandbox:InHomeIndoor() or _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
    self.isShowQuitDialogForBlocking = true
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    Context:SetTitle(_G.LuaText.TIPS):SetContent(_G.LuaText.onlinemodule_12):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.OK):SetButtonText(_G.LuaText.tips_dialog_butten_accept, _G.LuaText.tips_dialog_butten_cancel):SetCloseOnOK(true):SetCallback(self, self.OnQuitDialogForBlockingClose)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function HomeModule:OnQuitDialogForBlockingClose()
  self.isShowQuitDialogForBlocking = false
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.ReqLeavePlayerHomeIndoor)
end

function HomeModule:OnCmdGetReportData()
  return {
    homeName = HomeIndoorSandbox.Server.WorldData.HomeName,
    masterId = HomeIndoorSandbox.Server.MasterId
  }
end

function HomeModule:OnReLoginUpdatePet()
  self.data.HomePlantGuardPetGid = self:GrabHomePlantGuardPetFromPlayerData()
  self:DispatchEvent(HomeModuleEvent.HomePlantGuardUpdate, self.data.HomePlantGuardPetGid)
end

function HomeModule:CheckUIFunctionHide(FuncEnum)
  local InteractFunctions
  if _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
    InteractFunctions = self.data.FarmMainUIIcons
  elseif HomeIndoorSandbox and HomeIndoorSandbox:InLocalMasterIndoor() then
    InteractFunctions = self.data.LocalHomeMainUIIcons
  elseif HomeIndoorSandbox and HomeIndoorSandbox:InOtherHomeIndoor() then
    InteractFunctions = self.data.OtherHomeMainUIIcons
  elseif FuncEnum == Enum.FunctionEntrance.FE_EDIT_HOME or FuncEnum == Enum.FunctionEntrance.FE_FURNITURE_HANDBOOK then
    return true
  end
  if InteractFunctions and not InteractFunctions[FuncEnum] then
    return true
  end
  return false
end

function HomeModule:GetPlayerHomeOwnershipStatus(PlayUin)
  local OwnerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
  local PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  if 0 ~= OwnerUin then
    if OwnerUin == PlayerUin then
      if PlayerUin == PlayUin or not PlayUin then
        return HomeEnum.HomeOwnershipStatus.OnLineOwnerSelf
      else
        return HomeEnum.HomeOwnershipStatus.OnLineOwnerOther
      end
    else
      return HomeEnum.HomeOwnershipStatus.OnLineMemberOther
    end
  elseif PlayerUin == PlayUin or not PlayUin then
    return HomeEnum.HomeOwnershipStatus.OffLineSelf
  else
    return HomeEnum.HomeOwnershipStatus.OffLineOther
  end
end

function HomeModule:GetOnLinePlayerName(PlayUin)
  local Name
  PlayUin = PlayUin or _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
  
  local function GetName(visitList)
    if visitList then
      for i, visitor in pairs(visitList) do
        if visitor.uin == PlayUin then
          Name = visitor.name
          return Name
        end
      end
    end
  end
  
  local t = not Name and GetName(_G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList))
  t = not Name and GetName(_G.DataModelMgr.PlayerDataModel.visitList)
  return Name
end

function HomeModule:OnCmdOpenHomeownerWaitConfirmationPanel(...)
  self:OpenPanel("HomeownerWaitConfirmation", ...)
end

function HomeModule:CloseHomeownerWaitConfirmationPanel()
  self:ClosePanel("HomeownerWaitConfirmation")
end

function HomeModule:OnCmdSendZoneSceneHomeTeamCreateReq(teamType, worldMapCfgId)
  local funBan = teamType == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT and Enum.PlayerFunctionBanType.PFBT_LEAVE_HOME_INVITE or Enum.PlayerFunctionBanType.PFBT_VISIT_HOME_INVITE
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, funBan, nil, true)
  if bBan then
    Log.Error("HomeModule:OnCmdSendZoneSceneHomeTeamCreateReq is ban")
    return
  end
  local req = _G.ProtoMessage:newZoneSceneHomeTeamCreateReq()
  req.team_type = teamType
  req.world_map_cfg_id = worldMapCfgId
  
  local function OnZoneSceneHomeTeamQueryRsp(_rspWrapper, _rsp)
    if 0 == _rsp.ret_info.ret_code then
      if _rsp.team_info and _rsp.team_info.members and #_rsp.team_info.members > 1 then
        _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenHomeownerWaitConfirmationPanel, _rsp.team_info)
      else
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.invite_visit_home_empty)
      end
    else
      HomeIndoorSandbox.HomeTipsServ:ConditionalDisplayError(_rsp.ret_info)
    end
  end
  
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_CREATE_REQ, req, self, OnZoneSceneHomeTeamQueryRsp, false, true)
end

function HomeModule:OnCmdZoneSceneHomeTeamDisbandReq()
  local req = _G.ProtoMessage:newZoneSceneHomeTeamDisbandReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_DISBAND_REQ, req, self, self.OnZoneSceneHomeTeamDisbandRsp, false, true)
end

function HomeModule:OnZoneSceneHomeTeamDisbandRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:CloseHomeownerWaitConfirmationPanel()
  end
end

function HomeModule:OnZoneSceneHomeTeamUpdateNotify(notify)
  local teamInfo = notify.team_info
  local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local bIsHasPanel = self:HasPanel("HomeownerWaitConfirmation")
  if bIsHasPanel then
    self:DispatchEvent(HomeModuleEvent.OnTeamEnterHomeRefresh, teamInfo)
  end
  if teamInfo.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME or teamInfo.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if not visitorList or 0 == #visitorList then
      Log.Error("\230\163\128\230\181\139\229\136\176\229\189\147\229\137\141\228\184\141\229\156\168\232\129\148\230\156\186\231\138\182\230\128\129\239\188\140\230\148\182\229\136\176\228\186\134\232\191\155\229\133\165\229\174\182\229\155\173\231\155\184\229\133\179\231\154\132\233\152\159\228\188\141\230\155\180\230\150\176\233\128\154\231\159\165\239\188\154ZoneSceneHomeTeamUpdateNotify")
      return
    end
  end
  if teamInfo.status == ProtoEnum.HomeTeamStatus.HOME_TEAM_STATUS_FORMING then
    if #teamInfo.members > 1 then
      local selfInfo = self:GetMemberByTeamInfo(selfUin, teamInfo.members)
      if selfInfo then
        if selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_ACCEPT and not bIsHasPanel then
          _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenHomeownerWaitConfirmationPanel, notify.team_info)
        end
        if selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_NONE or selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_INVITED then
          local ownerInfo = self:GetMemberByTeamInfo(teamInfo.team_leader_uin, teamInfo.members)
          self:TryOpenApplyVisitInfoHitHandle(teamInfo.team_type, ownerInfo)
        end
      end
    end
  elseif teamInfo.status == ProtoEnum.HomeTeamStatus.HOME_TEAM_STATUS_DISBAND and teamInfo.team_leader_uin ~= selfUin then
    local selfInfo = self:GetMemberByTeamInfo(selfUin, teamInfo.members)
    if selfInfo and (selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_NONE or selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_INVITED or selfInfo.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_ACCEPT) then
      if teamInfo.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME or teamInfo.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.invite_visit_home_cancel_tips)
      elseif teamInfo.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.invite_leave_home_cancel_tips)
      end
    end
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  end
  if self.HomeTeamInvitationUICloseCountdown then
    _G.DelayManager:CancelDelayById(self.HomeTeamInvitationUICloseCountdown)
    self.HomeTeamInvitationUICloseCountdown = nil
  end
  self.HomeTeamInvitationUICloseCountdown = _G.DelayManager:DelaySeconds(10, function()
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
    self:CloseHomeownerWaitConfirmationPanel()
  end, self)
end

function HomeModule:GetMemberByTeamInfo(memberUin, members)
  if members then
    for i, v in pairs(members) do
      if v.uin == memberUin then
        return table.deepCopy(v)
      end
    end
  end
  return nil
end

function HomeModule:TryOpenApplyVisitInfoHitHandle(team_type, ownerBriefInfo)
  if not team_type or not ownerBriefInfo then
    Log.Error("TryOpenApplyVisitInfoHitHandle: team_type or ownerBriefInfo is nil")
    return
  end
  local funBan = team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT and Enum.PlayerFunctionBanType.PFBT_LEAVE_HOME_ALLOWED or Enum.PlayerFunctionBanType.PFBT_VISIT_HOME_ALLOWED
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, funBan, nil, true)
  if bBan then
    return
  end
  local bIsOpen = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CheckApplyVisitInfoHitPanelIsOpen)
  local bIsOpen2 = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CheckApplyVisitListPanelIsOpen)
  if bIsOpen or bIsOpen2 then
    return
  end
  local param = {
    uin = ownerBriefInfo.uin,
    name = ownerBriefInfo.name,
    level = ownerBriefInfo.role_level,
    world_level = ownerBriefInfo.world_level,
    card_info = {
      card_icon_selected = ownerBriefInfo.card_icon
    },
    team_type = team_type
  }
  local reason = team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT and FriendEnum.ExchangeVisitsType.ReturnBigWorld or FriendEnum.ExchangeVisitsType.EnterHome
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenApplyVisitInfoHit, reason, param)
end

function HomeModule:OnZoneSceneHomeTeamInviteNotify(notify)
  if notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME or notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if not visitorList or 0 == #visitorList then
      Log.Error("\230\163\128\230\181\139\229\136\176\229\189\147\229\137\141\228\184\141\229\156\168\232\129\148\230\156\186\231\138\182\230\128\129\239\188\140\230\148\182\229\136\176\228\186\134\232\191\155\229\133\165\229\174\182\229\155\173\233\130\128\232\175\183\233\128\154\231\159\165\239\188\154ZoneSceneHomeTeamInviteNotify")
      return
    end
  end
  self:TryOpenApplyVisitInfoHitHandle(notify.team_type, notify.team_leader)
end

function HomeModule:OnCmdZoneSceneHomeTeamRespondInviteReq(team_leader_id, team_type, respond_type)
  if respond_type == ProtoEnum.HomeTeamRespondType.HOME_TEAM_RESPOND_TYPE_ACCEPT then
    local funBan = team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT and Enum.PlayerFunctionBanType.PFBT_LEAVE_HOME_ACCEPT or Enum.PlayerFunctionBanType.PFBT_VISIT_HOME_ACCEPT
    local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, funBan, nil, true)
    if bBan then
      Log.Error("\232\174\191\229\174\162\229\186\148\231\173\148\233\130\128\232\175\183\239\188\140\229\138\159\232\131\189\229\183\178\232\162\171\231\166\129\231\148\168")
      return
    end
  end
  local req = _G.ProtoMessage:newZoneSceneHomeTeamRespondInviteReq()
  req.team_leader_id = team_leader_id
  req.respond_type = respond_type
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_RESPOND_INVITE_REQ, req, self, self.OnZoneSceneHomeTeamRespondInviteRsp, false, true)
end

function HomeModule:OnZoneSceneHomeTeamRespondInviteRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
    local notRefuse = false
    if _rsp.team_info.members then
      for i, v in pairs(_rsp.team_info.members) do
        if v.uin == playerUin and v.status == ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_ACCEPT then
          notRefuse = true
          break
        end
      end
    end
    if notRefuse then
      _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenHomeownerWaitConfirmationPanel, _rsp.team_info)
    elseif _rsp.team_info.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.online_leave_home_refuse)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.online_visit_home_refuse)
    end
  else
    HomeIndoorSandbox.HomeTipsServ:ConditionalDisplayError(_rsp.ret_info)
  end
end

function HomeModule:OnCmdZoneSceneHomeTeamEnterHomeReq()
  local req = _G.ProtoMessage:newZoneSceneHomeTeamEnterHomeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_ENTER_HOME_REQ, req, self, self.OnZoneSceneHomeTeamEnterHomeRsp, false, true)
end

function HomeModule:OnZoneSceneHomeTeamEnterHomeRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:CloseHomeownerWaitConfirmationPanel()
    _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 1, nil, nil, nil, nil, nil, nil, true)
  end
end

function HomeModule:OnZoneSceneHomeTeamEnterCheckResultNotify(notify)
  if 0 ~= notify.error_code and (notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME or notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT) then
    if notify.home_owner_id == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
      _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.CloseLoadingUI)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_invite_text)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
    end
  end
end

function HomeModule:OnHomeVisitInfoChanged()
  if not HomeIndoorSandbox:InOtherHomeIndoor() then
    return
  end
  local homePetList = self.data:GetHomePetInfo()
  for _, v in pairs(homePetList) do
    if v.base then
      local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, v.base.actor_id)
      if npc and npc.InteractionComponent then
        npc.InteractionComponent:UpdateHomeOptions()
      end
    end
  end
end

function HomeModule:OnCmdZoneSceneHomeTeamLeaveHomeReq()
  local req = _G.ProtoMessage:newZoneSceneHomeTeamLeaveHomeReq()
  if self.LeaveHomeDataCache then
    req.entry_id = self.LeaveHomeDataCache.entry_id
    req.use_special_teleport = self.LeaveHomeDataCache.use_special_teleport
    self.LeaveHomeDataCache = nil
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_LEAVE_HOME_REQ, req, self, self.OnZoneSceneHomeTeamLeaveHomeRsp, false, true)
end

function HomeModule:OnZoneSceneHomeTeamLeaveHomeRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:CloseHomeownerWaitConfirmationPanel()
  end
end

function HomeModule:OnZoneSceneHomeTeamEnterNotify(notify)
  local bIsResponse = self:HasPanel("HomeownerWaitConfirmation")
  self:CloseHomeownerWaitConfirmationPanel()
  if not bIsResponse and notify.home_owner_id ~= _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    if notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_HOME or notify.team_type == ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_PLANT then
      local Title = _G.DataConfigManager:GetLocalizationConf("invite_visit_home_break_team_title").msg
      local Tips = _G.DataConfigManager:GetLocalizationConf("invite_visit_home_break_team_text").msg
      local timeCountDown = _G.DataConfigManager:GetHomeGlobalConfig("invite_visit_home_break_team_show_time").num
      local Ctx = _G.DialogContext()
      Ctx:SetTitle(Title)
      Ctx:SetContent(Tips)
      Ctx:SetMode(_G.DialogContext.Mode.OK)
      Ctx:SetButtonText(LuaText.YES, nil)
      Ctx:SetCountdown(DialogContext.Mode.OK, timeCountDown)
      Ctx:SetForceEnableFullScreenBtn()
      Ctx:SetCallback(self, function(_, IsOK, CancelType)
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CmdZoneExitVisitReq)
      end)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
    end
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  end
end

function HomeModule:OnLeaveVisit()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  self:CloseHomeownerWaitConfirmationPanel()
end

function HomeModule:OnZoneSceneHomeTeamQueryReq(callBack1, callBack2, entryId, bSseSpecialTeleport)
  self.LeaveHomeDataCache = {}
  self.LeaveHomeDataCache.entry_id = entryId
  self.LeaveHomeDataCache.use_special_teleport = bSseSpecialTeleport
  local req = _G.ProtoMessage:newZoneSceneHomeTeamQueryReq()
  
  local function OnZoneSceneHomeTeamQueryRsp(_rspWrapper, _rsp)
    if 0 == _rsp.ret_info.ret_code and _rsp.team_info and _rsp.team_init_member_count > 1 then
      if _rsp.team_info.members and #_rsp.team_info.members > 1 then
        local Ctx = _G.DialogContext()
        Ctx:SetTitle(LuaText.online_owner_leave_home_invite_title)
        Ctx:SetContent(LuaText.online_owner_leave_home_invite_text)
        Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
        Ctx:SetButtonText(LuaText.online_owner_leave_home_invite_button_yes, LuaText.online_owner_leave_home_invite_button_no)
        Ctx:SetForceEnableFullScreenBtn()
        Ctx:SetCallback(self, function(_, IsOK, CancelType)
          if IsOK then
            if callBack2 then
              callBack2()
            end
            _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSendZoneSceneHomeTeamCreateReq, ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_VISIT)
          elseif CancelType == CommonBtnEnum.DialogCancelType.BtnClickType then
            if callBack1 then
              callBack1()
            end
          elseif (CancelType == CommonBtnEnum.DialogCancelType.NullClickType or CancelType == CommonBtnEnum.DialogCancelType.CloseClickType) and callBack2 then
            callBack2()
          end
        end)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
        return
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.online_owner_leave_home_invite_noone)
      end
    end
    if callBack1 then
      callBack1()
    end
  end
  
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_TEAM_QUERY_REQ, req, self, OnZoneSceneHomeTeamQueryRsp, false, true, nil, callBack1)
end

function HomeModule:ProcessVisitorComeIn()
  for Guid, homePropsData in pairs(HomeIndoorSandbox.Server.WorldData.HomeFurnitureGuidSet) do
    local furnitureEffectConf = _G.DataConfigManager:GetFurnitureEffectConf(homePropsData.ConfId, true)
    if furnitureEffectConf and furnitureEffectConf.trigger_type == Enum.FurnitureEffectSwitch.FES_VISIT_HOME and furnitureEffectConf.trigger_type == Enum.FurnitureEffectType.FET_PLAY_AUDIO_GlOBAL and furnitureEffectConf.effect_type_param then
      _G.NRCAudioManager:PlaySound2DAuto(furnitureEffectConf.effect_type_param, "HomeModule:ProcessVisitorComeIn")
      break
    end
  end
end

function HomeModule:DrawPetLayEggArea()
  local interactFurnitureList = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdGetInteractiveFurniture)
  if not interactFurnitureList then
    return
  end
  for i, Furniture in pairs(interactFurnitureList) do
    local center = Furniture:GetActorLocation() + UE.FVector(0, 0, 50)
    local diagonalLength = _G.DataConfigManager:GetPetGlobalConfig("pet_lay_egg_distance").num
    local sideLength = diagonalLength / math.sqrt(2)
    UE4.UKismetSystemLibrary.Abs_DrawDebugBox(_G.UE4Helper.GetCurrentWorld(), center, UE.FVector(sideLength, sideLength, 0), UE4.FLinearColor(1, 0, 0, 1), UE.FRotator(0, 0, 0), 0, 1)
  end
end

local TopKFurnitureEmptyCache = {}

function HomeModule:OnCmdOpenFurnitureFilterPanel(...)
  self:OpenPanel("FurnitureFilterPanel", ...)
end

function HomeModule:OnCmdCloseFurnitureFilterPanel()
  self:ClosePanel("FurnitureFilterPanel")
end

function HomeModule:OpenFurniturePhotoView(DisplayData)
  self:OpenPanel("FurniturePhotoView", DisplayData)
end

return HomeModule
