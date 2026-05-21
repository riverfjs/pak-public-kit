local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueTimelineAction = Base:Extend("DialogueTimelineAction")
DialogueTimelineAction:SetMemberCount(3)
FsmUtils.MergeMembers(Base, DialogueTimelineAction, {
  {
    name = "Name",
    type = "string",
    default = "None",
    display_name = "\229\144\141\231\167\176"
  },
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = 0,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  },
  {
    name = "StartTime",
    type = "float",
    default = 0.0,
    display_name = "\229\188\128\229\167\139\230\151\182\233\151\180"
  }
})

function DialogueTimelineAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:InjectProperties()
end

function DialogueTimelineAction:OnEnter()
end

return DialogueTimelineAction
