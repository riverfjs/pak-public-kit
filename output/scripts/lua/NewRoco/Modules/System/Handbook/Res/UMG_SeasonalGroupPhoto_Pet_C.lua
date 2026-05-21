local UMG_SeasonalGroupPhoto_Pet_C = _G.NRCPanelBase:Extend("UMG_SeasonalGroupPhoto_Pet_C")

function UMG_SeasonalGroupPhoto_Pet_C:OnActive()
end

function UMG_SeasonalGroupPhoto_Pet_C:OnDeactive()
end

function UMG_SeasonalGroupPhoto_Pet_C:OnAddEventListener()
end

function UMG_SeasonalGroupPhoto_Pet_C:InitPanel()
  local type = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
  self.PetSwitcher:SetActiveWidgetIndex(type - 1)
  local widget = self.PetSwitcher:GetActiveWidget()
  if widget then
    local childrenCount = widget:GetChildrenCount()
    for i = 0, childrenCount - 1 do
      local petIcon = widget:GetChildAt(i)
      if petIcon then
        petIcon:InitPanel()
      end
    end
  end
end

return UMG_SeasonalGroupPhoto_Pet_C
