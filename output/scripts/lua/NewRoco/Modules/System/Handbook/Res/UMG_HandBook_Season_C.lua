local UMG_HandBook_Season_C = _G.NRCPanelBase:Extend("UMG_HandBook_Season_C")

function UMG_HandBook_Season_C:OnActive(season_id)
  _G.NRCAudioManager:PlaySound2DAuto(1220002047, "UMG_HandBook_Season_C:OnActive")
  self.seasonId = season_id
  self.bOpen = false
  self:OnAddEventListener()
  self:InitPanel()
end

function UMG_HandBook_Season_C:OnDeactive()
end

function UMG_HandBook_Season_C:OnAddEventListener()
  self:AddButtonListener(self.BookButton, self.OnClickBookButton)
  self:AddButtonListener(self.close_btn, self.OnClickedClose)
end

function UMG_HandBook_Season_C:InitPanel()
  self.close_btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.DarkBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SeasonInfoList:SetRenderOpacity(0)
  self.SeasonInfoList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  local currentSeason = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetCurrentSeason)
  local seasonInfo = {}
  local seasonConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SEASON_CONF):GetAllDatas()
  for _, conf in pairs(seasonConf or {}) do
    if conf then
      if currentSeason and currentSeason >= conf.id then
        local temp = {conf = conf, parent = self}
        table.insert(seasonInfo, temp)
      end
      if self.seasonId and conf.id == self.seasonId then
        self.NameText:SetText(conf.s_title_subtitle)
        self.NRCImage_0:SetPath(conf.big_icon)
      end
    end
  end
  table.sort(seasonInfo, function(a, b)
    return a.conf.id < b.conf.id
  end)
  self.SeasonInfoList:InitList(seasonInfo)
  self.SeasonInfoList:SelectItemByIndex(self.seasonId - 1)
  self.RedDot:SetupKey(477)
end

function UMG_HandBook_Season_C:UpdateSeasonId(newSeasonId)
  if newSeasonId == self.seasonId then
    return
  end
  self.seasonId = newSeasonId
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonId)
  if seasonConf then
    self.NameText:SetText(seasonConf.s_title_subtitle)
    self.NRCImage_0:SetPath(seasonConf.big_icon)
  end
end

function UMG_HandBook_Season_C:OnClickBookButton()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  if self.bOpen then
    self:OnClickedClose()
  else
    _G.NRCAudioManager:PlaySound2DAuto(40008024, "UMG_HandBook_Season_C:OnClickBookButton")
    self.close_btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DarkBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonInfoList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonInfoList:SetRenderOpacity(1)
    self.bOpen = true
    self:PlayAnimation(self.In)
  end
end

function UMG_HandBook_Season_C:OnClickedClose()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008025, "UMG_HandBook_Season_C:OnClickedClose")
  self.bOpen = false
  self:PlayAnimation(self.Out)
end

function UMG_HandBook_Season_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self.close_btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DarkBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SeasonInfoList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SeasonInfoList:SetRenderOpacity(0)
  end
end

function UMG_HandBook_Season_C:OnPcClose()
  if self.bOpen then
    self:OnClickedClose()
  else
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.CloseSeasonHandBook)
  end
end

return UMG_HandBook_Season_C
