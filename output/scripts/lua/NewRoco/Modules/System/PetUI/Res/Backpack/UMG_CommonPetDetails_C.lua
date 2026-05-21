local PetUtils = require("NewRoco.Utils.PetUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_CommonPetDetails_C = _G.NRCViewBase:Extend("UMG_CommonPetDetails_C")

function UMG_CommonPetDetails_C:OnConstruct()
  self:AddButtonListener(self.SkillBtn, self.OnFeatureSkillBtnClick)
  self:AddButtonListener(self.NRCButton_112, self.OnNRCButton_112Click)
  self:AddButtonListener(self.NRCButton_43, self.OnNRCButton_112Click)
  self:AddButtonListener(self.NRCButton_1, self.OnTalentBtnClick)
  self:AddButtonListener(self.NRCButton, self.OnTalentBtnClick)
  self.ContentDetails.OnRichTextClick:Add(self, self.OnDescTextClicked)
  self.NRCButton_112.OnPressed:Add(self, self.OnCharacter_Pressed)
  self.NRCButton_112.OnReleased:Add(self, self.OnCharacter_Released)
  self.NRCButton_43.OnPressed:Add(self, self.OnCharacter_Pressed)
  self.NRCButton_43.OnReleased:Add(self, self.OnCharacter_Released)
  self.NRCButton_1.OnPressed:Add(self, self.OnTalent_Pressed)
  self.NRCButton_1.OnReleased:Add(self, self.OnTalent_Released)
  self.NRCButton.OnPressed:Add(self, self.OnTalent_Pressed)
  self.NRCButton.OnReleased:Add(self, self.OnTalent_Released)
  self.descText = ""
end

function UMG_CommonPetDetails_C:OnDestruct()
  self.BtnHandlerList = nil
  self.ContentDetails.OnRichTextClick:Remove(self, self.ResetDescText)
end

function UMG_CommonPetDetails_C:GetChangeAttrReqEnum(attribute)
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

function UMG_CommonPetDetails_C:OnDescTextClicked(id)
  if self.BtnHandlerList and self.BtnHandlerList.Call and self.BtnHandlerList.OnTextClickedHandler then
    self.BtnHandlerList.OnTextClickedHandler(self.BtnHandlerList.Call, self.descText)
  end
end

function UMG_CommonPetDetails_C:ResetDescText()
  if self.BtnHandlerList and self.BtnHandlerList.Call and self.BtnHandlerList.OnRestTextHandler then
    self.BtnHandlerList.OnRestTextHandler(self.BtnHandlerList.Call)
  end
end

function UMG_CommonPetDetails_C:OnNRCButton_112Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_ChangePetConfirmPanel_C:OnBtnBtnRechristenClick")
  local myOpenPetTipsType = self.SpecificOpenPetTipsType or TipEnum.OpenPetTipsType.PetWareHouse
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpendblockerTips, myOpenPetTipsType, self.petData)
end

function UMG_CommonPetDetails_C:OnTalentBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_ChangePetConfirmPanel_C:OnBtnBtnRechristenClick")
  if 0 == self.NRCSwitcher_41:GetActiveWidgetIndex() then
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenTipsStrongPoint, self.petData)
  elseif 1 == self.NRCSwitcher_41:GetActiveWidgetIndex() then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCheerUpPointTips, self.petData)
  end
end

function UMG_CommonPetDetails_C:OnFeatureSkillBtnClick()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPeculiarityTips, self.petData)
end

function UMG_CommonPetDetails_C:InitPetBaseInfo(PetData, PetBaseConf, AttrList, petEquipSkillList, showType, BtnHandlerList)
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
  local petNatureConf = _G.DataConfigManager:GetNatureConf(self.petData.nature)
  if petNatureConf then
    self.textPetNature:SetText(petNatureConf.name or "")
  end
  if 0 ~= self.petData.changed_nature_neg_attr_type or 0 ~= self.petData.changed_nature_pos_attr_type then
    self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_lailang_png.img_lailang_png'")
  else
    self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_character_png.img_character_png'")
  end
  local specialityId = self.petData and self.petData.speciality_id
  if specialityId then
    local PetTalentConf = _G.DataConfigManager:GetPetTalentConf(specialityId)
    if PetTalentConf then
      self.textPetNature_1:SetText(PetTalentConf.name)
    end
  end
  self:SetWeigthAndStature(self.petData)
  self:InitFeatures(PetBaseConf)
  if petEquipSkillList then
    if PetData.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or PetData.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      local fantasticId
      for _, skill in ipairs(PetData.skill.skill_data) do
        if skill.skill_src == _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          fantasticId = skill.id
          break
        end
      end
      local initData = {}
      for _, v in ipairs(petEquipSkillList) do
        local itemData = {}
        table.deepCopy(v, itemData)
        itemData.bFantastic = fantasticId == v.id
        table.insert(initData, itemData)
      end
      self.SkillList_1:InitGridView(initData)
    else
      self.SkillList_1:InitGridView(petEquipSkillList)
    end
  else
    local PetEquipSkillList = self:GetPetEquipSkills(self.petData)
    if PetData.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or PetData.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      local fantasticId
      for _, skill in ipairs(PetData.skill.skill_data) do
        if skill.skill_src == _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          fantasticId = skill.id
          break
        end
      end
      local initData = {}
      for _, v in ipairs(PetEquipSkillList) do
        local itemData = {}
        table.deepCopy(v, itemData)
        itemData.bFantastic = fantasticId == v.id
        table.insert(initData, itemData)
      end
      self.SkillList_1:InitGridView(initData)
    else
      self.SkillList_1:InitGridView(PetEquipSkillList)
    end
  end
  self:_UpdateCheerUpPointDisplay()
end

function UMG_CommonPetDetails_C:GetPetEquipSkills(petData)
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

function UMG_CommonPetDetails_C:InitFeatures(PetbaseConf)
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
      if self.showType == PetUIModuleEnum.CommonPetDetailsShowType.Normal then
        self.NRCSwitcher_0:SetActiveWidgetIndex(0)
        self.SkillNameTxt_1:SetText(skillCfg.name)
      else
        self.NRCSwitcher_0:SetActiveWidgetIndex(1)
        self.Name:SetText(skillCfg.name)
        self.descText = skillCfg.desc
        self.ContentDetails:SetText(skillCfg.desc)
      end
    else
      self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CommonPetDetails_C:SetWeigthAndStature(PetBaseInfo)
  if not PetBaseInfo.weight or not PetBaseInfo.height then
    return
  end
  local WeightData = PetBaseInfo.weight * 0.001
  local num = string.format("%.2f", WeightData)
  self.TextWeight:SetText(num)
  self.TextStature:SetText(string.format("%.2f", PetBaseInfo.height * 0.01))
end

function UMG_CommonPetDetails_C:OnDeactive()
end

function UMG_CommonPetDetails_C:OnAddEventListener()
end

function UMG_CommonPetDetails_C:OnCharacter_Pressed()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Press_1)
end

function UMG_CommonPetDetails_C:OnCharacter_Released()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Up_1)
end

function UMG_CommonPetDetails_C:OnTalent_Pressed()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Press_2)
end

function UMG_CommonPetDetails_C:OnTalent_Released()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Up_2)
end

function UMG_CommonPetDetails_C:SetSpecificOpenPetTipsType(openPetTipsType)
  self.SpecificOpenPetTipsType = openPetTipsType
end

function UMG_CommonPetDetails_C:SetFromWeeklyChallengeBattle(bFromWeeklyChallengeBattle, petData)
  self.bFromWeeklyChallengeBattle = bFromWeeklyChallengeBattle
  self.cheerUpPetData = petData
  if bFromWeeklyChallengeBattle then
    self.NRCSwitcher_41:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_41:SetActiveWidgetIndex(0)
  end
end

function UMG_CommonPetDetails_C:_UpdateCheerUpPointDisplay()
  if not self.bFromWeeklyChallengeBattle then
    return
  end
  local targetPetData = self.cheerUpPetData or self.petData
  if not targetPetData then
    return
  end
  local totalCheerUpPoint = 0
  local cheerPointTable = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.CHEER_POINT_CONF)
  for _, v in pairs(cheerPointTable) do
    local bHas, point = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsCheerUpRuleSatisfy, v.pet_type_1, v.pet_type_2, v.pet_type_3, targetPetData)
    if bHas then
      totalCheerUpPoint = totalCheerUpPoint + v.cheer_point
    end
  end
  local fontSize = totalCheerUpPoint >= 10 and totalCheerUpPoint <= 99 and 26 or 30
  local fontInfo = UE4.FSlateFontInfo()
  fontInfo.Size = fontSize
  fontInfo.FontMaterial = self.textPetNature_1.Font.FontMaterial
  fontInfo.FontObject = self.textPetNature_1.Font.FontObject
  fontInfo.LetterSpacing = self.textPetNature_1.Font.LetterSpacing
  fontInfo.OutlineSettings = self.textPetNature_1.Font.OutlineSettings
  fontInfo.TypefaceFontName = self.textPetNature_1.Font.TypefaceFontName
  self.textPetNature_1:SetFont(fontInfo)
  self.textPetNature_1:SetText(_G.LuaText.weekly_challenge_text_20 .. string.format("x%s", totalCheerUpPoint))
end

return UMG_CommonPetDetails_C
