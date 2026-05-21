local Base = require("NewRoco.Modules.System.PetUI.Res.PetTeam.UMG_ListItem_PetTeam_C")
local UMG_Common_ListItem_Pet1_C = require("NewRoco.Modules.System.Common.res.UMG_Common_ListItem_Pet1_C")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_ListItem_PetTeam1_C = Base:Extend("UMG_ListItem_PetTeam1_C")

function UMG_ListItem_PetTeam1_C:OnConstruct()
  Base.OnConstruct(self)
end

function UMG_ListItem_PetTeam1_C:OnDestruct()
  Base.OnDestruct(self)
end

function UMG_ListItem_PetTeam1_C:OnItemUpdate(data, datalist, index)
  Base.OnItemUpdate(self, data, datalist, index)
end

function UMG_ListItem_PetTeam1_C:OnItemSelected(_bSelected)
  Base.OnItemSelected(self, _bSelected)
end

function UMG_ListItem_PetTeam1_C:OnDeactive()
  Base.OnDeactive(self)
end

function UMG_ListItem_PetTeam1_C.GetInitState()
  local initState = Base.GetInitState()
  initState.isShowPut = true
  return initState
end

function UMG_ListItem_PetTeam1_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  Base.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsDragItem = prevProps and prevProps.isDragItem
  local currIsDragItem = currProps and currProps.isDragItem
  if prevKey ~= currKey or prevIsDragItem ~= currIsDragItem then
    local isShowMove = false
    if currIsDragItem then
      isShowMove = true
    end
    derivedState.isShowMove = isShowMove
  end
end

function UMG_ListItem_PetTeam1_C:RenderWidget(prevProps, currProps, prevState, currState)
  Base.RenderWidget(self, prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsShowPut = prevState and prevState.isShowPut
  local currIsShowPut = currState and currState.isShowPut
  local prevIsShowMove = prevState and prevState.isShowMove
  local currIsShowMove = currState and currState.isShowMove
  if prevIsShowPut ~= currIsShowPut then
    local putVisibility = UE.ESlateVisibility.Collapsed
    if currIsShowPut then
      putVisibility = UE.ESlateVisibility.Visible
    end
    self.Put:SetVisibility(putVisibility)
  end
  if prevKey ~= currKey or prevIsShowMove ~= currIsShowMove then
    local moveVisibility = UE.ESlateVisibility.Collapsed
    if currIsShowMove then
      moveVisibility = UE.ESlateVisibility.Visible
    end
    self.Move:SetVisibility(moveVisibility)
  end
end

function UMG_ListItem_PetTeam1_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  Base.OnWidgetDidUpdate(self, prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsDragItem = prevProps and prevProps.isDragItem
  local currIsDragItem = currProps and currProps.isDragItem
  if prevKey ~= currKey and currKey ~= WidgetStateManager.InitKey and currIsDragItem and not self:IsAnimationPlaying(self.In) then
    self:PlayAnimation(self.In)
  end
end

function UMG_ListItem_PetTeam1_C:GetProps()
  return Base.GetProps(self)
end

return UMG_ListItem_PetTeam1_C
