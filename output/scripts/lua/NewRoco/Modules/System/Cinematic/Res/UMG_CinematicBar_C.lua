local DesiredSizeX = 32.0
local UMG_CinematicBar_C = _G.NRCPanelBase:Extend("UMG_CinematicBar_C")

function UMG_CinematicBar_C:Construct()
  NRCPanelBase.Construct(self)
  self.LockeWordText:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.SubtitleText:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_CinematicBar_C:OnConstruct()
  self.ButtonSkip:PlayAnimation(self.ButtonSkip.LightOut, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 999)
  self:BindInputAction()
end

function UMG_CinematicBar_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  self.SkipMessageOn = nil
  _G.DelayManager:CancelDelayById(self.WakeUpUITimer)
  self.WakeUpUITimer = nil
end

function UMG_CinematicBar_C:RemoveBackground()
  self.Top:SetOpacity(0.0)
  self.BottomImg:SetOpacity(0.0)
  self.Frame:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_CinematicBar_C:Tick(MyGeometry, InDeltaTime)
  self:UpdateScreenSize(UE4.USlateBlueprintLibrary.GetLocalSize(MyGeometry))
end

function UMG_CinematicBar_C:UpdateScreenSize(InScreenSize)
  if self.ScreenSizeRecord == nil then
    self.ScreenSizeRecord = _G.ProtoMessage:newPosition2D()
    self.LockeWordText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SubtitleText:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.ScreenSizeRecord.x ~= InScreenSize.X or self.ScreenSizeRecord.y ~= InScreenSize.Y then
    self.ScreenSizeRecord.x = InScreenSize.X
    self.ScreenSizeRecord.y = InScreenSize.Y
    self:UpdateWidgetSize(self.ScreenSizeRecord.x, self.ScreenSizeRecord.y)
  end
end

function UMG_CinematicBar_C:UpdateWidgetSize(sizeX, sizeY)
  local xToRatio = sizeX / self.TargetRatio
  local centerHeight = math.min(xToRatio, sizeY)
  local alignHeight = (sizeY - xToRatio) / 2.0
  if alignHeight < 0 then
    alignHeight = 0
  end
  self.Top:SetBrushSize(UE4.FVector2D(DesiredSizeX, alignHeight))
  self.Center:SetBrushSize(UE4.FVector2D(DesiredSizeX, centerHeight))
  local bottomSlot = UE4.UWidgetLayoutLibrary.SlotAsVerticalBoxSlot(self.Bottom)
  if bottomSlot then
    bottomSlot:SetSize(UE4.FSlateChildSize(alignHeight, UE4.ESlateSizeRule.Fill))
  end
end

function UMG_CinematicBar_C:BindInputAction()
  self:AddButtonListener(self.ButtonSkip.Button, self.OnButtonSkip)
  local mappingContext = self:AddInputMappingContext("IMC_Cinematic")
  if mappingContext then
    mappingContext:BindAction("IA_Cinematic_WakeupUI", self, "OnWakeupUI")
  end
end

function UMG_CinematicBar_C:OnButtonSkip()
  if not (self.module and self.module.SeqConf) or not self.module.SeqConf.skippable then
    return
  end
  if self.SkipMessageOn then
    return
  end
  self.SkipMessageOn = true
  OpenMessageBoxWthCaller(LuaText.Title_CinematicSkip, LuaText.Msg_CinematicSkip, LuaText.CONFIRM, LuaText.CANCEL, DialogContext.Mode.OK_CANCEL, self.OnConfirmSkipClick, self, nil, true)
end

function UMG_CinematicBar_C:OnConfirmSkipClick(bResult)
  self.SkipMessageOn = nil
  if bResult and self.module and self.module.CinematicPlayer then
    self.module.CinematicPlayer:Stop()
  end
end

function UMG_CinematicBar_C:OnWakeupUI()
  if not (self.module and self.module.SeqConf) or not self.module.SeqConf.skippable then
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    return
  end
  if self.ButtonSkip:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self.ButtonSkip:PlayAnimation(self.ButtonSkip.FadeIn)
  end
  _G.DelayManager:CancelDelayById(self.WakeUpUITimer)
  local DelayTime = _G.DataConfigManager:GetTaskGlobalConfig("movie_skippable_time", false)
  DelayTime = (DelayTime and DelayTime.num or 15000) / 1000.0
  self.WakeUpUITimer = _G.DelayManager:DelaySeconds(DelayTime, function()
    self.WakeUpUITimer = nil
    if self.ButtonSkip:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
      self.ButtonSkip:PlayAnimation(self.ButtonSkip.LightOut)
    end
  end)
end

function UMG_CinematicBar_C:OnTouchStarted(MyGeometry, InTouchEvent)
  Log.Info("UMG_CinematicBar_C:OnTouchStarted, on touch started")
  self:OnWakeupUI()
  return UE4.UWidgetBlueprintLibrary.Handled()
end

return UMG_CinematicBar_C
