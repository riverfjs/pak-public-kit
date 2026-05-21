local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local LegendaryChallengeActivityObject = Base:Extend("LegendaryChallengeActivityObject")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function LegendaryChallengeActivityObject:OnConstruct(_conf)
  self.SubSlotDataArray = {}
end

function LegendaryChallengeActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.activity_data = _updateData
    self:ExtraImportantData()
    self.CurTaskId = self:SearchCurTaskId()
    self:SendEvent(ActivityModuleEvent.LegendaryChallengeActivityDataUpdate, _updateData)
  end
end

function LegendaryChallengeActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function LegendaryChallengeActivityObject:GetActivityData()
  return self.activity_data
end

function LegendaryChallengeActivityObject:GetCurTaskId()
  return self.CurTaskId
end

function LegendaryChallengeActivityObject:GetSubSlotDataArray()
  return self.SubSlotDataArray
end

function LegendaryChallengeActivityObject:GetTopSlotData()
  return self.TopSlotData
end

function LegendaryChallengeActivityObject:ExtraImportantData()
  if not self.activity_data or not self.activity_data.part_data then
    return
  end
  local activityConf = _G.DataConfigManager:GetActivityConf(self.activity_data.activity_id)
  if not activityConf then
    return
  end
  local partData = self.activity_data and self.activity_data.part_data
  self.TaskSubActivityBaseId = 0
  self.TaskSubActivityState = ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE
  local length = #partData
  local TopSlotData = {}
  self.SubSlotDataArray = table.new(length, 0)
  for idx, data in ipairs(partData) do
    local subSlotData = {}
    local slotIndex = data.param.param1
    local legendaryChallengeConf = _G.DataConfigManager:GetLegendaryChallengeConf(data.activity_part_id)
    if legendaryChallengeConf then
      self.SubSlotDataArray[slotIndex] = subSlotData
      subSlotData.baseId = data.activity_part_id
      subSlotData.state = data.state or ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE
      subSlotData.des1 = legendaryChallengeConf.slot_des1
      subSlotData.des2 = legendaryChallengeConf.slot_des2
      subSlotData.des3 = legendaryChallengeConf.slot_des3
      subSlotData.activityOptionId = legendaryChallengeConf.redirect_sub
      if 1 == slotIndex then
        self.TaskSubActivityBaseId = data.activity_part_id
        self.TaskSubActivityState = data.state
        TopSlotData.activityOptionId = legendaryChallengeConf.redirect_top
      end
    end
  end
  self.TopSlotData = TopSlotData
end

function LegendaryChallengeActivityObject:RefreshTaskSearchResult()
  self.CurTaskId = self:SearchCurTaskId()
end

function LegendaryChallengeActivityObject:SearchCurTaskId()
  if self.TaskSubActivityBaseId and 0 ~= self.TaskSubActivityBaseId then
    local legendaryChallengeConf = _G.DataConfigManager:GetLegendaryChallengeConf(self.TaskSubActivityBaseId)
    if legendaryChallengeConf and legendaryChallengeConf.task_conf_id and #legendaryChallengeConf.task_conf_id > 0 then
      for idx1, taskId in ipairs(legendaryChallengeConf.task_conf_id) do
        local taskInfo = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.getTaskByID, taskId)
        if taskInfo and taskInfo.state and taskInfo.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          return taskId
        end
      end
      if self.TaskSubActivityState == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE then
        return legendaryChallengeConf.task_conf_id[1]
      elseif self.TaskSubActivityState == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_OPEN then
        Log.Error("LegendaryChallengeActivityObject:SearchCurTaskId \229\137\167\230\131\133\228\187\187\229\138\161\230\180\187\229\138\168\229\164\132\228\186\142\229\188\128\229\144\175\231\138\182\230\128\129\239\188\140\228\189\134\230\152\175\230\137\190\228\184\141\229\136\176\232\191\155\232\161\140\228\184\173\231\154\132\230\180\187\229\138\168\228\187\187\229\138\161\239\188\129!")
        Log.Dump(self.activity_data, 6, "LegendaryChallengeActivityObject:SearchCurTaskId")
        Log.Dump(legendaryChallengeConf.task_conf_id, 4, "LegendaryChallengeActivityObject:SearchCurTaskId")
        return legendaryChallengeConf.task_conf_id[1]
      elseif self.TaskSubActivityState == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
        return legendaryChallengeConf.task_conf_id[#legendaryChallengeConf.task_conf_id]
      end
    end
  end
  return 0
end

return LegendaryChallengeActivityObject
