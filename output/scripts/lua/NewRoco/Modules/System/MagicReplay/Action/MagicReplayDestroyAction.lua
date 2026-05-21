local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local MagicReplayModuleCmd = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleCmd")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local MagicReplayConst = require("NewRoco.Modules.System.MagicReplay.MagicReplayConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local HoldingItemComponent = require("NewRoco.Modules.Core.Scene.Component.Show.HoldingItemComponent")
local MagicReplayActionBase = require("NewRoco.Modules.System.MagicReplay.Action.MagicReplayActionBase")
local CameraModuleCmd = reload("NewRoco.Modules.System.Camera.CameraModuleCmd")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local Base = MagicReplayActionBase
local MagicReplayDestroyAction = Base:Extend("MagicReplayDestroyAction")
FsmUtils.MergeMembers(Base, MagicReplayDestroyAction, {
  {
    name = "ParentModule",
    type = "var"
  },
  {
    name = "bIsReconnect",
    type = "var"
  },
  {
    name = "ReplayNpcId",
    type = "var"
  }
})

function MagicReplayDestroyAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function MagicReplayDestroyAction:ResetCamera()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerCameraManager = localPlayer:GetUEController().PlayerCameraManager
  if playerCameraManager then
    playerCameraManager:EndFilming()
  end
end

function MagicReplayDestroyAction:ResetLocalPlayer()
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, false, UE4.EPlayerForceHiddenType.MagicReplay)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MagicReplay)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local localPlayerId = localPlayer.serverData.base.actor_id
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ShowOwnPetByPlayerId, localPlayerId, true, NPCModuleEnum.NpcReasonFlags.MAGIC_REPLAY)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdSwitchChatBubbles, localPlayer.viewObj, true)
end

function MagicReplayDestroyAction:ResetUI()
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.CloseRecordPanel)
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.CloseReplayPanel)
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.CloseToolExitButtonPopup)
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.CloseToolRestartButtonPopup)
  _G.NRCModeManager:DoCmd(_G.ShareUIModuleCmd.CloseShareUIPanel, false)
end

function MagicReplayDestroyAction:ResetNpc()
  local recordInitInfo = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if recordInitInfo then
    local npc = _G.NRCModeManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFakeId, recordInitInfo.npc_id)
    if npc and npc.viewObj then
      local childActor = npc.viewObj.NRCChildActor
      if childActor then
        local Actor = childActor:GetChildActor()
        if Actor and Actor.CloseAirWall then
          Actor:CloseAirWall()
        end
      end
    end
  end
  local RecordNPC = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordNPC)
  if RecordNPC and RecordNPC.viewObj and RecordNPC.viewObj.DeactivateMagicReplayCheck then
    RecordNPC.viewObj:DeactivateMagicReplayCheck()
  end
  if self.ReplayNpcId and 0 ~= self.ReplayNpcId then
    local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.ReplayNpcId)
    if npc and npc.viewObj and npc.viewObj.DeactivateMagicReplayCheck then
      npc.viewObj:DeactivateMagicReplayCheck()
    end
  end
end

function MagicReplayDestroyAction:ResetBalls()
  MagicReplayUtils.ClearThrowBalls()
end

function MagicReplayDestroyAction:CheckDestroyCommon()
end

function MagicReplayDestroyAction:CheckDestroyInBattle()
end

function MagicReplayDestroyAction:ContinueDestroyInBlack()
  self:CheckDestroyCommon()
  self:FinishDestroy()
end

function MagicReplayDestroyAction:ResetPlayerCondition()
  MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REC, false)
  MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_REPLAY, false)
  MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_SHARE, false)
  MagicReplayUtils.ModifyPlayerConditionType(Enum.PlayerConditionType.PCT_MARK_VIDEO_WATCH, false)
end

function MagicReplayDestroyAction:ResetMagicSequenceMgr()
  _G.NRCModeManager:DoCmd(MagicReplayModuleCmd.StopPreview)
  _G.NRCModeManager:DoCmd(MagicReplayModuleCmd.StopReplay)
end

function MagicReplayDestroyAction:ResetTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.MagicReplay)
end

function MagicReplayDestroyAction:OnEnter()
  Log.Debug("MagicReplayDestroyAction:OnEnter")
  self:InjectProperties()
  _G.NRCAudioManager:SetStateByName("MagicReplay", "Close", "MagicReplayDestroyAction:OnEnter")
  self.ParentModule = self:GetProperty("ParentModule")
  self.ReplayNpcId = self:GetProperty("ReplayNpcId")
  self:ResetMagicSequenceMgr()
  self:ResetLocalPlayer()
  self:ResetPlayerCondition()
  self:ResetUI()
  self:ResetNpc()
  self:ResetBalls()
  self:ResetCamera()
  self:ResetTips()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_WHITE_SCREEN)
  self:Finish()
end

function MagicReplayDestroyAction:FinishDestroy()
  self:Finish()
end

function MagicReplayDestroyAction:DestroyStageActor()
end

function MagicReplayDestroyAction:OnExit()
end

function MagicReplayDestroyAction:OnFinish()
end

return MagicReplayDestroyAction
