local StoryFlagProcessorBase = require("NewRoco.Modules.System.StoryFlag.Processors.StoryFlagProcessorBase")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local TodLockProcessor = StoryFlagProcessorBase:Extend("TodLockProcessor")

function TodLockProcessor:Ctor(Module)
  StoryFlagProcessorBase.Ctor(self, Module)
  self.TodLockFlags = {}
  self.StoryFlagTimeHandler = nil
end

function TodLockProcessor:Process(World, HasFlag, ID, Conf, SceneResConf, ActionType)
  local SceneID = Conf.action_int_param[1]
  if SceneID == SceneResConf.id and HasFlag then
    if not self.TodLockFlags or not self.TodLockFlags[1] then
      self.TodLockFlags = {}
      self.TodLockFlags[1] = ID
    elseif ID > self.TodLockFlags[1] then
      table.insert(self.TodLockFlags, 1, ID)
    else
      table.insert(self.TodLockFlags, ID)
    end
  end
end

function TodLockProcessor:PostProcess(World, SceneResConf)
  local TodLockFlags = self.TodLockFlags
  if TodLockFlags and TodLockFlags[1] then
    local Conf = _G.DataConfigManager:GetFunctionStoryFlagConf(TodLockFlags[1])
    local SceneID = Conf.action_int_param[1]
    local LockTime = Conf.action_int_param[2] / 3600
    if self.StoryFlagTimeHandler then
      if self.StoryFlagTimeHandler.SceneID ~= SceneID or self.StoryFlagTimeHandler.FlagID ~= TodLockFlags[1] then
        _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.ReleaseTime, self.StoryFlagTimeHandler)
        self.StoryFlagTimeHandler = _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.RegisterTime, LockTime)
        self.StoryFlagTimeHandler.SceneID = SceneID
        self.StoryFlagTimeHandler.FlagID = TodLockFlags[1]
      end
    else
      self.StoryFlagTimeHandler = _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.RegisterTime, LockTime)
      self.StoryFlagTimeHandler.SceneID = SceneID
      self.StoryFlagTimeHandler.FlagID = TodLockFlags[1]
    end
    if table.len(TodLockFlags) > 1 then
      self:ShowTodLockDebugPopup(TodLockFlags, SceneID)
    end
  elseif self.StoryFlagTimeHandler then
    _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.ReleaseTime, self.StoryFlagTimeHandler)
    self.StoryFlagTimeHandler = nil
  end
  table.clear(self.TodLockFlags)
end

function TodLockProcessor:ShowTodLockDebugPopup(flags, sceneResId)
  local Ctx = DialogContext()
  local flagTxt = ""
  for _, id in pairs(flags) do
    flagTxt = flagTxt .. tostring(id) .. ", "
  end
  local conf = _G.DataConfigManager:GetLocalizationConf("tod_lock_conflict")
  Ctx:SetContent(string.format(conf.msg, flagTxt, sceneResId))
  Ctx:SetMode(DialogContext.Mode.OK)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function TodLockProcessor:Destroy()
  if self.StoryFlagTimeHandler then
    _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.ReleaseTime, self.StoryFlagTimeHandler)
    self.StoryFlagTimeHandler = nil
  end
  table.clear(self.TodLockFlags)
end

return TodLockProcessor
