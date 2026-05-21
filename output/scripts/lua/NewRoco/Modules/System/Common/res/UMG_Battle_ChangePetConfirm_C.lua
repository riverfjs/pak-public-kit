local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local TravelModuleEvent = reload("NewRoco.Modules.System.Travel.TravelModuleEvent")
local Base = require("NewRoco.Modules.System.BattleUI.Res.UMG_Battle_ChangePetConfirm_BaseUtility")
local UMG_Battle_ChangePetConfirm_C = Base:Extend("UMG_Battle_ChangePetConfirm_C")

function UMG_Battle_ChangePetConfirm_C:OnConstruct()
  Base.OnConstruct(self)
  self.CloseBtn.OnClicked:Add(self, self.OnClickClose)
  if self.CloseBtn_1 then
    self.CloseBtn_1.OnClicked:Add(self, self.OnClickClose)
  end
  if self.IconList then
    self.IconList.OnUserScrolled:Add(self, self.OnScrollChanged)
  end
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self:BindCloseHyperLink()
  if self.NRCTextDes then
    self.NRCTextDes.OnRichTextClick:Add(self, self.OnDescTextClicked)
  end
  self.descText = ""
end

function UMG_Battle_ChangePetConfirm_C:OnDestruct()
  self.CloseBtn.OnClicked:Remove(self, self.OnClickClose)
  if self.CloseBtn_1 then
    self.CloseBtn_1.OnClicked:Remove(self, self.OnClickClose)
  end
  if self.IconList then
    self.IconList.OnUserScrolled:Remove(self, self.OnScrollChanged)
  end
  if self:GetAnimByIndex(2) then
    self:UnbindAllFromAnimationFinished(self:GetAnimByIndex(2))
  else
    self:UnbindAllFromAnimationFinished(self.TweenOut)
  end
  self:UnbindCloseHyperLink()
  if self.NRCTextDes then
    self.NRCTextDes.OnRichTextClick:Remove(self, self.OnDescTextClicked)
  end
  Base.OnDestruct(self)
end

function UMG_Battle_ChangePetConfirm_C:BindCloseHyperLink()
  if self.CloseHyperLink then
    self.CloseHyperLink.OnClicked:Add(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_1 then
    self.CloseHyperLink_1.OnClicked:Add(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_2 then
    self.CloseHyperLink_2.OnClicked:Add(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_3 then
    self.CloseHyperLink_3.OnClicked:Add(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_4 then
    self.CloseHyperLink_4.OnClicked:Add(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_5 then
    self.CloseHyperLink_5.OnClicked:Add(self, self.OnCloseHyperLink)
  end
end

function UMG_Battle_ChangePetConfirm_C:UnbindCloseHyperLink()
  if self.CloseHyperLink then
    self.CloseHyperLink.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_1 then
    self.CloseHyperLink_1.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_2 then
    self.CloseHyperLink_2.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_3 then
    self.CloseHyperLink_3.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_4 then
    self.CloseHyperLink_4.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
  if self.CloseHyperLink_5 then
    self.CloseHyperLink_5.OnClicked:Remove(self, self.OnCloseHyperLink)
  end
end

function UMG_Battle_ChangePetConfirm_C:OnPcClose2()
  self:OnClickClose()
end

function UMG_Battle_ChangePetConfirm_C:OnActive(_data, IsNotChildPanel, notHideClose, showStrongPoint, PetFeatureShowData, callbackOwner, openCallback, closeCallback)
  Base.OnActive(self, _data)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").PETTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  self.IsInBattle = _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle)
  self.callbackOwner = callbackOwner
  self.closeCallback = closeCallback
  self.curBattleBaseId = _data.curBattleBaseId
  if self.IsInBattle then
    if self.Bg_pvp then
      self.Bg_pvp:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.Bg_pvp then
    self.Bg_pvp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.IsNotChildPanel = IsNotChildPanel
  self.showStrongPoint = nil == showStrongPoint or false
  if PetFeatureShowData and PetFeatureShowData.isShowPetTips then
    self:ShowPetFeatureTips(_data)
  elseif PetFeatureShowData and PetFeatureShowData.isShowPetSkill then
    self:ShowPetFeatureSkill(_data)
  elseif IsNotChildPanel then
    self:SetPetInfo(_data)
  elseif _data and _data.isPvpPrepareEnemy then
    self:SetPrepareEnemyInfo(_data)
  else
    self:Show(_data)
    if true == notHideClose then
    else
      self:HideClose()
    end
  end
  if not self:GetEnablePcEsc() then
    self:BindInputAction()
  end
  if openCallback then
    tcall(callbackOwner, openCallback)
  end
end

function UMG_Battle_ChangePetConfirm_C:OnDeactive()
  self:UnBindInputAction()
  if self.closeCallback then
    tcall(self.callbackOwner, self.closeCallback)
  end
  self.callbackOwner = nil
  self.closeCallback = nil
  Base.OnDeactive(self)
end

function UMG_Battle_ChangePetConfirm_C:OnMouseButtonUp(MyGeometry, MouseEvent)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Battle_ChangePetConfirm_C:SetHP(percent, bShowText)
  local hpLevelType = BattleUtils.EvaluateHpLevel(percent)
  if hpLevelType == BattleEnum.HpLevelType.Red then
    if self.HpBarPink then
      self.HpBarPink:SetPercent(percent)
    end
    if self.HpBarYellow then
      self.HpBarYellow:SetPercent(0)
    end
    if self.HpBarGreen then
      self.HpBarGreen:SetPercent(0)
    end
  elseif hpLevelType == BattleEnum.HpLevelType.Yellow then
    if self.HpBarPink then
      self.HpBarPink:SetPercent(0)
    end
    if self.HpBarYellow then
      self.HpBarYellow:SetPercent(percent)
    end
    if self.HpBarGreen then
      self.HpBarGreen:SetPercent(0)
    end
  else
    if self.HpBarPink then
      self.HpBarPink:SetPercent(0)
    end
    if self.HpBarYellow then
      self.HpBarYellow:SetPercent(0)
    end
    if self.HpBarGreen then
      self.HpBarGreen:SetPercent(percent)
    end
  end
  if self.hpText then
    if bShowText then
      local text = math.floor(percent * 100)
      self.hpText:SetText(string.format("%s%%", text))
      self.hpText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.hpText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_ChangePetConfirm_C:HideClose()
  self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CloseBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_ChangePetConfirm_C:Show(card)
  if not card then
    return
  end
  if card.petInfo == nil then
    Log.Error("UMG_Battle_ChangePetConfirm_C:Show card.petInfo is nil")
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").PETTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:Show")
  if self.HPBar then
    self.HPBar:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self.defentSize = self.CanvasPanel_1.Slot:GetSize()
  self.card = card
  local skillId, lock = self:GetPetFeatrueSkillId_Class4(card.petInfo.battle_common_pet_info, card.petInfo.battle_inside_pet_info)
  if lock then
    self.Lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.NameTxt:SetText(card.name)
  self.name = card.name
  local Pass = _G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg
  self.LvTxt:SetText(string.format(Pass, card.lv))
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.LVCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Visible)
  self:updatePetGender(card.petInfo.battle_common_pet_info.gender)
  if card.petState:GetMimic() then
    self.HeadIcon:SetIconPath(card.icon)
  else
    self.HeadIcon:SetIconPathAndMaterial(card.petBaseConf.id, card.petInfo.battle_common_pet_info.mutation_type, card.petInfo.battle_common_pet_info.glass_info)
  end
  if self.hpText then
    self.hpText:SetText(string.format("%d/%d", card.hp, card.max_hp))
    if BattleUtils.IsB1FinalBattleP3() then
      self.hpText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:SetHP(card:GetHpPercent())
  self:SetTypes(card.petInfo.battle_inside_pet_info.base_conf_id, card.petInfo.battle_common_pet_info.blood_id, false, true)
  self.TxtNeng:SetText(string.format("%d/%d", card.energy or 0, card.petBaseConf.max_energy))
  self:UpdateSkillListInCombat(card)
  self:InitAdaptation(card, skillId)
  self:StopAllAnimations()
  self:InitFeatures(skillId, lock)
  _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, true)
  local BattleManager = _G.BattleManager
  local state = BattleManager:GetCurrentStateName()
  local visible = state == BattleEnum.StateNames.RoundSelect or state == BattleEnum.StateNames.SwapSelect
  visible = visible and card:CanSummon()
  if not card:IsEnemy() then
    self.AttrList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if card:IsEnemy() then
    self:HideEnemyPetTips()
  end
  if card.isNameVisible == false then
    if self.NameMask then
      self.NameMask:LoadPanel(nil, self.name, false)
    end
  elseif self.NameMask then
    self.NameMask:UnLoadPanel(true)
  end
  self.Bg1:SetBackgroundVisible(false)
end

function UMG_Battle_ChangePetConfirm_C:SetPrepareEnemyInfo(petData, hasPetGid)
  self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Visible)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:SetPrepareEnemyInfo")
  _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, true)
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.LVCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:LoadPanelAnimation(0)
  if self.HPBar then
    self.HPBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.petData = petData
  self:ShowHandbookId(true)
  self:SetHP(1)
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:updatePetGender(-1)
  self.NameTxt:SetText(self.petData.name)
  local Pass = _G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg
  self.LvTxt:SetText(string.format(Pass, self.petData.level))
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if petBaseConf then
    local skillId, lock = self:GetPetFeatrueSkillId(petBaseConf)
    if lock then
      self.Lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    Base.UpdateBreakThroughStarsList(self, self.petData)
    self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
    self:SetTypes(self.petData.base_conf_id, self.petData.blood_id, false, false)
    self:InitFeatures(skillId, lock)
  end
  if self.BloodlineBattle then
    self.BloodlineBattle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_ChangePetConfirm_C:SetPetInfo(petData, hasPetGid, isAdjust)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:SetPetInfo")
  if self.IconList then
    self.IconList:ScrollToStart()
  end
  self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.Line1 then
    self.Line1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, true)
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.LVCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:LoadPanelAnimation(0)
  if petData.IsShowHp then
    if self.HPBar then
      self.HPBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif self.HPBar then
    self.HPBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local petGid = 0
  if hasPetGid then
    petGid = hasPetGid
    if self.HPBar then
      self.HPBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.AttrList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if petData then
      if petData.PetData then
        petGid = petData.PetData.gid
      else
        petGid = petData.gid
      end
    end
    if self.HPBar then
      self.HPBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.AttrList then
      self.AttrList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not self.petData then
    self.petData = petData.PetData
  end
  if self.petData then
    self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  end
  if isAdjust then
    self.petData = petData
    if self.PetAdjustTip then
      self.PetAdjustTip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    if not self.petData then
      self.petData = petData
    end
    if self.PetAdjustTip then
      self.PetAdjustTip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if petData and petData.PetData and petData.PetData.score then
    self.PetAdjustTip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if UE4.UObject.IsValid(self.Text_quantity) then
      self.Text_quantity:SetText(petData.PetData.score)
    end
  end
  if self.CanvasStrongPoint then
    if self.showStrongPoint and self.petData.speciality_id then
      self.CanvasStrongPoint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local specialityId = self.petData and self.petData.speciality_id
      local PetTalentConf = _G.DataConfigManager:GetPetTalentConf(specialityId)
      if PetTalentConf then
        self.SkillNameTxt_1:SetText(PetTalentConf.name)
        self.ChangeText:SetText(PetTalentConf.desc)
      else
        self.CanvasStrongPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.CanvasStrongPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:ShowHandbookId(true)
  local curHP, maxHP
  if self.petData and self.petData.additional_attr then
    curHP = PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPCUR)
    maxHP = PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPMAX)
  else
  end
  if curHP and maxHP then
    self:SetHP(curHP / maxHP)
  else
    self:SetHP(1)
  end
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self.petData then
    return
  end
  self:updatePetGender(self.petData.gender)
  self.NameTxt:SetText(self.petData.name)
  local Pass = _G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg
  self.LvTxt:SetText(string.format(Pass, self.petData.level))
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    local skillId, lock = self:GetPetFeatrueSkillId(petBaseConf)
    if lock then
      self.Lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
    Base.UpdateBreakThroughStarsList(self, self.petData)
    self.TxtNeng:SetText(string.format("%d/%d", self.petData.energy or 0, petBaseConf.max_energy))
    self:SetTypes(self.petData.base_conf_id, self.petData.blood_id, false, true)
    self:InitFeatures(skillId, lock)
  end
  if self.petData.attribute_new_info then
    local type = _G.ProtoEnum.AttributeType
    local addi_attr = self.petData.attribute_new_info.addi_attr_data
    if addi_attr and self.hpText then
      self.hpText:SetText(string.format("%d/%d", PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPCUR), PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPMAX)))
    end
  end
  self:InitSkillList()
  local attrList = {}
  local attrInfo = self.petData.attribute_info
  if not self.petData.attribute_new_info then
    return
  end
  local addi_attr = self.petData.attribute_new_info.addi_attr_data
  local positive_effect, negative_effect
  local natureConf = _G.DataConfigManager:GetNatureConf(self.petData.nature)
  if self.petData.changed_nature_pos_attr_type and 0 ~= self.petData.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_pos_attr_type)
  else
    positive_effect = natureConf.positive_effect
  end
  if self.petData.changed_nature_neg_attr_type and 0 ~= self.petData.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_neg_attr_type)
  else
    negative_effect = natureConf.negative_effect
  end
  local petBaseID = self.petData.finalEvoPetID or self.petData.base_conf_id
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_HPMAX,
    arrowType = _G.Enum.AttributeType.AT_HPMAX_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_HPMAX),
    attrInfo = attrInfo.hp,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_1
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYATK,
    arrowType = _G.Enum.AttributeType.AT_PHYATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_PHYATK),
    attrInfo = attrInfo.attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_3
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEATK,
    arrowType = _G.Enum.AttributeType.AT_SPEATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEATK),
    attrInfo = attrInfo.special_attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_4
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYDEF,
    arrowType = _G.Enum.AttributeType.AT_PHYDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_PHYDEF),
    attrInfo = attrInfo.defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_5
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEDEF,
    arrowType = _G.Enum.AttributeType.AT_SPEDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEDEF),
    attrInfo = attrInfo.special_defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_6
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEED,
    arrowType = _G.Enum.AttributeType.AT_SPEED_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEED),
    attrInfo = attrInfo.speed,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_2,
    NoShowLine = true
  })
  self:InitAttrList(attrList)
end

function UMG_Battle_ChangePetConfirm_C:GetChangeAttrReqEnum(attribute)
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

function UMG_Battle_ChangePetConfirm_C:SetBloodPulseIcon(_petData)
end

function UMG_Battle_ChangePetConfirm_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_ChangePetConfirm_C:InitAdaptation(card, skillId)
  if not card then
    return
  end
  local skillCount = #card:GetDisplaySkills()
  local featuresSize = self.defentSize
  featuresSize.y = 150
  if skillId and 0 ~= skillId then
    skillCount = skillCount + 1
  end
  for i = 1, skillCount do
    featuresSize.y = featuresSize.y + 96
  end
  self.CanvasPanel_1.Slot:SetSize(featuresSize)
end

function UMG_Battle_ChangePetConfirm_C:InitFeatures(skillId, lock)
  if 0 == skillId or nil == skillId then
    if self.SizeBox_67 then
      self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:LoadPanelAnimation(0)
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  if skillCfg then
    if skillCfg.icon then
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIcon:SetPath(skillCfg.icon)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:LoadPanelAnimation(0)
    else
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:LoadPanelAnimation(0)
    end
    self.SkillNameTxt:SetText(skillCfg.name)
    local des = skillCfg.desc
    local linkIds = BattleUtils.GetHyperLinkIds(des)
    if not (self.card and self.card:IsEnemy()) or #linkIds > 0 then
    end
    self.descText = des
    self.NRCTextDes:SetText(des)
    if self.SizeBox_67 then
      self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    if self.SizeBox_67 then
      self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:LoadPanelAnimation(0)
  end
end

function UMG_Battle_ChangePetConfirm_C:OnScrollChanged()
  if self.SkillList then
    self.SkillList:RefreshGridViewLayout()
  end
end

function UMG_Battle_ChangePetConfirm_C:OnCloseHyperLink()
  self:ShowOrHideCloseHyperLink(false)
end

function UMG_Battle_ChangePetConfirm_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Battle_ChangePetConfirm_C:InitSkillList()
  if not self.petData then
    return
  end
  local petEquipSkillList = self:GetPetEquipSkills(self.petData)
  if self.SkillList then
    self.SkillList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillList:InitGridView(petEquipSkillList)
    self.SkillList:RefreshGridViewLayout()
  end
end

function UMG_Battle_ChangePetConfirm_C:GetPetEquipSkills(petData)
  local petEquipSkills = {}
  if petData and petData.skill and petData.skill.skill_data then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  local RealEquipSkills = {}
  for i = 1, 4 do
    if petEquipSkills[i] then
      petEquipSkills[i].curBattleBaseId = self.curBattleBaseId
      table.insert(RealEquipSkills, petEquipSkills[i])
    end
  end
  return RealEquipSkills
end

function UMG_Battle_ChangePetConfirm_C:Hide(withAnim, bInBattle)
  _G.NRCAudioManager:PlaySound2DAuto(40002014, "UMG_Battle_ChangePetConfirm_C:Show")
  withAnim = withAnim or false
  bInBattle = bInBattle or nil == bInBattle
  if bInBattle then
    if not (not withAnim or self:IsAnimationPlaying(self.TweenIn)) or not self:IsAnimationPlaying(self:GetAnimByIndex(0)) then
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      if nil == self.card and _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle) then
        self:SetRenderOpacity(0)
      end
      self:LoadPanelAnimation(2)
      _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, false)
    elseif not self.IsNotChildPanel then
      if self.SetVisibility then
        self:SetVisibility(UE4.ESlateVisibility.Hidden)
      else
        Log.Error("self.SetVisibility Not Found")
      end
    end
  elseif not (not withAnim or self:IsAnimationPlaying(self.open) or self:IsAnimationPlaying(self.TweenIn)) or not self:IsAnimationPlaying(self:GetAnimByIndex(0)) then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:LoadPanelAnimation(2)
    _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, false)
  elseif not self.IsNotChildPanel then
    if self.SetVisibility then
      self:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      Log.Error("self.SetVisibility Not Found")
    end
  end
  self:OnCloseHyperLink()
end

function UMG_Battle_ChangePetConfirm_C:ShowInPetWarehouse()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:LoadPanelAnimation(0)
end

function UMG_Battle_ChangePetConfirm_C:InitAttrList(AttrList)
  self.AttrList:InitGridView(AttrList)
end

function UMG_Battle_ChangePetConfirm_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:SetRenderOpacity(1)
    if self.panelData then
      self:DoClose()
    end
  elseif Animation == self:GetAnimByIndex(0) then
    self:LoadPanelAnimation(1)
  elseif Animation == self:GetAnimByIndex(1) then
    self:LoadPanelAnimation(1)
  end
end

function UMG_Battle_ChangePetConfirm_C:ClosePanel()
  self:Hide()
  self.card = nil
end

function UMG_Battle_ChangePetConfirm_C:OnClickChoose()
  if not self.card then
    Log.Error("UMG_Battle_ChangePetConfirm_C - card is nil")
    return
  end
  self:Hide()
  self.card = nil
end

function UMG_Battle_ChangePetConfirm_C:OnClickClose()
  self:Hide(true, self.IsInBattle)
end

function UMG_Battle_ChangePetConfirm_C:HideEnemyPetTips()
  if not self.card then
    return
  end
  if BattleUtils.IsPartialShow(self.card) then
    self.PetTypePanel1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypePanel2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypePanel3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.BloodlineBattle then
    self.BloodlineBattle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.card:CheckIsMimic(true) then
    local skillId = _G.DataConfigManager:GetBattleGlobalConfig("battle_mimic_tip_skill").num
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg and skillCfg.icon then
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIcon:SetPath(skillCfg.icon)
      self.SkillNameTxt:SetText(skillCfg.name)
      local des = skillCfg.desc
      local linkIds = BattleUtils.GetHyperLinkIds(des)
      if not (self.card and self.card:IsEnemy()) or #linkIds > 0 then
      end
      self.descText = des
      self.NRCTextDes:SetText(des)
    end
  end
end

function UMG_Battle_ChangePetConfirm_C:ShowPetFeatureTips(infoData)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:ShowPetFeatureTips")
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.HPBar then
    if infoData.bShowHp and infoData.curHp and infoData.maxHp then
      self.HPBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local hpPercent = infoData.curHp / infoData.maxHp
      self:SetHP(hpPercent, infoData.bShowHpText)
    else
      self.HPBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.NRCImage_BG then
    self.NRCImage_BG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(infoData.petBaseId)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if infoData.isShinyFlower then
      self.HeadIcon:SetPetIconPathAndMaterial(modelConf.shiny_icon, _G.Enum.MutationDiffType.MDT_SHINING)
    else
      self.HeadIcon:SetPetIconPathAndMaterial(modelConf.icon, _G.Enum.MutationDiffType.MDT_NONE)
    end
    self.NameTxt:SetText(petBaseConf.name)
    local petFeatureSkillId = petBaseConf.pet_feature
    local skillCfg = _G.DataConfigManager:GetSkillConf(petFeatureSkillId)
    if skillCfg then
      self.SkillIcon:SetPath(skillCfg.icon)
      self.SkillNameTxt:SetText(skillCfg.name)
      self.descText = skillCfg.desc
      self.NRCTextDes:SetText(skillCfg.desc)
    end
    self:ShowHandbookId(true, infoData.petBaseId)
    local handbookInfo = _G.DataModelMgr.PlayerDataModel:GetHandbookInfoByPetBaseId(infoData.petBaseId)
    local typeList = {}
    if handbookInfo or infoData.bForceShowType then
      local unitTypeList = petBaseConf.unit_type
      for _, unitType in pairs(unitTypeList) do
        if unitType and unitType > 0 then
          table.insert(typeList, unitType)
        end
      end
    end
    self.Attr:InitGridView(typeList)
    local level = 0
    if infoData.level then
      level = infoData.level
    else
      local star = infoData.star
      if infoData.flowerSeedId and 0 ~= infoData.flowerSeedId then
        local seedConf = _G.DataConfigManager:GetActivitySpecFlowerSeedConf(infoData.flowerSeedId)
        level = seedConf.activity_team_battle_star_level[star] or 0
      elseif star then
        local key = string.format("team_battle_star_level_glass_%d", star)
        level = _G.DataConfigManager:GetPetGlobalConfig(key).numList[2]
      end
    end
    local Pass = _G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg
    self.LvTxt:SetText(string.format(Pass, level))
  else
    Log.Error("monster\232\161\168\228\184\173\231\154\132petBaseId\230\156\137\233\151\174\233\162\152\239\188\140\230\151\160\230\179\149\232\142\183\229\143\150petBaseConf\239\188\129\239\188\129\239\188\129")
  end
  self:LoadPanelAnimation(0)
end

function UMG_Battle_ChangePetConfirm_C:ShowHandbookId(bShowHandBookId, _baseId)
  local BaseId = _baseId or self.petData and self.petData.base_conf_id
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_HANDBOOK)
  local cfgDatas = cfgTable:GetAllDatas()
  local HandBookId = -1
  for i, v in pairs(cfgDatas) do
    local include_petbase_id = v.include_petbase_id
    if include_petbase_id and #include_petbase_id > 0 then
      for _, baseIdList in pairs(include_petbase_id) do
        local baseIdLists = baseIdList.petbase_id
        if baseIdLists and #baseIdLists > 0 then
          for _, baseId in pairs(baseIdLists) do
            if baseId == BaseId then
              HandBookId = v.id
              break
            end
          end
        end
        if -1 ~= HandBookId then
          break
        end
      end
    end
    if -1 ~= HandBookId then
      local text = "000"
      if HandBookId <= 9 then
        text = string.format("00%d", HandBookId)
      else
        text = string.format("0%d", HandBookId)
      end
      self.HandBookId:SetText(text)
      break
    end
  end
  if -1 == HandBookId then
    self.HandBookId:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif -1 ~= HandBookId and bShowHandBookId then
    self.HandBookId:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Battle_ChangePetConfirm_C:ShowPetFeatureSkill(petData)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").PETTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:ShowPetFeatureSkill")
  local bShowHandBookId = true
  if self.IconList then
    self.IconList:ScrollToStart()
  end
  self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.Line1 then
    self.Line1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCEventCenter:DispatchEvent(TravelModuleEvent.OnChangPetSkillTipsState, true)
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.LVCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:LoadPanelAnimation(0)
  if petData.IsMyself then
    local petGid = petData.gid
    self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  else
    self.petData = petData
  end
  bShowHandBookId = false
  self:SafeCall(self.AttrList, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  self:SafeCall(self.CanvasStrongPoint, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  self:ShowHandbookId(bShowHandBookId)
  local curHP, maxHP
  if self.petData.additional_attr then
    curHP = PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPCUR)
    maxHP = PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPMAX)
  else
  end
  if curHP and maxHP then
    self:SetHP(curHP / maxHP)
  else
    self:SetHP(1)
  end
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:updatePetGender(self.petData.gender)
  self.NameTxt:SetText(self.petData.name)
  local Pass = _G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg
  self.LvTxt:SetText(string.format(Pass, self.petData.level))
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if petBaseConf then
    local skillId, lock = self:GetPetFeatrueSkillId(petBaseConf)
    if lock then
      self.Lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
    Base.UpdateBreakThroughStarsList(self, self.petData)
    self.TxtNeng:SetText(string.format("%d/%d", self.petData.energy or 0, petBaseConf.max_energy))
    self:SetTypes(self.petData.base_conf_id, self.petData.blood_id, false, true)
    self:InitFeatures(skillId, lock)
  end
  if self.petData.attribute_new_info then
    local addi_attr = self.petData.attribute_new_info.addi_attr_data
    if addi_attr and self.hpText then
      self.hpText:SetText(string.format("%d/%d", PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPCUR), PetUtils.GetPetAdditionalByType(self.petData, _G.ProtoEnum.AttributeType.AT_HPMAX)))
    end
  end
  self:InitSkillList()
  local attrList = {}
  local attrInfo = self.petData.attribute_info
  if not self.petData.attribute_new_info then
    return
  end
  local positive_effect, negative_effect
  local natureConf = _G.DataConfigManager:GetNatureConf(self.petData.nature)
  if self.petData.changed_nature_pos_attr_type and 0 ~= self.petData.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_pos_attr_type)
  else
    positive_effect = natureConf.positive_effect
  end
  if self.petData.changed_nature_neg_attr_type and 0 ~= self.petData.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(self.petData.changed_nature_neg_attr_type)
  else
    negative_effect = natureConf.negative_effect
  end
  local petBaseID = self.petData.finalEvoPetID or self.petData.base_conf_id
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_HPMAX,
    arrowType = _G.Enum.AttributeType.AT_HPMAX_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_HPMAX),
    attrInfo = attrInfo.hp,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_1
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYATK,
    arrowType = _G.Enum.AttributeType.AT_PHYATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_PHYATK),
    attrInfo = attrInfo.attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_3
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEATK,
    arrowType = _G.Enum.AttributeType.AT_SPEATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEATK),
    attrInfo = attrInfo.special_attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_4
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYDEF,
    arrowType = _G.Enum.AttributeType.AT_PHYDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_PHYDEF),
    attrInfo = attrInfo.defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_5
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEDEF,
    arrowType = _G.Enum.AttributeType.AT_SPEDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEDEF),
    attrInfo = attrInfo.special_defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_6
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEED,
    arrowType = _G.Enum.AttributeType.AT_SPEED_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(self.petData, Enum.AttributeType.AT_SPEED),
    attrInfo = attrInfo.speed,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseID,
    name = LuaText.umg_battle_changepetconfirm_2,
    NoShowLine = true
  })
  self:InitAttrList(attrList)
end

function UMG_Battle_ChangePetConfirm_C:LoadPanelAnimation(index)
  self:StopAllAnimations()
  if self:GetAnimByIndex(index) then
    self:LoadAnimation(index)
  elseif 0 == index then
    self:PlayAnimation(self.TweenIn)
  elseif 1 == index then
    self:PlayAnimation(self.loop)
  elseif 2 == index then
    self:PlayAnimation(self.TweenOut)
  end
end

function UMG_Battle_ChangePetConfirm_C:ShowOrHideCloseHyperLink(bIsShow)
  if bIsShow then
    if self.CloseHyperLink then
      self.CloseHyperLink:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CloseHyperLink_1 then
      self.CloseHyperLink_1:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CloseHyperLink_2 then
      self.CloseHyperLink_2:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CloseHyperLink_3 then
      self.CloseHyperLink_3:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CloseHyperLink_4 then
      self.CloseHyperLink_4:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CloseHyperLink_5 then
      self.CloseHyperLink_5:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    if self.CloseHyperLink then
      self.CloseHyperLink:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CloseHyperLink_1 then
      self.CloseHyperLink_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CloseHyperLink_2 then
      self.CloseHyperLink_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CloseHyperLink_3 then
      self.CloseHyperLink_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CloseHyperLink_4 then
      self.CloseHyperLink_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.CloseHyperLink_5 then
      self.CloseHyperLink_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_ChangePetConfirm_C:BindInputAction()
  if not self.IsInBattle then
    local mappingContext = self:AddInputMappingContext("IMC_CommonCloseUI")
    if mappingContext then
      mappingContext:BindAction("IA_CloseUI", self, "OnPcClose2")
    end
  else
    local mappingContext = self:AddInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:BindAction("IA_CloseUI", self, "OnPcClose2")
    end
  end
end

function UMG_Battle_ChangePetConfirm_C:UnBindInputAction()
  if not self.IsInBattle then
    local mappingContext = self:GetInputMappingContext("IMC_CommonCloseUI")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseUI")
    end
    self:RemoveInputMappingContext("IMC_CommonCloseUI")
  else
    local mappingContext = self:GetInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseUI")
    end
    self:RemoveInputMappingContext("IMC_CloseBattleTips")
  end
end

return UMG_Battle_ChangePetConfirm_C
