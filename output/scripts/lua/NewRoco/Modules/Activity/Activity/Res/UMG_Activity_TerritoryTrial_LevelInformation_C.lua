local UMG_Activity_TerritoryTrial_LevelInformation_C = _G.NRCPanelBase:Extend("UMG_Activity_TerritoryTrial_LevelInformation_C")

function UMG_Activity_TerritoryTrial_LevelInformation_C:OnConstruct()
  self:SetChildViews(self.PopUp, self.previewWorld)
  self.firstSelect = true
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:OnActive(information)
  for _, v in ipairs(information.tabData) do
    v.caller = self
    v.selectedCallback = self.InitInformation
  end
  self.ListTab:InitList(information.tabData)
  self.information = information
  self.ContentDetails.OnRichTextClick:Add(self, self.SetDescText)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenTypeTips)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.ClosePanelHandler = self.CloseBtnClick
  CommonPopUpData.Call = self
  self.PopUp:SetPanelInfo(CommonPopUpData)
  local guard_data = information.guardData[1]
  self.ListTab:SelectItemByIndex(0)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.previewWorld:SetPreviewByPetBaseId(nil, guard_data.base_id, nil, nil, nil, function()
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:LoadAnimation(0)
  end)
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:OnDeactive()
  self.ContentDetails.OnRichTextClick:Remove(self, self.SetDescText)
  self:RemoveButtonListener(self.BtnRechristen_1)
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:OpenTypeTips()
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {
    petData = {
      base_conf_id = self.pet_base_id
    }
  }, _G.Enum.GoodsType.GT_PET)
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:CloseBtnClick()
  self:LoadAnimation(2)
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:OnAddEventListener()
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:InitInformation(index)
  self.selected_index = index
  local guard_data = self.information.guardData[index]
  self.textPetName:SetText(self.information.tabData[index].name)
  self.textPetLv:SetText(string.format(_G.LuaText.umg_petskilltemple2_1, guard_data.level[1]))
  self.Attr1:InitGridView(guard_data.type)
  self.SkillIcon_1:SetPath(guard_data.skill_icon)
  self.ContentDetails:SetText(guard_data.skill_desc)
  self.skill_desc = guard_data.skill_desc
  self.TextGridView:InitGridView(guard_data.buff_data)
  self.TextGridView:SetItemCount(#guard_data.buff_data)
  if self.firstSelect then
    self.firstSelect = false
  else
    self.previewWorld:SetPreviewByPetBaseId(nil, guard_data.base_id)
    self:PlayAnimation(self.Change)
  end
  self.SkillNameTxt_1:SetText(guard_data.skill_name)
  local initData = {}
  for i = 1, guard_data.inspire_time do
    table.insert(initData, {})
  end
  self.CatchHardLv:InitGridView(initData)
  self.pet_base_id = guard_data.base_id
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:GetSelectedIndex()
  return self.selected_index
end

function UMG_Activity_TerritoryTrial_LevelInformation_C:SetDescText()
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.skill_desc
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

return UMG_Activity_TerritoryTrial_LevelInformation_C
