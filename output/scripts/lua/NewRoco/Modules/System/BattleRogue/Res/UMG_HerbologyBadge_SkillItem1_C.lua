local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HerbologyBadge_SkillItem1_C = Base:Extend("UMG_HerbologyBadge_SkillItem1_C")

function UMG_HerbologyBadge_SkillItem1_C:OnConstruct()
  self.StarInfo = {}
  for index = 1, 5 do
    self.StarInfo[index] = {GrowUpType = 0, IsShow = -1}
  end
end

function UMG_HerbologyBadge_SkillItem1_C:OnDestruct()
end

function UMG_HerbologyBadge_SkillItem1_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  if not self.uiData then
    return
  end
  local skillData = self.uiData
  local skillConf = _G.DataConfigManager:GetSkillConf(skillData.base_skill_id)
  if skillConf then
    self.SkillIcon:SetPath(skillConf.icon)
    self.SkillNameTxt:SetText(skillConf.name)
  end
  local starMax = math.max(skillData.fusion_max or 0, 0)
  local fusionCount = math.max(skillData.fusion_count or 0, 0)
  local showStarCount = math.min(starMax, #self.StarInfo)
  local lightStarCount = math.min(fusionCount, showStarCount)
  if not skillData.fusion_count or 0 == skillData.fusion_count then
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    for starIndex = 1, #self.StarInfo do
      self.StarInfo[starIndex].GrowUpType = 0
      if starIndex <= showStarCount then
        self.StarInfo[starIndex].IsShow = starIndex <= lightStarCount and 1 or 0
      else
        self.StarInfo[starIndex].IsShow = -1
      end
    end
    if self.CatchHardLv then
      self.CatchHardLv:InitGridView(self.StarInfo)
    end
  end
end

function UMG_HerbologyBadge_SkillItem1_C:OnItemSelected(_bSelected)
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.OpenPeculiarityTips, self.uiData.base_skill_id)
end

function UMG_HerbologyBadge_SkillItem1_C:OnDeactive()
end

return UMG_HerbologyBadge_SkillItem1_C
