local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local LocalAlbumList = require("NewRoco/Modules/System/TakePhotos/Helper/LocalAlbumList")
local RemoteAlbumList = require("NewRoco/Modules/System/TakePhotos/Helper/RemoteAlbumList")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local UMG_TakePhotos_Film_C = _G.NRCPanelBase:Extend("UMG_TakePhotos_Film_C")
local EnmOperationMode = {Default = 0, Remove = 1}

function UMG_TakePhotos_Film_C:OnConstruct()
  self:BindInputAction()
  self._BtnToggleDeleteMode = self.Delete
  self._BtnExit = self.CloseBtn
  self._ImgSelectRemoveAll = self.Select
  self._BtnRemoveSelected = self.Btn_delete
  self._BtnCancelRemove = self.Btn_cancel
  self._PanelSelectAll = self.Check
  self.LocalAlbumList = LocalAlbumList(self)
  self.RemoteAlbumList = RemoteAlbumList(self)
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.Title1:SetSubtitle(LuaText.takephoto_storage_title)
  self.bInputBlockedEnabled = false
  self:RegisterEvent(self, TakePhotosModuleEvent.OnBeginUploadPhoto, self.OnBeginUploadPhoto)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnFinishUploadPhoto, self.OnFinishUploadPhoto)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnBeginRemovePhotos, self.OnBeginRemovePhotos)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotosRemoved, self.OnPhotosRemoved)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved, self.OnPhotosRemoved)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoActivitySubmit, self.OnPhotoActivitySubmit)
  _G.NRCEventCenter:RegisterEvent("UMG_TakePhotos_Film_C", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingStarted)
  UE4Helper.SetDesiredShowCursor(true, "UMG_TakePhotos_Film_C")
  self:RegisterEvent(self, TakePhotosModuleEvent.OnThumbnailTextureGenerated, self.OnThumbnailTextureGenerated)
  NRCEventCenter:RegisterEvent("UMG_TakePhotos_Film_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  self:GetModule().Controller.PhotoManager:InitThumbnailPool()
end

function UMG_TakePhotos_Film_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  if self.CurrAlbumList == self.RemoteAlbumList and self.titleConf.subtitle[2] then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
end

function UMG_TakePhotos_Film_C:OnReconnect()
  self:DoClose()
end

function UMG_TakePhotos_Film_C:GetModule()
  return self.module
end

function UMG_TakePhotos_Film_C:OnActive(bFromTakingPhoto)
  UpdateManager:Register(self)
  self.bFromTakingPhoto = bFromTakingPhoto
  self.CurrAlbumList = self.LocalAlbumList
  local Tab = self.Tab
  Tab:ClearSelection()
  local TabList = {}
  table.insert(TabList, {
    onClicked = FPartial(self.ToggleToLocalTab, self),
    icon = self.img_Album.AssetPathName,
    icon_selected = self.img_Album_Selected.AssetPathName
  })
  table.insert(TabList, {
    onClicked = FPartial(self.ToggleToRemoteTab, self),
    icon = self.img_Cloud.AssetPathName,
    icon_selected = self.img_Cloud_Selected.AssetPathName
  })
  Tab:InitGridView(TabList)
  Tab:SelectItemByIndex(0)
  if #TabList > 1 then
    Tab:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    Tab:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_TakePhotos_Film_C:GetRemoteTab()
  if not self.RemoteTab then
    self.RemoteTab = self.Tab:GetItemByIndex(1)
  end
  return self.RemoteTab
end

function UMG_TakePhotos_Film_C:UpdateRemoteTab()
  local RemoteTab = self:GetRemoteTab()
  if self.CurrAlbumList == self.RemoteAlbumList then
    RemoteTab:UpdateName("")
  else
    local Name = string.format("%s/%s", self.RemoteAlbumList:GetPhotoNum(), self.RemoteAlbumList:GetPhotoMaxNum())
    RemoteTab:UpdateName(Name)
  end
end

function UMG_TakePhotos_Film_C:OnShowTips()
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.takephoto_album_explanation_title):SetContent(LuaText.takephoto_album_explanation_text):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Ctx)
end

function UMG_TakePhotos_Film_C:RefreshTabInfo()
  self.Text_Hint:SetText(self.CurrAlbumList:GetHintText(self.bFromTakingPhoto))
end

function UMG_TakePhotos_Film_C:GetCurrentOperationMode()
  return self.CurrAlbumList.CurrOperationMode
end

function UMG_TakePhotos_Film_C:ToggleToRemoteTab()
  local ban = false
  ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CLOUD_BACKGROUND_IMAGE, true)
  if ban then
    return
  else
    ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CLOUD_IMAGE, true)
    if ban then
      return
    end
  end
  self:Log("[TakePhoto] Film ToggleToRemoteTab")
  self.CurrAlbumList = self.RemoteAlbumList
  self.CurrAlbumList:Reset()
  self:RefreshModeView()
  self:RefreshTabInfo()
  self.CurrAlbumList:ReloadConditionally()
  self:SetCommonTitle()
end

function UMG_TakePhotos_Film_C:ToggleToLocalTab()
  self:Log("[TakePhoto] Film ToggleToLocalTab")
  self.CurrAlbumList = self.LocalAlbumList
  self.CurrAlbumList:Reset()
  self:RefreshModeView()
  self:RefreshTabInfo()
  self:SetCommonTitle()
end

function UMG_TakePhotos_Film_C:OnDestruct()
  UpdateManager:UnRegister(self)
  self:UnBindInputAction()
  self:SetInputBlockEnabled(false, "RemovePhoto")
  self:SetInputBlockEnabled(false, "UploadPhoto")
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  UE4Helper.ReleaseDesiredShowCursor("UMG_TakePhotos_Film_C")
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnThumbnailTextureGenerated)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingStarted)
  self:GetModule().Controller.PhotoManager:ReleaseThumbnailPool()
end

function UMG_TakePhotos_Film_C:OnLoadingStarted()
  self:Log("[TakePhoto] OnLoadingStarted, close UMG_TakePhotos_Film")
  self:DoClose()
end

function UMG_TakePhotos_Film_C:BindInputAction()
  self:OnAddDynamicIMC()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CloseFirst")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseFirst")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_TakePhotos_Film_C:UnBindInputAction()
  self:OnRemoveDynamicIMC()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseFirst")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CloseFirst")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_TakePhotos_Film_C:OnPcClose()
  if self.CurrAlbumList:InDefaultMode() then
    self:OnBtnExitClicked()
  elseif self.CurrAlbumList:InRemoveMode() then
    self:OnBtnCancelRemoveClicked()
  end
end

function UMG_TakePhotos_Film_C:OnAddEventListener()
  self:AddButtonListener(self._BtnToggleDeleteMode.btnLevelUp, self.OnBtnToggleDeleteModeClicked)
  self:AddButtonListener(self._BtnExit.btnClose, self.OnBtnExitClicked)
  self:AddButtonListener(self._BtnRemoveSelected.btnLevelUp, self.OnBtnRemoveSelectedClicked)
  self:AddButtonListener(self._BtnCancelRemove.btnLevelUp, self.OnBtnCancelRemoveClicked)
  self:AddButtonListener(self.ParticularsBtn1.btnLevelUp, self.OnShowTips)
  self:AddButtonListener(self.TakePhoto.btnLevelUp, self.OnReqTakePhoto)
end

function UMG_TakePhotos_Film_C:OnThumbnailTextureGenerated(PhotoData)
  self.CurrAlbumList:OnThumbnailTextureGenerated(PhotoData)
end

function UMG_TakePhotos_Film_C:OnRemotePhotoFullEstablished()
  self:RefreshModeView()
end

function UMG_TakePhotos_Film_C:SetInputBlockEnabled(bEnable, Reason)
  if bEnable ~= self.bInputBlockedEnabled then
    self.bInputBlockedEnabled = bEnable
    if bEnable then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "UMG_TakePhotos_Film_C:" .. Reason)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "UMG_TakePhotos_Film_C:" .. Reason)
    end
  end
end

function UMG_TakePhotos_Film_C:OnBeginRemovePhotos()
  self:SetInputBlockEnabled(true, "RemovePhoto")
end

function UMG_TakePhotos_Film_C:OnPhotosRemoved()
  if self.bRemovedThisFrame then
    return
  end
  self.bRemovedThisFrame = true
  self:SetInputBlockEnabled(false, "RemovePhoto")
  self:RefreshModeView()
  self:DelayFrames(1, function()
    self.bRemovedThisFrame = false
  end)
end

function UMG_TakePhotos_Film_C:OnBeginUploadPhoto(PhotoData)
  self.CurrAlbumList:RefreshByUploadRefresh(PhotoData)
end

function UMG_TakePhotos_Film_C:OnFinishUploadPhoto(PhotoData, RemotePhotoData)
  self.CurrAlbumList:RefreshByUploadRefresh(PhotoData)
  self:UpdateRemoteTab()
end

function UMG_TakePhotos_Film_C:RefreshModeView()
  local PhotoManager = _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.GetPhotoActivityManager)
  local bInSubmitStatus = PhotoManager:InAlbumSubmitStatus()
  if self.CurrAlbumList:InDefaultMode() then
    self._PanelSelectAll:SetVisibility(UE.ESlateVisibility.Collapsed)
    self._BtnRemoveSelected:SetVisibility(UE.ESlateVisibility.Collapsed)
    self._BtnCancelRemove:SetVisibility(UE.ESlateVisibility.Collapsed)
    if bInSubmitStatus then
      self._BtnToggleDeleteMode:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self._BtnToggleDeleteMode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif self.CurrAlbumList:InRemoveMode() then
    self._PanelSelectAll:SetVisibility(UE.ESlateVisibility.Visible)
    self._BtnRemoveSelected:SetVisibility(UE.ESlateVisibility.Visible)
    self._BtnCancelRemove:SetVisibility(UE.ESlateVisibility.Visible)
    self._BtnToggleDeleteMode:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.CurrAlbumList:BuildDataList()
  self:AdaptSize()
  self:OnUpdateViewRange()
  self.List:InitGridView(self.CurrAlbumList:GetDataList())
  self.UpperLimit:InitNum(self.CurrAlbumList:GetPhotoNum(), self.CurrAlbumList:GetPhotoMaxNum(), self.CurrAlbumList:GetPhotoLimitTitle())
  self:RefreshSelectAllView()
  if self.TakePhoto then
    if self.CurrAlbumList:InRemoveMode() then
      self.TakePhoto:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif not self.bFromTakingPhoto then
      self.TakePhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self.TakePhoto:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
  self:UpdateRemoteTab()
end

function UMG_TakePhotos_Film_C:OnReqTakePhoto()
  self:OnClose()
  DelayManager:DelayFrames(1, function()
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
    _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.TryOpenMainPanel)
  end)
end

function UMG_TakePhotos_Film_C:AdaptSize()
  local ViewportSize = self:GetModule().data:GetScreenSize()
  local RT = self:GetModule().data.TheRT
  if RT then
    ViewportSize = UE.FVector2D(RT.SizeX, RT.SizeY)
  end
  local VXY = ViewportSize.X / ViewportSize.Y
  local FixWidth = 573
  local ThumbnailWidth = FixWidth - 40
  local ThumbnailHeight = ThumbnailWidth / VXY
  local ItemHeight = ThumbnailHeight + 60
  self.ItemDesiredWidth = math.floor(FixWidth)
  self.ItemDesiredHeight = math.floor(ItemHeight)
  self.ThumbnailDesiredWidth = ThumbnailWidth
  self.ThumbnailDesiredHeight = ThumbnailHeight
  self.List:SetCustomSize(self.ItemDesiredWidth, self.ItemDesiredHeight)
end

function UMG_TakePhotos_Film_C:OnItemSelected(SerialId)
  if 0 == SerialId or SerialId > self.CurrAlbumList:GetPhotoNum() then
    self:LogError("invalid serial", SerialId)
    return false
  end
  if self.CurrAlbumList:InRemoveMode() then
    _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_TakePhotos_Film_C:OnItemSelectedRemove")
    self.CurrAlbumList:ToggleSelectFlagBySerialId(SerialId)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_TakePhotos_Film_C:OnItemSelected")
    local PhotoData = self.CurrAlbumList:GetPhotoBySerialId(SerialId)
    local PhotoPath = PhotoData:GetPhotoPath()
    self:Log("\230\159\165\231\156\139\229\164\167\229\155\190", SerialId, PhotoPath)
    if PhotoPath and UE4.UBlueprintPathsLibrary.FileExists(PhotoPath) then
      local PhotoManager = _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.GetPhotoActivityManager)
      local bInSubmitStatus = PhotoManager:InAlbumSubmitStatus()
      local UiData = self.CurrAlbumList:GetDataBySerialId(SerialId)
      if not bInSubmitStatus or UiData and UiData.bActivityRequiredPhoto then
        self:GetModule():ClosePanel("PhotoFileViewUI")
        self:GetModule():PopupPhotoFileView(PhotoData)
      else
        self:Log("Invalid activity require photo", PhotoData.PhotoInfo)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_submit_illegal)
      end
    else
      self:LogWarning("Cannot found photo", PhotoPath)
    end
  end
  self:RefreshSelectAllView()
  return true
end

function UMG_TakePhotos_Film_C:RefreshSelectAllView()
  local bHasNoSelect = self.CurrAlbumList:RefreshSelectAllView()
  if bHasNoSelect or 0 == self.CurrAlbumList:GetPhotoNum() then
    self._ImgSelectRemoveAll:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self._ImgSelectRemoveAll:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  self:RefreshRemoveBtnStatus()
end

function UMG_TakePhotos_Film_C:RefreshRemoveBtnStatus()
  local bHasSelect = self.CurrAlbumList:RefreshRemoveBtnStatus()
  if self._BtnRemoveSelected:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
    if bHasSelect then
      self._BtnRemoveSelected:SetClickAble(true)
    else
      self._BtnRemoveSelected:SetClickAble(false)
    end
  end
end

function UMG_TakePhotos_Film_C:ToggleSelectAllWaitRemove()
  if self.CurrAlbumList:InRemoveMode() then
    local bSelectAll = self.CurrAlbumList:ToggleSelectAllWaitRemove()
    if bSelectAll then
      self._ImgSelectRemoveAll:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self._ImgSelectRemoveAll:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:RefreshRemoveBtnStatus()
    self:OnUpdateViewRange()
    self.List:InitGridView(self.CurrAlbumList:GetDataList())
  end
end

function UMG_TakePhotos_Film_C:UpdateRange()
  local ScrollBox = self.ScrollBox_0
  if ScrollBox then
    local ScrollOffset = ScrollBox:GetScrollOffset()
    local ViewportSize = UE.USlateBlueprintLibrary.GetLocalSize(ScrollBox:GetCachedGeometry())
    local ViewportHeight = ViewportSize.Y
    local StartRow = math.floor(ScrollOffset / self.ItemDesiredHeight)
    local EndRow = math.ceil((ScrollOffset + ViewportHeight) / self.ItemDesiredHeight)
    local ColumnsPerRow = self.List.m_colCount
    local StartIndex = StartRow * ColumnsPerRow
    local EndIndex = (EndRow + 1) * ColumnsPerRow - 1
    StartIndex = math.max(0, StartIndex)
    local bChanged, OldStart, OldEnd = self:GetModule().Controller.PhotoManager.ThumbnailScrollPool:UpdateThumbnailScrollRange(StartIndex, EndIndex)
    if bChanged then
      for i = StartIndex, EndIndex do
        if i < OldStart or i > OldEnd then
          local Data = self.CurrAlbumList:GetDataList()[i + 1]
          if Data then
            self.List:RefreshItemDataByIndex(i)
          end
        end
      end
    end
  else
  end
end

function UMG_TakePhotos_Film_C:OnTick()
  self:UpdateRange()
end

function UMG_TakePhotos_Film_C:OnUpdateViewRange()
  self:UpdateRange()
end

function UMG_TakePhotos_Film_C:RemoveSelection()
  self.CurrAlbumList:RemoveSelection()
  self:RefreshModeView()
end

function UMG_TakePhotos_Film_C:RemoveCurrentInPhotoView(SerialId)
  Log.Debug("RemoveCurrentInPhotoView")
  _G.NRCAudioManager:PlaySound2DAuto(41401009, "UMG_TakePhotos_Film_C:RemoveCurrentInPhotoView")
  if not self:GetModule().data:IfNeedNotifyDelete() then
    self.CurrAlbumList:RemovePhotoBySerialId(SerialId)
  else
    Log.Debug("DisplayDeletePrompt")
    self:GetModule():DisplayDeletePrompt({
      OnConfirm = function()
        Log.Debug("DisplayDeletePrompt OnConfirm")
        if not SerialId then
          return
        end
        if not self.enableView then
          return
        end
        self.CurrAlbumList:RemovePhotoBySerialId(SerialId)
        SerialId = nil
      end
    })
  end
end

function UMG_TakePhotos_Film_C:OnBtnToggleDeleteModeClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnBtnToggleDeleteModeClicked")
  self.CurrAlbumList:ToggleMode()
  self:RefreshModeView()
end

function UMG_TakePhotos_Film_C:OnBtnExitClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_TakePhotos_Film_C:OnMouseButtonDown_ToggleSelectAll")
  self:DoClose()
end

function UMG_TakePhotos_Film_C:OnMouseButtonDown_ToggleSelectAll()
  if self.CurrAlbumList:GetPhotoNum() > 0 then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnMouseButtonDown_ToggleSelectAll")
  end
  self:ToggleSelectAllWaitRemove()
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TakePhotos_Film_C:OnBtnRemoveSelectedClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401009, "UMG_TakePhotos_Film_C:OnBtnRemoveSelectedClicked")
  if not self:GetModule().data:IfNeedNotifyDelete() then
    self:RemoveSelection()
  else
    self:GetModule():DisplayDeletePrompt({
      OnConfirm = function()
        if not self.enableView then
          return
        end
        self:RemoveSelection()
      end
    })
  end
end

function UMG_TakePhotos_Film_C:OnBtnCancelRemoveClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnBtnCancelRemoveClicked")
  self.CurrAlbumList:ToggleToDefault()
  self:RefreshModeView()
end

function UMG_TakePhotos_Film_C:OnPhotoActivitySubmit()
  if self.CurrAlbumList then
    self.CurrAlbumList:RefreshActivityReportedFlag()
  end
end

return UMG_TakePhotos_Film_C
