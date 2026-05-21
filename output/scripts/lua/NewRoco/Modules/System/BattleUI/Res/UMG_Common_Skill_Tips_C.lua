local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
local UMG_Common_Skill_Tips_C = _G.NRCPanelBase:Extend("UMG_Common_Skill_Tips_C")
UMG_Common_Skill_Tips_C.DamageTypeMap = {
  [1] = nil,
  [2] = 1,
  [3] = 2
}
UMG_Common_Skill_Tips_C.CloseInputActionType = {Default = 1, BattleSkillItem = 2}
UMG_Common_Skill_Tips_C.ContextData = nil

function UMG_Common_Skill_Tips_C:OnConstruct()
  self.bNeedDisableDescTip = nil
  self.spEnergyUI = {
    self.SpEnergySkillInfo1,
    self.SpEnergySkillInfo2,
    self.SpEnergySkillInfo3,
    self.SpEnergySkillInfo4
  }
  self.descText = ""
  self:AddButtonListener(self.HotArea, self.OnHotAreaClick)
  self:AddButtonListener(self.CloseHyperLink, self.OnCloseHyperLink)
  self.Desc.OnRichTextClick:Add(self, self.OnDescTextClicked)
end

function UMG_Common_Skill_Tips_C:OnDestruct()
  self.spEnergyUI = {}
  self:RemoveButtonListener(self.HotArea)
  self:RemoveButtonListener(self.CloseHyperLink, self.OnCloseHyperLink)
  self.Desc.OnRichTextClick:Remove(self, self.OnDescTextClicked)
end

function UMG_Common_Skill_Tips_C:OnActive(contextData, ShowBlur, bNeedDisableDescTip)
  self.contextData = contextData
  self.bNeedDisableDescTip = bNeedDisableDescTip
  if ShowBlur then
    self.NRCImage_35:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_17:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_35:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_17:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.PPKanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
    self.EnergySwitcher:SetActiveWidgetIndex(1)
  else
    self.EnergySwitcher:SetActiveWidgetIndex(0)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400002, "UMG_Common_Skill_Tips_C:OnHotAreaClick")
  if contextData.offset then
    local CanvasSlot = self.ContentOffset.Slot
    CanvasSlot:SetPosition(contextData.offset)
  end
  self.IsHideClose = contextData.HideClose
  if contextData.skillData then
    Log.Debug("Will Update Skill Data")
    self:UpdateInfo(contextData.skillData, contextData.skillEntity)
  end
  if contextData.restraintResult then
    local restraintResult = contextData.restraintResult
    if restraintResult and restraintResult ~= BattleEnum.TypeRestraint.ENUM_NONE then
      self.Gain:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
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
      end
    else
      self.Gain:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:BindInputAction()
  if self.contextData and self.contextData.callbackOwner and self.contextData.openCallback then
    tcall(self.contextData.callbackOwner, self.contextData.openCallback)
  end
end

function UMG_Common_Skill_Tips_C:OnPcClose()
  self:OnHotAreaClick()
end

function UMG_Common_Skill_Tips_C:OnDeactive()
  self:UnBindInputAction()
  if self.contextData and self.contextData.callbackOwner and self.contextData.closeCallback then
    tcall(self.contextData.callbackOwner, self.contextData.closeCallback)
  end
  self.contextData = nil
end

function UMG_Common_Skill_Tips_C:SetClickClose(bClickClose)
  if bClickClose then
    self.HotArea:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.HotArea:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_Skill_Tips_C:OnCloseHyperLink()
end

function UMG_Common_Skill_Tips_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Common_Skill_Tips_C:UpdateInfo(skillData, skillEntity)
  self:OnCloseHyperLink()
  local commonAttrData = {}
  local skillConf = SkillUtils.GetSkillConf(skillData.id)
  if not skillConf then
    return
  end
  local newSkillConfig = skillConf
  if skillEntity then
    newSkillConfig = _G.BattleManager.battleRuntimeData:GetNewSkillBySpEnergy(skillEntity)
  end
  if newSkillConfig then
    self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(newSkillConfig.icon, _G.UIIconPath.SkillIconPath))
    self.TxtSkillName:SetText(newSkillConfig.name)
    local skillType = newSkillConfig.skill_dam_type
    if Enum.SkillDamType.SDT_RELAX ~= skillType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillType)
      if typeDic then
        table.insert(commonAttrData, {
          Path = typeDic.tips_res
        })
      end
    end
    local damageType = skillData.damage_type or newSkillConfig.damage_type
    local text, iconpath = BattleUtils.GetSkillTypePath(newSkillConfig.Skill_Type, damageType)
    self.SkillTypeIcon1:SetPath(iconpath)
    self.SkillTypeText:SetText(text)
  end
  if skillData.type == ProtoEnum.SkillActiveType.SAT_LACKENERGY then
    self.StarImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TxtPnum:SetText(tostring(skillConf.energy_cost[1]))
  elseif skillData.type == ProtoEnum.SkillActiveType.SAT_IDLE then
    self.StarImage:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif skillData.type == ProtoEnum.SkillActiveType.SAT_FEATURE then
    self.StarImage:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif skillConf.energy_rule ~= Enum.EnergyRule.ER_ROLEHP then
    self.StarImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TxtPnum:SetText(tostring(skillConf.energy_cost[1]))
  else
    self.StarImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local damageTypeImg = UMG_Common_Skill_Tips_C.DamageTypeMap[skillConf.damage_type]
  if skillConf.damage_type ~= ProtoEnum.DamageType.DT_NONE then
    if newSkillConfig and commonAttrData[1] then
      commonAttrData[1].Name = tostring(newSkillConfig.dam_para[1])
    end
    self.ImgPower:ChangeImage(damageTypeImg)
    self.ImgPower:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ImgPower:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if commonAttrData[1] then
      commonAttrData[1].Name = "-"
    end
  end
  if self.Attr then
    self.Attr:InitGridView(commonAttrData)
  end
  self.CDText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.bNeedDisableDescTip then
    self.Desc:SetText(UE4.UNRCStatics.ExtractDescIdKeywords(skillConf.desc))
  else
    self.descText = skillConf.desc
    self.Desc:SetText(skillConf.desc)
  end
  self.NRCTextDes_1:SetText(skillConf.flavor_text)
  if _G.BattleManager.isInBattle and 1 ~= skillConf.damage_type and not BattleUtils:IsFirstMeetAllEnemyPet(_G.BattleManager.battlePawnManager.playerTeam.player) then
    local restraintResult = BattleEnum.TypeRestraint.ENUM_NONE
    if not self.contextData.is_skill_conf then
      restraintResult = BattleUtils:GetSkillRestraint(skillData)
      if restraintResult ~= BattleEnum.TypeRestraint.ENUM_NONE then
        self.Gain:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
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
        end
      else
        self.Gain:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  else
    self.Gain:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _G.BattleManager.isInBattle then
    self:SetIntensifyInfo(skillData, skillEntity)
  else
    self.Amplify_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if skillConf.target_field and #skillConf.target_field > 0 and #skillConf.field_skill > 0 then
    self.Content_SpEnergy:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    for i = 1, #self.spEnergyUI do
      if i <= #skillConf.target_field and skillConf.field_skill[i] > 0 then
        self.spEnergyUI[i]:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.spEnergyUI[i]:InitUI(skillConf.field_belong, skillConf.target_field[i], skillConf.field_skill[i])
      else
        self.spEnergyUI[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  else
    self.Content_SpEnergy:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.IsHideClose then
    self:SetClickClose(false)
  end
  self:PlayAnimation(self.TweenIn)
end

function UMG_Common_Skill_Tips_C:SetIntensifyInfo(skillData, skillEntity)
  if self.contextData.is_skill_conf then
    self.Amplify_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif skillData.enhance_info and #skillData.enhance_info > 0 then
    self.Amplify_List:SetVisibility(UE4.ESlateVisibility.Visible)
    local IntensifyList = BattleUtils.PreProcessEnhanceInfo(skillData.enhance_info, skillEntity and skillEntity.owner and skillEntity.owner.card)
    IntensifyList = BattleUtils.OverlayEnhanceInfo(IntensifyList)
    self.Amplify_List:InitList(IntensifyList)
  else
    self.Amplify_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_Skill_Tips_C:OnAnimationFinished(Animation)
  if self.TweenIn == Animation then
    if not self.IsHideClose then
      self.HotArea:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.canCloseTips = true
  elseif self.TweenOut == Animation then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetSkillsPanelCanScroll, true)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.SetIsCanCloseBagPopUp, true)
    self:DoClose()
  end
end

function UMG_Common_Skill_Tips_C:OnHotAreaClick()
  if not self.canCloseTips then
    return
  end
  Log.Debug("UMG_Common_Skill_Tips_C:OnHotAreaClick")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400003, "UMG_Common_Skill_Tips_C:OnHotAreaClick")
  self.HotArea:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:PlayAnimation(self.TweenOut)
end

function UMG_Common_Skill_Tips_C:BindInputAction()
  local closeInputActionType = self.contextData and self.contextData.closeInputActionType or UMG_Common_Skill_Tips_C.CloseInputActionType.Default
  if closeInputActionType == UMG_Common_Skill_Tips_C.CloseInputActionType.Default then
    local mappingContext = self:AddInputMappingContext("IMC_CommonCloseUI")
    if mappingContext then
      mappingContext:BindAction("IA_CloseUI", self, "OnPcClose")
    end
  elseif closeInputActionType == UMG_Common_Skill_Tips_C.CloseInputActionType.BattleSkillItem then
    local mappingContext = self:AddInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:BindAction("IA_CloseUI", self, "OnPcClose")
    end
  end
end

function UMG_Common_Skill_Tips_C:UnBindInputAction()
  local closeInputActionType = self.contextData and self.contextData.closeInputActionType or UMG_Common_Skill_Tips_C.CloseInputActionType.Default
  if closeInputActionType == UMG_Common_Skill_Tips_C.CloseInputActionType.Default then
    local mappingContext = self:GetInputMappingContext("IMC_CommonCloseUI")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseUI")
    end
    self:RemoveInputMappingContext("IMC_CommonCloseUI")
  elseif closeInputActionType == UMG_Common_Skill_Tips_C.CloseInputActionType.BattleSkillItem then
    local mappingContext = self:GetInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseUI")
    end
    self:RemoveInputMappingContext("IMC_CloseBattleTips")
  end
end

return UMG_Common_Skill_Tips_C
