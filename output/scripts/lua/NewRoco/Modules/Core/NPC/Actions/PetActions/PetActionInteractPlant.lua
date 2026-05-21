local Base = require("NewRoco.Modules.Core.NPC.Actions.PetActionBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local PetTypeSkillMap = {
  [Enum.SkillDamType.SDT_WATER] = "G6_Home_Pet_JiaoShui",
  [Enum.SkillDamType.SDT_GRASS] = "G6_Home_Pet_ShiFei"
}
local ActionType2PetType = {
  [Enum.ActionType.ACT_HOME_PLANT_PET_WATER] = Enum.SkillDamType.SDT_WATER,
  [Enum.ActionType.ACT_HOME_PLANT_PET_MANURE] = Enum.SkillDamType.SDT_GRASS
}
local OptionType2PetTypeMap = {
  [FarmModuleEnum.OptionType.Watering] = Enum.SkillDamType.SDT_WATER,
  [FarmModuleEnum.OptionType.Fertilizing] = Enum.SkillDamType.SDT_GRASS
}
local PetActionInteractPlant = Base:Extend("PetActionInteractPlant")

function PetActionInteractPlant:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.InteractType = nil
end

function PetActionInteractPlant:GetRangeType()
  return _G.Enum.PetReleaseRange.PRR_FAR
end

function PetActionInteractPlant:GetLookAtType()
  return _G.Enum.PetReleaseLookAt.PRLA_TARGET_NPC
end

function PetActionInteractPlant:CheckEnvironment()
  if not Base.CheckEnvironment(self) then
    return false
  end
  if self.Config.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_WATER then
    return FarmUtils.IsLandWateringAvailable(self:GetOwnerNPC():GetFarmLandId())
  elseif self.Config.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_MANURE then
    return FarmUtils.IsLandFertilizingAvailable(self:GetOwnerNPC():GetFarmLandId())
  end
  return false
end

function PetActionInteractPlant:Execute(Runner)
  if self:PreExecuteCheck(Runner) then
    Base.Execute(self, Runner)
  else
    self:ForceFreeAI(Runner)
    self.Runner = Runner
    self:Finish(false)
  end
end

function PetActionInteractPlant:OnExecute()
  local PetView = self:GetRunnerView()
  local FarmLandNpc = FarmUtils.GetLandNPC(self:GetOwnerNPC():GetFarmLandId())
  local TargetView = FarmLandNpc and FarmLandNpc:GetViewObject()
  local SkillComp = self:GetRunnerSkillComponent()
  local SkillPath = string.format("%s/%s", "/Game/ArtRes/Effects/G6Skill/Home", PetTypeSkillMap[self.InteractType])
  local Skill = RocoSkillProxy.Create(SkillPath, SkillComp)
  if not (PetView and TargetView and SkillComp) or not SkillPath then
    Log.Warning("\230\137\167\232\161\140Action\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\230\149\176\230\141\174\239\188\129")
    self:Finish(false)
    return
  end
  Skill:SetCaster(PetView)
  Skill:SetTargets({TargetView})
  Skill:RegisterEventCallback("ActivateFailed", self, self.FailedExecute)
  Skill:RegisterEventCallback("PreEnd", self, self.SkillComplete)
  Skill:RegisterEventCallback("End", self, self.SkillComplete)
  Skill:RegisterEventCallback("Interrupt", self, self.SkillComplete)
  Skill:RegisterEventCallback("FreeAI", self, self.FreeAI)
  Skill:RegisterEventCallback("OnInteracted", self, self.OnInteracted)
  Skill:PlaySkill(self, self.OnSkillStart)
  if self.Config.action_type == _G.Enum.ActionType.ACT_HOME_PLANT_PET_WATER then
    self.ReduceTime = FarmUtils.GetWateringReduceTimeCurrent(self:GetOwnerNPC():GetFarmLandId())
    self.LandID = self:GetOwnerNPC():GetFarmLandId()
  end
end

function PetActionInteractPlant:OnSubmit(rsp)
  self:ConsumeOwnerActorTag()
  if 0 ~= rsp.ret_info.ret_code then
    self:FailedExecute()
    self.InteractSuccess = false
  else
    self.InteractSuccess = true
    self:TryAddFloatingText()
  end
end

function PetActionInteractPlant:PreExecuteCheck(Runner)
  local PetBaseId = Runner:GetPetbaseId()
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetBaseId, true)
  if not PetBaseConf then
    Log.Warning("[PetAction WaterPlant] need pet to execute!")
    return false
  end
  local PetTypes = PetBaseConf.unit_type
  local PetPos = Runner:GetActorLocation()
  local NPCPos = self:GetOwnerNPC():GetActorLocation()
  local DistSquared = UE4.FVector.DistSquared(PetPos, NPCPos)
  if DistSquared > 1000000 then
    return false
  end
  if not Runner:IsControlledByPlayer() then
    self.InteractType = ActionType2PetType[self.Config.action_type]
    return true
  end
  local LandID = self:GetOwnerNPC():GetFarmLandId()
  if LandID then
    local Status = FarmUtils.GetLandOptionStatus(LandID)
    if not OptionType2PetTypeMap[Status] then
      return false
    end
    local LandFlag = false
    for _, PetType in ipairs(PetTypes) do
      if OptionType2PetTypeMap[Status] == PetType then
        self.InteractType = PetType
        LandFlag = true
        break
      end
    end
    if not LandFlag then
      return false
    end
  else
    Log.Warning("Option\229\175\185\232\177\161\230\178\161\231\167\141\229\156\168\229\134\156\231\148\176\228\184\138")
  end
  return true
end

function PetActionInteractPlant:CheckSubType(PetTypes, SubType)
  for _, PetType in ipairs(PetTypes) do
    if PetType == SubType then
      return true
    end
  end
  return false
end

function PetActionInteractPlant:FailedExecute()
  Log.Warning("\230\137\167\232\161\140Action\229\164\177\232\180\165\239\188\140\229\143\175\232\131\189\230\152\175AI\229\143\136\229\176\157\232\175\149\229\164\154\230\172\161\228\186\164\228\186\146\228\186\134\239\188\140\233\171\152\229\134\183\230\139\146\231\187\157")
  self:FreeAI()
  self:Finish(false)
end

function PetActionInteractPlant:OnSkillStart(_, Result)
  if Result ~= UE.ESkillStartResult.Success then
    self:FailedExecute()
  end
  self:LockAI(Runner)
end

function PetActionInteractPlant:SkillComplete(_, _)
  self:FreeAI()
  self:Finish(false)
end

function PetActionInteractPlant:OnInteracted(_, _)
  Base.Submit(self)
  self:Finish(true)
end

function PetActionInteractPlant:ContinueWhenSuccess()
  return false
end

function PetActionInteractPlant:FreeAI()
  if self.LockedAI then
    self.LockedAI.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.INTERACT)
    self.LockedAI = nil
  end
end

function PetActionInteractPlant:ForceFreeAI(Pet)
  local FreeTarget = Pet or self.LockedAI
  if FreeTarget then
    FreeTarget.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.INTERACT)
    FreeTarget.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.ACTION_PROCESS)
    self.LockedAI = nil
  else
    Log.Warning("ForceFreeAI\230\151\182\239\188\140\231\178\190\231\129\181\230\182\136\229\164\177\228\186\134\239\188\129")
  end
end

function PetActionInteractPlant:LockAI(Pet)
  local LockTarget = Pet or self.Runner
  if LockTarget then
    LockTarget.AIComponent:ForceLockForReason(true, false, _G.AIDefines.LockReason.INTERACT)
    self.LockedAI = LockTarget
    if LockTarget.ThrowSession then
      LockTarget.ThrowSession:SetStatus()
    end
    Log.Debug("\229\188\128\229\167\139\228\186\164\228\186\146, \230\136\145\228\187\172\233\148\129\228\184\128\228\184\139AI")
  else
    Log.Warning("LockAI\230\151\182\239\188\140\231\178\190\231\129\181\230\182\136\229\164\177\228\186\134\239\188\129")
  end
end

function PetActionInteractPlant:TryAddFloatingText()
  if self.Config.action_type ~= _G.Enum.ActionType.ACT_HOME_PLANT_PET_WATER then
    return
  end
  if not self.InteractSuccess or not self.ReduceTime then
    return
  end
  local LandID = self.LandID or self:GetOwnerNPC():GetFarmLandId()
  local ReduceTime = self.ReduceTime
  self.ReduceTime = nil
  self.InteractSuccess = nil
  a.task(function()
    a.wait(au.DelaySeconds(0.3))
    FarmUtils.AddFloatingText(LandID, ReduceTime)
  end)()
end

return PetActionInteractPlant
