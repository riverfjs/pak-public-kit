local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialoguePrevTimelineBlackScreenOutAction = Base:Extend("DialoguePrevTimelineBlackScreenOutAction")
FsmUtils.MergeMembers(Base, DialoguePrevTimelineBlackScreenOutAction, {
  {
    name = "CurrentTimeline",
    type = "var"
  }
})

function DialoguePrevTimelineBlackScreenOutAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialoguePrevTimelineBlackScreenOutAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  if self.CurrentTimeline.black_switch_in then
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.CLOSE_BLACK_SCREEN)
    NRCModuleManager:DoCmd(DialogueModuleCmd.FadeOutDialogueCameraBlack)
  end
  self:Finish()
end

return DialoguePrevTimelineBlackScreenOutAction
