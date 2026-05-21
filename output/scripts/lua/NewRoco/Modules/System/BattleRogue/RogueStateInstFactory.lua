local Class = _G.MakeSimpleClass
local RogueModuleEnum = require("NewRoco.Modules.System.BattleRogue.RogueModuleEnum")
local RogueStateInstFactory = Class("RogueStateInstFactory")
RogueStateInstFactory.Register = {
  [RogueModuleEnum.RogueStateEnum.Init] = require("NewRoco.Modules.System.BattleRogue.RogueState.InitStateInst"),
  [RogueModuleEnum.RogueStateEnum.ChooseLevel] = require("NewRoco.Modules.System.BattleRogue.RogueState.ChooseLevelStateInst"),
  [RogueModuleEnum.RogueStateEnum.SelectPet] = require("NewRoco.Modules.System.BattleRogue.RogueState.ChoosePetStateInst"),
  [RogueModuleEnum.RogueStateEnum.AffirmPet] = require("NewRoco.Modules.System.BattleRogue.RogueState.AffirmPetStateInst"),
  [RogueModuleEnum.RogueStateEnum.ChallengeLobby] = require("NewRoco.Modules.System.BattleRogue.RogueState.ChallengeLobbyStateInst"),
  [RogueModuleEnum.RogueStateEnum.ChallengeBattle] = require("NewRoco.Modules.System.BattleRogue.RogueState.ChallengeBattleStateInst"),
  [RogueModuleEnum.RogueStateEnum.Exit] = require("NewRoco.Modules.System.BattleRogue.RogueState.ExitStateInst")
}

function RogueStateInstFactory:Ctor(...)
  self.StateInstMap = {}
end

function RogueStateInstFactory:GetStateInst(State, ...)
  if table.containsKey(self.Register, State) then
    if not self.StateInstMap[State] then
      local StateInst = self.Register[State](State, ...)
      self.StateInstMap[State] = StateInst
      return StateInst
    end
    self.StateInstMap[State]:Refresh()
    return self.StateInstMap[State]
  end
end

function RogueStateInstFactory:Release()
  table.clear(self.StateInstMap)
end

return RogueStateInstFactory
