local UMG_NounInterpretationTips_C = _G.NRCPanelBase:Extend("UMG_NounInterpretationTips_C")

function UMG_NounInterpretationTips_C:OnActive()
end

function UMG_NounInterpretationTips_C:OnDeactive()
end

function UMG_NounInterpretationTips_C:OnConstruct()
  self.TextIdMap = {}
  self.descItems = {}
  self:OnAddEventListener()
end

function UMG_NounInterpretationTips_C:OnAddEventListener()
end

function UMG_NounInterpretationTips_C:SetDesc(descText, id)
  id = tonumber(id)
  if id then
    if not self.TextIdMap then
      self.TextIdMap = {}
    end
    if self.TextIdMap[id] then
      return
    end
    self.TextIdMap[id] = true
    table.insert(self.descItems, {
      descText = descText,
      id = id,
      parent = self
    })
  end
  for i = 1, #self.descItems do
    self.descItems[i].limitIndex = #self.descItems
  end
  self:PlayInAnim()
  self.List:InitList(self.descItems)
end

function UMG_NounInterpretationTips_C:SetDescList(desc_list)
  self.descItems = desc_list
  self:PlayInAnim()
  self.List:InitList(self.descItems)
end

function UMG_NounInterpretationTips_C:PlayInAnim()
  if self:IsAnimationPlaying(self.Tips_out) then
    self:StopAllAnimations()
    self:PlayAnimation(self.Tips_in)
  else
    self:PlayAnimation(self.Tips_in)
  end
end

function UMG_NounInterpretationTips_C:ResetDescText()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.isDestruct then
    return
  end
  local item = self.List:GetItemByIndex(0)
  self.TextIdMap = {}
  self.descItems = {}
  if self:IsAnimationPlaying(self.Tips_out) or self:IsAnimationPlaying(self.Tips_in) or item.textBuffDesc:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:PlayAnimation(self.Tips_out)
end

function UMG_NounInterpretationTips_C:OnDescTextClicked(id)
  local descNote = _G.DataConfigManager:GetDescNoteConf(tonumber(id))
  local descText = string.format("\227\128\144%s\227\128\145\n%s", descNote.note, descNote.desc)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:SetDesc(descText, id)
end

function UMG_NounInterpretationTips_C:OnAnimationFinished(Anim)
  if self.isDestruct then
    return
  end
  if Anim == self.Tips_out then
    for i = 1, self.List:GetItemCount() do
      local item = self.List:GetItemByIndex(i - 1)
      item:HideDesc()
    end
  end
end

return UMG_NounInterpretationTips_C
