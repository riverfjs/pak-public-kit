local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local ActorTagProcessor = StoryFlagProcessorBase:Extend("ActorTagProcessor")
local SharedActorArray = UE.TArray(UE.AActor)

function ActorTagProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.TagStateCache = {}
end

function ActorTagProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  local Tag = Conf.action_string_param
  local bEnable = HasFlag
  if ActionType == Enum.StoryFlagAction.SFA_ACTOR_TAG_CLOSE then
    bEnable = not HasFlag
  end
  if not table.contains(Conf.action_int_param, SceneResConf.id) then
    return
  end
  self:ToggleActorWithFlags(World, Tag, bEnable)
end

function ActorTagProcessor:PostProcess(World, SceneResConf)
  table.clear(self.TagStateCache)
end

function ActorTagProcessor:ToggleActorWithFlags(World, Tag, Enable)
  if not World then
    return
  end
  if string.IsNilOrEmpty(Tag) then
    return
  end
  local Cache = self.TagStateCache[Tag]
  if nil ~= Cache and Cache == Enable then
    Log.Debug("Skip tag", Tag, Enable)
    return
  end
  self.TagStateCache[Tag] = Enable
  UE.UGameplayStatics.GetAllActorsWithTag(World, Tag, SharedActorArray)
  if 0 == SharedActorArray:Length() then
    return
  end
  for _, Actor in tpairs(SharedActorArray) do
    if Actor:IsA(UE.AEnvSystemVolume) then
      Log.Debug("Toggle Volume", Tag, Enable)
      Actor.IsUsedVolume = Enable
      Actor.BlendWeight = Enable and 1 or 0
    else
    end
  end
  SharedActorArray:Clear()
end

function ActorTagProcessor:Destroy()
  table.clear(self.TagStateCache)
end

return ActorTagProcessor
