local Base = require("NewRoco.Modules.System.Activity.ActivityObject.RecallActivityObject")
local RecallStarLightActivityObject = Base:Extend("RecallStarLightActivityObject")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function RecallStarLightActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.activityData = _updateData.recall_starlight_data
    self:SendEvent(ActivityModuleEvent.RefreshStarLightActivityData, _updateData.recall_starlight_data)
  end
end

function RecallStarLightActivityObject:GetActivityData()
  return self.activityData
end

return RecallStarLightActivityObject
