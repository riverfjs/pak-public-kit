local UMG_ScrapbookNameTag_C = _G.NRCPanelBase:Extend("UMG_ScrapbookNameTag_C")

function UMG_ScrapbookNameTag_C:OnConstruct()
  self.index = 0
  self.limit = 0
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:OnAddEventListener()
end

function UMG_ScrapbookNameTag_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_ScrapbookNameTag_C:OnActive()
end

function UMG_ScrapbookNameTag_C:OnDeactive()
end

function UMG_ScrapbookNameTag_C:OnAddEventListener()
  self:AddButtonListener(self.NRCButton_29, self.OnTagClicked)
end

function UMG_ScrapbookNameTag_C:PlayInDelayAnimation(bIsNew)
  if bIsNew then
    self.DelayId = _G.DelayManager:DelaySeconds(0.2, function()
      self:PlayAnimation(self.New_in)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end)
  else
    self.DelayId = _G.DelayManager:DelaySeconds(0.2, function()
      self:PlayAnimation(self.In)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end)
  end
end

function UMG_ScrapbookNameTag_C:PlayInAnimation()
  self:PlayAnimation(self.In)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_ScrapbookNameTag_C:PlayNewInAnimation()
  self:PlayAnimation(self.New_in)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_ScrapbookNameTag_C:OnTagClicked()
  if self:IsAnimationPlaying(self.Press_shine) then
    return
  end
  self:PlayAnimation(self.Press_shine)
end

function UMG_ScrapbookNameTag_C:OnAnimationFinished(Anim)
  if Anim == self.In and not self.index then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.ShowMapHeadNewInAnim)
  elseif Anim == self.New_in and not self.index then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.ShowMapHeadNewInAnim)
  end
end

return UMG_ScrapbookNameTag_C
