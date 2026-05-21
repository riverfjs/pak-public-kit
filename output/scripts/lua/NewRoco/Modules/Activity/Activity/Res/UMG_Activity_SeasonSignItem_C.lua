local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local UMG_Activity_SeasonSignItem_C = Base:Extend("UMG_Activity_SeasonSignItem_C")

function UMG_Activity_SeasonSignItem_C:OnConstruct()
  self:AddButtonListener(self.ButtonClick, self.BtnClick)
  self:AddButtonListener(self.IconButton, self.IconClick)
end

function UMG_Activity_SeasonSignItem_C:OnDestruct()
end

function UMG_Activity_SeasonSignItem_C:IconClick()
  _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.RewardId, self.RewardType)
end

function UMG_Activity_SeasonSignItem_C:BtnClick()
  if self.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_PetSurveyItem_C:BtnClick")
    local req = _G.ProtoMessage:newZoneReceivePlayerActivityConditionRewardReq()
    req.activity_id = self.activityId
    req.activity_part_id = self.activity_part_id
    ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_CONDITION_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityConditionRewardRsp)
  end
  if not self.state or self.state < ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_PetSurveyItem_C:BtnClick")
    MagicManualUtils.TaskTraceByGoGuide(self.go_guide)
  end
end

function UMG_Activity_SeasonSignItem_C:OnZoneReceivePlayerActivityConditionRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _req.activity_part_id ~= self.activity_part_id then
    return
  end
  local rewardsList = {}
  if self.RewardType == Enum.GoodsType.GT_BAGITEM then
    local item_conf = _G.DataConfigManager:GetBagItemConf(self.RewardId)
    if item_conf then
      local rewardsItemData = {}
      rewardsItemData.type = Enum.GoodsType.GT_BAGITEM
      rewardsItemData.id = item_conf.id
      rewardsItemData.num = self.ConditionRewardCount or 1
      table.insert(rewardsList, rewardsItemData)
    end
  elseif self.RewardType == Enum.GoodsType.GT_VITEM then
    local item_conf = _G.DataConfigManager:GetVisualItemConf(self.RewardId)
    if item_conf then
      local rewardsItemData = {}
      rewardsItemData.type = Enum.GoodsType.GT_VITEM
      rewardsItemData.id = item_conf.id
      rewardsItemData.num = self.ConditionRewardCount or 1
      table.insert(rewardsList, rewardsItemData)
    end
  elseif self.RewardType == Enum.GoodsType.GT_REWARD then
    local RewardConf = _G.DataConfigManager:GetRewardConf(self.RewardId)
    local rewardsGroup = RewardConf.RewardItem
    local ConditionRewardConf = _G.DataConfigManager:GetActivityConditionRewardConf(self.activity_part_id)
    local taskId = ConditionRewardConf and ConditionRewardConf.condition_group[1] and ConditionRewardConf.condition_group[1].condition_param
    for _, rewardItem in ipairs(rewardsGroup) do
      local rewardsItemData = {}
      rewardsItemData.type = rewardItem.Type
      rewardsItemData.id = rewardItem.Id
      rewardsItemData.num = rewardItem.Count * self.ConditionRewardCount or 1
      table.insert(rewardsList, rewardsItemData)
    end
  end
  local req = _G.ProtoMessage:newZoneGetPlayerActivityDataReq()
  req.activity_id = self.activityId
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_REQ, req)
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardsList, "")
end

function UMG_Activity_SeasonSignItem_C:OnItemUpdate(Data, datalist, index)
  local _data = Data.data
  self.uiData = _data
  self.activity_part_id = _data.activity_part_id
  self.state = _data.state
  self.activityId = Data.activityId
  self:SetInfo()
end

function UMG_Activity_SeasonSignItem_C:SetInfo()
  self:StopAllAnimations()
  local ConditionRewardConf = _G.DataConfigManager:GetActivityConditionRewardConf(self.activity_part_id)
  local taskId = ConditionRewardConf and ConditionRewardConf.condition_group[1] and ConditionRewardConf.condition_group[1].condition_param
  local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
  self.TaskInfo = NRCModuleManager:DoCmd(TaskModuleCmd.getTaskByID, taskId)
  self.taskConf = taskConf
  if not taskConf then
    Log.Error(taskId, "Not TaskConf")
    return
  end
  local RewardId = ConditionRewardConf and ConditionRewardConf.reward_group[1] and ConditionRewardConf.reward_group[1].goods_id
  local RewardType = ConditionRewardConf and ConditionRewardConf.reward_group[1] and ConditionRewardConf.reward_group[1].goods_type
  if self.TaskInfo then
    local targetNum = taskConf.task_condition[1].count
    local targetText = self.TaskInfo.task_target_list[1] .. "/" .. targetNum
    self.Desc:SetText(string.format("%s (%s)", taskConf.name, targetText))
    if not self.state or self.state < ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
      self.go_guide = nil
      for i, v in pairs(taskConf.go_guide) do
        if v.type and v.type == Enum.TaskGoActionType.TGAT_UI and v.text then
          self.go_guide = v
        end
      end
      if self.go_guide then
        self.BtnText:SetText(LuaText.head_to)
      else
        self.BtnText:SetText(LuaText.task_in_progress)
      end
      self.Switcher:SetActiveWidgetIndex(0)
      self.NRCImage_Get:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
      self.Switcher:SetActiveWidgetIndex(2)
      self.NRCImage_Get:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
      self.Switcher:SetActiveWidgetIndex(1)
      self.NRCImage_Get:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Available, 0, 99999)
    end
  else
    local targetNum = taskConf.task_condition[1].count
    local targetText = targetNum .. "/" .. targetNum
    self.Desc:SetText(string.format("%s (%s)", taskConf.name, targetText))
    if self.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
      self.NRCImage_Get:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Switcher:SetActiveWidgetIndex(2)
    elseif self.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
      self.NRCImage_Get:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Available, 0, 99999)
      self.Switcher:SetActiveWidgetIndex(1)
    end
  end
  self.RewardId = RewardId
  self.RewardType = RewardType
  if RewardType == Enum.GoodsType.GT_BAGITEM then
    local item_conf = _G.DataConfigManager:GetBagItemConf(RewardId)
    if item_conf then
      self.icon:SetPath(item_conf.icon)
    end
    self.ConditionRewardCount = ConditionRewardConf.reward_group[1].goods_count
    self.QuantityText:SetText(string.format("x%s", ConditionRewardConf.reward_group[1].goods_count))
  elseif RewardType == Enum.GoodsType.GT_VITEM then
    local item_conf = _G.DataConfigManager:GetVisualItemConf(RewardId)
    if item_conf then
      self.icon:SetPath(item_conf.icon)
    end
    self.ConditionRewardCount = ConditionRewardConf.reward_group[1].goods_count
    self.QuantityText:SetText(string.format("x%s", ConditionRewardConf.reward_group[1].goods_count))
  elseif RewardType == Enum.GoodsType.GT_REWARD then
    local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
    local rewardsGroup = RewardConf.RewardItem
    self.ConditionRewardCount = ConditionRewardConf.reward_group[1].goods_count
    if rewardsGroup and rewardsGroup[1] then
      self.QuantityText:SetText(string.format("x%s", rewardsGroup[1].Count * ConditionRewardConf.reward_group[1].goods_count))
      local type = rewardsGroup[1].Type
      if type == Enum.GoodsType.GT_BAGITEM then
        local item_conf = _G.DataConfigManager:GetBagItemConf(rewardsGroup[1].Id)
        if item_conf then
          self.icon:SetPath(item_conf.icon)
        end
      end
      if type == Enum.GoodsType.GT_VITEM then
        local item_conf = _G.DataConfigManager:GetVisualItemConf(rewardsGroup[1].Id)
        if item_conf then
          self.icon:SetPath(item_conf.iconPath)
        end
      end
    end
  end
end

function UMG_Activity_SeasonSignItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_SeasonSignItem_C:OnDeactive()
end

return UMG_Activity_SeasonSignItem_C
