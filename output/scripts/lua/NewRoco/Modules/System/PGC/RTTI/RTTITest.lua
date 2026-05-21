local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TestCaseClasses = {
  require("NewRoco.Modules.System.PGC.RTTI.Tests.SystemInitTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.TypeRegistrationStrictModeTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.ReflectionPropertyCacheDataFlagTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.DirtyBucketTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.DirtyYamlStoreSaveTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.DuplicateInstanceTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.SerializationTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.ProviderDuplicateAndCacheTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.ValidationPipelineTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.TypeInferenceTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.ConfTypeCreateAndValidateTestCase"),
  require("NewRoco.Modules.System.PGC.RTTI.Tests.ValidateBatchTestCase")
}

local function RunAll()
  local Results = {
    Total = 0,
    Passed = 0,
    Failed = 0,
    Failures = {}
  }
  for _, CaseClass in ipairs(TestCaseClasses) do
    local Case = CaseClass()
    Case:Run(Results)
  end
  local Summary = string.format("RTTI DataTest Done. Total=%d Passed=%d Failed=%d", Results.Total, Results.Passed, Results.Failed)
  Log.Info(Summary)
  if Results.Failed > 0 then
    for _, Failure in ipairs(Results.Failures) do
      Log.Warning(string.format([[
[FAILED CASE] %s
  Error:%s]], Failure.Name, Failure.ErrorMessage))
    end
    Log.Error("RTTI DataTest Failed")
  end
  return true
end

local RTTITest = {}

function RTTITest.Run()
  local Success, ErrorMessage = pcall(RunAll)
  if not Success then
    local LastError = RTTIManager:GetLastError()
    if LastError then
      Log.Info("RTTI DataTest Failed. LastError:", LastError.Message)
    end
    Log.Error(ErrorMessage)
  end
  Log.Info("RTTI DataTest Passed")
  PGCModuleData:InitRTTI()
end

return RTTITest
