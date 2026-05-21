local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local AbstractSerializer = RTTIBase.Class("AbstractSerializer")

local function ValidateVersionCompatibility(TypeInfo, ActualType, ActualVersion)
  local TypeName = TypeInfo.Name
  if nil == ActualType then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\230\141\174\230\178\161\230\156\137\230\144\186\229\184\166\231\177\187\229\158\139\229\144\141", TypeName)
    return false
  end
  if TypeName ~= ActualType then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\239\188\140\230\156\159\230\156\155:%s\239\188\140\229\174\158\233\153\133: %s", TypeName, ActualType)
    return false
  end
  if nil == ActualVersion then
    RTTIStatistics:RecordError(false, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\230\141\174\230\178\161\230\156\137\230\144\186\229\184\166\231\137\136\230\156\172\229\143\183", TypeName)
    return true
  end
  local ExpectedVersion = TypeInfo.Version
  if nil == ExpectedVersion then
    RTTIStatistics:RecordError(false, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\174\154\228\185\137\231\188\186\229\176\145\230\156\137\230\149\136\231\137\136\230\156\172\229\143\183", TypeName)
    return true
  end
  if ActualVersion > ExpectedVersion then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\230\141\174\231\137\136\230\156\172(%d)\233\171\152\228\186\142\231\177\187\229\158\139\231\137\136\230\156\172(%d)", TypeName, ActualVersion, ExpectedVersion)
    return false
  end
  return true
end

function AbstractSerializer:Serialize(TypeName, Object)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if TypeInfo then
    local Packet = {
      TypeName = TypeName,
      Version = TypeInfo.Version or 1,
      Timestamp = os.time(),
      Object = Object
    }
    return self:OnEncode(TypeInfo, Packet)
  else
    RTTIStatistics:RecordError(true, "\230\149\176\230\141\174\230\151\160\230\179\149\229\186\143\229\136\151\229\140\150\230\156\170\231\159\165\231\177\187\229\158\139\227\128\144%s\227\128\145", TypeName)
  end
end

function AbstractSerializer:Deserialize(TypeName, Content)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if TypeInfo then
    local DataFromDeserialize = self:OnDecode(TypeInfo, Content)
    if DataFromDeserialize and ValidateVersionCompatibility(TypeInfo, DataFromDeserialize.TypeName, DataFromDeserialize.Version) then
      return DataFromDeserialize.Object
    end
  else
    RTTIStatistics:RecordError(true, "\230\149\176\230\141\174\230\151\160\230\179\149\229\143\141\229\186\143\229\136\151\229\140\150\230\156\170\231\159\165\231\177\187\229\158\139\227\128\144%s\227\128\145", TypeName)
  end
end

function AbstractSerializer:OnEncode(TypeInfo, Packet)
end

function AbstractSerializer:OnDecode(TypeInfo, Content)
end

return AbstractSerializer
