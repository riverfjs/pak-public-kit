require("UnLuaEx")
local NpcSkillPlayComponent = require("NewRoco.Modules.Core.NPC.ViewNPCComponent.NpcSkillPlayComponent")
local FallingBeamComponent = require("NewRoco.Modules.Core.NPC.ViewNPCComponent.FallingBeamComponent")
local ExplodeActorComponent = require("NewRoco.Modules.Core.NPC.ViewNPCComponent.ExplodeActorComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleCmd = require("NewRoco.Modules.Core.NPC.NPCModuleCmd")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Delegate = require("Utils.Delegate")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local LuaActionRandomPos = require("NewRoco.AI.BehaviorTree.Actions.LuaActionRandomPos")
local DebugUtils = require("NewRoco.Modules.Core.Scene.Common.DebugUtils")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local NPCBaseCommon = UE.NPCBaseCommon
local tryReFixcoordTotalTime = 7
local ViewNPCBase = NRCClass("ViewNPCBase")

local function SetBit(Value, Bit, On)
  if On then
    return Value | 1 << Bit
  else
    return Value & ~(1 << Bit)
  end
end

function ViewNPCBase:Initialize(Initializer)
  self.sceneCharacter = nil
  if Initializer then
    self.sceneCharacter = Initializer.sceneCharacter
  end
  self.BeamComponent = false
  self.hiddenFlag = self.hiddenFlag or 0
  self.collisionDisableFlag = self.collisionDisableFlag or 0
  self.ShowUnlockDestroyHandler = -1
end

function ViewNPCBase:InitOutScene()
  Log.Error("ViewNPCBase:InitOutScene \230\142\165\229\143\163\229\183\178\231\187\143\229\186\159\229\188\131\239\188\140\232\175\183\232\176\131\230\149\180\232\176\131\231\148\168\231\154\132\229\156\176\230\150\185")
  self:Init()
  self:LuaBeginPlay()
  if self.SyncLoadResources then
    self:ForceVisible()
    local comp = self:GetComponentByClass(UE.USignificanceComponent)
    if comp then
      comp:SelfControlSignificance(true, UE.ESignificanceValue.Highest)
    end
    self.frameLoaded = true
    self:SyncLoadResources(true)
    self:SetActorHiddenInGame(false)
    if self.Inter_LoadResource_Finish then
      self:Inter_LoadResource_Finish()
    end
  else
    self:BlockLoadResource()
  end
  self:OnDistanceOptimize(0, 1, true)
end

function ViewNPCBase:InitOutSceneAsync(CallbackOwner, Callback)
  self:Init()
  self:LuaBeginPlay()
  self:LoadOutSceneAsync(CallbackOwner, Callback)
end

function ViewNPCBase:LoadOutSceneAsync(CallbackOwner, Callback)
  if Callback then
    self.LoadedCallback:Add(CallbackOwner, Callback)
  end
  if not self.NeedLoad then
    return
  end
  if self.SyncLoadResources then
    self.frameLoaded = true
    self:SetActorHiddenInGame(false)
    self:ForceHidden()
    self:ForceVisible()
  end
  self:OnFrameLoad(0)
end

function ViewNPCBase:TriggerLoadResources(CallbackOwner, Callback)
  if not self.SyncLoadResources then
    if Callback then
      Callback(CallbackOwner, self)
    end
    return
  end
  if Callback then
    self.LoadedCallback:Add(CallbackOwner, Callback)
  end
  self:ForceVisible()
end

function ViewNPCBase:SetSelfControlSignificance(SelfControl, Significance)
  local comp = self:GetComponentByClass(UE.USignificanceComponent)
  if comp then
    comp:SelfControlSignificance(SelfControl, Significance)
  end
end

function ViewNPCBase:LuaBeginPlay()
  if self.NeedBeam then
    self.BeamComponent = FallingBeamComponent(self)
  end
  if self.NeedExplode then
    self.ActorEmitter = ExplodeActorComponent()
  end
end

function ViewNPCBase:Show()
  self.ActorEmitter.startPos = self:GetExplodeLocation()
  self.ActorEmitter.angle = 18
  self.ActorEmitter.force = 3500
  self.ActorEmitter:Explode(self.sceneCharacter.luaObj.createdNPC)
  if self.sceneCharacter then
    self.sceneCharacter.luaObj.createdNPC = {}
  end
  if self.ShowUnlockDestroyHandler > 0 then
    _G.DelayManager:CancelDelayById(self.ShowUnlockDestroyHandler)
    self.ShowUnlockDestroyHandler = -1
  end
  self.ShowUnlockDestroyHandler = _G.DelayManager:DelaySeconds(1.5, self.OnUnlockDestroyDelayCallback, self)
end

function ViewNPCBase:OnUnlockDestroyDelayCallback()
  self.ShowUnlockDestroyHandler = -1
  if not self.sceneCharacter then
    return
  end
  self.sceneCharacter:SetNotDestroyFlag(false)
  if not self.sceneCharacter.shouldDestroy then
    return
  end
  local serverId = self.sceneCharacter.serverData.base.actor_id
  _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, serverId)
end

function ViewNPCBase:GetExplodeLocation()
  return self:Abs_K2_GetActorLocation()
end

function ViewNPCBase:SetChildNPC(npcs)
  if not npcs then
    return
  end
  local MyPosition = self.sceneCharacter:GetActorLocation()
  for _, npc in ipairs(npcs) do
    npc.viewObj.forbidFixCoord = false
    npc:SetActorLocation(MyPosition)
    if npc.viewObj then
      SceneUtils.CorrectActorPos(npc.viewObj, true)
      npc.viewObj:PlayBeamEffect()
    end
  end
end

function ViewNPCBase:SetSceneCharacter(sceneCharacter)
  if self.EnableCppTick == nil then
    self.EnableCppTick = true
  end
  if self.sceneCharacter and self.EnableCppTick then
    NPCBaseCommon.BindLuaCharacter(self)
  end
  self.sceneCharacter = sceneCharacter
  if sceneCharacter then
    if self.SetActorId then
      self:SetActorId(sceneCharacter:GetServerId())
    else
    end
    if self.EnableCppTick then
      local BodySize = sceneCharacter.config.BulkySizeType
      local Volume = -1
      if 0 == BodySize then
        Volume = sceneCharacter:GetBodySize()
      end
      NPCBaseCommon.BindLuaCharacter(self, sceneCharacter, 5000, Volume, BodySize)
    end
    sceneCharacter.hiddenFlag = sceneCharacter.hiddenFlag | (self.hiddenFlag or 0)
    sceneCharacter.collisionDisableFlag = sceneCharacter.collisionDisableFlag | (self.collisionDisableFlag or 0)
  elseif UE.UObject.IsValid(self) and self.SetActorId then
    self:SetActorId(0)
  end
  self.hiddenFlag = 0
  self.collisionDisableFlag = 0
end

local getmetatable = _ENV.getmetatable
local setmetatable = _ENV.setmetatable
local SupportedActorClass = UE.UNPCActorInterface

function ViewNPCBase:Init()
  local mt = getmetatable(self)
  setmetatable(self, nil)
  self.createdNPC = {}
  self.createNum = 0
  self.frameLoaded = false
  self.bViewOpt = false
  self.needTick = true
  self.hasResourceToLoad = true
  self.resourceLoading = false
  self.angleVisibleConfig = 0.34
  self.ClassType = "ViewNPCBase"
  self.firstload = false
  self.firstVisible = false
  self.overlapFlag = true
  self.debugWhenNear = false
  self.forbidFixCoord = false
  self.fixcoordFinish = false
  self.tryReFixcoordTime = tryReFixcoordTotalTime
  self.bPlayingEnterPerform = false
  self.hasPet = false
  self.ThrowSession = false
  self.needFixcoord = false
  self.runtimeCreate = false
  self.bSimulatePhysics = nil
  self.LoadedCallback = Delegate()
  self.EnableCppTick = true
  self.NeedLoad = true
  self.NeedBeam = true
  self.NeedExplode = true
  self.PureBlueprint = false
  self.IsFakeNpc = false
  self.bSkipOverlapCheck = false
  self.CachedTopHeight = 0
  self.CachedBotHeight = 0
  self.ShowUnlockDestroyHandler = -1
  setmetatable(self, mt)
  if UE.UObject.IsValid(self) and self:IsA(SupportedActorClass) then
    self:InitNPC()
  end
end

local TempOrigin = UE.FVector(0, 0, 0)
local TempExtend = UE.FVector(0, 0, 0)

function ViewNPCBase:GetBottomAndTop()
  if self.resourceLoading then
    return 0, 0
  end
  if not self.resourceLoaded then
    return 0, 0
  end
  TempOrigin:Set(0, 0, 0)
  TempExtend:Set(0, 0, 0)
  UE.UNRCStatics.GetActorDefaultCollidingBounds(self, TempOrigin, TempExtend)
  return TempOrigin.Z, TempExtend.Z
end

function ViewNPCBase:PlayLockLoopEffect()
end

function ViewNPCBase:PlayUnlockEffect(lockNum)
end

function ViewNPCBase:PlayUnlockLoopEffect()
end

function ViewNPCBase:PlayOptTimesOverEffect(Operator)
end

function ViewNPCBase:GetRealForwardVector()
  return self:GetActorForwardVector()
end

function ViewNPCBase:GetInterPos(playerPos, enableFixType, config_distance, config_rotation, playerRadius)
  Log.Debug("ViewNPCBase:GetInterPos", self:GetDebugInfo(), playerPos, enableFixType, config_distance, config_rotation, playerRadius)
  local npcPos = self:Abs_K2_GetActorLocation()
  npcPos.Z = playerPos.Z
  local forward
  if 3 == enableFixType or 4 == enableFixType then
    forward = self:GetRealForwardVector()
    forward:Normalize()
    forward = UE4.UKismetMathLibrary.RotateAngleAxis(forward, config_rotation, _G.FVectorUp)
  else
    forward = playerPos - npcPos
    forward:Normalize()
  end
  local targetPos = npcPos + forward * config_distance
  targetPos = SceneUtils.GetPosInNearLand(targetPos) or targetPos
  return targetPos
end

function ViewNPCBase:PreNavInter()
end

function ViewNPCBase:OnNavInterFinish(Success)
end

function ViewNPCBase:PlayOptRefreshEffect()
end

function ViewNPCBase:PlayOptTimesOverLoopEffect()
end

function ViewNPCBase:PlayOptTimesValidLoopEffect()
end

function ViewNPCBase:UpdatePotentialEnergy(action)
end

function ViewNPCBase:ShowPotentialEnergy(action)
end

function ViewNPCBase:HidePotentialEnergy()
end

function ViewNPCBase:UpdatePropertyType(action)
end

function ViewNPCBase:ShowPropertyType(action)
end

function ViewNPCBase:HidePropertyType()
end

function ViewNPCBase:LoadLockEffect()
  return nil
end

function ViewNPCBase:ResetLockNum(num)
end

function ViewNPCBase:UpdateData(ServerData, bIsReconnect)
  if self.SetActorId and ServerData and ServerData.base then
    self:SetActorId(ServerData.base.actor_id or 0)
  end
end

function ViewNPCBase:Recycle()
  if self.BeamComponent then
    self.BeamComponent:Destroy()
  end
  if self.ShowUnlockDestroyHandler and self.ShowUnlockDestroyHandler > 0 then
    _G.DelayManager:CancelDelayById(self.ShowUnlockDestroyHandler)
    self.ShowUnlockDestroyHandler = -1
  end
  self:OnDistanceOptimize(100000000, -1, false, 100)
  self:Init()
  if self.DetachRootComponentFromParent then
    self:DetachRootComponentFromParent()
  end
  if self.RecycleNPC then
    self:RecycleNPC()
  end
  self:SetSceneCharacter(nil)
end

local CallingBeginPlay = false

function ViewNPCBase:ReceiveBeginPlay()
  if CallingBeginPlay then
    return
  else
    CallingBeginPlay = true
    if UE.UObject.IsValid(self) then
      self.Overridden.ReceiveBeginPlay(self)
    end
    CallingBeginPlay = false
  end
  if self.bHidden then
    self.hiddenFlag = SetBit(self.hiddenFlag, NPCModuleEnum.NpcReasonFlags.EDITOR_DEFAULT, true)
  end
  if UE4.UObject.IsValid(self) and self.GetPlaceableConfigId then
    self.cachedPlaceableId = self:GetPlaceableConfigId()
    if 0 == self.cachedPlaceableId or self.cachedPlaceableId == nil then
      Log.Debug("Spawned an dynamic URocoPlaceableInterface actor at ", self:Abs_K2_GetActorLocation())
      return
    end
    self.hasResourceToLoad = false
    NRCModuleManager:DoCmd(NPCModuleCmd.PlaceableNpcEnter, self.cachedPlaceableId, self)
  end
end

function ViewNPCBase:ReceiveEndPlay(Reason)
  self.Overridden.ReceiveEndPlay(self, Reason)
  if self.BeamComponent then
    self.BeamComponent:Destroy()
  end
  if self.otherActor then
    self:ReceiveActorEndOverlap(self.otherActor)
  end
  if self.cachedPlaceableId then
    Log.Debug("[PlaceableNpc] ReceiveEndPlay PlaceableId=", self.cachedPlaceableId, self)
    NRCModuleManager:DoCmd(NPCModuleCmd.PlaceableNpcLeave, self.cachedPlaceableId)
  end
end

function ViewNPCBase:SetComponentNeedTick(comp, needTick)
  Log.Warning("ViewNPCBase:SetComponentNeedTick \229\183\178\231\187\143\229\164\177\230\149\136\229\149\166~")
end

function ViewNPCBase:OnResourceLoadFinish()
  if self.Inter_LoadResource_Finish then
    self:Inter_LoadResource_Finish()
  end
  if self.sceneCharacter then
    self.sceneCharacter:AdjustModelOpacity()
    self.sceneCharacter:AdjustModelFresnel()
  end
end

function ViewNPCBase:Inter_LoadResource_Finish()
  if not self.firstload then
    self:OnFirstLoad()
    self.firstload = true
  end
  self.resourceLoaded = true
  self.resourceLoading = false
  self:OnLoadResource()
end

function ViewNPCBase:LoadResource()
  if not self.hasResourceToLoad then
    return
  end
  if not self.resourceLoading then
    self.resourceLoading = true
    self:OnPreLoadResource()
  end
end

function ViewNPCBase:BlockLoadResource()
  if not self.hasResourceToLoad then
    return
  end
  if self.SyncLoadResources then
    self.frameLoaded = true
    self:SyncLoadResources(true)
    self:SetActorHiddenInGame(false)
    if self.Inter_LoadResource_Finish then
      self:Inter_LoadResource_Finish()
    end
    return
  end
  self:OnPreLoadResource()
  if not self.firstload then
    self:OnFirstLoad()
    self.firstload = true
  end
  self.resourceLoaded = true
  self.frameLoaded = true
  self:OnLoadResource()
end

function ViewNPCBase:UnLoadResource()
  if not self.hasResourceToLoad then
    return
  end
  if self.StartLoadResources then
    return
  end
  Log.Debug("ViewNPCBase UnLoadResource:", self.name, self:GetDebugInfo())
  self:OnPreUnLoadResource()
  _G.NRCResourceManager:UnLoadResByCaller(self)
  self:OnUnLoadResource()
  self.resourceLoaded = false
  self.resourceLoading = false
end

function ViewNPCBase:OnPreLoadResource()
end

function ViewNPCBase:OnPreUnLoadResource()
  if self.sceneCharacter then
    self.sceneCharacter:OnPreUnLoadResource()
  end
end

function ViewNPCBase:OnLoadResource()
  if self.sceneCharacter then
    self.sceneCharacter:SendEvent(NPCModuleEvent.VIEW_LOADED, self)
    self.sceneCharacter:OnLoadResource()
  end
  if self.LoadedCallback then
    self.LoadedCallback:Invoke(self)
    self.LoadedCallback:Clear()
  end
end

function ViewNPCBase:OnUnLoadResource()
end

function ViewNPCBase:GetUnLock()
  if self.sceneCharacter then
    return not self.sceneCharacter:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOCKED)
  else
    return true
  end
end

function ViewNPCBase:GetLockTime()
  if not UE.UObject.IsValid(self) then
    return 0
  end
  if not self.sceneCharacter then
    return 0
  end
  local LockComp = self.sceneCharacter.LockIndicatorComponent
  if not LockComp then
    return 0
  end
  if LockComp.GetLockTime then
    return LockComp:GetLockTime()
  else
    Log.Error("ViewNPCBase:GetUnLock LockComp.GetLockTime function is nil")
    return 0
  end
end

function ViewNPCBase:OnVisible()
  if not UE.UObject.IsValid(self) then
    return
  end
  if not self.GetLockTime then
    return
  end
  if self:GetLockTime() > 0 then
    self:PlayLockLoopEffect()
  else
    self:PlayUnlockLoopEffect()
  end
  if not self.firstVisible then
    self:OnFirstVisible()
    self.firstVisible = true
  end
  if not self.bPlayingEnterPerform then
    self:PlayLoopPerform()
  end
  if self.sceneCharacter and self.sceneCharacter.viewObj == self then
    if self.sceneCharacter.luaObj.isOptTimesValid then
      self:PlayOptTimesValidLoopEffect()
    else
      self:PlayOptTimesOverLoopEffect()
    end
    self.sceneCharacter:OnVisible()
  end
  if self.BeamComponent and not self.bHidden then
    self.BeamComponent:Show()
  end
end

function ViewNPCBase:OnInVisible()
  if self.BeamComponent then
    self.BeamComponent:Hide()
  end
  if self.sceneCharacter and self.sceneCharacter.viewObj == self then
    self.sceneCharacter:OnInvisible()
  end
end

function ViewNPCBase:PlayPickUpByPlayer(Player, Caller, Callback)
  self:PlayDisappearSkill("/Game/ArtRes/Effects/G6Skill/SceneCaiji/G6_Scene_Collected_CaiJi", Player.viewObj, Caller, Callback)
end

function ViewNPCBase:PlayPickUpByPet(Pet, Caller, Callback)
  self:PlayDisappearSkill("/Game/ArtRes/Effects/G6Skill/SceneCaiji/G6_Scene_Caiji_Com.G6_Scene_Caiji_Com", Pet.ViewObj, Caller, Callback)
end

function ViewNPCBase:PlayDisappearPerform()
  Log.Debug("ViewNPCBase:PlayDisappearPerform")
  if self.DestorySkill and self.RocoSkill then
    local skillClass = UE4.UKismetSystemLibrary.LoadClassAsset_Blocking(self.DestorySkill)
    if not skillClass then
      Log.Warning("no skill class", self:GetDebugInfo())
    end
    local skillObj = self.RocoSkill:FindOrAddSkillObj(skillClass)
    if skillObj then
      skillObj:SetCaster(self)
      skillObj:RegisterEventCallback("End", self.sceneCharacter, self.sceneCharacter.Destroy)
      self.RocoSkill:PlaySkill(skillObj)
    else
      Log.Warning("no skill obj", self:GetDebugInfo())
    end
  else
    self.sceneCharacter:Destroy()
  end
end

function ViewNPCBase:PlayDisappearSkill(SkillPath, SkillTarget, Caller, Callback)
  Caller = Caller or self.sceneCharacter
  Callback = Callback or self.sceneCharacter.Destroy
  if not UE.UObject.IsValid(self) then
    Log.Error("ViewNPCBase:PlayDisappearSkill: self is not valid")
    if Callback then
      Callback(Caller)
    end
    return
  end
  local AIComp = self.sceneCharacter and self.sceneCharacter.AIComponent
  if AIComp then
    AIComp:ForceLockForReason(true, false, AIDefines.LockReason.BORN_DIE)
  end
  if self.sceneCharacter and self.sceneCharacter:IsHidden() then
    Log.Debug("NPC\229\164\132\228\186\142\233\154\144\232\151\143\231\138\182\230\128\129\239\188\140\233\157\153\233\187\152\229\136\160\233\153\164", self:GetDebugInfo())
    self.sceneCharacter:Destroy()
    return
  end
  local SkillComp = self:GetComponentByClass(UE4.URocoSkillComponent)
  if not SkillComp then
    local Identity = UE4.FTransform()
    SkillComp = self:AddComponentByClass(UE4.URocoSkillComponent, false, Identity, false)
    self.RocoSkill = SkillComp
    if not self:GetComponentByClass(UE4.URocoFXComponent) then
      self:AddComponentByClass(UE4.URocoFXComponent, false, Identity, false)
    end
  end
  if not SkillComp then
    Log.Error("Can't find skill component", SkillPath)
    self.sceneCharacter:Destroy()
    return
  end
  SkillComp:StopPendingSkill()
  SkillComp:StopCurrentSkill()
  SkillComp:ClearAllPassiveSkillObjs()
  local targetSceneCharacter = SkillTarget and SkillTarget.sceneCharacter
  local isLocal = targetSceneCharacter and targetSceneCharacter.isLocal or false
  local loadPriority = isLocal and PriorityEnum.Active_NPC_BornDie or PriorityEnum.Passive_NPC_BornDie
  local Skill = RocoSkillProxy.Create(SkillPath, SkillComp, loadPriority)
  if not Skill then
    Log.Error("Failed to load skill", SkillPath)
    self.sceneCharacter:Destroy()
    return
  end
  Skill:SetPassive(true)
  Skill:SetCaster(self)
  if nil == SkillTarget or not UE.UObject.IsValid(SkillTarget) then
    Skill:SetTargets({self})
  else
    Skill:SetTargets({SkillTarget})
  end
  Skill:RegisterEventCallback("Hide", self, self.HideBeam)
  Skill:RegisterEventCallback("End", Caller, Callback)
  Skill:RegisterEventCallback("PreEnd", Caller, Callback)
  Skill:RegisterEventCallback("ActivateFailed", Caller, Callback)
  Skill:PlaySkill()
end

function ViewNPCBase:HideBeam()
  if self.BeamComponent then
    self.BeamComponent:Hide()
  end
end

function ViewNPCBase:OnEnterPerformFinish()
  self.bPlayingEnterPerform = false
  self:PlayLoopPerform()
end

function ViewNPCBase:PlayLoopPerform()
  if not self.sceneCharacter then
    return
  end
  local config = self.sceneCharacter.config
  local animName = config.original_action
  if animName and self.RocoAnim then
    Log.Debug("ViewNPCBase:PlayLoopPerform", animName, self:GetDebugInfo())
    self.RocoAnim:PlayAnimByName(animName, 1, -1, 0, 0, -1, 0)
  end
end

function ViewNPCBase:OnFirstVisible()
  if not self.sceneCharacter then
    return
  end
  local npcInfo = self.sceneCharacter.serverData
  if not npcInfo then
    return
  end
  local bornAnim = npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.NpcInteract_OptionCreateNpcWithAnimPlay
  local effectGenerate = npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.NpcInteract_OptionCreateNpc or npcInfo.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.Minigame or bornAnim or self.sceneCharacter.luaObj.createFromReward
  if effectGenerate then
    local BaseInfo = npcInfo.base
    local BornDieInfo = BaseInfo and BaseInfo.born_die_info
    local Spawning = BornDieInfo and BornDieInfo.is_borning
    if Spawning then
      effectGenerate = false
    end
  end
  if effectGenerate then
    if bornAnim and self.BornSkill then
      local skillComp = self:GetComponentByClass(UE.URocoSkillComponent)
      local skillObj = RocoSkillProxy.Create(tostring(self.BornSkill), skillComp, PriorityEnum.Passive_NPC_BornDie)
      if skillObj then
        skillObj:SetCaster(self)
        skillObj:RegisterEventCallback("End", self, self.OnEnterPerformFinish)
        skillObj:PlaySkill()
        self.bPlayingEnterPerform = true
      else
        Log.Warning("no skill obj", self:GetDebugInfo())
      end
    else
      Log.Debug("ViewNPCBase:OnFirstLoad effectGenerate Smoke", self:GetDebugInfo())
      local skillPath = _G.UEPath.NPC_CREATE_EFFECT
      local skillComp = self:GetComponentByClass(UE.URocoSkillComponent)
      local skillObj = RocoSkillProxy.Create(skillPath, skillComp, PriorityEnum.Passive_NPC_BornDie)
      if skillObj then
        skillObj:SetPassive(true)
        skillObj:SetCaster(self)
        skillObj:PlaySkill()
      end
    end
  end
  local startBeam = self.sceneCharacter.bCreateFromSrcNpc == false
  if startBeam then
    self:PlayBeamEffect()
  end
end

function ViewNPCBase:PlayBeamEffect()
  if not self.BeamComponent then
    return
  end
  self.BeamComponent:Create()
  self.BeamComponent:Toggle(not self.bHidden)
end

function ViewNPCBase:OnFirstLoad()
end

function ViewNPCBase:OnFrameLoad(distanceRatio)
  distanceRatio = distanceRatio or 0
  if distanceRatio < 1 then
    self:LoadResource()
  end
  self.frameLoaded = true
end

function ViewNPCBase:FixCoord(bForceLockOnGround, bAllowFakeFixCoord)
  bForceLockOnGround = bForceLockOnGround or false
  if self.runtimeCreate then
    if not self.sceneCharacter or self.forbidFixCoord then
      return true
    end
    if self:IsFake() and not bAllowFakeFixCoord then
      return true
    end
  end
  local bLockOnGround, sceneCharacter
  if self.runtimeCreate then
    sceneCharacter = self.sceneCharacter
  else
    sceneCharacter = {}
    sceneCharacter.serverPos = self:Abs_K2_GetActorLocation()
    sceneCharacter.landPos = self:Abs_K2_GetActorLocation()
  end
  if self.runtimeCreate then
    local ServerData = sceneCharacter.serverData
    local NPCBase = ServerData and ServerData.npc_base
    local refreshContentID = NPCBase and NPCBase.npc_content_cfg_id or 0
    local refreshConf
    if nil ~= refreshContentID and 0 ~= refreshContentID then
      refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(refreshContentID)
    end
    if not refreshConf or 0 == refreshConf.lock_on_ground then
      bLockOnGround = 1 == sceneCharacter.config.lock_on_ground
    else
      bLockOnGround = 1 == refreshConf.lock_on_ground
    end
  else
    bLockOnGround = self.needFixcoord
  end
  local halfHeight = 0
  if self.GetHalfHeight then
    halfHeight = self:GetHalfHeight()
  end
  if self.IsFakeNpc then
    return true
  end
  if self.runtimeCreate or self.needFixcoord then
    local NewLandPos
    if _G.GlobalConfig.DisableNPCFixCoordinate and not bForceLockOnGround then
      if NPCLuaUtils.HasValidPoint(sceneCharacter.serverData) then
        local ServerData = sceneCharacter.serverData
        if ServerData then
          local Pos = ServerData.base.pt.pos
          NewLandPos = UE.FVector(Pos.x, Pos.y, (Pos.z or 0) + halfHeight)
        end
        if not sceneCharacter.bCoordinateFixed and halfHeight > 0 then
          self:Abs_K2_SetActorLocation_WithoutHit(NewLandPos, false, false)
          Log.Debug("[NpcAOI]ViewNPCBase:FixCoord when HasHalfHeightConf is false", UE4.UObject.GetName(self), halfHeight, NewLandPos)
        end
      else
        Log.Debug("no valid point", sceneCharacter:DebugNPCNameAndID())
        local FinalVector
        for i = 1, 2 do
          local rangeMax = 150
          local heightOffset = 80
          NewLandPos = LuaActionRandomPos:GetRandomPosInRing(sceneCharacter.serverPos, 0.0, rangeMax, nil, 360)
          NewLandPos.Z = NewLandPos.Z + heightOffset
          local position = UE4.UNRCStatics.GetPosInLine(self, NewLandPos, sceneCharacter.serverPos, {}, {}, true)
          local can_see = UE.UKismetMathLibrary.Vector_IsNearlyZero(position)
          if not can_see then
          else
            local NearLocation = UE.UNRCStatics.GetPosInNearLand(self, NewLandPos)
            local distanceMax2 = 700
            if distanceMax2 < UE4.UKismetMathLibrary.Vector_Distance(NearLocation, sceneCharacter.serverPos) then
            else
              FinalVector = NearLocation
              break
            end
          end
        end
        FinalVector = FinalVector or LuaActionRandomPos:GetRandomPosInRing(sceneCharacter.serverPos, 0.0, 50.0, nil, 360)
        FinalVector.Z = FinalVector.Z + 100
        NewLandPos = self:FixCoordinate(FinalVector, self:GetFixHeight(), bLockOnGround, bForceLockOnGround)
        sceneCharacter:ReportPosition()
      end
    else
      NewLandPos = self:FixCoordinate(sceneCharacter.serverPos, halfHeight, bLockOnGround, bForceLockOnGround)
    end
    if NewLandPos then
      sceneCharacter.landPos = NewLandPos
    end
  end
  return true
end

function ViewNPCBase:GetFixHeight()
  if not self.fixHeight then
    self.fixHeight = 0
    if self.GetHalfHeight then
      self.fixHeight = self:GetHalfHeight()
    end
  end
  return self.fixHeight
end

function ViewNPCBase:PreChangeTick_OnFirstVisible()
  if self:FixCoord(false) then
    self:OnFixCoordFinish()
  else
    self.tryReFixcoordTime = 0
  end
end

function ViewNPCBase:OnFixCoordFinish()
  self.fixcoordFinish = true
  if self.sceneCharacter then
    if self.sceneCharacter.CheckPlayerInSeat then
      self.sceneCharacter:CheckPlayerInSeat()
    end
    if self.sceneCharacter.CheckPlayerInBox then
      self.sceneCharacter:CheckPlayerInBox()
    end
  end
end

function ViewNPCBase:PreChangeTick_OnVisible()
  if not UE.UObject.IsValid(self) then
    return
  end
  if not self.firstVisible and self.PreChangeTick_OnFirstVisible then
    self:PreChangeTick_OnFirstVisible()
    if self.sceneCharacter and self.sceneCharacter.IsFarmCropNpc and self.sceneCharacter:IsFarmCropNpc() then
      local landId = self.sceneCharacter:GetFarmLandId()
      FarmUtils.FixPlantNPCCoordinate(landId)
    end
  end
end

function ViewNPCBase:PreChangeTick_OnInVisible()
end

function ViewNPCBase:IsFake()
  if not self.sceneCharacter then
    return true
  end
  if self.sceneCharacter.serverData then
    return self.sceneCharacter:IsLocal()
  else
    return false
  end
end

function ViewNPCBase:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
end

function ViewNPCBase:SetActorNeedTick(flag)
  if not UE.UObject.IsValid(self) then
    Log.Error("Trying to call SetActorNeedTick on a nil actor", self)
    return
  end
  self.needTick = flag
  self:SetActorTickEnabled(flag)
end

function ViewNPCBase:SetActorLocation(newPos)
  self:Abs_K2_SetActorLocation_WithoutHit(newPos, false, false)
  if self.BeamComponent then
    self.BeamComponent:SetLocation(newPos)
  end
end

function ViewNPCBase:GetNearLocation()
  return self:Abs_K2_GetActorLocation()
end

function ViewNPCBase:GetNearLandLocation()
  local pos = self:GetNearLocation()
  return SceneUtils.GetPosInNearLand(pos)
end

function ViewNPCBase:GetNearLocations(num)
  local ans = {}
  return ans
end

function ViewNPCBase:GetNearLandLocations(num)
  local ans = {}
  local nearLocations = self:GetNearLandLocations(num)
  for _, pos in pairs(nearLocations) do
    local landPos = SceneUtils.GetPosInNearLand(pos)
    if landPos then
      table.insert(ans, landPos)
    end
  end
  return ans
end

function ViewNPCBase:ReceiveActorBeginOverlap(OtherActor)
  local OtherSceneCharacter = OtherActor.sceneCharacter
  if OtherSceneCharacter and OtherSceneCharacter.isLocal then
    Log.Debug("ViewNPCBase:ReceiveActorBeginOverlap", self:GetName())
    self.otherActor = OtherActor
    if self.debugWhenNear and self.sceneCharacter.serverData then
      Log.Debug("Debug When Near: ", self.sceneCharacter.config.name, self.sceneCharacter.serverData.base.actor_id, string.format("%u", self.sceneCharacter.serverData.base.actor_id))
      Log.Dump(self.sceneCharacter.serverData)
    end
    if self.sceneCharacter and self.sceneCharacter.InteractionComponent then
      self.sceneCharacter.InteractionComponent:OnPlayerEnterActionArea()
    else
    end
  end
end

function ViewNPCBase:CheckForOtherInteractions(HitOnWater)
end

function ViewNPCBase:SetThrowFuncInValid()
  if self.ThrowSession then
    self.ThrowSession:SetIsValid(false)
  end
end

function ViewNPCBase:SetThrowSession(session)
  self.ThrowSession = session
end

function ViewNPCBase:ShowThrowInterInfo()
end

function ViewNPCBase:OnThrowStart()
  self.ThrowSession:SetInAir()
end

function ViewNPCBase:CanEnterThrowInter(Comp)
  return self.Mesh and Comp == self.Mesh
end

function ViewNPCBase:CanThrowInter(Item)
  if not Item then
    return false
  end
  local Session = Item.ThrowSession
  if not Session then
    return false
  end
  if not Session:HasPet() then
    return false
  end
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return false
  end
  local InteractType = SceneCharacter.config.throwing_interact_type
  local InterComp = SceneCharacter.InteractionComponent
  if InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET and InterComp:CanBattle() then
    return true
  end
  local PetData = Session.petData
  local PetBaseConf = PetData and _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  if not PetBaseConf then
    return false
  end
  local SpecialInteract = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_SPEOBJ or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_TRIGGER
  SpecialInteract = SpecialInteract or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
  if SpecialInteract and InterComp:CanInteractWithPet(PetBaseConf) then
    local _, Special = InterComp:GetPetOption(PetData)
    if Special then
      return true
    else
      if SceneCharacter.Watch then
        Log.Error(SceneCharacter:DebugNPCNameAndID(), "\230\178\161\230\156\137\229\143\175\231\148\168\231\137\185\230\174\138\228\186\164\228\186\146")
      end
      return false
    end
  end
  local HumanInteract = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL
  if HumanInteract and InterComp:CanInteractWithPet(PetBaseConf) then
    local RandOpt = InterComp:GetRandomOption()
    if RandOpt then
      return true
    end
  end
  if SceneCharacter.Watch then
    Log.Error(SceneCharacter:DebugNPCNameAndID(), "\228\184\141\229\143\175\228\186\164\228\186\146\239\188\140\231\166\187\229\188\128")
  end
  return false
end

function ViewNPCBase:OnThrowItemEnter(item, OtherComp)
  Log.Debug("ViewNPCBase:OnThrowItemEnter")
  if not item then
    return
  end
  local Session = item.ThrowSession
  if not Session then
    return
  end
  if not Session:HasPet() then
    item:MakeCollectable()
    return
  end
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    Log.Warning("\230\138\149\230\142\183\231\155\174\230\160\135\230\178\161\230\156\137SceneCharacter\239\188\140\229\155\158\230\148\182\231\178\190\231\129\181")
    item:ReleaseFailedIfStop()
    return
  end
  local InteractType = SceneCharacter.config.throwing_interact_type
  local InterComp = SceneCharacter.InteractionComponent
  if InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET and InterComp:CanBattle() then
    local Comp = item:GetPetBallComp()
    Comp:BattleWithNPC(SceneCharacter)
    return
  end
  local PetData = Session.petData
  local SpecialInteract = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_SPEOBJ or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_TRIGGER
  SpecialInteract = SpecialInteract or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
  if SpecialInteract and InterComp:CanInteractWithPet(PetData) then
    local _, Special = InterComp:GetPetOption(PetData)
    local Comp = item:GetPetBallComp()
    if Special then
      Comp:DoSpecialPetAction(false, Special)
    else
      Comp:Log(SceneCharacter, "\231\137\185\230\174\138\228\186\164\228\186\146\229\164\177\232\180\165")
      Comp:ReleaseFailedIfStop()
    end
    return
  end
  local HumanInteract = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL
  if HumanInteract and InterComp:CanInteractWithPet(PetData) then
    local Dialogue = InterComp:GetDialogue()
    local RandOpt = InterComp:GetRandomOption()
    local Comp = item:GetPetBallComp()
    if Dialogue then
      Comp:DoSpecialHumanAction(false, Dialogue)
      return
    elseif RandOpt then
      Comp:DoRandomHumanOptions({RandOpt})
      return
    else
      Comp:Log(SceneCharacter, "\230\178\161\230\156\137\229\175\185\232\175\157\230\136\150\232\128\133\233\154\143\230\156\186\228\186\164\228\186\146")
    end
  end
  Log.Debug("\230\151\160\228\187\187\228\189\149\229\143\175\230\137\167\232\161\140\228\186\164\228\186\146\239\188\140\229\155\158\230\148\182\231\178\190\231\129\181")
  item:ReleaseFailedIfStop()
end

function ViewNPCBase:ReceiveActorEndOverlap(OtherActor)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.isLocal then
    self.otherActor = nil
    if self.sceneCharacter and self.sceneCharacter.InteractionComponent then
      self.sceneCharacter.InteractionComponent:OnPlayerLeaveActionArea()
    elseif self.sceneCharacter and self.sceneCharacter.HomeInteractionComponent then
      self.sceneCharacter.HomeInteractionComponent:OnPlayerLeaveActionArea()
    end
  end
end

function ViewNPCBase:ReceiveDestroyed()
  if self.sceneCharacter and self.sceneCharacter.OnDestroyedByEngine then
    self.sceneCharacter:OnDestroyedByEngine()
  end
end

function ViewNPCBase:OnDropStart()
end

function ViewNPCBase:OnDropStop()
end

function ViewNPCBase:OnEnterBattle(center, radius, disSqr)
  if disSqr >= radius * radius then
    return
  end
  local SceneCharacter = self.sceneCharacter
  local Config = SceneCharacter and SceneCharacter.config
  if Config and Config.dont_hide_in_battle > 0 then
    return
  end
  if not _G.NRCModuleManager:DoCmd(BattleModuleCmd.CheckNpcInHideRange, self) then
    return
  end
  if SceneCharacter then
    SceneCharacter:SetVisibleForBattleReason(false)
  end
end

function ViewNPCBase:OnLeaveBattle()
  local SceneCharacter = self.sceneCharacter
  if SceneCharacter then
    SceneCharacter:SetVisibleForBattleReason(true)
  end
end

function ViewNPCBase:SetVisibleForBattleReason(flag)
  assert(false, "deprecated, use self.sceneCharacter:SetVisibleForBattleReason instead")
  if self.sceneCharacter then
    self.sceneCharacter:SetVisibleForBattleReason(flag)
  end
end

function ViewNPCBase:SetVisible(Visible)
  if not UE.UObject.IsValid(self) then
    return
  end
  if self.bHidden ~= Visible then
    return
  end
  self:SetVisibleInternal(Visible)
end

function ViewNPCBase:SetCollisionEnable(CollisionEnable)
  self:SetCollisionEnableInternal(CollisionEnable)
end

function ViewNPCBase:SetLoadEnable(LoadEnable)
  self:SetLoadEnableInternal(LoadEnable)
end

function ViewNPCBase:SetVisibleInternal(Flag)
  Log.DebugFormat("[NPC\230\152\190\233\154\144] SetVisibleInternal\239\188\154 %s; \230\152\175\229\144\166\233\154\144\232\151\143: %s", self.sceneCharacter and self.sceneCharacter:DebugNPCNameAndID() or self.defaultLabel, tostring(not Flag))
  if self.SetHiddenMask then
    self:SetHiddenMask(not Flag, UE.EPlayerForceHiddenType.LuaHidden)
  else
    self:SetActorHiddenInGame(not Flag)
  end
  if self.BeamComponent then
    self.BeamComponent:Toggle(Flag)
  end
end

function ViewNPCBase:SetCollisionEnableInternal(Flag)
  if not UE4.UObject.IsValid(self) then
    Log.Error("SetCollisionEnableInternal for invalid view")
    return
  end
  if self.bSimulatePhysics == nil then
    local rootComponent = self:K2_GetRootComponent()
    self.bSimulatePhysics = false
    if rootComponent and UE.UObject.IsValid(rootComponent) and rootComponent:IsAnySimulatingPhysics() then
      self.bSimulatePhysics = true
    end
  end
  if not self.bSimulatePhysics then
    self:SetActorEnableCollision(Flag)
  end
end

function ViewNPCBase:SetLoadEnableInternal(Flag)
  if not UE.UObject.IsValid(self) then
    return
  end
  if Flag then
    if self.ReleaseVisibleLevel then
      self:ReleaseVisibleLevel()
    end
  elseif self.ForceHidden then
    self:ForceHidden()
  end
end

function ViewNPCBase:GetName()
  if self.sceneCharacter then
    return self.sceneCharacter.config.name
  else
    return "No SceneCharacter"
  end
end

function ViewNPCBase:GetDebugInfo()
  if RocoEnv.IS_SHIPPING then
    return ""
  end
  if self.sceneCharacter then
    return self.sceneCharacter:DebugNPCNameAndID()
  else
    return "No SceneCharacter"
  end
end

function ViewNPCBase:GetClassType()
  return 0
end

function ViewNPCBase:DebugDetail()
end

function ViewNPCBase:TogglePhysics(on)
  if not UE.UObject.IsValid(self) then
    return
  end
  local root = self:K2_GetRootComponent()
  if not root then
    Log.Error("Root Not found ", self:GetName())
    return
  end
  root:SetSimulatePhysics(on)
end

function ViewNPCBase:SetMeshAlpha(Alpha)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  local Comp = self.RocoMaterial
  if not Comp or not UE.UObject.IsValid(Comp) then
    return
  end
  if nil == Alpha then
    Comp:SetMaterialsFade(0)
  else
    Comp:SetMaterialsFade(Alpha)
  end
end

function ViewNPCBase:SetMeshAlphaOverride(Alpha)
  local Comp = self.RocoMaterial
  if not Comp then
    return
  end
  if nil == Alpha then
    Comp:ClearMaterialsFadeOverride()
  else
    Comp:SetMaterialsFadeOverride(Alpha)
  end
end

function ViewNPCBase:SetMeshFresnel(fresnel_color, fresnel_intensity, fresnel_exponent)
  local Comp = self.RocoMaterial
  if not Comp then
    return
  end
  Log.Info("ViewNPCBase:SetMeshFresnel", fresnel_color, fresnel_intensity, fresnel_exponent)
  if Comp.ModifyMaterialFresnel then
    Comp:ModifyMaterialFresnel(fresnel_color, fresnel_intensity, fresnel_exponent, self)
  end
end

function ViewNPCBase:ClearMeshFresnel()
  local Comp = self.RocoMaterial
  if not Comp then
    return
  end
  Log.Info("ViewNPCBase:ClearMeshFresnel")
  Comp:UnmodifyMaterial(self)
end

function ViewNPCBase:SetCustomDepth(Depth)
  NPCLuaUtils.SetCustomDepth(self, Depth)
end

function ViewNPCBase:PlayCommonPetInteractionSkill(petElement, target, onPetSkillEnd)
  if self.skillPlayComponent == nil then
    self.skillPlayComponent = NpcSkillPlayComponent(self)
  end
  self.skillPlayComponent:PlayCommonPetInteractionSkill(petElement, target, onPetSkillEnd)
end

function ViewNPCBase:PlaySkill(skillPath, caster, target, eventRegister, onSkillEnd, isPassive)
  if self.skillPlayComponent == nil then
    self.skillPlayComponent = NpcSkillPlayComponent(self)
  end
  self.skillPlayComponent:PlaySkill(skillPath, caster, target, eventRegister, onSkillEnd, isPassive)
end

function ViewNPCBase:PlaySkillByClass(assetClass, caster, target, eventRegister, onSkillEnd, isPassive)
  if self.skillPlayComponent == nil then
    self.skillPlayComponent = NpcSkillPlayComponent(self)
  end
  self.skillPlayComponent:PlaySkillByClass(assetClass, caster, target, eventRegister, onSkillEnd, isPassive)
end

function ViewNPCBase:ExportCurrentPosition()
  local serverData = self.sceneCharacter and self.sceneCharacter.serverData
  if serverData then
    local npc_content_cfg_id = serverData.npc_base.npc_content_cfg_id
    local npc_refresh_content = _G.DataConfigManager:GetNpcRefreshContentConf(npc_content_cfg_id)
    if npc_refresh_content.refresh_param then
      local halfHeight = 0
      if self.GetHalfHeight then
        halfHeight = self:GetHalfHeight()
      end
      local area_conf = _G.DataConfigManager:GetAreaConf(npc_refresh_content.refresh_param)
      if area_conf.area_type ~= _G.Enum.AreaType.AREAT_POINT then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\175\188\229\135\186AreaConf\232\162\171\230\139\146\231\187\157 %d\228\184\141\230\152\175\228\184\128\228\184\170\231\130\185\231\177\187\229\158\139\231\154\132\229\140\186\229\159\159", npc_refresh_content.refresh_param), nil, nil, 2)
        return
      end
      local location = self:Abs_K2_GetActorLocation()
      location.Z = location.Z - halfHeight
      local succeed = UE4.UNRCStatics.UpdateAreaConf(npc_refresh_content.refresh_param, location, self:K2_GetActorRotation())
      Log.Error("\229\175\188\229\135\186\228\189\141\231\189\174\228\191\174\230\173\163\229\140\186\229\159\159", npc_refresh_content.refresh_param, location.X, location.Y, location.Z)
      if succeed then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\175\188\229\135\186AreaConf\230\136\144\229\138\159 %d", npc_refresh_content.refresh_param), nil, nil, 2)
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\175\188\229\135\186AreaConf\231\154\132\231\168\139\229\186\143\231\173\137\228\186\13410\231\167\146\232\191\152\230\178\161\231\187\147\230\157\159\239\188\140\229\190\136\229\143\164\230\128\170 %d", npc_refresh_content.refresh_param), nil, nil, 2)
      end
    end
  end
end

function ViewNPCBase:ForceLockOnGround()
  self.sceneCharacter.serverPos = self:Abs_K2_GetActorLocation()
  self:FixCoord(true)
end

function ViewNPCBase:TellMeDistanceWithPlayer()
  local SquareDistance
  if self.sceneCharacter and self.sceneCharacter.squaredDis2Local then
    SquareDistance = self.sceneCharacter.squaredDis2Local
  else
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    SquareDistance = self:GetSquaredDistanceTo(localPlayer.viewObj)
  end
  local name = self.sceneCharacter and self.sceneCharacter.serverData and self.sceneCharacter.serverData.base.name
  name = name or self:GetFullName()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("%s\231\166\187\231\142\169\229\174\182\231\154\132\232\183\157\231\166\187\230\152\175%d\231\177\179\239\188\136\229\155\155\232\136\141\228\186\148\229\133\165\239\188\137", name, math.round(math.sqrt(SquareDistance) / 100)), nil, nil, 5)
end

function ViewNPCBase:BeforeDestroyAnim()
end

function ViewNPCBase:BeforeBornPerform()
end

function ViewNPCBase:AfterBornPerform()
end

function ViewNPCBase:SetVisibleFromCpp(Visible)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  self:SetVisibleFromCppByReason(Visible, NPCModuleEnum.NpcReasonFlags.CPP)
end

function ViewNPCBase:SetVisibleFromParent(Visible)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  self:SetVisibleFromCppByReason(Visible, NPCModuleEnum.NpcReasonFlags.PARENT)
end

function ViewNPCBase:SetVisibleFromCppByReason(Visible, Reason)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  local SceneCharacter = self.sceneCharacter
  if SceneCharacter then
    if not SceneCharacter.SetHidden then
      Log.Error("\229\165\135\230\128\170\228\186\134SetHidden\230\152\175\231\169\186\231\154\132", UE.UObject.GetName(self))
    end
    Reason = Reason or NPCModuleEnum.NpcReasonFlags.SKILL_DEFAULT
    SceneCharacter:SetHidden(not Visible, Reason)
    SceneCharacter:SetCollisionDisable(not Visible, Reason)
  else
    if not self.hiddenFlag or not self.collisionDisableFlag then
      self.hiddenFlag = 0
      self.collisionDisableFlag = 0
    end
    local NewHiddenFlag = SetBit(self.hiddenFlag, Reason, not Visible)
    local NewCollisionDisableFlag = SetBit(self.collisionDisableFlag, Reason, not Visible)
    if self.hiddenFlag ~= NewHiddenFlag then
      local OldIsVisible = 0 == self.hiddenFlag
      self.hiddenFlag = NewHiddenFlag
      local NewIsVisible = 0 == self.hiddenFlag
      if OldIsVisible ~= NewIsVisible then
        self:SetVisibleInternal(NewIsVisible)
      end
    end
    if self.collisionDisableFlag ~= NewCollisionDisableFlag then
      local OldIsCollisionEnable = 0 == self.collisionDisableFlag
      self.collisionDisableFlag = NewCollisionDisableFlag
      local NewIsCollisionEnable = 0 == self.collisionDisableFlag
      if OldIsCollisionEnable ~= NewIsCollisionEnable then
        self:SetCollisionEnableInternal(NewIsCollisionEnable)
      end
    end
  end
end

function ViewNPCBase:PreventOverlap(force, skipVis, skipCol)
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  local Comp = SceneCharacter:EnsureComponent(OverlapAwareVisibilityComponent)
  if not Comp then
    return
  end
  if force then
    SceneCharacter:CalSquaredDis2Local()
  end
  Comp:CheckInBoundAndMarkHidden(force, skipVis, skipCol)
end

function ViewNPCBase:RegisterToTrailSystem(DetectType)
  if not UE4.UObject.IsValid(self) then
    return
  end
  Log.Debug("ViewNPCBase:RegisterToTrailSystem", self:GetDebugInfo())
  local NRCTrailSystem = UE4.ANRCTrailSystem.Get(self)
  DetectType = DetectType or UE4.ENRCTrailFootstepDetectType.OneTime
  local Origin, Extend = self:GetActorBounds(true)
  NRCTrailSystem:RegisterObjectByActor(self, DetectType, Origin, Extend)
end

function ViewNPCBase:UnRegisterFromTrailSystem()
  if not UE4.UObject.IsValid(self) then
    return
  end
  Log.Debug("ViewNPCBase:UnRegisterFromTrailSystem", self:GetDebugInfo())
  local NRCTrailSystem = UE4.ANRCTrailSystem.Get(self)
  NRCTrailSystem:UnregisterObjectByActor(self)
end

function ViewNPCBase:InitWidgetComponent(HeadWidget)
  if not UE.UObject.IsValid(HeadWidget) then
    Log.Error("ViewNPCBase:InitWidgetComponent \228\188\160\229\133\165\231\154\132HeadWidget\230\151\160\230\149\136")
    return
  end
  local npc = self.sceneCharacter
  local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
  if not hudClass then
    Log.Error("ViewNPCBase:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) First Failed")
    hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
    if not hudClass then
      Log.Error("ViewNPCBase:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) Second Failed")
      return
    end
    return
  end
  local hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
  if not hud then
    Log.Error("ViewNPCBase:OnVisible Create hud First Failed")
    hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
    if not hud then
      Log.Error("ViewNPCBase:OnVisible Create hud Second Failed")
      return
    end
  end
  if hud and npc then
    HeadWidget:SetWidget(hud)
    hud:SetParentHUD(HeadWidget)
    local hudComp = npc:EnsureComponent(PetHUDComponent)
    hudComp:OnSetViewObj()
    hudComp:ForceUpdate()
  end
end

return ViewNPCBase
