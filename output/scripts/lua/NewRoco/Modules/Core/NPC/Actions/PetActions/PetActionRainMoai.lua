local Base = require("NewRoco.Modules.Core.NPC.Actions.PetActionBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local PetActionRainMoai = Base:Extend("PetActionRainMoai")

function PetActionRainMoai:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function PetActionRainMoai:GetRangeType()
  return Enum.PetReleaseRange.PRR_FAR_BIG
end

function PetActionRainMoai:OnExecute()
  self.interact_type = _G.Enum.SkillDamType.SDT_NONE
  for _, config in pairs(self.Config.interact_cond_group) do
    if config.interact_cond == Enum.PetInteract_cond.COND_SKILLDAM then
      for _, Type in ipairs(config.interact_cond_param) do
        self.interact_type = Enum.SkillDamType[Type]
      end
    end
  end
  local viewObj = self:GetOwnerNPCView()
  if not viewObj then
    self:Finish(false)
    return
  end
  self:PreSubmit()
end

function PetActionRainMoai:PreSubmit()
  local viewObj = self:GetOwnerNPCView()
  if not viewObj or not viewObj:IsCanInteract(self.interact_type) then
    self:Submit()
    self:Finish(false)
    Log.Warning("\231\155\184\229\144\140\229\164\169\230\176\148\239\188\159 ")
    return
  end
  viewObj.interactPet = self.Runner
  viewObj.interactType = self.interact_type
  viewObj.interactFinishDelegate:Add(self, self.OnPerformEnd)
  self:Submit()
  Base.SetSessionRecycle(self, false)
  a.task(function()
    a.wait(au.DelaySeconds(5))
    self:SetSessionRecycle(true)
  end)()
end

function PetActionRainMoai:OnSubmit(rsp)
  self:ConsumeOwnerActorTag()
  if 0 ~= rsp.ret_info.ret_code then
    self:Finish(false)
  end
end

function PetActionRainMoai:OnPerformEnd()
  self:Finish(true)
end

function PetActionRainMoai:OnFinish()
  Log.Debug("PetActionPotentialEnergy:OnFinish")
  local OwnerView = self:GetOwnerNPCView()
  if not OwnerView then
    return
  end
  if OwnerView.interactFinishDelegate then
    OwnerView.interactFinishDelegate:Remove(self, self.OnPerformEnd)
  end
end

return PetActionRainMoai
