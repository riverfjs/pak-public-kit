local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local BattleSpectatorOutsideRecord = require("NewRoco.Modules.System.BattleSpectator.BattleSpectatorOutsideRecord")
local BattleSpectatorObserveInfo = require("NewRoco.Modules.System.BattleSpectator.BattleSpectatorObserveInfo")
local BattleSpectatorModule = NRCModuleBase:Extend("BattleSpectatorModule")

function BattleSpectatorModule:OnConstruct()
  self.bCanDrawDebug = false
  self.OutsideRefreshScopeRadiusPlayer = self:GetNpcGlobalConfig("online_battle_show_player_npc_refresh_radius", "numList", {300, 150})
  self.OutsideRefreshScopeRadiusEnemy = self:GetNpcGlobalConfig("online_battle_show_enemy_npc_refresh_radius", "numList", {500, 300})
  self.OutsideRefreshScopeAngle = self:GetNpcGlobalConfig("online_battle_show_npc_refresh_angle", "numList", {-30, 30})
  self.OutsideRefreshMaxHeightGap = self:GetNpcGlobalConfig("online_battle_show_height_max_gap", "num", 200)
  self.CachedRecordsLoading = {}
  self.OutsideRecords = {}
  self.ObserveInfos = {}
  self.PreLoadList = {
    EQS_SpectatorOutside = "/Game/NewRoco/Modules/System/BattleSpectator/EQS/EQ_SpectatorOutside.EQ_SpectatorOutside",
    WaterPlatformRef = "/Game/NewRoco/Modules/Core/Battle/BP_WaterPlatform01.BP_WaterPlatform01_C",
    BattlePointRef = "/Game/NewRoco/Modules/System/BattleSpectator/BP_SpectatorBattlePoint.BP_SpectatorBattlePoint_C",
    NpcDisapperSkillRef = "/Game/ArtRes/Effects/G6Skill/SceneEffect/791247.791247_C",
    PetPerformSkillRef = "/Game/ArtRes/Effects/G6Skill/PVE/G6_PVE_3P.G6_PVE_3P_C",
    PerformEndSkillRef = "/Game/ArtRes/Effects/G6Skill/PVE/G6_PVE_3P_CallBack.G6_PVE_3P_CallBack_C",
    NightmareShieldBreakSkillRef = "/Game/ArtRes/Effects/G6Skill/Jineng/BossBattle/NMBoss/G6_NMBoss_SmokeBuff.G6_NMBoss_SmokeBuff_C"
  }
  self.Requests = {}
  self.LoadedAssets = {}
  self.LoadedAssetsRef = {}
end

function BattleSpectatorModule:OnDestruct()
end

function BattleSpectatorModule:OnActive()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NPCModuleEvent.On_NPC_Create, self.OnNpcCreate)
  self:StartLoading()
  local playerList = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  if playerList then
    for _, player in pairs(playerList) do
      self:OnNetPlayerSpawn(player)
    end
  end
end

function BattleSpectatorModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_Create, self.OnNpcCreate)
  self:StopLoading()
end

function BattleSpectatorModule:GetNpcGlobalConfig(key, field, default)
  local value = _G.DataConfigManager:GetNpcGlobalConfig(key, true)
  if value and field then
    local property = value[field]
    if property then
      return property
    end
  end
  return default
end

function BattleSpectatorModule:GetAsset(name)
  if not self.LoadedAssets then
    return nil
  end
  return self.LoadedAssets[name]
end

function BattleSpectatorModule:StartLoading()
  Log.Debug("BattleSpectatorModule:StartLoading")
  self.bIsLoadingAsset = true
  for name, path in pairs(self.PreLoadList) do
    self.Requests[name] = _G.NRCResourceManager:LoadResAsync(self, path, _G.PriorityEnum.Passive_Battle_OutsidePerform, 0, self.OnLoadSuccess, self.OnLoadFailed)
  end
end

function BattleSpectatorModule:StopLoading()
  self.bIsLoadingAsset = false
  if not self.Requests then
    return
  end
  for _, request in pairs(self.Requests) do
    _G.NRCResourceManager:UnLoadRes(request)
  end
  table.clear(self.Requests)
  for _, ref in pairs(self.LoadedAssetsRef) do
    if UE.UObject.IsValid(ref) then
      UnLua.Unref(ref)
    end
  end
  table.clear(self.LoadedAssetsRef)
  table.clear(self.LoadedAssets)
end

function BattleSpectatorModule:OnLoadSuccess(request, res)
  local path = request.assetPath
  local name = table.getKeyName(self.PreLoadList, path)
  Log.Debug("BattleSpectatorModule:OnLoadSuccess", name, path)
  self.LoadedAssets[name] = res
  self.LoadedAssetsRef[name] = res and UnLua.Ref(res)
  self:CheckFinish()
end

function BattleSpectatorModule:OnLoadFailed(request, message)
  local path = request.assetPath
  local name = table.getKeyName(self.PreLoadList, path)
  Log.Debug("BattleSpectatorModule:OnLoadFailed", name, path, message)
  _G.NRCResourceManager:UnLoadRes(request)
  self.Requests[name] = nil
  self:CheckFinish()
end

function BattleSpectatorModule:CheckFinish()
  local totalCount = table.len(self.Requests)
  local currentCount = table.len(self.LoadedAssets)
  if totalCount <= currentCount then
    Log.Debug("BattleSpectatorModule:CheckFinish complete", totalCount)
    self.bIsLoadingAsset = false
    self:CheckCachedNotify()
  else
    Log.Debug("BattleSpectatorModule:CheckFinish loading", totalCount, currentCount)
  end
end

function BattleSpectatorModule:CheckCachedNotify()
  if not self:GetShouldDoPerform() then
    return
  end
  Log.Debug("BattleSpectatorModule:CheckCachedNotify")
  for _, record in pairs(self.CachedRecordsLoading) do
    if record then
      self:BeginSpectatorOutside(record.bSelfInBattle, record.battle_id, record.playerId, record.npcId, record.petA, record.petB, record.otherEnemyPets)
    end
  end
  table.clear(self.CachedRecordsLoading)
end

function BattleSpectatorModule:OnLoadingUIClose()
  Log.Debug("BattleSpectatorModule:OnLoadingUIClose")
  self.bIsLoadingScene = false
  self:CheckCachedNotify()
end

function BattleSpectatorModule:OnLoadingUIOpen()
  Log.Debug("BattleSpectatorModule:OnLoadingUIOpen")
  self.bIsLoadingScene = true
end

function BattleSpectatorModule:GetShouldDoPerform()
  return self.bIsLoadingScene == false and false == self.bIsLoadingAsset
end

function BattleSpectatorModule:OnReconnectFinish()
  Log.Debug("BattleSpectatorModule:OnReconnectFinish")
end

function BattleSpectatorModule:OnNetPlayerSpawn(player)
  if not player then
    return
  end
  if player.isLocal then
    return
  end
  local serverData = player.serverData
  if not serverData then
    return
  end
  local playerId = player:GetServerId()
  self:CreateWatchRecord(playerId, player)
  Log.Debug("BattleSpectatorModule:OnNetPlayerSpawn", playerId, player:GetUin())
  local inner_battle = serverData.inner_battle
  if not inner_battle then
    return
  end
  local action = {
    actor_id = playerId,
    info = inner_battle.info
  }
  self:OnInnerBattleNotify(action)
end

function BattleSpectatorModule:OnNetPlayerDespawn(player)
  if not player then
    return
  end
  if player.isLocal then
    return
  end
  local serverId = player:GetServerId()
  if not serverId then
    return
  end
  self:DestroyWatchRecord(serverId)
  Log.Debug("BattleSpectatorModule:OnNetPlayerDespawn", serverId, player:GetUin())
  self:TryEndSpectatorOutside(serverId, true)
end

function BattleSpectatorModule:CreateWatchRecord(playerId, player)
  if not playerId or not player then
    return
  end
  if self.ObserveInfos[playerId] then
    self:DestroyWatchRecord(playerId)
  end
  local info = BattleSpectatorObserveInfo(playerId, player)
  self.ObserveInfos[playerId] = info
end

function BattleSpectatorModule:DestroyWatchRecord(playerId)
  if not playerId then
    return
  end
  local info = self.ObserveInfos[playerId]
  if info then
    info:OnDestroyed()
    self.ObserveInfos[playerId] = nil
  end
end

function BattleSpectatorModule:OnInnerBattleNotify(action)
  if not action then
    return
  end
  local info = action.info
  if not info then
    return
  end
  local playerId = action.actor_id
  if info.battle_state ~= ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE and 0 == info.world_npc_obj_id then
    Log.Debug("BattleSpectatorModule:OnInnerBattleNotify end battle", playerId, info.battle_state)
    self:TryEndSpectatorOutside(playerId)
    return
  end
  if not info.side_a_pets or not info.side_b_pets then
    return
  end
  if 0 == #info.side_a_pets or 0 == #info.side_b_pets then
    return
  end
  local petA1 = info.side_a_pets[1]
  local petB1 = info.side_b_pets[1]
  local player1 = petA1.owner_obj_id
  local npc1 = petB1.owner_obj_id
  if 0 == npc1 then
    npc1 = info.world_npc_obj_id
  end
  local petA2, player2
  if #info.side_a_pets > 1 then
    petA2 = info.side_a_pets[2]
    if petA2 then
      player2 = petA2.owner_obj_id
    end
  end
  local otherEnemyPets = {}
  if #info.side_b_pets > 1 then
    for idx = 2, #info.side_b_pets do
      local pet = info.side_b_pets[idx]
      if pet then
        table.insert(otherEnemyPets, pet)
      end
    end
  end
  if info.battle_state == ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE then
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local localPlayerId = localPlayer:GetServerId()
    local bSelfIsPlayerA = localPlayerId == player1
    local bSelfIsPlayerB = localPlayerId == player2
    local withFightStatus = localPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) and not localPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_OBSERVING)
    local bSelfInBattle = (bSelfIsPlayerA or bSelfIsPlayerB) and withFightStatus
    if bSelfInBattle then
      Log.Debug("BattleSpectatorModule:OnInnerBattleNotify self also in battle.", localPlayerId, player1, player2, npc1)
    end
    if player1 == playerId then
      Log.Debug("BattleSpectatorModule:OnInnerBattleNotify self 1p", info.world_npc_obj_id, info.battle_state, playerId, player1, player2, localPlayerId)
      self:TryBeginSpectatorOutside(bSelfInBattle, bSelfIsPlayerA, info.bfd_id, player1, npc1, petA1, petB1, otherEnemyPets)
    end
    if player2 and player2 ~= player1 then
      Log.Debug("BattleSpectatorModule:OnInnerBattleNotify 2p only", info.world_npc_obj_id, info.battle_state, playerId, player1, player2, localPlayerId)
      self:TryBeginSpectatorOutside(bSelfInBattle, bSelfIsPlayerB, info.bfd_id, player2, npc1, nil, nil, otherEnemyPets)
    end
  end
end

function BattleSpectatorModule:TryBeginSpectatorOutside(bSelfInBattle, bSelfPlayer, battle_id, playerId, npcId, petA, petB, otherEnemyPets)
  if bSelfPlayer then
    return
  end
  if self:GetShouldDoPerform() then
    self:BeginSpectatorOutside(bSelfInBattle, battle_id, playerId, npcId, petA, petB, otherEnemyPets)
  else
    Log.Debug("BattleSpectatorModule:TryBeginSpectatorOutside add cache", battle_id, playerId, npcId)
    self.CachedRecordsLoading[playerId] = {
      battle_id = battle_id,
      playerId = playerId,
      npcId = npcId,
      petA = petA,
      petB = petB,
      bSelfInBattle = bSelfInBattle,
      otherEnemyPets = otherEnemyPets
    }
  end
end

function BattleSpectatorModule:TryEndSpectatorOutside(playerId, bForceStop)
  if self.CachedRecordsLoading[playerId] then
    Log.Debug("BattleSpectatorModule:TryEndSpectatorOutside remove", playerId)
    self.CachedRecordsLoading[playerId] = nil
  else
    self:EndSpectatorOutside(playerId, bForceStop)
  end
end

function BattleSpectatorModule:BeginSpectatorOutside(bSelfInBattle, battle_id, playerId, npcId, petA, petB, otherEnemyPets)
  Log.Debug("BattleSpectatorModule:BeginSpectatorOutside", playerId, npcId)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, playerId)
  if not player then
    Log.Debug("BattleSpectatorModule:BeginSpectatorOutside player is nil", playerId, npcId)
    return
  end
  local record = self.OutsideRecords[playerId]
  if record then
    if record.battle_id == battle_id then
      Log.Debug("BattleSpectatorModule:BeginSpectatorOutside repeated notify", record:GetDebugInfo())
      record.bSelfInBattle = bSelfInBattle
      record:OnReconnect(petA, petB)
      return
    else
      record:OnDestroyed(true)
    end
  end
  record = BattleSpectatorOutsideRecord(self.OutsideRefreshScopeRadiusPlayer, self.OutsideRefreshScopeRadiusEnemy, self.OutsideRefreshScopeAngle, self.OutsideRefreshMaxHeightGap, battle_id, player, npcId, petA, petB)
  if bSelfInBattle then
    record.bSelfInBattle = true
    Log.Debug("BattleSpectatorModule:BeginSpectatorOutside self in this battle", battle_id, playerId, npcId)
  end
  self.OutsideRecords[playerId] = record
  record:SetOtherEnemyPets(otherEnemyPets)
  record:Begin()
end

function BattleSpectatorModule:EndSpectatorOutside(serverId, bForceStop)
  local record = self.OutsideRecords[serverId]
  if record then
    Log.Debug("BattleSpectatorModule:EndSpectatorOutside", serverId, bForceStop)
    record:OnDestroyed(bForceStop)
    return
  else
    Log.Debug("BattleSpectatorModule:EndSpectatorOutside no record", serverId, bForceStop)
  end
end

function BattleSpectatorModule:GetEQSRunner()
  local World = _G.UE4Helper.GetCurrentWorld()
  local Runner = NewObject(_G.NRCBigWorldPreloader:Get("EQS_Runner"), World)
  if Runner then
    Runner.Query = self:GetAsset("EQS_SpectatorOutside")
  end
  return Runner
end

function BattleSpectatorModule:GetWaterPlatformClass()
  return self:GetAsset("WaterPlatformRef")
end

function BattleSpectatorModule:GetBattlePointClass()
  return self:GetAsset("BattlePointRef")
end

function BattleSpectatorModule:GetNpcDisapperSkillClass()
  return self:GetAsset("NpcDisapperSkillRef")
end

function BattleSpectatorModule:GetPerformSkillClass()
  return self:GetAsset("PetPerformSkillRef")
end

function BattleSpectatorModule:GetPerformEndSkillClass()
  return self:GetAsset("PerformEndSkillRef")
end

function BattleSpectatorModule:GetNightmareShieldBreakSkillClass(name)
  return self:GetAsset("NightmareShieldBreakSkillRef")
end

function BattleSpectatorModule:RemoveRecord(record)
  if not record then
    return
  end
  local player = record.player
  if not player then
    return
  end
  local playerId = player:GetServerId()
  local battleId = record.battle_id
  local currentRecord = self.OutsideRecords[playerId]
  if currentRecord then
    if currentRecord.battle_id == battleId then
      Log.Debug("BattleSpectatorModule:RemoveRecord", playerId, record:GetDebugInfo())
      self.OutsideRecords[playerId] = nil
    else
      Log.Debug("BattleSpectatorModule:RemoveRecord not same battle")
    end
    record = nil
  end
end

function BattleSpectatorModule:OnLeaveBattle()
  Log.Debug("BattleSpectatorModule:OnLeaveBattle")
  for _, record in pairs(self.OutsideRecords) do
    if not record then
    else
      record:OnLeaveBattle()
    end
  end
end

function BattleSpectatorModule:OnNpcCreate(npc)
  if not npc then
    return
  end
  for _, record in pairs(self.OutsideRecords) do
    if record then
      record:CheckOnNpcCreate(npc)
    end
  end
end

function BattleSpectatorModule:OnInnerBattleShieldBroken(action)
  if not action then
    return
  end
  local cachedRecord = self.CachedRecordsLoading[action.actor_id]
  if cachedRecord then
    Log.Debug("BattleSpectatorModule:OnInnerBattleShieldBroken cached", action.actor_id, action.bfd_id, action.battle_conf_id, action.world_npc_obj_id)
    if cachedRecord.battle_id == action.bfd_id then
      cachedRecord.petB = action.pet_info
    end
    return
  end
  local record = self.OutsideRecords[action.actor_id]
  if not record then
    return
  end
  Log.Debug("BattleSpectatorModule:OnInnerBattleShieldBroken", record:GetDebugInfo())
  if record.battle_id == action.bfd_id then
    record:OnNightmareShieldBreak(action.pet_info)
  end
end

function BattleSpectatorModule:OnInnerBattleChangePet(action)
  if not action then
    return
  end
  local cachedRecord = self.CachedRecordsLoading[action.actor_id]
  if cachedRecord then
    Log.Debug("BattleSpectatorModule:OnInnerBattleChangePet cached", action.actor_id, action.bfd_id, action.battle_conf_id, action.world_npc_obj_id)
    if cachedRecord.battle_id == action.bfd_id then
      if action.is_side_b then
        cachedRecord.petB = action.pet_info
      else
        cachedRecord.petA = action.pet_info
      end
    end
    return
  end
  local record = self.OutsideRecords[action.actor_id]
  if not record then
    return
  end
  Log.Debug("BattleSpectatorModule:OnInnerBattleChangePet", record:GetDebugInfo())
  if record.battle_id == action.bfd_id then
    record:SwitchPet(action.pet_info, not action.is_side_b)
  end
end

function BattleSpectatorModule:OnTryKeepWatchNpcIfPlayerLogOut(record)
  if not record then
    return
  end
  local npc = record.npc
  if not npc then
    return
  end
  npc:SetVisibleForBattleOutsideReason(false)
  npc:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnBattledNpcLogicStatusChanged)
  Log.Debug("BattleSpectatorModule:OnTryKeepWatchNpcIfPlayerLogOut", npc:DebugNPCNameAndID())
  if not record.otherEnemyPets then
    return
  end
  for _, otherNpc in pairs(record.otherEnemyPets) do
    if otherNpc then
      Log.Debug("BattleSpectatorModule:OnTryKeepWatchNpcIfPlayerLogOut otherEnemyPets", otherNpc:DebugNPCNameAndID())
      otherNpc:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnBattledNpcLogicStatusChanged)
    end
  end
end

function BattleSpectatorModule:OnBattledNpcLogicStatusChanged(npc, changeInfo)
  if not npc then
    return
  end
  if not changeInfo then
    return
  end
  local changedStatus = changeInfo.changed_status
  if not changedStatus then
    return
  end
  local status = changedStatus.status
  local opType = changeInfo.op_type
  if status ~= ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING then
    return
  end
  if opType ~= ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnBattledNpcLogicStatusChanged)
  npc:SetVisibleForBattleOutsideReason(true)
  Log.Debug("BattleSpectatorModule:OnBattledNpcLogicStatusChanged", npc:DebugNPCNameAndID())
end

function BattleSpectatorModule:GetCanDrawDebug()
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bCanDrawDebug
end

function BattleSpectatorModule:SetCanDrawDebug(bNewState)
  self.bCanDrawDebug = bNewState
end

return BattleSpectatorModule
