local UMG_UpperLimit_C = _G.NRCPanelBase:Extend("UMG_UpperLimit_C")

function UMG_UpperLimit_C:OnActive()
end

function UMG_UpperLimit_C:OnDeactive()
end

function UMG_UpperLimit_C:InitNum(Num, LimitNum, TitleText, ShowIcon, IconPath, ShowText, Separator, bShowQuantityColor)
  local _ShowText = nil == ShowText and not ShowIcon or ShowText
  if Num and LimitNum and LimitNum <= Num and not bShowQuantityColor then
    self.QuantityUsed:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#b13b39FF"))
  else
    self.QuantityUsed:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE0FF"))
  end
  if _ShowText then
    if TitleText then
      self.SumNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SumNum:SetText(TitleText)
    else
      self.SumNum:SetText(LuaText.bag_UpperText)
      if self.SizeBox_0 then
        self.SizeBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.SumNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.SumNum:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if ShowIcon then
    if self.SizeBox_0 then
      self.SizeBox_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if IconPath then
      self.MoneyIcon:SetPath(IconPath)
    end
  elseif self.SizeBox_0 then
    self.SizeBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.QuantityUsed and Num then
    self.QuantityUsed:SetText(Num)
    self.QuantityUsed:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.QuantityUsed:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Quantity and LimitNum then
    if Separator then
      self.Quantity:SetText(string.format("%s%d", Separator, LimitNum))
    else
      self.Quantity:SetText("/" .. LimitNum)
    end
    self.Quantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpperLimit_C:PlayAnimationByName(AnimName, IsReverse)
  if AnimName then
    if IsReverse then
      self:PlayAnimationReverse(self[AnimName])
    else
      self:PlayAnimation(self[AnimName])
    end
  end
end

function UMG_UpperLimit_C:OnAddEventListener()
end

return UMG_UpperLimit_C
