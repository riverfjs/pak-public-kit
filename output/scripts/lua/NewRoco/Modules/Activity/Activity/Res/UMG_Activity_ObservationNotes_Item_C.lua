local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ObservationNotes_Item_C = Base:Extend("UMG_Activity_ObservationNotes_Item_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_ObservationNotes_Item_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Activity_ObservationNotes_Item_C:OnDestruct()
  self:RemoveButtonListener(self.NRCButton_Trace)
  self:RemoveButtonListener(self.NRCButton_Look)
end

function UMG_Activity_ObservationNotes_Item_C:OnAddEventListener()
  self:AddButtonListener(self.NRCButton_Trace, self.OnTracePet)
  self:AddButtonListener(self.NRCButton_Look, self.OnLookPet)
end

function UMG_Activity_ObservationNotes_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  local petBaseId = _data.petbase_id
  self.PetItem:SetIconPathAndMaterial(petBaseId, Enum.MutationDiffType.MDT_NONE)
  self.Text_PetName:SetText(_data.title)
  local hasCollectPet = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckHasPetByPetBaseId, petBaseId)
  if hasCollectPet then
    self.NoCollection:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_11:SetActiveWidgetIndex(1)
  else
    self.NoCollection:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.NRCSwitcher_11:SetActiveWidgetIndex(0)
  end
  local petBaseInfo = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if petBaseInfo and petBaseInfo.pictorial_book_id and 0 ~= petBaseInfo.pictorial_book_id then
    self.NRCText_Number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_Number:SetText(petBaseInfo.pictorial_book_id)
  else
    self.NRCText_Number:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if petBaseInfo and petBaseInfo.unit_type and petBaseInfo.unit_type then
    local unitType = petBaseInfo.unit_type[1]
    local colorStr = _G.DataConfigManager:GetActivityGlobalConfig("pet_information_color_" .. tostring(unitType)).str
    self.QualityColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(colorStr))
  end
end

function UMG_Activity_ObservationNotes_Item_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ObservationNotes_Item_C:OnDeactive()
end

function UMG_Activity_ObservationNotes_Item_C:OnTracePet()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_ObservationNotes_Item_C:OnTracePet")
  ActivityUtils.RequestTracePet({
    self.data.petbase_id
  }, self:GetParentCustomData())
end

function UMG_Activity_ObservationNotes_Item_C:OnLookPet()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ObservationNotes_Item_C:OnLookPet")
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenObservationNotesInfoPanel, self.data)
end

return UMG_Activity_ObservationNotes_Item_C
