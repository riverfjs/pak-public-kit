local Base = require("NewRoco.Modules.Activity.Activity.Res.UMG_Activity_TakePhotoCompetition_RankingsBase_C")
local UMG_Activity_TakePhotoCompetition_Rankings_C = Base:Extend("UMG_Activity_TakePhotoCompetition_Rankings_C")

function UMG_Activity_TakePhotoCompetition_Rankings_C:OnConstruct()
  Base.OnConstruct(self)
  self:SetChildViews(self.PhotoFile, self.LoadUpload)
  self:AddButtonListener(self.btnClose.btnClose, self.ClosePanel)
  self:AddButtonListener(self.ClickMyRank, self.OnClickMyRankData)
  self:AddButtonListener(self.PhotoBtn, self.OnClickPhotoBtn)
  self:SetCommonTitle(self.Title1)
  self.MyText:SetText(_G.LuaText.pic_game_rankboard_mine)
  self.WidgetSwitcher_Image:SetActiveWidgetIndex(0)
  self.Name:SetText(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
  self.npcIcon:SetPath(self:GetPlayerHeadIcon())
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_TakePhotoCompetition_Rankings_C:ClosePanel")
  self:OnClose()
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:OnDestruct()
  Base.OnDestruct(self)
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:OnActive(activityInst, rankDataObject, prefetching)
  _G.NRCAudioManager:PlaySound2DAuto(40008039, "UMG_Activity_TakePhotoCompetition_Rankings_C:OnActive")
  self.activityInst = activityInst
  local cfg = activityInst:GetCurrentPhaseConf()
  self.Numbers:SetPath(cfg and self:GetNumberImage(cfg.id) or "")
  self.Text_Title:SetText(cfg and cfg.name or "")
  self.Text_Describe:SetText(cfg and cfg.desc or "")
  if prefetching then
    self.LoadUpload:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.LoadUpload:SetLoading(_G.LuaText.pic_game_rankboard_load_text, true, true)
  end
  self.rankDataController:BindRankDataObject(rankDataObject)
  local playerRankData = rankDataObject:GetPlayerRankData(true)
  if playerRankData then
    self:RefreshPlayerRankData(playerRankData)
  else
    self:OnRefreshPlayerRankData(nil)
  end
  if cfg then
    self:SetCardBg(cfg.id, self.CardSwitcher)
  end
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:BindUIElements()
  local uiElements = {}
  uiElements.photoFile = self.PhotoFile
  uiElements.photoSwitcher = self.WidgetSwitcher_Image
  uiElements.rankList = self.rankList
  uiElements.emptyState = self.EmptyState
  uiElements.emptyText = self.Text_Empty
  uiElements.loadState = self.LoadUpload
  return uiElements
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:GetIsPlayerSubmit()
  local activityInst = self.activityInst
  return activityInst and not not activityInst:GetMySubmission()
end

function UMG_Activity_TakePhotoCompetition_Rankings_C:OnRefreshPlayerRankData(rankData)
  local hasSubmission = rankData and self:GetIsPlayerSubmit()
  local rankDataBrief = self:CreateRankUserBrief(rankData, hasSubmission)
  self.Score:SetText(rankDataBrief.score or "")
  if hasSubmission then
    self.NRCSwitcher:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    if not string.IsNilOrEmpty(rankDataBrief.estimatedRank) then
      self.NRCSwitcher:SetActiveWidgetIndex(3)
      self.RankNum_1:SetText(string.safeFormat("%s%s", _G.LuaText.pic_game_rankboard_percent, rankDataBrief.estimatedRank))
    elseif rankDataBrief.rank >= 1 and rankDataBrief.rank <= 3 then
      self.NRCSwitcher:SetActiveWidgetIndex(rankDataBrief.rank - 1)
    else
      self.NRCSwitcher:SetActiveWidgetIndex(3)
      if rankDataBrief.rank > 0 then
        self.RankNum_1:SetText(rankDataBrief.rank)
      else
        self.RankNum_1:SetText(string.safeFormat("%s%s", _G.LuaText.pic_game_rankboard_percent, "100%"))
      end
    end
  else
    self.NRCSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  end
end

return UMG_Activity_TakePhotoCompetition_Rankings_C
