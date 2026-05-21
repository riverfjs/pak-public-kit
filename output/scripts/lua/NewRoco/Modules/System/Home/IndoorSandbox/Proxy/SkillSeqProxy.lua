local DelegateClass = require("Utils.Delegate")
local RocoSkillBlackboard = require("NewRoco.Modules.Core.Battle.Skill.RocoSkillBlackboard")
local Queue = require("Utils.Queue")
local SkillElemConfig = Class("SkillElemConfig")

function SkillElemConfig:Ctor(CasterKey, G6SkillPath, bAutoPlay)
  self.CasterKey = CasterKey
  self.TargetKeys = {}
  self.CharacterKeys = {}
  self.G6SkillPath = nil
  self.G6SkillClass = nil
  self.SeqOwner = nil
  self.G6Request = nil
  self.Events = {}
  self.EventInstMap = {}
  self.bAutoPlay = bAutoPlay
  self:SetG6SkillPath(G6SkillPath)
end

function SkillElemConfig:OnBindSeq(Seq)
  self.SeqOwner = Seq
end

function SkillElemConfig:SetG6SkillPath(Path)
  self.G6SkillPath = NRCUtils.FormatBlueprintAssetPath(Path)
end

function SkillElemConfig:SetTargetKeys(TargetKeys)
  self.TargetKeys = TargetKeys
end

function SkillElemConfig:SetCharacterKeys(CharacterKeys)
  self.CharacterKeys = CharacterKeys
end

function SkillElemConfig:SetPrepareSkillDelegate(Delegate)
  self.PrepareSkillDelegate = Delegate
end

function SkillElemConfig:Destroy()
  if self.G6Request then
    NRCResourceManager:UnLoadRes(self.G6Request)
    self.G6Request = nil
  end
  self.G6SkillClassRef = nil
  self.G6SkillClass = nil
  self:TryCancel()
end

function SkillElemConfig:SetSkillEvent(EventName, Delegate)
  self.Events[EventName] = Delegate
end

function SkillElemConfig:PrepareLoad(OnFinish)
  assert(not self.G6Request)
  assert(self.G6SkillPath)
  
  local function OnSuc(_1, _2, Asset)
    self.G6SkillClass = Asset
    self.G6SkillClassRef = UnLua.Ref(Asset)
    self.G6Request = nil
    OnFinish(Asset)
  end
  
  local function OnFailed()
    self.G6Request = nil
    OnFinish()
  end
  
  local function OnUnload()
    self.G6Request = nil
    OnFinish()
  end
  
  Log.Debug("SkillSeqProxy:PrepareLoad", self.G6SkillPath)
  self.G6Request = NRCResourceManager:LoadResAsync(self, self.G6SkillPath, 256, 0, OnSuc, OnFailed, nil, OnUnload)
end

function SkillElemConfig:UnRegisterEvents(SkillObject)
  for k, v in pairs(self.EventInstMap) do
    SkillObject:UnregisterEventCallback(k, self, v)
    self.EventInstMap[k] = nil
  end
end

function SkillElemConfig:DoPrepareSkill(SkillObject, SkillComp)
  local Blackboard = RocoSkillBlackboard()
  Blackboard.Caster = self.SeqOwner:GetActor(self.CasterKey)
  local Targets = {}
  for k, v in pairs(self.TargetKeys) do
    table.insert(Targets, self.SeqOwner:GetActor(v))
  end
  Blackboard.Targets = Targets
  local Characters = {}
  for k, v in pairs(self.CharacterKeys) do
    Characters[k] = self.SeqOwner:GetActor(v)
  end
  Blackboard.Characters = Characters
  self:UnRegisterEvents(SkillObject)
  for Name, Evt in pairs(self.Events) do
    self.EventInstMap[Name] = Evt
    SkillObject:RegisterEventCallback(Name, self, Evt)
  end
  if self.PrepareSkillDelegate then
    self.PrepareSkillDelegate(self, SkillObject)
  end
  SkillObject.DynamicData = Blackboard
  SkillObject:RefreshAllEnd()
  self.SkillObject = SkillObject
  self.SkillComp = SkillComp
  return Blackboard
end

function SkillElemConfig:ResolveSkillComp()
  local Caster = self.SeqOwner:GetActor(self.CasterKey)
  if Caster then
    if not Caster.RocoSkill then
      Caster.RocoSkill = Caster:AddComponentByClass(UE4.URocoSkillComponent, false, UE.FTransform(), false)
    end
    if not Caster.RocoFX then
      Caster.RocoFX = Caster:AddComponentByClass(UE4.URocoFXComponent, false, UE.FTransform(), false)
    end
    return Caster.RocoSkill
  end
end

function SkillElemConfig:TryCancel()
  Log.Debug("SkillElemConfig:TryCancel", self.G6SkillPath)
  if self.SkillObject and self.SkillComp and UE4.UObject.IsValid(self.SkillObject) and UE4.UObject.IsValid(self.SkillComp) then
    self.SkillComp:CancelSkill(self.SkillObject, UE4.ESkillActionResult.SkillActionResultSuccessful)
  end
  if self.SkillObject and UE4.UObject.IsValid(self.SkillObject) then
    self:UnRegisterEvents(self.SkillObject)
  end
  self.SkillObject = nil
  self.SkillComp = nil
end

function SkillElemConfig:TryPause()
  if self.SkillObject and UE4.UObject.IsValid(self.SkillObject) then
    self.SkillObject:SetPlayRate(0)
  end
end

function SkillElemConfig:TryResume()
  if self.SkillObject and UE4.UObject.IsValid(self.SkillObject) then
    self.SkillObject:SetPlayRate(1)
  end
end

function SkillElemConfig:MarkCanceled()
  self.SkillObject = nil
  self.SkillComp = nil
end

function SkillElemConfig:HideActor(Key)
  local Actor = self.SeqOwner:GetActor(Key)
  if Actor and UE.UObject.IsValid(Actor) then
    self.SeqOwner:HideActor(Actor)
  end
end

function SkillElemConfig:DestroyActor(Key)
  self.SeqOwner:DestroyActor(Key)
end

function SkillElemConfig:ShowActor(Key)
end

local SkillSeqProxy = Class("SkillSeqProxy")

function SkillSeqProxy:Ctor()
  self.SkillQueue = Queue()
  self.Resources = {}
  self.ResourceMap = {}
  self.ResourceRef = {}
  self.Actors = {}
  self.Requests = {}
  self.DontDestroyFlag = {}
  self.RunningActors = {}
  self.ReplaySeq = Queue()
end

function SkillSeqProxy.CreateSkillElemConfig(CasterKey, G6SkillPath, bAutoPlay)
  return SkillElemConfig(CasterKey, G6SkillPath, bAutoPlay)
end

function SkillSeqProxy:Destroy()
  Log.Debug("SkillSeqProxy:Destroy")
  self.bDestroyed = true
  while self.SkillQueue:Size() > 0 do
    local Elem = self.SkillQueue:Dequeue()
    Elem:Destroy()
  end
  for Key, Request in pairs(self.Requests) do
    NRCResourceManager:UnLoadRes(Request)
    self.Requests[Key] = nil
  end
  for k, v in pairs(self.Actors) do
    if not self.DontDestroyFlag[k] and UE.UObject.IsValid(v) then
      v:K2_DestroyActor()
    end
    self.Actors[k] = nil
  end
  self.ResourceRef = {}
  self.ResourceMap = {}
  self.RunningActors = {}
end

function SkillSeqProxy:AddSkillElemConfig(ElemConf)
  ElemConf:OnBindSeq(self)
  self.SkillQueue:Enqueue(ElemConf)
end

function SkillSeqProxy:AddResourcePaths(Key, Path)
  self.Resources[Key] = Path
end

function SkillSeqProxy:AddActor(Key, Actor)
  self.Actors[Key] = Actor
  self.DontDestroyFlag[Key] = true
end

function SkillSeqProxy:SetFinishDelegate(FinishDelegate)
  self.FinishDelegate = FinishDelegate
end

function SkillSeqProxy:DestroyActor(Key)
  local Actor = self.Actors[Key]
  if Actor and UE.UObject.IsValid(Actor) then
    Actor:K2_DestroyActor()
  end
  self.Actors[Key] = nil
end

function SkillSeqProxy:GetActor(Key, bNoEnsure)
  if not Key then
    return
  end
  local Actor = self.Actors[Key]
  if Actor then
    self.RunningActors[Key] = Actor
    return Actor
  end
  if bNoEnsure then
    return
  end
  local Res = self.ResourceMap[Key]
  if not Res then
    return
  end
  if not UE.UObject.IsValid(Res) then
    Res = UE.UObject.Load(self.Resources[Key])
    self.ResourceMap[Key] = Res
    self.ResourceRef[Key] = UnLua.Ref(Res)
  end
  Actor = UE4Helper.GetCurrentWorld():SpawnActor(Res, UE.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  if Actor then
    Log.Debug("SkillSeqProxy:SpawnActor", Key, Actor:GetFullName())
  else
    Log.Error("SkillSeqProxy:SpawnActor spawn fail")
  end
  self.Actors[Key] = Actor
  self.RunningActors[Key] = Actor
  return self.Actors[Key]
end

function SkillSeqProxy:HideActor(Actor)
  if Actor then
    Actor:Abs_K2_SetActorLocation_WithoutHit(UE.FVector(99999, 0, 0))
  end
end

function SkillSeqProxy:Play(OnFailed)
  assert(not self.bDestroyed)
  local WaitElemCnt = self.SkillQueue:Size()
  local WaitResCnt = -1
  local LoadFinishCnt = 0
  local NeedLoadCnt = 0
  
  local function OnActorLoadFinish(_, Actor)
    LoadFinishCnt = LoadFinishCnt + 1
    Log.Debug("SkillSeqProxy:OnActorLoadFinish", NeedLoadCnt, NeedLoadCnt, Actor and Actor:GetFullName())
    if 0 == WaitElemCnt and 0 == WaitResCnt and LoadFinishCnt == NeedLoadCnt then
      self.RunningActors = {}
      self:InternalPlay()
    end
  end
  
  local function OnElemFinish(Asset)
    Log.Debug("SkillSeqProxy:OnElemFinish", Asset and Asset:GetName(), WaitElemCnt)
    WaitElemCnt = WaitElemCnt - 1
    if 0 == WaitElemCnt and 0 == WaitResCnt and LoadFinishCnt == NeedLoadCnt then
      self.RunningActors = {}
      self:InternalPlay()
    end
  end
  
  local function OnRelativeResFinish(Key, Res)
    Log.Debug("SkillSeqProxy:OnRelativeResFinish", Res and Res:GetName(), WaitResCnt)
    self.Requests[Key] = nil
    if Res then
      self.ResourceMap[Key] = Res
      self.ResourceRef[Key] = UnLua.Ref(Res)
      if not string.StartsWith(Key, "Light") then
        local Actor = self:GetActor(Key)
        self:HideActor(Actor)
        Actor:InitOutSceneAsync(self, OnActorLoadFinish)
      end
    end
    WaitResCnt = WaitResCnt - 1
    if 0 == WaitElemCnt and 0 == WaitResCnt and LoadFinishCnt == NeedLoadCnt then
      self.RunningActors = {}
      self:InternalPlay()
    end
  end
  
  for k, Elem in Queue.pairs(self.SkillQueue) do
    Elem:PrepareLoad(OnElemFinish)
  end
  WaitResCnt = 0
  for Key, Path in pairs(self.Resources) do
    WaitResCnt = WaitResCnt + 1
  end
  for Key, Path in pairs(self.Resources) do
    if not string.StartsWith(Key, "Light") then
      NeedLoadCnt = NeedLoadCnt + 1
    end
    self.Requests[Key] = self:LoadRes(Path, 255, FPartial(OnRelativeResFinish, Key))
  end
  self.DelayTimer = DelayManager:DelaySeconds(10, function()
    self.DelayTimer = nil
    if OnFailed then
      OnFailed()
    end
  end)
end

function SkillSeqProxy:LoadRes(Path, Priority, OnFinish)
  local function OnSuc(_1, _2, Asset)
    OnFinish(Asset)
  end
  
  local function OnFailed()
    OnFinish()
  end
  
  local function OnUnload()
    OnFinish()
  end
  
  return NRCResourceManager:LoadResAsync(self, Path, Priority, 0, OnSuc, OnFailed, nil, OnUnload)
end

function SkillSeqProxy:OnActorLoadFinish(_, Key, Actor)
end

function SkillSeqProxy:InternalPlay(bReplay)
  if self.bDestroyed then
    return
  end
  if self.DelayTimer then
    DelayManager:CancelDelayById(self.DelayTimer)
    self.DelayTimer = nil
  end
  Log.Debug("SkillSeqProxy:InternalPlay")
  local Seq = self.SkillQueue
  if bReplay then
    Seq = self.ReplaySeq
  end
  while Seq:Size() > 0 do
    local Elem = Seq:First()
    local SkillComp = Elem:ResolveSkillComp()
    if Elem.G6SkillClass and SkillComp then
      self:InternalPlayElem(Elem, SkillComp, bReplay)
      return true
    end
    Seq:Dequeue()
  end
  if not bReplay then
    self:OnSeqFinish()
  end
  return false
end

function SkillSeqProxy:InternalPlayElem(Elem, SkillComp, bReplay)
  Log.Debug("SkillSeqProxy:InternalPlayElem", Elem.G6SkillPath, SkillComp)
  local G6SkillClass = Elem.G6SkillClass
  local SkillObject = SkillComp:FindOrAddSkillObj(G6SkillClass)
  self:OnInternalPrepareSkill(SkillObject, Elem, SkillComp)
  SkillObject:RegisterEventCallback("End", self, function(event, skill)
    return self:OnInternalElemFinish(event, skill, Elem, bReplay)
  end)
  SkillObject:RegisterEventCallback("Interrupt", self, function(event, skill)
    return self:OnInternalElemFinish(event, skill, Elem, bReplay)
  end)
  SkillObject:SendLuaEvent("PreStart")
  local Result = SkillComp:LoadAndPlaySkill(SkillObject)
  if Result ~= UE.ESkillStartResult.Success then
    SkillObject:SendLuaEvent("End")
  end
end

function SkillSeqProxy:OnInternalPrepareSkill(SkillObject, Elem, SkillComp)
  self.RunningActors = {}
  Elem:DoPrepareSkill(SkillObject, SkillComp)
  Elem:TryResume()
end

function SkillSeqProxy:OnInternalElemFinish(Name, SkillObject, Elem, bReplay)
  Log.Debug("SkillSeqProxy:OnInternalElemFinish", Name, Elem.G6SkillPath, SkillObject)
  Elem:MarkCanceled()
  if bReplay then
    if self.ReplaySeq:First() == Elem then
      self.ReplaySeq:Dequeue()
      self:InternalPlay(true)
    end
  elseif self.SkillQueue:Size() > 0 and self.SkillQueue:First() == Elem then
    self.SkillQueue:Dequeue()
    if self.SkillQueue:Size() > 0 and self.SkillQueue:First().bAutoPlay then
      self:InternalPlay()
    end
  end
end

function SkillSeqProxy:StopElemConfigSeq()
  for k, v in Queue.pairs(self.ReplaySeq) do
    v:TryCancel()
  end
  self.ReplaySeq:Clear()
end

function SkillSeqProxy:PauseElemConfigSeq()
  for k, v in Queue.pairs(self.ReplaySeq) do
    v:TryPause()
  end
end

function SkillSeqProxy:ReplayElemConfigSeq(ElemList)
  self:StopElemConfigSeq()
  for i, e in ipairs(ElemList) do
    self.ReplaySeq:Enqueue(e)
  end
  self:InternalPlay(true)
end

function SkillSeqProxy:OnSeqFinish()
  Log.Debug("SkillSeqProxy:OnSeqFinish")
  if self.FinishDelegate then
    self.FinishDelegate()
  end
end

return SkillSeqProxy
