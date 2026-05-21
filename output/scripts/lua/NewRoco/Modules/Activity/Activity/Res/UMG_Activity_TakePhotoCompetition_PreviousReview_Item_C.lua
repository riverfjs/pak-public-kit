local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C = Base:Extend("UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C")

function UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  if _data.rank <= 3 then
    self.NRCSwitcher_56:SetActiveWidgetIndex(_data.rank - 1)
  else
    self.NRCSwitcher_56:SetActiveWidgetIndex(3)
    self.RankNum:SetText(_data.rank)
  end
  local userInfo = _data.user_info
  local extData = userInfo and userInfo.ext_data
  local baseExtData = extData and extData.base_data
  self.Score:SetText(userInfo and userInfo.score or "")
  self.Name:SetText(baseExtData and baseExtData.name or "")
  local headPath = ""
  local headId = baseExtData and baseExtData.card_icon_selected
  if headId and 0 ~= headId then
    headPath = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetCardHeadIconByHeadId, headId)
  end
  self.Icon:SetPath(headPath)
  self:PlayAnimation(self.Normal)
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C:OnItemSelected(_bSelected)
  self.Selected = _bSelected
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.Selection)
    self:BroadcastMsg("OnSelectRankDataItem", self.data)
  else
    self:PlayAnimation(self.Unselect)
  end
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C:OnAnimationFinished(anim)
  if anim == self.Unselect and not self.Selected then
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C:OnTouchEnded")
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_Activity_TakePhotoCompetition_PreviousReview_Item_C
