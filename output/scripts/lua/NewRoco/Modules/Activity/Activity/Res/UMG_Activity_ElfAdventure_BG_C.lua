local UMG_Activity_ElfAdventure_BG_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventure_BG_C")

function UMG_Activity_ElfAdventure_BG_C:OnActive()
end

function UMG_Activity_ElfAdventure_BG_C:PlayInAnimation()
  self:PlayAnimation(self.In)
end

function UMG_Activity_ElfAdventure_BG_C:OnAnimationFinished(anim)
  if anim == self.In then
    self:PlayAnimation(self.loop)
  end
  if anim == self.loop then
    self:PlayAnimation(self.loop)
  end
end

function UMG_Activity_ElfAdventure_BG_C:OnDeactive()
end

function UMG_Activity_ElfAdventure_BG_C:OnAddEventListener()
end

return UMG_Activity_ElfAdventure_BG_C
