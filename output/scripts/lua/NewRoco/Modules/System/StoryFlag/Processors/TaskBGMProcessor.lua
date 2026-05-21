local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local TaskBGMProcessor = StoryFlagProcessorBase:Extend("TaskBGMProcessor")

function TaskBGMProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.AreaBGMMap = {}
  self.GlobalBGMData = nil
  self.FlagToMusicMap = {}
end

function TaskBGMProcessor:PreProcess(World, SceneResConf)
  if self.AreaBGMMap then
    table.clear(self.AreaBGMMap)
  else
    self.AreaBGMMap = {}
  end
  self.GlobalBGMData = nil
end

function TaskBGMProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  local AreaFuncIDs = Conf.action_int_param
  local BGMState = Conf.action_string_param
  if HasFlag then
    if not AreaFuncIDs or 0 == #AreaFuncIDs then
      if not self.GlobalBGMData then
        self.GlobalBGMData = {BGMState = BGMState, FlagID = ID}
      elseif ID > self.GlobalBGMData.FlagID then
        self.GlobalBGMData.BGMState = BGMState
        self.GlobalBGMData.FlagID = ID
      end
    else
      for _, AreaFuncID in ipairs(AreaFuncIDs) do
        local BestData = self.AreaBGMMap[AreaFuncID]
        if not BestData then
          self.AreaBGMMap[AreaFuncID] = {BGMState = BGMState, FlagID = ID}
        elseif ID > BestData.FlagID then
          BestData.BGMState = BGMState
          BestData.FlagID = ID
        end
      end
    end
  end
end

function TaskBGMProcessor:PostProcess(World, SceneResConf)
end

function TaskBGMProcessor:GetCurrentStoryBgmState(AreaFuncID)
  local BGMData
  if self.GlobalBGMData then
    BGMData = self.GlobalBGMData
  elseif AreaFuncID and self.AreaBGMMap[AreaFuncID] then
    BGMData = self.AreaBGMMap[AreaFuncID]
  end
  if not BGMData then
    return ""
  end
  local FlagID = BGMData.FlagID
  local BGMState = BGMData.BGMState
  if not self.FlagToMusicMap[FlagID] then
    if not string.IsNilOrEmpty(BGMState) then
      BGMState = string.format("Task_Music;Task_Music;%s", BGMState)
    end
    self.FlagToMusicMap[FlagID] = BGMState
  end
  return self.FlagToMusicMap[FlagID]
end

function TaskBGMProcessor:Destroy()
  self.AreaBGMMap = nil
  self.GlobalBGMData = nil
  self.FlagToMusicMap = nil
  StoryFlagProcessorBase.Destroy(self)
end

return TaskBGMProcessor
