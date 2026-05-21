local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HerbologyBadge_SkillItem_C = Base:Extend("UMG_HerbologyBadge_SkillItem_C")

function UMG_HerbologyBadge_SkillItem_C:OnConstruct()
  self:AddButtonListener(self.Btn_ShutDown_4, self.OnClickBtn)
end

function UMG_HerbologyBadge_SkillItem_C:OnItemUpdate(ItemData, _, _)
  local FeatureID = ItemData.base_skill_id or 200025
  local SkillConf = _G.DataConfigManager:GetSkillConf(FeatureID)
  self.SkillIcon:SetPath(SkillConf.icon)
end

function UMG_HerbologyBadge_SkillItem_C:OnClickBtn()
  self:BroadcastMsg("OnItemClick")
end

return UMG_HerbologyBadge_SkillItem_C
