local PetUtils = require("NewRoco.Utils.PetUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_HerbologyBadge_PetDetails_C = _G.NRCViewBase:Extend("UMG_HerbologyBadge_PetDetails_C")

function UMG_HerbologyBadge_PetDetails_C:OnConstruct()
  self:AddButtonListener(self.SkillBtn, self.OnFeatureSkillBtnClick)
  self:AddButtonListener(self.Button_AddSill, self.OnAddSkillBtnClicked)
  self:AddButtonListener(self.Button_AddSill_1, self.OnAddSkillBtnClicked)
  self:AddButtonListener(self.ConversionBtn.btnLevelUp, self.OnAddSkillBtnClicked)
  self.ContentDetails.OnRichTextClick:Add(self, self.OnDescTextClicked)
  self.Button_AddSill_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.descText = ""
end

function UMG_HerbologyBadge_PetDetails_C:OnDestruct()
  self.BtnHandlerList = nil
  self.ContentDetails.OnRichTextClick:Remove(self, self.ResetDescText)
end

function UMG_HerbologyBadge_PetDetails_C:OnActive()
end

function UMG_HerbologyBadge_PetDetails_C:OnDeactive()
end

function UMG_HerbologyBadge_PetDetails_C:OnAddEventListener()
end

function UMG_HerbologyBadge_PetDetails_C:GetChangeAttrReqEnum(attribute)
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

function UMG_HerbologyBadge_PetDetails_C:OnDescTextClicked(id)
  if self.BtnHandlerList and self.BtnHandlerList.Call and self.BtnHandlerList.OnTextClickedHandler then
    self.BtnHandlerList.OnTextClickedHandler(self.BtnHandlerList.Call, self.descText)
  end
end

function UMG_HerbologyBadge_PetDetails_C:ResetDescText()
  if self.BtnHandlerList and self.BtnHandlerList.Call and self.BtnHandlerList.OnRestTextHandler then
    self.BtnHandlerList.OnRestTextHandler(self.BtnHandlerList.Call)
  end
end

function UMG_HerbologyBadge_PetDetails_C:OnFeatureSkillBtnClick()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPeculiarityTips, self.petData)
end

function UMG_HerbologyBadge_PetDetails_C:OnAddSkillBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_HerbologyBadge_PetDetails_C:OnAddSkillBtnClicked")
  if self.OnAddSkillClickedCallback then
    self.OnAddSkillClickedCallback()
  end
end

function UMG_HerbologyBadge_PetDetails_C:SetAddSkillClickedCallback(caller, callback)
  if caller and callback then
    function self.OnAddSkillClickedCallback()
      callback(caller)
    end
  else
    self.OnAddSkillClickedCallback = nil
  end
end

function UMG_HerbologyBadge_PetDetails_C:SetAddSkillBtnVisible(bShow)
  if self.NRCSwitcher_Sill then
    if bShow then
      self.NRCSwitcher_Sill:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_Sill:SetActiveWidgetIndex(0)
    end
  end
end

function UMG_HerbologyBadge_PetDetails_C:InitPetBaseInfo(PetData, PetBaseConf, AttrList, petEquipSkillList, showType, BtnHandlerList)
  self.showType = showType or PetUIModuleEnum.CommonPetDetailsShowType.Normal
  self.BtnHandlerList = BtnHandlerList
  self.petData = PetData
  local attrList = {}
  local attrInfo = self.petData.attribute_info
  local positive_effect, negative_effect
  local natureConf = _G.DataConfigManager:GetNatureConf(self.petData.nature)
  if 0 ~= self.petData.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_pos_attr_type)
  else
    positive_effect = natureConf and natureConf.positive_effect
  end
  if 0 ~= self.petData.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_neg_attr_type)
  else
    negative_effect = natureConf and natureConf.negative_effect
  end
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_HPMAX,
    arrowType = _G.Enum.AttributeType.AT_HPMAX_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_HPMAX),
    attrInfo = attrInfo.hp,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_1
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYATK,
    arrowType = _G.Enum.AttributeType.AT_PHYATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_PHYATK),
    attrInfo = attrInfo.attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_3
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEATK,
    arrowType = _G.Enum.AttributeType.AT_SPEATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_SPEATK),
    attrInfo = attrInfo.special_attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_4
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYDEF,
    arrowType = _G.Enum.AttributeType.AT_PHYDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_PHYDEF),
    attrInfo = attrInfo.defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_5
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEDEF,
    arrowType = _G.Enum.AttributeType.AT_SPEDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_SPEDEF),
    attrInfo = attrInfo.special_defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_6
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEED,
    arrowType = _G.Enum.AttributeType.AT_SPEED_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, ProtoEnum.AttributeType.AT_SPEED),
    attrInfo = attrInfo.speed,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.petData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_2,
    NoShowline = true
  })
  if AttrList then
    self.AttrList:InitGridView(AttrList)
  else
    self.AttrList:InitGridView(attrList)
  end
  self:InitFeatures(PetBaseConf)
  local skillListToShow = petEquipSkillList or self:GetPetEquipSkills(self.petData)
  local selectedSkill
  if skillListToShow then
    for _, v in pairs(skillListToShow) do
      if v then
        selectedSkill = v
        break
      end
    end
  end
  if selectedSkill then
    if self.NRCSwitcher_Sill then
      self.NRCSwitcher_Sill:SetActiveWidgetIndex(1)
    end
    local skillCfg = _G.DataConfigManager:GetSkillConf(selectedSkill.id)
    if skillCfg then
      if self.SkillIcon and skillCfg.icon then
        self.SkillIcon:SetPath(skillCfg.icon)
      end
      if self.Name_1 then
        self.Name_1:SetText(skillCfg.name or "")
      end
      if self.ContentDetails_1 then
        self.ContentDetails_1:SetText(skillCfg.desc or "")
      end
      if self.Department and skillCfg.skill_dam_type then
        local TypeDic = _G.DataConfigManager:GetTypeDictionary(skillCfg.skill_dam_type)
        local AttrInfo = {}
        AttrInfo.Name = TypeDic.short_name
        AttrInfo.Path = TypeDic.tips_res
        self.Department:SetInfo(AttrInfo)
      end
      if self.HerbologyBadge_Energy and skillCfg.energy_cost and skillCfg.energy_cost[1] then
        self.HerbologyBadge_Energy:SetEnergyInfo(skillCfg.energy_cost[1], false)
      end
    end
  elseif self.NRCSwitcher_Sill then
    self.NRCSwitcher_Sill:SetActiveWidgetIndex(0)
  end
end

function UMG_HerbologyBadge_PetDetails_C:GetPetEquipSkills(petData)
  local petEquipSkills = {}
  if petData then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  return petEquipSkills
end

function UMG_HerbologyBadge_PetDetails_C:InitFeatures(PetbaseConf)
  local skillId, lock = PetUtils.GetPetFeatrueSkillId(PetbaseConf)
  if lock then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif skillId and 0 ~= skillId then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg then
      if skillCfg.icon then
        self.SkillIcon_1:SetPath(skillCfg.icon)
      end
      self.Name:SetText(skillCfg.name)
      self.descText = skillCfg.desc
      self.ContentDetails:SetText(skillCfg.desc)
    else
      self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_PetDetails_C:SetSpecificOpenPetTipsType(openPetTipsType)
  self.SpecificOpenPetTipsType = openPetTipsType
end

return UMG_HerbologyBadge_PetDetails_C
