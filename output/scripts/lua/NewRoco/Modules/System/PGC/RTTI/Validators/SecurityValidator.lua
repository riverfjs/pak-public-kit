local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local AbstractValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.AbstractValidator")
local SecurityValidator = AbstractValidator:Extend("SecurityValidator")
local BuiltinRules = {
  SqlInjectionRule = {
    Patterns = {
      {
        Regexp = "['\"%;%s]*(%s*union%s+select)"
      },
      {
        Regexp = "['\"%;%s]*(%s*drop%s+table)"
      },
      {
        Regexp = "['\"%;%s]*(%s*delete%s+from)"
      },
      {
        Regexp = "['\"%;%s]*(%s*insert%s+into)"
      },
      {
        Regexp = "['\"%;%s]*(%s*update%s+.+set)"
      },
      {
        Regexp = "['\"%;%s]*(%s*exec%s*%(%s*)"
      },
      {
        Regexp = "['\"%;%s]*(%s*script%s*>)"
      },
      {Regexp = "(%-%-%s*)"},
      {
        Regexp = "(/[%*].*[%*]/)"
      }
    },
    Message = "\230\163\128\230\181\139\229\136\176\230\189\156\229\156\168\231\154\132SQL\230\179\168\229\133\165\230\148\187\229\135\187"
  },
  XssAttackRule = {
    Patterns = {
      {
        Regexp = "(<script[^>]*>)"
      },
      {
        Regexp = "(<iframe[^>]*>)"
      },
      {
        Regexp = "(javascript%s*:)"
      },
      {
        Regexp = "(on%w+%s*=)"
      },
      {
        Regexp = "(<img[^>]*onerror)"
      },
      {
        Regexp = "(<svg[^>]*onload)"
      },
      {
        Regexp = "(eval%s*%(%s*)"
      },
      {
        Regexp = "(document%.cookie)"
      },
      {
        Regexp = "(window%.location)"
      }
    },
    Message = "\230\163\128\230\181\139\229\136\176\230\189\156\229\156\168\231\154\132XSS\230\148\187\229\135\187"
  },
  SensitiveRule = {
    Patterns = {
      {
        Regexp = "(%d{15}%d?%d?[%dxX])",
        Name = "\232\186\171\228\187\189\232\175\129\229\143\183"
      },
      {
        Regexp = "(1[3-9]%d{9})",
        Name = "\230\137\139\230\156\186\229\143\183"
      },
      {
        Regexp = "([%w%.%-_]+@[%w%.%-_]+%.%w+)",
        Name = "\233\130\174\231\174\177\229\156\176\229\157\128"
      },
      {
        Regexp = "(%d{4}[%s%-]?%d{4}[%s%-]?%d{4}[%s%-]?%d{4})",
        Name = "\233\147\182\232\161\140\229\141\161\229\143\183"
      }
    }
  }
}

local function ValidateBuiltinRules(self, Data)
  for FieldName, FiledValue in pairs(Data) do
    if type(FiledValue) == "string" then
      for _, RulInfo in pairs(BuiltinRules) do
        local LowerValue = string.lower(FiledValue)
        for _, Pattern in ipairs(RulInfo.Patterns) do
          if string.match(LowerValue, Pattern.Regexp) then
            local Message = RulInfo.Message
            if not Message and Pattern.Name then
              Message = string.format("\230\163\128\230\181\139\229\136\176\230\149\143\230\132\159\228\191\161\230\129\175\239\188\154%s", Pattern.Name)
            end
            if self:PushFieldError(FieldName, Message) then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

local function ValidateCustomSecurityRules(self, Data)
  local EnableBlacklist = RTTISettings:Get("Validation.EnableBlacklist")
  local EnableWhitelist = RTTISettings:Get("Validation.EnableWhitelist")
  for FieldName, FieldValue in pairs(Data) do
    if type(FieldValue) == "string" then
      FieldValue = string.lower(FieldValue)
      for RuleName, Rule in pairs(self.SecurityRules) do
        local Success, Message = Rule(FieldValue)
        if not Success and self:PushFieldError(FieldName, "\229\174\137\229\133\168\232\167\132\229\136\153'%s'\230\137\167\232\161\140\229\164\177\232\180\165: %s", RuleName, Message) then
          return true
        end
      end
      if EnableBlacklist then
        for RuleName, Regexp in pairs(self.BlacklistPatterns) do
          if string.match(FieldValue, Regexp) and self:PushFieldError(FieldName, "\229\134\133\229\174\185\229\140\185\233\133\141\233\187\145\229\144\141\229\141\149\230\168\161\229\188\143, \233\187\145\229\144\141\229\141\149\232\167\132\229\136\153\229\144\141\231\167\176\239\188\154%s", RuleName) then
            return true
          end
        end
      end
      if EnableWhitelist then
        local IsWhitelisted = false
        for _, Regexp in pairs(self.WhitelistPatterns) do
          if string.match(FieldValue, Regexp) then
            IsWhitelisted = true
            break
          end
        end
        if not IsWhitelisted and self:PushFieldError(FieldName, "\229\134\133\229\174\185\228\184\141\229\156\168\231\153\189\229\144\141\229\141\149\232\140\131\229\155\180\229\134\133") then
          return true
        end
      end
    end
  end
  return false
end

function SecurityValidator:RegisterSecurityRule(RuleName, Callback)
  if type(RuleName) ~= "string" or type(Callback) ~= "function" then
    RTTIStatistics:RecordError(true, "\230\179\168\229\134\140\229\174\137\229\133\168\232\167\132\229\136\153RuleName\229\191\133\233\161\187\230\152\175\229\173\151\231\172\166\228\184\178\239\188\140Callback\229\191\133\233\161\187\230\152\175\229\135\189\230\149\176")
    return false
  end
  if self.SecurityRules[RuleName] then
    RTTIStatistics:RecordError(false, "\229\174\137\229\133\168\232\167\132\229\136\153\227\128\144%s\227\128\145\229\183\178\231\187\143\229\173\152\229\156\168\239\188\140\229\176\134\228\188\154\232\162\171\232\166\134\231\155\150\239\188\129", RuleName)
  end
  self.SecurityRules[RuleName] = Callback
  return true
end

function SecurityValidator:RegisterBlacklistRegexp(RuleName, Regexp)
  if RTTISettings:Get("Validation.EnableBlacklist") then
    self.BlacklistPatterns[RuleName] = string.lower(Regexp)
  else
    RTTIStatistics:RecordError(true, "\233\187\145\229\144\141\229\141\149\229\138\159\232\131\189\229\183\178\231\166\129\231\148\168")
    return false
  end
  return true
end

function SecurityValidator:RegisterWhitelistRegexp(RuleName, Regexp)
  if RTTISettings:Get("Validation.EnableWhitelist") then
    self.WhitelistPatterns[RuleName] = string.lower(Regexp)
  else
    RTTIStatistics:RecordError(true, "\231\153\189\229\144\141\229\141\149\229\138\159\232\131\189\229\183\178\231\166\129\231\148\168")
    return false
  end
  return true
end

function SecurityValidator:OnReset()
  self.SecurityRules = {}
  self.BlacklistPatterns = {}
  self.WhitelistPatterns = {}
end

function SecurityValidator:OnExecute(_, Data)
  if ValidateBuiltinRules(self, Data) then
    return
  end
  if ValidateCustomSecurityRules(self, Data) then
    return
  end
end

return SecurityValidator
