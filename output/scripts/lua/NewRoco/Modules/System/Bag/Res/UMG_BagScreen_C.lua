local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local UMG_BagScreen_C = _G.NRCPanelBase:Extend("UMG_BagScreen_C")

function UMG_BagScreen_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self:OnAddEventListener()
end

function UMG_BagScreen_C:OnActive(filterList, confName, filterCondition, LimitFilterTypes)
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_BagScreen_C:OnActive")
  self.FilterItemList = filterList
  self.ConfName = confName
  self.LimitTypes = LimitFilterTypes or {}
  self.data = self.module:GetData("BagModuleData")
  self.genderList = {}
  self.specialityList = {}
  self.PetMarkList = {}
  self.petTeamList = {}
  self.categoryList = {}
  self.attributeList = {}
  self.talentList = {}
  self.natureList = {}
  self.PetSeasonList = {}
  self.selfAttribute = {}
  self.filterTypeConditionDic = {}
  self.isShowReset = false
  self:OnChangeBtnLeft()
  self:InitPanel(confName)
  self:LoadAnimation(0)
  self:RevertLastSelectList(filterCondition)
  self:SetCommonPopUpInfo()
end

function UMG_BagScreen_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnClickFilterItem, self.OnClickFilterItem)
end

function UMG_BagScreen_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnBtn1)
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnBtn2)
  self:AddButtonListener(self.OnOffButton, self.OnToggleButton)
  _G.NRCEventCenter:RegisterEvent("UMG_BagScreen_C", self, BagModuleEvent.OnClickFilterItem, self.OnClickFilterItem)
end

function UMG_BagScreen_C:InitFilterLists()
  local petinfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  local departAllList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SKILLMACHINE_FILTER_CONF):GetAllDatas()
  local departList = {}
  local filterList = {}
  for i, v in pairs(departAllList) do
    if v.filter_type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
      table.insert(departList, v)
    end
  end
  for i, v in pairs(departAllList) do
    if v.filter_type == _G.Enum.FilterRule.FIL_SKILL_TYPE then
      table.insert(filterList, departAllList[i])
    end
  end
  self.petList:InitGridView(petinfoList)
  self.DepartmentList:InitGridView(departList)
  self.SkillTypeList:InitGridView(filterList)
  self:RevertLastSelectList()
end

function UMG_BagScreen_C:InitPanel(confName)
  local departAllList = _G.DataConfigManager:GetTable(confName):GetAllDatas()
  local isShowNatureLine = true
  for i, v in pairs(departAllList) do
    if v.filter_type == _G.Enum.FilterRule.FIL_LEARNABLE then
      if self:IsLimit(_G.Enum.FilterRule.FIL_LEARNABLE) then
        self:CreatePetTeamFilter()
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
      if self:IsLimit(_G.Enum.FilterRule.FIL_SKILLDAM_TYPE) then
        self:CreateCategoryFilter(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_SKILL_TYPE then
      if self:IsLimit(_G.Enum.FilterRule.FIL_SKILL_TYPE) then
        self:CreateAttributeFilter(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_TALENT_TYPE then
      if self:IsLimit(_G.Enum.FilterRule.FIL_TALENT_TYPE) then
        self:CreateTalentFilter(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
      if self:IsLimit(_G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT) then
        self:CreateNatureFilter(v)
        isShowNatureLine = false
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
      if self:IsLimit(_G.Enum.FilterRule.FIL_SELF_ATTRIBUTE) then
        self:CreateSelfAttributeFilter(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_PET_GENDER then
      if self:IsLimit(_G.Enum.FilterRule.FIL_PET_GENDER) then
        self:CreatePetGender(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_PET_TALENT then
      if self:IsLimit(_G.Enum.FilterRule.FIL_PET_TALENT) then
        self:CreatePetSpeciality(v)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_PET_MARK then
      if self:IsLimit(_G.Enum.FilterRule.FIL_PET_MARK) then
        self:CreatePetMark(v, true)
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_SHINING then
      if self:IsLimit(_G.Enum.FilterRule.FIL_SHINING) then
        self.IsFilterShining = _G.Enum.FilterShining.FS_NONE
      end
    elseif v.filter_type == _G.Enum.FilterRule.FIL_SEASON and self:IsLimit(_G.Enum.FilterRule.FIL_SEASON) then
      self:CreatePetSeason(v)
    end
  end
  self:ShowAllFilterList()
end

function UMG_BagScreen_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtn2
  CommonPopUpData.Btn_RightHandler = self.OnBtn1
  CommonPopUpData.ClosePanelHandler = self.OnBtnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_BagScreen_C:IsLimit(type)
  if #self.LimitTypes > 0 then
    for i = 1, #self.LimitTypes do
      local limitType = self.LimitTypes[i]
      if limitType == type then
        return true
      end
    end
    return false
  end
  return true
end

function UMG_BagScreen_C:ShowAllFilterList()
  local lastListIndex = 0
  local isShowGender = #self.genderList > 0
  lastListIndex = isShowGender and 1 or lastListIndex
  local isShowPetTeam = #self.petTeamList > 0 and self.data.displayMode ~= BagModuleEnum.DisplayMode.SkillMachine
  lastListIndex = isShowPetTeam and 2 or lastListIndex
  local isShowCategory = #self.categoryList > 0
  lastListIndex = isShowCategory and 3 or lastListIndex
  local isShowAttribute = #self.attributeList > 0
  lastListIndex = isShowAttribute and 4 or lastListIndex
  local isShowTalent = #self.talentList > 0
  lastListIndex = isShowTalent and 5 or lastListIndex
  local isShowNature = #self.natureList > 0
  lastListIndex = isShowNature and 6 or lastListIndex
  local isShowSelfAttribute = #self.selfAttribute > 0
  lastListIndex = isShowSelfAttribute and 6 or lastListIndex
  local isShowSpeciality = #self.specialityList > 0
  lastListIndex = isShowSpeciality and 7 or lastListIndex
  local isShowPetMark = #self.PetMarkList > 0
  lastListIndex = isShowPetMark and 8 or lastListIndex
  local isShowDifferentColor = self.IsFilterShining ~= nil
  lastListIndex = isShowDifferentColor and 9 or lastListIndex
  local isShowSeason = #self.PetSeasonList > 0
  lastListIndex = isShowSeason and 10 or lastListIndex
  self.NRCText_5:SetVisibility(isShowGender and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.Gender:SetVisibility(isShowGender and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_188:SetVisibility(isShowGender and 1 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_42:SetVisibility(isShowPetTeam and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.petList:SetVisibility(isShowPetTeam and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_188:SetVisibility(isShowPetTeam and 2 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText:SetVisibility(isShowCategory and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.DepartmentList:SetVisibility(isShowCategory and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_1:SetVisibility(isShowCategory and 3 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_1:SetVisibility(isShowAttribute and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.SkillTypeList:SetVisibility(isShowAttribute and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_2:SetVisibility(isShowAttribute and 4 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_2:SetVisibility(isShowTalent and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.GiftList:SetVisibility(isShowTalent and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_3:SetVisibility(isShowTalent and 5 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_3:SetVisibility(isShowNature and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.EnhancingPersonTypeList:SetVisibility(isShowNature and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_4:SetVisibility(isShowNature and 6 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_4:SetVisibility(isShowSelfAttribute and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.PersonalValueList:SetVisibility(isShowSelfAttribute and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_6:SetVisibility(isShowSpeciality and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.StrongPoint:SetVisibility(isShowSpeciality and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.PartnerMarker:SetVisibility(isShowPetMark and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_7:SetVisibility(isShowPetMark and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage:SetVisibility(isShowPetMark and 8 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_5:SetVisibility(isShowAttribute and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCImage_8:SetVisibility(isShowSeason and 9 ~= lastListIndex and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.DifferentColorsList:SetVisibility(isShowSeason and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.NRCText_9:SetVisibility(isShowSeason and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if isShowGender then
    self.Gender:InitGridView(self.genderList)
  end
  if isShowPetTeam then
    self.petList:InitGridView(self.petTeamList)
  end
  if isShowCategory then
    self.DepartmentList:InitGridView(self.categoryList)
  end
  if isShowAttribute then
    self.SkillTypeList:InitGridView(self.attributeList)
  end
  if isShowTalent then
    self.GiftList:InitGridView(self.talentList)
  end
  if isShowNature then
    self.EnhancingPersonTypeList:InitGridView(self.natureList)
  end
  if isShowSelfAttribute then
    self.PersonalValueList:InitGridView(self.selfAttribute)
  end
  if isShowSpeciality then
    self.StrongPoint:InitGridView(self.specialityList)
  end
  if isShowPetMark then
    self.PartnerMarker:InitGridView(self.PetMarkList)
  else
    self.PartnerMarker:InitGridView({})
  end
  self.DifferentColorScreening:SetVisibility(isShowDifferentColor and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.nrctext_8:SetVisibility(isShowDifferentColor and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if isShowSeason then
    self.DifferentColorsList:InitGridView(self.PetSeasonList)
  end
end

function UMG_BagScreen_C:CreatePetGender(conf)
  table.insert(self.genderList, conf)
end

function UMG_BagScreen_C:CreatePetSpeciality(conf)
  table.insert(self.specialityList, conf)
end

function UMG_BagScreen_C:CreatePetMark(conf, isWhiteColor)
  table.insert(self.PetMarkList, {
    data = conf,
    type = 4,
    InitSelect = false,
    NoEvent = true,
    isWhite = isWhiteColor
  })
end

function UMG_BagScreen_C:CreatePetSeason(conf)
  table.insert(self.PetSeasonList, conf)
end

function UMG_BagScreen_C:CreatePetTeamFilter()
  if self.petTeamList == nil or 0 == #self.petTeamList then
    self.petTeamList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    self.petList:InitGridView(self.petTeamList)
  end
end

function UMG_BagScreen_C:CreateCategoryFilter(conf)
  table.insert(self.categoryList, conf)
end

function UMG_BagScreen_C:CreateAttributeFilter(conf)
  table.insert(self.attributeList, conf)
end

function UMG_BagScreen_C:CreateTalentFilter(conf)
  table.insert(self.talentList, conf)
end

function UMG_BagScreen_C:CreateNatureFilter(conf)
  table.insert(self.natureList, conf)
end

function UMG_BagScreen_C:CreateSelfAttributeFilter(conf)
  table.insert(self.selfAttribute, conf)
end

function UMG_BagScreen_C:RevertLastSelectList(filterCondition)
  if filterCondition then
    if filterCondition.FilterGenderCondition then
      for i = 1, self.Gender:GetItemCount() do
        local item = self.Gender:GetItemByIndex(i - 1)
        local conf = item.conf
        for j = 1, #filterCondition.FilterGenderCondition do
          local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
          if filterCondition.FilterGenderCondition[j] == enum then
            local idx = i - 1
            local itm = self.Gender:GetItemByIndex(idx)
            itm:OnNotPlaySound()
            self.Gender:SelectItemByIndex(i - 1)
          end
        end
      end
    end
    if filterCondition.FilterSpecialityCondition then
      for i = 1, self.StrongPoint:GetItemCount() do
        local item = self.StrongPoint:GetItemByIndex(i - 1)
        local enum = item.data and item.data.filter_enum_value
        for j = 1, #filterCondition.FilterSpecialityCondition do
          if filterCondition.FilterSpecialityCondition[j] == enum then
            local idx = i - 1
            local itm = self.StrongPoint:GetItemByIndex(idx)
            itm:OnNotPlaySound()
            self.StrongPoint:SelectItemByIndex(i - 1)
          end
        end
      end
    end
    if filterCondition.FilterPetMarkCondition then
      for i = 1, self.PartnerMarker:GetItemCount() do
        local item = self.PartnerMarker:GetItemByIndex(i - 1)
        local enum = _G.Enum[item.data.filter_enum_name][item.data.filter_enum_value]
        for j = 1, #filterCondition.FilterPetMarkCondition do
          if filterCondition.FilterPetMarkCondition[j] == enum then
            local idx = i - 1
            local itm = self.PartnerMarker:GetItemByIndex(idx)
            itm:OnNotPlaySound()
            self.PartnerMarker:SelectItemByIndex(i - 1)
          end
        end
      end
    end
    local deepCopyList = {}
    if filterCondition.FilterPetCondition and #filterCondition.FilterPetCondition > 0 then
      deepCopyList = table.deepCopy(filterCondition.FilterPetCondition, deepCopyList, false)
    end
    if deepCopyList then
      for i = 1, self.petList:GetItemCount() do
        local item = self.petList:GetItemByIndex(i - 1)
        for j = 1, #deepCopyList do
          if not item.clickToggle and deepCopyList[j].base_conf_id == item.PetBaseId then
            self.petList:SelectItemByIndex(i - 1)
            table.remove(deepCopyList, j)
          end
        end
      end
    end
    if filterCondition.FilterDepartCondition then
      for i = 1, self.DepartmentList:GetItemCount() do
        local item = self.DepartmentList:GetItemByIndex(i - 1)
        local conf = item.conf or item.data
        for j = 1, #filterCondition.FilterDepartCondition do
          local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
          if filterCondition.FilterDepartCondition[j] == enum then
            local idx = i - 1
            local itm = self.DepartmentList:GetItemByIndex(idx)
            itm:OnNotPlaySound()
            self.DepartmentList:SelectItemByIndex(idx)
          end
        end
      end
    end
    if filterCondition.FilterClassifyCondition then
      for i = 1, self.SkillTypeList:GetItemCount() do
        local item = self.SkillTypeList:GetItemByIndex(i - 1)
        local conf = item.conf
        for j = 1, #filterCondition.FilterClassifyCondition do
          local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
          if filterCondition.FilterClassifyCondition[j] == enum then
            self.SkillTypeList:SelectItemByIndex(i - 1)
          end
        end
      end
    end
    if filterCondition.FilterNatureCondition then
      for i = 1, self.EnhancingPersonTypeList:GetItemCount() do
        local item = self.EnhancingPersonTypeList:GetItemByIndex(i - 1)
        local conf = item.data
        if conf then
          for j = 1, #filterCondition.FilterNatureCondition do
            local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
            if filterCondition.FilterNatureCondition[j] == enum then
              self.EnhancingPersonTypeList:SelectItemByIndex(i - 1)
            end
          end
        end
      end
    end
    if filterCondition.FilterAttributeCondition then
      for i = 1, self.PersonalValueList:GetItemCount() do
        local item = self.PersonalValueList:GetItemByIndex(i - 1)
        local conf = item.conf or item.data
        if conf then
          for j = 1, #filterCondition.FilterAttributeCondition do
            local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
            if filterCondition.FilterAttributeCondition[j] == enum then
              self.PersonalValueList:SelectItemByIndex(i - 1)
            end
          end
        end
      end
    end
    if filterCondition.FilterStrongCondition then
      for i = 1, self.StrongPoint:GetItemCount() do
        local item = self.StrongPoint:GetItemByIndex(i - 1)
        local conf = item.conf or item.data
        if conf then
          for j = 1, #filterCondition.FilterStrongCondition do
            local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
            if filterCondition.FilterStrongCondition[j] == enum then
              self.StrongPoint:SelectItemByIndex(i - 1)
            end
          end
        end
      end
    end
    if filterCondition.FilterShiningCondition then
      self.IsFilterShining = filterCondition.FilterShiningCondition
      self.Btnwitcher:SetActiveWidgetIndex(self.IsFilterShining)
      self:OnClickFilterItem(_G.Enum.FilterRule.FIL_SHINING, _G.Enum.FilterShining.FS_ALL_SHINING, self.IsFilterShining == _G.Enum.FilterShining.FS_ALL_SHINING)
    end
    if filterCondition.FilterSeasonCondition and #filterCondition.FilterSeasonCondition > 0 then
      for i = 1, self.DifferentColorsList:GetItemCount() do
        local item = self.DifferentColorsList:GetItemByIndex(i - 1)
        local conf = item.conf or item.data
        if conf then
          for j = 1, #filterCondition.FilterSeasonCondition do
            local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
            if filterCondition.FilterSeasonCondition[j] == enum then
              self.DifferentColorsList:SelectItemByIndex(i - 1)
            end
          end
        end
      end
    end
  end
end

function UMG_BagScreen_C:Filter(filter1, filter2, filter3)
  local filterList = {}
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterPet, filter1, self.FilterItemList)
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterDepart, filter2, filterList)
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterClassify, filter3, filterList)
  return filterList
end

function UMG_BagScreen_C:FilterGender(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData.gender == enum then
          table.insert(bagItemList, itemList[i])
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function UMG_BagScreen_C:FilterSpeciality(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData.filter_enum_value == enum then
          table.insert(bagItemList, itemList[i])
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function UMG_BagScreen_C:FilterPartnerMark(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData.partner_mark == enum then
          table.insert(bagItemList, itemList[i])
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function UMG_BagScreen_C:OnFilterPets()
  local filterGender = {}
  local FilterSpeciality
  local FilterPetMark = {}
  local filterPet = {}
  local filterEnum1 = {}
  local filterEnum2 = {}
  local filterNature = {}
  local filterPersonal = {}
  local filterStrong = {}
  local filterSeason = {}
  for i = 1, self.Gender:GetItemCount() do
    local item = self.Gender:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterGender, enum_filter)
    end
  end
  for i = 1, self.StrongPoint:GetItemCount() do
    local item = self.StrongPoint:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_value = item.data.filter_enum_value
      local enum = _G.Enum[item.data.filter_enum_name][item.data.filter_enum_value]
      table.insert(filterStrong, enum)
      if nil == FilterSpeciality then
        FilterSpeciality = {}
        table.insert(FilterSpeciality, enum_value)
      else
        table.insert(FilterSpeciality, enum_value)
      end
    end
  end
  for i = 1, self.PartnerMarker:GetItemCount() do
    local item = self.PartnerMarker:GetItemByIndex(i - 1)
    if true == item.uiData.InitSelect then
      local enum_value = _G.Enum[item.data.filter_enum_name][item.data.filter_enum_value]
      table.insert(FilterPetMark, enum_value)
    end
  end
  for i = 1, self.petList:GetItemCount() do
    local item = self.petList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local petData = item.data
      table.insert(filterPet, petData)
    end
  end
  for i = 1, self.DepartmentList:GetItemCount() do
    local item = self.DepartmentList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterEnum1, enum_filter)
    end
  end
  for i = 1, self.SkillTypeList:GetItemCount() do
    local item = self.SkillTypeList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterEnum2, enum_filter)
    end
  end
  for i = 1, self.EnhancingPersonTypeList:GetItemCount() do
    local item = self.EnhancingPersonTypeList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.data.filter_enum_name
      local enum_value = item.data.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterNature, enum_filter)
    end
  end
  for i = 1, self.PersonalValueList:GetItemCount() do
    local item = self.PersonalValueList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.data.filter_enum_name
      local enum_value = item.data.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterPersonal, enum_filter)
    end
  end
  for i = 1, self.DifferentColorsList:GetItemCount() do
    local item = self.DifferentColorsList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterSeason, enum_filter)
    end
  end
  local condition = {}
  if self.LimitTypes and #self.LimitTypes > 0 then
    for i = 1, #self.LimitTypes do
      local limitEnum = self.LimitTypes[i]
      if limitEnum == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
        condition.FilterDepartCondition = filterEnum1
      elseif limitEnum == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
        condition.FilterNatureCondition = filterNature
      elseif limitEnum == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
        condition.FilterAttributeCondition = filterPersonal
      elseif limitEnum == _G.Enum.FilterRule.FIL_PET_MARK then
        condition.FilterPetMarkCondition = FilterPetMark
      elseif limitEnum == _G.Enum.FilterRule.FIL_PET_TALENT then
        condition.FilterStrongCondition = filterStrong
      elseif limitEnum == _G.Enum.FilterRule.FIL_SEASON then
        condition.FilterSeasonCondition = filterSeason
      end
    end
  else
    condition.FilterDepartCondition = filterEnum1
    condition.FilterGenderCondition = filterGender
    condition.FilterSpecialityCondition = FilterSpeciality
    condition.FilterPetMarkCondition = FilterPetMark
    condition.FilterNatureCondition = filterNature
    condition.FilterAttributeCondition = filterPersonal
    condition.FilterStrongCondition = filterStrong
    if nil ~= self.IsFilterShining then
      condition.FilterShiningCondition = self.IsFilterShining
    end
    condition.FilterSeasonCondition = filterSeason
  end
  local filterList = {}
  filterList = self:FilterGender(filterGender, self.FilterItemList)
  filterList = self:FilterSpeciality(FilterSpeciality, filterList)
  filterList = self:FilterPartnerMark(FilterPetMark, filterList)
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterDepart, filterEnum1, filterList or {})
  return filterList, condition
end

function UMG_BagScreen_C:OnFilterSkillStone()
  local filterPetGender = {}
  local filterPet = {}
  local filterEnum1 = {}
  local filterEnum2 = {}
  for i = 1, self.Gender:GetItemCount() do
    local item = self.Gender:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local petData = item.data
      table.insert(filterPet, petData)
    end
  end
  for i = 1, self.petList:GetItemCount() do
    local item = self.petList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local petData = item.data
      table.insert(filterPet, petData)
    end
  end
  if self.data.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
    filterPet = self.data.FilterPetCondition
  end
  for i = 1, self.DepartmentList:GetItemCount() do
    local item = self.DepartmentList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterEnum1, enum_filter)
    end
  end
  for i = 1, self.SkillTypeList:GetItemCount() do
    local item = self.SkillTypeList:GetItemByIndex(i - 1)
    if item.clickToggle == true then
      local enum_type = item.conf.filter_enum_name
      local enum_value = item.conf.filter_enum_value
      local enum_filter = _G.Enum[enum_type][enum_value]
      table.insert(filterEnum2, enum_filter)
    end
  end
  local filterList = {}
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterPet, filterPet, self.FilterItemList)
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterDepart, filterEnum1, filterList)
  filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterClassify, filterEnum2, filterList)
  local condition = {}
  condition.FilterPetCondition = filterPet
  condition.FilterDepartCondition = filterEnum1
  condition.FilterClassifyCondition = filterEnum2
  return filterList, condition
end

function UMG_BagScreen_C:OnBtn2()
  if self.isShowReset == false then
    self:OnBtnClose()
    return
  end
  self.isShowReset = false
  self:OnChangeBtnLeft()
  self.filterTypeConditionDic = {}
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Bag_BXTips_C:OnClose")
  if self.data.displayMode ~= BagModuleEnum.DisplayMode.SkillMachine then
    for i = 1, self.petList:GetItemCount() do
      local item = self.petList:GetItemByIndex(i - 1)
      item.clickToggle = false
      item.Switcher:SetActiveWidgetIndex(1)
      if item.SortText then
        item.SortText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
      end
    end
  end
  for i = 1, self.Gender:GetItemCount() do
    local item = self.Gender:GetItemByIndex(i - 1)
    item.clickToggle = false
    item.Switcher:SetActiveWidgetIndex(1)
    if item.SortText then
      item.SortText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    end
  end
  for i = 1, self.StrongPoint:GetItemCount() do
    local item = self.StrongPoint:GetItemByIndex(i - 1)
    if item.clickToggle then
      item.clickToggle = false
      item:PlayAnimation(item.Cancel)
      if item.Text then
        item.Text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
      end
    end
  end
  if self.PetMarkList and #self.PetMarkList > 0 then
    for i = 1, self.PartnerMarker:GetItemCount() do
      local item = self.PartnerMarker:GetItemByIndex(i - 1)
      if item and item.uiData and item.uiData.InitSelect then
        item.uiData.InitSelect = false
        item:PlayAnimation(item.Cancel)
        item.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
        item.Text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
      end
    end
  end
  for i = 1, self.DepartmentList:GetItemCount() do
    local item = self.DepartmentList:GetItemByIndex(i - 1)
    item.clickToggle = false
    item.Switcher:SetActiveWidgetIndex(1)
    if item.SortText then
      item.SortText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    end
  end
  for i = 1, self.SkillTypeList:GetItemCount() do
    local item = self.SkillTypeList:GetItemByIndex(i - 1)
    item.clickToggle = false
    item.Switcher:SetActiveWidgetIndex(1)
    if item.SortText then
      item.SortText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    end
  end
  if self.selfAttribute and #self.selfAttribute > 0 then
    for i = 1, self.PersonalValueList:GetItemCount() do
      local item = self.PersonalValueList:GetItemByIndex(i - 1)
      item.clickToggle = false
      item.SelectSwitcher:SetActiveWidgetIndex(0)
    end
  end
  if self.natureList and #self.natureList > 0 then
    for i = 1, self.EnhancingPersonTypeList:GetItemCount() do
      local item = self.EnhancingPersonTypeList:GetItemByIndex(i - 1)
      item.clickToggle = false
      item:ResetBg()
    end
  end
  if self.IsFilterShining ~= nil then
    self.IsFilterShining = _G.Enum.FilterShining.FS_NONE
    self.Btnwitcher:SetActiveWidgetIndex(self.IsFilterShining)
  end
  if self.PetSeasonList and #self.PetSeasonList > 0 then
    for i = 1, self.DifferentColorsList:GetItemCount() do
      local item = self.DifferentColorsList:GetItemByIndex(i - 1)
      item:ResetBg()
    end
  end
end

function UMG_BagScreen_C:OnBtn1()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Bag_BXTips_C:OnClose")
  local filterList, condition
  if self.ConfName == _G.DataConfigManager.ConfigTableId.SKILLMACHINE_FILTER_CONF then
    filterList, condition = self:OnFilterSkillStone()
  else
    filterList, condition = self:OnFilterPets()
  end
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.OnFilter, filterList, condition)
  self:OnBtnClose()
end

function UMG_BagScreen_C:OnToggleButton()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_BagScreen_C:OnToggleButton")
  self.IsFilterShining = self.IsFilterShining == _G.Enum.FilterShining.FS_ALL_SHINING and _G.Enum.FilterShining.FS_NONE or _G.Enum.FilterShining.FS_ALL_SHINING
  self.Btnwitcher:SetActiveWidgetIndex(self.IsFilterShining)
  self:OnClickFilterItem(_G.Enum.FilterRule.FIL_SHINING, _G.Enum.FilterShining.FS_ALL_SHINING, self.IsFilterShining == _G.Enum.FilterShining.FS_ALL_SHINING)
end

function UMG_BagScreen_C:OnClickFilterItem(filter_type, enum, isToogle)
  if self.filterTypeConditionDic[filter_type] == nil then
    self.filterTypeConditionDic[filter_type] = {}
  end
  self.filterTypeConditionDic[filter_type][enum] = isToogle
  local isShowReset = false
  for _, filterTypeDic in pairs(self.filterTypeConditionDic) do
    for _, v in pairs(filterTypeDic) do
      if v then
        isShowReset = true
        break
      end
    end
  end
  self.isShowReset = isShowReset
  self:OnChangeBtnLeft()
end

function UMG_BagScreen_C:OnChangeBtnLeft()
  if self.isShowReset then
    self.Btn_Left:SetBtnText(LuaText.umg_rename_3)
  else
    self.Btn_Left:SetBtnText(LuaText.umg_dialog_1)
  end
end

function UMG_BagScreen_C:OnBtnClose()
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.OnBagScreenClose)
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_BagScreen_C:OnActive")
  self:PlayAnimation(self.Close)
end

function UMG_BagScreen_C:OnAnimationFinished(aim)
  if aim == self.Close then
    self:DoClose()
  end
end

return UMG_BagScreen_C
