local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputArray_C = UMG_AbstractInput:Extend("UMG_InputArray_C")

function UMG_InputArray_C:OnNormalizeData(Data)
  return true
end

function UMG_InputArray_C:OnFlushData()
end

return UMG_InputArray_C
