local UMG_SeasonBadgeTips_C = _G.NRCPanelBase:Extend("UMG_SeasonBadgeTips_C")

function UMG_SeasonBadgeTips_C:OnActive(data)
  self.data = data
  self:SetInfo()
  self:PlayAnimation(self.open)
  self:OnAddEventListener()
end

function UMG_SeasonBadgeTips_C:OnDeactive()
  self:RemoveAllButtonListener()
end

function UMG_SeasonBadgeTips_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn, self.OnCloseBtnClick)
end

function UMG_SeasonBadgeTips_C:SetInfo()
  local currBadgeInfo = self.data:GetSeasonBadgeInfo()
  if currBadgeInfo and currBadgeInfo.badgeConfData then
    self.ProbabilityText:SetText(LuaText.magic_manual_season_badge_subtitle)
    self.Icon:SetPath(currBadgeInfo.badgeConfData.badge_icon)
  end
  local badgeList = self.data:GetAllSeasonBadgeConf()
  self.List:InitList(badgeList)
end

function UMG_SeasonBadgeTips_C:OnAnimationFinished(anim)
  if anim == self.close then
    self:OnClose()
  end
end

function UMG_SeasonBadgeTips_C:OnCloseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008039, "UMG_SeasonBadgeTips_C:OnCloseBtnClick")
  self:PlayAnimation(self.close)
end

return UMG_SeasonBadgeTips_C
