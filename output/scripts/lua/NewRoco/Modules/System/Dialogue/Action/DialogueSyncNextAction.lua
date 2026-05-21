local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueSyncNextAction = Base:Extend("DialogueSyncNextAction")
FsmUtils.MergeMembers(Base, DialogueSyncNextAction, {
  {name = "ConfID", type = "var"},
  {name = "TargetNPC", type = "var"},
  {name = "Action", type = "var"},
  {name = "NPCOption", type = "var"}
})

function DialogueSyncNextAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueSyncNextAction:OnEnter()
  self:InjectProperties()
  if not (self.NPCOption and self.NPCOption.config) or not not self.NPCOption.config.dialogue_transmission_2P then
    self:Finish()
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and not player:IsTogetherMove2P() and self.ConfID > 0 then
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
      req.operation.dialogue_info.sync_type = DialogueUtils.IsEntryDialogue(self.fsm) and ProtoEnum.PlayerOperationSyncType.POST_START or ProtoEnum.PlayerOperationSyncType.POST_NEXT
      req.operation.dialogue_info.dialogue_npc_id = self.TargetNPC and self.TargetNPC.serverData and self.TargetNPC.serverData.npc_base.npc_content_cfg_id or 0
      req.operation.dialogue_info.select_ids = self:GetSelections()
      req.operation.dialogue_info.last_select_id = self:GetLastSelectID()
      req.operation.dialogue_info.progress = 22
      req.operation.dialogue_info.option_conf_id = self.NPCOption.config.id
      req.operation.movie_info = nil
      Log.Debug("DialogueSyncNextAction:OnEnter, send client operation %d %s", self.ConfID, req.operation.dialogue_info.sync_type == ProtoEnum.PlayerOperationSyncType.POST_START and "Start" or "Next")
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req, self, self.OnSyncReqRsp)
    end
  end
  self:Finish()
end

function DialogueSyncNextAction:OnSyncReqRsp(rsp)
  Log.Debug("DialogueSyncNextAction:OnSyncReqRsp, on client operation req rsp", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function DialogueSyncNextAction:OnExit()
end

function DialogueSyncNextAction:GetSelections()
  local SelectIds = {}
  if self.Action and self.Action.select_infos then
    local SelectInfos = self.Action.select_infos
    if SelectInfos then
      for _, Info in ipairs(SelectInfos) do
        if not Info.enabled then
        else
          local Conf = _G.DataConfigManager:GetSelectConf(Info.select_id)
          if not Conf then
          else
            table.insert(SelectIds, Info.select_id)
          end
        end
      end
    end
  end
  return SelectIds
end

function DialogueSyncNextAction:GetLastSelectID()
  local LastSelection = self.fsm:GetProperty("LastSelection", nil)
  self.fsm:SetProperty("LastSelection", nil)
  return LastSelection and LastSelection.id or 0
end

return DialogueSyncNextAction
