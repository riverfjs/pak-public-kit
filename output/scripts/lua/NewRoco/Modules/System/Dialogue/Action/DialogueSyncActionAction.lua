local NPCActionEvent = require("NewRoco.Modules.Core.NPC.Actions.NPCActionEvent")
local NPCActionFactory = require("NewRoco.Modules.Core.NPC.Actions.NPCActionFactory")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ActionUtils = require("NewRoco.Modules.Core.NPC.Actions.ActionUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = DialogueActionBase
local DialogueSyncActionAction = Base:Extend("DialogueSyncActionAction")
FsmUtils.MergeMembers(Base, DialogueSyncActionAction, {
  {
    name = "DialogueConf",
    type = "var"
  },
  {
    name = "ParentModule",
    type = "var"
  }
})

function DialogueSyncActionAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueSyncActionAction:OnEnter()
  self:InjectProperties()
  if not (self.DialogueConf and self.DialogueConf.action.action_type) or self.DialogueConf.action.action_type == Enum.ActionType.ACT_NONE then
    self:Finish()
    return
  end
  if self:ShouldSuspendSyncExit(self.DialogueConf.action.action_type) then
    self.ParentModule:CloseButtonExit()
  end
  if DialogueUtils.IsTeleportAction(self.DialogueConf.action.action_type) then
    self.fsm:SetProperty("PlayerPosSyncBlocker", false)
    local player = DialogueUtils.GetHero()
    if player.movementComponent and player.movementComponent.SetSyncMove then
      player.movementComponent:SetSyncMove(true)
    end
  end
  if self:IsActionSupportSync(self.DialogueConf.action.action_type) then
    self.Action = NPCActionFactory:Get(self.Option, self.DialogueConf.action, self.ServerAction, true)
    self.Action.DialogueConf = self.DialogueConf
    self.Action.SkipSubmit = true
    self.Action:AddEventListener(self, NPCActionEvent.OnFinish, self.OnClientActionFinish)
    self.Action:Execute()
  else
    self:Finish()
  end
end

function DialogueSyncActionAction:IsActionSupportSync(action_type)
  return action_type == Enum.ActionType.ACT_SHOW_CONTENT or action_type == Enum.ActionType.ACT_HIDE_CONTENT
end

function DialogueSyncActionAction:ShouldSuspendSyncExit(action_type)
  return action_type == Enum.ActionType.ACT_BATTLE
end

function DialogueSyncActionAction:OnClientActionFinish(rsp, success)
  if 0 == rsp.ret_info.ret_code then
    self:Finish()
  else
    Log.Error("DialogueSyncActionAction:OnClientActionFinish failed with ret_code: " .. rsp.ret_info.ret_code)
    self:Finish()
  end
end

return DialogueSyncActionAction
