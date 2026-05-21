local Base = _G.NRCPanelBase
local ModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_HerbologyBadge_SelectPet_C = Base:Extend("UMG_HerbologyBadge_SelectPet_C")

function UMG_HerbologyBadge_SelectPet_C:Construct()
  Base.Construct(self)
  self.GridView1:SetMsgHandler({
    OnItemSelected = _G.MakeWeakFunctor(self, self.OnGridViewItemSelected)
  })
end

function UMG_HerbologyBadge_SelectPet_C:OnActive()
  self.curPetDataList = {}
  self.curFilterRule = nil
  self.curSortRuleType = _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN
  self.isAscending = false
  self.bConfirmPanelInited = false
  self:OnAddEventListener()
  self:_InitComboBox()
  self:_InitPanel()
end

function UMG_HerbologyBadge_SelectPet_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_HerbologyBadge_SelectPet_C:OnAddEventListener()
  self:RegisterEvent(self, ModuleEvent.OnPetSelectPanelCloseButtonClicked, self.OnCloseButtonClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_HerbologyBadge_SelectPet_C", self, PetUIModuleEvent.PET_UI_SORT, self.OnPetSort)
  _G.NRCEventCenter:RegisterEvent("UMG_HerbologyBadge_SelectPet_C", self, PetUIModuleEvent.FilterPet, self.OnPetFilter)
end

function UMG_HerbologyBadge_SelectPet_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PET_UI_SORT, self.OnPetSort)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.FilterPet, self.OnPetFilter)
end

function UMG_HerbologyBadge_SelectPet_C:OnCloseButtonClicked()
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.ChooseLevel)
end

function UMG_HerbologyBadge_SelectPet_C:OnConstruct()
  self:SetChildViews(self.ConfirmPanel)
end

function UMG_HerbologyBadge_SelectPet_C:OnDestruct()
end

function UMG_HerbologyBadge_SelectPet_C:_InitComboBox()
  local comboBoxData = _G.NRCCommonDropDownListData()
  comboBoxData.Btn_LeftHandler = self.OnClickFilterButton
  comboBoxData.Btn_MidHandler = self.OnClickSortBtnClick
  comboBoxData.Btn_RightHandler = self.OnClickSwitchOrderButton
  comboBoxData.IsComboBox = false
  comboBoxData.Call = self
  self.ComboBox:SetPanelInfo(comboBoxData)
end

function UMG_HerbologyBadge_SelectPet_C:OnClickFilterButton()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.BattleRogue)
end

function UMG_HerbologyBadge_SelectPet_C:OnClickSortBtnClick()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSortPanel, self.curSortRuleType, PetUIModuleEnum.OpenSortType.BattleRogue)
end

function UMG_HerbologyBadge_SelectPet_C:OnClickSwitchOrderButton()
  self.isAscending = not self.isAscending
  self:OnPetSort(self.curSortRuleType)
end

function UMG_HerbologyBadge_SelectPet_C:_InitPanel()
  local petDataList = _G.DataModelMgr.PlayerDataModel:GetPetData()
  if not petDataList then
    return
  end
  self.curPetDataList = {}
  for _, petinfo in ipairs(petDataList) do
    if petinfo.base_conf_id then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petinfo.base_conf_id)
      if petBaseConf then
        table.insert(self.curPetDataList, petinfo)
      end
    end
  end
  local filteredList = self:_FilterPet()
  self:_UpdateGridView(filteredList)
end

function UMG_HerbologyBadge_SelectPet_C:_UpdateGridView(petDataList)
  local sortedList = self:_SortPet(petDataList)
  local grassPetInfoList = {}
  for _, petinfo in ipairs(sortedList) do
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petinfo.base_conf_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      table.insert(grassPetInfoList, {
        IconListInfo = petinfo.level,
        PetData = {
          level = petinfo.level,
          gid = petinfo.gid,
          PetIcon = modelConf,
          BaseConfId = petinfo.base_conf_id,
          PetBaseInfo = petinfo,
          IsOpenTeam = false,
          pet_status_flags = petinfo.pet_status_flags or 0
        },
        IsHasPet = true,
        IsFree = false,
        IsbMultipleChoice = false
      })
    end
  end
  if #grassPetInfoList > 0 then
    self.NRCSwitcher_511:SetActiveWidgetIndex(0)
    self.GridView1:InitList(grassPetInfoList)
    self.GridView1:SelectItemByIndex(0)
    if not self.bConfirmPanelInited then
      self.bConfirmPanelInited = true
      self.ConfirmPanel:OnActive(grassPetInfoList[1], true, nil, nil, false, true)
    else
      self.ConfirmPanel:PetSkillChangeToBaseInfo(grassPetInfoList[1].PetData)
      self.ConfirmPanel:SetPetInfo(grassPetInfoList[1].PetData)
    end
  else
    self.NRCSwitcher_511:SetActiveWidgetIndex(1)
  end
end

function UMG_HerbologyBadge_SelectPet_C:OnPetSort(index)
  self.curSortRuleType = index
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_BAG_SEQUENCE)
  local cfgDatas = cfgTable:GetAllDatas()
  local text = ""
  for _, v in ipairs(cfgDatas) do
    if v.sequence_default == index then
      text = v.sequence_desc
    end
  end
  self.ComboBox:SetComboText(text)
  local filteredList = self:_FilterPet()
  self:_UpdateGridView(filteredList)
end

function UMG_HerbologyBadge_SelectPet_C:OnPetFilter(typeChooseList)
  self.curFilterRule = typeChooseList
  local filteredList = self:_FilterPet()
  self:_UpdateGridView(filteredList)
end

function UMG_HerbologyBadge_SelectPet_C:OnGridViewItemSelected(item)
  if item and item.PetList then
    self.ConfirmPanel:PetSkillChangeToBaseInfo(item.PetList.PetData)
    self.ConfirmPanel:SetPetInfo(item.PetList.PetData)
  end
end

function UMG_HerbologyBadge_SelectPet_C:OnAnimationFinished(anim)
end

function UMG_HerbologyBadge_SelectPet_C:_FilterPet()
  if not self.curFilterRule then
    return self.curPetDataList
  end
  local typeChooseList = self.curFilterRule
  local departmentFilter = {}
  local departList = {}
  if typeChooseList.DepartmentFilter then
    for _, v in pairs(typeChooseList.DepartmentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(departmentFilter, _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value])
      end
    end
  end
  if #departmentFilter > 0 then
    for i = 1, #self.curPetDataList do
      if self.curPetDataList[i] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.curPetDataList[i].base_conf_id)
        if petBaseConf then
          for k = 1, #petBaseConf.unit_type do
            for j = 1, #departmentFilter do
              if petBaseConf.unit_type[k] == departmentFilter[j] and not self:HasGid(self.curPetDataList[i].gid, departList) then
                table.insert(departList, self.curPetDataList[i])
              end
            end
          end
        end
      end
    end
  else
    departList = self.curPetDataList
  end
  local talentFilter = {}
  local talentList = {}
  if typeChooseList.TalentFilter then
    for _, v in pairs(typeChooseList.TalentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(talentFilter, _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value])
      end
    end
  end
  if #talentFilter > 0 then
    for i = 1, #departList do
      for j = 1, #talentFilter do
        if departList[i].talent_rank == talentFilter[j] then
          table.insert(talentList, departList[i])
          break
        end
      end
    end
  else
    talentList = departList
  end
  local naturePositiveEffectFilter = {}
  local naturePositiveEffectList = {}
  if typeChooseList.NaturePositiveEffectFilter then
    for _, v in pairs(typeChooseList.NaturePositiveEffectFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(naturePositiveEffectFilter, _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value])
      end
    end
  end
  if #naturePositiveEffectFilter > 0 then
    for i = 1, #talentList do
      local naturePositive = talentList[i].changed_nature_pos_attr_type
      if not naturePositive or 0 == naturePositive then
        naturePositive = _G.DataConfigManager:GetNatureConf(talentList[i].nature).positive_effect
      else
        naturePositive = self:GetChangeAttrReqEnum(naturePositive)
      end
      for j = 1, #naturePositiveEffectFilter do
        if naturePositive == naturePositiveEffectFilter[j] then
          table.insert(naturePositiveEffectList, talentList[i])
          break
        end
      end
    end
  else
    naturePositiveEffectList = talentList
  end
  local attributeFilter = {}
  local attributeList = {}
  if typeChooseList.AttributeFilter then
    for _, v in pairs(typeChooseList.AttributeFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(attributeFilter, _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value])
      end
    end
  end
  if #attributeFilter > 0 then
    for i = 1, #naturePositiveEffectList do
      for j = 1, #attributeFilter do
        if attributeFilter[j] == _G.Enum.AttributeType.AT_HPMAX and naturePositiveEffectList[i].attribute_info.hp.talent and naturePositiveEffectList[i].attribute_info.hp.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYATK and naturePositiveEffectList[i].attribute_info.attack.talent and naturePositiveEffectList[i].attribute_info.attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEATK and naturePositiveEffectList[i].attribute_info.special_attack.talent and naturePositiveEffectList[i].attribute_info.special_attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYDEF and naturePositiveEffectList[i].attribute_info.defense.talent and naturePositiveEffectList[i].attribute_info.defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEDEF and naturePositiveEffectList[i].attribute_info.special_defense.talent and naturePositiveEffectList[i].attribute_info.special_defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEED and naturePositiveEffectList[i].attribute_info.speed.talent and naturePositiveEffectList[i].attribute_info.speed.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
      end
    end
  else
    attributeList = naturePositiveEffectList
  end
  local PartnerMarkerFilter = {}
  local PartnerMarkerList = {}
  if typeChooseList.PartnerMarkerFilter then
    for _, v in pairs(typeChooseList.PartnerMarkerFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(PartnerMarkerFilter, _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value])
      end
    end
  end
  if #PartnerMarkerFilter > 0 then
    for i = 1, #attributeList do
      for j = 1, #PartnerMarkerFilter do
        if attributeList[i].partner_mark == PartnerMarkerFilter[j] then
          table.insert(PartnerMarkerList, attributeList[i])
          break
        end
      end
    end
  else
    PartnerMarkerList = attributeList
  end
  local SpecialityFilter = {}
  local SpecialityList = {}
  if typeChooseList.SpecialityFilter then
    for _, v in pairs(typeChooseList.SpecialityFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        table.insert(SpecialityFilter, v.data.filter_enum_value)
      end
    end
  end
  if #SpecialityFilter > 0 then
    for i = 1, #PartnerMarkerList do
      for j = 1, #SpecialityFilter do
        if PartnerMarkerList[i].speciality_id then
          local petTalentConf = _G.DataConfigManager:GetPetTalentConf(PartnerMarkerList[i].speciality_id)
          if petTalentConf and petTalentConf.filter_enum_value == SpecialityFilter[j] then
            table.insert(SpecialityList, PartnerMarkerList[i])
            break
          end
        end
      end
    end
  else
    SpecialityList = PartnerMarkerList
  end
  return SpecialityList
end

function UMG_HerbologyBadge_SelectPet_C:_SortPet(filteredPetDataList)
  local list = {}
  for _, v in ipairs(filteredPetDataList) do
    table.insert(list, v)
  end
  table.stableSort(list, function(a, b)
    return a.gid < b.gid
  end)
  table.stableSort(list, function(a, b)
    return self:Compare(a, b)
  end)
  if self.isAscending then
    table.reverse(list)
  end
  return list
end

function UMG_HerbologyBadge_SelectPet_C:Compare(a, b)
  if self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN then
    return a.level > b.level
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_CATCH_DOWN then
    return a.add_time > b.add_time
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_HP_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_HPMAX].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_HPMAX].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_PHYATK_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYATK].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYATK].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEATK_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEATK].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEATK].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_PHYDEF_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYDEF].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYDEF].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEDEF_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEDEF].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEDEF].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEED_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEED].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEED].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_RARITY_DOWN then
    return true
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_TALENT_DOWN then
    return a.talent_rank > b.talent_rank
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_EFFORT_LEVEL_DOWN then
    local aGrowTime = a.grow_times or 0
    local bGrowTime = b.grow_times or 0
    return aGrowTime > bGrowTime
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_COLLECTION_DOWN then
    return a.partner_mark > b.partner_mark
  else
    return false
  end
end

function UMG_HerbologyBadge_SelectPet_C:HasGid(gid, tbl)
  if not tbl then
    return false
  end
  for i = 1, #tbl do
    if tbl[i].gid == gid then
      return true
    end
  end
  return false
end

function UMG_HerbologyBadge_SelectPet_C:GetChangeAttrReqEnum(attribute)
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

function UMG_HerbologyBadge_SelectPet_C:OnItemSelected()
end

function UMG_HerbologyBadge_SelectPet_C:OnPetDataUpdate(newPetData)
  if not newPetData then
    return
  end
  local latestPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(newPetData.gid) or newPetData
  for i, petData in ipairs(self.curPetDataList) do
    if petData.gid == newPetData.gid then
      self.curPetDataList[i] = latestPetData
      break
    end
  end
  local itemCount = self.GridView1:GetItemCount()
  for i = 0, itemCount - 1 do
    local item = self.GridView1:GetItemByIndex(i)
    if item and item.PetList and item.PetList.PetData and item.PetList.PetData.gid == newPetData.gid then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(latestPetData.base_conf_id)
      if petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        item.PetList.IconListInfo = latestPetData.level
        item.PetList.PetData.level = latestPetData.level
        item.PetList.PetData.PetIcon = modelConf
        item.PetList.PetData.BaseConfId = latestPetData.base_conf_id
        item.PetList.PetData.PetBaseInfo = latestPetData
        item.PetList.PetData.pet_status_flags = latestPetData.pet_status_flags or 0
        item:SetData()
      end
      break
    end
  end
  if self.ConfirmPanel and self.ConfirmPanel.petData and self.ConfirmPanel.petData.gid == newPetData.gid then
    self.ConfirmPanel:OnPetDataUpdate(newPetData)
  end
end

return UMG_HerbologyBadge_SelectPet_C
