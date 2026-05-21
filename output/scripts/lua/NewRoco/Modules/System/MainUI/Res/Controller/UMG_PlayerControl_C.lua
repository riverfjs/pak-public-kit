local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local UMG_PlayerControl_C = _G.NRCViewBase:Extend("UMG_PlayerControl_C")

function UMG_PlayerControl_C:OnConstruct()
  self:AddEventListener()
  self.DpiScaleY = 1
  self.bAiming = false
  self:SetAimJoystickVisible(false)
  self:BindInputAction()
  self:SetChildViews(self.UMG_Aim_Joystick)
  self.UMG_Aim_Joystick:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PlayerControl_C:OnDestruct()
  self:RemoveEventListener()
  self:UnBindInputAction()
end

function UMG_PlayerControl_C:ModifyPanelScaleOnPC(MainUIScale, MainUIPadding)
  local externWidth = -1 * (MainUIPadding.Left + MainUIPadding.Right) * MainUIScale.X
  local externHeight = -1 * (MainUIPadding.Top + MainUIPadding.Bottom) * MainUIScale.Y
  local TUIResolutionX = 2340
  local TUIResolutionY = 1080
  local PCScale = UE4.FVector2D(1 + externWidth / TUIResolutionX, 1 + externHeight / TUIResolutionY)
  self.UMG_TalkingBboutBubbles_Panel.Panel:SetRenderScale(PCScale)
end

function UMG_PlayerControl_C:OnEnable()
  self:UseMainUIChatBubbleParent()
end

function UMG_PlayerControl_C:OnDisable()
  Log.Debug("UMG_PlayerControl_C:OnDisable, \228\184\187\231\149\140\233\157\162(UMG_PlayerControl_C) \228\187\142Panel\228\184\138\231\167\187\233\153\164\230\137\128\230\156\137\230\176\148\230\179\161")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdHideChatBubbles, self.UMG_TalkingBboutBubbles_Panel.Panel)
end

function UMG_PlayerControl_C:OnTick(DeltaTime)
  local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
  if FriendModule then
    FriendModule:UpdateChatBubbles(DeltaTime)
  end
end

function UMG_PlayerControl_C:AddEventListener()
  self.CancelAimBtn.OnClicked:Add(self, self.OnCancelAimBtnClick)
  self.ShapeshiftBtn.OnClicked:Add(self, self.OnShapeshiftBtnClick)
  local caster = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if caster then
    caster.abilityComponent:AddEventListener(self, AbilityEvent.ON_BUFF_LOOP_END, self.OnLoopEnd)
  end
  NRCEventCenter:RegisterEvent("UMG_PlayerControl_C", self, MainUIModuleEvent.ChangeMoveJoystickMode, self.OnChangeModule)
end

function UMG_PlayerControl_C:OnLoopEnd()
  if self.UMG_Aim_Joystick.AimJoystickMode == MainUIModuleEnum.ShowAimJoystick.Ability then
    self.UMG_Aim_Joystick.bCancelHovered = true
    self.UMG_Aim_Joystick._abilityHelper = nil
    self.UMG_Aim_Joystick:LeaveAimState()
  end
end

function UMG_PlayerControl_C:SetAimJoystickMode(Mode, abilityID)
  self.UMG_Aim_Joystick:SetAimJoystickMode(Mode, abilityID)
end

function UMG_PlayerControl_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:BindAction("IA_Shapeshift", self, "OnPcShapeshiftBtnClick", UE.ETriggerEvent.Triggered)
  end
end

function UMG_PlayerControl_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:UnBindAction("IA_Shapeshift")
  end
end

function UMG_PlayerControl_C:OnPcShapeshiftBtnClick()
  if self.ShapeshiftBtn:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:OnShapeshiftBtnClick()
  end
end

function UMG_PlayerControl_C:UpdateBindInputAction()
  self:BindInputAction()
  self.UMG_Aim_Joystick:UpdateBindInputAction()
end

function UMG_PlayerControl_C:RemoveEventListener()
  local caster = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if caster then
    caster.abilityComponent:RemoveEventListener(self, AbilityEvent.ON_BUFF_LOOP_END, self.OnLoopEnd)
  end
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.ChangeMoveJoystickMode, self.OnChangeModule)
end

function UMG_PlayerControl_C:SetAimJoystickVisible(visible)
  self:PCKeyShow()
  if visible then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1117, "UMG_PlayerControl_C:SetAimJoystickVisible")
    self.UMG_Aim_Joystick:ShowAimJoystickPanel(true)
    self.bAiming = true
    self.CancelAimBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local isRideAbility = localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    if self:IsPCMode() then
      if not isRideAbility then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelAimBtnVisibility, true)
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
      else
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelAimBtnVisibility, false)
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, true)
      end
    end
    local vis = UE4.ESlateVisibility.Collapsed
    if not isRideAbility then
      local itemId = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedItemId)
      vis = 100728 == itemId and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
    end
    self.ShapeshiftBtn:SetVisibility(vis)
    if self:IsPCMode() then
      _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCShapeShiftBtnVisibility, vis == UE4.ESlateVisibility.Visible)
    end
  else
    self.UMG_Aim_Joystick:ShowAimJoystickPanel(false)
    self.bAiming = false
    self.CancelAimBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self:IsPCMode() then
      local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if not localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelAimBtnVisibility, false)
      end
      _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
    end
    self.ShapeshiftBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self:IsPCMode() then
      _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCShapeShiftBtnVisibility, false)
    end
  end
end

function UMG_PlayerControl_C:OnCancelAimBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1118, "UMG_PlayerControl_C:OnCancelAimBtnClick")
  self.UMG_Aim_Joystick.bCancelHovered = true
  self.UMG_Aim_Joystick.MouseLeftPressd = nil
  self.UMG_Aim_Joystick:ReleaseAim()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ClearThrowCacheData)
end

function UMG_PlayerControl_C:OnShapeshiftBtnClick()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local buff = localPlayer.buffComponent:GetBuff("MagicTransformBuff")
  if buff then
    buff.CastSelf = true
  end
  self.UMG_Aim_Joystick.bCancelHovered = false
  self.UMG_Aim_Joystick.MouseLeftPressd = nil
  self.UMG_Aim_Joystick:ReleaseAim()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ClearThrowCacheData)
end

function UMG_PlayerControl_C:OnChangeModule(isFullScreen)
  self.bFullScreen = isFullScreen
end

function UMG_PlayerControl_C:OnPcTouchStart()
  if MainUIModuleCmd then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListVisible, false)
  end
end

function UMG_PlayerControl_C:UseMainUIChatBubbleParent()
  Log.Debug("UMG_PlayerControl_C:UseMainUIChatBubbleParent, \228\184\187\231\149\140\233\157\162(UMG_PlayerControl_C) \230\179\168\229\134\140\228\184\186\230\176\148\230\179\161\231\136\182Panel")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseMainUIChatBubblesParent)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdChangeChatBubblesParent, self.UMG_TalkingBboutBubbles_Panel.Panel)
end

function UMG_PlayerControl_C:PCKeyShow()
  if self:IsPCMode() then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Control_Joystick:SetRenderOpacity(0)
    self.UMG_Control_Joystick:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.CancelAimBtn:SetRenderOpacity(0)
    self.ShapeshiftBtn:SetRenderOpacity(0)
  else
    self.ScrollPCKey:SetKeyVisibility(false)
  end
end

function UMG_PlayerControl_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

return UMG_PlayerControl_C
