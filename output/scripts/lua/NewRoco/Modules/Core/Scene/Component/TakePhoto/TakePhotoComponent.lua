local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local TakePhotoComponent = Base:Extend("TakePhotoComponent")
local CameraPath = "/Game/NewRoco/Modules/Core/NPC/TakePhoto/BP_TakePhotoCamera.BP_TakePhotoCamera_C"
local CameraTransform = UE.FTransform(UE.FRotator(-42, -13, 9.2):ToQuat(), UE.FVector(1.718, -15.26, -5), UE.FVector(0.5))
local CameraSocket = "Bip001-R-Hand"

function TakePhotoComponent:Attach(owner)
  Base.Attach(self, owner)
  self:SetCameraAssets(self.owner.uin)
  local player = self.owner
  player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnRide)
  player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
  player:AddEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnSyncCameraTextureChanged, self.SetCameraAssets)
  else
    Log.Warning("TakePhotoComponent:Attach TakePhotosModule is nil")
  end
  self._curCameraStatus = 0
end

function TakePhotoComponent:OnLoadCameraSuccess(assets, sessionId)
  if nil == assets then
    Log.Error("TakePhotoComponent:OnLoadCameraSuccess assets is nil")
    return
  end
  if sessionId ~= self.loadAssetSessionId and not self.bIgnoreSessionIdMismatch then
    Log.Error("TakePhotoComponent:OnLoadCameraSuccess sessionId is not match sessionId", sessionId, "self.loadAssetSessionId", tostring(self.loadAssetSessionId))
    return
  end
  local assetsTable = assets:ToTable()
  if nil == assetsTable then
    Log.Error("TakePhotoComponent:OnLoadCameraSuccess assetsTable is nil")
    return
  end
  self.cameraActor = TakePhotosUtils.SetCameraAppearance(self.cameraActor, nil, assetsTable)
  if not self.cameraActor then
    Log.Error("TakePhotoComponent:OnLoadCameraSuccess cameraActor is nil")
    return
  end
  local player = self.owner
  if UE.UObject.IsValid(player.viewObj) then
    local playerHidden = player.viewObj:GetActorHidden()
    self.cameraActor:SetOwnerVisible(not playerHidden)
  end
  if not self.DelayID then
    self.DelayID = _G.DelayManager:DelayFrames(1, function()
      self.DelayID = nil
      self:HandleTakePhotoStatus()
    end)
  end
end

function TakePhotoComponent:OnLoadCameraFail(assets, sessionId)
  Log.Debug("TakePhotoComponent OnLoadCameraFail", sessionId)
end

function TakePhotoComponent:OnPlayerStatusChanged(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO or status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF or status == ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD or status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND or status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P then
    Log.Debug("[TakePhotoComponent] OnPlayerStatusChanged ", status, value)
    self._curCameraStatus = nil
    self:HandleTakePhotoStatus()
  end
end

function TakePhotoComponent:OnRide(isRide)
  Log.Debug("[TakePhotoComponent] OnRide ", isRide)
  self._curCameraStatus = nil
  self:HandleTakePhotoStatus()
end

function TakePhotoComponent:OnDoubleRideChange(isRide, is1P)
  Log.Debug("[TakePhotoComponent] OnDoubleRideChange ", isRide, is1P)
  self:HandleTakePhotoStatus()
end

function TakePhotoComponent:HandleTakePhotoStatus()
  if self.owner and UE.UObject.IsValid(self.owner.viewObj) then
    local statusComponent = self.owner.statusComponent
    if statusComponent then
      if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO) then
        if self._curCameraStatus ~= ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO then
          self:HoldCamera()
        end
      elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF) then
        if self._curCameraStatus ~= ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF then
          self:HandCamera()
        end
      elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD) then
        if self._curCameraStatus ~= ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD then
          self:TripodCamera()
        end
      else
        if UE.UObject.IsValid(self.owner.viewObj) then
          self.owner.viewObj.TakePhotoCamera = nil
          self.owner.viewObj.TakePhotoHand = false
        end
        if self.cameraActor then
          self:SetCameraActorVisible(false)
        end
        self._curCameraStatus = 0
      end
    end
  end
end

function TakePhotoComponent:HoldCamera()
  self.owner.viewObj.TakePhotoCamera = nil
  if UE.UObject.IsValid(self.cameraActor) then
    local isRide = self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if not isRide then
      local isLink = self.owner:IsInTogetherMove()
      if isLink then
        self.owner.viewObj.TakePhotoHand = false
        local success = self:FloatingCamera(false)
        if success then
          self:SetCameraActorVisible(true)
          self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO
        end
      else
        self.owner.viewObj.TakePhotoHand = true
        self.cameraActor:K2_AttachToComponent(self.owner.viewObj.Mesh, CameraSocket, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, false)
        self.cameraActor:K2_SetActorRelativeTransform(CameraTransform, false, nil, false)
        self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO
        self:SetCameraActorVisible(true)
      end
    else
      self.owner.viewObj.TakePhotoHand = false
      local success = self:FloatingCamera(true)
      if success then
        self:SetCameraActorVisible(true)
        self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO
      else
        Log.Error("FloatingCamera Hold Failed")
      end
    end
  end
end

function TakePhotoComponent:HandCamera()
  self.owner.viewObj.TakePhotoHand = false
  if UE.UObject.IsValid(self.cameraActor) then
    local isRide = self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if not isRide then
      self.owner.viewObj.TakePhotoCamera = self.cameraActor
      self:SetCameraActorVisible(true)
      self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF
    else
      self.owner.viewObj.TakePhotoCamera = nil
      local success = self:FloatingCamera(true)
      if success then
        self:SetCameraActorVisible(true)
        self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF
      end
    end
  end
end

function TakePhotoComponent:TripodCamera()
  self.owner.viewObj.TakePhotoHand = false
  self.owner.viewObj.TakePhotoCamera = nil
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() or _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.InHome) then
    Log.Debug("TakePhotoComponent:TripodCamera Skip: InVisit or InHome ")
    self:SetCameraActorVisible(false)
  else
    local isRide = self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if isRide then
      local success = self:FloatingCamera(true)
      if success then
        self:SetCameraActorVisible(true)
        self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD
      end
    else
      local success = self:FloatingCamera(false)
      if success then
        self:SetCameraActorVisible(true)
        self._curCameraStatus = ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD
      end
    end
  end
end

function TakePhotoComponent:FloatingCamera(isRide)
  local forwardOffset = 40
  local rightOffset = 20
  local viewObj = self.owner.viewObj
  if UE.UObject.IsValid(viewObj) then
    local headLocation = viewObj.Mesh:GetSocketLocation("locator_Head")
    if isRide then
      local ridePet = self.owner:GetRidePetBP()
      if UE.UObject.IsValid(ridePet) then
        local petForward = ridePet:GetActorForwardVector()
        local petRight = ridePet:GetActorRightVector()
        headLocation = headLocation or ridePet:K2_GetActorLocation()
        local targetLocation = headLocation + petForward * forwardOffset + petRight * rightOffset
        self.cameraActor:K2_AttachToActor(ridePet, nil, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, false)
        self.cameraActor:K2_SetActorLocation(targetLocation, false, nil, false)
        self.cameraActor:SetActorRelativeScale3D(UE.FVector(0.5))
        return true
      end
      return false
    end
    local playerForward = viewObj:GetActorForwardVector()
    local playerRight = viewObj:GetActorRightVector()
    headLocation = headLocation or viewObj:K2_GetActorLocation()
    local targetLocation = headLocation + playerForward * forwardOffset + playerRight * rightOffset
    self.cameraActor:K2_AttachToActor(self.owner.viewObj, nil, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, false)
    self.cameraActor:K2_SetActorLocation(targetLocation, false, nil, false)
    self.cameraActor:SetActorRelativeScale3D(UE.FVector(0.5))
    return true
  end
  return false
end

function TakePhotoComponent:OnPlayerVisibleChange(isVisible)
  if UE.UObject.IsValid(self.cameraActor) then
    self.cameraActor:SetOwnerVisible(isVisible)
  end
end

function TakePhotoComponent:OnAvatarReady()
  local player = self.owner
  if UE.UObject.IsValid(player.viewObj) then
    local playerHidden = player.viewObj:GetActorHidden()
    self.cameraActor:SetOwnerVisible(not playerHidden)
  end
  self:HandleTakePhotoStatus()
end

function TakePhotoComponent:DeAttach()
  if self.DelayID then
    _G.DelayManager:CancelDelayById(self.DelayID)
    self.DelayID = nil
  end
  local player = self.owner
  player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnRide)
  player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
  player:RemoveEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnSyncCameraTextureChanged, self.SetCameraAssets)
  end
  if self.cameraActor then
    self.cameraActor:K2_DestroyActor()
    self.cameraActor = nil
  end
  Base.DeAttach(self)
end

function TakePhotoComponent:SetCameraAssets(ActorId)
  Log.Debug("TakePhotoComponent:SetCameraAssets", ActorId, self.owner.uin)
  if ActorId ~= self.owner.uin then
    return
  end
  local cameraAppearanceId = TakePhotosUtils.GetPlayerCameraAppearanceId(self.owner)
  self.bIgnoreSessionIdMismatch = true
  self.loadAssetSessionId = TakePhotosUtils.LoadCameraAppearance(self, cameraAppearanceId, CameraPath, self.OnLoadCameraSuccess, self.OnLoadCameraFail)
  self.bIgnoreSessionIdMismatch = false
end

function TakePhotoComponent:SetCameraActorVisible(bVisible)
  Log.Debug("TakePhotoComponent:SetCameraActorVisible", bVisible)
  if not self.cameraActor or not UE.UObject.IsValid(self.cameraActor) then
    Log.Warning("TakePhotoComponent:SetCameraActorVisible cameraActor is nil")
    return
  end
  self.cameraActor:SetVisible(bVisible)
  if bVisible then
    local Module = NRCModuleManager:GetModule("TakePhotosModule")
    if Module then
      Module:RegisterEvent(self, TakePhotosModuleEvent.OnSyncCameraTextureChanged, self.SetCameraAssets)
    else
      Log.Warning("TakePhotoComponent:SetCameraActorVisible TakePhotosModule is nil")
    end
  end
end

return TakePhotoComponent
