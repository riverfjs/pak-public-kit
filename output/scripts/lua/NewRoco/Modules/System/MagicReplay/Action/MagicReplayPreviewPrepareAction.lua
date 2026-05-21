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
local MagicReplayPreviewPrepareAction = Base:Extend("MagicReplayPreviewPrepareAction")
FsmUtils.MergeMembers(Base, MagicReplayPreviewPrepareAction, {
  {
    name = "ParentModule",
    type = "var"
  },
  {name = "CurrentOp", type = "var"}
})

function MagicReplayPreviewPrepareAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function MagicReplayPreviewPrepareAction:OnEnter()
  self:InjectProperties()
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OpenRecordPanel)
  local recordInitInfo = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
  if recordInitInfo then
    local npc = _G.NRCModeManager:DoCmd(_G.MagicMessageModuleCmd.GetVideoByFakeId, recordInitInfo.npc_id)
    if npc and npc.viewObj then
      npc.viewObj.NRCChildActor:GetChildActor():CloseAirWall()
    end
  end
  self.fsm:SetProperty("CurrentOp", MagicReplayModuleEnum.ModuleOpType.Preview)
  self:Finish()
end

function MagicReplayPreviewPrepareAction:OnExit()
end

return MagicReplayPreviewPrepareAction
