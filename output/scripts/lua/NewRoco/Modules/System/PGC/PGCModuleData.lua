local PGCModuleData = _G.NRCData:Extend("PGCModuleData")
local Enum = _G.Enum

function PGCModuleData:Ctor()
  NRCData.Ctor(self)
  self:InitRTTI()
end

function PGCModuleData:InitRTTI()
  local RTTIInitFilePath = "NewRoco.Modules.System.PGC.RTTI.RTTIInit"
  package.loaded[RTTIInitFilePath] = nil
  require(RTTIInitFilePath)
end

return PGCModuleData
