require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local UMG_Ability_Slot_RideJump_C = Base:Extend("UMG_Ability_Slot_RideJump_C")
local CHECK_INTERVAL = 0.5

function UMG_Ability_Slot_RideJump_C:OnConstruct()
  Base.OnConstruct(self)
  self._lastIsVisible = true
  self._curCheckInterval = CHECK_INTERVAL
  self.slotIndex = 2
  self.slotSubIndex = 4
  UE4.FCycleCounter.Create("UMG_Ability_Slot_RideJump_C:OnPlayerStatusChanged")
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_RideJump_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_RideJump_C", self, NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalTouchStart)
end

function UMG_Ability_Slot_RideJump_C:OnDestruct()
  Base.OnDestruct(self)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalTouchStart)
end

function UMG_Ability_Slot_RideJump_C:OnActive()
  self:ShowPetSwitch(false)
end

function UMG_Ability_Slot_RideJump_C:OnDeactive()
end

function UMG_Ability_Slot_RideJump_C:ReBindPlayer()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.OnEnvMask)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnRideMoveTypeChange)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH, self.OnRideMoveTypeChange)
  end
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.localPlayer then
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.OnEnvMask)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnRideMoveTypeChange)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH, self.OnRideMoveTypeChange)
  end
  self:OnPlayerStatusChanged(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
end

function UMG_Ability_Slot_RideJump_C:BindAbility(abilityHelper)
  Base.BindAbility(self, abilityHelper)
  local caster = self.localPlayer
  if self._abilityHelper then
    self._hasAbility = true
    self:RefreshView()
  else
    self:UnbindAbility(abilityHelper)
  end
end

function UMG_Ability_Slot_RideJump_C:UpdateUi(isAbilityAim)
  self.isAbilityAim = isAbilityAim
  self._isVisible = not isAbilityAim
  local isFocus = not NRCEnv:IsLocalMode()
  if self._isVisible then
    self:BeforeSetVisible(true, isFocus)
  else
    self:BeforeSetVisible(false, isFocus)
  end
end

function UMG_Ability_Slot_RideJump_C:UnbindAbility(abilityHelper)
  self._abilityHelper = nil
  self._hasAbility = false
  self:RefreshView()
end

function UMG_Ability_Slot_RideJump_C:OnPlayerStatusChanged(status, value, opCode)
  local caster = self.localPlayer
  if not caster then
    return
  end
  local statusComponent = caster.statusComponent
  UE4.FCycleCounter.Start("UMG_Ability_Slot_RideJump_C:OnPlayerStatusChanged")
  self._hasChangeEffect = false
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      self._hasChangeEffect = status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
      if not self._hasAbility then
        self:BindAbility(AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL_JUMP))
      else
        self:RefreshView()
      end
    elseif self._hasAbility then
      self:UnbindAbility()
    end
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    self:RefreshView()
  end
  UE4.FCycleCounter.Stop()
end

function UMG_Ability_Slot_RideJump_C:OnRideMoveTypeChange()
  self:RefreshView()
end

function UMG_Ability_Slot_RideJump_C:RefreshView()
  if self.OnRefreshHandle then
    DelayManager:CancelDelayById(self.OnRefreshHandle)
    self.OnRefreshHandle = nil
  end
  self.OnRefreshHandle = DelayManager:DelayFrames(1, function()
    self.OnRefreshHandle = nil
    if not UE.UObject.IsValid(self) then
      return
    end
    self:InternalRefreshView()
  end)
end

function UMG_Ability_Slot_RideJump_C:GetRelationTreePanelShow()
  if _G.RelationTreeCmd then
    return _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpeningRelationPanel)
  end
  return nil
end

function UMG_Ability_Slot_RideJump_C:UIBan(FuncId)
  if FuncId == Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT then
    self.bInBanCondition = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow()
    self:RefreshView()
  end
end

function UMG_Ability_Slot_RideJump_C:OnShortCutFlyChange(ShowShortCut)
  self._showShortCut = ShowShortCut
  self:RefreshView()
end

function UMG_Ability_Slot_RideJump_C:InternalRefreshView()
  local playChange = self._hasChangeEffect
  self._hasChangeEffect = false
  if not self._hasAbility then
    self._isVisible = false
    self:BeforeSetVisible(false)
    return
  end
  if not self.localPlayer or not UE4.UObject.IsValid(self.localPlayer.viewObj) then
    return
  end
  local UIBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP)
  if UIBan then
    self._isVisible = false
    self:BeforeSetVisible(false)
    return
  end
  local buff = self.localPlayer.buffComponent:GetBuff("Transform_Buff")
  local hasStatus = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
  local isInTransform = hasStatus or buff
  local preSetVisible = not self._showShortCut
  if self._isVisible ~= preSetVisible then
    self._isVisible = preSetVisible
    self:BeforeSetVisible(self._isVisible)
    if not self._isVisible then
      return
    end
  end
  if self.localPlayer.viewObj.BP_RideComponent.bIsDoubleRide2p then
    self._isVisible = false
  end
  local IconPath = self:GetIcon()
  if nil ~= IconPath and "" ~= IconPath then
    self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local pressIcon = self:GetPressIcon()
    if nil ~= pressIcon and "" ~= pressIcon then
      self.Image_Bg:SetPath(pressIcon)
    end
    self.BP_UIIcon:SetPath(IconPath)
    if IconPath ~= self.oldIconPath then
      self.oldIconPath = IconPath
    end
  else
    if self._isVisible then
      self._hasChangeEffect = playChange
    end
    self._isVisible = false
    self:BeforeSetVisible(false, true)
    return
  end
  if self._isVisible then
    if playChange then
      self:PlayAnimation(self.Show_change)
    end
    self:BeforeSetVisible(true)
  else
    self:BeforeSetVisible(false)
  end
  self:SetPcSlotText()
end

function UMG_Ability_Slot_RideJump_C:GetIcon()
  if self._abilityHelper then
    return self._abilityHelper:GetIcon(self.localPlayer)
  end
  return nil
end

function UMG_Ability_Slot_RideJump_C:GetPressIcon()
  if self._abilityHelper then
    return self._abilityHelper:GetPressIcon(self.localPlayer)
  end
  return nil
end

function UMG_Ability_Slot_RideJump_C:OnSlotPressed(bind)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(self.SoundID, "UMG_Ability_Slot_C:OnSlotPressed")
  local errorCode = self:OnCast(true)
  if errorCode == AbilityErrorCode.NO_ERROR then
    self:PlayAnimation(self.press)
  end
end

function UMG_Ability_Slot_RideJump_C:OnCast(isPress)
  if not self._hasAbility or not isPress then
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    return
  end
  local isBlock = self._abilityHelper:IsBlock(caster)
  if isBlock then
    return AbilityErrorCode.ABILITY_IS_CASTING
  end
  local errorCode = self._abilityHelper:CanCastAbility(caster)
  if errorCode == AbilityErrorCode.NO_ERROR then
    self._abilityHelper:HandleStatus(caster)
    self.localPlayer.viewObj.WalkRun = false
  end
  if errorCode == AbilityErrorCode.VITALITY_NOT_ENOUGH and MainUIModuleCmd then
    NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnDashAbilityVitalityDeficiency)
  end
  if errorCode == AbilityErrorCode.TASK_AREA_BAN and self.localPlayer and self.localPlayer.ShowTaskAreaRideAllBanTips and isPress then
    self.localPlayer:ShowTaskAreaRideAllBanTips()
  end
  if errorCode ~= AbilityErrorCode.NO_ERROR then
    Log.Debug(AbilityErrorCode.ToString(errorCode))
  end
  return errorCode
end

function UMG_Ability_Slot_RideJump_C:OnPCKey(action_type)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if not self.localPlayer then
    Log.Error("UMG_Ability_Slot_RideJump_C:OnPCKey Local player is nil")
    return
  end
  if 0 == action_type then
    self.Btn_Slot:OnPress()
    self:OnSlotPressed()
  else
    self.Btn_Slot:OnRelease()
    self:OnSlotReleased()
  end
end

function UMG_Ability_Slot_RideJump_C:SetPcSlotText()
  if self:IsPCMode() and SystemSettingModuleCmd then
    local pcKey = self.Text_PCKey
    if not _G.UE4Helper.IsPCMode() then
      pcKey = self.Text_PCKey
    elseif self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_AbilitySlot_SecondMainStart")
    if "" ~= image then
      pcKey:SetImageMode(image)
    else
      pcKey:SetText(text)
    end
  end
end

function UMG_Ability_Slot_RideJump_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Ability_Slot_RideJump_C:BeforeSetVisible(visible, isFocus)
  if not visible and self.ProgressBar_out and self:IsAnimationPlaying(self.ProgressBar_out) then
    self.CanvasPanel_83:setVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetVisible(visible, isFocus)
end

function UMG_Ability_Slot_RideJump_C:OnGlobalTouchStart(touchIndex, pos)
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

return UMG_Ability_Slot_RideJump_C
