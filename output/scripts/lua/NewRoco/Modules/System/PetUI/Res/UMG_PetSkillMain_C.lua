local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local BattleRogueModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local UMG_PetSkillMain_C = _G.NRCViewBase:Extend("UMG_PetSkillMain_C")

function UMG_PetSkillMain_C:OnConstruct()
  self.uiData = {}
  self:SetViewMode(0)
  self:ChangeState(self.uiData.mode)
  self.descText = ""
  self.petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  self.data = self.module:GetData("PetUIModuleData")
  self:OnAddEventListener()
  self:InitUI()
  self.backBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petMaxLevelLimit = (_G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit") or {}).num or 60
end

function UMG_PetSkillMain_C:OnDestruct()
  self:CancelDelay()
  self.ItemList:Release()
  table.clear(self.uiData)
  self:OnRemoveEventListener()
end

function UMG_PetSkillMain_C:OnEnable()
  Log.Debug("UMG_PetSkillMain_C:OnEnable")
end

function UMG_PetSkillMain_C:OnDisable()
  Log.Debug("UMG_PetSkillMain_C:OnDisable")
end

function UMG_PetSkillMain_C:InitUI()
  self.changeBtn4:SetBtnText(LuaText.umg_petskillmain_1)
  self.changeBtn2:SetBtnText(LuaText.umg_petskillmain_1)
  if self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PetAltar then
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:UpdateChangeBtn2Visibility()
  if self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.WeeklyChallengeBattle then
    self.CanvasPanel_UnlockPrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.HerbologyBadge then
    self.SelectionPrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetSkillMain_C:RefreshUI(bIsOpenByBag)
  self.DetailsSwitcher:SetActiveWidgetIndex(0)
  self:ResetDescText()
  if self.uiData == nil then
    Log.Debug("UMG_PetSkillMain_C:RefreshUI uiData is nil")
    return
  end
  if nil == self.uiData.petData then
    Log.Debug("UMG_PetSkillMain_C:RefreshUI petData is nil")
    return
  end
  local gid = self.uiData.petData.gid
  local IsTrialPet = self.uiData.petData.is_trial_pet
  if not IsTrialPet then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  local bUseOpenPetData = false
  if self.module:HasPanel("PetInfoMain") then
    local petInfoMain = self.module:GetPanel("PetInfoMain")
    if petInfoMain and petInfoMain.bUseOpenPetData then
      bUseOpenPetData = true
    end
  end
  if not friendInfo and not bUseOpenPetData then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
    if petData.base_conf_id ~= self.uiData.petData.base_conf_id then
      self:InitFilterAndSort()
    end
    self.uiData.petData = petData
  elseif friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.uiData.petData = friendInfo.petData
  end
  self:ShowPetFeature()
  self:ShowPetSkill()
  self:ShowSkillBtnState()
  self:ShowBgStyle()
  local openPetData, index, bIsRevertMainPanel, OpenTip, OpenSkillInfo = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if bIsOpenByBag and OpenSkillInfo then
    local AllSkillList = {}
    for i = 1, self.ItemList:GetItemCount() do
      if self.ItemList:GetItemByIndex(i) and self.ItemList:GetItemByIndex(i).skillConfig then
        table.insert(AllSkillList, self.ItemList:GetItemByIndex(i).skillConfig)
      end
    end
    for index, skillItem in ipairs(AllSkillList) do
      if skillItem.id == OpenSkillInfo.id then
        self.ItemList:SelectItemByIndex(index)
        self.ItemList:ScrollToStart()
      end
    end
  end
  self:UpdateChangeBtn2Visibility()
end

function UMG_PetSkillMain_C:SetEmpty()
  self.DetailsSwitcher:SetActiveWidgetIndex(1)
  self.NRCText_Empty:SetText(LuaText.Select_Null_Pet_Detail)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClosePetSKillTips)
end

function UMG_PetSkillMain_C:UpdateChangeBtn2Visibility()
  local Visibility = true
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    Visibility = false
  end
  if self.BtnSwitcher and 0 == self.BtnSwitcher:GetActiveWidgetIndex() and self.uiData and self.uiData.petData and self.uiData.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    Visibility = false
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    Visibility = false
  end
  if self.changeBtn2 then
    self.changeBtn2:SetVisibility(Visibility and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillMain_C:GetPetFeatrueSkillId()
  local skillId = self.uiData.petBaseConf.pet_feature
  if 0 ~= skillId then
    return skillId, false
  else
    local evolution_pet_id = self.uiData.petBaseConf.evolution_pet_id[1]
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

function UMG_PetSkillMain_C:ShowPetFeature()
  local skillId, lock = self:GetPetFeatrueSkillId()
  if 0 ~= skillId then
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg then
      if skillCfg.icon then
        self.SkillIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.SkillIcon:SetPath(skillCfg.icon)
      else
        self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      local skillDesc = skillCfg.desc
      self.descText = skillDesc
      self.NRCTextDes:SetText(skillDesc)
      self.SkillNameTxt:SetText(skillCfg.name)
      if lock then
        self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.skilLockTxt_2:SetText(LuaText.umg_skill_lock_2)
      else
        self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillMain_C:ShowDescRightPanel(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_PetSkillMain_C:SetDescText(descText)
  table.insert(self.descText, descText)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetDescTextTable, self.descText)
end

function UMG_PetSkillMain_C:ClearDescText()
  table.clear(self.descText)
end

function UMG_PetSkillMain_C:ShowBtnClosePanel()
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetSkillMain_C:HideBtnClosePanel()
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetSkillMain_C:RefreshSkillListByAssumptionChange()
  if 1 == self.uiData.mode then
    self:ShowPetSkill()
  end
end

function UMG_PetSkillMain_C:OnNewPetBagReleaseLifeModeChanged(IsReleaseLifeMode)
  self:UpdateChangeBtn2Visibility()
end

function UMG_PetSkillMain_C:ShowPetSkill()
  local posToIdDic = {}
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.uiData.petData = friendInfo.petData
    posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, friendInfo.petData.gid, nil, friendInfo.petData)
  else
    posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.uiData.petData.gid)
  end
  local IdToPosDic = {}
  for pos, skillId in pairs(posToIdDic) do
    IdToPosDic[skillId] = pos
  end
  self.cacheCurEquipSkillDic = IdToPosDic or {}
  local skills = self:GetAllSkills(self.uiData.petData)
  if self.sortRule then
    self:SkillRuleSortHandle(skills)
  end
  self.uiData.petData.skill.skillData = skills
  if #skills < 8 then
    for i = #skills + 1, 8 do
      skills[i] = {
        mode = i == #skills + 1 and -1 or nil
      }
    end
  elseif math.floor(#skills / 2) ~= #skills / 2 then
    skills[#skills + 1] = {
      mode = -1 or nil
    }
  end
  if 1 == self.uiData.mode then
    for i = #skills, 1, -1 do
      if -1 == skills[i].mode then
        table.remove(skills, i)
      end
    end
    for i = #skills, 1, -1 do
      if skills[i] then
      else
        table.remove(skills, i)
      end
    end
    if #skills < 10 then
      for i = #skills + 1, 10 do
        skills[i] = {
          mode = i == #skills + 1 and -1 or nil
        }
      end
    elseif math.floor(#skills / 2) ~= #skills / 2 then
      skills[#skills + 1] = {
        mode = -1 or nil
      }
    end
  end
  local nightmareSkillList = {}
  if #skills > 4 and self.uiData.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    for i = 1, 4 do
      skills[i].isNightmare = true
      table.insert(nightmareSkillList, skills[i])
    end
    self.ItemList:InitList(nightmareSkillList)
    self.curSkillList = nightmareSkillList
    return
  end
  self.ItemList:InitList(skills)
  self.curSkillList = skills
  if 1 == self.uiData.mode then
    local count = 0
    if posToIdDic then
      for i = 1, 4 do
        if posToIdDic[i] then
          count = count + 1
        end
      end
    end
    self:SetChangeBtnState(count > 0)
  end
  self:CheckCloseSkillTips()
end

function UMG_PetSkillMain_C:CheckCloseSkillTips()
  local curSkillTipsId = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSKillTipsCurShowSkillId)
  local closeSkillTips = curSkillTipsId > 0
  local index = -1
  if closeSkillTips then
    for i, v in ipairs(self.curSkillList) do
      if v.skillData and v.skillData.id == curSkillTipsId then
        closeSkillTips = false
        index = i
        break
      end
    end
  end
  if closeSkillTips then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetSkillTipsPanel)
  elseif index > 0 then
    local Item = self.ItemList:GetItemByIndex(index - 1)
    if Item and Item.isEquipSelected == true and self.uiData and 1 == self.uiData.mode then
      return
    end
    self.ItemList:SelectItemByIndex(index - 1)
    self.ItemList:ScrollToIndex(index - 1, false)
  end
end

function UMG_PetSkillMain_C:OnSkillItemSelected(item, rawIndex, userClick)
  if userClick then
    item:OnItemSelectedByClick()
  end
end

function UMG_PetSkillMain_C:OnErasePetSkillRedPoint()
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 133, {
    tostring(self.uiData.petData.gid)
  }, true)
end

function UMG_PetSkillMain_C:GetAllSkills(_petData)
  local skills = {}
  local skillIds = {}
  if _petData then
    for _, skillData in ipairs(_petData.skill.skill_data) do
      local skillId = skillData.id or 0
      if (skillData.type == Enum.SkillActiveType.SAT_NORMAL or skillData.type == Enum.SkillActiveType.SAT_LEGENDARY) and (skillData.is_learned or self.showLockSkill) then
        local filterResult = self.cacheCurEquipSkillDic[skillData.id] or self:SkillFilter(skillData.id)
        if filterResult and not skillIds[skillId] then
          local _skillData = table.deepCopy(skillData, false)
          local _pos = self.cacheCurEquipSkillDic[skillData.id]
          _skillData.is_equipped = nil ~= _pos
          _skillData.pos = _pos
          local itemData = {
            skillData = _skillData,
            mode = self.uiData.mode,
            petData = self.uiData.petData,
            delayPlayAnim = self.delayPlaySkillItemAnim
          }
          if self:IsHerbologySingleSelectMode() and self.herbologyBadgeLockedSkillId then
            itemData.herbologyBadgeLockedSkillId = self.herbologyBadgeLockedSkillId
          end
          table.insert(skills, itemData)
          skillIds[skillId] = true
        end
      end
    end
    local notUnLockSkillIds = self:GetLockSkillList(_petData.base_conf_id)
    for i, skillId in ipairs(notUnLockSkillIds) do
      if not skillIds[skillId] then
        local filterResult = self:SkillFilter(skillId)
        if filterResult then
          local skillData = {}
          skillData.id = skillId
          skillData.is_learned = false
          table.insert(skills, {
            skillData = skillData,
            mode = self.uiData.mode,
            petData = self.uiData.petData,
            delayPlayAnim = self.delayPlaySkillItemAnim
          })
          skillIds[skillId] = true
        end
      end
    end
  end
  return skills
end

function UMG_PetSkillMain_C:GetLockSkillList(base_conf_id)
  if self.showLockSkill then
    local skillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, base_conf_id)
    if skillConf then
      local notUnLockSkillIds = {}
      for _, val in pairs(skillConf.machine_skill_group) do
        if val.machine_skill_id > 0 then
          table.insert(notUnLockSkillIds, val.machine_skill_id)
        end
      end
      if 0 ~= skillConf.blood_skill_COMMON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_COMMON)
      end
      if 0 ~= skillConf.blood_skill_GRASS then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_GRASS)
      end
      if 0 ~= skillConf.blood_skill_FIRE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_FIRE)
      end
      if 0 ~= skillConf.blood_skill_WATER then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_WATER)
      end
      if 0 ~= skillConf.blood_skill_LIGHT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_LIGHT)
      end
      if 0 ~= skillConf.blood_skill_STONE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_STONE)
      end
      if 0 ~= skillConf.blood_skill_ICE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_ICE)
      end
      if 0 ~= skillConf.blood_skill_DRAGON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_DRAGON)
      end
      if 0 ~= skillConf.blood_skill_ELECTRIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_ELECTRIC)
      end
      if 0 ~= skillConf.blood_skill_TOXIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_TOXIC)
      end
      if 0 ~= skillConf.blood_skill_INSECT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_INSECT)
      end
      if 0 ~= skillConf.blood_skill_FIGHT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_FIGHT)
      end
      if 0 ~= skillConf.blood_skill_WING then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_WING)
      end
      if 0 ~= skillConf.blood_skill_MOE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_MOE)
      end
      if 0 ~= skillConf.blood_skill_GHOST then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_GHOST)
      end
      if 0 ~= skillConf.blood_skill_DEMON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_DEMON)
      end
      if 0 ~= skillConf.blood_skill_MECHANIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_MECHANIC)
      end
      if 0 ~= skillConf.blood_skill_PHANTOM then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_PHANTOM)
      end
      return notUnLockSkillIds
    end
  end
  return {}
end

function UMG_PetSkillMain_C:updatePetInfo(_petData, _petBaseConf)
  if self.uiData == nil then
    self.uiData = {}
  end
  if _petData and (not self.uiData.petData or nil ~= _petData and _petData.base_conf_id ~= self.uiData.petData.base_conf_id) then
    self:InitFilterAndSort()
  end
  self.uiData.petData = _petData
  self.uiData.petBaseConf = _petBaseConf
  if self.isShow then
    self:RefreshUI()
  end
end

function UMG_PetSkillMain_C:InitFilterAndSort()
  self.filterRule = nil
  self.sortRule = _G.DataConfigManager:GetSkillSequenceConf(1)
  self.skillSortReverse = false
  self.SkillIdToSourceMap = {}
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self:RefreshShowLockSkillBtn()
  local path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  self.ViewPet_4:SetPath(path, path, path)
end

function UMG_PetSkillMain_C:SetSubPanelVisible(_index)
  for panelIndex, subPanel in pairs(self.subPanels) do
    if subPanel then
      if _index == panelIndex then
        subPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        subPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
      end
    end
  end
  if 2 == _index then
    self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, false)
  else
    self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
  end
end

function UMG_PetSkillMain_C:OnAnimationFinished(Animation)
end

function UMG_PetSkillMain_C:OnAddEventListener()
  self:AddButtonListener(self.changeBtn1.btnLevelUp, self.OnSkillLearnButtonClick)
  self:AddButtonListener(self.changeBtn2.btnLevelUp, self.OnChangeButtonClick)
  self:AddButtonListener(self.changeBtn4.btnLevelUp, self.OnChangeButtonClick)
  self:AddButtonListener(self.changeBtn3.btnLevelUp, self.OnChangeButtonClick)
  self:AddButtonListener(self.Btn_ShutDown, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_4, self.ResetDescText)
  self:AddButtonListener(self.backBtn.btnClose, self.OnBackBtnClick)
  self:AddButtonListener(self.ViewPet_4.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_6.btnLevelUp, self.OnSortSkillClick)
  self:AddButtonListener(self.ViewPet_7.btnLevelUp, self.OnShowLockSkillClick)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  self:RegisterEvent(self, PetUIModuleEvent.ExitSkillEquipMode, self.OnExitSkillEquipMode)
  self:RegisterEvent(self, PetUIModuleEvent.ErasePetSkillRedPoint, self.OnErasePetSkillRedPoint)
  self:RegisterEvent(self, PetUIModuleEvent.ShowBtnClosePanel, self.ShowBtnClosePanel)
  self:RegisterEvent(self, PetUIModuleEvent.HideBtnClosePanel, self.HideBtnClosePanel)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, PetUIModuleEvent.EquipSkill, self.OnEquipSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, PetUIModuleEvent.OnEquipAssumptionSkill, self.RefreshSkillListByAssumptionChange)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, WeeklyChallengeBattleModuleEvent.OnPetSkillChanged, self.OnWeeklyChallengePetSkillChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillMain_C", self, BattleRogueModuleEvent.OnPetSkillChanged, self.OnHerbologyPetSkillChanged)
  self:RegisterEvent(self, PetUIModuleEvent.SelectEmptySkill, self.OnSelectEmptySkill)
  if not self.petUIModule then
    self.petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  end
  self.ItemList:SetItemSelectedCallback(self.OnSkillItemSelected, self)
end

function UMG_PetSkillMain_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.changeBtn2.btnLevelUp, self.OnChangeButtonClick)
  self:RemoveButtonListener(self.backBtn.btnClose, self.OnBackBtnClick)
  self:UnRegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  self:UnRegisterEvent(self, PetUIModuleEvent.ExitSkillEquipMode, self.OnExitSkillEquipMode)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.EquipSkill, self.OnEquipSkill)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnEquipAssumptionSkill, self.RefreshSkillListByAssumptionChange)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnPetSkillChanged, self.OnWeeklyChallengePetSkillChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleRogueModuleEvent.OnPetSkillChanged, self.OnHerbologyPetSkillChanged)
  self:UnRegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  if not self.petUIModule then
    self.petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  end
end

local _curMode = 0

function UMG_PetSkillMain_C:ChangeState(mode, ignoreAnim)
  if _curMode ~= mode then
    _curMode = mode
    if 1 == _curMode then
      self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, false)
      self:DispatchEvent(PetUIModuleEvent.HideRetractionBtn, true)
      self:DispatchEvent(PetUIModuleEvent.HideRightPanel_CloseBtn, true)
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips, mode)
      self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.changeBtn3:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.changeBtn2:SetBtnText(LuaText.umg_petskillmain_3)
      self:StopAllAnimations()
      self:PlayAnimation(self.state)
      self.backBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowRightPanelShareBtn, false)
    else
      self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
      self:DispatchEvent(PetUIModuleEvent.HideRetractionBtn, false)
      self:DispatchEvent(PetUIModuleEvent.HideRightPanel_CloseBtn, false)
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips, mode)
      self:SetChangeBtnState(true)
      self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.changeBtn3:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.changeBtn2:SetBtnText(LuaText.umg_petskillmain_1)
      if not ignoreAnim then
        self:StopAllAnimations()
        self:PlayAnimation(self.state_1)
      end
      self.backBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowRightPanelShareBtn, true)
    end
  end
end

function UMG_PetSkillMain_C:IsHerbologySingleSelectMode()
  return self.data and self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.HerbologyBadge
end

function UMG_PetSkillMain_C:OnChangeButtonClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_EQUIP_SKILL, true)
  if isBan then
    return
  end
  self:ResetDescText()
  self.ItemList:ScrollToStart()
  local gid = self.uiData.petData.gid
  if 0 == self.uiData.mode then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002008, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
    self:SetViewMode(1)
    local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, gid)
    if self:IsHerbologySingleSelectMode() then
      self.singleSelectedSkillId = nil
      local herbologySkillMap = _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.GetHerbologyPetSkillMapByGid, gid)
      self.herbologyBadgeLockedSkillId = herbologySkillMap and herbologySkillMap[1] or nil
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, gid, {})
      self:SetChangeBtnState(false)
    else
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, gid, posToIdDic)
    end
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002007, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
    local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, gid)
    if nil == posToIdDic or not next(posToIdDic) then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_4)
      return
    end
    local saveDataType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetCurEquipSkillType, gid, PetUIModuleEnum.PetEquipSkillType.Assumption)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, gid, posToIdDic, saveDataType)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, nil)
    self:SetViewMode(0)
    self.singleSelectedSkillId = nil
    self.herbologyBadgeLockedSkillId = nil
  end
  self:ChangeState(self.uiData.mode)
  self:ShowPetSkill()
  self:OnErasePetSkillRedPoint()
end

function UMG_PetSkillMain_C:ResetDescText()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetRightPanelDescText)
end

function UMG_PetSkillMain_C:OnSkillLearnButtonClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_LEARN_SKILL, true)
  if isBan then
    return
  end
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClosePetSKillTips)
  local CanUse = _G.NRCModuleManager:DoCmd(BagModuleCmd.CanUseSkillMachine, self.uiData.petData)
  if CanUse then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, BagModuleEnum.DisplayMode.SkillMachine, self.uiData.petData)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\178\161\230\156\137\229\143\175\229\173\166\228\185\160\231\154\132\230\138\128\232\131\189\231\159\179")
  end
end

function UMG_PetSkillMain_C:OnExitSkillEquipMode()
  self:SetViewMode(0)
  self:ChangeState(self.uiData.mode, true)
  self.backBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetSkillMain_C:OnBackBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
  self:SetViewMode(0)
  self:ChangeState(self.uiData.mode)
  self:ShowPetSkill()
  self.singleSelectedSkillId = nil
end

function UMG_PetSkillMain_C:SetViewMode(mode)
  if self.uiData.mode ~= mode then
    self.uiData.mode = mode
    self:InitFilterAndSort()
    if 0 == mode then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, nil)
    end
  end
end

function UMG_PetSkillMain_C:ClearSkillListSelection(bPetUI)
  if self.isDestruct then
    return
  end
  if bPetUI then
    self.ItemList:SetItemClickAble(false)
  else
    self.Img_Mask:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.ItemList:ClearSelection()
  self:DelaySeconds(0.35, function()
    if UE4.UObject.IsValid(self) and UE4.UObject.IsValid(self.ItemList) then
      if bPetUI then
        self.ItemList:SetItemClickAble(true)
      else
        self.Img_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end)
end

function UMG_PetSkillMain_C:OnSelectSkill(skillData)
  self:ResetDescText()
  if not skillData then
    Log.Error("\230\138\128\232\131\189\230\149\176\230\141\174\228\184\186\231\169\186,\230\181\139\232\175\149\229\143\175\230\138\138Log\229\143\145\231\187\153\231\168\139\229\186\143\230\159\165\232\175\162")
    return
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetBagOpenState, true)
  if not skillData.is_learned then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillData.id, false, self.uiData.mode, self.uiData.petBaseConf.id, true, self.uiData.petData.gid)
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillData.id, false, self.uiData.mode, self.uiData.petBaseConf.id, false, self.uiData.petData.gid)
  end
end

function UMG_PetSkillMain_C:OnSelectEmptySkill()
  self:ResetDescText()
end

function UMG_PetSkillMain_C:OnEquipSkill(skillData, index)
  local mode = self.uiData.mode
  if 0 == mode or nil == skillData then
    return
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetBagOpenState, true)
  if skillData.is_learned then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillData.id, false, mode, self.uiData.petBaseConf.id, false, self.uiData.petData.gid)
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillData.id, false, mode, self.uiData.petBaseConf.id, true, self.uiData.petData.gid)
    return
  end
  if self:IsHerbologySingleSelectMode() then
    if self.singleSelectedSkillId == skillData.id then
      self.singleSelectedSkillId = nil
    else
      self.singleSelectedSkillId = skillData.id
    end
    local posToIdDic = {}
    if self.singleSelectedSkillId then
      posToIdDic[1] = self.singleSelectedSkillId
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, self.uiData.petData.gid, posToIdDic, nil)
    self:SetChangeBtnState(nil ~= self.singleSelectedSkillId)
    return
  end
  
  local function EquipCount(posToIdDic)
    local count = 0
    for i = 1, 4 do
      if posToIdDic[i] then
        count = count + 1
      end
    end
    return count
  end
  
  local posToIdDic, IdToPosDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetAssumptionEquipSkill, self.uiData.petData.gid)
  posToIdDic = posToIdDic or {}
  IdToPosDic = IdToPosDic or {}
  if IdToPosDic[skillData.id] then
    for i = 1, 4 do
      if posToIdDic[i] == skillData.id then
        posToIdDic[i] = nil
      end
    end
    IdToPosDic[skillData.id] = nil
  elseif 4 == EquipCount(posToIdDic) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_5)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002003, "UMG_PetSkillMain_C:OnEquipSkill isFull")
    return
  else
    for i = 1, 4 do
      if nil == posToIdDic[i] then
        posToIdDic[i] = skillData.id
        IdToPosDic[skillData.id] = i
        break
      end
    end
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401004, "UMG_PetSkillMain_C:OnEquipSkill")
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, self.uiData.petData.gid, posToIdDic, index)
  self:SetChangeBtnState(EquipCount(posToIdDic) > 0)
end

function UMG_PetSkillMain_C:SetChangeBtnState(_IsHighlight)
  if _IsHighlight then
    self.changeBtn2.HideAnim = false
    self.changeBtn2.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
  else
    self.changeBtn2.HideAnim = true
    self.changeBtn2.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
  end
end

function UMG_PetSkillMain_C:OnPvpPetTeamEquipPetSkills(_changes)
  self:ShowPetSkill()
end

function UMG_PetSkillMain_C:OnWeeklyChallengePetSkillChanged()
  self:ShowPetSkill()
end

function UMG_PetSkillMain_C:OnHerbologyPetSkillChanged()
  if not self.uiData or not self.uiData.petData then
    return
  end
  self:ShowPetSkill()
end

function UMG_PetSkillMain_C:OnEquippedSuccess(_changes)
end

function UMG_PetSkillMain_C:OnPanelStateChange(_isShow)
  if self.uiData and self.uiData.petData then
    local showChange = self.isShow ~= _isShow
    if showChange then
      self:InitFilterAndSort()
    end
    self.isShow = _isShow
    if _isShow then
      if 0 == self.skillNorPlane:GetRenderOpacity() then
        self:PlayAnimation(self.state_1)
        if showChange then
          self.skillNorPlane:SetRenderOpacity(1)
        end
        self.BtnMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.BtnMask:SetVisibility(UE4.ESlateVisibility.Visible)
        self:PlayAnimation(self.inchange)
      end
    else
      self:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    self:SetViewMode(0)
    self:ChangeState(self.uiData.mode)
    self:RefreshUI()
  else
    self:SetEmpty()
  end
end

function UMG_PetSkillMain_C:OnAnimationFinished(Anim)
  if Anim == self.inchange then
    self.BtnMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillMain_C:GetEquipSkillDatas(_petData, _petBaseConf)
  local petEquipSkills = {}
  for i = 1, 4 do
    local data = {}
    data.petData = _petData
    data.callbackCaller = self
    data.callbackFunc = self.OnSkillChange
    table.insert(petEquipSkills, data)
  end
  if _petData then
    for i, skillData in ipairs(_petData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos].skillData = skillData
      end
    end
  end
  return petEquipSkills
end

function UMG_PetSkillMain_C:OnSkillSelected(selected)
end

function UMG_PetSkillMain_C:ShowSkillBtnState()
  self.UnusableBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.changeBtn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:UpdateChangeBtn2Visibility()
  if 0 == self.BtnSwitcher:GetActiveWidgetIndex() then
    if self.uiData.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
      self.HorizontalBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.HorizontalBox:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif self.uiData.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.changeBtn4:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetSkillMain_C:ShowBgStyle()
  if self.uiData.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.NightmareBg:SetVisibility(UE4.ESlateVisibility.Visible)
    self.StarBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NightmareBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.StarBg:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetSkillMain_C:OnSelectSkillClick()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
  self:ResetDescText()
  if self.uiData and self.uiData.petData and self.uiData.petBaseConf then
    local skillList = {}
    local skillIds = {}
    for i, v in ipairs(self.uiData.petData.skill.skill_data) do
      if (v.type == Enum.SkillActiveType.SAT_NORMAL or v.type == Enum.SkillActiveType.SAT_LEGENDARY) and (v.is_learned or self.showLockSkill) then
        table.insert(skillList, v)
        skillIds[v.id] = true
      end
    end
    local notUnLockSkillIds = self:GetLockSkillList(self.uiData.petBaseConf.id)
    for i, skillId in ipairs(notUnLockSkillIds) do
      if not skillIds[skillId] then
        local skillData = {}
        skillData.id = skillId
        skillData.is_learned = false
        table.insert(skillList, skillData)
        skillIds[skillId] = true
      end
    end
    local skillCountTab = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CalculationSkillNumByType, skillList, self.uiData.petBaseConf.id)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetFilteringPanel, self.filterRule, skillCountTab, skillList, self.uiData.petBaseConf.id)
  end
end

function UMG_PetSkillMain_C:OnSortSkillClick()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRule and self.sortRule.id or nil, self.skillSortReverse)
end

function UMG_PetSkillMain_C:OnPetSkillFilterRuleChange(filterRule)
  self.filterRule = filterRule
  local path
  if self.filterRule then
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  end
  self.ViewPet_4:SetPath(path, path, path)
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_PetSkillMain_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRule = nil ~= id and _G.DataConfigManager:GetSkillSequenceConf(id) or nil
  self.skillSortReverse = skillSortReverse
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_PetSkillMain_C:OnShowLockSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetSkillMain_C:OnShowLockSkillClick")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
  self:ResetDescText()
  self.showLockSkill = not self.showLockSkill
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.showLockSkill)
  self:RefreshShowLockSkillBtn()
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
  self.ItemList:ScrollToStart()
end

function UMG_PetSkillMain_C:RefreshShowLockSkillBtn()
  local path, text
  if self.showLockSkill then
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockVisible_png.img_UnlockVisible_png'"
    text = LuaText.skill_sort_text_2
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockInvisible_png.img_UnlockInvisible_png'"
    text = LuaText.skill_sort_text_1
  end
  self.ViewPet_7:SetPath(path, path, path)
  self.ViewPet_7:SetText(text)
end

function UMG_PetSkillMain_C:SkillFilter(skillId)
  if self.filterRule then
    if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_SOURCE] then
      local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSource, skillId, self.uiData.petBaseConf.id)
      local haveType = false
      for i, v in ipairs(skillSourceList) do
        if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_SOURCE][v] then
          haveType = true
          break
        end
      end
      if not haveType then
        return false
      end
    end
    local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
    if skillConf then
      if self.filterRule[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE] and not self.filterRule[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE][skillConf.skill_dam_type] then
        return false
      end
      if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_TYPE] and not self.filterRule[_G.Enum.FilterRule.FIL_SKILL_TYPE][skillConf.Skill_Type] then
        return false
      end
    end
  end
  return true
end

function UMG_PetSkillMain_C:SkillRuleSortHandle(skillList)
  if not (self.sortRule and skillList) or 0 == #skillList then
    return
  end
  local isReverse = self.skillSortReverse
  local sortType = isReverse and self.sortRule.sequence_switch or self.sortRule.sequence_default
  local sortFunc
  if isReverse then
    if sortType == Enum.SkillSequenceSwitch.SSS_DAM_TYPE_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "damType", "cost", "default")
      end
    elseif sortType == Enum.SkillSequenceSwitch.SSS_ENERGY_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "cost", "damType", "default")
      end
    elseif sortType == Enum.SkillSequenceSwitch.SSS_LEARN_SEQUENCE_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "default", "damType", "cost")
      end
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_DAM_TYPE_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "damType", "cost", "default")
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_ENERGY_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "cost", "damType", "default")
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_LEARN_SEQUENCE_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "default", "damType", "cost")
    end
  end
  if sortFunc then
    self:StableSort(skillList, sortFunc)
  end
end

function UMG_PetSkillMain_C:StableSort(list, compareFunc)
  for i = 2, #list do
    local j = i
    while j > 1 and compareFunc(list[j], list[j - 1]) do
      list[j], list[j - 1] = list[j - 1], list[j]
      j = j - 1
    end
  end
end

function UMG_PetSkillMain_C:CompareSkills(a, b, primaryKey, secondaryKey, tertiaryKey)
  local confA = a._sortCache or _G.DataConfigManager:GetSkillConf(a.skillData.id)
  local confB = b._sortCache or _G.DataConfigManager:GetSkillConf(b.skillData.id)
  a._sortCache = confA
  b._sortCache = confB
  if not confA or not confB then
    return false
  end
  local a_pos = 1 == self.uiData.mode and self.cacheCurEquipSkillDic[a.skillData.id] or a.skillData.pos
  local b_pos = 1 == self.uiData.mode and self.cacheCurEquipSkillDic[b.skillData.id] or b.skillData.pos
  if a_pos and not b_pos then
    return true
  end
  if not a_pos and b_pos then
    return false
  end
  if a_pos and b_pos then
    return a_pos < b_pos
  end
  if a.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    if a.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      return true
    elseif b.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      return false
    end
  end
  local primaryA = self:GetCompareValue(confA, primaryKey, 3)
  local primaryB = self:GetCompareValue(confB, primaryKey, 3)
  if primaryA ~= primaryB then
    if self.skillSortReverse and "default" ~= primaryKey then
      return primaryA > primaryB
    else
      return primaryA < primaryB
    end
  end
  if "default" ~= primaryKey then
    local secondaryA = self:GetCompareValue(confA, secondaryKey)
    local secondaryB = self:GetCompareValue(confB, secondaryKey)
    if secondaryA ~= secondaryB then
      return secondaryA < secondaryB
    end
    local tertiaryA = self:GetCompareValue(confA, tertiaryKey)
    local tertiaryB = self:GetCompareValue(confB, tertiaryKey)
    if tertiaryA ~= tertiaryB then
      return tertiaryA < tertiaryB
    end
  end
  return a.skillData.id < b.skillData.id
end

function UMG_PetSkillMain_C:GetCompareValue(conf, key, level)
  if not conf then
    Log.Error("CompareSkills: conf is nil")
    return nil
  end
  if "damType" == key then
    return self:GetSkillDamTypeOrderFromConf(conf, level)
  elseif "cost" == key then
    return conf.energy_cost[1]
  elseif "default" == key then
    return self:GetDefaultSortWeighting(conf)
  end
end

function UMG_PetSkillMain_C:GetSkillDamTypeOrderFromConf(skillConf, level)
  if not skillConf then
    return 200
  end
  if 3 ~= level then
    return skillConf.skill_dam_type
  end
  if skillConf.skill_dam_type == self.uiData.petBaseConf.unit_type[1] then
    return 1
  elseif skillConf.skill_dam_type == self.uiData.petBaseConf.unit_type[2] then
    return 2
  else
    return skillConf.skill_dam_type + 10
  end
end

function UMG_PetSkillMain_C:GetDefaultSortWeighting(skillConf)
  local Weighting = 9999
  if not skillConf then
    return Weighting
  end
  local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSource, skillConf.id, self.uiData.petBaseConf.id)
  if #skillSourceList > 0 then
    if skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
      local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.uiData.petBaseConf.id)
      if levelSkillConf then
        if self.skillSortReverse then
          for i, v in ipairs(levelSkillConf.level) do
            if v.param == skillConf.id then
              Weighting = self.petMaxLevelLimit - v.level_point
              break
            end
          end
        else
          for i, v in ipairs(levelSkillConf.level) do
            if v.param == skillConf.id then
              Weighting = v.level_point
              break
            end
          end
        end
      end
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_LEGENDARY then
      Weighting = self.petMaxLevelLimit + 1
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
      Weighting = self.petMaxLevelLimit + 2
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      Weighting = self.petMaxLevelLimit + 3
    end
  end
  return Weighting
end

function UMG_PetSkillMain_C:PetFriendInterfaceDisplay()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.changeBtn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetSkillMain_C
