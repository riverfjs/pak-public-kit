local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local SceneAIManager = Class("SceneAIManager")

function SceneAIManager:Ctor()
  self._cachedLastThrowItemLevel = 0
  self._cachedLastThrowStarSource = nil
  self._cachedLastThrowStarChargeLevel = 0
  self._cachedLastThrowStarChargePercent = 0
  self._cachedLastThrowPetGid = -1
  self.LastIsVisitState = false
  self.LastIsVisitOwner = false
  self.WeakAIComp = {}
  _G.MakeWeakTable(self.WeakAIComp)
  self.RolePlayBehaviorMapping = {}
  self.RolePlayBehaviorPool = {}
  self.ReportPositionSet = {}
  self.DelayingReportPosition = false
  self.bReportPositionSetNotEmpty = false
  self.HabitatRelationMap = {}
  self.Message_SceneCommand = _G.ProtoMessage:newZoneSceneClientAiCommandReq()
  self.Message_AiReport = _G.ProtoMessage:newZoneSceneAiReportReq()
  self.module = nil
end

function SceneAIManager:Init(module)
  self.module = module
  _G.NRCEventCenter:RegisterEvent("SceneAIManager", self, TaskModuleEvent.BattleOver, self.ApplyAfterBattleBehavior)
  _G.NRCEventCenter:RegisterEvent("SceneAIManager", self, MainUIModuleEvent.UI_SetThrowItem, self.OnPlayerThrowItemChanged)
  _G.NRCEventCenter:RegisterEvent("SceneAIManager", self, MainUIModuleEvent.UI_SetThrowNull, self.OnPlayerThrowItemChanged)
  _G.NRCEventCenter:RegisterEvent("SceneAIManager", self, HomeModuleEvent.HomePlantGuardJustConfirm, self.OnHomePlantGuardJustConfirm)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.VISIT_OWNER_CHANGED, self.OnPlayerDataUpdate)
  Log.Debug("SceneAIManager:Init LoadInfos Begin")
  Log.Debug("SceneAIManager:Init LoadInfos End")
  UE4.UNRCStatics.EnableDotTick(true)
  self.RegisterBlackboardKeyBundle()
end

function SceneAIManager:UnInit()
  self.UnregisterBlackboardKeyBundle()
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.BattleOver, self.ApplyAfterBattleBehavior)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem, self.OnPlayerThrowItemChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowNull, self.OnPlayerThrowItemChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, HomeModuleEvent.HomePlantGuardJustConfirm, self.OnHomePlantGuardJustConfirm)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.VISIT_OWNER_CHANGED, self.OnPlayerDataUpdate)
  self:CleanUp_AiReport()
  self:CleanUp_SceneCommand()
  table.clear(self.WeakAIComp)
  if self.d_SwitchBatch then
    _G.DelayManager:CancelDelayById(self.d_SwitchBatch)
    self.d_SwitchBatch = nil
  end
  self.module = nil
end

function SceneAIManager.RegisterBlackboardKeyBundle()
  for k, bundle in pairs(_G.AIDefines.DotsBlackboardKeyBundleKeys) do
    UE.UUnitAIHelper.RegisterBlackboardKeyBundle(k, bundle)
  end
end

function SceneAIManager.UnregisterBlackboardKeyBundle()
  for k, _ in pairs(_G.AIDefines.DotsBlackboardKeyBundleKeys) do
    UE.UUnitAIHelper.UnregisterBlackboardKeyBundle(k)
  end
end

local CachedResults = UE4.TArray(UE.AActor)
local NOTIFY_RADIUS = _G.DataConfigManager:GetBattleGlobalConfig("notify_radius", true).num * 100
local QueryTypes = {
  UE.EObjectTypeQuery.WorldDynamic,
  UE.EObjectTypeQuery.Pawn,
  UE.EObjectTypeQuery.WorldStatic
}
local BATTLE_RESULT_CONVERT_MAP

local function BattleResultConvert(ResultType)
  if nil == BATTLE_RESULT_CONVERT_MAP then
    BATTLE_RESULT_CONVERT_MAP = {
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_RUNAWAY] = Enum.WorldBattleResult.WBR_ESCAPE,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_LOSE_HP] = Enum.WorldBattleResult.WBR_ESCAPE,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_RUNAWAY_ROLE_MAGIC] = Enum.WorldBattleResult.WBR_ESCAPE,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_MONSTER_ESCAPE] = Enum.WorldBattleResult.WBR_ESCAPE,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN_DEFEAT] = Enum.WorldBattleResult.WBR_KILL,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN_CATCH] = Enum.WorldBattleResult.WBR_CATCH,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_MONSTER_ESCAPE2] = Enum.WorldBattleResult.WBR_MONSTER_ESCAPE,
      [ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_MONSTER_RUNAWAY] = Enum.WorldBattleResult.WBR_MONSTER_ESCAPE
    }
  end
  return BATTLE_RESULT_CONVERT_MAP[ResultType]
end

function SceneAIManager:ApplyAfterBattleBehavior(settleInfo)
  if not settleInfo then
    return
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerPos = player and player:GetActorLocation()
  local battleCenter = NRCModuleManager:DoCmd(BattleModuleCmd.GetBattleFieldCenterPos) or playerPos or UE.FVector()
  local battleRadius = NRCModuleManager:DoCmd(BattleModuleCmd.GetBattleFieldRadius) or 0
  self:SendSphereDotsEvent(battleCenter, battleRadius, Enum.DotsAIWorldEventType.DAWET_BATTLE_END, 1)
  local battleResult = settleInfo.result and BattleResultConvert(settleInfo.result) or 0
  Log.PrintScreenMsg("[SceneAIManager]\230\136\152\230\150\151\231\187\147\230\158\156\232\189\172\230\141\162 WorldBattleResult=%s", table.getKeyName(Enum.WorldBattleResult, battleResult) or tostring(battleResult))
  local npc = _G.NPCModuleCmd and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, settleInfo.interact_npc_id) or nil
  if not npc then
    if battleResult == Enum.WorldBattleResult.WBR_KILL then
      self:SendDotsEvent(npc, nil, Enum.DotsAIWorldEventType.DAWET_BATTLE_KILL, 1, playerPos)
    end
    return
  end
  local monsterInfo = settleInfo.monster_info[1]
  if not monsterInfo then
    Log.Warning("[SceneAIManager] BattleSettleInfo.monster_info is empty")
    return
  end
  if 0 == battleResult then
    return
  end
  local HidComp = npc:GetComponent(HiddenComponent)
  local AIComp = npc.AIComponent
  if HidComp and monsterInfo.world_hide ~= HidComp:IsHidden() then
    Log.Warning("[SceneAIManager] \230\136\152\230\150\151\228\184\173\231\178\190\231\129\181\229\140\191\232\184\170\229\143\145\231\148\159\230\155\180\230\150\176,\233\135\141\230\150\176\232\174\190\231\189\174\229\140\191\232\184\170", monsterInfo.world_hide, npc.config.name)
    if monsterInfo.world_hide then
      HidComp:SetHide()
    else
      HidComp:ResetHide()
    end
  end
  local battlePetPos = npc.viewObj:K2_GetActorLocation()
  local battleNature = npc.serverData.npc_base.world_nature or 0
  local battleBehaviorId = self.MatchBattleResult(battleResult, battleNature, true, monsterInfo and monsterInfo.sleep)
  local behaviorGroupConf = DataConfigManager:GetAiBattleResultBehavior(battleBehaviorId, true)
  if behaviorGroupConf then
    local behGroupId = behaviorGroupConf.behavior_group_id
    if 1 == behaviorGroupConf.id or 0 == behGroupId then
      Log.PrintScreenMsg("\230\136\152\230\150\151\228\184\173\231\178\190\231\129\181\230\151\160\228\186\139\229\143\145\231\148\159 %s %d", npc.config.name, battleNature)
      if HidComp and HidComp:IsHidden() then
        HidComp:SetHide()
      end
    else
      Log.PrintScreenMsg("\230\136\152\230\150\151\228\184\173\231\178\190\231\129\181\232\161\140\228\184\186\229\164\141\229\134\153 %d %s %s %d", behGroupId, behaviorGroupConf.editor_name, npc.config.name, battleNature)
      if AIComp and AIComp:IsActive() then
        if battleResult == Enum.WorldBattleResult.WBR_KILL then
          self:SendDotsEvent(npc, nil, Enum.DotsAIWorldEventType.DAWET_BATTLE_KILL, 1, battlePetPos)
        end
        AIComp.AIController:SetDotsCommonVector("Global_BattleCenter", playerPos)
        AIComp:OverrideBehavior(behGroupId, _G.Enum.BehaviorOverridePriority.BOP_A)
        if HidComp then
          HidComp:ResetHide()
        end
      else
        Log.Warning("\230\136\152\230\150\151\228\184\173\231\178\190\231\129\181\232\161\140\228\184\186\229\164\141\229\134\153\229\164\177\232\180\165\239\188\129", behGroupId, behaviorGroupConf.editor_name, npc.config.name, battleNature)
      end
    end
  else
    Log.PrintScreenMsg("\230\136\152\230\150\151\228\184\173\231\178\190\231\129\181\230\151\160\228\186\139\229\143\145\231\148\159_noconf %s %d", npc.config.name, battleNature)
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local CachedIgnoreActors = setmetatable({
    npc.viewObj
  }, {__mode = "kv"})
  local Success = UE.UNRCStatics.SphereOverlapActors(World, battlePetPos, NOTIFY_RADIUS, QueryTypes, CachedIgnoreActors, CachedResults)
  if Success then
    for _, Actor in tpairs(CachedResults) do
      local sNpc = Actor.sceneCharacter
      if sNpc and npc ~= sNpc and sNpc.AIComponent and sNpc.AIComponent:IsActive() then
        local sNature = sNpc.serverData and sNpc.serverData.npc_base.world_nature or 0
        local sBehaviorId = self.MatchBattleResult(battleResult, sNature, false, sNpc.AIComponent:HasBattleState(Enum.BattleAIStatus.BAS_SLEEP))
        local sBehaviorGroupConf = DataConfigManager:GetAiBattleResultBehavior(sBehaviorId, true)
        local sBehGroupId = sBehaviorGroupConf and sBehaviorGroupConf.behavior_group_id or 0
        if 0 ~= sBehGroupId then
          Log.Warning("\230\136\152\230\150\151\229\164\150\231\178\190\231\129\181\232\161\140\228\184\186\229\164\141\229\134\153", sBehGroupId, sBehaviorGroupConf.editor_name, npc.config.name, sNature)
          if sNpc.AIComponent and sNpc.AIComponent:IsActive() then
            sNpc.AIComponent.AIController:SetDotsCommonVector("Global_BattleCenter", playerPos)
            sNpc.AIComponent:OverrideBehavior(sBehGroupId, _G.Enum.BehaviorOverridePriority.BOP_A)
            local sHidComp = sNpc:GetComponent(HiddenComponent)
            if sHidComp then
              sHidComp:ResetHide()
            end
          else
            Log.Warning("\230\136\152\230\150\151\229\164\150\231\178\190\231\129\181\232\161\140\228\184\186\229\164\141\229\134\153\229\164\177\232\180\165\239\188\129", sBehGroupId, sBehaviorGroupConf.editor_name, npc.config.name, sNature)
          end
        else
          Log.Warning("\230\136\152\230\150\151\229\164\150\231\178\190\231\129\181\230\151\160\228\186\139\229\143\145\231\148\159\239\188\129", npc.config.name, sNature)
        end
        if battleResult == Enum.WorldBattleResult.WBR_KILL then
          sNpc.AIComponent.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_BATTLE_KILL, 1, battlePetPos)
        end
      end
    end
    CachedResults:Clear()
  end
end

function SceneAIManager.MatchBattleResult(battleResult, nature, isBattlePet, isSleeping)
  local resultConfs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.AI_BATTLE_RESULT_CONF):GetAllDatas()
  for _, resultConf in pairs(resultConfs) do
    if resultConf.enum_WorldBattleResult ~= battleResult then
    elseif resultConf.enum_WorldNature ~= nature then
    elseif isBattlePet then
      if isSleeping then
        return resultConf.enum_WorldBattleNPC2
      else
        return resultConf.enum_WorldBattleNPC1
      end
    elseif isSleeping then
      return resultConf.enum_WorldBattleNPC4
    else
      return resultConf.enum_WorldBattleNPC3
    end
  end
  return 0
end

local rp_reaction_require_range, rp_reaction_require_face, role_play_think_behavior_group, role_play_think_end_fsm

local function InitRolePlayBehaviorConfig()
  if nil == rp_reaction_require_range then
    rp_reaction_require_range = _G.DataConfigManager:GetGlobalConfig("rp_reaction_require_range", true).num
    rp_reaction_require_face = _G.DataConfigManager:GetGlobalConfig("rp_reaction_require_face", true).num
    role_play_think_behavior_group = _G.DataConfigManager:GetNpcGlobalConfig("role_play_think_behavior_group", true).num
    role_play_think_end_fsm = _G.DataConfigManager:GetNpcGlobalConfig("role_play_think_end_fsm", true).num
  end
end

function SceneAIManager:ApplyRolePlayBehavior(RpBehaviorId, RpStatus, fromPlayer)
  local BannedPercept = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_PAUSE_NPC_PERCEPT, false, false)
  if BannedPercept then
    return
  end
  InitRolePlayBehaviorConfig()
  local player = fromPlayer or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local playerId = player:GetServerId()
  if RpStatus == UE.EDotsStatusType.Start then
    self:OnRolePlayStart(RpBehaviorId, RpStatus, player)
  elseif RpStatus == UE.EDotsStatusType.Finish then
    self:OnRolePlayApply(RpBehaviorId, RpStatus, player)
  else
    self.RolePlayBehaviorMapping[playerId] = nil
  end
end

function SceneAIManager:BorrowRolePlayBehaviorItemFromPool(bgId, fixVal)
  if #self.RolePlayBehaviorPool > 0 then
    local tab = table.remove(self.RolePlayBehaviorPool)
    tab[1] = bgId
    tab[2] = fixVal
    return tab
  end
  return {bgId, fixVal}
end

function SceneAIManager:ReturnRolePlayBehaviorItemToPool(item)
  table.insert(self.RolePlayBehaviorPool, item)
end

function SceneAIManager:OnRolePlayStart(RpBehaviorId, RpStatus, fromPlayer)
  local RpConf = _G.DataConfigManager:GetRoleplayBehaviorConf(RpBehaviorId, true)
  if not RpConf then
    return
  end
  local player = fromPlayer or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerView = player and player.viewObj
  if not playerView then
    return
  end
  InitRolePlayBehaviorConfig()
  local playerRelPos = playerView:K2_GetActorLocation()
  local playerId = player:GetServerId()
  local radius = RpConf.range
  local isLocal = player.isLocal
  local World = _G.UE4Helper.GetCurrentWorld()
  local CachedIgnoreActors = setmetatable({}, {__mode = "kv"})
  local Success = UE.UNRCStatics.SphereOverlapActors(World, playerRelPos, radius, QueryTypes, CachedIgnoreActors, CachedResults)
  if Success then
    local pendingAffectNpc
    if self.RolePlayBehaviorMapping[playerId] then
      pendingAffectNpc = self.RolePlayBehaviorMapping[playerId]
      for _, behaviorItem in pairs(pendingAffectNpc) do
        self:ReturnRolePlayBehaviorItemToPool(behaviorItem)
      end
      table.clear(pendingAffectNpc)
    else
      self.RolePlayBehaviorMapping[playerId] = {}
      pendingAffectNpc = self.RolePlayBehaviorMapping[playerId]
    end
    for _, Actor in tpairs(CachedResults) do
      local Npc = Actor.sceneCharacter
      if not (Npc and Npc.AIComponent and Npc.AIComponent:IsActive()) or Npc.config.genre == Enum.ClientNpcType.CNT_PETBOSS then
      elseif Npc.HiddenComponent and Npc.HiddenComponent:IsHidden() and Npc.HiddenComponent:IsMimicType() then
      else
        local petConf = Npc and Npc:GetConfPetData()
        if petConf and petConf.pet_reaction then
          local IsHomePet = Npc.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME
          if IsHomePet and _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InHomeIndoor() and _G.HomeIndoorSandbox.HomeAIServ.MasterUid == player:GetLogicId() then
            IsHomePet = false
          end
          local anyBehavior = false
          if IsHomePet then
            local TreatLikeFriend = false
            if _G.HomeIndoorSandbox then
              TreatLikeFriend = _G.HomeIndoorSandbox.Utils.ShouldAiTreatLikeFriendByPlayer(player)
            end
            local BehaviorId, fixVal = self.ChooseRolePlayReactionRandomHomePet(petConf, RpBehaviorId, TreatLikeFriend)
            local npc_server_id = Npc:GetServerId()
            if 0 ~= BehaviorId then
              Log.DebugFormat("[SceneAI] Roleplay pre \232\161\140\228\184\186\232\166\134\229\134\153 rp=[%d] actor=[%u] npc_id=[%d] behavior=[%d] fixVal=[%d]%s", RpBehaviorId, npc_server_id, Npc.config.id, BehaviorId, fixVal, TreatLikeFriend and "f" or "s")
              pendingAffectNpc[npc_server_id] = self:BorrowRolePlayBehaviorItemFromPool(BehaviorId, fixVal)
              anyBehavior = true
            end
          else
            local BehaviorId = self.ChooseRolePlayReactionRandom(petConf, RpBehaviorId)
            if 0 ~= BehaviorId then
              local npc_server_id = Npc:GetServerId()
              Log.DebugFormat("[SceneAI] \232\161\140\228\184\186\232\166\134\229\134\153 pre \232\161\140\228\184\186\232\166\134\229\134\153 rp=[%d] actor=[%u] npc_id=[%d] behavior=[%d]", RpBehaviorId, npc_server_id, Npc.config.id, BehaviorId)
              pendingAffectNpc[npc_server_id] = self:BorrowRolePlayBehaviorItemFromPool(BehaviorId, 0)
              anyBehavior = true
            end
          end
          if isLocal then
            local needPlayThinkBehavior = anyBehavior
            if not needPlayThinkBehavior then
              local npcRelPos = Npc.viewObj:K2_GetActorLocation()
              local npcFwd = Npc.viewObj:GetActorForwardVector()
              local DirToPlayer = playerRelPos - npcRelPos
              if DirToPlayer:Size() < rp_reaction_require_range and npcFwd:CosineAngle2D(DirToPlayer) > math.cos(rp_reaction_require_face / 2) then
                needPlayThinkBehavior = true
              end
            end
            if needPlayThinkBehavior then
              Npc.AIComponent:OverrideBehavior(role_play_think_behavior_group, Enum.BehaviorOverridePriority.BOP_C, role_play_think_end_fsm, player)
            end
          end
        end
      end
    end
    CachedResults:Clear()
  end
end

function SceneAIManager:OnRolePlayApply(RpBehaviorId, RpStatus, fromPlayer)
  local player = fromPlayer or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerId = player and player:GetServerId() or 0
  local isLocal = player.isLocal
  local pendingAffectNpc = self.RolePlayBehaviorMapping[playerId]
  if not pendingAffectNpc then
    return
  end
  local Npcs = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  for npc_server_id, behaviorItem in pairs(pendingAffectNpc) do
    local BehaviorId = behaviorItem[1]
    local fixVal = behaviorItem[2]
    local Npc = Npcs[npc_server_id]
    if Npc then
      if Npc.HiddenComponent and Npc.HiddenComponent:IsHidden() and Npc.HiddenComponent:IsMimicType() then
        self:ReturnRolePlayBehaviorItemToPool(behaviorItem)
      else
        if Npc.AIComponent and Npc.AIComponent:IsActive() then
          Npc.AIComponent:OverrideBehavior(BehaviorId, _G.Enum.BehaviorOverridePriority.BOP_B, 0, player)
          if fixVal and 0 ~= fixVal then
            _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnRolePlayAffectHomePet, playerId, npc_server_id, fixVal)
            if isLocal then
              local AttrComp = Npc.HomePetAttributeComponent
              if AttrComp then
                local Controller = Npc.AIComponent.AIController
                Controller:SetDotsCommonInt("Global_FriendlyLevel", AttrComp:GetFriendlinessCurrent(playerId))
                Controller:RequestTickInputBlackboard()
              end
            end
          end
        end
        self:ReturnRolePlayBehaviorItemToPool(behaviorItem)
      end
    end
  end
  table.clear(pendingAffectNpc)
end

function SceneAIManager.ChooseRolePlayReactionRandom(petConf, RpBehaviorId)
  if not petConf or not petConf.pet_reaction then
    return 0
  end
  local reactionConf
  for _, reaction_conf_id in ipairs(petConf.pet_reaction) do
    reactionConf = _G.DataConfigManager:GetPetBehaviorReactionConf(reaction_conf_id, true)
    if reactionConf then
      for _, reaction in ipairs(reactionConf.reaction_random) do
        local matched = false
        if reaction.behavior_ids then
          for _, behavior_id in ipairs(reaction.behavior_ids) do
            if behavior_id == RpBehaviorId then
              matched = true
            end
          end
        else
          matched = reaction.behavior_id == RpBehaviorId
        end
        if matched then
          local total_weight = 0
          for i = 1, #reaction.reaction_ai do
            total_weight = total_weight + reaction.weight[i]
          end
          local match_weight = math.random(0, total_weight)
          local current_weight = 0
          for i = 1, #reaction.reaction_ai do
            current_weight = current_weight + reaction.weight[i]
            if match_weight <= current_weight then
              local result = reaction.reaction_ai[i]
              Log.DebugFormat("[SceneAI] \233\128\137\230\139\169 RP[%d] \232\161\140\228\184\186 petbase=[%d] reactionconf=[%d] result=[%d]", RpBehaviorId, petConf.id, reaction_conf_id, result or 0)
              return result
            end
          end
          return 0
        end
      end
    end
  end
  return 0
end

function SceneAIManager.ChooseRolePlayReactionRandomHomePet(petConf, RpBehaviorId, FixRole)
  if not petConf or not petConf.pet_reaction then
    return 0, 0
  end
  local reactionConf
  for _, reaction_conf_id in ipairs(petConf.pet_reaction) do
    reactionConf = _G.DataConfigManager:GetPetBehaviorReactionConf(reaction_conf_id, true)
    if reactionConf then
      for _, reaction in ipairs(reactionConf.reaction_random) do
        local matched = false
        if reaction.behavior_ids then
          for _, behavior_id in ipairs(reaction.behavior_ids) do
            if behavior_id == RpBehaviorId then
              matched = true
            end
          end
        else
          matched = reaction.behavior_id == RpBehaviorId
        end
        if matched then
          local total_weight = 0
          for i = 1, #reaction.home_reaction_ai do
            total_weight = total_weight + reaction.home_reaction_weight[i]
          end
          local match_weight = math.random(0, total_weight)
          local current_weight = 0
          for i = 1, #reaction.home_reaction_ai do
            current_weight = current_weight + reaction.home_reaction_weight[i]
            if match_weight <= current_weight then
              local fix_value = FixRole and (reaction.friend_reaction_fix_value[i] or reaction.friend_reaction_fix_value[1]) or reaction.stranger_reaction_fix_value[i] or reaction.stranger_reaction_fix_value[1] or 0
              local result = reaction.home_reaction_ai[i]
              Log.DebugFormat("[SceneAI] \233\128\137\230\139\169 RP[%d] Home\232\161\140\228\184\186 petbase=[%d] reactionconf=[%d] result=[%d]", RpBehaviorId, petConf.id, reaction_conf_id, result or 0)
              return result, fix_value
            end
          end
          return 0, 0
        end
      end
    end
  end
  return 0, 0
end

function SceneAIManager:SendSphereDotsEvent(origin, radius, eventType, param, contextNpc)
  if not origin then
    return
  end
  if not radius then
    local eventConf = _G.DataConfigManager:GetNrcAiSenseEventConf(eventType + 1000000, true)
    if eventConf and #eventConf.spread_dis > 0 then
      radius = eventConf.spread_dis[#eventConf.spread_dis]
    else
      radius = 0
    end
  end
  self:SendSenseEvent(origin, radius, eventType, param)
  goto lbl_36
  Log.Warning("[SceneAIManager:SendSphereDotsEvent] deprecated entrance !!! c:hzw")
  ::lbl_36::
end

local TempEventPos = UE.FVector(0, 0, 0)

function SceneAIManager:SendSenseEvent(origin, radius, eventType, param)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  SceneUtils.ConvertAbsoluteToRelativeInPlace(origin, TempEventPos)
  UE.UDotsStatics.SendSceneEvent(player.viewObj, Enum.UnitAISenseEventType.UASET_WORLD_EVENT, eventType, param or 0, TempEventPos, radius)
end

function SceneAIManager:SendDotsEvent(owner, radius, eventType, param, origin)
  Log.Debug("[SceneAIManager:SendDotsEvent]", origin, eventType)
  if not radius then
    local eventConf = DataConfigManager:GetNrcAiSenseEventConf(eventType + 1000000, true)
    if eventConf and #eventConf.spread_dis > 0 then
      radius = eventConf.spread_dis[#eventConf.spread_dis]
    else
      radius = 0
    end
  end
  origin = origin or owner:GetActorLocation()
  if 0 == radius then
    if owner.AIComponent and owner.AIComponent:IsActive() then
      owner.AIComponent.AIController:NotifyDotsWorldEvent(eventType, param, origin)
    end
  else
    self:SendSphereDotsEvent(origin, radius, eventType, param)
  end
end

function SceneAIManager:OnPlayerThrowItemChanged(type, itemInfo)
  local currentLevel = 0
  if type == MainUIModuleEnum.MainUIChooseType.PET then
    currentLevel = itemInfo.level
  end
  if self._cachedLastThrowItemLevel == currentLevel then
    return
  end
  self._cachedLastThrowItemLevel = currentLevel
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local ctrl = player:GetUEController()
    if ctrl then
      ctrl:SetDotsHoldingPetLevel(currentLevel)
    end
  end
end

local Battle1v1v1Radius = _G.DataConfigManager:GetBattleGlobalConfig("1v1v1_battle_radius").num
local Battle1vNThrowAttackRadius = _G.DataConfigManager:GetBattleGlobalConfig("1vn_battle_throwbattle_attack_radius").num
local Battle1vNThrowGroupRadius = _G.DataConfigManager:GetBattleGlobalConfig("1vn_battle_throwbattle_group_radius").num
local Battle1vNTouchAttackRadius = _G.DataConfigManager:GetBattleGlobalConfig("1vn_battle_touchbattle_attack_radius").num
local Battle1vNTouchGroupRadius = _G.DataConfigManager:GetBattleGlobalConfig("1vn_battle_touchbattle_group_radius").num
local PveNpcAroundRange = _G.DataConfigManager:GetBattleGlobalConfig("pve_npc_around_range").num

function SceneAIManager.MatchPetEvoHelper(evo_ids, other_evo_ids)
  if 0 == #evo_ids or 0 == #other_evo_ids then
    return false
  end
  for _, evo_id in ipairs(evo_ids) do
    for _, other_evo_id in ipairs(other_evo_ids) do
      if evo_id == other_evo_id then
        return true
      end
    end
  end
  return false
end

local Dummy = {}

function SceneAIManager.GetPetEvoIds(npc)
  if npc.config.traverse_data_type ~= Enum.Traverse_Data_Type.TDT_PETBASE or 0 == #npc.config.traverse_data_param then
    return Dummy
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(npc.config.traverse_data_param[1], false)
  return petBaseConf and petBaseConf.pet_evolution_id or Dummy
end

function SceneAIManager:QueryExtraBattleMember(origin, battle_type)
  local BOSS_GENRE = Enum.ClientNpcType.CNT_PETBOSS
  if origin.config.genre == BOSS_GENRE then
    return Dummy
  end
  if UIUtils.CheckIsHighValuePet(origin) then
    return Dummy
  end
  local isVisiting = self.LastIsVisitState and self.LastIsVisitOwner
  battle_type = battle_type or 1
  local position = origin:GetActorLocation()
  local members = {}
  MakeWeakTable(members)
  local IdSet = {}
  table.insert(members, origin)
  IdSet[origin:GetServerId()] = true
  local originAIComp = origin.AIComponent
  local originInGroupStatus = false
  local originInGroup = false
  local originGroupInst = 0
  local originGroupRole = 0
  local originGroupCfg = 0
  local originReadyFor1V1V1 = false
  if originAIComp then
    originInGroupStatus = originAIComp:HasBattleState(Enum.BattleAIStatus.BAS_GROUP)
    originReadyFor1V1V1 = originAIComp:HasControlFlags(Enum.SceneAiControlFlags.SACF_ENABLE_1V1V1_BATTLE)
    if originAIComp:IsActive() then
      originGroupInst, originGroupRole, originGroupCfg, originInGroup = originAIComp.AIController:GetGroupInfos()
      originReadyFor1V1V1 = originReadyFor1V1V1 and originInGroup
    end
  end
  local attackRadius = 1 == battle_type and Battle1vNThrowAttackRadius or Battle1vNTouchAttackRadius
  local groupRadius = 1 == battle_type and Battle1vNThrowGroupRadius or Battle1vNTouchGroupRadius
  local isSameRadius = attackRadius == groupRadius
  local World = _G.UE4Helper.GetCurrentWorld()
  local CachedIgnoreActors = setmetatable({}, {__mode = "kv"})
  local Success = UE.UKismetSystemLibrary.Abs_SphereOverlapActors(World, position, math.max(attackRadius, groupRadius, Battle1v1v1Radius, PveNpcAroundRange), nil, UE.ANPCBaseCharacter, CachedIgnoreActors, CachedResults)
  local CandidateNPCs = {}
  local Other1V1V1Member
  local members_side2x = {}
  MakeWeakTable(members_side2x)
  local members_onlooker = {}
  MakeWeakTable(members_onlooker)
  if Success then
    for _, Actor in tpairs(CachedResults) do
      local npc = Actor.sceneCharacter
      if not (npc and IdSet[npc:GetServerId()] == nil and npc.config) or npc.config.genre == BOSS_GENRE then
      else
        local AiComp = npc.AIComponent
        if not AiComp then
        elseif npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
        elseif UIUtils.CheckIsHighValuePet(npc) then
        else
          local dist = position:Dist2D(Actor:Abs_K2_GetActorLocation())
          local serverAIFreeState = AiComp.isServerAI
          local activatedLocalAi = AiComp:IsActive()
          if activatedLocalAi or serverAIFreeState then
            local check1v1v1 = not isVisiting and originReadyFor1V1V1 and nil == Other1V1V1Member and activatedLocalAi and dist < Battle1v1v1Radius
            if check1v1v1 and AiComp:HasControlFlags(Enum.SceneAiControlFlags.SACF_ENABLE_1V1V1_BATTLE) then
              local groupInst, groupRole, groupCfg, inGroup = AiComp.AIController:GetGroupInfos()
              if groupInst == originGroupInst then
                Other1V1V1Member = inGroup and npc or nil
              end
            else
              table.insert(CandidateNPCs, {n = npc, dist = dist})
            end
          end
          IdSet[npc:GetServerId()] = true
        end
      end
    end
    CachedResults:Clear()
  end
  table.sort(CandidateNPCs, function(l, r)
    return l.dist < r.dist
  end)
  local origin_pet_evo, against_pet_evo
  if not isVisiting then
    if Other1V1V1Member then
      Log.Debug("[1v1v1] \230\137\190\229\136\176\228\186\134\229\143\166\228\184\128\228\184\170\229\135\134\229\164\135\229\165\1891v1v1\231\154\132NPC", Other1V1V1Member.config.name)
      table.insert(members_side2x, Other1V1V1Member)
      origin_pet_evo = self.GetPetEvoIds(origin)
      against_pet_evo = self.GetPetEvoIds(Other1V1V1Member)
    else
      Log.Debug("[1vn] \229\188\128\229\167\139\229\175\187\230\137\190\229\145\168\232\190\185\231\154\132\231\148\168\228\186\1421vn\231\154\132NPC...")
    end
  end
  for _, npc_meta in ipairs(CandidateNPCs) do
    local npc = npc_meta.n
    local dist = npc_meta.dist
    if not isVisiting then
      if Other1V1V1Member then
        if dist <= Battle1v1v1Radius then
          local cur_pet_evo = self.GetPetEvoIds(npc)
          if #members < 3 and self.MatchPetEvoHelper(origin_pet_evo, cur_pet_evo) then
            table.insert(members, npc)
            Log.DebugFormat("[1v1v1] \230\187\161\232\182\179\230\157\161\228\187\1821X\228\190\167 \231\155\184\229\144\140\232\191\155\229\140\150\233\147\190 npc_id:%d, dist=%d", npc.config.id or 0, math.floor(npc_meta.dist) or 0)
            goto lbl_478
          elseif #members_side2x < 3 and self.MatchPetEvoHelper(against_pet_evo, cur_pet_evo) then
            table.insert(members_side2x, npc)
            Log.DebugFormat("[1v1v1] \230\187\161\232\182\179\230\157\161\228\187\1822X\228\190\167 \231\155\184\229\144\140\232\191\155\229\140\150\233\147\190 npc_id:%d, dist=%d", npc.config.id or 0, math.floor(npc_meta.dist) or 0)
            goto lbl_478
          end
        end
      elseif #members < 6 then
        local AIComp = npc.AIComponent
        local result = false
        if AIComp:HasBattleState(_G.Enum.BattleAIStatus.BAS_ATTACK) then
          result = isSameRadius or attackRadius > dist
          if result then
            Log.DebugFormat("[1vn] \230\187\161\232\182\179\230\157\161\228\187\182-\230\148\187\229\135\187 npc_id:%d, battle_state_attack=true, dist=%d", npc.config.id or 0, math.floor(dist) or 0)
          end
        end
        if not result and AIComp:IsActive() and (originInGroupStatus or AIComp:HasControlFlags(Enum.SceneAiControlFlags.SACF_ENABLE_GROUP_1VN_BATTLE)) then
          local groupInst, groupRole, groupCfg, inGroup = AIComp.AIController:GetGroupInfos()
          if inGroup and groupInst == originGroupInst then
            result = isSameRadius or groupRadius > dist
            if result then
              Log.DebugFormat("[1vn] \230\187\161\232\182\179\230\157\161\228\187\182-\231\190\164\231\187\132 npc_id:%d, group_inst=%d, dist=%d", npc.config.id or 0, groupInst or 0, math.floor(dist) or 0)
            end
          end
        end
        if result then
          table.insert(members, npc)
          goto lbl_478
        else
          Log.DebugFormat("[1vn] \228\189\160\230\178\161\230\156\137\232\181\132\230\160\188\229\149\138\239\188\140\230\178\161\230\156\137\232\181\132\230\160\188 npc_id:%d, dist=%d", npc.config.id or 0, math.floor(npc_meta.dist) or 0)
        end
      end
    end
    if dist < PveNpcAroundRange and (npc.config.is_pve_npc_around or 0) > 0 and #members_onlooker < 8 then
      table.insert(members_onlooker, npc)
    end
    ::lbl_478::
  end
  if Other1V1V1Member then
    Log.DebugFormat("[1v1v1] \230\144\156\231\180\162\231\187\147\230\157\159, \229\140\133\230\139\172\232\135\170\232\186\171\229\156\168\229\134\133\229\133\177\232\174\161%d\228\184\170NPC\230\139\137\229\133\1651X\228\190\167\230\136\152\230\150\151, %d\228\184\170Npc\230\139\137\229\133\1652X\228\190\167\230\136\152\230\150\151", #members, #members_side2x)
  else
    Log.DebugFormat("[1vn] \230\144\156\231\180\162\231\187\147\230\157\159, \229\140\133\230\139\172\232\135\170\232\186\171\229\156\168\229\134\133\229\133\177\232\174\161%d\228\184\170NPC\230\139\137\229\133\1651vn\230\136\152\230\150\151", #members)
  end
  return members, members_side2x, members_onlooker
end

function SceneAIManager.MakeCheerInfo(cheerNpc)
  local cheerMonsterId, err = SceneUtils.GetDefaultMonsterId(cheerNpc)
  if cheerMonsterId then
    local cheerInfo = _G.ProtoMessage:newCheerMonsterInitInfo()
    cheerInfo.sid = cheerNpc:GetServerId()
    cheerInfo.conf_id = cheerMonsterId
    local cheerAiComp = cheerNpc.AIComponent
    if cheerAiComp then
      cheerInfo.ai_status = cheerAiComp.battleState
      cheerInfo.pre_act_tag = cheerAiComp.PreAttackTag
      cheerInfo.pre_act_param = cheerAiComp.PreAttackCount
    end
    return cheerInfo, err
  else
    return nil, err
  end
end

function SceneAIManager.PrepareBattleData(cheerNpc, tag)
  _G.BattleManager.CheerPetsWorldInfo[tag] = cheerNpc:GetActorLocation()
  if cheerNpc.AIComponent then
    cheerNpc.AIComponent:LockForBattleReason()
  end
end

function SceneAIManager:FillBattleExtraMemberData(refCheerDatas, refOnlookers, origin, battle_type)
  Log.PrintScreenMsg("[SceneAI] Querying extra battle member")
  local enterType
  local cheers, against, onlookers = self:QueryExtraBattleMember(origin, battle_type)
  local validEnter = false
  if against and #against > 0 and #cheers > 0 then
    local count = 0
    local countA = 0
    local countB = 0
    Log.PrintScreenMsg("[1v1v1] NPC\231\173\155\233\128\137\229\174\140\230\175\149\239\188\140\229\135\134\229\164\135\232\191\155\230\136\152\230\149\176\230\141\174...")
    enterType = Enum.BattleType.BT_1V1V1
    for i = 1, math.min(#cheers, 3) do
      local cheerNpc = cheers[i]
      local cheerInfo, err = self.MakeCheerInfo(cheerNpc)
      if cheerInfo then
        countA = countA + 1
        cheerInfo.tag = SceneUtils.TagRef1v1v1_cheer[countA]
        cheerInfo.enter_index = count
        count = count + 1
        table.insert(refCheerDatas, cheerInfo)
        self.PrepareBattleData(cheerNpc, cheerInfo.tag)
      else
        Log.PrintScreenMsg("[1v1v1] %d %s \230\151\160\230\179\149\230\137\190\229\136\1761X\228\190\167 MonsterId, \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174(err=%d)", cheerNpc.config.id, cheerNpc.config.name, err or 0)
      end
    end
    for i = 1, math.min(#against, 3) do
      local cheerNpc = against[i]
      local cheerInfo, err = self.MakeCheerInfo(cheerNpc)
      if cheerInfo then
        countB = countB + 1
        cheerInfo.tag = SceneUtils.TagRef1v1v1_against[countB]
        cheerInfo.enter_index = count
        count = count + 1
        table.insert(refCheerDatas, cheerInfo)
        self.PrepareBattleData(cheerNpc, cheerInfo.tag)
      else
        Log.PrintScreenMsg("[1v1v1] %d %s \230\151\160\230\179\149\230\137\190\229\136\1762X\228\190\167 MonsterId, \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174(err=%d)", cheerNpc.config.id, cheerNpc.config.name, err or 0)
      end
    end
    validEnter = countA > 0 and countB > 0
  elseif #cheers > 1 then
    Log.PrintScreenMsg("[1vn] NPC\231\173\155\233\128\137\229\174\140\230\175\149\239\188\140\229\135\134\229\164\135\232\191\155\230\136\152\230\149\176\230\141\174...")
    enterType = Enum.BattleType.BT_1VN
    validEnter = true
    for i = 1, math.min(#cheers, 6) do
      local cheerNpc = cheers[i]
      local cheerInfo, err = self.MakeCheerInfo(cheerNpc)
      if cheerInfo then
        cheerInfo.tag = SceneUtils.TagRef1vN[i]
        cheerInfo.enter_index = i - 1
        table.insert(refCheerDatas, cheerInfo)
        self.PrepareBattleData(cheerNpc, cheerInfo.tag)
      else
        Log.PrintScreenMsg("[1vn] %d %s \230\151\160\230\179\149\230\137\190\229\136\176 MonsterId, \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174(err=%d)", cheerNpc.config.id, cheerNpc.config.name, err or 0)
      end
    end
  end
  if #refCheerDatas <= 1 or not validEnter then
    if nil ~= enterType then
      Log.PrintScreenMsg("[1vx] \231\178\190\231\129\181\230\149\176\233\135\143\228\184\141\232\182\179\229\164\159\232\191\155\229\133\165\231\137\185\230\174\138\230\136\152\230\150\151, \229\143\150\230\182\136\239\188\129")
    end
    table.clear(refCheerDatas)
  end
  if nil ~= enterType then
    Log.PrintScreenMsg("[1vx] \231\161\174\232\174\164\232\191\155\229\133\165\231\137\185\230\174\138\230\136\152\230\150\151 battle_type=%d", enterType)
  end
  local onlookerCount = onlookers and #onlookers or 0
  if onlookerCount > 0 then
    for i = 1, onlookerCount do
      local onlooker_npc = onlookers[i]
      table.insert(refOnlookers, onlooker_npc:GetServerId())
    end
    Log.PrintScreenMsg("[SceneAI][1vX] \229\176\157\232\175\149\229\188\149\229\133\165\229\155\180\232\167\130npc, \230\149\176\233\135\143 %d", onlookerCount)
  end
  return enterType
end

function SceneAIManager:OnPlayerDataUpdate()
  local newVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local newVisitOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
  local bVisitStateChanged = self.LastIsVisitState ~= newVisitState
  local bVisitOwnerChanged = self.LastIsVisitOwner ~= newVisitOwner
  if bVisitStateChanged then
    self.LastIsVisitState = newVisitState
  end
  if bVisitOwnerChanged then
    self.LastIsVisitOwner = newVisitOwner
  end
  if GlobalConfig.bEnableAISync and bVisitStateChanged and newVisitState and newVisitOwner then
    self:SwitchClientToServerAI()
  end
end

local NumSwitchBatch = 10

function SceneAIManager:SwitchClientToServerAI(actor_list)
  self:CollectPendingSwitchAIComp(actor_list)
  Log.PrintScreenMsg("=== [SceneAI] Start switching AI to server, total count:%d ===", #self.WeakAIComp)
  self:SwitchClientToServerAIBatch()
end

function SceneAIManager:CollectPendingSwitchAIComp(actor_list)
  table.clear(self.WeakAIComp)
  if actor_list then
    local npcDict = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
    for _, actor_id in ipairs(actor_list) do
      local npc = npcDict[actor_id]
      if npc and npc.AIComponent and not npc.AIComponent.isServerAI then
        local important = npc.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS
        if important then
          table.insert(self.WeakAIComp, 1, npc.AIComponent)
        else
          table.insert(self.WeakAIComp, npc.AIComponent)
        end
      end
    end
  else
    local npcIter = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetAllNPCInIter)
    for _, v in pairs(npcIter) do
      if v.AIComponent and not v.AIComponent.isServerAI then
        local important = v.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS
        if important then
          table.insert(self.WeakAIComp, 1, v.AIComponent)
        else
          table.insert(self.WeakAIComp, v.AIComponent)
        end
      end
    end
  end
end

function SceneAIManager:SwitchClientToServerAIBatch()
  self.d_SwitchBatch = nil
  local have_item_in_weak_table = false
  local req = _G.ProtoMessage:newZoneSwitchClientToServerAiReq()
  local count = 0
  for _, comp in pairs(self.WeakAIComp) do
    have_item_in_weak_table = true
    if comp:IsActive() then
      table.insert(req.actor_list, comp.owner:GetServerId())
      local full_datas = _G.ProtoMessage:newDotsComponentData()
      table.insert(req.comp_data_list, full_datas)
      local svrPt = comp.owner:GetServerPoint()
      svrPt.pos.z = math.round(svrPt.pos.z - comp.owner:GetScaledHalfHeight())
      table.insert(req.point_list, svrPt)
    end
    self.WeakAIComp[_] = nil
    count = count + 1
    if count > NumSwitchBatch then
      break
    end
  end
  if 0 ~= #req.actor_list then
    Log.PrintScreenMsg("[SceneAI] === Switching batch AI to server, current batch count:%d ===", #req.actor_list)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SWITCH_CLIENT_TO_SERVER_AI_REQ, req, self, self.SwitchClientToServerAiRsp, false, true)
  elseif have_item_in_weak_table then
    self.d_SwitchBatch = _G.DelayManager:DelayFrames(1, self.SwitchClientToServerAIBatch, self)
  else
    self:OnSwitchClientToServerComplete()
  end
end

function SceneAIManager:SwitchClientToServerAiRsp(rsp)
  if rsp.success_list then
    self:ApplySwitchClientToServerAIBatch(rsp.success_list)
  end
  if 0 == rsp.ret_info.ret_code or rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_INVALID then
    if self.LastIsVisitOwner and self.LastIsVisitState then
      self:SwitchClientToServerAIBatch()
    end
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ALREADY_IS_SERVER_AI then
    Log.PrintScreenMsg("[SceneAI] === Scene already is server AI, discard rest batches ===")
    self:OnSwitchClientToServerComplete()
  else
    Log.ErrorFormat("[SceneAI] Unknown ret_code, stop switching AI. code=%d", rsp.ret_info.ret_code)
  end
end

function SceneAIManager:ApplySwitchClientToServerAIBatch(actor_ids)
  if not actor_ids or 0 == #actor_ids then
    return
  end
  local npcs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  for _, actor_id in ipairs(actor_ids) do
    local npc = npcs[actor_id]
    if npc and npc.AIComponent then
      npc.AIComponent:SwitchToServerAI()
      Log.DebugFormat("[SceneAI] Confirm switching to server AI, actor_id:%u, actor_name:%s", actor_id, npc.config.name)
    else
      Log.PrintScreenMsg("[SceneAI] !! Cant find NPC switching to server AI, actor_id:%u", actor_id)
    end
  end
end

function SceneAIManager:OnSwitchClientToServerComplete()
  table.clear(self.WeakAIComp)
  Log.PrintScreenMsg("[SceneAI] === OnSwitchClientToServerComplete ===")
end

function SceneAIManager:SwitchServerToClientAIBatch(actor_ids, comp_datas)
  local batchCount = #actor_ids
  Log.PrintScreenMsg("[SceneAI] Switching Server to Client AI, batch count:%d", batchCount)
  for _ = 1, batchCount do
    local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, actor_ids[_])
    if npc then
      self:SwitchServerToClientAI(npc, nil)
    end
  end
end

function SceneAIManager:SwitchServerToClientAI(npc, data)
  if not npc.AIComponent then
    return Log.Debug("[SceneAI] Switching a npc without AIComponent to client AI", npc:GetServerId())
  end
  npc.serverData.npc_base.is_server_ai = false
  npc.AIComponent:UpdateDataFromConfig()
  if npc.PetHUDComponent then
    npc.PetHUDComponent:SetMainHudPerception(0, true)
  end
  npc.AIComponent:RescheduleGenre()
end

function SceneAIManager:RequestReportPosition(npc)
  if self.DelayingReportPosition then
    self.bReportPositionSetNotEmpty = true
    self.ReportPositionSet[npc:GetServerId()] = true
    return
  else
    npc:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE)
    self.DelayingReportPosition = true
    _G.DelayManager:DelaySeconds(5.0, self.PopReportPositionQueue, self)
  end
end

function SceneAIManager:PopReportPositionQueue()
  self.DelayingReportPosition = false
  if not self.bReportPositionSetNotEmpty then
    return
  end
  local msgItems = {}
  local NPCs = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  for actor_id, _ in pairs(self.ReportPositionSet) do
    local npc = NPCs[actor_id]
    if npc then
      local msgItem = npc:GetReportPositionItem(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE)
      if msgItem then
        table.insert(msgItems, msgItem)
      end
    end
  end
  if #msgItems > 0 then
    SceneUtils.DelayReportNpcPosition(nil, msgItems, false)
  end
  self.bReportPositionSetNotEmpty = false
  table.clear(self.ReportPositionSet)
  self.DelayingReportPosition = true
  _G.DelayManager:DelaySeconds(5.0, self.PopReportPositionQueue, self)
end

function SceneAIManager:EnqueueMessage_SceneCommand(info)
  if not info then
    return
  end
  if not self.d_PendingSend_SceneCommand then
    self.d_PendingSend_SceneCommand = _G.DelayManager:DelaySeconds(0.3, self.FlushMessage_SceneCommand, self)
  end
  Log.DebugFormat("[SceneAI] EnqueueMessage_SceneCommand: actor: %u , action: %s", info.actor_id, table.getKeyName(Enum.NpcSceneCommandType, info.action_id))
  table.insert(self.Message_SceneCommand.command_list, info)
end

function SceneAIManager:FlushMessage_SceneCommand()
  self.d_PendingSend_SceneCommand = nil
  Log.DebugFormat("[SceneAI] FlushMessage_SceneCommand: count %d", #self.Message_SceneCommand.command_list)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_AI_COMMAND_REQ, self.Message_SceneCommand)
  table.clear(self.Message_SceneCommand.command_list)
end

function SceneAIManager:CleanUp_SceneCommand()
  if self.d_PendingSend_SceneCommand then
    _G.DelayManager:CancelDelayById(self.d_PendingSend_SceneCommand)
    self:FlushMessage_SceneCommand()
  end
end

function SceneAIManager:EnqueueMessage_AiReport(info)
  if not info then
    return
  end
  if not self.d_PendingSend_AiReport then
    self.d_PendingSend_AiReport = _G.DelayManager:DelaySeconds(0.3, self.FlushMessage_AiReport, self)
  end
  table.insert(self.Message_AiReport.report_list, info)
end

function SceneAIManager:FlushMessage_AiReport()
  self.d_PendingSend_AiReport = nil
  local NPCs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  if NPCs then
    for _, req in ipairs(self.Message_AiReport.report_list) do
      local actor_id = req.npc_obj_id
      local npc = NPCs[actor_id]
      if npc and npc.AIComponent then
        req.ai_seq_id = npc.AIComponent:GetSyncSeq()
      end
    end
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_AI_REPORT_REQ, self.Message_AiReport)
  table.clear(self.Message_AiReport.report_list)
end

function SceneAIManager:CleanUp_AiReport()
  if self.d_PendingSend_AiReport then
    _G.DelayManager:CancelDelayById(self.d_PendingSend_AiReport)
    self:FlushMessage_AiReport()
  end
end

function SceneAIManager:OnHomePlantGuardJustConfirm()
  self._homePlantGuardJustConfirm = ZoneServer:GetServerTime()
end

function SceneAIManager:ApplyRelationship(domainId, relId, relType, ...)
  UE.UCellAIHelper.CreateRelationship(nil, domainId, relId, relType, {
    ...
  })
end

function SceneAIManager:ClearRelationship(domainId, relId)
  UE.UCellAIHelper.ClearRelationship(nil, domainId, relId or 0)
end

function SceneAIManager.MakeHabitatRelationId(fromHab, toHab, relType)
  return fromHab << 48 | toHab << 32 | relType << 16
end

function SceneAIManager:OnHabitatNeighborInfoChange(action)
  if action.del_habitat_ids then
    for _, habitat_id in ipairs(action.del_habitat_ids) do
      local habConf = _G.DataConfigManager:GetHabitatConf(habitat_id)
      local prevData = self.HabitatRelationMap[habitat_id]
      if habConf and prevData then
        local domainId = habConf.belong_camp | 4294967296
        self:RemoveNeighborRelation(domainId, habitat_id, prevData.first_neighbor)
        self:RemoveNeighborRelation(domainId, habitat_id, prevData.second_neighbor)
        self.HabitatRelationMap[habitat_id] = nil
      end
    end
  end
  if action.change_habitat_neighbor_datas and action.change_habitat_neighbor_datas.habitat_neighbor_datas then
    for _, changedHab in ipairs(action.change_habitat_neighbor_datas.habitat_neighbor_datas) do
      local habConf = _G.DataConfigManager:GetHabitatConf(changedHab.habitat_id)
      if habConf then
        local domainId = habConf.belong_camp | 4294967296
        local habId = changedHab.habitat_id
        local matched_first_neighbor = false
        local matched_second_neighbor = false
        local prevData = self.HabitatRelationMap[habId]
        if prevData then
          if prevData.first_neighbor then
            if changedHab.first_neighbor and prevData.first_neighbor.habitat_id == changedHab.first_neighbor.habitat_id then
              matched_first_neighbor = true
            else
              self:RemoveNeighborRelation(domainId, habId, prevData.first_neighbor)
            end
          end
          if prevData.second_neighbor then
            if changedHab.second_neighbor and prevData.second_neighbor.habitat_id == changedHab.second_neighbor.habitat_id then
              matched_second_neighbor = true
            else
              self:RemoveNeighborRelation(domainId, habId, prevData.second_neighbor)
            end
          end
        end
        if not matched_first_neighbor then
          self:AddNeighborRelation(domainId, habId, changedHab.first_neighbor)
        end
        if not matched_second_neighbor then
          self:AddNeighborRelation(domainId, habId, changedHab.second_neighbor)
        end
        self:UpdateRestraintBlackboard(habId, changedHab.first_neighbor, changedHab.second_neighbor)
        self.HabitatRelationMap[changedHab.habitat_id] = changedHab
      else
      end
    end
  end
end

function SceneAIManager:OnAllHabitatNeighborInfoChange(action)
  local domainToClear = {}
  for habitat_id, _ in pairs(self.HabitatRelationMap) do
    local habConf = _G.DataConfigManager:GetHabitatConf(habitat_id)
    if habConf then
      local domainId = habConf.belong_camp | 4294967296
      domainToClear[domainId] = true
    end
  end
  for domainId, _ in pairs(domainToClear) do
    self:ClearRelationship(domainId, 0)
  end
  self.HabitatRelationMap = {}
  if not action.all_habitat_neighbor_datas or not action.all_habitat_neighbor_datas.habitat_neighbor_datas then
    return
  end
  for _, habData in ipairs(action.all_habitat_neighbor_datas.habitat_neighbor_datas) do
    local habConf = _G.DataConfigManager:GetHabitatConf(habData.habitat_id)
    if habConf then
      local domainId = habConf.belong_camp | 4294967296
      self:AddNeighborRelation(domainId, habData.habitat_id, habData.first_neighbor)
      self:AddNeighborRelation(domainId, habData.habitat_id, habData.second_neighbor)
      self:UpdateRestraintBlackboard(habData.habitat_id, habData.first_neighbor, habData.second_neighbor)
      self.HabitatRelationMap[habData.habitat_id] = habData
    end
  end
end

function SceneAIManager:AddNeighborRelation(domainId, habitatId, neighborData)
  if not neighborData or not neighborData.restrain_relation then
    return
  end
  for _, relType in ipairs(neighborData.restrain_relation) do
    self:ApplyRelationship(domainId, self.MakeHabitatRelationId(habitatId, neighborData.habitat_id, relType), relType, habitatId, neighborData.habitat_id)
  end
end

function SceneAIManager:RemoveNeighborRelation(domainId, habitatId, neighborData)
  if not neighborData or not neighborData.restrain_relation then
    return
  end
  for _, relType in ipairs(neighborData.restrain_relation) do
    self:ClearRelationship(domainId, self.MakeHabitatRelationId(habitatId, neighborData.habitat_id, relType))
  end
end

function SceneAIManager:UpdateRestraintBlackboard(habitatId, FirstNeighborData, SecondNeighborData)
  local firstType = 0
  if FirstNeighborData and FirstNeighborData.restrain_relation then
    for _, relType in ipairs(FirstNeighborData.restrain_relation) do
      if relType > 1 and relType < 5 then
        firstType = relType
        break
      end
    end
  end
  local secondType = 0
  if SecondNeighborData and SecondNeighborData.restrain_relation then
    for _, relType in ipairs(SecondNeighborData.restrain_relation) do
      if relType > 1 and relType < 5 then
        secondType = relType
        break
      end
    end
  end
  UE.UUnitAIHelper.SetBatchBlackboardValueInt(nil, _G.AIDefines.DotsBatchFilterType.COLLECTION, habitatId, _G.AIDefines.DotsBlackboardKeyBundle.RestraintNeighbors, {firstType, secondType})
end

function SceneAIManager:LLMPETSCheckAvailable(npc)
  local AIComp = npc and npc.AIComponent
  if AIComp then
    return AIComp:IsAILoaded() and not AIComp:IsLocked()
  end
  return false
end

function SceneAIManager:LLMPETSQueryPets(action)
  Log.PrintScreenMsg("[SceneAI:LLM] BeginQuery")
  if not action or not action.pet_gid then
    return
  end
  local npcDic = self.module._npcDic
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local thrownPets = self.module:GetPetByPlayer(localPlayer.serverData.base.actor_id or 0)
  if not thrownPets or 0 == #thrownPets then
    return
  end
  local req = ProtoMessage:newZoneLlmPetsAvailablePetsReq()
  for _, actor_id in ipairs(thrownPets) do
    local npc = npcDic[actor_id]
    if npc and self:LLMPETSCheckAvailable(npc) then
      local serverData = npc.serverData
      local pet_info = serverData and serverData.pet_info
      if pet_info and table.contains(action.pet_gid, pet_info.gid) then
        Log.PrintScreenMsg("[SceneAI:LLM] %s \229\135\134\229\164\135\229\165\189\232\167\166\229\143\145LLM\229\147\141\229\186\148\228\186\134", npc.config.name)
        local newInfo = ProtoMessage:newLLM_PETS_FollowPetInfo()
        newInfo.npc_actor_id = npc:GetServerId()
        npc:GetServerPosition(newInfo.pos)
        table.insert(req.pets, newInfo)
      end
    end
  end
  if 0 == #req.pets then
    Log.PrintScreenMsg("[SceneAI:LLM]\230\137\190\228\184\141\229\136\176\229\143\175\228\187\165\232\167\166\229\143\145LLM\229\147\141\229\186\148\231\154\132\231\178\190\231\129\181")
    return
  end
  ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_LLM_PETS_AVAILABLE_PETS_REQ, req, false, false, true)
end

function SceneAIManager:LLMPETSBehaviorNotify(action)
  if not action or not action.behaviors then
    return
  end
  local npcDic = self.module._npcDic
  for _, behavior in ipairs(action.behaviors) do
    local actor_id = behavior.npc_actor_id or 0
    local npc = npcDic[actor_id]
    local AIComp = npc and npc.AIComponent
    if AIComp and behavior.behavior_group_infos then
      local sequal_bahavior_group_id = {}
      local text_message, text_emoji
      for _, behavior_info in ipairs(behavior.behavior_group_infos) do
        local behavior_id = behavior_info.llm_pet_behavior_id
        local behavior_conf = behavior_id and DataConfigManager:GetLlmPetBehaviorConf(behavior_id)
        if nil == text_message and not string.IsNilOrEmpty(behavior_info.world_text) then
          text_message = behavior_info.world_text
        end
        if nil == text_emoji and not string.IsNilOrEmpty(behavior_info.emoji_text) then
          text_emoji = behavior_info.emoji_text
        end
        if behavior_conf and behavior_conf.ai_behavior_group_id then
          table.insert(sequal_bahavior_group_id, behavior_conf.ai_behavior_group_id)
        else
          Log.PrintScreenMsg("[SceneAI:LLM] \229\188\130\229\184\184\239\188\140\230\137\190\228\184\141\229\136\176\232\161\140\228\184\186\231\187\132 %s -> %d", npc.config.name, behavior_id)
        end
      end
      if #sequal_bahavior_group_id > 0 then
        local Controller = AIComp:GetControllerSafe()
        if Controller then
          if text_message then
            Controller:SetDotsCommonString("Global_LlmPetMessage", text_message)
          end
          if text_emoji then
            Controller:SetDotsCommonString("Global_LlmPetEmoji", text_emoji)
          end
          Controller:AppendNextOverrideCommonString("Global_LlmPetBehaviorId", action.request_id)
        end
        AIComp:OverrideBehaviorWithSequal(sequal_bahavior_group_id, Enum.BehaviorOverridePriority.BOP_C, 1)
        Log.DebugFunc(function()
          return string.format("[SceneAI:LLM] \230\136\144\229\138\159\229\164\141\229\134\153: %s -> %s | t=%s | e=%s", npc.config.name, table.concat(sequal_bahavior_group_id, ","), text_message, text_emoji)
        end)
      end
    end
  end
end

function SceneAIManager:LLMPETSDebug(action)
  self.LlmDebugData = action
end

return SceneAIManager
