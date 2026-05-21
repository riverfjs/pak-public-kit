local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local ModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local TipsModuleCmd = _G.TipsModuleCmd
local UMG_HerbologyBadge_ConfirmPanel_C = _G.NRCViewBase:Extend("UMG_HerbologyBadge_ConfirmPanel_C")

function UMG_HerbologyBadge_ConfirmPanel_C:OnConstruct()
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self:SetChildViews(self.UMG_PetRate, self.CommonPetDetails)
  self.CommonPetDetails:SetAddSkillClickedCallback(self, self.OnBtnSkillClicked)
  self:OnAddEventListener()
  self.PetSkill = {}
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnDestruct()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnDisable()
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnActive(data, NeedBtn, PetNum, PetNumLimit, SkillPanel, bHerbologyBadge)
  if NeedBtn then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bHerbologyBadge = bHerbologyBadge or false
  self.SkillPanel = SkillPanel
  if self.SkillPanel then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.bHerbologyBadge then
      local savedSkillId = self.PetSkill[data.PetData.gid]
      local posToIdDic = savedSkillId and {
        [1] = savedSkillId
      } or {}
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, data.PetData.gid, posToIdDic)
    else
      local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, data.PetData.gid, PetUIModuleEnum.PetEquipSkillType.PetBag)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, data.PetData.gid, posToIdDic)
    end
    self.ChangePetSkillsPanel:LoadPanel(nil, data.PetData)
  else
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.In)
  end
  self.data = self.module:GetData("PetUIModuleData")
  self.descText = {}
  self.skillId = nil
  self:SetPetInfo(data.PetData)
  self:RefreshShowLockSkillBtn()
  self.ShadeImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetBtnVisible(NeedBtn)
  if NeedBtn then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Btn_In)
  else
    self:PlayAnimation(self.Btn_Out)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:RefreshInfo()
  if self.petData then
    self:SetPetData(_G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.gid))
    self:SetPetInfo(self.petData)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetPetInfo(PetData)
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
  self.textPetLv:SetText(self.petData.level)
  local BreakThroughStarsList = PetUtils.GetBreakThroughStarsList(self.petData)
  self.CatchHardLv:InitGridView(BreakThroughStarsList)
  local petType = petBaseConf and petBaseConf.unit_type or {}
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
  if self.bHerbologyBadge then
    local savedSkillId = self.PetSkill[self.petData.gid]
    local petEquipSkillList = {}
    if savedSkillId then
      for _, skillData in ipairs(self.petData.skill.skill_data) do
        if skillData.id == savedSkillId then
          petEquipSkillList[1] = skillData
          break
        end
      end
      if 0 == #petEquipSkillList then
        petEquipSkillList[1] = {id = savedSkillId}
      end
    end
    self.CommonPetDetails:InitPetBaseInfo(self.petData, petBaseConf, nil, petEquipSkillList)
  else
    self.CommonPetDetails:InitPetBaseInfo(self.petData, petBaseConf)
  end
  if self.bHerbologyBadge then
    local savedSkillId = self.PetSkill[self.petData.gid]
    self:SetConfirmBtnState(nil ~= savedSkillId)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetPetData(PetData)
  if not self.petData or self.petData.base_conf_id ~= PetData.base_conf_id then
    self:InitFilterAndSort()
  end
  self.petData = PetData
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetWeigthAndStature(PetBaseInfo)
  if not PetBaseInfo.weight or not PetBaseInfo.height then
    return
  end
  local WeightData = PetBaseInfo.weight * 0.001
  local num = string.format("%.2f", WeightData)
  self.TextWeight:SetText(num)
  self.TextStature:SetText(string.format("%.2f", PetBaseInfo.height * 0.01))
end

function UMG_HerbologyBadge_ConfirmPanel_C:GetChangeAttrReqEnum(attribute)
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

function UMG_HerbologyBadge_ConfirmPanel_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:GetPetFeatrueSkillId(baseConf)
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

function UMG_HerbologyBadge_ConfirmPanel_C:InitFeatures(PetbaseConf)
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

function UMG_HerbologyBadge_ConfirmPanel_C:GetPetEquipSkills(petData)
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

function UMG_HerbologyBadge_ConfirmPanel_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_HerbologyBadge_ConfirmPanel_C:TryClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.IsChangeSkill or 1 == self.PanelSwitcher:GetActiveWidgetIndex() then
    self:ExitSkillEditing()
    return
  end
  self:DispatchEvent(ModuleEvent.OnPetSelectPanelCloseButtonClicked)
end

function UMG_HerbologyBadge_ConfirmPanel_C:ExitSkillEditing()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnDisable()
  end
  self:InitFilterAndSort()
  self.NRCSwitcher_46:SetActiveWidgetIndex(0)
  self.PanelSwitcher:SetActiveWidgetIndex(0)
  self.IsChangeSkill = false
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnAddEventListener()
  self.BtnRechristen_1.OnPressed:Add(self, self.OnBtnRechristenPressed)
  self.BtnRechristen_1.OnReleased:Add(self, self.OnBtnRechristenReleased)
  self.BloodPulse.OnPressed:Add(self, self.OnBloodPulsePressed)
  self.BloodPulse.OnReleased:Add(self, self.OnBloodPulseReleased)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.TryClosePanel)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnDetailButtonClicked)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self:AddButtonListener(self.UMG_Btn.btnLevelUp, self.OnBtnSkillClicked)
  self:AddButtonListener(self.changeBtn4.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.changeBtn2.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:AddButtonListener(self.ViewPet_3.btnLevelUp, self.OnShowLockSkillClick)
  self:AddButtonListener(self.RecommendedBtn_1.btnLevelUp, self.OnBtnCultivateClicked)
  self:AddButtonListener(self.ConfirmSelection.btnLevelUp, self.OnConfirmButtonClicked)
  self:RegisterEvent(self, ModuleEvent.OnPetSkillChanged, self.OnPetSkillChanged)
  self:RegisterEvent(self, ModuleEvent.OnUpdatePetCollect, self.UpdateCollect)
  _G.NRCEventCenter:RegisterEvent("UMG_HerbologyBadge_ConfirmPanel_C", self, PetUIModuleEvent.OnPetAssumptionEquipSkillChange, self.OnAssumptionEquipSkillChange)
  if self.ChangePetSkillsPanel then
    self.ChangePetSkillsPanel.OnLoadPanelCallbackDelegate:Add(self, self.OnChangePetSkillPanelCallback)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, ModuleEvent.OnPetSkillChanged, self.OnPetSkillChanged)
  self:UnRegisterEvent(self, ModuleEvent.OnUpdatePetCollect, self.UpdateCollect)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnPetAssumptionEquipSkillChange, self.OnAssumptionEquipSkillChange)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnEquippedSuccess(_changes)
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

function UMG_HerbologyBadge_ConfirmPanel_C:OnChangePetSkillPanelCallback()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel and self.bHerbologyBadge then
    local savedSkillId = self.PetSkill[self.petData.gid]
    ChangePetSkillsPanel:SetHerbologyBadgeMode(true, nil, savedSkillId)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, {})
    ChangePetSkillsPanel:ShowPetSkill()
    self:SetChangeBtnState(false)
  end
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

function UMG_HerbologyBadge_ConfirmPanel_C:OnDetailButtonClicked()
  local titleText = "\232\191\153\230\152\175\230\160\135\233\162\152"
  local contentStr = "\232\191\153\230\152\175\229\134\133\229\174\185"
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_HerbologyBadge_ConfirmPanel_C:UpdateCollect(partner_mark)
  self.petData.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_HerbologyBadge_ConfirmPanel_C:UpdateChangePetSkills()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:RefreshUI(self.petData)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnCollectBtn()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.petData.gid, self.petData.partner_mark)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBtnRechristenPressed()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Press)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBtnRechristenReleased()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Up)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBloodPulsePressed()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Press)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBloodPulseReleased()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Up)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OpenPetTips()
  local petData = self.petData
  local uidata = {petData = petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uidata, _G.Enum.GoodsType.GT_PET)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnFeatureSkillBtnClick()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPeculiarityTips, self.petData)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnNRCButton_112Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_HerbologyBadge_ConfirmPanel_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpendblockerTips, TipEnum.OpenPetTipsType.PetWareHouse, self.petData)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnTalentBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_HerbologyBadge_ConfirmPanel_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenTipsStrongPoint, self.petData)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBloodPulse()
  local petData = self.petData
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetBloodPulse, petData, TipEnum.OpenPetTipsType.PetWareHouse)
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetChangeBtnState(_IsHighlight)
  local btns = {
    self.changeBtn4,
    self.changeBtn2
  }
  for _, btn in ipairs(btns) do
    if btn then
      if _IsHighlight then
        btn.HideAnim = false
        btn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
      else
        btn.HideAnim = true
        btn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
      end
    end
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:SetConfirmBtnState(_IsHighlight)
  local btn = self.ConfirmSelection
  if btn then
    if _IsHighlight then
      btn.HideAnim = false
      btn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
    else
      btn.HideAnim = true
      btn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
    end
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:SaveSkillChange()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if self.bHerbologyBadge and ChangePetSkillsPanel then
    local selectedSkillId = ChangePetSkillsPanel:GetHerbologyBadgeSelectedSkillId()
    if not selectedSkillId then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_4)
      return
    end
  end
  if ChangePetSkillsPanel then
    if self.bHerbologyBadge then
      local selectedSkillId = ChangePetSkillsPanel:GetHerbologyBadgeSelectedSkillId()
      self.PetSkill[self.petData.gid] = selectedSkillId
      local petEquipSkillList = {}
      if selectedSkillId then
        for _, skillData in ipairs(self.petData.skill.skill_data) do
          if skillData.id == selectedSkillId then
            petEquipSkillList[1] = skillData
            break
          end
        end
      end
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
      self.CommonPetDetails:InitPetBaseInfo(self.petData, petBaseConf, nil, petEquipSkillList)
      self:SetConfirmBtnState(nil ~= selectedSkillId)
      ChangePetSkillsPanel:OnDisable()
    else
      ChangePetSkillsPanel:OnChangeButtonClick()
      ChangePetSkillsPanel:OnDisable()
    end
  end
  self:InitFilterAndSort()
  self.NRCSwitcher_46:SetActiveWidgetIndex(0)
  self.PanelSwitcher:SetActiveWidgetIndex(0)
  self.IsChangeSkill = false
end

function UMG_HerbologyBadge_ConfirmPanel_C:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:ClearSkillListSelection()
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnSelectSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OpenSkillFilteringPanelByCurShowSkillList()
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnSortSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRuleId, self.skillSortReverse)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnPetSkillFilterRuleChange(filterRule)
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

function UMG_HerbologyBadge_ConfirmPanel_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRuleId = id
  self.skillSortReverse = skillSortReverse
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnPetSkillSortRuleChange(id, skillSortReverse)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnShowLockSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_HerbologyBadge_ConfirmPanel_C:OnShowLockSkillClick")
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    self.showLockSkill = not self.showLockSkill
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.showLockSkill)
    self:RefreshShowLockSkillBtn()
    ChangePetSkillsPanel:OnShowLockSkillChange(self.showLockSkill)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:RefreshShowLockSkillBtn()
  local path
  if self.showLockSkill then
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockVisible_png.img_UnlockVisible_png'"
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockInvisible_png.img_UnlockInvisible_png'"
  end
  self.ViewPet_3:SetPath(path, path, path)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBtnSkillClicked()
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self:RefreshShowLockSkillBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  self.IsChangeSkill = true
  if self.bHerbologyBadge then
    local posToIdDic = {}
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, posToIdDic)
  else
    local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid, PetUIModuleEnum.PetEquipSkillType.PetBag)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, posToIdDic)
  end
  if ChangePetSkillsPanel then
    if self.bHerbologyBadge then
      local savedSkillId = self.PetSkill[self.petData.gid]
      ChangePetSkillsPanel:SetHerbologyBadgeMode(true, nil, savedSkillId)
    end
    ChangePetSkillsPanel:OnEnable(self.petData)
    self.NRCSwitcher_46:SetActiveWidgetIndex(2)
    self.PanelSwitcher:SetActiveWidgetIndex(1)
  else
    self.ChangePetSkillsPanel:LoadPanel(nil, self.petData)
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self:ShowSkillBtnState()
  if self.bHerbologyBadge then
    self:SetChangeBtnState(false)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnBtnCultivateClicked()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.HerbologyBadge)
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  _G.NRCModuleManager:DoCmd(_G.CampingModuleCmd.SetIsCultivatePet, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPanelPetData, self.petData, 1, false)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetOpenPanelPetDataRedPoint)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1014, "UMG_LobbyMain_C:OnBtnPetHeadClick")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    bHideSkill = true,
    bUseOpenPetData = true
  })
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnConfirmButtonClicked()
  if self.bHerbologyBadge and self.petData then
    local savedSkillId = self.PetSkill[self.petData.gid]
    if not savedSkillId then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_4)
      return
    end
  end
  local TrialPetInfo = self.module.Data.TrialPetInfo
  TrialPetInfo.pet_gid = self.petData.gid
  table.clear(TrialPetInfo.skills)
  table.insert(TrialPetInfo.skills, self.PetSkill[TrialPetInfo.pet_gid])
  local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.AffirmPet)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnPetSkillChanged(petGid, posToIdDic)
  if not self.PetSkill then
    self.PetSkill = {}
  end
  self.PetSkill[petGid] = posToIdDic[1]
  if self.petData and self.petData.gid == petGid and self.bHerbologyBadge then
    local selectedSkillId = self.PetSkill[petGid]
    local petEquipSkillList = {}
    if selectedSkillId and self.petData.skill then
      for _, skillData in ipairs(self.petData.skill.skill_data) do
        if skillData.id == selectedSkillId then
          petEquipSkillList[1] = skillData
          break
        end
      end
    end
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
    self.CommonPetDetails:InitPetBaseInfo(self.petData, petBaseConf, nil, petEquipSkillList)
    self:SetConfirmBtnState(nil ~= selectedSkillId)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnAssumptionEquipSkillChange(posToIdDic)
  if self.bHerbologyBadge then
    local hasSkill = posToIdDic and nil ~= posToIdDic[1]
    self:SetChangeBtnState(hasSkill)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:ShowSkillBtnState()
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnNatureBtn()
  local petData = self.petData
  local uidata = {petData = petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpendblockerTips, uidata, TipEnum.OpenPetTipsType.PetWareHouse)
end

function UMG_HerbologyBadge_ConfirmPanel_C:PetSkillChangeToBaseInfo(PetInfo)
  if self.petData and PetInfo.gid ~= self.petData.gid and (self.IsChangeSkill or 1 == self.PanelSwitcher:GetActiveWidgetIndex()) then
    self.SkillPanel = false
    self.NRCSwitcher_46:SetActiveWidgetIndex(0)
    self.PanelSwitcher:SetActiveWidgetIndex(0)
    self.IsChangeSkill = false
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:OnDisable()
    end
    self:InitFilterAndSort()
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.data.bPetWarehouseTipBtnEnable then
    if 0 == GlobalConfig.OpenMainPanelFromDebugBtn then
      _G.NRCModuleManager:DoCmd(CampingModuleCmd.OpenPetWarehouseTips, false)
    end
    local panel = self.module:GetPanel("PetWarehousePanelMain")
    if panel then
      panel:PlayAnimation(panel.House_open)
    end
    self:PlayAnimation(self.Out)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  elseif Anim == self.Btn_Out then
    self.UMG_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:InitFilterAndSort()
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

function UMG_HerbologyBadge_ConfirmPanel_C:PetWarehouseReadyToClose()
  self.ShadeImage:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnGiftBtnClick()
  if self.petData and self.petData.gid then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendPetToFriend, self.petData.gid, true)
  end
end

function UMG_HerbologyBadge_ConfirmPanel_C:OnPetDataUpdate(newPetData)
  if not newPetData then
    return
  end
  if self.petData and self.petData.gid == newPetData.gid then
    self:RefreshInfo()
  end
end

return UMG_HerbologyBadge_ConfirmPanel_C
