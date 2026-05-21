local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HerbologyBadge_FeatureItem_C = Base:Extend("UMG_HerbologyBadge_FeatureItem_C")

function UMG_HerbologyBadge_FeatureItem_C:OnConstruct()
  self:AddButtonListener(self.Btn_ShutDown_4, self.OnClickBtn)
end

function UMG_HerbologyBadge_FeatureItem_C:OnItemUpdate(ItemData, _, _)
  local FeatureID = ItemData or 200025
  local SkillConf = _G.DataConfigManager:GetSkillConf(FeatureID)
  self.SkillIcon:SetPath(SkillConf.icon)
end

function UMG_HerbologyBadge_FeatureItem_C:OnClickBtn()
  self:BroadcastMsg("OnItemClick")
end

return UMG_HerbologyBadge_FeatureItem_C
