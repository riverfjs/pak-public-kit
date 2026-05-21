local UMG_Activity_ElfAdventure_BG2_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventure_BG2_C")

function UMG_Activity_ElfAdventure_BG2_C:OnActive()
  _G.NRCAudioManager:PlaySound2DAuto(40010021, "UMG_Activity_ElfAdventure_BG2_C:OnActive")
  self:PlayAnimation(self.In)
  self:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Activity_ElfAdventure_BG2_C:OnDeactive()
end

function UMG_Activity_ElfAdventure_BG2_C:OnAnimationFinished(anim)
  if anim == self.In then
    self:DelaySeconds(1, function()
      _G.NRCAudioManager:PlaySound2DAuto(40010022, "UMG_Activity_ElfAdventure_BG2_C:OnAnimationFinished")
      self:PlayAnimation(self.Out)
    end)
  end
  if anim == self.Out then
    self:DoClose()
  end
end

function UMG_Activity_ElfAdventure_BG2_C:OnAnimationStarted(anim)
  if anim == self.Out then
    self.module:OnElfAdventureBgAnimClose()
  end
end

function UMG_Activity_ElfAdventure_BG2_C:OnAddEventListener()
end

return UMG_Activity_ElfAdventure_BG2_C
