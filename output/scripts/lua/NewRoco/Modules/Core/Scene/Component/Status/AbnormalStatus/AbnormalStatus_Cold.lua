local Base = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusBase")
local AbnormalStatus_Cold = Base:Extend("AbnormalStatus_Cold")

function AbnormalStatus_Cold:Ctor(owner)
  Base.Ctor(self, owner)
end

function AbnormalStatus_Cold:OnExecute()
  Base.OnExecute(self)
  if self:IsLocalPlayer() then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowTemperatureCold, true)
  end
end

function AbnormalStatus_Cold:OnRemove(bForce)
  if self:IsLocalPlayer() then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowTemperatureCold, false, bForce)
  end
  Base.OnRemove(self, bForce)
end

return AbnormalStatus_Cold
