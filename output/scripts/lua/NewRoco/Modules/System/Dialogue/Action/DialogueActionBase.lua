local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local Base = FsmAction
local DialogueActionBase = Base:Extend("DialogueActionBase")

function DialogueActionBase:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueActionBase:GetActor(ActorID, NPCContentID)
  return DialogueUtils.GrabActor(ActorID, self.fsm, NPCContentID)
end

function DialogueActionBase:GetActorView(ActorID, NPCContentID)
  return DialogueUtils.GrabActorView(ActorID, self.fsm, NPCContentID)
end

function DialogueActionBase:GetActorTransform(ActorID, NPCContentID)
  return DialogueUtils.GrabActorTransform(ActorID, self.fsm, NPCContentID)
end

return DialogueActionBase
