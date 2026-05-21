local AIDefines = {}
AIDefines.UseCharacterReplicateMovementComponent = false
AIDefines.GoalResult = {
  CONTINUE = 1,
  SUCCESS = 2,
  FAILED = 3
}
AIDefines.ActionState = {Idle = 1, Working = 2}
AIDefines.ActionResult = {
  Success = 1,
  Failed = 2,
  Aborted = 3,
  Rejected = 4,
  Continue = 5,
  Invalid = 99
}

function AIDefines.ActionResult.Ok(result)
  return 1 == result or 5 == result
end

AIDefines.EInsightsUnitTag = {
  EInsightsUnitTag_None = 0,
  EInsightsUnitTag_AI = 1,
  EInsightsUnitTag_Dots = 2,
  EInsightsUnitTag_Server = 4,
  EInsightsUnitTag_Player = 8,
  EInsightsUnitTag_Count = 4
}

function AIDefines.ActionIsSuccess(result)
  return result == AIDefines.ActionResult.Success or result == AIDefines.ActionResult.Continue
end

function AIDefines.RegisterCycleCounters()
end

AIDefines.LockReason = {
  UNIVERSAL = 1,
  CINEMATIC = 2,
  DIALOGUE = 3,
  INTERACT = 4,
  UNLOCK_BONFIRE = 5,
  BORN_DIE = 6,
  STUN = 7,
  LEGENDARY_BATTLE_SHADOW = 8,
  MINIGAME_HIDE = 9,
  HIDDEN = 10,
  WAITING = 11,
  BUBBLE_SHOW = 12,
  ACTION_PROCESS = 13,
  ICE = 14,
  SUIT_PERFORM = 15,
  HOME_EDIT = 16,
  HOME_LOAD = 17,
  PET_BLESSING = 18,
  CATCH = 19,
  BattleSpectator = 20,
  RANK_MATCH = 21,
  TOY_FREE_PLACE = 22,
  INTERNAL_LEGACY_BATTLE = 50
}

function AIDefines.SetControlFlag(AIController, Flag, Set)
  local AIComp = AIController.Npc and AIController.Npc.AIComponent
  if AIComp then
    if Set then
      AIComp:SetControlFlags(Flag)
    else
      AIComp:UnsetControlFlags(Flag)
    end
  end
end

function AIDefines.InitBattleState(AIController, Status, Set)
  local AIComp = AIController.Npc and AIController.Npc.AIComponent
  if AIComp then
    if Set then
      AIComp:SetBattleState(Status)
    else
      AIComp:UnsetBattleState(Status)
    end
  end
end

AIDefines.DotsPlayerSalsNeedsToCopy = {
  [Enum.SpaceActorLogicStatus.SALS_FASHION_SUITS] = true,
  [Enum.SpaceActorLogicStatus.SALS_AT_HOME] = true,
  [Enum.SpaceActorLogicStatus.SALS_VISIT_HOME] = true,
  [Enum.SpaceActorLogicStatus.SALS_HOME_PLANT] = true,
  [Enum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_HANDHELD] = true,
  [Enum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_MYSELF] = true,
  [Enum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_TRIPOD_CAMERA] = true,
  [Enum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_TRIPOD_WORLD] = true
}
local DotsBlackboardKeyBundle = {
  HabitatCatchRecord = 1,
  EvoChainCatchRecord = 2,
  RestraintNeighbors = 3
}
AIDefines.DotsBlackboardKeyBundle = DotsBlackboardKeyBundle
local DotsBlackboardKeyBundleKeys = {
  [DotsBlackboardKeyBundle.HabitatCatchRecord] = {
    "Global_HabitatGroupCatch",
    "Global_HabitatGroupCatchSuccess",
    "Global_HabitatGroupCatchFail",
    "Global_HabitatGroupNpcNowNum",
    "Global_HabitatGroupNpcAllNum"
  },
  [DotsBlackboardKeyBundle.EvoChainCatchRecord] = {
    "Global_EvolutionCatch",
    "Global_EvolutionCatchSuccess",
    "Global_EvolutionCatchFail"
  },
  [DotsBlackboardKeyBundle.RestraintNeighbors] = {
    "Global_FirstNeighbourRestraint",
    "Global_SecondNeighbourRestraint"
  }
}
AIDefines.DotsBlackboardKeyBundleKeys = DotsBlackboardKeyBundleKeys
AIDefines.DotsBatchFilterType = {
  UID = 0,
  PETBASE = 1,
  NPCID = 2,
  CONTENTID = 3,
  EVOCHAIN = 4,
  COLLECTION = 5
}
AIDefines.DummyInstData = UE.FInstanceStructPtr()
return AIDefines
