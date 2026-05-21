local Enum = require("Data.Config.Enum")
local ProtoEnum = require("Data.PB.ProtoEnum")
local EventDispatcher = require("Common.EventDispatcher")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local ServerData = require("Common.LocalServer.LocalBattleRSPTable")
local BattlePlayer = require("NewRoco.Modules.Core.Battle.Entity.BattlePlayer")
local BattlePlayerSkillPlayer = BattlePlayerBase:Extend()

function BattlePlayerSkillPlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
end

function BattlePlayerSkillPlayer:Play(performNode)
  self.OldBoundsScale = nil
  self.performNode = performNode
  self.performInfo = performNode:GetInfo()
  self.IsFastPlay = performNode.IsFastPlay
  Log.Debug("BattlePlayerSkillPlayer PLAY Skill: ", performNode:GetInfo().role_skill_cast.caster_uin, performNode:GetInfo().role_skill_cast.skill_id, performNode:GetCastMomentToString(), self.performInfo.change_model)
  self.role_skill_cast = self.performInfo.role_skill_cast
  self.change_model = self.performInfo.change_model
  self.SkillConf = _G.DataConfigManager:GetSkillConf(self.role_skill_cast.skill_id)
  local isPerforming = true
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAYERSKILL_PERFORMING_UPDATE, isPerforming)
  self.Caster = BattleManager.battlePawnManager:GetPlayerByGuid(self.role_skill_cast.caster_uin)
  if not self.Caster or not self.Caster.model then
    Log.Error("BattlePlayerSkillPlayer no Caster ", self.role_skill_cast.caster_uin)
    self:OnSkillComplete()
    return
  end
  self.Caster:HideDialogBox()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdSwitchChatBubbles, self.Caster.model, false)
  if BattleUtils.IsTeam() and self.Caster ~= self.PawnManager.TeamatePlayer or self.IsFastPlay then
    self.IsFastPlay = true
    _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_PERFORM_SKILL, self.role_skill_cast)
  end
  self.targets = {}
  self:GetTargetPets()
  if self:IsChangePetSkill() then
    self:PawnExchangePet()
  else
    self:OnPlayPlayerSkill()
  end
end

function BattlePlayerSkillPlayer:PrepareSkill()
  local CastSkillParam = CastSkillObject.FromPerformInfoToPlayerSkill(self.performInfo.role_skill_cast)
  if not CastSkillParam then
    return nil
  end
  CastSkillParam:SetCaster(self.Caster.model):SetCompleteCallback(self.OnSkillComplete):SetSkillBreakCallback(self.OnSkillFailed):SetStartFailedCallback(self.OnSkillFailed):SetHideBuffBarCallback(self.OnHideBuffs):SetShowBuffBarCallback(self.OnShowBuffs):SetHideTargetsBuffBarCallback(self.HideTargetsBuffBar):SetShowTargetsBuffBarCallback(self.ShowTargetsBuffBar):SetCallbackOwner(self):SetInterrupt(true):SetIsPassive(false):SetTargetPets(self.targets):SetOnRoleMagicChangeModelCallback(self.OnRoleMagicChangeModel):SetExtraEvents({
    ShowPetName = self.OnShowPetName,
    ActionStart = self.ShowPet
  })
  return CastSkillParam
end

function BattlePlayerSkillPlayer:ShowPet()
  if self.newPet then
    self.newPet:ShowPet()
  end
end

function BattlePlayerSkillPlayer:HideTargetsBuffBar()
  if not self.targets then
    return
  end
  for i = 1, #self.targets do
    if self.targets[i] then
      self.targets[i]:ChangeBuffVisibility(false)
    end
  end
end

function BattlePlayerSkillPlayer:ShowTargetsBuffBar()
  if not self.targets then
    return
  end
  for i = 1, #self.targets do
    if self.targets[i] then
      self.targets[i]:ChangeBuffVisibility(true)
    end
  end
end

function BattlePlayerSkillPlayer:OnRoleMagicChangeModel()
  self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnRoleMagicChangeModel)
end

function BattlePlayerSkillPlayer:OnShowPetName()
  if self.role_skill_cast.is_call_success then
    BattleDataCenter:Dispatch(BattlePerformEvent.FinalBattleNameVisible, self.role_skill_cast.pet_id)
  end
end

function BattlePlayerSkillPlayer:GetTargetPets()
  local pet = self:GetPetWithID(self.role_skill_cast.pet_id)
  if pet then
    if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
      UE4.UNRCStatics.RemoveXRay(pet.model, pet.model.TeamXRayMaterial, pet.model)
    else
      UE4.UNRCStatics.RemoveXRay(pet.model, pet.model.EnemyXRayMaterial, pet.model)
    end
    table.insert(self.targets, pet)
    pet:SetIKEnable(false)
    self.cacheOriPetToDestroy = pet
  end
end

function BattlePlayerSkillPlayer:PawnExchangePet()
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED)
  if not self.change_model then
    self:OnSkillComplete()
    return
  end
  local changeModelBaseId = self.change_model.pet_info.battle_inside_pet_info.base_conf_id
  local card = self.Caster.deck:GetCardByGuid(self.change_model.pet_id)
  local petInfo = self.change_model.pet_info
  if not card then
    Log.Warning("not find pet by id : ", self.change_model.pet_id)
    self:OnSkillComplete()
    return
  end
  if petInfo.battle_inside_pet_info.pet_id then
    card:OverwriteByServer(petInfo)
    card:RefreshByServer()
    card:RefreshByInfoAndBaseConf(petInfo, changeModelBaseId)
  end
  card.pos = petInfo.battle_inside_pet_info.pos
  card:SetInBattleField(true)
  self.newPet = self.PawnManager:PawnPet(self.Caster.teamEnm, self.Caster.team, card, self.Caster)
  table.insert(self.targets, self.newPet)
end

function BattlePlayerSkillPlayer:IsChangePetSkill()
  local skill_id = self.role_skill_cast.skill_id
  local SkillConf = _G.DataConfigManager:GetSkillConf(skill_id)
  if SkillConf and SkillConf.skill_result and #SkillConf.skill_result > 0 then
    local EffectConf = _G.DataConfigManager:GetEffectConf(SkillConf.skill_result[1].effect_id)
    if EffectConf and (EffectConf.effect_order == Enum.EffectType.ET_BOSS_BLOOD or EffectConf.effect_order == Enum.EffectType.ET_ROLE_CHANGE_PET) then
      return true
    end
  else
    Log.Error("SKILL_CONF\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
  end
  return false
end

function BattlePlayerSkillPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
    return true
  end
end

function BattlePlayerSkillPlayer:OnPawnNewPetFinish(pet)
  self.newPet = pet
  self.newPet:SetScale(1)
  self.newPet.model:SetInSignificance(false)
  self.newPet:PinOnTheGround()
  self.newPet:SetIKEnable(false)
  _G.BattleEventCenter:UnBind(self)
  Log.Debug("BattlePlayerSkillPlayer OnPawnNewPetFinish")
  self:OnPlayPlayerSkill()
end

function BattlePlayerSkillPlayer:GetPetWithID(id)
  local pet = self.PawnManager:GetPetByGuid(id)
  return pet
end

function BattlePlayerSkillPlayer:OnPlayPlayerSkill()
  self.CastParam = self:PrepareSkill()
  if not self.CastParam then
    Log.Error("BattlePlayerSkillPlayer:OnPlayPlayerSkil \228\184\187\232\167\146\233\173\148\230\179\149\232\181\132\230\186\144\232\183\175\229\190\132\233\148\153\232\175\175 ", self.performInfo.role_skill_cast.skill_id)
    self:OnSkillComplete()
    return
  end
  self.Team = self.Caster.team
  self.Player = self.Team.player
  self.BreakFlow = false
  self:ApplyDefaultCamera()
  if self.IsFastPlay then
    self:OnSkillComplete()
    return
  end
  self.Caster:EnableGravity(false)
  local rocoSkillComponent, rocoSkill
  if self.Caster.model then
    rocoSkill = self.Caster.model.RocoSkill
  end
  if self.role_skill_cast.skill_id == BattleUtils.GetFBCallNameMagicId() then
    local isSucceed = self.role_skill_cast.is_call_success and "True" or "False"
    self.CastParam.BlackStringValue = {Call_Succeed = isSucceed}
    self.CastParam:SetIsPassive(true)
  end
  rocoSkillComponent, self.SkillObject = BattleSkillManager:PrepareSkill(self.Caster, rocoSkill, self.CastParam)
  self.SkillObject.BattleGenderType = self.Caster.roleInfo.base.sex
  if not self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    self.SkillObject.IsIgnoreCameraAction = true
  end
  if self.Caster.model and self.Caster.model.mesh then
    self.OldBoundsScale = self.Caster.model.mesh.BoundsScale
    self.OldFixedSkelBounds = self.Caster.model.mesh.bNRCUseFixedSkelBounds
    self.Caster.model.mesh.BoundsScale = 20
    if self.OldFixedSkelBounds then
      self.Caster.model.mesh.bNRCUseFixedSkelBounds = false
    end
  end
  if self.Caster == self.PawnManager.TeamatePlayer then
    self.SkillObject:RegisterEventCallback("OpenLoading", self, self.OpenLoading)
  end
  self.Player:ClearTakeBall()
  rocoSkillComponent:StopCurrentSkill()
  rocoSkillComponent:LoadAndPlaySkill(self.SkillObject)
  self:CheckBlackUI()
  Log.Debug("BattlePlayerSkillPlayer SkillObject:", self.SkillObject:GetName())
  if ServerData.values.battleMode then
    local frameCount = self.SkillObject:GetLength() * self.SkillObject:GetFPS()
    local cmd = string.format("FxPerf.Start %s_%s %f", self.role_skill_cast.skill_id, self.SkillObject:GetDisplayName(), frameCount)
    UE4.UNRCStatics.ExecConsoleCommand(cmd)
  end
  self:ClearDelay()
  self.popupDelayID = _G.DelayManager:DelayFrames(36, self.HidePopup, self)
end

function BattlePlayerSkillPlayer:ClearDelay()
  if self.popupDelayID then
    _G.DelayManager:CancelDelayById(self.popupDelayID)
    self.popupDelayID = nil
  end
end

function BattlePlayerSkillPlayer:CheckBlackUI()
  if BattleUtils.IsSpecialDelayPve() and self.CastParam and self.CastParam.skillID == 7800505 and BattleUtils.HasUI("BattleLoading") then
    NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseLoading)
  end
end

function BattlePlayerSkillPlayer:OnHideBuffs()
  self:IsShowPetBuffs(false)
  self:HideTargetsBuffBar()
end

function BattlePlayerSkillPlayer:OnShowBuffs()
  self:IsShowPetBuffs(true)
  self:ShowTargetsBuffBar()
end

function BattlePlayerSkillPlayer:IsShowPetBuffs(_IsShow)
  BattleManager.battlePawnManager:IsShowPetBuffs(_IsShow)
end

function BattlePlayerSkillPlayer:OpenLoading(Name, Skill)
  if BattleManager.isInBattle then
    local asyncData = {
      owner = self,
      callback = function()
      end
    }
    NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenLoading)
  end
end

function BattlePlayerSkillPlayer:HidePopup()
  if not self.IsFinishSKill then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.Caster.player, self.Caster)
  end
end

function BattlePlayerSkillPlayer:ApplyDefaultCamera(Chain)
  if self.role_skill_cast.target_id then
    BattleUtils.PlayDefaultTargetCamera(self.role_skill_cast.target_id[1], Chain, Chain and Chain.Invoke)
  end
end

function BattlePlayerSkillPlayer:OnSkillFailed()
  Log.Error("BattlePlayerSkillPlayer OnSkillFailed")
  self:OnSkillComplete()
end

function BattlePlayerSkillPlayer:OnSkillComplete()
  Log.Debug("BattlePlayerSkillPlayer OnSkillComplete")
  self:ClearDelay()
  self:ShowPet()
  if self:IsChangePetSkill() then
    if self.newPet and self.newPet.model then
      if self.newPet.teamEnm == BattleEnum.Team.ENUM_TEAM then
        UE4.UNRCStatics.SetRenderCustomDepth(self.newPet.model, self.newPet.model.TeamXRayMaterial, nil, false)
      else
        UE4.UNRCStatics.SetRenderCustomDepth(self.newPet.model, self.newPet.model.EnemyXRayMaterial, nil, false)
      end
    end
  elseif self.cacheOriPetToDestroy and self.cacheOriPetToDestroy.model and UE.UObject.IsValid(self.cacheOriPetToDestroy.model) then
    if self.cacheOriPetToDestroy.teamEnm == BattleEnum.Team.ENUM_TEAM then
      UE4.UNRCStatics.SetRenderCustomDepth(self.cacheOriPetToDestroy.model, self.cacheOriPetToDestroy.model.TeamXRayMaterial, nil, false)
    else
      UE4.UNRCStatics.SetRenderCustomDepth(self.cacheOriPetToDestroy.model, self.cacheOriPetToDestroy.model.EnemyXRayMaterial, nil, false)
    end
  end
  if self.cacheOriPetToDestroy then
    if self:IsChangePetSkill() and self.newPet then
      self.cacheOriPetToDestroy:Destroy()
    else
      self.cacheOriPetToDestroy:SetIKEnable(true)
      self.cacheOriPetToDestroy.buffComponent:RestartBattleState()
    end
  end
  self.cacheOriPetToDestroy = nil
  if self.OldBoundsScale and self.Caster and self.Caster.model then
    self.Caster.model.mesh.BoundsScale = self.OldBoundsScale
    self.Caster.model.mesh.bNRCUseFixedSkelBounds = self.OldFixedSkelBounds
    self.OldBoundsScale = nil
  end
  self.IsFinishSKill = true
  if self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end
  if not BattleUtils.IsDeepWater() and self.Caster then
    self.Caster:EnableGravity(true)
  end
  if ServerData.values.battleMode then
    _G.BattleEventCenter:Dispatch(BattleEvent.FX_PERF_ON_SKILL_PLAY_PAUSE)
  end
  local isPerforming = false
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAYERSKILL_PERFORMING_UPDATE, isPerforming)
  self.performNode:PerformComplete()
  self:Release()
end

function BattlePlayerSkillPlayer:OnSkillCastMoment(castMoment, LimitType)
  self.performNode:DispatchPerformCallback(castMoment, LimitType)
end

function BattlePlayerSkillPlayer:ModifyWeather()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  self.revertWeather = EnvSys:GetWeatherStat()
  EnvSys:SetWeatherStat(Enum.WeatherType.WT_SUNNY, false, false)
end

function BattlePlayerSkillPlayer:RevertWeather()
  if self.revertWeather then
    local Instance = UE.UNRCPlatformGameInstance.GetInstance()
    local EnvSys = Instance and Instance:GetWorldSubSystem()
    EnvSys:SetWeatherStat(self.revertWeather, false, false)
  end
end

return BattlePlayerSkillPlayer
