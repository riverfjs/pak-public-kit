local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = NPCActionBase
local NPCActionBattleWatchLite = Base:Extend("NPCActionBattleWatchLite")

function NPCActionBattleWatchLite:Ctor(Owner, Config, Info, OwnerNpc)
  Base.Ctor(self, Owner, Config, Info, OwnerNpc)
  if not self.OtherPlayer and self.OwnerNpc.serverData and self.OwnerNpc.serverData.npc_prop then
    local Infos = self.OwnerNpc.serverData.npc_prop.npc_prop_slot_infos
    if Infos then
      self.OtherPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Infos[1].holder_avatar_id)
    end
  end
end

function NPCActionBattleWatchLite:OnSubmit(rsp)
  Base.OnSubmit(self, rsp)
  if 0 == rsp.ret_info.ret_code then
    local Player = self:GetPlayer()
    if Player then
      self.OtherPlayer.playerToyComponent:PlayJumpBoxAnim(Player, self.OwnerNpc, self, self.OnSkillFinished)
    end
  else
    self:Finish(false)
  end
end

function NPCActionBattleWatchLite:OnSkillFinished()
  self:Finish(true)
end

function NPCActionBattleWatchLite:Finish(success, data, param)
  if self.OwnerNpc and self.OwnerNpc.InteractionComponent then
    self.OwnerNpc.InteractionComponent:TryEnableInteraction()
    self.OwnerNpc:SetNotDestroyFlag(false)
  end
  if self.OtherPlayer then
    self.OtherPlayer:Land()
    if self.OtherPlayer.inputComponent then
      self.OtherPlayer.inputComponent:SetInputEnable(self, true, "NPCActionBattleWatchLite")
    end
  end
  Base.Finish(self, success, data, param)
end

return NPCActionBattleWatchLite
