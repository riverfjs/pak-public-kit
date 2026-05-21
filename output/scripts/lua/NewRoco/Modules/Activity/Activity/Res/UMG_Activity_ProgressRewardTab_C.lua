local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ProgressRewardTab_C = Base:Extend("UMG_Activity_ProgressRewardTab_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_ProgressRewardTab_C:OnConstruct()
  self.redPointNew:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.redPointSpecial:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.redPointReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.redPointReward:SetRedPointUIType(Enum.RedPointType.RPT_AWARD, true)
end

function UMG_Activity_ProgressRewardTab_C:OnDestruct()
end

function UMG_Activity_ProgressRewardTab_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self:PlayAnimation(self.In)
  self.Title:SetText(_data)
end

function UMG_Activity_ProgressRewardTab_C:SetRedPoint(_bShowRed)
  self.redPointReward:SetVisibility(_bShowRed and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_ProgressRewardTab_C:OnItemSelected(_bSelected)
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Activity_ProgressRewardTab_C:OnItemSelected")
    self:PlayAnimation(self.Select)
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSelectChallengeTopItem, self.index)
  else
    self:PlayAnimation(self.Unselect)
  end
end

function UMG_Activity_ProgressRewardTab_C:OnDeactive()
end

return UMG_Activity_ProgressRewardTab_C
