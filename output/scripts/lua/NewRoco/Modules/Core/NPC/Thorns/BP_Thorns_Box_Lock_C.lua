require("UnLuaEx")
local NpcSkillPlayComponent = require("NewRoco.Modules.Core.NPC.ViewNPCComponent.NpcSkillPlayComponent")
local BP_Thorns_Box_Lock_C = NRCClass()

function BP_Thorns_Box_Lock_C:PlayDestroyEffect(DestroyedByFire)
  Log.Debug("BP_Thorns_Box_Lock_C:PlayDestroyEffect")
  local SkillClass = self.CutSKill
  if DestroyedByFire then
    SkillClass = self.BurnSkill
  end
  if self.skillPlayComponent == nil then
    self.skillPlayComponent = NpcSkillPlayComponent(self)
  end
  self.skillPlayComponent:PlaySkillByClass(SkillClass, self, nil, nil, self.OnSkillComplete, false)
end

function BP_Thorns_Box_Lock_C:OnSkillComplete(Name, Skill)
  self:K2_DestroyActor()
end

return BP_Thorns_Box_Lock_C
