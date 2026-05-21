local NPCShopUIModuleEvent = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local UMG_ReceiveAward_PopUp_C = _G.NRCPanelBase:Extend("UMG_ReceiveAward_PopUp_C")

function UMG_ReceiveAward_PopUp_C:OnConstruct()
  self.uiData = {}
  self.canClose = false
  UE4Helper.SetDesiredShowCursor(true, "UMG_ReceiveAward_PopUp_C")
  self:AddPcInputBlock()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnInVisible)
  self.bgProxy = _G.NRCModuleManager:DoCmd(TUIModuleCmd.PushBlackBackgroundWidgets, {
    self.BlackMask
  })
  self.IsOpenLegendaryBattleClosePanel = nil
end

function UMG_ReceiveAward_PopUp_C:OnDestruct()
  UE4Helper.ReleaseDesiredShowCursor("UMG_ReceiveAward_PopUp_C")
  self:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(TUIModuleCmd.PopBlackBackgroundWidgets, self.bgProxy)
end

function UMG_ReceiveAward_PopUp_C:OnActive(_param, text, reward_id, action, isOpenByBattleRewardPanel, IsOpenLegendaryBattleClosePanel, bIsSpecialAward, UseBtnInfo, IsWorldOpen, IsBestowBlessings)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401020, "UMG_ItemRewards_C:OnActive")
  local TitleText = text
  self.action = action
  self.isOpenByBattleRewardPanel = isOpenByBattleRewardPanel
  self.IsOpenLegendaryBattleClosePanel = IsOpenLegendaryBattleClosePanel
  local bInDungeon = _G.NRCModuleManager:DoCmd(_G.InstanceModuleCmd.IsInDungeon)
  self.bIsSpecialAward = bIsSpecialAward or bInDungeon
  self.IsBestowBlessings = IsBestowBlessings
  self.callBack = _param and _param.callBack or nil
  self.IsDungeonEggReward = self:CheckIsDungeonEggReward()
  if self.IsDungeonEggReward then
    self:DelaySeconds(5, function()
      self.RewardAnimFinished = true
    end)
  end
  if not _param and action then
    if reward_id then
      local RewardConf = _G.DataConfigManager:GetRewardConf(reward_id)
      if RewardConf then
        local RewardInfos = {}
        local RewardsInConf = RewardConf.RewardItem
        for _, item in ipairs(RewardsInConf) do
          table.insert(RewardInfos, {
            itemId = item.Id,
            id = item.Id,
            num = item.Count,
            type = item.Type,
            IsOverrideNum = true
          })
        end
        local text1 = LuaText.get_report_reward
        self.uiData = RewardInfos
        TitleText = text1
      end
    end
  else
    self.uiData = _param
  end
  if IsWorldOpen and bInDungeon then
    self.bPauseTip = true
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.DungeonReward)
  end
  if self.bIsSpecialAward and IsWorldOpen then
    self.TitlePattern:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if bInDungeon or IsBestowBlessings then
      self.TitleIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/CommonPopUp/Raw/Frames/img_icon_dan_png.img_icon_dan_png'")
    end
    self:PlayAnimation(self.In)
  else
    self:PlayAnimation(self.Normal_in)
    self.TitlePattern:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:OnAddEventListener()
  self.CommonPopUpData = UseBtnInfo
  if UseBtnInfo and UseBtnInfo.HideBtn == false then
    if UseBtnInfo.OnlyHideLeftBtn then
      self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BtnUse:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnClose:SetVisibility(UE4.ESlateVisibility.Visible)
    elseif UseBtnInfo.OnlyHideRightBtn then
      self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnUse:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BtnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnUse:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnClose:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnShowBtnClick)
    self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnBtnCloseClick)
  else
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnUse:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  if not string.IsNilOrEmpty(TitleText) then
    self.TitleText:SetText(TitleText)
  end
  self:SetDatas(self.uiData)
  self:BindInputAction()
end

function UMG_ReceiveAward_PopUp_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self)
end

function UMG_ReceiveAward_PopUp_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_ReceiveAward_PopUp_C:SetDatas(RewardsList)
  if self.isOpenByBattleRewardPanel and self.isOpenByBattleRewardPanel == true then
    if RewardsList and #RewardsList > 0 then
      local rewardsTable = _G.NRCCommonItemIconData():FromGoodsItem(RewardsList)
      for i = 1, #rewardsTable do
        rewardsTable[i].tag = self.uiData[i].tag
        rewardsTable[i] = self:HandleBossEvoReward(rewardsTable[i])
      end
      self.List1:InitList(rewardsTable)
      return
    else
      self.List1:Clear()
      return
    end
  end
  local SortRewardsList = {}
  local bHavePetEgg = false
  if self.IsDungeonEggReward or self.IsBestowBlessings then
    for i = 1, #RewardsList do
      if RewardsList[i].type == _G.Enum.GoodsType.GT_BAGITEM then
        RewardsList[i].isPetEgg, RewardsList[i].isPreciousPetEgg = self:IsPetEggAndPreciousPetEgg(RewardsList[i].itemId) or self.uiData.isPreciousPetEgg
      else
        RewardsList[i].isPetEgg, RewardsList[i].isPreciousPetEgg = false, false
      end
      if self.IsBestowBlessings then
        RewardsList[i].isPreciousPetEgg = true
      end
      if RewardsList[i].isPetEgg then
        bHavePetEgg = true
      end
    end
    SortRewardsList = self:SortItem2(RewardsList)
  else
    SortRewardsList = self:SortItem(RewardsList)
  end
  if SortRewardsList and #SortRewardsList > 0 then
    local rewardsTable = _G.NRCCommonItemIconData():FromGoodsItem(SortRewardsList)
    if self.IsDungeonEggReward or self.IsBestowBlessings then
      for i = 1, #SortRewardsList do
        rewardsTable[i].isPreciousPetEgg = SortRewardsList[i].isPreciousPetEgg
      end
    end
    for i = 1, #SortRewardsList do
      rewardsTable[i].bagItemGid = SortRewardsList[i].bagItemGid
      rewardsTable[i].AssignQuality = SortRewardsList[i].AssignQuality
      rewardsTable[i] = self:HandleBossEvoReward(rewardsTable[i])
      if SortRewardsList[i].eggInfo then
        rewardsTable[i].eggInfo = SortRewardsList[i].eggInfo
      end
      if SortRewardsList[i].gid then
        rewardsTable[i].gid = SortRewardsList[i].gid
      end
    end
    if self:NeedSpecialRefreshShow(bHavePetEgg) then
      self:SpecialRefreshListHandle(rewardsTable)
    else
      self.List1:InitList(rewardsTable)
    end
  else
    self.List1:Clear()
  end
end

function UMG_ReceiveAward_PopUp_C:NeedSpecialRefreshShow(bHavePetEgg)
  if (self.IsDungeonEggReward or self.IsBestowBlessings) and bHavePetEgg then
    return true
  end
  return false
end

function UMG_ReceiveAward_PopUp_C:SpecialRefreshListHandle(rewardsTable)
  if not rewardsTable or #rewardsTable < 1 then
    self.List1:Clear()
    Log.Error("UMG_ReceiveAward_PopUp_C:SpecialRefreshListHandle rewardsTable is nil or empty")
    return
  end
  self.rewardsTable = rewardsTable
  self.refreshIndex = 0
  self.RewardAnimFinished = false
  self:DoNextRefresh()
end

function UMG_ReceiveAward_PopUp_C:DoNextRefresh()
  if not UE4.UObject.IsValid(self) then
    return
  end
  self.refreshIndex = self.refreshIndex + 1
  local refreshIndex = self.refreshIndex
  if refreshIndex > #self.rewardsTable then
    self.RewardAnimFinished = true
    return
  end
  local thisRewardList = {}
  for i = 1, refreshIndex do
    local item = table.deepCopy(self.rewardsTable[i])
    item.SpecialShowHandle = i == refreshIndex
    table.insert(thisRewardList, item)
  end
  self.List1:InitList(thisRewardList)
  if refreshIndex <= #self.rewardsTable then
    local waitTime = 1 == refreshIndex and 2 or 0.2
    self:DelaySeconds(waitTime, function()
      self:DoNextRefresh()
    end)
  end
end

function UMG_ReceiveAward_PopUp_C:HandleBossEvoReward(RewardItem)
  local RetRewardItem = RewardItem
  if not RetRewardItem then
    Log.Error("UMG_ReceiveAward_PopUp_C:HandleBossEvoReward RewardItem is nil")
    return RetRewardItem
  end
  if RewardItem.itemId ~= nil and RewardItem.itemType and RewardItem.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(RewardItem.itemId)
    local BagItemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, RewardItem.itemId)
    if BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO then
        RetRewardItem.Extra = true
      end
    end
  end
  return RetRewardItem
end

function UMG_ReceiveAward_PopUp_C:CheckThisRewardShouldShow(RewardItem)
  local bShow = true
  if not RewardItem then
    Log.Error("UMG_ReceiveAward_PopUp_C:CheckThisRewardShouldShow RewardItem is nil")
    return bShow
  end
  if RewardItem.itemId ~= nil and RewardItem.itemType and RewardItem.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(RewardItem.itemId)
    local BagItemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, RewardItem.itemId)
    if BagItemData and BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO and 0 ~= BagItemData.num then
        bShow = false
      end
    end
  end
  return bShow
end

function UMG_ReceiveAward_PopUp_C:IsPetEggAndPreciousPetEgg(rewardId)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewardId)
  if bagItemConf and bagItemConf.item_behavior and #bagItemConf.item_behavior > 0 then
    for i = 1, #bagItemConf.item_behavior do
      if bagItemConf.item_behavior[i].use_action == _G.Enum.ItemBehavior.IB_PET_EGG_HATCH and #bagItemConf.item_behavior[i].ratio > 0 then
        for j = 1, #bagItemConf.item_behavior[i].ratio do
          local petEggConf = _G.DataConfigManager:GetPetEggConf(bagItemConf.item_behavior[i].ratio[j])
          if petEggConf and petEggConf.precious_egg_type and petEggConf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
            return true, true
          end
        end
        return true, false
      end
    end
  end
  return false, false
end

function UMG_ReceiveAward_PopUp_C:SortItem2(RewardsList)
  for i = 1, #RewardsList - 1 do
    for j = 1, #RewardsList - i do
      local a = RewardsList[j]
      local b = RewardsList[j + 1]
      if not a.isPetEgg and b.isPetEgg or not a.isPreciousPetEgg and b.isPreciousPetEgg then
        RewardsList[j], RewardsList[j + 1] = RewardsList[j + 1], RewardsList[j]
      end
    end
  end
  return RewardsList
end

function UMG_ReceiveAward_PopUp_C:SortItem(RewardsList)
  local SortRewardsList = {}
  for i, Reward in ipairs(RewardsList) do
    Reward.Sort = 0
    Reward.Conf = nil
    Reward.Quality = 0
    if Reward.type == _G.ProtoEnum.GoodsType.GT_VITEM then
      Reward.Conf = _G.DataConfigManager:GetVisualItemConf(Reward.id)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
        Reward.Quality = Reward.Conf.item_quality
      end
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_PET then
      Reward.Conf = _G.DataConfigManager:GetPetbaseConf(Reward.id)
      Reward.Sort = 0
      Reward.Quality = 0
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_BAGITEM then
      Reward.Conf = _G.DataConfigManager:GetBagItemConf(Reward.id)
      if Reward.Conf then
        Reward.Sort = Reward.Conf.sort_id
        Reward.Quality = Reward.Conf.item_quality
      end
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_EMOJI then
      Reward.Conf = _G.DataConfigManager:GetChatEmojiConf(Reward.id)
      if Reward.Conf then
        Reward.Sort = 0
        Reward.Quality = Reward.Conf.card_quality
      end
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_CARD_ICON then
      Reward.Conf = _G.DataConfigManager:GetCardIconConf(Reward.id)
      if Reward.Conf then
        Reward.Sort = 0
        Reward.Quality = Reward.Conf.card_quality
      end
    elseif Reward.type == _G.ProtoEnum.GoodsType.GT_CARD_SKIN then
      Reward.Conf = _G.DataConfigManager:GetCardSkinConf(Reward.id)
      if Reward.Conf then
        Reward.Sort = 0
        Reward.Quality = Reward.Conf.card_quality
      end
    end
  end
  SortRewardsList = RewardsList
  table.sort(SortRewardsList, function(a, b)
    if a.Quality ~= b.Quality then
      return a.Quality > b.Quality
    end
    if a.Sort < b.Sort then
      return a.Sort < b.Sort
    elseif a.Sort == b.Sort then
      local ANewSort = a.id
      local BNewSort = b.id
      if a.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        ANewSort = ANewSort + 9999999
      elseif b.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        BNewSort = BNewSort + 9999999
      end
      return ANewSort < BNewSort
    end
  end)
  return SortRewardsList
end

function UMG_ReceiveAward_PopUp_C:OnDeactive()
  if self.bPauseTip then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.DungeonReward)
    self.bPauseTip = false
  end
end

function UMG_ReceiveAward_PopUp_C:OnAddEventListener()
  self:AddButtonListener(self.FullScreen_Close, self.OnBtnCloseClick)
end

function UMG_ReceiveAward_PopUp_C:OnBtnCloseClick()
  if self.canClose == true and (self.RewardAnimFinished or not self.IsDungeonEggReward) then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_ItemRewards_C:OnBtnCloseClick")
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400003, "UMG_ItemRewards_C:OnBtnCloseClick")
    if self.bIsSpecialAward then
      self:PlayAnimation(self.Out)
    else
      self:PlayAnimation(self.Normal_out)
    end
    self.canClose = false
  end
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.ClosePanelHandler then
    self.CommonPopUpData.ClosePanelHandler(self.CommonPopUpData.Call)
  end
end

function UMG_ReceiveAward_PopUp_C:OnAnimationFinished(Animation)
  if Animation == self.Out or Animation == self.Normal_out then
    self.canClose = true
    if self.action then
      self.action:Finish()
    end
    if self.callBack then
      self:callBack()
    end
    _G.NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE)
    if self.IsOpenLegendaryBattleClosePanel then
      _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_RewardsPanel_Close)
    end
    self:DoClose()
  elseif Animation == self.In or Animation == self.Normal_in then
    self:UnlockIsSelectBtn()
    self.canClose = true
  end
end

function UMG_ReceiveAward_PopUp_C:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").GET)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TIPS)
end

function UMG_ReceiveAward_PopUp_C:BindInputAction()
end

function UMG_ReceiveAward_PopUp_C:OnPcClose()
  self:OnBtnCloseClick()
end

function UMG_ReceiveAward_PopUp_C:OnPcClose2()
end

function UMG_ReceiveAward_PopUp_C:OnShowBtnClick()
  if self.CommonPopUpData and self.CommonPopUpData.Call and self.CommonPopUpData.Btn_LeftHandler then
    self.CommonPopUpData.Btn_LeftHandler(self.CommonPopUpData.Call)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Dialog_C:OnClickOkButton")
end

function UMG_ReceiveAward_PopUp_C:CheckIsDungeonEggReward()
  return self.action and self.action.Config and self.action.Config.action_param2 == "DungeonEggReward"
end

return UMG_ReceiveAward_PopUp_C
