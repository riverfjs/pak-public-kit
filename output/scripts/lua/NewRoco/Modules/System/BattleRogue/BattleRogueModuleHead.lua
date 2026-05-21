local BattleRogueModuleHead = NRCModuleHeadBase:Extend("BattleRogueModuleHead")

function BattleRogueModuleHead:OnConstruct()
  _G.BattleRogueModuleCmd = reload("NewRoco.Modules.System.BattleRogue.BattleRogueModuleCmd")
  self:BindCmd(_G.BattleRogueModuleCmd.TryChangeState, "TryChangeState")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenExitPanel, "OpenExitPanel")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenChooseEnemyPanel, "OpenChooseEnemyPanel")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenPeculiarityTips, "OpenPeculiarityTips")
  self:BindCmd(_G.BattleRogueModuleCmd.EnterTrialScene, "EnterTrialScene")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenMonsterInfoPanel, "OpenMonsterInfoPanel")
  self:BindCmd(_G.BattleRogueModuleCmd.GetHerbologyPetSkillMapByGid, "GetHerbologyPetSkillMapByGid")
  self:BindCmd(_G.BattleRogueModuleCmd.SetHerbologyPetSkill, "SetHerbologyPetSkill")
  self:BindCmd(_G.BattleRogueModuleCmd.UpdatePetCollect, "UpdatePetCollect")
  self:BindCmd(_G.BattleRogueModuleCmd.UpdatePetData, "OnUpdatePetData")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenHerbologyTrialTips, "OpenHerbologyTrialTips")
  self:BindCmd(_G.BattleRogueModuleCmd.OpenHerbologyChapterTips, "OpenHerbologyChapterTips")
end

return BattleRogueModuleHead
