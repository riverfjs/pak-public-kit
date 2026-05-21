local UMG_Details_C = _G.NRCPanelBase:Extend("UMG_Details_C")

function UMG_Details_C:OnActive()
end

function UMG_Details_C:OnDeactive()
end

function UMG_Details_C:SetPath(_Path, _Path_1, _Path_2)
  self.Ordinary:SetPath(_Path)
  self.Select:SetPath(_Path_1)
  self.ps:SetPath(_Path_2)
end

function UMG_Details_C:SetText(text)
  if self.ItemName then
    self.ItemName:SetText(text)
    self.ItemName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Details_C:ChangeIconSelectState(selectIndex)
  if selectIndex then
    if self.normalBrush and self.selectBrush then
      if 1 == selectIndex then
        self.Ordinary:SetBrush(self.normalBrush)
        self.ps:SetBrush(self.selectBrush)
        self.Select:SetBrush(self.normalBrush)
      elseif 2 == selectIndex then
        self.Ordinary:SetBrush(self.selectBrush)
        self.ps:SetBrush(self.normalBrush)
        self.Select:SetBrush(self.selectBrush)
      end
    end
  else
    self.Ordinary:SetBrush(self.ps.Brush)
    self.ps:SetBrush(self.Select.Brush)
    self.Select:SetBrush(self.Ordinary.Brush)
  end
end

function UMG_Details_C:SwitchState(Index)
  if self.RoundBtnImages == nil then
    return
  end
  if self.RoundBtnImages[Index] == nil then
    return
  end
  self.Ordinary:SetBrush(self.RoundBtnImages[Index])
  self.ps:SetBrush(self.RoundBtnImages[Index])
  self.Select:SetBrush(self.RoundBtnImages[Index])
end

function UMG_Details_C:OnAddEventListener()
end

function UMG_Details_C:OnClickbtnLevelUp()
  self:OnClickbtnPressed()
end

function UMG_Details_C:AddButtonEvent(eventName)
  self.Event = eventName
end

function UMG_Details_C:AddPressedCallback(caller, callback)
  self.Caller = caller
  self.PressCallback = callback
end

function UMG_Details_C:AddReleasedCallback(caller, callback)
  self.Caller = caller
  self.ReleasedCallback = callback
end

function UMG_Details_C:OnConstruct()
  self.Event = nil
  self.Toggle = false
  self.PressCallback = nil
  if self.GetNormalIcon then
    self.normalBrush = self:GetNormalIcon()
  end
  if self.GetSelectIcon then
    self.selectBrush = self:GetSelectIcon()
  end
  self:OnAddEventListener()
end

function UMG_Details_C:OnDestruct()
end

function UMG_Details_C:OnAnimationFinished(anim)
  if anim == self.Up then
    if self.ReleasedCallback and self.Caller then
      self.ReleasedCallback(self.Caller)
    end
  elseif anim == self.Press then
  end
end

function UMG_Details_C:OnClickbtnPressed()
  self.Toggle = not self.Toggle
  if self.Event then
    _G.NRCEventCenter:DispatchEvent(self.Event, self.Toggle)
  end
  if self.Toggle then
    self:PlayAnimation(self.Press)
  else
    self:PlayAnimation(self.Up)
  end
  if self.PressCallback and self.Caller then
    self.PressCallback(self.Caller)
  end
end

function UMG_Details_C:OnClickbtnLevelReleased()
  self.Toggle = false
  self:StopAllAnimations()
  self:PlayAnimation(self.Up)
end

function UMG_Details_C:RevertState()
  self.Toggle = false
  self:StopAllAnimations()
  self:PlayAnimation(self.Up)
end

function UMG_Details_C:TriggerState()
  self.Toggle = true
  self:PlayAnimation(self.Press)
end

function UMG_Details_C:SetRedDot(value)
  if self.RedDot then
    self.RedDot:SetupKey(value)
  else
    self:LogError("cannt find reddot", self, self.RedDot)
  end
end

function UMG_Details_C:SetIgnoreRedPointDataList(reason, extraKeyTable)
  if self.RedDot then
    self.RedDot:SetIgnoreRedPointDataList(reason, extraKeyTable)
  else
    self:LogError("cannt find reddot", self, self.RedDot)
  end
end

function UMG_Details_C:ClearIgnoreRedPointDataList()
  if self.RedDot then
    self.RedDot:ClearIgnoreRedPointDataList()
  else
    self:LogError("cannt find reddot", self, self.RedDot)
  end
end

function UMG_Details_C:ShowOrHidePCKey(visible)
  if self.Text_PCKey then
    self.Text_PCKey:SetKeyVisibility(visible)
  end
end

function UMG_Details_C:IsPCKeyVisible()
  if self.Text_PCKey then
    return self.Text_PCKey:IsVisible()
  end
  return false
end

function UMG_Details_C:SetPCKey(keyUIName)
  if SystemSettingModuleCmd and self.Text_PCKey and keyUIName then
    self.Text_PCKey:SetKeyVisibility(true)
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, keyUIName)
    if "" ~= image then
      self.Text_PCKey:SetImageMode(image)
    else
      self.Text_PCKey:SetText(text)
    end
  end
end

return UMG_Details_C
