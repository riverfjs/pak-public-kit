local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueSyncEndAction = Base:Extend("DialogueSyncEndAction")
FsmUtils.MergeMembers(Base, DialogueSyncEndAction, {
  {
    name = "DialogueConf",
    type = "var"
  },
  {name = "ConfID", type = "var"},
  {name = "TargetNPC", type = "var"},
  {name = "NPCOption", type = "var"}
})

function DialogueSyncEndAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueSyncEndAction:OnEnter()
  self:InjectProperties()
  if not (self.NPCOption and self.NPCOption.config) or not not self.NPCOption.config.dialogue_transmission_2P then
    self:Finish()
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and not player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      local other_player_id = other_player:GetServerId()
      local req = _G.ProtoMessage:newZoneClientOperationReq()
      req.operation.operator_id = player:GetServerId()
      req.operation.operator_type = ProtoEnum.ClientOperationType.COT_TOGETHER_DIALOGUE
      req.operation.aim_info = nil
      req.operation.npc_action_info = nil
      req.operation.catch_info = nil
      req.operation.player_perform_info = nil
      req.operation.cinematic_info = nil
      req.operation.dialogue_info.target_npc_id = other_player_id
      req.operation.dialogue_info.dialogue_id = self.ConfID
      req.operation.dialogue_info.sync_type = ProtoEnum.PlayerOperationSyncType.POST_END
      req.operation.dialogue_info.dialogue_npc_id = self.TargetNPC and self.TargetNPC.serverData and self.TargetNPC.serverData.npc_base.npc_content_cfg_id or 0
      req.operation.movie_info = nil
      Log.Debug("DialogueSyncEndAction:OnEnter, send client operation %d %s", self.ConfID, "Skip")
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req, self, self.OnSyncReqRsp)
    end
  end
  self:Finish()
end

function DialogueSyncEndAction:OnSyncReqRsp(rsp)
  Log.Debug("DialogueSyncEndAction:OnSyncReqRsp, on client operation req rsp", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function DialogueSyncEndAction:OnExit()
end

return DialogueSyncEndAction
