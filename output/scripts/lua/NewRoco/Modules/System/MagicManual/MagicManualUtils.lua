local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ROLE_STAR_NPCLEVEL_CHANGE_CONF = _G.DataConfigManager:GetAllByName("ROLE_STAR_NPCLEVEL_CHANGE_CONF")
local WORLD_LEVEL_CONF = _G.DataConfigManager:GetAllByName("WORLD_LEVEL_CONF")
local MagicManualUtils = {}
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
MagicManualUtils.BossLevel = {
  _cache = {}
}

function MagicManualUtils.InitFlowerCueBubble(CueBubble, Owner, OnGetFlowerData)
  CueBubble:SetVisibility(UE.ESlateVisibility.Collapsed)
  local DetailsBtn = CueBubble.Btn_particulars
  local DetailsBtn1 = CueBubble.Btn_particulars1
  DetailsBtn.RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
  if Owner then
    DetailsBtn:SetVisibility(UE.ESlateVisibility.Visible)
    
    local function OnClicked()
      local FlowerData = OnGetFlowerData and OnGetFlowerData(Owner)
      if FlowerData then
        local ActivityObject = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstById, FlowerData.activity_id)
        if ActivityObject then
          local Type = ActivityObject:GetActivityType()
          if Type == Enum.ActivityType.ATP_SHINY_WEEKEND_START or Type == Enum.ActivityType.ATP_SHINY_WEEKEND_PREVIEW then
            ActivityObject:OnBtnShowActivityDesc()
          elseif Type == Enum.ActivityType.ATP_FLOWER_APPEAR_HARD then
            ActivityUtils.ShowPetNatureTips(ActivityUtils.GetPetNatureIdBySeedId(FlowerData.spec_flower_seed_id), FlowerData.battle_petbase_id)
          end
        end
      end
    end
    
    Owner:AddButtonListener(DetailsBtn.btnLevelUp, OnClicked)
    Owner:AddButtonListener(DetailsBtn1, OnClicked)
  else
    DetailsBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    DetailsBtn1:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  return CueBubble.Desc
end

function MagicManualUtils.GetFlowerLevel(star, flowerSeedId)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local level = 0
  local pet_top_level = 0
  if flowerSeedId and 0 ~= flowerSeedId then
    local seedConf = _G.DataConfigManager:GetActivitySpecFlowerSeedConf(flowerSeedId)
    level = seedConf and seedConf.activity_team_battle_star_level[star] or 0
  else
    local key = string.format("team_battle_star_level_glass_%d", star)
    local petGlobalConfig = _G.DataConfigManager:GetPetGlobalConfig(key)
    level = petGlobalConfig and petGlobalConfig.numList and petGlobalConfig.numList[2] or 0
  end
  for index, item in ipairs(WORLD_LEVEL_CONF) do
    if item.world_level == worldLevel then
      pet_top_level = item.pet_top_level
      break
    end
  end
  return level, level <= pet_top_level
end

function MagicManualUtils.GetBossLevel(npc_refresh_id)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  local playerWorldLv = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  if visitorList and #visitorList > 0 then
    playerWorldLv = visitorList[1].world_lv
  end
  if MagicManualUtils.BossLevel._cache[npc_refresh_id] then
    local cachedData = MagicManualUtils.BossLevel._cache[npc_refresh_id]
    if cachedData.playerWorldLv == playerWorldLv then
      return cachedData.level, cachedData.level <= cachedData.pet_top_level
    end
  end
  local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(npc_refresh_id)
  local level = 0
  local pet_top_level = 0
  if refreshConf and refreshConf.npc_level_script == Enum.NpcLevelScript.NLS_ROLE_STAR_CONFIG and refreshConf.level_param then
    for i, v in pairs(ROLE_STAR_NPCLEVEL_CHANGE_CONF) do
      local conf = v
      if conf.index_param then
        local match = true
        for j = 1, 3 do
          if conf.index_param[j] and conf.index_param[j].param and refreshConf.level_param[j] and conf.index_param[j].param == refreshConf.level_param[j] and conf.world_level == playerWorldLv then
          else
            match = false
          end
        end
        if match then
          local para = refreshConf.level_param[4] or 0
          level = conf.level + para
          for index, item in ipairs(WORLD_LEVEL_CONF) do
            if item.world_level == worldLevel then
              pet_top_level = item.pet_top_level
              break
            end
          end
          break
        end
      end
    end
  end
  MagicManualUtils.BossLevel._cache[npc_refresh_id] = {
    level = level,
    pet_top_level = pet_top_level,
    playerWorldLv = playerWorldLv
  }
  return level, level <= pet_top_level
end

function MagicManualUtils.TaskTraceByGoGuide(go_guide, notOpenTaskPanel)
  if go_guide and go_guide.type and go_guide.type == Enum.TaskGoActionType.TGAT_UI and go_guide.text then
    local args1, args2
    if go_guide.args then
      args1 = UIUtils.GetSplit(go_guide.args, ";")
      if args1 and #args1 > 1 then
      else
        args1 = tonumber(go_guide.args)
        if nil == args1 then
          args1 = go_guide.args
        end
      end
    end
    if go_guide.args2 then
      args2 = UIUtils.GetSplit(go_guide.args2, ";")
      if args2 and #args2 > 1 then
      else
        args2 = tonumber(go_guide.args2)
        if nil == args2 then
          args2 = go_guide.args2
        end
      end
    end
    _G.NRCModuleManager:DoCmdWithArgs(go_guide.text, args1, args2)
  end
end

function MagicManualUtils.GetFlowerSeedFusionDataByData(Data)
  local visit_flower_seed_boss_data = {}
  visit_flower_seed_boss_data.spec_flower_seed_id = Data.spec_flower_seed_id
  visit_flower_seed_boss_data.seed_star = Data.star
  visit_flower_seed_boss_data.owner_id = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin()
  visit_flower_seed_boss_data.inner_petbase_id = Data.battle_petbase_id
  visit_flower_seed_boss_data.seed_npc_logic_id = Data.npc_logic_id
  return visit_flower_seed_boss_data
end

function MagicManualUtils.RefreshCurBubbleText(TextField, NpcRefreshId)
  local ThrowCount = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcTeamBattleThrowCount, NpcRefreshId)
  if ThrowCount > 0 then
    TextField:SetText(LuaText.ShinyFlower_again_tip)
  else
    TextField:SetText(LuaText.ShinyFlower_first_tip)
  end
end

function MagicManualUtils.RefreshCueBubbleNature(CueBubble, BossInfo, NatureText)
  CueBubble.NRCSwitcher_67:SetActiveWidgetIndex(1)
  if not NatureText and BossInfo.activity_id then
    local petNatureId = ActivityUtils.GetPetNatureIdBySeedId(BossInfo.spec_flower_seed_id)
    local petNatureConf = petNatureId and _G.DataConfigManager:GetNatureConf(petNatureId)
    NatureText = petNatureConf and petNatureConf.name or ""
  end
  CueBubble.textPetNature:SetText(NatureText or "")
end

function MagicManualUtils.GetNPCChallengeEventSchedule(conf)
  local MaxSchedule = 0
  local battle_Set = conf.battle_set
  local NpcChallengeConfList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_CHALLENGE_CONF):GetAllDatas()
  for i, battleId in pairs(battle_Set) do
    for j, NpcChallengeConf in pairs(NpcChallengeConfList) do
      if battleId == NpcChallengeConf.module_id then
        MaxSchedule = MaxSchedule + 1
      end
    end
  end
  return MaxSchedule
end

function MagicManualUtils.GetBossChallengeEventSchedule(conf)
  local MaxSchedule = 0
  local battle_Set = conf.battle_set
  local NpcChallengeConfList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BOSS_CHALLENGE_CONF):GetAllDatas()
  for i, battleId in pairs(battle_Set) do
    for j, NpcChallengeConf in pairs(NpcChallengeConfList) do
      if battleId == NpcChallengeConf.id then
        MaxSchedule = MaxSchedule + 1
      end
    end
  end
  return MaxSchedule
end

function MagicManualUtils.GetNPCChallengeEventStarNum(conf)
  local MaxStarNum = 0
  for i, star in ipairs(conf.star_reward) do
    if MaxStarNum < star.star_required then
      MaxStarNum = star.star_required
    end
  end
  return MaxStarNum
end

function MagicManualUtils.GetFinishNPCChallengeEventSchedule(npc_challenge_data, _IsTargets)
  local FinishSchedule = 0
  if npc_challenge_data then
    local NpcChallengeData = npc_challenge_data
    for i, module in ipairs(NpcChallengeData.modules) do
      for j, level in ipairs(module.levels) do
        if not _IsTargets then
          if level.is_finish then
            FinishSchedule = FinishSchedule + 1
          end
        elseif level.targets and #level.targets > 0 then
          for k, _ in ipairs(level.targets) do
            if _.is_finish then
              FinishSchedule = FinishSchedule + 1
            end
          end
        end
      end
    end
  end
  return FinishSchedule
end

function MagicManualUtils.GetFinishBossChallengeEventSchedule(boss_challenge_data, _IsTargets)
  local FinishSchedule = 0
  if boss_challenge_data then
    local BossChallengeData = boss_challenge_data
    for i, level in ipairs(BossChallengeData.levels) do
      if not _IsTargets then
        if level.is_finish then
          FinishSchedule = FinishSchedule + 1
        end
      elseif level.targets and #level.targets > 0 then
        for k, _ in ipairs(level.targets) do
          if _.is_finish then
            FinishSchedule = FinishSchedule + 1
          end
        end
      end
    end
  end
  return FinishSchedule
end

function MagicManualUtils.GetWeeklyChallengeStarNum(weekly_challenge_data)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0
  local totalStarNum = 0
  if weekly_challenge_data and weekly_challenge_data.rewards then
    for k, v in ipairs(weekly_challenge_data.rewards) do
      local lvRequire = v.magic_lv_required or 0
      if totalStarNum < v.star_required_num and worldLevel >= lvRequire then
        totalStarNum = v.star_required_num
      end
    end
  end
  return totalStarNum
end

function MagicManualUtils.GetFinishWeeklyChallengeEventSchedule(weekly_challenge_data)
  local FinishSchedule = 0
  if weekly_challenge_data and weekly_challenge_data.rewards then
    for i, reward in ipairs(weekly_challenge_data.rewards) do
      if reward.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE or reward.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
        FinishSchedule = reward.star_required_num
      end
    end
  end
  return FinishSchedule
end

function MagicManualUtils.GetTimeFormatStr(_seconds)
  if _seconds > 0 then
    local day = _seconds // 86400
    local hour = (_seconds - 86400 * day) // 3600
    local minute = (_seconds - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      return string.format(_G.LuaText.activity_RTS1, day, hour)
    elseif hour > 0 or minute > 0 then
      return string.format(_G.LuaText.activity_RTS2, hour, minute)
    else
      return _G.LuaText.activity_RTS3
    end
  else
    return _G.LuaText.activity_expired_show_tip
  end
end

function MagicManualUtils.GetAllTaskIdFromRecallId(recallId)
  if not recallId or 0 == recallId then
    Log.Error("MagicManualUtils.GetAllTaskIdFromRecallId recall id\233\157\158\230\179\149")
    return nil
  end
  local recallConf = _G.DataConfigManager:GetReacallConf(recallId)
  if not recallConf then
    Log.Error("MagicManualUtils.GetAllTaskIdFromRecallId \229\176\157\232\175\149\228\188\160\229\133\165\228\184\128\228\184\170\228\184\141\229\173\152\229\156\168\231\154\132recall id %s", recallId)
    return nil
  end
  local result = {}
  local fieldName = "data"
  for i = 1, 20 do
    local curFieldName = fieldName .. tostring(i)
    local dataItem = recallConf[curFieldName]
    if dataItem and 0 ~= dataItem then
      local listConf = _G.DataConfigManager:GetReacallListConf(dataItem)
      if listConf then
        if listConf.reacallt_list_unlock_trigger1 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
          table.insertUnique(result, listConf.trigger1_data)
        end
        if listConf.reacallt_list_unlock_trigger2 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
          table.insertUnique(result, listConf.trigger2_data)
        end
        if listConf.reacallt_list_unlock_trigger3 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
          table.insertUnique(result, listConf.trigger3_data)
        end
        local termsIds = {}
        if listConf.main_terms_id1 and 0 ~= listConf.main_terms_id1 then
          table.insert(termsIds, listConf.main_terms_id1)
        end
        if listConf.main_terms_id2 and 0 ~= listConf.main_terms_id2 then
          table.insert(termsIds, listConf.main_terms_id2)
        end
        if listConf.main_terms_id3 and 0 ~= listConf.main_terms_id3 then
          table.insert(termsIds, listConf.main_terms_id3)
        end
        if listConf.sub_terms_id1 and 0 ~= listConf.sub_terms_id1 then
          table.insert(termsIds, listConf.sub_terms_id1)
        end
        if listConf.sub_terms_id2 and 0 ~= listConf.sub_terms_id2 then
          table.insert(termsIds, listConf.sub_terms_id2)
        end
        if listConf.sub_terms_id3 and 0 ~= listConf.sub_terms_id3 then
          table.insert(termsIds, listConf.sub_terms_id3)
        end
        if listConf.sub_terms_id4 and 0 ~= listConf.sub_terms_id4 then
          table.insert(termsIds, listConf.sub_terms_id4)
        end
        for i, v in ipairs(termsIds) do
          local termsConf = _G.DataConfigManager:GetReacallTremsConf(v)
          if termsConf then
            if termsConf.reacallt_terms_unlock_trigger1 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
              table.insertUnique(result, termsConf.trigger1_data)
            end
            if termsConf.reacallt_terms_unlock_trigger2 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
              table.insertUnique(result, termsConf.trigger2_data)
            end
            if termsConf.reacallt_terms_unlock_trigger3 == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
              table.insertUnique(result, termsConf.trigger3_data)
            end
          end
        end
      end
    end
  end
  return result
end

return MagicManualUtils
