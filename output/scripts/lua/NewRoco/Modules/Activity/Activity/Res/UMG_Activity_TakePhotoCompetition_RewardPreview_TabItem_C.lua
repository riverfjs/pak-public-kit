local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C = Base:Extend("UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C")

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnConstruct()
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnDestruct()
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnAnimationFinished(anim)
  if anim == self.change1 then
    self:PlayAnimation(self.select_loop)
  end
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.Title:SetText(self.data.tabName)
  if 1 == index then
    self:PlayAnimation(self.change1)
  else
    self:PlayAnimation(self.Open)
  end
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnItemSelected(_bSelected)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnItemSelected")
  self:StopAllAnimations()
  self:PlayAnimation(_bSelected and self.change1 or self.change2)
  local activityModule = _G.NRCModuleManager:GetModule("ActivityModule")
  if activityModule:HasPanel("TakePhotoCompetition_RewardPreview") then
    local panel = activityModule:GetPanel("TakePhotoCompetition_RewardPreview")
    if panel then
      panel:OnTabItemSelected(self.index)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C:OnDeactive()
end

return UMG_Activity_TakePhotoCompetition_RewardPreview_TabItem_C
