local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local UMG_HerbologyBadge_Trial_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_Trial_C")

function UMG_HerbologyBadge_Trial_C:Construct()
  NRCPanelBase.Construct(self)
  self.TrialID = -1
end

function UMG_HerbologyBadge_Trial_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  UE4Helper.SetEnableWorldRendering(true, nil, "SelectTrial")
  self.uiData = self.module.Data:GetCacheTrialData()
  self:OnAddEventListener()
  self:_InitPanel()
  self.TabList:SetMsgHandler({
    OnItemSelected = _G.MakeWeakFunctor(self, self.OnDifficultySelected)
  })
end

function UMG_HerbologyBadge_Trial_C:OnDeactive()
  UE4Helper.SetEnableWorldRendering(nil, nil, "SelectTrial")
  self:OnRemoveEventListener()
end

function UMG_HerbologyBadge_Trial_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnDetailButtonClicked)
  self:AddButtonListener(self.Notarize_Btn.btnLevelUp, self.OnNotarizeButtonClicked)
end

function UMG_HerbologyBadge_Trial_C:OnRemoveEventListener()
end

function UMG_HerbologyBadge_Trial_C:OnCloseButtonClicked()
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.Init)
end

function UMG_HerbologyBadge_Trial_C:OnDetailButtonClicked()
  local titleText = "\232\191\153\230\152\175\230\160\135\233\162\152"
  local contentStr = "\232\191\153\230\152\175\229\134\133\229\174\185"
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_HerbologyBadge_Trial_C:OnNotarizeButtonClicked()
  self.module.Data.TrialID = self.TrialID
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.SelectPet)
end

function UMG_HerbologyBadge_Trial_C:OnConstruct()
end

function UMG_HerbologyBadge_Trial_C:OnDestruct()
end

local RomanStrMap = {
  [1] = "I",
  [2] = "II",
  [3] = "III",
  [4] = "IV",
  [5] = "V",
  [6] = "VI",
  [7] = "VII",
  [8] = "VIII",
  [9] = "IX",
  [10] = "X",
  [11] = "XI",
  [12] = "XII"
}

function UMG_HerbologyBadge_Trial_C:_InitPanel()
  self.NRCText_1:SetText("\230\136\152\230\150\151\232\167\132\229\136\153")
  local TrialConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.GRASS_TRIAL_CONF):GetAllDatas()
  if not (self.uiData and self.uiData.progress_data) or not self.uiData.progress_data.cleared_trial_ids then
    self.TabList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:OnDifficultySelected(next(TrialConfs))
    return
  end
  if 0 == #self.uiData.progress_data.cleared_trial_ids then
    self.TabList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:OnDifficultySelected(next(TrialConfs))
  else
    local TrialList = {}
    for Index, TrialConf in pairs(TrialConfs) do
      table.insert(TrialList, {
        starNum = TrialConf.id,
        battleRomanNum = RomanStrMap[Index - 9999]
      })
    end
    self.TabList:SetVisibility(UE4.ESlateVisibility.Visible)
    self.TabList:InitList(TrialList)
    self.TabList:SelectItemByIndex(0)
  end
end

function UMG_HerbologyBadge_Trial_C:OnAnimationFinished(anim)
end

function UMG_HerbologyBadge_Trial_C:OnDifficultySelected(TrialID)
  self.TrialID = TrialID
  local TrialConf = _G.DataConfigManager:GetGrassTrialConf(TrialID)
  self.TextTitle:SetText(TrialConf.name)
  self.NRCText_Class:SetText(tostring(TrialConf.level))
  local rewardsTable = {}
  if TrialConf.reward then
    for _, rewardId in ipairs(TrialConf.reward) do
      local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
      if rewardConf and rewardConf.RewardItem then
        for _, rewardItem in ipairs(rewardConf.RewardItem) do
          local itemData = {}
          itemData.itemType = rewardItem.Type
          itemData.itemId = rewardItem.Id
          itemData.itemNum = rewardItem.Count
          itemData.bShowNum = true
          itemData.bShowTip = true
          table.insert(rewardsTable, itemData)
        end
      end
    end
  end
  self.AwardList:InitList(rewardsTable)
  local totalPoint = 0
  if TrialConf.chapter then
    for _, chapterId in ipairs(TrialConf.chapter) do
      local chapterConf = _G.DataConfigManager:GetGrassTrialChapterConf(chapterId)
      if chapterConf and chapterConf.node_struct then
        for _, nodeData in ipairs(chapterConf.node_struct) do
          if nodeData.reward_point and nodeData.reward_point > 0 then
            totalPoint = totalPoint + nodeData.reward_point
          end
        end
      end
    end
  end
  self.NRCText_Integral:SetText(tostring(totalPoint))
  local ruleDescs = {}
  if TrialConf.rule then
    for _, ruleId in ipairs(TrialConf.rule) do
      local effectConf = _G.DataConfigManager:GetGrassTrialEffectConf(ruleId)
      if effectConf and effectConf.info and effectConf.info ~= "" then
        table.insert(ruleDescs, effectConf.info)
      end
    end
  end
  if #ruleDescs > 0 then
    self.CanvasPanel_59:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCTextDes_1:SetText(table.concat(ruleDescs, "\n"))
  else
    self.CanvasPanel_59:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

return UMG_HerbologyBadge_Trial_C
