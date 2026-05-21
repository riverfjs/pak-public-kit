require("UnLuaEx")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BP_MiniRhythmPlane_C = NRCClass("BP_MiniRhythmPlane_C")

function BP_MiniRhythmPlane_C:ReceiveBeginPlay()
  self.Assets = {}
  local loadTask = a.task(function()
    local formatFunc = _G.NRCUtils.FormatResPackageNameToFullPath
    local assets = self.Assets
    local FxPlaneName = formatFunc(self.FX_Plane:GetLongPackageName())
    local FxHitName = formatFunc(self.FX_Hit:GetLongPackageName())
    local FXPlayerName = formatFunc(self.FX_Player:GetLongPackageName())
    if _G.NRCResourceManager.bind then
      assets.FxPlane = not string.IsNilOrEmpty(FxPlaneName) and _G.NRCResourceManager:LoadResAsync(self, FxPlaneName, PriorityEnum.Passive_World_AI_SkillRes, 10)
      assets.FxHit = not string.IsNilOrEmpty(FxHitName) and _G.NRCResourceManager:LoadResAsync(self, FxHitName, PriorityEnum.Passive_World_AI_SkillRes, 10)
      assets.FXPlayer = not string.IsNilOrEmpty(FXPlayerName) and _G.NRCResourceManager:LoadResAsync(self, FXPlayerName, PriorityEnum.Passive_World_AI_SkillRes, 10)
    else
      assets.FxPlane = {
        asset = LoadObject(FxPlaneName)
      }
      assets.FxPlane.assetRef = UnLua.Ref(assets.FxPlane.asset)
      assets.FxHit = {
        asset = LoadObject(FxHitName)
      }
      assets.FxHit.assetRef = UnLua.Ref(assets.FxHit.asset)
      assets.FXPlayer = {
        asset = LoadObject(FXPlayerName)
      }
      assets.FXPlayer.assetRef = UnLua.Ref(assets.FXPlayer.asset)
      self:BeginPlayRhythm()
      return
    end
    
    local function CreateTaskList()
      local TaskList = {}
      for key, req in pairs(assets) do
        if req then
          TaskList[key] = au.ResRequestCallback(req)
        end
      end
      return TaskList
    end
    
    local resultList = a.wait_all(CreateTaskList(), true)
    for key, result in pairs(resultList) do
      if result[1] then
        result[2].asset = result[3]
        result[2].assetRef = UnLua.Ref(result[3])
      else
        Log.Error("BP_MiniRhythmPlane_C:Failed to load asset", key, result[3])
      end
    end
    self:BeginPlayRhythm()
  end)
  self.loadContext = loadTask(au.DefaultTaskCallback)
end

function BP_MiniRhythmPlane_C:ReceiveEndPlay(reason)
  self:CleanUp()
  self.RocoFX:StopAllFx()
  a.kill(self.loadContext, true)
  self.loadContext = nil
  for _, req in pairs(self.Assets) do
    if req then
      req.assetRef = nil
      req.asset = nil
      _G.NRCResourceManager:UnLoadRes(req)
    end
  end
  self.Assets = nil
end

function BP_MiniRhythmPlane_C:ReceiveActorBeginOverlap(OtherActor)
  if not self.isPlaying then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj and player.viewObj == OtherActor then
    self.PlayerActor = OtherActor
    self:OnPlayerEnter()
  end
end

function BP_MiniRhythmPlane_C:ReceiveActorEndOverlap(OtherActor)
  if not self.isPlaying then
    return
  end
  if self.PlayerActor and not UE.UObject.IsValid(self.PlayerActor) then
    self:OnPlayerLeave()
    self.PlayerActor = nil
  end
  if self.PlayerActor and self.PlayerActor == OtherActor then
    self:OnPlayerLeave()
    self.PlayerActor = nil
  end
end

function BP_MiniRhythmPlane_C:RegisterUpdate()
  if self.isRegisterUpdate then
    return
  end
  self.isRegisterUpdate = true
  UpdateManager:Register(self)
end

function BP_MiniRhythmPlane_C:UnRegisterUpdate()
  if not self.isRegisterUpdate then
    return
  end
  self.isRegisterUpdate = false
  UpdateManager:UnRegister(self)
end

function BP_MiniRhythmPlane_C:OnPlayerEnter()
  if self.isPlayerEnter then
    return
  end
  self.isPlayerEnter = true
  if UE.UObject.IsValid(self.PlayerActor) then
    local player = self.PlayerActor.sceneCharacter
    player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_JUMPED, self.OnPlayerJump)
    local FXPlayer = self.Assets.FXPlayer and self.Assets.FXPlayer.asset
    if FXPlayer then
      local playerFxComp = self.PlayerActor.FxComponent
      self.FxPlayerInst = playerFxComp:PlayFx_Type_Setting2(FXPlayer, UE.EFXAttachPointType.Actor, true, nil, true, true)
      local FxComp = playerFxComp:GetFxSystemComponentById(self.FxPlayerInst)
      if FxComp then
        FxComp:SetAbsolute(false, true, true)
      end
    end
  end
end

function BP_MiniRhythmPlane_C:OnPlayerLeave()
  if not self.isPlayerEnter then
    return
  end
  self.isPlayerEnter = false
  if UE.UObject.IsValid(self.PlayerActor) then
    local player = self.PlayerActor.sceneCharacter
    player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_JUMPED, self.OnPlayerJump)
    if self.FxPlayerInst then
      self.PlayerActor.FxComponent:StopFx(self.FxPlayerInst)
      self.FxPlayerInst = nil
    end
  end
end

function BP_MiniRhythmPlane_C:OnAudioSessionFinish()
  self.audioSession = 0
  self:CleanUp()
  if self.FxPlaneInst and UE4.UObject.IsValid(self.RocoFX) then
    self.RocoFX:PauseFxByID(self.FxPlaneInst, true)
  end
end

local OverlappingActors = UE.TArray(UE.ARocoLocalPlayer)

function BP_MiniRhythmPlane_C:BeginPlayRhythm()
  if self.isPlaying then
    return
  end
  local soundId = self.SoundId
  if _G.NRCAudioManager then
    self.audioSession = _G.NRCAudioManager:PlaySound3DWithActorAuto(soundId, self, "BP_MiniRhythmPlane_C")
  else
    self.audioSession = UE4.UNRCAudioManager.Get():PlaySound3DWithActorAuto(soundId, self, "BP_MiniRhythmPlane_C")
  end
  if -1 == self.audioSession then
    Log.PrintScreenMsg("MiniRhythmPlane: PlaySound3DWithActorAuto failed %d", soundId)
    return
  end
  if _G.NRCAudioManager then
    _G.NRCAudioManager:AddSessionFinishCallback(self.audioSession, self, self.OnAudioSessionFinish)
  end
  self.isPlaying = true
  self:RegisterUpdate()
  self._hitSoundId = self.HitSoundId or 0
  self._beatOffsetMs = self.BeatOffsetMs
  self._beatMs = self.BeatMs
  self.judgeTimeMs = self.JudgeTimeMs
  self._beatMap = self.BeatMap:ToTable()
  self.nextJudgeBeatIdx = 1
  self.nextBeatIdx = 1
  local FxPlane = self.Assets.FxPlane and self.Assets.FxPlane.asset
  if FxPlane then
    self.FxPlaneInst = self.RocoFX:PlayFx_Name_Transform(FxPlane, "", UE.FTransform(), true)
  end
  self:GetOverlappingActors(OverlappingActors, UE.ARocoLocalPlayer)
  local player = _G.NRCModuleManager and _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerView = player.viewObj
  for i = 1, OverlappingActors:Num() do
    local overlapActor = OverlappingActors:Get(i)
    if overlapActor and UE.UObject.IsValid(overlapActor) and overlapActor == playerView then
      self.PlayerActor = overlapActor
      self:OnPlayerEnter()
    end
  end
end

function BP_MiniRhythmPlane_C:CleanUp()
  if self.audioSession and -1 ~= self.audioSession then
    if _G.NRCAudioManager then
      _G.NRCAudioManager:ReleaseSession(self.audioSession)
    else
      UE4.UNRCAudioManager.Get():ReleaseSession(self.audioSession)
    end
  end
  self:UnRegisterUpdate()
  self:OnPlayerLeave()
  self.PlayerActor = nil
  self.isPlaying = false
  self.audioSession = nil
  self.nextJudgeBeatIdx = nil
  self.nextBeatIdx = nil
  self._beatMap = nil
  self._lastParentHidden = nil
end

function BP_MiniRhythmPlane_C:UpdateVisibilityByParent()
  local parent = self:GetAttachParentActor()
  local parentHidden = parent and parent.bHidden or false
  if self._lastParentHidden == parentHidden then
    return
  end
  self._lastParentHidden = parentHidden
  if self.FxPlaneInst then
    local fxComp = self.RocoFX:GetFxSystemComponentById(self.FxPlaneInst)
    if fxComp and UE.UObject.IsValid(fxComp) then
      fxComp:SetHiddenInGame(parentHidden, false)
    end
  end
  if self.FxPlayerInst and self.PlayerActor and UE.UObject.IsValid(self.PlayerActor) then
    local fxComp = self.PlayerActor.FxComponent:GetFxSystemComponentById(self.FxPlayerInst)
    if fxComp and UE.UObject.IsValid(fxComp) then
      fxComp:SetHiddenInGame(parentHidden, false)
    end
  end
end

function BP_MiniRhythmPlane_C:OnTick(dt)
  if not self.isPlaying then
    return
  end
  self:UpdateVisibilityByParent()
  local dspTime = _G.NRCAudioManager and _G.NRCAudioManager:GetPlayPositionInMs(self.audioSession) or 0
  if 0 == dspTime then
    return
  end
  if self._beatMap and self.nextBeatIdx then
    while self.nextBeatIdx <= #self._beatMap do
      local beatIndex = self._beatMap[self.nextBeatIdx]
      local beatTimeMs = self._beatOffsetMs + beatIndex * self._beatMs
      if dspTime >= beatTimeMs then
        self:OnBeat(dspTime, beatIndex)
        self.nextBeatIdx = self.nextBeatIdx + 1
      else
        break
      end
    end
  end
  if self._beatMap and self.nextJudgeBeatIdx then
    while self.nextJudgeBeatIdx <= #self._beatMap do
      local beatIndex = self._beatMap[self.nextJudgeBeatIdx]
      local beatTimeMs = self._beatOffsetMs + beatIndex * self._beatMs
      if dspTime > beatTimeMs + self.judgeTimeMs then
        self.nextJudgeBeatIdx = self.nextJudgeBeatIdx + 1
      else
        break
      end
    end
  end
end

function BP_MiniRhythmPlane_C:OnBeat(dspTime, beatIndex)
  if GlobalConfig.DebugLuaBTree then
    UE.UKismetSystemLibrary.DrawDebugSphere(self, self:K2_GetActorLocation(), 500, 12, UE.FLinearColor(1, 1, 1, 1), 0.4)
  end
end

function BP_MiniRhythmPlane_C:OnPlayerHit()
  local FxHit = self.Assets.FxHit and self.Assets.FxHit.asset
  local player
  if self.PlayerActor and UE.UObject.IsValid(self.PlayerActor) then
    player = self.PlayerActor
  end
  if FxHit then
    self.RocoFX:PlayFx_Type_Setting2(FxHit, UE.EFXAttachPointType.Pos, false, nil)
    if player then
      local PlayerFxComponent = player.FxComponent
      local instId = PlayerFxComponent:PlayFx_Type_Setting2(FxHit, UE.EFXAttachPointType.Head, false, nil, true, true)
      local FxInst = PlayerFxComponent:GetFxSystemComponentById(instId)
      if FxInst then
        local playerRootComp = player:K2_GetRootComponent()
        if playerRootComp then
          FxInst:K2_AttachToComponent(playerRootComp, "", UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, true)
        end
        FxInst:SetAbsolute(false, true, true)
      end
    end
  end
  if 0 ~= self._hitSoundId and _G.NRCAudioManager then
    if player then
      _G.NRCAudioManager:PlaySound3DWithActorAuto(self._hitSoundId, player, "BP_MiniRhythmPlane_C_Hit")
    else
      _G.NRCAudioManager:PlaySound3DWithActorAuto(self._hitSoundId, self, "BP_MiniRhythmPlane_C_Hit")
    end
  end
end

function BP_MiniRhythmPlane_C:OnPlayerJump()
  if not (self.isPlaying and self._beatMap) or not self.nextJudgeBeatIdx then
    return
  end
  local dspTime = _G.NRCAudioManager and _G.NRCAudioManager:GetPlayPositionInMs(self.audioSession) or 0
  if 0 == dspTime then
    return
  end
  if self.nextJudgeBeatIdx > #self._beatMap then
    return
  end
  local beatIndex = self._beatMap[self.nextJudgeBeatIdx]
  local beatTimeMs = self._beatOffsetMs + beatIndex * self._beatMs
  local diff = math.abs(dspTime - beatTimeMs)
  if diff <= self.judgeTimeMs then
    Log.PrintScreenMsg("HIT!")
    self:OnPlayerHit()
    self.nextJudgeBeatIdx = self.nextJudgeBeatIdx + 1
  else
    Log.PrintScreenMsg("miss")
  end
end

return BP_MiniRhythmPlane_C
