local MagicCreationModuleHead = NRCModuleHeadBase:Extend("MagicCreationModuleHead")

function MagicCreationModuleHead:OnConstruct()
  _G.MagicCreationModuleCmd = reload("NewRoco.Modules.System.MagicCreation.MagicCreationModuleCmd")
  self:BindCmd(_G.MagicCreationModuleCmd.OpenTransferNpcPanel, "OpenTransferNpcPanel")
  self:BindCmd(_G.MagicCreationModuleCmd.CloseTransferNpcPanel, "CloseTransferNpcPanel")
  self:BindCmd(_G.MagicCreationModuleCmd.RegisterCreation, "RegisterCreation")
  self:BindCmd(_G.MagicCreationModuleCmd.UnregisterCreation, "UnregisterCreation")
  self:BindCmd(_G.MagicCreationModuleCmd.SetNpcAppearance, "SetNpcAppearance")
  self:BindCmd(_G.MagicCreationModuleCmd.ApplySuitEffect, "ApplySuitEffect")
  self:BindCmd(_G.MagicCreationModuleCmd.RegisterPreperform, "RegisterPreperform")
  self:BindCmd(_G.MagicCreationModuleCmd.UnregisterPreperform, "UnregisterPreperform")
  self:BindCmd(_G.MagicCreationModuleCmd.MakePreperformPair, "MakePreperformPair")
  self:BindCmd(_G.MagicCreationModuleCmd.PreperformLocalReady, "PreperformLocalReady")
  self:BindCmd(_G.MagicCreationModuleCmd.CheckLandValid, "CheckLandValid")
  self:BindCmd(_G.MagicCreationModuleCmd.CheckNpcHeightDifferenceWithPlayer, "CheckNpcHeightDifferenceWithPlayer")
  self:BindCmd(_G.MagicCreationModuleCmd.CheckEavesExisted, "CheckEavesExisted")
  self:BindCmd(_G.MagicCreationModuleCmd.GetCanDrawDebug, "GetCanDrawDebug")
end

return MagicCreationModuleHead
