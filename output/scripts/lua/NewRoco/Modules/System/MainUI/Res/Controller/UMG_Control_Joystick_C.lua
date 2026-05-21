local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local UMG_Control_Joystick_C = NRCUmgClass("UMG_Control_Joystick_C")
local LocalUE4 = UE4
local MAX_LENGTH = 80
local THRESHOLD = 10
local TOUCH_ZONE = 2000

function UMG_Control_Joystick_C:Construct()
  _G.UpdateManager:Register(self)
  self._skipTick = false
  self.DpiScaleY = 1
  self:OnInit()
  self:OnBeforeOpen()
  NRCEventCenter:RegisterEvent("UMG_Control_Joystick_C", self, NRCGlobalEvent.OnApplicationWillDeactivate, self.OnAppDeActive)
end

function UMG_Control_Joystick_C:Destruct()
  _G.UpdateManager:UnRegister(self)
  NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillDeactivate, self.OnAppDeActive)
  _G.NRCUmgClass.Destruct(self)
end

function UMG_Control_Joystick_C:OnInit()
  self.joystickPointIdx = -1
  self.startPos = LocalUE4.FVector2D()
  self.joystickEnabled = false
  self.CacheTouchDirVector3D = LocalUE4.FVector()
  self.navLock = false
  self.isJoystickTouch = false
  self._playerModule = NRCModuleManager:GetModule("PlayerModule")
end

function UMG_Control_Joystick_C:OnBeforeOpen()
  self.oriThumbPos = self.JoystickThumb.Slot:GetPosition()
  self.oriJoystickPos = self.Joystick.Slot:GetPosition()
  self.isJoystickThumbNoMoveShow = false
  self:SetShow(false)
end

function UMG_Control_Joystick_C:OnAppDeActive()
  self:LuaOnTouchEnded(self.joystickPointIdx)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and UE.UObject.IsValid(player.viewObj) then
    player.viewObj:ConsumeMovementInputVector()
    player.viewObj:ConsumeMovementInputVector()
    player.movementComponent:ClearMoveInput()
  end
end

function UMG_Control_Joystick_C:SetShow(isShow)
  if self:IsPCMode() then
    self.JoystickSmall:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif isShow then
    self.Joystick:SetRenderOpacity(1)
    self.JoystickSmall:SetVisibility(LocalUE4.ESlateVisibility.Collapsed)
  else
    self.Joystick:SetRenderOpacity(0)
    self.JoystickSmall:SetVisibility(LocalUE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_Control_Joystick_C:GetInputModuleData()
  if self._playerModule then
    return self._playerModule.playerModuleData
  end
end

function UMG_Control_Joystick_C:RegularTouchStartedMove()
  local curPos = self.TouchPos
  local touchDir = curPos - self.startPos
  local length = touchDir:Size()
  if length > TOUCH_ZONE then
    return
  end
  touchDir:Normalize()
  self.joystickDir = touchDir
  if length > MAX_LENGTH then
    length = MAX_LENGTH
  end
  self.joystickDistance = length
  if self.joystickEnabled == false and length >= THRESHOLD then
    self.joystickEnabled = true
    local viewportSize = LocalUE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
    local borderheight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
    viewportSize.X = viewportSize.X - borderWidth * 2
    viewportSize.Y = viewportSize.Y - borderheight * 2
    local dpi = LocalUE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    local pos = LocalUE4.FVector2D(self.startPos.X, self.startPos.Y - viewportSize.Y)
    pos = LocalUE4.FVector2D(pos.X / dpi, -(-pos.Y / dpi))
    pos.X = pos.X * self.DpiScaleY
    pos.Y = pos.Y * self.DpiScaleY
    self.Joystick.Slot:SetPosition(pos)
  end
  if self.joystickEnabled then
    self.JoystickThumb.Slot:SetPosition(touchDir * length + self.oriThumbPos)
    if not self.isJoystickThumbNoMoveShow then
      self.isJoystickThumbNoMoveShow = true
      self:SetShow(true)
    end
    self.CacheTouchDirVector3D.X = touchDir.X
    self.CacheTouchDirVector3D.Y = touchDir.Y
    local DirRotator = self.CacheTouchDirVector3D:ToRotator()
    self.JoystickThumb_NoMove:SetRenderTransformAngle(DirRotator.Yaw)
  elseif self.isJoystickThumbNoMoveShow then
    self.isJoystickThumbNoMoveShow = false
    self:SetShow(false)
  end
end

function UMG_Control_Joystick_C:LuaOnTouchStarted(finger, pos)
  self._skipTick = false
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if self.navLock then
    Log.Debug("\229\176\157\232\175\149\230\137\147\231\160\180\229\175\188\232\136\170\231\138\182\230\128\129")
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local controller = localPlayer:GetUEController()
    controller:StopMovement()
    self.navLock = false
  end
  if finger == self.TouchIndex then
    self.joystickPointIdx = finger
    local lockJoystick = MainUIModuleCmd and NRCModuleManager:DoCmd(MainUIModuleCmd.GetMoveJoystickMode) or false
    if lockJoystick then
      local joystickPos = self.JoystickSmall.Slot:GetPosition()
      local offest_x = self.JoystickSmall.Slot:GetSize().x / 2
      local offest_y = self.JoystickSmall.Slot:GetSize().y / 2
      local dpi = LocalUE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      local viewportSize = LocalUE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
      local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
      local borderheight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
      viewportSize.X = viewportSize.X - borderWidth * 2
      viewportSize.Y = viewportSize.Y - borderheight * 2
      self.startPos:Set((joystickPos.x + offest_x) * dpi / self.DpiScaleY, viewportSize.Y + (joystickPos.y + offest_y) * dpi / self.DpiScaleY)
      self:RegularTouchStartedMove()
    else
      self.startPos:Set(pos.X, pos.Y)
    end
  end
  self.isJoystickTouch = true
  NRCModuleManager:DoCmd(MultiTouchModuleCmd.JoystickStartTouch)
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_START, true, finger == self.TouchIndex, self.joystickPointIdx)
  self:TryCallPlayerModule(PlayerModuleEvent.ON_TOUCH_START_ROLEPLAY, self.ScreenPos)
end

function UMG_Control_Joystick_C:LuaOnTouchMoved(finger, dir)
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if finger == self.joystickPointIdx then
    local curPos = self.TouchPos
    local touchDir = curPos - self.startPos
    local length = touchDir:Size()
    local lockJoystick = MainUIModuleCmd and NRCModuleManager:DoCmd(MainUIModuleCmd.GetMoveJoystickMode) or false
    if lockJoystick and not self.joystickEnabled and length > TOUCH_ZONE then
      return
    end
    touchDir:Normalize()
    self.joystickDir = touchDir
    if length > MAX_LENGTH then
      length = MAX_LENGTH
    end
    self.joystickDistance = length
    if self.joystickEnabled == false and length >= THRESHOLD then
      self.joystickEnabled = true
      local viewportSize = LocalUE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
      local dpi = LocalUE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
      local borderheight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
      viewportSize.X = viewportSize.X - borderWidth * 2
      viewportSize.Y = viewportSize.Y - borderheight * 2
      local pos = LocalUE4.FVector2D(self.startPos.X, self.startPos.Y - viewportSize.Y)
      pos = LocalUE4.FVector2D(pos.X / dpi, -(-pos.Y / dpi))
      pos.X = pos.X * self.DpiScaleY
      pos.Y = pos.Y * self.DpiScaleY
      self.Joystick.Slot:SetPosition(pos)
    end
    if self.joystickEnabled then
      self.JoystickThumb.Slot:SetPosition(touchDir * length + self.oriThumbPos)
      if not self.isJoystickThumbNoMoveShow then
        self.isJoystickThumbNoMoveShow = true
        self:SetShow(true)
      end
      self.CacheTouchDirVector3D.X = touchDir.X
      self.CacheTouchDirVector3D.Y = touchDir.Y
      local DirRotator = self.CacheTouchDirVector3D:ToRotator()
      self.JoystickThumb_NoMove:SetRenderTransformAngle(DirRotator.Yaw)
    elseif self.isJoystickThumbNoMoveShow then
      self.isJoystickThumbNoMoveShow = false
      self:SetShow(false)
    end
  end
  self:TryCallPlayerModule(PlayerModuleEvent.ON_TOUCH_MOVE_ROLEPLAY, self.ScreenPos)
end

function UMG_Control_Joystick_C:LuaOnTouchEnded(finger)
  self.TouchIndex = -1
  self.isJoystickTouch = false
  NRCModuleManager:DoCmd(MultiTouchModuleCmd.JoystickEndTouch)
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_END, true)
  self:TryCallPlayerModule(PlayerModuleEvent.ON_TOUCH_END_ROLEPLAY, self.ScreenPos)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player or player.viewObj then
  end
  if finger == self.joystickPointIdx then
    self.joystickEnabled = false
    self._skipTick = true
    self.joystickPointIdx = -1
    self.JoystickThumb.Slot:SetPosition(self.oriThumbPos)
    self.Joystick.Slot:SetPosition(self.oriJoystickPos)
    self.isJoystickThumbNoMoveShow = false
    self:SetShow(false)
  end
end

function UMG_Control_Joystick_C:OnMouseCaptureLost()
  Log.Debug("[OnMouseCaptureLost] UMG_Control_Joystick_C")
  self:LuaOnTouchEnded(self.joystickPointIdx)
end

function UMG_Control_Joystick_C:OnTick(InDeltaTime)
  if self._skipTick then
    return
  end
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if not self.navLock and self.joystickEnabled and self.isJoystickTouch and self._playerModule then
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_MOVE, self.joystickDir, self.joystickDistance / MAX_LENGTH)
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.joystickDir, self.joystickDistance / MAX_LENGTH)
  end
end

function UMG_Control_Joystick_C:TryCallPlayerModule(Event, ...)
  if self._playerModule then
    self._playerModule:DispatchEvent(Event, ...)
  end
end

function UMG_Control_Joystick_C:ToggleJoystick(visible)
  if visible then
    self.Joystick:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Joystick:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Control_Joystick_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

return UMG_Control_Joystick_C
