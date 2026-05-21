local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local UMG_Pass_Select_C = _G.NRCPanelBase:Extend("UMG_Pass_Select_C")

function UMG_Pass_Select_C:OnConstruct()
end

function UMG_Pass_Select_C:ShowSwitchArrow(bShow)
  local visibility = bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
  if self.Btn_ArrowL then
    self.Btn_ArrowL:SetVisibility(visibility)
  end
  if self.Btn_ArrowR then
    self.Btn_ArrowR:SetVisibility(visibility)
  end
end

function UMG_Pass_Select_C:OnActive()
  local ArrowLData = {}
  ArrowLData.Call = self
  ArrowLData.btnHandler = self.OnClickArrowL
  ArrowLData.modeIndex = 3
  self.Btn_ArrowL:SetBtnInfo(ArrowLData)
  local ArrowRData = {}
  ArrowRData.Call = self
  ArrowRData.btnHandler = self.OnClickArrowR
  ArrowRData.modeIndex = 4
  self.Btn_ArrowR:SetBtnInfo(ArrowRData)
  self:ShowSwitchArrow(false)
  self:InitSpineWidget()
  self.SwitchToMoon = false
  self.SwitchToStart = false
  self.bShowMoonLight = false
  _G.NRCAudioManager:PlaySound2DAuto(1220002014, " UMG_Pass_Select_C:OnActive")
  local passInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local pass_id = passInfo.battle_pass_id
  local leftText = _G.DataConfigManager:GetLocalizationConf("BP_theme_choose_left").msg
  local rightText = _G.DataConfigManager:GetLocalizationConf("BP_theme_choose_right").msg
  self.isSelectPass = passInfo.theme_id and passInfo.theme_id > 0 and true or false
  self.BattlePassConf = _G.DataConfigManager:GetBattlePassConf(pass_id)
  self:SetCommonTitle()
  self.Title1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:OnAddEventListener()
  self:UpdatePanel()
  self.SubjectsChoice:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Moonshine:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_Affirm_moon.Title_1:SetText(rightText)
  self.Btn_affirm.Title_1:SetText(rightText)
  self.Btn_Return_1.Title_1:SetText(leftText)
  self.Btn_Return.Title_1:SetText(leftText)
  self.Btn_Affirm_moon.Title_2:SetText(rightText)
  self.Btn_affirm.Title_2:SetText(rightText)
  self.Btn_Return_1.Title_2:SetText(leftText)
  self.Btn_Return.Title_2:SetText(leftText)
  self.UMG_Pass_Select_Light:PlayLoop()
  self.CanvasPanel_83:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:DelaySeconds(2, function()
      self:ShowStartCanvas()
    end)
  end
  self:UnlockIsSelectBtn()
  self:BindInputAction()
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  self.bShowingStarConfirmTips = nil
end

function UMG_Pass_Select_C:InitSpineWidget()
  self.module:InitSpineWidgetForPanel(self, "BattlePassSelectPanel", "UMG_Pass_Select")
end

function UMG_Pass_Select_C:UpdatePanel()
  if self.BattlePassConf then
    local theme_ids = self.BattlePassConf.theme_id
    self:UpdateStarlight(theme_ids[2])
    self:UpdateMoonshine(theme_ids[1])
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_Select", self, theme_ids[1])
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_Select", self, theme_ids[2])
  end
end

function UMG_Pass_Select_C:ShowSelectCanvas()
  self:PlayAnimation(self.Out_Pink)
end

function UMG_Pass_Select_C:OutStartCanvas()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Pass_Select_C:OutStartCanvas")
  self:ShowSwitchArrow(false)
  self:PlayAnimation(self.Out_Pink)
  _G.NRCAudioManager:PlaySound2DAuto(1220002016, " UMG_Pass_Select_C:OutStartCanvas")
  self.Starlight:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Moonshine:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_affirm:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Btn_Return:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Pet_Starlight:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Pet_Moonshine:SetVisibility(UE4.ESlateVisibility.Visible)
  self.bShowingStarConfirmTips = nil
end

function UMG_Pass_Select_C:OutMoonCanvas()
  self:ShowSwitchArrow(false)
  self:PlayAnimation(self.Out_Blue)
  _G.NRCAudioManager:PlaySound2DAuto(1220002016, " UMG_Pass_Select_C:OutMoonCanvas")
  self.Starlight:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Moonshine:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_Affirm_moon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Btn_Return_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Pet_Starlight:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Pet_Moonshine:SetVisibility(UE4.ESlateVisibility.Visible)
  self.bShowingStarConfirmTips = nil
end

function UMG_Pass_Select_C:ShowStartCanvas()
  if self:IsAnimationPlaying(self.Page_In) then
    return
  end
  self:PlayAnimation(self.In_Pink)
  _G.NRCAudioManager:PlaySound2DAuto(1220002015, " UMG_Pass_Select_C:ShowStartCanvas")
  self.Starlight:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_affirm:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_Return:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Pet_Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Pet_Moonshine:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bShowingStarConfirmTips = true
end

function UMG_Pass_Select_C:ShowMoonCanvas()
  if self:IsAnimationPlaying(self.Page_In) then
    return
  end
  self:PlayAnimation(self.In_Blue)
  self.Btn_Affirm_moon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_Return_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(1220002015, " UMG_Pass_Select_C:ShowMoonCanvas")
  self.Moonshine:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Pet_Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Pet_Moonshine:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bShowingStarConfirmTips = false
end

function UMG_Pass_Select_C:UpdateStarlight(theme_id)
  local themeConf = _G.DataConfigManager:GetBattlePassThemeConf(theme_id)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(themeConf.theme_petbase_id)
  self.Text_Introduce:SetText(themeConf.theme_desc)
  self.NRCText_138:SetText(themeConf.theme_pet_title)
  self.textPetName:SetText(petBaseConf.name)
  self:ShowTypeIcons(petBaseConf, 1)
  self.startPetId = themeConf.theme_petbase_id
  self.startThemeId = theme_id
end

function UMG_Pass_Select_C:UpdateMoonshine(theme_id)
  local themeConf = _G.DataConfigManager:GetBattlePassThemeConf(theme_id)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(themeConf.theme_petbase_id)
  self.Text_Introduce_1:SetText(themeConf.theme_desc)
  self.NRCText:SetText(themeConf.theme_pet_title)
  self.textPetName_1:SetText(petBaseConf.name)
  self:ShowTypeIcons(petBaseConf, 2)
  self.moonPetId = themeConf.theme_petbase_id
  self.moonThemeId = theme_id
end

function UMG_Pass_Select_C:ShowTypeIcons(petBaseConf, selectType)
  local unit_type = petBaseConf.unit_type
  local commonAttrData = {}
  for i = 1, 2 do
    local petType = unit_type[#unit_type - i + 1]
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        table.insert(commonAttrData, 1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon,
          ShowTips = true,
          Type = petType
        })
      end
    end
  end
  if selectType and 1 == selectType then
    if self.Attr then
      self.Attr:InitGridView(commonAttrData)
    end
  elseif selectType and 2 == selectType and self.Attr1 then
    self.Attr1:InitGridView(commonAttrData)
  end
end

function UMG_Pass_Select_C:OnDeactive()
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, true)
  self:ClearAllEnhancedInput()
end

function UMG_Pass_Select_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_PassSelect")
  if mappingContext then
    mappingContext:BindAction("IA_Close_PassSelect", self, "OnPcClose")
  end
end

function UMG_Pass_Select_C:OnPcClose()
  self:StopAllAnimations()
  if self.bShowingStarConfirmTips ~= nil then
    if self.bShowingStarConfirmTips then
      self:OutStartCanvas()
    else
      self:OutMoonCanvas()
    end
  else
    self:OnClosePanel()
  end
end

function UMG_Pass_Select_C:OnPcClose2()
  if self.bShowingStarConfirmTips == nil then
    self:OnClosePanel()
  end
end

function UMG_Pass_Select_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  local battleThemConf = _G.DataConfigManager:GetBattlePassThemeConf(self.BattlePassConf and self.BattlePassConf.theme_id and self.BattlePassConf.theme_id[1])
  if nil == battleThemConf then
    Log.Error("UMG_Pass_Select_C:SetCommonTitle battleThemConf is nil")
    return
  end
  self.Title1:Set_MainTitle(battleThemConf.theme_name)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Pass_Select_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Return.btnLevelUp, self.OutStartCanvas)
  self:AddButtonListener(self.Btn_Return_1.btnLevelUp, self.OutMoonCanvas)
  self:AddButtonListener(self.UMG_Details_1.btnLevelUp, self.OnOpenMoonPetPanel)
  self:AddButtonListener(self.UMG_Details.btnLevelUp, self.OnOpenStartPetPanel)
  self:AddButtonListener(self.Btn_affirm.btnLevelUp, self.OnAffirmStart)
  self:AddButtonListener(self.Btn_Affirm_moon.btnLevelUp, self.OnAffirmMoon)
  self:AddButtonListener(self.Pet_Starlight, self.ShowStartCanvas)
  self:AddButtonListener(self.Pet_Moonshine, self.ShowMoonCanvas)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnClosePanel)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnOpenTips)
  self:AddButtonListener(self.StarlightDepartment, self.OnStarlightDepartmentClick)
  self:AddButtonListener(self.MoonshineDepartment, self.OnMoonshineDepartmentClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Select_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
end

function UMG_Pass_Select_C:OnOpenTips()
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_Select_C:OnOpenTips")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = "\230\180\187\229\138\168\232\175\180\230\152\142"
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local rule_tips_id = _G.DataConfigManager:GetBattlePassConf(BattlePassInfo.battle_pass_id).rule_tips_id
  local Content = _G.DataConfigManager:GetLocalizationConf(rule_tips_id).msg
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Pass_Select_C:OnClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_Pass_Select_C.OnAnimationFinished")
  local passInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.isSelectPass = passInfo.theme_id and passInfo.theme_id > 0 and true or false
  if self.isSelectPass == false then
    UE4Helper.SetEnableWorldRendering(true)
  end
  local mappingContext = self:GetInputMappingContext("IMC_PassSelect")
  if mappingContext then
    mappingContext:UnBindAction("IA_Close_PassSelect")
  end
  self:StopAllAnimations()
  self.UMG_Pass_Select_Light:StopAnimation(self.UMG_Pass_Select_Light.Loop)
  self:PlayAnimation(self.Page_Out)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  self.UMG_btnClose.btnClose:SetIsEnabled(false)
  self:OnClose()
end

function UMG_Pass_Select_C:OnOpenStartPetPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Pass_Select_C:OnOpenStartPetPanel")
  if self.startPetId then
    local petId = self.startPetId
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petId, true)
  end
end

function UMG_Pass_Select_C:OnOpenMoonPetPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Pass_Select_C:OnOpenStartPetPanel")
  if self.moonPetId then
    local petId = self.moonPetId
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petId, true)
  end
end

function UMG_Pass_Select_C:OnAffirmStart()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Pass_Select_C:OutStartCanvas")
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if curPassInfo then
    local theme_id = curPassInfo.theme_id
    if theme_id == self.startThemeId then
      if self.module:HasPanel("BattlePassAwardMain") then
        _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ClosePassSelectPanel)
      else
        _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, nil, false)
      end
      return
    end
  end
  self.selectAnim = self.Select_Pink
  _G.NRCAudioManager:PlaySound2DAuto(1220002019, " UMG_Pass_Select_C:OnAffirmStart")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ZoneSelectBattlePassThemeReq, self.startThemeId)
  self.Btn_affirm:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_Pass_Select_C:OnAffirmMoon()
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if curPassInfo then
    local theme_id = curPassInfo.theme_id
    if theme_id == self.moonThemeId then
      if self.module:HasPanel("BattlePassAwardMain") then
        _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ClosePassSelectPanel)
      else
        _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, nil, false)
      end
      return
    end
  end
  self.selectAnim = self.Select_Blue
  _G.NRCAudioManager:PlaySound2DAuto(1220002019, " UMG_Pass_Select_C:OnAffirmMoon")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ZoneSelectBattlePassThemeReq, self.moonThemeId)
  self.Btn_Affirm_moon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_Pass_Select_C:OnAnimStarted(anim)
  Log.Info("PassStart\230\146\173\230\148\190\231\154\132\229\138\168\231\148\187\230\152\175\239\188\154" .. anim.DisplayLabel)
  if anim == self.Out_Pink or anim == self.Out_Blue then
    self:StopAnimation(self.Loop_Selecting)
  elseif anim == self.In_Pink or anim == self.In_Blue then
    self:StopAnimation(self.Page_Loop)
  end
end

function UMG_Pass_Select_C:OnAnimationFinished(anim)
  Log.Info("PassFinish\230\146\173\230\148\190\231\154\132\229\138\168\231\148\187\230\152\175\239\188\154" .. anim.DisplayLabel)
  if anim == self.Out_Pink or anim == self.Out_Blue then
    self.SubjectsChoice:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Moonshine:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.Page_Out then
  elseif anim == self.Select_Blue or anim == self.Select_Pink then
    self:OnClose()
  elseif anim == self.Page_In then
    local endTime = self.Page_In:GetEndTime()
    self:SetAnimationCurrentTime(self.Page_In, endTime)
    Log.Info("PassFinish\230\146\173\230\148\190\231\154\132\229\138\168\231\148\187\230\152\175\239\188\154page_in,endtime:  ", endTime)
    self:PlayAnimation(self.Page_Loop, 0, 0)
  elseif anim == self.In_Pink or anim == self.In_Blue then
    if self.bShowingStarConfirmTips ~= nil then
      self:ShowSwitchArrow(true)
    end
    self:PlayAnimation(self.Loop_Selecting, 0, 0)
  end
  if self.SwitchToMoon then
    if anim == self.Out_Pink then
      self:ShowMoonCanvas()
    end
    if anim == self.In_Blue then
      self.SwitchToMoon = false
    end
  end
  if self.SwitchToStart then
    if anim == self.Out_Blue then
      self:ShowStartCanvas()
    end
    if anim == self.In_Pink then
      self.SwitchToStart = false
    end
  end
  NRCPanelBase.OnAnimationFinished(self, anim)
end

function UMG_Pass_Select_C:OnTick(deltaTime)
  if self.SpineWidget_Pink then
    self.SpineWidget_Pink:Tick(deltaTime, false)
  end
  if self.SpineWidget_Blue then
    self.SpineWidget_Blue:Tick(deltaTime, false)
  end
end

function UMG_Pass_Select_C:OnLogin()
end

function UMG_Pass_Select_C:OnSelectClosePanel()
  if self.selectAnim then
    self:PlayAnimation(self.selectAnim)
  end
end

function UMG_Pass_Select_C:OnReLoginUpdate()
  self.Btn_Affirm_moon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_affirm:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Pet_Moonshine:SetIsEnabled(true)
  self.Pet_Starlight:SetIsEnabled(true)
end

function UMG_Pass_Select_C:OnDestruct()
  local passInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.isSelectPass = passInfo.theme_id and passInfo.theme_id > 0 and true or false
  if self.isSelectPass == false then
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP, self.module.ActivityPassBgmState)
    if self.module.ActivityPassBgmState then
      MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
    end
  end
  _G.NRCEventCenter:UnRegisterEvent(self, "UMG_Pass_Select_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
end

function UMG_Pass_Select_C:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").CHANGETEAM)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PASS)
end

function UMG_Pass_Select_C:SwitchTheme()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Pass_Select_C:SwitchTheme")
  if self.bShowingStarConfirmTips ~= nil and self.bShowingStarConfirmTips then
    self.SwitchToMoon = true
    self:OutStartCanvas()
  else
    self.SwitchToStart = true
    self:OutMoonCanvas()
  end
end

function UMG_Pass_Select_C:OnStarlightDepartmentClick()
  if self.startPetId then
    local uiData = {}
    local petData = {}
    petData.base_conf_id = self.startPetId
    uiData.petData = petData
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uiData, _G.Enum.GoodsType.GT_PET)
  end
end

function UMG_Pass_Select_C:OnMoonshineDepartmentClick()
  if self.moonPetId then
    local uiData = {}
    local petData = {}
    petData.base_conf_id = self.moonPetId
    uiData.petData = petData
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uiData, _G.Enum.GoodsType.GT_PET)
  end
end

function UMG_Pass_Select_C:OnClickArrowL()
  self:SwitchTheme()
end

function UMG_Pass_Select_C:OnClickArrowR()
  self:SwitchTheme()
end

return UMG_Pass_Select_C
