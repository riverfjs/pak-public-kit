local UMG_Compass_C = require("NewRoco.Modules.System.MainUI.Res.compass.UMG_Compass_C")
local UMG_Compass_Sneak_C = _G.NRCPanelBase:Extend("UMG_Compass_Sneak_C")
local SneakState = {
  Normal = 0,
  Hidden = 1,
  Hidden_Exposed = 2,
  Hidden_Attacked = 3
}

local function ConvertToSneakState(state, childState)
  if state == UMG_Compass_C.State.NORMAL then
    return SneakState.Normal
  elseif state == UMG_Compass_C.State.HIDE then
    if childState == UMG_Compass_C.HideState.Hidden_Exposed then
      return SneakState.Hidden_Exposed
    elseif childState == UMG_Compass_C.HideState.Hidden_Attacked then
      return SneakState.Hidden_Attacked
    else
      return SneakState.Hidden
    end
  end
  return SneakState.Normal
end

function UMG_Compass_Sneak_C:StopAllAnimationsHelper()
  self.PendingLoopAnim = nil
  self:StopAllAnimations()
end

function UMG_Compass_Sneak_C:OnAnimationFinished(anim)
  if anim == self.In and self.PendingLoopAnim == self.Loop then
    self:PlayAnimation(self.Loop, 0.0, 0)
  elseif anim == self.In_Yellow and self.PendingLoopAnim == self.Loop_Yellow then
    self:PlayAnimation(self.Loop_Yellow, 0.0, 0)
  elseif anim == self.In_Red and self.PendingLoopAnim == self.Loop_Red then
    self:PlayAnimation(self.Loop_Red, 0.0, 0)
  elseif anim == self.Out_Yellow and self.PendingLoopAnim == self.Loop then
    self:PlayAnimation(self.Loop, 0.0, 0)
  elseif anim == self.Out_Red and self.PendingLoopAnim == self.Loop then
    self:PlayAnimation(self.Loop, 0.0, 0)
  elseif anim == self.Yellow_to_Red and self.PendingLoopAnim == self.Loop_Red then
    self:PlayAnimation(self.Loop_Red, 0.0, 0)
  elseif anim == self.Red_to_Yellow and self.PendingLoopAnim == self.Loop_Yellow then
    self:PlayAnimation(self.Loop_Yellow, 0.0, 0)
  end
end

function UMG_Compass_Sneak_C:ChangeTo(state, childState)
  local newState = ConvertToSneakState(state, childState)
  local oldState = self.CurSneakState or SneakState.Normal
  if oldState == newState then
    return
  end
  self:StopAllAnimationsHelper()
  if oldState == SneakState.Normal and newState == SneakState.Hidden then
    self.PendingLoopAnim = self.Loop
    self:PlayAnimation(self.In)
  elseif oldState == SneakState.Hidden and newState == SneakState.Normal then
    self:PlayAnimation(self.Out)
  elseif oldState == SneakState.Hidden and newState == SneakState.Hidden_Exposed then
    self.PendingLoopAnim = self.Loop_Yellow
    self:PlayAnimation(self.In_Yellow)
  elseif oldState == SneakState.Hidden_Exposed and newState == SneakState.Hidden then
    self.PendingLoopAnim = self.Loop
    self:PlayAnimation(self.Out_Yellow)
  elseif oldState == SneakState.Hidden and newState == SneakState.Hidden_Attacked then
    self.PendingLoopAnim = self.Loop_Red
    self:PlayAnimation(self.In_Red)
  elseif oldState == SneakState.Hidden_Attacked and newState == SneakState.Hidden then
    self.PendingLoopAnim = self.Loop
    self:PlayAnimation(self.Out_Red)
  elseif oldState == SneakState.Hidden_Exposed and newState == SneakState.Hidden_Attacked then
    self.PendingLoopAnim = self.Loop_Red
    self:PlayAnimation(self.Yellow_to_Red)
  elseif oldState == SneakState.Hidden_Attacked and newState == SneakState.Hidden_Exposed then
    self.PendingLoopAnim = self.Loop_Yellow
    self:PlayAnimation(self.Red_to_Yellow)
  elseif oldState == SneakState.Normal and newState == SneakState.Hidden_Exposed then
    self.PendingLoopAnim = self.Loop_Yellow
    self:PlayAnimation(self.In_Yellow)
  elseif oldState == SneakState.Normal and newState == SneakState.Hidden_Attacked then
    self.PendingLoopAnim = self.Loop_Red
    self:PlayAnimation(self.In_Red)
  elseif oldState == SneakState.Hidden_Exposed and newState == SneakState.Normal then
    self:PlayAnimation(self.Out_Yellow)
  elseif oldState == SneakState.Hidden_Attacked and newState == SneakState.Normal then
    self:PlayAnimation(self.Out_Red)
  end
  self.CurSneakState = newState
end

return UMG_Compass_Sneak_C
