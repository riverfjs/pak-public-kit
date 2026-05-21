local Base = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSequence")
local MagicMsgFrame = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicMsgFrame")
local MagicMsgFramePostProcesser = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicMsgFramePostProcesser")
local MagicSeqForRecord = Base:Extend("MagicSeqForRecord")
local LOGIC_VERSION_CONF_ID = 1003

function MagicSeqForRecord:Ctor(playerUin, createPos)
  self.playerUin = playerUin
  self.associatedActorIds = {}
  self.firstReceiveTimeMS = 0
  self.bPreview = false
  self.bRecordFinish = false
  local fileName = tostring(self.playerUin) .. "_" .. UE.UNRCStatics.GetTimestampMS()
  Base.Ctor(self, fileName, "w", createPos)
  local conf = _G.DataConfigManager:GetMarkGameplayConf(LOGIC_VERSION_CONF_ID)
  self.logic_ver = conf.version
  local recordRange = _G.DataConfigManager:GetGlobalConfig("mark_video_rec_range")
  if recordRange and recordRange.numList and #recordRange.numList >= 2 then
    self.recordRadius = recordRange.numList[1] * 100
    self.recordHeight = recordRange.numList[2] * 100
  else
    self.recordRadius = 1500
    self.recordHeight = 5000
  end
  self.baseInfo.player_pos = self.createPos
  self.baseInfo.version = self.logic_ver
  Log.Debug("[MagicSequence][Record] Ctor", self:GetFileName())
end

function MagicSeqForRecord:ReceiveRecordPb(protocolID, playActName, bytes, msgSize, decodedMsg, receiveTimeMS)
  local protocolName = _G.ProtoCMD:GetMessageName(protocolID)
  local protocolFullName = protocolName
  if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
    protocolFullName = protocolName .. "_" .. playActName
  end
  if 0 == self.firstReceiveTimeMS and 0 == #self.sequence then
    self.firstReceiveTimeMS = receiveTimeMS
    if protocolID ~= _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY or "actor_enter" ~= playActName then
      Log.Error("[MagicSequence][Record] ReceiveRecordPb, the first message must be the AOI of local player #0!")
      return false
    else
      local notify = decodedMsg
      if notify and notify.acts and notify.acts[1] and notify.acts[1].actor_enter and notify.acts[1].actor_enter.actors[1] then
        local actor = notify.acts[1].actor_enter.actors[1]
        local uin = actor.avatar.base.logic_id
        if actor.actor_detail_type ~= _G.ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal or uin ~= self.playerUin then
          Log.Error("[MagicSequence][Record] ReceiveRecordPb, the first message must be the AOI of local player #1!")
          return false
        end
      end
    end
  end
  if protocolFullName and MagicMsgFramePostProcesser[protocolFullName] and MagicMsgFramePostProcesser[protocolFullName].InFunc then
    local inFuncRet = MagicMsgFramePostProcesser[protocolFullName].InFunc(decodedMsg, self)
    if inFuncRet then
      local frameTime = receiveTimeMS - self.firstReceiveTimeMS
      local msgFrame = MagicMsgFrame(protocolID, playActName, frameTime, msgSize, bytes)
      table.insert(self.sequence, msgFrame)
      if msgFrame.playActName == "actor_leave" then
        table.insert(self.actorLeaves, #self.sequence)
      end
      Log.Debug("[MagicSequence][Record] ReceiveRecordPb", protocolID, _G.ProtoCMD:GetMessageName(protocolID), playActName, msgSize, receiveTimeMS)
    end
  end
  return true
end

function MagicSeqForRecord:EndRecord()
  self.bRecordFinish = true
  if self.sequence and #self.sequence > 0 then
    local deltaFrameTime = self.sequence[#self.sequence].frameTime - self.sequence[1].frameTime
    self.duration = deltaFrameTime / 1000
  end
  Log.Debug("[MagicSequence][Record] EndRecord", #self.sequence, self.duration)
end

function MagicSeqForRecord:SetPreview(preview)
  self.bPreview = preview
end

function MagicSeqForRecord:SaveToFile()
  if not self:CreateFile() then
    return false
  end
  if not self:WriteBaseInfo() then
    return false
  end
  if not self:WriteSequence() then
    return false
  end
  self:Close()
  self.baseInfoMD5 = self:ComputeBaseInfoMD5()
  self.fileMD5 = self:ComputeFileMD5()
  Log.Debug("[MagicSequence][Record] SaveToFile", self:GetFileName(), self.baseInfoMD5, self.fileMD5)
  return true
end

function MagicSeqForRecord:EndPlay()
  Base.EndPlay(self)
  self.bPreview = false
end

function MagicSeqForRecord:GetCurRecordDuration()
  local curDuration = 0
  if self.sequence and #self.sequence > 0 then
    local deltaFrameTime = self.sequence[#self.sequence].frameTime - self.sequence[1].frameTime
    curDuration = deltaFrameTime / 1000
  end
  return curDuration
end

return MagicSeqForRecord
