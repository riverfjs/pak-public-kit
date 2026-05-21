local UMG_ChangeName_C = _G.NRCPanelBase:Extend("UMG_ChangeName_C")
local UIUtilsTotal = require("NewRoco.Utils.UIUtils")

function UMG_ChangeName_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
  self.PopUp3:SetBtnLeftText(LuaText.umg_rename_3)
  self.PopUp3:SetBtnRightText(LuaText.umg_rename_4)
  self:OnAddEventListener()
  self.MaxiCount = DataConfigManager:GetHomeGlobalConfig("room_name_text_length").num or 12
end

function UMG_ChangeName_C:OnActive(RoomId, OnChanged)
  self:SetCommonPopUpInfo(self.PopUp3)
  self:PlayAnimation(self.appeat)
  self.RoomData = HomeIndoorSandbox.Server.WorldData:GetRoomData(RoomId)
  self.CurrentName = self.RoomData.RoomName
  self.UsernameDisplay:SetText(self.CurrentName)
  self.UsernameDisplay:SetHintText(self.CurrentName)
  self.NameHint:SetText(LuaText.illegal_name_tips)
  self.OnNameChanged = OnChanged
end

function UMG_ChangeName_C:OnDeactive()
end

function UMG_ChangeName_C:OnAddEventListener()
  self.UsernameDisplay.OnTextChanged:Add(self, self.OnTextChanged)
  self.UsernameDisplay.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
end

function UMG_ChangeName_C:OnTextChanged()
  local HoverText = self.UsernameDisplay:GetSelectedText()
  if HoverText and "" ~= HoverText then
    return
  end
  self:CommitText()
end

function UMG_ChangeName_C:CommitText()
  local Name = self.UsernameDisplay:GetText()
  local MaxContent, CurrentNum = string.GetSubStr(Name, self.MaxiCount)
  self.CurrentName = MaxContent
  self.UsernameDisplay:SetText(MaxContent)
  UIUtilsTotal.RemoveInvalidCharsHandle(self.UsernameDisplay)
  local bIsLegal = UIUtilsTotal.CheckNameIsLegal(self.UsernameDisplay:GetText())
  self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  UIUtilsTotal.SetBtnGary(self.PopUp3.Btn_Right, not bIsLegal, bIsLegal)
end

function UMG_ChangeName_C:OnTextEndTransaction()
  self:CommitText()
end

function UMG_ChangeName_C:OnBtnCancelClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_ChangeName_C:OnBtnOkClick")
  if self.bInRequesting then
    return
  end
  self.CurrentName = self.RoomData.RoomName
  self.UsernameDisplay:SetText(self.RoomData.RoomName)
end

function UMG_ChangeName_C:OnBtnOkClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_ChangeName_C:OnBtnOkClick")
  if self.bInRequesting then
    return
  end
  if not UIUtilsTotal.CheckNameIsLegal(self.CurrentName) then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
    Log.Debug("UMG_ChangeName_C:OnBtnOkClick input sensitive words CurrentName:", self.CurrentName)
    return
  end
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_RENAME_ROOM_REQ
  local Req = ProtoMessage:newZoneSceneHomeRenameRoomReq()
  Req.room_name = self.CurrentName
  Req.room_id = self.RoomData.RoomId
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    self.bInRequesting = nil
    if 0 ~= _protoData.ret_info.ret_code then
    else
      HomeIndoorSandbox:LogInfo("Change room name, from", self.RoomData.RoomName, "to", self.CurrentName, "room_id=", self.RoomData.RoomId)
      self.RoomData.RoomName = Req.room_name
      self.OnNameChanged()
      self:OnReqClose()
    end
  end
  
  self.bInRequesting = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
end

function UMG_ChangeName_C:OnbtnCloseRenamePanelClick()
  self:OnReqClose()
end

function UMG_ChangeName_C:OnReqClose()
  self:PlayAnimation(self.vanish)
end

function UMG_ChangeName_C:OnPcClose()
  self:OnReqClose()
end

function UMG_ChangeName_C:OnAnimationFinished(Anim)
  if self.vanish == Anim then
    self:DoClose()
  end
end

function UMG_ChangeName_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  else
    CommonPopUpData.TitleText = _G.DataConfigManager:GetLocalizationConf("room_name_change_title").msg
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCancelClick
  CommonPopUpData.Btn_RightHandler = self.OnBtnOkClick
  CommonPopUpData.ClosePanelHandler = self.OnbtnCloseRenamePanelClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

return UMG_ChangeName_C
