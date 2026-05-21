local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
require("NewRoco.Modules.Core.Battle.Entity.BattleInfo.Basic.TableTools")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger_Declare")
BattleDebugger.enableFieldUsageLog = 0
BattleDebugger.enableFieldUsageLogDebug = 0
BattleDebugger.enableVisualizeEnterBattleCamera = 0

function BattleDebugger:GetBattlePet(pet_id)
  return nil
end

function BattleDebugger:DoPlayAnimByName(animName, team, pos, LoopCount, endPosition)
  local BattleManager = _G.BattleManager
  local pet = BattleManager.battlePawnManager:GetPetByPos(team, pos)
  if pet then
    local animName = animName
    local rate = 1
    local position = 0
    local BlendInTime = 0
    local BlendOutTime = 0
    local LoopCount = LoopCount
    local endPosition = endPosition
    pet.model:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  end
end

function BattleDebugger:DoEnableScrollCamera(bEnable, x, y, z)
  if bEnable then
    local myPet = BattleManager.battlePawnManager:GetPetByPos(BattleEnum.Team.ENUM_TEAM, 1)
    local enemyPet = BattleManager.battlePawnManager:GetPetByPos(BattleEnum.Team.ENUM_ENEMY, 1)
    if myPet then
      local offset = UE4.FVector(x, y, z)
      local myPetTransform = myPet.model:Abs_GetTransform()
      local forwardVector = myPetTransform.Rotation:GetForwardVector()
      local rightVector = myPetTransform.Rotation:GetRightVector()
      local upVector = myPetTransform.Rotation:GetUpVector()
      local targetPosition = myPetTransform.Translation + myPetTransform.Rotation:RotateVector(offset)
      local targetRotation = (-rightVector):ToRotator()
      local targetTransform = UE4.FTransform(targetRotation:ToQuat(), targetPosition, UE4.FVector(1, 1, 1))
      UE4.UNRCStatics.EnableScrollCamera(myPet.model, targetTransform)
    end
  end
end

function BattleDebugger:DoTeleportTo(x, y, z)
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, string.format("NRCTransport %s, %s, %s", tostring(x), tostring(y), tostring(z)))
end

local function __index_HookGetter(t, k)
  local v = rawget(t.___hookRawCopy, k)
  local hooked = t.___fieldsToHook[k]
  if hooked then
    for i = 1, #t.___hookGetter do
      local hookHandler = t.___hookGetter[i]
      local parents = t.___hookParents
      hookHandler(t, k, v, parents)
    end
  end
  return v
end

local function __newindex_HookGetter(t, k, v)
  rawset(t.___hookRawCopy, k, v)
end

function BattleDebugger.HookGetter(tRoot, tParents, tFinalMember, final_keys)
  local t = tFinalMember
  if not t then
    return
  end
  local t_raw = {}
  for k, v in pairs(t) do
    t_raw[k] = v
  end
  table.clear(t)
  t.___hookRawCopy = t_raw
  t.___hookParents = tParents
  t.___fieldsToHook = {}
  for i = 1, #final_keys do
    local k = final_keys[i]
    t.___fieldsToHook[k] = true
  end
  t.___hookGetter = {
    BattleDebugger.HookGetter_BattleInsidePetInfo__battle_attr
  }
  local mt = {}
  mt.__index = __index_HookGetter
  mt.__newindex = __newindex_HookGetter
  setmetatable(t, mt)
end

local EPetRole = {
  "PetRole_Unknown",
  "PetRole_MyselfTeam",
  "PetRole_Teammate",
  "PetRole_EnemyTeam",
  "PetRole_ObserverNPC",
  "PetRole_SpectatorPlayer"
}
table.makeEnumTable(EPetRole)

function BattleDebugger.HookGetter_BattleInsidePetInfo__battle_attr(t, k, v, parents)
  local battle_attr = t
  local attr_type = k
  local battle_inside_pet_info = parents[#parents]
  local bInBattle = BattleUtils.GetInBattle(battle_inside_pet_info) or BattleManager.battlePawnManager:GetPetByGuid(battle_inside_pet_info.pet_id)
  local petRole = EPetRole.PetRole_Unknown
  if _G.BattleManager.battlePawnManager:IsValid(true) then
    local card = _G.BattleManager.battlePawnManager:GetCardByGuid(battle_inside_pet_info.pet_id)
    if card then
      if card:IsMyself() then
        petRole = EPetRole.PetRole_MyselfTeam
      elseif card:IsTeammate() then
        petRole = EPetRole.PetRole_Teammate
      elseif card:IsEnemy() then
        petRole = EPetRole.PetRole_EnemyTeam
      elseif card:IsObserver() then
        petRole = EPetRole.PetRole_ObserverTeam
      elseif card:IsSpectator() then
        petRole = EPetRole.PetRole_SpectatorPlayer
      end
    end
  end
  if petRole == EPetRole.PetRole_Unknown then
    local init_info = parents[2]
    local player_team = init_info.player_team
    local enemy_team = init_info.enemy_team
    local pet_team = parents[4]
    if pet_team.base then
      local roleInfo = pet_team
      local pet_role_uin = roleInfo.base.role_uin
      local my_uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
      if my_uin == pet_role_uin then
        petRole = EPetRole.PetRole_MyselfTeam
      elseif table.contains(enemy_team, roleInfo) then
        petRole = EPetRole.PetRole_EnemyTeam
      else
        petRole = EPetRole.PetRole_Teammate
      end
    else
      local otherRoleInfo = pet_team
      if petRole == EPetRole.PetRole_Unknown then
        for i = 1, #player_team do
          local roleInfo = player_team[i]
          if otherRoleInfo.role_uin == roleInfo.base.role_uin then
            petRole = EPetRole.PetRole_Teammate
            break
          end
        end
      end
      if petRole == EPetRole.PetRole_Unknown then
        for i = 1, #enemy_team do
          local roleInfo = enemy_team[i]
          if otherRoleInfo.role_uin == roleInfo.base.role_uin then
            petRole = EPetRole.PetRole_EnemyTeam
            break
          end
        end
      end
    end
  end
  Log.Debug(string.format("LogBattleTemp: BattleInsidePetInfo.battle_attr[%d] \232\162\171\232\174\191\233\151\174, v=%f, pet_id=%d, pos=%d, inBattle=%d, role=%s", k, v, battle_inside_pet_info.pet_id, battle_inside_pet_info.pos, bInBattle and 1 or 0, EPetRole:tostring(petRole)))
end

function BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(msg)
  if 1 == self.enableFieldUsageLog then
    self:DoHookGetter_ZoneBattleMessage__battle_attr(msg)
  end
end

function BattleDebugger:DoHookGetter_ZoneBattleMessage__battle_attr(msg)
  local find_final_field
  
  function find_final_field(t, ps, tc, keys, start_index, final_keys, action)
    local m = tc
    local ps = ps
    for i = start_index, #keys do
      local k = keys[i]
      local is_array = false
      if type(k) == "table" then
        k = k[1]
        is_array = true
      end
      local sub = m[k]
      if nil == sub then
        return
      else
        table.insert(ps, m)
        if is_array then
          table.insert(ps, sub)
          for j = 1, #sub do
            local sub_t = sub[j]
            local sub_ps = {}
            table.copy(ps, sub_ps)
            find_final_field(t, sub_ps, sub_t, keys, i + 1, final_keys, action)
          end
          return
        else
          m = sub
        end
      end
    end
    action(t, ps, m, final_keys)
  end
  
  local function action(tRoot, tParents, tFinalMember, final_keys)
    BattleDebugger.HookGetter(tRoot, tParents, tFinalMember, final_keys)
  end
  
  local function find_final_field_for_battle_attr_Values(keys)
    local final_keys = {
      ProtoEnum.AttributeType.AT_HPMAX_PERCENT,
      ProtoEnum.AttributeType.AT_PHYATK_PERCENT,
      ProtoEnum.AttributeType.AT_SPEATK_PERCENT,
      ProtoEnum.AttributeType.AT_PHYDEF_PERCENT,
      ProtoEnum.AttributeType.AT_SPEDEF_PERCENT,
      ProtoEnum.AttributeType.AT_SPEED_PERCENT,
      ProtoEnum.AttributeType.AT_PHYATK_BASE,
      ProtoEnum.AttributeType.AT_SPEATK_BASE,
      ProtoEnum.AttributeType.AT_PHYDEF_BASE,
      ProtoEnum.AttributeType.AT_SPEDEF_BASE,
      ProtoEnum.AttributeType.AT_SPEED_BASE,
      ProtoEnum.AttributeType.AT_SPEADD
    }
    if 1 == self.enableFieldUsageLogDebug then
      for i = 0, 100 do
        final_keys[i] = i
      end
    end
    for k, v in pairs(final_keys) do
      final_keys[k] = v + 1
    end
    find_final_field(msg, {}, msg, keys, 1, final_keys, action)
  end
  
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "supply_pet",
    "pet_infos",
    "pet_infos",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "data_update",
    "battler",
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "data_update",
    "other",
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "revive_info",
    "pet",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "change_pet",
    "battle_pet_info",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "change_model",
    "pet_info",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "perform_cmd",
    {
      "perform_info"
    },
    "pet_evolution",
    "pet_info",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "state_info",
    {
      "player_team"
    },
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "state_info",
    {"enemy_team"},
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "init_info",
    {
      "player_team"
    },
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "init_info",
    {"enemy_team"},
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "init_info",
    {"others"},
    {"pets"},
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
  local keys = {
    "sync_data",
    "pet_info",
    "battle_inside_pet_info",
    "battle_attr"
  }
  find_final_field_for_battle_attr_Values(keys)
end

function BattleDebugger:DoSetting(k, v)
  self[k] = v
  Log.Debug("LogBattleTemp: BattleDebugger:DoSetting", k, tostring(v))
end

return BattleDebugger
