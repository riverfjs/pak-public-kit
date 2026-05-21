local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueWaitNPCSpawnAction = Base:Extend("FsmWaitNPCSpawnAction")
FsmUtils.MergeMembers(Base, DialogueWaitNPCSpawnAction, {
  {name = "TargetNPC", type = "var"},
  {
    name = "DialogueConf",
    type = "var"
  }
})

function DialogueWaitNPCSpawnAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueWaitNPCSpawnAction:OnEnter()
  self:InjectProperties()
  if _G.RocoEnv.IS_EDITOR and self.Finish then
    self:Finish()
    return
  end
  self.timeout = 2
  self:OnTick(0)
  self:Finish()
end

function DialogueWaitNPCSpawnAction:OnTick(DeltaTime)
  if self:Check() then
    self:Finish()
  end
end

function DialogueWaitNPCSpawnAction:Check()
  local Conf = self.DialogueConf
  if not Conf then
    return true
  end
  local Performers = Conf.actor_perform
  if not Performers then
    return true
  end
  if 0 == #Performers then
    return true
  end
  for _, Perform in ipairs(Performers) do
    if 0 == Perform.actor then
    else
      local Actor = self:GetActor(Perform.actor)
      if not Actor then
        Log.Debug("\231\173\137\229\190\133\232\161\168\230\188\148\231\157\128\231\148\159\230\136\144", Conf.id, Perform.actor)
        return false
      end
      if Actor.isDestroy then
        Log.Warning("\229\143\130\228\184\142\232\161\168\230\188\148\231\154\132NPC\229\173\152\229\156\168\239\188\140\228\189\134\230\152\175\232\162\171\229\136\160\228\186\134\239\188\140\232\175\183\230\163\128\230\159\165\229\175\185\232\175\157\233\128\187\232\190\145", Conf.id, Perform.actor)
      else
        local View = Actor.viewObj
        if not View then
          Log.Debug("\231\173\137\229\190\133\232\161\168\230\188\148\232\128\133\230\168\161\229\158\139", Conf.id, Perform.actor)
          return false
        end
        if -1 ~= Perform.actor and (UE4.UObject.IsValid(View) and UE.UObject.IsA(View, UE.ANPCBaseActor) or UE.UObject.IsA(View, UE.ANPCBaseCharacter)) and not View.resourceLoaded then
          Log.Debug("\231\173\137\229\190\133NPC\230\168\161\229\158\139\229\138\160\232\189\189\229\174\140\230\136\144", Conf.id, Perform.actor)
          return false
        end
      end
    end
  end
  return true
end

function DialogueWaitNPCSpawnAction:OnTimeout()
  Log.Error("\231\173\137\229\190\133\229\143\130\228\184\142\229\175\185\232\175\157\232\161\168\230\188\148\231\154\132NPC\231\148\159\230\136\144\232\182\133\230\151\182\228\186\134...\232\175\183\230\163\128\230\159\165\229\175\185\232\175\157\233\133\141\231\189\174", self.TargetNPC)
end

function DialogueWaitNPCSpawnAction:OnExit()
  self.DialogueConf = nil
  self.TargetNPC = nil
end

return DialogueWaitNPCSpawnAction
