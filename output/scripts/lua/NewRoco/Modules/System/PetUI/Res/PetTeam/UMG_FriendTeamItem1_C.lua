local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_FriendTeamItem1_C = Base:Extend("UMG_FriendTeamItem1_C")

function UMG_FriendTeamItem1_C:OnConstruct()
  self.module = _G.NRCModuleManager:GetModule("PetUIModule")
  self:AddButtonListener(self.Btn_View.btnLevelUp, self.OpenDetailPanel)
  self:AddButtonListener(self.BtnCopy.btnLevelUp, self.CopyTeamCode)
end

function UMG_FriendTeamItem1_C:OnDestruct()
  self:RemoveButtonListener(self.Btn_View.btnLevelUp)
  self:RemoveButtonListener(self.BtnCopy.btnLevelUp)
end

function UMG_FriendTeamItem1_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  local trialPets = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  local AvatarPath = string.format("%s%s.%s'", path, _data.player_headpic, _data.player_headpic)
  self.PlayerNameText:SetText(_data.player_name)
  self.HeadPortrait:SetPath(AvatarPath)
  local petLevel = _data.pet_level
  local initData = {}
  local pet_team_info
  self.teamData = _data
  self.team_id = _data.team_id
  if _data.pet_team_info then
    pet_team_info = _data.pet_team_info
    local encodePetData = NRCModuleManager:DoCmd(_G.PetUIModuleCmd.EncodeShareTeamCode, pet_team_info.pets, pet_team_info.role_magic_id, pet_team_info.team_type, _data.team_name)
    self.teamShareCode = self:AddCodeAnnotation(encodePetData, pet_team_info.role_magic_id, _data.team_name, pet_team_info.pets)
  else
    local code = self.module:RemoveCodeAnnotation(_data.pet_team_share_id)
    pet_team_info = self.module:DecodeShareData(code)
    pet_team_info.team_type = _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4
    self.teamShareCode = self:AddCodeAnnotation(_data.pet_team_share_id, pet_team_info.role_magic_id, _data.team_name, pet_team_info.pets)
  end
  self.teamData.pet_team_info = pet_team_info
  self.TeamName:SetText(_data.team_name)
  self.MagicIcon:SetPath(_G.DataConfigManager:GetBagItemConf(pet_team_info.role_magic_id).icon)
  for _, v in ipairs(pet_team_info.pets) do
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
    table.insert(initData, pet)
  end
  self.PetGridView:InitGridView(initData)
end

function UMG_FriendTeamItem1_C:OnItemSelected(_bSelected)
end

function UMG_FriendTeamItem1_C:AddCodeAnnotation(shareCode, magicID, teamName, petData)
  local magicItemConf = _G.DataConfigManager:GetBagItemConf(magicID)
  local FullCode = "### " .. teamName .. "\n"
  local DebugData = {
    "# \233\173\148\230\179\149\239\188\154",
    "\239\188\154",
    "#\230\131\179\232\166\129\228\189\191\231\148\168\232\191\153\229\165\151\233\152\181\229\174\185\239\188\140\232\175\183\229\133\136\229\164\141\229\136\182\229\136\176\229\137\170\232\180\180\230\157\191\239\188\140\231\132\182\229\144\142\229\156\168\230\184\184\230\136\143\228\184\173\231\154\132\231\188\150\233\152\159\231\149\140\233\157\162\232\191\155\232\161\140\231\178\152\232\180\180\227\128\130"
  }
  if magicItemConf then
    FullCode = FullCode .. DebugData[1] .. magicItemConf.name .. "\n" .. "#\n"
  else
    FullCode = FullCode .. "#\n"
  end
  for i, pet in ipairs(petData) do
    if pet then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(pet.base_conf_id)
      local bloodConf = _G.DataConfigManager:GetPetBloodConf(pet.blood_id)
      FullCode = FullCode .. "# " .. petBaseConf.name .. DebugData[2] .. bloodConf.name
      FullCode = FullCode .. "\227\128\129{"
      if pet.skills then
        for j, skill in ipairs(pet.skills) do
          local skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
          FullCode = FullCode .. skillConf.name
          if j ~= #pet.skills then
            FullCode = FullCode .. "\227\128\129"
          end
        end
      end
      FullCode = FullCode .. "}\n"
    end
  end
  FullCode = FullCode .. "#\n"
  FullCode = FullCode .. shareCode .. "\n" .. "#\n"
  FullCode = FullCode .. DebugData[3]
  return FullCode
end

function UMG_FriendTeamItem1_C:OpenDetailPanel()
  self.module:GetData():SetShiningWeekendTeamOpenIndex(self.index)
  if self.team_id >= 10000 then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.UseAICoachRecommendTeam, self.teamData)
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLoadPetTeamPanel, self.teamData.pet_team_info.team_type, -1, self.teamShareCode)
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.SendShiningWeekendTLog, 5)
  self:OnReportAICoachLog("team_apply_click", self.team_id)
end

function UMG_FriendTeamItem1_C:CopyTeamCode()
  UE4.UNRCStatics.ClipboardCopy(self.teamShareCode)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FriendTeamItem1_C:CopyTeamCode")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("lineup_code_copy").msg)
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.SendShiningWeekendTLog, 4)
  self:OnReportAICoachLog("team_copy_click", self.team_id)
end

function UMG_FriendTeamItem1_C:OnReportAICoachLog(key, value)
  local isAICoachOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsCurrAICoachOpen)
  local isAIInWhiteList = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsPlayerInWhiteList)
  local isSystemOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetSysAICoachSceneIsOpen, Enum.FunctionEntrance.FE_AI_COACH_TEAM)
  if isAICoachOpen and isAIInWhiteList and isSystemOpen then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, key, value)
  end
end

return UMG_FriendTeamItem1_C
