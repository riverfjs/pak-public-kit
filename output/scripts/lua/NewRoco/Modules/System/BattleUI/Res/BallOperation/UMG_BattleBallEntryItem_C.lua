local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_BattleBallEntryItem_C = Base:Extend("UMG_BattleBallEntryItem_C")

function UMG_BattleBallEntryItem_C:OnConstruct()
  self.props = {}
end

function UMG_BattleBallEntryItem_C:OnDestruct()
end

function UMG_BattleBallEntryItem_C:OnItemUpdate(nextProps, datalist, index)
  local prevProps = self.props
  self.props = nextProps
  self:RenderWidget(prevProps, nextProps)
  self:OnWidgetDidUpdate(prevProps, nextProps)
end

function UMG_BattleBallEntryItem_C:RenderWidget(prevProps, nextProps)
  local prevData = prevProps and prevProps.data
  local nextData = nextProps and nextProps.data
  local prevCanDoLongClick = prevProps and prevProps.disableDoLongClick
  local nextCanDoLongClick = nextProps and nextProps.disableDoLongClick
  local prevCanCatch = prevProps and prevProps.bCanCatch
  local currCanCatch = nextProps and nextProps.bCanCatch
  local prevCatchMsg = prevProps and prevProps.catchMsg
  local currCatchMsg = nextProps and nextProps.catchMsg
  if prevData ~= nextData then
    local _data = nextData
    self.data = _data
  end
  if prevData ~= nextData or prevCanDoLongClick ~= nextCanDoLongClick then
    local _data = nextData
    if _data:IsValid() then
      self.NumberText:SetText(_data.id)
    end
    local entryProps = {}
    entryProps.disableDoLongClick = nextCanDoLongClick
    entryProps.ballData = nextData
    self.UMG_BattleBallEntry:SetProps(entryProps)
  end
  if prevCanCatch ~= currCanCatch or prevCatchMsg ~= currCatchMsg or prevData ~= nextData then
    local canCatch = true
    if nil ~= currCanCatch then
      canCatch = currCanCatch
    end
    local catchMsg = currCatchMsg
    self.UMG_BattleBallEntry:SetCanCatch(canCatch, catchMsg)
  end
end

function UMG_BattleBallEntryItem_C:OnWidgetDidUpdate(prevProps, nextProps)
  local prevData = prevProps and prevProps.data
  local nextData = nextProps and nextProps.data
  local prevIndex = prevData and prevData.index
  local nextIndex = nextData and nextData.index
  local prevIsValid = prevData and prevData:IsValid() or false
  local nextIsValid = nextData and nextData:IsValid() or false
  if nextIndex then
    local props = self.props
    local callbackOwner = props and props.callbackOwner
    local onSpawnCallback = props and props.onSpawnCallback
    if onSpawnCallback then
      tcall(callbackOwner, onSpawnCallback, nextIndex, self.UMG_BattleBallEntry)
    end
  end
end

function UMG_BattleBallEntryItem_C:OnItemSelected(_bSelected)
end

function UMG_BattleBallEntryItem_C:OnDeactive()
end

function UMG_BattleBallEntryItem_C:OnSpawn()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self.UMG_BattleBallEntry:SetVisibility(UE4.ESlateVisibility.Visible)
  if not self.UMG_BattleBallEntry:IsAnyOpenAnimationPlaying() and not self.UMG_BattleBallEntry:IsShowSelected() then
    self.UMG_BattleBallEntry:StopAndPlayAnim(self.UMG_BattleBallEntry.open)
  end
  local props = self.props
  local callbackOwner = props and props.callbackOwner
  local onSpawnCallback = props and props.onSpawnCallback
  local dataIndex = self.data and self.data.index
  if onSpawnCallback and dataIndex then
    tcall(callbackOwner, onSpawnCallback, dataIndex, self.UMG_BattleBallEntry)
  end
end

function UMG_BattleBallEntryItem_C:OnDespawn()
  local props = self.props
  local callbackOwner = props and props.callbackOwner
  local onDespawnCallback = props and props.onDespawnCallback
  local dataIndex = self.data and self.data.index
  if onDespawnCallback and dataIndex then
    tcall(callbackOwner, onDespawnCallback, dataIndex)
  end
  self.UMG_BattleBallEntry:StopCurrentAnimation()
  self.UMG_BattleBallEntry:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry:ResetPressState()
  self.UMG_BattleBallEntry.fatherList = nil
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleBallEntryItem_C:SelectCatchBall()
  self.UMG_BattleBallEntry:SelectCatchBall()
end

return UMG_BattleBallEntryItem_C
