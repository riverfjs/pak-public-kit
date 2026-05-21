local ResQueue = require("NewRoco.Utils.ResQueue")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCResObject = require("NewRoco.Modules.Core.NPC.NPCResObject")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleSpectatorOutsidePetInfo = require("NewRoco.Modules.System.BattleSpectator.BattleSpectatorOutsidePetInfo")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local waterSurfaceCheckNum = 3
local waterSurfaceCheckRadius = 80
local waterSurfaceCheckAngleEach = 360.0 / waterSurfaceCheckNum
local BattleSpectatorOutsideRecord = _G.MakeSimpleClass("BattleSpectatorOutsideRecord")
local BattleCenterActorTag = "SpectatorOutside"
local WaterPlatformRadius = 280
local EndPerformLoadTimeout = 3
local PlayerForbidPerformStatus = {
  ProtoEnum.WorldPlayerStatusType.WPST_RIDING,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL,
  ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY,
  ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING,
  ProtoEnum.WorldPlayerStatusType.WPST_FALLING,
  ProtoEnum.WorldPlayerStatusType.WPST_LANDING,
  ProtoEnum.WorldPlayerStatusType.WPST_SLIDING,
  ProtoEnum.WorldPlayerStatusType.WPST_CLIMB,
  ProtoEnum.WorldPlayerStatusType.WPST_CLIMB_DASH,
  ProtoEnum.WorldPlayerStatusType.WPST_MANTLE,
  ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM
}

function BattleSpectatorOutsideRecord:Ctor(radiusScopePlayer, radiusScopeEnemy, angleScope, maxHeightGap, battle_id, player, npcId, petDataA, petDataB)
  self.radiusScopePlayer = radiusScopePlayer
  self.radiusScopeEnemy = radiusScopeEnemy
  self.angleScope = angleScope
  self.maxHeightGap = maxHeightGap
  self.battle_id = battle_id
  self.player = player
  if player then
    self.playerId = player:GetServerId()
    player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
  end
  self.npcId = npcId
  if npcId then
    local npc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, npcId)
    if npc then
      self.npc = npc
    end
  end
  if petDataA then
    local petInfoA = BattleSpectatorOutsidePetInfo(petDataA)
    if petInfoA:IsValid() then
      self.petInfoA = petInfoA
    else
      Log.Debug("petInfoA is not valid", self:GetDebugInfo(), petDataA.base_conf_id, petDataA.conf_id, petDataA.owner_obj_id)
    end
  end
  if petDataB then
    local petInfoB = BattleSpectatorOutsidePetInfo(petDataB)
    if petInfoB:IsValid() then
      self.petInfoB = petInfoB
    else
      Log.Debug("petInfoB is not valid", self:GetDebugInfo(), petDataB.base_conf_id, petDataB.conf_id, petDataB.owner_obj_id)
    end
  end
end

function BattleSpectatorOutsideRecord:GetDebugInfo()
  if self.npc and self.npc.config then
    return string.format("%d { %d <-> %s }", self.battle_id, self.playerId, self.npc:DebugNPCNameAndID())
  end
  return string.format("%d { %d <-> %d }", self.battle_id, self.playerId, self.npcId)
end

function BattleSpectatorOutsideRecord:OnTick(deltaTime)
  if not self then
    return
  end
  self.tickedTime = self.tickedTime + deltaTime
  if self.tickedTime < self.tickedInterval then
    return
  end
  self.tickedTime = self.tickedTime - self.tickedInterval
  if self.player:IsMoving() or self:CheckPlayerInTheAir(self.player) then
    Log.Debug("BattleSpectatorOutsideRecord:OnTick player is moving or in air", self:GetDebugInfo())
    _G.UpdateManager:UnRegister(self)
    self:ForceStopEndPerform()
    return
  end
end

function BattleSpectatorOutsideRecord:SetOtherEnemyPets(petsInfo)
  if not petsInfo then
    return
  end
  if not self.otherEnemyPets then
    self.otherEnemyPets = {}
  end
  if not self.otherEnemyPetsId then
    self.otherEnemyPetsId = {}
  end
  for _, petInfo in pairs(petsInfo) do
    local npcId = petInfo.npc_obj_id
    if not npcId or 0 == npcId then
    else
      table.insert(self.otherEnemyPetsId, npcId)
      local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcId)
      if not npc or not self:IsNpcPet(npc) then
      else
        self.otherEnemyPets[npcId] = npc
        npc:SetVisibleForBattleOutsideReason(false)
        Log.Debug("BattleSpectatorOutsideRecord:SetOtherEnemyPets", self:GetDebugInfo(), npc:DebugNPCNameAndID())
      end
    end
  end
end

function BattleSpectatorOutsideRecord:TryRecoverOtherEnemyPets()
  if not self.otherEnemyPets then
    return
  end
  for _, npc in pairs(self.otherEnemyPets) do
    if npc then
      local stillInBattle = npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
      if not stillInBattle then
        npc:SetVisibleForBattleOutsideReason(true)
        Log.Debug("BattleSpectatorOutsideRecord:TryRecoverOtherEnemyPets", self:GetDebugInfo(), npc:DebugNPCNameAndID())
      else
        Log.Debug("BattleSpectatorOutsideRecord:TryRecoverOtherEnemyPets wait other player", self:GetDebugInfo(), npc:DebugNPCNameAndID())
      end
    end
  end
  self.otherEnemyPets = nil
end

function BattleSpectatorOutsideRecord:Begin()
  if not self.player.viewObj then
    self.player:AddEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnPlayerViewShellLoadedForQuery)
    return
  end
  Log.Debug("BattleSpectatorOutsideRecord:Begin")
  self:BeginInternal()
end

function BattleSpectatorOutsideRecord:GetPetInfoValid()
  if self.petInfoA and self.petInfoA:IsValid() and self.petInfoB and self.petInfoB:IsValid() then
    return true
  end
  return false
end

function BattleSpectatorOutsideRecord:BeginInternal()
  if self:GetPetInfoValid() then
    if self:CheckPlayerInTheAir(self.player) then
      Log.Debug("BattleSpectatorOutsideRecord:BeginInternal player is the air", self:GetDebugInfo())
      self:OnQueryFailed()
    else
      self:FirstQueryPlayer()
    end
  else
    self:OnQueryFailed()
  end
end

function BattleSpectatorOutsideRecord:CheckPlayerInTheAir(player)
  if not player then
    return false
  end
  local statusComp = player.statusComponent
  if statusComp:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING) then
    Log.Debug("BattleSpectatorOutsideRecord:CheckPlayerInTheAir player is failing", self:GetDebugInfo())
    return true
  end
  local rideStatusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  if statusComp:HasStatus(rideStatusId) then
    local customParams = statusComp:GetCustomParams(rideStatusId)
    if customParams then
      local rideParams = customParams.ride_param
      if rideParams then
        local moveMode = rideParams.ride_move_mode
        if moveMode == ProtoEnum.SceneRideAllType.SRAT_FLY then
          Log.Debug("BattleSpectatorOutsideRecord:CheckPlayerInTheAir player is flying", self:GetDebugInfo(), moveMode)
          return true
        end
        Log.Debug("BattleSpectatorOutsideRecord:CheckPlayerInTheAir player ride", self:GetDebugInfo(), moveMode)
      end
    end
  end
  return false
end

function BattleSpectatorOutsideRecord:OnPlayerViewShellLoadedForQuery()
  Log.Debug("BattleSpectatorOutsideRecord:OnPlayerViewShellLoadedForQuery")
  self.player:RemoveEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnPlayerViewShellLoadedForQuery)
  self:BeginInternal()
end

function BattleSpectatorOutsideRecord:DoEqsQuery(radius, angle, factor, onQueryFinished, onQueryFailed, onQueryNil)
  local player = self.player
  local runner = self.runner
  if player and runner and runner.Query then
    local request = runner:MakeRequest(nil, player.viewObj)
    self:SetQueryParams(request, radius, angle, factor)
    self.queryId = -1
    self.queryId = runner:StartQueryWithRequest(UE4.EEnvQueryRunMode.AllMatching, request, self, onQueryFinished)
    if self.queryId == nil or self.queryId < 0 then
      Log.Warning("DoEqsQuery failed", self:GetDebugInfo())
      onQueryFailed(self)
    end
  else
    onQueryNil(self)
  end
end

function BattleSpectatorOutsideRecord:SetQueryParams(request, scope, angle, factor)
  if not request then
    return
  end
  request:SetFloatParam("Donut.InnerRadius", scope[2])
  request:SetFloatParam("Donut.OuterRadius", scope[1])
  request:SetFloatParam("Donut.ArcAngle", angle)
  request:SetFloatParam("Distance.FloatValueMax", self.maxHeightGap)
  request:SetFloatParam("Dot.ScoringFactor", factor or 1.0)
end

function BattleSpectatorOutsideRecord:SavePlayerQueryResult(Result)
  self.PlayerQueryResult = UE4.FNRCQueryResult()
  self.PlayerQueryResult.bFinished = Result.bFinished
  self.PlayerQueryResult.bSuccess = Result.bSuccess
  for idx = 1, Result.AbsoluteResultLocations:Num() do
    local absLoc = Result.AbsoluteResultLocations:Get(idx)
    self.PlayerQueryResult.AbsoluteResultLocations:Add(UE4.FVector(absLoc.X, absLoc.Y, absLoc.Z))
  end
end

function BattleSpectatorOutsideRecord:FirstQueryPlayer()
  Log.Debug("BattleSpectatorOutsideRecord:FirstQueryPlayer", self:GetDebugInfo())
  if not self.runner or not UE4.UObject.IsValid(self.runner) then
    self.runner = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetEqsRunner)
  end
  local angelDiff = math.abs(self.angleScope[2] - self.angleScope[1])
  self:DoEqsQuery(self.radiusScopePlayer, angelDiff, 1, self.OnPlayerFirstQueryFinished, self.SecondQueryPlayer, self.OnQueryFailed)
end

function BattleSpectatorOutsideRecord:OnPlayerFirstQueryFinished(Result)
  if self:IsQuerySuccess(Result) then
    self:SavePlayerQueryResult(Result)
    self:DrawDebugQueryPoint(Result, true)
    self:FirstQueryEnemy()
  else
    self:SecondQueryPlayer()
  end
end

function BattleSpectatorOutsideRecord:FirstQueryEnemy()
  Log.Debug("BattleSpectatorOutsideRecord:FirstQueryEnemy", self:GetDebugInfo())
  local angelDiff = math.abs(self.angleScope[2] - self.angleScope[1])
  self:DoEqsQuery(self.radiusScopeEnemy, angelDiff, 1, self.OnEnemyFirstQueryFinished, self.SecondQueryPlayer, self.OnQueryFailed)
end

function BattleSpectatorOutsideRecord:OnEnemyFirstQueryFinished(Result)
  self:DrawDebugQueryPoint(Result, false)
  if self:CheckQueryResult(self.PlayerQueryResult, Result) then
    Log.Debug("First query success", self:GetDebugInfo())
    self:OnQuerySuccess()
  else
    Log.Debug("First query failed", self:GetDebugInfo())
    self:SecondQueryPlayer()
  end
end

function BattleSpectatorOutsideRecord:SecondQueryPlayer()
  Log.Debug("BattleSpectatorOutsideRecord:SecondQueryPlayer", self:GetDebugInfo())
  self.PlayerQueryResult = nil
  self:DoEqsQuery(self.radiusScopePlayer, 359.9, -1, self.OnPlayerSecondQueryFinished, self.OnQueryFailed, self.OnQueryFailed)
end

function BattleSpectatorOutsideRecord:OnPlayerSecondQueryFinished(Result)
  if self:IsQuerySuccess(Result) then
    self:SavePlayerQueryResult(Result)
    self:DrawDebugQueryPoint(Result, true)
    self:SecondQueryEnemy()
  else
    self:OnQueryFailed()
  end
end

function BattleSpectatorOutsideRecord:SecondQueryEnemy()
  Log.Debug("BattleSpectatorOutsideRecord:SecondQueryEnemy", self:GetDebugInfo())
  self:DoEqsQuery(self.radiusScopeEnemy, 359.9, -1, self.OnEnemySecondQueryFinished, self.OnQueryFailed, self.OnQueryFailed)
end

function BattleSpectatorOutsideRecord:OnEnemySecondQueryFinished(Result)
  self:DrawDebugQueryPoint(Result, false)
  if self:CheckQueryResult(self.PlayerQueryResult, Result) then
    Log.Debug("Second query success", self:GetDebugInfo())
    self.PlayerQueryResult = nil
    self:OnQuerySuccess()
  else
    self:OnQueryFailed()
  end
end

function BattleSpectatorOutsideRecord:OnQueryFailed()
  Log.Debug("BattleSpectatorOutsideRecord:OnQueryFailed", self:GetDebugInfo())
  self.querySuccess = false
  self.PlayerQueryResult = nil
  self:JustPlayerPerform()
end

function BattleSpectatorOutsideRecord:OnQuerySuccess()
  Log.Debug("BattleSpectatorOutsideRecord:OnQuerySuccess", self:GetDebugInfo())
  self.querySuccess = true
  self.PlayerQueryResult = nil
  self:LoadResource()
end

function BattleSpectatorOutsideRecord:IsQuerySuccess(Result)
  if not Result then
    return false
  end
  if not Result.bFinished or not Result.bSuccess then
    return false
  end
  local len = Result.AbsoluteResultLocations:Num()
  if len <= 0 then
    return false
  end
  return true
end

function BattleSpectatorOutsideRecord:CheckQueryResult(PlayerResult, EnemyResult)
  if not PlayerResult or not EnemyResult then
    return false
  end
  if not self:GetPetInfoValid() then
    return false
  end
  local playerLen = PlayerResult.AbsoluteResultLocations:Num()
  local enemyLen = EnemyResult.AbsoluteResultLocations:Num()
  local bDrawDebug = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug)
  local actorsToIgnore = {}
  local objectTypes = {
    UE4.ECollisionChannel.ECC_WorldStatic,
    UE4.ECollisionChannel.ECC_WorldDynamic
  }
  local delta = UE4.FVector(0, 0, 40)
  local drawDebugType = UE4.EDrawDebugTrace.None
  local traceColor, traceHitColor, drawTime
  if bDrawDebug then
    drawDebugType = UE4.EDrawDebugTrace.ForDuration
    traceColor = UE4.FLinearColor(0.6, 1, 0, 1)
    traceHitColor = UE4.FLinearColor(0.2, 0.7, 0.2, 1)
    drawTime = 30.0
  end
  for idxA = 1, playerLen do
    local locationA = PlayerResult.AbsoluteResultLocations:Get(idxA)
    for idxB = 1, enemyLen do
      local locationB = EnemyResult.AbsoluteResultLocations:Get(idxB)
      local distance = locationA:Dist(locationB)
      if distance < WaterPlatformRadius then
      elseif math.abs(locationA.Z - locationB.Z) > self.maxHeightGap then
      else
        local hitResults, bSuccess = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), locationA + delta, locationB + delta, objectTypes, false, actorsToIgnore, drawDebugType, nil, true, traceColor, traceHitColor, drawTime)
        if bSuccess and hitResults then
          do
            local function checkHitResult(hitResult)
              local actor = hitResult.Actor
              
              local comp = hitResult.Component
              if not actor or not comp then
                return false
              end
              if actor == self.battleScope then
                return false
              end
              if actor:ActorHasTag(BattleCenterActorTag) then
                return true
              end
              local collisionEnabled = comp:GetCollisionEnabled()
              if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
                return false
              end
              for _, channel in pairs(objectTypes) do
                if comp:GetCollisionResponseToChannel(channel) == UE4.ECollisionResponse.ECR_Block then
                  return true
                end
              end
              return false
            end
            
            for _, hitResult in tpairs(hitResults) do
              if checkHitResult(hitResult) then
                if bDrawDebug then
                  UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 0.2, 0, 0.8), drawTime)
                end
                goto lbl_190
              end
            end
          end
        end
        self.pointA = UE4.FVector(locationA.X, locationA.Y, locationA.Z)
        self.pointB = UE4.FVector(locationB.X, locationB.Y, locationB.Z)
        Log.Debug("BattleSpectatorOutsideRecord:CheckQueryResult check end", idxA, idxB, locationA, locationB)
        break
      end
      ::lbl_190::
    end
    if self.pointA and self.pointB then
      self.surfaceAIsWater = self:CheckSurfaceType(self.player.viewObj, self.pointA, self.surfaceAIsWater)
      self.surfaceBIsWater = self:CheckSurfaceType(self.player.viewObj, self.pointB, self.surfaceBIsWater)
      self.petInfoA:CheckPetHabit()
      self.petInfoB:CheckPetHabit()
      break
    end
  end
  if self.pointA and self.pointB then
    return true
  end
  return false
end

function BattleSpectatorOutsideRecord:DrawDebugQueryPoint(Result, bPlayer)
  local bDrawDebug = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug)
  if not bDrawDebug then
    return
  end
  local duration = 30
  local len = Result.AbsoluteResultLocations:Num()
  for idx = 1, len do
    local score = -1
    local location = Result.AbsoluteResultLocations:Get(idx)
    local isValid = Result.ItemSuccess:Get(idx)
    local failedDesc = Result.FailedTestDescriptions:Get(idx)
    local color
    if bPlayer then
      color = isValid and UE4.FLinearColor(0, 1, 0, 0.5) or UE4.FLinearColor(1, 0, 0, 0.3)
    else
      color = isValid and UE4.FLinearColor(0, 0.6, 0.3, 0.5) or UE4.FLinearColor(0.6, 0, 0.3, 0.3)
    end
    score = Result.Scores and Result.Scores:Get(idx) or -1
    local desc = string.format("%f", score)
    if "" ~= failedDesc then
      desc = failedDesc
    end
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), location, 25, 12, color, duration, 2)
    UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), location + UE4.FVector(0, 0, 20), string.format("%d: %f", idx, score), nil, UE4.FLinearColor(0, 0, 1, 1), duration)
  end
end

function BattleSpectatorOutsideRecord:LoadResource()
  if not self.petInfoA or not self.petInfoB then
    return
  end
  if not self.loadQueue then
    self.loadQueue = ResQueue()
  end
  if self.loadFinished then
    self.loadQueue:Release()
  end
  self.loadFinished = false
  if self.bSelfInBattle then
    self.bHasDisapperSkill = false
  elseif self:IsNpcPet(self.npc) then
    self.bHasDisapperSkill = true
  else
    self.bHasDisapperSkill = false
  end
  local distance = self.pointB - self.pointA
  local dirA = distance:ToRotator()
  local dirB = (-distance):ToRotator()
  self.loadQueue:InsertNPC("PetA", self.petInfoA:GetNpcConfId(), SceneUtils.ConvertVectorToPoint(self.pointA).pos, dirA.Yaw * 10, nil, _G.PriorityEnum.Passive_Battle_OutsidePerform)
  self.loadQueue:InsertNPC("PetB", self.petInfoB:GetNpcConfId(), SceneUtils.ConvertVectorToPoint(self.pointB).pos, dirB.Yaw * 10, nil, _G.PriorityEnum.Passive_Battle_OutsidePerform)
  self.loadQueue:StartLoad(self, self.OnLoadFinished)
  self.petInfoA:InitPet(self.loadQueue:Get("PetA"), self.pointA, true)
  self.petInfoB:InitPet(self.loadQueue:Get("PetB"), self.pointB, false)
  local batterCenterPoint = (self.pointA + self.pointB) / 2
  if not self.battleScope or not UE4.UObject.IsValid(self.battleScope) then
    self.battleScope = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ATriggerBox, UE4.FTransform(dirA:ToQuat(), batterCenterPoint, _G.FVectorOne), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if self.battleScope and UE4.UObject.IsValid(self.battleScope) then
      self.battleScope.Tags:Add(BattleCenterActorTag)
      local box = self.battleScope.CollisionComponent
      if box and UE4.UObject.IsValid(box) then
        box:SetBoxExtent(UE4.FVector(distance:Size() / 2 + 30, 60, 60))
        box:SetCollisionResponseToChannel(UE4.ECollisionChannel.ECC_GameTraceChannel9, UE4.ECollisionResponse.ECR_Ignore)
        if _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug) then
          self.battleScope:SetActorHiddenInGame(false)
          box.ShapeColor = UE4.FLinearColor(100, 20, 200, 200)
          box.LineThickness = 1
        end
      end
    end
  end
end

function BattleSpectatorOutsideRecord:OnLoadFinished(Queue, Success)
  self.loadFinished = Success
  if not Success then
    self:ClearPetInfo()
    self:BeginPerform()
    return
  end
  self:PreparePerform()
end

function BattleSpectatorOutsideRecord:GetRocoSkillComp(viewObj)
  if not viewObj or not UE4.UObject.IsValid(viewObj) then
    return nil
  end
  local skillComp = viewObj.RocoSkill
  if not skillComp then
    skillComp = viewObj:GetComponentByClass(UE4.URocoSkillComponent)
    skillComp = skillComp or viewObj:AddComponentByClass(UE4.URocoSkillComponent, false, UE4.FTransform(), false)
    viewObj.RocoSkill = skillComp
  end
  return skillComp
end

function BattleSpectatorOutsideRecord:PreparePerform()
  if self.surfaceAIsWater or self.surfaceBIsWater then
    local waterPlatformClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetWaterPlatformClass)
    self.petInfoA:GenerateWaterPlatform(waterPlatformClass, self.surfaceAIsWater, self.pointA)
    self.petInfoB:GenerateWaterPlatform(waterPlatformClass, self.surfaceBIsWater, self.pointB)
  end
  if self.bHasDisapperSkill then
    if self.npc.viewObj then
      self:NpcPlayDisapper()
    else
      self.npc:AddEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnNpcViewShellLoaded)
    end
    return
  end
  self:BeginPerform()
end

function BattleSpectatorOutsideRecord:OnNpcViewShellLoaded()
  Log.Debug("BattleSpectatorOutsideRecord:OnNpcViewShellLoaded")
  self.npc:RemoveEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnNpcViewShellLoaded)
  self:NpcPlayDisapper()
end

function BattleSpectatorOutsideRecord:NpcPlayDisapper()
  self.npcCachedTransform = self.npc:GetActorTransform()
  self:NpcPlayDisapperSkill(self.npc)
end

function BattleSpectatorOutsideRecord:NpcPlayDisapperSkill(npc)
  if not npc then
    Log.Debug("BattleSpectatorOutsideRecord:NpcPlayDisapperSkill not npc")
    return
  end
  local viewObj = npc.viewObj
  local skillComp = self:GetRocoSkillComp(viewObj)
  if not skillComp then
    Log.Warning("npc has no skill component", self:GetDebugInfo())
    self:BeginPerform()
    return
  end
  
  local function onSkillEnd(name, skill)
    if self and self.loadQueue then
      self:BeginPerform()
    end
  end
  
  local skillClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetNpcDisapperSkillClass)
  if not skillClass then
    Log.Warning("disapper skill class is nil", self:GetDebugInfo())
    self:BeginPerform()
    return
  end
  local skill = skillComp:FindOrAddSkillObj(skillClass)
  if not skill then
    Log.Warning("disapper skill is nil", self:GetDebugInfo())
    self:BeginPerform()
    return
  end
  skill:SetCaster(viewObj)
  skill:RegisterEventCallback("End", self, onSkillEnd)
  skillComp:StopCurrentSkill()
  skillComp:LoadAndPlaySkill(skill)
  Log.Debug("BattleSpectatorOutsideRecord:NpcPlayDisapperSkill", npc:DebugNPCNameAndID(), npc)
end

function BattleSpectatorOutsideRecord:PlayerPlaySkill(skillClass, caller, callback)
  if not skillClass then
    Log.Warning("BattleSpectatorOutsideRecord:PlayerPlaySkill skillClass is nil", self:GetDebugInfo())
    if caller and callback then
      callback(caller)
    end
    return
  end
  local player = self.player
  if not player then
    Log.Warning("BattleSpectatorOutsideRecord:PlayerPlaySkill player is nil", self:GetDebugInfo())
    if caller and callback then
      callback(caller)
    end
    return
  end
  local playerViewObj = player.viewObj
  local playerSkillComp = self:GetRocoSkillComp(playerViewObj)
  if not playerSkillComp then
    Log.Warning("player has no skill component", self:GetDebugInfo())
    if caller and callback then
      callback(caller)
    end
    return
  end
  if self.playerCurrentSkill and playerSkillComp:IsSkillLoading(self.playerCurrentSkill) then
    Log.Debug("BattleSpectatorOutsideRecord:PlayerPlaySkill IsSkillLoading", self:GetDebugInfo(), self.playerCurrentSkill:GetDisplayName())
    playerSkillComp:CancelSkill(self.playerCurrentSkill, UE4.ESkillActionResult.SkillActionResultDestruct)
  end
  local skill = playerSkillComp:FindOrAddSkillObj(skillClass)
  if not skill then
    Log.Warning("BattleSpectatorOutsideRecord:PlayerPlaySkill skill not found", self:GetDebugInfo())
    if caller and callback then
      callback(caller)
    end
    return
  end
  local characters = {}
  local bForbidPerform = false
  for _, status in pairs(PlayerForbidPerformStatus) do
    if player.statusComponent:HasStatus(status) then
      bForbidPerform = true
      Log.Debug("BattleSpectatorOutsideRecord:PlayerPlaySkill player cannot perform with status", self:GetDebugInfo(), status)
      break
    end
  end
  if not bForbidPerform then
    characters[UE4.EBattleStaticActorType.Player_1] = playerViewObj
  end
  local bNoPets = true
  if self.petInfoA then
    if self.petInfoA.pet then
      characters[UE4.EBattleStaticActorType.Pet_1_1] = self.petInfoA.pet.viewObj
      bNoPets = false
    end
    if self.petInfoA.petData then
      local ballId = self.petInfoA.petData.ball_id
      if ballId then
        local ballPath = _G.BattleUtils.GetPetBallPath({ball_id = ballId})
        skill:SetDynamicData({BallPath = ballPath})
      end
    end
  end
  if self.petInfoB and self.petInfoB.pet then
    characters[UE4.EBattleStaticActorType.Pet_2_1] = self.petInfoB.pet.viewObj
    bNoPets = false
  end
  if bNoPets and bForbidPerform then
    Log.Debug("BattleSpectatorOutsideRecord:PlayerPlaySkill no characters", self:GetDebugInfo())
    if caller and callback then
      callback(caller)
    end
    return
  end
  skill:SetCharacters(characters)
  skill:SetCaster(playerViewObj)
  skill:SetTargets({playerViewObj})
  if bNoPets then
    self:TryDisablePetRelatedAction(skill)
  end
  if self.battleScope and self.battlePoints then
    if not self.battleConf or not UE4.UObject.IsValid(self.battleConf) then
      self.battleConf = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ABattleFieldConf, UE4.FTransform(UE4.FQuat(0, 0, 0, 1), self.battleScope:Abs_K2_GetActorLocation(), _G.FVectorOne), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    end
    if self.battleConf and UE4.UObject.IsValid(self.battleConf) then
      self.battleConf.BattleFieldAttachPointMap:Clear()
      for type, actor in pairs(self.battlePoints) do
        self.battleConf.BattleFieldAttachPointMap:Add(type, actor)
      end
      skill.BattleFieldConf = self.battleConf
    end
  end
  if playerSkillComp:GetActiveSkill() == skill then
    Log.Debug("BattleSpectatorOutsideRecord:PlayerPlaySkill playerCurrentSkill is playing", self:GetDebugInfo())
    return
  end
  if caller and callback then
    skill:RegisterEventCallback("End", caller, callback)
  end
  self.playerCurrentSkill = skill
  playerSkillComp:LoadAndPlaySkill(skill)
end

function BattleSpectatorOutsideRecord:TryDisablePetRelatedAction(skill)
  if not skill then
    return
  end
  local actions = skill:GetAllActions()
  local actionNum = actions:Length()
  for i = 1, actionNum do
    local action = actions:Get(i)
    if action:IsA(UE.URocoPlayFxSystemAction) then
      if action.AttachSetting.TargetActorInfo.ActorType == UE4.ERocoSkillActorType.StaticPos then
        action.m_Enable = false
        Log.Debug("BattleSpectatorOutsideRecord:TryDisablePetRelatedAction URocoPlayFxSystemAction StaticPos", self:GetDebugInfo(), skill:GetDisplayName(), action.GUID)
      end
      if action.AttachSetting.TargetActorInfo.ActorType == UE4.ERocoSkillActorType.StaticCharacter then
        local actorType = action.AttachSetting.TargetActorInfo.CharacterActorType
        if actorType == UE4.EBattleStaticActorType.Pet_1_1 or actorType == UE4.EBattleStaticActorType.Pet_2_1 then
          action.m_Enable = false
          Log.Debug("BattleSpectatorOutsideRecord:TryDisablePetRelatedAction URocoPlayFxSystemAction StaticCharacter", self:GetDebugInfo(), skill:GetDisplayName(), action.GUID)
        end
      end
    end
  end
end

function BattleSpectatorOutsideRecord:BeginPerform()
  Log.Debug("BattleSpectatorOutsideRecord:BeginPerform", self:GetDebugInfo())
  if self:IsNpcPet(self.npc) and not self.bSelfInBattle then
    self.npc:SetVisibleForBattleOutsideReason(false)
  end
  if self.petInfoA then
    if not self.bSelfInBattle then
      self.petInfoA:SetOwner(self.player.viewObj)
    end
    self.petInfoA:ReadyForPreform(self.bSelfInBattle, self.surfaceAIsWater)
    if self.pointA then
      self.playerInitRotator = self.player:GetActorRotation()
      local direction = self.pointA - self.player:GetActorLocation()
      local rotator = direction:ToRotator()
      rotator.Pitch = 0
      rotator.Roll = 0
      self.player:SetActorRotation(rotator)
    end
  end
  if self.petInfoB then
    if not self.bSelfInBattle then
      self.petInfoB:SetOwner(self.player.viewObj)
    end
    self.petInfoB:ReadyForPreform(self.bSelfInBattle, self.surfaceBIsWater)
  end
  local playerViewObj = self.player.viewObj
  if playerViewObj then
    self:OnPlayerVisibleChange(not playerViewObj.bHiddenEd)
  end
  if self.querySuccess then
    local battlePointClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetBattlePointClass)
    if battlePointClass and self.battleScope and self.petInfoA and self.petInfoB and self.petInfoA.finalPosition and self.petInfoB.finalPosition then
      if not self.battlePoints then
        self.battlePoints = {}
      end
      local petALoc = self.petInfoA.finalPosition
      local petBLoc = self.petInfoB.finalPosition
      local center = (petALoc + petBLoc) / 2
      center.Z = math.max(petALoc.Z, petBLoc.Z)
      local pointsIno = {}
      pointsIno[UE4.EBattleFieldAttachPoint.Pos_1V1PlayerPet1] = petALoc
      pointsIno[UE4.EBattleFieldAttachPoint.Pos_1v1EnemyPet1] = petBLoc
      pointsIno[UE4.EBattleFieldAttachPoint.Center] = center
      for type, loc in pairs(pointsIno) do
        local actor = self.battlePoints[type]
        if actor and UE4.UObject.IsValid(actor) then
          actor:Abs_K2_SetActorLocation(loc, false, nil, false)
        else
          self.battlePoints[type] = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(battlePointClass, UE4.FTransform(UE4.FQuat(0, 0, 0, 1), loc, _G.FVectorOne), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        end
      end
      local bDrawDebug = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug)
      for _, actor in pairs(self.battlePoints) do
        if self.bSelfInBattle then
          actor:SetActorHiddenInGame(true)
        else
          UE4.UNRCStatics.SetActorOwner(actor, self.player.viewObj)
        end
        if bDrawDebug then
          UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), actor:K2_GetActorLocation(), 25, 12, UE4.FLinearColor(1, 0.2, 0.1, 1), 30.0, 2)
        end
      end
    end
  end
  local skillClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformSkillClass)
  self:PlayerPlaySkill(skillClass)
  if self.playerCurrentSkill then
    self.playerCurrentSkill:RegisterEventCallback("RoundOver", self, self.OnRoundOver)
    self.playerCurrentSkill:RegisterEventCallback("HitCenter", self, self.OnPetHitTogether)
  end
end

function BattleSpectatorOutsideRecord:OnDestroyed(bImmediate)
  if self.player and self.player:HasListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange) then
    self.player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
  end
  if self.runner and UE4.UObject.IsValid(self.runner) then
    if self.queryId then
      self.runner:RemoveRequest(self.queryId)
    end
    UE4.UObject.Release(self.runner)
    self.runner = nil
  end
  if self.loadQueue then
    self.loadQueue:Release()
    self.loadQueue = nil
  end
  if self.petInfoAToReplace then
    self.petInfoAToReplace:OnDestroyed()
    self.petInfoAToReplace = nil
  end
  if self.resPetAToReplace then
    self.resPetAToReplace:Release()
    self.resPetAToReplace = nil
  end
  if self.petInfoBToReplace then
    self.petInfoBToReplace:OnDestroyed()
    self.petInfoBToReplace = nil
  end
  if self.resPetBToReplace then
    self.resPetBToReplace:Release()
    self.resPetBToReplace = nil
  end
  self.bDestroying = true
  Log.Debug("BattleSpectatorOutsideRecord:OnDestroyed", self:GetDebugInfo(), bImmediate)
  self:ForceCancelSkill(self.player, _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformSkillClass))
  local viewObj = self.npc and self.npc.viewObj
  self:ForceCancelSkill(self.npc, _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetNpcDisapperSkillClass))
  if viewObj and UE4.UObject.IsValid(viewObj) and self.npcCachedTransform then
    viewObj:Abs_K2_SetActorTransform(self.npcCachedTransform, false, nil, false)
  end
  if bImmediate then
    self:OnEndSkillComplete()
  else
    local skillClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformEndSkillClass)
    self:PlayerPlaySkill(skillClass, self, self.OnEndSkillComplete)
    if self.petInfoA then
      self.petInfoA:ResetPetLocation()
      self.petInfoA:TryClearExceptPet()
    end
    if self.petInfoB then
      self:NpcPlayDisapperSkill(self.petInfoB.pet)
      self.petInfoB:ResetPetLocation()
      self.petInfoB:TryClearExceptPet()
    end
    self.endPerformLoadTimeoutDelayHandler = _G.DelayManager:DelaySeconds(EndPerformLoadTimeout, function()
      if not self then
        return
      end
      self:CheckEndSkillLoadTimeout()
    end)
    self.tickedTime = 0
    self.tickedInterval = 0.1
    _G.UpdateManager:Register(self)
  end
end

function BattleSpectatorOutsideRecord:OnEndSkillComplete(name, skill)
  Log.Debug("BattleSpectatorOutsideRecord:OnEndSkillComplete", self:GetDebugInfo())
  _G.UpdateManager:UnRegister(self)
  if self:IsNpcPet(self.npc) then
    if not self.npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
      self.npc:SetVisibleForBattleOutsideReason(true)
      Log.Debug("BattleSpectatorOutsideRecord:OnEndSkillComplete npc leave battle", self:GetDebugInfo())
    else
      _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.TryKeepWatchNpcIfPlayerLogOut, self)
    end
  end
  self:ClearPetInfo()
  self:TryRecoverOtherEnemyPets()
  self.playerCurrentSkill = nil
  self.npcCachedTransform = nil
  if self.endPerformLoadTimeoutDelayHandler then
    _G.DelayManager:CancelDelayById(self.endPerformLoadTimeoutDelayHandler)
    self.endPerformLoadTimeoutDelayHandler = nil
  end
  self:ForceStopPlayerAnim({
    "Command",
    "Stand",
    "CallBack"
  })
  _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.RemoveRecord, self)
end

function BattleSpectatorOutsideRecord:CheckEndSkillLoadTimeout()
  self:ForceCancelSkill(self.player, _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformSkillClass))
  self:ForceStopPlayerAnim({"Command", "Stand"})
  if not self.player then
    return
  end
  local playerViewObj = self.player.viewObj
  local playerSkillComp = self:GetRocoSkillComp(playerViewObj)
  if not playerSkillComp then
    return
  end
  if not self.playerCurrentSkill then
    return
  end
  if playerSkillComp:IsSkillLoading(self.playerCurrentSkill) then
    Log.Debug("BattleSpectatorOutsideRecord:CheckEndSkillLoadTimeout", self:GetDebugInfo())
    playerSkillComp:CancelSkill(self.playerCurrentSkill, UE4.ESkillActionResult.SkillActionResultDestruct)
    self.endPerformLoadTimeoutDelayHandler = nil
    self:OnEndSkillComplete()
  end
end

function BattleSpectatorOutsideRecord:ForceStopEndPerform()
  self:ForceCancelSkill(self.player, _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformEndSkillClass))
  self:ForceStopPlayerAnim({
    "Command",
    "Stand",
    "CallBack"
  })
end

function BattleSpectatorOutsideRecord:ForceCancelSkill(character, skillClass)
  if not character or not skillClass then
    return
  end
  local viewObj = character.viewObj
  local skillComp = self:GetRocoSkillComp(viewObj)
  if not skillComp then
    return
  end
  local skill = skillComp:FindSkillObj(skillClass)
  if not skill then
    return
  end
  Log.Debug("BattleSpectatorOutsideRecord:ForceCancelSkill", self:GetDebugInfo(), character:GetServerId(), skill:GetDisplayName())
  skillComp:CancelSkill(skill, UE4.ESkillActionResult.SkillActionResultDestruct)
  skillComp:RemoveSkillObj(skill)
end

function BattleSpectatorOutsideRecord:ForceStopPlayerAnim(animNames)
  local player = self.player
  if player and animNames then
    for _, animName in ipairs(animNames) do
      player:StopAnim(animName, 0.1)
    end
  end
end

function BattleSpectatorOutsideRecord:ClearPetInfo()
  Log.Debug("BattleSpectatorOutsideRecord:ClearPetInfo", self:GetDebugInfo())
  self.playerCurrentSkill = nil
  if self.petInfoA then
    self.petInfoA:OnDestroyed()
    self.petInfoA = nil
  end
  if self.petInfoB then
    self.petInfoB:OnDestroyed()
    self.petInfoB = nil
  end
  if self.battleConf and UE4.UObject.IsValid(self.battleConf) then
    self.battleConf:K2_DestroyActor()
    self.battleConf = nil
  end
  if self.battlePoints then
    for _, actor in pairs(self.battlePoints) do
      if UE4.UObject.IsValid(actor) then
        actor:K2_DestroyActor()
      end
    end
    table.clear(self.battlePoints)
    self.battlePoints = nil
  end
  if self.battleScope and UE4.UObject.IsValid(self.battleScope) then
    self.battleScope:K2_DestroyActor()
    self.battleScope = nil
  end
end

function BattleSpectatorOutsideRecord:JustPlayerPerform()
  self.bHasDisapperSkill = false
  self.playerCurrentSkill = nil
  self:PreparePerform()
end

function BattleSpectatorOutsideRecord:OnReconnect(petA, petB)
  Log.Debug("BattleSpectatorOutsideRecord:OnReconnect", self:GetDebugInfo())
  local bNeedUpdate = false
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, self.playerId)
  if player and player ~= self.player then
    self.player = player
    player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
    Log.Debug("BattleSpectatorOutsideRecord:OnReconnect update player", self:GetDebugInfo())
    bNeedUpdate = true
  end
  local npc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.npcId)
  if npc and npc ~= self.npc then
    self.npc = npc
    Log.Debug("BattleSpectatorOutsideRecord:OnReconnect update npc", self:GetDebugInfo())
    bNeedUpdate = true
  end
  if self.petInfoAToReplace then
    Log.Debug("BattleSpectatorOutsideRecord:OnReconnect pet a is switching", self:GetDebugInfo())
    self.petInfoA:UpdatePetData(self.petInfoAToReplace.petData)
    self.petInfoA:CheckPetHabit()
    self.petInfoAToReplace:OnDestroyed()
    self.petInfoAToReplace = nil
    bNeedUpdate = true
  end
  if self.resPetAToReplace then
    self.resPetAToReplace:Release()
    self.resPetAToReplace = nil
  end
  if self.petInfoBToReplace then
    Log.Debug("BattleSpectatorOutsideRecord:OnReconnect pet b is switching", self:GetDebugInfo())
    self.petInfoB:UpdatePetData(self.petInfoBToReplace.petData)
    self.petInfoB:CheckPetHabit()
    self.petInfoBToReplace:OnDestroyed()
    self.petInfoBToReplace = nil
    bNeedUpdate = true
  end
  if self.resPetBToReplace then
    self.resPetBToReplace:Release()
    self.resPetBToReplace = nil
  end
  if petA and self.petInfoA then
    self.petInfoA.bAlreadyPrepared = false
    self.petInfoA:UpdatePetData(petA)
    self.petInfoA:CheckPetHabit()
    bNeedUpdate = true
  end
  if petB and self.petInfoB then
    self.petInfoB.bAlreadyPrepared = false
    self.petInfoB:UpdatePetData(petB)
    self.petInfoB:CheckPetHabit()
    bNeedUpdate = true
  end
  if not bNeedUpdate then
    return
  end
  if not self.player.viewObj then
    self.player:AddEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnPlayerViewShellLoadedForReconnect)
    return
  end
  self:RecoverForReconnect()
end

function BattleSpectatorOutsideRecord:OnPlayerViewShellLoadedForReconnect()
  self.player:RemoveEventListener(NPCModuleEvent.VIEW_SHELL_LOADED, self, self.OnPlayerViewShellLoadedForReconnect)
  self:RecoverForReconnect()
end

function BattleSpectatorOutsideRecord:RecoverForReconnect()
  Log.Debug("BattleSpectatorOutsideRecord:RecoverForReconnect", self:GetDebugInfo())
  if self.petInfoA then
    self.petInfoA:OnReconnect()
  end
  if self.petInfoB then
    self.petInfoB:OnReconnect()
  end
  if self.querySuccess then
    self:LoadResource()
  else
    self:JustPlayerPerform()
  end
end

function BattleSpectatorOutsideRecord:OnLeaveBattle()
  Log.Debug("BattleSpectatorOutsideRecord:OnLeaveBattle", self:GetDebugInfo(), self.bSelfInBattle)
  if self.bSelfInBattle then
    if self:IsNpcPet(self.npc) and self.npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
      self.npc:SetVisibleForBattleOutsideReason(false)
    end
    local playerViewObj = self.player.viewObj
    if self.petInfoA then
      self.petInfoA:OnLeaveBattle(playerViewObj)
    end
    if self.petInfoB then
      self.petInfoB:OnLeaveBattle(playerViewObj)
    end
    if self.battlePoints then
      for _, actor in pairs(self.battlePoints) do
        UE4.UNRCStatics.SetActorOwner(actor, playerViewObj)
      end
    end
    self.bSelfInBattle = false
  end
end

function BattleSpectatorOutsideRecord:CheckOnNpcCreate(createdNpc)
  if not createdNpc then
    return
  end
  if not self:IsNpcPet(createdNpc) then
    return
  end
  local id = createdNpc:GetServerId()
  if id == self.npcId then
    if self.npc ~= createdNpc then
      self.npc = createdNpc
      self:UpdateNpcVisibleOnCreate(createdNpc)
      Log.Debug("BattleSpectatorOutsideRecord:CheckOnNpcCreate npc updated", self:GetDebugInfo())
    else
      Log.Debug("BattleSpectatorOutsideRecord:CheckOnNpcCreate not changed", self:GetDebugInfo())
    end
  end
  if self.otherEnemyPetsId and self.otherEnemyPets then
    for _, petId in ipairs(self.otherEnemyPetsId) do
      if petId == id then
        local otherNpc = self.otherEnemyPets[id]
        if otherNpc ~= createdNpc then
          self.otherEnemyPets[id] = createdNpc
          self:UpdateNpcVisibleOnCreate(createdNpc)
          Log.Debug("BattleSpectatorOutsideRecord:CheckOnNpcCreate other npc updated", self:GetDebugInfo(), createdNpc:DebugNPCNameAndID())
          break
        end
      end
    end
  end
end

function BattleSpectatorOutsideRecord:UpdateNpcVisibleOnCreate(npc)
  if self.bSelfInBattle then
    Log.Debug("BattleSpectatorOutsideRecord:UpdateNpcVisibleOnCreate self in battle", self:GetDebugInfo(), npc:DebugNPCNameAndID())
  else
    npc:SetVisibleForBattleOutsideReason(false)
  end
end

function BattleSpectatorOutsideRecord:CheckSurfaceType(querier, location, inSurfaceType)
  if nil ~= inSurfaceType then
    return inSurfaceType
  end
  if nil == location then
    return
  end
  local world = _G.UE4Helper.GetCurrentWorld()
  local offsetX = world:GetWorldOriginX()
  local offsetY = world:GetWorldOriginY()
  local offsetZ = world:GetWorldOriginZ()
  local relativePoint = UE4.FVector(location.X - offsetX, location.Y - offsetY, location.Z - offsetZ)
  local waterNum = 0
  local bCanDrawDebug = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug)
  local centerSurfaceType = UE4.UNRCStatics.CheckSurfaceTypeAtLocation(querier, relativePoint, 100)
  for idx = 1, waterSurfaceCheckNum do
    local angle = idx * waterSurfaceCheckAngleEach
    local radian = angle * math.pi / 180
    local point = UE4.FVector(relativePoint.X + waterSurfaceCheckRadius * math.cos(radian), relativePoint.Y + waterSurfaceCheckRadius * math.sin(radian), relativePoint.Z)
    local surfaceType = UE4.UNRCStatics.CheckSurfaceTypeAtLocation(querier, point, 100)
    if 2 == surfaceType then
      waterNum = waterNum + 1
      if bCanDrawDebug then
        UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), point, 15, 12, UE4.FLinearColor(0.3, 0.2, 0.7, 0.8), 30, 2)
      end
    elseif bCanDrawDebug then
      UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), point, 15, 12, UE4.FLinearColor(0.3, 0.7, 0.2, 0.8), 30, 2)
    end
  end
  if waterNum >= waterSurfaceCheckNum and 2 == centerSurfaceType then
    return true
  else
    return false
  end
end

function BattleSpectatorOutsideRecord:IsReplaceLoaded()
  if not self.petInfoAToReplace and not self.petInfoBToReplace then
    return false
  end
  if self.petInfoAToReplace and not self.petAReplaceLoaded then
    return false
  end
  if self.petInfoBToReplace and not self.petBReplaceLoaded then
    return false
  end
  return true
end

function BattleSpectatorOutsideRecord:OnPetHitTogether()
  if not self:IsReplaceLoaded() then
    return
  end
  Log.Debug("BattleSpectatorOutsideRecord:OnPetHitTogether", self:GetDebugInfo())
  if self.petInfoAToReplace then
    if self.petInfoA then
      self.petInfoA:OnDestroyed()
    end
    self.petInfoA = self.petInfoAToReplace
    self.petInfoA:CheckPetHabit()
    self.petInfoAToReplace = nil
    if self.resPetAToReplace then
      self.resPetAToReplace:Release()
      self.resPetAToReplace = nil
    end
    self.petAReplaceLoaded = nil
  end
  if self.petInfoBToReplace then
    if self.petInfoB then
      self.petInfoB:OnDestroyed()
    end
    self.petInfoB = self.petInfoBToReplace
    self.petInfoB:CheckPetHabit()
    self.petInfoBToReplace = nil
    if self.resPetBToReplace then
      self.resPetBToReplace:Release()
      self.resPetBToReplace = nil
    end
    self.petBReplaceLoaded = nil
  end
  self.bNewRoundBegin = true
end

function BattleSpectatorOutsideRecord:OnRoundOver()
  if not self.bNewRoundBegin then
    return
  end
  self.bNewRoundBegin = nil
  if self.surfaceAIsWater or self.surfaceBIsWater then
    local waterPlatformClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetWaterPlatformClass)
    if self.petInfoA then
      self.petInfoA:GenerateWaterPlatform(waterPlatformClass, self.surfaceAIsWater, self.pointA)
    end
    if self.petInfoB then
      self.petInfoB:GenerateWaterPlatform(waterPlatformClass, self.surfaceBIsWater, self.pointB)
    end
  end
  self:BeginPerform()
end

function BattleSpectatorOutsideRecord:SwitchPet(petDisplay, bIsPlayer)
  local distance = UE4.FVector(0, 0, 0)
  if self.pointA and self.pointB then
    distance = self.pointB - self.pointA
  end
  if bIsPlayer then
    if not self.petInfoA or not self.petInfoA:IsValid() then
      return
    end
    if self.resPetAToReplace then
      self.resPetAToReplace:Release()
      self.resPetAToReplace = nil
    end
    if self.petInfoAToReplace then
      self.petInfoAToReplace:OnDestroyed()
      self.petInfoAToReplace = nil
    end
    local petInfo = BattleSpectatorOutsidePetInfo(petDisplay)
    if not petInfo:IsValid() then
      return
    end
    self.petInfoAToReplace = petInfo
    local dirA = distance:ToRotator()
    self.resPetAToReplace = NPCResObject.MakeNPC(petInfo:GetNpcConfId(), SceneUtils.ConvertVectorToPoint(self.pointA).pos, dirA.Yaw * 10, nil, _G.PriorityEnum.Passive_Battle_OutsidePerform)
    self.petInfoAToReplace:InitPet(self.resPetAToReplace:Get(), self.pointA, true)
    self.resPetAToReplace:StartLoad(self, self.OnPetAReplaceLoaded)
  else
    if not self.petInfoB or not self.petInfoB:IsValid() then
      return
    end
    if self.resPetBToReplace then
      self.resPetBToReplace:Release()
      self.resPetBToReplace = nil
    end
    if self.petInfoBToReplace then
      self.petInfoBToReplace:OnDestroyed()
      self.petInfoBToReplace = nil
    end
    local petInfo = BattleSpectatorOutsidePetInfo(petDisplay)
    if not petInfo:IsValid() then
      return
    end
    self.petInfoBToReplace = petInfo
    local dirB = (-distance):ToRotator()
    self.resPetBToReplace = NPCResObject.MakeNPC(petInfo:GetNpcConfId(), SceneUtils.ConvertVectorToPoint(self.pointB).pos, dirB.Yaw * 10, nil, _G.PriorityEnum.Passive_Battle_OutsidePerform)
    self.petInfoBToReplace:InitPet(self.resPetBToReplace:Get(), self.pointB, true)
    self.resPetBToReplace:StartLoad(self, self.OnPetBReplaceLoaded)
  end
end

function BattleSpectatorOutsideRecord:OnPetAReplaceLoaded()
  self.petAReplaceLoaded = true
  Log.Debug("BattleSpectatorOutsideRecord:OnPetAReplaceLoaded", self:GetDebugInfo())
end

function BattleSpectatorOutsideRecord:OnPetBReplaceLoaded()
  self.petBReplaceLoaded = true
  Log.Debug("BattleSpectatorOutsideRecord:OnPetBReplaceLoaded", self:GetDebugInfo())
end

function BattleSpectatorOutsideRecord:OnNightmareShieldBreak(newPetDisplay)
  self:ForceCancelSkill(self.player, _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetPerformSkillClass))
  if self.petInfoA then
    self.petInfoA:ResetPetLocation()
  end
  if self.petInfoB then
    self.petInfoB:ResetPetLocation()
  end
  
  local function onPlayShieldSkillFailed()
    self:UpdatePetMutation(self.petInfoB, newPetDisplay)
    self:BeginPerform()
  end
  
  local skillClass = _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetNightmareShieldBreakSkillClass)
  if not skillClass then
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak skill class is nil", self:GetDebugInfo())
    onPlayShieldSkillFailed()
    return
  end
  local pet = self.petInfoB and self.petInfoB.pet
  if not pet then
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak pet b is nil", self:GetDebugInfo())
    onPlayShieldSkillFailed()
    return
  end
  local petViewObj = pet.viewObj
  local petSkillComp = self:GetRocoSkillComp(petViewObj)
  if not petSkillComp then
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak petSkillComp is nil", self:GetDebugInfo())
    onPlayShieldSkillFailed()
    return
  end
  local skill = petSkillComp:FindOrAddSkillObj(skillClass)
  if not skill then
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak skill is nil", self:GetDebugInfo())
    return
  end
  skill:SetCaster(petViewObj)
  skill:SetTargets({petViewObj})
  
  local function onTriggerMutation()
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak onTriggerMutation", self:GetDebugInfo())
    self:UpdatePetMutation(self.petInfoB, newPetDisplay)
  end
  
  local function onMutationEnd()
    Log.Debug("BattleSpectatorOutsideRecord:OnNightmareShieldBreak onMutationEnd", self:GetDebugInfo())
    self:BeginPerform()
  end
  
  skill:RegisterEventCallback("TriggerMutationChange", self, onTriggerMutation)
  skill:RegisterEventCallback("PreEnd", self, onMutationEnd)
  petSkillComp:LoadAndPlaySkill(skill)
end

function BattleSpectatorOutsideRecord:UpdatePetMutation(petInfo, petData)
  if not petInfo or not petData then
    return
  end
  if not petInfo.pet or not petInfo.petData then
    return
  end
  local petViewObj = petInfo.pet.viewObj
  local oldMutationType = petInfo.petData.mutation_type
  if PetMutationUtils.GetMutationValue(oldMutationType, _G.Enum.MutationDiffType.MDT_CHAOS) then
    PetMutationUtils.RemoveNightmareFirstMutation(petViewObj)
  end
  if PetMutationUtils.GetMutationValue(oldMutationType, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) then
    PetMutationUtils.RemoveNightmareSecondMutation(petViewObj)
  end
  if PetMutationUtils.GetMutationValue(oldMutationType, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) then
    PetMutationUtils.RemoveNightmareByIDMask(petViewObj)
  end
  PetMutationUtils.DoMutation(petViewObj, petData)
  petInfo.petData = petData
  Log.Debug("BattleSpectatorOutsideRecord:UpdatePetMutation", self:GetDebugInfo(), oldMutationType, petData.mutation_type)
end

function BattleSpectatorOutsideRecord:OnPlayerVisibleChange(Visible)
  Log.Debug("BattleSpectatorOutsideRecord:OnPlayerVisibleChange", self:GetDebugInfo(), Visible)
  if self.petInfoA then
    self.petInfoA:OnPlayerVisibleChange(Visible)
  end
  if self.petInfoB then
    self.petInfoB:OnPlayerVisibleChange(Visible)
  end
end

function BattleSpectatorOutsideRecord:IsNpcPet(npc)
  if not npc then
    return false
  end
  if npc:IsPet() then
    return true
  end
  if npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOWBOX_ELITE) then
    return true
  elseif npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_MIDBOX_ELITE) then
    return true
  elseif npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_HIGHBOX_ELITE) then
    return true
  end
  return false
end

return BattleSpectatorOutsideRecord
