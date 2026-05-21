local ViewNPCBase = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local Base = ViewNPCBase
local BP_NPCOrdnance_C = Base:Extend("BP_NPCOrdnance_C")

function BP_NPCOrdnance_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
end

function BP_NPCOrdnance_C:Init()
  Base.Init(self)
end

function BP_NPCOrdnance_C:ExcuteAction()
  local NPCActionCannonFire = require("NewRoco.Modules.Core.NPC.Actions.NPCActionCannonFire")
  local actionConfig = {
    action_type = Enum.ActionType.ACT_CANNON_FIRE
  }
  local action = NPCActionCannonFire(nil, actionConfig, nil, self.sceneCharacter)
  action:Execute(self)
end

function BP_NPCOrdnance_C:FireEnd()
  self.Child:SetVisible(true)
  self.ActorEmitter:Explode(self.createdNPC)
end

function BP_NPCOrdnance_C:Destruct()
end

function BP_NPCOrdnance_C:Show()
  self.ActorEmitter.startPos = self.NRCChildActor:Abs_K2_GetComponentLocation()
  self.ActorEmitter:SetTargetForwardRotator(self.NRCChildActor:K2_GetComponentRotation())
  self.ActorEmitter.force = self.Speed
  self.createdNPC = {}
  for _, npc in ipairs(self.sceneCharacter.luaObj.createdNPC) do
    table.insert(self.createdNPC, npc)
    self.Child = npc
    npc:SetVisible(false)
  end
  self:BlustOff()
end

function BP_NPCOrdnance_C:OnActionFire()
  local option = self.sceneCharacter.InteractionComponent:GetMainAction()
  if option:IsOptionEnable() then
    option:OnOptionAction()
  end
end

return BP_NPCOrdnance_C
