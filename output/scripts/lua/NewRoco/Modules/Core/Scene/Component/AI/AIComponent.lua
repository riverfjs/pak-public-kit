local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local AIReactionComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIReactionComponent")
local AttackComponent = require("NewRoco.Modules.Core.Scene.Component.Attack.AttackComponent")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local WorldCombatBuffComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatBuffComponent")
local SocketSnapComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.SocketSnapComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local FarmModuleEvent = require("NewRoco.Modules.System.Farm.FarmModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneAnimEnum = require("NewRoco.Modules.Core.Scene.Common.SceneAnimEnum")
local AIStateSpec = require("NewRoco.AI.State.AIStateSpec")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local Delegate = require("Utils.Delegate")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local AIComponent = Base:Extend("AIComponent")
local DefaultMetaAITreePath = "/Game/NewRoco/Modules/AI/BehaviorTree/MFBT/DotsVersion2/BT_MetaAI"

local function GetSquaredGlobalConf(key, default)
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local conf = _G.DataConfigManager:GetData(confID, key, true)
  if not conf then
    return default or 100
  end
  local num = conf.num
  return num * num
end

local responseMap = {}

local function GetSquaredResponseRange(bulky, default)
  bulky = bulky or 0
  if 0 == bulky then
    bulky = 1
  end
  if responseMap[bulky] then
    return responseMap[bulky]
  end
  responseMap[bulky] = GetSquaredGlobalConf(string.format("bt_response_range_%d", bulky), default or 56250000)
  return responseMap[bulky]
end

local DistOptimizeMarkType = {
  NEAR = 1,
  KEEP = 2,
  FAR = 3
}

function AIComponent:Ctor()
  self.AIController = nil
  self.isControllerCreated = false
  self.isBTLoaded = false
  self.isBTRunning = false
  self.ForceLockAI = 0
  self.lockedForBattleLogicStatusReason = false
  self.lockedForEnableReason = false
  self.lockedForPlayerNotFound = false
  self.ForceLockFlag = 0
  self.DelayLockHandle = {}
  self.isMFBT = true
  self.isServerAI = false
  self.TreePath = nil
  self.isDots = false
  self.performId = 0
  self.groupParam = nil
  self._DebugTreePath = nil
  self.cachedServerPerform = 0
  self.PersistentEnable = false
  self.isHighPriority = false
  self.distOptimizeMark = DistOptimizeMarkType.FAR
  self.squaredResponseRange = 0
  self.battleState = Enum.BattleAIStatus.BAS_NORMAL
  self.controlFlags = Enum.SceneAiControlFlags.SACF_NORMAL
  self.PreAttackTag = Enum.PreAttackBehavior.PAB_NORMAL
  self.PreAttackCount = 0
  self.isIntimate = false
  self.needApplyWorldCombatInfo = false
  self.lastHitBy = nil
  self.markRequestRelease = false
  self.ChargeSkillPath = nil
  self._registered_LogicStatusListener = false
  self._registered_NetPlayerSpawn = false
  self.relativePlayer = {ref = nil}
  MakeWeakTable(self.relativePlayer)
  self.perceivePlayer = false
  self.perceiveTargetState = false
  self.d_perceiveDebounce = nil
  self.perceiveDebounceTime = 0.3
  self.cfg_habitat = 0
  self.cfg_evochain = 0
end

function AIComponent:Attach(owner)
  Base.Attach(self, owner)
  self:RegisterStatusListener()
  local aiInfo = self.owner.serverData.ai_info
  if aiInfo then
    if aiInfo.scene_ai_control_flags then
      self:ApplyControlFlags(aiInfo.scene_ai_control_flags)
    end
    self.battleState = aiInfo.battle_ai_status or Enum.BattleAIStatus.BAS_NORMAL
  end
  self.squaredResponseRange = GetSquaredResponseRange(self.owner:GetBulkyLevel())
  if owner.TempDisAI then
    Log.Warning("[AIComponent] \230\163\128\230\181\139\229\136\176 SceneNpc.TempDisAI == true\239\188\140\229\183\178\231\166\129\231\148\168AI\231\187\132\228\187\182", owner.config.name, owner:GetServerId())
    return
  end
  if not owner.config then
    Log.Error("[AIComponent] Unknown npc config", owner:GetServerId())
    return
  end
  self.isMFBT = true
  self:PrepConf()
  self:UpdateDataFromConfig()
  self.owner:AddEventListener(self, NPCModuleEvent.BE_ATTACKED, self.OnBeAttacked)
  self.owner:AddEventListener(self, NPCModuleEvent.BE_HIT_BY_STAR, self.OnBeHitByStar)
  self.owner:AddEventListener(self, NPCModuleEvent.BE_COLLIDE_WHILE_ATTACK, self.OnBeCollide)
  self.owner:AddEventListener(self, NPCModuleEvent.BE_PEO_OVERLAP, self.OnBePeoOverlap)
  if owner.viewObj and owner.viewObj.resourceLoaded then
    self:OnResourceLoaded()
  end
  self.state_specs = {}
end

function AIComponent:UpdateData(ServerData, isReconnect)
  if isReconnect and self.markRequestRelease then
    Log.PrintScreenMsg("AIComponent:UpdateData \233\135\141\232\191\158\239\188\140\228\189\134\230\152\175\232\135\170\232\186\171\229\186\148\229\189\147\232\162\171\231\167\187\233\153\164 %s %d", self.owner.config.name, self.owner:GetServerId())
    self.owner:RequestRelease(2)
    return
  end
  if ServerData.attrs then
    self:OnHpUpdated(ServerData.attrs.hp, ServerData.attrs.hp_max)
  end
  local aiInfo = ServerData.ai_info
  if aiInfo and isReconnect and self.owner.viewObj and self.owner.viewObj.resourceLoaded then
    self:UpdateViewState(ServerData)
  end
  local newIsServerAI = ServerData.npc_base.is_server_ai or false
  local newPerformOverride = ServerData.ai_info and ServerData.ai_info.ai_override_perform_group_id or 0
  if newPerformOverride ~= self.cachedServerPerform or newIsServerAI ~= self.isServerAI then
    self:UpdateDataFromConfig()
    self:RescheduleGenre()
  end
  if newIsServerAI and aiInfo then
    self:ApplyControlFlags(aiInfo.scene_ai_control_flags)
    self.battleState = aiInfo.battle_ai_status
  end
  self:OnLogicStatusUpdated(isReconnect)
end

function AIComponent:UpdateViewState(ServerData)
  ServerData = ServerData or self.owner.serverData
  local isServerAI = ServerData.npc_base.is_server_ai or false
  if isServerAI then
    self.owner:SetCollisionDisable(ServerData.ai_info.collision_cancel, NPCModuleEnum.NpcReasonFlags.AI)
    local lookAtTarget = SceneUtils.GetActorByServerId(ServerData.ai_info.look_at_target_id)
    self.owner:SetHeadLookAtActor(lookAtTarget and lookAtTarget.viewObj, true)
    if not self:UpdateMovementModeAlter(ServerData.ai_info.move_mode) and ServerData.ai_info.move_mode then
      self.owner:SetMovementMode(ServerData.ai_info.move_mode.move_mode, ServerData.ai_info.move_mode.move_sub_mode)
    end
    local ai_info = ServerData.ai_info
    if ai_info then
      local looping_anim_id = ai_info.anim_id or 0
      local looping_anim = SceneAnimEnum.AnimationNameRev[looping_anim_id]
      if looping_anim then
        Log.Debug("ServerAI \230\129\162\229\164\141\229\138\168\231\148\187", looping_anim, "ai_info.anim_is_loop=", ai_info.anim_is_loop, self.owner.config.name)
        local play_rate = ai_info.anim_rate or 1
        if ai_info.anim_is_loop then
          self.owner:PlayAnim(looping_anim, play_rate, 0, 0, 0.2, -1)
        else
          self.owner:PlayAnim(looping_anim, play_rate, 0, 0, -1, 1)
        end
      end
      local vo_rot = ai_info.velocity_oriented_rotation
      if ai_info.is_velocity_oriented_rotation and vo_rot then
        UE.URocoAIHelper.UpdateVelocityOrientRotation(self.owner.viewObj, true, vo_rot.x, vo_rot.y, vo_rot.z)
      else
        UE.URocoAIHelper.UpdateVelocityOrientRotation(self.owner.viewObj, false, 0, 0, 0)
      end
    end
    local perceivePlayer = false
    if ai_info.perceive_player_obj_ids and #ai_info.perceive_player_obj_ids > 0 then
      local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      local localPlayerId = localPlayer and localPlayer:GetServerId() or 0
      for _, v in ipairs(ai_info.perceive_player_obj_ids) do
        if v == localPlayerId then
          perceivePlayer = true
          break
        end
      end
    end
    self:PerceiveLocalPlayer(perceivePlayer)
  end
end

local HOME_MAP_ID = 301

function AIComponent.IsCurrentInHome()
  return SceneUtils.GetSceneID() == HOME_MAP_ID
end

function AIComponent.IsCurrentInFarm()
  return SceneUtils.GetSceneID() == HOME_MAP_ID and (not _G.HomeIndoorSandbox or not _G.HomeIndoorSandbox:InHomeIndoor()) and true
end

function AIComponent:PrepConf()
  local npc_base = self.owner.serverData.npc_base
  local server_habitat_id = npc_base and npc_base.habitat_id
  if server_habitat_id then
    self.cfg_habitat = server_habitat_id
  else
    local contentConf = self.owner.contentConf
    self.cfg_habitat = contentConf and contentConf.pet_habitat_group or 0
  end
  local petbaseConf = self.owner:GetConfPetData()
  if petbaseConf then
    local evoConf = _G.DataConfigManager:GetPetEvolutionConf(petbaseConf.pet_evolution_id[1] or 0, true)
    if evoConf then
      self.cfg_evochain = evoConf.pvp_mute_group
    end
  end
end

function AIComponent:UpdateDataFromConfig()
  local _serverData = self.owner.serverData
  local IsServerAI = _serverData.npc_base.is_server_ai or false
  if not IsServerAI then
    self:InitPlayerOwner()
  end
  local bAIConfigValid = false
  local bGroupConfigValid = false
  local RESULT_btree
  local RESULT_perform = 0
  local RESULT_group
  local _aiInfo = _serverData.ai_info
  local Server_perform = _aiInfo and _aiInfo.ai_override_perform_group_id or 0
  self.cachedServerPerform = Server_perform
  if 0 ~= Server_perform then
    RESULT_btree = nil
    RESULT_perform = Server_perform
    bAIConfigValid = true
  end
  if not bAIConfigValid then
    local mutType = _serverData.npc_base.mutation_type
    if mutType and PetMutationUtils.GetMutationValue(mutType, _G.Enum.MutationDiffType.MDT_SHINING) then
      local mutPerformId = self.owner.config.shining_ai_conf
      if mutPerformId and mutPerformId > 0 then
        RESULT_btree = nil
        RESULT_perform = mutPerformId
        bAIConfigValid = true
      end
    end
  end
  if not bAIConfigValid then
    local sanctuary_id = _serverData.npc_base and _serverData.npc_base.owl_sanctuary_content_cfg_id
    if sanctuary_id and sanctuary_id > 0 then
      local sanctuary_conf = _G.DataConfigManager:GetOwlSanctuaryConf(sanctuary_id, true)
      if sanctuary_conf and sanctuary_conf.cave_ban_fly_ai_perform_group and 0 ~= sanctuary_conf.cave_ban_fly_ai_perform_group then
        local petbaseConf = self.owner:GetConfPetData()
        if petbaseConf and petbaseConf.model_conf then
          local modelConf = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf, true)
          if modelConf and (modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_FLY or modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_FLY_WATER) then
            RESULT_btree = nil
            RESULT_perform = sanctuary_conf.cave_ban_fly_ai_perform_group
            bAIConfigValid = true
          end
        end
      end
    end
  end
  local RefreshContentConfig = _G.DataConfigManager:GetNpcRefreshContentConf(_serverData.npc_base.npc_content_cfg_id, true)
  if RefreshContentConfig then
    if not bAIConfigValid then
      local conf_btree = RefreshContentConfig.mf_behavior_tree
      if not string.IsNilOrEmpty(conf_btree) then
        RESULT_btree = conf_btree
        RESULT_perform = 0
        bAIConfigValid = true
      else
        local conf_perform = RefreshContentConfig.ai_perform_group
        if conf_perform and 0 ~= conf_perform then
          RESULT_btree = nil
          RESULT_perform = conf_perform
          bAIConfigValid = true
        end
      end
    end
    if not bGroupConfigValid then
      local conf_group = RefreshContentConfig.ai_group_param
      if conf_group and #conf_group > 0 then
        RESULT_group = conf_group
        bGroupConfigValid = true
      end
    end
  end
  if bAIConfigValid and bGroupConfigValid then
    self.groupParam = RESULT_group
    self:UpdateInfoInternal(IsServerAI, RESULT_perform, RESULT_btree)
    return
  end
  local NpcConf = self.owner.config
  if NpcConf.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_FOLLOW and self.IsCurrentInHome() then
    local PetbaseConfig = self.owner:GetConfPetData()
    if PetbaseConfig and PetbaseConfig.home_npc_id then
      local HomeNpcConfig = _G.DataConfigManager:GetNpcConf(PetbaseConfig.home_npc_id, true)
      local conf_tree, conf_perform, conf_group = self:GetDatasFromNpcConfig(HomeNpcConfig, _serverData, false)
      if not bAIConfigValid and (conf_tree or conf_perform) then
        RESULT_btree = conf_tree
        RESULT_perform = conf_perform or 0
        bAIConfigValid = true
      end
      if not bGroupConfigValid and conf_group then
        RESULT_group = conf_group
        bGroupConfigValid = true
      end
      if bAIConfigValid and bGroupConfigValid then
        self.groupParam = RESULT_group
        self:UpdateInfoInternal(IsServerAI, RESULT_perform, RESULT_btree)
        return
      end
    end
  end
  local conf_tree, conf_perform, conf_group = self:GetDatasFromNpcConfig(NpcConf, _serverData, true)
  if not bAIConfigValid and (conf_tree or conf_perform) then
    RESULT_btree = conf_tree
    RESULT_perform = conf_perform or 0
    bAIConfigValid = true
  end
  if not bGroupConfigValid and conf_group then
    RESULT_group = conf_group
  end
  if not bAIConfigValid then
    local PetbaseConfig = self.owner:GetConfPetData()
    if PetbaseConfig then
      RESULT_perform = PetbaseConfig.ai_group_info_id or 0
    end
  end
  self.groupParam = RESULT_group
  self:UpdateInfoInternal(IsServerAI, RESULT_perform, RESULT_btree)
end

function AIComponent:GetDatasFromNpcConfig(npcConf, serverData, usePoolGroup)
  local btree, perform, group
  local poolConfId = npcConf.ai_random_pool_id
  if poolConfId then
    local poolConf = _G.DataConfigManager:GetNrcAiPerformPoolConf(poolConfId, true)
    if poolConf and #poolConf.pool_number > 0 then
      local selectedPoolConfIdx
      if poolConf.ai_rand_method == Enum.AiPoolRandomMethod.APRM_FIXED_INITIAL_VALUES and serverData.base.born_time then
        local born_time = serverData.base.born_time * 1000 - SceneAIUtils.DEBUG_BORN_TIME_OFFSET_SEC
        local period = math.floor(poolConf.param1 * 3600000)
        local current_time = _G.ZoneServer:GetServerTime()
        if current_time >= born_time + period then
          local actor_id = serverData.base.actor_id
          local r = _G.SceneAIUtils.DetermineRandInPeriod(math.max(period, 1), born_time, actor_id)
          selectedPoolConfIdx = poolConf.pool_number[math.ceil(r * #poolConf.pool_number)]
        end
      end
      if selectedPoolConfIdx then
        local selectedPoolPerform = poolConf[string.format("ai_perform_group_%d", selectedPoolConfIdx)]
        if selectedPoolPerform and 0 ~= selectedPoolPerform then
          perform = selectedPoolPerform
        end
        if usePoolGroup then
          local selectedPoolGroup = poolConf[string.format("ai_group_param_%d", selectedPoolConfIdx)]
          if selectedPoolGroup and #selectedPoolGroup > 0 then
            group = selectedPoolGroup
          end
        end
        Log.DebugFormat("[AIComponent] \233\135\135\230\160\183\229\136\176\233\154\143\230\156\186\230\177\160\233\133\141\231\189\174  npc_cfg:%d pool_cfg:%d idx:%d use_group:%s", npcConf.id, poolConfId, selectedPoolConfIdx, usePoolGroup and "true" or "false")
      end
    end
  end
  if not perform then
    local conf_tree = npcConf.mf_behavior_tree
    if not string.IsNilOrEmpty(conf_tree) then
      btree = conf_tree
    else
      local conf_perform = npcConf.ai_perform_group
      if conf_perform and 0 ~= conf_perform then
        perform = conf_perform
      end
    end
  end
  if not group then
    local conf_group = npcConf.ai_group_param
    if conf_group and #conf_group > 0 then
      group = conf_group
    end
  end
  if perform and 0 == perform or btree and "" == btree or group and 0 == #group then
    Log.Error("[AIComponent] assert failed: data not valid", perform, btree, group)
    return nil, nil, nil
  end
  return btree, perform, group
end

function AIComponent:SwitchToServerAI()
  self:UpdateInfoInternal(true, self.performId, self.TreePath)
end

function AIComponent:GetSyncSeq()
  if self.isServerAI then
    local svrComp = self:GetServerAIComponent()
    return svrComp and svrComp.seq_id or 0
  end
  return 0
end

function AIComponent:DebugOverrideAIInfo(info)
  if nil == info or "" == info then
    self:UpdateInfoInternal(true, 0, "")
    return
  end
  if type(info) == "string" then
    self:UpdateInfoInternal(false, 0, info)
    return
  end
  if type(info) == "number" then
    self:UpdateInfoInternal(false, info, "")
    return
  end
  Log.Error("[AIComponent:DebugOverrideAIInfo] invalid param. should be one of nil, number, string. current=", info)
end

function AIComponent:UpdateInfoInternal(IsServerAI, DotsPerformId, TreePath)
  local NeedRestart = false
  local bServerModeChanged = self.isServerAI ~= IsServerAI
  if bServerModeChanged then
    local NpcModule = self.owner.module
    NpcModule.ServerAICount = NpcModule.ServerAICount + (IsServerAI and 1 or -1)
    self:ClearContextData()
  end
  NeedRestart = NeedRestart or bServerModeChanged
  NeedRestart = NeedRestart or self.performId ~= DotsPerformId
  NeedRestart = NeedRestart or 0 == DotsPerformId and self.TreePath ~= TreePath
  self.isServerAI = IsServerAI
  self.performId = DotsPerformId
  self.isDots = 0 ~= DotsPerformId
  if self.isDots then
    self.TreePath = DefaultMetaAITreePath
  else
    self.TreePath = TreePath
    self.owner._battleHardCheck = true
  end
  if NeedRestart then
    self:RestartAI()
  end
  if self.isServerAI then
    self:GetServerAIComponent()
  elseif bServerModeChanged then
    local SvrAIComp = self:GetServerAIComponentRaw()
    if SvrAIComp then
      SvrAIComp.recording_move = false
    end
  end
end

function AIComponent:ClearContextData()
  self.controlFlags = 0
  self.battleState = 0
  if self.owner then
    local HudComp = self.owner.PetHUDComponent
    if HudComp then
      HudComp:SetMainHudPerception(0, true)
    end
    local moveComp = self:GetMoveComponent()
    if moveComp and moveComp:IsA(UE.UCharacterNavMovementComponent) then
      moveComp.ServerMoveSpeedExtra = 0
    end
    local SnapComp = self.owner.SocketSnapComponent
    if SnapComp and SnapComp.CancelSnap then
      SnapComp:CancelSnap()
    end
    if self.owner:IsAThrownPet() then
      local HiddenComp = self.owner.HiddenComponent
      if HiddenComp and HiddenComp:CanHide() and HiddenComp:IsHidden() then
        HiddenComp:EndHide()
      end
    end
  end
  if self.isControllerCreated and UE.UObject.IsValid(self.AIController) then
    local FlowComp = self.AIController.MultiposFlowComponent
    if FlowComp then
      FlowComp:AbortFollowing()
    end
  end
end

function AIComponent:DeAttach()
  for _, state_spec in pairs(self.state_specs) do
    state_spec:OnStateRemoved(AIStateSpec.RemoveReason.Finalize)
  end
  table.clear(self.state_specs)
  self:UnregisterNetPlayerSpawnEvent()
  self:UnRegisterStatusListener()
  self:SetFarmEventEnabled(false)
  self.owner:RemoveEventListener(self, NPCModuleEvent.BE_ATTACKED, self.OnBeAttacked)
  self.owner:RemoveEventListener(self, NPCModuleEvent.BE_HIT_BY_STAR, self.OnBeHitByStar)
  self.owner:RemoveEventListener(self, NPCModuleEvent.BE_COLLIDE_WHILE_ATTACK, self.OnBeCollide)
  self:DestroyController()
  if self.isServerAI then
    local NpcModule = self.owner.module
    NpcModule.ServerAICount = NpcModule.ServerAICount - 1
  end
  self:ClearHomePositionFix()
  self:ClearDelayLockForReasonAll()
  self:ClearPerceivePlayerState()
end

function AIComponent:OnEnable()
  if self.lockedForEnableReason then
    self:ForceLock(false)
    self.lockedForEnableReason = false
  end
end

function AIComponent:OnDisable()
  if not self.lockedForEnableReason then
    self:ForceLock(true)
    self.lockedForEnableReason = true
  end
end

function AIComponent:OnResourceLoaded()
  self:RescheduleGenre()
  if self.owner.serverData.ai_info then
    self:UpdateViewState()
  end
  if AIComponent.IsCurrentInHome() then
    self:InjectHomePositionFix()
  end
  self:InitPhysicsIfCanSwim()
end

local HALLWAY_MUTEX = 1
local HALLWAY_SPAWN_PT

local function GetHallwaySpawnPoint()
  if not HALLWAY_SPAWN_PT then
    local conf = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_init_hallway_pos", true)
    if conf then
      HALLWAY_SPAWN_PT = UE.FVector(conf.numList[1], conf.numList[2], conf.numList[3])
    else
      HALLWAY_SPAWN_PT = FVectorZero
    end
  end
  return HALLWAY_SPAWN_PT
end

function AIComponent:InjectHomePositionFix()
  if not _G.HomeIndoorSandbox or not _G.HomeIndoorSandbox:InHomeIndoor() then
    local bHasStatus, variant, extra_data = self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD)
    if bHasStatus then
      self:InjectFarmPositionFix(extra_data)
    end
    return
  end
  local npc = self.owner
  local view = npc.viewObj
  if view and view.SetIKEnable then
    view:SetIKEnable(false)
  end
  if not self.owner:IsHomeNpc() then
    return
  end
  local holdEgg = npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_HOLD_EGG)
  if not holdEgg and _G.SceneAIUtils.bHomeInitBehCheckEnterSceneTime and self.owner.serverData.base.enter_scene_times <= 1 then
    return
  end
  local nest_guid = npc.serverData.home_pet.home_pet_info.furniture_guid
  local nest_data = _G.HomeIndoorSandbox.Utils.GetPropDataById(nest_guid)
  if not nest_data then
    return
  end
  local ground_plane = nest_data.RealtimePlane
  if not ground_plane then
    local located_room = _G.HomeIndoorSandbox.World:GetRoomById(nest_data.RoomId)
    if not located_room then
      return
    end
    ground_plane = located_room:GetPlaneByActorId(nest_data.PlaneMasterId)
  end
  if not ground_plane then
    return
  end
  if not ground_plane.QueryRandomReachableCell then
    return
  end
  local beh_type = _G.SceneAIUtils.DetermineHomeInitiativeBehavior(self.owner:GetServerId())
  Log.PrintScreenMsg("[AIC] \229\174\182\229\155\173\233\154\143\230\156\186\229\136\157\229\167\139\229\140\150 for %s beh_type=%d", npc.config.name, beh_type)
  if 1 == beh_type then
    local pt = ground_plane:QueryPropsEdgeValidCell(nest_data)
    if pt then
      local hh = npc:GetScaledHalfHeight()
      local land_pt = SceneUtils.GetPosInLand(pt, hh + 0.1, hh * 2, hh * 10)
      if land_pt then
        npc:SetActorLocation(land_pt)
      else
      end
    end
  elseif 2 == beh_type then
    local pt = ground_plane:QueryRandomReachableCell(nest_data, 100, 200)
    local hh = npc:GetScaledHalfHeight()
    local land_pt = SceneUtils.GetPosInLand(pt, hh + 0.1, hh * 2, hh * 10)
    if land_pt then
      npc:SetActorLocation(land_pt)
    else
    end
  elseif 3 == beh_type then
    if HALLWAY_MUTEX > 0 then
      local pt = GetHallwaySpawnPoint()
      local hh = npc:GetScaledHalfHeight()
      local land_pt = SceneUtils.GetPosInLand(pt, hh + 0.1, hh * 2, hh * 10)
      if land_pt then
        npc:SetActorLocation(land_pt)
      else
      end
      HALLWAY_MUTEX = HALLWAY_MUTEX - 1
      self._use_hallway_mutex = true
    else
      local pt = ground_plane:QueryRandomReachableCell(nest_data, 100, 200)
      local hh = npc:GetScaledHalfHeight()
      local land_pt = SceneUtils.GetPosInLand(pt, hh, hh * 2, hh * 10)
      if land_pt then
        npc:SetActorLocation(land_pt)
      else
      end
    end
  end
end

function AIComponent:ClearHomePositionFix()
  if self._use_hallway_mutex then
    self._use_hallway_mutex = false
    HALLWAY_MUTEX = HALLWAY_MUTEX + 1
  end
end

local plant_guard_pet_random_point, home_plant_steal_attack_low, home_plant_steal_attack_middle, home_plant_steal_attack_high

local function InitHomeAIGuardConfig()
  if nil ~= plant_guard_pet_random_point then
    return
  end
  local data_plant_guard_pet_random_point = DataConfigManager:GetHomeGlobalConfig("plant_guard_pet_random_point")
  plant_guard_pet_random_point = data_plant_guard_pet_random_point and data_plant_guard_pet_random_point.num or 73010029
  local data_home_plant_steal_attack_low = DataConfigManager:GetHomeGlobalConfig("home_plant_steal_attack_low")
  home_plant_steal_attack_low = data_home_plant_steal_attack_low and data_home_plant_steal_attack_low.num or 9000
  local data_home_plant_steal_attack_middle = DataConfigManager:GetHomeGlobalConfig("home_plant_steal_attack_middle")
  home_plant_steal_attack_middle = data_home_plant_steal_attack_middle and data_home_plant_steal_attack_middle.num or 9000
  local data_home_plant_steal_attack_high = DataConfigManager:GetHomeGlobalConfig("home_plant_steal_attack_high")
  home_plant_steal_attack_high = data_home_plant_steal_attack_high and data_home_plant_steal_attack_high.num or 9000
end

function AIComponent:InjectFarmPositionFix(GuardStatusData)
  if _G.SceneAIUtils.bHomeInitBehCheckEnterSceneTime then
    local currentTime = ZoneServer:GetServerTime()
    local justSpawnTime = GuardStatusData and GuardStatusData.last_update_time * 1000 or 0
    if currentTime - justSpawnTime < 5000 then
      Log.DebugFormat("[AIC] InjectFarmPositionFix: just spawn, skip position fix. spawn_time=%d, curent_time=%d", justSpawnTime, currentTime)
      return
    end
  end
  InitHomeAIGuardConfig()
  local viewObj = self.owner.viewObj
  if viewObj and UE.UObject.IsValid(viewObj) then
    local randPointSet = _G.DataConfigManager:GetAreaConf(plant_guard_pet_random_point)
    if randPointSet and #randPointSet.pos > 0 then
      local AreaConf = randPointSet.pos[math.random(1, #randPointSet.pos)]
      local LocationData = AreaConf.position_xyz
      local RotationData = AreaConf.rotation_xyz
      local Location = UE4.FVector(LocationData[1], LocationData[2], LocationData[3])
      local Rotation = UE4.FRotator(RotationData[1], RotationData[2], RotationData[3])
      Location = SceneUtils.GetPosInLand(Location, self.owner:GetScaledHalfHeight(), 500) or Location
      viewObj:Abs_K2_SetActorLocationAndRotation_WithoutHit(Location, Rotation, false, false)
    end
  end
end

function AIComponent:TrySendGuardEvent()
  if not self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD) then
    return
  end
  InitHomeAIGuardConfig()
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player and FarmUtils.IsLocalPlayerStealExpelled(Player) then
    self:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_HOME_PLANT_VISTOR_PICK, 2, Player:GetActorLocationFrameCache())
    self.AIController:SetDotsCommonBool("Global_bLocalPlayerStealExpelled", true)
  end
  self.AIController:SetDotsCommonFloat("Global_fHomePlantStealAttackLow", home_plant_steal_attack_low / 100.0)
  self.AIController:SetDotsCommonFloat("Global_fHomePlantStealAttackMiddle", home_plant_steal_attack_middle / 100.0)
  self.AIController:SetDotsCommonFloat("Global_fHomePlantStealAttackHigh", home_plant_steal_attack_high / 100.0)
end

function AIComponent:TrySendFarmerEvent()
  local enableFarm = false
  if FarmUtils.IsCurrentHomeOwner() then
    enableFarm = self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD)
  end
  if not enableFarm and self.owner:IsAThrownPet() then
    local OwnerPlayerId = self.owner.serverData and self.owner.serverData.base.owner_id or 0
    local ownerPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, OwnerPlayerId)
    if ownerPlayer and ownerPlayer.isLocal then
      enableFarm = true
    end
  end
  if enableFarm then
    rawset(self, "IsUnitType_Water", self.owner:ContainsUnitType(Enum.SkillDamType.SDT_WATER))
    rawset(self, "IsUnitType_Grass", self.owner:ContainsUnitType(Enum.SkillDamType.SDT_GRASS))
    self:SetFarmEventEnabled(true)
    self:CollectInteractableFarms()
  end
end

function AIComponent:CollectInteractableFarms(InUnits)
  if not self:IsActive() then
    return
  end
  local Units = InUnits or _G.NRCModuleManager:DoCmd(_G.FarmModuleCmd.OnCollectAllLandOptionStatus)
  local canInteractFarmNum = Units and Units[FarmModuleEnum.OptionType.Harvesting] or 0
  if self.IsUnitType_Water then
    canInteractFarmNum = canInteractFarmNum + (Units and Units[FarmModuleEnum.OptionType.Watering] or 0)
  end
  if self.IsUnitType_Grass then
    canInteractFarmNum = canInteractFarmNum + (Units and Units[FarmModuleEnum.OptionType.Fertilizing] or 0)
  end
  self.AIController:SetDotsCommonInt("Global_iCanInteractFarmNum", canInteractFarmNum)
  self.AIController:RequestTickInputBlackboard()
  if canInteractFarmNum > 0 then
    Log.DebugFormat("AIComponent:TrySendFarmerEvent, \229\185\178\230\180\187\228\186\134: %s, count=%d", self.owner.config.name, canInteractFarmNum)
  end
end

function AIComponent:SetFarmEventEnabled(enable)
  if (enable or false) == self._farm_event_enable then
    return
  end
  if enable then
    _G.NRCEventCenter:RegisterEvent("AIComponent", self, FarmModuleEvent.OnUpdateLandOptionStatus, self.CollectInteractableFarms)
  else
    _G.NRCEventCenter:UnRegisterEvent(self, FarmModuleEvent.OnFarmLandInfoChanged, self.CollectInteractableFarms)
  end
end

function AIComponent:InitPhysicsIfCanSwim()
  local freeze = self.owner.config.freeze_movement_when_spawn or false
  if freeze then
    return
  end
  if self.owner.config.genre ~= Enum.ClientNpcType.CNT_NPC then
    return
  end
  if self.owner:IsAThrownPet() then
    return
  end
  if self.owner.modelConf.habitat_flag ~= Enum.HABITAT_FLAG.HAB_WATER then
    return
  end
  local moveComp = self:InitMovementComponent(true)
  if moveComp then
    moveComp.bRunPhysicsWithNoController = true
    moveComp:SetMovementMode(UE.EMovementMode.MOVE_Falling)
  end
end

function AIComponent:RescheduleGenre()
  local selfConf = self.owner.config
  local genre = selfConf.genre or 0
  self.isHighPriority = genre == Enum.ClientNpcType.CNT_PETBOSS or genre == Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM or (selfConf.is_ai_loading_high_priority or 0) > 0 or self.owner:IsAThrownPet() or self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD)
  if self.isHighPriority then
    self.owner:ScheduleNextTick(0.0)
  end
end

function AIComponent:RestartAI()
  self:StopMfbt()
  self.distOptimizeMark = DistOptimizeMarkType.FAR
end

function AIComponent:GetPerceptionLevel()
  if self.isControllerCreated then
    return self.AIController:GetPerceptionLevel()
  end
  return false
end

function AIComponent:IsResistCapture()
  if self:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_CAPTURE) then
    return true
  end
  return false
end

function AIComponent:SetDotsData(data)
  if self.isDots and self.isBTLoaded then
    self.AIController:SetComponentData(data)
    return
  else
  end
end

function AIComponent:GetDotsData()
  if self.isDots and self.isBTLoaded then
    return self.AIController:GetComponentData()
  end
  return nil
end

function AIComponent:CreateController()
  local view = self.owner.viewObj
  if not view or self.owner.isDestroy then
    return
  end
  if string.IsNilOrEmpty(self.TreePath) and not self.isServerAI then
    return
  end
  if view.ConfigureInitStatus then
    view:ConfigureInitStatus()
  end
  local freeze = self.owner.config.freeze_movement_when_spawn or false
  if UE.UObject.IsA(view, UE.ANPCBaseCharacter) then
    view.bSkipSetDefaultMovementMode = freeze
  end
  if view.AIControllerClass then
    view.AIControllerClass = UE.AMetaAIController
  end
  local isHomePet = self.owner.config.genre == Enum.ClientNpcType.CNT_HOME_NPC
  if isHomePet or self.owner:IsAThrownPet() then
    self.owner:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.AI)
  end
  local moveComp = self:GetMoveComponent()
  if moveComp and moveComp:IsA(UE.UCharacterNavMovementComponent) then
    moveComp.ServerGravity = 0
  end
  view:SpawnDefaultController()
  local Controller = view.Controller
  if Controller then
    self.AIController = Controller
    self.AIController.Npc = self.owner
    Log.DebugFunc(function()
      return string.format("[AIC] Created for %d|%d: mfbt=%s, dots=%s, svr=%s", self.owner:GetServerId(), self.owner.config.id, tostring(self.isMFBT), tostring(self.isDots), tostring(self.isServerAI))
    end)
  else
    return Log.ErrorFormat("[AIC] Cant Create AIC for %d", self.owner:GetServerId())
  end
  if not freeze then
    local moveComp = self:InitMovementComponent()
    if moveComp then
      moveComp.bRunPhysicsWithNoController = false
    end
  end
  self.isControllerCreated = true
  self:OnControllerCreated()
end

function AIComponent:GetMoveComponent()
  local char = self.owner.viewObj
  if char and UE.UObject.IsValid(char) then
    return char.GetMovementComponent and char:GetMovementComponent()
  end
  return nil
end

function AIComponent:InitMovementComponent(forceTickEnable)
  local moveComp = self:GetMoveComponent()
  if moveComp then
    moveComp:SetActive(true, true)
    if forceTickEnable then
      moveComp:SetComponentTickEnabled(true)
    elseif self:IsLocked() then
      moveComp:SetComponentTickEnabled(false)
    end
  end
  return moveComp
end

function AIComponent:UpdateMovementModeAlter(move_mode)
  if not self.isControllerCreated then
    return false
  end
  if not UE.UObject.IsValid(self.AIController) then
    return false
  end
  if not move_mode then
    local server_data = self.owner.serverData
    move_mode = server_data and server_data.ai_info and server_data.ai_info.move_mode
  end
  if not move_mode then
    return false
  end
  local FlowComp = self.AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
  local moveComp = self:GetMoveComponent()
  if moveComp and moveComp:IsA(UE.UCharacterNavMovementComponent) then
    local current_movement_state = moveComp.MovementMode
    if 1 == move_mode.move_mode or 3 == move_mode.move_mode then
      local NeedFalling = current_movement_state == UE.EMovementMode.MOVE_Flying or current_movement_state == UE.EMovementMode.MOVE_Custom and moveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Hovering
      if NeedFalling then
        move_mode.move_mode = 3
      end
    end
    moveComp.ServerGravity = server_data and server_data.ai_info and server_data.ai_info.move_mode and server_data.ai_info.move_mode.gravity or 0
  end
  if FlowComp then
    FlowComp:SetMoveMode(move_mode.move_mode or 0, move_mode.move_sub_mode or 0, move_mode.height or 0, move_mode.height_lerp_rate or 0)
    return true
  end
  return false
end

function AIComponent:DestroyController()
  if self.isControllerCreated then
    local view = self.owner.viewObj
    if view and UE.UObject.IsValid(view) then
      view:DetachFromControllerPendingDestroy()
      self.AIController.Npc = nil
      if self.AIController.mfbtLuaComponent then
        self.AIController.mfbtLuaComponent:ClearStatus()
      end
    elseif UE.UObject.IsValid(self.AIController) then
      self.AIController:UnPossess()
      self.AIController:K2_DestroyActor()
    end
    self.isBTRunning = false
    self.isBTLoaded = false
    self.AIController = nil
    self.isControllerCreated = false
    self:OnControllerDestroy()
  end
end

function AIComponent:OnControllerCreated()
  local ServerAIComp = self:GetServerAIComponentRaw()
  if ServerAIComp then
    ServerAIComp:OnControllerCreated()
  end
end

function AIComponent:OnControllerDestroy()
  local ServerAIComp = self:GetServerAIComponentRaw()
  if ServerAIComp then
    ServerAIComp:OnControllerDestroy()
  end
end

AIComponent.MaxLoadSemaphore = 2
AIComponent.LoadSemaphore = 0

function AIComponent:OnDistanceOptimize(sqrDistanceIgnoreZ, viewDotValue, sqrDistance, distanceRatio)
  local bulkyRatio = distanceRatio
  if not self.owner:IsLocal() then
    local responseRatio = sqrDistanceIgnoreZ / self.squaredResponseRange
    bulkyRatio = math.min(responseRatio, distanceRatio)
  end
  if self.PersistentEnable then
    bulkyRatio = 0
  end
  if SceneUtils.debugCloseCreateAIComp then
    bulkyRatio = 3
  end
  if bulkyRatio <= 1 then
    if self.distOptimizeMark ~= DistOptimizeMarkType.NEAR then
      if not self.PersistentEnable and AIComponent.LoadSemaphore >= AIComponent.MaxLoadSemaphore then
        return
      end
      if not self.isControllerCreated then
        if self.TreePath and not UE.URocoAIHelper.RequestMFBTAssetReady(self.TreePath) then
          Log.PrintScreenMsg("Pending Load MFBT Asset: %s", self.TreePath)
          return
        end
        if not string.IsNilOrEmpty(self._DebugTreePath) then
          self.TreePath = self._DebugTreePath
          self.isDots = false
        end
        if self.owner.viewObj and self.owner.viewObj:IsA(UE4.APawn) then
          self:CreateController()
        end
      end
      if self.isControllerCreated then
        if 0 == self.ForceLockAI then
          self:TryStartBtree(true)
        end
        self.distOptimizeMark = DistOptimizeMarkType.NEAR
        AIComponent.LoadSemaphore = AIComponent.LoadSemaphore + 1
      end
      self:UpdateAIReaction(true)
    end
  elseif bulkyRatio <= 1.18 then
    if self.distOptimizeMark ~= DistOptimizeMarkType.KEEP then
      if self.isControllerCreated then
        self:TryPauseBtree()
      end
      self.distOptimizeMark = DistOptimizeMarkType.KEEP
    end
  elseif self.distOptimizeMark ~= DistOptimizeMarkType.FAR then
    self:UpdateAIReaction(false)
    self:DestroyController()
    self.distOptimizeMark = DistOptimizeMarkType.FAR
  end
end

local ServerAIComponent

function AIComponent:GetServerAIComponent()
  if self.isServerAI and not self.owner:IsLocal() then
    if not ServerAIComponent then
      ServerAIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.ServerAIComponent")
    end
    local Existed = self.owner.ServerAIComponent ~= nil
    local Comp = self.owner:EnsureComponent(ServerAIComponent)
    if not Existed and Comp and self:IsLocked() then
      Comp:ForceLock(true)
    end
    return Comp
  end
  return nil
end

function AIComponent:GetServerAIComponentRaw()
  local ServerAIComp = self.owner and self.owner.ServerAIComponent
  return ServerAIComp
end

local NPCOverlapCooldownNoAI = _G.DataConfigManager:GetGlobalConfigNumByKeyType("default_npc_impact_vibration_cd", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, 5000)

function AIComponent:UpdateAIReaction(tryEnable)
  if self.DefaultReactionTriedEnable == tryEnable then
    return
  end
  self.DefaultReactionTriedEnable = tryEnable
  if tryEnable then
    local isHuman = self.owner:IsHuman()
    if isHuman and not self.isDots then
      local reactionComp = self.owner:EnsureComponent(AIReactionComponent)
      reactionComp:SetEnable(true)
      local Abilities = reactionComp.Abilities
      if self.isControllerCreated then
        reactionComp:UpdateAbility(Abilities.Lookup | Abilities.Angry)
      else
        if 0 == self.owner.config.not_turn_face then
          reactionComp:UpdateAbility(Abilities.AutoLookAt)
        end
        local view = self.owner.viewObj
        if view and view.OverrideOverlapCooldown then
          view:OverrideOverlapCooldown(NPCOverlapCooldownNoAI)
        end
      end
    end
  else
    local reactionComp = self.owner.AIReactionComponent
    if reactionComp then
      reactionComp:SetEnable(false)
    end
  end
end

function AIComponent:IsLocked()
  return self.ForceLockAI > 0
end

function AIComponent:IsLockedForReason(reason)
  return self.ForceLockFlag & 1 << reason > 0
end

function AIComponent:GetStopReason()
  local reason = ""
  if self.lockedForPlayerNotFound then
    reason = reason .. " PlayerNotFound,"
  end
  if self.lockedForEnableReason then
    reason = reason .. " CompEnable,"
  end
  if self.lockedForBattleLogicStatusReason then
    reason = reason .. " SALS_FIGHT,"
  end
  reason = reason .. "\n"
  for _, v in pairs(AIDefines.LockReason) do
    if self:IsLockedForReason(v) then
      reason = reason .. ", " .. table.getKeyName(AIDefines.LockReason, v)
    end
  end
  return string.format("%s\n \230\152\175\229\144\166\233\148\129\229\174\154: %s(%d)\n\229\142\159\229\155\160: %s", self.owner:DebugNPCNameAndID(), self.ForceLockAI > 0 and "TRUE" or "FALSE", self.ForceLockAI, reason)
end

local function LogLockFunc(owner, lock, reason)
  return string.format("AIComponent:ForceLockForReason %s %s %s", owner and owner:DebugNPCNameAndID() or "no name", true == lock, table.getKeyName(AIDefines.LockReason, reason))
end

function AIComponent:ForceLockForReason(lock, noStopMove, reason)
  self:ClearDelayLockForReason(reason)
  local flag = 1 << reason
  local currentlyLocked = self.ForceLockFlag & flag > 0
  lock = true == lock
  if currentlyLocked == lock then
    return
  end
  if lock then
    self.ForceLockFlag = self.ForceLockFlag | flag
  else
    self.ForceLockFlag = self.ForceLockFlag & ~flag
  end
  self:ForceLock(lock, noStopMove)
  Log.DebugFunc(LogLockFunc, self.owner, lock, reason)
end

function AIComponent:ForceLock(lock, noStopMove)
  local lastLockState = self.ForceLockAI > 0
  if lock then
    self.ForceLockAI = self.ForceLockAI + 1
  else
    self.ForceLockAI = math.max(self.ForceLockAI - 1, 0)
  end
  noStopMove = noStopMove or false
  local currentLockState = self.ForceLockAI > 0
  if lastLockState ~= currentLockState then
    if self.isControllerCreated then
      if currentLockState then
        self:TryPauseBtree()
        self.owner:Stop()
        if not noStopMove then
          local char = self.owner.viewObj
          if char and UE.UObject.IsValid(char) then
            local moveComp = char.GetMovementComponent and char:GetMovementComponent() or nil
            if moveComp then
              moveComp:SetComponentTickEnabled(false)
            end
          end
        end
      else
        local char = self.owner.viewObj
        if char and UE.UObject.IsValid(char) then
          local moveComp = char.GetMovementComponent and char:GetMovementComponent() or nil
          if moveComp then
            moveComp:SetComponentTickEnabled(true)
          end
          if self:IsActive() then
            self:TryStartBtree(self.isHighPriority)
          end
        end
        self.distOptimizeMark = DistOptimizeMarkType.FAR
      end
    end
    local ServerAIComp = self:GetServerAIComponent()
    if ServerAIComp then
      ServerAIComp:ForceLock(currentLockState)
    end
    self:OnForceLockChanged()
  end
  local AttackComp = self.owner.AttackComponent
  if AttackComp then
    AttackComp:SetSuspendAttack(currentLockState)
  end
  if currentLockState then
    local headLookAtComp = self.owner.HeadLookAtComponent
    if headLookAtComp then
      headLookAtComp:ResetAutoLookAt(true)
    end
  end
end

function AIComponent:ForceLockForReasonDelay(lock, noStopMove, reason, seconds)
  if seconds <= 0 then
    self:ForceLockForReason(lock, noStopMove, reason)
    return
  end
  self:ClearDelayLockForReason(reason)
  self.DelayLockHandle[reason] = _G.DelayManager:DelaySeconds(seconds, self.OnDelayLock, self, lock, noStopMove, reason)
end

function AIComponent:ClearDelayLockForReason(reason)
  local prevHandle = self.DelayLockHandle[reason]
  if prevHandle then
    _G.DelayManager:CancelDelayById(prevHandle)
    self.DelayLockHandle[reason] = nil
  end
end

function AIComponent:ClearDelayLockForReasonAll()
  for _, handle in pairs(self.DelayLockHandle) do
    _G.DelayManager:CancelDelayById(handle)
  end
end

function AIComponent:OnDelayLock(lock, noStopMove, reason)
  self.DelayLockHandle[reason] = nil
  self:ForceLockForReason(lock, noStopMove, reason)
end

function AIComponent:OnForceLockChanged()
  local locked = self:IsLocked()
  if not locked and self.pendingResetPosForEnterDeepWater then
    self.pendingResetPosForEnterDeepWater = false
    self:RequestResetPosForEnterDeepWater()
  end
  if self.ForceLockDelegate then
    self.ForceLockDelegate:Invoke(locked)
  end
end

function AIComponent:RegisterForceLockChanged(caller, callback)
  if not self.ForceLockDelegate then
    self.ForceLockDelegate = Delegate()
  end
  self.ForceLockDelegate:Add(caller, callback)
end

function AIComponent:UnRegisterForceLockChanged(caller, callback)
  if not self.ForceLockDelegate then
    return
  end
  self.ForceLockDelegate:Remove(caller, callback)
end

function AIComponent:TryStartBtree(NeedLoadIfNon)
  if self.isServerAI then
    if self.owner.ServerAIComponent then
    else
      self:GetServerAIComponent()
    end
    if self:IsControllerValid() then
      local Controller = self.AIController
      if Controller.SetCanTick then
        Controller:SetCanTick(false)
      end
    end
    return
  end
  if self.owner:IsMagicReplayActor() then
    return
  end
  if self.isMFBT or not string.IsNilOrEmpty(self.TreePath) then
    if NeedLoadIfNon and not self.isBTLoaded then
      self:SwitchMFBtree(self.TreePath)
    end
    if self.isBTLoaded and self.AIController and UE.UObject.IsValid(self.AIController) then
      self.isBTRunning = true
      self.AIController:SetCanTick(true)
      self.AIController:SuspendDotsGroup(false)
      if self.owner:CanIntimate() then
        self:SendBondBeginEvent()
      end
    end
    self:OnLogicStatusUpdated()
    self:OnBuffUpdated()
    if self.needApplyWorldCombatInfo then
      self:OnWorldCombatPhaseUpdated()
    end
    return
  end
end

function AIComponent:TryPauseBtree()
  if self.isBTRunning and self.AIController and UE.UObject.IsValid(self.AIController) then
    self.AIController:SetCanTick(false)
    self.AIController:SuspendDotsGroup(true)
    self.isBTRunning = false
  end
end

function AIComponent:SwitchMFBtree(mfbtPath)
  if not string.IsNilOrEmpty(mfbtPath) and self.AIController and UE.UObject.IsValid(self.AIController) then
    if self.AIController.RunMFBT == nil then
      return Log.Error("\228\189\191\231\148\168\228\186\134\233\148\153\232\175\175\231\154\132 Model_CONF\239\188\140\230\151\160\230\179\149\232\191\144\232\161\140\232\161\140\228\184\186\230\160\145 model_id:", self.owner.config.model_conf)
    end
    if self.isBTLoaded then
      self:StopMfbt()
      self.isBTLoaded = false
    end
    self.AIController:RunMFBT(mfbtPath, self.isDots)
  end
end

function AIComponent:OnLoadFinished(result)
  self.isBTLoaded = result
  self.isBTRunning = result
  if self.relativePlayer.ref then
    if not RocoEnv.IS_SHIPPING then
      Log.DebugFormat("[AIC] Bind owner player for %d: player=%d", self.owner:GetServerId(), self.relativePlayer.ref:GetServerId())
    end
    self.AIController:SetFocusPlayer(self.relativePlayer.ref.viewObj)
  end
  if self.isDots and self.owner.serverData.attrs then
    self:OnHpUpdated(self.owner.serverData.attrs.hp, self.owner.serverData.attrs.hp_max)
  end
  if AIComponent.IsCurrentInFarm() then
    self:TrySendFarmerEvent()
    self:TrySendGuardEvent()
  end
end

function AIComponent:StopMfbt()
  if self.isMFBT and self.isBTLoaded then
    if self.isControllerCreated and UE.UObject.IsValid(self.AIController) then
      self.AIController:UnloadMFBehaviorTree()
    end
    self.isBTLoaded = false
  end
end

function AIComponent:OnVisible()
end

function AIComponent:OnInvisible()
end

function AIComponent:IsAILoaded()
  return self.isBTLoaded
end

function AIComponent:IsActive()
  return self.isControllerCreated and UE.UObject.IsValid(self.AIController) and self.isBTLoaded
end

function AIComponent:IsControllerValid()
  return self.isControllerCreated and UE.UObject.IsValid(self.AIController)
end

function AIComponent:GetController()
  return self.AIController
end

function AIComponent:GetControllerSafe()
  if self.isControllerCreated and UE.UObject.IsValid(self.AIController) then
    return self.AIController
  end
  return nil
end

function AIComponent:GetNavPolyFlag()
  if self.isControllerCreated then
    local AreaID, AreaFlag, succ = self.AIController:GetNearestPolyAreaInfo()
    if succ then
      return AreaFlag, AreaID
    end
  end
  return 0, 0
end

function AIComponent:SetNavFilterFlag(Flag, isInclude)
  if self.isControllerCreated then
    self.AIController:SetNavFlagFilter(Flag, isInclude)
  end
end

function AIComponent:OnBeAttacked(other)
  if self:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_MAGIC_STAR) then
    Log.DebugFormat("AIComponent:OnBeAttacked,[%s]\229\143\151\229\136\176\230\148\187\229\135\187\239\188\140\228\189\134\229\155\160\228\184\186\230\156\137 SACF_DISABLE_MAGIC_STAR \230\137\128\228\187\165\229\133\141\231\150\171\228\186\134", self.owner.config.name)
    return
  end
  self.lastHitBy = 3
  if self.isServerAI then
    local info = _G.ProtoMessage:newSceneAiReportInfo()
    info.ai_seq_id = self:GetSyncSeq()
    info.npc_obj_id = self.owner.serverData.base.actor_id
    info.attack_obj_id = other.serverData.base.actor_id
    self.owner:GetServerPoint(info.client_point)
    info.report_type = ProtoEnum.SvrAIReportType.SART_NPC_ATTACK_HIT
    _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_AiReport(info)
    return
  end
  if self.owner.config.monster_hit_type ~= Enum.MonsterHitType.MHT_KNOCKBACK then
    return
  end
  local atkComp = self.owner.AttackComponent
  if atkComp and atkComp:IsAttacking() then
    atkComp:StopAttack(false, AIDefines.ActionResult.Aborted)
  end
  local hidComp = self.owner:GetComponent(HiddenComponent)
  if hidComp and hidComp:IsHidden() then
  else
    local origin = other:GetActorLocation()
    if self:IsActive() then
      self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_HIT_BY_OTHER_NPC, 1, origin)
    end
  end
end

function AIComponent:OnBeHitByStar()
  if not RocoEnv.IS_SHIPPING and self.owner.viewObj and UE.UObject.IsValid(self.owner.viewObj) then
    UE.URocoAIHelper.SelectToDebug(self.owner.viewObj)
  end
  self.lastHitBy = 1
  local level = self.owner.module.SceneAIManager._cachedLastThrowStarChargeLevel
  local resistance = 0
  local petBaseData = self.owner:GetConfPetData()
  if petBaseData then
    resistance = petBaseData.stun_resistance
  end
  level = level - resistance
  local bResisted = level <= 0
  if bResisted then
    if self:IsActive() then
      self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_HIT_BY_STAR, -1)
    end
    return
  end
  local atkComp = self.owner.AttackComponent
  if atkComp and atkComp:IsAttacking() then
    atkComp:StopAttack(false, AIDefines.ActionResult.Aborted)
  end
  local hidComp = self.owner:GetComponent(HiddenComponent)
  if hidComp and hidComp:IsHidden() then
    if self:IsActive() then
      self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_HIT_BY_STAR, level)
    end
  else
    if not self.isServerAI then
    else
    end
    if self:IsActive() then
      self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_HIT_BY_STAR, level)
    end
  end
end

function AIComponent:OnBeCollide(position, normal)
  if self:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_MAGIC_STAR) then
    Log.DebugFormat("AIComponent:OnBeAttacked,[%s]\230\148\187\229\135\187\230\146\158\229\136\176\228\184\156\232\165\191\228\186\134\239\188\140\228\189\134\229\155\160\228\184\186\230\156\137 SACF_DISABLE_MAGIC_STAR \230\137\128\228\187\165\229\133\141\231\150\171\228\186\134", self.owner.config.name)
    return
  end
  self.lastHitBy = 2
  if self.isServerAI then
    local info = _G.ProtoMessage:newSceneAiReportInfo()
    info.ai_seq_id = self:GetSyncSeq()
    info.npc_obj_id = self.owner.serverData.base.actor_id
    self.owner:GetServerPoint(info.client_point)
    info.report_type = ProtoEnum.SvrAIReportType.SART_NPC_ATTACK_COLLIDE
    _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_AiReport(info)
    return
  end
  local source = UE.UKismetMathLibrary.Subtract_VectorVector(position, normal * 100)
  local atkComp = self.owner.AttackComponent
  if atkComp and atkComp:IsAttacking() then
    atkComp:StopAttack(false, AIDefines.ActionResult.Aborted)
  end
  self.hitSource = source
  if self:IsActive() then
    self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_COLLIDE_BLOCK_BY_OBS, 1, position)
  end
end

function AIComponent:OnBePeoOverlap()
  if self.isDots and self:IsActive() then
    self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_PEO_OVERLAP)
  end
end

function AIComponent:OnHiddenStatusChangedInDialogue(isHidden, dialogue_id)
  if self:IsLocked() and self.isServerAI then
    local info = _G.ProtoMessage:newSceneAiReportInfo()
    info.ai_seq_id = self:GetSyncSeq()
    info.npc_obj_id = self.owner.serverData.base.actor_id
    info.dialog_id = dialogue_id
    self.owner:GetServerPoint(info.client_point)
    info.report_type = isHidden and ProtoEnum.SvrAIReportType.SART_DIALOG_BEGIN_HIDDEN or ProtoEnum.SvrAIReportType.SART_DIALOG_LEAVE_HIDDEN
    _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_AiReport(info)
  end
end

function AIComponent:RequestResetPosForEnterDeepWater()
  if self.isServerAI then
    Log.DebugFormat("AIComponent:OnEnterWater, teleport : %s", self.owner.config.name)
    local info = _G.ProtoMessage:newSceneAiReportInfo()
    info.ai_seq_id = self:GetSyncSeq()
    info.npc_obj_id = self.owner.serverData.base.actor_id
    self.owner:GetServerPoint(info.client_point)
    info.report_type = ProtoEnum.SvrAIReportType.SART_NPC_IN_DEEP_WATER
    _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_AiReport(info)
  elseif self.owner:GetActorLocation():Dist(self.owner.landPos) > 200 then
    if _G.DataModelMgr.PlayerDataModel:IsInDungeon() then
      Log.DebugFormat("SceneNpc:OnEnterWater, in dungeon, start perfect teleport : %s", self.owner.config.name)
      NPCLuaUtils.ResetPet(self.owner.viewObj, 0.6, self.owner.landPos)
    else
      Log.DebugFormat("AIComponent:OnEnterWater, teleport : %s", self.owner.config.name)
      self.owner:TeleportToPos(self.owner.landPos)
      self:RestartAI()
    end
  end
end

function AIComponent:MarkPendingResetPosForEnterDeepWater()
  if self:IsLocked() then
    Log.DebugFormat("AIComponent:OnEnterWater, mark pending reset pos for AI Locked: %s", self.owner.config.name)
    self.pendingResetPosForEnterDeepWater = true
  else
    self:RequestResetPosForEnterDeepWater()
  end
end

function AIComponent:OnEnterDeepWater()
  if not self.owner then
    return
  end
  if self.owner:IsPet() then
    if self.owner:IsAThrownPet() then
      Log.DebugFormat("AIComponent:OnEnterWater, thrown pet try teleport back: %s", self.owner.config.name)
      local OwnerPlayerId = self.owner.serverData and self.owner.serverData.base.owner_id or 0
      local ownerPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, OwnerPlayerId)
      if ownerPlayer and ownerPlayer.viewObj then
        if ownerPlayer.isLocal then
          if self.owner.ThrowSession then
            self.owner.ThrowSession:ForceRecycle()
          end
        else
          self.owner:TeleportToPos(ownerPlayer:GetActorLocation())
        end
      else
        Log.PrintScreenMsg("AIComponent:OnEnterWater, \230\151\160\228\184\187\231\154\132\231\178\190\231\129\181\232\144\189\230\176\180\228\186\134\239\188\140\230\151\160\230\179\149\229\155\158\230\148\182")
      end
    else
      Log.DebugFormat("AIComponent:OnEnterWater, requesting teleport back: %s", self.owner.config.name)
      self:MarkPendingResetPosForEnterDeepWater()
    end
  elseif self.owner:IsHuman() then
    Log.DebugFormat("AIComponent:OnEnterWater, requesting teleport back: %s", self.owner.config.name)
    self:MarkPendingResetPosForEnterDeepWater()
  end
end

function AIComponent:SyncReportRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.PrintScreenMsg("AIComponent:SyncReportRsp error: %d name=%s id=%d", rsp.ret_info.ret_code, self.owner.config.name, self.owner.config.id)
    return
  end
  Log.PrintScreenMsg("new seqid: %d", rsp.ai_seq_id or 0)
  self.owner.ServerAIComponent.seq_id = rsp.ai_seq_id
end

function AIComponent:RegisterStatusListener()
  if not self._registered_LogicStatusListener then
    self._registered_LogicStatusListener = true
    self.owner:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
    self.owner:AddEventListener(self, NPCModuleEvent.OnBuffUpdated, self.OnBuffUpdated)
  end
end

function AIComponent:UnRegisterStatusListener()
  if self._registered_LogicStatusListener then
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnBuffUpdated, self.OnBuffUpdated)
    self._registered_LogicStatusListener = false
  end
end

function AIComponent:OnLogicStatusUpdated(isReconnect)
  local LogicStatusComp = self.owner:EnsureComponent(LogicStatusComponent)
  local status = {}
  local hasBattleStatus = false
  if LogicStatusComp.StatusInfo then
    for _, Status in ipairs(LogicStatusComp.StatusInfo) do
      if Status.status == Enum.SpaceActorLogicStatus.SALS_FIGHTING then
        hasBattleStatus = true
      end
      status[Status.status] = Status.extra_data and Status.extra_data.ai_param or 1
    end
  end
  if self:IsActive() then
    self.AIController:UpdateLogicStatus(status, 0)
  end
  if hasBattleStatus then
    self:LockForBattleLogicStatusReason(isReconnect)
  else
    self:UnlockForBattleLogicStatusReason()
  end
end

function AIComponent:OnBuffUpdated()
  if self:IsActive() and self.isDots and self.isControllerCreated and self.AIController and self.AIController.UpdateBuffs then
    local WorldCombatBuffComp = self.owner:GetComponent(WorldCombatBuffComponent)
    if WorldCombatBuffComp then
      local buffs = {}
      local MetBarrierBuff = false
      for id, Buff in pairs(WorldCombatBuffComp.Buffs) do
        table.insert(buffs, Buff.Info.buff_cfg_id)
        if Buff.Config.buff_effect_type == Enum.WorldBuffEffect.WBE_BARRIER then
          local val = Buff.Info.buff_val
          local max_val = Buff.Config.params[1]
          self.AIController:UpdateBarrier(val, max_val)
          MetBarrierBuff = true
        end
      end
      if not MetBarrierBuff then
        self.AIController:UpdateBarrier(0, 0)
      end
      self.AIController:UpdateBuffs(buffs, 0)
    end
  end
end

function AIComponent:UpdateBarrier(val, max_val)
  if self:IsActive() and self.isDots and self.isControllerCreated and self.AIController and self.AIController.UpdateBarrier then
    self.AIController:UpdateBarrier(val, max_val)
  end
end

function AIComponent:OnWorldCombatPhaseUpdated(phase)
  self.needApplyWorldCombatInfo = true
  if self:IsActive() then
    local cmd = _G.WorldCombatModuleCmd
    phase = phase or cmd and _G.NRCModuleManager:DoCmd(cmd.GetWorldCombatPhase, self:GetOwner()) or 0
    Log.PrintScreenMsg("WorldCombat Phase Updated! %d", phase)
    self.AIController:UpdateWorldCombatPhase(phase)
  end
end

function AIComponent:OnHpUpdated(hp, maxHp)
  if self.isDots and self:IsActive() then
    self.AIController:UpdateHealth(hp, maxHp)
  end
end

function AIComponent:OnEnterBattle(center, radius, disSqr)
end

function AIComponent:OnLeaveBattle()
  self:UnlockForBattleReason()
end

function AIComponent:LockForBattleReason()
  if not self:IsLockedForReason(AIDefines.LockReason.INTERNAL_LEGACY_BATTLE) then
    local view = self.owner.viewObj
    if view and view.RocoSkill then
      local skillObj = view.RocoSkill:GetActiveSkill()
      if skillObj then
        view.RocoSkill:CancelSkill(skillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
      end
    end
    self:ForceLockForReason(true, nil, AIDefines.LockReason.INTERNAL_LEGACY_BATTLE)
  end
end

function AIComponent:UnlockForBattleReason(delay)
  if self:IsLockedForReason(AIDefines.LockReason.INTERNAL_LEGACY_BATTLE) then
    if delay then
      self:ForceLockForReasonDelay(false, nil, AIDefines.LockReason.INTERNAL_LEGACY_BATTLE, 1)
    else
      self:ForceLockForReason(false, nil, AIDefines.LockReason.INTERNAL_LEGACY_BATTLE)
    end
  end
end

function AIComponent:LockForBattleLogicStatusReason(isReconnect)
  if self.lockedForBattleLogicStatusReason == false then
    local view = self.owner.viewObj
    if view and view.RocoSkill then
      local skillObj = view.RocoSkill:GetActiveSkill()
      if skillObj then
        view.RocoSkill:CancelSkill(skillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
      end
    end
    self:ForceLock(true, not isReconnect)
    self.lockedForBattleLogicStatusReason = true
  end
  self:LockForBattleReason()
end

function AIComponent:UnlockForBattleLogicStatusReason()
  if self.lockedForBattleLogicStatusReason == true then
    self:ForceLock(false)
    self.lockedForBattleLogicStatusReason = false
  end
  self:UnlockForBattleReason(true)
end

function AIComponent:UpdateChargeSkill()
  if not self.owner then
    return
  end
  local level = self.owner.serverData.base.lv
  if not level or self.owner.config.traverse_data_type ~= Enum.Traverse_Data_Type.TDT_PETBASE then
    return
  end
  local petBaseId = self.owner.config.traverse_data_param[1]
  local levelConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, petBaseId)
  if not levelConf then
    return
  end
  local levels = levelConf.level
  for i = #levels, 1, -1 do
    if level < levels[i].level_point then
    else
      local skillConf = DataConfigManager:GetSkillConf(levels[i].param, true)
      if not skillConf then
      elseif not table.contains(skillConf.describe_type, Enum.SkillDescribeType.SDT_WORLDBUFF) then
      else
        self.ChargeSkillPath = skillConf.worldbuff_res_id
        break
      end
    end
  end
end

function AIComponent:GetChargeSkillPath()
  if self.ChargeSkillPath then
    return self.ChargeSkillPath
  end
  if not self.owner then
    return
  end
  local level = self.owner.serverData.base.lv
  if not level then
    self.ChargeSkillPath = ""
    return
  end
  local PetBaseId = self.owner:GetPetbaseId()
  if not PetBaseId then
    self.ChargeSkillPath = ""
    return
  end
  self.ChargeSkillPath = UE.URocoAIHelper.GetChargeSkillPath(PetBaseId, level)
  return self.ChargeSkillPath
end

function AIComponent:SetBattleState(status)
  self.battleState = self.battleState | 1 << status
end

function AIComponent:HasBattleState(status)
  if not status then
    Log.Warning("AIComponent:HasBattleState status is nil")
    return false
  end
  return 0 ~= self.battleState & 1 << status
end

function AIComponent:UnsetBattleState(status)
  self.battleState = self.battleState & ~(1 << status)
end

function AIComponent:UnsetBattleStateMulti(bitset)
  self.battleState = self.battleState & ~bitset
end

function AIComponent:SetControlFlags(flag)
  local previous = self.controlFlags
  self.controlFlags = self.controlFlags | 1 << flag
  if 4 == flag then
    local HudComp = self.owner and self.owner.PetHUDComponent
    if HudComp then
      HudComp:OnAiControlFlagChanged(self.controlFlags, previous)
    end
  elseif 11 == flag then
    if self.owner.marked_in_perception_trigger then
      self.owner:SendEvent(NPCModuleEvent.OnAiControlFlagChanged, self.controlFlags, previous, self.owner)
    end
  elseif flag == Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE and self.owner.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    self.owner:SendEvent(NPCModuleEvent.OnAiControlFlagChanged, self.controlFlags, previous, self.owner)
  end
end

function AIComponent:HasControlFlags(flag)
  return 0 ~= self.controlFlags & 1 << flag
end

function AIComponent:GetControlFlags()
  return self.controlFlags
end

function AIComponent:UnsetControlFlags(flag)
  local previous = self.controlFlags
  self.controlFlags = self.controlFlags & ~(1 << flag)
  if 11 == flag then
    if self.owner.marked_in_perception_trigger then
      self.owner:SendEvent(NPCModuleEvent.OnAiControlFlagChanged, self.controlFlags, previous, self.owner)
    end
  elseif flag == Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE and self.owner.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    self.owner:SendEvent(NPCModuleEvent.OnAiControlFlagChanged, self.controlFlags, previous, self.owner)
  end
end

function AIComponent:ApplyControlFlags(flags)
  local previous = self.controlFlags
  if flags == previous then
    return
  end
  for _, flag in pairs(Enum.SceneAiControlFlags) do
    local flag_bit = 1 << flag
    if 0 ~= flag_bit & previous and 0 == flag_bit & flags then
      self:UnsetControlFlags(flag)
    elseif 0 == flag_bit & previous and 0 ~= flag_bit & flags then
      self:SetControlFlags(flag)
    end
  end
end

function AIComponent:SetPreAttackTag(tag)
  if self.PreAttackTag ~= tag then
    self.PreAttackTag = tag
    self.PreAttackCount = self.PreAttackCount + 1
  end
end

function AIComponent:ClearPreAttackTag()
  self.PreAttackTag = 0
  self.PreAttackCount = 0
end

function AIComponent:NotifyRunawayEvent(origin, level)
  if self.isControllerCreated then
    level = level or 0
    if self.isDots then
      self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_RUNAWAY, level, origin)
    end
  end
end

function AIComponent:OverrideBehavior(BehaviorGroupId, BTOverridePriority, SwitchOutCondId, PlayerContext)
  if self:IsActive() then
    self.AIController:OverrideBehavior(BehaviorGroupId, BTOverridePriority, SwitchOutCondId or 0, PlayerContext and PlayerContext.viewObj or nil)
  end
end

local SequalBehaviorGroupId

local function GetSequalBehaviorGroupId()
  if not SequalBehaviorGroupId then
    local conf = _G.DataConfigManager:GetNrcAiGlobalConfigConf("llm_pets_sequal_behavior_group_id")
    SequalBehaviorGroupId = conf and conf.num or 9000
  end
  return SequalBehaviorGroupId
end

function AIComponent:OverrideBehaviorWithSequal(Seq, BTOverridePriority, SwitchOutCondId, PlayerContext)
  if self:IsActive() then
    self.AIController:OverrideBehaviorWithSequal(GetSequalBehaviorGroupId(), Seq, BTOverridePriority, SwitchOutCondId or 0, PlayerContext and PlayerContext.viewObj or nil)
  end
end

function AIComponent:NotifyDotsWorldEvent(EventType, Param, Origin, InInstigator)
  if self:IsActive() then
    self.AIController:NotifyDotsWorldEvent(EventType, Param, Origin, InInstigator)
  end
end

function AIComponent:IsRoleOfGroup(groupId, groupRole)
  if self:IsActive() then
    return self.AIController:IsRoleOfGroup(groupId, groupRole)
  end
  return false
end

function AIComponent:SendBondBeginEvent()
  if self.AIController then
    self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_BOUD_BEGIN)
  end
end

function AIComponent:SendBondBoxOpenEvent(Pos)
  if self.AIController then
    self.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_BOUD_FIND_CHEST_OPENED, 1, Pos)
  end
end

function AIComponent:InitPlayerOwner()
  if self.owner:IsLocal() then
    return
  end
  if self.IsCurrentInHome() then
    return
  end
  local OwnerPlayerId = self.owner.serverData.base.owner_id
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, OwnerPlayerId)
  if 0 == OwnerPlayerId or player and player.isLocal then
    return
  end
  if not player then
    self:LockForPlayerNotFound(true)
    self:RegisterNetPlayerSpawnEvent()
    return
  end
  self:OnNetPlayerSpawn(player)
end

function AIComponent:OnNetPlayerSpawn(player)
  local OwnerPlayerId = self.owner.serverData.base.owner_id
  if player.serverData.base.actor_id == OwnerPlayerId then
    self.relativePlayer.ref = player
    if self.AIController and self.isBTLoaded then
      Log.DebugFormat("[AIC] Bind owner player for %d: player=%d", self.owner:GetServerId(), player:GetServerId())
      self.AIController:SetFocusPlayer(player.viewObj)
    end
    player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_DESTROY, self.OnRelativePlayerUnLoaded)
    self:LockForPlayerNotFound(false)
    self:UnregisterNetPlayerSpawnEvent()
  end
end

function AIComponent:RegisterNetPlayerSpawnEvent()
  if not self._registered_NetPlayerSpawn then
    NRCEventCenter:RegisterEvent("AIComponent", self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
    self._registered_NetPlayerSpawn = true
  end
end

function AIComponent:UnregisterNetPlayerSpawnEvent()
  if self._registered_NetPlayerSpawn then
    NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
    self._registered_NetPlayerSpawn = false
  end
end

function AIComponent:LockForPlayerNotFound(lock)
  if self.lockedForPlayerNotFound ~= lock then
    self:ForceLock(lock)
    self.lockedForPlayerNotFound = lock
  end
end

function AIComponent:OnRelativePlayerUnLoaded()
  if self.relativePlayer.ref then
    if self.AIController and UE4.UObject.IsValid(self.AIController) then
      self.AIController:SetFocusPlayer(nil)
    end
    self:StopMfbt()
    self:LockForPlayerNotFound(true)
    self.relativePlayer.ref:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_DESTROY, self.OnRelativePlayerUnLoaded)
    self.relativePlayer.ref = nil
    self:RegisterNetPlayerSpawnEvent()
  end
end

function AIComponent:ClearPerceivePlayerState()
  if self.d_perceiveDebounce then
    _G.DelayManager:CancelDelayById(self.d_perceiveDebounce)
    self.d_perceiveDebounce = nil
  end
  self.perceiveTargetState = false
  if self.perceivePlayer then
    self.perceivePlayer = false
    self:NotifyPerceiveStateChanged()
  end
end

function AIComponent:NotifyPerceiveStateChanged()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  localPlayer:SendEvent(PlayerModuleEvent.ON_PERCEIVED_STATE_CHANGED, self.owner:GetServerId(), self.perceivePlayer)
end

function AIComponent:DebouncePerceivePlayer(bState)
  if self.d_perceiveDebounce and self.perceiveTargetState == bState then
    return
  end
  self.perceiveTargetState = bState
  if self.d_perceiveDebounce then
    _G.DelayManager:CancelDelayById(self.d_perceiveDebounce)
    self.d_perceiveDebounce = nil
  end
  if self.perceivePlayer == bState then
    return
  end
  self.d_perceiveDebounce = _G.DelayManager:DelaySeconds(self.perceiveDebounceTime, self.OnDebouncePerceivePlayerApply, self)
end

function AIComponent:OnDebouncePerceivePlayerApply()
  self.d_perceiveDebounce = nil
  if self.perceivePlayer ~= self.perceiveTargetState then
    self.perceivePlayer = self.perceiveTargetState
    self:NotifyPerceiveStateChanged()
  end
end

function AIComponent:PerceiveLocalPlayer(bState)
  if not self.owner or self.owner.isDestroy then
    return
  end
  self:DebouncePerceivePlayer(bState)
end

function AIComponent:TryAppendState(StateClass, ...)
  local StateId = StateClass.className
  local Instance = rawget(self.state_specs, StateId)
  if Instance then
    return Instance
  end
  Instance = StateClass()
  rawset(self.state_specs, StateId, Instance)
  Instance:OnStateAdd(self.owner, ...)
  return Instance
end

function AIComponent:TryRemoveState(StateClass, ...)
  local MemberName = StateClass.className
  local Instance = rawget(self.state_specs, MemberName)
  if Instance then
    Instance:OnStateRemoved(AIStateSpec.RemoveReason.Script, ...)
    rawset(self.state_specs, MemberName, nil)
  end
end

function AIComponent:TryRemoveStateDelayed(StateClass, DelayTime)
end

local ref_SceneAIManager

function AIComponent.GetManager()
  if not ref_SceneAIManager then
    local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
    ref_SceneAIManager = NPCModule.SceneAIManager
  end
  return ref_SceneAIManager
end

return AIComponent
