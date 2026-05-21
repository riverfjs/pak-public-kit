local Base = require("NewRoco.Modules.System.Activity.ActivityObject.RecallActivityObject")
local RecallBPActivityObject = Base:Extend("RecallBPActivityObject")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function RecallBPActivityObject:OnConstruct(_conf)
  Base.OnConstruct(self, _conf)
end

function RecallBPActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.activityData = _updateData.recall_bp_data
    self:SendEvent(ActivityModuleEvent.RefreshBPActivityData, _updateData.recall_bp_data)
  end
end

function RecallBPActivityObject:GetActivityData()
  return self.activityData
end

function RecallBPActivityObject:ClearActivityData()
  self.activityData = nil
end

return RecallBPActivityObject
