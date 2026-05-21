require("UnLuaEx")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local UMG_GetProps_Tips_C = NRCViewBase:Extend("UMG_GetProps_Tips_C")

function UMG_GetProps_Tips_C:OnConstruct()
  self.hidetime = 0
  self.quality = 0
  self.StarHide = false
  self.moveSpeed = 116.66666666666667
  self.ColorList = {
    [1] = "FFFFFFFF",
    [2] = "B8EB58FF",
    [3] = "48A8CBFF",
    [4] = "FC65FFFF",
    [5] = "EFA012FF"
  }
end

function UMG_GetProps_Tips_C:OnDestruct()
end

function UMG_GetProps_Tips_C:SetData(tip)
  self.hidetime = 1
  self.StarHide = false
  self.tip = tip
  if tip.showIconPath then
    self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Arrows:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Icon:SetPath(tip.showIconPath)
  else
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Arrows:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc = tip:Resolve()
  self.quality = Quality
  if ItemConf then
    if tip.reason == ProtoEnum.FlowReason.FLOW_REASON_HOME_PLANT_GOOD_YIELD then
      local harvestIconPath = _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetHarvestIconPath)
      self.Icon_Harvest:SetPath(harvestIconPath)
      self.Icon_Harvest:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Icon_Harvest:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.PropName:SetText(PropName)
    if tip.tipType == TipEnum.TipObjectType.PetLevelUp then
      self.Num:SetText(string.format("Lv+%d", tip.num))
    elseif tip.tipType == TipEnum.TipObjectType.RechargeUseCount then
      UIUtils.SetTextWithQuality(self.Num, string.format(LuaText.umg_getprops_tips_1, tip.source.remain_use_cnt - tip.num), Quality)
    else
      self.Num:SetText(string.format("x%d", tip.num))
    end
    Log.Debug(self.BackgroundImage:GetVisibility(), "UMG_GetProps_Tips_C:SetData")
    local Size = self.BackgroundImage.brushes:Length()
    local BrushIndex = math.clamp(Quality, 1, Size)
    if tip.type == Enum.GoodsType.GT_BAGITEM then
      self:SetPropIcon(PropIcon, ItemConf)
    else
      self:SetPropIcon(PropIcon)
    end
    self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BackgroundImage:ChangeImage(BrushIndex - 1)
    self.PropName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(self.ColorList[BrushIndex]))
    self.Num:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(self.ColorList[BrushIndex]))
  else
    local typeName = table.getKeyName(Enum.GoodsType, tip.type) or LuaText.umg_getprops_tips_2
    self.PropName:SetText(string.format("%s=%d\230\178\161\233\133\141!!!", typeName, tip.id))
    UIUtils.SetTextWithQuality(self.PropName, string.format("%s=%d\230\178\161\233\133\141!!!", typeName, tip.id), 5)
  end
  if tip.tipType == TipEnum.TipObjectType.PetLevelUp then
    self:PlayAnimation(self.LevelUp)
  end
end

function UMG_GetProps_Tips_C:PlayAnimationTweenIn()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  NRCModuleManager:DoCmd(TipsModuleCmd.Tips_MiracleExchange, self.tip)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1199, "UMG_GetProps_Tips_C:PlayAnimationTweenIn")
  if self.quality and self.quality > 2 then
    self:PlayAnimation(self.TweenIn)
  else
    self:PlayAnimation(self.TweenIn_2)
  end
end

function UMG_GetProps_Tips_C:TryTweenOut()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1076, "UMG_GetProps_Tips_C:TryTweenOut")
  self:PlayAnimation(self.TweenOut)
  self.StarHide = true
end

function UMG_GetProps_Tips_C:OnAnimationFinished(anim)
  if anim == self.TweenOut then
    self.show = false
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.TweenIn or anim == self.TweenIn_2 then
    self:PlayAnimation(self.Loop)
  end
end

function UMG_GetProps_Tips_C:Tick(MyGeometry, InDeltaTime)
  if self.hidetime and self.hidetime > 0 then
    self.hidetime = self.hidetime - InDeltaTime
  end
end

function UMG_GetProps_Tips_C:SetHideTime(time)
  self.hidetime = time
end

function UMG_GetProps_Tips_C:GetCanHide()
  return self.hidetime <= 0
end

function UMG_GetProps_Tips_C:TTE(Quality)
  local Size = self.BackgroundImage.brushes:Length()
  local BrushIndex = math.clamp(Quality, 1, Size)
  local Brush = self.BackgroundImage.brushes:Get(BrushIndex)
  if Brush then
    self.BackgroundImage:SetBrush(Brush)
  end
end

function UMG_GetProps_Tips_C:SetPropIcon(icon_path, bag_item_conf)
  if icon_path and bag_item_conf and bag_item_conf.type == _G.Enum.BagItemType.BI_PET_EGG and bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
    local eggInfo = {}
    eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
    self.ItemSwitcher:SetActiveWidgetIndex(2)
    self.PetEggItem:SetEggIcon(eggInfo, icon_path)
    return
  end
  if icon_path then
    self.ItemSwitcher:SetActiveWidgetIndex(0)
    self.PropIcon:SetPath(icon_path)
  end
end

return UMG_GetProps_Tips_C
