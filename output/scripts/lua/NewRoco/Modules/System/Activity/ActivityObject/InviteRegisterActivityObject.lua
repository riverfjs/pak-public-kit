local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local InviteRegisterActivityObject = Base:Extend("InviteRegisterActivityObject")

function InviteRegisterActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.activity_data = _updateData.part_data
    self.invite_data = _updateData.invite_register_data
    self:SendEvent(ActivityModuleEvent.RefreshInviteRegisterActivityData, _updateData.part_data)
  end
end

function InviteRegisterActivityObject:GetActivityData()
  return self.activity_data
end

function InviteRegisterActivityObject:GetInviteData()
  return self.invite_data
end

return InviteRegisterActivityObject
