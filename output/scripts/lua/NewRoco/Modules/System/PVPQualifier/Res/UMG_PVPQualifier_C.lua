local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local LuaText = require("LuaText")
local TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
local BattleModuleCmd = require("NewRoco.Modules.Core.Battle.BattleModuleCmd")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_PVPQualifier_C = _G.NRCPanelBase:Extend("UMG_PVPQualifier_C")
local NPCShopUIModuleEvent = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local NPCShopUIModuleEnum = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local PVPRankedMatchModuleEnum = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEnum")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local CWView_WeekendBenefitsPanel = require("NewRoco.Modules.System.PVPQualifier.Res.CWView_WeekendBenefitsPanel")
local TrialFreshBrunTime = 1
local initMatchPvpId = 5001

function UMG_PVPQualifier_C:OnActive()
  Log.Debug("SeasonOpen Progress: UMG_PVPQualifier_C:OnActive")
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.CWView_WeekendBenefitsPanel:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.data = self.module:GetData("PVPRankedMatchModuleData")
  self:SetCurrentMatchPvpId(initMatchPvpId)
  self:TrySendZonePvpInfoQueryReq()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPCutto)
  self:StartDelay()
  _G.FunctionBanManager:AddPlayerConditionType(_G.Enum.PlayerConditionType.PCT_PVP_RANK_MAIN_UI)
end

UMG_PVPQualifier_C.CloseStateEum = {
  PVPRankMatch = 1,
  ClickBtnClose = 2,
  OpenShop = 3
}

function UMG_PVPQualifier_C:TrySendZonePvpInfoQueryReq()
  if self.data:IsZonePvpInfoQueryRspExceed() then
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq)
  else
    self:OnSetPvpInfoQueryData(false)
  end
end

function UMG_PVPQualifier_C:OnSetPvpInfoQueryData(IsResetTrialPetData)
  self.IsResetTrialPetData = IsResetTrialPetData
  self:StartLoadSpineAsset()
end

function UMG_PVPQualifier_C:StartRefreshUi(IsResetTrialPetData)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:InitData()
  self:RefreshUI(IsResetTrialPetData)
  self.IsGetNextQualifierData = true
end

function UMG_PVPQualifier_C:OnDeactive()
  Log.Debug("SeasonOpen Progress: UMG_PVPQualifier_C:OnDeactive")
  if self.CWView_WeekendBenefitsPanel then
    self.CWView_WeekendBenefitsPanel:OnDeactive()
  else
    Log.Debug("CWView_WeekendBenefitsPanel is nil")
  end
  if self.data then
    self.data:ClearRankMatchData()
  end
  self:OnRemoveEventListener()
  self:CancelDelayFunc()
  self:SetCurrentMatchPvpId(nil)
  _G.FunctionBanManager:RemovePlayerConditionType(_G.Enum.PlayerConditionType.PCT_PVP_RANK_MAIN_UI)
  self.CloseState = nil
end

function UMG_PVPQualifier_C:OnAddEventListener()
  self:RegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpInfoQueryData, self.OnSetPvpInfoQueryData)
  self:AddButtonListener(self.BloodBtn_1, self.OnClickBloodBtn)
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickBtnClose)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OpenActivityDescription)
  self.AwardBtn:AddReleasedCallback(self, self.OpenAwardBtn)
  self.BloodBtn.OnPressed:Add(self, self.ExChangePressed)
  self.BloodBtn.OnReleased:Add(self, self.ExChangeReleased)
  self.BloodBtn.OnClicked:Add(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnClicked:Add(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnPressed:Add(self, self.ExChangePressed)
  self.BloodBtn_1.OnReleased:Add(self, self.ExChangeReleased)
  self.Btn_StartUsing_1.btnLevelUp.OnClicked:Add(self, self.OnBtnOpenPetTeamUI)
  self.Btn_StartUsing_1.RedDot:SetupKey(379)
  self.HistoricalRecordBtn.btnLevelUp.OnClicked:Add(self, self.OnBtnHistoricalRecord)
  self.WeeklyRewardBtn.btnLevelUp.OnClicked:Add(self, self.OnBtnWeeklyReward)
  self.BtnChallenge.btnLevelUp.OnClicked:Add(self, self.OnBtnChallenge)
  self.ShopBtn.btnLevelUp.OnClicked:Add(self, self.OnShopBtn)
  self.RankingEntrance:BindLuaCallBack({
    self,
    self.OnRankingEntranceCheckStateChangeChanged
  }, {
    self,
    self.OnRankingEnhanceCheckBoxIsClickable
  })
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PetUIModuleEvent.PetTeamManagementSelChanged, self.OnPetTeamManagementSelChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnPetTeamEquipPetMagic)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PetUIModuleEvent.PlayerDataUpdate, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PVPRankedMatchModuleEvent.UpdateSeasonStarReward, self.RefreshMoney)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, PVPRankedMatchModuleEvent.UpdateWeekReward, self.RefreshMoney)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPQualifier_C", self, SystemSettingModuleEvent.PlayerSettingUpdate, self.HandlePlayerSettingUpdate)
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, self.RefreshMoney)
  self.SpineFlag.AnimationStart:Add(self, self.OnSpineAnimationStart)
end

function UMG_PVPQualifier_C:OnReConnectStart()
  if self and UE4.UObject.IsValid(self) then
    self:DoClose()
  end
end

function UMG_PVPQualifier_C:HandlePlayerSettingUpdate()
  local isOpenRank = self:IsOpenRank()
  self:RefreshRankingEntranceUi(isOpenRank)
  self:SyncFlagAnimation(false)
end

function UMG_PVPQualifier_C:SyncFlagAnimation(IsResetTrialPetData)
  local isOpenRank = self:IsOpenRank()
  if self.curFlagAnimationState ~= isOpenRank then
    if not self.bPlayingFlagAnimation then
      self.curFlagAnimationState = isOpenRank
      self.latenSyncParam = nil
      if self.curFlagAnimationState then
        self:ShowInSpineWidget(IsResetTrialPetData)
      else
        self:ShowOutSpineWidget()
      end
      self:ResetSyncFlagAnimation()
    else
      self.latenSyncParam = IsResetTrialPetData
    end
  end
end

function UMG_PVPQualifier_C:ShowOutSpineWidgetDirectly(IsResetTrialPetData)
  self:ShowOutSpineWidget()
  self.curFlagAnimationState = false
  self.latenSyncParam = nil
end

function UMG_PVPQualifier_C:ResetSyncFlagAnimation()
  if self.delay_ResetSyncFlagAnimation then
    DelayManager:CancelDelayById(self.delay_ResetSyncFlagAnimation)
  end
  self.delay_ResetSyncFlagAnimation = DelayManager:DelaySeconds(2, function()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    self.delay_ResetSyncFlagAnimation = nil
    self.bPlayingFlagAnimation = false
    if nil ~= self.latenSyncParam then
      local IsResetTrialPetData = self.latenSyncParam
      self.latenSyncParam = nil
      self:SyncFlagAnimation(IsResetTrialPetData)
    end
  end)
end

function UMG_PVPQualifier_C:CloseAnim()
  self:PlayAnimation(self.Out, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, true)
  local isOpenRank = self:IsOpenRank()
  if isOpenRank then
    self:ShowOutSpineWidgetDirectly()
  end
end

function UMG_PVPQualifier_C:OnConnected()
  if self and UE4.UObject.IsValid(self) then
    self:DoClose()
  end
end

function UMG_PVPQualifier_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_PVPQualifier_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpInfoQueryData, self.OnSetPvpInfoQueryData)
  self:RemoveButtonListener(self.btnClose.btnClose, self.OnClickBtnClose)
  self:RemoveButtonListener(self.DetailsBtn.btnLevelUp, self.OpenActivityDescription)
  self.BloodBtn.OnPressed:Remove(self, self.ExChangePressed)
  self.BloodBtn.OnReleased:Remove(self, self.ExChangeReleased)
  self.BloodBtn.OnClicked:Remove(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnClicked:Remove(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnPressed:Remove(self, self.ExChangePressed)
  self.BloodBtn_1.OnReleased:Remove(self, self.ExChangeReleased)
  self.Btn_StartUsing_1.RedDot:UnRegister()
  self.Btn_StartUsing_1.btnLevelUp.OnClicked:Remove(self, self.OnBtnOpenPetTeamUI)
  self.HistoricalRecordBtn.btnLevelUp.OnClicked:Remove(self, self.OnBtnHistoricalRecord)
  self.WeeklyRewardBtn.btnLevelUp.OnClicked:Remove(self, self.OnBtnWeeklyReward)
  self.BtnChallenge.btnLevelUp.OnClicked:Remove(self, self.OnBtnChallenge)
  self.ShopBtn.btnLevelUp.OnClicked:Remove(self, self.OnShopBtn)
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, self.RefreshMoney)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamManagementSelChanged, self.OnPetTeamManagementSelChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnPetTeamEquipPetMagic)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PlayerDataUpdate, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.UpdateSeasonStarReward, self.RefreshMoney)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.UpdateWeekReward, self.RefreshMoney)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.PlayerSettingUpdate, self.HandlePlayerSettingUpdate)
  self.SpineFlag.AnimationStart:Clear()
end

function UMG_PVPQualifier_C:ExChangePressed()
  self.Exchange:OnClickbtnPressed()
  self.Exchange_1:OnClickbtnPressed()
end

function UMG_PVPQualifier_C:ExChangeReleased()
  self.Exchange:OnClickbtnLevelReleased()
  self.Exchange_1:OnClickbtnLevelReleased()
end

function UMG_PVPQualifier_C:OnPetTeamEquipPetMagic()
  self:RefreshPetTeam()
end

function UMG_PVPQualifier_C:OnPvpPetTeamEquipPetSkills(selectedTeamIdx)
  if selectedTeamIdx then
    self:RefreshPetTeam()
  end
end

function UMG_PVPQualifier_C:OnPetTeamManagementSelChanged(selectedTeamIdx)
  if selectedTeamIdx then
    self:RefreshPetTeam()
  end
end

function UMG_PVPQualifier_C:OnPlayerDataUpdate()
  self:RefreshPetTeam()
end

function UMG_PVPQualifier_C:OnTick(deltaTime)
  if self.SpineFlag then
    self.SpineFlag:Tick(deltaTime, false)
  end
end

function UMG_PVPQualifier_C:StartDelay()
  self.delayFuncID = DelayManager:DelaySeconds(TrialFreshBrunTime, function()
    self:RefreshTime()
    self:StartDelay()
  end)
end

function UMG_PVPQualifier_C:CancelDelayFunc()
  if self.delayFuncID then
    DelayManager:CancelDelayById(self.delayFuncID)
    self.delayFuncID = nil
  end
end

function UMG_PVPQualifier_C:RefreshTime()
  if self.trialInfo then
    self:RefreshTrialTime(self.trialInfo.refresh_time or 0)
  end
end

function UMG_PVPQualifier_C:OnLogin()
end

function UMG_PVPQualifier_C:OnConstruct()
  Log.Debug("SeasonOpen Progress: [PVPQualifier]:OnConstruct")
  self.CWView_WeekendBenefitsPanel = CWView_WeekendBenefitsPanel(self)
  self.RankingEntrance.bAllowUncheckGroup = true
end

function UMG_PVPQualifier_C:OnDestruct()
  Log.Debug("SeasonOpen Progress: [PVPQualifier]:OnDestruct")
  if self.CWView_WeekendBenefitsPanel then
    self.CWView_WeekendBenefitsPanel:OnDestruct()
  else
    Log.Debug("CWView_WeekendBenefitsPanel is nil")
  end
end

function UMG_PVPQualifier_C:OnAnimationFinished(anim)
  self.CWView_WeekendBenefitsPanel:OnAnimationFinished(anim)
  if anim == self.Out then
    if self.CloseState == UMG_PVPQualifier_C.CloseStateEum.PVPRankMatch then
      _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.StartRankMatch)
      local currentMatchPvpId = self.currentMatchPvpId
      _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZoneSceneMatchStartReq, currentMatchPvpId)
      self:DoClose()
    elseif self.CloseState == UMG_PVPQualifier_C.CloseStateEum.OpenShop then
      self:OpenShopBtn()
    end
  end
end

function UMG_PVPQualifier_C:OnSpineAnimationStart(entry)
  PVPRankedMatchModuleUtils.OnFlagSpineAnimationStart(entry)
end

function UMG_PVPQualifier_C:OnSwitcherSwitcher(SwitcherIndex)
  self.Switcher:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_PVPQualifier_C:OpenPVPCuttoCallBack()
  _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.ExistPVPQualifierPanel)
  self:DoClose()
end

function UMG_PVPQualifier_C:OnClickBtnClose()
  local flag = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdClosePVPQualifierCondition)
  if not flag then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPCutto, "UMG_PVPQualifier_C", self, self.OpenPVPCuttoCallBack, true, true)
  self:Disable()
end

function UMG_PVPQualifier_C:OnClickBloodBtn()
end

function UMG_PVPQualifier_C:InitData()
  self.teamType = self.data:GetPVPQualifierTeamType()
  self:InitPetTeamData()
end

function UMG_PVPQualifier_C:InitPetTeamData()
  self.teamInfos = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(self.teamType)
  if self.teamInfos then
    self.mainTeamIdx = self.teamInfos.main_team_idx or 0
    self.teamInfosTeams = self.teamInfos.teams[self.mainTeamIdx + 1]
    if self.teamInfosTeams.is_mirror then
      self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.Visible)
      self.FriendsLineupText:SetText(string.format(LuaText.share_pet_owner_inf_1, self.teamInfosTeams.mirror_friend_name))
      self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Exchange_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Exchange_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.roleMagicGid = self.teamInfosTeams.role_magic_gid
    self.teams = self:GetPetTeams()
  else
    self.mainTeamIdx = 0
    self.teamInfosTeams = {}
    self.roleMagicGid = nil
    self.teams = self:GetPetTeams()
  end
end

function UMG_PVPQualifier_C:GetPetTeams()
  local teams = {}
  local petNum = 0
  if self.teamInfosTeams and self.teamInfosTeams.pet_infos then
    for _, pet in pairs(self.teamInfosTeams.pet_infos) do
      table.insert(teams, {
        petGid = pet.pet_gid,
        hasPet = true,
        isPlayer = true,
        teamType = self.teamType,
        teamIdx = self.mainTeamIdx,
        isMirror = self.teamInfosTeams.is_mirror,
        canClickOpenTeamReplace = true
      })
      petNum = petNum + 1
    end
  end
  local Count = #teams + 1
  for i = Count, 6 do
    table.insert(teams, {
      hasPet = false,
      isPlayer = true,
      teamType = self.teamType,
      teamIdx = self.mainTeamIdx,
      canClickOpenTeamReplace = true
    })
  end
  return teams, petNum
end

function UMG_PVPQualifier_C:RefreshUI(IsResetTrialPetData)
  self:RefreshUI_Legacy(IsResetTrialPetData)
  self:RefreshUI_FirstVictory()
  self:RefreshUI_WeekendBenefits()
end

function UMG_PVPQualifier_C:RefreshUI_Legacy(IsResetTrialPetData)
  self:RefreshPetTeam()
  local RankStar = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_STAR)
  local RankOrder = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_ORDER)
  if not RankStar or not RankOrder then
    return
  end
  if PVPRankedMatchModuleUtils.IsSelfMaxRankStar() then
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
    if curRankConf then
      self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TextQuantity_1:SetText(string.format("%d/%d", curRankConf.star_num, curRankConf.star_total))
    end
  end
  self.RankName:SetText(PVPRankedMatchModuleUtils.GetCurRankName())
  self.curSeasonId = self.data:GetCurSeasonId()
  local seasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(self.curSeasonId)
  self.Title1:SetSubtitle(seasonConf.name)
  local seasonStep = self.data:GetCurSeasonStep()
  if seasonStep == ProtoEnum.PVP_RANK_STEP.STEP_PK then
    self.Time.TimeRemaining:SetText(PVPRankedMatchModuleUtils.GetCurSeasonStepRemainTimeStr())
  elseif seasonStep == ProtoEnum.PVP_RANK_STEP.STEP_SETTLE then
    local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character10").str
    self.Time.TimeRemaining:SetText(str)
  end
  self.WeeklyRewardBtn:SetRedDot(294)
  self.AwardBtn:SetRedDot(296)
  self:RefreshMoney()
  local curWeekWinCount, requireWinCount = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurWeekWinCount)
  self.TextQuantity:SetText(string.format("%d/%d", curWeekWinCount or 0, requireWinCount or 0))
  self:RefreshTrialInfo()
  if not IsResetTrialPetData then
    self:PlayAnimation(self.In)
  end
  local isOpenRank = self:IsOpenRank()
  self:RefreshRankingEntranceUi(isOpenRank)
  self:SyncFlagAnimation(IsResetTrialPetData)
end

function UMG_PVPQualifier_C:RefreshTrialInfo()
  self.trialInfo = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBrief)
  if self.trialInfo then
    self:CancelDelayFunc()
    self:StartDelay()
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
    self:CancelDelayFunc()
    self.TrialPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVPQualifier_C:RefreshTrialAttrList(TypeList)
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
  self.AttrList:InitGridView(PetTypeList)
end

function UMG_PVPQualifier_C:RefreshTrialTime(OverTime)
  local curTime = ActivityUtils.GetSvrTimestamp()
  local remainTime = OverTime - curTime
  if remainTime > 4000 then
    self.IsGetNextQualifierData = false
    TrialFreshBrunTime = 60
  elseif remainTime < 0 and not self.IsGetNextQualifierData then
    TrialFreshBrunTime = 10
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdResetTrialPetDataReq)
  else
    self.IsGetNextQualifierData = false
    TrialFreshBrunTime = 1
  end
  self.CountDown:SetText(ActivityUtils.GetTimeFormatStr(remainTime))
end

function UMG_PVPQualifier_C:RefreshMoney()
  self.MoneyBtn:InitGridView(BattleUtils.GetPvpScoreItemInfo(self.curSeasonId))
end

function UMG_PVPQualifier_C:RefreshUI_FirstVictory()
  local bAlreadyWonToday = _G.NRCModeManager:DoCmd(_G.PVPRankedMatchModuleCmd.OnCmdIsAlreadyWonToday)
  local bHasValidAwardItemId = false
  do
    local bIsChecked = self.RankingEntrance.CheckedState == UE4.ECheckBoxState.Checked
    local currentMatchBattleType = BattleConst.PvpQualifierOpenRankCheckValueToBattleType[bIsChecked]
    local battlePvpConf = _G.NRCModuleManager:DoCmd(BattleModuleCmd.GetPvpConfByBattleType, currentMatchBattleType)
    if battlePvpConf then
      local daily_first_win_award_list = battlePvpConf and battlePvpConf.daily_first_win_award_list or {}
      if daily_first_win_award_list then
        for i = 1, #daily_first_win_award_list do
          local awardConf = daily_first_win_award_list[i]
          local itemId = awardConf and awardConf.daily_first_win_award
          if itemId and itemId > 0 then
            bHasValidAwardItemId = true
            break
          end
        end
      end
    end
  end
  local bShowFirstVictory = not bAlreadyWonToday and bHasValidAwardItemId
  self.BtnChallenge:SetupView_FirstVictory(bShowFirstVictory)
end

function UMG_PVPQualifier_C:RefreshUI_WeekendBenefits()
  self.CWView_WeekendBenefitsPanel:RefreshUI()
end

function UMG_PVPQualifier_C:ShowInSpineWidget(IsResetTrialPetData)
  if self.delay_ShowOutSpineWidget then
    DelayManager:CancelDelayById(self.delay_ShowOutSpineWidget)
    self.delay_ShowOutSpineWidget = nil
  end
  local isOpenRank = self:IsOpenRank()
  local parentCanvas = self.SpineFlag:GetParent()
  if isOpenRank then
    parentCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_FlagContent:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local bNeedPlayShow = not IsResetTrialPetData
    self:DoShowInSpineWidget(bNeedPlayShow)
    if PVPRankedMatchModuleUtils.IsSelfMaxRankStar() then
      local option = self.PVPQualifier_Star.GetDefaultStartIndexOption(6)
      self.PVPQualifier_Star:SwitcherStarIndex(option)
    else
      local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
      local starNum = curRankConf and curRankConf.star_num
      local option = self.PVPQualifier_Star.GetDefaultStartIndexOption(starNum)
      self.PVPQualifier_Star:SwitcherStarIndex(option)
    end
  else
    local parentCanvas = self.SpineFlag:GetParent()
    parentCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVPQualifier_C:DoShowInSpineWidget(bNeedPlayShow)
  local state = PVPRankedMatchModuleEnum.ETopMasterChangeState.NotTopMaster
  local pvpRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local starNum = pvpRankConf and pvpRankConf.ID or 0
  local bMaxRankStar = PVPRankedMatchModuleUtils.IsMaxRankStar(starNum)
  if bMaxRankStar then
    local TopMasterInfo = self.data:GetTopMaster()
    if self.module:CheckNewWeekLocally(true) then
      if TopMasterInfo.prev_type <= 0 then
        state = PVPRankedMatchModuleEnum.ETopMasterChangeState.Stay
      elseif TopMasterInfo.type > TopMasterInfo.prev_type then
        state = PVPRankedMatchModuleEnum.ETopMasterChangeState.Promote
      elseif TopMasterInfo.type < TopMasterInfo.prev_type then
        state = PVPRankedMatchModuleEnum.ETopMasterChangeState.Demote
      else
        state = PVPRankedMatchModuleEnum.ETopMasterChangeState.Stay
      end
    else
      state = PVPRankedMatchModuleEnum.ETopMasterChangeState.Stay
    end
  end
  if state == PVPRankedMatchModuleEnum.ETopMasterChangeState.NotTopMaster then
    local incomingGradeAnimConf = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetGradingAnimConfig, starNum)
    if bNeedPlayShow then
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
      self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
    else
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.loop, true)
    end
  elseif state == PVPRankedMatchModuleEnum.ETopMasterChangeState.Promote then
    local incomingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, true, false)
    local outgoingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, false, false)
    if bNeedPlayShow then
      self.SpineFlag:SetAnimation(0, outgoingGradeAnimConf.show, false)
      self.SpineFlag:AddAnimation(0, outgoingGradeAnimConf.upgrade, false, 1)
      self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
    else
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.loop, true)
    end
  elseif state == PVPRankedMatchModuleEnum.ETopMasterChangeState.Demote then
    local incomingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, false, false)
    local outgoingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, true, false)
    if bNeedPlayShow then
      self.SpineFlag:SetAnimation(0, outgoingGradeAnimConf.show, false)
      self.SpineFlag:AddAnimation(0, outgoingGradeAnimConf.downgrade, false, 1)
      self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
    else
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.loop, true)
    end
  else
    local TopMasterInfo = self.data:GetTopMaster()
    local bTopMaster = TopMasterInfo.type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
    local incomingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, bTopMaster, false)
    if bNeedPlayShow then
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
      self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
    else
      self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.loop, true)
    end
  end
end

function UMG_PVPQualifier_C:ShowOutSpineWidget()
  local TopMasterInfo = self.data:GetTopMaster()
  local bTopMaster = TopMasterInfo.type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
  local starNum = PVPRankedMatchModuleUtils.GetSelfRankStar()
  local incomingGradeAnimConf = self.data:GetGradingAnimConfig(starNum, bTopMaster, false)
  self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.loop, false)
  DelayManager:CancelDelayByIdEx(self.delay_ShowOutSpineWidget)
  self.delay_ShowOutSpineWidget = DelayManager:DelaySeconds(0.6, function()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.out, false)
  end)
  self.PVPQualifier_Star:PlayOutAnimation()
  self.CanvasPanel_FlagContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PVPQualifier_C:RefreshPetTeam()
  self:InitPetTeamData()
  self.PetList:InitGridView(self.teams)
  self:UpdateRoleMagicInfo()
end

function UMG_PVPQualifier_C:IsOpenRank()
  local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local pvp = playerSettings and playerSettings.pvp
  local open_rank = pvp and pvp.open_rank
  open_rank = open_rank and true or false
  return open_rank
end

function UMG_PVPQualifier_C:OpenAwardBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_PVPQualifier_C:OpenAwardBtn")
  self:Hide()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPFirstReward)
end

function UMG_PVPQualifier_C:OpenActivityDescription()
  local titleText = _G.DataConfigManager:GetLocalizationConf("PVP_rank_rule_tips_headline").msg
  local contentStr = _G.LuaText.PVP_rank_rule_tips
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnActivityDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_PVPQualifier_C:OnActivityDescDialogClosed()
end

function UMG_PVPQualifier_C:UpdateRoleMagicInfo()
  local hasMagic = false
  local petData = self.teams
  if self.teamInfosTeams.is_mirror then
    if self.teamInfosTeams.mirror_magic_id and 0 ~= self.teamInfosTeams.mirror_magic_id then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.teamInfosTeams.mirror_magic_id)
      if BagItemConf then
        hasMagic = true
        self.Switcher:SetActiveWidgetIndex(0)
        self.Icon:SetPath(BagItemConf.icon)
      end
    end
  elseif self.roleMagicGid and 0 ~= self.roleMagicGid then
    local itemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, self.roleMagicGid)
    if itemInfo then
      local PlayerMagicConf = _G.DataConfigManager:GetBagItemConf(itemInfo.id)
      if PlayerMagicConf then
        hasMagic = true
        self.Switcher:SetActiveWidgetIndex(0)
        self.Icon:SetPath(PlayerMagicConf.icon)
      end
    end
  end
  if not hasMagic then
    self.Switcher:SetActiveWidgetIndex(1)
  end
end

function UMG_PVPQualifier_C:OnBtnOpenMagicBag()
  local teamData = self.teamInfosTeams
  if teamData.is_mirror then
    if teamData.role_magic_gid then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodMagicTips, self.teamInfosTeams)
    end
  else
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    if BagItemS and #BagItemS > 0 then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodLineMagic, self.teamType, self.mainTeamIdx)
    else
      local Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_tips1")
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Conf.str)
    end
  end
end

function UMG_PVPQualifier_C:OnBtnOpenPetTeamUI()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PVPQualifier_C:OnBtnOpenPetTeamUI")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetTeamPanel, self.teamType)
end

function UMG_PVPQualifier_C:OnBtnChallenge()
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.PVPRankClickChallenge)
  if self.data:IsSeasonStepSettle() then
    local BattleGlobalCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character14")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, BattleGlobalCfg.str)
    return
  end
  local curTeams, curPetNum = self:GetPetTeams()
  if 0 == curPetNum then
    local BattleGlobalCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character2")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, BattleGlobalCfg.str)
    return
  end
  do
    local petInfoList = self.teamInfosTeams and self.teamInfosTeams.pet_infos or {}
    local isMirror = self.teamInfosTeams.is_mirror
    local isBanFantasticSkillInRankPvp = BattleUtils.IsBanFantasticSkillInRankPvp(self.teamType)
    if isBanFantasticSkillInRankPvp then
      local anySkillIsFantastic = PetUtils.IsAnyPetInfoEquippedFantasticSkill(petInfoList, isMirror)
      if anySkillIsFantastic then
        local errorCodeKey = "Error_Code_2631"
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[errorCodeKey], nil, nil, 2)
        return
      end
    end
  end
  if curPetNum < 6 then
    local title = _G.LuaText.TIPS
    local des = LuaText.umg_pvp_matching_9
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.ConfirmCancelPopup):SetCloseOnCancel(true):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.BACK)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    return
  end
  self:TryPVPRankMatch()
end

function UMG_PVPQualifier_C:ConfirmCancelPopup(bCancel)
  if bCancel then
    self:TryPVPRankMatch()
  end
end

function UMG_PVPQualifier_C:TryPVPRankMatch()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.RankMatchRecoverCamera)
  self:CloseAnim()
  self.CloseState = UMG_PVPQualifier_C.CloseStateEum.PVPRankMatch
end

function UMG_PVPQualifier_C:OnBtnWeeklyReward()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPDailyChallenge)
end

function UMG_PVPQualifier_C:OpenShopBtn()
  local curSeasonId = self.curSeasonId
  local seasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(curSeasonId, true)
  local shopId = seasonConf and seasonConf.shop or BattleConst.PvpDefaultShopId
  self:Hide()
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.SetNpcShopOpenType, NPCShopUIModuleEnum.OpenNPCShopFormType.PvpQualifier)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.FinishNPCActionOpenShop, nil, shopId)
end

function UMG_PVPQualifier_C:OnShopBtn()
  self.CloseState = UMG_PVPQualifier_C.CloseStateEum.OpenShop
  self:CloseAnim()
end

function UMG_PVPQualifier_C:Hide()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PVPQualifier_C:Show()
  self:UpdateRoleMagicInfo()
  self:SyncFlagAnimation(false)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:TrySendZonePvpInfoQueryReq()
end

function UMG_PVPQualifier_C:TryReshow()
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self:Show()
  end
end

function UMG_PVPQualifier_C:OnBtnHistoricalRecord()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.TryOpenPVPHistoricalRecord)
end

function UMG_PVPQualifier_C:RefreshRankingEntranceUi(nextIsChecked)
  local prevIsChecked = self.isRankingEntranceChecked
  if prevIsChecked == nextIsChecked then
    return
  end
  self.isRankingEntranceChecked = nextIsChecked
  self.isSettingRankingEntranceState = true
  self.RankingEntrance:SetIsChecked(nextIsChecked)
  self.isSettingRankingEntranceState = false
  self:OnIsRankingEntranceCheckedChanged(prevIsChecked, nextIsChecked)
end

function UMG_PVPQualifier_C:OnIsRankingEntranceCheckedChanged(prevIsChecked, nextIsChecked)
  local currentMatchBattleType
  if nil ~= nextIsChecked then
    currentMatchBattleType = BattleConst.PvpQualifierOpenRankCheckValueToBattleType[nextIsChecked]
  end
  local battlePvpConf = _G.NRCModuleManager:DoCmd(BattleModuleCmd.GetPvpConfByBattleType, currentMatchBattleType)
  local matchPvpId = battlePvpConf and battlePvpConf.id
  if not matchPvpId then
    Log.Error("UMG_PVPQualifier_C:OnIsRankingEntranceCheckedChanged failed to calculate next match PVP_CONF id")
  end
  self:SetCurrentMatchPvpId(matchPvpId)
end

function UMG_PVPQualifier_C:SetCurrentMatchPvpId(nextMatchPvpId)
  local prevMatchPvpId = self.currentMatchPvpId
  self.currentMatchPvpId = nextMatchPvpId
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.SetCurMatchPvpId, nextMatchPvpId)
end

function UMG_PVPQualifier_C:OnRankingEntranceCheckStateChangeChanged(GroupId, CheckBoxName)
  if not self.isSettingRankingEntranceState then
    local nextIsChecked = self.RankingEntrance.CheckedState == UE4.ECheckBoxState.Checked
    self:HandleRankingEntranceCheckStateChanged(nextIsChecked)
  end
end

function UMG_PVPQualifier_C:HandleRankingEntranceCheckStateChanged(nextState)
  local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local nextPlayerSettings = {}
  if playerSettings then
    table.copy(playerSettings, nextPlayerSettings)
  end
  local prevPvp = playerSettings and playerSettings.pvp
  local prevOpenRank = prevPvp and prevPvp.open_rank
  local nextPvp = {}
  if prevPvp then
    table.copy(prevPvp, nextPvp)
  end
  local nextOpenRank = not prevOpenRank
  nextPvp.open_rank = nextOpenRank
  nextPlayerSettings.pvp = nextPvp
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, nextPlayerSettings)
end

function UMG_PVPQualifier_C:OnRankingEnhanceCheckBoxIsClickable(GroupId, CheckBoxName, IsClickable)
end

function UMG_PVPQualifier_C:StartLoadSpineAsset()
  local seasonId = self.data:GetCurSeasonId()
  local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local atlasPath, skeletonDataPath = PVPRankedMatchModuleUtils.GetSpineAssetPathsSeasonIdInRankConf(curRankConf, seasonId)
  if atlasPath == self.atlasPath and skeletonDataPath == self.skeletonDataPath then
    self:OnLoadSpineAssetComplete(false, "same path")
    return
  end
  if atlasPath and skeletonDataPath then
    local atlasAsset, skeletonAsset
    local isReady = false
    
    local function checkAssetReady()
      if isReady then
        return
      end
      if UE.UObject.IsValid(atlasAsset) and UE.UObject.IsValid(skeletonAsset) then
        isReady = true
        self.atlasPath = atlasPath
        self.skeletonDataPath = skeletonDataPath
        self:OnLoadSpineAssetComplete(true, atlasAsset, skeletonAsset)
      end
    end
    
    self:LoadPanelRes(atlasPath, 255, function(caller, resRequest, asset)
      atlasAsset = asset
      checkAssetReady()
    end, function()
      self:OnLoadSpineAssetComplete(false, "failed to load atlas data")
    end, nil)
    self:LoadPanelRes(skeletonDataPath, 255, function(caller, resRequest, asset)
      skeletonAsset = asset
      checkAssetReady()
    end, function()
      self:OnLoadSpineAssetComplete(false, "failed to load skeleton data")
    end, nil)
  else
    self:OnLoadSpineAssetComplete(false, "failed to fetch asset path")
  end
end

function UMG_PVPQualifier_C:OnLoadSpineAssetComplete(ok, res1, res2)
  if ok then
    local atlasAsset = res1
    local skeletonAsset = res2
    self:SetupSpineWidget(atlasAsset, skeletonAsset)
  else
    local errorMessage = res1
    Log.Error("[UMG_PVPQualifier_C]", errorMessage)
  end
  self:StartRefreshUi(self.IsResetTrialPetData)
end

function UMG_PVPQualifier_C:SetupSpineWidget(atlasAsset, skeletonAsset)
  local spineWidget = self.SpineFlag
  spineWidget:ClearTrack(0)
  spineWidget.skeletondata = skeletonAsset
  spineWidget.atlas = atlasAsset
  spineWidget:LuaSynchronizeProperties()
end

return UMG_PVPQualifier_C
