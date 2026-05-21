local Base = require("NewRoco.Modules.System.Common.res.UMG_Common_ListItem_Pet1_C")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_ListItem_PetTeam_C = Base:Extend("UMG_ListItem_PetTeam_C")

function UMG_ListItem_PetTeam_C:OnConstruct()
  Base.OnConstruct(self)
  self.stateManager = WidgetStateManager()
  local initState = self.GetInitState()
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

function UMG_ListItem_PetTeam_C:OnDestruct()
  Base.OnDestruct(self)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:DeInit()
  end
end

function UMG_ListItem_PetTeam_C:OnItemUpdate(data, datalist, index)
  local props = data and data.props
  if props then
    self:SetProps(props)
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.datalist = datalist
  nextState.index = index
  self:SetState(nextState)
end

function UMG_ListItem_PetTeam_C:OnItemSelected(_bSelected)
  Base.OnItemSelected(self, _bSelected)
end

function UMG_ListItem_PetTeam_C:OnDeactive()
  Base.OnDeactive(self)
end

function UMG_ListItem_PetTeam_C.GetInitState()
  local initState = {}
  return initState
end

function UMG_ListItem_PetTeam_C.DeriveStateFromProps(prevState, nextProps)
  return prevState
end

function UMG_ListItem_PetTeam_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevBaseInfo = prevProps and prevProps.baseInfo
  local currBaseInfo = currProps and currProps.baseInfo
  local prevIsWarehouseUiItem = prevProps and prevProps.isWarehouseUiItem
  local currIsWarehouseUiItem = currProps and currProps.isWarehouseUiItem
  local prevIsInTeam = prevProps and prevProps.isInTeam
  local currIsInTeam = currProps and currProps.isInTeam
  if prevBaseInfo ~= currBaseInfo then
    local petData = currBaseInfo and currBaseInfo.PetData
    local petGid = petData and petData.gid
    local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
    isRandomPet = isRandomPet or false
    derivedState.isRandomPet = isRandomPet
  end
  if prevIsWarehouseUiItem ~= currIsWarehouseUiItem or prevIsInTeam ~= currIsInTeam or prevKey ~= currKey then
    local canInteract = true
    if currIsWarehouseUiItem and currIsInTeam then
      canInteract = false
    end
    derivedState.canInteract = canInteract
  end
end

function UMG_ListItem_PetTeam_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsDragItem = prevProps and prevProps.isDragItem
  local currIsDragItem = currProps and currProps.isDragItem
  local prevPetIsDragging = prevProps and prevProps.petSelfIsDragging
  local currPetIsDragging = currProps and currProps.petSelfIsDragging
  local prevBaseInfo = prevProps and prevProps.baseInfo
  local currBaseInfo = currProps and currProps.baseInfo
  local prevIsRandomPet = prevState and prevState.isRandomPet
  local currIsRandomPet = currState and currState.isRandomPet
  local prevCanInteract = prevState and prevState.canInteract
  local currCanInteract = currState and currState.canInteract
  local prevIsWarehouseUiItem = prevProps and prevProps.isWarehouseUiItem
  local currIsWarehouseUiItem = currProps and currProps.isWarehouseUiItem
  local prevIsInTeam = prevProps and prevProps.isInTeam
  local currIsInTeam = currProps and currProps.isInTeam
  if prevIsDragItem ~= currIsDragItem or prevPetIsDragging ~= currPetIsDragging or prevIsRandomPet ~= currIsRandomPet or prevCanInteract ~= currCanInteract or prevKey ~= currKey then
    local dragMaskPetVisibility = UE.ESlateVisibility.Collapsed
    if (not currIsDragItem and currPetIsDragging or not currCanInteract) and not currIsRandomPet then
      dragMaskPetVisibility = UE.ESlateVisibility.SelfHitTestInvisible
    end
    self.DragMaskPet:SetVisibility(dragMaskPetVisibility)
  end
  if prevBaseInfo ~= currBaseInfo then
    local petData = currBaseInfo and currBaseInfo.PetData
    local petBaseInfo = petData and petData.PetBaseInfo
    local base_conf_id = petBaseInfo and petBaseInfo.base_conf_id
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id, true)
    local modelConfId = petBaseConf and petBaseConf.model_conf
    local modelConf = _G.DataConfigManager:GetModelConf(modelConfId, true)
    local iconPath = modelConf and modelConf.icon or ""
    self.DragMaskPet:SetPath(iconPath)
  end
  if (prevIsWarehouseUiItem ~= currIsWarehouseUiItem or prevIsInTeam ~= currIsInTeam or prevKey ~= currKey) and self.Equipment then
    local equipmentVisibility = UE.ESlateVisibility.Collapsed
    if currIsWarehouseUiItem and currIsInTeam then
      equipmentVisibility = UE.ESlateVisibility.SelfHitTestInvisible
    end
    self.Equipment:SetVisibility(equipmentVisibility)
  end
end

function UMG_ListItem_PetTeam_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevBaseInfo = prevProps and prevProps.baseInfo
  local currBaseInfo = currProps and currProps.baseInfo
  local prevIsDragItem = prevProps and prevProps.isDragItem
  local currIsDragItem = currProps and currProps.isDragItem
  local prevDataList = prevState and prevState.datalist
  local currDataList = currState and currState.datalist
  local prevIndex = prevState and prevState.index
  local currIndex = currState and currState.index
  local prevIsRandomPet = prevState and prevState.isRandomPet
  local currIsRandomPet = currState and currState.isRandomPet
  local prevPetIsDragging = prevProps and prevProps.petSelfIsDragging
  local currPetIsDragging = currProps and currProps.petSelfIsDragging
  local prevRightNumber = prevBaseInfo and prevBaseInfo.rightShowNumber
  local currRightNumber = currBaseInfo and currBaseInfo.rightShowNumber
  local prevCanInteract = prevState and prevState.canInteract
  local currCanInteract = currState and currState.canInteract
  local itemUpdated = false
  if prevBaseInfo ~= currBaseInfo or prevDataList ~= currDataList or prevIndex ~= currIndex or prevIsDragItem ~= currIsDragItem or prevKey ~= currKey then
    local baseInfo = currBaseInfo
    local isSelect = baseInfo and baseInfo.isSelect or false
    local nextSelect = isSelect or false
    if currIsDragItem then
      nextSelect = false
    end
    if isSelect ~= nextSelect and currBaseInfo then
      baseInfo = {}
      table.copy(currBaseInfo, baseInfo)
      baseInfo.isSelect = nextSelect
    end
    baseInfo = baseInfo or {}
    Base.OnItemUpdate(self, baseInfo, currDataList, currIndex)
    itemUpdated = true
  end
  if itemUpdated or prevIsRandomPet ~= currIsRandomPet or prevIsDragItem ~= currIsDragItem or prevPetIsDragging ~= currPetIsDragging or prevCanInteract ~= currCanInteract or prevKey ~= currKey then
    local baseInfo = currBaseInfo
    local isPetListItem = baseInfo and baseInfo.isPetListItem
    if currIsRandomPet and (not (not (not currIsDragItem and currPetIsDragging) or isPetListItem) or not currCanInteract) then
      self:ChangeItemState(Base.ItemState.RandomPet)
    end
  end
  if prevKey ~= currKey and not self:IsAnimationPlaying(self.In_2) then
    self:PlayAnimation(self.In_2)
  end
  local needInitRightNumber = prevKey ~= currKey and nil == currKey
  if needInitRightNumber then
    self:InitRightNumberState()
  end
  if prevRightNumber ~= currRightNumber then
    local isShow = nil ~= currRightNumber
    self:SetIsRightNumberShow(isShow)
  end
end

function UMG_ListItem_PetTeam_C:ChangeItemState(state)
  Base.ChangeItemState(self, state)
  if state == Base.ItemState.RandomPet then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(4)
    self:SetObturationVisible(false)
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ListItem_PetTeam_C:InitRightNumberState()
  local _, nextState = self:GetCurrAndNextState()
  nextState.isNumberShow = false
  nextState.isNumberShowDisplay = false
  nextState.isNumberAnimPlaying = false
  self:SetState(nextState)
  if self:IsAnimationPlaying(self.Number_In) then
    self:StopAnimation(self.Number_In)
  end
  if self:IsAnimationPlaying(self.Number_Out) then
    self:StopAnimation(self.Number_Out)
  end
  local numberOutEndTime = self.Number_Out:GetEndTime()
  self:PlayAnimation(self.Number_Out, numberOutEndTime)
end

function UMG_ListItem_PetTeam_C:SetIsRightNumberShow(isShow)
  local _, nextState = self:GetCurrAndNextState()
  nextState.isNumberShow = isShow
  self:SetState(nextState)
  self:RefreshIsRightNumberDisplay()
end

function UMG_ListItem_PetTeam_C:RefreshIsRightNumberDisplay()
  local currState, nextState = self:GetCurrAndNextState()
  local currIsNumberAnimPlaying = currState and currState.isNumberAnimPlaying
  local currIsNumberShowDisplay = currState and currState.isNumberShowDisplay
  local currIsNumberShow = currState and currState.isNumberShow
  if currIsNumberAnimPlaying then
    return
  end
  local prevIsDisplay = currIsNumberShowDisplay or false
  local nextIsDisplay = currIsNumberShow or false
  if prevIsDisplay == nextIsDisplay then
    return
  end
  nextState.isNumberShowDisplay = nextIsDisplay
  if prevIsDisplay and not nextIsDisplay then
    nextState.isNumberAnimPlaying = true
    self:PlayAnimation(self.Number_Out)
  elseif not prevIsDisplay and nextIsDisplay then
    nextState.isNumberAnimPlaying = true
    self:PlayAnimation(self.Number_In)
  end
  self:SetState(nextState)
end

function UMG_ListItem_PetTeam_C:OnAnimationFinished(Animation)
  Base.OnAnimationFinished(self, Animation)
  if Animation == self.Number_In or Animation == self.Number_Out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isNumberAnimPlaying = false
    self:SetState(nextState)
    self:RefreshIsRightNumberDisplay()
  end
end

function UMG_ListItem_PetTeam_C:GetProps()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetProps() or {}
end

function UMG_ListItem_PetTeam_C:GetState()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetState() or {}
end

function UMG_ListItem_PetTeam_C:GetCurrAndNextState()
  local stateManager = self.stateManager
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
  return {}, {}
end

function UMG_ListItem_PetTeam_C:SetProps(nextProps)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_ListItem_PetTeam_C:SetState(nextState)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetState(nextState)
  end
end

return UMG_ListItem_PetTeam_C
