local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local BornDieComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.BornDieComponent")
local Base = NPCActionBase
local NPCActionHideContent = Base:Extend("NPCActionShowContent")

function NPCActionHideContent:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.Contents = false
end

function NPCActionHideContent:Execute(playerId, needSendReq)
  Base.Execute(self, playerId, needSendReq)
  if not self.Contents then
    local NumberStrings = string.Split(self.Config.action_param1, ";")
    NumberStrings = NumberStrings or {
      self.Config.action_param1
    }
    for Index, Str in ipairs(NumberStrings) do
      NumberStrings[Index] = tonumber(Str)
    end
    self.Contents = NumberStrings
  end
  if self.Contents then
    for _, ContentID in ipairs(self.Contents) do
      local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, ContentID)
      self:HideNpc(NPC)
    end
  end
  self:Finish(true)
end

function NPCActionHideContent:ToggleShowHide(npc)
  if not npc then
    return
  end
  npc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  npc:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  npc:AdjustModelHeight()
  npc:AdjustModelOpacity()
  npc:AdjustModelFresnel()
end

function NPCActionHideContent:HideNpc(npc)
  if not npc then
    return
  end
  local View = npc.viewObj
  if not View or not UE.UObject.IsValid(View) then
    self:ToggleShowHide(npc)
    return
  end
  local DisappearSkill = npc.config.disappear_skill
  local DisappearAni = npc.config.disappear_ani
  local HasSkill = not string.IsNilOrEmpty(DisappearSkill)
  local HasAnim = not string.IsNilOrEmpty(DisappearAni)
  if not HasSkill and not HasAnim then
    self:ToggleShowHide(npc)
    return
  end
  local BornDieComp = npc:EnsureComponent(BornDieComponent)
  local action = _G.ProtoMessage:newSpaceAct_ActorDieBegin()
  action.die_reason = _G.ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_NONE
  action.killer = 0
  action.actor_id = npc:GetServerId()
  action.is_skill = HasSkill
  action.skill_or_anim = HasSkill and DisappearSkill or DisappearAni
  local HasPerform = BornDieComp:OnBeginDying(action, nil, true)
  if HasPerform then
    npc:AddEventListener(self, NPCModuleEvent.OnBornDiePerformEnd, self.OnDieFinish)
  else
    self:ToggleShowHide(npc)
  end
end

function NPCActionHideContent:OnDieFinish(npc)
  npc:RemoveEventListener(self, NPCModuleEvent.OnBornDiePerformEnd, self.OnDieFinish)
  if npc.isDestroy then
    return
  end
  local Comp = npc:EnsureComponent(BornDieComponent)
  if not Comp then
    return
  end
  if not Comp:IsAlive() then
    return
  end
  self:ToggleShowHide(npc)
end

function NPCActionHideContent:ExecuteWhenSkipping()
  if not self.Contents then
    local NumberStrings = string.Split(self.Config.action_param1, ";")
    NumberStrings = NumberStrings or {
      self.Config.action_param1
    }
    for Index, Str in ipairs(NumberStrings) do
      NumberStrings[Index] = tonumber(Str)
    end
    self.Contents = NumberStrings
  end
  if self.Contents then
    for _, ContentID in ipairs(self.Contents) do
      local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, ContentID)
      if NPC then
        self:HideNpcWhenSkipping(NPC)
      end
    end
  end
end

function NPCActionHideContent:HideNpcWhenSkipping(npc)
  if not npc then
    return
  end
  local View = npc.viewObj
  if not View or not UE.UObject.IsValid(View) then
    self:ToggleShowHide(npc)
    return
  end
  local DisappearSkill = npc.config.disappear_skill
  local DisappearAni = npc.config.disappear_ani
  local HasSkill = not string.IsNilOrEmpty(DisappearSkill)
  local HasAnim = not string.IsNilOrEmpty(DisappearAni)
  if not HasSkill and not HasAnim then
    self:ToggleShowHide(npc)
    return
  end
  local BornDieComp = npc:EnsureComponent(BornDieComponent)
  BornDieComp:OnDieWhenSkipping()
  self:ToggleShowHide(npc)
end

return NPCActionHideContent
