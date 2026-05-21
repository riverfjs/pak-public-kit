local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TipsSill_SkillItem_C = Base:Extend("UMG_TipsSill_SkillItem_C")

function UMG_TipsSill_SkillItem_C:OnConstruct()
  self:AddButtonListener(self.Btn_ShutDown_4, self.OnClickBtn)
  self.AttrData = {}
  self.StarInfo = {}
  for i = 1, 5 do
    self.StarInfo[i] = {GrowUpType = 0, IsShow = -1}
  end
end

function UMG_TipsSill_SkillItem_C:OnItemUpdate(ItemData, _, _)
  local FeatureID = ItemData.base_skill_id or 200025
  local SkillConf = _G.DataConfigManager:GetSkillConf(FeatureID)
  self.SkillIcon:SetPath(SkillConf.icon)
  self.SkillNameTxt:SetText(SkillConf.name)
  self.HerbologyBadge_Energy:SetEnergyInfo(ItemData.fused_energy_cost or SkillConf.energy_cost[1], true)
  for Index = 1, #(ItemData.merged_skill_ids or {}) do
    self.StarInfo[Index].IsShow = 1
  end
  self.CatchHardLv:InitGridView(self.StarInfo)
  local TypeDic = _G.DataConfigManager:GetTypeDictionary(SkillConf.skill_dam_type)
  self.AttrData.Name = TypeDic.short_name
  self.AttrData.Path = TypeDic.tips_res
  self.Department:SetInfo(self.AttrData)
end

function UMG_TipsSill_SkillItem_C:OnClickBtn()
  self:BroadcastMsg("OnItemClick", self._index)
end

return UMG_TipsSill_SkillItem_C
