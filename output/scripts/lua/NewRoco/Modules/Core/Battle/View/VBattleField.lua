local BattlePawnManager = require("NewRoco.Modules.Core.Battle.View.BattlePawnManager")
local BattleCraneCamera = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCamera")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleFieldConst = require("NewRoco.Modules.Core.Battle.Common.BattleFieldConst")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DelaySafeCaller = require("NewRoco.Modules.Core.Battle.Common.DelaySafeCaller")
local VBattleField = {}
VBattleField.BattlePawnManager = BattlePawnManager
VBattleField.battleFieldConf = nil
VBattleField.battleCameraManager = nil
VBattleField.battleFieldActor = nil
VBattleField.panelCameraController = nil
VBattleField.SharedMPC = nil
VBattleField.LevelsLoaded = nil
VBattleField.battleCraneCamera = nil

function VBattleField:Init(battleInitInfo)
  self.delaySafeCaller = DelaySafeCaller()
  self:SetupBattleFieldConf(battleInitInfo)
  if not self:CheckError() then
    return
  end
  self:_InitPosMode(battleInitInfo)
  local DepthCamCla = _G.BattleResourceManager:GetCacheAssetDirect(BattleConst.BattleDepthCam)
  self.BattleDepthCam = UE4.UGameplayStatics.GetActorOfClass(UE4Helper.GetCurrentWorld(), DepthCamCla)
  Log.Debug("VBattleField init:", self.BattleDepthCam)
  self.ReplacePetPos = {}
  self.WaterPlatformDict = {}
  self.WaterPlatformSwim = {}
  self._cachedLightingScenarioStreamingLevels = {}
  self.SceneObjects = {}
  self.skyPlatform = nil
  self.skyPlatformRef = nil
  self.WaterShakeGapTime = 60
  self.WaterPlatformRadius = 0
  self.WaterShakeSpendTime = 2
  self.battleFieldActor = self.battleFieldConf.BattleFieldActor
  self.battleFieldActor:SetActorHiddenInGame(false)
  self.panelCameraController = self.battleFieldConf.PanelCameraController
  self.panelCameraController:SetActorHiddenInGame(false)
  if not self.battleCraneCamera or not self.battleCameraManager then
    self:SetupCraneCamera()
  end
  self.battleCraneCamera:Init(self.battleFieldConf)
  self.battleFieldConf.EnemyCamera:K2_SetActorRelativeTransform(UE4.FTransform(), false, nil, false)
  self.battleFieldConf.TeammateCamera:K2_SetActorRelativeTransform(UE4.FTransform(), false, nil, false)
  self.battleFieldConf.TeammateCamera1v1:K2_SetActorRelativeTransform(UE4.FTransform(), false, nil, false)
  self:LoadCraneCameraOver(self.battleFieldConf.BattleCraneCamera)
  self:LoadAidCameraOver(self.battleFieldConf.AidRotationCam)
  if BattleUtils.IsDeepWater() then
    Log.Debug("battleFieldConf on deep water")
    self.battleFieldConf.BattleFieldType = UE4.EBattleFieldType.WaterSurface
    self:SafeDelaySeconds("d_StartWaterShake", self.WaterShakeGapTime, self.StartWaterShake, self)
  else
    Log.Debug("battleFieldConf on land")
    self.battleFieldConf.BattleFieldType = UE4.EBattleFieldType.Land
  end
end

function VBattleField:CheckError()
  if _G.RocoEnv.IS_SHIPPING then
    return true
  end
  if self.battleFieldConf then
    return true
  end
  local err = "BattleFieldConf is nil, Battle Can't Start, print information that maybe made BattleFieldConf is nil."
  err = err .. " position of Battle is  : " .. tostring(BattleManager.battleRuntimeData.TeleportBattleCenter or "nil")
  local Errors = string.split(err, "\n")
  local NewLines = {}
  for i = 1, 5 do
    if Errors[i] then
      table.insert(NewLines, Errors[i])
    else
      break
    end
  end
  local Shorten = table.concat(NewLines, "\n")
  local Ctx = DialogContext()
  Ctx:SetTitle("Error!!")
  Ctx:SetContent(err)
  Ctx:SetMode(DialogContext.Mode.OK)
  Ctx:SetCallback(nil, function()
    UE.UNRCStatics.QuitGame()
  end)
  Log.Error("zgx", err)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
  return false
end

function VBattleField:RecordNpcHideRange()
  self.BattleHideNpcCenter = {}
  self.BattleHideNpcExtent = {}
  local battleCenter = BattleManager.battleRuntimeData.NearbyValidBattleLocation
  local battleRotate = BattleManager.battleRuntimeData.NearbyValidBattleRotation
  if battleCenter and battleRotate then
    local hasEnemyPlayer = BattleUtils.HasEnemyPlayer()
    local fieldParam = BattleFieldConst.layer1Param
    if BattleManager.battleRuntimeData.subBattleType ~= BattleEnum.SubBattleType.Single then
      fieldParam = BattleFieldConst.layer2Param
    end
    local FRot = UE.FRotator(0, battleRotate - 90, 0)
    local ZExtent = fieldParam.BattlefieldHeight * 50
    local FirstTransform = UE.FTransform(FRot:ToQuat(), battleCenter, UE.FVector(1, 1, 1))
    local FirstExtent = UE.FVector(fieldParam.Radius1 * 100, 100 * fieldParam.Radius1 / fieldParam.Ratio1, ZExtent)
    local SecondTransform, SecondExtent
    if hasEnemyPlayer then
      SecondTransform = FirstTransform
      SecondExtent = UE.FVector(fieldParam.Radius2 * 100, 100 * fieldParam.Radius2 / fieldParam.Ratio2, ZExtent)
    else
      local SecondCenter = UE.UKismetMathLibrary.TransformLocation(FirstTransform, UE.FVector(-200, 0, 0))
      SecondTransform = UE.FTransform(FRot:ToQuat(), SecondCenter, UE.FVector(1, 1, 1))
      SecondExtent = UE.FVector(fieldParam.Radius2 * 100 - 200, 100 * fieldParam.Radius2 / fieldParam.Ratio2, ZExtent)
    end
    local ThirdCenter = UE.UKismetMathLibrary.TransformLocation(FirstTransform, UE.FVector(fieldParam.CameraCenterX * 100, fieldParam.CameraCenterY * -100, fieldParam.CameraCenterZ * 100))
    local ThirdTransform = UE.FTransform(FRot:ToQuat(), ThirdCenter, UE.FVector(1, 1, 1))
    local ThirdExtent = UE.FVector(fieldParam.CameraHalfX * 100, fieldParam.CameraHalfY * 100, fieldParam.CameraHalfZ * 100)
    self.BattleHideNpcCenter = {
      FirstTransform,
      SecondTransform,
      ThirdTransform
    }
    self.BattleHideNpcExtent = {
      FirstExtent,
      SecondExtent,
      ThirdExtent
    }
  end
end

function VBattleField:StartWaterShake()
  if BattleManager.isInBattle and self.battleCameraManager then
    self.battleCameraManager:StartWaterShake()
    self:SafeDelaySeconds("d_StopWaterShake", self.WaterShakeSpendTime, self.StopWaterShake, self)
  end
end

function VBattleField:StopWaterShake()
  if self.battleCameraManager then
    self.battleCameraManager:StopWaterShake()
    if BattleManager.isInBattle then
      self:SafeDelaySeconds("d_StartWaterShake", self.WaterShakeGapTime, self.StartWaterShake, self)
    end
  end
end

function VBattleField:LoadCraneCameraOver(SpringArmActor)
  if SpringArmActor then
    local battlePos = _G.FVectorOne
    if BattleManager.battleRuntimeData.TeleportBattleCenter then
      battlePos = BattleManager.battleRuntimeData.TeleportBattleCenter
    end
    local camTransform = UE4.UKismetMathLibrary.MakeTransform(battlePos, _G.FRotatorZero, UE4.FVector(1, 1, 1))
    SpringArmActor:Abs_K2_SetActorTransform_WithoutHit(camTransform)
    self.CraneCamera = SpringArmActor
  end
end

function VBattleField:LoadAidCameraOver(AidRotationCam)
  if AidRotationCam then
    local battlePos = _G.FVectorOne
    if BattleManager.TeleportBattleCenter then
      battlePos = BattleManager.TeleportBattleCenter
    end
    local camTransform = UE4.UKismetMathLibrary.MakeTransform(battlePos, _G.FRotatorZero, UE4.FVector(1, 1, 1))
    AidRotationCam:Abs_K2_SetActorTransform_WithoutHit(camTransform)
    self.AidRotationCam = AidRotationCam
  end
end

function VBattleField:TrySetup()
  return true
end

function VBattleField:SetupCraneCamera()
  self.battleCameraManager = BattleCraneCamera()
  self.battleCraneCamera = self.battleCameraManager
  self.battleCraneCamera:Construct()
end

function VBattleField:GetPCGCamTransform()
  return self.battleCraneCamera:GetCamComponentTransform()
end

function VBattleField:GetPCGCamFieldOfView()
  return self.battleCraneCamera.CameraComponent.FieldOfView
end

function VBattleField:GetPCGCamWorldRotation()
  return self.battleCraneCamera.CameraComponent:K2_GetComponentRotation()
end

function VBattleField:AdaptiveMyBattlePetPos(model)
  if BattleUtils.IsCrowdBattle() or BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if not model then
    Log.Error("VBattleField:AdaptiveMyBattlePetPos no model")
    return
  end
  local myPetMeshComponent = model:GetComponentByClass(UE.USkeletalMeshComponent)
  if not myPetMeshComponent then
    Log.Debug("VBattleField:AdaptiveEnemyBattlePetPos no myPetMeshComponent")
    return
  end
  local myPetMesh = myPetMeshComponent.SkeletalMesh
  if not myPetMesh then
    Log.Debug("VBattleField:AdaptiveEnemyBattlePetPos no myPetMesh")
    return
  end
  local pet = BattleManager.battlePawnManager:GetBattlePetByActor(model)
  if not pet then
    Log.Debug("VBattleField:AdaptiveEnemyBattlePetPos no BattlePet")
    return
  end
  local myPetBound = myPetMesh:GetImportedBounds()
  local fixValue = model:GetRadius()
  Log.Debug("show xx me Bound:", myPetBound.BoxExtent.X, myPetBound.BoxExtent.Y, myPetBound.BoxExtent.Z, fixValue, model:GetRadius())
  Log.Debug("fixValue my:", model:GetActorForwardVector(), fixValue, model:GetActorForwardVector())
  local finalPos = model:Abs_K2_GetActorLocation() - model:GetActorForwardVector() * fixValue
  model:Abs_K2_SetActorLocation_WithoutHit(finalPos)
  local newPos, _, isHit = LineTraceUtils.GetPointValidLocationByLine(finalPos)
  if not isHit then
    newPos = finalPos
    newPos.Z = newPos.Z - pet:GetHalfHeight()
  end
  self:Abs_SetPositionInBattleMap(pet.teamEnm, pet.card.posInField, false, newPos)
  if BattleUtils.IsDeepWater() then
    pet:SetPlatFormPos(newPos)
    local waterPlat = self:GetWaterPlatform(pet.teamEnm, pet.card.posInField or 1)
    if waterPlat then
      waterPlat:Abs_K2_SetActorLocation_WithoutHit(newPos)
    end
  end
end

function VBattleField:AdaptiveEnemyBattlePetPos(pet)
  if BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if not pet then
    Log.Error("VBattleField:AdaptiveEnemyBattlePetPos no pet")
    return
  end
  local model = pet.model
  if not model then
    Log.Error("VBattleField:AdaptiveEnemyBattlePetPos no model")
    return
  end
  local enemyPetMeshComponent = model:GetComponentByClass(UE.USkeletalMeshComponent)
  if not enemyPetMeshComponent then
    Log.Debug("VBattleField:AdaptiveEnemyBattlePetPos no enemyPetMeshComponent")
    return
  end
  local enemyPetMesh = enemyPetMeshComponent.SkeletalMesh
  if not enemyPetMesh then
    Log.Debug("VBattleField:AdaptiveEnemyBattlePetPos no enemyPetMesh")
    return
  end
  local enemyPetBound = enemyPetMesh:GetImportedBounds()
  local forward = model:GetActorForwardVector()
  if pet.card.petState:GetBackStab() then
    forward = -forward
  end
  local fixValue = model:GetRadius()
  Log.Debug("show xx enemy Bound:", enemyPetBound.BoxExtent.X, enemyPetBound.BoxExtent.Y, enemyPetBound.BoxExtent.Z, fixValue, model:GetRadius())
  local enemyTArr = self:GetTeamPositionMap(BattleEnum.Team.ENUM_ENEMY)
  for i = 1, enemyTArr:Length() do
    local actorEnemyPet = enemyTArr:Get(i)
    if _G.ShowAdaptiveLine then
      local lineBegin = actorEnemyPet:Abs_K2_GetActorLocation()
      local lineEnd = actorEnemyPet:Abs_K2_GetActorLocation() + UE4.FVector(0, 0, 1000)
      local _, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, {
        UE4.ETraceTypeQuery.TraceTypeQuery_MAX
      }, true, nil, UE4.EDrawDebugTrace.ForDuration, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), 9999)
    end
    local newPos = actorEnemyPet:Abs_K2_GetActorLocation() - forward * fixValue
    actorEnemyPet:Abs_K2_SetActorLocation_WithoutHit(newPos)
    if _G.ShowAdaptiveLine then
      local lineBegin = actorEnemyPet:Abs_K2_GetActorLocation()
      local lineEnd = actorEnemyPet:Abs_K2_GetActorLocation() + UE4.FVector(0, 0, 1000)
      local _, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, {
        UE4.ETraceTypeQuery.TraceTypeQuery_MAX
      }, true, nil, UE4.EDrawDebugTrace.ForDuration, nil, true, UE4.FLinearColor(1, 0, 1, 1), UE4.FLinearColor(1, 1, 0, 1), 9999)
    end
  end
  Log.Debug("fixValue ene:", model:GetActorForwardVector(), fixValue, model:GetActorForwardVector())
  local finalPos = model:Abs_K2_GetActorLocation() - forward * fixValue
  model:Abs_K2_SetActorLocation_WithoutHit(finalPos)
  local newPos, _, isHit = LineTraceUtils.GetPointValidLocationByLine(finalPos)
  if not isHit then
    newPos = finalPos
    newPos.Z = newPos.Z - pet:GetHalfHeight()
  end
  self:Abs_SetPositionInBattleMap(pet.teamEnm, pet.card.posInField, false, newPos)
  if BattleUtils.IsDeepWater() then
    pet:SetPlatFormPos(newPos)
    local waterPlat = self:GetWaterPlatform(pet.teamEnm, pet.card.posInField or 1)
    if waterPlat then
      waterPlat:Abs_K2_SetActorLocation_WithoutHit(newPos)
    end
  end
end

function VBattleField:_InitPosMode(battleInitInfo)
  if self.battleFieldConf and UE4.UObject.IsValid(self.battleFieldConf) then
    if BattleManager.battleRuntimeData:GetSubBattleType() ~= BattleEnum.SubBattleType.Single then
      self.battleFieldConf:SetCurrentPosNum(BattleManager.battleRuntimeData.playerPetNumber, BattleManager.battleRuntimeData.playerPetNumber, math.min(2, BattleManager.battleRuntimeData.enemyPetNumber), math.min(2, BattleManager.battleRuntimeData.enemyPetNumber))
    else
      self.battleFieldConf:SetCurrentPosNum(1, 2, 1, 2)
      local battleConfig = _G.DataConfigManager:GetBattleConf(battleInitInfo.battle_cfg_id[1])
      if 1 == battleConfig.challanger_unit_num and 1 == battleConfig.bechallanger_unit_num then
        self.battleFieldConf:SetCurrentPosNum(1, 1, 1, 1)
      elseif 2 == battleConfig.challanger_unit_num and 1 == battleConfig.bechallanger_unit_num then
        self.battleFieldConf:SetCurrentPosNum(1, 2, 1, 1)
      else
        self.battleFieldConf:SetCurrentPosNum(1, 2, 1, 2)
      end
    end
    self:AddTeamPosToInitPos(BattleEnum.Team.ENUM_TEAM)
    self:AddTeamPosToInitPos(BattleEnum.Team.ENUM_ENEMY)
  end
end

function VBattleField:RefreshPosModeWithPlayerAndPetNumber()
  if not UE.UObject.IsValid(self.battleFieldConf) then
    return
  end
  if BattleManager.battleRuntimeData:GetSubBattleType() ~= BattleEnum.SubBattleType.Single then
    self.battleFieldConf:SetCurrentPosNum(BattleManager.battleRuntimeData.playerPetNumber, BattleManager.battleRuntimeData.playerPetNumber, math.min(2, BattleManager.battleRuntimeData.enemyPetNumber), math.min(2, BattleManager.battleRuntimeData.enemyPetNumber))
    self:AddTeamPosToInitPos(BattleEnum.Team.ENUM_TEAM)
    self:AddTeamPosToInitPos(BattleEnum.Team.ENUM_ENEMY)
  end
end

function VBattleField:EnterBattle(LevelName)
end

function VBattleField:GetBattleFieldLocationByAttachPoint(attach)
  if not UE4.UObject.IsValid(self.battleFieldConf) then
    return nil
  end
  if attach and self.battleFieldConf.BattleFieldAttachPointMap:Find(attach) then
    return self.battleFieldConf.BattleFieldAttachPointMap:Find(attach):Abs_K2_GetActorLocation()
  end
  if attach == UE4.EBattleFieldAttachPoint.Pos_2v2EnemyPet1 then
    local array = self.battleFieldConf.EnemyNumPetPosMap:Find(2)
    if array then
      return array.PosArray:Get(1):Abs_K2_GetActorLocation()
    end
  elseif attach == UE4.EBattleFieldAttachPoint.Pos_2v2EnemyPet2 then
    local array = self.battleFieldConf.EnemyNumPetPosMap:Find(2)
    if array then
      local number = array.PosArray:Length()
      return array.PosArray:Get(number):Abs_K2_GetActorLocation()
    end
  elseif attach == UE4.EBattleFieldAttachPoint.Pos_2V2PlayerPet1 then
    local array = self.battleFieldConf.TeammateNumPetPosMap:Find(2)
    if array then
      return array.PosArray:Get(1):Abs_K2_GetActorLocation()
    end
  elseif attach == UE4.EBattleFieldAttachPoint.Pos_2V2PlayerPet2 then
    local array = self.battleFieldConf.TeammateNumPetPosMap:Find(2)
    if array then
      local number = array.PosArray:Length()
      return array.PosArray:Get(number):Abs_K2_GetActorLocation()
    end
  end
  return nil
end

function VBattleField:GetPetPointPosByTeamIndex(teamEnum, index)
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    local posActor = self.battleFieldConf.CurrentModePosInfo.TeamatePetPos:Get(index)
    return posActor:K2_GetActorLocation()
  elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
    local posActor = self.battleFieldConf.CurrentModePosInfo.EnemyPetPos:Get(index)
    return posActor:K2_GetActorLocation()
  end
  return nil
end

function VBattleField:GetCheerPetPosByIndex(index, cheerEnemyPosType)
  cheerEnemyPosType = cheerEnemyPosType or BattleEnum.CheerEnemyPosType.OneVsN
  local PosInfo = self.battleFieldConf.CheerEnemyPosMap:Find(cheerEnemyPosType)
  if PosInfo then
    local PosArray = PosInfo.PosArray
    local ContainsActor = PosArray:IsValidIndex(index)
    local actor = ContainsActor and PosInfo.PosArray:Get(index) or nil
    return actor and actor:Abs_K2_GetActorLocation()
  end
  return nil
end

function VBattleField:AbsModifyPetPointPosByTeamIndex(teamEnum, index, pos)
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    local posActor = self.battleFieldConf.CurrentModePosInfo.TeamatePetPos:Get(index)
    Log.Debug("AbsModifyPetPointPosByTeamIndex posActor 1:", posActor, posActor:GetName(), pos)
    return posActor:Abs_K2_SetActorLocation_WithoutHit(pos)
  elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
    local posActor = self.battleFieldConf.CurrentModePosInfo.EnemyPetPos:Get(index)
    Log.Debug("AbsModifyPetPointPosByTeamIndex posActor 2:", posActor, posActor:GetName(), pos)
    return posActor:Abs_K2_SetActorLocation_WithoutHit(pos)
  end
end

function VBattleField:GetPlayerPointPosByTeamIndex(teamEnum, index)
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    local posActor = self.battleFieldConf.CurrentModePosInfo.TeamatePlayerPos:Get(index)
    return posActor:K2_GetActorLocation()
  elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
    local posActor = self.battleFieldConf.CurrentModePosInfo.EnemyPlayerPos:Get(index)
    return posActor:K2_GetActorLocation()
  end
  return nil
end

function VBattleField:AbsModifyPlayerPointPosByTeamIndex(teamEnum, index, pos)
  Log.Debug("AbsModifyPlayerPointPosByTeamIndex posActor try set:", teamEnum, index, pos)
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    local posActor = self.battleFieldConf.CurrentModePosInfo.TeamatePlayerPos:Get(index)
    Log.Debug("AbsModifyPlayerPointPosByTeamIndex posActor 1:", posActor, pos)
    return posActor:Abs_K2_SetActorLocation_WithoutHit(pos)
  elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
    local posActor = self.battleFieldConf.CurrentModePosInfo.EnemyPlayerPos:Get(index)
    Log.Debug("AbsModifyPlayerPointPosByTeamIndex posActor 2:", posActor, pos)
    return posActor:Abs_K2_SetActorLocation_WithoutHit(pos)
  end
end

function VBattleField:LeaveBattle()
  self:ClearWaterPlatform()
  if self.WaterBattleReflection then
    self.WaterBattleReflection:Disable()
    self.WaterBattleReflection:K2_DestroyActor()
    self.WaterBattleReflection = nil
  end
  self.WaterBattleReflectionRef = nil
  if self.SceneObjects then
    for _, v in ipairs(self.SceneObjects) do
      v:K2_DestroyActor()
    end
  end
  if self.skyPlatform then
    self.skyPlatform:K2_DestroyActor()
    self.skyPlatform = nil
  end
  self.skyPlatformRef = nil
  self:ResetAttachPoint()
  self:ClearRawTransform()
  if self.battleCameraManager then
    self.battleCameraManager:Destruct()
    self.battleCameraManager = nil
  end
  self.TeamReflection = nil
  self.TeamReflectionShowActors = nil
  self:UnLoadBattleLevel()
  self:SwitchToMain()
  if UE4.UObject.IsValid(self.battleFieldActor) then
    self.battleFieldActor:SetWaterFight(0, 0)
    self.battleFieldActor.RocoFX:StopAllFx()
    self.battleFieldActor:SetActorHiddenInGame(true)
    SkillUtils.ClearSkillObj(self.battleFieldActor.Skill)
    self.battleFieldActor:LeaveBattle()
  end
  self.battleFieldActor = nil
  self.panelCameraController = nil
  self.AidRotationCam = nil
  self.CraneCamera = nil
  self.battleCraneCamera = nil
  self.battleFieldConf = nil
  self.WaterPlatformSwim = {}
  self.SceneObjects = {}
  self.WaterPlatformDict = {}
  self.BattleHideNpcCenter = nil
  self.BattleHideNpcExtent = nil
  if self.BattleDepthCam then
    self.BattleDepthCam:UpdateClearHiddenActor()
    self.BattleDepthCam = nil
  end
  self.delaySafeCaller:Dispose()
end

function VBattleField:ClearWaterPlatform()
  if self.WaterPlatformDict then
    for teamEnm, WaterPlatformLst in pairs(self.WaterPlatformDict) do
      if WaterPlatformLst then
        for index, WaterPlatform in pairs(WaterPlatformLst) do
          WaterPlatform:K2_DestroyActor()
        end
      end
      self.WaterPlatformDict[teamEnm] = nil
    end
  end
end

function VBattleField:LoadBattleLevel(LevelName, Location, Rotation)
  if not self.LevelsLoaded then
    self.LevelsLoaded = {}
  end
  local IsSuccess, LevelStreaming = UE.ULevelStreamingDynamic.LoadLevelInstance(_G.UE4Helper.GetCurrentWorld(), LevelName, Location, Rotation)
  if IsSuccess and LevelStreaming then
    table.insert(self.LevelsLoaded, LevelStreaming)
    return LevelStreaming
  else
    Log.Error("zgx Level Load Failed , Level Name", LevelName)
  end
end

function VBattleField:ShowBattleLevel()
  if self.LevelsLoaded then
    for _, Level in ipairs(self.LevelsLoaded) do
      Level:SetShouldBeVisible(true)
    end
  end
end

function VBattleField:SetEnvVolumeForLoadLevel(IsEnterBattle)
  if self.LevelsLoaded then
    for _, LevelStreaming in ipairs(self.LevelsLoaded) do
      if UE4.UObject.IsValid(LevelStreaming) then
        local EnvSystemVolume = UE4.UNRCStatics.GetActorFromLevelByClass(LevelStreaming:GetLoadedLevel(), UE4.AEnvSystemVolume)
        if EnvSystemVolume then
          EnvSystemVolume.IsUsedVolume = IsEnterBattle or false
          EnvSystemVolume.bUnbound = IsEnterBattle or false
        end
      else
        Log.Error("VBattleField  LevelStreaming is nil")
      end
    end
    self:MarkTodVolumeArrayDirty()
  end
end

function VBattleField:MarkTodVolumeArrayDirty()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if EnvSys then
    EnvSys:MarkTodVolumeArrayDirty()
  end
end

function VBattleField:UnLoadBattleLevel()
  if self.LevelsLoaded then
    self:SetEnvVolumeForLoadLevel(false)
    for _, Level in ipairs(self.LevelsLoaded) do
      if UE4.UObject.IsValid(Level) then
        Level:SetIsRequestingUnloadAndRemoval(true)
        Level:SetShouldBeVisible(false)
      end
    end
    self.LevelsLoaded = nil
  end
end

function VBattleField:SwitchToMain()
  local Flags = _G.LevelHelper.Flags
  _G.LevelHelper:SetLevelVisibility(Flags.Default | Flags.Main)
end

function VBattleField:SwitchToBattle()
  local Flags = _G.LevelHelper.Flags
  _G.LevelHelper:SetLevelVisibility(Flags.Battle)
end

function VBattleField:IsSameType(ProtoType, EngineType)
  if ProtoType == ProtoEnum.BattleType.BT_LEADERFIGHT or ProtoType == ProtoEnum.BattleType.BT_DUNGEONBOSS or ProtoType == ProtoEnum.BattleType.BT_BOSS_CHALLENGE then
    return EngineType == UE4.EBattleType.BossFight
  elseif ProtoType == ProtoEnum.BattleType.BT_TEAM_BATTLE or ProtoType == ProtoEnum.BattleType.BT_LEGENDARY_BATTLE then
    return EngineType == UE4.EBattleType.TeamFight
  elseif ProtoType == ProtoEnum.BattleType.BT_AONE_FINAL_BATTLE_P1 then
    return EngineType == UE4.EBattleType.A1FinalBattleP1
  elseif ProtoType == ProtoEnum.BattleType.BT_AONE_FINAL_BATTLE_P2 then
    return EngineType == UE4.EBattleType.A1FinalBattleP2
  elseif ProtoType == ProtoEnum.BattleType.BT_FINAL_BATTLE_B1_STATE1 then
    return EngineType == UE4.EBattleType.B1FinalBattleP1
  elseif ProtoType == ProtoEnum.BattleType.BT_FINAL_BATTLE_B1_STATE2 then
    return EngineType == UE4.EBattleType.B1FinalBattleP2
  elseif ProtoType == ProtoEnum.BattleType.BT_FINAL_BATTLE_B1_STATE3 then
    return EngineType == UE4.EBattleType.B1FinalBattleP3
  elseif ProtoType == ProtoEnum.BattleType.BT_1VN then
    return EngineType == UE4.EBattleType.OneVsAll
  elseif ProtoType == ProtoEnum.BattleType.BT_TERRITORY_TRIAL then
    return EngineType == UE4.EBattleType.TerritoryTrial
  else
    return EngineType == UE4.EBattleType.Normal
  end
end

function VBattleField:SetupBattleFieldConf(battleInitInfo)
  if self.battleFieldConf then
    return
  end
  local BattleType = ProtoEnum.BattleType.BT_PVE
  if battleInitInfo then
    local BattleConf = _G.DataConfigManager:GetBattleConf(battleInitInfo.battle_cfg_id[1])
    BattleType = BattleConf and BattleConf.type or ProtoEnum.BattleType.BT_PVE
  else
    Log.Error("\232\191\155\229\133\165\230\136\152\230\150\151\233\148\153\232\175\175 battleInitInfo \228\184\186\231\169\186... \233\186\187\231\131\166\230\137\167\232\161\140GM-\230\136\152\230\150\151-\228\191\157\229\173\152\228\184\138\228\184\128\229\156\186\230\136\152\230\150\151\229\189\149\229\131\143 \229\143\145\233\128\129\231\187\153Jinfuwang")
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local BattleFieldConfClass = _G.BattleResourceManager:GetCacheAssetDirect(_G.UEPath.BP_BattleFieldConf)
  local BattleFields = UE4.UGameplayStatics.GetAllActorsOfClass(World, BattleFieldConfClass)
  for _, BattleField in tpairs(BattleFields) do
    if self:IsSameType(BattleType, BattleField.BattleType) then
      self.battleFieldConf = BattleField
      break
    end
  end
  if not self.battleFieldConf then
    for _, BattleField in tpairs(BattleFields) do
      if self:IsSameType(ProtoEnum.BattleType.BT_PVE, BattleField.BattleType) then
        self.battleFieldConf = BattleField
      end
    end
    Log.Error("\231\188\186\229\176\145\229\156\186\230\153\175\233\133\141\231\189\174...", BattleType)
  end
end

function VBattleField:GetBattleFieldCenter()
  if self.battleFieldActor and UE4.UObject.IsValid(self.battleFieldActor) then
    return self.battleFieldActor:Abs_K2_GetActorLocation()
  else
    return BattleManager.battleRuntimeData.NearbyValidBattleLocation or _G.FVectorZero
  end
end

function VBattleField:GetBattleFieldCenterOri()
  return self.battleFieldActor:K2_GetActorLocation()
end

function VBattleField:GetBattleFieldRadius()
  return BattleConst.Define.BattleFieldRange
end

function VBattleField:GetBattleFieldCenterRaw(battlePet1, battlePet2)
  local pos1 = battlePet1.model:Abs_K2_GetActorLocation()
  local pos2 = battlePet2.model:Abs_K2_GetActorLocation()
  local center = (pos1 + pos2) / 2
  return center
end

function VBattleField:GetBattleFieldCenterValid(battlePet1, battlePet2)
  local centerRaw = self:GetBattleFieldCenterRaw(battlePet1, battlePet2)
  local height1 = battlePet1:GetHalfHeight()
  local height2 = battlePet2:GetHalfHeight()
  local ans, pos = self:GetPointValidLocation(centerRaw, (height1 + height2) / 2)
  return pos
end

function VBattleField:GetPointValidLocation(pos, halfHeight)
  local posByLineCheck = LineTraceUtils.GetPointValidLocationByLine(pos, halfHeight)
  if nil == posByLineCheck then
    local posByNavCheck = self:GetPointValidLocationByNavMesh(pos)
    if nil == posByNavCheck then
      return false, pos
    else
      return true, posByNavCheck
    end
  else
    return true, posByLineCheck
  end
end

function VBattleField:GetPointValidLocationByNavMesh(pos)
  local NavMeshObj = BattleEnv.RecastNavMesh_Default
  Log.Debug("BattleUtils GetPointValidLocation NavMeshObj:", type(NavMeshObj), pos)
  local QueryExtent = UE4.FVector(0, 0, BattleConst.BattleFieldValidCheck.LineTraceMaxLength)
  local actorLocation = pos
  local HitLocation, HitResult = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), actorLocation, nil, NavMeshObj, nil, QueryExtent)
  if HitResult and HitLocation then
    Log.Debug("BattleUtils GetPointValidLocation HitLocation 11:", HitLocation, ",PlayerLocation:", actorLocation)
    return HitLocation
  else
    Log.Debug("BattleUtils GetPointValidLocation find fail 22:", HitResult, HitLocation, actorLocation, UE4Helper.GetCurrentWorld())
  end
  return nil
end

function VBattleField:GetBattleFieldRotation(battlePet1, battlePet2)
  local playerPos = battlePet1.model:Abs_K2_GetActorLocation()
  local enemyPos = battlePet2.model:Abs_K2_GetActorLocation()
  local Dir = playerPos - enemyPos
  local Rotator = Dir:ToRotator()
  return Rotator.Yaw
end

function VBattleField:UpdateBattleFieldLocation(battlePet1, battlePet2)
  local center = self:GetBattleFieldCenterValid(battlePet1, battlePet2)
  self.battleFieldActor:Abs_K2_SetActorLocation_WithoutHit(center)
  Log.Warning("wjf UpdateBattleFieldLocation", center, self.battleFieldActor:Abs_K2_GetActorLocation(), self.battleFieldActor:K2_GetActorLocation())
end

function VBattleField:UpdateBattleFieldRotation(battlePet1, battlePet2)
  local rotatorZ = self:GetBattleFieldRotation(battlePet1, battlePet2) + BattleDefine.RotateBattleFieldAnglePrefix
  self.battleFieldActor:K2_SetActorRotation(UE4.FRotator(0, rotatorZ, 0), false)
end

function VBattleField:UpdateBattleFieldLocationAndRotationSettings(myPets, enemyPets)
  self:UpdateBattleFieldLocation(myPets[1], enemyPets[#enemyPets])
  self:UpdateBattleFieldRotation(myPets[1], enemyPets[1])
end

function VBattleField:UpdateActorValidLocation(actor)
  local ans, pos = false, UE4.FVector(0, 0, 0)
  ans, pos = self:GetPointValidLocation(actor:Abs_GetTransform().Translation)
  if true == ans then
    actor:Abs_K2_SetActorLocation_WithoutHit(pos)
  end
end

function VBattleField:CalcBattleFieldAngle()
  local teamateTArr = self:GetTeamPositionMap(BattleEnum.Team.ENUM_TEAM)
  local enemyTArr = self:GetTeamPositionMap(BattleEnum.Team.ENUM_ENEMY)
  local actorMyPet = teamateTArr:Get(1)
  local actorMyPetLoc = actorMyPet:Abs_K2_GetActorLocation()
  local actorEnemyPet = enemyTArr:Get(1)
  local actorEnemyPetLoc = actorEnemyPet:Abs_K2_GetActorLocation()
  local vect1 = actorEnemyPetLoc - actorMyPetLoc
  local vect2 = UE4.FVector(vect1.X, vect1.Y, 0)
  local angle = UE4.UNRCStatics.CalcAngle(vect2, vect1)
  if actorMyPetLoc.Z > actorEnemyPetLoc.Z then
    angle = -angle
  end
  return angle
end

function VBattleField:MoveToLocation(location, rotateAngle)
  if UE.UObject.IsValid(self.battleFieldActor) then
    local validPos = LineTraceUtils.GetPointValidLocationByLine(location, nil, nil, BattleManager.battleRuntimeData.NearbyValidBattleLocation)
    Log.Debug("movetolocation :", location, rotateAngle, self.battleFieldActor, type(self.battleFieldActor))
    self.battleFieldActor:Abs_K2_SetActorLocation_WithoutHit(validPos, false, false)
    Log.Warning("wjf UpdateBattleFieldLocation", validPos, self.battleFieldActor:Abs_K2_GetActorLocation(), self.battleFieldActor:K2_GetActorLocation())
    local rotate = UE4.UKismetMathLibrary.MakeRotator(0, 0, rotateAngle)
    self.battleFieldActor:K2_SetActorRotation(rotate, false)
    self:RecordRawTransform()
  end
end

function VBattleField:AddTeamPosToInitPos(team)
  local posArray = self:GetTeamPositionMap(team)
  if posArray then
    for i = 1, posArray:Length() do
      self:AddInitPos(posArray:Get(i))
    end
  end
  posArray = self:GetTeamPositionMap(team, true)
  if posArray then
    for i = 1, posArray:Length() do
      self:AddInitPos(posArray:Get(i))
    end
  end
end

function VBattleField:AddInitPos(actor)
  if not self.AttachPointInitPos then
    self.AttachPointInitPos = {}
  end
  local initPos = actor:K2_GetRootComponent():GetRelativeTransform().Translation
  self.AttachPointInitPos[actor] = UE4.FVector(initPos.X, initPos.Y, 0)
end

function VBattleField:ResetAttachPoint()
  if not self.AttachPointInitPos then
    return
  end
  for actor, pos in pairs(self.AttachPointInitPos) do
    if UE4.UObject.IsValid(actor) then
      actor:K2_GetRootComponent():K2_SetRelativeLocation(pos, false, nil, false)
    end
  end
end

function VBattleField:SpawnWaterBattleReflection()
  local spawnLoc = self:GetBattleFieldCenter()
  spawnLoc.Z = self.WaterHeight
  local fTransfom = UE.FTransform(UE.FQuat(), spawnLoc)
  local params = {}
  _G.BattleResourceManager:LoadActorAsyncWithParam(self, BattleConst.WaterBattleReflection, fTransfom, PriorityEnum.Passive_Battle_BattleField, params, self.SpawnWaterBattleReflectionOver)
end

function VBattleField:SpawnWaterBattleReflectionOver(WaterBattleReflection)
  self.WaterBattleReflection = WaterBattleReflection
  self.WaterBattleReflectionRef = WaterBattleReflection and UnLua.Ref(WaterBattleReflection)
  if self.WaterBattleReflection then
    self.WaterBattleReflection:Enable()
    self:RefreshWaterBattleReflection()
  end
end

function VBattleField:RefreshWaterBattleReflection()
  if not BattleManager.PrepareOver then
    return
  end
  if self.WaterBattleReflection then
    self.WaterBattleReflection.ShowOnlyActors:Clear()
    local pets = self.BattlePawnManager:GetAllPets()
    local hasModel = false
    for _, v in ipairs(pets) do
      if v.model and not v:GetCanSwimming() then
        hasModel = true
        self.WaterBattleReflection.ShowOnlyActors:Add(v.model)
      end
    end
    if hasModel then
      self.WaterBattleReflection:RefreshShowActors()
    end
  end
  if BattleUtils.IsTeam() then
    if not self.TeamReflection then
      local World = _G.UE4Helper.GetCurrentWorld()
      local reflections = UE4.UGameplayStatics.GetAllActorsOfClass(World, UE.APlanarReflection)
      for _, reflection in tpairs(reflections) do
        local pos = reflection:K2_GetActorLocation()
        if pos and math.abs(pos.Z - 200000) <= 1000 then
          self.TeamReflection = reflection
          break
        end
      end
    end
    if self.TeamReflection then
      local ReflectionComponent = self.TeamReflection.PlanarReflectionComponent
      if ReflectionComponent then
        if not self.TeamReflectionShowActors then
          self.TeamReflectionShowActors = {}
          for i = 1, ReflectionComponent.ShowOnlyActors:Length() do
            local actor = ReflectionComponent.ShowOnlyActors:Get(i)
            if actor and UE4.UObject.IsValid(actor) then
              table.insert(self.TeamReflectionShowActors, ReflectionComponent.ShowOnlyActors:Get(i))
            end
          end
        end
        ReflectionComponent.ShowOnlyActors:Clear()
        local pets = self.BattlePawnManager:GetAllPets()
        for _, v in ipairs(pets) do
          if v.model then
            ReflectionComponent.ShowOnlyActors:Add(v.model)
          end
        end
        for _, v in ipairs(self.BattlePawnManager.AllPlayerTeam) do
          if v.player and v.player.model then
            ReflectionComponent.ShowOnlyActors:Add(v.player.model)
          end
        end
        for _, v in ipairs(self.TeamReflectionShowActors) do
          ReflectionComponent.ShowOnlyActors:Add(v)
        end
        for _, v in ipairs(self.SceneObjects) do
          if v and UE4.UObject.IsValid(v) then
            ReflectionComponent.ShowOnlyActors:Add(v)
          end
        end
      end
    end
  end
end

function VBattleField:SpawnBattleFieldPlatform(battleFieldType)
  Log.Debug("VBattleField SpawnBattleFieldPlatform:", battleFieldType)
  if 0 == battleFieldType then
  elseif 1 == battleFieldType then
  elseif 2 == battleFieldType then
    self:SpawnSkyPlatform(self.battleFieldActor:Abs_K2_GetActorLocation())
  end
end

function VBattleField:PawnWaterPlatform(teamEnum, index, location)
  if self.WaterPlatformDict[teamEnum] and self.WaterPlatformDict[teamEnum][index] then
    return
  end
  local AreaId = NRCModuleManager:DoCmd(BigMapModuleCmd.GetBroadcastArea)
  if not AreaId then
    Log.Error("\230\178\161\230\137\190\229\136\176AreaId\239\188\154\229\188\186\229\136\182\232\174\190\231\189\174AreaId\228\184\18680003")
    AreaId = 80003
  end
  Log.Debug("VBattleField SpawnWaterPlatform:", teamEnum, index, location)
  local AreaFunConf = _G.DataConfigManager:GetAreaFuncConf(AreaId)
  local waterPlatformUrl = AreaFunConf.water_platform
  Log.Debug("VBattleField PawnWaterPlatform waterPlatformUrl:", waterPlatformUrl)
  local angle = math.random(0, 360)
  Log.Debug("VBattleField PawnWaterPlatform angle:", angle)
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, angle)
  local fTransfom = UE4.FTransform(quat, location)
  local params = {}
  _G.BattleResourceManager:LoadActorAsyncWithParam(self, waterPlatformUrl, fTransfom, PriorityEnum.Passive_Battle_BattleField, params, self.PawnWaterPlatformOver, nil, teamEnum, index)
end

function VBattleField:GetWaterPlatform(teamEnum, index)
  if self.WaterPlatformDict[teamEnum] then
    return self.WaterPlatformDict[teamEnum][index]
  end
end

function VBattleField:SetWaterPlatformVisible(teamEnum, index, canSwim)
  if self.WaterPlatformDict[teamEnum] and self.WaterPlatformDict[teamEnum][index] then
    self.WaterPlatformDict[teamEnum][index]:SetActorHiddenInGame(canSwim)
    self.WaterPlatformDict[teamEnum][index]:SetActorEnableCollision(not canSwim)
  else
    if not self.WaterPlatformSwim[teamEnum] then
      self.WaterPlatformSwim[teamEnum] = {}
    end
    self.WaterPlatformSwim[teamEnum][index] = canSwim
  end
end

function VBattleField:HideAllWaterPlatforms()
  if self.WaterPlatformDict then
    for teamEnm, WaterPlatformLst in pairs(self.WaterPlatformDict) do
      if WaterPlatformLst then
        for index, WaterPlatform in pairs(WaterPlatformLst) do
          WaterPlatform:SetActorHiddenInGame(true)
        end
      end
    end
  end
end

function VBattleField:PawnWaterPlatformOver(waterPlatform, teamEnum, index)
  Log.Debug("VBattleField PawnWaterPlatform PlatformHeight:", waterPlatform.PlatformHeight)
  if not self.WaterPlatformDict[teamEnum] then
    self.WaterPlatformDict[teamEnum] = {}
  end
  self.WaterPlatformDict[teamEnum][index] = waterPlatform
  if self.WaterPlatformRadius <= 0 and waterPlatform.LotusLeafMain and waterPlatform.LotusLeafMain.StaticMesh then
    local halfSize = waterPlatform.LotusLeafMain.StaticMesh:GetBounds().BoxExtent
    self.WaterPlatformRadius = math.max(halfSize.X, halfSize.Y) * 0.9
  end
  if self.WaterPlatformSwim[teamEnum] and self.WaterPlatformSwim[teamEnum][index] ~= nil then
    self:SetWaterPlatformVisible(teamEnum, index, self.WaterPlatformSwim[teamEnum][index])
    local Pets = BattlePawnManager:GetInFieldAllPet(teamEnum)
    for _, pet in ipairs(Pets) do
      if pet.card.posInField == index and pet.teamEnm == teamEnum then
        pet:InitPlatForm(waterPlatform)
        waterPlatform:Abs_K2_SetActorLocation_WithoutHit(pet.PlatFormPos)
        break
      end
    end
  elseif teamEnum == BattleEnum.Team.ENUM_OBSERVER then
    self:SetWaterPlatformVisible(teamEnum, index, false)
  else
    waterPlatform:SetActorHiddenInGame(true)
    waterPlatform:SetActorEnableCollision(false)
  end
end

function VBattleField:SpawnSkyPlatform(location)
  BattleResourceManager:LoadActorAsync(self, _G.UEPath.BP_SkyPlatform, UE4.FTransform(UE4.FQuat(), location), {}, self.OnSkyPlatformLoad)
end

function VBattleField:OnSkyPlatformLoad(skyPlatform)
  self.skyPlatform = skyPlatform
  self.skyPlatformRef = skyPlatform and UnLua.Ref(skyPlatform)
end

function VBattleField:GetSkyPlatform()
  return self.skyPlatform
end

function VBattleField:GetTeamPositionMap(teamType, isPlayer)
  if UE4.UObject.IsValid(self.battleFieldConf) then
    if isPlayer then
      if teamType == BattleEnum.Team.ENUM_TEAM then
        return self.battleFieldConf.CurrentModePosInfo.TeamatePlayerPos
      else
        return self.battleFieldConf.CurrentModePosInfo.EnemyPlayerPos
      end
    elseif teamType == BattleEnum.Team.ENUM_TEAM then
      return self.battleFieldConf.CurrentModePosInfo.TeamatePetPos
    else
      return self.battleFieldConf.CurrentModePosInfo.EnemyPetPos
    end
  else
    Log.Error("VBattleField:GetTeamPositionMap self.battleFieldConf is nil")
    return UE4.TArray(UE4.AActor)
  end
end

function VBattleField:IsBattleFieldConfValid()
  return UE4.UObject.IsValid(self.battleFieldConf)
end

function VBattleField:SetTeamPositionMap(teamType, posInField)
end

function VBattleField:GetTeamPositionMapFixedPos(teamType)
end

function VBattleField:GetPetBornPosition(teamEnm, posInField, card, isFinal)
  if BattleUtils.IsCrowdBattle() and posInField > 1 and teamEnm == BattleEnum.Team.ENUM_ENEMY then
    if not (not _G.BattleManager.battleRuntimeData.battleStartParam:IsReconnect() and _G.BattleManager.battleRuntimeData:HasValidNPC()) or isFinal or not card:CheckCanMoveBeforePawn() then
      local petPos = self:GetTeamPositionMap(teamEnm)
      if posInField <= petPos:Length() then
        return self:GetPositionInBattleMap(teamEnm, posInField)
      else
        local Result = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
        Result.Translation = self:GetPositionInElliptic(card.petInfo.battle_inside_pet_info.cheers_tag)
        local FirstEnemyBronPos = self:GetPositionInBattleMap(BattleUtils.GetEnemyTeamEnum(teamEnm), 1)
        local dir = FirstEnemyBronPos.Translation - Result.Translation
        dir.Z = 0
        Result.Rotation = dir:ToRotator():Clamp():ToQuat()
        return Result
      end
    else
      local FirstPetBronPos = self:GetPositionInBattleMap(teamEnm, 1)
      local PawnPos = BattleUtils.GetNavInvalidPos(FirstPetBronPos.Translation + self:GetRelativePosWithFirstInWorld(card.petInfo.battle_inside_pet_info.cheers_tag), FirstPetBronPos.Translation)
      local distance = PawnPos:Dist(FirstPetBronPos.Translation)
      if distance >= 50 and distance <= 5000 then
        FirstPetBronPos.Translation = PawnPos
        return FirstPetBronPos, true
      else
        return self:GetPetBornPosition(teamEnm, posInField, card, true)
      end
    end
  elseif BattleUtils.IsTerritoryTrialBattle() and teamEnm == BattleEnum.Team.ENUM_ENEMY then
    local petPos = self:GetTeamPositionMap(teamEnm)
    if posInField <= petPos:Length() then
      return self:GetPositionInBattleMap(teamEnm, posInField)
    else
      local territoryPrepareStandSlotIndex = BattleConst.TerritoryTrial.PetPosToClientStandPos[posInField]
      local startPos = _G.BattleManager.vBattleField:GetBattleFieldCenter()
      local index = territoryPrepareStandSlotIndex or -1
      local configPos = _G.BattleManager.vBattleField:GetCheerPetPosByIndex(index, BattleEnum.CheerEnemyPosType.TerritoryTrial) or startPos
      local final = BattleUtils.GetNavInvalidPos(configPos, startPos)
      local FirstEnemyBronPos = self:GetPositionInBattleMap(BattleUtils.GetEnemyTeamEnum(teamEnm), 1)
      local transform = UE.FTransform()
      local dir = FirstEnemyBronPos.Translation - final
      dir.Z = 0
      transform.Translation = final
      transform.Rotation = dir:ToRotator():Clamp():ToQuat()
      return transform
    end
  else
    return self:GetPositionInBattleMap(teamEnm, posInField)
  end
end

function VBattleField:RecordRawTransform()
  self.TeamatePetRawTransforms = self:DoRecordRawTransform(self.battleFieldConf.CurrentModePosInfo.TeamatePetPos)
  self.EnemyPetRawTransforms = self:DoRecordRawTransform(self.battleFieldConf.CurrentModePosInfo.EnemyPetPos)
end

function VBattleField:DoRecordRawTransform(actors)
  local rawTable = {}
  for i = 1, actors:Length() do
    local actor = actors:Get(i)
    if actor then
      local rawTransform = actor:Abs_GetTransform()
      local rawTransCopy = UE.FTransform(rawTransform.Rotation, rawTransform.Translation, rawTransform.Scale3D)
      rawTable[i] = rawTransCopy
    end
  end
  return rawTable
end

function VBattleField:ClearRawTransform()
  self.TeamatePetRawTransforms = nil
  self.EnemyPetRawTransforms = nil
end

function VBattleField:FindPetRawTransform(teamEnm, posInField)
  local transList = teamEnm == BattleEnum.Team.ENUM_TEAM and self.TeamatePetRawTransforms or self.EnemyPetRawTransforms
  if transList then
    return transList[posInField]
  end
  return nil
end

function VBattleField:GetRelativePosWithFirstInWorld(cheerFlag)
  local firstPet = _G.BattleManager.CheerPetsWorldInfo[10]
  local curPet = _G.BattleManager.CheerPetsWorldInfo[cheerFlag]
  if firstPet and curPet then
    return curPet - firstPet
  end
  return UE.FVector(0, 0, 0)
end

function VBattleField:Abs_SetPositionInBattleMap(teamEnm, posInField, isPlayer, newPos)
  local petPos = self:GetTeamPositionMap(teamEnm, isPlayer)
  if petPos then
    local petPosMap = petPos:Get(posInField)
    if petPosMap then
      petPosMap:Abs_K2_SetActorLocation(newPos, false, nil, false)
    else
      Log.Error("zgx GetPositionInBattleMap Error petPosMap is nil", teamEnm, posInField, isPlayer or "false")
    end
  else
    Log.Error("zgx GetPositionInBattleMap Error petPos is nil ", teamEnm, posInField, isPlayer or "false")
  end
end

function VBattleField:GetPositionInBattleMap(teamEnm, posInField, isPlayer)
  local petPos = self:GetTeamPositionMap(teamEnm, isPlayer)
  if petPos then
    local petPosMap = petPos:Get(posInField)
    if petPosMap then
      return petPosMap:Abs_GetTransform()
    else
      Log.Error("GetPositionInBattleMap Error petPosMap is nil", teamEnm, posInField, isPlayer or "false")
      local default = petPos:Get(1)
      if default then
        return default:Abs_GetTransform()
      end
    end
  else
    Log.Error("GetPositionInBattleMap Error  petPos is nil", teamEnm, posInField, isPlayer or "false")
    return
  end
  return UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
end

function VBattleField:GetPositionActorInBattleMap(teamEnm, posInField, isPlayer)
  local petPos = self:GetTeamPositionMap(teamEnm, isPlayer)
  local petPosMap = petPos:Get(posInField)
  if petPosMap then
    return petPosMap
  else
    Log.Error("GetPositionInBattleMap Error ", teamEnm, posInField, isPlayer or "false")
    return petPos:Get(1)
  end
end

function VBattleField:GetPositionInElliptic(index)
  if self.ReplacePetPos[index] then
    local total = self.ReplacePetPos[index]
    if #total > 0 then
      local target = math.round(#total / 2)
      return total[target]
    end
  end
  Log.Error("zgx GetPositionInElliptic Error", index)
  return UE4.FVector(0, 0, 0)
end

function VBattleField:GetPositionInEllipticRandom(index)
  if self.ReplacePetPos[index] then
    local total = self.ReplacePetPos[index]
    if #total > 0 then
      local target = math.round(math.random(1, #total))
      return total[target]
    end
  end
end

function VBattleField:BindCraneCamera()
  if self.battleCraneCamera then
    self.battleCraneCamera:BindCamera()
  end
end

function VBattleField:CheckGrassResIsOver()
  local grassStaticMeshPathList = _G.BattleManager.battleRuntimeData.battleGrassInfo.GrassStaticMeshPathList or {}
  for i, path in ipairs(grassStaticMeshPathList) do
    local asset = _G.BattleResourceManager:GetCacheAssetDirect(path, true)
    if not asset then
      return false
    end
  end
  return true
end

function VBattleField:ChangeGrass()
  if not self.isChangeGrass then
    local UNRCStatics = UE4.UNRCStatics
    local TMap = UE4.TMap
    local battleRuntimeData = _G.BattleManager.battleRuntimeData
    local foliageHismToTargetStaticMeshPathTable = battleRuntimeData.battleGrassInfo.foliageHismToTargetStaticMeshPathTable or {}
    local landscapeHismToTargetStaticMeshPathTable = battleRuntimeData.battleGrassInfo.landscapeHismToTargetStaticMeshPathTable or {}
    local foliageHismToTargetStaticMesh = TMap(UE.UHierarchicalInstancedStaticMeshComponent, UE.UStaticMesh)
    local landscapeHismToTargetStaticMesh = TMap(UE.UHierarchicalInstancedStaticMeshComponent, UE.UStaticMesh)
    local changedFoliageHism = {}
    for k, v in pairs(foliageHismToTargetStaticMeshPathTable) do
      local staticMesh = _G.BattleManager.battleResourceManager:GetCacheAssetDirect(v)
      if UE.UObject.IsValid(staticMesh) and UE.UObject.IsValid(k) then
        table.insert(changedFoliageHism, k)
        foliageHismToTargetStaticMesh:Add(k, staticMesh)
      end
    end
    for k, v in pairs(landscapeHismToTargetStaticMeshPathTable) do
      local staticMesh = _G.BattleManager.battleResourceManager:GetCacheAssetDirect(v)
      if UE.UObject.IsValid(staticMesh) and UE.UObject.IsValid(k) then
        landscapeHismToTargetStaticMesh:Add(k, staticMesh)
      end
    end
    local cachedHismAndStaticMeshFromLandscape = TMap(UE.UHierarchicalInstancedStaticMeshComponent, UE.UStaticMesh)
    Log.DebugFormat("BattleHideSceneTreesAction:ChangeBattleGrass, %s HISM from foliage, %s HISM from landscape", tostring(foliageHismToTargetStaticMesh:Length()), tostring(landscapeHismToTargetStaticMesh:Length()))
    UNRCStatics.SetBattleGrassTypeWithHism(foliageHismToTargetStaticMesh, landscapeHismToTargetStaticMesh, cachedHismAndStaticMeshFromLandscape)
    local uobjectRefs = {}
    local cachedHismAndStaticMeshFromLandscapeTable = cachedHismAndStaticMeshFromLandscape:ToTable()
    for staticMesh, landscape in pairs(cachedHismAndStaticMeshFromLandscapeTable) do
      table.insert(uobjectRefs, UnLua.Ref(staticMesh))
      table.insert(uobjectRefs, UnLua.Ref(landscape))
    end
    battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscape = cachedHismAndStaticMeshFromLandscapeTable
    battleRuntimeData.battleGrassInfo.CachedHismFromFoliageActor = changedFoliageHism
    battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscapeRefs = uobjectRefs
    self.isChangeGrass = true
  end
end

function VBattleField:ResetGrass()
  if self.isChangeGrass then
    local battleRuntimeData = _G.BattleManager.battleRuntimeData
    local foliageActors = battleRuntimeData.battleGrassInfo.FoliageActorList or {}
    local cachedHismAndStaticMeshFromLandscape = battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscape or {}
    local changedFoliageHism = battleRuntimeData.battleGrassInfo.CachedHismFromFoliageActor or {}
    local validFoliageActors = {}
    for i, actor in ipairs(foliageActors) do
      if UE.UObject.IsValid(actor) then
        table.insert(validFoliageActors, actor)
      end
    end
    local validChangedFoliageHism = {}
    for i, component in ipairs(changedFoliageHism) do
      if UE.UObject.IsValid(component) then
        table.insert(validChangedFoliageHism, component)
      end
    end
    local TMap = UE4.TMap
    local validCachedHismAndStaticMeshFromLandscape = TMap(UE.UHierarchicalInstancedStaticMeshComponent, UE.UStaticMesh)
    for k, v in pairs(cachedHismAndStaticMeshFromLandscape) do
      if UE.UObject.IsValid(k) and UE.UObject.IsValid(v) then
        validCachedHismAndStaticMeshFromLandscape:Add(k, v)
      end
    end
    local UNRCStatics = UE4.UNRCStatics
    UNRCStatics.ResetBattleGrassTypeWithHism(validFoliageActors, validChangedFoliageHism, validCachedHismAndStaticMeshFromLandscape)
    local uobjectRefs = battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscapeRefs or {}
    for i, ref in ipairs(uobjectRefs) do
      if UE.UObject.IsValid(ref) then
        UnLua.Unref(ref)
      end
    end
    uobjectRefs = {}
    battleRuntimeData.battleGrassInfo.FoliageActorList = {}
    battleRuntimeData.battleGrassInfo.GrassStaticMeshPathList = {}
    battleRuntimeData.battleGrassInfo.foliageHismToTargetStaticMeshPathTable = {}
    battleRuntimeData.battleGrassInfo.landscapeHismToTargetStaticMeshPathTable = {}
    battleRuntimeData.battleGrassInfo.CachedHismFromFoliageActor = {}
    battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscape = {}
    battleRuntimeData.battleGrassInfo.CachedHismAndStaticMeshFromLandscapeRefs = {}
    self.isChangeGrass = false
  end
end

function VBattleField:SafeDelaySeconds(idName, ...)
  self.delaySafeCaller:SafeDelaySeconds(idName, ...)
end

function VBattleField:SafeDelayFrames(idName, ...)
  self.delaySafeCaller:SafeDelayFrames(idName, ...)
end

function VBattleField:SafeCancelDelayById(idName)
  self.delaySafeCaller:SafeCancelDelayById(idName)
end

function VBattleField:SafeFindDelayById(idName)
  return self.delaySafeCaller:SafeFindDelayById(idName)
end

function VBattleField:IsChangedGrass()
  return self.isChangeGrass
end

function VBattleField:TryChangeGrass()
  if self:IsChangedGrass() then
    return true
  end
  if self:CheckGrassResIsOver() then
    self:ChangeGrass()
    return true
  end
  return false
end

function VBattleField:GetBattleFieldRange()
  local baseRange = BattleConst.Define.BattleFieldRange
  local battleConf = BattleUtils.GetBattleConfig()
  local battleType = battleConf and battleConf.type or ProtoEnum.BattleType.BT_INVALID
  local multiplier = BattleConst.BattleTypeToBattleFieldRangeMultiplier[battleType]
  multiplier = multiplier or 1
  local finalRange = baseRange * multiplier
  return finalRange
end

function VBattleField:UnloadLightingScenarioLevel()
  local world = UE4Helper.GetCurrentWorld()
  if not world then
    return
  end
  if not self._cachedLightingScenarioStreamingLevels then
    return
  end
  local CurSceneID = SceneUtils.GetSceneID() or 0
  local CurSceneResID = SceneUtils.GetSceneResId()
  if 103 ~= CurSceneID or 50002 ~= CurSceneResID then
    return
  end
  local streamingLevels = world.StreamingLevels:ToTable()
  for _, streamingLevel in ipairs(streamingLevels) do
    if streamingLevel then
      local level = streamingLevel:GetLoadedLevel()
      if level and level.bIsLightingScenario then
        table.insert(self._cachedLightingScenarioStreamingLevels, streamingLevel)
        streamingLevel:SetShouldBeLoaded(false)
        streamingLevel:SetShouldBeVisible(false)
      end
    end
  end
end

function VBattleField:ReloadLightingScenarioLevel()
  if not self._cachedLightingScenarioStreamingLevels or 0 == #self._cachedLightingScenarioStreamingLevels then
    return
  end
  for _, streamingLevel in ipairs(self._cachedLightingScenarioStreamingLevels) do
    if streamingLevel then
      local packageName = streamingLevel:GetWorldAssetPackageFName()
      streamingLevel:SetShouldBeLoaded(true)
      streamingLevel:SetShouldBeVisible(true)
    end
  end
  self._cachedLightingScenarioStreamingLevels = {}
end

return VBattleField
