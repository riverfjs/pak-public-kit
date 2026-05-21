local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local NPCActionGetReturnPet = Base:Extend("NPCActionGetReturnPet")

function NPCActionGetReturnPet:ExecuteWithModel()
  local activityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  if activityObjects and #activityObjects > 0 then
    local activityObject
    for _, object in ipairs(activityObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        activityObject = object
        break
      end
    end
    if activityObject then
      local req = _G.ProtoMessage:newZoneGetActivityOptionalPetsReq()
      req.activity_id = activityObject:GetActivityId()
      self.activity_id = req.activity_id
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_ACTIVITY_OPTIONAL_PETS_REQ, req, self, self.OpenPetPanel)
    end
  end
end

function NPCActionGetReturnPet:OpenPetPanel(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.optional_pets_id then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenBackflowPetSelect, rsp.optional_pets_id, self)
  else
    self:Finish(false)
  end
end

return NPCActionGetReturnPet
