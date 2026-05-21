local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C = Base:Extend("UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C")
local numberStr = {
  "I",
  "II",
  "III",
  "IV",
  "V",
  "VI",
  "VII",
  "VIII",
  "IX",
  "X"
}

function UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  local cfg = _G.DataConfigManager:GetTakephotoCompetitionConf(_data)
  if cfg then
    local number = cfg.id % 10
    self.TextSelect:SetText(numberStr[number])
    self.UnselectedText:SetText(numberStr[number])
  else
    self.TextSelect:SetText("")
    self.UnselectedText:SetText("")
  end
  self:PlayAnimation(self.normal)
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C:OnItemSelected(_bSelected)
  self.Selected = _bSelected
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.change1)
    self:BroadcastMsg("OnSelectTab", self.data)
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C:OnTouchEnded")
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C:OnAnimationFinished(anim)
  if anim == self.change1 then
    if self.Selected then
      self:PlayAnimation(self.select_loop, 0, 0)
    end
  elseif anim == self.change2 and not self.Selected then
    self:PlayAnimation(self.normal)
  end
end

return UMG_Activity_TakePhotoCompetition_PreviousReview_Tab_C
