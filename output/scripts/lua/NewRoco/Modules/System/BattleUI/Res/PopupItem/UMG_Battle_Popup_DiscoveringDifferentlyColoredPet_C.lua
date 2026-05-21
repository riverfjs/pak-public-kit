local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C = _G.NRCPanelBase:Extend("UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C")
local WidgetShowType = {
  Hide = 0,
  Entering = 1,
  Show = 2,
  Exiting = 3
}

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnConstruct()
  self:SetRenderOpacity(0)
  local initState = {}
  initState.showType = WidgetShowType.Hide
  local stringConf = _G.DataConfigManager:GetLocalizationConf("rare_pet_discovered", true)
  local stringConfMsg = stringConf and stringConf.msg or ""
  initState.popInfoText = stringConfMsg
  self.stateManager = WidgetStateManager()
  self.stateManager:Init({
    owner = self,
    initState = initState,
    UpdateDerivedState = self.UpdateDerivedState,
    RenderWidget = self.RenderWidget,
    OnWidgetDidUpdate = self.OnWidgetDidUpdate
  })
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnDestruct()
  if self.stateManager then
    self.stateManager:DeInit()
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevShowType = prevState and prevState.showType
  local currShowType = currState and currState.showType
  if prevShowType ~= currShowType then
    UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C.DeriveShowDisplay(currShowType, derivedState)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C.DeriveShowDisplay(showType, derivedState)
  local isShowDisplay = false
  if showType and showType ~= WidgetShowType.Hide then
    isShowDisplay = true
  end
  derivedState.isShowDisplay = isShowDisplay
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevPopInfoText = prevState and prevState.popInfoText
  local currPopInfoText = currState and currState.popInfoText
  local prevIsShowDisplay = prevState and prevState.isShowDisplay or false
  local currIsShowDisplay = currState and currState.isShowDisplay or false
  if prevPopInfoText ~= currPopInfoText then
    local popInfoText = currPopInfoText or ""
    self.PopInfo:SetText(popInfoText)
  end
  if prevIsShowDisplay ~= currIsShowDisplay or prevKey ~= currKey then
    self:RenderVisibility(currIsShowDisplay)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:RenderVisibility(isShowDisplay)
  local visibility = UE.ESlateVisibility.Collapsed
  local renderOpacity = 0
  if isShowDisplay then
    renderOpacity = 1
    visibility = UE.ESlateVisibility.Visible
  end
  self:SetVisibility(visibility)
  self:SetRenderOpacity(renderOpacity)
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsShow = prevProps and prevProps.isShow or false
  local currIsShow = currProps and currProps.isShow or false
  local prevIsShowDisplay = prevState and prevState.isShowDisplay or false
  local currIsShowDisplay = currState and currState.isShowDisplay or false
  local prevShowType = prevState and prevState.showType
  local currShowType = currState and currState.showType
  local prevIsFadeInAnimPlaying = prevState and prevState.isFadeInAnimPlaying or false
  local currIsFadeInAnimPlaying = currState and currState.isFadeInAnimPlaying or false
  local prevIsFadeOutAnimPlaying = prevState and prevState.isFadeOutAnimPlaying or false
  local currIsFadeOutAnimPlaying = currState and currState.isFadeOutAnimPlaying or false
  if prevIsShow ~= currIsShow then
    if currIsShow and currShowType == WidgetShowType.Hide then
      self:PlayAnimation(self.FadeIn)
    elseif not currIsShow and currShowType == WidgetShowType.Show then
      self:PlayAnimation(self.FadeOut)
    end
  end
  if prevIsShow ~= currIsShow or prevIsFadeInAnimPlaying ~= currIsFadeInAnimPlaying or prevIsFadeOutAnimPlaying ~= currIsFadeOutAnimPlaying or prevShowType ~= currShowType then
    self:UpdateInfoShowType()
  end
  if prevIsShowDisplay ~= currIsShowDisplay or prevKey ~= currKey then
    local state = self:GetState()
    local isShowDisplay = state and state.isShowDisplay or false
    local OnIsShowDisplayChanged = currProps and currProps.OnIsShowDisplayChanged
    if OnIsShowDisplayChanged then
      tcall(nil, OnIsShowDisplayChanged, isShowDisplay)
    end
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:UpdateInfoShowType()
  local state = self:GetState()
  local props = self:GetProps()
  local isShow = props and props.isShow or false
  local showType = state and state.showType
  local isFadeInAnimPlaying = state and state.isFadeInAnimPlaying or false
  local isFadeOutAnimPlaying = state and state.isFadeOutAnimPlaying or false
  local nextShowType = showType
  if showType == WidgetShowType.Hide then
    if isShow then
      if isFadeInAnimPlaying then
        nextShowType = WidgetShowType.Entering
      else
        nextShowType = WidgetShowType.Show
      end
    end
  elseif showType == WidgetShowType.Entering then
    if not isFadeInAnimPlaying then
      nextShowType = WidgetShowType.Show
    end
  elseif showType == WidgetShowType.Show then
    if not isShow then
      if isFadeOutAnimPlaying then
        nextShowType = WidgetShowType.Exiting
      else
        nextShowType = WidgetShowType.Hide
      end
    end
  elseif showType == WidgetShowType.Exiting and not isFadeOutAnimPlaying then
    nextShowType = WidgetShowType.Hide
  end
  if showType ~= nextShowType then
    local _, nextState = self:GetCurrAndNextState()
    nextState.showType = nextShowType
    self:SetState(nextState)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnAnimationStarted(Animation)
  if Animation == self.FadeIn then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isFadeInAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.FadeOut then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isFadeOutAnimPlaying = true
    self:SetState(nextState)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnAnimationFinished(Animation)
  if Animation == self.FadeIn then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isFadeInAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.FadeOut then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isFadeOutAnimPlaying = false
    self:SetState(nextState)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:GetProps()
  return self.stateManager:GetProps()
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:SetProps(nextProps)
  self.stateManager:SetProps(nextProps)
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:GetState()
  return self.stateManager:GetState()
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:GetCurrAndNextState()
  return self.stateManager:GetCurrAndNextState()
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:SetState(nextState)
  self.stateManager:SetState(nextState)
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnActive(OnActiveCallback)
  if OnActiveCallback then
    tcall(nil, OnActiveCallback, self)
  end
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnDeactive()
end

function UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C:OnAddEventListener()
end

return UMG_Battle_Popup_DiscoveringDifferentlyColoredPet_C
