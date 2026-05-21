local UMG_ShareUIPanel_C = _G.NRCPanelBase:Extend("UMG_ShareUIPanel_C")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local TimeoutEventListener = require("Common.TimeoutEventListener")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local CommonUtils = require("NewRoco.Utils.CommonUtils")
local ShareVerifier = require("NewRoco.Modules.System.Share.ShareVerifier")

function UMG_ShareUIPanel_C:OnActive()
  self.CanClose = false
  self.data = self.module:GetData()
  self.IsShareLock = false
  self.ShareChannelData = nil
  self.IsBanQRCode = false
  self.IsBanInfo = false
  self.IsPlaySubPanelCardAnim = false
  self.IsPlaySubPanelVideoAnim = false
  self.IsPlayPetPhotoAnim = false
  self.IsPlayHBPhotoAnim = false
  self.IsChannelQRCodeChange = false
  self.IsShowPlayerInfo = true
  self.LockEventListener = TimeoutEventListener()
  self.ChannelQRCodeEventListener = TimeoutEventListener()
  self:OnAddEventListener()
  self:InitShareWayList()
  self:InitSubUmg()
  self:InitReward()
  self:InitPlayerInfo()
  self:PlayInAnim()
  self:ShowCloseMoreBtn(false)
  self:BindInputAction()
  local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
  if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingPetVideo, false)
  end
end

function UMG_ShareUIPanel_C:OnDeactive()
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.CloseMoreBtn)
  _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnDeliverMessageNotify, self.OnShareSuccess)
  self.Button.OnClicked:Remove(self, self.OnShowPlayInfo)
end

function UMG_ShareUIPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.CloseMoreBtn, self.OnCloseMoreBtn)
  self.WidgetLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnDeliverMessageNotify, self.OnShareSuccess)
  self.Button.OnClicked:Add(self, self.OnShowPlayInfo)
end

function UMG_ShareUIPanel_C:InitTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  local titleList = self.titleConf.subtitle
  local subPanel = self.WidgetLoader:GetPanel()
  if subPanel then
    for _, v in ipairs(titleList) do
      if v.type_name == subPanel.name then
        self.Title1:SetSubtitle(v.subtitle)
        break
      end
    end
  end
end

function UMG_ShareUIPanel_C:InitShareWayList()
  if CommonUtils.IsGameCloudEnv() then
    Log.Debug("[UMG_ShareUIPanel_C:InitShareWayList] is game cloud env")
    self.RightList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LeftList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local tableId = _G.DataConfigManager.ConfigTableId.SHARE_CONF
  local allData = _G.DataConfigManager:GetAllByTableID(tableId)
  local leftList = {}
  local rightList = {}
  local loginPackData, moreShareWayData
  local shareType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareType)
  for _, shareWayData in pairs(allData) do
    if shareWayData.name == "more" then
      moreShareWayData = {
        share_icon = shareWayData.share_icon,
        name = shareWayData.name
      }
    elseif shareWayData.name == "imageQRcode" then
      local channelBanId = shareWayData.system_control_limit
      self.IsBanQRCode = false
      if channelBanId and not _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckShareChannelIsOpen, channelBanId) then
        self.IsBanQRCode = true
      end
    elseif shareWayData.name == "information" then
      local channelBanId = shareWayData.system_control_limit
      self.IsBanInfo = false
      if channelBanId and not _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckShareChannelIsOpen, channelBanId) then
        self.IsBanInfo = true
      end
    else
      local isOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckShareChannelOpen, shareWayData, shareType)
      if isOpen then
        local data = {
          share_icon = shareWayData.share_icon,
          name = shareWayData.name,
          qrcodeShow = shareWayData.qrcode_scenario,
          qrcodeLink = shareWayData.qrcode_link
        }
        if shareWayData.button_area[1] == _G.Enum.ShareButtonArea.SBA_FUNCHITONAL_AREA then
          if shareWayData.name == "copy" then
            if self.data.CurShareData.shareBaseId == _G.Enum.ShareButtonType.SBT_TEAM_SHARE then
              table.insert(leftList, data)
            end
          else
            table.insert(leftList, data)
          end
        else
          table.insert(rightList, data)
          if not loginPackData then
            local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
            local loginChannel = tostring(accountInfo.plat_info.cli_login_channel)
            if table.contains(shareWayData.pkg_channel_list, loginChannel) then
              loginPackData = data
            end
          end
        end
      end
    end
  end
  local showDataList = {}
  local moreDataList = {}
  for i, v in ipairs(rightList) do
    if i < 3 then
      table.insert(showDataList, v)
    elseif loginPackData then
      if v ~= loginPackData then
        table.insert(moreDataList, v)
      end
    else
      table.insert(moreDataList, v)
    end
  end
  if #moreDataList > 0 then
    table.insert(showDataList, moreShareWayData)
  end
  if loginPackData then
    table.insert(showDataList, 3, loginPackData)
  end
  if #showDataList > 0 then
    self.RightList:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RightList:InitGridView(showDataList)
    
    local function cb()
      local data = {moreDataList = moreDataList}
      self.ShareUIMore:Init(data)
    end
    
    self.delayId = _G.DelayManager:DelayFrames(1, cb, self)
  else
    self.RightList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.LeftList:InitGridView(leftList)
end

function UMG_ShareUIPanel_C:InitSubUmg()
  local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
  local widgetClass = sharePartConf.umg_path
  if widgetClass then
    local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(widgetClass)
    self.WidgetLoader:SetWidgetClass(softClassPath)
    self.data.CurShareData.IsBanQRCode = self.IsBanQRCode
    self.data.CurShareData.IsBanInfo = self.IsBanInfo
    if self.data.CurShareData.shareBaseId == _G.Enum.ShareButtonType.SBT_PET then
      if self.data.CurShareData.petData and next(self.data.CurShareData.petData) then
        local petData = {}
        table.deepCopy(self.data.CurShareData.petData, petData)
        local newPetData = self:GetNewPetData(petData)
        self.data.CurShareData.petData = newPetData
      else
        self.data.CurShareData.petData = {}
      end
    end
    self.WidgetLoader:LoadPanel(self, self.data.CurShareData)
  end
end

function UMG_ShareUIPanel_C:InitReward()
  if CommonUtils.IsGameCloudEnv() then
    Log.Debug("[UMG_ShareUIPanel_C:InitReward] is game cloud env")
    self.ShareUIReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if 0 == self.data.CurShareData.rewardGetState and self.RightList:GetItemCount() > 0 then
    local function cb()
      local firstItem = self.RightList:GetItemByIndex(0)
      
      local pos, _ = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), firstItem:GetCachedGeometry(), UE4.FVector2D(-1000, 0))
      local data = {
        shareBaseId = self.data.CurShareData.shareBaseId,
        pos = pos,
        isUpAnim = false
      }
      self.ShareUIReward:Init(data)
    end
    
    self.delayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_ShareUIPanel_C:ExecuteShareChannel(data)
  self.ShareChannelData = data
  local way = data.name
  if "more" == way then
    self:ExecuteMore()
  elseif "copy" == way then
    self:ExecuteCopy()
  elseif "save" == way then
    self:ExecuteSave()
  else
    self:ExecuteShare()
  end
end

function UMG_ShareUIPanel_C:ChooseLoginChannel(playerInfo, shareWayData, shareData)
  if playerInfo.loginChannelType == Enum.CliLoginChannel.CLC_WX then
    if shareWayData.login_required ~= Enum.ActivityLoginRequired.ALR_LOGIN_QQ then
      table.insert(shareData, shareWayData)
    end
  elseif playerInfo.loginChannelType == Enum.CliLoginChannel.CLC_QQ and shareWayData.login_required ~= Enum.ActivityLoginRequired.ALR_LOGIN_WECHAT then
    table.insert(shareData, shareWayData)
  end
end

function UMG_ShareUIPanel_C:OnAnimationFinished(Animation)
  if Animation == self.In_Photo or Animation == self.In_Video or Animation == self.In_Card then
    local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
    if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseShareCameraPanel)
      local subSharePanel = self.WidgetLoader:GetPanel()
      subSharePanel.PhotoSub.PlayBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    local shareBaseButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareBaseButtonType)
    if shareBaseButtonType == _G.Enum.ShareButtonType.SBT_PET then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainPanelVisibility, false)
    end
    if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_PICTURE then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetMainPanelPetImage3DActive, true)
    end
    self:PlayAnimation(self.Loop)
    self.CanClose = true
  elseif Animation == self.Loop then
    self:PlayAnimation(self.Loop)
  elseif Animation == self.Out or Animation == self.Out_Card then
    local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
    if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.IsShareRecordVideo) and sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
      local gid = self:GetPetShareGid()
      _G.NRCModuleManager:DoCmd(ShareModuleCmd.EndRecordVideo, gid)
    end
    self:CancelDelayId()
    self:OnClose()
  end
end

function UMG_ShareUIPanel_C:OnClickCloseBtn(isRePlayVideo)
  if not self.CanClose then
    return
  end
  self.CanClose = false
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_ShareUIPanel_C:OnClickCloseBtn")
  local shareBaseButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareBaseButtonType)
  if shareBaseButtonType == _G.Enum.ShareButtonType.SBT_PET then
    if _G.GlobalConfig.DebugOpenUI then
      NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PlayShareVideoEnablePetMain, true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainPanelVisibility, true)
    if not isRePlayVideo then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.VideoShareResetPetMainPet3D)
    end
  end
  local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
  if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_CARD then
    self:PlayAnimation(self.Out_Card)
    local subSharePanel = self.WidgetLoader:GetPanel()
    subSharePanel:PlayOutCard()
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_PICTURE then
    self:PlayAnimation(self.Out)
    local subSharePanel = self.WidgetLoader:GetPanel()
    subSharePanel:PlayOutAnim()
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_HB_PHOTO then
    self:PlayAnimation(self.Out)
    local subSharePanel = self.WidgetLoader:GetPanel()
    subSharePanel:PlayOutAnim()
  else
    self:PlayAnimation(self.Out)
  end
end

function UMG_ShareUIPanel_C:OnCloseMoreBtn()
  if self.ShareUIMore.IsPlayOut then
    return
  end
  self:ShowCloseMoreBtn(false)
  if self.ShareUIMore:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.ShareUIMore:PlayOutAnim()
  end
  local subSharePanel = self.WidgetLoader:GetPanel()
  local shareBaseButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareBaseButtonType)
  if shareBaseButtonType == _G.Enum.ShareButtonType.SBT_ROLE_CARD then
    subSharePanel:ShowSelectBox(false)
  elseif shareBaseButtonType == _G.Enum.ShareButtonType.SBT_PVP_RECORD then
    subSharePanel:HideSelectBoxByShare()
  end
end

function UMG_ShareUIPanel_C:ExecuteMore()
  if self.ShareUIMore:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.ShareUIMore:PlayOutAnim()
  elseif self.ShareUIMore.HasContent then
    self:ShowCloseMoreBtn(true)
    self.ShareUIMore:PlayInAnim()
  end
end

function UMG_ShareUIPanel_C:ExecuteCopy()
  local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
  if sharePartButtonType == _G.Enum.ShareButtonType.SBT_TEAM_SHARE then
    self:SendShareTLog()
    local subSharePanel = self.WidgetLoader:GetPanel()
    local FullCode = subSharePanel:AddCodeAnnotation()
    UE4.UNRCStatics.ClipboardCopy(FullCode)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy)
  end
end

function UMG_ShareUIPanel_C:ExecuteSave()
  if self:CheckIsShareLock() then
    return
  end
  self:HideCloseMoreBtnByShare()
  self:SetShareLock(true)
  self.LockEventListener:StartGlobalEventListener(2, "UMG_ShareUIPanel_C", self, ShareUIModuleEvent.RELEASE_SHARE_LOCK, self.OnReleaseLock)
  self:SendShareTLog()
  local shareType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareType)
  if shareType == _G.Enum.ShareType.STP_VIDEO then
    self:ExecuteSaveByVideo()
  elseif shareType == _G.Enum.ShareType.STP_APPLET then
    self:ExecuteSaveByMiniPrograms()
  else
    self:ExecuteSaveByPicture()
  end
end

function UMG_ShareUIPanel_C:ExecuteShare()
  if self:CheckIsShareLock() then
    return
  end
  self:HideCloseMoreBtnByShare()
  self:SetShareLock(true)
  self.LockEventListener:StartGlobalEventListener(2, "UMG_PartnerAndPeer_C", self, ShareUIModuleEvent.RELEASE_SHARE_LOCK, self.OnReleaseLock)
  self:SendShareTLog()
  local shareType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareType)
  if shareType == _G.Enum.ShareType.STP_VIDEO then
    self:ExecuteShareByVideo()
  elseif shareType == _G.Enum.ShareType.STP_APPLET then
    self:ExecuteShareByMiniPrograms()
  elseif shareType == _G.Enum.ShareType.STP_QRCODE then
    self:ExecuteOpenQRCodePanel()
  else
    self:ExecuteShareByPicture()
  end
end

function UMG_ShareUIPanel_C:ExecuteOpenQRCodePanel()
  local openId = "nil"
  local platId = -1
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      openId = needData.openid or "nil"
      platId = needData.plat_info.plat_id or -1
    end
  end
  local url = ""
  if _G.AppMain:GetFormalPipeline() then
    url = string.format("https://prod-http-01.nrc.qq.com/simShareCode?openid=%s&platid=%d&uin=%d", openId, platId, uin)
  else
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" and needData.serverName then
      local gameServerId = needData.serverName
      url = string.format("http://innerhttp-test.nrc.woa.com/%s/http/simShareCode?openid=%s&platid=%d&uin=%d", gameServerId, openId, platId, uin)
    end
  end
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetUrl(url)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(Service, Status)
      if Status == UE4.EHttpServiceStatus.RspSuccess then
        local RspContent = Service:GetRspContent()
        local gift_code = RspContent:match("\"gift_code\":\"([^\"]+)\"")
        if gift_code then
          local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
          if sharePartConf then
            local giftCode = string.gsub(gift_code, "data:image/png;base64,", "")
            local conf = _G.DataConfigManager:GetActivityWebsitePartConf(310004)
            _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenQCodePanel, conf, nil, giftCode)
          end
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
        end
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
      end
      self:SetShareLock(false)
    end
  })
end

function UMG_ShareUIPanel_C:SetShareLock(enable)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.IsShareLock == enable then
    return
  end
  self.IsShareLock = enable
  local sharePartId = self.data.CurShareData.sharePartId
  if sharePartId == _G.Enum.ShareButtonType.SBT_PET_PICTURE then
    local subSharePanel = self.WidgetLoader:GetPanel()
    subSharePanel.PhotoSub.UMG_PetImage3D:SetSharePhotoPetAnim(enable)
  end
end

function UMG_ShareUIPanel_C:CheckIsShareLock()
  return self.IsShareLock
end

function UMG_ShareUIPanel_C:GetPhotoPath()
  local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })
  if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
    UE.UNRCStatics.MakeDirectory(TempPhotos)
  end
  local GUID = UE.UKismetGuidLibrary.NewGuid()
  local FileNameTmp = UE.UKismetGuidLibrary.Conv_GuidToString(GUID)
  local FileName = FileNameTmp .. ".jpg"
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({TempPhotos, FileName})
  PhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(PhotoPath)
  local WaterMaskPhotoPath = UE.UBlueprintPathsLibrary.Combine({TempPhotos, FileName})
  WaterMaskPhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(WaterMaskPhotoPath)
  return PhotoPath, WaterMaskPhotoPath
end

function UMG_ShareUIPanel_C:SavePhoto(isSaveLocal)
  local function OnPermissionCallback(moveToAlbum)
    self:SetShareLock(false)
    
    local PhotoPath, WaterMaskPhotoPath = self:GetPhotoPath()
    local sharePanel = self:GetSavePhotoShareUmg()
    local shareBaseId = self.data.CurShareData.shareBaseId
    local sharePartId = self.data.CurShareData.sharePartId
    local subSharePanel = self.WidgetLoader:GetPanel()
    if not self.data.CurShareData.IsBanQRCode and subSharePanel.ShowShareChannelCode then
      self.IsChannelQRCodeChange = true
      self.ChannelQRCodeEventListener:StartGlobalEventListener(2, "UMG_ShareUIPanel_C", self, ShareUIModuleEvent.RELEASE_SHARE_LOCK, self.ResetChannelShareQRCode)
      subSharePanel:ShowShareChannelCode(self.ShareChannelData.qrcodeShow, self.ShareChannelData.qrcodeLink)
    end
    local result
    if sharePartId == _G.Enum.ShareButtonType.SBT_PET_CARD then
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), sharePanel, PhotoPath, false, 2)
    elseif shareBaseId == _G.Enum.ShareButtonType.SBT_PHOTO then
      local Width = subSharePanel.FileTexture:Blueprint_GetSizeX()
      local Height = subSharePanel.FileTexture:Blueprint_GetSizeY()
      local DesiredSize = UE.FVector2D(Width, Height)
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImageByCustomSize(UE4Helper.GetCurrentWorld(), sharePanel, WaterMaskPhotoPath, DesiredSize)
    else
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), sharePanel, PhotoPath)
    end
    if isSaveLocal then
      if result then
        if moveToAlbum then
          local destPath = UE.UPlatformImageLibrary.SaveImageToAlbum(PhotoPath)
          if RocoEnv.PLATFORM_WINDOWS then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.save_success_location, destPath), nil, nil, 2)
          elseif RocoEnv.PLATFORM_OPENHARMONY then
            return
          else
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_success_tips, nil, nil, 2)
          end
        end
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_fail_tips, nil, nil, 2)
      end
    end
  end
  
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.AccessAlbum)
  if not bGranted and (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS) then
    self:SetShareLock(false)
    if not NRCModuleManager:DoCmd(ShareModuleCmd.CheckPermission, self.ShareChannelData.name, UE.ENRCPermissionType.AccessAlbum) then
      return
    end
    self.requestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.AccessAlbum, {
      self,
      function(_, bGranted)
        self.requestCode = nil
        if bGranted then
          OnPermissionCallback(true)
        else
          self:LogError("!!!Permission!!!")
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_fail_tips, nil, nil, 2)
        end
      end
    })
  else
    OnPermissionCallback(true)
  end
end

function UMG_ShareUIPanel_C:GetSavePhotoShareUmg()
  return self.WidgetLoader:GetPanel().PhotoSub
end

function UMG_ShareUIPanel_C:CancelDelayId()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

function UMG_ShareUIPanel_C:ExecuteShareByPicture()
  local PhotoPath, WaterMaskPhotoPath = self:GetPhotoPath()
  self:SavePhoto(false)
  local absolutePath = UE.UNRCStatics.ConvertToAbsolutePath(PhotoPath, true)
  if UE.UNRCStatics.FileExists(PhotoPath) then
    if not self:VerifyShareFileOrTips(absolutePath, ShareVerifier.FileKind.Pic) then
      self:SetShareLock(false)
      return
    end
    NRCModuleManager:DoCmd(ShareModuleCmd.SharePic, absolutePath, self.ShareChannelData.name)
  else
    local sharePanel = self:GetSavePhotoShareUmg()
    local shareBaseId = self.data.CurShareData.shareBaseId
    local sharePartId = self.data.CurShareData.sharePartId
    local result
    local writtenPath = PhotoPath
    if sharePartId == _G.Enum.ShareButtonType.SBT_PET_CARD then
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), sharePanel, PhotoPath, false, 2)
    elseif shareBaseId == _G.Enum.ShareButtonType.SBT_PHOTO then
      local subSharePanel = self.WidgetLoader:GetPanel()
      local Width = subSharePanel.FileTexture:Blueprint_GetSizeX()
      local Height = subSharePanel.FileTexture:Blueprint_GetSizeY()
      local DesiredSize = UE.FVector2D(Width, Height)
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImageByCustomSize(UE4Helper.GetCurrentWorld(), sharePanel, WaterMaskPhotoPath, DesiredSize)
      writtenPath = WaterMaskPhotoPath
    else
      result = UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), sharePanel, PhotoPath)
    end
    if result then
      local writtenAbs = UE.UNRCStatics.ConvertToAbsolutePath(writtenPath, true)
      ShareVerifier.Register(writtenAbs)
      if not self:VerifyShareFileOrTips(absolutePath, ShareVerifier.FileKind.Pic) then
        self:SetShareLock(false)
        return
      end
      NRCModuleManager:DoCmd(ShareModuleCmd.SharePic, absolutePath, self.ShareChannelData.name)
    else
      Log.Error("save widget error")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
    end
  end
  self:SetShareLock(false)
end

function UMG_ShareUIPanel_C:VerifyShareFileOrTips(absPath, kind)
  local ok, reason = ShareVerifier.Verify(absPath, kind)
  if ok then
    return true
  end
  Log.Error("[Share] Verify failed", absPath, kind, reason)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
  return false
end

function UMG_ShareUIPanel_C:ExecuteShareByVideo()
  local sharePartId = self.data.CurShareData.sharePartId
  local SharePartConf = _G.DataConfigManager:GetSharePartConf(sharePartId, true)
  if sharePartId == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
    local gid = self:GetPetShareGid()
    NRCModuleManager:DoCmd(ShareModuleCmd.ShareLocalVideo, self.ShareChannelData.name, gid)
  elseif SharePartConf and SharePartConf.share_button_type == _G.Enum.ShareButtonType.SBT_RECORD_VIDEO then
    local shareVideoName = self.data.CurShareData.shareVideoName
    NRCModuleManager:DoCmd(ShareModuleCmd.ShareLocalVideo, self.ShareChannelData.name, shareVideoName)
  end
end

function UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms()
  local openId = "nil"
  local platId = -1
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      openId = needData.openid or "nil"
      platId = needData.plat_info.plat_id or -1
    end
  end
  local url = ""
  if _G.AppMain:GetFormalPipeline() then
    url = string.format("https://prod-http-01.nrc.qq.com/simShareCode?openid=%s&platid=%d&uin=%d", openId, platId, uin)
  else
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" and needData.serverName then
      local gameServerId = needData.serverName
      url = string.format("http://innerhttp-test.nrc.woa.com/%s/http/simShareCode?openid=%s&platid=%d&uin=%d", gameServerId, openId, platId, uin)
    end
  end
  Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==url==", url)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetUrl(url)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(Service, Status)
      if Status == UE4.EHttpServiceStatus.RspSuccess then
        Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==http is success!!!")
        local RspContent = Service:GetRspContent()
        local gift_code = RspContent:match("\"gift_code\":\"([^\"]+)\"")
        Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==gift_code==", gift_code)
        if gift_code then
          Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==sharePartId==", self.data.CurShareData.sharePartId)
          local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
          if sharePartConf then
            local giftCode = gift_code
            if RocoEnv.PLATFORM_WINDOWS then
              giftCode = string.gsub(giftCode, "data:image/png;base64,", "")
            end
            local title = sharePartConf.wechat_applet_title
            local desc = sharePartConf.wechat_applet_des
            local img = sharePartConf.wechat_applet_img
            local page = sharePartConf.wechat_applet_first_page
            if RocoEnv.PLATFORM_WINDOWS or RocoEnv.PLATFORM_OPENHARMONY then
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==share in pc or harmony")
              local conf = _G.DataConfigManager:GetActivityWebsitePartConf(310004)
              _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenQCodePanel, conf, nil, giftCode)
            else
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==share in phone")
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==name==", self.ShareChannelData.name)
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==page==", page)
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==img==", img)
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==title==", title)
              Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==desc==", desc)
              _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.ShareMiniApp, self.ShareChannelData.name, page, img, giftCode, title, desc)
            end
          end
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
        end
      else
        Log.Debug("UMG_ShareUIPanel_C:ExecuteShareByMiniPrograms==http is fail!!!")
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
      end
      self:SetShareLock(false)
    end
  })
end

function UMG_ShareUIPanel_C:ExecuteSaveByPicture()
  self:SavePhoto(true)
end

function UMG_ShareUIPanel_C:ExecuteSaveByVideo()
  local sharePartId = self.data.CurShareData.sharePartId
  local SharePartConf = _G.DataConfigManager:GetSharePartConf(sharePartId, true)
  if sharePartId == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
    local gid = self:GetPetShareGid()
    NRCModuleManager:DoCmd(ShareModuleCmd.SaveVideoToAlbum, gid)
  elseif SharePartConf and SharePartConf.share_button_type == _G.Enum.ShareButtonType.SBT_RECORD_VIDEO then
    local shareVideoName = self.data.CurShareData.shareVideoName
    _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.SaveVideoToAlbum, shareVideoName)
  end
end

function UMG_ShareUIPanel_C:ExecuteSaveByMiniPrograms()
  self:ExecuteSaveByPicture()
end

function UMG_ShareUIPanel_C:SendShareTLog()
  local shareArgs = {
    shareWay = self.ShareChannelData.name,
    shareBaseId = self.data.CurShareData.shareBaseId,
    sharePartId = self.data.CurShareData.sharePartId
  }
  local shareRewardId
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(self.data.CurShareData.shareBaseId)
  if shareBaseConf then
    shareRewardId = shareBaseConf.goods_type
  end
  if shareRewardId and 0 ~= shareRewardId then
    shareArgs.shareRewardId = shareRewardId
  end
  local extraArgs = {}
  local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
  local subSharePanel = self.WidgetLoader:GetPanel()
  if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_VIDEO or sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_PICTURE then
    extraArgs.intparam1 = subSharePanel.data.petData.base_conf_id
    extraArgs.intparam2 = subSharePanel.data.petData.gid
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_REPORT then
    extraArgs.intparam1 = subSharePanel.data.reportData.pet_brief.base_conf_id
    extraArgs.intparam2 = subSharePanel.data.reportData.pet_brief.gid
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_CARD then
    extraArgs.intparam3 = subSharePanel:GetShareCardId()
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_TEAM_SHARE then
    local codeStr = subSharePanel:AddCodeAnnotation()
    extraArgs.stringparam1 = codeStr:gsub("\n", "/")
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PHOTO then
    local photoMode = NRCModuleManager:DoCmd(TakePhotosModuleCmd.GetCurPhotoMode)
    extraArgs.intparam1 = photoMode
  end
  _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.SendShareTLog, shareArgs, extraArgs)
end

function UMG_ShareUIPanel_C:ShowCloseMoreBtn(isShow)
  if isShow then
    self.CloseMoreBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.CloseMoreBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ShareUIPanel_C:OnLoadWidgetCallback(Panel)
  if Panel then
    self:InitTitle()
    if self.IsPlaySubPanelCardAnim then
      self.IsPlaySubPanelCardAnim = false
      local subSharePanel = self.WidgetLoader:GetPanel()
      subSharePanel:PlayInCard()
    end
    if self.IsPlaySubPanelVideoAnim then
      self.IsPlaySubPanelVideoAnim = false
      local subSharePanel = self.WidgetLoader:GetPanel()
      subSharePanel:PlayStampInAnim()
    end
    if self.IsPlayPetPhotoAnim then
      self.IsPlayPetPhotoAnim = false
      local subSharePanel = self.WidgetLoader:GetPanel()
      subSharePanel:PlayInAnim()
    end
    if self.IsPlayHBPhotoAnim then
      self.IsPlayHBPhotoAnim = false
      local subSharePanel = self.WidgetLoader:GetPanel()
      subSharePanel:PlayInAnim()
    end
  end
end

function UMG_ShareUIPanel_C:GetNewPetData(petData)
  if not petData then
    Log.Error("UMG_ShareUIPanel_C:GetNewPetData petdata is nil")
    return petData
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetList then
    for i, data in ipairs(battlePetList) do
      if petData.gid == data.gid then
        return data
      end
    end
  end
  local backpackPetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackPetInfo()
  if backpackPetList then
    for i, data in ipairs(backpackPetList) do
      if petData.gid == data.gid then
        return data
      end
    end
  end
  local housePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerHousePetInfo()
  if housePetList then
    for i, data in ipairs(housePetList) do
      if petData.gid == data.gid then
        return data
      end
    end
  end
  return petData
end

function UMG_ShareUIPanel_C:PetShareCardExpire(expire_ids)
  local sharePartId = self.data.CurShareData.sharePartId
  if sharePartId == _G.Enum.ShareButtonType.SBT_PET_CARD then
    local subSharePanel = self.WidgetLoader:GetPanel()
    for _, v in ipairs(expire_ids) do
      subSharePanel:OnCardExpire(v)
    end
  end
end

function UMG_ShareUIPanel_C:OpenShareCardDebugPanel()
  local sharePartId = self.data.CurShareData.sharePartId
  if sharePartId == _G.Enum.ShareButtonType.SBT_PET_CARD then
    local subSharePanel = self.WidgetLoader:GetPanel()
    subSharePanel:OpenCardDebugPanel()
  end
end

function UMG_ShareUIPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_SharePanel")
  if mappingContext then
    mappingContext:BindAction("IA_CloseSharePanel", self, "OnPcClose2")
  end
end

function UMG_ShareUIPanel_C:OnPcClose2()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnClickCloseBtn()
end

function UMG_ShareUIPanel_C:OnShareSuccess(baseRet)
  if 0 ~= baseRet.retCode then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
  end
  self.LockEventListener:Stop()
  self:SetShareLock(false)
  self:ResetChannelShareQRCode()
end

function UMG_ShareUIPanel_C:PlayInAnim()
  local sharePartButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartButtonType)
  if sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
    self:PlayAnimation(self.In_Video, 0)
    self:PauseAnimation(self.In_Video)
    self.IsPlaySubPanelVideoAnim = true
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_CARD then
    self:PlayAnimation(self.In_Card)
    self.IsPlaySubPanelCardAnim = true
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_PET_PICTURE then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetMainPanelPetImage3DActive, false)
    self:PlayAnimation(self.In_Photo)
    self.IsPlayPetPhotoAnim = true
  elseif sharePartButtonType == _G.Enum.ShareButtonType.SBT_HB_PHOTO then
    self:PlayAnimation(self.In_Photo)
    self.IsPlayHBPhotoAnim = true
  else
    self:PlayAnimation(self.In_Photo)
  end
end

function UMG_ShareUIPanel_C:OnReleaseLock()
  self:SetShareLock(false)
end

function UMG_ShareUIPanel_C:ResetChannelShareQRCode()
  if self.IsChannelQRCodeChange then
    self.ChannelQRCodeEventListener:Stop()
    self.IsChannelQRCodeChange = false
    local subSharePanel = self.WidgetLoader:GetPanel()
    if subSharePanel.ResetShareChannelCode then
      subSharePanel:ResetShareChannelCode()
    end
  end
end

function UMG_ShareUIPanel_C:InitPlayerInfo()
  local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
  local isNeedShowPlayerInfo = sharePartConf.is_need_information
  if self.IsBanInfo or not isNeedShowPlayerInfo then
    self.Show:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Show:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_ShareUIPanel_C:OnShowPlayInfo()
  if self.IsShowPlayerInfo then
    self.Check:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsShowPlayerInfo = false
  else
    self.Check:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.IsShowPlayerInfo = true
  end
  local subSharePanel = self.WidgetLoader:GetPanel()
  if subSharePanel and subSharePanel.ShowPlayerInfoPanel then
    subSharePanel:ShowPlayerInfoPanel(self.IsShowPlayerInfo)
  end
end

function UMG_ShareUIPanel_C:HideCloseMoreBtnByShare()
  if self.CloseMoreBtn:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:ShowCloseMoreBtn(false)
    if self.ShareUIMore:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self.ShareUIMore:PlayOutAnim()
    end
    local subSharePanel = self.WidgetLoader:GetPanel()
    local shareBaseButtonType = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareBaseButtonType)
    if shareBaseButtonType == _G.Enum.ShareButtonType.SBT_ROLE_CARD then
      subSharePanel:HideSelectBoxByShare()
    elseif shareBaseButtonType == _G.Enum.ShareButtonType.SBT_PVP_RECORD then
      subSharePanel:HideSelectBoxByShare()
    end
  end
end

function UMG_ShareUIPanel_C:PlayPetVideoShareInAnim()
  self:StopAllAnimations()
  self:PlayAnimation(self.In_Video)
end

function UMG_ShareUIPanel_C:GetPetShareGid()
  if self.data.CurShareData.petData and self.data.CurShareData.petData.gid then
    return self.data.CurShareData.petData.gid
  end
  return 0
end

return UMG_ShareUIPanel_C
