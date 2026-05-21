local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local Base = _G.NRCViewBase
local UMG_Common_Props_Icon_C = Base:Extend("UMG_Common_Props_Icon_C")

function UMG_Common_Props_Icon_C:OnConstruct()
  self.Num:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Rim:SetIsEnabled(false)
  self.Rim:ActivateParticles(false)
end

function UMG_Common_Props_Icon_C:OnDestruct()
end

function UMG_Common_Props_Icon_C:SetData(Id, type, Num, EnableTips, NewFlag, FrameStyle)
  FrameStyle = FrameStyle or 0
  self.ItemId = Id
  self.Type = type
  if nil ~= EnableTips then
    self.EnableTips = EnableTips
  else
    self.EnableTips = true
  end
  local ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc = UIUtils.GetTipsDetails(self.Type, self.ItemId)
  self.Icon:SetPath(PropIcon)
  self:SetQuality(Quality)
  if Num and Num > 0 then
    local numStr = self:Num2Txt(Num)
    self.Num:SetText(numStr)
    self.Num:SetVisibility(UE4.ESlateVisibility.Visible)
    self.bg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Num:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.bg:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.FlagNew:SetVisibility(NewFlag and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Hidden)
  if 1 == FrameStyle then
    self:SetQuality(0)
    self.Mask:SetRetainRendering(true)
  else
    self.Mask:SetRetainRendering(false)
  end
end

function UMG_Common_Props_Icon_C:SetTip(tip, EnableTips, NewFlag, FrameStyle)
  self.tip = tip
  self.ItemId = tip.id
  self.Type = tip.type
  NewFlag = NewFlag or TipEnum.NewFlagType.None
  if nil == EnableTips then
    self.EnableTips = true
  else
    self.EnableTips = EnableTips
  end
  self.FrameStyle = FrameStyle or 0
  local ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc = tip:Resolve()
  self.IconSize:SetHeightOverride(tip:GetIconSize())
  self.IconSize:SetWidthOverride(tip:GetIconSize())
  self.Icon:SetPath(PropIcon)
  self:SetQuality(Quality)
  if tip.num > 1 and tip.tipType ~= TipEnum.TipObjectType.NewPet then
    self.Num:SetText(self:Num2Txt(tip.num))
    self.Num:SetVisibility(UE4.ESlateVisibility.Visible)
    self.bg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Num:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.bg:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if NewFlag == TipEnum.NewFlagType.None then
    self.FlagNew:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    self.FlagNew:SetBrush(self.FlagNew.brushes:Get(NewFlag))
    self.FlagNew:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:StopAllAnimations()
  self.Rim:ActivateParticles(false)
  if 1 == self.FrameStyle then
    self:SetQuality(0)
    self.Mask:SetRetainRendering(true)
  else
    self.Mask:SetRetainRendering(false)
  end
end

function UMG_Common_Props_Icon_C:TriggerFrameAnimation()
  if 1 == self.FrameStyle then
    self.Rim:SetIsEnabled(true)
    self.Rim:ActivateParticles(true, true)
  elseif self.tip.tipType == TipEnum.TipObjectType.NewPet then
    self:PlayAnimation(self.Show)
  end
end

function UMG_Common_Props_Icon_C:Tick(MyGeometry, InDeltaTime)
  self.Overridden.Tick(self, MyGeometry, InDeltaTime)
  if self.Btn then
    self.Btn:OnTick(InDeltaTime)
  end
end

function UMG_Common_Props_Icon_C:OnPress()
  if not self.EnableTips then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Common_Props_Icon_C:OnPress")
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.ItemId, self.Type)
end

function UMG_Common_Props_Icon_C:Num2Txt(num)
  if num < 10000 then
    return tostring(num)
  end
  if num < 100000 then
    return tostring(math.floor(num / 1000) / 10) .. "W"
  end
  if num < 9990000 then
    return tostring(math.floor(num / 10000)) .. "W"
  end
  return "999W"
end

function UMG_Common_Props_Icon_C:SetQuality(quality)
  self.QualityFrame:SetVisibility(0 == quality and UE4.ESlateVisibility.Hidden or UE4.ESlateVisibility.Visible)
  if 0 == quality then
    self.QualityFrame:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    self.QualityFrame:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    self.QualityFrame:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    self.QualityFrame:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    self.QualityFrame:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    self.QualityFrame:SetPath(UEPath.PROP_QUALITY_5)
  end
end

return UMG_Common_Props_Icon_C
