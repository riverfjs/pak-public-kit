local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local UMG_PlantAcquisitionItem_C = Base:Extend("UMG_PlantAcquisitionItem_C")
local INCREASE_INTERVAL = 0
local INCREASE_NUM = 0
local DECREASE_INTERVAL = 0
local DECREASE_NUM = 0
local PRESS_HOLD_DURATION = math.maxinteger
local PressCheckTimer = false
local LocalHandled = UE4.UWidgetBlueprintLibrary.Handled()
local LocalUnhandled = UE4.UWidgetBlueprintLibrary.Unhandled()

function UMG_PlantAcquisitionItem_C:OnConstruct()
  self.bAvailable = false
  self.itemQuality = 0
  self.bHadBeenEnterLongPressSinceRelease = false
  self.ReduceBtn.OnPressed:Add(self, self.OnPressReduceButton)
  self.ReduceBtn.OnReleased:Add(self, self.OnReleaseReduceButton)
  if PRESS_HOLD_DURATION == math.maxinteger then
    local config = _G.DataConfigManager:GetHomeGlobalConfig("home_plant_sell_press_start")
    if config and config.num then
      PRESS_HOLD_DURATION = config.num / 10000
    end
  end
end

function UMG_PlantAcquisitionItem_C:OnDestruct()
  self:StopPressCheckTimer()
  self.ReduceBtn.OnPressed:Remove(self, self.OnPressReduceButton)
  self.ReduceBtn.OnReleased:Remove(self, self.OnReleaseReduceButton)
end

function UMG_PlantAcquisitionItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self:UpdateUI()
  self:OnItemSelected(false, true)
end

function UMG_PlantAcquisitionItem_C:OnDespawn()
  self:PlayAnimation(self.normal)
  self:StopPressCheckTimer()
end

function UMG_PlantAcquisitionItem_C:OnItemSelected(_bSelected, bScrolled)
  if not self.uiData then
    return
  end
  local previousSelected = self._isSelected
  self._isSelected = _bSelected
  if _bSelected then
    if not bScrolled then
      if not previousSelected then
        self:StopAnimation(self.normal)
        self:PlayAnimation(self.change)
        if self.uiData.callbackCaller and self.uiData.callbackFunc and self.uiData.callbackFunc1 then
          self.uiData.callbackFunc(self.uiData.callbackCaller, self, self.index)
        end
      end
    else
      self:StopAnimation(self.normal)
      self:PlayAnimation(self.change, 0, 1, UE4.EUMGSequencePlayMode.Forward, 10)
    end
    self:UpdateFontOutline(true)
  else
    self:StopAnimation(self.change)
    self:StopAnimation(self.change_loop)
    self:PlayAnimation(self.normal)
    self:UpdateFontOutline(false)
  end
end

function UMG_PlantAcquisitionItem_C:OnDespawn()
  self:StopAnimation(self.change)
  self:StopAnimation(self.change_loop)
  self:PlayAnimation(self.normal)
  self:UpdateFontOutline(false)
end

function UMG_PlantAcquisitionItem_C:OnDeactive()
end

function UMG_PlantAcquisitionItem_C:UpdateUI()
  if not self.uiData then
    return
  end
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.itemId, true)
  if bagItemConf then
    self.itemQuality = bagItemConf.item_quality
    UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
    self.Selected:SetPath(string.format(UEPath.Fmt_PlantAcquisitionQualityBg, self.itemQuality, self.itemQuality))
    self.Icon:SetPath(bagItemConf.icon)
  end
  local iconPath = ""
  local normalShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId, true)
  if normalShopConf and normalShopConf.Type == Enum.GoodsType.GT_VITEM and normalShopConf.item_id then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(normalShopConf.item_id, true)
    if vItemConf and vItemConf.iconPath then
      iconPath = vItemConf.iconPath
    end
  end
  self.CurrencyIcon:SetPath(iconPath)
  self.Title:SetText(self.uiData.priceNum .. (LuaText.plant_sell_price_unit or ""))
  self:UpdateUIProperty()
end

function UMG_PlantAcquisitionItem_C:UpdateUIProperty()
  if not self.uiData then
    return
  end
  self:SetAvailable(self.uiData.currentOwnNum > 0)
  self.QuantityText:SetText(string.format("%d/%d", self.uiData.selectedNum, self.uiData.currentOwnNum))
  local font = self.QuantityText.Font
  if self.uiData.currentOwnNum / 1000 > 1 then
    font.Size = 21
  else
    font.Size = 26
  end
  self.QuantityText:SetFont(font)
  self.Title_1:SetText(self.uiData.currentOwnNum)
  if self.uiData.selectedNum > 0 then
    self.ReduceBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Quantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ReduceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PlantAcquisitionItem_C:SetAvailable(bAvailable)
  self.bAvailable = bAvailable
  if bAvailable then
    self:SetClickable(true)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetClickable(false)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Visible)
    if self._isSelected then
      Log.Error("UMG_PlantAcquisitionItem_C:SetAvailable set a item not available while selecting it!")
    end
  end
end

function UMG_PlantAcquisitionItem_C:OnAnimationFinished(anim)
  if anim == self.change then
    self:PlayAnimation(self.change_loop, 0, 99999)
  end
end

function UMG_PlantAcquisitionItem_C:OnMouseButtonDown(MyGeometry, MouseEvent)
  if not self.bAvailable then
    return LocalUnhandled
  end
  self.bHadBeenEnterLongPressSinceRelease = false
  self:StartPressCheckTimer(true)
  return LocalUnhandled
end

function UMG_PlantAcquisitionItem_C:OnMouseButtonUp(MyGeometry, MouseEvent)
  if not self.bAvailable then
    return LocalUnhandled
  end
  local hadBeenEnterLongPress = self:StopPressCheckTimer()
  if not hadBeenEnterLongPress and not self.bHadBeenEnterLongPressSinceRelease then
    self:ChangeSelectNum(1)
  end
  self.bHadBeenEnterLongPressSinceRelease = false
  return LocalUnhandled
end

function UMG_PlantAcquisitionItem_C:OnMouseLeave(MouseEvent)
  if not self.bAvailable then
    return LocalUnhandled
  end
  self:StopPressCheckTimer()
  return LocalUnhandled
end

function UMG_PlantAcquisitionItem_C:OnMouseMove(MyGeometry, MouseEvent)
  if self.bLongPressActive then
    return LocalHandled
  else
    return LocalUnhandled
  end
end

function UMG_PlantAcquisitionItem_C:StartPressCheckTimer(bIncrease)
  bIncrease = not not bIncrease
  if not self.uiData then
    return
  end
  self:InitLongPressParam()
  if 0 == INCREASE_NUM then
    return
  end
  if bIncrease and self.uiData.selectedNum == self.uiData.currentOwnNum or not bIncrease and 0 == self.uiData.selectedNum then
    return
  end
  self.bOwnPressCheckTimer = true
  self.bIncrease = bIncrease
  self:StartPressCheckTimerInternal(bIncrease)
end

function UMG_PlantAcquisitionItem_C:StartPressCheckTimerInternal(bIncrease)
  PressCheckTimer = _G.TimerManager:CreateTimer(self, "UMG_PlantAcquisitionItem_C", 9999, self.OnPressing, self.OnTimerComplete, 0)
end

function UMG_PlantAcquisitionItem_C:StopPressCheckTimer()
  if not self.bOwnPressCheckTimer then
    return false
  end
  local hadBeenEnterLongPress = self:ExitLongPress()
  self.bOwnPressCheckTimer = false
  self:StopPressCheckTimerInternal()
  return hadBeenEnterLongPress
end

function UMG_PlantAcquisitionItem_C:StopPressCheckTimerInternal()
  if PressCheckTimer then
    _G.TimerManager:RemoveTimer(PressCheckTimer)
    PressCheckTimer = false
  end
end

function UMG_PlantAcquisitionItem_C:OnPressing()
  if not PressCheckTimer then
    return
  end
  if not self.bLongPressActive and PressCheckTimer.duration - PressCheckTimer.leftTime > PRESS_HOLD_DURATION then
    self:EnterLongPress(self.bIncrease)
    self:TriggerLongPressAction(self.bIncrease)
  end
  if self.bLongPressActive then
    self.sinceLastAction = self.sinceLastAction + PressCheckTimer.elapsedTime * 1000
    if self.bIncrease then
      if self.sinceLastAction > INCREASE_INTERVAL then
        self.sinceLastAction = self.sinceLastAction - INCREASE_INTERVAL
        self:TriggerLongPressAction(self.bIncrease)
      end
    elseif self.sinceLastAction > DECREASE_INTERVAL then
      self.sinceLastAction = self.sinceLastAction - DECREASE_INTERVAL
      self:TriggerLongPressAction(self.bIncrease)
    end
  end
end

function UMG_PlantAcquisitionItem_C:InitLongPressParam()
  if 0 ~= INCREASE_NUM then
    return
  end
  local config = _G.DataConfigManager:GetHomeGlobalConfig("home_plant_sell_press")
  if config and config.numList and #config.numList >= 2 then
    INCREASE_INTERVAL = config.numList[1] / 10
    INCREASE_NUM = config.numList[2]
    DECREASE_INTERVAL = config.numList[1] / 10
    DECREASE_NUM = config.numList[2]
  end
end

function UMG_PlantAcquisitionItem_C:EnterLongPress(bIncrease)
  if bIncrease and self.ParentView then
    self.ParentView:OnChildItemClick(self, self.index - 1, true)
  end
  self.bLongPressActive = true
  self.sinceLastAction = 0
  self.bHadBeenEnterLongPressSinceRelease = true
end

function UMG_PlantAcquisitionItem_C:ExitLongPress()
  local longPressHadActive = self.bLongPressActive
  self.bLongPressActive = false
  self.sinceLastAction = 0
  return longPressHadActive
end

function UMG_PlantAcquisitionItem_C:TriggerLongPressAction(bIncrease)
  local ChangeSelectedNumMakeSense = true
  if bIncrease then
    ChangeSelectedNumMakeSense = self:ChangeSelectNum(INCREASE_NUM)
    if self.uiData.selectedNum == self.uiData.currentOwnNum then
      self:StopPressCheckTimer()
    end
  else
    ChangeSelectedNumMakeSense = self:ChangeSelectNum(-DECREASE_NUM)
    if 0 == self.uiData.selectedNum then
      self:StopPressCheckTimer()
    end
  end
  if not ChangeSelectedNumMakeSense then
    self:StopPressCheckTimer()
  end
end

function UMG_PlantAcquisitionItem_C:OnPressCheckTimerComplete()
  Log.Error("UMG_PlantAcquisitionItem_C:OnPressCheckTimerComplete press too long!!")
  self:ExitLongPress()
end

function UMG_PlantAcquisitionItem_C:PreprocessDeltaChange(intendDeltaChange)
  if not intendDeltaChange then
    return
  end
  local prevNum = self.uiData.selectedNum
  local newNum = math.clamp(self.uiData.selectedNum + intendDeltaChange, 0, self.uiData.currentOwnNum)
  if self.uiData.callbackFunc2 and self.uiData.callbackCaller then
    return self.uiData.callbackFunc2(self.uiData.callbackCaller, self.index, newNum - prevNum)
  end
end

function UMG_PlantAcquisitionItem_C:ChangeSelectNum(intendDeltaChange)
  local finalIntendDeltaChange = self:PreprocessDeltaChange(intendDeltaChange)
  if not finalIntendDeltaChange then
    return
  end
  local prevNum = self.uiData.selectedNum
  self.uiData.selectedNum = math.clamp(self.uiData.selectedNum + finalIntendDeltaChange, 0, self.uiData.currentOwnNum)
  if self.uiData.callbackFunc1 and self.uiData.callbackCaller then
    self.uiData.callbackFunc1(self.uiData.callbackCaller, self.index, self.uiData.selectedNum - prevNum, prevNum)
  end
  self:UpdateUIProperty()
  local finalDeltaChange = self.uiData.selectedNum - prevNum
  if prevNum ~= self.uiData.selectedNum then
    if finalDeltaChange > 0 then
      _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_PlantAcquisitionItem_C:ChangeSelectNum_ADD")
    else
      _G.NRCAudioManager:PlaySound2DAuto(41401008, "UMG_PlantAcquisitionItem_C:ChangeSelectNum_SUB")
    end
  end
  return 0 ~= finalDeltaChange, finalDeltaChange
end

function UMG_PlantAcquisitionItem_C:OnPressReduceButton()
  if not self.bAvailable then
    return
  end
  self.bHadBeenEnterLongPressSinceRelease = false
  self:StartPressCheckTimer(false)
  self:PlayAnimation(self.change_Press)
end

function UMG_PlantAcquisitionItem_C:OnReleaseReduceButton()
  local hadBeenEnterLongPress = self:StopPressCheckTimer()
  if not hadBeenEnterLongPress and not self.bHadBeenEnterLongPressSinceRelease then
    self:ChangeSelectNum(-1)
  end
  self:PlayAnimation(self.change_Up)
  self.bHadBeenEnterLongPressSinceRelease = false
end

function UMG_PlantAcquisitionItem_C:OpItem(opType, ...)
  if 1 == opType then
    local randomNum = (...)
    self:PlayEnterAnim(randomNum)
  end
end

function UMG_PlantAcquisitionItem_C:PlayEnterAnim(randomNum)
  if not randomNum then
    return
  end
  if 1 == randomNum then
    self:PlayAnimation(self.In_1)
  elseif 2 == randomNum then
    self:PlayAnimation(self.In_2)
  elseif 3 == randomNum then
    self:PlayAnimation(self.In_3)
  end
end

function UMG_PlantAcquisitionItem_C:UpdateFontOutline(bQualityColor)
  local qualityColor = "#DBD5C8FF"
  qualityColor = bQualityColor and self:GetFontOutlineColor(self.itemQuality) or qualityColor
  local linearColor = UE4.UNRCStatics.HexToLinearColor(qualityColor)
  local font = self.Title_1.Font
  font.OutlineSettings.OutlineColor = linearColor
  self.Title_1:SetFont(font)
  self.BackpackOutline:SetColorAndOpacity(linearColor)
end

function UMG_PlantAcquisitionItem_C:GetFontOutlineColor(quality)
  if 1 == quality or 0 == quality then
    return "#928f87"
  elseif 2 == quality then
    return "#569510"
  elseif 3 == quality then
    return "#3184a2"
  elseif 4 == quality then
    return "#7c56e1"
  elseif 5 == quality or 6 == quality then
    return "#e38e08"
  end
end

return UMG_PlantAcquisitionItem_C
