local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusBase")
local AbnormalStatus_Hot = Base:Extend("AbnormalStatus_Hot")

function AbnormalStatus_Hot:Ctor(owner)
  Base.Ctor(self, owner)
end

function AbnormalStatus_Hot:OnExecute()
  Base.OnExecute(self)
  if self:IsLocalPlayer() then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowTemperatureHot, true)
  end
end

function AbnormalStatus_Hot:OnRemove(bForce)
  if self:IsLocalPlayer() then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowTemperatureHot, false, bForce)
  end
  Base.OnRemove(self, bForce)
end

return AbnormalStatus_Hot
