local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattlePlaySeqBaseAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattlePlaySeqBaseAction")
local BattleB1P2EnterSequenceAction = BattlePlaySeqBaseAction:Extend("BattleB1P2EnterSequenceAction")
FsmUtils.MergeMembers(BattlePlaySeqBaseAction, BattleB1P2EnterSequenceAction, {})

function BattleB1P2EnterSequenceAction:DoEnter()
  if _G.BattleManager.debugEnv.closeB1FBP2Seq then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
    self:Finish()
    return
  end
  BattlePlaySeqBaseAction.DoEnter(self)
end

function BattleB1P2EnterSequenceAction:OnEnter()
  self:PlayWithSubtitle(BattleConst.B1P2EnterSequence, function(levelSequenceActor)
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
    self:SetBpUsePlayer(levelSequenceActor)
  end, true)
end

function BattleB1P2EnterSequenceAction:SetBpUsePlayer(levelSequenceActor)
  local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  if not player or not player.model then
    return
  end
  player:ShowPlayer()
  local MeshBasedPlayerBinding = levelSequenceActor:FindNamedBindings("NewBP")
  if MeshBasedPlayerBinding:Length() > 0 then
    self.CachedPlayerMeshTrans = player.model.Mesh:GetRelativeTransform()
    player.model.Mesh:ResetRelativeTransform()
  end
  player.model.CharacterMovement:SetComponentTickEnabled(false)
  levelSequenceActor:ApplyWorldOffsetToSequence()
  levelSequenceActor:SetBindingByTag("Player1", {
    player.model
  }, false)
  levelSequenceActor:SetBindingByTag("Player2", {
    player.model
  }, false)
end

function BattleB1P2EnterSequenceAction:RemoveLevelSequence()
  if self.levelSequence then
    _G.BattleManager.battleRuntimeData:CacheB1P2LevelSequence(self.levelSequence)
    local battleFieldActor = self.currentBattleFieldActor
    if UE.UObject.IsValid(battleFieldActor) then
      self.levelSequence.OnFinished:Remove(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    end
    local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    if player and self.CachedPlayerMeshTrans then
      player.model.Mesh:K2_SetRelativeTransform(self.CachedPlayerMeshTrans, false, nil, true)
      self.CachedPlayerMeshTrans = nil
    end
    self.levelSequence = nil
    self.levelSequenceActor = nil
  end
end

return BattleB1P2EnterSequenceAction
