local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local SyntaxValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.SyntaxValidator")
local SemanticValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.SemanticValidator")
local ReferenceValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.ReferenceValidator")
local SecurityValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.SecurityValidator")
local RTTIValidator = {
  Validators = {
    Syntax = SyntaxValidator(),
    Semantic = SemanticValidator(),
    Reference = ReferenceValidator(),
    Security = SecurityValidator()
  }
}

local function AddValidatorErrors(Errors, ValidatorResult)
  if not ValidatorResult.Success then
    for _, Error in ipairs(ValidatorResult.Errors) do
      table.insert(Errors, Error)
      if RTTISettings:Get("Validation.StopOnFirstError") then
        return true
      end
    end
  end
  return false
end

function RTTIValidator:Initialize()
  for _, Validator in pairs(self.Validators) do
    Validator:Reset()
  end
end

function RTTIValidator:RegisterCustomRule(RuleName, Callback)
  if self.Validators.Semantic then
    return self.Validators.Semantic:RegisterCustomRule(RuleName, Callback)
  end
  return false
end

function RTTIValidator:RegisterBusinessRule(RuleName, Callback, ApplicableTypeNames)
  if self.Validators.Semantic then
    return self.Validators.Semantic:RegisterBusinessRule(RuleName, Callback, ApplicableTypeNames)
  end
  return false
end

function RTTIValidator:RegisterSecurityRule(RuleName, Callback)
  if self.Validators.Security then
    return self.Validators.Security:RegisterSecurityRule(RuleName, Callback)
  end
  return false
end

function RTTIValidator:RegisterBlacklistRegexp(RuleName, Regexp)
  if self.Validators.Security then
    return self.Validators.Security:RegisterBlacklistRegexp(RuleName, Regexp)
  end
  return false
end

function RTTIValidator:RegisterWhitelistRegexp(RuleName, Regexp)
  if self.Validators.Security then
    return self.Validators.Security:RegisterWhitelistRegexp(RuleName, Regexp)
  end
  return false
end

function RTTIValidator:ValidateRecord(TypeName, Data)
  local StartTime = os.clock()
  local Errors = {}
  for _, Validator in pairs(self.Validators) do
    local Result = Validator:Execute(TypeName, Data)
    if AddValidatorErrors(Errors, Result) then
      break
    end
  end
  local Success = 0 == #Errors
  local Duration = os.clock() - StartTime
  RTTIStatistics:RecordValidation(Success, Duration)
  RTTIStatistics:SetLastValidationResult({
    TypeName = TypeName,
    Success = Success,
    Errors = Errors
  })
  return {Success = Success, Errors = Errors}
end

function RTTIValidator:ValidateBatch(TypeName, DataList)
  local DataCount = #DataList
  local Batch = {
    Success = true,
    SuccessCount = 0,
    FailCount = 0,
    TotalCount = 0,
    Results = {}
  }
  for Index, Data in ipairs(DataList) do
    local Result = self:ValidateRecord(TypeName, Data)
    if Result.Success then
      Batch.SuccessCount = Batch.SuccessCount + 1
    else
      Batch.FailCount = Batch.FailCount + 1
    end
    Batch.TotalCount = Batch.TotalCount + 1
    Batch.Success = Batch.Success and Result.Success
    table.insert(Batch.Results, Result)
    if RTTISettings:Get("Validation.StopOnFirstError") and not Result.Success then
      RTTIStatistics:RecordError(false, "\230\137\185\233\135\143\233\170\140\232\175\129\231\177\187\229\158\139\227\128\144%s\227\128\145\233\129\135\229\136\176\233\148\153\232\175\175\229\129\156\230\173\162:%d, %d", TypeName, Index, DataCount)
      break
    end
  end
  return Batch
end

return RTTIValidator
