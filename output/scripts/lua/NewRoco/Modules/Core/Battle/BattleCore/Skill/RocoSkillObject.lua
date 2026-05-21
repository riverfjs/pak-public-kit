local Delegate = require("Utils.Delegate")
local RocoSkillBlackboard = require("NewRoco.Modules.Core.Battle.Skill.RocoSkillBlackboard")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local RocoSkillObject = NRCClass()

function RocoSkillObject:Ctor()
  self.isReleaseRes = false
  self.CleanupMaterials = false
  self.IsSkillEditor = false
  self.Callbacks = {}
  self.RawCallback = Delegate()
  self.DynamicData = RocoSkillBlackboard()
  self.counterNode = 0
  self.countSkillType = Enum.SkillType.ST_NONE
  self.isCounter = false
  self.isInBulletTime = false
  self.GetActorCacheDict = {}
  self.jumpErrorLog = false
  WeakTable(self.GetActorCacheDict)
  BattleEventCenter:Bind(self, BattleEvent.SKillEvent_TriggerBeHit, BattleEvent.SKillEvent_EnterBulletTime, BattleEvent.SKillEvent_LeaveBulletTime, BattleEvent.SKillEvent_OnCounterEnd)
end

function RocoSkillObject:RegisterEventCallback(EventName, Caller, Callback)
  if string.IsNilOrEmpty(EventName) then
    return self
  end
  if not Callback then
    return self
  end
  local CallbackDelegate = self.Callbacks[EventName]
  if not CallbackDelegate then
    CallbackDelegate = Delegate()
    self.Callbacks[EventName] = CallbackDelegate
  elseif self.Callbacks[EventName]:Has(Caller, Callback) then
    Log.Debug("\230\138\128\232\131\189\233\135\141\229\164\141\230\179\168\229\134\140\228\186\134callback:", self:GetName(), EventName)
    return self
  end
  CallbackDelegate:Remove(Caller, Callback)
  CallbackDelegate:Add(Caller, Callback)
  return self
end

function RocoSkillObject:UnregisterEventCallback(EventName, Caller, Callback)
  if string.IsNilOrEmpty(EventName) then
    return
  end
  if not Callback then
    return
  end
  local CallbackDelegate = self.Callbacks[EventName]
  if not CallbackDelegate then
    return
  end
  CallbackDelegate:Remove(Caller, Callback)
end

function RocoSkillObject:RegisterRawCallback(Caller, Callback)
  if not Callback then
    return self
  end
  if not self.RawCallback then
    return
  end
  self.RawCallback:Remove(Caller, Callback)
  self.RawCallback:Add(Caller, Callback)
end

function RocoSkillObject:UnregisterRawCallback(Caller, Callback)
  if not Callback then
    return self
  end
  if not self.RawCallback then
    return
  end
  self.RawCallback:Remove(Caller, Callback)
end

function RocoSkillObject:SetSkillID(SkillID)
  self.DynamicData.SkillID = SkillID
  return self
end

function RocoSkillObject:SetTargets(targets)
  if type(targets) ~= "table" then
    Log.Error("SetTargets\231\177\187\229\158\139\233\148\153\232\175\175\239\188\140\233\156\128\232\166\129\228\184\186\230\149\176\231\187\132")
  end
  self:ClearActorEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
  self.DynamicData.Targets = targets
  self:AddActorsEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
  return self
end

function RocoSkillObject:SetLocation(Location)
  self.DynamicData.Location = Location
  return self
end

function RocoSkillObject:SetSelectLocations(LocationList)
  if not LocationList then
    return
  end
  if not self.DynamicData.SelectLocations then
    self.DynamicData.SelectLocations = {}
  end
  for _, posInfo in ipairs(LocationList) do
    _G.table.insert(self.DynamicData.SelectLocations, posInfo)
  end
end

function RocoSkillObject:ClearSelectLocations()
  _G.table.clear(self.DynamicData.SelectLocations)
end

function RocoSkillObject:GetSelectLocationByIdx(pointIdx)
  if self.IsSkillEditor then
    local target = self.DynamicData.Targets[1]
    if target then
      return target:K2_GetActorLocation()
    end
    return nil
  end
  local point = _G.ProtoMessage:newPosition()
  for _, posInfo in ipairs(self.DynamicData.SelectLocations) do
    if posInfo.point_idx == pointIdx then
      point = posInfo.target_pos
    end
  end
  point = SceneUtils.ServerPos2ClientPos(point)
  point = SceneUtils.ConvertAbsoluteToRelative(point)
  return point
end

function RocoSkillObject:SetCharacters(characters)
  self:ClearActorEnd(self.DynamicData.Characters, self, self.CharacterActorEndPlay)
  self.DynamicData.Characters = characters
  self:AddActorsEnd(self.DynamicData.Characters, self, self.CharacterActorEndPlay)
  return self
end

function RocoSkillObject:SetBallAdditionalPaths(ballPath)
  self.DynamicData.BallAdditionalPaths = ballPath
  return self
end

function RocoSkillObject:SetCaster(caster)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:ClearActorEnd({
    self.DynamicData.Caster
  }, self, self.CasterActorEndPlay)
  self.DynamicData.Caster = caster
  self:AddActorsEnd({
    self.DynamicData.Caster
  }, self, self.CasterActorEndPlay)
  return self
end

function RocoSkillObject:SetCounterActor(counterActor)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:ClearActorEnd({
    self.DynamicData.CounterActor
  }, self, self.CounterActorEndPlay)
  self.DynamicData.CounterActor = counterActor
  self:AddActorsEnd({
    self.DynamicData.CounterActor
  }, self, self.CounterActorEndPlay)
  return self
end

function RocoSkillObject:SetBeCounterActor(beCounterActor)
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:ClearActorEnd({
    self.DynamicData.BeCounterActor
  }, self, self.BeCounterActorEndPlay)
  self.DynamicData.BeCounterActor = beCounterActor
  self:AddActorsEnd({
    self.DynamicData.BeCounterActor
  }, self, self.BeCounterActorEndPlay)
  return self
end

function RocoSkillObject:CounterActorEndPlay(Actor, reason)
  if self.DynamicData and Actor == self.DynamicData.CounterActor then
    self.DynamicData.CounterActor = nil
  end
end

function RocoSkillObject:BeCounterActorEndPlay(Actor, reason)
  if self.DynamicData and Actor == self.DynamicData.BeCounterActor then
    self.DynamicData.BeCounterActor = nil
  end
end

function RocoSkillObject:CasterActorEndPlay(Actor, reason)
  if self.DynamicData and Actor == self.DynamicData.Caster then
    self.DynamicData.Caster = nil
  end
end

function RocoSkillObject:TargetActorEndPlay(Actor, reason)
  if self.DynamicData and self.DynamicData.Targets then
    for i, v in ipairs(self.DynamicData.Targets) do
      if v == Actor then
        self.DynamicData.Targets[i] = nil
        return
      end
    end
  end
end

function RocoSkillObject:CharacterActorEndPlay(Actor, reason)
  if self.DynamicData and self.DynamicData.Characters then
    for i = 0, 15 do
      if self.DynamicData.Characters[i] == Actor then
        self.DynamicData.Characters[i] = nil
      end
    end
  end
end

function RocoSkillObject:SetSettings(settings)
  self.DynamicData.Settings = settings
end

function RocoSkillObject:SetPower(Power)
  self.Power = Power
end

function RocoSkillObject:SetIsRestraint(IsRestraint)
  self.bIsRestraint = IsRestraint
end

function RocoSkillObject:SetIsRestrained(IsRestrained)
  self.bIsRestrained = IsRestrained
end

function RocoSkillObject:SetReduceHP(ReduceHP)
  self.ReduceHP = ReduceHP
end

function RocoSkillObject:SetDynamicData(Params)
  self.DynamicData:Set(Params)
  return self
end

function RocoSkillObject:SetAdditions(K, V)
  self.DynamicData:SetAdditions(K, V)
  return self
end

function RocoSkillObject:GetCaster()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Caster
end

function RocoSkillObject:GetCharacters()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Characters
end

function RocoSkillObject:GetAddition(K)
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Additions[K]
end

function RocoSkillObject:GetSkillID()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.SkillID
end

function RocoSkillObject:GetTargets()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Targets
end

function RocoSkillObject:GetLocation()
  if not self.DynamicData then
    return nil
  end
  return self.DynamicData.Location
end

function RocoSkillObject:NativeSetCounterActor(CounterActor)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:SetCounterActor(CounterActor)
end

function RocoSkillObject:NativeSetBeCounterActor(BeCounterActor)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:SetBeCounterActor(BeCounterActor)
end

function RocoSkillObject:NativeSetCaster(Caster)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:SetCaster(Caster)
end

function RocoSkillObject:NativeSetCharacters(Characters)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self:SetCharacters(Characters:ToTable())
end

function RocoSkillObject:NativeSetTargets(Targets)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  local DynTargets = self.DynamicData.Targets
  if not DynTargets then
    DynTargets = {}
    self.DynamicData.Targets = DynTargets
  end
  self:ClearActorEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
  for i = 1, Targets:Length() do
    local target = Targets:Get(i)
    table.insert(DynTargets, target)
  end
  self:AddActorsEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
end

function RocoSkillObject:NativeSetDataAsString(Key, Value)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  self.DynamicData[Key] = Value
end

function RocoSkillObject:NativeSetArrayPaths(Key, Values)
  self.IsSkillEditor = true
  if not self.DynamicData then
    self.DynamicData = RocoSkillBlackboard()
  end
  local DynArray = self.DynamicData[Key]
  if not DynArray then
    DynArray = {}
    self.DynamicData[Key] = DynArray
  end
  for i = 1, Values:Length() do
    table.insert(DynArray, Values:Get(i))
  end
end

function RocoSkillObject:NativeSetBattleFieldConf(Conf)
  self.IsSkillEditor = true
  self.BattleFieldConf = Conf
end

function RocoSkillObject:GetBattleFieldConf()
  if not UE.UObject.IsValid(self.BattleFieldConf) then
    return nil
  end
  return self.BattleFieldConf
end

function RocoSkillObject:OnCreateInstance()
  if self.Object and self.Object:IsValid() then
    Log.DebugFormat("SkillObject Instance %s Created", self.Object:GetName())
  else
    Log.Error("This skill object is not valid")
    return
  end
  self.Blackboard = NewObject(UE4.USkillBlackboard, self.Object)
  if _G.BattleManager then
    self.BattleFieldConf = _G.BattleManager.vBattleField.battleFieldConf
  end
end

function RocoSkillObject:OnSkillEvent(eventName, ...)
  if self.hasCPPEvent then
    local actions = self:GetAllActions()
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action:IsA(UE4.URocoAddSkillEventAction) then
        action:OnSkillEvent(eventName)
      end
    end
  end
end

function RocoSkillObject:OnBattleEvent(event, param1, param2)
  if event == BattleEvent.SKillEvent_TriggerBeHit then
    if param2 and self ~= param1 then
      for i = 1, #param2 do
        if self:GetCaster() == param2[i] then
          self:BroadcastTriggerEvent("BeingAttacked")
          break
        end
      end
    end
    return true
  elseif event == BattleEvent.SKillEvent_EnterBulletTime then
    if self.counterNode == param1 then
      self:SetBeCounter(param1, param2)
      UE4.RocoSkillUtils.StopCameraShakeActions(self)
      self.isInBulletTime = true
    end
    return true
  elseif event == BattleEvent.SKillEvent_LeaveBulletTime then
    if self.counterNode == param1 then
      self.isInBulletTime = false
    end
    return true
  elseif event == BattleEvent.SKillEvent_OnCounterEnd then
    if self.counterNode == param1 then
      self:SetBeCounter(0, Enum.SkillType.ST_NONE)
    end
    return true
  end
end

function RocoSkillObject:OnDestroyInstance()
  if self.Object and self.Object:IsValid() then
    Log.DebugFormat("SkillObject Instance %s Destructing", self.Object:GetName())
  else
    Log.Error("A SkillObject Instance Is Being Destructed")
    return
  end
  self.GetActorCacheDict = {}
  BattleEventCenter:UnBind(self)
  Log.Debug("Destroy Skill :", self:GetName())
  self:ReleaseRes()
end

function RocoSkillObject:ClearAllBindEvent()
  if self.m_BindEventActions then
    for _, Action in tpairs(self.m_BindEventActions) do
      if Action and Action:IsValid() then
        Action:OnActionDestruct()
      end
    end
  end
  if self:IsObjValid() then
    self.m_BindEventActions:Clear()
  end
  _G.RocoSkillEventCenter:RemoveEventBySkillObj(self)
end

function RocoSkillObject:OnSkillStart()
  self.isReleaseRes = false
  BattleUtils.ChangeBattleRtpc(self:GetCaster())
  self:SendLuaEvent("Start")
  self.hasCPPEvent = false
  local actions = self:GetAllActions()
  for i = 1, actions:Length() do
    local action = actions:Get(i)
    if action:IsA(UE4.URocoAddSkillEventAction) then
      for i = 1, action.EventParams:Length() do
        self:AddSkillEvent(action.EventParams[i].RawSkillEvent)
        self.hasCPPEvent = true
      end
    end
  end
end

function RocoSkillObject:OnSkillActionStart()
  self:SendLuaEvent("ActionStart")
end

function RocoSkillObject:OnSkillStartFailed(Result)
  if not self.IsObjValid or not self:IsObjValid() then
    Log.Error("RocoSkillObject OnSkillStartFailed obj is invalid")
    return
  end
  local Dlg = self:GetEventCallBack("StartFailed")
  if Dlg then
    Dlg:Invoke("StartFailed", self, Result)
    self:ClearDelegates()
    if not self.jumpErrorLog then
      Log.Warning("\230\138\128\232\131\189\229\188\128\229\167\139\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129:", self:GetName(), Result)
    end
  elseif not self.jumpErrorLog then
    Log.Error("\230\138\128\232\131\189\229\188\128\229\167\139\229\164\177\232\180\165: \230\178\161\230\156\137\231\155\145\229\144\172\229\164\177\232\180\165\228\186\139\228\187\182\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129", self:GetName(), Result)
  end
end

function RocoSkillObject:AddSkillEvent(eventName)
  if string.IsNilOrEmpty(eventName) then
    return
  end
  if _G.RocoSkillEventCenter then
    _G.RocoSkillEventCenter:AddEvent(eventName, self)
  end
end

function RocoSkillObject:OnSkillBranch()
  self:SendLuaEvent("Branch")
end

function RocoSkillObject:SetJumpErrorLog()
  self.jumpErrorLog = true
end

function RocoSkillObject:OnSkillInterrupt()
  if not self.IsObjValid or not self:IsObjValid() then
    Log.Error("RocoSkillObject OnSkillInterrupt obj is invalid")
    return
  end
  if not self.jumpErrorLog then
    local Dlg = self:GetEventCallBack("Interrupt")
    if Dlg then
      Log.Warning("\230\138\128\232\131\189\232\162\171\230\137\147\230\150\173\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129:", self:GetName())
    else
      Log.Error("\230\138\128\232\131\189\232\162\171\230\137\147\230\150\173: \230\178\161\230\156\137\231\155\145\229\144\172\230\137\147\230\150\173\228\186\139\228\187\182\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129", self:GetName())
    end
  end
  self:SendLuaEvent("Interrupt")
end

function RocoSkillObject:OnSkillEnd()
  if self.SendAndClearDelegates then
    self:SendAndClearDelegates("End")
  else
    Log.Error("SendAndClearDelegates is nil")
  end
  if self.ClearData then
    self:ClearData()
  else
    Log.Error("zgx ClearData is nil")
  end
  if self.ClearDelegates then
    self:ClearDelegates()
  else
    Log.Error("zgx ClearDelegates is nil")
  end
end

function RocoSkillObject:RefreshAllEnd()
  self:ClearAllEnd()
  if self.DynamicData then
    self:AddActorsEnd({
      self.DynamicData.Caster
    }, self, self.CasterActorEndPlay)
    self:AddActorsEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
    self:AddActorsEnd(self.DynamicData.Characters, self, self.CharacterActorEndPlay)
  end
end

function RocoSkillObject:AddActorsEnd(actors, caller, handle)
  if actors then
    for i, v in ipairs(actors) do
      if v and UE.UObject.IsValid(v) then
        v.OnEndPlay:Add(caller, handle)
      end
    end
  end
end

function RocoSkillObject:ClearAllEnd()
  if self.DynamicData then
    self:ClearActorEnd({
      self.DynamicData.Caster
    }, self, self.CasterActorEndPlay)
    self:ClearActorEnd(self.DynamicData.Targets, self, self.TargetActorEndPlay)
    self:ClearActorEnd(self.DynamicData.Characters, self, self.CharacterActorEndPlay)
  end
end

function RocoSkillObject:ClearActorEnd(actors, caller, callBack)
  if not actors then
    return
  end
  for i, v in ipairs(actors) do
    if v and UE.UObject.IsValid(v) then
      v.OnEndPlay:Remove(caller, callBack)
    end
  end
end

function RocoSkillObject:ClearData()
  self:ClearBlackboardData()
  if self.DynamicData then
    self:ClearAllEnd()
    self.DynamicData:Clear()
  end
end

function RocoSkillObject:ReleaseRes()
  if not self:IsObjValid() then
    return
  end
  self.isReleaseRes = true
  if self.Blackboard and UE.UObject.IsValid(self.Blackboard) and self.Blackboard.ObjectParams then
    local objectParams = self.Blackboard.ObjectParams:Length()
    if objectParams > 0 then
      local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      for i = 1, objectParams do
        if localPlayer and localPlayer.viewObj == self.Blackboard.ObjectParams:Values():Get(i) then
          self.Blackboard.ObjectParams:Values():Remove(i)
          break
        end
      end
    end
  end
  self:ClearData()
  self:ClearBlackboardData()
  self:ClearAllBindEvent()
end

function RocoSkillObject:IsObjValid()
  return self.isReleaseRes ~= true and self.isReleaseRes ~= nil and UE.UObject.IsValid(self)
end

function RocoSkillObject:ClearActorMaterial(actor)
end

function RocoSkillObject:ClearDelegates()
  for _, Del in pairs(self.Callbacks) do
    Del:Clear()
  end
  table.clear(self.Callbacks)
  if self.RawCallback then
    self.RawCallback:Clear()
  end
end

function RocoSkillObject:SendAndClearDelegates(event)
  local Callbacks = self.Callbacks
  self.Callbacks = {}
  local RawCallback = self.RawCallback
  self.RawCallback = nil
  self:SendLuaEvent(event, Callbacks, RawCallback)
  self.Callbacks = Callbacks
  self.RawCallback = RawCallback
  self:ClearDelegates()
end

function RocoSkillObject:GetEventCallBack(event, Callbacks)
  Callbacks = Callbacks or self.Callbacks
  return Callbacks[event]
end

function RocoSkillObject:SendLuaEvent(event, Callbacks, RawCallback)
  if not self.IsObjValid or not self:IsObjValid() then
    Log.Error("RocoSkillObject SendLuaEvent obj is invalid")
    return
  end
  RawCallback = RawCallback or self.RawCallback
  local Dlg = self:GetEventCallBack(event, Callbacks)
  if Dlg then
    Dlg:Invoke(event, self)
  end
  if "TriggerBeHit" == event then
    BattleEventCenter:Dispatch(BattleEvent.SKillEvent_TriggerBeHit, self, self:GetTargets())
  end
  if RawCallback then
    RawCallback:Invoke(event, self)
  end
  if "PreEnd" == event or "PreEndAnim" == event or "Interrupt" == event or "StartFailed" == event then
    self:ClearDelegates()
  end
end

function RocoSkillObject:MarkDebug(debug)
  debug = true == debug
  for _, Action in tpairs(self.m_TotalActions) do
    Action.m_DebugFlag = debug
  end
end

function RocoSkillObject:SetCounter(isCounter)
  self.isCounter = isCounter
end

function RocoSkillObject:SetBeCounter(counterNode, countSkillType)
  self.counterNode = counterNode
  self.countSkillType = countSkillType
end

function RocoSkillObject:GetBeCounterByDamage()
  return self.countSkillType == Enum.SkillType.ST_DAMAGE
end

function RocoSkillObject:GetBeCounterByDefend()
  return self.countSkillType == Enum.SkillType.ST_DEFEND
end

function RocoSkillObject:GetBasicSkill()
  return not self:GetCounter()
end

function RocoSkillObject:GetCounter()
  if self.IsSkillEditor and self.Overridden then
    return self.Overridden.GetCounter(self)
  else
    return self.isCounter
  end
end

function RocoSkillObject:GetBeCounter()
  if self.IsSkillEditor and self.Overridden then
    return self.Overridden.GetBeCounter(self)
  else
    return self.counterNode and self.counterNode > 0
  end
end

function RocoSkillObject:GetNormalSkill()
  return not self:GetCounter() and not self:GetBeCounter()
end

function RocoSkillObject:GetBeCounting()
  return self.countSkillType ~= Enum.SkillType.ST_NONE
end

return RocoSkillObject
