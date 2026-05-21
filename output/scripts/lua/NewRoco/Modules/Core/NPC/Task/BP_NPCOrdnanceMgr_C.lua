local ViewNPCBase = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local Base = ViewNPCBase
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local BP_NPCOrdnanceMgr_C = Base:Extend("BP_NPCOrdnanceMgr_C")

function BP_NPCOrdnanceMgr_C:OnLoadResource()
  Base.OnLoadResource(self)
  _G.UpdateManager:Register(self)
  self.LastTime = 0
  self.Ordnance = {}
  self.SelectedOrdnance = {}
  self.sceneCharacter:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusChanged)
  local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
  self.sceneCharacter:EnsureComponent(LogicStatusComponent)
  if self.sceneCharacter:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_ON) then
    self.StartFlag = true
  end
  for num in string.gmatch(self.Ordnances, "%d+") do
    table.insert(self.Ordnance, tonumber(num))
  end
  self:RefillPool()
end

function BP_NPCOrdnanceMgr_C:RefillPool()
  self.SelectedOrdnance = {}
  for _, id in ipairs(self.Ordnance) do
    table.insert(self.SelectedOrdnance, id)
  end
end

function BP_NPCOrdnanceMgr_C:PlayNextOrdnance()
  if 0 == #self.SelectedOrdnance then
    self:RefillPool()
  end
  local idx = math.random(1, #self.SelectedOrdnance)
  local npcID = self.SelectedOrdnance[idx]
  table.remove(self.SelectedOrdnance, idx)
  local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, npcID)
  if NPC and NPC.viewObj then
    NPC.viewObj:ExcuteAction()
  end
end

function BP_NPCOrdnanceMgr_C:StartOrdnance()
  self:RefillPool()
  self.StartFlag = true
end

function BP_NPCOrdnanceMgr_C:OnTick()
  if not self.StartFlag then
    return
  end
  local CurTime = _G.ZoneServer:GetServerTime() / 1000
  if 0 == self.LastTime then
    self.LastTime = CurTime
    self:PlayNextOrdnance()
  elseif CurTime - self.LastTime >= self.interval_time then
    self.LastTime = CurTime
    self:PlayNextOrdnance()
  end
end

function BP_NPCOrdnanceMgr_C:StopOrdnance()
  self.LastTime = 0
  self.StartFlag = false
end

function BP_NPCOrdnanceMgr_C:OnLogicStatusChanged(owner, changeInfo)
  if changeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_ADD or changeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_UPDATE then
    local statusInfo = changeInfo.changed_status
    if statusInfo.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_OFF then
      self:StopOrdnance()
    elseif statusInfo.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_ON then
      self:StartOrdnance()
    end
  end
end

function BP_NPCOrdnanceMgr_C:Destruct()
  _G.UpdateManager:UnRegister(self)
  self.sceneCharacter:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnStatusChanged)
  self.LastTime = 0
  self.StartFlag = false
end

return BP_NPCOrdnanceMgr_C
