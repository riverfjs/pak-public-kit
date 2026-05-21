local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local NPCActionFactory = require("NewRoco.Modules.Core.NPC.Actions.NPCActionFactory")
local Base = DialogueActionBase
local DialogueWaitSkipAction = Base:Extend("DialogueWaitSkipAction")
FsmUtils.MergeMembers(Base, DialogueWaitSkipAction, {
  {
    name = "DialogueConf",
    type = "var"
  },
  {
    name = "ParentModule",
    type = "var"
  },
  {name = "ConfID", type = "var"},
  {name = "LastConfID", type = "var"},
  {name = "Option", type = "var"}
})

function DialogueWaitSkipAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueWaitSkipAction:OnEnter()
  self:InjectProperties()
  local DummyConf = {}
  DummyConf.speed = 0.0
  DummyConf.ui_source_type = Enum.UIsourceType.UIT_BLACK
  self.ParentModule:_OpenMainPanelByName("DialogueBlack", DummyConf, nil, nil, self.OnSkipBlackFadeIn, self)
  self.ParentModule.PreUIType = Enum.UIsourceType.UIT_BLACK
  self.ParentModule:StopCurDialogueAudio()
end

function DialogueWaitSkipAction:OnSkipBlackFadeIn()
  self:SendNextActReq()
end

function DialogueWaitSkipAction:SendNextActReq()
  if not self.DialogueConf or not self.Option then
    Log.Warning("DialogueWaitSkipAction:SendNextActReq, Fail to find DialogueConfigure or NpcOption")
    self:Finish()
    return
  end
  local NextActReq = ProtoMessage:newZoneSceneNpcNextActReq()
  NextActReq.npc_id = self.Option.owner.serverData.base.actor_id
  NextActReq.option_id = self.Option.optionInfo.option_id
  NextActReq.battle_radius = _G.BattleConst.Define.BattleFieldRange
  NextActReq.cur_dialog_id = self.DialogueConf.id
  NextActReq.begin_skip_dialog = true
  if self.Option.owner then
    NextActReq.npc_pt = self.Option.owner:GetServerPoint()
  end
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    NextActReq.avatar_pt = localPlayer:GetServerPoint()
  end
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.NPCTalk)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, NextActReq, self, self.OnNextActReqRsp, false, false)
end

function DialogueWaitSkipAction:OnNextActReqRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("[DialogueFlow]DialogueWaitSkipAction:OnNextActReqRsp", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
    self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
    return
  end
  Log.Debug("DialogueWaitSkipAction:OnNextActReqRsp", self.DialogueConf.id, rsp.ret_info.ret_code)
  self:CheckActionNotify()
end

function DialogueWaitSkipAction:CheckActionNotify()
  if not self.DialogueConf or not self.Option then
    Log.Warning("DialogueWaitSkipAction:Check, Fail to find DialogueConfigure or NpcOption")
    self:Finish()
    return
  end
  local LastDialogueID = 0
  local NextDialogueID = self.DialogueConf.id
  local bSkipCommitted = false
  local SkippedDialogueIDs = {}
  Log.DebugFormat("DialogueWaitSkipAction:Check, check start from %d", NextDialogueID)
  while true do
    local Found = self.ParentModule:FindAction(self.Option, NextDialogueID, ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commited, false, true)
    if not Found then
      break
    end
    if Found.dialog_skip_state == ProtoEnum.DialogSkipState.DSS_SKIPPING then
      LastDialogueID = NextDialogueID
      NextDialogueID = Found.next_dialog_id
      table.insert(SkippedDialogueIDs, NextDialogueID)
      bSkipCommitted = true
      Log.DebugFormat("DialogueWaitSkipAction:Check, check next success, %d -> %d", LastDialogueID, NextDialogueID)
      if 0 == NextDialogueID then
        Log.DebugFormat("DialogueWaitSkipAction:Check, check final success, commited dialogue %d -> 0", LastDialogueID)
        break
      end
    else
      Log.ErrorFormat("DialogueWaitSkipAction:Check, commited action notify with dialogue id == %d should not have dialog_skip_state(%d) other than skipping", LastDialogueID, Found.dialog_skip_state)
      self:Finish()
      return
    end
  end
  if not bSkipCommitted then
    Log.DebugFormat("DialogueWaitSkipAction:Check, fail to find a single skip committed action, waiting for next one")
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.ForwardOptionChange)
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.ForwardOptionChange, self.CheckActionNotify)
    return
  end
  if 0 == NextDialogueID then
    self:SetProperty("ConfID", NextDialogueID)
    self:SetProperty("LastConfID", LastDialogueID)
    self:ExecuteSkippedActions(SkippedDialogueIDs)
    self:Finish()
    return
  end
  local Found = self.ParentModule:FindAction(self.Option, NextDialogueID, ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing)
  if Found then
    if Found.dialog_skip_state == ProtoEnum.DialogSkipState.DSS_STOP or Found.dialog_skip_state == ProtoEnum.DialogSkipState.DSS_STOP_AND_SKIPPABLE then
      Log.DebugFormat("DialogueWaitSkipAction:Check, check final success, stop at executing dialogue ", NextDialogueID)
      self:SetProperty("ConfID", NextDialogueID)
      self:SetProperty("LastConfID", LastDialogueID)
      self:ExecuteSkippedActions(SkippedDialogueIDs)
      self:Finish()
    else
      Log.ErrorFormat("DialogueWaitSkipAction:Check, the executing action notify next to commited one should not have dialog_skip_state(%d) other than stop", Found.dialog_skip_state)
      self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
      return
    end
  else
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.ForwardOptionChange)
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.ForwardOptionChange, self.CheckActionNotify)
  end
end

function DialogueWaitSkipAction:OnFinish()
  self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.ForwardOptionChange)
end

function DialogueWaitSkipAction:OnExit()
  if self.ParentModule then
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.ForwardOptionChange)
  end
end

function DialogueWaitSkipAction:ExecuteSkippedActions(SkippedDialogueIDs)
  if not SkippedDialogueIDs then
    return
  end
  for _, ID in ipairs(SkippedDialogueIDs) do
    local DialogueConf = _G.DataConfigManager:GetDialogueConf(ID, true)
    if DialogueConf and self:ShouldActionExecuteWhenSkipping(DialogueConf.action) then
      local Action = NPCActionFactory:Get(self.Option, DialogueConf.action, nil, true)
      if Action then
        Log.InfoFormat("DialogueWaitSkipAction, execute skipped action %s on dialogue %d", DialogueConf.action and DialogueConf.action.action_type or 0, ID)
        Action:ExecuteWhenSkipping()
      end
    end
  end
end

function DialogueWaitSkipAction:ShouldActionExecuteWhenSkipping(DialogueActionConf)
  return DialogueActionConf and DialogueActionConf.action_type and (DialogueActionConf.action_type == Enum.ActionType.ACT_HIDE_CONTENT or DialogueActionConf.action_type == Enum.ActionType.ACT_SHOW_CONTENT)
end

return DialogueWaitSkipAction
