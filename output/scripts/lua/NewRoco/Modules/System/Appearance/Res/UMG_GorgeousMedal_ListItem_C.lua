local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_GorgeousMedal_ListItem_C = Base:Extend("UMG_GorgeousMedal_ListItem_C")

function UMG_GorgeousMedal_ListItem_C:OnConstruct()
end

function UMG_GorgeousMedal_ListItem_C:OnDestruct()
  self:CancelDelay()
end

function UMG_GorgeousMedal_ListItem_C:CancelDelay()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

function UMG_GorgeousMedal_ListItem_C:OnItemUpdate(_data, datalist, index)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:StopAllAnimations()
  self:PlayAnimation(self.Normal)
  local parentCustomData = self:GetParentCustomData()
  self.bSelected = parentCustomData.curSelectMedalId == _data.conf.id
  self:CancelDelay()
  local waitTime = (math.floor(index / 5) + 1) * 0.05 - 0.05
  self.delayId = _G.DelayManager:DelaySeconds(waitTime, function()
    if self and UE4.UObject.IsValid(self) then
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.bSelected then
        self:PlaySelectAnim()
      else
        self:PlayOpenAnim()
      end
    end
  end)
  self.uiData = _data
  self.Image_Icon:SetPath(_data.conf.fashion_bond_icon)
  self.Cucoloris_Icon:SetPath(_data.conf.fashion_bond_icon)
  self.Image_Icon:SetVisibility(_data.state == AppearanceModuleEnum.FashionMedalState.NotUnLockable and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Cucoloris_Icon:SetVisibility((_data.state == AppearanceModuleEnum.FashionMedalState.NotUpgraded or _data.state == AppearanceModuleEnum.FashionMedalState.UnLockable) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RedDot:SetupKey(411, {
    _data.conf.fashion_bond_band,
    _data.conf.id,
    _data.getTime
  })
end

function UMG_GorgeousMedal_ListItem_C:PlayOpenAnim()
  self:StopAllAnimations()
  self:PlayAnimation(self.Open)
end

function UMG_GorgeousMedal_ListItem_C:PlaySelectAnim()
  self:StopAllAnimations()
  if self.bSelected then
    self:PlayAnimation(self.Select_in)
  else
    self:PlayAnimation(self.Select_out)
  end
end

function UMG_GorgeousMedal_ListItem_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_GorgeousMedal_ListItem_C:OnTouchEnded")
  self.RedDot:EraseRedPoint()
  Base.OnTouchEnded(self, _MyGeometry, _InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_GorgeousMedal_ListItem_C:OnItemSelected(_bSelected)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if _bSelected then
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OnBondSelected, self.uiData)
  end
  self.bSelected = _bSelected
  self:PlaySelectAnim()
end

function UMG_GorgeousMedal_ListItem_C:OnDeactive()
end

return UMG_GorgeousMedal_ListItem_C
