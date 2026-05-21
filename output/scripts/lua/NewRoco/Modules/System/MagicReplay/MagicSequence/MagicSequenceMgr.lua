local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local MagicMsgFramePostProcesser = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicMsgFramePostProcesser")
local MagicSequence = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSequence")
local MagicSeqForRecord = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSeqForRecord")
local MagicSeqForReplay = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicSeqForReplay")
local MIN_FREE_DISK_SPACE = 5
local MAX_SEQ_FILE_NUM = 1000
local CD_FOR_REPLAY = 500
local MagicSequenceMgr = _G.Class("MagicSequenceMgr")

function MagicSequenceMgr:Ctor()
  self:InitVideoProtocolConf()
  self.curMagicSeqForRecord = nil
  self.curMagicSeqForReplay = nil
  self.lastReplayTime = 0
  self.downloadServiceRefMap = {}
  self.uploadServiceRefMap = {}
  MagicSequence.MakeSureSequenceDirectoryExists()
  UE4.UNRCStatics.ManageFileLimitInDirectory(MagicSequence.AbsoluteMagicSequenceDirectory(), "*.seq", MAX_SEQ_FILE_NUM)
end

function MagicSequenceMgr:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("MagicSequenceMgr", self, MagicReplayModuleEvent.OnMagicReplayInterrupt, self.OnRecordInterrupt)
  _G.NRCEventCenter:RegisterEvent("MagicSequenceMgr", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function MagicSequenceMgr:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.OnMagicReplayInterrupt, self.OnRecordInterrupt)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function MagicSequenceMgr:InitVideoProtocolConf()
  self.markVideoProtocolConf = {}
  local AllDatas = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.MARK_VIDEO_PROTOCOL):GetAllDatas()
  for _, v in pairs(AllDatas) do
    local conf = v
    local newKey = ".Next."
    if conf.protocol_id == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
      newKey = newKey .. conf.protocol_string .. "_" .. conf.SpaceActionType_string
    else
      newKey = newKey .. conf.protocol_string
    end
    self.markVideoProtocolConf[newKey] = conf
  end
end

function MagicSequenceMgr:GetVideoProtocolConf(fullName)
  if self.markVideoProtocolConf and fullName then
    return self.markVideoProtocolConf[fullName]
  end
  return nil
end

function MagicSequenceMgr:PreProcessReplayPb(protocolID, playActName, bytes, msgSize, decodedMsg)
  local protocolName = _G.ProtoCMD:GetMessageName(protocolID)
  local protocolFullName = protocolName
  if protocolID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY then
    protocolFullName = protocolName .. "_" .. playActName
  end
  if protocolFullName and MagicMsgFramePostProcesser[protocolFullName] and MagicMsgFramePostProcesser[protocolFullName].OutFunc then
    local result, errMsg = MagicMsgFramePostProcesser[protocolFullName].OutFunc(decodedMsg, self.curMagicSeqForReplay or self.curMagicSeqForRecord)
    if result then
      Log.Debug("[MagicSequence][Mgr] PreProcessReplayPb successfully", protocolID, protocolName, playActName, msgSize)
      return true, decodedMsg
    else
      Log.Error("[MagicSequence][Mgr] PreProcessReplayPb failed, OutFunc return false, errMsg:", errMsg)
      return false, decodedMsg
    end
  end
  return false, decodedMsg
end

function MagicSequenceMgr:ReceiveRecordPb(protocolID, playActName, bytes, msgSize, decodedMsg, receiveTimeMS)
  if self.curMagicSeqForRecord and not self.curMagicSeqForRecord.bRecordFinish then
    return self.curMagicSeqForRecord:ReceiveRecordPb(protocolID, playActName, bytes, msgSize, decodedMsg, receiveTimeMS)
  end
  return false
end

function MagicSequenceMgr:SaveMagicSeqRecord()
  if self.curMagicSeqForRecord then
    if self.curMagicSeqForRecord.bRecordFinish then
      if not self:HasFreeDiskSpace() then
        Log.Error("[MagicSequence][Mgr] SaveMagicSeqRecord failed, no free disk space!")
        return false
      end
      if self.curMagicSeqForRecord:SaveToFile() then
        Log.Debug("[MagicSequence][Mgr] SaveMagicSeqRecord successfully!", self.curMagicSeqForRecord.major_ver, self.curMagicSeqForRecord.minor_ver, self.curMagicSeqForRecord.logic_ver)
        return true
      end
    else
      Log.Error("[MagicSequence][Mgr] SaveMagicSeqRecord failed, curMagicSeqForRecord bRecordFinish is false!")
    end
  else
    Log.Error("[MagicSequence][Mgr] SaveMagicSeqRecord failed, curMagicSeqForRecord is nil!")
  end
  return false
end

function MagicSequenceMgr:GetCurSeqForReplay()
  return self.curMagicSeqForReplay
end

function MagicSequenceMgr:GetCurSeqForRecord()
  return self.curMagicSeqForRecord
end

function MagicSequenceMgr:IsSeqExists(fileName)
  local fileFullName = MagicSequence.ConvertToFullFilName(fileName)
  if UE4.UBlueprintPathsLibrary.FileExists(fileFullName) then
    return true
  end
  return false
end

function MagicSequenceMgr:DelSeq(fileName)
  local fileFullName = MagicSequence.ConvertToFullFilName(fileName)
  if UE4.UBlueprintPathsLibrary.FileExists(fileFullName) then
    UE4.UNRCStatics.DeleteToFile(fileFullName)
    Log.Debug("[MagicSequence][Mgr] DelSeq successfully!", fileName)
  else
    Log.Error("[MagicSequence][Mgr] DelSeq failed, file not exits, ", fileFullName)
  end
end

function MagicSequenceMgr:OnTick(deltaTime)
  if self.curMagicSeqForReplay and self.curMagicSeqForReplay:IsPlaying() then
    local bEnd = self.curMagicSeqForReplay:Tick(deltaTime)
    if bEnd then
      Log.Debug("[MagicSequence][Mgr] OnTick EndPlay for MagicSeqForReplay,", self.curMagicSeqForReplay:GetFileName())
      self.curMagicSeqForReplay:EndPlay()
      _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqReplayEnd, self.curMagicSeqForReplay:GetFileName())
      self.curMagicSeqForReplay = nil
      _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.SetMainMagicActorId, nil)
    end
  elseif self.curMagicSeqForRecord and self.curMagicSeqForRecord.bPreview then
    local bEnd = self.curMagicSeqForRecord:Tick(deltaTime)
    if bEnd then
      Log.Debug("[MagicSequence][Mgr] OnTick EndPreview for MagicSeqForRecord,", self.curMagicSeqForRecord:GetFileName())
      self.curMagicSeqForRecord:EndPlay()
      _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqPreviewEnd, self.curMagicSeqForRecord:GetFileName())
      self.curMagicSeqForRecord.bPreview = false
      _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.SetMainMagicActorId, nil)
    end
  end
end

function MagicSequenceMgr:ResetRecord()
  if self.curMagicSeqForRecord then
    Log.Debug("[MagicSequence][Mgr] ResetRecord!")
    if self.curMagicSeqForRecord.bPreview then
      self.curMagicSeqForRecord:EndPlay()
    end
    self.curMagicSeqForRecord:Close()
    self.curMagicSeqForRecord = nil
  end
end

function MagicSequenceMgr:ResetReplay()
  if self.curMagicSeqForReplay then
    self.lastReplayTime = os.msTime()
    if self.curMagicSeqForReplay:IsPlaying() then
      self.curMagicSeqForReplay:EndPlay()
    end
    if self.curMagicSeqForReplay.file then
      self.curMagicSeqForReplay:Close()
    end
    self.curMagicSeqForReplay = nil
  end
end

function MagicSequenceMgr:ClearSeqInfo()
  self.curMagicSeqForReplay = nil
  self.curMagicSeqForRecord = nil
end

function MagicSequenceMgr:OnRecordStart()
  Log.Debug("[MagicSequence][Mgr] OnRecordStart")
  self:ResetRecord()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    Log.Error("[MagicSequence][Mgr] OnRecordStart, can not record magic sequence with out local player!")
    return false
  end
  local recordInitInfo = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if recordInitInfo then
    self.curMagicSeqForRecord = MagicSeqForRecord(localPlayer:GetLogicId(), recordInitInfo.create_pos)
  else
    Log.Error("[MagicSequence][Mgr] OnRecordStart failed, GetRecordFeedInitInfo return nil!")
    return false
  end
  return true
end

function MagicSequenceMgr:OnRecordEnd()
  Log.Debug("[MagicSequence][Mgr] OnRecordEnd")
  if self.curMagicSeqForRecord then
    self.curMagicSeqForRecord:EndRecord()
  end
end

function MagicSequenceMgr:OnRecordInterrupt()
  Log.Debug("[MagicSequence][Mgr] OnRecordInterrupt")
  self:ResetRecord()
  self:ResetReplay()
end

function MagicSequenceMgr:OnReconnect()
  Log.Debug("[MagicSequence][Mgr] OnReconnect")
  self:StopReplay()
  self:StopPreview()
  self:ClearSeqInfo()
end

function MagicSequenceMgr:HasFreeDiskSpace()
  local FreeDiskSpace = UE.UNRCStatics.GetFreeDiskSpace()
  Log.Debug("[MagicSequence][Mgr] free disk space:", FreeDiskSpace, ", min free disk space:", MIN_FREE_DISK_SPACE)
  if FreeDiskSpace > MIN_FREE_DISK_SPACE then
    return true
  end
  return false
end

function MagicSequenceMgr:ReqUploadMagicSeq(uploadUrl, fileName, caller, callback)
  if not uploadUrl then
    Log.Error("[MagicSequence][Mgr] ReqUploadMagicSeq failed without uploadUrl!")
    return
  end
  if not fileName then
    Log.Error("[MagicSequence][Mgr] ReqUploadMagicSeq failed without fileName!")
    return
  end
  if not callback then
    Log.Error("[MagicSequence][Mgr] ReqUploadMagicSeq failed without callback!")
    return
  end
  if self.uploadServiceRefMap[fileName] then
    Log.Debug("[MagicSequence][Mgr] ReqUploadMagicSeq already in progress, ", fileName)
    return
  end
  Log.Debug("[MagicSequence][Mgr] ReqUploadMagicSeq Start", fileName, uploadUrl)
  local fullFileName = MagicSequence.ConvertToFullFilName(fileName)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  self.uploadServiceRefMap[fileName] = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetHeader("Content-Type", "image/png")
  HttpService:SetFile(fullFileName)
  HttpService:SetUrl(uploadUrl)
  HttpService:SetVerb("PUT")
  HttpService:Request({
    HttpService,
    function(_, Status)
      self.uploadServiceRefMap[fileName] = nil
      if Status == UE.EHttpServiceStatus.RspSuccess then
        Log.Debug("[MagicSequence][Mgr] upload success,", fileName, uploadUrl)
        _G.tcall(caller, callback, fileName, true)
      else
        Log.Error("[MagicSequence][Mgr] upload failed,", fileName, uploadUrl)
        _G.tcall(caller, callback, fileName, false)
      end
    end
  })
end

function MagicSequenceMgr:ReqDownloadMagicSeq(feedVideoInfo, caller, callback)
  if not feedVideoInfo or not feedVideoInfo.file_url then
    Log.Error("[MagicSequence][Mgr] ReqDownloadMagicSeq failed without fileUrl!")
    return
  end
  if not feedVideoInfo.file_name then
    Log.Error("[MagicSequence][Mgr] ReqDownloadMagicSeq failed without fileName!")
    return
  end
  if not callback then
    Log.Error("[MagicSequence][Mgr] ReqDownloadMagicSeq failed without callback!")
    return
  end
  local downloadUrl = feedVideoInfo.file_url
  local fileName = feedVideoInfo.file_name
  if self:IsDebugReplay() then
    fileName = self.debugReplayFileName
    Log.Error("[MagicSequence][Mgr] [Debug] ReqDownloadMagicSeq", fileName)
  end
  local fullFileName = MagicSequence.ConvertToFullFilName(fileName)
  if UE4.UBlueprintPathsLibrary.FileExists(fullFileName) then
    local localFileMD5 = UE.UNRCStatics.HashFileMD5(fullFileName)
    if localFileMD5 == feedVideoInfo.file_md5 or self:IsDebugReplay() then
      Log.Debug("[MagicSequence][Mgr] ReqDownloadMagicSeq, file already exits, ", fullFileName)
      _G.tcall(caller, callback, fileName, true)
      return
    else
      UE4.UNRCStatics.DeleteToFile(fullFileName)
    end
  end
  if not self:HasFreeDiskSpace() then
    Log.Error("[MagicSequence][Mgr] ReqDownloadMagicSeq, no enough disk space, ", fullFileName)
    local conf = _G.DataConfigManager:GetLocalizationConf("mark_video_no_disk")
    if nil ~= conf then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, conf.msg)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "mark_video_no_disk")
    end
    _G.tcall(caller, callback, fileName, false)
    return
  end
  Log.Debug("[MagicSequence][Mgr] ReqDownloadMagicSeq Start", fileName, downloadUrl)
  MagicSequence.MakeSureSequenceDirectoryExists()
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  self.downloadServiceRefMap[fileName] = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetUrl(downloadUrl)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(Service, Status)
      if Status == UE4.EHttpServiceStatus.RspSuccess then
        Service:SaveToFile(fullFileName)
        local rspContent = HttpService:GetRspContent()
        if rspContent:sub(1, 5) == "<?xml" then
          Log.Error("[MagicSequence][Mgr] download failed with xml,", fileName, downloadUrl)
          _G.tcall(caller, callback, fileName, false)
        else
          Log.Debug("[MagicSequence][Mgr] download success", fileName, downloadUrl)
          _G.tcall(caller, callback, fileName, true)
        end
      else
        Log.Debug("[MagicSequence][Mgr] download failed", fileName, downloadUrl)
        _G.tcall(caller, callback, fileName, false)
      end
      self.downloadServiceRefMap[fileName] = nil
    end
  })
end

function MagicSequenceMgr:CanReplay()
  local curTime = os.msTime()
  local deltaTime = curTime - self.lastReplayTime
  if deltaTime < CD_FOR_REPLAY then
    Log.Debug("[MagicSequence][Mgr] can not replay, CD not over", curTime - self.lastReplayTime, CD_FOR_REPLAY)
    return false
  end
  return true
end

function MagicSequenceMgr:StartReplay(fileName, createPos, baseInfoMd5, fileMd5)
  if not fileName then
    Log.Error("[MagicSequence][Mgr] StartReplay failed, without fileName")
    return false
  end
  local curTime = os.msTime()
  local deltaTime = curTime - self.lastReplayTime
  if deltaTime < CD_FOR_REPLAY then
    Log.Error("[MagicSequence][Mgr] StartReplay failed, replay CD not over", curTime - self.lastReplayTime, CD_FOR_REPLAY)
    return false
  end
  if self:IsDebugReplay() then
    fileName = self.debugReplayFileName
    Log.Error("[MagicSequence][Mgr] [Debug] StartReplay", fileName)
  end
  local fullFileName = MagicSequence.ConvertToFullFilName(fileName)
  if not UE4.UBlueprintPathsLibrary.FileExists(fullFileName) then
    Log.Error("[MagicSequence][Mgr] StartReplay failed, fullFileName not exits, ", fullFileName)
    return false
  end
  local localFileMD5 = UE.UNRCStatics.HashFileMD5(fullFileName)
  if localFileMD5 ~= fileMd5 and not self:IsDebugReplay() then
    Log.Error("[MagicSequence][Mgr] StartReplay failed, file md5 not match", fileMd5, localFileMD5)
    self.curMagicSeqForReplay = nil
    return false
  end
  self:ResetReplay()
  self.curMagicSeqForReplay = MagicSeqForReplay(fileName, createPos)
  self.curMagicSeqForReplay.fileMD5 = localFileMD5
  if not self.curMagicSeqForReplay:ReadFromFile() then
    self.curMagicSeqForReplay = nil
    return false
  end
  if self.curMagicSeqForReplay.baseInfoMD5 ~= baseInfoMd5 and not self:IsDebugReplay() then
    Log.Error("[MagicSequence][Mgr] StartReplay failed, baseInfo md5 not match", baseInfoMd5, self.curMagicSeqForReplay.baseInfoMD5)
    self.curMagicSeqForReplay = nil
    return false
  end
  if not self.curMagicSeqForReplay:BeginPlay() then
    return false
  end
  self.lastReplayTime = os.msTime()
  return true
end

function MagicSequenceMgr:StopReplay()
  self:ResetReplay()
end

function MagicSequenceMgr:StartPreview()
  if self.curMagicSeqForRecord then
    if self.curMagicSeqForRecord:BeginPlay() then
      self.curMagicSeqForRecord.bPreview = true
      Log.Debug("[MagicSequence][Mgr] StartPreview ", self.curMagicSeqForRecord:GetFileName())
    end
  else
    Log.Error("[MagicSequence][Mgr] StartPreview current record is nil!")
  end
end

function MagicSequenceMgr:StopPreview()
  if self.curMagicSeqForRecord and self.curMagicSeqForRecord.bPreview then
    self.curMagicSeqForRecord:EndPlay()
  end
end

function MagicSequenceMgr:GMSwitchDebugReplay(isDebugReplay, fileName)
  if RocoEnv.IS_SHIPPING then
    return
  end
  self.isDebugReplay = isDebugReplay
  self.debugReplayFileName = fileName
end

function MagicSequenceMgr:IsDebugReplay()
  return self.isDebugReplay and self.debugReplayFileName and self.debugReplayFileName ~= ""
end

return MagicSequenceMgr
