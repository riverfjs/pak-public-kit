local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local LoadLevelProcessor = StoryFlagProcessorBase:Extend("LoadLevelProcessor")

function LoadLevelProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.PlotLevelName = {}
end

function LoadLevelProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  if not table.contains(Conf.action_int_param, SceneResConf.id) then
    return
  end
  local LevelName = Conf.action_string_param
  if HasFlag then
    if not table.contains(self.PlotLevelName, LevelName) then
      UE4.UNRCStatics.ImmediateLoadPlotStreamingLevel(LevelName)
      table.insert(self.PlotLevelName, LevelName)
    end
  else
    for i, v in ipairs(self.PlotLevelName) do
      if v == LevelName then
        UE4.UNRCStatics.ImmediateRemovePlotStreamingLevel(LevelName)
        table.removeValue(self.PlotLevelName, LevelName)
        break
      end
    end
  end
end

function LoadLevelProcessor:RemoveStoryLevels()
  for i, v in ipairs(self.PlotLevelName) do
    UE4.UNRCStatics.ImmediateRemovePlotStreamingLevel(v)
  end
  table.clear(self.PlotLevelName)
end

function LoadLevelProcessor:ClearLevelNames()
  table.clear(self.PlotLevelName)
end

function LoadLevelProcessor:Destroy()
  self:RemoveStoryLevels()
end

return LoadLevelProcessor
