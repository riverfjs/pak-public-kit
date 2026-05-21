local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local AbnormalStatusComponent = Base:Extend("AbnormalStatusComponent")

function AbnormalStatusComponent:Ctor()
  Base.Ctor(self)
  self.RegistryStatus = {}
  self.ActiveStatus = {}
  self.StartTimeMap = {}
  self.BannedLogicStatus = {}
  self.HiddenLogicStatus = {}
  local salsConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.SCENE_STATUS_SALS_CONF)
  if salsConf then
    for _, v in pairs(salsConf) do
      if v.not_set_abnormal_status then
        table.insert(self.BannedLogicStatus, v.player_sals)
      end
      if v.cut_hide_abnormal_status then
        table.insert(self.HiddenLogicStatus, v.player_sals)
      end
    end
  end
end

function AbnormalStatusComponent:Attach(owner)
  Base.Attach(self, owner)
  self:BindEvents()
end

function AbnormalStatusComponent:DeAttach()
  Base.DeAttach(self)
  self:UnbindEvents()
  self:RemoveAllStatus(true)
  self.RegistryStatus = {}
end

function AbnormalStatusComponent:Destroy()
  Base.Destroy(self)
  self:UnbindEvents()
  self:RemoveAllStatus(true)
  self.RegistryStatus = {}
end

function AbnormalStatusComponent:RegisterStatus(statusId, statusClass)
  if self.RegistryStatus[statusId] then
    Log.Error("abnormal status already registered!")
    return
  end
  self.RegistryStatus[statusId] = statusClass
end

function AbnormalStatusComponent:UnregisterStatus(statusId)
  self.RegistryStatus[statusId] = nil
end

function AbnormalStatusComponent:ExecuteStatus(statusId, startTime)
  self.StartTimeMap[statusId] = startTime
  if self.ActiveStatus[statusId] then
    Log.Error("abnormal status already active!")
    return
  end
  self:RemoveAllStatus(true)
  local statusConf = _G.DataConfigManager:GetAbnormalStatusConf(statusId)
  if not statusConf then
    return
  end
  local statusClass = self.RegistryStatus[statusId]
  if not statusClass then
    statusClass = require(string.format("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.%s", statusConf.class_name))
    self:RegisterStatus(statusId, statusClass)
  end
  local statusInstance = statusClass(self.owner)
  if not statusInstance then
    Log.Error("abnormal status instance create failed!")
    return
  end
  self.ActiveStatus[statusId] = statusInstance
  self.bStatusVisible = self:IsStatusVisible() and not self:IsStatusBanned()
  if self.bStatusVisible then
    statusInstance:OnExecute()
  end
  if statusConf.max_duration > 0 then
    self.DelayHandler = _G.DelayManager:DelaySeconds(statusConf.max_duration / 1000 + 3, function()
      self:RemoveStatus(statusId, false)
      self.DelayHandler = nil
    end)
  end
end

function AbnormalStatusComponent:RemoveStatus(statusId, bForce)
  local statusInstance = self.ActiveStatus[statusId]
  if not statusInstance then
    Log.Error("abnormal status not active!")
    return
  end
  statusInstance:OnRemove(bForce)
  self.ActiveStatus[statusId] = nil
end

function AbnormalStatusComponent:RemoveAllStatus(bForce)
  for _, statusInstance in pairs(self.ActiveStatus) do
    statusInstance:OnRemove(bForce)
  end
  self.ActiveStatus = {}
  if self.DelayHandler then
    _G.DelayManager:CancelDelay(self.DelayHandler)
    self.DelayHandler = nil
  end
end

function AbnormalStatusComponent:IsStatusActive(statusId)
  return self.ActiveStatus[statusId] ~= nil
end

function AbnormalStatusComponent:CanAddStatus(statusId)
  if self:IsStatusActive(statusId) then
    return false
  end
  local statusConf = _G.DataConfigManager:GetAbnormalStatusConf(statusId)
  if not statusConf then
    return false
  end
  local startTime = self.StartTimeMap[statusId]
  local currentTime = _G.ZoneServer:GetServerTime()
  if startTime and startTime > 0 and currentTime < startTime + statusConf.cooldown then
    return false
  end
  if self:IsStatusBanned() then
    return false
  end
  return true
end

function AbnormalStatusComponent:IsStatusVisible()
  local bIsLocal = self.owner and self.owner.isLocal
  if bIsLocal then
    for _, v in ipairs(self.HiddenLogicStatus) do
      if self.owner:IsLogicStatus(v) then
        return false
      end
    end
  end
  return true
end

function AbnormalStatusComponent:IsStatusBanned()
  if not self.owner then
    return true
  end
  for _, v in ipairs(self.BannedLogicStatus) do
    if self.owner:IsLogicStatus(v) then
      return true
    end
  end
  return false
end

function AbnormalStatusComponent:BindEvents()
  if self.owner and self.owner.isLocal then
    self.owner:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  end
end

function AbnormalStatusComponent:UnbindEvents()
  if self.owner and self.owner.isLocal then
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  end
end

function AbnormalStatusComponent:OnLogicStatusUpdated(owner, ChangeInfo)
  if not ChangeInfo or not ChangeInfo.changed_status then
    return
  end
  local bVisible = self:IsStatusVisible() and not self:IsStatusBanned()
  if bVisible ~= self.bStatusVisible then
    if bVisible then
      self:ShowAllHiddenStatus()
    else
      self:HideAllActiveStatus()
    end
  end
end

function AbnormalStatusComponent:HideAllActiveStatus()
  self.bStatusVisible = false
  for _, statusInstance in pairs(self.ActiveStatus) do
    statusInstance:OnRemove(true)
  end
end

function AbnormalStatusComponent:ShowAllHiddenStatus()
  self.bStatusVisible = true
  for _, statusInstance in pairs(self.ActiveStatus) do
    statusInstance:OnExecute()
  end
end

return AbnormalStatusComponent
