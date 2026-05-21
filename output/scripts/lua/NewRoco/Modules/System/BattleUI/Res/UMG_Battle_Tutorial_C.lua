local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Battle_Tutorial_C = _G.NRCPanelBase:Extend("UMG_Battle_Tutorial_C")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local TutorialStep = {
  None = 0,
  Step1 = 1,
  Step2 = 2,
  Step3 = 3
}

function UMG_Battle_Tutorial_C:OnActive(num, guideWidget)
  self.battleManager = _G.BattleManager
  NRCModuleManager:DoCmd(BattleUIModuleCmd.Close_Information_Recording)
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.CloseAllBattleChatRelatedUI, true)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleChangePetConfirmPanel)
  self.guideWidget = guideWidget
  self.bEnabledDebug = _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GetDebugEnabled)
  self.currentStep = TutorialStep.None
  self:BindInputAction()
  self:OnAddEventListener()
  if 1 == num then
    self:OnGetContent()
  elseif 2 == num then
    self:CallOutNameTutorial2(true)
  end
  if UE4Helper.IsPCMode() then
    self.CallNameTutorial1:SetRenderScale(UE4.FVector2D(0.82, 0.82))
    self.CallNameTutorial2:SetRenderScale(UE4.FVector2D(0.82, 0.82))
    self.CallNameTutorial2_1:SetRenderScale(UE4.FVector2D(0.82, 0.82))
    local cullSetting = self.Background_2.CullSetting
    cullSetting.CullType = UE4.EImageCulledType.Circle
    cullSetting.CircleRadius = 145
    self.Background_2:SetCullSetting(cullSetting)
  end
end

function UMG_Battle_Tutorial_C:UpdateGuidePositonInternal(guideWidget, backgroundWidget, tutorialPanelWidget)
  if not guideWidget or not UE4.UObject.IsValid(guideWidget) then
    return
  end
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(self)
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(self)
  local realViewportSize = viewportSize / viewportScale
  local geometry = guideWidget:GetPaintSpaceGeometry()
  local position = UE4.UNRCStatics.GetWidgetViewportPosition(guideWidget)
  local localSize = UE4.USlateBlueprintLibrary.GetLocalSize(geometry)
  local absoluteSize = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geometry)
  local realSize = UE4.FVector2D(absoluteSize.X, absoluteSize.Y)
  if realSize.X <= 0 then
    realSize.X = 100
  end
  if realSize.Y <= 0 then
    realSize.Y = 100
  end
  realSize = realSize / viewportScale
  local centerPosition = position + realSize / 2.0
  if centerPosition == backgroundWidget.CullOffset then
    return
  end
  local info = string.format("%s, %s, %s, %s, %s, %s, %s, %s", position, centerPosition, localSize, absoluteSize, realSize, viewportSize, realViewportSize, viewportScale)
  if self:CheckOutOfViewport(centerPosition, realViewportSize) then
    Log.Debug("UMG_Battle_Tutorial_C:UpdateGuidePositonInternal position is out of screen", info)
    if self.bEnabledDebug then
      centerPosition = viewportSize / 2.0
    end
  else
    Log.Debug("UMG_Battle_Tutorial_C:UpdateGuidePositonInternal", info)
  end
  backgroundWidget:SetCullOffset(centerPosition)
  local cullSetting = backgroundWidget.CullSetting
  cullSetting.CullType = UE4.EImageCulledType.Circle
  local addRadius = 40
  if not UE4Helper.IsPCMode() then
    addRadius = addRadius / 0.82
  end
  cullSetting.CircleRadius = math.max(realSize.X, realSize.Y) / 2.0 + addRadius
  backgroundWidget:SetCullSetting(cullSetting)
  local focusSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(tutorialPanelWidget)
  if focusSlot then
    focusSlot:SetPosition(centerPosition)
  end
end

function UMG_Battle_Tutorial_C:CheckOutOfViewport(position, viewport)
  local function pointOutOfViewport(point)
    if point.X < 0 or point.X > viewport.X or point.Y < 0 or point.Y > viewport.Y then
      return true
    end
    return false
  end
  
  if pointOutOfViewport(position) then
    return true
  end
  return false
end

function UMG_Battle_Tutorial_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.BattleScreenClick, self.HandleScreenClick)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.FinalBattleCloseTutorial, self.HandleScreenClick)
end

function UMG_Battle_Tutorial_C:OnAddEventListener()
  self:AddButtonListener(self.CallTutorialBtn1, self.CallOutNameTutorial2)
  self:AddButtonListener(self.CallTutorialBtn2, self.CloseCallOutNameTutorial2)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Tutorial_C", self, _G.NRCGlobalEvent.BattleScreenClick, self.HandleScreenClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Tutorial_C", self, _G.NRCGlobalEvent.FinalBattleCloseTutorial, self.HandleScreenClick)
end

function UMG_Battle_Tutorial_C:CallOutNameTutorial1()
  self:UpdateGuidePositonInternal(self.guideWidget, self.Background, self.CallNameTutorial1)
  self:ChangeWishPowerBgByCallNameTutorialIndex(1)
  NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattleUIBackpackTips)
  self.CallNameTutorialPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.Point_R)
  self:LimitInputAction("IA_BattleBagStart", "CallOutNameTutorial2")
end

function UMG_Battle_Tutorial_C:CallOutNameTutorial2(bFinalBattleEnergyIsFull)
  self:UploadData()
  self:LimitInputAction("IA_BattleSelectItemStart_1", "CloseCallOutNameTutorial2")
  self.bFinalBattleEnergyIsFull = bFinalBattleEnergyIsFull
  _G.BattleEventCenter:Dispatch(BattleEvent.SimulateClickBag)
end

function UMG_Battle_Tutorial_C:ShowTutorial2(guideWidget)
  if self.bHasShowTutorial2 and not self.bFinalBattleEnergyIsFull then
    return
  end
  if self.currentStep == TutorialStep.Step3 then
    return
  end
  if BattleUtils.IsFinalBattleP1() then
    if 2 == self.battleManager.battleRuntimeData.roundIndex then
      self.guideWidget = guideWidget
      self:UpdateGuidePositonInternal(self.guideWidget, self.Background_1, self.CallNameTutorial2)
      self:ChangeWishPowerBgByCallNameTutorialIndex(2)
      self.CallNameTutorialPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CallNameTutorialPanel2:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.Point_L)
      self.bHasShowTutorial2 = true
      self.currentStep = TutorialStep.Step2
    elseif self.bFinalBattleEnergyIsFull then
      self.guideWidget = guideWidget
      self:UpdateGuidePositonInternal(self.guideWidget, self.Background_1, self.CallNameTutorial2)
      self:ChangeWishPowerBgByCallNameTutorialIndex(2)
      self.CallNameTutorialPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CallNameTutorialPanel2:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.Point_L)
      self.bHasShowTutorial2 = true
      self.currentStep = TutorialStep.Step2
    end
  end
end

function UMG_Battle_Tutorial_C:CloseCallOutNameTutorial2()
  if self.currentStep ~= TutorialStep.Step2 then
    return
  end
  NRCEventCenter:DispatchEvent(BattlePerformEvent.SimulateClickItem0)
  self.CallNameTutorialPanel2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local curRound = _G.BattleManager.curRound
  if 2 == curRound then
    self:ChangeWishPowerBgByCallNameTutorialIndex(3)
    self.CallNameTutorialPanel3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Point_Middle)
    self.currentStep = TutorialStep.Step3
    self:LimitInputAction("IA_BattleSure", "HandleScreenClick")
  else
    self.currentStep = TutorialStep.None
    self:CancelAllLimitInputAction()
    self:OnClose()
  end
end

function UMG_Battle_Tutorial_C:UploadData()
  local List = ProtoMessage:newPointList()
  local point = ProtoMessage:newPoint()
  point.pos.x = 0
  table.insert(List.points, point)
end

function UMG_Battle_Tutorial_C:DownloadData()
end

function UMG_Battle_Tutorial_C:OnGetContent(Data)
  self:CallOutNameTutorial1()
end

function UMG_Battle_Tutorial_C:HandleScreenClick()
  if self.currentStep ~= TutorialStep.Step3 then
    return
  end
  if self.CallNameTutorialPanel3:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.CallNameTutorialPanel3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.currentStep = TutorialStep.None
  self:CancelAllLimitInputAction()
end

function UMG_Battle_Tutorial_C:OnAnimationFinished(anim)
  if anim == self.Point_R then
    self:PlayAnimation(self.Point_R_loop, 0, 9999)
  elseif anim == self.Point_L then
    self:PlayAnimation(self.Point_L_loop, 0, 9999)
  elseif anim == self.Point_Middle then
    self:PlayAnimation(self.Point_M_loop, 0, 9999)
  end
end

function UMG_Battle_Tutorial_C:OnPCTriggerTutorial()
  local invokeFunc = self.PCInvokeFunctionName
  if not invokeFunc then
    return
  end
  self.PCInvokeFunctionName = nil
  local funInst = self[invokeFunc]
  if funInst then
    funInst(self)
  end
end

function UMG_Battle_Tutorial_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_BattleTutorial")
  if mappingContext then
    mappingContext:BindAction("IA_BattleTutorial_0", self, "OnPCTriggerTutorial")
  end
end

function UMG_Battle_Tutorial_C:LimitInputAction(allowAction, triggerFunctionName)
  self.PCInvokeFunctionName = nil
  local mappingContext = self:GetInputMappingContext("IMC_BattleTutorial")
  if mappingContext then
    local bindKey = _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.GetMappingKey, allowAction)
    if bindKey then
      mappingContext:EnableInputMappingContext()
      mappingContext:ChangeKey("IA_BattleTutorial_0", bindKey)
      self.PCInvokeFunctionName = triggerFunctionName
    end
  end
end

function UMG_Battle_Tutorial_C:CancelAllLimitInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_BattleTutorial")
  if mappingContext then
    mappingContext:DisableInputMappingContext()
  end
end

function UMG_Battle_Tutorial_C:ChangeWishPowerBgByCallNameTutorialIndex(index)
  if 1 == index then
    self.Background:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif 2 == index then
    self.Background:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Background_1:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif 3 == index then
    self.Background_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Background_2:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

return UMG_Battle_Tutorial_C
