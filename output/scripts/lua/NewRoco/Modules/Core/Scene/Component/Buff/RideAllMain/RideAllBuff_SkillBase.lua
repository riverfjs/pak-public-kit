local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuff")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local RideAllBuff_SkillBase = Base:Extend("RideAllBuff_SkillBase")

function RideAllBuff_SkillBase:OnBegin(Owner, SkillConf)
  if self.owner.isLocal then
    self:OnBuffBegin(Owner, SkillConf)
    if self._needStartCostVitality then
      self:StartCostVitality()
    end
  else
    self:OnRemotePlayerBuffBegin(Owner, SkillConf)
  end
end

function RideAllBuff_SkillBase:OnBuffBegin(Owner, SkillConf, needStartCost)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_MAIN_ABILITY_RELEASED, self.OnMainAbilityReleased)
  _G.NRCPanelManager.layerCenter:AddEventListener(self, UILayerEvent.FULLSCREEN_LAYER_OPENWINDOW, self.OnFullScreenOpened)
  _G.NRCPanelManager.layerCenter:AddEventListener(self, UILayerEvent.BREAKRIDESKILL_LAYER_OPENWINDOW, self.OnFullScreenOpened)
  self._abilityID = AbilityID.RIDE_ALL_MAIN
  self.SkillId = SkillConf.id
  self.SkillConf = SkillConf
  self.RideType = SkillConf.active_type
  self.RideComp = self.owner.viewObj.BP_RideComponent
  self.RidePet = self.RideComp.RidePet
  self.SceneRidePet = self.RideComp.ScenePet
  if self.owner.isLocal then
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    local customParams = self.owner.statusComponent:GetCustomParams(Id)
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    customParams.ride_param.active_skill = self.SkillId
    self.owner.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  end
  self._needStartCostVitality = nil == needStartCost or true == needStartCost
end

function RideAllBuff_SkillBase:StartCostVitality()
  if self.owner.isLocal then
    self.owner.AddEventListener(self, PlayerModuleEvent.ON_VITALITY_OVER, self.OnVitalityOver)
    self.owner:SendEvent(PlayerModuleEvent.ON_UPDATE_VITALITY_COST, ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY, self.SkillId, self, self.OnStartCostVitalityFinish)
  else
    self:OnStartCostVitalityFinish(true)
  end
end

function RideAllBuff_SkillBase:OnRemotePlayerBuffBegin(Owner, SkillConf)
  self.RideComp = self.owner.viewObj.BP_RideComponent
  self.RidePet = self.RideComp.RidePet
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnPlayerStatusRefresh)
end

function RideAllBuff_SkillBase:OnRemotePlayerBuffFinish(param)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnPlayerStatusRefresh)
end

function RideAllBuff_SkillBase:OnRefreshRideallAbilityPlayerStatus(skill_stage, target_pos)
  local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  customParams.ride_skill_param.skill_stage = skill_stage
  if target_pos then
    customParams.ride_skill_param.target_pos = SceneUtils.ClientPos2ServerPos(target_pos, 100)
  end
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
end

function RideAllBuff_SkillBase:AnalyPropertyModify(SkillConf)
  local param1 = SkillConf.property_modify_speed_param_1
  local param2 = SkillConf.property_modify_speed_param_2
  local param3 = SkillConf.property_modify_speed_param_3
  self.propertyModify = {}
  local petData = self.SceneRidePet:GetPetData()
  if param1 and param1[1] and 0 ~= param1[1] and petData then
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
    end
    if petData.changed_nature_neg_attr_type == Enum.AttributeType.AT_SPEED then
      local removeSpeedValuePercent = petNatureConf.negative_effect_proportion / 10000
      natureSpeedPercent = natureSpeedPercent - removeSpeedValuePercent
    end
    local petName = self.SceneRidePet.config.name or ""
    local petID = self.SceneRidePet.config.id or 0
    Log.Debug("PropertyModifySpeed skill -> PetName = " .. petName .. " -PetID = " .. petID .. " -PetLevel = " .. petLevel .. " -PetSpeedEffort = " .. petSpeedEffort .. " -PetSpeetAllTalent = " .. petSpeetAllTalent .. " -PetSpeetBaseTalent = " .. petSpeetBaseTalent .. " -natureSpeedPercent = " .. natureSpeedPercent)
    local temp = (param2[1] * (petLevel - 1) / 59 + param2[2] * petSpeedEffort / 50 + param2[3] * (petSpeetAllTalent - petSpeetBaseTalent) / 50 + param2[4] * (natureSpeedPercent - 0.9) / 0.2 + param2[5] * petSpeetBaseTalent / 10) / 10000
    local value = param2[6] * temp * temp + param2[7] * temp + param2[8]
    local modifyList = {}
    for _, v in ipairs(param1) do
      modifyList[v] = true
    end
    self.propertyModify = modifyList
    self.modifyMode = param3
    self.modifyValue = value
    Log.Debug("PropertyModifySpeed skill -> ModifyValue = " .. value)
  end
end

function RideAllBuff_SkillBase:OnUpdate(deltaTime)
  if self.owner.isLocal then
    self:OnBuffUpdate(deltaTime)
  else
    self:OnRemotePlayerBuffUpdate(deltaTime)
  end
end

function RideAllBuff_SkillBase:OnBuffUpdate(deltaTime)
end

function RideAllBuff_SkillBase:OnRemotePlayerBuffUpdate(deltaTime)
end

function RideAllBuff_SkillBase:OnFullScreenOpened()
  self:StopActiveSKill()
end

function RideAllBuff_SkillBase:OnStartCostVitalityFinish(StartCostSuccess)
end

function RideAllBuff_SkillBase:OnVitalityOver()
end

function RideAllBuff_SkillBase:OnPlayerStatusChanged(...)
end

function RideAllBuff_SkillBase:OnPlayerStatusRefresh(...)
end

function RideAllBuff_SkillBase:OnMainAbilityReleased(...)
end

function RideAllBuff_SkillBase:OnRidePetChangeMoveType()
  self:StopActiveSKill()
end

function RideAllBuff_SkillBase:HandleRePress()
  return false
end

function RideAllBuff_SkillBase:StartFail()
  self._startFailDelay = DelayManager:DelayFrames(1, function()
    self:StopActiveSKill()
  end)
end

function RideAllBuff_SkillBase:StopActiveSKill()
  self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  self._startFailDelay = nil
end

function RideAllBuff_SkillBase:OnBuffFinish()
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_MAIN_ABILITY_RELEASED, self.OnMainAbilityReleased)
  _G.NRCPanelManager.layerCenter:RemoveEventListener(self, UILayerEvent.FULLSCREEN_LAYER_OPENWINDOW, self.OnFullScreenOpened)
  if self.owner.isLocal and not self.owner.statusComponent._waittingRemove[ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL] then
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    local customParams = self.owner.statusComponent:GetCustomParams(Id)
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    customParams.ride_param.active_skill = 0
    self.owner.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  end
  if self._startFailDelay then
    _G.DelayManager:CancelDelay(self._startFailDelay)
    self._startFailDelay = nil
  end
end

function RideAllBuff_SkillBase:OnFinish(param)
  if self.owner.isLocal then
    self:OnBuffFinish(param)
    if 0 == self.owner.vitalityComponent:GetCurVitality() then
      self.owner:SendEvent(PlayerModuleEvent.ON_VITALITY_OVER)
    end
  else
    self:OnRemotePlayerBuffFinish(param)
  end
end

function RideAllBuff_SkillBase:HasInput()
  if not self.RidePet then
    return false
  end
  return not UE4Helper.IsZeroVector(self.RidePet.CharacterMovement.ProxyInputVector)
end

function RideAllBuff_SkillBase:CanOffPet()
  return true
end

function RideAllBuff_SkillBase:CanThrowBall()
  return true
end

return RideAllBuff_SkillBase
