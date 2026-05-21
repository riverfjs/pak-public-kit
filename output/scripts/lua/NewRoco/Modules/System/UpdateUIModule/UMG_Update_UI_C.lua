local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local UMG_Update_UI_C = _G.NRCPanelBase:Extend("UMG_Update_UI_C")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")

function UMG_Update_UI_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_Update_UI_C", self, UpdateUIModuleEvent.UpdateNewResVersion, self.UpdateResVersion)
  _G.NRCEventCenter:RegisterEvent("UMG_Update_UI_C", self, _G.NRCGlobalEvent.OnShaderBeginPrecompile, self.OnPSOWarmUpBegin)
  _G.NRCEventCenter:RegisterEvent("UMG_Update_UI_C", self, UpdateUIModuleEvent.OnPSOWarmUpEnd, self.OnPSOWarmUpEnd)
  _G.NRCEventCenter:RegisterEvent("UMG_Update_UI_C", self, UpdateUIModuleEvent.PufferDownloadFinish, self.PufferDownloadFinish)
  self.bPufferDownloadFinished = false
  if _G.GlobalConfig.DebugOpenUI then
    self.UMG_Login_Register.Update:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_Login_Register.DownloadCompletes:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_Login_Register.Register:SetVisibility(UE4.ESlateVisibility.Visible)
    self:AddButtonListener(self.UMG_Login_Register.Btn_DropOut.btnLevelUp, self.DebugBtn_DropOutClick)
    return
  end
  self.VideoMap = {}
  self.VideoMap[UEPath.LOGIN_CLOUD_LOOP] = self.videoAsset1
  self.AnimationMap = {}
  self.AnimationEventMap = {}
  self.CanvasMap = {}
  self.CanvasMap[LoginEnum.CanvasNames.UpdateProgressPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Update)
  self.TargetPercent = 0
  self.CurrentPercent = 0
  self.bEnableRepairInUpdate = not not self.UMG_Login_Register.Btn_Repair_Update
  if self.bEnableRepairInUpdate then
    self.UMG_Login_Register.Btn_Repair_Update:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if self.UMG_Login_Register.Compliance then
    self.UMG_Login_Register.Compliance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.LogoCanvas then
    self.LogoCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Update_UI_C:OnPSOWarmUpBegin()
  if self.UMG_Login_Register.Btn_Repair_Update then
    self.UMG_Login_Register.Btn_Repair_Update:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Update_UI_C:OnPSOWarmUpEnd()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnShaderBeginPrecompile, self.OnPSOWarmUpBegin)
  if self.UMG_Login_Register.Btn_Repair_Update and not self.bPufferDownloadFinished then
    self.UMG_Login_Register.Btn_Repair_Update:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Update_UI_C:PufferDownloadFinish()
  self.bPufferDownloadFinished = true
end

function UMG_Update_UI_C:HideFixedFrame()
  if self.FixedFrame then
    self.FixedFrame:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Update_UI_C:OnClickRepair()
  self:DelaySeconds(0.1, function()
    _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Update_UI_C:OnClickRepair")
    _G.NRCModuleManager:DoCmd(UpdateUIModuleCmd.OpenRepairToolsPanel)
    self.UMG_Login_Register.Btn_Repair_Update:CancelSelect()
  end)
end

function UMG_Update_UI_C:DebugBtn_DropOutClick()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    self:DoClose()
  end
end

function UMG_Update_UI_C:OnDisable()
end

function UMG_Update_UI_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, UpdateUIModuleEvent.UpdateNewResVersion, self.UpdateResVersion)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnShaderBeginPrecompile, self.OnPSOWarmUpBegin)
  _G.NRCEventCenter:UnRegisterEvent(self, UpdateUIModuleEvent.OnPSOWarmUpEnd, self.OnPSOWarmUpEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, UpdateUIModuleEvent.PufferDownloadFinish, self.PufferDownloadFinish)
  table.clear(self.VideoMap)
  table.clear(self.AnimationMap)
  table.clear(self.CanvasMap)
end

function UMG_Update_UI_C:UpdateResVersion(NewVersion)
  self.TxtResVersion:SetText(NewVersion)
end

function UMG_Update_UI_C:OnClickAgeHint()
  local Context = DialogContext()
  Context:SetTitle(LuaText.umg_update_ui_1):SetContent("balabala"):SetMode(DialogContext.Mode.OK):SetCallback(self, function()
  end):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Update_UI_C:OnActive()
  self.UMG_Login_Register:OnActive(LoginEnum.PanelType.Update)
  self:SetProgress(0)
  local AppMain = _G.App
  self.TxtAppVersion:SetText(AppMain:GetAppVersion())
  self.TxtResVersion:SetText(AppMain:GetResVersion())
  self.TxtBuild:SetText(AppMain:GetResRevision())
  self:PlayAnimation(self.LogoOut, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
  if AppMain:GetFormalPipeline() then
    self.Text:SetText("")
  else
    self.Text:SetText("\231\160\148\229\143\145\228\184\173\231\137\136\230\156\172 \228\184\141\228\187\163\232\161\168\230\184\184\230\136\143\230\156\128\231\187\136\229\147\129\232\180\168")
  end
end

function UMG_Update_UI_C:OnHaltDownloading()
  local Context = DialogContext()
  Context:SetTitle(LuaText.umg_update_ui_2):SetContent(LuaText.umg_update_ui_3):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
    if result then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateSuspend)
    else
    end
  end):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function LoginUtils.OnDialogResult(result, ConfirmEvent, CancelEvent)
  if result then
    LoginUtils.SendEventToLoginFsm(ConfirmEvent)
  else
    LoginUtils.SendEventToLoginFsm(CancelEvent)
  end
end

function UMG_Update_UI_C:ShowCanvas(CanvasName, TurnOn, AnimationCompleteEvent)
  local CanvasInfo = self.CanvasMap[CanvasName]
  if not CanvasInfo then
    Log.Error("UMG_Login_New_C: Canvas name invalid", CanvasName)
    Log.Dump(self.CanvasMap)
    return
  end
  if TurnOn then
    CanvasInfo.Canvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:TryPlayAnimationAndRegisterEvent(CanvasInfo.ShowAnimationName, AnimationCompleteEvent)
  else
    CanvasInfo.Canvas:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:TryPlayAnimationAndRegisterEvent(CanvasInfo.HideAnimationName, AnimationCompleteEvent)
  end
end

function UMG_Update_UI_C:TryPlayAnimationAndRegisterEvent(InAnimationName, InEvent, PanelOverride)
  if not InAnimationName then
    Log.Debug("UMG_Update_UI_C:TryPlayAnimationAndRegisterEvent:no animation")
    _G.NRCEventCenter:DispatchEvent(InEvent)
    return
  end
  local Animation = self.AnimationMap[InAnimationName]
  if not Animation then
    Log.Error("No such animation")
    return
  end
  if InEvent then
    self:RegisterAnimationToFsmEvent(InAnimationName, InEvent)
  end
  self:PlayAnimation(Animation)
end

function UMG_Update_UI_C:RegisterAnimationToFsmEvent(AnimationName, InEvent)
  self.AnimationEventMap[AnimationName] = InEvent
end

function UMG_Update_UI_C:OnAnimationFinished(Animation)
  local AnimationName = table.getKeyName(self.AnimationMap, Animation)
  self:SendAnimationEventAndUnregister(AnimationName)
end

function UMG_Update_UI_C:SendAnimationEventAndUnregister(InAnimationName)
  local Event = self.AnimationEventMap[InAnimationName]
  self.AnimationEventMap[InAnimationName] = nil
  if Event then
    _G.NRCEventCenter:DispatchEvent(Event)
  else
    Log.Debug("UMG_Login_New_C: SendAnimationEvent: Animation Has no event")
  end
end

function UMG_Update_UI_C:OnTick(deltaTime)
  if self.enableView then
    self:_internalSetProgress(self.TargetPercent / 100)
  end
end

function UMG_Update_UI_C:_internalSetProgress(Percent)
  if Percent == self.TargetPercent / 100 and self.WaitForPercent then
    self.WaitForPercent = false
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.ProgressHit)
  end
  self.LastPercent = Percent
  self.UMG_Login_Register.JinduProgressBar:SetPercent(Percent)
  self.UMG_Login_Register.Text_Schedule:SetText((self.ProgressHint or "") .. " " .. math.round(Percent * 100) .. "%")
end

function UMG_Update_UI_C:SetProgress(Percent, Hint)
  self.WaitForPercent = true
  self.ProgressHint = Hint
  self.TargetPercent = 100 * Percent
end

function UMG_Update_UI_C:SetSpeed(Speed)
end

function UMG_Update_UI_C:SetAvgSpeed(Speed)
end

function UMG_Update_UI_C:OnAnimationFinished(Animation)
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  local AnimationName = table.getKeyName(self.AnimationMap, Animation)
  self:SendAnimationEventAndUnregister(AnimationName)
end

function UMG_Update_UI_C:ShowNotificationButton()
  self.UMG_Login_Register:ShowNotificationBtn()
end

return UMG_Update_UI_C
