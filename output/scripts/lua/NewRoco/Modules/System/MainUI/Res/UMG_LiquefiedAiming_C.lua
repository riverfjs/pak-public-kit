local UMG_LiquefiedAiming_C = _G.NRCPanelBase:Extend("UMG_LiquefiedAiming_C")

function UMG_LiquefiedAiming_C:OnAppear()
  self:StopAllAnim()
  self:PlayAnimation(self.In)
  self:PlayAnimation(self.Loop, 0, 99999)
end

function UMG_LiquefiedAiming_C:OnCancel(bFromInit)
  if bFromInit then
    self:HideAll()
  end
  self:StopAllAnim()
  self:PlayAnimation(self.Out)
end

function UMG_LiquefiedAiming_C:StopAllAnim()
  if self:IsAnyAnimationPlaying() then
    self:StopAllAnimations()
  end
end

function UMG_LiquefiedAiming_C:ClearActorCache()
  self:HideAll()
end

function UMG_LiquefiedAiming_C:OnShow()
  self:HideAll()
end

function UMG_LiquefiedAiming_C:HideAll()
  self.Centre:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LiquefiedAiming_C:OnEnable()
  self.Centre:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_3:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_4:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_LiquefiedAiming_C:OnDisable()
  self.Centre:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_3:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_4:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_LiquefiedAiming_C:OnParentViewLoaded()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_LiquefiedAiming_C
