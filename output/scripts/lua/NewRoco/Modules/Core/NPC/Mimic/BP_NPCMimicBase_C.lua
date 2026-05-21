local ViewNPCBase = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local Base = ViewNPCBase
local BP_NPCMimicBase_C = Base:Extend("BP_NPCMimicBase_C")

function BP_NPCMimicBase_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.mimicVisibility = false
end

function BP_NPCMimicBase_C:GetHalfHeight()
  return 0
end

function BP_NPCMimicBase_C:OnVisible()
  Base.OnVisible(self)
  self:ApplyVisibilityState()
end

function BP_NPCMimicBase_C:SetMimicVisibility(flag)
  if flag ~= self.mimicVisibility then
    self.mimicVisibility = flag
    self:ApplyVisibilityState()
  end
end

function BP_NPCMimicBase_C:ApplyVisibilityState()
  if self.StaticMesh then
    self.StaticMesh:SetHiddenInGame(not self.mimicVisibility, true)
  end
  if self.SkeletalMesh then
    self.SkeletalMesh:SetHiddenInGame(not self.mimicVisibility, true)
  end
end

function BP_NPCMimicBase_C:RegisterToTrailSystem(DetectType)
  if not UE4.UObject.IsValid(self) then
    return
  end
  Log.Debug("ViewNPCBase:RegisterToTrailSystem", self:GetDebugInfo())
  local NRCTrailSystem = UE4.ANRCTrailSystem.Get(self)
  DetectType = DetectType or UE4.ENRCTrailFootstepDetectType.OneTime
  local Origin, Extend = self:GetActorBounds(false)
  NRCTrailSystem:RegisterObjectByActor(self, DetectType, Origin, Extend)
end

function BP_NPCMimicBase_C:GetExplodeLocation()
  local vec = self:Abs_K2_GetActorLocation()
  return UE4.FVector(vec.X, vec.Y, vec.Z + 70)
end

function BP_NPCMimicBase_C:CanEnterThrowInter(Comp)
  return Comp == self.StaticMesh
end

local VecCache_Min = UE.FVector()
local VecCache_Max = UE.FVector()

function BP_NPCMimicBase_C:GetHeadWidgetOffsetInplace(transform)
  if self.SkeletalMesh and self.SkeletalMesh:DoesSocketExist("locator_hp") then
    UE4.UNRCStatics.GetSocketTransformInplace(self.SkeletalMesh, "locator_hp", transform, UE.ERelativeTransformSpace.RTS_Component)
    transform.Rotation = UE4Helper.IdentityRotator
    return true
  end
  if self.StaticMesh then
    self.StaticMesh:GetLocalBounds(VecCache_Min, VecCache_Max)
    local TranslationRef = transform.Translation
    TranslationRef.X = 0
    TranslationRef.Y = 0
    TranslationRef.Z = math.abs(VecCache_Max.Z - VecCache_Min.Z) + 60
    return true
  end
  return false
end

return BP_NPCMimicBase_C
