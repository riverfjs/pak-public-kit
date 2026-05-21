local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionPlaySkill = Base:Extend("LuaActionPlaySkill")

function LuaActionPlaySkill:Ctor(LuaBTNodeBase)
  Base.Ctor(self, LuaBTNodeBase)
  self.req = nil
end

function LuaActionPlaySkill:OnStart(AIController, ...)
  local owner = AIController
  self.owner = owner
  self.interrupted = false
  self.isPassive = false
  local skillId = self.SkillId:GetValue(owner)
  local skillConf = _G.DataConfigManager:GetNrcAiPerformSkillConf(skillId, true)
  if not skillConf then
    Log.PrintScreenMsg("[LuaActionPlaySkill] NRC_AI_PERFORM_SKILL_CONF \230\137\190\228\184\141\229\136\176\233\133\141\231\189\174 %s, id=%d", owner.Npc.config.name or "", skillId or 0)
    return self:Finish(false)
  end
  self.isPassive = skillConf.parallel_playback or false
  local InterruptOther = self.InterruptOther and self.InterruptOther:GetValue(owner)
  local interrupt_when_lock = skillConf.interrupt_when_stop_ai or false
  self.interrupt_when_lock = interrupt_when_lock
  if interrupt_when_lock then
    local AIComp = owner.Npc.AIComponent
    AIComp:RegisterForceLockChanged(self, self.OnAILockChanged)
  end
  self:PlaySkillByPath(owner.Npc, skillConf.skill_ref, InterruptOther)
end

function LuaActionPlaySkill:OnInterrupt(owner, Finalizing)
  self.interrupted = true
  self._npc = nil
  self:StopSkill(owner)
  self:CleanUp(false)
  self:ReleaseRes()
end

function LuaActionPlaySkill:PlaySkillByPath(npc, path, interrupt, load_priority)
  if not (npc and npc.viewObj) or npc.isDestroy then
    self:CleanUp(false)
    self:ReleaseRes()
    self:Finish(false)
    return
  end
  path = _G.NRCUtils.FormatBlueprintAssetPath(path)
  self._npc = npc
  self._interruptSkill = interrupt
  self.req = _G.NRCResourceManager:LoadResAsync(self, path, load_priority or _G.PriorityEnum.Passive_World_AI_SkillRes, 10, self.SkillLoadSucc, self.SkillLoadFail)
end

function LuaActionPlaySkill.CheckValid(npc)
  return npc and not npc.isDestroy and npc.AIComponent and npc.AIComponent:IsActive()
end

local LocalSpawnTransformObj = UE.FTransform()
local LocalTargetClass = UE.ANPCSimpleSkillTarget

function LuaActionPlaySkill:SkillLoadSucc(req, skillClass)
  local npc = self._npc
  local interrupt = self._interruptSkill
  self._npc = nil
  self._interruptSkill = nil
  if not self.CheckValid(npc) then
    self:CleanUp(false)
    self:ReleaseRes()
    self:Finish(false)
    return
  end
  local view = npc.viewObj
  if view and view.resourceLoaded then
    local skillComp = view:GetComponentByClass(UE4.URocoSkillComponent)
    if skillComp then
      if interrupt then
        skillComp:StopCurrentSkill()
      end
      view.RocoSkill:ClearNotworkingSkillObj()
      local skillObj = view.RocoSkill:FindOrAddSkillObj(skillClass)
      if skillObj and skillObj.SetCaster then
        if skillObj:IsWorking() then
          skillObj:ClearDelegates()
          skillComp:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
        end
        skillObj:SetPassive(self.isPassive)
        skillObj:SetCaster(view)
        skillObj:SetPriority(PriorityEnum.Passive_World_AI_SkillRes)
        skillObj:SetJumpErrorLog()
        if UE.UObject.IsValid(self.owner) then
          if self.UseTarget and self.UseTarget:GetValue(self.owner) then
            local targetCharacter = self.SkillTarget and self.SkillTarget:GetValue(self.owner)
            local targetView = targetCharacter and targetCharacter.viewObj
            if targetView then
              skillObj:SetTargets({targetView})
              self.targetCharacter = targetCharacter
              self.targetCharacter:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnTargetDestroy)
            end
          elseif self.UseSpecificPos and self.UseSpecificPos:GetValue(self.owner) then
            local targetPos = self.SpecificPos and self.SpecificPos:GetValue(self.owner)
            if targetPos then
              LocalSpawnTransformObj.Translation = targetPos
              local TargetObj = view:GetWorld():Abs_SpawnActor(LocalTargetClass, LocalSpawnTransformObj, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
              skillObj:SetTargets({TargetObj})
              skillObj:GetBlackboard():SetValueAsObject("AI_TargetObj", TargetObj)
            end
          end
        end
        skillObj:ClearDelegates()
        skillObj:RegisterEventCallback("End", self, self.OnSkillEnd):RegisterEventCallback("StartFailed", self, self.PlayFailed):RegisterEventCallback("PreEnd", self, self.OnSkillEnd):RegisterEventCallback("Interrupt", self, self.OnSkillEnd):RegisterEventCallback("ActivateFailed", self, self.PlayFailed)
        local Result = skillComp:LoadAndPlaySkill(skillObj)
        if Result == UE.ESkillStartResult.Success then
          self.skillObj = skillObj
          self.skillObj_ref = UnLua.Ref(skillObj)
          return
        end
      end
    end
  end
  self:PlayFailed()
end

function LuaActionPlaySkill:PlayFailed()
  self:CleanUp(false)
  self:ReleaseRes()
  self:Finish(false)
end

function LuaActionPlaySkill:SkillLoadFail(req, msg)
  Log.Error("LuaActionPlaySkill failed", msg)
  self:CleanUp(false)
  self:Finish(false)
end

function LuaActionPlaySkill:StopSkill(owner)
  if not self.skillObj or not UE.UObject.IsValid(self.skillObj) then
    self.skillObj = nil
    self.skillObj_ref = nil
    return
  end
  local skillObj = self.skillObj
  self.skillObj = nil
  if UE.UObject.IsValid(self.skillObj_ref) then
    UnLua.Unref(self.skillObj_ref)
    self.skillObj_ref = nil
  end
  owner = owner or self.owner
  if owner then
    local view = owner.Npc.viewObj
    if view and UE.UObject.IsValid(view) then
      local rocoSkill = view.RocoSkill
      if rocoSkill then
        rocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
    end
  end
end

function LuaActionPlaySkill:OnSkillEnd(skillObj)
  self:CleanUp(false)
  self:ReleaseRes()
  if not self.interrupted then
    self.interrupted = true
    self:Finish(true)
  end
end

function LuaActionPlaySkill:OnTargetDestroy()
  if self.targetCharacter then
    self:StopSkill()
  end
end

function LuaActionPlaySkill:OnAILockChanged(lock)
  if lock then
    self:StopSkill()
  end
end

function LuaActionPlaySkill:CleanUp(stopMontage)
  if self.owner then
    local Npc = self.owner.Npc
    if Npc then
      if stopMontage and Npc.AIComponent and not Npc.AIComponent:IsLocked() then
        Npc:StopAllMontage(0.1)
      end
      if Npc.AIComponent and self.interrupt_when_lock then
        Npc.AIComponent:UnRegisterForceLockChanged(self, self.OnAILockChanged)
      end
    end
    self.owner = nil
  end
  if self.targetCharacter then
    self.targetCharacter:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnTargetDestroy)
    self.targetCharacter = nil
  end
  self.skillObj = nil
  if UE.UObject.IsValid(self.skillObj_ref) then
    UnLua.Unref(self.skillObj_ref)
  end
  self.skillObj_ref = nil
  self._npc = nil
  self._interruptSkill = nil
end

function LuaActionPlaySkill:ReleaseRes()
  if self.req then
    local req = self.req
    self.req = nil
    _G.NRCResourceManager:UnLoadRes(req)
  end
end

return LuaActionPlaySkill
