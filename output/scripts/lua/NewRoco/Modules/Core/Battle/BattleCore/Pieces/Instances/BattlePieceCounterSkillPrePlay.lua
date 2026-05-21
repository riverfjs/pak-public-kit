local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePiecesBase = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.BattlePiecesBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattlePiecesBase
local BattlePieceCounterSkillPrePlay = Base:Extend("BattlePieceCounterSkillPrePlay")

function BattlePieceCounterSkillPrePlay:OnPlay(Caster, CallBack, CallBackOwner, IsMySelfPerform)
  BattleEventCenter:Bind(self, BattleEvent.SKillEvent_LeaveBulletTime)
  self.CallBack = CallBack
  self.CallBackOwner = CallBackOwner
  self.isMySelfPerform = IsMySelfPerform
  self.Caster = Caster
  self.IsFocusPlayer = false
  self:LeaveBulletTime()
  local player = self.Caster.player
  if player and UE.UObject.IsValid(player.model) and not BattleUtils.IsPlayerUseHumanRes(player) and self.isMySelfPerform then
    self.IsFocusPlayer = true
    self:EnterBulletTime()
  end
  self:PlayPetFocus()
end

function BattlePieceCounterSkillPrePlay:EnterBulletTime()
  self.BulletTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.ActionPerform, UE.EBulletTimeChangeType.Change, self.Caster.model:GetWorld(), BattleConst.Show.CounterSkillTimeDilation, UE.EBulletTimeChangeType.Keep, {
    self.Caster.model,
    self.Caster.player.model
  }, 1)
end

function BattlePieceCounterSkillPrePlay:LeaveBulletTime()
  if not self.BulletTimeId then
    return
  end
  _G.BattleBulletTimeManager:LeaveBulletTime(self.BulletTimeId)
  self.BulletTimeId = nil
end

function BattlePieceCounterSkillPrePlay:PlayPetFocus()
  local skillClass = BattleResourceManager:GetCacheAssetDirect(BattleConst.CounterSkillPreFx)
  local CastParam = CastSkillObject.Create()
  CastParam.SkillClass = skillClass
  CastParam:SetIsPassive(true)
  CastParam:SetCaster(self.Caster.model)
  CastParam:SetCallbackOwner(self)
  CastParam:SetCompleteCallback(self.FocusPetOver):SetInterrupt(true)
  local com, skillObj = BattleSkillManager:PrepareSkill(self.Caster, self.Caster.model.RocoSkill, CastParam)
  self.skillObj = skillObj
  self:SetOnBulletTime(true)
  local result = self.Caster.model.RocoSkill:LoadAndPlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    self:FocusPetOver()
  end
end

function BattlePieceCounterSkillPrePlay:FocusPetOver()
  if self.IsFocusPlayer then
    self:PlayNPCFocus()
  else
    self:Complete()
  end
end

function BattlePieceCounterSkillPrePlay:PlayNPCFocus()
  local skillClass = BattleResourceManager:GetCacheAssetDirect(BattleConst.CounterSkillPreNpc)
  local CastParam = CastSkillObject.Create()
  CastParam.SkillClass = skillClass
  CastParam:SetIsPassive(true)
  CastParam:SetCaster(self.Caster.player.model)
  CastParam:SetTargetPets({
    self.Caster
  })
  CastParam:SetCallbackOwner(self)
  CastParam:SetCompleteCallback(self.OnFocusPlayerOver):SetInterrupt(true)
  local com, skillObj = BattleSkillManager:PrepareSkill(self.Caster.player, self.Caster.player.model.RocoSkill, CastParam)
  self.skillObj = skillObj
  if self.skillObj and BattleUtils.IsB1FinalBattleP1() then
    local Blackboard = self.skillObj:GetBlackboard()
    if Blackboard then
      Blackboard:SetValueAsString("MingLong3", "MingLong3")
    end
  end
  local result = self.Caster.player.model.RocoSkill:LoadAndPlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    self:Complete()
  end
end

function BattlePieceCounterSkillPrePlay:OnFocusPlayerOver()
  BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPetByCopeSkill(0)
  self:Complete()
end

function BattlePieceCounterSkillPrePlay:OnComplete()
  _G.BattleEventCenter:UnBind(self)
  self:LeaveBulletTime()
  if self.CallBack then
    self.CallBack(self.CallBackOwner)
  end
  self.skillObj = nil
  self.CallBack = nil
  self.CallBackOwner = nil
  self.Caster = nil
end

function BattlePieceCounterSkillPrePlay:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.SKillEvent_LeaveBulletTime then
    self:SetOnBulletTime(false)
    return true
  end
end

function BattlePieceCounterSkillPrePlay:SetOnBulletTime(isOn)
  if self.skillObj then
    local blackboard = self.skillObj:GetBlackboard()
    if blackboard then
      blackboard:SetValueAsBool("OnBulletTime", isOn)
    end
  end
end

return BattlePieceCounterSkillPrePlay
