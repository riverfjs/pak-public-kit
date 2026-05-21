local BattlePetStateNode = require("NewRoco.Modules.Core.Battle.Entity.Card.BattlePetStateNode")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BuffGroupSign = Enum.BuffGroupSign
local BattlePetState = NRCClass()
local NodeStateToNameDict = {
  Battle = "Battle",
  Show = "Show",
  Endure = "Endure",
  Sleep = "Sleep",
  Drill = "Drill",
  Static = "Static",
  Mimic = "Mimic",
  Hidden = "Hidden",
  BackStab = "BackStab",
  Stun = "Stun",
  Ghost = "Ghost",
  Thunder = "Thunder",
  Diving = "Diving",
  Trail = "Trail",
  LeaderStun = "LeaderStun",
  CatchStun = "CatchStun",
  Gather = "Gather",
  Nightmare = "Nightmare",
  NightmareOne = "NightmareOne",
  SurpriseBox = "SurpriseBox",
  IdleToHappy = "IdleToHappy",
  BattleMimic = "BattleMimic",
  BlackMagic = "BlackMagic",
  PersistentShield = "PersistentShield",
  RiverSoulParticle = "RiverSoulParticle"
}

function BattlePetState:Ctor(owner)
  self.owner = owner
  self.isDead = false
  self.DeadType = ProtoEnum.BattleDeadInfo.DeadType.NORMAL_DEAD
  self.isStakeStanding = false
  self.isSilent = false
  self.isStuck = false
  self.isFever = false
  self.bRidOf = false
  self.stuckPos = nil
  self.nodeCfg = {
    {
      state = NodeStateToNameDict.Battle,
      parent = nil,
      isUnique = false,
      owner = self
    },
    {
      state = NodeStateToNameDict.Endure,
      parent = NodeStateToNameDict.Battle,
      buffSign = BuffGroupSign.BGS_DEFEND
    },
    {
      state = NodeStateToNameDict.Sleep,
      parent = NodeStateToNameDict.Battle,
      buffSign = BuffGroupSign.BGS_SLEEP
    },
    {
      state = NodeStateToNameDict.BackStab,
      parent = NodeStateToNameDict.Battle,
      buffSign = BuffGroupSign.BGS_BACKSTAB
    },
    {
      state = NodeStateToNameDict.Stun,
      parent = NodeStateToNameDict.Battle,
      buffSign = BuffGroupSign.BGS_MAGICDIZZY
    },
    {
      state = NodeStateToNameDict.BattleMimic,
      parent = NodeStateToNameDict.Battle,
      buffSign = BuffGroupSign.BGS_BATTLE_MIMIC
    },
    {
      state = NodeStateToNameDict.Show,
      parent = nil,
      isUnique = false,
      owner = self
    },
    {
      state = NodeStateToNameDict.Drill,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_DRILL
    },
    {
      state = NodeStateToNameDict.Static,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_STATIC
    },
    {
      state = NodeStateToNameDict.Mimic,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_MIMIC
    },
    {
      state = NodeStateToNameDict.Hidden,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_HIDE
    },
    {
      state = NodeStateToNameDict.Ghost,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_GHOST
    },
    {
      state = NodeStateToNameDict.Thunder,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_THUNDER
    },
    {
      state = NodeStateToNameDict.Diving,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_DIVING
    },
    {
      state = NodeStateToNameDict.Trail,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_TRAIL
    },
    {
      state = NodeStateToNameDict.LeaderStun,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_LEADERDIZZY
    },
    {
      state = NodeStateToNameDict.CatchStun,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_CATCHSTUN
    },
    {
      state = NodeStateToNameDict.Gather,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_GATHER
    },
    {
      state = NodeStateToNameDict.Nightmare,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_NIGHTMARE
    },
    {
      state = NodeStateToNameDict.NightmareOne,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_NIGHTMARE_ONE
    },
    {
      state = NodeStateToNameDict.SurpriseBox,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_FANTASTIC_BOX
    },
    {
      state = NodeStateToNameDict.IdleToHappy,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_IDLE
    },
    {
      state = NodeStateToNameDict.BlackMagic,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_BLACK_MAGIC
    },
    {
      state = NodeStateToNameDict.PersistentShield,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_PERSISTENT_SHIELD
    },
    {
      state = NodeStateToNameDict.RiverSoulParticle,
      parent = NodeStateToNameDict.Show,
      buffSign = BuffGroupSign.BGS_RIVERSOUL_PARTICLES
    }
  }
  self.stateDict = {}
  self.groupSignToState = {}
  self.diePerformType = BattleEnum.DiePerformType.Default
  for i, v in ipairs(self.nodeCfg) do
    local parent = v.parent and self.stateDict[v.parent]
    local owner = v.owner or self
    local node = BattlePetStateNode(v.state, parent, v.isUnique, owner)
    node:SetBuffSign(v.buffSign)
    self.stateDict[v.state] = node
    if v.buffSign then
      self.groupSignToState[v.buffSign] = v.state
    end
  end
end

function BattlePetState:ResetAllState()
  for i, node in pairs(self.stateDict) do
    node:ResetState()
  end
end

function BattlePetState:NodeValueChange(node)
  if self.owner and self.owner.BattlePet and node.buffSign then
    self.owner.BattlePet.buffComponent:OnStateValueChange(node.buffSign, node:GetValue())
  end
end

function BattlePetState:SetState(name, boo)
  local node = self.stateDict[name]
  node:SetValue(boo)
end

function BattlePetState:OpenState(buffGroupSign)
  local nameState = self.groupSignToState[buffGroupSign]
  if not nameState then
    Log.Warning(" BattlePetState:OpenState, GroupSign\230\156\170\233\133\141\231\189\174", buffGroupSign)
    return
  end
  self:SetState(nameState, true)
end

function BattlePetState:CloseState(buffGroupSign)
  local nameState = self.groupSignToState[buffGroupSign]
  if not nameState then
    Log.Warning(" BattlePetState:CloseState, GroupSign\230\156\170\233\133\141\231\189\174", buffGroupSign)
    return
  end
  self:SetState(nameState, false)
end

function BattlePetState:GetStateBySign(buffGroupSign)
  local nameState = self.groupSignToState[buffGroupSign]
  if nameState then
    return self:GetState(nameState)
  else
    Log.Warning("zgx BattlePetState:CloseState, GroupSign\230\156\170\233\133\141\231\189\174", buffGroupSign)
  end
end

function BattlePetState:GetState(name)
  return self.stateDict[name]:GetValue()
end

function BattlePetState:GetBeRidOf()
  return self.bRidOf
end

function BattlePetState:SetBeRidOf(isRidOf)
  self.bRidOf = isRidOf
end

function BattlePetState:SetStuck(boo)
  Log.Trace("BattlePetState SetStuck:", boo)
  self.isStuck = boo
end

function BattlePetState:SetStuckPos(pos)
  self.stuckPos = pos
end

function BattlePetState:GetStuck()
  return self.isStuck
end

function BattlePetState:SetDead(boo)
  self.isDead = boo
end

function BattlePetState:GetDead()
  return self.isDead
end

function BattlePetState:SetDeadType(type)
  self.DeadType = type
end

function BattlePetState:GetDeadType()
  return self.DeadType
end

function BattlePetState:SetFever(boo)
  self.isFever = boo
end

function BattlePetState:IsFever()
  return self.isFever
end

function BattlePetState:SetSleep(boo)
  Log.Debug("BattlePetState:SetSleep:", boo)
  self:SetState(NodeStateToNameDict.Sleep, boo)
end

function BattlePetState:GetSleep()
  return self:GetState(NodeStateToNameDict.Sleep)
end

function BattlePetState:GetGather()
  return self:GetState(NodeStateToNameDict.Gather)
end

function BattlePetState:SetSilent(boo)
  self.isSilent = boo
end

function BattlePetState:SetStakeStanding(boo)
  self.isStakeStanding = boo
end

function BattlePetState:SetEndure(boo)
  Log.Debug("BattlePetState:SetEndure:", boo)
  self:SetState(NodeStateToNameDict.Endure, boo)
end

function BattlePetState:GetEndure()
  return self:GetState(NodeStateToNameDict.Endure)
end

function BattlePetState:SetDrill(boo)
  Log.Debug("BattlePetState:SetDrill:", boo)
  self:SetState(NodeStateToNameDict.Drill, boo)
end

function BattlePetState:GetDrill()
  return self:GetState(NodeStateToNameDict.Drill)
end

function BattlePetState:SetStatic(boo)
  Log.Debug("BattlePetState:SetStatic:", boo)
  self:SetState(NodeStateToNameDict.Static, boo)
end

function BattlePetState:GetStatic()
  return self:GetState(NodeStateToNameDict.Static)
end

function BattlePetState:GetPersistentShield()
  return self:GetState(NodeStateToNameDict.PersistentShield)
end

function BattlePetState:SetMimic(boo)
  Log.Debug("BattlePetState:SetMimic:", boo)
  self:SetState(NodeStateToNameDict.Mimic, boo)
end

function BattlePetState:GetMimic()
  if self:GetState(NodeStateToNameDict.Mimic) then
    return true, BuffGroupSign.BGS_MIMIC
  elseif self:GetState(NodeStateToNameDict.BattleMimic) then
    return true, BuffGroupSign.BGS_BATTLE_MIMIC
  else
    return false
  end
end

function BattlePetState:GetSurpriseBox()
  if self:GetState(NodeStateToNameDict.SurpriseBox) then
    return true, BuffGroupSign.BGS_FANTASTIC_BOX
  else
    return false
  end
end

function BattlePetState:SetHidden(boo)
  Log.Debug("BattlePetState:SetHidden:", boo)
end

function BattlePetState:GetHidden()
  return self:GetState(NodeStateToNameDict.Hidden)
end

function BattlePetState:GetPetIsInHide()
  return self:GetState(NodeStateToNameDict.Hidden) or self:GetState(NodeStateToNameDict.Mimic) or self:GetState(NodeStateToNameDict.Static) or self:GetState(NodeStateToNameDict.Drill)
end

function BattlePetState:SetBackStab(boo)
  Log.Debug("BattlePetState:SetBackStab:", boo)
  self:SetState(NodeStateToNameDict.BackStab, boo)
end

function BattlePetState:GetBackStab()
  return self:GetState(NodeStateToNameDict.BackStab)
end

function BattlePetState:SetStun(boo)
  Log.Debug("BattlePetState:SetStun:", boo)
  self:SetState(NodeStateToNameDict.Stun, boo)
end

function BattlePetState:GetStun()
  return self:GetState(NodeStateToNameDict.Stun)
end

function BattlePetState:SetGhost(boo)
  self:SetState(NodeStateToNameDict.Ghost, boo)
end

function BattlePetState:GetGhost()
  return self:GetState(NodeStateToNameDict.Ghost)
end

function BattlePetState:SetThunder(boo)
  self:SetState(NodeStateToNameDict.Thunder, boo)
end

function BattlePetState:GetThunder()
  return self:GetState(NodeStateToNameDict.Thunder)
end

function BattlePetState:SetDiving(boo)
  self:SetState(NodeStateToNameDict.Diving, boo)
end

function BattlePetState:GetDiving()
  return self:GetState(NodeStateToNameDict.Diving)
end

function BattlePetState:SetTrail(boo)
  self:SetState(NodeStateToNameDict.Trail, boo)
end

function BattlePetState:GetTrail()
  return self:GetState(NodeStateToNameDict.Trail)
end

function BattlePetState:SetCatchStun(boo)
  self:SetState(NodeStateToNameDict.CatchStun, boo)
end

function BattlePetState:GetCatchStun()
  return self:GetState(NodeStateToNameDict.CatchStun)
end

function BattlePetState:GetLeaderStun()
  return self:GetState(NodeStateToNameDict.LeaderStun)
end

function BattlePetState:GetNightmare()
  return self:GetState(NodeStateToNameDict.Nightmare)
end

function BattlePetState:GetNightmareOne()
  return self:GetState(NodeStateToNameDict.NightmareOne)
end

function BattlePetState:CheckOnBuffTrigger(buffSign)
  return not string.IsNilOrEmpty(self.groupSignToState[buffSign])
end

function BattlePetState:IsStepbackable()
  return not self.isStakeStanding and not self:GetEndure()
end

function BattlePetState:IsAnimable(animName)
  if self.owner.IgnoreAnimCheck then
    return true
  end
  if self:GetDead() then
    if self:IsDiePerformType(BattleEnum.DiePerformType.WithStun) then
      return "Stun" == animName
    else
      return "Die" == animName
    end
  elseif self:GetStun() or self:GetCatchStun() or self:GetLeaderStun() then
    return "Stun" == animName
  elseif "Hurt" == animName then
    return not self:GetEndure() or not self.isSilent
  elseif "Happy" == animName or "Sad" == animName then
    return self:CanPlayAnim() and not self:GetBackStab()
  elseif "Shock" == animName or "Fear" == animName or "Show" == animName or "Anger" == animName or "Alert" == animName then
    return self:CanPlayAnim()
  elseif table.contains(SkillUtils.hitAnimationName, animName) then
    return self:CanPlayAnim() and not self:GetPersistentShield()
  elseif "StaticLoop" == animName then
    return self:GetStatic()
  elseif "DrillLoop" == animName then
    return self:GetDrill()
  elseif self:GetSleep() then
    return "SleepStand" == animName or "SleepLoop" == animName
  end
  return true
end

function BattlePetState:CanPlayAnim()
  return not self:GetEndure() and not self.isSilent and not self:GetSleep() and not self:GetCatchStun() and not self:GetGather() and not self:GetStun() and not self:GetLeaderStun()
end

function BattlePetState:IsMovable()
  return not self.isStuck
end

function BattlePetState:SetDiePerformType(type)
  self.diePerformType = type
end

function BattlePetState:IsDiePerformType(type)
  return self.diePerformType == type
end

return BattlePetState
