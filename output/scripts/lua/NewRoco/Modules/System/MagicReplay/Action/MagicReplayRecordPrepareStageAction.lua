local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local MagicReplayActionBase = require("NewRoco.Modules.System.MagicReplay.Action.MagicReplayActionBase")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local Base = MagicReplayActionBase
local MagicReplayRecordPrepareStageAction = Base:Extend("MagicReplayRecordPrepareStageAction")
FsmUtils.MergeMembers(Base, MagicReplayRecordPrepareStageAction, {
  {
    name = "ParentModule",
    type = "var"
  },
  {name = "CurrentOp", type = "var"}
})

function MagicReplayRecordPrepareStageAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function MagicReplayRecordPrepareStageAction:OnEnter()
  self:InjectProperties()
  self.ParentModule = self:GetProperty("ParentModule")
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, false, UE4.EPlayerForceHiddenType.MagicReplay)
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OpenRecordPanel)
  local recordInitInfo = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if recordInitInfo then
    local npc = _G.NRCModeManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFakeId, recordInitInfo.npc_id)
    if npc and npc.viewObj then
      npc.viewObj:ActivateMagicReplayCheck()
      npc.viewObj.NRCChildActor:GetChildActor():OpenAirWall()
    end
  end
  self.fsm:SetProperty("CurrentOp", MagicReplayModuleEnum.ModuleOpType.Record)
  self.fsm:Pause()
end

function MagicReplayRecordPrepareStageAction:OnExit()
  self.fsm:Resume()
end

return MagicReplayRecordPrepareStageAction
