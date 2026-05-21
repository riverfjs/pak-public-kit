local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local TeleportBackAction = BattleActionBase:Extend("TeleportBackAction")

function TeleportBackAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
end

function TeleportBackAction:OnEnter()
  _G.NRCSDKManager:PerfBeginExclude("TeleportBack")
  self.CheckGap = 0.2
  self.IsSendTeleport = false
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not self.localPlayer then
    Log.Error("zgx \232\142\183\229\143\150\228\184\141\229\136\176\230\156\172\229\156\176\232\167\146\232\137\178\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129")
    self:Finish()
  end
  local TeleportBackPos = _G.BattleManager.TeleportBackPos
  if TeleportBackPos then
    self:PrepareNpc()
    self:StartTeleportBack(TeleportBackPos)
  else
    local battleCenter = _G.BattleManager.battleRuntimeData.TeleportBattleCenter
    local playerPos = self.localPlayer:GetActorLocation()
    if battleCenter and battleCenter:Dist2D(playerPos) >= 10000 then
      self:StartTeleportBack(playerPos)
    else
      self:Finish()
    end
  end
end

function TeleportBackAction:StartTeleportBack(pos)
  self.waitTime = 0
  self.IsSendTeleport = true
  self.npcPos = pos
  local battleTransformCamera = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCamera, nil))
  if battleTransformCamera then
    local forward = self.localPlayer:GetForwardVector()
    local cameraPos = UE4.FVector(pos.X, pos.Y, pos.Z + 500) - forward * 500
    battleTransformCamera:Abs_K2_SetActorLocation_WithoutHit(cameraPos)
    self.localPlayer.ueController.PlayerCameraManager.blendBackImmediately = true
    self.localPlayer.ueController:SetViewTargetWithBlend(battleTransformCamera, 0)
    self.localPlayer:SetActorLocation(self.npcPos)
  else
    self.localPlayer.ueController:ReleaseRocoCamera(0, nil, nil, true)
    self.localPlayer:SetActorLocation(self.npcPos)
  end
  if BattleUtils.IsTeam() or BattleUtils.IsWeeklyChallenge() or BattleUtils.IsTrainBattle() then
    BattleManager.vBattleField:ReloadLightingScenarioLevel()
    UE4.UNRCStatics.ExecConsoleCommand("WorldTileTool.FreezeWorldComposition 0")
    UE4.UNRCStatics.BlockTillLevelLoadCompleted(UE4Helper.GetCurrentWorld())
    self:TeleportEnvActorInZ(BattleManager.EnvActorZ)
  end
  self:CheckGround()
end

function TeleportBackAction:TeleportEnvActorInZ(zValue)
  if not zValue then
    Log.Error("zgx TeleportEnvActorInZ failed\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129")
    return
  end
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if EnvSys then
    local CurEnvActor = EnvSys:GetEnvActor()
    if CurEnvActor then
      local rootComponent = CurEnvActor:K2_GetRootComponent()
      if rootComponent then
        rootComponent:SetMobility(UE4.EComponentMobility.Movable)
        local pos = CurEnvActor:Abs_K2_GetActorLocation()
        CurEnvActor:Abs_K2_SetActorLocation(UE.FVector(pos.X, pos.Y, zValue), false, nil, false)
        CurEnvActor.IsUseCertainTodVolume = false
        rootComponent:SetMobility(UE4.EComponentMobility.Static)
      end
    end
  end
end

function TeleportBackAction:PrepareNpc()
  self.SceneNpcs = {}
  if BattleUtils.IsBloodTeam() and _G.BattleManager.battleRuntimeData.IsCatchSuccessInBloodTeam then
    return
  end
  local battleNpc = _G.BattleManager.battleRuntimeData:GetAllNPCs()
  if battleNpc then
    for _, npcInfo in ipairs(battleNpc) do
      local npc = npcInfo.npc
      if npc and (not npc.viewObj or npc.viewObj.resourceLoading) then
        npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.SceneNpcLoadOver)
        table.insert(self.SceneNpcs, npc)
      end
    end
  end
end

function TeleportBackAction:CheckGround()
  if self.active then
    if self.waitTime > 20 or self:FindPointAtGround(self.npcPos) then
      if self.HitPos then
        self.HitPos.Z = self.HitPos.Z + self.localPlayer.viewObj:GetHalfHeight()
        if math.abs(self.HitPos.Z - self.npcPos.Z) > 20 and self.waitTime <= 20 then
          self.waitTime = 0
          self:FindGroundOver()
          return
        end
      else
        Log.Error("\231\187\147\231\174\151\228\188\160\233\128\129\229\135\186\231\142\176\233\151\174\233\162\152\239\188\129\239\188\129\239\188\129  30s\229\134\133\228\187\141\231\132\182\230\178\161\230\156\137\230\137\190\229\136\176\232\144\189\232\132\154\231\130\185")
      end
      self.waitTime = 0
      self:FindGroundOver()
    else
      self.waitTime = self.waitTime + self.CheckGap
      self:SafeDelaySeconds("d_CheckGround", self.CheckGap, self.CheckGround, self)
    end
  end
end

function TeleportBackAction:FindGroundOver()
  self.FindGround = true
  if self:CheckBackOver() then
    self:Finish()
  else
    self:SafeDelaySeconds("d_Finish", 5, self.Finish, self)
  end
end

function TeleportBackAction:SceneNpcLoadOver(npc)
  if self.SceneNpcs then
    for i = 1, #self.SceneNpcs do
      if self.SceneNpcs[i] == npc.sceneCharacter then
        npc.sceneCharacter:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.SceneNpcLoadOver)
        table.remove(self.SceneNpcs, i)
        break
      end
    end
    if self:CheckBackOver() and self.active then
      self:Finish()
    end
  end
end

function TeleportBackAction:CheckBackOver()
  if not self.SceneNpcs or 0 == #self.SceneNpcs then
    return self.FindGround
  end
end

function TeleportBackAction:FindPointAtGround(pos)
  self.HitPos = LineTraceUtils.GetPointValidLocationByLine(pos, nil, true)
  return self.HitPos
end

function TeleportBackAction:OnFinish()
  if self.localPlayer then
    if UE.UObject.IsValid(self.localPlayer.viewObj) then
      self.localPlayer:SetActorLocation(self.npcPos)
      self.localPlayer.viewObj:SetActorTickEnabled(true)
      self.localPlayer.movementComponent:SetSyncMove(true)
    end
    NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, false)
    if self.IsSendTeleport then
      UE4.UNRCStatics.ChangeLevelStreamingMode(0)
      NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportFinish)
    end
  end
  self.SceneNpcs = nil
  _G.BattleManager.battleRuntimeData.NpcIDs = nil
  _G.BattleManager.TeleportBackPos = nil
end

function TeleportBackAction:OnExit()
  _G.NRCSDKManager:PerfEndExclude("TeleportBack")
end

return TeleportBackAction
