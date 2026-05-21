local UMG_ChapterBegins_C = _G.NRCPanelBase:Extend("UMG_ChapterBegins_C")

function UMG_ChapterBegins_C:OnConstruct()
end

function UMG_ChapterBegins_C:OnActive(_data)
  _G.NRCAudioManager:PlaySound2DAuto(40005001, "UMG_ChapterBegins_C:OnActive")
  self.uiData = _data
  self:PlayAnimation(self.In)
  self:SetShowInfo()
end

function UMG_ChapterBegins_C:OnDeactive()
end

function UMG_ChapterBegins_C:OnAddEventListener()
end

function UMG_ChapterBegins_C:SetShowInfo()
  if self.uiData then
    if self.NRCText_31 and self.uiData.chapterNumber then
      self.NRCText_31:SetText(self.uiData.chapterNumber)
    end
    if self.NRCText and self.uiData.chapterName then
      self.NRCText:SetText(self.uiData.chapterName)
    end
    if self.Ribbons and self.uiData.chapterRibbon then
      self.Ribbons:SetPath(self.uiData.chapterRibbon)
    end
    if self.BookmarkColor and self.uiData.themeColor then
      self.BookmarkColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(self.uiData.themeColor))
    end
    if self.NRCText_1 then
      self.NRCText_1:SetText(LuaText.season_manual_new_chapter)
    end
  end
end

function UMG_ChapterBegins_C:OnAnimationFinished(anim)
  if anim == self.In then
    self:PlayAnimation(self.Loop)
  elseif anim == self.Loop then
    self:PlayAnimation(self.Out)
  elseif anim == self.Out then
    if self.uiData and self.uiData.widgetLoader then
      self.uiData.widgetLoader:DoClose()
    else
      self:DoClose()
    end
  end
end

return UMG_ChapterBegins_C
