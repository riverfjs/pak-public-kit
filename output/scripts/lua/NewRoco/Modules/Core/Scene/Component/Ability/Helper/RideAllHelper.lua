local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RideAllHelper = Base:Extend("RideAllHelper")

function RideAllHelper:CanCastAbility(caster, pet)
  if not pet or not pet.config then
    return AbilityErrorCode.CAN_NOT_FIND_ABILITY
  end
  local buffComp = caster.buffComponent
  local RideAllBuff = buffComp:GetBuff("RideAll_Main_Buff")
  if RideAllBuff and RideAllBuff.CanOffPet and not RideAllBuff:CanOffPet() then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  local petID = pet.config.id
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  local AllowRideType, AllowMovementId = self:GetRideMoveType(caster, pet)
  if not RideConf.not_use_for_ride then
    local pet_socket_mask = DataConfigManager:GetRideSocketExport(petID)
    if not (pet_socket_mask and pet_socket_mask.socket_mask) or 0 ~= DataModelMgr.PlayerDataModel.ban_ride_sockets_mask & pet_socket_mask.socket_mask then
      return AbilityErrorCode.DUNGEON_BAN
    end
  end
  if not caster.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and not caster.statusComponent:PreApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  if 0 == AllowRideType then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  local isAreaBan = self:IsTaskAreaBan(caster, petID)
  if isAreaBan then
    return AbilityErrorCode.TASK_AREA_BAN
  end
  local petData = pet and pet:GetPetData()
  if petData and 0 ~= petData.pet_status_flags & ProtoEnum.PetStatusFlag.TASK_TOGETHER_IN_PROGRESS then
    return AbilityErrorCode.TASK_LOCK
  end
  local MoveInfo = DataConfigManager:GetRideBasicMovement(AllowMovementId)
  if not caster.vitalityComponent:IsVitalityEnough(MoveInfo.vitality_cost.min_start) then
    return AbilityErrorCode.VITALITY_NOT_ENOUGH
  end
  return Base.CanCastAbility(self, caster)
end

function RideAllHelper:HandleStatus(caster, pet, ...)
  local statusComponent = caster.statusComponent
  local rideComponent = caster.viewObj.BP_RideComponent
  local reCall = rideComponent.ScenePet ~= pet
  local oldType
  local oldInDoubleRide = false
  local old2p
  if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    oldType = rideComponent.RideMoveType
    oldInDoubleRide = rideComponent:IsInDoubleRide()
    if oldInDoubleRide then
      local customParams = caster.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      if customParams and 0 ~= customParams.ride_param.double_ride_2p_id and customParams.ride_param.double_ride_2p_id ~= nil then
        old2p = customParams.ride_param.double_ride_2p_id
      end
    else
      statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ...)
    end
  end
  if reCall then
    local AllowRideType, AllowMovementId
    local AllRideConf = DataConfigManager:GetAllRidePet(pet.config.id)
    local SocketRideConf = DataConfigManager:GetRideSocket(pet.config.id, true)
    if oldType then
      local MovementList = AllRideConf.basic_movement_list
      for _, MovementId in pairs(MovementList) do
        local MoveConf = DataConfigManager:GetRideBasicMovement(MovementId)
        if MoveConf.move_type == oldType then
          AllowRideType = MoveConf.move_type
          AllowMovementId = MovementId
          self._cacheRideType = AllowRideType
          self._cacheMoveId = AllowMovementId
          self._cacheCanDoubleRide = rideComponent:ScenePetIsDoubleRide(pet)
          break
        end
      end
    end
    if nil == AllowRideType then
      AllowRideType, AllowMovementId = self:GetRideMoveType(caster, pet)
    end
    local ridePetParam = ProtoMessage:newPlayerRideStatusParams()
    ridePetParam.ride_pet_id = pet.config.id
    ridePetParam.mutation_type = _G.Enum.MutationDiffType.MDT_NONE
    ridePetParam.relative_emotion = 0
    ridePetParam.ride_load_finish = false
    ridePetParam.ride_pet_gid = pet.gid
    ridePetParam.option_id = pet.optionId or nil
    local petNpc = pet.npcId and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pet.npcId)
    if petNpc then
      ridePetParam.owner_id = petNpc:GetOwnerId()
    else
      ridePetParam.owner_id = caster:GetServerId()
    end
    local petData = pet:GetPetData()
    if petData then
      ridePetParam.mutation_type = petData.mutation_type
      ridePetParam.relative_emotion = petData.nature
      ridePetParam.glass_info = petData.glass_info
      ridePetParam.pet_voice = petData.voice
      ridePetParam.pet_gid = petData.gid
    end
    local cachedHandInHandParam, player2P
    if rideComponent:ScenePetIsDoubleRide(pet) then
      ridePetParam.double_ride_1p_id = caster.serverData.base.actor_id
      local HandInHandParam = caster.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
      cachedHandInHandParam = HandInHandParam
      if HandInHandParam then
        local uin2p = HandInHandParam.player_interact_param.player_uin2
        if uin2p then
          player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, uin2p)
        end
        if player2P and caster.InviteComponent:PreChangeTogether(ProtoEnum.RelationInteractSubType.RIST_DOUBLE_RIDE) then
          ridePetParam.double_ride_2p_id = player2P.serverData.base.actor_id
          if player2P.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
            player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
          end
          player2P.viewObj.BP_RideComponent:OnDoubleNotifyBegin(caster.serverData.base.logic_id, uin2p)
        end
      elseif oldInDoubleRide and old2p and caster.InviteComponent:PreChangeTogether(ProtoEnum.RelationInteractSubType.RIST_DOUBLE_RIDE) then
        statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ...)
        ridePetParam.double_ride_2p_id = old2p
        local player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, old2p)
        if player2P then
          player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
          player2P.viewObj.BP_RideComponent:OnDoubleNotifyBegin(caster.serverData.base.logic_id, player2P.serverData.base.logic_id)
        end
      end
    end
    local customParams = {ride_param = ridePetParam}
    caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
    caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
    if pet.gid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Friend or pet.gid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Wild or pet.gid == -ProtoEnum.SceneRideAllCustomGid.SRCG_Interact then
      ridePetParam.ride_npc_id = pet.npcId
    end
    statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, nil, nil, customParams, pet, AllowRideType, AllowMovementId, ...)
    if caster and caster.InviteComponent then
      caster.InviteComponent:EndChangeTogether()
    end
    if not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and caster and caster.InviteComponent then
      if cachedHandInHandParam then
        _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
      end
      if cachedHandInHandParam and caster.InviteComponent:PreChangeTogether(ProtoEnum.RelationInteractSubType.RIST_HOLD_HANDS) then
        local HandStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
        caster.InviteComponent.CurStatus = HandStatus
        player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
        local handSuccess = caster.InviteComponent:HandInHandLink(cachedHandInHandParam, HandStatus)
        caster.InviteComponent:EndChangeTogether()
        if not handSuccess then
          caster.InviteComponent:InteractCancel()
        else
          player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, cachedHandInHandParam)
        end
      else
        caster.InviteComponent:InteractCancel()
      end
    end
    caster:SendEvent(PlayerModuleEvent.ON_UPDATE_TOGETHER)
  end
end

function RideAllHelper:IsTaskAreaBan(caster, petID)
  if not caster or not caster.viewObj then
    Log.Error("RideAllHelper:\230\156\170\230\137\190\229\136\176\228\184\187\232\167\146\230\168\161\229\158\139")
    return true
  end
  local MovementList = DataConfigManager:GetAllRidePet(petID).basic_movement_list
  for _, MovementId in pairs(MovementList) do
    local MoveConf = DataConfigManager:GetRideBasicMovement(MovementId)
    if caster.taskAreaRideAllBanType and caster.taskAreaRideAllBanType[MoveConf.move_type] then
      return true
    end
  end
  return false
end

function RideAllHelper:GetRideMoveType(caster, scenePet)
  local AllowRideType = 0
  local AllowMovementId = 0
  if not (caster and caster.viewObj and scenePet) or not scenePet.config then
    Log.Error("RideAllHelper:\230\156\170\230\137\190\229\136\176\228\184\187\232\167\146\230\168\161\229\158\139")
    self._cacheRideType = AllowRideType
    self._cacheMoveId = AllowMovementId
    self._cacheCanDoubleRide = false
    return AllowRideType, AllowMovementId
  end
  local petID = scenePet.config.id
  local CharMoveComp = caster.viewObj.CharacterMovement
  local curPet = caster.viewObj.RidePet
  if curPet then
    CharMoveComp = curPet.CharacterMovement
  end
  local AllRideConf = DataConfigManager:GetAllRidePet(petID)
  local MovementList = {}
  if AllRideConf.basic_movement_list then
    MovementList = AllRideConf.basic_movement_list
  else
    Log.Error("RideAllHelper:\230\156\170\230\137\190\229\136\176\233\170\145\228\185\152\233\133\141\231\189\174, petID")
  end
  self._cacheRideTypeBase = nil
  local FlyMovementId = 0
  for _, MovementId in pairs(MovementList) do
    local MoveConf = DataConfigManager:GetRideBasicMovement(MovementId)
    local SubRideType = MoveConf.move_type
    if self._cacheRideTypeBase == nil then
      self._cacheRideTypeBase = SubRideType
    end
    if 0 == AllowRideType and not table.contains(DataModelMgr.PlayerDataModel.ban_type, SubRideType) then
      local hasBlock = false
      if SubRideType == ProtoEnum.SceneRideAllType.SRAT_GROUND then
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Walking or nil == curPet and caster.viewObj.CurWaterState >= UE.EWaterState.EWS_DeepWater
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Swimming and (nil ~= curPet or not (caster.viewObj.CurWaterState >= UE.EWaterState.EWS_DeepWater))
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_FLY then
        FlyMovementId = MovementId
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Falling and (CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or CharMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_Gliding)
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or CharMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_Climbing
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_CLIMB_WATER then
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or CharMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_ClimbWater
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_KEEP_BALANCE then
        hasBlock = CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or CharMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_KeepBalance or nil == curPet and caster.viewObj.CurWaterState >= UE.EWaterState.EWS_DeepWater
      end
      if not hasBlock then
        AllowRideType = SubRideType
        AllowMovementId = MovementId
      end
    end
  end
  if 0 == AllowRideType and 1 == #MovementList and 0 ~= FlyMovementId and not table.contains(DataModelMgr.PlayerDataModel.ban_type, ProtoEnum.SceneRideAllType.SRAT_FLY) then
    AllowRideType = ProtoEnum.SceneRideAllType.SRAT_FLY
    AllowMovementId = FlyMovementId
  end
  self._cacheRideType = AllowRideType
  self._cacheMoveId = AllowMovementId
  self._cacheCanDoubleRide = caster.viewObj.BP_RideComponent:ScenePetIsDoubleRide(scenePet)
  return AllowRideType, AllowMovementId
end

function RideAllHelper:GetIcon(caster, isBlock)
  if nil == isBlock then
    local gid = NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
    local pet = caster:GetPetByGid(gid)
    isBlock = self:IsBlock(caster, pet)
  end
  if not self._cacheRideType then
    Log.Error("\232\142\183\229\143\150\233\170\145\228\185\152UI\230\151\182\230\137\190\228\184\141\229\136\176Type\239\188\140\229\188\186\229\136\182\229\136\183\230\150\176")
    local gid = NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
    local pet = caster:GetPetByGid(gid)
    if not pet or not pet.config then
      return nil
    end
    local hasData = DataConfigManager:GetAllRidePet(pet.config.id, true)
    if hasData then
      self:GetRideMoveType(caster, pet)
    else
      return nil
    end
  end
  local UIType = self._cacheRideType
  if 0 == UIType then
    UIType = self._cacheRideTypeBase
  end
  if 0 == UIType then
    return Base.GetIcon(self, caster, isBlock)
  end
  local UIconf = DataConfigManager:GetAllRideUiConf(UIType)
  if not UIconf then
    return nil
  end
  if self._cacheCanDoubleRide then
    if isBlock then
      local Icon = UIconf.button_block_icon_double_ride
      if not string.IsNilOrEmpty(Icon) then
        return Icon
      end
    else
      local Icon = UIconf.button_icon_double_ride
      if not string.IsNilOrEmpty(Icon) then
        return Icon
      end
    end
  end
  if isBlock then
    local blockIcon = UIconf.button_block_icon
    if not string.IsNilOrEmpty(blockIcon) then
      return blockIcon
    end
  end
  return UIconf.button_icon
end

function RideAllHelper:GetPressIcon(caster)
  local UIType = self._cacheRideType
  if 0 == UIType then
    UIType = self._cacheRideTypeBase
  end
  if 0 == UIType then
    return Base.GetPressIcon(self, caster)
  end
  local UIconf = DataConfigManager:GetAllRideUiConf(UIType)
  if not UIconf then
    return nil
  end
  if self._cacheCanDoubleRide then
    local Icon = UIconf.button_press_icon_double_ride
    if not string.IsNilOrEmpty(Icon) then
      return Icon
    end
  end
  return UIconf.button_press_icon
end

function RideAllHelper:IsBlock(caster, pet)
  if not pet then
    Log.Error("RideAllHelper\229\136\164\230\150\173\230\151\182\228\188\160\229\133\165\228\186\134\231\169\186\231\178\190\231\129\181\239\188\129")
    return true
  end
  if self:CanCastAbility(caster, pet) ~= AbilityErrorCode.NO_ERROR then
    return true
  end
  return Base.IsBlock(self, caster)
end

function RideAllHelper:GetScaleByName(PetName)
  local result = 100
  local AllRide = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  for _, v in pairs(AllRide) do
    if v.animation_name == PetName then
      result = v.model_scale
      break
    end
  end
  return result
end

function RideAllHelper:GetIDByName(PetName)
  local result = 3001
  local AllRide = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  for _, v in pairs(AllRide) do
    if v.animation_name == PetName then
      result = v.id
      break
    end
  end
  return result
end

function RideAllHelper:FindRidePetByMovement(Movement, Result)
  local AllRide = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  if "" ~= Movement and ProtoEnum.SceneRideAllType[Movement] == nil then
    return
  end
  for _, v in pairs(AllRide) do
    if "" == Movement then
      Result:AddUnique(v.animation_name)
    else
      for _, movement in pairs(v.basic_movement_list) do
        if DataConfigManager:GetRideBasicMovement(movement).move_type == ProtoEnum.SceneRideAllType[Movement] then
          Result:AddUnique(v.animation_name)
          break
        end
      end
    end
  end
end

function RideAllHelper:FindRidePetByActiveSkill(ActiveSkill, Result)
  local AllRide = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  if "" ~= ActiveSkill and ProtoEnum.SceneRideAllActiveType[ActiveSkill] == nil then
    return
  end
  for _, v in pairs(AllRide) do
    if "" == ActiveSkill then
      Result:AddUnique(v.animation_name)
    else
      for _, movement in pairs(v.active_skill_list) do
        if DataConfigManager:GetRideBasicMovement(movement).active_type == ProtoEnum.SceneRideAllActiveType[ActiveSkill] then
          Result:AddUnique(v.animation_name)
          break
        end
      end
    end
  end
end

function RideAllHelper:Islocked(caster, petID)
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  if caster and caster.isLocal and RideConf then
    local PlayerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
    local WorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    local unlockLevel = RideConf.ride_unlock_level
    if unlockLevel > 10000 then
      return WorldLevel < unlockLevel - 10000
    else
      return PlayerLevel < unlockLevel
    end
  end
  return false
end

return RideAllHelper
