local UIUtils = require("NewRoco.Utils.UIUtils")
local PetTeamUtils = require("NewRoco.Modules.System.PetUI.Res.PetTeam.PetTeamUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_FriendTeam_LineupDetails_C = _G.NRCPanelBase:Extend("UMG_FriendTeam_LineupDetails_C")

function UMG_FriendTeam_LineupDetails_C:OnConstruct()
  self.data = self.module:GetData("PetUIModuleData")
  self.BtnImport_Grey.HideAnim = true
  self.BtnImport_Grey:SetIsEnabled(true)
  self:SetChildViews(self.PopUp1, self.PopUp2)
  self:OnAddEventListener()
end

function UMG_FriendTeam_LineupDetails_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_FriendTeam_LineupDetails_C:OnActive(friendTeamDetailsParam)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_FriendTeam_LineupDetails_C:OnActive")
  self.FriendTeamDetailsParam = friendTeamDetailsParam
  if self.FriendTeamDetailsParam.IsUnlockTeamShare and not self.FriendTeamDetailsParam.HasTrialPet then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  end
  self:InitCommonPopUp()
  self:UpdatePetList()
  self:UpdateTeamName()
  self:UpdateRoleMagicInfo()
end

function UMG_FriendTeam_LineupDetails_C:OnDeactive()
end

function UMG_FriendTeam_LineupDetails_C:OnAddEventListener()
  self:AddButtonListener(self.BtnReport.btnLevelUp, self.OnReportBtn)
  self:AddButtonListener(self.BtnCopy.btnLevelUp, self.OnCopyBtn)
  self:AddButtonListener(self.BtnImport.btnLevelUp, self.OnImPortBtn)
  self:AddButtonListener(self.BtnImport_Grey.btnLevelUp, self.OnImPortBtn)
end

function UMG_FriendTeam_LineupDetails_C:OnImPortBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_FriendTeam_LineupDetails_C:OnImPortBtn")
  if self.FriendTeamDetailsParam.IsUnlockTeamShare and not self.FriendTeamDetailsParam.HasTrialPet then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenFriendMirrorPetTeamCoverPanel, self.FriendTeamDetailsParam.TeamType, self.FriendTeamDetailsParam.PetTeam.team_idx, self.FriendTeamDetailsParam.FriendUin, self.FriendTeamDetailsParam.PetTeam)
  elseif self.FriendTeamDetailsParam.HasTrialPet then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_random_pet)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_import_failed)
  end
end

function UMG_FriendTeam_LineupDetails_C:OnRemoveEventListener()
end

function UMG_FriendTeam_LineupDetails_C:InitCommonPopUp()
  self:SetCommonPopUpInfo(self.PopUp1)
  self:SetCommonPopUpInfo(self.PopUp2)
  if self.FriendTeamDetailsParam.PetTeam.pet_infos and #self.FriendTeamDetailsParam.PetTeam.pet_infos > 3 then
    self.PopUp1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp2:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.PopUp1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PopUp2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_FriendTeam_LineupDetails_C:UpdatePetList()
  local FriendTeamDetailsItemDataList = {}
  for _, petInfo in ipairs(self.FriendTeamDetailsParam.PetTeam.pet_infos) do
    local itemData = {}
    itemData.SkillEquipList = petInfo.equip_infos
    itemData.PetData = self.data:GetPetDataByFriendUinAndPetGid(self.FriendTeamDetailsParam.FriendUin, petInfo.pet_gid)
    if itemData.PetData then
      table.insert(FriendTeamDetailsItemDataList, itemData)
    else
      Log.ErrorFormat("UMG_FriendTeam_LineupDetails_C:UpdatePetList \230\178\161\230\156\137\230\137\190\229\136\176\229\165\189\229\143\139\229\174\160\231\137\169\230\149\176\230\141\174 FriendUin: %s, PetGid: %s", tostring(self.FriendTeamDetailsParam.FriendUin), tostring(petInfo.pet_gid))
    end
  end
  self.ItemList:InitGridView(FriendTeamDetailsItemDataList)
end

function UMG_FriendTeam_LineupDetails_C:UpdateRoleMagicInfo()
  local hasMagic = false
  local petTeam = self.FriendTeamDetailsParam.PetTeam
  if petTeam.mirror_magic_id and 0 ~= petTeam.mirror_magic_id then
    local PlayerMagicConf = _G.DataConfigManager:GetBagItemConf(petTeam.mirror_magic_id)
    if PlayerMagicConf then
      hasMagic = true
      self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Icon:SetPath(PlayerMagicConf.icon)
    end
  end
  if not hasMagic then
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_FriendTeam_LineupDetails_C:UpdateTeamName()
  local teamNameStr
  local teamName = self.FriendTeamDetailsParam.PetTeam.team_name
  if not teamName or "" == teamName then
    local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
    teamNameStr = string.format(teamNameCfg.str, self.FriendTeamDetailsParam.PetTeam.team_idx + 1)
  else
    teamNameStr = teamName
  end
  self.teamName = teamNameStr
  UIUtils.SafeSetText(self.Text_1, teamNameStr)
end

function UMG_FriendTeam_LineupDetails_C:OnReportBtn()
  local ReportData = {}
  ReportData.uin = self.FriendTeamDetailsParam.FriendUin
  ReportData.business_data = {}
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_PERSONAL_INFORMATION_SCENE
  ReportData.business_data.signature = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_FriendTeam_LineupDetails_C:OnReportBtn")
  UIUtils.SafeSetVisibility(self, UE4.ESlateVisibility.Collapsed)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendReport, ReportData, self, self.OnFriendReportCloseCallback)
end

function UMG_FriendTeam_LineupDetails_C:OnFriendReportCloseCallback()
  Log.Info("UMG_FriendTeam_LineupDetails_C:OnFriendReportCloseCallback")
  UIUtils.SafeSetVisibility(self, UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_FriendTeam_LineupDetails_C:OnCopyBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FriendTeam_LineupDetails_C:OnReportBtn")
  local teamName = self.teamName
  local teamType = self.FriendTeamDetailsParam.TeamType
  local roleMagicID = self.FriendTeamDetailsParam.PetTeam.mirror_magic_id
  local sharedPetInfoList = {}
  for _, petInfo in ipairs(self.FriendTeamDetailsParam.PetTeam.pet_infos) do
    local petData = self.data:GetPetDataByFriendUinAndPetGid(self.FriendTeamDetailsParam.FriendUin, petInfo.pet_gid)
    if petData then
      local petSkillEquipInfoList
      if petInfo.equip_infos and #petInfo.equip_infos > 0 then
        petSkillEquipInfoList = petInfo.equip_infos
      else
        petSkillEquipInfoList = PetUtils.GetPetSkillEquipInfoListFromPetData(petData)
      end
      local sharedPetInfo = PetTeamUtils.GetSharedPetInfoFromFriendTeamInfo(petData, petSkillEquipInfoList)
      if sharedPetInfo then
        table.insert(sharedPetInfoList, sharedPetInfo)
      end
    end
  end
  Log.InfoFormat("UMG_FriendTeam_LineupDetails_C:OnCopyBtn teamName: %s, teamType: %s, roleMagicID: %s petNum: %s", tostring(teamName), tostring(teamType), tostring(roleMagicID), tostring(#sharedPetInfoList))
  local encodePetData = NRCModuleManager:DoCmd(PetUIModuleCmd.EncodeShareTeamCode, sharedPetInfoList, roleMagicID, teamType, teamName)
  UE4.UNRCStatics.ClipboardCopy(encodePetData)
  Log.InfoFormat("UMG_FriendTeam_LineupDetails_C:OnCopyBtn \229\164\141\229\136\182\233\152\181\229\174\185\231\160\129:\n%s", encodePetData)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy)
end

function UMG_FriendTeam_LineupDetails_C:OnAnimationFinished(anim)
end

function UMG_FriendTeam_LineupDetails_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_FriendTeam_LineupDetails_C:OnCloseClick()
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_FriendTeam_LineupDetails_C:OnCloseClick")
  self:DoClose()
end

return UMG_FriendTeam_LineupDetails_C
