local UMG_PigmentAcquire_C = _G.NRCPanelBase:Extend("UMG_PigmentAcquire_C")

function UMG_PigmentAcquire_C:OnActive(data, bHiddenBtn, tabIndex, subTabIndex, petData)
  self.data = data
  self.tabIndex = tabIndex
  self.subTabIndex = subTabIndex
  self.petData = petData
  self.currentPage = 1
  self.glassTintNum = 0
  self.itemPerPage = 10
  self.startPage = 1
  if self.data then
    self.glassTintNum = #self.data
  end
  self.totalPage = math.ceil(self.glassTintNum / self.itemPerPage)
  self.bHiddenBtn = bHiddenBtn
  _G.NRCAudioManager:PlaySound2DAuto(40010011, "UMG_PigmentAcquire_C:OnActive")
  self:PlayAnimation(self.In)
  self:OnAddEventListener()
  self:UpdatePanel()
end

function UMG_PigmentAcquire_C:UpdatePanel()
  if self.bHiddenBtn then
    self.CanvasPanel_56:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ClosePanelLobbyMain)
  end
  self.BtnLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BtnRight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.currentPage < self.totalPage then
    self.BtnRight:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.currentPage > self.startPage then
    self.BtnLeft:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.TitlePrompt:SetText(string.format(LuaText.whole_achieve_tint_colors, self.glassTintNum))
  local currentPageItems = {}
  if self.data and #self.data > 0 then
    local startIndex = (self.currentPage - 1) * self.itemPerPage + 1
    local endIndex = math.min(startIndex + self.itemPerPage - 1, self.glassTintNum)
    for i = startIndex, endIndex do
      local tintData = {
        data = self.data[i],
        petData = self.petData
      }
      table.insert(currentPageItems, tintData)
    end
  end
  self.NRCScrollView_0:InitGridView(currentPageItems)
end

function UMG_PigmentAcquire_C:OnDeactive()
  if not self.bHiddenBtn then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  end
end

function UMG_PigmentAcquire_C:OnAddEventListener()
  self:AddButtonListener(self.BtnLeft.btnLevelUp, self.OnClickedLeft)
  self:AddButtonListener(self.BtnRight.btnLevelUp, self.OnClickedRight)
  self:AddButtonListener(self.GoAndCheckBtn.btnLevelUp, self.OnClickedGoAndCheck)
  self:AddButtonListener(self.ConfirmBtn.btnLevelUp, self.OnClickedConfirm)
  self:AddButtonListener(self.BtnClose, self.OnClickedClose)
end

function UMG_PigmentAcquire_C:OnClickedLeft()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_PigmentAcquire_C:OnClickedLeft")
  self.currentPage = math.max(self.currentPage - 1, 1)
  self:UpdatePanel()
end

function UMG_PigmentAcquire_C:OnClickedRight()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_PigmentAcquire_C:OnClickedRight")
  self.currentPage = math.min(self.currentPage + 1, self.totalPage)
  self:UpdatePanel()
end

function UMG_PigmentAcquire_C:OnClickedGoAndCheck()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PigmentAcquire_C:OnClickedGoAndCheck")
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true, nil, nil, nil, self.tabIndex, self.subTabIndex)
  self:DoClose()
end

function UMG_PigmentAcquire_C:OnClickedConfirm()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PigmentAcquire_C:OnClickedConfirm")
  self:PlayAnimation(self.Out)
end

function UMG_PigmentAcquire_C:OnClickedClose()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  self:PlayAnimation(self.Out)
end

function UMG_PigmentAcquire_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

return UMG_PigmentAcquire_C
