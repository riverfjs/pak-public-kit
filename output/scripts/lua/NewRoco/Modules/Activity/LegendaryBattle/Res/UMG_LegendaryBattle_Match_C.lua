local LegendaryBattleModuleEnum = require("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleEnum")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local TeamBattleModuleEnum = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_LegendaryBattle_Match_C = _G.NRCPanelBase:Extend("UMG_LegendaryBattle_Match_C")

function UMG_LegendaryBattle_Match_C:OnConstruct()
  NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  self:OnAddEventListener()
  self.TabList:SetMsgHandler({
    OnItemSelected = _G.MakeWeakFunctor(self, self.OnItemSelected)
  })
end

function UMG_LegendaryBattle_Match_C:OnActive(npcAction)
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ToggleHideNPCs, true, nil, Enum.PlayerConditionType.PCT_LEGENDARY_BATTLE_ENTRENCE)
  self:PlayAnimation(self.In)
  self.logicId = npcAction.OwnerNpc.serverData.base.logic_id
  self.actorId = npcAction:GetOwnerNPC().serverData.base.actor_id
  self.refreshContentId = npcAction.OwnerNpc.serverData.npc_base.npc_content_cfg_id
  self.seasonLegendaryCfgId = self.module:GetSeasonLegendaryID()
  local bTeam = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if not bTeam then
    if 0 == self.module.startResonanceTime then
      self.module:SetCurChooseStarNum(math.max(self.module:GetMaxStarNum(), self.module.startStarNum))
    end
  elseif 0 == self.module.startResonanceTime and (self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Waiting or self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching or self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Full) then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if visitorList and #visitorList > 0 then
      if self.module.curMatchStage ~= LegendaryBattleModuleEnum.CurStage.Matching then
        self.module:SetCurChooseStarNum(math.max(self.module:GetMaxStarNum(visitorList[1].world_lv), self.module.startStarNum))
      end
    else
      self.module:SetCurChooseStarNum(math.max(self.module:GetMaxStarNum(), self.module.startStarNum))
    end
  end
  self:SetCommonTitle()
  self:RefreshPanel()
  self:RefreshBtnUI()
  npcAction:EndAction()
end

function UMG_LegendaryBattle_Match_C:RefreshBtnUI()
  local bShowStartChallengeBtn = _G.DataConfigManager:GetGlobalConfigNumByKey("boss_fight_match_switch", 1)
  if 1 == bShowStartChallengeBtn then
    self.ChallengeBtnSwitcher:SetActiveWidgetIndex(1)
    if self.NRCSwitcher_0 then
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    end
  else
    self.ChallengeBtnSwitcher:SetActiveWidgetIndex(0)
    if self.NRCSwitcher_0 then
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    end
  end
end

function UMG_LegendaryBattle_Match_C:OnDeactive()
end

function UMG_LegendaryBattle_Match_C:OnDestruct()
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ToggleHideNPCs, false, nil, Enum.PlayerConditionType.PCT_LEGENDARY_BATTLE_ENTRENCE)
  self:OnRemoveEventListener()
  self.module:ClearCamera()
end

function UMG_LegendaryBattle_Match_C:OnReLoginUpdate()
  self.module:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
  self:UpdateMatchStage(self.module.curMatchStage)
end

function UMG_LegendaryBattle_Match_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.MiddleBtn3.btnLevelUp, self.OnConfirmBtnClick)
  self:AddButtonListener(self.BtnAbandon.btnLevelUp, self.OnAbandonReCatch)
  self:AddButtonListener(self.BtnGoOn.btnLevelUp, self.OnReCatch)
  self:AddButtonListener(self.SingleChallenge.btnLevelUp, self.OnSingleChallengeClicked)
  self:AddButtonListener(self.TeamChallenge.btnLevelUp, self.OnTeamChallengeClicked)
  self:AddButtonListener(self.StartChallenge.btnLevelUp, self.OpenConfirmHelperPopup)
  self:AddButtonListener(self.StartMatch.btnLevelUp, self.OnConfirmBtnClick)
  self:AddButtonListener(self.StartChallengeBtn.btnLevelUp, self.OnSingleChallengeClicked)
  self:AddButtonListener(self.StartChallengeBtn_1.btnLevelUp, self.OpenConfirmHelperPopup)
  NRCEventCenter:RegisterEvent("UMG_LegendaryBattle_Match_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_LegendaryBattle_Match_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnBagChange)
  self:AddButtonListener(self.DepartmentBtn, self.OnOpenPetTips)
  self:AddButtonListener(self.UMG_Details.btnLevelUp, self.OnOpenPetInfoPanel)
end

function UMG_LegendaryBattle_Match_C:OnRemoveEventListener()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnBagChange)
end

function UMG_LegendaryBattle_Match_C:OnTick(MyGeometry, InDeltaTime)
  if self.module.timeInterval > 0.9 then
    if 0 ~= self.module.matchStartTime then
      local sec = math.floor(self.module.matchTime % 60)
      local min = math.floor(self.module.matchTime / 60)
      local timeText = string.format("%d:%02d", min, sec)
      self.Text_CountDown:SetText(timeText)
    end
    if self.module.resonanceLeftTime > 0 then
      self:UpdateResonanceText()
    elseif self.module.resonanceLeftTime < 0 then
      local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      if #visitorList < 4 then
        self.module:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
      else
        self.module:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Full)
      end
      self:UpdateMatchStage(self.curMatchStage)
      self.module.resonanceLeftTime = 0
      self.module.startResonanceTime = 0
    else
      self:UpdateResonance()
    end
  end
  if 0 == self.module.matchStartTime then
    self.Text_CountDown:SetText("0:00")
  end
end

function UMG_LegendaryBattle_Match_C:OnBagChange()
  self:UpdateCoin()
end

function UMG_LegendaryBattle_Match_C:RefreshPanel()
  local costItemId1, costNum1 = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId1)
  self.MoneyIcon2:SetPath(NRCUtils:FormatConfIconPath(bagItemConf.icon, _G.UIIconPath.BagItemPath))
  local ownedItem1 = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, bagItemConf.id)
  local ownedNum1 = 0
  if nil == ownedItem1 then
    ownedNum1 = 0
  else
    ownedNum1 = ownedItem1.num
  end
  local costNum2 = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
  local costItemId2 = _G.Enum.VisualItem.VI_STAR
  local vItemsConf = _G.DataConfigManager:GetVisualItemConf(costItemId2)
  self.MoneyIcon1:SetPath(NRCUtils:FormatConfIconPath(vItemsConf.bigIcon, _G.UIIconPath.BagItemPath))
  local ownedNum2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  self.TextQuantity:SetText(costNum1)
  self.TextQuantity_1:SetText(costNum2)
  local visitors = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  local visitChangeInfo = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetVisitListChangeInfo)
  if #visitors > 0 and #visitChangeInfo > 0 then
    for i = 1, #visitors do
      for j = 1, #visitChangeInfo do
        if visitors[i].uin == visitChangeInfo[j].uin then
          visitors[i].network = visitChangeInfo[j].network
        end
      end
    end
  end
  self:UpdatePlayerList(visitors)
  self:UpdateCoin()
  local awardList = {}
  self.AwardList:InitGridView(awardList)
  self:UpdateTime()
  self:SetStarNum(self.module.curChooseStarNum)
  local battleId = self.module:GetBattleIdByStarNum(self.module.curChooseStarNum)
  self:UpdateMatchStage(self.module.curMatchStage)
  self:ShowStarList()
  local sec = math.floor(self.module.matchTime % 60)
  local min = math.floor(self.module.matchTime / 60)
  local timeText = string.format("%d:%02d", min, sec)
  self.Text_CountDown:SetText(timeText)
  local tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_text").msg
  if self.seasonLegendaryCfgId then
    local seasonLegendaryConf = _G.DataConfigManager:GetSeasonLegendaryBattleEvent(self.seasonLegendaryCfgId)
    if seasonLegendaryConf then
      tips = seasonLegendaryConf.desc
    end
  end
  self.DescribeText:SetText(tips)
end

function UMG_LegendaryBattle_Match_C:UpdateResonance()
  if 0 == self.module.startResonanceTime or self.module.resonanceLeftTime < 0 then
    local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if bVisit then
      if self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching or self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Full then
        self.BtnSwitcher:SetActiveWidgetIndex(0)
      else
        self.BtnSwitcher:SetActiveWidgetIndex(3)
      end
      self.ConsumeSwitcher:SetActiveWidgetIndex(0)
    else
      self.BtnSwitcher:SetActiveWidgetIndex(2)
      self.ConsumeSwitcher:SetActiveWidgetIndex(0)
    end
  else
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.ConsumeSwitcher:SetActiveWidgetIndex(1)
    self:UpdateResonanceText()
  end
end

function UMG_LegendaryBattle_Match_C:UpdateResonanceText()
  local hour = math.floor(self.module.resonanceLeftTime / 60 / 60)
  local min = math.floor((self.module.resonanceLeftTime - hour * 60 * 60) / 60)
  local text = string.format(_G.DataConfigManager:GetLocalizationConf("legendary_battle_text_2").msg, hour, min)
  self.ResonanceTimeText:SetText(text)
end

function UMG_LegendaryBattle_Match_C:UpdateCoin()
  local costItemId1, costNum1 = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum)
  local costItemId2 = _G.Enum.VisualItem.VI_STAR
  local starNum1 = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, costItemId1)
  local starNum2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR) or 0
  if nil == starNum1 then
    starNum1 = 0
  else
    starNum1 = starNum1.num
  end
  if self.MoneyBtn then
    local initData = {
      {
        moneyType = costItemId2,
        sum = starNum2,
        IsShowBuyIcon = true
      },
      {
        moneyType = costItemId1,
        sum = starNum1,
        IsShowBuyIcon = true,
        bLegendary = true
      }
    }
    self.MoneyBtn:InitGridView(initData)
  end
  local colorEnough = "#FFC65FFF"
  local colorRed = "#AF3A3DFF"
  local costNum2 = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
  if costNum1 > starNum1 then
    self.TextQuantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorRed))
  else
    self.TextQuantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorEnough))
  end
  if starNum2 < costNum2 then
    self.TextQuantity_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorRed))
  else
    self.TextQuantity_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorEnough))
  end
end

function UMG_LegendaryBattle_Match_C:UpdateTime()
  self.CountDownIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local curLeftChallengeTimes, totalChallengeTimes = self.module:OnCmdGetChallengeTimes()
  local text = string.format(_G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_14").msg, tostring(curLeftChallengeTimes), totalChallengeTimes)
  self.TextCountDown:SetText(text)
end

function UMG_LegendaryBattle_Match_C:SetStarNum(num)
  local RomanNum = 0
  for k, v in ipairs(self.module.RomanNumList) do
    if v.num == num then
      RomanNum = v.romanNum
      break
    end
  end
  local text = string.format(self.module.curTitle, RomanNum)
  self.TextTitle:SetText(text)
  self.Text_GradeOfDifficulty:SetText(num)
  local battleId = self.module:GetBattleIdByStarNum(self.module.curChooseStarNum)
  if nil == battleId or nil == _G.DataConfigManager:GetBattleConf(battleId) or nil == _G.DataConfigManager:GetBattleConf(battleId).npc_battle_list then
    Log.Error("npc_battle_list is nil")
    return
  end
  local monsterConfId = _G.DataConfigManager:GetBattleConf(battleId).npc_battle_list[1].pos1_1st[1]
  local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
  self.TextName:SetText(petBaseConf.name)
  local level = 0
  if monsterConf.new_level and #monsterConf.new_level > 0 then
    level = monsterConf.new_level[1]
  end
  local lvText = string.format(LuaText.umg_petskilltemple2_1, level)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local pet_top_level = 0
  local WORLD_LEVEL_CONF = _G.DataConfigManager:GetAllByName("WORLD_LEVEL_CONF")
  for index, item in ipairs(WORLD_LEVEL_CONF) do
    if item.world_level == worldLevel then
      pet_top_level = item.pet_top_level
      break
    end
  end
  self.IsReCom = level <= pet_top_level
  if level <= pet_top_level then
    self.TextClass:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
  else
    self.TextClass:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
  end
  self.TextClass:SetText(lvText)
  local attrDatas = {}
  for i = 1, #petBaseConf.unit_type do
    local petType = petBaseConf.unit_type[i]
    local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
    table.insert(attrDatas, {
      Name = typeDic.short_name,
      Path = typeDic.type_icon
    })
  end
  self.Attr:InitGridView(attrDatas)
  local rewardsTable = {}
  local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_LEGENDARY)
  if dropReward then
    for k, v in ipairs(dropReward) do
      table.insert(rewardsTable, v)
    end
  end
  local showRewards = self.module:OnCmdGetLegendaryBattleAwards(num, monsterConf.base_id)
  for k, v in ipairs(showRewards) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.itemNum = v.Count
    if v.Count > 0 then
      rewards.bShowNum = true
    else
      rewards.bShowNum = false
    end
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  self.AwardList:InitGridView(rewardsTable)
  local starList = {}
  for i = 1, num do
    table.insert(starList, i)
  end
  self.DifficultyList:InitGridView(starList)
end

function UMG_LegendaryBattle_Match_C:ShowStarList()
  local starTbl = {}
  local battleTbl = self.module.StarList
  self.startNum = self.module.startStarNum
  local RomanNum = ""
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  if visitorList and #visitorList > 0 then
    worldLevel = visitorList[1].world_lv
  end
  for i = self.startNum, self.module:GetMaxStarNum(worldLevel) do
    for k, v in ipairs(self.module.RomanNumList) do
      if v.num == i then
        RomanNum = v.romanNum
      end
    end
    table.insert(starTbl, {
      starNum = i,
      battleId = battleTbl[i],
      battleRomanNum = RomanNum
    })
  end
  self.TabList:InitList(starTbl)
  self.TabList:SelectItemByIndex(self.module.curChooseStarNum - self.startNum)
  self.TabList:ScrollToIndex(self.module.curChooseStarNum - self.startNum, true)
end

function UMG_LegendaryBattle_Match_C:OnItemSelected(Num)
  self.module:OnSetStarNum(Num)
end

function UMG_LegendaryBattle_Match_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_LegendaryBattle_Match_C:UpdatePlayerList(visitorInfo)
  local visitors
  local beastResonanceInfo = self.module.resonanceInfos
  local resonanceTotalTime = self.module.resonanceTotalTime * 60
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  if visitorInfo then
    visitors = visitorInfo
    Log.Debug("UMG_LegendaryBattle_Match_C:UpdatePlayerList1", #visitors)
  else
    visitors = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    Log.Debug("UMG_LegendaryBattle_Match_C:UpdatePlayerList2", #visitors)
  end
  local visitorList = {}
  local text1 = ""
  if self.module.curMatchStage ~= LegendaryBattleModuleEnum.CurStage.Matching then
    self.DescribeText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.DescribeText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if #visitors > 0 then
    self.DescribeText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    text1 = string.format("%s(%d/%d)", LuaText.legendary_battle_text_7, #visitors, 4)
    for i = 1, 4 do
      if i <= #visitors then
        local headId = visitors[i].card_info.card_icon_selected
        local headPath = _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetCardHeadIconByHeadId, headId)
        local state = LegendaryBattleModuleEnum.CurState.None
        if visitors[i].fighting == true then
          if visitors[i].catch_state and (visitors[i].catch_state == _G.ProtoEnum.BeastCatchState.BCS_WAITING or visitors[i].catch_state == _G.ProtoEnum.BeastCatchState.BCS_FINISH) then
            state = LegendaryBattleModuleEnum.CurState.Catching
          else
            state = LegendaryBattleModuleEnum.CurState.Fighting
          end
        elseif visitors[i].check_result.start_resonance_time and visitors[i].check_result.start_resonance_time > 0 then
          state = LegendaryBattleModuleEnum.CurState.Resonance
        elseif beastResonanceInfo and #beastResonanceInfo > 0 then
          for _, v in pairs(beastResonanceInfo) do
            if v and v.uin == visitors[i].uin then
              if v.start_resonance_time and v.start_resonance_time > 0 and v.start_resonance_time + resonanceTotalTime - curTime > 0 then
                state = LegendaryBattleModuleEnum.CurState.Resonance
              end
              break
            end
          end
        end
        local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        if myUin == visitors[i].uin then
          self.module.curState = state
        end
        table.insert(visitorList, {
          name = visitors[i].name,
          uin = visitors[i].uin,
          iconPath = headPath,
          curState = state,
          netWork = visitors[i].network
        })
      else
        local battleId = self.module:GetBattleIdByStarNum(self.module.curChooseStarNum)
        if self.module.battleId and 0 ~= self.module.battleId and battleId ~= self.module.battleId then
          self.Switcher_Matching:SetActiveWidgetIndex(1)
          self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
          table.insert(visitorList, {
            name = _G.DataConfigManager:GetLocalizationConf("legendary_battle_text_3").msg,
            uin = 0,
            iconPath = ""
          })
        elseif self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Waiting then
          table.insert(visitorList, {
            name = _G.DataConfigManager:GetLocalizationConf("legendary_battle_text_3").msg,
            uin = 0,
            iconPath = ""
          })
        else
          table.insert(visitorList, {
            name = LuaText.umg_pvp_matching_6,
            uin = 0,
            iconPath = ""
          })
        end
      end
    end
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if bOwner then
      if self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching then
        self.TabList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      elseif 0 == self.module.startResonanceTime then
        self.TabList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.TabList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      end
      self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.TabList:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if 0 == self.module.startResonanceTime then
        self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
    self.NameListPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.MatchingWarning:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DescribeText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    text1 = string.format("%s(%d/%d)", LuaText.legendary_battle_text_7, 1, 4)
    for i = 1, 4 do
      if 1 == i then
        local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
        local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        local headPath = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetCurrentUsePlayerHead)
        table.insert(visitorList, {
          name = playerName,
          uin = playerUin,
          iconPath = headPath
        })
      else
        table.insert(visitorList, {
          name = "",
          uin = 0,
          iconPath = ""
        })
      end
    end
    if self.module.curMatchStage ~= LegendaryBattleModuleEnum.CurStage.Matching then
      self.MatchingWarning:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NameListPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.DescribeText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.MatchingWarning:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NameListPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.DescribeText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if 0 == self.module.startResonanceTime then
      self.TabList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.TabList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  end
  self.Teammate_List:InitGridView(visitorList)
  self.Text_RateOfProgress:SetText(text1)
end

function UMG_LegendaryBattle_Match_C:UpdateMatchStage(stage)
  local visitors = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if stage == LegendaryBattleModuleEnum.CurStage.Full and #visitors < 4 then
    stage = LegendaryBattleModuleEnum.CurStage.Waiting
  end
  self:RefreshMatchInfo(stage)
  self:UpdateResonance()
end

function UMG_LegendaryBattle_Match_C:RefreshMatchInfo(stage)
  self.module:SetCurMatchStage(stage)
  if stage == LegendaryBattleModuleEnum.CurStage.Waiting then
    self.MiddleBtn3:SetBtnText(_G.DataConfigManager:GetLocalizationConf("legendary_battle_text_4").msg)
    self.Switcher_Matching:SetActiveWidgetIndex(1)
    self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif stage == LegendaryBattleModuleEnum.CurStage.Matching then
    self.MiddleBtn3:SetBtnText(_G.DataConfigManager:GetLocalizationConf("legendary_battle_text_5").msg)
    self.Switcher_Matching:SetActiveWidgetIndex(2)
    self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif stage == LegendaryBattleModuleEnum.CurStage.Full then
    self.MiddleBtn3:SetBtnText(_G.DataConfigManager:GetLocalizationConf("legendary_battle_text_6").msg)
    self.Switcher_Matching:SetActiveWidgetIndex(0)
    self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.module.matchStartTime = 0
  end
  self:UpdatePlayerList(nil)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLegendaryMatchState, stage, self.module.curShowBattleId, self.curShowStarNum, self.module.matchTime)
end

function UMG_LegendaryBattle_Match_C:OnSortBtnClick()
  self.module:OnOpenStarSortTip()
end

function UMG_LegendaryBattle_Match_C:OnCloseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_LegendaryBattle_Match_C:OnCloseBtnClick")
  self:PlayAnimation(self.Out)
end

function UMG_LegendaryBattle_Match_C:OnAbandonReCatch()
  local tickName = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetTicketName)
  local title = LuaText.team_battle_text_3
  local des = string.format(LuaText.legendary_battle_tips_4, tickName or "")
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.legendary_battle_text_9, LuaText.umg_plane_teamitem_3):SetClickAnywhereClose(true):SetCallback(self, self.OnAbandon):SetCloseOnCancel(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_LegendaryBattle_Match_C:OnAbandon(bOk)
  if bOk then
    self.module:OnZoneQuitBeastCatchReq(self.actorId, self.logicId)
  end
end

function UMG_LegendaryBattle_Match_C:OnReCatch()
  self.module:OnZoneReentrantBeastCatchReq(self.actorId, self.logicId)
end

function UMG_LegendaryBattle_Match_C:OnDialogSingleChallengeClicked()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryBattleSingleChallengeClick)
  local star = self.module.curChooseStarNum
  local battle = self.module:GetBattleIdByStarNum(star)
  local logicId = self.logicId
  local actorId = self.actorId
  local enterCondition = _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CheckEnterCondition, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE)
  local bOpenConfirm, tips = self.module:CheckCanStartLegendaryBattle(enterCondition)
  if true == bOpenConfirm then
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SendZoneTeamBattleChallengeReq, actorId, logicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE, {battleId = battle, starNum = star})
  else
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.OpenPreWarConfirm, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE, {
      actorId = actorId,
      logicId = logicId,
      battleId = battle,
      starNum = star
    }, tips)
  end
end

function UMG_LegendaryBattle_Match_C:OnSingleChallengeClicked()
  if self.IsReCom then
  else
    local title = LuaText.TIPS
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(LuaText.magicmanual_challenge_trace_confirm02):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnDialogSingleChallengeClicked):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    return
  end
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryBattleSingleChallengeClick)
  _G.NRCAudioManager:PlaySound2DAuto(1220002091, "UMG_LegendaryBattle_Match_C:OnConfirmBtnClick")
  local star = self.module.curChooseStarNum
  local battle = self.module:GetBattleIdByStarNum(star)
  local logicId = self.logicId
  local actorId = self.actorId
  local enterCondition = _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CheckEnterCondition, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE)
  local bOpenConfirm, tips = self.module:CheckCanStartLegendaryBattle(enterCondition)
  if true == bOpenConfirm then
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SendZoneTeamBattleChallengeReq, actorId, logicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE, {battleId = battle, starNum = star})
  else
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.OpenPreWarConfirm, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE, {
      actorId = actorId,
      logicId = logicId,
      battleId = battle,
      starNum = star
    }, tips)
  end
end

function UMG_LegendaryBattle_Match_C:OnTeamChallengeClicked()
  if self.IsReCom then
  else
    local title = LuaText.TIPS
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(LuaText.magicmanual_challenge_trace_confirm02):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnConfirmBtnClick):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    return
  end
  self:OnConfirmBtnClick()
end

function UMG_LegendaryBattle_Match_C:OpenConfirmHelperPopup()
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryBattleConfirmHelpClick)
  local Context = DialogContext()
  local content = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_16").msg
  Context:SetContent(content):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnStartChallengeClicked):SetClickAnywhereClose(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_LegendaryBattle_Match_C:OnStartChallengeClicked(result)
  if true == result then
    local enterCondition = _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CheckEnterCondition, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST)
    local bOpenConfirm, tips = self.module:CheckCanStartLegendaryBattle(enterCondition)
    local star = self.module.curChooseStarNum
    local battle = self.module:GetBattleIdByStarNum(star)
    local logicId = self.logicId
    local actorId = self.actorId
    _G.NRCAudioManager:PlaySound2DAuto(1220002091, "UMG_LegendaryBattle_Match_C:OnConfirmBtnClick")
    if true == bOpenConfirm then
      _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SendZoneTeamBattleChallengeReq, actorId, logicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST, {battleId = battle, starNum = star})
    else
      _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.OpenPreWarConfirm, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST, {
        actorId = actorId,
        logicId = logicId,
        battleId = battle,
        starNum = star,
        bMatch = false
      }, tips)
    end
  end
end

function UMG_LegendaryBattle_Match_C:OnConfirmBtnClick()
  local enterCondition = _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CheckEnterCondition, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST)
  local bOpenConfirm, tips = self.module:CheckCanStartLegendaryBattle(enterCondition)
  local star = self.module.curChooseStarNum
  local battle = self.module:GetBattleIdByStarNum(star)
  local logicId = self.logicId
  local actorId = self.actorId
  if self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Waiting then
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_LegendaryBattle_Match_C:OnConfirmBtnClick")
    if false == bOpenConfirm then
      _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.OpenPreWarConfirm, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST, {
        actorId = actorId,
        logicId = logicId,
        battleId = battle,
        starNum = star,
        bMatch = true
      }, tips)
    else
      self:StartOrCancelMatch(true)
    end
  elseif self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching then
    self.module:OnZoneBeastCancelMatchReq()
  elseif self.module.curMatchStage == LegendaryBattleModuleEnum.CurStage.Full then
    _G.NRCAudioManager:PlaySound2DAuto(1220002091, "UMG_LegendaryBattle_Match_C:OnConfirmBtnClick")
    if true == bOpenConfirm then
      _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SendZoneTeamBattleChallengeReq, actorId, logicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST, {battleId = battle, starNum = star})
    else
      _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.OpenPreWarConfirm, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST, {
        actorId = actorId,
        logicId = logicId,
        battleId = battle,
        starNum = star
      }, tips)
    end
  end
end

function UMG_LegendaryBattle_Match_C:StartOrCancelMatch(bStart)
  if bStart then
    local starNum = self.module.curChooseStarNum
    local battleId = self.module:GetBattleIdByStarNum(starNum)
    self.module:OnSendZoneBeastStartMatchReq(battleId, starNum)
  end
end

function UMG_LegendaryBattle_Match_C:GetHeadIconById(Id)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Id = Id or player.gender
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon"
  if Id > 0 then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(Id)
    local HeadIconPath = ""
    if CardIconConf then
      HeadIconPath = CardIconConf.icon_resource_path
      return string.format("%s%s.%s'", path, HeadIconPath, HeadIconPath)
    else
      return ""
    end
  else
    return ""
  end
end

function UMG_LegendaryBattle_Match_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoClose()
  end
end

function UMG_LegendaryBattle_Match_C:OnOpenPetTips()
  local battleId = self.module:GetBattleIdByStarNum(self.module.curChooseStarNum)
  local battleConf = _G.DataConfigManager:GetBattleConf(battleId)
  if battleConf then
    local battleList = battleConf.npc_battle_list
    if battleList and battleList[1] then
      local posList = battleList[1].pos1_1st
      if posList and posList[1] then
        local monsterConfId = posList[1]
        local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
        if monsterConf then
          local level = 0
          if monsterConf.new_level and #monsterConf.new_level > 0 then
            level = monsterConf.new_level[1]
          end
          local infoData = {
            petBaseId = monsterConf.base_id,
            level = level,
            bForceShowType = true
          }
          _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm3, infoData, nil, false, false, {isShowPetTips = true})
        end
      end
    end
  end
end

function UMG_LegendaryBattle_Match_C:OnOpenPetInfoPanel()
  local battleId = self.module:GetBattleIdByStarNum(self.module.curChooseStarNum)
  local battleConf = _G.DataConfigManager:GetBattleConf(battleId)
  if battleConf then
    local battleList = battleConf.npc_battle_list
    if battleList and battleList[1] then
      local posList = battleList[1].pos1_1st
      if posList and posList[1] then
        local monsterConfId = posList[1]
        local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
        if monsterConf then
          _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, monsterConf.base_id, true)
        end
      end
    end
  end
end

return UMG_LegendaryBattle_Match_C
