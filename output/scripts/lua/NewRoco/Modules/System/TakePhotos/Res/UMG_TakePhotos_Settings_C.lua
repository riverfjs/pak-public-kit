local UMG_TakePhotos_Settings_C = _G.NRCPanelBase:Extend("UMG_TakePhotos_Settings_C")

function UMG_TakePhotos_Settings_C:OnConstruct()
  self.TakePhotoSettings = self:GetSettings()
  self.PhotoManager = self:GetModule().Controller.PhotoManager
  self:AddButtonListener(self.SwitchButton.SwitchButton, function()
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "SwitchButton")
    self.TakePhotoSettings.PlayerLookCamera:Toggle()
    if self.TakePhotoSettings.PlayerLookCamera:IsEnabled() then
      local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      local bRideAll = LocalPlayer and LocalPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      if bRideAll then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.take_photo_allride_lookat)
      end
    end
  end)
  self:AddButtonListener(self.SwitchButton_1.SwitchButton, function()
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "SwitchButton")
    self.TakePhotoSettings.PetLookCamera:Toggle()
  end)
  self:AddButtonListener(self.DropDownList.SelectButton, function()
    _G.NRCAudioManager:PlaySound2DAuto(40007001, "SelectButton")
    self.DropDownList:Toggle()
  end)
  self:AddButtonListener(self.DropDownList_1.SelectButton, function()
    _G.NRCAudioManager:PlaySound2DAuto(40007001, "SelectButton")
    self.DropDownList_1:Toggle()
  end)
  self:AddButtonListener(self.dropOut.btnClose, self.OnReqClose)
  self.DropDownList:InitDataList(self.TakePhotoSettings:CreateCountDownGroupUIDataList())
  self.DropDownList_1:InitDataList(self.TakePhotoSettings:CreateBurstGroupUIDataList())
  self:OnUpdatePetLookCamera(self.TakePhotoSettings.PetLookCamera:IsEnabled())
  self:OnUpdatePlayerLookCamera(self.TakePhotoSettings.PlayerLookCamera:IsEnabled())
  self.TakePhotoSettings.PetLookCamera.OnValueChanged:Add(self, self.OnUpdatePetLookCameraChanged)
  self.TakePhotoSettings.PlayerLookCamera.OnValueChanged:Add(self, self.OnUpdatePlayerLookCameraChanged)
  self.TakePhotoSettings.CountDownGroup.OnOptionChanged:Add(self, self.OnCountDownOptionChanged)
  self.TakePhotoSettings.BurstGroup.OnOptionChanged:Add(self, self.OnBurstOptionChanged)
  self.TakePhotoSettings.CameraRollProgress.OnValueChanged:Add(self, self.OnCameraRollChanged)
  self.TakePhotoSettings.CameraRollProgress:BindProgressBar(self, self.ScheduleLeft, self.ScheduleRight, self.Slider_95)
  self:OnCameraRollChanged(self.TakePhotoSettings.CameraRollProgress:GetValue())
  _G.NRCEventCenter:RegisterEvent("UMG_TakePhotos_Settings_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalPreTouch)
  self.TakePhotoSettings.FocalRegionProgress:BindProgressBar(self, self.ScheduleLeft_1, self.Slider)
  self.TakePhotoSettings.FocalScaleProgress:BindProgressBar(self, self.ScheduleLeft_2, self.Slider_1)
  self:InitLocalization()
  self:AddButtonListener(self.SwitchButton_2.SwitchButton, function()
    self.TakePhotoSettings.ActionMirror:Toggle()
    if self.TakePhotoSettings.ActionMirror:IsEnabled() then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player and (player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) or player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.take_photo_holdhands_pose)
      end
    end
  end)
  self.TakePhotoSettings.ActionMirror.OnValueChanged:Add(self, self.OnActionMirrorChanged)
end

function UMG_TakePhotos_Settings_C:OnActionMirrorChanged(bEnable)
  self.SwitchButton_2.NRCSwitcher_28:SetActiveWidgetIndex(bEnable and 1 or 0)
end

function UMG_TakePhotos_Settings_C:OnDestruct()
  self.TakePhotoSettings.PetLookCamera.OnValueChanged:Remove(self, self.OnUpdateLookCamera)
  self.TakePhotoSettings.PlayerLookCamera.OnValueChanged:Remove(self, self.OnUpdatePlayerLookCamera)
  self.TakePhotoSettings.CountDownGroup.OnOptionChanged:Remove(self, self.OnCountDownOptionChanged)
  self.TakePhotoSettings.BurstGroup.OnOptionChanged:Remove(self, self.OnBurstOptionChanged)
  self.TakePhotoSettings.CameraRollProgress:UnBind()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnGlobalPreTouch)
  self.DropDownList:ConditionUnExpand()
  self.DropDownList_1:ConditionUnExpand()
end

function UMG_TakePhotos_Settings_C:OnActive(OnPanelClose)
  self.OnPanelClose = OnPanelClose
end

function UMG_TakePhotos_Settings_C:OnReqClose()
  if self.OnPanelClose then
    self.OnPanelClose()
  end
end

function UMG_TakePhotos_Settings_C:GetModule()
  return NRCModuleManager:GetModule("TakePhotosModule")
end

function UMG_TakePhotos_Settings_C:GetSettings()
  return self:GetModule().Controller.TakePhotoSettings
end

function UMG_TakePhotos_Settings_C:OnGlobalPreTouch()
  self.DropDownList:NotifyUnExpandCheck()
  self.DropDownList_1:NotifyUnExpandCheck()
end

function UMG_TakePhotos_Settings_C:OnUpdatePetLookCamera(bEnable)
  self.SwitchButton_1.NRCSwitcher_28:SetActiveWidgetIndex(bEnable and 1 or 0)
end

function UMG_TakePhotos_Settings_C:OnUpdatePetLookCameraChanged(bEnable)
  return self:OnUpdatePetLookCamera(bEnable)
end

function UMG_TakePhotos_Settings_C:OnUpdatePlayerLookCamera(bEnable)
  self.SwitchButton.NRCSwitcher_28:SetActiveWidgetIndex(bEnable and 1 or 0)
end

function UMG_TakePhotos_Settings_C:OnUpdatePlayerLookCameraChanged(bEnable)
  return self:OnUpdatePlayerLookCamera(bEnable)
end

function UMG_TakePhotos_Settings_C:OnCountDownOptionChanged()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Settings_C:OnCountDownOptionChanged")
  self.DropDownList:RefreshList()
  self.DropDownList:ConditionUnExpand()
end

function UMG_TakePhotos_Settings_C:OnBurstOptionChanged(New, Old)
  local Num = self.TakePhotoSettings:GetTakePhotoBurstNum()
  local Remaining = self.PhotoManager:GetRemainingLocalPhotoSlots()
  if Num > Remaining and self.TakePhotoSettings.BurstGroup:GetSelectedIndex() > 1 then
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.takephoto_burst_insufficient_tips_titile):SetContent(string.format(LuaText.takephoto_burst_insufficient_tips_text, Remaining)):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.OK, LuaText.CANCEL):SetCloseOnCancel(true):SetCallback(self, function(_, isOK)
      if isOK then
        self.DropDownList_1:RefreshList()
        self.DropDownList_1:ConditionUnExpand()
      else
        self.bDisableAudio = true
        self.TakePhotoSettings.BurstGroup:Toggle(1)
        self.bDisableAudio = false
      end
    end)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  else
    if not self.bDisableAudio then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TakePhotos_Settings_C:OnBurstOptionChanged")
    end
    self.DropDownList_1:RefreshList()
    self.DropDownList_1:ConditionUnExpand()
  end
end

function UMG_TakePhotos_Settings_C:OnCameraRollChanged(Value)
  if not self.TextAngle then
    return
  end
  self.TextAngle:SetText(string.format("%d\194\176", math.floor(Value)))
end

function UMG_TakePhotos_Settings_C:InitLocalization()
  if self.NRCText_1 then
    self.NRCText_1:SetText(LuaText.takephoto_countdown_text)
  end
  if self.NRCText_8 then
    self.NRCText_8:SetText(LuaText.takephoto_burst_text)
  end
  if self.NRCText_2 then
    self.NRCText_2:SetText(LuaText.takephoto_lookat_text)
  end
  if self.NRCText_3 then
    self.NRCText_3:SetText(LuaText.takephoto_pet_lookat_text)
  end
  if self.NRCText_4 then
    self.NRCText_4:SetText(LuaText.takephoto_camera_slant_text)
  end
  if self.NRCText_6 then
    self.NRCText_6:SetText(LuaText.takephoto_focal_distance)
  end
  if self.NRCText_7 then
    self.NRCText_7:SetText(LuaText.takephoto_blur)
  end
end

return UMG_TakePhotos_Settings_C
