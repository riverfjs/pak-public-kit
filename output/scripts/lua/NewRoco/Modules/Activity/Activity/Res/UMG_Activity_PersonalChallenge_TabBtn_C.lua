local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_PersonalChallenge_TabBtn_C = Base:Extend("UMG_Activity_PersonalChallenge_TabBtn_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_PersonalChallenge_TabBtn_C:OnConstruct()
  self.RedDot:SetRedPointUIType(Enum.RedPointType.RPT_AWARD, true)
  self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_PersonalChallenge_TabBtn_C:OnDestruct()
end

function UMG_Activity_PersonalChallenge_TabBtn_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.data = _data
  self.bSelected = false
  self.conf = nil
  local parentCustomData = self:GetParentCustomData()
  if parentCustomData then
    self.bSelected = parentCustomData.curSelectId == _data.id
  end
  local singlePartId = _data.base_id and #_data.base_id > 0 and _data.base_id[1] or 0
  if singlePartId > 0 then
    self.conf = _G.DataConfigManager:GetActivityGlobalChallenge(singlePartId)
  end
  if self.conf then
    self.Suit_Ordinary:SetPath(self.conf.tab_icon)
    self.Suit_Selected:SetPath(self.conf.tab_icon_2)
  end
  self:PlayerAnimation()
end

function UMG_Activity_PersonalChallenge_TabBtn_C:PlayerAnimation()
  self:StopAllAnimations()
  if self.bSelected then
    self:PlayAnimation(self.Btn_Suit_A)
  else
    self:PlayAnimation(self.Btn_Suit_A_Out)
  end
end

function UMG_Activity_PersonalChallenge_TabBtn_C:SetRedPoint(_bShowRed)
  self.RedDot:SetVisibility(_bShowRed and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_PersonalChallenge_TabBtn_C:OnItemSelected(_bSelected)
  if _bSelected and self.data and self.data.id then
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSelectChallengeLeftItem, self.data.id)
  end
  self.bSelected = _bSelected
  self:PlayerAnimation()
end

function UMG_Activity_PersonalChallenge_TabBtn_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_Activity_PersonalChallenge_TabBtn_C:OnItemSelected")
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Activity_PersonalChallenge_TabBtn_C:OnAnimationFinished(anim)
  if anim == self.Btn_Suit_A then
    self:PlayAnimation(self.Btn_loop)
  end
end

return UMG_Activity_PersonalChallenge_TabBtn_C
