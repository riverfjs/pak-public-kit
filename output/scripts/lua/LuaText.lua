local LuaText = {}

function LuaText:Init()
end

function LuaText:GetErrorDesc(Code)
  local Key = string.format("Error_Code_%d", Code)
  local Desc = self[Key]
  if not RocoEnv.IS_SHIPPING then
    if string.IsNilOrEmpty(Desc) then
      local ErrorCodeDesc = require("Data.PB.ErrorCodeDesc")
      Desc = ErrorCodeDesc[Code]
    end
    if string.IsNilOrEmpty(Desc) then
      Desc = "\230\151\160\233\148\153\232\175\175\231\160\129\230\143\143\232\191\176"
    end
    Desc = string.format("%s(%d)", Desc, Code)
  end
  return Desc
end

setmetatable(LuaText, {
  __index = function(t, k)
    local raw = _G.DataConfigManager:GetLocalizationConf(k, true)
    if raw then
      return raw.msg
    else
      return string.format("%s\230\156\170\233\133\141\231\189\174", tostring(k))
    end
  end
})
return LuaText
