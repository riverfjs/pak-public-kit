local UMG_Activity_Common_C = _G.NRCPanelBase:Extend("UMG_Activity_Common_C")

function UMG_Activity_Common_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:SetCommonPopUpInfo()
  local pictureCustomData = {}
  pictureCustomData.controlByPageController = true
  self.Picture:SetCustomData(pictureCustomData)
  self.ScrollPageController:SetPageChangeHandler(self.OnPageChangeHandle, self)
  local leftArrow = {}
  leftArrow.Call = self
  leftArrow.btnHandler = self.OnClickPreviousBtn
  leftArrow.modeIndex = 3
  self.Btn2:SetBtnInfo(leftArrow)
  self.Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local rightArrow = {}
  rightArrow.Call = self
  rightArrow.btnHandler = self.OnClickNextBtn
  rightArrow.modeIndex = 4
  self.Btn1:SetBtnInfo(rightArrow)
  self.Btn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.Dot_List then
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Text1:SetText("")
end

function UMG_Activity_Common_C:OnActive(data)
  self.entries = data.entries
  if not string.IsNilOrEmpty(data.titleIcon) then
    self.PopUp:SetTitleIconInfo(data.titleIcon)
  end
  if not string.IsNilOrEmpty(data.titleText) then
    self.PopUp:SetTitleTextInfo(data.titleText)
  end
  local pageNum = #data.entries
  if pageNum > 1 then
    local pageData = {}
    for i = 1, pageNum do
      table.insert(pageData, i)
    end
    if self.Dot_List then
      self.Dot_List:InitGridView(pageData)
      self.Dot_List:SelectItemByIndex(0)
      self.Dot_List:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  end
  local pictures = {}
  for _, entry in ipairs(data.entries) do
    table.insert(pictures, entry.imagPath or "")
  end
  self.Picture:InitList(pictures)
  self.ScrollPageController:SetValidItemTotalNum(#pictures)
  self.ScrollPageController:ScrollToPage(0, 0.01)
  self:LoadAnimation(0)
end

function UMG_Activity_Common_C:OnDestruct()
end

function UMG_Activity_Common_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClickCloseBtn
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Activity_Common_C:OnPageChangeHandle(page)
  local pageNum = self.ScrollPageController:GetTotalPageNum()
  self.Btn2:SetVisibility(page > 0 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.Btn1:SetVisibility(page < pageNum - 1 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if self.Dot_List then
    self.Dot_List:SelectItemByIndex(page)
  end
  local entries = self.entries or {}
  local entry = entries[page + 1]
  local desc = entry and entry.desc or ""
  self.Text1:SetText(desc)
  if self.Text2 then
    self.Text2:SetText(desc)
  end
  if entry and not string.IsNilOrEmpty(entry.imagPath) then
    self.Switcher_0:SetActiveWidgetIndex(0)
  else
    self.Switcher_0:SetActiveWidgetIndex(1)
  end
end

function UMG_Activity_Common_C:ChangePage(curPage, newPage)
  local entries = self.entries or {}
  local curEntry = entries[curPage + 1]
  local curHasImage = curEntry and not string.IsNilOrEmpty(curEntry.imagPath)
  local newEntry = entries[newPage + 1]
  local newHasImage = newEntry and not string.IsNilOrEmpty(newEntry.imagPath)
  if not curHasImage or not newHasImage then
    self.ScrollPageController:ScrollToPage(newPage, 0.01)
  else
    self.ScrollPageController:ScrollToPage(newPage)
  end
  if not newHasImage then
    self.Switcher_0:SetActiveWidgetIndex(1)
  end
end

function UMG_Activity_Common_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_Common_C:OnClickCloseBtn")
  if self:GetAnimByIndex(2) then
    self:LoadAnimation(2)
  else
    self:DoClose()
  end
end

function UMG_Activity_Common_C:OnClickPreviousBtn()
  local curPage = self.ScrollPageController:GetCurrentPage() or 0
  if curPage > 0 then
    self:ChangePage(curPage, curPage - 1)
  end
end

function UMG_Activity_Common_C:OnClickNextBtn()
  local curPage = self.ScrollPageController:GetCurrentPage() or 0
  local pageNum = self.ScrollPageController:GetTotalPageNum() or 0
  if pageNum > curPage + 1 then
    self:ChangePage(curPage, curPage + 1)
  end
end

function UMG_Activity_Common_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_Activity_Common_C
