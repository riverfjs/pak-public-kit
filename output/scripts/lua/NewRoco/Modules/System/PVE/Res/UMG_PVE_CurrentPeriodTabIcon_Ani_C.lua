local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PVE_CurrentPeriodTabIcon_Ani_C = Base:Extend("UMG_PVE_CurrentPeriodTabIcon_Ani_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnConstruct()
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnDestruct()
  self:CancelPlayLoopAnim()
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.Title:SetText(_data.tab_name)
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnItemSelected(_bSelected)
  self.bSelected = _bSelected
  self:StopAllAnimations()
  self:CancelPlayLoopAnim()
  if _bSelected then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.DispatchEvent, PVEModuleEvent.SwitchCurrentPeriodSelectedItem, self.data)
    self:PlayAnimation(self.select_in)
  else
    self:PlayAnimation(self.select_out)
  end
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnAnimationFinished(anim)
  if self.bSelected then
    if anim == self.select_in then
      self:StartPlayLoopAnim()
    elseif anim == self.select_loop then
      self:CancelPlayLoopAnim()
      self.playLoopDelayId = _G.DelayManager:DelaySeconds(3, self.OnDelayPlayLoopAnim, self)
    end
  end
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:StartPlayLoopAnim()
  self:PlayAnimation(self.select_loop)
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:OnDelayPlayLoopAnim()
  self.playLoopDelayId = nil
  self:StartPlayLoopAnim()
end

function UMG_PVE_CurrentPeriodTabIcon_Ani_C:CancelPlayLoopAnim()
  if self.playLoopDelayId then
    _G.DelayManager:CancelDelayById(self.playLoopDelayId)
    self.playLoopDelayId = nil
  end
end

return UMG_PVE_CurrentPeriodTabIcon_Ani_C
