local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Season_List_C = Base:Extend("UMG_Season_List_C")

function UMG_Season_List_C:OnConstruct()
end

function UMG_Season_List_C:OnDestruct()
end

function UMG_Season_List_C:OnItemUpdate(_data, datalist, index)
  self:StopAllAnimations()
  self:PlayAnimation(self.Normal)
  self.seasonConf = _data.conf
  self.parent = _data.parent
  self.bSelected = false
  self:InitPanel()
end

function UMG_Season_List_C:InitPanel()
  if self.seasonConf then
    local icon = self.seasonConf.big_icon
    if icon then
      self.Bg:SetPath(icon)
    end
    local name = self.seasonConf.s_title_subtitle
    local id = self.seasonConf.id
    if name and id then
      local seasonName = string.format("S%d%s", id, name)
      self.Text:SetText(seasonName)
    end
    local totalNormalPetNum, collectNormalPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, id, ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW)
    local totalSeasonShinyPetNum, collectSeasonShinyPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, id, ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING)
    local totalNormalShinyPetNum, collectNormalShinyPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, id, ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING)
    local totalNum = totalNormalPetNum + totalSeasonShinyPetNum + totalNormalShinyPetNum
    local collectNum = collectNormalPetNum + collectSeasonShinyPetNum + collectNormalShinyPetNum
    self.ProgressText1:SetText(string.format("%d/%d", collectNum, totalNum))
    local shinyTotalNum = totalSeasonShinyPetNum + totalNormalShinyPetNum
    local collectShinyNum = collectSeasonShinyPetNum + collectNormalShinyPetNum
    self.ProgressText2:SetText(string.format("%d/%d", collectShinyNum, shinyTotalNum))
    self.Dot:SetupKey(478, {id})
  end
end

function UMG_Season_List_C:OnItemSelected(_bSelected)
  if self.bSelected == _bSelected then
    return
  end
  self.bSelected = _bSelected
  if _bSelected then
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonHandBook, self.seasonConf.id)
    if self.parent then
      self.parent:UpdateSeasonId(self.seasonConf.id)
    end
    self:StopAllAnimations()
    self:PlayAnimation(self.Click)
  else
    self:StopAllAnimations()
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Season_List_C:OnAnimationFinished(Anim)
  if Anim == self.Click then
    self:PlayAnimation(self.Click_loop)
  end
end

function UMG_Season_List_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Season_List_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Season_List_C:OnDeactive()
end

return UMG_Season_List_C
