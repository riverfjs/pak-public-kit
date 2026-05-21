local BattleComponent = require("NewRoco.Modules.Core.Battle.Entity.BattleComponent")
local Enum = require("Data.Config.Enum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local NRCUtils = require("Core.NRCUtils")
local Base = BattleComponent
local OnLookerCrowdShowComponent = Base:Extend("OnLookerCrowdShowComponent")
OnLookerCrowdShowComponent.EmotionType = {
  RARE = 1,
  PRAISE = 2,
  FEAR = 3,
  AFFIRM = 4
}
local cheerAnimSequence = {
  {materialAnimValue = 1, timeSpan = 0.5},
  {materialAnimValue = 0, timeSpan = 0.3},
  {materialAnimValue = 1, timeSpan = 0.5},
  {materialAnimValue = 0, timeSpan = 0.4},
  {materialAnimValue = 1, timeSpan = 0.9},
  {materialAnimValue = 0, timeSpan = 0.4}
}

function OnLookerCrowdShowComponent:Ctor(owner)
  Base.Ctor(self)
  self.owner = owner
  self.emotionsContextWaitingToPlay = {}
end

function OnLookerCrowdShowComponent:Enable()
  self:StartPlayIdleAnim()
end

function OnLookerCrowdShowComponent:Disable()
  self.emotionsContextWaitingToPlay = {}
  self.dynamicAnimMaterial = nil
  if self.playEmotionContext then
    self:OnPlayEmotionCompleted(false, "OnLookerCrowdShowComponent disable")
  end
  if self.playIdleAnimationContext then
    self:StopIdleAnim()
  end
  if self.playCheerAnimationContext then
    self:StopCheerAnim()
  end
end

function OnLookerCrowdShowComponent:PlayEmotion(emotionType, callbackOwner, callback)
  if self:IsPlaying() then
    local context = {
      emotionType = emotionType,
      callbackOwner = callbackOwner,
      callback = callback
    }
    table.insert(self.emotionsContextWaitingToPlay, context)
    return
  end
  local emotionConfig = _G.DataConfigManager:GetEmotionConf(emotionType)
  local skillPath = emotionConfig and emotionConfig.action_res
  skillPath = skillPath and NRCUtils.FormatBlueprintAssetPath(skillPath)
  self.playEmotionContext = {
    emotionType = emotionType,
    callbackOwner = callbackOwner,
    callback = callback,
    skillPath = skillPath
  }
  if not skillPath then
    self:OnPlayEmotionCompleted(false, string.format("skill path is nil, maybe emotion type is not valid", emotionType))
    return
  end
  local random_deviation = 1500
  local random_deviation_seconds = math.rand(1, random_deviation) / 1000
  self.playEmotionContext.delayPlayEmotionDelayId = _G.DelayManager:DelaySeconds(random_deviation_seconds, self.OnDelayPlayEmotion, self)
end

function OnLookerCrowdShowComponent:OnDelayPlayEmotion()
  if not self.playEmotionContext then
    Log.Warning("OnLookerCrowdShowComponent:OnDelayPlayEmotion playEmotionContext is nil")
    return
  end
  self:StartPlayCheerAnim()
  local skillPath = self.playEmotionContext.skillPath
  local asset = _G.BattleResourceManager:GetCacheAssetDirect(skillPath, true)
  if UE.UObject.IsValid(asset) then
    self:OnLoadEmotionSkillCompleted(true, asset)
  else
    _G.BattleResourceManager:LoadResAsyncThunk(self, skillPath, nil, nil, nil, _G.PriorityEnum.Passive_Battle_NPC, self.OnLoadEmotionSkillCompleted)
  end
end

function OnLookerCrowdShowComponent:IsPlaying()
  return self.playEmotionContext ~= nil
end

function OnLookerCrowdShowComponent:OnLoadEmotionSkillCompleted(ok, asset)
  if not ok then
    local errorMessage = tostring(asset)
    self:OnPlayEmotionCompleted(false, string.format("failed to load res %s", errorMessage))
    return
  end
  local skillClass = asset
  self:PlayEmotionSkill(skillClass)
end

function OnLookerCrowdShowComponent:PlayEmotionSkill(skillClass)
  if not UE.UObject.IsValid(skillClass) then
    self:OnPlayEmotionCompleted(false, "skillClass is not valid")
    return
  end
  local ownerModel = self:GetOwnerView()
  if not UE.UObject.IsValid(ownerModel) then
    self:OnPlayEmotionCompleted(false, "ownerModel is not valid")
    return
  end
  local emotionCaster = ownerModel.EmotionCaster:GetChildActor()
  local casterModel = emotionCaster
  if not UE.UObject.IsValid(casterModel) then
    self:OnPlayEmotionCompleted(false, "casterModel is not valid")
    return
  end
  local SkillComp = self:GetSkillComponent()
  if not UE.UObject.IsValid(SkillComp) then
    self:OnPlayEmotionCompleted(false, "SkillComp is not valid")
    return
  end
  local skillObject = SkillComp:FindOrAddSkillObj(skillClass)
  if not UE.UObject.IsValid(skillObject) then
    self:OnPlayEmotionCompleted(false, "Skill Object is not valid")
    return
  end
  skillObject:SetCaster(casterModel)
  skillObject:SetPassive(true)
  local blackboard = skillObject:GetBlackboard()
  if UE.UObject.IsValid(blackboard) then
    local directionValue = "Left"
    if ownerModel.EmotionDirection then
      directionValue = ownerModel.EmotionDirection
    end
    blackboard:SetValueAsString("Direction", directionValue)
  end
  local playSkillResult = SkillComp:LoadAndPlaySkill(skillObject)
  local skillLength = skillObject:GetLength()
  if playSkillResult == UE.ESkillStartResult.Success then
    Log.Debug("OnLookerCrowdShowComponent:OnLookerCrowdShowComponent Start", self.owner and self.owner.name)
    self.playEmotionContext.skillObject = skillObject
    self.playEmotionContext.skillTimeOutDelayId = _G.DelayManager:DelaySeconds(skillLength * 2, self.OnSkillTimeout, self)
    skillObject:RegisterEventCallback("End", self, self.OnSkillComplete)
    skillObject:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
    skillObject:RegisterEventCallback("Interrupt", self, self.OnSkillInterrupted)
  else
    self:OnPlayEmotionCompleted(false, "skill play failed")
  end
end

function OnLookerCrowdShowComponent:OnSkillInterrupted()
  self:OnPlayEmotionCompleted(false, "skill interrupt")
end

function OnLookerCrowdShowComponent:OnSkillComplete()
  self:OnPlayEmotionCompleted(true)
end

function OnLookerCrowdShowComponent:OnSkillTimeout()
  self:OnPlayEmotionCompleted(false, "skill time out")
end

function OnLookerCrowdShowComponent:OnPlayEmotionCompleted(ok, errorMessage)
  if not self.playEmotionContext then
    Log.Warning("OnLookerCrowdShowComponent:OnPlayEmotionCompleted playEmotionContext is nil")
    return
  end
  do
    local skillTimeOutDelayId = self.playEmotionContext.skillTimeOutDelayId
    if skillTimeOutDelayId then
      _G.DelayManager:CancelDelayById(skillTimeOutDelayId)
    end
    local skillObject = self.playEmotionContext.skillObject
    if skillObject then
      skillObject:UnregisterEventCallback("End", self, self.OnSkillComplete)
      skillObject:UnregisterEventCallback("PreEnd", self, self.OnSkillComplete)
      skillObject:UnregisterEventCallback("Interrupt", self, self.OnSkillInterrupted)
    end
  end
  local callbackOwner = self.playEmotionContext.callbackOwner
  local callback = self.playEmotionContext.callback
  self.playEmotionContext = nil
  if ok then
    tcall(callbackOwner, callback, true)
  else
    tcall(callbackOwner, callback, false, errorMessage)
  end
  if #self.emotionsContextWaitingToPlay > 0 then
    local firstContext = self.emotionsContextWaitingToPlay[1]
    table.remove(self.emotionsContextWaitingToPlay, 1)
    self:PlayEmotion(firstContext.emotionType, firstContext.callbackOwner, firstContext.callback)
  end
end

function OnLookerCrowdShowComponent:GetSkillComponent()
  local View = self:GetOwnerView()
  if not UE.UObject.IsValid(View) then
    return nil
  end
  return View.Skill
end

function OnLookerCrowdShowComponent:GetOwnerView()
  local model
  if self.owner then
    model = self.owner.model
  end
  if UE.UObject.IsValid(model) then
    return model
  end
  return nil
end

function OnLookerCrowdShowComponent:SetAnimMaterialValue(newValue)
  if not UE.UObject.IsValid(self.dynamicAnimMaterial) then
    local ownerView = self:GetOwnerView()
    local staticMeshComponent = ownerView and ownerView.NRCStaticMesh
    if staticMeshComponent then
      local sourceMaterial = staticMeshComponent:GetMaterial(0)
      self.dynamicAnimMaterial = staticMeshComponent:CreateDynamicMaterialInstance(0, sourceMaterial)
    end
  end
  if UE.UObject.IsValid(self.dynamicAnimMaterial) then
    self.dynamicAnimMaterial:SetScalarParameterValue("Anim", newValue)
  end
end

function OnLookerCrowdShowComponent:StartPlayIdleAnim()
  if self.playIdleAnimationContext then
    Log.Error("OnLookerCrowdShowComponent:StartPlayIdleAnim another playIdleAnimationContext is playing")
    return
  end
  local random_deviation_seconds = math.rand(500, 1000) / 1000
  local animSequence = {
    {
      meshRelativeOffset = {
        0,
        0,
        0
      },
      timeSpan = random_deviation_seconds
    },
    {
      meshRelativeOffset = self:GetRandomOffset(),
      timeSpan = 0.5
    },
    {
      meshRelativeOffset = self:GetRandomOffset(),
      timeSpan = 0.5
    },
    {
      meshRelativeOffset = self:GetRandomOffset(),
      timeSpan = 0.5
    },
    {
      meshRelativeOffset = {
        0,
        0,
        0
      },
      timeSpan = 0.5
    }
  }
  self.playIdleAnimationContext = {
    currentSequenceIndex = 0,
    animSequence = animSequence,
    onAnimCompleted = self.OnIdleAnimCompleted
  }
  self:OnSwitchAnimTimeout(self.playIdleAnimationContext)
end

function OnLookerCrowdShowComponent:OnIdleAnimCompleted()
  if not self.playIdleAnimationContext then
    Log.Error("OnLookerCrowdShowComponent:OnIdleAnimCompleted playIdleAnimationContext is nil")
    return
  end
  self:StopIdleAnim()
  if self.enable then
    self:StartPlayIdleAnim()
  end
end

function OnLookerCrowdShowComponent:StopIdleAnim()
  if not self.playIdleAnimationContext then
    Log.Error("OnLookerCrowdShowComponent:StopPlayIdleAnim playIdleAnimationContext is nil")
    return
  end
  local delaySwitchId = self.playIdleAnimationContext.delaySwitchId
  if delaySwitchId then
    _G.DelayManager:CancelDelayById(delaySwitchId)
  end
  self.playIdleAnimationContext = nil
end

function OnLookerCrowdShowComponent:StartPlayCheerAnim()
  if self.playCheerAnimationContext then
    self:StopCheerAnim()
    return
  end
  self.playCheerAnimationContext = {
    currentSequenceIndex = 0,
    animSequence = cheerAnimSequence,
    onAnimCompleted = self.OnCheerAnimCompleted
  }
  self:OnSwitchAnimTimeout(self.playCheerAnimationContext)
end

function OnLookerCrowdShowComponent:OnCheerAnimCompleted()
  if not self.playCheerAnimationContext then
    Log.Error("OnLookerCrowdShowComponent:OnCheerAnimCompleted playCheerAnimationContext is nil")
    return
  end
  self:StopCheerAnim()
end

function OnLookerCrowdShowComponent:StopCheerAnim()
  if not self.playCheerAnimationContext then
    Log.Error("OnLookerCrowdShowComponent:StopCheerAnim playCheerAnimationContext is nil")
    return
  end
  local delaySwitchId = self.playCheerAnimationContext.delaySwitchId
  if delaySwitchId then
    _G.DelayManager:CancelDelayById(delaySwitchId)
  end
  self.playCheerAnimationContext = nil
end

function OnLookerCrowdShowComponent:GetRandomOffset()
  local v = math.rand(-BattleConst.BattleCrowdNpc.RandomOffsetRangeH, BattleConst.BattleCrowdNpc.RandomOffsetRangeH)
  local h = math.rand(-BattleConst.BattleCrowdNpc.RandomOffsetRangeV, BattleConst.BattleCrowdNpc.RandomOffsetRangeV)
  return {
    0,
    v,
    h
  }
end

function OnLookerCrowdShowComponent:OnSwitchAnimTimeout(context)
  if not context then
    Log.Error("OnLookerCrowdShowComponent:OnSwitchAnimTimeout context is nil")
    return
  end
  local currentSequenceIndex = context.currentSequenceIndex
  currentSequenceIndex = currentSequenceIndex + 1
  context.currentSequenceIndex = currentSequenceIndex
  if currentSequenceIndex > #context.animSequence then
    tcall(self, context.onAnimCompleted)
    return
  end
  local frameData = context.animSequence[currentSequenceIndex]
  self:UpdateWithFrameData(frameData)
  local timeSpan = frameData.timeSpan
  if timeSpan <= 0 then
    timeSpan = 0.05
  end
  local delaySwitchId = _G.DelayManager:DelaySeconds(timeSpan, self.OnSwitchAnimTimeout, self, context)
  context.delaySwitchId = delaySwitchId
end

function OnLookerCrowdShowComponent:UpdateWithFrameData(data)
  if data.materialAnimValue then
    self:SetAnimMaterialValue(data.materialAnimValue)
  end
  if data.meshRelativeOffset then
    local x = data.meshRelativeOffset[1] or 0
    local y = data.meshRelativeOffset[2] or 0
    local z = data.meshRelativeOffset[3] or 0
    local ownerView = self:GetOwnerView()
    local staticMeshComponent = ownerView and ownerView.NRCStaticMesh
    if staticMeshComponent then
      local newRelativePosition = UE4.FVector(x, y, z)
      staticMeshComponent:K2_SetRelativeLocation(newRelativePosition, false, nil, false)
    end
  end
end

function OnLookerCrowdShowComponent:Destroy()
  Base.Destroy(self)
  local playIdleAnimationContext = self.playIdleAnimationContext
  local delaySwitchId = playIdleAnimationContext and playIdleAnimationContext.delaySwitchId
  if delaySwitchId then
    _G.DelayManager:CancelDelayById(delaySwitchId)
  end
  local playCheerAnimationContext = self.playCheerAnimationContext
  delaySwitchId = playCheerAnimationContext and playCheerAnimationContext.delaySwitchId
  if delaySwitchId then
    _G.DelayManager:CancelDelayById(delaySwitchId)
  end
  local playEmotionContext = self.playEmotionContext
  delaySwitchId = playEmotionContext and playEmotionContext.delayPlayEmotionDelayId
  if delaySwitchId then
    _G.DelayManager:CancelDelayById(delaySwitchId)
  end
end

return OnLookerCrowdShowComponent
