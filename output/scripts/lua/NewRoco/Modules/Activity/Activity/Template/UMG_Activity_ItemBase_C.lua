local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ItemBase_C = Base:Extend("UMG_Activity_ItemBase_C")

function UMG_Activity_ItemBase_C:OnConstruct()
end

function UMG_Activity_ItemBase_C:OnDestruct()
  self:TryStopAnimation()
  local delayPlayAnimId = self.delayPlayAnimId
  if delayPlayAnimId then
    _G.DelayManager:CancelDelayById(delayPlayAnimId)
  end
end

function UMG_Activity_ItemBase_C:OnEnter()
end

function UMG_Activity_ItemBase_C:OnLeave()
end

function UMG_Activity_ItemBase_C:OnEnable(firstLoad)
  if not firstLoad then
    self:OnEnter()
  end
end

function UMG_Activity_ItemBase_C:OnDisable()
  self:OnLeave()
end

function UMG_Activity_ItemBase_C:InvokeParentFunc(_funcName, ...)
  if not _funcName then
    return
  end
  local _data = self.itemData
  local parent = _data and _data.parent
  if UE4.UObject.IsValid(parent) and parent[_funcName] then
    return parent[_funcName](parent, self, self.index, _data.customData, ...)
  end
end

function UMG_Activity_ItemBase_C:OnItemUpdate(_data, datalist, index)
  self.itemData = _data
  self.index = index
  self.playingAnim = nil
  self.pendingAnims = {}
  self:OnEnter()
  self:InvokeParentFunc("OnItemUpdate")
end

function UMG_Activity_ItemBase_C:OnItemSelected(_bSelected, _bScroll)
  self:InvokeParentFunc("OnItemSelected", _bSelected, _bScroll)
end

function UMG_Activity_ItemBase_C:OpItem(opType, ...)
  self:InvokeParentFunc("OnItemOp", opType, ...)
end

function UMG_Activity_ItemBase_C:RefreshView()
  self:InvokeParentFunc("OnItemRefreshView")
end

function UMG_Activity_ItemBase_C:SetDebugEnable(tag)
  self.DebugTag = tag
end

function UMG_Activity_ItemBase_C:AddPendingAnimData(animData)
  local pendingAnims = self.pendingAnims
  if not pendingAnims then
    pendingAnims = {}
    self.pendingAnims = pendingAnims
  end
  table.insert(pendingAnims, animData)
  table.sort(pendingAnims, function(a, b)
    return a.priority < b.priority
  end)
end

function UMG_Activity_ItemBase_C:DoPlayAnimation(anim, reverse)
  if self.disableAnim then
    return false
  end
  self.playingAnim = anim
  if reverse then
    self:PlayAnimationReverse(anim)
  else
    self:PlayAnimation(anim)
  end
  if self.DebugTag then
    Log.ErrorFormat("[%s] DoPlayAnimation: %s", self.DebugTag, anim.DisplayLabel)
  end
  return true
end

function UMG_Activity_ItemBase_C:DelayDoPlayAnimation()
  self.delayPlayAnimId = nil
  local delayPlayAnims = self.delayPlayAnims
  if delayPlayAnims then
    for _, _animData in ipairs(delayPlayAnims) do
      if not self:IsAnimationPlaying(_animData.anim) then
        if _animData.priority then
          self:TryPlayAnimation(_animData.anim, _animData.reverse, _animData.priority, _animData.loopsToPlay)
        else
          self:PlayAnimationImmediately(_animData.anim, _animData.reverse)
        end
      end
    end
    self.delayPlayAnims = {}
  end
end

function UMG_Activity_ItemBase_C:PlayAnimationImmediately(anim, reverse)
  if not anim then
    return
  end
  if reverse then
    self:PlayAnimationReverse(anim)
  else
    self:PlayAnimation(anim)
  end
  if self.DebugTag then
    Log.ErrorFormat("[%s] PlayAnimationImmediately: %s", self.DebugTag, anim.DisplayLabel)
  end
end

function UMG_Activity_ItemBase_C:TryPlayAnimation(anim, reverse, priority, loopsToPlay)
  if anim then
    if self.playingAnim then
      if self.playingAnim ~= anim then
        local exists = false
        if self.pendingAnims then
          for _, _animData in ipairs(self.pendingAnims) do
            if _animData.anim == anim then
              exists = true
              break
            end
          end
        end
        if not exists then
          local pendingAnimData = {}
          pendingAnimData.anim = anim
          pendingAnimData.priority = priority or math.maxinteger
          pendingAnimData.reverse = not not reverse
          pendingAnimData.loopsToPlay = loopsToPlay
          self:AddPendingAnimData(pendingAnimData)
        end
      end
    else
      if self.pendingAnims then
        for _index, _animData in ipairs(self.pendingAnims) do
          if _animData.anim == anim then
            table.remove(self.pendingAnims, _index)
            break
          end
        end
      end
      local playSuccess = self:DoPlayAnimation(anim, reverse)
      if not playSuccess or loopsToPlay then
        local pendingAnimData = {}
        pendingAnimData.anim = anim
        pendingAnimData.priority = priority or math.maxinteger
        pendingAnimData.reverse = not not reverse
        pendingAnimData.loopsToPlay = loopsToPlay
        self:AddPendingAnimData(pendingAnimData)
      end
      return playSuccess
    end
  end
end

function UMG_Activity_ItemBase_C:DelayPlayAnimation(anim, reverse, priority, loopsToPlay)
  local delayPlayAnims = self.delayPlayAnims
  if not delayPlayAnims then
    delayPlayAnims = {}
    self.delayPlayAnims = delayPlayAnims
  else
    for _index, _animData in ipairs(delayPlayAnims) do
      if _animData.anim == anim then
        table.remove(delayPlayAnims, _index)
        break
      end
    end
  end
  local pendingAnimData = {}
  pendingAnimData.anim = anim
  pendingAnimData.priority = priority
  pendingAnimData.reverse = not not reverse
  pendingAnimData.loopsToPlay = loopsToPlay
  table.insert(delayPlayAnims, pendingAnimData)
  local delayPlayAnimId = self.delayPlayAnimId
  if not delayPlayAnimId then
    self.delayPlayAnimId = _G.DelayManager:DelayFrames(1, self.DelayDoPlayAnimation, self)
  end
end

function UMG_Activity_ItemBase_C:TryStopAnimation(anim, includePlaying)
  if anim then
    if self.pendingAnims then
      for _index, _animData in ipairs(self.pendingAnims) do
        if _animData.anim == anim then
          table.remove(self.pendingAnims, _index)
          break
        end
      end
    end
    if includePlaying and self.playingAnim == anim then
      self:StopAnimation(anim)
    end
  else
    self.pendingAnims = {}
    self:StopAllAnimations()
  end
end

function UMG_Activity_ItemBase_C:DisableAnimations()
  self.disableAnim = true
  self:StopAllAnimations()
end

function UMG_Activity_ItemBase_C:EnableAnimations(forbidResumePendingAnim)
  local preDisableAnim = self.disableAnim
  self.disableAnim = false
  if preDisableAnim and not forbidResumePendingAnim and self.pendingAnims and #self.pendingAnims > 0 then
    local pendingAnimData = self.pendingAnims[1]
    if pendingAnimData then
      local playSuccess = self:DoPlayAnimation(pendingAnimData.anim, pendingAnimData.reverse)
      if playSuccess then
        table.remove(self.pendingAnims, 1)
      end
    end
  end
end

function UMG_Activity_ItemBase_C:OnAnimationStarted(anim)
end

function UMG_Activity_ItemBase_C:OnAnimationFinished(anim)
  if self.DebugTag then
    Log.ErrorFormat("[%s] OnAnimationFinished: %s", self.DebugTag, anim.DisplayLabel)
  end
  self.playingAnim = nil
  if self.pendingAnims and #self.pendingAnims > 0 then
    local pendingAnimData = self.pendingAnims[1]
    if pendingAnimData then
      local playSuccess = self:DoPlayAnimation(pendingAnimData.anim, pendingAnimData.reverse)
      if playSuccess then
        table.remove(self.pendingAnims, 1)
        if pendingAnimData.loopsToPlay then
          self:AddPendingAnimData(pendingAnimData)
        end
      end
    end
  end
end

return UMG_Activity_ItemBase_C
