local Base = require("NewRoco.Modules.System.PVE.Res.UMG_PVE_Talent_Item")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")
local UMG_PVE_Talent_Item3_C = Base:Extend("UMG_PVE_Talent_Item3_C")

function UMG_PVE_Talent_Item3_C:InitItem(itemConf)
  Base.InitItem(self, itemConf)
  self.NRCSwitcher_10:SetActiveWidgetIndex(1)
end

function UMG_PVE_Talent_Item3_C:RefreshLockStatus(nodeData, bInit, bForce)
  Base.RefreshLockStatus(self, nodeData, bInit, bForce)
  if not nodeData then
    return
  end
  local newStatus = nodeData and nodeData.status or PVEModuleEnum.TalentNodeStatus.Locked
  local isUnlocked = newStatus == PVEModuleEnum.TalentNodeStatus.Unlocked
  local newPetConfId = nodeData and nodeData.newPetConfId or 0
  local hasFeatureSet = nil ~= newPetConfId and newPetConfId > 0
  self.SkillIcon_1:SetVisibility(isUnlocked and hasFeatureSet and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  Log.Debug("UMG_PVE_Talent_Item3_C:RefreshLockStatus", isUnlocked, newPetConfId)
  if hasFeatureSet then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(newPetConfId)
    if petBaseConf then
      local skillId = petBaseConf.pet_feature or 0
      if 0 ~= skillId then
        local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
        if skillConf and skillConf.icon then
          self.SkillIcon_1:SetPath(skillConf.icon)
        end
      end
    end
  end
  local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
  self.CanvasPanel_Pet:SetVisibility(nodeConf.type == Enum.SeasonGrowthType.SGT_PET and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

return UMG_PVE_Talent_Item3_C
