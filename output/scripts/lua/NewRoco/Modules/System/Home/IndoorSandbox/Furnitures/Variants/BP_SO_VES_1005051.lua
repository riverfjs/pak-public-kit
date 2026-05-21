local Base = require("NewRoco.Modules.System.Home.Res.NRCHomePlacementActor_C")
local BP_SO_VES_1005051 = Base:Extend("BP_SO_VES_1005051")

function BP_SO_VES_1005051:ReceiveBeginPlay()
  Base.ReceiveBeginPlay(self)
end

function BP_SO_VES_1005051:OnMeshLoaded()
  Base.OnMeshLoaded(self)
  Log.Debug("BP_SO_VES_1005051:PlayFX")
  self:PlayFX()
end

return BP_SO_VES_1005051
