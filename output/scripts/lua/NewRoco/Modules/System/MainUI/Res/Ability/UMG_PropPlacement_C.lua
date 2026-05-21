local UMG_PropPlacement_C = _G.NRCPanelBase:Extend("UMG_PropPlacement_C")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")

function UMG_PropPlacement_C:OnConstruct()
  self:BindInputAction()
  self:OnAddEventListener()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnPropPlacementPanelOpen)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnFunctionBanChanged)
  self.pressedTime = 0
end

function UMG_PropPlacement_C:OnDestruct()
  if self.Player then
    if self.Player.playerToyComponent then
      self.Player.playerToyComponent:CancelPlacingProp()
    end
    self.Player:RemoveEventListener(self, PlayerModuleEvent.ON_FREE_PLACE_PROP_VALID_CHANGED, self.OnCanPlacePropStateChanged)
    self.Player = nil
  end
  self:RemoveAllButtonListener()
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnFunctionBanChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnPropPlacementSelectItem, self.SelectItem)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnClose)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.EnterSleepMode, self.OnClose)
  self:RemoveInputMappingContext("IMC_PropPlacement")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnPropPlacementPanelClose)
end

function UMG_PropPlacement_C:OnActive(npcId)
  self:InitData()
  self:InitUI()
  self:RefreshUIList(npcId)
end

function UMG_PropPlacement_C:InitData()
  self.rotationSpeedClick = (_G.DataConfigManager:GetGlobalConfig("prop_default_rotation") or {}).num or 45
  self.rotationSpeedLongPressed = (_G.DataConfigManager:GetGlobalConfig("prop_rotation_speed") or {}).num or 3
  self.Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.Player:AddEventListener(self, PlayerModuleEvent.ON_FREE_PLACE_PROP_VALID_CHANGED, self.OnCanPlacePropStateChanged)
  self.putPropsItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, RolePlayModuleDef.RolePlayType.PutProp)
  local itemNum = #self.putPropsItems
  local itemNumPerPage = self.ScrollPageController_1:GetItemNumPerPage()
  local lastPageItemNum = itemNum % itemNumPerPage
  if 0 ~= lastPageItemNum then
    local missingItemNum = itemNumPerPage - lastPageItemNum
    for i = 1, missingItemNum do
      table.insert(self.putPropsItems, {})
    end
  end
  self.curSelectPropId = -1
end

function UMG_PropPlacement_C:RefreshUIList(npcId)
  self.List:InitList(self.putPropsItems)
  local index = -1
  for i, v in pairs(self.putPropsItems) do
    if v.value == npcId then
      index = i
      break
    end
  end
  local curPage = 0
  if index >= 0 then
    self.List:SelectItemByIndex(index - 1)
    local pageItemNum = self.ScrollPageController_1:GetItemNumPerPage()
    curPage = math.ceil(index / pageItemNum)
  end
  self.ScrollPageController_1:SetValidItemTotalNum(#self.putPropsItems, curPage)
  self.ScrollPageController_1:ScrollToPage(curPage - 1)
end

function UMG_PropPlacement_C:InitUI()
  if self:IsPCMode() then
    self.NRCSwitcher1:SetActiveWidgetIndex(1)
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.PCKey:SetScrollMode()
    self.PCKey:SetKeyVisibility(true)
    self.AbilitySlot_Place.Text_PCKey:SetLeftClickMode()
    self.AbilitySlot_Place.Text_PCKey:SetKeyVisibility(true)
    self.CancelChargeBtn.ScrollPCKey_2:SetRightClickMode()
    self.CancelChargeBtn.ScrollPCKey_2:SetKeyVisibility(true)
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_PropPlacement_Rotation_Pressed")
    if "" ~= image then
      self.AbilitySlot_Rotation.Text_PCKey:SetImageMode(image)
    else
      self.AbilitySlot_Rotation.Text_PCKey:SetText(text)
    end
    self.AbilitySlot_Rotation.Text_PCKey:SetKeyVisibility(true)
  else
    self.NRCSwitcher1:SetActiveWidgetIndex(0)
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  end
  if self.putPropsItems and #self.putPropsItems > self.ScrollPageController_1:GetItemNumPerPage() then
    self.NRCSwitcher1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher1:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PropPlacement_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_PropPlacement_C:OnAddEventListener()
  if self:IsPCMode() then
    self.AbilitySlot_Place.UMG_Ability_Slot_Place.Btn_Slot.OnPressed:Add(self, self.OnPropPlaceBtnPressed)
    self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation.Btn_Slot.OnPressed:Add(self, self.OnPropRotationBtnPressed)
    self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation.Btn_Slot.OnReleased:Add(self, self.OnPropRotationBtnReleased)
    self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation.Btn_Slot.OnNxLongPressed:Add(self, self.OnPropRotationBtnLongPressed)
    self:AddButtonListener(self.AbilitySlot_Place.UMG_Ability_Slot_Place.Btn_Slot, self.OnPropPlaceBtnClicked)
    self:AddButtonListener(self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation.Btn_Slot, self.OnPropRotationBtnClicked)
    self:AddButtonListener(self.CancelChargeBtn.CancelChargeBtn, self.OnCancelPlaceBtnClicked)
  else
    self.Ability_Slot_Place.Btn_Slot.OnPressed:Add(self, self.OnPropPlaceBtnPressed)
    self.Ability_Slot_Rotation.Btn_Slot.OnPressed:Add(self, self.OnPropRotationBtnPressed)
    self.Ability_Slot_Rotation.Btn_Slot.OnReleased:Add(self, self.OnPropRotationBtnReleased)
    self.Ability_Slot_Rotation.Btn_Slot.OnNxLongPressed:Add(self, self.OnPropRotationBtnLongPressed)
    self:AddButtonListener(self.Ability_Slot_Place.Btn_Slot, self.OnPropPlaceBtnClicked)
    self:AddButtonListener(self.Ability_Slot_Rotation.Btn_Slot, self.OnPropRotationBtnClicked)
    self:AddButtonListener(self.CancelPlaceBtn, self.OnCancelPlaceBtnClicked)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_PropPlacement_C", self, MainUIModuleEvent.OnPropPlacementSelectItem, self.SelectItem)
  _G.NRCEventCenter:RegisterEvent("UMG_PropPlacement_C", self, MainUIModuleEvent.MAINUICLOSE, self.OnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_PropPlacement_C", self, SystemSettingModuleEvent.EnterSleepMode, self.OnClose)
end

function UMG_PropPlacement_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_PropPlacement")
  if mappingContext then
    local actions = {
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
      },
      {
        name = "IA_SelectItem_6",
        method = "SelectItem6"
      },
      {
        name = "IA_PreviousTab_PropPlacement",
        method = "PreviousTab"
      },
      {
        name = "IA_NextTab_PropPlacement",
        method = "NextTab"
      },
      {
        name = "IA_PropPlacement_Place",
        method = "OnPropPlaceBtnClicked"
      },
      {
        name = "IA_PropPlacement_CancelPlace",
        method = "OnCancelPlaceBtnClicked"
      },
      {
        name = "IA_PropPlacement_Rotation_Pressed",
        method = "OnPropRotationBtnPressed"
      },
      {
        name = "IA_PropPlacement_Rotation_Released",
        method = "OnPropRotationBtnReleased"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
  else
    Log.Error("IMC_PropPlacement  is nil")
  end
end

function UMG_PropPlacement_C:PreviousTab()
  if self.ScrollPageController_1:IsScrolling() then
    return
  end
  local curPage = self.ScrollPageController_1:GetCurrentPage()
  local pageNum = self.ScrollPageController_1:GetTotalPageNum()
  if pageNum <= 1 then
    return
  end
  if curPage > 0 then
    self.ScrollPageController_1:ScrollToPage(curPage - 1)
  end
end

function UMG_PropPlacement_C:NextTab()
  if self.ScrollPageController_1:IsScrolling() then
    return
  end
  local curPage = self.ScrollPageController_1:GetCurrentPage()
  local pageNum = self.ScrollPageController_1:GetTotalPageNum()
  if pageNum <= 1 then
    return
  end
  if pageNum > curPage + 1 then
    self.ScrollPageController_1:ScrollToPage(curPage + 1)
  end
end

function UMG_PropPlacement_C:SelectItem1()
  self:SelectItem(1)
end

function UMG_PropPlacement_C:SelectItem2()
  self:SelectItem(2)
end

function UMG_PropPlacement_C:SelectItem3()
  self:SelectItem(3)
end

function UMG_PropPlacement_C:SelectItem4()
  self:SelectItem(4)
end

function UMG_PropPlacement_C:SelectItem5()
  self:SelectItem(5)
end

function UMG_PropPlacement_C:SelectItem6()
  self:SelectItem(6)
end

function UMG_PropPlacement_C:SelectItem(index)
  local curPage = self.ScrollPageController_1:GetCurrentPage()
  index = index + curPage * self.ScrollPageController_1:GetItemNumPerPage()
  local newIndex = index - 1
  local item = self.List:GetItemByIndex(newIndex)
  if item and item:IsValidItem() then
    local itemData = item.data
    if itemData and itemData.value ~= self.curSelectPropId then
      self:OnCanPlacePropStateChanged(false, true)
      if not item.bSelected then
        self.List:SelectItemByIndex(newIndex)
      end
      local propId = itemData.value or 0
      local conf = _G.DataConfigManager:GetRoleplayPropConf(propId)
      if conf then
        self.Ability_Slot_Place.PropPlaceIcon:SetPath(conf.icon_path)
        self.AbilitySlot_Place.UMG_Ability_Slot_Place.PropPlaceIcon:SetPath(conf.icon_path)
      end
      local Player = self.Player
      if Player and Player.playerToyComponent then
        Player.playerToyComponent:SwitchCurrentPlacingProp(itemData.value)
      end
      self.curSelectPropId = itemData.value
    end
  end
end

function UMG_PropPlacement_C:OnCancelPlaceBtnClicked()
  local Player = self.Player
  if Player and Player.playerToyComponent then
    Player.playerToyComponent:CancelPlacingProp()
  end
  self:DoClose()
end

function UMG_PropPlacement_C:OnPropPlaceBtnPressed()
  if self.curCanPlace then
    self.Ability_Slot_Place:PlayAnimation(self.Ability_Slot_Place.press)
  end
end

function UMG_PropPlacement_C:OnPropPlaceBtnClicked()
  if self:IsPCMode() then
    self.AbilitySlot_Place.UMG_Ability_Slot_Place:PlayAnimation(self.AbilitySlot_Place.UMG_Ability_Slot_Place.press)
  end
  local Player = self.Player
  if Player and Player.playerToyComponent then
    local bSuccess = Player.playerToyComponent:ConfirmPlacingProp()
    if bSuccess then
      local curTime = _G.ZoneServer:GetServerTime() / 1000
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.RefreshNextPutPropTime, curTime)
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.SetInPutPropNpcId, self.curSelectPropId)
      self:DoClose()
    end
  end
end

function UMG_PropPlacement_C:OnPropRotationBtnPressed()
  self.bInRotationBtnPressed = true
  if self:IsPCMode() then
    self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation:PlayAnimation(self.AbilitySlot_Rotation.UMG_Ability_Slot_Rotation.press)
    self.pressedTime = 0
  else
    self.Ability_Slot_Rotation:PlayAnimation(self.Ability_Slot_Rotation.press)
  end
end

function UMG_PropPlacement_C:OnPropRotationBtnClicked()
  if self.skipClickRotation then
    self.skipClickRotation = false
  else
    self:RotationProp(self.rotationSpeedClick)
  end
end

function UMG_PropPlacement_C:OnPropRotationBtnLongPressed()
  self.bStarRotation = true
end

function UMG_PropPlacement_C:OnPropRotationBtnReleased()
  self.bInRotationBtnPressed = false
  if self:IsPCMode() then
    if self.bStarRotation then
      self.bStarRotation = false
    else
      self:RotationProp(self.rotationSpeedClick)
    end
  else
    if self.bStarRotation then
      self.skipClickRotation = true
    end
    self.bStarRotation = false
  end
end

function UMG_PropPlacement_C:OnTick(time)
  if self.bInRotationBtnPressed then
    if self.bStarRotation then
      self:RotationProp(self.rotationSpeedLongPressed)
    elseif self:IsPCMode() then
      self.pressedTime = self.pressedTime + time
      if self.pressedTime > 0.5 then
        self.bStarRotation = true
      end
    end
  end
end

function UMG_PropPlacement_C:RotationProp(delta)
  local Player = self.Player
  if Player and Player.playerToyComponent then
    Player.playerToyComponent:AddPlacingPropRotation(delta)
  end
end

function UMG_PropPlacement_C:OnCanPlacePropStateChanged(_canPlace, bNotLoad)
  self.curCanPlace = _canPlace
  self.bNotLoad = bNotLoad
  local opacity = _canPlace and 1 or 0.4
  if self:IsPCMode() then
    self.AbilitySlot_Place.UMG_Ability_Slot_Place.Image_Icon:SetRenderOpacity(opacity)
  else
    self.Ability_Slot_Place.Image_Icon:SetRenderOpacity(opacity)
  end
end

function UMG_PropPlacement_C:OnFunctionBanChanged(isBan)
  if isBan then
    self:DoClose()
  end
end

return UMG_PropPlacement_C
