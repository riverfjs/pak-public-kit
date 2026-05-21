local UMG_ChallengeSubPanel_C = _G.NRCPanelBase:Extend("UMG_ChallengeSubPanel_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")

function UMG_ChallengeSubPanel_C:OnEnable(module)
  self.module = module
  self.data = self.module.data
  self.needDelay = true
  local challengeTabList = {
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_flowerseed_png.img_flowerseed_png'",
      Sort = self.data.ChallengeTaskType.XiShou,
      open = true,
      TaskTypeName = _G.DataConfigManager:GetLocalizationConf("magicmanualmoduledata_2").msg,
      TabType = 1
    },
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_Petboss_png.img_Petboss_png'",
      Sort = self.data.ChallengeTaskType.Boss,
      open = true,
      TaskTypeName = _G.DataConfigManager:GetLocalizationConf("magicmanualmoduledata_3").msg,
      TabType = 1
    },
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_chuanshuojingling_png.img_chuanshuojingling_png'",
      Sort = self.data.ChallengeTaskType.Legend,
      open = true,
      TaskTypeName = LuaText.rare_pet_release_tips_8,
      TabType = 1
    }
  }
  self.challengeTabList = challengeTabList
  self.TabList1:InitGridView(challengeTabList)
  if self.module.SubTableIndex > -1 and self.module.SubTableIndex < #challengeTabList then
    self:SelectTabBySubTabIndex(self.module.SubTableIndex)
    self.module.SubTableIndex = -1
  elseif (self.module.ChildTableIndex or 0) > 0 then
    self:SelectTabBySubTabIndex(self.module.ChildTableIndex)
    self.module.ChildTableIndex = 0
  else
    self.TabList1:SelectItemByIndex(0)
  end
  self:UpdateHealth()
  self:PlayAnimation(self.Change)
  self:OnAddEventListener()
  self:InitSeasonTalentWidgets()
  self.SeasonalSystemBtn.RedDot:SetupKey(486)
end

function UMG_ChallengeSubPanel_C:SelectTabBySubTabIndex(TabIndex)
  if self.challengeTabList and #self.challengeTabList > 0 then
    local index = 0
    for i, v in ipairs(self.challengeTabList) do
      if v.Sort == TabIndex then
        index = i - 1
      end
    end
    self.TabList1:SelectItemByIndex(index)
  end
end

function UMG_ChallengeSubPanel_C:OnRefreshChallengeUI(tabIndex, Sort, tableName)
  if Sort == self.data.ChallengeTaskType.Boss then
    self:RequestChallengeBossDatas()
    self.module:LeaveChallengeStopTick()
    self:ShowStarBones()
  elseif Sort == self.data.ChallengeTaskType.XiShou then
    self.module:LeaveChallengeBossStopTick()
    self:RequestChallengeXiShouDatas()
    self:ShowStarBones()
  elseif Sort == self.data.ChallengeTaskType.Legend then
    self.module:LeaveChallengeStopTick()
    self.module:LeaveChallengeBossStopTick()
    self:RequestLegendPetDatas()
    self:ShowHeTerOnuClearStarChain()
  end
end

function UMG_ChallengeSubPanel_C:UpdateBossView()
  local index = self.TabList1:GetSelectedIndex()
  if index + 1 ~= self.data.ChallengeTaskType.Boss then
    Log.Error("UMG_ChallengeSubPanel_C:UpdateBossView index is not boss:", index)
    return
  end
  self.FlowerSeedChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SeasonalSystemBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:CancelDelay()
  
  local function delayFunction()
    self.Button_Detail:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_60:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local list = self.data.BossList
    list = list or {}
    if #list > 0 then
      self.EmptyText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.EmptyText:SetText(_G.DataConfigManager:GetLocalizationConf("magicmanual_no_boss").msg)
      self.EmptyText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    for i = 1, #list do
      list[i].dataType = 2
    end
    if self.ChallengeScrollView:CheckCanUseCacheData() then
      self.ChallengeScrollView:InitList(list, true)
      self.ChallengeScrollView:CreatePanelFromCache()
    else
      self.ChallengeScrollView:InitList(list)
    end
    self.ChallengeScrollView:ScrollToStart()
    self.Switcher_quantity:SetActiveWidgetIndex(0)
    local needTick = false
    for i = 1, #list do
      if list[i].data and list[i].data.next_refresh_time and list[i].data.next_refresh_time - _G.ZoneServer:GetServerTime() / 1000 >= 0 then
        needTick = true
      end
      local item = self.ChallengeScrollView:GetItemByIndex(i - 1)
      if item then
        item.Switcher:SetActiveWidgetIndex(1)
        if 1 == i then
          item:PlayAnimation(item.In)
        else
          self:DelaySeconds(0.03 * (i - 1), function()
            item:PlayAnimation(item.In)
          end)
        end
      end
    end
    self:DelaySeconds(0.8, function()
      self.module:ShowMainPanel()
    end)
    if needTick then
      self.module:NeedBossItemsTick()
    end
  end
  
  if self.needDelay then
    self:DelayFrames(1, delayFunction)
    self.needDelay = false
  else
    delayFunction()
  end
end

function UMG_ChallengeSubPanel_C:RefreshChallengeItemBtn(RefreshId, next_npc_refresh_time)
  local ChallengeScrollView = self.ChallengeScrollView
  if self.FlowerSeedChallengeScrollView:GetVisibility() == UE4.ESlateVisibility.Visible then
    ChallengeScrollView = self.FlowerSeedChallengeScrollView
  end
  local ItemNum = ChallengeScrollView:GetTotalItemNumber()
  if next_npc_refresh_time then
    for i = 1, ItemNum do
      local item = ChallengeScrollView:GetItemByIndex(i - 1)
      if item and item.DataType == item.ChallengeType.BossData and item.BossData.content_cfg_id == RefreshId then
        item.BossData.next_refresh_time = next_npc_refresh_time
        item:SetBossDataInfo()
      end
    end
    self.module.NeedBossItemTick = true
  else
    for i = 1, ItemNum do
      local item = ChallengeScrollView:GetItemByIndex(i - 1)
      if item and item.DataType == item.ChallengeType.FlowerData and not item.FlowerData.is_camp_unlock then
        if item.FlowerData.content_cfg_id ~= RefreshId then
          item.Btn:SetBtnText(LuaText.head_to)
        else
          item.Btn:SetBtnText(LuaText.head_to_cancel)
        end
      end
      if item and item.DataType == item.ChallengeType.BossData and not item.BossData.is_camp_unlock then
        if item.BossData.content_cfg_id ~= RefreshId then
          item.Btn:SetBtnText(LuaText.head_to)
        else
          item.Btn:SetBtnText(LuaText.head_to_cancel)
        end
      end
      if item and item.DataType == item.ChallengeType.LegendData and not item.LegendData.is_camp_unlock then
        if item.LegendData.content_cfg_id ~= RefreshId then
          item.Btn:SetBtnText(LuaText.head_to)
        else
          item.Btn:SetBtnText(LuaText.head_to_cancel)
        end
      end
    end
  end
end

function UMG_ChallengeSubPanel_C:UpdateLegendPetView()
  self.FlowerSeedChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SeasonalSystemBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:CancelDelay()
  
  local function delayFunction()
    self.Button_Detail:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_60:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_quantity:SetActiveWidgetIndex(0)
    local text = ""
    local MaxTime = _G.DataConfigManager:GetLegendaryGlobalConfig("weekly_star_limit").num or 0
    if self.data.LegendChallengeNum > 0 then
      text = string.format("<LegendNormal>%d</>/%d", self.data.LegendChallengeNum, MaxTime)
    else
      text = string.format("<LegendRed>%d</>/%d", self.data.LegendChallengeNum, MaxTime)
    end
    self.TextQuantity:SetText(text)
    local refreshTime = self.data.LegendRemainTime - _G.ZoneServer:GetServerTime() / 1000
    local day = math.floor(refreshTime / 86400)
    local hour = math.floor((refreshTime - day * 86400) / 3600)
    local min = math.floor((refreshTime - day * 86400 - hour * 3600) / 60)
    local TimeText = 0
    if day > 0 then
      TimeText = string.format(LuaText.activity_RTS1, day, hour)
    else
      TimeText = string.format(LuaText.magicmanual_challenge_countdown01, hour, min)
    end
    self.Text_time:SetText(TimeText)
    local list = self.data.LegendList
    list = list or {}
    for i = 1, #list do
      list[i].dataType = 3
    end
    if self.ChallengeScrollView:CheckCanUseCacheData() then
      self.ChallengeScrollView:InitList(list, true)
      self.ChallengeScrollView:CreatePanelFromCache()
    else
      self.ChallengeScrollView:InitList(list)
    end
    self.ExclusiveMarkBtn:InitGridView(list)
    if #list > 0 then
      self.SeasonalSystemBtn_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:ShowHeTerOnuClearStarChain()
    self.ChallengeScrollView:ScrollToStart()
    if list and #list > 0 then
      self.Text_time:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      for i = 1, #list do
        local item = self.ChallengeScrollView:GetItemByIndex(i - 1)
        if item then
          item.Switcher:SetActiveWidgetIndex(1)
          if 1 == i then
            item:PlayAnimation(item.In)
          else
            self:DelaySeconds(0.03 * (i - 1), function()
              item:PlayAnimation(item.In)
            end)
          end
        end
      end
      self.EmptyText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.EmptyText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.EmptyText:SetText(LuaText.legendary_battle_tips_18)
      self.Text_time:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:DelaySeconds(0.8, function()
      self.module:ShowMainPanel()
    end)
  end
  
  if self.needDelay then
    self:DelayFrames(1, delayFunction)
    self.needDelay = false
  else
    delayFunction()
  end
end

function UMG_ChallengeSubPanel_C:GetLegendaryTicketList(list)
  local ticketList = {}
  local costItemId1 = _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num
  for _, v in pairs(list or {}) do
    if v and v.content_cfg_id then
      local costItemId, _ = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, v.content_cfg_id, true)
      if costItemId1 ~= costItemId then
        table.insertUnique(ticketList, costItemId)
      end
    end
  end
  return ticketList
end

function UMG_ChallengeSubPanel_C:BossItemsTick()
  local list = self.data.BossList
  local needTick = false
  for i = 1, #list do
    if list[i].data and list[i].data.next_refresh_time and list[i].data.next_refresh_time - _G.ZoneServer:GetServerTime() / 1000 >= 0 then
      needTick = true
    end
    local item = self.ChallengeScrollView:GetItemByIndex(i - 1)
    if item and item.needTick then
      item:RefreshTimeTick()
    end
  end
  if not needTick then
    self.module:LeaveChallengeBossStopTick()
  end
end

function UMG_ChallengeSubPanel_C:UpdateShinyFlowerInfo()
  for i = 0, self.TabList1:GetItemCount() - 1 do
    local TabItem = self.TabList1:GetItemByIndex(i)
    if TabItem and TabItem.data and TabItem.data.Sort == self.data.ChallengeTaskType.XiShou then
      local bEnable = NRCModuleManager:DoCmd(MagicManualModuleCmd.HasDoubleTeamBattleReward)
      TabItem:UpdateDoubleTeamBattleFlag(bEnable)
      break
    end
  end
  local Activity = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetOpeningShinyActivity)
  if Activity then
    self.CanvasPanel_60:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_quantity:SetActiveWidgetIndex(1)
    local Info = Activity:GetPlayerShinyPetDayInfo()
    local Total = Info and Info.total_double_times or 0
    local Remain = Info and Info.remaining_doule_times or 0
    self.TextQuantity_1:SetText(string.format("%s/%s", Remain, Total))
  else
    self.CanvasPanel_60:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ChallengeSubPanel_C:UpdateFlowerView(UpdateTime)
  local ChallengeScrollView
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    ChallengeScrollView = self.FlowerSeedChallengeScrollView
    self.FlowerSeedChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    ChallengeScrollView = self.ChallengeScrollView
    self.FlowerSeedChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.SeasonalSystemBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.data.XiShouRemainTime and self.data.XiShouRemainTime > 0 then
    local refreshTime = self.data.XiShouRemainTime - _G.ZoneServer:GetServerTime() / 1000
    local day = math.floor(refreshTime / 86400)
    local hour = math.floor((refreshTime - day * 86400) / 3600)
    local min = math.floor((refreshTime - day * 86400 - hour * 3600) / 60)
    local text = 0
    if day > 0 then
      text = string.format(LuaText.activity_RTS1, day, hour)
    else
      text = string.format(LuaText.magicmanual_challenge_countdown01, hour, min)
    end
    local list = self.data.XiShouFlowerList
    list = list or {}
    for i = 1, #list do
      if list[i].end_timestamp then
        local item = ChallengeScrollView:GetItemByIndex(i - 1)
        if item then
          item:SetActivityFlowerUpDateTime()
        end
      end
    end
  end
  if not UpdateTime then
    self:CancelDelay()
    
    local function delayFunction()
      local list = self.data.XiShouFlowerList
      list = list or {}
      if #list > 0 then
        self.EmptyText:SetVisibility(UE4.ESlateVisibility.Collapsed)
        ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.EmptyText:SetText(_G.DataConfigManager:GetLocalizationConf("all_flower_clear").msg)
        self.EmptyText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      for i = 1, #list do
        list[i].dataType = 1
      end
      if ChallengeScrollView:CheckCanUseCacheData() then
        ChallengeScrollView:InitList(list, true)
        ChallengeScrollView:CreatePanelFromCache()
      else
        ChallengeScrollView:InitList(list)
      end
      ChallengeScrollView:ScrollToStart()
      self:UpdateShinyFlowerInfo()
      for i = 1, #list do
        local item = ChallengeScrollView:GetItemByIndex(i - 1)
        if item then
          if item.Switcher then
            item.Switcher:SetActiveWidgetIndex(0)
          end
          if 1 == i then
            item:PlayAnimation(item.In)
          else
            self:DelaySeconds(0.03 * (i - 1), function()
              item:PlayAnimation(item.In)
            end)
          end
        end
      end
      self.module:ShowMainPanel()
    end
    
    if self.needDelay then
      self:DelayFrames(2, delayFunction)
      self.needDelay = false
      ChallengeScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      delayFunction()
    end
  end
end

function UMG_ChallengeSubPanel_C:RequestChallengeBossDatas()
  if self.module then
    self.module:GetBossData()
  end
end

function UMG_ChallengeSubPanel_C:RequestChallengeXiShouDatas()
  if self.module then
    self.module:GetFlowerData()
  end
end

function UMG_ChallengeSubPanel_C:RequestLegendPetDatas()
  if self.module then
    self.module:GetLegendPetDatas()
  end
end

function UMG_ChallengeSubPanel_C:UpdateHealth()
  if self.module and self.module.SubTableIndex > -1 then
    if self.module.SubTableIndex + 1 == self.data.ChallengeTaskType.Boss then
      self:ShowStarBones()
    elseif self.module.SubTableIndex + 1 == self.data.ChallengeTaskType.XiShou then
      self:ShowStarBones()
    elseif self.module.SubTableIndex + 1 == self.data.ChallengeTaskType.Legend then
      self:ShowHeTerOnuClearStarChain()
    end
    local ChallengeScrollView = self.ChallengeScrollView
    if self.FlowerSeedChallengeScrollView:GetVisibility() == UE4.ESlateVisibility.Visible then
      ChallengeScrollView = self.FlowerSeedChallengeScrollView
    end
    local Num = ChallengeScrollView:GetTotalItemNumber()
    for i = 1, Num do
      local item = ChallengeScrollView:GetItemByIndex(i - 1)
      if item then
        item:OnUpdateStarNum()
      end
    end
  end
end

function UMG_ChallengeSubPanel_C:ShowHeTerOnuClearStarChain()
  local list = self.data.LegendList
  local ticketList = self:GetLegendaryTicketList(list)
  local costItemId1 = _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num
  local starNum1 = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, costItemId1)
  if nil == starNum1 then
    starNum1 = 0
  else
    starNum1 = starNum1.num
  end
  local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local staminaB = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StaminaProportionB = string.format("%s%s%s", StarNum, "/", staminaB.num)
  local MoneyList = {
    {
      moneyType = _G.Enum.VisualItem.VI_STAR,
      sum = StaminaProportionB,
      IsShowBuyIcon = true
    }
  }
  self.MoneyBtn:InitGridView(MoneyList)
end

function UMG_ChallengeSubPanel_C:ShowStarBones()
  local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
  StarDebrisNum = StarDebrisNum or 0
  local staminaA = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit")
  local StaminaProportionA = ""
  local ShowColor = UE4.UNRCStatics.HexToSlateColor("F4EEE1FF")
  if StarDebrisNum >= staminaA.num then
    ShowColor = UE4.UNRCStatics.HexToSlateColor("FFC65FFF")
    StaminaProportionA = string.format("%s", StarDebrisNum)
  elseif StarDebrisNum >= 0 and StarDebrisNum < staminaA.num then
    StaminaProportionA = string.format("%s", StarDebrisNum)
  end
  local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local staminaB = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StaminaProportionB = string.format("%s%s%s", StarNum, "/", staminaB.num)
  local MoneyList = {
    {
      moneyType = _G.Enum.VisualItem.VI_STAR,
      sum = StaminaProportionB,
      IsShowBuyIcon = true
    },
    {
      moneyType = _G.Enum.VisualItem.VI_STAR_DEBRIS,
      sum = StaminaProportionA,
      IsShowBuyIcon = true,
      ShowColor = ShowColor
    }
  }
  self.MoneyBtn:InitGridView(MoneyList)
  if StarDebrisNum >= staminaA.num then
    self.MoneyBtn:GetItemByIndex(1).Full:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif StarDebrisNum >= 0 and StarDebrisNum < staminaA.num then
    self.MoneyBtn:GetItemByIndex(1).Full:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ChallengeSubPanel_C:OnDisable()
  self:CancelDelay()
  self:OnRemoveEventListener()
end

function UMG_ChallengeSubPanel_C:OnRemoveEventListener()
  self.IsAddButtonListener = false
  self:RemoveButtonListener(self.Button_Detail.btnLevelUp)
  self:RemoveButtonListener(self.SeasonalSystemBtn.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, PVEModuleEvent.TalentNodeUnlockCntChange, self.OnTalentNodeUnlockCntChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnMagicManualMainPanelTouchEnded, self.OnMagicManualMainPanelTouchEnded)
end

function UMG_ChallengeSubPanel_C:OnClickRefreshFlowerTips()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentText = _G.DataConfigManager:GetLocalizationConf("magicmanualmodule2tips_content").msg
  local ContentTitle = _G.DataConfigManager:GetLocalizationConf("magicmanualmodule2tips_title").msg
  if 3 == self.module.SubTableIndex + 1 then
    ContentText = LuaText.legendary_battle_list_text
    ContentTitle = LuaText.legendary_battle_list_title
  end
  Context:SetTitle(ContentTitle):SetContent(ContentText):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_ChallengeSubPanel_C:OnAddEventListener()
  if self.IsAddButtonListener then
    return
  end
  self.IsAddButtonListener = true
  self:AddButtonListener(self.Button_Detail.btnLevelUp, self.OnClickRefreshFlowerTips)
  self:AddButtonListener(self.SeasonalSystemBtn.btnLevelUp, self.OnClickSeasonalSystemBtn)
  self:AddButtonListener(self.SeasonalSystemBtn_1.btnLevelUp, self.OnClickSeasonalSystemBtn_1)
  _G.NRCEventCenter:RegisterEvent("UMG_ChallengeSubPanel_C", self, PVEModuleEvent.TalentNodeUnlockCntChange, self.OnTalentNodeUnlockCntChange)
  _G.NRCEventCenter:RegisterEvent("UMG_ChallengeSubPanel_C", self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:RegisterEvent("UMG_ChallengeSubPanel_C", self, MagicManualModuleEvent.OnMagicManualMainPanelTouchEnded, self.OnMagicManualMainPanelTouchEnded)
end

function UMG_ChallengeSubPanel_C:InitSeasonTalentWidgets()
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  if not seasonInfo then
    self.SeasonTalentRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local isCurSeasonOpenTalent = _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.IsCurSeasonOpenTalent)
  if not isCurSeasonOpenTalent then
    self.SeasonTalentRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_GET_SEASON_TALENT_POINT_REQ, {})
  self.SeasonTalentRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:UpdateSeasonalSystemText()
end

function UMG_ChallengeSubPanel_C:OnClickSeasonalSystemBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ChallengeSubPanel_C:OnClickSeasonalSystemBtn")
  _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.OpenPveTalentPanel)
end

function UMG_ChallengeSubPanel_C:OnTalentNodeUnlockCntChange(unlockCnt, totalCnt)
  self:UpdateSeasonalSystemText(unlockCnt, totalCnt)
end

function UMG_ChallengeSubPanel_C:OnSeasonInfoChange()
  self:InitSeasonTalentWidgets()
end

function UMG_ChallengeSubPanel_C:UpdateSeasonalSystemText(unlockCnt, totalCnt)
  if not unlockCnt or not totalCnt then
    unlockCnt, totalCnt = _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.GetTalentUnlockNodeNum)
  end
  local text = string.format("%d/%d", unlockCnt or 0, totalCnt or 0)
  self.SeasonalSystemText:SetText(text)
end

function UMG_ChallengeSubPanel_C:OnClickSeasonalSystemBtn_1()
  local bShow = self.ExclusiveMarkList:GetVisibility() == UE4.ESlateVisibility.Collapsed and true or false
  self:SetExclusiveMarkingListShow(bShow)
end

function UMG_ChallengeSubPanel_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self:SetExclusiveMarkingListShow(false)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_ChallengeSubPanel_C:OnMagicManualMainPanelTouchEnded()
  self:SetExclusiveMarkingListShow(false)
end

function UMG_ChallengeSubPanel_C:SetExclusiveMarkingListShow(bShow)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  local bCurShow = self.ExclusiveMarkList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible and true or false
  if bCurShow == bShow then
    return
  end
  self:StopAllAnimations()
  if bShow then
    self:PlayAnimation(self.Pop_In)
    self.ExclusiveMarkList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:PlayAnimation(self.Pop_Out)
    self.ExclusiveMarkList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_ChallengeSubPanel_C
