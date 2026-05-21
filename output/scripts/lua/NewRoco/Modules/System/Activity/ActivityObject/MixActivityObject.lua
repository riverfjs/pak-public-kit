local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local TaskQueryHandler = require("NewRoco.Modules.System.Misc.TaskQueryHandler")
local ConditionRewardHandler = require("NewRoco.Modules.System.Activity.ActivityObject.ConditionRewardHandler")
local CountDownHandler = require("NewRoco.Modules.System.Misc.CountDownHandler")
local MixActivityObject = Base:Extend("MixActivityObject")
local ThisWeekClassScheduleItemObject = ConditionRewardHandler.CreateVariableExtendCls()

function ThisWeekClassScheduleItemObject:OnConstruct()
end

function ThisWeekClassScheduleItemObject:GetTaskGoConf()
  local taskId = self:GetTaskId()
  if taskId and 0 ~= taskId then
    return _G.DataConfigManager:GetActivityTaskGoConf(taskId)
  end
end

function ThisWeekClassScheduleItemObject:GetTaskId()
  return self:GetConditionParam()
end

function ThisWeekClassScheduleItemObject:GetDesc()
  local taskGoConf = self:GetTaskGoConf()
  if taskGoConf then
    return taskGoConf.task_name
  end
end

function ThisWeekClassScheduleItemObject:GetRewardData()
  local taskId = self:GetTaskId()
  if taskId and 0 ~= taskId then
    local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
    if taskConf and taskConf.Reward and 0 ~= taskConf.Reward then
      local rewardConf = _G.DataConfigManager:GetRewardConf(taskConf.Reward)
      if rewardConf and rewardConf.RewardItem then
        for _, rewardItem in ipairs(rewardConf.RewardItem) do
          if rewardItem.Type == _G.Enum.GoodsType.GT_VITEM then
            return ActivityUtils.GetItemIconAndQuality(rewardItem.Type, rewardItem.Id), rewardItem.Count
          end
        end
      end
    end
  end
  return "", 0
end

function ThisWeekClassScheduleItemObject:GetRedPointData()
  local owner = self:GetOwner()
  local activityId = owner and owner:GetActivityId() or 0
  local taskId = self:GetTaskId() or 0
  return 455, {activityId, taskId}
end

function ThisWeekClassScheduleItemObject:IsCanJump()
  local taskGoConf = self:GetTaskGoConf()
  if taskGoConf and taskGoConf.option_id and 0 ~= taskGoConf.option_id then
    return true
  end
  return false
end

function ThisWeekClassScheduleItemObject:ExecuteJump()
  local taskGoConf = self:GetTaskGoConf()
  if taskGoConf then
    ActivityUtils.DoActivityOptionCmd(taskGoConf.option_id)
  end
end

function ThisWeekClassScheduleItemObject:RefreshTask(taskId)
  assert(taskId and 0 ~= taskId, "taskId is invalid")
  self:ChangeCondition(self:GetConditionEnum(), taskId)
end

local function CreateThisWeekClassScheduleItemObject(inActivityInst, inTaskId)
  return ConditionRewardHandler.CreateExtendClsInstance(ThisWeekClassScheduleItemObject, inActivityInst, Enum.RequiredType.ACTRT_TASK, inTaskId)
end

function MixActivityObject:OnConstruct(_conf)
  self.mixConf = _G.DataConfigManager:GetActivityMixConf(self:GetSinglePartId())
  self.mixData = {}
  self.initialFaction = ProtoEnum.ActivityFaction.FACTION_NONE
  self.selectFaction = ProtoEnum.ActivityFaction.FACTION_NONE
  self.judgeTaskQuery = TaskQueryHandler(self.mixConf and self.mixConf.must_do_task_judg)
  self.joinStatus = self:CalculateJoinStatus()
  self.finishedFactions = {}
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHOOSE_NEW_FACTION_NOTIFY, self.OnZoneChooseNewFactionNotify)
end

function MixActivityObject:OnDestruct()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHOOSE_NEW_FACTION_NOTIFY, self.OnZoneChooseNewFactionNotify)
end

function MixActivityObject:GetMixConf()
  return self.mixConf
end

function MixActivityObject:GetMixData()
  return self.mixData
end

function MixActivityObject:GetFactionConf()
  local factionId = self:GetFactionId()
  if factionId and 0 ~= factionId then
    return _G.DataConfigManager:GetActivityFactionConf(factionId)
  end
end

function MixActivityObject:GetJoinStatus()
  return self.joinStatus
end

function MixActivityObject:GetSelectFaction()
  return self.selectFaction
end

function MixActivityObject:GetFactionConfByFactionType(factionType)
  if factionType == ProtoEnum.ActivityFaction.FACTION_NONE then
    return
  end
  local factionConf = self:GetFactionConf()
  if factionConf then
    for _, factionGroup in ipairs(factionConf.faction_group) do
      if factionGroup.faction_type == factionType then
        return factionGroup
      end
    end
  end
end

function MixActivityObject:GetSelectFactionConf()
  local factionType = self:GetSelectFaction()
  return self:GetFactionConfByFactionType(factionType)
end

function MixActivityObject:GetInitialFactionConf()
  return self:GetFactionConfByFactionType(self.initialFaction)
end

function MixActivityObject:GetFactionId()
  return self.mixConf and self.mixConf.must_do_faction_id
end

function MixActivityObject:RefreshMustDoTaskStatus()
  if 0 ~= self:GetFactionId() and self:GetSelectFaction() == ProtoEnum.ActivityFaction.FACTION_NONE then
    return
  end
  if self:GetJoinStatus() == ActivityEnum.MixActivityJoinStatus.Normal then
    return
  end
  self.judgeTaskQuery:QueryTaskStatus(self, self.RefreshJoinStatus)
end

function MixActivityObject:TrackCurrentMustDoTask()
  return self.judgeTaskQuery:TrackTask()
end

function MixActivityObject:GetClassScheduleCountDownObject()
  if not self.ClassScheduleCountDownObject then
    self.ClassScheduleCountDownObject = CountDownHandler.CreateCountDownObjectByTimeFunction(self.GetClassScheduleNextRefreshTime, self)
  end
  return self.ClassScheduleCountDownObject
end

function MixActivityObject:GetClassScheduleNextRefreshTime()
  local joinStatus = self:GetJoinStatus()
  if joinStatus == ActivityEnum.MixActivityJoinStatus.Normal then
    local mixData = self:GetMixData()
    if mixData then
      return mixData.next_refresh_time
    end
  end
end

function MixActivityObject:OnRewardItemProgressChange(_itemObj)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.MixActivityClassScheduleProgressChange, self, _itemObj)
    local cur, total = _itemObj:GetProgress()
    if cur == total then
      if _itemObj:GetConditionCustomData() == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        _itemObj:SetRewardReceived(false)
      else
        _itemObj:SetCompleted(false)
      end
    end
  end
end

function MixActivityObject:OnRewardItemStatusChange(_itemObj, _userOperation)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.MixActivityClassScheduleStatusChange, self, _itemObj, _userOperation)
  end
end

function MixActivityObject:OnRewardItemConditionChange(_itemObj)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.MixActivityClassScheduleTaskChange, self, _itemObj)
  end
end

function MixActivityObject:GetClassScheduleItems()
  return self.classScheduleItems or {}
end

function MixActivityObject:GetClassScheduleItemByTaskId(_taskId)
  local classScheduleItems = self.classScheduleItems
  if classScheduleItems then
    for _, itemObj in ipairs(classScheduleItems) do
      if itemObj:GetTaskId() == _taskId then
        return itemObj
      end
    end
  end
end

function MixActivityObject:SendZoneRefreshMixActivityTaskReq(taskId)
  local req = _G.ProtoMessage:newZoneRefreshMixActivityTaskReq()
  req.activity_id = self:GetActivityId()
  req.task_id = taskId
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_REFRESH_MIX_ACTIVITY_TASK_REQ, req, self, self.OnZoneRefreshMixActivityTaskRsp)
end

function MixActivityObject:OnZoneRefreshMixActivityTaskRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _protoData.activity_data then
    self:RefreshMixData(_protoData.activity_data.mix_data)
  end
end

function MixActivityObject:SendZoneTaskRewardReq(taskId)
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = {taskId}
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.OnZoneTaskRewardRsp)
end

function MixActivityObject:OnZoneTaskRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _protoData.rewarded_task_list then
    for _, taskInfo in ipairs(_protoData.rewarded_task_list) do
      if taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        local itemObj = self:GetClassScheduleItemByTaskId(taskInfo.id)
        if itemObj then
          itemObj:SetRewardReceived(true)
          ActivityUtils.ShowRewardGetTips(nil, _protoData.ret_info)
        end
      end
    end
  end
end

function MixActivityObject:GetProgressVItemData()
  local mixConf = self:GetMixConf()
  local vItemId = mixConf and mixConf.progress_vitem_show
  local vItemCnt = 0
  if vItemId and 0 ~= vItemId then
    vItemCnt = _G.DataModelMgr.PlayerDataModel:GetVItemCount(vItemId) or 0
  end
  return vItemId, vItemCnt
end

function MixActivityObject:GetProgressTaskRewardQuery()
  return self.progressTaskQuery
end

function MixActivityObject:GetProgressTaskRewardStatus(taskId)
  local progressTaskQuery = self:GetProgressTaskRewardQuery()
  if progressTaskQuery then
    local taskStatus = progressTaskQuery:GetTaskStatus(taskId)
    if taskStatus == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      return ActivityEnum.RewardStatus.Available
    elseif taskStatus == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      return ActivityEnum.RewardStatus.Received
    else
      return ActivityEnum.RewardStatus.UnAvailable
    end
  end
end

function MixActivityObject:SendZoneChooseActivityFactionReq(_faction)
  local mixData = self:GetMixData()
  if self:GetSelectFaction() == ProtoEnum.ActivityFaction.FACTION_NONE or mixData and mixData.can_choose_new_faction then
    local req = _G.ProtoMessage:newZoneChooseActivityFactionReq()
    req.activity_id = self:GetActivityId()
    req.faction = _faction
    ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHOOSE_ACTIVITY_FACTION_REQ, req, self, self.OnZoneChooseActivityFactionRsp)
  end
end

function MixActivityObject:OnZoneChooseActivityFactionRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _req and _req.activity_id == self:GetActivityId() then
    self:RefreshSelectFaction(_req.faction)
  end
end

function MixActivityObject:GetFactionRankData()
  return self.factionRankData
end

function MixActivityObject:SendZoneActivityFactionRankReq()
  local req = _G.ProtoMessage:newZoneActivityFactionRankReq()
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_FACTION_RANK_REQ, req, self, self.OnZoneActivityFactionRankRsp)
end

function MixActivityObject:OnZoneActivityFactionRankRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _req and _req.activity_id == self:GetActivityId() then
    self.factionRankData = _protoData.rank_info and _protoData.rank_info.rank_list
    self:SendEvent(ActivityModuleEvent.MixActivityFactionRankDataChange, self, self.factionRankData)
  end
end

function MixActivityObject:GetFactionFinishedTimestamp(_faction)
  return self.finishedFactions[_faction]
end

function MixActivityObject:SendZoneFinishExperienceCardPopupReq()
  if not self.mixData.experience_card_popup then
    return
  end
  local req = _G.ProtoMessage:newZoneFinishExperienceCardPopupReq()
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_FINISH_EXPERIENCE_CARD_POPUP_REQ, req, self, self.OnZoneFinishExperienceCardPopupRsp)
end

function MixActivityObject:OnZoneFinishExperienceCardPopupRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _req and _req.activity_id == self:GetActivityId() then
    self.mixData.experience_card_popup = false
  end
end

function MixActivityObject:CalculateJoinStatus()
  local newJoinStatus = ActivityEnum.MixActivityJoinStatus.Init
  if 0 == self:GetFactionId() or self:GetSelectFaction() ~= ProtoEnum.ActivityFaction.FACTION_NONE then
    if self.judgeTaskQuery:CheckAllTaskDone() then
      newJoinStatus = ActivityEnum.MixActivityJoinStatus.Normal
    else
      newJoinStatus = ActivityEnum.MixActivityJoinStatus.InGuidTask
    end
  end
  return newJoinStatus
end

function MixActivityObject:UpdateFinishedFaction(finishedFactions)
  if finishedFactions then
    for _, factionData in ipairs(finishedFactions) do
      self.finishedFactions[factionData.faction] = factionData.finish_time
    end
  end
  local factionCfg = self:GetFactionConf()
  local factionNum = factionCfg and factionCfg.faction_group and #factionCfg.faction_group or 0
  return factionNum <= table.getTableCount(self.finishedFactions)
end

function MixActivityObject:RefreshMixData(mixData)
  self.mixData = mixData or {}
  self.initialFaction = mixData and mixData.first_choose_faction
  self:UpdateFinishedFaction(mixData and mixData.finished_faction)
  if nil ~= mixData then
    local classScheduleItems = self.classScheduleItems or {}
    self.classScheduleItems = classScheduleItems
    
    local function CreateOrRefreshScheduleItemObject(itemIndex, taskId)
      if taskId and 0 ~= taskId then
        local itemObj = classScheduleItems[itemIndex]
        if not itemObj then
          itemObj = CreateThisWeekClassScheduleItemObject(self, taskId)
          classScheduleItems[itemIndex] = itemObj
        elseif itemObj:GetTaskId() ~= taskId then
          itemObj:RefreshTask(taskId)
        end
        return itemIndex + 1
      else
        return itemIndex
      end
    end
    
    local itemIndex = CreateOrRefreshScheduleItemObject(1, mixData.main_task_id)
    if mixData.optional_task_id then
      for _, taskId in ipairs(mixData.optional_task_id) do
        itemIndex = CreateOrRefreshScheduleItemObject(itemIndex, taskId)
      end
    end
    for i = #classScheduleItems, itemIndex, -1 do
      table.remove(classScheduleItems, i)
    end
  else
    self.classScheduleItems = nil
  end
  self:RefreshSelectFaction(mixData and mixData.faction)
  self:RefreshMustDoTaskStatus()
  if self.ClassScheduleCountDownObject then
    self.ClassScheduleCountDownObject:ForceRefreshLeftTime()
  end
  local npcChallengeHandler = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetNpcChallengeHandler)
  if npcChallengeHandler then
    for _, challengeData in ipairs(mixData and mixData.npc_challenge_items or {}) do
      npcChallengeHandler:AddOrRefreshChallengeItem(challengeData)
    end
  end
  self:SendEvent(ActivityModuleEvent.MixActivitySvrDataChanged, self)
end

function MixActivityObject:RefreshJoinStatus()
  local newJoinStatus = self:CalculateJoinStatus()
  if self.joinStatus ~= newJoinStatus then
    self.joinStatus = newJoinStatus
    local classScheduleCountDownObject = self.ClassScheduleCountDownObject
    if classScheduleCountDownObject then
      classScheduleCountDownObject:ForceRefreshLeftTime()
    end
    self:SendEvent(ActivityModuleEvent.MixActivityJoinStatusChanged, self)
  end
end

function MixActivityObject:RefreshSelectFaction(_faction)
  local newFaction = _faction or ProtoEnum.ActivityFaction.FACTION_NONE
  if self.selectFaction == newFaction then
    return
  end
  self.selectFaction = newFaction
  local selectFactionConf = self:GetFactionConfByFactionType(newFaction)
  if selectFactionConf then
    self.progressTaskQuery = TaskQueryHandler(selectFactionConf.progress_reward_task_id)
  end
  self:SendEvent(ActivityModuleEvent.MixActivitySelectFactionChanged, self)
  self:RefreshJoinStatus()
end

function MixActivityObject:OnZoneChooseNewFactionNotify(_protoData)
  if not _protoData then
    return
  end
  if self:GetActivityId() == _protoData.activity_id and not self:UpdateFinishedFaction(_protoData.finished_faction) then
    self.mixData.experience_card_popup = true
    self.mixData.can_choose_new_faction = true
    self:SendEvent(ActivityModuleEvent.MixActivitySvrDataChanged, self)
  end
end

function MixActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function MixActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    local _mixData = _activityData and _activityData.mix_data
    self:RefreshMixData(_mixData)
  end
end

return MixActivityObject
