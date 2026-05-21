local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_TreasureSpot_Item_C = Base:Extend("UMG_Activity_TreasureSpot_Item_C")

function UMG_Activity_TreasureSpot_Item_C:OnConstruct()
  self:AddButtonListener(self.Button_Tracking, self.TracePet)
end

function UMG_Activity_TreasureSpot_Item_C:OnDestruct()
  self:RemoveButtonListener(self.Button_Tracking)
end

function UMG_Activity_TreasureSpot_Item_C:OnItemUpdate(_data, datalist, index)
  self.petBase_id = _data
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_data)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    self.Switcher:SetActiveWidgetIndex(0)
    self.HeadIcon:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
  else
    self.Switcher:SetActiveWidgetIndex(1)
  end
end

function UMG_Activity_TreasureSpot_Item_C:TracePet()
  if self.petBase_id then
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TreasureHuntTracePet, self.petBase_id)
  end
end

return UMG_Activity_TreasureSpot_Item_C
