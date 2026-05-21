local HomePropsData = require("NewRoco/Modules/System/Home/IndoorSandbox/Data/HomePropsData")
local HomeDecoData = require("NewRoco/Modules/System/Home/IndoorSandbox/Data/HomeDecoData")
local HomeRoomData = Class("HomeRoomData")

function HomeRoomData:Ctor(RoomId)
  self.RoomId = RoomId
  self.PropsDataMap = {}
  self.PropsDataList = {}
  self.NoDependencyPropsDataList = {}
  self.DependencyPropsDataList = {}
  self.DecoDataMap = {}
  self.DecoDataList = {}
end

function HomeRoomData:ClearRoomData()
  local PropsDataMap = self.PropsDataMap
  self.DecoDataMap = {}
  self.DecoDataList = {}
  self:ClearRoomPropsData()
  return PropsDataMap
end

function HomeRoomData:ClearRoomPropsData()
  self.PropsDataList = {}
  self.PropsDataMap = {}
  self.NoDependencyPropsDataList = {}
  self.DependencyPropsDataList = {}
end

function HomeRoomData:GetPropsDataList()
  return self.PropsDataList
end

function HomeRoomData:HasPropsData(PropsData)
  if not PropsData then
    return false
  end
  return self.PropsDataMap[PropsData.Id]
end

function HomeRoomData:CreateDynamicDecoDataByConfig(InteriorFinishConf, ItemGid)
  if InteriorFinishConf then
    local Data = HomeDecoData(InteriorFinishConf.id, self.RoomId)
    Data.bTempData = true
    Data:Deserialize({
      config_id = InteriorFinishConf.id,
      item_gid = ItemGid
    })
    return Data
  end
end

function HomeRoomData:GetDecoDataById(Id)
  return Id and self.DecoDataMap[Id]
end

function HomeRoomData:GetDecoDataByMainType(MainType)
  for i = #self.DecoDataList, 1, -1 do
    if self.DecoDataList[i]:GetConfigMainType() == MainType then
      return self.DecoDataList[i]
    end
  end
end

function HomeRoomData:CreateDynamicPropsDataByConfig(Config, FurnitureData, RoomPlane, TempLocalLocation, ParentPropsData, WorldRotation)
  if Config.cell_length > 0 and Config.cell_width > 0 and FurnitureData then
    local NewGuid = HomeIndoorSandbox.Utils.NewGuid_UInt64
    local Guid = NewGuid(HomeIndoorSandbox.Server.WorldData.HomeFurnitureGuidSet)
    if not Guid then
      return
    end
    local Data = HomePropsData(self.RoomId, true)
    Data.TempLocalLocation = TempLocalLocation
    Data.TempFurnitureData = FurnitureData
    Data.TempWorldRotation = WorldRotation
    Data:Deserialize({
      furniture_guid = Guid,
      item_gid = FurnitureData.BagItem.gid or -1,
      parent_furniture_guid = ParentPropsData and ParentPropsData.Id or 0,
      config_id = Config.id,
      position = {
        dir = {
          x = math.floor(RoomPlane.Rotator.Roll * 100),
          y = math.floor(RoomPlane.Rotator.Pitch * 100),
          z = math.floor(RoomPlane.Rotator.Yaw * 100)
        }
      }
    }, {
      plane_master_guid = RoomPlane.PlaneMasterId
    })
    HomeIndoorSandbox:Ensure(0 == Data.RotFlag, "invalid plane rotation", Data.RotFlag)
    return Data
  end
end

function HomeRoomData:RemovePropsData(PropsData)
  local Exists = self.PropsDataMap[PropsData.Id]
  if Exists then
    self.PropsDataMap[PropsData.Id] = nil
    for i, Data in ipairs(self.PropsDataList) do
      if Data == PropsData then
        table.remove(self.PropsDataList, i)
        break
      end
    end
    for i, Data in ipairs(self.DependencyPropsDataList) do
      if Data == PropsData then
        table.remove(self.DependencyPropsDataList, i)
        break
      end
    end
    for i, Data in ipairs(self.NoDependencyPropsDataList) do
      if Data == PropsData then
        table.remove(self.NoDependencyPropsDataList, i)
        break
      end
    end
  end
end

function HomeRoomData:RemoveDecoDataByIndex(Index)
  local DecoData = table.remove(self.DecoDataList, Index)
  self.DecoDataMap[DecoData.ConfId] = nil
end

function HomeRoomData:AddPropsData(Data)
  if HomeIndoorSandbox:Ensure(0 ~= Data.Id, "invalid props id") and HomeIndoorSandbox:Ensure(not self.PropsDataMap[Data.Id], "add exists props", Data.Id) then
    HomeIndoorSandbox:Ensure(not Data.bTempData, "add temp props data", Data.Id)
    self.PropsDataMap[Data.Id] = Data
    table.insert(self.PropsDataList, Data)
    if 0 ~= Data.ParentId then
      HomeIndoorSandbox:LogInfo("dependency props", Data.Id, Data.ParentId)
      table.insert(self.DependencyPropsDataList, Data)
    else
      HomeIndoorSandbox:LogInfo("no dependency props", Data.Id, Data.ParentId)
      table.insert(self.NoDependencyPropsDataList, Data)
    end
  end
end

function HomeRoomData:AddDecoData(Data)
  if HomeIndoorSandbox:Ensure(0 ~= Data.ConfId, "invalid deco id") and HomeIndoorSandbox:Ensure(not self.DecoDataMap[Data.ConfId], "add exists deco", Data.ConfId) then
    self.DecoDataMap[Data.ConfId] = Data
    table.insert(self.DecoDataList, Data)
  end
end

function HomeRoomData:GetPropsDataByListIndex(Index)
  return self.PropsDataList[Index]
end

function HomeRoomData:GetDependencyPropsDataList()
  return self.DependencyPropsDataList
end

function HomeRoomData:GetNoDependencyPropsDataList()
  return self.NoDependencyPropsDataList
end

function HomeRoomData:GetPropsCount()
  return #self.PropsDataList
end

function HomeRoomData:GetDecoDataList()
  return self.DecoDataList
end

function HomeRoomData:GetPropsDataById(Id)
  return self.PropsDataMap[Id]
end

function HomeRoomData:GetDecoCount()
  return #self.DecoDataList
end

function HomeRoomData:Serialize()
  if not HomeIndoorSandbox:Ensure(0 ~= self.RoomId, "invalid room id") then
    return
  end
  local Table = {
    room_id = self.RoomId,
    room_name = self.RoomName,
    room_plane_list = {},
    decoration_list = {}
  }
  local PlaneSet = {}
  for i, PropsData in ipairs(self.PropsDataList) do
    if PropsData.bTempData then
      HomeIndoorSandbox:Ensure(false, "logical error, cannot upload unsaved furnitures", PropsData.Id)
    else
      local Out = PropsData:Serialize()
      if Out then
        local Plane = PlaneSet[PropsData.PlaneMasterId]
        if not Plane then
          Plane = {
            plane_guid = PropsData.PlaneMasterId,
            furniture_list = {}
          }
          table.insert(Table.room_plane_list, Plane)
          PlaneSet[PropsData.PlaneMasterId] = Plane
        end
        table.insert(Plane.furniture_list, Out)
      end
    end
  end
  for i, DecoData in ipairs(self.DecoDataList) do
    if DecoData.bTempData then
      HomeIndoorSandbox:Ensure(false, "logical error, cannot upload unsaved decorations", DecoData.ConfId)
    else
      local Out = DecoData:Serialize()
      if Out then
        table.insert(Table.decoration_list, Out)
      end
    end
  end
  return Table
end

function HomeRoomData:OnServerSaveConfirm(Serialize)
  self.RawData = Serialize
end

function HomeRoomData:OnServerRecoverConfirm()
  self:Deserialize(self.RawData)
end

function HomeRoomData:InternalDeserializeProps(Table)
  self.PropsDataList = {}
  self.PropsDataMap = {}
  self.NoDependencyPropsDataList = {}
  self.DependencyPropsDataList = {}
  local Sandbox = HomeIndoorSandbox
  Sandbox:Ensure(0 ~= self.RoomId, "invalid room id")
  local Planes = Table.room_plane_list or {}
  for i, v in ipairs(Planes) do
    local Props = v.furniture_list or {}
    local PlaneGuid = v.plane_guid
    for j, PropsDataTable in ipairs(Props) do
      local PropsId = PropsDataTable.furniture_guid or 0
      if Sandbox:Ensure(0 ~= PropsId, "invalid props id") then
        local Data = HomePropsData(self.RoomId)
        Data:Deserialize(PropsDataTable, {plane_master_guid = PlaneGuid})
        self:AddPropsData(Data)
        if not Data:IsValidConfig() then
          HomeIndoorSandbox:Ensure(false, "invalid furniture config, maybe server/client not match or config changed", "id=", Data.Id, "confId=", Data.ConfId, "conf=", Data.Conf, "width=", Data.Conf and Data.Conf.cell_width, "length=", Data.Conf and Data.Conf.cell_length, "path=", Data:GetBlueprintClassPath())
        end
      end
    end
  end
  HomeIndoorSandbox.World:MarkWorldPlaneDirty()
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnHomeRoomLayoutChanged, self)
end

function HomeRoomData:InternalDeserializeDecorations(Table)
  self.DecoDataMap = {}
  self.DecoDataList = {}
  local Sandbox = HomeIndoorSandbox
  local DecoDataTable = Table.decoration_list or {}
  for i, DecoData in ipairs(DecoDataTable) do
    local DecoId = DecoData.config_id or 0
    if Sandbox:Ensure(0 ~= DecoId, "invalid deco id") then
      local Data = HomeDecoData(DecoId, self.RoomId)
      Data:Deserialize(DecoData)
      self:AddDecoData(Data)
    end
  end
end

function HomeRoomData:Deserialize(Table)
  self.TempFlags = {bPropsChanged = true, bDecosChanged = true}
  self.RawData = Table
  self:ClearRoomData()
  self.RoomId = Table.room_id or 0
  self.RoomName = Table.room_name or ""
  if self.RoomName == "" then
    local Names = DataConfigManager:GetHomeGlobalConfig("room_name").str
    Names = string.split(Names, ";")
    self.RoomName = Names[self.RoomId] or string.format("%s", self.RoomId)
  end
  self:InternalDeserializeProps(Table)
  self:InternalDeserializeDecorations(Table)
  self:OnTest()
end

function HomeRoomData:OnTest()
end

function HomeRoomData:UpdatePropsBindingInfo(RoomInfo)
  if not RoomInfo then
    return
  end
  local RoomPlaneList = RoomInfo.room_plane_list
  if RoomPlaneList then
    for j, RoomPlane in pairs(RoomPlaneList) do
      local FurnitureList = RoomPlane.furniture_list
      if FurnitureList then
        for k, Furniture in pairs(FurnitureList) do
          local PropsData = HomeIndoorSandbox.Server.WorldData:GetFurnitureById(Furniture.furniture_guid)
          if PropsData then
            PropsData:UpdateDynamicNpc(Furniture.dynamic_npc_ids or {})
            PropsData:UpdateNpc(Furniture.npc_id or 0)
          else
            HomeIndoorSandbox:Ensure(false, "Cannot found props data", Furniture.furniture_guid)
          end
        end
      end
    end
  end
end

function HomeRoomData:CompareUpdateRoomInfo(RoomInfo)
  local RoomId = RoomInfo.room_id or 0
  if RoomId ~= self.RoomId then
    self:Deserialize(RoomInfo)
    return true
  end
  self.RoomId = RoomId
  local Serialized = self:Serialize()
  local PropsFieldComparator = HomePropsData.GetSerializeComparatorTable()
  local PropsFiledNilFields = HomePropsData.GetSerializeNilFields()
  local bPropsChanged = not HomeIndoorSandbox.Utils.DeepEquals(RoomInfo.room_plane_list, Serialized.room_plane_list, nil, PropsFieldComparator, PropsFiledNilFields)
  local bDecosChanged = not HomeIndoorSandbox.Utils.DeepEquals(RoomInfo.decoration_list, Serialized.decoration_list)
  if bPropsChanged then
    self:InternalDeserializeProps(RoomInfo)
  else
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnHomeRoomLayoutChanged, self)
  end
  if bDecosChanged then
    self:InternalDeserializeDecorations(RoomInfo)
  end
  self.TempFlags = {bPropsChanged = bPropsChanged, bDecosChanged = bDecosChanged}
  self.RawData = RoomInfo
  self:OnTest()
  return bPropsChanged or bDecosChanged, bPropsChanged, bDecosChanged
end

function HomeRoomData:CalcComfortValue()
  local FurnitureComfortVal = 0
  local DecoComfortVal = self:CalcDecoComfortValue()
  for i, v in ipairs(self.PropsDataList) do
    FurnitureComfortVal = FurnitureComfortVal + v:GetComfortVal()
  end
  HomeIndoorSandbox:LogDebug("room furniture comfort value=", self.RoomId, FurnitureComfortVal)
  HomeIndoorSandbox:LogDebug("room decoration comfort value=", self.RoomId, DecoComfortVal)
  return DecoComfortVal + FurnitureComfortVal
end

function HomeRoomData:CalcDecoComfortValue()
  local DecoComfortVal = 0
  local DecoDataList = self.DecoDataList
  local MainConfigTypes = {}
  for i = #DecoDataList, 1, -1 do
    local DecoData = DecoDataList[i]
    local MainConfigType = DecoData:GetConfigMainType()
    if MainConfigTypes[MainConfigType] then
    else
      DecoComfortVal = DecoComfortVal + DecoData:GetComfortVal()
      MainConfigTypes[MainConfigType] = DecoData
    end
  end
  return DecoComfortVal
end

function HomeRoomData:ApplyDecoration(DecorateId)
end

return HomeRoomData
