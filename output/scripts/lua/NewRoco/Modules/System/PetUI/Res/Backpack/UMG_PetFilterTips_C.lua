local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetFilterTips_C = _G.NRCPanelBase:Extend("UMG_PetFilterTips_C")
UMG_PetFilterTips_C.FilterEnum = {
  DepartmentFilter = 0,
  TalentFilter = 1,
  NaturePositiveEffectFilter = 2,
  AttributeFilter = 3,
  PartnerMarkerFilter = 4,
  SpecialityFilter = 5,
  GetTimeFilter = 6,
  GenderFilter = 7
}
UMG_PetFilterTips_C.ShowTimeFilterOpenTypeList = {
  PetUIModuleEnum.OpenSortType.WareHouse,
  PetUIModuleEnum.OpenSortType.WareHouseFree
}

function UMG_PetFilterTips_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self:AddButtonListener(self.BtnDetails.btnLevelUp, self.OnClickedQuestion)
end

function UMG_PetFilterTips_C:OnDestruct()
end

function UMG_PetFilterTips_C:HiddenOrShowStrongPoint(bShow)
  if bShow then
    self.StrongPoint:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Img_Line_4:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.StrongPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetFilterTips_C:HiddenFilterByEnum(Enum)
  if Enum == self.FilterEnum.DepartmentFilter then
    self.FilterList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.TalentFilter then
    self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GiftList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.NaturePositiveEffectFilter then
    self.EnhancingPersonTypeList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.AttributeFilter then
    self.PersonalValueList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.PartnerMarkerFilter then
    self.PartnerMarker:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.SpecialityFilter then
    self.StrongPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Img_Line_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Enum == self.FilterEnum.GetTimeFilter then
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GainTheTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetFilterTips_C:OnActive(OpenType, FilterHiddenParam)
  self.OpenType = OpenType
  self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Visible)
  if FilterHiddenParam then
    self.FilterHiddenParam = FilterHiddenParam.HiddenParam
    self.OldFilter = FilterHiddenParam.chooseTypeList
    local HiddenFilterEnum = FilterHiddenParam.HiddenFilterEnum
    if HiddenFilterEnum then
      for i, v in ipairs(HiddenFilterEnum) do
        self:HiddenFilterByEnum(v)
      end
    end
  end
  if self.ShowTimeFilterOpenTypeList then
    local hideGetTime = true
    for _, type in pairs(self.ShowTimeFilterOpenTypeList) do
      if OpenType == type then
        hideGetTime = false
        break
      end
    end
    if hideGetTime then
      self:HiddenFilterByEnum(self.FilterEnum.GetTimeFilter)
    end
  end
  self.data = self.module:GetData("PetUIModuleData")
  if OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
    self.OldFilter = self.data.chooseTypeList1
    self:HiddenOrShowStrongPoint(false)
  elseif OpenType == PetUIModuleEnum.OpenSortType.WareHouse then
    self.OldFilter = self.data.chooseTypeList
    self:HiddenOrShowStrongPoint(true)
  elseif OpenType == PetUIModuleEnum.OpenSortType.TeamReplace then
    self.OldFilter = self.data.chooseTypeListTeamReplace
    self:HiddenOrShowStrongPoint(false)
  elseif OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListHomePetFeeding
  elseif OpenType == PetUIModuleEnum.OpenSortType.HomePlantGuard then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListHomePlantGuard
  elseif OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListWeeklyChallenge
  elseif OpenType == PetUIModuleEnum.OpenSortType.PetInheritance then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListPetInheritance
  elseif OpenType == PetUIModuleEnum.OpenSortType.PetPartnerActivity then
    self:HiddenOrShowStrongPoint(false)
    self.OldFilter = self.data.chooseTypeListPetPartnerActivity
  elseif OpenType == PetUIModuleEnum.OpenSortType.CertificationActivity then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListCertification
  elseif OpenType == PetUIModuleEnum.OpenSortType.BattleRogue then
    self:HiddenOrShowStrongPoint(true)
    self.OldFilter = self.data.chooseTypeListBattleRogue
  end
  if OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding and self.OldFilter.GenderFilter then
    self.GenderFilter = table.deepCopy(self.OldFilter.GenderFilter, self.GenderFilter, false)
  end
  self.DepartmentFilter = table.deepCopy(self.OldFilter.DepartmentFilter, self.DepartmentFilter, false)
  self.TalentFilter = table.deepCopy(self.OldFilter.TalentFilter, self.TalentFilter, false)
  self.NaturePositiveEffectFilter = table.deepCopy(self.OldFilter.NaturePositiveEffectFilter, self.NaturePositiveEffectFilter, false)
  self.AttributeFilter = table.deepCopy(self.OldFilter.AttributeFilter, self.AttributeFilter, false)
  if self.OldFilter.PartnerMarkerFilter then
    self.PartnerMarkerFilter = table.deepCopy(self.OldFilter.PartnerMarkerFilter, self.PartnerMarkerFilter, false)
  else
    self.PartnerMarkerFilter = {}
  end
  if self.OldFilter.SpecialityFilter then
    self.SpecialityFilter = table.deepCopy(self.OldFilter.SpecialityFilter, self.SpecialityFilter, false)
  else
    self.SpecialityFilter = {}
  end
  if self.OldFilter.GetTimeFilter then
    self.GetTimeFilter = table.deepCopy(self.OldFilter.GetTimeFilter, self.GetTimeFilter, false)
  else
    self.GetTimeFilter = {}
  end
  self:SetCommonPopUpInfo()
  self:SetPanelInfo()
  self:LoadAnimation(0)
  self:OnAddEventListener()
end

function UMG_PetFilterTips_C:SetPanelInfo()
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_FILTER_CONF)
  if self.OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding then
    cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.HOME_FILTER_CONF)
  end
  local cfgDatas = cfgTable:GetAllDatas()
  self.GenderType = {}
  self.SkillDamType = {}
  self.TalentType = {}
  self.NaturePositiveEffect = {}
  self.SelfAttribute = {}
  self.PartnerMarkerData = {}
  self.SpecialityData = {}
  self.GetTimeData = {}
  for i, v in pairs(cfgDatas) do
    if v.filter_type == _G.Enum.FilterRule.FIL_PET_GENDER then
      local InitSelect = false
      if self.GenderFilter and #self.GenderFilter > 0 then
        for j = 1, #self.GenderFilter do
          if self.GenderFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.GenderType, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.GenderFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE then
      local InitSelect = false
      if #self.DepartmentFilter > 0 then
        for j = 1, #self.DepartmentFilter do
          if self.DepartmentFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      if self.FilterHiddenParam then
        for j, param in pairs(self.FilterHiddenParam) do
          if param == _G.Enum[v.filter_enum_name][v.filter_enum_value] then
            table.insert(self.SkillDamType, {
              data = v,
              InitSelect = InitSelect,
              type = self.FilterEnum.DepartmentFilter
            })
          end
        end
      else
        table.insert(self.SkillDamType, {
          data = v,
          InitSelect = InitSelect,
          type = self.FilterEnum.DepartmentFilter
        })
      end
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_TALENT_TYPE then
      local InitSelect = false
      if #self.TalentFilter > 0 then
        for j = 1, #self.TalentFilter do
          if self.TalentFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.TalentType, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.TalentFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_NATURE_POSITIVE_EFFECT then
      local InitSelect = false
      if #self.NaturePositiveEffectFilter > 0 then
        for j = 1, #self.NaturePositiveEffectFilter do
          if self.NaturePositiveEffectFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.NaturePositiveEffect, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.NaturePositiveEffectFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_SELF_ATTRIBUTE then
      local InitSelect = false
      if #self.AttributeFilter > 0 then
        for j = 1, #self.AttributeFilter do
          if self.AttributeFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.SelfAttribute, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.AttributeFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_PET_MARK then
      local InitSelect = false
      if #self.PartnerMarkerFilter > 0 then
        for j = 1, #self.PartnerMarkerFilter do
          if self.PartnerMarkerFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.PartnerMarkerData, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.PartnerMarkerFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_PET_TALENT then
      local InitSelect = false
      if #self.SpecialityFilter > 0 then
        for j = 1, #self.SpecialityFilter do
          if self.SpecialityFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.SpecialityData, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.SpecialityFilter
      })
    end
    if v.filter_type == _G.Enum.FilterRule.FIL_CATCH_TIME then
      local InitSelect = false
      if #self.GetTimeFilter > 0 then
        for j = 1, #self.GetTimeFilter do
          if self.GetTimeFilter[j].data.id == v.id then
            InitSelect = true
            break
          end
        end
      end
      table.insert(self.GetTimeData, {
        data = v,
        InitSelect = InitSelect,
        type = self.FilterEnum.GetTimeFilter
      })
    end
  end
  self.CanvasPanel_6:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding and #self.GenderType > 0 and self.CanvasPanel_6 then
    self.GenderList:InitGridView(self.GenderType)
    self.CanvasPanel_6:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.GenderList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.FilterList:InitGridView(self.SkillDamType)
  self.GiftList:InitGridView(self.TalentType)
  self.EnhancingPersonTypeList:InitGridView(self.NaturePositiveEffect)
  self.PersonalValueList:InitGridView(self.SelfAttribute)
  self.PartnerMarker:InitGridView(self.PartnerMarkerData)
  self.StrongPoint:InitGridView(self.SpecialityData)
  self.GainTheTime:InitGridView(self.GetTimeData)
  for i, v in pairs(self.GetTimeData or {}) do
    if v.InitSelect == true then
      self.GainTheTime:SelectItemByIndex(i - 1)
    end
    local item = self.GainTheTime:GetItemByIndex(i - 1)
    if item then
      item:InitItemState(v.InitSelect)
    end
  end
end

function UMG_PetFilterTips_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.RestartFilter
  CommonPopUpData.Btn_RightHandler = self.ApplyFilter
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_PetFilterTips_C:OnDeactive()
end

function UMG_PetFilterTips_C:AddOrRemoveFilterFromFilterList(IsAdd, FilterData)
  if FilterData.type == self.FilterEnum.GenderFilter and self.GenderFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.GenderFilter, temp)
    else
      for i = 1, #self.GenderFilter do
        if self.GenderFilter[i].data.id == FilterData.data.id then
          table.remove(self.GenderFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.DepartmentFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.DepartmentFilter, temp)
    else
      for i = 1, #self.DepartmentFilter do
        if self.DepartmentFilter[i].data.id == FilterData.data.id then
          table.remove(self.DepartmentFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.TalentFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.TalentFilter, temp)
    else
      for i = 1, #self.TalentFilter do
        if self.TalentFilter[i].data.id == FilterData.data.id then
          table.remove(self.TalentFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.NaturePositiveEffectFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.NaturePositiveEffectFilter, temp)
    else
      for i = 1, #self.NaturePositiveEffectFilter do
        if self.NaturePositiveEffectFilter[i].data.id == FilterData.data.id then
          table.remove(self.NaturePositiveEffectFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.AttributeFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.AttributeFilter, temp)
    else
      for i = 1, #self.AttributeFilter do
        if self.AttributeFilter[i].data.id == FilterData.data.id then
          table.remove(self.AttributeFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.PartnerMarkerFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      temp.data.filter_icon = FilterData.data.filter_icon
      table.insert(self.PartnerMarkerFilter, temp)
    else
      for i = 1, #self.PartnerMarkerFilter do
        if self.PartnerMarkerFilter[i].data.id == FilterData.data.id then
          table.remove(self.PartnerMarkerFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.SpecialityFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      table.insert(self.SpecialityFilter, temp)
    else
      for i = 1, #self.SpecialityFilter do
        if self.SpecialityFilter[i].data.id == FilterData.data.id then
          table.remove(self.SpecialityFilter, i)
          break
        end
      end
    end
  end
  if FilterData.type == self.FilterEnum.GetTimeFilter then
    if IsAdd then
      local temp = {}
      temp.data = {}
      temp.data.id = FilterData.data.id
      temp.data.filter_type = FilterData.data.filter_type
      temp.data.filter_enum_name = FilterData.data.filter_enum_name
      temp.data.filter_enum_value = FilterData.data.filter_enum_value
      temp.data.filter_desc = FilterData.data.filter_desc
      table.insert(self.GetTimeFilter, temp)
    else
      for i = 1, #self.GetTimeFilter do
        if self.GetTimeFilter[i].data.id == FilterData.data.id then
          table.remove(self.GetTimeFilter, i)
          break
        end
      end
    end
  end
end

function UMG_PetFilterTips_C:OnAddEventListener()
  self:RegisterEvent(self, PetUIModuleEvent.AddOrRemoveFilterFromFilterList, self.AddOrRemoveFilterFromFilterList)
end

function UMG_PetFilterTips_C:OnPcClose()
  if self:IsPlayingAnimation() then
    return
  end
  self:ClosePanel()
end

function UMG_PetFilterTips_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
    self.data.chooseTypeList1 = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WareHouse then
    self.data.chooseTypeList = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.TeamReplace then
    self.data.chooseTypeListTeamReplace = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding then
    self.data.chooseTypeListHomePetFeeding = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePlantGuard then
    self.data.chooseTypeListHomePlantGuard = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
    self.data.chooseTypeListWeeklyChallenge = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetInheritance then
    self.data.chooseTypeListPetInheritance = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetPartnerActivity then
    self.data.chooseTypeListPetPartnerActivity = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.CertificationActivity then
    self.data.chooseTypeListCertification = self.OldFilter
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.BattleRogue then
    self.data.chooseTypeListBattleRogue = self.OldFilter
  end
  self:LoadAnimation(2)
end

function UMG_PetFilterTips_C:RestartFilter()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self.GenderFilter = {}
  self.DepartmentFilter = {}
  self.TalentFilter = {}
  self.NaturePositiveEffectFilter = {}
  self.AttributeFilter = {}
  self.PartnerMarkerFilter = {}
  self.SpecialityFilter = {}
  self.GetTimeFilter = {}
  if self.OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
    self.data.chooseTypeList1 = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WareHouse then
    self.data.chooseTypeList = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter,
      GetTimeFilter = self.GetTimeFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.TeamReplace then
    self.data.chooseTypeListTeamReplace = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding then
    self.data.chooseTypeListHomePetFeeding = {
      GenderFilter = self.GenderFilter,
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePlantGuard then
    self.data.chooseTypeListHomePlantGuard = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
    self.data.chooseTypeListWeeklyChallenge = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetInheritance then
    self.data.chooseTypeListPetInheritance = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetPartnerActivity then
    self.data.chooseTypeListPetPartnerActivity = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.CertificationActivity then
    self.data.chooseTypeListCertification = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
  end
  self:SetPanelInfo()
end

function UMG_PetFilterTips_C:ApplyFilter()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
    self.data.chooseTypeList1 = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter,
      GetTimeFilter = self.GetTimeFilter
    }
    self:DispatchEvent(PetUIModuleEvent.FilterPetSort, self.data.chooseTypeList1)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WareHouse then
    self.data.chooseTypeList = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter,
      GetTimeFilter = self.GetTimeFilter
    }
    self:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeList)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.TeamReplace then
    self.data.chooseTypeListTeamReplace = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    self:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListTeamReplace)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.NeedModuleCatch then
    local chooseTypeList = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, chooseTypeList)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePetFeeding then
    self.data.chooseTypeListHomePetFeeding = {
      GenderFilter = self.GenderFilter,
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListHomePetFeeding)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.HomePlantGuard then
    self.data.chooseTypeListHomePlantGuard = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListHomePlantGuard)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
    self.data.chooseTypeListWeeklyChallenge = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListWeeklyChallenge)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetInheritance then
    self.data.chooseTypeListPetInheritance = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPetInherit, self.data.chooseTypeListPetInheritance)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.PetPartnerActivity then
    self.data.chooseTypeListPetPartnerActivity = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPetPartner, self.data.chooseTypeListPetPartnerActivity)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.CertificationActivity then
    self.data.chooseTypeListCertification = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListCertification)
  elseif self.OpenType == PetUIModuleEnum.OpenSortType.BattleRogue then
    self.data.chooseTypeListBattleRogue = {
      DepartmentFilter = self.DepartmentFilter,
      TalentFilter = self.TalentFilter,
      NaturePositiveEffectFilter = self.NaturePositiveEffectFilter,
      AttributeFilter = self.AttributeFilter,
      PartnerMarkerFilter = self.PartnerMarkerFilter,
      SpecialityFilter = self.SpecialityFilter
    }
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.FilterPet, self.data.chooseTypeListBattleRogue)
  end
  self:LoadAnimation(2)
end

function UMG_PetFilterTips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_PetFilterTips_C:OnClickedQuestion()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.general_title)
  Ctx:SetContent(LuaText.filter_catch_time_explain)
  Ctx:SetMode(DialogContext.Mode.NotBtn)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

return UMG_PetFilterTips_C
