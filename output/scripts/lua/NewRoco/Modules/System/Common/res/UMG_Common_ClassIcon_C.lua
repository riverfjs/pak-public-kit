local UMG_Common_ClassIcon_C = _G.NRCPanelBase:Extend("UMG_Common_ClassIcon_C")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")

function UMG_Common_ClassIcon_C:OnActive()
end

function UMG_Common_ClassIcon_C:OnDeactive()
end

function UMG_Common_ClassIcon_C:OnAddEventListener()
end

function UMG_Common_ClassIcon_C:SetRankInfo(RankConf, pvpRankOrder, seasonId)
  local maxRankStar = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetMaxRankStar)
  local iconRankConf = RankConf
  local rankListItem = PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(iconRankConf, seasonId)
  local icon_mini = RankConf.icon_mini
  icon_mini = rankListItem and rankListItem.mini
  if maxRankStar <= RankConf.id then
    do
      local TopMasterInfo = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetTopMaster)
      local bTopMaster = TopMasterInfo.type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
      if bTopMaster then
        local topMasterConf = DataConfigManager:GetTopMasterConf(seasonId)
        if topMasterConf then
          iconRankConf = topMasterConf
          icon_mini = topMasterConf.icon_mini
        end
      end
    end
    self.ClassIcon:SetPath(icon_mini)
    self.Switcher_1:SetActiveWidgetIndex(1)
    if self.RankingText1 then
      self.RankingText1:SetText(PVPRankedMatchModuleUtils.GetOrderOrRankName(pvpRankOrder))
    end
  else
    self.ClassIcon:SetPath(icon_mini)
    self.Switcher_1:SetActiveWidgetIndex(0)
    self.DanGrading:SetPath(RankConf.number)
  end
end

return UMG_Common_ClassIcon_C
