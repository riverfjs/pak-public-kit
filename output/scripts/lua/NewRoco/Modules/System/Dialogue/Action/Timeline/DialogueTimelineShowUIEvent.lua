local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueTimelineShowUIEvent = Base:Extend("DialogueTimelineShowUIEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineShowUIEvent, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -100,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  }
})

function DialogueTimelineShowUIEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineShowUIEvent:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue or BattleAutoTest and BattleAutoTest.IsAutoBattle then
    self:Finish()
    return
  end
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.DialogueConfig = self.fsm:GetProperty("CurrentDialogue")
  if self.DialogueConfig and not string.IsNilOrEmpty(self.DialogueConfig.text) then
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.ShowMainPanel, self.OnShowUIFinish, self)
  end
  self:Finish()
end

function DialogueTimelineShowUIEvent:OnFinish()
  if self.entered and self.ParentModule then
    self.ParentModule.PreUIType = self.DialogueConfig.ui_source_type
  end
  Base.OnFinish(self)
end

function DialogueTimelineShowUIEvent:OnShowUIFinish()
end

return DialogueTimelineShowUIEvent
