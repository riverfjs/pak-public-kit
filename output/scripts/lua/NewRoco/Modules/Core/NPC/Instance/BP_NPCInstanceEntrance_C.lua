require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.Instance.BP_NPCInstanceMechanismBase_C")
local BP_NPCInstanceEntrance_C = Base:Extend("BP_NPCInstanceEntrance_C")
local UseSound = 1393
local UnLockSound = 1394

function BP_NPCInstanceEntrance_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  self.action = nil
  self.isInteraction = false
  self.isOnUnlock = false
  self:SetEffectShow(self.Use, false)
end

function BP_NPCInstanceEntrance_C:PlayUseEffect(action)
  if self.isInteraction then
    return
  end
  self.isInteraction = true
  self.action = action
  self.Use:Clear()
  self:SetEffectShow(self.Use, true, true)
  _G.NRCAudioManager:PlaySound2DAuto(UseSound, "BP_NPCInstanceEntrance_C:PlayUseEffect")
  self.waitUseEffectFinish = _G.DelayManager:DelaySeconds(1.5, self.OnUseEffectFinish, self)
end

function BP_NPCInstanceEntrance_C:OnUseEffectFinish()
  if self.action then
  end
  if self.waitUseEffectFinish then
    _G.DelayManager:CancelDelayById(self.waitUseEffectFinish)
    self.waitUseEffectFinish = nil
  end
  self.isInteraction = false
end

function BP_NPCInstanceEntrance_C:OnActionFinish()
  self:SetEffectShow(self.Use, false, true)
end

function BP_NPCInstanceEntrance_C:SetEffectShow(effect, isShow, isReset)
  effect:SetVisibility(isShow)
  if nil == isReset then
    isReset = false
  end
  effect:SetActive(isShow, isReset)
end

function BP_NPCInstanceEntrance_C:PlayLockLoopEffect()
end

function BP_NPCInstanceEntrance_C:PlayUnlockEffect(lockNum)
  _G.NRCAudioManager:PlaySound2DAuto(UnLockSound, "BP_NPCInstanceEntrance_C:PlayUnlockEffect")
end

function BP_NPCInstanceEntrance_C:OnUnLock()
end

return BP_NPCInstanceEntrance_C
