local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local PreProcessEnterBattleAction = BattleActionBase:Extend("PreProcessEnterBattleAction")
local MaxCheckTime = 20
local MaxFindTime = 20

function PreProcessEnterBattleAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
end

function PreProcessEnterBattleAction:OnEnter()
  self.CheckGap = 0.2
  self.fsm:Pause()
  BattleManager:PauseFocusTimer()
  self:SetTimeoutValue(BattleActionBase.PlayerSelectTime * 2)
  self.timeout = BattleActionBase.PlayerSelectTime * 2
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Close_AllTips)
  self.isPvp = BattleUtils.IsPvp()
  self.isAutoBattle = _G.BattleAutoTest.IsAutoBattle
  self.isTeam = BattleUtils.IsTeam()
  self.isStartTeleport = false
  self.IsCloseLoading = false
  self.hasGrassPreProcessExecuted = false
  self.npcPos = _G.BattleManager.battleRuntimeData.TeleportBattleCenter
  if self.isPvp and not self.isAutoBattle then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.EnterPVP)
  end
  Log.Debug("PreProcessEnterBattleAction:OnEnter")
  if self:CheckNeedTeleport() then
    if self.isPvp and not self.isAutoBattle then
      if not BattleUtils.HasUI("BattleLoading") and not BattleUtils.HasUI("TransformLoading") and not BattleUtils.HasUI("PVP_Prepare") then
        self.IsCloseLoading = true
        local asyncData = {
          owner = self,
          callback = self.CheckStartTeleport
        }
        NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenLoading)
        self:SafeDelaySeconds("d_CheckStartTeleport", 3, self.CheckStartTeleport, self)
      else
        self:CheckStartTeleport()
      end
    elseif BattleUtils.IsB1FinalBattleP1() then
      self:CheckStartTeleport()
    else
      local CameraAS = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCameraAS))
      if CameraAS then
        CameraAS:DetachRootComponentFromParent(true)
        self:CheckStartTeleport()
        return
      end
      local hasLoadingCurtain = _G.NRCModeManager:DoCmd(LevelSelectionModuleCmd.HasLoadingCurtain) or BattleUtils.IsWeeklyChallenge()
      if not BattleUtils.HasUI("BattleLoading") and not BattleUtils.HasUI("TransformLoading") and not hasLoadingCurtain then
        self.IsCloseLoading = true
        local asyncData = {
          owner = self,
          callback = self.CheckStartTeleport
        }
        NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenLoading)
        self:SafeDelaySeconds("d_CheckStartTeleport", 3, self.CheckStartTeleport, self)
      else
        self:CheckStartTeleport()
      end
    end
  else
    self:PreProcessBattleGrassChange()
  end
end

function PreProcessEnterBattleAction:CheckNeedTeleport()
  if self.npcPos then
    if self.isTeam or BattleUtils.IsWeeklyChallenge() or BattleUtils.IsB1FinalBattle() or BattleUtils.IsTrainBattle() then
      return true
    end
    if not self:FindPointAtGround(self.npcPos) then
      return true
    else
      self.LocalPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      local playerPos = self.LocalPlayer:GetActorLocation()
      if playerPos:Dist2D(self.npcPos) >= 10000 then
        return true
      end
    end
  end
  return false
end

function PreProcessEnterBattleAction:CheckStartTeleport()
  if not self.active then
    return
  end
  if not self.isStartTeleport then
    self.isStartTeleport = true
    self:StartTeleport()
  end
end

function PreProcessEnterBattleAction:LoadBattleLevel()
  if self.isTeam or BattleUtils.IsWeeklyChallenge() or BattleUtils.IsTrainBattle() then
    BattleUtils.TeleportEnvActorInZ()
    local scenePath = _G.DebugTeamScenePath
    if "" == scenePath then
      self:EnterBattle()
      return
    elseif nil == scenePath then
      local battleCfg = _G.BattleManager.battleRuntimeData.battleConfig
      if battleCfg and not string.IsNilOrEmpty(battleCfg.background) then
        scenePath = battleCfg.background
      elseif BattleUtils.IsBloodTeam() then
        scenePath = _G.DataConfigManager:GetBattleGlobalConfig("battle_map_local_blood").str
      elseif BattleUtils.IsWeeklyChallenge() then
        scenePath = "/Game/ArtRes/Level/Editor/Indoor/A2/L_Indoor_A2_04_LM"
      else
        scenePath = "/Game/ArtRes/Level/Game/Indoor/A2/Indoor_A2_04/Indoor_A2_04_Release"
      end
    end
    local LevelStreaming
    if BattleUtils.IsBloodTeam() then
      LevelStreaming = BattleLevelHelper:LoadLevelStream(scenePath, true, self.npcPos, UE.FRotator())
    else
      LevelStreaming = BattleManager.vBattleField:LoadBattleLevel(scenePath, self.npcPos, UE.FRotator())
    end
    if LevelStreaming then
      LevelStreaming.OnLevelLoaded:Add(LevelStreaming, function(level)
        self:FindLevelBattleCenter()
        if BattleUtils.IsTeam() then
          BattleUtils.ForceUpdateIndexMap()
        end
      end)
    else
      self:CameraTeleport(self.npcPos)
      self:PlayerTeleport(self.npcPos)
      self:CheckGround()
    end
  elseif BattleUtils.IsB1FinalBattle() then
    self:FindLevelBattleCenter()
  else
    self:CameraTeleport(self.npcPos)
    self:PlayerTeleport(self.npcPos)
    self.waitTime = 0
    self:SafeDelayFrames("d_CheckLevelLoadOver", 5, self.CheckLevelLoadOver, self)
  end
end

function PreProcessEnterBattleAction:CheckLevelLoadOver()
  if not self.active then
    return
  end
  local streamingLoading = UE4.UNRCStatics.StreamingLevelIsLoading(_G.UE4Helper.GetCurrentWorld(), _G.FVectorZero)
  if not streamingLoading or self.waitTime > MaxFindTime then
    self.waitTime = 0
    self:CheckGround()
  else
    self.waitTime = self.waitTime + self.CheckGap
    self:SafeDelaySeconds("d_CheckLevelLoadOver", self.CheckGap, self.CheckLevelLoadOver, self)
  end
end

function PreProcessEnterBattleAction:SetTileState()
  if self.isTeam or BattleUtils.IsWeeklyChallenge() or BattleUtils.IsTrainBattle() then
    UE4.UNRCStatics.BlockTillLevelUnLoadCompleted(UE4Helper.GetCurrentWorld())
    UE4.UNRCStatics.ExecConsoleCommand("WorldTileTool.FreezeWorldComposition 1")
  end
end

function PreProcessEnterBattleAction:StartTeleport()
  self.waitTime = 0
  if self.npcPos then
    self:SetTileState()
    NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
    NRCEventCenter:DispatchEvent(SceneEvent.PlayerTeleportStart)
    if not self.LocalPlayer then
      self.LocalPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    end
    self:RecordCurPlayerPos()
    self.LocalPlayer.viewObj:SetActorTickEnabled(false)
    self.LocalPlayer.movementComponent:SetSyncMove(false)
    self:LoadBattleLevel()
  else
    self:PreProcessBattleGrassChange()
  end
end

function PreProcessEnterBattleAction:RecordCurPlayerPos()
  _G.BattleManager.TeleportBackPos = self.LocalPlayer.viewObj:Abs_K2_GetActorLocation()
  if BattleUtils.IsWeeklyChallenge() then
    local isChallengeAgain, lastPlayerPos = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsWeeklyChallengeBattleAgain)
    if isChallengeAgain then
      _G.BattleManager.TeleportBackPos = lastPlayerPos
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetWeeklyChallengeBattleAgain, false)
    end
  end
end

function PreProcessEnterBattleAction:CameraTeleport(pos)
  local battleTransformCamera = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCamera, nil))
  if battleTransformCamera then
    local cameraSA = _G.ObjectRefUnBoxing(self.fsm:GetProperty(BattleConst.BattleSkipCameraAS, nil))
    if cameraSA then
      cameraSA:Abs_K2_SetActorLocation_WithoutHit(pos)
    end
  else
    battleTransformCamera = self:SpawnKamera(75, 2.15, false)
  end
  battleTransformCamera:Abs_K2_SetActorLocation_WithoutHit(pos, false, false)
  self.fsm:SetProperty(BattleConst.BattleSkipCamera, _G.ObjectRefBoxing(battleTransformCamera))
end

function PreProcessEnterBattleAction:PlayerTeleport(pos)
  if BattleUtils.IsTeam() or BattleUtils.IsWeeklyChallenge() or BattleUtils.IsTrainBattle() or BattleUtils.IsB1FinalBattle() then
  else
    BattleUtils.FocusPlayer()
    self.LocalPlayer:SetActorLocation(pos)
  end
end

function PreProcessEnterBattleAction:FindLevelBattleCenter()
  if not self.active then
    return
  end
  Log.Debug("PreProcessEnterBattleAction:FindLevelBattleCenter")
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
    BattleManager.vBattleField:SetEnvVolumeForLoadLevel(true)
    self:CameraTeleport(self.npcPos)
    self:PlayerTeleport(self.npcPos)
    self:CheckGround()
  else
    self.waitTime = self.waitTime + self.CheckGap
    if self.waitTime > MaxFindTime then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\230\136\152\229\156\186\228\184\173\229\191\131\231\130\185")
      if not _G.BattleManager.battleRuntimeData.TeleportBattleCenter then
        Log.Info("PreProcessEnterBattleAction:FindLevelBattleCenter \230\136\152\229\156\186\228\184\173\229\191\131\230\156\172\230\157\165\230\178\161\230\156\137\229\128\188\239\188\140\228\191\157\229\186\149\232\174\190\231\189\174\228\184\186\229\142\159\231\130\185")
        _G.BattleManager.battleRuntimeData.TeleportBattleCenter = UE4.FVector(0, 0, 0)
      end
      self.waitTime = 0
      self:CheckGround()
    else
      self:SafeDelaySeconds("d_FindLevelBattleCenter", self.CheckGap, self.FindLevelBattleCenter, self)
    end
  end
end

function PreProcessEnterBattleAction:CheckGround()
  if not self.active then
    return
  end
  Log.Debug("PreProcessEnterBattleAction:CheckGround")
  if self.waitTime > MaxCheckTime or self:FindPointAtGround(self.npcPos, true) then
    if self.waitTime > MaxCheckTime then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\229\156\176\233\157\162\239\188\129\239\188\129\239\188\129 \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\231\154\132\233\128\137\231\130\185\230\152\175\229\144\166\230\173\163\231\161\174!!! \230\156\172\229\156\186\230\136\152\230\150\151\231\154\132\233\128\137\231\130\185\228\184\186 ", self.npcPos)
    end
    BattleManager.battleRuntimeData.battleStartEnemyPos = self.npcPos
    self:LoadCharacterObject()
  else
    self.waitTime = self.waitTime + self.CheckGap
    self:SafeDelaySeconds("d_CheckGround", self.CheckGap, self.CheckGround, self)
  end
end

function PreProcessEnterBattleAction:EnterBattle()
  self:Finish()
end

function PreProcessEnterBattleAction:LoadCharacterObject()
  if BattleUtils.IsB1FinalBattle() then
    self.hasGrassPreProcessExecuted = true
    self:Finish()
    return
  end
  self:PreProcessBattleGrassChange()
end

function PreProcessEnterBattleAction:FindPointAtGround(pos, isWrite)
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

function PreProcessEnterBattleAction:SpawnKamera(fov, AspectR, Constrain)
  local Camera = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ACameraActor, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  local CameraComp = Camera:GetComponentByClass(UE4.UCameraComponent)
  CameraComp.FieldOfView = fov
  CameraComp.AspectRatio = AspectR
  CameraComp.bConstrainAspectRatio = Constrain
  Camera.bCollideWhenPlacing = true
  return Camera
end

function PreProcessEnterBattleAction:PreProcessBattleGrassChange()
  self.hasGrassPreProcessExecuted = true
  self:StartWaitFoliageReady()
end

function PreProcessEnterBattleAction:StartWaitFoliageReady()
  self.waitTime = 0
  local delayFrames = 1
  if self:CheckNeedTeleport() then
    delayFrames = 10
  end
  self:SafeDelayFrames("d_CheckAllLandscapeProxyAsyncFoliageTasksCompleted", delayFrames, self.CheckAllLandscapeProxyAsyncFoliageTasksCompleted, self)
end

function PreProcessEnterBattleAction:CheckAllLandscapeProxyAsyncFoliageTasksCompleted()
  if not self.active then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local landscapeProxies = UE4.UGameplayStatics.GetAllActorsOfClass(World, UE.ALandscapeProxy)
  local UNRCStatics = UE4.UNRCStatics
  local checkRes = UNRCStatics.CheckAllLandscapeProxyAsyncFoliageTasksCompleted(landscapeProxies)
  Log.Debug("PreProcessEnterBattleAction:CheckAllLandscapeProxyAsyncFoliageTasksCompleted checkRes =", checkRes)
  if self.waitTime > MaxCheckTime or checkRes then
    if self.waitTime > MaxCheckTime then
      Log.Error("PreProcessEnterBattleAction:CheckAllLandscapeProxyAsyncFoliageTasksCompleted \230\136\152\229\156\186\229\136\157\229\167\139\229\140\150\232\191\135\231\168\139\228\184\173\239\188\140\230\136\152\229\156\186\233\153\132\232\191\145 landscape \230\164\141\232\162\171\231\154\132\231\168\139\229\186\143\229\140\150\231\148\159\230\136\144\232\191\135\231\168\139\232\182\133\230\151\182")
    end
    self:PreLoadBattleGrassRes()
  else
    self.waitTime = self.waitTime + self.CheckGap
    self:SafeDelaySeconds("d_CheckAllLandscapeProxyAsyncFoliageTasksCompleted", self.CheckGap, self.CheckAllLandscapeProxyAsyncFoliageTasksCompleted, self)
  end
end

function PreProcessEnterBattleAction:PreLoadBattleGrassRes()
  BattleUtils.PrepareBattleGrassResList(true)
  local grassStaticMeshPathList = _G.BattleManager.battleRuntimeData.battleGrassInfo.GrassStaticMeshPathList or {}
  self.preLoadGrassAssetNumber = #grassStaticMeshPathList
  if self.preLoadGrassAssetNumber > 0 then
    for i = 1, #grassStaticMeshPathList do
      _G.BattleResourceManager:LoadResAsync(self, grassStaticMeshPathList[i], self.PreloadGrassAssetCallBack, self.PreloadGrassAssetCallBack, nil, nil, nil, PriorityEnum.Passive_Battle_Default)
    end
  end
  self:PreProcessBattleGrassChangeOver()
end

function PreProcessEnterBattleAction:PreloadGrassAssetCallBack()
end

function PreProcessEnterBattleAction:PreProcessBattleGrassChangeOver()
  self:EnterBattle()
end

function PreProcessEnterBattleAction:OnFinish()
  BattleManager:ResumeFocusTimer()
  self.fsm:Resume()
  self.LocalPlayer = nil
  if self.IsCloseLoading and not BattleManager.battleRuntimeData.battleStartParam:IsReconnect() and not BattleUtils.IsTrainBattle() then
    self.IsCloseLoading = false
    local asyncData = {
      owner = self,
      callback = function()
      end
    }
    NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.CloseLoading)
  end
  if BattleManager.vBattleField then
    local location = BattleManager.battleRuntimeData.NearbyValidBattleLocation
    local rotateAngle = BattleManager.battleRuntimeData.NearbyValidBattleRotation
    BattleManager.vBattleField:MoveToLocation(location, rotateAngle)
  end
  if not self.hasGrassPreProcessExecuted then
    Log.Error("PreProcessEnterBattleAction:OnFinish \230\136\152\229\156\186\232\141\137\229\156\176\233\162\132\229\164\132\231\144\134\232\191\135\231\168\139\230\156\170\230\137\167\232\161\140\239\188\140\232\175\183\230\163\128\230\159\165")
  end
end

return PreProcessEnterBattleAction
