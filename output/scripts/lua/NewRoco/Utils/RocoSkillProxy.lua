local Class = _G.MakeSimpleClass
local Delegate = require("Utils.Delegate")
local RocoSkillBlackboard = require("NewRoco.Modules.Core.Battle.Skill.RocoSkillBlackboard")
local State = {None = 1, Started = 2}

local function RunCallback(Owner, Callback, ...)
  if not Callback then
    return
  end
  if Owner then
    Callback(Owner, ...)
  else
    Callback(...)
  end
end

local RocoSkillProxy = Class("RocoSkillProxy")

function RocoSkillProxy.Create(Path, Comp, Priority)
  if string.IsNilOrEmpty(Path) then
    Log.Error("\228\188\160\229\133\165\231\154\132Path\228\184\186\231\169\186")
    return nil
  end
  if not Comp then
    Log.Error("\228\188\160\229\133\165\231\154\132Component\228\184\186\231\169\186")
    return nil
  end
  return RocoSkillProxy(Path, Comp, Priority)
end

function RocoSkillProxy:Ctor(Path, Comp, Priority)
  self.SkillPath = NRCUtils.FormatBlueprintAssetPath(Path)
  self.SkillComp = Comp
  self.Priority = Priority or 1
  self.State = State.None
  self.bIsPassive = false
  self.Callbacks = nil
  self.RawCallback = nil
  self.DynamicData = nil
  self.bStartFailedAsEnd = true
  self.bWithLoadAndPlay = true
  self.BattleGenderType = nil
  self.forcePlayPassiveSkill = false
  self.forcePlaySkill = false
  self.UseAddForPassiveSkill = false
  self.SkillUseCase = UE4.ESkillUseCase.Common
  self._fakeDelay = 0
  self._fakeDelayHandler = -1
  self.SkillPlayRate = 1
end

function RocoSkillProxy:GetSkillPath()
  return self.SkillPath
end

function RocoSkillProxy:PlaySkill(StartCallbackOwner, StartCallbackFunc)
  Log.Debug("RocoSkillProxy:PlaySkill")
  if StartCallbackFunc and type(StartCallbackFunc) ~= "function" then
    Log.Error("PlaySkill\231\154\132\231\172\172\228\186\140\228\184\170\229\143\130\230\149\176\230\152\175\239\188\154\229\155\158\232\176\131\229\135\189\230\149\176\239\188\140\228\187\150\229\190\151\230\152\175\228\184\170function")
  end
  if self.State == State.Started then
    RunCallback(StartCallbackOwner, StartCallbackFunc, self, UE.ESkillStartResult.StartFailed)
    return
  end
  self.State = State.Started
  self.StartCallbackOwner = StartCallbackOwner
  self.StartCallbackFunc = StartCallbackFunc
  if self._fakeDelay > 0 then
    self.Request = _G.NRCResourceManager:LoadResAsync(self, self.SkillPath, self.Priority, 0, self.OnFakeSuccess, self.OnFailed)
  else
    self.Request = _G.NRCResourceManager:LoadResAsync(self, self.SkillPath, self.Priority, 0, self.OnSuccess, self.OnFailed)
  end
end

function RocoSkillProxy:OnFakeSuccess(Request, Klass)
  if self._fakeDelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self._fakeDelayHandler)
    self._fakeDelayHandler = -1
  end
  self._fakeDelayHandler = _G.DelayManager:DelaySeconds(self._fakeDelay, self.OnSuccess, self, Request, Klass)
end

function RocoSkillProxy:SetPriority(value)
  self.Priority = value
end

function RocoSkillProxy:OnSuccess(Request, Klass)
  if self.Request ~= Request then
    Log.Error("\232\181\132\230\186\144\229\138\160\232\189\189\229\135\186\233\148\153\228\186\134", self.SkillPath)
    return
  end
  self:ReleaseRequest()
  self:SendEvent("LoadSuccess")
  if not UE4.UObject.IsValid(self.SkillComp) then
    self.State = State.None
    self:FireCallback(UE.ESkillStartResult.StartFailed)
    if self.bStartFailedAsEnd then
      self:SendEvent("End")
    end
    return
  end
  if self.UseAddForPassiveSkill and self.bIsPassive then
    self.SkillObject = self.SkillComp:AddSkillObjFromClassAndReturn(Klass)
  else
    self.SkillObject = self.SkillComp:FindOrAddSkillObj(Klass)
  end
  if not self.SkillObject then
    self.State = State.None
    self:FireCallback(UE.ESkillStartResult.StartFailed)
    if self.bStartFailedAsEnd then
      self:SendEvent("End")
    end
    return
  end
  if not self.bIsPassive and self.forcePlaySkill then
    local ActiveSkill = self.SkillComp:GetActiveSkill()
    if ActiveSkill then
      Log.Warning("\229\189\147\229\137\141\230\156\137\230\173\163\229\156\168\230\146\173\231\154\132\230\138\128\232\131\189\239\188\140\230\137\147\230\150\173", self.SkillPath, ActiveSkill and ActiveSkill:GetDisplayName())
      self.SkillComp:StopCurrentSkill()
    end
  end
  if not self.bIsPassive and self.SkillComp:GetActiveSkill() == self.SkillObject then
    self.State = State.None
    self:FireCallback(UE.ESkillStartResult.StartFailed)
    if self.bStartFailedAsEnd then
      self:SendEvent("End")
    end
    return
  end
  if self.bIsPassive and self.SkillComp:IsPassiveActive(self.SkillObject) then
    if self.forcePlayPassiveSkill or self.forcePlaySkill then
      Log.Debug("\232\162\171\229\138\168\230\138\128\232\131\189\228\185\159\230\156\137\229\188\186\232\161\140\230\146\173\230\148\190\231\154\132\230\157\131\229\136\169,\230\146\173!", self.SkillPath)
      self.SkillComp:CancelSkill(self.SkillObject, UE4.ESkillActionResult.SkillActionResultInterrupted)
    else
      self.State = State.None
      self:FireCallback(UE.ESkillStartResult.StartFailed)
      if self.bStartFailedAsEnd then
        self:SendEvent("End")
      end
      return
    end
  end
  if self.RawCallback then
    self.SkillObject.RawCallback = self.RawCallback
  end
  self.RawCallback = nil
  if self.DynamicData then
    self.SkillObject.DynamicData = self.DynamicData
    self.SkillObject:RefreshAllEnd()
  end
  self.DynamicData = nil
  if self.Callbacks then
    self.SkillObject.Callbacks = self.Callbacks
  end
  if self.BattleGenderType then
    self.SkillObject.BattleGenderType = self.BattleGenderType
  end
  self.BattleGenderType = nil
  self.Callbacks = nil
  self.SkillObject:SetPriority(self.Priority)
  self.SkillObject:SetPassive(self.bIsPassive)
  self.SkillObject:SetSkillUseCase(self.SkillUseCase)
  self.SkillObject:SendLuaEvent("PreStart")
  if self.bStartFailedAsEnd then
    self.SkillObject:RegisterEventCallback("ActivateFailed", self, self.OnActivateFailed)
  end
  self.SkillObject:SetPlayRate(self.SkillPlayRate)
  local Result = UE.ESkillStartResult.SystemsError
  if self.bWithLoadAndPlay then
    Result = self.SkillComp:LoadAndPlaySkill(self.SkillObject)
  else
    Result = self.SkillComp:PlaySkill(self.SkillObject)
  end
  self.State = State.None
  self:FireCallback(Result)
  if Result ~= UE.ESkillStartResult.Success and self.bStartFailedAsEnd then
    self.SkillObject:SendLuaEvent("End")
  end
end

function RocoSkillProxy:OnActivateFailed(Name, SkillObject)
  SkillObject:SendLuaEvent("End")
end

function RocoSkillProxy:OnFailed(Request, Message)
  if self.Request ~= Request then
    Log.Error("\232\181\132\230\186\144\229\138\160\232\189\189\229\135\186\233\148\153\228\186\134", self.SkillPath, Message)
    return
  end
  self:SendEvent("LoadFailed")
  if self.bStartFailedAsEnd then
    self:SendEvent("End")
  end
  self:ReleaseRequest()
  self.State = State.None
  self:FireCallback(UE.ESkillStartResult.SystemsError)
end

function RocoSkillProxy:CancelSkill(Reason)
  if self.SkillObject and UE4.UObject.IsValid(self.SkillComp) then
    self.SkillComp:CancelSkill(self.SkillObject, Reason)
  else
    Log.Debug("RocoSkillProxy:CancelSkill")
  end
end

function RocoSkillProxy:Destroy()
  self.SkillObject = nil
  self.SkillComp = nil
  self.Callbacks = nil
  self.RawCallback = nil
  self.DynamicData = nil
  self:ReleaseRequest()
  self.State = State.None
  self:FireCallback(UE.ESkillStartResult.SystemsError)
end

function RocoSkillProxy:FireCallback(Result)
  local Callback = self.StartCallbackFunc
  local CallbackOwner = self.StartCallbackOwner
  self.StartCallbackFunc = nil
  self.StartCallbackOwner = nil
  RunCallback(CallbackOwner, Callback, self, Result)
end

function RocoSkillProxy:ReleaseRequest()
  if self._fakeDelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self._fakeDelayHandler)
    self._fakeDelayHandler = -1
  end
  if not self.Request then
    return
  end
  _G.NRCResourceManager:UnLoadRes(self.Request)
  self.Request = nil
end

function RocoSkillProxy:SetPassive(bIsPassive)
  self.bIsPassive = bIsPassive
end

function RocoSkillProxy:SetSkillUseType(SkillUseCase)
  self.SkillUseCase = SkillUseCase
end

function RocoSkillProxy:SetUseAddForPassiveSkill(bUseAddForPassiveSkill)
  self.UseAddForPassiveSkill = bUseAddForPassiveSkill
end

function RocoSkillProxy:SetStartFailedAsEnd(bStartFailedAsEnd)
  self.bStartFailedAsEnd = bStartFailedAsEnd
end

function RocoSkillProxy:SetWithLoadAndPlay(bWithLoadAndPlay)
  self.bWithLoadAndPlay = bWithLoadAndPlay
end

function RocoSkillProxy:SetForcePlayPassive(bForcePlayPassive)
  self.forcePlayPassiveSkill = bForcePlayPassive
end

function RocoSkillProxy:SetForcePlaySkill(bForcePlaySkill)
  self.forcePlaySkill = bForcePlaySkill
end

function RocoSkillProxy:SetPlayRate(PlayRate)
  self.SkillPlayRate = PlayRate
end

function RocoSkillProxy:SendEvent(Name)
  if self.Callbacks then
    local Dlg = self.Callbacks[Name]
    if Dlg then
      Dlg:Invoke(Name, self.SkillObject)
    end
  end
  if self.RawCallback then
    self.RawCallback:Invoke(Name, self.SkillObject)
  end
end

function RocoSkillProxy:RegisterEventCallback(EventName, Caller, Callback)
  if string.IsNilOrEmpty(EventName) then
    return self
  end
  if not Callback then
    return self
  end
  if not self.Callbacks then
    self.Callbacks = {}
  end
  local CallbackDelegate = self.Callbacks[EventName]
  if not CallbackDelegate then
    CallbackDelegate = Delegate()
    self.Callbacks[EventName] = CallbackDelegate
  elseif self.Callbacks[EventName]:Has(Caller, Callback) then
    Log.Debug("\230\138\128\232\131\189\233\135\141\229\164\141\230\179\168\229\134\140\228\186\134callback:", self, EventName)
    return self
  end
  CallbackDelegate:Remove(Caller, Callback)
  CallbackDelegate:Add(Caller, Callback)
  return self
end

function RocoSkillProxy:UnregisterEventCallback(EventName, Caller, Callback)
  if string.IsNilOrEmpty(EventName) then
    return
  end
  if not Callback then
    return
  end
  if not self.Callbacks then
    return
  end
  local CallbackDelegate = self.Callbacks[EventName]
  if not CallbackDelegate then
    return
  end
  CallbackDelegate:Remove(Caller, Callback)
end

function RocoSkillProxy:RegisterRawCallback(Caller, Callback)
  if not Callback then
    return self
  end
  if not self.RawCallback then
    self.RawCallback = Delegate()
  end
  self.RawCallback:Remove(Caller, Callback)
  self.RawCallback:Add(Caller, Callback)
end

function RocoSkillProxy:UnregisterRawCallback(Caller, Callback)
  if not Callback then
    return self
  end
  if not self.RawCallback then
    return
  end
  self.RawCallback:Remove(Caller, Callback)
end

function RocoSkillProxy:SetSkillID(SkillID)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.SkillID = SkillID
  return self
end

function RocoSkillProxy:SetTargets(targets)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.Targets = targets
  return self
end

function RocoSkillProxy:SetLocation(Location)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.Location = Location
  return self
end

function RocoSkillProxy:SetCharacters(characters)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.Characters = characters
  return self
end

function RocoSkillProxy:SetBallAdditionalPaths(ballPath)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.BallAdditionalPaths = ballPath
  return self
end

function RocoSkillProxy:SetCaster(caster)
  if not caster then
    return self
  end
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.Caster = caster
  return self
end

function RocoSkillProxy:GetCaster()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Caster
end

function RocoSkillProxy:SetSettings(settings)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData.Settings = settings
end

function RocoSkillProxy:SetDynamicData(Params)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData:Set(Params)
  return self
end

function RocoSkillProxy:SetAdditions(K, V)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData:SetAdditions(K, V)
  return self
end

function RocoSkillProxy:GetAddition(K)
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Additions[K]
end

return RocoSkillProxy
