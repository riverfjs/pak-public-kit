local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local FlowerAppearHardActivityObject = Base:Extend("FlowerAppearHardActivityObject")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function FlowerAppearHardActivityObject:OnConstruct(_conf)
  self.flowerAppearConf = _G.DataConfigManager:GetActivityFlowerAppearConf(self:GetSinglePartId())
  self:AddActivityExpiredCallback("RoyalGriffinPopUpClose", nil, function()
    local module = _G.NRCModuleManager:GetModule("ActivityModule")
    local panel = module:GetPanel("OrdinaryReward")
    if panel then
      panel:ClosePanel()
    end
  end)
end

function FlowerAppearHardActivityObject:GetLimitTimeAppearConf()
  return self.flowerAppearConf
end

function FlowerAppearHardActivityObject:GetFlowerDataList()
  return self.flowerAppearConf and self.flowerAppearConf.flower_group or {}
end

function FlowerAppearHardActivityObject:GetFlowerData(index)
  if index then
    return self.flowerAppearConf and self.flowerAppearConf.flower_group and self.flowerAppearConf.flower_group[index]
  end
end

function FlowerAppearHardActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.activity_data = _updateData.part_data
    self:SendEvent(ActivityModuleEvent.RefreshRoyalGriffinActivityData, _updateData.part_data)
  end
end

function FlowerAppearHardActivityObject:GetActivityData()
  return self.activity_data
end

function FlowerAppearHardActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function FlowerAppearHardActivityObject:GetTaskState(task_id)
  if self.activity_data then
    for _, reward_data in ipairs(self.activity_data) do
      if reward_data.activity_part_id == task_id then
        return reward_data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE
      end
    end
  end
  return false
end

function FlowerAppearHardActivityObject:GetPetNatureId()
  return 0
end

function FlowerAppearHardActivityObject:ShowPetNatureTips()
end

return FlowerAppearHardActivityObject
