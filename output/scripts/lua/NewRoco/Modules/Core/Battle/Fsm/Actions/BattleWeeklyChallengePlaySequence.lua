local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local Base = BattleActionBase
local BattleWeeklyChallengePlaySequence = Base:Extend("BattleWeeklyChallengePlaySequence")
FsmUtils.MergeMembers(Base, BattleWeeklyChallengePlaySequence, {})

function BattleWeeklyChallengePlaySequence:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleWeeklyChallengePlaySequence:OnEnter()
  if not _G.BattleUtils.IsWeeklyChallenge() then
    self:Finish()
    return
  end
  BattleUtils.ImmediateChangeWeatherForBattle(BattleManager.battleRuntimeData.curWeatherID)
  self:LoadSequence()
end

function BattleWeeklyChallengePlaySequence:LoadSequence()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetPlaySequenceState, true)
  local weeklyChallengeConf = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetWeeklyChallengeConf)
  if not weeklyChallengeConf then
    Log.Error("BattleWeeklyChallengePlaySequence.LoadSequence \230\152\159\229\133\137\229\175\185\229\134\179\232\142\183\229\143\150\233\133\141\231\189\174WeeklyChallengeConf\229\164\177\232\180\165\239\188\140\230\178\161\230\156\137\230\180\187\229\138\168\230\149\176\230\141\174")
    self:ForceFinish()
    return
  end
  local sequencePath = weeklyChallengeConf.sequence_path
  if not sequencePath then
    Log.Error("BattleWeeklyChallengePlaySequence.LoadSequence sequence_path\233\133\141\231\189\174\233\148\153\232\175\175\239\188\140\231\173\150\229\136\146\230\163\128\230\159\165WeeklyChallengeConf\233\135\140\231\154\132sequence_path\233\133\141\231\189\174")
    self:ForceFinish()
    return
  end
  _G.BattleResourceManager:LoadResAsync(self, sequencePath, self.OnLoadSequence, self.OnLoadSequenceFailed)
end

function BattleWeeklyChallengePlaySequence:PlaySequence(leveSequenceRes)
end

function BattleWeeklyChallengePlaySequence:OnLoadSequence(leveSequenceRes)
  if self.finished then
    self:Finish()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenBlackBar)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ModifySceneSpotLight, false)
  local Settings = UE4.FMovieSceneSequencePlaybackSettings()
  local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
  Settings.bPauseAtEnd = true
  local levelSequenceActor = {}
  levelSequenceActor, self.levelSequencePlayer = UE4.ULevelSequencePlayer.CreateLevelSequencePlayer(battleFieldActor, leveSequenceRes, Settings, levelSequenceActor)
  self.levelSequenceActor = levelSequenceActor
  self:PlaySequence()
  if self.levelSequencePlayer then
    battleFieldActor:SetCacheLSCall(self, self.OnSequenceOver)
    self.levelSequencePlayer.OnFinished:Add(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    levelSequenceActor:ApplyWorldOffsetToSequence()
    local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    local MeshBasedPlayerBinding = levelSequenceActor:FindNamedBindings("NewBP")
    self:TryShowPlayer(player, MeshBasedPlayerBinding)
    levelSequenceActor:SetBindingByTag("Player1", {
      player.model
    }, false)
    levelSequenceActor:SetBindingByTag("Player2", {
      player.model
    }, false)
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SaveWeeklyChallengeLevelSequencePlayer, self.levelSequencePlayer, self.levelSequenceActor)
    self.levelSequencePlayer:Play()
    _G.BattleManager:PlayBattleBGM()
    _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.CloseLoadingCurtainEvent)
    if not _G.EnableSpeedUpWeekChallengeBattle then
      self:Finish()
    end
  else
    self:OnLoadSequenceFailed()
  end
end

function BattleWeeklyChallengePlaySequence:TryHidePlayer(player)
  if not player then
    return
  end
  if self.CachedPlayerMeshTrans then
    player.model.Mesh:K2_SetRelativeTransform(self.CachedPlayerMeshTrans, false, nil, true)
    self.CachedPlayerMeshTrans = nil
  end
  player:HidePlayer()
  if player.model then
    local sceneComp = player.model:GetComponentByClass(UE4.USceneComponent)
    if sceneComp then
      sceneComp:SetVisibility(false)
    end
  end
end

function BattleWeeklyChallengePlaySequence:TryShowPlayer(player, bMeshBasedPlayerBinding)
  if not player then
    return
  end
  if bMeshBasedPlayerBinding then
    self.CachedPlayerMeshTrans = player.model.Mesh:GetRelativeTransform()
    player.model.Mesh:ResetRelativeTransform()
  end
  player:ShowPlayer()
  if player.model then
    local sceneComp = player.model:GetComponentByClass(UE4.USceneComponent)
    if sceneComp then
      sceneComp:SetVisibility(true)
    end
  end
end

function BattleWeeklyChallengePlaySequence:OnLoadSequenceFailed()
  self.playSequenceOver = true
  self:Finish()
end

function BattleWeeklyChallengePlaySequence:ForceFinish()
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.PlayWeeklySequenceFinished)
  self:Finish()
end

function BattleWeeklyChallengePlaySequence:OnSequenceOver()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetPlaySequenceState, false)
  local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  self:TryHidePlayer(player)
  self.levelSequencePlayer = nil
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.PlayWeeklySequenceFinished)
  self:Finish()
end

function BattleWeeklyChallengePlaySequence:OnFinish()
end

return BattleWeeklyChallengePlaySequence
