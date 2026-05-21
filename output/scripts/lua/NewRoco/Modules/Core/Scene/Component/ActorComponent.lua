local Class = _G.MakeSimpleClass
local ActorComponent = Class("ActorComponent", nil, 128)
ActorComponent:SetMemberCount(2)

function ActorComponent:PreCtor()
  self.enabled = false
  self.owner = nil
end

function ActorComponent:Ctor()
end

function ActorComponent:Attach(owner)
  self.owner = owner
  self:SetEnable(true)
end

function ActorComponent:UpdateData(ServerData, isReconnect)
end

function ActorComponent:OnSetViewObj()
end

function ActorComponent:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
end

function ActorComponent:DeAttach()
end

function ActorComponent:Destroy()
end

function ActorComponent:Update(deltaTime)
end

function ActorComponent:UpdateByDistance(deltaTime)
end

function ActorComponent:FixedUpdate()
end

function ActorComponent:SetEnable(Value)
  if self.enabled ~= Value then
    self.enabled = Value
    if Value then
      self:OnEnable()
    else
      self:OnDisable()
    end
  end
end

function ActorComponent:OnEnable()
end

function ActorComponent:OnDisable()
end

function ActorComponent:OnVisible()
end

function ActorComponent:OnInvisible()
end

function ActorComponent:OnReConnect()
end

function ActorComponent:OnDisConnect()
end

function ActorComponent:OnPause(pause)
end

function ActorComponent:OnResourceLoaded()
end

function ActorComponent:PreResourceUnload()
end

function ActorComponent:Start()
  if self.object then
    self:Attach(self.object)
  end
end

function ActorComponent:GetOwner()
  return self.object or self.owner
end

function ActorComponent:GetOwnerView()
  if self.object then
    return self.object.model
  elseif self.owner then
    return self.owner.viewObj
  else
    return nil
  end
end

function ActorComponent:Enable()
end

function ActorComponent:Disable()
end

function ActorComponent:InitByCard(Card)
end

function ActorComponent:UpdateByCard(Card)
end

function ActorComponent:Log(...)
end

return ActorComponent
