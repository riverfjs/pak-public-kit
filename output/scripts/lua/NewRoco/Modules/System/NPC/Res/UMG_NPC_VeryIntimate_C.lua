local UMG_NPC_VeryIntimate_C = _G.NRCPanelBase:Extend("UMG_NPC_VeryIntimate_C")

function UMG_NPC_VeryIntimate_C:OnConstruct()
end

function UMG_NPC_VeryIntimate_C:OnDestruct()
end

function UMG_NPC_VeryIntimate_C:OnActive(owner)
  self.owner = owner
  self.bIsButtonActive = nil
  local bIsPetBondActive = self.owner and self.owner.bIsPetBondActive or false
  self:RefreshStatus(self.owner.bIsPetBondActive)
end

function UMG_NPC_VeryIntimate_C:RefreshStatus(newStatus)
  if nil == newStatus then
    newStatus = false
  end
  if nil == self.bIsButtonActive then
    self:StopAllAnimations()
    self.bIsButtonActive = newStatus
    if self.bIsButtonActive then
      self:PlayAnimation(self.BrightIn)
    else
      self:PlayAnimation(self.DarkIn)
    end
    return
  end
  if newStatus == self.bIsButtonActive then
    return
  end
  self:StopAllAnimations()
  self.bIsButtonActive = newStatus
  if newStatus then
    self:PlayAnimation(self.Dark2Bright)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_NPC_VeryIntimate_C:Anim.Dark2Bright")
  else
    self:PlayAnimation(self.Bright2Dark)
  end
end

function UMG_NPC_VeryIntimate_C:OnAnimationFinished(Anim)
  self:StopAllAnimations()
  if self.bIsButtonActive then
    self:PlayAnimation(self.BrightLoop, 0, 0)
  else
    self:PlayAnimation(self.DarkLoop, 0, 0)
  end
end

function UMG_NPC_VeryIntimate_C:OnDeactive()
end

function UMG_NPC_VeryIntimate_C:SetPetBondActive(bIsActive)
  self:RefreshStatus(bIsActive)
end

return UMG_NPC_VeryIntimate_C
