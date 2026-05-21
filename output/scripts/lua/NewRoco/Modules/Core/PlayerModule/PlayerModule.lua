local ScenePlayer = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayer")
local SceneLocalPlayer = require("NewRoco.Modules.Core.Scene.Actor.SceneLocalPlayer")
local PlayerModuleNetCenter = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleNetCenter")
local MovementRecorder = require("NewRoco.Modules.Core.Scene.Component.Movement.MovementRecorder")
local AbilityPool = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityPool")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SyncNpcActionComponent = require("NewRoco.Modules.Core.Scene.Component.Sync.SyncNpcActionComponent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local WorldCombatBuffComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatBuffComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local BitMask = require("Utils.BitMask")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local PetResponseComponent = require("NewRoco.Modules.Core.Scene.Component.Show.PetResponseComponent")
local MutualPerformComponent = require("NewRoco.Modules.Core.Scene.Component.AI.MutualPerformComponent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local EnumFriendRideStateChangeType = {
  None = 0,
  ActionNotify = 1,
  Reconnected = 2,
  PetMainTeamChanged = 3
}
local PlayerModule = NRCModuleBase:Extend("PlayerModule")

function PlayerModule:OnConstruct()
  self.MaxUpdatePlayerNumPerFrame = 5
  self.CurrUpdatePlayerIdx = 1
  self._lastTickTime = 0
  self._allPlayers = {}
  self._playerDic = {}
  self._playerWaitToPlayVisitorAppearEffect = {}
  self._playerCacheWhileVisit = {}
  self.playerInfo = nil
  self.IsSceneLoaded = false
  self._bornPos = nil
  self._cachedStatusChanges = {}
  self.abilityPool = AbilityPool()
  self.taskEffectState = {
    None = 0,
    Start = 1,
    Loop = 2,
    End = 3
  }
  self._hideAllPlayer = BitMask()
  self._hideNotVisitPlayer = BitMask()
  self.ridePetEyeViewOffset = {}
  self.rideThrowCameraOffset = {}
end

function PlayerModule:OnDestruct()
end

function PlayerModule:OnActive()
  self.playerModuleNetCenter = PlayerModuleNetCenter(self)
  self.playerModuleData = self:SetData("PlayerModuleData", "NewRoco.Modules.Core.PlayerModule.PlayerModuleData")
  self.playerModuleData:SetInitData(self)
  self:ClearAll()
  self.movementRecorder = MovementRecorder()
  self:RegisterCmd(_G.PlayerModuleCmd.AddSelfPlayer, self.OnAddSelfPlayer)
  self:RegisterCmd(_G.PlayerModuleCmd.GetSelfPlayerInfo, self.OnGetSelfPlayerInfo)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorLookAtAction, self.OnActorLookAtAction)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorEnterAction, self.OnActorEnterAction)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorLeaveAction, self.OnActorLeaveAction)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorMoveAction, self.OnActorMoveAction)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorTeleportAction, self.OnActorTeleportAction)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorUpdateLogicStatus, self.OnActorUpdateLogicStatus)
  self:RegisterCmd(_G.PlayerModuleCmd.AddPlayeHp, self.OnPlayerPetHpChangeNotify)
  self:RegisterCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER, self.GetAllPlayer)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerLevelChange, self.OnPlayerLevelChange)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerAttrChange, self.OnPlayerAttrChange)
  self:RegisterCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.OnGetPlayerByServerID)
  self:RegisterCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.OnGetPlayerByUin)
  self:RegisterCmd(_G.PlayerModuleCmd.SetWaitToPlayVisitorAppearEffect, self.OnSetWaitToPlayVisitorAppearEffect)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerDieBegin, self.OnPlayerBeginDie)
  self:RegisterCmd(_G.PlayerModuleCmd.CreateTestPlayer, self.CreateTestPlayer)
  self:RegisterCmd(_G.PlayerModuleCmd.DebugVisibleZoneInfo, self.PrintVisibleZoneInfo)
  self:RegisterCmd(_G.PlayerModuleCmd.SyncLocalPlayerStatus, self.SyncLocalPlayerStatus)
  self:RegisterCmd(_G.PlayerModuleCmd.MarkSendMoveReq, self.MarkSendMoveReq)
  self:RegisterCmd(_G.PlayerModuleCmd.SyncStatusImmediately, self.SyncStatusImmediately)
  self:RegisterCmd(_G.PlayerModuleCmd.SyncPlayerStatus, self.SyncPlayerStatus)
  self:RegisterCmd(_G.PlayerModuleCmd.ClearCachedStatusChange, self.ClearCachedStatusChange)
  self:RegisterCmd(_G.PlayerModuleCmd.RemoveCachedHandStatusChange, self.RemoveCachedHandStatusChange)
  self:RegisterCmd(_G.PlayerModuleCmd.AuraInfoChange, self.OnAuraInfoChange)
  self:RegisterCmd(_G.PlayerModuleCmd.FieldTagChange, self.OnFieldTagChange)
  self:RegisterCmd(_G.PlayerModuleCmd.BodyTempChange, self.OnBodyTempChange)
  self:RegisterCmd(_G.PlayerModuleCmd.PredictThrow, self.PredictThrow)
  self:RegisterCmd(_G.PlayerModuleCmd.MarkNoCrouch, self.OnMarkNoCrouch)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerEnterBattle, self.PlayerEnterBattle)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerLeftBattle, self.PlayerLeftBattle)
  self:RegisterCmd(_G.PlayerModuleCmd.EnvMask, self.EnvMask)
  self:RegisterCmd(_G.PlayerModuleCmd.ThrownPetInfoChange, self.ThrownPetInfoChange)
  self:RegisterCmd(_G.PlayerModuleCmd.FriendRideStateChange, self.FriendRideStateChange)
  self:RegisterCmd(_G.PlayerModuleCmd.LockTeleport, self.LockTeleport)
  self:RegisterCmd(_G.PlayerModuleCmd.UnLockTeleport, self.UnLockTeleport)
  self:RegisterCmd(_G.PlayerModuleCmd.BindTeleportCallback, self.BindTeleportCallback)
  self:RegisterCmd(_G.PlayerModuleCmd.GetCachedTeleportNotify, self.GetCachedTeleportNotify)
  self:RegisterCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, self.HideLocalPlayer)
  self:RegisterCmd(_G.PlayerModuleCmd.CLOSE_LOCAL_PLAYER_Collision, self.CloseLocalPlayerCollision)
  self:RegisterCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, self.HideOtherPlayer)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerFashionChange, self.PlayerFashionChange)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayerSalonChange, self.PlayerSalonChange)
  self:RegisterCmd(_G.PlayerModuleCmd.AddDistanceFadeMesh, self.AddDistanceFadeMesh)
  self:RegisterCmd(_G.PlayerModuleCmd.RemoveDistanceFadeMesh, self.RemoveDistanceFadeMesh)
  self:RegisterCmd(_G.PlayerModuleCmd.AddDistanceFadeRule, self.AddDistanceFadeRule)
  self:RegisterCmd(_G.PlayerModuleCmd.RemoveDistanceFadeRule, self.RemoveDistanceFadeRule)
  self:RegisterCmd(_G.PlayerModuleCmd.SetFadeSpeed, self.SetFadeSpeed)
  self:RegisterCmd(_G.PlayerModuleCmd.ResetFadeSpeed, self.ResetFadeSpeed)
  self:RegisterCmd(_G.PlayerModuleCmd.PetInfoChange, self.PetInfoChange)
  self:RegisterCmd(_G.PlayerModuleCmd.CheckPetIsFriendRiding, self.CheckPetIsFriendRiding)
  self:RegisterCmd(_G.PlayerModuleCmd.GetFriendRideInfoByPetGID, self.GetFriendRideInfoByPetGID)
  self:RegisterCmd(_G.PlayerModuleCmd.SyncBasicMovement, self.SyncBasicMovement)
  self:RegisterCmd(_G.PlayerModuleCmd.FindVisitorPos, self.FindVisitorPos)
  self:RegisterCmd(_G.PlayerModuleCmd.OnCmdAvatarNameChange, self.OnAvatarNameChange)
  self:RegisterCmd(_G.PlayerModuleCmd.GetPlayerIsAiming, self.OnCmdGetPlayerIsAiming)
  self:RegisterCmd(_G.PlayerModuleCmd.ForceSetPlayerTurnToBoss, self.OnForceSetPlayerTurnToBoss)
  self:RegisterCmd(_G.PlayerModuleCmd.GetPlayerFollowInfo, self.OnCmdGetPlayerFollowInfo)
  self:RegisterCmd(_G.PlayerModuleCmd.TaskStateChangeNty, self.TaskStateChangeNty)
  self:RegisterCmd(_G.PlayerModuleCmd.TravelTogetherSync, self.OnTravelTogetherSync)
  self:RegisterCmd(_G.PlayerModuleCmd.ActorKeepModel, self.ActorKeepModel)
  self:RegisterCmd(_G.PlayerModuleCmd.UnloadAvatar, self.UnLoadOtherPlayerAvatar)
  self:RegisterCmd(_G.PlayerModuleCmd.ReloadAvatar, self.ReLoadOtherPlayerAvatar)
  self:RegisterCmd(_G.PlayerModuleCmd.PlayIdleSkill, self.PlayIdleSkill)
  self:RegisterCmd(_G.PlayerModuleCmd.OnVisibleCircleChanged, self.OnVisibleCircleChanged)
  self:RegisterCmd(_G.PlayerModuleCmd.OnHomeOwnerStoryFlagChange, self.OnHomeOwnerStoryFlagChange)
  self:RegisterCmd(_G.PlayerModuleCmd.OnPetResponseVoice, self.OnPetResponseVoice)
  self:RegisterCmd(_G.PlayerModuleCmd.GetRidePetEyeViewOffset, self.GetRidePetEyeViewOffset)
  self:RegisterCmd(_G.PlayerModuleCmd.OnAbnormalStatusChange, self.OnAbnormalStatusChange)
  self:RegisterCmd(_G.PlayerModuleCmd.HIDE_NOVISIT_PLAYER, self.HideNotVisitPlayer)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PET_HP_CHANGE_NOTIFY, self.OnPlayerPetHpChangeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ADD_ROLE_ENERGY_NOTIFY, self.OnPlayerEnergyAddNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_INTERACT_ACTION_RESULT_NTF, self.OnInteractionActionResultNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_FRIEND_RIDE_NOTIFY, self.OnFriendRideNty)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, _G.NRCGlobalEvent.NetBeforeLockUpstream, self.OnBeforeLockUpstream)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, SceneEvent.LoadMapStart, self.OnSceneLeave)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, SceneEvent.PreLoadMapFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisConnect)
  _G.NRCEventCenter:RegisterEvent("PlayerModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.ON_VITEM_GP_CHANGED, self.OnGPChange)
  self.bStreamNotBlockTeleport = true
  self:InitMagicCropping()
end

function PlayerModule:OnDeactive()
  self:ClearAll()
  self._playerCacheWhileVisit = {}
  if self.playerModuleNetCenter then
    self.playerModuleNetCenter:Destroy()
    self.playerModuleNetCenter = nil
  end
  self:ClearData("PlayerModuleData")
  self.playerModuleData = nil
  self.ridePetEyeViewOffset = {}
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PET_HP_CHANGE_NOTIFY, self.OnPlayerPetHpChangeNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ADD_ROLE_ENERGY_NOTIFY, self.OnPlayerEnergyAddNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.NetBeforeLockUpstream, self.OnBeforeLockUpstream)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnSceneLeave)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisConnect)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.ON_VITEM_GP_CHANGED, self.OnGPChange)
  self:CancelDelayHandle()
end

function PlayerModule:OnDisConnect()
  local localPlayer = self.playerModuleData.localPlayer
  if localPlayer and localPlayer.viewObj and localPlayer.viewObj.CapsuleComponent then
    localPlayer.viewObj.CapsuleComponent:SetGenerateOverlapEvents(false)
  end
end

function PlayerModule:OnReconnect(bLight)
  Log.Debug("PlayerModule:OnReconnect")
  local localPlayer = self.playerModuleData.localPlayer
  if localPlayer then
    localPlayer.viewObj.CapsuleComponent:SetGenerateOverlapEvents(true)
    self:InitTaskState(self._localUin)
  end
  if self.playerModuleData and self.playerModuleData.FriendRidePetMap then
    for friendRidePetGID, _ in pairs(self.playerModuleData.FriendRidePetMap or {}) do
      if friendRidePetGID then
        self:FriendRideSelfPetStateChange(false, nil, friendRidePetGID, nil, EnumFriendRideStateChangeType.Reconnected)
      end
    end
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnForceUpdateFriendRideState)
end

function PlayerModule:OnLogin(isRelogin)
  if isRelogin then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnRelogin)
  end
  Log.Debug("PlayerModule:OnLogin", tostring(isRelogin))
end

function PlayerModule:OnActorTeleportAction(action)
  local teleportPlayer = self._playerDic[action.actor_id]
  if teleportPlayer then
    teleportPlayer:OnPlayerTeleport(action)
  end
  if action.actor_id == self._localUin then
  end
end

function PlayerModule:OnPlayerPetHpChangeNotify(notify)
  local localPlayer = self.playerModuleData.localPlayer
  if not localPlayer then
    return
  end
  Log.Debug("PlayerModule:OnPlayerPetHpChangeNotify")
  local addHpMap = {
    [ProtoEnum.PetHpChangeReason.PHCR_IN_SAFE_ZONE] = true,
    [ProtoEnum.PetHpChangeReason.PHCR_NPC_INTERACT] = true
  }
  if addHpMap[notify.change_reason] and notify.total_change_hp > 0 then
    localPlayer:PlayBloodAddEffect(notify)
  end
end

function PlayerModule:OnPlayerEnergyAddNotify(notify)
  if not notify then
    return
  end
  local localPlayer = self.playerModuleData.localPlayer
  if not localPlayer then
    return
  end
  localPlayer:PlayEnergyAddEffect(notify)
end

function PlayerModule:OnPlayerLevelChange(expData)
  local localPlayer = self.playerModuleData.localPlayer
  if expData.newLevel > expData.oldLevel then
    Log.Debug("PlayerModule:OnPlayerLevelChange", expData.newLevel, expData.oldLevel)
    localPlayer:PlayLevelUpEffect()
  end
end

function PlayerModule:OnPlayerAttrChange(action)
  local id = action.actor_id
  local player = self._playerDic[id]
  if player then
    if action.attrs == nil or 0 == #action.attrs then
      return
    end
    local hasHpChange = false
    local HpChangeTag
    for _, attr in pairs(action.attrs) do
      if attr.attr_type == ProtoEnum.AttrType.ENUM.NatureTemp then
        player.TemperatureComponent:OnReceiveServerData(attr.attr_val)
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.Hp then
        player.serverData.attrs.hp = attr.attr_val
        if id == self._localUin and player.roleHPComponent then
          hasHpChange = true
          HpChangeTag = attr.attr_present_tag
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.HpHalfInjure then
        player.serverData.attrs.half_injure = attr.attr_val
        if id == self._localUin and player.roleHPComponent then
          hasHpChange = true
          HpChangeTag = attr.attr_present_tag
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.HpMax then
        player.serverData.attrs.hp_max = attr.attr_val
        if id == self._localUin and player.roleHPComponent then
          player.roleHPComponent:OnHPMaxChange(false)
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.HpTemporary then
        local PreHP = player.serverData.attrs.hp + (player.serverData.attrs.hp_temporary or 0)
        player.serverData.attrs.hp_temporary = attr.attr_val
        if id == self._localUin and player.roleHPComponent then
          local CurHP = player.serverData.attrs.hp + attr.attr_val
          local bNeedChangeMaxHP = false
          if CurHP > player.serverData.attrs.hp_max then
            bNeedChangeMaxHP = true
          end
          if not bNeedChangeMaxHP and PreHP > player.serverData.attrs.hp_max and CurHP <= player.serverData.attrs.hp_max then
            bNeedChangeMaxHP = true
          end
          player.roleHPComponent:OnDataChange(attr.attr_present_tag)
          if bNeedChangeMaxHP then
            player.roleHPComponent:OnHPMaxChange(true)
          end
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.Stamina then
        player.serverData.attrs.stamina = attr.attr_val
        if id == self._localUin and player.vitalityComponent then
          local curVitality = player.vitalityComponent:GetCurVitality()
          if curVitality then
            Log.DebugFormat("ServerVitality:%.2f,ClientVitality:%.2f", attr.attr_val, curVitality)
            if GlobalConfig.ShowVitalitySyncInfo then
              UE4Helper.PrintScreenMsg(string.format("\230\156\141\229\138\161\229\153\168\228\189\147\229\138\155:%.2f\239\188\140\229\174\162\230\136\183\231\171\175\228\189\147\229\138\155:%.2f", attr.attr_val, curVitality))
            end
          end
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.StaminaMax then
        player.serverData.attrs.stamina_max = attr.attr_val
        if id == self._localUin and player.vitalityComponent then
          Log.DebugFormat("SpaceAct Sync Max Vitality %d", attr.attr_val)
          player.vitalityComponent:SyncVitality(attr.attr_val)
        end
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.BodyTemp and id == self._localUin then
        local TempComp = player.TemperatureComponent
        if TempComp then
          TempComp:SetBodyTempDirect(attr.attr_val)
          TempComp:UpdateBodyTempUI(attr.attr_val)
        end
      end
    end
    if hasHpChange then
      player.roleHPComponent:OnDataChange(HpChangeTag)
    end
  else
    Log.Debug("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:OnAddSelfPlayer(playerInfo)
  self.playerInfo = playerInfo
end

function PlayerModule:OnGetSelfPlayerInfo()
  return self.playerInfo
end

function PlayerModule:OnPlayerBeginDie(action)
  Log.Debug("PlayerModule:OnPlayerBeginDie")
  local id = action.actor_id
  local player = self._playerDic[id]
  if player and player.roleHPComponent then
    player.roleHPComponent:DeathPerform(action)
  end
end

function PlayerModule:OnActorLookAtAction(action)
  local id = action.actor_id
  if id == self._localUin then
    Log.Debug("PlayerModule: Receive self look at data")
    return
  end
  local player = self._playerDic[id]
  if player then
    local HeadLookAtComponent = player:GetHeadLookAtComponent()
    if HeadLookAtComponent then
      HeadLookAtComponent:OnReceiveLookAtData(action)
    end
  else
    Log.Debug("PlayerModule: Can't find player by id ", id)
  end
end

function PlayerModule:OnActorEnterAction(actor)
  Log.Debug("[PlayerAOI]PlayerModule:OnPlayerEnterAction", string.format("%u", actor.avatar.base.actor_id), actor.avatar.base.name)
  SceneUtils.FixActorPoint(actor)
  if _G.NRCModuleManager:GetModule("FriendModule") then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.ActorEnterAction, actor.avatar.base)
  end
  self.playerModuleNetCenter:AddPlayer(actor.avatar)
  if self.IsSceneLoaded then
    self:OnPlayerAppear(actor.avatar)
  end
  if self._playerCacheWhileVisit[actor.avatar.base.actor_id] then
    self._playerCacheWhileVisit[actor.avatar.base.actor_id] = nil
    local player = self._playerDic[actor.avatar.base.actor_id]
    if player then
      player.statusComponent:RecoverAllStatus_KeepModel(actor.avatar)
      player.serverData = actor.avatar
      player.LogicStatusComponent:UpdateData(player.serverData)
      local localPlayer = self.playerModuleData.localPlayer
      if localPlayer and localPlayer.SocialComponent then
        localPlayer.SocialComponent:OnNetPlayerSpawn(player)
      end
    end
  end
end

function PlayerModule:OnActorLeaveAction(id)
  Log.Debug("[PlayerAOI]PlayerModule:OnActorLeaveAction", string.format("%u", id))
  if self._playerCacheWhileVisit[id] then
    local player = self.playerModuleData.localPlayer
    if player and player.SocialComponent then
      local ptherPlayer = self._playerDic[id]
      player.SocialComponent:OnNetPlayerDeSpawn(ptherPlayer)
    end
    Log.Debug(string.format("\231\142\169\229\174\182%u \231\148\177\228\186\142\230\151\160\231\188\157\232\191\155\228\186\146\232\174\191\239\188\140\228\191\157\231\149\153\230\168\161\229\158\139", id))
    return
  end
  self.playerModuleNetCenter:RemovePlayer(id)
  if self.IsSceneLoaded then
    self:OnPlayerDisappear(id)
  end
end

function PlayerModule:ActorKeepModel(action)
  for _, v in pairs(action.keep_model_actor_ids) do
    Log.Debug("[PlayerAOI]PlayerModule:ActorKeepModel", v)
    self._playerCacheWhileVisit[v] = 30
  end
end

function PlayerModule:OnActorMoveAction(action)
  local id = action.actor_id
  if id == self._localUin then
    Log.Debug("PlayerModule: Receive self move data")
    return
  end
  local player = self._playerDic[id]
  if player then
    player.movementComponent:OnReceiveMoveData(action)
  else
    Log.Debug("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:OnActorUpdateLogicStatus(action)
  local ID = action.actor_id
  if ID == self._localUin then
    if self.playerModuleData and self.playerModuleData.localPlayer then
      self.playerModuleData.localPlayer:UpdateLogicStatus(action)
    end
  elseif self._playerDic[ID] then
    local player = self._playerDic[ID]
    if player then
      player:UpdateLogicStatus(action)
    end
  end
  self.playerModuleNetCenter:OnScenePerformNotify(action)
end

function PlayerModule:OnPlayerAppear(value)
  local ID = value.base.actor_id
  if ID == self._localUin then
    local serverPos = value.base.pt.pos
    self._bornPos = SceneUtils.ServerPos2PlayerPos(serverPos)
  elseif self._playerDic[ID] == nil and value.base.pt and not _G.GlobalConfig.DisableNetPlayer then
    local player = ScenePlayer(self)
    player:InitData(nil, value)
    self:AddPlayer(player)
    self._playerDic[ID] = player
    player:SetUin(ID)
    if self._hideAllPlayer:any() then
      local bits = self._hideAllPlayer:bits()
      for _, hideType in pairs(bits) do
        player.viewObj:SetHiddenMask(true, hideType)
      end
    end
    if self._hideNotVisitPlayer:any() then
      local bits = self._hideNotVisitPlayer:bits()
      for _, hideType in pairs(bits) do
        if not _G.DataModelMgr.PlayerDataModel:IsVisitor(player:GetLogicId()) then
          player.viewObj:SetHiddenMask(true, hideType)
        end
      end
    end
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnNetPlayerSpawn, player)
  end
  self:InitTaskState(ID)
  if self._playerWaitToPlayVisitorAppearEffect[value.base.logic_id] then
    self._playerWaitToPlayVisitorAppearEffect[value.base.logic_id] = nil
    local player = self:OnGetPlayerByServerID(ID)
    player:PlayVisitorTeleportEffect()
  end
end

function PlayerModule:OnPlayerDisappear(id)
  if id == self._localUin then
    return
  end
  local player = self._playerDic[id]
  if not player then
    return
  end
  _G.NRCEventCenter:DispatchEvent(SceneEvent.OnNetPlayerDespawn, player)
  self:RemovePlayer(player)
  player:Destroy()
  self._playerDic[id] = nil
end

function PlayerModule:SwitchStreamBlock()
  Log.Error("\230\178\161\231\148\168\239\188\140\229\136\171\231\158\142\231\130\185\228\186\134")
end

function PlayerModule:OnBeforeLockUpstream(bSameMap, bReconnecting)
  self:Log("PlayerModule:OnBeforeLockUpstream", bSameMap, bReconnecting)
  if bSameMap then
    if not bReconnecting then
      self.playerModuleData.localPlayer:StopRide(true)
    end
    self.playerModuleData.localPlayer:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
  end
end

function PlayerModule:OnEnterSceneFinishNtyAck(notify, isReconnecting, isEnteringCell)
  self:Log("PlayerModule:OnEnterSceneFinishNtyAck", isReconnecting, isEnteringCell)
  local player = self.playerModuleData.localPlayer
  if player and player.vitalityComponent then
    player.vitalityComponent:FetchSeverVitality()
  end
end

function PlayerModule:OnEnterSceneFinishNtyAckEnd(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  Log.DebugFormat("PlayerModule:OnEnterSceneFinishNtyAckEnd isReconnecting:%s isEnteringCell:%s", tostring(isReconnecting), tostring(isEnteringCell))
  if isEnteringCell then
    _G.DataModelMgr.PlayerDataModel:OnBriefFriendListReq()
    self:SyncChatOfflineRedPoint()
  elseif isReconnecting then
    self:SyncChatOfflineRedPoint()
  end
end

function PlayerModule:OnSceneLeave(Same, bReconnecting)
  self:Log("PlayerModule:OnSceneLeave", Same, bReconnecting)
  if Same then
  else
    self:ClearAll()
  end
end

function PlayerModule:OnGPChange(preValue, curValue)
  Log.Debug("PlayerModule:OnGPChange", preValue, curValue)
  if self:IsBanEffectPlay() then
    return
  end
  _G.PlayerResourceManager:LoadResources_PlayerPerform(self, UEPath.NS_GradePoint_Player, true, self.OnLoadEffectSuccess, self.OnLoadEffectFailed, nil, 100)
  self.GPDelayID = _G.DelayManager:DelaySeconds(1.5, function()
    _G.PlayerResourceManager:LoadResources_PlayerPerform(self, UEPath.NS_GradePoint1_Player, true, self.OnLoadEffectSuccess, self.OnLoadEffectFailed, nil, 100)
  end)
end

function PlayerModule:CancelDelayHandle()
  if self.GPDelayID then
    _G.DelayManager:CancelDelayById(self.GPDelayID)
    self.GPDelayID = nil
  end
end

function PlayerModule:IsBanEffectPlay()
  return false
end

function PlayerModule:OnLoadEffectSuccess(LoadedObj)
  if not UE.UObject.IsValid(LoadedObj) then
    return
  end
  local PlayerActor = _G.UE4Helper.GetPlayerCharacter(0)
  if not UE.UObject.IsValid(PlayerActor) then
    Log.Error("PlayerModule:OnLoadEffectSuccess Player Actor InValid")
    return false
  end
  local MeshComp = PlayerActor.Mesh
  if not UE.UObject.IsValid(MeshComp) then
    Log.Error("PlayerModule:OnLoadEffectSuccess MeshComp InValid")
    return false
  end
  self:SpawnNiagaraEffectAttached(LoadedObj, MeshComp, "locator_body", UE4.FVector(0, 0, 0), UE4.FRotator(0, 0, 0), UE.EAttachLocation.SnapToTarget, false, true, UE.ENCPoolMethod.ManualRelease, true)
end

function PlayerModule:OnLoadEffectFailed(LoadedObj)
  Log.Error("PlayerModule:OnLoadEffectFailed")
end

function PlayerModule:SpawnNiagaraEffectAttached(Template, AttachToComponent, AttachPointName, Location, Rotation, LocationType, bAutoDestroy, bAutoActivate, PoolingMethod, bPreCullCheck)
  if not UE.UObject.IsValid(Template) or not UE.UObject.IsValid(AttachToComponent) then
    return nil
  end
  local NiagaraComp = UE4.UNiagaraFunctionLibrary.SpawnSystemAttached(Template, AttachToComponent, AttachPointName, Location, Rotation, LocationType or UE.EAttachLocation.SnapToTarget, bAutoDestroy or false, bAutoActivate or false, PoolingMethod or UE.ENCPoolMethod.ManualRelease, bPreCullCheck or true)
  return NiagaraComp
end

function PlayerModule:OnSceneLoaded(isReconnect)
  Log.Debug("PlayerModule:OnSceneLoaded ", self.playerModuleNetCenter._bornPos, self.playerModuleNetCenter._bornRot, isReconnect)
  local playerActor = _G.UE4Helper.GetPlayerCharacter(0)
  if not UE.UObject.IsValid(playerActor) then
    Log.Error("PlayerModule:OnSceneLoaded can't find player actor in world, this is fatal, back to login")
    _G.AppMain.BackToLogin()
    return
  end
  local isLoginIn = not NRCEnv:IsLocalMode()
  self:CreateLocalPlayer(playerActor, self.playerInfo, not isLoginIn)
  self._bornPos = self.playerModuleNetCenter._bornPos
  self._bornRot = self.playerModuleNetCenter._bornRot
  if self._bornPos then
    if self.bStreamNotBlockTeleport then
      self.playerModuleData.localPlayer:OnPlayerBorn(self._bornPos, isReconnect)
      self._bornPos = nil
    end
  elseif self.bStreamNotBlockTeleport then
    self._bornPos = self.playerModuleData.localPlayer:GetActorLocation()
    self.playerModuleData.localPlayer:OnPlayerBorn(self._bornPos)
  end
  if self._bornRot then
    self.playerModuleData.localPlayer:SetActorRotation(self._bornRot)
    local Reason = self.playerModuleNetCenter._bornReason
    if not Reason or Reason ~= ProtoEnum.TeleportReason.ENUM.MINIGAME then
      local ueController = self.playerModuleData.localPlayer:GetUEController()
      if ueController then
        if 0 ~= self._bornRot.Roll then
          Log.Error("\231\153\187\229\189\149\230\151\182\231\142\169\229\174\182\229\173\152\229\156\168Roll\230\151\139\232\189\172\239\188\140\229\188\186\232\161\140\228\191\174\230\173\163\233\149\156\229\164\180")
          self._bornRot.Roll = 0
        end
        ueController:SetControlRotation(self._bornRot)
      end
    end
  else
    local rotation = self.playerModuleData.localPlayer:GetActorRotation()
    rotation.Yaw = rotation.Yaw + 60
    self.playerModuleData.localPlayer:SetActorRotation(rotation)
    if self.playerModuleData.localPlayer.ueController then
      self.playerModuleData.localPlayer.ueController:SetControlRotation(rotation)
    end
  end
  if self.playerModuleNetCenter:GetAllPlayer() then
    for _, Avatar in pairs(self.playerModuleNetCenter:GetAllPlayer()) do
      self:OnPlayerAppear(Avatar)
    end
  end
  NRCEventCenter:DispatchEvent(SceneEvent.PlayerBornFinish)
  self.IsSceneLoaded = true
end

function PlayerModule:FindVisitorPos(pos, otherPlayerToIgnore, canFindWaterSurface, useStartAngle, otherActorToIgnore)
  local player = self.playerModuleData.localPlayer
  if player then
    local BasePos = player.viewObj:Abs_K2_GetActorLocation()
    BasePos.Z = BasePos.Z + 45
    local BaseForward = player.viewObj:GetActorForwardVector()
    local OnLineGlobalConfig = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
    local radiusKey = "online_visitor_bornpoint_location_radius"
    if player.viewObj.BP_RideComponent.RidePet then
      radiusKey = "online_rider_bornpoint_location_radius"
    end
    local radiusList
    for i = 1, #OnLineGlobalConfig do
      if OnLineGlobalConfig[i].key == radiusKey then
        radiusList = OnLineGlobalConfig[i].numList
        break
      end
    end
    if pos then
      BasePos = pos
      BasePos.Z = BasePos.Z + 45
      radiusList[1] = _G.DataConfigManager:GetLegendaryGlobalConfig("teleport_radius_inner").num
      radiusList[2] = _G.DataConfigManager:GetLegendaryGlobalConfig("teleport_radius_outer").num
    end
    local BaseRadius = math.rand(radiusList[1], (radiusList[1] + radiusList[2]) / 2)
    local tryRadiusTime = 3
    local radiusStep = (radiusList[2] - BaseRadius) / tryRadiusTime
    local tryTime = 8
    local SphereRadius = player.viewObj.CapsuleComponent:GetScaledCapsuleRadius()
    local HorizTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_Camera)
    local AirWallTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
    local LandTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
    local WalkableZ = math.cos(math.rad(55))
    local DrawDebugType = UE.EDrawDebugTrace.None
    local ActorToIgnore = {
      player.viewObj,
      player.viewObj.BP_RideComponent.RidePet
    }
    if otherPlayerToIgnore then
      table.insert(ActorToIgnore, otherPlayerToIgnore.viewObj)
      table.insert(ActorToIgnore, otherPlayerToIgnore.viewObj.BP_RideComponent.RidePet)
    end
    if otherActorToIgnore then
      table.insert(ActorToIgnore, otherActorToIgnore.viewObj)
    end
    for r = 0, tryRadiusTime - 1 do
      local radius = BaseRadius + r * radiusStep
      local startAngle = math.rand(0, 360)
      if nil ~= useStartAngle then
        startAngle = useStartAngle
      end
      for i = 0, tryTime - 1 do
        local ForwardRotator = UE.UKismetMathLibrary.Conv_VectorToRotator(BaseForward)
        local traceDir = UE.UKismetMathLibrary.Conv_RotatorToVector(UE.FRotator(0, startAngle + i * 360 / tryTime + ForwardRotator.Yaw, 0))
        local traceEndLocation = BasePos + traceDir * radius
        local HitResult, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, BasePos, traceEndLocation, SphereRadius, HorizTraceChannel, false, ActorToIgnore, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        local AirHitResult, bAirHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, BasePos, traceEndLocation, SphereRadius, AirWallTraceChannel, false, ActorToIgnore, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        if not bHit and not bAirHit then
          HitResult, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, traceEndLocation, traceEndLocation - UE.FVector(0, 0, 400), SphereRadius + 3, LandTraceChannel, false, nil, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
          if bHit and WalkableZ < HitResult.ImpactNormal.Z then
            local resLoation = HitResult.Location
            resLoation.Z = HitResult.ImpactPoint.Z + player.viewObj.CapsuleComponent:GetScaledCapsuleHalfHeight() + 5
            if player.viewObj:CapsuleHasRoomCheck(player.viewObj.CapsuleComponent, resLoation, 0, 0, DrawDebugType) then
              return resLoation
            end
          end
        end
      end
    end
  end
  return nil
end

function PlayerModule:OnAvatarNameChange(actorChangeInfo)
  local player = self._playerDic[actorChangeInfo.actor_id]
  if player then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendChangeName, player.serverData.base.logic_id, actorChangeInfo.name)
  end
  if player and player.hudComponent then
    player.hudComponent:SetHudName(actorChangeInfo.name)
    player.serverData.base.name = actorChangeInfo.name
  end
end

function PlayerModule:OnTick2(deltaTime)
  self._lastTickTime = self._lastTickTime + deltaTime
  for uid, player in pairs(self._playerDic) do
    if player then
      if player.isDestroy then
        self:RemovePlayer(player)
      else
        player:Update(deltaTime)
        self:CheckTaskStateEffects(player, deltaTime)
      end
    end
  end
end

function PlayerModule:OnTick(deltaTime)
  self._lastTickTime = self._lastTickTime + deltaTime
  local allPlayer = self._allPlayers
  local curCount = #allPlayer
  local idx = 0
  local tmpIdx = curCount
  while tmpIdx > 0 do
    local player = allPlayer[tmpIdx]
    if player.isDestroy then
      if tmpIdx ~= curCount then
        allPlayer[tmpIdx] = allPlayer[curCount]
      end
      table.remove(allPlayer, curCount)
      self._playerDic[player:GetUin()] = nil
      curCount = curCount - 1
    end
    tmpIdx = tmpIdx - 1
  end
  local selfPlayer = allPlayer[1]
  if selfPlayer then
    selfPlayer:Update(deltaTime)
    self:CheckTaskStateEffects(selfPlayer, deltaTime)
  end
  curCount = #allPlayer
  if curCount > 1 then
    local updateNum = self.MaxUpdatePlayerNumPerFrame
    local LoopNum = 0
    local CurrUpdatePlayerIdxOld = self.CurrUpdatePlayerIdx
    while updateNum > 0 and LoopNum < 1 do
      self.CurrUpdatePlayerIdx = self.CurrUpdatePlayerIdx % curCount + 1
      local idx = self.CurrUpdatePlayerIdx
      if CurrUpdatePlayerIdxOld == self.CurrUpdatePlayerIdx then
        LoopNum = LoopNum + 1
      end
      if 1 ~= idx then
        local player = allPlayer[idx]
        if player and not player.isDestroy then
          local deltaTime1 = player:GetLastUpdateTime()
          deltaTime1 = self._lastTickTime - deltaTime1
          player:Update(deltaTime1)
          player:SetLastUpdateTime(self._lastTickTime)
          self:CheckTaskStateEffects(player, deltaTime1)
          updateNum = updateNum - 1
        end
      end
    end
  end
  self:UpdateMagicCropping(deltaTime)
  self:UpdatePlayerCacheWhileVisit(deltaTime)
  self:SyncStatusImmediately()
end

function PlayerModule:SyncStatusImmediately()
  if #self._cachedStatusChanges > 0 then
    self.playerModuleNetCenter:SyncStatusList(self._cachedStatusChanges)
    self._cachedStatusChanges = {}
  elseif self.playerModuleNetCenter and self.playerModuleNetCenter._needSendMoveReq and self.playerModuleData.localPlayer then
    self.playerModuleNetCenter._needSendMoveReq = false
    self.playerModuleData.localPlayer.movementComponent:SendMoveReq(true, false)
  end
end

function PlayerModule:RemovePlayer(player)
  local allPlayer = self._allPlayers
  local curCount = #allPlayer
  for i = 1, curCount do
    if player == allPlayer[i] then
      allPlayer[i] = allPlayer[curCount]
      table.remove(allPlayer, curCount)
      break
    end
  end
  for uid, tablePlayer in pairs(self._playerDic) do
    if tablePlayer == player then
      self._playerDic[uid] = nil
      break
    end
  end
end

function PlayerModule:CreateLocalPlayer(playerActor, playerData, isLocalMode)
  local isReconnect = false
  self._localUin = playerData.base.actor_id
  Log.Debug("PlayerModule Crate LocalPlayer")
  local localPlayer = self.playerModuleData.localPlayer
  if localPlayer then
    isReconnect = true
    localPlayer:UpdateData(playerData, isReconnect)
    localPlayer.isReconnect = true
  else
    self.playerModuleData.localPlayer = SceneLocalPlayer(self)
    localPlayer = self.playerModuleData.localPlayer
    self:AddPlayer(localPlayer)
    localPlayer:InitData(nil, playerData)
    if self.playerInfo then
      self._playerDic[self._localUin] = localPlayer
    end
    local playerController = localPlayer:GetUEController()
    playerController:OnCreateLocalPlayer()
    localPlayer:SetCharacterGender(playerData.base.gender)
    local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
    if MainUIModule and MainUIModule:HasPanel("LobbyMain") then
      local LobbyMain = MainUIModule:GetPanel("LobbyMain")
      LobbyMain:BindPlayerWorldPlayerStatusChange()
    end
  end
  return isReconnect
end

function PlayerModule:AddPlayer(player)
  self._allPlayers[#self._allPlayers + 1] = player
end

function PlayerModule:OnPlayersUpdate(playerList)
  for _, v in ipairs(playerList) do
    local player = self._playerDic[v.uin]
    if player then
      player:UpdateServerData(v)
    end
  end
end

function PlayerModule:ClearAll()
  self:Log("ClearAll")
  for _, v in pairs(self._playerDic) do
    local player = v
    self:Log("ClearAll", player:GetServerId())
    if player == self.playerModuleData.localPlayer then
      self:Log("ClearAll localPlayer")
      player:Destroy()
    else
      player:Destroy()
    end
  end
  self._lastTickTime = 0
  self._playerDic = {}
  self._allPlayers = {}
  self._playerCacheWhileVisit = {}
  self._bornPos = nil
  self._bornRot = nil
  self.abilityPool = AbilityPool()
  self.playerModuleData.localPlayer = nil
end

function PlayerModule:ClearInReconnect()
  self:Log("ClearInReconnect")
  for _, v in pairs(self._playerDic) do
    local player = v
    if not self._playerCacheWhileVisit[player.serverData.base.actor_id] then
      self:Log("ClearInReconnect", player:GetServerId())
      if player ~= self.playerModuleData.localPlayer then
        player:Destroy()
        self:RemovePlayer(player)
      end
    end
  end
end

function PlayerModule:GetLocalPlayer()
  return self.playerModuleData and self.playerModuleData.localPlayer
end

function PlayerModule:GetLocalPlayerUIN()
  return self._localUin or 0
end

function PlayerModule:HideAllPlayer(hide, hideType)
  Log.Trace("PlayerModule:HidePlayer All", hide, hideType)
  hideType = hideType or UE4.EPlayerForceHiddenType.OldForceHidden
  self._hideAllPlayer:set(hideType, hide)
  for _, v in pairs(self._allPlayers) do
    local player = v
    if player and player.viewObj then
      player.viewObj:SetHiddenMask(hide, hideType)
    end
  end
  local localPlayer = self:GetLocalPlayer()
  if localPlayer then
    localPlayer:GetUEController():SetFadeEnable(not hide)
  end
end

function PlayerModule:ForceShowAllPlayer()
  self:Log("ForceShowAllPlayer:")
  self._hideAllPlayer:set(UE4.EPlayerForceHiddenType.OldForceHidden, false)
  for _, v in pairs(self._allPlayers) do
    local player = v
    if player and player.viewObj then
      player.viewObj:SetForceHidden(false)
      player:SetVisible(true)
    end
  end
  local localPlayer = self:GetLocalPlayer()
  if localPlayer then
    localPlayer:GetUEController():SetFadeEnable(true)
  end
end

function PlayerModule:HideOtherPlayer(hide, hideType)
  Log.Trace("PlayerModule:HidePlayer Other", hide, hideType)
  hideType = hideType or UE4.EPlayerForceHiddenType.OldForceHidden
  self._hideAllPlayer:set(hideType, hide)
  for _, v in pairs(self._allPlayers) do
    local player = v
    if player and player:GetServerId() ~= self._localUin and player.viewObj then
      player.viewObj:SetHiddenMask(hide, hideType)
    end
  end
end

function PlayerModule:HideNotVisitPlayer(hide, hideType)
  if not hideType then
    Log.Error("PlayerModule:HideNotVisitPlayer can't hide without hide type")
    return
  end
  Log.Debug("PlayerModule:HideNotVisitPlayer ", hide, hideType)
  hideType = hideType or UE4.EPlayerForceHiddenType.OldForceHidden
  self._hideNotVisitPlayer:set(hideType, hide)
  for _, v in pairs(self._allPlayers) do
    local player = v
    if player and player:GetServerId() ~= self._localUin and not _G.DataModelMgr.PlayerDataModel:IsVisitor(player:GetLogicId()) and player.viewObj then
      player.viewObj:SetHiddenMask(hide, hideType)
    end
  end
end

function PlayerModule:OnGetPlayerByServerID(playerId)
  return self._playerDic[playerId]
end

function PlayerModule:OnGetPlayerByUin(Uin)
  for _, player in pairs(self._playerDic) do
    if player.serverData.base.logic_id == Uin then
      return player
    end
  end
end

function PlayerModule:OnSetWaitToPlayVisitorAppearEffect(Uin)
  self._playerWaitToPlayVisitorAppearEffect[Uin] = true
end

function PlayerModule:HidePlayer(playerId, hidden)
  local player = self:OnGetPlayerByServerID(playerId)
  if player and player.viewObj then
    player.viewObj:SetForceHidden(hidden)
  end
end

function PlayerModule:SyncLocalPlayerStatus(status, subStatus, opCode, clearFlag, customParam)
  local newChange = ProtoMessage.newPlayerStatusSyncInfo()
  newChange.status = status
  newChange.sub_status = subStatus
  newChange.op_code = opCode
  newChange.custom_status_param = customParam
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
    newChange.is_normal_remove = not clearFlag
  end
  table.insert(self._cachedStatusChanges, newChange)
  if 36 == status or 37 == status then
    Log.ErrorFormat("[TogetherTeleport] HandStatus Add %d to CacheList,OpCode %d", status, opCode)
  end
end

function PlayerModule:MarkSendMoveReq()
  if self.playerModuleNetCenter then
    self.playerModuleNetCenter._needSendMoveReq = true
  end
end

function PlayerModule:CheckTaskStateEffects(player, deltaTime)
  if player.taskEffectState == self.taskEffectState.Start then
    player.remainPlayTime = player.remainPlayTime - deltaTime
    if player.remainPlayTime < 0 then
      if player.nextTaskEffectData.state == self.taskEffectState.Loop then
        player.taskEffectState = self.taskEffectState.Loop
        self:PlayTaskLoopFx(player.nextTaskEffectData.path, player)
        player.loopEffectID = 0
        player.nextTaskEffectData = nil
      elseif player.nextTaskEffectData.state == self.taskEffectState.End then
        player.taskEffectState = self.taskEffectState.End
        self:PlayTaskLoopFx(player.nextTaskEffectData.path, player)
        player.loopEffectID = 0
        player.nextTaskEffectData = nil
        player.remainPlayTime = 1
      end
    end
  elseif player.taskEffectState == self.taskEffectState.End then
    player.remainPlayTime = player.remainPlayTime - deltaTime
    if player.remainPlayTime < 0 then
      if player.nextTaskEffectData and player.nextTaskEffectData.state == self.taskEffectState.Start then
        player.taskEffectState = self.taskEffectState.Start
        player.remainPlayTime = 1
        self:PlayTaskStartFx(player.nextTaskEffectData.path, player)
        player.nextTaskEffectData = {
          state = self.taskEffectState.Loop,
          path = player.nextTaskEffectData.nextPath
        }
      else
        player.taskEffectState = self.taskEffectState.None
        player.nextTaskEffectData = NIL
      end
    end
  end
end

function PlayerModule:CheckTaskStateChangeValue(newTaskState, curTaskState)
  local addTaskState = {}
  local removeTaskState = {}
  local allTempList = {}
  for _, v in pairs(newTaskState) do
    allTempList[v] = (allTempList[v] or 0) + 1
  end
  for _, v in pairs(curTaskState) do
    allTempList[v] = (allTempList[v] or 0) - 1
  end
  for k, count in pairs(allTempList) do
    if count > 0 then
      addTaskState[k] = true
    elseif count < 0 then
      removeTaskState[k] = true
    end
  end
  return addTaskState, removeTaskState
end

function PlayerModule:PlayTaskStartFx(fxPath, player)
  local function OnTaskStartFxLoadSucc(_, req, fxClass)
    if player and player.viewObj and player.viewObj.FXComponent then
      player.viewObj.FXComponent:PlayFx_Type_Setting2(fxClass, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
    end
  end
  
  _G.NRCResourceManager:LoadResAsync(self, fxPath, -1, 10, OnTaskStartFxLoadSucc)
end

function PlayerModule:PlayTaskEndFx(fxPath, player)
  local function OnTaskEndFxLoadSucc(_, req, fxClass)
    if player and player.viewObj and player.viewObj.FXComponent then
      player.viewObj.FXComponent:PlayFx_Type_Setting2(fxClass, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
    end
  end
  
  _G.NRCResourceManager:LoadResAsync(self, fxPath, -1, 10, OnTaskEndFxLoadSucc)
end

function PlayerModule:PlayTaskLoopFx(fxPath, player)
  local function OnTaskLoopFxLoadSucc(_, req, fxClass)
    if player and player.viewObj and player.viewObj.FXComponent and 0 == player.loopEffectID then
      player.loopEffectID = player.viewObj.FXComponent:PlayFx_Type_Setting2(fxClass, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
    end
  end
  
  _G.NRCResourceManager:LoadResAsync(self, fxPath, -1, 10, OnTaskLoopFxLoadSucc)
end

function PlayerModule:CheckTaskStatus(actorID, status)
  if actorID == self._localUin and status == ProtoEnum.WorldPlayerStatusType.WPST_SPECIALMOVE then
    local player = self._playerDic[actorID]
    if player and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SPECIALMOVE) then
      local task_info = player.serverData.task_state_info or {}
      local curTaskState = task_info.enabled_state_ids or {}
      if curTaskState[1] then
        player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_SPECIALMOVE, nil, nil, curTaskState[1])
      end
    end
  end
end

function PlayerModule:InitTaskState(actorID)
  Log.Debug("PlayerModule:InitTaskState")
  local player = self._playerDic[actorID]
  if player then
    local task_info = player.serverData.task_state_info or {}
    local newTaskState = task_info.enabled_state_ids or {}
    local curTaskState = {}
    local addTaskState, removeTaskState = self:CheckTaskStateChangeValue(newTaskState, curTaskState)
    local taskStateConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_STATE_CONF):GetAllDatas()
    if actorID == self._localUin then
      local addSucceed = false
      player:ClearTaskAreaCache()
      for key, _ in pairs(addTaskState) do
        local confData = taskStateConf[key]
        if 1 == confData.state_type then
          if player.taskEffectState == self.taskEffectState.Start then
            player.nextTaskEffectData = {
              state = self.taskEffectState.Loop,
              path = confData.effect_loop
            }
          elseif player.taskEffectState == self.taskEffectState.End then
            player.nextTaskEffectData = {
              state = self.taskEffectState.Start,
              path = confData.effect_begin,
              nextPath = confData.effect_loop
            }
          elseif player.taskEffectState == self.taskEffectState.Loop then
          else
            self:PlayTaskStartFx(confData.effect_begin, player)
            player.taskEffectState = self.taskEffectState.Start
            player.remainPlayTime = 1
            player.nextTaskEffectData = {
              state = self.taskEffectState.Loop,
              path = confData.effect_loop
            }
          end
          player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_SPECIALMOVE, nil, nil, key)
          addSucceed = true
        end
        player:EnterTaskArea(key)
      end
      if not addSucceed then
        if player.taskEffectState == self.taskEffectState.Loop then
          player.viewObj.FXComponent:StopFx(player.loopEffectID)
          player.loopEffectID = nil
          player.taskEffectState = self.taskEffectState.None
          player.nextTaskEffectData = nil
        end
        player.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_SPECIALMOVE)
      end
    else
      for key, _ in pairs(addTaskState) do
        local confData = taskStateConf[key]
        if 1 == confData.state_type then
          self:PlayTaskStartFx(confData.effect_begin, player)
          player.taskEffectState = self.taskEffectState.Start
          player.remainPlayTime = 1
          player.nextTaskEffectData = {
            state = self.taskEffectState.Loop,
            path = confData.effect_loop
          }
        end
      end
    end
  else
    Log.Error("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:TaskStateChangeNty(info, isCreateActor)
  Log.Debug("PlayerModule:TaskStateChangeNty")
  local id = info.actor_id
  local player = self._playerDic[id]
  if player then
    local newTaskState = info.enabled_state_ids or {}
    local task_info = player.serverData.task_state_info or {}
    local curTaskState = task_info.enabled_state_ids or {}
    local addTaskState, removeTaskState = self:CheckTaskStateChangeValue(newTaskState, curTaskState)
    player.serverData.task_state_info = info
    local taskStateConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_STATE_CONF):GetAllDatas()
    for key, _ in pairs(addTaskState) do
      local confData = taskStateConf[key]
      if 1 == confData.state_type then
        if id == self._localUin then
          player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_SPECIALMOVE, nil, nil, key)
        end
        if player.taskEffectState == self.taskEffectState.Start then
          player.nextTaskEffectData = {
            state = self.taskEffectState.Loop,
            path = confData.effect_loop
          }
        elseif player.taskEffectState == self.taskEffectState.End then
          player.nextTaskEffectData = {
            state = self.taskEffectState.Start,
            path = confData.effect_begin,
            nextPath = confData.effect_loop
          }
        else
          self:PlayTaskStartFx(confData.effect_begin, player)
          player.taskEffectState = self.taskEffectState.Start
          player.remainPlayTime = 1
          player.nextTaskEffectData = {
            state = self.taskEffectState.Loop,
            path = confData.effect_loop
          }
        end
      end
      if id == self._localUin then
        player:EnterTaskArea(key)
      end
    end
    for key, _ in pairs(removeTaskState) do
      local confData = taskStateConf[key]
      if 1 == confData.state_type then
        if id == self._localUin then
          player.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_SPECIALMOVE, nil, nil, key)
        end
        if player.taskEffectState == self.taskEffectState.Start then
          player.nextTaskEffectData = {
            state = self.taskEffectState.End,
            path = confData.effect_end
          }
        elseif player.taskEffectState == self.taskEffectState.Loop then
          player.viewObj.FXComponent:StopFx(player.loopEffectID)
          player.loopEffectID = nil
          player.remainPlayTime = 1
          self:PlayTaskEndFx(confData.effect_end, player)
          player.nextTaskEffectData = nil
        end
      end
      if id == self._localUin then
        player:LeaveTaskArea(key)
      end
    end
  else
    Log.Error("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:SyncPlayerStatus(info)
  Log.Debug("PlayerModule:OnReceiveStatusInfo")
  local id = info.actor_id
  if id == self._localUin then
    Log.Debug("PlayerModule: Receive self SpaceAct_SyncPlayerStatus")
  end
  local player = self._playerDic[id]
  if player then
    player.statusComponent:OnReceiveSyncAction(info)
    self:CheckTaskStatus(id, info.status)
  else
    Log.Debug("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:SyncPlayerOperation(info)
  Log.Debug("PlayerModule:OnReceiveSyncPlayerOperation")
  local id = info.operation.operator_id
  if id == self._localUin then
    Log.Debug("PlayerModule: Receive self ClientOperation")
    return
  end
  local player = self._playerDic[id]
  if player and player.viewObj then
    if 1 == info.operation.operator_type then
      player:SendEvent(PlayerModuleEvent.ON_THROW_SYNC, info.operation)
    elseif 2 == info.operation.operator_type then
      player:EnsureComponent(SyncNpcActionComponent)
      player.SyncNpcActionComponent:DealClientOperation(info.operation)
    elseif info.operation.operator_type == ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM then
      local performType = info.operation.player_perform_info.perform_type
      if performType == ProtoEnum.PlayerPerformType.PPT_SUIT_IDLE or performType == ProtoEnum.PlayerPerformType.PPT_SUIT_IDLE_BREAK or performType > 10000 then
        player:OnPlayerSuitRelax(info.operation)
      else
        player.viewObj:OnPlaySyncPerform(info.operation)
      end
    elseif info.operation.operator_type == ProtoEnum.ClientOperationType.COT_TOGETHER_CINEMATIC or info.operation.operator_type == ProtoEnum.ClientOperationType.COT_TOGETHER_MOVIE or info.operation.operator_type == ProtoEnum.ClientOperationType.COT_TOGETHER_DIALOGUE then
      local local_player = self.playerModuleData.localPlayer
      if local_player and local_player.TogetherSyncComponent then
        local_player.TogetherSyncComponent:OnSync(info)
      end
    end
  else
    Log.Debug("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:OnAuraInfoChange(Info)
  if Info.actor_id == self._localUin then
    local Player = self.playerModuleData.localPlayer
    if Player then
      Player.AuraComponent:UpdateByAction(Info)
    else
      Log.Error("Player\229\176\154\230\156\170\229\136\155\229\187\186\230\136\144\229\138\159\239\188\129\239\188\129")
    end
  end
end

function PlayerModule:OnFieldTagChange(Info)
  local Player = self.playerModuleData.localPlayer
  Player.AuraComponent:UpdateFieldTag(Info)
end

function PlayerModule:OnWorldCombatBuffChange(Action, Tag, BaseData)
  local player = self._playerDic[Action.actor_id]
  Log.Debug("PlayerModule:OnWorldCombatBuffChange", player, Action and Action.actor_id, self._localUin, player and player.SocialComponent)
  if player then
    local Comp = player:EnsureComponent(WorldCombatBuffComponent)
    Comp:OnBuffChanges(Action)
    if Action.actor_id == self._localUin and player.SocialComponent then
      player.SocialComponent:OnBuffChange(Action)
    end
  else
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176id\228\184\186 %u \231\154\132Player", Action.actor_id)
  end
end

function PlayerModule:PlayVitalityRecoverEffect(player)
  if player.vitality_recover_effect_id then
    return
  end
  player.vitality_recover_effect_id = 0
  
  local function OnTaskLoopFxLoadSucc(_, req, fxClass)
    if player and player.viewObj and player.viewObj.FXComponent and 0 == player.vitality_recover_effect_id then
      player.vitality_recover_effect_id = player.viewObj.FXComponent:PlayFx_Type_Setting2(fxClass, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
    end
  end
  
  local fxPath = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Res/XianZhiYiSu/NS_Scene_YSXZ_Loop.NS_Scene_YSXZ_Loop'"
  _G.NRCResourceManager:LoadResAsync(self, fxPath, -1, 10, OnTaskLoopFxLoadSucc)
end

function PlayerModule:StopVitalityRecoverEffect(player)
  if player.vitality_recover_effect_id and 0 ~= player.vitality_recover_effect_id then
    player.viewObj.FXComponent:StopFx(player.vitality_recover_effect_id)
  end
  player.vitality_recover_effect_id = nil
end

function PlayerModule:InitBuffs(player)
  if player and player.serverData and player.serverData.buff_info then
    local buffInfo = player.serverData.buff_info
    local RawBuffs = buffInfo.buff_infos
    if not RawBuffs then
      return
    end
    if 0 == #RawBuffs then
      return
    end
    for _, info in ipairs(RawBuffs) do
      local ID = info.buff_cfg_id
      if ID then
        local Conf = _G.DataConfigManager:GetWorldBuffConf(ID)
        if Conf then
          local EffectType = Conf and Conf.buff_effect_type
          if EffectType == Enum.WorldBuffEffect.WBE_RECOVER_STAMINA then
            if 1 == info.buff_val then
              self:PlayVitalityRecoverEffect(player)
            end
            break
          end
        end
      end
    end
  end
end

function PlayerModule:SocialBuffChange(player, Change, Tag, BaseData)
  if not Change then
    return
  end
  local RemoveID = Change and Change.removed_buff_id
  if RemoveID and RemoveID == player.socialBuffID then
    player.socialBuffID = nil
    self:StopVitalityRecoverEffect(player)
    return
  end
  local ChangeInfo = Change and Change.changed_buff_info
  if not ChangeInfo and Change and Change.buff_info and #Change.buff_info > 0 then
    ChangeInfo = Change.buff_info[1]
  end
  if ChangeInfo then
    local ID = ChangeInfo.buff_cfg_id
    if not ID or 0 == ID then
      Log.Error("SocialBuffChange BuffID\228\184\141\229\144\136\230\179\149")
      return
    end
    local Conf = _G.DataConfigManager:GetWorldBuffConf(ID)
    if not Conf then
      Log.Error("\230\137\190\228\184\141\229\136\176Buff\230\149\176\230\141\174")
      return
    end
    local EffectType = Conf and Conf.buff_effect_type
    if EffectType == Enum.WorldBuffEffect.WBE_RECOVER_STAMINA then
      player.socialBuffID = ChangeInfo.id
      if 0 == ChangeInfo.buff_val then
        self:StopVitalityRecoverEffect(player)
      else
        self:PlayVitalityRecoverEffect(player)
      end
    end
  end
end

function PlayerModule:OnBodyTempChange(notify)
  local player = self._playerDic[notify.actor_id]
  if player and player.TemperatureComponent then
    player.TemperatureComponent:OnRecBodyTempNofity(notify)
  end
end

function PlayerModule:GetAllPlayer()
  return self._allPlayers
end

function PlayerModule:PredictThrow(scenePlayer, DrawDebugType, DrawDebugTime)
  if scenePlayer then
    local ability = scenePlayer.abilityComponent:GetAbility(AbilityID.AIM_THROW, true)
    if ability then
      return ability:PredictThrow(DrawDebugType, DrawDebugTime)
    end
  end
  return {bHit = false}
end

function PlayerModule:CreateTestPlayer(gender)
  if self._playerDic[GlobalConfig.TestPlayerID] then
    self:DestroyTestPlayer()
    return
  end
  local playerInfo = ProtoMessage:newActorInfo_Avatar()
  playerInfo.base.actor_id = GlobalConfig.TestPlayerID
  playerInfo.base.name = "default test player"
  playerInfo.base.lv = 10
  playerInfo.base.gender = gender and gender or 2
  playerInfo.fashion_info = nil
  playerInfo.move_info = nil
  local bornPos = self.playerModuleData.localPlayer:GetActorLocation()
  playerInfo.base.pt.pos.x = bornPos.X
  playerInfo.base.pt.pos.y = bornPos.Y
  playerInfo.base.pt.pos.z = bornPos.Z
  playerInfo.base.pt.dir.x = 0
  playerInfo.base.pt.dir.y = 0
  playerInfo.base.pt.dir.z = 0
  self:OnPlayerAppear(playerInfo)
end

function PlayerModule:DestroyTestPlayer()
  self:OnPlayerDisappear(GlobalConfig.TestPlayerID)
end

function PlayerModule:GetTestPlayer()
  return self._playerDic[GlobalConfig.TestPlayerID]
end

function PlayerModule:PrintVisibleZoneInfo(zone)
  if zone.actor_id == self._localUin then
    local localPlayer = self.playerModuleData.localPlayer
    if localPlayer then
      if zone.enter then
        localPlayer.visibleZoneNum = 1
      elseif zone.leave then
        localPlayer.visibleZoneNum = 0
      end
    end
  end
  if zone.enter then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.EntranceVisibleZone, zone.enter.pool.area_cfg_id)
  elseif zone.leave then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.LeaveVisibleZone, zone.leave.pool.area_cfg_id)
  end
  if GlobalConfig.DebugVisiblePoolInfo and _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.RefreshVisiblePoolInfo, zone)
  end
  if not GlobalConfig.DebugVisibleZoneInfo then
    return
  end
  Log.Debug("PlayerModule PrintVisibleZoneInfo")
  local info
  if zone.enter then
    info = string.format("%s \232\191\155\229\133\165 %s", zone.enter.entrant_name, self:FormatVisiblePool(zone.enter.pool))
    UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), info, true, true, UE4.FLinearColor(1, 1, 1, 1), 15)
  end
  if zone.leave then
    info = string.format("%s \231\166\187\229\188\128 %s %s %s", zone.leave.leaver_name, self:FormatVisiblePool(zone.leave.pool), zone.leave.merge and string.format("\228\184\142\229\143\175\232\167\129\230\177\160%d\229\144\136\229\185\182", zone.leave.pool.pool_id) or "", zone.leave.recycle and "\229\143\175\232\167\129\230\177\160\232\162\171\233\148\128\230\175\129" or "")
    UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), info, true, true, UE4.FLinearColor(1, 1, 1, 1), 15)
  end
end

function PlayerModule:FormatVisiblePool(pool)
  local strFmt = _G.LuaText.visible_gm
  local baseInfo = string.format(strFmt, pool.area_cfg_id, pool.pool_id, pool.cell_id_str or "None")
  if pool.players then
    for _, v in pairs(pool.players) do
      local playerInfo = self:FormatVisiblePlayer(v)
      baseInfo = baseInfo .. playerInfo
    end
  end
  return baseInfo
end

function PlayerModule:FormatVisiblePlayer(player)
  return string.format(LuaText.playermodule_6, player.name, player.in_visible and LuaText.playermodule_7 or LuaText.playermodule_8)
end

function PlayerModule:OnMarkNoCrouch(noCrouch)
  local localPlayer = self.playerModuleData.localPlayer
  if localPlayer.CrouchComponent then
    localPlayer.CrouchComponent:SetNoCrouch(noCrouch)
  end
end

function PlayerModule:PlayerEnterBattle(player)
  if player.isLocal then
    player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_BATTLE)
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint, true)
    player.vitalityComponent:SetEnable(false)
    Log.Debug("LocalPlayerEnterBattle Disable VitalityComponent")
  end
end

function PlayerModule:PlayerLeftBattle(player)
  if player.isLocal then
    player.statusComponent:ClearStatus(Enum.WorldPlayerStatusType.WPST_BATTLE)
    player.vitalityComponent:SetEnable(true)
    Log.Debug("LocalPlayerLeftBattle Enable VitalityComponent")
  end
end

function PlayerModule:EnvMask(mask)
  local id = mask.actor_id
  if id ~= self._localUin then
    return
  end
  local player = self._playerDic[id]
  if player then
    mask.ban_type = mask.ban_type or {}
    mask.ban_ride_sockets = mask.ban_ride_sockets or {}
    table.sort(mask.ban_type, function(a, b)
      return a < b
    end)
    table.sort(mask.ban_ride_sockets, function(a, b)
      return a < b
    end)
    local isDiffBan = false
    if #DataModelMgr.PlayerDataModel.ban_type ~= #mask.ban_type then
      isDiffBan = true
    else
      for i = 1, #mask.ban_type do
        if DataModelMgr.PlayerDataModel.ban_type[i] ~= mask.ban_type[i] then
          isDiffBan = true
          break
        end
      end
    end
    if #DataModelMgr.PlayerDataModel.ban_ride_sockets ~= #mask.ban_ride_sockets then
      isDiffBan = true
    else
      for i = 1, #mask.ban_ride_sockets do
        if DataModelMgr.PlayerDataModel.ban_ride_sockets[i] ~= mask.ban_ride_sockets[i] then
          isDiffBan = true
          break
        end
      end
    end
    if isDiffBan or DataModelMgr.PlayerDataModel.envMask ~= mask.env_mask then
      DataModelMgr.PlayerDataModel.envMask = mask.env_mask
      DataModelMgr.PlayerDataModel.ban_type = mask.ban_type
      DataModelMgr.PlayerDataModel.ban_ride_sockets = mask.ban_ride_sockets
      local ban_ride_sockets_mask = 0
      for i = 1, #mask.ban_ride_sockets do
        ban_ride_sockets_mask = ban_ride_sockets_mask | 1 << mask.ban_ride_sockets[i]
      end
      DataModelMgr.PlayerDataModel.ban_ride_sockets_mask = ban_ride_sockets_mask
      player:SendEvent(PlayerModuleEvent.ON_ENV_MASK_CHANGED)
    end
  else
    Log.Debug("PlayerModule: can't find player by id ", id)
  end
end

function PlayerModule:ThrownPetInfoChange(action)
  local ID = action.actor_id
  if ID == self._localUin and self.playerModuleData then
    self.playerModuleData.localPlayer.ThrowManagementComponent:UpdateThrow(action)
  end
end

function PlayerModule:OnPetMainTeamChanged(CurMainTeamIndex)
  Log.Debug("PlayerModule:OnPetMainTeamChanged")
  if self.playerModuleData == nil then
    Log.Debug("PlayerModule:OnPetMainTeamChanged playerModuleData is nil")
    return
  end
  if nil == self.playerModuleData.FriendRidePetMap then
    Log.Debug("PlayerModule:OnPetMainTeamChanged FriendRidePetMap is nil")
    return
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnForceUpdateFriendRideState)
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, Enum.PlayerTeamType.PTT_BIG_WORLD)
  local CurMainTeam = teamInfo.teams[CurMainTeamIndex + 1]
  if nil == CurMainTeam then
    return
  end
  local bAlreadyUpdateUI = false
  for friendRidePetGID, _ in pairs(self.playerModuleData.FriendRidePetMap or {}) do
    if friendRidePetGID then
      local petInfo = PetUtils.PetTeamFindPetInfoByIndex(CurMainTeam, friendRidePetGID)
      if not petInfo then
        self:FriendRideSelfPetStateChange(false, nil, friendRidePetGID, nil, EnumFriendRideStateChangeType.PetMainTeamChanged)
        bAlreadyUpdateUI = true
      end
    end
  end
  if not bAlreadyUpdateUI then
    local player = self:GetLocalPlayer()
    player:SendEvent(PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE)
  end
end

function PlayerModule:OnFriendRideNty(nty)
  Log.DebugFormat("PlayerModule:OnFriendRideNty")
  Log.Dump(nty, 6, "ZoneSceneFriendRideNotify:")
  if nty and nty.friend_uin and nty.reason then
    local PetOwnerUin = nty.friend_uin
    local NotifyReason = nty.reason
    local IsFriendRiding = false
    self:SelfRideFriendPetStateChange(IsFriendRiding, PetOwnerUin, NotifyReason)
  end
end

function PlayerModule:FriendRideStateChange(action)
  Log.DebugFormat("PlayerModule:FriendRideStateChange")
  Log.Dump(action, 6, "friend_ride:")
  if action and action.is_riding ~= nil then
    local IsFriendRiding = action.is_riding
    if action.friend_ride_info_list and action.friend_ride_info_list[1] then
      local friendUin = action.friend_ride_info_list[1].uin
      local ridingPetGid = action.friend_ride_info_list[1].gid
      local pet = _G.DataModelMgr.PlayerDataModel:GetPetByGid(ridingPetGid)
      if pet then
        pet.rideFriendUin = IsFriendRiding and friendUin or nil
      end
      local friendName = action.friend_ride_info_list[1].name
      local player = self:GetLocalPlayer()
      if player then
        local LocalPlayerUin = player:GetLogicId()
        if LocalPlayerUin == friendUin then
        else
          self:FriendRideSelfPetStateChange(IsFriendRiding, friendUin, ridingPetGid, friendName, EnumFriendRideStateChangeType.ActionNotify)
        end
      end
    end
  end
end

function PlayerModule:FriendRideSelfPetStateChange(IsFriendRiding, friendUin, ridingPetGid, friendName, changeReasonType)
  Log.Debug("PlayerModule:FriendRideSelfPetStateChange IsFriendRiding=[", IsFriendRiding or 0, "] friendUin=[", friendUin or 0, "] ridingPetGid=[", ridingPetGid or 0, "], friendName=[", friendName or "", "]")
  if self.playerModuleData.FriendRidePetMap == nil then
    self.playerModuleData.FriendRidePetMap = {}
  end
  if IsFriendRiding then
    self.playerModuleData.FriendRidePetMap[ridingPetGid] = {IsFriendRiding = IsFriendRiding, FriendUin = friendUin}
    if not string.IsNilOrEmpty(friendName) then
      self.playerModuleData.FriendRidePetMap[ridingPetGid].FriendName = friendName
    end
  else
    self.playerModuleData.FriendRidePetMap[ridingPetGid] = nil
  end
  local player = self:GetLocalPlayer()
  player:SendEvent(PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE)
  if IsFriendRiding then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(ridingPetGid)
    if PetData then
      local TipText = _G.DataConfigManager:GetLocalizationConf("interactiontree_pet_friend_touch").msg
      local FinalTipText = string.format(TipText, friendName, PetData.name)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, FinalTipText)
    end
  elseif changeReasonType == EnumFriendRideStateChangeType.ActionNotify then
    local Session = ThrowSession.GetWithGID(ridingPetGid)
    if Session then
      Session:OnNPCFriendRideEnd()
    end
  end
end

function PlayerModule:SelfRideFriendPetStateChange(IsRiding, PetOwnerUin, NotifyReason)
  Log.Debug("PlayerModule:SelfRideFriendPetStateChange IsRiding=[", IsRiding or 0, "] PetOwnerUin=[", PetOwnerUin or 0, "] NotifyReason=[", NotifyReason or 0, "]")
  if IsRiding then
  else
    local TipText = _G.DataConfigManager:GetLocalizationConf("interactiontree_petshare_cancel").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, TipText)
  end
end

function PlayerModule:CheckPetIsFriendRiding(petGid)
  local IsFriendRiding = false
  if self.playerModuleData == nil then
    return IsFriendRiding
  end
  if nil == self.playerModuleData.FriendRidePetMap then
    return IsFriendRiding
  end
  if nil == petGid then
    return IsFriendRiding
  end
  if self.playerModuleData.FriendRidePetMap[petGid] then
    IsFriendRiding = self.playerModuleData.FriendRidePetMap[petGid].IsFriendRiding
    return IsFriendRiding
  end
  return IsFriendRiding
end

function PlayerModule:GetFriendRideInfoByPetGID(PetGID)
  if nil == PetGID then
    return
  end
  if nil == self.playerModuleData then
    return nil
  end
  if nil == self.playerModuleData.FriendRidePetMap then
    return nil
  end
  return self.playerModuleData.FriendRidePetMap[PetGID]
end

function PlayerModule:PlayerFashionChange(action)
  local ID = action.actor_id
  if ID == self._localUin then
    local player = self:GetLocalPlayer()
    player:SetPlayerFashionWearData(action.wearing_item)
    player:SendEvent(PlayerModuleEvent.ON_PLAYER_FASHION_CHANGE)
    player:UpdateShoesSoundSwitch()
  else
    local player = self._playerDic[ID]
    if player then
      player:SetPlayerFashionWearData(action.wearing_item)
    end
  end
end

function PlayerModule:PlayerSalonChange(action)
  local ID = action.actor_id
  if ID == self._localUin then
    local player = self:GetLocalPlayer()
    player:SetPlayerSalonWearData(action.salon_item_wear_data)
  else
    local player = self._playerDic[ID]
    player:SetPlayerSalonWearData(action.salon_item_wear_data)
  end
end

function PlayerModule:AddDistanceFadeMesh(Mesh)
  self.playerModuleData.localPlayer.FadeComponent:AddCommonMesh(Mesh)
end

function PlayerModule:RemoveDistanceFadeMesh(Mesh)
  self.playerModuleData.localPlayer.FadeComponent:RemoveCommonMesh(Mesh)
end

function PlayerModule:AddDistanceFadeRule(ruleFn)
  return self.playerModuleData.localPlayer.FadeComponent:ApplyFadeRule(ruleFn)
end

function PlayerModule:RemoveDistanceFadeRule(id)
  self.playerModuleData.localPlayer.FadeComponent:RemoveFadeRule(id)
end

function PlayerModule:SetFadeSpeed(fadeSpeed)
  self.playerModuleData.localPlayer.FadeComponent:SetFadeSpeed(fadeSpeed)
end

function PlayerModule:ResetFadeSpeed()
  self.playerModuleData.localPlayer.FadeComponent:ResetFadeSpeed()
end

function PlayerModule:LockTeleport(LockType)
  self.playerModuleData.localPlayer.teleportComponent:LockTeleport(LockType)
end

function PlayerModule:UnLockTeleport(LockType)
  self.playerModuleData.localPlayer.teleportComponent:UnLockTeleport(LockType)
end

function PlayerModule:BindTeleportCallback(Stamp, Caller, Callback)
  self.playerModuleData.localPlayer.teleportComponent:BindCallback(Stamp, Caller, Callback)
end

function PlayerModule:GetCachedTeleportNotify()
  return self.playerModuleData.localPlayer.teleportComponent:GetCachedNotify()
end

function PlayerModule:HideLocalPlayer(Hide, hideType)
  Log.Trace("PlayerModule:HidePlayer Local", Hide, hideType)
  hideType = hideType or UE4.EPlayerForceHiddenType.OldForceHidden
  local localPlayer = self:GetLocalPlayer()
  if localPlayer then
    localPlayer.viewObj:SetHiddenMask(Hide, hideType)
    localPlayer:GetUEController():SetFadeEnable(not localPlayer.viewObj:GetActorHidden())
  end
end

function PlayerModule:CloseLocalPlayerCollision(close)
  local localPlayer = self:GetLocalPlayer()
  if localPlayer and localPlayer.viewObj then
    localPlayer.viewObj:SetActorEnableCollision(not close)
  end
end

function PlayerModule:LockLocalPlayerRelaxIdle(Locked)
  local localPlayer = self:GetLocalPlayer()
  if localPlayer then
    localPlayer.viewObj.bActiveIdle = Locked
  end
end

function PlayerModule:SetLocalPlayerHandIkTargetMesh(MeshTarget)
  local localPlayer = self:GetLocalPlayer()
  if localPlayer then
    localPlayer.viewObj.HandIkTarget = MeshTarget
  end
end

function PlayerModule:PetInfoChange(action)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.actor_id)
  local ActionPetInfo = action.pet_info
  if player.petInfoMap == nil then
    player.petInfoMap = {}
    if player.serverData.scene_pet_info and player.serverData.scene_pet_info.pet_infos then
      for _, pet_info in ipairs(player.serverData.scene_pet_info.pet_infos) do
        player.petInfoMap[pet_info.gid] = pet_info
      end
    end
  end
  ActionPetInfo.interact_quantity = ActionPetInfo.interact_quantity or 0
  ActionPetInfo.interact_count = ActionPetInfo.interact_count or 0
  ActionPetInfo.interact_quantity_threshold = ActionPetInfo.interact_quantity_threshold or 0
  player.petInfoMap[action.pet_info.gid] = ActionPetInfo
  if _G.GlobalConfig.bShowHintWhenInteractQuantityChange and ActionPetInfo.npc_id then
    local pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ActionPetInfo.npc_id)
    if pet then
      pet:OnInteractQuantityChange(action)
    end
  end
  if ActionPetInfo.interact_quantity >= ActionPetInfo.interact_quantity_threshold and ActionPetInfo.npc_id then
    local pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ActionPetInfo.npc_id)
    if pet and pet.AIComponent then
      pet.AIComponent:SendBondBeginEvent()
    end
  end
end

function PlayerModule:SyncBasicMovement(basicMovementID, need_start_cost)
  self.playerModuleNetCenter:SyncBasicMovement(basicMovementID, need_start_cost)
end

function PlayerModule:OnCmdGetPlayerIsAiming()
  local localPlayer = self:GetLocalPlayer()
  if localPlayer and (localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)) then
    return true
  end
  return false
end

function PlayerModule:OnForceSetPlayerTurnToBoss(bossContentId)
  local isInBossBattle = true
  local bossPosition = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetBossLocation, bossContentId)
  if not bossPosition then
    return false
  end
  local localPlayer = self:GetLocalPlayer()
  if not localPlayer then
    isInBossBattle = false
    return isInBossBattle
  end
  local targetRotation = (bossPosition - localPlayer:GetActorLocation()):ToRotator()
  if (bossPosition - localPlayer:GetActorLocation()):Size() > 2000 then
    isInBossBattle = false
  end
  localPlayer:SetActorRotation(targetRotation)
  local playerController = localPlayer:GetUEController()
  if playerController then
    playerController:SetControlRotation(targetRotation)
  end
  return isInBossBattle
end

function PlayerModule:OnCmdGetPlayerFollowInfo()
  return self.playerInfo.follow_info
end

function PlayerModule:PosInvalidOutOfStuck()
  local Ctx = DialogContext()
  local tips = LuaText.cross_border_return_safe
  Ctx:SetContent(tips)
  Ctx:SetMode(DialogContext.Mode.OK)
  Ctx:SetTitle(LuaText.player_unstuck_confirm_title)
  local str = _G.LuaText.cross_border_return_safe_btn
  Ctx:SetButtonText(str)
  Ctx:SetCloseFlagWhenPlayerDie()
  local countdowntime = _G.DataConfigManager:GetMapGlobalConfig("cross_border_return_safe_time").num
  Ctx.countdownTime = countdowntime
  Ctx:SetCallbackOkOnly(self, self.SendOutOfStuckReq)
  if not self.BanPosInvalidFlag or self.BanPosInvalidFlag == false then
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  end
end

function PlayerModule:SendOutOfStuckReq()
  local req = ProtoMessage:newZoneSceneUnstuckTeleportReq()
  req.ignore_cooldown = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_UNSTUCK_TELEPORT_REQ, req, self, self.OutOfStuckRsp)
end

function PlayerModule:SyncChatOfflineRedPoint()
  if not _G.ZoneServer:IsConnected() then
    Log.Warning("[PlayerModule:SyncChatOfflineRedPoint] ZoneServer not connected")
    return
  end
end

function PlayerModule:BanPosInvalidOutOfStuck()
  if not self.BanPosInvalidFlag or self.BanPosInvalidFlag == false then
    self.BanPosInvalidFlag = true
    Log.Error("\230\137\147\229\188\128\229\177\143\232\148\189\230\136\144\229\138\159\239\188\140\231\142\176\229\156\168\228\188\154\229\177\143\232\148\189\228\189\141\231\189\174\233\157\158\230\179\149\229\188\185\231\170\151")
  else
    self.BanPosInvalidFlag = false
    Log.Error("\229\133\179\233\151\173\229\177\143\232\148\189\230\136\144\229\138\159\239\188\140\231\142\176\229\156\168\228\184\141\228\188\154\229\177\143\232\148\189\228\189\141\231\189\174\233\157\158\230\179\149\229\188\185\231\170\151")
  end
end

function PlayerModule:InitMagicCropping()
  local group_level = UE4.UNRCQualityLibrary.GetGroupQualityLevel("UtilityGroup")
  local quality_config = _G.DataConfigManager:GetBasicQualityConfigConf("StarMagicMaxCounts")
  local quality_list = quality_config.Qualities_IOS
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    quality_list = quality_config.Qualities_Android
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    quality_list = quality_config.Qualities_PC
  end
  local quality = quality_list[group_level + 1]
  if not quality then
    Log.Error("StarMagicMaxCounts is invalid!!!", group_level, table.tostring(quality_list))
    self.MaxStarCounts = 6
  else
    self.MaxStarCounts = tonumber(quality.QualityPriority)
    if not self.MaxStarCounts then
      Log.Error("StarMagicMaxCounts is invalid!!!", group_level, table.tostring(quality_list), quality.QualityPriority)
      self.MaxStarCounts = 6
    end
  end
  quality_config = _G.DataConfigManager:GetBasicQualityConfigConf("StarMagicMaxCountsOneFrame")
  quality_list = quality_config.Qualities_IOS
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    quality_list = quality_config.Qualities_Android
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    quality_list = quality_config.Qualities_PC
  end
  quality = quality_list[group_level + 1]
  if not quality then
    Log.Error("MaxStarCountsCurFrame is invalid!!!", group_level, table.tostring(quality_list))
    self.MaxStarCountsCurFrame = 3
  else
    self.MaxStarCountsCurFrame = tonumber(quality.QualityPriority)
    if not self.MaxStarCountsCurFrame then
      Log.Error("MaxStarCountsCurFrame is invalid!!!", group_level, table.tostring(quality_list), quality.QualityPriority)
      self.MaxStarCountsCurFrame = 3
    end
  end
  self.StarCountsHoldTime = 3
  self.NeedUpdateMagicCroppingTime = 0.3
  self.NeedCheckMagicCroppingPlayerTime = 2
  self.CurStarCounts = {}
  self.CurFrameStarCounts = 0
  self.CurPlayersStar = {}
  self.CurPlayersCounts = 0
  self.UpdateMagicCroppingTime = 0
  self.CheckMagicCroppingPlayerTime = 0
end

function PlayerModule:OutOfStuckRsp()
end

function PlayerModule:TryAddMagicStarCounts(Caster)
  if self.CurFrameStarCounts >= self.MaxStarCountsCurFrame then
    return false
  end
  if #self.CurStarCounts + self.CurPlayersCounts >= self.MaxStarCounts then
    return false
  end
  self.CurFrameStarCounts = self.CurFrameStarCounts + 1
  self.CurPlayersCounts = self.CurPlayersCounts + 1
  self.CurPlayersStar[Caster] = 1
  return true
end

function PlayerModule:RemoveMagicStarCounts(Caster)
  if self.CurPlayersStar[Caster] then
    self.CurPlayersStar[Caster] = nil
    self.CurPlayersCounts = self.CurPlayersCounts - 1
    table.insert(self.CurStarCounts, self.StarCountsHoldTime)
  end
end

function PlayerModule:UpdateMagicCropping(deltaTime)
  self.UpdateMagicCroppingTime = self.UpdateMagicCroppingTime + deltaTime
  self.CheckMagicCroppingPlayerTime = self.CheckMagicCroppingPlayerTime + deltaTime
  self.CurFrameStarCounts = 0
  if self.UpdateMagicCroppingTime > self.NeedUpdateMagicCroppingTime then
    local removeIndex = -1
    for index, value in ipairs(self.CurStarCounts) do
      self.CurStarCounts[index] = value - self.UpdateMagicCroppingTime
      if value <= 0 then
        removeIndex = index
      end
    end
    if removeIndex > 0 then
      local TableLength = #self.CurStarCounts
      for i = removeIndex + 1, TableLength do
        self.CurStarCounts[i - removeIndex] = self.CurStarCounts[i]
      end
      for i = TableLength, TableLength - removeIndex + 1, -1 do
        self.CurStarCounts[i] = nil
      end
    end
    self.UpdateMagicCroppingTime = 0
  end
  if self.CheckMagicCroppingPlayerTime > self.NeedCheckMagicCroppingPlayerTime then
    self.CheckMagicCroppingPlayerTime = 0
    for id, _ in pairs(self.CurPlayersStar) do
      if not self._playerDic[id] then
        Log.Error("\231\167\187\233\153\164\230\151\160\230\149\136\231\154\132player")
        self:RemoveMagicStarCounts(id)
      end
    end
  end
end

function PlayerModule:UpdatePlayerCacheWhileVisit(deltaTime)
  local RemoveTable
  for i, v in pairs(self._playerCacheWhileVisit) do
    self._playerCacheWhileVisit[i] = self._playerCacheWhileVisit[i] - deltaTime
    if self._playerCacheWhileVisit[i] < 0 then
      RemoveTable = RemoveTable or {}
      table.insert(RemoveTable, i)
    end
  end
  if RemoveTable then
    for i, v in pairs(RemoveTable) do
      Log.Error("\230\168\161\229\158\139\232\182\133\230\151\182\230\184\133\231\144\134", v)
      self._playerCacheWhileVisit[v] = nil
      self:OnActorLeaveAction(v)
    end
  end
end

function PlayerModule:TryAttackLocalPlayerWithRangeCheck(Location, Range, Damage, IsHeavy)
  local player = self:GetLocalPlayer()
  if player then
    local Loc = player:GetActorLocation()
    if Range > Loc:Dist(Location) then
      Loc:Sub(Location)
      Loc:Normalize()
      player:SendEvent(PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, Damage, Loc, IsHeavy)
    end
  end
end

function PlayerModule:ClearCachedStatusChange()
  self.playerModuleNetCenter.failedSyncStatus = {}
  self._cachedStatusChanges = {}
end

function PlayerModule:RemoveCachedHandStatusChange(status)
  if self._cachedStatusChanges and #self._cachedStatusChanges > 0 then
    for i = #self._cachedStatusChanges, 1, -1 do
      local cacheStatusInfo = self._cachedStatusChanges[i]
      if cacheStatusInfo.status == status then
        table.remove(self._cachedStatusChanges, i)
      end
    end
  end
end

function PlayerModule:OnTravelTogetherSync(nty)
  local actorId = nty.actor_id
  local player = self:OnGetPlayerByServerID(actorId)
  if player and UE.UObject.IsValid(player.viewObj) then
    local clientDir = SceneUtils.ServerPos2ClientPos(nty.pos_diff, 10000)
    player.viewObj.LinkComponent:LinkMove(clientDir)
  end
end

function PlayerModule:UnLoadOtherPlayerAvatar(num, UnloadReason)
  if not num or num < 0 then
    num = 0
    return
  end
  local playerTable = {}
  for k, v in pairs(self._playerDic) do
    if k ~= self._localUin then
      table.insert(playerTable, v)
    end
  end
  local otherPlayerNum = #playerTable
  if num >= otherPlayerNum then
    Log.DebugFormat("UnLoadOtherPlayerAvatar return keep number %d > all player number %d", num, #playerTable)
    return
  end
  table.sort(playerTable, function(playerA, playerB)
    local ADistance = playerA:DistanceTo(self.playerModuleData.localPlayer, true, true)
    local BDistance = playerB:DistanceTo(self.playerModuleData.localPlayer, true, true)
    return ADistance < BDistance
  end)
  local unloadNum = otherPlayerNum - num
  for i = 0, unloadNum - 1 do
    local player = playerTable[otherPlayerNum - i]
    if player and player.UnLoadAvatar then
      player:UnLoadAvatar(UnloadReason)
    end
  end
  local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  avatarSystem:ClearSKMPool()
end

function PlayerModule:ReLoadOtherPlayerAvatar(UnloadReason)
  for k, v in pairs(self._playerDic) do
    if k ~= self._localUin then
      v:LoadAvatar(UnloadReason)
    end
  end
end

function PlayerModule:OnInteractionActionResultNotify(notify)
  Log.Debug("PlayerModule:OnInteractionActionResultNotify", notify.pet_or_charge_bag_item_change, notify.avatar_hp_change)
  if notify.pet_or_charge_bag_item_change or notify.avatar_hp_change then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Camp_AUTO_RECOVER)
    if not notify.avatar_hp_change then
      local localPlayer = self:GetLocalPlayer()
      localPlayer:PlayAddRoleHpEffect()
    end
  end
end

function PlayerModule:PlayIdleSkill(nty)
  local actorId = nty.actor_id
  local player = self:OnGetPlayerByServerID(actorId)
  if player and player.statusComponent then
    if not player:CanPlayIdlePerform() then
      Log.Debug("PlayerModule:PlayIdleSkill Can't Play")
      return
    end
    local custom_params = ProtoMessage.newPlayerStatusCustomParams()
    local role_play_param = custom_params.role_play_param
    role_play_param.skill_interact_id = nty.skill_id
    if nty.pet_actor_id then
      role_play_param.skill_type = ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND
      role_play_param.pet_id = nty.pet_base_id
      role_play_param.pet_serverid = nty.pet_actor_id
      role_play_param.mutation_type = nty.mutation_type
      role_play_param.glass_info = nty.glass_info
      role_play_param.nature = nty.nature
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(nty.gid or 0)
      role_play_param.ball_id = PetData and PetData.ball_id or 0
    else
      role_play_param.skill_type = ProtoEnum.RolePlaySkillType.RPST_IDLE_OTHER
    end
    if player.isLocal then
      player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
      player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, 1, custom_params, true)
    else
      player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
      if player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX) then
        player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, custom_params, true)
      end
    end
  end
end

function PlayerModule:OnPetResponseVoice(action, tag, baseData)
  local player = self:OnGetPlayerByServerID(action.actor_id)
  if not player then
    return
  end
  local pet = UE.UObject.IsValid(player.viewObj) and player.viewObj.BP_RideComponent and player.viewObj.BP_RideComponent.ScenePet
  local ride_param = pet and pet.ride_param
  if not ride_param or ride_param.owner_id ~= action.owner_actor_id or ride_param.pet_gid ~= action.pet_gid then
    return
  end
  local responseComponent = pet:EnsureComponent(PetResponseComponent)
  responseComponent:AddPetResponse()
end

function PlayerModule:OnVisibleCircleChanged(notify)
  local localPlayer = self:GetLocalPlayer()
  if localPlayer and localPlayer.serverData then
    local localPlayerUin = localPlayer.serverData.base.logic_id
    if notify.uin == localPlayerUin then
      if notify.enter then
        localPlayer.visibleCircleNum = 1
        if not _G.RocoEnv.IS_SHIPPING then
          local memberStr = ""
          for _, v in ipairs(notify.enter.circle.members) do
            memberStr = memberStr .. string.format("[%d,%s],", v.uin, v.name)
          end
          local info = notify.enter.name .. " Enter circle " .. tostring(notify.enter.circle.circle_id) .. ",member:" .. memberStr
          UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), info, true, true, UE4.FLinearColor(1, 0, 0, 1), 15)
          Log.Debug("PlayerModule OnVisibleCircleChanged", info)
        end
      elseif notify.leave then
        localPlayer.visibleCircleNum = 0
        if not _G.RocoEnv.IS_SHIPPING then
          local memberStr = ""
          if notify.leave.circle and notify.leave.circle.members then
            for _, v in ipairs(notify.leave.circle.members) do
              memberStr = memberStr .. string.format("[%d,%s],", v.uin, v.name)
            end
          end
          local info = notify.leave.name .. " Leave circle " .. tostring(notify.leave.circle.circle_id) .. ",member:" .. memberStr
          UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), info, true, true, UE4.FLinearColor(1, 0, 0, 1), 15)
          Log.Debug("PlayerModule OnVisibleCircleChanged", info)
        end
      end
    else
      Log.Error("PlayerModule OnVisibleCircleChanged notify.uin ~= self._localUin", notify.uin, localPlayerUin)
    end
  end
end

function PlayerModule:OnHomeOwnerStoryFlagChange(notify)
  Log.Debug("PlayerModule:OnHomeOwnerStoryFlagChange")
  _G.DataModelMgr.PlayerDataModel:UpdateHomeOwnerStoryFlags(notify)
end

function PlayerModule:OnCatchRecordInfoChange(action)
  local player = self:GetLocalPlayer()
  local CatchComponent = player and player.CatchRecordComponent
  if CatchComponent then
    CatchComponent:OnRecordInfoChange(action)
  end
end

function PlayerModule:OnAIMutualPerformStateChanged(action)
  local player = self:GetLocalPlayer()
  if player then
    local mutComp = player:EnsureComponent(MutualPerformComponent)
    mutComp:OnStateUpdate(action)
  end
end

function PlayerModule:GetRidePetEyeViewOffset(petId, is2p)
  local offset = self.ridePetEyeViewOffset[petId]
  if not offset then
    local ridePetConfig = DataConfigManager:GetAllRidePet(petId)
    if ridePetConfig then
      if is2p then
        offset = UE.FVector(ridePetConfig.eyes_view_point_offset_2p_x or 0, ridePetConfig.eyes_view_point_offset_2p_y or 0, ridePetConfig.eyes_view_point_offset_2p_z or 0)
      else
        offset = UE.FVector(ridePetConfig.eyes_view_point_offset_x or 0, ridePetConfig.eyes_view_point_offset_y or 0, ridePetConfig.eyes_view_point_offset_z or 0)
      end
    else
      offset = UE.FVector(0)
    end
    self.ridePetEyeViewOffset[petId] = offset
  end
  return offset
end

function PlayerModule:OnAbnormalStatusChange(action)
  local id = action.actor_id
  local statusId = action.status_conf_id
  local player = self._playerDic[id]
  if player and player.AbnormalStatusComponent then
    if 0 == statusId then
      Log.Info("AbnormalStatusComponent RemoveAllStatus", id, statusId, action.start_time_ms)
      player.AbnormalStatusComponent:RemoveAllStatus(false)
    else
      Log.Info("AbnormalStatusComponent ExecuteStatus", id, statusId, action.start_time_ms)
      player.AbnormalStatusComponent:ExecuteStatus(statusId, action.start_time_ms)
    end
  else
    Log.Error("player or AbnormalStatusComponent not found", id, statusId, action.start_time_ms)
  end
end

function PlayerModule:GetRideThrowCameraOffset(petID)
  if not self.rideThrowCameraOffset or not petID then
    return 0, 0, 0
  end
  local offset = self.rideThrowCameraOffset[petID]
  if not offset then
    local v = DataConfigManager:GetAllRidePet(petID)
    local offsetX = v.ride_throw_camera_offset_x
    local offsetY = v.ride_throw_camera_offset_y
    local offsetZ = v.ride_throw_camera_offset_z
    offset = {
      offsetX,
      offsetY,
      offsetZ
    }
    self.rideThrowCameraOffset[v.id] = offset
  end
  return offset[1], offset[2], offset[3]
end

return PlayerModule
