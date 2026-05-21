require("UnLuaEx")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleTutorialGuideModuleEvent = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Delegate = require("Utils.Delegate")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_BattleBallEntry_C = NRCUmgClass:Extend("UMG_BattleBallEntry_C")
local Data = NRCClass:Extend("UMG_BattleBallEntry_C.Data")
UMG_BattleBallEntry_C.Data = Data

function Data:Ctor(id, conf_id, gid, number)
  self.id = id
  self.conf_id = conf_id
  self.gid = gid
  self.num = number
  self.isSelected = false
  local ballConf = _G.DataConfigManager:GetBallConf(conf_id or 0, true)
  self.ball_list_priority = ballConf and ballConf.ball_list_priority or -1
end

function Data:IsValid()
  return self.id >= 0 and self.conf_id >= 0 and self.gid >= 0
end

function UMG_BattleBallEntry_C:Initialize(Initializer)
  self.battleManager = _G.BattleManager
  self.ballData = nil
  self.ballBagCfg = nil
end

function UMG_BattleBallEntry_C:Construct()
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_BALL, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.UI_INSTANT_UPDATE_BALL_NUM)
  self.props = {}
  self._timer = 0
  self._longPressThreshold = BattleConst.ItemLongPressThreshold
  self._pressed = false
  self._isSelect = false
  self.curOperateType = BattleEnum.Operation.ENUM_CATCH
  self.TouchButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Forbid:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_BattleBallEntry_C:Destruct()
  self:CancelOpenAnimDelay()
  _G.BattleEventCenter:UnBind(self)
  NRCUmgClass.Destruct(self)
end

function UMG_BattleBallEntry_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_BALL then
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:OnOperatePanelChanged(...)
  elseif eventName == BattleEvent.UI_INSTANT_UPDATE_BALL_NUM then
    self:UpdateBallNum(...)
  end
end

function UMG_BattleBallEntry_C:OnOperatePanelChanged(operateType)
  self.curOperateType = operateType
  if operateType == BattleEnum.Operation.ENUM_CATCH then
  else
    self:ResetPressState()
    if self:IsShowSelected() then
      self:StopAndPlayAnim(self.Btn_Notclick)
    end
  end
end

function UMG_BattleBallEntry_C:_OnItemPressed()
  self._pressed = true
  self._timer = self._longPressThreshold
  self.CanvasPanel_0:SetRenderTransformPivot(UE.FVector2D(0.5, 0.5))
end

function UMG_BattleBallEntry_C:_OnItemRelease()
  if self._pressed and self:IsBallDataValid() then
    self:DoClick()
  end
  self._pressed = false
  if self.OpenCommonTips and self:IsPCMode() then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  end
end

function UMG_BattleBallEntry_C:OnItemPressed()
  self:_OnItemPressed()
end

function UMG_BattleBallEntry_C:OnItemRelease()
  self:_OnItemRelease()
end

function UMG_BattleBallEntry_C:Tick(geometry, deltaTime)
  if self._pressed and self.fatherList and self.fatherList:IsUserScrolling() then
    self:_OnItemPressed()
  end
  if not self._pressed then
    return
  end
  self._timer = self._timer - deltaTime
  if self._timer <= 0 then
    self:DoLongClick()
  end
end

function UMG_BattleBallEntry_C:RefreshBallSelected()
  if not self.ballData or not self.ballData.isSelected then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_BattleBallEntry_C:OnClickedBall")
    if self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.Visible or self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NubBg:SetColorAndOpacity(UE4.FLinearColor(0.904661, 0.854993, 0.752942, 1))
      self.Bg:SetRenderOpacity(1)
    end
  else
    self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NubBg:SetVisibility(UE4.ESlateVisibility.Visible)
    self:StopAndPlayAnim(self.Btn_Click)
  end
end

function UMG_BattleBallEntry_C:OnAnimationFinished(Animation)
  if self.curAnim == Animation then
    self.curAnim = nil
  end
  if self.Btn_Click == Animation and self:IsBallDataValid() and self.ballData.isSelected then
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif (self.open == Animation or self.Change_open == Animation) and self:IsBallDataValid() and self.ballData.isSelected then
    if not self:IsShowSelected() then
      self:StopAndPlayAnim(self.Btn_Click)
    end
  elseif self.close == Animation or self.Change_close == Animation then
    local tweenOutCallback = self.tweenOutCallback
    self.tweenOutCallback = nil
    if tweenOutCallback then
      tweenOutCallback()
    end
  end
end

function UMG_BattleBallEntry_C:IsShowSelected()
  return self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.Visible or self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible
end

function UMG_BattleBallEntry_C:GetBattleGuidanceLocationByIndex(index)
  if 1 == index then
    return Enum.BattleGuidanceLocation.BGL_CAPTURE_1
  end
  return 0
end

function UMG_BattleBallEntry_C:DoClick()
  if self.bCanCatch == false then
  end
  if self.curOperateType == BattleEnum.Operation.ENUM_CATCH then
    local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CATCH_IN_WORLD, true, true)
    if isBan then
      return
    end
    if self.ballData then
      local eventParam = self:GetBattleGuidanceLocationByIndex(self.ballData.index)
      if eventParam then
        _G.NRCEventCenter:DispatchEvent(BattleTutorialGuideModuleEvent.BtnClickEvent, eventParam)
      end
      _G.NRCModuleManager:DoCmd(NewbieGuideModuleCmd.BtnClick, "BattleCardGuide")
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, self.ballData)
    end
  end
end

function UMG_BattleBallEntry_C:DoLongClick()
  self._pressed = false
  self._timer = 0
  local props = self.props
  local disableDoLongClick = props and props.disableDoLongClick
  local enableDoLongClick = not disableDoLongClick
  do
    local locationX, locationY, bPressed = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(0)
    local startLocation = self.isTouching and self.touchStartPosition or nil
    local startLocationX = startLocation and startLocation.X
    if locationX and startLocationX then
      local diff = math.abs(locationX - startLocationX)
      local threshold = BattleConst.BallOperationScrollToAnotherPageThreshold / 2
      if enableDoLongClick and diff > threshold then
        enableDoLongClick = false
      end
    end
  end
  if self:IsBallDataValid() and enableDoLongClick then
    if self:IsPCMode() then
      local triggerInputActionName = _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.GetTriggerInputActionName)
      if not triggerInputActionName then
        _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "BattleBallEntryLongPressed")
      end
    end
    self.OpenCommonTips = true
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ballData.conf_id, _G.Enum.GoodsType.GT_BAGITEM, false, 0, 0, true, nil, self.ballData.num, self, self.OnCommonTipClose, self.OnCommonTipOpen)
  end
end

function UMG_BattleBallEntry_C:OnSelectExtraBall(ballGID)
  if self.curOperateType == BattleEnum.Operation.ENUM_CATCH and self.ballData and self.ballData.gid == ballGID then
    self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:StopAndPlayAnim(self.Btn_Click)
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallId = self.ballData.id
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallGID = self.ballData.gid
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, self.ballData)
    return true
  end
  return false
end

function UMG_BattleBallEntry_C:SelectCatchBall()
  if self.curOperateType == BattleEnum.Operation.ENUM_CATCH then
    self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:StopAndPlayAnim(self.Btn_Click)
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallId = self.ballData.id
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallGID = self.ballData.gid
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, self.ballData)
    return true
  end
  return false
end

function UMG_BattleBallEntry_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_BattleBallEntry_C:SetProps(nextProps)
  local prevProps = self.props
  self.props = nextProps
  self:RenderWidget(prevProps, nextProps)
end

function UMG_BattleBallEntry_C:RenderWidget(prevProps, nextProps)
  local prevData = prevProps and prevProps.ballData
  local nextData = nextProps and nextProps.ballData
  if prevData ~= nextData then
    self:SetData(nextData)
  end
end

function UMG_BattleBallEntry_C:SetData(itemData)
  Log.Debug("UMG_BattleBallEntry_C SetData")
  if not itemData or not itemData:IsValid() then
    self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BallIcon:CancelLoad()
    self.BallIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NumTxt:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NubBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ballData = itemData
    self.PCKey:SetKeyVisibility(false)
    self.Sign:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  else
    self:SetRenderOpacity(1)
    self.Bg:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BallIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NumTxt:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NubBg:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ballData = itemData
  if self.ballData then
    self.ballBagCfg = _G.DataConfigManager:GetBagItemConf(self.ballData.conf_id)
    if not self.ballBagCfg then
      Log.Error("UMG_BattleBallEntry_C Bag Conf not found " .. self.ballData.conf_id)
    else
      self.BallIcon:SetPath(NRCUtils:FormatConfIconPath(self.ballBagCfg.icon, _G.UIIconPath.BagItemPath))
      self.emptyImage:SetPath(NRCUtils:FormatConfIconPath(self.ballBagCfg.icon, _G.UIIconPath.BagItemPath))
    end
  end
  self.NumTxt:SetText(tostring(self.ballData.num))
  if self.ballData.sign then
    self.Sign:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Sign:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RefreshEmptyAndBanImage()
end

function UMG_BattleBallEntry_C:UpdateBallNum(BallIdNumMap)
  if not self.ballData or not self.ballData.id then
    return
  end
  local newNum = BallIdNumMap[self.ballData.id]
  if not newNum then
    return
  end
  self.ballData.num = newNum
  self.NumTxt:SetText(tostring(self.ballData.num))
end

function UMG_BattleBallEntry_C:HidePoint()
  if self.point0 then
    self.point0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.point1 then
    self.point1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.point2 then
    self.point2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.point3 then
    self.point3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BattleBallEntry_C:DelayPlayAnim(_IsOpen, i)
  self.tweenOutCallback = nil
  self:StopCurrentAnimation()
  self:CancelOpenAnimDelay()
  if _IsOpen then
    self:SetRenderOpacity(0)
  end
  local interval = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenInterval or 0.04
  self.playOpenAnimDelayHandler = _G.DelayManager:DelaySeconds(i * interval, self.PlayOpenAnimation, self, _IsOpen)
end

function UMG_BattleBallEntry_C:PlayOpenAnimation(_IsOpen)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:HidePoint()
  self.CanvasPanel_0:SetRenderTranslation(UE.FVector2D(0, 0))
  self.CanvasPanel_0:SetRenderScale(UE4.FVector2D(1, 1))
  self:SetRenderOpacity(1)
  self:CancelOpenAnimDelay()
  if _IsOpen then
    self:RandVisiblePoint()
    local openAnimSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenAnimSpeedRate or 1
    if BattleUtils.IsMainWindowChangingBetweenSubPanels() then
      self:StopAndPlayAnim(self.Change_open, 0, 1, 0, openAnimSpeedRate)
    else
      self:StopAndPlayAnim(self.open, 0, 1, 0, openAnimSpeedRate)
    end
  elseif BattleUtils.IsMainWindowChangingBetweenSubPanels() then
    self:StopAndPlayAnim(self.Change_close)
  else
    self:StopAndPlayAnim(self.close)
  end
end

function UMG_BattleBallEntry_C:IsAnyOpenAnimationPlaying()
  return self:IsAnimationPlaying(self.open) or self:IsAnimationPlaying(self.Change_open)
end

function UMG_BattleBallEntry_C:StopCurrentAnimation()
  if not self.curAnim then
    return
  end
  self.curAnim = nil
  self:StopAllAnimations()
end

function UMG_BattleBallEntry_C:RandVisiblePoint()
  if self.ballData then
    local Rand = math.random(0, 3)
    if self["point" .. Rand] then
      self["point" .. Rand]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_BattleBallEntry_C:SetCanCatch(bCanCatch, CatchMsg)
  if not UE4.UObject.IsValid(self) then
    return
  end
  self.CatchMsg = CatchMsg
  self.bCanCatch = bCanCatch
  self:RefreshEmptyAndBanImage()
end

function UMG_BattleBallEntry_C:RefreshEmptyAndBanImage()
  local bCanCatch = true
  if self.bCanCatch ~= nil then
    bCanCatch = self.bCanCatch
  end
  local catchMsg = self.CatchMsg
  local ballData = self.ballData
  local banImageVisibility = UE4.ESlateVisibility.Collapsed
  local emptyImageVisibility = UE4.ESlateVisibility.Collapsed
  local emptyImageOpacity = 1
  if not bCanCatch then
    banImageVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
    emptyImageVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  if not ballData or not ballData:IsValid() then
    banImageVisibility = UE4.ESlateVisibility.Collapsed
    emptyImageVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
    emptyImageOpacity = 0.2
  end
  self.emptyImage:SetVisibility(emptyImageVisibility)
  self.emptyImage:SetRenderOpacity(emptyImageOpacity)
  self.BanImage:SetVisibility(banImageVisibility)
end

function UMG_BattleBallEntry_C:OnTouchStarted(MyGeometry, InTouchEvent)
  self:_OnItemPressed()
  self.isTouching = true
  local locationX, locationY, bPressed = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(0)
  local location = UE.FVector2D(locationX, locationY)
  self.touchStartPosition = location
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_BattleBallEntry_C:OnTouchEnded(MyGeometry, InTouchEvent)
  self.isTouching = false
  self:_OnItemRelease()
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_BattleBallEntry_C:ResetPressState()
  self._pressed = false
end

function UMG_BattleBallEntry_C:IsBallDataValid()
  return self.ballData and self.ballData:IsValid()
end

function UMG_BattleBallEntry_C:StopAndPlayAnim(InAnimation, ...)
  if self.nextAnim ~= nil or self.curAnim == InAnimation then
    return
  end
  self:CancelOpenAnimDelay()
  self.nextAnim = InAnimation
  if self.curAnim then
    self:StopCurrentAnimation()
  end
  self:PlayAnimation(InAnimation, ...)
  self.curAnim = InAnimation
  self.nextAnim = nil
end

function UMG_BattleBallEntry_C:OnCommonTipOpen()
  if self.isTouching then
    self:OnItemRelease()
  end
  self.isTouching = false
end

function UMG_BattleBallEntry_C:OnCommonTipClose()
  self.OpenCommonTips = false
end

function UMG_BattleBallEntry_C:CancelOpenAnimDelay()
  if self.playOpenAnimDelayHandler then
    self:SetRenderOpacity(1)
    _G.DelayManager:CancelDelayById(self.playOpenAnimDelayHandler)
  end
  self.playOpenAnimDelayHandler = nil
end

return UMG_BattleBallEntry_C
