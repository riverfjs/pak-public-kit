local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local UMG_ShootVideoPanel_C = _G.NRCPanelBase:Extend("UMG_ShootVideoPanel_C")

function UMG_ShootVideoPanel_C:Construct()
  NRCPanelBase.Construct(self)
end

function UMG_ShootVideoPanel_C:OnConstruct()
  self:RegisterEventListener()
  self:PCKeySetting()
  self.maxRecordingTime = MagicReplayUtils.GetRecordingMaxTime()
end

function UMG_ShootVideoPanel_C:OnDestruct()
  self:UnregisterEventListener()
end

function UMG_ShootVideoPanel_C:RegisterEventListener()
  self.ParentModule = _G.NRCModuleManager:GetModule("MagicReplayModule")
  if self.ParentModule then
    self.ParentModule:RegisterEvent(self, MagicReplayModuleEvent.EnterRecordState, self.EnterRecordState)
    _G.NRCEventCenter:RegisterEvent("UMG_ShootVideoPanel_C", self, MagicReplayModuleEvent.EnterPreviewState, self.EnterPreviewState)
    self.ParentModule:RegisterEvent(self, MagicReplayModuleEvent.PlayCountDownNum, self.PlayCountDownNum)
    self.ParentModule:RegisterEvent(self, MagicReplayModuleEvent.StopCountDownNum, self.StopCountDownNum)
    self.ParentModule:RegisterEvent(self, MagicReplayModuleEvent.RefreshRecordPanel, self.RefreshUI)
  end
end

function UMG_ShootVideoPanel_C:UnregisterEventListener()
  if self.ParentModule then
    self.ParentModule:UnRegisterEvent(self, MagicReplayModuleEvent.EnterRecordState)
    _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.EnterPreviewState, self.EnterPreviewState)
    self.ParentModule:UnRegisterEvent(self, MagicReplayModuleEvent.PlayCountDownNum)
    self.ParentModule:UnRegisterEvent(self, MagicReplayModuleEvent.StopCountDownNum)
    self.ParentModule:UnRegisterEvent(self, MagicReplayModuleEvent.RefreshRecordPanel)
  end
end

function UMG_ShootVideoPanel_C:OnActive(args)
  self.Handler = nil
  self:StopAllAnimations()
  self:BindInputAction(args)
  self:RefreshUI(args)
  self:PlayAnimation(self.In)
end

function UMG_ShootVideoPanel_C:OnDeactive()
  UE4Helper.SetDesiredShowCursor(false, "RecordPanel")
  UE4Helper.ReleaseDesiredShowCursor("RecordPanel")
  self:UnBindInputAction()
end

function UMG_ShootVideoPanel_C:PCKeySetting()
  if SystemSettingModuleCmd then
    self.BtnExit:SetPCKey("IA_MagicReplay_ShootVideo_Exit")
    self.Confirm:SetPCKey("IA_MagicReplay_ShootVideo_Confirm")
    self.Reshoot:SetPCKey("IA_MagicReplay_ShootVideo_Restart")
    self.ScreenRecording:SetPCKey("IA_MagicReplay_ShootVideo_Record")
    self.Progress:SetPCKey("IA_MagicReplay_ShootVideo_Record")
  end
end

function UMG_ShootVideoPanel_C:BindInputAction(args)
  if self.bindActionSucceed then
    return
  end
  self:AddButtonListener(self.ClickArea, self.OnRecordClicked)
  self:AddButtonListener(self.Progress.btnLevelUp, self.OnRecordClicked)
  self:AddButtonListener(self.ScreenRecording.btnLevelUp, self.OnRecordClicked)
  self:AddButtonListener(self.BtnExit.btnLevelUp, self.OnExitClicked)
  self:AddButtonListener(self.Confirm.btnLevelUp, self.OnConfirmClicked)
  self:AddButtonListener(self.Reshoot.btnLevelUp, self.OnRestartClicked)
  if args.StateName == "RecordPrepareState" or args.StateName == "RecordProcessState" then
    local mappingContext = self:AddInputMappingContext("IMC_MagicReplay_ShootVideo")
    if mappingContext then
      local actions = {
        {
          name = "IA_MagicReplay_ShootVideo_Record",
          method = "OnRecordClicked"
        },
        {
          name = "IA_MagicReplay_ShootVideo_Exit",
          method = "OnExitClicked"
        },
        {
          name = "IA_MagicReplay_ShootVideo_Exit_Esc",
          method = "OnExitClicked"
        }
      }
      for _, action in ipairs(actions) do
        mappingContext:BindAction(action.name, self, action.method)
      end
    end
  elseif args.StateName == "PreviewPrepareState" or args.StateName == "PreviewProcessState" then
    local mappingContext = self:AddInputMappingContext("IMC_MagicReplay_Preview")
    if mappingContext then
      local actions = {
        {
          name = "IA_MagicReplay_ShootVideo_Exit",
          method = "OnExitClicked"
        },
        {
          name = "IA_MagicReplay_ShootVideo_Confirm",
          method = "OnConfirmClicked"
        },
        {
          name = "IA_MagicReplay_ShootVideo_Restart",
          method = "OnRestartClicked"
        },
        {
          name = "IA_MagicReplay_ShootVideo_Exit_Esc",
          method = "OnExitClicked"
        }
      }
      for _, action in ipairs(actions) do
        mappingContext:BindAction(action.name, self, action.method)
      end
    end
  end
  self.bindActionSucceed = true
  self.recordClickBan = false
end

function UMG_ShootVideoPanel_C:UnBindInputAction()
  self:RemoveButtonListener(self.ClickArea)
  self:RemoveButtonListener(self.Progress.btnLevelUp)
  self:RemoveButtonListener(self.ScreenRecording.btnLevelUp)
  self:RemoveButtonListener(self.BtnExit.btnLevelUp)
  self:RemoveButtonListener(self.Confirm.btnLevelUp)
  self:RemoveButtonListener(self.Reshoot.btnLevelUp)
  local mappingContext = self:GetInputMappingContext("IMC_MagicReplay_ShootVideo")
  if mappingContext then
    local actions = {
      {
        name = "IA_MagicReplay_ShootVideo_Record"
      },
      {
        name = "IA_MagicReplay_ShootVideo_Exit"
      },
      {
        name = "IA_MagicReplay_ShootVideo_Exit_Esc"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
    self:RemoveInputMappingContext("IMC_MagicReplay_ShootVideo")
  end
  mappingContext = self:GetInputMappingContext("IMC_MagicReplay_Preview")
  if mappingContext then
    local actions = {
      {
        name = "IA_MagicReplay_ShootVideo_Exit"
      },
      {
        name = "IA_MagicReplay_ShootVideo_Confirm"
      },
      {
        name = "IA_MagicReplay_ShootVideo_Restart"
      },
      {
        name = "IA_MagicReplay_ShootVideo_Exit_Esc"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
    self:RemoveInputMappingContext("IMC_MagicReplay_Preview")
  end
  self.bindActionSucceed = false
  self.recordClickBan = false
end

function UMG_ShootVideoPanel_C:OnRecordClicked()
  if not self.recordClickBan then
    _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OnSwitchRecordState)
  end
end

function UMG_ShootVideoPanel_C:OnRestartClicked()
  _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OpenToolRestartButtonPopup)
end

function UMG_ShootVideoPanel_C:OnConfirmClicked()
  _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnManualStopPreview)
end

function UMG_ShootVideoPanel_C:OnExitClicked()
  if self.StateName == "RecordProcessState" or self.StateName == "RecordPrepareState" then
    _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OpenToolExitButtonPopup, MagicReplayModuleEnum.ModuleOpType.Record)
  elseif self.StateName == "PreviewProcessState" or self.StateName == "PreviewPrepareState" then
    _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.OpenToolExitButtonPopup, MagicReplayModuleEnum.ModuleOpType.Preview)
  end
end

function UMG_ShootVideoPanel_C:EnterRecordState()
  local args = {
    StateName = "RecordPrepareState"
  }
  self:RefreshUI(args)
  self:UnBindInputAction()
  self:BindInputAction(args)
end

function UMG_ShootVideoPanel_C:EnterPreviewState()
  local args = {
    StateName = "PreviewPrepareState"
  }
  self:RefreshUI(args)
  self:UnBindInputAction()
  self:BindInputAction(args)
end

function UMG_ShootVideoPanel_C:PlayCountDownNum(num)
  if self.Switcher then
    self.Switcher:SetActiveWidgetIndex(1)
  end
  self:PlayAnimation(self.reciprocal)
  self.recordClickBan = true
end

function UMG_ShootVideoPanel_C:StopCountDownNum()
  self:PlayAnimation(self.End)
end

function UMG_ShootVideoPanel_C:RefreshUI(args)
  if args and args.StateName then
    self.StateName = args.StateName
    if self.Switcher then
      self.Switcher:SetActiveWidgetIndex(0)
    end
    if args.StateName == "RecordPrepareState" then
      if self.ClickArea then
        self.ClickArea:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.BtnExit:SetVisibility(UE4.ESlateVisibility.Visible)
      self.TimeSwitcher:SetActiveWidgetIndex(0)
      self.TitleText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Text_ClickStart:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_ClickStart:SetText(_G.LuaText.mark_video_ready_tips)
      self.TitleText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.RecordingBtnSwitcher:SetActiveWidgetIndex(0)
      UE4Helper.SetDesiredShowCursor(false, "RecordPanel")
      UE4Helper.ReleaseDesiredShowCursor("RecordPanel")
    elseif args.StateName == "RecordProcessState" then
      if self.ClickArea then
        self.ClickArea:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.BtnExit:SetVisibility(UE4.ESlateVisibility.Visible)
      self.TimeSwitcher:SetActiveWidgetIndex(0)
      self.TitleText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Text_CountDown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_ClickStart:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.TitleText_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TitleText_1:SetText(_G.LuaText.mark_video_recording_tips)
      self.RecordingBtnSwitcher:SetActiveWidgetIndex(1)
      UE4Helper.SetDesiredShowCursor(false, "RecordPanel")
      UE4Helper.ReleaseDesiredShowCursor("RecordPanel")
    elseif args.StateName == "PreviewPrepareState" then
      if self.ClickArea then
        self.ClickArea:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.BtnExit:SetVisibility(UE4.ESlateVisibility.Visible)
      self.TimeSwitcher:SetActiveWidgetIndex(1)
      self.RecordingBtnSwitcher:SetActiveWidgetIndex(2)
      UE4Helper.SetDesiredShowCursor(true, "RecordPanel")
    elseif args.StateName == "PreviewProcessState" then
      if self.ClickArea then
        self.ClickArea:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.BtnExit:SetVisibility(UE4.ESlateVisibility.Visible)
      self.TimeSwitcher:SetActiveWidgetIndex(1)
      self.RecordingBtnSwitcher:SetActiveWidgetIndex(2)
      UE4Helper.SetDesiredShowCursor(true, "RecordPanel")
    end
  end
  if not self.maxRecordingTime then
    self.maxRecordingTime = MagicReplayUtils.GetRecordingMaxTime()
  end
  self.Text_CountDown:SetText(self.maxRecordingTime)
  self.TitleText:SetText(_G.LuaText.mark_video_recording_title)
end

function UMG_ShootVideoPanel_C:OnTick()
  if self.ParentModule:IsNetRecording() then
    local recordingTime = math.floor(self.ParentModule:GetRecordingTime())
    if not self.maxRecordingTime then
      self.maxRecordingTime = MagicReplayUtils.GetRecordingMaxTime()
    end
    self.Text_CountDown:SetText(math.clamp(self.maxRecordingTime - recordingTime, 0, self.maxRecordingTime))
  end
end

function UMG_ShootVideoPanel_C:OnAnimationFinished(Animation)
  if not self then
    return
  end
  if Animation == self.Word_out then
    if self.Switcher then
      self.Switcher:SetActiveWidgetIndex(0)
    end
  elseif Animation == self.FadeOut then
  elseif Animation == self.reciprocal then
    self.recordClickBan = false
  end
end

function UMG_ShootVideoPanel_C:ClosePanel()
end

return UMG_ShootVideoPanel_C
