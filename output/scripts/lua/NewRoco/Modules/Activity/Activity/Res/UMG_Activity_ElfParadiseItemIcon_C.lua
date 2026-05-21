local UIUtils = require("NewRoco.Utils.UIUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Activity_ElfParadiseItemIcon_C = Base:Extend("UMG_Activity_ElfParadiseItemIcon_C")

function UMG_Activity_ElfParadiseItemIcon_C:OnConstruct()
  self.AddButton.OnClicked:Add(self, self.ChangeSelectReward)
  self.ChoosePetButton.OnClicked:Add(self, self.ChangeSelectReward)
end

function UMG_Activity_ElfParadiseItemIcon_C:OnDestruct()
  self.ChoosePetButton.OnClicked:Remove(self, self.ChangeSelectReward)
  self.AddButton.OnClicked:Remove(self, self.ChangeSelectReward)
end

function UMG_Activity_ElfParadiseItemIcon_C:ChangeSelectReward()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ElfParadiseItemIcon_C:ChangeSelectReward")
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    local Activity_id = PetTripActivityInst[1]:GetActivityId()
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenElfParadiseSelect, Activity_id)
  end
end

function UMG_Activity_ElfParadiseItemIcon_C:OnItemUpdate(_data, datalist, index)
  self.type = _data.type
  self.UiData = _data.data
  self.MeetStandard = _data.MeetStandard
  self.recieved_award = _data.recieved_award
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AlreadyReceived:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChoosePetButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AddButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Color:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_19:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Selected_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if 1 == self.type then
    if self.MeetStandard then
      if self.UiData then
        self.ChoosePetButton:SetVisibility(UE4.ESlateVisibility.Visible)
        if self.UiData then
          self.Color:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
          local icon, quality = UIUtils.GetIconAndQualityByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
          self:SetQuality(quality)
          self.Icon:SetPath(icon)
          self.IconText:SetVisibility(UE4.ESlateVisibility.Visible)
          self.IconText:SetText("x" .. self.UiData.goods_count)
        end
      else
        self.CanvasPanel_19:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Selected_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.RedDot:SetVisibility(UE4.ESlateVisibility.Visible)
        self.AddButton:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    else
      if self.UiData then
        self.Color:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
        local icon, quality = UIUtils.GetIconAndQualityByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
        self:SetQuality(quality)
        self.Icon:SetPath(icon)
        self.IconText:SetVisibility(UE4.ESlateVisibility.Visible)
        self.IconText:SetText("x" .. self.UiData.goods_count)
      end
      if 1 == self.UiData.goods_level then
        self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  elseif 2 == self.type then
    if self.UiData then
      self.Color:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
      local icon, quality = UIUtils.GetIconAndQualityByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
      self:SetQuality(quality)
      self.Icon:SetPath(icon)
      self.IconText:SetVisibility(UE4.ESlateVisibility.Visible)
      self.IconText:SetText("x" .. self.UiData.goods_count)
    end
  elseif 3 == self.type and self.UiData then
    self.Color:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
    local icon, quality = UIUtils.GetIconAndQualityByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
    self:SetQuality(quality)
    self.Icon:SetPath(icon)
    self.IconText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.IconText:SetText("x" .. self.UiData.goods_count)
    if self.recieved_award and self.AlreadyReceived then
      self.AlreadyReceived:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_Activity_ElfParadiseItemIcon_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Activity_ElfParadiseItemIcon_C:OnItemSelected(_bSelected)
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(1303, "UMG_Common_ListItemIcon_C:OpenTips")
    if self.UiData and self.UiData.goods_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.UiData.goods_id)
    elseif self.UiData and self.UiData.goods_type == _G.Enum.GoodsType.GT_REWARD then
      ActivityUtils.ShowRewardPreview(self.UiData.goods_id)
    elseif self.UiData then
      local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.UiData.goods_id, self.UiData.goods_type, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack)
    end
  end
end

function UMG_Activity_ElfParadiseItemIcon_C:OnDeactive()
end

return UMG_Activity_ElfParadiseItemIcon_C
