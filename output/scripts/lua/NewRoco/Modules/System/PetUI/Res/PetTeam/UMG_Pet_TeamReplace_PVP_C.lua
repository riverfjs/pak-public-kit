local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_Pet_TeamReplace_PVP_C = _G.NRCPanelBase:Extend("UMG_Pet_TeamReplace_PVP_C")

function UMG_Pet_TeamReplace_PVP_C:OnConstruct()
  self.data = self.module:GetData("PetUIModuleData")
  self:SetChildViews(self.UMG_PetRate, self.CommonPetDetails)
end

function UMG_Pet_TeamReplace_PVP_C:OnActive()
  self:OnAddEventListener()
  local titleConf = _G.DataConfigManager:GetTitleConf("RecommendedLineup3")
  self.Title1:SetBaseInfo(titleConf.head_icon, titleConf.subtitle[1].subtitle, titleConf.title)
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self.descText = {}
  self.IsChangeSkill = false
  self.curTeamType = Enum.PlayerTeamType.PTT_PVP_BATTLE_4
  self.curTeamIdx = 0
  self.skillSortReverse = false
  local initData = self:SetPetInfoList()
  self.WarehouseList:InitList(initData)
  self.petData = initData
  self.afterFilterList = initData
  self:SetCommonComboBoxInfo(self.ComScreen)
  self.bIsAscendingOrder = true
  self:SortItemInfo(1)
  self.curSelPetData = initData[1].PetData
  self.ChangePetSkillsPanel:LoadPanel(nil, self.curSelPetData.PetBaseInfo)
  self.WarehouseList:SelectItemByIndex(0)
end

function UMG_Pet_TeamReplace_PVP_C:OnPetTeamWarehouseItemSelected(PetData)
  if not self.curSelPetData or PetData and self.curSelPetData.base_conf_id ~= PetData.base_conf_id then
    self:InitFilterAndSort()
  end
  self.curSelPetData = PetData
  if PetData then
    self:ResetDescText()
    self:SetRightInfo(PetData)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_Pet_TeamReplace_PVP_C:OnPetTeamWarehouseItemSelected")
  else
    self.Switcher:SetActiveWidgetIndex(2)
    self:HideTipsIfNeeded()
  end
end

function UMG_Pet_TeamReplace_PVP_C:SetRightInfo(PetData, ListIndex)
  if not PetData then
    return
  end
  self.curShowPetData = PetData
  self.curSelPetData = PetData
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_FavoriteButton_C:UpdateInfo")
  self.ListIndex = ListIndex
  self.IconList_1:ScrollToStart()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.curSelPetData.base_conf_id, true)
  local commonAttrData = {}
  local commonAttrData1 = {}
  local petData = self.curSelPetData.PetBaseInfo
  if not petData then
    return
  end
  self.textPetName:SetText(petData.name)
  self:updatePetGender(petData.gender)
  self.UMG_PetRate:SetText(petData)
  self.textPetLv:SetText(petData.level)
  local PetLevel = PetUtils.GetBreakThroughStarsList(petData)
  self.CatchHardLv:InitGridView(PetLevel)
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
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petData.blood_id)
  if PetBloodConf then
    if not petData or petData.is_trial_pet then
      self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_CollectBtn:UpdateInfo(petData.partner_mark, true)
    end
    table.insert(commonAttrData, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
    if self.Attr then
      self.Attr:InitGridView(commonAttrData)
    end
  end
  self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local attrList = {}
  local attrInfo = petData.attribute_info
  local positive_effect, negative_effect
  local natureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
  if 0 ~= petData.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(petData.changed_nature_pos_attr_type)
  else
    positive_effect = natureConf.positive_effect
  end
  if 0 ~= petData.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(petData.changed_nature_neg_attr_type)
  else
    negative_effect = natureConf.negative_effect
  end
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_HPMAX,
    arrowType = _G.Enum.AttributeType.AT_HPMAX_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_HPMAX),
    attrInfo = attrInfo.hp,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_1
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYDEF,
    arrowType = _G.Enum.AttributeType.AT_PHYDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_PHYDEF),
    attrInfo = attrInfo.defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_5
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYATK,
    arrowType = _G.Enum.AttributeType.AT_PHYATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_PHYATK),
    attrInfo = attrInfo.attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_3
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEDEF,
    arrowType = _G.Enum.AttributeType.AT_SPEDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_SPEDEF),
    attrInfo = attrInfo.special_defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_6
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEATK,
    arrowType = _G.Enum.AttributeType.AT_SPEATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_SPEATK),
    attrInfo = attrInfo.special_attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_4
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEED,
    arrowType = _G.Enum.AttributeType.AT_SPEED_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(PetData.PetBaseInfo, Enum.AttributeType.AT_SPEED),
    attrInfo = attrInfo.speed,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = self.curSelPetData.base_conf_id,
    name = LuaText.umg_battle_changepetconfirm_2,
    NoShowline = true
  })
  local petEquipSkillList = self:GetPetEquipSkills(petData)
  self.BtnHandlerList = {}
  self.BtnHandlerList.Call = self
  self.BtnHandlerList.OnTextClickedHandler = self.OnDescTextClicked
  self.BtnHandlerList.OnRestTextHandler = self.ResetDescText
  self.CommonPetDetails:InitPetBaseInfo(petData, petBaseConf, attrList, petEquipSkillList, PetUIModuleEnum.CommonPetDetailsShowType.PvpRank, self.BtnHandlerList)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    local skillMap = self:GetSkillMapByPetGid(self.curShowPetData)
    local teamParam = self:GetTeamParam(self.curShowPetData.gid)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
  end
  if self.IsChangeSkill then
    local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, PetData.gid, PetUIModuleEnum.PetEquipSkillType.PvpTeam)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, PetData.gid, posToIdDic)
    self.Switcher:SetActiveWidgetIndex(1)
  else
    self.Switcher:SetActiveWidgetIndex(0)
  end
  if self.curSelPetData and ChangePetSkillsPanel then
    ChangePetSkillsPanel:RefreshUI(self.curSelPetData.PetBaseInfo)
  end
end

function UMG_Pet_TeamReplace_PVP_C:GetTeamParam(PetGid)
  local teamParam = {}
  teamParam.TeamType = self.curTeamType
  teamParam.TeamIdx = self.curTeamIdx
  teamParam.PetGid = PetGid
  return teamParam
end

function UMG_Pet_TeamReplace_PVP_C:GetSkillMapByPetGid(petData)
  local PetGid = petData.gid
  local skillList = self:GetPetEquipSkills(petData.PetBaseInfo)
  local skillMap = {}
  if skillList then
    for index, skillInfo in pairs(skillList) do
      skillMap[skillInfo.id] = index
    end
  end
  return skillMap
end

function UMG_Pet_TeamReplace_PVP_C:ResetDescText()
  table.clear(self.descText)
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_TeamReplace_PVP_C:OnDescTextClicked(descText)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Pet_TeamReplace_PVP_C:GetPetEquipSkills(petData)
  if not petData then
    Log.Error("UMG_Pet_TeamReplace_C:GetPetEquipSkills petData is nil")
    return {}
  end
  local petEquipSkills = self.data:GetPetSkillsData(petData.gid)
  if petEquipSkills then
    local result = {}
    for _, id in pairs(petEquipSkills) do
      table.insert(result, {id = id})
    end
    return result
  end
  petEquipSkills = {}
  if petData.skill and petData.skill.skill_data then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  return petEquipSkills
end

function UMG_Pet_TeamReplace_PVP_C:GetChangeAttrReqEnum(attribute)
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

function UMG_Pet_TeamReplace_PVP_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_TeamReplace_PVP_C:InitFilterAndSort()
  self.sortRuleId = 1
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:InitFilterAndSort()
  end
  local path2 = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  self.ViewPet:SetPath(path2, path2, path2)
  self:RefreshShowLockSkillBtn()
end

function UMG_Pet_TeamReplace_PVP_C:RefreshShowLockSkillBtn()
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

function UMG_Pet_TeamReplace_PVP_C:SetPetInfoList()
  self.petInfoList = {}
  local petData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  local trialRefreshTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime)
  local petInfoList = {}
  for i, petinfo in ipairs(petData) do
    local petInfo
    local baseConfId = petinfo and petinfo.base_conf_id
    if baseConfId then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseConfId)
      if petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        local temp = {
          level = petinfo.level,
          gid = petinfo.gid,
          petIcon = modelConf,
          pet_status_flags = petinfo.pet_status_flags or 0,
          base_conf_id = petinfo.base_conf_id,
          CanChangeTeam = petinfo.enable_change,
          CanChangeTeamSort = petinfo.enable_change and 1 or 0,
          energy = petinfo.energy,
          PetBaseInfo = petinfo,
          is_trial_pet = petinfo.is_trial_pet,
          refreshTime = trialRefreshTime,
          canInTeamNum = self.canInTeamNum
        }
        for j = 1, 12 do
          local PetBasicProperty
          if 1 == j then
            PetBasicProperty = petinfo.level
          elseif 2 == j then
            PetBasicProperty = petinfo.add_time
          elseif j <= 8 then
            PetBasicProperty = PetUtils.GetPetAdditionalByType(petinfo, j - 2)
          elseif 10 == j then
            PetBasicProperty = petinfo.talent_rank
          elseif 11 == j then
            if petinfo.partner_mark and petinfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
              PetBasicProperty = 100 - petinfo.partner_mark
            else
              PetBasicProperty = 0
            end
          elseif 12 == j then
            if petinfo.grow_times then
              PetBasicProperty = petinfo.grow_times
            else
              PetBasicProperty = 0
            end
          end
          if PetBasicProperty then
            temp[j] = PetBasicProperty
          end
        end
        temp.is_trial_pet = true
        petInfo = {PetData = temp}
      end
    end
    if petInfo then
      table.insert(petInfoList, petInfo)
    end
  end
  return petInfoList
end

function UMG_Pet_TeamReplace_PVP_C:SetCommonComboBoxInfo(ComboBox, ComboBoxText, ComboBoxIcon)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OpenFilterPanelBtnClick
  CommonDropDownListData.Btn_MidHandler = self.OnSortBtnButtonClick
  CommonDropDownListData.Btn_RightHandler = self.OnReversedSort
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_Pet_TeamReplace_PVP_C:OpenFilterPanelBtnClick()
  self:ResetDescText()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.TeamReplace, self.data.chooseTypeList)
end

function UMG_Pet_TeamReplace_PVP_C:OnSortBtnButtonClick()
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenSortPanel, self.SortIndex, PetUIModuleEnum.OpenSortType.TeamReplace)
end

function UMG_Pet_TeamReplace_PVP_C:OnReversedSort()
  self:ResetDescText()
  self.bIsAscendingOrder = not self.bIsAscendingOrder
  local newPetData = {}
  local oldPetData = self.afterFilterList
  for i = #oldPetData, 1, -1 do
    table.insert(newPetData, oldPetData[i])
  end
  self.afterFilterList = newPetData
  self.WarehouseList:InitList(newPetData)
end

function UMG_Pet_TeamReplace_PVP_C:RefreshPetListByChooseType(TypeChooseList)
  local DepartmentFilter = {}
  if TypeChooseList.DepartmentFilter then
    for i, v in pairs(TypeChooseList.DepartmentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(DepartmentFilter, enum)
      end
    end
  end
  local TalentFilter = {}
  if TypeChooseList.TalentFilter then
    for i, v in pairs(TypeChooseList.TalentFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(TalentFilter, enum)
    end
  end
  local NaturePositiveEffectFilter = {}
  if TypeChooseList.NaturePositiveEffectFilter then
    for i, v in pairs(TypeChooseList.NaturePositiveEffectFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(NaturePositiveEffectFilter, enum)
    end
  end
  local AttributeFilter = {}
  if TypeChooseList.AttributeFilter then
    for i, v in pairs(TypeChooseList.AttributeFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(AttributeFilter, enum)
    end
  end
  local PartnerMarkerFilter = {}
  if TypeChooseList.PartnerMarkerFilter then
    for i, v in pairs(TypeChooseList.PartnerMarkerFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(PartnerMarkerFilter, enum)
      end
    end
  end
  local resultList = {}
  local InitState = true
  if #DepartmentFilter > 0 or #TalentFilter > 0 or #NaturePositiveEffectFilter > 0 or #AttributeFilter > 0 or #PartnerMarkerFilter > 0 then
    InitState = false
    self.ComScreen.ScreeningBtn:ChangeIconSelectState(2)
  else
    self.ComScreen.ScreeningBtn:ChangeIconSelectState(1)
  end
  for _, petInfo in pairs(self.petData) do
    if petInfo.PetData then
      local CanInsert = InitState
      if self:CheckDepartmentFilter(DepartmentFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckTalentFilter(TalentFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckNaturePositiveEffectFilter(NaturePositiveEffectFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckAttributeFilter(AttributeFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckPartnerMarkerFilter(PartnerMarkerFilter, petInfo) then
        CanInsert = true
      end
      if CanInsert then
        table.insert(resultList, petInfo)
      end
    end
  end
  self.afterFilterList = resultList
  self:SortItemInfo(self.SortIndex)
end

function UMG_Pet_TeamReplace_PVP_C:CheckDepartmentFilter(DepartmentFilter, petInfo)
  if DepartmentFilter and #DepartmentFilter > 0 then
    local PetData = petInfo and petInfo.PetData
    local petBaseConfId = PetData and PetData.base_conf_id
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId, true)
    local unitTypeList = petBaseConf and petBaseConf.unit_type or {}
    for k = 1, #unitTypeList do
      for j = 1, #DepartmentFilter do
        if unitTypeList[k] == DepartmentFilter[j] then
          return true
        end
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_PVP_C:CheckTalentFilter(TalentFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local talent_rank = PetBaseInfo and PetBaseInfo.talent_rank
  if TalentFilter and #TalentFilter > 0 then
    for i = 1, #TalentFilter do
      if talent_rank == TalentFilter[i] then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_PVP_C:CheckNaturePositiveEffectFilter(NaturePositiveEffectFilter, petInfo)
  if NaturePositiveEffectFilter and #NaturePositiveEffectFilter > 0 then
    local PetData = petInfo and petInfo.PetData
    local PetBaseInfo = PetData and PetData.PetBaseInfo
    local changed_nature_pos_attr_type = PetBaseInfo and PetBaseInfo.changed_nature_pos_attr_type
    local nature = PetBaseInfo and PetBaseInfo.nature
    local NaturePositive = changed_nature_pos_attr_type
    if not NaturePositive or 0 == NaturePositive then
      local natureConf = _G.DataConfigManager:GetNatureConf(nature)
      NaturePositive = natureConf and natureConf.positive_effect
    else
      NaturePositive = self:GetChangeAttrReqEnum(NaturePositive)
    end
    for j = 1, #NaturePositiveEffectFilter do
      if NaturePositive == NaturePositiveEffectFilter[j] then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_PVP_C:GetChangeAttrReqEnum(attribute)
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

function UMG_Pet_TeamReplace_PVP_C:CheckAttributeFilter(AttributeFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local attributeInfo = PetBaseInfo and PetBaseInfo.attribute_info
  local hp = attributeInfo and attributeInfo.hp
  local hpTalent = hp and hp.talent
  local attack = attributeInfo and attributeInfo.attack
  local attackTalent = attack and attack.talent
  local specialAttack = attributeInfo and attributeInfo.special_attack
  local specialAttackTalent = specialAttack and specialAttack.talent
  local defense = attributeInfo and attributeInfo.defense
  local defenseTalent = defense and defense.talent
  local specialDefense = attributeInfo and attributeInfo.special_defense
  local specialDefenseTalent = specialDefense and specialDefense.talent
  local speed = attributeInfo and attributeInfo.speed
  local speedTalent = speed and speed.talent
  for j = 1, #AttributeFilter do
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_HPMAX and hpTalent and hpTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_PHYATK and attackTalent and attackTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEATK and specialAttackTalent and specialAttackTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_PHYDEF and defenseTalent and defenseTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEDEF and specialDefenseTalent and specialDefenseTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEED and speedTalent and speedTalent > 0 then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_PVP_C:CheckPartnerMarkerFilter(PartnerMarkerFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local partner_mark = PetBaseInfo and PetBaseInfo.partner_mark
  for j = 1, #PartnerMarkerFilter do
    if partner_mark == PartnerMarkerFilter[j] then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_PVP_C:SortItemInfo(sortId)
  self.SortIndex = sortId
  self.afterFilterList = self:PetListSort(self.bIsAscendingOrder, self.afterFilterList)
  self.WarehouseList:InitList(self.afterFilterList)
end

function UMG_Pet_TeamReplace_PVP_C:PetListSort(_IsAscendingOrder, _PetList)
  local newPetList = {}
  local travelPetList = {}
  for i = 1, #_PetList do
    local petInfo = _PetList[i]
    if petInfo.IsTravel then
      table.insert(travelPetList, petInfo)
    else
      table.insert(newPetList, petInfo)
    end
  end
  
  local function cmpFunction(a, b)
    return true
  end
  
  if _IsAscendingOrder then
    function cmpFunction(a, b)
      local aIconListSortInfo = a.PetData[self.SortIndex]
      
      local bIconListSortInfo = b.PetData[self.SortIndex]
      if aIconListSortInfo and bIconListSortInfo then
        if aIconListSortInfo == bIconListSortInfo then
          return aIconListSortInfo > bIconListSortInfo
        else
          return aIconListSortInfo > bIconListSortInfo
        end
      elseif aIconListSortInfo then
        return true
      elseif bIconListSortInfo then
        return false
      else
        return false
      end
    end
  else
    function cmpFunction(a, b)
      local aIconListSortInfo = a.PetData[self.SortIndex]
      
      local bIconListSortInfo = b.PetData[self.SortIndex]
      if aIconListSortInfo and bIconListSortInfo then
        if aIconListSortInfo == bIconListSortInfo then
          return aIconListSortInfo < bIconListSortInfo
        else
          return aIconListSortInfo < bIconListSortInfo
        end
      elseif aIconListSortInfo then
        return false
      elseif bIconListSortInfo then
        return true
      else
        return false
      end
    end
  end
  table.sort(newPetList, cmpFunction)
  for i = 1, #travelPetList do
    table.insert(newPetList, travelPetList[i])
  end
  return newPetList
end

function UMG_Pet_TeamReplace_PVP_C:OnClose()
  if self.IsChangeSkill then
    self.IsChangeSkill = false
    self.Switcher:SetActiveWidgetIndex(0)
    self:InitFilterAndSort()
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:OnDisable()
    end
    return
  end
  self.data.chooseTypeList = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {}
  }
  self:PlayAnimation(self.Out)
  _G.NRCAudioManager:PlaySound2DAuto(40002014, "UMG_Pet_TeamReplace_PVP_C:OnClose")
end

function UMG_Pet_TeamReplace_PVP_C:OnClickSkillsChange()
  self:ResetDescText()
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self:RefreshShowLockSkillBtn()
  if self.curShowPetData then
    self.IsChangeSkill = true
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.PvpPetTeamUmg)
    local skillMap = self:GetSkillMapByPetGid(self.curShowPetData)
    local teamParam = self:GetTeamParam(self.curShowPetData.gid)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
    _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      self:InitFilterAndSort()
      local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, self.curShowPetData.gid, PetUIModuleEnum.PetEquipSkillType.PvpTeam)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.curShowPetData.gid, posToIdDic)
      ChangePetSkillsPanel:ShowPetSkill()
      self.Switcher:SetActiveWidgetIndex(1)
    else
      self.ChangePetSkillsPanel:LoadPanel(nil, self.curSelPetData.PetBaseInfo)
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    self:ShowSkillBtnState()
  end
end

function UMG_Pet_TeamReplace_PVP_C:ShowSkillBtnState()
  if self.curSelPetData and self.curSelPetData.PetBaseInfo and self.curSelPetData.PetBaseInfo.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.changeBtn5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.changeBtn5:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Pet_TeamReplace_PVP_C:SaveSkillChange()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    if ChangePetSkillsPanel and ChangePetSkillsPanel.petData and ChangePetSkillsPanel.petData.blood_id ~= Enum.PetBloodType.PBT_NIGHTMARE then
      ChangePetSkillsPanel:OnChangeButtonClick()
    end
    ChangePetSkillsPanel:OnDisable()
  end
  self.IsChangeSkill = false
  self.Switcher:SetActiveWidgetIndex(0)
  self:InitFilterAndSort()
end

function UMG_Pet_TeamReplace_PVP_C:OnSelectSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OpenSkillFilteringPanelByCurShowSkillList()
  end
end

function UMG_Pet_TeamReplace_PVP_C:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:ClearSkillListSelection()
  end
end

function UMG_Pet_TeamReplace_PVP_C:OnSortSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRuleId, self.skillSortReverse)
end

function UMG_Pet_TeamReplace_PVP_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRuleId = id
  self.skillSortReverse = skillSortReverse
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnPetSkillSortRuleChange(id, skillSortReverse)
  end
end

function UMG_Pet_TeamReplace_PVP_C:OnPetSkillFilterRuleChange(filterRule)
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

function UMG_Pet_TeamReplace_PVP_C:OnShowLockSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_Pet_TeamReplace_PVP_C:OnShowLockSkillClick")
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    self.showLockSkill = not self.showLockSkill
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.showLockSkill)
    self:RefreshShowLockSkillBtn()
    ChangePetSkillsPanel:OnShowLockSkillChange(self.showLockSkill)
  end
end

function UMG_Pet_TeamReplace_PVP_C:OnBloodPulse()
  self:ResetDescText()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPetBloodPulse, self.curShowPetData.PetBaseInfo)
end

function UMG_Pet_TeamReplace_PVP_C:OpenPetTips()
  if not self.curShowPetData or not self.curShowPetData.PetBaseInfo then
    Log.Error("\229\174\160\231\137\169\230\149\176\230\141\174\228\184\186\231\169\186,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return
  end
  self:ResetDescText()
  local TipData = {
    petData = self.curShowPetData.PetBaseInfo
  }
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, TipData, _G.Enum.GoodsType.GT_PET)
end

function UMG_Pet_TeamReplace_PVP_C:OnPvpPetTeamEquipPetSkills()
  if self.IsChangeSkill then
    self.IsChangeSkill = false
    self.Switcher:SetActiveWidgetIndex(0)
  end
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.curShowPetData.gid, false)
  self.curShowPetData.PetBaseInfo = petData
  self.curSelPetData = petData
  self:SetRightInfo(self.curShowPetData)
end

function UMG_Pet_TeamReplace_PVP_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_Pet_TeamReplace_PVP_C:OnAddEventListener()
  self:RegisterEvent(self, PetUIModuleEvent.FilterPet, self.RefreshPetListByChooseType)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_SORT, self.SortItemInfo)
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamWarehouseItemSelected, self.OnPetTeamWarehouseItemSelected)
  self:AddButtonListener(self.Return.btnClose, self.OnClose)
  self:AddButtonListener(self.changeBtn4.btnLevelUp, self.OnClickSkillsChange)
  self:AddButtonListener(self.Btn_ShutDown, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_4, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_5, self.ResetDescText)
  self:AddButtonListener(self.changeBtn5.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:AddButtonListener(self.ViewPet_3.btnLevelUp, self.OnShowLockSkillClick)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:RegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
end

function UMG_Pet_TeamReplace_PVP_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PetUIModuleEvent.FilterPet)
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_UI_SORT)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamWarehouseItemSelected)
  self:RemoveButtonListener(self.Return.btnClose)
  self:RemoveButtonListener(self.changeBtn4.btnLevelUp)
  self:RemoveButtonListener(self.Btn_ShutDown)
  self:RemoveButtonListener(self.Btn_ShutDown_1)
  self:RemoveButtonListener(self.Btn_ShutDown_2)
  self:RemoveButtonListener(self.Btn_ShutDown_3)
  self:RemoveButtonListener(self.Btn_ShutDown_4)
  self:RemoveButtonListener(self.Btn_ShutDown_5)
  self:RemoveButtonListener(self.changeBtn5.btnLevelUp)
  self:RemoveButtonListener(self.ViewPet.btnLevelUp)
  self:RemoveButtonListener(self.ViewPet_2.btnLevelUp)
  self:RemoveButtonListener(self.ViewPet_3.btnLevelUp)
  self:RemoveButtonListener(self.BtnRechristen_1)
  self:RemoveButtonListener(self.BloodPulse)
  self:UnRegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills)
end

return UMG_Pet_TeamReplace_PVP_C
