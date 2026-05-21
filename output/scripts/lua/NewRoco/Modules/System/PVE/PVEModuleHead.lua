local PVEModuleHead = NRCModuleHeadBase:Extend("PVEModuleHead")

function PVEModuleHead:OnConstruct()
  _G.PVEModuleCmd = reload("NewRoco.Modules.System.PVE.PVEModuleCmd")
  self:BindCmd(_G.PVEModuleCmd.DispatchEvent, "CmdDispatchEvent")
  self:BindCmd(_G.PVEModuleCmd.IsCurSeasonOpenTalent, "IsCurSeasonOpenTalent")
  self:BindCmd(_G.PVEModuleCmd.OpenPveTalentPanel, "OpenPveTalentPanel")
  self:BindCmd(_G.PVEModuleCmd.OpenPveCurrentPeriod, "OpenPveCurrentPeriod")
  self:BindCmd(_G.PVEModuleCmd.OpenPveParticulars, "OpenPveParticulars")
  self:BindCmd(_G.PVEModuleCmd.GetTalentUnlockNodeNum, "GetTalentUnlockNodeNum")
  self:BindCmd(_G.PVEModuleCmd.GetTalentNodeDataById, "GetTalentNodeDataById")
  self:BindCmd(_G.PVEModuleCmd.GetTalentMaterial, "GetTalentMaterial")
  self:BindCmd(_G.PVEModuleCmd.GetTalentMaterialCnt, "GetTalentMaterialCnt")
  self:BindCmd(_G.PVEModuleCmd.GetTalentResetReturnMaterialCnt, "GetTalentResetReturnMaterialCnt")
  self:BindCmd(_G.PVEModuleCmd.ClosePveParticulars, "ClosePveParticulars")
  self:BindCmd(_G.PVEModuleCmd.LightUpTalentNode, "LightUpTalentNode")
  self:BindCmd(_G.PVEModuleCmd.GetPveFeatureListData, "GetPveFeatureListData")
  self:BindCmd(_G.PVEModuleCmd.GetOccupiedFeatureSkillIds, "GetOccupiedFeatureSkillIds")
  self:BindCmd(_G.PVEModuleCmd.SetShowInnerPanels, "SetShowInnerPanels")
  self:BindCmd(_G.PVEModuleCmd.ClearTalentNode, "ClearTalentNode")
  self:BindCmd(_G.PVEModuleCmd.OpenPveWarningPrompt, "OpenPveWarningPrompt")
end

return PVEModuleHead
