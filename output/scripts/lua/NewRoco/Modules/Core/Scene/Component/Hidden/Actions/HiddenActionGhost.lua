local Base = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenActionBase")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local HiddenPluginFx = require("NewRoco.Modules.Core.Scene.Component.Hidden.Actions.HiddenPluginFx")
local SkillPath_GHO_Idle = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Hide/Pet_Hide_Gho_Idle.Pet_Hide_Gho_Idle_C'"
local SkillPath_GHO_Alpha = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Hide/Pet_Hide_Gho_Alpha.Pet_Hide_Gho_Alpha_C'"
local SkillPath_GHO_Stop = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Hide/Pet_Hide_Gho_Stop.Pet_Hide_Gho_Stop_C'"
local SkillPath_GHO_End = "/Game/ArtRes/Effects/G6Skill/Pet_Hide/Pet_Hide_Gho_End"
local FxPath = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Res/Scene/hide/NR_Hide_Gho.NR_Hide_Gho'"
local HiddenActionGhost = Base:Extend("HiddenActionGhost")
HiddenActionGhost.GhostState = {
  Idle = 1,
  Alpha = 2,
  Stop = 3,
  End = 99
}
HiddenActionGhost.GhoState2SkillPath = {
  [HiddenActionGhost.GhostState.Idle] = SkillPath_GHO_Idle,
  [HiddenActionGhost.GhostState.Alpha] = SkillPath_GHO_Alpha,
  [HiddenActionGhost.GhostState.Stop] = SkillPath_GHO_Stop,
  [HiddenActionGhost.GhostState.End] = SkillPath_GHO_End
}
HiddenActionGhost.GhoState2EnableFx = {
  [HiddenActionGhost.GhostState.Idle] = false,
  [HiddenActionGhost.GhostState.Alpha] = true,
  [HiddenActionGhost.GhostState.Stop] = false,
  [HiddenActionGhost.GhostState.End] = false
}
HiddenActionGhost.GhoState2DisableCollision = {
  [HiddenActionGhost.GhostState.Idle] = false,
  [HiddenActionGhost.GhostState.Alpha] = true,
  [HiddenActionGhost.GhostState.Stop] = true,
  [HiddenActionGhost.GhostState.End] = true
}

function HiddenActionGhost:Ctor()
  self.fxPlug = HiddenPluginFx(FxPath, true, true, PriorityEnum.Passive_World_NPC_Hidden_Other)
  self.skillObj = nil
  self.skillObjRef = nil
end

function HiddenActionGhost:Init(comp)
  Base.Init(self, comp)
  self.fxPlug:Init(comp.owner)
  self.enableTick = false
  self.sub_state = self.GhostState.Idle
  self.SkillRequests = {}
  self.performingSwitch = false
  self.pendingState = nil
  self.moveDebounceCount = 0
end

function HiddenActionGhost:Release()
  self:SetTickEnabled(false)
  self.pendingState = nil
  self:ReleaseSkillReq()
  self.fxPlug:Release()
  self.skillObj = nil
  self.skillObjRef = nil
  Base.Release(self)
end

function HiddenActionGhost:OnHidden()
  self:SwitchState(self.GhostState.Alpha)
  self.comp:EnterHidden(AIDefines.ActionResult.Success)
  PetMutationUtils.DoMutationSpecific(self.owner.viewObj, UE.EPetMaterialDifferenceType.NiZongDiff)
  NRCAudioManager:PlaySound3DWithActorAuto(4059, self.owner.viewObj, "HiddenActionGhost:OnHidden")
end

function HiddenActionGhost:AssureHidden(imme)
  if self.sub_state == self.GhostState.Idle then
    self:SwitchState(self.GhostState.Alpha)
    PetMutationUtils.DoMutationSpecific(self.owner.viewObj, UE.EPetMaterialDifferenceType.NiZongDiff)
  end
end

function HiddenActionGhost:OnUnhidden()
  self:SwitchState(self.GhostState.Idle)
  self.comp:FinalizeHidden(AIDefines.ActionResult.Success)
  PetMutationUtils.DoMutationSpecific(self.owner.viewObj, UE.EPetMaterialDifferenceType.Default)
end

function HiddenActionGhost:AssureUnhidden(imme)
  if self.owner.isDestroy then
    return
  end
  self:SwitchState(self.GhostState.Idle)
  PetMutationUtils.DoMutationSpecific(self.owner.viewObj, UE.EPetMaterialDifferenceType.Default)
end

function HiddenActionGhost:EnablePinToGround()
  return false
end

function HiddenActionGhost:OnInitialHide()
  if self.sub_state ~= self.GhostState.Idle then
    self:SetTickEnabled(true)
  end
end

function HiddenActionGhost:SwitchState(newState)
  if self.performingSwitch then
    if newState == self.GhostState.Idle then
      self.pendingState = nil
      self.performingSwitch = false
      self.sub_state = newState
      self:ReleaseSkillReq()
      if self.sub_state == newState then
        self:SetTickEnabled(false)
      end
      return
    else
      self.pendingState = newState
      return
    end
  end
  if newState == self.GhostState.Idle then
    self:SetTickEnabled(false)
  else
    self:SetTickEnabled(true)
  end
  if self.sub_state == newState then
    return
  end
  self.sub_state = newState
  if self.GhoState2EnableFx[newState] then
    self.fxPlug:Show()
  else
    self.fxPlug:UnShow()
  end
  self.owner:SetCollisionDisable(self.GhoState2DisableCollision[newState], 4)
  self.performingSwitch = true
  self.SkillRequests[newState] = _G.NRCResourceManager:LoadResAsync(self, self.GhoState2SkillPath[newState], PriorityEnum.Passive_World_NPC_Hidden_Other, 10, self.SwitchStateLoadSucc, self.SwitchStateLoadFail)
end

function HiddenActionGhost:SwitchStateLoadSucc(req, skillClass)
  req.ref = skillClass and UnLua.Ref(skillClass)
  if not self.owner then
    self:ReleaseSkillReq()
    return
  end
  local Model = self.owner.viewObj
  if Model and Model.RocoSkill then
    local RocoSkill = Model.RocoSkill
    local skillObj = RocoSkill:FindOrAddSkillObj(skillClass)
    skillObj:SetCaster(Model)
    skillObj:SetTargets({Model})
    skillObj:SetPassive(true)
    skillObj:ClearDelegates()
    skillObj:RegisterEventCallback("End", self, self.SkillEnd)
    skillObj:RegisterEventCallback("PreEnd", self, self.SkillEnd)
    skillObj:RegisterEventCallback("Interrupt", self, self.SkillEnd)
    local result = RocoSkill:PlaySkill(skillObj)
    if result ~= UE.ESkillStartResult.Success then
      self:SkillEnd()
    else
      self.skillObj = skillObj
      self.skillObjRef = UnLua.Ref(skillObj)
    end
  else
    self:SkillEnd()
  end
end

function HiddenActionGhost:SwitchStateLoadFail(req, errMsg)
  self.performingSwitch = false
  if self.pendingState ~= nil then
    local pending = self.pendingState
    self.pendingState = nil
    self:SwitchState(pending)
  end
end

function HiddenActionGhost:SkillEnd()
  if not self.performingSwitch then
    return
  end
  self.skillObj = nil
  self.skillObjRef = nil
  self:ReleaseSkillReq(self.sub_state)
  self.performingSwitch = false
  if nil ~= self.pendingState then
    local pending = self.pendingState
    self.pendingState = nil
    self:SwitchState(pending)
  end
end

function HiddenActionGhost:OnTick(deltaTime)
  if self.sub_state == self.GhostState.Idle or self.owner == nil then
    self:SetTickEnabled(false)
  else
    local Model = self.owner.viewObj
    if not Model or not Model:IsValidLowLevel() then
      self:SetTickEnabled(false)
      self.ActorMovement = nil
      return
    end
    local bIsMoving = false
    local ActorMovement = Model:GetMovementComponent()
    if ActorMovement then
      local sampledMove = ActorMovement.Velocity:Size() > 10
      if sampledMove then
        if self.moveDebounceCount < 0.18 then
          self.moveDebounceCount = self.moveDebounceCount + deltaTime
        end
      elseif self.moveDebounceCount > 0 then
        self.moveDebounceCount = self.moveDebounceCount - deltaTime
      end
      bIsMoving = self.moveDebounceCount > 0.09
    end
    if self.sub_state == self.GhostState.Alpha then
      if not bIsMoving then
        self:SwitchState(self.GhostState.Stop)
      end
    elseif self.sub_state == self.GhostState.Stop and bIsMoving then
      self:SwitchState(self.GhostState.Alpha)
    end
  end
end

function HiddenActionGhost:ReleaseSkillReq(spec)
  local Model = self.owner and self.owner.viewObj
  if Model and Model.RocoSkill and UE.UObject.IsValid(self.skillObj) then
    Model.RocoSkill:CancelSkill(self.skillObj, UE.ESkillActionResult.SkillActionResultSuccessful)
  end
  self.skillObj = nil
  self.skillObjRef = nil
  if spec then
    local req = self.SkillRequests[spec]
    if nil == req then
      return
    end
    req.ref = nil
    _G.NRCResourceManager:UnLoadRes(req)
    self.SkillRequests[spec] = nil
  else
    for _, req in pairs(self.SkillRequests) do
      req.ref = nil
      _G.NRCResourceManager:UnLoadRes(req)
    end
    self.SkillRequests = {}
  end
end

function HiddenActionGhost:SetTickEnabled(enable)
  if self.enableTick ~= enable then
    if enable then
      UpdateManager:Register(self, true)
    else
      UpdateManager:UnRegister(self)
    end
    self.enableTick = enable
  end
end

return HiddenActionGhost
