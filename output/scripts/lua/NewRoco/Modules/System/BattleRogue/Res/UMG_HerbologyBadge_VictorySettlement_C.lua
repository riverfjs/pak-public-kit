local UMG_HerbologyBadge_VictorySettlement_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_VictorySettlement_C")
local PROGRESS_ANIM_DURATION = 2.0
local PROGRESS_ANIM_DELTA_TIME = 0.016

function UMG_HerbologyBadge_VictorySettlement_C:OnActive(initData)
  self.initData = initData or {}
  self:OnAddEventListener()
  self:_InitPanel()
end

function UMG_HerbologyBadge_VictorySettlement_C:OnDeactive()
  self:_StopProgressAnimation()
end

function UMG_HerbologyBadge_VictorySettlement_C:OnAddEventListener()
  self:AddButtonListener(self.CloseButton, self.OnCloseButtonClicked)
end

function UMG_HerbologyBadge_VictorySettlement_C:OnCloseButtonClicked()
  self:_StopProgressAnimation()
  self:DoClose()
end

function UMG_HerbologyBadge_VictorySettlement_C:OnConstruct()
end

function UMG_HerbologyBadge_VictorySettlement_C:OnDestruct()
  self:_StopProgressAnimation()
end

function UMG_HerbologyBadge_VictorySettlement_C:_InitPanel()
  local data = self.initData
  local bSuccess = data.bSuccess or false
  local claimedPoint = data.claimedPoint or 0
  local pointThisWeek = data.pointThisWeek or 0
  local awardPointRequire = data.awardPointRequire or 0
  local awardList = data.awardList or {}
  if bSuccess then
    self.Text_Title:SetText("\230\140\145\230\136\152\230\136\144\229\138\159")
  else
    self.Text_Title:SetText("\230\140\145\230\136\152\229\164\177\232\180\165")
  end
  self.NRCText_Integral:SetText(tostring(claimedPoint))
  self.NRCText_ThisWeekIntegral:SetText(string.format("%d/%d", pointThisWeek, awardPointRequire))
  if awardPointRequire > 0 and pointThisWeek >= awardPointRequire then
    self.NRCText_31:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCText_31:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if bSuccess then
    self.CanvasPanel_Succeed:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.AwardList and #awardList > 0 then
      self.AwardList:InitList(awardList)
    end
  else
    self.CanvasPanel_Succeed:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:_StartProgressAnimation(pointThisWeek, awardPointRequire)
end

function UMG_HerbologyBadge_VictorySettlement_C:_StartProgressAnimation(pointThisWeek, awardPointRequire)
  self:_StopProgressAnimation()
  self.ProgressBar_01:SetPercent(0)
  if awardPointRequire <= 0 then
    return
  end
  self._targetProgress = math.min(pointThisWeek / awardPointRequire, 1.0)
  if self._targetProgress <= 0 then
    return
  end
  self._progressAnimTimer = _G.TimerManager:CreateTimer(self, "VictorySettlement:ProgressAnimation", PROGRESS_ANIM_DURATION, self._OnProgressAnimUpdate, self._OnProgressAnimComplete, PROGRESS_ANIM_DELTA_TIME)
end

function UMG_HerbologyBadge_VictorySettlement_C:_OnProgressAnimUpdate()
  if not self._progressAnimTimer then
    return
  end
  local elapsedTime = self._progressAnimTimer.duration - self._progressAnimTimer.leftTime
  local t = math.min(elapsedTime / self._progressAnimTimer.duration, 1.0)
  local easeT = 1 - (1 - t) ^ 3
  local currentPercent = self._targetProgress * easeT
  self.ProgressBar_01:SetPercent(currentPercent)
end

function UMG_HerbologyBadge_VictorySettlement_C:_OnProgressAnimComplete()
  if self._targetProgress then
    self.ProgressBar_01:SetPercent(self._targetProgress)
  end
  self._progressAnimTimer = nil
end

function UMG_HerbologyBadge_VictorySettlement_C:_StopProgressAnimation()
  if self._progressAnimTimer then
    self._progressAnimTimer:Clear()
    self._progressAnimTimer = nil
  end
end

return UMG_HerbologyBadge_VictorySettlement_C
