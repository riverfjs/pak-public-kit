local AbstractSerializer = require("NewRoco.Modules.System.PGC.RTTI.Serializers.AbstractSerializer")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local JsonSerializer = AbstractSerializer:Extend("JsonSerializer")

function JsonSerializer:Ctor()
  self.Json = require("rapidjson")
end

function JsonSerializer:OnEncode(_, Packet)
  if self.Json and self.Json.encode then
    return self.Json.encode(Packet)
  else
    RTTIStatistics:RecordError(true, "\230\156\170\230\137\190\229\136\176\229\143\175\231\148\168\231\154\132json\229\186\147")
  end
end

function JsonSerializer:OnDecode(_, Content)
  if self.Json and self.Json.decode then
    return self.Json.decode(Content)
  else
    RTTIStatistics:RecordError(true, "\230\156\170\230\137\190\229\136\176\229\143\175\231\148\168\231\154\132json\229\186\147")
  end
end

return JsonSerializer
