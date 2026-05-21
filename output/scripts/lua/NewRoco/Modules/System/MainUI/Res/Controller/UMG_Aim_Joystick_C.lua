local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_Aim_Joystick_C = _G.NRCViewBase:Extend("UMG_Aim_Joystick_C")

function UMG_Aim_Joystick_C:OnConstruct()
  self:AddEventListener()
  self:BindInputAction()
  self.CacheMoveDirVector3D = UE4.FVector()
  self.DpiScaleY = 1
  self.bCancelHovered = false
  self._playerModule = NRCModuleManager:GetModule("PlayerModule")
  self.oriJoystickPos = self.Joystick.Slot:GetPosition()
  self.bShowThumgNoMove = false
  self.AimJoystickMode = MainUIModuleEnum.ShowAimJoystick.Throw
  self.JoystickThumb_NoMove:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.JoystickViewPos = nil
  self.TouchIndex = nil
  self.StartPos = nil
  self.PrePos = nil
  self.CurPos = nil
  self.TouchListenList = {}
  self.IsGetTouchIndex = false
  self.IsGetPointerIndex = false
  self.JoystickArea:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Aim_Joystick_C:OnDestruct()
  self:RemoveEventListener()
  self:UnBindInputAction()
end

function UMG_Aim_Joystick_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    local actions = {
      {
        name = "IA_AimStart",
        method = "AimStart"
      },
      {name = "IA_AimEnd", method = "AimEnd"},
      {
        name = "IA_AimCancel",
        method = "AimCancel"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
end

function UMG_Aim_Joystick_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    local actions = {
      {
        name = "IA_AimStart"
      },
      {name = "IA_AimEnd"},
      {
        name = "IA_AimCancel"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
  end
end

function UMG_Aim_Joystick_C:UpdateBindInputAction()
  self:BindInputAction()
end

function UMG_Aim_Joystick_C:OnInterruptAim()
  self:OnMouseRightKey(0, true)
end

function UMG_Aim_Joystick_C:AimStart()
  self:OnMouseLeftKey(0)
end

function UMG_Aim_Joystick_C:AimEnd()
  self:OnMouseLeftKey(1)
end

function UMG_Aim_Joystick_C:AimCancel()
  self:OnMouseRightKey(0)
end

function UMG_Aim_Joystick_C:OnLostFocus()
  self:OnMouseLeftKey(1, true)
end

function UMG_Aim_Joystick_C:AltFocus(action_type)
  if 0 == action_type then
    self:OnMouseLeftKey(1, true)
  elseif 1 == action_type then
  end
end

function UMG_Aim_Joystick_C:TopBlockImcChange(lastTopImc, newTopImc)
  if "IMC_MainUIDefault" == lastTopImc then
    self:OnMouseLeftKey(1, true)
  end
end

function UMG_Aim_Joystick_C:SetAimJoystickMode(mode, abilityID)
  if mode then
    Log.Debug("UMG_Aim_Joystick_C:SetAimJoystickMode", mode, abilityID)
    if abilityID then
      self._abilityHelper = AbilityHelperManager.GetHelper(abilityID)
    end
    local pos = UE4.FVector2D(-500.0, -260.0)
    if mode == MainUIModuleEnum.ShowAimJoystick.Ability then
      pos = UE4.FVector2D(-319, -157)
    end
    self.Joystick.Slot:SetPosition(pos)
    self.AimJoystickMode = mode
  end
end

function UMG_Aim_Joystick_C:AddEventListener()
  self.CancelBtn.OnClicked:Add(self, self.OnCancelBtnClicked)
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_INTERRUPT_AIM, self.OnInterruptAim)
  ScenePlayerInputManager.RegisterActionEvent("Alt", self, self.AltFocus)
  _G.NRCEventCenter:RegisterEvent("UMG_Aim_Joystick_C", self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  _G.NRCEventCenter:RegisterEvent("UMG_Aim_Joystick_C", self, NRCGlobalEvent.OnRocoTouchStart, self.OnJoystickRocoTouchStart)
  _G.NRCEventCenter:RegisterEvent("UMG_Aim_Joystick_C", self, NRCGlobalEvent.OnRocoTouchMove, self.OnJoystickRocoTouchMove)
  _G.NRCEventCenter:RegisterEvent("UMG_Aim_Joystick_C", self, NRCGlobalEvent.OnRocoTouchEnd, self.OnJoystickRocoTouchEnd)
  _G.NRCEventCenter:RegisterEvent("MultiTouchModule", self, NRCGlobalEvent.OnApplicationHasReactivated, self.OnAimJoystickHasReactivated)
  _G.NRCEventCenter:RegisterEvent("UMG_Aim_Joystick_C", self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
end

function UMG_Aim_Joystick_C:RemoveEventListener()
  self.CancelBtn.OnHovered:Remove(self, self.OnCancelBtnHovered)
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_INTERRUPT_AIM, self.OnInterruptAim)
  end
  ScenePlayerInputManager.UnRegisterActionEvent("Alt", self, self.AltFocus)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchStart, self.OnJoystickRocoTouchStart)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchMove, self.OnJoystickRocoTouchMove)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchEnd, self.OnJoystickRocoTouchEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasReactivated, self.OnAimJoystickHasReactivated)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
end

function UMG_Aim_Joystick_C:OnSceneLoaded()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_INTERRUPT_AIM, self.OnInterruptAim)
  end
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_INTERRUPT_AIM, self.OnInterruptAim)
end

function UMG_Aim_Joystick_C:OnJoystickRocoTouchStart(touchIndex, pos)
  local touchData = {
    touchIndex = touchIndex,
    touchPos = UE4.FVector2D(pos.X, pos.Y)
  }
  table.insert(self.TouchListenList, touchData)
end

function UMG_Aim_Joystick_C:OnJoystickRocoTouchMove(touchIndex, pos)
  self:InitTouchIndex()
  if self.TouchIndex ~= touchIndex then
    return
  end
  local rangeMin = 0
  local moveDir = pos - self.StartPos
  local length = moveDir:Size()
  self.CurPos = UE4.FVector2D(pos.X, pos.Y)
  local dir = self.CurPos - self.PrePos
  self.PrePos = UE4.FVector2D(pos.X, pos.Y)
  if rangeMin < length then
    dir.X = dir.X * _G.UserSettingManager.camera_rotate_aim_yaw
    dir.Y = dir.Y * _G.UserSettingManager.camera_rotate_aim_pitch
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TURN, dir, false)
    moveDir:Normalize()
    self.CacheMoveDirVector3D.X = moveDir.X
    self.CacheMoveDirVector3D.Y = moveDir.Y
    local DirRotator = self.CacheMoveDirVector3D:ToRotator()
    self.JoystickThumb_NoMove:SetRenderTransformAngle(DirRotator.yaw)
    if self.JoystickThumb_NoMove:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      self.JoystickThumb_NoMove:SetVisibility(UE4.ESlateVisibility.Visible)
      if self:IsPCMode() then
        self.Joystick:SetRenderOpacity(0)
      end
    end
  end
end

function UMG_Aim_Joystick_C:OnJoystickRocoTouchEnd(touchIndex, inputLimitFlag)
  self:InitTouchIndex()
  for i = 1, #self.TouchListenList do
    if self.TouchListenList[i].touchIndex == touchIndex then
      table.remove(self.TouchListenList, i)
      break
    end
  end
  if not self.IsGetPointerIndex and inputLimitFlag then
    return
  end
  if self.TouchIndex ~= touchIndex then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1122, "UMG_Aim_Joystick_C:OnJoystickRocoTouchEnd")
  self:ReleaseAim()
end

function UMG_Aim_Joystick_C:LeaveAimState()
  self.JoystickThumb_NoMove:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.AimJoystickMode == MainUIModuleEnum.ShowAimJoystick.Throw then
    local itemId = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedItemId)
    local bagItemConf
    if 0 ~= itemId then
      bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
    end
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if self.bCancelHovered then
      if player then
        player:SendEvent(PlayerModuleEvent.ON_END_THROW, false)
        if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
          player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
        end
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
      end
    elseif player then
      player:SendEvent(PlayerModuleEvent.ON_END_THROW, true)
      if bagItemConf and (GlobalConfig.TestMagicAbility or bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_MAGIC or bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL) then
        if bagItemConf.type == _G.Enum.BagItemType.BI_MAGIC then
          local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_STAR)
          local MagicConf = _G.DataConfigManager:GetMagicBaseConf(bagItemConf.magic_id)
          if MagicConf then
            helper = AbilityHelperManager.GetHelper(MagicConf.sceneability)
          end
          local buff = helper:GetBuff(player)
          if buff then
            buff:OnCastMagic()
          end
        end
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, false)
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ShowAutoLockIcon, true)
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
        return
      end
    end
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, false)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ShowAutoLockIcon, true)
  else
    self.AimJoystickMode = MainUIModuleEnum.ShowAimJoystick.Throw
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      player:SendEvent(PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, not self.bCancelHovered)
    end
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, false)
  end
end

function UMG_Aim_Joystick_C:OnCancelBtnHovered()
  self.bCancelHovered = true
end

function UMG_Aim_Joystick_C:OnCancelBtnOnUnhovered()
  self.bCancelHovered = false
end

function UMG_Aim_Joystick_C:OnCancelBtnClicked()
  self.bCancelHovered = true
  self:ReleaseAim()
end

function UMG_Aim_Joystick_C:TryCallPlayerModule(Event, ...)
  if self._playerModule then
    self._playerModule:DispatchEvent(Event, ...)
  end
end

function UMG_Aim_Joystick_C:ReleaseAim()
  self.TouchIndex = nil
  self.PrePos = nil
  self.CurPos = nil
  self.TouchListenList = {}
  self.IsGetTouchIndex = false
  self:LeaveAimState()
end

function UMG_Aim_Joystick_C:OnInVisible()
  self.bCancelHovered = true
  self:ReleaseAim()
end

function UMG_Aim_Joystick_C:ShowAimJoystickPanel(enable)
  if enable then
    if self.Visibility == UE.ESlateVisibility.Collapsed then
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self:SetRenderOpacity(0)
      if not self:IsPCMode() then
        self.IsGetTouchIndex = true
        self:InitJoystickViewPos()
        self.bCancelHovered = false
        self.JoystickThumb_NoMove:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:SetRenderOpacity(1)
      end
    end
  elseif self.Visibility ~= UE.ESlateVisibility.Collapsed then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local isRideAll = localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if isRideAll then
      self.bCancelHovered = true
      self:ReleaseAim()
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Aim_Joystick_C:InitTouchIndex()
  self:InitJoystickViewPos()
  if not self.TouchIndex and self.IsGetTouchIndex then
    self.IsGetPointerIndex = false
    local PointerIndex = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetAimJoystickPointerIndex, self.AimJoystickMode)
    local resultTouchIndex, resultTouchPos
    if -1 == PointerIndex then
      local minDist
      for _, touchData in ipairs(self.TouchListenList) do
        local targetPos
        if self.JoystickViewPos then
          targetPos = UE4.FVector2D(self.JoystickViewPos.X, self.JoystickViewPos.Y)
        else
          local Size = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
          targetPos = UE4.FVector2D(Size.X, Size.Y)
        end
        local dist = UE4.FVector.DistSquared2D(touchData.touchPos, targetPos)
        if not minDist or minDist > dist then
          resultTouchIndex = touchData.touchIndex
          resultTouchPos = UE4.FVector2D(touchData.touchPos.X, touchData.touchPos.Y)
          minDist = dist
        end
      end
    else
      for _, touchData in ipairs(self.TouchListenList) do
        if touchData.touchIndex == PointerIndex then
          resultTouchPos = UE4.FVector2D(touchData.touchPos.X, touchData.touchPos.Y)
          break
        end
      end
      resultTouchIndex = PointerIndex
      self.IsGetPointerIndex = true
    end
    if resultTouchIndex and resultTouchPos then
      self.TouchIndex = resultTouchIndex
      self.StartPos = UE4.FVector2D(resultTouchPos.X, resultTouchPos.Y)
      self.PrePos = UE4.FVector2D(resultTouchPos.X, resultTouchPos.Y)
      self.IsGetTouchIndex = false
      return
    end
    Log.Error("\230\138\149\230\142\183\230\140\137\233\146\174\232\142\183\229\143\150\228\184\141\229\136\176touchIndex\239\188\140\229\175\188\232\135\180\229\141\161\231\138\182\230\128\129\227\128\130\229\155\160\228\184\186TouchListenList\228\184\186\231\169\186\239\188\140\232\175\183\232\129\148\231\179\187koonickchen\239\188\129\239\188\129\239\188\129")
  end
end

function UMG_Aim_Joystick_C:OnAimJoystickHasReactivated()
  self:ReleaseAim()
end

function UMG_Aim_Joystick_C:InitJoystickViewPos()
  if not self.JoystickViewPos then
    if NRCEnv:IsLocalMode() then
      local Size = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
      local joyPos = self.Joystick.Slot:GetPosition()
      self.JoystickViewPos = UE4.FVector2D(Size.X + joyPos.X, Size.Y + joyPos.Y)
    else
      local pos1, _ = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), self.JoystickBg:GetCachedGeometry(), UE4.FVector2D(0, 0))
      if pos1.X <= 0 or pos1.Y <= 0 then
        return
      end
      local joystickBgSize = self.JoystickBg:GetDesiredSize()
      self.JoystickViewPos = UE4.FVector2D(pos1.X + joystickBgSize.X / 2, pos1.Y + joystickBgSize.Y / 2)
    end
  end
end

function UMG_Aim_Joystick_C:OnMouseLeftKey(action_type, lostFocus)
  if self:IsPCMode() then
    local pos = self.Joystick.Slot:GetPosition()
    pos.x = -179.499756
    pos.y = -136.68103
    self.Joystick.Slot:SetPosition(pos)
  end
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed then
    return
  end
  if NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER):GetUEController().bShowMouseCursor and not lostFocus then
    return
  end
  if 0 == action_type then
  end
  if 1 == action_type then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1122, "UMG_Aim_Joystick_C:OnMouseLeftKey")
    self.bCancelHovered = false
    self:ReleaseAim()
  end
end

function UMG_Aim_Joystick_C:OnMouseRightKey(action_type, lostFocus)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed then
    return
  end
  if NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER):GetUEController().bShowMouseCursor and not lostFocus then
    return
  end
  if 0 == action_type then
    self:OnCancelBtnClicked()
  end
end

function UMG_Aim_Joystick_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

return UMG_Aim_Joystick_C
