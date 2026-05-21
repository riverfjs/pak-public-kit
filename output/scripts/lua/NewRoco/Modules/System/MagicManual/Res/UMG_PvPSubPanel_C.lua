local NPCShopUIModuleEnum = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_PvPSubPanel_C = _G.NRCPanelBase:Extend("UMG_PvPSubPanel_C")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local CWView_WeekendBenefitsPanel = require("NewRoco.Modules.System.PVPQualifier.Res.CWView_WeekendBenefitsPanel")

function UMG_PvPSubPanel_C:OnConstruct()
  self.CWView_WeekendBenefitsPanel = CWView_WeekendBenefitsPanel(self)
end

function UMG_PvPSubPanel_C:OnDestruct()
  self.CWView_WeekendBenefitsPanel:OnDestruct()
end

function UMG_PvPSubPanel_C:OnActive()
  self.CWView_WeekendBenefitsPanel:OnActive()
end

function UMG_PvPSubPanel_C:OnDeactive()
  self.CWView_WeekendBenefitsPanel:OnDeactive()
end

function UMG_PvPSubPanel_C:OnEnable(module)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.module = module
  self.data = self.module.data
  self:RefreshCurrentSeasonId()
  local curSeasonId = self.curSeasonId
  self:OnAddEventListener()
  if curSeasonId then
    self:RefreshPvpUI()
  else
    self.tryEnable = true
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq)
  end
end

function UMG_PvPSubPanel_C:RefreshCurrentSeasonId()
  local curSeasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  self.curSeasonId = curSeasonId
end

function UMG_PvPSubPanel_C:RefreshPvpUI()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.MoneyBtn:InitGridView(BattleUtils.GetPvpScoreItemInfo(self.curSeasonId))
  local PvpChallengeList = self:GetPvpChallengeData()
  self.PvpList:InitList(PvpChallengeList)
  local num1 = self.PvpList:GetItemCount()
  for i = 1, num1 do
    local item = self.PvpList:GetItemByIndex(i - 1)
    item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 1 == i then
      item:PlayAnimation(item.In)
    else
      self:DelaySeconds(0.03 * (i - 1), function()
        item:PlayAnimation(item.In)
      end)
    end
  end
  self:UpdateWinInfo()
  self.WeeklyRewardBtn:SetRedDot(294)
  self:PlayAnimation(self.Change)
  self.CWView_WeekendBenefitsPanel:RefreshUI()
end

function UMG_PvPSubPanel_C:GetPvpChallengeData()
  local PvpIdList = {
    1001,
    2001,
    3001,
    4001,
    5001,
    6001
  }
  local temp = {}
  for _, Id in pairs(PvpIdList) do
    local conf = _G.DataConfigManager:GetPvpConf(Id)
    if conf and conf.is_show then
      table.insert(temp, conf)
    end
  end
  table.sort(temp, function(left, right)
    return left.sequence < right.sequence
  end)
  return temp
end

function UMG_PvPSubPanel_C:OnDisable()
  self:OnRemoveEventListener()
end

function UMG_PvPSubPanel_C:OnShopBtn()
  local curSeasonId = self.curSeasonId
  local seasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(curSeasonId, true)
  local shopId = seasonConf and seasonConf.shop or BattleConst.PvpDefaultShopId
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.SetNpcShopOpenType, NPCShopUIModuleEnum.OpenNPCShopFormType.MagicManualMain)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.FinishNPCActionOpenShop, nil, shopId)
end

function UMG_PvPSubPanel_C:OnAddEventListener()
  if self.IsAddButtonListener then
    return
  end
  self.IsAddButtonListener = true
  self:AddButtonListener(self.Btn_shopping.btnLevelUp, self.OnShopBtn)
  self.WeeklyRewardBtn.btnLevelUp.OnClicked:Add(self, self.OnBtnWeeklyReward)
  _G.NRCEventCenter:RegisterEvent("UMG_PvPSubPanel_C", self, PVPRankedMatchModuleEvent.SetPvpInfoQueryData, self.OnSetPvpInfoQueryData)
end

function UMG_PvPSubPanel_C:OnRemoveEventListener()
  self.IsAddButtonListener = false
  self:RemoveButtonListener(self.Btn_shopping.btnLevelUp)
  self.WeeklyRewardBtn.btnLevelUp.OnClicked:Remove(self, self.OnBtnWeeklyReward)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpInfoQueryData, self.OnSetPvpInfoQueryData)
end

function UMG_PvPSubPanel_C:OnAnimationFinished(anim)
  self.CWView_WeekendBenefitsPanel:OnAnimationFinished(anim)
end

function UMG_PvPSubPanel_C:OnBtnWeeklyReward()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPDailyChallenge)
end

function UMG_PvPSubPanel_C:OnSetPvpInfoQueryData()
  if self.tryEnable then
    self.tryEnable = nil
    self:RefreshCurrentSeasonId()
    self:RefreshPvpUI()
  end
end

function UMG_PvPSubPanel_C:UpdateWinInfo()
  local curWeekWinCount, requireWinCount = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurWeekWinCount)
  if curWeekWinCount and requireWinCount then
    self.TextQuantity:SetText(string.format("%d/%d", curWeekWinCount or 0, requireWinCount or 0))
  end
end

return UMG_PvPSubPanel_C
