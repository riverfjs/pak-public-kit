local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_TerritoryTrial_C = Base:Extend("UMG_Activity_TerritoryTrial_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_TerritoryTrial_C:BindUIElements()
  local uiElements = {}
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.title = self.Text_Title
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.MythicalCreaturesBG
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_TerritoryTrial_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
  local _activityInst = self.activityInst
  self:InitPanel(_activityInst:GetActivityData())
  self.redPointReward:SetupKey(215, self.activityInst:GetActivityId())
  local curWorldLv = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local requireLevel = _activityInst:GetWorldLevelRequired()
  if curWorldLv < requireLevel then
    self.RewardsPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_31:SetActiveWidgetIndex(1)
    local targetStr = _G.DataConfigManager:GetWorldLevelConf(requireLevel + 1).title
    self.NotUnlocked_Btn:SetOnlyShowTipText(string.format(_G.LuaText.activity_wolrd_level_low, targetStr))
  end
end

function UMG_Activity_TerritoryTrial_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_Activity_TerritoryTrial_C:OnAddEventListener()
  self:AddButtonListener(self.AwardBtn, self.OpenRewardPanel)
  self:AddButtonListener(self.ExamineBtn, self.OpenTrialDetailPanel)
  self:AddButtonListener(self.GoBtn.btnLevelUp, self.GotoTerritoryTrial)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshTerritoryTrialActivityData, self.InitPanel)
end

function UMG_Activity_TerritoryTrial_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.AwardBtn)
  self:RemoveButtonListener(self.ExamineBtn)
  self:RemoveButtonListener(self.GoBtn.btnLevelUp)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshTerritoryTrialActivityData)
end

function UMG_Activity_TerritoryTrial_C:InitPanel(territoryTrialData)
  local _activityInst = self.activityInst
  local rewardData = {}
  local territoryTrialConf = _G.DataConfigManager:GetTerritoryTrialConf(_activityInst:GetSinglePartId())
  local trialChallengeConf = _G.DataConfigManager:GetTerritoryTrialChallengeConf(territoryTrialConf.challenge_id[1])
  if territoryTrialData then
    if territoryTrialData.base_id ~= _activityInst:GetSinglePartId() then
      return
    end
    Log.DebugFormat("UMG_Activity_TerritoryTrial_C UpdateData update_base_id:%d, self_base_id:%d", territoryTrialData.base_id, _activityInst:GetSinglePartId())
    self.PointsText1:SetText(_G.LuaText.territory_trial_tips1)
    self.PointsText:SetText(territoryTrialData.trial_info.highest_score or _G.LuaText.territory_trial_battle_tips7)
    self.RoundsText1:SetText(_G.LuaText.territory_trial_tips2)
    self.RoundsText:SetText(territoryTrialData.trial_info.least_finish_round and string.format(_G.LuaText.territory_trial_tips3, territoryTrialData.trial_info.least_finish_round) or _G.LuaText.territory_trial_battle_tips7)
    local activity_id = _activityInst:GetActivityId()
    local reward_data = {}
    if territoryTrialConf.play_reward and 0 ~= territoryTrialConf.play_reward then
      reward_data.desc_text = territoryTrialConf.play_reward_text
      reward_data.reward_id = territoryTrialConf.play_reward
      reward_data.activity_id = activity_id
      reward_data.point_required = 0
      table.insert(rewardData, reward_data)
    end
    for _, v in ipairs(territoryTrialConf.point_reward) do
      reward_data = {}
      reward_data.desc_text = v.reward_text
      reward_data.reward_id = v.reward
      reward_data.activity_id = activity_id
      reward_data.point_required = v.point_required
      table.insert(rewardData, reward_data)
    end
    local rewardState = territoryTrialData.rewards
    for _, reward_state in ipairs(rewardState) do
      for _, r_data in ipairs(rewardData) do
        if reward_state.reward_id == r_data.reward_id then
          r_data.state = reward_state.state
          break
        end
      end
    end
  end
  local bossConf = _G.DataConfigManager:GetMonsterConf(trialChallengeConf.boss)
  local boss_base_id = bossConf.base_id
  local baseConf
  local normalBaseConf = _G.DataConfigManager:GetPetbaseConf(territoryTrialConf.pet_id)
  local pet_evolution_id = normalBaseConf.pet_evolution_id[1]
  local evolution_chain = _G.DataConfigManager:GetPetEvolutionConf(pet_evolution_id).evolution_chain
  local itemDatas = {}
  for i = 1, #evolution_chain do
    table.insert(itemDatas, {
      base_id = evolution_chain[i].petbase_id
    })
  end
  self.PetGridView:InitGridView(itemDatas)
  local trialInformation = {}
  trialInformation.tabData = {}
  trialInformation.guardData = {}
  local g_data, skillConf
  for _, v in ipairs(trialChallengeConf.guard) do
    local guard_conf = _G.DataConfigManager:GetMonsterConf(v.monster)
    local guard_name = guard_conf.name
    table.insert(trialInformation.tabData, {name = guard_name})
    g_data = {}
    g_data.level = guard_conf.new_level
    baseConf = _G.DataConfigManager:GetPetbaseConf(guard_conf.base_id)
    g_data.type = baseConf.unit_type
    skillConf = _G.DataConfigManager:GetSkillConf(baseConf.pet_feature)
    g_data.skill_icon = skillConf.icon
    g_data.skill_desc = skillConf.desc
    g_data.skill_name = skillConf.name
    g_data.inspire_time = guard_conf.inspire_time
    g_data.buff_data = {}
    for _, skill_id in ipairs(v.entry) do
      skillConf = _G.DataConfigManager:GetSkillConf(skill_id)
      local data = {}
      data.name = skillConf.name
      data.desc = skillConf.desc
      table.insert(g_data.buff_data, data)
    end
    g_data.base_id = guard_conf.base_id
    table.insert(trialInformation.guardData, g_data)
  end
  baseConf = _G.DataConfigManager:GetPetbaseConf(boss_base_id)
  table.insert(trialInformation.tabData, {
    name = bossConf.name,
    bBoss = true
  })
  g_data = {}
  g_data.level = bossConf.new_level
  g_data.type = baseConf.unit_type
  skillConf = _G.DataConfigManager:GetSkillConf(baseConf.pet_feature)
  g_data.skill_icon = skillConf.icon
  g_data.skill_desc = skillConf.desc
  g_data.skill_name = skillConf.name
  g_data.inspire_time = bossConf.inspire_time
  g_data.buff_data = {}
  for _, v in ipairs(trialChallengeConf.boss_entry) do
    skillConf = _G.DataConfigManager:GetSkillConf(v)
    local data = {}
    data.name = skillConf.name
    data.desc = skillConf.desc
    table.insert(g_data.buff_data, data)
  end
  g_data.base_id = boss_base_id
  table.insert(trialInformation.guardData, g_data)
  self.trialInformation = trialInformation
  self.rewardData = rewardData
  self:SortRewardData()
  self:DispatchEvent(ActivityModuleEvent.RefreshTerritoryTrialRewardPreview, rewardData)
end

function UMG_Activity_TerritoryTrial_C:SortRewardData()
  self:SortData(self.rewardData, function(a, b)
    if a.state == b.state then
      return a.point_required > b.point_required
    end
    if a.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
      return false
    elseif b.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
      return true
    elseif b.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
      return true
    else
      return false
    end
  end, 1, #self.rewardData)
end

function UMG_Activity_TerritoryTrial_C:SortData(data, func, start, stop)
  if stop <= start then
    return
  end
  local baseItem = data[start]
  local left = start
  local right = stop
  local bRight = true
  while left < right do
    if bRight then
      if func(baseItem, data[right]) then
        data[left] = data[right]
        left = left + 1
        bRight = false
      else
        right = right - 1
      end
    elseif func(data[left], baseItem) then
      data[right] = data[left]
      right = right - 1
      bRight = true
    else
      left = left + 1
    end
  end
  data[left] = baseItem
  self:SortData(data, func, start, left - 1)
  self:SortData(data, func, left + 1, stop)
end

function UMG_Activity_TerritoryTrial_C:OpenRewardPanel()
  if self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenTerritoryTrialRewardPreview, self.rewardData)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
end

function UMG_Activity_TerritoryTrial_C:OpenTrialDetailPanel()
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenTerritoryTrialInformation, self.trialInformation)
end

function UMG_Activity_TerritoryTrial_C:GotoTerritoryTrial()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  local redirect_id = _G.DataConfigManager:GetTerritoryTrialConf(self.activityInst:GetSinglePartId()).redirect
  ActivityUtils.DoActivityOptionCmd(redirect_id)
end

return UMG_Activity_TerritoryTrial_C
