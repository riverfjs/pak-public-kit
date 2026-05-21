local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local UMG_TaskSummary_GroupPhoto_C = _G.NRCPanelBase:Extend("UMG_TaskSummary_GroupPhoto_C")

function UMG_TaskSummary_GroupPhoto_C:OnConstruct()
  UE4Helper.SetDesiredShowCursor(true, "UMG_TaskSummary_GroupPhoto_C")
  self.TODData = {
    [Enum.TimeOfDay.TOD_DAWN] = {
      {StartTime = 4, EndTime = 8}
    },
    [Enum.TimeOfDay.TOD_DAY] = {
      {StartTime = 8, EndTime = 16}
    },
    [Enum.TimeOfDay.TOD_TWILIGHT] = {
      {StartTime = 16, EndTime = 20}
    },
    [Enum.TimeOfDay.TOD_EVENING] = {
      {StartTime = 20, EndTime = 24},
      {StartTime = 0, EndTime = 4}
    }
  }
  self.customData = nil
  self.Lock = false
  self:SetChildViews(self.UMG_TaskPhoto)
  self:OnAddEventListener()
end

function UMG_TaskSummary_GroupPhoto_C:OnDestruct()
  UE4Helper.ReleaseDesiredShowCursor("UMG_TaskSummary_GroupPhoto_C")
end

function UMG_TaskSummary_GroupPhoto_C:OnActive(tip)
  self.UMG_TaskPhoto:OnAddEventListener()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local curModule = self.module
  self.tipsDisplayController = curModule and curModule.getTaskSummaryTipsController
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
  if tip then
    self:OnPlayTips(tip)
  end
end

function UMG_TaskSummary_GroupPhoto_C:OnDeactive()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
  self:UnRegisterEvent(self, TaskModuleEvent.SwitchAvatarSuitComplete, self.OnSwitchAvatarSuitComplete)
  self.UMG_TaskPhoto:OnRemoveEventListener()
end

function UMG_TaskSummary_GroupPhoto_C:OnAddEventListener()
  self:RegisterEvent(self, TaskModuleEvent.SwitchAvatarSuitComplete, self.OnSwitchAvatarSuitComplete)
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnClickbtnCloseRenamePanel)
end

function UMG_TaskSummary_GroupPhoto_C:OnSwitchAvatarSuitComplete()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  self:PlayAnimation(self.In)
end

function UMG_TaskSummary_GroupPhoto_C:OnPlayTips(tip)
  self.customData = tip.customData
  self:SetPanelInfo()
end

function UMG_TaskSummary_GroupPhoto_C:SetTaskPhotoInfo(SetBgSuccess)
  Log.Debug("UMG_TaskSummary_GroupPhoto_C:SetTaskPhotoInfo  SetBgSuccess", SetBgSuccess)
  self:DoSetTaskPhotoInfo()
  local bUseAvatarImageCache = self.UMG_TaskPhoto:IsUseAvatarImageCache()
  if bUseAvatarImageCache then
    self:OnSwitchAvatarSuitComplete()
  end
end

function UMG_TaskSummary_GroupPhoto_C:DoSetTaskPhotoInfo()
  self.UMG_TaskPhoto:SetPlayerData(self.customData, "popup")
  self.UMG_TaskPhoto:SetpanelName("TaskSummary_GroupPhoto")
  self.UMG_TaskPhoto:SetPlayerPath()
end

function UMG_TaskSummary_GroupPhoto_C:IconSetPathSuccess()
  self:CancelDelay()
  self:SetTaskPhotoInfo(true)
end

function UMG_TaskSummary_GroupPhoto_C:IconSetPathFailed()
  self:CancelDelay()
  self:SetTaskPhotoInfo(false)
end

function UMG_TaskSummary_GroupPhoto_C:IconSetPathOutTime()
  self:CancelDelay()
  self:SetTaskPhotoInfo(false)
end

function UMG_TaskSummary_GroupPhoto_C:SetPanelInfo()
  local TaskSummaryConf = _G.DataConfigManager:GetTaskSummary(self.customData.summary_id)
  if not TaskSummaryConf then
    Log.ErrorFormat("Invalid summary_id(%s).", self.customData.summary_id)
    return
  end
  local nowTime = os.date("*t", self.customData.tod)
  local Index = 0
  for i, Tod in pairs(self.TODData) do
    for j, _Tod in ipairs(Tod) do
      if nowTime.hour >= _Tod.StartTime and nowTime.hour < _Tod.EndTime then
        Index = i
      end
    end
  end
  local BgPath = TaskSummaryConf.res_conf[1].bg_res
  local TodTime = tonumber(TaskSummaryConf.light_conf[1].light_para[1])
  for i, TaskSummary in ipairs(TaskSummaryConf.res_conf) do
    if self:FindPath(TaskSummary.tod, Index) and self:FindPath(TaskSummary.weather, self.customData.weather2) then
      BgPath = TaskSummary.bg_res
      break
    end
  end
  for i, TaskSummary in ipairs(TaskSummaryConf.light_conf) do
    if self:FindPath(TaskSummary.tod_pc, Index) and self:FindPath(TaskSummary.weather_pc, self.customData.weather2) then
      TodTime = tonumber(TaskSummary.light_para[1])
      break
    end
  end
  Log.Debug(BgPath, TodTime, Index, self.customData.summary_id, "UMG_TaskSummary_GroupPhoto_C:SetPanelInfo")
  self.PanelBg:SetPathWithSuccessAndFailedCallBack(BgPath, {
    self,
    self.IconSetPathSuccess
  }, {
    self,
    self.IconSetPathFailed
  })
  self:DelaySeconds(2, function()
    self:IconSetPathOutTime()
  end)
  self.Text_Title:SetText(TaskSummaryConf.task_name)
  self.Text:SetText(TaskSummaryConf.task_des)
end

function UMG_TaskSummary_GroupPhoto_C:FindPath(Conf, Param)
  for i, _ in ipairs(Conf) do
    if Param == _ then
      return true
    end
  end
end

function UMG_TaskSummary_GroupPhoto_C:OnAllTipsFinished()
  self:ClosePanel()
end

function UMG_TaskSummary_GroupPhoto_C:OnClickbtnCloseRenamePanel()
  if self.tipsDisplayController then
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  else
    if self.Lock then
      return
    end
    self:SetLock()
    self:DoClose()
  end
end

function UMG_TaskSummary_GroupPhoto_C:ClosePanel()
  if self.Lock then
    return
  end
  self:SetLock()
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  self:PlayAnimation(self.Out)
end

function UMG_TaskSummary_GroupPhoto_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

function UMG_TaskSummary_GroupPhoto_C:SetLock()
  self.Lock = not self.Lock
end

return UMG_TaskSummary_GroupPhoto_C
