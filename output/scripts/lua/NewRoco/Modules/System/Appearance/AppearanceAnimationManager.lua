local AppearanceAnimationManager = {}
AppearanceAnimationManager.__index = AppearanceAnimationManager

function AppearanceAnimationManager.new()
  local instance = setmetatable({}, AppearanceAnimationManager)
  instance.AnimPriority = {}
  instance.animQueue = {}
  instance.AvatarPlayingAnimTable = {}
  instance.AvatarPlayingAnimDelayId = {}
  return instance
end

function AppearanceAnimationManager:CreateAnimPlayParamInstance()
  local paramInstance = {}
  paramInstance.rate = 1.0
  paramInstance.position = 0.0
  paramInstance.blendInTime = 0.25
  paramInstance.blendOutTime = 0.25
  paramInstance.loopCount = 1
  paramInstance.endPosition = 0.0
  return paramInstance
end

function AppearanceAnimationManager:InitPriorityTable(priorityTable)
  if not priorityTable then
    self.AnimPriority = {}
    return
  end
  self.AnimPriority = priorityTable
end

function AppearanceAnimationManager:AddAnim(animName, priority)
  if not self.AnimPriority then
    self.AnimPriority = {}
  end
  self.AnimPriority[animName] = priority
end

function AppearanceAnimationManager:RemoveAnim(animName)
  if not self.AnimPriority then
    return
  end
  self.AnimPriority[animName] = nil
end

function AppearanceAnimationManager:GetAnimPriority(name)
  if not name then
    return 1
  end
  if not self.AnimPriority[name] then
    return 1
  end
  return self.AnimPriority[name]
end

function AppearanceAnimationManager:_PlayHighestPriorityAnim(avatar)
  if not self.animQueue[avatar] or 0 == #self.animQueue[avatar] then
    self.AvatarPlayingAnimTable[avatar] = nil
    return
  end
  table.stableSort(self.animQueue[avatar], function(a, b)
    return a.priority > b.priority
  end)
  local request = table.remove(self.animQueue[avatar], 1)
  local animComp = avatar:GetComponentByClass(UE4.URocoAnimComponent)
  if not animComp then
    Log.Error("AppearanceAnimationManager:_PlayHighestPriorityAnim avatar\230\156\170\230\139\165\230\156\137RocoAnim\231\187\132\228\187\182")
    return
  end
  self.AvatarPlayingAnimTable[avatar] = request.animName
  animComp:StopAllMontage()
  if request.playOnce then
    if nil ~= self.AvatarPlayingAnimDelayId[avatar] then
      _G.DelayManager:CancelDelayById(self.AvatarPlayingAnimDelayId[avatar])
    end
    self.AvatarPlayingAnimDelayId[avatar] = nil
    if request.playParam then
      animComp:PlayAnimByName(request.animName, request.playParam.rate, request.playParam.position, request.playParam.blendInTime, request.playParam.blendOutTime, request.playParam.loopCount, request.playParam.endPosition)
    else
      animComp:PlayAnimByName(request.animName)
    end
  else
    if nil ~= self.AvatarPlayingAnimDelayId[avatar] then
      _G.DelayManager:CancelDelayById(self.AvatarPlayingAnimDelayId[avatar])
    end
    local lastTime = animComp:GetAnimLengthByName(request.animName)
    if lastTime and lastTime > 0 then
      self.AvatarPlayingAnimDelayId[avatar] = _G.DelayManager:DelaySeconds(lastTime, function()
        self.AvatarPlayingAnimTable[avatar] = request.loopAnimName
        self.AvatarPlayingAnimDelayId[avatar] = nil
      end)
    else
      self.AvatarPlayingAnimTable[avatar] = request.loopAnimName
    end
    if request.playParam then
      animComp:PlayBeginLoopAnimByName(request.animName, request.loopAnimName, request.playParam.rate, request.playParam.blendInTime)
    else
      animComp:PlayBeginLoopAnimByName(request.animName, request.loopAnimName)
    end
  end
end

function AppearanceAnimationManager:TryPlayAnimByName(avatar, animName, interrupt)
  if not avatar then
    Log.Error("TryPlayAnimByName avatar\228\184\186\231\169\186")
    return
  end
  local animComp = avatar:GetComponentByClass(UE4.URocoAnimComponent)
  if not animComp then
    Log.Error("TryPlayAnimByName avatar\230\156\170\230\139\165\230\156\137RocoAnim\231\187\132\228\187\182")
    return
  end
  local priority = self:GetAnimPriority(animName)
  local newRequest = {
    animName = animName,
    priority = priority,
    playOnce = true
  }
  if interrupt then
    self.animQueue[avatar] = {newRequest}
    self:_PlayHighestPriorityAnim(avatar)
  else
    if self.animQueue[avatar] == nil then
      self.animQueue[avatar] = {}
    end
    if not self.AvatarPlayingAnimTable[avatar] then
      self.animQueue[avatar] = {newRequest}
      self:_PlayHighestPriorityAnim(avatar)
    else
      local currentPriority = self:GetAnimPriority(self.AvatarPlayingAnimTable[avatar])
      if currentPriority <= newRequest.priority then
        self.animQueue[avatar] = {newRequest}
        self:_PlayHighestPriorityAnim(avatar)
      end
    end
  end
end

function AppearanceAnimationManager:TryPlayAnimByNameWithParam(avatar, animName, interrupt, param)
  if not avatar then
    Log.Error("TryPlayAnimByNameWithParam avatar\228\184\186\231\169\186")
    return
  end
  local animComp = avatar:GetComponentByClass(UE4.URocoAnimComponent)
  if not animComp then
    Log.Error("TryPlayAnimByNameWithParam avatar\230\156\170\230\139\165\230\156\137RocoAnim\231\187\132\228\187\182")
    return
  end
  local priority = self:GetAnimPriority(animName)
  local newRequest = {
    animName = animName,
    priority = priority,
    playOnce = true,
    playParam = param
  }
  if interrupt then
    self.animQueue[avatar] = {newRequest}
    self:_PlayHighestPriorityAnim(avatar)
  else
    if self.animQueue[avatar] == nil then
      self.animQueue[avatar] = {}
    end
    if not self.AvatarPlayingAnimTable[avatar] then
      self.animQueue[avatar] = {newRequest}
      self:_PlayHighestPriorityAnim(avatar)
    else
      local currentPriority = self:GetAnimPriority(self.AvatarPlayingAnimTable[avatar])
      if currentPriority <= newRequest.priority then
        self.animQueue[avatar] = {newRequest}
        self:_PlayHighestPriorityAnim(avatar)
      end
    end
  end
end

function AppearanceAnimationManager:TryPlayBeginLoopAnimByName(avatar, startAnimName, loopAnimName, interrupt)
  if not avatar then
    Log.Error("TryPlayBeginLoopAnimByName avatar\228\184\186\231\169\186")
    return
  end
  local animComp = avatar:GetComponentByClass(UE4.URocoAnimComponent)
  if not animComp then
    Log.Error("TryPlayBeginLoopAnimByName avatar\230\156\170\230\139\165\230\156\137RocoAnim\231\187\132\228\187\182")
    return
  end
  local priority = self:GetAnimPriority(startAnimName)
  local newRequest = {
    animName = startAnimName,
    loopAnimName = loopAnimName,
    priority = priority,
    playOnce = false
  }
  if interrupt then
    self.animQueue[avatar] = {newRequest}
    self:_PlayHighestPriorityAnim(avatar)
  else
    if self.animQueue[avatar] == nil then
      self.animQueue[avatar] = {}
    end
    if not self.AvatarPlayingAnimTable[avatar] then
      self.animQueue[avatar] = {newRequest}
      self:_PlayHighestPriorityAnim(avatar)
    else
      local currentPriority = self:GetAnimPriority(self.AvatarPlayingAnimTable[avatar])
      if currentPriority <= newRequest.priority then
        self.animQueue[avatar] = {newRequest}
        self:_PlayHighestPriorityAnim(avatar)
      end
    end
  end
end

function AppearanceAnimationManager:TryPlayBeginLoopAnimByNameWithParam(avatar, startAnimName, loopAnimName, interrupt, animParam)
  if not avatar or not UE4.UObject.IsValid(avatar) then
    Log.Error("TryPlayBeginLoopAnimByNameWithParam avatar\228\184\186\231\169\186")
    return
  end
  local animComp = avatar:GetComponentByClass(UE4.URocoAnimComponent)
  if not animComp then
    Log.Error("TryPlayBeginLoopAnimByNameWithParam avatar\230\156\170\230\139\165\230\156\137RocoAnim\231\187\132\228\187\182")
    return
  end
  local priority = self:GetAnimPriority(startAnimName)
  local newRequest = {
    animName = startAnimName,
    loopAnimName = loopAnimName,
    priority = priority,
    playOnce = false,
    playParam = animParam
  }
  if interrupt then
    self.animQueue[avatar] = {newRequest}
    self:_PlayHighestPriorityAnim(avatar)
  else
    if self.animQueue[avatar] == nil then
      self.animQueue[avatar] = {}
    end
    if not self.AvatarPlayingAnimTable[avatar] then
      self.animQueue[avatar] = {newRequest}
      self:_PlayHighestPriorityAnim(avatar)
    else
      local currentPriority = self:GetAnimPriority(self.AvatarPlayingAnimTable[avatar])
      if currentPriority <= newRequest.priority then
        self.animQueue[avatar] = {newRequest}
        self:_PlayHighestPriorityAnim(avatar)
      end
    end
  end
end

return AppearanceAnimationManager
