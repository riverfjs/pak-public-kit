local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_Battle_Card_Item_C = Base:Extend("UMG_Battle_Card_Item_C")

function UMG_Battle_Card_Item_C:OnConstruct()
  self.UMG_Battle_Card:SetVisibility(UE.ESlateVisibility.Visible)
  self.UMG_Battle_Card:SetOnAnimationStartCallback(self.HandleCardAnimationStart, self)
  self.UMG_Battle_Card:SetOnAnimationFinishCallback(self.HandleCardAnimationFinish, self)
  self.stateManager = WidgetStateManager()
  local initState = {}
  self.stateManager:Init({
    owner = self,
    RenderWidget = self.RenderWidget,
    OnWidgetDidUpdate = self.OnWidgetDidUpdate,
    UpdateDerivedState = self.UpdateDerivedState,
    DeriveStateFromProps = self.DeriveStateFromProps,
    initState = initState,
    autoCreateDebugger = false
  })
end

function UMG_Battle_Card_Item_C:OnDestruct()
  self.stateManager:DeInit()
end

function UMG_Battle_Card_Item_C:OnItemUpdate(data, datalist, index)
  local _, nextState = self:GetCurrAndNextState()
  nextState.datalist = datalist
  nextState.index = index
  self:SetState(nextState)
  local props = data and data.props
  if props then
    self:SetProps(props)
  end
end

function UMG_Battle_Card_Item_C:OnItemSelected(_bSelected)
end

function UMG_Battle_Card_Item_C:OnDeactive()
end

function UMG_Battle_Card_Item_C.DeriveStateFromProps(prevState, nextProps)
  return prevState
end

function UMG_Battle_Card_Item_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevIsShow = prevProps and prevProps.isShow or false
  local currIsShow = currProps and currProps.isShow or false
  local prevStateIsShow = prevState and prevState.isShow or false
  local currStateIsShow = currState and currState.isShow or false
  local prevAnimationPlayingMap = prevState and prevState.animationPlayingMap or {}
  local currAnimationPlayingMap = currState and currState.animationPlayingMap or {}
  if prevIsShow ~= currIsShow or prevStateIsShow ~= currStateIsShow or prevAnimationPlayingMap ~= currAnimationPlayingMap then
    local animationPlayingCount = 0
    for animation, isPlaying in pairs(currAnimationPlayingMap) do
      if isPlaying then
        animationPlayingCount = animationPlayingCount + 1
      end
    end
    local isAnyAnimationPlaying = animationPlayingCount > 0
    local isShowDisplayProps = currIsShow or isAnyAnimationPlaying
    local isShowDisplayState = currStateIsShow or isAnyAnimationPlaying
    local isShowDisplay = isShowDisplayProps or isShowDisplayState
    derivedState.isShowDisplay = isShowDisplay
  end
end

function UMG_Battle_Card_Item_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevIsShow = prevProps and prevProps.isShow
  local currIsShow = currProps and currProps.isShow
  local prevIsShowDisplay = prevState and prevState.isShowDisplay
  local currIsShowDisplay = currState and currState.isShowDisplay
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  if prevIsShowDisplay ~= currIsShowDisplay or prevKey ~= currKey then
    local visibility = UE.ESlateVisibility.Hidden
    local renderOpacity = 0
    if currIsShowDisplay then
      renderOpacity = 1
      visibility = UE.ESlateVisibility.Visible
    end
    self.UMG_Battle_Card:SetRenderOpacity(renderOpacity)
  end
end

function UMG_Battle_Card_Item_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIndex = prevProps and prevProps.index
  local currIndex = currProps and currProps.index
  local prevCard = prevProps and prevProps.card
  local currCard = currProps and currProps.card
  local prevFatherList = prevProps and prevProps.fatherList
  local currFatherList = currProps and currProps.fatherList
  local prevCardUpdateFlag = prevProps and prevProps.cardUpdateFlag
  local currCardUpdateFlag = currProps and currProps.cardUpdateFlag
  local prevOnPetClickCallback = prevProps and prevProps.onPetClickCallback
  local currOnPetClickCallback = currProps and currProps.onPetClickCallback
  local prevOnPetClickCallbackOwner = prevProps and prevProps.onPetClickCallbackOwner
  local currOnPetClickCallbackOwner = currProps and currProps.onPetClickCallbackOwner
  local prevIsSelect = prevProps and prevProps.isSelect or false
  local nextIsSelect = currProps and currProps.isSelect or false
  local prevInputActionName = prevProps and prevProps.inputActionName
  local currInputActionName = currProps and currProps.inputActionName
  local prevUpdatePcKeyFlag = prevProps and prevProps.updatePcKeyFlag
  local currUpdatePcKeyFlag = currProps and currProps.updatePcKeyFlag
  local prevIsShow = prevProps and prevProps.isShow
  local currIsShow = currProps and currProps.isShow
  local prevChangingBetweenSubPanels = prevProps and prevProps.changingBetweenSubPanels
  local currChangingBetweenSubPanels = currProps and currProps.changingBetweenSubPanels
  if prevCard ~= currCard or prevKey ~= currKey or prevCardUpdateFlag ~= currCardUpdateFlag or prevFatherList ~= currFatherList then
    self.UMG_Battle_Card:SetData(currCard, currFatherList)
  end
  if prevOnPetClickCallback ~= currOnPetClickCallback or prevOnPetClickCallbackOwner ~= currOnPetClickCallbackOwner then
    self.UMG_Battle_Card:SetOnPetClickCallback(currOnPetClickCallback, currOnPetClickCallbackOwner)
  end
  if prevKey ~= currKey then
    self.UMG_Battle_Card:ResetSelect()
    local prevAnimationPlayingMap = prevState and prevState.animationPlayingMap or {}
    local nextAnimationPlayingMap = {}
    table.copy(prevAnimationPlayingMap, nextAnimationPlayingMap)
    local _, nextState = self:GetCurrAndNextState()
    nextState.animationPlayingMap = nextAnimationPlayingMap
    self:SetState(nextState)
  end
  if prevIsSelect ~= nextIsSelect or prevCard ~= currCard then
    if nextIsSelect then
      self.UMG_Battle_Card:Select()
    else
      self.UMG_Battle_Card:DisSelect()
    end
  end
  if prevInputActionName ~= currInputActionName or prevUpdatePcKeyFlag ~= currUpdatePcKeyFlag then
    if currInputActionName then
      self.UMG_Battle_Card.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, currInputActionName)
      if "" ~= image then
        self.UMG_Battle_Card.Text_PCKey:SetImageMode(image)
      else
        self.UMG_Battle_Card.Text_PCKey:SetText(text)
      end
    else
      self.UMG_Battle_Card.Text_PCKey:SetKeyVisibility(false)
    end
  end
  if prevIsShow ~= currIsShow or prevKey ~= currKey then
    if prevKey ~= currKey and currIsShow then
      self.UMG_Battle_Card:PlayOpenAnimation(true, false)
    elseif not prevIsShow and currIsShow then
      self.UMG_Battle_Card:PlayOpenAnimation(true, currChangingBetweenSubPanels)
    elseif prevIsShow and not currIsShow then
      self.UMG_Battle_Card:PlayOpenAnimation(false, currChangingBetweenSubPanels)
    end
  end
  if prevIsShow ~= currIsShow then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isShow = currIsShow
    self:SetState(nextState)
  end
end

function UMG_Battle_Card_Item_C:OnSpawn()
  local currProps = self:GetProps()
  local onSpawnCallback = currProps and currProps.onSpawnCallback
  local index = currProps and currProps.index
  if onSpawnCallback then
    tcall(nil, onSpawnCallback, index)
  end
end

function UMG_Battle_Card_Item_C:OnDespawn()
  local currProps = self:GetProps()
  local onDeSpawnCallback = currProps and currProps.onDeSpawnCallback
  local index = currProps and currProps.index
  if onDeSpawnCallback then
    tcall(nil, onDeSpawnCallback, index)
  end
end

function UMG_Battle_Card_Item_C:HandleCardAnimationStart(animation)
  local currState, nextState = self:GetCurrAndNextState()
  local currAnimationPlayingMap = currState and currState.animationPlayingMap or {}
  local nextAnimationPlayingMap = {}
  table.copy(currAnimationPlayingMap, nextAnimationPlayingMap)
  if nextAnimationPlayingMap and animation then
    nextAnimationPlayingMap[animation] = true
  end
  nextState.animationPlayingMap = nextAnimationPlayingMap
  self:SetState(nextState)
end

function UMG_Battle_Card_Item_C:HandleCardAnimationFinish(animation)
  local currState, nextState = self:GetCurrAndNextState()
  local currAnimationPlayingMap = currState and currState.animationPlayingMap or {}
  local nextAnimationPlayingMap = {}
  table.copy(currAnimationPlayingMap, nextAnimationPlayingMap)
  if nextAnimationPlayingMap and animation then
    nextAnimationPlayingMap[animation] = false
  end
  nextState.animationPlayingMap = nextAnimationPlayingMap
  self:SetState(nextState)
end

function UMG_Battle_Card_Item_C:GetProps()
  return self.stateManager:GetProps()
end

function UMG_Battle_Card_Item_C:GetState()
  return self.stateManager:GetProps()
end

function UMG_Battle_Card_Item_C:GetState()
  return self.stateManager:GetState()
end

function UMG_Battle_Card_Item_C:GetCurrAndNextState()
  return self.stateManager:GetCurrAndNextState()
end

function UMG_Battle_Card_Item_C:SetProps(nextProps)
  self.stateManager:SetProps(nextProps)
end

function UMG_Battle_Card_Item_C:SetState(nextState)
  self.stateManager:SetState(nextState)
end

return UMG_Battle_Card_Item_C
