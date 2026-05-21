local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local UMG_Pass_AwardMain_C = _G.NRCPanelBase:Extend("UMG_Pass_AwardMain_C")
local UIUtils = require("NewRoco.Utils.UIUtils")

function UMG_Pass_AwardMain_C:OnConstruct()
  self:SetChildViews(self.PresentAGift, self.Activity)
  self.PresentAGift:OnActive(0, LuaText.umg_pass_awardmain_1)
  self.Activity:OnActive(1, LuaText.umg_pass_awardmain_2)
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.PassAwardMap = {}
  self.bpTaskResetBeginTime = 0
end

function UMG_Pass_AwardMain_C:OnActive(arg, isSelectJump, tabIndex)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReqBattlePassShopData)
  self.Dot:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Dot_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Dot_1:SetupKey(142)
  self.Dot:SetupKey(147)
  self.module:InitSpineWidgetForPanel(self, "BattlePassAwardMain", "UMG_Pass_AwardMain")
  self.battlePassInfo = self.module.data:GetPlayerBattlePassInfo()
  self.updateTaskTime = self:GetUpdateActiveTime()
  if self.battlePassInfo then
    self.oldLv = self.battlePassInfo.exp_info.level
    self.oldExp = self.battlePassInfo.exp_info.exp
  end
  self.PassAwardMap = self:GetPassLevelAwardMap()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.SetActiveSelectTabIndex, 0)
  self.countDown = self:DisablePass(self.battlePassInfo.battle_pass_id)
  self.MaxBpLevel = self.module.data:GetBpMaxLevel()
  self:RefreshHeadBar()
  if nil ~= arg or 1 == tabIndex then
    self.taskId = arg
    self.Activity:OnTriggerFun()
  else
    self.PresentAGift:OnTriggerFun()
  end
  if isSelectJump then
    self:PlayAnimation(self.Page_In)
  else
    self:PlayAnimation(self.Page_In_2)
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ClosePassSelectPanel)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PASS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  self:BindInputAction()
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  local bpGlobalConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BP_GLOBAL_CONFIG):GetAllDatas()
  for _, conf in ipairs(bpGlobalConf) do
    if conf.key == "bp_task_reset_begin_time" then
      self.bpTaskResetBeginTime = UIUtils.GetSecondsFromTimeString(conf.str)
      break
    end
  end
  self:OnCountdown()
  self:InitGiftInfo()
end

function UMG_Pass_AwardMain_C:OnDestruct()
  self:CancelDelay()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateActiveTableView, self.OnRefreshUI)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateActivityTaskDatas, self.RefreshRevAllBtnVisState)
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP, self.module.ActivityPassBgmState)
  if self.module.ActivityPassBgmState then
    MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, "UMG_Pass_AwardMain_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.RefreshAnotherThemeFriendUI, self.OnRefreshAnotherThemeFriendUI)
  self.module:CloseAllPanel()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  self.WidgetLoader:UnLoadPanel(true)
  self.Unlock.OnPressed:Remove(self, self.OnUnlockBtnPressed)
  self.Unlock.OnReleased:Remove(self, self.OnUnlockBtnReleased)
end

function UMG_Pass_AwardMain_C:OnDeactive()
  self:CancelDelay()
  self:ClearAllEnhancedInput()
end

function UMG_Pass_AwardMain_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_PassAwardMain")
  if mappingContext then
    mappingContext:BindAction("IA_ClosePassAwardMain", self, "OnPcClose")
  end
end

function UMG_Pass_AwardMain_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseBtn()
end

function UMG_Pass_AwardMain_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.Upgrade, self.OnLevelUpClick)
  self:AddButtonListener(self.GetBtn.btnLevelUp, self.OnRecAllClick)
  self:AddButtonListener(self.ViewDetails.btnLevelUp, self.OnOpenPetPanel)
  self:AddButtonListener(self.Change_Team.btnLevelUp, self.OnChangeTeam)
  self:AddButtonListener(self.Unlock, self.OnOpenPurchas)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnOpenTips)
  self.WidgetLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_AwardMain_C", self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_AwardMain_C", self, BattlePassModuleEvent.UpdateActiveTableView, self.OnRefreshUI)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_AwardMain_C", self, BattlePassModuleEvent.UpdateActivityTaskDatas, self.RefreshRevAllBtnVisState)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_AwardMain_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  self.ViewDetails.btnLevelUp:SetVisibility(UE4.ESlateVisibility.Visible)
  self:AddButtonListener(self.BPFriendButton, self.OnBPFriendButtonClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_AwardMain_C", self, BattlePassModuleEvent.RefreshAnotherThemeFriendUI, self.OnRefreshAnotherThemeFriendUI)
  self.Unlock.OnPressed:Add(self, self.OnUnlockBtnPressed)
  self.Unlock.OnReleased:Add(self, self.OnUnlockBtnReleased)
end

function UMG_Pass_AwardMain_C:OnUnlockBtnPressed()
  if self.Press then
    self:PlayAnimation(self.Press)
  end
end

function UMG_Pass_AwardMain_C:OnUnlockBtnReleased()
  if self.Up then
    self:PlayAnimation(self.Up)
  end
end

function UMG_Pass_AwardMain_C:OnReLoginUpdate()
  if self.module then
    self.module:GetNewBattlePassInfo()
  end
end

function UMG_Pass_AwardMain_C:GetPassLevelAwardMap()
  local map = {}
  if self.battlePassInfo then
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local gender = player.gender
    local allRewardConf = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetAllRewardConfig)
    local battlePassCfg = _G.DataConfigManager:GetBattlePassConf(self.battlePassInfo.battle_pass_id)
    if nil == battlePassCfg then
      return map
    end
    local TOP_LEVEL = battlePassCfg.top_level
    local LOOP_LEVEL = battlePassCfg.loop_level
    for i = 1, TOP_LEVEL do
      for j = 1, #allRewardConf do
        if allRewardConf[j].bp_level == i then
          local rewardId = 0
          if 1 == gender then
            rewardId = allRewardConf[j].male_paid_reward_id
          else
            rewardId = allRewardConf[j].female_paid_reward_id
          end
          map[i] = rewardId
          break
        end
      end
    end
  end
  return map
end

function UMG_Pass_AwardMain_C:OnCountdown()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.DoDeactiveBattlepass)
  if self.countDown and self.countDown <= 0 then
    self:CancelDelay()
    self:OnClose()
    UE4Helper.SetEnableWorldRendering(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("bp_close").msg)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
    return
  end
  self.countDown = self.countDown - 1
  local str = self:GetExpireTimeDateString(self.countDown)
  if 1 == self.preTabIndex then
    local taskResetTime = self:GetUpdateActiveTime()
    str = self:GetExpireTimeDateString(taskResetTime)
  end
  if "" == str then
    self:CancelDelay()
    return
  end
  self.Time.TimeRemaining:SetText(str)
  self:DelaySeconds(1, self.OnCountdown, self)
end

function UMG_Pass_AwardMain_C:GetNextStartTime(datas, curTime)
  local endTimes = {}
  for _, data in ipairs(datas) do
    local starTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, data.task_set_start_time)
    if curTime < starTime then
      table.insert(endTimes, starTime)
    end
  end
  table.sort(endTimes, function(a, b)
    return a < b
  end)
  return #endTimes > 0 and endTimes[1] or nil
end

function UMG_Pass_AwardMain_C:GetUpdateActiveTime()
  local curTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  local nextResetCountdown = self:CalculateNextResetCountdown(curTime, self.bpTaskResetBeginTime)
  return nextResetCountdown
end

function UMG_Pass_AwardMain_C:CalculateNextResetCountdown(curTime, bpTaskResetBeginTime)
  if not curTime or curTime <= 0 then
    curTime = os.time()
  end
  local currentDate = os.date("*t", curTime)
  if not (currentDate and currentDate.year and currentDate.month and currentDate.day) or currentDate.year < 1970 or currentDate.year > 3000 or currentDate.month < 1 or currentDate.month > 12 or currentDate.day < 1 or currentDate.day > 31 then
    currentDate = os.date("*t")
  end
  local todayResetTime = os.time({
    year = currentDate.year,
    month = currentDate.month,
    day = currentDate.day,
    hour = 0,
    min = 0,
    sec = 0
  })
  if not todayResetTime or todayResetTime <= 0 then
    local nowDate = os.date("*t")
    todayResetTime = os.time({
      year = nowDate.year,
      month = nowDate.month,
      day = nowDate.day,
      hour = 0,
      min = 0,
      sec = 0
    })
  end
  todayResetTime = todayResetTime + bpTaskResetBeginTime
  if curTime < todayResetTime then
    return todayResetTime - curTime
  else
    local tomorrowDate = os.date("*t", todayResetTime)
    tomorrowDate.day = tomorrowDate.day + 1
    local tomorrowResetTime = os.time({
      year = tomorrowDate.year,
      month = tomorrowDate.month,
      day = tomorrowDate.day,
      hour = 0,
      min = 0,
      sec = 0
    })
    if not tomorrowResetTime or tomorrowResetTime <= 0 then
      tomorrowResetTime = todayResetTime + 86400
    else
      tomorrowResetTime = tomorrowResetTime + bpTaskResetBeginTime
    end
    return tomorrowResetTime - curTime
  end
end

function UMG_Pass_AwardMain_C:DisablePass(pass_id)
  if nil == pass_id then
    return 999999
  end
  local closeTime = _G.DataConfigManager:GetBattlePassConf(pass_id).close_time
  local passOverTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, closeTime)
  local curTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  local overTime = passOverTime - curTime
  return overTime
end

function UMG_Pass_AwardMain_C:SetThemeRes()
  self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local isThemeA = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsThemeA, self.theme_id)
  if isThemeA then
    self.SpineWidget_Blue:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SpineWidget_Pink:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SpineWidget_Pink:ClearTrack(0)
    self.SpineWidget_Blue:SetAnimation(0, "Idle", true)
  else
    self.SpineWidget_Blue:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SpineWidget_Pink:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SpineWidget_Blue:ClearTrack(0)
    self.SpineWidget_Pink:SetAnimation(0, "Idle", true)
    self.SpineWidget_Pink:SetScaleX(-1)
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_AwardMain", self)
end

function UMG_Pass_AwardMain_C:GetExpireTimeDateString(time)
  if time <= 0 then
    return
  end
  local day = math.floor(time / 86400)
  local hour = math.floor(time % 86400 / 3600)
  local minute = math.floor(time % 86400 % 3600 / 60)
  local str = ""
  if day > 0 then
    str = day .. LuaText.umg_pass_awardmain_3 .. hour .. LuaText.umg_pass_awardmain_4
  elseif hour > 0 then
    str = hour .. LuaText.umg_pass_awardmain_4 .. minute .. LuaText.umg_pass_awardmain_5
  elseif minute > 0 then
    str = 0 .. LuaText.umg_pass_awardmain_4 .. minute .. LuaText.umg_pass_awardmain_5
  else
    str = LuaText.activity_RTS3
  end
  return str
end

function UMG_Pass_AwardMain_C:OnLevelUpClick()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Pass_AwardMain_C:OnLevelUpClick")
  if self.battlePassInfo.exp_info.level >= self.MaxBpLevel then
    local canTirggerTips = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.CanAwardTablTipsTirgger)
    if false == canTirggerTips then
      return
    end
    local errorTips = _G.DataConfigManager:GetLocalizationConf("Error_bp_buylevel").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, errorTips)
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").UPGRADE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenLevelUpgradePanel)
  self:ShowOrHideTime(false)
end

function UMG_Pass_AwardMain_C:ShowOrHideTime(IsShow)
  if IsShow then
    self.Time:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pass_AwardMain_C:OnRecAllClick()
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_Pass_AwardMain_C:OnChangeTeam")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").GET
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  local curIndex = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetActiveSelectTabIndex)
  if 0 == curIndex then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReceiveBattlePassReward, true)
  else
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetAllZoneTaskReward)
  end
end

function UMG_Pass_AwardMain_C:OnOpenPetPanel()
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, false)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").PET
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  self.ViewDetails.btnLevelUp:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Pass_AwardMain_C:OnOpenPetPanel")
  self:CancelDelay()
  self:DelaySeconds(0.3, function()
    local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
    local petId = _G.DataConfigManager:GetBattlePassThemeConf(BattlePassInfo.theme_id).theme_petbase_id
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petId, true)
    self.ViewDetails.btnLevelUp:SetVisibility(UE4.ESlateVisibility.Visible)
  end)
end

function UMG_Pass_AwardMain_C:OnChangeTeam()
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, false)
  _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_Pass_AwardMain_C:OnChangeTeam")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").CHANGETEAM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassSelectPanel)
end

function UMG_Pass_AwardMain_C:OnOpenPurchas()
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Pass_AwardMain_C:OnOpenPurchas")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, false)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").UNLOCK
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassPurchasePanel)
end

function UMG_Pass_AwardMain_C:OnOpenTips()
  if self:CheckIsSelectBtn() then
    return
  end
  if self:IsAnimationPlaying(self.Page_Out) then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").INFO
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_AwardMain_C:OnOpenTips")
  self:OnOpenTipsPanel()
end

function UMG_Pass_AwardMain_C:OnOpenTipsPanel()
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_Select_C:OnOpenTips")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = LuaText.battle_pass_activity_title
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local rule_tips_id = _G.DataConfigManager:GetBattlePassConf(BattlePassInfo.battle_pass_id).rule_tips_id
  local Content = _G.DataConfigManager:GetLocalizationConf(rule_tips_id).msg
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Pass_AwardMain_C:OnUpdateBattlePassInfo()
  if self.battlePassInfo == nil then
    return
  end
  local oldLv = self.oldLv or self.battlePassInfo.exp_info.level
  local oldExp = self.oldExp or self.battlePassInfo.exp_info.exp
  self.battlePassInfo = self.module.data:GetPlayerBattlePassInfo()
  local newLv = self.battlePassInfo.exp_info.level
  local newExp = self.battlePassInfo.exp_info.exp
  self.oldLv = newLv
  self.oldExp = newExp
  self:RefreshHeadBar(oldExp)
  self:RefreshRevAllBtnVisState()
  self:InitGiftInfo()
  local curIndex = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetActiveSelectTabIndex)
  if 0 == curIndex then
    self:OpenPassGift(self.battlePassInfo)
  end
  if oldLv ~= newLv then
    self.delayPlayUpgradeInfo = {oldLv = oldLv, newLv = newLv}
    if self.module:HasPanel("BattlePurchasePanel") then
      self.module.data:SetCacheLevelUpData(oldLv, newLv)
      return
    end
    if oldExp == newExp then
      self:OnPetExpEffectPlayEnd()
    end
  end
end

function UMG_Pass_AwardMain_C:RefreshRevAllBtnVisState()
  local curIndex = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetActiveSelectTabIndex)
  if 0 == curIndex then
    if self:HasGiftRewards() then
      self.GetBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.GetBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    local showAllGetBtn = #_G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetAllFinshTaskIds) > 0
    local isCurWeekExpFull = self:IsCurWeekExpFull()
    local isBPLevelMax = self:IsBPLevelMax()
    if showAllGetBtn then
      self.GetBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.GetBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pass_AwardMain_C:IsCurWeekExpFull()
  if self.battlePassInfo then
    local maxWeekExp = self.module.data:GetMaxWeekExp()
    local curExp = self.battlePassInfo.exp_info.last_week_exp
    return maxWeekExp <= curExp
  else
    return false
  end
end

function UMG_Pass_AwardMain_C:IsBPLevelMax()
  if self.battlePassInfo then
    local maxLevel = self.module.data:GetBpMaxLevel()
    local curLevel = self.battlePassInfo.exp_info.level
    return maxLevel <= curLevel
  else
    return false
  end
end

function UMG_Pass_AwardMain_C:HasGiftRewards()
  local bpPassInfo = self.battlePassInfo
  local isPaid = self.module.data:IsPaid()
  if bpPassInfo and bpPassInfo.reward_info and bpPassInfo.reward_info.reward_taken_info and #bpPassInfo.reward_info.reward_taken_info > 0 then
    for i = 1, #bpPassInfo.reward_info.reward_taken_info do
      local info = bpPassInfo.reward_info.reward_taken_info[i]
      if info.is_free_reward_taken == false then
        return true
      end
      if isPaid and false == info.is_paid_reward_taken then
        local rewardId = self.PassAwardMap[i]
        if rewardId > 0 then
          return true
        end
      end
    end
  end
  return false
end

function UMG_Pass_AwardMain_C:HasTaskRewards()
  return #_G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetAllFinshTaskIds) > 0
end

function UMG_Pass_AwardMain_C:OnRefreshUI(tabIndex)
  if 0 == tabIndex then
    _G.NRCAudioManager:PlaySound2DAuto(1220002018, "UMG_Pass_AwardMain_C:OnRefreshUI")
    if self.preTabIndex and self.preTabIndex ~= tabIndex then
      self:DelaySeconds(0.2, function()
        self:OpenPassGift(self.battlePassInfo)
      end)
    else
      self:OpenPassGift(self.battlePassInfo)
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(1220002017, "UMG_Pass_AwardMain_C:OnRefreshUI")
    self:RefreshActivityUI()
    if self.preTabIndex and self.preTabIndex ~= tabIndex then
      self:DelaySeconds(0.2, function()
        self:OpenPassActivity(self.taskId)
      end)
    else
      self:OpenPassActivity(self.taskId)
    end
    self.taskId = nil
  end
  self:RefreshCommonTitle(tabIndex)
  self:RefreshRevAllBtnVisState()
  self.preTabIndex = tabIndex
end

function UMG_Pass_AwardMain_C:RefreshHeadBar(oldExp)
  local bpInfo = self.battlePassInfo
  local themId = bpInfo.theme_id
  self.theme_id = themId
  local battlePassConf = _G.DataConfigManager:GetBattlePassConf(bpInfo.battle_pass_id)
  local battleThemConf = _G.DataConfigManager:GetBattlePassThemeConf(themId)
  if nil == battleThemConf then
    Log.Error("\230\136\152\228\187\164id:", bpInfo.battle_pass_id, "\228\184\187\233\162\152id:", themId, "\230\156\137\232\175\175")
    return
  end
  local curGrade = bpInfo.battle_pass_brief_info.gift_grade
  if curGrade ~= _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self:InitBPFriendUI()
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  local themName = battleThemConf.theme_name
  local paid_reward_name = battleThemConf.paid_reward_name
  local maxWeekExp = self.module.data:GetMaxWeekExp()
  local unlockName = ""
  if _G.DataConfigManager:GetLocalizationConf("bp_gift_card_purchase_button") then
    unlockName = _G.DataConfigManager:GetLocalizationConf("bp_gift_card_purchase_button").msg
  end
  self.NRCText_101:SetText(unlockName)
  self.Unlock:SetVisibility(UE4.ESlateVisibility.Visible)
  local lv = bpInfo.exp_info.level or 0
  local nextLv = lv + 1
  self.Upgrade:SetVisibility(lv < battlePassConf.top_level and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if nextLv > battlePassConf.top_level then
    nextLv = battlePassConf.top_level
  end
  local nextLvlExp = self.module.data:GetNextLevelNeedExp(themId, nextLv)
  local themDes = _G.DataConfigManager:GetLocalizationConf("BP_theme_change_tips").msg
  local changTeamText = _G.DataConfigManager:GetLocalizationConf("BP_theme_change_button").msg
  local isMaxLevel = lv >= self.MaxBpLevel
  self.Text_Cass:SetText(lv)
  self.Schedule_Number:SetText(isMaxLevel and nextLvlExp or bpInfo.exp_info.exp)
  self.UpperLimit_Number:SetText("/" .. nextLvlExp)
  self.Schedule_Number_1:SetText(bpInfo.exp_info.last_week_exp)
  self.UpperLimit_Number_1:SetText("/" .. maxWeekExp)
  self:StopAnimation(self.Exp_Add)
  self.panel_expEffext:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if oldExp then
    if isMaxLevel then
      self.Schedule:SetPercent(1)
    else
      local anm = self.Exp_Add
      local anmTime = anm:GetEndTime() - anm:GetStartTime()
      if oldExp < bpInfo.exp_info.exp then
        local beginTime = anm:GetStartTime() + anmTime * (oldExp / nextLvlExp)
        local endTime = anm:GetStartTime() + anmTime * (bpInfo.exp_info.exp / nextLvlExp)
        self:PlayAnimationTimeRange(anm, beginTime, endTime)
        self.panel_expEffext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      elseif oldExp > bpInfo.exp_info.exp and bpInfo.exp_info.exp > 0 then
        local beginTime = anm:GetStartTime()
        local endTime = anm:GetStartTime() + bpInfo.exp_info.exp / nextLvlExp
        self:PlayAnimationTimeRange(anm, beginTime, endTime)
        self.panel_expEffext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      elseif oldExp > bpInfo.exp_info.exp and 0 == bpInfo.exp_info.exp then
        local beginTime = anm:GetStartTime() + anmTime * (oldExp / nextLvlExp)
        local endTime = beginTime - anm:GetEndTime() + anmTime * bpInfo.exp_info.exp / nextLvlExp
        self:PlayAnimationTimeRange(anm, beginTime, endTime)
        self.panel_expEffext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Schedule:SetPercent(bpInfo.exp_info.exp / nextLvlExp)
      end
    end
  else
    self.Schedule:SetPercent(isMaxLevel and 1 or bpInfo.exp_info.exp / nextLvlExp)
  end
  self.Hint:SetText(string.format(themDes, paid_reward_name))
  self.Change_Team:SetBtnText(changTeamText)
  self.Title1:Set_MainTitle(themName)
  self.Change_Team:SetVisibility(curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.HorizontalBox_81:SetVisibility(curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self:SetThemeRes()
end

function UMG_Pass_AwardMain_C:RefreshCommonTitle(index)
  if 0 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 1 == index and self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
end

function UMG_Pass_AwardMain_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Pass_AwardMain_C:OnRequestActiveTasks(battlePassConf)
  local bpInfo = self.module.data:GetPlayerBattlePassInfo()
  if bpInfo.task_info == nil then
    return
  end
  local taskIds = {}
  if bpInfo.task_info.daily_task_ids then
    for index, value in ipairs(bpInfo.task_info.daily_task_ids) do
      table.insert(taskIds, value)
    end
  end
  if 0 == #taskIds then
    Log.Info("\230\178\161\230\156\137\228\187\187\229\138\161")
    return
  end
  local repeatTaskIds = bpInfo.task_info.repeat_task_ids
  if repeatTaskIds then
    for index, value in ipairs(repeatTaskIds) do
      table.insert(taskIds, value)
    end
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnZoneTaskQueryReq, taskIds)
end

function UMG_Pass_AwardMain_C:GetWeekTasks(task_set_id)
  local taskConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local taskList = {}
  for i, cfg in pairs(taskConfs) do
    local parag_id = cfg.paragraph_id
    if parag_id == task_set_id then
      table.insert(taskList, cfg)
    end
  end
  return taskList
end

function UMG_Pass_AwardMain_C:OnUnDoFoldCollapsed()
  self:OnCountdown()
  self:RefreshActivityUI()
end

function UMG_Pass_AwardMain_C:RefreshActivityUI()
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local id = BattlePassInfo.battle_pass_id
  local battlePassConf = _G.DataConfigManager:GetBattlePassConf(id)
  local level_name = battlePassConf.level_name
  self.Class:SetText(level_name)
  self:OnRequestActiveTasks(battlePassConf)
end

function UMG_Pass_AwardMain_C:RefreshPresentAGiftUI()
  self.Pass_PresentAGift:RefreshUI(self.battlePassInfo)
end

function UMG_Pass_AwardMain_C:OnPetExpEffectPlayEnd()
  self.panel_expEffext:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.battlePassInfo and 0 == self.battlePassInfo.exp_info.exp then
    self.Schedule:SetPercent(0)
  end
  if self.delayPlayUpgradeInfo then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenLevelUpShowPanel, self.delayPlayUpgradeInfo.oldLv, self.delayPlayUpgradeInfo.newLv)
    self.delayPlayUpgradeInfo = nil
  end
end

function UMG_Pass_AwardMain_C:OnCloseBtn()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  local mappingContext = self:GetInputMappingContext("IMC_PassAwardMain")
  if mappingContext then
    mappingContext:UnBindAction("IA_ClosePassAwardMain")
  end
  if not self:IsAnimationPlaying(self.Page_Out) then
    self:OnClose()
    UE4Helper.SetEnableWorldRendering(true)
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  self.CloseBtn.btnClose:SetIsEnabled(false)
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_Pass_AwardMain_C:OnCloseBtn")
  _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.OnCloseAwardMain)
end

function UMG_Pass_AwardMain_C:OnSwitcherSwitcher_139(SwitcherIndex)
  self.Switcher_139:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Pass_AwardMain_C:OnSwitcherNRCSwitcher_34(SwitcherIndex)
  self.NRCSwitcher_34:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Pass_AwardMain_C:OnAnimFinished(Animation)
  if Animation == self.Page_Out then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").CLOSE
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", touchReasonType)
  elseif Animation == self.Exp_Add then
    self:OnPetExpEffectPlayEnd()
  end
end

function UMG_Pass_AwardMain_C:OnTick(deltaTime)
  if self.SpineWidget_Pink then
    self.SpineWidget_Pink:Tick(deltaTime, false)
  end
  if self.SpineWidget_Blue then
    self.SpineWidget_Blue:Tick(deltaTime, false)
  end
end

function UMG_Pass_AwardMain_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "BattlePassModule", "BattlePassAwardMain")
end

function UMG_Pass_AwardMain_C:InitGiftInfo()
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local theme_id = curPassInfo.theme_id
  local curGrade = curPassInfo.battle_pass_brief_info.gift_grade
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local gender = player.gender
  local noramlSubCouponNum, normalBagItem = self.module.data:GetSubCouponCountByTheme(theme_id, _G.Enum.BattlePassGiftGrade.BPGG_NORMAL, gender)
  local collectionSubCouponNum, collectionBagItem = self.module.data:GetSubCouponCountByTheme(theme_id, _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION, gender)
  if (noramlSubCouponNum > 0 or collectionSubCouponNum > 0) and curGrade == _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    self.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
    if normalBagItem and normalBagItem.conf and normalBagItem.conf.icon and self.MoneyIcon_2 then
      self.MoneyIcon_2:SetPath(normalBagItem.conf.icon)
    end
    if collectionBagItem and collectionBagItem.conf and collectionBagItem.conf.icon and self.MoneyIcon then
      self.MoneyIcon:SetPath(collectionBagItem.conf.icon)
    end
    if noramlSubCouponNum > 0 then
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if collectionSubCouponNum > 0 then
      self.ItemIcon_1:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ItemIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Tips:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Tips:SetText(LuaText.bp_gift_unlock_reminder)
  if noramlSubCouponNum > 0 and collectionSubCouponNum > 0 then
    self.Tips_1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Tips_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local canSwitch = self.module.data:CanSwitchTheme()
  self.Change_Team:SetVisibility(canSwitch and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Pass_AwardMain_C:OpenPassGift(passInfo)
  self:LoaderPanel("UMG_Pass_PresentAGift", passInfo)
end

function UMG_Pass_AwardMain_C:OpenPassActivity(taskId)
  self:LoaderPanel("UMG_Pass_Activity", taskId)
end

function UMG_Pass_AwardMain_C:LoaderPanel(name, arg)
  if self.LastOpenPanelName == name then
    return
  end
  self.WidgetLoader:UnLoadPanel(true)
  local widgetClass = string.format("WidgetBlueprint'/Game/NewRoco/Modules/System/BattlePass/Res/%s.%s'", name, string.format("%s_C", name))
  local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(widgetClass)
  self.WidgetLoader:SetWidgetClass(softClassPath)
  self.WidgetLoader:LoadPanel(self, arg)
  self.LastOpenPanelName = name
end

function UMG_Pass_AwardMain_C:OnLoadWidgetCallback(Panel)
  if Panel then
  end
end

function UMG_Pass_AwardMain_C:InitBPFriendUI()
  local petIcon = self.module.data:GetAnotherThemePetIcon()
  if petIcon and "" ~= petIcon then
    self.BPFriendThemeImage:SetPath(petIcon)
  end
  self:RefreshFriendButtonUI()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReqGetAnotherThemeFriends, false)
end

function UMG_Pass_AwardMain_C:OnRefreshAnotherThemeFriendUI()
  self:RefreshFriendButtonUI()
end

function UMG_Pass_AwardMain_C:RefreshFriendButtonUI()
  local count = self.module.data:GetAnotherThemeFriendCount()
  self.BPFriendThemeNum:SetText(string.safeFormat(LuaText.bp_friend_another_button, tostring(count)))
end

function UMG_Pass_AwardMain_C:OnBPFriendButtonClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Pass_AwardMain_C:OnBPFriendButtonClicked")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReqGetAnotherThemeFriends, true)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenSelectFriendPanel)
end

return UMG_Pass_AwardMain_C
