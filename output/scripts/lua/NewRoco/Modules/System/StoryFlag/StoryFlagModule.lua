local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local StoryFlagModuleEvent = require("NewRoco.Modules.System.StoryFlag.StoryFlagModuleEvent")
local ActorTagProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.ActorTagProcessor")
local TaskBGMProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.TaskBGMProcessor")
local LoadLevelProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.LoadLevelProcessor")
local OpenLightLevelProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.OpenLightLevelProcessor")
local TaskPreloadProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.TaskPreloadProcessor")
local TodLockProcessor = require("NewRoco.Modules.System.StoryFlag.Processors.TodLockProcessor")
local StoryFlagModule = NRCModuleBase:Extend("StoryFlagModule")

function StoryFlagModule:OnConstruct()
  _G.StoryFlagModuleCmd = reload("NewRoco.Modules.System.StoryFlag.StoryFlagModuleCmd")
  self.ClientFlags = table.new(0, 32)
  self.SameSceneRes = false
  local actorTagProcessor = ActorTagProcessor(self)
  self.Processors = {
    [Enum.StoryFlagAction.SFA_ACTOR_TAG_OPEN] = actorTagProcessor,
    [Enum.StoryFlagAction.SFA_ACTOR_TAG_CLOSE] = actorTagProcessor,
    [Enum.StoryFlagAction.SFA_TASK_BGM] = TaskBGMProcessor(self),
    [Enum.StoryFlagAction.SFA_LOAD_LEVEL] = LoadLevelProcessor(self),
    [Enum.StoryFlagAction.SFA_OPEN_LIGHT_LEVEL] = OpenLightLevelProcessor(self),
    [Enum.StoryFlagAction.SFA_TASK_PRELOAD] = TaskPreloadProcessor(self),
    [Enum.StoryFlagAction.SFA_TOD_LOCK] = TodLockProcessor(self)
  }
  self:RegisterCmd(_G.StoryFlagModuleCmd.GetCurrentStoryBgmState, self.GetCurrentStoryBgmState)
  self:RegisterCmd(_G.StoryFlagModuleCmd.GetLoadSceneList, self.GetLoadSceneList)
end

function StoryFlagModule:OnActive()
  self:BuildClientFlags()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryFlag)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.ON_HOME_OWNER_STORY_FLAG_CHANGED, self.UpdateHomeOwnerStoryFlag)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.PreLoadMapStart, self.OnPreLoadMapStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.BeforeLandPos, self.OnMapLoaded)
end

function StoryFlagModule:OnDeactive()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.ON_HOME_OWNER_STORY_FLAG_CHANGED, self.UpdateHomeOwnerStoryFlag)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryFlag)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnPreLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.BeforeLandPos, self.OnMapLoaded)
  for _, processor in pairs(self.Processors) do
    if processor and processor.Destroy then
      processor:Destroy()
    end
  end
end

function StoryFlagModule:BuildClientFlags()
  local Count = 0
  local RawConfs = _G.DataConfigManager:GetAllByName("FUNCTION_STORY_FLAG_CONF")
  for ID, Conf in pairs(RawConfs) do
    local ActionType = Conf.story_flag_action_type
    if self.Processors[ActionType] then
      self.ClientFlags[ID] = Conf
      Count = Count + 1
    end
  end
  Log.Debug("StoryFlagModule:BuildClientFlags", Count)
end

function StoryFlagModule:OnRelogin()
  self:UpdateStoryFlag()
end

function StoryFlagModule:OnPreLoadMapStart(SameSceneRes, bReconnecting, id)
  self.SameSceneRes = SameSceneRes
end

function StoryFlagModule:OnMapLoaded()
  Log.Debug("StoryFlagModule:OnMapLoaded")
  if not self.SameSceneRes then
    local loadLevelProcessor = self.Processors[Enum.StoryFlagAction.SFA_LOAD_LEVEL]
    if loadLevelProcessor and loadLevelProcessor.ClearLevelNames then
      loadLevelProcessor:ClearLevelNames()
    end
  end
  self:UpdateStoryFlag()
end

function StoryFlagModule:UpdateHomeOwnerStoryFlag(bFlag)
  self:UpdateStoryFlag()
  _G.NRCEventCenter:DispatchEvent(StoryFlagModuleEvent.OnHomeOwnerStoryFlagChange, bFlag)
end

function StoryFlagModule:UpdateStoryFlag(changedFlag)
  local StoryFlags = _G.DataModelMgr.PlayerDataModel:GetStoryFlags()
  local HomeOwnerFlags = _G.DataModelMgr.PlayerDataModel:GetHomeOwnerStoryFlags()
  local World = _G.UE4Helper.GetCurrentWorld()
  local SceneResConf = SceneUtils.GetSceneResConf()
  for _, Processor in pairs(self.Processors) do
    if Processor._processed then
      Processor._processed = false
    end
  end
  local changedFlagConf = changedFlag and _G.DataConfigManager:GetFunctionStoryFlagConf(changedFlag, true)
  local changedFlagType = changedFlagConf and changedFlagConf.story_flag_action_type
  for ID, Conf in pairs(self.ClientFlags) do
    local ActionType = Conf.story_flag_action_type
    if changedFlagType and changedFlagType ~= ActionType then
    else
      local HasFlag = false
      if _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(ID) then
        HasFlag = table.contains(StoryFlags, ID)
      else
        HasFlag = table.contains(HomeOwnerFlags, ID)
      end
      local Processor = self.Processors[ActionType]
      if Processor then
        if not Processor._processed and Processor.PreProcess then
          Processor:PreProcess(World, SceneResConf)
        end
        if Processor.Process then
          Processor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
        end
        Processor._processed = true
      end
    end
  end
  for _, Processor in pairs(self.Processors) do
    if Processor._processed then
      if Processor.PostProcess then
        Processor:PostProcess(World, SceneResConf)
      end
      Processor._processed = false
    end
  end
  _G.NRCEventCenter:DispatchEvent(StoryFlagModuleEvent.OnStoryFlagChange)
end

function StoryFlagModule:GetCurrentStoryBgmState(AreaFuncID)
  local taskBGMProcessor = self.Processors[Enum.StoryFlagAction.SFA_TASK_BGM]
  if taskBGMProcessor and taskBGMProcessor.GetCurrentStoryBgmState then
    return taskBGMProcessor:GetCurrentStoryBgmState(AreaFuncID)
  end
  return ""
end

function StoryFlagModule:GetLoadSceneList(SceneID)
  local openLightLevelProcessor = self.Processors[Enum.StoryFlagAction.SFA_OPEN_LIGHT_LEVEL]
  if openLightLevelProcessor and openLightLevelProcessor.GetLoadSceneList then
    return openLightLevelProcessor:GetLoadSceneList(SceneID)
  end
  return nil
end

return StoryFlagModule
