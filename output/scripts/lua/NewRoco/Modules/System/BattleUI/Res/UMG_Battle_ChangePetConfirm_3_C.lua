local PetUtils = require("NewRoco.Utils.PetUtils")
local TravelModuleEvent = reload("NewRoco.Modules.System.Travel.TravelModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UMG_Battle_HP_C = require("NewRoco.Modules.System.BattleUI.Res.HUD.UMG_Battle_HP_C")
local BattleCard = require("NewRoco.Modules.Core.Battle.Entity.Card.BattleCard")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local Base = require("NewRoco.Modules.System.BattleUI.Res.UMG_Battle_ChangePetConfirm_BaseUtility")
local UMG_Battle_ChangePetConfirm_3_C = Base:Extend("UMG_Battle_ChangePetConfirm_3_C")

function UMG_Battle_ChangePetConfirm_3_C:OnConstruct()
  Base.OnConstruct(self)
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  if self.ScrollBox_47 then
    self.ScrollBox_47.OnUserScrolled:Add(self, self.OnScrollChanged)
  end
  self.hpText:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_ChangePetConfirm_3_C:OnActive(data)
  Base.OnActive(self, data)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_Battle_ChangePetConfirm_C:Show")
  self.IsClose = false
  self.descText = ""
  self:OnAddEventListener()
  if data.cardData then
    self:ShowPetInfoAsCard(data.cardData)
  elseif data.battlePetInfo then
    self:ShowPetInfoAsInfo(data.battlePetInfo)
  end
  self:BindInputAction()
  self:ShowForbidSkillTxt(data.forbidBuffList)
  self:LoadPanelAnimation(0)
end

function UMG_Battle_ChangePetConfirm_3_C:OnDeactive()
  self.CloseBtn.OnClicked:Remove(self, self.OnClickClose)
  self:UnbindCloseHyperLink()
  self:UnBindInputAction()
  if self.NRCTextDes then
    self.NRCTextDes.OnRichTextClick:Remove(self, self.OnDescTextClicked)
  end
  if self.NRCTextDes_1 then
    self.NRCTextDes_1.OnRichTextClick:Remove(self, self.OnResonanceDescTextClicked)
  end
  if self.CloseBtn_1 then
    self.CloseBtn_1.OnClicked:Remove(self, self.OnClickClose)
  end
  Base.OnDeactive(self)
end

function UMG_Battle_ChangePetConfirm_3_C:OnAddEventListener()
  self.CloseBtn.OnClicked:Add(self, self.OnClickClose)
  self:BindCloseHyperLink()
  if self.NRCTextDes then
    self.NRCTextDes.OnRichTextClick:Add(self, self.OnDescTextClicked)
  end
  if self.NRCTextDes_1 then
    self.NRCTextDes_1.OnRichTextClick:Add(self, self.OnResonanceDescTextClicked)
  end
  if self.CloseBtn_1 then
    self.CloseBtn_1.OnClicked:Add(self, self.OnClickClose)
  end
  self.SpeedComparisonBtn.OnClicked:Add(self, self.OnClickSpeedComparisonBtn)
  self.ParticularsBtn.btnLevelUp.OnReleased:Add(self, self.OnClickSpeedComparisonBtn)
end

function UMG_Battle_ChangePetConfirm_3_C:BindCloseHyperLink()
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

function UMG_Battle_ChangePetConfirm_3_C:UnbindCloseHyperLink()
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

function UMG_Battle_ChangePetConfirm_3_C:OnScrollChanged()
  if self.SkillList then
    self.SkillList:RefreshGridViewLayout()
  end
end

function UMG_Battle_ChangePetConfirm_3_C:ShowPetInfoAsCard(card)
  local bIsEnemy = card:IsEnemy()
  local bIsMyself = card:IsMyself()
  local bIsPartialShow = BattleUtils.IsPartialShow(card)
  local bIsNameVisible = card.isNameVisible
  local battle_common_pet_info = card.petInfo.battle_common_pet_info
  local battle_inside_pet_info = card.petInfo.battle_inside_pet_info
  local is_mimic = card.petState:GetMimic()
  local isSurpriseBox = card.petState:GetSurpriseBox()
  self:ShowPetInfo_Class4(battle_common_pet_info, battle_inside_pet_info, bIsPartialShow, bIsEnemy, bIsMyself, bIsNameVisible, is_mimic, isSurpriseBox)
  self:UpdateSkillListInCombat(card)
  self:InitResonance()
end

function UMG_Battle_ChangePetConfirm_3_C:ShowPetInfoAsInfo(info)
  local bIsEnemy = PetUtils.IsEnemy(info)
  local bIsMyself = PetUtils.IsMyself(info)
  local bIsPartialShow = PetUtils.IsPartialShow(info.battle_inside_pet_info)
  local battle_common_pet_info = info.battle_common_pet_info
  local battle_inside_pet_info = info.battle_inside_pet_info
  self:ShowPetInfo_Class4(battle_common_pet_info, battle_inside_pet_info, bIsPartialShow, bIsEnemy, bIsMyself, true)
  self:UpdateSkillListInCombat_EnemyReversePet(info)
end

function UMG_Battle_ChangePetConfirm_3_C:ShowPetInfo_Class4(battle_common_pet_info, battle_inside_pet_info, bIsPartialShow, bIsEnemy, bIsMyself, bIsNameVisible, is_mimic, isSurpriseBox)
  is_mimic = is_mimic or false
  local skillId, lock = self:GetPetFeatrueSkillId_Class4(battle_common_pet_info, battle_inside_pet_info)
  self.FeatureSkill = skillId
  if lock then
    self.Lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.LvTxt:SetText(string.format(_G.DataConfigManager:GetLocalizationConf("umg_pass_awarditem1_1").msg, battle_common_pet_info.level))
  self.CurIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Visible)
  self:UpdatePetGender(battle_common_pet_info.gender)
  if bIsEnemy and is_mimic then
    self.Unknown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NameTxt:SetText(LuaText.A1_finalbattle_unknown_pet_name)
    self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif isSurpriseBox then
    self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Unknown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NameTxt:SetText(LuaText.A1_finalbattle_unknown_pet_name)
    self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local iconPath = PetUtils.GetPetIconPath({battle_common_pet_info = battle_common_pet_info, battle_inside_pet_info = battle_inside_pet_info})
    if bIsPartialShow then
      self.HeadIcon:SetIconPath(iconPath)
    else
      local uiParam = self.HeadIcon:PrepareUIParam(battle_inside_pet_info)
      self.HeadIcon:SetPetIconPathAndMaterial(iconPath, battle_common_pet_info.mutation_type, battle_common_pet_info.glass_info, uiParam)
    end
  else
    local name = PetUtils.GetPetShowName({battle_common_pet_info = battle_common_pet_info, battle_inside_pet_info = battle_inside_pet_info})
    self.NameTxt:SetText(name)
    self.CanvasPanel_130:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Unknown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local iconPath = PetUtils.GetPetIconPath({battle_common_pet_info = battle_common_pet_info, battle_inside_pet_info = battle_inside_pet_info})
    if bIsPartialShow then
      self.HeadIcon:SetIconPath(iconPath)
    else
      local uiParam = self.HeadIcon:PrepareUIParam(battle_inside_pet_info)
      self.HeadIcon:SetPetIconPathAndMaterial(iconPath, battle_common_pet_info.mutation_type, battle_common_pet_info.glass_info, uiParam)
    end
  end
  local hp = BattleUtils.GetHPForPerform(battle_inside_pet_info)
  local hpPercent = BattleUtils.GetHPPercentForPerform(battle_inside_pet_info)
  local maxHp = PetUtils.GetMaxHP(battle_inside_pet_info)
  self:SetHP(bIsEnemy, hp, maxHp, hpPercent)
  self:SetTypes(battle_inside_pet_info.base_conf_id, battle_common_pet_info.blood_id, bIsPartialShow, bIsMyself)
  self:InitFeatures(skillId, bIsEnemy)
  if false == bIsNameVisible then
    if self.NameMask then
      self.NameMask:LoadPanel(nil, name, false)
      self.NameTxt:SetText(LuaText.A1_finalbattle_unknown_pet_name)
    end
  elseif self.NameMask then
    self.NameMask:UnLoadPanel(true)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:UpdatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_ChangePetConfirm_3_C:SetHP(bIsEnemy, hp, maxHp, hpPercent)
  self.HPBar:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  local hpText = ""
  if bIsEnemy then
    hpText = string.format("%s%s", tostring(UMG_Battle_HP_C.GetPercentForShow(hpPercent)), "%")
  else
    hpText = string.format("%s/%s", tostring(hp), tostring(maxHp))
  end
  self.hpText:SetText(hpText)
  local hpLevelType = BattleUtils.EvaluateHpLevel(hpPercent)
  if hpLevelType == BattleEnum.HpLevelType.Red then
    self.HpBarPink:SetPercent(hpPercent)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(0)
  elseif hpLevelType == BattleEnum.HpLevelType.Yellow then
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(hpPercent)
    self.HpBarGreen:SetPercent(0)
  else
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(hpPercent)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:InitFeatures(skillId, bIsEnemy)
  if 0 == skillId or nil == skillId then
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  if skillCfg then
    if skillCfg.icon then
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillIcon:SetPath(skillCfg.icon)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.SkillNameTxt:SetText(skillCfg.name)
    local des = skillCfg.desc
    self.descText = des
    local linkIds = BattleUtils.GetHyperLinkIds(des)
    if not bIsEnemy or #linkIds > 0 then
    end
    self.NRCTextDes:SetText(des)
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:OnCloseHyperLink()
  self:ShowOrHideCloseHyperLink(false)
end

function UMG_Battle_ChangePetConfirm_3_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Battle_ChangePetConfirm_3_C:OnResonanceDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.resonance_desc_text
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Battle_ChangePetConfirm_3_C:OnClickClose()
  if self.IsClose then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_Battle_ChangePetConfirm_C:Show")
  self.IsClose = true
  self:LoadPanelAnimation(2)
end

function UMG_Battle_ChangePetConfirm_3_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif Animation == self:GetAnimByIndex(0) then
    self:LoadPanelAnimation(1)
  elseif Animation == self:GetAnimByIndex(1) then
    self:LoadPanelAnimation(1)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:ShowForbidSkillTxt(forbidBuffList)
  local isHasForbidSkill = false
  if forbidBuffList and self.FeatureSkill then
    local skillConf = _G.DataConfigManager:GetSkillConf(self.FeatureSkill)
    local curBuff
    if skillConf and skillConf.skill_result and skillConf.skill_result[1] then
      curBuff = skillConf.skill_result[1].effect_id
    end
    if curBuff then
      for _, buff in ipairs(forbidBuffList) do
        if buff == curBuff then
          isHasForbidSkill = true
          break
        end
      end
    end
  end
  if isHasForbidSkill then
    self.SkillNameTxt_1:SetText(_G.LuaText.boss_special_skill_tips)
    self.SkillNameTxt_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.SkillNameTxt_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:ShowOrHideCloseHyperLink(bIsShow)
  local visibility = bIsShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
  self:SafeCall(self.CloseHyperLink, "SetVisibility", visibility)
  self:SafeCall(self.CloseHyperLink_1, "SetVisibility", visibility)
  self:SafeCall(self.CloseHyperLink_2, "SetVisibility", visibility)
  self:SafeCall(self.CloseHyperLink_3, "SetVisibility", visibility)
  self:SafeCall(self.CloseHyperLink_4, "SetVisibility", visibility)
  self:SafeCall(self.CloseHyperLink_5, "SetVisibility", visibility)
end

function UMG_Battle_ChangePetConfirm_3_C:LoadPanelAnimation(index)
  self:StopAllAnimations()
  self:LoadAnimation(index)
end

function UMG_Battle_ChangePetConfirm_3_C:OnClickSpeedComparisonBtn()
  if self.SpeedComparison and (self.SpeedComparison:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible or self.SpeedComparison:GetVisibility() == UE4.ESlateVisibility.Visible) then
    self.SpeedComparison:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local player_cards = {}
  local enemy_cards = {}
  local card_data = self.data.cardData
  local battle_pet_info = self.data.battlePetInfo
  if card_data then
    if card_data:IsInBattle() then
      player_cards = self:GetBattleCards(false)
      enemy_cards = self:GetBattleCards(true)
    elseif card_data:IsMyself() then
      table.insert(player_cards, {
        card_data,
        BattleEnum.SpeedCompare.ENUM_NOTSURE
      })
      enemy_cards = self:GetBattleCards(true)
    else
      player_cards = self:GetBattleCards(false)
      table.insert(enemy_cards, {
        card_data,
        BattleEnum.SpeedCompare.ENUM_NOTSURE
      })
    end
  else
    player_cards = self:GetBattleCards(false)
    table.insert(enemy_cards, {
      battle_pet_info,
      BattleEnum.SpeedCompare.ENUM_NOTSURE
    })
  end
  if #player_cards > 0 and #enemy_cards > 0 then
    local default_max_speed_num = _G.DataConfigManager:GetAttrGlobalConfig("at_speed_maximum").num
    local min_speed_num, max_speed_num = default_max_speed_num, 0
    local is_comparison = true
    for i = 1, #enemy_cards do
      local min_speed, max_speed
      local card = enemy_cards[i][1]
      if card.battle_inside_pet_info then
        min_speed, max_speed = card.battle_inside_pet_info.speed_min, card.battle_inside_pet_info.speed_max
      else
        min_speed, max_speed = card:GetSpeedMinMax()
        is_comparison = is_comparison and not card.petState:GetMimic()
      end
      if min_speed_num > min_speed then
        min_speed_num = min_speed
      end
      if max_speed_num < max_speed then
        max_speed_num = max_speed
      end
    end
    if default_max_speed_num < max_speed_num then
      default_max_speed_num = max_speed_num
    end
    for i = 1, #player_cards do
      local card = player_cards[i][1]
      local speed = card:GetSpeed()
      if is_comparison then
        if max_speed_num < speed then
          player_cards[i][2] = BattleEnum.SpeedCompare.ENUM_FASTER
        end
        if min_speed_num > speed then
          player_cards[i][2] = BattleEnum.SpeedCompare.ENUM_SLOWER
        end
      else
        player_cards[i][2] = BattleEnum.SpeedCompare.ENUM_NOTSURE
      end
      if default_max_speed_num < speed then
        default_max_speed_num = speed
      end
    end
    for i = 1, #enemy_cards do
      enemy_cards[i][3] = default_max_speed_num
    end
    for i = 1, #player_cards do
      player_cards[i][3] = default_max_speed_num
    end
    self:SafeCall(self.SpeedComparison.OurSideList, "Clear")
    self:SafeCall(self.SpeedComparison.OurSideList, "InitGridView", player_cards)
    self:SafeCall(self.SpeedComparison.EnemyList, "Clear")
    self:SafeCall(self.SpeedComparison.EnemyList, "InitGridView", enemy_cards)
    self:SafeCall(self.SpeedComparison, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.SpeedComparison, "PlayAnimation", self.SpeedComparison.Appear)
    self:SafeCall(self.PetTypeAdvantagePanel, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_ChangePetConfirm_3_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_CloseBattlePetTips")
  if mappingContext then
    mappingContext:BindAction("IA_ClosePetInfoUI", self, "OnPcClose2")
  end
end

function UMG_Battle_ChangePetConfirm_3_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_CloseBattlePetTips")
  if mappingContext then
    mappingContext:UnBindAction("IA_ClosePetInfoUI")
  end
  self:RemoveInputMappingContext("IMC_CloseBattlePetTips")
end

function UMG_Battle_ChangePetConfirm_3_C:OnPcClose2()
  self:OnClickClose()
end

return UMG_Battle_ChangePetConfirm_3_C
