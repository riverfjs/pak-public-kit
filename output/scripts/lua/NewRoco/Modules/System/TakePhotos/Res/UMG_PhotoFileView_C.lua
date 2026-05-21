local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local CommonUtils = require("NewRoco.Utils.CommonUtils")
local TakePhotoFileManager = require("NewRoco.Modules.System.TakePhotos.Common.TakePhotoFileManager")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_PhotoFileView_C = _G.NRCPanelBase:Extend("UMG_PhotoFileView_C")

function UMG_PhotoFileView_C:OnConstruct()
  self._LeftBtn = self.LeftBtn
  self._RightBtn = self.RightBtn
  self._ShareBtn = self.Btn_share
  self._SaveBtn = self.Btn_conserve
  self._DeleteBtn = self.Delete
  self._WaterMaskPhotoPath = ""
  self.data = self:GetModule().data
  self:OnAddEventListener()
  self._DeleteBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self:UpdateHead()
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    self._ShareBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self._ShareBtn:SetVisibility(UE.ESlateVisibility.Visible)
  end
  self:PCSetting()
  self.bInputBlockedEnabled = false
  self:BindInputAction()
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved, self.OnPhotoRemoved)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnRenderTextureSerialized, self.OnRenderTextureSerialized)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnBeginUploadPhoto, self.OnBeginUploadPhoto)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnFinishUploadPhoto, self.OnFinishUploadPhoto)
  NRCEventCenter:RegisterEvent("UMG_PhotoFileView_C", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  UE4Helper.SetDesiredShowCursor(true, "UMG_PhotoFileView_C")
  if self.Dot_List then
    self.Dot_List:SetItemCanClickChecker(self.CheckCanSelectDotList, self)
  end
  self:CheckShareIsOpen()
  if CommonUtils.IsGameCloudEnv() then
    Log.Debug("[UMG_PhotoFileView_C:OnConstruct] is game cloud env")
    self._SaveBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PhotoFileView_C:OnDestruct()
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved)
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnRenderTextureSerialized)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
  self:UnBindInputAction()
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  UE4Helper.ReleaseDesiredShowCursor("UMG_PhotoFileView_C")
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_TakePhotos_Film_C:Close")
end

function UMG_PhotoFileView_C:OnActive(PhotoData)
  if PhotoData and PhotoData.ExtraInfo then
    self.ExtraInfo = PhotoData.ExtraInfo
  end
  if _G.ONLY_ANIMATION then
    self:LoadAnimation(0)
    return
  end
  self:RefreshByPhotoData(PhotoData)
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_PhotoFileView_C:Tick(MyGeometry, Dt)
  self:UpdateTransform()
end

function UMG_PhotoFileView_C:UpdateTransform()
  if not self.enableView then
    return
  end
  if self.FileTexture then
    local dpi = UE.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    local Width = self.FileTexture:Blueprint_GetSizeX()
    local Height = self.FileTexture:Blueprint_GetSizeY()
    local DesiredViewportSize = self:GetModule().data:GetScreenSize()
    local DeltaWidth = DesiredViewportSize.X / Width
    local DeltaHeight = DesiredViewportSize.Y / Height
    local DesiredHeight = 0
    local DesiredWidth = 0
    local Scale = 1 / dpi
    if math.abs(DeltaWidth) >= math.abs(DeltaHeight) then
      DesiredHeight = DesiredViewportSize.Y * Scale
      DesiredWidth = DesiredHeight * Width / Height
    else
      DesiredWidth = DesiredViewportSize.X * Scale
      DesiredHeight = DesiredWidth * Height / Width
    end
    local CanvasSlot = self.CanvasPanel_69.Slot
    local Padding = CanvasSlot:GetOffsets()
    Padding.Left = -DesiredWidth / 2
    Padding.Top = -DesiredHeight / 2
    Padding.Right = DesiredWidth
    Padding.Bottom = DesiredHeight
    CanvasSlot:SetOffsets(Padding)
  end
end

function UMG_PhotoFileView_C:OnEnterSceneFinishNtyAck()
  self:DoClose()
end

function UMG_PhotoFileView_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  elseif Anim == self:GetAnimByIndex(2) and not self.bDisableAnimationClose then
    self:DoClose()
  end
end

function UMG_PhotoFileView_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CloseSecond")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseSecond")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_PhotoFileView_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseSecond")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CloseSecond")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_PhotoFileView_C:OnPcClose()
  if self.bInputBlockedEnabled then
    return
  end
  self:ReqClose()
end

function UMG_PhotoFileView_C:PCSetting()
  if _G.UE4Helper.IsPCMode() then
    self.Btn_share:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PhotoFileView_C:ReqClose()
  if self.bClosing then
    return
  end
  self.bClosing = true
  NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnPhotoPanelClose)
  self.bDisableAnimationClose = false
  self:LoadAnimation(2)
end

function UMG_PhotoFileView_C:OnAddEventListener()
  self:AddButtonListener(self._LeftBtn, self.OnLeftBtnClicked)
  self:AddButtonListener(self._RightBtn, self.OnRightBtnClicked)
  self:AddButtonListener(self._ShareBtn.btnLevelUp, self.OnShareBtnClicked)
  self:AddButtonListener(self._SaveBtn.btnLevelUp, self.OnSaveBtnClicked)
  self:AddButtonListener(self._DeleteBtn.btnLevelUp, self.OnDeleteBtnClicked)
  self:AddButtonListener(self.Btn_Cloud.btnLevelUp, self.OnReqUploadPhoto)
  self:AddButtonListener(self.PhotoCamera.btnLevelUp, self.OnReqUploadPhotoToCard)
  self:AddButtonListener(self.NRCButton_Bg, function()
    return self:ReqClose()
  end)
  self:AddButtonListener(self.dropOut.btnClose, self.ReqClose)
  self.Switch.OnCheckStateChanged:Add(self, self.RefreshWaterMaskVisibility)
  _G.NRCEventCenter:RegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  if self.PostBtn then
    self:AddButtonListener(self.PostBtn.btnLevelUp, self.RequestReportActivityPhoto)
    self:AddButtonListener(self.AlreadyPosterBtn.btnLevelUp, self.AlreadyReportActivityPhoto)
    self:AddButtonListener(self.RepostBtn.btnLevelUp, self.ReplaceReportActivityPhoto)
    self.AlreadyPosterBtn:SetCommonText(LuaText.pic_game_submit_already)
    self.PostBtn:SetCommonText(LuaText.pic_game_submit_button)
    self.RepostBtn:SetCommonText(LuaText.pic_game_resubmit)
    if self.AlreadyPosterBtn.img_suo then
      self.AlreadyPosterBtn.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoActivitySubmit, self.OnPhotoActivitySubmit)
end

function UMG_PhotoFileView_C:OnDeleteBtnClicked()
  self:OnReqDelete()
end

function UMG_PhotoFileView_C:OnPhotoRemoved(PhotoData, Next)
  if PhotoData == self.PhotoData then
    if not Next then
      self:ReqClose()
    else
      self:RefreshByPhotoData(Next)
      self:RefreshDotList()
    end
  end
end

function UMG_PhotoFileView_C:RefreshWaterMaskVisibility(V)
  if nil ~= V then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:RefreshWaterMaskVisibility")
  end
  if self.PhotoData then
    self.PhotoData:SetWaterMaskEnabled(self.Switch:IsChecked())
  end
  if self.Switch:IsChecked() then
    self.PhotoFile.Text_WaterMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoFile.HeadPortrait:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoFile.Text_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoFile.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoFile.BG:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.PhotoFile.Text_WaterMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoFile.HeadPortrait:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoFile.Text_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoFile.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoFile.BG:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PhotoFileView_C:OnRenderTextureSerialized(PhotoData)
  if PhotoData == self.PhotoData then
    self:RefreshByPhotoData(PhotoData)
  end
end

function UMG_PhotoFileView_C:GetPhotoTexture()
  local Texture = self.PhotoData and self.PhotoData:GetPhotoTexture2D()
  return Texture
end

function UMG_PhotoFileView_C:GetModule()
  return self.module
end

function UMG_PhotoFileView_C:OnLeftBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1060, "UMG_PhotoFileView_C:OnLeftBtnClicked")
  self:DisplayPrevious()
end

function UMG_PhotoFileView_C:OnRightBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1060, "UMG_PhotoFileView_C:OnLeftBtnClicked")
  self:DisplayNext()
end

function UMG_PhotoFileView_C:UpdateHead()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local CardInfo = PlayerInfo.additional_data.card_brief_info
  if CardInfo then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardInfo.card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/", AvatarPath, AvatarPath)
      self.PhotoFile.HeadPortrait:SetPath(AvatarPath)
    end
  else
    Log.Error("\230\178\161\230\156\137\233\187\152\232\174\164\229\144\141\231\137\135\229\164\180\229\131\143\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\144\142\229\143\176\230\149\176\230\141\174")
  end
  self.PhotoFile.Text_Name:SetText(PlayerInfo.name)
  self.PhotoFile.Text_WaterMark:SetText(string.format("UID:%s", PlayerInfo.uin))
end

function UMG_PhotoFileView_C:OnShareBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_TakePhotos_Film_C:OnBtnToggleDeleteModeClicked")
  if not self.PhotoData then
    self:LogWarning("[TakePhoto] PhotoData is nil")
    return
  end
  local PhotoPath = self.PhotoData:GetPhotoPath()
  if not PhotoPath then
    self:LogWarning("[TakePhoto] loading photo", self.PhotoData.SerialId)
    return
  end
  self:OnReqShare()
end

function UMG_PhotoFileView_C:OnSaveBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnBtnToggleDeleteModeClicked")
  if not self.PhotoData then
    self:LogWarning("[TakePhoto] PhotoData is nil")
    return
  end
  local PhotoPath = self.PhotoData:GetPhotoPath()
  if not PhotoPath then
    self:LogWarning("[TakePhoto] loading photo", self.PhotoData.SerialId)
    return
  end
  if not self.PhotoData:IsValidPhoto() then
    return
  end
  local bWaterMaskEnabled = self.PhotoData.bWaterMaskEnabled
  local Names = string.split(PhotoPath, "/")
  local FileName = Names[#Names]
  if bWaterMaskEnabled then
    FileName = string.format("%s1.png", FileName)
  else
    FileName = string.format("%s0.png", FileName)
  end
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  
  local function OnPermissionCallback()
    local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "TempPhotos"
    })
    if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
      UE.UNRCStatics.MakeDirectory(TempPhotos)
    end
    local WaterMaskPhotoPath = UE.UBlueprintPathsLibrary.Combine({TempPhotos, FileName})
    WaterMaskPhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(WaterMaskPhotoPath)
    local Width = self.FileTexture:Blueprint_GetSizeX()
    local Height = self.FileTexture:Blueprint_GetSizeY()
    local DesiredSize = UE.FVector2D(Width, Height)
    self:RefreshInnerWaterMaskImmediate()
    local Result = UE.UPlatformImageLibrary.SaveUserWidgetToImageByCustomSize(UE4Helper.GetCurrentWorld(), self.PhotoFile, WaterMaskPhotoPath, DesiredSize)
    self:CloseInnerWaterMaskImmediate()
    if Result then
      Log.Debug("[TakePhoto] saved", WaterMaskPhotoPath)
      UE.UPlatformImageLibrary.SaveImageToAlbum(WaterMaskPhotoPath)
      if RocoEnv.PLATFORM_WINDOWS then
        if RocoEnv.IS_EDITOR then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\231\188\150\232\190\145\229\153\168\228\191\157\229\173\152\229\136\176:Saved\\PhotoScreenshots")
        elseif RocoEnv.PLATFORM_OPENHARMONY then
          return
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.PC_Photo_Save_Tips)
        end
      elseif RocoEnv.PLATFORM_OPENHARMONY then
        return
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_save_succeed)
      end
    end
  end
  
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.AccessAlbum)
  if not bGranted and (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS) then
    self.requestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.AccessAlbum, {
      self,
      function(_, bGranted)
        self.requestCode = nil
        if bGranted then
          OnPermissionCallback()
        else
          self:LogError("[TakePhotos] !!!Permission!!!")
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_save_fail)
        end
      end
    })
  else
    OnPermissionCallback()
  end
end

function UMG_PhotoFileView_C:OnReqUploadPhoto()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnReqUploadPhoto")
  if not self.PhotoData then
    Log.Error("[TakePhoto] PhotoData is nil")
    return
  end
  if self.panelData then
    self:OnReqUpload()
  end
end

function UMG_PhotoFileView_C:InternalRefreshUploadStatus()
  if not self.PhotoData then
    Log.Error("[TakePhoto] PhotoData is nil")
    return
  end
  local PhotoPath = self.PhotoData:GetPhotoPath()
  if not PhotoPath then
    return
  end
  local Names = string.split(PhotoPath, "/")
  local Name = Names[#Names]
  if self:GetModule().PhotoServer:HasPhotoName(Name) then
    self:Log("PhotoFileView has uploaded photo", Name)
    if not self.UploadedIconPath then
      self.UploadedIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_Share_Cloud2_png.img_Share_Cloud2_png'"
    end
    self.Btn_Cloud:SetPath(self.UploadedIconPath, self.UploadedIconPath, self.UploadedIconPath)
  else
    self:Log("PhotoFileView temp photo", Name)
    if not self.TempUploadIconPath then
      self.TempUploadIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_Share_Cloud1_png.img_Share_Cloud1_png'"
    end
    self.Btn_Cloud:SetPath(self.TempUploadIconPath, self.TempUploadIconPath, self.TempUploadIconPath)
  end
end

function UMG_PhotoFileView_C:OnReqUploadPhotoToCard()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnReqUploadPhotoToCard")
  if not self.PhotoData then
    Log.Error("[TakePhoto] PhotoData is nil")
    return
  end
  if self.panelData then
    self:OnReqUploadCard()
  end
end

function UMG_PhotoFileView_C:CanDisplay(PhotoData)
  local PhotoActivityManager = _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.GetPhotoActivityManager)
  local InAlbumSubmitStatus = PhotoActivityManager and PhotoActivityManager:InAlbumSubmitStatus()
  return not InAlbumSubmitStatus or PhotoActivityManager:CanRequestPhotoData(PhotoData)
end

function UMG_PhotoFileView_C:GetNext()
  return self.PhotoData:GetNext(function(PhotoData)
    return self:CanDisplay(PhotoData)
  end)
end

function UMG_PhotoFileView_C:GetPrevious()
  return self.PhotoData:GetPrevious(function(PhotoData)
    return self:CanDisplay(PhotoData)
  end)
end

function UMG_PhotoFileView_C:RefreshByPhotoData(PhotoData)
  self.PhotoData = PhotoData
  local Next = self:GetNext()
  local Prev = self:GetPrevious()
  if not Next and not Prev then
    self._LeftBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    self._RightBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    if Prev then
      self._LeftBtn:SetVisibility(UE.ESlateVisibility.Visible)
    else
      self._LeftBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if Next then
      self._RightBtn:SetVisibility(UE.ESlateVisibility.Visible)
    else
      self._RightBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  if not self.bInAnimPlayed then
    if self.PhotoData and self.PhotoData:GetPhotoPath() then
      self.bInAnimPlayed = true
      self:LoadAnimation(0)
      self:RefreshDotList()
    else
      self:SetVisibility(UE.ESlateVisibility.Hidden)
    end
  end
  self:InternalRefreshUploadStatus()
  if self:GetPhotoManager():IsRemotePhoto(self.PhotoData) then
    self.Btn_Cloud:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.Btn_Cloud:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  self.FileTexture = self:GetPhotoTexture()
  if self.FileTexture then
    self.PhotoFile.Photo:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(self.FileTexture))
    self.PhotoFile.Photo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoFile.Photo:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.Switch:SetIsChecked(self.PhotoData.bWaterMaskEnabled)
  self:RefreshWaterMaskVisibility()
  if self.ExtraInfo and self.ExtraInfo.bCustomFile then
    self._DeleteBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self._DeleteBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  local bShowPhotoCamera = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if bShowPhotoCamera then
    self.PhotoCamera:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoCamera:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:UpdateTransform()
  self:RefreshActivityReportButtons()
  self:RefreshUploadProgressMask()
end

function UMG_PhotoFileView_C:OnAnimationStarted(Anim)
  if Anim == self:GetAnimByIndex(0) then
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PhotoFileView_C:DisplayNext()
  local Next = self:GetNext()
  if Next then
    self:RefreshByPhotoData(Next)
    self:RefreshDotList()
  end
end

function UMG_PhotoFileView_C:DisplayPrevious()
  local Previous = self:GetPrevious()
  if Previous then
    self:RefreshByPhotoData(Previous)
    self:RefreshDotList()
  end
end

function UMG_PhotoFileView_C:GetPhotoManager()
  return self:GetModule().Controller.PhotoManager
end

function UMG_PhotoFileView_C:OnReqDelete()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Film_C:OnReqDelete")
  self.PhotoData:OnReqDelete()
end

function UMG_PhotoFileView_C:OnReqUpload()
  if not self.PhotoData:IsUploadFinish() then
    return
  end
  self.PhotoData:OnReqUpload()
end

function UMG_PhotoFileView_C:OnBeginUploadPhoto(PhotoData)
  self:RefreshUploadProgressMask()
end

function UMG_PhotoFileView_C:OnFinishUploadPhoto(PhotoData, RemotePhotoData)
  if RemotePhotoData and PhotoData == self.PhotoData then
    self:InternalRefreshUploadStatus()
  end
  self:RefreshUploadProgressMask()
end

function UMG_PhotoFileView_C:RefreshUploadProgressMask()
  if self.PhotoData:IsUploadFinish() then
    self:ToggleUploadProgressMask(false)
  else
    self:ToggleUploadProgressMask(true)
  end
end

function UMG_PhotoFileView_C:OnReqUploadCard()
  if not self.PhotoData:IsUploadFinish() then
    return
  end
  self.PhotoData:OnReqUploadCard()
end

function UMG_PhotoFileView_C:OnReqShare()
  self.PhotoData:OnReqShare()
  self:DispatchEvent(TakePhotosModuleEvent.OnPhotoFileShared, self.PhotoData)
end

function UMG_PhotoFileView_C:CheckCanSelectDotList()
  return self.bEnableDotListSelect
end

function UMG_PhotoFileView_C:RefreshDotList()
  if not self.Dot_List then
    return
  end
  local SectionList = self.PhotoData.SectionList
  local Num = SectionList and #SectionList or 0
  if Num > 1 and not self.PhotoData.bDisableSectionDots then
    local FakeDataList = {}
    local SelectedIndex = 1
    for i, Data in pairs(SectionList) do
      if Data == self.PhotoData then
        SelectedIndex = i
      end
      table.insert(FakeDataList, {})
    end
    self.Dot_List:InitGridView(FakeDataList)
    self.bEnableDotListSelect = true
    self.Dot_List:SelectItemByIndex(SelectedIndex - 1)
    self.bEnableDotListSelect = false
    self.Dot_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Dot_List:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PhotoFileView_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = false
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PhotoFileView_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PhotoFileView_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_PHOTO
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  if self.ShareIsOpen then
    self.Btn_share:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Btn_share:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PhotoFileView_C:ToggleUploadProgressMask(bEnabled)
  if bEnabled == self.bEnabledUploadMask then
    return
  end
  self.bEnabledUploadMask = bEnabled
  local LoadUpload = self.PhotoFile.UMG_LoadUpload
  if not LoadUpload then
    return
  end
  LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if bEnabled then
    LoadUpload:SetCardUploading()
  else
    LoadUpload:StopAllAnimations()
  end
end

function UMG_PhotoFileView_C:OnPhotoActivitySubmit()
  self:RefreshActivityReportButtons()
end

function UMG_PhotoFileView_C:RefreshActivityReportButtons()
  local PhotoActivityManager = _G.NRCModuleManager:DoCmd(TakePhotosModuleCmd.GetPhotoActivityManager)
  local InActivitySubmitStatus = PhotoActivityManager and PhotoActivityManager:InAlbumSubmitStatus() and PhotoActivityManager:CanRequestPhotoData(self.PhotoData)
  if self.Switcher then
    if InActivitySubmitStatus then
      self.ZHAOPIAN:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.HorizontalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.Switcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      if PhotoActivityManager:IsPhotoDataHasBeenSubmit(self.PhotoData) then
        self.Switcher:SetActiveWidgetIndex(1)
      else
        local SubmitContent = PhotoActivityManager:GetSubmitContest()
        if SubmitContent then
          self.Switcher:SetActiveWidgetIndex(2)
        else
          self.Switcher:SetActiveWidgetIndex(0)
        end
      end
      self.Switch:SetIsChecked(false)
      self:RefreshWaterMaskVisibility()
    else
      self.ZHAOPIAN:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.HorizontalBox_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.Switcher:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PhotoFileView_C:RequestReportActivityPhoto()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PhotoFileView_C:RequestReportActivityPhoto")
  if not self.PhotoData:IsUploadFinish() then
    return
  end
  Log.Debug("RequestReportActivityPhoto")
  self.PhotoData:OnReqUploadReport()
end

function UMG_PhotoFileView_C:AlreadyReportActivityPhoto()
  if not self.PhotoData:IsUploadFinish() then
    return
  end
  Log.Debug("AlreadyReportActivityPhoto")
  self.PhotoData:OnReqUploadReport()
end

function UMG_PhotoFileView_C:ReplaceReportActivityPhoto()
  if not self.PhotoData:IsUploadFinish() then
    return
  end
  Log.Debug("ReplaceReportActivityPhoto")
  self.PhotoData:OnReqUploadReport()
end

function UMG_PhotoFileView_C:RefreshInnerWaterMaskImmediate()
  self.Mark = self.PhotoFile.Mark
  self.MarkCanvas = self.PhotoFile.MarkCanvas
  UIUtils.RefreshWaterMaskImmediate(self)
end

function UMG_PhotoFileView_C:CloseInnerWaterMaskImmediate()
  self.MarkCanvas:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return UMG_PhotoFileView_C
