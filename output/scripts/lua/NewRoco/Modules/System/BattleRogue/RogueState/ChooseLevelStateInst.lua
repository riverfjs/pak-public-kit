local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ChooseLevelStateInst = Base:Extend("ChooseLevelStateInst")

function ChooseLevelStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
end

local LoadRes = {Skill = ""}

function ChooseLevelStateInst:GetPreLoadResList()
end

function ChooseLevelStateInst:OnResReady(LoadedAssets, Rsp)
  self:OpenPanel("SelectTrial")
end

function ChooseLevelStateInst:OnDoEnter()
end

function ChooseLevelStateInst:OnEnter()
end

function ChooseLevelStateInst:OnExit()
  if -1 == self.Direction then
    self:HidePanel("SelectTrial")
  else
    self:FoldPanel("SelectTrial")
  end
end

return ChooseLevelStateInst
