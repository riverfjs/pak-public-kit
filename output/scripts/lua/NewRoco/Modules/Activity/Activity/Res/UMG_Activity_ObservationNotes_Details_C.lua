local UMG_Activity_ObservationNotes_Details_C = _G.NRCPanelBase:Extend("UMG_Activity_ObservationNotes_Details_C")

function UMG_Activity_ObservationNotes_Details_C:OnActive(storyData)
  _G.NRCAudioManager:PlaySound2DAuto(40008019, "UMG_Activity_ObservationNotes_Details_C:OnActive")
  self.canClose = true
  self.NRCText_Title:SetText(storyData.story_title)
  self.NRCText_Describe:SetText(storyData.story_txt)
  self:OnAddEventListener()
  self:PlayAnimation(self.In_2)
end

function UMG_Activity_ObservationNotes_Details_C:OnDeactive()
  self:RemoveButtonListener(self.CloseBtn.btnClose)
end

function UMG_Activity_ObservationNotes_Details_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnCloseClick)
end

function UMG_Activity_ObservationNotes_Details_C:OnBtnCloseClick()
  if not self.canClose then
    return
  end
  self.canClose = false
  self:PlayAnimation(self.Out)
end

function UMG_Activity_ObservationNotes_Details_C:OnPcClose()
  self:OnBtnCloseClick()
end

function UMG_Activity_ObservationNotes_Details_C:OnAnimationFinished(Animation)
  if Animation == self.Out then
    self.canClose = true
    self:DoClose()
  end
end

return UMG_Activity_ObservationNotes_Details_C
