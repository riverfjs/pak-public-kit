local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local SettingPanelProxy = require("NewRoco.Modules.System.TakePhotos.Helper.SettingPanelProxy")
local NoWindowsMainPanelAdapter = require("NewRoco.Modules.System.TakePhotos.Helper.NoWindowsMainPanelAdapter")
local WindowsMainPanelAdapter = require("NewRoco.Modules.System.TakePhotos.Helper.WindowsMainPanelAdapter")
local VisibilityMutex = require("NewRoco.Modules.System.TakePhotos.Helper.VisibilityMutex")
local TripodControlPad = require("NewRoco.Modules.System.TakePhotos.Helper.TripodControlPad")
local TakePhotoProxy = require("NewRoco.Modules.System.TakePhotos.Helper.TakePhotoProxy")
local IdentifyProxy = require("NewRoco.Modules.System.TakePhotos.Helper.IdentifyProxy")
local TripodRecycle = require("NewRoco.Modules.System.TakePhotos.Helper.TripodRecycle")
local FovProgressBar = require("NewRoco.Modules.System.TakePhotos.Helper.FovProgressBar")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local Delegate = require("Utils.Delegate")
local UMG_TakePhotos_New_C = _G.NRCPanelBase:Extend("UMG_TakePhotos_New_C")
local bUsingPCMode = _G.RocoEnv.PLATFORM_WINDOWS
if bUsingPCMode then
  xpcall(function()
    WindowsMainPanelAdapter.InitializePCInputs(UMG_TakePhotos_New_C)
  end, function(err)
    Log.Error("err=", err)
  end)
end

function UMG_TakePhotos_New_C:OnConstruct()
  self.bThisTickEnabled = false
  self.CurrMode = nil
  self:AddButtonListener(self.dropOut.btnClose, self.OnReqClose)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPostEnterTakePhotos, self.OnInitializeMode)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnToggleMode, self.OnToggleMode)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnExitMode, self.OnExitMode)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotosRemoved, self.OnPhotoRemoved)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved, self.OnPhotoRemoved)
  self.Adapter = nil
  if bUsingPCMode then
    self.Adapter = WindowsMainPanelAdapter(self)
  else
    self.Adapter = NoWindowsMainPanelAdapter(self)
  end
  self.Adapter:OnInit()
  self.OnDestroyMultiDelegate = Delegate()
  self.OnTickMultiDelegate = Delegate()
  self.OnModeChangedDelegate = Delegate()
  self.OnAvatarReadyDelegate = Delegate()
  self.OnReadyDelegate = Delegate()
  self.SettingPanelProxy = SettingPanelProxy(self)
  self.TakePhotoProxy = TakePhotoProxy(self)
  self.IdentifyProxy = IdentifyProxy(self)
  self.FovProgressProxy = FovProgressBar(self)
  self.TripodRecycleProxy = TripodRecycle(self)
  self:OnInit()
end

function UMG_TakePhotos_New_C:OnDestruct()
  self:GetPhotoController():Exit(not self.bPendingCloseByUser)
  self.OnDestroyMultiDelegate:Invoke()
  self.Adapter:OnDestroy()
  self:OnDestroy()
end

function UMG_TakePhotos_New_C:OnActive()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  self.bPanelModeHidden = true
  self:RefreshHideAll()
end

function UMG_TakePhotos_New_C:OnPcClose()
  return self:OnReqClose()
end

function UMG_TakePhotos_New_C:OnReqClose()
  if self.bPendingCloseByUser then
    self:DoClose()
    return
  end
  self.bPendingCloseByUser = true
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_C:OnReqClose")
  self:GetPhotoController():Exit(false)
end

function UMG_TakePhotos_New_C:CloseImmediately()
  self:DoClose()
end

function UMG_TakePhotos_New_C:GetModule()
  return NRCModuleManager:GetModule("TakePhotosModule")
end

function UMG_TakePhotos_New_C:GetPhotoController()
  return self:GetModule().Controller
end

function UMG_TakePhotos_New_C:SetThisTickEnabled(bEnable)
  if bEnable ~= self.bThisTickEnabled then
    self.bThisTickEnabled = bEnable
    if bEnable then
      UpdateManager:Register(self)
    else
      UpdateManager:UnRegister(self)
    end
  end
end

function UMG_TakePhotos_New_C:OnInitializeMode()
  if self:OnBanChanged() then
    return
  end
  self:PlayAnimation(self.In)
  self:SetThisTickEnabled(true)
  self.CurrMode = self:GetModule().ModeMgr.CurrMode
  self.bPanelModeHidden = false
  self:RefreshHideAll()
  self:RefreshByMode()
  self:OnReady()
  self.OnReadyDelegate:Invoke()
end

function UMG_TakePhotos_New_C:OnToggleMode(Mode)
  self.OldMode = self.CurrMode
  self.CurrMode = Mode
  self:RefreshByMode()
end

function UMG_TakePhotos_New_C:OnExitMode()
  self.SettingPanelProxy:OnExitMode()
end

function UMG_TakePhotos_New_C:RefreshByMode()
  self.Adapter:RefreshByMode()
  self.OnModeChangedDelegate:Invoke(self.CurrMode)
  self:OnRefreshByMode(self.CurrMode)
end

function UMG_TakePhotos_New_C:OnTick(Dt)
  if not self.bThisTickEnabled then
    return
  end
  if not self.CurrMode then
    return
  end
  self.Adapter:OnTick(Dt)
  self.OnTickMultiDelegate:Invoke(Dt)
  self.CurrMode:OnTick(Dt)
  self:OnTickPanel(Dt)
  if self.bPendingWarningClose then
    self:Log("[TakePhoto] warning close")
    self:DoClose()
  end
end

function UMG_TakePhotos_New_C:NotifyWarningClose()
  self.bPendingWarningClose = true
end

function UMG_TakePhotos_New_C:OnInit()
  self._RightUpBtnGroup = self.HorizontalBox_2
  self._RightUpBtnGroupVisibilityMutex = VisibilityMutex(self._RightUpBtnGroup, true)
  self:InitModeBtnGroup()
  self:InitTripodBtnGroup()
  self._BtnReset = self.Reset
  self._Album = self.Album
  self._BtnTakePhoto = self.BtnPhotograph
  self._BtnTakePhotoVisibilityMutex = VisibilityMutex(self._BtnTakePhoto, true)
  self._BurstNumCanvas = self.CanvasPanel_ContinuousShot
  self._BurstNumCanvasVisibilityMutex = VisibilityMutex(self._BurstNumCanvas, true)
  self._Text_CountDownVisibilityMutex = VisibilityMutex(self.Text_CountDown, false)
  self.Mode_CanvasPanel_29_VisibilityMutex = VisibilityMutex(self.CanvasPanel_29, true)
  self._TaskPanel = self.VerticalBox_Task
  self._TaskPanelVisibilityMutex = VisibilityMutex(self._TaskPanel, false)
  self._TripodControlPad = TripodControlPad(self)
  if self.Expression then
    self.Expression:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.Mode1PWidgetMutexDefines = {
    self._TripodControlPad,
    self._TripodModeBtnGroupCanvasVisibilityMutex
  }
  self.ModeSelfieWidgetMutexDefines = {
    self._TripodControlPad,
    self._TripodModeBtnGroupCanvasVisibilityMutex
  }
  self.ModeTripodWidgetMutexDefines = {}
  self.ModeWorldWidgetMutexDefines = {
    self._TripodControlPad,
    self.FovProgressProxy.VisibilityMutex,
    self.CanvasPanel_AimTakingPhoto,
    self._BtnTakePhotoVisibilityMutex,
    self.Mode_CanvasPanel_29_VisibilityMutex,
    self.Mask,
    self.Btn_Set,
    self._BtnReset,
    self._BurstNumCanvasVisibilityMutex
  }
  self.PCKeyMap = {
    {
      PCKey = self.Handheld.PCKey,
      IAName = "IA_PgEnter1PMode"
    },
    {
      PCKey = self.Selfie.PCKey,
      IAName = "IA_PgEnterSelfieMode"
    },
    {
      PCKey = self.Fixed.PCKey,
      IAName = "IA_PgEnterTripodMode"
    },
    {
      PCKey = self._Album.Text_PCKey,
      IAName = "IA_PgOpenAlbum"
    },
    {
      PCKey = self._BtnReset.Text_PCKey,
      IAName = "IA_PgResetCamera"
    },
    {
      PCKey = self.Btn_Set.Text_PCKey,
      IAName = "IA_PgOpenSettingUI"
    },
    {
      PCKey = self._BtnWorldToTripod.PCKey,
      IAName = "IA_PgWorldToTripod"
    },
    {
      PCKey = self._BtnTripodToWorld.PCKey,
      IAName = "IA_PgTripodToWorld"
    },
    {
      PCKey = self.BtnUp.Text_PCKey,
      IAName = "IA_PgCameraUpStart"
    },
    {
      PCKey = self.BtnLeft.Text_PCKey,
      IAName = "IA_PgCameraLeftStart"
    },
    {
      PCKey = self.BtnRight.Text_PCKey,
      IAName = "IA_PgCameraRightStart"
    },
    {
      PCKey = self.BtnBelow.Text_PCKey,
      IAName = "IA_PgCameraDownStart"
    },
    {
      PCKey = self.BtnPhotograph.Text_PCKey,
      IAName = "IA_PgTakePhoto"
    }
  }
  self:PCKeySetting()
  self.LastMutexWidgets = nil
  self:AddButtonListener(self._Album.btnLevelUp, self.OnReqOpenAlbum)
  self:AddButtonListener(self._BtnReset.btnLevelUp, self.OnReqReset)
  self:AddButtonListener(self._BtnTakePhoto.btnLevelUp, self.OnReqTakePhoto)
  self.TakePhotoProxy.OnStatusChanged:Add(self, self.OnTakePhotoStatusChanged)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, self, self.OnBanChanged)
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.player then
    self.player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    
    function self.OnAvatarReadyHandle(_, UID)
      local Character = self.player.viewObj
      if Character.UID == UID then
        return self:OnAvatarReady()
      end
    end
    
    self.player.avatarSystem.OnSwitchAvatarSuitComplete:Add(self.player.avatarSystem, self.OnAvatarReadyHandle)
  end
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoFileShared, self.OnPhotoFileShared)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotosTaken, self.OnPhotosTaken)
  _G.NRCEventCenter:RegisterEvent(self.panelName, self, _G.NRCPanelEvent.OpenPanelFinish, self.OnOpenPanelFinish)
  _G.NRCEventCenter:RegisterEvent(self.panelName, self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanelFinish)
  self:InitializeOverlapBanConfig()
  self:InitRedDots()
end

function UMG_TakePhotos_New_C:InitRedDots()
  self.Btn_Set.RedDot:SetupKey(496)
end

function UMG_TakePhotos_New_C:InitModeBtnGroup()
  self._Btn1PHand = self.Handheld
  self._Btn1PHand:OnItemUpdate({
    IconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shouchi1_png.img_shouchi1_png'",
    Title = LuaText.takephoto_handheld
  })
  self._BtnSelfie = self.Selfie
  self._BtnSelfie:OnItemUpdate({
    IconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_zipai_png.img_zipai_png'",
    Title = LuaText.takephoto_myself
  })
  self._BtnTripod = self.Fixed
  self._BtnTripod:OnItemUpdate({
    IconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_guding_png.img_guding_png'",
    Title = LuaText.takephoto_tripod
  })
  self:AddButtonListener(self._Btn1PHand.btnLevelUp, self.OnReq1PHand)
  self:AddButtonListener(self._BtnSelfie.btnLevelUp, self.OnReqSelfie)
  self:AddButtonListener(self._BtnTripod.btnLevelUp, self.OnReqTripod)
end

function UMG_TakePhotos_New_C:InitTripodBtnGroup()
  self._TripodModeBtnGroupCanvasVisibilityMutex = VisibilityMutex(self.CanvasPanel_1, false)
  self._BtnWorldToTripod = self.CameraMode
  self._BtnWorldToTripod:OnItemUpdate({
    IconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangjimoshi_png.img_xiangjimoshi_png'",
    Title = LuaText.takephoto_tripod_character
  })
  self._BtnTripodToWorld = self.WorldMode
  self._BtnTripodToWorld:OnItemUpdate({
    IconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shijiemoshi_png.img_shijiemoshi_png'",
    Title = LuaText.takephoto_tripod_world
  })
  self:AddButtonListener(self._BtnWorldToTripod.btnLevelUp, self.OnReqWorldToTripod)
  self:AddButtonListener(self._BtnTripodToWorld.btnLevelUp, self.OnReqTripodToWorld)
end

function UMG_TakePhotos_New_C:OnDeactive()
  self:SetThisTickEnabled(false)
end

function UMG_TakePhotos_New_C:OnDestroy()
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, self, self.OnBanChanged)
  if self.player then
    self.player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    self.player.avatarSystem.OnSwitchAvatarSuitComplete:Remove(self.player.avatarSystem, self.OnAvatarReadyHandle)
    self.player = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanelFinish, self.OnOpenPanelFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanelFinish)
end

function UMG_TakePhotos_New_C:OnReady()
  local Setting = self.SettingPanelProxy.Settings
  self._BurstNumCanvasVisibilityMutex:SetVisible(Setting:GetTakePhotoBurstNum() > 0, "SettingControl")
end

function UMG_TakePhotos_New_C:OnBanChanged()
  local isBan = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO)
  if isBan then
    Log.Warning("[TakePhoto] FunctionBan exit take photos", self.CurrMode and self.CurrMode.Name)
    self:DoClose()
    return true
  end
end

function UMG_TakePhotos_New_C:OnAvatarReady(...)
  self.OnAvatarReadyDelegate:Invoke(...)
end

function UMG_TakePhotos_New_C:OnPlayerStatusChanged(status, value, opCode, ...)
  if not self:GetPhotoController().ModeSwitchContext:IsTransiting() then
    if status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO then
      if self.CurrMode and self.CurrMode.Mgr:Is1PMode() and self.player and not self.player.statusComponent:HasStatus(status) and self.panelData then
        self:Log("[TakePhoto] player exit take photo state 1p")
        self:DoClose()
      end
      return
    elseif status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF then
      if self.CurrMode and self.CurrMode.Mgr:IsSelfieMode() and self.player and not self.player.statusComponent:HasStatus(status) and self.panelData then
        self:Log("[TakePhoto] player exit take photo state selfie")
        self:DoClose()
      end
      return
    elseif status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD then
      if self.CurrMode and self.CurrMode.Mgr:IsTripodAvailableMode() and self.player and not self.player.statusComponent:HasStatus(status) and self.panelData then
        self:Log("[TakePhoto] player exit take photo state tripod")
        self:DoClose()
      end
      return
    end
  else
    Log.Debug("[TakePhoto] switching mode, trigger status changed")
  end
  if self.player then
    if self.player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
      if self.panelData then
        self:Log("[TakePhoto] player exit take photo state WPST_DEATH", status, value, opCode)
        self:DoClose()
        return
      end
    elseif self.player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) and self.CurrMode and not self.CurrMode.Mgr:IsTripodAvailableMode() and self.panelData then
      self:Log("[TakePhoto] player exit take photo state WPST_SWIMMING", status, value, opCode)
      self:DoClose()
      return
    end
    if self.player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR) then
      self.SettingPanelProxy:ResetEmoji()
    end
  end
end

function UMG_TakePhotos_New_C:OnTakePhotoStatusChanged(bPrevTakingPhoto)
  if not bPrevTakingPhoto and self.TakePhotoProxy:IsTakingPhoto() then
    self._TripodControlPad:SetVisible(false, "TakingPhoto")
    self._BtnTakePhotoVisibilityMutex:SetVisible(false, "TakingPhoto")
    self._BurstNumCanvasVisibilityMutex:SetVisible(false, "TakingPhoto")
  elseif bPrevTakingPhoto and not self.TakePhotoProxy:IsTakingPhoto() then
    self._TripodControlPad:SetVisible(true, "TakingPhoto")
    self._BtnTakePhotoVisibilityMutex:SetVisible(true, "TakingPhoto")
    self._BurstNumCanvasVisibilityMutex:SetVisible(true, "TakingPhoto")
  end
end

function UMG_TakePhotos_New_C:OnPhotosTaken(PhotoData)
  Log.Debug("[TakePhoto] OnPhotoTaken", PhotoData)
  PhotoData:SetPetIdentifyInfo(self.IdentifyProxy:GetPetIdentifyInfo())
  PhotoData:SetTaskIdentifyInfo(self.IdentifyProxy:GetTaskIdentifyInfo())
  PhotoData:SetPhotoInfo(_G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.CheckPhotoInfoImmediately))
  self.IdentifyProxy:TryUpload()
end

function UMG_TakePhotos_New_C:RefreshModeBtnGroup(Mode)
  if self.LastModeBtnWidget then
    self.LastModeBtnWidget:SetSelected(false)
  end
  if Mode.Mgr:Is1PMode() then
    self.LastModeBtnWidget = self._Btn1PHand
  elseif Mode.Mgr:IsSelfieMode() then
    self.LastModeBtnWidget = self._BtnSelfie
  elseif Mode.Mgr:IsTripodMode() then
    self.LastModeBtnWidget = self._BtnTripod
    self._BtnWorldToTripod:SetSelected(true)
    self._BtnTripodToWorld:SetSelected(false)
  elseif Mode.Mgr:IsWorldMode() then
    self.LastModeBtnWidget = self._BtnTripod
    self._BtnWorldToTripod:SetSelected(false)
    self._BtnTripodToWorld:SetSelected(true)
  else
    self.LastModeBtnWidget = nil
  end
  if self.LastModeBtnWidget then
    self.LastModeBtnWidget:SetSelected(true)
  end
end

function UMG_TakePhotos_New_C:RefreshTripodModeBtnGroup(Mode)
  if self.LastTripodModeBtnWidget then
    self.LastTripodModeBtnWidget:SetSelected(false)
  end
  if Mode.Mgr:IsTripodMode() then
    self.LastTripodModeBtnWidget = self._BtnWorldToTripod
  elseif Mode.Mgr:IsWorldMode() then
    self.LastTripodModeBtnWidget = self._BtnTripodToWorld
  else
    self.LastTripodModeBtnWidget = nil
  end
  if self.LastTripodModeBtnWidget then
    self.LastTripodModeBtnWidget:SetSelected(true)
  end
end

function UMG_TakePhotos_New_C:RefreshWidgetVisibilityMutexByMode(Mode)
  if self.LastMutexWidgets then
    for i, Widget in ipairs(self.LastMutexWidgets) do
      if Widget.SetVisible then
        Widget:SetVisible(true)
      else
        Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if Mode.Mgr:Is1PMode() then
    self.LastMutexWidgets = self.Mode1PWidgetMutexDefines
  elseif Mode.Mgr:IsSelfieMode() then
    self.LastMutexWidgets = self.ModeSelfieWidgetMutexDefines
  elseif Mode.Mgr:IsTripodMode() then
    self.LastMutexWidgets = self.ModeTripodWidgetMutexDefines
  elseif Mode.Mgr:IsWorldMode() then
    self.LastMutexWidgets = self.ModeWorldWidgetMutexDefines
  else
    self.LastMutexWidgets = nil
  end
  if self.LastMutexWidgets then
    for i, Widget in ipairs(self.LastMutexWidgets) do
      if Widget.SetVisible then
        Widget:SetVisible(false)
      else
        Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_TakePhotos_New_C:OnRefreshByMode(Mode)
  self:RefreshModeBtnGroup(Mode)
  self:RefreshTripodModeBtnGroup(Mode)
  self:RefreshWidgetVisibilityMutexByMode(Mode)
end

function UMG_TakePhotos_New_C:OnTickPanel(Dt)
  if self.CurrMode and self.CurrMode:ConsumeHandActionChangeRequest() then
    self.SettingPanelProxy:InternalPlayAction()
  end
end

function UMG_TakePhotos_New_C:IsTakingPhotos()
  return self.TakePhotoProxy:IsTakingPhoto()
end

function UMG_TakePhotos_New_C:OnReqTakePhoto()
  if not self._BtnTakePhoto:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_C:OnReqTakePhoto")
  if self:IsTakingPhotos() then
    return
  end
  self.TakePhotoProxy:TakePhotoByMode()
end

function UMG_TakePhotos_New_C:OnReqOpenAlbum()
  if not self._RightUpBtnGroupVisibilityMutex:IsVisible() then
    return
  end
  if self:IsTakingPhotos() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400007, "UMG_TakePhotos_C:OnBtnOpenAlbum")
  self:GetModule():OpenPhotosHistoryPanel()
end

function UMG_TakePhotos_New_C:OnReqReset()
  if not self._BtnReset:IsVisible() then
    return
  end
  if not self._RightUpBtnGroupVisibilityMutex:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_New_C:OnReqReset")
  if self:IsTakingPhotos() then
    return
  end
  if self.bPendingResetResult then
    return
  end
  self.bPendingResetResult = true
  local Context = DialogContext()
  Context:SetTitle(LuaText.takephoto_reset_popup_titile):SetContent(LuaText.takephoto_reset_popup_text):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.OK, LuaText.CANCEL):SetClickAnywhereClose(true):SetCallback(self, function(_, bOk, CancelType)
    self.bPendingResetResult = false
    if bOk then
      self:OnInternalReset()
    end
  end)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_TakePhotos_New_C:OnInternalReset()
  self.CurrMode:ResetCameraView()
  self.Adapter:OnReset()
  self:GetPhotoController().TakePhotoSettings:ResetCamera()
  self.FovProgressProxy:Reset()
end

function UMG_TakePhotos_New_C:OnReq1PHand()
  if self.CurrMode.Mgr:IsWorldMode() or self.CurrMode.Mgr:Is1PMode() then
    return
  end
  if not self.Mode_CanvasPanel_29_VisibilityMutex:IsVisible() then
    return
  end
  if self:IsTakingPhotos() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1085, "UMG_TakePhotos_C:OnReq1PHand")
  self:GetModule():TransitTo1P()
end

function UMG_TakePhotos_New_C:OnReqTripod()
  if self:IsTakingPhotos() or self.CurrMode.Mgr:IsTripodMode() then
    return
  end
  if not self.Mode_CanvasPanel_29_VisibilityMutex:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1085, "UMG_TakePhotos_C:OnReqTripod")
  self:GetModule():TransitToTripod()
end

function UMG_TakePhotos_New_C:OnReqSelfie()
  if self.CurrMode.Mgr:IsWorldMode() or self.CurrMode.Mgr:IsSelfieMode() then
    return
  end
  if not self.Mode_CanvasPanel_29_VisibilityMutex:IsVisible() then
    return
  end
  if self:IsTakingPhotos() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1085, "UMG_TakePhotos_C:OnReqSelfie")
  self:GetModule():TransitSelfie()
end

function UMG_TakePhotos_New_C:OnReqWorldToTripod()
  if not self._TripodModeBtnGroupCanvasVisibilityMutex:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40006004, "UMG_TakePhotos_C:OnReqWorldToTripod")
  self:GetModule():TransitToTripod()
end

function UMG_TakePhotos_New_C:OnReqTripodToWorld()
  if not self._TripodModeBtnGroupCanvasVisibilityMutex:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40006004, "UMG_TakePhotos_C:OnReqTripodToWorld")
  self:GetModule():TransitToWorld()
end

function UMG_TakePhotos_New_C:OnAnimationStarted(Anim)
  if Anim == self.Aim then
    self.CanvasPanel_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TakePhotos_New_C:OnAnimationFinished(Anim)
  if Anim == self.Lost then
    self.CanvasPanel_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_TakePhotos_New_C:PCKeySetting()
  if SystemSettingModuleCmd then
    for _, data in pairs(self.PCKeyMap) do
      self:PCKeySetButton(data.PCKey, data.IAName)
    end
  end
  self:PCModeUpdateUI()
end

function UMG_TakePhotos_New_C:PCKeySetButton(PCKey, IAName)
  PCKey:SetKeyVisibility(true)
  local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, IAName)
  if "" ~= image then
    PCKey:SetImageMode(image)
  else
    PCKey:SetText(text)
  end
end

function UMG_TakePhotos_New_C:PCModeUpdateUI()
  if self:IsPCMode() then
    local Padding = UE4.FMargin()
    Padding.Left = -452.571411
    Padding.Top = 160
    Padding.Right = 338.28
    Padding.Bottom = 80.516
    self.CanvasPanel_1.Slot:SetOffsets(Padding)
    Padding = UE4.FMargin()
    Padding.Left = -90
    Padding.Top = 0
    Padding.Right = 0
    Padding.Bottom = 0
    self._BtnTakePhoto.Text_PCKey.Slot:SetOffsets(Padding)
    self._BtnTakePhoto.Text_PCKey:SetKeyVisibility(true)
  end
end

function UMG_TakePhotos_New_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_TakePhotos_New_C:OnPhotoFileShared(PhotoData)
  self.IdentifyProxy:OnShared(PhotoData)
end

function UMG_TakePhotos_New_C:InitializeOverlapBanConfig()
  self.PanelOverlapBanMap = {
    RelationTree = {
      self._BtnTakePhotoVisibilityMutex,
      self._TripodControlPad,
      self._BurstNumCanvasVisibilityMutex,
      self._TaskPanelVisibilityMutex,
      self._RightUpBtnGroupVisibilityMutex,
      self._TripodModeBtnGroupCanvasVisibilityMutex,
      self.Mode_CanvasPanel_29_VisibilityMutex
    },
    PetRelationTree = {
      self._BtnTakePhotoVisibilityMutex,
      self._TripodControlPad,
      self._BurstNumCanvasVisibilityMutex,
      self._TaskPanelVisibilityMutex,
      self._RightUpBtnGroupVisibilityMutex,
      self._TripodModeBtnGroupCanvasVisibilityMutex,
      self.Mode_CanvasPanel_29_VisibilityMutex
    }
  }
  self.PanelHideAllFlag = VisibilityMutex(nil, true)
end

function UMG_TakePhotos_New_C:RefreshHideAll()
  local bVisible = not self.bPanelModeHidden and self.PanelHideAllFlag:IsVisible()
  if bVisible then
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    _G.NRCModuleManager:GetModule("MainUIModule"):GetPanel("LobbyMain").VisibleContents:SetVisibility(UE.ESlateVisibility.Collapsed)
    _G.NRCModuleManager:GetModule("MainUIModule"):GetPanel("LobbyMain").VisibleContents:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE.ESlateVisibility.Hidden)
  end
  self:Log("[TakePhoto] RefreshHideAll", bVisible)
  if not self.PanelHideAllFlag:IsVisible() then
    for k, v in pairs(self.PanelHideAllFlag.LockReasons) do
      self:Log("[TakePhoto] LockReason", k, v)
    end
  end
end

function UMG_TakePhotos_New_C:ToggleBanList(List, bVisible, Reason)
  for i, view in pairs(List) do
    view:SetVisible(bVisible, Reason)
    Log.Debug("[TakePhoto] ToggleBanList", view.Widget and view.Widget:GetName(), bVisible, Reason)
  end
end

function UMG_TakePhotos_New_C:OnOpenPanelFinish(panelData)
  if self.PanelOverlapBanMap then
    local BanConfig = self.PanelOverlapBanMap[panelData.panelName]
    if BanConfig then
      if BanConfig.bHideAll then
        self.PanelHideAllFlag:SetVisible(false, panelData.panelName)
        self:RefreshHideAll()
      end
      self:ToggleBanList(BanConfig, false, panelData.panelName)
      self.SettingPanelProxy.Adapter:Close()
    end
  end
end

function UMG_TakePhotos_New_C:OnClosePanelFinish(panelData)
  if self.PanelOverlapBanMap then
    local BanConfig = self.PanelOverlapBanMap[panelData.panelName]
    if BanConfig then
      if BanConfig.bHideAll then
        self.PanelHideAllFlag:SetVisible(true, panelData.panelName)
        self:RefreshHideAll()
      end
      self:ToggleBanList(BanConfig, true, panelData.panelName)
    end
  end
end

function UMG_TakePhotos_New_C:OnPhotoRemoved()
  self.TakePhotoProxy:RefreshBurstDesc()
end

return UMG_TakePhotos_New_C
