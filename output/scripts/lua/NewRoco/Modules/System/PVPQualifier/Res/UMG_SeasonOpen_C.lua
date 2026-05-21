local UMG_SeasonOpen_C = _G.NRCPanelBase:Extend("UMG_SeasonOpen_C")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local Timer = require("NewRoco.Modules.System.PVPQualifier.Res.Timer")

function UMG_SeasonOpen_C:OnConstruct()
  self.bNeedLatentClose = false
  self.bEventDispatched = false
  self.CloseDelayTimer = Timer()
  self.Video:OnConstruct(self)
end

function UMG_SeasonOpen_C:OnDestruct()
  self.Video:OnDestruct()
end

function UMG_SeasonOpen_C:OnActive()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:OnActive")
  self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local bSucceed = self:TryLoadVideo()
  if not bSucceed then
    self.bNeedLatentClose = true
  end
  self:SwitchSeasonText()
end

function UMG_SeasonOpen_C:SwitchSeasonText()
  local currentSeasonId = self.module.data:GetCurSeasonId() or 0
  local firstSeasonId = self.module.data:GetFirstSeasonId() or 0
  local index = math.max(0, currentSeasonId - firstSeasonId)
  self.Switcher_Text:SetActiveWidgetIndex(index)
end

function UMG_SeasonOpen_C:OnDeactive()
  self:TryStopVideo()
  self:TryDispatchEvent()
end

function UMG_SeasonOpen_C:OnTick(deltaTime)
  if not self.CloseDelayTimer:IsExceed() then
    self.CloseDelayTimer:Tick(deltaTime)
    if self.CloseDelayTimer:IsExceed() then
      self:OnCloseDelayFinished()
    end
  end
  if self.bNeedLatentClose then
    self.bNeedLatentClose = false
    self:DoClose()
  end
end

function UMG_SeasonOpen_C:OnClick_BtnClose()
  if self.CloseDelayTimer:IsExceed() then
    self:TryCloseAnimated()
  end
end

function UMG_SeasonOpen_C:OnMediaOpened()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:OnMediaOpened")
  self:TryDoOnMediaLoaded()
end

function UMG_SeasonOpen_C:TryDoOnMediaLoaded()
  if self.bOnMediaOpened then
    return
  end
  self.bOnMediaOpened = true
  self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Text_In)
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:UI_SeasonOpenAnimationLoaded")
  _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.UI_SeasonOpenAnimationLoaded)
end

function UMG_SeasonOpen_C:OnCloseDelayFinished()
  self:DoEnableClose()
end

function UMG_SeasonOpen_C:TryLoadVideo()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:TryLoadVideo")
  local seasonConf
  local curSeasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  if curSeasonId then
    seasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(curSeasonId)
  end
  if not seasonConf then
    return false
  end
  local closeDelayTime = seasonConf.close_delay * 0.001
  local videoPath1 = seasonConf.show_video
  local videoPath2 = seasonConf.loop_video
  if not (closeDelayTime and videoPath1) or not videoPath2 then
    return false
  end
  self.CloseDelayTimer:ResetAndPause(closeDelayTime)
  self.Text_Tips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Video:OnActive()
  self.Video:SetNRCMediaImageSize(MediaUtils.DIALOGUE_VIDEO_RESOLUTION.X, MediaUtils.DIALOGUE_VIDEO_RESOLUTION.Y)
  self.Video:AddOnMediaOpened(self, self.OnMediaOpened)
  local paramTable = {
    source = videoPath1,
    needAutoPlay = true,
    isLoop = false
  }
  self.Video:OpenMediaPanelByParamTable(paramTable)
  self.Video:AddNextVideo(videoPath2, true)
  return true
end

function UMG_SeasonOpen_C:TryPlayVideo()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:TryPlayVideo")
  self.Video:Play()
  self.CloseDelayTimer:Proceed()
end

function UMG_SeasonOpen_C:TryStopVideo()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:TryStopVideo")
  self.Video:OnDeactive()
end

function UMG_SeasonOpen_C:TryDispatchEvent()
  if self.bEventDispatched then
    Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:TryDispatchEvent(already bEventDispatched and return)")
    return
  end
  self.bEventDispatched = true
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:TryDispatchEvent UI_SeasonOpenAnimationFinished")
  _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.UI_SeasonOpenAnimationFinished)
end

function UMG_SeasonOpen_C:TryCloseAnimated()
  if not self.PlayingCloseAnim then
    self.PlayingCloseAnim = true
    self:DoCloseAnimated()
  end
end

function UMG_SeasonOpen_C:DoCloseAnimated()
  self:BindToAnimationFinished(self.Out, {
    self,
    self.OnAnimationFinished_Out
  })
  self:PlayAnimation(self.Out)
end

function UMG_SeasonOpen_C:OnAnimationFinished_Out()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:OnAnimationFinished_Out")
  self.PlayingCloseAnim = false
  self:TryDispatchEvent()
end

function UMG_SeasonOpen_C:DoEnableClose()
  Log.Debug("SeasonOpen Progress: UMG_SeasonOpen_C:DoEnableClose")
  self:AddButtonListener(self.BtnClose, self.OnClick_BtnClose)
  self.Text_Tips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.GoOn)
end

return UMG_SeasonOpen_C
