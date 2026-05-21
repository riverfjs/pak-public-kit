local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_QualificationInterpretation_C = _G.NRCPanelBase:Extend("UMG_QualificationInterpretation_C")

function UMG_QualificationInterpretation_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_QualificationInterpretation_C:OnActive(_Param, OpenType)
  self.data = _Param
  self:PlayAnimation(self.In)
  self:SetPanelInfo(OpenType)
end

function UMG_QualificationInterpretation_C:OnDeactive()
end

function UMG_QualificationInterpretation_C:OnAddEventListener()
end

function UMG_QualificationInterpretation_C:SetPanelInfo(OpenType)
  local data = self.data
  local Text
  if OpenType == PetUIModuleEnum.OpenPetRateType.Certification then
    Text = string.format("%s%s", data.conf.attribute_name, LuaText.umg_qualificationinterpretation_1)
    local addNum = data[1].attrInfo.total_race
    Text = _G.DataConfigManager:GetLocalizationConf("pet_talent_desc_1").msg
    Text = string.format(Text, data.conf.attribute_name, data.conf.attribute_name)
    self.Title_1:SetText(Text)
    Text = _G.DataConfigManager:GetLocalizationConf("pet_talent_desc_2").msg
    local attr = data.conf.attribute_name
    local MaxRace = 0
    local MaxTalent = 0
    local BasePoint = 0
    if "\231\148\159\229\145\189" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_level_constant").num
    elseif "\231\137\169\230\148\187" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_level_constant").num
    elseif "\233\173\148\230\148\187" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_level_constant").num
    elseif "\231\137\169\233\152\178" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_level_constant").num
    elseif "\233\173\148\233\152\178" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_level_constant").num
    elseif "\233\128\159\229\186\166" == attr then
      MaxRace = _G.DataConfigManager:GetAttrGlobalConfig("speed_race_constant").num
      MaxTalent = _G.DataConfigManager:GetAttrGlobalConfig("speed_talent_constant").num
      BasePoint = _G.DataConfigManager:GetAttrGlobalConfig("speed_level_constant").num
    end
    local PromoteData = (addNum * MaxRace + data[1].attrInfo.talent * MaxTalent + BasePoint) * 1.0E-4
    PromoteData = string.format("%.2f", PromoteData)
    Log.Debug(addNum, MaxRace, data[1].attrInfo.talent, MaxTalent, BasePoint, PromoteData, "UMG_QualificationInterpretation_C:SetPanelInfo")
    Text = string.format(Text, data.conf.attribute_name, PromoteData)
    self.Title_4:SetText(Text)
    Text = string.format(LuaText.umg_qualificationinterpretation_2, data.conf.attribute_name)
    Text = string.format(LuaText.umg_qualificationinterpretation_3, data.conf.attribute_name)
    Text = string.format(LuaText.umg_qualificationinterpretation_4, data.conf.attribute_name)
    if data[1].attrInfo.talent > 0 then
      local Text_1 = string.format("%s%d", "+", data[1].attrInfo.talent)
    else
    end
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(data.petdata.base_conf_id)
    if petBaseConf then
      local ModelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if ModelConf then
      end
    end
    local petlevel = PetUtils.GetCatchHardInfo(data.petdata)
  else
    Text = string.format("%s%s", data.conf.attribute_name, LuaText.umg_qualificationinterpretation_5)
    Text = _G.DataConfigManager:GetLocalizationConf("pet_effort_desc_1").msg
    Text = string.format(Text, data.conf.attribute_name, data.conf.attribute_name)
    self.Title_1:SetText(Text)
    Text = _G.DataConfigManager:GetLocalizationConf("pet_effort_desc_2").msg
    local num = 0
    if self.data[1].attrInfo then
      num = self.data[1].attrInfo.effort_add
    end
    Text = string.format(Text, data.conf.attribute_name, num)
    self.Title_4:SetText(Text)
    Text = _G.DataConfigManager:GetLocalizationConf("umg_qualificationinterpretation_5").msg
    Text = string.format("\229\189\147\229\137\141%s%s", data.conf.attribute_name, Text)
  end
end

function UMG_QualificationInterpretation_C:OnClickCloseBtn()
  self:PlayAnimation(self.Out)
end

function UMG_QualificationInterpretation_C:SetLvAndExpText(level, curExp, maxExp)
  local text = string.format("%s: %d      %s: %d/%d", _G.DataConfigManager:GetLocalizationConf("umg_petlevelup_19").msg, level, _G.DataConfigManager:GetLocalizationConf("umg_petlevelup_20").msg, curExp, maxExp)
end

function UMG_QualificationInterpretation_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

return UMG_QualificationInterpretation_C
