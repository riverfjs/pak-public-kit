local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local PetStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusComponent")
local SocketSnapComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.SocketSnapComponent")
local InteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.InteractionComponent")
local BezierFlyComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.BezierFlyComponent")
local AttackComponent = require("NewRoco.Modules.Core.Scene.Component.Attack.AttackComponent")
local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local BornDieComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.BornDieComponent")
local LockIndicatorComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.LockIndicatorComponent")
local PendantComponent = require("NewRoco.Modules.Core.Scene.Component.Pendant.PendantComponent")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local StunComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.StunComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Lua_NPCBaseHandy = require("NewRoco.Modules.Core.NPC.Lua_NPCBaseHandy")
local Lua_PEO_Scene = require("NewRoco.Modules.Core.NPC.Lua_PEO_Scene")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local PetInteractOptionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetInteractOptionComponent")
local SyncNpcActionComponent = require("NewRoco.Modules.Core.Scene.Component.Sync.SyncNpcActionComponent")
local SyncPetActionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SyncPetActionComponent")
local PotentialEnergyComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PotentialEnergyComponent")
local LegendaryBattleComponent = require("NewRoco.Modules.Core.Scene.Component.LegendaryBattleComponent")
local CreateMagicComponent = require("NewRoco.Modules.System.MagicCreation.CreateMagicComponent")
local MessageMagicComponent = require("NewRoco.Modules.System.MagicMessage.MessageMagicComponent")
local ViewNPCBase = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local AIDefines = require("NewRoco.AI.AIDefines")
local Array = require("Utils.Array")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local MiniGameModuleEvent = require("NewRoco.Modules.System.MiniGame.MiniGameModuleEvent")
local WorldCombatResLoadComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatResLoadComponent")
local SceneModuleCmd = require("NewRoco.Modules.Core.Scene.SceneModuleCmd")
local PlayerCompassComponent = require("NewRoco.Modules.Core.Scene.Component.PlayerShow.PlayerCompassComponent")
local WorldCombatStatus = require("NewRoco.Modules.System.WorldCombat.WorldCombatStatus")
local AuraSyncCheckComponent = require("NewRoco.Modules.Core.Scene.Component.Aura.AuraSyncCheckComponent")
local HomePetFeedStatusComponent = require("NewRoco.Modules.System.Home.HomePetFeed.HomePetFeedStatusComponent")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local OwlStarNotificationComponent = require("NewRoco.Modules.Core.Scene.Component.OwlStarNotification.OwlStarNotificationComponent")
local NpcStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.NpcStatusComponent")
local AudioCustomSettingComponent = require("NewRoco.Modules.Core.Scene.Component.Audio.AudioCustomSettingComponent")
local FarmConst = require("NewRoco.Modules.System.Farm.FarmConst")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local NPCTrailComponent = require("NewRoco.Modules.Core.Scene.Component.Collision.NPCTrailComponent")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local ScaleTransformComponent = require("NewRoco.Modules.Core.Scene.Component.Transform.ScaleTransformComponent")
local NRCModeManager = _G.NRCModeManager
local NPCBaseCommon = UE.NPCBaseCommon

local function GetSquaredGlobalConf(key, default)
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local conf = _G.DataConfigManager:GetGlobalConfigByKeyType(key, confID)
  if not conf then
    return default or 100
  end
  local num = conf.num
  return num
end

local PetInteractRange = GetSquaredGlobalConf("pet_interact_range")
local PetBattleRange = GetSquaredGlobalConf("pet_fight_range")
PetInteractRange = PetInteractRange * PetInteractRange
PetBattleRange = PetBattleRange * PetBattleRange
local VisibleRange1Sqr = GetSquaredGlobalConf("visible_range_1")
local VisibleRange2Sqr = GetSquaredGlobalConf("visible_range_2")
local VisibleRange3Sqr = GetSquaredGlobalConf("visible_range_3")
local VisibleRange11Sqr = GetSquaredGlobalConf("visible_range_11")
local VisibleRange12Sqr = GetSquaredGlobalConf("visible_range_12")
local VisibleRange13Sqr = GetSquaredGlobalConf("visible_range_13")
local VisibleRange14Sqr = GetSquaredGlobalConf("visible_range_14")
local sqrMap = {
  [0] = VisibleRange1Sqr * VisibleRange1Sqr,
  [1] = VisibleRange1Sqr * VisibleRange1Sqr,
  [2] = VisibleRange2Sqr * VisibleRange2Sqr,
  [3] = VisibleRange3Sqr * VisibleRange3Sqr,
  [11] = VisibleRange11Sqr * VisibleRange11Sqr,
  [12] = VisibleRange12Sqr * VisibleRange12Sqr,
  [13] = VisibleRange13Sqr * VisibleRange13Sqr,
  [14] = VisibleRange14Sqr * VisibleRange14Sqr
}
local squareRootMap = {
  [0] = VisibleRange1Sqr,
  [1] = VisibleRange1Sqr,
  [2] = VisibleRange2Sqr,
  [3] = VisibleRange3Sqr,
  [11] = VisibleRange11Sqr,
  [12] = VisibleRange12Sqr,
  [13] = VisibleRange13Sqr,
  [14] = VisibleRange14Sqr
}
local CollectTimeConf = _G.DataConfigManager:GetNpcGlobalConfig("drop_npc_auto_interact_time")
local CollectTimeout = (CollectTimeConf and CollectTimeConf.num or 10) * 1000
local NightmareScaleConf = _G.DataConfigManager:GetNpcGlobalConfig("random_nightmare_elite_scale_fix")
local NightmareScale = (NightmareScaleConf and NightmareScaleConf.num or 100) / 100.0
local Base = require("NewRoco.Modules.Core.Scene.Actor.SceneCharacter")
local SceneNpc = Base:Extend("SceneNpc", 128)
local VisualizeInteractionCheck = false
SceneNpc:SetMemberCount(64)

function SceneNpc:PreCtor(module)
  Base.PreCtor(self, module)
  self.viewObj = false
  self.isDestroy = false
  self.bulkyVisible = false
  self.bNeedPosAdjust = false
  self.canTriggerInteraction = true
  self.distanceRatio = 10
  self._distanceTimer = math.rand(0, 0.5)
  self.distanceOptLodTime = 0.5
  self.belongArea = nil
  self.customDepthStack = Array(1)
  self.customDepthMap = table.new(0, 1)
  self.Watch = false
  self.updateEnable = true
  self.isUnlock = true
  self.bCreateFromSrcNpc = false
  self.bDisappearPerform = false
  self.PlaceableId = nil
  self.DisappearSkillPath = ""
  self.DisappearSkillTarget = nil
  self.ThrowSession = nil
  self.isAimed = false
  self.bShowAimedLv = false
  self.hideTrackMark = false
  self.bHasCachedCustomDepth = false
  self.CachedCustomDepth = nil
  self.hiddenFlag = 0
  self.collisionDisableFlag = 0
  self.loadDisableFlag = 0
  self.visibility = true
  self.npcEnableCollision = true
  self.npcEnableLoadRes = true
  self.npcEnableCollisionChannelPawn = true
  self.firstTickEver = true
  self.shouldDestroy = false
  self.PlayerForwardDotCache = 1
  self.serverPos = UE.FVector(0, 0, 0)
  self.landPos = UE.FVector(0, 0, 0)
  self.DelayId = 0
  self.modelConf = nil
  self.contentConf = nil
  self.bIsCharacterBased = nil
  self.tracked = false
  self.custom_priority = -1
  self.ParentNPCRefreshContentID = nil
  self.DestroyModelOnCallbackIfNpcDestroyed = true
end

function SceneNpc:Ctor(module)
  Base.Ctor(self, module)
end

function SceneNpc:SetUpdateEnable(flag)
  self.updateEnable = flag
end

function SceneNpc:SetViewObj(viewObj)
  Base.SetViewObj(self, viewObj)
  self:InitOwner()
  if self.bHasCachedCustomDepth then
    self:SetCustomDepthInner(self.CachedCustomDepth)
  end
  if viewObj and 0 ~= self.BuffSpeedScale and 1 ~= self.BuffSpeedScale then
    viewObj.CustomTimeDilation = self.BuffSpeedScale
  end
  if viewObj and self.ThrowSession then
    viewObj:SetThrowSession(self.ThrowSession)
  end
  if RocoEnv.IS_EDITOR and viewObj then
    if viewObj.runtimeCreate then
      viewObj:SetFolderPath("SceneNpc/Runtime")
    else
      viewObj:SetFolderPath("SceneNpc")
    end
  end
end

function SceneNpc:OnDestroyedByEngine()
  Base.OnDestroyedByEngine(self)
  if self.serverData then
    local serverId = self.serverData.base.actor_id
    Log.Error("SceneNpc was destroyed by engine ", self:DebugNPCNameAndID())
    Log.Dump(self.serverData, 3, "SceneNpc:OnDestroyedByEngine")
    self.module:RemoveNpc(serverId, true)
  elseif self.ThrowSession then
    self.module:DeleteLocalNPC(self)
  end
end

function SceneNpc:DebugNPCID()
  local serverId = self.serverData.base.actor_id
  return string.format("%u %d", serverId, serverId)
end

function SceneNpc:DebugNPCNameAndID()
  if self.serverData then
    local serverId = self.serverData.base.actor_id
    return string.format("%s %u %d %d", self.config.name, serverId, serverId, self:GetContentId())
  elseif self.ThrowSession then
    return string.format("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: %s %d", self.config.name, self.ThrowSession.SeqID)
  else
    return self.config.name
  end
end

function SceneNpc:DebugDetail()
  if self.viewObj then
    self.viewObj:DebugDetail()
  end
end

function SceneNpc:DebugByServerID(id, ...)
  if self.serverData then
    local serverId = self.serverData.base.actor_id
    if serverId == id then
      Log.Debug(...)
    end
  end
end

function SceneNpc:InitWithNpcInfo(npcInfo)
  local npcConfig = _G.DataConfigManager:GetNpcConf(npcInfo.npc_base.npc_cfg_id)
  if npcConfig then
    self:InitData(npcConfig, npcInfo)
  else
    Log.Error("NPC\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\154", npcInfo.npc_base.npc_cfg_id)
    Log.Dump(npcInfo)
  end
end

function SceneNpc:InitData(config, serverData)
  Base.InitData(self, config, serverData)
  self.distanceRatio = self:GetDistanceRatio()
  if nil == config then
    Log.Error("\230\137\190\228\184\141\229\136\176NPC\233\133\141\231\189\174", serverData.npc_base.npc_cfg_id)
    return
  end
  local ConfName = config.name
  local ServerName = serverData.base.name
  if string.IsNilOrEmpty(ServerName) then
    serverData.base.name = ConfName
  end
  self.modelConf = _G.DataConfigManager:GetModelConf(self.config.model_conf)
  if not self.modelConf then
    Log.Error("\230\137\190\228\184\141\229\136\176ModelConf", self.config.id, self.config.model_conf)
    return
  end
  local Pos = serverData.base.pt.pos
  self.serverPos:Set(Pos.x, Pos.y, (Pos.z or 0) + 0.001)
  self.landPos:Set(Pos.x, Pos.y, (Pos.z or 0) + 0.001)
  local MiscInfo = serverData.misc_info
  if MiscInfo then
    self:BatchApplyFlags(MiscInfo.cannot_be_seen, MiscInfo.npc_hide_flag)
  end
  local npc_content_id = serverData.npc_base.npc_content_cfg_id
  local npc_content_conf = _G.DataConfigManager:GetNpcRefreshContentConf(npc_content_id, true)
  if npc_content_conf then
    self.contentConf = npc_content_conf
  end
  if not SceneUtils.debugCloseCreateNPCComp then
    self:InitComponent()
  end
  if npc_content_conf and npc_content_conf.visible_during_perception then
    self:SetVisibleForPerceptionReason(false)
  else
    self:SetVisibleForPerceptionReason(true)
  end
  if npc_content_conf then
    if npc_content_conf.visible_during_nightmare then
      _G.NRCEventCenter:RegisterEvent(ConfName, self, MiniGameModuleEvent.Start, self.MiniGameStart)
      _G.NRCEventCenter:RegisterEvent(ConfName, self, MiniGameModuleEvent.End, self.MiniGameEnd)
      if not _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsInNightmare) then
        self:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
      else
        self:SetVisibleForReason(true, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
      end
    end
    if npc_content_conf.refresh_delaytime and 0 ~= npc_content_conf.refresh_delaytime then
      self:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.ANY)
      self.DelayId = _G.DelayManager:DelaySeconds(npc_content_conf.refresh_delaytime / 1000, self.SetVisibleForDelay, self, true)
    end
  end
  if self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    _G.NRCEventCenter:DispatchEvent(_G.WorldCombatModuleEvent.BossInited, self)
  end
end

function SceneNpc:SetVisibleForDelay(visible)
  self:SetVisible(visible)
end

function SceneNpc:SetNotDestroyFlag(notDestroyFlag)
  local Flag = self.notDestroyFlag and not notDestroyFlag
  if Flag then
    local LoadQueue = self.luaObj and self.luaObj.ChildLoadQueue
    if LoadQueue and LoadQueue:IsLoading() then
      Log.Error("\229\135\134\229\164\135\233\148\128\230\175\129\231\154\132\229\175\185\232\177\161\230\173\163\229\156\168\231\173\137\229\190\133\229\173\144\229\175\185\232\177\161\229\138\160\232\189\189\229\174\140\230\136\144!", self:DebugNPCNameAndID())
      self.notDestroyFlag = true
      return
    end
  end
  if Flag and self.shouldDestroy then
    self.notDestroyFlag = notDestroyFlag
    if self.viewObj and self.viewObj.OnShouldDestroy then
    else
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, self.serverData.base.actor_id)
    end
  else
    self.notDestroyFlag = notDestroyFlag
  end
end

function SceneNpc:UpdateLevel(newLevel)
  Base.UpdateLevel(self, newLevel)
  newLevel = newLevel or 0
  if self.PetHUDComponent then
    self.PetHUDComponent:OnLevelChange(newLevel)
  end
  if self.luaObj then
    self.luaObj:OnLevelChange(newLevel)
  end
end

function SceneNpc:UpdateHp(newHp)
  if self.serverData then
    self.serverData.attrs.hp = newHp
  end
end

function SceneNpc:UpdateHpMax(newHpMax)
  if self.serverData then
    self.serverData.attrs.hp_max = newHpMax
  end
end

function SceneNpc:UpdateSizeScale(newSizeScale)
  if not newSizeScale or newSizeScale <= 0 then
    return
  end
  if self.serverData and self.serverData.misc_info then
    self.serverData.misc_info.size_scale = newSizeScale
  end
  local finalScale = self:GetFinalScale()
  local scaleTransformComponent = self:EnsureComponent(ScaleTransformComponent)
  if scaleTransformComponent then
    scaleTransformComponent:SetCustomScale(finalScale, 0.3, false, true)
  end
end

function SceneNpc:GetActorLocation()
  if self.viewObj and UE4.UObject.IsValid(self.viewObj) then
    return self.viewObj:Abs_K2_GetActorLocation()
  end
  return self.landPos
end

function SceneNpc:GetNearLocation()
  if self.viewObj and UE4.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetNearLocation()
  else
    return self.landPos
  end
end

function SceneNpc:IsHomeNpc()
  if self.config and self.config.npc_role_type and self.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME and self.serverData.home_pet and self.serverData.home_pet.home_pet_info.furniture_guid and 0 ~= self.serverData.home_pet.home_pet_info.furniture_guid then
    return true
  end
  return false
end

function SceneNpc:InitComponent()
  local ServerData = self.serverData
  local ActorBase = ServerData and ServerData.base
  local NPCBase = ServerData and ServerData.npc_base
  if ServerData and ServerData.npc_interact then
    self:EnsureComponent(InteractionComponent)
  end
  if self.config.min_map_disappear and self.config.min_map_disappear > 0 then
    self:EnsureComponent(OwlStarNotificationComponent)
  end
  local CharacterBaseNPC = self:IsCharacterBased()
  if CharacterBaseNPC then
    self:InitCharacterComponents()
  else
    if not SceneUtils.debugCloseCreateAIComp then
      local ai_config_valid = not string.IsNilOrEmpty(self.config.mf_behavior_tree) or self.config.ai_perform_group and 0 ~= self.config.ai_perform_group
      if ai_config_valid then
        self:EnsureComponent(AIComponent)
      end
    end
    if ServerData and ServerData.potential_energy_info then
      self:EnsureComponent(PotentialEnergyComponent)
    end
    if ServerData and ServerData.property_type_info then
      self:EnsureComponent(PotentialEnergyComponent)
    end
  end
  if ServerData then
    if ActorBase and ActorBase.born_die_info then
      self:EnsureComponent(BornDieComponent)
    end
    if NPCBase and NPCBase.world_hide and NPCBase.world_hide ~= Enum.WorldHide.WH_NONE then
      self:EnsureComponent(HiddenComponent)
    end
    local AIInfo = ServerData.ai_info
    local AIMoveInfo = AIInfo and AIInfo.ai_move_info
    local StickToInfo = AIMoveInfo and AIMoveInfo.stick_to_info
    if StickToInfo and StickToInfo.target_actor_id then
      self:EnsureComponent(SocketSnapComponent, true)
    end
    if ServerData.pet_info and ServerData.pet_info.gid then
      self:EnsureComponent(PetStatusComponent)
    end
    if ServerData.pendant_info and #ServerData.pendant_info > 0 then
      self:EnsureComponent(PendantComponent)
    end
    if CreateMagicComponent.ShouldCreate(self) then
      self:EnsureComponent(CreateMagicComponent)
    end
    if MessageMagicComponent.ShouldCreate(self) then
      self:EnsureComponent(MessageMagicComponent)
    end
  end
  if self.config.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT then
    self:EnsureComponent(LegendaryBattleComponent)
  end
  if self.config.genre == Enum.ClientNpcType.CNT_PETBOSS or self.config.genre == Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
    self:EnsureComponent(WorldCombatResLoadComponent)
  end
  if self:ShouldEnableAuraSyncCheck() then
    self:EnsureComponent(AuraSyncCheckComponent)
  end
  if self:IsFarmLandNpc() then
    self:EnsureComponent(PetHUDComponent)
  end
  if self.config.title_icon_path ~= "" then
    self:EnsureComponent(PetHUDComponent)
  end
  self:EnsureComponent(AudioCustomSettingComponent)
  local npc_trampling_lawn_comp = NPCTrailComponent.GetTramplingLawnComp(self.config)
  if npc_trampling_lawn_comp and 0 ~= npc_trampling_lawn_comp then
    self:EnsureComponent(NPCTrailComponent, npc_trampling_lawn_comp)
  end
  Base.InitComponent(self)
  if not CharacterBaseNPC then
    local Locked = self:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_LOCKED)
    if Locked or ServerData.combine_lock then
      self:EnsureComponent(LockIndicatorComponent)
    end
  end
  if ServerData and HomeIndoorSandbox then
    HomeIndoorSandbox.Utils.EnsureHomeNpcComponents(self)
  end
end

function SceneNpc:InitCharacterComponents()
  if not SceneUtils.debugCloseCreateAIComp then
    self:EnsureComponent(AIComponent)
  end
  if not SceneUtils.debugCloseCreateHUDComp then
    self:EnsureComponent(PetHUDComponent)
  end
  if self:IsHomeNpc() then
    self:EnsureComponent(HomePetFeedStatusComponent)
  end
end

function SceneNpc:EnterBattle()
  if self.HiddenComponent then
    self.HiddenComponent:EnterBattle()
  end
  local StunComp = self:EnsureComponent(StunComponent)
  if StunComp then
    StunComp:StopStun(true)
  end
end

function SceneNpc:LeaveBattle()
  if self.HiddenComponent then
    self.HiddenComponent:LeaveBattle()
  end
  local StunComp = self:EnsureComponent(StunComponent)
  if StunComp then
    StunComp:LeaveBattle()
  end
end

function SceneNpc:FixCoord()
  local meshComponent = SceneUtils.GetActorMesh(self.viewObj)
  local bSimulatePhysics = false
  if meshComponent then
    bSimulatePhysics = meshComponent.BodyInstance.bSimulatePhysics
  end
  if not bSimulatePhysics and 1 == self.config.lock_on_ground then
    self.landPos = SceneUtils.GetPosInNearLand(self.serverPos, 0) or self.landPos
    local landPos = self.landPos
    local debugStart
    if SceneUtils.debugCoordFix then
      debugStart = UE4.FVector(landPos.X, landPos.Y, landPos.Z)
    end
    landPos.Z = landPos.Z + self:GetHalfHeight()
    if SceneUtils.debugCoordFix then
      local debugEnd = UE4.FVector(landPos.X, landPos.Y, landPos.Z)
      Log.Debug("NPC Fixcoord Debug", self:DebugNPCNameAndID())
      Log.Debug(debugStart.X, debugStart.Y, debugStart.Z)
      Log.Debug(debugEnd.X, debugEnd.Y, debugEnd.Z)
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), debugStart, debugEnd, UE4.FLinearColor(1, 0, 0, 1), 100)
    end
    self.serverPos = landPos
    self.viewObj:SetActorLocation(landPos)
  end
end

function SceneNpc:FindBattleNPC()
  local p1 = self:GetActorLocation()
  local battleNpc
  local battleDist = PetInteractRange + 1
  for _, v in pairs(self.module._npcIterDic) do
    local battle = v.config.throwing_interact_type == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
    if not battle then
    else
      local p2 = v:GetActorLocation()
      local subx = p1.X - p2.X
      local suby = p1.Y - p2.Y
      local sqr = subx * subx + suby * suby
      if sqr > PetInteractRange then
      elseif battleDist > sqr and v.InteractionComponent:CanBattle() then
        battleNpc = v
        battleDist = sqr
      end
    end
  end
  return battleNpc
end

function SceneNpc:CanSee(Character)
  local View = self.viewObj
  if not View then
    return false
  end
  if not Character then
    return false
  end
  local OtherView = Character.viewObj
  if not OtherView then
    return false
  end
  if self.CachedStartPos then
    self.CachedStartPos.X = 0
    self.CachedStartPos.Y = 0
    self.CachedStartPos.Z = 0
  else
    self.CachedStartPos = UE4.FVector()
  end
  if self.CachedEndPos then
    self.CachedEndPos.X = 0
    self.CachedEndPos.Y = 0
    self.CachedEndPos.Z = 0
  else
    self.CachedEndPos = UE4.FVector()
  end
  local StartPos = self.CachedStartPos
  local EndPos = self.CachedEndPos
  View:GetActorBounds(true, StartPos, nil, false)
  OtherView:GetActorBounds(true, EndPos, nil, false)
  if not self.CachedIgnoreActor then
    self.CachedIgnoreActor = {}
  end
  table.insert(self.CachedIgnoreActor, View)
  table.insert(self.CachedIgnoreActor, OtherView)
  local DebugTrace = VisualizeInteractionCheck and UE.EDrawDebugTrace.Persistent or UE.EDrawDebugTrace.None
  local HitResult, Success = UE4.UKismetSystemLibrary.SphereTraceSingle(View, StartPos, EndPos, 5, UE.ETraceTypeQuery.Visibility, false, self.CachedIgnoreActor, DebugTrace, nil, true)
  table.clear(self.CachedIgnoreActor)
  if Success and HitResult.Actor then
    local ActorName = HitResult.Actor:GetName()
    if VisualizeInteractionCheck then
      Log.Error("Show Actor Name", ActorName)
    end
    local SurfaceType = UE.UNRCStatics.GetSurfaceType(HitResult)
    if SurfaceType == UE.EPhysicalSurface.SurfaceType2 then
      return true
    end
  end
  return not Success
end

function SceneNpc:CreateLuaObj()
  local luaPath
  if not self.modelConf then
    Log.Error("SceneNpc:CreateLuaObj modelConf is nil")
  else
    luaPath = self.modelConf.lua_class
  end
  if luaPath then
    self.luaObj = require(luaPath)()
  else
    local defPath
    if self.modelConf then
      defPath = self.GetDefaultLuaObjPathByBP(self.modelConf.path)
    end
    if defPath then
      self.luaObj = require(defPath)()
    else
      self.luaObj = Lua_NPCBaseHandy()
    end
  end
  self.luaObj:SetSceneCharacter(self)
  self.luaObj:LuaBeginPlay()
end

function SceneNpc.GetDefaultLuaObjPathByBP(BlueprintClass)
  if string.IsNilOrEmpty(BlueprintClass) then
    return nil
  end
  if string.StartsWith(BlueprintClass, "Blueprint'/Game/ArtRes/BP/Scene/") then
    return "NewRoco.Modules.Core.NPC.Lua_PEO_Scene"
  end
  if string.StartsWith(BlueprintClass, "Blueprint'/Game/ArtRes/BP/Pets/") then
    return "NewRoco.Modules.Core.NPC.Lua_NPCCharacter"
  end
  if string.StartsWith(BlueprintClass, "Blueprint'/Game/NewRoco/Modules/Core/NPC/Element_Interact") then
    return "NewRoco.Modules.Core.NPC.Torch.Lua_ElementInteract_General"
  end
  return nil
end

function SceneNpc:IsCharacterBased()
  if self.bIsCharacterBased ~= nil then
    return self.bIsCharacterBased
  end
  local Path = self.modelConf.path
  if string.IsNilOrEmpty(Path) then
    self.bIsCharacterBased = false
    return false
  end
  if string.StartsWith(Path, "Blueprint'/Game/ArtRes/BP/Scene/") then
    self.bIsCharacterBased = true
    return true
  end
  if string.StartsWith(Path, "Blueprint'/Game/ArtRes/BP/Pets/") then
    self.bIsCharacterBased = true
    return true
  end
  self.bIsCharacterBased = false
  return false
end

function SceneNpc:IsPet()
  return self.config.traverse_data_type and #self.config.traverse_data_param > 0 and self.config.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE
end

function SceneNpc:IsPetEgg()
  return self.config.traverse_data_type and #self.config.traverse_data_param > 0 and self.config.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_EGGTOPETBASE
end

function SceneNpc:IsFakeMutation()
  return self.config.traverse_data_type and self.config.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_FAKE_MUTATION
end

function SceneNpc:IsHuman()
  return self.luaObj:InstanceOf(Lua_PEO_Scene)
end

function SceneNpc:GetPetbaseId()
  return self.config.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE and self.config.traverse_data_param[1] or 0
end

function SceneNpc:GetConfPetData()
  if self.config.traverse_data_type ~= Enum.Traverse_Data_Type.TDT_PETBASE then
    return nil
  end
  return _G.DataConfigManager:GetPetbaseConf(self.config.traverse_data_param[1] or 0, true)
end

function SceneNpc:IsAThrownPet()
  local pet_info = self.serverData and self.serverData.pet_info
  local gid = pet_info and pet_info.gid
  return gid and 0 ~= gid
end

function SceneNpc:IsAHomePet()
  local home_pet = self.serverData and self.serverData.home_pet
  local home_pet_info = home_pet and home_pet.home_pet_info
  local pet_gid = home_pet_info and home_pet_info.pet_gid
  return pet_gid and 0 ~= pet_gid
end

function SceneNpc:GetNpcRefreshScale()
  if not self.contentConf then
    return 1
  end
  return math.clamp((self.contentConf.model_scale or 100) / 100, 0.001, 100.0)
end

function SceneNpc:GetNpcFarmScale()
  if not (self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id) or 0 == self.serverData.npc_base.home_plant_land_id then
    return 1
  end
  local land_id = self.serverData.npc_base.home_plant_land_id
  if not FarmUtils.IsLandHarvest(land_id) then
    return 1
  end
  local landInfo = FarmUtils.GetLandInfo(land_id)
  if not landInfo then
    return 1
  end
  local growConf = FarmUtils.GetPlantGrowConfByLandId(land_id, landInfo)
  if not growConf then
    return 1
  end
  local growGrade = growConf.plant_grow_grade[landInfo.plant_tab_id]
  if not growGrade then
    return 1
  end
  return math.clamp((growGrade.model_scale or 100) / 100, 0.001, 100.0)
end

function SceneNpc:GetConfigScale()
  local scale1 = math.clamp((self.modelConf.model_scale or 100) / 100, 0.001, 100.0)
  local scale2 = math.clamp((self.config.model_scale or 100) / 100, 0.001, 100.0)
  local scale3 = self:GetNpcRefreshScale()
  local scale4 = self:GetNpcFarmScale()
  local scale = scale1 * scale2 * scale3 * scale4
  return scale
end

function SceneNpc:GetFinalScale()
  local ConfigScale = self:GetConfigScale()
  local heightModelScale = 1
  local serverHeight = self.serverData and self.serverData.npc_base.height_scale
  if serverHeight and serverHeight > 0 and serverHeight < 20 then
    heightModelScale = serverHeight
  elseif self:IsPet() then
    heightModelScale = PetMutationUtils.GetNpcHeightModelScale(self.config, self.serverData.npc_base.height)
  end
  if self.LogicStatusComponent then
    local IsElite, _, _ = self.LogicStatusComponent:GetStatus(Enum.SpaceActorLogicStatus.SALS_NIGHTMARE_ELITE)
    if IsElite then
      heightModelScale = heightModelScale * NightmareScale
    end
  end
  local misc_info = self.serverData and self.serverData.misc_info
  local size_scale_value = misc_info and misc_info.size_scale or 100
  if size_scale_value <= 0 then
    size_scale_value = 100
  end
  local server_size_scale = size_scale_value / 100
  return ConfigScale * heightModelScale * server_size_scale
end

function SceneNpc:OnViewObjGetFromPool(viewObj)
  if not UE4.UObject.IsValid(viewObj) then
    return
  end
  if self.isDestroy and self.DestroyModelOnCallbackIfNpcDestroyed then
    if viewObj.K2_DestroyActor then
      viewObj:K2_DestroyActor()
    end
    return
  end
  if self.serverData and self:IsPet() then
    local petData = {
      mutation_type = self.serverData.npc_base.mutation_type,
      nature = self.serverData.npc_base.nature
    }
    PetMutationUtils.PrepareMutationAssets(viewObj, petData)
    local IsAquatic = false
    local CanStandOnWater = false
    local petBaseId = self:GetPetbaseId()
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if PetBaseConf then
      local modelId = PetBaseConf and PetBaseConf.model_conf or 0
      local modelConf = _G.DataConfigManager:GetModelConf(modelId, true)
      if modelConf then
        if modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_WATER or modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_AQUA then
          CanStandOnWater = true
          IsAquatic = true
        elseif modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_FLY then
          CanStandOnWater = true
          IsAquatic = false
        end
      end
    end
    viewObj:EnableCanStandOnWaterSurface(CanStandOnWater)
    viewObj:SetIsAquatic(IsAquatic)
  end
  if not viewObj.SetSceneCharacter then
    if RocoEnv.IS_EDITOR then
      Log.ErrorFormat("NPC viewObj not has function SetSceneCharacter: %s url %s", viewObj:GetActorLabel(), self.classUrl)
    end
    return
  end
  self.viewObj = viewObj
  self.viewObjRef = UnLua.Ref(viewObj)
  if self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS and self.viewObj.Mesh and UE.UObject.IsValid(self.viewObj.Mesh) then
    self.viewObj.Mesh.bUsePhysicsAsset = true
  end
  viewObj:Init()
  viewObj.runtimeCreate = true
  viewObj:SetSceneCharacter(self)
  viewObj:LuaBeginPlay()
  if viewObj.SetLoadPriority then
    viewObj:SetLoadPriority(self.custom_priority or -1)
  end
  if viewObj.PureBlueprint then
    local pos = self:GetFixedCoordinate(viewObj)
    local rot = self.serverDataRotate
    if pos and rot then
      viewObj:K2_SetActorRotation(rot, false)
      viewObj:Abs_K2_SetActorLocation_WithoutHit(pos, false, false)
      if viewObj.ReleaseVisibleLevel then
        viewObj:ReleaseVisibleLevel()
      end
    end
    return
  end
  self:AdjustModelHeight()
  local pos = self:GetFixedCoordinate(viewObj)
  local rot = self.serverDataRotate
  if pos and rot then
    viewObj:K2_SetActorRotation(rot, false)
    viewObj:Abs_K2_SetActorLocation_WithoutHit(pos, false, false)
    if viewObj.ReleaseVisibleLevel then
      viewObj:ReleaseVisibleLevel()
    end
  end
  self:CalSquaredDis2Local()
  self.distanceRatio = self:GetDistanceRatio()
  self.distanceOptLodTime = self:GetLodTime(self:GetDistanceRatio())
  if self.viewObj and UE.UObject.IsValid(self.viewObj.CharacterMovement) then
    self.viewObj.CharacterMovement.MaxWalkSpeed = self.config.npc_speed
  end
  if self.luaObj then
    self.luaObj:SetViewObj(self.viewObj)
  else
    Log.Error("\230\178\161\230\156\137luaObj")
  end
  self:SetViewObj(self.viewObj)
  local meshComponent = SceneUtils.GetActorMesh(self.viewObj)
  if 1 == self.config.forbid_collision and meshComponent then
    meshComponent:SetCollisionEnabled(UE4.ECollisionEnabled.NoCollision)
  elseif 2 == self.config.forbid_collision then
    self:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.EDITOR_DEFAULT)
  end
  if self:IsMagicReplayActor() then
    self:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.MAGIC_REPLAY)
  end
  if self.serverData and self.serverData.base and self.viewObj then
    if self.viewObj:IsA(UE.ANPCBaseCharacter) then
      UE4.UNRCStatics.SetSixLightingChannels(self.viewObj, true, false, true, false, true, false, false)
    elseif self.viewObj:IsA(UE.ANPCBaseActor) then
      UE4.UNRCStatics.SetSixLightingChannels(self.viewObj, true, false, false, true, false, false, false)
    end
  end
  if not SceneUtils.debugCloseNPCLabel and self.config and self.viewObj and self.viewObj.GetActorLabel and self.serverData then
    if not self.viewObj.defaultLabel then
      self.viewObj.defaultLabel = self.viewObj:GetActorLabel()
    end
    local defaultLabel = self.viewObj.defaultLabel
    local npc_content_cfg_id = self.serverData.npc_base.npc_content_cfg_id
    if npc_content_cfg_id then
      self.viewObj:SetActorLabelNoFlush(string.format("%s-%d-%u", defaultLabel, npc_content_cfg_id, self.serverData.base.actor_id))
    else
      self.viewObj:SetActorLabelNoFlush(string.format("%s-%u", defaultLabel, self.serverData.base.actor_id))
    end
  end
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.UpdateHiddenStatus, self)
  self:UpdateFlags()
  if self.contentConf and not string.IsNilOrEmpty(self.contentConf.Light_BP) then
    SceneUtils.SetupSpotLight(self, self.contentConf.Light_BP)
  end
  self:SendEvent(NPCModuleEvent.VIEW_SHELL_LOADED, self)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.VIEW_SHELL_LOADED, self)
  if self.viewObj and self.viewObj.OnFrameLoad and not SceneUtils.debugCloseNPCOnFrameLoad then
    self.viewObj:OnFrameLoad(self.distanceRatio)
  end
  local npcStatusComponent = self:EnsureComponent(NpcStatusComponent)
  if npcStatusComponent then
    npcStatusComponent:UpdateSignificanceStatus()
  end
  self:ApplyTrackStatus()
  self:ResolveNPCOverlap()
  if _G.MagicReplayModuleCmd and self:IsMagicReplayActor() and self.IsPet and self:IsPet() then
    if self.viewObj then
      self.viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.MagicReplay)
    end
    _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.viewObj)
  end
  if self.config.genre == _G.Enum.ClientNpcType.CNT_BULLET then
    self:OnMissileReConnectCreate()
  end
end

function SceneNpc:ResolveNPCOverlap()
  local npcRefreshCfg = self.contentConf
  local overlap_processing_type = npcRefreshCfg and npcRefreshCfg.overlap_processing_type or _G.Enum.OverLapProcessingType.OLPT_OVERLAP
  local overlapAwareComp = self:EnsureComponent(OverlapAwareVisibilityComponent)
  if overlapAwareComp then
    overlapAwareComp:ResolveNPCOverlap(overlap_processing_type)
  end
end

function SceneNpc:GetFixedCoordinate(viewObj)
  if not self.serverPos then
    self.bCoordinateFixed = false
    return nil
  end
  local halfHeight
  if viewObj then
    if viewObj.GetHalfHeight then
      halfHeight = viewObj:GetHalfHeight()
      self.bCoordinateFixed = true
    else
      halfHeight = 0
    end
  else
    halfHeight = self:GetModelConfHalfHeight()
    self.bCoordinateFixed = false
  end
  local actorPos = UE4.FVector(self.serverPos.X, self.serverPos.Y, self.serverPos.Z + halfHeight)
  return actorPos
end

function SceneNpc:GetModelConfHalfHeight()
  local modelScale = math.clamp((self.modelConf.model_scale or 100) / 100, 0.001, 100.0)
  local modelHalfHeight = (self.modelConf.capsule_halfheight or 1000) / 1000
  return modelScale * modelHalfHeight
end

function SceneNpc:AdjustModelHeight(UseBornPt, NeedFixPos)
  local finalScale = self:GetFinalScale()
  local scaleTransformComponent = self:EnsureComponent(ScaleTransformComponent)
  UseBornPt = UseBornPt and true or false
  NeedFixPos = NeedFixPos and true or false
  scaleTransformComponent:SetCustomScale(finalScale, 0, UseBornPt, NeedFixPos)
  self:SendEvent(NPCModuleEvent.OnNpcMeshAdjusted, self)
end

function SceneNpc:AdjustModelOpacity()
  if not self.viewObj or not UE4.UObject.IsValid(self.viewObj) then
    return
  end
  Log.Info("SceneNpc:AdjustModelOpacity ", self.viewObj:GetName())
  if self.config and self.config.opacity_rate and self.config.opacity_rate > 0 then
    local opacity = math.clamp(self.config.opacity_rate / 10000.0, 0.0, 1.0)
    self.viewObj:SetMeshAlphaOverride(1.0 - opacity)
  else
    self.viewObj:SetMeshAlphaOverride()
  end
end

function SceneNpc:AdjustModelFresnel()
  if not self.viewObj or not UE4.UObject.IsValid(self.viewObj) then
    return
  end
  if not self.config then
    return
  end
  Log.Info("SceneNpc:AdjustModelFresnel ", self.viewObj:GetName())
  local fresnel_color = SceneUtils.ParseStrRGB(self.config.fresnel_color)
  local fresnel_intensity = tonumber(self.config.fresnel_intensity or 0.0) / 10000.0
  local fresnel_exponent = (tonumber(self.config.fresnel_exponent) or 80000.0) / 10000.0
  if fresnel_color and fresnel_intensity and fresnel_intensity > 0 and fresnel_exponent then
    self.viewObj:SetMeshFresnel(fresnel_color, fresnel_intensity, fresnel_exponent)
  else
    self.viewObj:ClearMeshFresnel()
  end
end

function SceneNpc:GetOverrideExpression()
  if not self.serverData then
    return 100
  end
  local NatureID = self.serverData.npc_base and self.serverData.npc_base.nature
  if not NatureID or 0 == NatureID then
    return 100
  end
  local nature = _G.DataConfigManager:GetNatureConf(NatureID)
  if nature then
    return nature.relative_emotion
  end
  return 100
end

local MinPriorityDistance = 4000000
local MaxPriority = _G.PriorityEnum.Passive_World_NPC_Close_BP
local MinPriority = _G.PriorityEnum.Passive_World_NPC_Far_BP

local function GetPriorityByDistance(DistanceSquared)
  DistanceSquared = DistanceSquared or MinPriorityDistance
  local Uniformed = 1 - math.clamp(DistanceSquared / MinPriorityDistance, 0, 1)
  return MinPriority + math.round(Uniformed * (MaxPriority - MinPriority))
end

function SceneNpc:CreateView(block, priority)
  if nil == block then
    block = true
  end
  if self.viewObj then
    Log.Error("SceneNpc:CreateView, \229\175\185\229\183\178\231\187\143\229\173\152\229\156\168view\231\154\132npc\229\143\141\229\164\141\229\136\155\229\187\186view")
    return
  end
  if not self.modelConf then
    Log.Error("SceneNpc:CreateView, modelConf is invalid")
    return
  end
  local url = self.modelConf.path
  self.classUrl = url
  if nil ~= self.PlaceableId and 0 ~= self.PlaceableId then
    local PlaceableId = self.PlaceableId
    Log.Debug("[PlaceableNpc] \229\140\185\233\133\141\229\156\186\230\153\175\231\137\169\228\187\182\228\184\173\239\188\154", self:DebugNPCNameAndID(), PlaceableId)
    if self.module._placeEnteredDic[PlaceableId] and 0 ~= PlaceableId then
      Log.Error("[PlaceableNpc] CreatePlaceableNpc: \229\143\136\229\143\145\230\157\165\228\186\134\228\184\128\228\184\170\231\155\184\229\144\140\231\154\132PlaceableId=", PlaceableId)
      return
    end
    self.module._placeEnteredDic[PlaceableId] = self
    local view = self.module._placeSpawnedDic[PlaceableId]
    if view then
      Log.Debug("[PlaceableNpc] OnCreateView \229\140\185\233\133\141\230\136\144\229\138\159:", self:DebugNPCNameAndID(), PlaceableId)
      NPCLuaUtils.BindNpcViewObj(self, view)
      self:SetVisibleInternal(0 == self.hiddenFlag)
      self:SetCollisionInternal(0 == self.collisionDisableFlag)
    end
    return
  end
  local custom_priority = math.max(priority or -1, self.custom_priority or -1)
  if custom_priority <= 0 then
    if self:IsInitialNPC() then
      custom_priority = _G.PriorityEnum.Passive_World_NPC_Important_BP
    else
      custom_priority = GetPriorityByDistance(self.squaredDis2LocalIgnoreZ)
    end
  end
  self.custom_priority = custom_priority
  self.module.npcActorPool:Get(url, self, block, custom_priority)
end

function SceneNpc:GetBaseInfo()
  local Data = self.serverData
  if not Data then
    return nil
  end
  return Data.base
end

function SceneNpc:GetServerId()
  local BaseInfo = self:GetBaseInfo()
  if not BaseInfo then
    return 0
  end
  return BaseInfo.actor_id or 0
end

function SceneNpc:GetNpcBaseInfo()
  local Data = self.serverData
  if not Data then
    return nil
  end
  return Data.npc_base
end

function SceneNpc:GetContentId()
  local BaseInfo = self:GetNpcBaseInfo()
  if not BaseInfo then
    return 0
  end
  return BaseInfo.npc_content_cfg_id or 0
end

function SceneNpc:GetConfigId()
  return self.config.id
end

function SceneNpc:GetSourceNPCRefreshContentID()
  local NPCBaseInfo = self:GetNpcBaseInfo()
  if not NPCBaseInfo then
    return 0
  end
  local SourceRefreshConfID = NPCBaseInfo.src_npc_ref_cfg_id or 0
  if 0 ~= SourceRefreshConfID then
    return SourceRefreshConfID
  end
  local SourceActorID = NPCBaseInfo.src_npc_id or 0
  if 0 == SourceActorID then
    return 0
  end
  local SourceNPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, SourceActorID)
  if not SourceNPC then
    return 0
  end
  return SourceNPC:GetContentId()
end

function SceneNpc:GetRefreshPointID()
  local BaseInfo = self:GetNpcBaseInfo()
  if not BaseInfo then
    return 0
  end
  return BaseInfo.refresh_point or 0
end

function SceneNpc:GetLogicID()
  local BaseInfo = self:GetBaseInfo()
  if not BaseInfo then
    return 0
  end
  return BaseInfo.logic_id or 0
end

function SceneNpc:GetArea()
  if self.belongArea then
    return self.belongArea
  end
  local npcRefreshCfg = self.contentConf
  if npcRefreshCfg and npcRefreshCfg.patrol_belong_type == Enum.PatrolBelongType.PBT_AREA then
    local mapArea = self.module.MapRegionAreaUtil:GetMapArea(npcRefreshCfg.patrol_param)
    self.belongArea = mapArea
  end
  return self.belongArea
end

function SceneNpc:DestroyModel()
  if not self.luaObj then
    Log.Debug("SceneNpc:DestroyModel no luaObj")
    return
  end
  self.luaObj:OnDestroy()
  if self.PlaceableId ~= nil then
    local viewObj = self.viewObj
    if viewObj then
      viewObj:SetSceneCharacter(nil)
    end
    self.module._placeEnteredDic[self.PlaceableId] = nil
    self.viewObj = nil
    self.viewObjRef = nil
    return
  end
  self.module.npcActorPool:StopWaitClass(self)
  if self.viewObj then
    local viewObj = self.viewObj
    self.module.npcActorPool:PreRecycle(self.classUrl, viewObj)
    self.viewObj = nil
    self.viewObjRef = nil
  end
end

function SceneNpc:Disappear(immediately)
  if self.viewObj then
    if self.bDisappearPerform then
      self.viewObj:PlayDisappearPerform()
    elseif not string.IsNilOrEmpty(self.DisappearSkillPath) then
      self.viewObj:PlayDisappearSkill(self.DisappearSkillPath, self.DisappearSkillTarget)
      self.DisappearSkillTarget = nil
    else
      self:Destroy()
    end
  else
    self:Destroy()
  end
end

function SceneNpc:Destroy()
  Log.Debug("NPC\232\162\171\230\173\163\229\188\143\229\136\160\233\153\164", self:DebugNPCNameAndID())
  self:RemoveLaunchDelegate()
  self:SetUpdateEnable(false)
  _G.NRCModuleManager:DoCmd(SceneModuleCmd.ConsumeCachedActorTag, self:GetServerId())
  self:SendEvent(NPCModuleEvent.On_NPC_Destroy, self)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.On_NPC_Destroy, self)
  Base.Destroy(self)
  if self.ThrowSession then
    self.ThrowSession:RemoveEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStateChange)
    if self.ThrowSession.Status == ThrowSessionStatusEnum.InAir or self.ThrowSession.Status == ThrowSessionStatusEnum.Recycling then
      self.ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if self.contentConf and self.contentConf.visible_during_nightmare then
    _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.Start, self.MiniGameStart)
    _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.End, self.MiniGameEnd)
  end
end

function SceneNpc:CanRotation()
  if self.config then
    local notTurnFace = self.config.not_turn_face
    return 0 == notTurnFace
  end
  return true
end

function SceneNpc:GetBulkyLevel()
  if self.bulky then
    return self.bulky
  end
  if not self.config then
    Log.Error("NPC\231\154\132config\228\184\141\229\173\152\229\156\168")
    return nil
  end
  if not self.config then
    return 1
  end
  if self.config.bulky == nil or 0 == self.config.bulky then
    local modelConf = _G.DataConfigManager:GetModelConf(self.config.model_conf)
    if not modelConf then
      Log.Error("NPC\231\154\132model conf\228\184\141\229\173\152\229\156\168", self:DebugNPCNameAndID())
      return 1
    end
    local scaleRatio = (modelConf.model_scale or 100) / 100 * ((self.config.model_scale or 100) / 100) * self:GetNpcRefreshScale()
    local scale = (modelConf.capsule_halfheight or 1000) / 1000 * scaleRatio * ((modelConf.capsule_radius or 1000) / 1000) * scaleRatio
    if scale >= 0 and scale < 1000 then
      self.bulky = 1
    elseif scale >= 1000 and scale < 5000 then
      self.bulky = 2
    elseif scale >= 5000 and scale < 20000 then
      self.bulky = 3
    else
      self.bulky = 12
    end
  else
    self.bulky = self.config.bulky
  end
  return self.bulky
end

function SceneNpc:GetDistanceRatio()
  local visibleDisSqr
  if SceneUtils.debugDisSqr then
    visibleDisSqr = SceneUtils.debugDisSqr
  else
    visibleDisSqr = sqrMap[self:GetBulkyLevel()] or VisibleRange1Sqr
  end
  return self.squaredDis2LocalIgnoreZ / visibleDisSqr
end

function SceneNpc:GetVisibleDistance()
  local VisibleDistance
  if SceneUtils.debugDisSqr then
    VisibleDistance = SceneUtils.debugDisSqr
  else
    VisibleDistance = squareRootMap[self:GetBulkyLevel()] or VisibleRange1Sqr * 100
  end
  return VisibleDistance
end

function SceneNpc:GetBodySize()
  if not self.config then
    return 500
  end
  local Scale = self:GetConfigScale()
  local Radius = (self.modelConf.capsule_radius or 1000) / 1000
  local HalfHeight = (self.modelConf.capsule_halfheight or 1000) / 1000
  local Volume = Radius * Radius * HalfHeight * Scale * Scale * Scale * 8.0E-6
  return Volume
end

function SceneNpc:CalSquaredDis2Local()
  if self.bNeedPosAdjust then
    self.squaredDis2Local = 200000000
    self.squaredDis2LocalIgnoreZ = 200000000
    self.fowardDotValue = -1
    return 200000000, 200000000
  end
  local PlayerX = 0
  local PlayerY = 0
  local PlayerZ = 0
  PlayerX, PlayerY, PlayerZ, self.squaredDis2Local, self.squaredDis2LocalIgnoreZ, self.fowardDotValue, self.PlayerForwardDotCache = UE.NPCUtils.CalcDist(self.viewObj)
  self.PlayerPosCache.X = PlayerX
  self.PlayerPosCache.Y = PlayerY
  self.PlayerPosCache.Z = PlayerZ
  self.PlayerHeightDiff = math.abs(PlayerZ - self:GetActorLocation().Z)
  return self.squaredDis2Local, self.squaredDis2LocalIgnoreZ
end

function SceneNpc:ChangeNeedPosAdjust(value, bRefreshDistance, bRefreshUpdate)
  local oldValue = self.bNeedPosAdjust
  self.bNeedPosAdjust = value
  if bRefreshDistance and oldValue ~= value then
    self:CalSquaredDis2Local()
    self.distanceOptLodTime = -1
    if bRefreshUpdate then
      self:Update(0.022)
    end
  end
end

function SceneNpc:GetLodTime(distanceRatio)
  if distanceRatio <= 1.3 then
    return 0.5
  elseif distanceRatio <= 2 then
    return math.random(1, 2)
  elseif distanceRatio <= 3 then
    return math.random(3, 4)
  else
    return math.random(5, 7)
  end
end

function SceneNpc:OnThrowStart()
  Log.Debug("SceneNpc:OnThrowStart")
  if self.viewObj and self.viewObj.OnThrowStart then
    self.viewObj:OnThrowStart()
  end
end

function SceneNpc:BlockLoadResource()
  Log.Debug("SceneNpc:BlockLoadResource", self:DebugNPCNameAndID())
  if not self.viewObj then
    self:CreateView(false)
  end
  if not self.viewObj then
    Log.Error("view object\229\136\155\229\187\186\229\164\177\232\180\165\239\188\140\229\143\175\232\131\189\230\152\175\233\133\141\231\189\174\233\148\153\232\175\175")
    return
  end
  self.viewObj:BlockLoadResource()
  self:SetVisibleInternal(0 == self.hiddenFlag)
  self:SetCollisionInternal(0 == self.collisionDisableFlag)
end

function SceneNpc:Update(deltaTime)
  if not self.updateEnable then
    return
  end
  self._distanceTimer = self._distanceTimer + deltaTime
  if self._distanceTimer > self.distanceOptLodTime then
    self:CalSquaredDis2Local()
    if self.viewObj then
      self.distanceRatio = self:GetDistanceRatio()
      self:DistanceOptimize(self.distanceRatio)
    end
    self.module:AdjustNPCDistance(self)
    self._distanceTimer = 0
    self:UpdateLodTime()
  end
  if self.viewObj and self.distanceRatio < 1 then
    Base.UpdateByDistance(self, deltaTime)
  end
end

function SceneNpc:UpdateLodTime()
  self.distanceRatio = self:GetDistanceRatio()
  self.distanceOptLodTime = self:GetLodTime(self.distanceRatio)
end

function SceneNpc:OnPlayerTeleportStart()
  self.InteractionComponent:OnPlayerTeleportStart()
end

function SceneNpc:OnEnterVisit()
  self.InteractionComponent:OnEnterVisit()
end

function SceneNpc:OnLeaveVisit()
  self.InteractionComponent:OnLeaveVisit()
end

function SceneNpc:OnHomeVisitChange()
  self.InteractionComponent:OnHomeVisitChange()
end

function SceneNpc:PauseMove()
  if self.viewObj and self.viewObj.CharacterMovement then
    self.viewObj.CharacterMovement.GravityScale = 0
    self.viewObj.CharacterMovement:SetComponentTickEnabled(false)
  end
end

function SceneNpc:ResumeMove()
  if self.viewObj and self.viewObj.CharacterMovement then
    self.viewObj.CharacterMovement.GravityScale = 1
    self.viewObj.CharacterMovement:SetComponentTickEnabled(true)
  end
end

function SceneNpc:SetMovementMode(mode, custom_mode)
  local moveComp = self.viewObj and self.viewObj.CharacterMovement
  if moveComp then
    moveComp:SetMovementMode(mode, custom_mode)
  end
end

function SceneNpc:LockVisibility(value)
  self.isLockVisibility = value
end

function SceneNpc:SetVisibleInternal(Visible)
  local Changed = self.visibility ~= Visible
  self.visibility = Visible
  if self.viewObj then
    Changed = Changed or Visible == self.viewObj.bHidden
    self.viewObj:SetVisible(Visible)
  end
  if not Changed then
    return
  end
  local hidComp = self.HiddenComponent
  if hidComp then
    hidComp:SetVisible(Visible)
  end
  local hudComp = self.PetHUDComponent
  if hudComp then
    if Visible then
      hudComp:OnVisible()
    else
      hudComp:OnInvisible()
    end
  end
  local InterComp = self.InteractionComponent
  if InterComp then
    InterComp:RefreshOptions()
  end
  local owlStarNotificationComp = self.OwlStarNotificationComponent
  if owlStarNotificationComp then
    if Visible then
      if owlStarNotificationComp.OnVisible then
        owlStarNotificationComp:OnVisible()
      end
    elseif owlStarNotificationComp.OnInvisible then
      owlStarNotificationComp:OnInvisible()
    end
  end
end

function SceneNpc:SetCollisionInternal(CollisionEnable)
  self.npcEnableCollision = CollisionEnable
  if not self.viewObj then
    return
  end
  self.viewObj:SetCollisionEnable(self.npcEnableCollision)
end

function SceneNpc:SetLoadInternal(LoadEnable)
  self.npcEnableLoadRes = LoadEnable
  if not self.viewObj then
    return
  end
  self.viewObj:SetLoadEnable(self.npcEnableLoadRes)
end

function SceneNpc:UpdateFlags()
  if not self.viewObj then
    return
  end
  self:SetVisibleInternal(0 == self.hiddenFlag)
  self:SetCollisionInternal(0 == self.collisionDisableFlag)
  self:SetLoadInternal(0 == self.loadDisableFlag)
end

function SceneNpc:SetNPCCollision(enable, overrideProfile)
  self.npcEnableCollisionChannelPawn = enable
  self:ApplyCollision(overrideProfile)
end

local CollisionPresets = {
  [0] = "NPCCharacterFreeNoInteract",
  [1] = "NPCCharacterFreeNoInteract",
  [2] = "NPCCharacterFree",
  [3] = "NPCCharacter",
  [4] = "NPCCharacterFreeNoInteract",
  [5] = "NPCCharacterFreeNoInteract",
  [6] = "NPCCharacterBossCapsuleFree",
  [7] = "NPCCharacterBossCapsule"
}
local MeshCollisionPresets = {
  [0] = "NPCCharacterFreeNoInteract",
  [1] = "NPCCharacterFreeNoInteract",
  [2] = "NPCCharacterFreeNoInteract",
  [3] = "NPCCharacterBossMesh"
}

function SceneNpc:ApplyCollision(overrideProfile)
  if not self.viewObj or not UE4.UObject.IsValid(self.viewObj) then
    return
  end
  local id = 0
  if self.npcEnableCollisionChannelPawn then
    id = id + 1
    id = id + 2
  end
  if self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    id = id | 4
  end
  local presetName = overrideProfile or CollisionPresets[id] or "NPCCharacter"
  local capsComp = self.viewObj:GetComponentByClass(UE.UCapsuleComponent)
  if capsComp then
    capsComp:SetCollisionProfileName(presetName)
  end
  local meshPresetFlag = 0
  local meshComp = self.viewObj:GetComponentByClass(UE.UMeshComponent)
  if meshComp then
    if self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
      if self.collisionDisableFlag & ~(1 << NPCModuleEnum.NpcReasonFlags.HIDDEN) == self.collisionDisableFlag then
        meshPresetFlag = meshPresetFlag | 2
      end
      if 0 == self.hiddenFlag then
        meshPresetFlag = meshPresetFlag | 1
      end
    elseif self.npcEnableCollisionChannelPawn then
      meshPresetFlag = meshPresetFlag | 1
    end
    meshComp:SetCollisionProfileName(MeshCollisionPresets[meshPresetFlag])
    if meshPresetFlag & 2 > 0 then
      meshComp.KinematicBonesUpdateType = 0
      meshComp.bNRCAlwaysUpdateKinematicBonesToAnim = true
      meshComp.bNRCUseFixedSkelBounds = false
    end
  end
end

function SceneNpc:GetVisible()
  if self.viewObj and UE.UObject.IsValid(self.viewObj) and self.viewObj.bHidden == self.visibility then
    Log.Error("C++\229\146\140Lua\231\154\132\230\152\190\233\154\144\231\138\182\230\128\129\228\184\141\228\184\128\232\135\180\239\188\129", UE.UObject.GetName(self.viewObj), self.viewObj.bHidden, self.visibility, self.hiddenFlag)
  end
  return self.visibility
end

function SceneNpc:SetHidden(Hidden, Flag)
  if nil == Flag then
    Flag = 0
  end
  local MaskBit = 1 << Flag
  local CurrentHidden = 0 ~= self.hiddenFlag & MaskBit
  if Hidden then
    self.hiddenFlag = self.hiddenFlag | MaskBit
  else
    self.hiddenFlag = self.hiddenFlag & ~MaskBit
  end
  if CurrentHidden ~= (true == Hidden) then
    Log.DebugFormat("[NPC\230\152\190\233\154\144\232\174\190\231\189\174] NPC: %s; Hidden: %s; Flag: %s", self:DebugNPCNameAndID(), tostring(Hidden), table.getKeyName(NPCModuleEnum.NpcReasonFlags, Flag))
  end
  self:SetVisibleInternal(0 == self.hiddenFlag)
end

function SceneNpc:SetCollisionDisable(CollisionDisable, Flag)
  if nil == Flag then
    Flag = 0
  end
  if CollisionDisable then
    self.collisionDisableFlag = self.collisionDisableFlag | 1 << Flag
  else
    self.collisionDisableFlag = self.collisionDisableFlag & ~(1 << Flag)
  end
  self:SetCollisionInternal(0 == self.collisionDisableFlag)
end

function SceneNpc:SetLoadDisable(LoadDisable, Flag)
  if nil == Flag then
    Flag = 0
  end
  if LoadDisable then
    self.loadDisableFlag = self.loadDisableFlag | 1 << Flag
  else
    self.loadDisableFlag = self.loadDisableFlag & ~(1 << Flag)
  end
  self:SetLoadInternal(0 == self.loadDisableFlag)
end

function SceneNpc:IsHidden(Flag)
  if Flag then
    return 0 ~= self.hiddenFlag & 1 << Flag
  else
    return 0 ~= self.hiddenFlag
  end
end

function SceneNpc:SetVisibleForReason(Visible, Reason)
  if Reason == NPCModuleEnum.NpcReasonFlags.ANY then
    self:SetVisible(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.BATTLE then
    self:SetVisibleForBattleReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.DIALOGUE then
    self:SetVisibleForDialogueReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.CINEMATIC then
    self:SetVisibleForCinematicReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.HIDDEN then
    self:SetVisibleForHiddenReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.SERVER then
    self:SetVisibleForServerReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.PERCEPTION then
    self:SetVisibleForPerceptionReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.CALL_OUT then
    self:SetVisibleForCallOutReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.PET_NUM_LIMIT then
    self:SetVisiblePetNumLimitReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.MINI_GAME then
    self:SetVisibleForMiniGameReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.OVERLAP_AWARE then
    self:SetVisibleForOverlapReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.AI then
    self:SetVisibleForAIReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.BORN_DIE then
    self:SetVisibleForBornDieReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.LIGHT_MAGIC then
    self:SetVisibleForLightMagicReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.NIGHTMARE then
    self:SetVisibleForNightmareReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.WORLD_COMBAT_HIDDEN then
    self:SetVisibleForWorldCombatReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.LEGENDARY_BATTLE then
    self:SetVisibleForLegendaryBattleReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.HOME_EDIT_FLAG then
    self:SetVisibleForHomeEditFlagReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.SERVER_TASK then
    self:SetVisibleForServerTaskReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.MAGIC_REPLAY then
    self:SetVisibleForMagicReplayReason(Visible)
  elseif Reason == NPCModuleEnum.NpcReasonFlags.TAKE_PHOTO then
    self:SetVisibleForTakePhoto(Visible)
  end
end

function SceneNpc:SetVisible(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.ANY)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.ANY)
end

function SceneNpc:IsVisibleForBattleReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.BATTLE)
end

function SceneNpc:SetVisibleForBattleReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.BATTLE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.BATTLE)
end

function SceneNpc:IsVisibleForBattleReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.BATTLE)
end

function SceneNpc:SetVisibleForDialogueReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.DIALOGUE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.DIALOGUE)
end

function SceneNpc:IsVisibleForDialogueReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.DIALOGUE)
end

function SceneNpc:SetVisibleForCinematicReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.CINEMATIC)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.CINEMATIC)
  if _G.GlobalConfig.EnableLoadControl then
    self:SetLoadDisable(not Visible, NPCModuleEnum.NpcReasonFlags.CINEMATIC)
  end
end

function SceneNpc:IsVisibleForCinematicReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.CINEMATIC)
end

function SceneNpc:SetVisibleForHiddenReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.HIDDEN)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.HIDDEN)
end

function SceneNpc:IsVisibleForHiddenReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.HIDDEN)
end

function SceneNpc:SetVisibleForWorldCombatReason(Visible)
  Log.Debug("SceneNpc:SetVisibleForWorldCombatReason", self.serverData.base.actor_id, self.name, Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.WORLD_COMBAT_HIDDEN)
  local overrideProfile
  if self.config.genre == _G.Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
    local capsComp = self.viewObj:GetComponentByClass(UE.UCapsuleComponent)
    if capsComp then
      overrideProfile = capsComp:GetCollisionProfileName()
    end
  end
  self:ApplyCollision(overrideProfile)
end

function SceneNpc:SetVisibleForServerReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.SERVER)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.SERVER)
end

function SceneNpc:SetVisibleForServerTaskReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
end

function SceneNpc:SetVisibleForTakePhoto(Visible)
  if not self.config or self.config.reward_drop_type == _G.Enum.RewardNpcType.RNT_DROP then
    return
  end
  if Visible then
    self:SetMeshAlpha(0)
  else
    self:SetMeshAlpha(1)
  end
end

function SceneNpc:IsVisibleForServerReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.SERVER)
end

function SceneNpc:SetVisibleForPerceptionReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.PERCEPTION)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.PERCEPTION)
end

function SceneNpc:IsVisibleForPerceptionReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.PERCEPTION)
end

function SceneNpc:SetVisibleForCallOutReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.CALL_OUT)
end

function SceneNpc:IsVisibleForCallOutReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.CALL_OUT)
end

function SceneNpc:SetVisiblePetNumLimitReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.PET_NUM_LIMIT)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.PET_NUM_LIMIT)
end

function SceneNpc:IsVisiblePetNumLimitReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.PET_NUM_LIMIT)
end

function SceneNpc:SetVisibleForMiniGameReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.MINI_GAME)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.MINI_GAME)
end

function SceneNpc:IsVisibleForMiniGameReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.MINI_GAME)
end

function SceneNpc:SetVisibleForOverlapReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.OVERLAP_AWARE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.OVERLAP_AWARE)
end

function SceneNpc:IsVisibleForOverlapReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.OVERLAP_AWARE)
end

function SceneNpc:SetVisibleForAIReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.AI)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.AI)
end

function SceneNpc:IsVisibleForAIReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.AI)
end

function SceneNpc:SetVisibleForBornDieReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.BORN_DIE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.BORN_DIE)
end

function SceneNpc:IsVisibleForBornDieReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.BORN_DIE)
end

function SceneNpc:SetVisibleForLightMagicReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.LIGHT_MAGIC)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.LIGHT_MAGIC)
end

function SceneNpc:IsVisibleForLightMagicReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.LIGHT_MAGIC)
end

function SceneNpc:SetVisibleForNightmareReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
end

function SceneNpc:IsVisibleForNightmareReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
end

function SceneNpc:SetVisibleForExplodeReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.EXPLODE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.EXPLODE)
end

function SceneNpc:SetVisibleForLegendaryBattleReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.LEGENDARY_BATTLE)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.LEGENDARY_BATTLE)
end

function SceneNpc:SetVisibleForHomeEditFlagReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.HOME_EDIT_FLAG)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.HOME_EDIT_FLAG)
end

function SceneNpc:SetVisibleForMagicReplayReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.MAGIC_REPLAY)
end

function SceneNpc:IsVisibleForMagicReplayReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.MAGIC_REPLAY)
end

function SceneNpc:IsVisibleForBattleOutsideReason()
  return not self:IsHidden(NPCModuleEnum.NpcReasonFlags.BattleOutside)
end

function SceneNpc:SetVisibleForBattleOutsideReason(Visible)
  self:SetHidden(not Visible, NPCModuleEnum.NpcReasonFlags.BattleOutside)
  self:SetCollisionDisable(not Visible, NPCModuleEnum.NpcReasonFlags.BattleOutside)
end

function SceneNpc:BatchApplyHiddenFlags(Flags, Masks)
  self.hiddenFlag = self.hiddenFlag & ~Masks | Flags & Masks
  self:SetVisibleInternal(0 == self.hiddenFlag)
end

function SceneNpc:BatchApplyCollisionDisableFlags(Flags, Masks)
  self.collisionDisableFlag = self.collisionDisableFlag & ~Masks | Flags & Masks
  self:SetCollisionInternal(0 == self.collisionDisableFlag)
end

function SceneNpc:BatchApplyFlags(CannotBeSeen, HideFlags)
  local NewFlag = HideFlags or 0
  if CannotBeSeen then
    NewFlag = NewFlag | 1 << NPCModuleEnum.NpcReasonFlags.SERVER
  end
  self:BatchApplyHiddenFlags(NewFlag, NPCModuleEnum.ServerNpcReasonMasks)
  self:BatchApplyCollisionDisableFlags(NewFlag, NPCModuleEnum.ServerNpcReasonMasks)
end

function SceneNpc:OnEnterBattle(Center, Radius, Squared)
  if Squared >= Radius * Radius then
    return
  end
  local Config = self.config
  if Config and Config.dont_hide_in_battle > 0 then
    return
  end
  self:SetVisibleForBattleReason(false)
end

function SceneNpc:OnLeaveBattle()
  self:SetVisibleForBattleReason(true)
end

local NPCLocationCache = UE4.FVector()
local PlayerToNpcCache = UE4.FVector()

function SceneNpc:DistanceOptimize(distanceRatio)
  if not self.viewObj then
    return
  end
  if not distanceRatio then
    if self.firstTickEver then
      self:CalSquaredDis2Local()
      self.distanceRatio = self:GetDistanceRatio()
      self.firstTickEver = false
    else
      local Dist, Dist2D, Ratio, Dot = NPCBaseCommon.GetDistances(self.viewObj)
      if not Dist then
        return
      end
      self.squaredDis2Local = Dist * Dist
      self.squaredDis2LocalIgnoreZ = Dist2D * Dist2D
      self.distanceRatio = Ratio
      self.fowardDotValue = Dot
      local PlayerForwardCache
      self.PlayerPosCache, PlayerForwardCache = self.module:GetPlayerPosCache()
      UE4.UNRCStatics.K2_GetActorLocationInplace(self.viewObj, NPCLocationCache)
      NPCLocationCache:SubInto(self.PlayerPosCache, PlayerToNpcCache)
      local PlayerToNpc = PlayerToNpcCache
      self.PlayerHeightDiff = math.abs(PlayerToNpc.Z)
      PlayerToNpc.Z = 0
      PlayerToNpc:Normalize()
      self.PlayerForwardDotCache = UE4.FVector.Dot(PlayerToNpc, PlayerForwardCache)
    end
  end
  self.bulkyVisible = self.distanceRatio < 1
  if self.viewObj.OnDistanceOptimize ~= ViewNPCBase.OnDistanceOptimize then
    if self.isLockVisibility then
      self.viewObj:OnDistanceOptimize(self.squaredDis2LocalIgnoreZ, self.fowardDotValue, true, 0.1)
    else
      self.viewObj:OnDistanceOptimize(self.squaredDis2LocalIgnoreZ, self.fowardDotValue, self.bulkyVisible, self.distanceRatio)
    end
  end
  self:InvokeAllComponents("OnDistanceOptimize", self.squaredDis2LocalIgnoreZ, self.fowardDotValue, self.squaredDis2Local, self.distanceRatio)
end

function SceneNpc:SimpleMoveTo(targetPos, type)
  if self.viewObj and self.viewObj:IsA(UE4.APawn) then
    UE4.UAIBlueprintHelperLibrary.SimpleMoveToLocation(self.viewObj:GetController(), targetPos)
  end
end

function SceneNpc:SetThrowSession(session)
  if self.ThrowSession then
    self.ThrowSession:RemoveEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStateChange)
  end
  self.ThrowSession = session
  if self.viewObj then
    self.viewObj:SetThrowSession(session)
  end
  if session then
    session:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStateChange)
  end
end

function SceneNpc:OnSessionStateChange(Session, NewStatus, OldStatus)
  if Session ~= self.ThrowSession then
    Log.Error("ThrowSession\233\148\153\228\185\177", self:DebugNPCNameAndID())
    return
  end
  local InterComp = self.InteractionComponent
  if InterComp and (NewStatus == ThrowSessionStatusEnum.PostInteract or OldStatus == ThrowSessionStatusEnum.PostInteract) then
    InterComp:UpdateCachedOptions()
  end
end

function SceneNpc:OnPreUnLoadResource()
  self:InvokeAllComponents("PreResourceUnload")
end

function SceneNpc:OnLoadResource()
  self:InvokeAllComponents("OnResourceLoaded")
  if self:GetShouldDoMutation() and self.serverData and self.serverData.npc_base then
    local petData = {
      mutation_type = self.serverData.npc_base.mutation_type,
      nature = self.serverData.npc_base.nature,
      glass_info = self.serverData.npc_base.glass_info,
      base_conf_id = self:GetPetbaseId()
    }
    if self:IsPetEgg() then
      PetMutationUtils.SetPetDataGlassActorType(petData, PetMutationUtils.GlassActorType.NormalEgg)
    end
    PetMutationUtils.DoMutation(self.viewObj, petData)
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.serverData and self.serverData then
    local platform_actor_id = localPlayer.serverData and localPlayer.serverData.base.platform_actor_id or 0
    local MyID = self:GetServerId()
    if 0 ~= MyID and platform_actor_id == self:GetServerId() then
      Log.Debug("SceneNpc [LandOnActor]", self.serverData.base.name, MyID, "platform_actor_id", platform_actor_id)
      _G.DelayManager:DelayFrames(3, function()
        localPlayer:LandOnActor(self.viewObj)
      end)
    end
  end
end

function SceneNpc:GetShouldDoMutation()
  return self:IsPet() or self:IsPetEgg() or self:IsFakeMutation()
end

function SceneNpc:GetSpeed()
  if not self.viewObj then
    return self.config.speed
  end
  if self.viewObj.CharacterMovement then
    return self.viewObj.CharacterMovement.MaxWalkSpeed
  end
  if self.viewObj.GetSpeed then
    return self.viewObj:GetSpeed()
  end
end

function SceneNpc:SetSpeed(speed)
  if not speed or not self.viewObj then
    return
  end
  if self.viewObj.CharacterMovement then
    self.viewObj.CharacterMovement.MaxWalkSpeed = speed
  end
  if self.viewObj.SetSpeed then
    self.viewObj:SetSpeed()
  end
end

function SceneNpc:ResetSpeed()
  if not self.viewObj then
    return
  end
  if self.viewObj.CharacterMovement then
    self.viewObj.CharactForward.MaxWalkSpeed = self.config.speed
  end
  if self.viewObj.ResetSpeed then
    self.viewObj:ResetSpeed()
  end
end

function SceneNpc:OnVisible()
  Log.Debug("NPC\232\181\132\230\186\144\229\138\160\232\189\189\229\174\140\230\136\144", self:DebugNPCNameAndID())
  self:SendEvent(NPCModuleEvent.OnViewVisible, self)
  self.module:DispatchEvent(NPCModuleEvent.OnViewVisible, self)
  if self.bHasCachedCustomDepth and self.viewObj then
    self.viewObj:SetCustomDepth(self.CachedCustomDepth)
  end
end

function SceneNpc:OnInvisible()
  self:SendEvent(NPCModuleEvent.OnViewInvisible, self)
  self.module:DispatchEvent(NPCModuleEvent.OnViewInvisible, self)
end

function SceneNpc:SetMeshAlpha(Alpha)
  if nil == Alpha then
    Log.Error("SceneNpc:SetMeshAlpha\228\188\160\229\133\165\231\154\132Alpha\228\184\186\231\169\186")
  end
  if self.viewObj and self.viewObj.resourceLoaded then
    self.CacheCustomAlpha = nil
    self.viewObj:SetMeshAlpha(Alpha)
  else
    self.CacheCustomAlpha = Alpha
  end
end

function SceneNpc:SetCustomDepth(depth, reason)
  if nil == reason then
    reason = "default"
  end
  if nil == depth then
    self.customDepthStack:Remove(reason)
    self.customDepthMap[reason] = nil
  else
    self.customDepthStack:Remove(reason)
    self.customDepthStack:Add(reason)
    self.customDepthMap[reason] = depth
  end
  local real_depth
  if self.customDepthStack:Size() > 0 then
    local newest_reason = self.customDepthStack:Last()
    if newest_reason then
      real_depth = self.customDepthMap[newest_reason]
    end
  end
  self:SetCustomDepthInner(real_depth)
end

function SceneNpc:SetCustomDepthInner(depth)
  if self.viewObj and self.viewObj.resourceLoaded then
    self.bHasCachedCustomDepth = false
    self.CachedCustomDepth = nil
    self.viewObj:SetCustomDepth(depth)
  else
    self.bHasCachedCustomDepth = true
    self.CachedCustomDepth = depth
  end
end

local ClientNPCMask = SceneUtils.ClientNPCMask

function SceneNpc:IsLocal()
  if self.SpawnInCreatePlayerMode then
    return false
  end
  if not self.serverData then
    return true
  end
  local ID = self.serverData.base.actor_id
  if not ID or 0 == ID then
    return true
  end
  return ID & ClientNPCMask == ClientNPCMask
end

function SceneNpc:IsTraceNpc()
  local serverData = self.serverData
  if not serverData then
    return false
  end
  local FeedInfo = serverData.MagicFeedInfo
  if FeedInfo then
    return true
  end
  return false
end

function SceneNpc:Stop()
  if self.BezierFlyComponent and self.BezierFlyComponent:IsFlying() then
    self.BezierFlyComponent:FinishFly(AIDefines.ActionResult.Aborted)
    self.BezierFlyComponent:PostFlySettings()
  end
  Base.Stop(self)
end

function SceneNpc:GetGravityZ()
  local view = self.viewObj
  if view and UE.UObject.IsValid(view) then
    local MoveComp = view:GetMovementComponent()
    if MoveComp then
      return MoveComp:GetGravityZ()
    end
  end
  return 980
end

function SceneNpc:HitAway(source, force)
  if not source then
    return
  end
  self:Stop()
  local Model = self.viewObj
  if Model then
    local selfPos = self:GetActorLocation()
    local HitDir = selfPos - source
    HitDir.Z = 0
    HitDir:Normalize()
    local HitForce = force or 300
    HitDir = HitDir * HitForce
    HitDir.Z = 300
    _G.SceneAIUtils.CalcLaunchFallPosOnNav(self.viewObj, self:GetScaledRadius(), selfPos, HitDir, self:GetGravityZ())
    Model:LaunchCharacter(HitDir, true, true)
  end
end

function SceneNpc:LaunchCharacter(velocity, bXYOverride, bZOverride, disableCollision)
  if nil == bXYOverride then
    bXYOverride = true
  end
  if nil == bZOverride then
    bZOverride = true
  end
  local view = self.viewObj
  if self.viewObj and self.viewObj:IsA(UE4.ACharacter) then
    if disableCollision then
      self:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.LAUNCH_CHARACTER)
    end
    view:LaunchCharacter(velocity, bXYOverride, bZOverride)
    self.launchedMoveModeCallback = _G.SimpleDelegateFactory:CreateCallback(self, self.LaunchedMovementModeChanged)
    view.MovementModeChangedDelegate:Add(view, self.launchedMoveModeCallback)
  else
    self:SendEvent(NPCModuleEvent.ON_NPC_LAUNCH_END, self)
  end
end

function SceneNpc:LaunchedMovementModeChanged()
  local view = self.viewObj
  if not self.viewObj or not view.GetMovementComponent then
    return
  end
  local MoveComp = view:GetMovementComponent()
  local notFalling = MoveComp.MovementMode ~= UE.EMovementMode.MOVE_Falling
  if notFalling then
    self:RemoveLaunchDelegate()
    self:SendEvent(NPCModuleEvent.ON_NPC_LAUNCH_END, self)
    self:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.LAUNCH_CHARACTER)
  end
  if not notFalling and MoveComp:IsA(UE.UCharacterNavMovementComponent) then
    MoveComp:ReqCloseFallingResist()
    MoveComp:ReqCloseFallingMaxSpeedLimit()
  end
end

function SceneNpc:RemoveLaunchDelegate()
  if not self.launchedMoveModeCallback then
    return
  end
  local view = self.viewObj
  if view and UE.UObject.IsValid(view) and view:IsA(UE4.ACharacter) then
    view.MovementModeChangedDelegate:Remove(view, self.launchedMoveModeCallback)
  end
  self.launchedMoveModeCallback = nil
end

function SceneNpc:GetCurrentEnvLabel()
  return {}
end

local SignificantCompClass = UE.USignificanceComponent

function SceneNpc:SetSignificant(auto, override)
  if self.viewObj then
    local significantComp = self.viewObj:GetComponentByClass(SignificantCompClass)
    if significantComp then
      significantComp:SelfControlSignificance(not auto, override)
    end
  end
end

function SceneNpc.ToggleInteractionCheck(enable)
  VisualizeInteractionCheck = enable
end

function SceneNpc:TryRecycle(player_id)
  if nil == player_id then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    player_id = localPlayer and localPlayer.serverData.base.actor_id
  end
  self:EnsureComponent(PetInteractOptionComponent)
  self.PetInteractOptionComponent:TryRecycle(player_id)
end

function SceneNpc:CanIntimate()
  if self.viewObj and self.viewObj.ThrowSession then
    self:EnsureComponent(PetInteractOptionComponent)
    return self.PetInteractOptionComponent:CheckNeedInteract(self.serverData.base.owner_id, self.viewObj.ThrowSession:GetGID())
  else
    return false
  end
end

function SceneNpc:OnInteractQuantityChange(action)
  self:EnsureComponent(PetInteractOptionComponent)
  self.PetInteractOptionComponent:ShowInteractQuantity()
end

function SceneNpc:GetInteractPlayer()
  self:EnsureComponent(SyncNpcActionComponent)
  return self.SyncNpcActionComponent:GetInteractPlayer()
end

function SceneNpc:InteractFinish()
  self:EnsureComponent(SyncNpcActionComponent)
  return self.SyncNpcActionComponent:Clear()
end

function SceneNpc:OnClientBornBegin()
  if self.SyncPetActionComponent and self.SyncPetActionComponent.OnClientBornBegin then
    self.SyncPetActionComponent:OnClientBornBegin()
  end
end

function SceneNpc:OnClientBornEnd()
  if self.SyncPetActionComponent and self.SyncPetActionComponent.OnClientBornEnd then
    self.SyncPetActionComponent:OnClientBornEnd()
  end
end

function SceneNpc:GetCreatorID()
  return self.serverData.npc_base.create_avatar_id
end

function SceneNpc:GetWorldOwnerID()
  if not self.serverData then
    return self.owner_id
  end
  local ID = self.serverData.base.owner_id
  if not ID or 0 == ID then
    return _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
  end
  return self.serverData.base.owner_id
end

function SceneNpc:GetServerPosition(Position)
  local ret = Base.GetServerPosition(self, Position)
  if ret then
    ret.z = math.round(ret.z - self:GetScaledHalfHeight())
  end
  return ret
end

function SceneNpc:GetReportPositionItem(op_type)
  if self.isDestroy then
    return
  end
  if not self.serverData then
    return
  end
  if self.serverData.npc_base.create_avatar_id ~= _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
    self:ChangeNeedPosAdjust(false, false)
    return
  end
  local Item = self:GetSetNpcPosItem()
  op_type = op_type or 0
  local HalfHeight = self:GetScaledHalfHeight()
  if HalfHeight ~= HalfHeight then
    HalfHeight = 0
  end
  Item.pt.pos.z = math.round(Item.pt.pos.z - HalfHeight)
  Item.op_type = op_type
  return Item
end

function SceneNpc:ReportPosition(op_type, reset_pos_if_failed)
  local Item = self:GetReportPositionItem(op_type, reset_pos_if_failed)
  if not Item then
    return
  end
  SceneUtils.DelayReportNpcPosition(Item, nil, reset_pos_if_failed)
  self:ChangeNeedPosAdjust(false, false)
end

function SceneNpc:OnReportPositionRsp(rsp)
  if rsp.failed_npc_list and #rsp.failed_npc_list > 0 and self.viewObj then
    local npc_id = self:GetServerId()
    for _, npcItem in ipairs(rsp.failed_npc_list) do
      if npc_id == npcItem.npc_id then
        local HalfHeight = self:GetScaledHalfHeight()
        if HalfHeight ~= HalfHeight then
          HalfHeight = 0
        end
        npcItem.pt.pos.z = npcItem.pt.pos.z + HalfHeight
        self.viewObj:Abs_K2_SetActorLocationAndRotation_WithoutHit(SceneUtils.ServerPos2ClientPos(npcItem.pt.pos), SceneUtils.ServerPos2ClientRotator(npcItem.pt.dir))
        return
      end
    end
  end
end

function SceneNpc:RequestRelease(effect_op)
  if self:IsAThrownPet() and self.ThrowSession then
    self.ThrowSession:Recycle()
  elseif self:IsLocal() then
    local id = self:GetServerId()
    _G.DelayManager:DelayFrames(1, function()
      local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
      NPCModule:OnNPCLeave(id)
    end)
  elseif self:IsHomeNpc() then
  else
    local info = _G.ProtoMessage:newClientAiCommandInfo()
    info.actor_id = self:GetServerId()
    info.action_id = Enum.NpcSceneCommandType.NSC_RELEASE
    info.command_param = effect_op
    info.pos = SceneUtils.ClientPos2ServerPos(self:GetActorLocation())
    _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_SceneCommand(info)
  end
end

function SceneNpc:IsControlledByPlayer()
  local OwnerID = self:GetCreatorID()
  if not OwnerID then
    return true
  end
  local SrcActorType = SceneUtils.GetActorDetailType(OwnerID)
  if SrcActorType == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal then
    local ID = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_UIN)
    return ID == OwnerID
  else
    local ParentNPC = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, OwnerID)
    if ParentNPC then
      return ParentNPC:IsControlledByPlayer()
    else
      return true
    end
  end
end

function SceneNpc:IsFacePlay(player_id)
  local player
  if player_id then
    player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, player_id)
  else
    player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  end
  local npcForward = self.luaObj:GetForwardModify()
  local playPos = player.viewObj:Abs_K2_GetActorLocation()
  local npcPos = self:GetActorLocation()
  local npcToPlayer = UE4.FVector(playPos.X - npcPos.X, playPos.Y - npcPos.Y, 0)
  npcToPlayer:Normalize()
  local dot = UE4.FVector.Dot(npcForward, npcToPlayer)
  return dot > 0.866
end

function SceneNpc:CheckNavValid()
  local selfPos = self.viewObj:Abs_K2_GetActorLocation()
  local QueryExtent = UE4.FVector(0, 0, 85)
  local ProjectedLocation, resValue = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), selfPos, nil, nil, nil, QueryExtent)
  return resValue
end

function SceneNpc:ModifyMoveSpeedByBuff(SpeedRate)
  Base.ModifyMoveSpeedByBuff(self, SpeedRate)
  if self.viewObj then
    self.viewObj.CustomTimeDilation = SpeedRate
  end
end

function SceneNpc:GetCollisionCompByUComp(UPrimitiveComp)
  for _, luaComp in pairs(self.collisionComps) do
    if luaComp.viewObj == UPrimitiveComp then
      return luaComp
    end
  end
end

function SceneNpc:CanInteract()
  if self.bNeedPosAdjust then
    return false
  end
  if self.isDestroy or self.shouldDestroy then
    return false
  end
  if not self.canTriggerInteraction then
    return false
  end
  if not self.viewObj then
    return false
  end
  if not UE.UObject.IsValid(self.viewObj) then
    return false
  end
  if self.viewObj.bHidden then
    return false
  end
  if self.ThrowSession and self.ThrowSession.Status ~= ThrowSessionStatusEnum.PostInteract then
    return false
  end
  local petStatusComponent = self:GetComponent(PetStatusComponent)
  if petStatusComponent and not petStatusComponent:CanInteract() then
    return false
  end
  if self:IsMagicReplayActor() then
    return false
  end
  return true
end

function SceneNpc:ScheduleNextTick(Interval)
  if self.viewObj then
    NPCBaseCommon.ScheduleNextTick(self.viewObj, Interval)
  end
end

function SceneNpc:SetLoopAction(LoopAction)
  if not self.serverData then
    return
  end
  self.serverData.npc_base.loop_action = LoopAction
  if self.viewObj then
    self.viewObj:PlayLoopPerform()
  end
end

function SceneNpc:SetBuffInfoAction(buff_info)
  local ServerData = self.serverData
  if not ServerData then
    return
  end
  if not ServerData.buff_info then
    ServerData.buff_info = _G.ProtoMessage:newActorInfo_Buffs()
  end
  self.serverData.buff_info.battle_buff_infos = buff_info
end

function SceneNpc:OnEnterDeepWater()
  self:SendEvent(NPCModuleEvent.ON_NPC_ENTER_DEEP_WATER)
  if self.AIComponent then
    self.AIComponent:OnEnterDeepWater()
  end
end

function SceneNpc:TeleportToPos(targetPos)
  self:SetActorLocation(targetPos)
end

function SceneNpc:InitOwner()
end

function SceneNpc:SetHitedComponent(bEnable)
  if self.IsAThrownPet ~= nil and self:IsAThrownPet() and nil ~= self.viewObj then
    local CapsuleComponent = self.viewObj:GetComponentByClass(UE4.UCapsuleComponent)
    local hitedComps = self.viewObj:GetComponentsByTag(UE4.UCapsuleComponent, "HitedComponent")
    for idx = 1, hitedComps:Length() do
      local hitedComp = hitedComps:Get(idx)
      if bEnable then
        hitedComp:SetCollisionProfileName("SkillHited")
        hitedComp:SetGenerateOverlapEvents(true)
        local InRadius = CapsuleComponent:GetUnscaledCapsuleRadius()
        local InHalfHeight = CapsuleComponent:GetUnscaledCapsuleHalfHeight()
        hitedComp:SetCapsuleSize(InRadius, InHalfHeight, false)
      else
        hitedComp:SetCollisionProfileName("NoCollision")
        hitedComp:SetGenerateOverlapEvents(false)
      end
    end
  end
end

function SceneNpc:UpdateData(ServerData, isReconnect)
  self.serverData = ServerData
  if self.components then
    local items = self.components:Items()
    for _, v in ipairs(items) do
      v:UpdateData(ServerData, isReconnect)
    end
  end
  if self.viewObj then
    self.viewObj:UpdateData(ServerData, isReconnect)
  end
  if isReconnect and self.viewObj and not self.PlaceableId then
    self:SetActorScale3D(_G.FVectorOne)
    self:AdjustModelHeight(false, true)
    local MiscInfo = self.serverData.misc_info
    if MiscInfo then
      self:BatchApplyFlags(MiscInfo.cannot_be_seen, MiscInfo.npc_hide_flag)
    end
  end
  if self.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    _G.NRCEventCenter:DispatchEvent(_G.WorldCombatModuleEvent.BossReconnect, self, ServerData, isReconnect)
  end
  if self.config.genre == _G.Enum.ClientNpcType.CNT_BULLET then
    local worldCombatSkillComponent = self.WorldCombatSkillComponent
    if worldCombatSkillComponent then
      worldCombatSkillComponent:CurrSkillPerformOnReconnect(ServerData)
    end
  end
  if SceneUtils.IsLogicStatusNightmareBossActivated(self) and self.viewObj and self.viewObj.ModifySpecialEffect then
    self.viewObj:ModifySpecialEffect()
  end
  local BornDie = self.BornDieComponent
  if self.viewObj and BornDie and BornDie.PostponedByTask and not self:IsHidden(NPCModuleEnum.NpcReasonFlags.SERVER_TASK) then
    Log.Error("\230\150\173\231\186\191\233\135\141\232\191\158\230\129\162\229\164\141SERVER_TASK\233\154\144\232\151\143\231\154\132NPC", self:DebugNPCNameAndID())
    BornDie:OnBeginBorn()
  end
end

function SceneNpc:LockAIForReason(lock, noStopMove, LockReason)
  local AIComp = self:EnsureComponent(AIComponent)
  if not AIComp then
    return
  end
  AIComp:ForceLockForReason(lock, noStopMove, LockReason)
end

function SceneNpc:MiniGameStart(bInNightmare)
  if bInNightmare then
    self:SetVisibleForReason(true, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
  else
    self:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
  end
end

function SceneNpc:MiniGameEnd()
  self:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.NIGHTMARE)
end

function SceneNpc:DisableVisibilityOptimization()
  if not self.viewObj then
    Log.Error("SceneNpc:DisableVisibilityOptimization with nil viewobj ", self:DebugNPCNameAndID())
    return nil, nil, nil, nil
  end
  local mesh = self.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  if mesh then
    local VisibilityBasedAnimTickOption = mesh.VisibilityBasedAnimTickOption
    local bNRCUseFixedSkelBounds = mesh.bNRCUseFixedSkelBounds
    local bNRCAlwaysUpdateKinematicBonesToAnim = mesh.bNRCAlwaysUpdateKinematicBonesToAnim
    local BoundsScale = mesh.BoundsScale
    mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    mesh.bNRCUseFixedSkelBounds = false
    mesh.bNRCAlwaysUpdateKinematicBonesToAnim = true
    mesh.BoundsScale = 999
    return VisibilityBasedAnimTickOption, bNRCUseFixedSkelBounds, bNRCAlwaysUpdateKinematicBonesToAnim, BoundsScale
  end
  return nil, nil, nil, nil
end

function SceneNpc:EnableVisibilityOptimization(VisibilityBasedAnimTickOption, bNRCUseFixedSkelBounds, bNRCAlwaysUpdateKinematicBonesToAnim, BoundsScale)
  if not self.viewObj then
    Log.Error("SceneNpc:DisableVisibilityOptimization with nil viewobj ", self:DebugNPCNameAndID())
    return nil, nil, nil
  end
  local mesh = self.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  if mesh then
    mesh.VisibilityBasedAnimTickOption = VisibilityBasedAnimTickOption or UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    mesh.bNRCUseFixedSkelBounds = bNRCUseFixedSkelBounds or true
    mesh.bNRCAlwaysUpdateKinematicBonesToAnim = bNRCAlwaysUpdateKinematicBonesToAnim or false
    mesh.BoundsScale = BoundsScale or 1
  end
end

local AutoCollectTypes = {
  Enum.ActionType.ACT_BAGITEM,
  Enum.ActionType.ACT_ADD_PET_HP,
  Enum.ActionType.ACT_ADD_ROLE_ENERGY,
  Enum.ActionType.ACT_AWARD
}

function SceneNpc:GetAutoCollectOption(Now)
  local Config = self.config
  if not Config then
    return nil
  end
  if not self.canTriggerInteraction then
    return nil
  end
  if Config.reward_drop_type ~= Enum.RewardNpcType.RNT_DROP then
    return nil
  end
  local CheckLocal = self:IsLocal()
  if CheckLocal then
    return nil
  end
  local Data = self.serverData
  local BaseData = Data and Data.base
  local BornTime = (BaseData and BaseData.born_time or 0) * 1000
  if Now - BornTime < CollectTimeout then
    return nil
  end
  local InterComp = self.InteractionComponent
  if not InterComp then
    return nil
  end
  local Main = InterComp:GetMainAction()
  if not Main then
    return nil
  end
  local ActionConf = Main.config
  if not ActionConf then
    return nil
  end
  local Type = ActionConf.action and ActionConf.action.action_type
  if not Type then
    return nil
  end
  if not table.contains(AutoCollectTypes, Type) then
    return nil
  end
  if Main:HasAutoCollected() then
    return nil
  end
  if Main:NeedStatusNotify() then
    return nil
  end
  local CanInteract = self:CanInteract()
  if not CanInteract then
    return nil
  end
  return Main
end

function SceneNpc:IsFirstAppearance()
  if self.serverData and self.serverData.base and self.serverData.base.enter_scene_times then
    return 1 == self.serverData.base.enter_scene_times
  end
  return false
end

function SceneNpc:ShouldEnableAuraSyncCheck()
  if self.config.aura_id and 0 ~= #self.config.aura_id then
    for _, id in pairs(self.config.aura_id) do
      local config = _G.DataConfigManager:GetNpcAuraConf(id)
      if config and config.aura_effect then
        for _, effect in pairs(config.aura_effect) do
          if effect and (effect.aura_effect_type == Enum.AuraEffect.AE_CHANGE_TEMP or effect.aura_effect_type == Enum.AuraEffect.AE_SET_TEMP) then
            return true
          end
        end
      end
    end
  end
  if self.serverData then
    local IsElite = self:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_NIGHTMARE_ELITE)
    if IsElite then
      return true
    end
  end
  return false
end

function SceneNpc:IsFarmLandNpc()
  if not FarmUtils.IsModuleEnable() then
    return false
  end
  if self.luaObj and self.luaObj.landId then
    return true
  end
  return false
end

function SceneNpc:GetFarmLandNpcId()
  if not FarmUtils.IsModuleEnable() then
    return nil
  end
  return self.luaObj and self.luaObj.landId or nil
end

function SceneNpc:IsFarmCropNpc()
  if not FarmUtils.IsModuleEnable() then
    return false
  end
  if not (self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id) or 0 == self.serverData.npc_base.home_plant_land_id then
    return false
  end
  return true
end

function SceneNpc:GetFarmLandId()
  if not (self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id) or 0 == self.serverData.npc_base.home_plant_land_id then
    return nil
  end
  return self.serverData.npc_base.home_plant_land_id
end

function SceneNpc:GetFarmNPCType()
  if not FarmUtils.IsModuleEnable() then
    return FarmModuleEnum.NPCType.None
  end
  if self.config.id == FarmConst.SpecialNPCId.FarmEntranceNPCId then
    return FarmModuleEnum.NPCType.Entrance
  end
  if self.config.id == FarmConst.SpecialNPCId.FarmBoardNPCId then
    return FarmModuleEnum.NPCType.Board
  end
  if self.luaObj and self.luaObj.landId and 0 ~= self.luaObj.landId then
    return FarmModuleEnum.NPCType.Land
  end
  if self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id and 0 ~= self.serverData.npc_base.home_plant_land_id then
    return FarmModuleEnum.NPCType.Crop
  end
  return FarmModuleEnum.NPCType.None
end

function SceneNpc:ApplyTrackStatus()
  if self.PetHUDComponent and self.PetHUDComponent:HasNpcHud() then
    self.PetHUDComponent:SetTracked(self.tracked)
  end
  local npcStatusComponent = self:EnsureComponent(NpcStatusComponent)
  if npcStatusComponent then
    npcStatusComponent:SetTaskTrack(self.tracked)
  end
end

function SceneNpc:SetTracked(tracked)
  if self.tracked == tracked then
    return
  end
  Log.Debug("SetTracked", self.tracked, tracked, self.serverData and self.serverData.base and self.serverData.base.actor_id)
  self.tracked = tracked
  self:ApplyTrackStatus()
end

function SceneNpc:UpdateAcceptTaskHUD(TaskID, bVisible)
  if self.PetHUDComponent and self.PetHUDComponent:HasNpcHud() then
    self.PetHUDComponent:UpdateAcceptTaskHUD(TaskID, bVisible)
  end
end

function SceneNpc:GetFirstUnitType()
  local petBaseConf = self:GetConfPetData()
  if petBaseConf and #petBaseConf.unit_type > 0 then
    return petBaseConf.unit_type[1] or Enum.SKillDamType.SDT_NONE
  end
  return Enum.SkillDamType.SDT_NONE
end

function SceneNpc:ContainsUnitType(type)
  local petBaseConf = self:GetConfPetData()
  if petBaseConf and petBaseConf.unit_type then
    for _, unitType in ipairs(petBaseConf.unit_type) do
      if unitType == type then
        return true
      end
    end
  end
  return false
end

function SceneNpc:CheckPlayerInSeat()
  if not self.serverData then
    return
  end
  if not self.serverData.npc_interact then
    return
  end
  local SeatInfo = self.serverData.npc_interact.seat_info
  if not SeatInfo then
    return
  end
  if not SeatInfo.seat_info then
    return
  end
  for i, Info in ipairs(SeatInfo.seat_info) do
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Info.interact_avatar_id)
    if Player and Player.avatarLoaded then
      local PlayerSitInfo = Player.serverData.avatar_interact.sit_info
      if PlayerSitInfo and PlayerSitInfo.sit_npc_id == self.serverData.base.actor_id and PlayerSitInfo.seat_idx + 1 == i then
        if HomeIndoorSandbox:InHomeIndoor() then
          local FurnitureID = self.FurnitureID
          if not FurnitureID then
            return
          end
          local FurnitureView = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetFurnitureView, FurnitureID)
          if not FurnitureView then
            return
          end
          local SeatConf = _G.DataConfigManager:GetSeatConf(self.config.id)
          if not SeatConf then
            return
          end
          HomeUtils.PlayerSitToHomeSeat(self, FurnitureView, i, SeatConf.is_home_lie)
        else
          local Conf = _G.DataConfigManager:GetRoleplayPropConf(self.config.id)
          if not Conf then
            return
          end
          local SpecialG6 = Conf["special_start_" .. i]
          local SeatSlot = string.format("Seat_%s", i)
          Player.playerToyComponent:PlayerSitToSceneSeat(self, SeatSlot, SpecialG6, nil, Conf.scene_sit_blur_type)
        end
      end
    end
  end
end

function SceneNpc:CheckPlayerInBox()
  if not self:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_BLINDBOX_OCCUPIED) then
    return
  end
  if not self.serverData or not self.serverData.npc_prop and not not self.serverData.npc_prop.npc_prop_slot_infos then
    return
  end
  local PropInfo = self.serverData.npc_prop.npc_prop_slot_infos
  if #PropInfo > 0 then
    for i, Info in ipairs(PropInfo) do
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Info.holder_avatar_id)
      if Player and Player.avatarLoaded then
        Player:SetVisible(false)
      end
    end
  end
end

function SceneNpc:IsInitialNPC()
  local base = self.serverData and self.serverData.base
  local actor_id = base and base.actor_id or 0
  local is_initial = self.module and self.module:IsInInitialActorIDs(actor_id) or false
  return is_initial
end

function SceneNpc:CalculateServerDistance()
  if self.viewObj then
    return
  end
  local local_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local player_data = local_player and local_player.serverData
  local player_base = player_data and player_data.base
  local player_pos = player_base and player_base.pt.pos
  local self_pos = self.serverData and self.serverData.base.pt.pos
  if player_pos and self_pos then
    local delta_x = player_pos.x - self_pos.x
    local delta_y = player_pos.y - self_pos.y
    local delta_z = player_pos.z - self_pos.z
    self.squaredDis2LocalIgnoreZ = delta_x * delta_x + delta_y * delta_y
    self.squaredDis2Local = self.squaredDis2LocalIgnoreZ + delta_z * delta_z
  end
end

function SceneNpc:SetPetBondActive(bIsValid, Reason)
  if self.PetHUDComponent then
    self.PetHUDComponent:SetPetBondActive(bIsValid, Reason)
  end
end

function SceneNpc:SetPetBondVisible(bIsVisible)
  if self.PetHUDComponent then
    self.PetHUDComponent:SetPetBondVisible(bIsVisible)
  end
end

function SceneNpc:SetHomeOptionActive(bActive)
  if self.PetHUDComponent then
    self.PetHUDComponent:HighlightHomePetHud(bActive)
  end
end

function SceneNpc:GetRotationFixDistance()
  local dis = self.squaredDis2Local or 100000
  if self.PlayerForwardDotCache < 0 then
    dis = dis + 1000000
  end
  return dis
end

function SceneNpc:GetThrowInteractType()
  if self.customThrowType then
    return self.customThrowType
  end
  if self.config then
    return self.config.throwing_interact_type
  end
  return nil
end

function SceneNpc:GetActorType()
  if self.customActorType then
    return self.customActorType
  end
  return SceneUtils.GetActorDetailType(self:GetServerId())
end

function SceneNpc:GetAimDisplay()
  local optionList = {}
  if self.InteractionComponent then
    local Options = self.InteractionComponent:GetAllOptions()
    for _, Option in pairs(Options) do
      if Option:IsOptionEnable(true) then
        local optionId = Option.optionInfo.option_id
        table.insert(optionList, optionId)
      end
    end
  end
  local animDisplay = {}
  if self.customAimDisplay then
    table.insert(animDisplay, self.customAimDisplay)
  end
  for _, optionId in pairs(optionList) do
    local npcOptionCfg = _G.DataConfigManager:GetNpcOptionConf(optionId)
    if npcOptionCfg then
      table.insert(animDisplay, npcOptionCfg.npc_aim_display)
    end
  end
  return animDisplay
end

function SceneNpc:OnMissileReConnectCreate()
  local worldCombatSkillInfo = self.serverData.world_combat_skill_info
  if not worldCombatSkillInfo then
    Log.Debug("SceneNpc [Missile npc] worldCombatSkillInfo not found", self.serverData.base.name, self:GetServerId())
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.serverData.npc_base.src_npc_id)
  if not caster then
    Log.Error("SceneNpc [Missile npc] caster not found", self.serverData.base.name, self:GetServerId())
    return
  end
  local target = SceneUtils.GetActorByServerId(worldCombatSkillInfo.target_id)
  local targetPos = SceneUtils.ServerPos2ClientPos(worldCombatSkillInfo.target_pos)
  local skillId = worldCombatSkillInfo.skill_id
  local MissileUtils = require("NewRoco.Modules.Core.Missile.MissileUtils")
  local actionsData = worldCombatSkillInfo.actions_data
  for _, actionData in pairs(actionsData) do
    local missileData = MissileUtils:NewMissileData()
    local missileSnapShoot = actionData.missile_snapshoot
    missileData.MissileType = missileSnapShoot.missile_type or Enum.MissileType.TRACE_TARGET
    missileData.InitSpeed = missileSnapShoot.cur_speed or 0
    if missileData.MissileType == Enum.MissileType.TRACE_TARGET then
      missileData.AccelerateSpeed = missileSnapShoot.trace_bullet.accelerate_speed or 0
      missileData.MaxSpeed = missileSnapShoot.trace_bullet.max_speed or missileData.InitSpeed
      missileData.AngleSpeed = missileSnapShoot.trace_bullet.angle_speed or 0
      missileData.CancelTraceDist = missileSnapShoot.trace_bullet.cancel_trace_dist or 0
      missileData.TraceTime = missileSnapShoot.trace_bullet.trace_dur_time or 0
      missileData.IsKeepLandHeight = missileSnapShoot.trace_bullet.is_keep_land_height or false
      missileData.LandHeight = missileSnapShoot.trace_bullet.land_height or 0
    elseif missileData.MissileType == Enum.MissileType.AIM_AT_TARGET_POS then
      missileData.AccelerateSpeed = missileSnapShoot.normal_bullet.accelerate_speed or 0
      missileData.MaxSpeed = missileSnapShoot.normal_bullet.max_speed or missileData.InitSpeed
      missileData.IsKeepLandHeight = missileSnapShoot.normal_bullet.is_keep_land_height or false
      missileData.LandHeight = missileSnapShoot.normal_bullet.land_height or 0
      missileData.AngleSpeed = 0
      missileData.CancelTraceDist = 0
      missileData.TraceTime = 0
    elseif missileData.MissileType == Enum.MissileType.FLY_WITH_CURVE then
      missileData.CurveFlyTime = missileSnapShoot.curve_bullet.curve_fly_time or 0.01
      missileData.AccelerateSpeed = 0
    end
    Log.Debug("Reconnect launch missile", self.serverData.base.name, self:GetServerId())
    _G.NRCModeManager:DoCmd(_G.MissileModuleCmd.LaunchMissileByData, self.serverData.base.actor_id, nil, caster, target, targetPos, skillId, missileData)
  end
end

function SceneNpc:IsViewArtFurniture()
  if self.InteractionComponent then
    local Options = self.InteractionComponent:GetAllOptions()
    if Options then
      for _, v in pairs(Options) do
        if v:IsHomeViewArtOption() then
          return true
        end
      end
    end
  end
  return false
end

return SceneNpc
