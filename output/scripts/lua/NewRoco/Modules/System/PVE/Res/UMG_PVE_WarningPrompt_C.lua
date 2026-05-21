local UMG_PVE_WarningPrompt_C = _G.NRCPanelBase:Extend("UMG_PVE_WarningPrompt_C")

function UMG_PVE_WarningPrompt_C:OnActive(RuleIds, auto_close)
  self.auto_close = auto_close or false
  self:UpdateData(RuleIds)
  self:RefreshUI()
  self:PlayAnimation(self.In)
end

function UMG_PVE_WarningPrompt_C:UpdateData(RuleIds)
  self.battle_rules = {}
  for _, ruleId in pairs(RuleIds) do
    local ruleConf = _G.DataConfigManager:GetBattleRuleConf(ruleId)
    if ruleConf then
      local rule_text = ""
      if ruleConf.title then
        rule_text = string.format([[
%s
%s]], ruleConf.title, ruleConf.desc)
      else
        rule_text = ruleConf.desc
      end
      table.insert(self.battle_rules, {
        descText = rule_text,
        id = ruleId,
        limitIndex = #RuleIds,
        parent = self
      })
    end
  end
end

function UMG_PVE_WarningPrompt_C:RefreshUI()
  if self.auto_close then
    local Conf = _G.DataConfigManager:GetBattleGlobalConfig("battle_attention_tip_show_time")
    self:DelaySeconds(Conf.num / 1000, self.CountDownOver, self)
  end
  self.Btn.OnClicked:Add(self, self.OnClick)
  self.NounInterpretationTips:SetDescList(self.battle_rules)
  self.NRCImage_47:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HorizontalBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NounInterpretationTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PVE_WarningPrompt_C:CountDownOver()
  self:DoClose()
end

function UMG_PVE_WarningPrompt_C:OnClick()
  self:DoClose()
end

function UMG_PVE_WarningPrompt_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.link_ids = {id}
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_PVE_WarningPrompt_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

return UMG_PVE_WarningPrompt_C
