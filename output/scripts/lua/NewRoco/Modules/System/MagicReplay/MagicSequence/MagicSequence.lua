local MagicMsgFrame = require("NewRoco.Modules.System.MagicReplay.MagicSequence.MagicMsgFrame")
local Base = require("NewRoco.Modules.System.MagicReplay.MagicSequence.BinaryFile")
local pb = require("pb")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MAX_MAGIC_SEQUENCE_LENGTH = 30000
local MagicSeqDirectory = UE.UBlueprintPathsLibrary.Combine({
  UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
  "MagicSequence"
})
local MagicSeqFileExt = ".seq"
local MAGIC_SIZE = 4
local MAGIC_NUM = string.char(82, 79, 67, 79)
local MAJOR_VER = 1
local MINOR_VER = 2
local BASE_INFO_PB_NAME = ".Next.FeedVideoBaseInfo"
local MagicSequence = Base:Extend("MagicSequence")

function MagicSequence:Ctor(fileName, mode, createPos)
  if not UE.UNRCStatics.DirectoryExists(MagicSeqDirectory) then
    UE.UNRCStatics.MakeDirectory(MagicSeqDirectory)
  end
  self.fileName = fileName
  self.createPos = createPos
  local RelativeFullName = MagicSeqDirectory .. "/" .. self.fileName .. MagicSeqFileExt
  local AbsoluteFullName = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(RelativeFullName)
  Base.Ctor(self, AbsoluteFullName, mode)
  self.major_ver = MAJOR_VER
  self.minor_ver = MINOR_VER
  self.logic_ver = 1
  self.offsetOfBaseInfo = 0
  self.baseInfo = _G.ProtoMessage:newFeedVideoBaseInfo()
  self.baseInfoPbDataSize = 0
  self.baseInfoPbData = nil
  self.offsetOfSequence = 0
  self.sequence = {}
  self.duration = 0
  self.baseInfoMD5 = ""
  self.fileMD5 = ""
  self.totalPlayingTime = 0
  self.curPlayMsgIdx = 0
  self.actorLeaves = {}
end

function MagicSequence.MakeSureSequenceDirectoryExists()
  if not UE.UNRCStatics.DirectoryExists(MagicSeqDirectory) then
    UE.UNRCStatics.MakeDirectory(MagicSeqDirectory)
  end
end

function MagicSequence:CreateFile()
  if not Base.CreateFile(self) then
    return false
  end
  if self:InReadMode() then
    local magic_num_in_file = self:ReadMagic()
    if magic_num_in_file ~= MAGIC_NUM then
      Log.Error("[MagicSequence]: magic number not match!", magic_num_in_file, MAGIC_NUM)
      self:Close()
      return false
    end
    local read_major, read_minor, read_logic = self:ReadVersion()
    if read_major ~= self.major_ver then
      Log.Error("[MagicSequence]: major_ver not match!", read_major, self.major_ver)
      self:Close()
      return false
    end
    self.minor_ver = read_minor
    self.logic_ver = read_logic
  elseif self:InWriteMode() then
    self:WriteMagic()
    self:WriteVersion()
  end
  return true
end

function MagicSequence:WriteBaseInfo()
  if self.baseInfo then
    self:Seek(self.offsetOfBaseInfo)
    self.baseInfoPbData = pb.encode(BASE_INFO_PB_NAME, self.baseInfo)
    self.baseInfoPbDataSize = #self.baseInfoPbData
    local write_offset = self:WriteNumber(self.baseInfoPbDataSize)
    self:WriteRaw(self.baseInfoPbData)
    self.offsetOfSequence = self.offsetOfBaseInfo + write_offset + self.baseInfoPbDataSize
    self:WriteNumber(self.offsetOfSequence)
    Log.Debug("[MagicSequence] WriteBaseInfo", self:GetFileName(), self.offsetOfBaseInfo, self.baseInfoPbDataSize, self.offsetOfSequence)
    return true
  else
    Log.Error("[MagicSequence] WriteBaseInfo baseInfo is nil!")
  end
  return false
end

function MagicSequence:ReadBaseInfo()
  self:Seek(self.offsetOfBaseInfo)
  self.baseInfoPbDataSize = self:ReadNumber()
  self.baseInfoPbData = self:ReadRaw(self.baseInfoPbDataSize)
  self.baseInfo = pb.decode(BASE_INFO_PB_NAME, self.baseInfoPbData)
  if not self.baseInfo.fashion_id then
    self.baseInfo.fashion_id = {}
  end
  if not self.baseInfo.pet_base_id then
    self.baseInfo.pet_base_id = {}
  end
  if not self.baseInfo.chat_msg then
    self.baseInfo.chat_msg = {}
  end
  self.offsetOfSequence = self:ReadNumber()
  Log.Debug("[MagicSequence] ReadBaseInfo", self:GetFileName(), self.offsetOfBaseInfo, self.baseInfoPbDataSize, self.offsetOfSequence)
end

function MagicSequence:WriteMagicMsgFrame(msgFrame)
  if msgFrame and msgFrame.protocolId and msgFrame.msgSize and msgFrame.msg then
    self:WriteNumber(msgFrame.frameTime)
    self:WriteNumber(msgFrame.protocolId)
    self:WriteString(msgFrame.playActName)
    self:WriteNumber(msgFrame.msgSize)
    self:WriteRaw(msgFrame.msg)
  end
end

function MagicSequence:ReadMagicMsgFrame()
  local bActorLeave = false
  local msgFrame = MagicMsgFrame()
  msgFrame.frameTime = self:ReadNumber()
  msgFrame.protocolId = self:ReadNumber()
  msgFrame.playActName = self:ReadString()
  msgFrame.msgSize = self:ReadNumber()
  msgFrame.msg = self:ReadRaw(msgFrame.msgSize)
  if msgFrame.playActName == "actor_leave" then
    bActorLeave = true
  end
  Log.Debug("[MagicSequence] ReadMsgFrame", #self.sequence, msgFrame.frameTime, msgFrame.protocolId, msgFrame.playActName, msgFrame.msgSize)
  return msgFrame, bActorLeave
end

function MagicSequence:WriteSequence()
  if self.sequence and #self.sequence > 0 then
    self:Seek(self.offsetOfSequence)
    local seqLength = #self.sequence
    self:WriteNumber(seqLength)
    local lastFrameTime = 0
    for _, v in ipairs(self.sequence) do
      local seq = v
      self:WriteMagicMsgFrame(seq)
      lastFrameTime = v.frameTime
    end
    self.duration = lastFrameTime / 1000
    Log.Debug("[MagicSequence] WriteSequence length", seqLength, ",duration", self.duration)
    return true
  else
    Log.Error("[MagicSequence] WriteSequence sequence is empty!")
  end
  return false
end

function MagicSequence:ReadSequence()
  self:Seek(self.offsetOfSequence)
  local seqLength = self:ReadNumber()
  Log.Debug("[MagicSequence] ReadSequence length", seqLength)
  local i = 1
  local lastFrameTime = 0
  while seqLength >= i do
    local msgFrame, bActorLeave = self:ReadMagicMsgFrame()
    if bActorLeave then
      table.insert(self.actorLeaves, i)
    end
    table.insert(self.sequence, msgFrame)
    lastFrameTime = msgFrame.frameTime
    i = i + 1
  end
  self.duration = lastFrameTime / 1000
  Log.Debug("[MagicSequence] ReadSequence duration", self.duration)
end

function MagicSequence:WriteMagic()
  self:Seek(0)
  self:WriteRaw(MAGIC_NUM)
  Log.Debug("[MagicSequence] WriteMagic")
end

function MagicSequence:ReadMagic()
  self:Seek(0)
  local magic_data = self:ReadRaw(MAGIC_SIZE)
  if not magic_data or #magic_data < MAGIC_SIZE then
    Log.Error("[MagicSequence] ReadMagic failed!")
    return nil
  end
  Log.Debug("[MagicSequence] ReadMagic", magic_data)
  return magic_data
end

function MagicSequence:GetMagicNum()
  return MAGIC_NUM
end

function MagicSequence:WriteVersion()
  self:Seek(MAGIC_SIZE)
  self.offsetOfBaseInfo = MAGIC_SIZE
  local tempOffset = 0
  tempOffset = self:WriteNumber(self.major_ver)
  self.offsetOfBaseInfo = self.offsetOfBaseInfo + tempOffset
  tempOffset = self:WriteNumber(self.minor_ver)
  self.offsetOfBaseInfo = self.offsetOfBaseInfo + tempOffset
  tempOffset = self:WriteNumber(self.logic_ver)
  self.offsetOfBaseInfo = self.offsetOfBaseInfo + tempOffset
  self:WriteNumber(self.offsetOfBaseInfo)
  Log.Debug("[MagicSequence] WriteVersion", self.major_ver, self.minor_ver, self.logic_ver, self.offsetOfBaseInfo)
end

function MagicSequence:ReadVersion()
  self:Seek(MAGIC_SIZE)
  local major = self:ReadNumber()
  local minor = self:ReadNumber()
  local logic = self:ReadNumber()
  self.offsetOfBaseInfo = self:ReadNumber()
  Log.Debug("[MagicSequence] ReadVersion", major, minor, logic, self.offsetOfBaseInfo)
  return major, minor, logic
end

function MagicSequence:GetFileName()
  return self.fileName
end

function MagicSequence:GetFileNameWithExt()
  return self.fileName .. MagicSeqFileExt
end

function MagicSequence:GetFullFileName()
  return self.path
end

function MagicSequence.RelativeMagicSequenceDirectory()
  return MagicSeqDirectory
end

function MagicSequence.AbsoluteMagicSequenceDirectory()
  return UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(MagicSeqDirectory)
end

function MagicSequence.ConvertToFullFilName(fileName)
  return UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(MagicSeqDirectory) .. "/" .. fileName .. MagicSeqFileExt
end

function MagicSequence:GetDuration()
  return self.duration
end

function MagicSequence:ComputeBaseInfoMD5()
  if self.baseInfo then
    local str = ""
    if self.baseInfo.fashion_id then
      for i, v in ipairs(self.baseInfo.fashion_id) do
        str = str .. v
        if i ~= #self.baseInfo.fashion_id then
          str = str .. ","
        end
      end
      str = str .. ";"
    end
    if self.baseInfo.pet_base_id then
      for i, v in ipairs(self.baseInfo.pet_base_id) do
        str = str .. v
        if i ~= #self.baseInfo.pet_base_id then
          str = str .. ","
        end
      end
      str = str .. ";"
    end
    if self.baseInfo.chat_msg then
      for i, v in ipairs(self.baseInfo.chat_msg) do
        str = str .. v
        if i ~= #self.baseInfo.chat_msg then
          str = str .. ","
        end
      end
      str = str .. ";"
    end
    if self.baseInfo.player_pos then
      str = str .. self.baseInfo.player_pos.x .. "," .. self.baseInfo.player_pos.y .. "," .. self.baseInfo.player_pos.z
      str = str .. ";"
    end
    if self.baseInfo.version then
      str = str .. self.baseInfo.version
      str = str .. ";"
    end
    local strMd5 = UE.UNRCStatics.HashUTF8StringMD5(str)
    Log.Debug("[MagicSequence] ComputeBaseInfoMD5 source", str)
    Log.Debug("[MagicSequence] ComputeBaseInfoMD5", strMd5)
    return strMd5
  end
  return ""
end

function MagicSequence:ComputeFileMD5()
  return UE.UNRCStatics.HashFileMD5(self:GetFullFileName())
end

function MagicSequence:GetCreatePos()
  return self.createPos
end

function MagicSequence:Tick(deltaTime)
  if self:IsPlaying() then
    self.totalPlayingTime = self.totalPlayingTime + 1000 * deltaTime
    local curMsgFrame = self:GetCurMsgFrame()
    local bEnd = false
    while curMsgFrame and curMsgFrame.frameTime <= self.totalPlayingTime do
      bEnd = self:PlayCurMsgFrame()
      if bEnd then
        break
      end
      curMsgFrame = self:GetCurMsgFrame()
    end
    return bEnd
  end
end

function MagicSequence:IsPlaying()
  return self.curPlayMsgIdx > 0
end

function MagicSequence:BeginPlay()
  if self:IsPlaying() then
    Log.Error("[MagicSequence] BeginPlay failed, seq already playing!")
    return false
  end
  if #self.sequence <= 0 then
    Log.Error("[MagicSequence] BeginPlay failed, no sequences for playing!")
    return false
  end
  self.curPlayMsgIdx = 1
  Log.Debug("[MagicSequence] BeginPlay", self.fileName)
  return true
end

function MagicSequence:EndPlay()
  if self.curPlayMsgIdx <= #self.sequence and #self.actorLeaves > 0 then
    for i = 1, #self.actorLeaves do
      local curIdx = self.actorLeaves[i]
      if curIdx >= self.curPlayMsgIdx and curIdx <= #self.sequence then
        Log.Debug("[MagicSequence] EndPlay force actor_leave", curIdx)
        self:PlayMsgFrame(curIdx)
      end
    end
  end
  self.totalPlayingTime = 0
  self.curPlayMsgIdx = 0
  Log.Debug("[MagicSequence] EndPlay")
end

function MagicSequence:GetCurMsgFrame()
  if self.curPlayMsgIdx <= #self.sequence then
    return self.sequence[self.curPlayMsgIdx]
  end
  return nil
end

function MagicSequence:GetPlayProgress()
  return self.totalPlayingTime / 1000
end

function MagicSequence:PlayCurMsgFrame()
  if self.curPlayMsgIdx <= #self.sequence then
    local msgFrame = self.sequence[self.curPlayMsgIdx]
    _G.NRCNetworkManager:ReceiveLocalMsg(_G.ZoneServer.connectID, msgFrame.msg, msgFrame.msgSize)
    if self.curPlayMsgIdx == #self.sequence then
      return true
    end
    self.curPlayMsgIdx = self.curPlayMsgIdx + 1
  end
  return false
end

function MagicSequence:PlayMsgFrame(msgIdx)
  if msgIdx and msgIdx >= 1 and msgIdx <= #self.sequence then
    local msgFrame = self.sequence[msgIdx]
    _G.NRCNetworkManager:ReceiveLocalMsg(_G.ZoneServer.connectID, msgFrame.msg, msgFrame.msgSize)
  end
end

return MagicSequence
