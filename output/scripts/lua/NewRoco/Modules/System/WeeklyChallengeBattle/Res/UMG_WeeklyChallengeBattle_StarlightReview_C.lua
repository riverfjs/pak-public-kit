local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local JsonUtils = require("Common.JsonUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_WeeklyChallengeBattle_StarlightReview_C = _G.NRCPanelBase:Extend("UMG_WeeklyChallengeBattle_StarlightReview_C")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local _isDraging = false
local _isTouched = false
local _startPostion = UE4.FVector2D(0, 0)
local _slotId = 0
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local WeeklyChallengeBattleModuleEnum = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEnum")
UMG_WeeklyChallengeBattle_StarlightReview_C.PanelType = {
  MainPanel = 0,
  ChangeHistoryTeamPanel = 1,
  TeamPanel = 2,
  ShootPanel = 3,
  EditLocationPanel = 4,
  ChangeCurrTeamPanel = 5,
  HistoryTeam = 6,
  EditLocation_History = 7,
  Shoot_History = 8
}

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnConstruct()
  self:SetChildViews(self.UMG_StarLightWorldView, self.UMG_StarLightPhoto)
  self.UMG_StarLightWorldView:SetParent(self)
  self.startPos = UE4.FVector2D(0, 0)
  self.currTeamIndex = 0
  self.MaxCurrTeamIndex = 0
  self.historyTeamIndex = 0
  self.MaxHistoryTeamIndex = 0
  self.DelayTakePhotoTime = DataConfigManager:GetChallengeGlobalConf(2).num + 1
  self.petVolume = {}
  self.npcAction = nil
  self.fold = false
  self.fold_history = false
  self.TotalTime = 0
  self.bIsEventOOD = false
  self:_InitDataStructure()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.TryClearBgm)
  if self.npcAction and self.npcAction.Finish then
    self.npcAction:Finish()
    self.npcAction = nil
  end
  if self.comboBoxDelayId then
    _G.DelayManager:CancelDelayById(self.comboBoxDelayId)
    self.comboBoxDelayId = nil
  end
  self:ClearCurtainTimeoutProtection()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnPcClose()
  if self.currentOpenPanelType == UMG_WeeklyChallengeBattle_StarlightReview_C.PanelType.MainPanel then
    self:ClosePanel()
  elseif self.currentOpenPanelType == UMG_WeeklyChallengeBattle_StarlightReview_C.PanelType.ChangeHistoryTeamPanel and self.notHasHistoryData == true then
    self:SwitchToMainPanel()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnActive(npcAction, panelType, NeedOpenReward)
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.CloseLoadingCurtainEvent, panelType == self.PanelType.ShootPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetCanClearBgm, true)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.TrySetBgmToTheater)
  self:OnAddEventListener()
  self:_PrefetchResetState()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.QueryAllUsablePetBalancedData)
  if npcAction then
    self.npcAction = npcAction
  end
  self.currentOpenPanelType = -1
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    self.activityId = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
    local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
    if not weekly_challenge_data then
      Log.Error("UMG_FirstReleasePanel_C:OnStartShowButtonClick \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
      return
    end
    self.historyPetTeamData = {}
    self.challengeId = weekly_challenge_data.challenge_info.challenge_id
    self.challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  else
    self.challengeId = 1000
  end
  self:_InitRewardButton()
  self:_InitTime()
  self:InitPhotoData()
  self:InitUI()
  if panelType == self.PanelType.ShootPanel then
    self.goToShootAtFirst = true
    self.goToShoot = true
    self.UMG_StarLightWorldView:LoadFileFromJson(self.CurrJsonPath)
    if not self.currPetTeams then
      Log.Error("\231\188\186\229\164\177\231\188\150\233\152\159\230\149\176\230\141\174\229\141\180\230\131\179\232\166\129\230\137\147\229\188\128\230\139\141\231\133\167\231\149\140\233\157\162\239\188\140\228\184\141\231\172\166\229\144\136\230\173\163\229\184\184\233\128\187\232\190\145\239\188\140\232\139\165\229\135\186\231\142\176\232\175\183\232\129\148\231\179\187jobhuang\229\185\182\229\145\138\231\159\165\230\152\175\230\128\142\228\185\136\229\135\186\231\142\176\231\154\132")
    end
    self.currTeamIndex = #self.currPetTeams
    self:UpdateCurrTeamData()
    self.BtnPhotograph:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.currPetTeams then
    self.currTeamIndex = #self.currPetTeams
  end
  self:SwitchToPanel(panelType, true)
  if NeedOpenReward then
    self:OnRewardClaimButtonClick()
  end
  if _G.EnableSpeedUpWeekChallengeBattle then
    _G.BattleManager.battleRuntimeData:LoadWeekChallengeLevelStream()
  end
  self.InitOpenCurtain = true
  self:StartCurtainTimeoutProtection()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_InitDataStructure()
  self.typePanelMap = {
    [self.PanelType.MainPanel] = self.GroupPhotoPanel,
    [self.PanelType.ChangeHistoryTeamPanel] = self.ChangeHistoryTeamPanel,
    [self.PanelType.TeamPanel] = self.Team,
    [self.PanelType.ShootPanel] = self.Shoot,
    [self.PanelType.EditLocationPanel] = self.EditLocation,
    [self.PanelType.ChangeCurrTeamPanel] = self.ChangeCurrTeamPanel,
    [self.PanelType.HistoryTeam] = self.HistoryTeam,
    [self.PanelType.EditLocation_History] = self.EditLocation_History,
    [self.PanelType.Shoot_History] = self.Shoot_History
  }
  self.typePanelEnterAnimMap = {
    [self.PanelType.MainPanel] = self.GroupPhoto_IN,
    [self.PanelType.ChangeHistoryTeamPanel] = self.In,
    [self.PanelType.TeamPanel] = self.TeamList_in,
    [self.PanelType.ShootPanel] = nil,
    [self.PanelType.EditLocationPanel] = self.EditLocation_Curr_In,
    [self.PanelType.ChangeCurrTeamPanel] = self.In_curr,
    [self.PanelType.HistoryTeam] = self.TeamList_in_history,
    [self.PanelType.EditLocation_History] = self.EditLocation_Curr_In_history,
    [self.PanelType.Shoot_History] = nil
  }
  self.typePanelExitAnimMap = {
    [self.PanelType.MainPanel] = self.GroupPhoto_Out,
    [self.PanelType.ChangeHistoryTeamPanel] = self.Out,
    [self.PanelType.TeamPanel] = self.TeamList_out,
    [self.PanelType.ShootPanel] = nil,
    [self.PanelType.EditLocationPanel] = self.EditLocation_Curr_out,
    [self.PanelType.ChangeCurrTeamPanel] = self.Out_curr,
    [self.PanelType.HistoryTeam] = self.TeamList_out_history,
    [self.PanelType.EditLocation_History] = self.EditLocation_Curr_out_history,
    [self.PanelType.Shoot_History] = nil
  }
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitUI()
  self:UpdateCurrTeamBtn()
  self:UpdateHistoryTeamBtn()
  self:_InitEventBackground()
  self:_InitToShootDirectlyBtn()
  if self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    local activityId = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
    self.RedDot_2:SetupKey(371, activityId)
    self.RedDot_1:SetupKey(371, activityId)
  end
  self.NRCText_2:SetText(_G.LuaText.weekly_challenge_text_13)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_InitToShootDirectlyBtn()
  if self.BtnGoPhoto then
    local bIsPhotoRewardUnlocked = self:_IsPhotoRewardUnlocked()
    if self.currPetTeams and #self.currPetTeams > 0 and bIsPhotoRewardUnlocked then
      self.BtnGoPhoto:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.BtnGoPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_IsPhotoRewardUnlocked()
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  if not rewardList or 0 == #rewardList then
    return false
  end
  for _, reward in ipairs(rewardList) do
    if reward.bIsTakingPhoto then
      if reward.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT or reward.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE or reward.finishedStarNum and reward.star_required_num and reward.finishedStarNum >= reward.star_required_num then
        return true
      end
      return false
    end
  end
  return false
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateMainPanelPhotoUI()
  if self.currPhotoTeamData then
    self.petFullIDData = self:GetPetFullIDDataFromPhotoData(self.currPhotoTeamData.photo)
    local animPercentList = self.currPhotoTeamData.photo.anime_percent
    self.UMG_StarLightWorldView:UpdateAnimPercentList(animPercentList)
    local fashionItems = self.currPhotoTeamData.wearing_item
    local salon_item_data = self.currPhotoTeamData.salon_item_data
    self:UpdateSubPanelPetModel(self.CurrJsonPath, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent)
    self.UMG_StarLightWorldView:LoadPlayerAndAnimRes(fashionItems, salon_item_data)
  else
    self:LoadNPCPetTeams()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitPhotoData()
  if self.challenge_data then
    self.currPetTeams = self.challenge_data.pet_teams
    if self.currPetTeams then
      self.MaxCurrTeamIndex = #self.currPetTeams
    end
    self.currPhotoTeamData = self.challenge_data.team_photo
    if self.currPhotoTeamData then
      self.coverPhotoTeamID = self.currPhotoTeamData.team_id
    end
  end
  self:SendGetHistoryDataReq()
  if not self.currPhotoTeamData then
  end
  if self.currPhotoTeamData then
    self.petFullIDData = self:GetPetFullIDDataFromPhotoData(self.currPhotoTeamData.photo)
    self.photo_template_id = self.currPhotoTeamData.photo.photo_template_id
    self.CurrJsonPath = self:GetJsonNameFromID(self.photo_template_id)
  else
    local challengeConf = DataConfigManager:GetWeeklyChallengeConf(self.challengeId)
    if challengeConf then
      self.battleID = challengeConf.battle
      self.photo_template_id = challengeConf.photo
      self.CurrJsonPath = self:GetJsonNameFromID(self.photo_template_id)
    end
  end
  self:_InitToShootDirectlyBtn()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:SendGetHistoryDataReq()
  local req = ProtoMessage:newZoneWeeklyChallengeHistoryPhotoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_HISTORY_PHOTO_REQ, req, self, self.InitHistoryTeamData, false, false)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:GetPetFullIDDataFromTeamData(teamData)
  if not teamData then
    return nil
  end
  local petFullIDData = {}
  for i, petID in ipairs(teamData.pet_conf_id) do
    petFullIDData[i] = {}
    petFullIDData[i].petID = petID
    if teamData.pet_gid[i] then
      petFullIDData[i].petGID = teamData.pet_gid[i]
    end
  end
  return petFullIDData
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:GetPetFullIDDataFromPhotoData(photoData)
  if not photoData then
    return nil
  end
  local petFullIDData = {}
  for i, petID in ipairs(photoData.pet_conf_id) do
    petFullIDData[i] = {}
    petFullIDData[i].petID = petID
    if photoData.pet_gid[i] then
      petFullIDData[i].petGID = photoData.pet_gid[i]
    end
  end
  return petFullIDData
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnDeactive()
  if _G.EnableSpeedUpWeekChallengeBattle and not self.isStartChallenge then
    _G.BattleManager.battleRuntimeData:CancelLevelStream()
  end
  self:ClearCurtainTimeoutProtection()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.ChangeHistoryTeamUsePhotoData, self.ChangeHistoryTeamUsePhotoData)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.ChangeCurrTeamUseTeamData, self.ChangeCurrTeamUseTeamData)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.ChangeCurrTeamUsePhotoData, self.ChangeCurrTeamUsePhotoData)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.ReleaseStarLightDragItemPlayAnim, self.ReleaseStarLightDragItemPlayAnim)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ReleaseStarLightDragItem, self.ReleaseStarLightDragItem)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.StartDragStarLightPet, self.StartDragStarLightPet)
  NRCEventCenter:UnRegisterEvent(self, TakePhotosModuleEvent.OnPhotoPanelClose, self.OnPhotoPanelClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnComboBoxSelectChanged, self.OnDateComboBoxSelectChanged)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnStarlightShowdownPanelClose)
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnectStart)
  if self.DragItemInstance then
    self.DragItemInstance:RemoveFromParent()
  end
  if self.npcAction and self.npcAction.Finish then
    self.npcAction:Finish()
    self.npcAction = nil
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose_3.btnClose, self.ClosePanel)
  self:AddButtonListener(self.btnClose_2.btnClose, self.OnExitTeamPanelButtonClick)
  self:AddButtonListener(self.btnCloseTeam, self.OnExitTeamPanelButtonClick)
  self:AddButtonListener(self.UMG_StarLightPhoto.CloseBtn.btnClose, self.SwitchToMainPanel)
  self:AddButtonListener(self.btnClose_7.btnClose, self.SwitchToMainPanel)
  self:AddButtonListener(self.btnClose_5.btnClose, self.SwitchToMainPanel)
  self:AddButtonListener(self.Close.btnClose, self.OnExitEditLocationClick)
  self:AddButtonListener(self.Close_1.btnClose, self.OnExitHistoryEditLocationClick)
  self:AddButtonListener(self.Btn_Cover.btnLevelUp, self.OnCoverSet)
  self:AddButtonListener(self.btnClose_4.btnClose, self.OnExitHistoryPanel)
  self:AddButtonListener(self.btnCloseTeam_1, self.OnExitHistoryPanel)
  NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, PetUIModuleEvent.ReleaseStarLightDragItem, self.ReleaseStarLightDragItem)
  NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, PetUIModuleEvent.StartDragStarLightPet, self.StartDragStarLightPet)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, WeeklyChallengeBattleModuleEvent.ChangeCurrTeamUseTeamData, self.ChangeCurrTeamUseTeamData)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, WeeklyChallengeBattleModuleEvent.ChangeCurrTeamUsePhotoData, self.ChangeCurrTeamUsePhotoData)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, WeeklyChallengeBattleModuleEvent.ChangeHistoryTeamUsePhotoData, self.ChangeHistoryTeamUsePhotoData)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, WeeklyChallengeBattleModuleEvent.ReleaseStarLightDragItemPlayAnim, self.ReleaseStarLightDragItemPlayAnim)
  NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, TakePhotosModuleEvent.OnPhotoPanelClose, self.OnPhotoPanelClose)
  self:AddButtonListener(self.btnClose.btnClose, self.OnExitShootPanelButtonClick)
  self:AddButtonListener(self.btnClose_6.btnClose, self.OnExitHistoryShootPanelButtonClick)
  self:AddButtonListener(self.StartTheShow_1.btnLevelUp, self.OnStartShowButtonClick)
  self:AddButtonListener(self.RewardBtn_2, self.OnRewardClaimButtonClick)
  self:AddButtonListener(self.ParticularsBtn_1.btnLevelUp, self.OnDetailButtonClick)
  self:AddButtonListener(self.StarlightReviewBtn_1.btnLevelUp, self.OnEnterRetroPanelButtonClick)
  self:AddButtonListener(self.PreviousTeamsBtn.btnLevelUp, self.OnEnterHistoryTeamPanelButtonClick)
  self:AddButtonListener(self.PreviousTeamsBtn_1.btnLevelUp, self.OnEnterCurrTeamPanelButtonClick)
  if self.UMG_StarLightPhoto then
    self:AddButtonListener(self.UMG_StarLightPhoto.Btn_ArrowL_1.btnLevelUp, self.TurnHistoryTeamLeftPage)
    self:AddButtonListener(self.UMG_StarLightPhoto.Btn_ArrowR_1.btnLevelUp, self.TurnHistoryTeamRightPage)
  end
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.TurnCurrTeamLeftPage)
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.TurnCurrTeamRightPage)
  self:AddButtonListener(self.Btn_GoPhotograph.btnLevelUp, self.ChangeToTakePhoto)
  self:AddButtonListener(self.EditLocationBtn, self.ChangeToEditPosPanel)
  self:AddButtonListener(self.EditLocationBtn_1, self.ChangeToEditHistoryPosPanel)
  self:AddButtonListener(self.BtnPhotograph.btnLevelUp, self.TakePhoto)
  self:AddButtonListener(self.BtnPhotograph_1.btnLevelUp, self.TakePhoto)
  self:AddButtonListener(self.NRCButton_77, self.PlayAdjustUIFold)
  self:AddButtonListener(self.NRCButton, self.PlayAdjustUIFold2)
  self:AddButtonListener(self.Close.btnClose, self.OnExitCurrTeamEditPanel)
  self:AddButtonListener(self.UMG_StarLightPhoto.Btn_GoPhotograph.btnLevelUp, self.ChangeToTakePhotoHistory)
  self:AddButtonListener(self.RewardBtn_1, self.OnRewardClaimButtonClick)
  self:AddButtonListener(self.ResetBtn_1, self.OnResetButtonClick)
  if self.BtnGoPhoto then
    self:AddButtonListener(self.BtnGoPhoto.btnLevelUp, self.OnToShootDirectlyBtnClick)
  end
  if self.UMG_StarLightPhoto and self.UMG_StarLightPhoto.Date_ComboBox then
    _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, _G.NRCGlobalEvent.OnComboBoxSelectChanged, self.OnDateComboBoxSelectChanged)
  end
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnStarlightShowdownPanelClose, self.OnStarlightShowdownPanelClose)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged, self.OnActivityEventIdChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_StarlightReview_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnectStart)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnActivityEventIdChanged()
  self.bIsEventOOD = true
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnReConnectStart()
  self:DoClose()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ClosePanel()
  self.bIsExitPanel = true
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_WeeklyChallengeBattle_StarlightReview_C:ClosePanel")
  self:PlayAnimation(self.GroupPhoto_Out)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitCurrTeamEditPanel()
  self:SwitchToPanel(self.PanelType.ChangeCurrTeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitTeamPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitTeamPanelButtonClick")
  self:SwitchToPanel(self.PanelType.ChangeCurrTeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:StartDragStarLightPet(ItemUiData, itemIndex)
  self.DragData = ItemUiData
  self.itemIndex = itemIndex
  self:OnInitDragItem()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnInitDragItem()
  if not self.DragItemInstance and self.startPos then
    self.DragItemInstance = UE4.UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), self.DragItem)
    if self.DragItemInstance then
      self.DragItemInstance:AddToViewport(_G.UILayerCtrlCenter.ENUM_LAYER.TOP_MSG, false)
      self.DragItemInstance:SetAlignmentInViewport(UE4.FVector2D(0.5, 0.5))
      self:ShowDragItemStartPos()
    end
  elseif self.DragItemInstance then
    self:ShowDragItemStartPos()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ReleaseStarLightDragItem(itemData, newItemIndex)
  if not self.itemIndex then
    return
  end
  if self.itemIndex and self.itemIndex == newItemIndex then
    return
  end
  if not self.UMG_StarLightWorldView.petDataInfoList[self.itemIndex] then
    self.UMG_StarLightWorldView.petDataInfoList[self.itemIndex] = {}
  end
  if not self.UMG_StarLightWorldView.petDataInfoList[newItemIndex] then
    self.UMG_StarLightWorldView.petDataInfoList[newItemIndex] = {}
  end
  self:ReleaseStarLightDragItemPlayAnim()
  if self.currentOpenPanelType == self.PanelType.EditLocationPanel then
    local tempData = self.petFullIDData[self.itemIndex]
    self.petFullIDData[self.itemIndex] = itemData
    self.petFullIDData[newItemIndex] = tempData
    local ShowSkillPetIndexList = {
      newItemIndex,
      self.itemIndex
    }
    self:UpdateSubPanelPetModel(nil, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtFirstFrame, ShowSkillPetIndexList)
    self.OpponentLineUp:InitGridView(self.petFullIDData)
  elseif self.currentOpenPanelType == self.PanelType.EditLocation_History then
    local tempData = self.petFullIDData[self.itemIndex]
    self.petFullIDData[self.itemIndex] = itemData
    self.petFullIDData[newItemIndex] = tempData
    local ShowSkillPetIndexList = {
      newItemIndex,
      self.itemIndex
    }
    self:UpdateSubPanelPetModel(nil, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtFirstFrame, ShowSkillPetIndexList)
    self.OpponentLineUp_1:InitGridView(self.petFullIDData)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ReleaseStarLightDragItemPlayAnim(itemIndex)
  local index = self.itemIndex or itemIndex
  if not self.itemIndex and not itemIndex then
    return
  end
  local PetNumberUIItem = self.UMG_StarLightWorldView:GetCurrModePetNumberUIItem(index)
  PetNumberUIItem:StopAllAnimations()
  PetNumberUIItem:PlayAnimation(PetNumberUIItem.unselect)
  if self.DragItemInstance:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  if self.currentOpenPanelType == self.PanelType.EditLocationPanel then
    local originItem = self.OpponentLineUp:GetItemByIndex(index - 1)
    originItem:PlayAnimation(originItem.unselect)
    originItem.TeamSequenceNumber:StopAllAnimations()
    originItem.TeamSequenceNumber:PlayAnimation(originItem.TeamSequenceNumber.unselect)
  elseif self.currentOpenPanelType == self.PanelType.EditLocation_History then
    local originItem = self.OpponentLineUp_1:GetItemByIndex(index - 1)
    originItem:PlayAnimation(originItem.unselect)
    originItem.TeamSequenceNumber:PlayAnimation(originItem.TeamSequenceNumber.unselect)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  if self.DragItemInstance then
    self:ReleaseStarLightDragItemPlayAnim()
    self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:EndDragUpdateUI()
    self.itemIndex = nil
  end
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ShowDragItemStartPos()
  if self.DragItemInstance then
    if RocoEnv.PLATFORM_WINDOWS then
      local mousePos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
      self.DragItemInstance:SetPositionInViewport(mousePos, false)
    else
      self.DragItemInstance:SetPositionInViewport(self.startPos, true)
    end
  end
  if self.DragData then
    self.DragItemInstance:AsDragItemInitInfo(self.DragData, self.itemIndex)
  end
  self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnRocoTouchMoveHandler(touchIndex, position)
  local ViewportPos = UE4.FVector2D()
  if self.DragItemInstance then
    if RocoEnv.PLATFORM_WINDOWS then
      local mousePos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
      self.DragItemInstance:SetPositionInViewport(mousePos, false)
    else
      self.DragItemInstance:SetPositionInViewport(position, true)
    end
    self:StartDragUpdateUI()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnRocoTouchStartHandler(touchIndex, position)
  self.startPos.X = position.X
  self.startPos.Y = position.Y
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:SwitchToMainPanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_WeeklyChallengeBattle_StarlightReview_C:SwitchToMainPanel")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.AterPlayToMainPanelAnim)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:AterPlayToMainPanelAnim()
  self:SwitchToPanel(self.PanelType.MainPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitEditLocationClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitEditLocationClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.ExitEditLocationClick)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ExitEditLocationClick()
  self:SwitchToPanel(self.PanelType.ShootPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryEditLocationClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryEditLocationClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.ExitHistoryEditLocationClick)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ExitHistoryEditLocationClick()
  self:SwitchToPanel(self.PanelType.Shoot_History)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitShootPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitShootPanelButtonClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.ExitShootPanelButtonClick)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ExitShootPanelButtonClick()
  self:SwitchToPanel(self.PanelType.ChangeCurrTeamPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryShootPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryShootPanelButtonClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.ExitHistoryShootPlayAnim)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ExitHistoryShootPlayAnim()
  self:SwitchToPanel(self.PanelType.ChangeHistoryTeamPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterRetroPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterRetroPanelButtonClick")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.PlayEnterChangeHistoryAnimEnd)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:PlayEnterChangeHistoryAnimEnd()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
  self:SwitchToPanel(self.PanelType.ChangeHistoryTeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterCurrTeamPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterCurrTeamPanelButtonClick")
  self:SwitchToPanel(self.PanelType.TeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterHistoryTeamPanelButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnEnterHistoryTeamPanelButtonClick")
  self:SwitchToPanel(self.PanelType.HistoryTeam)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnStartShowButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnStartShowButtonClick")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  self.isStartChallenge = true
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RefreshAllUsablePetBalancedData)
  Log.Info("UMG_WeeklyChallengeBattle_StarlightReview_C:OnStartShowButtonClick Refreshing pet balanced data asynchronously")
  self:_DoOpenStarlightShowdownPanel()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_DoOpenStarlightShowdownPanel()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.OpenStarlightShowdownPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnStarlightShowdownPanelClose()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
  self:SwitchToPanel(self.PanelType.MainPanel, true)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnRewardClaimButtonClick()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenRewardClaimPopupPanel, rewardList, true)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnResetButtonClick()
  self:PlayAnimation(self.Press)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FormationPanel_C:OnClickResetButton")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return
  end
  local eventConf
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if weekly_challenge_data then
    eventConf = _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  end
  if not eventConf then
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(eventConf.challenge_id[1])
  if not challengeConf then
    return
  end
  local _, level, grow, workHard = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenResetNotification, bIsNeedBalance, grow, level, workHard)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnDetailButtonClick()
  local titleText = _G.LuaText.weekly_challenge_text_10
  local contentStr = _G.LuaText.weekly_challenge_text_9
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_FinishSwitchingPanel()
  if not self.ChangeHistoryTeamPanel then
    Log.Error("ChangeHistoryTeamPanel is nil\239\188\140\232\175\183\229\145\138\231\159\165jobhuang\230\152\175\230\128\142\228\185\136\229\135\186\231\142\176\231\154\132")
  else
    self.ChangeHistoryTeamPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Team:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HistoryTeam:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Shoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.EditLocation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.GroupPhotoPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChangeCurrTeamPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Shoot_History:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.EditLocation_History:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local panel
  if self.typePanelMap then
    panel = self.typePanelMap[self.currentOpenPanelType]
  else
    return
  end
  if panel then
    panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:_PlayPageEnterAnimation(self.currentOpenPanelType)
  if self.currentOpenPanelType == self.PanelType.ShootPanel or self.currentOpenPanelType == self.PanelType.Shoot_History then
    self.UMG_StarLightWorldView:PlayCurtainAnim()
  else
    self.UMG_StarLightWorldView:StopCurtainAnim()
  end
  if self.currentOpenPanelType == self.PanelType.ChangeCurrTeamPanel then
    self:UpdateCurrTeamData()
    self.Title1.Subtitle:SetText(LuaText.weekly_challenge_topic_6)
  elseif self.currentOpenPanelType == self.PanelType.MainPanel then
    self.Title1.Subtitle:SetText(LuaText.weekly_challenge_topic_1)
  elseif self.currentOpenPanelType == self.PanelType.ChangeHistoryTeamPanel then
    if 0 == self.historyTeamIndex then
      self.historyTeamIndex = 1
    end
    self.DefaultTeam_1:SelectItemByIndex(self.historyTeamIndex - 1)
    self.Title1.Subtitle:SetText(LuaText.weekly_challenge_topic_2)
  elseif self.currentOpenPanelType == self.PanelType.ShootPanel then
    local currTeamData = self.currPetTeams[self.currTeamIndex]
    local fashionitems = currTeamData and currTeamData.wearing_item
    local salon_item_data = currTeamData and currTeamData.salon_item_data
    self.UMG_StarLightWorldView:LoadPlayerAndAnimRes(fashionitems, salon_item_data)
    self.UMG_StarLightWorldView:PlayAllPetAnimInFirstFrame()
    self.Title1.Subtitle:SetText(LuaText.weekly_challenge_topic_5)
    self.UMG_StarLightWorldView:HideCaptureImage()
  elseif self.currentOpenPanelType == self.PanelType.EditLocationPanel then
    self.fold = false
    self.UMG_StarLightWorldView:StopAllPetAnimInFirstFrame()
    panel:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.currentOpenPanelType == self.PanelType.Shoot_History then
    self.UMG_StarLightWorldView:PlayAllPetAnimInFirstFrame()
    self.UMG_StarLightWorldView:HideCaptureImage()
  elseif self.currentOpenPanelType == self.PanelType.EditLocation_History then
    self.fold_history = false
    self.UMG_StarLightWorldView:StopAllPetAnimInFirstFrame()
    panel:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.currentOpenPanelType == self.PanelType.TeamPanel then
    if not self.hasInitedCurrTeamUI then
      self.hasInitedCurrTeamUI = true
      self:InitCurrTeamUI()
    end
  elseif self.currentOpenPanelType == self.PanelType.HistoryTeam and not self.hasInitedHistoryTeamUI then
    self.hasInitedHistoryTeamUI = true
    self:InitHistoryTeamUI()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:SwitchToPanel(toPanelType, bForceNotPlayExit)
  if not (self.typePanelMap and self.typePanelEnterAnimMap) or not self.typePanelExitAnimMap then
    if self._InitDataStructure then
      self:_InitDataStructure()
    end
    if not self.typePanelMap then
      return
    end
  end
  local fromPanelType = self.currentOpenPanelType
  local to = toPanelType
  self.currentOpenPanelType = toPanelType
  local bIsPlayedExit = false
  if not bForceNotPlayExit then
    bIsPlayedExit = self:_PlayPageExitAnimation(fromPanelType, to)
  end
  if not bIsPlayedExit then
    self:_FinishSwitchingPanel()
  end
  if toPanelType == self.PanelType.MainPanel then
    self:UpdateMainPanelPhotoUI()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_InitRewardButton()
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    self.TextClaimProgress_2:SetText("0/12")
    self.TextClaimProgress_1:SetText("0/12")
    return
  end
  local weeklyChallengeData = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  local totalStarNum = MagicManualUtils.GetWeeklyChallengeStarNum(weeklyChallengeData)
  local finishedStarNum = weeklyChallengeData.challenge_info.highest_cheer_point or 0
  self.TextClaimProgress_2:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
  self.TextClaimProgress_1:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_InitTime()
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    return
  end
  self.Time_1:InitializeData(self.WeeklyChallengeEventActivityObject[1]:GetActivityTimeLeft(), nil, true)
  self.Time_1:ShowCountDown()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_PlayPageExitAnimation(fromPanelType, toPanelType)
  if fromPanelType == toPanelType then
    return false
  end
  if not self.typePanelExitAnimMap then
    return false
  end
  local anim = self.typePanelExitAnimMap[fromPanelType]
  if anim then
    self:PlayAnimation(anim)
    return true
  end
  return false
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_PlayPageEnterAnimation(panelType)
  if not self.typePanelEnterAnimMap then
    return
  end
  local anim = self.typePanelEnterAnimMap[panelType]
  if anim then
    self:PlayAnimation(anim)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OpenStarlightShowdownPanel()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightShowdownPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnAnimationFinished(Anim)
  if Anim == self.Cut_In then
    self:PlayAnimation(self.Cut_Out)
    Log.Error("self:PlayAnimation(self.Cut_Out)")
  elseif Anim == self.Press then
    self:PlayAnimation(self.Up)
  end
  if self.bIsStarShow then
    self.bIsStarShow = false
  elseif self.bIsExitPanel then
    self.bIsExitPanel = false
    self:DoClose()
  else
    local bIsExitAnim = false
    if self.typePanelExitAnimMap then
      for k, v in pairs(self.typePanelExitAnimMap) do
        if v == Anim then
          bIsExitAnim = true
          break
        end
      end
    end
    if bIsExitAnim then
      self:_FinishSwitchingPanel()
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TurnCurrTeamLeftPage()
  _G.NRCAudioManager:PlaySound2DAuto(40002008, "UMG_WeeklyChallengeBattle_StarlightReview_C:TurnCurrTeamLeftPage")
  self.currTeamIndex = self.currTeamIndex - 1
  self:UpdateCurrTeamData()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TurnCurrTeamRightPage()
  _G.NRCAudioManager:PlaySound2DAuto(40002008, "UMG_WeeklyChallengeBattle_StarlightReview_C:TurnCurrTeamRightPage")
  self.currTeamIndex = self.currTeamIndex + 1
  self:UpdateCurrTeamData()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateCurrTeamData()
  if not self.hasInitedCurrTeamUI then
    if self.currPetTeams[self.currTeamIndex].photo then
      self:ChangeCurrTeamUsePhotoData(self.currPetTeams[self.currTeamIndex], self.currTeamIndex)
      self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
      self.NRCText_15:SetVisibility(UE4.ESlateVisibility.Visible)
      local teamID = self.currPetTeams[self.currTeamIndex].team_id
      if self.coverPhotoTeamID == teamID then
        self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
        self.NRCText_15:SetText(LuaText.weekly_challenge_text_33)
      else
        self.NRCText_15:SetText(LuaText.weekly_challenge_text_34)
        self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
      end
    else
      self:ChangeCurrTeamUseTeamData(self.currPetTeams[self.currTeamIndex], self.currTeamIndex)
      self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
      self.NRCText_15:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.DefaultTeam:SelectItemByIndex(self.currTeamIndex - 1)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeCurrTeamUseTeamData(teamData, index)
  local petFullIDData = self:GetPetFullIDDataFromTeamData(teamData)
  self.currTeamIndex = index
  self.total_cheer_point = self.currPetTeams[self.currTeamIndex].total_cheer_point
  self:CalcuPetVolume(petFullIDData)
  table.sort(petFullIDData, function(a, b)
    return a.Volume > b.Volume
  end)
  local petBody = self.UMG_StarLightWorldView.PetBody
  self.petFullIDData = petFullIDData
  local newPetFullIDData = {}
  for i = 1, 6 do
    local index = petBody[i]
    if petFullIDData[index] then
      newPetFullIDData[i] = petFullIDData[index]
    end
  end
  for i = 1, 6 do
    if not newPetFullIDData[i] then
      local emptyPetIDData = {}
      emptyPetIDData.petID = 0
      emptyPetIDData.petGID = 0
      newPetFullIDData[i] = emptyPetIDData
    end
  end
  self.petFullIDData = newPetFullIDData
  self.OpponentLineUp:InitGridView(newPetFullIDData)
  self.OpponentLineUp_2:InitGridView(newPetFullIDData)
  local cheerUpPoint = self.total_cheer_point or 0
  self.TeamCheer:SetText(string.format("x%s", cheerUpPoint))
  self:UpdateCurrTeamBtn()
  if self.goToShootAtFirst then
    self.goToShootAtFirst = false
    self:UpdateSubPanelPetModel(self.CurrJsonPath, WeeklyChallengeBattleModuleEnum.PhotoMode.PlayAtStart)
  else
    self:UpdateSubPanelPetModel(self.CurrJsonPath, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtFirstFrame)
  end
  local fashionItems = teamData.wearing_item
  local salon_item_data = teamData.salon_item_data
  self.UMG_StarLightWorldView:LoadPlayerAndAnimRes(fashionItems, salon_item_data)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeCurrTeamUsePhotoData(teamData, index)
  local photoData = teamData.photo
  local petFullIDData = self:GetPetFullIDDataFromPhotoData(photoData)
  self.currTeamIndex = index
  self.OpponentLineUp:InitGridView(petFullIDData)
  self.OpponentLineUp_2:InitGridView(petFullIDData)
  local cheerUpPoint = teamData.total_cheer_point or 0
  self.TeamCheer:SetText(string.format("x%s", cheerUpPoint))
  self.petFullIDData = petFullIDData
  local jsonPath = self:GetJsonNameFromID(photoData.photo_template_id)
  local animPercentList = photoData.anime_percent
  self.UMG_StarLightWorldView:UpdateAnimPercentList(animPercentList)
  self:UpdateCurrTeamBtn()
  self:UpdateSubPanelPetModel(jsonPath, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent)
  local fashionItems = teamData.wearing_item
  local salon_item_data = teamData.salon_item_data
  self.UMG_StarLightWorldView:LoadPlayerAndAnimRes(fashionItems, salon_item_data)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateCurrTeamBtn()
  if 0 == self.currTeamIndex then
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.currTeamIndex == self.MaxCurrTeamIndex then
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.currTeamIndex <= 1 then
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateHistoryTeamBtn()
  if 0 == self.historyTeamIndex then
    self.UMG_StarLightPhoto.Btn_ArrowR_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_StarLightPhoto.Btn_ArrowL_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.historyTeamIndex == self.MaxHistoryTeamIndex then
    self.UMG_StarLightPhoto.Btn_ArrowR_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UMG_StarLightPhoto.Btn_ArrowR_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.historyTeamIndex <= 1 then
    self.UMG_StarLightPhoto.Btn_ArrowL_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UMG_StarLightPhoto.Btn_ArrowL_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TurnHistoryTeamLeftPage()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_WeeklyChallengeBattle_StarlightReview_C:TurnHistoryTeamLeftPage")
  self.historyTeamIndex = self.historyTeamIndex - 1
  self.DefaultTeam_1:SelectItemByIndex(self.historyTeamIndex - 1)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TurnHistoryTeamRightPage()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_WeeklyChallengeBattle_StarlightReview_C:TurnHistoryTeamRightPage")
  self.historyTeamIndex = self.historyTeamIndex + 1
  self.DefaultTeam_1:SelectItemByIndex(self.historyTeamIndex - 1)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeHistoryTeamUsePhotoData(teamData, index)
  local photoData = teamData.photo
  local petFullIDData = self:GetPetFullIDDataFromPhotoData(photoData)
  self.historyTeamIndex = index
  self.OpponentLineUp_1:InitGridView(petFullIDData)
  self.petFullIDData = petFullIDData
  local jsonPath = self:GetJsonNameFromID(photoData.photo_template_id)
  local animPercentList = photoData.anime_percent
  self.UMG_StarLightWorldView:UpdateAnimPercentList(animPercentList)
  self:UpdateHistoryTeamBtn()
  self:UpdateHistoryPhotoUI(teamData)
  local fashionItems = teamData.wearing_item
  local salon_item_data = teamData.salon_item_data
  self:UpdateSubPanelPetModel(jsonPath, WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent)
  self.UMG_StarLightWorldView:LoadPlayerAndAnimRes(fashionItems, salon_item_data)
  self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  self.NRCText_15:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateHistoryPhotoUI(teamData)
  if self.isUpdatingHistoryPhotoUI then
    return
  end
  self.isUpdatingHistoryPhotoUI = true
  if not self.UMG_StarLightPhoto then
    self.isUpdatingHistoryPhotoUI = false
    return
  end
  if not self.UMG_StarLightPhoto.Date_ComboBox then
    self.isUpdatingHistoryPhotoUI = false
    return
  end
  local backgroundPath = self:GetEventBackgroundPath()
  if backgroundPath and self.UMG_StarLightPhoto.NRCImage_5 then
    self.UMG_StarLightPhoto.NRCImage_5:SetPath(backgroundPath)
  end
  if teamData.pet_conf_id then
    local petFullIDData = {}
    for i, petID in ipairs(teamData.pet_conf_id) do
      petFullIDData[i] = {
        petID = petID,
        petGID = teamData.pet_gid and teamData.pet_gid[i] or nil
      }
    end
    self.UMG_StarLightPhoto.PetList:InitGridView(petFullIDData)
  end
  local cheerUpPoint = teamData.total_cheer_point or 0
  self.UMG_StarLightPhoto.TeamCheer:SetText(string.format("x%s", cheerUpPoint))
  if self.historyPetTeamData and #self.historyPetTeamData > 0 then
    local comboBoxData = {}
    for i, data in ipairs(self.historyPetTeamData) do
      if data.photo and data.photo.timestamp then
        local dateDetail = ActivityUtils.ToTimeDetailData(data.photo.timestamp)
        comboBoxData[i] = {
          name = string.format("%04d/%02d/%02d", dateDetail.year, dateDetail.month, dateDetail.day),
          index = i,
          timestamp = data.photo.timestamp
        }
      end
    end
    if #comboBoxData > 0 and self.historyTeamIndex > 0 and self.historyTeamIndex <= #comboBoxData then
      local targetText = comboBoxData[self.historyTeamIndex].name
      local dropDownListData = {}
      dropDownListData.DropDownListInfo = comboBoxData
      dropDownListData.DropDownListIndex = self.historyTeamIndex
      dropDownListData.DropDownListText = targetText
      local success, err = pcall(function()
        self.UMG_StarLightPhoto.Date_ComboBox:SetPanelInfo(dropDownListData)
      end)
    end
  end
  self.isUpdatingHistoryPhotoUI = false
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitHistoryTeamData(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.history_photos then
      self.historyPetTeamData = rsp.history_photos
    end
    self:InitHistoryTeamUI()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitHistoryTeamUI()
  if self.historyPetTeamData and #self.historyPetTeamData > 0 then
    self.notHasHistoryData = false
    self.DefaultTeam_1:InitList(self.historyPetTeamData)
    self.MaxHistoryTeamIndex = #self.historyPetTeamData
    self:InitHistoryDateComboBox()
    self.NRCSwitcher_1:SetActiveWidgetIndex(2)
    self:UpdateHistoryTeamBtn()
  else
    self.notHasHistoryData = true
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitHistoryDateComboBox()
  if not self.historyPetTeamData or 0 == #self.historyPetTeamData then
    return
  end
  if not self.UMG_StarLightPhoto then
    return
  end
  if not self.UMG_StarLightPhoto.Date_ComboBox then
    return
  end
  local comboBoxData = {}
  for i, teamData in ipairs(self.historyPetTeamData) do
    if teamData.photo and teamData.photo.timestamp then
      local dateDetail = ActivityUtils.ToTimeDetailData(teamData.photo.timestamp)
      comboBoxData[i] = {
        name = string.format("%04d/%02d/%02d", dateDetail.year, dateDetail.month, dateDetail.day),
        index = i,
        timestamp = teamData.photo.timestamp
      }
    end
  end
  if #comboBoxData > 0 then
    self.comboBoxDelayId = _G.DelayManager:DelaySeconds(0.1, function()
      self.comboBoxDelayId = nil
      if not self.UMG_StarLightPhoto or not self.UMG_StarLightPhoto.Date_ComboBox then
        return
      end
      local success, err = pcall(function()
        local dropDownListData = {}
        dropDownListData.DropDownListInfo = comboBoxData
        dropDownListData.DropDownListIndex = 1
        dropDownListData.DropDownListText = comboBoxData[1].name
        self.UMG_StarLightPhoto.Date_ComboBox:SetPanelInfo(dropDownListData)
      end)
    end)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:InitCurrTeamUI()
  if self.currPetTeams then
    self.DefaultTeam:InitList(self.currPetTeams)
    self.DefaultTeam:SelectItemByIndex(self.currTeamIndex - 1)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToTakePhoto()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToTakePhoto")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenEffectPopup, self, self.EnterTakePhoto)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:EnterTakePhoto()
  self:SwitchToPanel(self.PanelType.ShootPanel)
  
  function self.curtainCloseCallback()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnToShootDirectlyBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnToShootDirectlyBtnClick")
  if not self.currPetTeams or 0 == #self.currPetTeams then
    Log.Warning("[UMG_WeeklyChallengeBattle_StarlightReview_C] OnToShootDirectlyBtnClick: \230\178\161\230\156\137\231\188\150\233\152\159\230\149\176\230\141\174\239\188\140\230\151\160\230\179\149\232\183\179\232\189\172\229\136\176\230\139\141\231\133\167\231\149\140\233\157\162")
    return
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.EnterTakePhotoDirectly)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:EnterTakePhotoDirectly()
  self:SwitchToTeamPanelFromMain()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToEditPosPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToEditPosPanel")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.OpenEditLocationPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OpenEditLocationPanel()
  self:SwitchToPanel(self.PanelType.EditLocationPanel)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToEditHistoryPosPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToEditHistoryPosPanel")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenEffectPopup, self, self.OpenEditHistoryLocationPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OpenEditHistoryLocationPanel()
  self:SwitchToPanel(self.PanelType.EditLocation_History)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:StartDragUpdateUI()
  if self.itemIndex == nil then
    return
  end
  if 0 == self.petFullIDData[self.itemIndex].petGID then
    return
  end
  for i = 1, self.OpponentLineUp:GetItemCount() do
    if i ~= self.itemIndex then
      local petItem = self.OpponentLineUp:GetItemByIndex(i - 1)
      petItem:StartDrag()
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:EndDragUpdateUI()
  _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetSwapPositions_C:EndDrag")
  for i = 1, self.OpponentLineUp:GetItemCount() do
    if i ~= self.itemIndex then
      local petItem = self.OpponentLineUp:GetItemByIndex(i - 1)
      petItem:EndDrag()
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:SetHasLoadedAllPet()
  self.hasLoadedAllPet = true
  if self.InitOpenCurtain then
    self.InitOpenCurtain = false
    self:ClearCurtainTimeoutProtection()
    _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.CloseLoadingCurtain)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CheckCaptureAndShowToImage()
  if self.CaptureImageOnce then
    self.CaptureImageOnce = false
    if self:CheckIsInShoot() then
      Log.Debug("[UMG_WeeklyChallengeBattle_StarlightReview_C] SetHasLoadedAllPet: PlayAtStart\230\168\161\229\188\143\239\188\140\230\152\190\231\164\186\229\138\168\230\128\129\229\156\186\230\153\175")
    else
      self:CaptureAndShowToImage()
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CaptureAndShowToImage()
  local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })
  if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
    UE.UNRCStatics.MakeDirectory(TempPhotos)
  end
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({
    TempPhotos,
    string.format("StarLight_%d.png", _G.ZoneServer:GetServerTime())
  })
  if UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), self.UMG_StarLightWorldView, PhotoPath) then
    Log.Debug("[UMG_WeeklyChallengeBattle_StarlightReview_C] CaptureAndShowToImage: \230\136\170\229\155\190\230\136\144\229\138\159, PhotoPath=", PhotoPath)
    local targetImage
    if self.currentOpenPanelType == self.PanelType.ChangeHistoryTeamPanel then
      targetImage = self.UMG_StarLightPhoto.Photo_1
    end
    if self.UMG_StarLightWorldView:LoadPhotoToImage(PhotoPath, targetImage) then
      self.UMG_StarLightWorldView.captureImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    Log.Error("[UMG_WeeklyChallengeBattle_StarlightReview_C] CaptureAndShowToImage: \230\136\170\229\155\190\229\164\177\232\180\165")
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:StartCurtainTimeoutProtection()
  self:ClearCurtainTimeoutProtection()
  local timeoutSeconds = 10
  self.curtainTimeoutHandle = _G.DelayManager:DelaySeconds(timeoutSeconds, function()
    if self.InitOpenCurtain then
      Log.Warning("UMG_WeeklyChallengeBattle_StarlightReview_C: \231\170\151\229\184\152\232\182\133\230\151\182\228\191\157\230\138\164\232\167\166\229\143\145\239\188\140\229\188\186\229\136\182\229\133\179\233\151\173\231\170\151\229\184\152")
      self.InitOpenCurtain = false
      self.curtainTimeoutHandle = nil
      _G.NRCModuleManager:DoCmd(LevelSelectionModuleCmd.CloseLoadingCurtain)
    end
  end)
  Log.Debug("UMG_WeeklyChallengeBattle_StarlightReview_C: \231\170\151\229\184\152\232\182\133\230\151\182\228\191\157\230\138\164\229\183\178\229\144\175\229\138\168\239\188\140\232\182\133\230\151\182\230\151\182\233\151\180: " .. timeoutSeconds .. "\231\167\146")
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ClearCurtainTimeoutProtection()
  if self.curtainTimeoutHandle then
    _G.DelayManager:CancelDelayById(self.curtainTimeoutHandle)
    self.curtainTimeoutHandle = nil
    Log.Debug("UMG_WeeklyChallengeBattle_StarlightReview_C: \231\170\151\229\184\152\232\182\133\230\151\182\228\191\157\230\138\164\229\183\178\230\184\133\233\153\164")
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CheckCanTakePhoto()
  if self.canTakePhoto and self.hasLoadedAllPet then
    self.hasTakePhoto = true
    self:TakePhoto()
  else
    Log.Debug("\232\191\152\230\156\170\230\187\161\232\182\179\230\139\141\231\133\167\230\157\161\228\187\182")
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:Tick(MyGeometry, InDeltaTime)
  self:CheckCaptureAndShowToImage()
  if not self.goToShoot then
    return
  end
  if self.hasLoadedAllPet then
    if self.TotalTime < self.DelayTakePhotoTime then
      self.TotalTime = self.TotalTime + InDeltaTime
    elseif self.TotalTime >= self.DelayTakePhotoTime and not self.hasTakePhoto then
      self.canTakePhoto = true
      self:CheckCanTakePhoto()
    end
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TakePhoto()
  _G.NRCAudioManager:PlaySound2DAuto(40009003, "UMG_WeeklyChallengeBattle_StarlightReview_C:TakePhoto")
  self:PlayAnimation(self.TakePhotos)
  if self:CheckIsInCurrShoot() then
    self:UploadData()
  end
  local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })
  if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
    UE.UNRCStatics.MakeDirectory(TempPhotos)
  end
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({
    TempPhotos,
    string.format("%d.png", _G.ZoneServer:GetServerTime())
  })
  if UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), self.UMG_StarLightWorldView, PhotoPath) then
    NRCModuleManager:GetModule("TakePhotosModule"):PopupCustomPhotoFileView(PhotoPath, nil, {bCustomFile = true})
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:TestUpload()
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UploadData()
  local req = _G.ProtoMessage:newZoneWeeklyChallengePhotoUploadReq()
  req.activity_id = self.activityId or 4001
  local photo_info = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeDataPhoto()
  photo_info.photo_template_id = self.photo_template_id or 1000
  local pet_teams = self:GetChallengePetTeamFromPetIDs()
  photo_info.pet_conf_id = pet_teams.pet_conf_id
  photo_info.pet_gid = pet_teams.pet_gid
  photo_info.anime_percent = self.UMG_StarLightWorldView:GetPetAnimFrame()
  self.UploadSuccPhotoData = photo_info
  req.photo_info = photo_info
  req.team_id = self.currPetTeams[self.currTeamIndex].team_id
  self.UMG_StarLightWorldView:StopAllPetAnimInCurrFrame()
  req.photo_info = photo_info
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_PHOTO_UPLOAD_REQ, req, self, self.UploadDataRsp, false)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UploadDataRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_23)
    self.currPetTeams[self.currTeamIndex].photo = rsp.team_photo.photo or self.UploadSuccPhotoData
    self.currPhotoTeamData = rsp.team_photo or self.currPetTeams[self.currTeamIndex]
    self.coverPhotoTeamID = rsp.team_photo.team_id or self.currPhotoTeamData.team_id
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:GetChallengePetTeamFromPetIDs()
  local pet_team = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeTeam()
  if self.petFullIDData then
    for i, IDData in pairs(self.petFullIDData) do
      pet_team.pet_gid[i] = IDData.petGID
      pet_team.pet_conf_id[i] = IDData.petID
      pet_team.total_cheer_point = self.total_cheer_point or 12
    end
  else
    Log.Error("UMG_WeeklyChallengeBattle_StarlightReview_C:GetChallengePetTeamFromPetIDs petFullIDData is nil")
  end
  return pet_team
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:LoadNPCPetTeams()
  self.UMG_StarLightWorldView:LoadFileFromJson(self.CurrJsonPath, true)
  self.UMG_StarLightWorldView:SetPhotoMode(WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent)
  self.UMG_StarLightWorldView:LoadBattleConf(self.battleID)
  self.NPCPetFullIDData = self.UMG_StarLightWorldView.petFullIDData
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:UpdateSubPanelPetModel(jsonPath, PhotoMode, ShowSkillPetIndexList)
  if jsonPath then
    self.UMG_StarLightWorldView:LoadFileFromJson(jsonPath)
  end
  self.UMG_StarLightWorldView:SetPhotoMode(PhotoMode)
  self.UMG_StarLightWorldView:UpdatePetModel(self.petFullIDData, ShowSkillPetIndexList)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:GetJsonNameFromID(photo_template_id)
  local photoConf = DataConfigManager:GetWeeklyPhotoConf(photo_template_id)
  if not photoConf then
    Log.Error(string.format("UMG_WeeklyChallengeBattle_StarlightReview_C:GetJsonPathFromID \232\142\183\229\143\150photoConf\229\164\177\232\180\165"))
    return ""
  end
  local jsonPath = photoConf.res_name
  return jsonPath
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnExitHistoryPanel")
  self:SwitchToPanel(self.PanelType.ChangeHistoryTeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_PrefetchResetState()
  self.module.data:RefetchTeamList()
  self.module.data:FetchCurrentEventId()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    Log.Error("_PrefetchResetState \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("_PrefetchResetState \232\142\183\229\143\150\230\180\187\229\138\168\230\149\176\230\141\174\229\164\177\232\180\165")
    return
  end
  local eventConf = _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  if not eventConf then
    Log.Error("_PrefetchResetState \232\142\183\229\143\150eventConf\229\164\177\232\180\165")
    return
  end
  local challengeId = eventConf.challenge_id[1]
  local activityId = self.WeeklyChallengeEventActivityObject[1]:GetActivityId()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ResetPetStateReq, activityId, challengeId)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CalcuPetVolume(petFullIDData)
  for i, petIDData in pairs(petFullIDData) do
    local petID = petIDData.petID
    local petGID = petIDData.petGID
    local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petID)
    local modelCfg = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf)
    local heightModelScale = 1
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petID)
    local name = petBaseConf.name
    if petGID then
      local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGID)
      if petDataInfo then
        name = petDataInfo.name
        heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(petDataInfo)
      end
    end
    local scaleRatio = (modelCfg.model_scale or 100) / 100
    local Radius = (modelCfg.capsule_radius or 1000) / 1000
    local HalfHeight = (modelCfg.capsule_halfheight or 1000) / 1000
    local Volume = Radius * Radius * HalfHeight * scaleRatio * heightModelScale
    petFullIDData[i].Volume = Volume
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold()
  if self.fold == false then
    _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold2")
    self.fold = true
    self:PlayAnimation(self.EditLocation_Curr_fold)
    self.UMG_StarLightWorldView:HideAllNumberUI()
  else
    _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold2")
    self.fold = false
    self:PlayAnimation(self.EditLocation_Curr_unfold)
    self.UMG_StarLightWorldView:ShowAllNumberUI()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold2()
  if self.fold_history == false then
    _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold2")
    self.fold_history = true
    self:PlayAnimation(self.EditLocation_Curr_fold_history)
  else
    _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_WeeklyChallengeBattle_StarlightReview_C:PlayAdjustUIFold2")
    self.fold_history = false
    self:PlayAnimation(self.EditLocation_Curr_unfold_history)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:ChangeToTakePhotoHistory()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_WeeklyChallengeBattle_StarlightReview_C:EnterHistoryShoot")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenEffectPopup, self, self.EnterTakePhotoHistory)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:EnterTakePhotoHistory()
  self:SwitchToPanel(self.PanelType.Shoot_History)
  
  function self.curtainCloseCallback()
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnCurtainCloseComplete()
  if self.curtainCloseCallback then
    local callback = self.curtainCloseCallback
    self.curtainCloseCallback = nil
    callback()
    Log.Error("Play cut in")
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:EnterHistoryEditLocation()
  self:SwitchToPanel(self.PanelType.EditLocation_History)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CheckIsInCurrShoot()
  if self.currentOpenPanelType == self.PanelType.ShootPanel then
    return true
  end
  return false
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:CheckIsInShoot()
  if self.currentOpenPanelType == self.PanelType.ShootPanel or self.currentOpenPanelType == self.PanelType.Shoot_History then
    return true
  end
  return false
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_GetBatchAndNumberFromCurtainName(fileName)
  if not fileName then
    return
  end
  local batch, number = string.match(fileName, "^MI_Curtain_(.-)_(.-)_Skeletal$")
  return batch, number
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:_InitEventBackground()
  Log.Info("UMG_StarlightShowdownPanel_C:_InitEventBackground \229\188\128\229\167\139\229\136\157\229\167\139\229\140\150\232\131\140\230\153\175")
  local backgroundPath = self:GetEventBackgroundPath()
  if backgroundPath then
    self.NRCImage_1:SetPath(backgroundPath)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:GetEventBackgroundPath()
  local challengeConf = DataConfigManager:GetWeeklyChallengeConf(self.challengeId)
  if not challengeConf then
    Log.Error("UMG_WeeklyChallengeBattle_StarlightReview_C:GetEventBackgroundPath challengeConf is nil")
    return nil
  end
  local photoConf = _G.DataConfigManager:GetWeeklyPhotoConf(challengeConf.photo)
  if not photoConf then
    Log.Error("UMG_WeeklyChallengeBattle_StarlightReview_C:GetEventBackgroundPath \232\142\183\229\143\150photoConf\229\164\177\232\180\165")
    return nil
  end
  local curtainName = "MI_Curtain_001_03_Skeletal"
  if photoConf.background then
    curtainName = photoConf.background
  else
    local json = JsonUtils.LoadSavedFromStarLight(photoConf.res_name or self.LoadJsonPath or "PhotoEditorJson", {})
    if json[1] and json[1][2] then
      curtainName = json[1][2]
    else
      Log.Error("\233\133\141\231\189\174\228\184\173\231\188\186\229\176\145\229\185\149\229\184\131\231\154\132\232\131\140\230\153\175\230\149\176\230\141\174\239\188\140\231\173\150\229\136\146\232\175\183\230\163\128\230\159\165\228\184\128\228\184\139")
    end
  end
  local batch, number = self:_GetBatchAndNumberFromCurtainName(curtainName)
  local backgroundPath = string.format(UEPath.WeeklyChallengeBattleBackground, batch, number, batch, number)
  return backgroundPath
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:SwitchToTeamPanelFromMain()
  self.currTeamIndex = #self.currPetTeams
  self:UpdateCurrTeamData()
  self:SwitchToPanel(self.PanelType.ChangeCurrTeamPanel)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnPhotoPanelClose()
  self.UMG_StarLightWorldView:PlayAllPetAnimInFirstFrame()
  self.BtnPhotograph:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnCoverSet()
  _G.NRCAudioManager:PlaySound2DAuto(40007001, "UMG_WeeklyChallengeBattle_StarlightReview_C:OnCoverSet")
  local req = ProtoMessage:newZoneWeeklyChallengeUpdatePhotoReq()
  local newCoverPhotoTeamID = self.currPetTeams[self.currTeamIndex].team_id
  req.team_id = newCoverPhotoTeamID
  req.activity_id = self.activityId or 4001
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_UPDATE_PHOTO_REQ, req, self, self.OnCoverSetSucc, false, false)
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnCoverSetSucc(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.weekly_challenge_text_23)
    self.currPhotoTeamData = rsp.team_photo
    self.coverPhotoTeamID = rsp.team_photo.team_id
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
    self.NRCText_15:SetText(LuaText.weekly_challenge_text_33)
  end
end

function UMG_WeeklyChallengeBattle_StarlightReview_C:OnDateComboBoxSelectChanged(index, dataList)
  if self.isUpdatingHistoryPhotoUI then
    return
  end
  if not self.historyPetTeamData or 0 == #self.historyPetTeamData then
    return
  end
  if not index or index < 1 or index > #self.historyPetTeamData then
    return
  end
  if self.currentOpenPanelType ~= self.PanelType.ChangeHistoryTeamPanel then
    return
  end
  if self.historyTeamIndex == index then
    return
  end
  local success, err = pcall(function()
    self.DefaultTeam_1:SelectItemByIndex(index - 1)
  end)
end

return UMG_WeeklyChallengeBattle_StarlightReview_C
