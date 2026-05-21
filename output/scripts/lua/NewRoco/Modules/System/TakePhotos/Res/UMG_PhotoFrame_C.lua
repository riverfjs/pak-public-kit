local UMG_PhotoFrame_C = _G.NRCPanelBase:Extend("UMG_PhotoFrame_C")

function UMG_PhotoFrame_C:OnConstruct()
  self.bThisTickEnabled = false
end

function UMG_PhotoFrame_C:OnActive(Command, OnFinish, LockCondition)
  Log.Debug("UMG_PhotoFrame_C OnActive")
  self:StopAllAnimations()
  self:SetThisTickEnabled(false)
  self.OnFinishDelegate = OnFinish
  self.LockConditionDelegate = LockCondition
  if "Enter" == Command then
    self._OnBeginAnim = self.In
    self._OnFinishAnim = self.Out
  elseif "Switch" == Command then
    self._OnBeginAnim = self.In_2
    self._OnFinishAnim = self.Out_2
  elseif "World" == Command then
    self._OnBeginAnim = self.In_3
    self._OnFinishAnim = self.Out_3
  else
    self:DoClose()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "UMG_PhotoFrame_C")
  self:SafePlayAnimation(self._OnBeginAnim)
  self.LockConditionTimeout = 5
  self.ElapsedConditionSeconds = 0
end

function UMG_PhotoFrame_C:SafePlayAnimation(Animation)
  if self.TimeoutOfAnimation then
    self:CancelDelayByID(self.TimeoutOfAnimation)
    self.TimeoutOfAnimation = nil
  end
  self:StopAnimation(Animation)
  local AnimationLen = Animation:GetEndTime() - Animation:GetStartTime()
  self.TimeoutOfAnimation = self:DelaySeconds(AnimationLen, self.OnTimeoutAnimation, self)
  self.PlayAnimationInfo = {Animation = Animation, Length = AnimationLen}
  self:Log("SafePlayAnimation", Animation, AnimationLen)
  self:PlayAnimation(Animation)
end

function UMG_PhotoFrame_C:OnTimeoutAnimation()
  self:Log("OnTimeoutAnimation", self.PlayAnimationInfo and self.PlayAnimationInfo.Animation)
  local PlayAnimationInfo = self.PlayAnimationInfo
  self.TimeoutOfAnimation = nil
  if PlayAnimationInfo then
    self:OnAnimationFinished(PlayAnimationInfo.Animation)
  end
end

function UMG_PhotoFrame_C:OnDeactive()
  self:SetThisTickEnabled(false)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "UMG_PhotoFrame_C")
end

function UMG_PhotoFrame_C:OnTick(Dt)
  if not self.bThisTickEnabled then
    return
  end
  self.ElapsedConditionSeconds = self.ElapsedConditionSeconds + Dt
  if self.LockConditionDelegate then
    if self.LockConditionDelegate() or self.ElapsedConditionSeconds > self.LockConditionTimeout then
      self:SafePlayAnimation(self._OnFinishAnim)
      self:SetThisTickEnabled(false)
    end
  else
    self:SetThisTickEnabled(false)
    self:SafePlayAnimation(self._OnFinishAnim)
  end
end

function UMG_PhotoFrame_C:SetThisTickEnabled(bEnable)
  if self.bThisTickEnabled ~= bEnable then
    self.bThisTickEnabled = bEnable
    if bEnable then
      UpdateManager:Register(self)
    else
      UpdateManager:UnRegister(self)
    end
  end
end

function UMG_PhotoFrame_C:OnAnimationFinished(Anim)
  self:Log("UMG_PhotoFrame_C OnAnimationFinished", Anim)
  if not self.PlayAnimationInfo then
    self:Log("Cannot found animation info", Anim)
    return
  end
  if self.PlayAnimationInfo.Animation ~= Anim then
    self:LogError("Invalid", Anim, self.PlayAnimationInfo.Animation)
    return
  end
  self.PlayAnimationInfo = nil
  if Anim == self._OnBeginAnim then
    if self.OnFinishDelegate then
      self.OnFinishDelegate()
    end
    if self.enableView then
      self:SetThisTickEnabled(true)
    end
  elseif Anim == self._OnFinishAnim and self.module then
    self:DoClose()
  end
end

function UMG_PhotoFrame_C:OnAddEventListener()
end

function UMG_PhotoFrame_C:OnDestruct()
  _G.DelayManager:DelayFrames(3, function()
    _G.NRCModuleManager:GetModule("MainUIModule"):GetPanel("LobbyMain").VisibleContents:SetVisibility(UE.ESlateVisibility.Collapsed)
    _G.NRCModuleManager:GetModule("MainUIModule"):GetPanel("LobbyMain").VisibleContents:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end)
end

return UMG_PhotoFrame_C
