local Base = BattleActionBase
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePetRidOfAction = Base:Extend("BattlePetRidOfAction")

function BattlePetRidOfAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
end

function BattlePetRidOfAction:OnEnter()
  self.buffTriggers = self.BattleManager.battleRuntimeData:GetCacheRidOfBuffTrigger()
  if not self.buffTriggers or 0 == #self.buffTriggers then
    self:Finish()
    return
  end
  self.curIndex = 1
  self:PlayBuffTrigger()
end

function BattlePetRidOfAction:PlayBuffTrigger()
  if self.curIndex > #self.buffTriggers then
    self:Finish()
    return
  end
  self.buffTrigger = self.buffTriggers[self.curIndex]
  self.curIndex = self.curIndex + 1
  self.Target = self.PawnManager:GetPetByGuid(self.buffTrigger.target_id)
  if not self.Target then
    Log.Error("there is ni Target!!!")
    self:PlayBuffTrigger()
    return
  end
  self.Caster = self.PawnManager:GetPetByGuid(self.buffTrigger.caster_id)
  if not (self.Caster and self.Caster.model) or self.Caster:IsDead() then
    Log.Error("there is ni caster!!!")
    self:PlayBuffTrigger()
    return
  end
  self.BuffConf = _G.DataConfigManager:GetBuffConf(self.buffTrigger.buff_id)
  if not self.BuffConf then
    self:PlayBuffTrigger()
    return
  end
  self.skillComponent = self.Caster.model.RocoSkill
  self.CastSkillParam = self:PrepareSkill()
  if not self.CastSkillParam then
    Log.Error("there is ni buff res!!!")
    self:PlayBuffTrigger()
    return
  end
  local buffShowEndTime = self.BattleManager.battleRuntimeData:GetParallelShowTime()
  local waitTime = buffShowEndTime - os.time()
  if waitTime > 0 then
    self.waitShowEnd = _G.DelayManager:DelaySeconds(waitTime, self.OnPlay, self)
    return
  end
  self.hasComplete = false
  self:OnPlay()
end

function BattlePetRidOfAction:PrepareSkill()
  local CastSkillParam = CastSkillObject.FromPerformInfoToBuffTrigger(self.buffTrigger)
  if not CastSkillParam then
    Log.Debug("BattleBuffPlayer no CastSkillParam: ", self.buffTrigger.buff_id)
    return nil
  end
  CastSkillParam:SetCaster(self.Caster.model):SetCompleteCallback(self.SkillComplete):SetCallbackOwner(self):SetHideBuffBarCallback(self.HideBuffBar):SetShowBuffBarCallback(self.ShowBuffBar):SetHideTargetsBuffBarCallback(self.HideTargetsBuffBar):SetShowTargetsBuffBarCallback(self.ShowTargetsBuffBar):SetSkillBreakCallback(self.SkillComplete):SetIsPassive(true):SetTargetPets({
    self.Target
  })
  return CastSkillParam
end

function BattlePetRidOfAction:HideBuffBar()
  self:HideCasterBuffBar()
  self:HideTargetsBuffBar()
end

function BattlePetRidOfAction:ShowBuffBar()
  self:ShowCasterBuffBar()
  self:ShowTargetsBuffBar()
end

function BattlePetRidOfAction:HideCasterBuffBar()
  if not self.Caster then
    return
  end
  self.Caster:ChangeBuffVisibility(false)
end

function BattlePetRidOfAction:ShowCasterBuffBar()
  if not self.Caster then
    return
  end
  self.Caster:ChangeBuffVisibility(true)
end

function BattlePetRidOfAction:HideTargetsBuffBar()
  if not self.Target then
    return
  end
  self.Target:ChangeBuffVisibility(false)
end

function BattlePetRidOfAction:ShowTargetsBuffBar()
  if not self.Target then
    return
  end
  self.Target:ChangeBuffVisibility(true)
end

function BattlePetRidOfAction:OnPlay()
  if self.waitShowEnd then
    _G.DelayManager:CancelDelayById(self.waitShowEnd)
    self.waitShowEnd = nil
  end
  self.Caster:SwimSetLockIdle(false)
  local rocoSkillComponent
  rocoSkillComponent, self.SkillObject = BattleSkillManager:PrepareSkill(self.Caster, self.skillComponent, self.CastSkillParam)
  if rocoSkillComponent and self.SkillObject then
    local result = rocoSkillComponent:PlaySkill(self.SkillObject)
    if result ~= UE4.ESkillStartResult.Success then
      Log.Warning("BattlePetRidOfAction:OnPlay", "PlaySkill failed", self.buffTrigger.buff_id, result)
      self:SkillComplete()
    end
  end
end

function BattlePetRidOfAction:SkillComplete()
  if self.hasComplete then
    return
  end
  self.hasComplete = true
  if self.Target then
    local hasReturn = self.BattleManager.battleRuntimeData:GetHasPetReturn(self.buffTrigger.target_id)
    if hasReturn then
      self.Target:ResetModelPos()
      self.Target:SetPetVisibility(true)
    elseif self.buffTrigger.need_select_pet and self.Target then
      self.Target.team:RecallPet(self.Target)
    end
  end
  self.SkillObject = nil
  self.Caster = nil
  self.Target = nil
  self.buffTrigger = nil
  self:PlayBuffTrigger()
end

function BattlePetRidOfAction:OnFinish()
  if self.BattleManager.vBattleField.battleCameraManager then
    self.BattleManager.vBattleField.battleCameraManager:CalcPos()
  end
  BattleSkillManager:ClearCache()
  self.PawnManager:ClearRequestDict()
  self.BattleManager.battleRuntimeData:ClearCacheRidOf()
end

return BattlePetRidOfAction
