local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TakePhotosModule = NRCModuleBase:Extend("TakePhotosModule")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local TakePhotosModeMgr = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeMgr")
local MainUIModuleEnum = require("NewRoco/Modules/System/MainUI/MainUIModuleEnum")
local PhotoServer = require("NewRoco/Modules/System/TakePhotos/Helper/PhotoServer")
local TakePhotoControl = require("NewRoco/Modules/System/TakePhotos/Controller/TakePhotoControl")
local PhotoFileDefine = require("NewRoco.Modules.System.TakePhotos.Helper.PhotoFileDefine")
local PhotoActivityManager = require("NewRoco.Modules.System.TakePhotos.Helper.PhotoActivityManager")
local PhotoCacheDefine = require("NewRoco.Modules.System.TakePhotos.Common.PhotoCacheDefine")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")

function TakePhotosModule:OnConstruct()
  _G.TakePhotosModuleCmd = reload("NewRoco.Modules.System.TakePhotos.TakePhotosModuleCmd")
  _G.TakePhotosEnum = reload("NewRoco.Modules.System.TakePhotos.TakePhotosEnum")
  self.data = self:SetData("TakePhotosModuleData", "NewRoco.Modules.System.TakePhotos.TakePhotosModuleData")
  self:RegPanel("TakePhotosMainUI", "UMG_TakePhotos_New", Enum.UILayerType.UI_LAYER_MAIN, "In", "Out")
  self:RegPanel("PopupPhotoMomentUI", "UMG_TakePhotos_Moment", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PhotoHistoryUI", "UMG_TakePhotos_Film", Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("PhotoFileViewUI", "UMG_PhotoFileView", Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("UMG_PhotoFrame", "UMG_PhotoFrame", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("UMG_PhotoFrame_Open", "UMG_PhotoFrame_Open", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("UMG_DeletePrompt", "UMG_DeletePrompt", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_PhotoCropping", "UMG_PhotoCropping", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, 2, true)
  if _G.RocoEnv.IS_EDITOR then
    local path = "/Game/NewRoco/Modules/System/TakePhotos/Editor/UMG_TakePhotosRiderEditor"
    self:RegPanel("UMG_TakePhotosRiderEditor", "UMG_TakePhotosRiderEditor", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, nil, path)
  end
  self.ScreenShotService = UE4.UMoreFunPlatformKits.CreateScreenShotService()
  self.ScreenShotServiceRef = UnLua.Ref(self.ScreenShotService)
  self.ModeMgr = TakePhotosModeMgr()
  self.bMakingPhoto = false
  self.PhotoServer = PhotoServer(self)
  self.Controller = TakePhotoControl(self)
  self.PhotoActivityManager = PhotoActivityManager(self)
  self.data:InitSaveData()
end

function TakePhotosModule:RegPanel(name, path, layer, openAnimName, closeAnimName, customDisableRendering, touchCount, isSingleTouchPanel, customPath)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = customPath or string.format("/Game/NewRoco/Modules/System/TakePhotos/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.touchCount = touchCount
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = false
  self:RegisterPanel(registerData)
  return registerData
end

function TakePhotosModule:OnActive()
  self:RegisterEvent(self, TakePhotosModuleEvent.OnExitTakePhotos, self.OnExitTakePhotos)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnEnterTakePhotos, self.OnEnterTakePhotos)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnRemotePhotoFullEstablished, self.OnRemotePhotoFullEstablished)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnBeginTakingPhotos, self.ExecCmdWithBeforeCapture)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnFinishTakingPhotos, self.ExecCmdWithFinishCapture)
  _G.NRCEventCenter:RegisterEvent("TakePhotosModule", self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:RegisterEvent("TakePhotosModule", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:RegisterEvent("TakePhotosModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("TakePhotosModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  if not _G.ZoneServer:IsUpstreamLocked() then
    self:OnEnterSceneFinishNtyAck()
  end
  PhotoCacheDefine:UpdateFileCaches()
end

function TakePhotosModule:OnRelogin()
end

function TakePhotosModule:OnDeactive()
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnExitTakePhotos)
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnEnterTakePhotos)
  self:UnRegisterEvent(self, TakePhotosModuleEvent.OnRemotePhotoFullEstablished)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  self.Controller:OnDestroy()
end

function TakePhotosModule:OnEnterSceneFinishNtyAck()
  self.Controller:OnEnterSceneFinish()
  self:ExitTakePhotos()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.statComponent then
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO)
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF)
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD)
  end
end

function TakePhotosModule:OnEnterSceneFinishNtyAckEnd()
  self.PhotoServer:OnEnterSceneFinish()
  self.ModeMgr.TakePhotosModeTripod:OnEnterSceneFinish()
end

function TakePhotosModule:OnDestruct()
end

function TakePhotosModule:OpenRideEditor()
  if _G.RocoEnv.IS_EDITOR and not self.ModeMgr:IsNoneMode() then
    self:OpenPanel("UMG_TakePhotosRiderEditor")
  end
end

function TakePhotosModule:OpenDebugPanel()
  self:OpenPanel("TakePhotosDebugUI")
end

function TakePhotosModule:CloseDebugPanel()
  self:ClosePanel("TakePhotosDebugUI")
  self.data:Clear()
end

function TakePhotosModule:TryOpenMainPanel()
  if not self.data:IsSaveGameDataReady() then
    return false
  end
  if self:IsDisplayingPhotoFile() then
    return
  end
  return self:InternalEnterTakePhoto()
end

function TakePhotosModule:OnOpenPanel(PanelData)
  local Name = PanelData.panelName
  if "TakePhotosMainUI" == Name or "PhotoHistoryUI" == Name then
    self.data:AddRef()
  end
end

function TakePhotosModule:OnClosePanel(PanelData)
  local Name = PanelData.panelName
  if "TakePhotosMainUI" == Name or "PhotoHistoryUI" == Name then
    self.data:RemoveRef()
    self:ClosePanel("UMG_PhotoFrame_Open")
  end
end

function TakePhotosModule:InternalOpenPhotoFrame(Command, OnFinish, LockConditionDelegate)
  local PanelName = "UMG_PhotoFrame"
  if "Enter" == Command then
    PanelName = "UMG_PhotoFrame_Open"
  end
  if self:HasPanel(PanelName) then
    local panel = self:GetPanel(PanelName)
    if panel then
      panel:OnActive(Command, OnFinish, LockConditionDelegate)
    end
  end
  self:ClosePanel(PanelName)
  self:OpenPanel(PanelName, Command, OnFinish, LockConditionDelegate)
end

function TakePhotosModule:InternalEnterTakePhoto()
  return self.Controller:Enter()
end

function TakePhotosModule:InternalSwitchTakePhoto(OnFinish)
  self:InternalOpenPhotoFrame("Switch", OnFinish)
end

function TakePhotosModule:InternalWorldPreviewTakePhoto(OnFinish)
  self:InternalOpenPhotoFrame("World", OnFinish)
end

function TakePhotosModule:SetForbidRelation(bForbid)
  if bForbid ~= self.bForbidRelationSetting then
    self.bForbidRelationSetting = bForbid
    self:Log("[TakePhoto] SetForbidRelation", bForbid)
    if bForbid then
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetGlobalPetHUDEnabled, false)
      local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
      if MainUIModule then
        MainUIModule:SetGlobalPlayerHudEnabled(false, _G.MainUIModuleEnum.DisableHudOpSource.GlobalForbid)
        MainUIModule:OnCmdIsShowPropTips(false, "TakePhoto")
        MainUIModule:OnCmdIsShowDownTips(false, "TakePhoto")
        MainUIModule:SetRewardTipsEnabled(false, MainUIModuleEnum.RewardTipsDisableReason.TakePhoto)
      end
      self:OpenWithCmd()
      self.ModeMgr:SetTipsEnabled(false)
    else
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetGlobalPetHUDEnabled, true)
      local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
      if MainUIModule then
        MainUIModule:SetGlobalPlayerHudEnabled(true, _G.MainUIModuleEnum.DisableHudOpSource.GlobalForbid)
        MainUIModule:OnCmdIsShowPropTips(true, "TakePhoto")
        MainUIModule:OnCmdIsShowDownTips(true, "TakePhoto")
        MainUIModule:SetRewardTipsEnabled(true, MainUIModuleEnum.RewardTipsDisableReason.TakePhoto)
      end
      self:CloseWithCmd()
      self.ModeMgr:SetTipsEnabled(true)
    end
  end
end

function TakePhotosModule:CloseWithCmd()
end

function TakePhotosModule:OpenWithCmd()
end

function TakePhotosModule:ExecCmdWithBeforeCapture()
  Log.Debug("ExecCmdWithBeforeCapture")
  UE4.UNRCStatics.ExecConsoleCommand("g.GCloseInstanceByEnterQueue 1")
  if self.DelayFinishCaptureCmd then
    _G.DelayManager:CancelDelayById(self.DelayFinishCaptureCmd)
    self.DelayFinishCaptureCmd = nil
  end
end

function TakePhotosModule:ExecCmdWithFinishCapture()
  Log.Debug("ExecCmdWithFinishCapture")
  if self.DelayFinishCaptureCmd then
    _G.DelayManager:CancelDelayById(self.DelayFinishCaptureCmd)
    self.DelayFinishCaptureCmd = nil
  end
  self.DelayFinishCaptureCmd = _G.DelayManager:DelayFrames(1, function()
    Log.Debug("ExecCmdWithFinishCapture Ready")
    self.DelayFinishCaptureCmd = nil
    UE4.UNRCStatics.ExecConsoleCommand("g.GCloseInstanceByEnterQueue 0")
  end)
end

function TakePhotosModule:OnEnterTakePhotos()
  self:Log("[TakePhoto] OnEnterTakePhotos")
end

function TakePhotosModule:OnExitTakePhotos()
  self:Log("[TakePhoto] OnExitTakePhotos")
  self.ModeMgr:CleanupTakePhotos()
  self:ClosePanel("UMG_PhotoFrame_Open")
  if self.DelayTakingPhotoHandle then
    DelayManager:CancelDelayById(self.DelayTakingPhotoHandle)
    self.DelayTakingPhotoHandle = nil
  end
end

function TakePhotosModule:OnRemotePhotoFullEstablished()
  self.Controller.PhotoManager:UpdateRemoteBriefList(self.PhotoServer.AlbumFileList)
end

function TakePhotosModule:IfInTakePhotoState(bExcludeWorldPreview)
  if not bExcludeWorldPreview then
    return self.ModeMgr.CurrMode ~= nil or nil ~= self.ModeMgr.pendingMode
  else
    return self.ModeMgr:IsTripodMode() or self.ModeMgr:Is1PMode()
  end
  return false
end

function TakePhotosModule:IfInTakePhotoHandledMode()
  return self.ModeMgr:Is1PMode()
end

function TakePhotosModule:IfInTakePhotoTripodMode()
  return self.ModeMgr:IsTripodMode()
end

function TakePhotosModule:IfInTakePhotoWorldPreviewMode()
  return self.ModeMgr:IsWorldMode()
end

function TakePhotosModule:TransitTo1P()
  return self.Controller:TransitTo(self.ModeMgr.TakePhotosMode1P)
end

function TakePhotosModule:TransitSelfie()
  return self.Controller:TransitTo(self.ModeMgr.TakePhotosModeSelfie)
end

function TakePhotosModule:TransitToTripod()
  return self.Controller:TransitTo(self.ModeMgr.TakePhotosModeTripod)
end

function TakePhotosModule:TransitToWorld()
  return self.Controller:TransitTo(self.ModeMgr.TakePhotosModeWorld)
end

function TakePhotosModule:UpdatePhotoBigTexture(PhotoPath)
  local Texture = self.data.ThePhotoBigTexture
  if Texture and UE.UObject.IsValid(Texture) and UE.UPlatformImageLibrary.UpdateTexture2DByFile and UE.UPlatformImageLibrary.UpdateTexture2DByFile(Texture, PhotoPath) then
    Log.Debug("[TakePhoto] UpdatePhotoBigTexture", PhotoPath)
    return Texture
  end
  Log.Debug("[TakePhoto] ImportFileAsTexture2D", PhotoPath)
  self.data.ThePhotoBigTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(UE4Helper.GetCurrentWorld(), PhotoPath)
  if self.data.ThePhotoBigTextureRef and UE.UObject.IsValid(self.data.ThePhotoBigTextureRef) then
    UnLua.Unref(self.data.ThePhotoBigTextureRef)
  end
  self.data.ThePhotoBigTextureRef = self.data.ThePhotoBigTexture and UnLua.Ref(self.data.ThePhotoBigTexture)
  return self.data.ThePhotoBigTexture
end

function TakePhotosModule:SharePhoto(Way)
  self:DispatchEvent(TakePhotosModuleEvent.OnReqSharePhoto, Way)
end

function TakePhotosModule:OpenPhotosHistoryPanel(bFromOther, bFromActivity)
  if not self.data:IsSaveGameDataReady() then
    return
  end
  self.bInRemoteHistory = bFromOther
  if bFromOther or bFromActivity then
    self:ClosePanel("PhotoHistoryUI")
  end
  self.PhotoActivityManager:ToggleAlbumSubmitStatus(bFromActivity)
  self:OpenPanel("PhotoHistoryUI", not self.bInRemoteHistory)
end

function TakePhotosModule:OpenPhotosRemoteHistoryPanel()
  self:OpenPhotosHistoryPanel(true)
end

function TakePhotosModule:OpenPhotosActivityAlbumPanel()
  if not self.Controller.PhotoManager:AnyPhotoCanReportActivity() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_submit_no_photo, nil, nil, 2)
    return
  end
  if self.PhotoActivityManager:InSubmitCoolDown(true) then
    return
  end
  if not self.PhotoActivityManager:CanRequestContestSubmit() then
    Log.Error(" Invalid activity photo stage ")
    return
  end
  self:OpenPhotosHistoryPanel(false, true)
end

function TakePhotosModule:PopupCustomPhotoFileView(CustomFilePath, DoUpload, ExtraInfo)
  local PhotoData = self.Controller.PhotoManager:AddPhotoByCustomUpload(CustomFilePath, DoUpload)
  self.PhotoActivityManager:ToggleAlbumSubmitStatus(false)
  self:PopupPhotoFileView(PhotoData, ExtraInfo)
end

function TakePhotosModule:PopupTakingPhotoFileView(PhotoData, ExtraInfo)
  self.PhotoActivityManager:ToggleAlbumSubmitStatus(false)
  self:PopupPhotoFileView(PhotoData, ExtraInfo)
end

function TakePhotosModule:PopupPhotoFileView(PhotoData, ExtraInfo)
  if self:HasPanel("PhotoFileViewUI") then
    local panel = self:GetPanel("PhotoFileViewUI")
    if panel then
      if ExtraInfo then
        panel.ExtraInfo = ExtraInfo
      end
      panel:RefreshByPhotoData(PhotoData)
    end
  else
    if ExtraInfo then
      PhotoData.ExtraInfo = ExtraInfo
    end
    self:OpenPanel("PhotoFileViewUI", PhotoData)
  end
end

function TakePhotosModule:TryExitTakePhotoByTripodDestroyed()
  if self.ModeMgr:IsTripodAvailableMode() and self.ModeMgr.TakePhotosModeTripod:IfThinkNpcDestroyedEffect() then
    self:Log("[TakePhoto] npc destroyed passively, exit take photos...")
    self:ClosePanel("TakePhotosMainUI")
  else
  end
end

function TakePhotosModule:ExitTakePhotos()
  self:LogWarning("[TakePhoto] ExitTakePhotos manually")
  self:ClosePanel("TakePhotosMainUI")
end

function TakePhotosModule:DispatchEvent(eventName, ...)
  self.eventDispatcher:SendEvent(eventName, ...)
  NRCEventCenter:DispatchEvent(eventName, ...)
end

function TakePhotosModule:DisplayDeletePrompt(Data)
  if self:HasPanel("UMG_DeletePrompt") then
    return
  end
  self:OpenPanel("UMG_DeletePrompt", Data)
end

function TakePhotosModule:OpenSharePhotoPanel(PhotoPath, bWaterMaskEnabled, CustomData, Md5)
  if not PhotoPath then
    Log.Error("Invalid PhotoPath")
    return
  end
  if not UE.UNRCStatics.FileExists(PhotoPath) then
    Log.Error("Invalid PhotoPath", PhotoPath)
    return
  end
  local photoData = {
    PhotoPath = PhotoPath,
    bWaterMaskEnabled = bWaterMaskEnabled,
    CustomData = CustomData,
    Md5 = Md5
  }
  Log.Debug("TakePhotosModule:OpenSharePhotoPanel", PhotoPath, Md5, bWaterMaskEnabled, CustomData)
  local shareBaseId = _G.Enum.ShareButtonType.SBT_PHOTO
  local sharePartId = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartIdByShareBaseId, shareBaseId)
  local shareData = {
    shareBaseId = shareBaseId,
    sharePartId = sharePartId,
    photoData = photoData
  }
  _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, shareData)
end

function TakePhotosModule:ReportTLog(RealBurstNum, bQuickShot)
  local key = "PhotographLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  local playerLocationStr = string.format("%d|%d|%d", math.floor(playerLocation.X), math.floor(playerLocation.Y), math.floor(playerLocation.Z))
  RealBurstNum = RealBurstNum or 1
  self.data.CurPhotoMode = 0
  if bQuickShot then
    self.data.CurPhotoMode = 5
  elseif not self.ModeMgr:IsNoneMode() then
    if self.ModeMgr:Is1PMode() then
      self.data.CurPhotoMode = 1
    elseif self.ModeMgr:IsSelfieMode() then
      self.data.CurPhotoMode = 2
    else
      self.data.CurPhotoMode = 4
    end
  end
  local Type = self.data.CurPhotoMode
  local Settings = self.Controller.TakePhotoSettings
  local LastSeconds = Settings and Settings:GetTakePhotoCountDownSeconds() or 0
  local PlayerWatchCamera = Settings and Settings.PlayerLookCamera:IsEnabled() and 1 or 0
  local PetWatchCamera = Settings and Settings.PetLookCamera:IsEnabled() and 1 or 0
  local WithPartner = (player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) or player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST)) and 1 or 0
  local WithPet = player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL) and 1 or 0
  local PhotoManager = self.Controller.PhotoManager
  local Pose = Settings and Settings:GetSelectedPoseId() or 0
  local Emoji = Settings and Settings:GetSelectedEmojiId() or 0
  local Filter = Settings and Settings:GetSelectedFilterId() or 0
  local PhotoCount = PhotoManager and PhotoManager:GetLocalPhotoNum()
  local CloudPhotoCount = PhotoManager and PhotoManager:GetRemotePhotoNum()
  local value = string.format("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", key, roleDataStr, playerLocationStr, Type, RealBurstNum, LastSeconds, PlayerWatchCamera, PetWatchCamera, WithPartner, WithPet, Pose, Emoji, Filter, PhotoCount, CloudPhotoCount)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function TakePhotosModule:OpenPhotoCroppingPanel(Texture, ConfirmCallback, bUploadToCard, ClipPhoto)
  self:OpenPanel("UMG_PhotoCropping", Texture, ConfirmCallback, bUploadToCard, ClipPhoto)
end

function TakePhotosModule:DownloadCard(Url, Callback)
  self.PhotoServer:ReqDownloadCard(Url, Callback)
end

function TakePhotosModule:UploadCard(FilePath, Callback)
  local function OnUploadFinish(bSuccess, ...)
    if bSuccess then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.rolecard_photo_upload_succeed)
    else
      local args = {
        ...
      }
      if #args > 1 and args[2] then
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.rolecard_photo_upload_failed)
      end
    end
    Callback(bSuccess, ...)
  end
  
  self.PhotoServer:ReqUploadTempPhoto(FilePath, ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_CARD, OnUploadFinish)
end

function TakePhotosModule:GetPetLookLensTarget()
  return self.Controller:GetPetLookLensTarget()
end

function TakePhotosModule:IsPetLookLensTargetEnabled()
  return self.Controller:IsPetLookLensTargetEnabled()
end

function TakePhotosModule:GetIdentifyLookViewInfo()
  return self.Controller:GetIdentifyLookViewInfo()
end

function TakePhotosModule:IsDisplayingPhotoFile()
  if self.DelayShotCut then
    return true
  end
  local bLoading = NRCPanelManager:IsLoadingPanel("TakePhotosModule", "PhotoFileViewUI")
  if bLoading then
    return true
  end
  local bHasPanel = self:HasPanel("PhotoFileViewUI")
  if bHasPanel then
    return true
  end
  bLoading = NRCPanelManager:IsLoadingPanel("TakePhotosModule", "PopupPhotoMomentUI")
  if bLoading then
    return true
  end
  bHasPanel = self:HasPanel("PopupPhotoMomentUI")
  if bHasPanel then
    return true
  end
  return false
end

function TakePhotosModule:QuickShotCut()
  if not self.data:IsSaveGameDataReady() then
    Log.Debug("UMG_LobbyMain_C:Photo NotDataReady")
    return false
  end
  if self:IsDisplayingPhotoFile() then
    Log.Debug("UMG_LobbyMain_C:Photo IsDisplayingPhotoFile")
    return
  end
  local bBan = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, true, true)
  if bBan then
    return false
  end
  if self.Controller.PhotoManager:IsLocalPhotosFull() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_storage_max_tips)
    return false
  end
  _G.NRCAudioManager:PlaySound2DAuto(40009004, "QuickShotCut")
  local Data = self.data
  local Size = Data:GetScreenSize()
  local RT, RtRef = self.data:CreateRT(Size)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraManager = player:GetUEController().playerCameraManager
  self:SetForbidRelation(true)
  self:ExecCmdWithBeforeCapture()
  cameraManager:StartCaptureImmediately(RT)
  self:ExecCmdWithFinishCapture()
  self:SetForbidRelation(false)
  self.DelayShotCut = _G.DelayManager:DelayFrames(1, function()
    self.DelayShotCut = nil
    assert(RT)
    assert(RtRef)
    assert(UE.UObject.IsValid(RT))
    local PhotoData = self.Controller.PhotoManager:AddPhotoByTakingPhoto(RT)
    if not PhotoData then
      RtRef = nil
      UnLua.Unref(RT)
      return
    end
    PhotoData:AttachSection({})
    PhotoData.OnRenderTextureSerialized:Add(self, function(_)
      RtRef = nil
      UnLua.Unref(RT)
    end)
    local PhotoInfo = self:CheckPhotoInfoImmediately()
    PhotoData:SetPhotoInfo(PhotoInfo)
    self:OpenPanel("PopupPhotoMomentUI", function()
      self:PopupTakingPhotoFileView(PhotoData)
    end)
    self:ReportTLog(1, true)
  end)
  return true
end

function TakePhotosModule:CheckPhotoInfoImmediately()
  local PhotoInfo = _G.ProtoMessage:newPlayerPhotoAlbumInfo()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local radius = localPlayer:GetRadius()
  local halfH = localPlayer:GetHalfHeight()
  local playerExtent = UE.FVector(radius, radius, halfH)
  local world = UE4Helper.GetCurrentWorld()
  local worldOriginal = UE.FVector(world:GetWorldOriginX(), world:GetWorldOriginY(), world:GetWorldOriginZ())
  local IdentifyPos = localPlayer:GetActorLocation()
  local CameraLocation, CameraRotation, ViewInfo, IdentifyCameraFOV = self:GetIdentifyLookViewInfo()
  local bInView = false
  if self.ModeMgr:Is1PMode() then
    bInView = false
  else
    bInView = UE.UNRCStatics.IsBoxInCustomFrustumVolume and UE.UNRCStatics.IsBoxInCustomFrustumVolume(IdentifyPos - worldOriginal, playerExtent, ViewInfo)
    local TargetHitResult, bTargetHit = UE.UKismetSystemLibrary.Abs_LineTraceSingle(world, CameraLocation, IdentifyPos, UE.ETraceTypeQuery.Visibility, false, {
      localPlayer.viewObj
    }, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 0.1)
    if bTargetHit then
      bInView = false
      Log.Debug("[TakePhoto] Player Collision", TargetHitResult.Actor and TargetHitResult.Actor:GetName())
    end
  end
  PhotoInfo.include_myself = bInView
  PhotoInfo.pet_base_id_list = {}
  do
    local IdentifyDistance = TakePhotosEnum.TPGlobalNum("takephoto_check_distance_max")
    local CameraViewBoxExtent = UE.FVector(0, 0, 0)
    local CameraFOV = UE.FVector2D(0, 0)
    if UE.UNRCStatics.GetFrustumBoundingExtent(ViewInfo, 0, IdentifyDistance, CameraViewBoxExtent, CameraFOV) then
      local CameraForward = UE.UKismetMathLibrary.GetForwardVector(CameraRotation)
      local CameraViewBoxCenter = CameraLocation + CameraForward * IdentifyDistance - worldOriginal
      local BoxOverlapCache = self.BoxOverlapCache or UE.TArray(UE.AActor)
      BoxOverlapCache:Clear()
      UE.UNRCStatics.BoxOverlapMultiByObjectType(world, CameraRotation:ToQuat(), BoxOverlapCache, CameraViewBoxCenter, CameraViewBoxExtent, UE.EObjectTypeQuery.Pawn)
      UE.UNRCStatics.BoxOverlapMultiByObjectType(world, CameraRotation:ToQuat(), BoxOverlapCache, CameraViewBoxCenter, CameraViewBoxExtent, UE.EObjectTypeQuery.Character)
      self.BoxOverlapCache = BoxOverlapCache
      local Overlaps = {}
      local OverrideConfigs = {}
      local OverlapSet = {}
      for i, Overlap in tpairs(BoxOverlapCache) do
        if not OverlapSet[Overlap] and not Overlap.bHidden and Overlap:WasRecentlyRendered(0.2) then
          local SceneCharacter = Overlap.sceneCharacter
          if SceneCharacter and SceneCharacter.IsPet and SceneCharacter:IsPet() then
            table.insert(Overlaps, Overlap)
            OverlapSet[Overlap] = true
          elseif Overlap.Rider then
            local HitScenePlayerPet = Overlap.Rider.BP_RideComponent.ScenePet
            if HitScenePlayerPet then
              OverrideConfigs[Overlap] = HitScenePlayerPet.config
              table.insert(Overlaps, Overlap)
              OverlapSet[Overlap] = true
            end
          end
        end
      end
      
      local function SortCandidateOverlap(A, B)
        local VA = A:Abs_K2_GetActorLocation() - CameraLocation
        local VB = B:Abs_K2_GetActorLocation() - CameraLocation
        local DisA = VA:Size()
        local DisB = VB:Size()
        local WeightA = VA:Dot(CameraForward) / DisA
        local WeightB = VB:Dot(CameraForward) / DisB
        return WeightA > WeightB
      end
      
      table.sort(Overlaps, SortCandidateOverlap)
      local ActorToIgnores
      local DesiredMaxiNum = TakePhotosEnum.TPGlobalNum("takephoto_identify_pet_max", 1)
      for i, Overlap in ipairs(Overlaps) do
        local SceneCharacter = Overlap.sceneCharacter
        local PetBaseConf = OverrideConfigs[Overlap] or SceneCharacter and SceneCharacter:GetConfPetData()
        if PetBaseConf then
          ActorToIgnores = nil
          if self.ModeMgr:Is1PMode() or self.ModeMgr:IsSelfieMode() then
            ActorToIgnores = {
              localPlayer.viewObj
            }
          end
          bInView = UE.UNRCStatics.IsPointInCustomFrustumVolume(Overlap:K2_GetActorLocation(), ViewInfo)
          if bInView then
            if not ActorToIgnores then
              ActorToIgnores = {Overlap}
            else
              table.insert(ActorToIgnores, Overlap)
            end
            local TargetHitResult, bTargetHit = UE.UKismetSystemLibrary.Abs_LineTraceSingle(world, CameraLocation, Overlap:Abs_K2_GetActorLocation(), UE.ETraceTypeQuery.Visibility, false, ActorToIgnores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 0.1)
            if not bTargetHit then
              table.insert(PhotoInfo.pet_base_id_list, PetBaseConf.id)
              if _G.RocoEnv.IS_EDITOR then
                Log.Debug("[TakePhoto] Capture pet base id", PetBaseConf.id, Overlap:GetFullName())
              else
                Log.Debug("[TakePhoto] Capture pet base id", PetBaseConf.id, Overlap:GetName())
              end
              if DesiredMaxiNum <= #PhotoInfo.pet_base_id_list then
                break
              end
            end
          end
        end
      end
      BoxOverlapCache:Clear()
    end
  end
  return PhotoInfo
end

function TakePhotosModule:OnCmdGetCurPhotoMode()
  return self.data.CurPhotoMode
end

function TakePhotosModule:ZoneAddPetRecordAndShareReq(PetBaseId)
  local Req = _G.ProtoMessage:newZoneAddPetRecordAndShareReq()
  Req.base_id = PetBaseId
  Log.Debug("ZoneAddPetRecordAndShareReq", PetBaseId)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PET_RECORD_AND_SHARE_REQ, Req, self, self.OnZoneAddPetRecordAndShareRsp)
end

function TakePhotosModule:OnZoneAddPetRecordAndShareRsp(Rsp)
  Log.Debug("OnZoneAddPetRecordAndShareRsp", Rsp.ret_info and Rsp.ret_info.ret_code)
end

function TakePhotosModule:IsPetInHandbook(PetBaseId)
  return self.data:IsPetInHandbook(PetBaseId)
end

function TakePhotosModule:OnCmdSyncPhotoToken(Notify)
  if Notify then
    self:DispatchEvent(TakePhotosModuleEvent.OnSyncPhotoToken, Notify.actor_id, Notify.camera_npc_id)
  end
end

function TakePhotosModule:SetSelfiePlayerLookAtOffset(bClear)
  if bClear then
    self.SelfiePlayerLookAtOffset = nil
  else
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local leftHandCamera = player.viewObj.LeftHandCamera
    local poseConf = DataConfigManager:GetTakePhotoPoseConf(self.Controller.TakePhotoSettings:GetSelectedPoseId(), true)
    if poseConf and poseConf.look_at then
      local look_at = poseConf.look_at
      local Offset
      if leftHandCamera then
        Offset = UE.FVector(look_at[1], -look_at[2], look_at[3])
      else
        Offset = UE.FVector(look_at[1], look_at[2], look_at[3])
      end
      self.SelfiePlayerLookAtOffset = Offset
    else
      self.SelfiePlayerLookAtOffset = nil
    end
  end
end

function TakePhotosModule:GetSelfiePlayerLookAtOffset()
  return self.SelfiePlayerLookAtOffset
end

function TakePhotosModule:GetPhotoActivityManager()
  return self.PhotoActivityManager
end

function TakePhotosModule:OnCmdCheckPhotoFileViewUI()
  return self:HasPanel("PhotoFileViewUI")
end

function TakePhotosModule:ReqChangeCameraTexture(SkinId)
  local ContentId = self.RefreshContentId
  local OpType = _G.ProtoEnum.ControllableNpcOpType.CNOT_SET_SKIN
  
  local function OnTakePhotoFlash(Req, Rsp)
    Log.Debug("[TakePhoto] rsp set camera skin", Rsp and Rsp.ret_info and Rsp.ret_info.ret_code)
  end
  
  NRCModuleManager:DoCmd(NPCModuleCmd.ReqControlNpc, ContentId, OpType, nil, OnTakePhotoFlash, nil, SkinId)
end

function TakePhotosModule:OnSyncCameraTextureChanged(ChangeInfo)
  local ActorId = ChangeInfo.actor_id
  local SkinId = ChangeInfo.camera_skin_id
  Log.Debug("OnSyncCameraTextureChanged", ActorId, SkinId, table.concat(ChangeInfo.unlock_skin_ids or {}, ";"))
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, ActorId)
  if not Player then
    Log.Error("Cannot found invalid player", ActorId, SkinId)
  elseif SkinId then
    if not Player.serverData.camera_info then
      Player.serverData.camera_info = {
        skin_id = SkinId,
        unlock_skin_ids = {SkinId}
      }
    else
      Log.Debug("OnSyncCameraTextureChanged", ActorId, "From", Player.serverData.camera_info.skin_id, "to", SkinId)
      Player.serverData.camera_info.skin_id = SkinId
      Player.serverData.camera_info.unlock_skin_ids = ChangeInfo.unlock_skin_ids
    end
  end
  self:DispatchEvent(TakePhotosModuleEvent.OnSyncCameraTextureChanged, ActorId)
  if 0 ~= (ChangeInfo.bag_item_id or 0) then
    local reward = {
      first_get = true,
      id = ChangeInfo.bag_item_id,
      num = 1,
      type = ProtoEnum.GoodsType.GT_BAGITEM
    }
    local tip = TipObject.FromGoodsItem(reward)
    if tip then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, tip)
    end
  end
end

return TakePhotosModule
