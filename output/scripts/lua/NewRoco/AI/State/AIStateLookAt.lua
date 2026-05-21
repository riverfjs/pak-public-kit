local WeakSceneCharacter = require("NewRoco.Modules.Core.Scene.Common.WeakSceneCharacter")
local AIStateLookAt = MakeSimpleClass("AIStateLookAt")
UE.FInstanceStructBuilder("AIStateLookAtData"):AddFieldObject("Target"):AddFieldBool("Immediately"):Build()

function AIStateLookAt.CreateData()
  return UE.FInstanceStructPtr("AIStateLookAtData")
end

function AIStateLookAt:OnEnter()
  local npc = self.Container.owner
  if not npc then
    return
  end
  local target = WeakSceneCharacter.GetCharacter(self.Data.Target)
  local immediately = self.Data.Immediately or false
  if target then
    npc:SetHeadLookAtActor(target, immediately, false)
  end
end

function AIStateLookAt:OnLeave(reason)
  local npc = self.Container.owner
  if npc then
    npc:SetHeadLookAtActor(nil, true, false)
  end
end

return AIStateLookAt
