local FarmModuleEvent = require("NewRoco.Modules.System.Farm.FarmModuleEvent")
local MagicReplayModuleData = _G.NRCData:Extend("MagicReplayModuleData")

function MagicReplayModuleData:Ctor()
  NRCData.Ctor(self)
  self:InitMagicBan()
  self:InitUploadInfo()
  self.recordFeedInitInfo = nil
  self.replayFeedDetail = nil
  self.replayNpcId = nil
  self.mainMagicActorId = nil
  self.replaySeqInfo = nil
end

function MagicReplayModuleData:InitUploadInfo()
  self.uploadInfo = nil
end

function MagicReplayModuleData:InitMagicBan()
end

return MagicReplayModuleData
