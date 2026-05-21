local TakePhotosModeBasic = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeBasic")
local TakePhotosMode1P = TakePhotosModeBasic:Extend("TakePhotosMode1P")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")

function TakePhotosMode1P:PreCheck()
  local bBan, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, true, true)
  if bBan then
    return false, "" ~= Msg
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    if player.buffComponent:HasBuff("Transform_Buff") then
      return false
    end
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      local petID = player.viewObj.BP_RideComponent:GetPetBaseID()
      if not petID then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_ride_tips)
        return false, true
      end
      local RideConf = DataConfigManager:GetAllRidePet(petID)
      if player.viewObj.BP_RideComponent.bIsLoading or RideConf.takephoto_ban_switch then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_ride_tips)
        return false, true
      end
    end
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
      return false
    end
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
      return false
    end
    local InstanceModule = _G.NRCModuleManager:GetModule("InstanceModule")
    if InstanceModule.bSwitching then
      Log.Warning("\230\151\160\230\179\149\230\137\147\229\188\128, \230\173\163\229\156\168\231\173\137\229\190\133\229\137\175\230\156\172\230\181\129\231\168\139")
      return false
    end
    local canApply, overrideValues, opCode = player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_TAKE_PHOTO)
    if canApply then
      return true
    end
  end
  return false
end

function TakePhotosMode1P:GetRenderTarget2D()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraManager = player:GetUEController().playerCameraManager
  local RT = NRCModuleManager:GetModule("TakePhotosModule").data:RequestRT()
  cameraManager:StartCaptureImmediately(RT)
  return RT
end

function TakePhotosMode1P:GetPlayerConditionType()
  return Enum.PlayerConditionType.PCT_TAKE_PHOTO_HANDHELD
end

function TakePhotosMode1P:OnShowEnterTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_handle_camera_tips, nil, nil, self.Mgr.ToggleTipsSeconds)
end

function TakePhotosMode1P:OnEnter()
  self.World = UE4Helper.GetCurrentWorld()
  self.Overlaps = {}
  self.OverlapCache = UE4.TArray(UE.AActor)
  TakePhotosModeBasic.OnEnter(self)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", true)
  end
  if FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_ONLINE_OWNER_ALLOWED) then
    NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  end
  TakePhotosUtils.ToggleCameraFromWorldTo1P()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  
  function self.OnAvatarReadyHandle(_, UID)
    if player.viewObj.UID == UID then
      return self:OnAvatarReady()
    end
  end
  
  player.avatarSystem.OnSwitchAvatarSuitComplete:Add(player.avatarSystem, self.OnAvatarReadyHandle)
  if player:IsTogetherMove2P() then
    local OtherPlayer = player:GetAnotherTogetherMovePlayer()
    if OtherPlayer and OtherPlayer:GetAnimComponent() then
      local OtherPlayerABP = OtherPlayer:GetAnimComponent():GetAnimInstance("RideAll")
      if OtherPlayerABP then
        OtherPlayerABP.bEnableTransformFilter = true
        Log.Debug("TakePhotosMode1P OtherPlayerABP bEnableTransformFilter = true", OtherPlayer.uin)
      end
      self.OtherPlayer = OtherPlayer
    end
  end
  _G.NRCAudioManager:SetEmitterSwitch("Mute_Switch", "Unmute", player.viewObj)
end

function TakePhotosMode1P:OnExit(bExitTakePhoto)
  TakePhotosModeBasic.OnExit(self)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", false)
  end
  self.SavedFov = self:GetBaseFov()
  TakePhotosUtils.ExistCameraFrom1PToWorld(bExitTakePhoto)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.avatarSystem.OnSwitchAvatarSuitComplete:Remove(player.avatarSystem, self.OnAvatarReadyHandle)
  self:ResetOverlaps()
  if self.OtherPlayer then
    if self.OtherPlayer and self.OtherPlayer:GetAnimComponent() then
      local OtherPlayerABP = self.OtherPlayer:GetAnimComponent():GetAnimInstance("RideAll")
      if OtherPlayerABP then
        OtherPlayerABP.bEnableTransformFilter = false
        Log.Debug("TakePhotosMode1P OtherPlayerABP bEnableTransformFilter = false", self.OtherPlayer.uin)
      end
    end
    self.OtherPlayer = nil
  end
  _G.NRCAudioManager:SetEmitterSwitch("Mute_Switch", "Mute", player.viewObj)
end

function TakePhotosMode1P:OnAvatarReady()
  TakePhotosUtils.OnAvatarReadyIn1PMode()
end

function TakePhotosMode1P:ResetCameraView()
  self.SavedFov = self:GetBaseFov()
  TakePhotosUtils.Reset1PCameraView()
end

function TakePhotosMode1P:GetBaseFov()
  return TakePhotosEnum.TPGlobalNum("takephoto_hand_camera_fov", 90)
end

function TakePhotosMode1P:OnTick(Dt)
  if not self.Overlaps then
    return
  end
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local playerView = localPlayer.viewObj
  if not playerView or not UE.UObject.IsValid(playerView) then
    return
  end
  for Overlap, _ in pairs(self.Overlaps) do
    self.Overlaps[Overlap] = 0
  end
  local ObjectTypes = {
    UE.EObjectTypeQuery.Pawn
  }
  local CachedResults = self.OverlapCache
  local PlayerLocation = localPlayer:GetUEController().PlayerCameraManager:GetCameraLocation()
  local Success = UE.UNRCStatics.SphereOverlapActors(self.World, PlayerLocation, 11, ObjectTypes, {
    localPlayer.viewObj
  }, CachedResults)
  if not Success then
    CachedResults:Clear()
  end
  for i, Overlap in tpairs(CachedResults) do
    self.Overlaps[Overlap] = 1
  end
  for Overlap, Alpha in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, Alpha)
    if 0 == Alpha then
      self.Overlaps[Overlap] = nil
    end
  end
end

function TakePhotosMode1P:InternalEnabledAlpha(Overlap, Alpha)
  if not UE.UObject.IsValid(Overlap) then
    return
  end
  local bVisible = 0 == Alpha
  if Overlap.sceneCharacter and Overlap.sceneCharacter.isLocal ~= nil then
  else
    local SceneCharacter = Overlap.sceneCharacter
    if SceneCharacter then
      if SceneCharacter.SetVisibleForTakePhoto then
        SceneCharacter:SetVisibleForTakePhoto(bVisible)
      end
    elseif Overlap.SetMeshAlpha then
      Overlap:SetMeshAlpha(Alpha)
    end
  end
end

function TakePhotosMode1P:ResetOverlaps()
  for Overlap, _ in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, 0)
  end
  self.Overlaps = nil
  self.World = nil
end

return TakePhotosMode1P
