local UMG_SeasonRankBase = _G.NRCPanelBase:Extend("UMG_SeasonRankBase")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local Timer = require("NewRoco.Modules.System.PVPQualifier.Res.Timer")
local UMG_PVP_DanGrading_C = require("NewRoco.Modules.System.BattleUI.Res.UMG_PVP_DanGrading_C")
local kCloseDelayTime = 2

function UMG_SeasonRankBase:OnConstruct()
  self.bEventDispatched = false
  self.CloseDelayTimer = Timer()
end

function UMG_SeasonRankBase:OnActive(oldRank, resetToRank)
  Log.Debug("SeasonOpen Progress: UMG_SeasonRankBase:OnActive")
  self:BindToAnimationFinished(self.In, {
    self,
    self.OnAnimationFinished_In
  })
  self:PlayAnimation(self.In)
  local umgAnimLength = 0
  umgAnimLength = umgAnimLength + self.In:GetEndTime() - self.In:GetStartTime()
  umgAnimLength = umgAnimLength + self.DissolveFlag:GetEndTime() - self.DissolveFlag:GetStartTime()
  self.CloseDelayTimer:Reset(kCloseDelayTime + umgAnimLength)
  self:AddButtonListener(self.BtnClose, self.OnClick_BtnClose)
  local oldRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(oldRank)
  local rankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(resetToRank)
  local curSeasonId = self.module.data:GetCurSeasonId()
  local oldSeasonId = self.module.data:GetPrevSeasonId()
  local oldRankListItem = PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(oldRankConf, oldSeasonId)
  local oldTexPath = oldRankListItem and oldRankListItem.tex_path
  local RankListItem = PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(rankConf, curSeasonId)
  local texPath = RankListItem and RankListItem.tex_path
  if oldRankConf then
    self.later:SetPath(oldTexPath)
    self.RankName:SetText(oldRankConf.name)
  end
  if rankConf then
    self.before_1:SetPath(texPath)
    self.RankName_later:SetText(rankConf.name)
  end
  self.TextHint:SetText(_G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character24").str)
end

function UMG_SeasonRankBase:OnDeactive()
  self:TryDispatchEvent()
end

function UMG_SeasonRankBase:OnClick_BtnClose()
  if self.CloseDelayTimer:IsExceed() then
    self:TryCloseAnimated()
  end
end

function UMG_SeasonRankBase:TryDispatchEvent()
  if self.bEventDispatched then
    return
  end
  self.bEventDispatched = true
  _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.UI_SeasonResetRankAnimationFinished)
end

function UMG_SeasonRankBase:TryCloseAnimated()
  if not self.PlayingCloseAnim then
    self.PlayingCloseAnim = true
    self:DoCloseAnimated()
  end
end

function UMG_SeasonRankBase:DoCloseAnimated()
  self:BindToAnimationFinished(self.Out, {
    self,
    self.OnAnimationFinished_Out
  })
  self:PlayAnimation(self.Out)
end

function UMG_SeasonRankBase:OnAnimationFinished_In()
  Log.Debug("SeasonOpen Progress: UMG_SeasonRankBase:OnAnimationFinished_In")
  self:PlayAnimation(self.DissolveFlag)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdTrySwitch_UMG_SeasonOpen, false)
end

function UMG_SeasonRankBase:OnAnimationFinished_Out()
  Log.Debug("SeasonOpen Progress: UMG_SeasonRankBase:OnAnimationFinished_Out")
  self.PlayingCloseAnim = false
  self:TryDispatchEvent()
end

function UMG_SeasonRankBase:OnTick(deltaTime)
  self.CloseDelayTimer:Tick(deltaTime)
end

return UMG_SeasonRankBase
