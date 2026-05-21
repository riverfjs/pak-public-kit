local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local DialogueConst = require("NewRoco.Modules.System.Dialogue.DialogueConst")
local UMG_Control_Camera_Dialog_C = NRCUmgClass:Extend("UMG_Control_Camera_Dialog_C")
local LocalUE4 = UE4

function UMG_Control_Camera_Dialog_C:Construct()
  self.Overridden.Construct(self)
  self:OnInit()
  self:OnBeforeOpen()
end

function UMG_Control_Camera_Dialog_C:OnInit()
  self.joystickPointIdx = -1
  self.startPos = LocalUE4.FVector2D()
  self.player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self._playerModule = NRCModuleManager:GetModule("PlayerModule")
end

function UMG_Control_Camera_Dialog_C:OnBeforeOpen()
end

function UMG_Control_Camera_Dialog_C:GetInputModuleData()
  if self._playerModule then
    return self._playerModule.playerModuleData
  end
end

function UMG_Control_Camera_Dialog_C:LuaOnTouchStarted(finger, pos)
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if finger == self.TouchIndex then
    self.joystickPointIdx = finger
    self.startPos:Set(pos.X, pos.Y)
  end
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_START, false)
end

function UMG_Control_Camera_Dialog_C:LuaOnTouchMoved(finger, dir)
  local inputModuleData = self:GetInputModuleData()
  if inputModuleData and not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if finger == self.joystickPointIdx and self._playerModule then
    local player = PlayerModuleCmd
    local deltaTime = UE4.UGameplayStatics.GetWorldDeltaSeconds(self.player.viewObj)
    dir.X = dir.X * deltaTime * DialogueConst.InputHandleParam.BaseTurnRate
    dir.Y = dir.Y * deltaTime * DialogueConst.InputHandleParam.BaseLookUpRate
    if dir.X > DialogueConst.InputHandleParam.MaxSingleStepYaw then
      dir.X = DialogueConst.InputHandleParam.MaxSingleStepYaw
    elseif dir.X < -DialogueConst.InputHandleParam.MaxSingleStepYaw then
      dir.X = -DialogueConst.InputHandleParam.MaxSingleStepYaw
    end
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TURN, dir, false)
  end
end

function UMG_Control_Camera_Dialog_C:LuaOnTouchEnded(finger)
  self.TouchIndex = -1
  self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_TOUCH_END, false)
end

function UMG_Control_Camera_Dialog_C:OnMouseCaptureLost()
  Log.Debug("[OnMouseCaptureLost] UMG_Control_Camera_Dialog_C")
  self:LuaOnTouchEnded(0)
end

function UMG_Control_Camera_Dialog_C:Tick(MyGeometry, InDeltaTime)
  local inputModuleData = self:GetInputModuleData()
  if not inputModuleData.playerCtrlEnable then
    self:LuaOnTouchEnded(self.joystickPointIdx)
    return
  end
  if not self.navLock and self.joystickEnabled and self._playerModule then
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_MOVE, self.joystickDir, self.joystickDistance / MAX_LENGTH)
    self:TryCallPlayerModule(PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.joystickDir, self.joystickDistance / MAX_LENGTH)
  end
end

function UMG_Control_Camera_Dialog_C:TryCallPlayerModule(Event, ...)
  if self._playerModule then
    self._playerModule:DispatchEvent(Event, ...)
  end
end

return UMG_Control_Camera_Dialog_C
