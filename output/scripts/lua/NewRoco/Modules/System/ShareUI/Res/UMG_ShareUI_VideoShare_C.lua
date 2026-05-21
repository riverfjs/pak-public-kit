local ShareVerifier = require("NewRoco.Modules.System.Share.ShareVerifier")
local UMG_ShareUI_VideoShare_C = _G.NRCPanelBase:Extend("UMG_ShareUI_VideoShare_C")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")

function UMG_ShareUI_VideoShare_C:OnActive(data)
  self.data = data
  self._refActorIsolateWorld = nil
  self:OnAddEventListener()
  self:ShowPlayerInfoPanel(false)
  self:ShowMagicVideo()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.Video)
end

function UMG_ShareUI_VideoShare_C:OnDeactive()
  self:RemoveButtonListener(self.PhotoSub.PlayBtn, self.OnPlayVideoClick)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.Video)
end

function UMG_ShareUI_VideoShare_C:OnAddEventListener()
  self:AddButtonListener(self.PhotoSub.PlayBtn, self.OnPlayVideoClick)
end

function UMG_ShareUI_VideoShare_C:ShowMagicVideo()
  local bPicValid, reason = ShareVerifier.Verify(self.data.VideoCoverPath, ShareVerifier.FileKind.Pic)
  if bPicValid then
    self.PhotoSub.Voideo:SetBrushFromTexture(self.data.ImageObj, true)
  end
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  self.PhotoSub.Grade:SetText(playerInfo.name)
  self.PhotoSub.Grade_1:SetText("UID:" .. playerInfo.uin)
  local cardInfo = playerInfo.additional_data.card_brief_info
  if cardInfo then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(cardInfo.card_icon_selected)
    if cardIconConf then
      local avatarPath = cardIconConf.icon_resource_path
      avatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/", avatarPath, avatarPath)
      self.PhotoSub.HeadPortrait:SetPath(avatarPath)
    end
  end
end

function UMG_ShareUI_VideoShare_C:OnPlayVideoClick()
  local bVideoValid, reason = ShareVerifier.Verify(self.data.VideoPath, ShareVerifier.FileKind.Video)
  if not bVideoValid then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.invalid_video_tips, nil, nil, 2)
    return
  end
  local data = self.data
  local param = {}
  param.Conf = {}
  param.Conf.end_black = 1
  param.Conf.begin_black = 1
  param.Conf.begin_black_fade_in = 1
  param.Conf.movie_path = data.VideoPath
  
  function param.Callback()
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingMagicVideo, false)
  end
  
  param.From = "VideoShare"
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.PlayVideo, param)
  _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingMagicVideo, true)
end

function UMG_ShareUI_VideoShare_C:ShowPlayerInfoPanel(isShow)
  if isShow then
    self.PhotoSub.HeadPortrait:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.Grade:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.Grade_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.Grade:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.Grade_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_ShareUI_VideoShare_C
