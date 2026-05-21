local UMG_DreamStaff_C = _G.NRCPanelBase:Extend("UMG_DreamStaff_C")
local MagicStateEnum = {
  LockNone = 1,
  LockPet = 2,
  LockPlayer = 3
}

function UMG_DreamStaff_C:OnConstruct()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CurState = MagicStateEnum.LockNone
  self.CurNormalAnim = nil
  self.CurSpecialAnim = nil
end

function UMG_DreamStaff_C:OnDestruct()
end

function UMG_DreamStaff_C:PlayNormalAnimationHelper(anim, isLoop)
  self.CurNormalAnim = anim
  self:StopNormalAnim()
  if isLoop then
    self:PlayAnimation(anim, 0.0, 0)
  else
    self:PlayAnimation(anim)
  end
end

function UMG_DreamStaff_C:PlaySpecialAnimationHelper(anim, isLoop)
  self.CurSpecialAnim = anim
  self:StopSpecialAnim()
  if isLoop then
    self:PlayAnimation(anim, 0.0, 0)
  else
    self:PlayAnimation(anim)
  end
end

function UMG_DreamStaff_C:OnShow()
  self.CurNormalAnim = nil
  self.CurSpecialAnim = nil
  self:StopAllAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if nil == self.isLockingState or self.isLockingState == false then
    self:PlayNormalAnimationHelper(self.open)
    self:ShowInitState()
  else
    self:OnEnterLockingState(true)
  end
end

function UMG_DreamStaff_C:OnEnterLockingState(bool, data)
  if bool then
    self:PlayNormalAnimationHelper(self.change1)
  else
    self:PlayNormalAnimationHelper(self.change2)
  end
  self:CheckShowIcon(bool, data)
end

function UMG_DreamStaff_C:OnCancel(cancelType)
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:StopAllAnim()
  self:PlayNormalAnimationHelper(self.close)
end

function UMG_DreamStaff_C:StopAllAnim()
  if self:IsAnyAnimationPlaying() then
    self:StopAllAnimations()
  end
end

function UMG_DreamStaff_C:ClearActorCache()
  self.lastActor = nil
  self.isLockingState = false
end

function UMG_DreamStaff_C:OnAnimationFinished(anim)
  if anim == self.CurNormalAnim then
    if anim == self.close then
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif anim == self.open or anim == self.change2 then
      self:PlayNormalAnimationHelper(self.normal, true)
    elseif anim == self.change1 then
      self:PlayNormalAnimationHelper(self.select, true)
    end
  end
  if anim == self.CurSpecialAnim then
    if anim == self.Change_To_Hypnosis then
      self:PlaySpecialAnimationHelper(self.Hypnosis_Loop, true)
    elseif anim == self.Change_To_Normal then
      self:PlaySpecialAnimationHelper(self.Normal_Loop, true)
    end
  end
end

function UMG_DreamStaff_C:ShowInitState()
  self:CheckShowIcon()
end

function UMG_DreamStaff_C:CheckShowIcon(isLock, data)
  local isActive = self:UpdateLockState(data)
  if isActive then
    if self.CurState == MagicStateEnum.LockPet then
      self.Normal_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Hypnosis_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlaySpecialAnimationHelper(self.Change_To_Hypnosis)
      self.CurState = MagicStateEnum.LockPlayer
    elseif self.CurState == MagicStateEnum.LockNone then
      self.Normal_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Hypnosis_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlaySpecialAnimationHelper(self.Hypnosis_Loop, true)
      self.CurState = MagicStateEnum.LockPlayer
    end
  elseif isLock then
    if self.CurState == MagicStateEnum.LockPlayer then
      self.Normal_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Hypnosis_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlaySpecialAnimationHelper(self.Change_To_Normal)
      self.CurState = MagicStateEnum.LockPet
    elseif self.CurState == MagicStateEnum.LockNone then
      self.Normal_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Hypnosis_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlaySpecialAnimationHelper(self.Normal_Loop, true)
      self.CurState = MagicStateEnum.LockPet
    end
  else
    self:StopSpecialAnim()
    self.Normal_Image:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Hypnosis_Image:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CurState = MagicStateEnum.LockNone
  end
end

function UMG_DreamStaff_C:ResetState()
  self:CheckShowIcon()
  if self:IsAnimationPlaying(self.change1) then
    self:StopAnimation(self.change1)
    self:PlayNormalAnimationHelper(self.change2)
  elseif self:IsAnimationPlaying(self.select) then
    self:StopAnimation(self.select)
    self:PlayNormalAnimationHelper(self.change2)
  end
end

function UMG_DreamStaff_C:StopNormalAnim()
  if self:IsAnimationPlaying(self.open) then
    self:StopAnimation(self.open)
  end
  if self:IsAnimationPlaying(self.normal) then
    self:StopAnimation(self.normal)
  end
  if self:IsAnimationPlaying(self.change1) then
    self:StopAnimation(self.change1)
  end
  if self:IsAnimationPlaying(self.select) then
    self:StopAnimation(self.select)
  end
  if self:IsAnimationPlaying(self.change2) then
    self:StopAnimation(self.change2)
  end
end

function UMG_DreamStaff_C:StopSpecialAnim()
  if self:IsAnimationPlaying(self.Normal_Loop) then
    self:StopAnimation(self.Normal_Loop)
  end
  if self:IsAnimationPlaying(self.Change_To_Hypnosis) then
    self:StopAnimation(self.Change_To_Hypnosis)
  end
  if self:IsAnimationPlaying(self.Hypnosis_Loop) then
    self:StopAnimation(self.Hypnosis_Loop)
  end
  if self:IsAnimationPlaying(self.Change_To_Normal) then
    self:StopAnimation(self.Change_To_Normal)
  end
end

function UMG_DreamStaff_C:UpdateLockState(data)
  local isActive = false
  self.Centre:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Centre_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if data then
    local AbnormalStatusComponent = data.AbnormalStatusComponent
    if AbnormalStatusComponent then
      isActive = true
      local CanAdd = AbnormalStatusComponent:CanAddStatus(1)
      if not CanAdd then
        self.Centre_1:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Centre:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  return isActive
end

return UMG_DreamStaff_C
