local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local UMG_FirstReleasePanel_C = _G.NRCPanelBase:Extend("UMG_FirstReleasePanel_C")

function UMG_FirstReleasePanel_C:OnActive(petDataList)
  self:OnAddEventListener()
  self.bIsEventOOD = false
  self.eventConf = self:_GetEventConf()
  self.petDataList = {}
  for k, v in ipairs(petDataList) do
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
    if petData and 0 ~= petData then
      table.insert(self.petDataList, petData)
    end
  end
  self:_InitPanel()
end

function UMG_FirstReleasePanel_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_FirstReleasePanel_C:OnPcClose()
  self:OnReturnButtonClick()
end

function UMG_FirstReleasePanel_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnReturnButtonClick)
  self:AddButtonListener(self.StartTheShow.btnLevelUp, self.OnStartShowButtonClick)
  self:AddButtonListener(self.ResetBtn, self.OnResetButtonClick)
  _G.NRCEventCenter:RegisterEvent("UMG_StarlightShowdownPanel_C", self, WeeklyChallengeBattleModuleEvent.OpenLoadingCurtainEvent, self.OpenLoadingCurtainEvent)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged, self.OnActivityEventIdChanged)
end

function UMG_FirstReleasePanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OpenLoadingCurtainEvent, self.OpenLoadingCurtainEvent)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged)
end

function UMG_FirstReleasePanel_C:OnActivityEventIdChanged()
  self.bIsEventOOD = true
end

function UMG_FirstReleasePanel_C:OnReturnButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_FirstReleasePanel_C:OnReturnButtonClick")
  self:StopAnimation(self.In)
  self:StopAnimation(self.Out)
  self:PlayAnimation(self.Out)
end

function UMG_FirstReleasePanel_C:OnResetButtonClick()
  self:PlayAnimation(self.Press)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FirstReleasePanel_C:OnResetButtonClick")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  if not self.eventConf then
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.eventConf.challenge_id[1])
  if not challengeConf then
    return
  end
  local _, level, grow, workHard = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenResetNotification, bIsNeedBalance, grow, level, workHard)
end

function UMG_FirstReleasePanel_C:OnStartShowButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FirstReleasePanel_C:OnStartShowButtonClick")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.WeeklyChallengeClick)
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_FirstReleasePanel_C:OnStartShowButtonClick \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("UMG_FirstReleasePanel_C:OnStartShowButtonClick \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
  local challengeId = weekly_challenge_data.challenge_info.challenge_id
  local firstDebutPetGid = self.module.data:GetFirstDebutPetGid()
  if not firstDebutPetGid or 0 == firstDebutPetGid then
    Log.Error("UMG_FirstReleasePanel_C:OnStartShowButtonClick \232\142\183\229\143\150\233\166\150\229\143\145\229\174\160\231\137\169gid\229\164\177\232\180\165")
    return
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.AddDontDisablePanelToList, "StarlightShowDown")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendZoneWeeklyChallengeCreateBattleReq, activityId, challengeId, firstDebutPetGid)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetCanClearBgm, false)
end

function UMG_FirstReleasePanel_C:OpenLoadingCurtainEvent()
  self:DoClose()
end

function UMG_FirstReleasePanel_C:_InitPanel()
  self:StopAnimation(self.Out)
  self:StopAnimation(self.In)
  self:PlayAnimation(self.In)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  local initList = {}
  if bIsNeedBalance then
    local team = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
    if team and team.teams and team.teams[1] and team.teams[1].pet_infos then
      for k, v in ipairs(team.teams[1].pet_infos) do
        if v then
          local petData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, v.pet_gid)
          if not petData or 0 == petData.gid then
            Log.Error("\233\152\159\228\188\141\228\184\173\231\154\132\229\174\160\231\137\169\233\135\141\231\189\174\228\191\161\230\129\175\231\188\186\229\164\177\239\188\140\230\156\137\233\151\174\233\162\152")
          else
            table.insert(initList, petData)
          end
        end
      end
    else
      Log.Error("\231\169\186\233\152\159\228\188\141\232\191\155\229\133\165\239\188\140\230\156\137\233\151\174\233\162\152")
    end
  else
    for k, v in ipairs(self.petDataList) do
      if v.gid and 0 ~= v.gid then
        table.insert(initList, v)
      end
    end
  end
  self.PetList:InitGridView(initList)
  for i = 1, #self.petDataList do
    self.PetList:OpItemByIndex(i, 1, false)
  end
  self.PetList:SelectItemByIndex(0)
  for i = 1, #self.petDataList do
    self.PetList:OpItemByIndex(i, 1, true)
  end
  if bIsNeedBalance then
    self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local eventConf = self:_GetEventConf()
  if eventConf then
    self:_InitRivalInfo(eventConf)
  end
  self.Switcher_Title:SetActiveWidgetIndex(1)
  self.NRCText_37:SetText(_G.LuaText.weekly_challenge_text_13)
  local totalCheerUpPoint = 0
  for k, v in ipairs(self.petDataList) do
    if v.gid and 0 ~= v.gid and v.cheer_point_info and #v.cheer_point_info > 0 then
      for k1, v1 in ipairs(v.cheer_point_info) do
        totalCheerUpPoint = totalCheerUpPoint + v1.cheer_point
      end
    end
  end
  self.Headline_1:SetText(string.format("x%s", totalCheerUpPoint))
end

function UMG_FirstReleasePanel_C:_InitRivalInfo(eventConf)
  if not eventConf then
    Log.Error("UMG_FirstReleasePanel_C:_InitRivalInfo eventConf\228\184\186\231\169\186")
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(eventConf.challenge_id[1])
  if not challengeConf then
    Log.Error("UMG_FirstReleasePanel_C:_InitRivalInfo \232\142\183\229\143\150WeeklyChallengeConf\229\164\177\232\180\165")
    return
  end
  local text = _G.LuaText[challengeConf.text]
  self.ContentTip:SetText(text)
  local charCount = utf8.len(text) or 0
  local font = self.ContentTip.Font
  if charCount > 24 then
    font.Size = 18
  else
    font.Size = 22
  end
  self.ContentTip:SetFont(font)
  local initList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetRivalPetInitList)
  self.PetList_1:InitGridView(initList)
  local battleConf = _G.DataConfigManager:GetBattleConf(challengeConf.battle, true)
  if battleConf and battleConf.npc_battle_list and #battleConf.npc_battle_list > 0 then
    if 0 ~= battleConf.npc_battle_list[1].magic then
      self.MagicIconSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCImage_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.MagicIconSwitcher:SetActiveWidgetIndex(0)
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(battleConf.npc_battle_list[1].magic, true)
      if bagItemConf then
        self.Icon_1:SetPath(bagItemConf.big_icon)
      else
        Log.Warning(string.format("\229\136\157\229\167\139\229\140\150\229\175\185\230\137\139\233\173\148\230\179\149\229\143\145\231\148\159\233\148\153\232\175\175\239\188\140magic id: %s\239\188\140\229\173\152\229\156\168magic id\228\189\134\230\152\175\229\156\168bag item conf\228\184\173\230\151\160\230\179\149\230\137\190\229\136\176\239\188\140\229\176\134\228\189\191\231\148\168\231\169\186\231\138\182\230\128\129\230\155\191\228\187\163", battleConf.npc_battle_list[1].magic))
        self.MagicIconSwitcher:SetActiveWidgetIndex(1)
      end
    else
      self.MagicIconSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.MagicIconSwitcher:SetActiveWidgetIndex(1)
    end
  end
  self.Title:SetText(challengeConf.name)
end

function UMG_FirstReleasePanel_C:_GetEventConf()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return nil
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if weekly_challenge_data then
    return _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  end
  return nil
end

function UMG_FirstReleasePanel_C:_GetEventConf()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    return nil
  end
  local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if weekly_challenge_data then
    return _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  end
  return nil
end

function UMG_FirstReleasePanel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
    _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseFirstDebutPetChoosePanel)
  elseif Anim == self.Press then
    self:PlayAnimation(self.Up)
  end
end

return UMG_FirstReleasePanel_C
