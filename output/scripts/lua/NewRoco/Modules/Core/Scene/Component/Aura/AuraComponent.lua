local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local AuraObject = require("NewRoco.Modules.Core.Scene.Component.Aura.AuraObject")
local FieldTagManager = require("NewRoco.Modules.Core.Scene.Common.FieldTagManager")
local Base = ActorComponent
local AuraComponent = Base:Extend("AuraComponent")

function AuraComponent:Attach(owner)
  Base.Attach(self, owner)
  self.Auras = {}
  self.FieldTagManager = FieldTagManager()
  self.bIsAuraInitialized = false
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAck, self.InitAuras)
end

function AuraComponent:DeAttach()
  self:ClearAuras()
  Base.DeAttach(self)
end

function AuraComponent:UpdateData(ServerData, isReconnect)
  if ServerData then
    self:UpdateAuras(ServerData.aura_infos)
  end
end

function AuraComponent:InitAuras()
  if self.bIsAuraInitialized then
    return
  end
  self.bIsAuraInitialized = true
  local serverData = self.owner.serverData
  local AuraInfos = serverData.aura_infos
  if AuraInfos and #AuraInfos > 0 then
    for _, Info in ipairs(AuraInfos) do
      self:MakeAura(Info)
    end
  end
end

function AuraComponent:UpdateAuras(aura_infos)
  for _, aura in pairs(self.Auras) do
    if aura then
      aura.pendingKill = true
    end
  end
  if aura_infos and #aura_infos > 0 then
    for _, info in pairs(aura_infos) do
      self:UpdateAura(info)
      local aura = self.Auras[info.id]
      if aura then
        aura.pendingKill = false
      end
    end
  end
  for id, aura in pairs(self.Auras) do
    if aura and aura.pendingKill then
      aura:Destroy()
      self.Auras[id] = nil
    end
  end
end

function AuraComponent:MakeAura(Info)
  local Aura = AuraObject(self, Info)
  if not Aura then
    Log.Error("AuraComponent:MakeAura can't find proper aura")
    Log.Dump(Info, 2, "Invalid Aura Info")
    return
  end
  Aura.bRestored = true
  self.Auras[Info.id] = Aura
  Aura:UpdateInfo(Info)
end

function AuraComponent:UpdateAura(Info)
  local Aura = self.Auras[Info.id]
  if Aura then
    Aura:UpdateInfo(Info)
  else
    self:AddAura(Info)
  end
end

function AuraComponent:AddAura(Info)
  local VisibleList = Info and Info.avatar_white_list
  if VisibleList and #VisibleList > 0 then
    local UIN = _G.PlayerModuleCmd and _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    if not table.contains(VisibleList, UIN) then
      Log.Debug("AuraComponent:AddAura local player not in visible list, skip add", Info.id, Info.aura_conf_id)
      return nil
    end
  end
  local Aura = AuraObject(self, Info)
  if not Aura then
    Log.Error("AuraComponent:AddAura can't find proper aura")
    Log.Dump(Info, 2, "Invalid Aura Info")
    return nil
  end
  Info.enabled = true
  self.Auras[Info.id] = Aura
  Aura.bRestored = false
  Aura:OnAdd()
  return Aura
end

function AuraComponent:RemoveAura(RemoveInfo)
  local id = RemoveInfo.aura_id
  local Aura = self.Auras[id]
  local Killer
  if RemoveInfo.reason == ProtoEnum.RemoveAuraReason.DAR_MUTEX then
    Killer = self.Auras[RemoveInfo.mutex_aura_id[1]]
  end
  if Aura then
    Aura:OnRemove(Killer, RemoveInfo)
    self.Auras[id] = nil
  elseif Killer then
    local Victim = _G.DataConfigManager:GetNpcAuraConf(RemoveInfo.create_info.conf_id)
    Killer:OnRemoveOther(Victim, RemoveInfo)
  else
    Log.Error("Can't find aura with id", id)
  end
end

function AuraComponent:UpdateByAction(Action)
  if not Action then
    return
  end
  if Action.aura_info then
    for _, Info in ipairs(Action.aura_info) do
      self:UpdateAura(Info)
    end
  end
  if Action.removed_auras then
    for _, Removed in ipairs(Action.removed_auras) do
      self:RemoveAura(Removed)
    end
  end
end

function AuraComponent:UpdateFieldTag(Action)
  Log.Debug("Getting SpaceAct_FieldTagChange", Action.aura_id or "0")
  self.FieldTagManager:Update(Action)
end

function AuraComponent:SumEffect(EffectType)
  local Count = 0
  local Temperature = 0
  for _, Aura in pairs(self.Auras) do
    local Params = Aura:GetEffectParams(EffectType)
    if Params and Aura:InRange(self.owner) then
      Temperature = Temperature + (Params[1] or 0)
      Count = Count + 1
    end
  end
  if 0 == Count then
    return 0
  end
  return Temperature / Count
end

function AuraComponent:GetTemperature()
  local Val = self:SumEffect(Enum.AuraEffect.AE_SET_TEMP)
  if Val > 0 then
    return Val, Enum.AuraEffect.AE_SET_TEMP
  end
  return self:SumEffect(Enum.AuraEffect.AE_CHANGE_TEMP), Enum.AuraEffect.AE_CHANGE_TEMP
end

function AuraComponent:Destroy()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.InitAuras)
  for _, Aura in pairs(self.Auras) do
    Aura:Destroy()
  end
  table.clear(self.Auras)
  Base.Destroy(self)
end

function AuraComponent:GetAuraByID(id)
  if not id then
    return nil
  end
  return self.Auras[id]
end

function AuraComponent:GetAuraByEffectType(EffectType)
  local Ret = {}
  for _, Aura in pairs(self.Auras) do
    if Aura:HasEffect(EffectType) then
      table.insert(Ret, Aura)
    end
  end
  return Ret
end

function AuraComponent:HasEffectOnActor(EffectType, ActorID)
  if not EffectType then
    return false
  end
  if not ActorID then
    return false
  end
  if 0 == ActorID then
    return false
  end
  for _, Aura in pairs(self.Auras) do
    if Aura.Info.belong_actor_id == ActorID and Aura:HasEffect(EffectType) then
      return true
    end
  end
  return false
end

function AuraComponent:ClearAuras()
  self.bIsAuraInitialized = false
  for _, Aura in pairs(self.Auras) do
    Aura:Destroy()
  end
  table.clear(self.Auras)
end

function AuraComponent:OnReConnect()
  self:UpdateAuras(self.owner.serverData.aura_infos)
end

return AuraComponent
