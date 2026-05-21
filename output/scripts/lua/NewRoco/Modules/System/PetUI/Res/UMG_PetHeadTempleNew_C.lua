local UMG_PetHeadTempleNew_C = _G.NRCPanelBase:Extend("UMG_PetHeadTempleNew_C")

function UMG_PetHeadTempleNew_C:OnActive()
end

function UMG_PetHeadTempleNew_C:OnDeactive()
end

function UMG_PetHeadTempleNew_C:OnAddEventListener()
end

function UMG_PetHeadTempleNew_C:ShowDetail(petData)
  self.LengthSwitcher:SetActiveWidgetIndex(1)
  local base_conf_id = petData.base_conf_id
  local mutation_type = petData.mutation_type
  local glass_info = petData.glass_info
  if self.HeadIcon_1 then
    self.HeadIcon_1:SetIconPathAndMaterial(base_conf_id, mutation_type, glass_info)
    self.HeadIcon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.UnSelectedGrade then
    self.UnSelectedGrade:SetText(petData.level)
  end
  if self.UnSelectedName then
    self.UnSelectedName:SetText(petData.name)
  end
  local PetConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
  local currentEnergy = petData.energy
  if PetConf then
    local maxEnergy = PetConf.max_energy
    if self.UnSelectedTxtNeng then
      self.UnSelectedTxtNeng:SetText(string.format("%02d", currentEnergy))
    end
    if self.MaxEnergy then
      self.MaxEnergy:SetText(string.format("/%d", maxEnergy))
    end
    if self.UnSelectedTxtNeng then
      if currentEnergy <= 5 then
        local SlateColor = UE4.UNRCStatics.HexToSlateColor("#af3d3e")
        self.UnSelectedTxtNeng:SetColorAndOpacity(SlateColor)
      else
        local WhiteColor = UE4.UNRCStatics.HexToSlateColor("#FFFFFF7F")
        self.UnSelectedTxtNeng:SetColorAndOpacity(WhiteColor)
      end
    end
  end
  if 1 == petData.gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif 2 == petData.gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHeadTempleNew_C:HideDetail(petData)
  self.LengthSwitcher:SetActiveWidgetIndex(0)
  local base_conf_id = petData.base_conf_id
  local mutation_type = petData.mutation_type
  local glass_info = petData.glass_info
  if self.HeadIcon then
    self.HeadIcon:SetIconPathAndMaterial(base_conf_id, mutation_type, glass_info)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.PetLevel then
    self.PetLevel:SetText(petData.level)
  end
end

function UMG_PetHeadTempleNew_C:SetDragData(petData, bLong)
  if not petData then
    return
  end
  self.dragPetData = petData
  if bLong then
    self:ShowDetail(petData)
  else
    self:HideDetail(petData)
  end
end

function UMG_PetHeadTempleNew_C:GetDragItemRect(bLong)
  local widget = bLong and self.Move_Long or self.Move
  local geo = widget:GetCachedGeometry()
  return {
    pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(geo, UE4.FVector2D(0, 0)),
    size = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geo)
  }
end

return UMG_PetHeadTempleNew_C
