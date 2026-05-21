local SeasonIntegrationModuleHead = NRCModuleHeadBase:Extend("SeasonIntegrationModuleHead")

function SeasonIntegrationModuleHead:OnConstruct()
  _G.SeasonIntegrationModuleCmd = reload("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleCmd")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPanel, "OpenSeasonIntegrationPanel")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo, "GetSeasonInfo")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.ShowSeasonBeginsTips, "ShowSeasonBeginsTips")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPopUp, "OpenSeasonIntegrationPopUp")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonPopup, "OpenSeasonPopup")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.SendZoneSetSeasonFirstPopReq, "SendZoneSetSeasonFirstPopReq")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.PlayBonusCatchEffect, "PlayBonusCatchEffect")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.OnBonusCatchLimitTips, "OnBonusCatchLimitTips")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.S2_GetCurrentKnockBoxInfo, "S2_GetCurrentKnockBoxInfo")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.S2_OpenKnockBoxMessage, "S2_OpenKnockBoxMessage")
  self:BindCmd(_G.SeasonIntegrationModuleCmd.S2_CloseKnockBoxMessage, "S2_CloseKnockBoxMessage")
end

return SeasonIntegrationModuleHead
