local ShareModuleEnum = require("NewRoco.Modules.System.Share.ShareModuleEnum")
local ShareModuleEvent = require("NewRoco.Modules.System.Share.ShareModuleEvent")
local VideoRecordEnum = require("Core.Service.Pandora.VideoRecordEnum")
local JsonUtils = require("Common.JsonUtils")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local ShareModule = NRCModuleBase:Extend("ShareModule")
local rapidjson = require("rapidjson")
local ShareVerifier = require("NewRoco.Modules.System.Share.ShareVerifier")

function ShareModule:OnConstruct()
  self.uploadGameInstance = UE.UUploadImpl.GetInstance()
  self.uploadGameInstanceRef = UnLua.Ref(self.uploadGameInstance)
  if UE4.UNRCPlatformGameInstance.GetInstance() then
    local handleRecorder = SimpleDelegateFactory:CreateCallback(self, self.HandleRecorder)
    local handleUpload = SimpleDelegateFactory:CreateCallback(self, self.HandleUpload)
    local shareObserverHandler = SimpleDelegateFactory:CreateCallback(self, self.OnShareCallback)
    local handleScreenShot = SimpleDelegateFactory:CreateCallback(self, self.ScreenShowHandle)
    self.ShareObserver = UE.UShareObserver.GetInstance()
    self.ShareObserverRef = UnLua.Ref(self.ShareObserver)
    UE.UShareStatics.SetShareObserver(self.ShareObserver)
    UE.UBP_GameJoyPluginLibrary.GetInstance().onGameJoyEvent:Add(UE4.UNRCPlatformGameInstance.GetInstance(), handleRecorder)
    self.uploadGameInstance.OnLiveVideoEvent:Add(UE4.UNRCPlatformGameInstance.GetInstance(), handleUpload)
    self.ShareObserver.Callback:Bind(UE4.UNRCPlatformGameInstance.GetInstance(), shareObserverHandler)
    self.uploadGameInstance.ScreenShowEvent:Add(UE4.UNRCPlatformGameInstance.GetInstance(), handleScreenShot)
  end
  local quality = 3
  Log.Debug("quality type is ", type(quality))
  UE.UBP_GameJoyPluginLibrary.SetVideoQuality(quality)
  UE.UBP_GameJoyPluginLibrary.SetVideoBitrate(3, 8000000)
  UE.UBP_GameJoyPluginLibrary.InitGameJoyBPLib()
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY or RocoEnv.PLATFORM_IOS then
    UE.UBP_GameJoyPluginLibrary.SetCaptureSource(1)
    if not RocoEnv.PLATFORM_IOS then
      UE.UBP_GameJoyPluginLibrary.SetShareRenderContext()
    end
  end
  UE.UShareStatics.Init()
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCSDKManagerEvent.OnIOSMediaIDGetNotify, self.OnIOSImageIDNotify)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.Shutdown, self.OnShutdown)
end

function ShareModule:OnShareCallback(ret)
  if ret.SourceMethodName == "OnDeliverMessageNotify" then
    Log.Debug("ret.MSDKMethodNameID: ", ret.MSDKMethodNameID)
    Log.Debug("ret.RetCode: ", ret.RetCode)
    Log.DebugFormat("ThirdChannelCode:%s, ThirdChannelMsg:%s", tostring(ret.ThirdChannelCode), tostring(ret.ThirdChannelMsg))
    if self:CheckShareSuccessQQ(ret.RetCode, ret.ThirdChannelCode) or self:CheckShareSuccessWeChat(ret.RetCode, ret.ThirdChannelCode) then
      _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.TryGetShareRewardReq)
    end
  elseif ret.SourceMethodName == "OnQueryFriendNotify" then
    _G.NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnQueryFriendNotify, ret)
  elseif ret.SourceMethodName == "OnSendResult" then
    Log.Debug("OnSendResult:", ret.RetCode, ret.RetMsg, ret.ThirdChannelCode, ret.ThirdChannelMsg)
  elseif ret.SourceMethodName == "OnShareResult" then
    Log.Debug("OnShareResult:", ret.RetCode, ret.RetMsg, ret.ThirdChannelCode, ret.ThirdChannelMsg)
  elseif ret.SourceMethodName == "OnMediaIDGetNotify" then
    local jsonStr = ret.ExtraJson
    Log.Debug("OnMediaIDGetNotify:" .. jsonStr .. ", and ret.RetMsg is " .. ret.RetMsg)
    local jsonTable = JsonUtils.StringToJson(jsonStr)
    if jsonTable.LocalID then
      self:OnIOSImageIDNotify(jsonTable.LocalID, ret.RetMsg)
    end
  elseif ret.SourceMethodName == "OnUSSDKResult" then
    Log.Debug("OnShareResult:", ret.RetCode, ret.RetMsg, ret.ThirdChannelCode, ret.ThirdChannelMsg)
    if 1 ~= ret.RetCode and ret.ThirdChannelCode == -10000005 then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips3 or "")
    end
  end
end

function ShareModule:HandleUpload(Event, Param1, Param2, Msg, pContext)
  Log.PrintScreenMsg("HandleUpload with Event:%d", Event)
  if Event == ShareModuleEnum.UpLoadEvent.Finished then
    if nil ~= Msg then
      Log.Debug("upload finished with Msg ", Msg)
      NRCEventCenter:DispatchEvent(ShareModuleEvent.UploadFileNotify, true, Msg)
    else
      Log.Error("upload finished with null Msg")
    end
  end
end

function ShareModule:HandleRecorder(eventID, errorCode, info)
  Log.Debug("HandleRecorder with ", eventID, errorCode, info)
  local MsgTable = JsonUtils.StringToJson(info)
  Log.Dump(MsgTable, 2, "OnRecorderCallback")
  if eventID == VideoRecordEnum.EventType.EVENT_ID_END_RECORD then
    if errorCode == VideoRecordEnum.ErrorCode.STATUS_RECORD_SUCCESS then
      if nil == MsgTable then
        Log.Error("no valid msg when end record success")
        return
      end
      Log.Debug("STATUS_RECORD_SUCCESS")
      local videoPath = nil ~= MsgTable.localVideoPath and MsgTable.localVideoPath or ""
      local coverPath = nil ~= MsgTable.cover and MsgTable.cover or ""
      local TempVideos = UE.UBlueprintPathsLibrary.Combine({
        UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
        "TempVideos"
      })
      if not UE.UNRCStatics.DirectoryExists(TempVideos) then
        Log.Error("TempVideos not exits")
        UE.UNRCStatics.MakeDirectory(TempVideos)
      end
      local petVideoPath = UE.UBlueprintPathsLibrary.Combine({
        TempVideos,
        (not string.IsNilOrEmpty(self.videoName) and self.videoName or "unknown") .. ".mp4"
      })
      local petVideoCoverPath = UE.UBlueprintPathsLibrary.Combine({
        TempVideos,
        (not string.IsNilOrEmpty(self.videoName) and self.videoName or "unknown") .. ".jpg"
      })
      local petVideoPathAbs = UE.UNRCStatics.ConvertToAbsolutePath(petVideoPath, true)
      local petVideoCoverPathAbs = UE.UNRCStatics.ConvertToAbsolutePath(petVideoCoverPath, true)
      Log.Debug("move cache video: %s to save path:%s", videoPath, petVideoPathAbs)
      Log.Debug("move cache cover: %s to save path:%s", coverPath, petVideoCoverPathAbs)
      UE.UBP_GameJoyPluginLibrary.MoveFile(videoPath, petVideoPath)
      UE.UBP_GameJoyPluginLibrary.MoveFile(coverPath, petVideoCoverPath)
      if UE.UNRCStatics.FileExists(petVideoPathAbs) then
        ShareVerifier.Register(petVideoCoverPathAbs)
        ShareVerifier.Register(petVideoPathAbs)
        _G.NRCEventCenter:DispatchEvent(ShareModuleEvent.VideoRecordSuccess, petVideoPathAbs, petVideoCoverPathAbs)
      else
        Log.Warning("[Share] video not found after MoveFile, skip register", petVideoPathAbs)
      end
    end
    self.videoName = ""
  elseif eventID == VideoRecordEnum.EventType.EVENT_ID_MOVE_MEDIA_TO_ALBUM then
    if errorCode == VideoRecordEnum.ErrorCode.SUCCESS then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_success_tips, nil, nil, 2)
    end
  elseif eventID == VideoRecordEnum.EventType.EVENT_ID_START_RECORD and errorCode == VideoRecordEnum.ErrorCode.STATUS_START_SUCCESS then
    UE.UBP_GameJoyPluginLibrary.SetCoverSize(960, 540)
  end
  if errorCode == VideoRecordEnum.ErrorCode.PERMISSION_STATUS_UNKNOWN then
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
      UE.UBP_GameJoyPluginLibrary.RequestSDKPermission(Event, VideoRecordEnum.Permission.RECORD_AUDIO)
      UE.UBP_GameJoyPluginLibrary.RequestSDKPermission(Event, VideoRecordEnum.Permission.ALBUM_ANDROID)
    elseif RocoEnv.PLATFORM_IOS then
      UE.UBP_GameJoyPluginLibrary.RequestSDKPermission(Event, VideoRecordEnum.Permission.RECORD_AUDIO)
      UE.UBP_GameJoyPluginLibrary.RequestSDKPermission(Event, VideoRecordEnum.Permission.ALBUM_IOS_READ_WRITE)
    end
  end
end

function ShareModule:RequestRT()
  if not self.ShareRT then
    self.ShareRT = UE.UPlatformImageLibrary.CreateRenderTargetMatchingBackBuffer(_G.UE4Helper.GetCurrentWorld(), "ShareModule_")
    self.bShareRTMatchesBackBuffer = self.ShareRT ~= nil
    if not self.ShareRT then
      local ViewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
      self.ShareRT = UE.UPlatformImageLibrary.CreateRenderTarget2D(_G.UE4Helper.GetCurrentWorld(), "ShareModule_", UE.ETextureRenderTargetFormat.RTF_RGBA8, math.floor(ViewportSize.X), math.floor(ViewportSize.Y))
    end
    self.ShareRTRef = UnLua.Ref(self.ShareRT)
  end
end

function ShareModule:_GetBackbufferSamplingCVar()
  return UE.UKismetSystemLibrary.GetConsoleVariableIntValue("r.OpenGL.EnableBackbufferSampling") or 0
end

function ShareModule:_EnableBackbufferSamplingIfNeeded()
  if self._savedBackbufferSampling ~= nil then
    return
  end
  if not RocoEnv.PLATFORM_ANDROID and not RocoEnv.PLATFORM_OPENHARMONY then
    return
  end
  local cvar = self:_GetBackbufferSamplingCVar()
  if 1 == cvar then
    return
  end
  self._savedBackbufferSampling = cvar
  UE.UKismetSystemLibrary.ExecuteConsoleCommand(_G.UE4Helper.GetCurrentWorld(), "r.OpenGL.EnableBackbufferSampling 1")
  Log.Debug("ShareModule: enable r.OpenGL.EnableBackbufferSampling (saved=" .. tostring(cvar) .. ")")
end

function ShareModule:_RestoreBackbufferSamplingIfNeeded()
  if self._savedBackbufferSampling == nil then
    return
  end
  local saved = self._savedBackbufferSampling
  self._savedBackbufferSampling = nil
  if 1 ~= saved then
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(_G.UE4Helper.GetCurrentWorld(), string.format("r.OpenGL.EnableBackbufferSampling %d", saved))
    Log.Debug("ShareModule: restore r.OpenGL.EnableBackbufferSampling = " .. tostring(saved))
  end
end

function ShareModule:_ShouldFlipYForCaptureTexture(bUseCopy)
  if bUseCopy then
    return false
  end
  local rhiName = UE.UNRCStatics.GetCurrentRHIName() or ""
  if string.find(rhiName, "OpenGL") ~= nil or nil ~= string.find(rhiName, "GLES") or nil ~= string.find(rhiName, "Vulkan") then
    return true
  end
  return false
end

function ShareModule:StartRecordVideo(camera, videoName, bExcludeUI)
  if not string.IsNilOrEmpty(self.videoName) then
    self:EndRecordVideo(self.videoName, self.bExcludeUI)
    Log.Error("Stop Last Record Task,the Last VideoName is" .. self.videoName .. "and the new one is " .. (not string.IsNilOrEmpty(videoName) and videoName) or "nil")
  end
  self.mainCamera = camera
  if self.mainCamera == nil then
    Log.Error("camera not valid")
    return
  end
  self.videoName = videoName
  self.bExcludeUI = bExcludeUI
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY or RocoEnv.PLATFORM_IOS then
    if not bExcludeUI then
      self:_EnableBackbufferSamplingIfNeeded()
    end
    self.captureComponent = self.mainCamera:GetComponentByClass(UE4.UNRCCameraCaptureComponent)
    if nil == self.captureComponent then
      Log.Error("captureComponent invalid")
      return
    end
    if not self.ShareRT then
      self:RequestRT()
    end
    self.captureComponent.TextureTarget = self.ShareRT
    if self.captureComponent.TextureTarget then
      Log.Debug("self.captureComponent.TextureTarget not nil")
      UE.UPlatformImageLibrary.UpdateRenderTarget(self.captureComponent.TextureTarget, true)
      self.recordDelayId = _G.DelayManager:DelayFrames(3, self.OnStartRecordVideo, self, bExcludeUI)
    end
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShareRecordVideo, true)
end

function ShareModule:OnStartRecordVideo(bExcludeUI)
  self.recordDelayId = nil
  if not UE4.UObject.IsValid(self.captureComponent) then
    Log.Error("self.captureComponent invalid")
    return
  end
  UE.UBP_GameJoyPluginLibrary.SetCaptureTexture(self.captureComponent.TextureTarget)
  if bExcludeUI then
    local bFlipY = self:_ShouldFlipYForCaptureTexture(false)
    UE.UBP_GameJoyPluginLibrary.SetCaptureTextureFlipY(bFlipY)
    Log.Debug(string.format("ShareModule[Scene]: SetCaptureTextureFlipY(%s)", tostring(bFlipY)))
    self.captureComponent:StartVideoCaptureScene()
  else
    local bUseCopy = self.bShareRTMatchesBackBuffer == true
    local bFlipY = self:_ShouldFlipYForCaptureTexture(bUseCopy)
    UE.UBP_GameJoyPluginLibrary.SetCaptureTextureFlipY(bFlipY)
    Log.Debug(string.format("ShareModule[UI]: bUseCopy=%s SetCaptureTextureFlipY(%s) RHI=%s", tostring(bUseCopy), tostring(bFlipY), tostring(UE.UNRCStatics.GetCurrentRHIName())))
    self.captureComponent:StartVideoCaptureSceneWithUI(bUseCopy)
  end
  UE.UBP_GameJoyPluginLibrary.EnableInGameAudio(true)
  UE.UBP_GameJoyPluginLibrary.StartRecorder()
end

function ShareModule:EndRecordVideo(videoName, bExcludeUI)
  UE.UBP_GameJoyPluginLibrary.StopRecorder()
  if (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY or RocoEnv.PLATFORM_IOS) and self.captureComponent ~= nil and UE4.UObject.IsValid(self.captureComponent) then
    if bExcludeUI then
      self.captureComponent:StopVideoCaptureScene()
    else
      self.captureComponent:StopVideoCaptureSceneWithUI()
    end
  end
  self:_RestoreBackbufferSamplingIfNeeded()
  self.mainCamera = nil
  self.captureComponent = nil
  if self.ShareRT then
    self.ShareRT = nil
  end
  self.bExcludeUI = false
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShareRecordVideo, false)
end

function ShareModule:ForceClearRecordedVideo(videoName, imageName)
  if not string.IsNilOrEmpty(videoName) or not string.IsNilOrEmpty(imageName) then
    local TempVideos = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "TempVideos"
    })
    if not string.IsNilOrEmpty(videoName) then
      local videoPath = UE.UBlueprintPathsLibrary.Combine({
        TempVideos,
        videoName .. ".mp4"
      })
      local videoAbsPath = UE.UNRCStatics.ConvertToAbsolutePath(videoPath, true)
      local bDeleteVideo = UE.UNRCStatics.DeleteToFile(videoAbsPath)
      Log.Debug("ForceClearRecordedVideo video", videoAbsPath, bDeleteVideo)
    end
    if not string.IsNilOrEmpty(imageName) then
      local imagePath = UE.UBlueprintPathsLibrary.Combine({
        TempVideos,
        imageName .. ".jpg"
      })
      local imageAbsPath = UE.UNRCStatics.ConvertToAbsolutePath(imagePath, true)
      local bDeleteImage = UE.UNRCStatics.DeleteToFile(imageAbsPath)
      Log.Debug("ForceClearRecordedVideo iamge", imageAbsPath, bDeleteImage)
    end
  else
    local absPath = UE.UNRCStatics.ConvertToAbsolutePath(UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "TempVideos"
    }), true)
    local bRemove = UE.UNRCStatics.RemoveFolder(absPath)
    Log.Debug("ForceClearRecordedVideo:", absPath, ", result:", bRemove)
  end
end

function ShareModule:OnDestruct()
  self.channel = nil
  self.reqInfoForTT = nil
  self.reqInfoForTTRef = nil
  self.recordDelayId = nil
end

function ShareModule:OnActive()
  self.uploadGameInstance:InitSetting(nil)
end

function ShareModule:OnDeactive()
end

function ShareModule:OnShutDown()
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  self:_RestoreBackbufferSamplingIfNeeded()
  self.uploadGameInstance.OnLiveVideoEvent:Clear()
  UE.UBP_GameJoyPluginLibrary.GetInstance().onGameJoyEvent:Clear()
  self.uploadGameInstance = nil
  self.uploadGameInstanceRef = nil
end

function ShareModule:ShareToChannel(reqInfo, channel)
  local shareHandlers = {
    [ShareModuleEnum.ShareChannel.QQFriend] = function()
      UE.UShareStatics.SendToChannel(reqInfo, "QQ")
    end,
    [ShareModuleEnum.ShareChannel.Qzone] = function()
      UE.UShareStatics.ShareToChannel(reqInfo, "QQ")
    end,
    [ShareModuleEnum.ShareChannel.WeChatFriend] = function()
      UE.UShareStatics.SendToChannel(reqInfo, "WeChat")
    end,
    [ShareModuleEnum.ShareChannel.WeChatMoments] = function()
      UE.UShareStatics.ShareToChannel(reqInfo, "WeChat")
    end,
    [ShareModuleEnum.ShareChannel.TiktokFriend] = function()
      if RocoEnv.PLATFORM_IOS then
        self.reqInfoForTT = reqInfo
        self.reqInfoForTTRef = UnLua.Ref(self.reqInfoForTT)
        self.channel = ShareModuleEnum.ShareChannel.TiktokFriend
        UE.UShareStatics.SaveMediaWrapper(reqInfo.ImagePath, "NRC")
      elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
        UE.UShareStatics.SendToDouYin(reqInfo)
      end
    end,
    [ShareModuleEnum.ShareChannel.Tiktok] = function()
      if RocoEnv.PLATFORM_IOS then
        self.reqInfoForTT = reqInfo
        self.reqInfoForTTRef = UnLua.Ref(self.reqInfoForTT)
        self.channel = ShareModuleEnum.ShareChannel.Tiktok
        if reqInfo.type == UE.EShareType.ShareVideo then
          UE.UShareStatics.SaveMediaWrapper(reqInfo.VideoPath, "NRC")
        elseif reqInfo.type == UE.EShareType.ShareImg then
          UE.UShareStatics.SaveMediaWrapper(reqInfo.ImagePath, "NRC")
        end
      elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
        UE.UShareStatics.ShareToDouYin(reqInfo)
      end
    end,
    [ShareModuleEnum.ShareChannel.Weibo] = function()
      UE.UShareStatics.SetUSSDKChannel("Weibo")
      UE.UShareStatics.ShareToChannel(reqInfo, "Weibo")
    end,
    [ShareModuleEnum.ShareChannel.RedNote] = function()
      UE.UShareStatics.SetUSSDKChannel("RedNote")
      UE.UShareStatics.ShareToChannel(reqInfo, "RedNote")
    end,
    [ShareModuleEnum.ShareChannel.KuaiShou] = function()
      UE.UShareStatics.SetUSSDKChannel("Kwai")
      UE.UShareStatics.ShareToChannel(reqInfo, "KuaiShou")
    end,
    [ShareModuleEnum.ShareChannel.BiliBili] = function()
      UE.UShareStatics.SetUSSDKChannel("Bilibili")
      UE.UShareStatics.ShareToChannel(reqInfo, "BiliBili")
    end
  }
  local handler = shareHandlers[channel]
  if handler then
    Log.Debug("ShareToChannel:", channel)
    handler()
  else
    Log.Error("ShareToChannel not support now:", channel)
  end
end

function ShareModule:OnIOSImageIDNotify(localIDStr, errInfoStr)
  if not string.IsNilOrEmpty(localIDStr) and self.reqInfoForTT ~= nil then
    self.reqInfoForTT.ImageID = localIDStr
    self.reqInfoForTT.VideoID = localIDStr
    Log.Dump(self.reqInfoForTT, 1, "SendToDouYinReq")
    if self.channel == ShareModuleEnum.ShareChannel.TiktokFriend then
      UE.UShareStatics.SendToDouYin(self.reqInfoForTT)
    elseif self.channel == ShareModuleEnum.ShareChannel.Tiktok then
      UE.UShareStatics.ShareToDouYin(self.reqInfoForTT)
    end
    self.channel = nil
    self.reqInfoForTT = nil
    self.reqInfoForTTRef = nil
  else
    Log.Error("OnIOSImageIDNotify error: ", not string.IsNilOrEmpty(errInfoStr) and errInfoStr or "")
  end
end

function ShareModule:CheckAppInstall(channel)
  local allData = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.SHARE_CONF)
  if nil == allData then
    Log.Error("no share_conf found")
    return false
  end
  for _, shareWayData in ipairs(allData) do
    if channel == shareWayData.name then
      if RocoEnv.PLATFORM_ANDROID then
        if shareWayData.package_name_android then
          return UE.UNRCDeviceInfoHelper.IsAppInstalled(shareWayData.package_name_android)
        end
      elseif RocoEnv.PLATFORM_IOS then
        if shareWayData.package_name_ios then
          local isAppInstall = false
          for _, package_scheme in ipairs(shareWayData.package_name_ios) do
            if UE.UNRCDeviceInfoHelper.IsAppInstalled(package_scheme .. "://") then
              isAppInstall = true
            end
          end
          return isAppInstall
        end
      elseif RocoEnv.PLATFORM_OPENHARMONY and shareWayData.package_name_harmony then
        return UE.UNRCDeviceInfoHelper.IsAppInstalled(shareWayData.package_name_harmony)
      end
    end
  end
  return false
end

function ShareModule:SharePic(picPath, channel)
  if not self:CheckAppInstall(channel) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    NRCEventCenter:DispatchEvent(ShareModuleEvent.AppNotInstallNotify)
    return
  end
  if not UE.UNRCStatics.FileExists(picPath) then
    Log.Error("invalid picPath when SharePic")
    return
  end
  local ok, reason = ShareVerifier.Verify(picPath, ShareVerifier.FileKind.Pic)
  if not ok then
    Log.Error("[Share] SharePic blocked by verifier", picPath, reason)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
    return
  end
  if not table.contains(ShareModuleEnum.ShareChannel, channel) then
    Log.Error("channel not support", channel)
    return
  end
  local reqInfo = NewObject(UE.UFriendReqWrapper)
  reqInfo.Type = UE.EShareType.ShareImg
  if channel == ShareModuleEnum.ShareChannel.Weibo or channel == ShareModuleEnum.ShareChannel.RedNote or channel == ShareModuleEnum.ShareChannel.KuaiShou or channel == ShareModuleEnum.ShareChannel.BiliBili then
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if accountInfo then
      reqInfo.Title = LuaText.USSDK_Share_Title or "NRC"
      reqInfo.ImagePath = picPath
      reqInfo.User = accountInfo.openid or 0
      reqInfo.Content = LuaText.USSDK_Share_Content or "NRC"
      if channel == ShareModuleEnum.ShareChannel.BiliBili then
        local extraTable = {
          biz_code = "tencent_ussdk",
          type_id = 0,
          topic_id = 0,
          delivery_mode = 2
        }
        reqInfo.ExtraJson = JsonUtils.EncodeTable(extraTable)
      elseif channel == ShareModuleEnum.ShareChannel.KuaiShou then
        local extraTable = {
          message_description = LuaText.USSDK_Share_Content or "NRC",
          disable_fallback = false,
          share_strategy = "SinglePictureEdit"
        }
        reqInfo.ExtraJson = JsonUtils.EncodeTable(extraTable)
      end
      self:ShareToChannel(reqInfo, channel)
    end
  elseif reqInfo then
    Log.Debug("pic path is ", picPath)
    reqInfo.ImagePath = picPath
    self:ShareToChannel(reqInfo, channel)
  else
    Log.Debug("reqInfo is nil!")
  end
end

function ShareModule:ShareInviteWechat(title, content, openid, friendVroleID, friendVrolename)
  if not self:CheckAppInstall(ShareModuleEnum.ShareChannel.WeChatFriend) then
    Log.WarningFormat("ShareModule:ShareInviteWechat wechat not install, title:%s, content:%s, openid:%s", tostring(title), tostring(content), tostring(openid))
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    return
  end
  if string.IsNilOrEmpty(title) or string.IsNilOrEmpty(content) then
    Log.ErrorFormat("ShareModule:ShareInviteWechat invalid title or content, title:%s, content:%s, openid:%s", tostring(title), tostring(content), tostring(openid))
    return
  end
  local reqInfo = NewObject(UE.UFriendReqWrapper)
  if not reqInfo then
    Log.Error("ShareModule:ShareInviteWechat create UFriendReqWrapper failed")
    return
  end
  if openid then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.ReportInviteFriendTLog, 4, openid, friendVroleID, friendVrolename)
  else
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.ReportInviteFriendTLog, 3)
  end
  reqInfo.Type = UE.EShareType.ShareInvite
  reqInfo.Title = title
  reqInfo.Desc = content
  reqInfo.User = openid or ""
  reqInfo.ThumbPath = "https://img.gamecenter.qq.com/gc_img/gc/formal/common/1110613799/thumImg.png?v=1762326178911"
  reqInfo.ExtraJson = "{\"game_data\":\"test data\",\"isFriendInGame\":true}"
  Log.DebugFormat("ShareModule:ShareInviteWechat reqInfo Type:%s, Title:%s, Desc:%s, User:%s, Link:%s, ExtraJson:%s", tostring(reqInfo.Type), tostring(reqInfo.Title), tostring(reqInfo.Desc), tostring(reqInfo.User), tostring(reqInfo.Link), tostring(reqInfo.ExtraJson))
  self:ShareToChannel(reqInfo, ShareModuleEnum.ShareChannel.WeChatFriend)
end

function ShareModule:CalculateMiniAppExtraCode(extraCode)
  local paramNqExtraData = {code = extraCode}
  local nqExtraDataJsonStr = rapidjson.encode(paramNqExtraData) or ""
  local nqExtraDataJsonBase64Str = UE4.UNRCStatics.EncodeBase64(nqExtraDataJsonStr)
  return nqExtraDataJsonBase64Str
end

function ShareModule:ShareWeChatMiniAppToQQByURL(extraCode)
  local miniAppUrl = "mqqapi://miniapp/open"
  local nqExtraDataJsonBase64Str = self:CalculateMiniAppExtraCode(extraCode)
  local paramNq = {
    [1] = {type = "activity"},
    [2] = {
      url = "simpkg/pages/index"
    },
    [3] = {extraData = nqExtraDataJsonBase64Str}
  }
  local params = {
    [1] = {_atype = "0"},
    [2] = {
      _mappid = "wx9a5bc2cdcaff1af1"
    },
    [3] = {_miniapptype = "2"},
    [4] = {_mvid = ""},
    [5] = {
      _path = "pages/entry/entry"
    },
    [6] = {
      _vt = RocoEnv.IS_SHIPPING and "3" or "1"
    },
    [7] = {_sig = "3966102803"},
    [8] = {_nq = paramNq},
    [9] = {host_scene = "2000000000"}
  }
  local paramStr = ""
  local firstParam = true
  for index, valueTable in ipairs(params) do
    for key, value in pairs(valueTable) do
      if key and value then
        local encodedKey = string.urlEncode(tostring(key))
        local encodedValue = ""
        if type(value) == "table" then
          local paramTableStr = ""
          local firstTableParam = true
          for indexInnerTable, valueTableInnerTable in ipairs(value) do
            for keyInnerTable, valueInnerTable in pairs(valueTableInnerTable) do
              if keyInnerTable and valueInnerTable then
                if firstTableParam then
                  paramTableStr = string.format("%s=%s", keyInnerTable, valueInnerTable)
                else
                  paramTableStr = string.format("%s&%s=%s", paramTableStr, keyInnerTable, valueInnerTable)
                end
                firstTableParam = false
              end
            end
          end
          encodedValue = string.urlEncode(paramTableStr)
        else
          encodedValue = string.urlEncode(tostring(value))
        end
        if firstParam then
          paramStr = string.format("%s?%s=%s", paramStr, encodedKey, encodedValue)
        else
          paramStr = string.format("%s&%s=%s", paramStr, encodedKey, encodedValue)
        end
        firstParam = false
      end
    end
  end
  local url = string.format("%s%s", miniAppUrl, paramStr)
  self:Log("ShareWeChatMiniAppToQQByURL url: ", url)
  local screenType = 2
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    screenType = 1
  end
  local isFullScreen = true
  local isUseURLEncode = false
  local entraJson = "{\"isEmbedWebView\":false}"
  local bIsBrowser = true
  UE4.UWebViewStatics.OpenURL(url, screenType, isFullScreen, isUseURLEncode, entraJson, bIsBrowser)
end

function ShareModule:ShareQQArk(arkJson)
  if not self:CheckAppInstall(ShareModuleEnum.ShareChannel.QQFriend) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    return
  end
  if string.IsNilOrEmpty(arkJson) then
    Log.Error("invalid arkJson when ShareQQArk")
    return
  end
  local reqInfo = NewObject(UE.UFriendReqWrapper)
  if reqInfo then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.ReportInviteFriendTLog, 1)
    reqInfo.Type = UE.EShareType.ShareQQArk
    local defaultTitle = LuaText.Invite_Friend_Limit1
    local defaultContent = LuaText.Invite_Friend_Limit2
    reqInfo.Title = defaultTitle
    reqInfo.Desc = defaultContent
    reqInfo.Link = "https://static.gamecenter.qq.com/xgame/gc-assets/pages/game-detail/index.html?page_name=QQGameCenterGameDetail&open_kuikly_info=%7B%22url%22%3A%22%3FFFROMSCHEMA%3D%26appid%3D1110613799%26adtag%3Dgameclient%22%2C%22page_name%22%3A%22QQGameCenterGameDetail%22%2C%22bundle_name%22%3A%22gamecenter_detail%22%7D"
    reqInfo.ImagePath = "https://img.gamecenter.qq.com/gc_img/gc/formal/common/1110613799/thumImg.png?v=1762326178911"
    reqInfo.ExtraJson = arkJson
    Log.DebugFormat("ShareModule:ShareQQArk reqInfo Type:%s, Title:%s, Desc:%s, ImagePath:%s, ExtraJson:%s", tostring(reqInfo.Type), tostring(reqInfo.Title), tostring(reqInfo.Desc), tostring(reqInfo.ImagePath), tostring(reqInfo.ExtraJson))
    self:ShareToChannel(reqInfo, ShareModuleEnum.ShareChannel.QQFriend)
  else
    Log.Debug("reqInfo is nil!")
  end
end

function ShareModule:ShareMiniApp(channel, originThumbPath, miniAppPath, extraCode, title, desc)
  if not self:CheckAppInstall(channel) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    NRCEventCenter:DispatchEvent(ShareModuleEvent.AppNotInstallNotify)
    return
  end
  Log.PrintScreenMsgRed("ShareMiniApp with channel: " .. channel)
  Log.Info("ShareModule:ShareMiniApp", "originThumbPath ", originThumbPath, "miniAppPath ", miniAppPath, " extraCode : ", extraCode, " title ", title, " desc ", desc)
  if channel == ShareModuleEnum.ShareChannel.QQFriend or channel == ShareModuleEnum.ShareChannel.Qzone then
    self:Log("ShareMiniApp with channel: ", channel)
    self:ShareWeChatMiniAppToQQByURL(extraCode)
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.TryGetShareRewardReq)
    return
  end
  if string.IsNilOrEmpty(originThumbPath) then
    originThumbPath = _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_img") and _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_img").str
  end
  if string.IsNilOrEmpty(miniAppPath) then
    miniAppPath = _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_FirstPage") and _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_FirstPage").str
  end
  if string.IsNilOrEmpty(title) then
    title = _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_title") and _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_title").str or "NRC"
  end
  if string.IsNilOrEmpty(desc) then
    desc = _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_des") and _G.DataConfigManager:GetActivityGlobalConfig("SIM_WechatApplet_des").str or "NRC"
  end
  if channel == ShareModuleEnum.ShareChannel.QQFriend or channel == ShareModuleEnum.ShareChannel.Qzone or channel == ShareModuleEnum.ShareChannel.WeChatFriend then
    if not self:CheckAppInstall(channel) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
      return
    end
  else
    return
  end
  if string.IsNilOrEmpty(originThumbPath) or string.IsNilOrEmpty(miniAppPath) then
    Log.Error("empty originThumbPath or miniAppPath")
    return
  end
  if extraCode then
    local nqExtraCode = self:CalculateMiniAppExtraCode(extraCode)
    local nqExtraCodeEscaped = string.urlEncode(nqExtraCode)
    if nqExtraCode then
      miniAppPath = string.format("%s%s", miniAppPath, nqExtraCodeEscaped)
    end
    Log.Info("miniAppPath: ", miniAppPath, " nqExtraCode: ", nqExtraCode, " escaped nqExtraCode: ", nqExtraCodeEscaped)
  end
  
  local function successHandler(finalPath)
    local reqInfo = NewObject(UE.UFriendReqWrapper)
    reqInfo.Type = UE.EShareType.ShareMiniProgram
    reqInfo.Title = title
    reqInfo.Desc = desc
    reqInfo.Link = "https://rocom.qq.com"
    reqInfo.ThumbPath = finalPath
    local extraTable = {}
    if channel == ShareModuleEnum.ShareChannel.WeChatFriend then
      extraTable = {
        weapp_id = "gh_08aab75eddb7",
        mini_program_type = 2,
        with_share_ticket = 0
      }
      if RocoEnv.IS_SHIPPING then
        extraTable.mini_program_type = 0
      else
        extraTable.mini_program_type = 2
      end
      reqInfo.mediaPath = miniAppPath
      Log.Info("reqInfo. mediaPath ", miniAppPath)
    elseif channel == ShareModuleEnum.ShareChannel.QQFriend or channel == ShareModuleEnum.ShareChannel.Qzone then
      extraTable = {
        mini_appid = "gh_08aab75eddb7",
        mini_path = miniAppPath,
        mini_program_type = 3,
        with_share_ticket = 0
      }
    end
    if table.len(extraTable) > 0 then
      reqInfo.ExtraJson = JsonUtils.EncodeTable(extraTable)
    end
    Log.Info("ShareModule:ShareMiniApp reqInfo.ExtraJson: " .. tostring(reqInfo.ExtraJson) .. " extraTable len " .. table.len(extraTable))
    self:ShareToChannel(reqInfo, channel)
  end
  
  local function failHandler()
    Log.Error("LoadAssetFailed")
  end
  
  self:ResPathToNativePath(originThumbPath, successHandler, failHandler)
end

function ShareModule:ResPathToNativePath(ThumbPath, successHandler, failHandler)
  local function LoadAssetSuccess(caller, request, asset)
    local tempPhotos = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      
      "Shareable"
    })
    if not UE.UNRCStatics.DirectoryExists(tempPhotos) then
      UE.UNRCStatics.MakeDirectory(tempPhotos)
    end
    local filePath = UE4.UNRCStatics.GetBaseFilename(ThumbPath, true)
    local finalPath = UE.UNRCStatics.ConvertToAbsolutePath(UE.UBlueprintPathsLibrary.Combine({tempPhotos, filePath}) .. ".png", true)
    Log.PrintScreenMsgRed("finalPath return " .. finalPath)
    local texture = asset.BakedSourceTexture
    local textureSize = UE4.FVector2D(texture:Blueprint_GetSizeX(), texture:Blueprint_GetSizeY())
    local topLeftUV = UE4.FVector2D(asset.BakedSourceUV.X / textureSize.X, asset.BakedSourceUV.Y / textureSize.Y)
    local rightBottomUV = UE4.FVector2D((asset.BakedSourceUV.X + asset.BakedSourceDimension.X) / textureSize.X, (asset.BakedSourceUV.Y + asset.BakedSourceDimension.Y) / textureSize.Y)
    local requiredSize = UE4.FVector2D(asset.BakedSourceDimension.X, asset.BakedSourceDimension.Y)
    if texture then
      if UE.UPlatformImageLibrary.SaveTextureAsFile(_G.UE4Helper.GetCurrentWorld(), texture, requiredSize, topLeftUV, rightBottomUV, finalPath) and successHandler then
        successHandler(finalPath)
      elseif failHandler then
        Log.Error("UE.UPlatformImageLibrary.SaveTextureAsFile failed")
        failHandler()
      end
    end
  end
  
  _G.NRCResourceManager:LoadResAsync(self, ThumbPath, 0, 1, LoadAssetSuccess, failHandler, nil, nil)
end

function ShareModule:ShareCosVideo(channel, videoLink)
  if not self:CheckAppInstall(channel) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    return
  end
  if string.IsNilOrEmpty(channel) or string.IsNilOrEmpty(videoLink) then
    Log.Error("invalid videoLink when ShareCosVideo")
    return
  end
  local reqInfo = NewObject(UE.UFriendReqWrapper)
  reqInfo.Type = UE.EShareType.ShareVideo
  if channel == ShareModuleEnum.ShareChannel.BiliBili then
    reqInfo.Title = LuaText.USSDK_Share_Title or "NRC"
    reqInfo.User = accountInfo.openid
    reqInfo.Content = LuaText.USSDK_Share_Content or "NRC"
    local extraJsonTable = {
      biz_code = "tencent_ussdk",
      type_id = 0,
      topic_id = 1330131,
      delivery_mode = 2
    }
    reqInfo.ExtraJson = JsonUtils.Encode(extraJsonTable)
  else
    Log.Error("invalid channel when ShareCosVideo")
    return
  end
  self:ShareToChannel(reqInfo, channel)
end

function ShareModule:ShareLocalVideo(channel, videoName)
  if not self:CheckAppInstall(channel) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    return
  end
  if string.IsNilOrEmpty(channel) or string.IsNilOrEmpty(videoName) then
    Log.Error("invalid channel or filePath when shareVideo")
    return
  end
  local TempVideos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempVideos"
  })
  local filePath = UE.UBlueprintPathsLibrary.Combine({
    TempVideos,
    videoName .. ".mp4"
  })
  local fileAbsPath = UE.UNRCStatics.ConvertToAbsolutePath(filePath, true)
  if not UE.UNRCStatics.FileExists(fileAbsPath) then
    Log.Error("%s not exist", fileAbsPath)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips2, nil, nil, 2)
    return
  end
  local ok, reason = ShareVerifier.Verify(fileAbsPath, ShareVerifier.FileKind.Video)
  if not ok then
    Log.Error("[Share] ShareLocalVideo blocked by verifier", fileAbsPath, reason)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
    return
  end
  local reqInfo = NewObject(UE.UFriendReqWrapper)
  reqInfo.Type = UE.EShareType.ShareVideo
  reqInfo.VideoPath = fileAbsPath
  if channel == ShareModuleEnum.ShareChannel.Tiktok or channel == ShareModuleEnum.ShareChannel.TiktokFriend then
    reqInfo.Title = _G.DataConfigManager:GetLocalizationConf("ShareTxt_tiktok").msg ~= nil and _G.DataConfigManager:GetLocalizationConf("ShareTxt_tiktok").msg ~= nil or "NRC"
    reqInfo.Desc = LuaText.share_tip
  elseif channel == ShareModuleEnum.ShareChannel.QQFriend or channel == ShareModuleEnum.ShareChannel.Qzone or channel == ShareModuleEnum.ShareChannel.WeChatFriend or channel == ShareModuleEnum.ShareChannel.WeChatMoments then
  elseif channel == ShareModuleEnum.ShareChannel.Weibo or channel == ShareModuleEnum.ShareChannel.RedNote or channel == ShareModuleEnum.ShareChannel.KuaiShou then
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if accountInfo then
      reqInfo.Title = LuaText.USSDK_Share_Title or "NRC"
      reqInfo.User = accountInfo.openid
      reqInfo.Content = LuaText.USSDK_Share_Content or "NRC"
      local coverPath = UE.UBlueprintPathsLibrary.Combine({
        TempVideos,
        videoName .. ".jpg"
      })
      local coverAbsPath = UE.UNRCStatics.ConvertToAbsolutePath(coverPath, true)
      if not UE.UNRCStatics.FileExists(coverAbsPath) then
        Log.Error("%s not exist", coverAbsPath)
      end
      reqInfo.ThumbPath = coverAbsPath
    else
      Log.Error("accountInfo is nil")
      return
    end
    if channel == ShareModuleEnum.ShareChannel.KuaiShou then
      local extraTable = {
        message_description = LuaText.USSDK_Share_Content or "NRC",
        disable_fallback = false,
        share_strategy = "SingleVideoClip"
      }
      reqInfo.ExtraJson = JsonUtils.EncodeTable(extraTable)
    end
  end
  self:ShareToChannel(reqInfo, channel)
end

function ShareModule:ShareRecordVideo(petName)
  local TempVideos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempVideos"
  })
  if UE.UNRCStatics.DirectoryExists(TempVideos) then
    local filePath = UE.UBlueprintPathsLibrary.Combine(TempVideos, petName .. ".mp4")
    if not UE.UNRCStatics.FileExists(filePath) then
    end
  else
    UE.UNRCStatics.MakeDirectory(TempVideos)
  end
end

function ShareModule:SaveVideoToAlbum(videoName)
  local filePath = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempVideos"
  })
  filePath = UE.UBlueprintPathsLibrary.Combine({
    filePath,
    videoName .. ".mp4"
  })
  local absoluteFilePath = UE.UNRCStatics.ConvertToAbsolutePath(filePath, true)
  if not UE.UNRCStatics.FileExists(absoluteFilePath) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips2, nil, nil, 2)
    Log.Error("%s not exist ", absoluteFilePath)
    return
  end
  
  local function OnPermissionCallback()
    Log.Debug("MoveVideoToAlbum with path:", absoluteFilePath)
    UE.UBP_GameJoyPluginLibrary.MoveVideoToAlbum(VideoRecordEnum.EventType.EVENT_ID_MOVE_MEDIA_TO_ALBUM, "NRC", absoluteFilePath)
  end
  
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.AccessAlbum)
  if not bGranted and (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY) then
    if not self:CheckPermission(ShareModuleEnum.NeedAlbumPermissionChannel.save, UE.ENRCPermissionType.AccessAlbum) then
      return
    end
    self.requestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.AccessAlbum, {
      self,
      function(_, bGranted)
        self.requestCode = nil
        if bGranted then
          OnPermissionCallback()
        else
          self:LogError("!!!Permission!!!")
        end
      end
    })
  else
    OnPermissionCallback()
  end
end

function ShareModule:SaveToAlbum()
end

function ShareModule:StartUploadFile(videoPath, coverPath)
  if not UE.UNRCStatics.FileExists(videoPath) or not UE.UNRCStatics.FileExists(coverPath) then
    Log.Error("invalid videoPath or coverPath", videoPath, coverPath)
    return
  end
  local Req = _G.ProtoMessage:newZoneGetCosSignatureReq()
  self.videoPath = videoPath
  self.coverPath = coverPath
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_COS_SIGNATURE_REQ, Req, self, self.UploadFileWithSig)
end

function ShareModule:UploadFileWithSig(Rsp)
  local Sig = Rsp.signature
  Log.Dump(Rsp, 2, "UploadFileWithSig")
  if not Rsp.ret_info or 0 ~= Rsp.ret_info.ret_code or not Sig then
    Log.Error("Error when req for sig")
    return
  end
  local videoName = string.match(self.videoPath ~= nil and self.videoPath, "[^/\\]+$")
  Log.Debug("videoPath is ", self.videoPath)
  Log.Debug("coverPath is ", self.coverPath)
  self.uploadGameInstance:StartUploadVideo(Sig, self.videoPath ~= nil and self.videoPath, nil ~= self.coverPath and self.coverPath, true, true, not string.IsNilOrEmpty(videoName) and videoName or "unknown.mp4")
  self.videoPath = nil
  self.coverPath = nil
end

function ShareModule:CheckPermission(channel, permission)
  if permission == UE.ENRCPermissionType.AccessAlbum then
    if UE.UNRCPermissionMgr.IfPermissionExpectStatus(permission, 3) or UE.UNRCPermissionMgr.IfPermissionExpectStatus(permission, 2) then
      local tips = string.format(LuaText.need_open_system_setting_tips, LuaText.permission_type_0)
      local Context = DialogContext()
      Context:SetTitle(LuaText.umg_login_new_2):SetContent(tips):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
      return false
    end
    return true
  end
end

function ShareModule:GetQRCodeTexture(text, eccLevel)
  local qrCodeGenerator = NewObject(UE4.UQRCodeGenerator)
  local qrGeneratorRef = UnLua.Ref(qrCodeGenerator)
  local qrCode = qrCodeGenerator:EncodeText(eccLevel or UE4.EQrEcc.Ecc_MEDIUM, text)
  if qrCode and qrCode.QRCodeTexture then
    qrCode:DisplayQRToTexture()
    return qrCode.QRCodeTexture
  end
  return nil
end

local BASE64CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function ShareModule:GetFilledBase64(originalNum, requiredBitNum)
  local originRes = ""
  originalNum = originalNum and originalNum or 0
  if 0 == originalNum then
    originRes = "A"
  end
  while originalNum > 0 do
    local remainder = originalNum % 64
    originRes = originRes .. string.sub(BASE64CHARS, remainder + 1, remainder + 1)
    originalNum = math.floor(originalNum / 64)
  end
  originRes = string.reverse(originRes)
  while requiredBitNum > #originRes do
    originRes = originRes .. "~"
  end
  
  local function replace_chars_efficient(str)
    return (str:gsub("[%/+]", {
      ["+"] = "-",
      ["/"] = "_"
    }))
  end
  
  return replace_chars_efficient(originRes)
end

function ShareModule:DecodeFilledBase64(encodedStr)
  local function restore_chars(str)
    return (str:gsub("[%-_]", {
      ["-"] = "+",
      
      _ = "/"
    }))
  end
  
  local restoredStr = restore_chars(encodedStr)
  restoredStr = restoredStr:gsub("~+$", "")
  local num = 0
  for i = 1, #restoredStr do
    local char = string.sub(restoredStr, i, i)
    local pos = string.find(BASE64CHARS, char, 1, true)
    if not pos then
      Log.Error("Invalid Base64 character: " .. char)
      return 0
    end
    local value = pos - 1
    num = num * 64 + value
  end
  return num
end

function ShareModule:ScreenShowHandle()
  local canOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, _G.Enum.ShareButtonType.SBT_SCREENSHOT)
  if canOpen then
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenScreenshotSharingPanel)
  end
end

function ShareModule:CheckShareSuccessQQ(code, thirdCode)
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local isQQ = playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_QQ
  return isQQ and (0 == code or 2 == code or 9999 == code and -1 == thirdCode)
end

function ShareModule:CheckShareSuccessWeChat(code, thirdCode)
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local isWeChat = playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_WX
  return isWeChat and (0 == code or 2 == code or 9999 == code and (0 == thirdCode or -2 == thirdCode))
end

function ShareModule:ShareH5WechatAndQQ(title, content, openid, link, urlPath, bShareToWechat)
  if bShareToWechat then
    if not self:CheckAppInstall(ShareModuleEnum.ShareChannel.WeChatFriend) then
      Log.WarningFormat("ShareModule:ShareH5WechatAndQQ wechat not install, title:%s, content:%s, openid:%s", tostring(title), tostring(content), tostring(openid))
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
      return
    end
  elseif not self:CheckAppInstall(ShareModuleEnum.ShareChannel.QQFriend) then
    Log.WarningFormat("ShareModule:ShareH5WechatAndQQ QQ not install, title:%s, content:%s, openid:%s", tostring(title), tostring(content), tostring(openid))
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.app_not_install_tip, nil, nil, 2)
    return
  end
  if string.IsNilOrEmpty(title) or string.IsNilOrEmpty(content) and string.IsNilOrEmpty(openid) then
    Log.ErrorFormat("ShareModule:ShareH5WechatAndQQ invalid title or content or openid, title:%s, content:%s, openid:%s", tostring(title), tostring(content), tostring(openid))
    return
  end
  
  local function successHandler(thumbPath)
    local reqInfo = NewObject(UE.UFriendReqWrapper)
    if not reqInfo then
      Log.Error("ShareModule:ShareH5WechatAndQQ create UFriendReqWrapper failed")
      return
    end
    reqInfo.Type = UE.EShareType.ShareLink
    reqInfo.Title = title
    reqInfo.Desc = content
    reqInfo.User = openid
    reqInfo.Link = link
    reqInfo.ThumbPath = thumbPath
    reqInfo.ExtraJson = "{\"isFriendInGame\":false}"
    Log.WarningFormat("ShareModule:ShareH5WechatAndQQ reqInfo Type:%s, Title:%s, Desc:%s, User:%s, Link:%s, ThumbPath:%s, ExtraJson:%s", tostring(reqInfo.Type), tostring(reqInfo.Title), tostring(reqInfo.Desc), tostring(reqInfo.User), tostring(reqInfo.Link), tostring(reqInfo.ThumbPath), tostring(reqInfo.ExtraJson))
    self:ShareToChannel(reqInfo, bShareToWechat and ShareModuleEnum.ShareChannel.WeChatFriend or ShareModuleEnum.ShareChannel.QQFriend)
  end
  
  local function failHandler()
    Log.Error("LoadAssetFailed")
  end
  
  self:ResPathToNativePath(urlPath, successHandler, failHandler)
end

return ShareModule
