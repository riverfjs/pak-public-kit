local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = require("NewRoco.Modules.Core.NPC.ThrowSessionBase")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local ShowTrajectory = false
local ColorMap = {
  [ThrowSessionStatusEnum.InHand] = UE4.FLinearColor(1, 1, 0, 1),
  [ThrowSessionStatusEnum.InAir] = UE4.FLinearColor(0, 1, 0, 1),
  [ThrowSessionStatusEnum.Recycling] = UE4.FLinearColor(0, 0, 1, 1),
  [ThrowSessionStatusEnum.PreReleasing] = UE4.FLinearColor(1, 0.5, 0, 1),
  [ThrowSessionStatusEnum.Releasing] = UE4.FLinearColor(1, 0.5, 0, 1)
}
local ThrowSession = Base:Extend("ThrowSession")
ThrowSession:SetMemberCount(20)
local PetStatus = ProtoEnum.WorldPlayerPetStatusType
ThrowSession.CurrentID = 0
ThrowSession.ActivePetSessions = {}
ThrowSession.DebugHits = false
ThrowSession.StatusMap = {
  [ThrowSessionStatusEnum.InHand] = PetStatus.WPPST_IN_SCENE,
  [ThrowSessionStatusEnum.InAir] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.PreReleasing] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.Releasing] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.Interacting] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.CriticalInteracting] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.PostInteract] = PetStatus.WPPST_IN_SCENE,
  [ThrowSessionStatusEnum.Recycling] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.Destroyed] = PetStatus.WPPST_IN_BAG,
  [ThrowSessionStatusEnum.WaitBeginDrop] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.WaitEnter] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.Abandon] = PetStatus.WPPST_IN_BAG,
  [ThrowSessionStatusEnum.WaitForRecycle] = PetStatus.WPPST_IN_INTERACT,
  [ThrowSessionStatusEnum.FriendRiding] = PetStatus.WPPST_IN_FRIENDRIDING
}
ThrowSession.CanRecycleStatus = {
  ThrowSessionStatusEnum.PostInteract,
  ThrowSessionStatusEnum.Interacting,
  ThrowSessionStatusEnum.InAir,
  ThrowSessionStatusEnum.Releasing,
  ThrowSessionStatusEnum.PreReleasing,
  ThrowSessionStatusEnum.FriendRiding
}
ThrowSession.DestroyBallStatus = {
  ThrowSessionStatusEnum.CriticalInteracting,
  ThrowSessionStatusEnum.PostInteract,
  ThrowSessionStatusEnum.WaitForRecycle,
  ThrowSessionStatusEnum.Abandon
}
ThrowSession.DestroyPetStatus = {
  ThrowSessionStatusEnum.InHand,
  ThrowSessionStatusEnum.InAir,
  ThrowSessionStatusEnum.WaitBeginDrop,
  ThrowSessionStatusEnum.WaitEnter,
  ThrowSessionStatusEnum.WaitForRecycle,
  ThrowSessionStatusEnum.Abandon
}
ThrowSession.DyingStatus = {
  ThrowSessionStatusEnum.Recycling,
  ThrowSessionStatusEnum.Destroyed
}

function ThrowSession:Ctor()
  Base.Ctor(self)
  self.bThrowFailed = false
  self.bHasPendingCollisionReq = false
  self.bIsBroken = false
  self:SetIsValid(true)
  self.Ball = nil
  self.NPC = nil
  self.petData = nil
  self.itemData = nil
  self.InAirPosition = nil
  self.CatchPetBaseID = 0
  self.BeginDrop = nil
  self.Status = ThrowSessionStatusEnum.InHand
  self.BallStatus = ThrowSessionStatusEnum.InHand
  self.PrevPos = nil
  self.bHasPendingRelease = false
  self.shouldForceRecycle = false
  self.beginThrowFinished = false
  self.petSyncFinished = false
  self.endThrowFinished = false
  self.bIsLocal = true
  self.is_local = false
  self.owner_id = nil
  self.JumpSkill = nil
  self.hasSyncPet = false
  if ShowTrajectory then
    _G.UpdateManager:Register(self)
  end
  self.canBeRecycle = nil
  self.BallId = 0
  self.hasSentRecycle = false
  self.isCatchFinished = false
end

function ThrowSession:SetBallStatus(Status)
  if nil == Status then
    return
  end
  self.BallStatus = Status
end

function ThrowSession:SetStatus(Status)
  if nil == Status then
    Log.Error("Status shouldn't be nil")
    return
  end
  if self.Status == Status then
    return
  end
  if self.Status == ThrowSessionStatusEnum.Destroyed and Status < ThrowSessionStatusEnum.Destroyed then
    Log.Error("\230\138\149\230\142\183\231\138\182\230\128\129\229\143\145\231\148\159\228\186\134\229\128\146\233\128\128", self.SeqID, table.getKeyName(ThrowSessionStatusEnum, self.Status), table.getKeyName(ThrowSessionStatusEnum, Status))
    return
  end
  if self.Status == ThrowSessionStatusEnum.Recycling and Status < ThrowSessionStatusEnum.Recycling then
    Log.Error("\230\138\149\230\142\183\231\138\182\230\128\129\229\143\145\231\148\159\228\186\134\229\128\146\233\128\128", self.SeqID, table.getKeyName(ThrowSessionStatusEnum, self.Status), table.getKeyName(ThrowSessionStatusEnum, Status))
    return
  end
  if self.Status == ThrowSessionStatusEnum.CriticalInteracting and Status < ThrowSessionStatusEnum.CriticalInteracting then
    Log.Debug("\230\138\149\230\142\183\231\138\182\230\128\129\229\143\145\231\148\159\228\186\134\229\128\146\233\128\128", self.SeqID, table.getKeyName(ThrowSessionStatusEnum, self.Status), table.getKeyName(ThrowSessionStatusEnum, Status))
    return
  end
  if self.ScenePet then
    self.ScenePet:SetStatus(ThrowSession.StatusMap[Status] or PetStatus.WPPST_IN_SCENE)
  end
  if self.Status == ThrowSessionStatusEnum.PostInteract and Status == ThrowSessionStatusEnum.WaitEnter then
    return
  end
  local LogFunc = Log.Debug
  if ShowTrajectory then
    LogFunc = Log.Error
  end
  LogFunc(self, "\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151 Throw Session Status Change", self.SeqID, table.getKeyName(ThrowSessionStatusEnum, self.Status), table.getKeyName(ThrowSessionStatusEnum, Status))
  if ShowTrajectory and self.Status == ThrowSessionStatusEnum.InAir and Status ~= ThrowSessionStatusEnum.InAir then
    Log.Error(self.SeqID, "\233\163\158\232\161\140\232\183\157\231\166\187", math.sqrt(self:GetFlyDistance()))
  end
  local Old = self.Status
  self.Status = Status
  self:SendEvent(ThrowSessionEvent.OnStatusChanged, self, self.Status, Old)
  if self.Status == ThrowSessionStatusEnum.Destroyed then
    self:OnSessionDestroyed()
  end
  if Old == ThrowSessionStatusEnum.CriticalInteracting and self.NPC and self.NPC.AIComponent then
    self.NPC.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
  end
  if self.Status == ThrowSessionStatusEnum.CriticalInteracting and self.NPC and self.NPC.AIComponent then
    self.NPC.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.INTERACT)
  end
  if self.Status == ThrowSessionStatusEnum.PostInteract then
    if self.shouldForceRecycle then
      self:Recycle()
    elseif self.NPC and self.NPC.AIComponent then
      self.NPC.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
    end
  end
  if self.NPC and table.contains(ThrowSession.DestroyPetStatus, self.Status) then
    self.NPC:Destroy()
    self.NPC = nil
    Log.Error("Force Cleanup NPC", self.SeqID)
  end
  if self.Ball and table.contains(ThrowSession.DestroyBallStatus, self.Status) then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self.Ball)
    self.Ball = nil
    Log.Error("Force Cleanup Ball", self.SeqID)
  end
end

function ThrowSession:SetIsValid(valid)
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: SetIsValid", valid)
  self.isValid = valid
end

function ThrowSession:OnSessionDestroyed()
  local Found
  for Index, Session in ipairs(ThrowSession.ActivePetSessions) do
    if Session == self then
      Found = Index
      break
    end
  end
  if Found then
    Log.Debug("Removing session from active session list", self.Status, self.SeqID, self.petData and self.petData.gid)
    table.remove(ThrowSession.ActivePetSessions, Found)
  else
    Log.Debug("Session\232\162\171\229\136\160\228\186\134\228\189\134\230\152\175\228\184\141\229\173\152\229\156\168\229\156\168ActivePetSessions\233\135\140\233\157\162", self.Status, self.SeqID, self.petData and self.petData.gid)
  end
  if self.is_local then
    local player = SceneUtils.GetPlayer()
    local throwManagementComponent = player and player.ThrowManagementComponent
    local isCatching = throwManagementComponent and throwManagementComponent:IsCatchSession(self) or false
    if isCatching then
      Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \232\167\166\229\143\145\228\186\134\230\156\128\228\191\157\229\186\149\231\154\132\228\191\157\230\138\164\230\142\170\230\150\189\239\188\140\230\156\137\228\186\155\230\158\129\231\171\175\230\131\133\229\134\181\228\188\154\229\175\188\232\135\180\230\141\149\230\141\137\232\161\168\230\188\148\230\178\161\229\138\158\230\179\149\230\173\163\229\184\184\232\191\155\232\161\140\239\188\140\230\173\164\230\151\182\232\135\179\229\176\145\232\166\129\229\156\168\233\148\128\230\175\129\231\154\132\230\151\182\229\128\153\230\184\133\231\144\134\228\184\128\228\184\139\239\188\140\228\184\141\232\131\189\232\174\169\230\141\149\230\141\137\231\138\182\230\128\129\230\174\139\231\149\153", self.SeqID)
      throwManagementComponent:EndCatch(self)
    end
  end
end

function ThrowSession:IsInHand()
  return self.Status == ThrowSessionStatusEnum.InHand
end

function ThrowSession.CheckSessionActive(throwSession)
  local Found
  for Index, Session in ipairs(ThrowSession.ActivePetSessions) do
    if Session == throwSession and Session.Status ~= ThrowSessionStatusEnum.Recycling then
      Found = Index
      break
    end
  end
  return Found
end

function ThrowSession:SetHasSyncPet(hasPet)
  self.hasSyncPet = hasPet
end

function ThrowSession:HasPet(includeSyncPet)
  if includeSyncPet and self.hasSyncPet then
    return true
  end
  return self.petData ~= nil
end

function ThrowSession:GetPetName()
  return self.petData.name
end

function ThrowSession:GetGID()
  if self:HasPet() then
    return self.petData.gid
  elseif self:HasItem() then
    return self.itemData.gid
  else
    Log.Error("Invalid Throw Session")
    return 0
  end
end

function ThrowSession:GetItemID()
  if self:HasPet() then
    return 0
  elseif self:HasItem() then
    return self.itemData.id
  else
    Log.Error("Invalid Throw Session")
    return 0
  end
end

function ThrowSession:GetThrowID()
  return self.SeqID
end

function ThrowSession:GetNpcID(default)
  if self.petData then
    local BaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
    if BaseConf and BaseConf.npc_id > 0 then
      return BaseConf.npc_id
    else
      Log.Error("\228\184\165\233\135\141\233\148\153\232\175\175!\230\138\149\230\142\183\231\178\190\231\129\181\230\151\182\230\151\160\230\179\149\232\142\183\229\143\150PETBASE_CONF!!!", self.petData.base_conf_id, BaseConf and BaseConf.npc_id or "\230\151\160\230\179\149\232\142\183\229\143\150PETBASE_CONF")
    end
  else
    Log.Error("\228\184\165\233\135\141\233\148\153\232\175\175!\230\138\149\230\142\183\231\178\190\231\129\181\230\151\182\229\174\140\229\133\168\230\178\161\230\156\137PetData!!!!!")
  end
  return default or 0
end

function ThrowSession:GetPetEcology()
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if not BaseConf then
    return Enum.ECOLOGY_FEATURE.ECO_LAND
  end
  local Features = BaseConf.ecology_feature
  if not Features then
    return Enum.ECOLOGY_FEATURE.ECO_LAND
  end
  if 0 == #Features then
    return Enum.ECOLOGY_FEATURE.ECO_LAND
  end
  for _, Feature in ipairs(Features) do
    if Feature == Enum.ECOLOGY_FEATURE.ECO_FLY then
      return Feature
    end
    if Feature == Enum.ECOLOGY_FEATURE.ECO_ICE_ELEMENT then
      return Feature
    end
    if Feature == Enum.ECOLOGY_FEATURE.ECO_WATER then
      return Feature
    end
    if Feature == Enum.ECOLOGY_FEATURE.ECO_AQUA then
      return Feature
    end
  end
  return Enum.ECOLOGY_FEATURE.ECO_LAND
end

function ThrowSession:GetPetType()
  if self.petData == nil then
    return {}
  end
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if BaseConf then
    return BaseConf.unit_type
  else
    return {}
  end
end

function ThrowSession:GetPetHabitat()
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if not BaseConf then
    return Enum.HABITAT_FLAG.HAB_LAND
  end
  local NpcConf = _G.DataConfigManager:GetNpcConf(BaseConf.npc_id)
  if not NpcConf then
    return Enum.HABITAT_FLAG.HAB_LAND
  end
  local ModelConf = _G.DataConfigManager:GetModelConf(NpcConf.model_conf)
  if ModelConf then
    return ModelConf.habitat_flag or Enum.HABITAT_FLAG.HAB_LAND
  end
  return Enum.HABITAT_FLAG.HAB_LAND
end

function ThrowSession:HasItem()
  return self.itemData ~= nil
end

function ThrowSession:ForceRecycle(Reason)
  self.shouldForceRecycle = true
  self:Recycle(Reason)
end

function ThrowSession:Recycle(Reason)
  Log.DebugFormat("[ThrowSession:Recycle] Status: %s    bSentCreatePetReq:%s    bPetSyncFinished:%s", table.getKeyName(ThrowSessionStatusEnum, self.Status), self.bSentCreatePetReq, self.petSyncFinished)
  if self.Status == ThrowSessionStatusEnum.CriticalInteracting then
    return
  end
  if not table.contains(ThrowSession.CanRecycleStatus, self.Status) then
    return
  end
  if self.bSentCreatePetReq and not self.petSyncFinished then
    Log.Debug("\229\136\171\230\128\165\239\188\140\232\189\172\230\173\163\228\184\173...")
    return
  end
  local petGid = self:GetGID()
  if petGid and _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.CheckPetIsFriendRiding, petGid) then
    self:SendRecycleFriendRidePetReq()
  else
    self:SendRecycleReq(Reason)
  end
  if self.NPC and self.NPC.viewObj and self.JumpSkill then
    self.NPC.viewObj.RocoSkill:CancelSkill(self.JumpSkill, UE.ESkillActionResult.SkillActionResultInterrupted)
  end
  local View = self.NPC and self.NPC.viewObj
  if View then
    View:FlyBackToPlayer()
  elseif self.NPC then
    Log.Error("\232\162\171\229\155\158\230\148\182\231\154\132\229\175\185\232\177\161\228\184\141\229\173\152\229\156\168", self.NPC:DebugNPCNameAndID())
  else
    Log.Error("\232\162\171\229\155\158\230\148\182\231\154\132\229\175\185\232\177\161\228\184\141\229\173\152\229\156\168")
    return
  end
  if self.NPC then
    self.NPC.shouldDestroy = true
    self.NPC:SetNotDestroyFlag(true)
  end
  if self.NPC then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.UnRegisterNPCFromModule, self.NPC.serverData.base.actor_id)
  end
  self:ForceSetCanBeRecycle(true)
end

function ThrowSession:RecycleDirect(Reason)
  Log.Debug("ThrowSession:RecycleDirect", table.getKeyName(ThrowSessionStatusEnum, self.Status), self.NPC)
  self:SendRecycleReq(Reason)
  self:SetStatus(ThrowSessionStatusEnum.Destroyed)
  if self.NPC then
    self.NPC:SetNotDestroyFlag(false)
    self.NPC:Disappear()
    self.NPC = nil
  end
end

function ThrowSession:RecycleFromAbility()
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: ThrowSession:RecycleFromAbility", self.SeqID, table.getKeyName(ThrowSessionStatusEnum, self.Status), self.NPC, "|||", self.Ball)
  if self.NPC and self.Status ~= ThrowSessionStatusEnum.PreReleasing then
    self:Recycle()
  elseif self.Ball then
    self:RecycleBall()
  else
    Log.Error(self:ToString())
    self:SetStatus(ThrowSessionStatusEnum.Destroyed)
  end
end

function ThrowSession:ClearPet()
  if self.NPC then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPet, self.NPC)
    self.NPC = nil
    self:SendRecycleReq(ProtoEnum.RecycleThrowPetReason.RTPR_NONE)
  end
end

function ThrowSession:GetBallView()
  local BallView = self.Ball and self.Ball.viewObj
  return BallView
end

function ThrowSession:RecycleBall()
  local BallView = self:GetBallView()
  if BallView then
    BallView:SetActorScale3D(_G.FVectorOne)
    BallView:ThrowRecycle()
  end
end

function ThrowSession:ClearBall()
  local Ball = self.Ball
  if not Ball then
    return
  end
  Ball:SetNotDestroyFlag(false)
  local BallView = Ball and Ball.viewObj
  if BallView then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, BallView, false)
  end
end

function ThrowSession:SendRecycleReq(Reason)
  Log.Trace("ThrowSession:SendRecycleReq", Reason, self.hasSentRecycle)
  if self.hasSentRecycle then
    return
  end
  self.hasSentRecycle = true
  local Req = ProtoMessage:newZoneSceneRecycleThrowPetReq()
  Req.gid = self:GetGID()
  Req.reason = Reason or ProtoEnum.RecycleThrowPetReason.RTPR_None
  _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RECYCLE_THROW_PET_REQ, Req, false)
end

function ThrowSession:SendRecycleFriendRidePetReq()
  Log.Trace("ThrowSession:SendRecycleFriendRidePetReq", self.hasSentRecycle)
  if self.hasSentRecycle then
    return
  end
  self.hasSentRecycle = true
  local Req = ProtoMessage:newZoneSceneRecycleFriendRidePetReq()
  local PetGID = self:GetGID()
  local FriendRideInfo = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GetFriendRideInfoByPetGID, PetGID)
  if FriendRideInfo and FriendRideInfo.IsFriendRiding then
    Req.friend_uin = FriendRideInfo.FriendUin
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RECYCLE_FRIEND_RIDE_PET_REQ, Req, self, self.OnRecycleFriendRidePetRsp, false, false)
end

function ThrowSession:OnRecycleFriendRidePetRsp(Rsp)
end

function ThrowSession:NotifyCreatePet(Owner, Callback)
  if self.endThrowSendDone then
    return
  end
  self.endThrowSendDone = true
  local req = ProtoMessage:newZoneSceneEndThrowReq()
  req.gid = self:GetGID()
  req.throw_id = self:GetThrowID()
  req.throw_type = ProtoEnum.ThrowType.THROW_PET
  req.throw_effect = ProtoEnum.ThrowEffect.CREATE
  req.item_conf_id = self:GetItemID()
  local Point = self.NPC and self.NPC:GetServerPoint()
  if Point then
    req.end_throw_pos = Point.pos
  end
  self.CreateCallback = Callback
  self.CreateCaller = Owner
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, self, self.OnCreatePetRsp, false, false)
end

function ThrowSession:OnCreatePetRsp(rsp)
  local CreateCallback = self.CreateCallback
  local CreateCaller = self.CreateCaller
  self.CreateCallback = nil
  self.CreateCaller = nil
  if CreateCallback then
    CreateCallback(CreateCaller, rsp, self)
  end
end

function ThrowSession:OnCreatePetFailed()
  Log.Trace("ThrowSession:OnCreatePetFailed")
  local Req = ProtoMessage:newZoneSceneRecycleThrowPetReq()
  Req.gid = self:GetGID()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RECYCLE_THROW_PET_REQ, Req, self, self.OnServerRecycle, false, false)
  self:SetStatus(ThrowSessionStatusEnum.Destroyed)
end

function ThrowSession:SetBall(ballNpc)
  self.Ball = ballNpc
end

function ThrowSession:SetNPC(npc)
  self.NPC = npc
  self.NPC:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNPCLeave)
  self.NPC:AddEventListener(self, NPCModuleEvent.ON_NPC_FRIENDRIDE_END, self.OnNPCFriendRideEnd)
end

function ThrowSession:OnNPCLeave(npc)
  if not self.Ball and self.Status ~= ThrowSessionStatusEnum.Recycling then
    local IsFriendRiding = false
    if self.petData and self.petData.gid and npc and npc.serverData and npc.serverData.base and npc.serverData.base.actor_id and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetPetIsDieForFriendRide, npc.serverData.base.actor_id) then
      IsFriendRiding = true
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SetDiePetForFriendRideMap, npc.serverData.base.actor_id, nil)
    end
    if IsFriendRiding then
      self:SetStatus(ThrowSessionStatusEnum.FriendRiding)
    else
      self:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
  end
  npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnNPCLeave)
end

function ThrowSession:OnNPCFriendRideEnd(npc)
  if not self.Ball and self.Status ~= ThrowSessionStatusEnum.Recycling and self.petData and self.petData.gid and not _G.NRCModuleManager:DoCmd(PlayerModuleCmd.CheckPetIsFriendRiding, self.petData.gid) then
    self:SetStatus(ThrowSessionStatusEnum.Destroyed)
  end
end

function ThrowSession:SetPetData(petData)
  self.petData = petData
  self.ScenePet = _G.DataModelMgr.PlayerDataModel:GetPetByGid(petData.gid)
  if self.ScenePet then
    self.ScenePet:SetStatus(ThrowSession.StatusMap[self.Status] or PetStatus.WPPST_IN_SCENE)
  end
end

function ThrowSession:OnBeginThrow()
  self.beginThrowFinished = false
  local req = ProtoMessage:newZoneSceneBeginThrowReq()
  req.gid = self:GetGID()
  req.throw_id = self:GetThrowID()
  req.throw_type = self:GetThrowType()
  req.item_conf_id = self:GetItemID()
  if req.throw_type == _G.ProtoEnum.ThrowType.THROW_PET then
    local isMainTeamIndex, teamIndex = _G.DataModelMgr.PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(req.gid)
    if not isMainTeamIndex then
      local change_team = ProtoMessage:newQuickChangeMainTeamInfo()
      change_team.main_team_idx = teamIndex
      change_team.team_type = Enum.PlayerTeamType.PTT_BIG_WORLD
      req.change_team = change_team
    end
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEGIN_THROW_REQ, req, self, self.OnBeginTrowRsp, false, true)
end

function ThrowSession:OnBeginTrowRsp(rsp)
  self.beginThrowFinished = true
  self:SendEvent(ThrowSessionEvent.OnBeginThrowFinished, 0 == rsp.ret_info.ret_code)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.UI_BeginThrowChangeTeam, self, rsp)
  if 0 == rsp.ret_info.ret_code then
    return
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_INVALID_THROW_GID then
    if self:HasItem() then
      local CurrentBagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self:GetGID())
      local CurrentCount = CurrentBagItemInfo and CurrentBagItemInfo.num or 0
      if CurrentCount <= 1 then
        Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151 \229\188\128\229\167\139\230\138\149\230\142\183\230\138\165\233\148\153\239\188\140\229\183\178\231\159\165\233\148\153\232\175\175\231\160\129\239\188\140\231\142\169\229\174\182\230\178\161\230\156\137\231\144\131\228\186\134", self.SeqID, self:GetGID())
      else
        Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151 \229\188\128\229\167\139\230\138\149\230\142\183\230\138\165\233\148\153, \229\144\142\229\143\176\232\174\164\228\184\186\231\142\169\229\174\182\230\178\161\231\144\131\228\186\134\239\188\140\228\189\134\230\152\175\229\174\162\230\136\183\231\171\175\232\167\137\229\190\151\232\191\152\230\156\137", self.SeqID, self:GetGID(), CurrentCount)
      end
    else
      Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151 \229\188\128\229\167\139\230\138\149\230\142\183\230\138\165\233\148\153, \229\144\142\229\143\176\232\174\164\228\184\186\231\142\169\229\174\182\231\178\190\231\129\181\230\178\161\228\186\134\239\188\1292083", self.SeqID, self:GetGID())
    end
  else
    Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151 \229\188\128\229\167\139\230\138\149\230\142\183\230\138\165\233\148\153", _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code), self.SeqID, self:GetGID())
  end
  self.bThrowFailed = true
  self:SetIsValid(false)
  self:RecycleAllRes()
end

function ThrowSession:SetInAir()
  self:SetStatus(ThrowSessionStatusEnum.InAir)
  if self.Ball then
    self.InAirPosition = self.Ball:GetActorLocation()
  end
  if self.Ball and self.Ball.viewObj then
    _G.NRCAudioManager:PlaySound3DWithActor(1122, self.Ball.viewObj, "ThrowSession:SetInAir")
    _G.NRCAudioManager:PlaySound3DWithActor(1123, self.Ball.viewObj, "ThrowSession:SetInAir")
  end
  self:OnBeginThrow()
end

function ThrowSession:SendEndThrowReq(Owner, Callback, Location, MovingDistance)
  if self.endThrowSendDone then
    return
  end
  self.endThrowSendDone = true
  local req = ProtoMessage:newZoneSceneEndThrowReq()
  req.gid = self:GetGID()
  req.throw_id = self:GetThrowID()
  req.throw_type = ProtoEnum.ThrowType.THROW_BAGITEM
  req.throw_effect = ProtoEnum.ThrowEffect.TE_NONE
  req.end_throw_pos = SceneUtils.ClientPos2ServerPos(Location)
  req.throw_create_info.create_pt.pos = SceneUtils.ClientPos2ServerPos(Location)
  req.fly_distance = math.round(MovingDistance)
  req.item_conf_id = self:GetItemID()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, Owner, Callback, false, true)
end

function ThrowSession:SendFailEndThrowReq()
  if self.bThrowFailed then
    self:RecycleAllRes()
  else
    if self.endThrowSendDone then
      return
    end
    if not self.is_local then
      return
    end
    self.endThrowSendDone = true
    local req = _G.ProtoMessage:newZoneSceneEndThrowReq()
    req.throw_id = self:GetThrowID()
    req.gid = self:GetGID()
    req.throw_type = self:GetThrowType()
    req.item_conf_id = self:GetItemID()
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req)
  end
  if self.Ball and self.Ball.viewObj then
    self.Ball.viewObj:ThrowRecycle()
  end
end

function ThrowSession:RecycleAllRes()
  self:RecycleBall()
  self:ClearPet()
end

function ThrowSession:SendEmptyBallEndThrowReq()
  if self.endThrowSendDone then
    return
  end
  self.endThrowSendDone = true
  local req = _G.ProtoMessage:newZoneSceneEndThrowReq()
  req.throw_id = self:GetThrowID()
  req.gid = self:GetGID()
  req.item_conf_id = self:GetItemID()
  req.throw_type = _G.ProtoEnum.ThrowType.THROW_BAGITEM
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req)
end

function ThrowSession:GetFlyDistance()
  local Start = self.InAirPosition
  local End = self.Ball and self.Ball:GetActorLocation()
  if not Start or not End then
    Log.Error("no start or end")
    return -1
  end
  local Dist = UE4.FVector.DistSquared(Start, End)
  return Dist
end

function ThrowSession:OnHit()
  if not self:HasItem() then
    return
  end
  if not self.Ball then
    return
  end
  return
end

function ThrowSession:OnCollisionRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("ZoneSceneThrowCollisionRsp ret_code", rsp.ret_info.ret_code)
    return
  end
  self.bHasPendingCollisionReq = false
  if ThrowSession.DebugHits then
    Log.Error(self.SeqID, "\229\143\145\231\148\159\231\162\176\230\146\158", rsp.is_broken and "\231\160\180\231\162\142" or "\228\184\141\231\160\180\231\162\142")
  end
  if not rsp.is_broken then
    return
  end
  self:SetIsValid(false)
  local BallView = self.Ball and self.Ball.viewObj
  if BallView then
    BallView:BreakItself()
  end
  self.bIsBroken = rsp.is_broken
  self:SendEmptyBallEndThrowReq()
end

function ThrowSession:IsInAir()
  return self.Status == ThrowSessionStatusEnum.InAir
end

function ThrowSession:IsRecycling()
  return self.Status == ThrowSessionStatusEnum.Recycling
end

function ThrowSession:IsBallRecycling()
  return self.BallStatus == ThrowSessionStatusEnum.Recycling
end

function ThrowSession:IsPostInteract()
  return self.Status == ThrowSessionStatusEnum.PostInteract
end

function ThrowSession:IsDestroyed()
  return self.Status == ThrowSessionStatusEnum.Destroyed
end

function ThrowSession:IsCatching()
  return self.Status == ThrowSessionStatusEnum.Catching
end

function ThrowSession:SetRecycling()
  self:SetStatus(ThrowSessionStatusEnum.Recycling)
end

function ThrowSession:SetBallRecycling()
  self:SetBallStatus(ThrowSessionStatusEnum.Recycling)
end

function ThrowSession:SetWaitBeginDrop()
  self:SetStatus(ThrowSessionStatusEnum.WaitEnter)
end

function ThrowSession:SetDestroyed()
  self:SetStatus(ThrowSessionStatusEnum.Destroyed)
end

function ThrowSession:OnTick(DeltaTime)
  if not ShowTrajectory then
    _G.UpdateManager:UnRegister(self)
    return
  end
  if self.Status == ThrowSessionStatusEnum.Destroyed then
    _G.UpdateManager:UnRegister(self)
    return
  end
  if not self.PrevPos and self.Ball and not self.Ball.isDestroy and self.Ball.viewObj then
    self.PrevPos = self.Ball:GetActorLocation()
  end
  if not self.PrevPos then
    return
  end
  if self.Status == ThrowSessionStatusEnum.Interacting then
    return
  end
  if self.Status == ThrowSessionStatusEnum.PostInteract then
    return
  end
  local CurrentPos
  if self.Ball and not self.Ball.isDestroy and self.Ball.viewObj then
    CurrentPos = self.Ball:GetActorLocation()
  end
  if self.NPC and not self.NPC.isDestroy and self.NPC.viewObj then
    CurrentPos = self.NPC:GetActorLocation()
  end
  if not CurrentPos then
    return
  end
  if UE.FVector.Dist(CurrentPos, self.PrevPos) > 10000.0 then
    return
  end
  local Color = ColorMap[self.Status] or UE4.FLinearColor(1, 1, 1, 1)
  UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.PrevPos, CurrentPos, Color, 30, 2)
  self.PrevPos = CurrentPos
  if self:IsInAir() then
    local Projectile = self.Ball.viewObj.ProjectileMovement
    Log.Error(self.SeqID, Projectile.bIsSliding, Projectile.Velocity:Size())
  end
end

function ThrowSession.ToggleShowTrajectory(Value)
  ShowTrajectory = Value
end

function ThrowSession.CreatePet(petData)
  for Index, Old in ipairs(ThrowSession.ActivePetSessions) do
    if Old.petData.gid == petData.gid then
      Log.Warning("\229\174\160\231\137\169GID\233\135\141\229\164\141\229\149\166", petData.gid)
      return Old
    end
  end
  local Session = ThrowSession()
  Session:SetPetData(petData)
  Session.Status = ThrowSessionStatusEnum.None
  Session:SetStatus(ThrowSessionStatusEnum.InHand)
  Log.Debug("Add session to active session list", Session.Status, Session.SeqID, Session.petData and Session.petData.gid)
  table.insert(ThrowSession.ActivePetSessions, Session)
  return Session
end

function ThrowSession.CreateItem(itemData)
  local Session = ThrowSession()
  Session.itemData = itemData
  return Session
end

function ThrowSession:SetBallId(BallId)
  self.BallId = BallId
end

function ThrowSession:GetBallId()
  return self.BallId
end

function ThrowSession.GetWithGID(GID)
  if not GID or 0 == GID then
    return nil
  end
  for _, Session in ipairs(ThrowSession.ActivePetSessions) do
    if Session.petData and GID == Session.petData.gid then
      return Session
    end
  end
  return nil
end

function ThrowSession.ClearActiveSessions()
  if ThrowSession.ActivePetSessions then
    table.clear(ThrowSession.ActivePetSessions)
  end
end

function ThrowSession:SyncPetCreate(npc, born_reason)
  local req = _G.ProtoMessage:newZoneSceneCreateScenePetReq()
  req.gid = self:GetGID()
  req.throw_id = self:GetThrowID()
  req.create_reason = born_reason
  npc:GetServerPoint(req.create_pt)
  req.create_pt.pos.z = req.create_pt.pos.z - math.round(npc:GetHalfHeight())
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CREATE_SCENE_PET_REQ, req, self, self.OnCreateScenePetRsp)
  self.bSentCreatePetReq = true
end

function ThrowSession:OnCreateScenePetRsp(rsp)
  self.petSyncFinished = true
  if 0 == rsp.ret_info.ret_code then
  else
    self.bThrowFailed = true
    self:SetIsValid(false)
    self:RecycleAllRes()
  end
  self:SendEvent(ThrowSessionEvent.OnSyncPetCreateFinished)
end

function ThrowSession:GetThrowType()
  if self:HasPet() then
    return _G.ProtoEnum.ThrowType.THROW_PET
  elseif self:HasItem() then
    return _G.ProtoEnum.ThrowType.THROW_BAGITEM
  else
    return _G.ProtoEnum.ThrowType.NONE
  end
end

function ThrowSession:ClearInReconnect()
  self:SetStatus(ThrowSessionStatusEnum.Destroyed)
  self.CreateCallback = nil
  self.CreateCaller = nil
end

function ThrowSession:ForceSetCanBeRecycle(canRecycle)
  local isValid = self:IsValidForceSetCanBeRecycleByStatus(canRecycle)
  if not isValid then
    Log.Warning("\232\174\190\231\189\174\230\152\175\229\144\166\229\143\175\229\155\158\230\148\182\231\138\182\230\128\129\230\163\128\230\159\165\229\164\177\232\180\165: ", canRecycle, self.Status)
    return
  end
  self.canBeRecycle = canRecycle
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:SendEvent(PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH)
  end
end

function ThrowSession:IsValidForceSetCanBeRecycleByStatus(canRecycle)
  if not canRecycle and self.Status == ThrowSessionStatusEnum.Recycling then
    return false
  end
  return true
end

function ThrowSession:ToString()
  local NPC = self.NPC and string.format("%u", self.NPC:GetServerId()) or "no npc"
  local Ball = self.Ball and string.format("%u", self.Ball:GetServerId()) or "no ball"
  local Brief = string.format("%d %d %s %s %s", self.SeqID, self:GetGID(), table.getKeyName(ThrowSessionStatusEnum, self.Status), NPC, Ball)
  return Brief
end

function ThrowSession:IsDying()
  return table.contains(ThrowSession.DyingStatus, self.Status)
end

function ThrowSession:GetThrowBallActConf()
  local ballId = self:GetBallId() or 0
  local hasPet = self:HasPet(true) or false
  local ballActConf
  if hasPet then
    local ballConf = _G.DataConfigManager:GetBallConf(ballId, true)
    local ballActId = ballConf and ballConf.solid_ball_act or 0
    ballActConf = _G.DataConfigManager:GetBallAct(ballActId, true)
  else
    ballActConf = _G.DataConfigManager:GetBallAct(ballId, true)
  end
  if not ballActConf then
    Log.Error(string.format("\229\146\149\229\153\156\231\144\131%d\231\154\132\230\137\139\230\132\159\230\178\161\230\156\137\233\133\141\231\189\174\239\188\140\232\175\183\230\137\190chaunychen\229\184\174\229\191\153\231\156\139\231\156\139", ballId))
    ballActConf = _G.DataConfigManager:GetBallAct(280001, true)
  end
  return ballActConf
end

function ThrowSession:SendCatchFinishReq()
  if not self.is_local then
    return
  end
  if self.isCatchFinished then
    Log.Error("\229\176\157\232\175\149\233\135\141\229\164\141\229\143\145\233\128\129CatchFinish", self.SeqID)
    return
  end
  self.isCatchFinished = true
  if not self.SeqID then
    Log.Error("\230\178\161\230\156\137throwId")
    return
  end
  ThrowSession.RawSendCatchFinish(self.SeqID)
  local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
  if PlayerModule then
    _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnWorldPetCatchFinish, self.bCatchSuccess)
  end
end

function ThrowSession.RawSendCatchFinish(throwId)
  if not throwId then
    Log.Error("ThrowSession.RawSendCatchFinish with throwId nil")
    return
  end
  local req = _G.ProtoMessage:newZoneSceneThrowCatchFinishReq()
  req.throw_id = throwId
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_THROW_CATCH_FINISH_REQ, req)
end

return ThrowSession
