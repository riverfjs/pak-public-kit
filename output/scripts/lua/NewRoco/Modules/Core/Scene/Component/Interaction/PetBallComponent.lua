local EQSQueryType = require("NewRoco.Modules.Core.NPC.EQSQueryType")
local ResQueue = require("NewRoco.Utils.ResQueue")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local PetInteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetInteractionComponent")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local Base = ActorComponent
local CD2Conf = _G.DataConfigManager:GetBattleGlobalConfig("touch_battle_min_cd")
local CD2 = 3
if CD2Conf and CD2Conf.num then
  CD2 = CD2Conf.num
end

local function GetSquaredGlobalConf(key, default)
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local conf = _G.DataConfigManager:GetGlobalConfigByKeyType(key, confID)
  if not conf then
    return default or 100
  end
  local num = conf.num
  return num * num
end

local function GetGlobalNum(key, default)
  local Conf = _G.DataConfigManager:GetNpcGlobalConfig(key)
  if not Conf then
    return default or 100
  end
  return Conf.num
end

local PetInteractRange = GetSquaredGlobalConf("pet_interact_range")
local PetBattleRange = GetSquaredGlobalConf("pet_fight_range")
local PetBattleHeight = GetGlobalNum("pet_fight_range_height")
local MaxInteractRange = 1000000
local PET_BALL_KEY = "_ID_AUTOGENERATE_BALL0"
local PetBallComponent = Base:Extend("PetBallComponent")

function PetBallComponent:Attach(owner)
  Base.Attach(self, owner)
  self.enabled = false
  self.LoadQueue = nil
  self.ObjectTypes = {
    UE.EObjectTypeQuery.WorldDynamic,
    UE.EObjectTypeQuery.Pawn,
    UE.EObjectTypeQuery.WorldStatic
  }
  self.CachedResults = UE4.TArray(UE.AActor)
  self.CachedIgnoreActors = setmetatable({}, {__mode = "kv"})
  self.CurrentThrowSession = nil
  self.pendingSpecialAction = false
  self.pendingNormalOptions = false
  self.pendingRandomOptions = false
  self.bAlreadyInteracted = false
  self.petReleaseLocation = nil
end

function PetBallComponent:GetLocalPlayer()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return nil
  end
  return Player.viewObj
end

function PetBallComponent:Query(PetData)
  local OwnerView = self:GetOwnerView()
  if not OwnerView or not UE.UObject.IsValid(OwnerView) then
    Log.Error("OwnerView is gone")
    return nil, nil, nil, nil
  end
  local OwnerPos = OwnerView:K2_GetActorLocation()
  table.clear(self.CachedIgnoreActors)
  table.insert(self.CachedIgnoreActors, OwnerView)
  local Player = self:GetLocalPlayer()
  if Player then
    table.insert(self.CachedIgnoreActors, Player)
  end
  local Success = UE.UNRCStatics.SphereOverlapActors(self.owner.viewObj, OwnerPos, math.sqrt(MaxInteractRange), self.ObjectTypes, self.CachedIgnoreActors, self.CachedResults)
  table.clear(self.CachedIgnoreActors)
  if not Success then
    return nil, nil, nil, nil
  end
  if 0 == self.CachedResults:Length() then
    return nil, nil, nil, nil
  end
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  local BattleNpc, CurrentSpecialPetAction
  local CurrentDistSquared = MaxInteractRange + 1
  local NormalNpcOptions = {}
  local HumanNpcOption = {}
  local throwSession = self.owner and self.owner.ThrowSession
  local ScenePet = throwSession and throwSession.ScenePet
  for _, Actor in tpairs(self.CachedResults) do
    local Character = Actor.sceneCharacter
    if not Character then
    elseif Character.name == "ScenePlayerBase" then
    elseif not Character.config then
    elseif not Character.hiddenFlag or Character.hiddenFlag > 0 then
    else
      local InteractType = Character.config.throwing_interact_type
      local bIsNormal = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_COMMONOBJ
      local bIsSpecial = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_SPEOBJ or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_TRIGGER
      bIsSpecial = bIsSpecial or InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
      local battle = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
      local bIsHuman = InteractType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL
      if not bIsNormal and not bIsSpecial and not battle and not bIsHuman then
        self:Log(Character, "\228\184\141\229\156\168\229\143\175\230\142\165\229\143\151\231\154\132\228\186\164\228\186\146\230\150\185\229\188\143\229\134\133")
      else
        local InterComp = Character.InteractionComponent
        if not InterComp then
          self:Log(Character, "\228\184\141\229\133\183\229\164\135\230\156\137\228\186\164\228\186\146\232\131\189\229\138\155")
        else
          local TargetActorPos = Actor:K2_GetActorLocation()
          local DeltaZ = OwnerPos.Z - TargetActorPos.Z
          if math.abs(DeltaZ) > 500 then
            self:Log(Character, "\233\171\152\229\186\166\229\183\174\229\164\170\229\164\154\228\186\134", OwnerPos.Z, TargetActorPos.Z, 500)
          else
            local DeltaX = OwnerPos.X - TargetActorPos.X
            local DeltaY = OwnerPos.Y - TargetActorPos.Y
            local DistSquared = DeltaX * DeltaX + DeltaY * DeltaY
            local NormalOption, SpecialAction = InterComp:GetPetOption(PetData)
            local finalPetInteractRangeSquared = PetInteractRange
            local normal_option_config = NormalOption and NormalOption.config
            local pet_interact_radius = normal_option_config and normal_option_config.pet_interact_radius
            if pet_interact_radius and pet_interact_radius > 0 then
              finalPetInteractRangeSquared = pet_interact_radius * pet_interact_radius
            end
            local finalPetNormalInteractRangeSquared = finalPetInteractRangeSquared
            if ScenePet then
              local bContains, param = ScenePet:ContainsRealSpecialityEffect(_G.Enum.PetTalentEffect.PTE_GATHER_RANGE_RATIO, true)
              if bContains then
                param = param or 100
                finalPetNormalInteractRangeSquared = finalPetNormalInteractRangeSquared * (param / 100)
              end
            end
            local finalPetBattleRangeSquared = PetBattleRange
            local pet_fight_radius = normal_option_config and normal_option_config.pet_fight_radius
            if pet_fight_radius and pet_fight_radius > 0 then
              finalPetBattleRangeSquared = pet_fight_radius * pet_fight_radius
            else
              local tempPetBattleRange = InterComp:CanBattleMaxRangeSquared()
              if tempPetBattleRange > 0 then
                finalPetBattleRangeSquared = tempPetBattleRange
              end
            end
            if battle and not _G.DataModelMgr.PlayerDataModel:BattleDisabled() then
              if DeltaZ <= finalPetBattleRangeSquared and DistSquared <= finalPetBattleRangeSquared then
                if InterComp:CanBattle() and self.owner:CanSee(Character) then
                  BattleNpc = Character
                  break
                else
                  self:Log(Character, "\230\178\161\230\156\137\230\136\152\230\150\151\233\133\141\231\189\174")
                end
              else
                self:Log(Character, "\229\143\145\232\181\183\230\136\152\230\150\151\232\183\157\231\166\187\229\164\170\232\191\156", DistSquared, finalPetBattleRangeSquared, DeltaZ, PetBattleHeight)
              end
            end
            if _G.GlobalConfig.DebugPetInteract then
              UE4.UKismetSystemLibrary.DrawDebugSphere(UE4Helper.GetCurrentWorld(), OwnerPos, math.sqrt(finalPetInteractRangeSquared), 20, UE4.FLinearColor(0, 1, 0, 1), 10, 2)
              UE4.UKismetSystemLibrary.DrawDebugSphere(UE4Helper.GetCurrentWorld(), OwnerPos, math.sqrt(finalPetBattleRangeSquared), 16, UE4.FLinearColor(1, 0, 0, 1), 10, 2)
            end
            local CheckFeature = InterComp:CanInteractWithPet(BaseConf)
            if not CheckFeature then
              self:Log(Character, "\230\140\137\231\133\167\231\179\187\229\136\171\230\151\160\230\179\149\228\186\164\228\186\146")
            else
              if bIsSpecial then
                if DistSquared <= finalPetInteractRangeSquared then
                  if SpecialAction then
                    if CurrentDistSquared > DistSquared then
                      local Visual
                      if nil == Visual then
                        Visual = self.owner:CanSee(Character)
                      end
                      if Visual then
                        CurrentSpecialPetAction = SpecialAction
                        CurrentDistSquared = DistSquared
                      else
                        self:Log(Character, "\229\173\152\229\156\168\233\152\187\230\140\161")
                      end
                    else
                      self:Log(Character, "\228\184\141\230\152\175\230\156\128\232\191\145\231\154\132\228\186\164\228\186\146\231\137\169")
                    end
                  else
                    self:Log(Character, "\230\178\161\230\156\137\231\137\185\230\174\138\228\186\164\228\186\146\233\128\137\233\161\185")
                  end
                else
                  self:Log(Character, "\228\184\141\230\187\161\232\182\179\231\137\185\230\174\138\228\186\164\228\186\146\230\156\128\229\176\143\232\183\157\231\166\187", finalPetInteractRangeSquared, DistSquared)
                end
              end
              if bIsNormal then
                if DistSquared <= finalPetNormalInteractRangeSquared then
                  if NormalOption then
                    table.insert(NormalNpcOptions, NormalOption)
                  else
                    self:Log(Character, "\230\178\161\230\156\137\230\153\174\233\128\154\228\186\164\228\186\146\233\128\137\233\161\185")
                  end
                else
                  self:Log(Character, "\228\184\141\230\187\161\232\182\179\230\153\174\233\128\154\228\186\164\228\186\146\230\156\128\229\176\143\232\183\157\231\166\187", finalPetNormalInteractRangeSquared, DistSquared)
                end
              end
              if bIsHuman and DistSquared <= finalPetInteractRangeSquared then
                local RandomOption = InterComp:GetRandomOption()
                if RandomOption then
                  table.insert(HumanNpcOption, RandomOption)
                else
                  self:Log(Character, "\228\184\141\229\173\152\229\156\168\229\175\185\232\175\157\228\185\159\228\184\141\229\173\152\229\156\168\233\154\143\230\156\186\232\161\140\228\184\186")
                end
              end
            end
          end
        end
      end
    end
  end
  return BattleNpc, CurrentSpecialPetAction, NormalNpcOptions, HumanNpcOption
end

function PetBallComponent:CheckForOtherInteractions(HitOnWater, CurrentThrowSession)
  self.CurrentThrowSession = CurrentThrowSession
  local BattleNPC, SpecialPetAction, NormalOptions, RandomOptions = self:Query(self.CurrentThrowSession.petData)
  if BattleNPC then
    local Ban, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_THROW_BATTLE, false, false, CD2)
    local AIDisable = false
    if not Ban and BattleNPC.AIComponent then
      AIDisable = BattleNPC.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_THROW_BATTLE)
    end
    if Ban then
      Log.Debug("\228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
      self:QueryStandPoint(EQSQueryType.StandRelease, nil, 200, 500)
    elseif AIDisable then
      Log.Debug("\230\138\149\230\142\183\232\191\155\230\136\152\230\150\151\229\164\177\232\180\165\239\188\140\231\155\174\230\160\135AI\231\166\129\231\148\168\228\186\134\230\138\149\230\142\183\232\191\155\230\136\152")
      self:QueryStandPoint(EQSQueryType.StandRelease, nil, 200, 500)
    else
      self:BattleWithNPC(BattleNPC)
    end
  elseif SpecialPetAction then
    self:DoSpecialPetAction(false, SpecialPetAction)
  elseif NormalOptions and #NormalOptions > 0 then
    self.pendingNormalOptions = NormalOptions
    self:QueryStandPoint(EQSQueryType.StandRelease, nil, 200, 500)
  elseif RandomOptions and #RandomOptions > 0 then
    self:DoRandomHumanOptions(RandomOptions)
  else
    self:QueryStandPoint(EQSQueryType.StandRelease, nil, 200, 500)
  end
end

function PetBallComponent:BattleWithNPC(BattleNpc)
  self:ToggleCollision(false)
  self:GetThrowSession():SetStatus(ThrowSessionStatusEnum.Interacting)
  BattleNpc.InteractionComponent:SubmitBattleOption(self.CurrentThrowSession)
  self:TogglePhysics(false)
end

function PetBallComponent:DoSpecialPetAction(HitOnWater, SpecialPetAction)
  self:ToggleCollision(false)
  self.pendingSpecialAction = SpecialPetAction
  local Range = SpecialPetAction:GetRangeType()
  local Params = SpecialPetAction:GetRangeParams()
  if Range == Enum.PetReleaseRange.PRR_CLOSE then
    if Params then
      self:QueryStandPoint(EQSQueryType.StandRelease, SpecialPetAction:GetOwnerNPCView(), Params[1], Params[2])
    else
      self:QueryStandPoint(EQSQueryType.StandRelease, SpecialPetAction:GetOwnerNPCView(), 200, 500)
    end
  elseif Range == Enum.PetReleaseRange.PRR_NONE then
    self:QueryStandPoint(EQSQueryType.None, SpecialPetAction:GetOwnerNPCView())
  elseif Range == Enum.PetReleaseRange.PRR_FAR_BIG then
    if Params then
      self:QueryStandPoint(EQSQueryType.FarRelease, SpecialPetAction:GetOwnerNPCView(), Params[1], Params[2])
    else
      self:QueryStandPoint(EQSQueryType.FarRelease, SpecialPetAction:GetOwnerNPCView(), 300, 600)
    end
  elseif Range == Enum.PetReleaseRange.PRR_FAN_FRONT then
    if Params then
      self:QueryStandPoint(EQSQueryType.FanRelease, SpecialPetAction:GetOwnerNPCView(), Params[1], Params[2])
    else
      self:QueryStandPoint(EQSQueryType.FanRelease, SpecialPetAction:GetOwnerNPCView(), 300, 600)
    end
  elseif Params then
    self:QueryStandPoint(EQSQueryType.FarRelease, SpecialPetAction:GetOwnerNPCView(), Params[1], Params[2])
  else
    self:QueryStandPoint(EQSQueryType.FarRelease, SpecialPetAction:GetOwnerNPCView(), 200, 500)
  end
end

function PetBallComponent:DoRandomHumanOptions(options)
  self.pendingRandomOptions = options
  self:QueryStandPoint(EQSQueryType.StandRelease, nil, 200, 500)
end

function PetBallComponent:QueryStandPoint(QueryType, Querier, InnerRadius, OuterRadius)
  if nil == Querier then
    Querier = self:GetOwnerView()
  end
  local Session = self:GetThrowSession()
  local PetData = Session and Session.petData
  if not Session or not PetData then
    Log.Warning("PetBallComponent:QueryStandPoint")
    return
  end
  if not ThrowSession.CheckSessionActive(Session) then
    Log.Error("PetBallComponent: can not create pet when session is not active!")
    Session:RecycleAllRes()
    return
  end
  if Session.endThrowSendDone then
    Log.Error("PetBallComponent: can not create pet when session has sent end throw request!")
    Session:RecycleAllRes()
    return
  end
  local ModelID = Session.ScenePet.config.model_conf
  local QuerierLocation
  if QueryType == EQSQueryType.None then
    if not Querier then
      Log.Error("PetBallComponent: querier is nil!")
      Session:RecycleAllRes()
      return
    end
    QuerierLocation = Querier:Abs_K2_GetActorLocation()
    if not QuerierLocation then
      Log.Error("PetBallComponent: can not get querier location!")
      Session:RecycleAllRes()
      return
    end
  end
  self.owner:SetNotDestroyFlag(true)
  Session.bHasPendingRelease = true
  Session:SetStatus(ThrowSessionStatusEnum.PreReleasing)
  if self.LoadQueue then
    self.LoadQueue:Release()
  else
    self.LoadQueue = ResQueue(30, ResQueue.RunMode.Concurrent, _G.PriorityEnum.Active_Throw_Pet)
  end
  self.LoadQueue:InsertSessionThrowBegin("Session", Session)
  if QueryType == EQSQueryType.None then
    self.PetReleaseLocation = QuerierLocation
  else
    self.LoadQueue:InsertStandRelease("EQS", QueryType, PetData, ModelID, Querier, InnerRadius, OuterRadius)
  end
  self.LoadQueue:InsertPet("Pet", Session)
  self.LoadQueue:InsertClass("Jump", "/Game/ArtRes/Effects/G6Skill/Yuancheng/CallOut_Suc")
  self.LoadQueue:StartLoad(self, self.JumpRelease)
end

function PetBallComponent:CancelJump(Pet, Queue, Session)
  if Session then
    Session.bHasPendingRelease = false
    Session:RecycleAllRes()
    Session:SetStatus(ThrowSessionStatusEnum.Destroyed)
  end
  if Queue then
    Queue:Release()
  end
  self:ReleaseFailedIfStop()
end

function PetBallComponent:JumpRelease(Queue, Success)
  local Session = self:GetThrowSession()
  local PetResObject = Queue:GetResObject("Pet")
  local Pet = PetResObject:Get()
  if not Success then
    self:CancelJump(Pet, Queue, Session)
    self:ShowTips("pet_eco_reject")
    return
  end
  if self:IsThrowSessionDestroyed() then
    self:CancelJump(Pet, Queue, Session)
    return
  end
  if self:IsThrowSessionRecycling() then
    self:CancelJump(Pet, Queue, Session)
    return
  end
  if self:IsThrowSessionWaitForRecycle() then
    self:CancelJump(Pet, Queue, Session)
    return
  end
  if PetResObject.Session ~= nil and PetResObject.Session ~= self.CurrentThrowSession then
    self:CancelJump(Pet, Queue, Session)
    return
  end
  local EQSObject = Queue:GetResObject("EQS")
  local Location
  if EQSObject then
    Location = EQSObject.AbsoluteLocations[1]
  else
    local ReleaseLocation = self.PetReleaseLocation
    if not ReleaseLocation then
      self:CancelJump(Pet, Queue, Session)
      return
    end
    Location = UE.FVector(ReleaseLocation.X, ReleaseLocation.Y, ReleaseLocation.Z + 35)
  end
  if Location then
    Location = ThrowUtils:TweakStandLocation(Location, Pet, Session.petData)
    Pet:SetActorLocation(Location)
  end
  Session:SetStatus(ThrowSessionStatusEnum.Releasing)
  if self.pendingNormalOptions and #self.pendingNormalOptions > 0 then
    local Owner = self.pendingNormalOptions[1].owner
    SceneUtils.LookAt(Pet, Owner)
    if Owner and Owner.viewObj then
      Pet:SetHeadLookAtActor(Owner.viewObj, true)
    end
  else
    local LookAtTarget = self.pendingSpecialAction and self.pendingSpecialAction:GetLookAtType() == Enum.PetReleaseLookAt.PRLA_TARGET_NPC
    if LookAtTarget then
      SceneUtils.LookAt(Pet, self.pendingSpecialAction:GetOwnerNPC())
      Pet:SetHeadLookAtActor(self.pendingSpecialAction:GetOwnerNPCView(), true)
    else
      local player = SceneUtils.GetPlayer()
      if player then
        SceneUtils.LookAt(Pet, player)
        Pet:SetHeadLookAtActor(player.viewObj, true)
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SyncPetCreate, Pet, _G.ProtoEnum.ClientCreatePetReason.CCPR_THROW)
  if self.pendingSpecialAction then
    self.pendingSpecialAction:SetBeforeActionSettings(Pet.viewObj)
  end
  local PetView = Pet.viewObj
  self:FixWaterLineIfInWater(PetView)
  self:StopMovement()
  if Pet.AIComponent then
    Pet.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.INTERACT)
  end
  if PetView.CharacterMovement then
    PetView.CharacterMovement:Deactivate()
  end
  local _, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(Pet.serverData.pet_info.gid)
  local MedalType
  if WearMedal then
    local medal_conf = _G.DataConfigManager:GetMedalConf(WearMedal.conf_id, true)
    if medal_conf then
      MedalType = medal_conf.fx_res
    end
  end
  local JumpSkill = PetView.RocoSkill:FindOrAddSkillObj(Queue:Get("Jump"))
  if not JumpSkill then
    Log.Error("PetBallComponent:JumpRelease Jumpskill is nil")
    return
  end
  JumpSkill:SetPriority(_G.PriorityEnum.Active_Throw_Pet)
  JumpSkill:SetAdditions("pet", Pet)
  if JumpSkill.Blackboard then
    JumpSkill.Blackboard:SetValueAsObject(PET_BALL_KEY, self:GetOwnerView())
    if MedalType then
      JumpSkill.Blackboard:SetValueAsString(MedalType, MedalType)
    end
  end
  JumpSkill:SetCaster(PetView)
  JumpSkill:RegisterEventCallback("End", self, self.ReleasePetComplete)
  JumpSkill:RegisterEventCallback("Interrupt", self, self.OnPetReleaseInterrupt)
  JumpSkill:RegisterEventCallback("PreEnd", self, self.ReleasePetComplete)
  JumpSkill:RegisterEventCallback("PreEndAnim", self, self.ReleasePetComplete)
  JumpSkill:RegisterEventCallback("HideBall", self, self.Hide)
  JumpSkill:RegisterEventCallback("ShowPet", self, self.ShowPet)
  JumpSkill:RegisterEventCallback("OutHarvest", self, self.CallOutHarvest)
  local Result = PetView.RocoSkill:LoadAndPlaySkill(JumpSkill)
  if Result == UE.ESkillStartResult.Success then
    PetView.bPlayingReleaseSkill = true
  else
    PetView.bPlayingReleaseSkill = false
  end
  Session.JumpSkill = JumpSkill
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ON_THROW_PET_CREATED, PetView)
end

function PetBallComponent:OnPetReleaseInterrupt(Name, SkillObject)
  self.LoadQueue:Release()
  self:TryRemovePetBall(SkillObject)
  local Session = self:GetThrowSession()
  if not Session then
    return
  end
  Session.JumpSkill = nil
  Session.bHasPendingRelease = false
  local pet = SkillObject:GetAddition("pet")
  if pet then
    if pet:IsVisibleForCallOutReason() then
      Session:Recycle(_G.ProtoEnum.RecycleThrowPetReason.RTPR_None)
      Session:ClearBall()
    else
      Session:RecycleBall()
      Session:ClearPet()
    end
  else
    Session:Recycle(_G.ProtoEnum.RecycleThrowPetReason.RTPR_None)
  end
end

function PetBallComponent:FixWaterLineIfInWater(PetView)
  local Pet = PetView.sceneCharacter
  local HalfHeight = Pet:GetScaledHalfHeight()
  local Location = PetView:K2_GetActorLocation()
  local surface_type = UE.UNRCStatics.CheckSurfaceTypeAtLocation(PetView, Location, math.max(HalfHeight + 1, 100))
  if 2 == surface_type then
    local CharacterMovement = PetView.CharacterMovement
    if not CharacterMovement or not CharacterMovement.IsEnableSwim then
      return
    end
    local OutSurface, OutWaterDepth, OutHit = UE.URocoMapUtils.GetSurface(PetView, Location, nil, nil, nil, UE.FVector(0, 0, -1))
    local PetWaterDepth = HalfHeight - CharacterMovement:GetSwimPosOffsetZ()
    local WaterHeight = OutHit.ImpactPoint.Z
    if 0 == OutWaterDepth or OutWaterDepth > PetWaterDepth then
      Location.Z = Location.Z - PetWaterDepth
      CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Swimming)
      CharacterMovement:OverrideNextDefaultMovementMode(UE.EMovementMode.MOVE_Swimming)
    else
      Location.Z = WaterHeight - OutWaterDepth + HalfHeight + 0.5
    end
    PetView:K2_SetActorLocation(Location, false, nil, false)
  end
end

function PetBallComponent:CallOutHarvest(Name, SkillObject)
  local pet = SkillObject:GetAddition("pet")
  if not pet then
    Log.Error("No pet!")
    return nil
  end
  local PetView = pet.viewObj
  if PetView then
    PetView.bPlayingReleaseSkill = false
  end
  Log.Debug("BP_NPCItemBase_C:CallOutHarvest", pet.ThrowSession:GetGID())
  if self.CurrentThrowSession and (self:IsThrowSessionDestroyed() or self:IsThrowSessionRecycling()) then
    return
  end
  pet:SendEvent(NPCModuleEvent.ON_HARVEST, pet)
  if self.pendingNormalOptions and #self.pendingNormalOptions > 0 then
    local InterComp = pet:EnsureComponent(PetInteractionComponent)
    InterComp:InstantHarvest(self.pendingNormalOptions)
    self.bAlreadyInteracted = true
  end
end

function PetBallComponent:ShowPet(Name, SkillObject)
  local pet = SkillObject:GetAddition("pet")
  if pet and pet.viewObj then
    pet:SetVisibleForCallOutReason(true)
  end
end

function PetBallComponent:Hide(Name, SkillObject)
  local pet = SkillObject:GetAddition("pet")
  if pet and pet.viewObj then
    pet:SetVisibleForCallOutReason(true)
  end
  local OwnerView = self:GetOwnerView()
  if OwnerView and OwnerView.SetActorScale3D then
    OwnerView:SetActorScale3D(_G.FVectorOne * 0.01)
  end
  self:TryRemovePetBall(SkillObject)
end

function PetBallComponent:ReleasePetComplete(Name, SkillObject)
  local Session = self:GetThrowSession()
  if Session then
    Session.JumpSkill = nil
  end
  self:TryRemovePetBall(SkillObject)
  local Ball = self:GetOwnerView()
  if UE4.UObject.IsValid(Ball) then
    Ball:SetActorHiddenInGame(true)
  end
  local pet = SkillObject:GetAddition("pet")
  if not pet then
    Log.Error("Pet Released but not found any more...")
  end
  if self.LoadQueue then
    self.LoadQueue:Release()
  end
  if self.CurrentThrowSession then
    if self.CurrentThrowSession.Status == ThrowSessionStatusEnum.Destroyed then
      return
    end
    if self.CurrentThrowSession.Status == ThrowSessionStatusEnum.Recycling then
      return
    end
    if not pet or pet.isDestroy then
      self.CurrentThrowSession:RecycleAllRes()
      return
    end
  end
  self.petReleaseFinished = true
  self:TryDoReleaseInteract()
end

function PetBallComponent:TryRemovePetBall(SkillObject)
  if not SkillObject or not UE.UObject.IsValid(SkillObject) then
    return
  end
  local PetBall = SkillObject.Blackboard:GetValueAsObject(PET_BALL_KEY)
  local Ball = self:GetOwnerView()
  if Ball == PetBall then
    SkillObject.Blackboard:RemoveObjectValue(PET_BALL_KEY)
  end
end

function PetBallComponent:TryDoReleaseInteract()
  local Session = self:GetThrowSession()
  Session:RemoveEventListener(self, ThrowSessionEvent.OnSyncPetCreateFinished, self.TryDoReleaseInteract)
  if self.petReleaseFinished and Session and Session.petSyncFinished then
    if self:IsThrowSessionWaitForRecycle() or self:IsThrowSessionDestroyed() or self:IsThrowSessionRecycling() then
      Log.Error("IsThrowSessionWaitForRecycle=", self:IsThrowSessionWaitForRecycle(), "IsThrowSessionDestroyed=", self:IsThrowSessionDestroyed(), "IsThrowSessionRecycling=", self:IsThrowSessionRecycling())
      Session:RecycleAllRes()
    else
      self:DoReleaseInteract()
    end
  elseif Session and not Session.petSyncFinished then
    Session:AddEventListener(self, ThrowSessionEvent.OnSyncPetCreateFinished, self.TryDoReleaseInteract)
  end
end

local EWaterState_EWS_DeepWater = UE.EWaterState.EWS_DeepWater

function PetBallComponent:DoReleaseInteract()
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: PetBallComponent:DoReleaseInteract", self.CurrentThrowSession and self.CurrentThrowSession.SeqID)
  self.owner:SetNotDestroyFlag(false)
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self.owner.viewObj, true)
  if self.CurrentThrowSession then
    self.CurrentThrowSession.Ball = nil
  end
  local pet = self.CurrentThrowSession and self.CurrentThrowSession.NPC
  local PetView = pet.viewObj
  if PetView then
    local Comp = PetView.CharacterMovement
    if Comp then
      Comp:Activate()
    end
  end
  if self.pendingSpecialAction then
    local InterComp = pet:EnsureComponent(PetInteractionComponent)
    local Success = InterComp and InterComp:InteractWithAction(self.pendingSpecialAction, false)
    if not Success then
      Log.Debug("\228\186\164\228\186\146\229\164\177\232\180\165\239\188\140\229\143\145\233\128\129EndThrow")
      self.CurrentThrowSession:SendFailEndThrowReq()
    end
  elseif self.pendingNormalOptions and #self.pendingNormalOptions > 0 then
    local InterComp = pet:EnsureComponent(PetInteractionComponent)
    InterComp:InteractWithOptions(self.pendingNormalOptions, self.bAlreadyInteracted)
  elseif self.pendingRandomOptions and #self.pendingRandomOptions > 0 then
    local InterComp = pet:EnsureComponent(PetInteractionComponent)
    InterComp:SendRandomOption(self.pendingRandomOptions)
    pet:EnsureComponent(PetHUDComponent):ForceUpdate()
    pet.ThrowSession:SetStatus(ThrowSessionStatusEnum.PostInteract)
  else
    self.CurrentThrowSession:NotifyCreatePet(self, self.PostPetCreation)
    local NeedRecycle = false
    local StandType = ThrowUtils:ToStandType(pet.ThrowSession.petData)
    if 0 == StandType then
      if PetView then
        local Location = PetView:K2_GetActorLocation()
        Location.Z = Location.Z - 5 - PetView:GetHalfHeight()
        local Type = UE.UNRCStatics.CheckSurfaceTypeAtLocation(PetView, Location, 100)
        if 1 ~= Type then
          local envInfo = PetView:GetComponentByClass(UE.UCharacterEnvInfoComponent)
          if envInfo then
            NeedRecycle = envInfo:GetWaterState() == EWaterState_EWS_DeepWater
          else
            NeedRecycle = true
          end
        end
        Log.WarningFormat("DoReleaseInteract: StandType=%d, CurrentType=%d, base_conf_id=%d", StandType, Type, pet.ThrowSession.petData.base_conf_id)
      else
        Log.ErrorFormat("DoReleaseInteract: PetView is gone , base_conf_id=%d", pet.ThrowSession.petData.base_conf_id)
      end
    end
    if NeedRecycle then
      pet.ThrowSession:SetStatus(ThrowSessionStatusEnum.PostInteract)
      pet.ThrowSession:Recycle()
    else
      pet:EnsureComponent(PetHUDComponent):ForceUpdate()
      pet.ThrowSession:SetStatus(ThrowSessionStatusEnum.PostInteract)
      pet.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
    end
  end
  pet.ThrowSession.bHasPendingRelease = false
  self.CurrentThrowSession = nil
  self.pendingSpecialAction = false
  self.pendingNormalOptions = false
  self.pendingRandomOptions = false
  self.bAlreadyInteracted = false
end

function PetBallComponent:IsThrowSessionDestroyed()
  local Session = self:GetThrowSession()
  if not Session then
    return true
  end
  return Session.Status == ThrowSessionStatusEnum.Destroyed
end

function PetBallComponent:IsThrowSessionRecycling()
  local Session = self:GetThrowSession()
  if not Session then
    return true
  end
  return Session.Status == ThrowSessionStatusEnum.Recycling
end

function PetBallComponent:IsThrowSessionWaitForRecycle()
  local Session = self:GetThrowSession()
  if not Session then
    return true
  end
  return Session.Status == ThrowSessionStatusEnum.WaitForRecycle
end

function PetBallComponent:GetThrowSession()
  if self.CurrentThrowSession then
    return self.CurrentThrowSession
  end
  local OwnerView = self:GetOwnerView()
  if not OwnerView then
    return nil
  end
  self.CurrentThrowSession = OwnerView.ThrowSession
  return self.CurrentThrowSession
end

function PetBallComponent:ToggleCollision(enable)
  local View = self:GetOwnerView()
  if View then
    View:ToggleCollision(enable)
  end
end

function PetBallComponent:TogglePhysics(enable)
  local View = self:GetOwnerView()
  if View then
    View:TogglePhysics(enable)
  end
end

function PetBallComponent:ReleaseFailedIfStop()
  local View = self:GetOwnerView()
  if View then
    View:ReleaseFailedIfStop()
  end
end

function PetBallComponent:StopMovement()
  local View = self:GetOwnerView()
  if View then
    View:StopMovement()
  end
end

function PetBallComponent:Log(Character, ...)
  if not Character.Watch then
    return
  end
  Log.Error(Character:DebugNPCNameAndID(), ...)
end

function PetBallComponent:ShowTips(TipsID)
  _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText[TipsID])
end

return PetBallComponent
