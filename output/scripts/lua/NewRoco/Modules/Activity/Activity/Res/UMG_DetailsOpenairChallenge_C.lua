local UMG_DetailsOpenairChallenge_C = _G.NRCPanelBase:Extend("UMG_DetailsOpenairChallenge_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_DetailsOpenairChallenge_C:OnConstruct()
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.ExplanationBtn.btnLevelUp, self.OnClickExplanationBtn)
  self:AddButtonListener(self.Btn_Challenge.btnLevelUp, self.OnClickChallengeBtn)
  self.Btn_Lock:SetTitleTextAndIcon()
end

function UMG_DetailsOpenairChallenge_C:SetTitle(cfg)
  self.Title:Set_MainTitle(cfg and cfg.title)
  self.Title:SetBg(cfg and cfg.head_icon)
  self.Title:SetSubtitle(cfg and cfg.subtitle)
end

function UMG_DetailsOpenairChallenge_C:OnDestruct()
  local action = self.action
  if action then
    local battleId = self.confirmChoose and self.selectItem and self.selectItem.difficult_id
    if battleId then
      action:Finish(true, nil, tostring(battleId))
    else
      action:Finish(true)
    end
  end
end

function UMG_DetailsOpenairChallenge_C:OnActive(cfg, action)
  self.cfg = cfg
  self.action = action
  self.bg1:SetPath(cfg.bg)
  self.ImageBadge:SetPath(cfg.bg_icon)
  self:SetTitle(cfg)
  local challengeHandler = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetNpcChallengeHandler)
  local challengeObject = challengeHandler and challengeHandler:GetOrAddChallengeItem(cfg.id) or nil
  local clickCallback = _G.MakeWeakFunctor(self, self.OnSelectTab)
  if action and challengeObject then
    local actionParams = action.Info and action.Info.begin_act_params
    if actionParams then
      local battleUiId = actionParams[1]
      if battleUiId == cfg.id then
        for idx = 2, #actionParams do
          challengeObject:SetBattleFinished(actionParams[idx])
        end
      end
    end
  end
  local tabItems = {}
  for _, v in ipairs(cfg.difficult_group or {}) do
    local item = {}
    item.tabName = v.tab_name
    item.clickCallback = clickCallback
    item.cfg = v
    item.finished = challengeObject and challengeObject:IsBattleFinished(v.difficult_id) or false
    table.insert(tabItems, item)
  end
  for index, item in ipairs(tabItems) do
    if item.cfg.condition == Enum.SpecialBattleLevelUnlockType.SBLUT_NONE then
      item.unlocked = true
    elseif item.cfg.condition == Enum.SpecialBattleLevelUnlockType.SBLUT_STEP then
      local preFinished = false
      if index > 1 then
        preFinished = tabItems[index - 1].finished
      end
      item.unlocked = preFinished
    end
  end
  self.TabList:InitList(tabItems)
  local defaultSelectTab = 0
  for index, item in ipairs(tabItems) do
    if not item.finished and item.unlocked then
      defaultSelectTab = index - 1
      break
    end
  end
  self.TabList:SelectItemByIndex(defaultSelectTab)
end

function UMG_DetailsOpenairChallenge_C:OnSelectTab(item)
  if not item or not item.cfg then
    return
  end
  local itemCfg = item.cfg
  self.selectItem = item.cfg
  self.TextTitle:SetText(itemCfg.name)
  self.Btn_Lock:SetBtnText(itemCfg.lock_tips)
  self.DescribeText:SetText(itemCfg.des)
  local worldLevelCfg = _G.DataConfigManager:GetWorldLevelConf(itemCfg.recommend_world_level + 1, true)
  if worldLevelCfg then
    local levelTips = _G.LuaText.NPC_BattleUI_recommend_WorldLevel
    local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    if worldLevel < itemCfg.recommend_world_level then
      levelTips = string.SafeGsub(levelTips, "%%s", "<span color=\"#CF303E\">%s</>")
    end
    self.TextRecommendedStarRating:SetText(string.format(levelTips, worldLevelCfg.title))
  else
    self.TextRecommendedStarRating:SetText("")
  end
  local attrIcons = {}
  local petAttrTable = ActivityUtils.CreatePetCommonAttrListData(itemCfg.recommend)
  for _, v in ipairs(petAttrTable) do
    table.insert(attrIcons, v.Path)
  end
  self.Attr_1:InitGridView(attrIcons)
  if #attrIcons > 0 then
    self.CanvasDepartment:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasDepartment:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local rewardItems = {}
  local rewardCfg = _G.DataConfigManager:GetRewardConf(itemCfg.first_reward, true)
  if rewardCfg then
    for _, v in ipairs(rewardCfg.RewardItem) do
      local itemData = {}
      itemData.itemType = v.Type
      itemData.itemId = v.Id
      itemData.itemNum = v.Count
      itemData.bShowNum = true
      itemData.bShowTip = true
      itemData.bShowGetTag = item.finished
      table.insert(rewardItems, itemData)
    end
  end
  self.AwardList:InitGridView(rewardItems)
  if #rewardItems > 0 then
    self.CanvasPanel_781:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.AwardList:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.CanvasPanel_781:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AwardList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if item.finished then
    if itemCfg.is_loop then
      self.BtnSwitcher:SetActiveWidgetIndex(0)
    else
      self.BtnSwitcher:SetActiveWidgetIndex(2)
    end
  elseif item.unlocked then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  end
  self:PlayAnimation(self.Change)
end

function UMG_DetailsOpenairChallenge_C:OnClickChallengeBtn()
  self.confirmChoose = true
  self:OnClickCloseBtn()
end

function UMG_DetailsOpenairChallenge_C:OnClickCloseBtn()
  self:OnClose()
end

function UMG_DetailsOpenairChallenge_C:OnClickExplanationBtn()
  local cfg = self.cfg
  if not cfg then
    return
  end
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(_G.LuaText.activity_tip_headline):SetContent(cfg.tips):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_DetailsOpenairChallenge_C:OnPcClose()
  self:OnClickCloseBtn()
end

return UMG_DetailsOpenairChallenge_C
