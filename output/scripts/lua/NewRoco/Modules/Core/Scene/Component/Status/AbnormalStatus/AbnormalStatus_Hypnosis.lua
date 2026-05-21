local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatus_SkillBase")
local AbnormalStatus_Hypnosis = Base:Extend("AbnormalStatus_Hypnosis")

function AbnormalStatus_Hypnosis:Ctor(owner)
  Base.Ctor(self, owner)
  self.skillPath = "/Game/ArtRes/Effects/G6Skill/Avatar/Staff/DreamStaff/G6_Scene_DreamStaff_Vertigo01_Loop.G6_Scene_DreamStaff_Vertigo01_Loop"
  self.niagaraComp = nil
  self.fadeStartTime = 0
  self.fadeEndTime = 0
end

function AbnormalStatus_Hypnosis:OnExecute()
  Base.OnExecute(self)
end

function AbnormalStatus_Hypnosis:OnRemove(bForce)
  if not bForce and UE.UObject.IsValid(self.currentSkill) and self:IsLocalPlayer() then
    local actions = self.currentSkill:GetAllActions()
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action and action:IsA(UE4.URocoCameraLensEffectAction) then
        self.niagaraComp = action:GetFXSystemComponent()
        self.fadeStartTime = self.currentSkill:GetCurrentTime()
        self.fadeEndTime = self.currentSkill:GetLength()
        _G.UpdateManager:Register(self)
        break
      end
    end
  end
  Base.OnRemove(self, bForce)
end

function AbnormalStatus_Hypnosis:OnTick(RealTickTime)
  if not UE.UObject.IsValid(self.currentSkill) or not UE.UObject.IsValid(self.niagaraComp) then
    _G.UpdateManager:UnRegister(self)
    return
  end
  local currentTime = self.currentSkill:GetCurrentTime()
  if currentTime < self.fadeStartTime or currentTime > self.fadeEndTime then
    _G.UpdateManager:UnRegister(self)
    return
  end
  local alpha = UE.UKismetMathLibrary.MapRangeClamped(currentTime, self.fadeStartTime, self.fadeEndTime, 1.0, 0.0)
  self.niagaraComp:SetFloatParameter("Alpha", alpha)
end

function AbnormalStatus_Hypnosis:OnSkillEnd(event, skillObj)
  _G.UpdateManager:UnRegister(self)
  self.niagaraComp = nil
  self.fadeStartTime = 0
  self.fadeEndTime = 0
  Base.OnSkillEnd(self, event, skillObj)
end

return AbnormalStatus_Hypnosis
