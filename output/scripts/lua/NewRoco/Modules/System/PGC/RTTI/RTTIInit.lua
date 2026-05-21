local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")

local function ForceLoadDefine(FileName)
  local FileDefinePath = "NewRoco.Modules.System.PGC.RTTI.Defines.Generates." .. FileName
  package.loaded[FileDefinePath] = nil
  local Success, ErrorMessage = pcall(require, FileDefinePath)
  if not Success then
    error(string.format("ForceLoadDefine failed: %s (%s)", tostring(FileName), tostring(ErrorMessage)))
  end
end

local function RegisterConfig(TypeName)
  local ConfigTableId = DataConfigManager.ConfigTableId[TypeName]
  if ConfigTableId then
    local Config = DataConfigManager:GetTable(ConfigTableId)
    if Config then
      RTTIManager:RegisterConfig(TypeName, Config)
    end
  end
end

RTTIManager:Shutdown()
RTTIManager:Initialize({
  Core = {StrictMode = true},
  User = {Name = "jaunwang"},
  Ruler = {
    NPC_REFRESH_CONTENT_CONF = {new_key_padding = 5}
  },
  DataProvider = {
    MaxQueryDepth = 100,
    TimeoutMs = 100000000,
    EnableValidation = true
  }
})
ForceLoadDefine("EnumDefine")
ForceLoadDefine("TypeDefine")
local ConfigTypeNames = {
  "NPC_CONF",
  "NPC_REFRESH_CONTENT_CONF"
}
for _, TypeName in ipairs(ConfigTypeNames) do
  ForceLoadDefine(TypeName)
  RegisterConfig(TypeName)
end
