local UMG_Activity_ElfCollection_Tips_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfCollection_Tips_C")

function UMG_Activity_ElfCollection_Tips_C:OnActive(petBaseId, trailParam)
  self.IsClose = false
  self.PetBaseId = petBaseId
  self.TrailParam = trailParam
  self:ShowInfo()
  self:OnAddEventListener()
  self:LoadAnimation(0)
end

function UMG_Activity_ElfCollection_Tips_C:OnDeactive()
  self:RemoveButtonListener(self.HotArea, self.CloseBtnClick)
end

function UMG_Activity_ElfCollection_Tips_C:OnAddEventListener()
  self:AddButtonListener(self.HotArea, self.CloseBtnClick)
end

function UMG_Activity_ElfCollection_Tips_C:ShowInfo()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetBaseId)
  if petBaseConf then
    if petBaseConf.name then
      self.TitleText:SetText(petBaseConf.name)
    end
    if petBaseConf.form and petBaseConf.form ~= "" then
      self.UsualAppearance:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Type:SetText(petBaseConf.form)
    else
      self.UsualAppearance:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if petBaseConf.Pet_Circadian then
      local liveType = petBaseConf.Pet_Circadian
      if liveType == _G.Enum.PetCircadian.PC_ALLDAY then
        self.Switcher1:SetActiveWidgetIndex(0)
      elseif liveType == _G.Enum.PetCircadian.PC_NIGHT then
        self.Switcher1:SetActiveWidgetIndex(1)
      elseif liveType == _G.Enum.PetCircadian.PC_DAY then
        self.Switcher1:SetActiveWidgetIndex(2)
      end
    end
    if petBaseConf.model_conf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        self.Pet:SetPath(modelConf.icon)
      end
    end
  end
  if self.TrailParam then
    local tipsLine = {}
    for line in self.TrailParam:gmatch([[
([^
]+)]]) do
      table.insert(tipsLine, line)
    end
    self.List:InitGridView(tipsLine)
    if #tipsLine > 1 then
      local item = self.List:GetItemByIndex(#tipsLine - 1)
      item:HideLine()
    end
  end
end

function UMG_Activity_ElfCollection_Tips_C:CloseBtnClick()
  if not self.IsClose then
    _G.NRCAudioManager:PlaySound2DAuto(40002014, "UMG_Activity_ElfCollection_Tips_C:CloseBtnClick")
    self.IsClose = true
    self:LoadAnimation(2)
  end
end

function UMG_Activity_ElfCollection_Tips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  elseif anim == self:GetAnimByIndex(1) then
    self:LoadAnimation(1)
  elseif anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_ElfCollection_Tips_C:OnPcClose()
  self:CloseBtnClick()
end

return UMG_Activity_ElfCollection_Tips_C
