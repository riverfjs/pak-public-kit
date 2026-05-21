local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")
local UMG_FriendTeam_AICoach1_C = _G.NRCPanelBase:Extend("UMG_FriendTeam_AICoach1_C")

function UMG_FriendTeam_AICoach1_C:OnActive(acivityid, teamData)
  self.teamData = teamData
  self.acivityid = acivityid
  self.PopUp3:SetBtnLeftText(LuaText.ai_coach_9)
  self.PopUp3:SetBtnRightText(LuaText.ai_coach_10)
  self.PopUp3:SetTitleTextInfo(LuaText.ai_coach_6)
  self.PopUp3:SetRightBtnTitleTextAndIconShow(false)
  self:OnRefreshInfo()
  self:OnAddEventListener()
  self:LoadAnimation(0)
end

function UMG_FriendTeam_AICoach1_C:OnDeactive()
  self:RemoveAllButtonListener()
end

function UMG_FriendTeam_AICoach1_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp3.Btn_Left.btnLevelUp, self.OnBtnLeftLevelUp)
  self:AddButtonListener(self.PopUp3.Btn_Right.btnLevelUp, self.OnBtnRightLevelUp)
  self:AddButtonListener(self.PopUp3.btnClose.btnClose, self.OnBtnClose)
end

function UMG_FriendTeam_AICoach1_C:OnBtnClose()
  self:LoadAnimation(2)
  self.reopen = false
end

function UMG_FriendTeam_AICoach1_C:OnBtnLeftLevelUp()
  self:LoadAnimation(2)
  self.reopen = true
end

function UMG_FriendTeam_AICoach1_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
    if self.reopen then
      _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyReOpenAIRequest)
    end
  end
end

function UMG_FriendTeam_AICoach1_C:OnBtnRightLevelUp()
  self:LoadAnimation(2)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnZoneSaveRecommendPetTeamReq, self.acivityid, self.teamData)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnReportRecommendTeamUseFeedback, ProtoEnum.ZoneAiCoachLineupFeedbackReq.TYPE.USE, self.teamData.team_id)
end

function UMG_FriendTeam_AICoach1_C:OnRefreshInfo()
  local data = {}
  data.HideBtn = true
  data.Panel = self
  data.team = {}
  data.team.team_name = self.teamData.team_name
  data.team.role_magic_gid = self.teamData.pet_team_info and self.teamData.pet_team_info.role_magic_id
  data.petList = {}
  local trialPets = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  for i, v in pairs(self.teamData.pet_team_info.pets) do
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
  self.ImportIineupItem:OnItemUpdate(data)
end

return UMG_FriendTeam_AICoach1_C
