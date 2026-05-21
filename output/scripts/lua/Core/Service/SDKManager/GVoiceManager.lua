local GVoiceManager = _G.Singleton:Extend("GVoiceManager")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")

function GVoiceManager:Ctor()
  self:RegisterEvent()
end

function GVoiceManager:RegisterEvent()
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.PlayerBornFinish, self.BeginReceiver)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnApplicationHasEnteredForeground)
end

function GVoiceManager:Init(PlayerUin)
  self.GVoiceMgrInstance = UE.UNRCVoiceManager.GetInstance()
  self.GVoiceMgrInstanceRef = UnLua.Ref(self.GVoiceMgrInstance)
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:InitVoice(tostring(PlayerUin), "", true, true)
    self:BeginReceiver()
    self:RegisterDelegate()
    self.GVoiceMgrInstance:ApplyMessageKey()
  else
    Log.Warning("GVoiceManager: OnActive Failed GVoiceMgrInstance is nil")
  end
end

function GVoiceManager:OnEnterBackground()
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:Pause()
  end
end

function GVoiceManager:OnApplicationHasEnteredForeground()
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:Resume()
  end
end

function GVoiceManager:BeginReceiver()
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:BeginReceiver(_G.UE4Helper.GetCurrentWorld())
  end
end

function GVoiceManager:SetMode(GCloudVoiceMode)
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:SetMode(GCloudVoiceMode)
  end
end

function GVoiceManager:RegisterDelegate()
  if self.GVoiceMgrInstance then
    self.GVoiceMgrInstance:GetVoiceDelegate().VoiceMessageKeyResult:Add(self.GVoiceMgrInstance, self.VoiceMessageKeyResultHandle)
    self.GVoiceMgrInstance:GetVoiceDelegate().VoiceStreamSpeechToText:Add(self.GVoiceMgrInstance, self.VoiceStreamSpeechToTextHandle)
    self.GVoiceMgrInstance:GetVoiceDelegate().PlayRecordedFileFinished:Add(self.GVoiceMgrInstance, self.PlayRecordedFileFinishedHanle)
  end
end

function GVoiceManager:VoiceMessageKeyResultHandle(GCloudVoiceCompleteCode)
  Log.Debug("GVoiceManager:VoiceMessageKeyResultHandle GCloudVoiceCompleteCode is ", GCloudVoiceCompleteCode)
end

function GVoiceManager:VoiceStreamSpeechToTextHandle(Code, Error, Result, VoicePath)
  local Text = string.format("GVoiceManager:VoiceStreamSpeechToTextHandle Code = %s Error = %s Result = %s, VoicePath = %s", Code, Error, Result, VoicePath)
  Log.Debug(Text)
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.VoiceStreamSpeechToTextHandle, Code, Error, Result, VoicePath)
end

function GVoiceManager:PlayRecordedFileFinishedHanle(code, filePath)
  Log.Debug(string.format("GVoiceManager:PlayRecordedFileFinishedHanle code = %s, filePath = %s", code, filePath))
  _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnPlayRecordedFileFinished, code, filePath)
end

function GVoiceManager:GetMicLevel()
  if self.GVoiceMgrInstance then
    local level = self.GVoiceMgrInstance:GetMicLevel(true)
    status = level > 1000 and 1 or 0
    Log.Debug("GVoiceManager:OnMicStateDelegateHandle is ", level, status)
    return level / 65535
  end
  return 0
end

function GVoiceManager:PlayRecordedFile(filePath)
  local RetCode = -1
  if self.GVoiceMgrInstance then
    RetCode = self.GVoiceMgrInstance:PlayRecordedFile(filePath)
    Log.Debug(string.format("GVoiceManager:PlayRecordedFile RetCode is:%d, filePath:%s ", RetCode, filePath))
  end
  return RetCode
end

function GVoiceManager:StopPlayRecordedFile()
  if self.GVoiceMgrInstance then
    return self.GVoiceMgrInstance:StopPlayRecordedFile()
  end
  return -1
end

function GVoiceManager:GetSpeakerLevel()
  if self.GVoiceMgrInstance then
    local level = self.GVoiceMgrInstance:GetSpeakerLevel()
    return level / 65535
  end
  return 0
end

function GVoiceManager:StartRecording(FilePath, bRSTT)
  if self.GVoiceMgrInstance then
    return self.GVoiceMgrInstance:StartRecording(FilePath, bRSTT)
  end
  return -1
end

function GVoiceManager:StopRecording(bRSTT)
  if self.GVoiceMgrInstance then
    return self.GVoiceMgrInstance:StopRecording(bRSTT)
  end
  return -1
end

function GVoiceManager:Free()
  self.GVoiceMgrInstance = nil
  self.GVoiceMgrInstanceRef = nil
end

return GVoiceManager
