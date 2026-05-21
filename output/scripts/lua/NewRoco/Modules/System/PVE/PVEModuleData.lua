local PVEModuleData = _G.NRCData:Extend("PVEModuleData")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")

function PVEModuleData:Ctor()
  NRCData.Ctor(self)
  self.talentData = {}
  self.talentNodeData = {}
end

function PVEModuleData:GeneratePveTalentData()
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  local seasonId = seasonInfo and seasonInfo.season_id
  local talentSeasonId = self.talentData and self.talentData.seasonId
  if seasonId == talentSeasonId then
    return
  end
  local talentData = {
    seasonId = seasonId,
    pveBaseConf = nil,
    unlockNodeCnt = seasonInfo and seasonInfo.light_talent_count or 0,
    totalNodeCnt = 0,
    material = 0,
    materialCnt = 0,
    nodeSortToId = {}
  }
  local talentNodeData
  if seasonInfo then
    local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
    local seasonPveBaseConf = seasonConf and _G.DataConfigManager:GetSeasonPveBaseConf(seasonConf.season_pve_id)
    local seasonTalentConf = seasonPveBaseConf and _G.DataConfigManager:GetSeasonTalentConf(seasonPveBaseConf.season_talent)
    if seasonTalentConf then
      talentData.seasonTalentConf = seasonTalentConf
      talentData.pveBaseConf = seasonPveBaseConf
      talentData.totalNodeCnt = #seasonTalentConf.point
      talentNodeData = table.new(0, talentData.totalNodeCnt)
      for _, pointId in ipairs(seasonTalentConf.point) do
        local seasonGrowthConf = _G.DataConfigManager:GetSeasonGrowthConf(pointId)
        if seasonGrowthConf then
          if 0 == talentData.material and 0 ~= seasonGrowthConf.material then
            talentData.material = seasonGrowthConf.material
          end
          if nil == talentData.nodeSortToId[seasonGrowthConf.sort] then
            talentData.nodeSortToId[seasonGrowthConf.sort] = seasonGrowthConf.id
          end
        end
        local nodeData = {
          id = pointId,
          sort = seasonGrowthConf and seasonGrowthConf.sort,
          status = seasonGrowthConf and 0 == seasonGrowthConf.sort and PVEModuleEnum.TalentNodeStatus.CanUnlock or PVEModuleEnum.TalentNodeStatus.Locked,
          newPetConfId = nil
        }
        talentNodeData[nodeData.id] = nodeData
      end
    end
  end
  self.talentData = talentData
  self.talentNodeData = talentNodeData or {}
end

function PVEModuleData:GetTalentNodeIdBySort(sort)
  return self.talentData and self.talentData.nodeSortToId and self.talentData.nodeSortToId[sort]
end

function PVEModuleData:GetTalentNodeData(id)
  return self.talentNodeData and self.talentNodeData[id]
end

function PVEModuleData:TraverseTalentNodeData(handler)
  if not self.talentNodeData or not handler then
    return
  end
  for id, data in pairs(self.talentNodeData) do
    if handler(id, data) then
      break
    end
  end
end

return PVEModuleData
