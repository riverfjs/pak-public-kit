local BattleAIInputParams = require("NewRoco.Modules.Core.Battle.AI.BattleAIInputParams")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleAIManager = NRCClass:Extend("BattleAIManager")

function BattleAIManager:Ctor()
  Log.Debug("BattleAIManager ctor")
  UE4.UNRCStatics.EnableEQSDebug(false)
  UE4.UNRCStatics.EnableMoveableBattleDebug(false)
  self.playerSearchThreadCount = 0
  self.playerSearchRunningThreadCount = 0
end

function BattleAIManager:DebugShowPetDistanceBetween()
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  local vec1 = BattlePet1.model:Abs_K2_GetActorLocation()
  local vec2 = BattlePet2.model:Abs_K2_GetActorLocation()
  Log.Debug("show me pet distance between:", (vec1 - vec2):Size())
end

function BattleAIManager:DebugCreateBlockCubeInBattleField()
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
end

function BattleAIManager:TestCheckIsAttackable(boo)
  if boo then
    local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
    local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
    BattlePet1.model.Tags = {
      "BattlePetFrom"
    }
    BattlePet2.model.Tags = {
      "BattlePetTo"
    }
    Log.Debug("TestCheckIsAttackable:", BattlePet1.model:Abs_K2_GetActorLocation(), BattlePet2.model:Abs_K2_GetActorLocation())
    local positionChecker = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattleCheckCurPositionIsAtkable.BattleCheckCurPositionIsAtkable")
    if positionChecker then
      local result = positionChecker:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, BattlePet1.model, self, function(_, QueryResult)
        Log.Debug("BattleAIManager OnCheckComplete:", QueryResult.bSuccess, BattlePet1.guid, BattlePet2.guid)
      end)
      Log.Debug("BattleAIManager SearchValidPosition:", BattlePet1.name, result)
    end
  else
    local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
    local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
    BattlePet1.model.Tags = {
      "BattlePetTo"
    }
    BattlePet2.model.Tags = {
      "BattlePetFrom"
    }
    Log.Debug("TestCheckIsAttackable:", BattlePet1.model:Abs_K2_GetActorLocation(), BattlePet2.model:Abs_K2_GetActorLocation())
    Log.Debug("SHOW ME RANGE::")
    local positionChecker = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattleCheckCurPositionIsAtkable.BattleCheckCurPositionIsAtkable")
    if positionChecker then
      local result = positionChecker:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, BattlePet2.model, self, function(_, QueryResult)
        Log.Debug("BattleAIManager OnCheckComplete:", QueryResult.bSuccess, BattlePet2.guid, BattlePet1.guid)
      end)
      Log.Debug("BattleAIManager SearchValidPosition:", BattlePet2.name, result)
    end
  end
end

function BattleAIManager:TestMoveToValidPos()
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  BattlePet1.model.Tags = {
    "BattlePetTo"
  }
  BattlePet2.model.Tags = {
    "BattlePetFrom"
  }
  local battlePetFrom = BattlePet2
  local battlePetTo = BattlePet1
  self.battlePetFrom = battlePetFrom
  self.battlePetTo = battlePetTo
  self.searchPosRunner = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattlePetSearchPosEQS.BattlePetSearchPosEQS")
  if self.searchPosRunner then
    self.onComplete = onComplete
    self.searchPosRunner:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePetFrom.model, self, function(_, QueryResult)
      if 0 == QueryResult.ResultLocations:Length() then
        Log.Error("search pos fail:", self.battlePetFrom.guid, self.battlePetTo.guid)
      else
        local targetLocation = QueryResult.ResultLocations:Get(1)
        self:JumpToLocation(self.battlePetFrom, targetLocation)
      end
    end)
  end
end

function BattleAIManager:TestMoveToValidPos1()
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  BattlePet1.model.Tags = {
    "BattlePetFrom"
  }
  BattlePet2.model.Tags = {
    "BattlePetTo"
  }
  local battlePetFrom = BattlePet1
  local battlePetTo = BattlePet2
  self.battlePetFrom = battlePetFrom
  self.battlePetTo = battlePetTo
  self.searchPosRunner = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattlePetSearchPosEQS.BattlePetSearchPosEQS")
  if self.searchPosRunner then
    self.onComplete = onComplete
    self.searchPosRunner:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePetFrom.model, self, function(_, QueryResult)
      if 0 == QueryResult.ResultLocations:Length() then
        Log.Error("search pos fail:", self.battlePetFrom.guid, self.battlePetTo.guid)
      else
        local targetLocation = QueryResult.ResultLocations:Get(1)
        self:JumpToLocation(self.battlePetFrom, targetLocation)
      end
    end)
  end
end

function BattleAIManager:CheckCurPositionIsValidToAtkTarget(battlePetFrom, battlePetTo, callbackTaget, onComplete)
  if self.isRunningAI then
    if onComplete then
      onComplete(callbackTaget)
    end
    Log.Error("\229\189\147\229\137\141\230\173\163\229\156\168\232\191\144\232\161\140\230\136\152\230\150\151AI\239\188\140\232\175\183\229\139\191\229\144\140\230\151\182\229\164\154\230\172\161\232\176\131\231\148\168")
    return
  end
  if not battlePetFrom or not battlePetTo then
    self:OnMoveCompleted(false)
    return
  end
  self.isRunningAI = true
  self:MarkAllBattlePet()
  battlePetFrom.model.Tags = {
    "BattlePetFrom"
  }
  battlePetTo.model.Tags = {
    "BattlePetTo"
  }
  Log.Debug("CheckCurPositionIsValidToAtkTarget:", battlePetFrom.model:Abs_K2_GetActorLocation(), battlePetTo.model:Abs_K2_GetActorLocation())
  self.battlePetFrom = battlePetFrom
  self.battlePetTo = battlePetTo
  self.callbackTaget = callbackTaget
  self.onComplete = onComplete
  self.positionChecker = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattleCheckCurPositionIsAtkable.BattleCheckCurPositionIsAtkable")
  self.positionChecker:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePetFrom.model, self, self.OnCheckAttackableComplete)
end

function BattleAIManager:OnCheckAttackableComplete(QueryResult)
  Log.Debug("BattleAIManager OnCheckComplete:", QueryResult.bSuccess, self.battlePetFrom.guid, self.battlePetTo.guid)
  if QueryResult.bSuccess then
    self:OnMoveCompleted(false)
  else
    Log.Warning(self.battlePetFrom:GetCard():GetName(), "\229\176\157\232\175\149\230\148\187\229\135\187\228\189\134\230\148\187\229\135\187\230\163\128\230\181\139\228\184\141\233\128\154\232\191\135\239\188\140\233\156\128\232\166\129\228\191\174\230\148\185\228\189\141\231\189\174:")
    self:SearchValidPosition(self.battlePetFrom, self.battlePetTo, self.callbackTaget, self.onComplete)
  end
end

function BattleAIManager:SearchValidPosition(battlePetFrom, battlePetTo, callbackTaget, onComplete)
  if not battlePetFrom or not battlePetTo then
    self:OnMoveCompleted(false)
    return
  end
  self.searchPosRunner = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattlePetSearchPosEQS.BattlePetSearchPosEQS")
  Log.Debug("BattleAIManager SearchValidPosition:", self.battlePetFrom.model)
  self.searchPosRunner:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePetFrom.model, self, self.OnSearchCompleteCallback)
end

function BattleAIManager:SearchPlayerValidPosition(battlePlayer, battlePetTo, battlePetFrom, callbackTarget, onComplete)
  if not battlePlayer or not battlePetTo then
    self:OnMoveCompleted(false)
    return
  end
  self.playerSearchThreadCount = self.playerSearchThreadCount + 1
  self.playerSearchRunningThreadCount = self.playerSearchRunningThreadCount + 1
  if battlePlayer.teamEnm == BattleEnum.Team.ENUM_TEAM then
    self:MarkAllBattlePet()
    battlePetTo.model.Tags = {
      "BattlePetTo"
    }
    battlePetFrom.model.Tags = {
      "BattlePetFrom"
    }
    self.battlePlayerFromTeam = battlePlayer
    self.battlePetToTeam = battlePetTo
    self.battlePetFromTeam = battlePetFrom
    self.playerSearchPosRunnerTeam = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattlePlayerSearchPosEQS.BattlePlayerSearchPosEQS")
    if self.playerSearchPosRunnerTeam then
      self.callbackTargetTeam = callbackTarget
      self.onCompleteTeam = onComplete
      self.playerSearchPosRunnerTeam:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePlayer.model, self, self.OnTeamPlayerSearchCompleteCallback)
    end
  else
    self:MarkAllBattlePet()
    battlePetTo.model.Tags = {
      "BattlePetFrom"
    }
    battlePetFrom.model.Tags = {
      "BattlePetTo"
    }
    self.battlePlayerFromEnemy = battlePlayer
    self.battlePetToEnemy = battlePetFrom
    self.battlePetFromEnemy = battlePetTo
    self.playerSearchPosRunnerEnemy = self:CreateEQSRunner("/Game/NewRoco/Modules/Core/Battle/AI/BattlePlayerSearchPosEQSEnemy.BattlePlayerSearchPosEQSEnemy")
    if self.playerSearchPosRunnerEnemy then
      self.callbackTargetEnemy = callbackTarget
      self.onCompleteEnemy = onComplete
      self.playerSearchPosRunnerEnemy:StartQuery(UE4.EEnvQueryRunMode.SingleResult, nil, battlePlayer.model, self, self.OnEnemyPlayerSearchCompleteCallback)
    end
  end
end

function BattleAIManager:OnTeamPlayerSearchCompleteCallback(QueryResult)
  if 0 == QueryResult.AbsoluteResultLocations:Length() then
    self:OnPlayerMoveFinishTeam()
    return
  end
  local targetLocation = QueryResult.AbsoluteResultLocations:Get(1)
  local ans, pos = LineTraceUtils.GetPointValidLocation(targetLocation)
  if true == ans and true == self.battlePlayerFromTeam.model.AllowToTurn then
    pos.Z = pos.Z + self.battlePlayerFromTeam.model:GetHalfHeight()
    local playerPos = self.battlePlayerFromTeam.model:Abs_K2_GetActorLocation()
    local distance = UE4.FVector(pos.X - playerPos.X, pos.Y - playerPos.Y, pos.Z - playerPos.Z)
    local distance3D = distance:Size()
    if distance3D < BattleConst.DynamicBattle.PlayerMinMovementLength then
      self:OnPlayerMoveFinishTeam()
      return
    end
    self.controllerTeam = self.battlePlayerFromTeam.model:GetController()
    local pathFindingComp = self.controllerTeam:GetPathFollowingComponent()
    UE4.UNRCStatics.SetPathFollowingBlockDetection(pathFindingComp, 10.0, 0.1, 5.0)
    pos = SceneUtils.ConvertAbsoluteToRelative(pos)
    self.moveToProxyObjTeam = UE4.UAIBlueprintHelperLibrary.CreateMoveToProxyObject(UE4Helper.GetCurrentWorld(), self.controllerTeam:K2_GetPawn(), pos)
    local handlerSuccess = SimpleDelegateFactory:CreateCallback(self, self.OnPlayerMoveSuccessTeam)
    self.moveToProxyObjTeam.OnSuccess:Add(self.battlePlayerFromTeam.model:GetController(), handlerSuccess)
    local handlerFail = SimpleDelegateFactory:CreateCallback(self, self.OnPlayerMoveFailTeam)
    self.moveToProxyObjTeam.OnFail:Add(self.battlePlayerFromTeam.model:GetController(), handlerFail)
    self.battlePlayerFromTeam.model.Mesh:GetAnimInstance():SetRootMotionMode(UE.ERootMotionMode.IgnoreRootMotion)
    self.battlePlayerFromTeam.model:PlayAnimByName(BattleConst.ACAnimNamePlayer.BattleRun, 1, 0, 0, 0, -1)
  else
    self:OnPlayerMoveFinishTeam()
  end
end

function BattleAIManager:OnEnemyPlayerSearchCompleteCallback(QueryResult)
  if 0 == QueryResult.AbsoluteResultLocations:Length() then
    self:OnPlayerMoveFinishEnemy()
    return
  end
  local targetLocation = QueryResult.AbsoluteResultLocations:Get(1)
  local ans, pos = LineTraceUtils.GetPointValidLocation(targetLocation)
  if true == ans and true == self.battlePlayerFromEnemy.model.AllowToTurn then
    pos.Z = pos.Z + self.battlePlayerFromEnemy.model:GetHalfHeight()
    local playerPos = self.battlePlayerFromEnemy.model:Abs_K2_GetActorLocation()
    local distance = UE4.FVector(pos.X - playerPos.X, pos.Y - playerPos.Y, pos.Z - playerPos.Z)
    local distance3D = distance:Size()
    if distance3D < BattleConst.DynamicBattle.PlayerMinMovementLength then
      self:OnPlayerMoveFinishEnemy(false)
      return
    end
    self.controllerEnemy = self.battlePlayerFromEnemy.model:GetController()
    self.battlePlayerFromEnemy.model.Turn_Alpha = 0
    self.battlePlayerFromEnemy.model.Overlap_Alpha = 0
    pos = SceneUtils.ConvertAbsoluteToRelative(pos)
    self.moveToProxyObjEnemy = UE4.UAIBlueprintHelperLibrary.CreateMoveToProxyObject(UE4Helper.GetCurrentWorld(), self.controllerEnemy:K2_GetPawn(), pos)
    local pathFindingComp = self.controllerEnemy:GetPathFollowingComponent()
    UE4.UNRCStatics.SetPathFollowingBlockDetection(pathFindingComp, 10.0, 0.1, 5.0)
    local handlerSuccess = SimpleDelegateFactory:CreateCallback(self, self.OnPlayerMoveSuccessEnemy)
    self.moveToProxyObjEnemy.OnSuccess:Add(self.battlePlayerFromEnemy.model:GetController(), handlerSuccess)
    local handlerFail = SimpleDelegateFactory:CreateCallback(self, self.OnPlayerMoveFailEnemy)
    self.moveToProxyObjEnemy.OnFail:Add(self.battlePlayerFromEnemy.model:GetController(), handlerFail)
  else
    self:OnPlayerMoveFinishEnemy(false)
  end
end

function BattleAIManager:OnPlayerMoveSuccessTeam()
  self.moveToProxyObjTeam:Release()
  self.moveToProxyObjTeam = nil
  self.controllerTeam = nil
  self.battlePlayerFromTeam.model.RocoAnim:StopAnimByName(BattleConst.ACAnimNamePlayer.BattleRun)
  self:OnPlayerMoveFinishTeam()
end

function BattleAIManager:OnPlayerMoveFailTeam(Reason)
  self.moveToProxyObjTeam:Release()
  self.moveToProxyObjTeam = nil
  self.controllerTeam = nil
  self.battlePlayerFromTeam.model.RocoAnim:StopAnimByName(BattleConst.ACAnimNamePlayer.BattleRun)
  self:OnPlayerMoveFinishTeam()
end

function BattleAIManager:OnPlayerMoveSuccessEnemy()
  self.moveToProxyObjEnemy:Release()
  self.moveToProxyObjEnemy = nil
  self.controllerEnemy = nil
  _G.DelayManager:DelaySeconds(BattleConst.DynamicBattle.WaitPlayerTranslationTime, self.OnPlayerMoveFinishEnemy, self)
end

function BattleAIManager:OnPlayerMoveFailEnemy()
  self.moveToProxyObjEnemy:Release()
  self.moveToProxyObjEnemy = nil
  self.controllerEnemy = nil
  _G.DelayManager:DelaySeconds(BattleConst.DynamicBattle.WaitPlayerTranslationTime, self.OnPlayerMoveFinishEnemy, self)
end

function BattleAIManager:OnPlayerMoveFinishTeam()
  if not self.battlePetFromTeam or self.battlePlayerFromTeam == nil or nil == self.battlePlayerFromTeam.model or self.battlePlayerFromTeam.model.AllowToTurn == false or nil == self.battlePetToTeam.model then
    self:OnTeamMoveCompleted()
    return
  end
  local aPos = self.battlePlayerFromTeam.model:Abs_K2_GetActorLocation()
  local bPos = self.battlePetToTeam.model:Abs_K2_GetActorLocation()
  local dir = bPos - aPos
  dir.Z = 0
  local cur = self.battlePlayerFromTeam.model:K2_GetActorRotation()
  local Rot = dir:ToRotator():Clamp()
  local turnTime = tonumber(_G.DataConfigManager:GetGlobalConfigByKeyType("npc_turn_time", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str)
  self.battlePlayerFromTeam.model:OnTurn(Rot.Yaw, turnTime)
  _G.DelayManager:DelaySeconds(BattleConst.DynamicBattle.WaitPlayerRotationTime, self.OnTeamMoveCompleted, self)
end

function BattleAIManager:OnPlayerMoveFinishEnemy()
  if self.battlePetFromEnemy == nil or nil == self.battlePlayerFromEnemy.model or self.battlePlayerFromEnemy.model.AllowToTurn == false or nil == self.battlePetToEnemy.model then
    self:OnEnemyMoveCompleted()
    return
  end
  local aPos = self.battlePlayerFromEnemy.model:Abs_K2_GetActorLocation()
  local bPos = self.battlePetToEnemy.model:Abs_K2_GetActorLocation()
  local dir = bPos - aPos
  dir.Z = 0
  local cur = self.battlePlayerFromEnemy.model:K2_GetActorRotation()
  local Rot = dir:ToRotator():Clamp()
  local turnTime = tonumber(_G.DataConfigManager:GetGlobalConfigByKeyType("npc_turn_time", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str)
  self.battlePlayerFromEnemy.model.EnableInjectAnim = true
  self.battlePlayerFromEnemy.model:OnTurn(Rot.Yaw, turnTime)
  _G.DelayManager:DelaySeconds(BattleConst.DynamicBattle.WaitPlayerRotationTime, self.OnEnemyMoveCompleted, self)
end

function BattleAIManager:MoveSpawnPointToValidLocation(actor)
  local NavMeshObj = BattleEnv.RecastNavMesh_Default
  Log.Debug("BattleConstructNearbyBattleEnvAction MoveSpawnPointToValidLocation NavMeshObj:", type(NavMeshObj), actor:GetName(), actor:Abs_K2_GetActorLocation())
  local QueryExtent = UE4.FVector(0, 0, 40000)
  local actorLocation = actor:Abs_K2_GetActorLocation()
  local HitLocation, HitResult = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), actorLocation, nil, NavMeshObj, nil, QueryExtent)
  if HitResult and HitLocation then
    Log.Debug("BattleConstructNearbyBattleEnvAction MoveSpawnPointToValidLocation HitLocation 11:", HitLocation, ",PlayerLocation:", actorLocation)
    actor:Abs_K2_SetActorLocation_WithoutHit(HitLocation)
    Log.Debug("BattleConstructNearbyBattleEnvAction MoveSpawnPointToValidLocation:", BattleEnv.BattlePetCameraLocationZFix)
  else
    Log.Debug("BattleConstructNearbyBattleEnvAction MoveSpawnPointToValidLocation find fail 22:", HitResult, HitLocation, actorLocation, UE4Helper.GetCurrentWorld())
  end
end

function BattleAIManager:OnSearchCompleteCallback(QueryResult)
  if 0 == QueryResult.ResultLocations:Length() then
    Log.Error("\230\151\160\230\179\149\230\137\190\229\136\176\229\144\136\233\128\130\229\143\175\228\187\165\232\191\155\230\148\187\231\154\132\231\130\185\239\188\140\229\142\159\229\156\176\229\143\145\232\181\183\230\148\187\229\135\187:", self.battlePetFrom.guid, self.battlePetTo.guid)
    self:OnMoveCompleted(false)
    return
  end
  local targetLocation = QueryResult.ResultLocations:Get(1)
  self:JumpToLocation(self.battlePetFrom, targetLocation)
end

function BattleAIManager:JumpToPosFixed(battlePet, pos)
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = _G.BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  if not BattlePet1 or not BattlePet2 then
    return
  end
  if not BattlePet1.model or not BattlePet2.model then
    return
  end
  BattlePet1.model.Tags = {
    "BattlePetTo"
  }
  BattlePet2.model.Tags = {
    "BattlePetFrom"
  }
  self.battlePetFrom = BattlePet1
  self.battlePetTo = BattlePet2
  return self:JumpToLocation(battlePet, pos, false)
end

function BattleAIManager:JumpToLeftPos(battlePet, distance)
  self:JumpToPosAssignPos(battlePet, distance, false)
end

function BattleAIManager:JumpToRightPos(battlePet, distance)
  self:JumpToPosAssignPos(battlePet, distance, true)
end

function BattleAIManager:JumpToPosAssignPos(battlePet, distance, isRight)
  if self.petOriPos then
    return false
  end
  local BattlePet1 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local BattlePet2 = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  if not (BattlePet1 and BattlePet1.model and BattlePet2) or not BattlePet2.model then
    return
  end
  BattlePet1.model.Tags = {
    "BattlePetTo"
  }
  BattlePet2.model.Tags = {
    "BattlePetFrom"
  }
  self.battlePetFrom = BattlePet1
  self.battlePetTo = BattlePet2
  local leftDir = -UE4.UKismetMathLibrary.GetRightVector(battlePet.model:K2_GetActorRotation())
  local halfHeight = battlePet:GetHalfHeight()
  local oriPos = battlePet.model:K2_GetActorLocation()
  self.petOriPos = oriPos
  if isRight then
    oriPos = self.petOriPos
    self.petOriPos = nil
  end
  local leftLoc = oriPos + leftDir * distance
  local groundPos, isHit = LineTraceUtils.GetPointValidLocationByLine(leftLoc, halfHeight, false)
  self:JumpToLocation(battlePet, groundPos, false)
end

function BattleAIManager:JumpToLocation(battlePetFrom, targetPoint, donntHandleEvent)
  local g6SkillClass = _G.BattleResourceManager:GetCacheAssetDirect(BattleConst.AI_BattlePetJumpToLocation_C)
  local skillComponent = battlePetFrom.model.RocoSkill
  if not skillComponent then
    return false
  end
  local skillObj = skillComponent:FindOrAddSkillObj(g6SkillClass)
  if not skillObj then
    return false
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(battlePetFrom.model)
  skillObj:SetTargets({
    self.battlePetTo.model
  })
  if not donntHandleEvent then
    skillObj:RegisterRawCallback(self, self.OnSkillEvent)
  end
  skillObj:RegisterEventCallback("Interrupt", self, self.OnJumpFailed)
  skillObj:RegisterEventCallback("StartFailed", self, self.OnJumpFailed)
  local Blackboard = skillObj:GetBlackboard()
  Blackboard:SetValueAsVector("TargetLocation", targetPoint)
  local result = skillComponent:PlaySkill(skillObj)
  return 0 == result
end

function BattleAIManager:OnJumpFailed()
  Log.Error("BattleAIManager:OnJumpFailed")
  self:OnMoveCompleted(false)
end

function BattleAIManager:OnSkillEvent(event, skill)
  if "End" == event or "Interrupt" == event then
    Log.Debug("\229\138\168\231\148\187\230\146\173\230\148\190\229\174\140\230\175\149")
    self:OnMoveCompleted(true)
    if BattleManager.vBattleField.battleCraneCamera then
      BattleManager.vBattleField.battleCraneCamera:JumpAnimCallBack()
    end
  elseif "CameraFollow" == event then
  end
end

function BattleAIManager:OnSuccess(RequestID, Result)
  self:OnMoveCompleted(true)
end

function BattleAIManager:OnFail()
  self:OnMoveCompleted(false)
end

function BattleAIManager:OnTeamMoveCompleted(result)
  if self.onCompleteTeam then
    DelayManager:DelayFrames(1, self.onCompleteTeam, self.callbackTargetTeam)
  end
  self:TryClearTags()
  self:TryClearPlayers()
end

function BattleAIManager:OnEnemyMoveCompleted(result)
  if self.onCompleteEnemy then
    DelayManager:DelayFrames(1, self.onCompleteEnemy, self.callbackTargetEnemy)
  end
  self:TryClearTags()
  self:TryClearPlayers()
end

function BattleAIManager:OnMoveCompleted(result)
  if self.onComplete then
    DelayManager:DelayFrames(1, self.onComplete, self.callbackTaget)
  end
  self:TryClearTags()
  self.onComplete = nil
  self.battlePetFrom = nil
  self.battlePetTo = nil
  self.positionChecker = nil
  self.searchPosRunner = nil
  self.playerSearchPosRunner = nil
  self.isRunningAI = false
end

function BattleAIManager:SearchEllipticPosWithCallBack(BattleCenter, Caller, CallBack, InsideA, InsideB, OutSideA, OutSideB, StartAngle, EndAngle)
  if not BattleCenter then
    return
  end
  BattleCenter.Tags = {
    "BattleCenter"
  }
  local Runner = self:CreateEllipticEQSRunner(InsideA, InsideB, OutSideA, OutSideB, StartAngle, EndAngle)
  if Runner then
    local queryId = Runner:StartQuery(UE4.EEnvQueryRunMode.AllMatching, nil, BattleCenter, Caller, CallBack)
    return true, queryId, Runner
  end
end

function BattleAIManager:SearchEllipticPos(BattleCenter, InsideA, InsideB, OutSideA, OutSideB, StartAngle, EndAngle)
  if not BattleCenter then
    self:OnEllipticSearchCompleteCallback()
    return
  end
  BattleCenter.Tags = {
    "BattleCenter"
  }
  local Runner = self:CreateEllipticEQSRunner(InsideA, InsideB, OutSideA, OutSideB, StartAngle, EndAngle)
  if Runner then
    Runner:StartQuery(UE4.EEnvQueryRunMode.AllMatching, nil, BattleCenter, self, self.OnEllipticSearchCompleteCallback)
    return true
  end
end

function BattleAIManager:OnEllipticSearchCompleteCallback(QueryResult)
  if QueryResult then
    _G.BattleManager.EllipticPos = {}
    for i = 1, QueryResult.AbsoluteResultLocations:Length() do
      local point = QueryResult.AbsoluteResultLocations:Get(i)
      table.insert(_G.BattleManager.EllipticPos, point)
    end
  end
end

function BattleAIManager:TryClearTags()
  if self.playerSearchThreadCount > 0 then
    self.playerSearchThreadCount = self.playerSearchThreadCount - 1
  end
  if 0 == self.playerSearchThreadCount then
    if self.battlePlayerFromTeam and self.battlePlayerFromTeam.model then
      self.battlePlayerFromTeam.model.Tags = {}
    end
    if self.battlePlayerFromEnemy and self.battlePlayerFromEnemy.model then
      self.battlePlayerFromEnemy.model.Tags = {}
    end
  end
end

function BattleAIManager:TryClearPlayers()
  if self.playerSearchRunningThreadCount > 0 then
    self.playerSearchRunningThreadCount = self.playerSearchRunningThreadCount - 1
  end
  if 0 == self.playerSearchRunningThreadCount then
    self.onCompleteTeam = nil
    self.battlePetFromTeam = nil
    self.battlePetToTeam = nil
    self.battlePlayerFromTeam = nil
    self.playerSearchPosRunnerTeam = nil
    self.onCompleteEnemy = nil
    self.battlePetFromEnemy = nil
    self.battlePetToEnemy = nil
    self.battlePlayerFromEnemy = nil
    self.playerSearchPosRunnerEnemy = nil
  end
end

function BattleAIManager:MarkAllBattlePet()
  local battlePets = BattleManager.battlePawnManager:GetAllPets()
  for i = 1, #battlePets do
    battlePets[i].model.Tags = {
      "BattlePetOther"
    }
  end
end

function BattleAIManager:ClearTags()
  if self.battlePetTo then
    self.battlePetTo.model.Tags = {}
  end
  if self.battlePetFrom then
    self.battlePetFrom.model.Tags = {}
  end
  if self.battlePlayerFrom then
    self.battlePlayerFrom.model.Tags = {}
  end
  if self.battlePlayerTo then
    self.battlePlayerTo.model.Tags = {}
  end
end

function BattleAIManager:CreateEQSRunner(QueryPath)
  local World = _G.UE4Helper.GetCurrentWorld()
  local Runner = NewObject(BattleResourceManager:GetCacheAssetDirect(BattleConst.BP_BattleEQSRunner_C), World)
  Runner.Query = UE4.UObject.Load(QueryPath)
  return Runner
end

function BattleAIManager:CreateEllipticEQSRunner(InsideA, InsideB, OutSideA, OutSideB, StartAngle, EndAngle)
  local World = _G.UE4Helper.GetCurrentWorld()
  local Runner = NewObject(BattleResourceManager:GetCacheAssetDirect(BattleConst.BP_BattleEQSRunner_C), World)
  if not self.EllipticQuery then
    self.EllipticQuery = BattleResourceManager:GetCacheAssetDirect(BattleConst.BattleSearchElliptic)
  end
  Runner.Query = self.EllipticQuery
  local changeQuery = Runner.Query
  local QueryManager = UE4.UNRCStatics.GetEnvQueryManager()
  if QueryManager and QueryManager.InstanceCache:Length() > 0 then
    for i = 1, QueryManager.InstanceCache:Length() do
      local Query = QueryManager.InstanceCache:Get(i).Template
      if Query:GetName() == "BattleSearchEllipticPosEQS_AllMatching" then
        changeQuery = Query
        break
      end
    end
  end
  if changeQuery and changeQuery.Options:Length() >= 1 then
    local QueryOption = changeQuery.Options:Get(1)
    local elliptic = QueryOption.Generator
    if InsideA and elliptic.InsideA then
      elliptic.InsideA.DefaultValue = InsideA
    end
    if InsideB and elliptic.InsideB then
      elliptic.InsideB.DefaultValue = InsideB
    end
    if OutSideA and elliptic.OutSideA then
      elliptic.OutSideA.DefaultValue = OutSideA
    end
    if OutSideB and elliptic.OutSideB then
      elliptic.OutSideB.DefaultValue = OutSideB
    end
    if StartAngle and elliptic.StartAngle then
      elliptic.StartAngle.DefaultValue = StartAngle
    end
    if EndAngle and elliptic.EndAngle then
      elliptic.EndAngle.DefaultValue = EndAngle
    end
  end
  return Runner
end

return BattleAIManager
