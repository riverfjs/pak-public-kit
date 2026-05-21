local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local AbnormalStatus_SkillBase = Base:Extend("AbnormalStatus_SkillBase")

function AbnormalStatus_SkillBase:Ctor(owner)
  Base.Ctor(self, owner)
  self.currentSkill = nil
  self.skillProxy = nil
  self.skillPath = nil
end

function AbnormalStatus_SkillBase:OnExecute()
  Base.OnExecute(self)
  if self.skillProxy then
    self.skillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  if not self.skillPath then
    return
  end
  local view = self:GetOwnerView()
  local skillComp = view and view.RocoSkill
  if not skillComp then
    return
  end
  local priority = _G.PriorityEnum.Other_Player_Logic
  if self:IsLocalPlayer() then
    priority = _G.PriorityEnum.Local_Player_Logic
  end
  self.skillProxy = RocoSkillProxy.Create(self.skillPath, skillComp, priority)
  self.skillProxy:SetCaster(view)
  self.skillProxy:SetTargets({view})
  self.skillProxy:RegisterEventCallback("ActivateFailed", self, self.OnSkillFailed)
  self.skillProxy:RegisterEventCallback("PreStart", self, self.OnSkillPreStart)
  self.skillProxy:RegisterEventCallback("End", self, self.OnSkillEnd)
  self.skillProxy:SetPassive(true)
  self.skillProxy:PlaySkill()
end

function AbnormalStatus_SkillBase:OnRemove(bForce)
  if bForce then
    if self.skillProxy then
      self.skillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
  else
    if UE.UObject.IsValid(self.currentSkill) then
      local blackboard = self.currentSkill:GetBlackboard()
      if blackboard then
        blackboard:SetValueAsInt("Continue", 0)
      end
    end
    if self.skillProxy then
      self.skillProxy:ReleaseRequest()
    end
  end
  Base.OnRemove(self, bForce)
end

function AbnormalStatus_SkillBase:OnSkillFailed(event, skillObj)
  Log.PrintScreenMsg("AbnormalStatus_SkillBase:OnSkillFailed path=%s", self.skillPath or "nil")
  self:OnSkillEnd(event, skillObj)
end

function AbnormalStatus_SkillBase:OnSkillPreStart(event, skillObj)
  if not UE.UObject.IsValid(skillObj) then
    return
  end
  self.currentSkill = skillObj
  local blackboard = skillObj:GetBlackboard()
  if not blackboard then
    return
  end
  local owner = self:GetOwner()
  if not owner then
    return
  end
  if owner.IsMagicReplayActor and owner:IsMagicReplayActor() then
  else
    blackboard:SetValueAsString("NoVideoMagic", "NoVideoMagic")
  end
  blackboard:SetValueAsInt("Continue", -1)
end

function AbnormalStatus_SkillBase:OnSkillEnd(event, skillObj)
  self.currentSkill = nil
  self.skillProxy = nil
end

return AbnormalStatus_SkillBase
