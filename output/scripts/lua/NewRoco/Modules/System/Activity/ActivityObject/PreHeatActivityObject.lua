local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local PreHeatActivityObject = Base:Extend("PreHeatActivityObject")
local TaskQueryHandler = require("NewRoco.Modules.System.Misc.TaskQueryHandler")
local CountDownHandler = require("NewRoco.Modules.System.Misc.CountDownHandler")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local PreHeatCollectItemObject = Class("PreHeatCollectItemObject")

function PreHeatCollectItemObject:Ctor(owner, slot, cfg)
  self.owner = owner
  self.slot = slot
  self.cfg = cfg
  self.status = ActivityEnum.ItemStatus.Locked
  self.finishTimestamp = 0
  self.unlockCountDown = CountDownHandler.CreateCountDownObjectByTimestamp(cfg and ActivityUtils.ToTimestamp(cfg.unlock_time) or 0)
  self.unlockCountDown:AddListener("PreHeatCollectItemObject", self, self.OnUnlockCountDown)
end

function PreHeatCollectItemObject:GetRedpointData()
  local owner = self:GetOwner()
  local slot = self:GetSlot() or 0
  if owner then
    return 447, {
      owner:GetActivityId(),
      slot - 1
    }
  end
end

function PreHeatCollectItemObject:GetOwner()
  return self.owner
end

function PreHeatCollectItemObject:GetSlot()
  return self.slot or 0
end

function PreHeatCollectItemObject:GetCfg()
  return self.cfg
end

function PreHeatCollectItemObject:GetStatus()
  return self.status
end

function PreHeatCollectItemObject:GetFinishTimestamp()
  return self.finishTimestamp
end

function PreHeatCollectItemObject:GetTaskId()
  return self.cfg and self.cfg.manuscript_task_id
end

function PreHeatCollectItemObject:GetOptionId()
  local taskId = self:GetTaskId()
  if taskId and 0 ~= taskId then
    return self.cfg and self.cfg.option_id
  end
end

function PreHeatCollectItemObject:GetUnLockCountDown()
  return self.unlockCountDown
end

function PreHeatCollectItemObject:SetStatus(status, timestamp)
  if self.status ~= status then
    self.status = status
    self:OnCollectItemObjectStatusChanged()
  end
  self.finishTimestamp = timestamp
end

function PreHeatCollectItemObject:OnClick()
  local status = self:GetStatus()
  if status == ActivityEnum.ItemStatus.Locked then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_preheat__unlock_tips)
  elseif status == ActivityEnum.ItemStatus.UnLocked then
    local optionId = self:GetOptionId()
    if optionId and optionId > 0 then
      ActivityUtils.DoActivityOptionCmd(optionId)
    end
  elseif status == ActivityEnum.ItemStatus.Available then
    local owner = self:GetOwner()
    if owner then
      local req = _G.ProtoMessage:newZoneActivityPreHeatRewardReq()
      req.activity_id = owner:GetActivityId()
      req.operate_type = 1
      req.section_id = self:GetSlot() - 1
      ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PRE_HEAT_REWARD_REQ, req, self, self.OnZoneActivityPreHeatRewardRsp)
    end
  elseif status == ActivityEnum.ItemStatus.Finished then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenSeasonPreheatingRecordBookPanel, self)
  end
  local key, extraKey = self:GetRedpointData()
  if key then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, key, extraKey)
  end
end

function PreHeatCollectItemObject:OnCollectItemObjectStatusChanged()
  local owner = self:GetOwner()
  if owner and owner.OnCollectItemObjectStatusChanged then
    owner:OnCollectItemObjectStatusChanged(self)
  end
end

function PreHeatCollectItemObject:OnZoneActivityPreHeatRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  self:SetStatus(ActivityEnum.ItemStatus.Finished, self.finishTimestamp)
end

function PreHeatCollectItemObject:OnUnlockCountDown(leftSeconds)
  if leftSeconds <= 0 then
    local status = self:GetStatus()
    if status <= ActivityEnum.ItemStatus.Locked then
      local taskId = self:GetTaskId()
      if taskId and 0 ~= taskId then
        self:SetStatus(ActivityEnum.ItemStatus.UnLocked, self.finishTimestamp)
      else
        self:SetStatus(ActivityEnum.ItemStatus.Available, self.finishTimestamp)
      end
    end
  end
end

function PreHeatActivityObject:OnConstruct(_conf)
  self.preHeatCfg = _G.DataConfigManager:GetActivityPreheatConf(self:GetSinglePartId())
  self.preUnLockTaskQuery = TaskQueryHandler(self.preHeatCfg and self.preHeatCfg.pre_unlock_task)
  self.collectItemObjectList = {}
  if self.preHeatCfg then
    for slot, v in ipairs(self.preHeatCfg.reward_group or {}) do
      local itemObject = PreHeatCollectItemObject(self, slot, v)
      table.insert(self.collectItemObjectList, itemObject)
    end
  end
  self.finalRewardStatus = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
end

function PreHeatActivityObject:GetPreHeatCfg()
  return self.preHeatCfg
end

function PreHeatActivityObject:GetFinalRewardStatus()
  return self.finalRewardStatus or ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
end

function PreHeatActivityObject:GetPreUnLockTaskData()
  local allFinished = self.preUnLockTaskQuery:CheckAllTaskDone()
  return allFinished, self.preHeatCfg and self.preHeatCfg.option_txt
end

function PreHeatActivityObject:QueryPreUnLockTaskStatus()
  local allFinished = self.preUnLockTaskQuery:CheckAllTaskDone()
  self.preUnLockTaskQuery:QueryTaskStatus(self, self.OnQueryPreUnLockTaskStatus, allFinished)
end

function PreHeatActivityObject:TrackPreUnLockTask()
  local taskId = self.preUnLockTaskQuery:GetTaskByStatus(ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN)
  if taskId then
    ActivityUtils.TraceTaskParagraph(taskId)
  end
end

function PreHeatActivityObject:OnQueryPreUnLockTaskStatus(preAllFinished, allFinished)
  if preAllFinished ~= allFinished then
    self:SendEvent(ActivityModuleEvent.PreHeatActivity_PreUnLockTaskStatusChanged, self)
  end
end

function PreHeatActivityObject:SendZoneActivityPreHeatRewardReq()
  if self.finalRewardStatus ~= ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    return
  end
  local req = _G.ProtoMessage:newZoneActivityPreHeatRewardReq()
  req.activity_id = self:GetActivityId()
  req.operate_type = 0
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PRE_HEAT_REWARD_REQ, req, self, self.OnZoneActivityPreHeatRewardRsp)
end

function PreHeatActivityObject:OnZoneActivityPreHeatRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  self:SetFinalRewardStatus(ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE)
  local cfg = self:GetPreHeatCfg()
  if cfg and self:GetAttachView() then
    ActivityUtils.ShowRewardGetTips(cfg.reward_id, _protoData.ret_info)
  end
end

function PreHeatActivityObject:SetFinalRewardStatus(status)
  if self.finalRewardStatus ~= status then
    self.finalRewardStatus = status
    self:SendEvent(ActivityModuleEvent.PreHeatActivity_FinalRewardStatusChanged, self)
  end
end

function PreHeatActivityObject:GetCollectItemObject(index)
  return self.collectItemObjectList[index]
end

function PreHeatActivityObject:GetCollectItemFinishedCount()
  local finishedCount = 0
  for _, itemObject in ipairs(self.collectItemObjectList) do
    if itemObject:GetStatus() == ActivityEnum.ItemStatus.Finished then
      finishedCount = finishedCount + 1
    end
  end
  return finishedCount, #self.collectItemObjectList
end

function PreHeatActivityObject:OnCollectItemObjectStatusChanged(itemObject)
  self:SendEvent(ActivityModuleEvent.PreHeatActivity_CollectItemStatusChanged, self, itemObject)
end

function PreHeatActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function PreHeatActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    local _preheatData = _activityData and _activityData.season_preheat_data
    self:SetFinalRewardStatus(_preheatData and _preheatData.final_reward_status)
    for idx, itemObject in ipairs(self.collectItemObjectList) do
      local section = _preheatData and _preheatData.section_list and _preheatData.section_list[idx] or {}
      local itemStatus = ActivityEnum.ItemStatus.Locked
      if section then
        if 1 == section.statue then
          itemStatus = ActivityEnum.ItemStatus.UnLocked
        elseif 2 == section.statue then
          itemStatus = ActivityEnum.ItemStatus.Available
        elseif 3 == section.statue then
          itemStatus = ActivityEnum.ItemStatus.Finished
        end
      end
      itemObject:SetStatus(itemStatus, section and section.finish_timestamp or 0)
    end
  end
end

return PreHeatActivityObject
