local Base = require("NewRoco.Modules.System.Home.IndoorSandbox.Furnitures.BehaviourTriggerFurniture")
local BP_FNO_DOL_1005021 = Base:Extend("BP_FNO_DOL_1005021")

function BP_FNO_DOL_1005021:DoStartBehaviour()
  Log.Debug("BP_FNO_DOL_1005021:DoStartBehaviour")
  self:TriggerFX()
end

function BP_FNO_DOL_1005021:DoStopBehaviour()
  Log.Debug("BP_FNO_DOL_1005021:DoStopBehaviour")
  self:CloseFX()
end

return BP_FNO_DOL_1005021
