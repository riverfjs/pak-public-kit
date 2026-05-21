local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local UMG_SeasonIntegrationPopUp_C = _G.NRCPanelBase:Extend("UMG_SeasonIntegrationPopUp_C")
local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")

function UMG_SeasonIntegrationPopUp_C:OnActive(tipsId, seasonId)
  local tipsConf = _G.DataConfigManager:GetSeasonTipsTabConf(tipsId)
  if tipsConf then
    self.PopUp.TitleText:SetText(tipsConf.tips_name)
    if not tipsConf.tab_group or 0 == #tipsConf.tab_group then
      self.ListTab:Clear()
      return
    end
    self.curTabGroup = tipsConf.tab_group
    self.ListTab:InitGridView(tipsConf.tab_group)
    self.ListTab:SelectItemByIndex(0)
  end
  self.seasonId = seasonId
end

function UMG_SeasonIntegrationPopUp_C:OnDeactive()
end

function UMG_SeasonIntegrationPopUp_C:ShowNewPetTab(pageID)
  local seasonTipsNewPetConf = _G.DataConfigManager:GetSeasonTipsNewPetConf(pageID)
  if seasonTipsNewPetConf then
    self.Top_Text:SetText(seasonTipsNewPetConf.top_text)
    self.Middle_Text:SetText(seasonTipsNewPetConf.middle_text)
    local petList = {}
    for i = 1, #seasonTipsNewPetConf.new_pet do
      table.insert(petList, {
        id = seasonTipsNewPetConf.new_pet[i],
        bShiny = false
      })
    end
    self.List_NewPet:InitGridView(petList)
    local shinyPetList = {}
    for i = 1, #seasonTipsNewPetConf.new_shiny_pet do
      table.insert(shinyPetList, {
        id = seasonTipsNewPetConf.new_shiny_pet[i],
        bShiny = true
      })
    end
    self.List_NewShinyPet:InitGridView(shinyPetList)
  end
end

function UMG_SeasonIntegrationPopUp_C:ShowPVPTab(pageID)
  local seasonTipsPvpConf = _G.DataConfigManager:GetSeasonTipsPvpConf(pageID)
  if seasonTipsPvpConf then
    self.NRCImage_BannerImg:SetPath(seasonTipsPvpConf.banner_img)
    local pvpSeasonId = seasonTipsPvpConf and seasonTipsPvpConf.pvp_season_id
    local pvpRankSeasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(pvpSeasonId)
    if pvpRankSeasonConf then
      local year1, month1, day1, hour1, min1 = pvpRankSeasonConf.start_time:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
      local year2, month2, day2, hour2, min2 = pvpRankSeasonConf.end_time1:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
      self.TextTime:SetText(string.format(LuaText.season_tips_PVP_time, year1, month1, day1, hour1, min1) .. "-" .. string.format(LuaText.season_tips_PVP_time, year2, month2, day2, hour2, min2))
    end
    local itemList = {}
    for i = 1, #seasonTipsPvpConf.tab_group do
      local classIcon = ""
      local classNumber = ""
      local pvpRankConf = _G.DataConfigManager:GetPvpRankConf(seasonTipsPvpConf.tab_group[i].rank)
      local rankListItem = PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(pvpRankConf, pvpSeasonId)
      if rankListItem then
        classIcon = rankListItem and rankListItem.mini
      end
      if pvpRankConf then
        classNumber = pvpRankConf.number
      end
      local rewardConf = _G.DataConfigManager:GetRewardConf(seasonTipsPvpConf.tab_group[i].reward)
      if rewardConf then
        local rewards = rewardConf.RewardItem
        for j = 1, #rewards do
          if rewards[j].Type == Enum.GoodsType.GT_BAGITEM then
            table.insert(itemList, {
              itemType = _G.Enum.GoodsType.GT_BAGITEM,
              itemId = rewards[j].Id,
              itemNum = rewards[j].Count,
              bShowNum = true,
              classIcon = classIcon,
              classNumber = classNumber
            })
          end
          if rewards[j].Type == Enum.GoodsType.GT_VITEM then
            table.insert(itemList, {
              itemType = _G.Enum.GoodsType.GT_VITEM,
              itemId = rewards[j].Id,
              itemNum = rewards[j].Count,
              bShowNum = true,
              classIcon = classIcon,
              classNumber = classNumber
            })
          end
          if rewards[j].Type == Enum.GoodsType.GT_CARD_LABEL then
            table.insert(itemList, {
              itemType = _G.Enum.GoodsType.GT_CARD_LABEL,
              itemId = rewards[j].Id,
              itemNum = rewards[j].Count,
              bShowNum = true,
              classIcon = classIcon,
              classNumber = classNumber
            })
          end
        end
      end
    end
    self.RewardList:InitList(itemList)
  end
end

function UMG_SeasonIntegrationPopUp_C:ShowTxtTab(pageID)
  local seasonTipsTxtConf = _G.DataConfigManager:GetSeasonTipsTxtConf(pageID)
  if seasonTipsTxtConf then
    self.NRCText_Title:SetText(seasonTipsTxtConf.subtiltle)
    self.NRCTextContent:SetText(seasonTipsTxtConf.text)
  end
end

function UMG_SeasonIntegrationPopUp_C:ShowComposeTab(pageID)
  local seasonComposeConf = _G.DataConfigManager:GetSeasonTptCommonConf(pageID)
  if seasonComposeConf then
    self.List_NewPet_1:InitGridView(seasonComposeConf.paragraph_group)
    self.List_NewPet_1:RefreshGridViewLayout()
  end
end

function UMG_SeasonIntegrationPopUp_C:ShowTabByIndex(index)
  if not self.curTabGroup then
    return
  end
  if index < 1 or index > #self.curTabGroup then
    return
  end
  local tab = self.curTabGroup[index]
  if not tab or not tab.page_type then
    Log.Error("UMG_SeasonIntegrationPopUp_C:ShowTabByIndex tab is nil")
    return
  end
  if tab.page_type == Enum.SeasonTipsPageType.SEASON_TPT_NEW_PET then
    self.NRCScrollView_0:NRCScrollToStart()
    self:ShowNewPetTab(tab.page_id)
  elseif tab.page_type == Enum.SeasonTipsPageType.SEASON_TPT_PVP then
    self:ShowPVPTab(tab.page_id)
  elseif tab.page_type == Enum.SeasonTipsPageType.SEASON_TPT_TXT then
    self:ShowTxtTab(tab.page_id)
  elseif tab.page_type == Enum.SeasonTipsPageType.SEASON_TPT_COMMON then
    self.NRCScrollView:NRCScrollToStart()
    self:ShowComposeTab(tab.page_id)
  end
  self.Switcher:SetActiveWidgetIndex(tab.page_type - 1)
end

function UMG_SeasonIntegrationPopUp_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.PopUp.FullScreen_Close, self.OnClickCloseBtn)
  self:RegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonPopUpTabSelect, self.OnSelectTab)
end

function UMG_SeasonIntegrationPopUp_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_SeasonIntegrationPopUp_C:OnDestruct()
  self:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonPopUpTabSelect)
end

function UMG_SeasonIntegrationPopUp_C:OnAnimationFinished(anim)
end

function UMG_SeasonIntegrationPopUp_C:OnClickCloseBtn()
  self:DoClose()
end

function UMG_SeasonIntegrationPopUp_C:OnSelectTab(pageIndex)
  self:ShowTabByIndex(pageIndex)
end

return UMG_SeasonIntegrationPopUp_C
