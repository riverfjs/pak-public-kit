local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattlePetState = require("NewRoco.Modules.Core.Battle.Entity.Card.BattlePetState")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local ServerData = require("Common.LocalServer.LocalBattleRSPTable")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePathWithAppearance = require("NewRoco.Modules.Core.Battle.Common.BattlePathWithAppearance")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
local Enum = require("Data.Config.Enum")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleCard = NRCClass()

function BattleCard:Ctor(owner, petInfo, CardIndex)
  self.owner = owner
  self.petInfo = nil
  self.IgnoreAnimCheck = false
  self:ReplaceByServer(petInfo)
  self.petState = BattlePetState(self)
  local battleInfo = petInfo.battle_inside_pet_info
  local configID = battleInfo.conf_id
  self.resourceScale = 1.0
  self.initResourceScale = 1.0
  self.AppearancePath = BattlePathWithAppearance()
  self.AppearancePath:SetOwner(self)
  self.isMonster = false
  self.config = _G.DataConfigManager:GetPetConf(configID, true)
  if not self.config then
    self.config = _G.DataConfigManager:GetMonsterConf(configID)
    self.isMonster = true
    if not self.config then
      Log.Error("not found monster config : ", configID)
    end
  end
  if not self.config and ServerData.values.battleMode then
    local RowConfs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.PET_CONF)
    for _, v in pairs(RowConfs) do
      self.config = v
      self.isMonster = false
      break
    end
  end
  if not self.config then
    self.isMonster = false
  end
  self.ordinaryBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.battle_common_pet_info.base_conf_id)
  self:SetHpValue(0)
  self.WillMove1VN = false
  self.CardIndex = CardIndex
  self:RefreshByInfoAndBaseConf(self.petInfo, battleInfo.base_conf_id)
  self:RefreshByServer()
  self.posInField = (self.owner.FirstPetPosInField or 0) + (self.pos <= 0 and 1 or self.pos)
end

function BattleCard:HpChange(value)
  if value then
    local newHp = self.hp + value
    newHp = math.clamp(newHp, 0, self.max_hp)
    self:SetHpValue(newHp)
  end
end

function BattleCard:ShieldChange(value)
  if value then
    local newShield = self.shield + value
    newShield = math.clamp(newShield, 0, self.max_shield)
    self.shield = newShield
  end
end

function BattleCard:RefreshResource()
  self.icon = PetUtils.GetPetIconPath(self.petInfo, self.petBaseConf)
  self.resourcePath = PetUtils.GetPetModelPath(self.petInfo, self.petBaseConf)
  self.resourceScale, self.initResourceScale = PetUtils.GetPetResourceScale(self.petInfo, self.petBaseConf, self:IsEnemy())
end

function BattleCard:InitAppearancePath()
  self.AppearancePath:Reset()
  local suitPerformConf
  if self.owner and self.owner.FashionData and self.owner.FashionData.suitConf then
    suitPerformConf = BattleUtils.GetFashionPerformBySuitConf(self.owner.FashionData.suitConf, self.petBaseConf.id)
  end
  if not suitPerformConf and self.owner and self.owner.FashionData and self.owner.FashionData.bondConfs then
    for _, v in ipairs(self.owner.FashionData.bondConfs) do
      suitPerformConf = BattleUtils.GetFashionPerformById(v.perform_id, self.petBaseConf.id)
      if suitPerformConf then
        break
      end
    end
  end
  if suitPerformConf then
    local petBaseId = self.petBaseConf.id
    if table.contains(suitPerformConf.petbase1_id, petBaseId) then
      local changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect1_callout_skill)
      if changePath then
        self.AppearancePath.HuanChong = changePath
        self.AppearancePath.EnemyZhaoHuan = changePath
        self.AppearancePath.EnemyHuanChong = changePath
        self.AppearancePath.HuanchongSuiId = suitPerformConf.id
      end
    elseif table.contains(suitPerformConf.petbase2_id, petBaseId) then
      local changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect2_callout_skill)
      if changePath then
        self.AppearancePath.HuanChong = changePath
        self.AppearancePath.EnemyZhaoHuan = changePath
        self.AppearancePath.EnemyHuanChong = changePath
        self.AppearancePath.HuanchongSuiId = suitPerformConf.id
      end
    elseif table.contains(suitPerformConf.petbase3_id, petBaseId) then
      local changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect3_callout_skill)
      if changePath then
        self.AppearancePath.HuanChong = changePath
        self.AppearancePath.EnemyZhaoHuan = changePath
        self.AppearancePath.EnemyHuanChong = changePath
        self.AppearancePath.HuanchongSuiId = suitPerformConf.id
      end
      changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect3_win_skill)
      if changePath then
        self.AppearancePath.PVPOver = changePath
        self.AppearancePath.PVPOverSuiId = suitPerformConf.id
        self.AppearancePath.WeeklyChallengeOver = changePath
      end
    elseif table.contains(suitPerformConf.petbase4_id, petBaseId) then
      local changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect4_callout_skill)
      if changePath then
        self.AppearancePath.HuanChong = changePath
        self.AppearancePath.EnemyZhaoHuan = changePath
        self.AppearancePath.EnemyHuanChong = changePath
        self.AppearancePath.HuanchongSuiId = suitPerformConf.id
      end
      changePath = BattleUtils.GetSkillPathByResId(suitPerformConf.suiteffect4_win_skill)
      if changePath then
        self.AppearancePath.PVPOver = changePath
        self.AppearancePath.PVPOverSuiId = suitPerformConf.id
        self.AppearancePath.WeeklyChallengeOver = changePath
      end
    end
  end
end

function BattleCard:SetEnergy(value)
  if value < 0 then
    value = 0
  end
  self.petInfo.battle_common_pet_info.energy = value
  self.energy = value
end

function BattleCard:SetMaxEnergy(maxEnergy)
  maxEnergy = maxEnergy or 0
  maxEnergy = math.max(maxEnergy, 0)
  local currPetInfo = self.petInfo
  local currInsideInfo = currPetInfo and currPetInfo.battle_inside_pet_info
  local nextInsideInfo = {}
  table.copy(currInsideInfo, nextInsideInfo)
  nextInsideInfo.max_energy = maxEnergy
  local nextPetInfo = {}
  table.copy(currPetInfo, nextPetInfo)
  nextPetInfo.battle_inside_pet_info = nextInsideInfo
  self:OverwriteByServer(nextPetInfo)
  self:RefreshByServer()
end

function BattleCard:RefreshMedal(petInfo)
  if petInfo and petInfo.battle_common_pet_info.wear_medal_conf_id and petInfo.battle_common_pet_info.wear_medal_conf_id > 0 then
    self.medalConf = _G.DataConfigManager:GetMedalConf(petInfo.battle_common_pet_info.wear_medal_conf_id, true)
  end
  self:RefreshMedalName(petInfo)
end

function BattleCard:RefreshName(petInfo)
  self.name = PetUtils.GetPetShowName(petInfo, self.petBaseConf)
  self:RefreshMedalName(petInfo)
  self.guid = petInfo.battle_inside_pet_info.pet_id
end

function BattleCard:RefreshMedalName(petInfo)
  local isMimic, MimicType, buffInfo = self:CheckIsMimic()
  if not isMimic and self.medalConf and self.medalConf.prefix_text then
    self.medalName = self.medalConf.prefix_text .. self.name
  else
    self.medalName = self.name
  end
end

function BattleCard:GetMedalFxBlackBoard()
  if self.medalConf and self.petInfo then
    if self.medalConf.can_repeat_get > 0 and self.medalConf.repeat_get_award and #self.medalConf.repeat_get_award > 0 then
      local fxCount = self.medalConf.repeat_get_award[1].count or 0
      local count = self.petInfo.battle_common_pet_info.medal_complete_cnt
      if fxCount <= count and self.medalConf.repeat_get_award[1].fx_res_2 then
        return self.medalConf.repeat_get_award[1].fx_res_2
      end
    end
    if self.medalConf.fx_res then
      return self.medalConf.fx_res
    end
  end
end

function BattleCard:RefreshByInfoAndBaseConf(petInfo, baseConfID)
  self:RefreshByBaseConf(baseConfID)
  self:RefreshName(petInfo)
end

function BattleCard:RefreshByBaseConf(baseConfID)
  self:InitByPetBaseID(baseConfID)
end

function BattleCard:InitByPetBaseID(baseID)
  local conf = _G.DataConfigManager:GetPetbaseConf(baseID)
  if not conf then
    Log.Error("pet base config not found : ", baseID)
  end
  self.petBaseConf = conf
  if not self.petBaseConf then
    Log.Error("BattleCard InitByPet fail,cannt find petBaseConf:", configID)
    return
  end
  self:OnPetBaseConfChanged()
end

function BattleCard:OnPetBaseConfChanged()
  self:RefreshName(self.petInfo)
  self:RefreshResource()
  self:InitAppearancePath()
end

function BattleCard:ReplaceByServerPetData(commonInfo)
  if commonInfo then
    self.petInfo.battle_common_pet_info = commonInfo
  end
end

function BattleCard:RefreshByServerPetData()
  self:RefreshBasicData()
  self:RefreshMutationTypeDataByConfig()
end

function BattleCard:_CheckPetInfoValid(petInfo)
  if not petInfo then
    Log.Error("BattleCard:RefreshByServer\230\178\161\230\156\137petInfo\239\188\140\230\151\160\230\179\149\230\155\180\230\150\176\230\149\176\230\141\174")
    return false
  end
  if not petInfo.battle_inside_pet_info then
    Log.Error("BattleCard:RefreshByServer\230\178\161\230\156\137battle_inside_pet_info\239\188\140\230\151\160\230\179\149\230\155\180\230\150\176\230\149\176\230\141\174")
    return false
  end
  if self.guid and petInfo.battle_inside_pet_info.pet_id ~= self.guid then
    Log.ErrorFormat("RefreshByServer Error, guid (self: %d, server: %d) not match", self.guid, petInfo.battle_inside_pet_info.pet_id or 0)
    return false
  end
  return true
end

function BattleCard:ReplaceByServer(petInfo)
  if not self:_CheckPetInfoValid(petInfo) then
    return
  end
  local curDataLevel = self.petInfo and self.petInfo.data_level
  local incomingDataLevel = petInfo.data_level
  if curDataLevel and incomingDataLevel then
    if curDataLevel >= incomingDataLevel and petInfo.full_for_data_level then
      self.petInfo = petInfo
    else
      self:OverwriteByServer(petInfo)
    end
  else
    self.petInfo = petInfo
  end
  self:ModifyPetInfoByBattleCmdPushbackData()
end

function BattleCard:OverwriteByServer(petInfo)
  self:InternalOverwriteByServer(petInfo)
  self:ModifyPetInfoByBattleCmdPushbackData()
end

function BattleCard:InternalOverwriteByServer(petInfo)
  if petInfo.battle_common_pet_info then
    if not self.petInfo.battle_common_pet_info then
      self:ReplaceByServerPetData(petInfo.battle_common_pet_info)
    else
      for k, v in pairs(petInfo.battle_common_pet_info) do
        self.petInfo.battle_common_pet_info[k] = v
      end
    end
  end
  if petInfo.battle_inside_pet_info then
    if not self.petInfo.battle_inside_pet_info then
      self.petInfo.battle_inside_pet_info = petInfo.battle_inside_pet_info
    else
      for k, v in pairs(petInfo.battle_inside_pet_info) do
        self.petInfo.battle_inside_pet_info[k] = v
      end
    end
  end
  if petInfo.req then
    if not self.petInfo.req then
      self.petInfo.req = petInfo.req
    else
      for k, v in pairs(petInfo.req) do
        self.petInfo.req[k] = v
      end
    end
  end
end

function BattleCard:ModifyPetInfoByBattleCmdPushbackData()
  local battleInfoManager = _G.BattleManager.battleInfoManager
  local petId = self.guid
  local roundPetInfo = battleInfoManager:GetBattlePetInfoFromPushPopByPetId(petId)
  local petInfo = roundPetInfo and roundPetInfo.petInfo
  if petInfo then
    self:InternalOverwriteByServer(petInfo)
  end
end

function BattleCard:RefreshByServer()
  local petInfo = self.petInfo
  local commonInfo = self.petInfo.battle_common_pet_info
  local battleInfo = self.petInfo.battle_inside_pet_info
  self:RefreshAttr(battleInfo)
  self.skillRoundData = battleInfo.skill_round_data
  self:RefreshByServerPetData()
  self:RefreshStateBit(battleInfo)
  self:RefreshMedal(petInfo)
  self.medalBlackBoard = self:GetMedalFxBlackBoard()
  if self:IsEnemy() and not BattleUtils.IsTeam() then
    self.IsFirstMeet = PetUtils.IsPlayerFirstMeetPet(_G.BattleManager.battlePawnManager.playerTeam.player, battleInfo.pet_id)
  else
    self.IsFirstMeet = false
  end
  if self.hp > 0 then
    self.petState:SetDead(false)
  else
    self.petState:SetDead(true)
  end
  if self.bInBattleField then
    self.pos = battleInfo.pos
    Log.Debug("pet is in battle:", petInfo.battle_inside_pet_info.pet_id)
  else
    self.pos = -1
    Log.Debug("pet is not in battle:", petInfo.battle_inside_pet_info.pet_id)
  end
  if self.petBaseConf then
    if battleInfo.base_conf_id ~= self.petBaseConf.id then
      local isMimic, MimicType = self:CheckIsMimic()
      if not isMimic or MimicType ~= ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC then
        self:RefreshByInfoAndBaseConf(petInfo, petInfo.battle_inside_pet_info.base_conf_id)
      else
        self:RefreshName(petInfo)
      end
    else
      self:RefreshName(petInfo)
    end
  else
    self:RefreshName(petInfo)
  end
end

function BattleCard:GetEnergy()
  return self.petInfo.battle_common_pet_info.energy
end

function BattleCard:IsEnemy()
  return self.owner:IsEnemy()
end

function BattleCard:IsObserver()
  return self.owner:IsObserver()
end

function BattleCard:IsSpectator()
  return self.owner:IsSpectator()
end

function BattleCard:IsMyself()
  return self.owner:IsMyself()
end

function BattleCard:IsTeammate()
  return self.owner:IsTeammate()
end

function BattleCard:Die(deadInfo)
  if not self.petState:GetDead() then
    if deadInfo then
      self.petState:SetDeadType(deadInfo.dead_type or ProtoEnum.BattleDeadInfo.DeadType.NORMAL_DEAD)
    end
    self.petState:SetDead(true)
    self:SetHpValue(0)
    self.owner:OnPetDead(self)
  end
end

function BattleCard:RefreshSkillByServer(skills)
  local battlePetInfo = {}
  local insideInfo = {}
  insideInfo.skill_round_data = skills
  battlePetInfo.battle_inside_pet_info = insideInfo
  self:OverwriteByServer(battlePetInfo)
  self:RefreshByServer()
end

function BattleCard:RefreshAttrItemByServer(attrType, attrValue)
  local prevPetInfo = self.petInfo
  local prevInsideInfo = prevPetInfo and prevPetInfo.battle_inside_pet_info
  local prevAttr = prevInsideInfo and prevInsideInfo.battle_attr or {}
  local nextAttr = {}
  table.copy(prevAttr, nextAttr)
  nextAttr[attrType + 1] = attrValue
  local battlePetInfo = {}
  local insideInfo = {}
  insideInfo.battle_attr = nextAttr
  battlePetInfo.battle_inside_pet_info = insideInfo
  self:OverwriteByServer(battlePetInfo)
end

function BattleCard:RefreshAttr(battleInfo)
  self.max_hp = PetUtils.GetMaxHP(battleInfo)
  self:SetHpValue(PetUtils.GetHP(battleInfo))
  self.max_shield, self.shield = PetUtils.GetNightMareShield(battleInfo)
  self.isNightMarePet = PetUtils.CheckIsNightMarePet(battleInfo)
  self.haveNightMareShield = PetUtils.CheckHasNightMareShield(battleInfo)
  self.isSurpriseBoxPet = PetUtils.CheckIsSurpriseBoxPet(battleInfo.base_conf_id)
  self.haveSurpriseBoxShield = PetUtils.CheckHasSurpriseShield(battleInfo)
  if self.max_hp < self.hp then
    Log.Error("zgx \229\174\160\231\137\169\231\154\132\229\189\147\229\137\141\232\161\128\233\135\143\233\171\152\228\186\142\230\156\128\229\164\167\232\161\128\233\135\143\239\188\129\239\188\129\239\188\129 \233\156\128\232\166\129\229\144\142\229\143\176\230\163\128\230\159\165\230\149\176\230\141\174\231\154\132\229\144\136\231\144\134\230\128\167\239\188\129\239\188\129", self.max_hp, self.hp, self.name)
    self.max_hp = self.hp
  end
end

function BattleCard:RefreshStateBit(battleInfo)
  self.bInBattleField = BattleUtils.GetInBattle(battleInfo)
  self.bBeCatch = BattleUtils.GetBeCatch(battleInfo)
  self:UpdatePetState()
end

function BattleCard:UpdatePetState()
  self.petState:SetSilent(BattleUtils.GetIsBanSkill(self.petInfo.battle_inside_pet_info))
  self:SetBeRidOf(BattleUtils.GetIsRidOf(self.petInfo.battle_inside_pet_info))
end

function BattleCard:Update(syncInfo)
end

function BattleCard:GetHpPercent()
  return PetUtils._DoGetPercent(self.hp, self.max_hp)
end

function BattleCard:GetHp()
  return self.hp
end

function BattleCard:GetMaxHp()
  return self.max_hp
end

function BattleCard:GetFrozenPercent()
  local killAtHp = self.petInfo.battle_inside_pet_info and self.petInfo.battle_inside_pet_info.kill_info and self.petInfo.battle_inside_pet_info.kill_info.kill_at_hp or 0
  return PetUtils._DoGetPercent(killAtHp, self.max_hp)
end

function BattleCard:GetSpeed()
  return PetUtils.GetSpeed(self.petInfo.battle_inside_pet_info)
end

function BattleCard:GetSpeedMinMax()
  return PetUtils.GetSpeedMinMax(self.petInfo.battle_inside_pet_info)
end

function BattleCard:GetShield()
  return self.shield
end

function BattleCard:GetMaxShield()
  return self.max_shield
end

function BattleCard:CanSummon()
  if self:IsModelInBattle() then
    return false
  end
  if self.hp <= 0 then
    return false
  end
  return true
end

function BattleCard:IsCanSelect()
  return not self:IsCheerPet() and not self:IsPetInPrepareZone() and self:IsExistAtField()
end

function BattleCard:IsExistAtField()
  return self:IsModelInBattle() and not self:IsBeCatch() and self:IsAlive() and self:HasBattlePetModel() and not self:WillMove()
end

function BattleCard:IsInBattle()
  return self.bInBattleField
end

function BattleCard:SetInBattleField(InBattleField)
  self.bInBattleField = InBattleField
end

function BattleCard:GetIsRunAway()
  return BattleUtils.GetIsRunAway(self.petInfo.battle_inside_pet_info)
end

function BattleCard:IsModelInBattle()
  return self:IsInBattle() and not self:IsBeRidOf()
end

function BattleCard:WillMove()
  return self.WillMove1VN
end

function BattleCard:SetWillMove(willMove)
  self.WillMove1VN = willMove
end

function BattleCard:IsBeCatch()
  return self.bBeCatch
end

function BattleCard:SetBeCatch(catch)
  self.bBeCatch = catch
end

function BattleCard:IsBeRidOf()
  return self.petState:GetBeRidOf()
end

function BattleCard:SetBeRidOf(isRidOf)
  self.petState:SetBeRidOf(isRidOf)
end

function BattleCard:SetPosInField(nextValue)
  self.posInField = nextValue
end

function BattleCard:GetPosInField()
  return self.posInField
end

function BattleCard:RefreshPosInFieldWithPos()
  local pos = self.pos
  self:SetPosInField(pos)
end

function BattleCard:HideBuffBar()
  if self.BattlePet then
    self.BattlePet:ChangeBuffVisibility(false)
  end
end

function BattleCard:IsAlive()
  if self:IsInBattle() then
    return not self.petState:GetDead()
  end
  return self:CanSummon()
end

function BattleCard:RecallBattlePet(pet)
  if pet then
    _G.BattleManager.battlePawnManager:RecallBattlePet(pet.team, pet)
  end
  self:SetInBattleField(false)
end

function BattleCard:SummonBattlePet(teamEnm, team, index)
  self:SetInBattleField(true)
  _G.BattleManager.battlePawnManager:SummonBattlePet(teamEnm, team, {
    {pet_pos = index}
  }, {self})
end

function BattleCard:ChangeHp(changeValue)
  self:SetHpValue(math.clamp(self.hp + changeValue, 0, self.max_hp))
end

function BattleCard:SetHpValue(hpValue)
  self.hp = hpValue
end

function BattleCard:GetBuffs()
  return self.petInfo.battle_inside_pet_info.buffs
end

function BattleCard:ClearBuffs()
  self.petInfo.battle_inside_pet_info.buffs = {}
end

function BattleCard:ChangeBuffInfo(buffInfo)
  local buffs = self:GetBuffs()
  if not buffs then
    Log.Debug(self.name, "\232\186\171\228\184\138buff\229\136\151\232\161\168\228\184\186\231\169\186")
    return
  end
  for i, buff in ipairs(buffs) do
    if buff.buff_id == buffInfo.buff_id then
      buffs[i] = buffInfo
      return
    end
  end
end

local function DisplaySkillSorter(a, b)
  if a.type == b.type then
    if a.pos == b.pos then
      if a.state == b.state then
        return false
      else
        return a.state == _G.ProtoEnum.SkillState.SKILL_READY and true or false
      end
    else
      return a.pos < b.pos
    end
  else
    return a.type < b.type
  end
end

function BattleCard:GetDisplaySkillsForShowPetInfo()
  local Skills = {}
  if not self.skillRoundData then
    return Skills
  end
  for i, Skill in ipairs(self.skillRoundData) do
    if Skill.priority_display then
      table.insert(Skills, Skill)
    elseif Skill.type == ProtoEnum.SkillActiveType.SAT_NORMAL then
      table.insert(Skills, Skill)
    elseif Skill.type == ProtoEnum.SkillActiveType.SAT_ULTIMATE then
      table.insert(Skills, Skill)
    elseif Skill.type == Enum.SkillActiveType.SAT_LEGENDARY then
      table.insert(Skills, Skill)
    end
  end
  table.sort(Skills, DisplaySkillSorter)
  return Skills
end

function BattleCard:GetDisplaySkills()
  local Skills = {}
  if not self.skillRoundData then
    return Skills
  end
  for i, Skill in ipairs(self.skillRoundData) do
    if Skill.type == ProtoEnum.SkillActiveType.SAT_NORMAL then
      table.insert(Skills, Skill)
    elseif Skill.type == ProtoEnum.SkillActiveType.SAT_ULTIMATE then
      table.insert(Skills, Skill)
    elseif Skill.type == Enum.SkillActiveType.SAT_LEGENDARY then
      table.insert(Skills, Skill)
    end
  end
  table.sort(Skills, DisplaySkillSorter)
  return Skills
end

function BattleCard:GetDisplayAndReadySkills()
  local Skills = {}
  if not self.skillRoundData then
    return Skills
  end
  for i, Skill in ipairs(self.skillRoundData) do
    if Skill.type == ProtoEnum.SkillActiveType.SAT_NORMAL and Skill.state == _G.ProtoEnum.SkillState.SKILL_READY then
      table.insert(Skills, Skill)
    elseif Skill.type == ProtoEnum.SkillActiveType.SAT_ULTIMATE and Skill.state == _G.ProtoEnum.SkillState.SKILL_READY then
      table.insert(Skills, Skill)
    end
  end
  table.sort(Skills, DisplaySkillSorter)
  return Skills
end

function BattleCard:GetDisplaySkillRoundData()
  local displaySkills = self:GetDisplaySkills()
  local roundData = {}
  for _, displaySkill in ipairs(displaySkills) do
    for _, data in ipairs(self.skillRoundData) do
      if displaySkill.id == data.id then
        table.insert(roundData, data)
      end
    end
  end
  return roundData
end

function BattleCard:GetDisplaySkillsForEnemy(bAllowHiddenSkill)
  return PetUtils.GetBattleSkills(self.petInfo.battle_inside_pet_info, bAllowHiddenSkill)
end

function BattleCard:GetSkillRounds(flag)
  local skills = {}
  if not self.skillRoundData then
    return skills
  end
  for _, skill in ipairs(self.skillRoundData) do
    if skill.flag & flag > 0 then
      table.insert(skills, skill)
    end
  end
  table.sort(skills, DisplaySkillSorter)
  return skills
end

function BattleCard:GetPetType()
  return PetUtils.GetPetTypes(self.petInfo.battle_inside_pet_info)
end

function BattleCard:SetPetType(battle_attr)
  self.petInfo.battle_inside_pet_info.battle_attr = battle_attr
  self:RefreshAttr(self.petInfo.battle_inside_pet_info)
end

function BattleCard:GetCatchRateByBallID(ballID)
  local InsideInfo = self.petInfo.battle_inside_pet_info
  if not InsideInfo or not InsideInfo.catch_info then
    return 0
  end
  local CatchRates = InsideInfo.catch_info.catch_prob_list
  if not CatchRates or 0 == #CatchRates then
    return 0
  end
  for _, Prob in ipairs(CatchRates) do
    if Prob.ball_id == ballID then
      return Prob.catch_prob
    end
  end
  return 0
end

function BattleCard:GetCatchAnimByCatchRate(Rate)
  return BattleUtils.GetCatchRateAnim(Rate)
end

function BattleCard:GetName()
  return self.name
end

function BattleCard:GetRestraint()
  local Skills = self:GetDisplaySkills()
  local result = 0
  local weakResult = 0
  local checkSkillNum = 0
  local doubleRestraintAnyPetSkillCount = 0
  local restraintAnyPetSkillCount = 0
  local doubleWeakSkillCount = 0
  local weakSkillCount = 0
  local restraintTypeNoneSkillCount = 0
  if Skills then
    for _, v in ipairs(Skills) do
      local type = BattleUtils:GetSkillRestraint(v)
      if type ~= BattleEnum.TypeRestraint.ENUM_NONE then
        checkSkillNum = checkSkillNum + 1
        if type == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
          restraintAnyPetSkillCount = restraintAnyPetSkillCount + 1
        elseif type == BattleEnum.TypeRestraint.ENUM_RESTRAINT_DOUBLE then
          restraintAnyPetSkillCount = restraintAnyPetSkillCount + 1
          doubleRestraintAnyPetSkillCount = doubleRestraintAnyPetSkillCount + 1
        elseif type == BattleEnum.TypeRestraint.ENUM_NORMAL then
          if v.restraint_types then
            restraintTypeNoneSkillCount = restraintTypeNoneSkillCount + 1
          end
        elseif type == BattleEnum.TypeRestraint.ENUM_WEAK then
          weakSkillCount = weakSkillCount + 1
        elseif type == BattleEnum.TypeRestraint.ENUM_WEAK_DOUBLE then
          weakSkillCount = weakSkillCount + 1
          doubleWeakSkillCount = doubleWeakSkillCount + 1
        end
      end
    end
  end
  if 0 == checkSkillNum then
    return BattleEnum.TypeRestraint.ENUM_NONE
  end
  if doubleRestraintAnyPetSkillCount > 0 then
    return BattleEnum.TypeRestraint.ENUM_RESTRAINT_DOUBLE
  elseif restraintAnyPetSkillCount > 0 then
    return BattleEnum.TypeRestraint.ENUM_RESTRAINT
  elseif doubleWeakSkillCount == checkSkillNum then
    return BattleEnum.TypeRestraint.ENUM_WEAK_DOUBLE
  elseif weakSkillCount == checkSkillNum then
    return BattleEnum.TypeRestraint.ENUM_WEAK
  else
    return BattleEnum.TypeRestraint.ENUM_NORMAL
  end
  return BattleEnum.TypeRestraint.ENUM_NONE
end

function BattleCard:UpdateStateByAddingBuff(buffConf)
  for _, sign in ipairs(buffConf.buff_groupsigns) do
    local filter = PetUtils.FilterSign(sign)
    if filter then
      self.petState:OpenState(sign)
    end
  end
end

function BattleCard:UpdateStateByRemovingBuff(buffConf)
  local stateLst = {}
  for _, sign in ipairs(buffConf.buff_groupsigns) do
    local filter = PetUtils.FilterSign(sign)
    if filter then
      self.petState:CloseState(sign)
      if not self.petState:GetStateBySign(sign) then
        table.insert(stateLst, sign)
      end
    end
  end
  return stateLst
end

function BattleCard:CheckIsMimic(isInited)
  if isInited then
    return self.petState:GetMimic()
  else
    local isMimic, sign, buff = PetUtils.DoCheckIsMimic(self.petInfo.battle_inside_pet_info)
    if isMimic then
      return isMimic, sign, buff
    end
    return self.petState:GetMimic() or false
  end
end

function BattleCard:CheckIsSurpriseBox(isInited)
  if isInited then
    return self.petState:GetSurpriseBox()
  else
    local isMimic, sign, buff = PetUtils.DoCheckIsSurpriseBox(self.petInfo.battle_inside_pet_info)
    if isMimic then
      return isMimic, sign, buff
    end
    return self.petState:GetSurpriseBox() or false
  end
end

function BattleCard:GetMonsterConfigIsNightmareValue()
  return self.config and self.isMonster and self.config.is_nightmare
end

function BattleCard:CheckCanMoveBeforePawn()
  if not self.petInfo then
    return false
  end
  local buffInfos = self.petInfo.battle_inside_pet_info.buffs
  if buffInfos then
    for _, buff in ipairs(buffInfos) do
      local config = _G.DataConfigManager:GetBuffConf(buff.buff_id)
      if config then
        for _, sign in ipairs(config.buff_groupsigns) do
          if sign == Enum.BuffGroupSign.BGS_BACKSTAB or sign == Enum.BuffGroupSign.BGS_SLEEP or sign == Enum.BuffGroupSign.BGS_DRILL or sign == Enum.BuffGroupSign.BGS_STATIC or sign == Enum.BuffGroupSign.BGS_MIMIC or sign == Enum.BuffGroupSign.BGS_BATTLE_MIMIC or sign == Enum.BuffGroupSign.BGS_HIDE or sign == Enum.BuffGroupSign.BGS_LEADERDIZZY or sign == Enum.BuffGroupSign.BGS_MAGICDIZZY or sign == Enum.BuffGroupSign.BGS_CATCHSTUN then
            return false
          end
        end
      end
    end
  end
  return true
end

function BattleCard:GetBuffConfByGroupSign(groupSign)
  local buffInfos = self.petInfo.battle_inside_pet_info.buffs
  if buffInfos then
    for _, buff in ipairs(buffInfos) do
      local config = _G.DataConfigManager:GetBuffConf(buff.buff_id)
      if config then
        for _, sign in ipairs(config.buff_groupsigns) do
          if sign == groupSign then
            return config
          end
        end
      end
    end
  end
end

function BattleCard:GetBuffInfoByGroupSign(groupSign)
  local buffInfos = self.petInfo.battle_inside_pet_info.buffs
  if buffInfos then
    for _, buff in ipairs(buffInfos) do
      local config = _G.DataConfigManager:GetBuffConf(buff.buff_id)
      if config then
        for _, sign in ipairs(config.buff_groupsigns) do
          if sign == groupSign then
            return buff
          end
        end
      end
    end
  end
end

function BattleCard:GetMasterPet()
  if self:IsCheerPet() then
    local myFlag = math.floor(self.petInfo.battle_inside_pet_info.cheers_tag / 10)
    if self.owner then
      local pets = self.owner.team.pets
      for _, v in pairs(pets) do
        if not v.card:IsCheerPet() and math.floor(v.card.petInfo.battle_inside_pet_info.cheers_tag / 10) == myFlag then
          return v
        end
      end
    end
  end
end

function BattleCard:IsCheerPet()
  local flag = self.petInfo.battle_inside_pet_info.cheers_tag
  return flag and 0 ~= flag % 10
end

function BattleCard:IsPetInPrepareZone()
  local petInfo = self.petInfo
  local battle_inside_pet_info = petInfo and petInfo.battle_inside_pet_info
  local isPetPrepare = BattleUtils.GetIsPetPrepare(battle_inside_pet_info)
  return isPetPrepare
end

function BattleCard:IsMyCheer(card)
  if card:IsCheerPet() and not self:IsCheerPet() then
    local myFlag = math.floor(self.petInfo.battle_inside_pet_info.cheers_tag / 10)
    local petFlag = math.floor(card.petInfo.battle_inside_pet_info.cheers_tag / 10)
    return myFlag == petFlag
  end
  return false
end

function BattleCard:GetCheerPets()
  local results = {}
  if self.owner and self.owner.deck and self.petInfo then
    local cards = self.owner.deck.cards or {}
    local myFlag = math.floor(self.petInfo.battle_inside_pet_info.cheers_tag / 10)
    for _, v in ipairs(cards) do
      if v:IsCheerPet() and v ~= self and math.floor(v.petInfo.battle_inside_pet_info.cheers_tag / 10) == myFlag and v:IsExistAtField() then
        table.insert(results, v)
      end
    end
  end
  return results
end

function BattleCard:HasBattlePetModel()
  if self.BattlePet and self.BattlePet.model then
    return true
  end
  return false
end

function BattleCard:ChangeBuffData(buffChange, sync_data)
  local buffs = self.petInfo.battle_inside_pet_info.buffs or {}
  local buff_id = buffChange.buff_id
  if not buff_id or 0 == buff_id then
    Log.Error("Can't find valid buff id: ", buff_id)
    Log.Dump(buffChange, 3, "Dumping wrong buff id")
    return
  end
  local changeType = buffChange.type
  local Conf = _G.DataConfigManager:GetBuffConf(buff_id)
  if not Conf then
    Log.Error("Can't find valid buff conf: ", buff_id)
    return
  end
  if changeType == ProtoEnum.BuffChangeType.BCT_ADD then
    local isFound = false
    for i, v in ipairs(buffs) do
      if v.buff_id == buffChange.buff_id then
        buffs[i] = buffChange.buff_info
        isFound = true
      end
    end
    if not isFound then
      table.insert(buffs, buffChange.buff_info)
    end
  elseif changeType == ProtoEnum.BuffChangeType.BCT_CHANGE then
    for i, v in ipairs(buffs) do
      if v.buff_id == buffChange.buff_id then
        buffs[i] = buffChange.buff_info
      end
    end
  elseif changeType == ProtoEnum.BuffChangeType.BCT_REMOVE then
    if not buffs then
      Log.Error("\229\176\157\232\175\149\231\167\187\233\153\164\228\184\141\229\173\152\229\156\168\231\154\132buff", buffChange.buff_id)
      return
    end
    for i, v in ipairs(buffs) do
      if v.buff_id == buffChange.buff_id then
        table.remove(buffs, i)
      end
    end
  elseif changeType == ProtoEnum.BuffChangeType.BCT_NULL then
  else
    Log.Error("BuffComponent ChangeBuffData invalid changeType:", changeType)
  end
  self.petInfo.battle_inside_pet_info.buffs = buffs
end

function BattleCard:GetCurrentGatherSkill()
  return self.petInfo.battle_inside_pet_info.charging_skill_id
end

function BattleCard:GetBallID()
  return self.petInfo.battle_common_pet_info.ball_id
end

function BattleCard:GetBallPath()
  return BattleUtils.GetPetBallPath(self.petInfo.battle_common_pet_info)
end

function BattleCard:GetBloodId()
  return self.petInfo.battle_common_pet_info.blood_id
end

function BattleCard:GetLevel()
  return self.petInfo.battle_common_pet_info.level
end

function BattleCard:GetPetbaseId()
  return self.petInfo.battle_common_pet_info.base_conf_id
end

function BattleCard:GetPetbaseConf()
  return _G.DataConfigManager:GetPetbaseConf(self.petInfo.battle_common_pet_info.base_conf_id)
end

function BattleCard:GetModelConf()
  local petBaseConf = self:GetPetbaseConf()
  return _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
end

function BattleCard:GetMutationType()
  return self.petInfo.battle_common_pet_info.mutation_type
end

function BattleCard:RefreshBasicData()
  local commonInfo = self.petInfo.battle_common_pet_info
  if commonInfo then
    self.lv = commonInfo.level
    self.energy = commonInfo.energy
  end
end

function BattleCard:RefreshMutationTypeDataByConfig()
  local commonInfo = self.petInfo.battle_common_pet_info
  local isNightmareValue = self:GetMonsterConfigIsNightmareValue()
  local extraMutationDiffType = isNightmareValue and BattleConst.MonsterIsNightmareValueToMutationDiffType[isNightmareValue]
  if commonInfo and extraMutationDiffType then
    local newMutationTypeValue = commonInfo.mutation_type
    newMutationTypeValue = newMutationTypeValue | extraMutationDiffType
    commonInfo.mutation_type = newMutationTypeValue
  end
end

function BattleCard:GetNature()
  return self.petInfo.battle_common_pet_info.nature
end

function BattleCard:GetShineColor()
  return self.petInfo.battle_common_pet_info.glass_info.glass_value
end

function BattleCard:ShowPopup(Info, target, callback)
  local isShow = false
  local type
  local popUpPlainText = ""
  if not self:CheckIsMimic() then
    if SkillUtils.IsBuff(Info.buff_id) then
      local BuffConf = _G.DataConfigManager:GetBuffConf(Info.buff_id)
      if not BuffConf then
        if target and callback then
          callback(target)
        end
        return
      end
      local buffBaseIds = BuffConf.buff_base_ids
      local buffBaseConf
      if buffBaseIds then
        buffBaseConf = _G.DataConfigManager:GetBuffbaseConf(buffBaseIds[1])
      end
      local check = false
      for _, sign in ipairs(BuffConf.buff_groupsigns) do
        if sign == ProtoEnum.BuffGroupSign.BGS_SPE then
          check = true
        end
      end
      if buffBaseConf then
        if buffBaseConf.buffbase_order == Enum.BuffType.BFT_O_TWEENTYSEVEN then
          check = true
          type = BattleEnum.InfoPopupType.PlainText
          local closeBuffText127 = _G.DataConfigManager:GetLocalizationConf("pet_close_buff_text_127")
          local closeBuffText127Msg = closeBuffText127 and closeBuffText127.msg or "%s"
          popUpPlainText = string.format(closeBuffText127Msg, self.name)
        elseif buffBaseConf.buffbase_order == Enum.BuffType.BFT_O_TWEENTYEIGHT then
          check = true
          type = BattleEnum.InfoPopupType.PlainText
          local closeBuffText128 = _G.DataConfigManager:GetLocalizationConf("pet_close_buff_text_128")
          local closeBuffText128Msg = closeBuffText128 and closeBuffText128.msg or "%s"
          popUpPlainText = string.format(closeBuffText128Msg, self.name)
          local internalCallback = callback
          if target and callback then
            callback = nil
            internalCallback(target)
          end
        end
      end
      if not BuffUtils.IsShowBuffOrLetter(self, BuffConf) then
        check = false
      end
      if not check then
        if target and callback then
          callback(target)
        end
        return
      end
      if nil == type then
        type = BattleEnum.InfoPopupType.UseBuff
      end
      isShow = true
    elseif SkillUtils.IsEffect(Info.buff_id) then
      type = BattleEnum.InfoPopupType.UseEffect
      isShow = true
    end
  end
  if isShow then
    if type == BattleEnum.InfoPopupType.PlainText then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        type,
        self.owner,
        popUpPlainText
      })
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        type,
        self.owner,
        self,
        Info
      })
    end
    self:TryCancelHidePopupDelay()
    self.hidePopupDelayId = _G.DelayManager:DelaySeconds(1, self.DelayHidePopupTimeOut, self, target, callback)
  elseif target and callback then
    callback(target)
  end
  return isShow
end

function BattleCard:TryCancelHidePopupDelay()
  local hidePopupDelayId = self.hidePopupDelayId
  if hidePopupDelayId then
    _G.DelayManager:CancelDelayById(hidePopupDelayId)
  end
  self.hidePopupDelayId = nil
end

function BattleCard:DelayHidePopupTimeOut(target, callback)
  self.hidePopupDelayId = nil
  self:HidePopup(target, callback)
end

function BattleCard:HidePopup(target, callback)
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.owner)
  if target and callback then
    callback(target)
  end
end

function BattleCard:Destroy()
  self:TryCancelHidePopupDelay()
  self.petInfo = nil
  self.petBaseConf = nil
  self.petState = nil
  self.ordinaryBaseConf = nil
  self.medalConf = nil
end

return BattleCard
