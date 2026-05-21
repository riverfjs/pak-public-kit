local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local BitSwitch = require("Utils.BitSwitch")
local StringCache = require("Utils.StringCache")
local InputComponent = Base:Extend("InputComponent")

function InputComponent:Ctor()
  self.BaseTurnRate = 45.0
  self.BaseLookUpRate = 45.0
  self.ZoomRate = 500.0
  self._inputSwitch = BitSwitch.new("InputDisable")
  self._hasAddListener = false
  self._cameraControlSwitch = BitSwitch.new("CameraDisable")
  self._moveSwitch = BitSwitch.new("MoveDisable")
  self._ignoreMoveInputSwitch = BitSwitch.new("IgnoreMoveInput")
  self._startTurnDir = UE.FVector2D(0, 0)
  self._totalTurnDis = 0
  self._turnAccDistAngle = _G.DataConfigManager:GetGlobalConfigNumByKeyType("camera_turn_acc_distance_angle", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1)
  self._turnAccDistAngle = math.cos(math.rad(self._turnAccDistAngle))
  self._turnAccDistCurve = _G.DataConfigManager:GetGlobalConfigStrByKeyType("camera_turn_acc_distance_curve", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  self._turnAccDistCurve = LoadObject(self._turnAccDistCurve)
  if self._turnAccDistCurve then
    self._turnAccDistCurveRef = UnLua.Ref(self._turnAccDistCurve)
  end
  self._turnAccSpeedCurve = _G.DataConfigManager:GetGlobalConfigStrByKeyType("camera_turn_acc_speed_angle", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  self._turnAccSpeedCurve = LoadObject(self._turnAccSpeedCurve)
  if self._turnAccSpeedCurve then
    self._turnAccSpeedCurveRef = UnLua.Ref(self._turnAccSpeedCurve)
  end
end

function InputComponent:Attach(Owner)
  Log.Trace("InputComponent attach")
  Base.Attach(self, Owner)
  self:ResetInputSwitch()
  if self.owner then
    self.playerController = self.owner:GetUEController()
  end
  self:AddEventListener()
  if ScenePlayerInputManager.IsPause() then
    local controller = self.owner:GetUEController()
    controller:DisableInput(controller)
  end
end

function InputComponent:DeAttach()
  Log.Trace("InputComponent DeAttach")
  self.owner = nil
  self:RemoveEventListener()
end

function InputComponent:OnVisible()
  if self.owner then
    self.playerController = self.owner:GetUEController()
  end
end

function InputComponent:OnInvisible()
  self.playerController = nil
end

function InputComponent:AddEventListener()
  if not self._hasAddListener then
    self._hasAddListener = true
    local playerModule = NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE, self.OnInputMove)
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END, self.OnInputTurnEnd)
    end
  end
end

function InputComponent:RemoveEventListener()
  if self._hasAddListener then
    self._hasAddListener = false
    local playerModule = NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE, self.OnInputMove)
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END, self.OnInputTurnEnd)
    end
  end
end

function InputComponent:PlayDialogueVideo(isPlay)
  self.isPlayDialogueVideo = isPlay
end

function InputComponent:GetPlayDialogueVideo()
  return self.isPlayDialogueVideo
end

function InputComponent:SetInputEnable(caller, enable, flag)
  if not caller and not flag then
    Log.ErrorFormat("Unable to call SetInputEnable without caller and flag")
    return
  end
  local label = flag or caller.name or StringCache.intern("default")
  if not enable then
    self._inputSwitch:open(label)
  else
    self._inputSwitch:close(label)
  end
  if not self.owner then
    return
  end
  local inputEnable = not self._inputSwitch:is_open()
  local controller = self.owner:GetUEController()
  if controller and UE.UObject.IsValid(controller) then
    if inputEnable then
      controller:EnableInput(controller)
    else
      controller:DisableInput(controller)
    end
  end
  if self.owner.viewObj and UE.UObject.IsValid(self.owner.viewObj) then
    self.owner.viewObj.bActiveIdle = not inputEnable
  end
  if not inputEnable and self.owner.abilityComponent and self.owner.abilityComponent.CurrentAbility then
    local ability = self.owner.abilityComponent.CurrentAbility
    if ability:IsCasting() then
      ability:Finish(true)
    end
  end
  self:SetMoveEnable(self, inputEnable, "InputEnable")
end

function InputComponent:GetInputEnable()
  return not self._inputSwitch:is_open()
end

function InputComponent:SetCameraControlEnable(caller, enable, flag)
  if not caller then
    Log.ErrorFormat("Unable to call SetCameraControlEnable without caller")
    return
  end
  local label = flag or caller.name or StringCache.intern("default")
  if not enable then
    self._cameraControlSwitch:open(label)
  else
    self._cameraControlSwitch:close(label)
  end
end

function InputComponent:GetCameraControlEnable()
  return not self._cameraControlSwitch:is_open()
end

function InputComponent:SetMoveEnable(caller, enable, flag)
  if not caller then
    Log.ErrorFormat("Unable to call SetMoveEnable without caller")
    return
  end
  local label = flag or caller.name or StringCache.intern("default")
  if not enable then
    self._moveSwitch:open(label)
  else
    self._moveSwitch:close(label)
  end
  local moveEnable = not self._moveSwitch:is_open()
  if UE.UObject.IsValid(self.playerController) then
    self.playerController:SetMoveEnable(moveEnable)
  end
end

function InputComponent:SetIgnoreMoveInput(caller, ignore, flag)
  if not caller then
    Log.ErrorFormat("Unable to call SetIgnoreMoveInput without caller")
    return
  end
  local label = flag or caller.name or StringCache.intern("default")
  local res = false
  if ignore then
    res = self._ignoreMoveInputSwitch:open(label)
  else
    res = self._ignoreMoveInputSwitch:close(label)
  end
  local isIgnore = self._ignoreMoveInputSwitch:is_open()
  if UE.UObject.IsValid(self.playerController) then
    self.playerController:ResetIgnoreMoveInput()
    if isIgnore then
      self.playerController:SetIgnoreMoveInput(isIgnore)
    end
  end
end

function InputComponent:OnZoomIn()
  if self._cameraControlSwitch:is_open() then
    return
  end
  local pawn = self.owner.viewObj
  if pawn then
    local DeltaSeconds = UE4.UGameplayStatics.GetWorldDeltaSeconds(self.playerController)
    local Value = DeltaSeconds * self.ZoomRate
    local BP_RocoSpringArmComponent = pawn.BP_RocoSpringArmComponent
    if BP_RocoSpringArmComponent then
      BP_RocoSpringArmComponent.TargetArmLength = BP_RocoSpringArmComponent.TargetArmLength + Value
    end
  end
end

function InputComponent:OnZoomOut()
  if self._cameraControlSwitch:is_open() then
    return
  end
  local pawn = self.owner.viewObj
  if pawn then
    local DeltaSeconds = UE4.UGameplayStatics.GetWorldDeltaSeconds(self.playerController)
    local Value = DeltaSeconds * self.ZoomRate
    local BP_RocoSpringArmComponent = pawn.BP_RocoSpringArmComponent
    if BP_RocoSpringArmComponent then
      BP_RocoSpringArmComponent.TargetArmLength = BP_RocoSpringArmComponent.TargetArmLength - Value
    end
  end
end

function InputComponent:OnPlayerAccelerate()
  if self._inputSwitch:is_open() then
    return
  end
  self.playerController:OnPlayerAccelerate()
end

function InputComponent:OnInputTouch(screenPos)
  if self._inputSwitch:is_open() then
    return
  end
  self.autoInteractNpc = nil
  local ueCtrl = self.playerController
  if ueCtrl then
    local WorldLocation, CamDir = ueCtrl:Abs_DeprojectScreenPositionToWorld(screenPos.X, screenPos.Y)
    UE4.UGameplayStatics.GetPlayerCameraManager(ueCtrl, 0):K2_GetRootComponent():Abs_K2_GetComponentLocation()
    local End = CamDir * 10000 + CamLoc
    local OutHit, Res = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(ueCtrl, CamLoc, End, 3, false, nil, 0)
    if Res then
      local target = OutHit.Location
      local sceneCharacter = OutHit.Actor.sceneCharacter
      if sceneCharacter then
        Log.Debug("OnTouch Character")
        sceneCharacter:OnTouch()
      end
    end
  end
end

function InputComponent:OnEnable()
  Base.OnEnable(self)
  self:AddEventListener()
end

function InputComponent:OnDisable()
  Base.OnDisable(self)
  self:RemoveEventListener()
end

function InputComponent:Move2Npc(npc)
  if npc then
    self.autoInteractNpc = npc
    local pos = npc:GetInteractionPos()
    self:MoveTo(pos)
  end
end

function InputComponent:CastAbility(ability, ...)
  if self._inputSwitch:is_open() then
    return AbilityErrorCode.INPUT_DISABLED
  end
  local abilityComponent = self.owner.abilityComponent
  return abilityComponent:CastAbility(ability, ...)
end

function InputComponent:StopAbility(abilityId)
  if self._inputSwitch:is_open() then
    return AbilityErrorCode.INPUT_DISABLED
  end
  local abilityComponent = self.owner.abilityComponent
  abilityComponent:StopAbility(false)
  return AbilityErrorCode.NO_ERROR
end

function InputComponent:UpdateDirection()
  if self._inputSwitch:is_open() then
    return
  end
  local ueCtrl = self.playerController
  local Rotation = ueCtrl:GetControlRotation()
  Rotation:Set(0, Rotation.Yaw, 0)
  self.forward = Rotation:ToVector()
  self.right = Rotation:GetRightVector()
end

local dir3D = UE.FVector2D(0, 0)

function InputComponent:OnInputMove(dir, axis)
  if self._inputSwitch:is_open() or 0 == axis or self._moveSwitch:is_open() then
    return
  end
  dir3D:Set(dir.X, dir.Y)
  self.playerController:OnTouchMove(dir3D, axis)
end

local dir2D = UE4.FVector2D(0, 0)

function InputComponent:OnInputTurn(dir, isRate)
  if self._cameraControlSwitch:is_open() then
    return
  end
  if not UE4.UObject.IsValid(self.playerController) or self.playerController.IsCameraControlDisabled and self.playerController:IsCameraControlDisabled() then
    return
  end
  local TurnAccRate = 1
  local UMath = UE.UKismetMathLibrary
  if GlobalConfig.TurnAccMode > 0 and self._turnAccDistCurve and self._turnAccSpeedCurve then
    if UMath.IsZero2D(self._startTurnDir) and not UMath.IsZero2D(dir) then
      self._startTurnDir = UMath.Normal2D(dir)
      self._totalTurnDis = 0
    end
    if not UMath.IsZero2D(self._startTurnDir) and UMath.IsZero2D(dir) then
      self._startTurnDir:Set(0, 0)
      self._totalTurnDis = 0
    end
    if not UMath.IsZero2D(self._startTurnDir) and 1 == GlobalConfig.TurnAccMode then
      local dirNormal = UMath.Normal2D(dir)
      local angle = UMath.DotProduct2D(self._startTurnDir, dirNormal)
      if angle > self._turnAccDistAngle then
        self._totalTurnDis = self._totalTurnDis + UMath.DotProduct2D(self._startTurnDir, dir)
      else
        self._startTurnDir = UMath.Normal2D(dir)
        self._totalTurnDis = 0
      end
      TurnAccRate = self._turnAccDistCurve:GetFloatValue(self._totalTurnDis)
      if GlobalConfig.DebugTurnAccMode then
        UE4.UKismetSystemLibrary:PrintString("\232\183\157\231\166\187\229\138\160\233\128\159\239\188\140\231\180\175\231\167\175\232\183\157\231\166\187\239\188\154" .. self._totalTurnDis .. "  \229\138\160\233\128\159\229\128\141\231\142\135\239\188\154" .. TurnAccRate, true, false, UE4.FLinearColor(1, 0, 0, 1), 1)
      end
    end
    if not UMath.IsZero2D(self._startTurnDir) and 2 == GlobalConfig.TurnAccMode then
      local speed = UMath.VSize2D(dir) / UE.UGameplayStatics.GetWorldDeltaSeconds(self.playerController)
      TurnAccRate = self._turnAccSpeedCurve:GetFloatValue(speed)
      if GlobalConfig.DebugTurnAccMode then
        UE4.UKismetSystemLibrary:PrintString("\233\128\159\229\186\166\229\138\160\233\128\159\239\188\140\231\167\187\229\138\168\233\128\159\229\186\166\239\188\154" .. speed .. "    \229\138\160\233\128\159\229\128\141\231\142\135\239\188\154" .. TurnAccRate, true, false, UE4.FLinearColor(1, 0, 0, 1), 1)
      end
    end
  end
  dir:Mul(TurnAccRate)
  dir2D:Set(dir.X, dir.Y)
  if UE4.UObject.IsValid(self.playerController) then
    self.playerController:OnTouchTurn(dir2D, isRate)
  end
end

function InputComponent:OnInputTurnEnd()
  self._startTurnDir:Set(0, 0)
  self._totalTurnDis = 0
end

function InputComponent:Move(dir, axis)
  if self._inputSwitch:is_open() then
    return
  end
  if self.owner.viewObj.IsFlailLanding then
    return
  end
  if self.owner.movementComponent and self.owner.movementComponent:IsMoving() == false then
    self:UpdateDirection()
  end
  self.owner.movementComponent:ApplyMoveInput(dir, axis)
end

function InputComponent:OnPause(pause)
  self:SetInputEnable(self, not pause, "OnPause")
end

function InputComponent:OnDisConnect()
  self:ResetInputSwitch()
end

function InputComponent:ResetInputSwitch()
  self._inputSwitch:reset()
  self._moveSwitch:reset()
  self._cameraControlSwitch:reset()
  self:SetInputEnable(self, true)
end

function InputComponent:GetDisableFlags()
  local outFlags = {}
  table.insert(outFlags, string.format("InputFlags:%s", table.concat(self._inputSwitch:get_open_label_names(), ",")))
  table.insert(outFlags, string.format("CameraControlFlags:%s", table.concat(self._moveSwitch:get_open_label_names(), ",")))
  table.insert(outFlags, string.format("MoveFlags:%s", table.concat(self._cameraControlSwitch:get_open_label_names(), ",")))
  return table.concat(outFlags, ";")
end

function InputComponent:DumpState()
  Log.Warning(self._inputSwitch)
  Log.Warning(self._cameraControlSwitch)
  Log.Warning(self._moveSwitch)
end

return InputComponent
