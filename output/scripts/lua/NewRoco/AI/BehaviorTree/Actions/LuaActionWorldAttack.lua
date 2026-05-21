local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local AttackComponent = require("NewRoco.Modules.Core.Scene.Component.Attack.AttackComponent")
local LuaActionWorldAttack = Base:Extend("LuaActionWorldAttack")
local DefaultTimeoutCount = 10

function LuaActionWorldAttack:OnStart(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  local AttackComp = owner.Npc:EnsureComponent(AttackComponent)
  if not AttackComp then
    return self:Finish(false)
  end
  if GlobalConfig.DisablePetAttack then
    return self:Finish(false)
  end
  local player = owner:GetFocusPlayerCharacter()
  if not player or not player.viewObj then
    return self:Finish(false)
  end
  if player.statusComponent and player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_BATTLE) then
    Log.Debug("[AttackComponent] \231\178\190\231\129\181\230\148\187\229\135\187 \229\138\159\232\131\189\229\183\178\229\155\160[\231\142\169\229\174\182\230\136\152\230\150\151\228\184\173]\231\166\129\231\148\168 npc:", owner.Npc.config.name)
    return self:Finish(false)
  end
  if player.statusComponent and player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
    Log.Debug("[AttackComponent] \231\178\190\231\129\181\230\148\187\229\135\187 \229\138\159\232\131\189\229\183\178\229\155\160[\231\142\169\229\174\182\229\183\178\230\173\187\228\186\161]\231\166\129\231\148\168 npc:", owner.Npc.config.name)
    return self:Finish(false)
  end
  if not UE4.UNRCStatics.GetEnableWorldRendering() then
    Log.Debug("[AttackComponent] \231\178\190\231\129\181\230\148\187\229\135\187 \229\138\159\232\131\189\229\183\178\229\155\160[DisableWorldRendering]\231\166\129\231\148\168 npc:", owner.Npc.config.name)
    return self:Finish(false)
  end
  if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    Log.Debug("[AttackComponent] \231\178\190\231\129\181\230\148\187\229\135\187 \229\138\159\232\131\189\229\183\178\229\155\160[\228\184\180\230\151\182\229\164\132\231\144\134\229\175\185\232\175\157\227\128\129\230\146\173\231\137\135\227\128\129\233\187\145\229\185\149\230\151\182\229\177\143\232\148\189\230\148\187\229\135\187]\231\166\129\231\148\168 npc:", owner.Npc.config.name)
    return self:Finish(false)
  end
  local isAttackBan = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_BT_ATTACK, false, false)
  if isAttackBan then
    Log.Debug("[AttackComponent] \231\178\190\231\129\181\230\148\187\229\135\187 \229\138\159\232\131\189\229\183\178\229\155\160[FunctionBanModule]\231\166\129\231\148\168 npc:", owner.Npc.config.name)
    return self:Finish(false)
  end
  local aimType = self.AimType:GetValue(owner) or 1
  local attackType = self.AttackType:GetValue(owner) or 1
  local range = self.Range:GetValue(owner) or 30
  local predict = self.Predict:GetValue(owner) or 0
  local damage = self.Damage:GetValue(owner) or 30
  local hitStrength = self.HitStrength:GetValue(owner) or 50
  local isHeavy = self.IsHeavy:GetValue(owner) or false
  local PlayerHitType = isHeavy and ProtoEnum.PlayerAttackPerformType.PAPT_Heavy or self.PlayerHitType and self.PlayerHitType:GetValue(owner) or ProtoEnum.PlayerAttackPerformType.PAPT_Light
  local attackParam = owner.Npc.AttackComponent.CreateParam()
  self.timeout = 0
  attackParam.Target = player
  attackParam.AimType = aimType
  attackParam.ActionType = attackType
  attackParam.Radius = range
  attackParam.Predict = predict
  if _G.GlobalConfig.DisablePetDamage then
    attackParam.Damage = 0
  else
    attackParam.Damage = damage
  end
  attackParam.HitStrength = hitStrength
  attackParam.PlayerHitType = PlayerHitType
  attackParam.AbnormalStatus = self.AbnormalType and self.AbnormalType:GetValue(owner) or 0
  attackParam.AbnormalDuration = self.AbnormalDuration and self.AbnormalDuration:GetValue(owner) or 0
  local specificPos = self.UseSpecificPos and self.UseSpecificPos:GetValue(owner) and self.SpecificPos and self.SpecificPos:GetValue(owner)
  attackParam.TargetPos = specificPos
  owner.Npc.AttackComponent:StartAttack(attackParam, self, self.AttackEnd)
  self.timeout = DefaultTimeoutCount
end

function LuaActionWorldAttack:OnInterrupt(AIController)
  local owner = AIController
  if owner and owner.Npc.AttackComponent then
    owner.Npc.AttackComponent:StopAttack(true)
  end
end

function LuaActionWorldAttack:OnUpdate(AIController, DeltaTime)
  local owner = AIController
  self.timeout = self.timeout - DeltaTime
  if self.timeout < 0 then
    owner.Npc.AttackComponent:StopAttack(true)
    self:Finish(true)
  end
end

function LuaActionWorldAttack:AttackEnd(result)
  self:Finish(AIDefines.ActionResult.Ok(result))
end

return LuaActionWorldAttack
