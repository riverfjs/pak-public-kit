local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local UMG_StarlightShowdownPanel_C = _G.NRCPanelBase:Extend("UMG_StarlightShowdownPanel_C")

function UMG_StarlightShowdownPanel_C:OnConstruct()
  self:SetChildViews(self.World3D)
end

function UMG_StarlightShowdownPanel_C:OnActive()
  self.module.bIsTeamDirty = false
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RefetchTeamList)
  self:SetChildViews(self.MyTeam)
  self.MyTeam:SetParent(self)
  self:OnAddEventListener()
  self.bIsEventOOD = false
  self.LoadJsonPath = "PhotoEditorJson"
  self.eventConf = self:_GetEventConf()
  if not (self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1]) or not self.eventConf then
    Log.Error("UMG_StarlightShowdownPanel_C\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\140\230\180\187\229\138\168Object\232\142\183\229\143\150\228\184\186\231\169\186")
    return
  end
  self:_PrefetchResetState()
  self:_InitPanel()
end

function UMG_StarlightShowdownPanel_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_StarlightShowdownPanel_C:OnPcClose()
  self:OnCloseButtonClick()
end

function UMG_StarlightShowdownPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClick)
  self:AddButtonListener(self.ParticularsBtn.btnLevelUp, self.OnDetailButtonClick)
  self:AddButtonListener(self.RewardBtn_1, self.OnRewardButtonClick)
  self:AddButtonListener(self.ResetBtn, self.OnResetButtonClick)
  self:AddButtonListener(self.RewardBtn_2, self.OnRewardButtonClick)
  self:AddButtonListener(self.Reminder.btnLevelUp, self.OnStartChallengeButtonClick)
  self:AddButtonListener(self.BtnEditingTeam.btnLevelUp, self.OnEditTeamBtnClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_StarlightShowdownPanel_C", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnTeamEquipMagic)
  _G.NRCEventCenter:RegisterEvent("UMG_StarlightShowdownPanel_C", self, WeeklyChallengeBattleModuleEvent.OpenLoadingCurtainEvent, self.OnLoadingCurtain)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged, self.OnActivityEventIdChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_StarlightShowdownPanel_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnectStart)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnTeamPetChanged, self.OnTeamPetChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnAllPetBalancedDataReady, self.OnAllPetBalancedDataReady)
end

function UMG_StarlightShowdownPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnTeamEquipMagic)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OpenLoadingCurtainEvent, self.OnLoadingCurtain)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnectStart)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnTeamPetChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnAllPetBalancedDataReady)
end

function UMG_StarlightShowdownPanel_C:OnActivityEventIdChanged()
  self.bIsEventOOD = true
end

function UMG_StarlightShowdownPanel_C:OnReConnectStart()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
  self:ClosePanel()
end

function UMG_StarlightShowdownPanel_C:OnPetAdjust()
  local petTeamList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local curPetList = {}
  for k, v in ipairs(petTeamList) do
    if v.gid and 0 ~= v.gid then
      local newerPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
      table.insert(curPetList, newerPetData)
    end
  end
  for i = #curPetList + 1, 6 do
    table.insert(curPetList, {})
  end
  self:UpdateTeamPetList(curPetList)
end

function UMG_StarlightShowdownPanel_C:OnTeamPetChanged(petList)
  self:UpdateTeamPetList(petList)
end

function UMG_StarlightShowdownPanel_C:OnAllPetBalancedDataReady()
  Log.Info("UMG_StarlightShowdownPanel_C:OnAllPetBalancedDataReady Refreshing pet team list")
  local petTeamList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local curPetList = {}
  for k, v in ipairs(petTeamList) do
    if v.gid and 0 ~= v.gid then
      local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, v.gid)
      if balancedPetData then
        table.insert(curPetList, balancedPetData)
      else
        local newerPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
        table.insert(curPetList, newerPetData)
      end
    end
  end
  for i = #curPetList + 1, 6 do
    table.insert(curPetList, {})
  end
  self:UpdateTeamPetList(curPetList)
end

function UMG_StarlightShowdownPanel_C:OnCloseButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_StarlightShowdownPanel_C:OnCloseButtonClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.ClosePanel)
end

function UMG_StarlightShowdownPanel_C:ClosePanel()
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnStarlightShowdownPanelClose)
  self:DoClose()
end

function UMG_StarlightShowdownPanel_C:OnDetailButtonClick()
  local titleText = _G.LuaText.weekly_challenge_text_10
  local contentStr = _G.LuaText.weekly_challenge_text_9
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_StarlightShowdownPanel_C:OnRewardButtonClick()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenRewardClaimPopupPanel, rewardList, true)
end

function UMG_StarlightShowdownPanel_C:OnResetButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StarlightShowdownPanel_C:OnResetButtonClick")
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

function UMG_StarlightShowdownPanel_C:OnStartChallengeButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StarlightShowdownPanel_C:OnStartChallengeButtonClick")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_StarlightShowdownPanel_C:OnStartChallengeButtonClick \230\180\187\229\138\168Object\228\184\186\231\169\186\239\188\140\230\151\160\230\179\149\229\188\128\229\167\139\230\140\145\230\136\152")
    return
  end
  if self.module.bIsTeamDirty then
    Log.Error("UMG_StarlightShowdownPanel_C:OnStartChallengeButtonClick \229\189\147\229\137\141\233\152\159\228\188\141\230\149\176\230\141\174\228\184\186\231\187\143\232\191\135\229\144\142\229\143\176\231\161\174\232\174\164\239\188\140\230\151\160\230\179\149\229\188\128\229\167\139\230\140\145\230\136\152")
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance) and self.module.bIsResetDataDirty then
    Log.Error("UMG_StarlightShowdownPanel_C:OnStartChallengeButtonClick \229\189\147\229\137\141\233\156\128\232\166\129\232\191\155\232\161\140\229\174\160\231\137\169\233\135\141\231\189\174\230\137\141\232\131\189\229\188\128\229\167\139\239\188\140\228\189\134\230\178\161\230\156\137\230\148\182\229\136\176\229\144\136\230\179\149\231\154\132\233\135\141\231\189\174\230\149\176\230\141\174\229\155\158\229\140\133\239\188\140\230\173\163\229\156\168\232\191\155\232\161\140\233\135\141\230\150\176\232\175\183\230\177\130")
    self:_PrefetchResetState()
    return
  end
  if self.bClicked then
    return
  end
  self.bClicked = true
  local currentTeam = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local validPetCount = 0
  for k, v in pairs(currentTeam) do
    if v.gid and 0 ~= v.gid then
      validPetCount = validPetCount + 1
    end
  end
  local oldCheerPoint = self.WeeklyChallengeEventActivityObject[1]:GetFinishWeeklyChallengeEventSchedule()
  local curCheerPoint = self:_CalculateCheerUpPoint(currentTeam)
  if validPetCount >= 1 and validPetCount < 6 then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local context = DialogContext()
    context:SetTitle(_G.LuaText.player_unstuck_confirm_title)
    context:SetContent(_G.LuaText.weekly_challenge_text_8)
    context:SetMode(DialogContext.Mode.OK_CANCEL)
    context:SetDialogType(DialogContext.DialogType.GeneralTip)
    context:SetCallback(self, self.OnStartChallengeCallback)
    context:SetForceEnableFullScreenBtn()
    context:SetButtonText(_G.LuaText.rolecard_favourite_pets_show_btn, _G.LuaText.CANCEL)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, context)
  elseif oldCheerPoint >= curCheerPoint then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local context = DialogContext()
    context:SetTitle(_G.LuaText.player_unstuck_confirm_title)
    context:SetContent(_G.LuaText.weekly_challenge_text_7)
    context:SetMode(DialogContext.Mode.OK_CANCEL)
    context:SetDialogType(DialogContext.DialogType.GeneralTip)
    context:SetCallback(self, self.OnCheerPointNotEnoughCallback)
    context:SetForceEnableFullScreenBtn()
    context:SetButtonText(_G.LuaText.rolecard_favourite_pets_show_btn, _G.LuaText.CANCEL)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, context)
  else
    self:OpenFirstDebutPanel()
    self.World3D:MoveCenter()
  end
end

function UMG_StarlightShowdownPanel_C:OnStartChallengeCallback(bIsOk)
  if bIsOk then
    local currentTeam = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
    local oldCheerPoint = self.WeeklyChallengeEventActivityObject[1]:GetFinishWeeklyChallengeEventSchedule()
    local curCheerPoint = self:_CalculateCheerUpPoint(currentTeam)
    if oldCheerPoint >= curCheerPoint then
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local context = DialogContext()
      context:SetTitle(_G.LuaText.player_unstuck_confirm_title)
      context:SetContent(_G.LuaText.weekly_challenge_text_7)
      context:SetMode(DialogContext.Mode.OK_CANCEL)
      context:SetDialogType(DialogContext.DialogType.GeneralTip)
      context:SetCallback(self, self.OnCheerPointNotEnoughCallback)
      context:SetForceEnableFullScreenBtn()
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, context)
    else
      self:OpenFirstDebutPanel()
      self.World3D:MoveCenter()
    end
  else
    self.bClicked = false
  end
end

function UMG_StarlightShowdownPanel_C:OnCheerPointNotEnoughCallback(bIsOk)
  if bIsOk then
    self:OpenFirstDebutPanel()
    self.World3D:MoveCenter()
  else
    self.bClicked = false
  end
end

function UMG_StarlightShowdownPanel_C:OnEditTeamBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_StarlightShowdownPanel_C:OnEditTeamBtnClicked")
  self:OpenTeamEditPanel(true)
end

function UMG_StarlightShowdownPanel_C:_GetEventConf()
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

function UMG_StarlightShowdownPanel_C:_PrefetchResetState()
  if not self.eventConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_PrefetchResetState eventConf\228\184\186\231\169\186")
    return
  end
  local challengeId = self.eventConf.challenge_id[1]
  local activityId = self.WeeklyChallengeEventActivityObject[1]:GetActivityId()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ResetPetStateReq, activityId, challengeId)
end

function UMG_StarlightShowdownPanel_C:_InitPanel()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitPanel \233\157\162\230\157\191\229\188\128\229\167\139\229\136\157\229\167\139\229\140\150")
  self:PlayAnimation(self.Open)
  local bNeedReq = false
  local currentTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  if currentTeamInfo.teams and currentTeamInfo.teams[currentTeamInfo.main_team_idx + 1] and currentTeamInfo.teams[currentTeamInfo.main_team_idx + 1].pet_infos then
    for k, v in pairs(currentTeamInfo.teams[currentTeamInfo.main_team_idx + 1].pet_infos) do
      if v.pet_gid and 0 ~= v.pet_gid then
        bNeedReq = true
        break
      end
    end
  end
  if bNeedReq and self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    local activityId = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
    local challengeId = self.eventConf.challenge_id[1]
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ResetPetStateReq, activityId, challengeId)
  end
  self:_InitEventBackground()
  self:_InitRivalInfo()
  self:_InitPetTeamList()
  self:_InitStartButton()
  self:_InitRewardButton()
  self:_InitResetButton()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitPanel \233\157\162\230\157\191\229\136\157\229\167\139\229\140\150\229\174\140\230\136\144")
end

function UMG_StarlightShowdownPanel_C:_InitEventBackground()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitEventBackground \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\232\131\140\230\153\175")
  if not self.eventConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitEventBackground eventConf\228\184\186\231\169\186")
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.eventConf.challenge_id[1])
  if not challengeConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitEventBackground \232\142\183\229\143\150WeeklyChallengeConf\229\164\177\232\180\165")
    return
  end
  local photoConf = _G.DataConfigManager:GetWeeklyPhotoConf(challengeConf.photo)
  if not photoConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitEventBackground \232\142\183\229\143\150photoConf\229\164\177\232\180\165")
    return
  end
  local curtainName = "MI_Curtain_001_03_Skeletal"
  if photoConf.background then
    curtainName = photoConf.background
    Log.Info(string.format("UMG_StarlightShowdownPanel_C:_InitEventBackground \228\189\191\231\148\168\233\133\141\231\189\174\232\161\168\230\168\161\230\157\191 %s", curtainName))
  else
    local json = JsonUtils.LoadSavedFromStarLight(photoConf.res_name or self.LoadJsonPath or "PhotoEditorJson", {})
    if json[1] and json[1][2] then
      curtainName = json[1][2]
    else
      Log.Error("\233\133\141\231\189\174\228\184\173\231\188\186\229\176\145\229\185\149\229\184\131\231\154\132\232\131\140\230\153\175\230\149\176\230\141\174\239\188\140\231\173\150\229\136\146\232\175\183\230\163\128\230\159\165\228\184\128\228\184\139")
    end
    Log.Info(string.format("UMG_StarlightShowdownPanel_C:_InitEventBackground \228\189\191\231\148\168\229\144\136\231\133\167\230\168\161\230\157\191 %s", curtainName))
  end
  local batch, number = self:_GetBatchAndNumberFromCurtainName(curtainName)
  local backgroundPath = string.format(UEPath.WeeklyChallengeBattleBackground, batch, number, batch, number)
  Log.Info(string.format("\229\138\160\232\189\189\232\131\140\230\153\175\232\181\132\230\186\144\232\183\175\229\190\132 %s", backgroundPath))
  self.NRCImage_5:SetPath(backgroundPath)
end

function UMG_StarlightShowdownPanel_C:_InitRivalInfo()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitRivalInfo \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\229\175\185\230\137\139\228\191\161\230\129\175")
  if not self.eventConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitRivalInfo eventConf\228\184\186\231\169\186")
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.eventConf.challenge_id[1])
  if not challengeConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitRivalInfo \232\142\183\229\143\150WeeklyChallengeConf\229\164\177\232\180\165")
    return
  end
  local initList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetRivalPetInitList)
  local battleConf = _G.DataConfigManager:GetBattleConf(challengeConf.battle, true)
  self.OpponentLineUp:InitGridView(initList)
  local hpList = {}
  for k = 1, battleConf.rival_available_HP do
    table.insert(hpList, {})
  end
  self.HPList:InitGridView(hpList)
  if battleConf and battleConf.npc_battle_list and #battleConf.npc_battle_list > 0 then
    if 0 ~= battleConf.npc_battle_list[1].magic then
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.MagicIconSwitcher:SetActiveWidgetIndex(0)
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(battleConf.npc_battle_list[1].magic, true)
      if bagItemConf then
        self.Icon_1:SetPath(bagItemConf.big_icon)
      else
        Log.Warning(string.format("\229\136\157\229\167\139\229\140\150\229\175\185\230\137\139\233\173\148\230\179\149\229\143\145\231\148\159\233\148\153\232\175\175\239\188\140magic id: %s\239\188\140\229\173\152\229\156\168magic id\228\189\134\230\152\175\229\156\168bag item conf\228\184\173\230\151\160\230\179\149\230\137\190\229\136\176\239\188\140\229\176\134\228\189\191\231\148\168\231\169\186\231\138\182\230\128\129\230\155\191\228\187\163", battleConf.npc_battle_list[1].magic))
        self.MagicIconSwitcher:SetActiveWidgetIndex(1)
      end
    else
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.MagicIconSwitcher:SetActiveWidgetIndex(1)
    end
  end
  self.NRCText_1:SetText(_G.LuaText.weekly_challenge_text_35)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local difficultyList = {}
  for k = 1, 5 do
    if k <= worldLevel then
      table.insert(difficultyList, {bShow = true})
    else
      table.insert(difficultyList, {bShow = false})
    end
  end
  self.HPList_1:InitGridView(difficultyList)
  self.NRCText:SetText(challengeConf.name)
  local npcConf = _G.DataConfigManager:GetNpcConf(challengeConf.npc)
  if not npcConf then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitRivalInfo \232\142\183\229\143\150NpcConf\229\164\177\232\180\165")
    return
  end
  self.World3D:SetVisibility(UE4.ESlateVisibility.Visible)
  self.World3D:SetModule(npcConf.model_conf)
end

function UMG_StarlightShowdownPanel_C:_InitPetTeamList()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitPetTeamList \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\229\183\177\230\150\185\233\152\159\228\188\141")
  self:OnTeamEquipMagic(0)
end

function UMG_StarlightShowdownPanel_C:_InitStartButton()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitStartButton \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\229\188\128\229\167\139\230\140\145\230\136\152\230\140\137\233\146\174\231\138\182\230\128\129")
  self:_UpdateStartButton()
  self.TextHint:SetText(_G.LuaText.weekly_challenge_text_30)
  self.Hint:SetShowLockIcon(false)
  self.Hint.Title_1:SetText(_G.LuaText.weekly_challenge_text_11)
  self.Hint:SetTitleTextAndIcon()
end

function UMG_StarlightShowdownPanel_C:_InitRewardButton()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitRewardButton \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\229\165\150\229\138\177\230\140\137\233\146\174\231\138\182\230\128\129")
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_StarlightShowdownPanel_C:_InitRewardButton \230\180\187\229\138\168Object\228\184\186\231\169\186")
    self.TextClaimProgress_1:SetText("0/12")
    return
  end
  local weeklyChallengeData = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  local totalStarNum = MagicManualUtils.GetWeeklyChallengeStarNum(weeklyChallengeData)
  local finishedStarNum = weeklyChallengeData.challenge_info.highest_cheer_point or 0
  self.TextClaimProgress_1:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
  self.TextClaimProgress_2:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
  self.RedDot_1:SetupKey(371, self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId())
  self.RedDot_2:SetupKey(371, self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId())
end

function UMG_StarlightShowdownPanel_C:_InitResetButton()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitResetButton \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\233\135\141\231\189\174\229\133\187\230\136\144\230\140\137\233\146\174")
  self.NRCText_37:SetText(_G.LuaText.weekly_challenge_text_13)
  self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self.eventConf then
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.eventConf.challenge_id[1])
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  if bIsNeedBalance then
    self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_StarlightShowdownPanel_C:_UpdateStartButton()
  local currentTeam = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local validPetCount = 0
  for k, v in pairs(currentTeam) do
    if v.gid ~= nil and 0 ~= v.gid then
      validPetCount = validPetCount + 1
    end
  end
  if 0 == validPetCount then
    self.Switcher:SetActiveWidgetIndex(1)
  else
    self.Switcher:SetActiveWidgetIndex(0)
  end
end

function UMG_StarlightShowdownPanel_C:UpdateTeamPetList(petList)
  self.MyTeam:SetPetTeamList(petList)
  self:_UpdateStartButton()
end

function UMG_StarlightShowdownPanel_C:OnTeamEquipMagic(mainTeamIndex)
  local currentTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  local skillId = 0
  if currentTeamInfo and currentTeamInfo.teams and currentTeamInfo.teams[mainTeamIndex + 1] then
    skillId = currentTeamInfo.teams[mainTeamIndex + 1].role_magic_gid
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    local bIsHasBlood = BagItemS and #BagItemS > 0 and true or false
    if bIsHasBlood and BagItemS then
      for i, bagItem in ipairs(BagItemS) do
        if bagItem.gid == skillId then
          self:UpdateTeamSkill(bagItem.id)
          return
        end
      end
    end
  end
  self:UpdateTeamSkill(0)
end

function UMG_StarlightShowdownPanel_C:OnLoadingCurtain()
  self:DoClose()
end

function UMG_StarlightShowdownPanel_C:UpdateTeamSkill(skill)
  self.MyTeam:SetSkill(skill)
end

function UMG_StarlightShowdownPanel_C:OnTeamEditPanelClosed()
  self:StopAnimation(self.Open)
  self:StopAnimation(self.Close)
  self:PlayAnimation(self.Open)
  _G.NRCAudioManager:PlaySound2DAuto(1069, "UMG_StarlightShowdownPanel_C:OnTeamEditPanelClosed")
  self.World3D:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.MyTeam:SetVisibility(UE4.ESlateVisibility.Visible)
  self.MyTeam.bClicked = false
end

function UMG_StarlightShowdownPanel_C:OnFirstDebutPetChoosePanelClosed()
  self:StopAnimation(self.Open)
  self:StopAnimation(self.Close)
  self:PlayAnimation(self.Open)
  _G.NRCAudioManager:PlaySound2DAuto(1069, "UMG_StarlightShowdownPanel_C:OnTeamEditPanelClosed")
  self.World3D:MoveResest()
  self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.MyTeam:SetVisibility(UE4.ESlateVisibility.Visible)
  self.bClicked = false
end

function UMG_StarlightShowdownPanel_C:OnEnterFirstDebutPanel()
  self.World3D:MoveCenter()
end

function UMG_StarlightShowdownPanel_C:_CalculateCheerUpPoint(petDataList)
  local totalCheerUpPoint = 0
  for k, v in ipairs(petDataList) do
    if v.gid and 0 ~= v.gid and v.cheer_point_info and #v.cheer_point_info > 0 then
      for k1, v1 in ipairs(v.cheer_point_info) do
        totalCheerUpPoint = totalCheerUpPoint + v1.cheer_point
      end
    end
  end
  return totalCheerUpPoint
end

function UMG_StarlightShowdownPanel_C:_GetBatchAndNumberFromCurtainName(fileName)
  if not fileName then
    return
  end
  local batch, number = string.match(fileName, "^MI_Curtain_(.-)_(.-)_Skeletal$")
  return batch, number
end

function UMG_StarlightShowdownPanel_C:GetJsonPathFromID(photo_template_id)
  local photoConf = DataConfigManager:GetWeeklyChallengeConf(photo_template_id)
  local jsonPath = photoConf.res_name
  return jsonPath
end

function UMG_StarlightShowdownPanel_C:OpenFirstDebutPanel()
  self.bIsOpeningFirstDebutPanel = true
  self:StopAnimation(self.Open)
  self:StopAnimation(self.Close)
  self:PlayAnimation(self.Close)
  self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCAudioManager:PlaySound2DAuto(1070, "UMG_StarlightShowdownPanel_C:OpenFirstDebutPanel")
end

function UMG_StarlightShowdownPanel_C:OpenTeamEditPanel(bFromBtn)
  self.bIsOpeningTeamEditPanel = true
  self:StopAnimation(self.Open)
  self:StopAnimation(self.Close)
  self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.World3D:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.Close)
  self.bClickPetHead = true
  _G.NRCAudioManager:PlaySound2DAuto(1070, "UMG_StarlightShowdownPanel_C:OpenTeamEditPanel")
end

function UMG_StarlightShowdownPanel_C:OnPetDataUpdate(newPetData)
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(newPetData.gid)
  self.MyTeam:UpdatePetData(petData)
end

function UMG_StarlightShowdownPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Close then
    if self.bIsOpeningFirstDebutPanel then
      self.MyTeam:SetVisibility(UE4.ESlateVisibility.Collapsed)
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenFirstDebutPetChoosePanel)
      self.bIsOpeningFirstDebutPanel = false
    elseif self.bIsOpeningTeamEditPanel then
      self.MyTeam:SetVisibility(UE4.ESlateVisibility.Collapsed)
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenTeamEditPanel, self.bClickPetHead)
      self.bIsOpeningTeamEditPanel = false
    else
      self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnStarlightShowdownPanelClose)
      self:DoClose()
    end
  end
end

return UMG_StarlightShowdownPanel_C
