require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local UMG_Ability_Slot_Jump_C = Base:Extend("UMG_Ability_Slot_Jump_C")

function UMG_Ability_Slot_Jump_C:OnConstruct()
  Base.OnConstruct(self)
  self._isBlock = false
  self._isVisible = true
  self._unVisibleStatus = {
    ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL,
    ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING,
    ProtoEnum.WorldPlayerStatusType.WPST_CLIMB
  }
  self._blockStatus = {
    ProtoEnum.WorldPlayerStatusType.WPST_SLIDING,
    ProtoEnum.WorldPlayerStatusType.WPST_FALLING,
    ProtoEnum.WorldPlayerStatusType.WPST_MANTLE,
    ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE
  }
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_WATER_STATUS_CHANGE, self.OnWaterStatusChange)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CLIMB_DOWN, self.OnClimbDownCondition)
  self:OnPlayerStatusChanged()
  UE4.FCycleCounter.Create("UMG_Ability_Slot_Jump_C:OnPlayerStatusChanged")
  if self:IsPCMode() then
    local Padding = UE4.FMargin()
    Padding.Left = 0
    Padding.Top = 0
    Padding.Right = 0
    Padding.Bottom = 0
    self.Slot:SetOffsets(Padding)
    self:SetRenderOpacity(0)
  end
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MOVE, self, self.RefreshFlag)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_Jump_C", self, NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalTouchStart)
  self.slotIndex = 2
  self.slotSubIndex = 1
end

function UMG_Ability_Slot_Jump_C:OnDestruct()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_CLIMB_DOWN, self.OnClimbDownCondition)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_WATER_STATUS_CHANGE, self.OnWaterStatusChange)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalTouchStart)
  Base.OnDestruct(self)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MOVE, self, self.RefreshFlag)
end

function UMG_Ability_Slot_Jump_C:ReBindPlayer()
  Base.ReBindPlayer(self)
  self:BindAbility(AbilityHelperManager.GetHelper(AbilityID.PLAYER_JUMP))
end

function UMG_Ability_Slot_Jump_C:OnRefreshByUserReasonChanged()
  Base.OnRefreshByUserReasonChanged(self)
  self:RefreshFlag()
end

function UMG_Ability_Slot_Jump_C:SlotVisibilityChangeFunc(visible, slotIndex, slotSubIndex)
  if slotIndex == self.slotIndex and slotSubIndex ~= self.slotSubIndex then
    if visible then
      if self.out ~= nil and self:IsAnimationPlaying(self.out) then
        self:StopAnimation(self.out)
      end
      if nil ~= self.show and self:IsAnimationPlaying(self.show) then
        self:StopAnimation(self.show)
      end
      if nil ~= self.press and self:IsAnimationPlaying(self.press) then
        self:StopAnimation(self.press)
      end
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self.ParentPanel then
        self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.shortCut = 3 == slotSubIndex
    elseif 3 == slotSubIndex then
      self.shortCut = false
      self:RefreshFlag()
    end
  end
end

function UMG_Ability_Slot_Jump_C:RefreshUI()
  if not self._abilityHelper then
    self:SetVisible(false)
    return
  end
  if self._isVisible then
    local IconPath = self._abilityHelper:GetIcon(self.localPlayer, self._isBlock)
    if nil ~= IconPath and "" ~= IconPath then
      self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if IconPath ~= self.oldIconPath then
        self.oldIconPath = IconPath
        self.BP_UIIcon:SetPath(IconPath)
      end
    else
      self._isVisible = false
      self:SetVisible(self._isVisible, true)
      return
    end
  end
  self:SetVisible(self._isVisible and not self.shortCut)
end

function UMG_Ability_Slot_Jump_C:IsBlock()
  return self._isBlock
end

function UMG_Ability_Slot_Jump_C:OnCast(isPress)
  if not (self._abilityHelper and self.localPlayer) or not self.localPlayer.viewObj then
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    return
  end
  if caster.viewObj:GetMovementComponent().bIsMantle then
    return
  end
  if not (caster.viewObj and caster.viewObj.Mesh) or not caster.viewObj.Mesh:GetAnimInstance() then
    return
  end
  if caster.viewObj.Mesh:GetAnimInstance().bIsPlayingAnyMontage then
    local bInTakePhoto = _G.TakePhotosModuleCmd and _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.IfInTakePhotoState)
    if not caster.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR) and not bInTakePhoto then
      return
    end
  end
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_MOVE)
  if bBan then
    return
  end
  local UIBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP)
  if UIBan then
    return
  end
  local castType = isPress and Enum.SceneAbilitySlotCastType.SASCT_PRESS or Enum.SceneAbilitySlotCastType.SASCT_CLICK
  local caster = self.localPlayer
  local statusComponent = caster.statusComponent
  self.localPlayer.viewObj:Jump()
  return true
end

function UMG_Ability_Slot_Jump_C:OnPlayerStatusChanged(...)
  self:RefreshFlag()
end

function UMG_Ability_Slot_Jump_C:RefreshFlag()
  if self.OnRefreshHandle then
    DelayManager:CancelDelayById(self.OnRefreshHandle)
    self.OnRefreshHandle = nil
  end
  self.OnRefreshHandle = DelayManager:DelayFrames(1, function()
    self.OnRefreshHandle = nil
    if not UE.UObject.IsValid(self) then
      return
    end
    self:InternalRefreshFlag()
  end)
end

function UMG_Ability_Slot_Jump_C:OnWaterStatusChange(newStatus, oldStatus)
  self:RefreshFlag()
end

function UMG_Ability_Slot_Jump_C:InternalRefreshFlag()
  UE4.FCycleCounter.Start("UMG_Ability_Slot_Jump_C:OnPlayerStatusChanged")
  if not (self._unVisibleStatus and self._blockStatus) or not self.localPlayer then
    Log.Debug("UMG_Ability_Slot_Jump_C may destroyed")
    UE4.FCycleCounter.Stop()
    return
  end
  local statusComponent = self.localPlayer.statusComponent
  self._isVisible = not self._canClimbDown
  for _, value in pairs(self._unVisibleStatus) do
    if statusComponent:HasStatus(value) then
      self._isVisible = false
      break
    end
  end
  self._isBlock = false
  for _, value in pairs(self._blockStatus) do
    if statusComponent:HasStatus(value) then
      self._isBlock = true
      break
    end
  end
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_MOVE)
  if bBan then
    self._isVisible = false
  end
  if self:IsHiddenByUser() then
    self._isVisible = false
  end
  local UIBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP)
  if UIBan then
    self._isVisible = false
    self._isBlock = true
  end
  self:RefreshUI()
  UE4.FCycleCounter.Stop()
end

function UMG_Ability_Slot_Jump_C:OnClimbDownCondition(canClimbDown)
  self._canClimbDown = canClimbDown
  self:OnPlayerStatusChanged()
end

function UMG_Ability_Slot_Jump_C:CancelMagicThrow()
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:SendEvent(PlayerModuleEvent.ON_END_THROW, false)
  if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  end
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, false)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ShowAutoLockIcon, true)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
end

function UMG_Ability_Slot_Jump_C:OnSlotPressed(bind)
  if not (self:IsPCMode() or self._isVisible) or self._isBlock then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(self.SoundID, "UMG_Ability_Slot_C:OnSlotPressed")
  local succeed = self:OnCast(true)
  if not self._isBlock and succeed and self.press then
    self:PlayAnimation(self.press)
  end
end

function UMG_Ability_Slot_Jump_C:OnSlotReleased(bind)
end

function UMG_Ability_Slot_Jump_C:OnSlotClicked(bind)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(self.SoundID, "UMG_Ability_Slot_C:OnSlotPressed")
  self:OnCast(false)
end

function UMG_Ability_Slot_Jump_C:OnPCKey()
  if self:IsPCMode() then
    self:OnSlotPressed()
  else
    if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
      return
    end
    self:OnSlotPressed()
  end
end

function UMG_Ability_Slot_Jump_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Ability_Slot_Jump_C:OnGlobalTouchStart(touchIndex, pos)
  if self:IsPCMode() then
    return
  end
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if not mainUIModule or not mainUIModule.bAiming then
    return
  end
  if not self._isVisible or self._isBlock then
    return
  end
  local buttonPos, _ = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), self.Btn_Slot:GetCachedGeometry(), UE4.FVector2D(0, 0))
  if buttonPos.X <= 0 or buttonPos.Y <= 0 then
    return
  end
  local buttonSize = self.Btn_Slot:GetDesiredSize()
  if not buttonSize or buttonSize.X <= 0 or buttonSize.Y <= 0 then
    return
  end
  local touchPos = UE4.FVector2D(pos.X, pos.Y)
  if touchPos.X >= buttonPos.X and touchPos.X <= buttonPos.X + buttonSize.X and touchPos.Y >= buttonPos.Y and touchPos.Y <= buttonPos.Y + buttonSize.Y then
    self:OnSlotPressed()
  end
end

return UMG_Ability_Slot_Jump_C
