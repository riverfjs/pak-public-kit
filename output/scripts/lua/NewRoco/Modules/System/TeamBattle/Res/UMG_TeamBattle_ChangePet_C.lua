local UMG_TeamBattle_ChangePet_C = _G.NRCPanelBase:Extend("UMG_TeamBattle_ChangePet_C")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_TeamBattle_ChangePet_C:OnActive()
  self.bStartTick = true
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddToDisableLobbyMainPopUpList, "ChangePetPanel")
  self.module:OnCmdZoneTeamBattleSelectPetReq(1)
  self:SetCommonPopUpInfo(self.PopUp3)
  self:InitPanelInfo()
  self:LoadAnimation(0)
end

function UMG_TeamBattle_ChangePet_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveFromDisableLobbyMainPopUpList, "ChangePetPanel")
end

function UMG_TeamBattle_ChangePet_C:OnAddEventListener()
  self:AddButtonListener(self.NRCButton, self.OnClickedRightBtn)
  self:AddButtonListener(self.NRCButton_68, self.OnClickedLeftBtn)
end

function UMG_TeamBattle_ChangePet_C:OnRemoveEventListener()
end

function UMG_TeamBattle_ChangePet_C:OnConstruct()
  self.data = self.module:GetData("TeamBattleModuleData")
  self.bStartTick = false
  self:SetChildViews(self.PopUp3)
  self:OnAddEventListener()
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "ChangePetPanel")
end

function UMG_TeamBattle_ChangePet_C:OnDestruct()
  self.bStartTick = false
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "ChangePetPanel")
end

function UMG_TeamBattle_ChangePet_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnCancelBtnClicked
  CommonPopUpData.Btn_RightHandler = self.OnConfirmBtnClicked
  CommonPopUpData.ClosePanelHandler = self.OnCancelBtnClicked
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_TeamBattle_ChangePet_C:OnTick(deltaTime)
  if self.bStartTick == true and self.module.CurChallengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE and self.module.CurChallengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    if self.module.LeftTime >= 0 then
      local percent = self.module.LeftTime / self.module.CountDownTime
      self.JinduProgressBar:SetPercent(percent)
      if true == self.module.ShowBtnTime then
        local text = string.format(LuaText.umg_teambattle_changepet_1, math.ceil(self.module.LeftTime))
        self.PopUp3:SetBtnLeftText(text)
      end
    end
    if self.module.LeftTime <= 0 then
      self:DoClose()
    end
  end
end

function UMG_TeamBattle_ChangePet_C:OnCancelBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_TeamBattle_ChangePet_C:OnCancelBtnClicked")
  self:LoadAnimation(1)
  self.module:OnCmdZoneTeamBattleSelectPetReq(2)
end

function UMG_TeamBattle_ChangePet_C:OnPcClose()
  self:OnCancelBtnClicked()
end

function UMG_TeamBattle_ChangePet_C:OnConfirmBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_TeamBattle_ChangePet_C:OnConfirmBtnClicked")
  self:LoadAnimation(1)
  self.module:OnCmdSetCurChoosePet(self.data.ChangePetPanelChoosePet.gid)
  local teamIndex = self:GetChooseTeamIndex()
  if teamIndex >= 0 then
    self.module:OpenTeamBattlePreparationPanel(self.data.ChangePetPanelChoosePet, 0, nil, teamIndex)
  else
    self.module:OpenTeamBattlePreparationPanel(self.data.ChangePetPanelChoosePet, 0)
  end
end

function UMG_TeamBattle_ChangePet_C:InitPanelInfo()
  if self.module.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or self.module.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    self.curBattleBaseId = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetBattlePetBaseId)
  elseif self.module.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.module.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    self.curBattleBaseId = self.module:GetOwnerSelectTeamBattlePetBaseId()
  end
  if self.module.CurChallengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE and self.module.CurChallengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  if PetTeams then
    local mainIndex = PetTeams.main_team_idx or 0
    self.curTeamIndex = mainIndex
    self.totalTeamNum = 0
    self.validTeamIndex = {}
    self.maxIndex = 1
    self.curIndex = 1
    if PetTeams.teams then
      for i, team in pairs(PetTeams.teams or {}) do
        if team and team.pet_infos then
          self.totalTeamNum = self.totalTeamNum + 1
          table.insert(self.validTeamIndex, i - 1)
          self.maxIndex = i - 1
        end
        for _, pet in pairs(team.pet_infos or {}) do
          if pet.pet_gid == self.data.curChoosePet then
            self.curTeamIndex = i - 1
            self.curIndex = #self.validTeamIndex
            break
          end
        end
      end
    end
  end
  if self.totalTeamNum > 1 then
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local dotInfo = {}
    for i = 1, self.totalTeamNum do
      table.insert(dotInfo, {index = i})
    end
    self.Dot_List:InitGridView(dotInfo)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateShowPets()
end

function UMG_TeamBattle_ChangePet_C:OnAnimationFinished(anim)
  if anim == self.Out or anim == self:GetAnimByIndex(1) then
    local panel = self.module:GetPanel("PreparationPanel")
    if panel then
      panel:Enable()
    end
    self:DoClose()
  end
end

function UMG_TeamBattle_ChangePet_C:OnClickedRightBtn()
  if self.curIndex < self.totalTeamNum then
    self.curIndex = self.curIndex + 1
  else
    self.curIndex = 1
  end
  self:UpdateShowPets()
end

function UMG_TeamBattle_ChangePet_C:OnClickedLeftBtn()
  if self.curIndex > 1 then
    self.curIndex = self.curIndex - 1
  else
    self.curIndex = self.totalTeamNum
  end
  self:UpdateShowPets()
end

function UMG_TeamBattle_ChangePet_C:UpdateShowPets()
  self.curTeamIndex = self.validTeamIndex[self.curIndex]
  local teamPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo(self.curTeamIndex)
  local PetInfo = {}
  for _, v in pairs(teamPetInfo or {}) do
    local data = {
      PetData = v,
      curBattleBaseId = self.curBattleBaseId
    }
    table.insert(PetInfo, data)
  end
  self.Pet_List:ClearSelection()
  self.Pet_List:InitGridView(PetInfo)
  for i, v in pairs(teamPetInfo or {}) do
    if v.gid == self.data.curChoosePet then
      self.Pet_List:SelectItemByIndex(i - 1)
      break
    end
  end
  self.Dot_List:SelectItemByIndex(self.curIndex - 1)
  self:UpdateTeamInfo()
end

function UMG_TeamBattle_ChangePet_C:UpdateTeamInfo()
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  if teamInfo and teamInfo.teams then
    local teamPetInfo = teamInfo.teams[self.curTeamIndex + 1]
    if teamPetInfo then
      local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
      if teamPetInfo.team_name then
        self.TeamName:SetText(teamPetInfo.team_name)
      else
        self.TeamName:SetText(string.format(default_name, self.curTeamIndex + 1))
      end
      local bagItems = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
      local hasRoleMagic = false
      for _, bagItem in pairs(bagItems or {}) do
        if bagItem.gid == teamPetInfo.role_magic_gid then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItem.id)
          if bagItemConf then
            self.TeamMagic:SetPath(bagItemConf.icon)
            hasRoleMagic = true
          end
          break
        end
      end
      if not hasRoleMagic then
        local path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_kong_png.img_kong_png'"
        self.TeamMagic:SetPath(path)
      end
    end
  end
end

function UMG_TeamBattle_ChangePet_C:GetChooseTeamIndex()
  local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  if PetTeams and PetTeams.teams then
    for i, team in pairs(PetTeams.teams or {}) do
      for _, pet in pairs(team.pet_infos or {}) do
        if pet.pet_gid == self.data.curChoosePet then
          return i - 1
        end
      end
    end
  end
  return -1
end

return UMG_TeamBattle_ChangePet_C
