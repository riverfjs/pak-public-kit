local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UMG_PetInfoMain_C = _G.NRCPanelBase:Extend("UMG_PetInfoMain_C")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BattleUIModuleCmd = reload("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local FULL_SCREEN_SHOW_TIME = 1

function UMG_PetInfoMain_C:Initialize(Initializer)
  self.show = false
end

function UMG_PetInfoMain_C:OnConstruct()
  self.isEnterScreen = false
  self.isEnterFree = false
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PET)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PET)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  else
    _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;Pet_Interface")
  end
  local db = _G.DataConfigManager:GetGlobalConfigByKeyType("ui_audio_reduction_db", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  UE4.UNRCAudioManager.SetWorldListenerVolumeOffset(db)
  self.IsFirstLoadBg = true
  self:OnAddEventListener()
  self:BindInputAction()
  self.data = self.module:GetData("PetUIModuleData")
  if false == self.show then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OpenedOrCloseMain, true)
    self.show = true
  end
  self:SetChildViews(self.petMiddlePanel, self.petLeftPanel)
  self.petLeftPanel:setPetInfoMainCtrl(self)
  self.petMiddlePanel:setPetInfoMainCtrl(self)
  self.petMiddlePanel:GetPetViewCameraActor()
  _G.NRCAudioManager:SetStateByName("Pet_Action_Universal", "Open", "UMG_PetInfoMain_C")
  self.currentSelectedPetIndex = 0
  self.petInfo = nil
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPetData then
    self.IsFirstOpen = true
    self:HideLeftPanel(true)
  end
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.localPlayer then
    self.Controller = self.localPlayer:GetUEController()
    self.localPlayer:SendEvent(PlayerModuleEvent.ON_END_THROW, false)
  end
  self.NeedSelectAudio = false
  self.CanListenShareType = true
  self:InitComboBox()
  self.module:PreLoadPanel("PetRightPanel")
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:CheckShareIsOpen()
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetDistrictMapGuideRecordEnable, true, "UMG_PetInfoMain_C")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetIsShowPetNotUnlockSkill, false)
end

function UMG_PetInfoMain_C:OnDestruct()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PET)
  UE4.UNRCAudioManager.ResetWorldListenerVolumeOffset()
  if self.show == true then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OpenedOrCloseMain, false)
    self.show = false
  end
  _G.NRCAudioManager:SetStateByName("Pet_Action_Universal", "Close", "UMG_PetInfoMain_C")
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnMainPetUIExit)
  self.module.IsBagToOpenPanel = false
  local openPetData, index, isRevertPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if not self.data then
    Log.Error("moduleData\228\184\141\232\167\129\228\186\134\239\188\140\230\156\137\233\151\174\233\162\152")
  end
  self.data.CulCanEvo = false
  self.data.CulCanBreakThrough = false
  self.data:SetFriendInfoToPetMain(nil)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, nil, nil, isRevertPanel)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseMyTeamPanel)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetDistrictMapGuideRecordEnable, false, "UMG_PetInfoMain_C")
  self.module:InitCachePetBoxFilterData()
  self:UpdateMainPet()
  self:OnRemoveEventListener()
end

function UMG_PetInfoMain_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_PetUI")
  if mappingContext then
    mappingContext:BindAction("IA_ClosePetUI", self, "OnPcClose")
    mappingContext:BindAction("IA_ClosePetQuick", self, "OnPcClose")
  end
end

function UMG_PetInfoMain_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  if self.petMiddlePanel.petImage3D.eggConfid then
    return
  end
  if self.isEnterFree then
    if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
      self.module:SwitchReleaseLifeModeInPortableBag()
    end
    self:DispatchEvent(PetUIModuleEvent.OnNewPetBagExitFree)
    return
  end
  if self.petLeftPanel then
    self.petLeftPanel:LeaveDragState()
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetRightPanelPcClose)
end

function UMG_PetInfoMain_C:OnActive(_param, IsPvPToPetTeam, resListData, bShowSendMark, ...)
  self.bShowSendMark = bShowSendMark
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOSE_PET)
  if not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.IsPetHatchingPanel) then
    self.petMiddlePanel.petImage3D:OnActive(_param.baseConf, _param.ModuleName, resListData.modelPath)
  else
    self:EnterEggPanelHideComponents()
  end
  if _G.AppearanceModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  end
  self.LoadFinishCallback = _param.callback
  self.LoadFinishCaller = _param.caller
  self.subPanelIndex = _param and _param.subPanelIndex or 1
  self._param = _param
  self:OnUMGLoadFinished()
  self.IsPvPToPetTeam = IsPvPToPetTeam
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    self.petLeftPanel:StopAnimation(self.petLeftPanel.Open)
    self.petLeftPanel:PlayAnimation(self.petLeftPanel.Open, 0, 1, 0, 1)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn or 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:DelaySeconds(3, function()
      self.petLeftPanel.Attribute:SwitchVersion()
    end)
  elseif 4 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:DelaySeconds(1, function()
      self.petLeftPanel:OnPetBagBtnClick()
    end)
  end
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  self:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.SetIsOpenPetPanel, false)
  if _param.bHideSkill then
    self.bHideSkill = _param.bHideSkill
    self.petLeftPanel:SetSkillShow(false)
  end
  if _param.bUseOpenPetData then
    self.bUseOpenPetData = _param.bUseOpenPetData
  end
  if self.petLeftPanel and self.petLeftPanel.Attribute then
    self.petLeftPanel.Attribute.bShowSendMark = bShowSendMark
  end
  self:CheckEnterType()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_PetInfoMain_C:_OnPreNtfEnterScene()
  self.module:OnCmdClosePetBloodPulse()
  self:ClosePetInfoMain(true)
end

function UMG_PetInfoMain_C:OnUMGLoadFinished()
  if self.LoadFinishCallback and self.LoadFinishCaller then
    self.LoadFinishCallback(self.LoadFinishCaller)
  end
  self.LoadFinishCallback = nil
  self.LoadFinishCaller = nil
  self:OnMainPanelStateChange(true, true)
  self:StartCamera()
  self.UMG_btnClose.NRCSwitcher_1:SetActiveWidgetIndex(0)
end

function UMG_PetInfoMain_C:SetBtnIsEnabled(IsEnabled)
  if IsEnabled then
    self.UMG_btnClose.btnClose:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.UMG_btnClose.btnClose:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetInfoMain_C:StartCamera()
  self:OnSwithBagCameraFinished()
end

function UMG_PetInfoMain_C:OnSwithBagCameraFinished()
  local bHasCompass = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.HasCompass)
  if not bHasCompass then
  end
end

function UMG_PetInfoMain_C:OpenPetBloodPulsePanel()
end

function UMG_PetInfoMain_C:OnPetBagOpen()
  self.petLeftPanel:OnMenuButtonClick(1)
  self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, false)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.EnterBackpack)
end

function UMG_PetInfoMain_C:OnPetBagClose()
  local selectPetIndex = self.currentSelectedPetIndex
  self.petLeftPanel:updatePetList(false)
  if selectPetIndex > 6 then
    self.petLeftPanel:OnPetItemClick(selectPetIndex)
  else
    self.petLeftPanel:OnPetItemClick(selectPetIndex)
  end
  self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.ExitBackpack)
end

function UMG_PetInfoMain_C:CheckPetLeftPanelVisibleAndShowPetHeadList()
  if self.petLeftPanel then
    local leftPanelVisible = self.petLeftPanel:GetVisibility() == UE4.ESlateVisibility.Visible or self.petLeftPanel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible
    local showList = self.petLeftPanel:CheckPetHeadListShow()
    return leftPanelVisible and showList
  end
  return false
end

function UMG_PetInfoMain_C:SetMask()
  self:DispatchEvent(PetUIModuleEvent.PET_UI_UPGRADE_CONSTRAINT, false)
end

function UMG_PetInfoMain_C:OnEnable()
end

function UMG_PetInfoMain_C:OnDisable()
end

function UMG_PetInfoMain_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.BtnReturn.btnClose, self.OnReturnButtonClicked)
  self:AddButtonListener(self.ViewingBtn.btnLevelUp, self.OnViewingBtnClicked)
  self:AddButtonListener(self.RecommendedBtn.btnLevelUp, self.OnRecommendedBtnClicked)
  self:AddButtonListener(self.TimeRewindBtn.btnLevelUp, self.OnTimeRewindBtnClicked)
  self:AddButtonListener(self.ShareMaskBtn, self.OnShareMaskBtn)
  self:RegisterEvent(self, PetUIModuleEvent.ChangeChoosePet, self.OnSelectPetIndex)
  self:RegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_CHANGE, self.OnLeftSubPanelChange)
  self:RegisterEvent(self, PetUIModuleEvent.ClosePetInfoBtn, self.OnClosePetInfoBtn)
  self:RegisterEvent(self, PetUIModuleEvent.Hide_CloseBtn, self.ShowOrHideCloseBtn)
  self:RegisterEvent(self, PetUIModuleEvent.ShowHideRecommendedBtn, self.OnShowHideRecommendedBtn)
  self:RegisterEvent(self, MainUIModuleEvent.OPEN_PET_FORMATION, self.OpenPetFormation)
  self:RegisterEvent(self, PetUIModuleEvent.ShowPetInfoMainUI, self.ShowPetInfoMainUI)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewEvoPanelOpened, self.OnNewEvoPanelOpened)
  self:RegisterEvent(self, PetUIModuleEvent.OnLoadBackgroundSucc, self.OnLoadBackgroundSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewEvoPanelClosed, self.OnNewEvoPanelClosed)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewEvoPanelDestruct, self.OnNewEvoPanelDestruct)
  self:RegisterEvent(self, PetUIModuleEvent.OnSetPetActorRotation, self.SetPetActorRotation)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_UPGRADE_CONSTRAINT, self.OnUpGradeConstraint)
  self:RegisterEvent(self, PetUIModuleEvent.SwitchCloseBtnState, self.OnSwitchCloseBtnState)
  self:RegisterEvent(self, PetUIModuleEvent.MovePetModelToLeft, self.OnLeftCloseSubPanel)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewPetBagEnterScreenState, self.OnChangeCloseBtnStyle)
  _G.NRCEventCenter:RegisterEvent("UMG_PetInfoMain_C", self, PetUIModuleEvent.OnShareComboBoxSelectChanged, self.SelectShareType)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnCloseEggPanel, self.OnCloseEggClick)
  self:AddButtonListener(self.GiftColleaguesBtn.btnLevelUp, self.OnGiftBtnClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnSendPetFailed, self.OnSendPetFailed)
  self:RegisterEvent(self, PetUIModuleEvent.ShowHideGiftColleaguesBtn, self.ShowHideGiftColleaguesBtn)
  self:RegisterEvent(self, PetUIModuleEvent.ShowHideTimeRewindBtn, self.ShowHideTimeRewindBtn)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_PetInfoMain_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_CHANGE)
  self:UnRegisterEvent(self, PetUIModuleEvent.Hide_CloseBtn)
  self:UnRegisterEvent(self, PetUIModuleEvent.ShowHideRecommendedBtn)
  self:UnRegisterEvent(self, MainUIModuleEvent.OPEN_PET_FORMATION)
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_PLAYER_DEAD, self.DeadClosePanel)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnLoadBackgroundSucc)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewEvoPanelOpened)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewEvoPanelDestruct)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnSetPetActorRotation)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnShareComboBoxSelectChanged, self.SelectShareType)
  self:RemoveButtonListener(self.ShareBtn.btnLevelUp)
  self:RemoveButtonListener(self.TimeRewindBtn.btnLevelUp)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnCloseEggPanel)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnSendPetFailed)
  self:UnRegisterEvent(self, PetUIModuleEvent.ShowHideGiftColleaguesBtn)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagEnterScreenState)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_PetInfoMain_C:OnShowHideRecommendedBtn(show)
  if self.RecommendedBtn then
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      show = false
    end
    self.RecommendedBtn:SetVisibility(show and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:DeadClosePanel()
  self:ClosePetInfoMain(false)
end

function UMG_PetInfoMain_C:OnLeftSubPanelChange(_subPanelIndex)
  local bShow = not _subPanelIndex or not (_subPanelIndex > 0)
  self:ShowOrHideCloseBtn(bShow)
end

function UMG_PetInfoMain_C:OnClosePetInfoBtn(IsClos)
  self:ShowOrHideCloseBtn(not IsClos)
end

function UMG_PetInfoMain_C:ShowPetInfoMainUI(bShow, bAnim)
  if bShow then
    if bAnim then
      self:OnClickAttributeBtn()
      self.petLeftPanel:PlayEvoPanelAnim(false)
      if self:GetPetBagOpenState() == false then
        self.petMiddlePanel.petImage3D:EvoPlayPetSkill(false, true)
      else
      end
    end
  elseif bAnim then
    self:OnClickAttributeBtn()
    self.petLeftPanel:PlayEvoPanelAnim(true)
    if self:GetPetBagOpenState() == false then
      self.petMiddlePanel.petImage3D:EvoPlayPetSkill(true, true)
    else
    end
  end
end

function UMG_PetInfoMain_C:OnSelectPetChange(_petData)
  self.petLeftPanel:OnSelectPetChange(_petData)
  self.module.data.PetData = _petData
  local bOnlyPetDataRefresh = self.petData and _petData and self.petData.gid == _petData.gid
  self.petData = _petData
  self:DispatchEvent(PetUIModuleEvent.RightPanelSelectPetChange, _petData, nil, bOnlyPetDataRefresh)
  self.petMiddlePanel:OnSelectPetChange(_petData)
  self:CheckCanSendToFriend()
  local bOpenEvoPanel = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsOpenEvoPanel)
  if self.petData and not bOpenEvoPanel then
    if self.ShareIsOpen then
      local isHidden = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, self.petData.gid)
      if isHidden then
        self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
        if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
          self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self:ShowShareBtn()
        end
      end
    end
  elseif not self.petData then
    self:ResetShareComboBox()
  end
  self:CheckEnterType()
end

function UMG_PetInfoMain_C:OnPlayerDataUpdate(UpdateGoodType, PetDataChangeItemList)
  if UpdateGoodType == _G.Enum.GoodsType.GT_PET and self.petInfo and self.petInfo.petData then
    self.petInfo.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petInfo.petData.gid)
    self:UpdateTimeRewindBtnVisibility()
  end
end

function UMG_PetInfoMain_C:CheckCanSendToFriend()
  self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local canShow = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCanShowSendBtn)
  local bOpenEvoPanel = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsOpenEvoPanel)
  if self.bShowSendMark and canShow and not bOpenEvoPanel and self.petData and self.petData.together_catch_info and self.petData.together_catch_info.is_onwer_catch then
    local timeStamp = self.petData.together_catch_info.transfer_deadline
    if timeStamp then
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      if currentTime and timeStamp > currentTime then
        local text = LuaText.peer_pet_give_btn_text
        self.GiftColleaguesBtn:SetText(text)
        self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  end
end

function UMG_PetInfoMain_C:OnGiftBtnClick()
  if self.petData and self.petData.gid then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendPetToFriend, self.petData.gid, true)
  end
end

function UMG_PetInfoMain_C:OnSendPetFailed()
  self:CheckCanSendToFriend()
end

function UMG_PetInfoMain_C:OnShowInitData(_data)
  if _data then
    if _data.pet_gid and _data.pet_gid > 0 then
      self.petLeftPanel:SetInitPetId(_data.pet_gid)
    end
    if _data.subMenuIndex and _data.subMenuIndex > 0 then
      self:DelayFrames(1, function()
        self.petLeftPanel:OnMenuButtonClick(_data.subMenuIndex)
        if 1 == _data.subMenuIndex and _data.showLevelUpPanel then
          self:OnClickAttributeBtn()
          NRCModuleManager:DoCmd(PetUIModuleCmd.OpenLevelUpPanel, self, self.uiData)
        end
      end)
    end
  end
end

function UMG_PetInfoMain_C:OnAnimationFinished(Animation)
  if Animation == self.In_2 then
    self.petLeftPanel:PlayAnimationIn()
    self:DispatchEvent(PetUIModuleEvent.RightPanelPlayAnimationIn)
  elseif Animation == self.In then
  elseif Animation == self.ChangeIn then
    self:OpenPetBloodPulsePanel()
    NRCModeManager:DoCmd(BattleUIModuleCmd.RestorePVPMatchClick)
  end
  if Animation == self.ChangeOut then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.Out then
    self:FinishCamera()
  end
end

function UMG_PetInfoMain_C:OnUpGradeConstraint(_ISConstraint)
  if _ISConstraint then
    self.BannedClick:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BannedClick:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetInfoMain_C:ClosePanelInfo()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetInfoMain_C:OnMainPanelStateChange(_isShow, _isParentChange)
  self:StopAllAnimations()
  if _isParentChange then
    if _isShow then
      self:PlayAnimation(self.ChangeIn)
      self.petLeftPanel:PlayAnimationIn()
    else
      self.petLeftPanel:PlayAnimationInReverse()
    end
  elseif _isShow then
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:OnDeactive()
  self:CancelDelay()
  self.petLeftPanel:OnDeactive()
  self.petMiddlePanel:OnDeactive()
  self:StopAllAnimations()
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_PetInfoMain_C:OnOpenSequenceLoaded(asset)
  if self.petMiddlePanel then
    self.petMiddlePanel.petImage3D:OnPlayCameraBoostSequence(asset)
  end
end

function UMG_PetInfoMain_C:SetPetActorRotation(deltaRotation)
  self.petMiddlePanel.petImage3D:SetPetActorRotation(deltaRotation)
end

function UMG_PetInfoMain_C:OnPetTraceBackSuccessAndRewardPopupClose(retVal, petGID)
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGID)
  local PetInfo = {
    base_conf_id = PetData.base_conf_id,
    gid = PetData.gid,
    level = PetData.level,
    petData = PetData
  }
  self:OnSelectPet(self.currentSelectedPetIndex, PetInfo, false, false)
end

function UMG_PetInfoMain_C:OnLeftCloseSubPanel()
  self.petMiddlePanel:MovePetModelToLeft()
end

function UMG_PetInfoMain_C:OnChangeCloseBtnStyle(isEnterScreen, isEnterFree)
  if nil ~= isEnterFree then
    self.isEnterFree = isEnterFree
  end
  if self.isEnterScreen or self.isEnterFree then
    self:ShowOrHideCloseBtn(false)
    self.BtnReturn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self:ShowOrHideCloseBtn(true)
    self.BtnReturn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:OnClickAttributeBtn()
  self.petLeftPanel.Attribute:SwitchVersion()
end

function UMG_PetInfoMain_C:showFightMainPanel()
  local curSubPanelIndex = self.petLeftPanel:getCurSubPanelIndex()
  if 1 == curSubPanelIndex then
    self.petLeftPanel:HideSubPanel()
    self:OnLeftCloseSubPanel()
  else
    self.petLeftPanel:ShowSubPanel(1, 1)
    self.petMiddlePanel:MovePetModelToRight()
  end
end

function UMG_PetInfoMain_C:showSkillMainPanel(_petSkillData, _skillIndex)
  if self.petLeftPanel:checkCurSkillInfo(_skillIndex) then
    self.petLeftPanel:HideSubPanel()
    self:OnLeftCloseSubPanel()
  else
    self.petLeftPanel:ShowSubPanel(2, 1)
    self.petMiddlePanel:MovePetModelToRight()
    self.petLeftPanel:OnMainUIPetSkillSelectChange(_petSkillData, _skillIndex)
  end
end

function UMG_PetInfoMain_C:showLevelUpPanel()
  self.petMiddlePanel:MovePetModelToRight()
end

function UMG_PetInfoMain_C:ShowGrowUpPanel()
  local curSubPanelIndex = self.petLeftPanel:getCurSubPanelIndex()
  if 4 == curSubPanelIndex then
    self:DispatchEvent(PetUIModuleEvent.HideSubPanel)
    self:OnLeftCloseSubPanel()
  else
    self:DispatchEvent(PetUIModuleEvent.RightPanelShowSubPanel, 5)
    self.petMiddlePanel:MovePetModelToRight()
  end
end

function UMG_PetInfoMain_C:showPetTotalWarehouse()
  local curSubPanelIndex = self.petLeftPanel:getCurSubPanelIndex()
  if 4 == curSubPanelIndex then
    self.petLeftPanel:HideSubPanel()
    self:OnLeftCloseSubPanel()
  else
    self.petLeftPanel:ShowSubPanel(4)
    self.petMiddlePanel:MovePetModelToRight()
  end
end

function UMG_PetInfoMain_C:CloseWareHouseUpdate()
  Log.Error("\229\166\130\230\158\156\232\191\152\232\131\189\232\167\166\229\143\145\232\191\153\228\184\128\230\174\181\239\188\140\230\132\159\232\167\137\230\152\175\230\156\137\233\151\174\233\162\152\231\154\132\239\188\140\231\178\190\231\129\181\231\149\140\233\157\162\228\184\141\229\186\148\232\175\165\229\134\141\230\156\137\228\187\147\229\186\147\231\154\132\228\187\163\231\160\129")
  self.petLeftPanel:ClosePetToTalWareHouseUpdate()
  self.petRightPanel:OnRightPanelChange(false)
  self.PetTotalWarehouse.PetSumUp:SetPetSumUpPetNewSkill()
  self.PetTotalWarehouse:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Image_54:SetVisibility(UE4.ESlateVisibility.Visible)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SavaPetSortIndex, true, self.PetTotalWarehouse:GetSortIndex())
  self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, nil)
end

function UMG_PetInfoMain_C:getLeftPanelSubPanelIndex()
  return self.petLeftPanel:getCurSubPanelIndex()
end

function UMG_PetInfoMain_C:GetPetAttributeVisibleState()
  return self.petLeftPanel.Attribute:IsOpenDetail()
end

function UMG_PetInfoMain_C:GetPetBagVisibleState()
  return self.petLeftPanel.PetBag:IsOpenPetBag()
end

function UMG_PetInfoMain_C:GetPetBagOpenState()
  return _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetBagOpenState)
end

function UMG_PetInfoMain_C:GetAttributeOpenState()
  if UE4.UKismetSystemLibrary.IsValid(self.petLeftPanel) then
    return not self.petLeftPanel.Attribute.showing
  end
  return false
end

function UMG_PetInfoMain_C:OpenPetFormation()
  self.petLeftPanel:OpenPetFormation()
end

function UMG_PetInfoMain_C:OnSelectPetIndex(index, petInfo, needAudio, notUpdatePetMiddle)
  if not petInfo or not next(petInfo) then
    if needAudio then
    end
    self:OnSelectEmpty(index)
  else
    self:OnSelectPet(index, petInfo, needAudio, notUpdatePetMiddle)
  end
end

function UMG_PetInfoMain_C:OnSelectPet(index, petInfo, needAudio, notUpdatePetMiddle)
  self.module:SetCurrPetData(petInfo.petData)
  self.module:SetCurSelectPetGIDInPortableBag(petInfo.gid)
  if not notUpdatePetMiddle then
    self.petMiddlePanel:OnSelectPetInfoUpdate(petInfo, petInfo.petData, self.module.NotChangeAnim)
  end
  self.module.NotChangeAnim = false
  self.petLeftPanel:OnGlobalPetItemClick(index)
  self.currentSelectedPetIndex = index
  self.petInfo = petInfo
  self.currentSelectedPetGid = petInfo.gid
  self:OnSelectPetChange(petInfo.petData)
  self:UpdateTimeRewindBtnVisibility()
  self:SetTopBtnPanelVisibility(true)
  self.NeedSelectAudio = true
end

function UMG_PetInfoMain_C:OnSelectEmpty(index)
  self.module:SetCurrPetData(nil)
  self.petMiddlePanel:OnSelectEmpty()
  self.module.NotChangeAnim = false
  self.petLeftPanel:OnGlobalPetItemClick(index)
  self.currentSelectedPetIndex = nil
  self.petInfo = nil
  self.currentSelectedPetGid = nil
  self:OnSelectPetChange(nil)
  self:SetTopBtnPanelVisibility(false)
end

function UMG_PetInfoMain_C:UpdateTimeRewindBtnVisibility(bShow)
  if self.petInfo == nil then
    Log.Debug("UMG_PetInfoMain_C:UpdateTimeRewindBtnVisibility petInfo is nil")
    return
  end
  if nil == self.petInfo.petData then
    Log.Debug("UMG_PetInfoMain_C:UpdateTimeRewindBtnVisibility petData is nil")
    return
  end
  if nil == bShow then
    local bCanShow = true
    local bCanTraceBack = PetUtils.CheckPetIsCanTraceBack(self.petInfo.petData, true, true, true)
    if self.module and self.module:HasPanel("PetEvoNewPanel") then
      bCanShow = false
    end
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      bCanShow = false
    end
    self.TimeRewindBtn:SetVisibility(bCanTraceBack and bCanShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  else
    self.TimeRewindBtnBox:SetVisibility(bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:SetTopBtnPanelVisibility(Visible)
  self.TopBtnPanel:SetVisibility(Visible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetInfoMain_C:SetCurrentSelectedPetIndex(_currentSelectedPetIndex)
  self.currentSelectedPetIndex = _currentSelectedPetIndex
end

function UMG_PetInfoMain_C:UpdatePetSelect()
  if self.currentSelectedPetIndex <= 6 then
    self.petLeftPanel:OnPetItemClick(self.currentSelectedPetIndex)
  end
end

function UMG_PetInfoMain_C:NoChangePetTeamClose()
  if self.petLeftPanel and self.petLeftPanel.petBagTeamIndex and self.petLeftPanel.curTeamInfo.main_team_idx == self.petLeftPanel.petBagTeamIndex - 1 then
    local Index = self.petLeftPanel:GetPetBagValidTeamIndex()
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, Index, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
  end
  if self.module and self.module:HasPanel("PetRightPanel") then
    local PetRightPanel = self.module:GetPanel("PetRightPanel")
    PetRightPanel:OnEmptyClose()
  end
  self:ClosePetInfoMain()
end

function UMG_PetInfoMain_C:ClosePetInfoMain(bImmediately)
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(0)
  self.bImmediately = bImmediately or self.bImmediately or false
  local mappingContext = self:GetInputMappingContext("IMC_PetUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_ClosePetUI")
    mappingContext:UnBindAction("IA_ClosePetQuick")
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetBagPanel)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetSkillTipsPanel)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseRightPanel)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401010, "UMG_GameInfoMain_C:OnbtnCloseClick")
  self:SetPetNewSkillInfo()
  self:UpdateWarehouseMainInfo()
  self:UpdateMainPet()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.RefreshPetTeamPanel, self.IsPvPToPetTeam)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  if self.petMiddlePanel then
    self.petMiddlePanel:MiddlePlayCameraRegressionSequence()
  end
  if UE4.UNRCStatics.IsEditor() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.ClosePetAdjustVisualTool)
  end
  if self.bImmediately then
    self:FinishCamera()
  else
    self:PlayAnimation(self.Out)
    self:SetPanelReadyToClosed()
    if self.petMiddlePanel and self.petMiddlePanel.petImage3D then
      self.petMiddlePanel.petImage3D:HidePetBeforeCloseAnim()
    end
  end
  self.petMiddlePanel.petImage3D:StopPetAudio()
  self.ShareUIReward:CheckPlayAnimOut()
end

function UMG_PetInfoMain_C:OnReturnButtonClicked()
  if self.isEnterFree then
    if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
      self.module:SwitchReleaseLifeModeInPortableBag()
    end
    self:DispatchEvent(PetUIModuleEvent.OnNewPetBagExitFree)
    return true
  end
  if self.module:CloseNewPetBagPanel() then
    if self.petRightPanel then
      self.petRightPanel:ClosePanel()
    end
    if self.petLeftPanel then
      self.petLeftPanel:IsShowTitle(true)
    end
    return true
  end
end

function UMG_PetInfoMain_C:OnCloseButtonClicked(bImmediately)
  self.bImmediately = bImmediately
  local PetBagTeamIsValid = self.petLeftPanel:CheckCurPetBagTeamIsValid(true)
  self.module:CloseNewPetBagPanel()
  if PetBagTeamIsValid then
    if self.petLeftPanel.petBagTeamIndex and self.petLeftPanel.curTeamInfo.main_team_idx ~= self.petLeftPanel.petBagTeamIndex - 1 then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, self.petLeftPanel.petBagTeamIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
    end
  else
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.TIPS)
    Ctx:SetContent(LuaText.empty_team_exit_confirm_tip)
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    Ctx:SetCallbackOkOnly(self, self.NoChangePetTeamClose)
    Ctx:SetClickAnywhereClose(true)
    Ctx:SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    return true
  end
  _G.NRCModuleManager:DoCmd(BattleRogueModuleCmd.PetMainClose)
  self:ClosePetInfoMain(bImmediately)
  return false
end

function UMG_PetInfoMain_C:OnViewingBtnClicked()
end

function UMG_PetInfoMain_C:ShowOrHideViewingBtn(_IsShow)
  self.ViewingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetInfoMain_C:OnRecommendedBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_PetInfoMain_C:OnRecommendedBtnClicked")
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDistrictMapGuide, self.petData)
end

function UMG_PetInfoMain_C:OnTimeRewindBtnClicked()
  Log.Debug("UMG_PetInfoMain_C:OnTimeRewindBtnClicked")
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetInfoMain_C:OnTimeRewindBtnClicked")
  if self.petData and self.petData.gid then
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPetTraceBackPopup, self.petData.gid)
  end
end

function UMG_PetInfoMain_C:SetFullScreenMaskShow(bShow)
  if self.FullScreenMask == nil then
    return
  end
  if self.FullScreenCollapsedDelayId then
    _G.DelayManager:CancelDelay(self.FullScreenCollapsedDelayId)
    self.FullScreenCollapsedDelayId = nil
  end
  if bShow then
    self.FullScreenMask:SetVisibility(UE4.ESlateVisibility.Visible)
    self.FullScreenCollapsedDelayId = _G.DelayManager:DelaySeconds(FULL_SCREEN_SHOW_TIME, function()
      self:SetFullScreenMaskShow(false)
    end)
  else
    self.FullScreenMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:SetPetNewSkillInfo()
  if self.PetInfoMain == nil then
    return
  end
  local SelectPetData = self.petLeftPanel:GetSelectPet()
  local SelectMenuButtonsIndex = self.petLeftPanel:GetMenuButtonsIndex()
  if 3 == SelectMenuButtonsIndex then
    PetUtils.UpdatePetNewSkill(SelectPetData)
  end
end

function UMG_PetInfoMain_C:UpdateWarehouseMainInfo()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    return
  end
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPetData then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.UpdatePetWareHouseMainInfo)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.UpdatePVPPetInfo, openPetData)
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.UpdatePetData, openPetData)
    _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.UpdatePetData, openPetData)
  end
end

function UMG_PetInfoMain_C:UpdateMainPet()
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
end

function UMG_PetInfoMain_C:OnNewEvoPanelOpened()
  self.petMiddlePanel.petImage3D:OnNewEvoPanelOpened()
end

function UMG_PetInfoMain_C:IsFirstLoadBackground()
  return self.IsFirstLoadBg
end

function UMG_PetInfoMain_C:OnLoadBackgroundSuccess()
  if not self.IsFirstLoadBg or self.enableView then
  end
  self.IsFirstLoadBg = false
end

function UMG_PetInfoMain_C:OnNewEvoPanelClosed(bSucc)
  if bSucc then
  end
  self.petMiddlePanel.petImage3D:OnNewEvoPanelClosed(bSucc)
  self:ShowOrHideViewingBtn(true)
end

function UMG_PetInfoMain_C:OnNewEvoPanelDestruct()
  self.petMiddlePanel.petImage3D:OnNewEvoPanelDestruct()
end

function UMG_PetInfoMain_C:OnClickStartEvo()
  self.petMiddlePanel.petImage3D:StartEvolution()
end

function UMG_PetInfoMain_C:HideLeftPanel(isHide)
  self.petLeftPanel:SetVisibility(isHide and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetInfoMain_C:FinishCamera()
  local PetUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule:HasPanel("PetInfoMain") then
    local openPetData, index, isRevertPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
    local bInBattle = _G.BattleManager.isInBattle
    local bHasCompass = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.HasCompass)
    local IsCultivatePet = _G.NRCModuleManager:DoCmd(CampingModuleCmd.GetIsCultivatePet)
    Log.Debug(isRevertPanel, bHasCompass, IsCultivatePet, "UMG_PetInfoMain_C:FinishCamera")
    if true == isRevertPanel and not bInBattle then
      if bHasCompass or IsCultivatePet then
      else
        if self.localPlayer and self.data:GetEnterPetPanelType() ~= PetUIModuleEnum.EnterType.PetAltar then
          self.localPlayer.inputComponent:SetInputEnable(self, true)
        else
        end
      end
    else
      if IsCultivatePet and self.localPlayer and self.data:GetEnterPetPanelType() ~= PetUIModuleEnum.EnterType.PetAltar then
        self.localPlayer.inputComponent:SetInputEnable(self, true)
      end
      isRevertPanel = true
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, openPetData, index, isRevertPanel)
    end
    self.data:SetEnterPetPanelType(nil)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.RefreshPetTeamPanel)
    self:DoClose()
  end
end

function UMG_PetInfoMain_C:OnSwitchCloseBtnState(_State)
  if 0 == _State then
    self.UMG_btnClose.NRCSwitcher_1:SetActiveWidgetIndex(_State)
  else
    self.UMG_btnClose.NRCSwitcher_1:SetActiveWidgetIndex(_State)
  end
end

function UMG_PetInfoMain_C:GetPetHeadSlotScreenPos()
  return self.petMiddlePanel.petImage3D:GetPetHeadSlotScreenPos()
end

function UMG_PetInfoMain_C:GetOpenTwoPanelLevelSequenceIsLoad()
  return self.petMiddlePanel.petImage3D:GetOpenTwoPanelLevelSequence()
end

function UMG_PetInfoMain_C:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PET)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PETITEM)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").NEWPET)
end

function UMG_PetInfoMain_C:SelectShareType(index)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetInfoMain_C:SelectShareType")
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if not isBan then
    if not self.CanListenShareType then
      return
    end
    self.CanListenShareType = false
    self.ShareIndex = index
    local itemData = self.ComboBox_Popup.List_title:GetDataByIndex(index)
    if itemData then
      local data = {
        shareBaseId = self.shareBaseId,
        sharePartId = itemData.SharePartId,
        petData = self.petData
      }
      if itemData.SharePartId == _G.Enum.ShareButtonType.SBT_PET_VIDEO then
        if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_video_on_pc_tip)
        else
          _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.SetIsSharingPetVideo, true)
          _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenShareOverlayPanel, data)
        end
      else
        _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, data)
      end
    end
  end
  self:ResetShareComboBox()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetPetRightPanelShareComboBox)
end

function UMG_PetInfoMain_C:ResetCanListenShareType()
  self.CanListenShareType = true
end

function UMG_PetInfoMain_C:PlayShareVideoG6()
  local skillPath = "/Game/ArtRes/Effects/G6Skill/UI/G6_UI_Share.G6_UI_Share"
  local skillClass = UE4.UClass.Load(skillPath)
  
  local function endCb()
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PlayShareCameraPanelCloseAnim)
  end
  
  self.petMiddlePanel.petImage3D:PlaySharePetSkill(skillClass, endCb)
end

function UMG_PetInfoMain_C:OnShareClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if isBan then
    return
  end
  if not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCanSharePet) then
    return
  end
  if self:GetAttributeOpenState() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetInfoMain_C:OnShareClick")
  if self.IsShowShareBox then
    self.IsShowShareBox = false
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.IsShowShareBox = true
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Visible)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetCanListenShareType)
    self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetInfoMain_C:OnShareMaskBtn()
  if self.IsShowShareBox then
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsShowShareBox = false
  end
  self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetInfoMain_C:ResetShareComboBox()
  self.IsShowShareBox = false
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetInfoMain_C:EnablePlayBgm(enable)
  if enable then
    _G.NRCAudioManager:SetStateByName("Pet_Show", "None")
  else
    _G.NRCAudioManager:SetStateByName("Pet_Show", "Show")
  end
end

function UMG_PetInfoMain_C:DealVideoShareData()
  local scale, offset, rotate
  local scaleConf = _G.DataConfigManager:GetGlobalConfig("share_video_zoom")
  if scaleConf and scaleConf.str then
    scale = tonumber(scaleConf.str)
  end
  local offsetConf = _G.DataConfigManager:GetGlobalConfig("share_video_move")
  if offsetConf and offsetConf.numList then
    offset = UE4.FVector(offsetConf.numList[1], offsetConf.numList[2], offsetConf.numList[3])
  end
  local rotateConf = _G.DataConfigManager:GetGlobalConfig("share_videp_rotation")
  if rotateConf and rotateConf.numList then
    rotate = UE4.FRotator(rotateConf.numList[1], rotateConf.numList[2], rotateConf.numList[3])
  end
  local petShareData = {
    scale = scale,
    offset = offset,
    rotate = rotate
  }
  self.petMiddlePanel.petImage3D:SavePetModeDataCache()
  self.petMiddlePanel.petImage3D:SetPetModeByShareData(petShareData)
end

function UMG_PetInfoMain_C:EnterEggPanelHideComponents()
  local eggInfo
  local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
  for i = 1, #backpackEggList do
    if backpackEggList[i].gid == self.module.curEggGid then
      eggInfo = backpackEggList[i]
    end
  end
  if eggInfo then
    self.petMiddlePanel:initEggModelInfo(eggInfo)
  end
  self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ShowOrHideCloseBtn(false)
  self:OnShowHideRecommendedBtn(false)
  self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:UpdateTimeRewindBtnVisibility(false)
end

function UMG_PetInfoMain_C:ExitEggPanelHideComponents()
  self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ShowOrHideCloseBtn(true)
  self:OnShowHideRecommendedBtn(true)
  self:UpdateTimeRewindBtnVisibility(true)
  if self.ShareIsOpen then
    if self.petData and self.petData.gid then
      local isHidden = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, self.petData.gid)
      if isHidden then
        self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self:ShowShareBtn()
      end
    else
      self:ShowShareBtn()
    end
  end
  if not self.petMiddlePanel.petImage3D.IsOnActive and self.petLeftPanel.petList and #self.petLeftPanel.petList > 0 then
    local firstPetData = self.petLeftPanel.petList[1]
    local petbaseConf = _G.DataConfigManager:GetPetbaseConf(firstPetData.base_conf_id)
    local moduleConf = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf)
    self.petMiddlePanel.petImage3D:OnActive(petbaseConf, "PetInfoMain", moduleConf.path)
  end
end

function UMG_PetInfoMain_C:OnCloseEggClick()
  self:ExitEggPanelHideComponents()
end

function UMG_PetInfoMain_C:ShowHideGiftColleaguesBtn(bShow)
  if bShow then
    self:CheckCanSendToFriend()
  else
    self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:ShowHideTimeRewindBtn(bShow)
  self:UpdateTimeRewindBtnVisibility(bShow)
end

function UMG_PetInfoMain_C:CloseSwitchButton(isDisable)
  self.BtnReturn.btnClose:SetIsEnabled(not isDisable)
  self:UpdateTimeRewindBtnVisibility()
end

function UMG_PetInfoMain_C:CheckEnterType()
  local enterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  if enterType == PetUIModuleEnum.EnterType.PetInheritance then
    self:SetTopBtnPanelVisibility(false)
  end
end

function UMG_PetInfoMain_C:OpenLeaderItemPanel(Open)
  if Open then
    self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ViewingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TimeRewindBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:OnShowHideRecommendedBtn(true)
    self:ShowOrHideShareBtn()
    self:ShowOrHideViewingBtn(true)
    self.petLeftPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SelectPetInfoMainPet()
  end
  self:ShowOrHideCloseBtn(not Open)
  self:ShowHideGiftColleaguesBtn(not Open)
end

function UMG_PetInfoMain_C:SelectPetInfoMainPet()
  self:OnSelectPetIndex(self.currentSelectedPetIndex, self.petInfo)
end

function UMG_PetInfoMain_C:ShowOrHideShareBtn()
  if self.ShareIsOpen then
    if self.petData and self.petData.gid then
      local isHidden = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, self.petData.gid)
      if isHidden then
        self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
        if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
          self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self:ShowShareBtn()
        end
      end
    else
      self:ShowShareBtn()
    end
  end
end

function UMG_PetInfoMain_C:InitComboBox()
  self.IsShowShareBox = false
  local selectList = {}
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(_G.Enum.ShareButtonType.SBT_PET)
  if shareBaseConf and shareBaseConf.base_id and #shareBaseConf.base_id > 1 then
    for index, v in ipairs(shareBaseConf.base_id) do
      local channelBanId = shareBaseConf.system_control_limit[index + 1]
      local isBan = false
      if channelBanId and not _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckShareChannelIsOpen, channelBanId) then
        isBan = true
      end
      if not isBan then
        local sharePartConf = _G.DataConfigManager:GetSharePartConf(v)
        if sharePartConf then
          local selectData = {
            name = sharePartConf.tab_name,
            isHideRedDot = true,
            isNotChangColor = true,
            ComType = CommonBtnEnum.ComboBoxType.PetShare,
            SharePartId = v
          }
          table.insert(selectList, selectData)
        end
      end
    end
  end
  if RocoEnv.IS_EDITOR or RocoEnv.PLATFORM_WINDOWS or RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
    self.ComboBox_Popup.List_title:InitList(selectList)
  end
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ShareIndex = 1
end

function UMG_PetInfoMain_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = true
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PetInfoMain_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PetInfoMain_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_PET
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  self:ShowShareBtn()
end

function UMG_PetInfoMain_C:ShowShareBtn()
  if self.ShareIsOpen then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetInfoMain_C:ShowOrHideCloseBtn(bShow)
  local bOpenEvoPanel = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsOpenEvoPanel)
  if bShow and not bOpenEvoPanel then
    self.UMG_btnClose:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetInfoMain_C
