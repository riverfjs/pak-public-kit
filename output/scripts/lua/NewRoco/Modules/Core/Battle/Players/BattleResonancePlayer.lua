local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleResonancePlayer = BattlePlayerBase:Extend()

function BattleResonancePlayer:Ctor()
  BattlePlayerBase.Ctor(self)
end

function BattleResonancePlayer:Reset()
end

function BattleResonancePlayer:Play(performNode)
  self:Reset()
  self.performNode = performNode
  self.performInfo = performNode:GetInfo()
  if self:GetRuntimeData("is_finish") == true then
    self:OnFinish()
    return
  end
  local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.performInfo.skill_cast.caster_id)
  if pet and pet.battlePetComponents then
    pet.battlePetComponents:ShowResonance(self.performInfo.skill_cast.skill_id)
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.ShowResonanceFinish)
end

function BattleResonancePlayer:OnBattleEvent(eventName, ...)
  if BattleEvent.ShowResonanceFinish == eventName then
    local pet = (...)
    if pet.guid == self.performInfo.skill_cast.caster_id then
      self:Finish()
    end
  end
end

function BattleResonancePlayer:OnFinish()
  self.performNode:PerformComplete()
end

function BattleResonancePlayer:Finish()
  if self:GetRuntimeData("is_finish") then
    return
  end
  self:SetRuntimeData("is_finish", true)
  self:OnFinish()
  _G.BattleEventCenter:Dispatch(BattleEvent.ResonanceSkillFinish, self.performInfo.group_id)
  _G.BattleEventCenter:UnBind(self)
end

return BattleResonancePlayer
