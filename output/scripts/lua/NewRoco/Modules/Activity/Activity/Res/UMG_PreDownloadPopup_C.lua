local UMG_PreDownloadPopup_C = _G.NRCPanelBase:Extend("UMG_PreDownloadPopup_C")
local PreDownloadEvent = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")

function UMG_PreDownloadPopup_C:OnActive(_activityInst)
  _G.NRCEventCenter:DispatchEvent(PreDownloadEvent.PreDownloadPanelActive)
  self:AddEventListeners()
  if _activityInst and _activityInst.AttachView then
    _activityInst:AttachView(self)
    self.activityInst = _activityInst
  end
  self.bDownloadLocal = false
  self.cdTimer = false
  if _G.NRCPreDownloadManager:IsPreDownloadResEnabled() then
    self.bDownloadLocal = not _G.NRCPreDownloadManager:IfNeedToDownload()
    Log.Debug("UMG_PreDownloadPopup_C OnActive bDownloadLocal" .. (self.bDownloadLocal and "true" or "false"))
  end
  if self.activityInst then
    if not self.activityData then
      self.activityData = self.activityInst.preDownloadData
    end
    if self.activityData then
      if self.bDownloadLocal then
        self:RefreshUIByActivityStatus()
      elseif self.activityData.book_download then
        local downloadingProgress = _G.NRCPreDownloadManager:GetDownloadProgress()
        if _G.NRCPreDownloadManager:IsDownloading() then
          if 0 ~= downloadingProgress then
            if downloadingProgress < 0 then
              downloadingProgress = 0
            elseif downloadingProgress > 1 then
              downloadingProgress = 1
            end
            if 1 == downloadingProgress then
              self:ShowProgress(false)
              self:RefreshUIByActivityStatus()
              if not self.bDownloadLocal then
                self.bDownloadLocal = true
                if self.activityInst and self.activityInst.NotifyDownloadFinished then
                  self.activityInst:NotifyDownloadFinished()
                end
              end
            else
              self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
              self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
              self:ShowProgress(true)
            end
          else
            self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
            self:ShowProgress(true)
          end
        else
          Log.Debug("UMG_PreDownloadPopup_C OnActive downloadingProgress IsDownloading false")
          if _G.NRCPreDownloadManager:IsPreDownloadResEnabled() then
            local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_tips").str or ""
            if 0 ~= downloadingProgress then
              self:ShowProgress(true)
              text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips").str or ""
            else
              self:ShowProgress(false)
            end
            self.ClaimBtn:SetBtnText(text)
            self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
            self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
          else
            local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked").str or ""
            self.ReceivedBtn:SetBtnText(text)
            self.ReceivedBtn:SetShowLockIcon(false)
            self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
            self:ShowProgress(false)
          end
        end
      elseif _G.NRCPreDownloadManager:IsDownloading() then
        self:ShowProgress(true)
      else
        self:RefreshUIByActivityStatus()
      end
    end
    self.activityId = self.activityInst.activityConf.id
    self:ShowRewardUI()
    local activityConf = _G.DataConfigManager:GetActivityConf(self.activityId)
    if activityConf then
      self.Text_Title:SetText(activityConf.activity_name or "")
      local endTime = ActivityUtils.ToTimestamp(activityConf.disappear_time)
      local startTime = ActivityUtils.ToTimestamp(activityConf.appear_time)
      local curTime = _G.ZoneServer:GetServerTime() / 1000
      if startTime < curTime and endTime > curTime then
        local remainingDay = math.floor((endTime - curTime) / 86400)
        local remainingHour = math.floor((endTime - curTime - remainingDay * 24 * 60 * 60) / 3600)
        local dayStr = remainingDay > 0 and _G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_day") and _G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_day").str and string.format(_G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_day").str, remainingDay) or ""
        local hourStr = remainingHour > 0 and _G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_hour") and _G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_hour").str and string.format(_G.DataConfigManager:GetActivityGlobalConfig("activity_remain_time_hour").str, remainingHour) or ""
        self.Text_TimeRemaining:SetText(dayStr .. hourStr)
        self.Desc:SetText(activityConf.prompt_text or "")
        ActivityUtils.GetCdnImageByActivityConf(activityConf.id, FPartial(self.OnGetCdnImage, self))
      end
    else
    end
  end
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
end

function UMG_PreDownloadPopup_C:OnGetCdnImage(bSuccess, imagePath)
  if bSuccess and UE.UBlueprintPathsLibrary.FileExists(imagePath) then
    local cdnTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(self, imagePath)
    self.BgImage:SetBrushFromTexture(cdnTexture)
  end
end

function UMG_PreDownloadPopup_C:ShowRewardUI()
  local rewardConf = _G.DataConfigManager:GetPreDownloadConf(self.activityId)
  if rewardConf and rewardConf.reward_id then
    local reward = _G.DataConfigManager:GetRewardConf(rewardConf.reward_id)
    if reward and reward.RewardItem then
      local rewardList = {}
      for i, rewardItem in ipairs(reward.RewardItem) do
        local rewardData = {
          itemType = rewardItem.Type,
          itemId = rewardItem.Id,
          itemNum = rewardItem.Count,
          index = i,
          bShowNum = true
        }
        table.insert(rewardList, rewardData)
      end
      if table.isNotEmpty(rewardList) then
        self.Award:InitGridView(rewardList)
        self.Award:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.activityData and self.activityData.rewarded then
          self.Received:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        return
      end
    end
  end
  self.Award:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_PreDownloadPopup_C:AddEventListeners()
  if self.activityData then
    if self.activityData.book_download then
      self.ClaimBtn.RedDot:SetupKey(498)
    else
      self.ClaimBtn.RedDot:SetupKey(491)
    end
  end
  self:AddButtonListener(self.ClaimBtn.btnLevelUp, self.OnClaimButtonClicked)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.PauseBtn.btnLevelUp, self.OnPauseBtnClicked)
  self:AddButtonListener(self.ParticularsBtn, self.OnParticularsBtnClicked)
  _G.NRCEventCenter:RegisterEvent("PreDownloadProgressNotify", self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
  _G.NRCEventCenter:RegisterEvent("UMG_PreDownloadPopup_C", self, PreDownloadEvent.PreDownloadBatchProgress, self.OnDownloadPercentRefresh)
  _G.NRCEventCenter:RegisterEvent("UMG_PreDownloadPopup_C", self, PreDownloadEvent.PreDownloadStart, self.OnPreDownloadStart)
  _G.NRCEventCenter:RegisterEvent("UMG_PreDownloadPopup_C", self, PreDownloadEvent.PreDownloadPaused, self.OnPreDownloadPaused)
  self:RegisterEvent(self, ActivityModuleEvent.PreDownloadActivityDataUpdate, self.OnActivityDataUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_PreDownloadPopup_C", self, _G.MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnMainLobbyClose)
end

function UMG_PreDownloadPopup_C:OnMainLobbyClose()
  self:DoClose()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
end

function UMG_PreDownloadPopup_C:CheckCondAndDownload()
  if RocoEnv.PLATFORM_WINDOWS then
    return false
  end
  if _G.NRCPreDownloadManager:IsDownloading() then
    return true
  end
  if self.activityInst and self.activityInst.bStoppedByUser then
    return false
  end
  local wifiStatus = UE.UNetworkStatics.GetNetworkState()
  if 2 == wifiStatus then
    _G.NRCPreDownloadManager:StartDownload()
    return true
  end
  Log.Debug("UMG_PreDownloadPopup_C", "CheckNetWorkAndDownload", wifiStatus)
  return false
end

function UMG_PreDownloadPopup_C:ShowProgress(bShow)
  if bShow then
    if _G.NRCPreDownloadManager:IsDownloading() then
      if self.PauseBtn:GetVisibility() ~= UE.ESlateVisibility.Visible then
        self.PauseBtn:SetVisibility(UE.ESlateVisibility.Visible)
      end
      if self.ClaimBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
        self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    elseif self.PauseBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.PauseBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.ProgressBar:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.ProgressBar:SetVisibility(UE.ESlateVisibility.Visible)
    end
    if self.ReceivedBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local localSize = _G.NRCPreDownloadManager:GetLocalDownloadedSize()
    local totalSize = _G.NRCPreDownloadManager:GetTotalSize()
    local progressNum = _G.NRCPreDownloadManager:GetDownloadProgress()
    if progressNum then
      self.ProgressBar:SetPercent(progressNum)
    end
    local progress = localSize .. "/" .. totalSize
    local speedText = _G.NRCPreDownloadManager:GetDownloadSpeedText()
    if not string.IsNilOrEmpty(speedText) and _G.NRCPreDownloadManager:IsDownloading() then
      progress = "(" .. speedText .. ")" .. progress
    end
    self.Progress:SetText(progress)
    if self.Progress:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.Progress:SetVisibility(UE.ESlateVisibility.Visible)
    end
  else
    if self.PauseBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.PauseBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.ProgressBar:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.ProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.Progress:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.Progress:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PreDownloadPopup_C:RefreshUIByActivityStatus()
  if self.activityData then
    if self.bDownloadLocal and self.activityData.rewarded then
      self:ShowProgress(false)
      local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_award_got") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_award_got").str or ""
      self.ReceivedBtn:SetBtnText(text)
      self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Visible)
      self.ReceivedBtn:SetShowLockIcon(false)
      self.ReceivedBtn:SetClickAble(false)
      self.Received:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Get)
      self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      self:ShowProgress(false)
    elseif self.bDownloadLocal then
      local downloadedText = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_finish") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_finish").str or ""
      self.ClaimBtn:SetBtnText(downloadedText)
      self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
      self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      self:ShowProgress(false)
    elseif not _G.NRCPreDownloadManager:IsPreDownloadResEnabled() then
      if self.activityData.book_download then
        local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked").str or ""
        self.ReceivedBtn:SetBtnText(text)
        self.ReceivedBtn:SetShowLockIcon(false)
        self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Visible)
        self.ReceivedBtn:SetClickAble(false)
        self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ShowProgress(false)
      else
        local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_book_available") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_book_available").str or ""
        self.ClaimBtn:SetBtnText(text)
        self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
        self.ClaimBtn:SetClickAble(true)
        self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ShowProgress(false)
      end
    else
      local text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_tips").str or ""
      local progress = _G.NRCPreDownloadManager:GetDownloadProgress()
      Log.Debug("progress is " .. progress)
      if progress > 0 then
        text = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips").str or ""
        self:ShowProgress(true)
      else
        self:ShowProgress(false)
      end
      self.ClaimBtn:SetBtnText(text)
      self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
      self.ClaimBtn:SetClickAble(true)
      self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PreDownloadPopup_C:OnActivityDataUpdate(updateData)
  self.activityData = updateData
  self:RefreshUIByActivityStatus()
end

function UMG_PreDownloadPopup_C:OnPreDownloadStart()
  Log.Debug("UMG_PreDownloadPopup_C OnPreDownloadStart")
  self:ShowProgress(true)
  self.PauseBtn:SetVisibility(UE.ESlateVisibility.Visible)
  self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_PreDownloadPopup_C:OnPreDownloadPaused()
  Log.Debug("UMG_PreDownloadPopup_C OnPreDownloadPaused")
  self.PauseBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  local pauseText = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_resume_tips").str or ""
  self.ClaimBtn:SetBtnText(pauseText)
  self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
  self.ClaimBtn:SetClickAble(true)
  self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  if self.Progress:GetVisibility() == UE.ESlateVisibility.Visible then
    local curText = self.Progress:GetText()
    if curText and curText:find("%(") then
      curText = curText:gsub("%([^)]+%)", "")
      self.Progress:SetText(curText)
    end
  end
end

function UMG_PreDownloadPopup_C:OnDownloadPercentRefresh(percent, totalSize, downloadedSize, speed)
  if percent < 0 then
    percent = 0
  elseif percent > 1 then
    percent = 1
  end
  if 1 == percent then
    self.bDownloadLocal = true
    if self.PauseBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.PauseBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.ProgressBar:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.ProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.Progress:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.Progress:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    if self.ProgressBar:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.ProgressBar:SetVisibility(UE.ESlateVisibility.Visible)
    end
    if self.Progress:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.Progress:SetVisibility(UE.ESlateVisibility.Visible)
    end
  end
  self.ProgressBar:SetPercent(percent)
  local text = string.format("%s/%s", downloadedSize, totalSize)
  if not string.IsNilOrEmpty(speed) then
    text = "(" .. speed .. ")" .. text
  end
  self.Progress:SetText(text)
end

function UMG_PreDownloadPopup_C:OnCdFinish()
  if self.cdTimer then
    _G.TimerManager:RemoveTimer(self.cdTimer)
    self.cdTimer = nil
  end
end

function UMG_PreDownloadPopup_C:OnClaimButtonClicked()
  if self.cdTimer then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetActivityGlobalConfig("operating_cd_tips") and _G.DataConfigManager:GetActivityGlobalConfig("operating_cd_tips").str or "")
    return
  else
    self.cdTimer = _G.TimerManager:CreateTimer(self, "PredownloadCdTimer", 1, nil, self.OnCdFinish, 0.1)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_PreDownloadPopup_C:OnClaimButtonClicked")
  if self.bDownloadLocal and self.activityInst then
    self.activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.GetReward)
    return
  end
  if self.activityInst then
    if _G.NRCPreDownloadManager:IsPreDownloadResEnabled() then
      _G.NRCPreDownloadManager:StartDownload(true)
      if self.ActivityData and not self.ActivityData.book_download then
        self.activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Join)
      end
    else
      _G.NRCEventCenter:DispatchEvent(PreDownloadEvent.PreDownloadBooked)
      self.activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Join)
    end
  end
end

function UMG_PreDownloadPopup_C:OnPauseBtnClicked()
  if self.cdTimer then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetActivityGlobalConfig("operating_cd_tips") and _G.DataConfigManager:GetActivityGlobalConfig("operating_cd_tips").str or "")
    return
  else
    self.cdTimer = _G.TimerManager:CreateTimer(self, "PredownloadCdTimer", 1, nil, self.OnCdFinish, 0.1)
  end
  if self.activityInst then
    self.activityInst.bStoppedByUser = true
  end
  _G.NRCPreDownloadManager:PauseDownload(true)
end

function UMG_PreDownloadPopup_C:OnParticularsBtnClicked()
  if self.activityInst then
    self.activityInst:OnBtnShowActivityDesc()
  end
end

function UMG_PreDownloadPopup_C:OnCloseBtnClicked()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008006, "UMG_PreDownloadPopup_C:DoClose")
  self:DoClose()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
end

function UMG_PreDownloadPopup_C:OnPcClose()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008006, "UMG_PreDownloadPopup_C:DoClose")
  self:DoClose()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
end

function UMG_PreDownloadPopup_C:OnPreDownloadFinished(bSuccess)
  if bSuccess then
    self.bDownloadLocal = true
    if self.activityData then
      if self.activityData.rewarded then
        self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Visible)
        local receiveText = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_award_got") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_award_got").str or ""
        self.Received:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.Get)
        self.ReceivedBtn:SetBtnText(receiveText)
        self.ReceivedBtn:SetClickAble(false)
        self.ReceivedBtn:SetShowLockIcon(false)
        self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      else
        self.ClaimBtn:SetVisibility(UE.ESlateVisibility.Visible)
        local receiveText = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_finish") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_finish").str or ""
        self.ClaimBtn:SetBtnText(receiveText)
        self.ClaimBtn:SetClickAble(true)
        self.ReceivedBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    end
    local progress = "100%"
    self.ProgressBar:SetPercent(1)
    self.Progress:SetText(progress)
    if self.ProgressBar:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.ProgressBar:SetVisibility(UE.ESlateVisibility.Visible)
    end
    if self.Progress:GetVisibility() ~= UE.ESlateVisibility.Visible then
      self.Progress:SetVisibility(UE.ESlateVisibility.Visible)
    end
    if self.PauseBtn:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
      self.PauseBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PreDownloadPopup_C:RemoveEventListeners()
  self:RemoveButtonListener(self.ClaimBtn.btnLevelUp)
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.PauseBtn.btnLevelUp)
  self:RemoveButtonListener(self.ParticularsBtn)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadBatchProgress, self.OnDownloadPercentRefresh)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadStart, self.OnPreDownloadStart)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadPaused, self.OnPreDownloadPaused)
  self:UnRegisterEvent(self, ActivityModuleEvent.PreDownloadActivityDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnMainLobbyClose)
end

function UMG_PreDownloadPopup_C:OnDeactive()
  self:RemoveEventListeners()
  _G.NRCEventCenter:DispatchEvent(PreDownloadEvent.PreDownloadPanelDeactive)
end

return UMG_PreDownloadPopup_C
