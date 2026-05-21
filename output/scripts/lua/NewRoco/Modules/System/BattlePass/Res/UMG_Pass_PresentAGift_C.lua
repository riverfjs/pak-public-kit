local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local UMG_Pass_PresentAGift_C = _G.NRCPanelBase:Extend("UMG_Pass_PresentAGift_C")

function UMG_Pass_PresentAGift_C:OnConstruct()
  self:OnAddEventListener()
  self.isFirstOpen = true
end

function UMG_Pass_PresentAGift_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateActiveTableView, self.UpdateTable)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.OnCloseAwardMain, self.ClosePanel)
end

function UMG_Pass_PresentAGift_C:OnAddEventListener()
  self.List_1:BindLuaCallback({
    self,
    self.OnScrollCallback
  })
  self:AddButtonListener(self.AwardItem3.Btn_Below, self.OnOpenPurchasePanel)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PresentAGift_C", self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PresentAGift_C", self, BattlePassModuleEvent.UpdateActiveTableView, self.UpdateTable)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PresentAGift_C", self, BattlePassModuleEvent.OnCloseAwardMain, self.ClosePanel)
end

function UMG_Pass_PresentAGift_C:UpdateTable(index)
  if self.LastTableIndex ~= index and 0 ~= index then
    self:ClosePanel()
  end
  self.LastTableIndex = index
end

function UMG_Pass_PresentAGift_C:ClosePanel()
  self:PlayOutGiftAnimation()
end

function UMG_Pass_PresentAGift_C:OnActive(battlePassInfo)
  if battlePassInfo then
    self:RefreshUI(battlePassInfo)
  end
  self:PlayInGiftAnimation()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TAB)
end

function UMG_Pass_PresentAGift_C:RefreshUI(battlePassInfo)
  self.battlePassInfo = battlePassInfo
  local themeId = battlePassInfo.theme_id
  self.curLevel = battlePassInfo.exp_info and battlePassInfo.exp_info.level or 0
  self.themCfg = _G.DataConfigManager:GetBattlePassThemeConf(themeId)
  if not self.themCfg then
    Log.Error(themeId, "\233\133\141\231\189\174\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\232\129\148\231\179\187monoli")
    Log.Dump(self.battlePassInfo, 9, "UMG_Pass_PresentAGift_C:RefreshUI")
    return
  end
  self.battlePassId = battlePassInfo.battle_pass_id
  self:SetupHeadItem()
  self:SetupItems()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_PresentAGift", self)
  _G.NRCGCManager:TryGC(false, 33)
end

function UMG_Pass_PresentAGift_C:OnUpdateBattlePassInfo()
  local battlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self:RefreshUI(battlePassInfo)
end

function UMG_Pass_PresentAGift_C:PlayInGiftAnimation()
  local animLv = self.curLevel
  if self.curScrollLv then
    animLv = self.curScrollLv
  end
  if self.ItemDatas and #self.ItemDatas > 0 then
    self:HideListItems(animLv, #self.ItemDatas)
    self:DelaySeconds(0, function()
      self:PlayListAnimation(animLv, #self.ItemDatas, true)
    end)
  end
end

function UMG_Pass_PresentAGift_C:PlayOutGiftAnimation()
  self:PlayAnimation(self.Kuili_Out)
end

function UMG_Pass_PresentAGift_C:HideListItems(from, to)
  if 0 == from then
    from = 1
  end
  for i = from, to do
    local item = self.List_1:GetItemByIndex(i - 1)
    if item then
      item:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_Pass_PresentAGift_C:PlayListAnimation(from, to, isIn)
  if 0 == from then
    from = 1
  end
  for i = from, to do
    local item = self.List_1:GetItemByIndex(i - 1)
    if not item then
      return
    end
    if isIn then
      item:PlayInAnimation(0.04 * (i - from + 4))
    else
      item:PlayNormalAnimation()
    end
  end
end

function UMG_Pass_PresentAGift_C:SetupHeadItem()
  local themCfg = self.themCfg
  if nil == themCfg then
    Log.Error("\233\133\141\231\189\174\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\232\129\148\231\179\187monoli")
    return
  end
  self.AwardItem3.FreeNameText:SetText(themCfg.free_reward_name)
  self.AwardItem3.FreeIcon:SetPath(themCfg.free_reward_icon)
  self.AwardItem3.Theme_PaidNameText:SetText(themCfg.paid_reward_name)
  self.AwardItem3.PaidIcon:SetPath(themCfg.paid_reward_icon)
  self.AwardItem3.PaidIconBg:SetPath(themCfg.paid_reward_icon)
  self.AwardItem3.PaidIconBg:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("0000004C"))
  local hexColor = themCfg.paid_reward_name_color
  self.AwardItem3.Theme_PaidNameText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727"))
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_AwardItem3", self.AwardItem3)
  if self:HasPaid() then
    self.AwardItem3.PaidIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AwardItem3.lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.AwardItem3.PaidIconBg:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.AwardItem3.lock_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_Pass_PresentAGift_C:GetHandbookId(themCfg)
  local handbookId = 0
  local handbookConfs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK):GetAllDatas()
  for _, handbookConf in ipairs(handbookConfs) do
    for i = 1, #handbookConf.include_petbase_id do
      local petbaseId = handbookConf.include_petbase_id[i].petbase_id[1]
      if petbaseId == themCfg.theme_petbase_id then
        handbookId = handbookConf.id
        break
      end
    end
  end
  return handbookId
end

function UMG_Pass_PresentAGift_C:HasPaid()
  local grade = self.battlePassInfo.battle_pass_brief_info and self.battlePassInfo.battle_pass_brief_info.gift_grade or _G.Enum.BattlePassGiftGrade.BPGG_FREE
  local hasPaid = grade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL or grade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION
  return hasPaid
end

function UMG_Pass_PresentAGift_C:SetupItems()
  local playerLv = self.battlePassInfo.exp_info.level
  local rewardTakenInfo = {}
  if self.battlePassInfo.reward_info and self.battlePassInfo.reward_info.reward_taken_info then
    rewardTakenInfo = self.battlePassInfo.reward_info.reward_taken_info
  end
  local battlePassCfg = _G.DataConfigManager:GetBattlePassConf(self.battlePassId)
  local TOP_LEVEL = battlePassCfg.top_level
  local LOOP_LEVEL = battlePassCfg.loop_level
  local hasPaid = self:HasPaid()
  local bpLvToTakenMap = {}
  for i, value in pairs(rewardTakenInfo) do
    bpLvToTakenMap[i] = {
      info = value,
      index = i - 1
    }
  end
  
  local function _checkRewardState(bp_level, isFree, hasPaid)
    local state = 0
    if not bpLvToTakenMap[bp_level] then
      state = 0
    elseif isFree then
      if bpLvToTakenMap[bp_level].info.is_free_reward_taken then
        state = 2
      else
        state = 1
      end
    elseif bpLvToTakenMap[bp_level].info.is_paid_reward_taken then
      state = 2
    elseif hasPaid then
      state = 1
    end
    return state
  end
  
  local themCfg = self.themCfg
  local reward_set_id = themCfg.reward_set_id
  local passRewardCfgs = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetAllRewardConfig)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local gender = player.gender
  local r = {}
  for i, cfg in ipairs(passRewardCfgs) do
    if cfg.belong_reward_set_id == reward_set_id then
      local freeRewardId = cfg.male_free_reward_id
      if 2 == gender then
        freeRewardId = cfg.female_free_reward_id
      end
      local freeItemCfgs = _G.DataConfigManager:GetRewardConf(freeRewardId).RewardItem
      local freeItems = {}
      local freeState = _checkRewardState(cfg.bp_level, true, hasPaid)
      for index, value in ipairs(freeItemCfgs) do
        freeItems[index] = {
          cfg = value,
          state = freeState,
          awardInfo = bpLvToTakenMap[cfg.bp_level]
        }
      end
      local paidItemCfgs = {}
      local paid_reward_id
      if 1 == gender then
        paid_reward_id = cfg.male_paid_reward_id
      else
        paid_reward_id = cfg.female_paid_reward_id
      end
      if paid_reward_id and paid_reward_id > 0 then
        paidItemCfgs = _G.DataConfigManager:GetRewardConf(paid_reward_id).RewardItem
      end
      local paidItems = {}
      local paidState = _checkRewardState(cfg.bp_level, false, hasPaid)
      for index, value in ipairs(paidItemCfgs) do
        paidItems[index] = {
          cfg = value,
          state = paidState,
          awardInfo = bpLvToTakenMap[cfg.bp_level]
        }
      end
      r[#r + 1] = {
        id = cfg.id,
        needExp = cfg.need_exp,
        level = cfg.bp_level,
        awardInfo = bpLvToTakenMap[cfg.bp_level],
        freeState = freeState,
        paidState = paidState,
        freeItems = freeItems,
        paidItems = paidItems,
        isSpecial = cfg.is_special_level
      }
    end
  end
  if playerLv > TOP_LEVEL then
    local temp = r[#r]
    for i = TOP_LEVEL + 1, playerLv do
      local freeState = _checkRewardState(i, true, hasPaid)
      local paidState = _checkRewardState(i, false, hasPaid)
      if freeState > 0 or paidState > 0 then
        local freeItems = {}
        for index, item in ipairs(temp.freeItems) do
          freeItems[index] = {
            cfg = item.cfg,
            state = freeState,
            awardInfo = bpLvToTakenMap[i]
          }
        end
        local paidItems = {}
        for index, item in ipairs(temp.paidItems) do
          paidItems[index] = {
            cfg = item.cfg,
            state = paidState,
            awardInfo = bpLvToTakenMap[i]
          }
        end
        local t = {
          id = i,
          needExp = temp.needExp,
          level = i,
          awardInfo = bpLvToTakenMap[i],
          freeState = freeState,
          paidState = paidState,
          freeItems = freeItems,
          paidItems = paidItems,
          isSpecial = false
        }
        table.insert(r, #r, t)
      end
    end
  end
  self.ItemDatas = r
  self._lastSpecificLevel = nil
  self.List_1:InitList(r)
  if self.isFirstOpen then
    local item = self.List_1:GetItemByIndex(0)
    if item then
      self.ItemWidth = item:GetDesiredSize().X
      self.List_1:SetRenderOpacity(0)
      self:DelayFrames(2, function()
        self.List_1:SetRenderOpacity(1)
        self.List_1:ScrollToIndex(self.curLevel - 1 >= 0 and self.curLevel - 1 or 0, true)
        self:ListInit()
      end)
      self.curScrollLv = self.curLevel
    end
  else
    self:RefreshSpecificItem(self.curScrollLv)
  end
end

function UMG_Pass_PresentAGift_C:ListInit()
  local cgo = self.List_1:GetCachedGeometry()
  local listSize = UE4.USlateBlueprintLibrary.GetLocalSize(cgo)
  if self.ItemWidth then
    self.VisItemCount = math.ceil(listSize.X / self.ItemWidth)
    self.listSize_x = listSize.X
  end
  self:RefreshSpecificItem(self.curLevel)
  self.isFirstOpen = false
end

function UMG_Pass_PresentAGift_C:OnScrollCallback(Offset)
  if self.ItemWidth and self.listSize_x then
    local curScrollLv = math.floor(Offset / self.ItemWidth) + 1
    local borderScrollLv = math.floor((Offset + self.listSize_x - self.ItemWidth / 2) / self.ItemWidth) + 2
    self:RefreshSpecificItem(curScrollLv, borderScrollLv)
    self.curScrollLv = curScrollLv
  end
end

function UMG_Pass_PresentAGift_C:RefreshSpecificItem(curScrollLv, borderScrollLv)
  if self.VisItemCount == nil then
    return
  end
  local visItemCount = self.VisItemCount
  local startIdx = math.ceil(curScrollLv + visItemCount)
  local itemDatas = self.ItemDatas
  if borderScrollLv then
    startIdx = borderScrollLv
  end
  local targetData
  for i = startIdx, #itemDatas do
    if nil == itemDatas[i] then
      Log.Error("startIdx, visItemCount, i", startIdx, visItemCount, i)
    elseif 1 == itemDatas[i].isSpecial then
      targetData = itemDatas[i]
      break
    end
  end
  if not targetData and startIdx > #itemDatas then
    targetData = itemDatas[#itemDatas]
  end
  if targetData and targetData.level ~= self._lastSpecificLevel then
    self._lastSpecificLevel = targetData.level
    self.AwardItem2:RefreshItem(targetData)
  end
end

function UMG_Pass_PresentAGift_C:OnOpenPurchasePanel()
  local panelName = "BattlePassAwardMain"
  local moduleName = "BattlePassModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, false)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).TICKET
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(1220002005, "UMG_Pass_PresentAGift_C:OnOpenPurchasePanel")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassPurchasePanel)
end

return UMG_Pass_PresentAGift_C
