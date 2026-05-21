local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger_Declare")
local Base = BattleActionBase
local BattleRoundAction = Base:Extend("BattleRoundAction")
FsmUtils.MergeMembers(Base, BattleRoundAction, {})

function BattleRoundAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function BattleRoundAction:OnEnter()
  self.fsm:Pause()
  self.BattleManager = _G.BattleManager
  self:SetTeamPetHighlight(false)
  self:SetEnemyPetHighlight(false)
  self.PawnManager = self.BattleManager.battlePawnManager
  self.SelectMarkerManager = self.fsm:GetProperty("MarkerManager")
  self.BattleManager.battleRuntimeData:ClearEvolutionCachedData()
  self.CurrentPet = self.fsm:GetProperty("CurrentPet")
  self.SelectMarkerManager:SetCurrentPet(self.CurrentPet)
  local PlayerTeam = self.PawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  local EnemyTeam = self.PawnManager:GetTeam(BattleEnum.Team.ENUM_ENEMY)
  if not PlayerTeam or not EnemyTeam then
    self:Finish()
    return
  end
  self.CurrentPlayer = self.PawnManager.TeamatePlayer
  self.CurrentEnemyPets = self.PawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  self.CurrentTeamPets = self.PawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  self.CurrentMyPets = self.PawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
  self.CurrentEnemyPlayer = EnemyTeam.player
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self.BattleManager.SelectTargetManager:Clear()
  Log.Debug("Entering...", self.state:GetName(), self:GetName())
  self:ResetPetTurn()
end

function BattleRoundAction:ResetPetTurn()
  for i, v in pairs(self.CurrentTeamPets) do
    v:ResetRotation(true)
  end
  for i, v in pairs(self.CurrentEnemyPets) do
    v:ResetRotation(true)
  end
end

function BattleRoundAction:OnFinish()
  self.fsm:Resume()
end

function BattleRoundAction:OnExit()
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self.SelectMarkerManager:ClearCurrentPet()
  self:ToggleDarkScene(false)
  self:SetTeamPetHighlight(false)
  self:SetEnemyPetHighlight(false)
  self.BattleManager = nil
  self.PawnManager = nil
  self.CurrentPet = nil
  self.CurrentPlayer = nil
  self.CurrentEnemyPets = nil
  self.CurrentEnemyPlayer = nil
end

function BattleRoundAction:SendPushbackReq(req)
  return _G.BattleNetManager:SendBattleCmdPushbackReq(req, self, self.OnPushbackSent)
end

function BattleRoundAction:OnPushbackSent(rsp)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(rsp)
  if self.BattleManager then
    _G.BattleEventCenter:Dispatch(BattleEvent.PUSHBACK_CMD_SENT, rsp)
  end
  self:ClearPushbackReq()
end

function BattleRoundAction:SendPopbackReq(req)
  _G.BattleNetManager:SendBattleCmdPopbackReq(req, self, self.OnPopbackSent)
end

function BattleRoundAction:OnPopbackSent(rsp)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(rsp)
  _G.BattleEventCenter:Dispatch(BattleEvent.POPBACK_CMD_SENT, rsp)
end

function BattleRoundAction:ClearPushbackReq()
  if self:IsValid() then
    self.fsm:SetProperty("CurrentPushbackReq", nil)
  end
end

function BattleRoundAction:SetEnemyPetHighlight(highlight)
  if not self.BattleManager or not self.BattleManager.battlePawnManager then
    return
  end
  if not self.BattleManager.battlePawnManager.enemyTeam then
    return
  end
  local enemyPets = self.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  for i, enemyPet in pairs(enemyPets) do
    local restPets = enemyPet.team.RestPets
    if not restPets[enemyPet.card.pos] then
      enemyPet:SetHighlight(highlight)
    end
  end
end

function BattleRoundAction:SetTeamPetHighlight(highlight)
  if not BattleManager.battlePawnManager then
    return
  end
  if not BattleManager.battlePawnManager.playerTeam then
    return
  end
  local teamPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, teamPet in pairs(teamPets) do
    teamPet:SetHighlight(highlight)
  end
end

function BattleRoundAction:ToggleDarkScene(dark, highLightTargets)
  if not self.BattleManager then
    return
  end
  local BattleField = self.BattleManager.vBattleField
  if not BattleField then
    return
  end
  local BattleFieldActor = BattleField.battleFieldActor
  if not BattleFieldActor then
    return
  end
  BattleFieldActor:ToggleDarkScene(dark, highLightTargets)
end

function BattleRoundAction:ResetPetsLight()
  self:SetPetsDark(BattleEnum.Team.ENUM_ENEMY, false)
  self:SetPetsDark(BattleEnum.Team.ENUM_TEAM, false)
end

function BattleRoundAction:SetPetsDark(type, on)
  if type == BattleEnum.Team.ENUM_TEAM then
    local playerPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
    if playerPets then
      for i, player in pairs(playerPets) do
        local restPets = player.team.RestPets
        if not restPets[player.card.pos] then
          player:SetDark(on)
        end
      end
    end
  elseif type == BattleEnum.Team.ENUM_ENEMY then
    local enemyPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
    if enemyPets then
      for _, enemy in pairs(enemyPets) do
        local restPets = enemy.team.RestPets
        if not restPets[enemy.card.pos] then
          enemy:SetDark(on)
        end
      end
    end
  else
    Log.Error("Invalid type of team found")
  end
end

return BattleRoundAction
