local UMG_Activity_TakePhotoCompetition_RaffleTicket_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_RaffleTicket_C")
local ActivityModuleCmd = require("NewRoco.Modules.System.Activity.ActivityModuleCmd")
local FriendModuleCmd = reload("NewRoco.Modules.System.Friend.FriendModuleCmd")
local allGoodsReturnConf = _G.DataConfigManager:GetAllByName("GOODS_RETURN_CONF")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnActive(rsp)
  if not rsp then
    Log.Error("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnActive rsp is nil")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40007006, "UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnActive")
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if not takePhotoActivityInst then
    Log.Error("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnActive takePhotoActivityInst is nil")
    return
  end
  local activity_data = takePhotoActivityInst[1]:GetActivityData()
  if not activity_data then
    return
  end
  local rewardPhaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(rsp.activity_sub_id)
  if rewardPhaseConf then
    local lastDigit = rsp.activity_sub_id % 10
    self.Text_Title:SetText(string.format("%02d", lastDigit))
    self.Text_Title2:SetText(rewardPhaseConf.name)
  end
  self.rewardInfo = rsp
  self:SetRewardDetail()
  self:PlayAnimation(self.In)
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnDeactive()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnAddEventListener()
  self:AddButtonListener(self.PhotoButton, self.OnClickPhoto)
  self:AddButtonListener(self.BtnReceiveReward.btnLevelUp, self.OnClickReceiveReward)
  self:AddButtonListener(self.ClickCloseBtn, self.OnClickClose)
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnConstruct()
  self:SetChildViews(self.ActivityPhotoFile)
  self:OnAddEventListener()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnDestruct()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:SetRewardDetail()
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if takePhotoActivityInst and takePhotoActivityInst[1] then
    local submission = takePhotoActivityInst[1]:GetMySubmission(self.rewardInfo.activity_sub_id)
    if submission then
      self.ActivityPhotoFile:DisplayFixedFramePhotoMiniMode(submission.mini_photo_url, submission.mini_photo_md5)
      local contentStr = ""
      if self.rewardInfo.rank_no and self.rewardInfo.rank_no > 0 then
        contentStr = string.format(LuaText.pic_game_submit_receive_award_rank, submission.total_hot_count, self.rewardInfo.rank_no)
      elseif self.rewardInfo.estimated and self.rewardInfo.estimated.rank and self.rewardInfo.estimated.total_count then
        local percentValue = self:CalculateRankPercentage(self.rewardInfo.estimated.rank, self.rewardInfo.estimated.total_count)
        contentStr = string.format(LuaText.pic_game_submit_receive_award_percent, submission.total_hot_count, percentValue .. "%")
      end
      local rewardConf = _G.DataConfigManager:GetRewardConf(self.rewardInfo.reward_id)
      local hasReturnReward = false
      if rewardConf then
        local rewards = rewardConf.RewardItem
        local itemList = {}
        local returnItemList = {}
        for i = 1, #rewards do
          local hasCollected, returnGoodsType, returnGoodsId, returnGoodsNum = self:CheckRepeatedCollection(rewards[i].Type, rewards[i].Id)
          if hasCollected then
            hasReturnReward = true
            local returnRewardQuality
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(returnGoodsId)
            if bagItemConf then
              returnRewardQuality = bagItemConf.item_quality
            end
            table.insert(returnItemList, {
              itemType = returnGoodsType,
              itemId = returnGoodsId,
              itemNum = returnGoodsNum,
              bShowNum = true,
              bConverted = false,
              itemQuality = returnRewardQuality
            })
          end
          local rewardQuality
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewards[i].Id)
          if bagItemConf then
            rewardQuality = bagItemConf.item_quality
          end
          table.insert(itemList, {
            itemType = rewards[i].Type,
            itemId = rewards[i].Id,
            itemNum = rewards[i].Count,
            bShowNum = true,
            bConverted = hasCollected,
            itemQuality = rewardQuality,
            index = i
          })
        end
        if #returnItemList > 0 then
          for i = 1, #returnItemList do
            returnItemList[i].index = i + #itemList
            table.insert(itemList, returnItemList[i])
          end
        end
        table.sort(itemList, function(a, b)
          if a.itemQuality == b.itemQuality then
            return a.index < b.index
          else
            return a.itemQuality > b.itemQuality
          end
        end)
        self.NRCGridView_Reward:InitGridView(itemList)
      end
      if hasReturnReward then
        contentStr = string.format([[
%s
%s]], contentStr, LuaText.pic_game_return_text)
      end
      self.ContentText:SetText(contentStr)
      self.submission = submission
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:CheckRepeatedCollection(itemType, itemId)
  if itemType == Enum.GoodsType.GT_BAGITEM and allGoodsReturnConf then
    for confId, v in pairs(allGoodsReturnConf) do
      local returnConf = v
      if itemId == returnConf.bagitem_id then
        if returnConf.need_goods_type == Enum.GoodsType.GT_CARD_ICON then
          local HasCardIcon = _G.NRCModuleManager:DoCmd(FriendModuleCmd.HasCardIcon, returnConf.need_goods_id)
          return HasCardIcon, returnConf.return_goods_type, returnConf.return_goods_id, returnConf.return_num
        end
        if returnConf.need_goods_type == Enum.GoodsType.GT_CARD_SKIN then
          local HasCardSkin = _G.NRCModuleManager:DoCmd(FriendModuleCmd.HasCardSkin, returnConf.need_goods_id)
          return HasCardSkin, returnConf.return_goods_type, returnConf.return_goods_id, returnConf.return_num
        end
      end
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:CalculateRankPercentage(currentRank, totalCount)
  if totalCount <= 0 then
    return 100
  end
  if currentRank <= 0 then
    return 100
  end
  if totalCount < currentRank then
    return 100
  end
  local percentage = currentRank / totalCount * 100
  return math.ceil(percentage)
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickPhoto()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickPhoto")
  local activityInst
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if takePhotoActivityInst then
    activityInst = takePhotoActivityInst[1]
  end
  if nil == activityInst then
    Log.Info("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickPhoto activityInst is nil")
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
  if activityInst and activityInst:IsActivityInactive() then
    Log.Info("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickPhoto activityInactive")
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
  if self.submission then
    local bigPhotoData = {}
    bigPhotoData.bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.RewardPhoto
    bigPhotoData.sourcePhoto = self.ActivityPhotoFile
    bigPhotoData.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    bigPhotoData.photo_url = self.submission.photo_url
    bigPhotoData.photo_md5 = self.submission.photo_md5
    bigPhotoData.mini_photo_url = self.submission.mini_photo_url
    bigPhotoData.mini_photo_md5 = self.submission.mini_photo_md5
    bigPhotoData.hot_value = self.submission.total_hot_count
    bigPhotoData.activity_sub_id = self.rewardInfo.activity_sub_id
    _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, bigPhotoData)
  end
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickReceiveReward()
  if not self.bShowedReward then
    return
  end
  local activityInst
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if takePhotoActivityInst then
    activityInst = takePhotoActivityInst[1]
  end
  if nil == activityInst then
    Log.Info("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickReceiveReward activityInst is nil")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_expired_tips)
    self:OnClickClose()
    return
  end
  if activityInst and activityInst:IsActivityInactive() then
    Log.Info("UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickReceiveReward activityInactive")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_expired_tips)
    self:OnClickClose()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdTakeReward, self.rewardInfo.activity_id, self.rewardInfo.activity_sub_id, {1, 2}, function(bSuccess)
    if bSuccess then
      self.ClickCloseBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnReceiveReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end, true)
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnClickClose()
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  self:PlayAnimation(self.Out)
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoClose()
  end
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  if self.bShowedReward then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  self.isDragging = true
  self.startDragPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  self.tearingAnimDuration = self.Tearing:GetEndTime() - self.Tearing:GetStartTime()
  local viewPortSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  self.maxDragDistance = viewPortSize.X / 3
  if not self.dragDistance or self.dragDistance <= 0 then
    self.dragDistance = 0
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnTouchMoved(_MyGeometry, _InTouchEvent)
  if not self.isDragging or not self.startDragPosition then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local currentPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
  if currentPosition.X > self.startDragPosition.X then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  self.dragDistance = self.startDragPosition.X - currentPosition.X
  if 0 == self.dragDistance then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local frame = math.floor(self.dragDistance / self.maxDragDistance * 60)
  frame = math.max(0, math.min(60, frame))
  if frame ~= self.currentFrame then
    local startFrame = self.currentFrame or 0
    self:PlayAnimationAtFrame(startFrame, frame)
    self.currentFrame = frame
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self.isDragging = false
  self.startDragPosition = nil
  self.currentFrame = nil
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_TakePhotoCompetition_RaffleTicket_C:PlayAnimationAtFrame(oldFrame, newFrame)
  if 60 == newFrame then
    self.Border_Tear:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ClickCloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    _G.NRCAudioManager:PlaySound2DAuto(40004003, "UMG_Activity_TakePhotoCompetition_RaffleTicket_C:PlayAnimationAtFrame")
    self:PlayAnimation(self.Reward)
    self.bShowedReward = true
    return
  end
  local beginTime = oldFrame / 60 * self.tearingAnimDuration
  local endTime = newFrame / 60 * self.tearingAnimDuration
  self:PlayAnimationTimeRange(self.Tearing, beginTime, endTime, 1, UE4.EUMGSequencePlayMode.Forward, 1, false)
end

return UMG_Activity_TakePhotoCompetition_RaffleTicket_C
