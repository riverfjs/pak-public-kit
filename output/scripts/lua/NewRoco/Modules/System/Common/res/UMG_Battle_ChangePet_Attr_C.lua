local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleModuleCmd = require("NewRoco.Modules.Core.Battle.BattleModuleCmd")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_ChangePet_Attr_C = Base:Extend("UMG_Battle_ChangePet_Attr_C")

function UMG_Battle_ChangePet_Attr_C:OnConstruct()
  if self.Desc then
    self.Desc.OnRichTextClick:Add(self, self.OnDescTextClicked)
  end
end

function UMG_Battle_ChangePet_Attr_C:OnDestruct()
  if self.Desc then
    self.Desc.OnRichTextClick:Remove(self, self.OnDescTextClicked)
  end
end

function UMG_Battle_ChangePet_Attr_C:OnItemUpdate(_data, datalist, index)
  self:UpdateInfo(_data)
end

function UMG_Battle_ChangePet_Attr_C:UpdateInfo(data)
  local skillData = data
  if not skillData then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if skillData.id < 0 then
    self:UpdateInfoAsUnknowSkill()
  else
    self:UpdateInfoAsNormalSkill(data)
  end
end

function UMG_Battle_ChangePet_Attr_C:UpdateInfoAsUnknowSkill()
  self:ToggleWidgets(false)
  local iconPath = "Texture2D'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/SkillIcon/img_wenhao.img_wenhao'"
  self.SkillIcon:SetPath(iconPath)
  self.TxtSkillName:SetText(_G.LuaText.pet_skill_name_unknow)
end

function UMG_Battle_ChangePet_Attr_C:UpdateInfoAsNormalSkill(data)
  local skillData = data
  local petGuid = data and data.petGuid
  local battleCard = petGuid and _G.BattleManager.battlePawnManager:GetCardByGuid(petGuid)
  local skillConf = _G.SkillUtils.GetSkillConf(skillData.id)
  if not skillConf then
    Log.Debug("\230\138\128\232\131\189id\230\178\146\230\156\137\230\137\190\229\136\176", skillData.skill_id)
  end
  self:ToggleWidgets(true)
  local skillIcon = skillConf and skillConf.icon or ""
  local skillName = skillConf and skillConf.name or ""
  local skillDesc = skillConf and skillConf.desc or ""
  local skill_dam_type = skillConf and skillConf.skill_dam_type
  local damage_type = skillConf and skillConf.damage_type
  local energy_rule = skillConf and skillConf.energy_rule
  local dam_para = skillConf and skillConf.dam_para or {}
  local energy_cost = skillConf and skillConf.energy_cost or {}
  self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(skillIcon, _G.UIIconPath.SkillIconPath))
  local fantasticBackgroundPath = ""
  local performFlag = skillData and skillData.perform_flag
  local petId = data and data.petGuid
  local skillId = skillData and skillData.skill_id
  local seasonId = skillData and skillData.season_id
  if performFlag == _G.ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_FANTASTIC then
    local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, seasonId)
    fantasticBackgroundPath = paths and paths.squareNm3 or fantasticBackgroundPath
  end
  local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
  if not string.IsNilOrEmpty(fantasticBackgroundPath) then
    selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  self.Select_NM_3:SetPath(fantasticBackgroundPath)
  self.Select_NM_3:SetVisibility(selectNm3Visibility)
  self.TxtSkillName:SetText(skillName)
  if self._parent.parentPanel.isDisableDesc then
    self.Desc:SetText(UE4.UNRCStatics.ExtractDescIdKeywords(skillDesc))
  else
    self.descText = skillDesc
    self.Desc:SetText(skillDesc)
  end
  local bLast = self._index == #self._data
  if bLast then
    self.Divider:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Divider:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local typeDic = _G.DataConfigManager:GetTypeDictionary(skill_dam_type)
  if typeDic then
    self.PetTypeIcon:SetPath(typeDic.tips_res)
  end
  if damage_type == Enum.DamageType.DT_NONE then
    self.TxtPower:SetText("-")
  else
    self.TxtPower:SetText(string.format("%d", dam_para[1] or 0))
  end
  if _G.BattleManager.isInBattle and 1 ~= damage_type and not BattleUtils:IsFirstMeetAllEnemyPet(_G.BattleManager.battlePawnManager.TeamatePlayer) then
    self.GainCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local restraintResult = BattleUtils:GetSkillRestraint(skillData)
    if restraintResult == BattleEnum.TypeRestraint.ENUM_NORMAL then
      self.EffectSwitcher:SetActiveWidgetIndex(1)
    elseif restraintResult == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
      self.EffectSwitcher:SetActiveWidgetIndex(0)
    elseif restraintResult == BattleEnum.TypeRestraint.ENUM_RESTRAINT_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(3)
    elseif restraintResult == BattleEnum.TypeRestraint.ENUM_WEAK then
      self.EffectSwitcher:SetActiveWidgetIndex(2)
    elseif restraintResult == BattleEnum.TypeRestraint.ENUM_WEAK_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(4)
    else
      self.GainCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif skillData.curBattleBaseId and skillData.curBattleBaseId > 0 and 1 ~= damage_type then
    self.GainCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local isPhase, IsDouble = PetUtils.GetTypeRestraint(skillData.curBattleBaseId, {skill_dam_type})
    if nil == isPhase then
      self.EffectSwitcher:SetActiveWidgetIndex(1)
    elseif false == isPhase then
      if IsDouble then
        self.EffectSwitcher:SetActiveWidgetIndex(4)
      else
        self.EffectSwitcher:SetActiveWidgetIndex(2)
      end
    elseif true == isPhase then
      if IsDouble then
        self.EffectSwitcher:SetActiveWidgetIndex(3)
      else
        self.EffectSwitcher:SetActiveWidgetIndex(0)
      end
    else
      self.GainCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.GainCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if energy_rule == Enum.EnergyRule.ER_ROLEHP then
    self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.StarImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RoleHPImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillNengNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillNengNum:SetText(energy_cost[1])
  else
    self.RoleHPImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 0 == skillData.cost_energy and 0 == energy_cost[1] then
      self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.StarImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillNengNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SkillNengNum:SetText(energy_cost[1])
    end
  end
  if skillData.skill_id then
    local skillEnhanceInfos = _G.NRCModuleManager:DoCmd(BattleModuleCmd.CollectSkillEnhanceInfoForChangePetAttr, skillData.skill_id, petGuid)
    local ownerPlayer = battleCard and battleCard.owner
    local deck = ownerPlayer and ownerPlayer.deck
    local ownerPlayerBattleCards = deck and deck.cards or {}
    local inFieldCards = {}
    for i, card in ipairs(ownerPlayerBattleCards) do
      if card:IsInBattle() then
        table.insert(inFieldCards, card)
      end
    end
    local firstPetCard = inFieldCards and inFieldCards[1]
    skillEnhanceInfos = BattleUtils.PreProcessEnhanceInfo(skillEnhanceInfos, firstPetCard)
    skillEnhanceInfos = BattleUtils.OverlayEnhanceInfo(skillEnhanceInfos)
    if next(skillEnhanceInfos) then
      self.AttrList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.AttrList:InitGridView(skillEnhanceInfos)
    else
      self.AttrList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.AttrList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PlayAnimation(self.TweenIn, 0, 1)
end

function UMG_Battle_ChangePet_Attr_C:OnItemSelected(_bSelected)
  self:OnCloseHyperLink()
end

function UMG_Battle_ChangePet_Attr_C:OnCloseHyperLink()
  if self._parent.parentPanel and self._parent.parentPanel.OnCloseHyperLink then
    self._parent.parentPanel:OnCloseHyperLink()
  end
end

function UMG_Battle_ChangePet_Attr_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Battle_ChangePet_Attr_C:ToggleWidgets(bNormalSkill)
  local hideForUnknow = bNormalSkill and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed
  local showForAll = UE4.ESlateVisibility.SelfHitTestInvisible
  self.SkillIcon:SetVisibility(showForAll)
  self.TxtSkillName:SetVisibility(showForAll)
  self.Divider:SetVisibility(showForAll)
  self.TxtPower:SetVisibility(hideForUnknow)
  self.Desc:SetVisibility(hideForUnknow)
  self.PetTypeIcon:SetVisibility(hideForUnknow)
  self.Canvasnenliang:SetVisibility(hideForUnknow)
  self.GainCanvas:SetVisibility(hideForUnknow)
  self.GainCanvas:SetVisibility(hideForUnknow)
  self.StarImage:SetVisibility(hideForUnknow)
  self.RoleHPImage:SetVisibility(hideForUnknow)
  self.AttrList:SetVisibility(hideForUnknow)
end

return UMG_Battle_ChangePet_Attr_C
