local OutOfScreenPadding = 5
local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local Base = require("Core.NRCModule.NRCPanelBase")
local GuidanceHintTextDirection = {
  Down = 0,
  Up = 1,
  Left = 2,
  Right = 3
}
local UMG_Guidance_Hint_C = Base:Extend("UMG_Guidance_Hint_C")

function UMG_Guidance_Hint_C:Destruct()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
  if self.outOfScreenHandle then
    _G.DelayManager:CancelDelayById(self.outOfScreenHandle)
    self.outOfScreenHandle = nil
  end
  self.bHasTryShowBtnClose = nil
end

function UMG_Guidance_Hint_C:Init(config, focusConf, bIsBattleGuide)
  local text = ""
  if _G.UE4Helper.IsPCMode() then
    text = focusConf.pc_text or ""
  else
    text = focusConf.mobile_text or ""
  end
  self.Text_Hint:SetText(text)
  self.bIsBattleGuide = bIsBattleGuide
  self.bHasTryShowBtnClose = nil
  if self.bHasInited then
    return
  end
  self.bHasInited = true
  
  local function onSkip()
    if self.bIsBattleGuide then
      _G.NRCAudioManager:PlaySound2DAuto(41401010, self.name)
      self:TrySkipInBattle()
    else
      Log.Debug("UMG_Guidance_Hint_C onSkip", config.unique_id, config.group_id, config.sub_guide_id)
      _G.NRCAudioManager:PlaySound2DAuto(41401010, self.name)
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideSkip, config)
    end
  end
  
  if self.btnClose.btnClose and self.btnClose.btnClose.OnClicked then
    self.btnClose.btnClose.OnClicked:Add(self, onSkip)
  end
end

function UMG_Guidance_Hint_C:ClearGuideInBattle()
  _G.NRCModuleManager:DoCmd(_G.BattleTutorialGuideModuleCmd.ClearGuide)
end

function UMG_Guidance_Hint_C:TrySkipInBattle()
  local title = _G.DataConfigManager:GetBattleGlobalConfig("battle_train_skip_title").str
  local des = _G.DataConfigManager:GetBattleGlobalConfig("battle_train_skip_display").str
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.ClearGuideInBattle):SetButtonText(_G.DataConfigManager:GetLocalizationConf("teambattlemodule_8").msg, _G.DataConfigManager:GetLocalizationConf("teambattlemodule_7").msg):SetCloseOnCancel(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Guidance_Hint_C:UpdatePosition(style, focusConf, focusSize, centerPosition)
  if not self.bHasInited then
    return
  end
  local offsetValue
  if _G.UE4Helper.IsPCMode() then
    offsetValue = focusConf.pc_edior_pos
  else
    offsetValue = focusConf.mobile_edior_pos
  end
  local offsetLeft = 50
  local offsetRight = 20
  local offsetNoClose = math.max(offsetLeft, offsetRight)
  if style.finish_button_showtime < 0 then
    self:UpdateImageSlot(offsetNoClose, offsetNoClose)
    self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetNoClose, offsetNoClose)
  elseif 0 == style.finish_button_showtime then
    self.btnClose:SetVisibility(UE4.ESlateVisibility.Visible)
    self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetLeft, offsetRight)
  elseif style.finish_button_showtime > 0 then
    if self.delayId then
      if self.bIsBattleGuide then
        return
      end
      self:UpdateImageSlot(offsetLeft, offsetRight)
      self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetLeft, offsetRight)
    else
      if self.bIsBattleGuide and self.bHasTryShowBtnClose then
        self:UpdateImageSlot(offsetLeft, offsetRight)
        self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetNoClose, offsetNoClose)
        return
      end
      self.bHasTryShowBtnClose = true
      self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:UpdateImageSlot(offsetNoClose, offsetNoClose)
      self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetNoClose, offsetNoClose)
      self.delayId = _G.DelayManager:DelaySeconds(style.finish_button_showtime / 1000.0, function()
        if not self or not UE4.UObject.IsValid(self) then
          return
        end
        self.delayId = nil
        if not self.btnClose or not UE4.UObject.IsValid(self.btnClose) then
          return
        end
        self.btnClose:SetVisibility(UE4.ESlateVisibility.Visible)
        self:UpdateImageSlot(offsetLeft, offsetRight)
        self:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetLeft, offsetRight)
      end)
    end
  end
end

function UMG_Guidance_Hint_C:UpdateImageSlot(offsetLeft, offsetRight)
  local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.NRCImage_28)
  if not slot then
    return
  end
  local layout = slot.LayoutData
  layout.Offsets.Left = -offsetLeft
  layout.Offsets.Right = -offsetRight
  slot:SetLayout(layout)
end

function UMG_Guidance_Hint_C:UpdateSlotPosition(focusConf, offsetValue, focusSize, centerPosition, offsetLeft, offsetRight)
  local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self)
  if not slot or not UE4.UObject.IsValid(slot) then
    return
  end
  offsetValue = offsetValue or 0
  focusSize = focusSize or UE4.FVector2D(0, 0)
  local align = UE4.FVector2D(0.5, 0.5)
  local offset = UE4.FVector2D(0, 0)
  local direction = GuidanceHintTextDirection.Down
  if focusConf.text_pos == nil or focusConf.text_pos == "down" then
    align = UE4.FVector2D(0.5, 0)
    offset.Y = offsetValue + focusSize.Y / 2.0
  elseif focusConf.text_pos == "up" then
    align = UE4.FVector2D(0.5, 1)
    offset.Y = -(offsetValue + focusSize.Y / 2.0)
    direction = GuidanceHintTextDirection.Up
  elseif focusConf.text_pos == "right" then
    align = UE4.FVector2D(0, 0.5)
    offset.X = offsetValue + focusSize.X / 2.0 + offsetLeft
    direction = GuidanceHintTextDirection.Right
  elseif focusConf.text_pos == "left" then
    align = UE4.FVector2D(1, 0.5)
    offset.X = -(offsetValue + focusSize.X / 2.0 + offsetRight)
    direction = GuidanceHintTextDirection.Left
  end
  Log.Debug("UMG_Guidance_Hint_C set alignment and position", focusConf.text_pos, offsetValue, focusSize, align, offset)
  slot:SetAlignment(align)
  slot:SetPosition(offset)
  if not self.bIsBattleGuide then
    self:SetRenderOpacity(0)
  end
  if self.outOfScreenHandle then
    _G.DelayManager:CancelDelayById(self.outOfScreenHandle)
    self.outOfScreenHandle = nil
  end
  self:InvalidateLayoutAndVolatility()
  self.outOfScreenHandle = _G.DelayManager:DelayFrames(1, function()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    self:CheckOutOfScreen(slot, offset, centerPosition, direction)
  end)
end

function UMG_Guidance_Hint_C:CheckOutOfScreen(slot, offset, centerPosition, direction)
  if not slot or not UE4.UObject.IsValid(slot) then
    return
  end
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(self)
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(self)
  local blackBorder = GuideConfigTypes.GetBlackBorderSize()
  local realViewportSize = (viewportSize - blackBorder * 2.0) / viewportScale
  local geometry = self.NRCImage_28:GetCachedGeometry()
  local localSize = UE4.USlateBlueprintLibrary.GetLocalSize(geometry)
  local absoluteSize = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geometry)
  local realSize = UE4.FVector2D(absoluteSize.X, absoluteSize.Y) / viewportScale
  local screenPosition = UE4.FVector2D(centerPosition.X + offset.X, centerPosition.Y + offset.Y)
  if direction == GuidanceHintTextDirection.Up then
    screenPosition.Y = screenPosition.Y - realSize.Y / 2.0
  elseif direction == GuidanceHintTextDirection.Down then
    screenPosition.Y = screenPosition.Y + realSize.Y / 2.0
  elseif direction == GuidanceHintTextDirection.Left then
    screenPosition.X = screenPosition.X - realSize.X / 2.0
  elseif direction == GuidanceHintTextDirection.Right then
    screenPosition.X = screenPosition.X + realSize.X / 2.0
  end
  if absoluteSize.X <= 0 and absoluteSize.Y <= 0 then
    Log.Debug("UMG_Guidance_Hint_C CheckOutOfScreen self hidden", viewportSize, viewportScale, realViewportSize, centerPosition, offset, screenPosition, localSize, absoluteSize, realSize)
    if self.outOfScreenHandle then
      _G.DelayManager:CancelDelayById(self.outOfScreenHandle)
      self.outOfScreenHandle = nil
    end
    self.outOfScreenHandle = _G.DelayManager:DelayFrames(1, function()
      if not self or not UE4.UObject.IsValid(self) then
        return
      end
      self:CheckOutOfScreen(slot, offset, centerPosition, direction)
    end)
    return
  end
  local bOutOfScreen = false
  local topLeft = UE4.FVector2D(screenPosition.X - realSize.X / 2.0, screenPosition.Y - realSize.Y / 2.0)
  local downRight = UE4.FVector2D(screenPosition.X + realSize.X / 2.0, screenPosition.Y + realSize.Y / 2.0)
  Log.Debug("UMG_Guidance_Hint_C CheckOutOfScreen base", viewportSize, viewportScale, blackBorder, realViewportSize, centerPosition, offset, screenPosition, localSize, absoluteSize, realSize, topLeft, downRight)
  local realOutOfScreenPadding = OutOfScreenPadding / viewportScale
  local realScreenTopLeft = UE4.FVector2D(0, 0)
  local realScreenDownRight = realViewportSize
  local safePadding, safePaddingScale, spillOverPadding = UE4.UWidgetBlueprintLibrary.GetSafeZonePadding(self)
  local orientation = UE4.UBlueprintPlatformLibrary.GetDeviceOrientation()
  Log.Debug("UMG_Guidance_Hint_C CheckOutOfScreen margin", safePadding, safePaddingScale, spillOverPadding, orientation)
  if safePadding then
    local paddingHorizontal = math.max(safePadding.X, safePadding.Z) / viewportScale
    realScreenTopLeft.X = paddingHorizontal
    realScreenTopLeft.Y = safePadding.Y / viewportScale
    realScreenDownRight.X = realViewportSize.X - paddingHorizontal
    realScreenDownRight.Y = realViewportSize.Y - safePadding.W / viewportScale
  end
  if topLeft.X < realScreenTopLeft.X then
    offset.X = offset.X - (topLeft.X - realScreenTopLeft.X) + realOutOfScreenPadding
    bOutOfScreen = true
  elseif downRight.X > realScreenDownRight.X then
    offset.X = offset.X - (downRight.X - realScreenDownRight.X) - realOutOfScreenPadding
    bOutOfScreen = true
  end
  if topLeft.Y < realScreenTopLeft.Y then
    offset.Y = offset.Y - (topLeft.Y - realScreenTopLeft.Y) + realOutOfScreenPadding
    bOutOfScreen = true
  elseif downRight.Y > realScreenDownRight.Y then
    offset.Y = offset.Y - (downRight.Y - realScreenDownRight.Y) - realOutOfScreenPadding
    bOutOfScreen = true
  end
  if not bOutOfScreen then
    Log.Debug("UMG_Guidance_Hint_C CheckOutOfScreen not", viewportSize, viewportScale, blackBorder, realViewportSize, "margin", realScreenTopLeft, realScreenDownRight, "pos", centerPosition, offset, screenPosition, "size", localSize, absoluteSize, realSize)
    self:SetRenderOpacity(1)
    return
  end
  Log.Debug("UMG_Guidance_Hint_C CheckOutOfScreen", viewportSize, viewportScale, blackBorder, realViewportSize, "margin", realScreenTopLeft, realScreenDownRight, "pos", centerPosition, offset, screenPosition, "size", localSize, absoluteSize, realSize)
  slot:SetPosition(offset)
  self:SetRenderOpacity(1)
end

return UMG_Guidance_Hint_C
