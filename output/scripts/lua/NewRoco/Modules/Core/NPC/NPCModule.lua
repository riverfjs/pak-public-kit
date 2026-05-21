local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local InteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.InteractionComponent")
local LocalPetComponent = require("NewRoco.Modules.Core.NPC.Component.LocalPetComponent")
local PetStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusComponent")
local StunComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.StunComponent")
local PotentialEnergyComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PotentialEnergyComponent")
local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
local BattleNPCGenerator = require("NewRoco.Modules.Core.NPC.LuaClass.BattleNPCGenerator")
local SceneNpc = require("NewRoco.Modules.Core.Scene.Actor.SceneNpc")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local PriorityQueue = require("Utils.PriorityQueue")
local Queue = require("Utils.Queue")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCBrutalFinder = require("NewRoco.Modules.Core.NPC.LuaClass.NPCBrutalFinder")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local ServerAICommandEnum = require("NewRoco.Modules.Core.Scene.Component.AI.ServerAICommandEnum")
local NPCActorPool = require("NewRoco.Modules.Core.NPC.NPCActorPool")
local NPCActorPoolNew = require("NewRoco.Modules.Core.NPC.NPCActorPoolNew")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local ThrowStarSession = require("NewRoco.Modules.Core.NPC.MagicStar.ThrowStarSession")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local SceneAIManager = require("NewRoco.AI.SceneAIManager")
local NPCEnvQueryManager = require("NewRoco.Modules.Core.NPC.NPCEnvQueryManager")
local MapRegionAreaUtil = require("NewRoco.Modules.Core.Scene.Map.MapRegionAreaUtil")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PetHolderComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetHolderComponent")
local PetInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetInteractionComponent")
local LockIndicatorComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.LockIndicatorComponent")
local PendantComponent = require("NewRoco.Modules.Core.Scene.Component.Pendant.PendantComponent")
local SyncPetActionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SyncPetActionComponent")
local ThrowSessionManager = require("NewRoco.Modules.Core.NPC.ThrowSession.ThrowSessionManager")
local WorldCombatBuffComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatBuffComponent")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local ActorHolderComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.ActorHolderComponent")
local AIDefines = require("NewRoco.AI.AIDefines")
local ShowHideFactory = require("NewRoco.Modules.Core.NPC.ShowHide.ShowHideFactory")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local NpcOption = require("NewRoco.Modules.Core.NPC.Executors.NpcOption")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ResObject = require("NewRoco.Utils.ResObject")
local InstancePool = require("Utils.InstancePool")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local DeviceEvent = require("NewRoco.Modules.Core.App.DeviceEvent")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local ThrowLightBallSession = require("NewRoco.Modules.Core.NPC.MagicStar.ThrowLightBallSession")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local CatchPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchPetComponent")
local HomeSceneNPC = require("NewRoco.Modules.System.Home.HomeNPC.HomeSceneNPC")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local BornDieComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.BornDieComponent")
local CreateMagicComponent = require("NewRoco.Modules.System.MagicCreation.CreateMagicComponent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local PetResponseComponent = require("NewRoco.Modules.Core.Scene.Component.Show.PetResponseComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local NPCBaseCommon = UE.NPCBaseCommon
local pairs = _ENV.pairs
local Ticker
local PlayerPosCache = UE.FVector(0, 0, 0)
local PlayerForwardsCache = UE.FVector(0, 0, 0)
local PlayerInteractState
local PlayerRadiusDiff = 0
local RolePlayBehaviorID = 0
local FrameCount = -1
local FrameOperateCount = 0
local GetFrameCount = _G.GetFrameCount
local OldCheck

local function ToggleNPCCheck(Enable)
  NPCBaseCommon.ToggleNPCCheck(Enable)
  if nil == OldCheck then
    Log.Debug("[NpcAction][Common]\232\174\190\231\189\174\230\152\175\229\144\166\229\188\128\229\144\175\230\163\128\230\159\165\230\137\128\230\156\137NPC\228\186\164\228\186\146", Enable)
  elseif OldCheck ~= Enable then
    Log.Debug("[NpcAction][Common]", Enable and "\229\188\128\229\144\175\230\163\128\230\159\165\230\137\128\230\156\137NPC\228\186\164\228\186\146" or "\229\133\179\233\151\173\230\163\128\230\159\165\230\137\128\230\156\137NPC\228\186\164\228\186\146")
  end
  OldCheck = Enable
end

local SignificanceCalcNPC = 1
local ShouldFindNPC = true
_G.NPCModuleCmd = reload("NewRoco.Modules.Core.NPC.NPCModuleCmd")
local NPCModule = NRCModuleBase:Extend("NPCModule")

local function CmpNPCFrameLoadPriority(npc1, npc2)
  local dis1 = npc1.squaredDis2LocalIgnoreZ or 100000
  local dis2 = npc2.squaredDis2LocalIgnoreZ or 100000
  local is_initial1 = npc1:IsInitialNPC()
  local is_initial2 = npc2:IsInitialNPC()
  if is_initial1 ~= is_initial2 then
    return is_initial1
  end
  if not npc1.squaredDis2LocalIgnoreZ or not npc2.squaredDis2LocalIgnoreZ then
  end
  return dis1 < dis2
end

function NPCModule:OnConstruct()
  Log.Debug("NPCModule:OnConstruct")
  self.data = self:SetData("NPCModuleData", "NewRoco.Modules.Core.NPC.NPCModuleData")
  self._npcDic = {}
  self._npcIterDic = {}
  self._npcContentDic = {}
  self._npcLogicDic = {}
  self._hashIDQueue = Queue(128)
  self._coeNpcNum = 0
  self._prepareMountDic = {}
  self._lockListeners = {}
  self._npcFinders = {}
  MakeWeakTable(self._npcContentDic)
  MakeWeakTable(self._npcLogicDic)
  self._npc2LoadQueue = PriorityQueue()
  self._npc2LoadQueue:SetCmpFunction(CmpNPCFrameLoadPriority)
  self.npcActorPool = NPCActorPool()
  self.frame = 0
  self.MapLoaded = false
  self.playerTeleporting = false
  self.playerPreTeleporting = false
  self.teleportBlockLoadDis = 0.5
  self.cachedBattleNpcGenerate = {}
  self._throwItemNPC = {}
  self._thrwoCreateCallback = {}
  self._placeSpawnedDic = {}
  MakeWeakTable(self._placeSpawnedDic)
  self._placeEnteredDic = {}
  MakeWeakTable(self._placeEnteredDic)
  self.FurnitureView = {}
  MakeWeakTable(self.FurnitureView)
  self.FurnitureNPC = {}
  MakeWeakTable(self.FurnitureNPC)
  self.MonitorNPCByConfID = {}
  self.MonitorNPCByServerID = {}
  self.followingNpc = nil
  self.HasEnterBattle = false
  self.ThrowSessionManager = ThrowSessionManager()
  self.localParticles = {}
  self.EQSManager = NPCEnvQueryManager()
  self.MapRegionAreaUtil = MapRegionAreaUtil()
  self.SceneAIManager = SceneAIManager()
  self.LocalNPCCounter = 0
  self.client_vis_nty_count = 0
  self.LastBattleEndTime = -1
  self.InitialActorIDs = {}
  self.subHudPools = {}
  self.BallRes = {}
  self.StarMagicQuality = 2
  self.revivePointNPC = {}
  self.GMMarkerPointNPC = {}
  self.playerPetMap = {}
  self.totalPlayerPetNum = 0
  AIDefines.RegisterCycleCounters()
  NPCLuaUtils.PreLoad("Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_NPCItemStar.BP_NPCItemStar_C'", _G.PriorityEnum.Active_Player_Action)
  NPCLuaUtils.PreLoad("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/StarMagic/G6_StarMagic_Critical_Hit01.G6_StarMagic_Critical_Hit01_C'")
  NPCLuaUtils.PreLoad("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/StarMagic/G6_StarMagic_Hit01.G6_StarMagic_Hit01_C'")
  NPCLuaUtils.PreLoad("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/StarMagic/G6_StarMagic_Hit02.G6_StarMagic_Hit02_C'")
  NPCLuaUtils.PreLoad("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/StarMagic/G6_StarMagic_Hit03.G6_StarMagic_Hit03_C'")
  NPCLuaUtils.PreLoad("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/StarMagic/G6_StarMagic_Hit04.G6_StarMagic_Hit04_C'")
  NPCLuaUtils.PreLoad("Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_MoZhang.BP_MoZhang_C'")
  NPCLuaUtils.PreLoad("SkeletalMesh'/Game/ArtRes/AnimSequence/Human/PC/PC3/Avatar/Mw/32500101/SKM_PC3_Mw_32500101.SKM_PC3_Mw_32500101'")
  NPCLuaUtils.PreLoad("Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_NPCMagicLightBall.BP_NPCMagicLightBall_C'")
  NPCLuaUtils.PreLoad(_G.UEPath.CATCH_SKILL_WORLD, _G.PriorityEnum.Active_Player_Action)
  NPCLuaUtils.PreLoad("/Game/ArtRes/Effects/G6Skill/Yuancheng/CallBack_False_Ball", _G.PriorityEnum.Active_Player_Action)
  NPCLuaUtils.PreLoad("/Game/ArtRes/Effects/G6Skill/Yuancheng/CallOut_Suc", _G.PriorityEnum.Active_Player_Action)
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance:InitializeDotsSubsystem()
  end
  self.ServerAICount = 0
  self.MAX_TIME_FOR_LOADING_NPC = 8000
  self.MAX_NUM_OF_MOST_IMPORTANT_NPC = 5
end

function NPCModule:RecordOperations()
  local ThisFrameCount = GetFrameCount()
  if ThisFrameCount == FrameCount then
    FrameOperateCount = FrameOperateCount + 1
  else
    FrameOperateCount = 0
    FrameCount = ThisFrameCount
  end
end

function NPCModule:CheckOperation()
  local ThisFrameCount = GetFrameCount()
  if ThisFrameCount == FrameCount then
    return FrameOperateCount > 0
  else
    return false
  end
end

function NPCModule:FindBallHeadBounce(Actor, Owner, Callback)
  return self.EQSManager:Run("BallHeadBounce", UE.EEnvQueryRunMode.SingleResult, nil, Actor, Owner, Callback)
end

function NPCModule:FindFarRelease(Actor, StandType, InnerRadius, OuterRadius, Owner, Callback)
  local Runner = self.EQSManager:Get("FarRelease")
  if not Runner then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150EQSRunner:FarRelease")
    return -1
  end
  local Request = Runner:MakeRequest(nil, Actor)
  Request:SetIntParam("Stand.StandType", StandType or 0)
  Request:SetFloatParam("Donut.InnerRadius", InnerRadius or 200)
  Request:SetFloatParam("Donut.OuterRadius", OuterRadius or 500)
  return Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, Owner, Callback)
end

function NPCModule:QueryPosForServer(Owner, Callback)
  local Runner = self.EQSManager:Get("PosForServer")
  if not Runner then
    _G.tcall(Owner, Callback, nil)
    return -1
  end
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not LocalPlayer or not LocalPlayer.viewObj then
    _G.tcall(Owner, Callback, nil)
    return -1
  end
  local Request = Runner:MakeRequest(nil, LocalPlayer.viewObj)
  Request:SetIntParam("Stand.StandType", 0)
  Request:SetFloatParam("Donut.InnerRadius", 400)
  Request:SetFloatParam("Donut.OuterRadius", 1000)
  local QueryID = Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.AllMatching, Request, Owner, Callback)
  if QueryID < 0 then
    Log.Error("QueryNpcPosForServer failed", QueryID)
  end
end

function NPCModule:FindFanFrontRelease(Actor, StandType, InnerRadius, OuterRadius, Owner, Callback)
  local Runner = self.EQSManager:Get("FanFront")
  if not Runner then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150EQSRunner:FanFront")
    return -1
  end
  local Request = Runner:MakeRequest(nil, Actor)
  Request:SetIntParam("Stand.StandType", StandType or 0)
  Request:SetFloatParam("Donut.InnerRadius", InnerRadius or 200)
  Request:SetFloatParam("Donut.OuterRadius", OuterRadius or 500)
  return Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, Owner, Callback)
end

function NPCModule:FindStandRelease(Actor, StandType, InnerRadius, OuterRadius, Owner, Callback)
  local Runner = self.EQSManager:Get("CloseRelease")
  if not Runner then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150EQSRunner:CloseRelease")
    return -1
  end
  local Request = Runner:MakeRequest(nil, Actor)
  if Owner and Owner.ModelID then
    local ModelConf = _G.DataConfigManager:GetModelConf(Owner.ModelID)
    local CheckCapsuleRadius = ModelConf and ModelConf.capsule_radius
    local CheckHeight = ModelConf and ModelConf.capsule_halfheight
    CheckCapsuleRadius = CheckCapsuleRadius and CheckCapsuleRadius * 7.5E-4 or 0
    CheckHeight = CheckHeight and CheckHeight * 7.5E-4 or 0
    local CheckZOffset = math.max(CheckHeight, CheckCapsuleRadius) + 20
    Request:SetFloatParam("CustomOverlap.Radius", CheckCapsuleRadius)
    Request:SetFloatParam("CustomOverlap.HalfHeight", CheckHeight)
    Request:SetFloatParam("CustomOverlap.OverlapZOffset", CheckZOffset)
  end
  Request:SetIntParam("Stand.StandType", StandType or 0)
  Request:SetFloatParam("Donut.InnerRadius", InnerRadius or 200)
  Request:SetFloatParam("Donut.OuterRadius", OuterRadius or 500)
  return Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, Owner, Callback)
end

function NPCModule:FindSenseRelease(Actor, StandType, Owner, Callback)
  local Runner = self.EQSManager:Get("SenseRelease")
  if not Runner then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150EQSRunner:SenseRelease")
    return -1
  end
  local Request = Runner:MakeRequest(nil, Actor)
  Request:SetIntParam("Stand.StandType", StandType or 0)
  return Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, Owner, Callback)
end

function NPCModule:FindPetBlessingRelease(Actor, StandType, Params, Owner, Callback)
  local Runner = self.EQSManager:Get("PetBlessing")
  if not Runner then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150EQSRunner:PetBlessing")
    return -1
  end
  local Request = Runner:MakeRequest(nil, Runner)
  Request:SetIntParam("Stand.StandType", StandType or 0)
  local playerId1 = Params and Params.playerId1
  local playerId2 = Params and Params.playerId2
  local player1 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerId1)
  local player2 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerId2)
  local playerLocation1 = player1.viewObj:K2_GetActorLocation()
  local playerLocation2 = player2.viewObj:K2_GetActorLocation()
  Request:SetFloatParam("TargetLocationX1", playerLocation1.X)
  Request:SetFloatParam("TargetLocationY1", playerLocation1.Y)
  Request:SetFloatParam("TargetLocationZ1", playerLocation1.Z)
  Request:SetFloatParam("TargetLocationX2", playerLocation2.X)
  Request:SetFloatParam("TargetLocationY2", playerLocation2.Y)
  Request:SetFloatParam("TargetLocationZ2", playerLocation2.Z)
  Request:SetFloatParam("Grid.GenerateCenterX", (playerLocation1.X + playerLocation2.X) / 2)
  Request:SetFloatParam("Grid.GenerateCenterY", (playerLocation1.Y + playerLocation2.Y) / 2)
  Request:SetFloatParam("Grid.GenerateCenterZ", (playerLocation1.Z + playerLocation2.Z) / 2)
  return Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, Owner, Callback)
end

function NPCModule:CancelRequest(QueryId)
  local Runner = self.EQSManager:Get("SenseRelease")
  Runner:RemoveRequest(QueryId)
end

function NPCModule:RunSceneEQS(Name, Type, Query, Actor, Owner, Callback)
  return self.EQSManager:Run(Name, Type, Query, Actor, Owner, Callback)
end

function NPCModule:GetEQS(Name)
  return self.EQSManager:Get(Name)
end

function NPCModule:GetBallClass(ballId)
  local ballNpcID = 50338
  local Klass = _G.NRCBigWorldPreloader:Get("Ball")
  local BallConf
  local BallID = ballId
  if not BallID or 0 == BallID then
    BallID = 100002
  end
  BallConf = _G.DataConfigManager:GetBallConf(BallID)
  local PreloadObj
  if BallConf then
    if BallConf.npc_id > 0 then
      ballNpcID = BallConf.npc_id
    end
    PreloadObj = self.BallRes[BallID]
    if PreloadObj then
      local NewBall = PreloadObj:Get()
      if NewBall then
        Klass = NewBall
      end
    else
      local ModelConf = _G.DataConfigManager:GetModelConf(BallConf.fx_source)
      if ModelConf then
        local Res = ResObject.MakeUClass(ModelConf.path)
        self.BallRes[BallID] = Res
        Res:StartLoad(self, self.OnBallLoaded)
      end
    end
  end
  return ballNpcID, Klass, PreloadObj
end

function NPCModule:RetryGetBallClass(ballId, owner_id, custom_priority)
  if self.BallRes[ballId] then
    local res = self.BallRes[ballId]
    res:DoRelease()
    self.BallRes[ballId] = nil
  end
  local Klass = _G.NRCBigWorldPreloader:Get("Ball")
  local itemNpc = self:CreateFakeNpc(50038, false, nil, owner_id, Klass, custom_priority)
  if not itemNpc or not itemNpc.viewObj then
    Log.Error("\229\176\157\232\175\149\232\142\183\229\143\150\230\156\128\229\186\149\229\177\130\231\154\132\231\144\131\232\191\155\232\161\140\228\191\157\229\186\149\228\185\159\229\164\177\232\180\165\228\186\134")
    return nil
  end
  return itemNpc
end

function NPCModule:CreateThrowBagItem(itemInfo, throw_session_id, owner_id, hasPet)
  local ballNpcId, Klass, PreloadObj = self:GetBallClass(itemInfo.id)
  local local_player_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  local custom_priority = _G.PriorityEnum.Passive_3P_Throw_BP
  if local_player_id == owner_id then
    custom_priority = _G.PriorityEnum.Active_Player_Throw_BP
  end
  local itemNpc = self:CreateFakeNpc(ballNpcId, false, nil, owner_id, Klass, custom_priority)
  if not itemNpc then
    return nil
  end
  if not itemNpc.viewObj then
    Log.Error("\229\146\149\229\153\156\231\144\131\231\154\132\232\181\132\230\186\144\230\156\137\233\151\174\233\162\152\239\188\140\230\136\145\228\187\172\232\167\163\233\153\164\230\142\137\229\188\149\231\148\168\228\184\139\230\172\161\233\135\141\230\150\176\229\138\160\232\189\189\228\184\128\230\172\161", itemInfo.id)
    itemNpc = self:RetryGetBallClass(itemInfo.id, owner_id, custom_priority)
    if not itemNpc or not itemNpc.viewObj then
      Log.Error("\229\176\157\232\175\149\232\142\183\229\143\150\230\156\128\229\186\149\229\177\130\231\154\132\231\144\131\232\191\155\232\161\140\228\191\157\229\186\149\228\185\159\229\164\177\232\180\165\228\186\134")
      return nil
    end
  end
  local session = ThrowSession.CreateItem(itemInfo)
  session:SetBallId(itemInfo.id)
  if throw_session_id then
    session:SetSeqID(throw_session_id)
  end
  session.Ball = itemNpc
  session:SetHasSyncPet(hasPet or false)
  session:SetOwnerId(owner_id)
  itemNpc:SetThrowSession(session)
  if itemNpc and itemNpc.viewObj then
    itemNpc.viewObj:SetActorHiddenInGame(false)
  end
  self.ThrowSessionManager:AssignThrowBagItemSession(session, owner_id)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.ADD_THROW_SESSION_ITEM, session)
  return itemNpc
end

function NPCModule:CreateThrowPetBall(petData, owner_id)
  if not petData then
    Log.Warning("petData\230\152\175\231\169\186\231\154\132\239\188\140\230\151\160\230\179\149\229\136\155\229\187\186ThrowPetBall\239\188\140\230\139\146\231\187\157")
    return nil
  end
  local Session = ThrowSession.GetWithGID(petData.gid)
  if Session then
    Log.Warning("\233\135\141\229\164\141\232\175\183\230\177\130\229\136\155\229\187\186\229\144\140\230\160\183GID\229\175\185\229\186\148\231\154\132ThrowSession\239\188\140\228\184\141\229\133\129\232\174\184\232\191\153\230\160\183\229\129\154\239\188\140\232\191\148\229\155\158\231\169\186", Session.SeqID, "\231\138\182\230\128\129\230\152\175:", Session.Status)
    return nil
  end
  local local_player_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  local custom_priority = _G.PriorityEnum.Passive_3P_Throw_BP
  if local_player_id == owner_id then
    custom_priority = _G.PriorityEnum.Active_Player_Throw_BP
  end
  local ballNpcID, Klass, PreloadObj = self:GetBallClass(petData.ball_id)
  local ballNpc = self:CreateFakeNpc(ballNpcID, false, nil, owner_id, Klass, custom_priority)
  local session = ThrowSession.CreatePet(petData)
  session.Ball = ballNpc
  session:SetBallId(petData.ball_id)
  if ballNpc then
    ballNpc:SetThrowSession(session)
    if PreloadObj then
      ballNpc.classUrl = PreloadObj.Path
    end
    if UE4.UObject.IsValidLowLevel(ballNpc.viewObj) then
      ballNpc.viewObj:SetActorHiddenInGame(false)
    end
  end
  self.ThrowSessionManager:AssignThrowPetBallSession(session)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.ADD_THROW_SESSION_PET, session)
  return ballNpc
end

function NPCModule:CreateThrowStar(is_local, owner_id)
  Log.Debug("NPCModule:CreateThrowStar", is_local, owner_id)
  local NpcId = 60812
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local player_position = localPlayer.viewObj:Abs_K2_GetActorLocation()
  local class = NPCLuaUtils.GetClass("Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_NPCItemStar.BP_NPCItemStar_C'")
  local local_player_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  local custom_priority = _G.PriorityEnum.Passive_3P_Throw_BP
  if local_player_id == owner_id then
    custom_priority = _G.PriorityEnum.Active_Player_Throw_BP
  end
  local starNPC = self:CreateFakeNpc(NpcId, false, nil, owner_id, class, custom_priority)
  if nil == starNPC then
    Log.Error("Create Throw Star Failed, Get Nil")
    return nil
  end
  if not UE4.UObject.IsValidLowLevel(starNPC.viewObj) then
    Log.Error("Create Throw Star Failed!!! No Valid ViewObj")
    return starNPC
  end
  starNPC.viewObj:Abs_K2_SetActorLocation_WithoutHit(player_position)
  local session = ThrowStarSession.CreateStar()
  session.StarNPC = starNPC
  session.is_local = is_local
  self.ThrowSessionManager:AssignThrowStarSession(session, owner_id)
  starNPC:SetThrowSession(session)
  starNPC.viewObj:SetActorHiddenInGame(false)
  return starNPC
end

function NPCModule:CreateThrowLightBall(bIsLocal, OwnerID)
  local NpcId = 60816
  local LocalPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Position = LocalPlayer.viewObj:Abs_K2_GetActorLocation()
  local Klass = NPCLuaUtils.GetClass("Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_NPCMagicLightBall.BP_NPCMagicLightBall_C'")
  local FakeNpc = self:CreateFakeNpc(NpcId, false, nil, OwnerID, Klass)
  if not FakeNpc then
    return
  end
  if not UE4.UObject.IsValidLowLevel(FakeNpc.viewObj) then
    return FakeNpc
  end
  FakeNpc.viewObj:Abs_K2_SetActorLocation_WithoutHit(Position)
  local Session = ThrowLightBallSession.CreateLightBall()
  Session.LightBallNPC = FakeNpc
  FakeNpc.ThrowSession = Session
  FakeNpc.viewObj.ThrowSession = Session
  FakeNpc.viewObj:SetActorHiddenInGame(false)
  FakeNpc.is_local = bIsLocal
  self.ThrowSessionManager:AssignThrowLightBallSession(Session, OwnerID)
  return FakeNpc
end

function NPCModule:DeleteParticleNPC(ParticleNPC)
  if self.localParticles[ParticleNPC] then
    self.localParticles[ParticleNPC] = nil
  end
  ParticleNPC:Disappear(true)
end

function NPCModule:DeleteThrowBall(ball, keepSession)
  self.ThrowSessionManager:DeleteThrowBall(ball, keepSession)
end

function NPCModule:DeleteLocalNPC(npc)
  self:Log("DeleteLocalNPC", npc)
  if not npc then
    return
  end
  local actor_id = npc:GetServerId()
  local dict_npc = self._npcDic[actor_id]
  if dict_npc and dict_npc == npc then
    self:Log("\228\184\141\229\164\170\229\186\148\232\175\165\239\188\140\232\191\153\233\135\140\228\184\141\229\186\148\232\175\165\229\136\160\230\142\137\229\183\178\231\187\143\229\156\168NPC Dic\233\135\140\233\157\162\231\154\132\231\178\190\231\129\181\239\188\140\229\143\175\232\131\189\230\152\175\230\138\165\233\148\153\228\186\134\228\185\139\231\177\187\231\154\132\229\144\167\239\188\140\230\128\187\228\185\139\229\142\187NPC\230\168\161\229\157\151\233\135\140\233\157\162\228\185\159\232\191\155\232\161\140\228\184\128\230\172\161\229\136\160\233\153\164")
    npc:SetNotDestroyFlag(false)
    self:RemoveNpc(actor_id)
  end
  local Session = npc.ThrowSession
  if Session then
    Session:SetStatus(ThrowSessionStatusEnum.Destroyed)
    Session:SendEvent(ThrowSessionEvent.OnNpcRecycleFinished)
  end
  npc:Disappear(true)
  if npc.ThrowSession == nil then
    self:Log("DeleteLocalNPC npc.ThrowSession == nil", npc)
    return
  end
  self.ThrowSessionManager:DeleteThrowNPC(npc)
end

function NPCModule:DeleteThrowStar(star)
  if not star then
    return
  end
  local npc = star
  if not npc then
    return
  end
  if self.ThrowSessionManager:GetStar(star) then
    if npc.ThrowSession then
      npc.ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
    npc.viewObj:OnDisappear()
    npc:Disappear(true)
    self.ThrowSessionManager:ForgetStar(star)
  end
end

function NPCModule:DeleteThrowLightBall(Ball)
  if not Ball then
    return
  end
  local Npc = Ball
  if not Npc then
    return
  end
  if self.ThrowSessionManager:GetLightBall(Ball) then
    if Npc.ThrowSession then
      Npc.ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
    Npc:Disappear(true)
    self.ThrowSessionManager:ForgetStar(Ball)
  end
end

function NPCModule:GetThrowBagItemCount(BagItemGID)
  return self.ThrowSessionManager:GetThrowBagItemCount(BagItemGID)
end

function NPCModule:RecycleThrowPet(pet)
  self.ThrowSessionManager:RecycleThrowPet(pet)
end

function NPCModule:CacheLastThrowStarInfo(source, charge_level, charge_percent)
  local sceneAIManager = self.SceneAIManager
  sceneAIManager._cachedLastThrowStarSource = source
  sceneAIManager._cachedLastThrowStarChargeLevel = charge_level
  sceneAIManager._cachedLastThrowStarChargePercent = charge_percent
end

function NPCModule:OnUpdateBattleFieldPos(pos)
  self:OnAttractRunAway(pos, _G.NRCModuleManager:DoCmd(_G.BattleModuleCmd.GetBattleFieldRadius), 2, true)
end

function NPCModule:OnAttractRunAway(origin, radius, level, IsInBattle)
  if IsInBattle then
    self.SceneAIManager:SendSphereDotsEvent(origin, radius, _G.Enum.DotsAIWorldEventType.DAWET_RUNAWAY_BATTLE, level)
  else
    self.SceneAIManager:SendSphereDotsEvent(origin, radius, _G.Enum.DotsAIWorldEventType.DAWET_RUNAWAY, level)
  end
end

function NPCModule:SendSenseEvent(origin, type, radius, param, isSceneNpc)
  if isSceneNpc then
    self.SceneAIManager:SendDotsEvent(origin, radius, type, param, nil)
  else
    self.SceneAIManager:SendSphereDotsEvent(origin, radius, type, param)
  end
end

function NPCModule:ApplyRpBehavior(RpBehaviorId, RpStatus, player)
  local isLocalPlayer = not player or player.isLocal
  if isLocalPlayer and RpStatus == UE.EDotsStatusType.Finish then
    Log.Debug("amonsu==NPCModule==Add RolePlayBehaviorID====", RpBehaviorId)
    RolePlayBehaviorID = RpBehaviorId
    if self.RpBehaviorDelayHandle then
      _G.DelayManager:CancelDelayById(self.RpBehaviorDelayHandle)
      self.RpBehaviorDelayHandle = nil
    end
    self.RpBehaviorDelayHandle = _G.DelayManager:DelaySeconds(1, function()
      Log.Debug("amonsu==NPCModule==Remove RolePlayBehaviorID====", RpBehaviorId)
      RolePlayBehaviorID = 0
      self.RpBehaviorDelayHandle = nil
    end)
  end
  self.SceneAIManager:ApplyRolePlayBehavior(RpBehaviorId, RpStatus, player)
end

function NPCModule:OnPlayerTeleportPreStart()
  self:Log("OnPlayerTeleportPreStart")
  self.playerPreTeleporting = true
end

function NPCModule:OnPlayerTeleportStart()
  self:Log("OnPlayerTeleportStart")
  self.playerPreTeleporting = false
  self.playerTeleporting = true
  for _, v in pairs(self._npcIterDic) do
    v:OnPlayerTeleportStart()
    v:SetUpdateEnable(false)
    v:PauseMove()
  end
end

function NPCModule:PlayerTeleportLoad()
  Log.Debug("NPCModule:PlayerTeleportLoad")
end

function NPCModule:OnPlayerTeleportFinish()
  Log.Debug("NPCModule:OnPlayerTeleportFinish")
  for _, v in pairs(self._npcIterDic) do
    v:ResumeMove()
    v:SetUpdateEnable(true)
  end
  self.playerTeleporting = false
end

function NPCModule:OnEnterVisit()
  for _, v in pairs(self._npcIterDic) do
    v:OnEnterVisit()
  end
end

function NPCModule:OnLeaveVisit()
  for _, v in pairs(self._npcIterDic) do
    v:OnLeaveVisit()
  end
end

function NPCModule:OnHomeVisitChange()
  for _, v in pairs(self._npcIterDic) do
    v:OnHomeVisitChange()
  end
end

function NPCModule:RegisterTopKFinder(id, k, handler1, constValidFunc, handler2, adjustValidFunc, handler3, compareFunc, handler4, changeToValidFunc, handler5, changeToInValidFunc)
  self._npcFinders[id] = NPCBrutalFinder(k, handler1, constValidFunc, handler2, adjustValidFunc, handler3, compareFunc, handler4, changeToValidFunc, handler5, changeToInValidFunc)
end

function NPCModule:UnRegisterTopKFinder(id)
  self._npcFinders[id] = nil
end

local TopKNPCEmptyCache = {}

function NPCModule:GetTopKNPC(id)
  if self._npcFinders[id] then
    return self._npcFinders[id]:GetTopK()
  end
  table.clear(TopKNPCEmptyCache)
  return TopKNPCEmptyCache
end

function NPCModule:OnDestruct()
  Log.Debug("NPCModule:OnDestruct")
end

function NPCModule:OnActive()
  Log.Debug("NPCModule:OnActive")
  self.SceneAIManager:Init(self)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.PlayerTeleportPreStart, self.OnPlayerTeleportStart)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.PlayerTeleportFinish, self.OnPlayerTeleportFinish)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.LoadMapStart, self.LoadMapStart)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.LoadMapFinish, self.OnMapLoaded)
  NRCEventCenter:RegisterEvent("NPCModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  NRCEventCenter:RegisterEvent("NPCModule", self, NPCModuleEvent.TO_DISPERSE_AI, self.OnAttractRunAway)
  NRCEventCenter:RegisterEvent("NPCModule", self, BattleEvent.UPDATE_BATTLEFIELD_POS, self.OnUpdateBattleFieldPos)
  _G.NRCEventCenter:RegisterEvent("NPCModule", self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:RegisterEvent("NPCModule", self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SWITCH_SERVER_TO_CLIENT_AI_NTY, self.OnSwitchServerToClientAINty)
  FunctionBanManager:AddRawFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HIDE_IN_AREA_NPCS, self, self.ToggleHideNPCs)
  self.PreloadRes = {}
  self.PreloadRes[1] = NRCResourceManager:LoadResAsync(self, "/Game/ArtRes/Effects/G6Skill/SceneEffect/791247", -1, -1, self.OnPreloadDummy, self.OnPreloadDummy, self.OnPreloadDummy)
  self.PreloadRes[2] = NRCResourceManager:LoadResAsync(self, "/Game/ArtRes/Effects/G6Skill/SceneEffect/791246", -1, -1, self.OnPreloadDummy, self.OnPreloadDummy, self.OnPreloadDummy)
  self.MAX_TIME_FOR_LOADING_NPC = _G.DataConfigManager:GetGlobalConfig("MAX_TIME_FOR_LOADING_NPC").num
  self.MAX_NUM_OF_MOST_IMPORTANT_NPC = _G.DataConfigManager:GetGlobalConfig("MAX_NUM_OF_MOST_IMPORTANT_NPC").num
  if _G.WorldCombatModuleEvent ~= nil then
    NRCEventCenter:RegisterEvent("NPCModule", self, _G.WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
    NRCEventCenter:RegisterEvent("NPCModule", self, _G.WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.UI_SetThrowItem, self.OnThrowItemChange)
  DeviceUtils.EventDispatcher:AddEventListener(self, DeviceEvent.OnQualityChange, self.OnQualityChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_HOME_VISIT_INFO_CHANGED, self.OnHomeVisitChange)
  self:OnQualityChange()
end

function NPCModule:OnQualityChange(ImageQuality, FrameQuality, MemoryQuality)
  if _G.SystemSettingModuleCmd and _G.ZoneServer:CanSendNetworkCmd() then
    local newPlayerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    if newPlayerSettings then
      newPlayerSettings.quality = ImageQuality
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, newPlayerSettings)
    end
  end
  local group_level = UE4.UNRCQualityLibrary.GetGroupQualityLevel("UtilityGroup")
  local quality_config = _G.DataConfigManager:GetBasicQualityConfigConf("StarMagicQuality")
  local quality_list = quality_config.Qualities_IOS
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    quality_list = quality_config.Qualities_Android
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    quality_list = quality_config.Qualities_PC
  end
  if not quality_list or #quality_list < group_level + 1 then
    Log.Error("StarMagicQuality is invalid!!!", quality_list and #quality_list, group_level + 1)
    self.StarMagicQuality = 4
    return
  end
  local quality = quality_list[group_level + 1]
  if not quality then
    Log.Error("StarMagicQuality is invalid!!!", group_level, table.tostring(quality_list))
    self.StarMagicQuality = 4
    return
  end
  self.StarMagicQuality = tonumber(quality.QualityPriority)
  if not self.StarMagicQuality then
    Log.Error("StarMagicQuality is invalid!!!", group_level, table.tostring(quality_list), quality.QualityPriority)
    self.StarMagicQuality = 4
  end
end

function NPCModule:GetStarMagicQuality(is_local)
  if is_local then
    return math.clamp(self.StarMagicQuality, 0, 2)
  else
    return math.clamp(self.StarMagicQuality - 2, 0, 2)
  end
end

function NPCModule:OnDeactive()
  Log.Debug("NPCModule:OnDeactive")
  self.SceneAIManager:UnInit()
  if self.data then
    self.data:Clear()
  end
  self:ClearAll()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportPreStart, self.OnPlayerTeleportPreStart)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportFinish, self.OnPlayerTeleportFinish)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.LoadMapStart)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnMapLoaded)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.TO_DISPERSE_AI, self.OnAttractRunAway)
  NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.UPDATE_BATTLEFIELD_POS, self.OnUpdateBattleFieldPos)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SWITCH_SERVER_TO_CLIENT_AI_NTY, self.OnSwitchServerToClientAINty)
  FunctionBanManager:RemoveRawFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HIDE_IN_AREA_NPCS, self, self.ToggleHideNPCs)
  self.CloseRelease = nil
  self.FarRelease = nil
  NRCResourceManager:UnLoadRes(self.PreloadRes[1])
  NRCResourceManager:UnLoadRes(self.PreloadRes[2])
  table.clear(self.PreloadRes)
  if nil ~= _G.WorldCombatModuleEvent then
    NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
    NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem, self.OnThrowItemChange)
  DeviceUtils.EventDispatcher:RemoveEventListener(self, DeviceEvent.OnQualityChange, self.OnQualityChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_HOME_VISIT_INFO_CHANGED, self.OnHomeVisitChange)
end

function NPCModule:OnPreloadDummy()
end

function NPCModule:OnThrowItemChange(Type, PetData)
  if Type == MainUIModuleEnum.MainUIChooseType.MAGIC then
    return
  end
  if not PetData then
    return
  end
  local BallID = Type == MainUIModuleEnum.MainUIChooseType.ITEM and PetData.id or PetData.ball_id
  if not BallID or 0 == BallID then
    BallID = 100002
  end
  local Res = self.BallRes[BallID]
  if Res then
    return
  end
  local Conf = _G.DataConfigManager:GetBallConf(BallID)
  if not Conf then
    return
  end
  local ModelConf = _G.DataConfigManager:GetModelConf(Conf.fx_source)
  if not ModelConf then
    return
  end
  Res = ResObject.MakeUClass(ModelConf.path)
  self.BallRes[BallID] = Res
  Res:StartLoad(self, self.OnBallLoaded)
end

function NPCModule:OnBallLoaded()
  Log.Debug("On ball loaded")
end

function NPCModule:ClearAll(SameScene)
  if SameScene then
    self.ThrowSessionManager:ClearAll()
    return
  end
  self:Log("NPCModule:ClearAll")
  local k, npc = next(self._npcIterDic)
  while k do
    npc.notDestroyFlag = false
    self:OnNPCLeave(npc.serverData.base.actor_id, true)
    self._npcIterDic[k] = nil
    k, npc = next(self._npcIterDic)
  end
  table.clear(self._npcDic)
  table.clear(self._npcIterDic)
  table.clear(self._prepareMountDic)
  table.clear(self._npcContentDic)
  table.clear(self._npcLogicDic)
  self._npc2LoadQueue:Clear()
  self._npc2LoadQueue:SetCmpFunction(CmpNPCFrameLoadPriority)
  self.frame = 0
  self.MapLoaded = false
  self.MonitorNPCByConfID = {}
  self.MonitorNPCByServerID = {}
  self.HasEnterBattle = false
  self.ThrowSessionManager:ClearAll()
  self.npcActorPool:ClearAll()
  self.data:Clear()
  self.MapRegionAreaUtil:ClearMapRegion()
  if self.subHudPools then
    for _, _pool in pairs(self.subHudPools) do
      if _pool then
        _pool:Clear()
      end
    end
    self.subHudPools = {}
  end
end

function NPCModule:GetNearestNPC()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local ans
  local dist = math.huge
  local playerPos = player:GetActorLocationFrameCache()
  for _, npc in pairs(self._npcIterDic) do
    local d = UE4.FVector.DistSquared2D(npc:GetActorLocation(), playerPos)
    if dist > d then
      ans = npc
      dist = d
    end
  end
  return ans
end

function NPCModule:GetNPCByRefresh(refresh)
  for _, npc in pairs(self._npcIterDic) do
    if npc.serverData.npc_base.npc_content_cfg_id == refresh then
      return npc
    end
  end
  return nil
end

function NPCModule:GetNPCByViewObj(viewObj)
  if viewObj and UE4.UObject.IsValid(viewObj) then
    for _, npc in pairs(self._npcIterDic) do
      if npc.viewObj == viewObj then
        return npc
      end
    end
  end
  return nil
end

function NPCModule:OnChangeNpcAttr(action)
  local npc = self._npcDic[action.actor_id]
  if not npc then
  else
    if self:IsMonitor(action.actor_id, npc.config) then
      self:Log("##NPCMonitor")
      Log.Dump(action, 99, "NPCModule:OnChangeNpcAttr")
    end
    local NotifyToAi = false
    for _, attr in pairs(action.attrs) do
      if attr.attr_type == ProtoEnum.AttrType.ENUM.Lv then
        npc:UpdateLevel(attr.attr_val)
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.MoveSpd then
        self:Log("OnChangeNpcAttr MoveSpd:", tostring(attr.attr_val))
        npc:SetSpeed(attr.attr_val)
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.Hp then
        npc:UpdateHp(attr.attr_val)
        NotifyToAi = true
      elseif attr.attr_type == ProtoEnum.AttrType.ENUM.HpMax then
        npc:UpdateHpMax(attr.attr_val)
        NotifyToAi = true
      end
    end
    if NotifyToAi and npc.AIComponent then
      npc.AIComponent:OnHpUpdated(npc.serverData.attrs.hp, npc.serverData.attrs.hp_max)
    end
  end
end

function NPCModule:OnBeginDropItem(action, Tag, BaseData)
  local src_npc = self._npcDic[action.src_npc_id]
  local operator_player_id = BaseData.operator_obj_id
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  local player_uin = SceneModule and SceneModule:GetPlayerUin(operator_player_id) or 0
  local local_player_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if local_player_id ~= operator_player_id and not _G.DataModelMgr.PlayerDataModel:IsVisitor(player_uin) then
    Log.Debug("NPCModule:OnBeginDropItem[NpcAOI] \228\184\162\230\142\137\228\186\146\232\167\129\229\140\186\229\133\182\228\187\150\233\157\158\228\186\146\232\174\191\231\142\169\229\174\182\231\154\132BeginDrop\239\188\140\232\191\153\228\186\155\228\186\186\231\154\132BeginDrop\229\144\142\231\187\173\230\152\175\230\178\161\230\156\137NPCEnter\231\154\132", operator_player_id)
    return
  end
  if action.drop_item_refresh_source == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Battle then
    self:Log("\230\136\152\230\150\151\230\142\137\232\144\189", action.drop_itme_num)
    self.battleNPCGenerator = BattleNPCGenerator()
    if action.src_npc_pos then
      self.battleNPCGenerator:SetPos(UE4.FVector(action.src_npc_pos.x, action.src_npc_pos.y, action.src_npc_pos.z))
    else
      local pos = BattleExitHelper.CalcDeadPosition()
      pos = SceneUtils.GetPosInLand(pos, 60)
      self.battleNPCGenerator:SetPos(pos)
    end
    self.battleNPCGenerator:SetCreateNPCTotalNum(action.drop_itme_num)
  elseif action.drop_item_refresh_source == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ThrowBagItem then
    self.ThrowSessionManager:ThrowBagItemBeginDrop(action)
  elseif src_npc then
    src_npc:SetNotDestroyFlag(true)
    if src_npc.luaObj.SetCreateNPCTotalNum then
      if BaseData then
        src_npc.luaObj:SetCreateNPCTotalNum(action.drop_itme_num, BaseData.operator_obj_id)
      else
        src_npc.luaObj:SetCreateNPCTotalNum(action.drop_itme_num, -1)
      end
    end
  elseif SceneUtils.GetActorType(action.src_npc_id) == ProtoEnum.SpaceEnum_SpaceObjSubType.ENUM.Actor_Avatar then
  else
    Log.Error("\230\148\182\229\136\176SpaceAct_BeginDropItem\229\141\143\232\174\174\230\151\182\230\186\144npc\228\184\141\229\173\152\229\156\168, src_npc_id:", string.format("%u", action.src_npc_id or 0), action.src_npc_id)
  end
end

function NPCModule:OnEndDropItem(action)
end

function NPCModule:InternalAddNPC(npcInfo, npc)
  if self._npcDic[npcInfo.base.actor_id] then
    Log.Error("NPC duplicated...!!!", npcInfo.base.actor_id)
  end
  self._npcDic[npcInfo.base.actor_id] = npc
  if self._hashIDQueue:Size() > 0 then
    local id = self._hashIDQueue:Dequeue()
    npc.hashId = id
    self._npcIterDic[id] = npc
  else
    local id = self._coeNpcNum
    npc.hashId = id
    self._npcIterDic[id] = npc
    self._coeNpcNum = self._coeNpcNum + 1
  end
  local RefreshPointID = npcInfo.npc_base.refresh_point
  if RefreshPointID and RefreshPointID > 0 then
    self._npcContentDic[RefreshPointID] = npc
  end
  local LogicID = npcInfo.base.logic_id
  if LogicID and LogicID > 0 then
    self._npcLogicDic[LogicID] = npc
  end
end

local Yellow, Red, Green

function NPCModule:CreateNpc(npcInfo, bNeedPosAdjust)
  if not npcInfo then
    return
  end
  Log.Debug("NPCModule:CreateNpc ", npcInfo.npc_base.npc_cfg_id)
  local configID = _G.DataConfigManager:GetNpcConf(npcInfo.npc_base.npc_cfg_id)
  if not configID then
    Log.Error("NPC\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\154", npcInfo.npc_base.npc_cfg_id)
    Log.Dump(npcInfo)
    return
  end
  if SceneUtils.debugCoordFix then
    if not Yellow then
      Yellow = UE.FLinearColor(1, 1, 0, 1)
    end
    local World = UE4Helper.GetCurrentWorld()
    local Point = npcInfo.base.born_pt
    local Pos = Point.pos
    local Vec = UE.FVector(Pos.x, Pos.y, Pos.z)
    Vec = SceneUtils.ConvertAbsoluteToRelative(Vec)
    UE.UKismetSystemLibrary.DrawDebugSphere(World, Vec, 30, 8, Yellow, 999, 2)
    local Name = configID.name
    if string.IsNilOrEmpty(Name) then
      Name = "no name"
    end
    UE.UKismetSystemLibrary.DrawDebugString(World, Vec, Name, nil, Green, 999)
    local ContentConf = _G.DataConfigManager:GetNpcRefreshContentConf(npcInfo.npc_base.npc_content_cfg_id)
    if ContentConf and ContentConf.refresh_type == Enum.RefreshType.RFT_AREA then
      local Area = _G.DataConfigManager:GetAreaConf(ContentConf.refresh_param)
      if Area and Area.area_type == Enum.AreaType.AREAT_POINT then
        if not Red then
          Red = UE.FLinearColor(1, 0, 0, 1)
        end
        if not Green then
          Green = UE.FLinearColor(0, 1, 0, 1)
        end
        Pos = Area.pos[1].position_xyz
        Vec.X = Pos[1]
        Vec.Y = Pos[2]
        Vec.Z = Pos[3]
        Vec = SceneUtils.ConvertAbsoluteToRelative(Vec)
        UE.UKismetSystemLibrary.DrawDebugSphere(World, Vec, 40, 8, Red, 999, 2)
      end
    end
  end
  local npc = SceneNpc(self)
  npc.bNeedPosAdjust = bNeedPosAdjust
  npc:InitWithNpcInfo(npcInfo)
  self:InternalAddNPC(npcInfo, npc)
  npc:CreateLuaObj()
  npc:CalculateServerDistance()
  local bIsReliedNpc = false
  local bIsPlacedNpc = false
  local contentCfg = _G.DataConfigManager:GetNpcRefreshContentConf(npcInfo.npc_base.npc_content_cfg_id, true)
  if contentCfg then
    bIsReliedNpc = contentCfg.refresh_type == Enum.RefreshType.RFT_RELY
    bIsPlacedNpc = contentCfg.refresh_type == Enum.RefreshType.RFT_BYTAGID or contentCfg.refresh_type == Enum.RefreshType.RFT_BYTAG
    if bIsPlacedNpc then
      npc.PlaceableId = npcInfo.npc_base.refresh_point
    end
  end
  if SceneUtils.debugBlockCreateAndLoad then
    npc:CreateView(false)
    if npc.viewObj and npc.viewObj.OnFrameLoad and not bIsPlacedNpc then
      npc.viewObj:OnFrameLoad(0)
    end
  end
  if npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ThrowPet or npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ThrowBagItem then
    self._npc2LoadQueue:EnQueue(npc)
    self:CheckShouldHide(npc)
    return npc
  end
  local battleReward = npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Battle
  local bOptionCreateNPC = npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.NpcInteract_OptionCreateNpc
  if bOptionCreateNPC or (not npcInfo.npc_base.src_npc_id or 0 == npcInfo.npc_base.src_npc_id or not bNeedPosAdjust) and not battleReward then
    npc.bCreateFromSrcNpc = false
    self._npc2LoadQueue:EnQueue(npc)
  else
    npc.bCreateFromSrcNpc = true
    local npc_id = npcInfo.base.actor_id
    local src_npc_id = npcInfo.npc_base.src_npc_id
    local src_npc = self._npcDic[src_npc_id]
    if src_npc or battleReward then
      local generatorNpc
      if battleReward then
        if not _G.BattleManager.isInBattle then
          if npc.config.reward_drop_type == Enum.RewardNpcType.RNT_DROP then
            if not self.battleNPCGenerator then
              self.battleNPCGenerator = BattleNPCGenerator()
              Log.Error("\233\157\158\233\152\187\230\150\173\239\188\154\228\184\141\229\186\148\232\175\165\229\135\186\231\142\176\231\154\132\233\148\153\232\175\175\239\188\140\232\139\165\230\156\137\229\135\186\231\142\176\233\186\187\231\131\166\230\136\170\229\155\190\229\143\145\231\187\153\229\188\128\229\143\145\229\164\141\230\159\165 npc id", string.format("%u %d", npc_id, npc_id), "npc_content_cfg_id", npcInfo.npc_base.npc_content_cfg_id, npcInfo.npc_base.refresh_src, npcInfo.npc_base.pos_need_adjust, npcInfo.base.enter_scene_times, string.format("%u %d", src_npc_id or 0, src_npc_id or 0), npcInfo.base.pt.pos.z)
            end
            self.battleNPCGenerator:SetCreateNPC(npc)
          else
            if not self.battleNPCGenerator.createNum then
              Log.Warning("\230\156\137src npc id\239\188\140\228\189\134\230\186\144npc\228\186\139\229\137\141\230\178\161\230\156\137\230\148\182\229\136\176\233\128\154\231\159\165")
            end
            self.battleNPCGenerator:ReSetCreateNPCTotalNum(self.battleNPCGenerator.createNum - 1)
            npc.luaObj.createFromReward = true
            self._npc2LoadQueue:EnQueue(npc)
          end
        else
          Log.Debug("\231\188\147\229\173\152\229\136\155\229\187\186", npc:DebugNPCNameAndID())
          table.insert(self.cachedBattleNpcGenerate, npc)
        end
      else
        if src_npc then
          generatorNpc = src_npc.luaObj
          src_npc:SetNotDestroyFlag(true)
        end
        if generatorNpc then
          if npc.config.reward_drop_type == Enum.RewardNpcType.RNT_DROP or bIsReliedNpc then
            if generatorNpc.SetCreateNPC then
              if generatorNpc:SetCreateNPC(npc) then
                self._npc2LoadQueue:EnQueue(npc)
              end
            else
              self:LogWarning("\230\186\144npc\230\178\161\230\156\137SetCreateNPC\230\150\185\230\179\149")
            end
          else
            Log.Debug("RNT_CREATE", npc:DebugNPCNameAndID())
            if not generatorNpc.createNum then
              Log.Warning("\230\156\137src npc id\239\188\140\228\189\134\230\186\144npc\228\186\139\229\137\141\230\178\161\230\156\137\230\148\182\229\136\176\233\128\154\231\159\165")
            end
            generatorNpc:ReSetCreateNPCTotalNum((generatorNpc.createNum or 1) - 1)
            npc.bNeedPosAdjust = false
            npc.serverPos = src_npc:GetNearLocation()
            npc.luaObj.createFromReward = true
            self._npc2LoadQueue:EnQueue(npc)
          end
        else
          self:LogWarning("generatorNpc\228\184\141\229\173\152\229\156\168\239\188\140\231\148\177\231\137\185\230\174\138\230\151\182\233\151\180\231\130\185\230\150\173\231\186\191\233\135\141\232\191\158\229\188\149\232\181\183\239\188\140\232\175\165\233\151\174\233\162\152\230\182\137\229\143\138\232\175\184\229\164\154\230\150\185\233\157\162\239\188\136\230\136\152\230\150\151\231\138\182\230\128\129\227\128\129\230\156\141\229\138\161\229\153\168\231\137\169\231\144\134\227\128\129\229\138\168\231\148\187\230\149\176\230\141\174\231\173\137\239\188\137\239\188\140\229\190\133\229\144\142\231\187\173\232\167\132\229\136\146")
        end
      end
    else
    end
  end
  local selfId = npcInfo.base.actor_id
  if self._prepareMountDic[selfId] then
    for _, childInfo in pairs(self._prepareMountDic[selfId]) do
      self:CreateNpc(childInfo, true)
    end
    self._prepareMountDic[selfId] = nil
  end
  self:CheckShouldHide(npc)
  npc:SendEvent(NPCModuleEvent.On_NPC_Create, npc)
  NRCEventCenter:DispatchEvent(NPCModuleEvent.On_NPC_Create, npc)
  return npc
end

function NPCModule:CreateFakeNpc(configID, blockLoad, serverData, ownerId, class, priority)
  Log.Debug("NPCModule:CreateFakeNpc")
  if not configID then
    Log.Error("NPCModule:CreateFakeNpc \233\133\141\231\189\174\228\184\141\229\173\152\229\156\168")
    return
  end
  local npc = SceneNpc(self)
  if serverData then
    npc.serverData = serverData
  end
  npc.owner_id = ownerId
  npc.config = _G.DataConfigManager:GetNpcConf(configID)
  npc.modelConf = _G.DataConfigManager:GetModelConf(npc.config.model_conf)
  npc:CreateLuaObj()
  if class then
    local viewObj = self.npcActorPool:CreateActorByClass(class)
    if not viewObj then
      Log.Error("\228\188\160\232\191\155\230\157\165\231\154\132class\233\157\158\230\179\149\228\186\134\239\188\159\232\191\153\228\184\141\229\175\185\229\144\167", configID, class, UE.UObject.IsValid(class) and class:GetFullName())
      return npc
    end
    if viewObj.SetLoadPriority then
      viewObj:SetLoadPriority(priority or -1)
    end
    if viewObj.ReleaseVisibleLevel then
      viewObj:ReleaseVisibleLevel()
    end
    if viewObj then
      Log.Debug("NPCModule CreateFakeNpc With class", configID)
      npc:OnViewObjGetFromPool(viewObj)
      viewObj.IsFakeNpc = true
      npc:InitOwner()
    else
      Log.Trace("NPCModule CreateFakeNpc With class Failed", class, configID)
      npc:CreateView(blockLoad or false, priority)
    end
  else
    Log.Debug("NPCModule CreateFakeNpc With no class", configID)
    npc:CreateView(blockLoad or false, priority)
  end
  if UE4.UObject.IsValidLowLevel(npc.viewObj) then
    Log.Debug("NPCModule:CreateFakeNpc Done", configID)
    if blockLoad then
      npc.viewObj.forbidFixCoord = true
      npc.viewObj:InitOutScene()
    else
      npc.viewObj:LoadOutSceneAsync()
    end
  elseif class then
    Log.Error("NPCModule:CreateFakeNpc \229\136\155\229\187\186viewobj\229\164\177\232\180\165")
  else
    Log.Debug("NPCModule:CreateFakeNpc with viewObj Load Later", configID)
  end
  return npc
end

function NPCModule:CreateLocalPet(Session, Priority)
  local PetData = Session.petData
  local ActorInfo = ProtoMessage:newActorInfo_Npc()
  ActorInfo.base.actor_id = self:AcquireFakeID()
  ActorInfo.base.lv = 0
  ActorInfo.pet_info.gid = Session:GetGID()
  Priority = Priority or 1
  if PetData then
    ActorInfo.npc_base.height = PetData.height
    ActorInfo.npc_base.weight = PetData.weight
    ActorInfo.npc_base.nature = PetData.nature
    ActorInfo.npc_base.mutation_type = PetData.mutation_type
    ActorInfo.npc_base.glass_info = PetData.glass_info
  end
  local pet = self:CreateFakeNpc(Session:GetNpcID(60012), false, ActorInfo, Priority)
  pet:SetThrowSession(Session)
  Session:SetNPC(pet)
  pet:EnsureComponent(PetStatusComponent)
  pet:EnsureComponent(LocalPetComponent)
  pet:EnsureComponent(AIComponent)
  pet.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.INTERACT)
  self.ThrowSessionManager:AssignLocalPet(Session)
  return pet
end

function NPCModule:DeleteLocalPetInHome(homePet)
  if not homePet then
    return
  end
  local actor_id = homePet:GetServerId()
  if self._npcDic[actor_id] then
    homePet:SetNotDestroyFlag(false)
    self:RemoveNpc(actor_id)
  end
  homePet:Disappear(true)
end

function NPCModule:CreateLocalPetInHome(npc_id, petLocation, direction, petData)
  if not npc_id or not petData then
    return nil
  end
  local actorInfo = ProtoMessage:newActorInfo_Npc()
  actorInfo.base.actor_id = self:AcquireFakeID()
  if petLocation then
    actorInfo.base.pt.pos = petLocation
  else
    actorInfo.base.pt.pos.x = 0
    actorInfo.base.pt.pos.y = 0
    actorInfo.base.pt.pos.z = 0
  end
  if direction then
    actorInfo.base.pt.dir.z = direction
  else
    actorInfo.base.pt.dir.z = 0
    actorInfo.base.pt.dir.x = 0
    actorInfo.base.pt.dir.y = 0
  end
  if petData then
    actorInfo.npc_base.height = petData.height
    actorInfo.npc_base.weight = petData.weight
    actorInfo.npc_base.nature = petData.nature
    actorInfo.npc_base.mutation_type = petData.mutation_type
    actorInfo.npc_base.glass_info = petData.glass_info
    actorInfo.base.lv = petData.level
    actorInfo.base.name = petData.name
    actorInfo.base.gender = petData.gender
    actorInfo.pet_info.gid = petData.gid
  end
  local homeNpc = SceneNpc(self, petData.gid, actorInfo)
  homeNpc:InitData(_G.DataConfigManager:GetNpcConf(npc_id), actorInfo)
  self:InternalAddNPC(actorInfo, homeNpc)
  homeNpc:CreateLuaObj()
  self._npc2LoadQueue:EnQueue(homeNpc)
  return homeNpc
end

function NPCModule:SyncPetCreate(npc, born_reason)
  if npc.ThrowSession then
    npc.ThrowSession:SyncPetCreate(npc, born_reason)
  end
end

function NPCModule:CreateFollowingNpc(npcInfo, model_id, specificTree)
  specificTree = specificTree or "/Game/NewRoco/Modules/AI/BehaviorTree/MFBT/Partner/BT_Partner1"
  if not npcInfo then
    return
  end
  if self.followingNpc then
    self.followingNpc:Destroy()
  end
  local npc = SceneNpc(self)
  local configID = _G.DataConfigManager:GetNpcConf(10012)
  configID.model_conf = model_id
  configID.show_level = 0
  configID.mf_behavior_tree = specificTree
  npc:InitData(configID, npcInfo)
  self:InternalAddNPC(npcInfo, npc)
  npc:CreateLuaObj()
  npc:CreateView(false)
  self._npc2LoadQueue:EnQueue(npc)
  self.followingNpc = npc
  return npc
end

local ClientNPCMask = SceneUtils.ClientNPCMask

function NPCModule:AcquireFakeID()
  local FakeID = ProtoEnum.SpaceEnum_SpaceObjSubType.ENUM.Actor_Npc << 60
  self.LocalNPCCounter = self.LocalNPCCounter + 1
  FakeID = FakeID | ClientNPCMask | self.LocalNPCCounter
  return FakeID
end

function NPCModule:ConvertFeed(FeedID, FeedType)
  local NewID = ProtoEnum.SpaceEnum_SpaceObjSubType.ENUM.Actor_Npc << 60
  local UIN = (FeedID & 1152921504338411520) >> 2
  local Type = FeedType << 22
  return NewID | UIN | ClientNPCMask | Type | FeedID & 4194303
end

function NPCModule:CreateLocalNPC(NPCConfID, Position, Dir, PetGID, Priority)
  self:Log("CreateLocalNPC", NPCConfID)
  local Conf = _G.DataConfigManager:GetNpcConf(NPCConfID)
  local ActorInfo = _G.ProtoMessage:newActorInfo_Npc()
  ActorInfo.base.actor_id = self:AcquireFakeID()
  ActorInfo.base.logic_id = ActorInfo.base.actor_id
  ActorInfo.base.lv = 0
  if Position then
    ActorInfo.base.pt.pos = Position
  else
    ActorInfo.base.pt.pos.x = 0
    ActorInfo.base.pt.pos.y = 0
    ActorInfo.base.pt.pos.z = 0
  end
  if Dir then
    ActorInfo.base.pt.dir.z = Dir
  else
    ActorInfo.base.pt.dir.z = 0
    ActorInfo.base.pt.dir.x = 0
    ActorInfo.base.pt.dir.y = 0
  end
  if PetGID then
    ActorInfo.pet_info.gid = PetGID
  end
  local npc = SceneNpc(self)
  npc.custom_priority = Priority
  npc:InitData(Conf, ActorInfo)
  self:InternalAddNPC(ActorInfo, npc)
  npc:CreateLuaObj()
  self._npc2LoadQueue:EnQueue(npc)
  return npc
end

function NPCModule:CreateLocalNPCWithActorInfo(ActorInfo, Priority)
  local Conf = _G.DataConfigManager:GetNpcConf(ActorInfo.npc_base.npc_cfg_id)
  local npc = SceneNpc(self)
  npc.custom_priority = Priority
  npc:InitData(Conf, ActorInfo)
  self:InternalAddNPC(ActorInfo, npc)
  npc:CreateLuaObj()
  self._npc2LoadQueue:EnQueue(npc)
  return npc
end

function NPCModule:OnLogin(isRelogin)
  self:Log("NPCModule:OnLogin", isRelogin)
  self.EQSManager:ReleaseAll()
  if isRelogin then
    self.data:Clear()
  end
end

function NPCModule:ClearActorInReconnect(InitialActors)
  self:Log("NPCModule:ClearActorInReconnect[NpcAOI] \230\150\173\231\186\191\233\135\141\232\191\158\230\151\182\230\184\133\231\144\134actor")
  local initActorsLookup = {}
  if InitialActors then
    for _, Actor in ipairs(InitialActors) do
      if Actor.actor_detail_type ~= ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal then
        local serverId = Actor.npc.base.actor_id
        if serverId and 0 ~= serverId then
          initActorsLookup[serverId] = true
        end
      end
    end
  end
  local needToRemove = {}
  for _, npc in pairs(self._npcIterDic) do
    local serverId = npc.serverData.base.actor_id
    if not initActorsLookup[serverId] and not npc.serverData.MagicFeedInfo then
      table.insert(needToRemove, serverId)
    else
      self:Log("[NpcAOI]Reconnect, keep npc actor", serverId, npc.serverData.base.name)
    end
    npc.notDestroyFlag = false
  end
  for _, serverId in pairs(needToRemove) do
    self:OnNPCLeave(serverId, true)
  end
  NpcOption:SetNeedStatusNotify(false)
end

function NPCModule:OnEnterSceneFinishNtyAck(ackNotify, isReconnecting, isEnteringCell)
  self.StartTimeOfEnterSceneFinishNtyAck = os.msTime()
end

function NPCModule:CheckInitialNPCsReady()
  if not self.InitialActorIDs or table.isEmpty(self.InitialActorIDs) then
    return true
  end
  local elapsedTime = 0
  local curOnlineState = _G.ZoneServer:GetOnlineState()
  if curOnlineState == OnlineState.EnteredCell and self.StartTimeOfEnterSceneFinishNtyAck and self.StartTimeOfEnterSceneFinishNtyAck > 0 then
    local curTime = os.msTime()
    elapsedTime = curTime - self.StartTimeOfEnterSceneFinishNtyAck
    if elapsedTime > self.MAX_TIME_FOR_LOADING_NPC then
      Log.Debug("[NpcAOI]CheckInitialNPCsReady is TimeOut, elapsed time = ", elapsedTime)
      table.clear(self.InitialActorIDs)
      return true
    end
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    Log.Error("[NpcAOI]CheckInitialNPCsReady Player is nil")
    return false
  end
  local PlayerPos = Player:GetActorLocation()
  if not PlayerPos then
    return false
  end
  for idx, ID in ipairs(self.InitialActorIDs) do
    if 0 == self.InitialActorIDs[idx] then
    else
      local NPC = self._npcDic[ID]
      if not NPC then
      else
        local ServerData = NPC.serverData
        if not ServerData then
        else
          local View = NPC.viewObj
          if not View or not UE4.UObject.IsValid(View) then
            Log.Debug("[NpcAOI]NPC view is not ready...", NPC:DebugNPCNameAndID())
            if NPC.PlaceableId then
              local NpcView = self._placeSpawnedDic[NPC.PlaceableId]
              if NpcView then
                if UE.UObject.IsValid(NpcView) then
                  Log.Warning("[PlaceableNpc] bind miss! try force bind", NPC.PlaceableId, NPC:DebugNPCNameAndID())
                  self._placeEnteredDic[NPC.PlaceableId] = NPC
                  NPCLuaUtils.BindNpcViewObj(NPC, NpcView)
                else
                  Log.Warning("[PlaceableNpc] delete miss! try force delete", NPC.PlaceableId, NPC:DebugNPCNameAndID())
                  self._placeSpawnedDic[NPC.PlaceableId] = nil
                end
              else
                Log.Debug("[NpcAOI]NPC view is not ready, but it is Placeable.", NPC:DebugNPCNameAndID())
                goto lbl_185
              end
            end
            return false
          else
            Log.Debug("[NpcAOI]NPC view ready!!!", NPC:DebugNPCNameAndID())
            self.InitialActorIDs[idx] = 0
          end
          if not View.GetCurrentVisibleLevel or View:GetCurrentVisibleLevel() ~= UE.ENPCVisibleLevel.VISIBLE then
          elseif View.resourceLoading and not View.resourceLoaded then
            Log.Debug("[NpcAOI]NPC resource loading...", NPC:DebugNPCNameAndID())
            return false
          end
        end
      end
    end
    ::lbl_185::
  end
  Log.Debug("[NpcAOI]CheckInitialNPCsReady OK, elapsed time = ", elapsedTime)
  return true
end

function NPCModule:ClearInitialNPCsList()
  table.clear(self.InitialActorIDs)
end

function NPCModule:OnNPCEnterFinish()
  Log.Debug("NPCModule:OnNPCEnterFinish")
  if not self._prepareMountDic then
    return
  end
  local createNum = 0
  for srcId, srcCreateTable in pairs(self._prepareMountDic) do
    if srcCreateTable then
      for _, childInfo in pairs(srcCreateTable) do
        local serverId = childInfo.base.actor_id
        createNum = createNum + 1
        Log.Debug("Create", string.format("%u %d", serverId, serverId), " src", srcId)
        self:CreateNpc(childInfo, false)
      end
      self._prepareMountDic[srcId] = nil
    end
  end
  Log.Debug("Create Finish, num ", createNum)
  self._prepareMountDic = {}
end

function NPCModule:OnPlaceableNpcEnter(placeableId, viewObj)
  Log.Debug("[PlaceableNpc] OnNpcEnter", placeableId, viewObj)
  if not self._placeSpawnedDic[placeableId] then
    self._placeSpawnedDic[placeableId] = viewObj
  else
    if _G.RocoEnv.IS_EDITOR then
      Log.ErrorFormat("[PlaceableNpc] \229\156\186\230\153\175\231\137\169\228\187\182\231\154\132\229\148\175\228\184\128ID\229\143\145\231\148\159\231\162\176\230\146\158\239\188\140\232\175\183\230\163\128SCENE_OBJECT_CONF\230\159\165\229\175\188\229\135\186\231\187\147\230\158\156 id=%d name_1=%s name_2=%s", placeableId, viewObj:GetFullName(), self._placeSpawnedDic[placeableId]:GetFullName())
    else
      Log.Error("[PlaceableNpc] \229\156\186\230\153\175\231\137\169\228\187\182\231\154\132\229\148\175\228\184\128ID\229\143\145\231\148\159\231\162\176\230\146\158\239\188\140\232\175\183\230\163\128SCENE_OBJECT_CONF\230\159\165\229\175\188\229\135\186\231\187\147\230\158\156 id=", placeableId, "name=", viewObj:GetFullName())
    end
    return
  end
  local npc = self._placeEnteredDic[placeableId]
  if npc then
    Log.Debug("[PlaceableNpc] OnNpcEnter \229\140\185\233\133\141\230\136\144\229\138\159", placeableId, npc:DebugNPCNameAndID())
    NPCLuaUtils.BindNpcViewObj(npc, viewObj)
  end
end

function NPCModule:OnPlaceableNpcLeave(placeableId)
  local view = self._placeSpawnedDic[placeableId]
  self._placeSpawnedDic[placeableId] = nil
  if view then
    if view.sceneCharacter then
      local npc = view.sceneCharacter
      Log.Debug("[PlaceableNpc] \229\183\178\232\167\163\231\187\145\239\188\154", npc:DebugNPCNameAndID(), placeableId)
      npc.viewObj = nil
      npc.viewObjRef = nil
    end
    view:OnUnLoadResource()
    view:SetSceneCharacter(nil)
  end
end

function NPCModule:OnNPCEnter(actor, Tag, BaseData, bConnect)
  local NPCInfo = actor and actor.npc
  if not NPCInfo then
    Log.Error("\230\156\141\229\138\161\229\153\168\228\184\139\229\143\145\231\154\132NPC\228\184\173\230\178\161\230\156\137npc info")
    return
  end
  local ActorBaseInfo = NPCInfo and NPCInfo.base
  if not ActorBaseInfo then
    Log.Error("\230\156\141\229\138\161\229\153\168\228\184\139\229\143\145\231\154\132NPC\228\184\173\230\178\161\230\156\137npc.base")
    return
  end
  local NPCBaseInfo = NPCInfo and NPCInfo.npc_base
  if not NPCBaseInfo then
    Log.Error("\230\156\141\229\138\161\229\153\168\228\184\139\229\143\145\231\154\132NPC\228\184\173\230\178\161\230\156\137npc.npc_base")
    return
  end
  local NPCConf = _G.DataConfigManager:GetNpcConf(NPCBaseInfo.npc_cfg_id)
  if NPCConf and ActorBaseInfo then
    local NameInBase = ActorBaseInfo.name
    if string.IsNilOrEmpty(NameInBase) then
      ActorBaseInfo.name = NPCConf.name
    end
  end
  self:Log("[NpcAOI]OnNPCEnter", ActorBaseInfo.actor_id, NPCBaseInfo.npc_cfg_id, NPCBaseInfo.npc_content_cfg_id, ActorBaseInfo.name, actor.actor_detail_type, NPCBaseInfo.pos_need_adjust or false, NPCBaseInfo.src_npc_id or 0, SceneUtils.DebugPositionToString(NPCBaseInfo.src_npc_pos) or "", SceneUtils.DebugPositionToString(ActorBaseInfo.pt.pos) or "")
  if SceneUtils.debugCloseCreateNPC then
    return
  end
  SceneUtils.FixActorPoint(actor)
  local serverId = ActorBaseInfo.actor_id
  local npc = self._npcDic[serverId]
  if not npc then
    for _, n in pairs(self._npcIterDic) do
      if n.serverData.base.actor_id == serverId then
        npc = n
        break
      end
    end
  end
  if npc then
    self:Log("[NpcAOI] OnNpcEnter:UpdateData for npc", npc.serverData.base.actor_id, npc.serverData.base.name)
    npc.shouldDestroy = false
    npc:UpdateData(NPCInfo, true)
    npc.luaObj:UpdateData(NPCInfo, true)
    return
  end
  if NPCBaseInfo.src_npc_id then
    self:Log("src npc", string.format("%u %d", NPCBaseInfo.src_npc_id, NPCBaseInfo.src_npc_id))
  end
  self:RecordOperations()
  self:PreInfoAndCreate(NPCInfo)
  if BaseData and BaseData.simulate then
    npc = self._npcDic[serverId]
    if npc then
      npc.simulate = true
    end
    self:Log("\230\156\172\229\156\176\230\168\161\230\139\159NPC\232\191\155\229\133\165\229\156\186\230\153\175", string.format("actor_id = %d", serverId))
  end
  if self.MapLoaded then
  else
    Log.Error("\229\156\176\229\155\190\232\191\152\230\178\161\229\138\160\232\189\189\229\174\140\230\136\144")
  end
  self:TryAddPlayerPet(NPCInfo)
end

function NPCModule:PreInfoAndCreate(npcInfo)
  local src_npc_id = npcInfo.npc_base.src_npc_id
  local ActorType = npcInfo.base.detail_type
  if ActorType == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet then
    local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if npcInfo.base.owner_id == LocalPlayer.serverData.base.actor_id then
      self:OnServerCreatePet(npcInfo)
      return
    end
  end
  local AttachInfo = npcInfo.attach_item_info
  if AttachInfo and (AttachInfo.attach_item_type == _G.Enum.NpcAttachItemType.NAIT_HOME_SEAT or AttachInfo.attach_item_type == _G.Enum.NpcAttachItemType.NAIT_HOME_PET_NEST and not npcInfo.home_pet) and ActorType ~= ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_HomePetEgg then
    self:CreateVirtualHomeNPC(npcInfo)
    return
  end
  if src_npc_id and 0 ~= src_npc_id then
    local SrcActorType = SceneUtils.GetActorDetailType(src_npc_id)
    if SrcActorType == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal and (npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ThrowPet or npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ThrowBagItem) then
      self:OnServerCreateBall(npcInfo)
      return
    end
    local enterSceneTimes = npcInfo.base.enter_scene_times
    if NPCLuaUtils.HasValidPoint(npcInfo) then
      Log.Debug("\228\191\161\228\187\187\230\156\141\229\138\161\229\153\168\229\157\144\230\160\135 ", "npc_id", string.format("%u %d", npcInfo.base.actor_id, npcInfo.base.actor_id), "src_npc_id", string.format("%u %d", src_npc_id, src_npc_id))
      if 1 ~= enterSceneTimes then
        npcInfo.npc_base.refresh_src = ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Normal
      end
      self:CreateNpc(npcInfo)
    else
      local pos = npcInfo.base.pt.pos
      Log.Debug("\229\157\144\230\160\135\231\137\185\230\174\138\229\128\188 ", "npc_id", string.format("%u %d", npcInfo.base.actor_id, npcInfo.base.actor_id), "src_npc_id", string.format("%u %d", src_npc_id, src_npc_id), SrcActorType, table.getKeyName(ProtoEnum.SpaceEnum_ActorDetailType.ENUM, SrcActorType))
      Log.Debug(pos.x, pos.y, pos.z)
      local battleReward = npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Battle
      if not self.battleNPCGenerator then
        battleReward = false
      end
      if self._npcDic[src_npc_id] or battleReward then
        Log.Debug("create!")
        self:CreateNpc(npcInfo, true)
      else
        Log.Debug("\231\188\147\229\173\152\229\136\155\229\187\186")
        if not self._prepareMountDic[src_npc_id] then
          self._prepareMountDic[src_npc_id] = {}
        end
        table.insert(self._prepareMountDic[src_npc_id], npcInfo)
      end
    end
  else
    if 1 ~= npcInfo.base.enter_scene_times then
      npcInfo.npc_base.refresh_src = ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Normal
    end
    self:CreateNpc(npcInfo)
  end
  if npcInfo.world_combat_info and npcInfo.world_combat_info.avatar_id ~= nil and #npcInfo.world_combat_info.avatar_id > 0 then
    local Action = _G.ProtoMessage:newSpaceAct_WorldCombatBegin()
    Action.npc_id = npcInfo.base.actor_id
    Action.world_combat_id = npcInfo.world_combat_info.world_combat_id
    Action.avatar_id = npcInfo.world_combat_info.avatar_id
    Action.world_combat_cfg_id = npcInfo.world_combat_info.world_combat_cfg_id
    Action.world_combat_phase = npcInfo.world_combat_info.world_combat_phase
    _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.WorldCombatBegin, Action)
  end
end

function NPCModule:OnServerCreateBall(npcInfo)
  Log.Warning("\229\146\149\229\153\156\231\144\131\229\144\142\231\187\173\228\184\141\229\186\148\232\175\165\230\152\175\229\144\142\229\143\176\228\184\139\229\143\145\231\154\132\239\188\140\229\166\130\230\158\156\231\156\139\229\136\176\232\191\153\229\143\165\232\175\180\230\152\142\229\144\142\229\143\176\228\184\141\229\164\159\230\150\176\239\188\140\231\148\168\229\188\128\229\143\145\230\156\141\232\175\149\232\175\149\229\144\167\239\188\140\230\151\167\230\156\141\229\138\161\229\153\168\231\154\132\230\138\165\233\148\153\229\143\175\228\187\165\230\154\130\230\151\182\229\191\189\231\149\165\239\188\140\229\133\136\228\191\157\231\149\153\228\185\139\229\137\141\231\154\132\233\128\187\232\190\145\232\174\169\229\138\159\232\131\189\228\184\141\232\135\179\228\186\142\229\135\186\229\164\170\229\164\167\233\151\174\233\162\152")
  if not self.ThrowSessionManager then
    Log.Error("\228\184\186\228\187\128\228\185\136???\228\184\186\228\187\128\228\185\136\232\131\189\231\187\149\232\191\135OnConstruct\231\132\182\229\144\142\232\176\131\231\148\168\229\136\176\232\191\153\228\184\170\229\135\189\230\149\176\239\188\140\232\191\153\229\144\136\231\144\134\229\144\151\239\188\159ThrowSessionManager\229\183\178\231\187\143\228\184\162\228\186\134\239\188\140\229\166\130\230\158\156\233\129\135\229\136\176\232\191\153\232\161\140\230\138\165\233\148\153\232\175\183\229\143\145\231\187\153marvynwang")
  end
  local MiscInfo = npcInfo and npcInfo.misc_info
  local ThrowID = MiscInfo and (MiscInfo.throw_id or 0) or 0
  local NPCBase = npcInfo and npcInfo.npc_base
  local SourceID = NPCBase and (NPCBase.src_npc_id or 0) or 0
  local Found = self.ThrowSessionManager and self.ThrowSessionManager:GetBall(SourceID, ThrowID)
  if Found then
    Found:InitWithNpcInfo(npcInfo)
    Found.ThrowSession.bIsLocal = false
    self.ThrowSessionManager:ForgetBall(Found)
    self:InternalAddNPC(npcInfo, Found)
    Found:CalSquaredDis2Local()
    Found.distanceOptLodTime = -1
    Found:Update(0.022)
  elseif NPCLuaUtils.HasValidPoint(npcInfo) then
    Log.Error("\229\151\175\239\188\159\229\146\149\229\153\156\231\144\131\228\184\141\232\167\129\228\186\134\239\188\159\233\130\163\229\176\177\228\184\141\229\136\155\229\187\186\228\186\134\239\188\140\229\188\128\230\145\134\239\188\140\229\143\141\230\173\163\229\146\149\229\153\156\231\144\131\228\185\159\228\184\141\231\149\153\229\156\186\239\188\140\230\178\161\230\156\137\229\176\177\230\178\161\230\156\137\229\144\167\239\188\140\229\146\149\229\153\156\231\144\131\230\182\136\229\164\177\228\186\134\230\128\187\230\152\175\230\156\137\229\174\131\231\154\132\233\129\147\231\144\134\231\154\132")
  end
end

function NPCModule:OnServerCreatePet(npcInfo)
  local MiscInfo = npcInfo and npcInfo.misc_info
  local ThrowID = MiscInfo and (MiscInfo.throw_id or 0) or 0
  local Found = self.ThrowSessionManager:GetPet(npcInfo.base.owner_id, ThrowID, npcInfo.pet_info.gid)
  local Player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, npcInfo.base.owner_id)
  local IsInWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInWorldCombat)
  if Found then
    if Found.ThrowSession and Found.ThrowSession.IsDying and Found.ThrowSession:IsDying() then
      Log.Warning("\228\184\139\229\143\145\231\154\132\229\164\170\230\153\154\228\186\134\239\188\140\229\183\178\231\187\143\229\156\168\229\155\158\230\148\182\228\184\173\230\136\150\229\183\178\231\187\143\229\136\160\233\153\164\228\186\134\239\188\140\229\176\177\228\184\141\232\166\129\230\157\165\228\186\134", npcInfo.base.actor_id, Found.ThrowSession.Status)
      return
    end
    Found:InitWithNpcInfo(npcInfo)
    self.ThrowSessionManager:ForgetPet(Found)
    Found:UpdateLodTime()
    Found:UpdateData(npcInfo, false)
    self:InternalAddNPC(npcInfo, Found)
    local Session = Found.ThrowSession
    if Session then
      if not Session.bHasPendingRelease then
        Session:SetStatus(ThrowSessionStatusEnum.PostInteract)
      end
      if Player.ThrowManagementComponent then
        Player.ThrowManagementComponent:AddThrowSession(npcInfo.base.actor_id, Session)
      end
    else
      Log.Error("Can't find session on scene npc!!!")
    end
    if IsInWorldCombat then
      Found:SetHitedComponent(true)
    end
    self:SendSenseEvent(Found:GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_PET_DROP)
  else
    local Session = Player.ThrowManagementComponent:GetThrowSession(npcInfo.base.actor_id, npcInfo.pet_info.gid)
    if Session then
      local Pet = self:CreateNpc(npcInfo)
      Pet:SetThrowSession(Session)
      Pet:UpdateLodTime()
      Session:SetNPC(Pet)
      _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.ADD_THROW_SESSION_PET, Session)
      Session:SetStatus(ThrowSessionStatusEnum.PostInteract)
      if IsInWorldCombat then
        Pet:SetHitedComponent(true)
      end
      self:SendSenseEvent(Pet:GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_PET_DROP)
    else
      Log.Error("\230\137\190\228\184\141\229\136\176\230\149\176\230\141\174\227\128\130\227\128\130\227\128\130")
    end
  end
end

function NPCModule:LoadMapStart(SameScene)
  Log.Debug("NPCModule:LoadMapStart")
  ToggleNPCCheck(false)
  self:ClearAll(SameScene)
  self.MapLoaded = false
end

function NPCModule:OnMapLoaded()
  self:Log("NPCModule:OnMapLoaded")
  if 1 == SignificanceCalcNPC then
    ToggleNPCCheck(true)
  end
  local allnpc = self.data:GetAllNPC()
  for _, npcInfo in pairs(allnpc) do
    self:PreInfoAndCreate(npcInfo)
  end
  local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
  if hudClass then
    local world = UE4.UNRCPlatformGameInstance.GetInstance()
    self:PreCreateHudClass(NPCModuleEnum.HudPoolType.PetHud, function()
      return UE4.UWidgetBlueprintLibrary.Create(world, hudClass)
    end)
  end
  self.MapLoaded = true
end

function NPCModule:OnNPCLeave(id, bClient)
  local npc = self._npcDic[id]
  if npc and npc.serverData.base then
    self:Log("[NpcAOI]OnNPCLeave", id, npc.serverData.base.name, bClient and "true" or "false")
  else
    self:Log("[NpcAOI]OnNPCLeave, but cannot find the npc.", id, bClient and "true" or "false")
  end
  self:RecordOperations()
  self:Log("NPCModule:OnNPCLeave", string.format("%u %d", id, id))
  self:RemoveNpc(id, true)
end

function NPCModule:OnFriendRidePetNPCEndLeave(id)
  local npc = self._npcDic[id]
  if npc and npc.serverData.base then
    self:Log("[NpcAOI]OnFriendRidePetNPCEndLeave", id, npc.serverData.base.name)
    npc:SendEvent(NPCModuleEvent.ON_NPC_FRIENDRIDE_END, npc)
  else
    self:Log("[NpcAOI]OnFriendRidePetNPCEndLeave, but cannot find the npc.", id)
  end
end

function NPCModule:RemoveNpc(id, immediately, debug)
  debug = debug or false
  self.data:RemoveNPC(id)
  local npc = self._npcDic[id]
  self._npc2LoadQueue:Remove(npc)
  if npc then
    self:TryRemovePlayerPet(npc.serverData)
    npc:SendEvent(NPCModuleEvent.On_NPC_LEAVE, npc)
    NRCEventCenter:DispatchEvent(NPCModuleEvent.On_NPC_LEAVE, npc)
    if not npc.notDestroyFlag or debug then
      self:Log("\228\184\141\229\156\168\229\136\155\229\187\186\232\191\135\231\168\139\228\184\173\239\188\140\231\171\139\229\141\179\232\135\170\228\184\187\230\142\167\229\136\182\230\182\136\229\164\177", id)
      npc:Disappear(immediately)
      self._npcDic[id] = nil
      self._npcIterDic[npc.hashId] = nil
      local RefreshPointID = npc:GetRefreshPointID()
      if RefreshPointID > 0 then
        self._npcContentDic[RefreshPointID] = nil
      end
      local LogicID = npc:GetLogicID()
      if LogicID and LogicID > 0 then
        self._npcLogicDic[LogicID] = nil
      end
      self._hashIDQueue:Enqueue(npc.hashId)
    else
      self:Log("\229\136\155\229\187\186\232\191\135\231\168\139\228\184\173\239\188\140\229\187\182\232\191\159\230\182\136\229\164\177", id)
      npc.shouldDestroy = true
      if npc.InteractionComponent then
        npc.InteractionComponent:TryDisableInteraction()
      end
      if npc.viewObj and npc.viewObj.OnShouldDestroy then
        npc.viewObj:OnShouldDestroy()
      end
    end
  else
    for src_id, mount_npc_array in pairs(self._prepareMountDic) do
      for index, actor_info in pairs(mount_npc_array or {}) do
        if actor_info.base.actor_id == id then
          self:TryRemovePlayerPet(actor_info)
          table.removeKey(mount_npc_array, index)
          if 0 == table.size(mount_npc_array) then
            table.removeKey(self._prepareMountDic, src_id)
          end
          return
        end
      end
    end
  end
end

function NPCModule:UnRegisterNPCFromNPCModule(id)
  self.data:RemoveNPC(id)
  local npc = self._npcDic[id]
  if npc and npc.serverData.base then
    self:Log("[NpcAOI]UnRegisterNPCFromNPCModule", string.format("%u %d", id, id), npc.serverData.base.name)
  else
    self:Log("[NpcAOI]UnRegisterNPCFromNPCModule, but cannot find the npc.", string.format("%u %d", id, id))
  end
  self._npc2LoadQueue:Remove(npc)
  if npc then
    self:TryRemovePlayerPet(npc.serverData)
    npc:SendEvent(NPCModuleEvent.On_NPC_LEAVE, npc)
    NRCEventCenter:DispatchEvent(NPCModuleEvent.On_NPC_LEAVE, npc)
    self._npcDic[id] = nil
    self._npcIterDic[npc.hashId] = nil
    local RefreshID = npc:GetRefreshPointID()
    if RefreshID > 0 then
      self._npcContentDic[RefreshID] = nil
    end
    local LogicID = npc:GetLogicID()
    if LogicID and LogicID > 0 then
      self._npcLogicDic[LogicID] = nil
    end
    self._hashIDQueue:Enqueue(npc.hashId)
    npc.serverData.base.actor_id = 0
  else
  end
end

function NPCModule:OnNPCServerMove(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.ServerMove, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCInterruptServerMove(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.InterruptServerMove, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcServerFly(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.ServerFly, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcWeatherChange(action)
  Log.Warning("NPCModule:OnNpcWeatherChange", action.actor_id, action.area_id, action.weather)
  local npc = self._npcDic[action.actor_id]
  if npc then
    if not npc.serverData.weather_info then
      npc.serverData.weather_info = {}
    end
    npc.serverData.weather_info.weather_type = action.weather
    npc.luaObj:OnWeatherChange()
  else
    Log.DebugFormat("[OnNpcWeatherChange] Can't find NPC %u ", action.actor_id)
  end
end

function NPCModule:OnNpcWorldHidden(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.WorldHidden, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcWorldUnhidden(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.WorldUnhidden, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcServerAttach(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.ServerAttach, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcCancelServerAttach(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.CancelServerAttach, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcServerJump(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.Launch, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcCancelServerJump(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.CancelLaunch, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcServerStickTo(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.StickTo, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcServerFinishStickTo(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.FinishStickTo, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnAiTryInteractNpc(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.TryInteractNpc, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcPlayRealtimeDialog(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayRealtimeDialog, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcStopRealtimeDialog(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.StopRealtimeDialog, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCCollisionCancelRecover(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc:SetCollisionDisable(action.is_collision_cancel, NPCModuleEnum.NpcReasonFlags.AI)
    if npc.ServerAIComponent then
      npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.CollisionCancelRecover, action, BaseData, action.sync_common_info)
    end
  end
end

function NPCModule:OnNpcAiStatusChanged(action)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.AIComponent then
    npc.AIComponent.battleState = action.battle_ai_status
  end
end

function NPCModule:OnNpcAiControlFlagsChanged(action)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.AIComponent then
    npc.AIComponent:ApplyControlFlags(action.scene_ai_control_flags)
  end
end

function NPCModule:OnStunServerNty(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.AIComponent then
    local finalDuration = action.remain_time
    if finalDuration and finalDuration > 0 then
      local StunComp = npc:EnsureComponent(StunComponent)
      StunComp:Stun(finalDuration)
    end
  end
end

function NPCModule:OnNPCPlayChatBubble(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayChatBubble, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCMfbtDebug(action)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.AIComponent and npc.AIComponent.AIController then
    npc.AIComponent.AIController:OnMfbtDebug(action)
  else
    Log.PrintScreenMsg("[ServerAIDebug] \229\143\175\232\131\189\229\135\186\232\167\134\233\135\142\230\136\150\232\162\171\230\156\172\229\156\176\231\167\187\233\153\164\228\186\134\239\188\140\233\128\154\231\159\165\230\156\141\229\138\161\229\153\168\231\155\180\230\142\165\229\133\179\230\142\137", action.actor_id)
  end
end

function NPCModule:OnNet_ClientVisualizationNty(nty)
  Log.Warning("OnNet_ClientVisualizationNty count:", #nty.ai_list)
  self.client_vis_nty_count = self.client_vis_nty_count - 1
  if #nty.ai_list ~= #nty.player_list then
    return Log.Error("[Error] ai_list ~= player_list\239\188\140\232\175\183\230\163\128\230\159\165 ZoneSceneClientVisualizationNty")
  end
  local DotsInsightsSubSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UDotsInsightsSubSystem)
  for _, actor in ipairs(nty.ai_list) do
    DotsInsightsSubSystem:RecordUnit(actor.actor_id, SceneUtils.ServerPos2ClientPos(actor.pt.pos), AIDefines.EInsightsUnitTag.EInsightsUnitTag_AI | AIDefines.EInsightsUnitTag.EInsightsUnitTag_Dots | AIDefines.EInsightsUnitTag.EInsightsUnitTag_Server, actor.owner_id, actor.lod_type - 1, true)
  end
  local localPlayerId = 0
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer.serverData then
    localPlayerId = localPlayer.serverData.base.actor_id
    DotsInsightsSubSystem:SetLocalPlayerId(localPlayerId)
  end
  for _, player in ipairs(nty.player_list) do
    if player.player_id ~= localPlayerId then
      DotsInsightsSubSystem:RecordUnit(player.player_id, SceneUtils.ServerPos2ClientPos(player.pt.pos), AIDefines.EInsightsUnitTag.EInsightsUnitTag_Player | AIDefines.EInsightsUnitTag.EInsightsUnitTag_Server, 0, 0, true)
    end
  end
end

function NPCModule:OnSwitchServerToClientAINty(notify)
  Log.Debug("OnSwitchServerToClientAINty")
  self.SceneAIManager:SwitchServerToClientAIBatch(notify.actor_list, notify.comp_data_list)
end

function NPCModule:OnInformClientSwitchAi(action)
  Log.DebugFormat("OnInformClientSwitchAi, type=%d", action.npc_type or -1)
  if 1 == action.npc_type then
    local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      self.SceneAIManager:SwitchClientToServerAI(self:GetPetByPlayer(localPlayer.serverData.base.actor_id or 0))
    end
  elseif 0 == action.npc_type then
    self.SceneAIManager:SwitchClientToServerAI()
  end
end

function NPCModule:OnClientSwitchToServerAi(action)
  Log.Debug("OnSwitchClientToServerAINty")
  self.SceneAIManager:ApplySwitchClientToServerAIBatch(action.actor_list)
end

function NPCModule:OnHabitatNeighborInfoChange(action)
  self.SceneAIManager:OnHabitatNeighborInfoChange(action)
end

function NPCModule:OnAllHabitatNeighborInfoChange(action)
  self.SceneAIManager:OnAllHabitatNeighborInfoChange(action)
end

function NPCModule:GetServerAICount()
  return self.ServerAICount
end

function NPCModule:OnNPCIntimateBondFind(action)
  local npc = self._npcDic[action.actor_id]
  local pos
  if 0 ~= action.target_actor_id then
    local chest = self._npcDic[action.target_actor_id]
    pos = chest:GetActorLocation()
    chest.luaObj.IntimateBondFindAIId = action.actor_id
    Log.Debug("NPCModule:OnNPCIntimateBondFind : ", chest.luaObj and chest.luaObj.IntimateBondFindAIId)
  else
    pos = SceneUtils.ServerPos2ClientPos(action.target_pos)
  end
  Log.Debug("chest.sceneCharacter.luaObj.IntimateBondFindAIId:", action.actor_id, action.target_actor_id, tostring(pos))
  if npc and nil ~= pos then
    npc.AIComponent.AIController:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_BOUD_FIND, 1, pos)
  end
end

function NPCModule:OnNPCDotsComponentSync(action)
  Log.Debug("OnNPCDotsComponentSync", action.npc_id)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local LuaData = {}
    for _, BytesData in ipairs(action.component_datas) do
      LuaData[BytesData.id] = BytesData.data
    end
    npc.AIComponent.AIController:SetComponentData(LuaData)
  end
end

function NPCModule:OnNPCMove(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local bSucc = false
    local toPosVector = SceneUtils.ServerPos2ClientPos(action.to_pos)
    toPosVector, bSucc = self:GetPosInNav(toPosVector, 100, 2000)
    if bSucc then
      npc:SimpleMoveTo(toPosVector)
    else
    end
  else
    Log.DebugFormat("Can't find NPC %u when move", action.actor_id)
  end
end

function NPCModule:OnNPCTeleport(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc:SetActorLocation(SceneUtils.ServerPos2ClientPos(action.to_pt.pos))
    npc:SetActorRotation(SceneUtils.ServerDir2ClientRotator(action.to_pt.dir.z))
  end
end

function NPCModule:OnNPCUpdateLogicStatus(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc:UpdateLogicStatus(action)
    local refreshId = npc.serverData.npc_base.npc_content_cfg_id
    for moduleName, v in pairs(self._lockListeners) do
      if v[refreshId] or v._all then
        self:DispatchLockStatusChange(moduleName, refreshId, SceneUtils.IsLogicStatusUnlock(npc))
      end
    end
  else
    Log.Debug("\233\128\187\232\190\145\231\138\182\230\128\129\230\155\180\230\150\176\239\188\140\230\137\190\228\184\141\229\136\176NPC\239\188\129\239\188\129\239\188\129\239\188\129", action.actor_id)
  end
end

function NPCModule:OnCombineLockStateChange(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local Comp = npc:EnsureComponent(LockIndicatorComponent)
    Comp:UpdateWithAction(action)
  else
    Log.Debug("NPCModule:OnCombineLockStateChange \230\137\190\228\184\141\229\136\176\229\175\185\229\186\148npc ", string.format("%u %d", action.actor_id, action.actor_id), "\229\156\176\229\155\190\230\152\175\229\144\166\229\138\160\232\189\189\239\188\140\229\166\130\229\138\160\232\189\189\229\136\153\228\184\141\229\186\148\230\152\175\229\174\162\230\136\183\231\171\175\231\154\132\233\151\174\233\162\152", self.MapLoaded)
  end
end

function NPCModule:DispatchLockStatusChange(moduleName, refreshId, bUnlock)
  NRCEventCenter:DispatchEvent(string.format("%s.LockStatusChange", moduleName), refreshId, bUnlock)
end

function NPCModule:RegisterLockStatusListener(moduleName, handler, callback)
  NRCEventCenter:RegisterEvent("NPCModule", handler, string.format("%s.LockStatusChange", moduleName), callback)
end

function NPCModule:UnRegisterLockStatusListener(moduleName, handler, callback)
  NRCEventCenter:UnRegisterEvent(handler, string.format("%s.LockStatusChange", moduleName), callback)
end

function NPCModule:AddLockStatusListenId(moduleName, refreshId)
  if not self._lockListeners[moduleName] then
    self._lockListeners[moduleName] = {}
  end
  if refreshId then
    self._lockListeners[moduleName][refreshId] = true
  else
    self._lockListeners[moduleName]._all = true
  end
end

function NPCModule:RemoveLockStatusListenId(moduleName, refreshId)
  if not self._lockListeners[moduleName] then
    return
  end
  if refreshId then
    self._lockListeners[moduleName][refreshId] = nil
  else
    self._lockListeners[moduleName]._all = nil
  end
end

function NPCModule:ClearLockStatusListenId(moduleName, refreshId)
  if not self._lockListeners[moduleName] then
    return
  end
  self._lockListeners[moduleName] = {}
  self._lockListeners[moduleName]._all = nil
end

function NPCModule:OnOptionInfoChange(action, Tag, BaseData)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnOptionsChange(action, Tag, BaseData)
    if self:IsMonitor(action.npc_id, npc.config.id) then
      self:Log("##NPCMonitor")
      Log.Dump(action, 99, "NPCModule:OnOptionInfoChange")
    end
  else
  end
end

function NPCModule:OnDialogSelectInfoChange(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnSelectionInfoChange(action)
  else
  end
end

function NPCModule:OnAddStoryFlags(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnAddStoryFlag(action)
  else
    Log.DebugFormat("Can't find NPC %u when adding story flag", action.actor_id)
  end
end

function NPCModule:OnRemoveStoryFlags(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnRemoveStoryFlag(action)
  else
    Log.DebugFormat("Can't find NPC %u when removing story flag", action.actor_id)
  end
end

function NPCModule:OnAddSelectAction(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnAddSelectAction(action)
  else
    Log.DebugFormat("Can't find NPC %u when adding selects", action.actor_id)
  end
end

function NPCModule:OnRemoveSelectAction(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnRemoveSelectAction(action)
  else
    Log.DebugFormat("Can't find NPC %u when removing selects", action.actor_id)
  end
end

function NPCModule:OnAddOptionAction(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnAddOptionAction(action)
  else
    Log.DebugFormat("Can't find NPC %u when add option", action.npc_id)
  end
end

function NPCModule:OnRemoveOptionAction(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    local InterComp = npc:EnsureComponent(InteractionComponent)
    InterComp:OnRemoveOptionAction(action)
  else
    Log.DebugFormat("Can't find NPC %u when removing option", action.npc_id)
  end
end

function NPCModule:OnPotentialEnergyChange(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local Old = npc.serverData.potential_energy_info or {}
    local New = action.potential_energy_info
    local Comp = npc:EnsureComponent(PotentialEnergyComponent)
    Comp:OnPotentialEnergyChanged(Old, New)
  else
    Log.DebugFormat("Can't find NPC %u when set OnPotentialEnergyChange", action.actor_id)
  end
end

function NPCModule:OnPropertyTypeChange(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local Old = npc.serverData.property_type_info or {}
    local New = action.property_type_info
    local Comp = npc:EnsureComponent(PotentialEnergyComponent)
    Comp:OnPropertyTypeChange(Old, New)
  else
    Log.DebugFormat("Can't find NPC %u when set OnPropertyTypeChange", action.actor_id)
  end
end

function NPCModule:OnPlayAnimBeforeRemove(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc.bDisappearPerform = true
  else
    Log.DebugFormat("Can't find NPC %u when set bDisappearPerform", action.npc_id)
  end
end

function NPCModule:OnNpcBornEnd(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    if npc.BornDieComponent then
      npc.BornDieComponent:OnBornEnd(action)
    end
    npc:SendEvent(NPCModuleEvent.On_NPC_Born, npc, action)
  else
  end
end

function NPCModule:OnNpcDieBegin(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc:EnsureComponent(BornDieComponent)
    if npc.BornDieComponent then
      npc.BornDieComponent:OnBeginDying(action)
    end
    npc:SendEvent(NPCModuleEvent.On_NPC_Die, npc, action)
  else
  end
end

function NPCModule:OnActorSwitchBossAINty(action)
  Log.PrintScreenMsg("OnActorSwitchBossAINty %s", tostring(action.is_server_ai))
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc.serverData.npc_base.is_server_ai = action.is_server_ai
    local AIComp = npc.AIComponent
    if AIComp then
      if action.is_server_ai then
        AIComp:SwitchToServerAI()
        AIComp:GetServerAIComponent()
      else
        AIComp:UpdateDataFromConfig()
        AIComp:RescheduleGenre()
      end
    end
    if npc.TurnComponent then
      npc.TurnComponent:StopTurn(AIDefines.ActionResult.Aborted, true)
    end
  end
end

function NPCModule:OnActorAIPerformGroupChanged(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    if not npc.serverData.ai_info then
      npc.serverData.ai_info = {}
    end
    npc.serverData.ai_info.ai_override_perform_group_id = action.perform_group_id
    local AIComp = npc:EnsureComponent(AIComponent)
    AIComp:UpdateDataFromConfig()
  end
end

function NPCModule:OnActorAISetMoveMode(action)
  local npc = self._npcDic[action.actor_id]
  if not npc or npc.AIComponent and npc.AIComponent:UpdateMovementModeAlter(action.move_mode) then
  else
    npc:SetMovementMode(action.move_mode.move_mode, action.move_mode.move_sub_mode)
  end
end

function NPCModule:OnActorUpdateVelocityOrientRotation(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.VelocityOrientRotation, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcWorldLaunchPlayer(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.WorldLaunchPlayer, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCPlayAnimation(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayAnimation, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCStopAnimation(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.StopAnimation, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCPlayZoomAnimation(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayZoomAnimation, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnPendantInfoChange(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    npc:EnsureComponent(PendantComponent):UpdateGroupInfo(action)
  end
end

function NPCModule:OnUnlockSleepingOwl(action)
  local npc = self._npcDic[action.npc_id]
  if npc then
    npc:SendEvent(NPCModuleEvent.UnlockSleepingOwl, action)
  end
  _G.NRCModuleManager:DoCmd(_G.SleepingOwlModuleCmd.OnUnlockSleepOwl, action)
end

function NPCModule:OnPetClosenessLvUpgrade(Action)
  local npc = self:GetNpcByServerID(Action.pet_npc_obj_id)
  if not npc then
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176\228\187\187\228\189\149\229\144\140\230\173\165\228\184\173\231\154\132\231\178\190\231\129\181")
    return
  end
  local PetStatusComp = npc:EnsureComponent(PetStatusComponent)
  if PetStatusComp then
    PetStatusComp:OnSyncPetUpdate(Action)
  end
end

function NPCModule:UpdatePetInteractionResult(Action)
  local npc = self._npcDic[Action.pet_npc_id]
  local hostNpc = self._npcDic[Action.npc_id]
  Log.Debug("\229\144\136\229\135\187\228\186\164\228\186\146\230\151\165\229\191\151: NPCModule:UpdatePetInteractionResult", table.getKeyName(_G.ProtoEnum.SpaceAct_PetInteractResNty.PetInteractStatus, Action.status), Action.npc_id, Action.pet_npc_id, Action.option_id, Action.combine_interact_pet_npc_ids and #Action.combine_interact_pet_npc_ids)
  if not hostNpc then
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176\230\173\163\229\156\168\228\186\164\228\186\146\231\154\132npc\231\155\174\230\160\135\229\175\185\232\177\161")
  else
    npc = npc or hostNpc:EnsureComponent(PetHolderComponent):GetPets()[1]
  end
  if not npc then
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176\228\187\187\228\189\149\228\186\164\228\186\146\228\184\173\231\154\132\231\178\190\231\129\181")
    return
  end
  local InterComp = npc:EnsureComponent(PetInteractionComponent)
  if InterComp then
    InterComp:UpdateInteractResult(Action)
  end
end

function NPCModule:UpdateCombineInteractInfo(Action)
  local npc = self._npcDic[Action.actor_id]
  Log.Debug("\229\144\136\229\135\187\228\186\164\228\186\146\230\151\165\229\191\151: NPCModule:UpdateCombineInteractInfo", Action.actor_id, "||", Action.wait_pet_interact_avatar_id)
  if npc then
    local Comp = npc:EnsureComponent(PetHolderComponent)
    if Comp then
      Comp:UpdateAction(Action)
    end
  else
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176id\228\184\186 %u \231\154\132NPC", Action.actor_id)
  end
end

function NPCModule:UpdateRelatedNPCInfo(Action)
  local npc = self._npcDic[Action.actor_id]
  if npc then
    local Comp = npc:EnsureComponent(ActorHolderComponent)
    if Comp then
      Comp:UpdateRelatedNPC(Action)
    end
  else
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176id\228\184\186 %u \231\154\132NPC", Action.actor_id)
  end
end

function NPCModule:OnWorldCombatBuffChange(Action, Tag, BaseData)
  local npc = self._npcDic[Action.actor_id]
  if npc then
    local Comp = npc:EnsureComponent(WorldCombatBuffComponent)
    Comp:OnBuffChanges(Action)
  else
    Log.ErrorFormat("\230\137\190\228\184\141\229\136\176id\228\184\186 %u \231\154\132NPC", Action.actor_id)
  end
end

function NPCModule:OnNPCAnimPauseOrResume(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.AnimPauseOrResume, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCLookAt(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.LookAt, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCHeadLookAt(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc.viewObj:OnNPCHeadLookAt(action.look_at_pos)
  end
end

function NPCModule:OnNPCTurnTo(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.TurnTo, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcCancelTurnTo(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.CancelTurnTo, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcWorldAttack(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.WorldAttack, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcStopWorldAttack(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.StopWorldAttack, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcPlayPerceptionEffect(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayPerceptionEffect, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcPlayPerceptionHud(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayPerceptionHud, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcPerceivePlayer(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PerceivePlayer, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcAiSeqIdNotify(action, Tag, baseData)
  if not action.actor_id_list or not action.ai_sed_list then
    Log.PrintScreenMsg("[NPCModule:OnNpcAiSeqIdNotify] action.actor_id_list or action.ai_sed_list is nil")
    return
  end
  if #action.actor_id_list ~= #action.ai_sed_list then
    Log.PrintScreenMsg("[NPCModule:OnNpcAiSeqIdNotify] action.actor_id_list and action.ai_sed_list length mismatch")
    return
  end
  for i, actor_id in ipairs(action.actor_id_list) do
    local npc = self._npcDic[actor_id]
    if npc and npc.ServerAIComponent then
      npc.ServerAIComponent.seq_id = action.ai_sed_list[i]
    end
  end
end

function NPCModule:OnNPCShowPetFaceState(action)
  assert(false, "OnNPCShowPetFaceState : deprecated")
end

function NPCModule:OnNPCModelShowHide(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc then
    if npc.viewObj then
      if action.is_fade_out == nil then
      end
      npc.viewObj:SetActorHiddenInGame(action.is_fade_out)
    end
    if npc.ServerAIComponent then
      npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.Empty, action, BaseData, action.sync_common_info)
    end
  end
end

function NPCModule:OnNPCBattleOnOff(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc then
    if action.on_or_off == true then
      npc.InteractionComponent:TryEnableInteraction()
    else
      npc.InteractionComponent:TryDisableInteraction()
    end
    Log.Debug("[NPCModule:OnNPCBattleOnOff] Server set npa interaction enable:", action.on_or_off, npc.config.id, npc.config.name)
    if npc.ServerAIComponent then
      npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.Empty, action, BaseData, action.sync_common_info)
    end
  end
end

function NPCModule:OnNPCSetPos(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc then
    local pos = SceneUtils.ServerPos2ClientPos(action.to_pos)
    local halfHeight = npc:GetScaledHalfHeight()
    if npc:IsPetEgg() then
      pos.Z = pos.Z + halfHeight
    else
      pos = SceneUtils.GetPosInLand(pos, halfHeight, halfHeight * 2, halfHeight * 5) or pos
    end
    npc:SetActorLocation(pos)
    local Rotator = UE.UKismetMathLibrary.MakeRotator(action.to_dir.x / 10, action.to_dir.y / 10, action.to_dir.z / 10)
    npc:SetActorRotation(Rotator)
    if npc.ServerAIComponent then
      npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.SetNpcPos, action, BaseData, action.sync_common_info)
    end
  end
end

function NPCModule:OnNPCPlayVoice(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc.viewObj and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlayVoice, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNPCStopVoice(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.Empty, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcPlaySkill(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.PlaySkill, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnNpcStopSkill(action, Tag, BaseData)
  local npc = self._npcDic[action.actor_id]
  if npc and npc.ServerAIComponent then
    npc.ServerAIComponent:EnqueueEvent(ServerAICommandEnum.ServerAICommandEvent.StopSkill, action, BaseData, action.sync_common_info)
  end
end

function NPCModule:OnShowHideNPC(action)
  local ID = action.actor_id
  local npc = self._npcDic[ID]
  if npc then
    npc.serverData.misc_info.cannot_be_seen = action.cannot_be_seen
    npc.serverData.misc_info.npc_hide_flag = action.npc_hide_flag
    npc:BatchApplyFlags(action.cannot_be_seen, action.npc_hide_flag)
  end
end

function NPCModule:OnEnterBattle(center, radius)
  self:Log("NPCModule:OnEnterBattle center,radius:", center, radius)
  self.HasEnterBattle = true
  self:CommonHideNPCs(_G.Enum.PlayerConditionType.PCT_BATTLE)
  self.ThrowSessionManager:EnterBattle(center, radius)
  ToggleNPCCheck(false)
end

function NPCModule:OnLeaveBattle()
  self:Log("NPCModule:OnLeaveBattle", #self.cachedBattleNpcGenerate)
  self.HasEnterBattle = false
  for _, v in pairs(self.cachedBattleNpcGenerate) do
    Log.Debug("\231\188\147\229\173\152\229\136\155\229\187\186", v:DebugNPCNameAndID(), v.config.reward_drop_type, self.battleNPCGenerator.createNum)
    if v.config.reward_drop_type == Enum.RewardNpcType.RNT_DROP then
      self.battleNPCGenerator:SetCreateNPC(v)
    else
      self.battleNPCGenerator:ReSetCreateNPCTotalNum(self.battleNPCGenerator.createNum - 1)
      local pos = BattleExitHelper.CalcDeadPosition()
      pos = SceneUtils.GetPosInLand(pos, 60)
      v:SetActorLocation(pos)
      v.distanceOptLodTime = -1
      v:Update(0.022)
      v.luaObj.createFromReward = true
      self._npc2LoadQueue:EnQueue(v)
    end
  end
  self.cachedBattleNpcGenerate = {}
  self:CommonShowNPCs(_G.Enum.PlayerConditionType.PCT_BATTLE)
  self.ThrowSessionManager:LeaveBattle()
  self.LastBattleEndTime = _G.UpdateManager.Timestamp
  if 1 == SignificanceCalcNPC then
    ToggleNPCCheck(true)
  end
end

function NPCModule:OnGetHasEnterBattle()
  return self.HasEnterBattle
end

function NPCModule:GetLastBattleEndTime()
  return self.LastBattleEndTime
end

function NPCModule:CommonHideNPCs(Reason)
  local Impl = ShowHideFactory.Get(Reason)
  if not Impl then
    return
  end
  if not Impl:StartHide() then
    return
  end
  local ShowHideReason = Impl:GetReason()
  for _, v in pairs(self._npcIterDic) do
    if Impl:CheckShouldHide(v) then
      v:SetVisibleForReason(false, ShowHideReason)
    end
  end
  Impl:EndHide()
  self:UpdateTickStatus()
end

function NPCModule:CommonShowNPCs(Reason)
  local Impl = ShowHideFactory.Get(Reason)
  if not Impl then
    return
  end
  if not Impl:StartShow() then
    return
  end
  local ShowHideReason = Impl:GetReason()
  for _, v in pairs(self._npcIterDic) do
    if Impl:CheckShouldShow(v) and v:IsHidden(ShowHideReason) then
      local overlapAwareComp = v:EnsureComponent(OverlapAwareVisibilityComponent)
      overlapAwareComp:ResolveNPCOverlap(Enum.OverLapProcessingType.OLPT_OVERLAP)
      v:SetVisibleForReason(true, ShowHideReason)
    end
  end
  Impl:EndShow()
  self:UpdateTickStatus()
end

function NPCModule:ToggleHideNPCs(newState, functionType, Reason)
  if Enum.PlayerConditionType.PCT_BATTLE == Reason then
    return
  end
  if newState then
    self:CommonHideNPCs(Reason)
  else
    self:CommonShowNPCs(Reason)
  end
end

function NPCModule:CheckShouldHide(npc)
  local Instances = ShowHideFactory.GetInstances()
  for _, Instance in pairs(Instances) do
    if Instance.bShouldHideOrShow and Instance:CheckShouldHide(npc) then
      local ShowHideReason = Instance:GetReason()
      npc:SetHidden(true, ShowHideReason)
      npc:SetCollisionDisable(true, ShowHideReason)
    end
  end
end

function NPCModule:UpdateTickStatus()
  local Instances = ShowHideFactory.GetInstances()
  local ShouldPauseTick = false
  local ShouldPauseFind = false
  for _, Instance in pairs(Instances) do
    if Instance.bShouldHideOrShow then
      ShouldPauseTick = ShouldPauseTick or Instance:ShouldPauseTick()
      ShouldPauseFind = ShouldPauseFind or Instance:ShouldPauseFind()
    end
  end
  if ShouldPauseTick then
    ToggleNPCCheck(false)
  else
    ToggleNPCCheck(true)
  end
  if ShouldPauseFind then
    ShouldFindNPC = false
    Log.Debug("[NpcAction][Common] stop find npcs")
  else
    ShouldFindNPC = true
    Log.Debug("[NpcAction][Common] start find npcs")
  end
end

function NPCModule:UpdateHiddenStatus(npc)
  self:CheckShouldHide(npc)
end

function NPCModule:GetShouldFindNPC()
  return ShouldFindNPC
end

function NPCModule:SetNPCAILock(flag)
  for _, v in pairs(self._npcIterDic) do
    if v.AIComponent then
      v.AIComponent:ForceLock(flag)
    end
  end
end

function NPCModule:OnFindNPC(id)
  if not self._npcIterDic then
    return nil
  end
  for _, npc in pairs(self._npcIterDic) do
    if npc.config.id == id then
      return npc
    end
  end
  return nil
end

function NPCModule:DebugLoadQueue()
  Log.Debug("debug priority", #self._npc2LoadQueue._items)
  for i, npc in ipairs(self._npc2LoadQueue._items) do
    local selfDis = npc.squaredDis2LocalIgnoreZ
    local fatherId = math.max(1, math.floor(i / 2))
    local fatherNPC = self._npc2LoadQueue._items[fatherId]
    local fatherDis = fatherNPC.squaredDis2LocalIgnoreZ
    Log.Debug(selfDis >= fatherDis, selfDis, npc.viewObj:GetName(), "fater:", fatherDis, fatherNPC.viewObj:GetName())
  end
end

local Finder, FinderIndex, FinderSubIndex
local OldTickState = false

function NPCModule:OnTick(deltaTime)
  if SceneUtils.debugCloseNPCModuleTick then
    return
  end
  AIComponent.LoadSemaphore = 0
  if not self:CheckOperation() then
    self.npcActorPool:OnTick(deltaTime)
  end
  local npc = self._npc2LoadQueue:DeQueue()
  if npc and not npc.viewObj and not SceneUtils.debugCloseCreateNPCView then
    npc:CreateView(false)
  end
  if _G.GlobalConfig.bShouldShowDebugPetName then
    if not self.Res then
      self.Res = ResObject.MakeUClass("/Game/NewRoco/Modules/System/Marker/Res/BP_MarkerBoss.BP_MarkerBoss_C")
      self.Res:StartLoad(self, self.SpawnBeam)
    end
    self:ShowNPCDebugNameByDistance()
  elseif self.Res then
    self.Res:Release()
    self.Res = nil
    if self.Beams and next(self.Beams) then
      for i, beam in pairs(self.Beams) do
        if UE4.UObject.IsValid(beam) and beam.K2_DestroyActor then
          beam:K2_DestroyActor()
        end
      end
      self.Beams = nil
      self.BeamsRef = nil
    end
  end
  if _G.GlobalConfig.bShouldShowRevivePointInfo then
    self:ShowRevivePointNPCDebugName()
  end
  if _G.GlobalConfig.bShouldShowGMMarkerPointInfo then
    self:ShowGMMarkerPointNPCDebugName()
    self:DrawMarkerPointDebugLine()
  end
  if 1 == SignificanceCalcNPC then
    if not Ticker then
      Ticker = UE.UNRCPlatformGameInstance.GetInstance():GetNPCTicker()
    end
    local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local PlayerView = Player and Player.viewObj
    if PlayerView and UE4.UObject.IsValid(PlayerView) then
      if PlayerView.BP_RideComponent and UE4.UObject.IsValid(PlayerView.BP_RideComponent.RidePet) then
        PlayerView = PlayerView.BP_RideComponent.RidePet
      end
      PlayerPosCache.X, PlayerPosCache.Y, PlayerPosCache.Z = PlayerView:K2_GetActorLocation_XYZ()
      UE4.UNRCStatics.GetActorForwardVectorInplace(PlayerView, PlayerForwardsCache)
      PlayerInteractState = self:GetPlayerInteractState(Player)
      local HalfHeight, Radius = Player:GetControlPawnCapsuleSize()
      PlayerRadiusDiff = math.max(Radius - 45, 0)
    else
      return
    end
    local Now = UE.UNRCStatics.GetUTCTimestampMS()
    local SlowCount = 0
    local SlowTicks = {
      Ticker:TickSlow()
    }
    SlowCount = #SlowTicks
    local State = _G.SceneModuleCmd and _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.CheckSceneFullyEntered) or false
    if State or NRCEnv:IsLocalMode() then
      local CheckAutoCollect = self:CanAutoCollect(Player)
      local HasAutoCollectThisFrame = false
      for i = 1, SlowCount do
        local NPC = SlowTicks[i]
        if NPC and (NPC.className == "SceneNpc" or NPC.className == "HomeSceneNPC") and NPC.updateEnable and not NPC.isDestroy then
          NPC:DistanceOptimize()
          if not NPC:IsLocal() then
            self:AdjustNPCDistance(NPC)
          end
          NPC:UpdateByDistance(deltaTime)
          if CheckAutoCollect and not HasAutoCollectThisFrame then
            local Option = NPC:GetAutoCollectOption(Now)
            if Option then
              Option:SendAutoCollectReq(Player)
              HasAutoCollectThisFrame = true
            end
          end
        end
      end
      if SlowCount > 20 and RocoEnv.IS_EDITOR then
        Log.DebugFormat("[NPC Tick] From C++: %d", SlowCount)
      end
    end
    if OldTickState ~= State then
      Log.Debug("[NpcAction][Common] Tick State Changed", OldTickState, "->", State)
      OldTickState = State
    end
  else
    local npcDic = self._npcIterDic
    for _, v in pairs(npcDic) do
      v:Update(deltaTime)
    end
  end
  if 1 == SignificanceCalcNPC and ShouldFindNPC then
    if not Finder then
      FinderIndex, Finder = next(self._npcFinders, FinderIndex)
    end
    if Finder then
      FinderSubIndex = Finder:StepIterate(self._npcIterDic, FinderSubIndex, FinderIndex)
      if not FinderSubIndex then
        FinderSubIndex = nil
        if not self._npcFinders[FinderIndex] then
          FinderIndex = nil
        end
        FinderIndex, Finder = next(self._npcFinders, FinderIndex)
      end
    end
  end
end

function NPCModule:ShowNPCDebugNameByDistance()
  local World = _G.UE4Helper.GetCurrentWorld()
  for _, n in pairs(self._npcDic) do
    local npc = n
    if not npc then
    else
      local Dist = npc.squaredDis2Local
      if not Dist then
      else
        local ServerData = npc.serverData
        if not ServerData then
        else
          local owlContId = ServerData.npc_base.owl_sanctuary_content_cfg_id
          local fakeId = ServerData.npc_base.ContentIdForOwl
          if Dist > 4000000 then
            if owlContId and 0 ~= owlContId and self.Beams and fakeId and self.Beams[fakeId] then
              local Beam = self.Beams[fakeId]
              local HasBeam = Beam and Beam:IsValid()
              if HasBeam then
                Beam:K2_DestroyActor()
                self.Beams[fakeId] = nil
                self.BeamsRef[fakeId] = nil
                ServerData.npc_base.ContentIdForOwl = nil
              end
            end
            goto lbl_196
          elseif owlContId and 0 ~= owlContId then
            if not self.Beams then
              goto lbl_196
            end
            if (not fakeId or not self.Beams[fakeId]) and self.Res then
              local BeamClass = self.Res:Get()
              self:SpawnOwlPet(npc, BeamClass)
            end
          end
          local Config = npc.config
          if not Config then
          else
            local View = npc.viewObj
            if not View then
            elseif not UE.UObject.IsValid(View) then
            else
              local id = Config.id
              local npc_content_cfg_id = ServerData.npc_base.npc_content_cfg_id
              local area_id = 0
              if npc_content_cfg_id then
                local npc_content_cfg = _G.DataConfigManager:GetNpcRefreshContentConf(npc_content_cfg_id, true)
                area_id = npc_content_cfg and npc_content_cfg.refresh_param
              end
              local debug_string = string.format("%s (%d,%d,%d)", ServerData.base.name, id or 0, npc_content_cfg_id or 0, area_id or 0)
              if owlContId and 0 ~= owlContId then
                if self.Beams and fakeId and self.Beams[fakeId] then
                  local Beam = self.Beams[fakeId]
                  local HasBeam = Beam and Beam:IsValid()
                  if HasBeam then
                    local Position = npc:GetActorLocation()
                    Beam:Abs_K2_SetActorLocation_WithoutHit(Position, false, true)
                  end
                end
                debug_string = string.format([[
%s (%d,%d,%d)
  %d]], ServerData.base.name, id or 0, npc_content_cfg_id or 0, area_id or 0, owlContId or 0)
              end
              UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, npc.viewObj:Abs_K2_GetActorLocation(), debug_string, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
            end
          end
        end
      end
    end
    ::lbl_196::
  end
end

function NPCModule:SpawnBeam()
  if self.Res then
    local BeamClass = self.Res:Get()
    if not BeamClass then
      return
    end
    if not self.Beams then
      self.Beams = {}
      self.BeamsRef = {}
    end
    for _, npc in pairs(self._npcDic) do
      local owlContId = npc.serverData.npc_base.owl_sanctuary_content_cfg_id
      if owlContId and 0 ~= owlContId then
        local fakeId = npc.serverData.npc_base.ContentIdForOwl
        if not fakeId then
          self:SpawnOwlPet(npc, BeamClass)
        end
      end
    end
  end
end

function NPCModule:SpawnOwlPet(npc, BeamClass)
  local fakeId = self:AcquireFakeID()
  npc.serverData.npc_base.ContentIdForOwl = fakeId
  self.Beams[fakeId] = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(BeamClass, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, {
    min = 100,
    max = 1000,
    mult = 10
  })
  self.BeamsRef[fakeId] = self.Beams and UnLua.Ref(self.Beams[fakeId])
  local OwlPetLevel = self:GetOwlPetLevel(npc.config.id)
  self.Beams[fakeId]:SetPetType(OwlPetLevel)
  self.Beams[fakeId].NS_Scene_Box_TypeLock:SetActive(true, true)
end

function NPCModule:GetOwlPetLevel(npcId)
  local NpcConf = _G.DataConfigManager:GetNpcConf(npcId, true)
  local PetBaseId = NpcConf and NpcConf.traverse_data_param
  if not PetBaseId then
    return 5
  end
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetBaseId, true)
  local OwlPetLevel = PetBaseConf and PetBaseConf.stage
  if not OwlPetLevel then
    return 5
  end
  if 1 == OwlPetLevel then
    return 5
  elseif 2 == OwlPetLevel then
    return 12
  else
    return 0
  end
  return OwlPetLevel
end

function NPCModule:ShowRevivePointNPCDebugName()
  local World = _G.UE4Helper.GetCurrentWorld()
  for _, n in pairs(self.revivePointNPC) do
    local npc = n
    local name = n.Name
    local areaId = n.AreaId
    if not npc then
    else
      local Dist = npc.squaredDis2Local
      if not Dist then
      else
        local ServerData = npc.serverData
        if not ServerData then
        else
          local Config = npc.config
          if not Config then
          else
            local View = npc.viewObj
            if not View then
            elseif not UE.UObject.IsValid(View) then
            else
              local id = Config.id
              local npc_content_cfg_id = ServerData.npc_base.npc_content_cfg_id
              local debug_string = string.format("%s (%d,%d,%d)", name, id or 0, npc_content_cfg_id or 0, areaId)
              UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, npc.viewObj:Abs_K2_GetActorLocation(), debug_string, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
            end
          end
        end
      end
    end
  end
end

function NPCModule:ShowGMMarkerPointNPCDebugName()
  local World = _G.UE4Helper.GetCurrentWorld()
  for _, n in pairs(self.GMMarkerPointNPC) do
    local npc = n
    local index = _
    local name = n.Name
    if not npc then
    else
      local Dist = npc.squaredDis2Local
      if not Dist then
      else
        local ServerData = npc.serverData
        if not ServerData then
        else
          local Config = npc.config
          if not Config then
          else
            local View = npc.viewObj
            if not View then
            elseif not UE.UObject.IsValid(View) then
            else
              local debug_string = string.format("%s%s", name, index)
              UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, npc.viewObj:Abs_K2_GetActorLocation(), debug_string, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
            end
          end
        end
      end
    end
  end
end

function NPCModule:AddRevivePointNPC(NPC)
  table.insert(self.revivePointNPC, NPC)
end

function NPCModule:ClearRevivePointNPC()
  for i = 1, #self.revivePointNPC do
    self.revivePointNPC[i]:Disappear(true)
  end
  self.revivePointNPC = {}
end

function NPCModule:AddGMMarkerPointNPC(NPC)
  _G.GlobalConfig.bShouldShowGMMarkerPointInfo = true
  table.insert(self.GMMarkerPointNPC, NPC)
end

function NPCModule:ClearGMMarkerPointNPC()
  for i = 1, #self.GMMarkerPointNPC do
    self.GMMarkerPointNPC[i]:Disappear(true)
  end
  self.GMMarkerPointNPC = {}
  _G.GlobalConfig.bShouldShowGMMarkerPointInfo = false
end

function NPCModule:GetDistance2D(pos1, pos2)
  local deltaX = pos1.X - pos2.X
  local deltaY = pos1.Y - pos2.Y
  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function NPCModule:GetDistance3D(pos1, pos2)
  local deltaX = pos1.X - pos2.X
  local deltaY = pos1.Y - pos2.Y
  local deltaZ = pos1.Z - pos2.Z
  return math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
end

function NPCModule:DrawMarkerPointDebugLine()
  if #self.GMMarkerPointNPC > 0 and 1 ~= #self.GMMarkerPointNPC then
    for i = 1, #self.GMMarkerPointNPC do
      if i + 1 <= #self.GMMarkerPointNPC then
        local pos1 = self.GMMarkerPointNPC[i]:GetActorLocation()
        local pos2 = self.GMMarkerPointNPC[i + 1]:GetActorLocation()
        local textPos = UE4.FVector((pos1.X + pos2.X) / 2, (pos1.Y + pos2.Y) / 2, (pos1.Z + pos2.Z) / 2 + 25)
        local redColor = UE.FLinearColor(1.0, 0.0, 0.0, 1.0)
        local distance = self:GetDistance3D(pos1, pos2)
        local horizontalDistance = self:GetDistance2D(pos1, pos2)
        local content = string.format("\228\184\164\231\130\185\231\155\180\231\186\191\232\183\157\231\166\187:%s\n\228\184\164\231\130\185\230\176\180\229\185\179\232\183\157\231\166\187%s", distance, horizontalDistance)
        local line = UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), pos1, pos2, redColor, 0, 2)
        UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), textPos, content, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
      end
    end
  elseif #self.GMMarkerPointNPC > 0 and 1 == #self.GMMarkerPointNPC then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
    local pos1 = self.GMMarkerPointNPC[1]:GetActorLocation()
    local pos2 = playerLocation
    local textPos = UE4.FVector((pos1.X + pos2.X) / 2, (pos1.Y + pos2.Y) / 2, (pos1.Z + pos2.Z) / 2 + 25)
    local redColor = UE.FLinearColor(1.0, 0.0, 0.0, 1.0)
    local distance = self:GetDistance3D(pos1, pos2)
    local horizontalDistance = self:GetDistance2D(pos1, pos2)
    local content = string.format("\228\184\164\231\130\185\231\155\180\231\186\191\232\183\157\231\166\187:%s\n\228\184\164\231\130\185\230\176\180\229\185\179\232\183\157\231\166\187%s", distance, horizontalDistance)
    local line = UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), pos1, pos2, redColor, 0, 2)
    UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), textPos, content, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
  end
end

function NPCModule:GetPlayerPosCache()
  return PlayerPosCache, PlayerForwardsCache
end

function NPCModule:GetPlayerRadiusDiff()
  return PlayerRadiusDiff
end

function NPCModule:GetPlayerInteractStateCache()
  return PlayerInteractState
end

function NPCModule:GetRolePlayBehaviorID()
  return RolePlayBehaviorID
end

function NPCModule:AdjustNPCDistance(npc)
  self._npc2LoadQueue:Adjust(npc)
end

function NPCModule:GetNpcByGroup(group)
  local npcGroup = {}
  for _, v in pairs(self._npcIterDic) do
    if v:GetGroup() == group then
      npcGroup[v:GetGroupIdx()] = v
    end
  end
  return npcGroup
end

function NPCModule:GetNpcByFilter(handler, filterFunc)
  for _, v in pairs(self._npcIterDic) do
    local flag
    if handler then
      flag = filterFunc(handler, v)
    else
      flag = filterFunc(v)
    end
    if flag then
      return v
    end
  end
  return nil
end

function NPCModule:GetNpcsByFilter(handler, filterFunc)
  local ans = {}
  for _, v in pairs(self._npcIterDic) do
    local flag
    if handler then
      flag = filterFunc(handler, v)
    else
      flag = filterFunc(v)
    end
    if flag then
      table.insert(ans, v)
    end
  end
  return ans
end

local function DefaultThrowFilter(npc)
  return npc.InteractionComponent:CanBattle()
end

function NPCModule:GetThrowAimNpcs(handler, filterFunc)
  local ans = {}
  for _, v in pairs(self._npcIterDic) do
    if DefaultThrowFilter(v) then
      local flag = true
      if handler then
        flag = filterFunc(handler, v)
      else
        flag = filterFunc(v)
      end
      if flag then
        table.insert(ans, v)
      end
    end
  end
  return ans
end

function NPCModule:GetNpcByRefreshID(refreshId)
  for _, v in pairs(self._npcIterDic) do
    local rfID = v.serverData.npc_base.npc_content_cfg_id
    if rfID == refreshId then
      return v
    end
  end
  return nil
end

function NPCModule:GetNpcByServerID(serverID)
  return self._npcDic[serverID]
end

function NPCModule:GetNpcByRefreshPoint(RefreshPointID)
  return self._npcContentDic[RefreshPointID]
end

function NPCModule:GetNPCByLogicID(logicID)
  if not logicID or 0 == logicID then
    return nil
  end
  return self._npcLogicDic[logicID]
end

function NPCModule:OnFindNPCByConfigID(configID)
  if not configID then
    return nil
  end
  if 0 == configID then
    return nil
  end
  for _, npc in pairs(self._npcIterDic) do
    if npc and npc.config and npc.config.id == configID then
      return npc
    end
  end
  return nil
end

function NPCModule:OnFindNPCByConfigIDAndUin(configID, CreatorUin)
  if not configID or not CreatorUin then
    return nil
  end
  if 0 == configID or 0 == CreatorUin then
    return nil
  end
  for _, npc in pairs(self._npcIterDic) do
    if npc and npc.config and npc.config.id == configID and npc.serverData.npc_base.create_avatar_id == CreatorUin then
      return npc
    end
  end
  return nil
end

function NPCModule:GetAllNPC()
  return self._npcDic
end

function NPCModule:GetAllNPCInIter()
  return self._npcIterDic
end

local HUD_POOL_SIZE_LIMIT = 30

function NPCModule:PreCreateHudClass(poolType, creator)
  local hudPool = self:GetOrCreateSubHudPool(poolType)
  if hudPool and creator then
    local createNum = HUD_POOL_SIZE_LIMIT - hudPool:Count()
    for i = 1, createNum do
      local inst = creator()
      if inst and UE4.UObject.IsValid(inst) then
        hudPool:Recycle(inst)
      end
    end
  end
end

function NPCModule:GetOrCreateSubHudPool(poolType)
  if not _G.GlobalConfig.EnableHudPool then
    return
  end
  if poolType and self.subHudPools then
    local _umgPool = self.subHudPools[poolType]
    if not _umgPool then
      _umgPool = InstancePool(poolType, nil, 0)
      self.subHudPools[poolType] = _umgPool
    end
    return _umgPool
  end
end

function NPCModule:GetHudFromPool(poolType)
  local hudPool = self:GetOrCreateSubHudPool(poolType)
  if hudPool then
    return hudPool:Get()
  end
end

function NPCModule:ReturnHudToPool(poolType, inst)
  local hudPool = self:GetOrCreateSubHudPool(poolType)
  if hudPool and hudPool:Count() <= HUD_POOL_SIZE_LIMIT and inst and UE4.UObject.IsValid(inst) then
    hudPool:Recycle(inst)
  end
end

function NPCModule:DebugNPCMemInfo(instanceDetail, actorDetail, packageDetail)
  if nil == instanceDetail then
    instanceDetail = false
  end
  if nil == actorDetail then
    actorDetail = false
  end
  if nil == packageDetail then
    packageDetail = false
  end
  local npcs = self._npcDic
  if not npcs then
    return
  end
  local packageMap = {}
  local bpActorMap = {}
  self:Log("------------------------------------------------------")
  self:Log("NPC\232\147\157\229\155\190\228\184\142Package\229\134\133\229\173\152,\230\179\168\230\132\143\228\184\141\229\140\133\230\139\172\232\180\180\229\155\190\227\128\129Mesh\227\128\129\229\138\168\231\148\187\231\173\137\232\181\132\230\186\144\229\134\133\229\173\152(\228\184\141\232\191\135\231\178\146\229\173\144\229\155\160\228\184\186\232\174\161\231\174\151\230\150\185\229\188\143\233\151\174\233\162\152\231\155\174\229\137\141\232\178\140\228\188\188\230\152\175\229\140\133\230\139\172\231\154\132\239\188\140\229\133\183\228\189\147\229\156\168\230\159\165\239\188\140\232\175\166\232\167\129iwiki")
  self:Log("Pacakge\230\149\176\233\135\143\229\143\175\228\187\163\232\161\168NPC\231\167\141\231\177\187\230\149\176\233\135\143\239\188\140BP Actor\228\184\186\229\174\158\228\190\139\228\184\170\230\149\176")
  if instanceDetail then
    self:Log("NPC Memory Summary")
  end
  for _, npc in pairs(npcs) do
    if npc.viewObj then
      local outObj, objName, OutObjName, objSize, outObjSize = UE4.UNRCStatics.GetUObjectInfo(npc.viewObj)
      if instanceDetail then
        self:Log(npc.config.name, objName, OutObjName, outObj, tostring(objSize / 1024) .. "kb", tostring(outObjSize / 1024) .. "kb")
      end
      packageMap[outObj] = outObjSize / 1024
      bpActorMap[npc.viewObj] = objSize / 1024
    end
  end
  local counter = PriorityQueue()
  self:Log("NPC BP Actor Summary")
  local actorSum = 0
  local actorNum = 0
  local actorMedian = 0
  for obj, size in pairs(bpActorMap) do
    if actorDetail then
      local log = UE4.UNRCStatics.PrintObject(obj)
      self:Log(log)
    end
    actorSum = actorSum + size
    actorNum = actorNum + 1
    if counter:Size() < math.ceil(actorNum / 2) then
      counter:EnQueue(size)
    elseif size > counter:GetTop() then
      counter:DeQueue()
      counter:EnQueue(size)
    end
    actorMedian = counter:GetTop()
  end
  self:Log("BP Actor Sum: ", tostring(actorSum) .. "kb", tostring(actorSum / 1024) .. "mb", "num:" .. tostring(actorNum), "median:" .. tostring(actorMedian) .. "kb", "average:" .. tostring(actorSum / actorNum) .. "kb")
  self:Log("\232\167\134\233\135\142\229\134\133(\229\183\178\231\187\143OnFrameLoad\229\138\160\232\189\189\232\181\132\230\186\144)\239\188\154")
  self:Log("\232\167\134\233\135\142\229\164\150(\231\169\186BP\229\141\160\231\148\168)\239\188\154")
  self:Log("NPC Package Summary")
  local packageSum = 0
  local packageNum = 0
  local packageMedian = 0
  counter:Clear()
  for outObj, size in pairs(packageMap) do
    if packageDetail then
      local log = UE4.UNRCStatics.PrintObject(outObj)
      self:Log(log)
    end
    packageSum = packageSum + size
    packageNum = packageNum + 1
    if counter:Size() < math.ceil(packageNum / 2) then
      counter:EnQueue(size)
    elseif size > counter:GetTop() then
      counter:DeQueue()
      counter:EnQueue(size)
    end
    packageMedian = counter:GetTop()
  end
  self:Log("Package Sum: ", tostring(packageSum) .. "kb", tostring(packageSum / 1024) .. "mb", "num:" .. tostring(packageNum), "median:" .. tostring(packageMedian) .. "kb", "average:" .. tostring(packageSum / packageNum) .. "kb")
  self:Log("------------------------------------------------------")
end

function NPCModule:AddMonitorByConfID(id)
  self.MonitorNPCByConfID[id] = true
end

function NPCModule:AddMonitorByServerID(id)
  self.MonitorNPCByServerID[id] = true
end

function NPCModule:ClearMonitor()
  self.MonitorNPCByConfID = {}
  self.MonitorNPCByServerID = {}
end

function NPCModule:IsMonitor(serverID, confID)
  return self.MonitorNPCByServerID[serverID] or self.MonitorNPCByConfID[confID]
end

function NPCModule:GetPosInNav(pos, size, height)
  pos.Z = pos.Z + 100
  size = size or 100
  height = height or 7000
  local QueryExtent = UE4.FVector(size, size, height)
  local ProjectedLocation, resValue = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), pos, nil, nil, nil, QueryExtent)
  if resValue then
    return ProjectedLocation, true
  end
  return pos, false
end

function NPCModule:OnClientOperation(rsp)
  local npc = self:GetNpcByServerID(rsp.operation.operator_id)
  if npc then
    local Comp = npc:EnsureComponent(SyncPetActionComponent)
    Comp:DealClientOperation(rsp.operation)
  end
end

function NPCModule:ShowThrowSessionManager()
  if _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.ShowTable, self.ThrowSessionManager, "NPC Options")
  end
end

function NPCModule:DeleteThrowBallById(owner_id, throw_id)
  self.ThrowSessionManager:DeleteThrowBallById(owner_id, throw_id)
end

function NPCModule:GetThrowBallById(src_id, throw_id)
  return self.ThrowSessionManager:GetBall(src_id, throw_id)
end

function NPCModule:RecycleAllThrowPets(Reason)
  local ActivePetSessions = ThrowSession.ActivePetSessions
  if ActivePetSessions then
    for i = #ActivePetSessions, 1, -1 do
      ActivePetSessions[i]:ForceRecycle(Reason)
    end
  end
end

function NPCModule:GetMapRegionArea(areaId)
  return self.MapRegionAreaUtil:GetMapArea(areaId)
end

function NPCModule:UpdateCatchGuaranteeRateInfo(action)
  local npc = self._npcDic[action.actor_id]
  if npc then
    npc.serverData.npc_base.catch_guarantee_rate = action.catch_guarantee_rate
    npc.serverData.npc_base.last_catch_time = action.last_catch_time
  end
end

function NPCModule:OnHomePetSvrInfoChange(action, tag, baseData)
  local npc = self._npcDic[baseData.operator_obj_id]
  if npc then
    npc.serverData.home_pet = action.home_pet
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnHomePetInfoChanged, action.home_pet)
    if BigMapModuleCmd then
      if action.action_type == _G.ProtoEnum.SpaceActionType.ENUM.HomePetAwardProcuced then
        _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, npc.serverData, _G.Enum.MapModuleDataUpdateReason.HOME_PET_REFRESH_PRODUCTION)
      elseif action.action_type == _G.ProtoEnum.SpaceActionType.ENUM.HomePetAwardComsumed then
        if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InLocalMasterIndoor() then
          _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, npc.serverData, _G.Enum.MapModuleDataUpdateReason.HOME_PET_CLEAR_PRODUCTION)
        elseif _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor() then
          _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetHomePetNpcData, npc.serverData, _G.Enum.MapModuleDataUpdateReason.HOME_PET_REFRESH_PRODUCTION)
        end
      end
    end
  end
end

function NPCModule:ChangeLoopAction(action)
  local sceneNpc = self:GetNpcByServerID(action.actor_id)
  if sceneNpc then
    sceneNpc:SetLoopAction(action.new_loop_action)
  end
end

function NPCModule:ChangeBattleBuff(action)
  local sceneNpc = self:GetNpcByServerID(action.actor_id)
  if sceneNpc then
    sceneNpc:SetBuffInfoAction(action.buff_info)
  end
end

function NPCModule:OnWorldCombatEnter()
  local AllPets = self:GetNpcsByFilter(nil, function(Iter)
    local NPC = Iter
    if NPC.serverData and NPC.serverData.base and NPC.serverData.base.detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet and NPC.IsAThrownPet and NPC:IsAThrownPet() then
      return true
    else
      return false
    end
  end)
  for _, Pet in pairs(AllPets) do
    Pet:SetHitedComponent(true)
  end
end

function NPCModule:OnWorldCombatExit()
  local AllPets = self:GetNpcsByFilter(nil, function(Iter)
    local NPC = Iter
    if NPC.serverData and NPC.serverData.base and NPC.serverData.base.detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet and NPC.IsAThrownPet and NPC:IsAThrownPet() then
      return true
    else
      return false
    end
  end)
  for _, Pet in pairs(AllPets) do
    Pet:SetHitedComponent(false)
  end
end

function NPCModule:GetPlayerInteractState(LocalPlayer)
  local PlayerState = Enum.LocationInteractionBanType.STA_BEGIN
  local StatusComponent = LocalPlayer.statusComponent
  if not StatusComponent then
    return PlayerState
  end
  if StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED) then
    PlayerState = Enum.LocationInteractionBanType.STA_LAND
  elseif StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
    PlayerState = Enum.LocationInteractionBanType.STA_SWIM
  elseif StatusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING) then
    PlayerState = Enum.LocationInteractionBanType.STA_JUMP_AND_FALL
  elseif StatusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB, ProtoEnum.WorldPlayerStatusType.WPST_SLIDING, ProtoEnum.WorldPlayerStatusType.WPST_MANTLE) then
    PlayerState = Enum.LocationInteractionBanType.STA_CLIMB
  elseif StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    local RideComponent = LocalPlayer.viewObj.BP_RideComponent
    if RideComponent then
      local RidePet = RideComponent.RidePet
      if RidePet then
        local RideMovement = RidePet.CharacterMovement.MovementMode
        if RideMovement == UE.EMovementMode.MOVE_Walking then
          PlayerState = Enum.LocationInteractionBanType.STA_LAND_RIDE
        elseif RideMovement == UE.EMovementMode.MOVE_Swimming then
          PlayerState = Enum.LocationInteractionBanType.STA_WATER_RIDE
        elseif RideMovement == UE.EMovementMode.MOVE_Flying or RideMovement == UE.EMovementMode.MOVE_Falling or RideMovement == UE.EMovementMode.MOVE_Custom and RidePet.CharacterMovement.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Gliding then
          PlayerState = Enum.LocationInteractionBanType.STA_FLY_RIDE
        elseif RideMovement == UE.EMovementMode.MOVE_Custom and RidePet.CharacterMovement.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Climbing then
          PlayerState = Enum.LocationInteractionBanType.STA_CLIMB_RIDE
        end
      end
    end
  elseif StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) and StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    PlayerState = Enum.LocationInteractionBanType.STA_CLIMB_RIDE
  end
  return PlayerState
end

function NPCModule:NotifyBeginActionParams(Action, Tag, Data)
  local Npc = self._npcDic[Action.npc_id]
  if Npc and Npc.InteractionComponent then
    Npc.InteractionComponent:NotifyBeginActionParams(Action, Tag, Data)
  end
end

function NPCModule:TryAddPlayerPet(actor)
  local gid = actor.pet_info and actor.pet_info.gid
  if not gid then
    return
  end
  local owner_id = actor.base and actor.base.owner_id
  if not owner_id then
    return
  end
  if not self.playerPetMap[owner_id] then
    self.playerPetMap[owner_id] = {}
  end
  local actor_id = actor.base and actor.base.actor_id
  if not actor_id then
    return
  end
  local petMap = self.playerPetMap[owner_id]
  if not table.contains(petMap, actor_id) then
    table.insert(petMap, actor_id)
    self.totalPlayerPetNum = self.totalPlayerPetNum + 1
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnPlayerPetNumChanged, self.totalPlayerPetNum)
  end
end

function NPCModule:TryRemovePlayerPet(actor)
  local gid = actor.pet_info and actor.pet_info.gid
  if not gid then
    return
  end
  local owner_id = actor.base and actor.base.owner_id
  if not owner_id then
    return
  end
  if not self.playerPetMap[owner_id] then
    return
  end
  local actor_id = actor.base and actor.base.actor_id
  if not actor_id then
    return
  end
  local petMap = self.playerPetMap[owner_id]
  if table.contains(petMap, actor_id) then
    table.removeValue(petMap, actor_id)
    self.totalPlayerPetNum = self.totalPlayerPetNum - 1
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnPlayerPetNumChanged, self.totalPlayerPetNum)
  end
  if table.isEmpty(petMap) then
    self.playerPetMap[owner_id] = nil
  end
end

function NPCModule:GetPetByPlayer(player_id)
  return self.playerPetMap[player_id] or {}
end

function NPCModule:GetTotalPlayerPetNum()
  return self.totalPlayerPetNum
end

function NPCModule:OnPetNameChange(Action, Tag, BaseData)
  local npc = self:GetNpcByServerID(Action.actor_id)
  if not npc then
    return
  end
  npc.serverData.base.name = Action.name
  local InterComp = npc:EnsureComponent(InteractionComponent)
  InterComp:OnOptionsChange(Action, Tag, BaseData)
  self:CheckRenameEasterEgg(Action.name, npc)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnPetInfoChangeEvent)
end

function NPCModule:CheckRenameEasterEgg(new_name, npc)
  if nil == new_name then
    return
  end
  if "" == new_name then
    return
  end
  if nil == npc then
    return
  end
  if nil == npc.viewObj then
    return
  end
  if npc.serverData and npc.serverData.pet_info then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(npc.serverData.pet_info.gid)
    if PetData then
      local PetConfId = PetData.conf_id
      local PetConf = _G.DataConfigManager:GetPetConf(PetConfId)
      if PetConf and PetConf.need_name and "" ~= PetConf.need_name and new_name == PetConf.need_name then
        local PetSceneSkillPath = PetConf.world_anim
        if PetSceneSkillPath then
          local SkillComp = npc.viewObj:GetComponentByClass(UE.URocoSkillComponent)
          local SkillObj = RocoSkillProxy.Create(PetSceneSkillPath, SkillComp, PriorityEnum.Active_Throw_Pet)
          if SkillObj then
            SkillObj:SetCaster(npc.viewObj)
            SkillObj:PlaySkill()
          end
        end
      end
    end
  end
end

function NPCModule:ReqControlNpc(RefreshContentId, ControllableNpcOpType, Point, RspDelegate, ServerId, SkinId)
  local Req = ProtoMessage:newZoneSceneNpcControlReq()
  Req.content_id = RefreshContentId
  Req.operate_type = ControllableNpcOpType
  Req.point = Point
  Req.npc_id = ServerId
  Req.skin_id = SkinId
  Log.Info("[NPC] ReqControlNpc", RefreshContentId, ControllableNpcOpType, Point, RspDelegate, ServerId)
  local rspWrapper = {}
  rspWrapper.handler = _G.MakeWeakFunctor(self, self.OnNpcControlRsp)
  rspWrapper.reqMsg = Req
  rspWrapper.rsp_delegate = RspDelegate
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    if _rspWrapper then
      _rspWrapper.handler(_protoData, _rspWrapper.reqMsg, _rspWrapper.rsp_delegate)
    end
  end
  
  local Success = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_CONTROL_REQ, Req, rspWrapper, OnSvrRspHandle)
  if not Success and RspDelegate then
    RspDelegate(Req, nil)
  end
end

function NPCModule:OnNpcControlRsp(Rsp, Req, RspDelegate)
  local bSuccess = 0 == Rsp.ret_info.ret_code
  if not bSuccess then
    Log.Error("NPCModule:OnNpcControlRsp Failed!", Rsp.ret_info.ret_code, Rsp.ret_info.ret_msg)
  end
  if RspDelegate then
    RspDelegate(Req, Rsp)
  end
end

local PCT_DUNGEON_TYPES = {
  Enum.PlayerConditionType.PCT_DUNGEON,
  Enum.PlayerConditionType.PCT_DUNGEON_SHADOW,
  Enum.PlayerConditionType.PCT_HOME_PLANT
}

function NPCModule:CanAutoCollect(Player)
  if SceneUtils.debugDisableAutoCollect then
    return false
  end
  local IsOwner = _G.DataModelMgr.PlayerDataModel:IsCurrentWorldOwner()
  if not IsOwner then
    return false
  end
  if NpcOption:NeedStatusNotify() then
    return false
  end
  if not Player then
    return false
  end
  local HasConditionOtherThanDungeon = _G.FunctionBanManager:HasConditionsOtherThan(PCT_DUNGEON_TYPES)
  if HasConditionOtherThanDungeon then
    return false
  end
  local InputComp = Player.inputComponent
  if not InputComp:GetInputEnable() then
    return false
  end
  local HasBlocker = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.HasInputBlocker)
  if HasBlocker then
    return false
  end
  if Player.statusComponent and Player.statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
    return false
  end
  return true
end

function NPCModule:GetTopKNpcInCpp(num, maxDistance)
  local npcIds = UE4.URocoPlayerBlueprintFunctionLibrary.GetTopKNearestNpc(_G.UE4Helper.GetCurrentWorld(), num or 5, maxDistance or 1000.0, self._npcDic)
  local topK = {}
  for _, index in tpairs(npcIds) do
    local npc = self._npcDic[index]
    if nil ~= npc then
      table.insert(topK, npc)
    end
  end
  return topK
end

function NPCModule:CheckPlayerShowPet(playerId, bHide)
  if not playerId then
    return
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    return
  end
  local playerPets = self:GetNpcsByFilter(nil, function(NPC)
    if NPC.serverData and NPC.serverData.base and NPC.serverData.base.detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet and NPC.serverData.pet_info ~= nil and 0 ~= NPC.serverData.pet_info.gid then
      return NPC.serverData.base.owner_id == playerId
    else
      return false
    end
  end)
  if bHide then
    for _, pet in pairs(playerPets) do
      if pet.visibility then
        local curShowPet = pet
        curShowPet:SetVisiblePetNumLimitReason(false)
        return
      end
    end
  else
    table.sort(playerPets, function(a, b)
      return a.serverData.base.born_time > b.serverData.base.born_time
    end)
    if #playerPets > 0 then
      local shouldShowPet = playerPets[1]
      shouldShowPet:SetVisiblePetNumLimitReason(true)
    end
  end
end

function NPCModule:ShowOwnPetByPlayerId(playerId, bShow, reason)
  if not playerId then
    return
  end
  local playerPets = self:GetNpcsByFilter(nil, function(NPC)
    if NPC.serverData and NPC.serverData.base and NPC.serverData.base.detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet and NPC.serverData.pet_info ~= nil and 0 ~= NPC.serverData.pet_info.gid then
      return NPC.serverData.base.owner_id == playerId
    else
      return false
    end
  end)
  for _, pet in pairs(playerPets) do
    pet:SetVisibleForReason(bShow, reason)
  end
end

function NPCModule:OnNpcOptionNotify(Action, Tag, BaseData)
  if not Action then
    return
  end
  local npc = self._npcDic[Action.npc_id]
  if npc then
    npc:SendEvent(NPCModuleEvent.OptActionNotify, npc, Action)
    if Action.action_type == Enum.ActionType.ACT_SIT or Action.action_type == Enum.ActionType.ACT_HOME_SIT_LIE then
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, BaseData.operator_obj_id)
      if Player and Player.playerToyComponent then
        Player.playerToyComponent:OnSeatNPCNotify(npc, Action)
      end
    end
  end
end

function NPCModule:SortActors(Actors)
  table.clear(self.InitialActorIDs)
  local TrackedNPCs = {}
  local MapTrackedNPCInfo
  if _G.BigMapModuleCmd then
    MapTrackedNPCInfo = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetMapTraceItemData, BigMapModuleEnum.TraceType.NPC)
  end
  local LargeNPCs = {}
  local NearNPCs = {}
  local OtherActors = {}
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local platform_actor_id = Player.serverData.base.platform_actor_id or 0
  for _, v in ipairs(Actors) do
    local actorInfo = v
    if actorInfo.npc and actorInfo.npc.npc_base then
      local serverData = actorInfo.npc
      local npcBase = actorInfo.npc.npc_base
      local npc_content_cfg_id = npcBase.npc_content_cfg_id
      local contentConf = _G.DataConfigManager:GetNpcRefreshContentConf(npc_content_cfg_id, true)
      if contentConf and contentConf.refresh_rule == Enum.RefreshRuleConf.RRC_TASK_NO_RESET then
        table.insert(TrackedNPCs, actorInfo)
      elseif MapTrackedNPCInfo and MapTrackedNPCInfo.npcInfo and MapTrackedNPCInfo.npcInfo.npc_refresh_id and MapTrackedNPCInfo.npcInfo.npc_refresh_id == npc_content_cfg_id then
        table.insert(TrackedNPCs, actorInfo)
      elseif 0 ~= platform_actor_id and platform_actor_id == serverData.base.actor_id then
        table.insert(TrackedNPCs, actorInfo)
      else
        local npcConf = _G.DataConfigManager:GetNpcConf(npcBase.npc_cfg_id)
        local modelConf
        if npcConf then
          modelConf = _G.DataConfigManager:GetModelConf(npcConf.model_conf)
        end
        
        local function GetNpcRefreshScale()
          if not contentConf then
            return 1
          end
          return math.clamp((contentConf.model_scale or 100) / 100, 0.001, 100.0)
        end
        
        local function GetNpcFarmScale()
          if not (serverData and serverData.npc_base and serverData.npc_base.home_plant_land_id) or 0 == serverData.npc_base.home_plant_land_id then
            return 1
          end
          local land_id = serverData.npc_base.home_plant_land_id
          if not FarmUtils.IsLandHarvest(land_id) then
            return 1
          end
          local plantGrowConf = FarmUtils.GetPlantGrowConfByLandId(land_id)
          if not plantGrowConf then
            return 1
          end
          local landInfo = FarmUtils.GetLandInfo(land_id)
          if not landInfo then
            return 1
          end
          local growGrade = plantGrowConf.plant_grow_grade[landInfo.plant_tab_id]
          return math.clamp((growGrade.model_scale or 100) / 100, 0.001, 100.0)
        end
        
        local function GetConfigScale()
          local scale1 = math.clamp((modelConf.model_scale or 100) / 100, 0.001, 100.0)
          local scale2 = math.clamp((npcConf.model_scale or 100) / 100, 0.001, 100.0)
          local scale3 = GetNpcRefreshScale()
          local scale4 = GetNpcFarmScale()
          local scale = scale1 * scale2 * scale3 * scale4
          return scale
        end
        
        local function GetBodySize()
          if not npcConf then
            return 500
          end
          local Scale = GetConfigScale()
          local Radius = (modelConf.capsule_radius or 1000) / 1000
          local HalfHeight = (modelConf.capsule_halfheight or 1000) / 1000
          local Volume = Radius * Radius * HalfHeight * Scale * Scale * Scale * 8.0E-6
          return Volume
        end
        
        local function IsOverSized()
          if npcConf.BulkySizeType >= UE4.EBodySizeType.Large then
            return true
          end
          local Volume = GetBodySize()
          local BodySizeType = NPCBaseCommon.ConvertVolumeToBodySizeType(Volume)
          return BodySizeType >= UE4.EBodySizeType.Large
        end
        
        if npcConf and modelConf and IsOverSized() then
          table.insert(LargeNPCs, actorInfo)
        else
          local PlayerPos = Player.serverData.base.pt.pos
          local npcPos = serverData.base.pt.pos
          
          local function Dist(P1, P2)
            local X = P1.x - P2.x
            local Y = P1.y - P2.y
            local Z = P1.z - P2.z
            return X * X + Y * Y + Z * Z
          end
          
          local distance = Dist(PlayerPos, npcPos)
          local force_load_distance = 1000
          if distance <= force_load_distance then
            table.insert(NearNPCs, actorInfo)
          else
            table.insert(OtherActors, actorInfo)
          end
        end
      end
    else
      table.insert(OtherActors, actorInfo)
    end
  end
  SceneUtils.SortActorsByDistanceToPlayer(TrackedNPCs, Player.serverData.base.pt.pos)
  SceneUtils.SortActorsByDistanceToPlayer(LargeNPCs, Player.serverData.base.pt.pos)
  SceneUtils.SortActorsByDistanceToPlayer(NearNPCs, Player.serverData.base.pt.pos)
  SceneUtils.SortActorsByDistanceToPlayer(OtherActors, Player.serverData.base.pt.pos)
  local NewActors = {}
  for _, v in ipairs(TrackedNPCs) do
    table.insert(NewActors, v)
  end
  for _, v in ipairs(LargeNPCs) do
    table.insert(NewActors, v)
  end
  for _, v in ipairs(NearNPCs) do
    table.insert(NewActors, v)
  end
  for _, v in ipairs(OtherActors) do
    table.insert(NewActors, v)
  end
  local NewActorsSize = #NewActors
  Log.DebugFormat("[NpcAOI] waiting SortActos: TrackedNPCs(%d), LargeNPCs(%d), NearNPCs(%d), OtherActors(%d)", #TrackedNPCs, #LargeNPCs, #NearNPCs, #OtherActors)
  for i = 1, self.MAX_NUM_OF_MOST_IMPORTANT_NPC do
    if NewActorsSize < i then
      break
    end
    local actorInfo = NewActors[i]
    if actorInfo and actorInfo.npc then
      local ID = actorInfo.npc.base.actor_id
      table.insert(self.InitialActorIDs, ID)
      if _G.RocoEnv.IS_EDITOR then
        local waitingReason = "Normal"
        if i < #TrackedNPCs then
          waitingReason = "TrackedNPC"
        elseif i < #TrackedNPCs + #LargeNPCs then
          waitingReason = "LargeNPC"
        elseif i < #TrackedNPCs + #LargeNPCs + #NearNPCs then
          waitingReason = "NearNPC"
        end
        Log.Debug("[NpcAOI] waiting for InitialActor:", ID, NewActors[i].npc.npc_base.npc_content_cfg_id, NewActors[i].npc.base.name, waitingReason)
      end
    end
  end
  return NewActors
end

function NPCModule:IsInInitialActorIDs(actorId)
  for _, v in ipairs(self.InitialActorIDs) do
    if v == actorId then
      return true
    end
  end
  return false
end

function NPCModule:OnCmdCreateAllBall(ballId)
  self:GetBallClass(ballId)
end

function NPCModule:ThrowCatchNotify(notify)
  Log.Debug(string.format("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: NPCModule:ThrowCatchNotify %d %d %d %d", notify.is_catch and 1 or 0, notify.is_catch_success and 1 or 0, notify.throw_id or 0, notify.caster_id or 0))
  if notify.is_catch then
    local local_caster_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    local is_local = local_caster_id == notify.caster_id
    local throw_ball = self:GetThrowBallById(notify.caster_id, notify.throw_id)
    local npc = self:GetNpcByServerID(notify.npc_id)
    if not npc then
      Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: Cannot get pet being caught in BornDieComponent:OnBeginDying! npc id: ", string.format("%u", notify.npc_id))
      if throw_ball and throw_ball.viewObj then
        throw_ball.viewObj:ThrowRecycle()
      end
      _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEndWithoutCondition, notify.caster_id or 0)
      if is_local then
        ThrowSession.RawSendCatchFinish(notify.throw_id)
      end
      return
    end
    if not throw_ball then
      Log.Error("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \229\146\149\229\153\156\231\144\131\228\184\141\232\167\129\228\186\134\239\188\140\230\141\149\230\141\137\232\161\168\230\188\148\228\190\157\232\181\150\229\146\149\229\153\156\231\144\131\229\173\152\229\156\168\239\188\140\230\148\190\229\188\131\230\141\149\230\141\137\232\161\168\230\188\148\239\188\140\231\155\180\230\142\165\231\148\168\231\187\147\230\158\156")
      npc:SetNotDestroyFlag(false)
      _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEndWithoutCondition, notify.caster_id or 0)
      if is_local then
        ThrowSession.RawSendCatchFinish(notify.throw_id)
      end
      return
    end
    if npc:IsHidden() then
      Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \231\178\190\231\129\181\232\162\171\233\154\144\232\151\143\228\186\134\239\188\140\230\148\190\229\188\131\230\141\149\230\141\137\232\161\168\230\188\148\239\188\140\231\155\180\230\142\165\231\148\168\231\187\147\230\158\156")
      npc:SetNotDestroyFlag(false)
      _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.CatchEndWithoutCondition, notify.caster_id or 0)
      if throw_ball.ThrowSession then
        throw_ball.ThrowSession:SendCatchFinishReq()
      elseif is_local then
        ThrowSession.RawSendCatchFinish(notify.throw_id)
      end
      local throw_ball_view = throw_ball.viewObj
      if throw_ball_view then
        throw_ball_view:RemoveItem()
      else
        throw_ball:Destroy()
      end
      return
    end
    npc:SetNotDestroyFlag(true)
    local isSuccess = notify.is_catch_success
    Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: PlayCaughtSkill", notify.throw_id or 0)
    local throw_ball_view = throw_ball.viewObj
    if throw_ball_view and throw_ball_view.StopMovement then
      throw_ball_view:StopMovement()
    end
    throw_ball:EnsureComponent(CatchPetComponent):PlayCaughtSkill(throw_ball, npc, isSuccess, notify.shake_times, notify.is_tech_satisfied, nil, notify.glass_info, notify.is_quick_catch)
  else
    local throw_ball = self:GetThrowBallById(notify.caster_id, notify.throw_id)
    if not throw_ball then
      Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \230\137\190\228\184\141\229\136\176\229\146\149\229\153\156\231\144\131\239\188\140\229\143\175\232\131\189\230\152\175\229\183\178\231\187\143\232\162\171\229\136\160\228\186\134", notify.throw_id or 0)
      return
    end
    local player_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    if throw_ball.ThrowSession and throw_ball.ThrowSession:HasPet(true) then
      if notify.caster_id == player_id then
        Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \232\135\170\229\183\177\231\154\132\229\146\149\229\153\156\231\144\131\232\135\170\229\183\177\229\164\132\231\144\134", notify.throw_id or 0)
        return
      end
      if notify.is_create_pet_npc then
        Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \232\191\153\228\184\170\231\144\131\229\136\155\229\187\186\229\135\186\228\186\134\228\184\128\229\143\170\231\178\190\231\129\181\239\188\140\231\173\137\232\191\153\228\184\170\231\178\190\231\129\181\231\154\132\229\136\155\229\187\186", notify.throw_id or 0)
        local ballView = throw_ball.viewObj
        if ballView and ballView.QuickOverdue then
          ballView:QuickOverdue()
        end
        return
      end
    end
    if throw_ball.viewObj then
      Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: ThrowRecycle", notify.throw_id or 0)
      throw_ball.viewObj:ThrowRecycle()
    else
      local throwSession = throw_ball.ThrowSession
      Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \230\178\161\230\156\137viewObject\239\188\140\233\130\163\229\176\177\229\143\170\232\174\190\231\189\174\230\136\144Destroy\229\144\167\239\188\140\228\184\141\229\186\148\232\175\165\230\178\161\230\156\137", notify.throw_id or 0)
      if throwSession then
        throwSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
      end
    end
  end
end

function NPCModule:SetDiePetForFriendRideMap(actor_id, value)
  if nil == actor_id then
    return
  end
  if nil == self.DiePetForFriendRideMap then
    self.DiePetForFriendRideMap = {}
  end
  self.DiePetForFriendRideMap[actor_id] = value
end

function NPCModule:GetPetIsDieForFriendRide(actor_id)
  if self.DiePetForFriendRideMap == nil then
    return false
  end
  if nil == actor_id then
    return false
  end
  return self.DiePetForFriendRideMap[actor_id]
end

function NPCModule:CreateVirtualHomeNPC(ServerData)
  local ConfigID = ServerData.npc_base.npc_cfg_id
  local NPCConf = _G.DataConfigManager:GetNpcConf(ConfigID)
  if not NPCConf then
    Log.Error("HomeNPC\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\154", ConfigID)
    Log.Dump(ServerData)
    return
  end
  local NPC = HomeSceneNPC(self, ServerData.attach_item_info.attach_item_id)
  NPC:InitWithNpcInfo(ServerData)
  NPC.config = NPCConf
  NPC.modelConf = _G.DataConfigManager:GetModelConf(NPCConf.model_conf)
  NPC:CreateLuaObj()
  NPC:CreateView()
  self:InternalAddNPC(ServerData, NPC)
  self._npc2LoadQueue:EnQueue(NPC)
  return NPC
end

function NPCModule:OnFurnitureViewEnter(FurnitureID, View)
  if not self.FurnitureView[FurnitureID] then
    self.FurnitureView[FurnitureID] = View
    local NPC = self.FurnitureNPC[FurnitureID]
    if NPC and not NPC.viewObj then
      NPC:CreateView()
    end
  end
end

function NPCModule:OnFurnitureViewLeave(FurnitureID)
  local View = self.FurnitureView[FurnitureID]
  if View then
    self.FurnitureView[FurnitureID] = nil
    if View.sceneCharacter then
      local NPC = View.sceneCharacter
      NPC.viewObj = nil
      NPC.viewObjRef = nil
      NPC.FurnitureID = nil
    end
    View:BindSceneVirtualNPC()
  end
end

function NPCModule:GetFurnitureView(FurnitureID)
  if not FurnitureID then
    return
  end
  return self.FurnitureView[FurnitureID]
end

function NPCModule:GetFurnitureNPC(FurnitureID)
  if not FurnitureID then
    return
  end
  return self.FurnitureNPC[FurnitureID]
end

function NPCModule:OnPetResponseVoice(action, tag, baseData)
  local npc = self:GetNpcByServerID(action.actor_id)
  if not npc then
    return
  end
  local responseComponent = npc:EnsureComponent(PetResponseComponent)
  responseComponent:AddPetResponse()
end

function NPCModule:OnLLMPETSQueryPets(action)
  self.SceneAIManager:LLMPETSQueryPets(action)
end

function NPCModule:OnLLMPETSBehaviorNotify(action)
  self.SceneAIManager:LLMPETSBehaviorNotify(action)
end

function NPCModule:OnLLMPETSDebug(action)
  self.SceneAIManager:LLMPETSDebug(action)
end

function NPCModule:OnNpcSizeScaleChange(action)
  if not (action and action.npc_id) or not action.size_scale then
    return
  end
  local npc = self._npcDic[action.npc_id]
  if npc then
    npc:UpdateSizeScale(action.size_scale)
  end
end

function NPCModule:OnOptionBlacklistAndWhitelist(Action, Tag, BaseData)
  if not Action then
    return
  end
  local NPC = self._npcDic[Action.npc_id]
  if NPC then
    local InterComp = NPC and NPC.InteractionComponent
    if InterComp then
      local Option = InterComp:GetOptionByID(Action.option_id)
      if Option then
        if Action.whitelist_uins then
          Option.optionInfo.whitelist_uins = Action.whitelist_uins
        end
        if Action.blacklist_uins then
          Option.optionInfo.blacklist_uins = Action.blacklist_uins
        end
        InterComp:UpdateByDistance(0)
      end
    end
  end
end

return NPCModule
