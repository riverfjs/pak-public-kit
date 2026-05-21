local rapidjson = require("rapidjson")
local AICoachModuleUtils = require("NewRoco.Modules.System.AICoachModule.AICoachModuleUtils")
local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local UMG_LineupAdjustment_C = _G.NRCPanelBase:Extend("UMG_LineupAdjustment_C")
local LostType = {
  Magic = 1,
  Pet = 2,
  Skill = 3
}
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")

function UMG_LineupAdjustment_C:OnActive(rsp, OpenAdjustTeamType, OpenAdjustTeamIndex)
  self:OnAddEventListener()
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_LineupAdjustment_C:OnActive")
  self:RefreshPanel(rsp, OpenAdjustTeamType, OpenAdjustTeamIndex)
  self:OnInitAICoachShowUI()
end

function UMG_LineupAdjustment_C:OnInitAICoachShowUI()
  local AICoachTeamData = self.module:GetData():GetAICoachRecommendTeamUIData()
  local isAICoachOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsCurrAICoachOpen)
  local isAIInWhiteList = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsPlayerInWhiteList)
  local isSystemOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetSysAICoachSceneIsOpen, Enum.FunctionEntrance.FE_AI_COACH_TEAM)
  local isAllOpen = isAICoachOpen and isAIInWhiteList and isSystemOpen
  self.isOpenFromAICoach = false
  self.isNeedEnterAnim = false
  self.AIEmotionType = nil
  self.NRCText_166:SetText(LuaText.ai_coach_18)
  if isAllOpen and AICoachTeamData and AICoachTeamData.teamData and AICoachTeamData.activityID then
    _G.NRCModeManager:DoCmd(AICoachModuleCmd.OnOpenAICoachBySceneTypeWithoutSession, Enum.AIcoachSceneType.AST_Group_Detail)
    self.isOpenFromAICoach = true
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_expo")
    self.AICoachGvoice:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Progress:SetPercent(0)
    self.isNeedEnterAnim = true
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnRecoverSceneAICoachState, Enum.AIcoachSceneType.AST_Group_Recommend)
  else
    self.AICoachGvoice:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LineupAdjustment_C:RefreshPanel(rsp, OpenAdjustTeamType, OpenAdjustTeamIndex)
  if rsp then
    self.petData = rsp.adjusted_team.pets
    self.shared_team = rsp.shared_team
    self.sharedPetData = rsp.shared_team.pets
    self.teamType = OpenAdjustTeamType
    self.magicID = rsp.shared_team.role_magic_id
    self.oldMagicID = self.magicID
    self.IgnoreList = {}
    self.LostDataList = {}
    self.OpenAdjustTeamType = OpenAdjustTeamType
    self.OpenAdjustTeamIndex = OpenAdjustTeamIndex
    do
      local adjustedTeam = rsp and rsp.adjusted_team
      local sharedTeam = rsp and rsp.shared_team
      _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OnCmdDistributeGidForRandomPetInAdjustedAndSharedTeam, adjustedTeam, sharedTeam)
    end
    if -1 == OpenAdjustTeamIndex then
      self.SaveBtn:SetBtnText(_G.DataConfigManager:GetLocalizationConf("weekend_challenge_5").msg)
      self.RenameBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:GetTeamName(self.module:GetData():GetShiningWeekendTeamName())
      self.NRCScaleBox_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self:GetTeamName(rsp.shared_team.team_name)
    end
    self.SaveBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DiffList = {}
    self:CalculateExchangeInfo()
    local fullPetData = {}
    for i, data in ipairs(self.sharedPetData) do
      fullPetData[i] = {}
      fullPetData[i].sharedPetData = data
      fullPetData[i].petData = self.petData[i]
      if 0 ~= fullPetData[i].petData.gid then
        fullPetData[i].petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(fullPetData[i].petData.gid)
      end
      fullPetData[i].oldPetData = table.deepCopy(fullPetData[i].petData)
      fullPetData[i].teamType = self.teamType
    end
    self.fullPetData = fullPetData
    self:UpdateUIData()
    for i, data in ipairs(self.sharedPetData) do
      fullPetData[i].PetGidList = self:InitPetGidList()
      fullPetData[i].checkTalentList = self.checkTalentList[i]
      fullPetData[i].checkNatureList = self.checkNatureList[i]
      fullPetData[i].needBloodItemList = self.needBloodItemList[i]
    end
    self:SetCommonTitle()
    self:UpdateUI()
    self.id = UE4.UNRCStatics.ClipboardPaste()
    self:SendTLog(rsp.shared_team)
  end
end

function UMG_LineupAdjustment_C:GetTeamName(teamName)
  self.teamName = teamName
  if teamName and "" ~= teamName then
    return
  end
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, self.OpenAdjustTeamType)
  local TeamIndex = self.OpenAdjustTeamIndex + 1
  local CurPetTeam = teamInfo.teams[TeamIndex]
  if self.OpenAdjustTeamType ~= Enum.PlayerTeamType.PTT_BIG_WORLD then
    if not CurPetTeam.team_name or "" == CurPetTeam.team_name then
      local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
      self.teamName = string.format(teamNameCfg.str, TeamIndex)
    else
      self.teamName = CurPetTeam.team_name
    end
  else
    local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
    if CurPetTeam.team_name then
      self.teamName = CurPetTeam.team_name
    else
      self.teamName = string.format(default_name, TeamIndex)
    end
  end
end

function UMG_LineupAdjustment_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnReconnect)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ChangeTeamMagic, self.ChangeTeamMagic)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ChangePetSkill, self.ChangePetSkill)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.RefreshAdjustPetPanel, self.RefreshAdjustPetPanel)
  if self.isOpenFromAICoach then
    _G.NRCModeManager:DoCmd(AICoachModuleCmd.OnCloseAICoachByScene, Enum.AIcoachSceneType.AST_Group_Detail)
  end
  self.module:GetData():SetAICoachRecommendTeamUIData({})
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnNotifyAICoachNarrationTextUpdate, self.OnNotifyAICoachTextUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnNotifyAICoachTextUpdate, self.OnNotifyAICoachTextUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnNotifyAICoachEmotionChange, self.OnNotifyAICoachEmotionChange)
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnNotifyAICoachRequestFinish, self.OnNotifyAICoachRequestFinish)
end

function UMG_LineupAdjustment_C:SolveDeficiencyBtnClick()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenShareTeamDiffOrLackPanel, 2)
end

function UMG_LineupAdjustment_C:SolveDifferencesBtnClick()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenShareTeamDiffOrLackPanel, 1)
end

function UMG_LineupAdjustment_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.Btn_SolveDeficiency.btnLevelUp, self.SolveDeficiencyBtnClick)
  self:AddButtonListener(self.Btn_SolveDifferences.btnLevelUp, self.SolveDifferencesBtnClick)
  self:AddButtonListener(self.RevertButton.btnLevelUp, self.OnReverBtnClick)
  self:AddButtonListener(self.SaveBtn.btnLevelUp, self.OnSaveBtnClick)
  self:AddButtonListener(self.RenameBtn.btnLevelUp, self.Rename)
  self:AddButtonListener(self.MagicBtn, self.OpenAlternativeMagic)
  self:AddButtonListener(self.BtnTimePet, self.OnOpenAICoachRequest)
  self:RegisterEvent(self, PetUIModuleEvent.SetShareTeamName, self.SetShareTeamName)
  self:RegisterEvent(self, PetUIModuleEvent.AdjustLostPet, self.AdjustLostPet)
  self:RegisterEvent(self, PetUIModuleEvent.SetIgnoreType, self.SetIgnoreTypeAndUpdate)
  self:RegisterEvent(self, PetUIModuleEvent.PetShareTeamIgnoreAllDiffType, self.IgnoreAllDiffType)
  self:RegisterEvent(self, PetUIModuleEvent.OpenPetShareTeamSolveAllTypePanel, self.OpenSolveAllDiffTypePanel)
  self:RegisterEvent(self, PetUIModuleEvent.OpenShareTeamDetailsDifferencesPanel, self.OpenDetailsDifferencesPanel)
  self:RegisterEvent(self, PetUIModuleEvent.SolveAllDiffType, self.SolveAllDiffType)
  self:RegisterEvent(self, PetUIModuleEvent.SolveAllLostType, self.SolveAllLostType)
  self:RegisterEvent(self, PetUIModuleEvent.ChangeWorldTeamSuccess, self.OnSaveSucc)
  self:RegisterEvent(self, PetUIModuleEvent.AutoSolveLostData, self.AutoSolveLostData)
  self:RegisterEvent(self, PetUIModuleEvent.OpenQuickLearnAllLostSkillPanel, self.OpenQuickLearnAllLostSkillPanel)
  self:RegisterEvent(self, PetUIModuleEvent.ShowSolveSuccTips, self.ShowSolveSuccTips)
  self:RegisterEvent(self, PetUIModuleEvent.OnShiningWeekendPetChangeClose, self.OnPetChangeClose)
  NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, PetUIModuleEvent.RefreshAdjustPetPanel, self.RefreshAdjustPetPanel)
  NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, PetUIModuleEvent.ChangeTeamMagic, self.ChangeTeamMagic)
  NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, PetUIModuleEvent.ChangePetSkill, self.ChangePetSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnReconnect)
  _G.NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, AICoachModuleEvent.OnNotifyAICoachNarrationTextUpdate, self.OnNotifyAICoachTextUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, AICoachModuleEvent.OnNotifyAICoachTextUpdate, self.OnNotifyAICoachTextUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, AICoachModuleEvent.OnNotifyAICoachEmotionChange, self.OnNotifyAICoachEmotionChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LineupAdjustment_C", self, AICoachModuleEvent.OnNotifyAICoachRequestFinish, self.OnNotifyAICoachRequestFinish)
end

function UMG_LineupAdjustment_C:_OnReconnect()
  self:OnClickCloseBtn()
end

function UMG_LineupAdjustment_C:SetCommonTitle()
  if -1 == self.OpenAdjustTeamIndex then
    local titleConf = _G.DataConfigManager:GetTitleConf("RecommendedLineup2")
    self.Title1:SetBaseInfo(titleConf.head_icon, titleConf.subtitle[1].subtitle, titleConf.title)
  else
    self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
    self.Title1:Set_MainTitle(self.titleConf.title)
    self.Title1:SetBg(self.titleConf.head_icon)
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_LineupAdjustment_C:UpdateDiffAndLackNum()
  local ButtonInfoList = {}
  local DiffNum = 0
  local LostNum = 0
  DiffNum = (self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Talent] or 0) + (self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Nature] or 0) + (self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Blood] or 0)
  local DiffData = {
    moneyType = 1,
    sum = DiffNum,
    IsShareButton = true
  }
  self.DiffNum = DiffNum
  table.insert(ButtonInfoList, DiffData)
  LostNum = (self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] or 0) + (self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] or 0) + (self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] or 0)
  local LostData = {
    moneyType = 2,
    sum = LostNum,
    IsShareButton = true
  }
  self.LostNum = LostNum
  self.Btn_SolveDeficiency:SetVisibility(self.LostNum > 0 and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Btn_SolveDifferences:SetVisibility(self.DiffNum > 0 and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if self.LostNum > 0 and self.DiffNum > 0 then
    self.Spacer_221:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Spacer_221:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Btn_SolveDeficiency:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.lineup_code_pending, LostNum, "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_ExclamationMark_png.img_ExclamationMark_png'")
  self.Btn_SolveDifferences:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.lineup_code_pending, DiffNum, "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_QuestionMark_png.img_QuestionMark_png'")
  table.insert(ButtonInfoList, LostData)
end

function UMG_LineupAdjustment_C:GetChangeAttrForReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

function UMG_LineupAdjustment_C:GetChangeAttrToReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX_PERCENT then
    return Enum.AttributeType.AT_HPMAX
  elseif attribute == Enum.AttributeType.AT_PHYATK_PERCENT then
    return Enum.AttributeType.AT_PHYATK
  elseif attribute == Enum.AttributeType.AT_SPEATK_PERCENT then
    return Enum.AttributeType.AT_SPEATK
  elseif attribute == Enum.AttributeType.AT_PHYDEF_PERCENT then
    return Enum.AttributeType.AT_PHYDEF
  elseif attribute == Enum.AttributeType.AT_SPEDEF_PERCENT then
    return Enum.AttributeType.AT_SPEDEF
  elseif attribute == Enum.AttributeType.AT_SPEED_PERCENT then
    return Enum.AttributeType.AT_SPEED
  end
end

function UMG_LineupAdjustment_C:CheckHasPetTalentData()
  self.checkTalentList = {}
  local DiffNum = 0
  for i, fullPetData in ipairs(self.fullPetData) do
    local v = fullPetData.petData
    local checkList = {}
    local CurPetAttributeList = {}
    local curPetAttrNum = 0
    if v.gid and v.gid > 0 and not v.AdjustCompleted then
      local sharedPetData = fullPetData.sharedPetData
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
      if sharedPetData.attack_talent and 0 ~= sharedPetData.attack_talent then
        if petData and petData.attribute_info.attack.talent and petData.attribute_info.attack.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_PHYATK_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.attack.talent and petData.attribute_info.attack.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_PHYATK_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
      if sharedPetData.defense_talent and 0 ~= sharedPetData.defense_talent then
        if petData and petData.attribute_info.defense.talent and petData.attribute_info.defense.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_PHYDEF_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.defense.talent and petData.attribute_info.defense.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_PHYDEF_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
      if sharedPetData.hp_talent and 0 ~= sharedPetData.hp_talent then
        if petData and petData.attribute_info.hp.talent and petData.attribute_info.hp.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_HPMAX_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.hp.talent and petData.attribute_info.hp.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_HPMAX_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
      if sharedPetData.special_attack_talent and 0 ~= sharedPetData.special_attack_talent then
        if petData and petData.attribute_info.special_attack.talent and petData.attribute_info.special_attack.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_SPEATK_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.special_attack.talent and petData.attribute_info.special_attack.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_SPEATK_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
      if sharedPetData.special_defense_talent and 0 ~= sharedPetData.special_defense_talent then
        if petData and petData.attribute_info.special_defense.talent and petData.attribute_info.special_defense.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_SPEDEF_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.special_defense.talent and petData.attribute_info.special_defense.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_SPEDEF_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
      if sharedPetData.speed_talent and 0 ~= sharedPetData.speed_talent then
        if petData and petData.attribute_info.speed.talent and petData.attribute_info.speed.talent > 0 then
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = true,
            attribute = Enum.AttributeType.AT_SPEED_PERCENT,
            type = 1
          })
          curPetAttrNum = curPetAttrNum + 1
        else
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent][Enum.AttributeType.AT_SPEED_PERCENT]
          if not IsIgnore then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasTalent = false,
            attribute = Enum.AttributeType.AT_SPEED_PERCENT,
            type = 1,
            IsIgnore = IsIgnore
          })
        end
      elseif petData and petData.attribute_info.speed.talent and petData.attribute_info.speed.talent > 0 then
        table.insert(CurPetAttributeList, Enum.AttributeType.AT_SPEED_PERCENT)
        curPetAttrNum = curPetAttrNum + 1
      end
    end
    local NewCheckList = {}
    local curMatchIndex = 1
    for j = 1, #checkList do
      if not checkList[j].HasTalent then
        if checkList[j].IsIgnore then
          if CurPetAttributeList[curMatchIndex] then
            checkList[j].cur_attribute = CurPetAttributeList[curMatchIndex]
            curMatchIndex = curMatchIndex + 1
            table.insert(NewCheckList, checkList[j])
          end
        else
          table.insert(NewCheckList, checkList[j])
        end
      else
        table.insert(NewCheckList, checkList[j])
      end
    end
    local NewCheckListNum = #NewCheckList
    if curPetAttrNum > NewCheckListNum then
      for k = 1, curPetAttrNum - NewCheckListNum do
        for CurPetIndex = 1, #CurPetAttributeList do
          local find = false
          NewCheckListNum = #NewCheckList
          for CheckListIndex = 1, NewCheckListNum do
            if NewCheckList[CheckListIndex].cur_attribute == CurPetAttributeList[CurPetIndex] then
              find = true
            end
          end
          if not find then
            table.insert(NewCheckList, {
              gid = v.gid,
              HasTalent = true,
              cur_attribute = CurPetAttributeList[CurPetIndex],
              attribute = CurPetAttributeList[CurPetIndex],
              type = 1
            })
            break
          end
        end
      end
    end
    table.insert(self.checkTalentList, {
      gid = v.gid,
      checkList = NewCheckList
    })
    self.fullPetData[i].checkTalentList = self.checkTalentList[i]
  end
  self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Talent] = DiffNum
end

function UMG_LineupAdjustment_C:CheckHasPetNatureData()
  self.checkNatureList = {}
  local DiffNum = 0
  for i, fullPetData in ipairs(self.fullPetData) do
    local v = fullPetData.petData
    local checkList = {}
    if v.gid and v.gid > 0 and not v.AdjustCompleted then
      local sharedPetData = fullPetData.sharedPetData
      local SharePetNatureConf = _G.DataConfigManager:GetNatureConf(sharedPetData.nature)
      if SharePetNatureConf then
        local share_pos_effect = SharePetNatureConf.positive_effect
        local share_neg_effect = SharePetNatureConf.negative_effect
        if self.sharedPetData[i].changed_nature_pos_attr_type and self.sharedPetData[i].changed_nature_pos_attr_type > 0 then
          share_pos_effect = self:GetChangeAttrForReqEnum(self.sharedPetData[i].changed_nature_pos_attr_type)
        end
        if self.sharedPetData[i].changed_nature_neg_attr_type and self.sharedPetData[i].changed_nature_neg_attr_type > 0 then
          share_neg_effect = self:GetChangeAttrForReqEnum(self.sharedPetData[i].changed_nature_neg_attr_type)
        end
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
        if petData then
          local PetNatureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
          local pos_effect = PetNatureConf.positive_effect
          local neg_effect = PetNatureConf.negative_effect
          if petData.changed_nature_pos_attr_type and petData.changed_nature_pos_attr_type > 0 then
            pos_effect = self:GetChangeAttrForReqEnum(petData.changed_nature_pos_attr_type)
          end
          if petData.changed_nature_neg_attr_type and petData.changed_nature_neg_attr_type > 0 then
            neg_effect = self:GetChangeAttrForReqEnum(petData.changed_nature_neg_attr_type)
          end
          local HasNature = share_pos_effect == pos_effect and share_neg_effect == neg_effect
          local IsIgnore = self.IgnoreList[v.gid] and self.IgnoreList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Nature]
          if not IsIgnore and not HasNature then
            DiffNum = DiffNum + 1
          end
          table.insert(checkList, {
            gid = v.gid,
            HasNature = HasNature,
            share_pos_effect = share_pos_effect,
            share_neg_effect = share_neg_effect,
            pos_effect = pos_effect,
            neg_effect = neg_effect,
            natureName = SharePetNatureConf.name,
            type = 0,
            IsIgnore = IsIgnore
          })
        else
          Log.Error("UMG_LineupAdjustment_C gid petData is nil", v.gid)
        end
      else
        Log.Error("UMG_LineupAdjustment_C SharePetNatureConf is nil, notice jobhuang")
      end
    end
    table.insert(self.checkNatureList, {
      gid = v.gid,
      checkList = checkList
    })
    self.fullPetData[i].checkNatureList = self.checkNatureList[i]
  end
  self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Nature] = DiffNum
end

function UMG_LineupAdjustment_C:UpdateUI()
  self:SetMagicUI()
  self.Text_1:SetText(self.teamName)
  self:UpdateDiffAndLackNum()
  local PetList = {}
  if self.teamType ~= Enum.PlayerTeamType.PTT_PVP_BATTLE_5 then
    if #self.fullPetData < 6 then
      for i = 1, 6 do
        if self.fullPetData[i] then
          PetList[i] = self.fullPetData[i]
        else
          PetList[i] = {}
        end
      end
    else
      PetList = self.fullPetData
    end
  elseif #self.fullPetData < 3 then
    for i = 1, 3 do
      if self.fullPetData[i] then
        PetList[i] = self.fullPetData[i]
      else
        PetList[i] = {}
      end
    end
  else
    PetList = self.fullPetData
  end
  self.NRCGridView_54:InitGridView(PetList)
  for i, gid in pairs(self.fullPetData[1].PetGidList) do
    NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetBagUIItemUpdateUI, gid)
  end
  if -1 == self.OpenAdjustTeamIndex and not self.bSendTLog3 then
    self:SendTLog3(PetList)
    self.bSendTLog3 = true
  end
end

function UMG_LineupAdjustment_C:InitPetGidList()
  local PetGidList = {}
  for i, fullpetdata in ipairs(self.fullPetData) do
    if 0 ~= fullpetdata.petData.gid then
      table.insert(PetGidList, fullpetdata.petData.gid)
    end
  end
  return PetGidList
end

function UMG_LineupAdjustment_C:TryOpenShareTeamDiffPanel()
  if self.DiffNum and self.DiffNum > 0 then
    self.module:OpenShareTeamDiffPanel(self.DiffNum, self.DiffList)
  end
end

function UMG_LineupAdjustment_C:TryOpenShareTeamLackPanel()
  if self.LostNum and self.LostNum > 0 then
    self.module:OpenShareTeamLackPanel(nil, nil, self.LostNum, self.LostDataList)
  end
end

function UMG_LineupAdjustment_C:OpenRevisePanelByType(type, data)
  if type == PetUIModuleEnum.PetTeamShareReviseType.Talent then
    for i, v in ipairs(self.checkTalentList) do
      if v.gid and v.gid == data.gid then
        local ChangeType = data.type
        local checkList = v.checkList
        local NeedHideType = {}
        for _, k in ipairs(checkList) do
          if k.attribute ~= ChangeType and k.HasTalent then
            table.insert(NeedHideType, k.attribute)
          end
        end
        self.module:OpenTeamShareReviseTalentPanel(ChangeType, NeedHideType, data.gid)
        break
      end
    end
  end
  if type == PetUIModuleEnum.PetTeamShareReviseType.Nature then
    for i, v in ipairs(self.checkNatureList) do
      if v.gid and v.gid == data.gid then
        self.module:OpenTeamShareReviseNaturePanel(data, data.gid)
        break
      end
    end
  end
end

function UMG_LineupAdjustment_C:ClosePanel()
  if self.bCloseFromUse then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("weekend_challenge_10").msg)
  end
  self:OnClose()
  self.BackgroundCapture:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LineupAdjustment_C:OnClickCloseBtn()
  self:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_LineupAdjustment_C:OnClickCloseBtn")
end

function UMG_LineupAdjustment_C:OnReverBtnClick()
  local dialogContext = DialogContext()
  dialogContext:SetTitle(LuaText.TIPS):SetForceEnableFullScreenBtn(true)
  dialogContext:SetContent(LuaText.lineup_code_restore):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel):SetCloseOnCancel(true):SetCallback(self, self.ReverBtnCallBack)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
end

function UMG_LineupAdjustment_C:ReverBtnCallBack()
  if not self.fullPetData then
    Log.Error("\229\156\168\231\130\185\229\135\187\232\191\152\229\142\159\231\154\132\230\151\182\229\128\153\231\188\186\229\176\145fullPetData\239\188\140\232\175\183\229\145\138\231\159\165jobhuang\230\152\175\230\128\142\228\185\136\229\135\186\231\142\176\231\154\132")
    return
  end
  for i, data in ipairs(self.fullPetData) do
    self.fullPetData[i].petData = table.deepCopy(self.fullPetData[i].oldPetData)
    self.fullPetData[i].petData.AdjustCompleted = false
  end
  for i, data in ipairs(self.fullPetData) do
    self.fullPetData[i].PetGidList = self:InitPetGidList()
  end
  self.magicID = self.oldMagicID
  self.IgnoreList = {}
  self:RefreshAdjustPetPanel()
end

function UMG_LineupAdjustment_C:OnSave()
  local teams = {}
  local fullPetData = self.fullPetData or {}
  if fullPetData then
    for i, fullPetDataItem in ipairs(fullPetData) do
      local petData = fullPetDataItem and fullPetDataItem.petData
      local petGid = petData and petData.gid
      if 0 ~= petGid then
        local teamPetInfo = _G.ProtoMessage:newPetTeam_PetInfo()
        local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
        teamPetInfo.pet_gid = petGid
        local skills = petData and petData.skills or {}
        for j, skillData in pairs(skills) do
          local PetSkillEquipInfo = _G.ProtoMessage:newPetSkillEquipInfo()
          PetSkillEquipInfo.id = skillData.id
          PetSkillEquipInfo.pos = skillData.pos
          if 0 ~= skillData.id then
            table.insert(teamPetInfo.equip_infos, PetSkillEquipInfo)
          end
        end
        table.insert(teams, teamPetInfo)
      end
    end
  end
  if self.magicID then
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    local magicGid
    local findMagicFlag = false
    for index, BagItem in pairs(BagItemS) do
      if BagItem.id == self.magicID then
        findMagicFlag = true
        magicGid = BagItem.gid
      end
    end
    if findMagicFlag then
      teams.magicID = magicGid
    end
  end
  if self.OpenAdjustTeamType == Enum.PlayerTeamType.PTT_BIG_WORLD then
    local AllChangeTeam = {}
    local AllChangeTeamIndex = {}
    table.insert(AllChangeTeam, teams)
    table.insert(AllChangeTeamIndex, self.OpenAdjustTeamIndex)
    local RemoveTeamIndex = {}
    local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
    local PetGidList = self:InitPetGidList()
    if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
      for j, team in ipairs(PetTeams.teams) do
        if j - 1 ~= self.OpenAdjustTeamIndex then
          local gid = PetUtils.PetTeamGetPetGidList(team)
          local PetRemoveGid = {}
          local HasRemove = false
          if gid then
            for _, v in ipairs(gid) do
              local HasFind = false
              for i = 1, #PetGidList do
                if v == PetGidList[i] then
                  HasRemove = true
                  HasFind = true
                  break
                end
              end
              if not HasFind then
                table.insert(PetRemoveGid, v)
              end
            end
            if HasRemove then
              table.insert(RemoveTeamIndex, PetRemoveGid)
              table.insert(AllChangeTeamIndex, j - 1)
            end
          end
        end
      end
    end
    for i, v in ipairs(RemoveTeamIndex) do
      local PetRemoveGid = v
      local _teams = {}
      for j, gid in ipairs(PetRemoveGid) do
        local teamPetInfo = _G.ProtoMessage:newPetTeam_PetInfo()
        teamPetInfo.pet_gid = gid
        table.insert(_teams, teamPetInfo)
      end
      table.insert(AllChangeTeam, _teams)
    end
    if AllChangeTeam and AllChangeTeam[1] and #AllChangeTeam[1] > 0 then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamsInfo, AllChangeTeam, AllChangeTeamIndex, Enum.PlayerTeamType.PTT_BIG_WORLD, nil, {
        self.teamName
      })
      self:OnClose()
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_no_available_pet)
    end
  elseif teams and #teams > 0 then
    if self.bSendTLog2 then
      self:SendTLog2(teams, self.OpenAdjustTeamType, self.teamName)
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamInfo, teams, self.OpenAdjustTeamIndex, self.OpenAdjustTeamType, self.teamName)
    self:OnClose()
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_no_available_pet)
  end
end

function UMG_LineupAdjustment_C:OnSaveBtnClick()
  if -1 == self.OpenAdjustTeamIndex then
    if self.LostNum > 0 then
      local Context = DialogContext()
      local ContentText = string.format(LuaText.lineup_code_save_hint, self.LostNum)
      Context:SetTitle(LuaText.umg_shop_tips_8):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnOpenImportLineup):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    else
      self:OnOpenImportLineup()
    end
  elseif self.LostNum > 0 then
    local Context = DialogContext()
    local ContentText = string.format(LuaText.lineup_code_save_hint, self.LostNum)
    Context:SetTitle(LuaText.umg_shop_tips_8):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnSave):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    self:OnSave()
  end
end

function UMG_LineupAdjustment_C:IsCurrAICoachSceneTypeMatch()
  local sceneType = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetCurrAICoachScene)
  return sceneType == Enum.AIcoachSceneType.AST_Group_Detail
end

function UMG_LineupAdjustment_C:OnNotifyAICoachTextUpdate(text)
  if not self:IsCurrAICoachSceneTypeMatch() then
    return
  end
  if self.isNeedEnterAnim then
    self:PlayAnimation(self.AICoach_Open)
    self.TextPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.isNeedEnterAnim = false
  end
  self.ChatContent:SetText(text)
end

function UMG_LineupAdjustment_C:OnAnimFinished(Animation)
  if Animation == self.In and self.isOpenFromAICoach then
    local text = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetAICoachReplyText)
    if text and "" ~= text then
      self.isNeedEnterAnim = true
      self:OnNotifyAICoachTextUpdate(text)
    end
  end
end

function UMG_LineupAdjustment_C:OnNotifyAICoachEmotionChange(emotionType)
  if not self:IsCurrAICoachSceneTypeMatch() then
    return
  end
  if self.AIEmotionType and self.AIEmotionType == emotionType then
    return
  end
  self.AIEmotionType = emotionType
  if emotionType == AICoachModuleUtils.EnumAICoachEmotion.Idle then
    self.AICoach:SetPath(UEPath.AICoachEmotionPath.Idle)
  elseif emotionType == AICoachModuleUtils.EnumAICoachEmotion.Think then
    self.AICoach:SetPath(UEPath.AICoachEmotionPath.Think)
  elseif emotionType == AICoachModuleUtils.EnumAICoachEmotion.Answer then
    self.AICoach:SetPath(UEPath.AICoachEmotionPath.Answer)
  end
end

function UMG_LineupAdjustment_C:OnNotifyAICoachRequestFinish()
  if not self:IsCurrAICoachSceneTypeMatch() then
    return
  end
  if self.timerID then
    _G.DelayManager:CancelDelayById(self.timerID)
    self.timerID = nil
  end
  self.timerID = _G.DelayManager:DelaySeconds(5, function()
    if self and self:IsValid() then
      self.isNeedEnterAnim = true
      self.timerID = nil
      self:PlayAnimation(self.AICoach_Close)
    else
      Log.Warning("UMG_FriendTeamPanel_C:OnNotifyAICoachRequestFinish - Panel is no longer valid")
    end
  end)
end

function UMG_LineupAdjustment_C:OnOpenAICoachRequest()
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.RecordAudio)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    bGranted = true
  end
  if bGranted then
    self.AIGvoice:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.AIGvoice:OnInitialize(nil, FriendEnum.VoiceInputScene.AICoach)
    self.AIGvoice:PlayerAnimIn()
    self.AIGvoice:StartActive()
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_coach_icon_click")
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.SetAICoachTeamDiffJson, self:GetCurrTeamDiffData())
  else
    local IsFirstTime = UE.UNRCPermissionMgr.IsFirstTimeRequest(UE.ENRCPermissionType.RecordAudio)
    if IsFirstTime then
      self.RequestPermission = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.RecordAudio, {
        self,
        function(_, bGranted)
          self.RequestPermission = nil
          if bGranted then
          else
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_gvoice_microphone_premission_not_open)
          end
        end
      })
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_gvoice_microphone_premission_not_open)
    end
  end
end

function UMG_LineupAdjustment_C:OnTick()
  if self.isOpenFromAICoach then
    local isVoicePlaying = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsVoicePlaying)
    if isVoicePlaying then
      local voiceLevel = _G.GVoiceManager:GetSpeakerLevel()
      self.Progress:SetPercent(voiceLevel * 2)
    end
  end
end

function UMG_LineupAdjustment_C:OnOpenImportLineup()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFriendMirrorPetTeamCoverPanel, self.teamType)
  self:OnSaveAICoachRecommendTeam()
end

function UMG_LineupAdjustment_C:OnSaveAICoachRecommendTeam()
  local AICoachTeamData = self.module:GetData():GetAICoachRecommendTeamUIData()
  if AICoachTeamData and AICoachTeamData.teamData and AICoachTeamData.activityID then
    local teamData = self:GetAICoachTeamResult()
    if teamData then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnZoneSaveRecommendPetTeamReq, AICoachTeamData.activityID, teamData)
      _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_apply_click", teamData.team_id, teamData.team_name, self:GetCurrMissingInfo())
    end
  end
end

function UMG_LineupAdjustment_C:GetCurrMissingInfo()
  local missingInfo = ""
  if self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] and self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] > 0 then
    missingInfo = missingInfo .. string.format(LuaText.lineup_code_pet_lack, self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet])
  end
  if self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] and self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] > 0 then
    missingInfo = missingInfo .. string.format(LuaText.lineup_code_skill_lack, self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill])
  end
  if self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] and self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] > 0 then
    missingInfo = missingInfo .. string.format(LuaText.lineup_code_magic_lack, self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic])
  end
  return missingInfo
end

function UMG_LineupAdjustment_C:GetAICoachTeamResult()
  local AICoachTeamData = self.module:GetData():GetAICoachRecommendTeamUIData()
  if AICoachTeamData and AICoachTeamData.teamData then
    local teamData = AICoachTeamData.teamData
    teamData.pet_team_info.role_magic_id = self.magicID
    teamData.pet_team_info.pets = {}
    local fullPetData = self.fullPetData
    for _, value in ipairs(fullPetData) do
      local petInfo = ProtoMessage:newSharedPetInfo()
      petInfo.base_conf_id = value.sharedPetData.base_conf_id
      petInfo.nature = value.sharedPetData.nature
      petInfo.blood_id = value.sharedPetData.blood_id
      petInfo.hp_talent = value.sharedPetData.hp_talent
      petInfo.attack_talent = value.sharedPetData.attack_talent
      petInfo.special_attack_talent = value.sharedPetData.special_attack_talent
      petInfo.defense_talent = value.sharedPetData.defense_talent
      petInfo.special_defense_talent = value.sharedPetData.special_defense_talent
      petInfo.speed_talent = value.sharedPetData.speed_talent
      petInfo.changed_nature_pos_attr_type = value.sharedPetData.changed_nature_pos_attr_type
      petInfo.changed_nature_neg_attr_type = value.sharedPetData.changed_nature_neg_attr_type
      petInfo.skills = value.sharedPetData.skills
      if value.petData.AdjustCompleted then
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(value.petData.gid)
        if petData then
          petInfo.base_conf_id = petData.base_conf_id
          petInfo.nature = petData.nature
          petInfo.blood_id = petData.blood_id
          local attribute_info = petData.attribute_info
          if attribute_info then
            petInfo.hp_talent = attribute_info.hp.talent and attribute_info.hp.talent or 0
            petInfo.attack_talent = attribute_info.attack and attribute_info.attack.talent or 0
            petInfo.special_attack_talent = attribute_info.special_attack.talent and attribute_info.special_attack.talent or 0
            petInfo.defense_talent = attribute_info.defense.talent and attribute_info.defense.talent or 0
            petInfo.special_defense_talent = attribute_info.special_defense.talent and attribute_info.special_defense.talent or 0
            petInfo.speed_talent = attribute_info.speed.talent and attribute_info.speed.talent or 0
          end
          petInfo.changed_nature_pos_attr_type = petData.changed_nature_pos_attr_type
          petInfo.changed_nature_neg_attr_type = petData.changed_nature_neg_attr_type
        end
      end
      if value.petData.skills and #value.petData.skills > 0 then
        for i, skill in ipairs(petInfo.skills) do
          for k, _skill in ipairs(value.petData.skills) do
            if skill.pos and _skill.pos and skill.pos == _skill.pos and _skill.id and _skill.id > 0 then
              skill.id = _skill.id
              break
            end
          end
        end
      end
      table.insert(teamData.pet_team_info.pets, petInfo)
    end
    return teamData
  end
end

function UMG_LineupAdjustment_C:GetCurrTeamDiffData()
  local AICoachTeamData = self.module:GetData():GetAICoachRecommendTeamUIData()
  if not AICoachTeamData or not AICoachTeamData.teamData then
    return nil
  end
  local teamData = {}
  teamData.magicid = tostring(self.magicID)
  teamData.team_id = tostring(AICoachTeamData.teamData.team_id)
  teamData.team_name = AICoachTeamData.teamData.team_name
  teamData.team_type = ""
  teamData.team_source = "ai"
  teamData.pets = {}
  for i, v in ipairs(self.fullPetData) do
    local petData = {}
    if v.petData.AdjustCompleted and v.petData.gid then
      local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.petData.gid)
      if petInfo then
        petData.petbase_id = tostring(petInfo.base_conf_id)
        petData.pet_gid = tostring(v.petData.gid)
        petData.bloodline = tostring(petInfo.blood_id)
        petData.bloodline_diff = false
        petData.bloodline_bag = ""
        petData.nature_id = tostring(petInfo.nature)
        petData.nature_diff = false
        petData.nature_bag = ""
        local attribute_info = petInfo.attribute_info
        if attribute_info then
          local talentList = AICoachModuleUtils.GetTalentValue(attribute_info.hp.talent, attribute_info.attack.talent, attribute_info.special_attack.talent, attribute_info.defense.talent, attribute_info.special_defense.talent, attribute_info.speed.talent)
          petData.talent_a_name = tostring(talentList[1] or 0)
          petData.talent_a_diff = false
          petData.talent_a_bag = ""
          petData.talent_b_name = tostring(talentList[2] or 0)
          petData.talent_b_diff = false
          petData.talent_b_bag = ""
          petData.talent_c_name = tostring(talentList[3] or 0)
          petData.talent_c_diff = false
          petData.talent_c_bag = ""
        end
        petData.skill_a_id = tostring(v.petData.skills[1].id or 0)
        petData.skill_a_id_missing = false
        petData.skill_b_id = tostring(v.petData.skills[2].id or 0)
        petData.skill_b_id_missing = false
        petData.skill_c_id = tostring(v.petData.skills[3].id or 0)
        petData.skill_c_id_missing = false
        petData.skill_d_id = tostring(v.petData.skills[4].id or 0)
        petData.skill_d_id_missing = false
        petData.is_pet_missing = false
      end
    elseif 0 ~= v.petData.gid then
      local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.petData.gid)
      if petInfo then
        petData.petbase_id = tostring(petInfo.base_conf_id)
        petData.pet_gid = tostring(v.petData.gid)
        petData.bloodline = tostring(v.sharedPetData.blood_id or 0)
        petData.bloodline_bag = tostring(petInfo.blood_id or 0)
        petData.bloodline_diff = v.sharedPetData.blood_id ~= petInfo.blood_id
        petData.nature_id = tostring(v.sharedPetData.nature or 0)
        petData.nature_bag = tostring(petInfo.nature or 0)
        petData.nature_diff = v.sharedPetData.nature ~= petInfo.nature
        local attribute_info = petInfo.attribute_info
        if attribute_info then
          local talentList = AICoachModuleUtils.GetTalentValue(attribute_info.hp.talent, attribute_info.attack.talent, attribute_info.special_attack.talent, attribute_info.defense.talent, attribute_info.special_defense.talent, attribute_info.speed.talent)
          local startIndex = #talentList + 1
          for i = startIndex, 3 do
            table.insert(talentList, 0)
          end
          local talentListOld = AICoachModuleUtils.GetTalentValue(v.sharedPetData.hp_talent, v.sharedPetData.attack_talent, v.sharedPetData.special_attack_talent, v.sharedPetData.defense_talent, v.sharedPetData.special_defense_talent, v.sharedPetData.speed_talent)
          startIndex = #talentListOld + 1
          for i = startIndex, 3 do
            table.insert(talentListOld, 0)
          end
          table.sort(talentList, function(a, b)
            return a < b
          end)
          table.sort(talentListOld, function(a, b)
            return a < b
          end)
          petData.talent_a_name = tostring(talentListOld[1])
          petData.talent_a_diff = talentList[1] ~= talentListOld[1]
          petData.talent_a_bag = tostring(talentList[1])
          petData.talent_b_name = tostring(talentListOld[2])
          petData.talent_b_diff = talentList[2] ~= talentListOld[2]
          petData.talent_b_bag = tostring(talentList[2])
          petData.talent_c_name = tostring(talentListOld[3])
          petData.talent_c_diff = talentList[3] ~= talentListOld[3]
          petData.talent_c_bag = tostring(talentList[3])
        end
        local result, skillid = self:GetSkillValue(v.petData.skills[1], v.sharedPetData.skills[1], petInfo)
        petData.skill_a_id = skillid
        petData.skill_a_id_missing = result
        result, skillid = self:GetSkillValue(v.petData.skills[2], v.sharedPetData.skills[2], petInfo)
        petData.skill_b_id = skillid
        petData.skill_b_id_missing = result
        result, skillid = self:GetSkillValue(v.petData.skills[3], v.sharedPetData.skills[3], petInfo)
        petData.skill_c_id = skillid
        petData.skill_c_id_missing = result
        result, skillid = self:GetSkillValue(v.petData.skills[4], v.sharedPetData.skills[4], petInfo)
        petData.skill_d_id = skillid
        petData.skill_d_id_missing = result
        petData.is_pet_missing = false
      end
    else
      petData.petbase_id = tostring(v.sharedPetData.base_conf_id or 0)
      petData.bloodline = tostring(v.sharedPetData.blood_id or 0)
      petData.bloodline_diff = false
      petData.bloodline_bag = ""
      petData.nature_id = tostring(v.sharedPetData.nature or 0)
      petData.nature_diff = false
      petData.nature_bag = ""
      local talentList = AICoachModuleUtils.GetTalentValue(v.sharedPetData.hp_talent, v.sharedPetData.attack_talent, v.sharedPetData.special_attack_talent, v.sharedPetData.defense_talent, v.sharedPetData.special_defense_talent, v.sharedPetData.speed_talent)
      petData.talent_a_name = tostring(talentList[1] or 0)
      petData.talent_a_diff = false
      petData.talent_a_bag = ""
      petData.talent_b_name = tostring(talentList[2] or 0)
      petData.talent_b_diff = false
      petData.talent_b_bag = ""
      petData.talent_c_name = tostring(talentList[3] or 0)
      petData.talent_c_diff = false
      petData.talent_c_bag = ""
      petData.skill_a_id = tostring(v.sharedPetData.skills[1].id or 0)
      petData.skill_a_id_missing = false
      petData.skill_b_id = tostring(v.sharedPetData.skills[2].id or 0)
      petData.skill_b_id_missing = false
      petData.skill_c_id = tostring(v.sharedPetData.skills[3].id or 0)
      petData.skill_c_id_missing = false
      petData.skill_d_id = tostring(v.sharedPetData.skills[4].id or 0)
      petData.skill_d_id_missing = false
      petData.is_pet_missing = true
    end
    table.insert(teamData.pets, petData)
  end
  local teamList = {}
  table.insert(teamList, teamData)
  local success, result = pcall(rapidjson.encode, teamList)
  if not success then
    Log.Error("UMG_LineupAdjustment_C.GetCurrTeamDiffData failed~")
    return nil
  end
  return result
end

function UMG_LineupAdjustment_C:GetSkillValue(petDataSkill, sharedPetDataSkill, petInfo)
  if petDataSkill and petDataSkill.id and petDataSkill.id > 0 then
    return false, tostring(petDataSkill.id)
  else
    local skillData = petInfo.skill.skill_data
    for k, v in ipairs(skillData) do
      if v.id == sharedPetDataSkill.id then
        return false, tostring(v.id)
      end
    end
    return true, tostring(sharedPetDataSkill.id)
  end
end

function UMG_LineupAdjustment_C:SetIgnoreType(ShareReviseType, gid, data)
  if ShareReviseType == PetUIModuleEnum.PetTeamShareReviseType.Talent then
    if self.IgnoreList[gid] then
      if self.IgnoreList[gid][ShareReviseType] then
        self.IgnoreList[gid][ShareReviseType][data] = true
      else
        self.IgnoreList[gid][ShareReviseType] = {}
        self.IgnoreList[gid][ShareReviseType][data] = true
      end
    else
      self.IgnoreList[gid] = {}
      self.IgnoreList[gid][ShareReviseType] = {}
      self.IgnoreList[gid][ShareReviseType][data] = true
    end
  elseif ShareReviseType == PetUIModuleEnum.PetTeamShareReviseType.Nature then
    if self.IgnoreList[gid] then
      self.IgnoreList[gid][ShareReviseType] = true
    else
      self.IgnoreList[gid] = {}
      self.IgnoreList[gid][ShareReviseType] = true
    end
  elseif ShareReviseType == PetUIModuleEnum.PetTeamShareReviseType.Blood then
    if self.IgnoreList[gid] then
      self.IgnoreList[gid][ShareReviseType] = true
    else
      self.IgnoreList[gid] = {}
      self.IgnoreList[gid][ShareReviseType] = true
    end
  end
end

function UMG_LineupAdjustment_C:SetIgnoreTypeAndUpdate(ShareReviseType, gid, data)
  self:SetIgnoreType(ShareReviseType, gid, data)
  self:RefreshAdjustPetPanel()
end

function UMG_LineupAdjustment_C:SolveAllDiffType()
  self.SolveAllDiffNum = 0
  local useItemList = {}
  local exchangeInfoList = {}
  for i, v in pairs(self.SolveAllDiffList) do
    local gid = i
    local data = v
    if data then
      if data[PetUIModuleEnum.PetTeamShareReviseType.Talent] and #data[PetUIModuleEnum.PetTeamShareReviseType.Talent] then
        for _, item in ipairs(data[PetUIModuleEnum.PetTeamShareReviseType.Talent]) do
          self.SolveAllDiffNum = self.SolveAllDiffNum + 1
          local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100422)
          if BagItem and BagItem.num > 0 then
            local changeType = self:GetChangeAttrToReqEnum(item.ChangeType)
            local attribute = self:GetChangeAttrToReqEnum(item.attribute)
            local UseItemInfo = {}
            UseItemInfo.gid = BagItem.gid
            UseItemInfo.item_conf_id = BagItem.id
            UseItemInfo.num = 1
            UseItemInfo.para = gid
            UseItemInfo.change_talent_type = attribute
            UseItemInfo.result_type = changeType
            table.insert(useItemList, UseItemInfo)
          end
        end
      end
      if data[PetUIModuleEnum.PetTeamShareReviseType.Nature] and #data[PetUIModuleEnum.PetTeamShareReviseType.Nature] then
        for _, item in ipairs(data[PetUIModuleEnum.PetTeamShareReviseType.Nature]) do
          self.SolveAllDiffNum = self.SolveAllDiffNum + 1
          local bagItemId = item.Items[1].itemId
          local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
          if BagItem and BagItem.num > 0 then
            local PosNature = self:GetChangeAttrToReqEnum(item.share_pos_effect)
            local NegNature = self:GetChangeAttrToReqEnum(item.share_neg_effect)
            local UseItemInfo = {}
            UseItemInfo.gid = BagItem.gid
            UseItemInfo.item_conf_id = BagItem.id
            UseItemInfo.num = 1
            UseItemInfo.para = gid
            if 1 == item.UseType then
              UseItemInfo.change_attr_type = {2}
              UseItemInfo.target_type = {NegNature}
            elseif 2 == item.UseType then
              UseItemInfo.change_attr_type = {1}
              UseItemInfo.target_type = {PosNature}
            elseif 3 == item.UseType then
              UseItemInfo.change_attr_type = {1, 2}
              UseItemInfo.target_type = {PosNature, NegNature}
            end
            table.insert(useItemList, UseItemInfo)
          end
        end
      end
      if data[PetUIModuleEnum.PetTeamShareReviseType.Blood] and #data[PetUIModuleEnum.PetTeamShareReviseType.Blood] then
        for _, item in ipairs(data[PetUIModuleEnum.PetTeamShareReviseType.Blood]) do
          self.SolveAllDiffNum = self.SolveAllDiffNum + 1
          if item.exchangeID then
            local costGoodsList = {}
            for _, NeedItem in pairs(item.NeedItemList) do
              local goods = _G.ProtoMessage:newGoods()
              goods.goods_type = NeedItem.itemType or _G.Enum.GoodsType.GT_BAGITEM
              goods.goods_id = NeedItem.itemId
              goods.goods_num = NeedItem.needNum or 1
              table.insert(costGoodsList, 1, goods)
            end
            local exchangeInfo = _G.ProtoMessage:newCSExchangeItem()
            exchangeInfo.id = item.exchangeID
            exchangeInfo.num = 1
            exchangeInfo.cost_goods = costGoodsList
            local Find = false
            for index, exchange in ipairs(exchangeInfoList) do
              if exchange.id == item.exchangeID then
                Find = true
                exchangeInfoList[index].num = exchangeInfoList[index].num + 1
                local existingCostGoods = exchange.cost_goods
                for _, newGoods in ipairs(costGoodsList) do
                  local findItem = false
                  for _, existingGoods in ipairs(existingCostGoods) do
                    if newGoods.goods_id == existingGoods.goods_id then
                      findItem = true
                      break
                    end
                  end
                  if not findItem then
                    table.insert(existingCostGoods, newGoods)
                  end
                end
                exchangeInfoList[index].cost_goods = existingCostGoods
                break
              end
            end
            if not Find then
              table.insert(exchangeInfoList, exchangeInfo)
            end
            local UseItemInfo = {}
            UseItemInfo.gid = 0
            UseItemInfo.item_conf_id = item.BloodItemID
            UseItemInfo.num = 1
            UseItemInfo.para = item.petGid
            table.insert(useItemList, UseItemInfo)
          elseif item.NeedItemList then
            for _, NeedItem in pairs(item.NeedItemList) do
              local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, NeedItem.itemId)
              if bagItem then
                local UseItemInfo = {}
                UseItemInfo.gid = bagItem.gid
                UseItemInfo.item_conf_id = bagItem.id
                UseItemInfo.num = 1
                UseItemInfo.para = item.petGid
                UseItemInfo.para2 = item.tarBloodID
                table.insert(useItemList, UseItemInfo)
              end
            end
          end
        end
      end
    end
  end
  if #useItemList > 0 then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, exchangeInfoList, useItemList)
  end
end

function UMG_LineupAdjustment_C:SolveAllLostType()
  self.solveLostSkillNum = 0
  local useItemList = {}
  local exchangeInfoList = {}
  for i, v in pairs(self.SolveAllLostList) do
    local gid = i
    local data = v
    if data and data[PetUIModuleEnum.PetTeamShareReviseType.Skill] and #data[PetUIModuleEnum.PetTeamShareReviseType.Skill] then
      for _, item in ipairs(data[PetUIModuleEnum.PetTeamShareReviseType.Skill]) do
        self.solveLostSkillNum = self.solveLostSkillNum + #item.skillIDList
        if item.exchangeID then
          local costGoodsList = {}
          for _, NeedItem in pairs(item.NeedItemList) do
            local goods = _G.ProtoMessage:newGoods()
            goods.goods_type = NeedItem.itemType or _G.Enum.GoodsType.GT_BAGITEM
            goods.goods_id = NeedItem.itemId
            goods.goods_num = NeedItem.needNum or 1
            table.insert(costGoodsList, 1, goods)
          end
          local exchangeInfo = _G.ProtoMessage:newCSExchangeItem()
          exchangeInfo.id = item.exchangeID
          exchangeInfo.num = 1
          exchangeInfo.cost_goods = costGoodsList
          local Find = false
          for index, exchange in ipairs(exchangeInfoList) do
            if exchange.id == item.exchangeID then
              Find = true
              exchangeInfoList[index].num = exchangeInfoList[index].num + 1
              local existingCostGoods = exchange.cost_goods
              for _, newGoods in ipairs(costGoodsList) do
                local findItem = false
                for _, existingGoods in ipairs(existingCostGoods) do
                  if newGoods.goods_id == existingGoods.goods_id then
                    findItem = true
                    break
                  end
                end
                if not findItem then
                  table.insert(existingCostGoods, newGoods)
                end
              end
              exchangeInfoList[index].cost_goods = existingCostGoods
              break
            end
          end
          if not Find then
            table.insert(exchangeInfoList, exchangeInfo)
          end
          local UseItemInfo = {}
          UseItemInfo.gid = 0
          UseItemInfo.item_conf_id = item.BloodItemID
          UseItemInfo.num = 1
          UseItemInfo.para = item.petGid
          table.insert(useItemList, UseItemInfo)
        elseif item.NeedItemList then
          for _, NeedItem in pairs(item.NeedItemList) do
            local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, NeedItem.itemId)
            if bagItem then
              local UseItemInfo = {}
              UseItemInfo.gid = bagItem.gid
              UseItemInfo.item_conf_id = bagItem.id
              UseItemInfo.num = NeedItem.needNum
              UseItemInfo.para = item.petGid
              table.insert(useItemList, UseItemInfo)
            end
          end
        end
      end
    end
  end
  if #useItemList > 0 then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, exchangeInfoList, useItemList)
  end
end

function UMG_LineupAdjustment_C:ShowSolveSuccTips()
  if self.SolveAllDiffNum and 0 ~= self.SolveAllDiffNum then
    local str = string.format(LuaText.lineup_code_auto_fix_difference, self.SolveAllDiffNum)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
    self.SolveAllDiffNum = 0
  elseif self.solveLostSkillNum and 0 ~= self.solveLostSkillNum then
    local str = string.format(LuaText.lineup_code_auto_fix_lack, self.solveLostSkillNum)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
    self.solveLostSkillNum = 0
  end
end

function UMG_LineupAdjustment_C:OpenDetailsDifferencesPanel(openType)
  if 1 == openType then
    self.module:OpenPetShareTeamDetailsDifferencesPanel(self.SolveAllDiffList)
  elseif 2 == openType then
    self.module:OpenPetShareTeamLostDataDetailsPanel(self.SolveAllLostList)
  end
end

function UMG_LineupAdjustment_C:OpenSolveAllDiffTypePanel()
  local CanSolveDiffList = {}
  self.SolveAllDiffNeedItemList = {}
  self.SolveAllDiffList = {}
  for i, v in ipairs(self.petData) do
    self.SolveAllDiffList[v.gid] = {}
  end
  local diffTalentNum = 0
  local diffNatureNum = 0
  local diffBloodNum = 0
  for i, v in ipairs(self.checkTalentList) do
    local checkList = v.checkList
    if checkList and #checkList > 0 then
      local DiffTalentListByGid = {}
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
      
      function checkHide(Type)
        if #DiffTalentListByGid > 0 then
          for _, CheckItem in ipairs(DiffTalentListByGid) do
            if CheckItem.attribute == Type then
              return true
            end
          end
        end
        for _, CheckItem in ipairs(checkList) do
          if CheckItem.attribute == Type then
            return true
          end
        end
        return false
      end
      
      for _, CheckItem in ipairs(checkList) do
        if not CheckItem.HasTalent and not CheckItem.IsIgnore then
          if self.SolveAllDiffNeedItemList[100422] then
            if self.SolveAllDiffNeedItemList[100422].NeedNum + 1 > self.SolveAllDiffNeedItemList[100422].CurNum then
              break
            end
            self.SolveAllDiffNeedItemList[100422].NeedNum = self.SolveAllDiffNeedItemList[100422].NeedNum + 1
          else
            local ItemInfo = {}
            ItemInfo.CurNum = 0
            ItemInfo.NeedNum = 1
            local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100422)
            if BagItem and BagItem.num and BagItem.num >= ItemInfo.NeedNum then
              ItemInfo.CurNum = BagItem.num
            else
              break
            end
            self.SolveAllDiffNeedItemList[100422] = ItemInfo
          end
          local changeTalentList = {}
          local talentNum = 0
          local petlevel = PetUtils.GetBreakThroughStarsList(petData)
          local LevelNum = 0
          for j = 1, #petlevel do
            if 1 == petlevel[j].IsShow then
              LevelNum = LevelNum + 1
            end
          end
          if petData.attribute_info.attack.talent and petData.attribute_info.attack.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_PHYATK_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.attack.talent,
                attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          if petData.attribute_info.defense.talent and petData.attribute_info.defense.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_PHYDEF_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.defense.talent,
                attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          if petData.attribute_info.hp.talent and petData.attribute_info.hp.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_HPMAX_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.hp.talent,
                attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          if petData.attribute_info.special_attack.talent and petData.attribute_info.special_attack.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_SPEATK_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.special_attack.talent,
                attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          if petData.attribute_info.special_defense.talent and petData.attribute_info.special_defense.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_SPEDEF_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.special_defense.talent,
                attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          if petData.attribute_info.speed.talent and petData.attribute_info.speed.talent > 0 then
            if not checkHide(Enum.AttributeType.AT_SPEED_PERCENT) then
              table.insert(changeTalentList, {
                num = petData.attribute_info.speed.talent,
                attribute = Enum.AttributeType.AT_SPEED_PERCENT,
                ChangeType = CheckItem.attribute,
                Items = {
                  {itemId = 100422, num = 1}
                }
              })
            end
            talentNum = talentNum + 1
          end
          local maxTalentIndex = 0
          local maxTalent = 0
          for j, Talent in ipairs(changeTalentList) do
            if maxTalent < Talent.num then
              maxTalent = Talent.num
              maxTalentIndex = j
            end
          end
          if talentNum < 3 then
            table.insert(DiffTalentListByGid, {
              LevelNum = LevelNum,
              attribute = nil,
              ChangeType = CheckItem.attribute,
              Items = {
                {itemId = 100422, num = 1}
              }
            })
          else
            table.insert(DiffTalentListByGid, changeTalentList[maxTalentIndex])
          end
        end
      end
      if #DiffTalentListByGid > 0 then
        diffTalentNum = diffTalentNum + #DiffTalentListByGid
        self.SolveAllDiffList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Talent] = DiffTalentListByGid
      end
    end
  end
  CanSolveDiffList[PetUIModuleEnum.PetTeamShareReviseType.Talent] = diffTalentNum
  for i, v in ipairs(self.checkNatureList) do
    local checkList = v.checkList
    if checkList and #checkList > 0 then
      local DiffNatureListByGid = {}
      for _, CheckItem in ipairs(checkList) do
        if not CheckItem.HasNature and not CheckItem.IsIgnore then
          local share_pos_effect = CheckItem.share_pos_effect
          local share_neg_effect = CheckItem.share_neg_effect
          local pos_effect = CheckItem.pos_effect
          local neg_effect = CheckItem.neg_effect
          local natureName = CheckItem.natureName
          local curNagItemNum = 0
          if self.SolveAllDiffNeedItemList[100421] and self.SolveAllDiffNeedItemList[100421].CurNum then
            curNagItemNum = self.SolveAllDiffNeedItemList[100421].CurNum
          else
            local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100421)
            if BagItem and BagItem.num >= 1 then
              curNagItemNum = BagItem.num
            end
          end
          local NeedNagItemNum = self.SolveAllDiffNeedItemList[100421] and self.SolveAllDiffNeedItemList[100421].NeedNum or 0
          local curAllItemNum = 0
          if self.SolveAllDiffNeedItemList[100420] and self.SolveAllDiffNeedItemList[100420].CurNum then
            curAllItemNum = self.SolveAllDiffNeedItemList[100420].CurNum
          else
            local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
            if BagItem and BagItem.num >= 1 then
              curAllItemNum = BagItem.num
            end
          end
          local NeedAllItemNum = self.SolveAllDiffNeedItemList[100420] and self.SolveAllDiffNeedItemList[100420].NeedNum or 0
          if share_neg_effect ~= neg_effect then
            if pos_effect ~= share_pos_effect then
              if curAllItemNum >= NeedAllItemNum + 1 then
                table.insert(DiffNatureListByGid, {
                  UseType = 3,
                  natureName = natureName,
                  share_neg_effect = share_neg_effect,
                  neg_effect = neg_effect,
                  share_pos_effect = share_pos_effect,
                  pos_effect = pos_effect,
                  Items = {
                    {itemId = 100420, num = 1}
                  }
                })
                local ItemInfo = {}
                ItemInfo.CurNum = curAllItemNum
                ItemInfo.NeedNum = NeedAllItemNum + 1
                self.SolveAllDiffNeedItemList[100420] = ItemInfo
              elseif curNagItemNum >= NeedNagItemNum + 1 then
                table.insert(DiffNatureListByGid, {
                  UseType = 1,
                  natureName = natureName,
                  share_neg_effect = share_neg_effect,
                  neg_effect = neg_effect,
                  share_pos_effect = share_pos_effect,
                  pos_effect = pos_effect,
                  Items = {
                    {itemId = 100421, num = 1}
                  }
                })
                local ItemInfo = {}
                ItemInfo.CurNum = curNagItemNum
                ItemInfo.NeedNum = NeedNagItemNum + 1
                self.SolveAllDiffNeedItemList[100421] = ItemInfo
              end
            elseif share_neg_effect ~= pos_effect and curNagItemNum >= NeedNagItemNum + 1 then
              table.insert(DiffNatureListByGid, {
                UseType = 1,
                natureName = natureName,
                share_neg_effect = share_neg_effect,
                neg_effect = neg_effect,
                share_pos_effect = share_pos_effect,
                pos_effect = pos_effect,
                Items = {
                  {itemId = 100421, num = 1}
                }
              })
              local ItemInfo = {}
              ItemInfo.CurNum = curNagItemNum
              ItemInfo.NeedNum = NeedNagItemNum + 1
              self.SolveAllDiffNeedItemList[100421] = ItemInfo
            end
          elseif pos_effect ~= share_pos_effect and curAllItemNum >= NeedAllItemNum + 1 then
            table.insert(DiffNatureListByGid, {
              UseType = 2,
              natureName = natureName,
              share_pos_effect = share_pos_effect,
              pos_effect = pos_effect,
              share_neg_effect = share_neg_effect,
              neg_effect = neg_effect,
              Items = {
                {itemId = 100420, num = 1}
              }
            })
            local ItemInfo = {}
            ItemInfo.CurNum = curAllItemNum
            ItemInfo.NeedNum = NeedAllItemNum + 1
            self.SolveAllDiffNeedItemList[100420] = ItemInfo
          end
        end
      end
      if #DiffNatureListByGid > 0 then
        diffNatureNum = diffNatureNum + #DiffNatureListByGid
        self.SolveAllDiffList[v.gid][PetUIModuleEnum.PetTeamShareReviseType.Nature] = DiffNatureListByGid
      end
    end
  end
  CanSolveDiffList[PetUIModuleEnum.PetTeamShareReviseType.Nature] = diffNatureNum
  for i, v in pairs(self.needBloodItemList) do
    local NeedItemList = v.NeedItemList
    local DiffBloodListByGid = {}
    if NeedItemList and #NeedItemList > 0 then
      local IsEnough = false
      for index, Item in ipairs(NeedItemList) do
        local curItemNum = 0
        if self.SolveAllDiffNeedItemList[Item.itemId] and self.SolveAllDiffNeedItemList[Item.itemId].CurNum then
          curItemNum = self.SolveAllDiffNeedItemList[Item.itemId].CurNum
        else
          local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, Item.itemId)
          if BagItem and BagItem.num >= 1 then
            curItemNum = BagItem.num
          else
            curItemNum = 0
          end
        end
        local NeedItemNum = self.SolveAllDiffNeedItemList[Item.itemId] and self.SolveAllDiffNeedItemList[Item.itemId].NeedNum or 0
        NeedItemNum = NeedItemNum + Item.needNum
        if curItemNum < NeedItemNum then
          break
        end
        if index == #NeedItemList then
          IsEnough = true
        end
      end
      if IsEnough then
        for _, Item in ipairs(NeedItemList) do
          local curItemNum = 0
          if self.SolveAllDiffNeedItemList[Item.itemId] and self.SolveAllDiffNeedItemList[Item.itemId].CurNum then
            curItemNum = self.SolveAllDiffNeedItemList[Item.itemId].CurNum
          else
            local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, Item.itemId)
            if BagItem and BagItem.num >= 1 then
              curItemNum = BagItem.num
            else
              curItemNum = 0
            end
          end
          local NeedItemNum = self.SolveAllDiffNeedItemList[Item.itemId] and self.SolveAllDiffNeedItemList[Item.itemId].NeedNum or 0
          NeedItemNum = NeedItemNum + Item.needNum
          local ItemInfo = {}
          ItemInfo.CurNum = curItemNum
          ItemInfo.NeedNum = NeedItemNum
          self.SolveAllDiffNeedItemList[Item.itemId] = ItemInfo
        end
        table.insert(DiffBloodListByGid, v)
      end
    end
    if #DiffBloodListByGid > 0 then
      diffBloodNum = diffBloodNum + #DiffBloodListByGid
      self.SolveAllDiffList[v.petGid][PetUIModuleEnum.PetTeamShareReviseType.Blood] = DiffBloodListByGid
    end
  end
  CanSolveDiffList[PetUIModuleEnum.PetTeamShareReviseType.Blood] = diffBloodNum
  local count = 0
  for i, _ in pairs(self.SolveAllDiffNeedItemList) do
    count = count + 1
  end
  if count > 0 then
    self.module:OpenShareTeamSolveDifferencesPanel(CanSolveDiffList, self.SolveAllDiffNeedItemList)
  else
    local str = string.format(LuaText.lineup_code_no_solvable_difference)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
  end
end

function UMG_LineupAdjustment_C:IgnoreAllDiffType()
  for i, v in ipairs(self.checkNatureList) do
    if not (v.checkList and #v.checkList > 0) or v.checkList[1].IsIgnore then
    else
      self:SetIgnoreType(PetUIModuleEnum.PetTeamShareReviseType.Nature, v.gid)
    end
  end
  for i, v in ipairs(self.checkTalentList) do
    if v.checkList and #v.checkList > 0 then
      local checkList = v.checkList
      for _, checkItem in ipairs(checkList) do
        if checkItem.IsIgnore then
        else
          self:SetIgnoreType(PetUIModuleEnum.PetTeamShareReviseType.Talent, v.gid, checkItem.attribute)
        end
      end
    end
  end
  for i, v in pairs(self.needBloodItemList) do
    if v.IsIgnore then
    elseif v.petGid then
      self.needBloodItemList[i].IsIgnore = true
      NRCEventCenter:DispatchEvent(PetUIModuleEvent.IgnoreBloodDiff, v.petGid)
      self:SetIgnoreType(PetUIModuleEnum.PetTeamShareReviseType.Blood, v.petGid)
    end
  end
  self:RefreshAdjustPetPanel()
end

function UMG_LineupAdjustment_C:RefreshAdjustPetPanel()
  self:UpdateUIData()
  self:UpdateUI()
end

function UMG_LineupAdjustment_C:SetShareTeamName(TeamName)
  self.teamName = TeamName
  self.Text_1:SetText(self.teamName)
end

function UMG_LineupAdjustment_C:UpdateUIData()
  self:CheckHasPetTalentData()
  self:CheckHasPetNatureData()
  self:CalcuBloodDiff()
  self:CalcuLostData()
  self:UpdatePetGidList()
end

function UMG_LineupAdjustment_C:UpdatePetGidList(index, petData)
  for i, data in ipairs(self.fullPetData) do
    data.PetGidList = self:InitPetGidList()
  end
end

function UMG_LineupAdjustment_C:AdjustLostPet(index, petData)
  self.petData[index] = petData
  self.fullPetData[index].petData = petData
  self.fullPetData[index].petData.AdjustCompleted = true
  local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petData.gid)
  self.fullPetData[index].petDataInfo = petDataInfo
  self:RefreshAdjustPetPanel()
  local teamData = self:GetAICoachTeamResult()
  if self.isOpenFromAICoach and teamData then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_resolve_click", teamData.team_id, self.teamName, self:GetCurrMissingInfo())
  end
end

function UMG_LineupAdjustment_C:SetMagicUI(index, petData)
  if self.magicID then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.magicID)
    if BagItemConf then
      self.Icon:SetPath(BagItemConf.icon)
    else
      Log.Error("\231\188\186\229\176\145\233\173\148\230\179\149\233\133\141\231\189\174")
    end
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    local MagicList = {}
    for index, BagItem in pairs(BagItemS) do
      table.insert(MagicList, {
        id = BagItem.id
      })
    end
    local findMagicFlag = false
    for _, magic in pairs(MagicList) do
      if magic.id == self.magicID then
        findMagicFlag = true
      end
    end
    self.MagicList = MagicList
    if not findMagicFlag then
      self:SetPetIDList()
      self:SetMagicPetNum()
      self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] = 1
    else
      self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] = 0
      self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_73:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LineupAdjustment_C:SetPetIDList()
  self.petIdList = {}
  local gidList = {}
  for _, Data in ipairs(self.fullPetData) do
    if 0 ~= Data.petData.gid then
      table.insert(gidList, Data.petData.gid)
    end
  end
  if gidList then
    for i, v in ipairs(gidList) do
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v)
      table.insert(self.petIdList, petData)
    end
  end
end

function UMG_LineupAdjustment_C:SetMagicPetNum()
  for _, magic in ipairs(self.MagicList) do
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(magic.id)
    if BagItemConf then
      local PlayerMagicConf = _G.DataConfigManager:GetPlayerMagicConf(BagItemConf.player_skill_id)
      if PlayerMagicConf then
        local SkillConf = _G.DataConfigManager:GetSkillConf(PlayerMagicConf.skill_id)
        if SkillConf then
          local PetDataList = {}
          for i, PetData in ipairs(self.petIdList) do
            for j, Blood in ipairs(SkillConf.target_blood_limit) do
              if PetData.blood_id == Blood or self:DepartmentMatching(PetData, Blood) then
                table.insert(PetDataList, PetData)
                break
              end
            end
          end
          if PetDataList and #PetDataList > 0 then
            magic.PetNum = #PetDataList
            magic.petDataList = PetDataList
          else
            magic.PetNum = 0
          end
        end
      end
    end
  end
  table.sort(self.MagicList, function(a, b)
    return a.PetNum > b.PetNum or a.PetNum == b.PetNum and a.id < b.id
  end)
end

function UMG_LineupAdjustment_C:DepartmentMatching(PetData, blood_id)
  for i, type in ipairs(PetData.skill_dam_type) do
    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(blood_id)
    if PetBloodConf and type == PetBloodConf.blood_type then
      return true
    end
  end
  return false
end

function UMG_LineupAdjustment_C:OpenAlternativeMagic()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_LineupAdjustment_C:OpenAlternativeMagic")
  if self.MagicList and #self.MagicList > 0 then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenSkillAlternative, 2, self.MagicList)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_no_recommend_magic)
  end
end

function UMG_LineupAdjustment_C:ChangeTeamMagic(magicID)
  self.magicID = magicID
  if magicID then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.magicID)
    self.Icon:SetPath(BagItemConf.icon)
    self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:CalcuLostData()
  self:UpdateUI()
  local teamData = self:GetAICoachTeamResult()
  if self.isOpenFromAICoach and teamData then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_resolve_click", teamData.team_id, self.teamName, self:GetCurrMissingInfo())
  end
end

function UMG_LineupAdjustment_C:Rename()
  local param = {
    teamName = self.teamName
  }
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenRechristenPanel, param, nil, 3)
end

function UMG_LineupAdjustment_C:CalculateExchangeInfo()
  local BagConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  local SkillIDToBagIDMap = {}
  local BloodIDToBagIDMap = {}
  self.SkillIDToBagIDMap = SkillIDToBagIDMap
  self.BloodIDToBagIDMap = BloodIDToBagIDMap
  for i, bagItemConf in pairs(BagConf) do
    if bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_LEARN_SKILL and bagItemConf.item_behavior[1].ratio[1] then
      local SkillID = bagItemConf.item_behavior[1].ratio[1]
      SkillIDToBagIDMap[SkillID] = bagItemConf.id
    end
    if bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD and bagItemConf.item_behavior[1].ratio[1] then
      local BloodID = bagItemConf.item_behavior[1].ratio[1]
      if 19 ~= BloodID then
        BloodIDToBagIDMap[BloodID] = bagItemConf.id
      end
    end
    if bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
      BloodIDToBagIDMap[19] = bagItemConf.id
    end
  end
end

function UMG_LineupAdjustment_C:OnGetUnlockedExchangeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.exchangeInfoTable = {}
    local server_exchange_data_map = {}
    for i, exchange_data in ipairs(rsp.player_exchange_info and rsp.player_exchange_info.exchange_data or {}) do
      if exchange_data.exchange_group then
        server_exchange_data_map[exchange_data.exchange_group] = exchange_data
      end
    end
    local unlockExchangeIds = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetUnlockExchange)
    self.exchangeData = unlockExchangeIds
    for _, exchange_id in ipairs(unlockExchangeIds) do
      local exchange_data = {}
      exchange_data.exchange_id = exchange_id
      exchange_data.exchange_times = 0
      exchange_data.next_refresh_time = nil
      local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchange_id)
      local server_exchange_data = server_exchange_data_map[exchangeConf.exchange_time_limit_group or 0]
      if server_exchange_data then
        exchange_data.exchange_times = server_exchange_data.exchange_times
        exchange_data.next_refresh_time = server_exchange_data.next_refresh_time
      end
      local exchangeTimeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(exchangeConf.exchange_time_limit_group, true)
      if exchangeTimeLimitConf then
        exchange_data.remain_exchange_times = exchangeTimeLimitConf.exchange_manufacture_times - exchange_data.exchange_times
      end
      self.exchangeInfoTable[exchange_data.exchange_id] = exchange_data
    end
  else
    self.exchangeData = {}
    self.exchangeInfoTable = {}
    Log.Error("\231\130\188\233\135\145\232\167\163\233\148\129\228\191\161\230\129\175\229\155\158\229\140\133\233\148\153\232\175\175: ", table.tostring(rsp))
  end
  self:CalculateItemCostByID(self.BloodIDToBagIDMap[1])
end

function UMG_LineupAdjustment_C:CalculateItemCostByID(itemID)
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemID)
  
  local function _SortRecipeFunc(a, b)
    local canExchangeA = a.canExchangeNum > 0 and 1 or 0
    local canExchangeB = b.canExchangeNum > 0 and 1 or 0
    if canExchangeA ~= canExchangeB then
      return canExchangeA > canExchangeB
    else
      return a.exchangeId < b.exchangeId
    end
  end
  
  local ExchangeDataList = {}
  for i, exchangeID in pairs(self.BagIDToExchangeIDMap[itemID]) do
    if self.UnlockExchangeMap[exchangeID] then
      local cfg = _G.DataConfigManager:GetExchangeConf(exchangeID)
      local item = {}
      local get_item = cfg.get_item[1]
      item.exchangeId = cfg.id
      item.exchangeConf = cfg
      item.exchange_time_lower_limit = cfg.exchange_time_lower_limit
      item.exchange_time_upper_limit = cfg.exchange_time_upper_limit
      item.get_item = get_item
      item.cost_item = {}
      item.num = 0
      item.IsRefresh = self.IsRefresh
      item.exchangeInfo = self.exchangeInfoTable[item.exchangeId]
      item.refreshType = 0
      local groupId = cfg.exchange_time_limit_group
      if 0 ~= groupId then
        local exchangeTimeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(groupId)
        if exchangeTimeLimitConf then
          item.refreshType = exchangeTimeLimitConf.refresh_reset_type
        end
      end
      item.BagItemConf = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id)
      for i, cost_item in ipairs(cfg.cost_item) do
        local bagItemData = AlchemyUtils.GetBagItemByID(cost_item.cost_goods_id)
        local new_cost_item = {}
        new_cost_item.cost_goods_id = cost_item.cost_goods_id
        new_cost_item.cost_goods_type = cost_item.cost_goods_type
        new_cost_item.cost_goods_num = cost_item.cost_goods_num
        if bagItemData then
          new_cost_item.num = bagItemData.num
        else
          new_cost_item.num = 0
        end
        table.insert(item.cost_item, new_cost_item)
      end
      if get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        local bagItemData = AlchemyUtils.GetBagItemByID(get_item.get_goods_id)
        if bagItemData then
          item.num = bagItemData.num
        end
      end
      item.canExchangeNum = AlchemyUtils.GetCanExchangeNum(cfg, item.exchangeInfo)
      table.insert(ExchangeDataList, item)
    end
  end
  table.sort(ExchangeDataList, _SortRecipeFunc)
  return ExchangeDataList
end

function UMG_LineupAdjustment_C:CalcNeedNum(itemId, hasNum)
  self.itemId = itemId
  local itemType = self.item.cost_goods_type
  local needNum = self.item.cost_goods_num * self.item_num
  if itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(self.itemId)
    if nil ~= vItemConf then
      self.UMG_UIIcon:SetPath(vItemConf.bigIcon)
    end
  elseif itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.itemId)
    if nil ~= bagItemConf then
      self.UMG_UIIcon:SetPath(bagItemConf.icon)
    end
  end
  if hasNum >= needNum then
    self.CurrentNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#ffffffff"))
  else
    self.CurrentNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#ff4a4aff"))
  end
end

function UMG_LineupAdjustment_C:GetSortGoodsList(exchangeId, item, index)
  local dataList = {}
  local goodsList = item.cost_goods_id
  local costType = item.cost_goods_type
  local needNum = item.cost_goods_num
  for i = 1, #goodsList do
    local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, goodsList[i], costType)
    local itemData = {
      itemId = goodsList[i],
      itemNum = num,
      needNum = needNum
    }
    table.insert(dataList, itemData)
  end
  dataList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetSortGoodsList, dataList, costType)
  return dataList, dataList[1].itemId, dataList[1].itemNum
end

function UMG_LineupAdjustment_C:ChangePetSkill(petIndex, skillIndex, skillID)
  if skillID == self.fullPetData[petIndex].sharedPetData.skills[skillIndex].id then
  end
  self.fullPetData[petIndex].petData.skills[skillIndex].id = skillID
  self.fullPetData[petIndex].petData.skills[skillIndex].pos = skillIndex
  self:CalcuLostData()
  self:UpdateUI()
  local teamData = self:GetAICoachTeamResult()
  if self.isOpenFromAICoach and teamData then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "team_recomm_detail_resolve_click", teamData.team_id, self.teamName, self:GetCurrMissingInfo())
  end
end

function UMG_LineupAdjustment_C:CalcuLostData()
  self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] = 0
  for i, fullpetdata in ipairs(self.fullPetData) do
    if 0 == fullpetdata.petData.gid then
      self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] = self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Pet] + 1
    end
  end
  self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] = 0
  for i, fullpetdata in ipairs(self.fullPetData) do
    if fullpetdata.petData.AdjustCompleted then
    elseif fullpetdata.petData.skills then
      for j, petHasSkill in ipairs(fullpetdata.petData.skills) do
        if 0 == petHasSkill.id and 0 ~= fullpetdata.sharedPetData.skills[j].id then
          local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(fullpetdata.petData.gid)
          local sharedPetDataSkillID = fullpetdata.sharedPetData.skills[j].id
          local hasLearned = false
          for _, skill in pairs(petDataInfo.skill.skill_data) do
            if skill.id == sharedPetDataSkillID and skill.is_learned then
              hasLearned = true
            end
          end
          if false == hasLearned then
            self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] = self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Skill] + 1
          end
        end
      end
    end
  end
end

function UMG_LineupAdjustment_C:AutoSolveLostData()
  self.autoSolveNum = 0
  if self.LostDataList[PetUIModuleEnum.PetTeamShareReviseType.Magic] > 0 and self.MagicList[1] and self.MagicList[1].id then
    self:ChangeTeamMagic(self.MagicList[1].id)
    self.autoSolveNum = self.autoSolveNum + 1
  end
  for i, fullpetdata in ipairs(self.fullPetData) do
    if fullpetdata.petData.skills then
      for j, petHasSkill in ipairs(fullpetdata.petData.skills) do
        if 0 == petHasSkill.id then
          local hasRepeatedSkill = false
          if petHasSkill.alternative_skills then
            local autoSkillIndex = 1
            ::lbl_47::
            if petHasSkill.alternative_skills[autoSkillIndex] then
              local autoChooseSkillID = petHasSkill.alternative_skills[autoSkillIndex]
              for k, petSkill in ipairs(fullpetdata.petData.skills) do
                if petSkill.id == autoChooseSkillID then
                  hasRepeatedSkill = true
                  break
                end
              end
              if hasRepeatedSkill then
                autoSkillIndex = autoSkillIndex + 1
                goto lbl_47
              else
                petHasSkill.id = autoChooseSkillID
                NRCEventCenter:DispatchEvent(PetUIModuleEvent.ChangePetSkill, i, j, autoChooseSkillID)
                self.autoSolveNum = self.autoSolveNum + 1
              end
            else
              Log.Debug("jobhuang \230\151\160\229\143\175\233\128\137\230\138\128\232\131\189")
            end
          end
        end
      end
    end
  end
  self:SendAdjustAllLostPetReq()
  self:RefreshAdjustPetPanel()
end

function UMG_LineupAdjustment_C:CalcuBloodDiff()
  local diffNum = 0
  self.needBloodItemList = {}
  for i, fullpetdata in ipairs(self.fullPetData) do
    if 0 ~= fullpetdata.petData.gid and not fullpetdata.petData.AdjustCompleted then
      local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(fullpetdata.petData.gid)
      if petDataInfo and petDataInfo.blood_id ~= fullpetdata.sharedPetData.blood_id then
        local IsIgnore = self.IgnoreList[fullpetdata.petData.gid] and self.IgnoreList[fullpetdata.petData.gid][PetUIModuleEnum.PetTeamShareReviseType.Blood]
        if not IsIgnore then
          diffNum = diffNum + 1
        end
        local tarBloodID = fullpetdata.sharedPetData.blood_id
        local BloodItemID = self.BloodIDToBagIDMap[tarBloodID]
        self.needBloodItemList[i] = {}
        self.needBloodItemList[i].petIndex = i
        self.needBloodItemList[i].nowBloodID = petDataInfo.blood_id
        self.needBloodItemList[i].petGid = fullpetdata.petData.gid
        if 23 ~= tarBloodID then
          self.needBloodItemList[i].tarBloodID = tarBloodID
          local NeedItemList, exchangeID = NRCModuleManager:DoCmd(PetUIModuleCmd.CalcuBloodChangeNeedItems, BloodItemID)
          self.needBloodItemList[i].NeedItemList = NeedItemList
          self.needBloodItemList[i].exchangeID = exchangeID
          self.needBloodItemList[i].IsIgnore = IsIgnore
          self.needBloodItemList[i].BloodItemID = BloodItemID
          self.fullPetData[i].needBloodItemList = self.needBloodItemList[i]
        end
      else
        self.needBloodItemList[i] = {}
        self.fullPetData[i].needBloodItemList = {}
      end
    end
  end
  self.DiffList[PetUIModuleEnum.PetTeamShareReviseType.Blood] = diffNum
end

function UMG_LineupAdjustment_C:SendAdjustAllLostPetReq()
  local req = ProtoMessage:newZonePetTeamShareAutoCompleteTeamReq()
  req.team_type = self.teamType
  req.shared_team = self.shared_team
  local current_team = ProtoMessage:newAdjustedPetTeamInfo()
  current_team.pets = self.petData
  req.current_team = current_team
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_SHARE_AUTO_COMPLETE_TEAM_REQ, req, self, self.AdjustAllLostPetRsp)
end

function UMG_LineupAdjustment_C:AdjustAllLostPetRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.petData = rsp.completed_team.pets
    for i, data in ipairs(self.petData) do
      if 0 ~= data.gid then
        local AdjustCompleted = self.fullPetData[i].petData.gid ~= data.gid
        if AdjustCompleted then
          self.autoSolveNum = self.autoSolveNum + 1
          self.fullPetData[i].petData = data
          self.fullPetData[i].petData.AdjustCompleted = AdjustCompleted
          local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data.gid)
          self.fullPetData[i].petDataInfo = petDataInfo
        end
      end
    end
    local str = string.format(LuaText.lineup_code_auto_recommend_lack, self.autoSolveNum)
    if 0 == self.autoSolveNum then
      str = LuaText.lineup_code_no_solvable_lack
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
    end
    self:RefreshAdjustPetPanel()
  end
end

function UMG_LineupAdjustment_C:OpenQuickLearnAllLostSkillPanel()
  local SkillCostItemList = {}
  self.SkillCostItemList = SkillCostItemList
  for i, fullpetdata in ipairs(self.fullPetData) do
    SkillCostItemList[i] = {}
    if 0 ~= fullpetdata.petData.gid then
      local skillDataList = fullpetdata.petData.skills
      local MaxSkillLevelItem
      local MaxLevel = 0
      for j, petHasSkill in ipairs(skillDataList) do
        if 0 == petHasSkill.id then
          local skillID = petHasSkill.id
          local learnSkillID = fullpetdata.sharedPetData.skills[j].id
          local petBaseID = fullpetdata.petDataInfo.base_conf_id
          local NeedItemList, exchangeID, LearnLevel = NRCModuleManager:DoCmd(PetUIModuleCmd.CalcuSkillLearningNeedItems, learnSkillID, petBaseID, fullpetdata.petData.gid)
          local maxCanUpLevel = PetUtils.GetPetMaxLevel()
          if not LearnLevel then
            local SkillNeedItemList = {}
            SkillNeedItemList.NeedItemList = NeedItemList
            SkillNeedItemList.exchangeID = exchangeID
            SkillNeedItemList.skillIDList = {learnSkillID}
            SkillNeedItemList.petGid = fullpetdata.petData.gid
            table.insert(SkillCostItemList[i], SkillNeedItemList)
          elseif LearnLevel < maxCanUpLevel then
            MaxSkillLevelItem = MaxSkillLevelItem or {}
            if MaxLevel < LearnLevel then
              MaxLevel = LearnLevel
              MaxSkillLevelItem.NeedItemList = NeedItemList
              MaxSkillLevelItem.exchangeID = exchangeID
              MaxSkillLevelItem.petGid = fullpetdata.petData.gid
            end
            if not MaxSkillLevelItem.skillIDList then
              MaxSkillLevelItem.skillIDList = {}
            end
            table.insert(MaxSkillLevelItem.skillIDList, learnSkillID)
          end
        end
      end
      if MaxSkillLevelItem then
        table.insert(SkillCostItemList[i], MaxSkillLevelItem)
      end
    end
  end
  self.SolveAllLostNeedItemList = {}
  self.SolveAllLostList = {}
  for i, v in ipairs(self.petData) do
    self.SolveAllLostList[v.gid] = {}
  end
  for i, PetSkillData in pairs(self.SkillCostItemList) do
    local LostSkillListByGid = {}
    local petGid
    for j, v in pairs(PetSkillData) do
      if v.petGid then
        petGid = v.petGid
      end
      local NeedItemList = v.NeedItemList
      if NeedItemList and #NeedItemList > 0 then
        local IsEnough = false
        for index, Item in ipairs(NeedItemList) do
          local curItemNum = 0
          if self.SolveAllLostNeedItemList[Item.itemId] and self.SolveAllLostNeedItemList[Item.itemId].CurNum then
            curItemNum = self.SolveAllLostNeedItemList[Item.itemId].CurNum
          else
            local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, Item.itemId)
            if BagItem and BagItem.num >= 1 then
              curItemNum = BagItem.num
            else
              curItemNum = 0
            end
          end
          local NeedItemNum = self.SolveAllLostNeedItemList[Item.itemId] and self.SolveAllLostNeedItemList[Item.itemId].NeedNum or 0
          NeedItemNum = NeedItemNum + Item.needNum
          if curItemNum < NeedItemNum then
            break
          end
          if index == #NeedItemList then
            IsEnough = true
          end
        end
        if IsEnough then
          for _, Item in ipairs(NeedItemList) do
            local curItemNum = 0
            if self.SolveAllLostNeedItemList[Item.itemId] and self.SolveAllLostNeedItemList[Item.itemId].CurNum then
              curItemNum = self.SolveAllLostNeedItemList[Item.itemId].CurNum
            else
              local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, Item.itemId)
              if BagItem and BagItem.num >= 1 then
                curItemNum = BagItem.num
              else
                curItemNum = 0
              end
            end
            local NeedItemNum = self.SolveAllLostNeedItemList[Item.itemId] and self.SolveAllLostNeedItemList[Item.itemId].NeedNum or 0
            NeedItemNum = NeedItemNum + Item.needNum
            local ItemInfo = {}
            ItemInfo.CurNum = curItemNum
            ItemInfo.NeedNum = NeedItemNum
            self.SolveAllLostNeedItemList[Item.itemId] = ItemInfo
          end
          table.insert(LostSkillListByGid, v)
        end
      end
    end
    if #LostSkillListByGid > 0 then
      if petGid and not self.SolveAllLostList[petGid][PetUIModuleEnum.PetTeamShareReviseType.Skill] then
        self.SolveAllLostList[petGid][PetUIModuleEnum.PetTeamShareReviseType.Skill] = {}
      end
      if petGid then
        self.SolveAllLostList[petGid][PetUIModuleEnum.PetTeamShareReviseType.Skill] = LostSkillListByGid
      end
    end
  end
  local count = 0
  for i, _ in pairs(self.SolveAllLostNeedItemList) do
    count = count + 1
  end
  if count > 0 then
    self.module:OpenShareTeamSolveLostDataPanel(self.LostDataList, self.SolveAllLostNeedItemList)
  else
    local str = string.format(LuaText.lineup_code_no_solvable_lack)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
  end
end

function UMG_LineupAdjustment_C:OnSaveSucc()
  self:ClosePanel()
end

function UMG_LineupAdjustment_C:SendTLog(PetTeamInfo)
  local key = "PVPTeamShareLog"
  local tempString = "PVPTeamShareLog|%s|%s|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s"
  local gameServerId = "nil"
  local deEventTime = os.date("%Y-%m-%d %H:%M:%S")
  local gameAppId = "1110613799"
  local platId = -1
  local zoneId = 0
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() or 0
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      gameServerId = needData.serverName or "nil"
      platId = needData.plat_info.plat_id or -1
      zoneId = needData.zoneId or 0
      openId = needData.openid or "nil"
    end
  end
  local ActionType = 1
  local ShareFrom = PetTeamInfo and PetTeamInfo.team_type or 1
  local ShareType = 0
  if PetTeamInfo and PetTeamInfo.team_type == Enum.PlayerTeamType.PTT_PVP_BATTLE_5 then
    ShareType = 1
  end
  local ShareCode = self.id or "nil"
  local value = string.format(tempString, deEventTime, gameAppId, platId, zoneId, openId, uin, roleName, level, ActionType, ShareFrom, ShareType, ShareCode)
  for i = 1, 6 do
    if PetTeamInfo and PetTeamInfo.pets and PetTeamInfo.pets[i] then
      value = value .. "|" .. PetTeamInfo.pets[i].base_conf_id
    else
      value = value .. "|0"
    end
  end
  for i = 1, 6 do
    if PetTeamInfo and PetTeamInfo.pets and PetTeamInfo.pets[i] then
      for j = 1, 4 do
        if PetTeamInfo.pets[i].skills and PetTeamInfo.pets[i].skills[j] then
          value = value .. "|" .. PetTeamInfo.pets[i].skills[j].id
        else
          value = value .. "|0"
        end
      end
    end
  end
  local TeamMagicID = 0
  if PetTeamInfo then
    TeamMagicID = PetTeamInfo.role_magic_id or 0
  end
  local TeamName = self.teamName or "nil"
  value = value .. "|" .. TeamMagicID
  value = value .. "|" .. TeamName
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_LineupAdjustment_C:OnPetChangeClose(teamIndex)
  if -1 == self.OpenAdjustTeamIndex then
    self.bSendTLog2 = true
  end
  self.OpenAdjustTeamIndex = teamIndex - 1
  self:OnSave()
  self.bCloseFromUse = true
  self:OnClickCloseBtn()
end

function UMG_LineupAdjustment_C:SendTLog2(team, teamType, teamName)
  local key = "WeekendChallengeTeamDepolyLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  if not RankStar then
    return
  end
  local curRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
  local RankName = curRankConf.id
  local index = self.module:GetData().ShiningWeekendTeamOpenIndex
  local teamData = self.module:GetData():GetRecommendPetTeamList()[index]
  if not teamData then
    return
  end
  local TeamID = teamData.team_id
  local PlayerName = teamData.player_name
  local TeamCode
  if teamData.pet_team_share_id then
    TeamCode = teamData.pet_team_share_id
  else
    TeamCode = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.EncodeShareTeamCode, teamData.pet_team_info.pets, teamData.pet_team_info.role_magic_id, teamData.pet_team_info.team_type, teamData.team_name)
  end
  local pets = {}
  local baseIdArray = {}
  for i = 1, 6 do
    local pet = team[i]
    if pet then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet.pet_gid)
      if petData then
        local sharePet = _G.ProtoMessage:newSharedPetInfo()
        sharePet.base_conf_id = petData.conf_id
        sharePet.nature = petData.nature
        sharePet.blood_id = petData.blood_id
        local skillEquip = {}
        for _, v in ipairs(pet.equip_infos) do
          table.insert(skillEquip, {
            id = v.id,
            pos = v.pos
          })
        end
        sharePet.skills = skillEquip
        sharePet.changed_nature_pos_attr_type = petData.changed_nature_pos_attr_type
        sharePet.changed_nature_neg_attr_type = petData.changed_nature_neg_attr_type
        if petData.attribute_info.attack.talent > 0 then
          sharePet.attack_talent = 1
        end
        if petData.attribute_info.defense.talent > 0 then
          sharePet.defense_talent = 1
        end
        if petData.attribute_info.hp.talent > 0 then
          sharePet.hp_talent = 1
        end
        if petData.attribute_info.special_attack.talent > 0 then
          sharePet.special_attack_talent = 1
        end
        if petData.attribute_info.special_defense.talent > 0 then
          sharePet.special_defense_talent = 1
        end
        if petData.attribute_info.speed.talent > 0 then
          sharePet.speed_talent = 1
        end
        table.insert(pets, sharePet)
        baseIdArray[i] = tostring(petData.base_conf_id)
      end
    else
      baseIdArray[i] = "nil"
    end
  end
  local FinalTeamCode = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.EncodeShareTeamCode, pets, team.magicID, teamType, teamName)
  local MagicID = team.magicID
  local value = string.format("%s|%s|%d|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", key, roleDataStr, RankName, TeamID, PlayerName, TeamCode, FinalTeamCode, tostring(MagicID), baseIdArray[1], baseIdArray[2], baseIdArray[3], baseIdArray[4], baseIdArray[5], baseIdArray[6])
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_LineupAdjustment_C:SendTLog3(petList)
  local key = "WeekendChallengeTeamMissingLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  if not RankStar then
    return
  end
  local curRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
  local RankName = curRankConf and curRankConf.id
  local index = self.module:GetData().ShiningWeekendTeamOpenIndex
  local teamData = self.module:GetData():GetRecommendPetTeamList()[index]
  if not teamData then
    return
  end
  local TeamID = teamData.team_id
  local PlayerName = teamData.player_name
  local TeamCode
  if teamData.pet_team_share_id then
    TeamCode = teamData.pet_team_share_id
  else
    TeamCode = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.EncodeShareTeamCode, teamData.pet_team_info.pets, teamData.pet_team_info.role_magic_id, teamData.pet_team_info.team_type, teamData.team_name)
  end
  local TalentDiffCount = 0
  local BloodDiffCount = 0
  local CharacterDiffCount = 0
  local baseIdArray = {}
  local skillArray = {}
  local i = 1
  for _, pet in ipairs(petList) do
    for _, v in ipairs(pet.checkTalentList.checkList) do
      if not v.HasTalent then
        TalentDiffCount = TalentDiffCount + 1
      end
    end
    if pet.needBloodItemList and pet.needBloodItemList.BloodItemID then
      BloodDiffCount = BloodDiffCount + 1
    end
    for _, v in ipairs(pet.checkNatureList.checkList) do
      if not v.HasNature then
        CharacterDiffCount = CharacterDiffCount + 1
      end
    end
    if not pet.petDataInfo then
      baseIdArray[i] = tostring(pet.sharedPetData.base_conf_id)
    else
      baseIdArray[i] = "nil"
    end
    local skills = pet.petData.skills
    if skills then
      for j = 1, #skills do
        if 0 == skills[j].id then
          skillArray[4 * (i - 1) + j] = pet.sharedPetData.skills[j].id
        else
          skillArray[4 * (i - 1) + j] = "nil"
        end
      end
    end
    i = i + 1
  end
  local value = string.format("%s|%s|%d|%d|%s|%s|%d|%d|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", key, roleDataStr, RankName, TeamID, PlayerName, TeamCode, TalentDiffCount, BloodDiffCount, CharacterDiffCount, baseIdArray[1], baseIdArray[2], baseIdArray[3], baseIdArray[4], baseIdArray[5], baseIdArray[6], skillArray[1], skillArray[2], skillArray[3], skillArray[4], skillArray[5], skillArray[6], skillArray[7], skillArray[8], skillArray[9], skillArray[10], skillArray[11], skillArray[12], skillArray[13], skillArray[14], skillArray[15], skillArray[16], skillArray[17], skillArray[18], skillArray[19], skillArray[20], skillArray[21], skillArray[22], skillArray[23], skillArray[24])
  _G.GEMPostManager:SendNRCTLog(key, value)
end

return UMG_LineupAdjustment_C
