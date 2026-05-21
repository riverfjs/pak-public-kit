local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputStruct_C = UMG_AbstractInput:Extend("UMG_InputStruct_C")

function UMG_InputStruct_C:OnNormalizeData(Data)
  return true
end

function UMG_InputStruct_C:OnFlushData()
end

return UMG_InputStruct_C
