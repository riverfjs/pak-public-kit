local ActionUtils = {}
ActionUtils.VisualDebug = false
ActionUtils.ExpectedErrorCodes = {
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ERR_OTHER_PLAYER_IS_INTERACTING_MIRACLE,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ERR_MIRACLE_NPC_TIME_OUT,
  ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_BAG_ITEM_PET_EGG_LIMIT,
  ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_BAG_ITEM_USEFUL_LIMIT,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_BONFIRE_IS_BURNING,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_INVALID_ACTION_PARAMS,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_CNT_NOT_ENOUGH,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_NUMBER_NOT_ENOUGH,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NOT_MATCH_LAND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NOT_RIPE,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SEED_CONF_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_WATER_NOT_ALLOW,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SEED_BAGITEM_NOT_EXIST,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SHOVEL_SEEDLING,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_WATER_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_MANURE_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_OWNER_PICK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_VISITOR_PICK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_UNLOCK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_NO_FRIEND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NPC_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_CATCH_FORBID,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ACTOR_NOT_READY,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_VISITOR_NUM_OVER_LIMIT,
  ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_SYSTEM_MAINTENANCE,
  ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_CLIENT_VERSION_IMCOMPATIBLE,
  ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_SYSTEM_NOT_OPEN
}
for k, v in pairs(ProtoEnum.MOBA_RET.ZoneSceneTeleportToPlayerError) do
  table.insert(ActionUtils.ExpectedErrorCodes, v)
end
ActionUtils.EndDialogueErrorCodes = {
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ERR_OTHER_PLAYER_IS_INTERACTING_MIRACLE,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ERR_MIRACLE_NPC_TIME_OUT,
  ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_BAG_ITEM_PET_EGG_LIMIT,
  ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_BAG_ITEM_USEFUL_LIMIT,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_BONFIRE_IS_BURNING,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_INVALID_ACTION_PARAMS,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_CNT_NOT_ENOUGH,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_NUMBER_NOT_ENOUGH,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NOT_MATCH_LAND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NOT_RIPE,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SEED_CONF_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_WATER_NOT_ALLOW,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SEED_BAGITEM_NOT_EXIST,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_SHOVEL_SEEDLING,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_WATER_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_MANURE_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_OWNER_PICK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_VISITOR_PICK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_UNLOCK_FAILED,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_LAND_STEAL_NO_FRIEND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NPC_NOT_FOUND,
  ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PLANT_NPC_NOT_FOUND
}
ActionUtils.ActionSubmissionMode = {
  ThrowEnd = 0,
  Local = 1,
  SceneNpc = 2,
  NextAct = 3
}
ActionUtils.DefaultActionSubmissionMode = ActionUtils.ActionSubmissionMode.ThrowEnd

local function GetAngleAsCosine(key)
  local Conf = _G.DataConfigManager:GetBattleGlobalConfig(key)
  local Angle = 30
  if Conf and Conf.num then
    Angle = Conf.num
  end
  return math.cos(Angle)
end

local function GetNum(key)
  local Conf = _G.DataConfigManager:GetBattleGlobalConfig(key)
  local Num = 30
  if Conf and Conf.num then
    Num = Conf.num
  end
  return Num
end

local P2NAbs = GetAngleAsCosine("touch_battle_player_trigger_angle")
local N2PAbs = GetAngleAsCosine("touch_battle_npc_trigger_angle")
local VDiffThreshold = GetNum("velocity_difference_threshold")

function ActionUtils.CalcPursue(Action)
  if not Action then
    return false, false
  end
  local Player = Action:GetPlayer()
  local PlayerView = Player and Player.viewObj
  if PlayerView.BP_RideComponent.RidePet then
    PlayerView = PlayerView.BP_RideComponent.RidePet
  end
  local NPC = Action:GetOwnerNPC()
  local NPCView = NPC and NPC.viewObj
  if not PlayerView or not NPCView then
    return false, false
  end
  local PComp = PlayerView.CharacterMovement
  local NComp = NPCView.CharacterMovement
  local PVel = PComp.Velocity
  local NVel = NComp.Velocity
  local PVelNorm = UE.FVector(PVel.X, PVel.Y, 0)
  local NVelNorm = NPCView:GetActorForwardVector()
  PVelNorm:Normalize()
  local PlayerLoc = PlayerView:K2_GetActorLocation()
  local NPCLoc = NPCView:K2_GetActorLocation()
  local P2NDir = NPCLoc - PlayerLoc
  local N2PDir = PlayerLoc - NPCLoc
  P2NDir.Z = 0
  N2PDir.Z = 0
  P2NDir:Normalize()
  N2PDir:Normalize()
  local CosP2N = PVelNorm:Dot(P2NDir)
  local CosN2P = NVelNorm:Dot(N2PDir)
  local PlayerPursue = CosP2N >= 1 - P2NAbs
  local NPCPursue = CosN2P >= 1 - N2PAbs
  if PlayerPursue or NPCPursue then
    Player.TouchBattleVel = PVel:Size()
    Player.IsTurnToTarget = PlayerPursue
    NPC.TouchBattleVel = NVel:Size()
    NPC.IsTurnToTarget = NPCPursue
  end
  if PlayerPursue and NPCPursue then
    local PSpeed = PVel:Size()
    local NSpeed = NVel:Size()
    if PSpeed > NSpeed + VDiffThreshold then
      NPCPursue = false
    elseif PSpeed < NSpeed - VDiffThreshold then
      PlayerPursue = false
    end
  end
  if ActionUtils.VisualDebug then
    if PVel:Size() < 10 then
      UE.UKismetSystemLibrary.DrawDebugArrow(PlayerView, PlayerLoc, PlayerLoc + FVectorUp * 300, 6, UE.FLinearColor(0, 1, 1, 1), -1, 3)
    else
      UE.UKismetSystemLibrary.DrawDebugArrow(PlayerView, PlayerLoc, PlayerLoc + PVelNorm * 300, 6, UE.FLinearColor(0, 1, 1, 1), -1, 3)
    end
    if NVel:Size() < 10 then
      UE.UKismetSystemLibrary.DrawDebugArrow(PlayerView, NPCLoc, NPCLoc + FVectorUp * 300, 6, UE.FLinearColor(0, 1, 1, 1), -1, 3)
    else
      UE.UKismetSystemLibrary.DrawDebugArrow(PlayerView, NPCLoc, NPCLoc + NVelNorm * 300, 6, UE.FLinearColor(0, 1, 1, 1), -1, 3)
    end
    if PlayerPursue or NPCPursue then
      UE.UKismetSystemLibrary.DrawDebugLine(PlayerView, PlayerLoc, NPCLoc, UE.FLinearColor(0, 1, 0, 1), -1, 3)
    else
      UE.UKismetSystemLibrary.DrawDebugLine(PlayerView, PlayerLoc, NPCLoc, UE.FLinearColor(1, 0, 0, 1), -1, 3)
    end
  end
  return PlayerPursue, NPCPursue
end

return ActionUtils
