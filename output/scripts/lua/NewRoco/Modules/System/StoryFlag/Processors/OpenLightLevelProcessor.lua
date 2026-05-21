local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local OpenLightLevelProcessor = StoryFlagProcessorBase:Extend("OpenLightLevelProcessor")

function OpenLightLevelProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.LevelSwitchCache = {}
end

function OpenLightLevelProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  local SceneIDs = Conf.action_int_param
  for _, SceneID in ipairs(SceneIDs) do
    self.LevelSwitchCache[SceneID] = Conf
    if SceneID == SceneResConf.id and HasFlag then
      _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.SwitchDynamicLevel, Conf.action_string_param)
    end
  end
end

function OpenLightLevelProcessor:GetLoadSceneList(SceneID)
  if not SceneID then
    return nil
  end
  local Conf = self.LevelSwitchCache[SceneID]
  if not Conf then
    return nil
  end
  local Flag = Conf.id
  local StoryFlags = _G.DataModelMgr.PlayerDataModel:GetStoryFlags()
  local HomeOwnerFlags = _G.DataModelMgr.PlayerDataModel:GetHomeOwnerStoryFlags()
  local bIsContain = false
  if _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(Flag) then
    bIsContain = table.contains(StoryFlags, Flag)
  else
    bIsContain = table.contains(HomeOwnerFlags, Flag)
  end
  if bIsContain then
    return Conf
  end
  return nil
end

function OpenLightLevelProcessor:Destroy()
  table.clear(self.LevelSwitchCache)
end

return OpenLightLevelProcessor
