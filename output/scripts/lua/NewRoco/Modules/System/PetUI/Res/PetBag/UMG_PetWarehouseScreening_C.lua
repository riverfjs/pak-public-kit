local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetWarehouseScreening_C = _G.NRCPanelBase:Extend("UMG_PetWarehouseScreening_C")

function UMG_PetWarehouseScreening_C:OnDeactive()
end

function UMG_PetWarehouseScreening_C:OnAddEventListener()
  self:AddButtonListener(self.backBtn.btnClose, self.OnBackBtnClick)
  self:AddButtonListener(self.ReleaseLifeBtn.btnLevelUp, self.OnReleaseLifeBtnClick)
  self:AddButtonListener(self.AddBtn.btnLevelUp, self.OnAddBtnClick)
  self:AddButtonListener(self.AddBtn_1.btnLevelUp, self.OnAddBtn1Click)
  self:AddButtonListener(self.AddBtn_2.btnLevelUp, self.OnAddBtn2Click)
  self:AddButtonListener(self.AddBtn_3.btnLevelUp, self.OnAddBtn3Click)
  self:AddButtonListener(self.AddBtn_4.btnLevelUp, self.OnAddBtn4Click)
  self:AddButtonListener(self.Btn_Reset.btnLevelUp, self.OnBtnResetClick)
  self:AddButtonListener(self.Btn_Confirm.btnLevelUp, self.OnBtnConfirmClick)
  self:AddButtonListener(self.NRCButton_82, self.OnBtnConfirmClick)
  self:AddButtonListener(self.TimeRewindTipsBtn.btnLevelUp, self.OnTimeRewindTipsBtnClick)
end

function UMG_PetWarehouseScreening_C:OnConstruct()
  self.FilterCondition = {
    FilterPetIdCondition = {},
    FilterTalentCondition = {},
    FilterDepartCondition = {},
    FilterNatureCondition = {},
    FilterAttributeCondition = {},
    FilterPetMarkCondition = {},
    FilterStrongCondition = {},
    FilterTimeCondition = {},
    FilterTraceBackCondition = {}
  }
  self.TalentConfigs = {}
  self.DepartConfigs = {}
  self.NatureConfigs = {}
  self.AttributeConfigs = {}
  self.PetMarkConfigs = {}
  self.StrongConfigs = {}
  self.TimeConfigs = {}
  self.TraceBackConfigs = {}
  local fileters = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_FILTER_CONF)
  if fileters then
    self.PetFilterConfs = fileters:GetAllDatas()
  end
  for _, conf in pairs(self.PetFilterConfs) do
    if conf.filter_type == _G.Enum.FilterRule.FIL_TALENT_TYPE then
      table.insert(self.TalentConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
      table.insert(self.DepartConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
      table.insert(self.NatureConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
      table.insert(self.AttributeConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_PET_MARK then
      table.insert(self.PetMarkConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_PET_TALENT then
      table.insert(self.StrongConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_CATCH_TIME then
      table.insert(self.TimeConfigs, conf)
    end
    if conf.filter_type == _G.Enum.FilterRule.FIL_ROLLBACK_TYPE then
      table.insert(self.TraceBackConfigs, conf)
    end
  end
  self.NRCText_2:SetText(LuaText.filter_attribute_list)
  local isAttributeOpen = self.module:FoldOrOpenRightPanel()
  self:DispatchEvent(PetUIModuleEvent.AttributeChangeSetEggBtn, isAttributeOpen)
  self:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseScreening_C", self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseScreening_C", self, PetUIModuleEvent.OnChangePetBagFilterCondition, self.OnChangePetBagFilterCondition)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseScreening_C", self, PetUIModuleEvent.OnChangePetBagFilterToggle, self.OnChangePetBagFilterToggle)
end

function UMG_PetWarehouseScreening_C:OnDestruct()
  self.module:OnSavePetBagChildrenPanelState("Screening", false)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnChangePetBagFilterCondition, self.OnChangePetBagFilterCondition)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnChangePetBagFilterToggle, self.OnChangePetBagFilterToggle)
end

function UMG_PetWarehouseScreening_C:OnActive()
  self.petList:InitGridView({})
  self.FilterList:InitGridView({})
  self.EnhancingPersonTypeList:InitGridView({})
  self.PersonalValueList:InitGridView({})
  self.PartnerMarker:InitGridView({})
  self.StrongPoint:InitGridView({})
  self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AddBtn_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCButton_82:SetVisibility(UE4.ESlateVisibility.Visible)
  local CacheFilterData = self.module:GetCachePetBoxFilterData()
  if CacheFilterData and CacheFilterData.Condition then
    self.FilterCondition = table.deepCopy(CacheFilterData.Condition)
  end
  self.GiftList:InitGridView(self.TalentConfigs)
  local timeDatas = {}
  for i = 1, #self.TimeConfigs do
    local data = {
      conf = self.TimeConfigs[i],
      isToggle = true
    }
    table.insert(timeDatas, data)
  end
  self.GainTheTime:InitGridView(timeDatas)
  self.TimeRewindList:InitGridView(self.TraceBackConfigs)
  if #self.TraceBackConfigs > 0 and PetUtils.CheckCurIsInTraceBackTime() then
    self.TimeRewind:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TimeRewind:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.FilterCondition and self.FilterCondition.FilterTraceBackCondition and #self.FilterCondition.FilterTraceBackCondition > 0 then
      self.FilterCondition.FilterTraceBackCondition = {}
    end
  end
  self:SetFilterCondition(self.FilterCondition)
  self.module:SetNewPetBagWarehouseScreeningPanelOpenState(true)
  self:DispatchEvent(PetUIModuleEvent.OnUpdatePetBagEmptyView)
end

function UMG_PetWarehouseScreening_C:OnFilter(filterList, condition)
  self:SetFilterCondition(condition)
  self:ConfirmResult()
end

function UMG_PetWarehouseScreening_C:OnChangePetBagFilterCondition(type, data)
  if type == _G.Enum.FilterRule.FIL_LEARNABLE then
    local petidData = data
    for i = 1, #self.FilterCondition.FilterPetIdCondition do
      if self.FilterCondition.FilterPetIdCondition[i] == petidData.petBaseId then
        table.remove(self.FilterCondition.FilterPetIdCondition, i)
        break
      end
    end
    self:UpdatePetList(self.FilterCondition.FilterPetIdCondition)
  elseif type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
    local enum = data
    for i = 1, #self.FilterCondition.FilterDepartCondition do
      if self.FilterCondition.FilterDepartCondition[i] == enum then
        table.remove(self.FilterCondition.FilterDepartCondition, i)
        break
      end
    end
    self:UpdateDepartList(self.FilterCondition.FilterDepartCondition)
  elseif type == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
    local enum = data
    for i = 1, #self.FilterCondition.FilterNatureCondition do
      if self.FilterCondition.FilterNatureCondition[i] == enum then
        table.remove(self.FilterCondition.FilterNatureCondition, i)
        break
      end
    end
    self:UpdateConditionList(self.FilterCondition.FilterNatureCondition, type)
  elseif type == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
    local enum = data
    for i = 1, #self.FilterCondition.FilterAttributeCondition do
      if self.FilterCondition.FilterAttributeCondition[i] == enum then
        table.remove(self.FilterCondition.FilterAttributeCondition, i)
        break
      end
    end
    self:UpdateAttributeList(self.FilterCondition.FilterAttributeCondition)
  elseif type == _G.Enum.FilterRule.FIL_PET_MARK then
    local enum = data
    for i = 1, #self.FilterCondition.FilterPetMarkCondition do
      if self.FilterCondition.FilterPetMarkCondition[i] == enum then
        table.remove(self.FilterCondition.FilterPetMarkCondition, i)
        break
      end
    end
    self:UpdateConditionList(self.FilterCondition.FilterPetMarkCondition, type)
  elseif type == _G.Enum.FilterRule.FIL_PET_TALENT then
    local enum = data
    for i = 1, #self.FilterCondition.FilterStrongCondition do
      if self.FilterCondition.FilterStrongCondition[i] == enum then
        table.remove(self.FilterCondition.FilterStrongCondition, i)
        break
      end
    end
    self:UpdateStrongList(self.FilterCondition.FilterStrongCondition)
  elseif type == _G.Enum.FilterRule.FIL_CATCH_TIME then
  end
  self:ConfirmResult()
end

function UMG_PetWarehouseScreening_C:OnChangePetBagFilterToggle(type, data, toggle)
  if type == _G.Enum.FilterRule.FIL_TALENT_TYPE then
    for i = 1, #self.TalentConfigs do
      local conf = self.TalentConfigs[i]
      local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
      if enum == data then
        local isHave = false
        for j = 1, #self.FilterCondition.FilterTalentCondition do
          if self.FilterCondition.FilterTalentCondition[j] == enum then
            isHave = true
            if false == toggle then
              table.remove(self.FilterCondition.FilterTalentCondition, j)
            end
          end
        end
        if toggle and not isHave then
          table.insert(self.FilterCondition.FilterTalentCondition, enum)
        end
      end
    end
  elseif type == _G.Enum.FilterRule.FIL_CATCH_TIME then
    for i = 1, #self.TimeConfigs do
      local conf = self.TimeConfigs[i]
      local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
      if enum == data then
        local isHave = false
        for j = 1, #self.FilterCondition.FilterTimeCondition do
          if self.FilterCondition.FilterTimeCondition[j] == enum then
            isHave = true
            if false == toggle then
              table.remove(self.FilterCondition.FilterTimeCondition, j)
            end
          end
        end
        if toggle and not isHave then
          table.insert(self.FilterCondition.FilterTimeCondition, enum)
        end
      end
    end
  elseif type == _G.Enum.FilterRule.FIL_ROLLBACK_TYPE then
    for i = 1, #self.TraceBackConfigs do
      local conf = self.TraceBackConfigs[i]
      local enum = _G.Enum[conf.filter_enum_name][conf.filter_enum_value]
      if enum == data then
        local isHave = false
        for j = 1, #self.FilterCondition.FilterTraceBackCondition do
          if self.FilterCondition.FilterTraceBackCondition[j] == enum then
            isHave = true
            if false == toggle then
              table.remove(self.FilterCondition.FilterTraceBackCondition, j)
            end
          end
        end
        if toggle and not isHave then
          table.insert(self.FilterCondition.FilterTraceBackCondition, enum)
        end
      end
    end
  end
  self:ConfirmResult()
end

function UMG_PetWarehouseScreening_C:SetFilterCondition(condition)
  if condition and self.FilterCondition then
    if condition.FilterPetIdCondition then
      local PetIdCondition = {}
      if self.FilterCondition.FilterPetIdCondition and #self.FilterCondition.FilterPetIdCondition > 0 then
        local dic = {}
        for i = 1, #self.FilterCondition.FilterPetIdCondition do
          table.insert(PetIdCondition, self.FilterCondition.FilterPetIdCondition[i])
          dic[self.FilterCondition.FilterPetIdCondition[i]] = true
        end
        for i = 1, #condition.FilterPetIdCondition do
          if not dic[condition.FilterPetIdCondition[i]] then
            table.insert(PetIdCondition, condition.FilterPetIdCondition[i])
          end
        end
      else
        PetIdCondition = condition.FilterPetIdCondition
      end
      self.FilterCondition.FilterPetIdCondition = PetIdCondition
      self:UpdatePetList(PetIdCondition)
    end
    if condition.FilterTalentCondition then
      self.FilterCondition.FilterTalentCondition = condition.FilterTalentCondition
      self:UpdateTalentList(self.FilterCondition.FilterTalentCondition)
    end
    if condition.FilterDepartCondition then
      self.FilterCondition.FilterDepartCondition = condition.FilterDepartCondition
      self:UpdateDepartList(self.FilterCondition.FilterDepartCondition)
    end
    if condition.FilterNatureCondition then
      self.FilterCondition.FilterNatureCondition = condition.FilterNatureCondition
      self:UpdateConditionList(self.FilterCondition.FilterNatureCondition, _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT)
    end
    if condition.FilterAttributeCondition then
      self.FilterCondition.FilterAttributeCondition = condition.FilterAttributeCondition
      self:UpdateAttributeList(self.FilterCondition.FilterAttributeCondition)
    end
    if condition.FilterPetMarkCondition then
      self.FilterCondition.FilterPetMarkCondition = condition.FilterPetMarkCondition
      self:UpdateConditionList(self.FilterCondition.FilterPetMarkCondition, _G.Enum.FilterRule.FIL_PET_MARK)
    end
    if condition.FilterStrongCondition then
      self.FilterCondition.FilterStrongCondition = condition.FilterStrongCondition
      self:UpdateStrongList(self.FilterCondition.FilterStrongCondition)
    end
    if condition.FilterTimeCondition then
      self.FilterCondition.FilterTimeCondition = condition.FilterTimeCondition
      self:UpdateTimeList(self.FilterCondition.FilterTimeCondition)
    end
    if condition.FilterTraceBackCondition then
      self.FilterCondition.FilterTraceBackCondition = condition.FilterTraceBackCondition
      self:UpdateTraceBackList(self.FilterCondition.FilterTraceBackCondition)
    end
  end
end

function UMG_PetWarehouseScreening_C:UpdatePetList(condition)
  local datas = {}
  for i = 1, #condition do
    local baseId = condition[i]
    local data = {petBaseId = baseId, isShowReduction = true}
    if data then
      table.insert(datas, data)
    end
  end
  self.petList:InitGridView(datas)
end

function UMG_PetWarehouseScreening_C:UpdateTalentList(condition)
  for j = 1, self.GiftList:GetItemCount() do
    local item = self.GiftList:GetItemByIndex(j - 1)
    for i = 1, #condition do
      local conditionEnum = condition[i]
      if item and item.enum == conditionEnum then
        item:OnSelect()
      end
    end
  end
end

function UMG_PetWarehouseScreening_C:UpdateConditionList(condition, enum)
  local datas = {}
  local gridView
  local filterConfs = {}
  if enum == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
    gridView = self.FilterList
    filterConfs = self.DepartConfigs
  elseif enum == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
    gridView = self.EnhancingPersonTypeList
    filterConfs = self.NatureConfigs
  elseif enum == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
    gridView = self.PersonalValueList
    filterConfs = self.AttributeConfigs
  elseif enum == _G.Enum.FilterRule.FIL_PET_MARK then
    gridView = self.PartnerMarker
    filterConfs = self.PetMarkConfigs
  elseif enum == _G.Enum.FilterRule.FIL_PET_TALENT then
    gridView = self.StrongPoint
    filterConfs = self.StrongConfigs
  end
  for i = 1, #condition do
    local enumType = condition[i]
    for _, v in pairs(filterConfs) do
      if _G.Enum[v.filter_enum_name][v.filter_enum_value] == enumType then
        table.insert(datas, v)
      end
    end
  end
  gridView:InitGridView(datas)
end

function UMG_PetWarehouseScreening_C:UpdateStrongList(condition)
  local datas = {}
  for i = 1, #condition do
    local enumType = condition[i]
    for _, v in pairs(self.StrongConfigs) do
      if _G.Enum[v.filter_enum_name][v.filter_enum_value] == enumType then
        local data = {conf = v, isToggle = false}
        table.insert(datas, data)
      end
    end
  end
  self.StrongPoint:InitGridView(datas)
end

function UMG_PetWarehouseScreening_C:UpdateDepartList(condition)
  local datas = {}
  for i = 1, #condition do
    local enumType = condition[i]
    for _, v in pairs(self.DepartConfigs) do
      if _G.Enum[v.filter_enum_name][v.filter_enum_value] == enumType then
        local data = {conf = v, isDepartment = true}
        table.insert(datas, data)
      end
    end
  end
  self.FilterList:InitGridView(datas)
end

function UMG_PetWarehouseScreening_C:UpdateAttributeList(condition)
  local datas = {}
  for i = 1, #condition do
    local enumType = condition[i]
    for _, v in pairs(self.AttributeConfigs) do
      if _G.Enum[v.filter_enum_name][v.filter_enum_value] == enumType then
        local data = {conf = v, isDepartment = false}
        table.insert(datas, data)
      end
    end
  end
  self.PersonalValueList:InitGridView(datas)
end

function UMG_PetWarehouseScreening_C:UpdateTimeList(condition)
  for j = 1, self.GainTheTime:GetItemCount() do
    local item = self.GainTheTime:GetItemByIndex(j - 1)
    for i = 1, #condition do
      local conditionEnum = condition[i]
      if item and item.enum == conditionEnum then
        self.GainTheTime:SelectItemByIndex(j - 1)
      end
    end
  end
end

function UMG_PetWarehouseScreening_C:UpdateTraceBackList(condition)
  for j = 1, self.TimeRewindList:GetItemCount() do
    local item = self.TimeRewindList:GetItemByIndex(j - 1)
    for i = 1, #condition do
      local conditionEnum = condition[i]
      if item and item.enum == conditionEnum then
        self.TimeRewindList:SelectItemByIndex(j - 1)
      end
    end
  end
end

function UMG_PetWarehouseScreening_C:OnBackBtnClick()
  if self:IsAnimationPlaying(self.In) then
    return
  end
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetBox")
  if isSelectBtn then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").SUBPANEL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  self:DispatchEvent(PetUIModuleEvent.OnLeavePetBoxFilter)
  self:DispatchEvent(PetUIModuleEvent.OnNewPetBagRightPanelClose, "NewPetBagWarehouseScreening")
  self.module:SetNewPetBagWarehouseScreeningPanelOpenState(false)
  self:DispatchEvent(PetUIModuleEvent.OnUpdatePetBagEmptyView)
  self:OnClose()
end

function UMG_PetWarehouseScreening_C:OnReleaseLifeBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnReleaseLifeBtnClick")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenNewPetBagScreenSearchPanel)
end

function UMG_PetWarehouseScreening_C:OnAddBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnAddBtnClick")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, {}, _G.DataConfigManager.ConfigTableId.PET_FILTER_CONF, {
    FilterDepartCondition = self.FilterCondition.FilterDepartCondition
  }, {
    _G.Enum.FilterRule.FIL_SKILLDAM_TYPE
  })
end

function UMG_PetWarehouseScreening_C:OnAddBtn1Click()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnAddBtn1Click")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, {}, _G.DataConfigManager.ConfigTableId.PET_FILTER_CONF, {
    FilterNatureCondition = self.FilterCondition.FilterNatureCondition
  }, {
    _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT
  })
end

function UMG_PetWarehouseScreening_C:OnAddBtn2Click()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnAddBtn2Click")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, {}, _G.DataConfigManager.ConfigTableId.PET_FILTER_CONF, {
    FilterAttributeCondition = self.FilterCondition.FilterAttributeCondition
  }, {
    _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE
  })
end

function UMG_PetWarehouseScreening_C:OnAddBtn3Click()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnAddBtn3Click")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, {}, _G.DataConfigManager.ConfigTableId.PET_FILTER_CONF, {
    FilterPetMarkCondition = self.FilterCondition.FilterPetMarkCondition
  }, {
    _G.Enum.FilterRule.FIL_PET_MARK
  })
end

function UMG_PetWarehouseScreening_C:OnAddBtn4Click()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetWarehouseScreening_C:OnAddBtn4Click")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, {}, _G.DataConfigManager.ConfigTableId.PET_FILTER_CONF, {
    FilterStrongCondition = self.FilterCondition.FilterStrongCondition
  }, {
    _G.Enum.FilterRule.FIL_PET_TALENT
  })
end

function UMG_PetWarehouseScreening_C:OnBtnResetClick()
  self.FilterCondition = {
    FilterPetIdCondition = {},
    FilterTalentCondition = {},
    FilterDepartCondition = {},
    FilterNatureCondition = {},
    FilterAttributeCondition = {},
    FilterPetMarkCondition = {},
    FilterStrongCondition = {},
    FilterTimeCondition = {},
    FilterTraceBackCondition = {}
  }
  self.petList:InitGridView({})
  self.FilterList:InitGridView({})
  self.EnhancingPersonTypeList:InitGridView({})
  self.PersonalValueList:InitGridView({})
  self.PartnerMarker:InitGridView({})
  self.StrongPoint:InitGridView({})
  self.GainTheTime:ClearSelection()
  self:UnSelectListItems(self.GiftList)
  self:UnSelectListItems(self.TimeRewindList)
  self:ConfirmResult()
end

function UMG_PetWarehouseScreening_C:UnSelectListItems(list)
  for j = 1, list:GetItemCount() do
    local item = list:GetItemByIndex(j - 1)
    if item then
      item:OnUnSelect()
    end
  end
end

function UMG_PetWarehouseScreening_C:OnTimeRewindTipsBtnClick()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentText = _G.DataConfigManager:GetLocalizationConf("pet_return_filter_tip").msg
  local ContentTitle = _G.DataConfigManager:GetLocalizationConf("pet_return_filter_title").msg
  Context:SetTitle(ContentTitle):SetContent(ContentText):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_PetWarehouseScreening_C:OnBtnConfirmClick()
  self:ConfirmResult()
  self.module:CloseNewPetBagBoxPanel()
  self:OnBackBtnClick()
end

function UMG_PetWarehouseScreening_C:ConfirmResult()
  local CacheFilterData = self.module:GetCachePetBoxFilterData()
  CacheFilterData.Condition = self.FilterCondition
  local isCondition = self.module:IsFilteringCondition(self.FilterCondition)
  if false == isCondition then
    self.module:InitCachePetBoxFilterData()
  end
  self.module:SetCachePetBoxFilterData(CacheFilterData)
  if false == isCondition then
    self.module:OnCmdFilterPetBoxData({}, self.FilterCondition, true)
  else
    self.module:UpdateCachePetBoxFilterData(true, true)
  end
end

function UMG_PetWarehouseScreening_C:IsFilteringCondition(AllCondition)
  local function Check(Condition)
    if #Condition > 0 then
      return true
    end
    return false
  end
  
  if Check(AllCondition.FilterPetIdCondition) then
    return true
  elseif Check(AllCondition.FilterTalentCondition) then
    return true
  elseif Check(AllCondition.FilterDepartCondition) then
    return true
  elseif Check(AllCondition.FilterNatureCondition) then
    return true
  elseif Check(AllCondition.FilterAttributeCondition) then
    return true
  elseif Check(AllCondition.FilterPetMarkCondition) then
    return true
  elseif Check(AllCondition.FilterStrongCondition) then
    return true
  elseif Check(AllCondition.FilterTimeCondition) then
    return true
  end
  return false
end

function UMG_PetWarehouseScreening_C:GetAttributeEnums(attribute_info)
  local enums = {}
  local hp = attribute_info.hp
  local attack = attribute_info.attack
  local special_attack = attribute_info.special_attack
  local defense = attribute_info.defense
  local special_defense = attribute_info.special_defense
  local speed = attribute_info.speed
  if hp.talent_add_value and hp.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_HPMAX)
  end
  if attack.talent_add_value and attack.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_PHYATK)
  end
  if special_attack.talent_add_value and special_attack.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEATK)
  end
  if defense.talent_add_value and defense.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_PHYDEF)
  end
  if special_defense.talent_add_value and special_defense.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEDEF)
  end
  if speed.talent_add_value and speed.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEED)
  end
  return enums
end

function UMG_PetWarehouseScreening_C:GetStrongEnum(speciality_id)
  local conf = _G.DataConfigManager:GetPetTalentConf(speciality_id)
  local enum = _G.Enum.PetTalentFilterName[conf.filter_enum_value]
  return enum
end

function UMG_PetWarehouseScreening_C:OnPcClose()
  self:OnBackBtnClick()
end

function UMG_PetWarehouseScreening_C:OnAnimFinished(anim)
  if anim == self.Out then
  end
end

return UMG_PetWarehouseScreening_C
