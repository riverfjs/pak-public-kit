require("UnLuaEx")
local LuaParamType = require("NewRoco.AI.BehaviorTree.LuaParams.LuaParamType")
local LuaBoolParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaBoolParam")
local LuaFloatParam = require("NewRoco.AI.BehaviorTree.LuaParams.LuaFloatParam")
local AIBlackboardKeyDefine = require("NewRoco.AI.BehaviorTree.Pet.AIBlackboardKeyDefine")
local MFBTLuaTreeComponent = require("NewRoco.AI.BehaviorTree.MFBT.MFBTLuaTreeComponent")
local NavigationDefines = require("NewRoco.AI.Navigation.NavigationDefines")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local HomePetAttributeComponent

local function RequireHomePetAttributeComponent()
  if nil == HomePetAttributeComponent then
    HomePetAttributeComponent = require("NewRoco.Modules.System.Home.HomePetFeed.HomePetAttributeComponent")
  end
end

local AIC_Pet_C = NRCClass()
local _localUE4 = UE4
local _localString = string
AIC_Pet_C.LocalGlobalConfig = GlobalConfig

function AIC_Pet_C:Ctor()
  self.LuaBTBlackboard = nil
  self.mfbtLuaComponent = MFBTLuaTreeComponent(self)
  self.isMFBTEnable = false
  self.isServerMoveRunning = false
  self.mfbtDebugging = false
  self.animStopQueue = {}
end

function AIC_Pet_C:GetBlackboardValue(Key, isMFBTEnable, inType)
  if nil == Key then
    return nil
  end
  if nil == isMFBTEnable then
    isMFBTEnable = self.isMFBTEnable
  end
  local retObject
  if self.LocalGlobalConfig.BTreeUseLuaBlackboard then
    retObject = self.LuaBTBlackboard[Key]
    if nil == retObject and nil ~= inType then
      if inType == LuaParamType.Bool then
        retObject = self:GetMfbbBool(Key)
      elseif inType == LuaParamType.Int then
        retObject = self:GetMfbbInt(Key)
      elseif inType == LuaParamType.Float then
        retObject = self:GetMfbbFloat(Key)
      elseif inType == LuaParamType.String then
        retObject = self:GetMfbbString(Key)
      elseif inType == LuaParamType.Vector then
        retObject = self:GetMfbbVector(Key)
      elseif inType == LuaParamType.Rotator then
        retObject = self:GetMfbbQuat(Key):ToRotator()
      elseif inType == LuaParamType.Object then
        retObject = self:GetMfbbObject(Key)
      end
    end
    self.LuaBTBlackboard[Key] = retObject
  else
  end
  if nil == retObject then
    local Obj = self:GetBlackboardObjectInCPP(Key, isMFBTEnable)
    if Obj and Obj.IsA and Obj:IsA(UE.AActor) and Obj.sceneCharacter then
      retObject = Obj.sceneCharacter
    end
  end
  return retObject
end

function AIC_Pet_C:QueryCrossBlackboardValue(keyName, type)
  local retObj
  if self.LocalGlobalConfig.BTreeUseLuaBlackboard then
    for k, v in pairs(self.LuaBTBlackboard) do
      if _localString.EndsWith(k, "]_" .. keyName) then
        return v
      end
    end
  else
    local fullname = self:QueryCrossBlackboardKey(keyName)
    if "" ~= fullname and nil ~= type then
      if type == LuaParamType.Bool then
        retObj = self:GetMfbbBool(fullname)
      elseif type == LuaParamType.Int then
        retObj = self:GetMfbbInt(fullname)
      elseif type == LuaParamType.Float then
        retObj = self:GetMfbbFloat(fullname)
      elseif type == LuaParamType.String then
        retObj = self:GetMfbbString(fullname)
      elseif type == LuaParamType.Rotator then
        retObj = self:GetMfbbQuat(fullname):Rotator()
      elseif type == LuaParamType.Vector then
        retObj = self:GetMfbbVector(fullname)
      elseif type == LuaParamType.Object then
        retObj = self:GetMfbbObject(fullname)
      elseif type == LuaParamType.Enum then
        retObj = self:GetMfbbInt(fullname)
      end
    end
  end
  if nil == retObj and nil ~= type then
    Log.Debug("[AIC_Pet_C:QueryCrossBlackboardValue] Cant find value of " .. keyName)
    if type == LuaParamType.Bool then
      return false
    elseif type == LuaParamType.Int then
      return 0
    elseif type == LuaParamType.Float then
      return 0
    elseif type == LuaParamType.String then
      return ""
    elseif type == LuaParamType.Rotator then
      return UE4.FQuat(0, 0, 0, 1):Rotator()
    elseif type == LuaParamType.Vector then
      return FVectorZero
    elseif type == LuaParamType.Object then
      return nil
    elseif type == LuaParamType.Enum then
      return 0
    end
  end
  return retObj
end

function AIC_Pet_C:GetSpecialObjectByKey(key)
  if _localString.EndsWith(key, "_LocalPlayer") then
    if self.Npc.AIComponent.relativePlayer.ref then
      return self.Npc.AIComponent.relativePlayer.ref
    end
    return NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  elseif _localString.EndsWith(key, "_SelfActor") then
    return self.Npc
  end
end

function AIC_Pet_C:GetFocusPlayerCharacter()
  local player_view = self:GetFocusPlayer()
  if player_view and player_view.IsA and player_view:IsA(UE.AActor) and player_view.sceneCharacter then
    return player_view.sceneCharacter
  end
  if self.Npc.AIComponent.relativePlayer.ref then
    return self.Npc.AIComponent.relativePlayer.ref
  end
  return _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function AIC_Pet_C:GetBlackboardObjectInCPP(key, isMFBTEnable)
  if isMFBTEnable then
    local object = self:GetMfbbObject(key)
    return object
  elseif self.Blackboard then
    return self.Blackboard:GetValueAsObject(key)
  end
end

function AIC_Pet_C:SetSteeringParam(enable, maxForce, mass)
  local pathFollowing = self:GetPathFollowingComponent()
  if pathFollowing then
    pathFollowing.bEnableSteering = enable
    if enable then
      pathFollowing.MaxSteeringForce = maxForce
      pathFollowing.SteeringMass = mass
    end
  end
end

function AIC_Pet_C:SetBlackboardObjectInCPP(key, actor, isMFBTEnable)
  if isMFBTEnable then
    if actor then
      self:SetMfbbObject(key, actor)
    else
      self:SetMfbbObject(key, nil)
    end
  elseif self.Blackboard and actor then
    self.Blackboard:SetValueAsObject(key, actor)
  end
end

function AIC_Pet_C:GetBattleCenterInfo()
  local battleCenter = NRCModuleManager:DoCmd(BattleModuleCmd.GetBattleFieldCenterPos)
  local battleRadius = NRCModuleManager:DoCmd(BattleModuleCmd.GetBattleFieldRadius)
  return battleCenter, battleRadius
end

function AIC_Pet_C:AddDelegateListener(DelegateProperty, Caller, Listener)
  if not DelegateProperty or not Listener then
    return
  end
  local handlerWarp = _G.SimpleDelegateFactory:CreateCallback(Caller, Listener)
  DelegateProperty:Add(self, handlerWarp)
  return handlerWarp
end

function AIC_Pet_C:RemoveDelegateListener(DelegateProperty, HandlerWarp)
  if not DelegateProperty or not HandlerWarp then
    return
  end
  DelegateProperty:Remove(self, HandlerWarp)
end

function AIC_Pet_C:GenerateExternalBlackboardParam()
  self.ExternalBBParamTable = {}
  self:GenerateExternalBlackBoardParamByKey(AIBlackboardKeyDefine.EscapeFromBattle, LuaParamType.Bool)
  self:GenerateExternalBlackBoardParamByKey(AIBlackboardKeyDefine.Sensity, LuaParamType.Float)
end

function AIC_Pet_C:GenerateExternalBlackBoardParamByKey(key, type)
  if self.isMFBTEnable then
    key = self:QueryCrossBlackboardKey(key)
  end
  local tempParam
  if type == LuaParamType.Bool then
    tempParam = LuaBoolParam()
  elseif type == LuaParamType.Float then
    tempParam = LuaFloatParam()
  else
    return Log.Error("[AIC] External blackboard generate failed.")
  end
  tempParam.type = type
  tempParam.isMFBTEnable = self.isMFBTEnable
  tempParam.useBlackboardKey = true
  tempParam.key = key
  self.ExternalBBParamTable[key] = tempParam
end

function AIC_Pet_C:TryStopAnimByName(animName)
  if self.isServerMoveRunning then
    table.insert(self.animStopQueue, animName)
  else
    self.Npc:StopAnim(animName)
  end
end

function AIC_Pet_C:SetIsMFBTEnableFlag(enableMFBT)
  self.isMFBTEnable = enableMFBT
  self:OnMFBTEnableChanged()
end

function AIC_Pet_C:OnMFBTEnableChanged()
  if self.ExternalBBParamTable then
    for k, v in pairs(self.ExternalBBParamTable) do
      if v then
        v.isMFBTEnable = self.isMFBTEnable
      end
    end
  end
end

local ShowSpawnPos = false

function AIC_Pet_C:RunMFBT(path, isDots)
  self:SetIsMFBTEnableFlag(true)
  local npc = self.Npc
  local AIComp = npc.AIComponent
  self.configId = npc.config.id
  self.petbaseId = npc:GetPetbaseId()
  self.npcDetailType = npc.serverData.base.detail_type or 0
  self.evoChain = AIComp.cfg_evochain
  self.performGroupId = AIComp.performId
  self.contentId = npc:GetContentId()
  self.enterSceneTime = npc.serverData.base.enter_scene_times or 0
  self:ApplyDomainParams()
  self:ApplyGroupParams()
  local serverDataBase = self.Npc.serverData.base
  self.selfLevel = serverDataBase.lv
  local born_pos = serverDataBase.born_pt.pos.x and serverDataBase.born_pt.pos or serverDataBase.pt.pos
  local born_dir = serverDataBase.born_pt.dir.z or 0
  local half_height = npc:GetScaledHalfHeight() or 0
  local _bornPosPtr = self.bornPos
  _bornPosPtr.X = born_pos.x
  _bornPosPtr.Y = born_pos.y
  _bornPosPtr.Z = (born_pos.z or 0) + half_height
  local _bornDirPtr = self.bornDir
  born_dir = math.rad(born_dir / 10.0)
  _bornDirPtr.X = math.cos(born_dir)
  _bornDirPtr.Y = math.sin(born_dir)
  _bornDirPtr.Z = 0
  if ShowSpawnPos then
    UE.UKismetSystemLibrary.Abs_DrawDebugPoint(self, UE.FVector(born_pos.x, born_pos.y, born_pos.z), 20, UE.FLinearColor(0, 1, 0, 1), 99)
    local pt = serverDataBase.pt.pos
    UE.UKismetSystemLibrary.Abs_DrawDebugPoint(self, UE.FVector(pt.x, pt.y + 20, pt.z), 20, UE.FLinearColor(0, 1, 1, 1), 99)
  end
  Log.DebugFormat("[AIC] RunMFBT=%s, cfg=%d, petbase=%d, perform=%d, group=%s", path, self.configId, self.petbaseId, self.performGroupId, group_param and "true" or "false")
  self:RunMFBehaviorTreeByPath(path, isDots)
end

function AIC_Pet_C:LoadFinished(result)
  self.Npc.AIComponent:OnLoadFinished(result)
  if result then
    self:InitNavFilter()
    self:InitModelBB()
    self:InitFunctionalBB()
    self:InitPredefinedBB()
    if self.Npc.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME then
      self:InitHomePetBB()
      if not (self.enterSceneTime and self.enterSceneTime <= 1) or self.Npc.IsMagicReplayActor and self.Npc:IsMagicReplayActor() then
      else
        _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.Npc:GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_HOME_PET_SPAWN, 1)
      end
    end
  end
end

function AIC_Pet_C:ApplyDomainParams()
  local npc = self.Npc
  if npc.AIComponent.IsCurrentInHome() then
    self.domainId = 1
    local AttrComp = npc.HomePetAttributeComponent
    if AttrComp then
      self.baseFriendliness = AttrComp.FriendlinessBase
    end
    self.collectionId = npc:GetServerId()
    return
  end
  if self.domainId and 0 == self.domainId then
    local belong_camp = npc.contentConf and npc.contentConf.belong_camp or 0
    if 0 == belong_camp then
      local sanctuary_id = npc.serverData.npc_base.owl_sanctuary_content_cfg_id
      if sanctuary_id and sanctuary_id > 0 then
        local sanctuary_conf = DataConfigManager:GetOwlSanctuaryConf(sanctuary_id)
        if sanctuary_conf then
          belong_camp = sanctuary_conf.camp_content_id or 0
        end
      end
    end
    self.domainId = 0 == belong_camp and 0 or belong_camp | 4294967296
  end
  if self.collectionId and 0 == self.collectionId then
    self.collectionId = npc.AIComponent.cfg_habitat
  end
end

function AIC_Pet_C:ApplyGroupParams()
  local npc = self.Npc
  local group_param = npc.AIComponent.groupParam
  if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_NIGHTMARE_ELITE) and npc.config.nightmare_ai_group and 0 ~= npc.config.nightmare_ai_group then
    self:AppendGroupParam(npc.config.nightmare_ai_group, npc.config.ai_group_role_id, 0)
    return
  end
  if group_param then
    for _, param in ipairs(group_param) do
      if 0 ~= param.ai_group then
        self:AppendGroupParam(param.ai_group, param.ai_group_role_id, param.ai_group_priority)
      end
    end
    if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD) then
      self:AppendGroupParam(280021, {90}, 0)
    end
    local petbase = npc:GetPetbaseId()
    if petbase then
      local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petbase, true)
      if petbaseConf and petbaseConf.pet_habitat_group_role_type then
        local habitatGroupRoleType = petbaseConf.pet_habitat_group_role_type
        self:AppendGroupParam(100001, {habitatGroupRoleType}, 0)
      end
    end
  end
end

function AIC_Pet_C:InitModelBB()
  local Hab = self.Npc.modelConf.habitat_flag
  if Hab == Enum.HABITAT_FLAG.HAB_FLY or Hab == Enum.HABITAT_FLAG.HAB_FLY_WATER then
    self:SetDotsCommonBool("Global_CanEverFly", true)
  end
  local ServerData = self.Npc.serverData
  if ServerData.pet_info and ServerData.pet_info.gid then
    self:SetDotsCommonFloat("Global_PartnerIdx", self.Npc.serverData.pet_info.gid % 6 or 0)
  end
  if ServerData.npc_base.initial_affectionate then
    self:SetDotsCommonInt("Global_InitialTerrainAffinity", ServerData.npc_base.initial_affectionate)
  end
  local mutation_type = ServerData.npc_base.mutation_type or 0
  if 0 ~= mutation_type then
    if 0 ~= Enum.MutationDiffType.MDT_SHINING & mutation_type then
      self:SetDotsCommonInt("Global_HasShiningType", 1)
    end
    if 0 ~= Enum.MutationDiffType.MDT_GLASS & mutation_type then
      self:SetDotsCommonInt("Global_HasClassType", 1)
    end
    local CHAOS_MASK = Enum.MutationDiffType.MDT_CHAOS | Enum.MutationDiffType.MDT_CHAOS_TWO | Enum.MutationDiffType.MDT_CHAOS_THREE
    if 0 ~= CHAOS_MASK & mutation_type then
      self:SetDotsCommonInt("Global_HasChaosType", 1)
    end
  end
end

function AIC_Pet_C:InitPredefinedBB()
  local serverData = self.Npc.serverData
  local refreshContentId = serverData.npc_base.npc_content_cfg_id
  if not refreshContentId or 0 == refreshContentId then
    return
  end
  local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(refreshContentId, true)
  if not refreshConf then
    return
  end
  if 0 ~= refreshConf.bb_input_id then
    local inputBlackboardsConf = _G.DataConfigManager:GetNrcAiBbInputConf(refreshConf.bb_input_id, true)
    if not inputBlackboardsConf then
      return
    end
    for i = 1, #inputBlackboardsConf.blackboard_input do
      local item = inputBlackboardsConf.blackboard_input[i]
      if item.data_type == Enum.BBInputType.BBIT_INT then
        self:SetDotsCommonInt(item.blackboard_name, tonumber(item.data))
      elseif item.data_type == Enum.BBInputType.BBIT_FLOAT then
        local factor = 100
        if 0 ~= item.additional_para then
          factor = item.additional_para
        end
        self:SetDotsCommonFloat(item.blackboard_name, tonumber(item.data) / factor)
      elseif item.data_type == Enum.BBInputType.BBIT_BOOL then
        self:SetDotsCommonBool(item.blackboard_name, not string.IsNilOrEmpty(item.data))
      elseif item.data_type == Enum.BBInputType.BBIT_VEC then
        local areaConf = _G.DataConfigManager:GetAreaConf(tonumber(item.data))
        if areaConf then
          local pos = areaConf.pos[item.additional_para + 1]
          if pos then
            self:SetDotsCommonVector(item.blackboard_name, _localUE4.FVector(pos.position_xyz[1], pos.position_xyz[2], pos.position_xyz[3]))
          end
        end
      elseif item.data_type == Enum.BBInputType.BBIT_STRING then
        self:SetDotsCommonString(item.blackboard_name, item.data)
      end
    end
  end
  local bWriteToParent = false
  local ParentController
  local bWriteToChild = false
  local ChildControllers = {}
  local src_npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, serverData.npc_base.src_npc_id)
  if refreshConf.refresh_type == Enum.RefreshType.RFT_RELY and nil ~= src_npc and src_npc.AIComponent:IsActive() then
    bWriteToParent = true
    ParentController = src_npc.AIComponent.AIController
  end
  local Model = self.Npc.viewObj
  local Logic = self.Npc.luaObj
  local selfUObjectId = _localUE4.UNRCStatics.GetObjectUniqueID(Model)
  if Logic.reliedPet and #Logic.reliedPet > 0 then
    bWriteToChild = true
    for _, npc in ipairs(Logic.reliedPet) do
      if not npc.AIComponent:IsAILoaded() then
        bWriteToChild = false
        break
      end
      table.insert(ChildControllers, _, npc.AIComponent.AIController)
    end
  end
  if bWriteToParent and ParentController then
    local ParentLogic = src_npc.luaObj
    if ParentLogic.reliedPet then
      for idx, npc in ipairs(ParentLogic.reliedPet) do
        if self.Npc == npc then
          local parentId = _localUE4.UNRCStatics.GetObjectUniqueID(src_npc.viewObj)
          self:SetDotsCommonObject("Global_RelyParent", parentId)
          break
        end
      end
      ParentController:SetDotsCommonObject("Global_RelyChild", selfUObjectId)
    end
  end
  if bWriteToChild then
    for idx, owner in ipairs(ChildControllers) do
      local childId = _localUE4.UNRCStatics.GetObjectUniqueID(owner.Npc.viewObj)
      self:SetDotsCommonObject("Global_RelyChild", childId)
      owner:SetDotsCommonObject("Global_RelyParent", selfUObjectId)
    end
  end
end

function AIC_Pet_C:InitFunctionalBB()
  local npc = self.Npc
  local AIComp = npc.AIComponent
  local habitat_id = AIComp.cfg_habitat
  local evochain_id = AIComp.cfg_evochain
  if 0 == habitat_id and 0 == evochain_id then
    return
  end
  local serverId = npc:GetServerId()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CatchRecord = player and player.CatchRecordComponent
  if CatchRecord then
    local context = UE4Helper.GetCurrentWorld()
    local hab_data = CatchRecord.habitatRecord[habitat_id]
    if hab_data then
      UE.UUnitAIHelper.SetBatchBlackboardValueInt(context, _G.AIDefines.DotsBatchFilterType.UID, serverId, _G.AIDefines.DotsBlackboardKeyBundle.HabitatCatchRecord, {
        hab_data.acc_try_catch_time,
        hab_data.acc_catch_succ_time,
        hab_data.acc_catch_fail_time,
        hab_data.exist_npc_num,
        hab_data.can_refresh_npc_num
      })
    end
    local evo_data = CatchRecord.evoChainRecord[evochain_id]
    if evo_data then
      UE.UUnitAIHelper.SetBatchBlackboardValueInt(context, _G.AIDefines.DotsBatchFilterType.UID, serverId, _G.AIDefines.DotsBlackboardKeyBundle.EvoChainCatchRecord, {
        evo_data.acc_try_catch_time,
        evo_data.acc_catch_succ_time,
        evo_data.acc_catch_fail_time
      })
    end
  end
  local HabRelData = habitat_id > 0 and AIComp.GetManager().HabitatRelationMap[habitat_id] or nil
  if HabRelData then
    local firstRes = 0
    local secondRes = 0
    if HabRelData.first_neighbor and HabRelData.first_neighbor.restrain_relation then
      for _, relType in ipairs(HabRelData.first_neighbor.restrain_relation) do
        if relType > 1 and relType < 5 then
          firstRes = relType
          break
        end
      end
    end
    if HabRelData.second_neighbor and HabRelData.second_neighbor.restrain_relation then
      for _, relType in ipairs(HabRelData.second_neighbor.restrain_relation) do
        if relType > 1 and relType < 5 then
          firstRes = relType
          break
        end
      end
    end
    UE.UUnitAIHelper.SetBatchBlackboardValueInt(nil, _G.AIDefines.DotsBatchFilterType.UID, serverId, _G.AIDefines.DotsBlackboardKeyBundle.RestraintNeighbors, {firstRes, secondRes})
  end
end

function AIC_Pet_C:InitHomePetBB()
  RequireHomePetAttributeComponent()
  local homeNpc = self.Npc
  local AttrComp = homeNpc:EnsureComponent(HomePetAttributeComponent)
  if AttrComp then
    local nestNpc = AttrComp.NestNpcId and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, AttrComp.NestNpcId)
    if nestNpc then
      self:SetDotsCommonVector("Global_NestPos", nestNpc:GetActorLocation())
    else
      self:SetDotsCommonVector("Global_NestPos", homeNpc.serverPos)
    end
    self:SetDotsCommonInt("Global_FriendlyLevel", AttrComp:GetFriendlinessCurrent())
  end
end

function AIC_Pet_C:HookBTTreeInit()
end

function AIC_Pet_C:HookBTTreeStart()
  self.mfbtLuaComponent:OnTreeInit()
end

function AIC_Pet_C:HookBTTreeDestroy()
  self.mfbtLuaComponent:OnTreeDestroy()
end

function AIC_Pet_C:HookBTTaskStart(Event)
  self.mfbtLuaComponent:OnBTTaskStart(Event.SubtreeID, Event.NodeExeID, Event.LuaFileName)
end

function AIC_Pet_C:HookBTTaskTick(Event)
  self.mfbtLuaComponent:OnBTTaskTick(Event.SubtreeID, Event.NodeExeID, Event.LuaFileName, Event.Deltatime)
end

function AIC_Pet_C:HookBTTaskInterrupt(Event, Finalizing)
  self.mfbtLuaComponent:OnBTTaskInterrupt(Event.SubtreeID, Event.NodeExeID, Finalizing)
end

function AIC_Pet_C:HookBTServiceStart(Event, Finalizing)
  self.mfbtLuaComponent:OnBTServiceStart(Event.SubtreeID, Event.NodeExeID, Event.LuaFileName, Finalizing)
end

function AIC_Pet_C:HookBTServiceTick(Event)
  self.mfbtLuaComponent:OnBTServiceTick(Event.SubtreeID, Event.NodeExeID, Event.LuaFileName, Event.Deltatime)
end

function AIC_Pet_C:HookBTServiceEnd(Event, Finalizing)
  self.mfbtLuaComponent:OnBTServiceEnd(Event.SubtreeID, Event.NodeExeID, Finalizing)
end

function AIC_Pet_C:HookBTDecoratorCalc(Event)
  Log.Debug("HookBtDecoratorCalc: \228\184\141\229\133\129\232\174\184\229\134\141\228\189\191\231\148\168lua\232\163\133\233\165\176\229\153\168, file =", Event.LuaFileName)
end

function AIC_Pet_C:OnNodeInstanceCreated(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
  return self.mfbtLuaComponent:OnNodeInstanceCreated(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
end

function AIC_Pet_C:OnNodeInstanceCreateFinished(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
  self.mfbtLuaComponent:OnNodeInstanceCreateFinished(SubtreeID, NodeExeID, NodeType, LuaActionName, TreeName)
end

function AIC_Pet_C:OnParamCreateInt(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateInt(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateFloat(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateFloat(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateBool(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateBool(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateString(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateString(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateQuaternion(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateQuaternion(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateVector(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateVector(IsArray, ParamName, Value, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:OnParamCreateObject(IsArray, ParamName, IsUseBlackboard, BlackboardKey)
  self.mfbtLuaComponent:OnParamCreateObject(IsArray, ParamName, IsUseBlackboard, BlackboardKey)
end

function AIC_Pet_C:SelectedToDebug()
  if self.Npc.AIComponent.isServerAI then
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "[MFBT] \229\183\178\233\128\137\228\184\173\229\174\162\230\136\183\231\171\175AI\232\176\131\232\175\149\229\175\185\232\177\161")
  end
end

function AIC_Pet_C:RequestServerDebug()
  local req = _G.ProtoMessage.newZoneSceneMfbtNpcDebugReq()
  req.npc_id = self.Npc.serverData.base.actor_id
  req.op = 1
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MFBT_NPC_DEBUG_REQ, req, self, self.OnResponseMFBTDebug, false, true)
  Log.Debug("[AIC_Pet_C:SelectedToDebug] Switch Debug Actor, start receiving mfbtDebug delegates.")
end

function AIC_Pet_C:OnResponseMFBTDebug(rsp)
  if 0 == rsp.ret_info.ret_code then
    if not self.mfbtDebuging and self.CreateMFDebugController then
      if self:CreateMFDebugController(rsp.bt_path) then
        self.mfbtDebuging = true
        Log.Debug("[MFBT] Start Remote Debugging with btree:%s", rsp.bt_path)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "[MFBT] \229\188\128\229\167\139\232\176\131\232\175\149")
      else
        Log.WarningFormat("[MFBT] Path Invalid:%s", rsp.bt_path)
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "[MFBT] \229\183\178\233\128\137\228\184\173\230\156\141\229\138\161\229\153\168AI\232\176\131\232\175\149\229\175\185\232\177\161\239\188\140\233\135\141\230\150\176\229\136\155\229\187\186\232\176\131\232\175\149\232\191\158\230\142\165")
    end
  else
    Log.Error("[MFBT] Remote-Debugging RSP = failed.")
  end
end

function AIC_Pet_C:OnMfbtDebug(action)
  if self.MfDebugEventParser then
    for _, v in ipairs(action.event_datas) do
      Log.Debug("EventType:", v.event_type)
      local LuaData = {}
      local Index = v.event_type
      LuaData[Index] = 0
      for _, BytesData in ipairs(v.event_data) do
        Index = Index + 1
        LuaData[Index] = BytesData
      end
      self:MfDebugEventParser(LuaData)
    end
  end
end

function AIC_Pet_C:InitNavFilter()
  local isBoss = self.Npc.config.genre == Enum.ClientNpcType.CNT_PETBOSS
  if not self.Npc:IsPet() or isBoss then
  else
    self:SetNavFlagFilter(NavigationDefines.FlagId.SafeArea, false)
  end
  local modelConf = self.Npc.modelConf
  if modelConf and 0 == modelConf.exclude_nav_flag & 1 << NavigationDefines.FlagId.Water then
  elseif not isBoss then
    self:SetNavFlagFilter(NavigationDefines.FlagId.Water, false)
  end
  if self.Npc.AIComponent.IsCurrentInHome() then
    if self.Npc:GetScaledRadius() > 60 then
      self:SetNavFlagFilter(NavigationDefines.FlagId.HomeDoor, false)
    end
    local pathFollow = self:GetPathFollowingComponent()
    if pathFollow and pathFollow.SetCrowdSimulationStateEnabledImme then
      pathFollow:SetCrowdSimulationStateEnabledImme(false)
    end
  end
end

function AIC_Pet_C:GetAreaConf(AreaID)
  local AreaRow = UE4.TArray(UE4.FVector)
  local AreaConf = _G.DataConfigManager:GetAreaConf(AreaID)
  if AreaConf and AreaConf.pos and #AreaConf.pos > 0 then
    local Idx = 1
    while Idx <= #AreaConf.pos do
      local Location = AreaConf.pos[Idx].position_xyz
      local ResultLocation = UE4.FVector()
      ResultLocation = UE4.FVector(Location[1], Location[2], Location[3])
      AreaRow:Add(ResultLocation)
    end
  end
  return AreaRow
end

function AIC_Pet_C:GetCurrentReactionPetData()
  local result = UE.FNrcAiReactionNpcContext()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local ridingPet = localPlayer.viewObj.BP_RideComponent.ScenePet
  local pet_gid = -1
  local petObj
  if ridingPet then
    pet_gid = ridingPet.gid
  else
    local thrown_pets = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetPetByPlayer, localPlayer.serverData.base.actor_id or 0)
    local last_thrown_pet_actor_id = #thrown_pets > 0 and thrown_pets[#thrown_pets]
    if last_thrown_pet_actor_id then
      local last_thrown_pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, last_thrown_pet_actor_id)
      if last_thrown_pet then
        pet_gid = last_thrown_pet.serverData.pet_info.gid
        petObj = last_thrown_pet.viewObj
      end
    end
  end
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet_gid)
  if not PetData then
    Log.PrintScreenMsg("[NPCReaction] %s decision: cant find valid pet", self.Npc.config.name)
    return result
  end
  local npcGroup = self.Npc.config.npc_group_id
  local is_awesome = PetData.talent_rank == _G.Enum.PetTalentRate.PTR_PERFECT
  local is_alterchromo = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING)
  local is_rainbow = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS)
  result.bFound = true
  result.bIsAwesome = is_awesome
  result.bIsAlterChromo = is_alterchromo
  result.bIsRainBow = is_rainbow
  result.PetBaseId = PetData.base_conf_id
  result.QuerierConfigGroupId = npcGroup
  if petObj then
    result.PetActor = petObj
  end
  return result
end

function AIC_Pet_C:GetPlayerRidingPetBaseId()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local ridingPet = localPlayer.viewObj.BP_RideComponent.ScenePet
  if ridingPet then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(ridingPet.gid)
    if PetData then
      return PetData.base_conf_id
    end
  end
  return 0
end

function AIC_Pet_C:GetPlayerFashionId()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  return fashionInfo and fashionInfo.suit_id or 0
end

function AIC_Pet_C:GetPlayerSuitAIEffect()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_FASHION_SUITS
  local statusParams = localPlayer.statusComponent._statusParams[statusId]
  return statusParams and statusParams.ai_param or 0
end

function AIC_Pet_C:OnMoveFailedMaxCount()
end

return AIC_Pet_C
