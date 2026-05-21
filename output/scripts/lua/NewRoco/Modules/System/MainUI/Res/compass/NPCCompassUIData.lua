local CompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.CompassUIData")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local Base = CompassUIData
local NPCCompassUIData = Base:Extend("NPCCompassUIData")

function NPCCompassUIData:Ctor(fatherLayer, compass, Space, LevelArray, MoveLevel)
  Base.Ctor(self, fatherLayer, compass, Space, LevelArray)
  self.MapAreaState = CompassUIData.MapAreaState
  self.MoveNpcLevelArray = MoveLevel
  self.IsRegisterNpcCreate = false
end

function NPCCompassUIData:InitData(Info, worldMap, ViewField)
  Base.InitData(self, Info, worldMap, ViewField)
  self:OnNPCLeave()
  self.NpcAngleLimit = ViewField
  self:EnableDistanceLevel()
  self.CurState = CompassUIData.MapAreaState.MAP_NPC
  self.NpcConfig = Info.NpcConfig
  self.petInfo = Info.petInfo
  self.IsOwlStarNpc = self.NpcConfig.min_map_disappear and self.NpcConfig.min_map_disappear > 0
  self.IsCathPetNpc = Info.IsCathPetNpc
  if self.IsCathPetNpc then
    self:DisableDistanceLevel()
  end
  self.NPC_level = Info.NPC_Level or 1
  self.glass_info = Info.glass_info
  self.mutation_type = Info.mutation_type
  self.state = Info.state
  self.isFound = Info.isFound
  self.npc_refresh_id = Info.npc_refresh_id
  self.ownerId = Info.ownerId
  self.layer_id = Info.layer_id
  self.worldMapActivityConf = Info.worldMapActivityConf
end

function NPCCompassUIData:UpdateData(Info, worldMap, ViewField)
  self:SetPos(Info.Position)
  self.WorldMapConfig = worldMap
  self.worldMapActivityConf = Info.worldMapActivityConf
  self.IsUnLock = Info.IsUnLock
  self.IsFinish = Info.IsFinish
  self.NpcConfig = Info.NpcConfig
  self.NPC_level = Info.NPC_Level or 1
  self.petInfo = Info.petInfo
  self.npc_refresh_id = Info.npc_refresh_id
  self.ownerId = Info.ownerId
  self.layer_id = Info.layer_id
  if self.LogicId and self.LogicId ~= Info.LogicId then
    self:OnNPCLeave()
    self.LogicId = Info.LogicId
    self:GetSceneNpc()
  end
  self:SetIcon()
end

function NPCCompassUIData:SetIsShow(isShow)
  if Base.SetIsShow(self, isShow) then
    if self.WorldMapConfig and self.WorldMapConfig.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING or self.WorldMapConfig.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1152, "NPCCompassUIData:SetIsShow")
    end
    self:GetSceneNpc()
  end
  if self.npc and self.IsShow then
    self:IsAddInMoveDisLayer(true)
  else
    self:IsAddInMoveDisLayer(false)
  end
end

function NPCCompassUIData:GetSceneNpc()
  if self.IsShow and self.LogicId then
    if not self.npc then
      self.npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByLogicID, self.LogicId or -1)
      if not self.npc then
        if not self.IsRegisterNpcCreate then
          self.IsRegisterNpcCreate = true
          _G.NRCEventCenter:RegisterEvent("NPCCompassUIData", self, NPCModuleEvent.On_NPC_Create, self.OnNPCCreate)
        end
      else
        self.npc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNPCLeave)
      end
    end
  else
    self:OnNPCLeave()
  end
end

function NPCCompassUIData:OnNPCCreate(npc)
  if self.IsShow and self.LogicId and npc.serverData.base.logic_id == self.LogicId then
    self.npc = npc
    self.npc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNPCLeave)
  end
end

function NPCCompassUIData:OnNPCLeave()
  if self.npc then
    self.npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNPCLeave)
    self.npc = nil
    self:IsAddInMoveDisLayer(false)
  end
  if self.IsRegisterNpcCreate then
    self.IsRegisterNpcCreate = false
    _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_Create, self.OnNPCCreate)
  end
end

function NPCCompassUIData:UpdateWorldPos()
  if self.npc and self.npc.viewObj then
    local pos = self.npc:GetActorLocation()
    if pos then
      self.WorldPos.X = pos.X
      self.WorldPos.Y = pos.Y
      self.WorldPos.Z = pos.Z
    end
  end
end

function NPCCompassUIData:IsAddInMoveDisLayer(value)
  if self.MoveNpcLevelArray and self.Id then
    if not self.MoveNpcLevelArray.KeysList then
      self.MoveNpcLevelArray.UpdateIndex = 1
      self.MoveNpcLevelArray.NeedUpdateCount = 0
      self.MoveNpcLevelArray.KeysList = {}
      self.MoveNpcLevelArray.ItemNumber = 0
    end
    if value then
      if not self.MoveNpcLevelArray.KeysList[self.Id] then
        self.MoveNpcLevelArray.ItemNumber = self.MoveNpcLevelArray.ItemNumber + 1
        if 1 == self.MoveNpcLevelArray.ItemNumber then
          if self.MoveNpcLevelArray.CurUpdateKey then
            Log.Error("zgx should not has value", self.MoveNpcLevelArray.CurUpdateKey, self.MoveNpcLevelArray.DistanceLevel)
          end
          self.MoveNpcLevelArray.CurUpdateKey = self.Id
        end
        self.MoveNpcLevelArray.KeysList[self.Id] = -1
      end
    elseif self.MoveNpcLevelArray.KeysList[self.Id] then
      self.MoveNpcLevelArray.ItemNumber = self.MoveNpcLevelArray.ItemNumber - 1
      if self.MoveNpcLevelArray.CurUpdateKey == self.Id then
        self.MoveNpcLevelArray.CurUpdateKey = next(self.MoveNpcLevelArray.KeysList, self.Id)
        if self.MoveNpcLevelArray.ItemNumber > 0 and not self.MoveNpcLevelArray.CurUpdateKey then
          self.MoveNpcLevelArray.CurUpdateKey = next(self.MoveNpcLevelArray.KeysList)
        end
      end
      self.MoveNpcLevelArray.KeysList[self.Id] = nil
    end
  end
end

function NPCCompassUIData:ResetData()
  self.petInfo = nil
  Base.ResetData(self)
end

return NPCCompassUIData
