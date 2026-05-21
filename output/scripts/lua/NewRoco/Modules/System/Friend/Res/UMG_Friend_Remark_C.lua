local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Friend_Remark_C = _G.NRCPanelBase:Extend("UMG_Friend_Remark_C")

function UMG_Friend_Remark_C:OnConstruct()
  self.OldInput = nil
  self.NewInput = nil
  self:SetChildViews(self.PopUp3)
  self:OnAddEventListener()
end

function UMG_Friend_Remark_C:OnDestruct()
end

function UMG_Friend_Remark_C:OnActive(_data)
  self.data = _data
  self:SetCommonPopUpInfo(self.PopUp3)
  local HintText
  if self.data.name then
    _G.NRCAudioManager:PlaySound2DAuto(1082, "UMG_Plane_ExchangeVisits_C:OnActive")
    HintText = _G.DataConfigManager:GetLocalizationConf("friend_remake_affirm_initial_text").msg
    self.InputBox:SetHintText(HintText)
    if self.data.note and self.data.note ~= "" then
      self.InputBox:SetText(self.data.note)
    else
      self.InputBox:SetText(self.data.name)
    end
    self.Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.data.additional_data then
    local pos = self.VerticalBox_68.Slot:GetPosition()
    HintText = _G.DataConfigManager:GetLocalizationConf("card_name_empty_text").msg
    self.InputBox:SetHintText(HintText)
    self.InputBox:SetText(self.data.name)
    pos.y = -182
    self.VerticalBox_68.Slot:SetPosition(pos)
    local Name = _G.DataConfigManager:GetLocalizationConf("card_change_name").msg
    self.PopUp3:SetTitleTextInfo(Name)
    self.Hint:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.NameHint:SetText(LuaText.illegal_name_tips)
  self:LoadAnimation(0)
end

function UMG_Friend_Remark_C:OnDeactive()
end

function UMG_Friend_Remark_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClose
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Friend_Remark_C:OnAddEventListener()
  self.InputBox.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
end

function UMG_Friend_Remark_C:OnTextChanged()
  if self._isPinYin then
    return
  end
  local text = self.InputBox:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  self.NewInput = self.InputBox:GetText()
  self.NewInput = UIUtils.RemoveEmoji(self.NewInput)
  UIUtils.RemoveInvalidCharsHandle(self.InputBox)
  local MaxCount
  if self.data.note then
    MaxCount = _G.DataConfigManager:GetFriendGlobalConfig("friend_remake_name_num_max").num
  else
    MaxCount = _G.DataConfigManager:GetRoleGlobalConfig("max_name_char_num").num
  end
  local MaxContent, CurrentNum = string.GetSubStr(self.NewInput, MaxCount)
  if MaxContent ~= self.InputBox:GetText() then
    self.InputBox:SetText(MaxContent)
  end
  local bIsLegal = UIUtils.CheckNameIsLegal(self.InputBox:GetText())
  self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  UIUtils.SetBtnGary(self.PopUp3.Btn_Right, not bIsLegal, bIsLegal)
end

function UMG_Friend_Remark_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnTextChanged()
end

function UMG_Friend_Remark_C:OnClickConfirm()
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Plane_ExchangeVisits_C:OnActive")
  local InputInfo = self.InputBox:GetText()
  if InputInfo ~= self.data.note then
    if not UIUtils.CheckNameIsLegal(InputInfo) then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
      Log.Debug("UMG_Friend_Remark_C:OnClickConfirm InputInfo has special chars inputInfo:", InputInfo)
      return
    end
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.ModifyFriendRemark, self.data.uin, InputInfo)
  else
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.CloseFriendInfoFrame)
    self:OnClose()
  end
end

function UMG_Friend_Remark_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  elseif Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Friend_Remark_C:OnClose()
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Plane_ExchangeVisits_C:OnActive")
  self:LoadAnimation(2)
end

return UMG_Friend_Remark_C
