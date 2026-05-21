local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local MagicReplayUtils = {}

function MagicReplayUtils.IsRecordEndTeleportEnabled()
  local conf = _G.DataConfigManager:GetGlobalConfig("mark_video_reset_startpoint")
  if conf and conf.num then
    return 1 == conf.num
  end
  return false
end

function MagicReplayUtils.IsMarkVideoNameShowEnabled()
  local conf = _G.DataConfigManager:GetGlobalConfig("mark_video_name_show")
  if conf and conf.num then
    return 1 == conf.num
  end
  return false
end

function MagicReplayUtils.GetRecordingMaxTime()
  local conf = _G.DataConfigManager:GetGlobalConfig("mark_video_rec_time")
  if conf and conf.numList and conf.numList[1] then
    return conf.numList[1]
  end
  return 30
end

function MagicReplayUtils.GetFsmStateTypeByName(name)
  if "RecordPrepareState" == name or "RecordProcessState" == name then
    return MagicReplayModuleEnum.ModuleOpType.Record
  elseif "PreviewPrepareState" == name or "PreviewProcessState" == name then
    return MagicReplayModuleEnum.ModuleOpType.Preview
  elseif "ReplayPrepareState" == name or "ReplayProcessState" == name then
    return MagicReplayModuleEnum.ModuleOpType.Replay
  elseif "ShareState" == name then
    return MagicReplayModuleEnum.ModuleOpType.Share
  else
    return MagicReplayModuleEnum.ModuleOpType.Other
  end
end

function MagicReplayUtils.IsOpActivated(opType)
  if opType == MagicReplayModuleEnum.ModuleOpType.Record then
    return _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_MARK_VIDEO_REC)
  elseif opType == MagicReplayModuleEnum.ModuleOpType.Preview then
    return _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY)
  elseif opType == MagicReplayModuleEnum.ModuleOpType.Replay then
    return _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH)
  elseif opType == MagicReplayModuleEnum.ModuleOpType.Share then
    return _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE)
  else
    return false
  end
end

function MagicReplayUtils.ModifyPlayerConditionType(playerConditionType, isAdd)
  local counter = _G.FunctionBanManager:GetConditionCounter(playerConditionType)
  if isAdd then
    if not counter then
      _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, playerConditionType)
    end
  elseif counter then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, playerConditionType)
  end
end

function MagicReplayUtils.isMagicReplayActivated()
  return MagicReplayUtils.IsOpActivated(MagicReplayModuleEnum.ModuleOpType.Record) or MagicReplayUtils.IsOpActivated(MagicReplayModuleEnum.ModuleOpType.Preview) or MagicReplayUtils.IsOpActivated(MagicReplayModuleEnum.ModuleOpType.Replay) or MagicReplayUtils.IsOpActivated(MagicReplayModuleEnum.ModuleOpType.Share)
end

function MagicReplayUtils.ClearThrowBalls()
  local main_actor_id = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetMainMagicActorId)
  if main_actor_id then
    local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
    if NPCModule and NPCModule.ThrowSessionManager then
      local throwSessionManager = NPCModule.ThrowSessionManager
      local BallMap = throwSessionManager:GetBallMap(main_actor_id)
      for Ball, _ in pairs(BallMap) do
        local Session = Ball.ThrowSession
        if Session then
          _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowBallById, main_actor_id, Session:GetThrowID())
        end
      end
    end
  end
end

return MagicReplayUtils
