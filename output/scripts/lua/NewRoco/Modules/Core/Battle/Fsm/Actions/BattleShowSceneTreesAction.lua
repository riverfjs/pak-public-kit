local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleDelayExecuteActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleDelayExecuteActionBase")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleDelayExecuteActionBase
local BattleShowSceneTreesAction = Base:Extend("BattleShowSceneTreesAction")
FsmUtils.MergeMembers(Base, BattleShowSceneTreesAction, {})

function BattleShowSceneTreesAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleShowSceneTreesAction:OnEnter()
  Base.OnEnter(self)
  self:Finish()
end

function BattleShowSceneTreesAction:DelayRun()
  Base.DelayRun(self)
  local normalleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("normalleaf_hidden_distance").num
  local climbleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("climbleaf_hidden_distance").num
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
    UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(BattleManager.battleRuntimeData.NearbyValidBattleLocation, 0, BattleConst.HideObjectParam.ExitBattleShowGrassDist, climbleaf_hidden_distance)
  else
    UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(BattleManager.battleRuntimeData.NearbyValidBattleLocation, 0, BattleConst.HideObjectParam.ExitBattleShowGrassDist, normalleaf_hidden_distance)
  end
  self:ResetBattleGrass()
  NRCModeManager:DoCmd(TaskModuleCmd.SetSplineVisible, true)
  if BattleConst.DonntHideTree then
    self:DelayComplete()
    return
  end
  Log.Debug("BattleShowSceneTreesAction OnEnter")
  self:ShowTrees()
  self:DelayComplete()
end

function BattleShowSceneTreesAction:ShowTrees()
  for i, v in pairs(self:GetTreeDict()) do
    local treeComponent = v[1].Component
    local treeItem = v[1].Item
    for i = 2, #v do
      v[i].Scale3D = UE4.FVector(1, 1, 1)
      treeComponent:UpdateInstanceTransform(treeItem, v[i], false)
    end
  end
  self:ClearTreeDict()
  local staticMeshTreeLst = BattleManager.battleRuntimeData.battleHideStaticMeshLst
  for i = 1, #staticMeshTreeLst do
    if staticMeshTreeLst[i] and UE.UObject.IsValid(staticMeshTreeLst[i]) then
      staticMeshTreeLst[i]:SetActorHiddenInGame(false)
    end
  end
  BattleManager.battleRuntimeData.battleHideStaticMeshLst = {}
end

function BattleShowSceneTreesAction:GetTreeDict()
  return BattleManager.battleRuntimeData.battleHideTreeDict
end

function BattleShowSceneTreesAction:ClearTreeDict()
  BattleManager.battleRuntimeData.battleHideTreeDict = {}
end

function BattleShowSceneTreesAction:ResetBattleGrass()
  BattleManager.vBattleField:ResetGrass()
end

function BattleShowSceneTreesAction:OnExit()
end

return BattleShowSceneTreesAction
