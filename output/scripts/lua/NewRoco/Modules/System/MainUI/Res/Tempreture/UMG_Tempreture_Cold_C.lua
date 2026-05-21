local UMG_Tempreture_Cold_C = _G.NRCPanelBase:Extend("UMG_Tempreture_Cold_C")

function UMG_Tempreture_Cold_C:OnConstruct()
end

function UMG_Tempreture_Cold_C:OnDestruct()
end

function UMG_Tempreture_Cold_C:OnActive()
  self:DoCustomOpen()
end

function UMG_Tempreture_Cold_C:OnDeactive()
end

function UMG_Tempreture_Cold_C:OnEnable()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_Tempreture_Cold_C:OnDisable()
end

function UMG_Tempreture_Cold_C:DoCustomOpen()
  Log.Debug("UMG_Tempreture_Cold_C:DoCustomOpen", self.bDoingClose)
  _G.NRCAudioManager:PlaySound2DAuto(40008010, "UMG_Tempreture_Cold_C:DoCustomOpen")
  self.bDoingClose = false
  self:StopAllAnimations()
  self:PlayAnimation(self.ColdOpen)
  self:PlayAnimation(self.ColdLoop, 0, 0)
  self:OnEnable()
end

function UMG_Tempreture_Cold_C:DoCustomClose(bForce)
  Log.Debug("UMG_Tempreture_Cold_C:DoCustomClose", self.bDoingClose, bForce)
  self.bDoingClose = true
  if bForce then
    self:StopAllAnimations()
    self:DoClose()
    return
  end
  self:StopAllAnimations()
  self:PlayAnimation(self.ColdClose)
end

function UMG_Tempreture_Cold_C:OnAnimationFinished(Animation)
  if Animation == self.ColdClose and self.bDoingClose then
    self.bDoingClose = false
    self:DoClose()
  end
end

return UMG_Tempreture_Cold_C
