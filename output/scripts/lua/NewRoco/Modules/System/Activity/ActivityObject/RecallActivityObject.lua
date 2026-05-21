local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local RecallActivityObject = Base:Extend("RecallActivityObject")

function RecallActivityObject:GetActivityEndTime()
  if self:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY then
    if not self.close_timestamp then
      local activityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
      if activityObjects and #activityObjects > 0 then
        for _, object in ipairs(activityObjects) do
          local recall_data = object:GetActivityData()
          if recall_data and recall_data.active then
            self.close_timestamp = recall_data.close_timestamp
            break
          end
        end
      end
    end
    if self.close_timestamp then
      Log.Debug("RecallActivityObject:GetActivityEndTime, close_timestamp", self.close_timestamp)
      return self.close_timestamp
    else
      Log.Debug("RecallActivityObject:GetActivityEndTime, UseBaseEndTime")
      return Base.GetActivityEndTime(self)
    end
  else
    return Base.GetActivityEndTime(self)
  end
end

return RecallActivityObject
