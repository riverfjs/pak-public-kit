local CdnResChecker = Class("CdnResChecker")

function CdnResChecker:Ctor(caller, callback)
  self.IsMissing = nil
  self.RawUrl = nil
  self.Url = nil
  self.HttpService = nil
  self.HttpServiceRef = nil
  self.VerificationKeys = {}
  self.GetedKeys = {}
  self.OnResMissing = _G.MakeWeakFunctor(caller, callback)
end

function CdnResChecker:Release()
  if self.HttpService and UE.UObject.IsValid(self.HttpService) then
    UnLua.Unref(self.HttpService)
    self.HttpService = nil
    self.HttpServiceRef = nil
  end
  self.IsMissing = nil
  self.RawUrl = nil
  self.Url = nil
end

function CdnResChecker:SetUrl(url)
  if self.RawUrl == url then
    return false
  end
  self.RawUrl = url
  self.IsMissing = nil
  table.clear(self.VerificationKeys)
  if not string.IsNilOrEmpty(url) then
    local timestamp = tostring(_G.ZoneServer:GetServerTime())
    if string.find(url, "?") then
      self.Url = url .. "&_t=" .. timestamp
    else
      self.Url = url .. "?_t=" .. timestamp
    end
  else
    self.Url = nil
  end
  return true
end

function CdnResChecker:SetVerificationKeys(key, value)
  self.VerificationKeys[string.lower(key)] = value
end

function CdnResChecker:Check()
  if self.IsMissing then
    if self.OnResMissing then
      self.OnResMissing()
    end
    return
  end
  self:CheckInternal()
end

function CdnResChecker:CheckInternal()
  if string.IsNilOrEmpty(self.Url) or table.isEmpty(self.VerificationKeys) then
    return
  end
  if not string.IsNilOrEmpty(self.AsyncCheckingUrl) then
    return
  end
  if not self.HttpService then
    self.HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
    if self.HttpService then
      self.HttpServiceRef = UnLua.Ref(self.HttpService)
    end
  end
  if self.HttpService then
    self.AsyncCheckingUrl = self.RawUrl
    table.clear(self.GetedKeys)
    self.HttpService:ResetHeaders()
    self.HttpService:ResetFields()
    self.HttpService:SetUrl(self.Url)
    self.HttpService:SetVerb("HEAD")
    self.HttpService:SetHeaderReceivedDelegate({
      self.HttpService,
      function(_, Key, Value)
        self.GetedKeys[string.lower(Key)] = Value
      end
    })
    self.HttpService:Request({
      self.HttpService,
      function(_, Status)
        self:ValidKeys()
        self.AsyncCheckingUrl = nil
      end
    })
  end
end

function CdnResChecker:ValidKeys()
  if self.AsyncCheckingUrl ~= self.RawUrl then
    return
  end
  local isValid = true
  for key, value in pairs(self.VerificationKeys) do
    if value ~= self.GetedKeys[key] then
      isValid = false
      break
    end
  end
  if not isValid then
    self.IsMissing = true
    self.OnResMissing()
  end
end

return CdnResChecker
