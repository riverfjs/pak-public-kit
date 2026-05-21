local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = NRCClass()
CastSkillObject.objectLst = {}
WeakTable(CastSkillObject.objectLst)

function CastSkillObject:Ctor()
  self.SkillCmd = nil
  self.BuffCmd = nil
  self.IsBuffShow = false
  self.Caster = nil
  self.Targets = nil
  self.Characters = nil
  self.ResID = ""
  self.CallbackOwner = nil
  self.PerformCallback = nil
  self.CompleteCallback = nil
  self.OnStartFailedCallback = nil
  self.SkipBackswingCallback = nil
  self.OnCounterCallback = nil
  self.OnInterruptCallback = nil
  self.OnCopingCallback = nil
  self.OnRoleMagicChangeModelCallback = nil
  self.OnBeingAttackedCallback = nil
  self.OnHitCallback = nil
  self.OnHitComboCallback = nil
  self.OnFlyEnergyCallback = nil
  self.OnLastHitCallBack = nil
  self.ShowBuffBarCallback = nil
  self.HideBuffBarCallback = nil
  self.ShowTargetsBuffBarCallback = nil
  self.HideTargetsBuffBarCallback = nil
  self.ShowHPBarCallback = nil
  self.HideHPBarCallback = nil
  self.HidePopupCallback = nil
  self.ShowPopupCallback = nil
  self.OpenUICallback = nil
  self.InterruptBeCounterSkill = nil
  self.OnAllHitEnd = nil
  self.OnStateEffectEndCallback = nil
  self.OnNormalDefendEnd = nil
  self.Interrupt = false
  self.AcceptPreEnd = false
  self.skillID = nil
  self.buffID = nil
  self.Power = 1
  self.IsRestraint = false
  self.IsRestrained = false
  self.ReduceHP = 0.0
  self.IsPassive = false
  self.TargetPets = nil
  self.SpType = -1
  self.DamageType = 0
  self.CounterActor = nil
  self.BeCounterActor = nil
  BattleResourceManager:AttachCastSkillObject(self)
end

function CastSkillObject:IsValid(isLogIllegalMsg)
  Log.Debug("CastSkillObject IsValid:", self.ResID)
  if nil == isLogIllegalMsg then
    isLogIllegalMsg = true
  end
  if string.IsNilOrEmpty(self.ResID) then
    return false
  end
  if not _G.StopCheckBattleSkillResIsExist then
    Log.Debug("CastSkillObject IsValid check skill res is exist:", self.ResID)
    self.SkillClass = BattleSkillManager:GetLoadedClass(self.ResID)
    if not self.SkillClass then
      self.SkillClass = UE4.USkillRecordLibrary.AnalyzeSkill(self.ResID).Object
      Log.Error("CastSkillObject IsValid\232\181\176\232\191\155\228\186\134\229\188\186\229\136\182\229\144\140\230\173\165\229\138\160\232\189\189\228\191\157\230\138\164\233\128\187\232\190\145:", self.ResID)
    end
    if not self.SkillClass then
      if isLogIllegalMsg then
        Log.ErrorFormat("\230\138\128\232\131\189\232\181\132\230\186\144%s\228\184\162\229\149\166\239\188\129\231\173\150\229\136\146\231\190\142\230\156\175\232\181\182\231\180\167\230\159\165\229\149\138\239\188\129\239\188\129\239\188\129\239\188\129", self.ResID)
      end
      return false
    end
  else
    return true
  end
  return true
end

function CastSkillObject:ReleaseSkill()
  self.SkillClass = nil
  UE4.USkillRecordLibrary.ReleaseSkill(self.ResID)
end

function CastSkillObject:SetCallbackOwner(owner)
  self.CallbackOwner = owner
  return self
end

function CastSkillObject:SetPerformCallback(callback)
  self.PerformCallback = callback
end

function CastSkillObject:SetCompleteCallback(callback)
  self.CompleteCallback = callback
  if not self.OnSkillBreakCallback then
    self:SetSkillBreakCallback(callback)
  end
  return self
end

function CastSkillObject:SetSkipMeleeBackswingCallback(callback)
  self.SkipMeleeBackswingCallback = callback
  return self
end

function CastSkillObject:SetSkipRangedBackswingCallback(callback)
  self.SkipRangedBackswingCallback = callback
  return self
end

function CastSkillObject:SetOnRoleMagicChangeModelCallback(callback)
  self.OnRoleMagicChangeModelCallback = callback
  return self
end

function CastSkillObject:SetOnBeingAttackedCallback(callback)
  self.OnBeingAttackedCallback = callback
end

function CastSkillObject:SetOnHitCallback(callback)
  self.OnHitCallback = callback
  return self
end

function CastSkillObject:SetOnInterruptCallback(callback)
  self.OnInterruptCallback = callback
  return self
end

function CastSkillObject:SetOnCopingCallback(callback)
  self.OnCopingCallback = callback
  return self
end

function CastSkillObject:SetOnRemoveCutsceneBlackGround(callback)
  self.OnRemoveCutsceneBlackGround = callback
  return self
end

function CastSkillObject:SetOnCounterCallback(callback)
  self.OnCounterCallback = callback
  return self
end

function CastSkillObject:SetOnHitComboCallback(callback)
  self.OnHitComboCallback = callback
  return self
end

function CastSkillObject:SetOnFlyEnergyCallback(callback)
  self.OnFlyEnergyCallback = callback
  return self
end

function CastSkillObject:SetOnCounterEndCallback(callback)
  self.OnCounterEndCallback = callback
  return self
end

function CastSkillObject:SetOnStopBulletTime(callback)
  self.OnStopBulletTime = callback
  return self
end

function CastSkillObject:SetOnAllHitEnd(callback)
  self.OnAllHitEnd = callback
  return self
end

function CastSkillObject:SetOnStateEffectEnd(callback)
  self.OnStateEffectEndCallback = callback
  return self
end

function CastSkillObject:SetOnNormalDefendEnd(callback)
  self.OnNormalDefendEnd = callback
  return self
end

function CastSkillObject:SetOnOtherPetPerformCallback(callback)
  self.OnOtherPetPerformCallback = callback
  return self
end

function CastSkillObject:SetTriggerBeforeHitCallback(callback)
  self.OnTriggerBeforeHitCallback = callback
  return self
end

function CastSkillObject:SetHideBuffBarCallback(callback)
  self.HideBuffBarCallback = callback
  return self
end

function CastSkillObject:SetShowBuffBarCallback(callback)
  self.ShowBuffBarCallback = callback
  return self
end

function CastSkillObject:SetHideTargetsBuffBarCallback(callback)
  self.HideTargetsBuffBarCallback = callback
  return self
end

function CastSkillObject:SetShowTargetsBuffBarCallback(callback)
  self.ShowTargetsBuffBarCallback = callback
  return self
end

function CastSkillObject:SetHideHPBarCallback(callback)
  self.HideHPBarCallback = callback
  return self
end

function CastSkillObject:SetShowHPBarCallback(callback)
  self.ShowHPBarCallback = callback
  return self
end

function CastSkillObject:SetHidePopupCallback(callback)
  self.HidePopupCallback = callback
  return self
end

function CastSkillObject:SetShowPopupCallback(callback)
  self.ShowPopupCallback = callback
  return self
end

function CastSkillObject:SetOpenUICallback(callback)
  self.OpenUICallback = callback
  return self
end

function CastSkillObject:SetInterruptBeCounterSkill(callback)
  self.InterruptBeCounterSkill = callback
  return self
end

function CastSkillObject:SetLastHitCallback(callback)
  self.OnLastHitCallBack = callback
  return self
end

function CastSkillObject:SetStartFailedCallback(callback)
  self.OnStartFailedCallback = callback
  return self
end

function CastSkillObject:SetSkillBreakCallback(callback)
  self.OnSkillBreakCallback = callback
  return self
end

function CastSkillObject:SetExtraEvents(extraEvents)
  self.ExtraEvents = extraEvents
  return self
end

function CastSkillObject:AddExtraEvent(name, callBack)
  if not self.ExtraEvents then
    self.ExtraEvents = {}
  end
  self.ExtraEvents[name] = callBack
  return self
end

function CastSkillObject:SetInterrupt(interrupt)
  Log.Debug("CastSkillObject SetInterrupt:", interrupt)
  self.Interrupt = interrupt
  return self
end

function CastSkillObject:SetCaster(caster)
  self.Caster = caster
  return self
end

function CastSkillObject:SetCounterActor(counter)
  self.CounterActor = counter
  return self
end

function CastSkillObject:SetBeCounterActor(beCounter)
  self.BeCounterActor = beCounter
  return self
end

function CastSkillObject:SetTargets(targets)
  self.Targets = targets
  return self
end

function CastSkillObject:SetTargetPets(targetPets)
  self.TargetPets = targetPets
  return self
end

function CastSkillObject:SetCharacters(characters)
  self.Characters = characters
  return self
end

function CastSkillObject:SetAcceptPreEnd(accept)
  self.AcceptPreEnd = accept
  return self
end

function CastSkillObject:SetPower(Power)
  self.Power = Power or 1
  return self
end

function CastSkillObject:SetIsRestraint(IsRestraint)
  self.IsRestraint = IsRestraint
  return self
end

function CastSkillObject:SetIsRestrained(IsRestrained)
  self.IsRestrained = IsRestrained
  return self
end

function CastSkillObject:SetReduceHP(ReduceHP)
  self.ReduceHP = ReduceHP
  return self
end

function CastSkillObject:SetDynamicData(Data)
  self.DynamicData = Data
  return self
end

function CastSkillObject:HasExtraEvent(event)
  return self.ExtraEvents and self.ExtraEvents[event] ~= nil
end

function CastSkillObject:SetDamageType(damageType)
  self.DamageType = damageType
  return self
end

function CastSkillObject:SetIsPassive(IsPassive)
  self.IsPassive = IsPassive
  return self
end

function CastSkillObject:SetSpType(spType)
  self.SpType = spType
  return self
end

function CastSkillObject:AddBlackStringValue(key, Value)
  if not self.BlackStringValue then
    self.BlackStringValue = {}
  end
  self.BlackStringValue[key] = Value
end

function CastSkillObject:AddActorKey(actor, key)
  if not self.ActorStringValue then
    self.ActorStringValue = {}
  end
  if not self.ActorStringValue[actor] then
    self.ActorStringValue[actor] = {}
  end
  table.insert(self.ActorStringValue[actor], key)
  return nil
end

function CastSkillObject:RegisterEventCallback(eventName, caller, callback)
end

function CastSkillObject.FromPerformInfoToSkill(skill_cast, skillResChange)
  if not skill_cast then
    Log.Error("no skill_cast")
    return nil
  end
  local Obj = CastSkillObject.Create()
  Obj.skillID = skill_cast.skill_id
  local RealSkillID = skill_cast.skill_id
  local SkillConf
  SkillConf = _G.SkillUtils.GetSkillConf(RealSkillID, true)
  if not SkillConf then
    Log.Error("CastSkillObject.FromPerformInfoToSkill cannt find SkillConf:", RealSkillID, skill_cast.skill_id)
    return nil
  end
  local SkillRes
  if skillResChange then
    SkillRes = skillResChange.res_id
  else
    SkillRes = SkillConf.res_id
  end
  Obj.DamageType = SkillConf.damage_type
  Obj.skillID = RealSkillID
  Obj.ResID = SkillRes
  if not Obj:IsValid() then
    Log.Warning("skill ", ": ", RealSkillID, " ", "obj of res_id is not valid")
    return nil
  end
  return Obj
end

function CastSkillObject.FromPerformInfoToPlayerSkill(role_skill_cast)
  if not role_skill_cast then
    Log.Error("no role_skill_cast")
    return nil
  end
  local Obj = CastSkillObject.Create()
  Obj.skillID = role_skill_cast.skill_id
  local RealSkillID = role_skill_cast.skill_id
  local SkillConf = _G.DataConfigManager:GetSkillConf(RealSkillID, true)
  if not SkillConf then
    return nil
  end
  local SkillRes = SkillConf.res_id
  Obj.DamageType = SkillConf.damage_type
  Obj.skillID = RealSkillID
  Obj.ResID = SkillRes
  if not Obj:IsValid() then
    Log.Warning("skill ", ": ", RealSkillID, " ", "obj of res_id is not valid")
    return nil
  end
  return Obj
end

function CastSkillObject.FromPerformInfoToBuffTrigger(buff_trigger)
  if not buff_trigger then
    Log.Error("no buff_trigger")
    return nil
  end
  local Obj = CastSkillObject.Create()
  Obj.buffID = buff_trigger.buff_id
  Obj.perform_type = buff_trigger.perform_type
  local RealBuffID = buff_trigger.buff_id
  local BuffConf = _G.DataConfigManager:GetBuffConf(RealBuffID, true)
  if not BuffConf then
    return nil
  end
  local perform_type = buff_trigger.perform_type
  local BuffRes = BuffConf["res_id_" .. perform_type]
  if not BuffRes then
    return nil
  end
  Obj.ResID = BuffRes
  if not Obj:IsValid() then
    return nil
  end
  return Obj
end

function CastSkillObject.FromPerformInfoToSpEnergyTrigger(sp_energy_trigger)
  if not sp_energy_trigger then
    Log.Error("no sp_energy_trigger")
    return nil
  end
  local Obj = CastSkillObject.Create()
  Obj:SetSpType(-1)
  local BuffRes
  if sp_energy_trigger.trigger_type == ProtoEnum.BattleSpEnergyTrigger.SP_TRIGGER_TYPE.SP_TRIGGER_SKILL then
    BuffRes = BattleConst.SpEnergy.TriggerSkillPathTmp
  else
    local curStack = _G.BattleManager.battleRuntimeData:GetSpEnergyStackByType(sp_energy_trigger.dam_type)
    local fieldConf = _G.DataConfigManager:GetFieldLayerConf(curStack, true)
    if fieldConf then
      BuffRes = fieldConf.res_id
    else
      BuffRes = BattleConst.SpEnergy.TriggerSkillPathTmp
    end
  end
  Obj.ResID = BuffRes
  if not Obj:IsValid() then
    return nil
  end
  return Obj
end

function CastSkillObject.FromBuffIDKeep(buffID)
  if not buffID then
    return nil
  end
  Log.Debug("CastSkillObject FromBuffIDKeep:", buffID)
  local Obj = CastSkillObject.Create()
  Obj.IsBuffShow = true
  Obj.buffID = buffID
  local conf = _G.DataConfigManager:GetBuffConf(buffID)
  if not conf then
    return nil
  end
  if conf.res_id then
    Obj.ResID = conf.res_id .. "Keep"
    Log.Debug("CastSkillObject FromBuffIDKeep ResID:", Obj.ResID)
    if not Obj:IsValid(false) then
      return nil
    end
  else
    return nil
  end
  Log.Debug("CastSkillObject FromBuffIDKeep do succ:", Obj.buffID, Obj.ResID)
  return Obj
end

function CastSkillObject.FromBuffIDExit(buffID)
  if not buffID then
    return nil
  end
  Log.Debug("CastSkillObject FromBuffIDExit:", buffID)
  local Obj = CastSkillObject.Create()
  Obj.IsBuffShow = true
  local conf = _G.DataConfigManager:GetBuffConf(buffID)
  if not conf then
    return nil
  end
  if conf.res_id then
    Obj.ResID = conf.res_id .. "Exit"
    Log.Debug("CastSkillObject FromBuffIDExit ResID:", Obj.ResID)
    if not Obj:IsValid(false) then
      return nil
    end
  else
    return nil
  end
  return Obj
end

function CastSkillObject.FromSkillResID(resID)
  local Obj = CastSkillObject.Create()
  Obj.ResID = resID
  if not Obj:IsValid() then
    return nil
  end
  return Obj
end

function CastSkillObject.FromSkillID(skillID)
  local skillClass = BattleUtils.GetSkillClass(skillID)
  local obj = CastSkillObject.Create()
  obj.SkillClass = skillClass
  return obj
end

function CastSkillObject.Create()
  local obj = CastSkillObject()
  table.insert(CastSkillObject.objectLst, obj)
  return obj
end

return CastSkillObject
