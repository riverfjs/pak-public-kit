local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SerializationTestCase = AbstractTestCase:Extend("SerializationTestCase")

function SerializationTestCase:Ctor()
  self.Name = "\229\186\143\229\136\151\229\140\150/\229\143\141\229\186\143\229\136\151\229\140\150\239\188\136Lua/Json\239\188\137\228\184\142\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141"
  self.Description = "\232\166\134\231\155\150 Serialize/Deserialize(lu\208\176/json) \228\184\142\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\233\148\153\232\175\175\232\174\176\229\189\149"
end

function SerializationTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Reflection = {EnableSerialization = true},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:RegisterAllTestTypes()
  local Data = RTTIManager:CreateInstance("TestDataType")
  self:AssertTrue(RTTIManager:SetProperty("TestDataType", Data, "Name", "Alpha"))
  local LuaContent = RTTIManager:Serialize("TestDataType", Data, "lua")
  self:AssertType(LuaContent, "string")
  self:AssertTrue("" ~= LuaContent, "Lua\229\186\143\229\136\151\229\140\150\231\187\147\230\158\156\228\184\141\232\131\189\228\184\186\231\169\186")
  local LuaRestored = RTTIManager:Deserialize("TestDataType", LuaContent, "lua")
  self:AssertType(LuaRestored, "table")
  self:AssertTrue(RTTIManager:DeepEquals(Data, LuaRestored), "Lua\229\143\141\229\186\143\229\136\151\229\140\150\229\175\185\232\177\161\229\186\148\228\184\142\229\142\159\229\175\185\232\177\161\231\173\137\228\187\183")
  local JsonContent = RTTIManager:Serialize("TestDataType", Data, "json")
  self:AssertType(JsonContent, "string")
  self:AssertTrue("" ~= JsonContent, "Json\229\186\143\229\136\151\229\140\150\231\187\147\230\158\156\228\184\141\232\131\189\228\184\186\231\169\186")
  local JsonRestored = RTTIManager:Deserialize("TestDataType", JsonContent, "json")
  self:AssertType(JsonRestored, "table")
  self:AssertTrue(RTTIManager:DeepEquals(Data, JsonRestored), "Json\229\143\141\229\186\143\229\136\151\229\140\150\229\175\185\232\177\161\229\186\148\228\184\142\229\142\159\229\175\185\232\177\161\231\173\137\228\187\183")
  local OtherType = self:BuildMinimalTypeDefine("OtherType")
  self:AssertTrue(RTTIManager:RegisterType("OtherType", OtherType))
  RTTIManager:ResetSystemStatus()
  local Wrong = RTTIManager:Deserialize("OtherType", LuaContent, "lua")
  self:AssertTrue(nil == Wrong, "\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\230\151\182\229\186\148\232\191\148\229\155\158nil")
  local LastError = RTTIManager:GetLastError()
  self:AssertType(LastError, "table")
  self:AssertStringContains(LastError.Message, "\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141", "\229\186\148\232\174\176\229\189\149\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\233\148\153\232\175\175")
end

return SerializationTestCase
