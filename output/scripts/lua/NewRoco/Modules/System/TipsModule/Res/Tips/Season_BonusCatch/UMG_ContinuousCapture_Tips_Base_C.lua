local UMG_ContinuousCapture_Tips_Base_C = _G.NRCPanelBase:Extend("UMG_ContinuousCapture_Tips_Base_C")

function UMG_ContinuousCapture_Tips_Base_C:OnConstruct()
  Log.Debug("UMG_ContinuousCapture_Tips_Base_C:Construct")
  self.CurrentTip = nil
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ContinuousCapture_Tips_Base_C:OnDestruct()
  Log.Debug("UMG_ContinuousCapture_Tips_C:Destruct")
end

function UMG_ContinuousCapture_Tips_Base_C:OnActive(arg)
  self.CurrentTip = arg
  self:ConsumeTips(arg)
end

function UMG_ContinuousCapture_Tips_Base_C:SetParent(parent)
  self.ParentPanel = parent
end

function UMG_ContinuousCapture_Tips_Base_C:ConsumeTips(tip)
  if not self:Show(tip) then
    self.ParentPanel:ConsumeNext()
  end
end

function UMG_ContinuousCapture_Tips_Base_C:Show(tip)
  if self:ShouldShowTip(tip) then
    self:SetTipsContent(tip)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return true
  else
    return false
  end
end

function UMG_ContinuousCapture_Tips_Base_C:OnTipsEnd()
  self.CurrentTip = nil
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ParentPanel:ConsumeNext()
end

function UMG_ContinuousCapture_Tips_Base_C:ShouldShowTip(tip)
  if not tip then
    return false
  end
  return tip.text
end

function UMG_ContinuousCapture_Tips_Base_C:SetTipsContent(tip)
end

return UMG_ContinuousCapture_Tips_Base_C
