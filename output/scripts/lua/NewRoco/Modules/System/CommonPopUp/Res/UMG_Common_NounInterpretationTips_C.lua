local UMG_Common_NounInterpretationTips_C = _G.NRCPanelBase:Extend("UMG_Common_NounInterpretationTips_C")

function UMG_Common_NounInterpretationTips_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Common_NounInterpretationTips_C:OnDestruct()
end

function UMG_Common_NounInterpretationTips_C:OnActive(_param)
  self.uiData = _param
  self:SetMainInfo()
  self:PlayAnimation(self.Tips_in)
end

function UMG_Common_NounInterpretationTips_C:OnDeactive()
end

function UMG_Common_NounInterpretationTips_C:OnAddEventListener()
  self:AddButtonListener(self.GlobalCloseBtn, self.OnCloseBtn)
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtn)
end

function UMG_Common_NounInterpretationTips_C:SetMainInfo()
  if self.uiData.bIsUseOriginalText then
    if self.uiData.originalTextList then
      local textList = self.uiData.originalTextList
      local descList = {}
      for i = 1, #textList do
        if self.uiData.OverviewChangeInfoList and self.uiData.DetailsChangeInfoList then
          table.insert(descList, {
            descText = textList[i],
            bIsUseOriginalText = true,
            OverviewChangeInfo = self.uiData.OverviewChangeInfoList[i],
            DetailsChangeInfo = self.uiData.DetailsChangeInfoList[i]
          })
        else
          table.insert(descList, {
            descText = textList[i],
            bIsUseOriginalText = true
          })
        end
      end
      self.DescScrollView:InitList(descList)
      for i = 1, self.DescScrollView:GetItemCount() do
        local item = self.DescScrollView:GetItemByIndex(i - 1)
        if i ~= self.DescScrollView:GetItemCount() or self.uiData.LineShowFlagList and self.uiData.LineShowFlagList[i] then
          item.Line1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          item.Line1:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
      end
    end
  else
    local linkIds = {}
    if self.uiData.link_ids then
      linkIds = self.uiData.link_ids
    else
      linkIds = self:GetHyperLinkIds(self.uiData.text)
    end
    local descList = {}
    for i = 1, #linkIds do
      table.insert(descList, {
        descId = tonumber(linkIds[i])
      })
    end
    self.DescScrollView:InitList(descList)
    for i = 1, self.DescScrollView:GetItemCount() do
      local item = self.DescScrollView:GetItemByIndex(i - 1)
      if i ~= self.DescScrollView:GetItemCount() then
        item.Line1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        item.Line1:SetVisibility(UE4.ESlateVisibility.Hidden)
      end
    end
  end
end

function UMG_Common_NounInterpretationTips_C:GetHyperLinkIds(inputString)
  local pattern = "<desc_id=(%d+)>"
  local ids = {}
  local vis = {}
  for id in string.gmatch(inputString, pattern) do
    if not vis[id] then
      table.insert(ids, id)
      vis[id] = true
    end
  end
  return ids
end

function UMG_Common_NounInterpretationTips_C:GetChildIds(inputString, vis)
  local pattern = "<desc_id=(%d+)>"
  local ids = {}
  for id in string.gmatch(inputString, pattern) do
    if not vis[id] then
      table.insert(ids, id)
      vis[id] = true
      local descNote = _G.DataConfigManager:GetDescNoteConf(tonumber(id))
      local childIds = self:GetChildIds(descNote.desc, vis)
      for _, childId in pairs(childIds) do
        table.insert(ids, childId)
      end
    end
  end
  return ids
end

function UMG_Common_NounInterpretationTips_C:OnCloseBtn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401012, "UMG_Common_NounInterpretationTips_C:OnCloseBtn")
  if not self:IsAnimationPlaying(self.Tips_out) then
    self:PlayAnimation(self.Tips_out)
  end
end

function UMG_Common_NounInterpretationTips_C:OnAnimationFinished(anim)
  if anim == self.Tips_out then
    self:DoClose()
  end
end

return UMG_Common_NounInterpretationTips_C
