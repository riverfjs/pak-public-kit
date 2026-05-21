local BattleSpectatorModuleHead = NRCModuleHeadBase:Extend("BattleSpectatorModuleHead")

function BattleSpectatorModuleHead:OnConstruct()
  _G.BattleSpectatorModuleCmd = reload("NewRoco.Modules.System.BattleSpectator.BattleSpectatorModuleCmd")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetEqsRunner, "GetEQSRunner")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetWaterPlatformClass, "GetWaterPlatformClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetBattlePointClass, "GetBattlePointClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetNpcDisapperSkillClass, "GetNpcDisapperSkillClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetPerformSkillClass, "GetPerformSkillClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetPerformEndSkillClass, "GetPerformEndSkillClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetNightmareShieldBreakSkillClass, "GetNightmareShieldBreakSkillClass")
  self:BindCmd(_G.BattleSpectatorModuleCmd.OnInnerBattleNotify, "OnInnerBattleNotify")
  self:BindCmd(_G.BattleSpectatorModuleCmd.RemoveRecord, "RemoveRecord")
  self:BindCmd(_G.BattleSpectatorModuleCmd.OnInnerBattleShieldBroken, "OnInnerBattleShieldBroken")
  self:BindCmd(_G.BattleSpectatorModuleCmd.OnInnerBattleChangePet, "OnInnerBattleChangePet")
  self:BindCmd(_G.BattleSpectatorModuleCmd.TryKeepWatchNpcIfPlayerLogOut, "OnTryKeepWatchNpcIfPlayerLogOut")
  self:BindCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug, "GetCanDrawDebug")
  self:BindCmd(_G.BattleSpectatorModuleCmd.SetCanDrawDebug, "SetCanDrawDebug")
end

return BattleSpectatorModuleHead
