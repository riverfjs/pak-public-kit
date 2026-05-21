local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PlayerLookLens = Class("PlayerLookLens")

function PlayerLookLens:Ctor(MainPanel)
  self.PlayerMap = {}
  MainPanel.OnTickMultiDelegate:Add(self, self.OnTick)
  MainPanel.OnDestroyMultiDelegate:Add(self, self.OnDestroy)
  MainPanel.OnModeChangedDelegate:Add(self, self.OnModeChanged)
  self.Settings = MainPanel:GetPhotoController().TakePhotoSettings
  self.Settings.PlayerLookCamera.OnValueChanged:Add(self, self.OnLookLensSettingChanged)
  self.LookLensLockReasons = {}
  self.bLookLensEnabled = nil
  if not self.Settings.PlayerLookCamera:IsEnabled() then
    self.LookLensLockReasons.SettingsLock = true
  end
  self.ViewTarget = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ACameraActor, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.ViewTarget:SetActorEnableCollision(false)
  self.ViewTarget:SetActorHiddenInGame(true)
  self.ViewTarget2p = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ACameraActor, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.ViewTarget2p:SetActorEnableCollision(false)
  self.ViewTarget2p:SetActorHiddenInGame(true)
end

function PlayerLookLens:OnDestroy()
  self.ViewTarget:K2_DestroyActor()
  self.ViewTarget = nil
  self.ViewTarget2p:K2_DestroyActor()
  self.ViewTarget2p = nil
  self:RefreshPlayers(false)
end

function PlayerLookLens:OnTick(Dt)
  local bEnableLookLens = self:IfNeedEnableLookLens()
  self:RefreshViewTarget(bEnableLookLens)
  self:RefreshPlayers(bEnableLookLens)
end

function PlayerLookLens:IfNeedEnableLookLens()
  return not next(self.LookLensLockReasons)
end

function PlayerLookLens:ClearAllPlayer()
  for Player, v in pairs(self.PlayerMap) do
    Player:SetHeadLookAtActorIfOverride(nil)
  end
  self.PlayerMap = {}
end

function PlayerLookLens:RefreshPlayer(Player, bNeedLookLens)
  if nil == Player then
    return
  end
  if Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    if self.PlayerMap[Player] then
      Player:SetHeadLookAtActorIfOverride(nil)
      self.PlayerMap[Player] = nil
    end
    return
  end
  if bNeedLookLens then
    if Player.isLocal then
      Player:SetHeadLookAtActorIfOverride(self.ViewTarget, true)
    else
      Player:SetHeadLookAtActorIfOverride(self.ViewTarget2p, true)
    end
    self.PlayerMap[Player] = true
  else
    Player:SetHeadLookAtActorIfOverride(nil)
    self.PlayerMap[Player] = nil
  end
end

function PlayerLookLens:RefreshPlayers(bNeedLookLens)
  local isMaster = _G.NRCModeManager:DoCmd(_G.HomeModuleCmd.IsInHomeScene)
  if isMaster then
    for i, Player in ipairs(_G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)) do
      self:RefreshPlayer(Player, bNeedLookLens)
    end
  else
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if next(visitorList) then
      for i, visitor in ipairs(visitorList) do
        local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, visitor.uin)
        self:RefreshPlayer(Player, bNeedLookLens)
      end
    else
      local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      self:RefreshPlayer(Player, bNeedLookLens)
    end
  end
end

function PlayerLookLens:RefreshViewTarget(bEnableLookLens)
  if self.ViewTarget then
    local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local Controller = LocalPlayer and LocalPlayer:GetUEController()
    if Controller then
      local Mesh = LocalPlayer.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
      if Mesh then
        local TargetLoc, TargetLoc2p
        if bEnableLookLens then
          if self.currentMode.Mgr:IsSelfieMode() then
            TargetLoc = Controller.PlayerCameraManager:Abs_GetCameraLocation()
            TargetLoc2p = TargetLoc
            local playerController = LocalPlayer:GetUEController()
            local curCamActor = playerController:GetViewTarget()
            local offset = NRCModuleManager:DoCmd(TakePhotosModuleCmd.GetSelfiePlayerLookAtOffset)
            if offset then
              TargetLoc = TargetLoc + curCamActor:Abs_GetTransform():TransformVector(offset)
            end
          else
            local LookAtScale = 0.5
            local X, Y = Controller:GetViewportSize()
            local PlayerLoc = Mesh:Abs_GetSocketLocation("locator_Head")
            local CameraLoc, Dir = Controller:Abs_DeprojectScreenPositionToWorld(X * 0.5, Y * 0.5)
            local TempLoc = (PlayerLoc + CameraLoc) * LookAtScale
            local NormalizedDirection = UE.UKismetMathLibrary.Normal(Dir, 0.01)
            local NormalizedNormal = UE.UKismetMathLibrary.Normal(PlayerLoc - CameraLoc, 0.01)
            local Denominator = NormalizedDirection:Dot(NormalizedNormal)
            TargetLoc = CameraLoc
            if math.abs(Denominator) > 1.0E-4 then
              local Numerator = -(NormalizedNormal:Dot(CameraLoc) - NormalizedNormal:Dot(TempLoc))
              local Num = Numerator / Denominator
              TargetLoc = CameraLoc + NormalizedDirection * Num
            end
            TargetLoc2p = TargetLoc
          end
        end
        self.ViewTarget:Abs_K2_SetActorLocation_WithoutHit(TargetLoc, false, nil, false)
        self.ViewTarget2p:Abs_K2_SetActorLocation_WithoutHit(TargetLoc2p, false, nil, false)
      end
    end
  end
end

function PlayerLookLens:OnModeChanged(Mode)
  if Mode:IsEnablePlayerLookLensFeature() then
    self.LookLensLockReasons.ModeLook = nil
  else
    self.LookLensLockReasons.ModeLook = true
  end
  self.currentMode = Mode
end

function PlayerLookLens:OnLookLensSettingChanged(bEnable)
  if bEnable then
    self.LookLensLockReasons.SettingsLock = nil
  else
    self.LookLensLockReasons.SettingsLock = true
  end
end

return PlayerLookLens
