local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local nameColorBoundary = _G.DataConfigManager:GetPetGlobalConfig("pet_level_boundary").num
local UMG_NpcInfo_EctypeNPC_C = _G.NRCPanelBase:Extend("UMG_NpcInfo_EctypeNPC_C")

function UMG_NpcInfo_EctypeNPC_C:OnActive()
end

function UMG_NpcInfo_EctypeNPC_C:OnDeactive()
end

function UMG_NpcInfo_EctypeNPC_C:OnAddEventListener()
end

function UMG_NpcInfo_EctypeNPC_C:OnConstruct()
end

function UMG_NpcInfo_EctypeNPC_C:OnDestruct()
end

function UMG_NpcInfo_EctypeNPC_C:OnEnable(name, desc, headIconPath, isHeadIconActive, rewardsList, isDone, collectionInfoList, npcContentId)
  self.npcName_1:SetText(name)
  self.npcDesc_1:SetText(desc)
  self:SetHeadIconActive(isHeadIconActive, headIconPath)
  self.DungeonAwardList:InitGridView(rewardsList)
  self.OffTheStocks:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if isDone then
    self.OffTheStocks:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.List:InitGridView(collectionInfoList)
  if npcContentId then
    self.LevelGroup:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local level, IsReCom = MagicManualUtils.GetBossLevel(npcContentId)
    local worldLevel = (_G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0) + 1
    local pet_level_limit = _G.DataConfigManager:GetWorldLevelConf(worldLevel).pet_level_limit
    local subLevel = level - pet_level_limit
    local fColor = UE4.UNRCStatics.HexToSlateColor("#62605EFF")
    if subLevel > nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#c12a2a")
    elseif subLevel > 0 and subLevel <= nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#e77d00")
    else
      fColor = UE4.UNRCStatics.HexToSlateColor("#62605EFF")
    end
    self.NRCText01:SetColorAndOpacity(fColor)
    self.NRCText01_1:SetColorAndOpacity(fColor)
    self.NRCText01:SetText(string.format(LuaText.dungeon_enemy_level_description, ""))
    self.NRCText01_1:SetText(level)
  else
    self.LevelGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NpcInfo_EctypeNPC_C:OnDisable()
end

function UMG_NpcInfo_EctypeNPC_C:SetHeadIconActive(shouldActivate, headIconPath)
end

return UMG_NpcInfo_EctypeNPC_C
