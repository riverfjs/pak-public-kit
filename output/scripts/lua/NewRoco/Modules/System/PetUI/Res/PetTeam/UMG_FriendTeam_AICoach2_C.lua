local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")
local UMG_FriendTeam_AICoach2_C = _G.NRCPanelBase:Extend("UMG_FriendTeam_AICoach2_C")

function UMG_FriendTeam_AICoach2_C:OnActive(acivityid, teamData, teamData2)
  self.teamData = teamData
  self.teamData2 = teamData2
  self.acivityid = acivityid
  self.PopUp2:SetBtnLeftText(LuaText.ai_coach_9)
  self.PopUp2:SetBtnRightText(LuaText.ai_coach_14)
  self.PopUp2:SetTitleTextInfo(LuaText.ai_coach_6)
  self.PopUp2:SetRightBtnTitleTextAndIconShow(false)
  self:OnRefreshInfo()
  self:OnAddEventListener()
  self:LoadAnimation(0)
end

function UMG_FriendTeam_AICoach2_C:OnDeactive()
end

function UMG_FriendTeam_AICoach2_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp2.Btn_Left.btnLevelUp, self.OnBtnLeftLevelUp)
  self:AddButtonListener(self.PopUp2.Btn_Right.btnLevelUp, self.OnBtnRightLevelUp)
  self:AddButtonListener(self.PopUp2.btnClose.btnClose, self.OnBtnClose)
end

function UMG_FriendTeam_AICoach2_C:OnBtnClose()
  self:LoadAnimation(2)
  self.reopen = false
end

function UMG_FriendTeam_AICoach2_C:OnBtnLeftLevelUp()
  self:LoadAnimation(2)
  self.reopen = true
end

function UMG_FriendTeam_AICoach2_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    if self.reopen then
      _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyReOpenAIRequest)
    end
    self:DoClose()
  end
end

function UMG_FriendTeam_AICoach2_C:OnBtnRightLevelUp()
  self:LoadAnimation(2)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnZoneSaveRecommendPetTeamReq, self.acivityid, self.teamData)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnReportRecommendTeamUseFeedback, ProtoEnum.ZoneAiCoachLineupFeedbackReq.TYPE.REPLACE, self.teamData.team_id)
end

function UMG_FriendTeam_AICoach2_C:OnRefreshInfo()
  local data1 = self:OnConvertData(self.teamData, LuaText.ai_coach_12)
  local data2 = self:OnConvertData(self.teamData2, LuaText.ai_coach_13)
  local data = {data1, data2}
  self.LineupView:InitList(data)
end

function UMG_FriendTeam_AICoach2_C:OnConvertData(teamData, teamName)
  local data = {}
  data.HideBtn = true
  data.Panel = self
  data.team = {}
  data.team.team_name = teamName
  data.team.role_magic_gid = teamData.pet_team_info and teamData.pet_team_info.role_magic_id
  data.petList = {}
  local trialPets = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  for i, v in pairs(teamData.pet_team_info.pets) do
    local pet = {}
    pet.PetData = {
      mutation_type = Enum.MutationDiffType.MDT_NONE,
      glass_info = {
        glass_type = Enum.GlassType.GT_NULL,
        glass_value = 0
      },
      level = petLevel,
      base_conf_id = v.base_conf_id,
      isTrailPet = false
    }
    for _, trialPet in ipairs(trialPets) do
      if v.base_conf_id == trialPet.base_conf_id and not _G.DataModelMgr.PlayerDataModel:GetPetDataByPetBaseId(v.base_conf_id) then
        pet.PetData.isTrailPet = true
        break
      end
    end
    table.insert(data.petList, pet)
  end
  return data
end

return UMG_FriendTeam_AICoach2_C
