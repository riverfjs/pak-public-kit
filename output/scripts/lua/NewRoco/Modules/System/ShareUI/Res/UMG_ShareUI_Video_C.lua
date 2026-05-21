local UMG_ShareUI_Video_C = _G.NRCPanelBase:Extend("UMG_ShareUI_Video_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_ShareUI_Video_C:OnConstruct()
  self.module = _G.NRCModuleManager:GetModule("ShareUIModule")
  self.PhotoSub.PlayBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ShareUI_Video_C:OnActive(data)
  self.data = data
  self.uiItem = {}
  self.uiItem.genderIcons = {
    self.PhotoSub.NRCImage_18,
    self.PhotoSub.NRCImage_17
  }
  self._refActorIsolateWorld = nil
  self:OnAddEventListener()
  self.PhotoSub:Init(self.data.petData.gid)
  self:ShowPetInfo()
  self:ShowPlayerInfo()
  self:ShowPlayerInfoPanel(false)
end

function UMG_ShareUI_Video_C:OnDeactive()
  self:RemoveButtonListener(self.PhotoSub.PlayBtn, self.OnPlayVideoClick)
end

function UMG_ShareUI_Video_C:OnAddEventListener()
  self:AddButtonListener(self.PhotoSub.PlayBtn, self.OnPlayVideoClick)
end

function UMG_ShareUI_Video_C:ShowPetInfo()
  self.PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.petData.base_conf_id)
  local handbookInfo = _G.DataModelMgr.PlayerDataModel:GetHandbookInfoByPetBaseId(self.data.petData.base_conf_id)
  if handbookInfo then
    local handbookCfg = _G.DataConfigManager:GetPetHandbook(handbookInfo.handbook_id)
    local petName = _G.DataConfigManager:GetPetHandbook(handbookInfo.handbook_id).name
    self.PhotoSub.Name_1:SetText(petName)
    self.PhotoSub.DepartmentName:SetText(handbookCfg.type_desc)
    self.PhotoSub.Describe:SetText(self.PetBaseConf.description)
  else
    Log.Error("UMG_VideoSharing_C:ShowPetInfo \229\155\190\233\137\180\230\178\161\230\156\137\233\133\141\231\189\174\232\175\165\231\178\190\231\129\181\239\188\129\239\188\129\239\188\129")
  end
  if self.PetBaseConf.form == nil or self.PetBaseConf.form == "" then
    self.PhotoSub.Name_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PhotoSub.Name_2:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.PhotoSub.Name_2:SetText(self.PetBaseConf.form)
  self:updatePetGender(self.data.petData.gender)
  self:ShowPetType()
  self:ShowWeightAndStature()
  self:ShowPetImage()
  self:ShowPetFindInfo()
end

function UMG_ShareUI_Video_C:ShowPlayerInfo()
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
  self.PhotoSub.PetNameText:SetText(string.format(_G.LuaText.Pet_Share_NUM_Txt, playerInfo.name, tostring(self.data.petData.gid)))
  self:ShowCardInfo()
end

function UMG_ShareUI_Video_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.uiItem.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ShareUI_Video_C:ShowPetType()
  local unit_type = _G.DataConfigManager:GetPetbaseConf(self.data.petData.base_conf_id).unit_type
  self.PhotoSub.Attr:InitGridView(unit_type)
end

function UMG_ShareUI_Video_C:ShowWeightAndStature()
  self.PhotoSub.QuestionMark_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PhotoSub.QuestionMark_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.data.petData.weight then
    self.PhotoSub.Weight_1:SetText(string.format(LuaText.umg_handbookcontent_2, self.data.petData.weight * 0.001))
  end
  if self.data.petData.height then
    self.PhotoSub.Stature_1:SetText(string.format(LuaText.umg_handbookcontent_3, self.data.petData.height * 0.01))
  end
end

function UMG_ShareUI_Video_C:ShowCardInfo()
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local cardInfo = playerInfo.additional_data.card_brief_info
  if cardInfo and cardInfo.card_label_first_selected and cardInfo.card_label_last_selected then
    local cardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(cardInfo.card_label_first_selected)
    local cardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(cardInfo.card_label_last_selected)
    if cardLabelFirstConf and cardLabelLastConf then
      self.PhotoSub.BusinessCard_Label:SetLabelText(string.format("%s%s", cardLabelFirstConf.label_text, cardLabelLastConf.label_text))
    end
  end
end

function UMG_ShareUI_Video_C:ShowPetImage()
  local _scale = self.PetBaseConf.res_ui_percentage and self.PetBaseConf.res_ui_percentage > 0 and self.PetBaseConf.res_ui_percentage or 1
  local NewUILocation = UE4.FVector2D(0, 0)
  local _offsetConf
  if self.PetBaseConf.res_offset and next(self.PetBaseConf.res_offset) then
    _offsetConf = self.PetBaseConf.res_offset
    _offsetConf = UE4.FVector2D(_offsetConf[1] or 0, _offsetConf[2] or 0)
  else
    _offsetConf = UE4.FVector2D(0, 0)
  end
  NewUILocation.X = NewUILocation.X + _offsetConf.X
  NewUILocation.Y = NewUILocation.Y + _offsetConf.Y
  self.PhotoSub.Icon_2.Slot:SetPosition(NewUILocation)
  if 1 == self.PetBaseConf.res_horizontal_flip_data then
    self.PhotoSub.Icon_2:SetRenderScale(UE4.FVector2D(_scale, _scale))
  else
    self.PhotoSub.Icon_2:SetRenderScale(UE4.FVector2D(-_scale, _scale))
  end
  local path = self.PetBaseConf.JL_res
  if PetMutationUtils.GetMutationValue(self.data.petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(self.data.petData.mutation_type) then
    path = self.PetBaseConf.JL_shiny_res
  end
  self.PhotoSub.IconBg_3:SetPath(self.PetBaseConf.share_bg)
  self.PhotoSub.Icon_2:SetPath(path)
end

function UMG_ShareUI_Video_C:ShowPetFindInfo()
  if self.data.petData.add_time then
    local addTime = os.date("%Y/%m/%d", self.data.petData.add_time)
    self.PhotoSub.Time:SetText(addTime)
    self.PhotoSub.Time:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local isShowFindPos = false
  if self.data.petData.caught_camp then
    local campConf = _G.DataConfigManager:GetCampConf(self.data.petData.caught_camp)
    if campConf then
      isShowFindPos = true
      self.PhotoSub.Name_3:SetText(campConf.camp_name)
    end
  end
  if isShowFindPos then
    self.PhotoSub.Name_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.Name_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ShareUI_Video_C:OnPlayVideoClick()
  local data = self.data
  
  local function OpenCb()
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PlayShareVideoG6)
  end
  
  local function CloseCb()
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, data)
  end
  
  _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingPetVideo, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenShareCameraPanel, data.petData, OpenCb, CloseCb)
  _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CloseShareUIPanel, true)
end

function UMG_ShareUI_Video_C:PlayStampInAnim()
  self.PhotoSub:PlayStampInAnim()
end

function UMG_ShareUI_Video_C:ShowPlayerInfoPanel(isShow)
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

return UMG_ShareUI_Video_C
