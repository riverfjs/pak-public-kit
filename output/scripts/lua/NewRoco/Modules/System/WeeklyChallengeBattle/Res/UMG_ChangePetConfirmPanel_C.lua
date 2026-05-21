local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local ModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_ChangePetConfirmPanel_C = _G.NRCPanelBase:Extend("UMG_ChangePetConfirmPanel_C")

function UMG_ChangePetConfirmPanel_C:OnConstruct()
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self:SetChildViews(self.UMG_PetRate, self.CommonPetDetails)
end

function UMG_ChangePetConfirmPanel_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, nil)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnDisable()
  end
end

function UMG_ChangePetConfirmPanel_C:OnActive(data, NeedBtn, SkillPanel, bDirectToSkill)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.WeeklyChallengeBattle)
  self.NeedBtn = NeedBtn
  if NeedBtn then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bDirectToSkill = bDirectToSkill
  self.SkillPanel = SkillPanel
  self.CanvasPanel_UnlockPrompt:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if self.SkillPanel then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, data.PetData.gid)
    local posToIdDic = {}
    if balancedPetData and balancedPetData.skill and balancedPetData.skill.skill_data then
      for _, skillData in ipairs(balancedPetData.skill.skill_data) do
        if skillData.is_equipped and skillData.pos and skillData.pos > 0 then
          posToIdDic[skillData.pos] = skillData.id
        end
      end
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, data.PetData.gid, posToIdDic)
    self.bPendingWeeklyChallengeBattleFlag = true
    self.ChangePetSkillsPanel:LoadPanel(nil, balancedPetData or data.PetData)
  else
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.In)
    _G.NRCAudioManager:PlaySound2DAuto(1069, "UMG_ChangePetConfirmPanel_C:OnActive")
  end
  self.NRCText_37:SetText(_G.LuaText.weekly_challenge_text_13)
  self.data = self.module:GetData("PetUIModuleData")
  self.descText = {}
  self.skillId = nil
  if self.RecommendedBtn then
    self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local bIsNeedBalance = _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  if self.CanvasPanel_94 then
    if bIsNeedBalance then
      self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasPanel_UnlockPrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CanvasPanel_UnlockPrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:SetPetInfo(data.PetData)
  self:InitRewardButton()
  self:OnAddEventListener()
  self:RefreshShowLockSkillBtn()
  local formationPanel = self.module:GetPanel("TeamEdit")
  if formationPanel and formationPanel.ConsumePendingChangeSelectPetData then
    local pendingPetData = formationPanel:ConsumePendingChangeSelectPetData()
    if pendingPetData then
      self:OnFormationPanelChangeSelectPet(pendingPetData)
    end
  end
end

function UMG_ChangePetConfirmPanel_C:InitRewardButton()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    self.TextClaimProgress_1:SetText("0/12")
    return
  end
  local weeklyChallengeData = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  local totalStarNum = MagicManualUtils.GetWeeklyChallengeStarNum(weeklyChallengeData)
  local finishedStarNum = weeklyChallengeData.challenge_info.highest_cheer_point or 0
  self.TextClaimProgress_1:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
  self.RedDot_1:SetupKey(371, self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId())
end

function UMG_ChangePetConfirmPanel_C:SetBtnVisible(NeedBtn)
  if NeedBtn then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Btn_In)
  else
    self:PlayAnimation(self.Btn_Out)
  end
end

function UMG_ChangePetConfirmPanel_C:RefreshInfo()
  if self.petData then
    local petData
    petData = petData or _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.petData.gid)
    if petData then
      self:SetPetData(petData)
    else
      self:SetPetData(_G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.gid))
    end
    self:SetPetInfo(self.petData)
  end
end

function UMG_ChangePetConfirmPanel_C:SetPetInfo(PetData)
  if not PetData then
    return
  end
  self.IconList:ScrollToStart()
  if PetData.PetBaseInfo then
    if self.petData and self.petData.gid == PetData.PetBaseInfo.gid then
    else
      self:PlayAnimation(self.Change)
    end
    self:SetPetData(PetData.PetBaseInfo)
  else
    if self.petData and self.petData.gid == PetData.gid then
    else
      self:PlayAnimation(self.Change)
    end
    self:SetPetData(PetData)
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  local commonAttrData = {}
  local commonAttrData1 = {}
  self:UpdateChangePetSkills()
  self.textPetName:SetText(self.petData.name)
  self:updatePetGender(self.petData.gender)
  self.UMG_PetRate:SetText(self.petData, TipEnum.OpenPetTipsType.PetWareHouse)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  local _, level, grow = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  if bIsNeedBalance then
    self.textPetLv:SetText(level or self.petData.level or 0)
  else
    self.textPetLv:SetText(self.petData.level or 0)
  end
  local originalPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.gid)
  local BreakThroughStarsList = PetUtils.GetBreakThroughStarsList(originalPetData)
  local starInitList = {}
  for i = 1, 5 do
    local item = BreakThroughStarsList[i]
    local isShow = 0
    if i <= grow then
      isShow = 1
    else
      isShow = -1
    end
    table.insert(starInitList, {
      IsShow = isShow,
      bIsReset = item and 1 ~= item.IsShow,
      i
    })
  end
  self.CatchHardLv:InitGridView(starInitList)
  local petType = petBaseConf.unit_type
  for i = 1, 2 do
    if i <= #petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  if self.Attr1 then
    self.Attr1:InitGridView(commonAttrData1)
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  self.UMG_CollectBtn:UpdateInfo(self.petData.partner_mark, true)
  table.insert(commonAttrData, {
    Name = PetBloodConf.blood_name,
    Path = PetBloodConf.icon
  })
  if self.Attr then
    self.Attr:InitGridView(commonAttrData)
  end
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
  self.CommonPetDetails:SetFromWeeklyChallengeBattle(true)
  local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.petData.gid)
  self.CommonPetDetails:InitPetBaseInfo(balancedPetData or self.petData, petBaseConf)
end

function UMG_ChangePetConfirmPanel_C:SetPetData(PetData)
  if not self.petData or self.petData.base_conf_id ~= PetData.base_conf_id then
    self:InitFilterAndSort()
  end
  self.petData = PetData
end

function UMG_ChangePetConfirmPanel_C:SetWeigthAndStature(PetBaseInfo)
  if not PetBaseInfo.weight or not PetBaseInfo.height then
    return
  end
  local WeightData = PetBaseInfo.weight * 0.001
  local num = string.format("%.2f", WeightData)
  self.TextWeight:SetText(num)
  self.TextStature:SetText(string.format("%.2f", PetBaseInfo.height * 0.01))
end

function UMG_ChangePetConfirmPanel_C:GetChangeAttrReqEnum(attribute)
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

function UMG_ChangePetConfirmPanel_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ChangePetConfirmPanel_C:GetPetFeatrueSkillId(baseConf)
  local skillId = baseConf.pet_feature
  if 0 ~= skillId then
    return skillId, false
  else
    local evolution_pet_id = baseConf.evolution_pet_id[1]
    if nil == evolution_pet_id then
      return
    end
    local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
    if evolution_pet_id then
      skillId = evoPetbaseCfg.pet_feature
      if 0 ~= skillId then
        return skillId, true
      end
    end
  end
  return 0
end

function UMG_ChangePetConfirmPanel_C:InitFeatures(PetbaseConf)
  local skillId, lock = PetUtils.GetPetFeatrueSkillId(PetbaseConf)
  if lock then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif skillId and 0 ~= skillId then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg then
      if skillCfg.icon then
        self.SkillIcon_1:SetPath(skillCfg.icon)
      end
      self.SkillNameTxt_1:SetText(skillCfg.name)
    else
      self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ChangePetConfirmPanel_C:GetPetEquipSkills(petData)
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

function UMG_ChangePetConfirmPanel_C:OnDeactive()
end

function UMG_ChangePetConfirmPanel_C:OnAddEventListener()
  self.BtnRechristen_1.OnPressed:Add(self, self.OnBtnRechristenPressed)
  self.BtnRechristen_1.OnReleased:Add(self, self.OnBtnRechristenReleased)
  self.BloodPulse.OnPressed:Add(self, self.OnBloodPulsePressed)
  self.BloodPulse.OnReleased:Add(self, self.OnBloodPulseReleased)
  self:AddButtonListener(self.Btn_Details, self.ClosePanel)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.CloseAndCloseFormationPanel)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self:AddButtonListener(self.UMG_Btn.btnLevelUp, self.OnBtnSkillClicked)
  self:AddButtonListener(self.changeBtn4.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.changeBtn2.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:AddButtonListener(self.ViewPet_3.btnLevelUp, self.OnShowLockSkillClick)
  self:AddButtonListener(self.Exchange.btnLevelUp, self.OpenExChangeMainPetPanelBtnClick)
  self:AddButtonListener(self.RecommendedBtn.btnLevelUp, self.OnRecommendedBtnClick)
  self:AddButtonListener(self.RecommendedBtn_1.btnLevelUp, self.OnBtnCultivateClicked)
  self:AddButtonListener(self.RewardBtn_1, self.OnRewardButtonClick)
  self:AddButtonListener(self.ResetBtn, self.OnResetButtonClick)
  self:AddButtonListener(self.ParticularsBtn.btnLevelUp, self.OnDetailButtonClick)
  self:RegisterEvent(self, ModuleEvent.EnterSwapMode, self.OnEnterExchangeMode)
  self:RegisterEvent(self, ModuleEvent.QuitSwapMode, self.OnQuitExchangeMode)
  self:RegisterEvent(self, ModuleEvent.ChangeSelectPet, self.OnFormationPanelChangeSelectPet)
  self:RegisterEvent(self, ModuleEvent.UpdatePetCollect, self.UpdateCollect)
  self:RegisterEvent(self, ModuleEvent.UpdateChangePetSkillsPanel, self.UpdateChangePetSkills)
  self:RegisterEvent(self, ModuleEvent.OnPetSkillChanged, self.OnWeeklyChallengePetSkillChanged)
  if self.ChangePetSkillsPanel then
    self.ChangePetSkillsPanel.OnLoadPanelCallbackDelegate:Add(self, self.OnChangePetSkillPanelCallback)
  end
end

function UMG_ChangePetConfirmPanel_C:OnRewardButtonClick()
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenRewardClaimPopupPanel, rewardList, true)
end

function UMG_ChangePetConfirmPanel_C:OnResetButtonClick()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    return
  end
  local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    return
  end
  local eventConf = _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  if not eventConf then
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(eventConf.challenge_id[1])
  if not challengeConf then
    return
  end
  local _, level, grow, workHard = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenResetNotification, bIsNeedBalance, grow, level, workHard)
end

function UMG_ChangePetConfirmPanel_C:OnDetailButtonClick()
  local titleText = _G.LuaText.weekly_challenge_text_10
  local contentStr = _G.LuaText.weekly_challenge_text_9
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_ChangePetConfirmPanel_C:OnEquippedSuccess(_changes)
  local curPetData = self.petData
  if not curPetData or not _changes then
    return
  end
  for i, changItem in ipairs(_changes) do
    if changItem.type == _G.ProtoEnum.GoodsType.GT_PET then
      local petData = changItem.pet_data
      if curPetData.gid == petData.gid then
        self:SetPetData(petData)
        self:SetPetInfo(petData)
      end
    end
  end
end

function UMG_ChangePetConfirmPanel_C:OnChangePetSkillPanelCallback()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel.bFromWeeklyChallengeBattle = true
    ChangePetSkillsPanel:ShowPetSkill()
  end
  self.bPendingWeeklyChallengeBattleFlag = nil
  if self.SkillPanel then
    self.SkillPanel = false
    self.NRCSwitcher_46:SetActiveWidgetIndex(2)
    self.PanelSwitcher:SetActiveWidgetIndex(1)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
  else
    self.NRCSwitcher_46:SetActiveWidgetIndex(2)
    self.PanelSwitcher:SetActiveWidgetIndex(1)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_ChangePetConfirmPanel_C:UpdateCollect(partner_mark)
  self.petData.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_ChangePetConfirmPanel_C:UpdateChangePetSkills()
  if 1 == self.PanelSwitcher:GetActiveWidgetIndex() then
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:RefreshUI(self.petData)
    end
  end
end

function UMG_ChangePetConfirmPanel_C:OnWeeklyChallengePetSkillChanged()
  if self.petData then
    local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.petData.gid)
    if balancedPetData and balancedPetData.skill then
      self.petData.skill = balancedPetData.skill
    end
  end
  self:UpdateChangePetSkills()
end

function UMG_ChangePetConfirmPanel_C:OnCollectBtn()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.petData.gid, self.petData.partner_mark)
end

function UMG_ChangePetConfirmPanel_C:OnBtnRechristenPressed()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Press)
end

function UMG_ChangePetConfirmPanel_C:OnBtnRechristenReleased()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Up)
end

function UMG_ChangePetConfirmPanel_C:OnBloodPulsePressed()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Press)
end

function UMG_ChangePetConfirmPanel_C:OnBloodPulseReleased()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Up)
end

function UMG_ChangePetConfirmPanel_C:OpenPetTips()
  local petData = self.petData
  local uidata = {petData = petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uidata, _G.Enum.GoodsType.GT_PET)
end

function UMG_ChangePetConfirmPanel_C:OnFeatureSkillBtnClick()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPeculiarityTips, self.petData)
end

function UMG_ChangePetConfirmPanel_C:OnNRCButton_112Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_ChangePetConfirmPanel_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpendblockerTips, TipEnum.OpenPetTipsType.PetWareHouse, self.petData)
end

function UMG_ChangePetConfirmPanel_C:OnTalentBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_ChangePetConfirmPanel_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenTipsStrongPoint, self.petData)
end

function UMG_ChangePetConfirmPanel_C:OnBloodPulse()
  local petData = self.petData
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetBloodPulse, petData, TipEnum.OpenPetTipsType.PetWareHouse)
end

function UMG_ChangePetConfirmPanel_C:SaveSkillChange()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnChangeButtonClick()
    ChangePetSkillsPanel:OnDisable()
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseBagSKillTips)
  if self.bDirectToSkill then
    self:ClosePanel()
  else
    self:InitFilterAndSort()
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    self.IsChangeSkill = false
  end
end

function UMG_ChangePetConfirmPanel_C:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:ClearSkillListSelection()
  end
end

function UMG_ChangePetConfirmPanel_C:OnSelectSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OpenSkillFilteringPanelByCurShowSkillList()
  end
end

function UMG_ChangePetConfirmPanel_C:OnSortSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRuleId, self.skillSortReverse)
end

function UMG_ChangePetConfirmPanel_C:OnPetSkillFilterRuleChange(filterRule)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    local path
    if filterRule then
      path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
    else
      path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
    end
    self.ViewPet:SetPath(path, path, path)
    ChangePetSkillsPanel:OnPetSkillFilterRuleChange(filterRule)
  end
end

function UMG_ChangePetConfirmPanel_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRuleId = id
  self.skillSortReverse = skillSortReverse
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnPetSkillSortRuleChange(id, skillSortReverse)
  end
end

function UMG_ChangePetConfirmPanel_C:OnShowLockSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    self.showLockSkill = not self.showLockSkill
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.showLockSkill)
    self:RefreshShowLockSkillBtn()
    ChangePetSkillsPanel:OnShowLockSkillChange(self.showLockSkill)
  end
end

function UMG_ChangePetConfirmPanel_C:RefreshShowLockSkillBtn()
  local path, text
  if self.showLockSkill then
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockVisible_png.img_UnlockVisible_png'"
    text = LuaText.skill_sort_text_2
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockInvisible_png.img_UnlockInvisible_png'"
    text = LuaText.skill_sort_text_1
  end
  self.ViewPet_3:SetPath(path, path, path)
  self.ViewPet_3:SetText(text)
end

function UMG_ChangePetConfirmPanel_C:OnBtnSkillClicked()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.WeeklyChallengeBattle)
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  self.IsChangeSkill = true
  local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.petData.gid)
  local posToIdDic = {}
  if balancedPetData and balancedPetData.skill and balancedPetData.skill.skill_data then
    for _, skillData in ipairs(balancedPetData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos and skillData.pos > 0 then
        posToIdDic[skillData.pos] = skillData.id
      end
    end
  else
    posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid, PetUIModuleEnum.PetEquipSkillType.PetBag)
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, posToIdDic)
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:SetFromWeeklyChallengeBattle(true)
    ChangePetSkillsPanel:OnEnable(self.petData)
    self.NRCSwitcher_46:SetActiveWidgetIndex(2)
    self.PanelSwitcher:SetActiveWidgetIndex(1)
  else
    self.ChangePetSkillsPanel:LoadPanel(nil, self.petData)
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self:ShowSkillBtnState()
end

function UMG_ChangePetConfirmPanel_C:OnBtnCultivateClicked()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.WeeklyChallengeBattle)
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  _G.NRCModuleManager:DoCmd(CampingModuleCmd.SetIsCultivatePet, true)
  local originalPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.gid)
  local petData = table.deepCopy(originalPetData, false)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 1, false)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetDataRedPoint)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1014, "UMG_LobbyMain_C:OnBtnPetHeadClick")
  NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    bHideSkill = true,
    bUseOpenPetData = true
  })
end

function UMG_ChangePetConfirmPanel_C:ShowSkillBtnState()
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_ChangePetConfirmPanel_C:OpenExChangeMainPetPanelBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  local bIsSwapModeOpened = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OnDetailExchangeButtonClick)
  if bIsSwapModeOpened then
    self.Exchange.Title_1:SetText(_G.LuaText.weekly_challenge_text_5)
  else
    self.Exchange.Title_1:SetText(_G.LuaText.weekly_challenge_text_4)
  end
end

function UMG_ChangePetConfirmPanel_C:OnEnterExchangeMode()
  self.Exchange.Title_1:SetText(_G.LuaText.weekly_challenge_text_5)
end

function UMG_ChangePetConfirmPanel_C:OnQuitExchangeMode()
  self.Exchange.Title_1:SetText(_G.LuaText.weekly_challenge_text_4)
end

function UMG_ChangePetConfirmPanel_C:OnFormationPanelChangeSelectPet(petData)
  if self.NeedBtn then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.SkillPanel = SkillPanel
  if self.SkillPanel then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChangePetSkillsPanel:LoadPanel(nil, data.PetData)
  else
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:OnDisable()
    end
  end
  self.data = self.module:GetData("PetUIModuleData")
  self.descText = {}
  self.skillId = nil
  local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, petData.gid)
  self:SetPetInfo(balancedPetData or petData)
  self:RefreshShowLockSkillBtn()
end

function UMG_ChangePetConfirmPanel_C:OnRecommendedBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_ChangePetConfirmPanel_C:OnRecommendedBtnClick")
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDistrictMapGuide, self.petData)
end

function UMG_ChangePetConfirmPanel_C:OnRecommendedBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_ChangePetConfirmPanel_C:OnRecommendedBtnClick")
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDistrictMapGuide, self.petData)
end

function UMG_ChangePetConfirmPanel_C:OnNatureBtn()
  local petData = self.petData
  local uidata = {petData = petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpendblockerTips, uidata, TipEnum.OpenPetTipsType.PetWareHouse)
end

function UMG_ChangePetConfirmPanel_C:ClosePanel(bFromCloseBtn)
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.IsChangeSkill then
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    self.IsChangeSkill = false
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:OnDisable()
    end
    self:InitFilterAndSort()
    return
  end
  if self.data.bPetWarehouseTipBtnEnable then
    if 0 == GlobalConfig.OpenMainPanelFromDebugBtn then
      _G.NRCModuleManager:DoCmd(CampingModuleCmd.OpenPetWarehouseTips, false)
    end
    local panel = self.module:GetPanel("PetWarehousePanelMain")
    if panel then
      panel:PlayAnimation(panel.House_open)
    end
  end
  if bFromCloseBtn then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseFormationPanel)
  end
  self:PlayAnimation(self.Out)
  _G.NRCAudioManager:PlaySound2DAuto(1070, "UMG_ChangePetConfirmPanel_C:ClosePanel")
end

function UMG_ChangePetConfirmPanel_C:CloseAndCloseFormationPanel()
  self:ClosePanel(true)
end

function UMG_ChangePetConfirmPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DispatchEvent(ModuleEvent.OnChangePetConfirmPanelClose)
    self:DoClose()
  elseif Anim == self.Btn_Out then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ChangePetConfirmPanel_C:InitFilterAndSort()
  self.sortRuleId = 1
  self.skillSortReverse = false
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:InitFilterAndSort()
  end
  self:RefreshShowLockSkillBtn()
  local path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  self.ViewPet:SetPath(path, path, path)
end

function UMG_ChangePetConfirmPanel_C:OnPetDataUpdate(newPetData)
  self:RefreshInfo()
end

return UMG_ChangePetConfirmPanel_C
