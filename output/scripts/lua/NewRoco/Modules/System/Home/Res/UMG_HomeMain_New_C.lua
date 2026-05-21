local UMG_HomeMain_New_C = _G.NRCPanelBase:Extend("UMG_HomeMain_New_C")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local HomeStats = require("NewRoco/Modules/System/Home/Res/Helpers/HomeStats")
local FurnitureList = require("NewRoco/Modules/System/Home/Res/Helpers/FurnitureList")
local FurnitureManager = require("NewRoco/Modules/System/Home/Res/Helpers/FurnitureManager")
local FurnitureTouchPlace = require("NewRoco/Modules/System/Home/Res/Helpers/FurnitureTouchPlace")

function UMG_HomeMain_New_C:OnConstruct()
  self.FurnitureListHelper = FurnitureList(self)
  self.FurnitureManagerHelper = FurnitureManager(self)
  self.FurnitureTouchPlace = FurnitureTouchPlace(self)
  self.Mode = nil
  self.bGroundView = true
  self.bTicking = false
  self.TickFlags = 0
  self.HomeStats = HomeStats()
  self.HomeStats:BindComfortValView(self.SumNum)
  self.HomeStats:BindRoomNameView(self.RoomName)
  self.HomeStats:BindAddComfortValView(self.SumNum_1)
  self:OnAddEventListener()
  self:Init()
  if self.NRCText_82 then
    self.NRCText_82:SetText(LuaText.furniture_list_empty)
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, false)
end

function UMG_HomeMain_New_C:OnDestruct()
  self.FurnitureListHelper:Release()
  self.FurnitureListHelper = nil
  self.FurnitureManagerHelper:Release()
  self.FurnitureManagerHelper = nil
end

function UMG_HomeMain_New_C:OnActive()
  self:BindInputAction()
  if self:IsPCMode() then
    self.CanvasPCKey:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PCKeySetting()
  else
    self.CanvasPCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  HomeIndoorSandbox.World.Controller:AttachPanelForControl(self)
  self.Perspective:SetText(LuaText.furniture_over_view)
end

function UMG_HomeMain_New_C:EnsureGetHighLightMat()
  return HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
end

function UMG_HomeMain_New_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  if self.FurnitureManagerHelper then
    self.FurnitureManagerHelper:OnClose()
  end
  self:RemoveInputMappingContext("IMC_HomeEdit")
  HomeIndoorSandbox.World.Controller:DetachPanelForControl()
  if self.bEnabledUploadMask then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "UMG_HomeMain_New_C OnReqPublishCallback")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "UMG_HomeMain_New_C OnReqPublishCallback")
  end
end

function UMG_HomeMain_New_C:OnRocoTouchStartHandler(TouchIndex, Pos)
  return self.FurnitureTouchPlace:OnRocoTouchStartHandler(TouchIndex, Pos)
end

function UMG_HomeMain_New_C:OnRocoTouchMoveHandler(TouchIndex, Pos)
  return self.FurnitureTouchPlace:OnRocoTouchMoveHandler(TouchIndex, Pos)
end

function UMG_HomeMain_New_C:OnRocoTouchEndHandler(TouchIndex)
  return self.FurnitureTouchPlace:OnRocoTouchEndHandler(TouchIndex)
end

function UMG_HomeMain_New_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_HomeEdit")
  if mappingContext then
    mappingContext:EnableInputMappingContext()
  else
    mappingContext = self:AddInputMappingContext("IMC_HomeEdit")
    if mappingContext then
      local actions = {
        {
          name = "IA_MouseWheelUp_Home",
          method = "OnPcWheelUp"
        },
        {
          name = "IA_MouseWheelDown_Home",
          method = "OnPcWheelDown"
        },
        {
          name = "IA_MoveLeft_Home",
          method = "OnPcMoveLeft"
        },
        {
          name = "IA_MoveRight_Home",
          method = "OnPcMoveRight"
        },
        {
          name = "IA_MoveForward_Home",
          method = "OnPcMoveForward"
        },
        {
          name = "IA_MoveBackward_Home",
          method = "OnPcMoveBackward"
        },
        {
          name = "IA_SelectFurnitureTab_left",
          method = "OnPcSelectFurnitureTabLeft"
        },
        {
          name = "IA_SelectFurnitureTab_right",
          method = "OnPcSelectFurnitureTabRight"
        },
        {
          name = "IA_SelectFurnitureSecondTab",
          method = "OnPcSelectFurnitureSecondTab"
        },
        {
          name = "IA_DecorateMode_Close",
          method = "OnPcClose"
        },
        {
          name = "IA_DecorateMode_QuickClose",
          method = "OnPcClose"
        }
      }
      for _, action in ipairs(actions) do
        mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
      end
    end
  end
end

function UMG_HomeMain_New_C:OnPcSelectFurnitureTabLeft()
  self.FurnitureListHelper:OnPcSelectFurnitureTabLeft()
end

function UMG_HomeMain_New_C:OnPcSelectFurnitureTabRight()
  self.FurnitureListHelper:OnPcSelectFurnitureTabRight()
end

function UMG_HomeMain_New_C:OnPcSelectFurnitureSecondTab()
  self.FurnitureListHelper:OnPcSelectFurnitureSecondTab()
end

local LEFT_DIR = UE.FVector2D(-1, 0)
local RIGHT_DIR = UE.FVector2D(1, 0)
local FORWARD_DIR = UE.FVector2D(0, -1)
local BACKWARD_DIR = UE.FVector2D(0, 1)

function UMG_HomeMain_New_C:OnPcMoveLeft(v)
  if not self.enableView then
    return
  end
  self:DispatchEvent(HomeIndoorSandbox.Event.OnPcMovementInput, LEFT_DIR)
end

function UMG_HomeMain_New_C:OnPcMoveRight(v)
  if not self.enableView then
    return
  end
  self:DispatchEvent(HomeIndoorSandbox.Event.OnPcMovementInput, RIGHT_DIR)
end

function UMG_HomeMain_New_C:OnPcMoveForward(v)
  if not self.enableView then
    return
  end
  self:DispatchEvent(HomeIndoorSandbox.Event.OnPcMovementInput, FORWARD_DIR)
end

function UMG_HomeMain_New_C:OnPcMoveBackward(v)
  if not self.enableView then
    return
  end
  self:DispatchEvent(HomeIndoorSandbox.Event.OnPcMovementInput, BACKWARD_DIR)
end

function UMG_HomeMain_New_C:OnPcWheelUp()
  if not self.enableView then
    return
  end
  local Pos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform()
  if self.FurnitureTouchPlace:IfPosInFurnitureListBounds(Pos.X, Pos.Y) then
    return
  end
  if self.FurnitureManagerHelper:IfPosInFurnitureListBounds(Pos.X, Pos.Y) then
    return
  end
  HomeIndoorSandbox.World.Controller:OnPCFOVInputUp()
end

function UMG_HomeMain_New_C:OnPcWheelDown()
  if not self.enableView then
    return
  end
  local Pos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform()
  if self.FurnitureTouchPlace:IfPosInFurnitureListBounds(Pos.X, Pos.Y) then
    return
  end
  if self.FurnitureManagerHelper:IfPosInFurnitureListBounds(Pos.X, Pos.Y) then
    return
  end
  HomeIndoorSandbox.World.Controller:OnPCFOVInputDown()
end

function UMG_HomeMain_New_C:OnBtnExitHomeEditor()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_HomeMain_New_C:OnBtnExitHomeEditor")
  if self.bPendingClose then
    HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor pending close")
    return
  end
  if HomeIndoorSandbox.Server.WorldData:IsViolation() then
    if not HomeIndoorSandbox.HomeEditServ:IfNeedUpload() and HomeIndoorSandbox.HomeTipsServ:TryProcessHomeViolationDuringEditing() then
      HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor violation")
      return
    end
    local Ctx = DialogContext()
    Ctx:SetCallback(self, self.OnViolationExitHomeDialogCallback)
    Ctx:SetContent(LuaText.home_edit_close_text)
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    Ctx:SetTitle(LuaText.home_edit_close_title)
    Ctx:SetButtonText(_G.LuaText.home_edit_close_button_yes, _G.LuaText.home_edit_close_button_no)
    Ctx:SetCloseBtnNotDoCancel(true)
    Ctx:SetClickAnywhereClose(true)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    return
  end
  if not HomeIndoorSandbox.HomeEditServ:IfNeedUpload() then
    HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor close directly")
    self:OnReqExitHomeEditor()
    return
  end
  HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor")
  local Ctx = DialogContext()
  Ctx:SetCallback(self, self.OnExitHomeDialogCallback)
  Ctx:SetContent(LuaText.home_edit_close_text)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.home_edit_close_title)
  Ctx:SetButtonText(_G.LuaText.home_edit_close_button_yes, _G.LuaText.home_edit_close_button_no)
  Ctx:SetCloseBtnNotDoCancel(true)
  Ctx:SetClickAnywhereClose(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_HomeMain_New_C:OnViolationExitHomeDialogCallback(bOk, CancelType)
  if bOk then
    self:OnReqPublishCallback(true)
  elseif CancelType == CommonBtnEnum.DialogCancelType.BtnClickType then
    HomeIndoorSandbox.HomeTipsServ:TryProcessHomeViolationDuringEditing()
  end
end

function UMG_HomeMain_New_C:OnExitHomeDialogCallback(bOK, CancelType)
  if bOK then
    self:OnReqPublishCallback(true)
  elseif CancelType == CommonBtnEnum.DialogCancelType.BtnClickType then
    self:OnReqExitHomeEditor()
  end
end

function UMG_HomeMain_New_C:OnReqExitHomeEditor()
  if self.bPendingClose then
    HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor pending close")
    return
  end
  if self.HC then
    if self.HC:GetVisibility() == UE.ESlateVisibility.Visible then
      HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor HC return")
      return
    end
    self.HC:SetVisibility(UE.ESlateVisibility.Visible)
  end
  self.bPendingClose = true
  HomeIndoorSandbox:LogWarn("OnBtnExitHomeEditor OnReqExitHomeEditor")
  HomeIndoorSandbox.Module:StartTransitionUI(function()
    self:OnClose()
    DelayManager:DelaySeconds(0.25, function()
      HomeIndoorSandbox.Module:StopTransitionUI()
    end)
  end)
end

function UMG_HomeMain_New_C:OnPcClose()
  local SelectedActor = HomeIndoorSandbox.HomeEditServ.TheSelectedPropsActor
  if SelectedActor and SelectedActor:IsValid() then
  elseif HomeIndoorSandbox.HomeEditServ.ThePreviewDecoData then
  else
    self:OnBtnExitHomeEditor()
  end
end

function UMG_HomeMain_New_C:OnBtnSwitchPrevRoom()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_HomeMain_New_C:OnBtnSwitchPrevRoom")
  self:ReqStartSwitch(self.InternalSwitchPrevRoom)
end

function UMG_HomeMain_New_C:InternalSwitchPrevRoom()
  HomeIndoorSandbox.Module:SwitchPrevEditRoom()
  self:RefreshRoomStats()
end

function UMG_HomeMain_New_C:OnBtnSwitchNextRoom()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_HomeMain_New_C:OnBtnSwitchNextRoom")
  self:ReqStartSwitch(self.InternalSwitchNextRoom)
end

function UMG_HomeMain_New_C:InternalSwitchNextRoom()
  HomeIndoorSandbox.Module:SwitchNextEditRoom()
  self:RefreshRoomStats()
end

function UMG_HomeMain_New_C:ReqStartSwitch(DoSwitchRoomDelegate)
  self.DoSwitchRoomDelegate = DoSwitchRoomDelegate
  self:PlayAnimation(self.CutTo_In)
end

function UMG_HomeMain_New_C:OnBtnToggleCameraMode()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_HomeMain_New_C:OnBtnToggleCameraMode")
  if self.bGroundView then
    self:ToggleToWallCamera()
  else
    self:ToggleToGroundCamera()
  end
end

function UMG_HomeMain_New_C:ToggleToGroundCamera()
  if not self.bGroundView then
    self.bGroundView = true
    HomeIndoorSandbox.World.Controller:ToggleToGroundCamera()
    local HomeEnum = HomeIndoorSandbox.Enum
    self.Perspective:SetPath(HomeEnum.GroundViewIcon, HomeEnum.GroundViewIcon, HomeEnum.GroundViewIcon)
    self.Perspective:SetText(LuaText.furniture_over_view)
  end
end

function UMG_HomeMain_New_C:ToggleToWallCamera()
  if self.bGroundView then
    self.bGroundView = false
    HomeIndoorSandbox.World.Controller:ToggleToWallCamera()
    local HomeEnum = HomeIndoorSandbox.Enum
    self.Perspective:SetPath(HomeEnum.WallViewIcon, HomeEnum.WallViewIcon, HomeEnum.WallViewIcon)
    self.Perspective:SetText(LuaText.furniture_level_view)
  end
end

function UMG_HomeMain_New_C:OnBtnOpenManagerPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_HomeMain_New_C:OnBtnOpenManagerPanel")
  if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Placing then
    return
  end
  self:ToggleToManagerMode()
end

function UMG_HomeMain_New_C:OnBtnCloseManagerPanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_HomeMain_New_C:OnBtnCloseManagerPanel")
  self:ToggleToDefaultMode()
end

function UMG_HomeMain_New_C:OnBtnUnloadAllProps()
  self.FurnitureManagerHelper:OnBtnUnloadAllProps()
end

function UMG_HomeMain_New_C:OnBtnEditRoomName()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_HomeMain_New_C:OnBtnEditRoomName")
  self.FurnitureManagerHelper:OnBtnEditRoomName()
end

function UMG_HomeMain_New_C:OnBtnUnloadProps()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_HomeMain_New_C:OnBtnUnloadProps")
  HomeIndoorSandbox.Module:UnloadPackUpProps()
  self:ToggleToDefaultMode()
end

function UMG_HomeMain_New_C:OnBtnRotateProps()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_HomeMain_New_C:OnBtnRotateProps")
  HomeIndoorSandbox.Module:NotifyRotationOperation()
end

function UMG_HomeMain_New_C:OnBtnCancelPlace()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_HomeMain_New_C:OnBtnCancelPlace")
  HomeIndoorSandbox.Module:NotifyCancelOperation()
  self:ToggleToDefaultMode()
end

function UMG_HomeMain_New_C:OnBtnConfirmPlace()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_HomeMain_New_C:OnBtnConfirmPlace")
  HomeIndoorSandbox.Module:NotifyConfirmOperation()
  self:ToggleToDefaultMode()
end

function UMG_HomeMain_New_C:OnBtnFurnitureListShow()
  if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Init then
    _G.NRCAudioManager:PlaySound2DAuto(40008024, "UMG_HomeMain_New_C:OnBtnFurnitureListShow")
    self:SetFurnitureListEnabled(false)
  end
end

function UMG_HomeMain_New_C:OnBtnFurnitureListHide()
  if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Init then
    _G.NRCAudioManager:PlaySound2DAuto(40008025, "UMG_HomeMain_New_C:OnBtnFurnitureListHide")
    self:SetFurnitureListEnabled(true)
  end
end

function UMG_HomeMain_New_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Exit.btnClose, self.OnBtnExitHomeEditor)
  self:AddButtonListener(self.Btn_Left, self.OnBtnSwitchPrevRoom)
  self:AddButtonListener(self.Btn_Right, self.OnBtnSwitchNextRoom)
  self:AddButtonListener(self.Perspective.btnLevelUp, self.OnBtnToggleCameraMode)
  self:AddButtonListener(self.Management.btnLevelUp, self.OnBtnOpenManagerPanel)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnCloseManagerPanel)
  self:AddButtonListener(self.OneClickBtn.btnLevelUp, self.OnBtnUnloadAllProps)
  self:AddButtonListener(self.Btn_Editor, self.OnBtnEditRoomName)
  self:AddButtonListener(self.Place.btnLevelUp, self.OnBtnUnloadProps)
  self:AddButtonListener(self.Rotation.btnLevelUp, self.OnBtnRotateProps)
  self:AddButtonListener(self.Cancel.btnLevelUp, self.OnBtnCancelPlace)
  self:AddButtonListener(self.Confirm.btnLevelUp, self.OnBtnConfirmPlace)
  self:AddButtonListener(self.ClickItemBtn, self.OnShowComfortTips)
  self:AddButtonListener(self.Btn_Show, self.OnBtnFurnitureListShow)
  self:AddButtonListener(self.Btn_Hide, self.OnBtnFurnitureListHide)
  self:AddButtonListener(self.Btn_Publish.btnLevelUp, self.OnReqPublish)
  self.FurnitureManagerHelper:OnAddEventListener()
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnPlacedPropsSelected, self.ToggleToPlacingMode)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnEditPropsStatusChanged, self.OnEditPropsStatusChanged)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnEditDecoFinished, self.OnEditDecoFinished)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnInternalComfortChanged, self.OnInternalComfortChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_HomeMain_New_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_HomeMain_New_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_HomeMain_New_C", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
end

function UMG_HomeMain_New_C:OnShowComfortTips()
  HomeIndoorSandbox.Module:OpenHomeComfortLevelTips()
end

function UMG_HomeMain_New_C:GetHomeModule()
  return self.module
end

function UMG_HomeMain_New_C:GetHomeModuleData(...)
  return self.module:GetData(...)
end

function UMG_HomeMain_New_C:OnEditPropsStatusChanged(Status, PropsData)
  if Status == HomeIndoorSandbox.Enum.EnmEditPropsStatus.SPAWN_SUCCESS then
    self:ToggleToPlacingMode()
    self.HomeStats:ResolveComfort(PropsData)
    self.FurnitureTouchPlace:OnPostCreateItem(PropsData)
    _G.NRCAudioManager:PlaySound2DAuto(40007002, "FurnitureTouchPlace:CreateItem")
  else
    self.FurnitureTouchPlace:OnPostCreateItem(nil, Status)
  end
end

function UMG_HomeMain_New_C:OnEditDecoFinished(DecoData, DiffValue)
  if DecoData then
    self:ToggleToPlacingMode()
  end
  self.HomeStats:ResolveComfort(DecoData, DiffValue)
end

function UMG_HomeMain_New_C:OnInternalComfortChanged()
  self.HomeStats:ResolveComfort()
end

function UMG_HomeMain_New_C:ToggleToPlacingMode(bDisableTitleChange)
  return self:SetMode(HomeIndoorSandbox.Enum.EnmPanelMode.Placing, bDisableTitleChange)
end

function UMG_HomeMain_New_C:ToggleToManagerMode()
  return self:SetMode(HomeIndoorSandbox.Enum.EnmPanelMode.Manager)
end

function UMG_HomeMain_New_C:ToggleToDefaultMode()
  return self:SetMode(HomeIndoorSandbox.Enum.EnmPanelMode.Init)
end

function UMG_HomeMain_New_C:SetMode(Mode, bDisableTitleChange)
  if Mode ~= self.Mode then
    self.Mode = Mode
    if Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Init then
      self:SetCameraModeSwitchEnabled(true)
      self:SetFurnitureManagerEnabled(false)
      self:SetFurnitureListEnabled(true)
      self:SetFurnitureOperationEnabled(false)
      self:SetControlPanelEnabled(true)
      self.EditFurniture:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasDown:SetVisibility(UE.ESlateVisibility.Visible)
      self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self:ToggleRoomNameToPropsName(false)
    elseif Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Manager then
      self:SetCameraModeSwitchEnabled(false)
      self:SetFurnitureManagerEnabled(true)
      self:SetFurnitureListEnabled(false)
      self:SetFurnitureOperationEnabled(false)
      self:SetControlPanelEnabled(true)
      self.EditFurniture:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasDown:SetVisibility(UE.ESlateVisibility.Visible)
      self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self:ToggleRoomNameToPropsName(false)
    elseif Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Placing then
      self:SetCameraModeSwitchEnabled(false)
      self:SetFurnitureManagerEnabled(false)
      self:SetFurnitureListEnabled(false)
      self:SetFurnitureOperationEnabled(true)
      self:SetControlPanelEnabled(true)
      self:ToggleRoomNameToPropsName(not bDisableTitleChange)
    end
  end
  self:RefreshRoomStats()
end

function UMG_HomeMain_New_C:InFurnitureMode()
  return self.FurnitureListHelper:InFurnitureMode()
end

function UMG_HomeMain_New_C:ToggleRoomNameToPropsName(bEnable)
  if bEnable then
    self.RoomSwitch:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.FurnitureCategory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local Props = HomeIndoorSandbox.HomeEditServ.TheSelectedPropsActor
    if Props then
      local PropsData = Props.PropsData
      self.FurnitureName:SetText(PropsData:GetName())
      local Conf = PropsData:GetTabConf()
      if Conf then
        self.FurnitureIcon:SetPath(Conf.tab_icon)
      end
    else
      local PreviewDeco = HomeIndoorSandbox.HomeEditServ.ThePreviewDecoData
      if PreviewDeco then
        self.FurnitureName:SetText(PreviewDeco:GetName())
        local Conf = PreviewDeco:GetTabConf()
        if Conf then
          self.FurnitureIcon:SetPath(Conf.tab_icon)
        end
      end
    end
  else
    self.RoomSwitch:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.FurnitureCategory:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_HomeMain_New_C:Init()
  self.Text_RoomName:SetIsEnabled(false)
  self:ToggleToDefaultMode()
end

function UMG_HomeMain_New_C:RefreshRoomStats(bDisableTitleChange)
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Placing then
    return
  end
  self.HomeStats:ResolveComfort()
  self.HomeStats:ResolveRoomName()
  if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Manager then
    self.FurnitureManagerHelper:InitLayer()
  elseif self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Init then
    self.FurnitureListHelper:InitTabLayer()
  end
  local EditRoomId = HomeIndoorSandbox.HomeEditServ.EditRoomId
  local MaxiRoomId = HomeIndoorSandbox.World.MaxRoomId
  local MinRoomId = HomeIndoorSandbox.World.MinRoomId
  local HasPrev = MaxiRoomId ~= MinRoomId and 0 ~= MinRoomId
  local HasNext = HasPrev
  self.Btn_Left:SetVisibility(HasPrev and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  self.Btn_Right:SetVisibility(HasNext and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
end

function UMG_HomeMain_New_C:SetCameraModeSwitchEnabled(bEnable)
  self.Perspective:SetVisibility(bEnable and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UMG_HomeMain_New_C:SetFurnitureManagerEnabled(bEnable)
  self.HouseManagement:SetVisibility(bEnable and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
  if not bEnable then
    self.FurnitureManagerHelper:OnClose()
  end
end

function UMG_HomeMain_New_C:SetFurnitureListEnabled(bEnable)
  self.bFurnitureListEnabled = bEnable
  if not bEnable then
    self:PlayAnimation(self.Tab_Hide)
  else
    self:PlayAnimation(self.Tab_OpenUp)
    self.Furniture:SetAllowOverscroll(true)
  end
end

function UMG_HomeMain_New_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_HomeMain_New_C:PCKeySetting()
  if SystemSettingModuleCmd then
    self.PCKey:SetKeyVisibility(true)
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_SelectFurnitureTab_left")
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey1:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_SelectFurnitureTab_right")
    if "" ~= image then
      self.PCKey1:SetImageMode(image)
    else
      self.PCKey1:SetText(text)
    end
    self.PCKey2:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_SelectFurnitureSecondTab")
    if "" ~= image then
      self.PCKey2:SetImageMode(image)
    else
      self.PCKey2:SetText(text)
    end
    self.PCKey_1:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_MoveForward_Home")
    if "" ~= image then
      self.PCKey_1:SetImageMode(image)
    else
      self.PCKey_1:SetText(text)
    end
    self.PCKey_2:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_MoveLeft_Home")
    if "" ~= image then
      self.PCKey_2:SetImageMode(image)
    else
      self.PCKey_2:SetText(text)
    end
    self.PCKey_3:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_MoveBackward_Home")
    if "" ~= image then
      self.PCKey_3:SetImageMode(image)
    else
      self.PCKey_3:SetText(text)
    end
    self.PCKey_4:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_MoveRight_Home")
    if "" ~= image then
      self.PCKey_4:SetImageMode(image)
    else
      self.PCKey_4:SetText(text)
    end
    self.PCKey_5:SetKeyVisibility(true)
    self.PCKey_5:SetScrollMode()
  end
  self.MovementHintText:SetText(LuaText.pc_move_camera_text)
  self.MouseHintText:SetText(LuaText.pc_zoom_FOV_text)
end

function UMG_HomeMain_New_C:OnAnimationFinished(Anim)
  if Anim == self.Tab_Hide then
    if self.Mode == HomeIndoorSandbox.Enum.EnmPanelMode.Placing then
      self.CanvasDown:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.Furniture:SetAllowOverscroll(false)
  elseif Anim == self.CutTo_In then
    self.DoSwitchRoomDelegate(self)
    self:PlayAnimation(self.CutTo_Out)
    self.DoSwitchRoomDelegate = nil
  end
end

function UMG_HomeMain_New_C:SetFurnitureOperationEnabled(bEnable)
  if bEnable then
    self:PlayAnimation(self.Put_Tab_In)
  else
    self:PlayAnimation(self.Put_Tab_Out)
  end
  self:SetEnableTick(bEnable, HomeIndoorSandbox.Enum.EnmPanelTickSource.Placing)
end

function UMG_HomeMain_New_C:SetControlPanelEnabled(bEnable)
  self.ControlPanel:SetVisibility(bEnable and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UMG_HomeMain_New_C:SetEnableTick(bEnabled, Source)
  if bEnabled then
    self.TickFlags = self.TickFlags | Source
  else
    self.TickFlags = self.TickFlags & ~Source
  end
  if self.TickFlags ~ 0 then
    if not self.bTicking then
      self.bTicking = true
      UpdateManager:Register(self)
    end
  elseif self.bTicking then
    self.bTicking = false
    UpdateManager:UnRegister(self)
  end
end

function UMG_HomeMain_New_C:OnTick(Dt)
  local SelectedActor = HomeIndoorSandbox.HomeEditServ.TheSelectedPropsActor
  if SelectedActor and SelectedActor:IsValid() then
    self.Rotation:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if SelectedActor.PropsData.bTempData then
      self.Confirm:SetVisibility(UE.ESlateVisibility.Hidden)
    else
      self.Confirm:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if SelectedActor.PropsData.TempLocalLocation then
      self.Place:SetVisibility(UE.ESlateVisibility.Hidden)
    else
      self.Place:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Cancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Publish:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_Exit:SetVisibility(UE.ESlateVisibility.Collapsed)
  elseif HomeIndoorSandbox.HomeEditServ.ThePreviewDecoData then
    self.Place:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Rotation:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Confirm:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Cancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Publish:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_Exit:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.Place:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Rotation:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Confirm:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Cancel:SetVisibility(UE.ESlateVisibility.Hidden)
    if HomeIndoorSandbox.HomeEditServ:IfNeedUpload() then
      self.Publish:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Publish:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.Btn_Exit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_HomeMain_New_C:OnReqPublish()
  HomeIndoorSandbox:LogWarn("OnReqPublish")
  if HomeIndoorSandbox.HomeEditServ:IsInPublishCountDown() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_layout_release_CD)
    return
  end
  local Ctx = DialogContext()
  Ctx:SetCallback(self, self.OnReqPublishCallback)
  Ctx:SetContent(LuaText.home_layout_release_text)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.home_layout_release_title)
  Ctx:SetButtonText(LuaText.home_layout_release_button, _G.LuaText.NO)
  Ctx:SetClickAnywhereClose(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_HomeMain_New_C:OnReqPublishCallback(bOk)
  if bOk then
    if HomeIndoorSandbox.HomeEditServ:IsInPublishCountDown() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_layout_release_CD)
      return
    end
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddInputBlockMappingContext, "UMG_HomeMain_New_C OnReqPublishCallback")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "UMG_HomeMain_New_C OnReqPublishCallback")
    self:ToggleUploadProgressMask(true)
    HomeIndoorSandbox.HomeEditServ:UploadAllEditManually(function(bSuccess, bRspReceived)
      if self.enableView and self.bEnabledUploadMask then
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "UMG_HomeMain_New_C OnReqPublishCallback")
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "UMG_HomeMain_New_C OnReqPublishCallback")
        self:ToggleUploadProgressMask(false)
        if bSuccess then
          HomeIndoorSandbox.Module:GetData():EvalCollectBagFurnitureItemInfo()
          self.FurnitureListHelper:Refresh()
        elseif bRspReceived then
          HomeIndoorSandbox.Module:GetData():EvalCollectBagFurnitureItemInfo()
          self.FurnitureListHelper:Refresh()
        end
        HomeIndoorSandbox.World.Controller:LandPos()
      end
    end)
  end
end

function UMG_HomeMain_New_C:ToggleUploadProgressMask(bEnabled)
  self.bEnabledUploadMask = bEnabled
  if not self.NRCWidgetLoader_LoadUpload then
    return
  end
  self.NRCWidgetLoader_LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if not self.NRCWidgetLoader_LoadUpload:GetPanel() then
    self.NRCWidgetLoader_LoadUpload:LoadPanelSync(self)
  end
  if bEnabled then
    local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
    if panel then
      panel:SetPublishUploading()
    end
  else
    local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
    if panel then
      panel:StopAllAnimations()
    end
  end
end

function UMG_HomeMain_New_C:AddButtonListener(btn, handler)
  HomeIndoorSandbox:LogDebug("\230\183\187\229\138\160\230\140\137\233\146\174\239\188\154\229\155\158\232\176\131", btn, btn and btn:GetFullName(), self.viewbuttonEventDict and not self.viewbuttonEventDict[btn])
  NRCPanelBase.AddButtonListener(self, btn, handler)
  HomeIndoorSandbox:LogDebug("\230\183\187\229\138\160\230\140\137\233\146\174\239\188\154\229\174\140\230\136\144", self.viewbuttonEventDict and not self.viewbuttonEventDict[btn])
end

function UMG_HomeMain_New_C:RemoveButtonListener(btn)
  NRCPanelBase.RemoveButtonListener(self, btn)
  HomeIndoorSandbox:LogWarn("\231\167\187\233\153\164\230\140\137\233\146\174\239\188\154", btn, btn and btn:GetFullName())
end

function UMG_HomeMain_New_C:RemoveAllButtonListener()
  NRCPanelBase.RemoveAllButtonListener(self)
  HomeIndoorSandbox:LogWarn("\231\167\187\233\153\164\230\140\137\233\146\174\239\188\154\230\137\128\230\156\137")
end

return UMG_HomeMain_New_C
