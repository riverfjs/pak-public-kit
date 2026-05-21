local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetDetailedTemplate_C = Base:Extend("UMG_PetDetailedTemplate_C")
local SELECT_COLOR = UE4.UNRCStatics.HexToSlateColor("F4EEE1FF")
local UNSELECT_COLOR_TEXT = UE4.UNRCStatics.HexToSlateColor("929086FF")
local UNSELECT_COLOR_IMAGE = UE4.UNRCStatics.HexToSlateColor("62605EFF")
local SELECT_LINEAR_COLOR = UE4.UNRCStatics.HexToLinearColor("F4EEE1FF")
local UNSELECT_LINEAR_COLOR_IMAGE = UE4.UNRCStatics.HexToLinearColor("62605EFF")

function UMG_PetDetailedTemplate_C:OnDestruct()
  self.uiData = nil
  Log.Debug("UMG_PetDetailedTemplate_C:OnDestruct")
end

function UMG_PetDetailedTemplate_C:OnEnable()
  Log.Debug("UMG_PetDetailedTemplate_C:OnEnable")
end

function UMG_PetDetailedTemplate_C:OnDisable()
  Log.Debug("UMG_PetDetailedTemplate_C:OnDisable")
end

function UMG_PetDetailedTemplate_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.bTipVisible = false
  self.TipsType = 0
  self.Btn_QuestionMark.OnClicked:Add(self, self.OnClickQuestionMark)
  self.StriveLevelBtn.OnClicked:Add(self, self.OnClickStriveLevel)
  self.Properbtn.OnClicked:Add(self, self.OnClickProperbtn)
  self.MaskBtn.OnClicked:Add(self, self.OnMaskBtn)
  self:updateItemInfo(_data)
end

function UMG_PetDetailedTemplate_C:updateItemInfo(_data)
  self:SetBaseInfo()
  if 1 == _data.conf.is_percent_attr then
    self.numTxt:SetText(_data.num // 100 .. "%")
  else
    self.numTxt:SetText(_data.num)
  end
  local natureConf = _G.DataConfigManager:GetNatureConf(_data.nature)
  local positive_effect, negative_effect
  if 0 ~= _data.petdata.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(_data.petdata.changed_nature_pos_attr_type)
  elseif natureConf then
    positive_effect = natureConf.positive_effect
  end
  if 0 ~= _data.petdata.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(_data.petdata.changed_nature_neg_attr_type)
  elseif natureConf then
    negative_effect = natureConf.negative_effect
  end
  if _data.conf.attr_ui_type == Enum.AttrUIType.AUT_BASE then
    if positive_effect == _data.attribute then
      self.imgUp:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.imgUp:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    if negative_effect == _data.attribute then
      self.imgDown:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.imgDown:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    if _data[1].attrInfo.talent and 0 ~= _data[1].attrInfo.talent then
      self.numTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFC65FFF"))
    else
      self.numTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F5EEE1FF"))
    end
  end
  self.nameTxt:SetText(_data.conf.attribute_name)
  local Text = string.format("%s%s", _data.conf.attribute_name, LuaText.umg_petdetailedtemplate_1)
  self.Title_4:SetText(Text)
  self.NRCImageIcon:SetPath(_data.conf.attribute_icon)
  self.Title:SetText(_data[1].name)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_data.petdata.base_conf_id)
  local addNum = _data[1].attrInfo.total_race
  local SumHistogram = addNum + _data[1].attrInfo.talent
  self.Title_2:SetText(addNum)
  local size = self.progressPetExp.Slot:GetSize()
  size.x = SumHistogram
  self.progressPetExp.Slot:SetSize(size)
  self.progressPetExp:SetPercent(addNum / SumHistogram)
  self.progressPetExp:SetIncreasePercent(_data[1].attrInfo.talent / SumHistogram)
  if _data[1].attrInfo.talent > 0 then
    self.Title_3:SetVisibility(UE4.ESlateVisibility.Visible)
    local Text_1 = string.format("%s%d", "+", _data[1].attrInfo.talent)
    self.Title_3:SetText(Text_1)
  else
    self.Title_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local StriveLevel = _data[1].attrInfo.effort_add or 0
  self.Text_Class:SetText(StriveLevel)
  self.Properbtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetDetailedTemplate_C:SetBaseInfo()
  self.imgDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.imgUp:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetDetailedTemplate_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

function UMG_PetDetailedTemplate_C:OnItemSelected(selected)
  Log.Debug("UMG_PetDetailedTemplate_C:OnItemSelected")
end

function UMG_PetDetailedTemplate_C:OnClickQuestionMark()
  self:ShowTalentTips()
end

function UMG_PetDetailedTemplate_C:OnClickStriveLevel()
  self:ShowEffortTips()
end

function UMG_PetDetailedTemplate_C:ShowTalentTips()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401011, "UMG_PetDetailedTemplate_C:ShowTalentTips")
  local attrName = self.data.conf.attribute_name
  local text_title = string.format(LuaText.pet_talent_desc_3, attrName)
  local text_desc = string.format(LuaText.pet_talent_desc_1, attrName, self.data.conf.attribute_name)
  local MaxRace = 0
  local MaxTalent = 0
  local BasePoint = 0
  if "\231\148\159\229\145\189" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_level_constant").num
  elseif "\231\137\169\230\148\187" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_level_constant").num
  elseif "\233\173\148\230\148\187" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_level_constant").num
  elseif "\231\137\169\233\152\178" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_level_constant").num
  elseif "\233\173\148\233\152\178" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_level_constant").num
  elseif "\233\128\159\229\186\166" == attrName then
    MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("speed_race_constant").num
    MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("speed_talent_constant").num
    BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("speed_level_constant").num
  end
  local attrInfo = self.data[1].attrInfo
  local promoteValue = (attrInfo.total_race * MaxRace + attrInfo.talent * MaxTalent + BasePoint) * 1.0E-4
  promoteValue = string.format("%.2f", promoteValue)
  local text_value = string.format(LuaText.pet_talent_desc_2, attrName, promoteValue)
  local text_compTitle = string.format(LuaText.pet_talent_desc_4, attrName)
  local text_race = string.format(LuaText.pet_talent_desc_5, attrName, attrInfo.total_race)
  local text_talent = string.format(LuaText.pet_talent_desc_6, attrName, attrInfo.talent)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.bIsUseOriginalText = true
  nounInterpretationTipsInfo.originalTextList = {}
  nounInterpretationTipsInfo.originalTextList[1] = text_title .. "\n" .. text_desc .. "\n" .. text_value
  nounInterpretationTipsInfo.originalTextList[2] = text_compTitle .. "\n" .. text_race .. "\n" .. text_talent
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_PetDetailedTemplate_C:ShowEffortTips()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401011, "UMG_PetDetailedTemplate_C:ShowEffortTips")
  local attrName = self.data.conf.attribute_name
  local text_title = string.format(LuaText.pet_effort_desc_3, attrName)
  local text_desc = string.format(LuaText.pet_effort_desc_1, attrName, attrName)
  local attrInfo = self.data[1].attrInfo
  local grow_times = self.data.petdata.grow_times or 0
  local text_effortLevel = LuaText.pet_effort_desc_4 .. grow_times
  local text_addLevel = string.format(LuaText.pet_effort_desc_2, attrName, attrInfo.effort_add)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.bIsUseOriginalText = true
  nounInterpretationTipsInfo.originalTextList = {}
  nounInterpretationTipsInfo.originalTextList[1] = text_title .. "\n" .. text_desc .. "\n" .. text_effortLevel .. "\n" .. text_addLevel
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_PetDetailedTemplate_C:OnClickProperbtn()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.CmdTalentRestorePopup)
end

function UMG_PetDetailedTemplate_C:OnMaskBtn()
  self:CloseAllDetailedTips(true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseAllDetailedTips, self.index, true)
end

function UMG_PetDetailedTemplate_C:CloseAllDetailedTips(IsCloseMaskBtn)
  self.QualificationInterpretation1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QualificationInterpretation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if IsCloseMaskBtn then
    self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bTipVisible = false
  self._parent:RefreshGridViewLayout()
end

function UMG_PetDetailedTemplate_C:OpenAllDetailedMaskBtn()
  self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_PetDetailedTemplate_C:ShowTips(OpenType)
  if self.bTipVisible then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401011, "UMG_PetDetailedTemplate_C:OnClickStriveLevel")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401012, "UMG_PetDetailedTemplate_C:OnClickStriveLevel")
  end
  if OpenType == self.TipsType or 0 == self.TipsType then
    if self.bTipVisible then
      self:ShowOrHideQualification(false, OpenType)
    else
      self:ShowOrHideQualification(true, OpenType)
    end
    self.bTipVisible = not self.bTipVisible
  else
    self.bTipVisible = false
    if self.bTipVisible then
      self:ShowOrHideQualification(false, OpenType)
    else
      self:ShowOrHideQualification(true, OpenType)
    end
    self.bTipVisible = not self.bTipVisible
  end
  self.TipsType = OpenType
  self._parent:RefreshGridViewLayout()
end

function UMG_PetDetailedTemplate_C:ShowOrHideQualification(_IsShow, OpenPetRateType)
  if _IsShow then
    if OpenPetRateType == PetUIModuleEnum.OpenPetRateType.Certification then
      self.QualificationInterpretation:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.QualificationInterpretation1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.QualificationInterpretation:OnActive(self.data, OpenPetRateType)
    else
      self.QualificationInterpretation1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.QualificationInterpretation:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.QualificationInterpretation1:OnActive(self.data, OpenPetRateType)
    end
    self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenAllDetailedMask, self.index)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseAllDetailedTips, self.index, false)
  else
    if OpenPetRateType == PetUIModuleEnum.OpenPetRateType.Certification then
      self.QualificationInterpretation:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.QualificationInterpretation1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetDetailedTemplate_C:SetOtherIndexMask(bSelect, OpenType, _curIndex)
  self.bTipVisible = false
  if _curIndex == self._index then
    self:ShowOrHideQualification(false, OpenType)
  end
  self._parent:RefreshGridViewLayout()
end

function UMG_PetDetailedTemplate_C:SetSelectColor(bSelect, OpenType, IsOther)
  if not IsOther then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.AttrTipsOpen, bSelect, self._index, OpenType)
  end
  if OpenType == PetUIModuleEnum.OpenPetRateType.Certification then
    if bSelect then
      self.Title:SetColorAndOpacity(SELECT_COLOR)
      self.Image_detail:SetColorAndOpacity(SELECT_LINEAR_COLOR)
      self.Title_4:SetColorAndOpacity(UNSELECT_COLOR_TEXT)
      self.Image_detail1:SetColorAndOpacity(UNSELECT_LINEAR_COLOR_IMAGE)
    else
      self.Title:SetColorAndOpacity(UNSELECT_COLOR_TEXT)
      self.Image_detail:SetColorAndOpacity(UNSELECT_LINEAR_COLOR_IMAGE)
    end
  elseif bSelect then
    self.Title_4:SetColorAndOpacity(SELECT_COLOR)
    self.Image_detail1:SetColorAndOpacity(SELECT_LINEAR_COLOR)
    self.Title:SetColorAndOpacity(UNSELECT_COLOR_TEXT)
    self.Image_detail:SetColorAndOpacity(UNSELECT_LINEAR_COLOR_IMAGE)
  else
    self.Title_4:SetColorAndOpacity(UNSELECT_COLOR_TEXT)
    self.Image_detail1:SetColorAndOpacity(UNSELECT_LINEAR_COLOR_IMAGE)
  end
end

return UMG_PetDetailedTemplate_C
