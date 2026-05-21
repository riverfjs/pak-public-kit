local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local Base = ActorComponent
local PetInteractOptionComponent = Base:Extend("PetInteractOptionComponent")

function PetInteractOptionComponent:Ctor()
  Base.Ctor(self)
end

function PetInteractOptionComponent:Attach(owner)
  Base.Attach(self, owner)
end

function PetInteractOptionComponent:DeAttach()
  Base.DeAttach(self)
end

function PetInteractOptionComponent:Destroy()
  Base.Destroy(self)
end

function PetInteractOptionComponent:TryRecycle(player_id)
  if nil == not player_id then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    player_id = localPlayer and localPlayer.serverData.base.actor_id
  end
  local view = self:GetOwnerView()
  if not view then
    Log.Error("PetInteractOptionComponent:TryRecycle: Owner View is nil")
    return
  end
  if view.ThrowSession and not view.ThrowSession:IsRecycling() then
    view.ThrowSession:SetStatus(ThrowSessionStatusEnum.PostInteract)
    if view.ThrowSession.shouldForceRecycle then
      view.ThrowSession:Recycle()
    elseif self:CheckNeedInteract(player_id, view.ThrowSession:GetGID()) then
      local AIComp = self.owner:EnsureComponent(AIComponent)
      AIComp:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
      view.sceneCharacter:EnsureComponent(PetHUDComponent):ForceUpdate()
    elseif NRCModuleManager:DoCmd(FarmModuleCmd.OnCmdGetIsInFarm) then
      local AIComp = self.owner:EnsureComponent(AIComponent)
      AIComp:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
      view.sceneCharacter:EnsureComponent(PetHUDComponent):ForceUpdate()
    else
      view.ThrowSession:Recycle()
    end
  else
    view:FlyBackToPlayer()
  end
end

function PetInteractOptionComponent:GetInteractQuantity(player_id, gid)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, player_id)
  if not player or player.petInfoMap == nil or player.petInfoMap[gid] == nil then
    Log.Warning("GetInteractQuantity get pet info error :  ", player_id, gid)
    return 0, math.maxinteger
  end
  local pet_info = player.petInfoMap[gid]
  return pet_info.interact_quantity or 0, pet_info.interact_quantity_threshold or 0
end

function PetInteractOptionComponent:CheckNeedInteract(player_id, gid)
  local interact_quantity, interact_quantity_threshold = self:GetInteractQuantity(player_id, gid)
  return interact_quantity_threshold <= interact_quantity
end

function PetInteractOptionComponent:ShowInteractQuantity()
  local World = _G.UE4Helper.GetCurrentWorld()
  local Location = _G.FVectorZero
  local ColorRed = UE.FLinearColor(1, 0, 0, 1)
  local interact_quantity, threshold = self:GetInteractQuantity(self.owner.serverData.base.owner_id, self.owner.serverData.pet_info.gid)
  local Text = string.format("%s: %d/%d", self.owner.serverData.base.name, interact_quantity, threshold)
  UE.UKismetSystemLibrary.DrawDebugString(World, Location, Text, self.owner.viewObj, ColorRed, 5)
end

return PetInteractOptionComponent
