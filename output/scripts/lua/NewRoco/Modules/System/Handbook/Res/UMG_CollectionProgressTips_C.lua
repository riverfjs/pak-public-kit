local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_CollectionProgressTips_C = _G.NRCPanelBase:Extend("UMG_CollectionProgressTips_C")

function UMG_CollectionProgressTips_C:OnActive(data)
  _G.NRCAudioManager:PlaySound2DAuto(41400002, "UMG_CollectionProgressTips_C:OnActive")
  self:PlayAnimation(self.Appear)
  self.NRCText_76:SetText(LuaText.handbook_collect_progress_5)
  self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, true)
  if data.seasonId then
    local seasonConf = _G.DataConfigManager:GetSeasonConf(data.seasonId)
    if seasonConf then
      local name = seasonConf.s_title_subtitle
      local str
      if data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
        str = LuaText.season_collect_tips_2
      elseif data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING then
        str = LuaText.season_collect_tips_3
      elseif data.petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING then
        str = LuaText.season_collect_tips_4
      end
      if str and name then
        self.ChangeText:SetText(string.format(str, name, data.collectedCount, data.totalCount))
      end
    end
  else
    self.ChangeText:SetText(string.format(LuaText.handbook_collect_progress_6, data.areaConf.name, data.collectedCount))
  end
end

function UMG_CollectionProgressTips_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_CollectionProgressTips_C:OnDeactive()
end

function UMG_CollectionProgressTips_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseTips, self.OnCloseTips)
end

function UMG_CollectionProgressTips_C:OnCloseTips()
  if self:IsAnimationPlaying(self.Disappear) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_CollectionProgressTips_C:OnActive")
  self:PlayAnimation(self.Disappear)
end

function UMG_CollectionProgressTips_C:OnAnimationFinished(Animation)
  if Animation == self.Disappear then
    self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, false)
    self:DoClose()
  end
end

return UMG_CollectionProgressTips_C
