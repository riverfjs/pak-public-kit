local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuff")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local Stat = require("NewRoco.Modules.Core.Scene.Component.Stat.Stat")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local ScenePlayerRideAllBuff = Base:Extend("ScenePlayerRideAllBuff")

function ScenePlayerRideAllBuff:OnBegin(Owner, PetMesh, PetABP, Scale, isRecoverRide)
  self.EnvSystem = _G.NRCModuleManager:GetModule("EnvSystemModule")
  self.Rider = Owner.viewObj
  self.RideComponent = self.Rider.BP_RideComponent
  self.RideComponent.AutoReClimb = false
  self.PreClimbStartTime = 0
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnStatusRefresh)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_TALENT_CHANGE, self.OnTalentUpdate)
  _G.NRCEventCenter:RegisterEvent("ScenePlayerRideAllBuff", self, PetUIModuleEvent.PetWearMedalEvent, self.OnTalentUpdate)
  _G.NRCEventCenter:RegisterEvent("ScenePlayerRideAllBuff", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPetDataChange)
  self.owner.statComponent:CreateStat(StatType.SKILL_RUN_SPEED, 1)
  self.owner.statComponent:CreateStat(StatType.SKILL_FLY_UP_SPEED, 1)
  self.owner.statComponent:CreateStat(StatType.SKILL_JUMP_Z_SPEED, 1)
  self.owner.statComponent:CreateStat(StatType.SKILL_JUMP_X_SPEED, 1)
  self:OnRidePetChangeMoveType()
  self.waitDoubleRide = false
  self.waitStartRide = false
  self._cachedTalentUpdateTime = nil
  self.isRecoverRide = isRecoverRide
  if not Owner.isLocal then
    self.waitStartRide = true
    self.PetMesh = PetMesh
    self.PetABP = PetABP
    self.Scale = Scale
    self:Check3PRide()
  end
end

function ScenePlayerRideAllBuff:OnUpdateByComponent(deltaTime)
  if not self.RideComponent.bIsDoubleRide2p and self.RideComponent.RidePet and self.RideComponent.ScenePet and self.RideComponent.ScenePet.config and self.RideComponent:IsPetOnlyFly(self.RideComponent.ScenePet.config.id) and not self.RideComponent:IsInDoubleRide() then
    local MoveForward = self.RideComponent.RidePet:GetMovementComponent().Acceleration
    local petRadius = self.RideComponent.PetRadius or 0
    if self.Rider:GetMovementComponent():CanClimbWhileRiding(MoveForward, petRadius) then
      self.PreClimbStartTime = self.PreClimbStartTime + deltaTime
    else
      self.PreClimbStartTime = 0
    end
    if self.PreClimbStartTime >= self.Rider:GetMovementComponent().StartClimbInputHoldTime then
      self.RideComponent.AutoReClimb = true
      self.RideComponent:OnRideFailed()
    end
  end
  self:CheckEnterDoubleRide()
  if self._cachedTalentUpdateTime then
    local CurTime = math.floor(self.EnvSystem:GetCurrentTime() / 3600.0)
    for _, v in pairs(self._cachedTalentUpdateTime) do
      if v == CurTime then
        self:OnTalentUpdate()
        return
      end
    end
  end
end

function ScenePlayerRideAllBuff:UpdateAudio(deltaTime)
  local RidePet = self.owner:GetRidePetBP()
  if UE.UObject.IsValid(RidePet) then
    local Speed = RidePet.CharacterMovement.CurrentSpeed
    if not Speed then
      return
    end
    local NewStopRTPC = 1
    if Speed < 100 then
      NewStopRTPC = Speed / 100
    end
    if NewStopRTPC < 0.01 then
      NewStopRTPC = 0
    end
    if not self.StopRTPC then
      self.StopRTPC = 0
    end
    if self.StopRTPC ~= NewStopRTPC then
      if NewStopRTPC > self.StopRTPC then
        self.StopRTPC = NewStopRTPC
      else
        local maxReduce = deltaTime * 5
        local Reduce = self.StopRTPC - NewStopRTPC
        if maxReduce < Reduce then
          Reduce = maxReduce
        end
        self.StopRTPC = self.StopRTPC - Reduce
      end
      _G.NRCAudioManager:SetEmitterRTPC("Pet_Ride_Stop", self.StopRTPC, RidePet)
    end
  end
end

function ScenePlayerRideAllBuff:OnRidePetChangeMoveType()
  if not self.owner.isLocal then
    return
  end
  local RideComponent = self.owner.viewObj.BP_RideComponent
  if UE.UObject.IsValid(RideComponent.RideMoveComp) and RideComponent.RidePet and RideComponent.RideMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Falling and (RideComponent.RideMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or RideComponent.RideMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_Gliding) then
    RideComponent.RidePet.InLeap = false
  end
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local customParams = self.owner.statusComponent._statusParams[Id]
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  if customParams.ride_param == nil then
    customParams.ride_param = {}
  end
  if customParams.ride_param.double_ride_2p_id == self.owner.serverData.base.actor_id then
    return
  end
  customParams.ride_param.ride_move_mode = RideComponent.RideMoveType
  customParams.ride_param.ride_basic_move_id = RideComponent.RideMovementId
  customParams.ride_param.ride_socket_type = RideComponent.SocketType
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
end

function ScenePlayerRideAllBuff:OnFinish(param)
  self:RemoveTalent()
  self:RemovePropertyModifySpeed()
  self.RideComponent.bIsDoubleRide2p = false
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnStatusRefresh)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_TALENT_CHANGE, self.OnTalentUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetWearMedalEvent, self.OnTalentUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPetDataChange)
  if self.RideComponent.area_id then
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.HideVisualWall, self.area_id)
    self.RideComponent.area_id = nil
  end
end

function ScenePlayerRideAllBuff:CheckEnterDoubleRide()
  if self.waitDoubleRide and not self.RideComponent.bIsLocalDebug then
    local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    local customParams = self.owner.statusComponent:GetCustomParams(statusId)
    if not customParams then
      return
    end
    local uin_1p = customParams.ride_param.double_ride_1p_id
    local player_1p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, uin_1p)
    local player_2p = self.owner
    if player_1p and UE.UObject.IsValid(player_1p.viewObj) then
      local customParams_1P = player_1p.statusComponent:GetCustomParams(statusId)
      local RideComponent_1p = player_1p.viewObj.BP_RideComponent
      if customParams_1P and RideComponent_1p and RideComponent_1p.RidePet and RideComponent_1p.RidePet.Mesh and customParams_1P.ride_param.double_ride_2p_id == self.owner.serverData.base.actor_id then
        self.RideComponent.bIsDoubleRide2p = true
        RideComponent_1p:LuaDoubleRideStatusChange(player_1p.viewObj, player_2p.viewObj, true)
        local pet_Id = customParams_1P.ride_param.ride_pet_id
        local ForceConf = DataConfigManager:GetRideSocket(pet_Id)
        if not ForceConf then
          Log.Error("\229\143\140\228\186\186\233\170\145\228\185\152\233\133\141\231\189\174\229\188\130\229\184\184\239\188\129")
        end
        local socket_1p = 1 == player_1p.gender and ForceConf.double_ride_socket_pc1_1p or ForceConf.double_ride_socket_pc2_1p
        local socket_2p = 1 == player_2p.gender and ForceConf.double_ride_socket_pc1_2p or ForceConf.double_ride_socket_pc2_2p
        RideComponent_1p:ChangeSocketWhileRiding(socket_1p)
        RideComponent_1p.RidePet.Mesh:GetAnimInstance().bIsInDoubleRide = true
        RideComponent_1p.double_ride_2p_id = self.owner.serverData.base.actor_id
        local gender, slot_type, suffix = string.match(socket_2p, "^(.-)_(.-)_Ride(.*)$")
        for SocketNameFormList, v in pairs(Enum.ScenePlayerRideSocketType) do
          if SocketNameFormList == slot_type then
            self.RideComponent.SocketName_Male = gender
            self.RideComponent.RideSocketName = socket_2p
            self.RideComponent.SocketType = v
            self.RideComponent.SocketName_Head = slot_type
            self.RideComponent.SocketName_Tail = suffix
          end
        end
        self.owner.viewObj.Mesh.bEabledAuxiliaryAnimGraphThread = false
        player_2p:GetAnimComponent():StopAllMontage(0)
        self.RideComponent:DoubleRide2p(RideComponent_1p.RidePet, pet_Id, player_2p.isLocal)
        self.RideComponent:ChangeAnimSocketName()
        RideComponent_1p:UpdateHeadWidgetDoubleRide(true)
        RideComponent_1p.ScenePet:OnSetDoubleRide2P(true, player_2p)
        self.RideComponent:UpdateHeadWidgetDoubleRide(true)
        self.waitDoubleRide = false
        if player_1p.isLocal then
          player_1p:SendEvent(PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, true, pet_Id, true)
        end
        if player_2p.isLocal then
          player_2p:SendEvent(PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, true, pet_Id, false)
        end
        player_2p:SendEvent(PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, true)
        self:OnRidePetChangeMoveType()
      end
    end
  end
end

function ScenePlayerRideAllBuff:OnStatusRefresh(status, subStatus, opCode)
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  if status ~= statusId then
    return
  end
  local player = self.owner
  local rideComponent = player.viewObj.BP_RideComponent
  local customParams = player.statusComponent:GetCustomParams(statusId)
  local double_ride_2p_id = customParams.ride_param.double_ride_2p_id
  local double_ride_1p_id = customParams.ride_param.double_ride_1p_id
  self:Check3PRide()
  if rideComponent.RidePet then
    if rideComponent.RidePet.Mesh:GetAnimInstance().bIsInDoubleRide and (nil == double_ride_2p_id or double_ride_2p_id <= 0) then
      if self.owner and self.owner.InviteComponent then
        self.owner.InviteComponent:InteractCancel()
      end
      local comp_double_ride_2p_id = rideComponent.double_ride_2p_id
      rideComponent.double_ride_2p_id = nil
      rideComponent:GetRideSocketAndType(rideComponent.RidePet.Mesh.SkeletalMesh)
      rideComponent:ChangeSocketWhileRiding(rideComponent.RideSocketName)
      rideComponent.RidePet.Mesh:GetAnimInstance().bIsInDoubleRide = false
      rideComponent:UpdateHeadWidgetDoubleRide(true)
      if self.RideComponent.area_id then
        _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.HideVisualWall, self.RideComponent.area_id)
        self.RideComponent.area_id = nil
      end
      if comp_double_ride_2p_id then
        local player_2p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, comp_double_ride_2p_id)
        if player_2p and player_2p.viewObj.BP_RideComponent.bIsDoubleRide2p then
          player_2p.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
        end
      end
    end
    if (nil == double_ride_1p_id or double_ride_1p_id <= 0) and nil ~= double_ride_2p_id and double_ride_2p_id > 0 then
      if self.owner and self.owner.InviteComponent then
        self.owner.InviteComponent:InteractCancel()
      end
      local comp_double_ride_2p_id = rideComponent.double_ride_2p_id
      rideComponent.double_ride_2p_id = nil
      if comp_double_ride_2p_id then
        local player_2p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, comp_double_ride_2p_id)
        if player_2p and player_2p.viewObj.BP_RideComponent.bIsDoubleRide2p then
          player_2p.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
        end
      end
    end
  end
  if rideComponent.RidePet and rideComponent.RidePet.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_None then
    self:SetPetMovementModeByMoveType()
  end
end

function ScenePlayerRideAllBuff:Check3PRide()
  if self.waitStartRide then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    self.waitStartRide = not customParams.ride_param.ride_load_finish
    local rideComponent = self.owner.viewObj.BP_RideComponent
    if not self.waitStartRide and rideComponent.ScenePet then
      rideComponent.ScenePet:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE)
      rideComponent:StartRide(self.PetMesh, self.PetABP, self.Scale)
    end
  end
end

function ScenePlayerRideAllBuff:SetPetMovementModeByMoveType()
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local player = self.owner
  local rideComponent = player.viewObj.BP_RideComponent
  local ridePet = rideComponent.RidePet
  local customParams = player.statusComponent:GetCustomParams(statusId)
  if ridePet and customParams and customParams.ride_param.ride_move_mode then
    local ride_move_mode = customParams.ride_param.ride_move_mode
    local moveMode = ride_move_mode >= UE4.EMovementMode.MOVE_Custom and UE4.EMovementMode.MOVE_Custom or ride_move_mode
    local customMode = ride_move_mode
    ridePet.CharacterMovement:SetMovementMode(moveMode, customMode)
  end
end

function ScenePlayerRideAllBuff:ApplyTalent()
  if self.RideComponent and self.RideComponent.RidePet and self.RideComponent.ScenePet then
    local ScenePet = self.RideComponent.ScenePet
    local Talents = ScenePet:GetAllEffectTalent()
    if Talents then
      self._StatObjID = {}
      self._StatID = {}
      for _, talent_id in pairs(Talents) do
        local TalentConf = DataConfigManager:GetPetTalentConf(talent_id, true)
        local isActive = true
        for _, Condition_group in pairs(TalentConf.condition_group) do
          local condition = Condition_group.talent_condition
          local condition_param = Condition_group.talent_condition_param
          if condition == ProtoEnum.PetTalentCondition.PTC_GAME_TIME and condition_param then
            if not self._cachedTalentUpdateTime then
              self._cachedTalentUpdateTime = {}
            end
            local CurTime = math.floor(self.EnvSystem:GetCurrentTime() / 3600.0)
            local TimeLeft = condition_param[1]
            local TimeRight = condition_param[2]
            local NextUpdateTime = 0
            if TimeLeft < TimeRight then
              if CurTime >= TimeLeft and CurTime < TimeRight then
                NextUpdateTime = TimeRight
              else
                isActive = false
                NextUpdateTime = TimeLeft
              end
            elseif CurTime >= TimeLeft or CurTime < TimeRight then
              NextUpdateTime = TimeRight
            else
              isActive = false
              NextUpdateTime = TimeLeft
            end
            table.insert(self._cachedTalentUpdateTime, NextUpdateTime)
          end
          if condition == ProtoEnum.PetTalentCondition.PTC_EQUIP_BADGE then
            local _, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(ScenePet.gid)
            if not WearMedal then
              isActive = false
            end
          end
        end
        if isActive then
          for _, Effect in pairs(TalentConf.effect_group) do
            self:ApplyTalentImpl(Effect.effect, Effect.effect_param)
            ScenePet.TalentEffectMap[Effect.effect] = true
          end
        end
      end
    end
  end
end

function ScenePlayerRideAllBuff:GetPropertyModifySpeedValue(param2)
  local petData = self.RideComponent.ScenePet:GetPetData()
  if not petData then
    return 1
  end
  local petLevel = petData.level
  local petSpeedEffort = petData.attribute_info.speed.effort_add or 0
  local petSpeetAllTalent = petData.attribute_info.speed.talent or 0
  local petSpeetBaseTalent = petData.attribute_info.speed.talent_add_value or 0
  local natureSpeedPercent = 1
  local petNatureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
  if petData.changed_nature_pos_attr_type == Enum.AttributeType.AT_SPEED then
    local _, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(petData)
    local addSpeedValuePercent = (petNatureConf.positive_effect_proportion + petNatureConf.positive_effect_grow * (GrowOrder - 1)) / 10000
    natureSpeedPercent = natureSpeedPercent + addSpeedValuePercent
  elseif petNatureConf and petNatureConf.positive_effect == Enum.AttributeType.AT_SPEED_PERCENT then
    local _, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(petData)
    local addSpeedValuePercent = (petNatureConf.positive_effect_proportion + petNatureConf.positive_effect_grow * (GrowOrder - 1)) / 10000
    natureSpeedPercent = natureSpeedPercent + addSpeedValuePercent
  end
  if petData.changed_nature_neg_attr_type == Enum.AttributeType.AT_SPEED then
    local removeSpeedValuePercent = petNatureConf.negative_effect_proportion / 10000
    natureSpeedPercent = natureSpeedPercent - removeSpeedValuePercent
  elseif petNatureConf.negative_effect == Enum.AttributeType.AT_SPEED_PERCENT then
    local removeSpeedValuePercent = petNatureConf.negative_effect_proportion / 10000
    natureSpeedPercent = natureSpeedPercent - removeSpeedValuePercent
  end
  local petName = self.RideComponent.ScenePet.config.name or ""
  local petID = self.RideComponent.ScenePet.config.id or 0
  Log.Debug("PropertyModifySpeed RIDE -> PetName = " .. petName .. " -PetID = " .. petID .. " -PetLevel = " .. petLevel .. " -PetSpeedEffort = " .. petSpeedEffort .. " -PetSpeetAllTalent = " .. petSpeetAllTalent .. " -PetSpeetBaseTalent = " .. petSpeetBaseTalent .. " -natureSpeedPercent = " .. natureSpeedPercent)
  local temp = (param2[1] * (petLevel - 1) / 59 + param2[2] * petSpeedEffort / 50 + param2[3] * (petSpeetAllTalent - petSpeetBaseTalent) / 50 + param2[4] * (natureSpeedPercent - 0.9) / 0.3 + param2[5] * petSpeetBaseTalent / 10) / 10000
  local value = (param2[6] * temp * temp + param2[7] * temp + param2[8]) / 10000
  Log.Debug("PropertyModifySpeed RIDE -> ModifyValue = " .. value)
  return value
end

function ScenePlayerRideAllBuff:ApplyPropertyModifySpeed()
  if self.RideComponent and self.RideComponent.RidePet and self.RideComponent.ScenePet and self.RideComponent.ScenePet.gid then
    self._PropertyStatObjID = {}
    local petID = self.RideComponent.ScenePet.config.id
    local RideConf = DataConfigManager:GetAllRidePet(petID)
    for _, MoveID in pairs(RideConf.basic_movement_list) do
      local moveConf = DataConfigManager:GetRideBasicMovement(MoveID)
      local MoveComp
      local StatName = StatType.BASE_MAX_SPEED
      if moveConf.property_modify_speed_param_1 and moveConf.property_modify_speed_param_1[1] and 0 ~= moveConf.property_modify_speed_param_1[1] then
        if moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_GROUND then
          MoveComp = self.RideComponent.RidePet.VehicleWalkMovement
        elseif moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_SWIM then
          MoveComp = self.RideComponent.RidePet.CharacterSwimMovement
        elseif moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY then
          MoveComp = self.RideComponent.RidePet.CharacterFlyMovement
        elseif moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
          MoveComp = self.RideComponent.RidePet.CharacterClimbMovement
        elseif moveConf.move_type == ProtoEnum.SceneRideAllType.SRAT_CLIMB_WATER then
          MoveComp = self.RideComponent.RidePet.CharacterClimbWaterFallMovement
        end
        if MoveComp then
          local percent = self:GetPropertyModifySpeedValue(moveConf.property_modify_speed_param_2) - 1
          local statID_PropertySpeed = self.owner.statComponent:ApplyStat(StatName, percent, Stat.StatApplyType.Percent, MoveComp)
          if not self._PropertyStatObjID[MoveComp] then
            self._PropertyStatObjID[MoveComp] = {}
          end
          table.insert(self._PropertyStatObjID[MoveComp], {id = statID_PropertySpeed, name = StatName})
        end
      end
    end
  end
end

function ScenePlayerRideAllBuff:ApplyTalentImpl(effect, effect_param)
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_RUN_SPEED_RATIO then
    local MoveComp = self.RideComponent.RidePet.VehicleWalkMovement
    local statID_SkillRunSpeed = self.owner.statComponent:ApplyStat(StatType.SKILL_RUN_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    local statID_RunSpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    table.insert(self._StatID, {
      id = statID_SkillRunSpeed,
      name = StatType.SKILL_RUN_SPEED
    })
    if not self._StatObjID[MoveComp] then
      self._StatObjID[MoveComp] = {}
    end
    table.insert(self._StatObjID[MoveComp], {
      id = statID_RunSpeed,
      name = StatType.BASE_MAX_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_SWIM_SPEED_RATIO then
    local MoveComp = self.RideComponent.RidePet.CharacterSwimMovement
    local statID_SwimSpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    if not self._StatObjID[MoveComp] then
      self._StatObjID[MoveComp] = {}
    end
    table.insert(self._StatObjID[MoveComp], {
      id = statID_SwimSpeed,
      name = StatType.BASE_MAX_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_FLY_SPEED_RATIO then
    local MoveComp = self.RideComponent.RidePet.CharacterFlyMovement
    local statID_SkillFlyUpSpeed = self.owner.statComponent:ApplyStat(StatType.SKILL_FLY_UP_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    local statID_FlySpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    local statID_FlyUpSpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_UP_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    table.insert(self._StatID, {
      id = statID_SkillFlyUpSpeed,
      name = StatType.SKILL_FLY_UP_SPEED
    })
    if not self._StatObjID[MoveComp] then
      self._StatObjID[MoveComp] = {}
    end
    table.insert(self._StatObjID[MoveComp], {
      id = statID_FlySpeed,
      name = StatType.BASE_MAX_SPEED
    })
    table.insert(self._StatObjID[MoveComp], {
      id = statID_FlyUpSpeed,
      name = StatType.BASE_MAX_UP_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_CLIMB_SPEED_RATIO then
    local MoveComp = self.RideComponent.RidePet.CharacterClimbMovement
    local statID_MaxSpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    local statID_ClimbSpeed = self.owner.statComponent:ApplyStat(StatType.CLIMB_SPEED_TALENT_RATIO, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    if not self._StatObjID[MoveComp] then
      self._StatObjID[MoveComp] = {}
    end
    table.insert(self._StatObjID[MoveComp], {
      id = statID_ClimbSpeed,
      name = StatType.CLIMB_SPEED_TALENT_RATIO
    })
    table.insert(self._StatObjID[MoveComp], {
      id = statID_MaxSpeed,
      name = StatType.BASE_MAX_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_SWIM_CLIMB_SPEED_RATIO then
    local MoveComp = self.RideComponent.RidePet.CharacterClimbWaterFallMovement
    local statID_MaxSpeed = self.owner.statComponent:ApplyStat(StatType.BASE_MAX_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    local statID_ClimbSpeed = self.owner.statComponent:ApplyStat(StatType.CLIMB_SPEED_TALENT_RATIO, effect_param / 10000 - 1, Stat.StatApplyType.Percent, MoveComp)
    if not self._StatObjID[MoveComp] then
      self._StatObjID[MoveComp] = {}
    end
    table.insert(self._StatObjID[MoveComp], {
      id = statID_ClimbSpeed,
      name = StatType.CLIMB_SPEED_TALENT_RATIO
    })
    table.insert(self._StatObjID[MoveComp], {
      id = statID_MaxSpeed,
      name = StatType.BASE_MAX_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_JUMP_Z_VELOCITY_RATIO then
    local statID_SkillJumpZSpeed = self.owner.statComponent:ApplyStat(StatType.SKILL_JUMP_Z_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    table.insert(self._StatID, {
      id = statID_SkillJumpZSpeed,
      name = StatType.SKILL_JUMP_Z_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_JUMP_X_VELOCITY_RATIO then
    local statID_SkillJumpXSpeed = self.owner.statComponent:ApplyStat(StatType.SKILL_JUMP_X_SPEED, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    table.insert(self._StatID, {
      id = statID_SkillJumpXSpeed,
      name = StatType.SKILL_JUMP_X_SPEED
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_SKILL_STAMINA_RATIO then
    local statId_vitality = self.owner.statComponent:ApplyStat(StatType.VITALITY_COST_RATIO_TALENT, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    table.insert(self._StatID, {
      id = statId_vitality,
      name = StatType.VITALITY_COST_RATIO_TALENT
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_PERCEPT_SKILL_STAMINA_RATIO then
    local statId_ride_perception_vitality = self.owner.statComponent:ApplyStat(StatType.VITALITY_RIDE_PERCEPTION_COST_RATIO_TALENT, effect_param / 10000 - 1, Stat.StatApplyType.Percent)
    table.insert(self._StatID, {
      id = statId_ride_perception_vitality,
      name = StatType.VITALITY_RIDE_PERCEPTION_COST_RATIO_TALENT
    })
  end
  if effect == ProtoEnum.PetTalentEffect.PTE_MOUNT_GATHER_RANGE_RATIO then
    local statId_pet_gather_range_ratio = self.owner.statComponent:ApplyStat(StatType.PTE_MOUNT_GATHER_RANGE_RATIO, effect_param * 0.01, Stat.StatApplyType.BaseValueOverride, nil, 1)
    table.insert(self._StatID, {
      id = statId_pet_gather_range_ratio,
      name = StatType.PTE_MOUNT_GATHER_RANGE_RATIO
    })
  end
end

function ScenePlayerRideAllBuff:RemoveTalent()
  if self.owner and self.owner.statComponent and self._StatID then
    for _, statInfo in pairs(self._StatID) do
      local name = statInfo.name
      local id = statInfo.id
      self.owner.statComponent:RemoveStat(name, id)
    end
    for obj, objStat in pairs(self._StatObjID) do
      for _, statInfo in pairs(objStat) do
        local name = statInfo.name
        local id = statInfo.id
        self.owner.statComponent:RemoveStat(name, id, obj)
      end
    end
  end
  self._cachedTalentUpdateTime = nil
  if self.RideComponent and self.RideComponent.ScenePet then
    self.RideComponent.ScenePet.TalentEffectMap = {}
  end
end

function ScenePlayerRideAllBuff:OnTalentUpdate()
  self:RemoveTalent()
  self:ApplyTalent()
  if self.RideComponent and self.RideComponent.ScenePet then
    self.RideComponent.ScenePet:SendEvent(PlayerModuleEvent.ON_RIDEPET_TALENT_CHANGE_POST)
  end
end

function ScenePlayerRideAllBuff:RemovePropertyModifySpeed()
  if self.owner and self.owner.statComponent and self._PropertyStatObjID then
    for obj, objStat in pairs(self._PropertyStatObjID) do
      for _, statInfo in pairs(objStat) do
        local name = statInfo.name
        local id = statInfo.id
        self.owner.statComponent:RemoveStat(name, id, obj)
      end
    end
  end
end

function ScenePlayerRideAllBuff:OnPetDataChange(GoodsChangeItem, CmdID)
  if not self.RideComponent or not self.RideComponent.ScenePet then
    return
  end
  local petGid = self.RideComponent.ScenePet.gid
  if not petGid then
    return
  end
  if GoodsChangeItem and GoodsChangeItem.pet_data and GoodsChangeItem.pet_data.gid == petGid then
    self:RemovePropertyModifySpeed()
    self:ApplyPropertyModifySpeed()
    Log.Debug("ScenePlayerRideAllBuff:OnPetDataChange - \233\135\141\230\150\176\229\186\148\231\148\168\233\170\145\228\185\152\233\128\159\229\186\166\228\191\174\230\173\163, petGid=" .. tostring(petGid))
  end
end

return ScenePlayerRideAllBuff
