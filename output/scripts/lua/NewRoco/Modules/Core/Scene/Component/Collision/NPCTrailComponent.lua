local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local Base = ActorComponent
local NPCTrailComponent = Base:Extend("NPCTrailComponent")
local TriggerRange = 1000000
local LeaveTriggerRange = TriggerRange * 1.2

function NPCTrailComponent:Ctor(npc_trampling_lawn_comp)
  Base.Ctor(self)
  self.isTrigger = false
  self.npc_trampling_lawn_comp = npc_trampling_lawn_comp
end

function NPCTrailComponent:Attach(owner)
  Base.Attach(self, owner)
end

function NPCTrailComponent:DeAttach()
  Base.DeAttach(self)
  local OwnerView = self:GetOwnerView()
  if not UE4.UObject.IsValid(OwnerView) or not OwnerView.RegisterToTrailSystem then
    return
  end
  if self.isTrigger then
    OwnerView:UnRegisterFromTrailSystem()
    self.isTrigger = false
  end
end

function NPCTrailComponent:Destroy()
  Base.Destroy(self)
end

function NPCTrailComponent:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  local OwnerView = self:GetOwnerView()
  if not UE4.UObject.IsValid(OwnerView) or not OwnerView.RegisterToTrailSystem then
    return
  end
  if not OwnerView.resourceLoaded then
    return
  end
  local BornDieComponent = self.owner.BornDieComponent
  if BornDieComponent and BornDieComponent:IsPerforming() then
    return
  end
  if not self.npc_trampling_lawn_comp or 0 == self.npc_trampling_lawn_comp then
    return
  end
  if _G.GlobalConfig.DebugTrailBox and distance < TriggerRange then
    local Origin, Extend = OwnerView:GetActorBounds(true)
    UE.UKismetSystemLibrary.DrawDebugBox(_G.UE4Helper.GetCurrentWorld(), Origin, Extend, UE.FLinearColor(1, 0, 0, 1), UE.FRotator(0, 0, 0), 10, 5)
  end
  if distance < TriggerRange and not self.isTrigger then
    local DetectType = UE4.ENRCTrailFootstepDetectType.OneTime
    if self.npc_trampling_lawn_comp == _G.Enum.TramplingLawnComp.TLC_DYNAMIC then
      Log.Error("\229\166\130\230\158\156\231\148\168\229\138\168\230\128\129\230\163\128\230\181\139\228\188\154\229\146\140\231\142\176\230\156\137\233\128\187\232\190\145\229\134\178\231\170\129\239\188\140\229\166\130\230\158\156\231\161\174\229\174\158\230\156\137\233\156\128\232\166\129\232\175\183\230\137\190dzymli/marvynwang\231\156\139\231\156\139\229\133\183\228\189\147\230\152\175\228\187\128\228\185\136\230\131\133\229\134\181\239\188\140\232\139\165\230\151\160\229\191\133\232\166\129\232\175\183\228\189\191\231\148\168Static\231\137\136\230\156\172")
    end
    OwnerView:RegisterToTrailSystem(DetectType)
    self.isTrigger = true
  elseif distance >= LeaveTriggerRange and self.isTrigger then
    OwnerView:UnRegisterFromTrailSystem()
    self.isTrigger = false
  end
end

function NPCTrailComponent.GetTramplingLawnComp(config)
  if not config then
    return nil
  end
  local npc_trampling_lawn_comp = config and config.npc_trampling_lawn_comp
  if npc_trampling_lawn_comp and 0 ~= npc_trampling_lawn_comp then
    return npc_trampling_lawn_comp
  end
  local model_conf_id = config.model_conf
  local model_conf = _G.DataConfigManager:GetModelConf(model_conf_id, true)
  local model_trampling_lawn_comp = model_conf and model_conf.trampling_lawn_comp
  if model_trampling_lawn_comp and 0 ~= model_trampling_lawn_comp then
    return model_trampling_lawn_comp
  end
  return nil
end

return NPCTrailComponent
