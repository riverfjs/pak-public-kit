local ViewNPCBase = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local Base = ViewNPCBase
local BP_NPC_Chair_Base_C = Base:Extend("BP_NPC_Chair_Base_C")

function BP_NPC_Chair_Base_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.ServerDetectRadius = false
end

function BP_NPC_Chair_Base_C:OnShouldDestroy()
  self:MakeCharactersAboveFall()
  if self.sceneCharacter and not self.sceneCharacter.notDestroyFlag then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, self.sceneCharacter.serverData.base.actor_id)
  end
end

function BP_NPC_Chair_Base_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  if self.sceneCharacter then
    local StaticMesh = self:GetComponentByClass(UE4.UStaticMeshComponent)
    if StaticMesh then
      StaticMesh:SetWorldScale3D(_G.FVectorOne * self.sceneCharacter:GetConfigScale())
    end
  end
end

function BP_NPC_Chair_Base_C:ReceiveBeginPlay()
  if UE4Helper.GetCurrentWorld() and self.SwitchMesh then
    self:SwitchMesh(true)
  end
  Base.ReceiveBeginPlay(self)
end

function BP_NPC_Chair_Base_C:ReceiveEndPlay(Reason)
  self:UnregisterFromPlayerToyComponent()
  Base.ReceiveEndPlay(self, Reason)
end

local Min = UE.FVector()
local Max = UE.FVector()

function BP_NPC_Chair_Base_C:GetInteractMarkHeight()
  local StaticMesh = self:GetComponentByClass(UE4.UStaticMeshComponent)
  if StaticMesh then
    StaticMesh:GetLocalBounds(Min, Max)
    local extend = Max.Z - Min.Z
    Min:Set(0, 0, 0)
    Max:Set(0, 0, 0)
    return extend
  else
    local MeshComp = self:GetComponentByClass(UE4.USkeletalMeshComponent)
    if MeshComp then
      local SkeletalMesh = MeshComp.SkeletalMesh
      if SkeletalMesh then
        local Bound = SkeletalMesh:GetBounds()
        return Bound.BoxExtent.Z * 2
      end
    end
  end
  return 0
end

local ExtentdHeight = 200
local DefaultExtend = UE.FVector(100, 100, ExtentdHeight)
local CachedResults = UE.TArray(UE.AActor)

function BP_NPC_Chair_Base_C:MakeCharactersAboveFall()
  local Characters = {}
  local Location = self:Abs_K2_GetActorLocation()
  Location.Z = Location.Z + ExtentdHeight + 1
  local bSuccess = UE.UKismetSystemLibrary.Abs_BoxOverlapActors(self, Location, DefaultExtend, {
    UE.EObjectTypeQuery.Pawn
  }, UE.ANPCBaseCharacter, nil, CachedResults)
  if bSuccess then
    for _, Character in tpairs(CachedResults) do
      if Character and UE.UObject.IsValid(Character) and Character.sceneCharacter then
        if Character.CharacterMovement and Character.CharacterMovement.ForceStoreIgnoreState then
          Character.CharacterMovement:ForceStoreIgnoreState(self)
        end
        UE.UNRCCharacterUtils.RequestCharacterMove(Character, FVectorDown, false, false)
      end
    end
  end
  CachedResults:Clear()
end

function BP_NPC_Chair_Base_C:SetSceneCharacter(sceneCharacter)
  Base.SetSceneCharacter(self, sceneCharacter)
  if not sceneCharacter then
    return
  end
  if sceneCharacter:IsLocal() then
    return
  end
  if self.ServerDetectRadius then
    return
  end
  self:RegisterToPlayerToyComponent()
  local npcId = sceneCharacter:GetConfigId()
  local propConf = _G.DataConfigManager:GetRoleplayPropConf(npcId, true)
  if not propConf then
    return
  end
  local radius = propConf.prop_server_radius
  if not radius or radius <= 0 then
    return
  end
  self.ServerDetectRadius = radius
  self.Tags:Add("PlayerToy")
end

function BP_NPC_Chair_Base_C:RegisterToPlayerToyComponent()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local toyComponent = localPlayer.playerToyComponent
  if not toyComponent then
    return
  end
  if toyComponent.RegisterToy then
    toyComponent:RegisterToy(self)
  end
end

function BP_NPC_Chair_Base_C:UnregisterFromPlayerToyComponent()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local toyComponent = localPlayer.playerToyComponent
  if not toyComponent then
    return
  end
  if toyComponent.UnregisterToy then
    toyComponent:UnregisterToy(self)
  end
end

return BP_NPC_Chair_Base_C
