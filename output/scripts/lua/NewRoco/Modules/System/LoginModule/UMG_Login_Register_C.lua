local UMG_Login_Register_C = _G.NRCPanelBase:Extend("UMG_Login_Register_C")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")

function UMG_Login_Register_C:OnConstruct()
end

function UMG_Login_Register_C:OnActive(PanelType)
  Log.Debug("UMG_Login_Register_C:OnActive")
  self.PanelType = PanelType
  if self.Text_Describe then
    self.Text_Describe:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.EnableNotificationPanel then
    self.EnableNotificationPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.CancelDownloadPanel then
    self.CancelDownloadPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RegisterUpdateRepairBtnClickEvent()
  self:RegisterNotificationBtnClickEvent()
  self:SetUpBtnIndex()
end

function UMG_Login_Register_C:OnDeactive()
end

function UMG_Login_Register_C:OnAddEventListener()
end

function UMG_Login_Register_C:SetUpBtnIndex()
  Log.Debug("UMG_Login_Register_C:SetUpBtnIndex")
  if self.PanelType == LoginEnum.PanelType.Update then
    self.Btn_Repair_Update:OnActive(2)
    self.EnableNotification:OnActive(4)
  else
    self.Btn_Announcement:OnActive(1)
    self.Btn_Repair:OnActive(2)
    self.Btn_Repair_Update:OnActive(2)
    self.Btn_Repair_1:OnActive(2)
    self.Btn_WriteOff:OnActive(3)
    self.EnableNotification:OnActive(4)
    self.Btn_DropOut:OnActive(5)
    if self and self.Btn_AutoGame and self.Btn_AutoGame.btnLevelUp then
      self.Btn_AutoGame:OnActive(6)
    end
    self.Btn_Suspend:OnActive(7)
    self.Btn_Suspend_1:OnActive(7)
    self.Btn_ScanLogin:OnActive(8)
    self.Btn_CustomerService:OnActive(9)
    self.Btn_CustomerService_1:OnActive(9)
    self.DownloadBtn:OnActive(10)
  end
end

function UMG_Login_Register_C:ShowUpdateRepairBtn()
  if self.Btn_Repair_Update then
    self.Btn_Repair_Update:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Login_Register_C:HideUpdateRepairBtn()
  if self.Btn_Repair_Update then
    self.Btn_Repair_Update:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Login_Register_C:RegisterUpdateRepairBtnClickEvent()
  if self.Btn_Repair_Update then
    self:AddButtonListener(self.Btn_Repair_Update.btnLevelUp, self.OnClickRepair)
  end
end

function UMG_Login_Register_C:OnClickRepair()
  self:DelaySeconds(0.1, function()
    _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Update_UI_C:OnClickRepair")
    _G.NRCModuleManager:DoCmd(UpdateUIModuleCmd.OpenRepairToolsPanel)
    self.Btn_Repair_Update:CancelSelect()
  end)
end

function UMG_Login_Register_C:ShowNotificationBtn()
  if self.EnableNotificationPanel then
    self.EnableNotificationPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Login_Register_C:HideNotificationBtn()
  if self.EnableNotificationPanel then
    self.EnableNotificationPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Login_Register_C:RegisterNotificationBtnClickEvent()
  if self.EnableNotification then
    self:AddButtonListener(self.EnableNotification.btnLevelUp, self.OnClickNotificationBtn)
  end
end

function UMG_Login_Register_C:OnClickNotificationBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Login_Register_C:OnClickNotificationBtn")
  self:DelaySeconds(0.3, function()
    UE.UNRCPermissionMgr.JumpToSysSetting()
    self.EnableNotification:CancelSelect()
  end)
end

function UMG_Login_Register_C:EnableDownloadBtnRedDot()
  if self.DownloadBtn then
    self.DownloadBtn:SetRedPointUIType(Enum.RedPointType.RPT_COMMON, true)
  end
end

function UMG_Login_Register_C:DisableDownloadBtnRedDot()
  if self.DownloadBtn then
    self.DownloadBtn:SetRedPointUIType(Enum.RedPointType.RPT_COMMON, false)
  end
end

return UMG_Login_Register_C
