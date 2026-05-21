local UMG_ContinuousCapture_Tips_C = _G.NRCPanelBase:Extend("UMG_ContinuousCapture_Tips_C")

function UMG_ContinuousCapture_Tips_C:OnConstruct()
  Log.Debug("UMG_ContinuousCapture_Tips_C:Construct")
  self.CurrentTip = nil
  self.CooldownDelay = nil
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ContinuousCapture_Tips_C:OnDestruct()
  Log.Debug("UMG_ContinuousCapture_Tips_C:Destruct")
  self.CurrentTip = nil
  if self.CooldownDelay then
    _G.DelayManager:CancelDelayById(self.CooldownDelay)
    self.CooldownDelay = nil
  end
end

function UMG_ContinuousCapture_Tips_C:OnActive(arg)
  self.CurrentTip = arg
  self:ConsumeTips(arg)
end

function UMG_ContinuousCapture_Tips_C:SetParent(parent)
  self.ParentPanel = parent
end

function UMG_ContinuousCapture_Tips_C:ConsumeTips(tip)
  if not self:Show(tip) then
    self.ParentPanel:ConsumeNext()
  end
end

function UMG_ContinuousCapture_Tips_C:Show(tip)
  if tip.text then
    self.Text_Tips:SetText(tip.text)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(self.CurrentTip.soundId, "UMG_ContinuousCapture_Tips_C:Show")
    self:PlayAnimation(self.In)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return true
  else
    return false
  end
end

function UMG_ContinuousCapture_Tips_C:OnAnimationFinished(Animation)
  if self.Out == Animation then
    self.CurrentTip = nil
    self:SetRenderOpacity(0)
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ParentPanel:ConsumeNext()
  elseif self.In then
    self:PlayAnimation(self.Loop, 0, 0)
    if self.CooldownDelay then
      _G.DelayManager:CancelDelayById(self.CooldownDelay)
      self.CooldownDelay = nil
    end
    self.CooldownDelay = _G.DelayManager:DelaySeconds(self.CurrentTip.showTime, function()
      self:PlayAnimation(self.Out)
    end)
  end
end

return UMG_ContinuousCapture_Tips_C
