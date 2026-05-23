local Base = require("NewRoco.Modules.Core.Scene.Actor.SceneActor")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SummonPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SummonPetComponent")
local PassiveSkillComponent = require("NewRoco.Modules.Core.Scene.Component.RidePet.RidePetPassiveSkillComponent")
local RemotePlayerRidePetPassiveSkillComponent = require("NewRoco.Modules.Core.Scene.Component.RidePet.RemotePlayerRidePetPassiveSkillComponent")
local ScenePlayerPet = Base:Extend("ScenePlayerPet")

function ScenePlayerPet:Ctor(module, id, gid, owner, petData, isInMainTeam)
  Base.Ctor(self, module)
  self.TalentEffectMap = {}
  self.isInMainTeam = isInMainTeam
  self.rideFriendUin = nil
  self:RefreshData(module, id, gid, owner)
  self:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG)
  self._petData = petData
end

function ScenePlayerPet:InitComponent()
  if self.config then
    self.rideConfig = DataConfigManager:GetAllRidePet(self.config.id, true)
  end
  if self.rideConfig then
    if self.owner.isLocal then
      self:EnsureComponent(PassiveSkillComponent)
    else
      self:EnsureComponent(RemotePlayerRidePetPassiveSkillComponent)
    end
  end
end

function ScenePlayerPet:SetRideParam(param)
  self.ride_param = param
end

function ScenePlayerPet:SetViewObj(viewObj)
  Base.SetViewObj(self, viewObj)
  if viewObj then
    if viewObj.RocoAudio and self.config then
      viewObj.RocoAudio:SetPetBaseId(self.config.id)
    else
      Log.Warning("ScenePlayerPet:SetViewObj Audio Fail", viewObj.RocoAudio, self.config)
    end
    local pet_voice = self.ride_param and self.ride_param.pet_voice
    if pet_voice then
      _G.NRCAudioManager:SetEmitterRTPC("Pet_Vo_Pitch", pet_voice, viewObj)
    end
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_World", viewObj)
  end
end

function ScenePlayerPet:OnRideSuccess()
  if self.RidePetPassiveSkillComponent then
    self.RidePetPassiveSkillComponent:OnRideSuccess()
  elseif self.RemotePlayerRidePetPassiveSkillComponent then
    self.RemotePlayerRidePetPassiveSkillComponent:OnRideSuccess()
  end
end

function ScenePlayerPet:RefreshData(module, id, gid, owner, isInMainTeam)
  self.owner = owner
  self:SetInMainTeam(isInMainTeam)
  if self.config == nil or nil == self.gid or self.config.id ~= id or self.gid ~= gid then
    self:RecycleFriendPet()
    self:ResetStatus()
    self.config = _G.DataConfigManager:GetPetbaseConf(id)
    self.gid = gid
    self.canDoubleRide = nil
    if not self.config then
      return
    end
    local bRidePetPassiveSkillComponentCreated = nil ~= self.RidePetPassiveSkillComponent
    self:InitComponent()
    if bRidePetPassiveSkillComponentCreated and self.RidePetPassiveSkillComponent then
      self.RidePetPassiveSkillComponent:RebuildPassiveSkills()
    end
    if self.config.scene_ability > 0 then
      local sceneAbilityConf = DataConfigManager:GetSceneAbilityConf(self.config.scene_ability)
      self.abilityType = sceneAbilityConf.scene_ability_type
    else
      self.abilityType = -1
    end
  end
end

function ScenePlayerPet:SetInMainTeam(isInMainTeam)
  if self.isInMainTeam ~= isInMainTeam then
    self.isInMainTeam = isInMainTeam
    if not self.isInMainTeam then
      self:RecycleFriendPet()
    end
  end
end

function ScenePlayerPet:RecycleFriendPet()
  if self.rideFriendUin then
    local req = ProtoMessage:newZoneSceneRecycleFriendRidePetReq()
    req.friend_uin = self.rideFriendUin
    self.rideFriendUin = nil
    _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RECYCLE_FRIEND_RIDE_PET_REQ, req)
  end
end

function ScenePlayerPet:SetStatus(status, isReConnect)
  if self._status ~= status then
    if status == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
      if self.owner and self.owner.isLocal then
        local Comp = self.owner:EnsureComponent(SummonPetComponent)
        Comp:Recall(self.gid, false)
      end
      self:RecycleFriendPet()
    end
    self._status = status
    self:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, 1, self)
  end
end

function ScenePlayerPet:NotifySeverRideStatus(isInRide)
end

function ScenePlayerPet:OnNotifiedSeverRideStatus(rsp)
end

function ScenePlayerPet:RemoveStatus(status)
  if self._status == status then
    self._status = nil
    self:SendEvent(PlayerModuleEvent.ON_STATUS_CHANGED, status, 0, self)
  end
end

function ScenePlayerPet:GetStatus()
  local status = self._status or ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG
  return status
end

function ScenePlayerPet:IsFlyPet()
  if self.rideConfig then
    local movementList = self.rideConfig.basic_movement_list
    for i = 1, #movementList do
      local movementId = movementList[i]
      local movementConfig = DataConfigManager:GetRideBasicMovement(movementId)
      if movementConfig.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY then
        return true
      end
    end
  end
  return false
end

function ScenePlayerPet:IsRidePet()
  return self.abilityType == Enum.SceneAbilityType.SCAT_RIDE
end

function ScenePlayerPet:Destroy()
  self:SetInMainTeam(false)
  self:ResetStatus()
  self.config = nil
  self.owner = nil
  self.canDoubleRide = nil
  Base.Destroy(self)
end

function ScenePlayerPet:FindThrowSession()
  return ThrowSession.GetWithGID(self.gid)
end

function ScenePlayerPet:GetThrowStatus()
  local Session = self:FindThrowSession()
  if Session then
    return self.ThrowSession.Status
  else
    return ThrowSessionStatusEnum.Destroyed
  end
end

function ScenePlayerPet:ThrowRecycle()
  local Session = self:FindThrowSession()
  if Session then
    self.ThrowSession:Recycle()
  end
end

function ScenePlayerPet:ResetStatus()
  if self.gid then
    if self._status == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
      if not self.owner.viewObj.BP_RideComponent:TryChangeToLink() then
        self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
        self:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG)
      end
    elseif self._status == _G.ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_INTERACT then
      self:SetStatus(_G.ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG)
    end
  end
end

function ScenePlayerPet:IsInRide()
  return self._status and self._status == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE
end

function ScenePlayerPet:GetPetData()
  if self._petData then
    return self._petData
  end
  return DataModelMgr.PlayerDataModel:GetPetDataByGid(self.gid)
end

function ScenePlayerPet:GetAllEffectTalent()
  local petData = self:GetPetData()
  if petData then
    if not petData.real_speciality_ids then
      return nil
    end
    if self:SafeCheckTalent(petData.real_speciality_ids) then
      return petData.real_speciality_ids
    else
      local res = {}
      for _, v in pairs(petData.real_speciality_ids) do
        local SafeTalent = self:GetSafeTalent(v)
        if SafeTalent then
          table.insert(res, SafeTalent)
        end
      end
      return res
    end
  else
    return nil
  end
end

function ScenePlayerPet:GetSafeTalent(talent_id, turns)
  if nil == talent_id then
    return nil
  end
  turns = turns or 0
  turns = turns + 1
  if turns > 5 then
    Log.Error("\230\159\165\230\137\190\230\155\191\230\141\162\231\137\185\233\149\191\230\151\182\233\128\146\229\189\146\230\172\161\230\149\176\232\191\135\229\164\154\239\188\129")
    return nil
  end
  local TalentConf = DataConfigManager:GetPetTalentConf(talent_id, true)
  if TalentConf then
    if TalentConf.remove then
      return self:GetSafeTalent(TalentConf.new_talent_id, turns)
    else
      return talent_id
    end
  end
  return nil
end

function ScenePlayerPet:SafeCheckTalent(real_speciality_ids)
  if not real_speciality_ids then
    return false
  end
  for _, v in pairs(real_speciality_ids) do
    local TalentConf = DataConfigManager:GetPetTalentConf(v, true)
    if not TalentConf or TalentConf.remove then
      return false
    end
  end
  return true
end

function ScenePlayerPet:OnTalentUpdate()
  if not self.gid or not self.config then
    return
  end
  if self.owner and self.owner.isLocal and UE.UObject.IsValid(self.owner.viewObj) then
    local RideComponent = self.owner.viewObj.BP_RideComponent
    self.canDoubleRide = RideComponent:IsDoubleRidePet(self, false)
    self:SendEvent(PlayerModuleEvent.ON_RIDEPET_TALENT_CHANGE)
  end
end

function ScenePlayerPet:ContainsRealSpecialityEffect(HasEffect, bCheckActive)
  local PetData = self:GetPetData()
  if not PetData or not PetData.real_speciality_ids then
    return false, nil
  end
  for _, v in pairs(PetData.real_speciality_ids) do
    local TalentConf = _G.DataConfigManager:GetPetTalentConf(v, true)
    local ContainEffect = false
    local EffectParam
    if TalentConf then
      for _, Effect in pairs(TalentConf.effect_group) do
        if Effect.effect == HasEffect then
          ContainEffect = true
          EffectParam = Effect.effect_param
          break
        end
      end
    end
    if bCheckActive and ContainEffect then
      ContainEffect = self:CheckIsTalentActive(TalentConf)
    end
    if ContainEffect then
      return true, EffectParam
    end
  end
  return false, nil
end

local EnvSystemModule

local function GetEnvSystem()
  if not EnvSystemModule then
    EnvSystemModule = _G.NRCModuleManager:GetModule("EnvSystemModule")
  end
  return EnvSystemModule
end

function ScenePlayerPet:CheckIsTalentActive(TalentConf)
  local isActive = true
  for _, Condition_group in pairs(TalentConf.condition_group) do
    local condition = Condition_group.talent_condition
    local condition_param = Condition_group.talent_condition_param
    if condition == Enum.PetTalentCondition.PTC_GAME_TIME then
      if condition_param then
        local CurTime = math.floor(GetEnvSystem():GetCurrentTime() / 3600.0)
        local TimeLeft = condition_param[1]
        local TimeRight = condition_param[2]
        if TimeLeft < TimeRight then
          if not (CurTime >= TimeLeft) or not (CurTime < TimeRight) then
            isActive = false
          end
        elseif not (CurTime >= TimeLeft) and not (CurTime < TimeRight) then
          isActive = false
        end
      end
    elseif condition == Enum.PetTalentCondition.PTC_EQUIP_BADGE then
      local _, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.gid)
      if not WearMedal then
        isActive = false
      end
    end
    if not isActive then
      break
    end
  end
  return isActive
end

function ScenePlayerPet:OnSetDoubleRide2P(isOnPet, player2P)
  if self.RidePetPassiveSkillComponent then
    self.RidePetPassiveSkillComponent:OnSetDoubleRide2P(isOnPet, player2P)
  elseif self.RemotePlayerRidePetPassiveSkillComponent then
    self.RemotePlayerRidePetPassiveSkillComponent:OnSetDoubleRide2P(isOnPet, player2P)
  end
end

return ScenePlayerPet
