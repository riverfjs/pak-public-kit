local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PVE_SkillListItem_C = Base:Extend("UMG_PVE_SkillListItem_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")

function UMG_PVE_SkillListItem_C:OnConstruct()
  self.Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PVE_SkillListItem_C:OnDestruct()
  self.featureData = nil
end

function UMG_PVE_SkillListItem_C:OnItemUpdate(_data, datalist, index)
  self.featureData = _data
  if not _data then
    return
  end
  local skillConf = _data.skillConf
  if self.SkillIcon_1 and skillConf and skillConf.icon then
    self.SkillIcon_1:SetPath(skillConf.icon)
  end
  if self.SkillNameTxt and skillConf then
    self.SkillNameTxt:SetText(skillConf.name or "")
  end
  if self.NRCTextDes and skillConf then
    self.NRCTextDes:SetText(skillConf.desc or "")
    if self.NRCTextDes_1 then
      self.NRCTextDes_1:SetText(skillConf.desc or "")
    end
  end
  local isLocked = not _data.isActive
  if self.Lock then
    self.Lock:SetVisibility(isLocked and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
  if self.HeadIcon and _data.petbaseId and _data.petbaseId > 0 then
    local firstEvoId = _data.petbaseId
    self.HeadIcon:SetIconPathAndMaterial(firstEvoId, nil, nil)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.EvoListName then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(firstEvoId)
      local petName = petBaseConf and petBaseConf.name or ""
      self.EvoListName:SetText(isLocked and string.format(_G.LuaText.season_growth_unlock_pet_tips, petName) or petName)
    end
  end
  self:UpdateEquipment()
end

function UMG_PVE_SkillListItem_C:UpdateEquipment()
  local curNewPetConfId = self:GetParentCustomData()
  if self.featureData and self.Equipment then
    self.Equipment:SetVisibility(curNewPetConfId and curNewPetConfId == self.featureData.petbaseId and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVE_SkillListItem_C:OpItem(type)
  self:UpdateEquipment()
end

function UMG_PVE_SkillListItem_C:OnItemSelected(_bSelected)
  if self.isSelected == _bSelected then
    self:PlayAnimation(_bSelected and self.Select_Loop or self.Unselect_Loop)
  else
    self:PlayAnimation(_bSelected and self.Select_In or self.Select_Out)
  end
  if _bSelected and self.featureData then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.DispatchEvent, PVEModuleEvent.SelectFeatureItem, self.featureData)
  end
end

function UMG_PVE_SkillListItem_C:OnDeactive()
  self.featureData = nil
end

return UMG_PVE_SkillListItem_C
