local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local HeadLookAtComponent = require("NewRoco.Modules.Core.Scene.Component.HeadLookAt.HeadLookAtComponent")
local BattleExitHelper = {}

function BattleExitHelper.CalcDeadPosition()
  local player = BattleUtils.GetPlayerModel()
  local Start = player:Abs_K2_GetActorLocation() + player:GetActorForwardVector() * 200
  return Start
end

function BattleExitHelper.LookAt(a, b)
  if not a or not b then
    return
  end
  local aPos = a:Abs_K2_GetActorLocation()
  local bPos = b:Abs_K2_GetActorLocation()
  local dir = bPos - aPos
  dir.Z = 0
  a:K2_SetActorRotation(dir:ToRotator(), true)
end

function BattleExitHelper.ResetPlayerCamera()
  Log.Error("BattleExitHelper ResetPlayerCamera delay", UE4.UNRCStatics.GetCurGFrameNumber())
  local player = BattleUtils.GetPlayer()
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_LOCAL_PLAYER, false)
  BattleUtils.SetPlayerSkmTickable(true)
  _G.BattleManager.battlePawnManager:HideAll(false)
  _G.BattleManager.vBattleField:HideAllWaterPlatforms()
  _G.BattleManager:StopBattleBGM()
  BattleUtils.RequestPlayerCam()
end

function BattleExitHelper.PlayExitSkill(killer, victim, caller, callback, exit, postStart, banBall)
  if not killer then
    Log.Error("BattleExitHelper PlayExitSkill is not exist")
    if postStart then
      postStart(caller)
    end
    if exit then
      exit(caller)
    end
    if callback then
      callback(caller)
    end
    return
  end
  local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.LeaveBattleField)
  if not SkillResConf then
    Log.Debug("BattleExitHelper.PlayExitSkill0")
    if postStart then
      postStart(caller)
    end
    if exit then
      exit(caller)
    end
    if callback then
      callback(caller)
    end
    return
  end
  BattleResourceManager:LoadClassAsync(nil, SkillResConf.res_id, function(_caller, skillClass)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideMain)
    local PawnManager = _G.BattleManager.battlePawnManager
    BattleUtils.SetPlayerSkmTickable(true)
    local player = PawnManager:GetPlayerMyTeam()
    if not player or not player.model then
      if callback then
        callback(caller)
      end
      return
    end
    PawnManager:TogglePetBuffsVisibility(false)
    local SkillObject = player.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
    if not SkillObject then
      if callback then
        callback(caller)
      end
      return
    end
    local localplayer = BattleUtils.GetPlayer()
    local headLookAtComponent = localplayer:GetHeadLookAtComponent()
    if headLookAtComponent then
      headLookAtComponent:DisableManualOverride(true)
    end
    local blackboard = SkillObject:GetBlackboard()
    if not banBall and blackboard and UE.UObject.IsValid(blackboard) then
      blackboard:SetValueAsString("HasBall", "HasBall")
    end
    local characters = PawnManager:GetAllPawnActorForSkill()
    characters[0] = localplayer.viewObj
    SkillObject:SetCharacters(characters)
    SkillObject:SetCaster(localplayer.viewObj)
    local path = killer:GetBallPath()
    SkillObject:SetDynamicData({BallPath = path})
    local targets = {
      killer and killer.model,
      victim and victim.model
    }
    SkillObject:SetTargets(targets)
    if exit then
      SkillObject:RegisterEventCallback("Exit", caller, exit)
    end
    SkillObject:RegisterEventCallback("PostStart", nil, function()
      player:HidePlayer()
      BattleExitHelper.OnSkillPostStart()
      postStart(caller)
    end)
    SkillObject:RegisterEventCallback("Exit", nil, BattleExitHelper.OnSkillExit)
    SkillObject:RegisterEventCallback("Restore", nil, BattleExitHelper.ResetPlayerCamera)
    SkillObject:RegisterEventCallback("PreEnd", caller, callback)
    SkillObject:RegisterEventCallback("End", caller, callback)
    player.model.RocoSkill:StopCurrentSkill()
    player:PlaySkillObject(SkillObject)
  end, function()
    if callback then
      callback(caller)
    end
  end)
end

function BattleExitHelper.OnSkillPostStart(event, skill)
  _G.BattleManager.battlePawnManager:HideAll(true)
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_LOCAL_PLAYER, false)
end

function BattleExitHelper.OnSkillExit(event, skill)
  local player = BattleUtils.GetPlayer()
  _G.BattleManager.battlePawnManager:HideAll(true)
  local playerBattle = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  playerBattle.model:SetActorEnableCollision(false)
  playerBattle.model:K2_GetRootComponent():SetCollisionProfileName("NoCollision")
  playerBattle.model:Abs_K2_SetActorLocation_WithoutHit(player:GetActorLocation())
  playerBattle.model:CustomTurn(player:GetActorRotation())
  _G.BattleManager.battleRuntimeData.rotation = nil
end

function BattleExitHelper.SetSeamlessExitBattle(caster, targets)
  _G.BattleManager.battleRuntimeData.battleExitParam.lastHitKiller = caster
  _G.BattleManager.battleRuntimeData.battleExitParam.lastHitPets = targets
  _G.BattleManager.battleRuntimeData.battleExitParam.IsBattleFinishSeamless = true
end

function BattleExitHelper.SetEnemyEscape(caster, targets)
  _G.BattleManager.battleRuntimeData.battleExitParam.lastHitKiller = caster
  _G.BattleManager.battleRuntimeData.battleExitParam.lastHitPets = targets
  _G.BattleManager.battleRuntimeData.battleExitParam.IsEnemyEscape = true
end

function BattleExitHelper.SetCatchExitBattle()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsBattleFinishByCatch = true
end

function BattleExitHelper.IsFinishSeamless()
  return _G.BattleManager.battleRuntimeData.battleExitParam.IsBattleFinishSeamless
end

function BattleExitHelper.IsFinishPveSeamless()
  return _G.BattleManager.battleRuntimeData.battleExitParam.IsPveSeamlessOver
end

function BattleExitHelper.IsFinishHandleSeamless()
  return _G.BattleManager.battleRuntimeData.battleExitParam.handleBattleExitBySeamlessType
end

function BattleExitHelper.IsFinishByCatch()
  return _G.BattleManager.battleRuntimeData.battleExitParam.IsBattleFinishByCatch
end

function BattleExitHelper.SetFinishPveSeamless()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsPveSeamlessOver = true
end

function BattleExitHelper.ClearFinishPveSeamless()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsPveSeamlessOver = false
end

function BattleExitHelper.SetFinishHandleSeamless()
  _G.BattleManager.battleRuntimeData.battleExitParam.handleBattleExitBySeamlessType = true
end

function BattleExitHelper.ClearFinishHandleSeamless()
  _G.BattleManager.battleRuntimeData.battleExitParam.handleBattleExitBySeamlessType = false
end

function BattleExitHelper.ClearFinishSeamlessFlag()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsPveSeamlessOver = false
  _G.BattleManager.battleRuntimeData.battleExitParam.handleBattleExitBySeamlessType = false
  _G.BattleManager.battleRuntimeData.battleExitParam.IsBattleFinishSeamless = false
end

function BattleExitHelper.IsPlayerSkillEscape()
  return _G.BattleManager.battleRuntimeData.battleExitParam.IsPlayerSkillEscape
end

function BattleExitHelper.SetPlayerSkillEscape()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsPlayerSkillEscape = true
end

function BattleExitHelper.ClearPlayerSkillEscape()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsPlayerSkillEscape = false
end

function BattleExitHelper:ResetData()
  self.ClearEnemyEscape()
  self.ClearPlayerSkillEscape()
  self.ClearFinishHandleSeamless()
  self.ClearFinishPveSeamless()
  self.ClearFinishSeamlessFlag()
end

function BattleExitHelper.ClearEnemyEscape()
end

return BattleExitHelper
