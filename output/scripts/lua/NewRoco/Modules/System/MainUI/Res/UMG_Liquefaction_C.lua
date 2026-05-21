local UMG_LiqueFaction_C = _G.NRCPanelBase:Extend("UMG_LiqueFaction_C")

function UMG_LiqueFaction_C:OnActive()
end

function UMG_LiqueFaction_C:OnDeactive()
end

function UMG_LiqueFaction_C:OnAddEventListener()
end

function UMG_LiqueFaction_C:OnAppear()
  self:StopAllAnim()
  self:PlayAnimation(self.In)
end

function UMG_LiqueFaction_C:OnCancel(bFromInit)
  if bFromInit then
    self:HideAll()
  end
  self:StopAllAnim()
  self:PlayAnimation(self.Out)
end

function UMG_LiqueFaction_C:StopAllAnim()
  if self:IsAnyAnimationPlaying() then
    self:StopAllAnimations()
  end
end

function UMG_LiqueFaction_C:ClearActorCache()
  self:HideAll()
end

function UMG_LiqueFaction_C:OnShow()
  self:HideAll()
end

function UMG_LiqueFaction_C:HideAll()
  self.Centre:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LiqueFaction_C:OnEnable()
  self.Centre:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_LiqueFaction_C:OnDisable()
  self.Centre_Forbidden:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Centre:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OuterRing:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.OuterRing_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

return UMG_LiqueFaction_C
