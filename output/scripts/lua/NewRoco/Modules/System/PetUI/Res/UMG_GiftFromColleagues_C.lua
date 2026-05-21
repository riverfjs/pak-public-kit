local UMG_GiftFromColleagues_C = _G.NRCPanelBase:Extend("UMG_GiftFromColleagues_C")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_GiftFromColleagues_C:OnActive(petData)
  self.petData = petData
  self:SetCommonPopUpInfo(self.PopUp4)
  self:SetPanelInfo()
  self:LoadAnimation(0)
end

function UMG_GiftFromColleagues_C:OnDeactive()
end

function UMG_GiftFromColleagues_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
end

function UMG_GiftFromColleagues_C:OnTick(deltaTime)
  if self.petData and self.petData.together_catch_info and self.petData.together_catch_info.transfer_deadline then
    local deadline = self.petData.together_catch_info.transfer_deadline
    local isFirstShow = false
    if not self.curTime then
      self.curTime = 0
      isFirstShow = true
    end
    if isFirstShow or self.curTime + deltaTime >= 1 then
      local Text = LuaText.peer_pet_give_affirm_btn_affirm_content_time_text
      local TimeText = self:GetTimeText(deadline)
      self.PopUp4:SetDescInfo(string.format("%s%s", Text, TimeText))
      self.curTime = 0
    else
      self.curTime = self.curTime + deltaTime
    end
  end
end

function UMG_GiftFromColleagues_C:GetTimeText(deadline)
  local curTimeStamp = _G.ZoneServer:GetServerTime() / 1000
  local leftTime = ""
  local timeImg = "<img id=\"Time\"></>"
  if deadline <= curTimeStamp then
    local str = string.format(LuaText.peer_pet_give_affirm_time_s, "0")
    leftTime = string.format("%s%s", timeImg, str)
  else
    local totalTime = deadline - curTimeStamp
    local day = math.floor(totalTime / 86400)
    totalTime = totalTime % 86400
    local hour = math.floor(totalTime / 3600)
    totalTime = totalTime % 3600
    local minute = math.floor(totalTime / 60)
    local second = math.floor(totalTime % 60)
    local dayText = self:GetTimeTextInner(day, LuaText.peer_pet_give_affirm_time_d)
    local hourText = self:GetTimeTextInner(hour, LuaText.peer_pet_give_affirm_time_h)
    local minuteText = self:GetTimeTextInner(minute, LuaText.peer_pet_give_affirm_time_m)
    local secondText = self:GetTimeTextInner(second, LuaText.peer_pet_give_affirm_time_s)
    if 0 == day and 0 == hour and 0 == minute and 0 == second then
      secondText = string.format(LuaText.peer_pet_give_affirm_time_s, "0")
    end
    leftTime = string.format("%s%s%s%s%s", timeImg, dayText, hourText, minuteText, secondText)
  end
  return leftTime
end

function UMG_GiftFromColleagues_C:GetTimeTextInner(time, text)
  local resText = ""
  if time > 0 then
    resText = string.format(text, tostring(time))
  end
  return resText
end

function UMG_GiftFromColleagues_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  local TitleText = LuaText.peer_pet_give_affirm_title
  local RightBtnText = LuaText.peer_pet_give_affirm_btn_affirm_text
  local LeftBtnText = LuaText.peer_pet_give_affirm_btn_cancel_text
  CommonPopUpData.Btn_LeftText = LeftBtnText
  CommonPopUpData.Btn_RightText = RightBtnText
  CommonPopUpData.TitleText = TitleText
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClickedClose
  CommonPopUpData.Btn_RightHandler = self.OnClickedOK
  CommonPopUpData.ClosePanelHandler = self.OnClickedClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_GiftFromColleagues_C:SetPanelInfo()
  local bgPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal1_png.img_daojukuangnormal1_png'"
  local petInfos = {
    {
      petData = self.petData,
      InitSelect = false,
      bgPath = bgPath
    }
  }
  self.ExChangeItemList:InitGridView(petInfos)
  self:SetContentText()
end

function UMG_GiftFromColleagues_C:SetContentText()
  local IsInTeam, TeamInfo = PetUtils.GetIsInPvpOrPveTeamByGid(self.petData.gid)
  if IsInTeam then
    local teamText = LuaText.peer_pet_give_affirm_btn_affirm_content_pvp .. "\n"
    for i, v in ipairs(TeamInfo or {}) do
      local formatStr = "%s%s: <span color=\"#d56c1f\">%s</>\n"
      if i == #TeamInfo then
        formatStr = "%s%s: <span color=\"#d56c1f\">%s</>"
      end
      local teamInfo = v.teamInfo
      local teamIndex = v.teamIndex
      local find = false
      local PvpConf = _G.DataConfigManager:GetAllByName("PVP_CONF")
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
          if i == #TeamInfo then
            str = "%s%s%s"
          end
          teamText = string.format(str, teamText, Text_2, text)
        end
      end
    end
    self.ContentText:SetText(teamText)
  elseif self.petData and self.petData.name and self.petData.together_catch_info and self.petData.together_catch_info.related_name then
    local petName = self.petData.name
    local friendName = self.petData.together_catch_info.related_name
    local text = LuaText.peer_pet_give_affirm_btn_affirm_content
    self.ContentText:SetText(string.format(text, petName, friendName))
  end
end

function UMG_GiftFromColleagues_C:OnAddEventListener()
end

function UMG_GiftFromColleagues_C:GetTeamName(teamName, teamIndex)
  if not teamName or "" == teamName then
    local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
    return string.format(teamNameCfg.str, teamIndex)
  else
    return teamName
  end
end

function UMG_GiftFromColleagues_C:OnClickedOK()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendPetToFriend, self.petData.gid)
  self:LoadAnimation(2)
end

function UMG_GiftFromColleagues_C:OnClickedClose()
  self:LoadAnimation(2)
end

function UMG_GiftFromColleagues_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_GiftFromColleagues_C
