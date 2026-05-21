require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local BP_NPCSupplyMachine_C = Base:Extend("BP_NPCSupplyMachine_C")

function BP_NPCSupplyMachine_C:OnFrameLoad(distanceRatio)
  local meshRes = UE4.UKismetSystemLibrary.LoadAsset_Blocking(self.MeshRes)
  self.SkeletalMesh:SetSkeletalMesh(meshRes)
  self.frameLoaded = true
  Base.OnFrameLoad(self, distanceRatio)
end

function BP_NPCSupplyMachine_C:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.frameLoaded and self.meshOptVisible ~= bulkyVisible then
    self:K2_GetRootComponent():SetVisibility(bulkyVisible, true)
    self.meshOptVisible = bulkyVisible
  end
end

return BP_NPCSupplyMachine_C
