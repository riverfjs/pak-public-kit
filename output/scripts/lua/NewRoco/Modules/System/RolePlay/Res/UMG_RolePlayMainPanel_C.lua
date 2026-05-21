local UMG_RolePlayMainPanel_C = _G.NRCPanelBase:Extend("UMG_RolePlayMainPanel_C")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local RolePlayModuleEvent = require("NewRoco.Modules.System.RolePlay.RolePlayModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TouchEmptyHide = require("NewRoco.Modules.System.Home.Res.Helpers.TouchEmptyHide")

function UMG_RolePlayMainPanel_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("TipsDisplayCoordinator", self, MainUIModuleEvent.MAINUICLOSE, self.OnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_RolePlayMainPanel_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  self:RegisterEvent(self, RolePlayModuleEvent.GetNewRolePlay, self.OnGetNewRolePlay)
  self:RegisterEvent(self, RolePlayModuleEvent.OnPreBeginPopupPoseSelectPanel, self.OnPreBeginPopupPoseSelectPanel)
  self:RegisterEvent(self, RolePlayModuleEvent.OnBeginPopupPoseSelectPanel, self.OnBeginPopupPoseSelectPanel)
  self:RegisterEvent(self, RolePlayModuleEvent.OnEndPopupPoseSelectPanel, self.OnEndPopupPoseSelectPanel)
  self:RegisterEvent(self, RolePlayModuleEvent.OnRefreshRoleplayGroupSelection, self.OnRefreshRoleplayGroupSelection)
  self.TouchEmptyHideActionSelectPanel = TouchEmptyHide(self)
  self.TouchEmptyHideActionSelectPanel:Bind()
  self.TouchEmptyHideActionSelectPanel.OnTouchEmpty:Add(self, self.OnTouchEmptyCloseActionSelectPanel)
  self:SetChildViews(self.RolePlayPoseLevel)
  self:AddButtonListener(self.CloseBtn, self.OnBtnClickClose)
  self:OnInitBehaviourButtons()
  self:BindInputAction()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  self.curRolePlayType = nil
  self.cachedRolePlayItems = {}
  self.cachedRolePlayValidItems = {}
  self.fashionRelaxData = {}
  self.ScrollPageController:SetPageChangeHandler(self.OnPageChangeHandle, self)
  self:PCKeySetting()
  self.FKey:SetScrollMode()
  self.FKey:SetKeyVisibility(true)
  _G.NRCEventCenter:DispatchEvent(RolePlayModuleEvent.RolePlayMainPanelOpen)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnFunctionBanChanged)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PROP, self, self.OnFurnitureBanChanged)
  self.ScrollPageController:InitEnableLongPressEvent()
end

function UMG_RolePlayMainPanel_C:OnBehaviourTabBtnClicked(Type)
  return self:CallTabFunction(Type)
end

function UMG_RolePlayMainPanel_C:OnTouchEmptyCloseActionSelectPanel()
  self:HideRolePlayPoseLevelPanel()
end

function UMG_RolePlayMainPanel_C:HideRolePlayPoseLevelPanel()
  if self.RolePlayPoseLevel:IsVisible() then
    _G.NRCAudioManager:PlaySound2DAuto(40008004, "UMG_RolePlayMainPanel_C:HideRolePlayPoseLevelPanel")
    self.RolePlayPoseLevel:Hide()
    self.ScrollPageController:SetCanScroll(true)
    if not self:IsAnimationPlaying(self.Tabs_Show) then
      self:PlayAnimation(self.Tabs_Show)
    end
  end
end

function UMG_RolePlayMainPanel_C:OnTouchActionSelectPanel()
  self.TouchEmptyHideActionSelectPanel:NotifyTouched()
end

function UMG_RolePlayMainPanel_C:OnEndPopupPoseSelectPanel()
  self.TouchEmptyHideActionSelectPanel:NotifyTouched()
end

function UMG_RolePlayMainPanel_C:OnPreBeginPopupPoseSelectPanel(bSelected)
  if not bSelected then
    self.RolePlayPoseLevel:Hide()
  end
end

function UMG_RolePlayMainPanel_C:OnBeginPopupPoseSelectPanel(Data, Index)
  Log.Debug("UMG_RolePlayMainPanel_C:ReqPopupPoseSelectPanel", Data, Index)
  if not Data then
    return
  end
  local RoleplayConf = _G.DataConfigManager:GetRoleplayBehaviorConf(Data.value, true)
  if not RoleplayConf then
    return
  end
  local Group = _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.GetGroupByRoleplayConf, RoleplayConf)
  if not Group then
    return
  end
  local Offset = (Index - 1) % 5
  Offset = Offset * 155 - 45
  local RolePlayPoseLevelSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.RolePlayPoseLevel)
  local Offsets = RolePlayPoseLevelSlot:GetOffsets()
  Offsets.Left = Offset
  RolePlayPoseLevelSlot:SetOffsets(Offsets)
  local Items = {}
  local LockedConfList = {}
  for i, v in ipairs(Group) do
    local Item = self.AllRolePlayActionTypes[v.RPbehavior_type]
    if Item then
      table.insert(Items, Item)
    else
      table.insert(LockedConfList, v)
    end
  end
  table.sort(Items, function(a, b)
    if a.value == b.value then
      return a.value == Data.value
    elseif a.value == Data.value then
      return true
    elseif b.value == Data.value then
      return false
    else
      return a.value < b.value
    end
  end)
  for i, LockedConf in ipairs(LockedConfList) do
    local Item = _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.CreateLockedRoleplayAction, LockedConf)
    table.insert(Items, Item)
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008003, "UMG_RolePlayMainPanel_C:HideRolePlayPoseLevelPanel")
  self.RolePlayPoseLevel:Show(Items)
  self.ScrollPageController:SetCanScroll(false)
  self.TouchEmptyHideActionSelectPanel:NotifyTouched()
  self:PlayAnimation(self.Tabs_Hidden)
end

function UMG_RolePlayMainPanel_C:CallTabFunction(Type)
  local btnData = self.rolePlayTypeBtn[Type]
  if not btnData then
    self:LogError("logical error!!!", Type)
    return
  end
  if not btnData.btn:IsVisible() then
    self:LogWarning("invisible behaviour tab button", Type)
    return
  end
  local Method = self.TabButtonTabFunc[Type]
  if Method then
    Method(self)
  else
    self:LogError("logical error!!! cannot found method of", Type)
  end
end

function UMG_RolePlayMainPanel_C:OnInitBehaviourButtons()
  if self.InteractiveActionBtn then
    self.InteractiveActionBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.SoundBtn then
    self.SoundBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.TabButtonList = {
    self.ActionBtn,
    self.SuitBtn,
    self.FurnitureBtn
  }
  self.TabButtonTabFunc = {
    [RolePlayModuleDef.RolePlayType.Action] = self.OnBtnShowActions,
    [RolePlayModuleDef.RolePlayType.Suit] = self.OnBtnShowSuits,
    [RolePlayModuleDef.RolePlayType.PutProp] = self.OnBtnShowFurniture
  }
  do
    local function BuildRolePlayBtnData(_btn, _btype, index, _normalIcon, _selectedIcon, _disableIcon, _nextbtype, _prevbtype)
      local btnData = {}
      
      btnData.btn = _btn
      btnData.btype = _btype
      btnData.index = index
      btnData.normalIcon = _normalIcon
      btnData.selectedIcon = _selectedIcon
      btnData.disableIcon = _disableIcon
      
      function btnData.onClicked()
        self:OnBehaviourTabBtnClicked(_btype)
      end
      
      btnData.nextbtype = _nextbtype
      btnData.prevbtype = _prevbtype
      return btnData
    end
    
    self.rolePlayTypeBtn = {}
    local ButtonSortConfList = {}
    local ROLEPLAY_SORT_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ROLEPLAY_SORT_CONF):GetAllDatas()
    for i, v in pairs(ROLEPLAY_SORT_CONF) do
      table.insert(ButtonSortConfList, v)
    end
    table.sort(ButtonSortConfList, function(a, b)
      return a.id < b.id
    end)
    self.ButtonSortConfList = ButtonSortConfList
    local NextType = 0
    local PrevType = 0
    for i, ButtonSortConf in ipairs(ButtonSortConfList) do
      local Enum = ButtonSortConf.behavior_type
      local Btn = self.TabButtonList[i]
      if Btn then
        local RolePlayType = RolePlayModuleDef.GetRolePlayTypeByEnum(Enum)
        if RolePlayType then
          local NextIdx = i == #ButtonSortConfList and 1 or i + 1
          NextType = RolePlayModuleDef.GetRolePlayTypeByEnum(ButtonSortConfList[NextIdx].behavior_type)
          local PrevIdx = 1 == i and #ButtonSortConfList or i - 1
          PrevType = RolePlayModuleDef.GetRolePlayTypeByEnum(ButtonSortConfList[PrevIdx].behavior_type)
          local Data = BuildRolePlayBtnData(Btn, RolePlayType, i, ButtonSortConf.tab_icon1, ButtonSortConf.tab_icon2, ButtonSortConf.tab_icon3, NextType, PrevType)
          self.rolePlayTypeBtn[RolePlayType] = Data
          self:AddButtonListener(Btn.btnLevelUp, Data.onClicked)
        else
          Log.Error("Logical Error!!! cannot found role play type by enum", Enum)
        end
      else
        Log.Error("Logical Error!!! cannot found btn by enum", Enum)
      end
    end
    for _rolePlayType, _btnData in pairs(self.rolePlayTypeBtn) do
      local _btn = _btnData.btn
      _btn:SetIcon(_btnData.normalIcon, _btnData.selectedIcon, _btnData.disableIcon)
      if not self:CheckBtnIsVisible(_rolePlayType) then
        self:SetBtnStatus(_rolePlayType, RolePlayModuleDef.RolePlayBtnState.Hide)
      elseif self:CheckBtnIsDisable(_rolePlayType) then
        self:SetBtnStatus(_rolePlayType, RolePlayModuleDef.RolePlayBtnState.Disabled)
      else
        self:SetBtnStatus(_rolePlayType, RolePlayModuleDef.RolePlayBtnState.Normal)
      end
    end
  end
end

function UMG_RolePlayMainPanel_C:OnFunctionBanChanged(isBan)
  if isBan then
    self:DoClose()
  end
end

function UMG_RolePlayMainPanel_C:OnFurnitureBanChanged(isBan)
  local thisType = RolePlayModuleDef.RolePlayType.PutProp
  local isCurSelectType = self.curRolePlayType == thisType
  if isBan then
    self:SetBtnStatus(thisType, RolePlayModuleDef.RolePlayBtnState.Disabled)
  else
    self:SetBtnStatus(thisType, isCurSelectType and RolePlayModuleDef.RolePlayBtnState.Selected or RolePlayModuleDef.RolePlayBtnState.Normal)
  end
  if isCurSelectType then
    self:SwitchTab(thisType)
  end
end

function UMG_RolePlayMainPanel_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnClose)
  self:UnRegisterEvent(self, RolePlayModuleEvent.GetNewRolePlay)
  _G.NRCEventCenter:DispatchEvent(RolePlayModuleEvent.RolePlayMainPanelClosed)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnFunctionBanChanged)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PROP, self, self.OnFurnitureBanChanged)
  if self.TouchEmptyHideActionSelectPanel then
    self.TouchEmptyHideActionSelectPanel:UnBind()
  end
end

function UMG_RolePlayMainPanel_C:OnActive(_rolePlayType)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.ROLE_PLAY_PANEL_OPEN)
  _G.NRCAudioManager:PlaySound2DAuto(40008002, "UMG_RolePlayMainPanel_C:OnActive")
  self:SwitchTab(_rolePlayType or RolePlayModuleDef.RolePlayType.Action)
  self.RolePlayPoseLevel.OnPanelTouched:Clear()
  self.RolePlayPoseLevel.OnPanelTouched:Add(self, self.OnTouchActionSelectPanel)
end

function UMG_RolePlayMainPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_Fashion")
  if mappingContext then
    local actions = {
      {
        name = "IA_FashionExit",
        method = "CloseUI"
      },
      {
        name = "IA_NextPage",
        method = "NextPage"
      },
      {
        name = "IA_PreviousTab",
        method = "PreviousTab"
      },
      {name = "IA_NextTab", method = "NextTab"},
      {
        name = "IA_SelectItem_1",
        method = "SelectItem1"
      },
      {
        name = "IA_SelectItem_2",
        method = "SelectItem2"
      },
      {
        name = "IA_SelectItem_3",
        method = "SelectItem3"
      },
      {
        name = "IA_SelectItem_4",
        method = "SelectItem4"
      },
      {
        name = "IA_SelectItem_5",
        method = "SelectItem5"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
    mappingContext:BindAction("IA_PgChangeScene")
    mappingContext:BindAction("IA_ChangeWalkRun")
  else
    Log.Error("IMC_Fashion  is nil")
  end
end

function UMG_RolePlayMainPanel_C:PCKeySetting()
  if SystemSettingModuleCmd and self.PCKey then
    self.PCKey:SetKeyVisibility(true)
    self.PCKey:SetText("Tab")
  end
  if self.PCKey_1 then
    self.PCKey_1:SetKeyVisibility(true)
    self.PCKey_1:SetText("Esc")
  end
end

function UMG_RolePlayMainPanel_C:CloseUI()
  self:OnBtnClickClose()
end

function UMG_RolePlayMainPanel_C:NextPage()
  if self.ScrollPageController:IsScrolling() then
    return
  end
  local curPage = self.ScrollPageController:GetCurrentPage()
  local pageNum = self.ScrollPageController:GetTotalPageNum()
  if not curPage or not pageNum then
    return
  end
  if pageNum <= 1 then
    return
  end
  if curPage + 1 == pageNum then
    self.ScrollPageController:ScrollToPage(0)
  else
    self.ScrollPageController:ScrollToPage(curPage + 1)
  end
end

function UMG_RolePlayMainPanel_C:PreviousTab(a)
  local RolePlayType = self.curRolePlayType
  for i = 1, #self.TabButtonList do
    RolePlayType = self.rolePlayTypeBtn[RolePlayType].prevbtype
    local Status = self:GetBtnStatus(RolePlayType)
    if Status ~= RolePlayModuleDef.RolePlayBtnState.Disabled and Status ~= RolePlayModuleDef.RolePlayBtnState.Hide then
      break
    end
  end
  self:CallTabFunction(RolePlayType)
end

function UMG_RolePlayMainPanel_C:NextTab()
  local RolePlayType = self.curRolePlayType
  for i = 1, #self.TabButtonList do
    RolePlayType = self.rolePlayTypeBtn[RolePlayType].nextbtype
    local Status = self:GetBtnStatus(RolePlayType)
    if Status ~= RolePlayModuleDef.RolePlayBtnState.Disabled and Status ~= RolePlayModuleDef.RolePlayBtnState.Hide then
      break
    end
  end
  self:CallTabFunction(RolePlayType)
end

function UMG_RolePlayMainPanel_C:SelectItem1()
  self:SelectItem(1)
end

function UMG_RolePlayMainPanel_C:SelectItem2()
  self:SelectItem(2)
end

function UMG_RolePlayMainPanel_C:SelectItem3()
  self:SelectItem(3)
end

function UMG_RolePlayMainPanel_C:SelectItem4()
  self:SelectItem(4)
end

function UMG_RolePlayMainPanel_C:SelectItem5()
  self:SelectItem(5)
end

function UMG_RolePlayMainPanel_C:SelectItem(index)
  local curPage = self.ScrollPageController:GetCurrentPage()
  if not curPage then
    return
  end
  index = index + curPage * 5
  local itemData = self.ItemList:GetItemByIndex(index - 1)
  if itemData and itemData.data and next(itemData.data) then
    if not self.ItemList:OpItemByIndex(index, "IsCanSelect") then
      return
    end
    self.ItemList:SelectItemByIndex(index - 1)
  end
end

function UMG_RolePlayMainPanel_C:CheckBtnIsVisible(_rolePlayType)
  if _rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
    return false
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
    local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RP_DRESSUP)
    return not isHide
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    local rolePlayItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, _rolePlayType)
    if not rolePlayItems or 0 == #rolePlayItems then
      return false
    end
  end
  return true
end

function UMG_RolePlayMainPanel_C:CheckBtnIsDisable(_rolePlayType)
  if _rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_PROP, false, false)
    return Ban
  end
  return false
end

function UMG_RolePlayMainPanel_C:SetBtnStatus(_rolePlayType, _state)
  if not _rolePlayType then
    return
  end
  local btnData = self.rolePlayTypeBtn[_rolePlayType]
  if btnData then
    btnData.btn:SetBtnState(_state)
    self:RefreshBtnConnectionLine()
  end
end

function UMG_RolePlayMainPanel_C:GetBtnStatus(_rolePlayType)
  if not _rolePlayType then
    return nil
  end
  local btnData = self.rolePlayTypeBtn[_rolePlayType]
  if btnData then
    return btnData.btn:GetBtnState()
  end
  return nil
end

function UMG_RolePlayMainPanel_C:RefreshBtnConnectionLine()
  local furnitureBtnState = self:GetBtnStatus(RolePlayModuleDef.RolePlayType.PutProp)
  local suitBtnState = self:GetBtnStatus(RolePlayModuleDef.RolePlayType.Suit)
  local rightLineShow = furnitureBtnState and furnitureBtnState ~= RolePlayModuleDef.RolePlayBtnState.Hide and suitBtnState and suitBtnState ~= RolePlayModuleDef.RolePlayBtnState.Hide
  self.NRCImage:SetVisibility(rightLineShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_RolePlayMainPanel_C:OnRefreshRoleplayGroupSelection(RpType)
  self.cachedRolePlayItems[RolePlayModuleDef.RolePlayType.Action] = nil
  if self.curRolePlayType == RolePlayModuleDef.RolePlayType.Action then
    local rolePlayItems = self:GetRolePlayItems(self.curRolePlayType)
    local desiredIndex
    for i, v in pairs(rolePlayItems) do
      if v.rpType == RpType then
        desiredIndex = i
        break
      end
    end
    if nil ~= desiredIndex then
      local ItemView = self.ItemList:GetItemByIndex(desiredIndex - 1)
      if ItemView then
        ItemView:RefreshByRoleplaySelectReplace(rolePlayItems[desiredIndex])
      else
        self.ItemList:UpdateList(rolePlayItems, -1)
      end
    else
      self.ItemList:UpdateList(rolePlayItems, -1)
    end
    self:HideRolePlayPoseLevelPanel()
  end
end

function UMG_RolePlayMainPanel_C:GetRolePlayItems(_rolePlayType)
  local rolePlayItems = self.cachedRolePlayItems[_rolePlayType]
  if not rolePlayItems or self.curRolePlayType == RolePlayModuleDef.RolePlayType.Suit or self.curRolePlayType == RolePlayModuleDef.RolePlayType.Interactive or self.curRolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    if self.curRolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
      rolePlayItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, _rolePlayType, self.fashionRelaxData)
    else
      rolePlayItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, _rolePlayType)
      if _rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
        local indexToRemove = {}
        for k, v in ipairs(rolePlayItems) do
          if v.suitType == "allCollect" then
            table.insert(indexToRemove, k)
          end
        end
        table.sort(indexToRemove)
        for i = #indexToRemove, 1, -1 do
          local idx = indexToRemove[i]
          table.remove(rolePlayItems, idx)
        end
      end
      if _rolePlayType == RolePlayModuleDef.RolePlayType.Action then
        self.AllRolePlayActionTypes = {}
        for k, v in pairs(rolePlayItems) do
          if "table" == type(v) then
            self.AllRolePlayActionTypes[v.rpType] = v
          end
        end
        local DisplayTypeMap = _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.GetDisplayRolePlayMap)
        for i = #rolePlayItems, 1, -1 do
          local Item = rolePlayItems[i]
          if "table" == type(Item) then
            local Conf = _G.DataConfigManager:GetRoleplayBehaviorConf(Item.value)
            if not DisplayTypeMap[Conf.RPbehavior_type] then
              table.remove(rolePlayItems, i)
            end
          end
        end
      end
    end
    self.cachedRolePlayValidItems[_rolePlayType] = #rolePlayItems
    local itemNum = #rolePlayItems
    local itemNumPerPage = self.ScrollPageController:GetItemNumPerPage()
    local lastPageItemNum = itemNum % itemNumPerPage
    if 0 ~= lastPageItemNum then
      local missingItemNum = itemNumPerPage - lastPageItemNum
      for i = 1, missingItemNum do
        table.insert(rolePlayItems, {})
      end
    end
    self.cachedRolePlayItems[_rolePlayType] = rolePlayItems
  end
  return rolePlayItems
end

function UMG_RolePlayMainPanel_C:SwitchTab(_rolePlayType)
  local btnStatus = self:GetBtnStatus(_rolePlayType)
  if btnStatus == RolePlayModuleDef.RolePlayBtnState.Hide then
    if self.curRolePlayType == nil then
      self.ItemList:ClearSelection()
      self.ItemList:InitList({})
      self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    return
  end
  if self:IsAnimationPlaying(self.Tabs_Hidden) then
    return
  end
  local isDisable = self:CheckBtnIsDisable(_rolePlayType)
  if isDisable then
    self.Panel_ItemList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  else
    self.Panel_ItemList:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if _rolePlayType == RolePlayModuleDef.RolePlayType.Action then
    _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_ANIMATION)
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
    _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOTH)
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Sound then
    _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_BARKING)
  end
  local preRolePlayType = self.curRolePlayType
  self.curRolePlayType = _rolePlayType
  if _rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
    self.hasSwitchToWardrobe = true
  end
  local changeTab = preRolePlayType ~= _rolePlayType
  local lastTabBtnState = self:GetBtnStatus(preRolePlayType)
  if changeTab then
    if lastTabBtnState ~= RolePlayModuleDef.RolePlayBtnState.Disabled then
      self:SetBtnStatus(preRolePlayType, lastTabBtnState == RolePlayModuleDef.RolePlayBtnState.Selected and RolePlayModuleDef.RolePlayBtnState.Normal or lastTabBtnState)
    end
    self:SetBtnStatus(self.curRolePlayType, RolePlayModuleDef.RolePlayBtnState.Selected)
  end
  if preRolePlayType == RolePlayModuleDef.RolePlayType.Suit and self.curRolePlayType ~= RolePlayModuleDef.RolePlayType.Suit then
    self:EraseWardrobeRedPoint()
  end
  local rolePlayItems = self:GetRolePlayItems(_rolePlayType)
  self.ItemList:ClearSelection()
  self.ItemList:InitList(rolePlayItems)
  local index = 0
  for k, v in ipairs(rolePlayItems) do
    if v.bSelected then
      index = k
      break
    end
  end
  if 0 ~= index then
    self.ItemList:SelectItemByIndex(index - 1)
  end
  local curPage = 0
  if _rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    curPage = self.ScrollPageController:GetCurrentPage()
  end
  self.ScrollPageController:SetValidItemTotalNum(self.cachedRolePlayValidItems[_rolePlayType], curPage)
  self.ScrollPageController:ScrollToPage(curPage, 0.1)
  local pageNum = self.ScrollPageController:GetTotalPageNum()
  if pageNum > 1 then
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local pageData = {}
    for i = 1, pageNum do
      table.insert(pageData, i)
    end
    self.Dot_List:ClearSelection()
    self.Dot_List:InitGridView(pageData)
    self.Dot_List:SelectItemByIndex(0)
  else
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RolePlayMainPanel_C:RefreshTabData(_data)
  if not _data then
    self:LogError("RefreshTabData: _tab and _data should not be nil!")
    return
  end
  local _tab = _data.type
  self.cachedRolePlayItems[_tab] = nil
  if self.curRolePlayType == _tab then
    self:SwitchTab(_tab)
  end
end

function UMG_RolePlayMainPanel_C:OnPageChangeHandle(_page)
  self.Dot_List:SelectItemByIndex(_page)
end

function UMG_RolePlayMainPanel_C:OnGetNewRolePlay(_data)
  local itemConf = {}
  if _data then
    if _data.behavior_type == Enum.BehaviorType.BT_CALL then
      itemConf.type = RolePlayModuleDef.RolePlayType.Sound
    elseif _data.behavior_type == Enum.BehaviorType.BT_PROP then
      itemConf.type = RolePlayModuleDef.RolePlayType.PutProp
    else
      itemConf.type = RolePlayModuleDef.RolePlayType.Action
    end
    itemConf.value = _data.id
    self:RefreshTabData(itemConf)
  end
end

function UMG_RolePlayMainPanel_C:OnBtnShowActions()
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_RolePlayMainPanel_C:OnBtnShowActions")
  self:SwitchTab(RolePlayModuleDef.RolePlayType.Action)
end

function UMG_RolePlayMainPanel_C:OnBtnShowSounds()
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_RolePlayMainPanel_C:OnBtnShowSounds")
  self:SwitchTab(RolePlayModuleDef.RolePlayType.Sound)
end

function UMG_RolePlayMainPanel_C:OnBtnShowSuits()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_RP_DRESSUP, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_RolePlayMainPanel_C:OnBtnShowSuits")
  self:SwitchTab(RolePlayModuleDef.RolePlayType.Suit)
end

function UMG_RolePlayMainPanel_C:OnBtnShowInteractive()
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_RolePlayMainPanel_C:OnBtnShowInteractive")
  self:SwitchTab(RolePlayModuleDef.RolePlayType.Interactive)
end

function UMG_RolePlayMainPanel_C:OnBtnShowFurniture()
  local isBan = self:CheckBtnIsDisable(RolePlayModuleDef.RolePlayType.PutProp)
  if isBan then
    local MagicAlive = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetMagicAlive)
    if MagicAlive then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.mark_video_toys_ban)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_ban)
    end
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_RolePlayMainPanel_C:OnBtnShowFurniture")
  self:SwitchTab(RolePlayModuleDef.RolePlayType.PutProp)
end

function UMG_RolePlayMainPanel_C:OnBtnClickClose()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_RolePlayMainPanel_C:OnBtnClickClose")
  self:EraseWardrobeRedPoint()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.ROLE_PLAY_PANEL_CLOSE)
  self:OnClose()
end

function UMG_RolePlayMainPanel_C:EraseWardrobeRedPoint()
  if not self.hasSwitchToWardrobe then
    return
  end
  _G.NRCEventCenter:DispatchEvent(RolePlayModuleEvent.ItemEraseRedPoint)
end

return UMG_RolePlayMainPanel_C
