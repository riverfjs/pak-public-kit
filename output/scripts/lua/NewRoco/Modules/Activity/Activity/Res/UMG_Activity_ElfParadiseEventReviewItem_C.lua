local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ElfParadiseEventReviewItem_C = Base:Extend("UMG_Activity_ElfParadiseEventReviewItem_C")

function UMG_Activity_ElfParadiseEventReviewItem_C:OnConstruct()
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OnDestruct()
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self.BtnUnfold.btnLevelUp.OnClicked:Add(self, self.OnBtnUnfoldClicked)
  self.ClickButton.OnClicked:Add(self, self.OpenTips)
  self.IsOpen = false
  if self.uiData then
    self.BtnUnfold:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.uiData.activity_id then
      local activityConf = _G.DataConfigManager:GetActivityConf(self.uiData.activity_id)
      if activityConf then
        self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Time:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Name:SetText(activityConf.activity_name .. self.index)
        self.Time:SetText(string.format("%s-%s", activityConf.appear_time, activityConf.disappear_time))
      end
    end
    if self.uiData.result and 0 ~= self.uiData.result then
      self.Switch:SetActiveWidgetIndex(1)
      self.BtnUnfold.btnLevelUp:SetIsEnabled(true)
      local itemDataList = {}
      table.insert(itemDataList, self.uiData.total_record_num or 0)
      table.insert(itemDataList, self.uiData.total_happy_value or 0)
      table.insert(itemDataList, self.uiData.pet_gift_num or 0)
      self.List_Detailst:InitGridView(itemDataList)
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = self.uiData.goods_type
      rewards.itemId = self.uiData.goods_id
      rewards.itemNum = self.uiData.num
      rewards.bShowGetTag = true
      self.ListItemIcon:OnItemUpdate(rewards, nil, 1)
    else
      self.Switch:SetActiveWidgetIndex(0)
      self.BtnUnfold.btnLevelUp:SetIsEnabled(false)
    end
  end
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OpenTips()
  if self.uiData.goods_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.uiData.goods_id)
  elseif self.uiData.goods_type == _G.Enum.GoodsType.GT_REWARD then
    ActivityUtils.ShowRewardPreview(self.uiData.goods_id)
  else
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.goods_id, self.uiData.goods_type, false)
  end
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OnBtnUnfoldClicked()
  if self.IsOpen then
    self.BtnUnfold:SetRenderScale(UE4.FVector2D(1, 1))
    self.CanvasPanel_Online:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsOpen = false
  else
    self.BtnUnfold:SetRenderScale(UE4.FVector2D(1, -1))
    self.CanvasPanel_Online:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.IsOpen = true
  end
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ElfParadiseEventReviewItem_C:OnDeactive()
end

return UMG_Activity_ElfParadiseEventReviewItem_C
