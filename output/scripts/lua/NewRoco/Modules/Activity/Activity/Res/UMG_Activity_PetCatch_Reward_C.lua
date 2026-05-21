local UMG_Activity_PetCatch_Reward_C = _G.NRCPanelBase:Extend("UMG_Activity_PetCatch_Reward_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_PetCatch_Reward_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self.CustomItemWidth = 195
  self:AddButtonListener(self.Btn3.btnLevelUp, self.OnClickGetAllReward)
  self.List.OnUserScrolled:Add(self, self.UseScrollCallBack)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshReceivePetCatchRewards, self.OnRefreshReceivePetCatchRewards)
end

function UMG_Activity_PetCatch_Reward_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  CommonPopUpData.TitleText = LuaText.get_report_reward
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Activity_PetCatch_Reward_C:ShowJackpot(offset)
  local size = self.List.Slot:GetSize()
  local ShowSize = size.x + offset
  local ItemWidth = self.CustomItemWidth
  local Index = math.floor(ShowSize / ItemWidth + 0.5)
  local PointsRewards = self.activityInst:GetPointsRewards()
  local itemData = {}
  local find = false
  local MaxIndex = -1
  for i, v in ipairs(PointsRewards) do
    if v.if_reward_jackpot and i > Index then
      find = true
      itemData.parent = self
      itemData.customData = i
      itemData.IsRewardPoint = true
      break
    end
    if v.if_reward_jackpot and i <= Index and i >= MaxIndex then
      MaxIndex = i
    end
  end
  if not find then
    itemData.parent = self
    itemData.customData = MaxIndex
    itemData.IsRewardPoint = true
  end
  self.PetCatch_RewardItem1:SetNormalState1()
  self.PetCatch_RewardItem1:OnItemUpdate(itemData, nil, itemData.customData - 1)
  self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Activity_PetCatch_Reward_C:UseScrollCallBack(offset)
  if self.activityInst and self.activityInst:GetActivityType() == Enum.ActivityType.ATP_TRACK_CONDITION then
    self:ShowJackpot(offset)
  end
end

function UMG_Activity_PetCatch_Reward_C:OnActive(_activityInst)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCAudioManager:PlaySound2DAuto(41400002, "UMG_Activity_PetCatch_Reward_C:OnActive")
  self.activityInst = _activityInst
  if _activityInst then
    local pos = self.List.Slot:GetPosition()
    local size = self.List.Slot:GetSize()
    if self.activityInst:GetActivityType() == Enum.ActivityType.ATP_PET_CATCH then
      self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.activityInst:GetActivityType() == Enum.ActivityType.ATP_TRACK_CONDITION then
      pos.x = -105.0
      size.x = 862.0
      local ItemType = self.activityInst.SeasonCheckinConf and self.activityInst.SeasonCheckinConf.change_goods_type
      local ItemId = self.activityInst.SeasonCheckinConf and self.activityInst.SeasonCheckinConf.change_goods_id
      if ItemType and ItemId then
        if ItemType == Enum.GoodsType.GT_BAGITEM then
          local item_conf = _G.DataConfigManager:GetBagItemConf(ItemId)
          if item_conf then
            self.icon:SetPath(item_conf.icon)
          end
        end
        if ItemType == Enum.GoodsType.GT_VITEM then
          local item_conf = _G.DataConfigManager:GetVisualItemConf(ItemId)
          if item_conf then
            self.icon:SetPath(item_conf.iconPath)
          end
        end
      end
      self.Btn3.RedDot:SetupKey(427, {
        self.activityInst:GetActivityId()
      })
    end
    self.List.Slot:SetPosition(pos)
    self.List.Slot:SetSize(size)
    local points = _activityInst:GetPoints()
    local pointsMax = _activityInst:GetPointsMax()
    self.Text_quantity:SetText(points .. "/" .. pointsMax)
    local minSlotRewardNotGet = math.maxinteger
    local maxSlotCanGetRewards = 0
    local hasRewardNotReceived = false
    local rewardsTable = {}
    local rewardsGroup = _activityInst:GetPointsRewards()
    if rewardsGroup then
      for _slot, _reward in ipairs(rewardsGroup) do
        if 0 == _reward.reward_id then
          break
        end
        table.insert(rewardsTable, _slot)
        local rewardNotReceived = false
        if points >= _reward.points_condition then
          maxSlotCanGetRewards = _slot
          if not _activityInst:IsRewardGet(_slot - 1) then
            rewardNotReceived = true
          end
        end
        if points < _reward.points_condition or rewardNotReceived then
          minSlotRewardNotGet = math.min(minSlotRewardNotGet, _slot)
        end
        if rewardNotReceived then
          hasRewardNotReceived = true
        end
      end
    end
    self.List:InitList(ActivityUtils.CreateActivityItemBaseDataForList(self, rewardsTable))
    if minSlotRewardNotGet ~= math.maxinteger then
      local offset = self.CustomItemWidth * (minSlotRewardNotGet - 1)
      self.List:SetScrollOffset(offset)
      self:ShowJackpot(offset)
    else
      self:ShowJackpot(0)
    end
    local percent = 0
    if points > 0 and rewardsGroup and #rewardsGroup > 0 then
      local scale = 1 / (#rewardsGroup * 2 - 1)
      if maxSlotCanGetRewards > 0 then
        percent = (maxSlotCanGetRewards * 2 - 1) * scale
      end
      if maxSlotCanGetRewards <= 0 then
        local curPoints = rewardsGroup[1].points_condition
        percent = percent + (points - curPoints) / curPoints * scale * 2
      elseif maxSlotCanGetRewards + 1 <= #rewardsGroup then
        local nextPoints = rewardsGroup[maxSlotCanGetRewards + 1].points_condition
        local curPoints = rewardsGroup[maxSlotCanGetRewards].points_condition
        percent = percent + (points - curPoints) / (nextPoints - curPoints) * scale * 2
      else
        local curPoints = rewardsGroup[maxSlotCanGetRewards].points_condition
        local prePoints = rewardsGroup[maxSlotCanGetRewards - 1].points_condition
        percent = percent + (points - curPoints) / (curPoints - prePoints) * scale * 2
      end
    end
    self.JinduProgressBar:SetPercent(percent)
    self:DelayFrames(5, function()
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:LoadAnimation(0)
      self.Btn3:SetVisibility(hasRewardNotReceived and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
      self:SetCommonPopUpInfo()
    end)
  end
end

function UMG_Activity_PetCatch_Reward_C:OnDeactive()
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_Activity_PetCatch_Reward_C:OnDeactive")
end

function UMG_Activity_PetCatch_Reward_C:OnCloseBtn()
  self:LoadAnimation(2)
end

function UMG_Activity_PetCatch_Reward_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_PetCatch_Reward_C:OnDestruct()
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshReceivePetCatchRewards)
end

function UMG_Activity_PetCatch_Reward_C:OnClickGetAllReward()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_PetCatch_Reward_C:OnClickGetAllReward")
  local _activityInst = self.activityInst
  if _activityInst then
    local pointIndexGroup = {}
    local points = _activityInst:GetPoints()
    local rewardsGroup = _activityInst:GetPointsRewards()
    if rewardsGroup then
      for _slot, _reward in ipairs(rewardsGroup) do
        if 0 ~= _reward.reward_id and points >= _reward.points_condition then
          if not _activityInst:IsRewardGet(_slot - 1) then
            table.insert(pointIndexGroup, _slot - 1)
          end
        else
          break
        end
      end
    end
    _activityInst:ReqGetRewards(pointIndexGroup)
  end
end

function UMG_Activity_PetCatch_Reward_C:OnRefreshReceivePetCatchRewards(_activityInst, _receivedRewardsIndex, _userOperation, _protoData)
  if not _activityInst or _activityInst ~= self.activityInst then
    return
  end
  if _userOperation then
    for _, _slot in ipairs(_receivedRewardsIndex) do
      local itemIndex = self.List:GetIndexByData(_slot, function(_data, _valueInList)
        return _valueInList and _valueInList.customData == _data + 1
      end)
      if itemIndex then
        self.List:OpItemByIndex(itemIndex, _userOperation)
      end
    end
  end
  local hasRewardNotReceived = false
  local points = _activityInst:GetPoints()
  local rewardsGroup = _activityInst:GetPointsRewards()
  local minSlotRewardNotGet = math.maxinteger
  local maxSlotCanGetRewards = 0
  if rewardsGroup then
    for _slot, _reward in ipairs(rewardsGroup) do
      if 0 ~= _reward.reward_id and points >= _reward.points_condition and not _activityInst:IsRewardGet(_slot - 1) then
        hasRewardNotReceived = true
        break
      end
    end
  end
  if rewardsGroup then
    for _slot, _reward in ipairs(rewardsGroup) do
      if 0 == _reward.reward_id then
        break
      end
      local rewardNotReceived = false
      if points >= _reward.points_condition then
        maxSlotCanGetRewards = _slot
        if not _activityInst:IsRewardGet(_slot - 1) then
          rewardNotReceived = true
        end
      end
      if points < _reward.points_condition or rewardNotReceived then
        minSlotRewardNotGet = math.min(minSlotRewardNotGet, _slot)
      end
    end
  end
  if minSlotRewardNotGet ~= math.maxinteger then
    local offset = self.CustomItemWidth * (minSlotRewardNotGet - 1)
    self.List:SetScrollOffset(offset)
    self:ShowJackpot(offset)
  else
    self:ShowJackpot(0)
  end
  self.Btn3:SetVisibility(hasRewardNotReceived and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_PetCatch_Reward_C:OnItemUpdate(_itemInst, _index, _rewardSlot)
  local activityInst = self.activityInst
  if activityInst and _itemInst then
    local points = activityInst:GetPoints()
    local pointsRewards = activityInst:GetPointsRewards()
    local pointRewardConf = pointsRewards and pointsRewards[_rewardSlot]
    if pointRewardConf then
      _itemInst:SetQuantity(pointRewardConf.points_condition)
      _itemInst:SetupRedPoint(ActivityEnum.RedPointKey.DetailReward, {
        activityInst:GetActivityId(),
        _rewardSlot - 1
      })
      if self.activityInst:GetActivityType() == Enum.ActivityType.ATP_PET_CATCH then
        local rewardConf = _G.DataConfigManager:GetRewardConf(pointRewardConf.reward_id)
        local rewardItem = rewardConf and rewardConf.RewardItem[1]
        local itemData = {}
        itemData.itemType = rewardItem and rewardItem.Type or 0
        itemData.itemId = rewardItem and rewardItem.Id or 0
        itemData.itemNum = rewardItem and rewardItem.Count or 0
        itemData.bShowNum = true
        itemData.bShowTip = true
        itemData.IsCanClick = true
        _itemInst:SetItemData(itemData)
      elseif self.activityInst:GetActivityType() == Enum.ActivityType.ATP_TRACK_CONDITION then
        _itemInst:SetupRedPoint(427, {
          activityInst:GetActivityId(),
          _rewardSlot - 1
        })
        if pointRewardConf.reward_type == Enum.GoodsType.GT_REWARD then
          local rewardConf = _G.DataConfigManager:GetRewardConf(pointRewardConf.reward_id)
          local rewardItem = rewardConf and rewardConf.RewardItem[1]
          local itemData = {}
          itemData.itemType = rewardItem and rewardItem.Type or 0
          itemData.itemId = rewardItem and rewardItem.Id or 0
          itemData.itemNum = rewardItem and rewardItem.Count or 0
          itemData.bShowNum = true
          itemData.bShowTip = true
          itemData.IsCanClick = true
          _itemInst:SetItemData(itemData)
        else
          local itemData = {}
          itemData.itemType = pointRewardConf.reward_type or 0
          itemData.itemId = pointRewardConf.reward_id or 0
          itemData.itemNum = pointRewardConf.reward_count or 0
          itemData.bShowNum = true
          itemData.bShowTip = true
          itemData.IsCanClick = true
          _itemInst:SetItemData(itemData)
        end
      end
      if points >= pointRewardConf.points_condition then
        if self.activityInst:GetActivityType() == Enum.ActivityType.ATP_TRACK_CONDITION then
          local rewardReceived = activityInst:IsRewardGet(_rewardSlot - 1)
          if _itemInst.itemData.IsRewardPoint then
            if rewardReceived then
              _itemInst.NRCImage_0:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#F4EEE1FF"))
              _itemInst.ParticleSystemWidget2_53:SetActivate(false)
              _itemInst.ParticleSystemWidget2_53:SetVisibility(UE4.ESlateVisibility.Collapsed)
            else
              _itemInst.NRCImage_0:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC65FFF"))
              _itemInst.ParticleSystemWidget2_53:SetActivate(true)
              _itemInst.ParticleSystemWidget2_53:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            end
          elseif rewardReceived then
          else
            _itemInst:SetRewardAvailable_SeasonItem()
          end
        else
          _itemInst:SetRewardAvailable()
        end
      end
    end
  end
  self:OnItemOp(_itemInst, _index, _rewardSlot, false)
end

function UMG_Activity_PetCatch_Reward_C:OnItemOp(_itemInst, _index, _rewardSlot, _userOperation)
  local activityInst = self.activityInst
  if activityInst and _itemInst then
    local rewardReceived = activityInst:IsRewardGet(_rewardSlot - 1)
    _itemInst:SetAlreadyReceived(rewardReceived, _userOperation and rewardReceived, self.activityInst:GetActivityType() == Enum.ActivityType.ATP_TRACK_CONDITION and not _itemInst.itemData.IsRewardPoint)
  end
end

function UMG_Activity_PetCatch_Reward_C:OnItemSelected(_itemInst, _index, _rewardSlot, _bSelected, _bScroll)
  local activityInst = self.activityInst
  if _bSelected and _itemInst and activityInst then
    local rewardReceived = activityInst:IsRewardGet(_rewardSlot - 1)
    if rewardReceived then
      _itemInst:SelectItem(_bScroll)
    else
      local points = activityInst:GetPoints()
      local pointsRewards = activityInst:GetPointsRewards()
      local pointRewardConf = pointsRewards and pointsRewards[_rewardSlot]
      if pointRewardConf and points >= pointRewardConf.points_condition then
        activityInst:ReqGetRewards({
          _rewardSlot - 1
        })
      else
        _itemInst:SelectItem(_bScroll)
      end
    end
  end
end

return UMG_Activity_PetCatch_Reward_C
