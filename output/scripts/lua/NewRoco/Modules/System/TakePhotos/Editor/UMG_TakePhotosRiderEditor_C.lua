require("NewRoco.Modules.System.TakePhotos.Editor.TakePhotoEditorTools")
local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")
local UMG_TakePhotosRiderEditor_C = _G.NRCPanelBase:Extend("UMG_TakePhotosRiderEditor_C")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local EnumModeType = {
  Handle1p = 1,
  Handle2p = 2,
  Selfie = 3,
  Selfie2P = 4
}

function UMG_TakePhotosRiderEditor_C:GetModule()
  return self.module
end

function UMG_TakePhotosRiderEditor_C:OnConstruct()
  self:AddButtonListener(self.dropOut.btnClose, self.DoClose)
  self:RegisterEvent(self, TakePhotosModuleEvent.OnToggleMode, self.OnModeChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_TakePhotosRiderEditor_C", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  self:BindEvents()
end

function UMG_TakePhotosRiderEditor_C:OnClosePanel(PanelData)
  local Name = PanelData.panelName
  if "TakePhotosMainUI" == Name then
    self:DoClose()
  end
end

function UMG_TakePhotosRiderEditor_C:OnActive()
  self:OnModeChanged()
end

function UMG_TakePhotosRiderEditor_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
end

function UMG_TakePhotosRiderEditor_C:OnAddEventListener()
end

function UMG_TakePhotosRiderEditor_C:Refresh()
  local M = self:GetModule()
  if M.ModeMgr:IsNoneMode() then
    self:SetVisibility(UE.ESlateVisibility.Hidden)
  else
    local Player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not (Player and Player.viewObj) or not UE.UObject.IsValid(Player.viewObj) then
      return
    end
    self.Player = Player
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local Name = ""
    if Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      Name = "\233\170\145\228\185\152\231\138\182\230\128\129"
      self.VerticalBox_Functions:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      Name = "\233\157\158\233\170\145\228\185\152\231\138\182\230\128\129"
      self.VerticalBox_Functions:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.NRCText_1:SetText(Name)
    if not M.ModeMgr:Is1PMode() and not M.ModeMgr:IsSelfieMode() then
      self.VerticalBox_Functions:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.VerticalBox_Functions:IsVisible() then
      if M.ModeMgr:Is1PMode() then
        Name = Name .. "|\230\137\139\230\140\129\231\155\184\230\156\186\230\168\161\229\188\143"
        self.VerticalBox_Functions:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      elseif M.ModeMgr:IsSelfieMode() then
        Name = Name .. "|\232\135\170\230\139\141\231\155\184\230\156\186\230\168\161\229\188\143"
        self.VerticalBox_Functions:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      elseif M.ModeMgr:IsTripodMode() then
        Name = Name .. "|\230\148\175\230\158\182\231\155\184\230\156\186\230\168\161\229\188\143"
      elseif M.ModeMgr:IsWorldMode() then
        Name = Name .. "|\230\148\175\230\158\182\228\184\150\231\149\140\230\168\161\229\188\143"
      end
      if M.ModeMgr:Is1PMode() then
        self:ShowHandledMode()
        if self.ModeType == EnumModeType.Handle1p then
          Name = Name .. "|1P"
        else
          Name = Name .. "|2P"
        end
      elseif M.ModeMgr:IsSelfieMode() then
        local b2PRider = M.ModeMgr.TakePhotosModeSelfie.SelfieCameraControl.AttachParams.b2PRider
        if b2PRider then
          Name = Name .. "|1P"
        else
          Name = Name .. "|2P"
        end
        self:ShowSelfieMode(b2PRider)
      else
        assert(false, "\229\188\130\229\184\184\230\131\133\229\134\181")
      end
      _G.TakePhotoEditorTools.Get():UpdateMode(self.ModeType)
      local ScenePet = self.Player:GetRidePetLua()
      TakePhotoEditorTools.Get():SetRideId(ScenePet.config.id)
      self.DisplayName = Name
      self:UpdateName()
      for i = 1, #self.AllSliders do
        self["HorizontalBox_" .. i - 1]:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
      self.Name2Keys = {
        eyes_view_point_offset_x = {
          "eyes_view_point_offset_x",
          "eyes_view_point_offset_2p_x"
        },
        eyes_view_point_offset_y = {
          "eyes_view_point_offset_y",
          "eyes_view_point_offset_2p_y"
        },
        eyes_view_point_offset_z = {
          "eyes_view_point_offset_z",
          "eyes_view_point_offset_2p_z"
        },
        view_offset_h = "view_offset_h",
        view_offset_v = "view_offset_v",
        cam_offset_h = "cam_offset_h",
        cam_offset_d = "cam_offset_d",
        cam_offset_l = "cam_offset_l",
        cam_min_l = "cam_min_l",
        cam_max_l = "cam_max_l",
        selfie2p_view_offset_x = "selfie2p_view_offset_x",
        selfie2p_view_pitch = "selfie2p_view_pitch",
        selfie2p_view_yaw = "selfie2p_view_yaw"
      }
      self.ProgressRanges = {}
      self.Index2Names = {}
      if M.ModeMgr:Is1PMode() then
        self:SetupProgressRange(1, "\232\167\134\232\167\146\229\129\143\231\167\187X", -200, 200, "eyes_view_point_offset_x")
        self:SetupProgressRange(2, "\232\167\134\232\167\146\229\129\143\231\167\187Y", -200, 200, "eyes_view_point_offset_y")
        self:SetupProgressRange(3, "\232\167\134\232\167\146\229\129\143\231\167\187Z", -200, 200, "eyes_view_point_offset_z")
      elseif M.ModeMgr:IsSelfieMode() then
        if M.ModeMgr.TakePhotosModeSelfie.SelfieCameraControl.AttachParams.b2PRider then
          self:SetupProgressRange(1, "\231\155\184\229\175\185\229\142\159\230\156\137\232\167\134\232\183\157", -500, 500, "selfie2p_view_offset_x")
          self:SetupProgressRange(2, "\233\148\129\229\174\154\228\187\176\228\191\175\232\167\134\232\167\146", -70, 70, "selfie2p_view_pitch")
          self:SetupProgressRange(3, "\233\148\129\229\174\154\230\176\180\229\185\179\232\167\134\232\167\146", -180, 180, "selfie2p_view_yaw")
        else
          self:SetupProgressRange(1, "\232\167\134\231\130\185\230\176\180\229\185\179\229\129\143\231\167\187", -200, 200, "view_offset_h")
          self:SetupProgressRange(2, "\232\167\134\231\130\185\233\171\152\229\186\166\229\129\143\231\167\187", -200, 200, "view_offset_v")
          self:SetupProgressRange(3, "\231\155\184\230\156\186\230\176\180\229\185\179\229\129\143\231\167\187", -200, 200, "cam_offset_h")
          self:SetupProgressRange(4, "\229\136\157\229\167\139\231\155\184\230\156\186\232\183\157\231\166\187\229\129\143\231\167\187", 0, 500, "cam_offset_d")
          self:SetupProgressRange(5, "\229\136\157\229\167\139\231\155\184\230\156\186\233\171\152\229\186\166\229\129\143\231\167\187", -200, 200, "cam_offset_l")
          self:SetupProgressRange(6, "\231\155\184\230\156\186\230\156\128\229\176\143\231\155\184\229\175\185\233\171\152\229\186\166", -100, 0, "cam_min_l")
          self:SetupProgressRange(7, "\231\155\184\230\156\186\230\156\128\229\164\167\231\155\184\229\175\185\233\171\152\229\186\166", 0, 200, "cam_max_l")
        end
      end
    end
  end
end

function UMG_TakePhotosRiderEditor_C:OnModeChanged()
  self:Refresh()
end

function UMG_TakePhotosRiderEditor_C:ShowHandledMode()
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local customParams = self.Player.statusComponent:GetCustomParams(statusId)
  if customParams and customParams.ride_param and (customParams.ride_param.double_ride_1p_id or 0) == self.Player.serverData.base.actor_id then
    self.ModeType = EnumModeType.Handle1p
  elseif customParams and customParams.ride_param and (customParams.ride_param.double_ride_2p_id or 0) == self.Player.serverData.base.actor_id then
    self.ModeType = EnumModeType.Handle2p
  else
    self.ModeType = EnumModeType.Handle1p
  end
end

function UMG_TakePhotosRiderEditor_C:ShowSelfieMode(b2PRider)
  if b2PRider then
    self.ModeType = EnumModeType.Selfie2P
  else
    self.ModeType = EnumModeType.Selfie
  end
end

function UMG_TakePhotosRiderEditor_C:UpdateName()
  local Name = self.DisplayName
  if _G.TakePhotoEditorTools.Get():IsDirty() then
    Name = Name .. "|\230\149\176\230\141\174\230\156\137\229\143\152\229\140\150\230\136\150\232\128\133\230\178\161\230\156\137\228\191\157\229\173\152\232\191\135"
  else
    Name = Name .. "|\230\149\176\230\141\174\230\151\160\229\143\152\229\140\150"
  end
  self.NRCText_1:SetText(Name)
end

function UMG_TakePhotosRiderEditor_C:BindEvents()
  self.AllSliders = {
    self.Slider,
    self.Slider_1,
    self.Slider_2,
    self.Slider_4,
    self.Slider_5,
    self.Slider_6,
    self.Slider_7,
    self.Slider_8,
    self.Slider_9,
    self.Slider_10
  }
  self.AllProgress = {
    self.ScheduleRight_1,
    self.ScheduleRight,
    self.ScheduleRight_2,
    self.ScheduleRight_3,
    self.ScheduleRight_5,
    self.ScheduleRight_6,
    self.ScheduleRight_7,
    self.ScheduleRight_8,
    self.ScheduleRight_9,
    self.ScheduleRight_10
  }
  self.TextFields = {
    self.NRCText_2,
    self.NRCText,
    self.NRCText_3,
    self.NRCText_4,
    self.NRCText_6,
    self.NRCText_7,
    self.NRCText_8,
    self.NRCText_9,
    self.NRCText_10,
    self.NRCText_12
  }
  self.ValueFields = {
    self.EditableText_196,
    self.EditableText,
    self.EditableText_1,
    self.EditableText_2,
    self.EditableText_3,
    self.EditableText_4,
    self.EditableText_5,
    self.EditableText_6,
    self.EditableText_7,
    self.EditableText_8
  }
  for i, Slider in ipairs(self.AllSliders) do
    Slider.OnValueChanged:Add(self, function()
      self:OnSliderValueChanged(i, Slider:GetValue())
    end)
  end
  for i, Input in ipairs(self.ValueFields) do
    Input.OnTextCommitted:Add(self, function()
      local Value = math.tointeger(Input:GetText())
      if Value then
        self:OnInputValueCommited(i, Value)
      else
        Input:SetText(0)
      end
    end)
  end
  self:AddButtonListener(self.Button_reset, self.Reset)
  self:AddButtonListener(self.Button_export, self.Export)
end

function UMG_TakePhotosRiderEditor_C:SetupProgressRange(Index, Name, Min, Max, LogicalName)
  self.ProgressRanges[Index] = {
    Max - Min,
    Min,
    Max,
    Name
  }
  self.AllSliders[Index]:SetMinValue(Min)
  self.AllSliders[Index]:SetMaxValue(Max)
  self.Index2Names[Index] = LogicalName
  self["HorizontalBox_" .. Index - 1]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.TextFields[Index]:SetText(Name)
  local Keys = self.Name2Keys[LogicalName]
  local Value = 0
  if type(Keys) == "string" then
    Value = TakePhotoEditorTools.Get():GetSelfieData(Keys)
  elseif type(Keys) == "table" then
    if self.ModeType == EnumModeType.Handle1p then
      Value = TakePhotoEditorTools.Get():GetHandledData(Keys[1])
    elseif self.ModeType == EnumModeType.Handle2p then
      Value = TakePhotoEditorTools.Get():GetHandled2pData(Keys[2])
    end
  end
  self.AllSliders[Index]:SetValue(Value)
  self:OnSliderValueChanged(Index, Value)
end

function UMG_TakePhotosRiderEditor_C:OnSliderValueChanged(Index, Value)
  if self.ProgressRanges[Index] then
    local Values = self.ProgressRanges[Index]
    local Progress = self.AllProgress[Index]
    Progress:SetPercent((Value - Values[2]) / Values[1])
    local Keys = self.Name2Keys[self.Index2Names[Index]]
    Value = math.floor(Value)
    if type(Keys) == "string" then
      TakePhotoEditorTools.Get():SetSelfieData(Keys, Value)
    elseif type(Keys) == "table" then
      if self.ModeType == EnumModeType.Handle1p then
        TakePhotoEditorTools.Get():SetHandledData(Keys[1], Value)
      elseif self.ModeType == EnumModeType.Handle2p then
        TakePhotoEditorTools.Get():SetHandled2pData(Keys[2], Value)
      end
    end
    self:UpdateName()
    self.ValueFields[Index]:SetText(Value)
    self:GetModule():DispatchEvent(TakePhotosModuleEvent.OnRideEditConfigValueChanged)
  end
end

function UMG_TakePhotosRiderEditor_C:OnInputValueCommited(Index, Value)
  if self.ProgressRanges[Index] then
    local Values = self.ProgressRanges[Index]
    if Value < Values[2] then
      Value = Values[2]
    elseif Value > Values[3] then
      Value = Values[3]
    end
    self.AllSliders[Index]:SetValue(Value)
    self:OnSliderValueChanged(Index, Value)
  end
end

function UMG_TakePhotosRiderEditor_C:Export()
  TakePhotoEditorTools.Get():ExportAll()
  self:OnModeChanged()
end

function UMG_TakePhotosRiderEditor_C:Reset()
  TakePhotoEditorTools.Get():ResetAll()
  self:OnModeChanged()
  self:GetModule():DispatchEvent(TakePhotosModuleEvent.OnRideEditConfigValueChanged)
end

return UMG_TakePhotosRiderEditor_C
