local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_HerbologyBadge_SkillTips_C = _G.NRCViewBase:Extend("UMG_HerbologyBadge_SkillTips_C")

function UMG_HerbologyBadge_SkillTips_C:OnConstruct()
  self:AddButtonListener(self.CloseBtn, self.OnClose)
  self:AddButtonListener(self.TipsSillTab.Button, self.ShowFeatureTips)
  self:AddButtonListener(self.TipsSillTab_1.Button, self.ShowSkillTips)
  self:AddButtonListener(self.Btn_Details.btnLevelUp, self.OpenPetInfoPanel)
  self:AddButtonListener(self.NRCButton_6, self.OpenPetInfoPanel)
  self.TipsSillTab.Name:SetText(LuaText.umg_petleftpanel_11)
  self.TipsSillTab_1.Name:SetText(LuaText.umg_petleftpanel_2)
  self.List_Characteristics:SetMsgHandler({
    OnItemClick = _G.MakeWeakFunctor(self, self.OnFeatureClick)
  })
  self.List_Sill:SetMsgHandler({
    OnItemClick = _G.MakeWeakFunctor(self, self.OnSkillClick)
  })
end

function UMG_HerbologyBadge_SkillTips_C:OnClose()
  self:PlayAnimation(self.Out)
end

function UMG_HerbologyBadge_SkillTips_C:ActiveFeatures()
  self:SetVisibility(UE.ESlateVisibility.Visible)
  self:PlayAnimation(self.In_online)
  self.Switcher:SetActiveWidgetIndex(0)
  self.TipsSillTab:PlayAnimation(self.TipsSillTab.Press)
  local Title = string.format(LuaText.grass_trial_feature_title, tostring(#self.module.Data.TrialPetInfo.acquired_feature_ids))
  self.Title:SetText(Title)
  self:InitList()
  self:SetSkillBtnNormal()
end

function UMG_HerbologyBadge_SkillTips_C:ActiveSkills()
  self:SetVisibility(UE.ESlateVisibility.Visible)
  self:PlayAnimation(self.In_online)
  self.Switcher:SetActiveWidgetIndex(1)
  self.TipsSillTab_1:PlayAnimation(self.TipsSillTab.Press)
  local Title = string.format(LuaText.grass_trial_skill_title, tostring(#self.module.Data.TrialPetInfo.skills))
  self.Title:SetText(Title)
  self:InitList()
  self:SetFeatureBtnNormal()
end

function UMG_HerbologyBadge_SkillTips_C:InitList()
  self.List_Sill:InitList(self.module.Data.TrialPetInfo.skills)
  self.List_Characteristics:InitList(self.module.Data.TrialPetInfo.acquired_feature_ids)
end

function UMG_HerbologyBadge_SkillTips_C:OnAnimationFinished(Animation)
  if Animation == self.Out then
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_SkillTips_C:ShowFeatureTips()
  self.TipsSillTab:PlayAnimation(self.TipsSillTab.Press)
  self.Switcher:SetActiveWidgetIndex(0)
  local Title = string.format(LuaText.grass_trial_feature_title, tostring(#self.module.Data.TrialPetInfo.acquired_feature_ids))
  self.Title:SetText(Title)
  self.TipsSillTab_1:PlayAnimation(self.TipsSillTab_1.Press, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
end

function UMG_HerbologyBadge_SkillTips_C:ShowSkillTips()
  self.TipsSillTab_1:PlayAnimation(self.TipsSillTab.Press)
  self.Switcher:SetActiveWidgetIndex(1)
  local Title = string.format(LuaText.grass_trial_skill_title, tostring(#self.module.Data.TrialPetInfo.skills))
  self.Title:SetText(Title)
  self.TipsSillTab:PlayAnimation(self.TipsSillTab_1.Press, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
end

function UMG_HerbologyBadge_SkillTips_C:SetSkillBtnNormal()
  self.TipsSillTab_1.Select_BG:SetRenderOpacity(0)
  self.TipsSillTab_1.BackGround:SetRenderOpacity(1)
  self.TipsSillTab_1.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#8D8A77FF"))
end

function UMG_HerbologyBadge_SkillTips_C:SetFeatureBtnNormal()
  self.TipsSillTab.Select_BG:SetRenderOpacity(0)
  self.TipsSillTab.BackGround:SetRenderOpacity(1)
  self.TipsSillTab.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#8D8A77FF"))
end

function UMG_HerbologyBadge_SkillTips_C:OpenPetInfoPanel()
  self.module:OpenHerbologyBadgeDetailedInformation()
end

function UMG_HerbologyBadge_SkillTips_C:OnFeatureClick(FeatureIndex)
  local FeatureID = self.module.Data.TrialPetInfo.acquired_feature_ids[FeatureIndex]
  _G.NRCModuleManager:DoCmd(BattleRogueModuleCmd.OpenPeculiarityTips, FeatureID)
end

function UMG_HerbologyBadge_SkillTips_C:OnSkillClick(SkillIndex)
  local SkillID = self.module.Data.TrialPetInfo.skills[SkillIndex].base_skill_id
  _G.NRCModuleManager:DoCmd(BattleRogueModuleCmd.OpenPeculiarityTips, SkillID)
end

return UMG_HerbologyBadge_SkillTips_C
