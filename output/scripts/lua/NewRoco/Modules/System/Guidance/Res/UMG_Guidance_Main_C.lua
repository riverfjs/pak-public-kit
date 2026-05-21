local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local Base = require("Core.NRCModule.NRCPanelBase")
local listItemOutOfBoundTolerance = 0.35
local GuidanceFocusControlActionsType = {ScrollLock = 1}
local UMG_Guidance_Main_C = Base:Extend("UMG_Guidance_Main_C")

function UMG_Guidance_Main_C:OnConstruct()
  self.bHasStarted = false
  self.tickedInterval = 0.1
  self.tickedTime = 0
  self.bStrongGuide = false
  self.bOnTop = false
  self.bTargetVisible = false
  self.controlActions = {}
end

function UMG_Guidance_Main_C:OnActive(config, style, targetWidget, panelData, pathWidgets, isInBattle)
  if not style then
    return
  end
  self.bEnabledDebug = _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GetDebugEnabled)
  self.config = config
  self.style = style
  self.targetWidget = targetWidget
  self.targetPanelData = panelData
  self.pathWidgets = pathWidgets or {}
  self.bStrongGuide = style.strong_guide
  self.isInBattle = isInBattle
  if pathWidgets and pathWidgets[#pathWidgets] ~= targetWidget then
    table.insert(self.pathWidgets, targetWidget)
  end
  self:CheckIsInBattle()
  self:InitFromFocusConfigs()
  if _G.UE4Helper.IsPCMode() then
    self.resX, self.resY = UE4.UNRCQualityLibrary.GetPCResolution()
    self.windowsPositionInScreen = UE4.UNRCTUIStatics.GetSizeInScreen()
    self.windowsSizeInScreen = UE4.UNRCTUIStatics.GetPositionInScreen()
  else
  end
  self.OnPcCloseHandler = self.OnPcEscClose
  self:CheckHasList()
  self:SetRenderOpacity(0)
  self:CheckPanelOnTop()
  self:CheckWidgetVisible()
  if self.isInBattle then
    self:DoHide()
  elseif self:GetShouldDisplay() then
    self:DoDisplay()
    self:DoStart()
  else
    self:DoHide()
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.GuidanceModuleEvent.OnPanelClosed, self.OnGuideEventPanelClosed)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnDisplayMetricsChanged, self.OnDisplayMetricsChanged)
end

function UMG_Guidance_Main_C:Destruct()
  if self.bUsedWeakFunctionBan then
    if not self.isInBattle then
      Log.Debug("UMG_Guidance_Main_C:Destruct self.bUsedWeakFunctionBan")
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveTargetStatus, ProtoEnum.PlayerConditionType.PCT_NEWPLAYER_GUIDE)
    end
    self.bUsedWeakFunctionBan = nil
  end
  if self.delayInitHandle then
    _G.DelayManager:CancelDelayById(self.delayInitHandle)
    self.delayInitHandle = nil
  end
  if self.panelClosedHandle then
    _G.DelayManager:CancelDelay(self.panelClosedHandle)
    self.panelClosedHandle = nil
  end
  _G.UpdateManager:UnRegister(self)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.GuidanceModuleEvent.OnPanelClosed, self.OnGuideEventPanelClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnDisplayMetricsChanged, self.OnDisplayMetricsChanged)
  self:StopAllAnimations()
  self:DoHide(true)
  self:ClearListItemRecord()
  Base.Destruct(self)
end

function UMG_Guidance_Main_C:OnDisplayMetricsChanged()
  Log.Debug("UMG_Guidance_Main_C:OnDisplayMetricsChanged")
  self.displayMetricsChanged = true
end

function UMG_Guidance_Main_C:CheckIsInBattle()
  if self.isInBattle then
    self.bOnTop = true
    self.bTargetVisible = false
  end
end

function UMG_Guidance_Main_C:InitFromFocusConfigs()
  self.ignoreAnimations = {}
  if not self.style then
    return
  end
  local typeId = self.style.type_id
  if not typeId then
    return
  end
  local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId)
  if not focusConf then
    return
  end
  if focusConf.ignore_anims and table.len(focusConf.ignore_anims) > 0 then
    for _, ignore_id in pairs(focusConf.ignore_anims) do
      local ignore_conf = _G.DataConfigManager:GetGuideAnimationIgnoreConf(ignore_id, true)
      if ignore_conf then
        self.ignoreAnimations[ignore_conf.panel_name] = ignore_conf.anim_names
      end
    end
  end
  if focusConf.ban_action and table.len(focusConf.ban_action) > 0 then
    for _, action in pairs(focusConf.ban_action) do
      self.controlActions[action] = true
    end
  end
end

function UMG_Guidance_Main_C:ReadyToStart()
  if self.bHasStarted then
    return
  end
  Log.Debug("UMG_Guidance_Main_C:ReadyToStart")
  self.bHasStarted = true
  if self.style.delay_time and self.style.delay_time > 0 then
    self.delayInitHandle = _G.DelayManager:DelaySeconds(self.style.delay_time / 1000.0, function()
      if not self or not UE4.UObject.IsValid(self) then
        return
      end
      self:SetRenderOpacity(0)
      self:CheckPanelOnTop()
      self:CheckWidgetVisible()
      if self:GetShouldDisplay() then
        self.delayInitHandle = nil
        self:DoStart()
      else
        Log.Debug("UMG_Guidance_Main_C:UpdateDisplayOrHide delayInitHandle", self.delayInitHandle)
        self.bHasStarted = false
        _G.DelayManager:CancelDelayById(self.delayInitHandle)
        self.delayInitHandle = nil
      end
    end)
    Log.Debug("UMG_Guidance_Main_C:ReadyToStart delayInitHandle", self.delayInitHandle)
  else
    self:DoStart()
  end
end

function UMG_Guidance_Main_C:DoStart()
  self.bHasStarted = true
  self:InitStyle()
  self:InitGuidanceWidgetControlInfo()
  self:SetRenderOpacity(1)
  if self.openAnim then
    self:PlayAnimation(self.openAnim)
    self.openAnim = nil
  end
  if self.loopAnim then
    self:PlayAnimation(self.loopAnim, 0, 0)
    self.loopAnim = nil
  end
end

function UMG_Guidance_Main_C:GetShouldDisplay()
  return self.bOnTop and self.bTargetVisible
end

function UMG_Guidance_Main_C:DoDisplay()
  if self.enabled and self:IsVisible() then
    return
  end
  self.enabled = true
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:CustomizeTargetWidgets(true)
  if self.bStrongGuide then
    if self.panelData then
      UE4Helper.SetDesiredShowCursor(true, self.panelData.panelName)
    end
    _G.NRCPanelManager:PushPanelWaitJudgeImc(self.panelData)
    if not self.hasPausedTip then
      self.hasPausedTip = true
      if not self.isInBattle then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.StrongGuide)
      end
    end
    if self.bUsedWeakFunctionBan then
      if not self.isInBattle then
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.AddFunctionBan, self.config)
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveTargetStatus, ProtoEnum.PlayerConditionType.PCT_NEWPLAYER_GUIDE)
      end
      self.bUsedWeakFunctionBan = nil
    end
  end
end

function UMG_Guidance_Main_C:DoHide(onDestroy)
  if self.bHasStarted and not self.enabled then
    return
  end
  self.enabled = false
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:CustomizeTargetWidgets(false, onDestroy)
  if self.bStrongGuide then
    if self.panelData then
      UE4Helper.ReleaseDesiredShowCursor(self.panelData.panelName)
    end
    _G.NRCPanelManager:TryRemoveImcManual(self.panelData)
    if not self.isInBattle then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.StrongGuide)
    end
    if not self.bUsedWeakFunctionBan and not onDestroy then
      if not self.isInBattle then
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.AddTargetStatus, ProtoEnum.PlayerConditionType.PCT_NEWPLAYER_GUIDE)
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveFunctionBan, self.config)
      end
      self.bUsedWeakFunctionBan = true
    end
  end
end

function UMG_Guidance_Main_C:CustomizeTargetWidgets(bEnabled, bOnDestroy)
  if not self.pathWidgets then
    return
  end
  for _, widget in ipairs(self.pathWidgets) do
    if widget and UE4.UObject.IsValid(widget) then
      if bEnabled then
        self:TryCustomizeTargetWidgetsInGuide(widget)
        if widget.OnBeginGuideTarget then
          widget:OnBeginGuideTarget(self.config)
        end
      else
        self:TryCustomizeTargetWidgetsOutGuide(widget)
        if widget.OnEndGuideTarget then
          widget:OnEndGuideTarget(self.config, bOnDestroy)
        end
      end
    end
  end
end

function UMG_Guidance_Main_C:CheckWidgetIsPlayingAnimation()
  for _, widget in ipairs(self.pathWidgets) do
    if not widget or not UE4.UObject.IsValid(widget) then
      Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget is not valid")
      self.bTargetVisible = false
      return false
    end
    if widget.IsPlayingAnimation and widget:IsPlayingAnimation() then
      local widgetClassName = widget.className
      widgetClassName = widgetClassName:gsub("_C$", "")
      local ignoreAnims = self.ignoreAnimations[widgetClassName]
      if ignoreAnims and table.len(ignoreAnims) > 0 and widget and widget.ActiveSequencePlayers then
        for _, player in tpairs(widget.ActiveSequencePlayers) do
          if player.Animation then
            local animaName = player.Animation:GetName()
            animaName = animaName:gsub("_INST$", "")
            if table.contains(ignoreAnims, animaName) then
              if self.bEnabledDebug then
                Log.Debug("UMG_Guidance_Main_C:CheckWidgetIsPlayingAnimation \230\142\167\228\187\182\230\173\163\229\156\168\230\146\173\230\148\190\229\138\168\231\148\187=", widget:GetName(), widgetClassName, animaName)
              end
              self.bTargetVisible = false
              return false
            end
          end
        end
      end
    end
  end
  return true
end

function UMG_Guidance_Main_C:CheckWidgetVisible()
  if self.isInBattle then
    if self:IsWindowStateChanged() then
      self.targetWidget:InvalidateLayoutAndVolatility()
    end
    if not self:CheckWidgetIsPlayingAnimation() then
      return
    end
    if not self.outOfScreen then
      self.bTargetVisible = true
    end
    return
  end
  if not self.bOnTop then
    return
  end
  for _, widget in ipairs(self.pathWidgets) do
    if not widget or not UE4.UObject.IsValid(widget) then
      Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget is not valid")
      self.bTargetVisible = false
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost, self.config)
      return
    end
    if widget.IsPlayingAnimation and widget:IsPlayingAnimation() then
      local widgetClassName = widget.className
      widgetClassName = widgetClassName:gsub("_C$", "")
      local ignoreAnims = self.ignoreAnimations[widgetClassName]
      if ignoreAnims and table.len(ignoreAnims) > 0 then
        for _, ignoreAnim in ipairs(ignoreAnims) do
          local anim = widget[ignoreAnim]
          if anim and UE4.UObject.IsValid(anim) and widget:IsAnimationPlaying(anim) then
            if self.bEnabledDebug then
              Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget is playing animation", widget:GetName(), widgetClassName, ignoreAnim)
            end
            self.bTargetVisible = false
            return
          end
        end
      end
    end
    local pathWidget = widget
    while pathWidget and UE4.UObject.IsValid(pathWidget) do
      if not pathWidget:IsVisible() then
        if self.bEnabledDebug then
          Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget is not visible", widget:GetName(), pathWidget:GetName())
        end
        self.bTargetVisible = false
        return
      end
      pathWidget = pathWidget:GetParent()
    end
  end
  if self.bTargetHasList then
    for _, widget in ipairs(self.pathWidgets) do
      if widget and UE4.UObject.IsValid(widget) then
        local record = widget.GuidanceListRecord
        if record then
          local index = record.index
          if record.scroll and UE4.UObject.IsValid(record.scroll) then
            local scroll = record.scroll
            if scroll:GetScrollBoxHandleScrollingState() then
              if self.bEnabledDebug then
                Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget is scrolling", widget:GetName(), index)
              end
              self.bTargetVisible = false
              return
            end
            if not scroll:IsItemVisible(index, listItemOutOfBoundTolerance) then
              if self.bEnabledDebug then
                Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget not in scroll range", widget:GetName(), index)
              end
              self.bTargetVisible = false
              return
            end
          elseif record.grid and UE4.UObject.IsValid(record.grid) then
            if self:CheckGridOrListOutOfBound(record.grid, widget) then
              if self.bEnabledDebug then
                Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget not in grid range", widget:GetName(), index)
              end
              self.bTargetVisible = false
              return
            end
          elseif record.list and UE4.UObject.IsValid(record.list) and self:CheckGridOrListOutOfBound(record.list, widget) then
            if self.bEnabledDebug then
              Log.Debug("UMG_Guidance_Main_C:CheckWidgetVisible widget not in list range", widget:GetName(), index)
            end
            self.bTargetVisible = false
            return
          end
        end
      end
    end
  end
  local positionUpdated = self:CheckWindowStateChanged()
  if self.bTargetHasList and not positionUpdated then
    positionUpdated = true
  end
  if positionUpdated then
    if not self.bTargetHasList and UE4.UObject.IsValid(self.targetWidget) then
      self.targetWidget:InvalidateLayoutAndVolatility()
    end
    self:UpdatePosition()
  end
  if not self.outOfScreen then
    self.bTargetVisible = true
  end
end

function UMG_Guidance_Main_C:CheckPanelOnTop()
  if not self.targetPanelData then
    return
  end
  local targetPanelLayer = self.targetPanelData.panelLayer
  local targetPanelModule = self.targetPanelData.moduleName
  local targetPanelName = self.targetPanelData.panelName
  local panelStack = _G.NRCPanelManager.PanelStack
  local len = #panelStack
  if len > 0 then
    for idx = len, 1, -1 do
      local moduleName = panelStack[idx].moduleName
      local panelName = panelStack[idx].panelName
      local panel = _G.NRCPanelManager:GetPanel(moduleName, panelName)
      if panel and panel:IsVisible() then
        local panelData = panel.panelData
        if GuideConfigTypes.IsTopPanel(panelData, self.targetPanelData) and GuideConfigTypes.ComparePanelLayer(panelData.panelLayer, targetPanelLayer) then
          if panelName ~= targetPanelName or moduleName ~= targetPanelModule then
            if self.bEnabledDebug then
              Log.Debug("UMG_Guidance_Main_C:CheckPanelOnTop panel not on top", idx, moduleName, panelName, targetPanelName, targetPanelModule)
            end
            self.bOnTop = false
            return
          else
            break
          end
        end
      end
    end
  end
  self.bOnTop = true
end

function UMG_Guidance_Main_C:CheckWindowStateChanged()
  if _G.UE4Helper.IsPCMode() then
    local positionInScreen = UE4.UNRCTUIStatics.GetPositionInScreen()
    if self.windowsPositionInScreen == nil then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckWindowStateChanged window position is nil", positionInScreen)
      end
      self.windowsPositionInScreen = positionInScreen
    elseif self.windowsPositionInScreen.X ~= positionInScreen.X or self.windowsPositionInScreen.Y ~= positionInScreen.Y then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckWindowStateChanged window position changed", self.windowsPositionInScreen, positionInScreen)
      end
      self.windowsPositionInScreen = positionInScreen
      if not self.bHasStarted then
        return true
      end
    end
    local sizeInScreen = UE4.UNRCTUIStatics.GetSizeInScreen()
    if nil == self.windowsSizeInScreen then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckWindowStateChanged window size is nil", sizeInScreen)
      end
      self.windowsSizeInScreen = sizeInScreen
    elseif self.windowsSizeInScreen.X ~= sizeInScreen.X or self.windowsSizeInScreen.Y ~= sizeInScreen.Y then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckWindowStateChanged window size changed", self.windowsSizeInScreen, sizeInScreen)
      end
      self.windowsSizeInScreen = sizeInScreen
      return true
    end
  end
  return false
end

function UMG_Guidance_Main_C:IsWindowStateChanged()
  if _G.UE4Helper.IsPCMode() then
    local sizeInScreen = UE4.UNRCTUIStatics.GetSizeInScreen()
    local positionInScreen = UE4.UNRCTUIStatics.GetPositionInScreen()
    if self.windowsPositionInScreen == nil then
      self.windowsPositionInScreen = positionInScreen
      return true
    elseif self.windowsPositionInScreen.X ~= positionInScreen.X or self.windowsPositionInScreen.Y ~= positionInScreen.Y then
      self.windowsPositionInScreen = positionInScreen
      return true
    end
    if nil == self.windowsSizeInScreen then
      self.windowsSizeInScreen = sizeInScreen
    elseif self.windowsSizeInScreen.X ~= sizeInScreen.X or self.windowsSizeInScreen.Y ~= sizeInScreen.Y then
      self.windowsSizeInScreen = sizeInScreen
      return true
    end
  end
  if RocoEnv.IS_EDITOR then
    return true
  end
  return false
end

function UMG_Guidance_Main_C:OnTick(deltaTime)
  if not self then
    return
  end
  self.tickedTime = self.tickedTime + deltaTime
  if self.tickedTime < self.tickedInterval then
    return
  end
  self.tickedTime = self.tickedTime - self.tickedInterval
  if _G.UE4Helper.IsPCMode() then
    local resX, resY = UE4.UNRCQualityLibrary.GetPCResolution()
    if resX ~= self.resX or resY ~= self.resY then
      Log.Debug("UMG_Guidance_Main_C:OnTick resolution changed", self.resX, self.resY, resX, resY)
      self.resX = resX
      self.resY = resY
      self.resolutionChanged = true
    end
  elseif self.displayMetricsChanged then
    self.targetWidget:InvalidateLayoutAndVolatility()
    local position = UE4.UNRCStatics.GetWidgetViewportPosition(self.targetWidget)
    if not self.positionCached then
      self.positionCached = position
      Log.Debug("UMG_Guidance_Main_C:OnTick displayMetricsChanged", self.positionCached)
    else
      local delta = position - self.positionCached
      if delta:Size() <= 0.5 then
        self.displayMetricsChanged = false
        self.positionCached = nil
        self.resolutionChanged = true
      else
        self.positionCached = position
      end
    end
  end
  self:TryUpdateListItem()
  self:UpdateDisplayOrHide()
end

function UMG_Guidance_Main_C:UpdateDisplayOrHide()
  self:CheckPanelOnTop()
  self:CheckWidgetVisible()
  if self:GetShouldDisplay() then
    if not self.bHasStarted then
      self:ReadyToStart()
    end
    if self.resolutionChanged == true then
      Log.Debug("UMG_Guidance_Main_C:UpdateDisplayOrHide resolution changed")
      self.resolutionChanged = false
      self:UpdatePosition()
    end
    self:DoDisplay()
  else
    self:DoHide()
    if self.delayInitHandle then
      Log.Debug("UMG_Guidance_Main_C:UpdateDisplayOrHide delayInitHandle", self.delayInitHandle)
      self.bHasStarted = false
      _G.DelayManager:CancelDelayById(self.delayInitHandle)
      self.delayInitHandle = nil
    end
  end
end

function UMG_Guidance_Main_C:InitStyle()
  Log.Debug("UMG_Guidance_Main_C:InitStyle")
  if not self.style then
    return
  end
  local typeId = self.style.type_id
  if not typeId then
    return
  end
  local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId)
  if not focusConf then
    return
  end
  if not self.isInBattle then
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.AddFunctionBan, self.config)
  end
  if focusConf.circle_data and string.len(focusConf.circle_data) > 0 then
    local circleDataNumber = string.sub(focusConf.circle_data, 2)
    local circleType = (tonumber(circleDataNumber) or 1) - 1
    self.SwitcherShape:SetActiveWidgetIndex(0)
    local circleNums = self.SwitcherCircle:GetNumWidgets()
    self.SwitcherCircle:SetActiveWidgetIndex(math.min(circleType, circleNums - 1))
    self.circleCanvas = nil
    self.circleInitSize = nil
    if 0 == circleType then
      self:SetAnimationToPlay(self.Magic_Animation, self.Magic_Loop)
      self.circleCanvas = self.magic
      self.circleInitSize = 158
    elseif 1 == circleType then
      self:SetAnimationToPlay(self.Sprint_Animation, self.Sprint_Loop)
      self.circleCanvas = self.sprint
      self.circleInitSize = 200
    elseif 2 == circleType then
      self:SetAnimationToPlay(self.Rocker_Animation, self.Rocker_Loop)
      self.circleCanvas = self.rocker
      self.circleInitSize = 260
    end
  else
    self.SwitcherShape:SetActiveWidgetIndex(1)
    self:SetAnimationToPlay(self.Rect_Animation, self.Rect_Loop)
  end
  self.Hint:Init(self.config, focusConf, self.isInBattle)
  if UE4.UObject.IsValid(self.targetWidget) then
    self.targetWidget:InvalidateLayoutAndVolatility()
  end
  self:UpdatePosition()
  if self.bStrongGuide then
    self.Background:SetVisibility(UE4.ESlateVisibility.Visible)
    local brush = self.Background.Brush
    brush.TintColor.SpecifiedColor.A = (self.style.transparence or 100) / 100.0
  else
    self.Background:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.FocusPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Guidance_Main_C:UpdatePosition()
  if not self.targetWidget or not UE4.UObject.IsValid(self.targetWidget) then
    return
  end
  if not self.bHasStarted then
    return
  end
  self:UpdatePositionInternal()
  if self.outOfScreen then
    self:DoHide()
  else
    self:DoDisplay()
  end
end

function UMG_Guidance_Main_C:UpdatePositionInternal()
  if not self.targetWidget or not UE4.UObject.IsValid(self.targetWidget) then
    return
  end
  local typeId = self.style.type_id
  if not typeId then
    return
  end
  local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId)
  if not focusConf then
    return
  end
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(self)
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(self)
  local realViewportSize = viewportSize / viewportScale
  local geometry = self.targetWidget:GetPaintSpaceGeometry()
  local position = UE4.UNRCStatics.GetWidgetViewportPosition(self.targetWidget)
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
  if centerPosition == self.Background.CullOffset then
    return
  end
  if focusConf.rectangle_data and type(focusConf.rectangle_data) == "table" then
    if #focusConf.rectangle_data >= 1 then
      realSize.X = realSize.X + focusConf.rectangle_data[1]
    end
    if #focusConf.rectangle_data >= 2 then
      realSize.Y = realSize.Y + focusConf.rectangle_data[2]
    end
  end
  local info = string.format("%s, %s, %s, %s, %s, %s, %s, %s", position, centerPosition, localSize, absoluteSize, realSize, viewportSize, realViewportSize, viewportScale)
  if self:CheckOutOfViewport(centerPosition, realViewportSize) then
    Log.Debug("UMG_Guidance_Main_C:UpdatePosition position is out of screen", info)
    if self.bEnabledDebug then
      centerPosition = viewportSize / 2.0
      self.outOfScreen = false
    else
      self.outOfScreen = true
      return
    end
  else
    self.outOfScreen = false
    Log.Debug("UMG_Guidance_Main_C:UpdatePosition", info)
  end
  self.Background:SetCullOffset(centerPosition)
  local cullSetting = self.Background.CullSetting
  if focusConf.circle_data and string.len(focusConf.circle_data) > 0 then
    cullSetting.CullType = UE4.EImageCulledType.Circle
    cullSetting.CircleRadius = math.max(realSize.X, realSize.Y) / 2.0
    if self.circleCanvas and self.circleInitSize and self.circleInitSize > 0 then
      local circleScale = math.max(localSize.X, localSize.Y) / self.circleInitSize / 0.9
      self.circleCanvas:SetRenderScale(UE4.FVector2D(circleScale, circleScale))
    end
  else
    cullSetting.CullType = UE4.EImageCulledType.Rectangular
    cullSetting.RectangularSize = realSize
    self.SwitcherShape:SetActiveWidgetIndex(1)
    self.img_fang:SetBrushSize(realSize)
    local img_fang1_slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.img_fang_1)
    if img_fang1_slot then
      img_fang1_slot:SetSize(realSize)
    end
  end
  self.Background:SetCullSetting(cullSetting)
  local focusSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.FocusPanel)
  if focusSlot then
    focusSlot:SetPosition(centerPosition)
  end
  self.Hint:UpdatePosition(self.style, focusConf, realSize, centerPosition)
end

function UMG_Guidance_Main_C:SetAnimationToPlay(start, loop)
  if self:IsAnimationPlaying(loop) then
    return
  end
  self:StopAllAnimations()
  if start and start ~= self.openAnim then
    self.openAnim = start
  end
  if loop and loop ~= self.loop then
    self.loopAnim = loop
  end
end

function UMG_Guidance_Main_C:CheckOutOfViewport(position, viewport)
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

function UMG_Guidance_Main_C:ClearListItemRecord()
  if self.pathWidgets then
    for _, widget in ipairs(self.pathWidgets) do
      if widget then
        if widget.GuidanceListRecord then
          widget.GuidanceListRecord = nil
        end
        local guideControlTargetWidget = widget.guideControlTargetWidget
        if guideControlTargetWidget then
          local scrollRecord = guideControlTargetWidget.scroll
          if scrollRecord then
            local scrollBox = scrollRecord.scroll
            if scrollBox and UE4.UObject.IsValid(scrollBox) and scrollRecord.callback then
              scrollBox.OnUserScrolled:Remove(scrollBox, scrollRecord.callback)
            end
          end
        end
      end
    end
  end
  self.bTargetHasList = false
end

function UMG_Guidance_Main_C:CheckHasList()
  if self.pathWidgets then
    for _, widget in ipairs(self.pathWidgets) do
      local child = widget
      if widget then
        local record = widget.GuidanceListRecord
        if record then
          self.bTargetHasList = true
          if record.grid and UE4.UObject.IsValid(record.grid) then
            child = record.grid
          end
        end
      end
      local parent = child:GetParent()
      if parent and UE4.UObject.IsValid(parent) and parent:IsA(UE4.UScrollBox) then
        local scrollInfo = {scroll = parent}
        widget.guidanceWidgetControlInfo = {scroll = scrollInfo}
        
        local function callback()
          if not widget or not UE4.UObject.IsValid(widget) then
            return
          end
          if not widget.bGuideLockScroll then
            return
          end
          if not parent or not UE4.UObject.IsValid(parent) then
            return
          end
          local offset = scrollInfo.offset
          if not offset then
            return
          end
          parent:SetScrollOffset(offset)
        end
        
        parent.OnUserScrolled:Add(parent, callback)
      end
    end
  else
    Log.Debug("UMG_Guidance_Main_C pathWidgets is nil")
  end
end

function UMG_Guidance_Main_C:TryUpdateListItem()
  if not self.bTargetHasList then
    return
  end
  local bChanged = false
  local newPathWidgets = {}
  for _, widget in ipairs(self.pathWidgets) do
    if widget then
      local record = widget.GuidanceListRecord
      local item
      if record then
        local index = record.index
        if record.list and UE4.UObject.IsValid(record.list) then
          item = record.list:GetItemAt(index - 1)
        elseif record.grid and UE4.UObject.IsValid(record.grid) then
          item = record.grid:GetItemByIndex(index - 1)
        elseif record.scroll and UE4.UObject.IsValid(record.scroll) then
          item = record.scroll:GetItemByIndex(index - 1)
        end
        if item and UE4.UObject.IsValid(item) then
          table.insert(newPathWidgets, item)
          if item ~= widget then
            if self.bEnabledDebug then
              Log.Debug("UMG_Guidance_Main_C:TryUpdateListItem target widget in list view has changed", index, widget, item)
            end
            bChanged = true
            widget.GuidanceListRecord = nil
            item.GuidanceListRecord = record
          end
        end
      else
        table.insert(newPathWidgets, widget)
      end
    end
  end
  if bChanged then
    local newTargetWidget = newPathWidgets[#newPathWidgets]
    if self.bEnabledDebug then
      Log.Debug("UMG_Guidance_Main_C:TryUpdateListItem target widget in list view has changed", self.targetWidget, newTargetWidget)
    end
    table.clear(self.pathWidgets)
    self.pathWidgets = newPathWidgets
    self.targetWidget = newTargetWidget
    if self.config then
      self.config:ClearButtonWatch()
      self.config:DoWatchTargetButtonClick(self.targetWidget)
    end
  end
end

function UMG_Guidance_Main_C:OnPcEscClose()
end

function UMG_Guidance_Main_C:CheckGridOrListOutOfBound(list, widget)
  if not list or not UE4.UObject.IsValid(list) then
    return false
  end
  if not widget or not UE4.UObject.IsValid(widget) then
    return false
  end
  
  local function getPosAndSize(target)
    local geometry = target:GetPaintSpaceGeometry()
    local position = UE4.UNRCStatics.GetWidgetViewportPosition(target)
    local size = UE4.USlateBlueprintLibrary.GetLocalSize(geometry)
    local realSize = UE4.FVector2D(size.X, size.Y)
    return position, realSize
  end
  
  local function checkOutOfBound(posChild, sizeChild, posParent, sizeParent)
    local childEnd = posChild + sizeChild
    local checkStart = posParent - sizeChild * listItemOutOfBoundTolerance
    local checkEnd = posParent + sizeParent + sizeChild * listItemOutOfBoundTolerance
    if posChild.X >= checkStart.X and posChild.Y >= checkStart.Y and childEnd.X <= checkEnd.X and childEnd.Y <= checkEnd.Y then
      return false
    end
    return true
  end
  
  local parent = list:GetParent()
  if parent and UE4.UObject.IsValid(parent) and parent:IsA(UE4.UScrollBox) then
    if not widget.bGuideLockScroll and UE4.UNRCTUIStatics.GetScrollBoxHandleScrollingState(parent) then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckGridOrListOutOfBound parent is scrolling", widget:GetName(), parent:GetName())
      end
      return true
    end
    local widgetPos, widgetSize = getPosAndSize(widget)
    local parentPos, parentSize = getPosAndSize(parent)
    if checkOutOfBound(widgetPos, widgetSize, parentPos, parentSize) then
      if self.bEnabledDebug then
        Log.Debug("UMG_Guidance_Main_C:CheckGridOrListOutOfBound widget out of scroll", parent:GetName(), widgetPos, widgetSize, parentPos, parentSize)
      end
      return true
    end
  end
  return false
end

function UMG_Guidance_Main_C:OnGuideEventPanelClosed(panelData)
  if not panelData then
    return
  end
  if not self.pathWidgets then
    return
  end
  local panel = _G.NRCPanelManager:GetPanel(panelData.moduleName, panelData.panelName)
  if not panel then
    return
  end
  for _, widget in ipairs(self.pathWidgets) do
    if widget == panel then
      Log.Debug("UMG_Guidance_Main_C:OnGuideEventPanelClosed target panel closed", panelData.moduleName, panelData.panelName)
      if self.panelClosedHandle then
        _G.DelayManager:CancelDelay(self.panelClosedHandle)
      end
      self.panelClosedHandle = _G.DelayManager:DelayFrames(1, function()
        if self then
          self.panelClosedHandle = nil
        end
        if not self.isInBattle then
          _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost, self.config)
        end
      end)
      return
    end
  end
end

function UMG_Guidance_Main_C:InitGuidanceWidgetControlInfo()
  if not self.pathWidgets then
    return
  end
  for _, widget in ipairs(self.pathWidgets) do
    local controlInfo = widget.guidanceWidgetControlInfo
    if not controlInfo then
    else
      local scrollInfo = controlInfo.scroll
      if scrollInfo then
        local scrollBox = scrollInfo.scroll
        if scrollBox and UE4.UObject.IsValid(scrollBox) then
          scrollInfo.offset = scrollBox:GetScrollOffset()
          scrollInfo.bOverScroll = scrollBox.AllowOverscroll
          scrollInfo.wheelMultiplier = scrollBox.WheelScrollMultiplier
          Log.Debug("UMG_Guidance_Main_C:InitGuidanceWidgetControlInfo", UE4.UKismetSystemLibrary.GetDisplayName(scrollBox), scrollInfo.offset, scrollInfo.bOverScroll, scrollInfo.wheelMultiplier)
        end
      end
    end
  end
end

function UMG_Guidance_Main_C:GetNeedDoCustomControl(actionType)
  if not self.controlActions or not actionType then
    return false
  end
  if self.controlActions[actionType] then
    return true
  end
  return false
end

function UMG_Guidance_Main_C:TryCustomizeTargetWidgetsInGuide(widget)
  if not widget then
    return
  end
  local controlInfo = widget.guidanceWidgetControlInfo
  if not controlInfo then
    return
  end
  local scrollInfo = controlInfo.scroll
  if scrollInfo and self:GetNeedDoCustomControl(GuidanceFocusControlActionsType.ScrollLock) then
    local scrollBox = scrollInfo.scroll
    if scrollBox and UE4.UObject.IsValid(scrollBox) then
      widget.bGuideLockScroll = true
      scrollBox:SetAllowOverscroll(false)
      scrollBox:SetWheelScrollMultiplier(0)
    end
  end
end

function UMG_Guidance_Main_C:TryCustomizeTargetWidgetsOutGuide(widget)
  if not widget then
    return
  end
  local controlInfo = widget.guidanceWidgetControlInfo
  if not controlInfo then
    return
  end
  local scrollInfo = controlInfo.scroll
  if scrollInfo and self:GetNeedDoCustomControl(GuidanceFocusControlActionsType.ScrollLock) then
    local scrollBox = scrollInfo.scroll
    if scrollBox and UE4.UObject.IsValid(scrollBox) then
      widget.bGuideLockScroll = nil
      scrollBox:SetAllowOverscroll(scrollInfo.bOverScroll or false)
      scrollBox:SetWheelScrollMultiplier(scrollInfo.wheelMultiplier or 1)
    end
  end
end

return UMG_Guidance_Main_C
