local BattlePlayAnimBaseAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattlePlayAnimBaseAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Base = BattlePlayAnimBaseAction
local BattleLeaderBattleShowTimeAction = Base:Extend("BattleLeaderBattleShowTime")
FsmUtils.MergeMembers(Base, BattleLeaderBattleShowTimeAction, {})

function BattleLeaderBattleShowTimeAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleLeaderBattleShowTimeAction:OnEnter()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local target = BattleUtils.GetTraceNpc()
  if BattleUtils.IsWorldLeaderFight() then
    if not target or not target.npc.viewObj then
      self:Finish()
      return
    end
    local targetModel = target.npc.viewObj
    local position = targetModel:K2_GetActorLocation()
    local newPosition = UE4.UNRCStatics.PinActorOnGround(nil, targetModel, position, targetModel)
    local cameraManager = player.viewObj:GetController().PlayerCameraManager
    local cameraTransform = UE4.FTransform(cameraManager:GetCameraRotation():ToQuat(), cameraManager:GetCameraLocation(), FVectorOne)
    local bossTransform = targetModel:GetTransform()
    bossTransform.Scale3D = FVectorOne
    local worldRelativeTransform = UE.UKismetMathLibrary.MakeRelativeTransform(cameraTransform, bossTransform)
    local worldCameraFov = cameraManager:GetFOVAngle()
    local battleRuntimeData = _G.BattleManager.battleRuntimeData
    battleRuntimeData:SetWorldLeaderShowInfo(worldRelativeTransform, worldCameraFov)
    Log.Debug("BattleLeaderBattleShowTimeAction", cameraTransform, bossTransform, worldRelativeTransform, worldCameraFov)
    self:Finish()
  else
    local targetModel = target and target.npc.viewObj
    self:Play(player, {targetModel}, BattleConst.Define.LeaderBattleShowTime, true)
    _G.BattleManager:PlayBattleBGM()
  end
end

function BattleLeaderBattleShowTimeAction:OnHidePlayer()
  Log.Debug("BattlePlayBattleStandAnimAction OnHidePlayer")
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
end

function BattleLeaderBattleShowTimeAction:End()
  if BattleUtils.IsLeaderFight() then
    local Blackboard = self.skillObj:GetBlackboard()
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID1)
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID1_SA)
  end
end

function BattleLeaderBattleShowTimeAction:SaveObject(bb, name)
  Log.Debug("BattlePlayAnimBaseAction SaveObject:", name, bb:GetValueAsObject(name))
  self.fsm:SetProperty(name, bb:GetValueAsObject(name))
  bb:RemoveObjectValue(name)
end

function BattleLeaderBattleShowTimeAction:OnExit()
end

return BattleLeaderBattleShowTimeAction
