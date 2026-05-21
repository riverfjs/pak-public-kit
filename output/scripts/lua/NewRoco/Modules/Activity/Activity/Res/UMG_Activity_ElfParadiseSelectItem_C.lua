local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Activity_ElfParadiseSelectItem_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfParadiseSelectItem_C")

function UMG_Activity_ElfParadiseSelectItem_C:OnConstruct()
  self:AddButtonListener(self.ExamineBtn.btnLevelUp, self.BtnExamineBtnOnClick)
end

function UMG_Activity_ElfParadiseSelectItem_C:UpdateUI(data)
  self.WishChoiceCountInfo = data.WishChoiceCountInfo or {}
  self.Parent = data.Parent
  self.UiData = data.data
  self.wish = data.wish
  local icon, quality, name = UIUtils.GetIconAndQualityByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
  self:SetQuality(self.UiData.goods_level)
  self.Image:SetPath(icon)
  self.Text01:SetText(self.UiData.goods_tag)
  self.Text02:SetText(self.UiData.goods_tag)
  self.Text03:SetText(self.UiData.goods_tag)
  self.Switch:SetActiveWidgetIndex((self.UiData.goods_level > 3 and 3 or self.UiData.goods_level) - 1)
  local overCount, ShowText = self.Parent:GetWishPeopleCountText(self.wish)
  if overCount then
    self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.Text_PeoPle:SetText(ShowText)
  self.Text_Num:SetText(self.UiData.goods_num)
  self.RewardsTitle:SetText(name)
  self.RewardsQuantity:SetText("x" .. self.UiData.goods_count)
end

function UMG_Activity_ElfParadiseSelectItem_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.NRCImage_Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityElvesPlaying/Frames/img_bg_cheng_png.img_bg_cheng_png'")
  elseif 2 == quality then
    self.NRCImage_Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityElvesPlaying/Frames/img_bg_zi_png.img_bg_zi_png'")
  elseif 3 == quality then
    self.NRCImage_Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityElvesPlaying/Frames/img_bg_lan_png.img_bg_lan_png'")
  end
end

function UMG_Activity_ElfParadiseSelectItem_C:OnDeactive()
end

function UMG_Activity_ElfParadiseSelectItem_C:SetSelect()
  self:StopAllAnimations()
  self.BgSwitcher:SetActiveWidgetIndex(1)
  self:PlayAnimation(self.select_loop, 0, 99999)
end

function UMG_Activity_ElfParadiseSelectItem_C:CancelSelect()
  self:StopAllAnimations()
  self.BgSwitcher:SetActiveWidgetIndex(0)
  self:PlayAnimation(self.normal)
end

function UMG_Activity_ElfParadiseSelectItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Activity_ElfParadiseSelectItem_C:OnTouchEnded")
  self.Parent:OnSelectItem(self.wish)
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Activity_ElfParadiseSelectItem_C:BtnExamineBtnOnClick()
  UIUtils.OpenItemTipsByItemIDAndItemType(self.UiData.goods_id, self.UiData.goods_type)
end

return UMG_Activity_ElfParadiseSelectItem_C
