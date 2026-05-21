local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_Battle_DifferentColors_C = _G.NRCPanelBase:Extend("UMG_Battle_DifferentColors_C")

function UMG_Battle_DifferentColors_C:OnConstruct()
  self:TryInitStateManager()
end

function UMG_Battle_DifferentColors_C:OnDestruct()
  if self.stateManager then
    self.stateManager:DeInit()
  end
end

function UMG_Battle_DifferentColors_C:TryInitStateManager()
  if self.isInitStateManager then
    return
  end
  local initState = {}
  local stateManager = WidgetStateManager()
  stateManager:Init({
    owner = self,
    initState = initState,
    UpdateDerivedState = self.UpdateDerivedState,
    RenderWidget = self.RenderWidget,
    OnWidgetDidUpdate = self.OnWidgetDidUpdate
  })
  self.stateManager = stateManager
  self.isInitStateManager = true
end

function UMG_Battle_DifferentColors_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevIsShow = prevProps and prevProps.isShow or false
  local currIsShow = currProps and currProps.isShow or false
  local prevIsResonanceInAnimPlaying = prevState and prevState.isResonanceInAnimPlaying
  local currIsResonanceInAnimPlaying = currState and currState.isResonanceInAnimPlaying
  local prevIsResonanceOutAnimPlaying = prevState and prevState.isResonanceOutAnimPlaying
  local currIsResonanceOutAnimPlaying = currState and currState.isResonanceOutAnimPlaying
  if prevIsShow ~= currIsShow or prevIsResonanceInAnimPlaying ~= currIsResonanceInAnimPlaying or prevIsResonanceOutAnimPlaying ~= currIsResonanceOutAnimPlaying then
    UMG_Battle_DifferentColors_C.DeriveShowDisplay(currIsShow, currIsResonanceInAnimPlaying, currIsResonanceOutAnimPlaying, derivedState)
  end
end

function UMG_Battle_DifferentColors_C.DeriveShowDisplay(isShow, isResonanceInAnimPlaying, isResonanceOutAnimPlaying, derivedState)
  local isShowDisplay = false
  if isShow or isResonanceInAnimPlaying or isResonanceOutAnimPlaying then
    isShowDisplay = true
  end
  derivedState.isShowDisplay = isShowDisplay
end

function UMG_Battle_DifferentColors_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsShowDisplay = prevState and prevState.isShowDisplay or false
  local currIsShowDisplay = currState and currState.isShowDisplay or false
  if prevKey ~= currKey or prevIsShowDisplay ~= currIsShowDisplay then
    self:RenderShowDisplay(currIsShowDisplay)
  end
end

function UMG_Battle_DifferentColors_C:RenderShowDisplay(isShowDisplay)
  local visibility = UE.ESlateVisibility.Collapsed
  if isShowDisplay then
    visibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self:SetVisibility(visibility)
end

function UMG_Battle_DifferentColors_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevIsShow = prevProps and prevProps.isShow or false
  local currIsShow = currProps and currProps.isShow or false
  if prevIsShow ~= currIsShow then
    self:PlayOpenAnim(currIsShow)
  end
end

function UMG_Battle_DifferentColors_C:GetProps()
  local stateManager = self:GetStateManager()
  if stateManager then
    return self.stateManager:GetProps()
  end
end

function UMG_Battle_DifferentColors_C:SetProps(nextProps)
  local stateManager = self:GetStateManager()
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_Battle_DifferentColors_C:GetState()
  local stateManager = self:GetStateManager()
  if stateManager then
    stateManager:GetState()
  end
end

function UMG_Battle_DifferentColors_C:GetCurrAndNextState()
  local stateManager = self:GetStateManager()
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
end

function UMG_Battle_DifferentColors_C:SetState(nextState)
  local stateManager = self:GetStateManager()
  if stateManager then
    stateManager:SetState(nextState)
  end
end

function UMG_Battle_DifferentColors_C:GetStateManager()
  local stateManager = self.stateManager
  if nil == stateManager then
    self:TryInitStateManager()
    stateManager = self.stateManager
  end
  return stateManager
end

function UMG_Battle_DifferentColors_C:OnActive()
end

function UMG_Battle_DifferentColors_C:OnDeactive()
end

function UMG_Battle_DifferentColors_C:OnAddEventListener()
end

function UMG_Battle_DifferentColors_C:PlayOpenAnim(isShow)
  if self:IsAnimationPlaying(self.Resonance_In) then
    self:StopAnimation(self.Resonance_In)
  end
  if self:IsAnimationPlaying(self.Resonance_Out) then
    self:StopAnimation(self.Resonance_Out)
  end
  if isShow then
    self:PlayAnimation(self.Resonance_In)
  else
    self:PlayAnimation(self.Resonance_Out)
  end
end

function UMG_Battle_DifferentColors_C:OnAnimationStarted(Animation)
  if Animation == self.Resonance_In then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isResonanceInAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.Resonance_Out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isResonanceOutAnimPlaying = true
    self:SetState(nextState)
  end
end

function UMG_Battle_DifferentColors_C:OnAnimationFinished(Animation)
  if Animation == self.Resonance_In then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isResonanceInAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.Resonance_Out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isResonanceOutAnimPlaying = false
    self:SetState(nextState)
  end
end

return UMG_Battle_DifferentColors_C
