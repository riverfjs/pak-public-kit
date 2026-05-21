local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_SkillsEquipment_C = Base:Extend("UMG_SkillsEquipment_C")

function UMG_SkillsEquipment_C:OnConstruct()
end

function UMG_SkillsEquipment_C:OnDestruct()
end

function UMG_SkillsEquipment_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:UpdateInfo(self.uiData)
end

function UMG_SkillsEquipment_C:UpdateInfo(skillData)
  if not skillData then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  local skillConf = _G.SkillUtils.GetSkillConf(skillData.id)
  local commonAttrData = {}
  local fantasticBackgroundPath = ""
  if skillConf then
    self.skillConf = skillConf
    self.SkillIcon:SetPath(skillConf.icon)
    self.SkillNameTxt:SetText(skillConf.name)
    self.Number:SetText(self.index)
    if self.uiData.bFantastic then
      local skillId
      if skillData and skillData.id and skillData.skill_id then
        skillId = skillData and skillData.skill_id
      elseif skillData and skillData.id then
        skillId = skillData and skillData.id
      end
      local seasonId = skillData and skillData.season_id
      local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, seasonId)
      if paths then
        fantasticBackgroundPath = paths.squareNm3 or fantasticBackgroundPath
      end
    end
  else
    Log.Debug("\230\138\128\232\131\189id\230\178\146\230\156\137\230\137\190\229\136\176", skillData.skill_id)
  end
  if self.Select_NM_3 then
    local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
    if not string.IsNilOrEmpty(fantasticBackgroundPath) then
      selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
    end
    self.Select_NM_3:SetPath(fantasticBackgroundPath)
    self.Select_NM_3:SetVisibility(selectNm3Visibility)
  end
end

function UMG_SkillsEquipment_C:OnItemSelected(_bSelected)
  if _bSelected and self.skillConf then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenSkillTips, {
      skillData = self.skillConf,
      HideClose = false,
      isAddImc = true
    }, true)
  end
end

function UMG_SkillsEquipment_C:OnDeactive()
end

return UMG_SkillsEquipment_C
