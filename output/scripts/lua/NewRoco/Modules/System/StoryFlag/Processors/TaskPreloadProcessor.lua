local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local StoryFlagPreloadLists = require("NewRoco.Modules.Core.Task.PreloadRes.StoryFlagPreloadLists")
local TaskPreloadProcessor = StoryFlagProcessorBase:Extend("TaskPreloadProcessor")

function TaskPreloadProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.PreloadedRequests = {}
  self.PreloadedRefs = {}
end

function TaskPreloadProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  self:TogglePreload(HasFlag, ID)
end

function TaskPreloadProcessor:TogglePreload(HasFlag, Flag)
  local List = StoryFlagPreloadLists[Flag]
  if not List then
    return
  end
  if HasFlag then
    for Key, Value in pairs(List) do
      if self.PreloadedRequests[Key] then
      else
        local Res = _G.NRCBigWorldPreloader:Get(Key)
        if Res then
        else
          local Req = _G.NRCResourceManager:LoadResAsync(self, Value, 100, 0, self.PreloadFinish, self.PreloadFailed)
          self.PreloadedRequests[Key] = Req
        end
      end
    end
  else
    for Key, _ in pairs(List) do
      local Req = self.PreloadedRequests[Key]
      if Req then
        _G.NRCResourceManager:UnLoadRes(Req)
        self.PreloadedRequests[Key] = nil
      end
      local Ref = self.PreloadedRefs[Key]
      if Ref then
        self.PreloadedRefs[Key] = nil
      end
    end
  end
end

function TaskPreloadProcessor:PreloadFinish(req, asset)
  self.PreloadedRefs[req.assetPath] = asset and UnLua.Ref(asset)
  Log.Debug("storyflag\233\162\132\229\138\160\232\189\189\230\136\144\229\138\159", req.assetPath)
end

function TaskPreloadProcessor:PreloadFailed(req, errMsg)
  Log.Error("\230\151\160\230\179\149\233\162\132\229\138\160\232\189\189", errMsg)
  _G.NRCResourceManager:UnLoadRes(req)
end

function TaskPreloadProcessor:Destroy()
  for Key, Req in pairs(self.PreloadedRequests) do
    _G.NRCResourceManager:UnLoadRes(Req)
  end
  table.clear(self.PreloadedRequests)
  table.clear(self.PreloadedRefs)
end

return TaskPreloadProcessor
