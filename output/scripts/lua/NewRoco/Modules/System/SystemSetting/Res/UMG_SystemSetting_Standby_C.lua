local UMG_SystemSetting_Standby_C = _G.NRCPanelBase:Extend("UMG_SystemSetting_Standby_C")

function UMG_SystemSetting_Standby_C:OnConstruct()
  self._sleepUpdateTimer = nil
end

function UMG_SystemSetting_Standby_C:OnActive(targetFrameQuality, targetBrightness, originalFrameQuality, originalBrightness)
  Log.Warning(string.format("UMG_SystemSetting_Standby_C:OnActive \232\191\155\229\133\165\229\190\133\230\156\186\231\149\140\233\157\162 \231\155\174\230\160\135\229\184\167\231\142\135%s\239\188\140\229\142\159\229\167\139\229\184\167\231\142\135%s", targetFrameQuality, originalFrameQuality))
  UE4Helper.SetEnableWorldRendering(false, nil, "UMG_SystemSetting_Standby_C")
  UE4.UNRCQualityLibrary.SetFrameQuality(targetFrameQuality)
  _G.NRCSDKManager:SetQualityToApm()
  self.originalFrameQuality = originalFrameQuality
  self.originalBrightness = originalBrightness
  self:InitSleepPanel()
  if self._sleepUpdateTimer and _G.TimerManager and _G.TimerManager.RemoveTimer then
    _G.TimerManager:RemoveTimer(self._sleepUpdateTimer)
    self._sleepUpdateTimer = nil
  end
  if _G.TimerManager and _G.TimerManager.CreateTimer then
    self._sleepUpdateTimer = _G.TimerManager:CreateTimer(self, "UMG_SystemSetting_Standby_C.Update", math.maxinteger, self.OnUpdateSleepPanel, nil, 1)
  end
  self:OnAddEventListener()
end

function UMG_SystemSetting_Standby_C:InitSleepPanel()
  self:_UpdateTimeAndBattery()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local gender = 1
  if player and player.gender then
    gender = player.gender
  end
  if 2 == gender then
    self.Icon:SetPath("Texture2D'/Game/NewRoco/Modules/System/SystemSetting/Raw/Textures/img_Standby2.img_Standby2'")
  else
    self.Icon:SetPath("Texture2D'/Game/NewRoco/Modules/System/SystemSetting/Raw/Textures/img_Standby1.img_Standby1'")
  end
end

function UMG_SystemSetting_Standby_C:OnDeactive()
  UE4.UNRCQualityLibrary.SetFrameQuality(self.originalFrameQuality)
  UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_SystemSetting_Standby_C")
  _G.NRCSDKManager:SetQualityToApm()
  if self._sleepUpdateTimer and _G.TimerManager and _G.TimerManager.RemoveTimer then
    _G.TimerManager:RemoveTimer(self._sleepUpdateTimer)
    self._sleepUpdateTimer = nil
  end
end

function UMG_SystemSetting_Standby_C:OnAddEventListener()
  self:AddButtonListener(self.NRCButton_29, self.OnQuitSleepModeButtonClick)
end

function UMG_SystemSetting_Standby_C:OnQuitSleepModeButtonClick()
  Log.Warning("UMG_SystemSetting_Standby_C:OnQuitSleepModeButtonClick \233\128\154\232\191\135\230\140\137\233\146\174\233\128\128\229\135\186\229\190\133\230\156\186\231\149\140\233\157\162")
  self:DoClose()
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.QuitSleepMode)
end

function UMG_SystemSetting_Standby_C:_UpdateTimeAndBattery()
  local now = os.date("*t")
  local hourStr = string.format("%02d", tonumber(now and now.hour or 0) or 0)
  local minuteStr = string.format("%02d", tonumber(now and now.min or 0) or 0)
  local monthStr = string.format("%02d", tonumber(now and now.month or 1) or 1)
  local dayStr = string.format("%02d", tonumber(now and now.day or 1) or 1)
  if self.Text01 and self.Text01.SetText then
    self.Text01:SetText(hourStr)
  end
  if self.Text02 and self.Text02.SetText then
    self.Text02:SetText(minuteStr)
  end
  if self.Text03 and self.Text03.SetText then
    self.Text03:SetText(monthStr)
  end
  if self.Text04 and self.Text04.SetText then
    self.Text04:SetText(dayStr)
  end
  local wday = now and now.wday or 1
  local weekNames = {
    "\230\151\165",
    "\228\184\128",
    "\228\186\140",
    "\228\184\137",
    "\229\155\155",
    "\228\186\148",
    "\229\133\173"
  }
  local weekStr = "\229\145\168" .. (weekNames[wday] or weekNames[1])
  if self.Text05 and self.Text05.SetText then
    self.Text05:SetText(weekStr)
  end
  local level = 0
  if UE4 and UE4.UMobileDataFunctionLibrary and UE4.UMobileDataFunctionLibrary.GetBatteryLevel then
    level = tonumber(UE4.UMobileDataFunctionLibrary.GetBatteryLevel()) or 0
  end
  self.Dian1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Dian2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Dian3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if level <= 33 then
    if self.Dian1 then
      self.Dian1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif level <= 66 then
    if self.Dian1 then
      self.Dian1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Dian2 then
      self.Dian2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    if self.Dian1 then
      self.Dian1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Dian2 then
      self.Dian2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Dian3 then
      self.Dian3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_SystemSetting_Standby_C:OnUpdateSleepPanel()
  self:_UpdateTimeAndBattery()
end

return UMG_SystemSetting_Standby_C
