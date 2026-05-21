local UMG_HerbologyBadge_Energy_C = _G.NRCViewBase:Extend("UMG_HerbologyBadge_Energy_C")

function UMG_HerbologyBadge_Energy_C:SetEnergyInfo(Num, bHighLight)
  self.SkillNengNum:SetText(tostring(Num))
  self.NRCSwitcher_Star:SetActiveWidgetIndex(bHighLight and 1 or 0)
end

return UMG_HerbologyBadge_Energy_C
