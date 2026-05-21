local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local Base = require("NewRoco.Modules.Core.Fsm.FsmState")
local MagicReplayFsmState = Base:Extend("MagicReplayFsmState")

function MagicReplayFsmState:Ctor(name, properties, mode, actions, transitions)
  Base.Ctor(self, name, properties, mode, actions, transitions)
end

function MagicReplayFsmState:OnEnter(fsm)
  Base.OnEnter(self, fsm)
  local stateName = self:GetName()
  if "RecordPrepareState" == stateName then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.MagicReplay)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, true)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, false)
  elseif "PreviewPrepareState" == stateName then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.MagicReplay)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, true)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, false)
  elseif "ShareState" == stateName then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.MagicReplay)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, true)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, false)
  elseif "ReplayPrepareState" == stateName or "ReplayIdleState" == stateName then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.MagicReplay)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, true)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, false)
  elseif "ShareVideoState" == stateName then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.MagicReplay)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, false)
    MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, true)
  end
end

function MagicReplayFsmState:OnExit()
  Base.OnExit(self)
end

return MagicReplayFsmState
