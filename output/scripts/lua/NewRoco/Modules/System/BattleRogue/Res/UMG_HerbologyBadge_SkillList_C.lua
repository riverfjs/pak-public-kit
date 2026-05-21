local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HerbologyBadge_SkillList_C = Base:Extend("UMG_HerbologyBadge_SkillList_C")

function UMG_HerbologyBadge_SkillList_C:OnConstruct()
  self:AddButtonListener(self.SkillBtn, self.OnItemSelected)
end

function UMG_HerbologyBadge_SkillList_C:OnDestruct()
end

function UMG_HerbologyBadge_SkillList_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  if not self.uiData then
    return
  end
  local featureId = self.uiData
  local skillCfg = _G.DataConfigManager:GetSkillConf(featureId)
  if skillCfg then
    if self.SkillNameTxt then
      self.SkillNameTxt:SetText(skillCfg.name or "")
    end
    if self.NRCTextDes then
      self.NRCTextDes:SetText(skillCfg.desc or "")
    end
    if self.SkillIcon_1 then
      self.SkillIcon_1:SetPath(skillCfg.icon or "")
    end
  end
end

function UMG_HerbologyBadge_SkillList_C:OnItemSelected(_bSelected)
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.OpenPeculiarityTips, self.uiData)
end

function UMG_HerbologyBadge_SkillList_C:OnDeactive()
end

return UMG_HerbologyBadge_SkillList_C
