local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetTeam_C = _G.NRCViewBase:Extend("UMG_PetTeam_C")
local PetTeamUtils = require("NewRoco.Modules.System.PetUI.Res.PetTeam.PetTeamUtils")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local _isDraging = false
local _isTouched = false
local _startPostion = UE4.FVector2D(0, 0)
local _slotId = 0
local TrialFreshBrunTime = 1

function UMG_PetTeam_C:OnActive()
end

function UMG_PetTeam_C:OnDeactive()
end

function UMG_PetTeam_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_formation.btnLevelUp, self.OnOpenTeamManagementUI)
  self:AddButtonListener(self.Btn_add, self.OnBtnAddClicked)
  self:AddButtonListener(self.Btn_add_1, self.OnBtnAddClicked1)
  self:AddButtonListener(self.Btn_add_2, self.OnBtnAddClicked2)
  self:AddButtonListener(self.Btn_add_3, self.OnBtnAddClicked3)
  self:AddButtonListener(self.Btn_add_4, self.OnBtnAddClicked4)
  self:AddButtonListener(self.Btn_add_5, self.OnBtnAddClicked5)
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.Exchange_1.btnLevelUp, self.OnBtnOpenMagicBag)
  self:AddButtonListener(self.Exchange.btnLevelUp, self.OnBtnOpenMagicBag)
  self:AddButtonListener(self.BloodBtn, self.OnBtnOpenMagicBag)
  self:AddButtonListener(self.BloodBtn_1, self.OnBtnOpenMagicBag)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:AddButtonListener(self.KeyBtn.btnLevelUp, self.OnImportClick)
  if self.FriendTeamBtn then
    self:AddButtonListener(self.FriendTeamBtn.btnLevelUp, self.OnFriendPetTeamEntryClick)
  end
  self:SetBtnArrow()
  self.AllTeamsBtn:AddReleasedCallback(self, self.OnBtnAllTeamsBtn)
  self:AddButtonListener(self.NameButton, self.OnBtnRenameClick)
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamManagementModifyTeamName, self.RefreshCurTeamUI)
  _G.NRCEventCenter:RegisterEvent("UMG_PetTeam_C", self, PetUIModuleEvent.PetTeamEquipPetMagic, self.OnPetTeamEquipPetMagic)
  self:RegisterEvent(self, PetUIModuleEvent.PetEquipSkillFinished, self.OnPetEquipSkillFinished)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
end

function UMG_PetTeam_C:OnPetTeamEquipPetMagic(MagicData)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamRoleMagicGid, MagicData.TeamIdx, MagicData.TeamType, MagicData.MagicGid)
end

function UMG_PetTeam_C:OnImportClick()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLoadPetTeamPanel, self.curTeamType, self.teamIdx)
end

function UMG_PetTeam_C:OnShareClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if isBan then
    return
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenShareTeamPanel, self.curTeamType, self.teamIdx)
end

function UMG_PetTeam_C:OnBtnOpenMagicBag()
  local teamData = self.teamData
  if teamData.is_mirror then
    if teamData.role_magic_gid then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodMagicTips, self.teamData)
    end
  else
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    if BagItemS and #BagItemS > 0 then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodLineMagic, self.curTeamType, self.teamIdx)
    else
      local Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_tips1")
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Conf.str)
    end
  end
end

function UMG_PetTeam_C:OnBtnAddClicked()
  self:OnOpenUmgTeamPetReplace(nil, 1)
end

function UMG_PetTeam_C:OnBtnAddClicked1()
  self:OnOpenUmgTeamPetReplace(nil, 2)
end

function UMG_PetTeam_C:OnBtnAddClicked2()
  self:OnOpenUmgTeamPetReplace(nil, 3)
end

function UMG_PetTeam_C:OnBtnAddClicked3()
  self:OnOpenUmgTeamPetReplace(nil, 4)
end

function UMG_PetTeam_C:OnBtnAddClicked4()
  self:OnOpenUmgTeamPetReplace(nil, 5)
end

function UMG_PetTeam_C:OnBtnAddClicked5()
  self:OnOpenUmgTeamPetReplace(nil, 6)
end

function UMG_PetTeam_C:OnBtnAllTeamsBtn()
  self.Parent:OpenTeamManagementUI()
end

function UMG_PetTeam_C:OnBtnRightChangeTeam()
  self.rightOrLeftClick = true
  self.Parent:OnClickChangeTeam(true)
end

function UMG_PetTeam_C:OnBtnLeftChangeTeam()
  self.rightOrLeftClick = true
  self.Parent:OnClickChangeTeam(false)
end

function UMG_PetTeam_C:OnOpenUmgTeamPetReplace(PetIndex, SlotId)
  if PetIndex then
    if self.teamData.pet_infos and self.teamData.pet_infos[PetIndex] then
      local petGid = self.teamData.pet_infos[PetIndex].pet_gid
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetTeamReplacePanel, self.curTeamType, self.teamIdx, petGid, nil, PetUIModuleEnum.ModifyPetMode.SingleEdit)
      self:SetBtnCloseState(PetUIModuleEnum.PetTeamShowType.HidePetsUis)
    end
  elseif SlotId then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetTeamReplacePanel, self.curTeamType, self.teamIdx, nil, SlotId, PetUIModuleEnum.ModifyPetMode.SingleEdit)
    self:SetBtnCloseState(PetUIModuleEnum.PetTeamShowType.HidePetsUis)
  end
end

function UMG_PetTeam_C:OnCloseBtnClick()
  self.Parent:OnCloseBtnClick()
end

function UMG_PetTeam_C:SetBtnCloseState(state, isFirst)
  self.btnCloseState = state
  if state == PetUIModuleEnum.PetTeamShowType.Normal then
    self.UMG_PetTeamImage:SetCaptureScene(false)
    self:RefreshBtnState(false)
    self:RefreshTrialInfo(false)
    self:StopTweenInAndTweenOutAnimation()
    if not isFirst then
      self.playInUiCount = 0
      self:PlayAnimation(self.In_UI)
    end
  elseif state == PetUIModuleEnum.PetTeamShowType.HidePetsUis then
    self.UMG_PetTeamImage:SetCaptureScene(true)
    self:RefreshBtnState(true)
    self:RefreshTrialInfo(true)
    self:StopTweenInAndTweenOutAnimation()
    self.playOutUiCount = 0
    self:PlayAnimation(self.Out_UI)
  elseif state == PetUIModuleEnum.PetTeamShowType.HideUis then
    self.UMG_PetTeamImage:SetCaptureScene(false)
    self:RefreshBtnState(true)
    self:RefreshTrialInfo(true)
    self:StopTweenInAndTweenOutAnimation()
    if not isFirst then
      self.playOutUiCount = 0
      self:PlayAnimation(self.Out_UI)
    end
  end
end

function UMG_PetTeam_C:OnRemoveEventListener()
  self.Btn_formation.RedDot:UnRegister()
  self:RemoveButtonListener(self.Btn_formation.btnLevelUp, self.OnOpenTeamManagementUI)
  self:RemoveButtonListener(self.Btn_add, self.OnBtnAddClicked)
  self:RemoveButtonListener(self.Btn_add_1, self.OnBtnAddClicked1)
  self:RemoveButtonListener(self.Btn_add_2, self.OnBtnAddClicked2)
  self:RemoveButtonListener(self.Btn_add_3, self.OnBtnAddClicked3)
  self:RemoveButtonListener(self.Btn_add_4, self.OnBtnAddClicked4)
  self:RemoveButtonListener(self.Btn_add_5, self.OnBtnAddClicked5)
  self:RemoveButtonListener(self.btnClose.btnClose, self.OnCloseBtnClick)
  self:RemoveButtonListener(self.Exchange_1.btnLevelUp, self.OnBtnOpenMagicBag)
  self:RemoveButtonListener(self.Exchange.btnLevelUp, self.OnBtnOpenMagicBag)
  self:RemoveButtonListener(self.BloodBtn, self.OnBtnOpenMagicBag)
  self:RemoveButtonListener(self.BloodBtn_1, self.OnBtnOpenMagicBag)
  self:RemoveButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:RemoveButtonListener(self.KeyBtn.btnLevelUp, self.OnImportClick)
  self:RemoveButtonListener(self.NameButton, self.OnBtnRenameClick)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamManagementModifyTeamName, self.RefreshCurTeamUI)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagic, self.OnPetTeamEquipPetMagic)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetEquipSkillFinished, self.OnPetEquipSkillFinished)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
end

function UMG_PetTeam_C:OnConstruct()
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(2)
  self:SetChildViews(self.PetTeam_1, self.PetTeam1, self.PetTeam2, self.PetTeam3, self.PetTeam4, self.PetTeam5, self.UMG_PetTeamImage)
  self.btnCloseState = PetUIModuleEnum.PetTeamShowType.Normal
  self.rightOrLeftClick = nil
  self.PetTeamUiList = {
    self.PetTeam_1,
    self.PetTeam1,
    self.PetTeam2,
    self.PetTeam3,
    self.PetTeam4,
    self.PetTeam5
  }
  self.BtnAddList = {
    self.Btn_add,
    self.Btn_add_1,
    self.Btn_add_2,
    self.Btn_add_3,
    self.Btn_add_4,
    self.Btn_add_5
  }
  self.PetBtnList = {
    self.PetBtn,
    self.PetBtn_1,
    self.PetBtn_2,
    self.PetBtn_3,
    self.PetBtn_4,
    self.PetBtn_5
  }
  self.SwitchList = {
    self.Switcher_1,
    self.Switcher_2,
    self.Switcher_3,
    self.Switcher_4,
    self.Switcher_5,
    self.Switcher_6
  }
  self:OnAddEventListener()
  self:InitUI()
  self:SetCommonTitle()
  self.UMG_PetTeamImage:SetParent(self)
  self:SetPanelHitTestVisible(false)
  self:CheckShareIsOpen()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_PetTeam_C:OnTick(deltaTime)
  if self.TrialBurnTime and self.TrialBurnTime >= 0 then
    self.TrialBurnTime = self.TrialBurnTime + deltaTime
    if self.TrialBurnTime >= TrialFreshBrunTime and self.trialInfo then
      self.TrialBurnTime = 0
      self:RefreshTrialTime(self.trialInfo.refresh_time or 0)
    end
  end
end

function UMG_PetTeam_C:OnDestruct()
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(0)
  self.IsResetTrialPetData = nil
  self:CancelDelay()
  self:OnRemoveEventListener()
  self.UMG_PetTeamImage:ReleaseForce()
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_PetTeam_C:RefreshTrialInfo(forceHide)
  if self.curTeamType == Enum.PlayerTeamType.PTT_PVP_BATTLE_4 and not forceHide then
    self.trialInfo = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBrief) or {}
    if self.trialInfo then
      self.Btn_formation.RedDot:SetupKey(380)
      self.TrialBurnTime = 0
      local pvp_rank_character31Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character31")
      local pvp_rank_character31ConfStr = pvp_rank_character31Conf and pvp_rank_character31Conf.str or ""
      local pvp_rank_character32Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character32")
      local pvp_rank_character32ConfStr = pvp_rank_character32Conf and pvp_rank_character32Conf.str or ""
      local trialInfo = self.trialInfo
      local unitTypeList = trialInfo and trialInfo.unit_type or {}
      local trailDescriptionText = ""
      if next(unitTypeList) then
        trailDescriptionText = pvp_rank_character31ConfStr
      else
        trailDescriptionText = pvp_rank_character32ConfStr
      end
      self.TrialPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:RefreshTrialAttrList(unitTypeList)
      self:RefreshTrialTime(self.trialInfo.refresh_time or 0)
      self.TrialDescription:SetText(trailDescriptionText)
    else
      self.TrialBurnTime = -1
      self.TrialPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TrialBurnTime = -1
    self.TrialPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetTeam_C:RefreshTrialAttrList(TypeList)
  local PetTypeList = {}
  for i, v in ipairs(TypeList or {}) do
    local petType = v
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        table.insert(PetTypeList, {
          Path = typeDic.tips_base_icon,
          Name = typeDic.short_name
        })
      end
    end
  end
  self.Attr:InitGridView(PetTypeList)
end

function UMG_PetTeam_C:RefreshTrialTime(OverTime)
  local curTime = ActivityUtils.GetSvrTimestamp()
  local remainTime = OverTime - curTime
  if remainTime > 4000 then
    TrialFreshBrunTime = 60
  else
    TrialFreshBrunTime = 1
  end
  self.CountDown:SetText(ActivityUtils.GetTimeFormatStr(remainTime))
end

function UMG_PetTeam_C:SetPanelHitTestVisible(bCanHit)
  if bCanHit then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_PetTeam_C:OnOpenTeamManagementUI()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetTeam_C:OnOpenTeamManagementUI")
  if not _isTouched then
    self:OnOpenUmgTeamPetReplace(nil, 11)
  end
end

function UMG_PetTeam_C:OnOpenPetWarehouseUI(petGid, slotId)
  if self.Parent and not _isTouched then
    self.Parent:OpenPetWarehouseUI(petGid, slotId)
  end
end

function UMG_PetTeam_C:OnOpenFastFormationUI()
  if self.Parent and not _isTouched then
    self.Parent:OpenFastFormationUI()
  end
end

function UMG_PetTeam_C:OnFriendPetTeamEntryClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetTeam_C:OnFriendPetTeamEntryClick")
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenFriendPetTeamPanel, self.curTeamType)
end

function UMG_PetTeam_C:ShowRightBottom(_isShow)
end

function UMG_PetTeam_C:OnOpenResonanceUI()
  if _isTouched then
    return
  end
  if self.teamData == nil or nil == self.teamData.pet_infos or 0 == #self.teamData.pet_infos then
    local msg = _G.DataConfigManager:GetPetGlobalConfig("pet_no_synchron").str
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg)
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1290, "UMG_PetTeam_C:OnOpenResonanceUI")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetTeamResonancePanel, self.teamData)
end

function UMG_PetTeam_C:InitUI()
  for slotIdx, petTeam in ipairs(self.PetTeamUiList) do
    petTeam:InitUI(slotIdx, self)
  end
end

function UMG_PetTeam_C:InitFriendTeamEntry()
  local isShow = PetTeamUtils.IsShowFriendTeamEntrance(self.curTeamType)
  UIUtils.SafeSetVisibility(self.FriendTeamName, UE4.ESlateVisibility.Collapsed, true)
  if isShow then
    UIUtils.SafeSetVisibility(self.FriendTeamBtn, UE4.ESlateVisibility.Visible)
    self.FriendTeamBtn:SetText(LuaText.share_pet_friend_team_text)
  else
    UIUtils.SafeSetVisibility(self.FriendTeamBtn, UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetTeam_C:SetParent(parent)
  self.Parent = parent
end

function UMG_PetTeam_C:RefreshCurTeamUI()
  self.Text_name:SetText(self:GetTeamName())
end

function UMG_PetTeam_C:OnBtnRenameClick()
  local param = {
    teamType = self.curTeamType,
    TeamIdx = self.teamIdx,
    teamName = self:GetTeamName()
  }
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenRechristenPanel, param, nil, 2)
end

function UMG_PetTeam_C:GetTeamName()
  local teamData = self.teamData
  if teamData.is_mirror then
    self.Btn_formation:SetBtnText(LuaText.share_pet_friend_team_open)
    self.NameButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Friend:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_FriendName:SetText(string.format(LuaText.share_pet_owner_inf_1, teamData.mirror_friend_name))
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(teamData.mirror_friend_card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
      self.Image_Head:SetPath(AvatarPath)
    end
  else
    if self.ShareIsOpen then
      self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.Btn_formation:SetBtnText(LuaText.share_pet_friend_team_edit)
    self.NameButton:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Friend:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Exchange_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if not teamData.team_name or teamData.team_name == "" then
    local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
    return string.format(teamNameCfg.str, self.teamIdx + 1)
  else
    return teamData.team_name
  end
end

function UMG_PetTeam_C:RefreshBtnState(forceHide)
  if forceHide then
    for i = 1, 6 do
      self.PetTeamUiList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SwitchList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PetBtnList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    local canInTeamNum = PetTeamUtils.GetCanInPetNum(self.curTeamType)
    for i = 1, canInTeamNum do
      if self.teamData and self.teamData.pet_infos and self.teamData.pet_infos[i] then
        self.PetTeamUiList[i]:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.SwitchList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.PetBtnList[i]:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      else
        self.PetTeamUiList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.SwitchList[i]:SetVisibility(UE4.ESlateVisibility.Visible)
        self.SwitchList[i]:SetActiveWidgetIndex(0)
        self.PetBtnList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if canInTeamNum < 6 then
      for i = canInTeamNum + 1, 6 do
        self.SwitchList[i]:SetVisibility(UE4.ESlateVisibility.Visible)
        self.SwitchList[i]:SetActiveWidgetIndex(1)
        self.PetTeamUiList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.PetBtnList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetTeam_C:OnPetEquipSkillFinished()
  self:SetTeamData(self.teamIdx, self.teamData, self.curTeamType, true)
end

function UMG_PetTeam_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_PetTeam_C:SetBtnArrow()
  local CommonBtnArrowData1 = {}
  CommonBtnArrowData1.Call = self
  CommonBtnArrowData1.btnHandler = self.OnBtnRightChangeTeam
  CommonBtnArrowData1.modeIndex = 4
  self.RightBtn:SetBtnInfo(CommonBtnArrowData1)
  local CommonBtnArrowData2 = {}
  CommonBtnArrowData2.Call = self
  CommonBtnArrowData2.btnHandler = self.OnBtnLeftChangeTeam
  CommonBtnArrowData2.modeIndex = 3
  self.TheLeftBtn:SetBtnInfo(CommonBtnArrowData2)
end

function UMG_PetTeam_C:SetTeamData(teamIdx, teamData, teamType, forceUpdate, IsResetTrialPetData)
  self.teamIdx = teamIdx or 0
  self.teamData = teamData
  self.curTeamType = teamType
  self.IsResetTrialPetData = IsResetTrialPetData
  self:RefreshCommonTitle(teamType)
  self:RefreshTeamInfo()
  self:InitFriendTeamEntry()
  self.UMG_PetTeamImage:SetTeamData(teamIdx, teamData, self.curTeamType, forceUpdate)
  self.Text_name:SetText(self:GetTeamName())
  self:UpdateRoleMagicInfo()
  self:RefreshBtnState(self.btnCloseState ~= PetUIModuleEnum.PetTeamShowType.Normal)
  self:RefreshTrialInfo(self.btnCloseState ~= PetUIModuleEnum.PetTeamShowType.Normal)
  local dataList = {}
  for i = 1, 8 do
    table.insert(dataList, i)
  end
  self.FormationQuantity:InitGridView(dataList)
  self.FormationQuantity:SelectItemByIndex(teamIdx)
  self:PlayAnimation(self.Cut_1)
end

function UMG_PetTeam_C:RefreshCommonTitle(teamType)
  local allBattleTypeConf = _G.DataConfigManager:GetAllByName("BATTLE_TYPE_CONF")
  for i, v in pairs(allBattleTypeConf) do
    if v.player_team_type == teamType then
      self.Title1:Set_MainTitle(v.name)
      break
    end
  end
end

function UMG_PetTeam_C:SetTeamNameText(teamIdx, teamData, teamType)
  self.teamData = teamData
  self.Text_name:SetText(self:GetTeamName())
end

function UMG_PetTeam_C:UpdateRoleMagicInfo()
  local teamData = self.teamData
  local hasMagic = false
  if teamData.is_mirror then
    if teamData.mirror_magic_id and 0 ~= teamData.mirror_magic_id then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(teamData.mirror_magic_id)
      if BagItemConf then
        hasMagic = true
        self.Switcher:SetActiveWidgetIndex(0)
        self.Text_Magic:SetText(BagItemConf.name)
        self.Icon:SetPath(BagItemConf.icon)
      end
    end
  elseif teamData.role_magic_gid and 0 ~= teamData.role_magic_gid then
    local itemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, teamData.role_magic_gid)
    if itemInfo then
      local PlayerMagicConf = _G.DataConfigManager:GetBagItemConf(itemInfo.id)
      if PlayerMagicConf then
        hasMagic = true
        self.Switcher:SetActiveWidgetIndex(0)
        self.Text_Magic:SetText(PlayerMagicConf.name)
        self.Icon:SetPath(PlayerMagicConf.icon)
      end
    end
  end
  if not hasMagic then
    self.Switcher:SetActiveWidgetIndex(1)
    local nameLessCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_magic_nameless")
    self.Text_Magic:SetText(nameLessCfg.str)
  end
end

function UMG_PetTeam_C:RefreshTeamInfo()
  local teamData = self.teamData
  for slotIdx, petTeam in ipairs(self.PetTeamUiList) do
    local data
    if teamData.pet_infos and teamData.pet_infos[slotIdx] then
      data = teamData.pet_infos[slotIdx].pet_gid
    end
    petTeam:SetData(data, teamData.is_mirror)
  end
end

function UMG_PetTeam_C:GetSlotIdByScreenPosition(screenPosition)
  for index = 1, #self.PetBtnList do
    local teamBoxGeo = self.PetBtnList[index]:GetCachedGeometry()
    if UE4.USlateBlueprintLibrary.IsUnderLocation(teamBoxGeo, screenPosition) then
      return index
    end
  end
  return nil
end

function UMG_PetTeam_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  local pointerIndex = UE4.UKismetInputLibrary.PointerEvent_GetPointerIndex(_InTouchEvent)
  if 0 ~= pointerIndex then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  local screenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  local touchId = self:GetSlotIdByScreenPosition(screenPosition)
  if not touchId then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  if touchId > 0 then
    _slotId = touchId
    _startPostion = screenPosition
    _isDraging = false
    _isTouched = true
  end
  local screenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  for index = 1, #self.PetBtnList do
    local teamBoxGeo = self.PetBtnList[index]:GetCachedGeometry()
    if UE4.USlateBlueprintLibrary.IsUnderLocation(teamBoxGeo, screenPosition) then
      _slotId = index
      _startPostion = screenPosition
      _isDraging = false
      _isTouched = true
    end
  end
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_PetTeam_C:OnTouchMoved(_MyGeometry, _InTouchEvent)
  if false == _isTouched then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  local pointerIndex = UE4.UKismetInputLibrary.PointerEvent_GetPointerIndex(_InTouchEvent)
  if 0 ~= pointerIndex then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  local screenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  local diffPostion = screenPosition - _startPostion
  local localPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), screenPosition)
  if false == _isDraging and diffPostion:SizeSquared() > 25 then
    _isDraging = true
    if self.teamData.is_mirror then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_owner_inf_3)
    else
      self:DispatchEvent(PetUIModuleEvent.PetTeamTouchStarted, _slotId, localPos)
      self:RefreshBtnState(true)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1282, "UMG_PetTeam_C:PetTeamTouchStarted")
    end
  end
  if _isDraging then
    self:DispatchEvent(PetUIModuleEvent.PetTeamTouchMoved, localPos)
  end
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_PetTeam_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  if false == _isTouched then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  local pointerIndex = UE4.UKismetInputLibrary.PointerEvent_GetPointerIndex(_InTouchEvent)
  if 0 ~= pointerIndex then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  if false == _isDraging then
    self:OnClicked()
  else
    local screenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
    local touchId = self:GetSlotIdByScreenPosition(screenPosition)
    touchId = touchId or _slotId
    self:DispatchEvent(PetUIModuleEvent.PetTeamTouchEnded, touchId)
    self:RefreshBtnState(false)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1283, "UMG_PetTeam_C:PetTeamTouchEnded")
    _isDraging = false
  end
  _isTouched = false
  _slotId = 0
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_PetTeam_C:OnClicked()
  if self.teamData then
    self:OnOpenUmgTeamPetReplace(_slotId)
  end
end

function UMG_PetTeam_C:MoveCameraToSlot(slotId)
  self.UMG_PetTeamImage:MoveCameraToSlot(slotId)
end

function UMG_PetTeam_C:SetAllNameTagVisState(isShow)
  for _, petTeam in ipairs(self.PetTeamUiList) do
    petTeam:SetNameTagVisState(isShow)
  end
end

function UMG_PetTeam_C:ShowDragIndicator(isShow)
  for _, petTeam in ipairs(self.PetTeamUiList) do
    petTeam:ShowDragIndicator(isShow)
  end
end

function UMG_PetTeam_C:ShowSlotInfoTag(slotId)
  if not slotId or 0 == slotId then
    return
  end
  self.PetTeamUiList[slotId]:PlayShowAnimation()
end

function UMG_PetTeam_C:PlayShowAnim()
  if not self.rightOrLeftClick then
    if not self.IsResetTrialPetData then
      _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
    end
    self.IsResetTrialPetData = nil
  end
  self.UMG_PetTeamImage:PlayShowAnim()
end

function UMG_PetTeam_C:StopTweenInAndTweenOutAnimation()
  if self:IsAnimationPlaying(self.In_UI) then
    self:StopAnimation(self.In_UI)
  end
  if self:IsAnimationPlaying(self.Out_UI) then
    self:StopAnimation(self.Out_UI)
  end
end

function UMG_PetTeam_C:OnAnimationFinished(Anim)
  if Anim == self.In_UI then
    if 0 == self.playInUiCount then
      self:PlayAnimation(self.In_UI, 0.16)
      self.playInUiCount = self.playInUiCount + 1
      _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    end
  elseif Anim == self.Out_UI and 0 == self.playOutUiCount then
    self:PlayAnimation(self.Out_UI, 0.16)
    self.playOutUiCount = self.playOutUiCount + 1
  end
end

function UMG_PetTeam_C:AsyncLoadSceneOver()
  if self.Parent then
    self.Parent:AsyncLoadSceneOver()
  end
end

function UMG_PetTeam_C:CheckShowShareReward(data)
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

function UMG_PetTeam_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PetTeam_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_TEAM_SHARE
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  if self.ShareIsOpen then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetTeam_C
