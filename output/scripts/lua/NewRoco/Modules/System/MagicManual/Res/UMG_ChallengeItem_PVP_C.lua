local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_ChallengeItem_PVP_C = Base:Extend("UMG_ChallengeItem_PVP_C")
local pvpRankNpcId = 5001
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")

function UMG_ChallengeItem_PVP_C:OnConstruct()
end

function UMG_ChallengeItem_PVP_C:OnDestruct()
end

function UMG_ChallengeItem_PVP_C:OnItemUpdate(_data, datalist, index)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.uiData = _data
  if not _data.npcid then
    return
  end
  self.Text_Time_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _data.id == pvpRankNpcId then
    self:RefreshPvpRankInfo()
  else
    self:RefreshPvpInfo()
  end
end

function UMG_ChallengeItem_PVP_C:RefreshPvpRankInfo()
  self.SwitcherMessage:SetActiveWidgetIndex(1)
  local curSeasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  local seasonConf = _G.DataConfigManager:GetPvpRankSeasonConf(curSeasonId)
  if seasonConf then
    self.Title:SetText(string.format(_G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character9").str, seasonConf.name))
  else
    Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176\229\175\185\229\186\148\233\133\141\231\189\174id\228\184\186:", curSeasonId)
    return
  end
  local curWeekWinCount, requireWinCount = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurWeekWinCount)
  curWeekWinCount = curWeekWinCount or 0
  requireWinCount = requireWinCount or 0
  self.Text_Session:SetText(string.format("%d/%d", curWeekWinCount, requireWinCount))
  self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local seasonStep = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetCurSeasonStep)
  if seasonStep == ProtoEnum.PVP_RANK_STEP.STEP_PK then
    local month1, day1 = seasonConf.start_time:match("%d+-(%d+)-(%d+)")
    local month2, day2 = seasonConf.end_time1:match("%d+-(%d+)-(%d+)")
    self.Text_TimeRemaining:SetText(string.format("%s.%s-%s.%s", month1, day1, month2, day2))
    self.NRCText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_Time:SetText(PVPRankedMatchModuleUtils.GetCurSeasonStepRemainTimeStr())
  elseif seasonStep == ProtoEnum.PVP_RANK_STEP.STEP_SETTLE then
    local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character10").str
    self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_TimeRemaining:SetText(str)
    local str1 = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character10").str
    self.Text_Time:SetText(str1)
  end
  local pvpRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local RankOrder = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_ORDER)
  if pvpRankConf then
    self.ClassIcon:SetRankInfo(pvpRankConf, RankOrder, curSeasonId)
  end
  self.NRCImage_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:RefreshBaseInfo()
end

function UMG_ChallengeItem_PVP_C:RefreshPvpInfo()
  self.SwitcherMessage:SetActiveWidgetIndex(0)
  local itemData = self.uiData
  self.Title:SetText(itemData.name)
  self.NRCText_1:SetText(itemData.des)
  self:RefreshBaseInfo()
  self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCImage_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCImage_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(itemData.icon_color))
  self.Department_1:SetPath(itemData.ticket_stub)
end

function UMG_ChallengeItem_PVP_C:RefreshBaseInfo()
  local itemData = self.uiData
  self.SystemType:SetPath(itemData.icon)
  local awardList = itemData and itemData.award_list or {}
  local rewardsTable = {}
  local bShowFirstVictory = not _G.NRCModeManager:DoCmd(_G.PVPRankedMatchModuleCmd.OnCmdIsAlreadyWonToday)
  local daily_first_win_award_list = itemData and itemData.daily_first_win_award_list or {}
  if daily_first_win_award_list then
    for i = 1, #daily_first_win_award_list do
      local awardConf = daily_first_win_award_list[i]
      local itemId = awardConf and awardConf.daily_first_win_award
      if itemId and itemId > 0 then
        local rewards = _G.NRCCommonItemIconData()
        local type = awardConf and awardConf.Type
        rewards.itemType = type
        rewards.itemId = itemId
        rewards.bShowFirstVictory = bShowFirstVictory
        table.insert(rewardsTable, rewards)
      end
    end
  end
  for _, confAwardItem in pairs(awardList) do
    local id = confAwardItem and confAwardItem.award
    local type = confAwardItem and confAwardItem.Type
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = type
    rewards.itemId = id
    table.insert(rewardsTable, rewards)
  end
  self.ItemIcon:InitGridView(rewardsTable)
  self.Img_di:SetPath(itemData.banner)
  if self.Btn and self.Btn.btnLevelUp and self.Btn.btnLevelUp.OnClicked then
    self.Btn.btnLevelUp.OnClicked:Remove(self, self.TraceBtnClick)
    self.Btn.btnLevelUp.OnClicked:Add(self, self.TraceBtnClick)
  end
  local npcInfo = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetNpcInfoByRefreshId, self.uiData.npcid)
  local LockState = _G.ProtoEnum.LockStatus.ENUM
  if npcInfo and (npcInfo.status == LockState.UNLOCKED or npcInfo.status == LockState.DUNGEON_FINISH) then
    self.IconRole:SetPath(itemData.npc_icon)
    self.BtnSwitch:SetActiveWidgetIndex(0)
    self.Switcher_NPC:SetActiveWidgetIndex(0)
    local NpcRefreshID = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetTraceNpcRefreshID)
    self.Btn:SetBtnText(LuaText.TASK_GOTO)
    self.ClassIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.IconRole:SetPathWithCallBack(itemData.npc_icon, function()
      self:SetStampImage(self.IconRole_1)
    end)
    self.BtnSwitch:SetActiveWidgetIndex(1)
    self.Switcher_NPC:SetActiveWidgetIndex(1)
    self.ClassIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.Btn1 then
      self.Btn1:SetClickAble(false, true)
      self.Btn1:SetShowLockIcon(false)
    end
  end
end

function UMG_ChallengeItem_PVP_C:SetStampImage(image)
  local material = image:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", self.IconRole.Brush.ResourceObject)
  image:SetBrushFromMaterial(material, false)
end

function UMG_ChallengeItem_PVP_C:TraceBtnClick()
  if self.uiData == nil then
    return
  end
  local functionEntranceType = _G.Enum.FunctionEntrance.FE_MAGIC_BOOK_PVP_RANK or 0
  local bBanPvpRank = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntranceType, true)
  if bBanPvpRank then
    return
  end
  local bShowTeleportDialog = self.uiData.id == pvpRankNpcId and not NRCModuleManager:DoCmd(MagicManualModuleCmd.HadAgreeRankTeleport) and _G.DataModelMgr.PlayerDataModel:HasStoryFlag(DataConfigManager:GetGlobalConfigNumByKeyType("pvp_rank_task", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, 0))
  if bShowTeleportDialog then
    self:OpenTeleportDialog()
  else
    self:ConfirmTeleport(true)
  end
end

function UMG_ChallengeItem_PVP_C:OnAnimationStarted(anim)
  if anim == self.In then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_ChallengeItem_PVP_C:OnItemSelected(_bSelected)
end

function UMG_ChallengeItem_PVP_C:OnDeactive()
end

function UMG_ChallengeItem_PVP_C:OnLogin()
end

function UMG_ChallengeItem_PVP_C:OnAnimationFinished(anim)
end

function UMG_ChallengeItem_PVP_C:OnSwitcherBtnSwitch(SwitcherIndex)
  self.BtnSwitch:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_ChallengeItem_PVP_C:OnClickNotFound()
end

function UMG_ChallengeItem_PVP_C:OpenTeleportDialog()
  if not self.uiData.npcid then
    return
  end
  local teleportDialog = DialogContext()
  teleportDialog:SetCallback(self, self.ConfirmTeleport)
  teleportDialog:SetContent(DataConfigManager:GetGlobalConfigStrByKeyType("pvp_rank_task_tips", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, ""))
  teleportDialog:SetMode(DialogContext.Mode.OK_CANCEL)
  teleportDialog:SetTitle(LuaText.TIPS)
  teleportDialog:SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.BACK)
  teleportDialog:SetClickAnywhereClose(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, teleportDialog)
end

function UMG_ChallengeItem_PVP_C:ConfirmTeleport(result)
  if not result then
    return
  end
  if not self.uiData.npcid then
    return
  end
  local NpcData = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, self.uiData.npcid)
  if NpcData then
    local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
    if bBan then
      return
    end
    if self.uiData.id == pvpRankNpcId then
      NRCModuleManager:DoCmd(MagicManualModuleCmd.AgreeRankTeleport)
    end
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SendWorldMapTeleportReq, NpcData.entry_id)
  else
    Log.Error("Invalid NpcData", self.uiData.npcid)
  end
end

return UMG_ChallengeItem_PVP_C
