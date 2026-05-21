local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_HerbologyBadge_ChangePet_Attr_C = Base:Extend("UMG_HerbologyBadge_ChangePet_Attr_C")

function UMG_HerbologyBadge_ChangePet_Attr_C:OnConstruct()
end

function UMG_HerbologyBadge_ChangePet_Attr_C:OnDestruct()
end

function UMG_HerbologyBadge_ChangePet_Attr_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:UpdateInfo(self.uiData, datalist)
end

function UMG_HerbologyBadge_ChangePet_Attr_C:UpdateInfo(skillData, datalist)
  if not skillData or not skillData.id then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  local skillConf = _G.SkillUtils.GetSkillConf(skillData.id)
  if not skillConf then
    Log.Debug("UMG_HerbologyBadge_ChangePet_Attr_C: skill conf not found for id", skillData.id)
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  self.SkillIcon:SetPath(skillConf.icon)
  local fantasticBackgroundPath = ""
  if skillData.bFantastic then
    local skillId = skillData and skillData.id
    local seasonId = skillData and skillData.season_id
    local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, seasonId)
    fantasticBackgroundPath = paths and paths.squareNm3 or fantasticBackgroundPath
  end
  local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
  if not string.IsNilOrEmpty(fantasticBackgroundPath) then
    selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  self.Select_NM_3:SetPath(fantasticBackgroundPath)
  self.Select_NM_3:SetVisibility(selectNm3Visibility)
  self.TxtSkillName:SetText(skillConf.name or "")
  self.Desc:SetText(skillConf.desc or "")
  if self.HerbologyBadge_Energy and skillConf.energy_cost and skillConf.energy_cost[1] then
    self.HerbologyBadge_Energy:SetEnergyInfo(skillConf.energy_cost[1], false)
  end
  local commonAttrData = {}
  local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
  if typeDic then
    local attrItem = {
      Path = typeDic.tips_res
    }
    if skillConf.damage_type == Enum.DamageType.DT_NONE then
      attrItem.Name = "-"
    else
      attrItem.Name = string.format("%d", skillConf.dam_para and skillConf.dam_para[1] or 0)
    end
    table.insert(commonAttrData, attrItem)
  end
  self.Attr:InitGridView(commonAttrData)
  if datalist and self.index == #datalist then
    self.Divider:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Divider:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_HerbologyBadge_ChangePet_Attr_C:OnItemSelected(_bSelected)
end

function UMG_HerbologyBadge_ChangePet_Attr_C:OnDeactive()
end

return UMG_HerbologyBadge_ChangePet_Attr_C
