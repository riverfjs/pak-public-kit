local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
local UMG_Control_Camera_Home_C = NRCUmgClass:Extend("UMG_Control_Camera_Home_C")

function UMG_Control_Camera_Home_C:Construct()
  self.Overridden.Construct(self)
  self:OnInit()
  self:OnBeforeOpen()
end

function UMG_Control_Camera_Home_C:OnInit()
  self.Module = NRCModuleManager:GetModule("HomeModule")
  self._camera_yaw_speed_multiplier_yaw = _G.DataConfigManager:GetGlobalConfigNumByKeyType("camera_rotate_speed_yaw", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 3000) / 1000.0
  self._camera_yaw_speed_multiplier_pitch = _G.DataConfigManager:GetGlobalConfigNumByKeyType("camera_rotate_speed_pitch", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000) / 1000.0
end

function UMG_Control_Camera_Home_C:OnBeforeOpen()
end

function UMG_Control_Camera_Home_C:LuaOnTouchStarted(finger, pos)
  Log.Debug("[Home] LuaOnTouchStarted==", finger, pos)
  self.Module:DispatchEvent(HomeModuleEvent.OnTouchCameraStart, pos)
end

function UMG_Control_Camera_Home_C:LuaOnTouchMoved(finger, DeltaPos)
  local isTwoTouch, touchDistance = self:GetTouchScaleInfo()
  if isTwoTouch then
    if self.bTwoTouching then
      local DiffDistance = touchDistance - self.touchDistance
      self.Module:DispatchEvent(HomeModuleEvent.OnZoomCamera, DiffDistance)
    end
    self.touchDistance = touchDistance
    return
  end
  DeltaPos.X = DeltaPos.X * self._camera_yaw_speed_multiplier_yaw
  DeltaPos.Y = DeltaPos.Y * self._camera_yaw_speed_multiplier_pitch
  self.Module:DispatchEvent(HomeModuleEvent.OnTurnCamera, DeltaPos, self.ScreenPos)
end

function UMG_Control_Camera_Home_C:LuaOnTouchEnded(finger)
  Log.Debug("[Home] LuaOnTouchEnded==", finger)
  self.TouchIndex = -1
  self.Module:DispatchEvent(HomeModuleEvent.OnTouchCameraEnd, self.ScreenPos)
end

function UMG_Control_Camera_Home_C:OnMouseCaptureLost()
  Log.Debug("[OnMouseCaptureLost] UMG_Control_Camera_Home_C")
  self:LuaOnTouchEnded(0)
end

return UMG_Control_Camera_Home_C
