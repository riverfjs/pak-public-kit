local EventDispatcher = require("Common.EventDispatcher")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleBuffChangePlayer = BattlePlayerBase:Extend()

function BattleBuffChangePlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
end

function BattleBuffChangePlayer:Reset()
  self.performNode = nil
  self.buff_change = nil
  self.BuffConf = nil
  self.Target = nil
  self.Team = nil
  self.Player = nil
  self.skillTarget = nil
  self:CancelDelay()
end

function BattleBuffChangePlayer:Play(performNode)
  self:Reset()
  self:InitFromNode(performNode)
  if self:CheckIsMimicBuffRemove() then
    self.Target = BattleManager.battlePawnManager:GetPetByGuid(self.buff_change.target_id)
    if self.Target and not self.Target:IsDead() and not self.Target.card:CheckIsMimic(true) then
      self.Team = self.Target.team
      self.Player = self.Team.player
      self:PawnNewPetModel()
    else
      self:OnSkillComplete()
    end
  elseif self:CheckIsNightMareBuffRemove() then
    self.hasMutationChangeTriggered = false
    self.Target = BattleManager.battlePawnManager:GetPetByGuid(self.buff_change.target_id)
    if self.Target then
      self.Target.buffComponent:RegisterSkillEventCallBack(ProtoEnum.BuffGroupSign.BGS_NIGHTMARE, self, BattleConst.NightmareMutationChangeEventName, self.OnTriggerMutationChange)
      self.nightmareRemoveDelay = _G.DelayManager:DelaySeconds(3, self.OnTriggerMutationChange, self)
    else
      self:OnSkillComplete()
    end
  elseif self:CheckIsBuffChange(ProtoEnum.BuffChangeType.BCT_ADD, ProtoEnum.BuffGroupSign.BGS_NIGHTMARE_ONE) then
    self.Target = BattleManager.battlePawnManager:GetPetByGuid(self.buff_change.target_id)
    self.Target.buffComponent:RegisterCompleteCallBack(ProtoEnum.BuffGroupSign.BGS_NIGHTMARE, self, self.OnSkillComplete)
    self.nightmareRemoveDelay = _G.DelayManager:DelaySeconds(2, self.OnSkillComplete, self)
  else
    self:OnSkillComplete()
  end
end

function BattleBuffChangePlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.buff_change = performInfo.buff_change
  if self.buff_change then
    self.BuffConf = _G.DataConfigManager:GetBuffConf(self.buff_change.buff_id)
  end
end

function BattleBuffChangePlayer:CheckIsMimicBuffRemove()
  if not self.buff_change or self.buff_change.type ~= ProtoEnum.BuffChangeType.BCT_REMOVE then
    return false
  end
  if not self.BuffConf then
    return false
  end
  local isMimic = false
  for _, sign in ipairs(self.BuffConf.buff_groupsigns) do
    if sign == ProtoEnum.BuffGroupSign.BGS_MIMIC or sign == ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC then
      isMimic = true
      break
    end
  end
  return isMimic
end

function BattleBuffChangePlayer:CheckIsNightMareBuffRemove()
  return self:CheckIsBuffChange(ProtoEnum.BuffChangeType.BCT_REMOVE, ProtoEnum.BuffGroupSign.BGS_NIGHTMARE)
end

function BattleBuffChangePlayer:CheckIsBuffChange(changeType, buffGroupSign)
  if not self.buff_change or self.buff_change.type ~= changeType then
    return false
  end
  if not self.BuffConf then
    return false
  end
  local isTargetBGS = false
  for _, sign in ipairs(self.BuffConf.buff_groupsigns) do
    if sign == buffGroupSign then
      isTargetBGS = true
      break
    end
  end
  return isTargetBGS
end

function BattleBuffChangePlayer:PawnNewPetModel()
  local card = self.Target.card
  if card then
    local realPetId = self.Target.card.petInfo.battle_inside_pet_info.base_conf_id
    _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED)
    card:RefreshByBaseConf(realPetId)
    self.Target:ShowPet()
    self.Target.buffComponent:RemoveBuffs(true)
    self.Target:ChangeBuffVisibility(false)
    self.newPet = BattleManager.battlePawnManager:PawnPet(self.Player.teamEnm, self.Player.team, card, self.Player, true)
  else
    self:OnSkillComplete()
  end
end

function BattleBuffChangePlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
    return true
  end
end

function BattleBuffChangePlayer:OnPawnNewPetFinish(pet)
  if not pet or not pet.model then
    self:OnSkillComplete()
    return
  end
  self.newPet = pet
  self.newPet:SetScale(1)
  local pos = self.newPet.model:Abs_K2_GetActorLocation()
  local halfHeight = pet:GetHalfHeight()
  local ans, posNew = LineTraceUtils.GetPointValidLocation(pos, halfHeight)
  posNew.Z = posNew.Z + self.newPet:GetHalfHeight()
  self.newPet.model:Abs_K2_SetActorLocation_WithoutHit(posNew)
  _G.BattleEventCenter:UnBind(self)
  self.oldPet = self.Target
  self.newPet:ShowPet()
  if self.performNode and self.performNode.IsFastPlay then
    self:OnSkillComplete()
  else
    self:OnPlay()
  end
end

function BattleBuffChangePlayer:OnPlay()
  if not self.Target or self.Target:IsDead() or self.performNode.IsFastPlay then
    self:OnSkillComplete()
    return
  end
  local skillClass = BattleResourceManager:GetCacheAssetDirect(BattleConst.MimicRemove)
  if skillClass then
    local caster = self.Target.model
    if self.Target.model and self.Target.model.MimicActor then
      local mimic = self.Target.model.MimicActor:GetChildActor()
      if mimic then
        caster = mimic
      end
    end
    self.skillTarget = self.Target
    local CastParam = CastSkillObject.Create()
    CastParam.SkillClass = skillClass
    CastParam:SetIsPassive(true)
    CastParam:SetCaster(caster)
    CastParam:SetCompleteCallback(self.OnSkillComplete):SetInterrupt(true):SetHideBuffBarCallback(self.HideBuffBar):SetShowBuffBarCallback(self.ShowBuffBar):SetHideTargetsBuffBarCallback(self.HideTargetsBuffBar):SetShowTargetsBuffBarCallback(self.ShowTargetsBuffBar):SetSkillBreakCallback(self.OnSkillBreakCallback):SetCallbackOwner(self):SetTargetPets({
      self.newPet
    }):SetExtraEvents({
      ActionStart = self.ShowPet
    })
    self.skillComponent = self.newPet.model.RocoSkill
    self.Target = self.newPet
    self.Target:SwimSetLockIdle(false)
    local rocoSkillComponent
    rocoSkillComponent, self.SkillObject = BattleSkillManager:PrepareSkill(self.Target, self.skillComponent, CastParam)
    if rocoSkillComponent and self.SkillObject then
      if not self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
        self.SkillObject.IsIgnoreCameraAction = true
      end
      self.newPet:HidePet()
      self.performNode:AddTimeoutDuration(self.SkillObject:GetLength())
      rocoSkillComponent:CancelSkill(self.SkillObject, UE4.ESkillActionResult.SkillActionResultSuccessful)
      rocoSkillComponent:PlaySkill(self.SkillObject)
      self.performNode.performPlayer:BuffSkillPlay(self.Target, self.SkillObject, self.buff_change.buff_id)
    else
      self:OnSkillComplete()
    end
  else
    self:OnSkillComplete()
  end
end

function BattleBuffChangePlayer:ShowPet()
  if not self.newPet then
    return
  end
  self.newPet:ShowPet()
end

function BattleBuffChangePlayer:HideBuffBar()
  self:HideCasterBuffBar()
end

function BattleBuffChangePlayer:ShowBuffBar()
  self:ShowCasterBuffBar()
end

function BattleBuffChangePlayer:HideCasterBuffBar()
  if not self.skillTarget then
    return
  end
  self.skillTarget:ChangeBuffVisibility(false)
end

function BattleBuffChangePlayer:ShowCasterBuffBar()
  if not self.skillTarget then
    return
  end
  self.skillTarget:ChangeBuffVisibility(true)
end

function BattleBuffChangePlayer:OnSkillBreakCallback()
  self:OnSkillComplete()
end

function BattleBuffChangePlayer:OnMimicFinish()
  if self.oldPet then
    table.insert(BattleManager.battlePawnManager.PendingKillBattlePets, self.oldPet)
  end
  if self.newPet then
    self.newPet:SetIKEnable(true)
  end
  if BattleManager.vBattleField.battleCameraManager then
    BattleManager.vBattleField.battleCameraManager:CalcPosCache()
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  else
    Log.Error("BattleBuffChangePlayer:OnMimicFinish battleCameraManager is nil")
  end
end

function BattleBuffChangePlayer:OnTriggerMutationChange()
  if self.hasMutationChangeTriggered then
    return
  end
  self.hasMutationChangeTriggered = true
  if self.Target then
    self.Target:ResetModelPos()
  end
  self.skillCompleteAfterMutationChangeDelay = _G.DelayManager:DelayFrames(1, self.OnSkillComplete, self)
  local card = self.Target.card
  if card then
    local mutationPetData = PetMutationUtils.GetDisplayMutationData(card, true)
    local target = self.Target
    local model = target and target.model
    if UE.UObject.IsValid(model) and model.ClearMaterials then
      model:ClearMaterials()
    end
    PetMutationUtils.DoMutation(self.Target.model, mutationPetData)
    _G.BattleEventCenter:Dispatch(BattleEvent.MutationChange, card.petInfo.battle_inside_pet_info.base_conf_id)
  end
end

function BattleBuffChangePlayer:OnSkillComplete()
  if self:CheckIsMimicBuffRemove() then
    self:OnMimicFinish()
  end
  if self.performNode then
    self.performNode:PerformComplete()
  end
  self:Reset()
end

function BattleBuffChangePlayer:Clear()
  BattlePlayerBase.Clear(self)
  self:CancelDelay()
end

function BattleBuffChangePlayer:CancelDelay()
  if self.skillCompleteAfterMutationChangeDelay then
    _G.DelayManager:CancelDelayById(self.skillCompleteAfterMutationChangeDelay)
    self.skillCompleteAfterMutationChangeDelay = nil
  end
  if self.nightmareRemoveDelay then
    _G.DelayManager:CancelDelayById(self.nightmareRemoveDelay)
    self.nightmareRemoveDelay = nil
  end
end

return BattleBuffChangePlayer
