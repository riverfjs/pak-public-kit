local BattlePlayAnimBaseAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattlePlayAnimBaseAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleTeam = require("NewRoco.Modules.Core.Battle.Entity.BattleTeam")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local Base = BattlePlayAnimBaseAction
local BattlePvePlayBattleStandAnimAction = Base:Extend("BattlePvePlayBattleStandAnimAction")
FsmUtils.MergeMembers(Base, BattlePvePlayBattleStandAnimAction, {})

function BattlePvePlayBattleStandAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattlePvePlayBattleStandAnimAction:OnEnter()
  self.invisibleNPCLst = {}
  self.Player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.Target = BattleUtils.GetTraceNpc()
  if not self.Target or not self.Target.npc.viewObj then
    Log.Error("zgx Target is nil!!!!")
    self:Finish()
    return
  end
  if BattleUtils.ContainTaskPerformControl(Enum.TaskBattlePerformanceControl.TBPC_ENTER_SKIP) then
    self:Finish()
    return
  end
  local enterSkillPath = BattleConst.Define.NPCEnter
  Log.Debug("BattlePvePlayBattleStandAnimAction target type:", self.Target.npc, type(self.Target.npc))
  self:Play(self.Target.npc, {
    self.Player.viewObj
  }, enterSkillPath, true)
end

function BattlePvePlayBattleStandAnimAction:OnSetSkillObj(skillObj)
  if skillObj then
    local blackboard = skillObj:GetBlackboard()
    if blackboard then
      Log.Msg("BattlePvePlayBattleStandAnimAction OnSetSkillObj")
      blackboard:SetValueAsInt("IsSkip", 1)
      local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      local cameraManager = player.viewObj:GetController().PlayerCameraManager
      local cameraTransform = UE4.FTransform(cameraManager:GetCameraRotation():ToQuat(), cameraManager:GetCameraLocation(), _G.FVectorOne)
      blackboard:SetValueAsTransform("StartTransform", cameraTransform)
    end
  end
end

function BattlePvePlayBattleStandAnimAction:ProcessMimic()
  if not self.Target then
    return
  end
  local HidComp = self.Target.npc.HiddenComponent
  if HidComp and HidComp:GetHiddenType() == Enum.WorldHide.WH_MIMIC_OPTION then
    HidComp:UnpinToGround(true)
    HidComp:EndHide(self, function()
    end)
  end
end

function BattlePvePlayBattleStandAnimAction:CreateCameraPos()
  self.CameraPos = _G.UE4Helper.GetCurrentWorld():SpawnActor(UE4.AActor, self.Target.npc:GetActorTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.CameraPos:AddComponentByClass(UE4.USceneComponent, false, UE4.FTransform(), false)
  local aPos = self.Target.npc:GetActorLocation()
  local bPos = self.Player:GetActorLocation()
  local dir = bPos - aPos
  dir.Z = 0
  self.CameraPos:Abs_K2_SetActorLocation_WithoutHit(aPos)
  self.CameraPos:K2_SetActorRotation(dir:ToRotator(), true)
end

function BattlePvePlayBattleStandAnimAction:OnHidePlayer()
  Log.Debug("BattlePvePlayBattleStandAnimAction OnHidePlayer")
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
end

function BattlePvePlayBattleStandAnimAction:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattlePvePlayBattleStandAnimAction:SaveBattleCam()
  local Blackboard = self.skillObj.Blackboard
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
end

function BattlePvePlayBattleStandAnimAction:OnFinish()
  Base.OnFinish(self)
  Log.Msg("BattlePvePlayBattleStandAnimAction OnFinish")
  if self.CameraPos then
    self.fsm:SetProperty(BattleConst.BattleStand.CameraRoot, self.CameraPos)
  end
  self:RevertTargetRootMotion()
  for npcActor, v in pairs(self.invisibleNPCLst) do
    if UE4.UObject.IsValid(npcActor) then
      npcActor:SetActorHiddenInGame(false)
    end
  end
  self.invisibleNPCLst = {}
  self.Target = nil
  self.Player = nil
end

function BattlePvePlayBattleStandAnimAction:RevertTargetRootMotion()
  if self.Target then
    self.Target.npc:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromMontagesOnly)
  end
end

function BattlePvePlayBattleStandAnimAction:SaveObject(bb, name)
  self.fsm:SetProperty(name, bb:GetValueAsObject(name))
  bb:RemoveObjectValue(name)
end

function BattlePvePlayBattleStandAnimAction:OnExit()
  self:RevertTargetRootMotion()
  self.invisibleNPCLst = nil
  self.Target = nil
end

function BattlePvePlayBattleStandAnimAction:OnTick(DeltaTime)
  self:HideNPC()
end

function BattlePvePlayBattleStandAnimAction:HideNPC()
  if self.camera and UE4.UObject.IsValid(self.camera) then
    local loc = self.camera:Abs_K2_GetActorLocation()
    local forward = self.camera:GetActorForwardVector()
    if not forward then
      Log.Error("BattlePvePlayBattleStandAnimAction HideNPC forward is nil")
      return
    end
    local traceColor, traceHitColor
    local traceTime = 0
    if false then
      traceColor = UE4.FLinearColor(0, 1, 1, 1)
      traceHitColor = UE4.FLinearColor(1, 0, 0, 1)
      traceTime = 10
    end
    local channel = {
      UE4.ECollisionChannel.ECC_Pawn
    }
    local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), loc, loc + forward * 100, channel, true, nil, UE4.EDrawDebugTrace.None, nil, true, traceColor, traceHitColor, traceTime)
    if isHit then
      for i = hitResults:Length(), 1, -1 do
        local Hit = hitResults:Get(i)
        local hitActor = Hit.Actor
        if hitActor ~= self.Target.npc then
          hitActor:SetActorHiddenInGame(true)
          self.invisibleNPCLst[hitActor] = 1
        end
      end
    end
  end
end

return BattlePvePlayBattleStandAnimAction
