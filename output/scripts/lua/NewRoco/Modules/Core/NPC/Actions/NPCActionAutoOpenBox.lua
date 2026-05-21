local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionAutoOpenBox = Base:Extend("NPCActionAutoOpenBox")

function NPCActionAutoOpenBox:Execute(playerId, needSendReq)
  Log.Debug("NPCActionAutoOpenBox:Execute", self.OwnerNpc:DebugNPCNameAndID())
  self:DisableOwnerCollision()
  Base.Execute(self, playerId, needSendReq)
end

function NPCActionAutoOpenBox:DisableOwnerCollision()
  local ownerNPC = self:GetOwnerNPC()
  if not ownerNPC then
    Log.Warning("NPCActionAutoOpenBox:DisableOwnerCollision - OwnerNPC is nil")
    return
  end
  ownerNPC:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.BORN_DIE)
  Log.Debug("NPCActionAutoOpenBox: Owner collision disabled", ownerNPC:DebugNPCNameAndID())
end

function NPCActionAutoOpenBox:RestoreOwnerCollision()
  local ownerNPC = self:GetOwnerNPC()
  if not ownerNPC then
    Log.Warning("NPCActionAutoOpenBox:DisableOwnerCollision - OwnerNPC is nil")
    return
  end
  ownerNPC:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.BORN_DIE)
  Log.Debug("NPCActionAutoOpenBox: Owner collision recover", ownerNPC:DebugNPCNameAndID())
end

function NPCActionAutoOpenBox:FailedOnSubmit(CmdID, Msg)
  self:RestoreOwnerCollision()
  NPCActionBase.FailedOnSubmit(self, CmdID, Msg)
end

function NPCActionAutoOpenBox:FailedOnCommit(CmdID, Msg)
  self:RestoreOwnerCollision()
  NPCActionBase.FailedOnCommit(self, CmdID, Msg)
end

return NPCActionAutoOpenBox
