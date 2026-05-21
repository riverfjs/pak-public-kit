local UMG_Tempreture_Hot_C = _G.NRCPanelBase:Extend("UMG_Tempreture_Hot_C")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TemperatureEnum = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureEnum")

function UMG_Tempreture_Hot_C:OnConstruct()
end

function UMG_Tempreture_Hot_C:OnDestruct()
end

function UMG_Tempreture_Hot_C:OnActive()
  self:DoCustomOpen()
end

function UMG_Tempreture_Hot_C:OnDeactive()
end

function UMG_Tempreture_Hot_C:OnEnable()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_Tempreture_Hot_C:OnDisable()
end

function UMG_Tempreture_Hot_C:DoCustomOpen()
  Log.Debug("UMG_Tempreture_Hot_C:DoCustomOpen", self.bDoingClose)
  _G.NRCAudioManager:PlaySound2DAuto(40008012, "UMG_Tempreture_Hot_C:DoCustomOpen")
  self.bDoingClose = false
  self:StopAllAnimations()
  self:PlayAnimation(self.HotOpen)
  self:PlayAnimation(self.HotLoop, 0, 0)
  self:OnEnable()
end

function UMG_Tempreture_Hot_C:DoCustomClose(bForce)
  Log.Debug("UMG_Tempreture_Hot_C:DoCustomClose", self.bDoingClose, bForce)
  self.bDoingClose = true
  if bForce then
    self:StopAllAnimations()
    self:DoClose()
    return
  end
  self:StopAllAnimations()
  self:PlayAnimation(self.HotClose)
end

function UMG_Tempreture_Hot_C:OnAnimationFinished(Animation)
  if Animation == self.HotClose and self.bDoingClose then
    self.bDoingClose = false
    self:DoClose()
  end
end

return UMG_Tempreture_Hot_C
