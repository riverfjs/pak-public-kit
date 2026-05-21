local AbnormalStatusBase = Class("AbnormalStatusBase")

function AbnormalStatusBase:Ctor(owner)
  self.owner = owner
end

function AbnormalStatusBase:OnExecute()
end

function AbnormalStatusBase:OnRemove(bForce)
end

function AbnormalStatusBase:GetOwner()
  return self.owner
end

function AbnormalStatusBase:GetOwnerView()
  return self.owner and self.owner.viewObj
end

function AbnormalStatusBase:IsLocalPlayer()
  if self.owner then
    return self.owner.isLocal
  end
  return false
end

return AbnormalStatusBase
