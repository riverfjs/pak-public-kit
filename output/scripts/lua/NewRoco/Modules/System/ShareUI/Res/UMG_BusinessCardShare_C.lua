local UMG_BusinessCardShare_C = _G.NRCPanelBase:Extend("UMG_BusinessCardShare_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")

function UMG_BusinessCardShare_C:OnActive(data)
  self.data = data
  self.SelectIndex = 1
  self:InitPanelInfo()
end

function UMG_BusinessCardShare_C:OnDeactive()
  self.PhotoSub.PetMedalBtn.OnClicked:Remove(self, self.OnShowSelectBox)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnShareComboBoxSelectChanged, self.SelectShareType)
end

function UMG_BusinessCardShare_C:OnAddEventListener()
  self.PhotoSub.PetMedalBtn.OnClicked:Add(self, self.OnShowSelectBox)
  _G.NRCEventCenter:RegisterEvent("UMG_BusinessCardShare_C", self, PetUIModuleEvent.OnShareComboBoxSelectChanged, self.SelectShareType)
end

function UMG_BusinessCardShare_C:InitPanelInfo()
  self:InitPlayerInfo()
  self:InitAdventureLog()
  self:InitCode()
  self:InitPhoto()
  self:InitSelectBox()
  self:UpdateCollectList()
  self:OnAddEventListener()
end

function UMG_BusinessCardShare_C:InitPlayerInfo()
  local CardInfo = self.data.extraData.CardInfo
  local BaseData = self.data.extraData.BaseData
  local SkillId = self.data.extraData.SkillId
  local ShinePetIcon = self.data.extraData.ShinePetIcon
  local desc
  if CardInfo.card_signature == nil or CardInfo.card_signature == "" then
    desc = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  else
    desc = CardInfo.card_signature
  end
  self.PhotoSub.Personalized_Signature:SetText(desc)
  if BaseData.note and "" ~= BaseData.note then
    self.PhotoSub.Name_content_3:SetText(BaseData.note)
    self.PhotoSub.Name_content_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFC65FFF"))
  else
    self.PhotoSub.Name_content_3:SetText(BaseData.name)
    self.PhotoSub.Name_content_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFFFF"))
  end
  self.PhotoSub.NRCText_1:SetText(BaseData.uin)
  self.PhotoSub.BusinessCard_HeadItem:UpdateHead(BaseData, nil, true)
  local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(SkillId)
  if CardSkinConf then
    local Path = string.format(UEPath.CARD_COMMON_PATH, CardSkinConf.skin_resource_path, "Fram", CardSkinConf.skin_resource_path, "Fram")
    self.PhotoSub.PanelBg_3:SetPathWithCallBack(Path, {self, ShinePetIcon})
  end
end

function UMG_BusinessCardShare_C:InitAdventureLog()
  local BaseData = self.data.extraData.BaseData
  local CardInfo = self.data.extraData.CardInfo
  self.PhotoSub.Time:SetText(os.date("%Y.%m.%d", BaseData.regist_date))
  local fashion = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedFashion()
  local fashionNum = 0
  if fashion then
    fashionNum = #fashion
  end
  self.PhotoSub.ClothingCollection:SetText(tostring(fashionNum))
  local fashionPercentDesc = "0.0%"
  if 0 ~= fashionNum then
    local totalFashionCount = _G.DataModelMgr.PlayerDataModel.TotalFashionCount
    local percentage = fashionNum / totalFashionCount * 100
    fashionPercentDesc = string.format("%.1f%%", percentage)
  end
  self.PhotoSub.ClothingCollection2:SetText(fashionPercentDesc)
  if CardInfo.card_fashion_bond_collect_num then
    UIUtils.SafeSetText(self.PhotoSub.Time_1, CardInfo.card_fashion_bond_collect_num)
  else
    UIUtils.SafeSetText(self.PhotoSub.Time_1, "0")
  end
  local collectNum = 0
  if CardInfo.card_handbook_collect_num then
    collectNum = CardInfo.card_handbook_collect_num
  end
  self.PhotoSub.Time_2:SetText(collectNum)
  local collectPercentDesc = "0.0%"
  if 0 ~= collectNum then
    local totalCollectCount = _G.DataModelMgr.PlayerDataModel.TotalCollectCount
    local percentage = collectNum / totalCollectCount * 100
    collectPercentDesc = string.format("%.1f%%", percentage)
  end
  self.PhotoSub.Time_3:SetText(collectPercentDesc)
  if CardInfo.card_handbook_collect_num then
    collectNum = CardInfo.card_handbook_collect_num
  end
  local shiningPetCount, glassPetCount = 0, 0
  if CardInfo.card_pet_info then
    glassPetCount = CardInfo.card_pet_info.collected_glass_pet_count or 0
    shiningPetCount = CardInfo.card_pet_info.collected_shining_pet_count or 0
  end
  self.PhotoSub.Time_6:SetText(tostring(glassPetCount))
  self.PhotoSub.Time_7:SetText(tostring(shiningPetCount))
end

function UMG_BusinessCardShare_C:UpdateCollectList()
  local showCollectList
  local itemData = self.PhotoSub.ComboBox_Popup.List_title:GetDataByIndex(self.SelectIndex)
  if itemData then
    if itemData.SharePartId == _G.Enum.ShareButtonType.SBT_ROLE_CARD_PET then
      showCollectList = self.data.extraData.PetCollectList
    else
      showCollectList = self.data.extraData.BadgeCollectList
    end
  end
  if showCollectList then
    local newShowList = {
      table.unpack(showCollectList, 1, math.min(6, #showCollectList))
    }
    self.PhotoSub.LovePartner_3:InitGridView(newShowList)
  end
end

function UMG_BusinessCardShare_C:InitPhoto()
  local CardInfo = self.data.extraData.CardInfo
  local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(CardInfo.card_label_first_selected)
  local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(CardInfo.card_label_last_selected)
  if CardLabelFirstConf and CardLabelLastConf then
    self.PhotoSub.UMG_BusinessCard_Label_61:SetLabelText(string.format("%s%s", CardLabelFirstConf.label_text, CardLabelLastConf.label_text))
  end
  self.PhotoSub.UMG_ClippingPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local Texture = self.data.extraData.UploadedPhotoTex
  if Texture then
    local function cb()
      self.PhotoSub.UploadedPhoto:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      
      local FrameSize = self.PhotoSub.EmptyBg_1.Slot:GetSize()
      local DesiredWidth = FrameSize.X
      local DesiredHeight = FrameSize.Y
      local ThumbnailWidth = Texture:Blueprint_GetSizeX()
      local ThumbnailHeight = Texture:Blueprint_GetSizeY()
      local ScaleToViewWidth = DesiredWidth / ThumbnailWidth
      local ScaleToViewHeight = DesiredHeight / ThumbnailHeight
      local MaxiScale = math.max(ScaleToViewWidth, ScaleToViewHeight)
      DesiredWidth = MaxiScale * ThumbnailWidth
      DesiredHeight = MaxiScale * ThumbnailHeight
      self.PhotoSub.UploadedPhoto:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(Texture))
      self.PhotoSub.UploadedPhoto.Slot:SetSize(UE4.FVector2D(math.floor(DesiredWidth), math.floor(DesiredHeight)))
      self.PhotoSub.EmptyBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    
    self:DelaySeconds(0.1, cb)
  else
    self.PhotoSub.EmptyBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.UploadedPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BusinessCardShare_C:InitCode()
  if self.data.IsBanQRCode then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local path = "Texture2D'/Game/NewRoco/Modules/System/ShareUI/Raw/Textures/img_ShareQrCode.img_ShareQrCode'"
    self.PhotoSub.QRCodeImage:SetPath(path)
  end
end

function UMG_BusinessCardShare_C:InitSelectBox()
  self.SelectIndex = 1
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(self.data.shareBaseId)
  local selectList = {}
  if shareBaseConf and shareBaseConf.base_id then
    for index, v in ipairs(shareBaseConf.base_id) do
      local channelBanId = shareBaseConf.system_control_limit[index + 1]
      local isBan = false
      if channelBanId and not _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckShareChannelIsOpen, channelBanId) then
        isBan = true
      end
      if not isBan then
        local sharePartConf = _G.DataConfigManager:GetSharePartConf(v)
        if sharePartConf then
          local selectData = {
            name = sharePartConf.tab_name,
            isHideRedDot = true,
            isNotChangColor = true,
            ComType = CommonBtnEnum.ComboBoxType.PetShare,
            SharePartId = v
          }
          table.insert(selectList, selectData)
        end
      end
    end
    if #selectList > 0 then
      self.PhotoSub.PetMedalSwitch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PhotoSub.PetMedalText:SetText(selectList[self.SelectIndex].name)
      self.PhotoSub.ComboBox_Popup.List_title:InitList(selectList)
      
      local function cb()
        _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.ShowShareUIPanelCloseMoreBtn, true)
      end
      
      self.PhotoSub.ComboBox_Popup:SetInAnimCallBack(cb)
      self.PhotoSub.ComboBox_Popup:SetAnimChoice(true)
    else
      self.PhotoSub.PetMedalSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.PhotoSub.PetMedalSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.PhotoSub.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.IsShowSelectBox = false
end

function UMG_BusinessCardShare_C:OnShowSelectBox()
  if self.IsShowSelectBox then
    self:ShowSelectBox(false)
  else
    self:ShowSelectBox(true)
  end
end

function UMG_BusinessCardShare_C:SelectShareType(index)
  self:OnShowSelectBox()
  if index == self.SelectIndex then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if not isBan then
    self.SelectIndex = index
    local itemData = self.PhotoSub.ComboBox_Popup.List_title:GetDataByIndex(index)
    self.PhotoSub.PetMedalText:SetText(itemData.name)
    self:UpdateCollectList()
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.UpdateSharePartId, itemData.SharePartId)
  end
end

function UMG_BusinessCardShare_C:ShowSelectBox(isShow)
  self.IsShowSelectBox = isShow
  self.PhotoSub.ComboBox_Popup:PlayAnimationInfo(isShow)
end

function UMG_BusinessCardShare_C:ShowShareChannelCode(qrcodeShow, qrcodeLink)
  if self.data.IsBanQRCode then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif qrcodeShow and qrcodeShow == Enum.ShareQRcodeScenario.SQRS_HIDE then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if qrcodeLink then
      local qrCodeTexture = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetQRCodeTexture, qrcodeLink)
      if qrCodeTexture then
        self.PhotoSub.QRCodeImage:SetBrushFromTexture(qrCodeTexture, false)
      end
    end
  end
end

function UMG_BusinessCardShare_C:ResetShareChannelCode()
  self:InitCode()
end

function UMG_BusinessCardShare_C:HideSelectBoxByShare()
  if self.PhotoSub.ComboBox_Popup and self.PhotoSub.ComboBox_Popup:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.IsShowSelectBox = false
    self.PhotoSub.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_BusinessCardShare_C
