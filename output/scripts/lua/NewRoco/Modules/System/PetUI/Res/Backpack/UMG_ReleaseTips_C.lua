local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_ReleaseTips_C = _G.NRCPanelBase:Extend("UMG_ReleaseTips_C")

function UMG_ReleaseTips_C:OnActive(PetData, _teamInfo, ParamCall, IsOpenInFreePanel, FreeReasonType, OpenType)
  self:LoadAnimation(0)
  self:BindInputAction()
  self.FreeReasonType = FreeReasonType or PetUIModuleEnum.PetFreeReasonType.None
  self.OpenType = OpenType or PetUIModuleEnum.ReleaseTipsOpenType.None
  self.ParamCall = ParamCall
  local petInfos = {
    {
      petData = PetData,
      InitSelect = false,
      bgPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal1_png.img_daojukuangnormal1_png'"
    }
  }
  self.ExChangeItemList:InitGridView(petInfos)
  local PvpConf = _G.DataConfigManager:GetAllByName("PVP_CONF")
  local teamText = LuaText.participated_pet_from_team .. "\n"
  for i, v in ipairs(_teamInfo) do
    local formatStr = "%s%s: <span color=\"#d56c1f\">%s</>\n"
    if i == #_teamInfo then
      formatStr = "%s%s: <span color=\"#d56c1f\">%s</>"
    end
    local teamInfo = v.teamInfo
    local teamIndex = v.teamIndex
    local find = false
    local teamName = self:GetTeamName(teamInfo.teams[teamIndex].team_name, teamIndex)
    for j, conf in pairs(PvpConf) do
      if conf.team_type == teamInfo.team_type then
        teamText = string.format(formatStr, teamText, conf.name, teamName)
        find = true
        break
      end
    end
    if not find then
      local Text = LuaText.challenge_title_1
      local Text_1 = LuaText.challenge_title_2
      local Text_2 = LuaText.weekly_challenge_topic_1
      if teamInfo.team_type == Enum.PlayerTeamType.PTT_PVE_CHALLENGE_ALTER then
        local formatStr1 = "%s%s/%s: <span color=\"#d56c1f\">%s</>\n"
        if i == #_teamInfo then
          formatStr1 = "%s%s/%s: <span color=\"#d56c1f\">%s</>"
        end
        teamText = string.format(formatStr1, teamText, Text, Text_1, teamName)
      end
      if teamInfo.team_type == Enum.PlayerTeamType.PTT_PVE_NPC_CHALLENGE_FIGHT then
        teamText = string.format(formatStr, teamText, Text, teamName)
      end
      if teamInfo.team_type == Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT then
        teamText = string.format(formatStr, teamText, Text_1, teamName)
      end
      if teamInfo.team_type == Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT then
        local text = LuaText.umg_pvp_matching_8
        local str = "%s%s%s\n"
        if i == #_teamInfo then
          str = "%s%s%s"
        end
        teamText = string.format(str, teamText, Text_2, text)
      end
    end
  end
  self.Desc:SetText(teamText)
  self:OnAddEventListener()
  if IsOpenInFreePanel then
    self.PopUp4:SetDescInfo(LuaText.participated_pet_free_tips1)
  else
    self.PopUp4:SetDescInfo(LuaText.participated_pet_free_tips2)
  end
  if OpenType == PetUIModuleEnum.ReleaseTipsOpenType.TraceBack then
    self.PopUp4:SetDescInfo(LuaText.pet_return_confiim_tip)
  end
end

function UMG_ReleaseTips_C:GetTeamName(teamName, teamIndex)
  if not teamName or "" == teamName then
    local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
    return string.format(teamNameCfg.str, teamIndex)
  else
    return teamName
  end
end

function UMG_ReleaseTips_C:OnDeactive()
  self:UnBindInputAction()
end

function UMG_ReleaseTips_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
end

function UMG_ReleaseTips_C:OnAddEventListener()
  self:SetCommonPopUpInfo(self.PopUp4)
end

function UMG_ReleaseTips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_ReleaseTips_C:ClosePanel()
  self:LoadAnimation(2)
end

function UMG_ReleaseTips_C:OnBtnLeftClicked()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  self:ClosePanel()
end

function UMG_ReleaseTips_C:OnBtnRightClicked()
  if self.ParamCall then
    self.ParamCall.callback(self.ParamCall.caller, self.FreeReasonType)
  end
  self:ClosePanel()
end

function UMG_ReleaseTips_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.Btn_RightText = LuaText.umg_bag_popup_2
  CommonPopUpData.Btn_LeftText = LuaText.umg_bag_popup_1
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnLeftClicked
  CommonPopUpData.Btn_RightHandler = self.OnBtnRightClicked
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_ReleaseTips_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_CommonCloseUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseUI", self, "OnPcClose2")
  end
end

function UMG_ReleaseTips_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_CommonCloseUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseUI")
  end
  self:RemoveInputMappingContext("IMC_CommonCloseUI")
end

function UMG_ReleaseTips_C:OnPcClose2()
  self:ClosePanel()
end

return UMG_ReleaseTips_C
