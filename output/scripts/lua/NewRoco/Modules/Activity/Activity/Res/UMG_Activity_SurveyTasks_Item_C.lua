local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_SurveyTasks_Item_C = Base:Extend("UMG_Activity_SurveyTasks_Item_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_SurveyTasks_Item_C:OnConstruct()
end

function UMG_Activity_SurveyTasks_Item_C:OnDestruct()
  self:RemoveButtonListener(self.NRCButton_Trace)
end

function UMG_Activity_SurveyTasks_Item_C:OnAddEventListener()
  self:AddButtonListener(self.NRCButton_Trace, self.OnTracePet)
end

function UMG_Activity_SurveyTasks_Item_C:OnItemUpdate(_data, datalist, index)
  self.PetBaseId = _data
  self.PetItem:SetIconPathAndMaterial(self.PetBaseId, Enum.MutationDiffType.MDT_NONE)
  local petBaseInfo = _G.DataConfigManager:GetPetbaseConf(self.PetBaseId)
  if petBaseInfo and petBaseInfo.unit_type and petBaseInfo.unit_type then
    local unitType = petBaseInfo.unit_type[1]
    local colorStr = _G.DataConfigManager:GetActivityGlobalConfig("pet_information_color_" .. tostring(unitType)).str
    self.NRCImage_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(colorStr))
  end
  self:OnAddEventListener()
end

function UMG_Activity_SurveyTasks_Item_C:OnItemSelected(_bSelected)
end

function UMG_Activity_SurveyTasks_Item_C:OnTracePet()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_SurveyTasks_Item_C:OnTracePet")
  ActivityUtils.RequestTracePet({
    self.PetBaseId
  }, self:GetParentCustomData())
end

return UMG_Activity_SurveyTasks_Item_C
