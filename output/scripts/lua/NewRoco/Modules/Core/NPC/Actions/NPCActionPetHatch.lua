local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = NPCActionBase
local NPCActionPetHatch = Base:Extend("NPCActionPetHatch")

function NPCActionPetHatch:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function NPCActionPetHatch:Execute()
  Base.Execute(self)
  local param1 = string.split(self.Config.action_param1, ";")
  local param2 = string.split(self.Config.action_param2, ";")
  local BeforeEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[1]))
  local AfterEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[2]))
  if not BeforeEvoNpc or not AfterEvoNpc then
    Log.Error("NPCActionPetHatch:Execute: npc is nil")
    self:Finish(true)
    return
  end
  local serverData = BeforeEvoNpc.serverData
  if not serverData then
    Log.Error("NPCActionPetHatch:Execute: serverData is nil")
    self:Finish(true)
    return
  end
  local NpcBase = serverData.npc_base
  if not NpcBase then
    Log.Error("NPCActionPetHatch:Execute: NpcBase is nil")
    self:Finish(true)
    return
  end
  local HatchPetInfo = {
    Action = self,
    eggConfId = tonumber(param1[1]),
    petBaseId = tonumber(param1[2]),
    baseInfo = NpcBase
  }
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetHatchOnlyPanel, HatchPetInfo)
  self.DelayId = _G.DelayManager:DelaySeconds(0.5, function()
    BeforeEvoNpc:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
    AfterEvoNpc:SetVisibleForReason(true, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  end)
end

function NPCActionPetHatch:Finish(success)
  Base.Finish(self, success)
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

return NPCActionPetHatch
