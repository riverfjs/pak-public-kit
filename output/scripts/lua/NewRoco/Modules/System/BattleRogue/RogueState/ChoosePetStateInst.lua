local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ChoosePetStateInst = Base:Extend("ChoosePetStateInst")

function ChoosePetStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
end

function ChoosePetStateInst:OnDoEnter()
end

local LoadRes = {}

function ChoosePetStateInst:GetPreLoadResList()
end

function ChoosePetStateInst:OnResReady(LoadedAssets, Rsp)
  self:OpenPanel("SelectPet")
end

function ChoosePetStateInst:OnEnter()
end

function ChoosePetStateInst:OnExit()
  if -1 == self.Direction then
    self:HidePanel("SelectPet")
  else
    self:FoldPanel("SelectPet")
  end
end

return ChoosePetStateInst
