local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local RideAllAbility = Base:Extend("RideAllAbility")

function RideAllAbility:Init(abilityConf)
  Base.Init(self, abilityConf)
  self._buffName = "RideAll_Buff"
end

function RideAllAbility:Start(onFinished, customParams, ScenePet, RideMoveType, MovementId)
  Log.Debug("RideAllAbility Start")
  local isReConnect = false
  local rideComponent = self.caster.viewObj.BP_RideComponent
  if customParams and customParams.ride_param.double_ride_2p_id == self.caster.serverData.base.actor_id then
    if self.caster.IsMagicReplayActor and self.caster:IsMagicReplayActor() then
    else
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.caster:GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_RIDE_UPDATE)
    end
    self.caster.buffComponent:AddBuff(self._buffName, require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerRideAllBuff"), self.caster)
    local buff = self.caster.buffComponent:GetBuff(self._buffName)
    buff.waitDoubleRide = true
    return
  end
  if self.caster.isLocal and nil == ScenePet then
    if customParams and customParams.ride_param.ride_pet_gid then
      ScenePet = self.caster:GetPetByGid(customParams.ride_param.ride_pet_gid)
      isReConnect = true
      if customParams.ride_param.ride_move_mode then
        RideMoveType = customParams.ride_param.ride_move_mode
        local rideid = customParams.ride_param.ride_pet_id
        if not rideid or 0 == rideid or customParams.ride_param.ride_pet_gid <= 0 then
          self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
          return
        end
        local MovementList = DataConfigManager:GetAllRidePet(rideid).basic_movement_list
        for _, ListMovementId in pairs(MovementList) do
          local MoveConf = DataConfigManager:GetRideBasicMovement(ListMovementId)
          if MoveConf.move_type == RideMoveType then
            MovementId = ListMovementId
            break
          end
        end
      end
    end
    if nil == ScenePet then
      Log.Error("\229\133\168\231\178\190\231\129\181\233\170\145\228\185\152\229\143\172\229\148\164\230\151\160ScenePet")
      return
    end
  end
  Base.Start(self, onFinished)
  if not self.caster.isLocal then
    Log.Debug("\229\144\140\230\173\165\229\133\182\228\187\150\231\142\169\229\174\182\231\154\132\233\170\145\228\185\152\229\143\172\229\148\164")
    self:SyncStart(customParams)
    return
  end
  if rideComponent then
    local PetName
    local PetID = ScenePet.config.id
    local PetConf = DataConfigManager:GetAllRidePet(PetID)
    if rideComponent.bDebugRide then
      PetName = rideComponent.DebugRidePetName
    else
      PetName = PetConf.animation_name
    end
    if nil == PetName then
      return
    end
    local PetABP = string.format("/Game/ArtRes/AnimSequence/Pets/%s/ABP_RideAll_%s.ABP_RideAll_%s_C", PetName, PetName, PetName)
    local PetMesh = string.format("/Game/ArtRes/AnimSequence/Pets/%s/SKM_%s_Skin.SKM_%s_Skin", PetName, PetName, PetName)
    rideComponent:StopRide()
    rideComponent:BindScenePet(ScenePet, RideMoveType, MovementId)
    rideComponent.SyncDiffMat = customParams.ride_param.mutation_type
    rideComponent.SyncDiffNature = customParams.ride_param.relative_emotion
    rideComponent.GlassInfo = customParams.ride_param.glass_info
    if rideComponent.bIsLoading then
      rideComponent:OnRideFailed()
      return
    end
    local Scale = PetConf.model_scale / 100
    if PetConf.model_scale and 0 ~= PetConf.model_scale then
      Scale = PetConf.model_scale / 100
    else
      local PetBaseConf = DataConfigManager:GetPetbaseConf(PetID)
      if PetBaseConf then
        local modelConfId = PetBaseConf.model_conf
        local modelConf = DataConfigManager:GetModelConf(modelConfId)
        if modelConf and modelConf.model_scale and 0 ~= modelConf.model_scale then
          Scale = modelConf.model_scale / 100
        else
          Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\230\168\161\229\158\139\231\188\169\230\148\190 \230\136\150\231\188\169\230\148\190\230\149\176\230\141\174\229\188\130\229\184\184 ID = " .. modelConfId)
        end
      else
        Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\231\178\190\231\129\181Base ID = " .. PetID)
      end
    end
    if self.caster.IsMagicReplayActor and self.caster:IsMagicReplayActor() then
    else
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.caster:GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_RIDE_UPDATE)
    end
    ScenePet:SetRideParam(customParams.ride_param)
    ScenePet:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE, isReConnect)
    self.caster.buffComponent:AddBuff(self._buffName, require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerRideAllBuff"), self.caster, nil, nil, nil, self.isRecover)
    rideComponent:StartRide(PetMesh, PetABP, Scale)
  end
end

function RideAllAbility:Interrupt(owner)
  Log.Error("\233\170\145\228\185\152\229\188\128\229\167\139\231\154\132\230\138\128\232\131\189\228\184\141\229\186\148\232\175\165\229\173\152\229\156\168\230\137\147\230\150\173\239\188\140\229\188\186\232\161\140\229\129\156\230\173\162\230\138\128\232\131\189")
  self:Finish()
end

function RideAllAbility:Recover(owner, customParams, ...)
  self.isRecover = true
  self:Start(nil, customParams, ...)
  self.isRecover = false
end

function RideAllAbility:SyncStart(customParams)
  if nil == customParams then
    Log.Error("\229\176\157\232\175\149\232\191\155\232\161\140\233\170\145\228\185\152\229\144\140\230\173\165\230\151\182\239\188\140\230\178\161\230\156\137\230\148\182\229\136\176\233\170\145\228\185\152\229\143\130\230\149\176")
    return
  end
  local PetGID = customParams.ride_param.ride_pet_gid
  if self.caster.statusComponent._shouldWaitRecover and not self.caster.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    for _, v in pairs(self.caster.serverData.avatar_status.status_list) do
      if v == ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM then
        self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
        return
      end
    end
    if PetGID == -ProtoEnum.SceneRideAllCustomGid.SRCG_Transform then
      Log.Debug("RideAllAbility:SyncStart Ride Transform Pet but no Transform Status")
      self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      return
    end
  end
  local PetID = customParams.ride_param.ride_pet_id
  local rideComponent = self.caster.viewObj.BP_RideComponent
  if rideComponent then
    if self.caster.buffComponent:HasBuff(self._buffName) and self.caster.buffComponent:HasBuff("Transform_Buff") and rideComponent.ScenePet.config.id == PetID then
      Log.Debug("RideAllAbility: ride same pet while transforming")
      return
    end
    local PetName
    local PetConf = DataConfigManager:GetAllRidePet(PetID)
    PetName = PetConf.animation_name
    local PetABP = string.format("/Game/ArtRes/AnimSequence/Pets/%s/ABP_RideAll_%s.ABP_RideAll_%s_C", PetName, PetName, PetName)
    local PetMesh = string.format("/Game/ArtRes/AnimSequence/Pets/%s/SKM_%s_Skin.SKM_%s_Skin", PetName, PetName, PetName)
    local ScenePet = ScenePlayerPet(nil, PetID, PetGID, self.caster)
    ScenePet:SetRideParam(customParams.ride_param)
    rideComponent:StopRide()
    rideComponent:BindScenePet(ScenePet)
    rideComponent.SyncDiffMat = customParams.ride_param.mutation_type
    rideComponent.SyncDiffNature = customParams.ride_param.relative_emotion
    rideComponent.GlassInfo = customParams.ride_param.glass_info
    local Scale = PetConf.model_scale / 100
    if PetConf.model_scale and 0 ~= PetConf.model_scale then
      Scale = PetConf.model_scale / 100
    else
      local PetBaseConf = DataConfigManager:GetPetbaseConf(PetID)
      if PetBaseConf then
        local modelConfId = PetBaseConf.model_conf
        local modelConf = DataConfigManager:GetModelConf(modelConfId)
        if modelConf and modelConf.model_scale and 0 ~= modelConf.model_scale then
          Scale = modelConf.model_scale / 100
        else
          Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\230\168\161\229\158\139\231\188\169\230\148\190 \230\136\150\231\188\169\230\148\190\230\149\176\230\141\174\229\188\130\229\184\184 ID = " .. modelConfId)
        end
      else
        Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\231\178\190\231\129\181Base ID = " .. PetID)
      end
    end
    self.caster.buffComponent:AddBuff(self._buffName, require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerRideAllBuff"), self.caster, PetMesh, PetABP, Scale, self.isRecover)
  end
end

return RideAllAbility
