local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetWarehouseOrganization_C = _G.NRCPanelBase:Extend("UMG_PetWarehouseOrganization_C")
UMG_PetWarehouseOrganization_C.LineType = {
  None = 0,
  FrontLine = 1,
  BehindLine = 2
}

function UMG_PetWarehouseOrganization_C:OnConstruct()
  self.SelectBoxIndex = 0
  self:OnAddEventListener()
end

function UMG_PetWarehouseOrganization_C:OnAddEventListener()
  self:AddButtonListener(self.backBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.SortingBtn.btnLevelUp, self.OnClickSortingBtn)
  self:AddButtonListener(self.Btn_Organize.btnLevelUp, self.OnClickSortedOutBtn)
  self:AddButtonListener(self.ResetBtn.btnLevelUp, self.OnClickResetBtn)
  self:AddButtonListener(self.BtnClick, self.OnClickBtnClickBtn)
  self:RegisterEvent(self, PetUIModuleEvent.OnChageSelectPetBagBoxItem, self.OnChageSelectPetBagBoxItem)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxChangeNotifyEvent, self.OnPetBoxChangeNotify)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxMarkChange, self.OnPetBoxMarkChange)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxUpdate, self.OnPetBoxUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseOrganization_C", self, PetUIModuleEvent.OnPetPortableBagTouchEnded, self.OnPetPortableBagTouchEnded)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseOrganization_C", self, PetUIModuleEvent.SetPanelCanScroll, self.SetBoxListPanelCanScroll)
end

function UMG_PetWarehouseOrganization_C:OnDeactive()
  self:LeaveEditState()
  self:ClearTimer()
  self:UnRegisterEvent(self, PetUIModuleEvent.OnChageSelectPetBagBoxItem, self.OnChageSelectPetBagBoxItem)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxChangeNotifyEvent, self.OnPetBoxChangeNotify)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxMarkChange, self.OnPetBoxMarkChange)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxUpdate, self.OnPetBoxUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent, OnPetPortableBagTouchEnded, self.OnPetPortableBagTouchEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SetPanelCanScroll, self.SetBoxListPanelCanScroll)
  if UE4.UObject.IsValid(self.DragItemInstance) then
    self.DragItemInstance:RemoveFromParent()
    self.DragItemInstance = nil
  end
end

function UMG_PetWarehouseOrganization_C:OnActive()
  self.offsetPerSec = _G.DataConfigManager:GetGlobalConfigByKeyType("warehouse_auto_move_ratio", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OrganizeBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SortedOut:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local bFromBag = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBoxPanelOpenState)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetBoxPanelOpenState, false)
  if bFromBag then
    self.bNeedToInit = true
    self.bFromBag = true
    self.module:SetNewPetBagBoxPanelOpenState(true)
    self.module:OnSavePetBagChildrenPanelState("Box", true)
    self:OnEnable()
  else
    self:Disable()
    self.bNeedToInit = true
  end
end

function UMG_PetWarehouseOrganization_C:OnEnable()
  if self.bNeedToInit then
    self:SetBoxList()
    self:SetEditBoxList()
    self.ItemList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemList:SetRenderOpacity(1)
    self.ItemList2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.ItemList2:SetRenderOpacity(0)
    self.bNeedToInit = false
  end
  if self.bNeedToInit ~= nil then
    local isAttributeOpen = self.module:FoldOrOpenRightPanel()
    self:DispatchEvent(PetUIModuleEvent.AttributeChangeSetEggBtn, isAttributeOpen)
    self.CanScroll = true
    self.bLockOffsetUpdate = false
    self:DispatchEvent(PetUIModuleEvent.OnUpdatePetBagEmptyView)
    self.bEnableFlag = true
    self:StopAnimation(self.Out)
    self:StopAnimation(self.In)
    self:PlayAnimation(self.In)
  end
end

function UMG_PetWarehouseOrganization_C:OnTick(deltaTime)
  if not self.curTickTime then
    self.curTickTime = 0
  end
  if self.curTickTime + deltaTime >= 1 then
    self.curTickTime = 0
    self:UpdateScrollOffset()
  else
    self.curTickTime = self.curTickTime + deltaTime
  end
end

function UMG_PetWarehouseOrganization_C:UpdateScrollOffset()
  if self.bLockOffsetUpdate then
    return
  end
  if self.EnterEditState then
    local offset = self.ItemList2:GetScrollOffset()
    self.ItemList:NRCSetScrollOffset(offset)
  else
    local offset = self.ItemList:GetScrollOffset()
    if offset > self.ItemList2:GetScrollOffsetOfEnd() then
      offset = self.ItemList2:GetScrollOffsetOfEnd()
    end
    self.ItemList2:NRCSetScrollOffset(offset)
  end
end

function UMG_PetWarehouseOrganization_C:SetBoxList(targetBoxID, bForceNoCreate, bNeedToDispatchEvent)
  local itemList = self.module:GetPetBoxDatas()
  local selectIdx = 0
  local selectBoxId = targetBoxID or self.module:GetLastOpenBoxId()
  local list = {}
  for i, v in ipairs(itemList or {}) do
    if v.id == selectBoxId then
      selectIdx = i - 1
    end
    local item = {
      boxInfo = v,
      bEditItem = false,
      parent = self
    }
    table.insert(list, item)
  end
  local oldSelectIdx = self.ItemList:GetSelectedIndex() - 1
  self.bLockOffsetUpdate = true
  local offset = self.ItemList:GetScrollOffset()
  self.ItemList:InitList(list, bForceNoCreate)
  self.ItemList:SelectItemByIndex(selectIdx)
  if bForceNoCreate and oldSelectIdx == selectIdx and bNeedToDispatchEvent then
    self:DispatchEvent(PetUIModuleEvent.OnClickSelectPetBagBoxItem, list[selectIdx + 1].boxInfo, selectIdx + 1)
  end
  if self.bFromBag then
    self.bFromBag = false
    self:DelayFrames(10, function()
      local maxOffset = self.ItemList:GetScrollOffsetOfEnd()
      self.ItemList:NRCSetScrollOffset(maxOffset)
      self.bLockOffsetUpdate = false
    end)
  elseif targetBoxID and bForceNoCreate or not targetBoxID and bForceNoCreate then
    self.ItemList:SetRenderOpacity(0)
    self:DelayFrames(10, function()
      self.ItemList:NRCSetScrollOffset(offset)
      self.ItemList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ItemList:SetRenderOpacity(1)
      self.bLockOffsetUpdate = false
    end)
  else
    self.bLockOffsetUpdate = false
  end
end

function UMG_PetWarehouseOrganization_C:SetEditBoxList(bForceNoCreate)
  local itemList = self.module:GetPetBoxDatas()
  local list = {}
  for _, v in pairs(itemList or {}) do
    if v and v.petBoxInfo then
      local item = {
        boxInfo = v,
        bEditItem = true,
        parent = self
      }
      table.insert(list, item)
    end
  end
  self.ItemList2:InitList(list, bForceNoCreate)
end

function UMG_PetWarehouseOrganization_C:OnChageSelectPetBagBoxItem(SelectBoxIndex)
  self.SelectBoxIndex = SelectBoxIndex
  if self.bNeedToInit == false then
    self.ItemList:SelectItemByIndex(self.SelectBoxIndex)
  end
end

function UMG_PetWarehouseOrganization_C:OnPetBoxChangeNotify()
  self:SetBoxList(nil, true)
  self:SetEditBoxList()
end

function UMG_PetWarehouseOrganization_C:GetNewSelectBoxID()
  for i, boxID in pairs(self.EditBoxList or {}) do
    if boxID == self.module:GetLastOpenBoxId() then
      return i
    end
  end
  return nil
end

function UMG_PetWarehouseOrganization_C:OnClickCloseBtn()
  if self.EnterEditState then
    self.bLockExchange = true
    self:UpdateScrollOffset()
    local needToSave = self:CheckNeedToSaveNewList()
    if needToSave and self.EditBoxList then
      self.newSelectBoxID = self:GetNewSelectBoxID()
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxSwapReq, self.EditBoxList)
    end
    self:SetBoxListPanelCanScroll(true)
    self:LeaveEditState()
    if needToSave then
      self.ItemList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.ItemList:SetRenderOpacity(0)
    end
    self.BtnClick:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.bLockExchange = false
  else
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
    self:ClosePanel()
  end
end

function UMG_PetWarehouseOrganization_C:OnClickSortingBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseOrganization_C:OnClickSortingBtn")
  self.EnterEditState = true
  self.newSelectBoxID = nil
  self.EditBoxList = self:GetOriBoxList()
  self.SortingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OrganizeBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ResetBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.curScrollOffset = self.ItemList:GetScrollOffset()
  self.ItemList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.ItemList:SetRenderOpacity(0)
  self.ItemList2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ItemList2:SetRenderOpacity(1)
  self.BtnClick:SetVisibility(UE4.ESlateVisibility.Visible)
  self:UpdateScrollOffset()
  self:DispatchEvent(PetUIModuleEvent.OnEnterBoxEditState, true)
  for i = 1, self.ItemList2:GetTotalItemNumber() do
    local item = self.ItemList2:GetItemByIndex(i - 1)
    if item then
      item:PlayAnimation(item.In)
    end
  end
end

function UMG_PetWarehouseOrganization_C:GetOriBoxList()
  local boxList = {}
  local itemList = self.module:GetPetBoxDatas()
  for _, item in pairs(itemList or {}) do
    if item and item.petBoxInfo and item.petBoxInfo.box_id then
      table.insert(boxList, item.petBoxInfo.box_id)
    end
  end
  return boxList
end

function UMG_PetWarehouseOrganization_C:OnClickSortedOutBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseOrganization_C:OnClickSortedOutBtn")
  local curBoxIndex = self.ItemList:GetSelectedIndex()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBoxOrganizationFethod, curBoxIndex)
end

function UMG_PetWarehouseOrganization_C:OnClickResetBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetWarehouseOrganization_C:OnClickResetBtn")
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Call = self
  popUpData.Btn_RightText = LuaText.umg_bag_11
  popUpData.Btn_LeftText = LuaText.CANCEL
  popUpData.TitleText = LuaText.general_title
  popUpData.ContentText = LuaText.box_revert_sequence
  popUpData.Btn_RightHandler = self.OnResetPetList
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function UMG_PetWarehouseOrganization_C:OnClickBtnClickBtn()
  self:OnClickCloseBtn()
end

function UMG_PetWarehouseOrganization_C:OnResetPetList()
  self.EditBoxList = self:GetOriBoxList()
  self:UpdateEditBoxList()
end

function UMG_PetWarehouseOrganization_C:LeaveEditState()
  self.EnterEditState = false
  self.EditBoxList = nil
  self.SortingBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.OrganizeBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ResetBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ItemList:SetRenderOpacity(1)
  self.ItemList2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.ItemList2:SetRenderOpacity(0)
  self:DispatchEvent(PetUIModuleEvent.OnEnterBoxEditState, false)
  for i = 1, self.ItemList:GetTotalItemNumber() do
    local item = self.ItemList:GetItemByIndex(i - 1)
    if item then
      item:PlayAnimation(item.In)
    end
  end
end

function UMG_PetWarehouseOrganization_C:OnPetBoxMarkChange(box_id, mark_type, box_name, lock)
  if box_id and mark_type then
    local item = self.ItemList:GetItemByIndex(box_id - 1)
    if item then
      item:UpdateMarkIconAndName(mark_type, box_name, lock)
    end
    local item1 = self.ItemList2:GetItemByIndex(box_id - 1)
    if item1 then
      item1:UpdateMarkIconAndName(mark_type, box_name, lock)
    end
  end
end

function UMG_PetWarehouseOrganization_C:OnPcClose()
  self:OnClickCloseBtn()
end

function UMG_PetWarehouseOrganization_C:ClosePanel()
  self.module:CloseNewPetBagBoxPanel()
end

function UMG_PetWarehouseOrganization_C:OnPetBoxUpdate(targetBoxID)
  if targetBoxID then
    self:SetBoxList(targetBoxID)
    if targetBoxID then
      self:SetEditBoxList()
    end
  else
    self:SetBoxList(self.newSelectBoxID, true, true)
    self:SetEditBoxList(true)
    self.newSelectBoxID = nil
  end
end

function UMG_PetWarehouseOrganization_C:SetBoxListPanelCanScroll(CanScroll)
  self.CanScroll = CanScroll
  if not self.CanScroll then
    self:OnDragStart()
  else
    self:OnDragEnd()
    self:DisableFullBox(false)
  end
end

function UMG_PetWarehouseOrganization_C:OnDragStart()
  if self.EnterEditState then
    if self.DragBoxInfo then
      _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseOrganization_C:OnDragStart")
      self.ItemList2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.ScrollView = self.ItemList2
      self:OnInitDragItem()
      self:ForceLayoutPrepass()
    end
  else
    self.ItemList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.ScrollView = self.ItemList
    self:DisableFullBox(true)
  end
  self.DragArea1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.DragArea2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.ClickImage:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.ScrollView then
    self.itemSize = self.ScrollView:GetItemSize()
    self.ScrollOffset = self.ScrollView:GetScrollOffset()
    if self.ScrollOffset < 0 then
      self.ScrollOffset = 0
    end
  end
  self.Col = 2
end

function UMG_PetWarehouseOrganization_C:OnDragEnd()
  if self.EnterEditState then
    self:CheckBoxExchange()
    self:ClearItemDragState()
    self.ItemList2:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.curDragBoxIndex then
      local curDragBox = self.ItemList2:GetItemByIndex(self.curDragBoxIndex)
      if curDragBox then
        curDragBox:ReadyDragTo(false, self.LineType.None)
      end
    end
  else
    self.ItemList:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.curDragItemIndex then
      local item = self.ItemList:GetItemByIndex(self.curDragItemIndex)
      if item then
        item:ReadyDragPetToBox(false)
      end
    end
  end
  if self.DragItemInstance then
    self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:ClearTimer()
  self.DragArea1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.DragArea2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ClickImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ScrollView = nil
  self.itemSize = nil
  self.ScrollOffset = nil
  self.Col = 2
  self.startPos = nil
  self.curDragItemIndex = nil
  self.curDragBoxIndex = nil
  self.DragBoxInfo = nil
end

function UMG_PetWarehouseOrganization_C:ClearItemDragState()
  local selectedItem
  for i = 1, self.ItemList2:GetTotalItemNumber() do
    local item = self.ItemList2:GetItemByIndex(i - 1)
    if item and item.boxInfo and self.DragBoxInfo and item.boxInfo.box_id == self.DragBoxInfo.box_id then
      selectedItem = item
      break
    end
  end
  if selectedItem then
    selectedItem.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetWarehouseOrganization_C:CreateTimer(bAdd)
  if self.ScrollView then
    self.ScrollView:SetScrollBarForceVisible(true)
  end
  if not self.ScrollTimer then
    self.bStopChoose = true
    self.ScrollTimer = _G.TimerManager:CreateTimer(self, "ScrollTimer", 999, self.OnTimerUpdate, self.OnTimerComplete, 0.01)
    if bAdd then
      self.offsetPerSec = math.abs(self.offsetPerSec)
    else
      self.offsetPerSec = -math.abs(self.offsetPerSec)
    end
    self:OnStopChoose()
  end
end

function UMG_PetWarehouseOrganization_C:OnStopChoose()
  if self.curDragItemIndex then
    local item = self.ItemList:GetItemByIndex(self.curDragItemIndex)
    if item then
      item:ReadyDragPetToBox(false)
    end
  end
  self.curDragItemIndex = nil
  if self.curDragBoxIndex then
    local curDragBox = self.ItemList2:GetItemByIndex(self.curDragBoxIndex)
    if curDragBox then
      curDragBox:ReadyDragTo(false, self.LineType.None)
    end
  end
  self.curDragBoxIndex = nil
end

function UMG_PetWarehouseOrganization_C:OnTouchMoved(_MyGeometry, _TouchEvent)
  if not self.EnterEditState then
    if self:CheckIsInDragArea(self.DragArea1, _TouchEvent) then
      self:CreateTimer(false)
    elseif self:CheckIsInDragArea(self.DragArea2, _TouchEvent) then
      self:CreateTimer(true)
    else
      self:ClearTimer()
    end
    self:ChooseTargetBox(_MyGeometry, _TouchEvent)
  elseif self.EnterEditState and self.DragItemInstance and not self.CanScroll then
    if self:CheckIsInDragArea(self.DragArea1) then
      self:CreateTimer(false)
    elseif self:CheckIsInDragArea(self.DragArea2) then
      self:CreateTimer(true)
    else
      self:ClearTimer()
    end
    self:ChooseExchangeBox()
    if RocoEnv.PLATFORM_WINDOWS then
      local mousePos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
      local targetPos = self:GetWidgetPositionWithButtonOffset(mousePos)
      self.DragItemInstance:SetPositionInViewport(targetPos, false)
    else
      local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_TouchEvent)
      local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      local targetPos = self:GetWidgetPositionWithButtonOffset(screenPos, scale)
      self.DragItemInstance:SetPositionInViewport_ViewPosition(targetPos, true)
    end
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetWarehouseOrganization_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_PetWarehouseOrganization_C:OnPetPortableBagTouchEnded()
  if not self.EnterEditState then
    self:CheckPetDragToBox()
  end
end

function UMG_PetWarehouseOrganization_C:OnBoxTouchStarted(position)
  self:ClearTimer()
  if self.EnterEditState then
    self.startPos = UE4.FVector2D(position.x, position.y)
  end
end

function UMG_PetWarehouseOrganization_C:OnMouseLeave(_MouseEvent)
  if not self.CanScroll then
    if self.EnterEditState then
      self:OnDragEnd()
    else
      if self.curDragItemIndex then
        local item = self.ItemList:GetItemByIndex(self.curDragItemIndex)
        if item then
          item:ReadyDragPetToBox(false)
        end
      end
      self.curDragItemIndex = nil
    end
  end
end

function UMG_PetWarehouseOrganization_C:GetItemByTouchPos(_MyGeometry, _TouchEvent)
  if not self.ScrollView then
    return nil, nil
  end
  local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_TouchEvent)
  local Geometry = self.ScrollView:GetCachedGeometry()
  local curPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(Geometry, screenPos)
  if not (self.itemSize and 0 ~= self.itemSize.X and 0 ~= self.itemSize.Y and self.ScrollOffset) or not self.Col then
    self.itemSize = self.ScrollView:GetItemSize()
    self.ScrollOffset = self.ScrollView:GetScrollOffset()
    if self.ScrollOffset < 0 then
      self.ScrollOffset = 0
    end
    self.Col = 2
  end
  local AllRow = curPos.Y + self.ScrollOffset
  local AllCol = curPos.X
  local clickCol = math.floor(AllCol / self.itemSize.X)
  local clickRow = math.floor(AllRow / self.itemSize.Y)
  if clickCol < 0 or clickCol >= self.Col then
    return nil, nil
  end
  local index = clickRow * self.Col + clickCol
  local item = self.ScrollView:GetItemByIndex(index)
  return item, index
end

function UMG_PetWarehouseOrganization_C:ChooseTargetBox(_MyGeometry, _TouchEvent)
  if self.bStopChoose then
    return
  end
  local item, index = self:GetItemByTouchPos(_MyGeometry, _TouchEvent)
  if item then
    if self.curDragItemIndex then
      local curDragItem = self.ItemList:GetItemByIndex(self.curDragItemIndex)
      if curDragItem then
        curDragItem:ReadyDragPetToBox(false)
      end
    end
    if item:CheckHasEmptyPos() and not item:CheckIsLock() then
      item:ReadyDragPetToBox(true)
    end
    self.curDragItemIndex = index
  else
    if self.curDragItemIndex then
      local curDragItem = self.ItemList:GetItemByIndex(self.curDragItemIndex)
      if curDragItem then
        curDragItem:ReadyDragPetToBox(false)
      end
    end
    self.curDragItemIndex = nil
  end
end

function UMG_PetWarehouseOrganization_C:CheckPetDragToBox()
  if self.curDragItemIndex then
    local curDragItem = self.ItemList:GetItemByIndex(self.curDragItemIndex)
    if curDragItem then
      local boxID, pos = curDragItem:GetEmptyPos()
      if boxID and pos then
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdDragPetToBox, boxID, pos)
        curDragItem:ReadyDragPetToBox(false)
        curDragItem = nil
        return true
      elseif not curDragItem:CheckIsLock() then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_is_full)
      end
    end
  end
  return false
end

function UMG_PetWarehouseOrganization_C:DisableFullBox(bDisable)
  for i = 1, self.ItemList:GetTotalItemNumber() do
    local item = self.ItemList:GetItemByIndex(i - 1)
    if item and not item:CheckHasEmptyPos() and not item:CheckIsLock() then
      item:OnDisableDragPetTo(bDisable)
    end
  end
end

function UMG_PetWarehouseOrganization_C:InitButtonOffset()
  local selectedItem
  for i = 1, self.ItemList2:GetTotalItemNumber() do
    local item = self.ItemList2:GetItemByIndex(i - 1)
    if item and item.boxInfo and item.boxInfo.box_id == self.DragBoxInfo.box_id then
      selectedItem = item
      break
    end
  end
  if not selectedItem or not selectedItem.SortingBtn then
    return
  end
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  if scale and scale > 0 then
    local itemGeometry = selectedItem:GetCachedGeometry()
    local btnGeometry = selectedItem.SortingBtn:GetCachedGeometry()
    local itemSize = UE4.USlateBlueprintLibrary.GetLocalSize(itemGeometry)
    local btnSize = UE4.USlateBlueprintLibrary.GetLocalSize(btnGeometry)
    local btnAbsolutePos = UE4.USlateBlueprintLibrary.LocalToAbsolute(btnGeometry, UE4.FVector2D(0, 0))
    local itemAbsolutePos = UE4.USlateBlueprintLibrary.LocalToAbsolute(itemGeometry, UE4.FVector2D(0, 0))
    local btnPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), btnAbsolutePos)
    local itemPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), itemAbsolutePos)
    self.ButtonOffsetX = btnPos.x + btnSize.x / 2 - (itemPos.x + itemSize.x / 2)
  end
end

function UMG_PetWarehouseOrganization_C:BoxDragStart(box_info)
  if self.EnterEditState then
    self.DragBoxInfo = box_info
    self:InitButtonOffset()
    self:SetBoxListPanelCanScroll(false)
  end
end

function UMG_PetWarehouseOrganization_C:OnInitDragItem()
  if not self.DragItemInstance then
    self.DragItemInstance = UE4.UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), self.DragItem)
    if self.DragItemInstance then
      self.DragItemInstance:AddToViewport(_G.UILayerCtrlCenter.ENUM_LAYER.TOP_MSG, false)
      self.DragItemInstance:SetAlignmentInViewport(UE4.FVector2D(0.5, 0.5))
    end
  end
  if self.DragItemInstance then
    self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.DragItemInstance:OnDrag(self.DragBoxInfo)
    if RocoEnv.PLATFORM_WINDOWS then
      local mousePos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
      local targetPos = self:GetWidgetPositionWithButtonOffset(mousePos)
      self.DragItemInstance:SetPositionInViewport(targetPos, false)
    elseif self.startPos then
      local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      local targetPos = self:GetWidgetPositionWithButtonOffset(self.startPos, scale)
      self.DragItemInstance:SetPositionInViewport_ViewPosition(targetPos, true)
    end
  end
end

function UMG_PetWarehouseOrganization_C:CheckIsInDragArea(DragArea, _TouchEvent)
  local screenPos
  if _TouchEvent then
    screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_TouchEvent)
  else
    screenPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.DragItemInstance:GetCachedGeometry(), UE4.FVector2D(0, 0))
  end
  local dragAreaPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(DragArea:GetCachedGeometry(), UE4.FVector2D(0, 0))
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  if screenPos and scale and scale > 0 then
    screenPos = screenPos / scale
    dragAreaPos = dragAreaPos / scale
    local dragItemSize = UE4.FVector2D(0, 0)
    if not _TouchEvent then
      dragItemSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.DragItemInstance:GetCachedGeometry())
    end
    local dragAreaSize = UE4.USlateBlueprintLibrary.GetLocalSize(DragArea:GetCachedGeometry())
    if dragItemSize and dragAreaSize then
      local maxX = dragAreaPos.x + dragAreaSize.x
      local maxY = dragAreaPos.y + dragAreaSize.y
      if screenPos.x + dragItemSize.x / 2 >= dragAreaPos.x and maxX >= screenPos.x - dragItemSize.x / 2 and screenPos.y + dragItemSize.y / 2 >= dragAreaPos.y and maxY >= screenPos.y - dragItemSize.y / 2 then
        return true
      end
    end
  end
  return false
end

function UMG_PetWarehouseOrganization_C:ChooseExchangeBox()
  if self.bStopChoose then
    return
  end
  local item, index, lineType = self:GetItemByDragItemPos()
  if item then
    if self.curDragBoxIndex then
      local curDragBox = self.ItemList2:GetItemByIndex(self.curDragBoxIndex)
      if curDragBox then
        if index == self.curDragBoxIndex and lineType == curDragBox.curLineType then
          return
        end
        curDragBox:ReadyDragTo(false, self.LineType.None)
      end
    end
    if item.boxInfo and self.DragBoxInfo and item.boxInfo.box_id ~= self.DragBoxInfo.box_id then
      item:ReadyDragTo(true, lineType)
    end
    self.curDragBoxIndex = index
  else
    if self.curDragBoxIndex then
      local curDragBox = self.ItemList2:GetItemByIndex(self.curDragBoxIndex)
      if curDragBox then
        curDragBox:ReadyDragTo(false, self.LineType.None)
      end
    end
    self.curDragBoxIndex = nil
  end
end

function UMG_PetWarehouseOrganization_C:GetItemByDragItemPos()
  if not (self.DragItemInstance and self.ScrollView) or self.bLockExchange then
    return
  end
  local screenPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.DragItemInstance:GetCachedGeometry(), UE4.FVector2D(0, 0))
  local Geometry = self.ScrollView:GetCachedGeometry()
  local curPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(Geometry, screenPos)
  local dragItemSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.DragItemInstance:GetCachedGeometry())
  if not (self.itemSize and 0 ~= self.itemSize.X and 0 ~= self.itemSize.Y and self.ScrollOffset) or not self.Col then
    return nil, nil
  end
  local AllRow = curPos.Y + self.ScrollOffset + dragItemSize.y / 2
  local AllCol = curPos.X + dragItemSize.x
  local clickCol = math.floor(AllCol / self.itemSize.X)
  local clickRow = math.floor(AllRow / self.itemSize.Y)
  if clickCol < 0 or clickCol > self.Col then
    return nil, nil, self.LineType.None
  end
  local maxNum = self.ScrollView:GetTotalItemNumber()
  local index = clickRow * self.Col + clickCol
  local lineType = self.LineType.FrontLine
  if clickCol == self.Col or maxNum == index then
    lineType = self.LineType.BehindLine
    index = index - 1
  elseif index - 1 >= 0 then
    local frontItem = self.ScrollView:GetItemByIndex(index - 1)
    if frontItem and frontItem.boxInfo and frontItem.boxInfo.box_id and frontItem.boxInfo.box_id == self.DragBoxInfo.box_id then
      return nil, nil, nil
    end
  end
  local item = self.ScrollView:GetItemByIndex(index)
  return item, index, lineType
end

function UMG_PetWarehouseOrganization_C:CheckBoxExchange()
  local item, _, _ = self:GetItemByDragItemPos()
  if self.DragBoxInfo and item then
    local dragBoxID, targetBoxID, bBehind
    if self.DragBoxInfo.box_id then
      dragBoxID = self.DragBoxInfo.box_id
    end
    if item.boxInfo and item.boxInfo.box_id then
      targetBoxID = item.boxInfo.box_id
      if item.curLineType == self.LineType.BehindLine then
        bBehind = true
      end
    end
    if dragBoxID and targetBoxID then
      _G.NRCAudioManager:PlaySound2DAuto(40002007, "UMG_PetWarehouseOrganization_C:CheckBoxExchange")
      self:ExchangeBox(dragBoxID, targetBoxID, bBehind)
    end
  end
  if self.curDragBoxIndex then
    local curDragBox = self.ItemList2:GetItemByIndex(self.curDragBoxIndex)
    if curDragBox then
      curDragBox:ReadyDragTo(false, self.LineType.None)
    end
  end
end

function UMG_PetWarehouseOrganization_C:ExchangeBox(dragBoxID, targetBoxID, bBehind)
  local dragBoxIndex, targetBoxIndex
  for i, value in ipairs(self.EditBoxList or {}) do
    if value == dragBoxID then
      dragBoxIndex = i
    end
    if value == targetBoxID then
      targetBoxIndex = i
    end
  end
  if dragBoxIndex == targetBoxIndex then
    return
  end
  local insertIndex
  if dragBoxIndex and targetBoxIndex then
    table.remove(self.EditBoxList, dragBoxIndex)
    if dragBoxIndex < targetBoxIndex then
      targetBoxIndex = targetBoxIndex - 1
    end
    insertIndex = targetBoxIndex
    if bBehind then
      insertIndex = targetBoxIndex + 1
    end
    table.insert(self.EditBoxList, insertIndex, dragBoxID)
  end
  self:UpdateEditBoxList(insertIndex)
end

function UMG_PetWarehouseOrganization_C:UpdateEditBoxList(insertIndex)
  local itemList = self.module:GetPetBoxDatas()
  local list = {}
  for _, box_id in pairs(self.EditBoxList or {}) do
    for _, v in pairs(itemList or {}) do
      if v and v.petBoxInfo and v.petBoxInfo.box_id and box_id == v.petBoxInfo.box_id then
        local item = {
          boxInfo = v,
          bEditItem = true,
          parent = self
        }
        table.insert(list, item)
      end
    end
  end
  self.ItemList2:InitList(list, true)
  if insertIndex and insertIndex - 1 >= 0 then
    local item = self.ItemList2:GetItemByIndex(insertIndex - 1)
    if item and item.Completion then
      item:PlayAnimation(item.Completion)
    end
  end
end

function UMG_PetWarehouseOrganization_C:CheckNeedToSaveNewList()
  local originalList = self:GetOriBoxList()
  for i, item in pairs(originalList or {}) do
    if item and self.EditBoxList and self.EditBoxList[i] and item ~= self.EditBoxList[i] then
      return true
    end
  end
  return false
end

function UMG_PetWarehouseOrganization_C:OnTimerUpdate()
  if self.offsetPerSec and self.ScrollView then
    local curOffset = self.ScrollView:GetScrollOffset()
    local maxOffset = self.ScrollView:GetScrollOffsetOfEnd()
    local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    local realOffset = self.offsetPerSec * scale
    if self.offsetPerSec > 0 then
      if maxOffset > curOffset + realOffset then
        self.ScrollView:NRCSetScrollOffset(curOffset + realOffset)
        self.bStopChoose = true
        self:OnStopChoose()
      else
        self.ScrollView:NRCSetScrollOffset(maxOffset)
        self.bStopChoose = false
      end
    elseif curOffset + realOffset > 0 then
      self.ScrollView:NRCSetScrollOffset(curOffset + realOffset)
      self.bStopChoose = true
      self:OnStopChoose()
    else
      self.ScrollView:NRCSetScrollOffset(0)
      self.bStopChoose = false
    end
  end
  self.ScrollOffset = self.ScrollView:GetScrollOffset()
  if self.ScrollOffset < 0 then
    self.ScrollOffset = 0
  end
end

function UMG_PetWarehouseOrganization_C:OnTimerComplete()
  self:ClearTimer()
end

function UMG_PetWarehouseOrganization_C:ClearTimer()
  if self.ScrollView then
    self.ScrollView:SetScrollBarForceVisible(false)
  end
  if self.ScrollTimer then
    _G.TimerManager:RemoveTimer(self.ScrollTimer)
    self.ScrollTimer = nil
  end
  self.bStopChoose = false
end

function UMG_PetWarehouseOrganization_C:GetWidgetPositionWithButtonOffset(position, scale)
  local BUTTON_OFFSET_X = self.ButtonOffsetX or 0
  if scale then
    BUTTON_OFFSET_X = BUTTON_OFFSET_X * scale
  end
  local targetPosition = UE4.FVector2D(position.X - BUTTON_OFFSET_X, position.Y)
  return targetPosition
end

function UMG_PetWarehouseOrganization_C:GetTipsDesc()
  local itemList = self.module:GetPetBoxDatas()
  for _, item in pairs(itemList or {}) do
    if item and item.petBoxInfo and item.petBoxInfo.mark_type ~= _G.Enum.WarehouseMarkType.WMT_DEFAULT then
      return LuaText.box_auto_arrange_tips_full
    end
  end
  return LuaText.box_auto_arrange_tips_lite
end

function UMG_PetWarehouseOrganization_C:HidePanel()
  self.bEnableFlag = false
  self:StopAnimation(self.In)
  self:StopAnimation(self.Out)
  self:PlayAnimation(self.Out)
end

function UMG_PetWarehouseOrganization_C:OnAnimationFinished(Anim)
  if not self.bEnableFlag then
    self:Disable()
  end
end

return UMG_PetWarehouseOrganization_C
