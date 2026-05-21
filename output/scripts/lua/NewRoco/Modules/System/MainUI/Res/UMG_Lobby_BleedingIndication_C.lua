local UMG_Lobby_BleedingIndication_C = _G.NRCViewBase:Extend("UMG_Lobby_BleedingIndication_C")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")

function UMG_Lobby_BleedingIndication_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_Lobby_BleedingIndication_C", self, SceneEvent.PlayerBornFinish, self.ReBindPlayer)
  self._show = false
  self.DpiScaleY = 1
  self:ReBindPlayer()
end

function UMG_Lobby_BleedingIndication_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.ReBindPlayer)
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE, self.HPChange)
  end
end

function UMG_Lobby_BleedingIndication_C:ReBindPlayer()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE, self.HPChange)
  end
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.localPlayer then
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE, self.HPChange)
    self.hp = self.localPlayer.serverData.attrs.hp + self.localPlayer.serverData.attrs.hp_temporary or 0
    self.half = self.localPlayer.serverData.attrs.half_injure or 0
  end
end

function UMG_Lobby_BleedingIndication_C:OnAddEventListener()
end

function UMG_Lobby_BleedingIndication_C:HPChange(count, tempHP)
  local tempHalf = self.localPlayer.serverData.attrs.half_injure or 0
  Log.Debug("UMG_Lobby_BleedingIndication:HPChange  IN", self.hp, count, tempHP, self.half, tempHalf)
  if count < self.hp then
    Log.Debug("UMG_Lobby_BleedingIndication:HPChange  full")
    self:PlayReduce()
  elseif self.hp == count and self.half ~= tempHalf and 1 == tempHalf then
    Log.Debug("UMG_Lobby_BleedingIndication:HPChange  half")
    self:PlayToHalf()
  end
  self.half = tempHalf
  self.hp = count
end

function UMG_Lobby_BleedingIndication_C:PlayToHalf()
  self._show = true
  self:UpdateSlotPosition()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Heart_Broken_Half)
end

function UMG_Lobby_BleedingIndication_C:PlayReduce()
  self._show = true
  self:UpdateSlotPosition()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Heart_Broken_All)
end

function UMG_Lobby_BleedingIndication_C:OnAnimationFinished(anim)
  self._show = false
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Lobby_BleedingIndication_C:OnTick(InDeltaTime)
  if self._show then
    self:UpdateSlotPosition()
  end
end

local UpdateSlotPositionTempVector2D = UE4.FVector2D(0, 0)
local UpdateSlotPositionScreenPosCache = UE4.FVector2D(0, 0)
local UpdateSlotPositionViewportPosCache = UE4.FVector2D(0, 0)
local UpdateSlotPositionCameraRightVectorCache = UE4.FVector(0, 0, 0)
local UpdateSlotPositionCameraUpVectorCache = UE4.FVector(0, 0, 0)

function UMG_Lobby_BleedingIndication_C:UpdateSlotPosition()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  if not player.viewObj then
    return
  end
  local playerMesh = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  local offset = player.viewObj.BleedingIndication_Offset
  local cameraManager = player:GetUEController().playerCameraManager
  local playerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  local headLocation = playerMesh:Abs_GetSocketLocation("Root")
  local ScreenPos = UpdateSlotPositionScreenPosCache
  local CameraRotation = cameraManager:GetCameraRotation()
  UE4.UNRCStatics.GetRightVectorFromRotationInplace(CameraRotation, UpdateSlotPositionCameraRightVectorCache)
  UE4.UNRCStatics.GetUpVectorFromRotationInplace(CameraRotation, UpdateSlotPositionCameraUpVectorCache)
  local CameraRightVector = UpdateSlotPositionCameraRightVectorCache
  local CameraUpVector = UpdateSlotPositionCameraUpVectorCache
  CameraRightVector:Mul(offset.X)
  CameraUpVector:Mul(offset.Y)
  headLocation:Add(CameraRightVector)
  headLocation:Add(CameraUpVector)
  local headPosition = headLocation
  UE4.UGameplayStatics.Abs_ProjectWorldToScreen(playerController, headPosition, ScreenPos)
  local ViewportPos = UpdateSlotPositionViewportPosCache
  UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), ScreenPos, ViewportPos)
  local x = math.clamp(ViewportPos.X, 312, 1400)
  local y = math.clamp(ViewportPos.Y, 120, 800)
  UpdateSlotPositionTempVector2D:Set(x * self.DpiScaleY, y * self.DpiScaleY)
  self.Slot:SetPosition(UpdateSlotPositionTempVector2D)
end

return UMG_Lobby_BleedingIndication_C
