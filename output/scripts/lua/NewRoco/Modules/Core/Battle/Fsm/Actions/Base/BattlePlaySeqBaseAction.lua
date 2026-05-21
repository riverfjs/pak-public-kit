local BattleClientBranchActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleClientBranchActionBase")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleClientBranchActionBase
local CinematicModuleEvent = require("NewRoco.Modules.Core.Cinematic.CinematicModuleEvent")
local BattlePlaySeqBaseAction = Base:Extend("BattlePlayAnimBaseAction")
FsmUtils.MergeMembers(Base, BattlePlaySeqBaseAction, {})

function BattlePlaySeqBaseAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientSeqAction)
end

function BattlePlaySeqBaseAction:DoEnter()
  Base.DoEnter(self)
  self.fsm:Pause()
  self.timeout = 99999999
  NRCModeManager:DoCmd(BattleUIModuleCmd.MainHideAll, false)
  NRCModeManager:DoCmd(BattleUIModuleCmd.CloseWishPowerPanel)
  BattleManager.battlePawnManager:IsShowPetBuffs(false)
  BattleManager.battlePawnManager:HideAll(true)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  local AllNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetAllNPCInIter)
  for k, v in pairs(AllNpc) do
    v:SetVisibleForHiddenReason(false)
  end
end

function BattlePlaySeqBaseAction:Play(path, bindingFunc, needPauseOnEnd)
  local leveSequenceRes = _G.BattleResourceManager:GetCacheAssetDirect(path)
  local Settings = UE4.FMovieSceneSequencePlaybackSettings()
  if needPauseOnEnd then
    Settings.bPauseAtEnd = true
  end
  local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
  self.currentBattleFieldActor = battleFieldActor
  self.levelSequenceActor = {}
  local levelSequenceActor, levelSequencePlayer = UE4.ULevelSequencePlayer.CreateLevelSequencePlayer(battleFieldActor, leveSequenceRes, Settings, self.levelSequenceActor)
  if bindingFunc then
    bindingFunc(levelSequenceActor)
  end
  self.levelSequence = levelSequencePlayer
  self.levelSequenceActor = levelSequenceActor
  if self.levelSequence then
    battleFieldActor:SetCacheLSCall(self, self.ToFinish)
    self.levelSequence.OnFinished:Add(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    local CurrentWorld = _G.UE4Helper.GetCurrentWorld()
    local EnableRebasing = UE4.UNRCStatics.IsEnabledWorldRebasing(CurrentWorld)
    if true == EnableRebasing then
      levelSequenceActor:ApplyWorldOffsetToSequence()
    end
    self.levelSequence:Play()
    _G.BattleManager:ModifySceneSpotLight(false)
  end
  return levelSequenceActor
end

function BattlePlaySeqBaseAction:PlayWithSubtitle(path, bindingFunc, needPauseOnEnd)
  local Always = UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
  local Klass = _G.NRCBigWorldPreloader:Get("CinematicPlayer")
  local CurrentWorld = _G.UE4Helper.GetCurrentWorld()
  local Player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.levelSequenceActor = CurrentWorld:SpawnActor(Klass, Player.viewObj:GetTransform(), Always, CurrentWorld)
  local Settings = UE4.FMovieSceneSequencePlaybackSettings()
  if needPauseOnEnd then
    Settings.bPauseAtEnd = true
  end
  self.levelSequenceActor.PlaybackSettings = Settings
  local leveSequenceRes = _G.BattleResourceManager:GetCacheAssetDirect(path)
  self.levelSequenceActor:SetSequence(leveSequenceRes)
  self.levelSequence = self.levelSequenceActor.SequencePlayer
  local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
  self.currentBattleFieldActor = battleFieldActor
  battleFieldActor:SetCacheLSCall(self, self.ToFinish)
  self.levelSequence.OnFinished:Add(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
  if bindingFunc then
    bindingFunc(self.levelSequenceActor)
  end
  local EnableRebasing = UE4.UNRCStatics.IsEnabledWorldRebasing(CurrentWorld)
  if true == EnableRebasing then
    self.levelSequenceActor:ApplyWorldOffsetToSequence()
  end
  self.levelSequenceActor.SequencePlayer:Play()
  _G.NRCEventCenter:DispatchEvent(CinematicModuleEvent.OpenCinematicBar, true)
end

function BattlePlaySeqBaseAction:ToFinish()
  self:RemoveLevelSequence()
  if self.currentBattleFieldActor then
    self.currentBattleFieldActor = nil
  end
  if not _G.BattleManager.isInBattle then
    self:Finish()
    return
  end
  local AllNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetAllNPCInIter)
  for k, v in pairs(AllNpc) do
    v:SetVisibleForHiddenReason(true)
  end
  _G.BattleManager:ModifySceneSpotLight(true)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false)
  if self.fsm then
    self.fsm:Resume()
  else
    Log.Warning("BattlePlaySeqBaseAction fsm is nil")
  end
  _G.NRCEventCenter:DispatchEvent(CinematicModuleEvent.CloseCinematicBar)
  self:Finish()
end

function BattlePlaySeqBaseAction:RemoveLevelSequence()
  if self.levelSequenceActor then
    self.levelSequenceActor:Destroy()
    self.levelSequenceActor = nil
  end
  if self.levelSequence then
    self.levelSequence:Stop()
    local battleFieldActor = self.currentBattleFieldActor
    if UE.UObject.IsValid(battleFieldActor) then
      self.levelSequence.OnFinished:Remove(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    end
    self.levelSequence:Destroy()
    self.levelSequence = nil
  end
end

return BattlePlaySeqBaseAction
