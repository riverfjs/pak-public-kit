local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local Base = ActorComponent
local ThrowManagementComponent = Base:Extend("ThrowManagementComponent")

function ThrowManagementComponent:Ctor()
  Base.Ctor(self)
  self.ThrownSessions = table.new(0, 8)
  self.RawThrownPetInfo = table.new(0, 8)
  self.TempDict = table.new(0, 8)
  self.CachingSessions = setmetatable(table.new(0, 8), {__mode = "v"})
  self.LocalCachingSessions = setmetatable(table.new(0, 8), {__mode = "v"})
end

function ThrowManagementComponent:Attach(owner)
  Base.Attach(self, owner)
  if not self.owner.serverData then
    return
  end
  local Infos = self.owner.serverData.throwed_pet_infos
  self:UpdateThrowPetsFull(Infos)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.PreLoadMapStart, self.OnLoadMapStart)
end

function ThrowManagementComponent:DeAttach()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnLoadMapStart)
  Base.DeAttach(self)
end

function ThrowManagementComponent:OnLoadMapStart(SameScene)
  Log.Error("Change Scene Clearing Catch Sessions")
  local Num = table.len(self.CachingSessions)
  table.clear(self.CachingSessions)
  if Num > 0 then
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEnd)
  end
  if table.isNotEmpty(self.LocalCachingSessions) then
    table.clear(self.LocalCachingSessions)
  end
end

function ThrowManagementComponent:OnReConnect()
  if not self.owner.serverData then
    return
  end
  local Infos = self.owner.serverData.throwed_pet_infos
  self:UpdateThrowPetsFull(Infos)
end

function ThrowManagementComponent:UpdateData(ServerData, isReconnect)
  Base.UpdateData(self, ServerData, isReconnect)
  local Infos = ServerData.throwed_pet_infos
  self:UpdateThrowPetsFull(Infos)
end

function ThrowManagementComponent:UpdateThrowPetsFull(Infos)
  if Infos then
    for _, Info in ipairs(Infos) do
      self.RawThrownPetInfo[Info.npcId] = Info
    end
  end
  local RemoveList = {}
  local Sessions = ThrowSession.ActivePetSessions
  for Index, Session in ipairs(Sessions) do
    local GID = Session:GetGID()
    local Found = false
    if Infos then
      for _, Info in ipairs(Infos) do
        if Info.gid == GID then
          Found = true
          break
        end
      end
    end
    if Found then
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(GID)
      Session:SetPetData(PetData)
      Session:SetStatus(ThrowSessionStatusEnum.PostInteract)
      Session:ForceSetCanBeRecycle(true)
    else
      table.insert(RemoveList, 1, Index)
    end
  end
  for Index, Remove in ipairs(RemoveList) do
    local Removed = table.remove(Sessions, Remove)
    if Removed then
      Removed:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
  end
end

function ThrowManagementComponent:UpdateThrow(action)
  if action.throwed_pet_infos then
    for _, Added in ipairs(action.throwed_pet_infos) do
      self.RawThrownPetInfo[Added.npcId] = Added
    end
  end
  if action.delete_pet_gids then
    table.clear(self.TempDict)
    for ActorID, Info in pairs(self.RawThrownPetInfo) do
      if table.include(action.delete_pet_gids, Info.gid) then
        table.insert(self.TempDict, ActorID)
      end
    end
    for _, ActorID in ipairs(self.TempDict) do
      self.RawThrownPetInfo[ActorID] = nil
    end
    table.clear(self.TempDict)
    for ActorID, Session in pairs(self.ThrownSessions) do
      if table.include(action.delete_pet_gids, Session.petData.gid) then
        table.insert(self.TempDict, ActorID)
      end
    end
    for _, ActorID in ipairs(self.TempDict) do
      self.ThrownSessions[ActorID] = nil
    end
  end
end

function ThrowManagementComponent:HasThrowSession(actorID)
  return self.RawThrownPetInfo[actorID] ~= nil
end

function ThrowManagementComponent:GetThrowSession(actorID, GID)
  local CachedSession = self.ThrownSessions[actorID]
  if CachedSession and CachedSession.Status ~= ThrowSessionStatusEnum.Destroyed then
    return CachedSession
  end
  local Info = self.RawThrownPetInfo[actorID]
  if Info then
    GID = Info.gid
  end
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(GID)
  if not petData then
    Log.Error("Can't get pet data with gid", GID)
    return nil
  end
  local Session = ThrowSession.CreatePet(petData)
  self.ThrownSessions[actorID] = Session
  return Session
end

function ThrowManagementComponent:AddThrowSession(actorID, Session)
  self.ThrownSessions[actorID] = Session
end

function ThrowManagementComponent:StartCatch(Session)
  if not Session then
    Log.Error("ThrowManagementComponent:StartCatch Getting nil Session!!!")
    return
  end
  self.CachingSessions[Session.SeqID] = Session
  if Session.is_local then
    self.LocalCachingSessions[Session.SeqID] = Session
  end
  if self:IsCatching() then
    NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchStart)
  end
end

function ThrowManagementComponent:EndCatch(Session)
  if not Session or not Session.SeqID then
    Log.Error("ThrowManagementComponent:EndCatch Getting nil Session!!!")
    return
  end
  self.CachingSessions[Session.SeqID] = nil
  if Session.is_local then
    self.LocalCachingSessions[Session.SeqID] = nil
    if Session.bCatchSuccess then
    end
  end
  if not self:IsCatching() then
    NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEnd)
  else
    NRCEventCenter:DispatchEvent(NPCModuleEvent.StillCatching)
  end
  NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEndWithoutCondition)
end

function ThrowManagementComponent:IsCatching()
  local Key, Value = next(self.CachingSessions)
  return nil ~= Key and nil ~= Value
end

function ThrowManagementComponent:IsCatchSession(Session)
  local SeqId = Session and Session.SeqID
  if not SeqId then
    return false
  end
  if self.CachingSessions[SeqId] then
    return true
  end
  return false
end

return ThrowManagementComponent
