local TaskModuleCmd = require("NewRoco.Modules.Core.Task.TaskModuleCmd")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local UMG_ImageFlowPanel_C = _G.NRCPanelBase:Extend("UMG_ImageFlowPanel_C")
local FlowStyle = {TSCAT_SLIDE = 1, ACT_SLIDE = 2}

function UMG_ImageFlowPanel_C:OnConstruct()
  self.BtnClose.btnClose.OnClicked:Add(self, self.OnBtnCloseClicked)
  self.Playing.ButtonAAA.OnClicked:Add(self, self.OnPlayingClicked)
  self.BtnNext.OnClicked:Add(self, self.OnBtnNextClicked)
  self.bIsSuccess = false
  self.bIsEffect = false
end

function UMG_ImageFlowPanel_C:OnDestruct()
  self.BtnClose.btnClose.OnClicked:Remove(self, self.OnBtnCloseClicked)
  self.Playing.ButtonAAA.OnClicked:Remove(self, self.OnPlayingClicked)
  self.BtnNext.OnClicked:Remove(self, self.OnBtnNextClicked)
end

function UMG_ImageFlowPanel_C:OnActive(InParam)
  self.ImageFlowID = InParam.ImageFlowID
  self.Caller = InParam.Caller
  self.Callback = InParam.Callback
  self.Conf = _G.DataConfigManager:GetSlideConf(InParam.ImageFlowID, true)
  self.Style = InParam.Style
  self.SwitchType = Enum.SlidePictureSwitchType.SPST_NONE
  self.CurStoryBgm = "Task_Music;None"
  self.CurSound = -1
  if not self.Conf then
    self:SendCloseEvent(false)
  end
  self.bIsInit = true
  self:StopAllAnimations()
  self:PlayAnimation(self.UI_In)
  _G.NRCModeManager:DoCmd(TaskModuleCmd.UpdateImageFlowState, true)
  self:UpdateData()
  self:BindInputAction()
end

function UMG_ImageFlowPanel_C:OnDeactive()
  self:UnBindInputAction()
  _G.NRCModeManager:DoCmd(TaskModuleCmd.UpdateImageFlowState, false)
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnImageFlowEnd)
  self.CurStoryBgm = "Task_Music;None"
  _G.NRCAudioManager:BatchSetState(self.CurStoryBgm)
  self:StopSound()
  self:ClearTimerHandle()
end

function UMG_ImageFlowPanel_C:OnBtnCloseClicked()
  self:SendCloseEvent(true)
end

function UMG_ImageFlowPanel_C:OnPlayingClicked()
end

function UMG_ImageFlowPanel_C:SendFinishEvent(bIsSuccess)
  self:FireCallback(bIsSuccess)
end

function UMG_ImageFlowPanel_C:FireCallback(...)
  if self.Callback then
    if self.Caller then
      self.Callback(self.Caller, ...)
    else
      self.Callback(...)
    end
  end
end

function UMG_ImageFlowPanel_C:OnBtnNextClicked()
  self.bIsInit = false
  self:StopSound()
  if not self.Conf then
    Log.Debug("UMG_ImageFlowPanel_C:OnBtnNextClicked Conf not found", self.ImageFlowID)
    return
  end
  if not self.ImageFlowID then
    Log.Debug("UMG_ImageFlowPanel_C:OnBtnNextClicked ImageFlowID not found", self.ImageFlowID)
    return
  end
  if self.bIsEffect then
    if self.SwitchType == Enum.SlidePictureSwitchType.SPST_BLACK then
      self:OnBtnNextClickedBlack()
    elseif self.SwitchType == Enum.SlidePictureSwitchType.SPST_FADE then
      self:OnBtnNextClickedFade()
    end
    self.bIsEffect = false
    return
  end
  local NextImageFlowID = tonumber(self.Conf.next_picture)
  self.Conf = _G.DataConfigManager:GetSlideConf(NextImageFlowID, true)
  if not self.Conf then
    Log.Debug("UMG_ImageFlowPanel_C:OnBtnNextClicked NextImageFlowID not found", self.ImageFlowID)
    if self.Style == FlowStyle.TSCAT_SLIDE then
      self:SendCloseEvent(true)
    elseif self.Style == FlowStyle.ACT_SLIDE then
      self:SendCloseEvent(true)
    end
    return
  end
  self.ImageFlowID = NextImageFlowID
  self:UpdateData()
end

function UMG_ImageFlowPanel_C:UpdateData()
  if not self.ImageFlowID then
    return
  end
  Log.Debug("UMG_ImageFlowPanel_C:UpdateData", self.ImageFlowID)
  self:ClearTimerHandle()
  self.SwitchType = self.Conf.picture_switch_type or Enum.SlidePictureSwitchType.SPST_NONE
  if self.SwitchType ~= Enum.SlidePictureSwitchType.SPST_NONE then
    self.bIsEffect = true
  end
  if self.bIsInit then
    if self.SwitchType == Enum.SlidePictureSwitchType.SPST_BLACK then
      self:PlayAnimation(self.cut_out)
    elseif self.SwitchType == Enum.SlidePictureSwitchType.SPST_FADE then
      self:PlayAnimation(self.Img_In)
    end
  end
  self.ImgShow:SetPath(self.Conf.picture)
  self.FlowText:SetText(self.Conf.text)
  if self.Conf.mask_effect_type == Enum.SlideMaskEffectType.SMET_SNOW then
    self.MaskPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.noise, 0, 0, 1, 1, false)
  else
    self:StopAnimation(self.noise)
    self.MaskPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local BgmConf = _G.DataConfigManager:GetStoryBgmConf(tonumber(self.Conf.background_music), true)
  if BgmConf and not string.IsNilOrEmpty(BgmConf.story_bgm_state) then
    self.CurStoryBgm = string.format("Task_Music;Task_Music;%s", BgmConf.story_bgm_state)
    _G.NRCAudioManager:BatchSetState(self.CurStoryBgm)
  end
  if not string.IsNilOrEmpty(self.Conf.dialogue_sound) then
    self:StopSound()
    self.CurSound = _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.Conf.dialogue_sound)
  else
    self:StopSound()
  end
  if self.Conf.auto_play_time > 0 then
    self.NextHandler = _G.DelayManager:DelaySeconds(self.Conf.auto_play_time, self.OnBtnNextClicked, self)
  end
end

function UMG_ImageFlowPanel_C:BindInputAction()
  local MappingContext = self:AddInputMappingContext("IMC_ImageFlow")
  if MappingContext then
    MappingContext:BindAction("IA_CloseImageFlow", self, "OnPcClose")
    MappingContext:BindAction("IA_NextImage", self, "OnPcNext")
  end
end

function UMG_ImageFlowPanel_C:UnBindInputAction()
  local MappingContext = self:GetInputMappingContext("IMC_ImageFlow")
  if MappingContext then
    MappingContext:UnBindAction("IA_CloseImageFlow")
    MappingContext:UnBindAction("IA_NextImage")
  end
  local Imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_ImageFlow")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, Imc)
end

function UMG_ImageFlowPanel_C:SendCloseEvent(bIsSuccess)
  self.bIsSuccess = bIsSuccess
  self:StopAllAnimations()
  self:PlayAnimation(self.UI_Out)
end

function UMG_ImageFlowPanel_C:OnPcClose()
  Log.Debug("UMG_ImageFlowPanel_C:OnPcClose")
  self:SendCloseEvent(true)
end

function UMG_ImageFlowPanel_C:OnPcNext()
  Log.Debug("UMG_ImageFlowPanel_C:OnPcNext")
  if self.BtnNext:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:OnBtnNextClicked()
  end
end

function UMG_ImageFlowPanel_C:ClearTimerHandle()
  if self.NextHandler then
    _G.DelayManager:CancelDelayById(self.NextHandler)
    self.NextHandler = nil
  end
end

function UMG_ImageFlowPanel_C:OnAnimationFinished(Anim)
  if Anim == self.UI_Out then
    self:StopAllAnimations()
    self:SendFinishEvent(self.bIsSuccess)
    self:DoClose()
  elseif Anim == self.cut_in then
    self:PlayAnimation(self.cut_Out)
    self.BtnNext:SetVisibility(UE4.ESlateVisibility.Visible)
    self:OnBtnNextClicked()
  elseif Anim == self.cut_out then
    self.bIsInit = false
  elseif Anim == self.Img_In then
    self.bIsInit = false
  elseif Anim == self.Img_Out then
    self:PlayAnimation(self.Img_In)
    self.BtnNext:SetVisibility(UE4.ESlateVisibility.Visible)
    self:OnBtnNextClicked()
  end
end

function UMG_ImageFlowPanel_C:OnBtnNextClickedBlack()
  self.BtnNext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.cut_in)
end

function UMG_ImageFlowPanel_C:OnBtnNextClickedFade()
  self.BtnNext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Img_Out)
end

function UMG_ImageFlowPanel_C:StopSound()
  if self.CurSound and -1 ~= self.CurSound then
    _G.NRCAudioManager:ReleaseSession(self.CurSound, true, "UMG_ImageFlowPanel_C")
    self.CurSound = -1
  end
end

return UMG_ImageFlowPanel_C
