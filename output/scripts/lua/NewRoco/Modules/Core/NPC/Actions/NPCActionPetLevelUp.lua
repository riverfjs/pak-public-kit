local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = NPCActionBase
local NPCActionPetLevelUp = Base:Extend("NPCActionPetLevelUp")

function NPCActionPetLevelUp:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function NPCActionPetLevelUp:Execute()
  Base.Execute(self)
  local param1 = string.split(self.Config.action_param1, ";")
  local param2 = string.split(self.Config.action_param2, ";")
  local BeforeEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[1]))
  local AfterEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[2]))
  if not BeforeEvoNpc or not AfterEvoNpc then
    self.TempDelayId = _G.DelayManager:DelaySeconds(0.5, function()
      BeforeEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[1]))
      AfterEvoNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, tonumber(param2[2]))
      if not BeforeEvoNpc or not AfterEvoNpc then
        Log.Error("NPCActionPetLevelUp:Execute: npc is nil")
        self:Finish(true)
        return
      else
        local serverData = BeforeEvoNpc.serverData
        self:OpenLevelUpPanel(BeforeEvoNpc, AfterEvoNpc, serverData, param1)
      end
    end)
  else
    local serverData = BeforeEvoNpc.serverData
    self:OpenLevelUpPanel(BeforeEvoNpc, AfterEvoNpc, serverData, param1)
  end
end

function NPCActionPetLevelUp:OpenLevelUpPanel(BeforeEvoNpc, AfterEvoNpc, serverData, param1)
  if not serverData then
    Log.Error("NPCActionPetLevelUp:Execute: serverData is nil")
    self:Finish(true)
    return
  end
  local NpcBase = serverData.npc_base
  if not NpcBase then
    Log.Error("NPCActionPetLevelUp:Execute: NpcBase is nil")
    self:Finish(true)
    return
  end
  local EvoPetInfo = {
    Action = self,
    petID = tonumber(param1[1]),
    evoPetID = tonumber(param1[2]),
    baseInfo = NpcBase
  }
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetEvoOnlyPanel, EvoPetInfo)
  self.DelayId = _G.DelayManager:DelaySeconds(0.5, function()
    BeforeEvoNpc:SetVisibleForReason(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
    AfterEvoNpc:SetVisibleForReason(true, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  end)
end

function NPCActionPetLevelUp:Finish(success)
  Base.Finish(self, success)
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if self.TempDelayId then
    _G.DelayManager:CancelDelayById(self.TempDelayId)
    self.TempDelayId = nil
  end
end

return NPCActionPetLevelUp
