require("UnLua")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BP_ElementInteract_General_C = Base:Extend("BP_ElementInteract_General_C")

function BP_ElementInteract_General_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.Interacting = false
  self.IsBurning = false
end

function BP_ElementInteract_General_C:UpdateBurningState(ForceUpdate)
  if self.Interacting then
    Log.Debug("Interacting... Skill update burning state", self.IsBurning)
    return
  end
  local ShouldBurn = SceneUtils.IsLogicStatusTriggerOn(self.sceneCharacter)
  if not ForceUpdate and ShouldBurn == self.IsBurning then
    return
  end
  if ShouldBurn then
    self:LightUp()
  else
    self:PutDown(ForceUpdate)
  end
end

function BP_ElementInteract_General_C:OnVisible()
  Base.OnVisible(self)
  self:UpdateBurningState(true)
end

function BP_ElementInteract_General_C:LightUp()
  self.IsBurning = true
  if self.Scene_fire_Loop then
    self.Scene_fire_Loop:SetActive(true)
  end
  if self.PointLight then
    self.PointLight:SetVisibility(true)
  end
  if self.OnLightUp then
    self:OnLightUp()
  end
  _G.DelayManager:DelaySeconds(0.5, function()
    if self.AudioID then
      self.AudioSession = _G.NRCAudioManager:PlaySound3DWithActorAuto(self.AudioID, self, "BP_NPCTorchBase_C:LightUp")
    end
  end)
end

function BP_ElementInteract_General_C:PutDown(ForceUpdate)
  self.IsBurning = false
  if self.Scene_fire_Loop then
    self.Scene_fire_Loop:SetActive(false)
  end
  if self.OnFirePutDown then
    self:OnFirePutDown()
  end
  if self.PointLight then
    if ForceUpdate then
      self.PointLight:SetVisibility(false)
    else
      if self.DelayHandler then
        _G.DelayManager:CancelDelayById(self.DelayHandler)
        self.DelayHandler = nil
      end
      self.DelayHandler = _G.DelayManager:DelaySeconds(0.3, function(PointLight)
        self.DelayHandler = nil
        if UE.UObject.IsValid(PointLight) then
          PointLight:SetVisibility(false)
        end
      end, self.PointLight)
    end
  end
  if 0 ~= self.AudioID and self.AudioSessionID then
    _G.NRCAudioManager:ReleaseSession(self.AudioSessionID, true, "BP_ElementInteract_General_C" .. self.AudioID, false)
    self.AudioSessionID = nil
  end
end

function BP_ElementInteract_General_C:CanEnterThrowInter(Comp)
  return Comp and (Comp == self.ActionArea or Comp == self.StaticMesh)
end

function BP_ElementInteract_General_C:Recycle()
  self:PutDown()
  Base.Recycle(self)
end

function BP_ElementInteract_General_C:SetInteracting(Interacting)
  self.Interacting = Interacting
  self:UpdateBurningState()
end

return BP_ElementInteract_General_C
