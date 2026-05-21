local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local HomePetAttributeComponent = require("NewRoco.Modules.System.Home.HomePetFeed.HomePetAttributeComponent")
local Enum = require("Data.Config.Enum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local TimeUtils = require("NewRoco.Modules.System.EnvSystem.TimeUtils")
local PetUtils = {}
PetUtils.iconBallPath = {}
PetUtils.iconBallPath[100002] = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_icon1_png.img_icon1_png'"
PetUtils.iconBallPath[100003] = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_icon2_png.img_icon2_png'"
PetUtils.iconBallPath[100255] = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_icon3_png.img_icon3_png'"
PetUtils.DamageToPetType = {
  [Enum.SkillDamType.SDT_GRASS] = 0,
  [Enum.SkillDamType.SDT_INSECT] = 1,
  [Enum.SkillDamType.SDT_DEMON] = 2,
  [Enum.SkillDamType.SDT_LIGHT] = 3,
  [Enum.SkillDamType.SDT_FIRE] = 4,
  [Enum.SkillDamType.SDT_COMMON] = 5,
  [Enum.SkillDamType.SDT_WATER] = 6,
  [Enum.SkillDamType.SDT_STONE] = 7,
  [Enum.SkillDamType.SDT_WING] = 8,
  [Enum.SkillDamType.SDT_GHOST] = 9,
  [Enum.SkillDamType.SDT_PHANTOM] = 10,
  [Enum.SkillDamType.SDT_ICE] = 11,
  [Enum.SkillDamType.SDT_ELECTRIC] = 12,
  [Enum.SkillDamType.SDT_TOXIC] = 13,
  [Enum.SkillDamType.SDT_FIGHT] = 14,
  [Enum.SkillDamType.SDT_MOE] = 15,
  [Enum.SkillDamType.SDT_DRAGON] = 16,
  [Enum.SkillDamType.SDT_MECHANIC] = 17,
  [Enum.SkillDamType.SDT_NONE] = 18
}
PetUtils.WorldCombatBuffToUIType = {
  [Enum.WorldcombatDoubleBuff.WDB_SPEDEF] = 0,
  [Enum.WorldcombatDoubleBuff.WDB_SPEATK] = 1,
  [Enum.WorldcombatDoubleBuff.WDB_HP] = 2,
  [Enum.WorldcombatDoubleBuff.WDB_SPEED] = 3,
  [Enum.WorldcombatDoubleBuff.WDB_PHYDEF] = 4,
  [Enum.WorldcombatDoubleBuff.WDB_PHYATK] = 5
}

function PetUtils.CreateFakePetData(petBaseId)
  if petBaseId and 0 ~= petBaseId then
    local petData = _G.ProtoMessage:newPetData()
    petData.gid = 0
    petData.base_conf_id = petBaseId
    petData.mutation_type = 0
    petData.blood_id = 0
    petData.level = 0
    return petData
  end
end

function PetUtils.GetHP(battle_inside_pet_info)
  if not battle_inside_pet_info.battle_attr then
    Log.Warning("\230\149\176\230\141\174\229\188\130\229\184\184\239\188\154 battle_inside_pet_info.battle_attr is nil")
    return 999
  end
  return battle_inside_pet_info.battle_attr[_G.ProtoEnum.AttributeType.AT_HPCUR + 1]
end

function PetUtils.GetMaxHP(battle_inside_pet_info)
  if not battle_inside_pet_info.battle_attr then
    Log.Warning("\230\149\176\230\141\174\229\188\130\229\184\184\239\188\154 battle_inside_pet_info.battle_attr is nil")
    return 999
  end
  return battle_inside_pet_info.battle_attr[_G.ProtoEnum.AttributeType.AT_HPMAX + 1]
end

function PetUtils.GetHPPercent(battle_inside_pet_info)
  local max = PetUtils.GetMaxHP(battle_inside_pet_info)
  local hp = PetUtils.GetHP(battle_inside_pet_info)
  return PetUtils._DoGetPercent(hp, max)
end

function PetUtils._DoGetPercent(hp, max)
  if 0 == max then
    max = 1
  end
  return math.clamp(hp / max, 0, 1)
end

function PetUtils.GetFrozenPercent(battle_inside_pet_info)
  local max = PetUtils.GetMaxHP(battle_inside_pet_info)
  local killAtHp = battle_inside_pet_info and battle_inside_pet_info.kill_info and battle_inside_pet_info.kill_info.kill_at_hp or 0
  return PetUtils._DoGetPercent(killAtHp, max)
end

function PetUtils._DoGetPercent(value, max)
  if 0 == max then
    max = 1
  end
  return math.clamp(value / max, 0, 1)
end

function PetUtils.GetSpeed(battle_inside_pet_info)
  if battle_inside_pet_info and battle_inside_pet_info.battle_attr then
    return battle_inside_pet_info.battle_attr[_G.Enum.AttributeType.AT_SPEED + 1] or 0
  end
  return 0
end

function PetUtils.GetSpeedMinMax(battle_inside_pet_info)
  if battle_inside_pet_info then
    local v1 = battle_inside_pet_info.speed_min or 0
    local v2 = battle_inside_pet_info.speed_max or 0
    return math.min(v1, v2), math.max(v1, v2)
  end
  return 0, 0
end

function PetUtils.GetNatureDes(pet_data)
  if pet_data and pet_data.nature and pet_data.nature_desc_id then
    local NatureConf = _G.DataConfigManager:GetNatureConf(pet_data.nature)
    local random_desc = NatureConf and NatureConf.random_desc or {}
    if #random_desc > 0 then
      for i, v in ipairs(random_desc) do
        if v.nature_id == pet_data.nature_desc_id then
          return v.nature_desc
        end
      end
    end
  end
  return pet_data.nature_desc or ""
end

function PetUtils.GetPetTypes(battle_inside_pet_info)
  local battle_attr = battle_inside_pet_info.battle_attr or {}
  local attr1 = battle_attr[Enum.AttributeType.AT_DAMTYPE1 + 1]
  local attr2 = battle_attr[Enum.AttributeType.AT_DAMTYPE2 + 1]
  local attr3 = battle_attr[Enum.AttributeType.AT_DAMTYPE3 + 1]
  return {
    attr1,
    attr2,
    attr3
  }
end

function PetUtils.GetPetTypesById(base_id)
  local conf = _G.DataConfigManager:GetPetbaseConf(base_id)
  local types = {}
  if conf and conf.unit_type then
    for i = 3, 1, -1 do
      if conf.unit_type[i] then
        table.insert(types, conf.unit_type[i])
      end
    end
  end
  return types
end

function PetUtils.GetPetGrowUpType(PetData)
  local RetType = PetUIModuleEnum.PetGrowUpType.None
  if nil == PetData then
    Log.Error("PetUtils.GetPetGrowUpType PetData is nil")
    return RetType
  end
  local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(PetData)
  if ResidueGrowCount > 0 then
    RetType = PetUIModuleEnum.PetGrowUpType.WaitToGrowUp
  else
    local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
    if BreakNumberAllConf then
      local MaxBreakThroughLevel = #BreakNumberAllConf
      if MaxBreakThroughLevel <= GrowOrder - 1 then
        if PetData.inspire_lv then
          local InspireLevelAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.INSPIRE_LEVEL_CONF):GetAllDatas()
          local MaxInspireLevel = #InspireLevelAllConf
          if MaxInspireLevel > PetData.inspire_lv then
            RetType = PetUIModuleEnum.PetGrowUpType.WaitToInspire
          else
            RetType = PetUIModuleEnum.PetGrowUpType.Max
          end
        else
          RetType = PetUIModuleEnum.PetGrowUpType.WaitToInspire
        end
      else
        RetType = PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough
      end
    end
  end
  return RetType
end

function PetUtils.GetPetEggConfigTypeByGID(EggGID)
  local ConfigType = PetUIModuleEnum.PetEggConfigType.None
  local PetEggConf
  if nil == EggGID then
    return ConfigType, PetEggConf
  end
  if 0 == EggGID then
    return ConfigType, PetEggConf
  end
  local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, EggGID)
  if nil == BagEggItem then
    return ConfigType, PetEggConf
  end
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(BagEggItem.id)
  if nil == BagItemConf then
    return ConfigType, PetEggConf
  end
  local EggData = BagEggItem.egg_data
  if nil == EggData then
    return ConfigType, PetEggConf
  end
  if EggData.src and EggData.src == _G.Enum.EggAcquireWayType.EAWT_BLESSING then
    ConfigType = PetUIModuleEnum.PetEggConfigType.BlessingEgg
    PetEggConf = _G.DataConfigManager:GetPetEggConf(EggData.conf_id)
    return ConfigType, PetEggConf
  end
  if 0 == EggData.conf_id and EggData.random_egg_conf then
    ConfigType = PetUIModuleEnum.PetEggConfigType.RandomEgg
    PetEggConf = _G.DataConfigManager:GetPetRandomEggConf(EggData.random_egg_conf)
    return ConfigType, PetEggConf
  end
  if 0 ~= EggData.conf_id then
    ConfigType = PetUIModuleEnum.PetEggConfigType.NormalEgg
    PetEggConf = _G.DataConfigManager:GetPetEggConf(EggData.conf_id)
    return ConfigType, PetEggConf
  end
  return ConfigType, PetEggConf
end

function PetUtils.GetPetEggAppearanceType(EggGID)
  local RetType = PetUIModuleEnum.PetEggAppearanceType.None
  if nil == EggGID then
    return RetType
  end
  local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, EggGID)
  if nil == BagEggItem then
    return RetType
  end
  local EggData = BagEggItem.egg_data
  if nil == EggData then
    return RetType
  end
  local PreciousEggType
  local PetEggConfigType, PetEggConfig = PetUtils.GetPetEggConfigTypeByGID(EggGID)
  if PetEggConfig then
    PreciousEggType = PetEggConfig.precious_egg_type
  end
  if EggData.precious_egg_type then
    PreciousEggType = EggData.precious_egg_type
  end
  if PreciousEggType then
    if PreciousEggType == _G.Enum.PreciousEggType.PET_SHINING then
      RetType = PetUIModuleEnum.PetEggAppearanceType.VisiblyShining
    elseif PreciousEggType == _G.Enum.PreciousEggType.PET_SHINING_GLASS then
      RetType = PetUIModuleEnum.PetEggAppearanceType.VisiblyGlassAndShining
    elseif PreciousEggType == _G.Enum.PreciousEggType.PET_GLASS then
      RetType = PetUIModuleEnum.PetEggAppearanceType.VisiblyGlass
    elseif PreciousEggType == _G.Enum.PreciousEggType.PET_PARTNER then
      RetType = PetUIModuleEnum.PetEggAppearanceType.VisiblyGlass
    elseif PreciousEggType == _G.Enum.PreciousEggType.PET_PRECIOUS then
      if EggData.mutation_type == _G.Enum.MutationDiffType.MDT_GLASS then
        RetType = PetUIModuleEnum.PetEggAppearanceType.VisiblyGlass
      end
    elseif PreciousEggType == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
      RetType = PetUIModuleEnum.PetEggAppearanceType.CustomGlass
    end
    if EggData.mutation_type == _G.Enum.MutationDiffType.MDT_CHAOS or EggData.mutation_type == _G.Enum.MutationDiffType.MDT_CHAOS_TWO or EggData.mutation_type == _G.Enum.MutationDiffType.MDT_CHAOS_THREE then
      RetType = PetUIModuleEnum.PetEggAppearanceType.Chaos
    end
  end
  return RetType
end

function PetUtils.CheckIsBanFreePet(petData)
  local IsBanFreePet = false
  if nil == petData then
    return IsBanFreePet
  end
  if nil == petData.base_conf_id then
    return IsBanFreePet
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  if nil == petBaseConf then
    return IsBanFreePet
  end
  if petBaseConf.ban_free and 1 == petBaseConf.ban_free then
    IsBanFreePet = true
    return IsBanFreePet
  end
  return IsBanFreePet
end

function PetUtils.CheckIsForbidSelectPetInFreeMode(PetGID, bShowTips)
  local IsForbidSelectPetInFreeMode = false
  if nil == PetGID then
    return IsForbidSelectPetInFreeMode
  end
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetGID)
  if nil == PetData then
    return IsForbidSelectPetInFreeMode
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    local IsInHome = false
    if PetData.business_identity and PetData.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET then
      IsInHome = true
    end
    local IsInGuard = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePlantGuardPetGid) == PetGID
    if IsInHome or IsInGuard then
      IsForbidSelectPetInFreeMode = true
      if bShowTips then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_pet_cannot_free)
      end
    end
    if PetUtils.CheckIsBanFreePet(PetData) then
      IsForbidSelectPetInFreeMode = true
      if bShowTips and PetData and PetData.base_conf_id then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petbag_2 .. petBaseConf.name .. LuaText.umg_petbag_3)
      end
    end
    local IsInActivity = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.IsPetInCurTripInfo, PetData.gid)
    if IsInActivity then
      IsForbidSelectPetInFreeMode = true
      if bShowTips then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_trip_54)
      end
    end
  end
  return IsForbidSelectPetInFreeMode
end

function PetUtils.IsPartialShow(battle_inside_pet_info)
  if not battle_inside_pet_info then
    return false
  end
  local playerTeam = _G.BattleManager.battlePawnManager.playerTeam
  if not playerTeam then
    return false
  end
  local player = playerTeam.player
  if not player then
    return false
  end
  local bIsFirstMeet = PetUtils.IsPlayerFirstMeetPet(player, battle_inside_pet_info.pet_id)
  if bIsFirstMeet then
    return true
  end
  local bIsMimic = PetUtils.HasBuff(battle_inside_pet_info, Enum.BuffGroupSign.BGS_MIMIC)
  if bIsMimic then
    return true
  end
  return false
end

function PetUtils.FilterSign(sign)
  local filter = sign ~= Enum.BuffGroupSign.BGS_HIDE and sign ~= Enum.BuffGroupSign.BGS_NONE
  return filter
end

function PetUtils.HasBuff(battle_inside_pet_info, sign)
  if battle_inside_pet_info then
    local buffs = battle_inside_pet_info.buffs
    if buffs then
      for iBuff = 1, #buffs do
        local buff = buffs[iBuff]
        local conf = _G.DataConfigManager:GetBuffConf(buff.buff_id)
        if conf then
          for iSign = 1, #conf.buff_groupsigns do
            local signToCompare = conf.buff_groupsigns[iSign]
            local filter = PetUtils.FilterSign(signToCompare)
            if filter and signToCompare == sign then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function PetUtils.IsPlayerFirstMeetPet(player, petId)
  if not PetUtils.CheckPlayerFirstMeetPetFunctionEnable() then
    return false
  end
  local isFirstMeet = true
  if player and player.roleInfo and player.roleInfo.base then
    local noMetPets = player.roleInfo.base.first_seen_pets or {}
    isFirstMeet = table.contains(noMetPets, petId)
  end
  if PetUtils.IsPvp() then
    isFirstMeet = false
  end
  return isFirstMeet
end

function PetUtils.CheckPlayerFirstMeetPetFunctionEnable()
  return false
end

function PetUtils.IsPvp()
  local battleType = _G.BattleManager.battleRuntimeData.battleType
  local EBattleType = Enum.BattleType
  return battleType == EBattleType.BT_PVP or battleType == EBattleType.BT_PVP_SRANDARD or battleType == EBattleType.BT_PVP_RANDOM or battleType == EBattleType.BT_PVP_WATER or battleType == EBattleType.BT_PVP_INSECT or battleType == EBattleType.BT_PVP_RANK or battleType == EBattleType.BT_PVP_THREE or battleType == EBattleType.BT_PVP_SCARE
end

function PetUtils.GetTeamEnum(petInfo)
  if not petInfo then
    return BattleEnum.Team.ENUM_OBSERVER
  end
  local owner_uin = petInfo.role_uin
  if PetUtils.IsInBattleTeam(owner_uin, _G.BattleManager.battlePawnManager.playerTeam) then
    return BattleEnum.Team.ENUM_TEAM
  end
  if PetUtils.IsInBattleTeam(owner_uin, _G.BattleManager.battlePawnManager.enemyTeam) then
    return BattleEnum.Team.ENUM_ENEMY
  end
  local allPlayerTeam = _G.BattleManager.battlePawnManager.AllPlayerTeam
  if not allPlayerTeam then
    return BattleEnum.Team.ENUM_OBSERVER
  end
  for i = 1, #allPlayerTeam do
    local team = allPlayerTeam[i]
    if PetUtils.IsInBattleTeam(owner_uin, team) then
      return BattleEnum.Team.ENUM_TEAM
    end
  end
  local allEnemyTeam = _G.BattleManager.battlePawnManager.AllEnemyTeam
  if not allEnemyTeam then
    return BattleEnum.Team.ENUM_OBSERVER
  end
  for i = 1, #allEnemyTeam do
    local team = allEnemyTeam[i]
    if PetUtils.IsInBattleTeam(owner_uin, team) then
      return BattleEnum.Team.ENUM_ENEMY
    end
  end
end

function PetUtils.IsInBattleTeam(role_uin, team)
  if role_uin and team and team.player and role_uin == team.player.guid then
    return true
  end
  return false
end

function PetUtils.IsMyself(petInfo)
  if PetUtils.IsInBattleTeam(petInfo.role_uin, _G.BattleManager.battlePawnManager.playerTeam) then
    return true
  end
end

function PetUtils.IsTeammate(petInfo)
  local myTeam = _G.BattleManager.battlePawnManager.playerTeam
  local allPlayerTeam = _G.BattleManager.battlePawnManager.AllPlayerTeam
  if allPlayerTeam then
    for i = 1, #allPlayerTeam do
      local team = allPlayerTeam[i]
      if myTeam ~= team and PetUtils.IsInBattleTeam(petInfo.role_uin, team) then
        return true
      end
    end
  end
  return false
end

function PetUtils.IsEnemy(petInfo)
  local allEnemyTeam = _G.BattleManager.battlePawnManager.AllEnemyTeam
  if allEnemyTeam then
    for i = 1, #allEnemyTeam do
      local team = allEnemyTeam[i]
      if PetUtils.IsInBattleTeam(petInfo.role_uin, team) then
        return true
      end
    end
  end
  return false
end

function PetUtils.GetBattleSkills(battle_inside_pet_info, bAllowHiddenSkill)
  local Skills = {}
  local PosMax = BattleConst.PET_MAX_EQUIP_SKILL_NUM
  if PetUtils.DoCheckIsMimic(battle_inside_pet_info) then
    return Skills
  end
  if PetUtils.DoCheckIsSurpriseBox(battle_inside_pet_info) then
    return Skills
  end
  local battle_type = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleType or 0
  if battle_type ~= Enum.BattleType.BT_WORLDLEADER and battle_inside_pet_info and battle_inside_pet_info.used_original_skill then
    for i, Skill in ipairs(battle_inside_pet_info.used_original_skill) do
      if Skill.pos and Skill.pos >= 1 and PosMax >= Skill.pos then
        Skills[Skill.pos] = Skills[Skill.pos] or Skill
      end
    end
  end
  local skills_rule3 = {}
  for i, v in pairs(Skills) do
    table.insert(skills_rule3, v)
  end
  Skills = skills_rule3
  if bAllowHiddenSkill then
    for i = 1, PosMax do
      if nil == Skills[i] then
        local unknowSkill = {id = -1}
        Skills[i] = unknowSkill
      end
    end
  end
  return Skills
end

function PetUtils.FindFirstBuffBaseConfByBuffType(battle_inside_pet_info, buffType)
  if battle_inside_pet_info and battle_inside_pet_info.buffs then
    for i = 1, #battle_inside_pet_info.buffs do
      local buffInfo = battle_inside_pet_info.buffs[i]
      local buffBaseConf = BuffUtils.FindFirstBuffBaseConfByBuffType(buffInfo.buff_id, buffType)
      if buffBaseConf then
        return buffBaseConf
      end
    end
  end
  return nil
end

function PetUtils.GetNightMareShield(insidePetInfo)
  if not insidePetInfo.battle_attr then
    Log.Warning("\230\149\176\230\141\174\229\188\130\229\184\184\239\188\154insidePetInfo.battle_attr is nil")
    return 999, 999
  else
    if PetUtils.CheckIsSurpriseBoxPet(insidePetInfo.base_conf_id) then
      return insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD_MAX + 1], insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD + 1]
    end
    return insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AT_NIGHTMARE_SHIELD_MAX + 1], insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AT_NIGHTMARE_SHIELD + 1]
  end
end

function PetUtils.CheckIsNightMarePet(insidePetInfo)
  if insidePetInfo and insidePetInfo.battle_attr then
    return (insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AT_NIGHTMARE_SHIELD_MAX + 1] or 0) > 0
  end
end

function PetUtils.CheckHasNightMareShield(insidePetInfo)
  if insidePetInfo and insidePetInfo.battle_attr then
    if PetUtils.CheckIsSurpriseBoxPet(insidePetInfo.base_conf_id) then
      return (insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD + 1] or 0) > 0
    end
    return (insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AT_NIGHTMARE_SHIELD + 1] or 0) > 0
  end
end

function PetUtils.GetSurpriseBoxShield(insidePetInfo)
  if not insidePetInfo.battle_attr then
    Log.Warning("\230\149\176\230\141\174\229\188\130\229\184\184\239\188\154insidePetInfo.battle_attr is nil")
    return 999, 999
  else
    return insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD_MAX + 1], insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD + 1]
  end
end

function PetUtils.CheckIsSurpriseBoxPet(confId)
  if not confId then
    return false
  end
  local boxPetConf = _G.DataConfigManager:GetBattleGlobalConfig("fantastic_box_petbase")
  if not boxPetConf then
    return false
  end
  local list = boxPetConf.numList
  if not list then
    return false
  end
  local Ids = boxPetConf.numList
  for _, id in pairs(Ids) do
    if id == confId then
      return true
    end
  end
  return false
end

function PetUtils.CheckHasSurpriseShield(insidePetInfo)
  if insidePetInfo and insidePetInfo.battle_attr then
    return (insidePetInfo.battle_attr[_G.ProtoEnum.AttributeType.AI_BOX_SHIELD + 1] or 0) > 0
  end
end

function PetUtils.GetEmptyEquipSkillPos(petData)
  if not petData then
    return 1
  end
  local pos = 0
  for i = 1, #petData.skill.skill_data do
    local petSkillData = petData.skill.skill_data[i]
    if petSkillData.is_equipped and pos <= petSkillData.pos then
      pos = petSkillData.pos
    end
  end
  return pos
end

function PetUtils.CheckLearnNewSkill(oldPetData, newPetData)
  for i = 1, #newPetData.skill.skill_data do
    local newSkillData = newPetData.skill.skill_data[i]
    for j = 1, #oldPetData.skill.skill_data do
      local oldSkillData = oldPetData.skill.skill_data[j]
      if newSkillData.id == oldSkillData.id then
        local ret = newSkillData.is_learned ~= oldSkillData.is_learned
        if ret then
          return true
        end
      end
    end
  end
  return false
end

function PetUtils.GetNewSkillDatas(oldPetData, newPetData)
  local changeSkills
  for i = 1, #newPetData.skill.skill_data do
    local newTmpSkillData = newPetData.skill.skill_data[i]
    local find = false
    for j = 1, #oldPetData.skill.skill_data do
      local oldTmpSkillData = oldPetData.skill.skill_data[j]
      if newTmpSkillData.id == oldTmpSkillData.id and newTmpSkillData.is_learned ~= oldTmpSkillData.is_learned then
        find = true
      end
    end
    if find then
      changeSkills = changeSkills or {}
      table.insert(changeSkills, newTmpSkillData)
    end
  end
  return changeSkills
end

function PetUtils.GetTypeRestraint(base_id, UnitType)
  local RestainTypeList, ResistTypeList = NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetRestrainAndResistType, {base_conf_id = base_id})
  local isPhase
  local IsDouble = false
  for _, type in pairs(UnitType) do
    for i, v in pairs(RestainTypeList) do
      if v.typeID == type then
        isPhase = true
        IsDouble = v.isDouble
        break
      end
    end
    for i, v in pairs(ResistTypeList) do
      if v.typeID == type then
        if isPhase then
          if IsDouble and v.isDouble then
            isPhase = nil
            break
          end
          if IsDouble and not v.isDouble then
            isPhase = true
            IsDouble = false
            break
          end
          if not IsDouble and v.isDouble then
            isPhase = false
            IsDouble = false
          end
          break
        end
        isPhase = false
        IsDouble = v.isDouble
        break
      end
    end
  end
  return isPhase, IsDouble
end

function PetUtils.UpdatePetNewSkill(petData)
  local skillList = {}
  if nil == petData then
    return
  end
  for i, skillData in ipairs(petData.skill.skill_data) do
    if skillData.is_equipped and skillData.pos > 0 and skillData.pos <= 4 then
      table.insert(skillList, skillData)
    end
  end
  if skillList and #skillList > 0 then
    for i, v in ipairs(skillList) do
      NRCModuleManager:DoCmd(PetUIModuleCmd.RemoveSkillNew, petData.gid, v.id)
    end
  end
end

function PetUtils.GetPetSkillEquipInfoListFromPetData(petData)
  local petSkillEquipInfoList = {}
  if petData then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        local petSkillEquipInfo = _G.ProtoMessage:newPetSkillEquipInfo()
        petSkillEquipInfo.id = skillData.id
        petSkillEquipInfo.pos = skillData.pos
        petSkillEquipInfoList[skillData.pos] = petSkillEquipInfo
      end
    end
  end
  return petSkillEquipInfoList
end

function PetUtils.GetNewHandBookDatas(NewPetHandbook, OldPetHandbook, str)
  local PetHandbook = NewPetHandbook
  local handbook_record = OldPetHandbook
  local NewPetHandBookInfo = {}
  local PetGlobalConfig
  local PetGlobalConfig_1 = _G.DataConfigManager:GetPetGlobalConfig(str)
  NewPetHandBookInfo.pet_base_id = handbook_record.pet_base_id
  NewPetHandBookInfo.PetGlobalConfigText = PetGlobalConfig_1
  NewPetHandBookInfo.PetGlobalConfig = PetGlobalConfig
  NewPetHandBookInfo.HandBook = PetHandbook
  return NewPetHandBookInfo
end

function PetUtils.IsHavePet()
  local petList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  return nil ~= petList and #petList > 0
end

function PetUtils.HandbookIsHasPet(petbaseid)
  local petInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if not petInfo then
    Log.Error("\229\174\160\231\137\169\230\149\176\230\141\174\230\156\137\232\175\175\232\175\183\230\163\128\230\159\165")
    return true
  end
  local PetBaseId = petbaseid
  for j, records in ipairs(petInfo.handbook.records) do
    if records.pet_base_id == PetBaseId then
      return true
    end
  end
  return false
end

function PetUtils.GetAttributeTypeSByHabitUnlock(_PetData)
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(_PetData.base_conf_id)
  local group_id = PetBaseConf.belong_habit_group
  if 0 == group_id then
    return
  end
  local AttributeTypeS = {}
  local HabitConf = PetUtils.GetImpressionGroupConf(group_id)
  for i, Conf in ipairs(HabitConf) do
    if _PetData.habit_level >= Conf.group_number and Conf.habit_ability[1].ability_type == Enum.HabitAbilityType.HAT_ATTR and Conf.habit_ability[1].ability_param1[1] then
      table.insert(AttributeTypeS, Conf.habit_ability[1].ability_param1[1])
    end
  end
  return AttributeTypeS
end

function PetUtils.GetPetAdditionalByType(PetData, AttributeType)
  if not PetData then
    Log.Error("\230\178\161\230\156\137\231\178\190\231\129\181\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return 0
  end
  if PetData.attribute_new_info and PetData.attribute_new_info.addi_attr_data then
    local PetAdditional = PetData.attribute_new_info.addi_attr_data
    for i, attr in ipairs(PetAdditional) do
      if attr.type == AttributeType then
        return attr.addi_attr
      end
    end
  end
  return PetUtils.GetPetBaseAttrByType(PetData, AttributeType)
end

function PetUtils.GetEnhanceAttributeTypeByUnitType(UnitType)
  local RetAttributeType = Enum.AttributeType.AT_NONE
  if UnitType == Enum.SkillDamType.SDT_COMMON then
    RetAttributeType = Enum.AttributeType.AT_COMMON_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_GRASS then
    RetAttributeType = Enum.AttributeType.AT_GRASS_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_FIRE then
    RetAttributeType = Enum.AttributeType.AT_FIRE_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_WATER then
    RetAttributeType = Enum.AttributeType.AT_WATER_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_LIGHT then
    RetAttributeType = Enum.AttributeType.AT_LIGHT_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_EARTH then
    RetAttributeType = Enum.AttributeType.AT_EARTH_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_STONE then
    RetAttributeType = Enum.AttributeType.AT_STONE_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_ICE then
    RetAttributeType = Enum.AttributeType.AT_ICE_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_DRAGON then
    RetAttributeType = Enum.AttributeType.AT_DRAGON_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_ELECTRIC then
    RetAttributeType = Enum.AttributeType.AT_ELECTRIC_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_TOXIC then
    RetAttributeType = Enum.AttributeType.AT_TOXIC_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_INSECT then
    RetAttributeType = Enum.AttributeType.AT_INSECT_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_FIGHT then
    RetAttributeType = Enum.AttributeType.AT_FIGHT_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_WING then
    RetAttributeType = Enum.AttributeType.AT_WING_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_MOE then
    RetAttributeType = Enum.AttributeType.AT_MOE_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_GHOST then
    RetAttributeType = Enum.AttributeType.AT_GHOST_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_DEMON then
    RetAttributeType = Enum.AttributeType.AT_DEMON_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_MECHANIC then
    RetAttributeType = Enum.AttributeType.AT_MECHANIC_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_PHANTOM then
    RetAttributeType = Enum.AttributeType.AT_PHANTOM_ENHANCE
  elseif UnitType == Enum.SkillDamType.SDT_RELAX then
    RetAttributeType = Enum.AttributeType.AT_RELAX_ENHANCE
  end
  return RetAttributeType
end

function PetUtils.GetAttributeValueByAttributeType(PetData, AttributeType)
  local RetValue = 0
  if PetData and PetData.attribute_new_info and PetData.attribute_new_info.addi_attr_data then
    for i, attrItem in pairs(PetData.attribute_new_info.addi_attr_data) do
      if attrItem.type == AttributeType then
        RetValue = attrItem.addi_attr
        break
      end
    end
  end
  return RetValue
end

function PetUtils.GetPetBaseAttrByType(PetData, AttributeType)
  local PetBase = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  if AttributeType == _G.Enum.AttributeType.AT_HIT then
    return PetBase.hit
  elseif AttributeType == _G.Enum.AttributeType.AT_DODGE then
    return PetBase.dodge
  elseif AttributeType == _G.Enum.AttributeType.AT_CRIT then
    return PetBase.critical
  elseif AttributeType == _G.Enum.AttributeType.AT_CRITRES then
    return PetBase.critical_res
  elseif AttributeType == _G.Enum.AttributeType.AT_CRITDAM then
    return PetBase.critical_dam
  elseif AttributeType == _G.Enum.AttributeType.AT_CRITDAMRES then
    return PetBase.critical_dam_res
  elseif AttributeType == _G.Enum.AttributeType.AT_PHYADD then
    return PetBase.phy_dam_add
  elseif AttributeType == _G.Enum.AttributeType.AT_SPEADD then
    return PetBase.spe_dam_add
  elseif AttributeType == _G.Enum.AttributeType.AT_PHYRES then
    return PetBase.phy_dam_res
  elseif AttributeType == _G.Enum.AttributeType.AT_SPERES then
    return PetBase.spe_dam_res
  elseif AttributeType == _G.Enum.AttributeType.AT_ALLADD then
    return PetBase.all_dam_add
  elseif AttributeType == _G.Enum.AttributeType.AT_ALLRES then
    return PetBase.all_dam_res
  elseif AttributeType == _G.Enum.AttributeType.AT_WAVELOW then
    return PetBase.dam_wave_low
  elseif AttributeType == _G.Enum.AttributeType.AT_WAVEHIGH then
    return PetBase.dam_wave_high
  elseif AttributeType == _G.Enum.AttributeType.AT_COUNTER_BONUS then
    return PetBase.counter_bonus
  elseif AttributeType == _G.Enum.AttributeType.AT_RESIST_BONUS then
    return PetBase.resist_bonus
  elseif AttributeType == _G.Enum.AttributeType.AT_COMMON_ENHANCE then
    return PetBase.common_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_GRASS_ENHANCE then
    return PetBase.grass_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_FIRE_ENHANCE then
    return PetBase.fire_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_WATER_ENHANCE then
    return PetBase.water_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_LIGHT_ENHANCE then
    return PetBase.light_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_STONE_ENHANCE then
    return PetBase.stone_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_PHANTOM_ENHANCE then
    return PetBase.phantom_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_ICE_ENHANCE then
    return PetBase.ice_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_DRAGON_ENHANCE then
    return PetBase.dragon_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_ELECTRIC_ENHANCE then
    return PetBase.electric_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_TOXIC_ENHANCE then
    return PetBase.toxic_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_INSECT_ENHANCE then
    return PetBase.insect_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_FIGHT_ENHANCE then
    return PetBase.fight_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_WING_ENHANCE then
    return PetBase.wing_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_MOE_ENHANCE then
    return PetBase.moe_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_GHOST_ENHANCE then
    return PetBase.ghost_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_DEMON_ENHANCE then
    return PetBase.demon_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_MECHANIC_ENHANCE then
    return PetBase.mechanic_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_COMMON_RESIST then
    return PetBase.common_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_GRASS_RESIST then
    return PetBase.grass_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_FIRE_RESIST then
    return PetBase.fire_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_WATER_RESIST then
    return PetBase.water_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_LIGHT_RESIST then
    return PetBase.light_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_EARTH_RESIST then
    return PetBase.earth_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_PHANTOM_RESIST then
    return PetBase.phantom_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_ICE_RESIST then
    return PetBase.ice_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_DRAGON_RESIST then
    return PetBase.dragon_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_ELECTRIC_RESIST then
    return PetBase.electric_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_TOXIC_RESIST then
    return PetBase.toxic_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_INSECT_RESIST then
    return PetBase.insect_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_FIGHT_RESIST then
    return PetBase.fight_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_WING_RESIST then
    return PetBase.wing_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_MOE_RESIST then
    return PetBase.moe_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_GHOST_RESIST then
    return PetBase.ghost_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_DEMON_RESIST then
    return PetBase.demon_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_MECHANIC_RESIST then
    return PetBase.mechanic_resist
  elseif AttributeType == _G.Enum.AttributeType.AT_HEAL_ENHANCE then
    return PetBase.heal_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_SHEILD_ENHANCE then
    return PetBase.sheild_enhance
  elseif AttributeType == _G.Enum.AttributeType.AT_HPMAX_PERCENT then
    return PetBase.hpmax_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_PHYATK_PERCENT then
    return PetBase.phyatk_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_SPEATK_PERCENT then
    return PetBase.speatk_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_PHYDEF_PERCENT then
    return PetBase.phydef_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_SPEDEF_PERCENT then
    return PetBase.spedef_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_SPEED_PERCENT then
    return PetBase.speed_percent
  elseif AttributeType == _G.Enum.AttributeType.AT_DAMTYPE1 then
    return #PetBase.unit_type > 0 and PetBase.unit_type[1] or _G.Enum.SkillDamType.SDT_NONE
  elseif AttributeType == _G.Enum.AttributeType.AT_DAMTYPE2 then
    return #PetBase.unit_type > 1 and PetBase.unit_type[2] or _G.Enum.SkillDamType.SDT_NONE
  elseif AttributeType == _G.Enum.AttributeType.AT_DAMTYPE2 then
    return #PetBase.unit_type > 2 and PetBase.unit_type[3] or _G.Enum.SkillDamType.SDT_NONE
  end
  return 0
end

function PetUtils.GetPetUnlockedHabitItemNum(group_id, habit_level)
  local ItemNum = 0
  local HabitConf = PetUtils.GetImpressionGroupConf(group_id)
  for i, Conf in ipairs(HabitConf) do
    if habit_level < Conf.group_number then
      ItemNum = ItemNum + Conf.unlock_item_num
    end
  end
  return ItemNum
end

function PetUtils.GetImpressionGroupConf(group_id)
  local habits = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_HABIT_CONF):GetAllDatas()
  local groupConf = {}
  for i, conf in pairs(habits) do
    if conf.group_id == group_id then
      table.insert(groupConf, conf)
    end
  end
  return groupConf
end

function PetUtils.GetPetIsMixedBlood(_PetData, unit_type)
  if not (_PetData and unit_type) or 0 == #unit_type then
    return false
  end
  local PetData = _PetData
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(PetData.blood_id)
  if PetBloodConf then
    for i, type in ipairs(unit_type) do
      if type == PetBloodConf.blood_type then
        return false
      end
    end
  end
  return true
end

function PetUtils.GetPetMaxLevel(_PetData)
  local PlayerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local WorldLevelConf = _G.DataConfigManager:GetWorldLevelConf(PlayerWorldLevel + 1)
  local WorldLevelConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
  if not WorldLevelConf then
    Log.Error("\230\159\165\228\184\141\229\136\176WORLD_LEVEL_CONF\233\133\141\231\189\174\232\161\168\230\149\176\230\141\174", PlayerWorldLevel + 1)
    return 0, WorldLevelConfList[#WorldLevelConfList].pet_level_limit
  end
  if not WorldLevelConf.pet_level_limit then
    Log.Dump(WorldLevelConf, 6, "PetUtils.GetPetMaxLevel")
    Log.Error("\233\133\141\231\189\174\232\161\168\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152\233\186\187\231\131\166\231\156\139\231\156\139")
  end
  return WorldLevelConf.pet_level_limit, WorldLevelConfList[#WorldLevelConfList].pet_level_limit
end

function PetUtils.GetPetStriveMaxLevel(ExpType)
  local PlayerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local PetEffortsList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_EFFORTS_LEVEL):GetAllDatas()
  local List = {}
  local MaxLevel
  local IsSatisfy = false
  for i, PetEfforts in pairs(PetEffortsList) do
    if ExpType == PetEfforts.need_exp_type then
      if PlayerWorldLevel < PetEfforts.need_star and not IsSatisfy then
        MaxLevel = PetEfforts.efforts_level
        IsSatisfy = true
      end
      table.insert(List, {
        Level = PetEfforts.efforts_level
      })
    end
  end
  table.sort(List, function(a, b)
    return a.Level < b.Level
  end)
  return MaxLevel, List[#List].Level
end

function PetUtils.GetPetStriveMaxStar(ExpType, Level)
  local PlayerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local PetEffortsList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_EFFORTS_LEVEL):GetAllDatas()
  for i, PetEfforts in pairs(PetEffortsList) do
    if ExpType == PetEfforts.need_exp_type and PetEfforts.efforts_level == Level then
      return PetEfforts.need_star
    end
  end
end

function PetUtils.NeedUpgradeWorldLevel()
  local _WorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() + 1
  local WorldLevelS = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
  for i, WorldLevel in ipairs(WorldLevelS) do
    if _WorldLevel == WorldLevel.world_level then
      return WorldLevel.world_level, WorldLevel.title
    end
  end
end

function PetUtils.GetPetBaseInfoByUseItemVisualType(BagItem, PetData)
  local PetUpGradeBaseInfo = {}
  PetUpGradeBaseInfo.gid = PetData.gid
  PetUpGradeBaseInfo.curLevel = PetData.level
  PetUpGradeBaseInfo.curPetExp = PetData.exp
  PetUpGradeBaseInfo.LevelName = LuaText.petutils_1
  PetUpGradeBaseInfo.ItemConsumeGold = 0
  local BagItemConf = BagItem and BagItem.itemConf
  if BagItemConf and BagItemConf.item_behavior then
    for i, item in ipairs(BagItemConf.item_behavior) do
      local UseAction = item.use_action
      if UseAction == Enum.ItemBehavior.IB_ADD_PET_EXP then
        PetUpGradeBaseInfo.itemPetExp = item.ratio[1]
      elseif UseAction == Enum.ItemBehavior.IB_COST_VITEM then
        local ratio = item.ratio[1]
        if ratio == Enum.VisualItem.VI_COIN then
          PetUpGradeBaseInfo.ItemConsumeGold = item.ratio[2]
        end
      end
    end
  end
  local maxExp
  local petLevelExpList = {}
  local PetLevel
  local IsLevel = false
  local AddExpType = PetUIModuleEnum.AddExpType.PetExp
  if BagItem then
    AddExpType = PetUtils.GetAddExpType(BagItem)
  end
  if AddExpType and AddExpType == PetUIModuleEnum.AddExpType.PetExp then
    PetUpGradeBaseInfo.maxLevel, PetUpGradeBaseInfo.MaxLevelInfo = PetUtils.GetPetMaxLevel()
    PetLevel = PetUpGradeBaseInfo.curLevel
    if PetLevel then
      local LevelList = PetUpGradeBaseInfo.maxLevel or 0
      if LevelList < PetUpGradeBaseInfo.curLevel then
        LevelList = PetUpGradeBaseInfo.curLevel
      end
      if PetUpGradeBaseInfo.curLevel > 1 then
        PetLevel = PetUpGradeBaseInfo.curLevel - 1
      end
      for level = PetLevel, LevelList do
        local petLevelConf = _G.DataConfigManager:GetPetLevelConf(level)
        if level == PetUpGradeBaseInfo.maxLevel - 1 then
          maxExp = petLevelConf.pet_exp
        end
        petLevelExpList[level] = petLevelConf
      end
    else
      Log.Error("PetLevel is nil")
    end
  else
  end
  local WorldLevelConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
  local PlayerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  PetUpGradeBaseInfo.petLevelExpList = petLevelExpList
  PetUpGradeBaseInfo.maxNeedExp = maxExp
  PetUpGradeBaseInfo.AddExpType = AddExpType
  PetUpGradeBaseInfo.IsFullWorldLevel = PlayerWorldLevel == WorldLevelConf[#WorldLevelConf].world_level and true or false
  return PetUpGradeBaseInfo
end

function PetUtils.GetAddExpType(BagItem)
  local BagItemConf = BagItem.itemConf
  if BagItemConf.item_behavior then
    for i, item in ipairs(BagItemConf.item_behavior) do
      local UseAction = item.use_action
      if UseAction == Enum.ItemBehavior.IB_GET_VITEM then
      end
    end
  end
  return PetUIModuleEnum.AddExpType.PetExp
end

function PetUtils.GetStrivePercent(_attribute_type, StriveLevel, StriveExp)
  local MaxExp = 0
  local CurExp = StriveExp
  local PetEffortsList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_EFFORTS_LEVEL):GetAllDatas()
  for i, PetEfforts in pairs(PetEffortsList) do
    if PetEfforts.attribute_type == _attribute_type then
      if PetEfforts.efforts_level == StriveLevel then
        MaxExp = PetEfforts.need_exp_data
      end
      if StriveLevel > PetEfforts.efforts_level then
        CurExp = CurExp - PetEfforts.need_exp_data
      end
    end
  end
  if 10 == StriveLevel then
    MaxExp = 50000
    CurExp = 50000
  end
  return CurExp / MaxExp, CurExp, MaxExp
end

function PetUtils.GetPetGrowLevel(_PetData)
  if not _PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\233\128\187\232\190\145")
    return
  end
  local PetData = _PetData
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  local break_reward = _G.DataConfigManager:GetBreakRewardConf(PetBaseConf.break_award_sort)
  local PetGrowLevel = 999
  local GrowOrder = 0
  for i, v in ipairs(break_reward.break_award) do
    if PetData.last_breakthrough_lv < v.break_level_point then
      PetGrowLevel = v.break_level_point
      GrowOrder = i
      break
    end
  end
  return PetGrowLevel, GrowOrder
end

function PetUtils.GetResidueGrowCountAndGrowOrder(_PetData)
  if not _PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\233\128\187\232\190\145")
    return
  end
  local PetData = _PetData
  local PetGrowCount = PetData.grow_times or 0
  local Count = 0
  local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
  local GrowOrder = #BreakNumberAllConf + 1
  local IsMax = true
  for i, BreakNumber in ipairs(BreakNumberAllConf) do
    if PetData.last_breakthrough_lv and PetData.last_breakthrough_lv < BreakNumber.require_level then
      Count = BreakNumber.require_grow_time
      GrowOrder = i
      IsMax = false
      break
    end
  end
  Count = Count - PetGrowCount
  if Count < 0 then
    if not IsMax then
      Log.Error("\230\159\165\231\156\139\228\184\186\228\187\128\228\185\136\230\136\144\233\149\191\230\172\161\230\149\176\229\176\143\228\186\1420")
    end
    return 0, GrowOrder
  end
  return Count, GrowOrder
end

function PetUtils.GetPetGrowNeedItems(_PetData)
  local ItemInfos = {}
  local petData = _PetData
  local itemCfg, itemCount
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(petData)
  local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
  if PetBaseConf and GrowOrder >= 1 and GrowOrder <= #BreakNumberAllConf then
    local breakItemConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_ITEM_CONF):GetAllDatas()
    local BreakNumberConf = _G.DataConfigManager:GetBreakNumberConf(GrowOrder)
    local UnitType = PetBaseConf.unit_type
    for i, v in ipairs(UnitType) do
      if UnitType[i] then
        local ConsumeNum = BreakNumberConf.type_item_number
        for j, k in ipairs(breakItemConf) do
          if v == k.unit_type and GrowOrder == k.break_level then
            if #UnitType > 1 then
              ConsumeNum = ConsumeNum // #UnitType
            end
            if ConsumeNum > 0 then
              itemCfg = k.break_type_item > 1 and _G.DataConfigManager:GetBagItemConf(k.break_type_item) or nil
              itemCount = PetUtils.getItemCount(k.break_type_item)
              table.insert(ItemInfos, {
                itemId = k.break_type_item,
                itemCfg = itemCfg,
                itemNum = ConsumeNum,
                BagNum = itemCount,
                isShowFinish = false,
                ExChangeItemId = k.exchange_type_item,
                ExChangeRatio = k.exchange_ratio,
                bShowNum = true,
                bShowTip = true,
                itemType = _G.Enum.GoodsType.GT_BAGITEM
              })
            end
          end
        end
      end
    end
    if BreakNumberConf.cost_item_number and BreakNumberConf.cost_item_number > 0 then
      itemCfg = PetBaseConf.break_cost_item > 1 and _G.DataConfigManager:GetBagItemConf(PetBaseConf.break_cost_item) or nil
      itemCount = PetUtils.getItemCount(PetBaseConf.break_cost_item)
      table.insert(ItemInfos, {
        itemId = PetBaseConf.break_cost_item,
        itemCfg = itemCfg,
        itemNum = BreakNumberConf.cost_item_number,
        BagNum = itemCount,
        isShowFinish = false,
        bShowNum = true,
        bShowTip = true,
        itemType = _G.Enum.GoodsType.GT_BAGITEM
      })
    end
    if PetBaseConf and PetBaseConf.break_spec_item_id > 0 and BreakNumberConf.spec_item_number and BreakNumberConf.spec_item_number > 0 then
      itemCfg = _G.DataConfigManager:GetBagItemConf(PetBaseConf.break_spec_item_id)
      itemCount = PetUtils.getItemCount(PetBaseConf.break_spec_item_id)
      table.insert(ItemInfos, {
        itemId = PetBaseConf.break_spec_item_id,
        itemCfg = itemCfg,
        itemNum = BreakNumberConf.spec_item_number,
        BagNum = itemCount,
        isShowFinish = false,
        bShowNum = true,
        bShowTip = true,
        itemType = _G.Enum.GoodsType.GT_BAGITEM
      })
    end
    if BreakNumberConf.dust_number and BreakNumberConf.dust_number > 0 then
      local PetGlobalConf = _G.DataConfigManager:GetPetGlobalConfig("break_common_dust_id")
      itemCfg = _G.DataConfigManager:GetBagItemConf(PetGlobalConf.num)
      itemCount = PetUtils.getItemCount(PetGlobalConf.num)
      table.insert(ItemInfos, {
        itemId = PetGlobalConf.num,
        itemCfg = itemCfg,
        itemNum = BreakNumberConf.dust_number,
        BagNum = itemCount,
        isShowFinish = false,
        bShowNum = true,
        bShowTip = true,
        itemType = _G.Enum.GoodsType.GT_BAGITEM
      })
    end
  end
  table.sort(ItemInfos, function(a, b)
    return a.itemCfg.sort_id < b.itemCfg.sort_id
  end)
  return ItemInfos
end

function PetUtils.GetPetInspireNeedItems(PetData)
  local BagItemInfoList = {}
  local NeedMoney = 0
  if nil == PetData then
    return BagItemInfoList, NeedMoney
  end
  local PetGrowUpType = PetUtils.GetPetGrowUpType(PetData)
  if PetGrowUpType == PetUIModuleEnum.PetGrowUpType.WaitToInspire then
    local InspireLevelAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.INSPIRE_LEVEL_CONF):GetAllDatas()
    local NextInspireLevel = 1
    if PetData.inspire_lv then
      NextInspireLevel = PetData.inspire_lv + 1
    end
    local NextInspireLevelConf = InspireLevelAllConf[NextInspireLevel]
    if NextInspireLevelConf and NextInspireLevelConf.require_item then
      for _, v in pairs(NextInspireLevelConf.require_item) do
        if v then
          local ItemID = v.item_id
          if ItemID then
            local ItemType = v.item_type
            if ItemType ~= _G.Enum.GoodsType.GT_VITEM then
              local ItemCount = 0
              if ItemType == _G.Enum.GoodsType.GT_BAGITEM then
                ItemCount = PetUtils.getItemCount(ItemID)
              end
              local ItemNeedNum = v.item_num
              local ItemCfg = _G.DataConfigManager:GetBagItemConf(ItemID)
              table.insert(BagItemInfoList, {
                itemId = ItemID,
                itemCfg = ItemCfg,
                itemNum = ItemNeedNum,
                BagNum = ItemCount,
                itemType = ItemType,
                isShowFinish = false,
                bShowNum = true,
                bShowTip = true
              })
            elseif 1 == ItemID then
              NeedMoney = v.item_num
            end
          end
        end
      end
    end
  end
  return BagItemInfoList, NeedMoney
end

function PetUtils.getItemCount(_itemId)
  local itemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, _itemId)
  if itemData and itemData.num then
    return itemData.num or 0
  end
  return 0
end

function PetUtils.GetCatchHardInfo(_PetData, _IsBreakThrough)
  if not _PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  local PetData = _PetData
  local PetLevelData, IsFinish = PetUtils.GetCanGrowLevelGap(PetData)
  if not PetLevelData then
    return {}, 0
  end
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  local break_reward = _G.DataConfigManager:GetBreakRewardConf(PetBaseConf.break_award_sort)
  local PetLevelInfo = PetData.level
  local CurrentGrowNum = 0
  local CurrentGrowLevle = 0
  local Starlevel = 0
  local PetLevel = {}
  if IsFinish then
    CurrentGrowNum = 999
  else
    for i, v in ipairs(break_reward.break_award) do
      if PetLevelData == v.break_level_point then
        CurrentGrowNum = i
        CurrentGrowLevle = v.break_level_point
        break
      end
    end
  end
  for i = 1, 5 do
    if PetLevelData > break_reward.break_award[#break_reward.break_award].break_level_point then
      table.insert(PetLevel, {
        i,
        IsShow = 1,
        IsBreakThrough = _IsBreakThrough
      })
      Starlevel = Starlevel + 1
    elseif i < CurrentGrowNum then
      table.insert(PetLevel, {
        i,
        IsShow = 1,
        IsBreakThrough = _IsBreakThrough
      })
      Starlevel = Starlevel + 1
    elseif i == CurrentGrowNum and PetLevelInfo >= CurrentGrowLevle then
      table.insert(PetLevel, {
        i,
        IsShow = 0,
        IsBreakThrough = _IsBreakThrough
      })
    else
      table.insert(PetLevel, {
        i,
        IsShow = -1,
        IsBreakThrough = _IsBreakThrough
      })
    end
  end
  return PetLevel, Starlevel
end

function PetUtils.GetGrowStarsList(_PetData, _NeedGrowCount)
  if not _PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  local GrowStarsList = {}
  local PetData = _PetData
  local NeedGrowCount = _NeedGrowCount or 0
  local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(PetData)
  local MaxCount = _G.DataConfigManager:GetPetGlobalConfig("break_need_grow_time").num
  for i = 1, MaxCount do
    if i <= MaxCount - ResidueGrowCount then
      table.insert(GrowStarsList, {
        i,
        IsShow = 1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToGrowUp
      })
    elseif i <= MaxCount - ResidueGrowCount + NeedGrowCount then
      table.insert(GrowStarsList, {
        i,
        IsShow = 0,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToGrowUp
      })
    else
      table.insert(GrowStarsList, {
        i,
        IsShow = -1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToGrowUp
      })
    end
  end
  return GrowStarsList
end

function PetUtils.GetBreakThroughStarsList(_PetData, _IsBreakThrough, IsHide)
  if not _PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  local BreakThroughStarsList = {}
  local PetData = _PetData
  local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(PetData)
  local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
  for i = 1, #BreakNumberAllConf do
    if i < GrowOrder then
      table.insert(BreakThroughStarsList, {
        i,
        IsShow = 1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough,
        IsHide = IsHide
      })
    elseif i == GrowOrder then
      table.insert(BreakThroughStarsList, {
        i,
        IsShow = 0,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough,
        IsHide = IsHide
      })
    else
      table.insert(BreakThroughStarsList, {
        i,
        IsShow = -1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough,
        IsHide = IsHide
      })
    end
  end
  return BreakThroughStarsList
end

function PetUtils.GetInspireStarsList(PetData)
  if not PetData then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  local InspireStarsList = {}
  local InspireLevelAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.INSPIRE_LEVEL_CONF):GetAllDatas()
  local PetInspireLv = 0
  if PetData.inspire_lv then
    PetInspireLv = PetData.inspire_lv
  end
  for i = 1, #InspireLevelAllConf do
    if i <= PetInspireLv then
      table.insert(InspireStarsList, {
        i,
        IsShow = 1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToInspire,
        IsHide = false
      })
    elseif i == PetInspireLv + 1 then
      table.insert(InspireStarsList, {
        i,
        IsShow = 0,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToInspire,
        IsHide = false
      })
    else
      table.insert(InspireStarsList, {
        i,
        IsShow = -1,
        GrowUpType = PetUIModuleEnum.PetGrowUpType.WaitToInspire,
        IsHide = false
      })
    end
  end
  return InspireStarsList
end

function PetUtils.GetPetStarsListByPetGID(PetGID, PetData)
  local RetStarsList = {}
  if not PetGID and not PetData then
    Log.Error("PetUtils.GetStarsListByPetGID PetGID is nil")
    return RetStarsList
  end
  local RealPetData = PetData
  if nil == RealPetData then
    RealPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetGID)
  end
  if not RealPetData then
    Log.Error("PetUtils.GetStarsListByPetGID PetData is nil")
    return RetStarsList
  end
  local PetGrowUpType = PetUtils.GetPetGrowUpType(RealPetData)
  if PetGrowUpType == PetUIModuleEnum.PetGrowUpType.WaitToGrowUp or PetGrowUpType == PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough then
    RetStarsList = PetUtils.GetBreakThroughStarsList(RealPetData)
  elseif PetGrowUpType == PetUIModuleEnum.PetGrowUpType.WaitToInspire or PetGrowUpType == PetUIModuleEnum.PetGrowUpType.Max then
    RetStarsList = PetUtils.GetInspireStarsList(RealPetData)
  end
  return RetStarsList
end

function PetUtils.CheckPetIsMaxLevel(PetData)
  local LevelToplimitConf = _G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit")
  if PetData and PetData.level and PetData.level >= LevelToplimitConf.num then
    return true
  end
  return false
end

function PetUtils.GetCanGrowLevelGap(_PetData)
  local PetLevelData = _PetData.last_breakthrough_lv
  Log.Debug(PetLevelData, "PetUtils.GetCanGrowLevelGap")
  local baseConfId = _PetData and _PetData.base_conf_id
  local PetBaseConf = baseConfId and _G.DataConfigManager:GetPetbaseConf(baseConfId, true)
  local breakAwardSort = PetBaseConf and PetBaseConf.break_award_sort
  local break_reward = breakAwardSort and _G.DataConfigManager:GetBreakRewardConf(breakAwardSort, true)
  if not break_reward then
    return
  end
  if 0 == PetLevelData then
    return PetLevelData + break_reward.break_award[1].break_level_point
  else
    for i, v in ipairs(break_reward.break_award) do
      if PetLevelData == v.break_level_point then
        if i == #break_reward.break_award then
          return v.break_level_point, true
        else
          return break_reward.break_award[i + 1].break_level_point, false
        end
      end
    end
  end
end

function PetUtils.ConvertColor(skillDamType)
  if skillDamType == Enum.SkillDamType.SDT_GRASS then
    return "#3bbe39"
  elseif skillDamType == Enum.SkillDamType.SDT_TOXIC then
    return "#c644f7"
  else
    return "#3bbe39"
  end
end

function PetUtils.FilterPet(filter, itemList)
  local bagItemList = {}
  local ItemGidDic = {}
  if nil ~= filter and #filter > 0 then
    local petFilter = filter
    local learnskillid = 0
    for j = 1, #petFilter do
      if petFilter[j] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petFilter[j].base_conf_id)
        learnskillid = petBaseConf and petBaseConf.level_skill_conf_id or 0
      end
      local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(learnskillid)
      local PetLevelSkillList = {}
      local Allmachineskilllist = {}
      if LevelSkillConf then
        local machineskilllist = LevelSkillConf.machine_skill_group
        local PetLevelInfo = LevelSkillConf.level
        for l, v in pairs(PetLevelInfo) do
          table.insert(PetLevelSkillList, {
            machine_skill_id = v.param
          })
        end
        
        local function isIdExists(id, table)
          for _, v in ipairs(table) do
            if v.machine_skill_id == id then
              return true
            end
          end
          return false
        end
        
        for _, v in ipairs(machineskilllist) do
          if not isIdExists(v.machine_skill_id, Allmachineskilllist) then
            table.insert(Allmachineskilllist, v)
          end
        end
      end
      local machineskilllistNum = #Allmachineskilllist
      local TempList = {}
      for i = 1, #itemList do
        if #TempList < 1 then
          local List = {}
          table.insert(List, itemList[i])
          local list = {
            ItemId = itemList[i].id,
            List = List,
            conf = itemList[i].conf
          }
          table.insert(TempList, list)
        else
          local num = #TempList
          for k = 1, num do
            if TempList[k].id == itemList[i].id then
              local List = TempList[k].List
              table.insert(List, itemList[i].gid)
              break
            end
            if k == num then
              local List = {}
              table.insert(List, itemList[i])
              local list = {
                ItemId = itemList[i].id,
                List = List,
                conf = itemList[i].conf
              }
              table.insert(TempList, list)
            end
          end
        end
      end
      if #TempList < 1 then
        return bagItemList
      end
      local TempItemList = {}
      local TempListNum = #TempList
      for k = 1, machineskilllistNum do
        for i = 1, TempListNum do
          local bagItemConf = TempList[i].conf
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            if Allmachineskilllist[k].machine_skill_id == skillMachineid then
              table.insert(TempItemList, TempList[i].List)
            end
          end
        end
      end
      if #TempItemList < 1 then
        return bagItemList
      end
      local TempItemListNum = #TempItemList
      for i = 1, TempItemListNum do
        local List = TempItemList[i]
        local num = #List
        for k = 1, num do
          if not ItemGidDic[List[k].gid] then
            ItemGidDic[List[k].gid] = true
            table.insert(bagItemList, List[k])
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function PetUtils.FilterDepart(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].filterData.bagitem_id then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].filterData.bagitem_id)
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            if skillConf.skill_dam_type == enum then
              table.insert(bagItemList, itemList[i])
            end
          end
        elseif itemList[i].filterData and itemList[i].filterData.petbase_id then
          local petbaseConf = _G.DataConfigManager:GetPetbaseConf(itemList[i].filterData.petbase_id)
          if petbaseConf then
            for k = 1, #petbaseConf.unit_type do
              local unitType = petbaseConf.unit_type[k]
              if unitType == enum then
                table.insert(bagItemList, itemList[i])
              end
            end
          end
        else
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            if skillConf.skill_dam_type == enum then
              table.insert(bagItemList, itemList[i])
            end
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function PetUtils.FilterClassify(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].id then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            if skillConf.Skill_Type == enum then
              table.insert(bagItemList, itemList[i])
            end
          end
        elseif itemList[i].filterData and itemList[i].filterData.bagitem_id then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].filterData.bagitem_id)
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            if skillConf.Skill_Type == enum then
              table.insert(bagItemList, itemList[i])
            end
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function PetUtils.GetBaseConfId(confId)
  if confId > 1000000 then
    return math.modf(confId / 1000)
  else
    return confId
  end
end

function PetUtils.GetPetPhase(confId)
  if confId > 1000000 then
    confId = confId - 1000000
  end
  local phase = math.modf(confId / 1000)
  return phase
end

function PetUtils.CalcProperty(petCfg, petData, propertyType)
  return 0
end

function PetUtils.CalcRaceValue(petCfg, petData)
  local hp = petCfg.hp_max_race
  local atk = petCfg.phy_attack_race
  local defense = petCfg.phy_defence_race
  local speAtk = petCfg.spe_attack_race
  local speDef = petCfg.spe_defence_race
  local spd = petCfg.speed_race
  return hp + atk + defense + speAtk + speDef + spd
end

function PetUtils.CalcBasicProperty(petCfg, petData, propertyType)
  local groupValue = 0
  local talent = 0
  local base_point = 0
  local baseValue = 0
  local groupConst = 0
  local talentConst = 0
  local pointConst = 0
  local levelConst = 0
  if propertyType == Enum.AttributeType.AT_HPMAX then
    groupValue = petCfg.hp_max_race
    talent = petData.attribute_info.hp.talent
    base_point = petData.attribute_info.hp.base_point
    baseValue = petCfg.hp_max_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("hp_max_level_constant").num
  elseif propertyType == Enum.AttributeType.AT_PHYATK then
    groupValue = petCfg.phy_attack_race
    talent = petData.attribute_info.attack.talent
    base_point = petData.attribute_info.attack.base_point
    baseValue = petCfg.phy_attack_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_level_constant").num
  elseif propertyType == Enum.AttributeType.AT_PHYDEF then
    groupValue = petCfg.phy_defence_race
    talent = petData.attribute_info.defense.talent
    base_point = petData.attribute_info.defense.base_point
    baseValue = petCfg.phy_defence_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_level_constant").num
  elseif propertyType == Enum.AttributeType.AT_SPEATK then
    groupValue = petCfg.spe_attack_race
    talent = petData.attribute_info.special_attack.talent
    base_point = petData.attribute_info.special_attack.base_point
    baseValue = petCfg.spe_attack_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_level_constant").num
  elseif propertyType == Enum.AttributeType.AT_SPEDEF then
    groupValue = petCfg.spe_defence_race
    talent = petData.attribute_info.special_defense.talent
    base_point = petData.attribute_info.special_defense.base_point
    baseValue = petCfg.spe_defence_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_level_constant").num
  elseif propertyType == Enum.AttributeType.AT_SPEED then
    groupValue = petCfg.speed_race
    talent = petData.attribute_info.speed.talent
    base_point = petData.attribute_info.speed.base_point
    baseValue = petCfg.speed_first
    groupConst = _G.DataConfigManager:GetAttrGlobalConfig("speed_race_constant").num
    talentConst = _G.DataConfigManager:GetAttrGlobalConfig("speed_talent_constant").num
    pointConst = _G.DataConfigManager:GetAttrGlobalConfig("speed_base_point_constant").num
    levelConst = _G.DataConfigManager:GetAttrGlobalConfig("speed_level_constant").num
  end
  local factor = _G.DataConfigManager:GetGlobalConfigByKeyType("prob_calculate_param", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  local ret = (groupConst / factor * groupValue + talent * (talentConst / factor)) * petData.level + baseValue + petData.level * (levelConst / factor)
  return math.floor(ret + 0.5)
end

function PetUtils.GetLevelUpData(petData)
  local petLv = petData.level or 0
  local evolutionPetBaseId, evolutionIndex = PetUtils.GetEvolutionPetBaseId(petData)
  if not evolutionPetBaseId then
    return nil
  end
  local evolutionPetBaseConf = _G.DataConfigManager:GetPetbaseConf(evolutionPetBaseId)
  local evolution_poss_level = evolutionPetBaseConf.evolution_poss_level
  local evolution_need_level = evolutionPetBaseConf.evolution_need_level
  local LvRange = petLv - evolution_poss_level
  if petLv < evolution_need_level then
    local evolutionLvTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.EVOLUTION_LEVEL_DATA):GetAllDatas()
    for _, v in pairs(evolutionLvTable) do
      if LvRange >= v.level_lower_limit and LvRange <= v.level_upper_limit then
        local data = {}
        data.evoType = false
        data.evolutionleveldata = v
        return data
      end
    end
  else
    local data = {}
    data.evoType = true
    data.evolutionPetBaseConf = evolutionPetBaseConf
    data.evolutionIndex = evolutionIndex
    return data
  end
end

function PetUtils.GetEvolutionPetBaseId(petData)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local petEvolutionList = petBaseConf.evolution_pet_id
  local petEquipSkillList = PetUtils.GetPetEquipSkills(petData)
  local TargetEvoPetBaseId
  local playerRedPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  for k, v in ipairs(playerRedPointInfo) do
    if (v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_TEAM or v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_BACKPACK) and v.point_data and #v.point_data > 0 then
      for key, val in ipairs(v.point_data) do
        local dataList = string.Split(val, ".")
        if petData and petData.gid == tonumber(dataList[1]) then
          TargetEvoPetBaseId = dataList[2]
          if "string" == type(TargetEvoPetBaseId) then
            TargetEvoPetBaseId = tonumber(TargetEvoPetBaseId)
          end
          break
        end
      end
    end
  end
  if petEvolutionList then
    for i = 1, #petEvolutionList do
      if petEvolutionList[i] and TargetEvoPetBaseId == petEvolutionList[i] then
        return TargetEvoPetBaseId, i
      end
    end
    return nil
  end
end

function PetUtils.GetPetEquipSkills(petData)
  local petEquipSkills = {}
  if petData then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  return petEquipSkills
end

function PetUtils.GetPetCollectTagIcon(partner_mark)
  local PetFilterConf = _G.DataConfigManager:GetAllByName("PET_FILTER_CONF")
  for _, v in pairs(PetFilterConf) do
    if v.filter_type == Enum.FilterRule.FIL_PET_MARK and _G.Enum[v.filter_enum_name][v.filter_enum_value] == partner_mark then
      return v.filter_icon
    end
  end
  return ""
end

function PetUtils.GetPetEvolutionTrain(type, petBaseId)
  local petEvolutionTrainList = {}
  if 0 == type then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if petBaseConf.evolution_pet_id then
      for i = 1, #petBaseConf.evolution_pet_id do
        table.insert(petEvolutionTrainList, petBaseConf.evolution_pet_id[i])
      end
      for i = 1, #petEvolutionTrainList do
        if petBaseConf.evolution_pet_id then
          table.insert(petEvolutionTrainList, petBaseConf.evolution_pet_id[i])
        end
      end
      return petEvolutionTrainList
    end
  elseif 1 == type then
    local petBaseInfo = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PETBASE_CONF)
    for k, v in ipairs(petBaseInfo) do
      if v then
        for i = 1, #v do
          if v == petBaseId then
            table.insert(petEvolutionTrainList, k)
          end
        end
      end
    end
    for k, v in ipairs(petEvolutionTrainList) do
      if v then
        for i = 1, #v do
          if v == petBaseId then
            table.insert(petEvolutionTrainList, k)
          end
        end
      end
    end
    return petEvolutionTrainList
  end
end

function PetUtils.RedShow(_records)
  local records = _records
  for i, record in ipairs(records) do
    if record.study_lv then
      local PetHandbook = _G.DataConfigManager:GetPetHandbook(record.pet_base_id)
      for j, awardlist in ipairs(record.award_get_list) do
        if j <= record.study_lv and false == awardlist and PetHandbook.pet_handbook[j].award_type == _G.Enum.PetHandbookAward.AWARD_ITEM then
          return true
        end
      end
    end
  end
  return false
end

function PetUtils.GetEvoListIDs(baseID)
  local tablelist = {}
  local find = true
  local findid = baseID
  while find do
    local id = PetUtils.GetEvo(findid)
    if id then
      findid = id
      table.insert(tablelist, id)
    else
      find = false
    end
  end
  local evoIds = {}
  local count = #tablelist
  for i = count, 1, -1 do
    table.insert(evoIds, tablelist[i])
  end
  table.insert(evoIds, baseID)
  return evoIds
end

function PetUtils.GetEvo(baseID)
  local dataTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PETBASE_CONF)
  local petConfs = NRCModuleManager:GetModule("PetUIModule"):GetData():GetPetBaseConf() or dataTable:GetAllDatas()
  for i, data in pairs(petConfs) do
    local evolutionPetId = data.evolution_pet_id
    if #evolutionPetId > 0 then
      for j = 1, #evolutionPetId do
        if evolutionPetId[j] == baseID then
          return data.id
        end
      end
    end
  end
end

function PetUtils.GetEvoWithConf(baseID, petConfs)
  for i, data in pairs(petConfs) do
    if #data.evolution_pet_id > 0 then
      for j = 1, #data.evolution_pet_id do
        if data.evolution_pet_id[j] == baseID then
          return data.id
        end
      end
    end
  end
end

function PetUtils.GetBattlePetSocketPosition3D(Pet)
  local socketName = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Body)
  local meshComponent = Pet.model:GetComponentByClass(UE.UMeshComponent)
  if meshComponent then
    return meshComponent:Abs_GetSocketLocation(socketName)
  end
  Log.Error("locator pos not found")
  return
end

function PetUtils.GetBattlePetSocketPosition2D(Pet)
  local vP = UE4.FVector2D(0, 0)
  if not Pet then
    return vP
  end
  if not Pet.model then
    return vP
  end
  local uP = UE4.FVector2D(0, 0)
  UE4.UGameplayStatics.Abs_ProjectWorldToScreen(UE4.UGameplayStatics.GetPlayerController(Pet.model, 0), Pet.buffPos, uP, false)
  UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), uP, vP)
  return vP
end

function PetUtils.GetMultiplayerTargetAnimByHealth(Rate, isSelf)
  if isSelf then
    return "Happy"
  end
  if not Rate then
    return "Show"
  end
  Rate = Rate * 100
  if Rate <= 20 then
    return "Fear"
  elseif Rate >= 20 and Rate < 50 then
    return "Shock"
  else
    return "Show"
  end
end

function PetUtils.PetIsEquipmentHaving(_PetData)
  local conf = _G.DataConfigManager:GetPetGlobalConfig("pet_max_equip_num")
  local items = _PetData.possession.item
  local maxNum = conf.num
  local IsEquipHavingAward = false
  for i = 1, maxNum do
    if i <= #items and items[i] and items[i].conf_id then
      IsEquipHavingAward = true
    end
  end
  return IsEquipHavingAward
end

function PetUtils.GetHavingPropertyByPossession(_possession, NextLevel)
  local HavingProperty = {}
  if nil == _possession or nil == _possession.conf_id and nil == _possession.level then
    return HavingProperty
  end
  local possession = _possession
  local level
  if nil ~= NextLevel then
    level = possession.level + NextLevel
  else
    level = possession.level
  end
  local PetCarryonItem = _G.DataConfigManager:GetPetCarryonItem(possession.conf_id)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(possession.conf_id)
  local PetCarryonUpgrade = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_CARRYON_UPGRADE):GetAllDatas()
  for i, Upgrade in pairs(PetCarryonUpgrade) do
    if PetCarryonItem.upgrade_cost == Upgrade.sort_id and level == Upgrade.level then
      for _, v in ipairs(Upgrade.carryon_attr) do
        local AttributeConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ATTRIBUTE_CONF):GetAllDatas()
        for j, Attribute in ipairs(AttributeConf) do
          if v.attr_enum == Attribute.attribute then
            table.insert(HavingProperty, {
              AttributeConf = Attribute,
              PetCarryonUpgrade = v,
              bagItemConf = bagItemConf
            })
          end
        end
      end
    end
  end
  if nil == HavingProperty or nil == HavingProperty[1] then
    return nil
  end
  return HavingProperty
end

function PetUtils.GetHavingSkillPropertyByPossession(_possession, NewAddStage, IsRestrictMax)
  local HavingSkillProperty = {}
  if nil == _possession then
    return HavingSkillProperty
  end
  local possession = _possession
  local id = possession.conf_id
  local stage = possession.stage
  if nil == stage then
    stage = 0
  end
  if nil ~= NewAddStage then
    stage = stage + NewAddStage
    if true == IsRestrictMax then
      local PetGlobalConf = _G.DataConfigManager:GetPetGlobalConfig("max_resonance_time")
      if stage >= PetGlobalConf.num then
        stage = PetGlobalConf.num
      end
    end
  end
  local PetCarryonItem = _G.DataConfigManager:GetPetCarryonItem(id)
  local SkillId = PetCarryonItem.skill[stage + 1]
  if nil ~= SkillId then
    local SkillConf = _G.DataConfigManager:GetSkillConf(SkillId)
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(possession.conf_id)
    HavingSkillProperty.SkillConf = SkillConf
    HavingSkillProperty.bagItemConf = bagItemConf
    HavingSkillProperty.PetCarryonItem = PetCarryonItem
  end
  return HavingSkillProperty
end

function PetUtils.GetPetIsEquipmentByHavingId(_conf_id)
  local conf_id = _conf_id
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if battlePetList then
    for i, petData in pairs(battlePetList.pet_data) do
      local num = #petData.possession.item
      if num > 0 then
        for j = 1, num do
          local possessItem = petData.possession.item[j]
          if possessItem.conf_id ~= nil and possessItem.conf_id > 0 and possessItem.conf_id == conf_id then
            return true
          end
        end
      end
    end
  end
  return false
end

function PetUtils.IsCommonEvolution(petGid1, petGid2)
  local petInfo1 = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid1)
  local baseConfId1 = petInfo1 and petInfo1.base_conf_id
  local petBaseConf1 = _G.DataConfigManager:GetPetbaseConf(baseConfId1, true)
  local petEvolutionId1 = petBaseConf1 and petBaseConf1.pet_evolution_id
  local petInfo2 = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid2)
  local baseConfId2 = petInfo2 and petInfo2.base_conf_id
  local petBaseConf2 = _G.DataConfigManager:GetPetbaseConf(baseConfId2, true)
  local petEvolutionId2 = petBaseConf2 and petBaseConf2.pet_evolution_id
  if petEvolutionId1 and petEvolutionId2 then
    local petEvoID1 = petEvolutionId1[1]
    local petEvoID2 = petEvolutionId2[1]
    if petEvoID1 and petEvoID2 then
      if petEvoID1 == petEvoID2 then
        return true
      end
      local evoCfg1 = _G.DataConfigManager:GetPetEvolutionConf(petEvoID1)
      local evoCfg2 = _G.DataConfigManager:GetPetEvolutionConf(petEvoID2)
      if evoCfg1 and evoCfg2 and evoCfg1.pvp_mute_group and evoCfg2.pvp_mute_group then
        return evoCfg1.pvp_mute_group == evoCfg2.pvp_mute_group
      else
        return false
      end
    else
      return false
    end
  else
    return petGid1 == petGid2
  end
end

function PetUtils.CheckPvpTeamIsMirror(team_index, TeamType)
  Log.Debug(team_index, TeamType, "CheckPvpTeamIsMirror")
  local teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  if TeamType then
    if TeamType == Enum.PlayerTeamType.PTT_BIG_WORLD then
      teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
    else
      teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(TeamType)
    end
  end
  if not teamInfo then
    return
  end
  local InitTeam = teamInfo.teams[team_index + 1]
  if not InitTeam then
    return
  end
  return InitTeam.is_mirror
end

function PetUtils.CheckPvpTeamValid(Team, TeamType)
  if TeamType == Enum.PlayerTeamType.PTT_BIG_WORLD then
    return true
  else
    local vis = {}
    local groupMap = {}
    for _, petGid in pairs(Team) do
      local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid, true)
      if petInfo then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id, true)
        local petEvoID = petBaseConf and petBaseConf.pet_evolution_id[1]
        local petEvoConf
        if petEvoID then
          petEvoConf = _G.DataConfigManager:GetPetEvolutionConf(petEvoID)
        end
        if petEvoConf then
          if groupMap[petEvoConf.pvp_mute_group] then
            return false
          else
            groupMap[petEvoConf.pvp_mute_group] = true
          end
        elseif petInfo.base_conf_id then
          if vis[petInfo.base_conf_id] then
            return false
          else
            vis[petInfo.base_conf_id] = true
          end
        end
      else
        Log.Error("\228\187\142\231\142\169\229\174\182\232\186\171\228\184\138\232\142\183\229\143\150\229\174\160\231\137\169petGid=", petGid, "\229\164\177\232\180\165")
      end
    end
    return true
  end
end

function PetUtils.GetPetTeamActivedResonances(team, _IsFirstOpenPanel)
  local activedResonances = {}
  if team and team.pet_infos then
    local unityTypeDic = {}
    for _, petInfo in ipairs(team.pet_infos) do
      if petInfo.pet_gid then
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petInfo.pet_gid)
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
        if petBaseConf then
          local unit_types = petBaseConf.unit_type
          for _, unitType in ipairs(unit_types) do
            if nil == unityTypeDic[unitType] then
              unityTypeDic[unitType] = {}
            end
            local reduplicated = false
            local petList = unityTypeDic[unitType]
            for _, t in ipairs(petList) do
              if t.petBaseConf.id == petBaseConf.id then
                reduplicated = true
                break
              end
            end
            if not reduplicated then
              local t = {
                gid = petInfo.pet_gid,
                petBaseConf = petBaseConf
              }
              table.insert(unityTypeDic[unitType], t)
            end
          end
        end
      end
    end
    for _unit_type, pets in pairs(unityTypeDic) do
      local petNum = #pets
      local activedNum = 0
      local colorConf = _G.DataConfigManager:GetSkillColorConf(_unit_type)
      for _, type_synchron in ipairs(colorConf.type_synchron) do
        local synNum = type_synchron.synchron_number
        if petNum >= synNum and activedNum < synNum then
          activedNum = synNum
        end
      end
      if activedNum > 0 then
        local typeCfg = _G.DataConfigManager:GetTypeDictionary(colorConf.unit_type)
        local t = {
          activedNum = activedNum,
          typeCfg = typeCfg,
          pets = pets,
          IsFirstOpenPanel = _IsFirstOpenPanel
        }
        table.insert(activedResonances, t)
      end
    end
  end
  return activedResonances
end

function PetUtils.PetInfoCreate(petGid)
  local petInfo = ProtoMessage:newPvpFightHis_PetInfo()
  petInfo.pet_gid = petGid
  return petInfo
end

function PetUtils.GetIsMainTeamByGid(petGid)
  local IsMainTeam = false
  local petIndex = 0
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  local TeamIndex = teamInfo.main_team_idx or 0
  if teamInfo.teams then
    for j, team in ipairs(teamInfo.teams) do
      local petInfo, petInfoIndex = PetUtils.PetTeamFindPetInfoByIndex(team, petGid)
      if petInfo and j == TeamIndex + 1 then
        IsMainTeam = true
        petIndex = petInfoIndex
      end
    end
  end
  return IsMainTeam, petIndex
end

function PetUtils.GetIsInPvpOrPveTeamByGid(petGid)
  local IsInTeam = false
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfos = petInfoList.team_infos
  local teamInfo = {}
  local PvpConf = _G.DataConfigManager:GetAllByName("PVP_CONF")
  if teamInfos and #teamInfos > 0 then
    for i, v in ipairs(teamInfos) do
      if v.team_type ~= Enum.PlayerTeamType.PTT_BIG_WORLD and v.team_type ~= Enum.PlayerTeamType.PTT_INVALID then
        local isShow = true
        for j, conf in pairs(PvpConf) do
          if conf.team_type == v.team_type then
            isShow = conf.is_show
          end
        end
        if isShow then
          local teams = v.teams
          for j, team in ipairs(teams) do
            local petInfo, petInfoIndex = PetUtils.PetTeamFindPetInfoByIndex(team, petGid)
            if petInfo then
              table.insert(teamInfo, {teamInfo = v, teamIndex = j})
            end
          end
        end
      end
    end
  end
  if #teamInfo > 0 then
    IsInTeam = true
  end
  return IsInTeam, teamInfo
end

function PetUtils.PetTeamGetPetGidList(team)
  if not team or next(team) == nil then
    return nil
  end
  if not team.pet_infos then
    return nil
  end
  
  local function callback(pet_info)
    return pet_info.pet_gid
  end
  
  local pet_gid_list = Array(table.unpack(team.pet_infos)):Map(callback):Items()
  return pet_gid_list
end

function PetUtils.PetTeamFindPetInfoByIndex(team, petGid)
  if not team or next(team) == nil then
    return nil, -1
  end
  if not team.pet_infos then
    return nil, -1
  end
  for i, petInfo in ipairs(team.pet_infos) do
    if nil ~= petInfo and petInfo.pet_gid == petGid then
      return petInfo, i
    end
  end
  return nil, -1
end

function PetUtils.CheckIsBigWorldTeamPet(petGid)
  local IsBigWorldTeamPet = false
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, Enum.PlayerTeamType.PTT_BIG_WORLD)
  if teamInfo and teamInfo.teams then
    for _, team in pairs(teamInfo.teams) do
      local petInfo = PetUtils.PetTeamFindPetInfoByIndex(team, petGid)
      if petInfo then
        IsBigWorldTeamPet = true
      end
    end
  end
  return IsBigWorldTeamPet
end

function PetUtils.CheckIsTheLastBigWorldTeamPet(petGid)
  local IsTheLastBigWorldTeamPet = false
  local IsBigWorldTeamPet = false
  local IsOnlyOnePet = false
  local PetNumInBigWorldTeam = 0
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, Enum.PlayerTeamType.PTT_BIG_WORLD)
  if teamInfo and teamInfo.teams then
    for _, team in pairs(teamInfo.teams) do
      if team.pet_infos then
        PetNumInBigWorldTeam = PetNumInBigWorldTeam + #team.pet_infos
      end
      local petInfo = PetUtils.PetTeamFindPetInfoByIndex(team, petGid)
      if petInfo then
        IsBigWorldTeamPet = true
      end
    end
    if 1 == PetNumInBigWorldTeam then
      IsOnlyOnePet = true
    end
    if IsBigWorldTeamPet and IsOnlyOnePet then
      IsTheLastBigWorldTeamPet = true
    end
  end
  return IsTheLastBigWorldTeamPet
end

function PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, teamType)
  if not playerPetInfo or next(playerPetInfo) == nil or not playerPetInfo.team_infos then
    return nil, -1
  end
  for i, teamInfo in pairs(playerPetInfo.team_infos) do
    if teamInfo.team_type == teamType then
      return teamInfo, i
    end
  end
  return nil, -1
end

function PetUtils.PlayerPetInfoSetTeamInfo(playerPetInfo, petTeamInfo, teamType)
  if not playerPetInfo or next(playerPetInfo) == nil then
    return
  end
  if not playerPetInfo.team_infos then
    playerPetInfo.team_infos = {}
  end
  if not petTeamInfo or next(petTeamInfo) == nil then
    return
  end
  local teamInfoResult = teamType and {
    PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, teamType)
  } or {
    PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, petTeamInfo.team_type)
  }
  local previousPetTeamInfo = teamInfoResult[1]
  local previousPetTeamInfoIndex = teamInfoResult[2]
  if previousPetTeamInfo then
    playerPetInfo.team_infos[previousPetTeamInfoIndex] = petTeamInfo
  else
    table.insert(playerPetInfo.team_infos, petTeamInfo)
  end
end

function PetUtils.DamageTypeToPetType(SkillDamageType, Default)
  Default = Default or 5
  if nil == SkillDamageType then
    return Default
  end
  if PetUtils.DamageToPetType[SkillDamageType] then
    return PetUtils.DamageToPetType[SkillDamageType]
  else
    return Default
  end
end

function PetUtils.WorldCombatBuffToUIIdx(WorldCombatBuffType, Default)
  Default = Default or 0
  if nil == WorldCombatBuffType then
    return Default
  end
  if PetUtils.WorldCombatBuffToUIType[WorldCombatBuffType] then
    return PetUtils.WorldCombatBuffToUIType[WorldCombatBuffType]
  else
    return Default
  end
end

function PetUtils.GetPetCurBloodSkillConf(petData)
  if not petData then
    Log.Error("petData is nil")
  end
  for i, v in ipairs(petData.skill.skill_data) do
    if v.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      return _G.DataConfigManager:GetSkillConf(v.id)
    end
  end
  return nil
end

function PetUtils.GetSkillBloodData(blood_id, LevelSkillConf)
  if not LevelSkillConf then
    Log.Error("LevelSkillConf is nil")
    return
  end
  if blood_id == Enum.PetBloodType.PBT_COMMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_COMMON)
  elseif blood_id == Enum.PetBloodType.PBT_GRASS then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GRASS)
  elseif blood_id == Enum.PetBloodType.PBT_FIRE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIRE)
  elseif blood_id == Enum.PetBloodType.PBT_WATER then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WATER)
  elseif blood_id == Enum.PetBloodType.PBT_LIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_LIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_STONE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_STONE)
  elseif blood_id == Enum.PetBloodType.PBT_ICE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ICE)
  elseif blood_id == Enum.PetBloodType.PBT_DRAGON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DRAGON)
  elseif blood_id == Enum.PetBloodType.PBT_ELECTRIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ELECTRIC)
  elseif blood_id == Enum.PetBloodType.PBT_TOXIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_TOXIC)
  elseif blood_id == Enum.PetBloodType.PBT_INSECT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_INSECT)
  elseif blood_id == Enum.PetBloodType.PBT_FIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_WING then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WING)
  elseif blood_id == Enum.PetBloodType.PBT_MOE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MOE)
  elseif blood_id == Enum.PetBloodType.PBT_GHOST then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GHOST)
  elseif blood_id == Enum.PetBloodType.PBT_DEMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DEMON)
  elseif blood_id == Enum.PetBloodType.PBT_MECHANIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MECHANIC)
  elseif blood_id == Enum.PetBloodType.PBT_PHANTOM then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_PHANTOM)
  end
end

function PetUtils.GetPetBloodBySkillDamType(SkillDamType)
  local skillToBloodMap = {
    [Enum.SkillDamType.SDT_NONE] = Enum.PetBloodType.PBT_COMMON,
    [Enum.SkillDamType.SDT_COMMON] = Enum.PetBloodType.PBT_COMMON,
    [Enum.SkillDamType.SDT_GRASS] = Enum.PetBloodType.PBT_GRASS,
    [Enum.SkillDamType.SDT_FIRE] = Enum.PetBloodType.PBT_FIRE,
    [Enum.SkillDamType.SDT_WATER] = Enum.PetBloodType.PBT_WATER,
    [Enum.SkillDamType.SDT_LIGHT] = Enum.PetBloodType.PBT_LIGHT,
    [Enum.SkillDamType.SDT_STONE] = Enum.PetBloodType.PBT_STONE,
    [Enum.SkillDamType.SDT_ICE] = Enum.PetBloodType.PBT_ICE,
    [Enum.SkillDamType.SDT_DRAGON] = Enum.PetBloodType.PBT_DRAGON,
    [Enum.SkillDamType.SDT_ELECTRIC] = Enum.PetBloodType.PBT_ELECTRIC,
    [Enum.SkillDamType.SDT_TOXIC] = Enum.PetBloodType.PBT_TOXIC,
    [Enum.SkillDamType.SDT_INSECT] = Enum.PetBloodType.PBT_INSECT,
    [Enum.SkillDamType.SDT_FIGHT] = Enum.PetBloodType.PBT_FIGHT,
    [Enum.SkillDamType.SDT_WING] = Enum.PetBloodType.PBT_WING,
    [Enum.SkillDamType.SDT_MOE] = Enum.PetBloodType.PBT_MOE,
    [Enum.SkillDamType.SDT_GHOST] = Enum.PetBloodType.PBT_GHOST,
    [Enum.SkillDamType.SDT_DEMON] = Enum.PetBloodType.PBT_DEMON,
    [Enum.SkillDamType.SDT_MECHANIC] = Enum.PetBloodType.PBT_MECHANIC,
    [Enum.SkillDamType.SDT_PHANTOM] = Enum.PetBloodType.PBT_PHANTOM,
    [Enum.SkillDamType.SDT_INVALID] = Enum.PetBloodType.PBT_COMMON,
    [Enum.SkillDamType.SDT_EARTH] = Enum.PetBloodType.PBT_STONE,
    [Enum.SkillDamType.SDT_RELAX] = Enum.PetBloodType.PBT_COMMON
  }
  return skillToBloodMap[SkillDamType] or Enum.PetBloodType.PBT_COMMON
end

function PetUtils.GetSkillDamTypeByPetBloodType(petBloodType)
  local bloodTypeToDamTypeMap = {
    [Enum.PetBloodType.PBT_COMMON] = Enum.SkillDamType.SDT_COMMON,
    [Enum.PetBloodType.PBT_GRASS] = Enum.SkillDamType.SDT_GRASS,
    [Enum.PetBloodType.PBT_FIRE] = Enum.SkillDamType.SDT_FIRE,
    [Enum.PetBloodType.PBT_WATER] = Enum.SkillDamType.SDT_WATER,
    [Enum.PetBloodType.PBT_LIGHT] = Enum.SkillDamType.SDT_LIGHT,
    [Enum.PetBloodType.PBT_STONE] = Enum.SkillDamType.SDT_STONE,
    [Enum.PetBloodType.PBT_ICE] = Enum.SkillDamType.SDT_ICE,
    [Enum.PetBloodType.PBT_DRAGON] = Enum.SkillDamType.SDT_DRAGON,
    [Enum.PetBloodType.PBT_ELECTRIC] = Enum.SkillDamType.SDT_ELECTRIC,
    [Enum.PetBloodType.PBT_TOXIC] = Enum.SkillDamType.SDT_TOXIC,
    [Enum.PetBloodType.PBT_INSECT] = Enum.SkillDamType.SDT_INSECT,
    [Enum.PetBloodType.PBT_FIGHT] = Enum.SkillDamType.SDT_FIGHT,
    [Enum.PetBloodType.PBT_WING] = Enum.SkillDamType.SDT_WING,
    [Enum.PetBloodType.PBT_MOE] = Enum.SkillDamType.SDT_MOE,
    [Enum.PetBloodType.PBT_GHOST] = Enum.SkillDamType.SDT_GHOST,
    [Enum.PetBloodType.PBT_DEMON] = Enum.SkillDamType.SDT_DEMON,
    [Enum.PetBloodType.PBT_MECHANIC] = Enum.SkillDamType.SDT_MECHANIC,
    [Enum.PetBloodType.PBT_PHANTOM] = Enum.SkillDamType.SDT_PHANTOM
  }
  return bloodTypeToDamTypeMap[petBloodType] or Enum.SkillDamType.SDT_COMMON
end

function PetUtils.GetPetFeatrueSkillId(baseConf)
  if not baseConf then
    return 0, false
  end
  local skillId = baseConf.pet_feature
  if 0 ~= skillId then
    return skillId, false
  else
    local evolution_pet_id = baseConf.evolution_pet_id[1]
    if nil == evolution_pet_id then
      return
    end
    local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
    if evolution_pet_id then
      skillId = evoPetbaseCfg.pet_feature
      if 0 ~= skillId then
        return skillId, true
      end
    end
  end
  return 0
end

function PetUtils.IsPreciousPet(PetList, BaseConf)
  local TypeString = ""
  local IsPrecious = false
  local has_grow_times = false
  local Is_PTR_PERFECT = false
  local Is_MDT_GLASS = false
  local Is_MDT_SHINING_GLASS = false
  local Is_MDT_SHINING = false
  local Is_PBT_BOSS = false
  local Is_PBT_NIGHTMARE = false
  local is_pet_legendary = false
  for _, PetData in pairs(PetList) do
    if PetData.grow_times and PetData.grow_times >= 1 and not has_grow_times then
      has_grow_times = true
    end
    if PetData.talent_rank >= _G.Enum.PetTalentRate.PTR_PERFECT and not Is_PTR_PERFECT then
      Is_PTR_PERFECT = true
    end
    if (PetData.mutation_type or 0) & _G.Enum.MutationDiffType.MDT_GLASS > 0 and not Is_MDT_GLASS then
      Is_MDT_GLASS = true
    end
    if PetUtils.CheckIsShiningGlass(PetData.mutation_type) and not Is_MDT_SHINING_GLASS then
      Is_MDT_SHINING_GLASS = true
    end
    if (PetData.mutation_type or 0) & _G.Enum.MutationDiffType.MDT_SHINING > 0 and not Is_MDT_SHINING then
      Is_MDT_SHINING = true
    end
    if PetData.blood_id == Enum.PetBloodType.PBT_BOSS and not Is_PBT_BOSS then
      Is_PBT_BOSS = true
    end
    if PetData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE and not Is_PBT_NIGHTMARE then
      Is_PBT_NIGHTMARE = true
    end
    local LEGENDARY_BATTLE_EVENT = _G.DataConfigManager:GetAllByName("LEGENDARY_BATTLE_EVENT")
    for _, v in pairs(LEGENDARY_BATTLE_EVENT) do
      if v.pet_base_id then
        if v.pet_base_id == PetData.base_conf_id then
          is_pet_legendary = true
          break
        else
          local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(v.pet_base_id)
          if PetBaseConf.pet_evolution_id[1] then
            local PetEvolutionConf = _G.DataConfigManager:GetPetEvolutionConf(PetBaseConf.pet_evolution_id[1])
            if PetEvolutionConf and PetEvolutionConf.evolution_chain then
              for _, PetEvolution in pairs(PetEvolutionConf.evolution_chain) do
                if PetEvolution.petbase_id == PetData.base_conf_id then
                  is_pet_legendary = true
                  break
                end
              end
            end
          end
          if is_pet_legendary then
            break
          end
        end
      end
    end
  end
  if has_grow_times or Is_PTR_PERFECT or Is_MDT_GLASS or Is_MDT_SHINING_GLASS or Is_MDT_SHINING or Is_PBT_BOSS or Is_PBT_NIGHTMARE or is_pet_legendary then
    IsPrecious = true
  end
  if has_grow_times then
    TypeString = TypeString .. "\229\183\178\229\159\185\229\133\187,"
  end
  if Is_PTR_PERFECT then
    TypeString = TypeString .. "\228\186\134\228\184\141\232\181\183\229\164\169\229\136\134,"
  end
  if Is_MDT_GLASS then
    TypeString = TypeString .. "\231\130\171\229\189\169,"
  end
  if Is_MDT_SHINING_GLASS then
    TypeString = TypeString .. "\231\130\171\229\189\169\229\188\130\232\137\178,"
  end
  if Is_MDT_SHINING then
    TypeString = TypeString .. "\229\188\130\232\137\178,"
  end
  if Is_PBT_BOSS then
    TypeString = TypeString .. "\233\166\150\233\162\134\232\161\128\232\132\137,"
  end
  if Is_PBT_NIGHTMARE then
    TypeString = TypeString .. "\229\153\169\230\162\166,"
  end
  if is_pet_legendary then
    TypeString = TypeString .. LuaText.rare_pet_release_tips_8 .. ","
  end
  TypeString = string.sub(TypeString, 1, TypeString:len() - 1)
  return IsPrecious, TypeString
end

function PetUtils.AddRewardToItemList(RewardItems, List)
  local AwardList = List
  for j, rewardConf in pairs(RewardItems) do
    if AwardList and AwardList[rewardConf.Id] then
      AwardList[rewardConf.Id].Count = AwardList[rewardConf.Id].Count + rewardConf.Count
    else
      local Rewards = {}
      Rewards.Count = rewardConf.Count
      Rewards.Id = rewardConf.Id
      Rewards.Type = rewardConf.Type
      AwardList[rewardConf.Id] = Rewards
    end
  end
  return AwardList
end

function PetUtils.RemoveRewardToItemList(RewardItems, List)
  local AwardList = List
  for j, rewardConf in pairs(RewardItems) do
    if AwardList and AwardList[rewardConf.Id] then
      AwardList[rewardConf.Id].Count = AwardList[rewardConf.Id].Count - rewardConf.Count
      if AwardList[rewardConf.Id].Count <= 0 then
        AwardList[rewardConf.Id] = nil
      end
    end
  end
  return AwardList
end

function PetUtils.GetPetFreeAwradList(PetInfo, _FreeRewardConf)
  local AwardList = {}
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(PetInfo.catch_base_id)
  if not petBaseConf then
    return {}
  end
  local StarList, Starlevel = PetUtils.GetResidueGrowCountAndGrowOrder(PetInfo)
  local FreeRewardConf = _FreeRewardConf
  FreeRewardConf = FreeRewardConf or _G.DataConfigManager:GetAllByName("PET_FREE_REWARD_CONF")
  for i, v in pairs(FreeRewardConf) do
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_FREESORT and v.free_unlock_data == petBaseConf.petfree_sort then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_SPLOOK and (PetInfo.mutation_type or 0) & _G.Enum.MutationDiffType.MDT_GLASS > 0 then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_SPBLOOD and v.free_unlock_data == PetInfo.blood_id then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_PETBASE and v.free_unlock_data == PetInfo.catch_base_id then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_TALENT and v.free_unlock_data == PetInfo.talent_rank then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_BREAKLV and v.free_unlock_data == Starlevel - 1 then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_GROWTH_TIME and v.free_unlock_data == PetInfo.grow_times then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_MEDAL then
      local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(PetInfo.gid)
      if MedalList and #MedalList > 0 then
        for _, Medal in pairs(MedalList) do
          if Medal.conf_id == v.free_unlock_data then
            local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
            if RewardConf then
              AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
            end
          end
        end
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_BALL and v.free_unlock_data == PetInfo.ball_id then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_LEVEL and v.free_unlock_data == PetInfo.level then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
    if v.free_reward_type == Enum.PetFreeAwardType.PFAT_INSPIRELV and PetInfo.inspire_lv ~= nil and v.free_unlock_data == PetInfo.inspire_lv then
      local RewardConf = _G.DataConfigManager:GetRewardConf(v.free_reward_id)
      if RewardConf then
        AwardList = PetUtils.AddRewardToItemList(RewardConf.RewardItem, AwardList)
      end
    end
  end
  local GrowOrder = Starlevel
  if GrowOrder - 1 > 0 then
    local BreakNumberConf = _G.DataConfigManager:GetBreakNumberConf(GrowOrder - 1)
    if petBaseConf and petBaseConf.break_spec_item_id > 0 and BreakNumberConf.free_memory_item_number and BreakNumberConf.free_memory_item_number > 0 then
      local Rewards = {
        {
          Type = Enum.GoodsType.GT_BAGITEM,
          Id = petBaseConf.break_spec_item_id,
          Count = BreakNumberConf.free_memory_item_number
        }
      }
      AwardList = PetUtils.AddRewardToItemList(Rewards, AwardList)
    end
  end
  return AwardList
end

function PetUtils.CheckPetIsCanFree(petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyFreePvpOrPvePetCaller, ApplyFreePvpOrPvePetCallback, FreeReasonType)
  onlyCheck = onlyCheck or false
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  ApplyFreePvpOrPvePetCaller = ApplyFreePvpOrPvePetCaller or PetUtils
  ApplyFreePvpOrPvePetCallback = ApplyFreePvpOrPvePetCallback or PetUtils.DefaultApplyFreePvpOrPvePetCallback
  FreeReasonType = FreeReasonType or PetUIModuleEnum.PetFreeReasonType.None
  local bCanFree = false
  if not PetUtils.CommonPetHandleCheck(PetUIModuleEnum.PetCommonHandleCheckType.Free, petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyFreePvpOrPvePetCaller, ApplyFreePvpOrPvePetCallback, FreeReasonType) then
    return bCanFree
  end
  if PetUtils.CheckPetIsInherited(petData.gid) then
    if not onlyCheck then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.INHERITANCE_10)
    end
    return bCanFree
  end
  bCanFree = true
  return bCanFree
end

function PetUtils.GetIsInPvpOrPveTeam(petData, onlyCheck, ApplyHandlePvpOrPvePetCaller, ApplyHandlePvpOrPvePetCallback, FreeReasonType, ReleaseTipsOpenType)
  ApplyHandlePvpOrPvePetCaller = ApplyHandlePvpOrPvePetCaller or PetUtils
  ApplyHandlePvpOrPvePetCallback = ApplyHandlePvpOrPvePetCallback or PetUtils.DefaultApplyFreePvpOrPvePetCallback
  FreeReasonType = FreeReasonType or PetUIModuleEnum.PetFreeReasonType.None
  ReleaseTipsOpenType = ReleaseTipsOpenType or PetUIModuleEnum.ReleaseTipsOpenType.None
  local IsInTeam, teamInfo = PetUtils.GetIsInPvpOrPveTeamByGid(petData.gid)
  if IsInTeam then
    if not onlyCheck and nil ~= ApplyHandlePvpOrPvePetCallback then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetReleaseTips, petData, teamInfo, {caller = ApplyHandlePvpOrPvePetCaller, callback = ApplyHandlePvpOrPvePetCallback}, true, FreeReasonType, ReleaseTipsOpenType)
    end
    return true
  else
    return false
  end
end

function PetUtils.DefaultApplyFreePvpOrPvePetCallback()
end

function PetUtils.CheckPetIsCanTraceBack(petData, onlyCheck, checkForShow, bIgnorePvpOrPveTeam, ApplyTraceBackPvpOrPvePetCaller, ApplyTraceBackPvpOrPvePetCallback)
  Log.Debug("PetUtils.CheckPetIsCanTraceBack")
  if nil == onlyCheck then
    onlyCheck = true
  end
  checkForShow = checkForShow or false
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  ApplyTraceBackPvpOrPvePetCaller = ApplyTraceBackPvpOrPvePetCaller or PetUtils
  ApplyTraceBackPvpOrPvePetCallback = ApplyTraceBackPvpOrPvePetCallback or PetUtils.DefaultApplyFreePvpOrPvePetCallback
  local bCanTraceBack = false
  if nil == petData then
    Log.Error("PetUtils.CheckPetIsCanTraceBack petData is nil")
    return bCanTraceBack
  end
  if not checkForShow then
    if not PetUtils.CommonPetHandleCheck(PetUIModuleEnum.PetCommonHandleCheckType.TraceBack, petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyTraceBackPvpOrPvePetCaller, ApplyTraceBackPvpOrPvePetCallback) then
      return bCanTraceBack
    end
    if PetUtils.CheckPetIsInherited(petData.gid) then
      bCanTraceBack = false
      if not onlyCheck then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_activity)
      end
      return bCanTraceBack
    end
  end
  if nil == petData.bitflag then
    return bCanTraceBack
  end
  if nil == petData.base_conf_id then
    Log.Error("PetUtils.CheckPetIsCanTraceBack petData.base_conf_id is nil")
    return bCanTraceBack
  end
  local PetEvolutionIdMap = {}
  local PetBaseConf = DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  if PetBaseConf then
    for _, v in pairs(PetBaseConf.pet_evolution_id or {}) do
      PetEvolutionIdMap[v] = true
    end
  end
  if 0 == petData.bitflag & _G.ProtoEnum.PetDataBitFlag.PDBF_PET_HAS_BACKTRACK_SNAPSHOT then
    bCanTraceBack = false
    return bCanTraceBack
  end
  if 0 == petData.bitflag & _G.ProtoEnum.PetDataBitFlag.PDBF_PET_HAS_BACKTRACK_ITEMS then
    bCanTraceBack = false
    return bCanTraceBack
  end
  local TargetPetRollBackConfig
  local TargetStartTimeStamp = 0
  local PetRollBackConfigs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_ROLLBACK_CONF):GetAllDatas()
  for _, petRollBackConfig in pairs(PetRollBackConfigs or {}) do
    if petRollBackConfig and petRollBackConfig.pet_evolution_id then
      for _, petEvolutionId in pairs(petRollBackConfig.pet_evolution_id or {}) do
        if PetEvolutionIdMap[petEvolutionId] then
          local CurTimeStamp = _G.ZoneServer:GetServerTime() / 1000
          local StartTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.start_time or "")
          local EndTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.end_time or "")
          if CurTimeStamp > StartTimeStamp and CurTimeStamp < EndTimeStamp then
            TargetPetRollBackConfig = petRollBackConfig
            TargetStartTimeStamp = StartTimeStamp
            break
          end
        end
      end
    end
  end
  if nil == TargetPetRollBackConfig or 0 == TargetStartTimeStamp then
    bCanTraceBack = false
    if not onlyCheck then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_tend_tip)
    end
    return bCanTraceBack
  end
  if petData.key_experience and petData.key_experience.backtrack_record_info and petData.key_experience.backtrack_record_info.last_backtrack_time then
    local lastTraceBackTime = petData.key_experience.backtrack_record_info.last_backtrack_time
    if TargetStartTimeStamp < lastTraceBackTime then
      bCanTraceBack = false
      return bCanTraceBack
    end
  end
  bCanTraceBack = true
  return bCanTraceBack
end

function PetUtils.CommonPetHandleCheck(checkType, petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyHandlePvpOrPvePetCaller, ApplyHandlePvpOrPvePetCallback, FreeReasonType)
  local bCanHandle = false
  checkType = checkType or PetUIModuleEnum.PetCommonHandleCheckType.None
  if nil == petData then
    return bCanHandle
  end
  if _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") then
    local bInFollow, Tip = _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, petData.gid, 3)
    if bInFollow then
      if not onlyCheck then
        if checkType == PetUIModuleEnum.PetCommonHandleCheckType.Free then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tip)
        elseif checkType == PetUIModuleEnum.PetCommonHandleCheckType.TraceBack then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_tongxing)
        end
      end
      return bCanHandle
    end
  end
  local isTaskLock = petData.pet_status_flags and petData.pet_status_flags & ProtoEnum.PetStatusFlag.TASK_FORCE_LOCK > 0
  if isTaskLock then
    if not onlyCheck then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2356)
    end
    return bCanHandle
  end
  local IsInActivity = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.IsPetInCurTripInfo, petData.gid)
  if IsInActivity then
    if not onlyCheck then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_trip_54)
    end
    return bCanHandle
  end
  local IsInHome = false
  if petData.business_identity and petData.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET then
    IsInHome = true
  end
  local IsInGuard = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePlantGuardPetGid) == petData.gid
  if IsInHome or IsInGuard then
    if not onlyCheck then
      if checkType == PetUIModuleEnum.PetCommonHandleCheckType.Free then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_pet_cannot_free)
      elseif checkType == PetUIModuleEnum.PetCommonHandleCheckType.TraceBack then
        if IsInGuard then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_guard)
        elseif IsInHome then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_home)
        end
      end
    end
    return bCanHandle
  end
  if petData.partner_mark and petData.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
    if not onlyCheck then
      if checkType == PetUIModuleEnum.PetCommonHandleCheckType.Free then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetPetGlobalConfig("collection_cant_release").str)
      elseif checkType == PetUIModuleEnum.PetCommonHandleCheckType.TraceBack then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_tag)
      end
    end
    return bCanHandle
  end
  if not bIgnorePvpOrPveTeam then
    local IsInPvpOrPveTeam
    if checkType == PetUIModuleEnum.PetCommonHandleCheckType.Free then
      IsInPvpOrPveTeam = PetUtils.GetIsInPvpOrPveTeam(petData, onlyCheck, ApplyHandlePvpOrPvePetCaller, ApplyHandlePvpOrPvePetCallback, FreeReasonType, PetUIModuleEnum.ReleaseTipsOpenType.Free)
    elseif checkType == PetUIModuleEnum.PetCommonHandleCheckType.TraceBack then
      IsInPvpOrPveTeam = PetUtils.GetIsInPvpOrPveTeam(petData, onlyCheck, ApplyHandlePvpOrPvePetCaller, ApplyHandlePvpOrPvePetCallback, nil, PetUIModuleEnum.ReleaseTipsOpenType.TraceBack)
    end
    if IsInPvpOrPveTeam then
      return bCanHandle
    end
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  if nil == petBaseConf then
    return bCanHandle
  end
  if petBaseConf.ban_free and 1 == petBaseConf.ban_free then
    if not onlyCheck then
      if checkType == PetUIModuleEnum.PetCommonHandleCheckType.Free then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petbag_2 .. petBaseConf.name .. LuaText.umg_petbag_3)
      elseif checkType == PetUIModuleEnum.PetCommonHandleCheckType.TraceBack then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_return_ban_special)
      end
    end
    return bCanHandle
  end
  bCanHandle = true
  return bCanHandle
end

function PetUtils.GetTargetPetRollBackConfig(petData)
  local PetEvolutionIdMap = {}
  local PetBaseConf = DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  if PetBaseConf then
    for _, v in pairs(PetBaseConf.pet_evolution_id or {}) do
      PetEvolutionIdMap[v] = true
    end
  end
  local TargetPetRollBackConfig
  local TargetStartTimeStamp = 0
  local PetRollBackConfigs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_ROLLBACK_CONF):GetAllDatas()
  for _, petRollBackConfig in pairs(PetRollBackConfigs or {}) do
    if petRollBackConfig and petRollBackConfig.pet_evolution_id then
      for _, petEvolutionId in pairs(petRollBackConfig.pet_evolution_id or {}) do
        if PetEvolutionIdMap[petEvolutionId] then
          local CurTimeStamp = _G.ZoneServer:GetServerTime() / 1000
          local StartTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.start_time or "")
          local EndTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.end_time or "")
          if CurTimeStamp > StartTimeStamp and CurTimeStamp < EndTimeStamp then
            TargetPetRollBackConfig = petRollBackConfig
            TargetStartTimeStamp = StartTimeStamp
            break
          end
        end
      end
    end
  end
  return TargetPetRollBackConfig
end

function PetUtils.CheckCurIsInTraceBackTime()
  local bInTraceBackTime = false
  local TargetPetRollBackConfig
  local TargetStartTimeStamp = 0
  local PetRollBackConfigs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_ROLLBACK_CONF):GetAllDatas()
  for _, petRollBackConfig in pairs(PetRollBackConfigs or {}) do
    if petRollBackConfig then
      local CurTimeStamp = _G.ZoneServer:GetServerTime() / 1000
      local StartTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.start_time or "")
      local EndTimeStamp = TimeUtils.ToTimeStamp(petRollBackConfig.end_time or "")
      if CurTimeStamp > StartTimeStamp and CurTimeStamp < EndTimeStamp then
        bInTraceBackTime = true
        TargetPetRollBackConfig = petRollBackConfig
        TargetStartTimeStamp = StartTimeStamp
        break
      end
    end
  end
  return bInTraceBackTime
end

function PetUtils.CheckIsShiningGlass(mutation_type)
  local isShining = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
  local isGlass = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_GLASS
  return isShining and isGlass
end

function PetUtils.CheckIsShiningChaos(mutation_type)
  local isShining = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
  local isChaos1 = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_CHAOS
  local isChaos2 = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_CHAOS_TWO
  local isChaos3 = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_CHAOS_THREE
  return isShining and (isChaos1 or isChaos2 or isChaos3)
end

function PetUtils.CheckIsCommonGlass(mutation_type, glass_info)
  local isGlass = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_GLASS
  if glass_info and glass_info.glass_type then
    return isGlass and glass_info.glass_type == _G.Enum.GlassType.GT_COMMON
  end
  return false
end

function PetUtils.CheckIsHiddenGlass(mutation_type, glass_info)
  local isGlass = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_GLASS
  if glass_info and glass_info.glass_type then
    return isGlass and glass_info.glass_type == _G.Enum.GlassType.GT_HIDDEN
  end
  return false
end

function PetUtils.CheckIsHiddenShiningGlass(mutation_type, glass_info)
  local isShining = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
  local isHiddenGlass = PetUtils.CheckIsHiddenGlass(mutation_type, glass_info)
  return isShining and isHiddenGlass
end

function PetUtils.GetShineDataValue(value, bit)
  if not value then
    Log.Error("\228\188\160\229\133\165\231\154\132\231\130\171\229\189\169id\228\184\186\231\169\186\239\188\129\239\188\129\239\188\129")
    return nil, nil
  end
  if math.type(value) == "integer" then
    local v = value >> bit
    local k = (1 << bit) - 1
    value = value & k
    return v, value
  end
  Log.Error("\228\188\160\229\133\165\231\154\132\231\130\171\229\189\169id\228\184\141\228\184\186\230\149\180\230\149\176\239\188\140\230\149\176\230\141\174\231\177\187\229\158\139\230\156\137\232\175\175\239\188\129\239\188\129\239\188\129")
  return nil, nil
end

function PetUtils.CheckIsCHAOS(mutation_type)
  return PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS) or PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) or PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_THREE)
end

local ProbabilityConf, RangeList

function PetUtils.CheckIfPetCounterattack(Pet, Operator)
  if not ProbabilityConf or not RangeList then
    local LowRangeConf = _G.DataConfigManager:GetHomeGlobalConfig("home_steal_attack_low")
    local MiddleRangeConf = _G.DataConfigManager:GetHomeGlobalConfig("home_steal_attack_middle")
    local HighRangeConf = _G.DataConfigManager:GetHomeGlobalConfig("home_steal_attack_high")
    RangeList = {
      {
        LowRangeConf.numList[1],
        LowRangeConf.numList[2]
      },
      {
        MiddleRangeConf.numList[1],
        MiddleRangeConf.numList[2]
      },
      {
        HighRangeConf.numList[1],
        HighRangeConf.numList[2]
      }
    }
    ProbabilityConf = {
      LowRangeConf.num,
      MiddleRangeConf.num,
      HighRangeConf.num
    }
  end
  local OperatorID = Operator:GetServerId()
  local PetAttrComp = Pet:EnsureComponent(HomePetAttributeComponent)
  local OperatorFriendliness = PetAttrComp:GetFriendlinessCurrent(OperatorID)
  local Level
  for ConfLevel, ConfRange in ipairs(RangeList) do
    if OperatorFriendliness >= ConfRange[1] and OperatorFriendliness <= ConfRange[2] then
      Level = ConfLevel
      break
    end
  end
  if not Level then
    Log.Error("\231\174\151\228\184\141\229\135\186\230\157\165\229\165\189\230\132\159\229\186\166\229\164\132\229\156\168\229\147\170\228\184\170\231\173\137\231\186\167\239\188\159\230\163\128\230\159\165\228\184\128\228\184\139\230\149\176\230\141\174\231\156\139\231\156\139")
    return false
  end
  if _G.GlobalConfig.bShouldUseGMPetCounterPercentage then
    local percentage
    if _G.AppMain:HasDebug() then
      percentage = _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.GetGMPetCounterPercentage, PetAttrComp.owner.serverData.base.actor_id)
    end
    if percentage and math.random(0, 10000) <= percentage * 100 then
      return true
    end
  elseif math.random(0, 10000) <= ProbabilityConf[Level] then
    return true
  end
  return false
end

function PetUtils.GetFantasticSkillInPetSkillDataList(petSkillDataList)
  local fantasticId = -1
  for _, skill in ipairs(petSkillDataList) do
    if skill.skill_src == _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      fantasticId = skill.id
      break
    end
  end
  return fantasticId
end

function PetUtils.IsAnyPetInfoEquippedFantasticSkill(petInfoList, isMirror)
  local anySkillIsFantastic = false
  for i, petInfo in ipairs(petInfoList) do
    local equipSkillIdList = {}
    local petSkillEquipInfo = petInfo and petInfo.equip_infos or {}
    local equippedFantasticId = -1
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petInfo.pet_gid, isMirror)
    local petEquipSkills = PetUtils.GetPetEquipSkills(petData)
    local petDataSkill = petData and petData.skill
    local skillData = petDataSkill and petDataSkill.skill_data or {}
    local petDataBloodId = petData and petData.blood_id
    local fantasticId = -1
    if petDataBloodId == _G.Enum.PetBloodType.PBT_FANTASTIC or petDataBloodId == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      fantasticId = PetUtils.GetFantasticSkillInPetSkillDataList(skillData)
    end
    if next(petSkillEquipInfo) then
      for _, v in ipairs(petSkillEquipInfo) do
        table.insert(equipSkillIdList, v.id)
      end
    elseif next(petEquipSkills) then
      for _, v in ipairs(petEquipSkills) do
        table.insert(equipSkillIdList, v.id)
      end
    end
    for _, v in ipairs(equipSkillIdList) do
      if fantasticId == v then
        equippedFantasticId = fantasticId
        break
      end
    end
    if -1 ~= equippedFantasticId then
      anySkillIsFantastic = true
      break
    end
  end
  return anySkillIsFantastic
end

function PetUtils.CheckPetIsInherited(petGid)
  local petInheritanceActivityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_INHERITANCE)
  if petInheritanceActivityObjects then
    for _, activityInst in ipairs(petInheritanceActivityObjects) do
      if activityInst:IsPetInherited(petGid) then
        return true
      end
    end
  end
  return false
end

function PetUtils.GetPetTypeInfoType(petData)
  local typeInfo = petData and petData.type
  local type = typeInfo and typeInfo.type
  return type
end

function PetUtils.CheckNeedSwitchToPvpBalancePetData(petData)
  local balancedPetBaseInfo = petData and petData.balancedPetBaseInfo
  local isPvpBalance = nil ~= balancedPetBaseInfo
  local petGuid = petData and petData.gid
  local PetBaseInfo = petData and petData.PetBaseInfo
  local petTypeInfoType = PetUtils.GetPetTypeInfoType(PetBaseInfo)
  if not petGuid then
    return false
  end
  if isPvpBalance then
    return false
  end
  local isTrialPet, _ = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, petGuid)
  local isRandomPet = petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM
  if isTrialPet or isRandomPet then
    return false
  end
  return true
end

function PetUtils.CheckIsRandomPetBase(petBaseConfId)
  petBaseConfId = petBaseConfId or 0
  local startIdConf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_param7", true)
  local startId = startIdConf and startIdConf.num or 0
  local minEnumValue = Enum.SkillDamType.SDT_INVALID
  local maxEnumValue = Enum.SkillDamType.SDT_RELAX
  local minId = startId + minEnumValue
  local maxId = startId + maxEnumValue
  return petBaseConfId >= minId and petBaseConfId <= maxId
end

function PetUtils.GetRandomPetBaseConfIdFromSkillDamType(skillDamType)
  skillDamType = skillDamType or 0
  local startIdConf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_param7", true)
  local startId = startIdConf and startIdConf.num or 0
  local minEnumValue = Enum.SkillDamType.SDT_INVALID
  local maxEnumValue = Enum.SkillDamType.SDT_RELAX
  local minId = startId + minEnumValue
  local maxId = startId + maxEnumValue
  for id = minId, maxId do
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(id, true)
    local petBaseConfId = petBaseConf and petBaseConf.id or 0
    local unit_type = petBaseConf and petBaseConf.unit_type or {}
    local currentSkillDamType = unit_type[1]
    if currentSkillDamType and currentSkillDamType == skillDamType then
      return petBaseConfId
    end
  end
end

function PetUtils.GeneralMultipleConditionFilter(filterDic, itemList)
  local FreeButNotFilterList = {}
  local FreeAndFilterList = {}
  local NotFreeButFilterList = {}
  local RawFilteredList = {}
  if not (filterDic and itemList) or 0 == #itemList then
    return itemList or {}
  end
  for i = 1, #itemList do
    local item = itemList[i]
    local isAllConditionsMet = true
    for key, conditions in pairs(filterDic) do
      local isCurrentConditionMet = false
      if 0 == #conditions then
        isCurrentConditionMet = true
      elseif item.filterData and item.filterData[key] then
        local itemValue = item.filterData[key]
        if type(itemValue) == "table" then
          for j = 1, #itemValue do
            for _, conditionValue in ipairs(conditions) do
              if itemValue[j] == conditionValue then
                isCurrentConditionMet = true
                break
              end
            end
            if isCurrentConditionMet then
              break
            end
          end
        else
          for _, conditionValue in ipairs(conditions) do
            if itemValue == conditionValue then
              isCurrentConditionMet = true
              break
            end
          end
        end
      end
      if not isCurrentConditionMet then
        isAllConditionsMet = false
        break
      end
    end
    if isAllConditionsMet then
      table.insert(RawFilteredList, item)
    end
    if item.filterData.isInReleaseList and not isAllConditionsMet then
      table.insert(FreeButNotFilterList, item)
    elseif item.filterData.isInReleaseList and isAllConditionsMet then
      table.insert(FreeAndFilterList, item)
    elseif not item.filterData.isInReleaseList and isAllConditionsMet then
      table.insert(NotFreeButFilterList, item)
    end
  end
  return RawFilteredList, FreeButNotFilterList, FreeAndFilterList, NotFreeButFilterList
end

function PetUtils.SortFilterPetList(filterList)
  if not filterList then
    return
  end
  table.sort(filterList, function(a, b)
    local a_growLevel, a_order = PetUtils.GetResidueGrowCountAndGrowOrder(a)
    local b_growLevel, b_order = PetUtils.GetResidueGrowCountAndGrowOrder(b)
    if nil == a_order then
      a_order = 0
    end
    if nil == b_order then
      b_order = 0
    end
    if a_order == b_order then
      if a.talent_rank == b.talent_rank then
        if a.level == b.level then
          return a.base_conf_id < b.base_conf_id
        else
          return a.level > b.level
        end
      else
        return a.talent_rank > b.talent_rank
      end
    else
      return a_order > b_order
    end
  end)
end

function PetUtils.GeneralFilter(filter, itemList, variableName)
  local list = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].filterData[variableName] and itemList[i].filterData[variableName] == enum then
          table.insert(list, itemList[i])
        end
      end
    end
  else
    list = itemList
  end
  return list
end

function PetUtils.GeneralFilterArray(filter, itemList, variableName)
  local list = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].filterData[variableName] then
          local enums = itemList[i].filterData[variableName]
          for _, e in pairs(enums) do
            if e == enum then
              table.insert(list, itemList[i])
            end
          end
        end
      end
    end
  else
    list = itemList
  end
  return list
end

function PetUtils.isTimestampInToday(timestamp, startHour)
  local startHourOfDay = startHour or 0
  local currentTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local currentDate = os.date("*t", currentTime)
  local startOfToday = os.time({
    year = currentDate.year,
    month = currentDate.month,
    day = currentDate.day,
    hour = startHourOfDay,
    min = 0,
    sec = 0
  })
  local startOfTomorrow = startOfToday + 86400
  return timestamp >= startOfToday and timestamp < startOfTomorrow
end

function PetUtils.isTimestampInThisWeek(timestamp, weekStart)
  local firstDayOfWeek = weekStart or "Mon"
  local currentTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local currentDate = os.date("*t", currentTime)
  local currentWday = currentDate.wday
  local daysFromWeekStart
  if "Mon" == firstDayOfWeek then
    daysFromWeekStart = (currentWday - 2) % 7
    if daysFromWeekStart < 0 then
      daysFromWeekStart = 6
    end
  else
    daysFromWeekStart = currentWday - 1
  end
  local startOfThisWeek = os.time({
    year = currentDate.year,
    month = currentDate.month,
    day = currentDate.day,
    hour = 0,
    min = 0,
    sec = 0
  }) - daysFromWeekStart * 24 * 60 * 60
  local startOfNextWeek = startOfThisWeek + 604800
  return timestamp >= startOfThisWeek and timestamp < startOfNextWeek
end

function PetUtils.FilterTime(filter, itemList)
  local list = {}
  if nil ~= filter and #filter > 0 then
    local repeatDic = {}
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].filterData.time then
          if enum == _G.Enum.PetCatchTime.PCT_THISWEEK then
            if PetUtils.isTimestampInThisWeek(itemList[i].filterData.time) and not repeatDic[itemList[i].filterData.gid] then
              table.insert(list, itemList[i])
              repeatDic[itemList[i].filterData.gid] = true
            end
          elseif enum == _G.Enum.PetCatchTime.PCT_TODAY and PetUtils.isTimestampInToday(itemList[i].filterData.time) and not repeatDic[itemList[i].filterData.gid] then
            table.insert(list, itemList[i])
            repeatDic[itemList[i].filterData.gid] = true
          end
        end
      end
    end
  else
    list = itemList
  end
  return list
end

function PetUtils.IsFilteringCondition(AllCondition)
  local function Check(Condition)
    if Condition and #Condition > 0 then
      return true
    end
    return false
  end
  
  if Check(AllCondition.FilterPetIdCondition) then
    return true
  elseif Check(AllCondition.FilterTalentCondition) then
    return true
  elseif Check(AllCondition.FilterDepartCondition) then
    return true
  elseif Check(AllCondition.FilterNatureCondition) then
    return true
  elseif Check(AllCondition.FilterAttributeCondition) then
    return true
  elseif Check(AllCondition.FilterPetMarkCondition) then
    return true
  elseif Check(AllCondition.FilterStrongCondition) then
    return true
  elseif Check(AllCondition.FilterTimeCondition) then
    return true
  elseif Check(AllCondition.FilterTraceBackCondition) then
    return true
  end
  return false
end

function PetUtils.GetIncubationProgressItemList()
  local Ret = {}
  local PreciousItemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByLableType, _G.Enum.ItemLableType.ILT_PRECIOUS)
  for _, item in pairs(PreciousItemList) do
    if item and item.conf then
      for i = 1, #item.conf.item_behavior do
        if item.conf.item_behavior[i] and item.conf.item_behavior[i].use_action and item.conf.item_behavior[i].use_action == _G.Enum.ItemBehavior.IB_PET_HATCH_PROCESS_ADD and item.conf.item_behavior[i].ratio and item.conf.item_behavior[i].ratio[1] and item.conf.item_behavior[i].ratio[1] > 0 then
          table.insert(Ret, item)
          break
        end
      end
    end
  end
  return Ret
end

function PetUtils.CheckPetEggIsHatchSecsMax(gid)
  local bHatchSecsMax = false
  if nil == gid then
    Log.Debug("PetUtils.CheckPetEggIsHatchSecsMax gid is nil")
    return bHatchSecsMax
  end
  local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, gid)
  if nil == BagEggItem then
    Log.Debug("PetUtils.CheckPetEggIsHatchSecsMax BagEggItem is nil")
    return bHatchSecsMax
  end
  local hatchedSecs, hatchedMaxSecs
  if BagEggItem.egg_data then
    hatchedSecs = BagEggItem.egg_data.hatched_secs
    if BagEggItem.egg_data and 0 == BagEggItem.egg_data.conf_id then
      hatchedMaxSecs = BagEggItem.egg_data.max_hatched_secs
    elseif BagEggItem.egg_data and 0 ~= BagEggItem.egg_data.conf_id then
      local eggConf = _G.DataConfigManager:GetPetEggConf(BagEggItem.egg_data.conf_id)
      hatchedMaxSecs = eggConf.hatch_data
    end
    if hatchedSecs and hatchedMaxSecs and hatchedSecs >= hatchedMaxSecs then
      bHatchSecsMax = true
    end
  end
  return bHatchSecsMax
end

function PetUtils.GetDefaultPetImage3DResListData()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  ResListData.LoadingResList = {}
  table.insert(ResListData.PreLoadResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchPetShow_UI.G6_SwitchPetShow_UI_C'")
  table.insert(ResListData.PreLoadResList, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenTwoPanel.OpenTwoPanel'")
  table.insert(ResListData.PreLoadResList, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/CloseTwoPanel.CloseTwoPanel'")
  table.insert(ResListData.PreLoadResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenPetInfo_UI.G6_OpenPetInfo_UI_C'")
  table.insert(ResListData.PreLoadResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_ClosePetInfo_UI.G6_ClosePetInfo_UI_C'")
  table.insert(ResListData.PreLoadResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchEegShow_UI.G6_SwitchEegShow_UI_C")
  table.insert(ResListData.PreLoadResList, "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'")
  return ResListData
end

function PetUtils.DoCheckIsMimic(battle_inside_pet_info)
  if not battle_inside_pet_info then
    return false
  end
  local buffs = battle_inside_pet_info.buffs
  if buffs then
    for _, buff in ipairs(buffs) do
      local config = _G.DataConfigManager:GetBuffConf(buff.buff_id)
      if config then
        for _, sign in ipairs(config.buff_groupsigns) do
          if (sign == ProtoEnum.BuffGroupSign.BGS_MIMIC or sign == ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC) and buff.stack > 0 then
            return true, sign, buff
          end
        end
      end
    end
  end
  return false
end

function PetUtils.DoCheckIsSurpriseBox(battle_inside_pet_info)
  if not battle_inside_pet_info then
    return false
  end
  local buffs = battle_inside_pet_info.buffs
  if buffs then
    for _, buff in ipairs(buffs) do
      local config = _G.DataConfigManager:GetBuffConf(buff.buff_id)
      if config then
        for _, sign in ipairs(config.buff_groupsigns) do
          if sign == ProtoEnum.BuffGroupSign.BGS_FANTASTIC_BOX and buff.stack > 0 then
            return true, sign, buff
          end
        end
      end
    end
  end
  return false
end

function PetUtils.GetBuffInfoByGroupSign(battle_inside_pet_info, groupSign)
  local buffInfos = battle_inside_pet_info.buffs
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

function PetUtils.GetPetIconPath(info, petBaseConf)
  local IconPath = BattleConst.MimicHeadIcon
  local battle_inside_pet_info = info.battle_inside_pet_info
  local battle_common_pet_info = info.battle_common_pet_info
  petBaseConf = petBaseConf or _G.DataConfigManager:GetPetbaseConf(battle_inside_pet_info.base_conf_id, true)
  if not petBaseConf then
    return IconPath
  end
  local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  if not modelConf then
    return IconPath
  end
  IconPath = modelConf.icon or IconPath
  local MutationType = battle_common_pet_info and battle_common_pet_info.mutation_type or 0
  IconPath = (PetMutationUtils.GetMutationValue(MutationType, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(MutationType)) and modelConf.shiny_icon or IconPath
  local isMimic, MimicType = PetUtils.DoCheckIsMimic(battle_inside_pet_info)
  if isMimic and MimicType == ProtoEnum.BuffGroupSign.BGS_MIMIC then
    return BattleConst.MimicHeadIcon
  end
  return IconPath
end

function PetUtils.GetPetModelPath(info, petBaseConf)
  local ModelPath = ""
  local battle_inside_pet_info = info.battle_inside_pet_info
  petBaseConf = petBaseConf or _G.DataConfigManager:GetPetbaseConf(battle_inside_pet_info.base_conf_id, true)
  if not petBaseConf then
    return ModelPath
  end
  local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  if not modelConf then
    return ModelPath
  end
  if BattleUtils.IsBeastTeam() and modelConf.hd_path then
    ModelPath = modelConf.hd_path
  else
    ModelPath = modelConf.path
  end
  return ModelPath
end

function PetUtils.GetPetResourceScale(info, petBaseConf, isEnemy)
  local Scale = 1.0
  local InitScale = 1.0
  local battle_inside_pet_info = info.battle_inside_pet_info
  local battle_common_pet_info = info.battle_common_pet_info
  petBaseConf = petBaseConf or _G.DataConfigManager:GetPetbaseConf(battle_inside_pet_info.base_conf_id, true)
  if not petBaseConf then
    return Scale, InitScale
  end
  local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  if not modelConf then
    return Scale, InitScale
  end
  if modelConf.model_scale ~= nil and 0 ~= modelConf.model_scale then
    Scale = modelConf.model_scale / 100.0
    InitScale = Scale
  end
  local isMimic = PetUtils.DoCheckIsMimic(battle_inside_pet_info)
  if isMimic then
    return 1.0, 1.0
  end
  Scale = Scale * PetMutationUtils.GetHeightModelScaleByPetData(battle_common_pet_info)
  InitScale = Scale
  if nil == isEnemy then
    isEnemy = PetUtils.IsEnemy(info)
  end
  if not isEnemy then
    return Scale, InitScale
  end
  if BattleUtils.IsBloodTeam() then
    Scale = BattleUtils.GetBloodTeamPetScale(battle_common_pet_info.height)
  else
    local isBeastCatch = false
    if BattleUtils.IsBeastTeam() then
      if not BattleUtils.IsPlayerSelectCatchInBeast() then
        Scale = Scale * BattleUtils.GetBeastTeamPetScale()
      else
        isBeastCatch = true
      end
    end
    local isMonster = false
    local config = _G.DataConfigManager:GetPetConf(battle_inside_pet_info.conf_id, true)
    if not config then
      config = _G.DataConfigManager:GetMonsterConf(battle_inside_pet_info.conf_id)
      isMonster = true
    end
    if not BattleUtils.IsPvp() and config and isMonster and not isBeastCatch then
      local monsterScale = config.model_scale or 100
      if monsterScale > 0 then
        Scale = Scale * (monsterScale / 100)
      end
    end
  end
  return Scale, InitScale
end

function PetUtils.GetPetShowName(info, petBaseConf)
  local battle_inside_pet_info = info.battle_inside_pet_info
  petBaseConf = petBaseConf or _G.DataConfigManager:GetPetbaseConf(battle_inside_pet_info.base_conf_id, true)
  local name = battle_inside_pet_info.name
  local isMimic, MimicType, buffInfo = PetUtils.DoCheckIsMimic(battle_inside_pet_info)
  if isMimic then
    if MimicType == ProtoEnum.BuffGroupSign.BGS_MIMIC then
      name = "???"
    elseif MimicType == ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC then
      buffInfo = buffInfo or PetUtils:GetBuffInfoByGroupSign(battle_inside_pet_info, MimicType)
      if buffInfo and buffInfo.buff_data then
        local mimicPetId = buffInfo.buff_data[1]
        local petConf = _G.DataConfigManager:GetPetConf(mimicPetId or 0, true)
        if petConf then
          name = petConf.name
        end
      end
    end
  end
  if string.IsNilOrEmpty(name) and petBaseConf then
    name = petBaseConf.name
  end
  return name
end

function PetUtils.GetHelpPetEquipSkills(LevelSkillConf, bloodId, lv, curBattleBaseId)
  local petEquipSkills = {}
  local skillList = LevelSkillConf.level
  if bloodId and bloodId > 0 and lv >= LevelSkillConf.blood_skill_level_point then
    skillList = {}
    local hasRecordBloodSkill = false
    for _, v in ipairs(LevelSkillConf.level) do
      if not hasRecordBloodSkill and v.level_point >= LevelSkillConf.blood_skill_level_point then
        hasRecordBloodSkill = true
        local bloodSkill = PetUtils.GetSkillBloodData(bloodId, LevelSkillConf)
        table.insert(skillList, {
          level_point = LevelSkillConf.blood_skill_level_point,
          param = bloodSkill.id
        })
      end
      if lv >= v.level_point then
        table.insert(skillList, v)
      end
    end
    if not hasRecordBloodSkill then
      hasRecordBloodSkill = true
      local bloodSkill = PetUtils.GetSkillBloodData(bloodId, LevelSkillConf)
      table.insert(skillList, {
        level_point = LevelSkillConf.blood_skill_level_point,
        param = bloodSkill.id
      })
    end
  end
  if skillList and #skillList > 0 then
    local usedSkillIds = {}
    for skillIndex = 1, 4 do
      local default_skill = skillList[skillIndex]
      local can_equip_default_skill = default_skill and default_skill.level_point and lv >= default_skill.level_point and default_skill.param
      if can_equip_default_skill then
        for _, usedId in ipairs(usedSkillIds) do
          if default_skill.param == usedId then
            can_equip_default_skill = false
            break
          end
        end
      end
      local active_skill = can_equip_default_skill and {
        id = default_skill.param,
        level_point = default_skill.level_point
      } or {id = 0, level_point = 0}
      for _, v in ipairs(skillList) do
        if v.level_point >= active_skill.level_point and lv >= v.level_point then
          local isUsed = false
          for _, usedId in ipairs(usedSkillIds) do
            if v.param == usedId then
              isUsed = true
              break
            end
          end
          if not isUsed then
            active_skill.id = v.param
            active_skill.level_point = v.level_point
          end
        end
      end
      table.insert(petEquipSkills, {
        id = active_skill.id,
        curBattleBaseId = curBattleBaseId
      })
      if active_skill.id > 0 then
        table.insert(usedSkillIds, active_skill.id)
      end
    end
  end
  return petEquipSkills
end

function PetUtils.GetHandBookIdByPetBaseConfId(petBaseConfId)
  local dataTable = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK)
  local handbookConfs = dataTable and dataTable:GetAllDatas() or {}
  local targetHandBookConfId
  for _, handbookConf in ipairs(handbookConfs) do
    local handBookConfId = handbookConf and handbookConf.id
    local includePetBaseIdList = handbookConf and handbookConf.include_petbase_id or {}
    for i, includePetBaseIdItem in ipairs(includePetBaseIdList) do
      local petBaseIdList = includePetBaseIdItem and includePetBaseIdItem.petbase_id or {}
      if table.contains(petBaseIdList, petBaseConfId) then
        targetHandBookConfId = handBookConfId
        goto lbl_57
      end
    end
  end
  ::lbl_57::
  return targetHandBookConfId
end

function PetUtils.TryGetPetSkillSeasonId(petGid, skillId)
  local dataModelManager = _G.DataModelMgr
  local playerDataModel = dataModelManager and dataModelManager.PlayerDataModel
  local petData = playerDataModel and playerDataModel:GetPetDataByGid(petGid)
  local skillInfo = petData and petData.skill
  local skillDataList = skillInfo and skillInfo.skill_data or {}
  local seasonId
  for i, skillData in ipairs(skillDataList) do
    local skillDataId = skillData and skillData.id
    if skillDataId and skillDataId == skillId then
      seasonId = skillData and skillData.season_id
      break
    end
  end
  return seasonId
end

return PetUtils
