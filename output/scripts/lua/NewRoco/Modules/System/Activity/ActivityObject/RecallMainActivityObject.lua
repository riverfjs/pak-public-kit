local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local RecallMainActivityObject = Base:Extend("RecallMainActivityObject")

function RecallMainActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    if self.activityData and self.activityData.active and not _updateData.recall_data.active then
      self:SendEvent(ActivityModuleEvent.OnRecallActivityFinish)
    end
    self.activityData = _updateData.recall_data
    if _updateData.recall_data.active and (not _updateData.recall_data.is_disposable_reward_taken or not _updateData.recall_data.is_pet_egg_taken) and not _G.NRCModuleManager:GetModule("TaskModule"):HasPanel("ReturnRewardPanel") and not _G.NRCModuleManager:GetModule("ActivityModule"):HasPanel("BackflowPetSelect") then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.CreateReturnRewardTips)
    end
  end
end

function RecallMainActivityObject:GetActivityData()
  return self.activityData
end

function RecallMainActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function RecallMainActivityObject:OnReconnectFinish()
  self:ReqGetPlayerActivityData()
  return true
end

return RecallMainActivityObject
