local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PVP_HistoricalRecord_Item_C = Base:Extend("UMG_PVP_HistoricalRecord_Item_C")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")

function UMG_PVP_HistoricalRecord_Item_C:OnConstruct()
end

function UMG_PVP_HistoricalRecord_Item_C:OnDestruct()
  self:CancelDelay()
end

function UMG_PVP_HistoricalRecord_Item_C:CancelDelay()
  if self.showAnimDelayId then
    _G.DelayManager:CancelDelayById(self.showAnimDelayId)
  end
end

function UMG_PVP_HistoricalRecord_Item_C:OnItemUpdate(_data, datalist, index)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.uiData = _data
  self:CancelDelay()
  self.showAnimDelayId = _G.DelayManager:DelaySeconds((index - 1) * 0.05, function()
    if self and UE.UObject.IsValid(self) then
      self:ShowAnim()
    end
  end)
  local enemyParam = {}
  enemyParam.PetInfos = _data.pet_info
  enemyParam.PvpRankStar = _data.pvp_rank_star
  enemyParam.PvpRankOder = _data.pvp_rank_order
  enemyParam.season_id = _data.season_id
  if _data.enemy then
    enemyParam.name = _data.enemy.name
    enemyParam.headIcon = _data.enemy.additional_data.card_brief_info.card_icon_selected
  elseif _data.npc_enemy then
    enemyParam.name = _data.npc_enemy.name
    enemyParam.headIcon = _data.npc_enemy.icon
  end
  self:SetInfos(false, enemyParam)
  local playerParam = {}
  playerParam.name = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  playerParam.PetInfos = _data.pet_info_self or {}
  playerParam.PvpRankStar = _data.pvp_rank_star_self or _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_STAR)
  playerParam.PvpRankOder = _data.pvp_rank_order_self or _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_ORDER)
  playerParam.season_id = _data.season_id
  local playerCardInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  playerParam.headIcon = playerCardInfo.card_icon_selected
  self:SetInfos(true, playerParam)
end

function UMG_PVP_HistoricalRecord_Item_C:SetInfos(IsPlayer, Param)
  local curSeasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  local seasonId = Param.season_id or 9
  if IsPlayer then
    self.Text_Name:SetText(Param.name)
    self.PetList:InitGridView(Param.PetInfos)
    local enemyRankStarConf = PVPRankedMatchModuleUtils.GetPvpRankConf(Param.PvpRankStar)
    if enemyRankStarConf then
      self.ClassIcon:SetRankInfo(enemyRankStarConf, Param.PvpRankOder, seasonId)
    end
    self:SetHeadInfo(self.HeadPortrait, Param.headIcon)
  else
    self.Text_Name_1:SetText(Param.name)
    self.PetList_1:InitGridView(Param.PetInfos)
    local enemyRankStarConf = PVPRankedMatchModuleUtils.GetPvpRankConf(Param.PvpRankStar)
    if enemyRankStarConf then
      self.ClassIcon_1:SetRankInfo(enemyRankStarConf, Param.PvpRankOder, seasonId)
    end
    self:SetHeadInfo(self.HeadPortrait_1, Param.headIcon)
  end
end

function UMG_PVP_HistoricalRecord_Item_C:ShowAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.showAnimDelayId = nil
  local _data = self.uiData
  if self:IsWin(_data.result) then
    self.Switcher:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.In_Win)
  else
    self.Switcher:SetActiveWidgetIndex(1)
    self:PlayAnimation(self.In_Lose)
  end
end

function UMG_PVP_HistoricalRecord_Item_C:IsWin(type)
  if type == ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN or type == ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_MONSTER_RUNAWAY or type == ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN_DEFEAT or type == ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN_CATCH or type == ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_WIN_HP then
    return true
  else
    return false
  end
end

function UMG_PVP_HistoricalRecord_Item_C:SetHeadInfo(Widget, card_icon_selected)
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if card_icon_selected and 0 ~= card_icon_selected then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local AvatarPath = CardIconConf.icon_resource_path
    AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
    Widget:SetPath(AvatarPath)
  else
  end
end

function UMG_PVP_HistoricalRecord_Item_C:OnItemSelected(_bSelected)
end

function UMG_PVP_HistoricalRecord_Item_C:OnDeactive()
end

return UMG_PVP_HistoricalRecord_Item_C
