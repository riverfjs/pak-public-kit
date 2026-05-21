local UMG_PetReportShare_C = _G.NRCPanelBase:Extend("UMG_PetReportShare_C")

function UMG_PetReportShare_C:OnActive(data)
  self.data = data
  self:InitUI()
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_RetReport_SharePanel_C:OnActive")
end

function UMG_PetReportShare_C:InitUI()
  self.PhotoSub:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PhotoSub.PetImage:SetUILocation()
  self:InitPetBaseUI()
  self:InitPetRatioUI()
end

function UMG_PetReportShare_C:InitPetBaseUI()
  if self.data.reportData and self.data.reportData.pet_brief then
    if self.data.reportData.pet_brief.name then
      local name = self.data.reportData.pet_brief.name
      self.PhotoSub.NameText:SetText(name)
    end
    self:SetPetIcon(self.data.reportData.pet_brief.base_conf_id, self.data.reportData.pet_brief.mutation_type, self.data.reportData.pet_brief.glass_info)
    self.PhotoSub.Heterochrome:SetMutationIcon(self.data.reportData.pet_brief)
  end
end

function UMG_PetReportShare_C:SetPetIcon(baseConfID, mutation_type, glass_info)
  if self.data.reportData.bSpecial then
    self.PhotoSub.BgSwitcher:SetActiveWidgetIndex(1)
  else
    self.PhotoSub.BgSwitcher:SetActiveWidgetIndex(0)
  end
  self.PhotoSub.PetImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PhotoSub.PetImage:SetPetIcon(true, baseConfID, mutation_type, glass_info)
end

function UMG_PetReportShare_C:InitPetRatioUI()
  if self.data.reportData and self.data.reportData.report_infos and self.data.reportData.final_ratio and self.data.reportData.total_coin then
    self.PhotoSub.Number_1:SetText(tostring(self.data.reportData.total_coin))
    if self.data.reportData.final_ratio then
      local final_ratio = self.data.reportData.final_ratio / 10000
      if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsInteger, final_ratio) then
        self.PhotoSub.MultiplyingPowerText:SetText(string.format("x%d", math.floor(final_ratio)))
      else
        self.PhotoSub.MultiplyingPowerText:SetText(string.format("x%.1f", final_ratio))
      end
      local color
      local report_text_super = _G.DataConfigManager:GetPetGlobalConfig("report_text_super")
      local report_text_hard = _G.DataConfigManager:GetPetGlobalConfig("report_text_hard")
      local report_text_middle = _G.DataConfigManager:GetPetGlobalConfig("report_text_middle")
      local report_text_easy = _G.DataConfigManager:GetPetGlobalConfig("report_text_easy")
      if report_text_super and report_text_hard and report_text_middle and report_text_easy then
        if report_text_hard.num and final_ratio >= report_text_hard.num then
          color = report_text_super.str
        elseif report_text_hard.num and report_text_middle.num and final_ratio >= report_text_middle.num and final_ratio < report_text_hard.num then
          color = report_text_hard.str
        elseif report_text_middle.num and report_text_easy.num and final_ratio >= report_text_easy.num and final_ratio < report_text_middle.num then
          color = report_text_middle.str
        elseif report_text_easy.num and final_ratio > 0 and final_ratio < report_text_easy.num then
          color = report_text_easy.str
        end
      end
      if color then
        self.PhotoSub.QualityBG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
      end
    end
    local ratioList = {}
    local index = -1
    local needToHide = false
    local talentText = _G.DataConfigManager:GetLocalizationConf("report_ratio_talent_text")
    for _, info in pairs(self.data.reportData.report_infos or {}) do
      local id = info.id
      if id then
        local ratioConf = _G.DataConfigManager:GetReportCoinRatioConf(id)
        if ratioConf then
          local ratioInfo = {}
          ratioInfo.enum_name = ratioConf.enum_name
          ratioInfo.param_name = ratioConf.param_name
          if ratioConf.enum_ReportCoinRatio == Enum.ReportCoinRatio.RCR_GLASS_HIDDEN then
            local glassName = self:GetHiddenGlassName()
            if glassName then
              ratioInfo.param_name = glassName
            end
          end
          ratioInfo.ratio = info.ratio / 10000
          ratioInfo.id = id
          table.insert(ratioList, ratioInfo)
          if talentText and talentText.msg then
            if -1 == index and talentText.msg == ratioInfo.enum_name then
              index = #ratioList
            end
            if ratioInfo.ratio > 1 and talentText.msg ~= ratioInfo.enum_name then
              needToHide = true
            end
          end
        end
      end
    end
    if #ratioList > 1 and index > 0 and ratioList[index] and 1 == ratioList[index].ratio and needToHide then
      table.remove(ratioList, index)
    end
    table.sort(ratioList, function(a, b)
      return a.id < b.id
    end)
    self.PhotoSub.List:InitGridView(ratioList)
  end
  for i = 1, self.PhotoSub.List:GetItemCount() do
    local item = self.PhotoSub.List:GetItemByIndex(i - 1)
    if item then
      item.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_PetReportShare_C:GetHiddenGlassName()
  if self.data and self.data.reportData and self.data.reportData.pet_brief and self.data.reportData.pet_brief.glass_info and self.data.reportData.pet_brief.glass_info.glass_type == ProtoEnum.GlassType.GT_HIDDEN then
    local HiddenGlassID = self.data.reportData.pet_brief.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        local name = HiddenGlassConf.name
        name = name and name:gsub("<[^>]*>", ""):gsub("</>", "")
        return name
      end
    end
  end
  return nil
end

return UMG_PetReportShare_C
