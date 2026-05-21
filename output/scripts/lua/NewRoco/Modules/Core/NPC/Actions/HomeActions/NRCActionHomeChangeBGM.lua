local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local M = Base:Extend("NRCActionHomeChangeBGM")

function M:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function M:Execute()
  self.SkipSubmit = true
  Base.Execute(self)
  local Npc = self.Owner.owner
  local Comp = Npc:GetComponent(HomeNpcInfoComponent)
  local EventName = self.Owner:GetActionConf().action_param1
  Log.Debug("NRCActionHomeChangeBGM:Execute", EventName)
  Comp:EnsureSound2dProxy(EventName):Toggle()
  self.needSendReq = false
  self.SkipSubmit = false
  self:Submit()
  self:Finish()
end

return M
