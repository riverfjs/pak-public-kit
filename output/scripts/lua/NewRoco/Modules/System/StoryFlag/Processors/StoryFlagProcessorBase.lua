local Class = _G.MakeSimpleClass
local StoryFlagProcessorBase = Class("StoryFlagProcessorBase")

function StoryFlagProcessorBase:Ctor(Module)
  self.Module = Module
  self._processed = false
end

function StoryFlagProcessorBase:PreProcess(World, SceneResConf)
end

function StoryFlagProcessorBase:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
end

function StoryFlagProcessorBase:PostProcess(World, SceneResConf)
end

function StoryFlagProcessorBase:Destroy()
end

return StoryFlagProcessorBase
