local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local UMG_Battle_Characteristics_C = _G.NRCPanelBase:Extend("UMG_Battle_Characteristics_C")

function UMG_Battle_Characteristics_C:OnConstruct()
  self.pet = nil
end

function UMG_Battle_Characteristics_C:OnDestruct()
end

function UMG_Battle_Characteristics_C:OnActive()
end

function UMG_Battle_Characteristics_C:OnDeactive()
end

function UMG_Battle_Characteristics_C:OnAddEventListener()
end

function UMG_Battle_Characteristics_C:BindPet(Pet)
  self.pet = Pet
end

function UMG_Battle_Characteristics_C:Show(skill_id)
  local skill_cfg = _G.SkillUtils.GetSkillConf(skill_id)
  if skill_cfg.icon then
    self.Characteristics:SetPath(skill_cfg.icon)
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Resonance_In)
end

function UMG_Battle_Characteristics_C:OnAnimationFinished(Anim)
  if Anim == self.Resonance_In then
    self:PlayAnimation(self.Resonance_Out)
  elseif Anim == self.Resonance_Out then
    _G.BattleEventCenter:Dispatch(BattleEvent.ShowResonanceFinish, self.pet)
  end
end

return UMG_Battle_Characteristics_C
