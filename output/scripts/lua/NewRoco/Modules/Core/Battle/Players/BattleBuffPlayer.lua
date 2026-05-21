local EventDispatcher = require("Common.EventDispatcher")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local Enum = require("Data.Config.Enum")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleBuffPlayer = BattlePlayerBase:Extend()

function BattleBuffPlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.playerType = 2
  self.PawnManager = BattleManager.battlePawnManager
  self.Caster = nil
  self.TurnPlayer = nil
end

function BattleBuffPlayer:Reset()
  self.Caster = nil
  self.BuffConf = nil
  self.BuffBaseConf = nil
  self.isSleepingNodeTriggered = false
end

function BattleBuffPlayer:Play(performNode)
  self:Reset()
  self.BattleManager = _G.BattleManager
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.BuffTrigger = performInfo.buff_trigger
  Log.Debug("BattleBuffPlayer Play :", self.performNode:GetNodeIdx(), self.BuffTrigger.caster_id, self.BuffTrigger.buff_id, self.BuffTrigger.perform_type)
  self.Target = self.PawnManager:GetPetByGuid(self.BuffTrigger.target_id)
  if BattleManager.isPureLogicMode then
    self:Finish()
    return
  end
  if not self.Target then
    self:Finish()
    return
  end
  self.Team = self.Target.team
  self.Player = self.Team.player
  self.Caster = self.PawnManager:GetPetByGuid(self.BuffTrigger.caster_id)
  if not self.Caster or not self.Caster.model then
    Log.Error("there is ni caster!!!")
    self:Finish()
    return
  end
  self.BuffConf = _G.DataConfigManager:GetBuffConf(self.BuffTrigger.buff_id)
  if not self.BuffConf then
    self:Finish()
    return
  end
  if not self.BuffTrigger.buffbase_ids then
    Log.Error("\229\144\142\229\143\176\230\149\176\230\141\174\229\188\130\229\184\184buffbase_ids\228\184\186\231\169\186,buffID:", self.BuffTrigger.buff_id)
    self:Finish()
    return
  end
  self.BuffBaseConf = _G.DataConfigManager:GetBuffbaseConf(self.BuffTrigger.buffbase_ids[1])
  if not self.BuffBaseConf then
    Log.Error("BattleBuffPlayer:Play \230\149\176\230\141\174\229\188\130\229\184\184, buffID:, buff base conf id", self.BuffTrigger.buff_id, self.BuffTrigger.buffbase_ids[1])
    self:Finish()
    return
  end
  if not self.Caster.buffComponent:CanPlayBuff(self.BuffTrigger.buff_id) then
    self:Finish()
    return
  end
  if BuffUtils.IsFreezeBuff(self.BuffTrigger.buff_id) and not self.BuffTrigger.frozen_death then
    self:Finish()
    return
  end
  if BuffUtils.IsRidOfBuff(self.BuffTrigger.buff_id) and self.BattleManager.battleRuntimeData:IsDelayRiOf() then
    self.BattleManager.battleRuntimeData:AddCacheRidOfBuffTrigger(self.BuffTrigger)
    self:Finish()
    return
  end
  self:TryTurnToTarget()
  self.CastSkillParam = self:PrepareSkill()
  self.skillComponent = self.Caster.model.RocoSkill
  self.CastPet = self.Caster
  if not self.CastSkillParam then
    self:Finish()
    return
  end
  local performPlayer = self.performNode.performPlayer
  if performPlayer then
    if performPlayer:CheckBuffRepeatByRes(self.CastSkillParam.ResID, self.BuffTrigger.target_id) then
      self:Finish()
      return
    end
    performPlayer:RecordBuffPlayedRes(self.CastSkillParam.ResID, self.BuffTrigger.target_id)
  end
  self:OnPlay()
end

function BattleBuffPlayer:PrepareSkill()
  local CastSkillParam = CastSkillObject.FromPerformInfoToBuffTrigger(self.BuffTrigger)
  if not CastSkillParam then
    Log.Debug("BattleBuffPlayer no CastSkillParam: ", self.BuffTrigger.buff_id)
    return nil
  end
  local DontAcceptPreEnd = false
  local casterModel = self:GetCasterModel()
  CastSkillParam:SetCaster(casterModel):SetCompleteCallback(self.OnSkillComplete):SetOnHitCallback(self.OnHit):SetOnFlyEnergyCallback(self.OnFlyEnergy):SetCallbackOwner(self):SetInterrupt(false):SetAcceptPreEnd(not DontAcceptPreEnd):SetDamageType(Enum.DamageType.DT_NONE):SetHideBuffBarCallback(self.HideBuffBar):SetShowBuffBarCallback(self.ShowBuffBar):SetHideTargetsBuffBarCallback(self.HideTargetsBuffBar):SetShowTargetsBuffBarCallback(self.ShowTargetsBuffBar):SetSkillBreakCallback(self.OnSkillBreakCallback):SetIsPassive(true):SetTriggerBeforeHitCallback(self.OnTriggerBeforeHit)
  if self.performNode.IsLastHitNode then
    CastSkillParam:SetLastHitCallback(self.OnLastHit)
  end
  CastSkillParam:SetTargetPets(self:GetTargetPets())
  return CastSkillParam
end

function BattleBuffPlayer:OnPlay()
  if self.Caster:IsDead() then
    self:Finish()
    return
  end
  self.Caster:SwimSetLockIdle(false)
  local rocoSkillComponent
  rocoSkillComponent, self.SkillObject = BattleSkillManager:PrepareSkill(self.Caster, self.skillComponent, self.CastSkillParam)
  if not self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    self.SkillObject.IsIgnoreCameraAction = true
  end
  Log.Debug("BattleBuffPlayer:OnPlay ", self.BuffTrigger.buff_id)
  self:ScanEnergyPerform()
  self:CheckDefenceOther()
  self.performNode:AddTimeoutDuration(self.SkillObject:GetLength())
  local prePlayTime = SkillUtils.SpeedUpSkillEndEvent(self.SkillObject)
  if prePlayTime > 0 then
    self.BattleManager.battleRuntimeData:SetParallelShowTime(prePlayTime)
  end
  rocoSkillComponent:CancelSkill(self.SkillObject, UE4.ESkillActionResult.SkillActionResultSuccessful)
  rocoSkillComponent:PlaySkill(self.SkillObject)
  self.performNode.performPlayer:BuffSkillPlay(self.Caster, self.SkillObject, self.BuffTrigger.buff_id)
  self:CheckParallelPlay()
end

function BattleBuffPlayer:CheckParallelPlay()
  if not self.BattleManager.battleRuntimeData:GetCacheRidOfBuffTrigger() then
    return
  end
  if not BuffUtils.IsParallelBuff(self.BuffTrigger.buff_id) then
    return
  end
  local maxShowTime = BuffUtils.MaxParallelBuffTime()
  local currentEndTime = os.time() + math.min(maxShowTime, self.SkillObject:GetLength())
  self.BattleManager.battleRuntimeData:SetParallelShowTime(currentEndTime)
  self:Finish()
end

function BattleBuffPlayer:CheckDefenceOther()
  if self.BuffBaseConf.buffbase_order == Enum.BuffType.BFT_O_TWELVE then
    BattleEventCenter:Dispatch(BattleEvent.DefenceOtherStart, self.Caster.guid)
  end
end

function BattleBuffPlayer:OnSkillCastMoment(castMoment)
  if not self.performNode then
    return
  end
  self.performNode:DispatchPerformCallback(castMoment)
end

function BattleBuffPlayer:OnSkillComplete()
  if not self.performNode then
    return
  end
  if self:CheckIsSleepSkill() then
    if self.isSleepingNodeTriggered == false then
      self:SafeDelayFrames("d_SkillComplete", 2, self.SkillComplete, self)
      self.isSleepingNodeTriggered = true
    end
  else
    self:SafeDelayFrames("d_SkillComplete", 2, self.SkillComplete, self)
  end
end

function BattleBuffPlayer:OnSkillBreakCallback()
  self:OnSkillComplete()
end

function BattleBuffPlayer:OnTriggerBeforeHit()
  self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnBeforeHit)
end

function BattleBuffPlayer:HideBuffBar()
  self:HideCasterBuffBar()
  self:HideTargetsBuffBar()
end

function BattleBuffPlayer:ShowBuffBar()
  self:ShowCasterBuffBar()
  self:ShowTargetsBuffBar()
end

function BattleBuffPlayer:HideCasterBuffBar()
  if not self.Caster then
    return
  end
  self.Caster:ChangeBuffVisibility(false)
end

function BattleBuffPlayer:ShowCasterBuffBar()
  if not self.Caster then
    return
  end
  self.Caster:ChangeBuffVisibility(true)
end

function BattleBuffPlayer:HideTargetsBuffBar()
  if not self.Target then
    return
  end
  self.Target:ChangeBuffVisibility(false)
end

function BattleBuffPlayer:ShowTargetsBuffBar()
  if not self.Target then
    return
  end
  self.Target:ChangeBuffVisibility(true)
end

function BattleBuffPlayer:CheckIsSleepSkill()
  if not self.CastSkillParam then
    return false
  end
  if self.CastSkillParam and self.CastSkillParam.ResID == BattleConst.Define.SleepResID then
    return true
  end
  return false
end

function BattleBuffPlayer:SkillComplete()
  if not self.BuffTrigger then
    return
  end
  BattleUtils:RestartBattleState(self:GetTargetPets())
  self.performNode:PerformComplete()
  if not self.BattleManager.battleRuntimeData:IsDelayRiOf() then
    local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.BuffTrigger.target_id)
    if pet then
      if self.BattleManager.battleRuntimeData:GetHasPetReturn(self.BuffTrigger.target_id) then
        self.Target:ResetModelPos()
        self.Target:SetPetVisibility(true)
      elseif self.BuffTrigger.need_select_pet then
        pet.team:RecallPet(pet)
      end
    end
  end
  self:ClearRef()
end

function BattleBuffPlayer:OnLastHit()
end

function BattleBuffPlayer:OnAnimationHit()
  self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnAnimationHit)
end

function BattleBuffPlayer:OnHit()
  do
    local buffTrigger = self.BuffTrigger
    local buffBaseConf = self.BuffBaseConf
    local targetId = buffTrigger and buffTrigger.target_id
    local buffBaseOrder = buffBaseConf and buffBaseConf.buffbase_order
    local buffId = buffTrigger and buffTrigger.buff_id
    _G.BattleEventCenter:Dispatch(BattlePerformEvent.BuffTriggerOnHit, targetId, buffBaseOrder, buffId)
  end
  if self:CheckIsSleepSkill() then
    if self.isSleepingNodeTriggered == false then
      self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnHit)
      self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnAnimationHit)
      self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnAttackHit)
      self.isSleepingNodeTriggered = true
    end
  else
    self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnHit)
    self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnAnimationHit)
    self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnAttackHit)
  end
end

function BattleBuffPlayer:OnFlyEnergy()
  self:OnSkillCastMoment(ProtoEnum.Buffbasetrigger_type.OnFlyEnergy)
end

function BattleBuffPlayer:PlayPassiveBuff()
  Log.Trace("BattleBuffPlayer PlayPassiveBuff:", self.BuffCmd.dont_play)
  self.CurrentChain:Invoke()
end

function BattleBuffPlayer:Finish()
  self:OnHit()
  self:SkillComplete()
end

function BattleBuffPlayer:ClearRef()
  self.SkillObject = nil
  self.CastPet = nil
  self.performNode = nil
  self.Player = nil
  self.BuffTrigger = nil
  self.PerformInfo = nil
  self:Release()
end

function BattleBuffPlayer:GetPetWithID(id)
  local pet = self.PawnManager:GetPetByGuid(id)
  return pet
end

function BattleBuffPlayer:GetCasterModel()
  if self.BuffBaseConf.buffbase_order == Enum.BuffType.BFT_O_TWEENTYSEVEN or self.BuffBaseConf.buffbase_order == Enum.BuffType.BFT_O_TWEENTYEIGHT then
    return self.Player and self.Player.model
  end
  return self.Caster and self.Caster.model
end

function BattleBuffPlayer:GetTargetPets()
  local pets = {}
  local pet = BattleUtils.GetPetWithID(self.BuffTrigger.target_id)
  if pet then
    table.insert(pets, pet)
  end
  return pets
end

function BattleBuffPlayer:TryTurnToTarget()
  local performGroup = self.performNode and self.performNode.OwnerGroup
  if performGroup then
    if performGroup.IsProcessCounter then
      return
    end
    if performGroup.OwnerCluster.HeadGroup.HeadNode:IsCopeSkill() then
      return
    end
  end
  if self.Caster and self.Target then
    if self.Target and self.Target.teamEnm ~= self.Caster.teamEnm then
      self.Caster:SetTurnTo(self.Target, true)
      self.Target:SetTurnTo(self.Caster, true)
    else
      self.Caster:ResetRotation(true)
    end
  end
end

function BattleBuffPlayer:ScanEnergyPerform()
  if SkillUtils.SkillObjHasLuaEvent(self.SkillObject, UE4.ERocoSkillLuaEventType.FlyEnergy) then
    SkillUtils.ScanEnergyPerform(self.performNode, self.BuffBaseConf.id)
  end
end

return BattleBuffPlayer
