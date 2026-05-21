local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local UMG_ClaimReward_C = _G.NRCPanelBase:Extend("UMG_ClaimReward_C")

function UMG_ClaimReward_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_ClaimReward_C:OnActive(rewardList, bInActivity)
  self:OnAddEventListener()
  self:_InitEventActivityObject()
  self.bInActivity = bInActivity
  self.PhotoReward = self:_GetPhotoReward(rewardList)
  self.RewardList = self:_GetStarRewardWithoutPhoto(rewardList)
  self:_InitPanel()
  self:LoadAnimation(0)
end

function UMG_ClaimReward_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_ClaimReward_C:OnAddEventListener()
  local commonPopUpData = _G.NRCCommonPopUpData()
  commonPopUpData.Call = self
  commonPopUpData.ClosePanelHandler = self.OnPanelClose
  self.PopUp:SetPanelInfo(commonPopUpData)
  if self.Btn6 then
    self:AddButtonListener(self.Btn6.btnLevelUp, self.OnReceiveAllRewardButtonClick)
  end
  self:AddButtonListener(self.ViewBtn.btnLevelUp, self.OnGoToPhotoButtonClicked)
  self:RegisterEvent(self, WeeklyChallengeBattleModuleEvent.ReceiveRewardSuccess, self.OnReceiveRewardSuccessfully)
end

function UMG_ClaimReward_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.ReceiveRewardSuccess)
end

function UMG_ClaimReward_C:OnReceiveAllRewardButtonClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClaimReward_C:OnReceiveAllRewardButtonClick")
  self:TryReceiveAllReward()
end

function UMG_ClaimReward_C:OnPcClose()
  self:OnPanelClose()
end

function UMG_ClaimReward_C:OnReceiveRewardSuccessfully(activityId, starRequiredNum, activityType)
  self.WeeklyChallengeEventActivityObject[1]:SetRewardState(starRequiredNum)
  local item
  for i, reward in ipairs(self.RewardList) do
    if starRequiredNum == reward.star_required_num then
      reward.state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
      local Item = self.DailyItems:GetItemByIndex(i - 1)
      if Item then
        Item:UpdateReceiveAwardState(reward)
        item = Item
        break
      end
    end
  end
  if self.PhotoReward and self.PhotoReward.star_required_num == starRequiredNum then
    self.PhotoReward.state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
  end
  self:ProceedNextReceiveRewardReq()
  if (not (self.startIndex and self.needToSendReqList) or 0 == #self.needToSendReqList) and item then
    local itemInfos = {}
    local rewards = item.RewardList
    if rewards then
      for _, v1 in ipairs(rewards) do
        local index = 0
        for k2, v2 in ipairs(itemInfos) do
          if v2.itemId == v1.itemId then
            index = k2
            break
          end
        end
        local itemId = v1.itemId
        local itemText = v1.itemNum
        if 0 == index then
          table.insert(itemInfos, {
            itemId = itemId,
            itemText = itemText,
            id = itemId,
            num = v1.itemNum,
            type = v1.itemType
          })
        else
          itemInfos[index].num = itemInfos[index].num + v1.itemNum
        end
      end
    end
    if #itemInfos > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
    end
    self.RewardList = self:_GetStarRewardWithoutPhoto(self.RewardList)
    self:_InitPanel()
    self:UpdateReceiveAllRewardButton(self.RewardList)
  end
end

function UMG_ClaimReward_C:_InitEventActivityObject()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    self.challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
    return
  end
  Log.Error("UMG_ClaimReward_C:_InitEventActivityObject \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
end

function UMG_ClaimReward_C:_InitPanel()
  self:_InitRewardList()
  self:_InitPhotoReward()
end

function UMG_ClaimReward_C:_InitRewardList()
  if not self.RewardList or 0 == #self.RewardList then
    return
  end
  self.DailyItems:InitList(self.RewardList)
  for i = 0, self.DailyItems:GetItemCount() - 1 do
    local item = self.DailyItems:GetItemByIndex(i)
    if item then
      item:SetParent(self)
    end
  end
  self:UpdateReceiveAllRewardButton(self.RewardList)
end

function UMG_ClaimReward_C:_InitPhotoReward()
  if not self.PhotoReward then
    return
  end
  self.Text_Content_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Text_Content:SetText(string.format(_G.LuaText.weekly_challenge_text_22, self.PhotoReward.star_required_num))
  self.NRCText:SetText(string.format("x%s", self.PhotoReward.difficultyRequire))
  self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local data = self.PhotoReward
  if data.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT or data.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT or data.finishedStarNum >= data.star_required_num then
    self.Switcher:SetActiveWidgetIndex(0)
    self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if data.bIsTakingPhoto then
      self.ViewBtn.Title_1:SetText(_G.LuaText.weekly_challenge_text_21)
    end
  elseif data.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
    self.Switcher:SetActiveWidgetIndex(1)
  elseif data.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN then
    self.Switcher:SetActiveWidgetIndex(3)
    local worldLevelConf = _G.DataConfigManager:GetWorldLevelConf(data.difficultyRequire + 1, true)
    if worldLevelConf then
      self.Quantity:SetText(string.format(_G.LuaText.weekly_challenge_text_29, worldLevelConf.title))
    end
  end
  self.Quantity_1:SetText(string.format("%d/%d", data.finishedStarNum, data.star_required_num))
end

function UMG_ClaimReward_C:OnPanelClose()
  self:LoadAnimation(2)
end

function UMG_ClaimReward_C:_GetPhotoReward(primalList)
  for k, v in ipairs(primalList) do
    if v.bIsTakingPhoto then
      return v
    end
  end
  return nil
end

function UMG_ClaimReward_C:_GetStarRewardWithoutPhoto(primalList)
  local listWithoutPhoto = {}
  for k, v in ipairs(primalList) do
    if not v.bIsTakingPhoto then
      table.insert(listWithoutPhoto, v)
    end
  end
  table.sort(listWithoutPhoto, function(a, b)
    local stateOrder = {
      [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT] = 1,
      [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH] = 2,
      [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN] = 3,
      [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE] = 4
    }
    local stateA_value = stateOrder[a.state] or 9999
    local stateB_value = stateOrder[b.state] or 9999
    if stateA_value ~= stateB_value then
      return stateA_value < stateB_value
    end
    return a.star_required_num < b.star_required_num
  end)
  return listWithoutPhoto
end

function UMG_ClaimReward_C:TryReceiveAllReward()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_ClearanceReward_Item_C:OnReceiveAwar \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetActivityId()
  self.needToSendReqList = {}
  for i = 0, self.DailyItems:GetItemCount() - 1 do
    local item = self.DailyItems:GetItemByIndex(i)
    if item and not item.data.bIsTakingPhoto and item.data.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
      table.insert(self.needToSendReqList, {
        activityId = activityId,
        starNum = item.data.star_required_num,
        rewardList = item.RewardList
      })
    end
  end
  if #self.needToSendReqList <= 0 then
    return
  end
  self.startIndex = 1
  local req = self.needToSendReqList[self.startIndex]
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendReceiveRewardReq, req.activityId, req.starNum, self.RewardList, ProtoEnum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
end

function UMG_ClaimReward_C:ProceedNextReceiveRewardReq()
  if not (self.startIndex and self.needToSendReqList) or 0 == #self.needToSendReqList then
    return
  end
  self.startIndex = self.startIndex + 1
  if self.startIndex > #self.needToSendReqList then
    local itemInfos = {}
    for k, v in ipairs(self.needToSendReqList) do
      local rewards = v.rewardList
      for _, v1 in ipairs(rewards) do
        local index = 0
        for k2, v2 in ipairs(itemInfos) do
          if v2.itemId == v1.itemId then
            index = k2
            break
          end
        end
        local itemId = v1.itemId
        local itemText = v1.itemNum
        if 0 == index then
          table.insert(itemInfos, {
            itemId = itemId,
            itemText = itemText,
            id = itemId,
            num = v1.itemNum,
            type = v1.itemType
          })
        else
          itemInfos[index].num = itemInfos[index].num + v1.itemNum
        end
      end
    end
    if #itemInfos > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
    end
    self.needToSendReqList = {}
    self.startIndex = 1
    self.RewardList = self:_GetStarRewardWithoutPhoto(self.RewardList)
    self:_InitPanel()
    self:UpdateReceiveAllRewardButton(self.RewardList)
    return
  end
  local req = self.needToSendReqList[self.startIndex]
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendReceiveRewardReq, req.activityId, req.starNum, self.RewardList, ProtoEnum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
end

function UMG_ClaimReward_C:UpdateReceiveAllRewardButton(rewardList)
  local bHasReceivableReward = false
  for k, v in ipairs(rewardList) do
    if v.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT and not v.bIsTakingPhoto then
      bHasReceivableReward = true
    end
  end
  if self.Btn6 then
    if bHasReceivableReward then
      self.Btn6:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Btn6:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ClaimReward_C:OnGoToPhotoButtonClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClearanceReward_Item_C:OnReceiveAward")
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_ClearanceReward_Item_C:OnReceiveAward \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetActivityId()
  if self.bInActivity then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenCurtainPopup, self, self.OnGoToTakingPhoto)
  else
    local WorldMapConfId = 700002
    local NpcData = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetNpcDataByWorldMapConfId, WorldMapConfId)
    if NpcData then
      local bBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, _G.Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
      if bBan then
        return
      end
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendWorldMapTeleportReq, NpcData.entry_id)
      _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.TeleportChallenge, WorldMapConfId, true)
    else
      Log.Warning("\230\178\161\230\156\137NpcData\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    end
  end
  if self.PhotoReward.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendReceiveRewardReq, activityId, self.PhotoReward.star_required_num, self.PhotoReward, ProtoEnum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  end
end

function UMG_ClaimReward_C:OnGoToTakingPhoto()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GoTakePhoto)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseCurtainPopup)
end

function UMG_ClaimReward_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_ClaimReward_C
