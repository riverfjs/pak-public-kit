local ShareUIModule = NRCModuleBase:Extend("ShareUIModule")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")

function ShareUIModule:OnConstruct()
  _G.ShareUIModuleCmd = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleCmd")
  self.data = self:SetData("ShareUIModuleData", "NewRoco.Modules.System.ShareUI.ShareUIModuleData")
  self.IsLoadingPanelOpen = true
  self.IsOpenWebView = false
  self.IsSharingPetVideo = false
  self.IsSharingMagicVideo = false
  self.CheckRewardStateList = {}
end

function ShareUIModule:OnActive()
  self:RegPanel("ShareUIPanel", "UMG_ShareUIPanel", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self:RegPanel("ScreenshotSharing", "UMG_ScreenshotSharing", _G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCEventCenter:RegisterEvent("ShareUIModule", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.LoadingPanelIsOpen)
  _G.NRCEventCenter:RegisterEvent("ShareUIModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.LoadingPanelIsClose)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnOpenWebView, self.OnOpenWebView)
  _G.NRCEventCenter:RegisterEvent("ShareUIModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SHARE_FORM_EXPIRE_NOTIFY, self.OnCardExpire)
end

function ShareUIModule:RegPanel(name, path, layer, openAnim, closeAnim)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/ShareUI/Res/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  self:RegisterPanel(registerData)
end

function ShareUIModule:OnRelogin()
end

function ShareUIModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.LoadingPanelIsOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.LoadingPanelIsClose)
  _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnOpenWebView, self.OnOpenWebView)
end

function ShareUIModule:OnDestruct()
end

local function ExtractVersionStrNumbers(inputVerString)
  local numbers = table.new(4, 0)
  if inputVerString then
    for num in string.gmatch(inputVerString, "([^%.]+)") do
      table.insert(numbers, tonumber(num))
    end
  end
  return numbers
end

function ShareUIModule:OnCmdCheckIsOpen(shareBaseId)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE)
  if isBan then
    return false
  end
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(shareBaseId)
  if not shareBaseConf then
    return false
  end
  local startTime = shareBaseConf.start_time
  local endTime = shareBaseConf.end_time
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  if startTime and endTime and (startTime > serverTimestamp or endTime < serverTimestamp) then
    return false
  end
  local channelConfigID = shareBaseConf.system_control_limit[1]
  if channelConfigID and not self:OnCmdCheckShareChannelIsOpen(channelConfigID) then
    return false
  end
  return true
end

function ShareUIModule:OnCmdOpenShareUIPanel(data)
  self.data.CurShareData = data
  self:OnCmdGetShareRewardInfoReq()
end

function ShareUIModule:OnCmdCloseShareUIPanel(isRePlayVideo)
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:OnClickCloseBtn(isRePlayVideo)
  end
end

function ShareUIModule:OnCmdShareChannelExecute(data)
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:ExecuteShareChannel(data)
  end
end

function ShareUIModule:OnCmdOpenScreenshotSharingPanel()
  if self.IsLoadingPanelOpen then
    return
  end
  if self.IsOpenWebView then
    return
  end
  if NRCModuleManager:DoCmd(TakePhotosModuleCmd.CheckPhotoFileViewUI) then
    return
  end
  if self.IsSharingPetVideo then
    return
  end
  if self.IsSharingMagicVideo then
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    return
  end
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  local isInGuide = false
  if myPlayer then
    isInGuide = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NEWPLAYER_GUIDE_BLACKMASK) or myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NEWPLAYER_GUIDE)
  end
  if isInGuide then
    return
  end
  if self:HasPanel("ShareUIPanel") then
    return
  end
  if self:HasPanel("ScreenshotSharing") then
    self:ClosePanel("ScreenshotSharing")
  end
  self:OpenPanel("ScreenshotSharing")
end

function ShareUIModule:OnCmdGetPlayerInfo()
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local name = playerInfo.name
  local uin = "UID:" .. playerInfo.uin
  local headPath = ""
  local cardInfo = playerInfo.additional_data.card_brief_info
  if cardInfo then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(cardInfo.card_icon_selected)
    if cardIconConf then
      local avatarPath = cardIconConf.icon_resource_path
      headPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/", avatarPath, avatarPath)
    end
  end
  return {
    name = name,
    uin = uin,
    headPath = headPath
  }
end

function ShareUIModule:OnCmdSendShareTLog(shareArgs, extraArgs)
  local key = "InGameShareLog"
  local tempString = "%s|%s|%s|%s|%d|%d|%s|%d|%s|%d|%s|%d|%d|%d|%d|%d|%d|%s|%s|%s"
  local gameServerId = "nil"
  local gameTime = os.date("%Y-%m-%d %H:%M:%S")
  local gameAppId = "1110613799"
  local platId = -1
  local zoneId = 0
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local shareChannel = shareArgs.shareWay
  local shareBaseID = shareArgs.shareBaseId
  local sharePartID = shareArgs.sharePartId
  local shareRewardID = 0
  if shareArgs.shareRewardId then
    shareRewardID = shareArgs.shareRewardId
  end
  local extraTable = {
    intparam1 = 0,
    intparam2 = 0,
    intparam3 = 0,
    stringparam1 = "nil",
    stringparam2 = "nil",
    stringparam3 = "nil"
  }
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      gameServerId = needData.serverName or "nil"
      platId = needData.plat_info.plat_id or -1
      zoneId = needData.zoneId or 0
      openId = needData.openid or "nil"
    end
  end
  if extraArgs then
    for k, v in pairs(extraArgs) do
      extraTable[k] = v
    end
  end
  local value = string.format(tempString, key, gameServerId, gameTime, gameAppId, platId, zoneId, openId, uin, roleName, level, shareChannel, shareBaseID, sharePartID, shareRewardID, extraTable.intparam1, extraTable.intparam2, extraTable.intparam3, extraTable.stringparam1, extraTable.stringparam2, extraTable.stringparam3)
  Log.Debug("ShareUIModule:OnCmdSendShareTLog==value==", value)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function ShareUIModule:OnCmdGetShareRewardInfoReq()
  local req = _G.ProtoMessage:newZonePlayerShareInfoReq()
  req.share_base_id, req.share_part_id = self:GetShareSendRemoteId()
  req.opt = 2
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SHARE_INFO_REQ, req, self, self.GetShareRewardInfoRsp, false, true)
end

function ShareUIModule:GetShareRewardInfoRsp(rsp)
  if 1 == rsp.opt then
    if 0 == rsp.ret_info.ret_code then
      self.data.CurShareData.rewardGetState = rsp.reward_received
      local shareBaseId = self.data.CurShareData.shareBaseId
      local shareRewardConf = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetShareRewardItemInfo, shareBaseId)
      if shareRewardConf then
        local rewardsList = {
          {
            id = shareRewardConf.goods_id,
            type = shareRewardConf.goods_type,
            num = shareRewardConf.goods_count
          }
        }
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardsList, "")
      end
      if self:HasPanel("ShareUIPanel") then
        local panel = self:GetPanel("ShareUIPanel")
        panel.ShareUIReward:ShowPanel(false)
      end
    else
      local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
    end
  elseif 2 == rsp.opt then
    local rewardGetState = 0
    if 0 == rsp.ret_info.ret_code then
      rewardGetState = rsp.reward_received
    else
      local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
    end
    if self.CheckRewardStateList and #self.CheckRewardStateList > 0 then
      local removeData = table.remove(self.CheckRewardStateList, 1)
      local data = {
        shareBaseId = removeData.shareBaseId,
        sharePartId = removeData.sharePartId,
        rewardGetState = rewardGetState
      }
      _G.NRCEventCenter:DispatchEvent(ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, data)
    else
      self.data.CurShareData.rewardGetState = rewardGetState
      if self:HasPanel("ShareUIPanel") then
        return
      end
      self:OpenPanel("ShareUIPanel")
    end
  end
end

function ShareUIModule:OnCmdTryGetShareRewardReq()
  if self.data.CurShareData and 0 == self.data.CurShareData.rewardGetState then
    local req = _G.ProtoMessage:newZonePlayerShareInfoReq()
    req.share_base_id, req.share_part_id = self:GetShareSendRemoteId()
    req.opt = 1
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SHARE_INFO_REQ, req, self, self.GetShareRewardInfoRsp, false, true)
  end
end

function ShareUIModule:OnCmdGetShareRewardItemInfo(shareBaseId)
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(shareBaseId)
  if shareBaseConf then
    local rewardId = shareBaseConf.goods_type
    if rewardId and 0 ~= rewardId then
      return _G.DataConfigManager:GetShareRewardConf(rewardId)
    end
  end
  return nil
end

function ShareUIModule:OnCmdGetSharePartIdByShareBaseId(shareBaseId, index)
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(shareBaseId)
  if shareBaseConf then
    local sharePartList = shareBaseConf.base_id
    if sharePartList and #sharePartList > 0 then
      if index then
        return sharePartList[index]
      else
        return sharePartList[1]
      end
    end
  end
  return nil
end

function ShareUIModule:OnCmdCheckShareChannelOpen(channelData, shareType)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE)
  if isBan then
    return false
  end
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_WX and channelData.login_required == Enum.ActivityLoginRequired.ALR_LOGIN_QQ then
    return false
  end
  if playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_QQ and channelData.login_required == Enum.ActivityLoginRequired.ALR_LOGIN_WECHAT then
    return false
  end
  if channelData.name ~= "copy" and channelData.share_type and not table.contains(channelData.share_type, shareType) then
    return false
  end
  local channelBanId = channelData.system_control_limit
  if channelBanId and not self:OnCmdCheckShareChannelIsOpen(channelBanId) then
    return false
  end
  local isPC = RocoEnv.IS_EDITOR or RocoEnv.PLATFORM_WINDOWS
  if channelData.name ~= "save" and channelData.name ~= "copy" and channelData.name ~= "more" and channelData.name ~= "WeChatFriend" and channelData.name ~= "WeChatMoments" and channelData.name ~= "QQFriend" and channelData.name ~= "Qzone" and channelData.name ~= "Qrcode" then
    if isPC and (shareType ~= _G.Enum.ShareType.STP_APPLET or shareType ~= _G.Enum.ShareType.STP_QRCODE) then
      return false
    elseif not isPC and not _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.CheckAppInstall, channelData.name) then
      return false
    end
  end
  return true
end

function ShareUIModule:GetShareSendRemoteId(shareBaseId, index)
  local sendBaseId, sendPartId
  if shareBaseId then
    sendBaseId = shareBaseId
    sendPartId = self:OnCmdGetSharePartIdByShareBaseId(shareBaseId, index)
  elseif self.data and self.data.CurShareData then
    sendBaseId = self.data.CurShareData.shareBaseId
    sendPartId = sendBaseId
    local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
    if sharePartConf and sharePartConf.share_button_type then
      sendPartId = sharePartConf.share_button_type
    end
  end
  return sendBaseId, sendPartId
end

function ShareUIModule:OnCmdGetShareType()
  local sharePartConf = _G.DataConfigManager:GetSharePartConf(self.data.CurShareData.sharePartId)
  if sharePartConf and sharePartConf.share_type then
    return sharePartConf.share_type
  end
  return nil
end

function ShareUIModule:LoadingPanelIsOpen()
  self.IsLoadingPanelOpen = true
end

function ShareUIModule:LoadingPanelIsClose()
  self.IsLoadingPanelOpen = false
end

function ShareUIModule:OnWebViewOptNotify(webViewRet)
  if webViewRet.msgType == NRCSDKManagerEnum.WebViewMsgType.CloseWebViewURL then
    self.IsOpenWebView = false
  end
end

function ShareUIModule:OnCmdUpdateSharePartId(sharePartId)
  self.data.CurShareData.sharePartId = sharePartId
end

function ShareUIModule:OnCmdShowShareUIPanelCloseMoreBtn(isShow)
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:ShowCloseMoreBtn(isShow)
  end
end

function ShareUIModule:OnOpenWebView()
  self.IsOpenWebView = true
end

function ShareUIModule:OnCmdShowShareUIPanelPetImage3D(data)
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:ShowPetImage3D(data)
  end
end

function ShareUIModule:OnCmdGetSharePartButtonType()
  local sharePartId = self.data.CurShareData.sharePartId
  local sharePartConf = _G.DataConfigManager:GetSharePartConf(sharePartId)
  return sharePartConf.share_button_type
end

function ShareUIModule:OnCmdGetShareBaseButtonType()
  local shareBaseId = self.data.CurShareData.shareBaseId
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(shareBaseId)
  return shareBaseConf.share_button_type
end

function ShareUIModule:OnCardExpire(notify)
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:PetShareCardExpire(notify.expire_ids)
  end
end

function ShareUIModule:OnCmdOpenShareCardDebugPanel()
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:OpenShareCardDebugPanel()
  end
end

function ShareUIModule:OnCmdCheckRewardStateEntrance(shareBaseId)
  local share_base_id, share_part_id = self:GetShareSendRemoteId(shareBaseId)
  local req = _G.ProtoMessage:newZonePlayerShareInfoReq()
  req.share_base_id = share_base_id
  req.share_part_id = share_part_id
  req.opt = 2
  table.insert(self.CheckRewardStateList, {shareBaseId = share_base_id, sharePartId = share_part_id})
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SHARE_INFO_REQ, req, self, self.GetShareRewardInfoRsp, false, true)
end

function ShareUIModule:OnCmdCheckShareChannelIsOpen(channelBanId)
  local IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, channelBanId, false, true)
  if IsBan then
    return false
  end
  return true
end

function ShareUIModule:OnReconnect()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseShareCameraPanel)
  self:CloseAllPanel()
end

function ShareUIModule:OnCmdSetIsSharingPetVideo(flag)
  self.IsSharingPetVideo = flag
end

function ShareUIModule:OnCmdSetIsSharingMagicVideo(flag)
  self.IsSharingMagicVideo = flag
end

function ShareUIModule:OnCmdPlayPetVideoShareInAnim()
  if self:HasPanel("ShareUIPanel") then
    local panel = self:GetPanel("ShareUIPanel")
    panel:PlayPetVideoShareInAnim()
  end
end

return ShareUIModule
