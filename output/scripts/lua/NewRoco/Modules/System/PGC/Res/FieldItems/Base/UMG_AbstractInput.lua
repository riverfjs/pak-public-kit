local UMG_AbstractView = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractView")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local UMG_AbstractInput = UMG_AbstractView:Extend("UMG_AbstractInput")

function UMG_AbstractInput:GetProperty()
  if self.Data then
    local TypeName = self.Data.RTTI.TypeInfo.Name
    local FieldName = self.Data.RTTI.FieldInfo.Name
    local Record = self.Data.Record
    return RTTIManager:GetProperty(TypeName, Record, FieldName)
  end
end

function UMG_AbstractInput:SetProperty(Value)
  if self.Data then
    local TypeName = self.Data.RTTI.TypeInfo.Name
    local FieldName = self.Data.RTTI.FieldInfo.Name
    local Record = self.Data.Record
    local Success = RTTIManager:SetProperty(TypeName, Record, FieldName, Value)
    if Success then
      local PrimaryKeyValue = RTTIManager:GetPrimaryKeyValue(TypeName, Record)
      if PrimaryKeyValue then
        NRCModuleManager:DoCmd(PGCModuleCmd.RefreshDataState, TypeName, PrimaryKeyValue)
      end
    end
    return Success
  end
end

return UMG_AbstractInput
