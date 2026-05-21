local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local ThrowUtils = {}

function ThrowUtils.ShakeTrees(Location, Range, OutTreePosArray)
  local World = _G.UE4Helper.GetCurrentWorld()
  UE.UNRCStatics.BatchShakeTrees(World, Location, Range, OutTreePosArray)
end

function ThrowUtils.GatherMagicActions(Caster, RelativeLocation, MagicID, ChargeLevel, Range, FilterFunc, hitActor, hitActorBone)
  local World = _G.UE4Helper.GetCurrentWorld()
  local CasterView = Caster and Caster.viewObj
  local CachedIgnoreActors = {}
  if CasterView then
    table.insert(CachedIgnoreActors, CasterView)
  end
  if not RelativeLocation and CasterView then
    RelativeLocation = CasterView:K2_GetActorLocation()
  end
  local drawDebugTrace = UE4.EDrawDebugTrace.None
  local hitResults, isHit = UE4.UKismetSystemLibrary.SphereTraceMultiByProfile(World, RelativeLocation, RelativeLocation, Range, "ThrowedItem", false, CachedIgnoreActors, drawDebugTrace, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), 999)
  local Actions = {}
  local TargetInfos = {}
  local Players = {}
  local CharacterCheckedMap = {}
  for i = hitResults:Length(), 1, -1 do
    local Hit = hitResults:Get(i)
    local Actor = Hit.Actor
    if not Actor then
    else
      local Character = Actor and Actor.sceneCharacter
      if Character then
        if Character.IsHidden and Character:IsHidden() then
        else
          if CharacterCheckedMap[Character] then
            goto lbl_201
          else
            CharacterCheckedMap[Character] = true
          end
          if FilterFunc and not FilterFunc(Character) then
          else
            if Actor:Cast(UE4.ARocoPlayerBase) and Character and not Character.isLocal then
              local playerUin = Character.serverData.base.logic_id
              table.insert(Players, playerUin)
            end
            local InterComp = Character and Character.InteractionComponent
            local Options = InterComp and InterComp._options
            local weak_point_name
            if hitActor and Actor == hitActor then
              weak_point_name = hitActorBone
            end
            if Options then
              for _, value in pairs(Options) do
                local ValidOption
                local MagicActions = value:EnsureMagicActions()
                for _, Action in pairs(MagicActions) do
                  if Action:CanExecute(Character, ChargeLevel, MagicID, RelativeLocation) then
                    Action:Execute(Character, Caster)
                    table.insert(Actions, Action)
                    if Action.Config.action_type ~= _G.Enum.ActionType.ACT_TRIGGER_OPTION_ACTION then
                      ValidOption = value
                    end
                  end
                end
                if ValidOption then
                  local TargetInfo = _G.ProtoMessage:newThrowTargetNpcInfo()
                  TargetInfo.npc_id = Character.serverData.base.actor_id
                  TargetInfo.option_id = value.optionInfo.option_id
                  TargetInfo.weakness_pos_name = weak_point_name
                  Character:GetServerPosition(TargetInfo.npc_pos)
                  table.insert(TargetInfos, TargetInfo)
                end
              end
            end
          end
        end
      end
    end
    ::lbl_201::
  end
  table.clear(CachedIgnoreActors)
  table.clear(CharacterCheckedMap)
  return Actions, TargetInfos, Players
end

function ThrowUtils:ToStandType(petData)
  local Hab = self:GetPetHabitat(petData)
  Log.Warning(petData.name, table.getKeyName(Enum.HABITAT_FLAG, Hab))
  if Hab == Enum.HABITAT_FLAG.HAB_WATER then
    return 1
  elseif Hab == Enum.HABITAT_FLAG.HAB_AQUA then
    return 2
  elseif Hab == Enum.HABITAT_FLAG.HAB_FLY or Hab == Enum.HABITAT_FLAG.HAB_FLY_WATER then
    if SceneUtils.InHomeScene() then
      return 0
    else
      return 3
    end
  else
    local Eco = self:GetPetEcology(petData)
    if Eco == Enum.ECOLOGY_FEATURE.ECO_ICE_ELEMENT then
      return 1
    else
      return 0
    end
  end
end

function ThrowUtils:GetPetEcology(petData)
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
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

function ThrowUtils:GetPetHabitat(petData)
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
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

function ThrowUtils:TweakStandLocation(Location, Pet, PetData)
  if not Pet.viewObj then
    Log.Error("ThrowUtils:TweakStandLocation, Pet.viewObj is nil")
    return Location
  end
  local RelativeLocation = SceneUtils.ConvertAbsoluteToRelative(Location)
  local Type = UE.UNRCStatics.CheckSurfaceTypeAtLocation(Pet.viewObj, RelativeLocation, 100)
  Log.Warning("Standing on", Type)
  local MoveComp = Pet.viewObj.CharacterMovement
  if 2 == Type then
    local HalfHeight = Pet:GetScaledHalfHeight()
    Location.Z = Location.Z + HalfHeight
    if MoveComp then
      if MoveComp.IsEnableSwim then
      end
      local Habit = ThrowUtils:GetPetHabitat(PetData)
      if Habit == Enum.HABITAT_FLAG.HAB_FLY then
        MoveComp:SetMovementMode(UE.EMovementMode.MOVE_Flying)
        MoveComp:OverrideNextDefaultMovementMode(UE.EMovementMode.MOVE_Flying)
        Location.Z = Location.Z + MoveComp.FlyAboveWaterOffsetZ
      end
    end
  else
    if 3 == Type then
      MoveComp:SetMovementMode(UE.EMovementMode.MOVE_Flying)
      MoveComp:OverrideNextDefaultMovementMode(UE.EMovementMode.MOVE_Flying)
    end
    Location.Z = Location.Z + Pet:GetScaledHalfHeight()
  end
  return Location
end

function ThrowUtils.CheckActionEffectInAnglesForward(Runner, RelativeLocation, MinAngle, MaxAngle)
  if MinAngle > 180 or MinAngle < -180 or MaxAngle > 180 or MaxAngle < -180 then
    return nil, true
  end
  if MinAngle == MaxAngle then
    return nil, true
  end
  local RunnerLocation = RelativeLocation
  local RunnerSkeMesh = Runner.viewObj:GetComponentByClass(UE.USkeletalMeshComponent)
  if RunnerSkeMesh then
    RunnerLocation = RunnerSkeMesh:GetSocketLocation("locator_body")
  elseif Runner.viewObj and UE4.UObject.IsValid(Runner.viewObj) then
    RunnerLocation = Runner.viewObj:K2_GetActorLocation()
  end
  local RunnerToHitVector = RelativeLocation - RunnerLocation
  RunnerToHitVector.Z = 0
  RunnerToHitVector:Normalize()
  local ForwardVector = Runner.viewObj:GetActorForwardVector()
  ForwardVector.Z = 0
  ForwardVector:Normalize()
  local CrossVector = ForwardVector:Cross(RunnerToHitVector)
  local Direction = CrossVector.Z > 0 and 1 or -1
  local InnerCos = math.clamp(RunnerToHitVector:Dot(ForwardVector), -1, 1)
  local Degree = Direction * math.deg(math.acos(InnerCos))
  Degree = (Degree + 180) % 360 - 180
  if MinAngle <= MaxAngle then
    return Degree, MinAngle <= Degree and MaxAngle >= Degree
  else
    return Degree, MinAngle <= Degree or MaxAngle >= Degree
  end
end

function ThrowUtils.CheckActionEffectInAnglesVertical(Runner, RelativeLocation, ZAngle)
  local RunnerSkeMesh = Runner.viewObj:GetComponentByClass(UE.USkeletalMeshComponent)
  if not RunnerSkeMesh then
    return nil, false
  end
  local RunnerLocation = RunnerSkeMesh:GetSocketLocation("locator_body")
  if 0 == ZAngle then
    return nil, false
  end
  ZAngle = ZAngle / 2.0
  if ZAngle > 180 or ZAngle < -180 then
    return nil, true
  end
  local RunnerToHitVector = RelativeLocation - RunnerLocation
  RunnerToHitVector:Normalize()
  local innerCos = math.clamp(UE.UKismetMathLibrary.Dot_VectorVector(RunnerToHitVector, UE4Helper.UpVector), -1, 1)
  local degree = math.deg(math.acos(innerCos))
  if ZAngle > 0 then
    if degree >= -ZAngle and ZAngle >= degree then
      return degree, true
    else
      return degree, false
    end
  elseif degree >= -ZAngle and degree <= 180 or degree >= -180 and ZAngle >= degree then
    return degree, true
  else
    return degree, false
  end
end

function ThrowUtils.IsDisableByMutation(CatchTarget, ballId)
  local serverData = CatchTarget and CatchTarget.serverData
  local npc_base = serverData and serverData.npc_base
  local mutation_type = npc_base and npc_base.mutation_type
  if not mutation_type or 0 == mutation_type then
    return false, ""
  end
  local BallForbidCaptureConfig = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.BALL_FORBID_CAPTURE)
  for _, BallForbidCapture in ipairs(BallForbidCaptureConfig) do
    if PetMutationUtils.GetMutationValue(mutation_type, BallForbidCapture.mutation_type) then
      if BallForbidCapture.whitelist_ball_id and #BallForbidCapture.whitelist_ball_id > 0 then
        if not table.contains(BallForbidCapture.whitelist_ball_id, ballId) then
          return true, BallForbidCapture.forbid_tips
        end
      elseif BallForbidCapture.blacklist_ball_id and #BallForbidCapture.blacklist_ball_id > 0 and table.contains(BallForbidCapture.blacklist_ball_id, ballId) then
        return true, BallForbidCapture.forbid_tips
      end
    end
  end
  return false, ""
end

return ThrowUtils
