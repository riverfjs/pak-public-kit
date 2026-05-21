local UIUtils = require("NewRoco.Utils.UIUtils")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local JsonUtils = require("Common.JsonUtils")
local UMG_CharacterPick_C = _G.NRCPanelBase:Extend("UMG_CharacterPick_C")

function UMG_CharacterPick_C:Ctor()
  self.isInit = false
  self.USE_NEW = true
  self.ClickIntervalLength = 0.2
  self.CanReturnToSelection = false
  self.deltaRot = UE4.FRotator(0, 0, 0)
  self.bStartRot = false
  self.OnPcCloseHandler = self.OnPCEscPressed
end

function UMG_CharacterPick_C:OnConstruct()
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.CharacterSelected, self.OnCharacterSelected)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.EnterName, self.StartEnterName)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.SetCharacterToMale, self.SetCharacterToMale)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.SetCharacterToFemale, self.SetCharacterToFemale)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.ShowConfirmPanel, self.ShowConfirmPanel)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.HideConfirmPanels, self.HideConfirmPanels)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.CantClickConfirmPanels, self.CantClickConfirmPanels)
  NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.AutoTestEnterText, self.AutoTestEnterText)
  _G.NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, _G.NRCGlobalEvent.OnVirtualKeyboardShowOrHide, self.OnVirtualKeyboardShowOrHide)
  self.allowClick = true
end

function UMG_CharacterPick_C:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.CharacterSelected, self.OnCharacterSelected)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.EnterName, self.StartEnterName)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.ShowConfirmPanel, self.ShowConfirmPanel)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.HideConfirmPanels, self.HideConfirmPanels)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.SetCharacterToMale, self.SetCharacterToMale)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.SetCharacterToFemale, self.SetCharacterToFemale)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.AutoTestEnterText, self.AutoTestEnterText)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SYNC_NOTIFY, self.OnIconInfoUpdate)
  _G.NRCEventCenter:RegisterEvent(self, _G.NRCGlobalEvent.OnVirtualKeyboardShowOrHide, self.OnVirtualKeyboardShowOrHide)
end

function UMG_CharacterPick_C:OnActive()
  UE4Helper.SetDesiredShowCursor(true, "UMG_CharacterPick_C")
  self.data = NRCModuleManager:GetModule("LoginModule"):GetData("LoginData")
  self.ButtonBackPick:SetIsEnabled(true)
  self:InitView()
  if not self.isInit then
    self.isInit = true
    self:AddButtonListener(self.ButtonBackPick.btnClose, self.BackToMain)
    self:AddButtonListener(self.ButtonConfirm.btnLevelUp, self.OnClickPickConfirm)
    self:AddButtonListener(self.ButtonBackName.btnClose, self.BackToConfirm)
    self:AddButtonListener(self.Btn_NameConfirm.btnLevelUp, self.OnClickNameConfirm)
    self:AddButtonListener(self.ButtonBackFinish.btnClose, self.BackToName)
    self:AddButtonListener(self.Btn_BackFinish.btnLevelUp, self.BackToName)
    self:AddButtonListener(self.TriggerInput, self.StartEditName)
    self:AddButtonListener(self.ButtonBackConfirm.btnClose, self.NotifyBackToSelection)
    self:AddButtonListener(self.SexBtn_Male.SelectButton, self.OnMaleBtnClick)
    self:AddButtonListener(self.SexBtn_Female.SelectButton, self.OnFemaleBtnClick)
    self:AddButtonListener(self.Btn_Confirm.btnLevelUp, self.OnBtnConfirmClicked)
    self:AddDelegateListener(self.InputTextName.OnTextChanged, self.OnTextChanged)
    self:AddDelegateListener(self.InputTextName.OnTextCommitted, self.OnTextCommitted)
    self.SexBtn_Male.Icon_M:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SexBtn_Male.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bSelecting = true
end

function UMG_CharacterPick_C:StartEnterName()
  self.NameCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.NameIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.EnterName, self.StartEnterName)
end

function UMG_CharacterPick_C:DisableSpin()
  self.bSelecting = false
end

function UMG_CharacterPick_C:NotifyBackToSelection()
  if self.CanReturnToSelection then
    self.ConfirmCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
    NRCEventCenter:DispatchEvent(LoginModuleEvent.EndPostSelectionIdle, LoginModuleEvent.BackToSelection)
    self.CanReturnToSelection = false
  end
end

function UMG_CharacterPick_C:OnDeactive()
  UE4Helper.ReleaseDesiredShowCursor("UMG_CharacterPick_C")
end

function UMG_CharacterPick_C:InitView()
  self.LeftPick:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.PickCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
  local initName
  if _G.RocoEnv.IS_EDITOR then
    _G.NRCModuleManager:GetModule("LoginModule"):GetData("LoginData"):BuildOpenID()
    initName = _G.NRCModuleManager:GetModule("LoginModule"):GetData("LoginData"):GetOpenID()
  else
    local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if playerInfoData.loginChannel then
      local userName = LoginUtils.GetPersistedUserName()
      Log.Info("UMG_CharacterPick_C:InitView ", userName or "userName nil")
      initName = userName or ""
    else
      initName = ""
    end
  end
  self:SetPlayerName(initName or "", true)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ConfirmCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.NameCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.FinishCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:StartBlur(false)
  self.Trans:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.isInFemale = false
  self.isInMale = false
  local nameLimitText = DataConfigManager:GetGlobalConfigByKeyType("ftue_entername", DataConfigManager.ConfigTableId.ROLE_GLOBAL_CONFIG).str
  self.NameExplain:SetText(nameLimitText)
  self.NameHint:SetText(LuaText.illegal_name_tips)
  self:ResetView()
end

function UMG_CharacterPick_C:ResetView()
  self.PickCanvas:SetRenderOpacity(1)
  self.ConfirmCanvas:SetRenderOpacity(1)
  self.NameCanvas:SetRenderOpacity(1)
  self.FinishCanvas:SetRenderOpacity(1)
  self.ButtonConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ButtonBackName:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_NameConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ButtonBackFinish:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_NameConfirm:SetIsEnabled(true)
end

function UMG_CharacterPick_C:OnCharacterSelected(inEvent)
  if inEvent == LoginModuleEvent.BackToMain then
    return
  end
  self.PickCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_CharacterPick_C:ShowConfirmPanel()
  self:DelaySeconds(0.3, function()
    self.allowClick = true
    if self.ConfirmCanvas:GetVisibility() ~= UE4.ESlateVisibility.Visible then
      self.ConfirmCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ButtonConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.ConfirmIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    end
  end)
end

function UMG_CharacterPick_C:HideConfirmPanels()
  Log.Error("HideConfirmPanels")
  self.ConfirmCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_CharacterPick_C:CantClickConfirmPanels()
  self.allowClick = false
end

function UMG_CharacterPick_C:SwitchCharacter()
  local controller = UE4.UGameplayStatics.GetPlayerController(self, 0)
  local TargetStateEvent = LoginModuleEvent.FemaleCharacterSelected
  if not controller.bMaleSelected then
    controller.bMaleSelected = true
    TargetStateEvent = LoginModuleEvent.MaleCharacterSelected
  else
    controller.bMaleSelected = false
  end
  NRCEventCenter:DispatchEvent(LoginModuleEvent.EndPostSelectionIdle, TargetStateEvent)
end

function UMG_CharacterPick_C:BackToMain()
  self.ButtonBackPick:SetIsEnabled(false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1092, "UMG_CharacterPick_C:BackToMain")
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.CharacterSelected)
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.OnDisconnected)
end

function UMG_CharacterPick_C:OnClickPickConfirm()
  if not self.allowClick then
    return
  end
  NRCProfilerLog:NRCClickBtn(true, "BeautyLoginMain")
  self.ButtonConfirm:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.ConfirmOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1091, "UMG_CharacterPick_C:OnClickPickConfirm")
  self:DelaySeconds(0.5, function()
    self.ConfirmCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  end)
  if not self.USE_NEW then
    self:PlayChooseConfirmSeq()
  else
    NRCEventCenter:DispatchEvent(LoginModuleEvent.EndPostSelectionIdle, LoginModuleEvent.EnterDesign)
    _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.OpenBeautyLoginPanel, true, true)
    self.ButtonBackName:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CharacterPick_C:BackToConfirm()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1092, "UMG_CharacterPick_C:BackToConfirm")
  self.ButtonBackName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.NameOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self:DelaySeconds(0.3, function()
    self.NameCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.FinishCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.ButtonConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
  end)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.EndConfirmState, LoginModuleEvent.ConfirmToDesignState)
  _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.OpenBeautyLoginPanel, false)
end

function UMG_CharacterPick_C:SetCharacterToFemale()
  Log.Debug("UMG_CharacterPick_C:SetCharacterToFemale")
  self.GenderEvent = LoginModuleEvent.FemaleCharacterSelected
  if not self.bIsPlaying then
    self.CanReturnToSelection = true
    self.isMale = false
    self.data:SetRegisterGender(ProtoEnum.ESexValue.SEX_FEMALE)
  else
    return
  end
end

function UMG_CharacterPick_C:SetCharacterToMale()
  Log.Debug("UMG_CharacterPick_C:SetCharacterToMale")
  self.GenderEvent = LoginModuleEvent.MaleCharacterSelected
  if not self.bIsPlaying then
    self.CanReturnToSelection = true
    self.isMale = true
    self.data:SetRegisterGender(ProtoEnum.ESexValue.SEX_MALE)
  else
    return
  end
end

function UMG_CharacterPick_C:OnClickNameConfirm()
  Log.Debug("UMG_CharacterPick_C:OnClickNameConfirm")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1091, "UMG_CharacterPick_C:OnClickPickConfirm")
  self.Btn_NameConfirm:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if string.SubStringGetTotalIndex(self:GetPlayerName()) > 12 then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_1, 0)
    self:BackToName()
  else
    local roleAttrReq = ProtoMessage:newZoneRoleAttrReq()
    local curChooseGender = self.data:GetRegisterGender() or ProtoEnum.ESexValue.SEX_MALE
    roleAttrReq.sex = curChooseGender
    roleAttrReq.name = self:GetPlayerName()
    local salonData = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetTempBeautyDataByGender, curChooseGender)
    local avatarSalonIdToSalonIdsMap = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetAvatarSalonIdToSalonIds)
    if salonData and #salonData > 0 then
      for k, v in ipairs(salonData) do
        if avatarSalonIdToSalonIdsMap[v.SalonId] and avatarSalonIdToSalonIdsMap[v.SalonId][v.SalonColorIndex + 1] then
          table.insert(roleAttrReq.salon_item_wear_data, {
            item_wear_id = avatarSalonIdToSalonIdsMap[v.SalonId][v.SalonColorIndex + 1],
            color_wear_id = v.SalonColorIndex + 1
          })
        end
      end
    end
    self:SaveVideoData(curChooseGender, roleAttrReq.salon_item_wear_data)
    roleAttrReq.fashion_suit_id = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialSelectedSuitId, _G.NRCModuleManager:DoCmd(LoginModuleCmd.GetCurRegisterGender))
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ROLE_ATTR_REQ, roleAttrReq, self, self.CheckRoleValid, true, true)
  end
end

function UMG_CharacterPick_C:SaveVideoData(sex, item_wear_data)
  local VideoData = {}
  sex = sex or 1
  local skin = 1
  if self:IsBlackMan(item_wear_data) then
    skin = 2
  end
  table.insert(VideoData, sex)
  table.insert(VideoData, skin)
  JsonUtils.DumpSaved("VideoData", VideoData)
end

function UMG_CharacterPick_C:IsBlackMan(item_wear_data)
  if item_wear_data then
    for _, wearData in pairs(item_wear_data) do
      if wearData.item_wear_id == 156 then
        return true
      end
    end
  end
  return false
end

function UMG_CharacterPick_C:OnEndLogin()
  Log.Debug("end login")
  self:EnterGame()
end

function UMG_CharacterPick_C:CheckRoleValid(rsp)
  Log.Debug("UMG_CharacterPick_C:CheckRoleValid")
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.SUCCESS then
    _G.NRCAudioManager:SetStateByName("Login_Game", "Start_Game", "UMG_Login_New")
    NRCEventCenter:RegisterEvent("UMG_CharacterPick_C", self, LoginModuleEvent.EndLogin, self.OnEndLogin)
    self.FinishCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
    if rsp.appearance_info then
      _G.DataModelMgr.PlayerDataModel:SetPlayerAppearanceInfo(rsp.appearance_info)
    end
    UE4Helper.ReleaseDesiredShowCursor("UMG_CharacterPick_C")
    NRCEventCenter:DispatchEvent(LoginModuleEvent.EndConfirmState, LoginModuleEvent.PlayEndSequence)
    _G.GEMPostManager:GEMPostStepEvent("ClickNameButton")
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_DUPLICATE then
    self:BackToName()
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_2, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_INVALID_NAME_LEN then
    self:BackToName()
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_1, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    self:BackToName()
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_3, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_EMPTY then
    self:BackToName()
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_4, 0)
  end
end

function UMG_CharacterPick_C:EnterGame()
  NRCModuleManager:GetModule("LoginModule"):DispatchEvent(LoginModuleEvent.EnterGame, self.data)
  NRCModuleManager:DoCmd(LoginModuleCmd.ReqEnter)
end

function UMG_CharacterPick_C:BackToName()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1092, "UMG_CharacterPick_C:BackToConfirm")
  self:PlayAnimation(self.FinishOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self.ButtonBackFinish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:DelaySeconds(0.3, function()
    self.NameCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.FinishCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:PlayAnimation(self.NameIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end)
  _G.NRCModuleManager:DoCmd(AppearanceLoginModuleCmd.OpenBeautyLoginPanel, true)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.EndConfirmState, LoginModuleEvent.ConfirmToDesignState)
end

function UMG_CharacterPick_C:OnPCEscPressed()
  if self.FinishCanvas:GetVisibility() == UE4.ESlateVisibility.Visible and self.PickCanvas:GetVisibility() == UE4.ESlateVisibility.Hidden then
    self:BackToName()
  elseif self.ConfirmCanvas:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:NotifyBackToSelection()
  end
end

function UMG_CharacterPick_C:OnTextChanged()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1089, "UMG_CharacterPick_C:OnTextChanged")
  local playerName = self.InputTextName:GetText()
  self:SetPlayerName(playerName)
end

function UMG_CharacterPick_C:OnTextCommitted(text, type)
  if type == UE4.ETextCommit.OnEnter then
    self:SetPlayerName(text)
  end
end

function UMG_CharacterPick_C:OnTick(deltaTime)
  if self.bStartRot == true then
    local actorHolder = LoginUtils.GetUObjectHolder()
    local curRot = UE4.FRotator(0, 0, 0)
    local rotateAmount = self.deltaRot * deltaTime
    if rotateAmount > 0 then
      rotateAmount = math.min(7, rotateAmount)
    else
      rotateAmount = math.max(-7, rotateAmount)
    end
    if self.data.curRegisterGender == Enum.ESexValue.SEX_MALE then
      curRot = actorHolder.Player1:K2_GetActorRotation()
      if math.abs(curRot.Yaw - actorHolder.player1StartRotation.Yaw) > 3.5 then
        actorHolder.Player1:K2_SetActorRotation(curRot + UE4.FRotator(0, rotateAmount, 0), false)
      else
        self.bStartRot = false
      end
    elseif self.data.curRegisterGender == Enum.ESexValue.SEX_FEMALE then
      curRot = actorHolder.Player2:K2_GetActorRotation()
      if math.abs(curRot.Yaw - actorHolder.player2StartRotation.Yaw) > 3.5 then
        actorHolder.Player2:K2_SetActorRotation(curRot + UE4.FRotator(0, rotateAmount, 0), false)
      else
        self.bStartRot = false
      end
    end
  end
  if self.enterComposing then
    if not self:IsComposing() then
      self.enterComposing = false
      local playerName = self.InputTextName:GetText()
      self:SetPlayerName(playerName)
    end
  elseif self:IsComposing() then
    self.enterComposing = true
  end
end

function UMG_CharacterPick_C:NameUsable()
  self:PlayAnimation(self.NameOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self:DelaySeconds(0.3, function()
    self.NameCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.FinishCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn_NameConfirm:SetIsEnabled(true)
    self.Btn_NameConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.FinishIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end)
  _G.NRCModuleManager:DoCmd(AppearanceLoginModuleCmd.OpenBeautyLoginPanel, false)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.DesignToConfirm)
  self.bStartRot = true
  self:CalcDeltaRotation()
end

function UMG_CharacterPick_C:CalcDeltaRotation()
  local ActorHolder = LoginUtils.GetUObjectHolder()
  local curRot = FRotatorZero()
  local targetRot = FRotatorZero()
  if self.data.curRegisterGender == Enum.ESexValue.SEX_MALE then
    curRot = ActorHolder.Player1:K2_GetActorRotation()
    targetRot = ActorHolder.player1StartRotation
  elseif self.data.curRegisterGender == Enum.ESexValue.SEX_FEMALE then
    curRot = ActorHolder.Player2:k2_GetActorRotation()
    targetRot = ActorHolder.player2StartRotation
  end
  local deltaRot = (targetRot.Yaw - curRot.Yaw) % 360
  if deltaRot > 180 then
    deltaRot = deltaRot - 360
  end
  self.deltaRot = deltaRot
end

function UMG_CharacterPick_C:CheckNameUsable()
  local nameText = self.InputTextName:GetText()
  if not UIUtils.CheckNameIsLegal(nameText) then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_3, 0)
    Log.Debug("UMG_CharacterPick_C:CheckNameUsable nameText has special chars, nameText: ", nameText)
    return
  end
  self:SendZoneCheckNameReq(nameText)
end

function UMG_CharacterPick_C:SendZoneCheckNameReq(content)
  local req = _G.ProtoMessage:newZoneCheckNameReq()
  req.name = content
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_CHECK_NAME_REQ, req, self, self.CheckName, true)
end

function UMG_CharacterPick_C:CheckName(rsp)
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.SUCCESS then
    self:NameUsable()
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_DUPLICATE then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_2, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_INVALID_NAME_LEN then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_1, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_3, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_EMPTY then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_4, 0)
  end
end

function UMG_CharacterPick_C:OnVirtualKeyboardShowOrHide(bShow)
  self.bCurVirtualKeyboardIsShow = bShow
  self:StartBlur(bShow)
end

function UMG_CharacterPick_C:StartBlur(bOn)
  if bOn and RocoEnv.PLATFORM ~= "PLATFORM_WINDOWS" then
    self.BackgroundCapture:StartCapture()
    self.BackgroundCapture:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BackgroundCapture:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_CharacterPick_C:StartEditName()
  self.currentName = self:GetPlayerName()
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Visible)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.InputTextName:SetFocus()
end

function UMG_CharacterPick_C:AutoTestEnterText(text)
  self:SetPlayerName(text)
end

function UMG_CharacterPick_C:SubStr(str, byte_count)
  local count = 0
  local len = #str
  local index = 1
  while byte_count > count and len >= index do
    local ch = string.byte(str, index)
    local step
    if ch < 128 then
      step = 1
    elseif ch >= 192 and ch < 224 then
      step = 2
    elseif ch >= 224 and ch < 240 then
      step = 3
    elseif ch >= 240 and ch < 248 then
      step = 4
    elseif ch >= 248 and ch < 252 then
      step = 5
    elseif ch >= 252 then
      step = 6
    else
      step = 0
    end
    if byte_count < count + step then
      break
    end
    count = count + step
    index = index + step
  end
  return string.sub(str, 1, index - 1)
end

function UMG_CharacterPick_C:SetPlayerName(text, bNotShowTip)
  if self:IsComposing() then
    return
  end
  if string.SubStringGetTotalIndex(text) > 12 then
    self.InputTextName:SetJustification(UE4.ETextJustify.Left)
    self.NameShow:SetJustification(UE4.ETextJustify.Left)
  else
    self.InputTextName:SetJustification(UE4.ETextJustify.Center)
    self.NameShow:SetJustification(UE4.ETextJustify.Center)
  end
  local oldText = text
  text = self:SubStr(text, 21)
  text = string.GetSubStr(text, 12)
  if oldText ~= text and not bNotShowTip then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.max_name_tip)
  end
  local finalText = UIUtils.RemoveEmoji(text)
  finalText = UIUtils.RemoveInvalidCharsByFont(finalText, self.InputTextName.WidgetStyle.Font.FontObject)
  local bIsLegal = UIUtils.CheckNameIsLegal(finalText)
  self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  self.NameExplain:SetVisibility(bIsLegal and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  local normalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_yellow_png.img_btn1_yellow_png'"
  UIUtils.SetBtnGary(self.Btn_Confirm, not bIsLegal, bIsLegal, normalIconPath)
  local curName = self.InputTextName:GetText()
  if finalText ~= curName then
    self.InputTextName:SetText(finalText)
  end
  self.NameShow:SetText(finalText)
end

function UMG_CharacterPick_C:OnSelectedSeqFinished()
end

function UMG_CharacterPick_C:GetPlayerName()
  return self.InputTextName:GetText()
end

function UMG_CharacterPick_C:StopSeqq()
  self:StopSeq()
end

function UMG_CharacterPick_C:OnMaleBtnClick()
  if not self.allowClick then
    return
  end
  if self.isInMale then
    return
  end
  self.isInMale = true
  self.isInFemale = false
  NRCEventCenter:DispatchEvent(LoginModuleEvent.CharacterSelected, LoginModuleEvent.MaleCharacterSelected)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.EndPostSelectionIdle, LoginModuleEvent.MaleCharacterSelected)
  self.SexBtn_Male:PlayAnimation(self.SexBtn_Male.Select)
  self.SexBtn_Female:PlayAnimation(self.SexBtn_Female.Out)
  if self.ConfirmCanvas:GetVisibility() == UE4.ESlateVisibility.Visible then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_CharacterPick_C:SwitchCharacterMale")
  end
end

function UMG_CharacterPick_C:OnFemaleBtnClick()
  if not self.allowClick then
    return
  end
  if self.isInFemale then
    return
  end
  self.isInMale = false
  self.isInFemale = true
  NRCEventCenter:DispatchEvent(LoginModuleEvent.CharacterSelected, LoginModuleEvent.FemaleCharacterSelected)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.EndPostSelectionIdle, LoginModuleEvent.FemaleCharacterSelected)
  self.SexBtn_Female:PlayAnimation(self.SexBtn_Male.Select)
  self.SexBtn_Male:PlayAnimation(self.SexBtn_Male.Out)
  if self.ConfirmCanvas:GetVisibility() == UE4.ESlateVisibility.Visible then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_CharacterPick_C:SwitchCharacterFemale")
  end
end

function UMG_CharacterPick_C:OnBtnConfirmClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_CharacterPick_C:OnItemSelected")
  if _G.CreatePlayerModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.CreatePlayerModuleCmd.CheckNameUsable)
  else
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.CheckNameUsable)
  end
end

function UMG_CharacterPick_C:IsComposing()
  return UE4.UNRCStatics.IsComposing(self.InputTextName)
end

return UMG_CharacterPick_C
