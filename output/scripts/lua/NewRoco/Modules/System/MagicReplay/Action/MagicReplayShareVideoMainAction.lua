local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local MagicReplayActionBase = require("NewRoco.Modules.System.MagicReplay.Action.MagicReplayActionBase")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local ShareModuleEvent = require("NewRoco.Modules.System.Share.ShareModuleEvent")
local NRCPanelEnum = require("Core.NRCPanel.NRCPanelEnum")
local Base = MagicReplayActionBase
local MagicReplayShareVideoMainAction = Base:Extend("MagicReplayShareVideoMainAction")
FsmUtils.MergeMembers(Base, MagicReplayShareVideoMainAction, {
  {
    name = "ParentModule",
    type = "var"
  }
})

function MagicReplayShareVideoMainAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function MagicReplayShareVideoMainAction:OnEnter()
  self:InjectProperties()
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.timeout = MagicReplayUtils.GetRecordingMaxTime() + 5
  local replayFeedDetail = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetReplayFeedDetail)
  self.mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if self.mainUIModule then
    self.mainUIModule:ClosePanel("ShowMagicMessage")
  end
  self.shareVideoName = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetCurrentShareVideoName) .. "_" .. UE.UNRCStatics.GetTimestampMS()
  self.delayId = _G.DelayManager:DelaySeconds(0.5, function()
    self.switchCam = false
    self.localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    _G.NRCEventCenter:RegisterEvent("MagicReplayShareVideoMainAction", self, MagicReplayModuleEvent.OnMagicSeqPlayerSpawned, self.OnMagicSeqPlayerSpawned)
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, true)
    local success = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.StartReplay, replayFeedDetail.feed_video_info.file_name, replayFeedDetail.feed_info.create_pos, replayFeedDetail.feed_video_info.base_info_md5, replayFeedDetail.feed_video_info.file_md5)
    _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, MagicReplayModuleEvent.StopReplayProcess, self.StopReplay)
    _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, MagicReplayModuleEvent.OnMagicSeqReplayEnd, self.StopReplay)
    _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
    _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnStartReplayProcess)
    if not success then
      self:StopReplay()
    else
      self.fsm:Pause()
    end
  end)
end

function MagicReplayShareVideoMainAction:OnMagicSeqPlayerSpawned()
  if self.switchCam then
    return
  end
  self.playerCameraManager = self.localPlayer:GetUEController().PlayerCameraManager
  if self.playerCameraManager then
    local main_actor_id = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetMainMagicActorId)
    if main_actor_id then
      local main_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, main_actor_id)
      if main_player and main_player.viewObj then
        self.playerCameraManager:BeginFilming(main_player.viewObj, true)
        self.switchCam = true
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.StartRecordVideo, self.playerCameraManager, self.shareVideoName, true)
  _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingMagicVideo, true)
end

function MagicReplayShareVideoMainAction:StopReplay()
  self.fsm:Resume()
  self:Finish()
end

function MagicReplayShareVideoMainAction:OnFinish()
  self:Clear()
  self.fsm:Resume()
end

function MagicReplayShareVideoMainAction:OnExit()
  _G.DelayManager:CancelDelayById(self.delayId)
  if not self.finished then
    self:Clear()
    self.fsm:Resume()
  end
end

function MagicReplayShareVideoMainAction:OnEnterBackground()
  self:StopReplay()
end

function MagicReplayShareVideoMainAction:Clear()
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.StopReplay)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.OnMagicSeqReplayEnd, self.StopReplay)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.StopReplayProcess, self.StopReplay)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, false)
  if self.playerCameraManager then
    self.playerCameraManager:EndFilming()
  end
  _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.EndRecordVideo, self.shareVideoName, true)
  local feedDetail = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetReplayFeedDetail)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenShowMagicMessage, feedDetail)
  _G.NRCEventCenter:RegisterEvent("MagicReplayReplayMainAction", self, ShareModuleEvent.VideoRecordSuccess, self.ReceiveFileExit)
end

function MagicReplayShareVideoMainAction:ReceiveFileExit(VideoPathAbs, VideoCoverPathAbs)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareModuleEvent.VideoRecordSuccess, self.ReceiveFileExit)
  local TempVideos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempVideos"
  })
  local videoName = not string.IsNilOrEmpty(self.shareVideoName) and self.shareVideoName or "unknown"
  local videoPath = UE.UNRCStatics.ConvertToAbsolutePath(UE.UBlueprintPathsLibrary.Combine({
    TempVideos,
    videoName .. ".mp4"
  }), true)
  if videoPath == VideoPathAbs then
    local imagePath = UE.UNRCStatics.ConvertToAbsolutePath(UE.UBlueprintPathsLibrary.Combine({
      TempVideos,
      videoName .. ".jpg"
    }), true)
    local imageObj = _G.NRCModuleManager:GetModule("TakePhotosModule"):UpdatePhotoBigTexture(imagePath)
    local data = {
      VideoPath = videoPath,
      VideoCoverPath = imagePath,
      ImageObj = imageObj,
      sharePartId = 901,
      shareBaseId = 9,
      shareVideoName = self.shareVideoName
    }
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.OpenShareUIPanel, data)
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingMagicVideo, false)
  end
end

return MagicReplayShareVideoMainAction
