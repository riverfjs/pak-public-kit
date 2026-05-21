local UMG_MarkingBox_C = _G.NRCPanelBase:Extend("UMG_MarkingBox_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")

function UMG_MarkingBox_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
end

function UMG_MarkingBox_C:OnActive(box_data)
  if box_data then
    self.CurEditorBoxId = box_data.id
    self.CurMarkType = box_data.mark_type
    self.CurBoxName = box_data.box_name
    self.CurLockState = box_data.lock
  end
  self.newLockState = self.CurLockState
  self.bOpenDetails = false
  self:OnAddEventListener()
  self:PlayAnimation(self:GetAnimByIndex(0))
  self:OnInitPanel()
end

function UMG_MarkingBox_C:OnDeactive()
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnSwitchPetBoxMark, self.OnSwitchPetBoxMark)
end

function UMG_MarkingBox_C:OnAddEventListener()
  NRCEventCenter:RegisterEvent("UMG_MarkWarehouse_C", self, PetUIModuleEvent.OnSwitchPetBoxMark, self.OnSwitchPetBoxMark)
  self:AddDelegateListener(self.InputBox.OnTextCommitted, self.OnTextCommitted)
  self:AddDelegateListener(self.InputBox.OnTextEndTransaction, self.OnTextEndTransaction)
  self:AddDelegateListener(self.InputBox.OnTextChanged, self.OnTextChanged)
  self:AddButtonListener(self.CheckButton, self.OnClickedCheckButton)
  self:AddButtonListener(self.SwitchBtn.btnLevelUp, self.OnClickedSwitchBtn)
  self:AddButtonListener(self.CloseTipsBtn, self.OnClickedCloseTipsBtn)
end

function UMG_MarkingBox_C:OnInitPanel()
  self:SetCommonPopUpInfo(self.PopUp3)
  self.CloseTipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText:SetText(LuaText.box_name_customize)
  self.NRCText_98:SetText(LuaText.box_mark_customize)
  self.maxNameLength = _G.DataConfigManager:GetPetGlobalConfig("box_name_length").num
  self.InputBox:SetText(self.CurBoxName)
  self.InputBox:SetHintText(LuaText.box_name_customize_default)
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local mark_unlock_info = playerInfo.backpack_info and playerInfo.backpack_info.mark_unlock_info or 0
  self.confs = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetAllWarehousCollectMarkConfigs)
  local markInfos = {}
  local index = -1
  local selectIndex
  for _, cfg in pairs(self.confs or {}) do
    local isUnlock = self:GetMarkFlag(mark_unlock_info, cfg.mark_type)
    if isUnlock or cfg.default_diplay_mark then
      local info = {
        conf = cfg,
        isUnlock = isUnlock,
        allConf = self.confs
      }
      table.insert(markInfos, info)
      index = index + 1
      if cfg.mark_type == self.CurMarkType then
        self.selectedUnlockMark = true
        selectIndex = index
      end
    end
  end
  self.FilterList:InitGridView(markInfos)
  if selectIndex and selectIndex >= 0 then
    self.FilterList:SelectItemByIndex(selectIndex)
  end
  self:OnTextChanged(self.CurBoxName)
  if self.CurLockState then
    self.CheckSwitcher:SetActiveWidgetIndex(1)
  else
    self.CheckSwitcher:SetActiveWidgetIndex(0)
  end
  self.DetailTips.Title:SetText(LuaText.box_lock_tips)
end

function UMG_MarkingBox_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCancelClick
  CommonPopUpData.Btn_RightHandler = self.OnBtnOkClick
  CommonPopUpData.ClosePanelHandler = self.OnPanelClose
  CommonPopUpData.Btn_RightGrayStatHandler = self.OnBtnOkClick
  CommonPopUpData.TitleText = LuaText.select_box_icon_titile
  CommonPopUpData.Btn_Right_GrayState_Text = LuaText.general_confirm
  CommonPopUpData.Btn_LeftText = LuaText.general_cancel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_MarkingBox_C:GetMarkFlag(mark_info, mark_type)
  return mark_info & mark_type == mark_type
end

function UMG_MarkingBox_C:OnBtnCancelClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_MarkWarehouse_C:OnBtnCancelClick")
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self:PlayAnimation(self:GetAnimByIndex(2))
end

function UMG_MarkingBox_C:OnPanelClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_MarkWarehouse_C:OnPanelClose")
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self:PlayAnimation(self:GetAnimByIndex(2))
end

function UMG_MarkingBox_C:OnBtnOkClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_MarkWarehouse_C:OnBtnOkClick")
  if self.CurEditorBoxId then
    local curSelectMarkType = _G.Enum.WarehouseMarkType.WMT_DEFAULT
    local isUnLock = false
    local item = self.FilterList:GetSelectedItem()
    if item then
      curSelectMarkType = item.mark_type
      isUnLock = item.data.isUnlock
    end
    if isUnLock and self.bLegalName and self.nameLen > 0 then
      local curName = self.InputBox:GetText()
      if self.CurMarkType ~= curSelectMarkType or curName ~= self.box_name or self.newLockState ~= self.CurLockState then
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxSetMarkTypeReq, self.CurEditorBoxId, curSelectMarkType, curName, self.newLockState)
      end
      self:OnBtnCancelClick()
    elseif 0 == self.nameLen then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.box_name_customize_nil)
    elseif not self.bLegalName then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.box_name_customize_illegal)
    elseif not isUnLock then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_mark_lock)
    end
  end
end

function UMG_MarkingBox_C:OnTextCommitted()
  self._isPinYin = false
  self:OnTextChanged(self.InputBox:GetText())
end

function UMG_MarkingBox_C:OnTextChanged(Text)
  if self._isPinYin then
    return
  end
  local text = self.InputBox:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  local len = self:GetNameLen(Text)
  if len > self.maxNameLength then
    local text1 = string.GetSubStr(Text, self.maxNameLength)
    self.InputBox:SetText(text1)
  end
  UIUtils.RemoveInvalidCharsHandle(self.InputBox)
  self.nameLen = self:GetNameLen(self.InputBox:GetText())
  self.bLegalName = UIUtils.CheckNameIsLegal(self.InputBox:GetText())
  self:UpdateRightBtnState()
end

function UMG_MarkingBox_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnTextChanged(self.InputBox:GetText())
end

function UMG_MarkingBox_C:GetNameLen(Name)
  local str = string.StringGetTotalNum(Name)
  if str > self.maxNameLength then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.box_name_customize_too_long)
  end
  return str
end

function UMG_MarkingBox_C:UpdateRightBtnState()
  if self.nameLen and self.nameLen > 0 and self.bLegalName and self.selectedUnlockMark then
    self.PopUp3:SetBtnRightEnableState(true)
  else
    self.PopUp3:SetBtnRightEnableState(false)
  end
end

function UMG_MarkingBox_C:OnSwitchPetBoxMark(mark_type, is_unlock)
  self.selectedUnlockMark = is_unlock
  self:UpdateRightBtnState()
  local Desc = self:GetMarkDesc(mark_type, is_unlock)
  if Desc then
    self.PopUp3:SetDescInfo(Desc)
  end
end

function UMG_MarkingBox_C:GetMarkDesc(mark_type, is_unlock)
  for _, conf in pairs(self.confs or {}) do
    if conf and conf.mark_type == mark_type then
      return conf.mark_desc_text
    end
  end
  return nil
end

function UMG_MarkingBox_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_MarkingBox_C:OnClickedCheckButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_MarkingBox_C:OnClickedCheckButton")
  if self.newLockState then
    self.newLockState = false
    self.CheckSwitcher:SetActiveWidgetIndex(0)
  else
    self.newLockState = true
    self.CheckSwitcher:SetActiveWidgetIndex(1)
  end
end

function UMG_MarkingBox_C:OnClickedSwitchBtn()
  if self.bOpenDetails then
    self:OnClickedCloseTipsBtn()
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_MarkingBox_C:OnClickedSwitchBtn")
    self.bOpenDetails = true
    self.DetailTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CloseTipsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_MarkingBox_C:OnClickedCloseTipsBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_MarkingBox_C:OnClickedSwitchBtn")
  self.bOpenDetails = false
  self.DetailTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CloseTipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_MarkingBox_C
