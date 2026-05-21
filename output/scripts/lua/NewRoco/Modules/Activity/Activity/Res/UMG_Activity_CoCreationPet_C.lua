local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_CoCreationPet_C = Base:Extend("UMG_Activity_CoCreationPet_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_CoCreationPet_C:BindUIElements()
  local uiElements = {}
  if self.activityInst.bStart then
    uiElements.desireActivityType = Enum.ActivityType.ATP_PLAYER_CO_CREATION_START
  else
    uiElements.desireActivityType = Enum.ActivityType.ATP_PLAYER_CO_CREATION_PREVIEW
  end
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.bgImage = self.MythicalCreaturesBG
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.closeAnimName = "Out"
  return uiElements
end

function UMG_Activity_CoCreationPet_C:OnConstruct()
  Base.OnConstruct(self)
  local _activityInst = self.activityInst
  self.Text_IssueNumber:SetText(_activityInst:GetActivityNumTitle())
  local petBaseId = _activityInst:GetPetBaseId()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  self.TextName:SetText(petBaseConf.name)
  local typeData = {}
  for _, type in ipairs(petBaseConf.unit_type) do
    table.insert(typeData, {Type = type, ShowTips = true})
  end
  self.Attr:InitGridView(typeData)
  self.DrawImagle:SetPath(_activityInst:GetPetImagePath())
  local curWorldLv = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local requireLevel = self.activityInst:GetWorldLevelRequired()
  if curWorldLv < requireLevel then
    self.BtnSearchPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_EventReview:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NotUnlocked:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local targetStr = _G.DataConfigManager:GetWorldLevelConf(requireLevel + 1).title
    self.Text_hint:SetText(string.format(_G.LuaText.activity_wolrd_level_low, targetStr))
  else
    if not _activityInst.bStart then
      self.BtnSearchPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Btn_EventReview:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Btn_EventReview_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.NotUnlocked:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local fruit_reward_id = _activityInst:GetFruitRewardId()
  local rewardConf = _G.DataConfigManager:GetRewardConf(fruit_reward_id).RewardItem[1]
  local rewardData = {
    {
      itemType = rewardConf.Type,
      itemId = rewardConf.Id,
      itemNum = rewardConf.Count,
      Key = 215,
      extraKey = _activityInst:GetActivityId()
    }
  }
  self.AwardList:InitList(rewardData)
  if _activityInst.bStart then
    local base_id = _activityInst:GetSinglePartId()
    local task_id = _G.DataConfigManager:GetActivityPlayerCoCreation(base_id).fruit_task_id
    local petNum = 0
    local taskConf = _G.DataConfigManager:GetTaskConf(task_id)
    local title = taskConf.name
    local targetNum = taskConf.task_condition[1].count
    local progress = string.format(_G.DataConfigManager:GetLocalizationConf("Activity_PlayerCoCreation_task").msg, petNum, targetNum)
    self.NRCText1:SetText(title .. " " .. progress)
    local req = _G.ProtoMessage:newZoneTaskQueryReq()
    req.task_list = {task_id}
    req.task_state = 0
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.InitPetNum, false, true)
    self.NRCSwitcher_bg:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_bg:SetActiveWidgetIndex(1)
    self.RewardsPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BasicInformation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:OnAddEventListener()
  self.Btn_EventReview:SetRedDotKey(465)
end

function UMG_Activity_CoCreationPet_C:InitPetNum(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local petNum = rsp.task_info_list and rsp.task_info_list[1].task_target_list[1] or 0
    local task_id = _G.DataConfigManager:GetActivityPlayerCoCreation(self.activityInst:GetSinglePartId()).fruit_task_id
    local taskConf = _G.DataConfigManager:GetTaskConf(task_id)
    local title = taskConf.name
    local targetNum = taskConf.task_condition[1].count
    local progress = string.format(_G.DataConfigManager:GetLocalizationConf("Activity_PlayerCoCreation_task").msg, petNum, targetNum)
    self.NRCText1:SetText(title .. " " .. progress)
    if self.activityInst.co_creation_data.co_creation_data.task_reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
      self.ClaimBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    elseif self.activityInst.co_creation_data.co_creation_data.task_reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
      for i = 0, self.AwardList:GetItemCount() - 1 do
        local item = self.AwardList:GetItemByIndex(i)
        item:SetAlreadyReceived(true)
        item:PlayAnimation(item.Receive, item.Receive:GetEndTime() - 0.01)
      end
    end
  end
end

function UMG_Activity_CoCreationPet_C:OpenDetailPanel()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.activityInst:GetPetBaseId(), true)
end

function UMG_Activity_CoCreationPet_C:findPet()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  ActivityUtils.RequestTracePet(self.activityInst:GetTrackPetId(), self.activityInst)
end

function UMG_Activity_CoCreationPet_C:OpenReviewPanel()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenActivityReview, self.activityInst.co_creation_data)
end

function UMG_Activity_CoCreationPet_C:GetFruit()
  if self.bWaitGetFruit then
    return
  end
  local req = _G.ProtoMessage:newZoneReceiveActivityCoCreationRewardReq()
  req.activity_id = self.activityInst:GetActivityId()
  req.is_task_reward = true
  self.bWaitGetFruit = true
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_ACTIVITY_CO_CREATION_REWARD_REQ, req, self, self.OnGetFruit, false, true)
end

function UMG_Activity_CoCreationPet_C:OnGetFruit(rsp)
  self.bWaitGetFruit = false
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self.ClaimBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local fruit_reward_id = self.activityInst:GetFruitRewardId()
    local rewardConf = _G.DataConfigManager:GetRewardConf(fruit_reward_id).RewardItem[1]
    local popupInitData = {
      {
        id = rewardConf.Id,
        type = rewardConf.Type,
        num = rewardConf.Count
      }
    }
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
    for i = 0, self.AwardList:GetItemCount() - 1 do
      local item = self.AwardList:GetItemByIndex(i)
      item:SetAlreadyReceived(true)
      item:PlayAnimation(item.Receive)
    end
  end
end

function UMG_Activity_CoCreationPet_C:OnAddEventListener()
  self:AddButtonListener(self.ExamineBtn, self.OpenDetailPanel)
  self:AddButtonListener(self.BtnSearchPet.btnLevelUp, self.findPet)
  self:AddButtonListener(self.Btn_EventReview.btnLevelUp, self.OpenReviewPanel)
  self:AddButtonListener(self.Btn_EventReview_1.btnLevelUp, self.OpenReviewPanel)
  self:AddButtonListener(self.ClaimBtn, self.GetFruit)
end

function UMG_Activity_CoCreationPet_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.ExamineBtn)
  self:RemoveButtonListener(self.BtnSearchPet.btnLevelUp)
  self:RemoveButtonListener(self.Btn_EventReview.btnLevelUp)
  self:RemoveButtonListener(self.Btn_EventReview_1.btnLevelUp)
  self:RemoveButtonListener(self.ClaimBtn)
end

function UMG_Activity_CoCreationPet_C:OnDestruct()
  self:OnRemoveEventListener()
end

return UMG_Activity_CoCreationPet_C
