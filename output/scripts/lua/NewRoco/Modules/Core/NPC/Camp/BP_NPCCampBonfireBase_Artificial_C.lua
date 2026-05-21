local Base = require("NewRoco.Modules.Core.NPC.Camp.BP_NPCCampBonfireBase_C")
local MagicCreationUtils = require("NewRoco.Modules.System.MagicCreation.MagicCreationUtils")
local EnterCampLoopCameraLoc = UE4.FVector(662.996643, 893.041321, 171.135284)
local PetWarehouseLoopCameraLoc = UE4.FVector(221.337646, 828.200928, 200.131775)
local PlayerCampLoc = UE4.FVector(-80, 240, 45)
local PetCampLoc = UE4.FVector(211, 116, 25)
local CameraCheckNum = 9
local CameraCheckAngleEach = 360.0 / CameraCheckNum
local cameraMoreYaw = 10.0
local BP_NPCCampBonfireBase_Artificial_C = Base:Extend("BP_NPCCampBonfireBase_Artificial_C")

function BP_NPCCampBonfireBase_Artificial_C:PlayActivateEffect(bPlaySkill)
  Log.Debug("BP_NPCCampBonfireBase_Artificial_C:PlayActivateEffect", bPlaySkill)
  Base.PlayActivateEffect(self, false)
end

function BP_NPCCampBonfireBase_Artificial_C:UpdateData(ServerData, bIsReconnect)
  if bIsReconnect and self.hasRecycled and self.sceneCharacter.updateEnable then
    MagicCreationUtils.UndoDeleteEffect(self.sceneCharacter)
    local mesh = self.NRCSkeletalMesh
    mesh:SetVisibility(true, true)
  end
end

function BP_NPCCampBonfireBase_Artificial_C:OnRecycle()
  self:ClearPet()
end

function BP_NPCCampBonfireBase_Artificial_C:UndoRecycle()
  self:TryAppearLulu()
end

local CameraCheckExtent = UE4.FVector(15, 15, 15)

function BP_NPCCampBonfireBase_Artificial_C:TryAdjustRotationOnTransfer()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerSelfCharacter = localPlayer.viewObj
  
  local function judgeHitResult(hitResult)
    if not hitResult then
      return false
    end
    local comp = hitResult.Component
    if not UE4.UObject.IsValid(comp) then
      return false
    end
    local collisionEnabled = comp:GetCollisionEnabled()
    if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
      return false
    end
    return true
  end
  
  local world = _G.UE4Helper.GetCurrentWorld()
  local channel = UE4.ECollisionChannel.ECC_Camera
  local traceObjectTypes = {
    UE4.EObjectTypeQuery.WorldStatic,
    UE4.EObjectTypeQuery.WorldDynamic,
    UE4.EObjectTypeQuery.Character,
    UE4.EObjectTypeQuery.Pawn,
    UE4.EObjectTypeQuery.Vehicle,
    UE4.EObjectTypeQuery.Tree
  }
  local drawDebugType = UE4.EDrawDebugTrace.None
  local traceColor, traceHitColor
  local duration = 0
  local bCanDrawDebug = _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.GetCanDrawDebug)
  if bCanDrawDebug then
    drawDebugType = UE4.EDrawDebugTrace.ForDuration
    traceColor = UE4.FLinearColor(0.6, 1, 0, 1)
    traceHitColor = UE4.FLinearColor(0.7, 0.2, 0.2, 1)
    duration = 30.0
  end
  
  local function checkLocValid(start, targets)
    for _, target in pairs(targets) do
      local direction = target - start
      local rotation = direction:ToRotator()
      local hitResults, bSuccess = UE4.UKismetSystemLibrary.BoxTraceMultiForObjects(world, start, target, CameraCheckExtent, rotation, traceObjectTypes, false, {self, playerSelfCharacter}, drawDebugType, nil, true, traceColor, traceHitColor, duration)
      if bSuccess then
        for _, hitResult in pairs(hitResults) do
          if judgeHitResult(hitResult) then
            if bCanDrawDebug then
              UE4.UKismetSystemLibrary.DrawDebugString(world, hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(0.9, 0.1, 0, 0.9), duration)
            end
            return false
          end
        end
      end
    end
    return true
  end
  
  local bSucceed = false
  local origin = self:K2_GetActorLocation()
  local center = origin + UE4.FVector(0, 0, self.Capsule:GetScaledCapsuleHalfHeight())
  local rotateAxis = UE4.FVector(0, 0, 1)
  for idx = 0, CameraCheckNum - 1 do
    local angle = idx * CameraCheckAngleEach
    local cameraAngle = angle + cameraMoreYaw
    local cameraALoc = origin + EnterCampLoopCameraLoc:RotateAngleAxis(cameraAngle, rotateAxis)
    local cameraLocs = {cameraALoc}
    local playerLoc = origin + PlayerCampLoc:RotateAngleAxis(cameraAngle, rotateAxis)
    local petLoc = origin + PetCampLoc:RotateAngleAxis(cameraAngle, rotateAxis)
    for _, loc in pairs(cameraLocs) do
      if not checkLocValid(loc, {
        center,
        playerLoc,
        petLoc
      }) then
        goto lbl_175
      end
    end
    if not self:CheckTransferSpaceSufficient({playerLoc, petLoc}) then
    else
      self:K2_SetActorRotation(UE4.FRotator(0, angle, 0), false)
      bSucceed = true
      Log.Debug("BP_NPCCampBonfireBase_Artificial_C:TryAdjustRotationOnTransfer correct", idx, angle)
      break
    end
    ::lbl_175::
  end
  return bSucceed
end

function BP_NPCCampBonfireBase_Artificial_C:CheckTransferSpaceSufficient(locations)
  local selfLocation = self:K2_GetActorLocation()
  local moreCheckSize = 50
  if locations then
    for _, loc in pairs(locations) do
      if not loc then
      else
        if MagicCreationUtils.CheckHeightDifferenceTooMuchBetweenNpcAndInteractPoint(selfLocation, loc) then
          return false
        end
        local delta = loc - selfLocation
        delta = delta / delta:Size()
        local moreCheckLocation = loc + delta * moreCheckSize
        if MagicCreationUtils.CheckHeightDifferenceTooMuchBetweenNpcAndInteractPoint(selfLocation, moreCheckLocation) then
          return false
        end
      end
    end
  end
  return true
end

return BP_NPCCampBonfireBase_Artificial_C
