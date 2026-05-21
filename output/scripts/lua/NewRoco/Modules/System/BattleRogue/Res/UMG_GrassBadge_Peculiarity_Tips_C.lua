local Base = require("NewRoco.Modules.System.PetUI.Res.UMG_Peculiarity_Tips_C")
local UMG_GrassBadge_Peculiarity_Tips_C = Base:Extend("UMG_GrassBadge_Peculiarity_Tips_C")

function UMG_GrassBadge_Peculiarity_Tips_C:OnConstruct()
  Base.OnConstruct(self)
  self.descText = ""
end

function UMG_GrassBadge_Peculiarity_Tips_C:OnActive(FeatureID, PetData, PetBaseConfID)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_Peculiarity_Tips_C:OnActive")
  if PetData then
    self.HeadIcon:SetIconPathAndMaterial(PetData.base_conf_id, PetData.mutation_type, PetData.glass_info)
  else
    self.HeadIcon:SetIconPathAndMaterial(PetBaseConfID)
  end
  self.Title:SetText(LuaText.umg_petleftpanel_11)
  if nil == FeatureID or 0 == FeatureID then
    local GetPetbaseConf = _G.DataConfigManager:GetPetbaseConf(PetData and PetData.base_conf_id or PetBaseConfID)
    if GetPetbaseConf then
      FeatureID = self:GetPetFeatureSkillId(GetPetbaseConf)
    end
  end
  if FeatureID and 0 ~= FeatureID then
    local SkillConf = _G.DataConfigManager:GetSkillConf(FeatureID)
    if SkillConf then
      if SkillConf.icon then
        self.SkillIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.SkillIcon:SetPath(SkillConf.icon)
      end
      local SkillDesc = SkillConf.desc
      self.descText = SkillDesc
      self.NRCTextDes:SetText(SkillDesc)
      self.SkillNameTxt:SetText(SkillConf.name)
    end
  end
  self:LoadAnimation(0)
  self:OnAddEventListener()
end

return UMG_GrassBadge_Peculiarity_Tips_C
