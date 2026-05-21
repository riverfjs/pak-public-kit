local HomePropsData = Class("HomePropsData")
local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")

function HomePropsData:Ctor(RoomId, bTempData)
  self.RoomId = RoomId
  self.bTempData = bTempData
  self.TempLocalLocation = nil
  self.TempWorldRotation = nil
  self.Id = 0
  self.ConfId = 0
  self.Conf = nil
  self.PlaneMasterId = 0
  self.Location = UE.FVector(0, 0, 0)
  self.Rotator = UE.FRotator(0, 0, 0)
  self.ItemGid = 0
  self.ParentId = 0
  self.RotFlag = 0
  self.PropsActor = nil
  self.RealtimeParentPropsData = nil
  self.RealtimePlane = nil
  self.bInManagerSelected = nil
  self.TempFurnitureData = nil
  self.bExpandedInManager = false
end

function HomePropsData:GetConfigId()
  return self.ConfId
end

function HomePropsData:GetConfig()
  return self.Conf
end

function HomePropsData:IsValidConfig()
  return self.Conf and self.Conf.cell_width and self.Conf.cell_width > 0 and self.Conf.cell_length and self.Conf.cell_length > 0 and self:GetBlueprintClassPath()
end

function HomePropsData:GetSizeConfig()
  return self.Conf.cell_width, self.Conf.cell_length
end

local ChildActors = UE4.TArray(UE4.AActor)

function HomePropsData:ChangeRotation()
  self.RotFlag = (self.RotFlag + 1) % 4
  if not self.RealtimeParentPropsData then
    self.PropsActor:GetAttachedActors(ChildActors, true)
    for _, Child in tpairs(ChildActors) do
      if Child.PropsData then
        Child.PropsData:ChangeRotation()
      end
    end
  end
end

function HomePropsData:ResolveSubPropsActorArray()
  if not self.RealtimeParentPropsData and self.PropsActor then
    self.PropsActor:GetAttachedActors(ChildActors, true)
    for i = ChildActors:Length(), 1, -1 do
      if not ChildActors:Get(i).PropsData then
        ChildActors:Remove(i)
      end
    end
    return ChildActors
  end
end

function HomePropsData:Save()
  self.bTempData = false
  self.TempLocalLocation = nil
  self.TempWorldRotation = nil
  local Transform = self.RealtimePlane:Abs_GetTransform()
  local LocalRotation = HomeIndoorSandbox.Utils.GetRotationByFlag(self.RotFlag)
  local WorldRotation = Transform:TransformRotation(LocalRotation)
  self.Rotator = WorldRotation:ToRotator()
  self.Location = self.PropsActor:Abs_K2_GetActorLocation()
  self.PlaneMasterId = self.RealtimePlane.PlaneMasterId
  if self.RealtimeParentPropsData then
    self.ParentId = self.RealtimeParentPropsData.Id
  else
    self.ParentId = 0
  end
  if self.TempFurnitureData then
    HomeIndoorSandbox.Module:GetData():OnEditingFurniturePlaced(self, self.TempFurnitureData)
    self.TempFurnitureData = nil
  end
end

function HomePropsData:Recover(bNoClearTempFlag)
  if not bNoClearTempFlag then
    self.bTempData = false
    self.TempLocalLocation = nil
    if self.TempFurnitureData then
      HomeIndoorSandbox:Ensure(false, "logical error, recover unsaved furniture", self.TempFurnitureData.FurnitureItemConf.id)
    end
  end
  self.RealtimePlane = HomeIndoorSandbox.World:GetRoomById(self.RoomId):GetPlaneByActorId(self.PlaneMasterId)
  self:LoadRotFlagFromRotator()
  self.RealtimeParentPropsData = HomeIndoorSandbox.Server.WorldData:GetRoomData(self.RoomId):GetPropsDataById(self.ParentId)
end

function HomePropsData:LoadRotFlagFromRotator()
  local PlaneTransform = self.RealtimePlane:Abs_GetTransform()
  if self.bTempData and self.TempWorldRotation then
    local DesiredLocalRotation = PlaneTransform:InverseTransformRotation(self.TempWorldRotation:ToQuat()):ToRotator()
    local Yaw = DesiredLocalRotation.Yaw
    if Yaw < 0 then
      Yaw = Yaw + 360
    end
    local RotFlag = math.floor(Yaw / 90 + 0.5)
    DesiredLocalRotation = HomeIndoorSandbox.Utils.GetRotationByFlag(RotFlag)
    local WorldRotation = PlaneTransform:TransformRotation(DesiredLocalRotation)
    self.Rotator = WorldRotation:ToRotator()
    HomeIndoorSandbox:LogDebug("edit place props, initialize rotation=", self.Rotator, ",input world rotation=", self.TempWorldRotation)
    self.TempWorldRotation = nil
  end
  local LocalRotation = PlaneTransform:InverseTransformRotation(self.Rotator:ToQuat()):ToRotator()
  if LocalRotation.Yaw < 0 then
    LocalRotation.Yaw = LocalRotation.Yaw + 360
  end
  local RotFlag = math.floor(LocalRotation.Yaw / 90 + 0.5)
  HomeIndoorSandbox:Ensure(math.abs(RotFlag * 90 - LocalRotation.Yaw) < 1, "invalid rotation", self.Rotator)
  self.RotFlag = RotFlag
end

function HomePropsData:ResolvePropsActor()
  return self.PropsActor
end

function HomePropsData:ResolveParentPropsActor()
  if self.RealtimeParentPropsData then
    return self.RealtimeParentPropsData:ResolvePropsActor()
  end
end

function HomePropsData:OnPrePlaceProps(PropsActor)
  HomeIndoorSandbox:LogInfo("OnPrePlaceProps", self.Id, PropsActor)
  PropsActor.PropsData = self
  self.PropsActor = PropsActor
  self:Recover(true)
end

function HomePropsData:OnPostLoad(PropsActor)
  HomeIndoorSandbox:LogInfo("OnPostLoad", self.Id, PropsActor)
  if PropsActor.bIsFurnitureInHome and PropsActor.OnPostLoad then
    PropsActor:OnPostLoad(self)
  end
  if PropsActor.hasPoi then
    local PoiComp = PropsActor:GetComponentByClass(UE.UNRCHomePOIRuntimeComponent)
    if PoiComp and PoiComp.OnPostLoad then
      PoiComp:OnPostLoad(self)
    end
  end
  PropsActor:SetCameraCollisionEnabled(not HomeIndoorSandbox.HomeEditServ:InEditMode())
  HomeIndoorSandbox.HomeEditServ.EditContext:OnPropsCreated(self)
  self:SyncNpcComponents()
end

function HomePropsData:OnPreRelease()
  self.PropsActor = nil
  self.RealtimePlane = nil
  self.TempFurnitureData = nil
end

local COMPARATOR_

local function COMPARE_VAL(a, b)
  return math.abs(a - b) < 5
end

function HomePropsData.GetSerializeComparatorTable()
  if not COMPARATOR_ then
    COMPARATOR_ = {
      position = {
        dir = {
          x = COMPARE_VAL,
          y = COMPARE_VAL,
          z = COMPARE_VAL
        }
      }
    }
  end
  return COMPARATOR_
end

local NIL_FIELDS

function HomePropsData.GetSerializeNilFields()
  if not NIL_FIELDS then
    NIL_FIELDS = {npc_id = true, dynamic_npc_ids = true}
  end
  return NIL_FIELDS
end

function HomePropsData:Serialize()
  if not HomeIndoorSandbox:Ensure(0 ~= self.Id, "invalid props id") then
    return
  end
  local Table = {
    furniture_guid = self.Id,
    item_gid = self.ItemGid,
    parent_furniture_guid = self.ParentId,
    config_id = self.Conf.id,
    position = {
      pos = {
        x = math.floor(self.Location.X * 100),
        y = math.floor(self.Location.Y * 100),
        z = math.floor(self.Location.Z * 100)
      },
      dir = {
        x = math.floor(self.Rotator.Roll * 100),
        y = math.floor(self.Rotator.Pitch * 100),
        z = math.floor(self.Rotator.Yaw * 100)
      }
    },
    npc_id = self.NpcId or 0,
    dynamic_npc_ids = self.DynamicNpcIdList
  }
  return Table
end

function HomePropsData:Deserialize(Table, Extra)
  self.Id = Table.furniture_guid or 0
  self.ItemGid = Table.item_gid or 0
  self.ParentId = Table.parent_furniture_guid or 0
  self.ConfId = Table.config_id or 0
  self.PlaneMasterId = Extra.plane_master_guid or 0
  local Point = Table.position or {}
  local Pos = Point.pos or {}
  local Dir = Point.dir or {}
  self.Location.X = (Pos.x or 0) / 100
  self.Location.Y = (Pos.y or 0) / 100
  self.Location.Z = (Pos.z or 0) / 100
  local WorldRotX = (Dir.x or 0) / 100
  local WorldRotY = (Dir.y or 0) / 100
  local WorldRotZ = (Dir.z or 0) / 100
  self.Rotator = UE.FRotator(WorldRotY, WorldRotZ, WorldRotX)
  self.NpcId = Table.npc_id or 0
  self.DynamicNpcIdList = Table.dynamic_npc_ids or {}
  if HomeIndoorSandbox:Ensure(0 ~= self.Id, "invalid props id") and HomeIndoorSandbox:Ensure(0 ~= self.ConfId, "invalid props conf id") then
    self.Conf = DataConfigManager:GetFurnitureItemConf(self.ConfId)
  end
  if 0 ~= self.NpcId then
    HomeIndoorSandbox:LogDebug("Furniture bind npc", self.Id, self.ConfId, self.NpcId)
  end
end

function HomePropsData:GetName()
  if self.Conf then
    return self.Conf.name
  end
end

function HomePropsData:GetComfortVal()
  return self.Conf and self.Conf.comfort or 0
end

function HomePropsData:GetTabConf()
  if self.Conf then
    local Conf = DataConfigManager:GetFurnitureClassificationConf(self.Conf.classification)
    return Conf
  end
end

function HomePropsData:GetTypeEnum()
  if self.Conf then
    return self.Conf.type
  end
end

function HomePropsData:GetWidth()
  if self.Conf then
    return self.Conf.cell_width
  end
end

function HomePropsData:GetLength()
  if self.Conf then
    return self.Conf.cell_length
  end
end

function HomePropsData:GetBlueprintClassPath()
  if self.Conf then
    local Path = self.Conf.model
    if not string.EndsWith(Path, "_C") then
      local t = string.Split(Path, "/")
      if t then
        local name = t[#t]
        if string.find(name, ".") then
          return Path .. "_C"
        end
        return string.format("%s.%s_C", Path, name)
      end
    elseif Path and "" ~= Path then
      return Path
    end
  end
end

function HomePropsData:GetIcon()
  if self.Conf then
    return self.Conf.icon
  end
end

function HomePropsData:AnyDynamicNpc()
  if self.DynamicNpcIdList and 0 ~= #self.DynamicNpcIdList then
    for i, NpcId in pairs(self.DynamicNpcIdList) do
      local Npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, NpcId)
      if Npc then
        return true
      end
    end
  end
  return false
end

function HomePropsData:UpdateDynamicNpc(DynamicIdList)
  HomeIndoorSandbox:LogDebug("UpdateDynamicNpc", self.Id, table.concat(DynamicIdList, ";"))
  self.DynamicNpcIdList = DynamicIdList
end

function HomePropsData:UpdateNpc(NpcId)
  HomeIndoorSandbox:LogDebug("UpdateNpc", self.Id, NpcId)
  self.NpcId = NpcId
end

function HomePropsData:GetConfigNpcId()
  return self.NpcId
end

function HomePropsData:GetDynamicNpcIdList()
  return self.DynamicNpcIdList
end

function HomePropsData:SyncNpcComponents()
  if self.NpcId and 0 ~= self.NpcId then
    local Npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.NpcId)
    if Npc then
      local Comp = Npc:GetComponent(HomeNpcInfoComponent)
      if Comp then
        Comp:OnFurniturePostLoad()
      end
    end
    if self.DynamicNpcIdList then
      for i, NpcId in pairs(self.DynamicNpcIdList) do
        Npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, NpcId)
        if Npc then
          local Comp = Npc:GetComponent(HomeNpcInfoComponent)
          if Comp then
            Comp:OnFurniturePostLoad()
          end
        end
      end
    end
  end
end

function HomePropsData:Abs_GetTransform()
  return UE.FTransform(self.Rotator:ToQuat(), self.Location, FVectorOne)
end

return HomePropsData
