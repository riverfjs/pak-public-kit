local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local MagicReplayActionBase = require("NewRoco.Modules.System.MagicReplay.Action.MagicReplayActionBase")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local Base = MagicReplayActionBase
local MagicReplayReplayMainAction = Base:Extend("MagicReplayReplayMainAction")
FsmUtils.MergeMembers(Base, MagicReplayReplayMainAction, {
  {
    name = "ParentModule",
    type = "var"
  }
})

function MagicReplayReplayMainAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function MagicReplayReplayMainAction:OnEnter()
  self:InjectProperties()
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.timeout = MagicReplayUtils.GetRecordingMaxTime() + 5
  local replayFeedDetail = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetReplayFeedDetail)
  local success = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.StartReplay, replayFeedDetail.feed_video_info.file_name, replayFeedDetail.feed_info.create_pos, replayFeedDetail.feed_video_info.base_info_md5, replayFeedDetail.feed_video_info.file_md5)
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.SetReplaySeqInfo)
  _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, MagicReplayModuleEvent.StopReplayProcess, self.StopReplay)
  _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, MagicReplayModuleEvent.OnMagicSeqReplayEnd, self.StopReplay)
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnStartReplayProcess)
  if not success then
    self:StopReplay()
  else
    self.fsm:Pause()
  end
end

function MagicReplayReplayMainAction:StopReplay()
  MagicReplayUtils.ClearThrowBalls()
  self.fsm:Resume()
  self:Finish()
end

function MagicReplayReplayMainAction:OnFinish()
  self.fsm:Resume()
  self:Clear()
end

function MagicReplayReplayMainAction:OnExit()
  if not self.finished then
    self.fsm:Resume()
    self:Clear()
  end
end

function MagicReplayReplayMainAction:Clear()
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.StopReplay)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.OnMagicSeqReplayEnd, self.StopReplay)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.StopReplayProcess, self.StopReplay)
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnStopReplayProcess)
end

return MagicReplayReplayMainAction
