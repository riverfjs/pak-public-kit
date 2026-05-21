local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local UMG_Control_Camera_C = _G.NRCUmgClass:Extend("UMG_Control_Camera_C")
local LocalUE4 = UE4

function UMG_Control_Camera_C:Construct()
  self:OnInit()
  self:OnBeforeOpen()
  _G.UpdateManager:UnRegister(self)
end

function UMG_Control_Camera_C:Destruct()
  if self._playerModule then
    self._playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_TOUCH_START_ROLEPLAY)
    self._playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_TOUCH_MOVE_ROLEPLAY)
    self._playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_TOUCH_END_ROLEPLAY)
  end
  _G.NRCUmgClass.Destruct(self)
end

function UMG_Control_Camera_C:OnInit()
  self.joystickPointIdx = -1
  self.startPos = LocalUE4.FVector2D()
  self._playerModule = NRCModuleManager:GetModule("PlayerModule")
  if self._playerModule then
    self._playerModule:RegisterEvent(self, PlayerModuleEvent.ON_TOUCH_START_ROLEPLAY, self.OnTouchStartRolePlayHandle)
    self._playerModule:RegisterEvent(self, PlayerModuleEvent.ON_TOUCH_MOVE_ROLEPLAY, self.OnTouchMoveRolePlayHandle)
    self._playerModule:RegisterEvent(self, PlayerModuleEvent.ON_TOUCH_END_ROLEPLAY, self.OnTouchEndRolePlayHandle)
  end
  self.enterRoleplay = false
  self.btnShowTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.longPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self._camera_yaw_speed_multiplier_yaw = _G.DataConfigManager:GetGlobalConfigNumByKeyType("camera_rotate_speed_yaw", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 3000) / 1000.0
  self._camera_yaw_speed_multiplier_pitch = _G.DataConfigManager:GetGlobalConfigNumByKeyType("camera_rotate_speed_pitch", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000) / 1000.0
  self.StartBtnShowTime = 0
  self.StartLongPressTime = 0
  self.IsBtnShow = false
  self.IsLongPressEnd = false
  self.IsCanClick = false
end

function UMG_Control_Camera_C:OnBeforeOpen()
end

function UMG_Control_Camera_C:GetInputModuleData()
  if self._playerModule then
    return self._playerModule.playerModuleData
  end
end

function UMG_Control_Camera_C:LuaOnTouchStarted(finger, pos)
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if _G.AppearanceModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  end
  if finger == self.TouchIndex then
    self.joystickPointIdx = finger
    self.startPos:Set(pos.X, pos.Y)
  end
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_START, false)
  if MainUIModuleCmd then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListVisible, false)
  end
  self:OnTouchStartRolePlayHandle()
end

function UMG_Control_Camera_C:LuaOnTouchMoved(finger, dir)
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if finger == self.joystickPointIdx and self._playerModule and not UE.UKismetMathLibrary.IsZero2D(dir) then
    self._camera_yaw_speed_multiplier_yaw = _G.UserSettingManager.camera_rotate_yaw or 0.065
    self._camera_yaw_speed_multiplier_pitch = _G.UserSettingManager.camera_rotate_pitch or 0.025
    dir.X = dir.X * self._camera_yaw_speed_multiplier_yaw
    dir.Y = dir.Y * self._camera_yaw_speed_multiplier_pitch
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TURN, dir, false)
  end
  if MainUIModuleCmd then
  end
end

function UMG_Control_Camera_C:LuaOnTouchEnded(finger)
  self.TouchIndex = -1
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_END, false)
  self:OnTouchEndRolePlayHandle()
end

function UMG_Control_Camera_C:OnMouseCaptureLost()
  Log.Debug("[OnMouseCaptureLost] UMG_Control_Camera_C")
  self:LuaOnTouchEnded()
end

function UMG_Control_Camera_C:LongPressDataInitialize(isEnter)
  self.enterRoleplay = isEnter
  self.StartBtnShowTime = 0
  self.IsBtnShow = false
  self.StartLongPressTime = 0
  self.Progress:showEndAni()
  self.bInFuncBan = false
  if isEnter then
    _G.UpdateManager:Register(self)
  else
    _G.UpdateManager:UnRegister(self)
  end
  if not isEnter then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").ROLEPLAYER
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  end
end

function UMG_Control_Camera_C:SetEnableEnterRolePlayer(isNotEnterRolePlay)
  self.isNotEnterRolePlay = isNotEnterRolePlay
  Log.Debug("SetEnableEnterRolePlayer", isNotEnterRolePlay)
end

function UMG_Control_Camera_C:OnTick(InDeltaTime)
  if self.isNotEnterRolePlay then
    return
  end
  if self.enterRoleplay == true then
    self.StartBtnShowTime = self.StartBtnShowTime + InDeltaTime
    if self.StartBtnShowTime >= self.btnShowTime and self:ClickPlayerModel() then
      self.IsBtnShow = true
      _G.NRCAudioManager:PlaySound2DAuto(40008017, "UMG_Control_Camera_C:OnTick")
    end
  end
  if self.IsBtnShow and not self.bInFuncBan then
    self.bInFuncBan = NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, true, true)
  end
  local bRealOpenEnabled = not self.bInFuncBan
  if self.IsBtnShow and bRealOpenEnabled then
    self.StartLongPressTime = self.StartLongPressTime + InDeltaTime
    self.Progress:showAni(nil, self.StartLongPressTime, self.longPressTime)
    if self.StartLongPressTime >= self.longPressTime and self:CheckCanOpenPanel() then
      _G.NRCProfilerLog:NRCClickBtn(true, "RolePlayMainPanel")
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OpenMainPanel)
      self:LongPressDataInitialize(false)
    end
  end
end

function UMG_Control_Camera_C:ClickPlayerModel()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerCtrl = player and UE4.UGameplayStatics.GetPlayerControllerFromID(player.viewObj, 0)
  if playerCtrl then
    local pos = self.ScreenPos
    local WorldLocation, CamDir = playerCtrl:Abs_DeprojectScreenPositionToWorld(pos.X, pos.Y)
    local endPos = WorldLocation + CamDir * 1000
    local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(_G.UE4.ECollisionChannel.ECC_GameTraceChannel9)
    local OutHit, Res = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(playerCtrl, WorldLocation, endPos, TraceChannel, false, nil, 0, nil, true)
    if OutHit.Actor == player.viewObj then
      return true
    end
  end
  return false
end

function UMG_Control_Camera_C:LuaOnSetRolePlayStatus(status, screenPos)
  if 0 == status then
    self:OnTouchStartRolePlayHandle(screenPos)
  elseif 1 == status then
    self:OnTouchMoveRolePlayHandle(screenPos)
  elseif 2 == status then
    self:OnTouchEndRolePlayHandle(screenPos)
  end
end

function UMG_Control_Camera_C:OnTouchStartRolePlayHandle(_touchScreenPos)
  if _touchScreenPos then
    self.ScreenPos = _touchScreenPos
  end
  if self:CheckCanOpenPanel() then
    if _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain") then
      Log.Debug("OnTouchStartRolePlayHandle: IsSelectBtn")
      return
    end
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").ROLEPLAYER
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    self:LongPressDataInitialize(true)
  end
end

function UMG_Control_Camera_C:CheckCanOpenPanel()
  if not _G.RolePlayModuleCmd or not _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.CheckCanOpenMainPanel) then
    return false
  end
  if not self:ClickPlayerModel() then
    return false
  end
  return true
end

function UMG_Control_Camera_C:OnTouchMoveRolePlayHandle(_touchScreenPos)
  if _touchScreenPos then
    self.ScreenPos = _touchScreenPos
  end
end

function UMG_Control_Camera_C:OnTouchEndRolePlayHandle(_touchScreenPos)
  if _touchScreenPos then
    self.ScreenPos = _touchScreenPos
  end
  self:LongPressDataInitialize(false)
end

function UMG_Control_Camera_C:TryCallPlayerModule(Event, ...)
  if self._playerModule then
    self._playerModule:DispatchEvent(Event, ...)
  end
end

function UMG_Control_Camera_C:SetIsCanClick(_IsCanClick)
  self.IsCanClick = _IsCanClick
end

function UMG_Control_Camera_C:IsPCMode()
  if self.IsCanClick then
    return false
  else
    return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
  end
end

function UMG_Control_Camera_C:LuaOnPCTouchStart(pos)
end

return UMG_Control_Camera_C
