local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleDelayExecuteActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleDelayExecuteActionBase")
local Base = BattleDelayExecuteActionBase
local BattleHideSceneTreesAction = Base:Extend("BattleHideSceneTreesAction")
FsmUtils.MergeMembers(Base, BattleHideSceneTreesAction, {})

function BattleHideSceneTreesAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleHideSceneTreesAction:OnEnter()
  Base.OnEnter(self)
  self:Finish()
end

function BattleHideSceneTreesAction:DelayRun()
  Base.DelayRun(self)
  local batleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("batleaf_hidden_distance").num
  UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(BattleManager.battleRuntimeData.NearbyValidBattleLocation, 1, BattleConst.HideObjectParam.HideGrassDist, batleaf_hidden_distance)
  self:ChangeBattleGrass()
  NRCModeManager:DoCmd(TaskModuleCmd.SetSplineVisible, false)
  if BattleConst.DonntHideTree then
    self:Finish()
    return
  end
  self.isShowDebugBox = false
  self:HideTreesInSphere()
  self:DelayComplete()
end

function BattleHideSceneTreesAction:ChangeBattleGrass()
  BattleManager.vBattleField:ChangeGrass()
end

function BattleHideSceneTreesAction:HideTreesInSphere()
  Log.Debug("BattleHideSceneTreesAction HideTreesInSphere:", BattleConst.Define.BattleFieldRange)
  if BattleConst.debugCloseHideScene then
    return
  end
  local playerPos = BattleManager.battleRuntimeData.TeleportBattleCenter
  local BattleFiledRangeSquare = 1000000
  local PropsActors = UE.UActorTagSubSystem.GetActorsByTag(_G.UE4Helper.GetCurrentWorld(), "LayerTag_PropsA")
  for i = 1, PropsActors:Length() do
    local OneActor = PropsActors:Get(i)
    local actorPos = OneActor:Abs_K2_GetActorLocation()
    if BattleFiledRangeSquare > UE4.FVector.DistSquared(actorPos, playerPos) then
      local RootComponent = OneActor:K2_GetRootComponent()
      local collisionEnabled = RootComponent and RootComponent:GetCollisionEnabled()
      if collisionEnabled == UE4.ECollisionEnabled.NoCollision then
        local Origin, Extend = OneActor:GetActorBounds()
        local visible = RootComponent and RootComponent:IsVisible()
        Log.Debug("hitactor is static mesh:", OneActor:GetName(), OneActor:IsA(UE4.AStaticMeshActor), Origin, Extend)
        if visible and OneActor:IsA(UE4.AStaticMeshActor) and not self:IsValidToShow(Extend.X, Extend.Y, Extend.Z) then
          Log.Debug("hitactor hide actor", OneActor:GetName(), Origin, Extend)
          OneActor:SetActorHiddenInGame(true)
          table.insert(BattleManager.battleRuntimeData.battleHideStaticMeshLst, OneActor)
        end
      end
    end
  end
end

function BattleHideSceneTreesAction:IsValidToShow(x, y, z)
  if x * y * z >= BattleConst.HideObjectParam.DonntHideVolume then
    return true
  end
  if x >= BattleConst.HideObjectParam.DonntHideSizeX or y >= BattleConst.HideObjectParam.DonntHideSizeY or z >= BattleConst.HideObjectParam.DonntHideSizeZ then
    return true
  else
    return false
  end
end

function BattleHideSceneTreesAction:GetTreeDict()
  return BattleManager.battleRuntimeData.battleHideTreeDict
end

function BattleHideSceneTreesAction:ClearTreeDict()
  BattleManager.battleRuntimeData.battleHideTreeDict = {}
end

function BattleHideSceneTreesAction:OnExit()
end

return BattleHideSceneTreesAction
