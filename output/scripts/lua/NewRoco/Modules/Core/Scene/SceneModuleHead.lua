local SceneModuleHead = NRCModuleHeadBase:Extend("SceneModuleHead")

function SceneModuleHead:OnConstruct()
  _G.SceneModuleCmd = require("NewRoco.Modules.Core.Scene.SceneModuleCmd")
  self:BindCmd(SceneModuleCmd.EnterScene, "RequestEnterScene")
  self:BindCmd(SceneModuleCmd.EnterMap, "EnterMap")
  self:BindCmd(SceneModuleCmd.GetBlockingArea, "GetBlockingArea")
  self:BindCmd(SceneModuleCmd.GetRelatedBlockingArea, "GetRelatedBlockingArea")
  self:BindCmd(SceneModuleCmd.RegisterBlockingArea, "RegisterBlockingArea")
  self:BindCmd(SceneModuleCmd.UnregisterBlockingArea, "UnregisterBlockingArea")
  self:BindCmd(SceneModuleCmd.ConsumeCachedNotify, "ConsumeCachedNotify")
  self:BindCmd(SceneModuleCmd.ConsumeCachedBattleTag, "ConsumeCachedBattleTag")
  self:BindCmd(SceneModuleCmd.ConsumeCachedBattleTagForNpcGuideChange, "ConsumeCachedBattleTagForNpcGuideChange")
  self:BindCmd(SceneModuleCmd.ConsumeCachedActorTag, "ConsumeCachedActorTag")
  self:BindCmd(SceneModuleCmd.SwitchDynamicLevel, "SwitchDynamicLevel")
  self:BindCmd(SceneModuleCmd.GetCurrentZoneSceneTeleportNotify, "GetCurrentZoneSceneTeleportNotify")
  self:BindCmd(SceneModuleCmd.GetCurrentMapResId, "GetCurrentMapResId")
  self:BindCmd(SceneModuleCmd.CheckSceneFullyEntered, "CheckSceneFullyEntered")
  self:BindCmd(SceneModuleCmd.IsMagicBanned, "IsMagicBanned")
  self:BindCmd(SceneModuleCmd.IsRolePlayPropBanned, "IsRolePlayPropBanned")
end

return SceneModuleHead
