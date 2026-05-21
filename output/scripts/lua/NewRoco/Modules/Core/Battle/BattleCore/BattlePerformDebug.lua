local BattlePerformDebug = NRCClass:Extend("BattlePerformDebug")

function BattlePerformDebug:Ctor()
  if RocoEnv.IS_EDITOR then
    BattlePerformDebug.isLogEnabled = false
    Log.Debug("BattlePerformDebug is enable")
  else
    BattlePerformDebug.isLogEnabled = false
    Log.Debug("BattlePerformDebug is disable")
  end
end

function BattlePerformDebug.ZGXDebugPerformDetail(performNode, performInfo)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("         zgx  performInfo type : ", performNode.performTypeToWord[performInfo.type] or "performtype: " .. tostring(performInfo.type), performNode.castmomentToWord[performInfo.cast_moment] or "cast_moment: " .. tostring(performInfo.cast_moment), "group id: " .. performInfo.group_id, " Node Id " .. performNode.performNodeIdx, "isHead " .. tostring(performInfo.is_group_head), "group_ref: " .. tostring(performInfo.group_ref), "ExecIdx " .. performInfo.exec_index)
  if performInfo.type == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    local skillData = SkillUtils.GetSkillConf(performInfo.skill_cast.skill_id, true)
    local pet = BattleManager.battlePawnManager:GetPetByGuid(performInfo.skill_cast.caster_id)
    if skillData then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will use skill ", pet and pet.card.name or "nil", skillData.id, skillData.name, skillData.res_id)
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will use skill \230\137\190\228\184\141\229\136\176\239\188\129\239\188\129\239\188\129 ", pet and pet.card.name or "nil", performInfo.skill_cast.skill_id)
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    local skillData = SkillUtils.GetSkillConf(performInfo.combo_skill_cast.skill_id, true)
    local pet = BattleManager.battlePawnManager:GetPetByGuid(performInfo.combo_skill_cast.caster_id)
    if skillData then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will use skill ", pet and pet.card.name or "nil", skillData.id, skillData.name, skillData.res_id)
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will use skill \230\137\190\228\184\141\229\136\176\239\188\129\239\188\129\239\188\129 ", pet and pet.card.name or "nil", performInfo.combo_skill_cast.skill_id)
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    local buffData = _G.DataConfigManager:GetBuffConf(performInfo.buff_trigger.buff_id, true)
    local pet = BattleManager.battlePawnManager:GetPetByGuid(performInfo.buff_trigger.caster_id)
    if buffData then
      local perform_type = performInfo.buff_trigger.perform_type
      local BuffRes = buffData["res_id_" .. perform_type] or "\230\151\160\232\161\168\230\188\148"
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will trigger buff ", pet and pet.card.name or "nil", buffData.id, buffData.editor_name or "", BuffRes)
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will trigger buff \230\137\190\228\184\141\229\136\176\239\188\129\239\188\129\239\188\129")
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
    local buffChange = performInfo.buff_change
    local pet = BattleManager.battlePawnManager:GetPetByGuid(buffChange.target_id)
    local target = tostring(buffChange.target_id)
    local buffData = _G.DataConfigManager:GetBuffConf(performInfo.buff_change.buff_id, true)
    if pet then
      target = pet.card.name
    end
    local op = "nil"
    if buffChange.type == ProtoEnum.BuffChangeType.BCT_ADD then
      op = "\230\150\176\229\162\158 buff , id\228\184\186 " .. buffChange.buff_id .. "(" .. (buffData.editor_name or "") .. ")" .. "  \229\177\130\230\149\176\228\184\186 " .. buffChange.buff_info.stack
    elseif buffChange.type == ProtoEnum.BuffChangeType.BCT_CHANGE then
      op = "\229\143\152\230\155\180 buff , id\228\184\186 " .. buffChange.buff_id .. "(" .. (buffData.editor_name or "") .. ")" .. "  \229\177\130\230\149\176\228\184\186 " .. buffChange.buff_info.stack
    elseif buffChange.type == ProtoEnum.BuffChangeType.BCT_REMOVE then
      op = "\229\136\160\233\153\164 buff , id\228\184\186 " .. buffChange.buff_id .. "(" .. (buffData.editor_name or "") .. ")"
    end
    BattlePerformDebug.Log("                                                                                                                  ---> zgx buff change ", target, op)
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
    local effectData = _G.DataConfigManager:GetEffectConf(performInfo.effect_trigger.effect_id, true)
    local pet = BattleManager.battlePawnManager:GetPetByGuid(performInfo.effect_trigger.caster_id)
    if effectData then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will trigger effect ", pet and pet.card.name or "nil", effectData.id, effectData.editor_name or "")
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx will trigger effect \230\137\190\228\184\141\229\136\176\239\188\129\239\188\129\239\188\129")
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH then
    local cheersData = performInfo.cheers_switch
    local cheerPet = BattleManager.battlePawnManager:GetPetByGuid(cheersData.pet_id)
    local op = ""
    if cheerPet then
      op = cheerPet.card.name .. "\228\184\138\229\156\186  \230\150\176\231\154\132posInField\228\184\186 " .. cheersData.to_pos .. "   "
    end
    local battlePet = BattleManager.battlePawnManager:GetPetByGuid(cheersData.old_pet_id)
    if battlePet then
      op = op .. battlePet.card.name .. "\228\184\139\229\156\186"
    end
    BattlePerformDebug.Log("                                                                                                                  ---> zgx cheers switch ", op)
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_PET_ESCAPE then
    local petEscape = performInfo.pet_escape
    local pet = BattleManager.battlePawnManager:GetPetByGuid(petEscape.pet_id)
    local op = ""
    if pet then
      op = pet.card.name .. "\233\128\131\232\183\145 cheerflag \228\184\186 " .. pet.card.petInfo.battle_inside_pet_info.cheers_tag
    end
    BattlePerformDebug.Log("                                                                                                                  ---> zgx escape ", op)
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DEATH then
    local petDead = performInfo.dead_info
    local pet = BattleManager.battlePawnManager:GetPetByGuid(petDead.target_id)
    local op = ""
    if pet then
      op = pet.card.name .. " \230\173\187\228\186\161"
    end
    BattlePerformDebug.Log("                                                                                                                  ---> zgx death ", op)
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_REVIVE then
    local petRevive = performInfo.revive_info
    local pet = BattleManager.battlePawnManager:GetCardByGuid(petRevive.caster_id)
    local op = ""
    if pet then
      op = pet.name .. " \229\164\141\230\180\187"
    end
    BattlePerformDebug.Log("                                                                                                                  ---> zgx revive ", op)
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DAMAGE then
    local pet = BattleManager.battlePawnManager:GetCardByGuid(performInfo.damage_info.target_id)
    local hp_change = -1
    local hp_result = -1
    local shield_result = -1
    local shield_change = -1
    local damage_result = -1
    local damage_change = -1
    for _, petSyncInfo in ipairs(performInfo.sync_data.pet_sync_info) do
      if petSyncInfo.pet_id == performInfo.damage_info.target_id then
        hp_change = petSyncInfo.hp_change or -1
        hp_result = petSyncInfo.hp_result or -1
        shield_result = petSyncInfo.shield_result or -1
        shield_change = petSyncInfo.shiled_change or -1
        damage_result = petSyncInfo.damage_result or -1
        damage_change = petSyncInfo.damage_change or -1
        if petSyncInfo.attr_change and (petSyncInfo.attr_type == _G.ProtoEnum.AttributeType.AT_NIGHTMARE_SHIELD or petSyncInfo.attr_type == _G.ProtoEnum.AttributeType.AI_BOX_SHIELD) then
          shield_change = petSyncInfo.attr_change
          shield_result = petSyncInfo.attr_result
        end
      end
    end
    if pet then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx damage ", pet.name or "nil", damage_result, hp_result, shield_result, shield_change, damage_result, damage_change)
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx damge \230\137\190\228\184\141\229\136\176\231\155\174\230\160\135\239\188\129\239\188\129\239\188\129 ")
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_HEAL then
    local pet = BattleManager.battlePawnManager:GetCardByGuid(performInfo.heal_info.target_id)
    local hp_result = -1
    for _, petSyncInfo in ipairs(performInfo.sync_data.pet_sync_info) do
      if petSyncInfo.pet_id == performInfo.heal_info.target_id then
        hp_result = petSyncInfo.hp_result or -1
      end
    end
    if pet then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Heal ", pet.name or "nil", hp_result)
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Heal \230\137\190\228\184\141\229\136\176\231\155\174\230\160\135\239\188\129\239\188\129\239\188\129 ")
    end
  elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
    local restPet = BattleManager.battlePawnManager:GetCardByGuid(performInfo.change_pet.rest_pet_id)
    local battlePet = BattleManager.battlePawnManager:GetCardByGuid(performInfo.change_pet.battle_pet_id)
    if restPet and battlePet then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Change pet  \228\184\139\229\156\186 " .. (restPet.name or "nil") .. "  \228\184\138\229\156\186 " .. (battlePet.name or "nil"))
    elseif restPet then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Change pet \230\137\190\228\184\141\229\136\176\228\184\138\229\156\186\231\155\174\230\160\135\239\188\129\239\188\129\239\188\129 \228\184\139\229\156\186\229\174\160\231\137\169 ", restPet.name or "nil")
    elseif battlePet then
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Change pet \230\137\190\228\184\141\229\136\176\228\184\139\229\156\186\231\155\174\230\160\135\239\188\129\239\188\129\239\188\129 \228\184\138\229\156\186\229\174\160\231\137\169 ", battlePet.name or "nil")
    else
      BattlePerformDebug.Log("                                                                                                                  ---> zgx Change pet \230\137\190\228\184\141\229\136\176\231\155\174\230\160\135\239\188\129\239\188\129\239\188\129 ")
    end
  end
end

function BattlePerformDebug.DebugClusterStart(cluster)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.LogWarning("zgx Cluster start has group " .. cluster.NeedPerformGroupCount)
end

function BattlePerformDebug.DebugClusterStop(cluster)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.LogWarning("zgx Cluster end")
end

function BattlePerformDebug.DebugGroupStart(group)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("     zgx Group start  group id " .. group.GroupId .. " has nodes " .. group.NeedPerformNodeCount)
end

function BattlePerformDebug.DebugGroupStop(group)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("     zgx Group end group id " .. group.GroupId)
end

function BattlePerformDebug.DebugNodeDoPerform(performNode)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL or performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    BattlePerformDebug.LogWarning("               zgx  PerformingNode  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  else
    BattlePerformDebug.Log("             zgx  PerformingNode  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  end
end

function BattlePerformDebug.DebugNodeCompletePerform(performNode)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL or performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    BattlePerformDebug.LogWarning("               zgx  CompleteNode  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  else
    BattlePerformDebug.Log("             zgx  CompleteNode  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  end
end

function BattlePerformDebug.DebugNodeLogicPerform(performNode)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL or performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    BattlePerformDebug.LogWarning("                 zgx  DoLogic  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  else
    BattlePerformDebug.Log("                zgx  DoLogic  " .. BattlePerformDebug:CombineNodeInfo(performNode))
  end
end

function BattlePerformDebug.DebugRoundEnd()
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("zgx RoundEnd")
end

function BattlePerformDebug.ReceviceNotify(notifyCmdId, notify)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("zgx ReceviceNotify:", ProtoCMD:GetMessageName(notifyCmdId))
end

function BattlePerformDebug.HandleNotify(notify)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  BattlePerformDebug.Log("zgx HandleNotify:", ProtoCMD:GetMessageName(notify.notifyCmdId))
  NRCModuleManager:DoCmd(BattleUIModuleCmd.SavePreProcessCmd, "zgx HandleNotify:" .. ProtoCMD:GetMessageName(notify.notifyCmdId))
end

function BattlePerformDebug:CombineNodeInfo(performNode)
  if not BattlePerformDebug.isLogEnabled then
    return
  end
  return "PerformType:" .. performNode:GetPerformTypeTostring() .. "  CastMoment:" .. performNode:GetCastMomentToString() .. "  GroupId:" .. performNode.groupID .. "  IsHead:" .. tostring(performNode:IsGroupHead()) .. "  ExecIdx:" .. performNode:GetExecIdx() .. "   PerformID:" .. performNode:GetPerformID() .. "    NodeIdx:" .. performNode:GetNodeIdx() .. "  IsFastPlay:" .. tostring(performNode.IsFastPlay or "false")
end

function BattlePerformDebug.EnableLog(value)
  BattlePerformDebug.isLogEnabled = value
end

function BattlePerformDebug.Log(...)
  if BattlePerformDebug.isLogEnabled then
    Log.Debug(...)
  end
end

function BattlePerformDebug.LogWarning(...)
  if BattlePerformDebug.isLogEnabled then
    Log.Warning(...)
  end
end

return BattlePerformDebug
