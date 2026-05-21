local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineCameraDOFEvent = Base:Extend("DialogueTimelineCameraDOFEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineCameraDOFEvent, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -101,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  },
  {
    name = "KeepLast",
    type = "bool",
    default = false,
    display_name = "\230\152\175\229\144\166\228\191\157\231\149\153\228\184\138\228\184\128\228\184\170DOF Event\231\154\132\229\143\130\230\149\176"
  },
  {
    name = "Stop",
    type = "bool",
    default = false,
    display_name = "\230\152\175\229\144\166\228\184\173\230\173\162DOF\230\149\136\230\158\156"
  },
  {
    name = "Scale",
    type = "float",
    default = 2.0,
    display_name = "\229\164\177\231\132\166\230\168\161\231\179\138\229\185\133\229\186\166"
  },
  {
    name = "FocalActorID0",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\232\129\154\231\132\166\232\167\146\232\137\178ID0"
  },
  {
    name = "FocalActorID1",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\232\129\154\231\132\166\232\167\146\232\137\178ID1"
  },
  {
    name = "FocalActorID2",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\232\129\154\231\132\166\232\167\146\232\137\178ID2"
  },
  {
    name = "FocalRegionMargin",
    type = "float",
    default = 10.0,
    display_name = "\232\129\154\231\132\166\232\167\146\232\137\178\229\146\140\232\129\154\231\132\166\229\140\186\229\159\159\232\190\185\231\149\140\231\154\132\233\162\157\229\164\150\232\183\157\231\166\187"
  },
  {
    name = "OutFocalActorID0",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID0"
  },
  {
    name = "OutFocalActorID1",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID1"
  },
  {
    name = "OutFocalActorID2",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID2"
  },
  {
    name = "OutFocalActorID3",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID3"
  },
  {
    name = "OutFocalActorID4",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID4"
  },
  {
    name = "OutFocalActorID5",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178ID5"
  },
  {
    name = "OutFocalRegionMargin",
    type = "float",
    default = 10.0,
    display_name = "\229\164\177\231\132\166\232\167\146\232\137\178\229\146\140\229\164\177\231\132\166\229\140\186\229\159\159\232\190\185\231\149\140\231\154\132\233\162\157\229\164\150\232\183\157\231\166\187"
  },
  {
    name = "CustomFocalDistance",
    type = "float",
    default = 0.0,
    display_name = "\232\135\170\229\174\154\228\185\137\232\129\154\231\132\166\229\140\186\229\159\159\229\137\141\232\190\185\231\149\140\229\146\140\231\155\184\230\156\186\232\183\157\231\166\187(\230\151\160\232\129\154\231\132\166\232\167\146\232\137\178\230\151\182\230\156\137\230\149\136)"
  },
  {
    name = "CustomFocalRegion",
    type = "float",
    default = 0.0,
    display_name = "\232\135\170\229\174\154\228\185\137\232\129\154\231\132\166\229\140\186\229\159\159\229\174\189\229\186\166(\230\151\160\232\129\154\231\132\166\232\167\146\232\137\178\230\151\182\230\156\137\230\149\136)"
  },
  {
    name = "CustomNearTransitionRegion",
    type = "float",
    default = 0.0,
    display_name = "\232\135\170\229\174\154\228\185\137\232\191\145\229\164\132\232\189\172\230\141\162\229\140\186\229\174\189\229\186\166(\232\191\145\229\164\132\230\151\160\229\164\177\231\132\166\232\167\146\232\137\178\230\151\182\230\156\137\230\149\136)"
  },
  {
    name = "CustomFarTransitionRegion",
    type = "float",
    default = 0.0,
    display_name = "\232\135\170\229\174\154\228\185\137\232\191\156\229\164\132\232\189\172\230\141\162\229\140\186\229\174\189\229\186\166(\232\191\156\229\164\132\230\151\160\229\164\177\231\132\166\232\167\146\232\137\178\230\151\182\230\156\137\230\149\136)"
  }
})

function DialogueTimelineCameraDOFEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineCameraDOFEvent:OnEnter()
  Base.OnEnter(self)
  self:Finish()
end

function DialogueTimelineCameraDOFEvent:OnFinish()
  Base.OnFinish(self)
end

return DialogueTimelineCameraDOFEvent
