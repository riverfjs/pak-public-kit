local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local scrollStep = 100
local scrollSensitivity = 5
local UMG_SeasonalGroupPhoto_C = _G.NRCPanelBase:Extend("UMG_SeasonalGroupPhoto_C")

function UMG_SeasonalGroupPhoto_C:OnActive(seasonId, bOpenReward)
  self.seasonId = seasonId
  self:OnAddEventListener()
  self.touchStartPos = nil
  self.lastScrollOffset = 0
  self.isScrolling = false
  self:InitPanel()
  if bOpenReward then
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonRewardPanel, self.seasonId)
  end
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.AreaHandbookChangePanel)
end

function UMG_SeasonalGroupPhoto_C:OnDeactive()
  self.SeasonalGroupPhoto.OnLoadPanelCallbackDelegate:Remove(self, self.OnLoadWidgetCallback)
  if not self.module:HasPanel("HandbookCover") then
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCloseAreaHandbookChangPanel, true)
  end
end

function UMG_SeasonalGroupPhoto_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickedCloseBtn)
  self:AddButtonListener(self.CollectionProgressBtn, self.OnClickedCollectionProgressBtn)
  self:AddButtonListener(self.RewardBtn.btnLevelUp, self.OnClickedRewardBtn)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnClickedShareBtn)
  self.SeasonalGroupPhoto.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
end

function UMG_SeasonalGroupPhoto_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf("SeasonHandBook_S")
  if self.titleConf then
    self.Title1:Set_MainTitle(self.titleConf.title)
    self.Title1:SetBg(self.titleConf.head_icon)
  end
  if self.seasonId then
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonId)
    if seasonConf then
      local seasonName = seasonConf.s_title_subtitle
      if seasonName then
        self.Title1:SetSubtitle(seasonName)
      end
    end
  end
end

function UMG_SeasonalGroupPhoto_C:InitPanel()
  self:PlayAnimation(self.In)
  self:SetCommonTitle()
  if self.seasonId then
    self.RewardBtn.RedDot:SetupKey(479, {
      self.seasonId
    })
  end
  self.TabList1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:LoadSeasonPetPhoto()
end

function UMG_SeasonalGroupPhoto_C:LoadSeasonPetPhoto()
  if self.SeasonalGroupPhoto then
    local seasonHandbookConf = _G.DataConfigManager:GetSeasonHandbookConf(self.seasonId)
    if seasonHandbookConf then
      local path = seasonHandbookConf.share_umg_path
      local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(path)
      if softClassPath then
        self.SeasonalGroupPhoto:SetWidgetClass(softClassPath)
        self.SeasonalGroupPhoto:LoadPanel(nil)
      end
      local bgPath = seasonHandbookConf.big_bg_res
      self.BgPet:SetPath(bgPath)
    end
  end
end

function UMG_SeasonalGroupPhoto_C:OnLoadWidgetCallback()
  self:OnChangeSelectedPhotoType(ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW)
end

function UMG_SeasonalGroupPhoto_C:OnChangeSeason(newSeasonId)
  self:PlayAnimation(self.In)
  self.seasonId = newSeasonId
  self:SetCommonTitle()
  if self.seasonId then
    self.RewardBtn.RedDot:SetupKey(479, {
      self.seasonId
    })
  end
  self.touchStartPos = nil
  self.lastScrollOffset = 0
  self.isScrolling = false
  self.PhotoScrollBox:SetScrollOffset(0)
  self.SeasonalGroupPhoto:UnLoadPanel(true)
  self:LoadSeasonPetPhoto()
end

function UMG_SeasonalGroupPhoto_C:OnInitPhotoPanel()
  local type = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
  local photoPanel = self.SeasonalGroupPhoto:GetPanel()
  if photoPanel then
    photoPanel.PetSwitcher:SetActiveWidgetIndex(type - 1)
    local widget = photoPanel.PetSwitcher:GetActiveWidget()
    if widget then
      local childrenCount = widget:GetChildrenCount()
      for i = 0, childrenCount - 1 do
        local petIcon = widget:GetChildAt(i)
        if petIcon then
          petIcon:InitPanel()
        end
      end
    end
  end
end

function UMG_SeasonalGroupPhoto_C:OnChangeSelectedPhotoType(type)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetCurSelectedSeasonPhotoType, type)
  self:OnInitPhotoPanel()
  local totalNum, collectNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, self.seasonId, type)
  self.Quantity:SetText(string.format("%d/%d", collectNum, totalNum))
end

function UMG_SeasonalGroupPhoto_C:OnClickedCloseBtn()
  if self:IsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_SeasonalGroupPhoto_C:OnClickedCloseBtn")
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.CloseHandbookSeasonList)
  self:OnClose()
end

function UMG_SeasonalGroupPhoto_C:OnClickedCollectionProgressBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SeasonalGroupPhoto_C:OnClickedCollectionProgressBtn")
  local type = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
  local totalNum, collectNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, self.seasonId, type)
  local info = {
    seasonId = self.seasonId,
    collectedCount = collectNum,
    totalCount = totalNum,
    petType = type
  }
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenCollectionProgressTips, info)
end

function UMG_SeasonalGroupPhoto_C:OnClickedRewardBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SeasonalGroupPhoto_C:OnClickedRewardBtn")
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonRewardPanel, self.seasonId)
end

function UMG_SeasonalGroupPhoto_C:OnClickedShareBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SeasonalGroupPhoto_C:OnClickedShareBtn")
  local type = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
  local data = {
    seasonId = self.seasonId,
    petType = type
  }
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonPetPhotoShare, data)
end

function UMG_SeasonalGroupPhoto_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  self.touchStartPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(_MyGeometry, screenPos)
  self.lastScrollOffset = self.PhotoScrollBox:GetScrollOffset()
  self.isScrolling = false
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_SeasonalGroupPhoto_C:OnTouchMoved(_MyGeometry, _InTouchEvent)
  if not self.touchStartPos then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  local curPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(_MyGeometry, screenPos)
  local offsetX = self.touchStartPos.X - curPos.X
  if math.abs(offsetX) > scrollSensitivity and self.lastScrollOffset + offsetX >= 0 and self.lastScrollOffset + offsetX <= self.PhotoScrollBox:GetScrollOffsetOfEnd() then
    self.isScrolling = true
    local newOffset = self.lastScrollOffset + offsetX
    self.PhotoScrollBox:SetScrollOffset(newOffset)
    self.lastScrollOffset = newOffset
    self.touchStartPos = curPos
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_SeasonalGroupPhoto_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self.touchStartPos = nil
  self.isScrolling = false
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_SeasonalGroupPhoto_C:OnMouseWheel(MyGeometry, InTouchEvent)
  local wheelData = UE4.UKismetInputLibrary.PointerEvent_GetWheelDelta(InTouchEvent)
  if 0 ~= wheelData then
    self.touchStartPos = nil
    self.isScrolling = false
    local currentOffset = self.PhotoScrollBox:GetScrollOffset()
    local newOffset = currentOffset + -wheelData * scrollStep
    local maxOffset = self.PhotoScrollBox:GetScrollOffsetOfEnd()
    if newOffset < 0 then
      newOffset = 0
    elseif maxOffset < newOffset then
      newOffset = maxOffset
    end
    self.PhotoScrollBox:SetScrollOffset(newOffset)
    self.lastScrollOffset = newOffset
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_SeasonalGroupPhoto_C
