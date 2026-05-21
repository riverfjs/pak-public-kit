local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local AbstractValidator = RTTIBase.Class("AbstractValidator")

function AbstractValidator:Ctor()
  self:Reset()
end

function AbstractValidator:PushTypeError(TypeName, MessageFormat, ...)
  local Message = string.format(MessageFormat, ...)
  local Error = {TypeName = TypeName, Message = Message}
  table.insert(self.Errors, Error)
  return self.StopOnFirstError
end

function AbstractValidator:PushFieldError(FieldName, MessageFormat, ...)
  local Message = string.format(MessageFormat, ...)
  local Error = {
    TypeName = self.CurrentTypeName,
    FieldName = FieldName,
    Message = Message
  }
  table.insert(self.Errors, Error)
  return self.StopOnFirstError
end

function AbstractValidator:IsStrictMode()
  return self.StrictMode or false
end

function AbstractValidator:Reset()
  self:OnReset()
end

function AbstractValidator:Execute(TypeName, Data)
  self.Errors = {}
  self.CurrentTypeName = TypeName
  self.StrictMode = RTTISettings:Get("Core.StrictMode")
  self.StopOnFirstError = RTTISettings:Get("Validation.StopOnFirstError")
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if TypeInfo then
    self:OnExecute(TypeInfo, Data)
  else
    self:PushTypeError(TypeName, "\230\149\176\230\141\174\230\151\160\230\179\149\229\143\141\229\186\143\229\136\151\229\140\150\230\156\170\231\159\165\231\177\187\229\158\139")
  end
  return {
    Success = 0 == #self.Errors,
    Errors = self.Errors
  }
end

function AbstractValidator:OnReset()
end

function AbstractValidator:OnExecute(TypeInfo, Data)
end

return AbstractValidator
