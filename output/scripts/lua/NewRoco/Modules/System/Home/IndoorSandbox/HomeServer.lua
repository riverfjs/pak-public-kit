local HomeWorldData = require("NewRoco/Modules/System/Home/IndoorSandbox/Data/HomeWorldData")
local HomeVisitData = require("NewRoco/Modules/System/Home/IndoorSandbox/Data/HomeVisitData")
local ErrorCodeDesc = require("Data.PB.ErrorCodeDesc")
local Delegate = require("Utils.Delegate")
local HomePropertyBinder = Class("HomePropertyBinder")

function HomePropertyBinder:Ctor(Cmd, RequestFields)
  self.Cmd = Cmd
  self.RequestFields = RequestFields
  self.bSuccess = nil
  self.OnReceived = Delegate()
end

function HomePropertyBinder:Promise(Caller, Function)
  local function ForwardFunction()
    if Caller then
      if not Caller.WidgetTreeRef or UE.UObject.IsValid(Caller) then
        Function(Caller, self.Response, self.bSuccess)
      end
    else
      Function(self.Response, self.bSuccess)
    end
  end
  
  if self.Response then
    ForwardFunction()
  else
    self.OnReceived:Add(nil, ForwardFunction)
  end
  return self
end

function HomePropertyBinder:Work()
  if self.Request then
    return
  end
  self.Request = nil
  self.Response = nil
  local ProtoName = _G.ProtoCMD.MessageMap[self.Cmd]
  if not ProtoName then
    HomeIndoorSandbox:Ensure(false, "cannot found proto name by cmd", self.Cmd)
    return false
  end
  local GetterName = string.gsub(ProtoName, "%.Next%.", "new")
  local ProtoGetter = _G.ProtoMessage[GetterName]
  if not ProtoGetter then
    HomeIndoorSandbox:Ensure(false, "cannot found proto getter by cmd name", self.Cmd, GetterName)
    return
  end
  local Cmd = self.Cmd
  local Req = ProtoGetter(_G.ProtoMessage)
  if not Req then
    HomeIndoorSandbox:Ensure(false, "cannot found proto by cmd name", self.Cmd)
    return
  end
  if self.RequestFields then
    for k, v in pairs(self.RequestFields) do
      Req[k] = v
    end
  end
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    self.bSuccess = _G.HomeIndoorSandbox.Server:IfReceiveSuccess(_protoData, ProtoName)
    self.Response = _protoData
    self:OnCallback()
  end
  
  local bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle, false, true)
  if bSuccess then
    self.Request = Req
  else
    HomeIndoorSandbox:Ensure(false, "upstream locked", self.Cmd)
  end
  return self
end

function HomePropertyBinder:OnCallback()
  self.OnReceived:Invoke(self.Response, self.bSuccess)
end

local HomeServer = Class("HomeServer")

function HomeServer:Ctor()
  self.WorldData = HomeWorldData()
  self.MasterId = nil
  self.VisitData = HomeVisitData()
end

function HomeServer:IsLocalMaster()
  return self.MasterId == _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
end

function HomeServer:IfReceiveSuccess(Proto, RspName)
  if Proto and Proto.ret_info then
    if 0 ~= Proto.ret_info.ret_code then
      HomeIndoorSandbox:Ensure(false, RspName, "err:", Proto.ret_info.ret_code, Proto.ret_info.ret_msg)
    else
      return true
    end
  else
    HomeIndoorSandbox:Ensure(false, RspName, "err: not ret_info")
  end
  return false
end

function HomeServer:OnNotifyHomeInfo(HomeInfo)
  self.MasterId = HomeInfo and HomeInfo.home_owner_id
  self.WorldData:Deserialize(HomeInfo or {})
end

function HomeServer:ReqEnterHomeIndoor(Callback, PlayerUin, TargetHomeSceneType, worldMapConfId)
  Callback = Callback or HomeIndoorSandbox.DummyFunction
  TargetHomeSceneType = TargetHomeSceneType or ProtoEnum.ZoneSceneHomeEnterReq.HomeSceneType.HomeSceneType_Home
  if Enum.PlayerFunctionBanType.PFBT_VISIT_HOME then
    local Ban, _ = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_VISIT_HOME, true, true)
    if Ban then
      Callback(false)
      return
    end
  end
  if not PlayerUin then
    local OwnerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
    if 0 ~= OwnerUin then
      PlayerUin = OwnerUin
    else
      PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    end
  end
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_ENTER_REQ
  local Req = ProtoMessage:newZoneSceneHomeEnterReq()
  Req.home_owner_id = PlayerUin
  Req.home_scene_type = TargetHomeSceneType
  if worldMapConfId and worldMapConfId > 0 then
    Req.world_map_cfg_id = worldMapConfId
  end
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeEnterRsp")
    if not (not bSuccess and _protoData.ret_info) or HomeIndoorSandbox.HomeTipsServ:ConditionalDisplayError(_protoData.ret_info) then
    elseif HomeIndoorSandbox.HomeTipsServ:TryProcessHomeVisitLimits(_protoData.ret_info, _protoData) then
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle, true, true, 1)
  if not bSuccess then
    Callback(false)
  end
end

function HomeServer:ReqExitHome(Callback)
  Callback = Callback or HomeIndoorSandbox.DummyFunction
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_LEAVE_REQ
  local Req = ProtoMessage:newZoneSceneHomeLeaveReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeLeaveRsp")
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle, true, false, 1)
  if not bSuccess then
    Callback(false)
  end
end

function HomeServer:ReqUpgradeHome(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_FINISH_EXPAND_ROOM_REQ
  local Req = ProtoMessage:newZoneSceneHomeFinishExpandRoomReq()
  Req.room_level = self.WorldData.RoomLevel + 1
  HomeIndoorSandbox:LogWarn("ReqUpgradeHome", Req.room_level)
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    Log.Dump(_protoData, 10, "HOME_INFO ZoneSceneHomeFinishExpandRoomRsp")
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeFinishExpandRoomRsp")
    HomeIndoorSandbox:LogWarn("ReqUpgradeHome Rsp", _protoData.home_info and _protoData.home_info.room_level)
    if bSuccess then
      self.WorldData:Deserialize(_protoData.home_info)
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(false)
  end
end

function HomeServer:ReqStartUpgradeHome(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_START_EXPAND_ROOM_REQ
  local Req = ProtoMessage:newZoneSceneHomeStartExpandRoomReq()
  Req.room_level = self.WorldData.RoomLevel + 1
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeStartExpandRoomRsp")
    if bSuccess then
      self.WorldData.RoomExpansionInfo = _protoData.room_expansion_info
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(false)
  end
end

function HomeServer:ReqEnterEditMode(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_ENTER_EDIT_REQ
  local Req = ProtoMessage:newZoneSceneHomeEnterEditReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  Req.is_edit = true
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeEnterEditRsp")
    if not bSuccess then
      HomeIndoorSandbox:LogWarn("cannot enter edit mode")
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    HomeIndoorSandbox:LogWarn("ReqEnterEditMode, send failed")
    Callback(bSuccess)
  end
end

function HomeServer:ReqExitEditMode(Callback)
  Callback = Callback or HomeIndoorSandbox.DummyFunction
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_ENTER_EDIT_REQ
  local Req = ProtoMessage:newZoneSceneHomeEnterEditReq()
  Req.is_edit = false
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeEnterEditRsp")
    if not bSuccess then
      HomeIndoorSandbox:LogWarn("cannot exit edit mode")
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    HomeIndoorSandbox:LogWarn("ReqExitEditMode, send failed")
    Callback(bSuccess)
  end
end

function HomeServer:ReqUploadRooms(Callback, RoomIdList, bForce, InSerialize)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_SAVE_ROOM_LAYOUT_REQ
  local Req = ProtoMessage:newZoneSceneHomeSaveRoomLayoutReq()
  local Serialize = InSerialize or self.WorldData:Serialize()
  Req.room_layout_info = Serialize.room_layout
  Req.force_save = bForce
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    Log.Dump(_protoData, 10, "HOME_INFO ZoneSceneHomeSaveRoomLayoutRsp")
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeSaveRoomLayoutRsp")
    if not bSuccess then
      if _protoData.ret_info and _protoData.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HOME_LAYOUT_REVIEW_FAILED then
        HomeIndoorSandbox.HomeTipsServ:ShowImportTips(LuaText.home_layout_release_contravention_tips)
      else
        HomeIndoorSandbox.HomeTipsServ:ShowImportTips(LuaText.home_layout_release_fail_tips)
      end
    elseif not bForce then
      HomeIndoorSandbox.HomeTipsServ:ShowImportTips(LuaText.home_layout_release_succeed_tips)
    end
    if bForce then
      Callback(true)
    else
      if HomeIndoorSandbox:InLocalMasterIndoor() then
        if not bSuccess then
          HomeIndoorSandbox.World:ReloadCacheWorldLayoutConditionally()
        else
          HomeIndoorSandbox.World:ReloadWorldLayoutConditionally(_protoData.room_layout_info)
        end
      end
      Callback(bSuccess)
    end
  end
  
  Log.Dump(Req, 10, "ZoneSceneHomeSaveRoomLayoutReq")
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle, nil, true)
  if not bSuccess then
    HomeIndoorSandbox:LogWarn("ReqUploadRooms, send failed")
    Callback(bSuccess)
  elseif not bForce then
    HomeIndoorSandbox.HomeEditServ:StartPublishCountDown()
  end
  return bSuccess
end

function HomeServer:GetLocalHomeBriefInfo()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    local home_info = (Player.serverData or {}).home_basic_info or {}.my_home_info
    if home_info then
      home_info.home_local_name = string.format(LuaText.home_name, home_info.home_name)
      local room_conf = DataConfigManager:GetRoomConf(home_info.room_level, true)
      home_info.home_tag_name = room_conf and room_conf.name or ""
    end
    return home_info
  end
end

function HomeServer:GetHomeRoomLevel()
  if HomeIndoorSandbox:InHomeIndoor() then
    return self.WorldData.RoomLevel
  else
    local Brief = self:GetDisplayHomeBriefInfo()
    if Brief then
      return Brief.room_level
    end
  end
  return 0
end

function HomeServer:GetDisplayHomeBriefInfo()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    local home_basic_info = (Player.serverData or {}).home_basic_info or {}
    local home_info = home_basic_info.target_home_info or home_basic_info.my_home_info
    if home_info then
      home_info.home_local_name = string.format(LuaText.home_name, home_info.home_name)
      local room_conf = DataConfigManager:GetRoomConf(home_info.room_level, true)
      home_info.home_tag_name = room_conf and room_conf.name or ""
    end
    if HomeIndoorSandbox:InLocalMasterIndoor() and home_info.home_owner_id == HomeIndoorSandbox.Server.MasterId then
      home_info.home_comfort_level = HomeIndoorSandbox.Server.WorldData.HomeComfortLevel
    end
    return home_info
  end
end

function HomeServer:GetExpansionStatus(RoomExpansionInfo, RoomLevel)
  local bHasRoomLevel = 0 ~= (RoomExpansionInfo and RoomExpansionInfo.room_level or 0)
  if not bHasRoomLevel then
    return HomeIndoorSandbox.Enum.EnmExpandStatus.None
  end
  if RoomLevel >= RoomExpansionInfo.room_level then
    HomeIndoorSandbox:Ensure(false, "why room_expansion_info.room_level <= current home room level", RoomExpansionInfo.room_level, RoomLevel)
    return HomeIndoorSandbox.Enum.EnmExpandStatus.None
  end
  local RoomLevelConf = DataConfigManager:GetRoomConf(RoomExpansionInfo.room_level)
  if not RoomLevelConf then
    return HomeIndoorSandbox.Enum.EnmExpandStatus.None
  end
  local Cost = RoomLevelConf.expend_cost_time or 0
  local ExpiredTime = RoomExpansionInfo.expansion_start_timestamp + Cost + 2
  local RemainTime = ExpiredTime - _G.ZoneServer:GetServerTime() / 1000
  if RemainTime < 0 then
    return HomeIndoorSandbox.Enum.EnmExpandStatus.ExpandEstablished
  end
  return HomeIndoorSandbox.Enum.EnmExpandStatus.Expanding, RemainTime, Cost, RoomLevelConf
end

function HomeServer:GetHomeInformation()
  local RoomLayout = HomeIndoorSandbox.Server.WorldData.RawRoomLayoutInfo
  local CurrRoomCnt = #((RoomLayout or {}).rooms or {})
  local TotalRoomCnt = 0
  local ROOM_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ROOM_CONF):GetAllDatas()
  local HomeLevel = HomeIndoorSandbox.Server.WorldData.HomeLevel
  for k, v in pairs(ROOM_CONF) do
    if HomeLevel >= v.home_level then
      TotalRoomCnt = TotalRoomCnt + 1
    end
  end
  local CurrPetCnt = #(HomeIndoorSandbox.Module.data:GetHomePetInfo() or {})
  local TotalPetCnt = 0
  local CurrFurnitureTypeCnt = 0
  local TotalFurnitureTypeCnt = HomeIndoorSandbox.Module.data.TotalFurnitureTypeCnt
  local Rooms = RoomLayout and RoomLayout.rooms or {}
  if Rooms then
    for _, Room in ipairs(Rooms) do
      local room_plane_list = Room.room_plane_list
      if room_plane_list then
        for i, plane in ipairs(room_plane_list) do
          local furniture_list = plane.furniture_list
          if furniture_list then
            for _, furniture in ipairs(furniture_list) do
              local Conf = DataConfigManager:GetFurnitureItemConf(furniture.config_id)
              if Conf and Conf.interact_type == Enum.FurniturelnteractType.FIT_REFRESH_PET then
                TotalPetCnt = TotalPetCnt + 1
                HomeIndoorSandbox:LogDebug("\229\176\143\231\170\157 \230\145\134\230\148\190\239\188\154", furniture.config_id, furniture.npc_id, furniture.furniture_guid)
              end
            end
          end
        end
      end
    end
  end
  HomeIndoorSandbox.Module.data:EvalCollectBagFurnitureItemInfo()
  for k, v in pairs(HomeIndoorSandbox.Module.data.FurnitureItemDataMap) do
    if v.FurnitureItemConf and v.FurnitureItemConf.interact_type == Enum.FurniturelnteractType.FIT_REFRESH_PET and v.BagItem then
      TotalPetCnt = TotalPetCnt + v.BagItem.num
      HomeIndoorSandbox:LogDebug("\229\176\143\231\170\157 \232\131\140\229\140\133\239\188\154", v.BagItem.num)
    end
  end
  local FarmModule = NRCModuleManager:GetModule("FarmModule")
  local CurrFarmLandCnt = FarmModule and FarmModule:GetCurUnlockFarmLandNum() or 0
  local TotalFarmLandCnt = FarmModule and FarmModule:GetCurMaxUnlockFarmLandNum() or 0
  return {
    {
      title = LuaText.home_report_room,
      cur_cnt = CurrRoomCnt,
      max_cnt = TotalRoomCnt,
      icon_name = "room_info_icon"
    },
    {
      title = LuaText.home_report_furniture,
      cur_cnt = CurrFurnitureTypeCnt,
      max_cnt = TotalFurnitureTypeCnt,
      icon_name = "furniture_info_icon",
      serverInfoBinder = self:AsyncGainServerInfo(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_GET_UNLOCKED_FURNITURE_INFO_REQ):Work()
    },
    {
      title = LuaText.home_report_farmland,
      cur_cnt = CurrFarmLandCnt,
      max_cnt = TotalFarmLandCnt,
      icon_name = "land_info_icon"
    },
    {
      title = LuaText.home_report_pet,
      cur_cnt = CurrPetCnt,
      max_cnt = TotalPetCnt,
      icon_name = "pet_info_icon"
    }
  }
end

function HomeServer:ReqFurnitureCreationList(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_HOME_WAREHOUSE_GET_BUILD_LIST_REQ
  local Req = ProtoMessage:newZoneHomeWarehouseGetBuildListReq()
  Req.home_id = self.MasterId
  if not self:IsLocalMaster() then
    Req.need_self_list = true
  else
    Req.need_self_list = false
  end
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneHomeWarehouseGetBuildListRsp")
    _protoData.ding_map = {}
    _protoData.home_map = {}
    _protoData.self_map = {}
    if bSuccess then
      for i, v in pairs(_protoData.ding_list or {}) do
        _protoData.ding_map[v] = true
      end
      for i, v in pairs(_protoData.home_list or {}) do
        _protoData.home_map[v] = true
      end
      if self:IsLocalMaster() then
        _protoData.self_map = _protoData.home_map
      else
        for i, v in pairs(_protoData.self_list or {}) do
          _protoData.self_map[v] = true
        end
      end
    else
      HomeIndoorSandbox:LogWarn("cannot get furniture build list")
    end
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    HomeIndoorSandbox:LogWarn("ReqFurnitureCreationList, send failed")
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:ReqCreateFurniture(Callback, ItemId, Num)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_HOME_WAREHOUSE_BUILD_REQ
  local Req = ProtoMessage:newZoneHomeWarehouseBuildReq()
  Req.bag_item_id = ItemId
  Req.num = Num
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneHomeWarehouseBuildRsp")
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    HomeIndoorSandbox:LogWarn("ReqBuildFurniture, send failed")
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:ReqHomeLeveRewardInfos(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_LEVEL_REWARD_REQ
  local Req = ProtoMessage:newZoneHomeQueryLevelRewardReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneHomeQueryLevelRewardRsp")
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:ReqClaimHomeLevelReward(Callback, Level)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_HOME_CLAIM_LEVEL_REWARD_REQ
  local Req = ProtoMessage:newZoneHomeClaimLevelRewardReq()
  Req.level = Level
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneHomeClaimLevelRewardRsp")
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:ReqHomeVisitHistoryInfo(Callback)
  Callback = Callback or HomeIndoorSandbox.DummyFunction
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_GET_VIST_HISTORY_REQ
  local Req = ProtoMessage:newZoneSceneHomeGetVistHistoryReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    self.VisitData:Deserialize(_protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneSceneHomeGetVistHistoryRsp")
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:ReqTaskInfoForExpandRoom(Callback)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ
  local Req = ProtoMessage:newZoneTaskQueryReq()
  local RoomLevelConf = DataConfigManager:GetRoomConf(HomeIndoorSandbox.Server.WorldData.RoomLevel + 1)
  if not RoomLevelConf then
    return false
  end
  local task_paragraph_id = RoomLevelConf.task
  Req.task_paragraph_id = task_paragraph_id
  Req.task_state = 0
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    bSuccess = self:IfReceiveSuccess(_protoData, "ZoneTaskQueryRsp")
    if bSuccess then
      local task_info_list = _protoData.task_info_list
      HomeIndoorSandbox.Module:GetData():UpdateExpandTask(task_paragraph_id, task_info_list)
    end
    Callback(bSuccess, _protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Callback(bSuccess)
  end
  return bSuccess
end

function HomeServer:AsyncGainServerInfo(Cmd, RequestFields)
  return HomePropertyBinder(Cmd, RequestFields)
end

return HomeServer
