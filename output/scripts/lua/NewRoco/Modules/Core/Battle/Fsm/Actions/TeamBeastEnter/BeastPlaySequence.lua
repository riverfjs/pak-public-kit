local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local BeastPlaySequence = Base:Extend("BeastPlaySequence")
FsmUtils.MergeMembers(Base, BeastPlaySequence, {})

function BeastPlaySequence:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(Base.ActionType.ClientTurnPlayAction)
end

function BeastPlaySequence:OnEnter()
  BattleUtils.ForceUpdateIndexMap()
  BattleUtils.ImmediateChangeWeatherForBattle(BattleManager.battleRuntimeData.curWeatherID)
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_LOAD_MODE_LOVER, BattleEvent.PLAYER_LOAD_MODEL_OVER)
  if BattleUtils.IsEnterCatchInTeamBattle() then
    self:Finish()
  else
    self:PlaySequence()
  end
end

function BeastPlaySequence:PlaySequence()
  local leveSequenceRes = self.fsm:GetProperty("BeastLoadSequence", false)
  if not leveSequenceRes then
    self:Finish()
    return
  end
  self.fsm:SetProperty("BeastLoadSequence", nil)
  local Settings = UE4.FMovieSceneSequencePlaybackSettings()
  local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
  Settings.bPauseAtEnd = true
  local levelSequenceActor = {}
  levelSequenceActor, self.levelSequencePlayer = UE4.ULevelSequencePlayer.CreateLevelSequencePlayer(battleFieldActor, leveSequenceRes, Settings, levelSequenceActor)
  if not self.levelSequencePlayer then
    self:Finish()
    return
  end
  battleFieldActor:SetCacheLSCall(self, self.Finish)
  self.levelSequencePlayer.OnFinished:Add(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
  levelSequenceActor:ApplyWorldOffsetToSequence()
  self:SafeDelayFrames("d_CloseTransformLoadingUI", 2, function()
    NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
  end)
  self.levelSequencePlayer:Play()
end

function BeastPlaySequence:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PLAYER_LOAD_MODEL_OVER then
    local player = (...)
    if player and player.model then
      player:HidePlayer()
      local sceneComp = player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(false)
      end
    end
    return true
  elseif eventName == BattleEvent.PET_LOAD_MODE_LOVER then
    local pet = (...)
    if pet and pet.model then
      pet:HidePet(true)
    end
    return true
  end
end

function BeastPlaySequence:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  if self.levelSequencePlayer then
    local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
    self.levelSequencePlayer.OnFinished:Remove(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    self.fsm:SetProperty("BeastLevelPlayer", self.levelSequencePlayer)
  end
end

return BeastPlaySequence
