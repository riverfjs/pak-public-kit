local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PVE_CurrentPeriod_List_C = Base:Extend("UMG_PVE_CurrentPeriod_List_C")

function UMG_PVE_CurrentPeriod_List_C:OnConstruct()
end

function UMG_PVE_CurrentPeriod_List_C:OnDestruct()
end

function UMG_PVE_CurrentPeriod_List_C:OnItemUpdate(_data, datalist, index)
  local battleRuleConf = _G.DataConfigManager:GetBattleRuleConf(_data.battle_rule)
  if battleRuleConf then
    self.DescribeText:SetText(battleRuleConf.season_desc)
    self.MechanismText:SetText(battleRuleConf.season_title)
  else
    self.DescribeText:SetText("")
    self.MechanismText:SetText("")
  end
end

function UMG_PVE_CurrentPeriod_List_C:OnItemSelected(_bSelected)
end

function UMG_PVE_CurrentPeriod_List_C:OnDeactive()
end

return UMG_PVE_CurrentPeriod_List_C
