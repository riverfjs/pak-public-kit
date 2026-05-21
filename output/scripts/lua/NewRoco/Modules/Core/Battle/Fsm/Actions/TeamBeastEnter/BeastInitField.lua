local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local BeastInitField = Base:Extend("BeastInitField")
FsmUtils.MergeMembers(Base, BeastInitField, {})
local MaxFindTime = 20

function BeastInitField:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BeastInitField:OnEnter()
  self.CheckGap = 0.1
  self.waitTime = 0
  self.fsm:Pause()
  self:SetTimeoutValue(Base.PlayerSelectTime)
  self.timeout = Base.PlayerSelectTime
  self:TeleportPlayer()
  NRCEventCenter:DispatchEvent(BattleEvent.EnterBattle)
  BattleManager:OpenBattleMainWindow()
end

function BeastInitField:SetTillLevelLoadState()
  UE4.UNRCStatics.BlockTillLevelUnLoadCompleted(UE4Helper.GetCurrentWorld())
  UE4.UNRCStatics.ExecConsoleCommand("WorldTileTool.FreezeWorldComposition 1")
end

function BeastInitField:SpawnKamera(fov, AspectR, Constrain)
  local Camera = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ACameraActor, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  local CameraComp = Camera:GetComponentByClass(UE4.UCameraComponent)
  CameraComp.FieldOfView = fov
  CameraComp.AspectRatio = AspectR
  CameraComp.bConstrainAspectRatio = Constrain
  Camera.bCollideWhenPlacing = true
  return Camera
end

function BeastInitField:TransformCamera()
  local battleTransformCamera = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCamera, nil))
  if battleTransformCamera then
    local cameraSA = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCameraAS, nil))
    if cameraSA then
      cameraSA:DetachRootComponentFromParent(true)
      cameraSA:Abs_K2_SetActorLocation_WithoutHit(self.npcPos)
    end
  else
    battleTransformCamera = self:SpawnKamera(75, 2.15, false)
  end
  battleTransformCamera:Abs_K2_SetActorLocation_WithoutHit(self.npcPos, false, false)
  self.fsm:SetProperty(BattleConst.BattleSkipCamera, _G.ObjectRefBoxing(battleTransformCamera))
end

function BeastInitField:TeleportPlayer()
  self.npcPos = BattleManager.battleRuntimeData.TeleportBattleCenter
  if self.npcPos then
    self:SetTillLevelLoadState()
    NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
    NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportStart)
    self.LocalPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    BattleManager.TeleportBackPos = self.LocalPlayer.viewObj:Abs_K2_GetActorLocation()
    self.LocalPlayer.viewObj:SetActorTickEnabled(false)
    self.LocalPlayer.movementComponent:SetSyncMove(false)
    BattleManager.vBattleField:UnloadLightingScenarioLevel()
    BattleUtils.TeleportEnvActorInZ(self.npcPos.Z)
    self:FindBattleCenter()
  else
    self:Finish()
  end
end

function BeastInitField:PlayerTeleport(pos)
end

function BeastInitField:FindBattleCenter()
  if self.finished then
    return
  end
  local BattleCenterTable = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(_G.UE4Helper.GetCurrentWorld(), UE4.AActor, "LevelBattleCenter"):ToTable()
  if BattleCenterTable and #BattleCenterTable > 0 then
    if #BattleCenterTable > 1 then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\137\190\229\136\176\229\164\154\228\184\170LevelBattleCenter\239\188\129\239\188\129\239\188\129 \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\231\154\132\233\128\137\231\130\185\230\152\175\229\144\166\230\173\163\231\161\174!!!")
    end
    local BattleCenter = BattleCenterTable[1]
    self.npcPos = BattleCenter:Abs_K2_GetActorLocation()
    _G.BattleManager.battleRuntimeData.TeleportBattleCenter = self.npcPos
    _G.BattleManager.battleRuntimeData.ServerBattleRotate = BattleCenter:K2_GetActorRotation().Yaw
    _G.BattleManager.battleRuntimeData.teamBattleCenterTrans = BattleCenter:Abs_GetTransform()
    self.waitTime = 0
    self:PlayerTeleport(self.npcPos)
    self:TransformCamera()
    self:FindGround()
  else
    self.waitTime = self.waitTime + self.CheckGap
    if self.waitTime > MaxFindTime then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\230\136\152\229\156\186\228\184\173\229\191\131\231\130\185")
      self.waitTime = 0
      self:PlayerTeleport(self.npcPos)
      self:TransformCamera()
      self:FindGround()
    else
      self:SafeDelaySeconds("d_FindBattleCenter", self.CheckGap, self.FindBattleCenter, self)
    end
  end
end

function BeastInitField:FindGround()
  if self.finished then
    return
  end
  if self.waitTime > MaxFindTime or self:FindPointAtGround(self.npcPos, true) then
    if self.waitTime > MaxFindTime then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\229\156\176\233\157\162\239\188\129\239\188\129\239\188\129 \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\231\154\132\233\128\137\231\130\185\230\152\175\229\144\166\230\173\163\231\161\174!!! \230\156\172\229\156\186\230\136\152\230\150\151\231\154\132\233\128\137\231\130\185\228\184\186 ", self.npcPos)
    end
    BattleManager.battleRuntimeData.battleStartEnemyPos = self.npcPos
    self:Finish()
  else
    self.waitTime = self.waitTime + self.CheckGap
    self:SafeDelaySeconds("d_FindGround", self.CheckGap, self.FindGround, self)
  end
end

function BeastInitField:FindPointAtGround(pos, isWrite)
  local findPos, _, isHit = LineTraceUtils.GetPointValidLocationByLine(pos)
  if findPos and isHit then
    if isWrite then
      pos.X = findPos.X
      pos.Y = findPos.Y
      pos.Z = findPos.Z
    end
    return true
  else
    return false
  end
end

function BeastInitField:OnFinish()
  BattleManager.vBattleField:SetEnvVolumeForLoadLevel(true)
  self.fsm:Resume()
  self.LocalPlayer = nil
end

return BeastInitField
