local UMG_Intimacy_C = _G.NRCViewBase:Extend("UMG_Intimacy_C")

function UMG_Intimacy_C:SetBtnText(text)
  self.textPetNature:SetText(text)
end

return UMG_Intimacy_C
