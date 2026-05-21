local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local RideAllMainAbility = require("NewRoco.Modules.Core.Scene.Component.Ability.RideAll.RideAllMainAbility")
local RideAllMainAbilityHelper = Base:Extend("RideAllMainAbilityHelper")

function RideAllMainAbilityHelper:CanCastAbility(caster)
  local SkillId = self:GetRideMainAbility(caster)
  if nil == SkillId or 0 == SkillId then
    return AbilityErrorCode.CAN_NOT_FIND_ABILITY
  end
  local isAreaBan = self:IsTaskAreaBan(caster)
  if isAreaBan then
    return AbilityErrorCode.TASK_AREA_BAN
  end
  local MoveInfo = DataConfigManager:GetRideBasicMovement(SkillId)
  if MoveInfo then
    if MoveInfo.active_type == ProtoEnum.SceneRideAllActiveType.SRAA_DASH_WITHOUT_VITALITY then
      local inCD = RideAllMainAbilityHelper.IsSkillInCooldown(caster, ProtoEnum.SceneRideAllActiveType.SRAA_DASH_WITHOUT_VITALITY)
      if inCD then
        return AbilityErrorCode.IN_COOLDOWN
      end
    end
    if MoveInfo.active_type == ProtoEnum.SceneRideAllActiveType.SRAA_DASH_DASHFORWARD then
      local inCD = RideAllMainAbilityHelper.IsSkillInCooldown(caster, ProtoEnum.SceneRideAllActiveType.SRAA_DASH_DASHFORWARD)
      if inCD then
        return AbilityErrorCode.IN_COOLDOWN
      end
    end
  end
  local MoveInfo = DataConfigManager:GetRideBasicMovement(SkillId)
  if MoveInfo then
    if MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_LEAP then
      local status = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY
      if caster.statusComponent:HasStatus(status) then
        local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
        if buff and buff.CanHandleRePress and not buff:CanHandleRePress() then
          return AbilityErrorCode.ABILITY_IS_CASTING
        end
      end
    end
    if not caster.vitalityComponent:IsVitalityEnough(MoveInfo.vitality_cost.min_start) then
      local canPlay = false
      local statusComponent = caster.statusComponent
      local status = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY
      if statusComponent:HasStatus(status) then
        local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
        if buff and buff.VitalityNotEnoughCanPlay and buff:VitalityNotEnoughCanPlay() then
          canPlay = true
        end
      end
      if not canPlay then
        return AbilityErrorCode.VITALITY_NOT_ENOUGH
      end
    end
    if MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_FLYUP then
      if table.contains(DataModelMgr.PlayerDataModel.ban_type, ProtoEnum.SceneRideAllType.SRAT_FLY) then
        return AbilityErrorCode.DUNGEON_BAN
      end
    elseif MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_CLIMBUP then
      local rideComponent = caster.viewObj.BP_RideComponent
      if rideComponent.RidePet.CharacterClimbMovement and rideComponent.RidePet.CharacterClimbMovement:IsClimbDashing() then
        return AbilityErrorCode.ABILITY_IS_CASTING
      end
    elseif MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_JUMP or MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_SWIMJUMP then
      local rideComponent = caster.viewObj.BP_RideComponent
      if rideComponent.RidePet.CharacterMovement and not rideComponent.RidePet.CharacterMovement:CanJump() then
        return AbilityErrorCode.ABILITY_IS_CASTING
      end
    elseif MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_CLIMB_WATER_JUMP then
      local rideComponent = caster.viewObj.BP_RideComponent
      if rideComponent.RidePet.CharacterClimbWaterFallMovement and rideComponent.RidePet.CharacterClimbWaterFallMovement:IsClimbDashing() then
        return AbilityErrorCode.ABILITY_IS_CASTING
      end
    elseif MoveInfo.active_type == Enum.SceneRideAllActiveType.SRAA_KEEP_BALANCE then
      local rideComponent = caster.viewObj.BP_RideComponent
      if rideComponent:IsInDoubleRide() then
        return AbilityErrorCode.ABILITY_IS_CASTING
      end
    end
  end
  return Base.CanCastAbility(self, caster)
end

function RideAllMainAbilityHelper:GetSkillActiveType(caster)
  local SkillId = self:GetRideMainAbility(caster)
  if nil == SkillId or 0 == SkillId then
    return nil
  end
  local MoveInfo = DataConfigManager:GetRideBasicMovement(SkillId)
  if MoveInfo then
    return MoveInfo.active_type
  end
  return nil
end

function RideAllMainAbilityHelper:IsTaskAreaBan(caster)
  local rideComponent = caster.viewObj.BP_RideComponent
  if not (rideComponent.RidePet and rideComponent.ScenePet) or not rideComponent.ScenePet.config then
    return nil
  end
  local petID = rideComponent.ScenePet.config.id
  local MovementList = DataConfigManager:GetAllRidePet(petID).basic_movement_list
  for _, MovementId in pairs(MovementList) do
    local MoveConf = DataConfigManager:GetRideBasicMovement(MovementId)
    if caster.taskAreaRideAllBanType and caster.taskAreaRideAllBanType[MoveConf.move_type] then
      return true
    end
  end
  return false
end

function RideAllMainAbilityHelper:IsLongPressAbility(caster)
  local SkillId = self:GetRideMainAbility(caster)
  local SkillConf = DataConfigManager:GetRideBasicMovement(SkillId, true)
  if nil == SkillConf then
    return false
  end
  if SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_POWERDASH or SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_GRAPPLE or SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_DOUBLERIDE then
    return true
  end
  return false
end

function RideAllMainAbilityHelper:GetRideMainAbility(caster)
  local rideComponent = caster.viewObj.BP_RideComponent
  if not (rideComponent.RidePet and rideComponent.ScenePet) or not rideComponent.ScenePet.config then
    return nil
  end
  local moveId = rideComponent.RideMovementId
  local RideConf = DataConfigManager:GetAllRidePet(rideComponent.ScenePet.config.id)
  if 0 == moveId and rideComponent.RidePet.CharacterMovement:IsJumping() then
    if self.lastRidePetId == rideComponent.ScenePet.config.id then
      local jumpConf = DataConfigManager:GetRideBasicMovement(self.lastRidePetSkillId, true)
      if jumpConf and (jumpConf.active_type == Enum.SceneRideAllActiveType.SRAA_JUMP or jumpConf.active_type == Enum.SceneRideAllActiveType.SRAA_SWIMJUMP) then
        return self.lastRidePetSkillId
      end
    end
    for index, moveid in pairs(RideConf.basic_movement_list) do
      local moveConf = DataConfigManager:GetRideBasicMovement(moveid)
      if moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_GROUND then
        local jumpSkill = RideConf.active_skill_list[index]
        local jumpConf = DataConfigManager:GetRideBasicMovement(jumpSkill, true)
        if jumpConf and jumpConf.active_type == Enum.SceneRideAllActiveType.SRAA_JUMP then
          return jumpSkill
        end
      end
    end
  end
  local abilityId
  for index, value in pairs(RideConf.active_skill_list) do
    local skillConf = DataConfigManager:GetRideBasicMovement(value, true)
    if skillConf and (skillConf.active_type == Enum.SceneRideAllActiveType.SRAA_GRAPPLE or skillConf.active_type == Enum.SceneRideAllActiveType.SRAA_LEAP) then
      abilityId = value
    end
    if skillConf and skillConf.active_type == Enum.SceneRideAllActiveType.SRAA_DOUBLERIDE then
      if rideComponent.RidePet.Rider == caster.viewObj then
        return value
      else
        return nil
      end
    end
    local skillMovementId = RideConf.basic_movement_list[index]
    if moveId == skillMovementId then
      return value
    end
  end
  return abilityId
end

function RideAllMainAbilityHelper:GetIcon(caster, isBlock)
  local OriginId = self:GetRideMainAbility(caster)
  local SkillId = OriginId
  local rideComponent = caster.viewObj.BP_RideComponent
  if rideComponent.ScenePet == nil or nil == rideComponent.ScenePet.config then
    return nil
  end
  if rideComponent.bIsLoading then
    return nil
  end
  if nil == SkillId or 0 == SkillId then
    local petId = rideComponent.ScenePet.config.id
    if self.lastRidePetId == petId then
      SkillId = self.lastRidePetSkillId
    else
      local RideConf = DataConfigManager:GetAllRidePet(petId, true)
      if nil == RideConf then
        return nil
      end
      SkillId = RideConf.active_skill_list[1]
    end
    if nil == SkillId then
      return nil
    end
  end
  local SkillConf = DataConfigManager:GetRideBasicMovement(SkillId, true)
  if nil == SkillConf then
    return nil
  end
  self.lastRidePetId = rideComponent.ScenePet.config.id
  self.lastRidePetSkillId = SkillId
  local UIconf = DataConfigManager:GetAllRideUiConf(10000 + tonumber(SkillConf.active_type))
  local bUseConf2 = false
  local customParams = caster.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if customParams and nil ~= customParams.ride_param.double_ride_2p_id and customParams.ride_param.double_ride_2p_id > 0 then
    bUseConf2 = true
  end
  if self:CanCastAbility(caster) ~= AbilityErrorCode.NO_ERROR and nil ~= rideComponent.RidePet then
    return bUseConf2 and UIconf.button_block_icon_2 or UIconf.button_block_icon
  end
  isBlock = self:IsBlock(caster)
  if SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_LEAP then
    if isBlock then
      local statusComponent = caster.statusComponent
      local status = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY
      if statusComponent:HasStatus(status) then
        local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
        if buff and buff.CanHandleRePress and buff:CanHandleRePress() then
          isBlock = false
        end
        if buff and 1 == buff.curSkillStage then
          bUseConf2 = true
        end
      end
    elseif rideComponent.RidePet.InLeap then
      isBlock = true
    end
  elseif SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_JUMP or SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_SWIMJUMP then
    if not isBlock and rideComponent.RidePet and rideComponent.RidePet.CharacterMovement and not rideComponent.RidePet.CharacterMovement:CanJump() then
      isBlock = true
    end
  elseif SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_KEEP_BALANCE and not isBlock and rideComponent:IsInDoubleRide() then
    isBlock = true
  end
  if isBlock then
    return bUseConf2 and UIconf.button_block_icon_2 or UIconf.button_block_icon
  end
  return bUseConf2 and UIconf.button_icon_2 or UIconf.button_icon
end

function RideAllMainAbilityHelper:GetPressIcon(caster)
  local OriginId = self:GetRideMainAbility(caster)
  local SkillId = OriginId
  local rideComponent = caster.viewObj.BP_RideComponent
  if rideComponent.ScenePet == nil then
    return nil
  end
  if rideComponent.bIsLoading then
    return nil
  end
  if nil == SkillId or 0 == SkillId then
    local petId = rideComponent.ScenePet.config.id
    if self.lastRidePetId == petId then
      SkillId = self.lastRidePetSkillId
    else
      local RideConf = DataConfigManager:GetAllRidePet(petId, true)
      if nil == RideConf then
        return nil
      end
      SkillId = RideConf.active_skill_list[1]
    end
    if nil == SkillId then
      return nil
    end
  end
  local SkillConf = DataConfigManager:GetRideBasicMovement(SkillId, true)
  if nil == SkillConf then
    return nil
  end
  self.lastRidePetId = rideComponent.ScenePet.config.id
  self.lastRidePetSkillId = SkillId
  local UIconf = DataConfigManager:GetAllRideUiConf(10000 + tonumber(SkillConf.active_type))
  local bUseConf2 = false
  local customParams = caster.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if customParams and nil ~= customParams.ride_param.double_ride_2p_id and customParams.ride_param.double_ride_2p_id > 0 then
    bUseConf2 = true
  end
  if SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_LEAP then
    local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
    if buff and 1 == buff.curSkillStage then
      bUseConf2 = true
    end
  end
  return bUseConf2 and UIconf.button_press_icon_2 or UIconf.button_press_icon
end

function RideAllMainAbilityHelper:GetHelper(caster)
  return false
end

function RideAllMainAbilityHelper:HandleStatus(caster, ...)
  local statusComponent = caster.statusComponent
  local status = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY
  if statusComponent:HasStatus(status) then
    local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
    if buff and buff.HandleRePress and buff:HandleRePress() then
      return
    end
    statusComponent:RemoveStatus(status, nil, 1, ...)
  else
    local SkillId = self:GetRideMainAbility(caster) or 0
    local rideSkillParam = ProtoMessage:newPlayerRideSkillStatusParams()
    rideSkillParam.skill_id = SkillId
    rideSkillParam.skill_stage = 1
    local customParams = (...) or {}
    customParams.ride_skill_param = rideSkillParam
    statusComponent:ApplyStatus(status, nil, 1, customParams)
  end
end

local CooldownState = {}

function RideAllMainAbilityHelper.IsSkillInCooldown(caster, skillType)
  if not caster then
    return false
  end
  local playerID = caster:GetServerId()
  if 0 == playerID then
    return false
  end
  if not CooldownState[playerID] then
    return false
  end
  local playerCooldown = CooldownState[playerID]
  if not playerCooldown[skillType] then
    return false
  end
  local cooldownEndTime = playerCooldown[skillType]
  local currentTime = os.msTime()
  return cooldownEndTime > currentTime
end

function RideAllMainAbilityHelper.GetSkillLeftCooldown(caster, skillType)
  if not caster then
    return 0
  end
  local playerID = caster:GetServerId()
  if 0 == playerID then
    return 0
  end
  if not CooldownState[playerID] then
    return 0
  end
  local playerCooldown = CooldownState[playerID]
  if not playerCooldown[skillType] then
    return 0
  end
  local cooldownEndTime = playerCooldown[skillType]
  local currentTime = os.msTime()
  local leftTime = (cooldownEndTime - currentTime) / 1000
  return math.max(0, leftTime)
end

function RideAllMainAbilityHelper.StartSkillCooldown(caster, skillType, cooldownTime)
  if not caster then
    return
  end
  local playerID = caster:GetServerId()
  if 0 == playerID then
    return
  end
  if not CooldownState[playerID] then
    CooldownState[playerID] = {}
  end
  local playerCooldown = CooldownState[playerID]
  local COOLDOWN_TIME_MS = cooldownTime * 1000
  local currentTime = os.msTime()
  playerCooldown[skillType] = currentTime + COOLDOWN_TIME_MS
  Log.Error(string.format("\230\138\128\232\131\189 %s \229\188\128\229\167\139\229\134\183\229\141\180\239\188\140\229\134\183\229\141\180\230\151\182\233\151\180\239\188\154%d\231\167\146", tostring(skillType), cooldownTime))
end

return RideAllMainAbilityHelper
