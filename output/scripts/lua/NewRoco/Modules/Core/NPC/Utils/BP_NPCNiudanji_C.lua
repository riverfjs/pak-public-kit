require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local BP_NPCNiudanji_C = Base:Extend("BP_NPCNiudanji_C")

function BP_NPCNiudanji_C:OnFrameLoad(distanceRatio)
  if self.HeadWidget then
    self:InitWidgetComponent(self.HeadWidget)
  end
  Base.OnFrameLoad(self, distanceRatio)
end

return BP_NPCNiudanji_C
