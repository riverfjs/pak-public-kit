local AbstractSerializer = require("NewRoco.Modules.System.PGC.RTTI.Serializers.AbstractSerializer")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local LuaSerializer = AbstractSerializer:Extend("LuaSerializer")

local function EscapeString(Text)
  Text = tostring(Text)
  Text = Text:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return Text
end

local EncodeLiteral = function(Value, Depth, Seen)
  Depth = Depth or 1
  Seen = Seen or {}
  local MaxNestingLevel = RTTISettings:Get("Core.MaxNestingLevel", 20)
  if Depth > MaxNestingLevel then
    return "\"<depth_limit>\""
  end
  local ValueType = type(Value)
  if "string" == ValueType then
    return string.format("\"%s\"", EscapeString(Value))
  elseif "number" == ValueType or "boolean" == ValueType then
    return tostring(Value)
  elseif "nil" == ValueType then
    return "nil"
  elseif "table" ~= ValueType then
    return string.format("\"<unsupported:%s>\"", ValueType)
  end
  if Seen[Value] then
    return "\"<cycle>\""
  end
  Seen[Value] = true
  local IsArray = true
  local Count = 0
  for Key in pairs(Value) do
    Count = Count + 1
    if type(Key) ~= "number" or Key < 1 or math.floor(Key) ~= Key then
      IsArray = false
      break
    end
  end
  local Parts = {}
  if IsArray then
    for Index = 1, Count do
      table.insert(Parts, EncodeLiteral(Value[Index], Depth + 1, Seen))
    end
    Seen[Value] = nil
    return "{" .. table.concat(Parts, ",") .. "}"
  end
  local Keys = {}
  for Key in pairs(Value) do
    table.insert(Keys, tostring(Key))
  end
  table.sort(Keys)
  for _, KeyStr in ipairs(Keys) do
    local RawKey
    local NumericKey = tonumber(KeyStr)
    if NumericKey then
      RawKey = string.format("[%s]", NumericKey)
    elseif KeyStr:match("^[A-Za-z_][A-Za-z0-9_]*$") then
      RawKey = KeyStr
    else
      RawKey = string.format("[\"%s\"]", EscapeString(KeyStr))
    end
    table.insert(Parts, string.format("%s=%s", RawKey, EncodeLiteral(Value[KeyStr] or Value[tonumber(KeyStr)], Depth + 1, Seen)))
  end
  Seen[Value] = nil
  return "{" .. table.concat(Parts, ",") .. "}"
end

function LuaSerializer:OnEncode(_, Packet)
  return "return " .. EncodeLiteral(Packet, 1, {})
end

function LuaSerializer:OnDecode(_, Content)
  local Loader, ErrorMessage = load(Content)
  if Loader then
    local Success, Result = pcall(Loader)
    if Success then
      return Result
    end
  else
    RTTIStatistics:RecordError(true, "lua\232\167\163\230\158\144\229\164\177\232\180\165\239\188\154%s", ErrorMessage)
  end
end

return LuaSerializer
