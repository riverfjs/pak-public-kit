local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local UMG_Task_ReturnReward_C = _G.NRCPanelBase:Extend("UMG_Task_ReturnReward_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Task_ReturnReward_C:OnActive()
  local mainObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  local is_disposable_reward_taken
  if mainObjects and #mainObjects > 0 then
    for _, object in ipairs(mainObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        self.recallActivity = object
        self.bNewRecall = true
        is_disposable_reward_taken = recall_data.is_disposable_reward_taken
        break
      end
    end
  end
  local curModule = self.module
  self.tipsDisplayController = curModule and curModule.getReturnRewardTipsController
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008044, "UMG_Task_ReturnReward_C:OnActive")
  self.isCollect = false
  self.bNormalClose = false
  self.rewardList = {}
  self:SetInfo()
  self:OnAddEventListener()
  self:PlayAnimation(self.In)
  self:AddPcInputBlock()
  UE4Helper.SetDesiredShowCursor(true, "UMG_Task_ReturnReward_C")
  if is_disposable_reward_taken then
    for i = 1, self.AwardList:GetItemCount() do
      local item = self.AwardList:GetItemByIndex(i - 1)
      item:SetAlreadyReceived(true)
      item.NRCImage_1:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#00000066"))
    end
    self:PlayAnimation(self.Receive)
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Visible)
    self.isCollect = true
    self.CanvasPanel_52:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Task_ReturnReward_C:OnDeactive()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
  self:RemovePcInputBlock()
  UE4Helper.ReleaseDesiredShowCursor("UMG_Task_ReturnReward_C")
end

function UMG_Task_ReturnReward_C:SetInfo()
  if self.bNewRecall then
    local recall_class = self.recallActivity:GetActivityData().recall_class
    local reward_id = _G.DataConfigManager:GetActivityRecallClassConf(recall_class).disposable_reward_id
    local rewardConf = _G.DataConfigManager:GetRewardConf(reward_id)
    self.rewardList = self:SetRewards(rewardConf.RewardItem)
    self.TextDescribe:SetText(_G.LuaText.recall_s2letter_text)
    self.BtnLeaveFor:SetBtnText(_G.LuaText.recall_s2letter_button_text)
  else
    local recallEventConf = _G.DataConfigManager:GetActivityConf(15)
    local activityConf = _G.DataConfigManager:GetActivityRewardByStageConf(recallEventConf.base_id[1])
    local disposable_reward_id = activityConf.disposable_reward_id
    local rewardConf = _G.DataConfigManager:GetRewardConf(disposable_reward_id)
    self.rewardList = self:SetRewards(rewardConf.RewardItem)
    local recallText = _G.DataConfigManager:GetLocalizationConf("Recall_Postcard_Text").msg
    if recallText then
      self.TextDescribe:SetText(recallText)
    end
  end
  self.AwardList:InitGridView(self.rewardList)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TextName:SetText(LuaText.recall_mail_sender)
end

function UMG_Task_ReturnReward_C:PlayInAnim()
  if self._playInAnimTimerId then
    _G.DelayManager:CancelDelayById(self._playInAnimTimerId)
    self._playInAnimTimerId = nil
  end
  self:SetRenderOpacity(0)
  self._playInAnimTimerId = _G.DelayManager:DelaySeconds(1, function()
    self._playInAnimTimerId = nil
    self:SetRenderOpacity(1)
    self:PlayAnimation(self.In)
  end)
end

function UMG_Task_ReturnReward_C:SetRewards(itemInfo)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.itemNum = v.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

function UMG_Task_ReturnReward_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_Task_ReturnReward_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_Task_ReturnReward_C:OnAddEventListener()
  NRCEventCenter:RegisterEvent("UMG_Task_ReturnReward_C", self, SceneEvent.OnRelogin, self.OnReLogin)
  self:AddButtonListener(self.CollectButton, self.CollectReward)
  self:AddButtonListener(self.BtnLeaveFor.btnLevelUp, self.GoToRecallEventInActivityPanel)
end

function UMG_Task_ReturnReward_C:OnReLogin()
  self.isCollect = false
end

function UMG_Task_ReturnReward_C:CollectReward()
  if _G.GlobalConfig.DebugOpenUI then
    self.tipsDisplayController:GetExecutor():Clear()
    self:OnClose()
    return
  end
  if not self.isCollect then
    if self.bNewRecall then
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityDisposableRewardReq()
      req.activity_id = self.recallActivity:GetActivityId()
      req.activity_stage_id = self.recallActivity:GetSinglePartId()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_DISPOSABLE_REWARD_REQ, req, self, self.GetRecallReward, true, true)
    else
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityDisposableRewardReq()
      local recallEventConf = _G.DataConfigManager:GetActivityConf(15)
      req.activity_id = recallEventConf.id
      req.activity_stage_id = recallEventConf.base_id[1]
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_DISPOSABLE_REWARD_REQ, req, self, self.OnZoneGetPlayerActivityInfoRsp, true, true)
    end
  end
end

function UMG_Task_ReturnReward_C:GetRecallReward(rsp)
  if 0 == rsp.ret_info.ret_code then
    local recall_class = self.recallActivity:GetActivityData().recall_class
    local reward_id = _G.DataConfigManager:GetActivityRecallClassConf(recall_class).disposable_reward_id
    local rewardData = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem
    local popupInitData = {}
    for i = 1, #rewardData do
      local popupData = _G.ProtoMessage:newGoodsItem()
      popupData.id = rewardData[i].Id
      popupData.num = rewardData[i].Count
      popupData.type = rewardData[i].Type
      table.insert(popupInitData, popupData)
    end
    local commonPopUpData = _G.NRCCommonPopUpData()
    commonPopUpData.Call = self
    commonPopUpData.ClosePanelHandler = self.FinishReward
    commonPopUpData.HideBtn = true
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData, nil, nil, nil, nil, nil, nil, commonPopUpData)
    for i = 1, self.AwardList:GetItemCount() do
      local item = self.AwardList:GetItemByIndex(i - 1)
      item:SetAlreadyReceived(true)
      item.NRCImage_1:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#00000066"))
    end
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ACTIVITY_REWARD_HAS_BEEN_RECEIVED then
    for i = 1, self.AwardList:GetItemCount() do
      local item = self.AwardList:GetItemByIndex(i - 1)
      item:SetAlreadyReceived(true)
      item.NRCImage_1:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#00000066"))
    end
    self:FinishReward()
  end
end

function UMG_Task_ReturnReward_C:FinishReward()
  self:PlayAnimation(self.Receive)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Visible)
  self.isCollect = true
  self.CanvasPanel_52:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Task_ReturnReward_C:OnZoneGetPlayerActivityInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:PlayAnimation(self.Receive)
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Visible)
    self.isCollect = true
    self.CanvasPanel_52:SetVisibility(UE4.ESlateVisibility.Collapsed)
    for i = 1, self.AwardList:GetItemCount() do
      local item = self.AwardList:GetItemByIndex(i - 1)
      item:SetAlreadyReceived(true)
      item.NRCImage_1:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#00000066"))
    end
  else
    self:ReqGetPlayerActivityData(true)
  end
end

function UMG_Task_ReturnReward_C:GoToRecallEventInActivityPanel()
  if not self.bNewRecall then
    self:ReqGetPlayerActivityData()
  end
  self:PlayAnimation(self.Out)
end

function UMG_Task_ReturnReward_C:ClosePanel()
  self.tipsDisplayController:GetExecutor():Clear()
  self:DoClose()
end

function UMG_Task_ReturnReward_C:OnAnimationFinished(anim)
  if anim == self.Out then
    if self.bNewRecall then
      local req = _G.ProtoMessage:newZoneGetActivityOptionalPetsReq()
      req.activity_id = self.recallActivity:GetActivityId()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_ACTIVITY_OPTIONAL_PETS_REQ, req, self, self.OpenPetPanel)
    else
      if not self.bNormalClose then
        _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenMainPanel, nil, 15)
      end
      self:ClosePanel()
    end
  end
end

function UMG_Task_ReturnReward_C:OpenPetPanel(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.optional_pets_id then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenBackflowPetSelect, rsp.optional_pets_id, self.recallActivity:GetActivityId())
    self:ClosePanel()
  end
end

function UMG_Task_ReturnReward_C:ReqGetPlayerActivityData(bNeedRsp)
  local recallEventConf = _G.DataConfigManager:GetActivityConf(15)
  local req = _G.ProtoMessage:newZoneGetPlayerActivityDataReq()
  req.activity_id = recallEventConf.id
  if bNeedRsp then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_REQ, req, self, self.GetPlayerActivityDataRsp, false, false)
  else
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_REQ, req)
  end
end

function UMG_Task_ReturnReward_C:GetPlayerActivityDataRsp(rsp)
  local stageData = rsp.activity_data and rsp.activity_data.stage_data
  local subStageData = stageData.sub_stage_data and stageData.sub_stage_data[1]
  local isActive = false
  local isRewardTaken = false
  if subStageData then
    isActive = subStageData.active
    isRewardTaken = subStageData.is_disposable_reward_taken
  end
  if not isActive then
    self.bNormalClose = true
    if self and UE4.UObject.IsValid(self) and self.Out then
      self:PlayAnimation(self.Out)
    end
  end
  if isRewardTaken and self and UE4.UObject.IsValid(self) then
    self.bNormalClose = true
    self:PlayAnimation(self.Out)
  end
end

function UMG_Task_ReturnReward_C:OnDestruct()
  if self._playInAnimTimerId then
    _G.DelayManager:CancelDelayById(self._playInAnimTimerId)
    self._playInAnimTimerId = nil
  end
end

return UMG_Task_ReturnReward_C
