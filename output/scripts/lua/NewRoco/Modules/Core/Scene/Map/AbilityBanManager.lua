local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityBanManager = _G.MakeSimpleClass("MagicBanManager")

function AbilityBanManager:Ctor()
  self.CurrentAreaIds = {}
  self.MagicBanInfos = {}
  self.RolePlayPropBanInfos = {}
  self:InitFromDataConfig()
end

function AbilityBanManager:InitFromDataConfig()
  local allRoleplayPropIds = {}
  local roleplayPropConfs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.ROLEPLAY_PROP_CONF)
  for _, roleplayPropConf in pairs(roleplayPropConfs) do
    if not roleplayPropConf then
    else
      local roleplayPropId = roleplayPropConf.id
      table.insert(allRoleplayPropIds, roleplayPropId)
    end
  end
  local areaFuncConfs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.AREA_FUNC_CONF)
  for _, areaFuncConf in pairs(areaFuncConfs) do
    if not areaFuncConf then
    else
      local areaIds = areaFuncConf.area_id
      if areaIds then
        local area_ban_magic = areaFuncConf.area_ban_magic
        local ban_roleplay_tools = areaFuncConf.ban_roleplay_tools
        for _, areaId in pairs(areaIds) do
          self:InsertMagicBan(areaId, area_ban_magic)
          self:InsertRolePlayPropBan(areaId, ban_roleplay_tools, allRoleplayPropIds)
        end
      end
    end
  end
end

function AbilityBanManager:Destruct()
end

function AbilityBanManager:OnEnterArea(areaId)
  if not areaId then
    return
  end
  if self.CurrentAreaIds[areaId] then
    return
  end
  Log.Debug("AbilityBanManager:OnEnterArea", areaId)
  self.CurrentAreaIds[areaId] = true
  self:CheckMagicOnEnterArea(areaId)
  self:CheckRolePlayPropOnEnterArea(areaId)
end

function AbilityBanManager:OnExitArea(areaId)
  if not areaId then
    return
  end
  if not self.CurrentAreaIds[areaId] then
    return
  end
  Log.Debug("AbilityBanManager:OnExitArea", areaId)
  self:CheckMagicOnExitArea(areaId)
  self:CheckRolePlayPropOnExitArea(areaId)
  self.CurrentAreaIds[areaId] = nil
end

function AbilityBanManager:OnPlayerTeleport()
  if not self.CurrentAreaIds then
    return
  end
  Log.Debug("AbilityBanManager:OnPlayerTeleport")
  for areaId, _ in pairs(self.CurrentAreaIds) do
    self:OnExitArea(areaId)
  end
end

function AbilityBanManager:Init()
end

function AbilityBanManager:InsertMagicBan(areaId, banMagics)
  if not self.MagicBanInfos then
    return
  end
  if not banMagics then
    return
  end
  if 0 == #banMagics then
    return
  end
  for _, magicType in pairs(banMagics) do
    if not self.MagicBanInfos[magicType] then
      self.MagicBanInfos[magicType] = {
        SceneMagicType = magicType,
        AbilityID = AbilityID.GetAbilityIdFromSceneMagicType(magicType),
        BanAreaIds = {
          [areaId] = 0
        },
        BannedFlag = 0
      }
    else
      self.MagicBanInfos[magicType].BanAreaIds[areaId] = table.getTableCount(self.MagicBanInfos[magicType].BanAreaIds)
    end
    Log.Debug("AbilityBanManager:InsertMagicBan", magicType, areaId)
  end
end

function AbilityBanManager:DumpMagicBanInfo(Info)
  if not Info then
    return
  end
  return string.format("%s - %s", table.getKeyName(ProtoEnum.SceneMagicType, Info.SceneMagicType), table.getKeyName(AbilityID, Info.AbilityID))
end

function AbilityBanManager:CheckMagicOnEnterArea(areaId)
  if not self.MagicBanInfos then
    return
  end
  for _, magicBanInfo in pairs(self.MagicBanInfos) do
    local bBannedBefore = magicBanInfo.BannedFlag > 0
    local index = magicBanInfo.BanAreaIds[areaId]
    if index then
      local flag = 1 << index
      if 0 == magicBanInfo.BannedFlag & flag then
        magicBanInfo.BannedFlag = magicBanInfo.BannedFlag + flag
      end
    end
    local bBannedAfter = magicBanInfo.BannedFlag > 0
    if bBannedBefore and not bBannedAfter then
      self:OnMagicAllowed(magicBanInfo)
    elseif not bBannedBefore and bBannedAfter then
      self:OnMagicBanned(magicBanInfo)
    end
  end
end

function AbilityBanManager:CheckMagicOnExitArea(areaId)
  if not self.MagicBanInfos then
    return
  end
  for _, magicBanInfo in pairs(self.MagicBanInfos) do
    local bBannedBefore = magicBanInfo.BannedFlag > 0
    local index = magicBanInfo.BanAreaIds[areaId]
    if index then
      local flag = 1 << index
      if magicBanInfo.BannedFlag & flag then
        magicBanInfo.BannedFlag = magicBanInfo.BannedFlag - flag
      end
    end
    local bBannedAfter = magicBanInfo.BannedFlag > 0
    if bBannedBefore and not bBannedAfter then
      self:OnMagicAllowed(magicBanInfo)
    elseif not bBannedBefore and bBannedAfter then
      self:OnMagicBanned(magicBanInfo)
    end
  end
end

function AbilityBanManager:OnMagicBanned(Info)
  if not Info then
    return
  end
  Log.Debug("AbilityBanManager:OnMagicBanned", self:DumpMagicBanInfo(Info))
  local helper = AbilityHelperManager.GetHelper(Info.AbilityID)
  if helper then
    helper.bBannedByArea = true
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RefreshLocalPlayerAbilities)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  if not localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    return
  end
  local abilityComponent = localPlayer.abilityComponent
  if not abilityComponent then
    return
  end
  local currentAbility = abilityComponent._currentAbility
  if not currentAbility then
    return
  end
  if currentAbility.helper ~= helper then
    return
  end
  Log.Debug("AbilityBanManager:OnMagicBanned Magic is casting, cancel", Info.AbilityID)
  localPlayer:SendEvent(PlayerModuleEvent.ON_END_THROW, false)
  localPlayer.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
end

function AbilityBanManager:OnMagicAllowed(Info)
  if not Info then
    return
  end
  Log.Debug("AbilityBanManager:OnMagicAllowed", self:DumpMagicBanInfo(Info))
  local helper = AbilityHelperManager.GetHelper(Info.AbilityID)
  if helper then
    helper.bBannedByArea = false
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RefreshLocalPlayerAbilities)
end

function AbilityBanManager:GetMagicIsBannedInArea(SceneMagicType, AreaId)
  if not self.MagicBanInfos then
    return false
  end
  local Info = self.MagicBanInfos[SceneMagicType]
  if not Info then
    return false
  end
  return Info.BanAreaIds[AreaId]
end

function AbilityBanManager:GetMagicIsBannedInAreas(SceneMagicType, AreaIds)
  if not self.MagicBanInfos then
    return false
  end
  local Info = self.MagicBanInfos[SceneMagicType]
  if not Info then
    return false
  end
  for _, AreaId in pairs(AreaIds) do
    if Info.BanAreaIds[AreaId] then
      return true, AreaId
    end
  end
  return false
end

function AbilityBanManager:GetMagicIsBannedInAreasTArray(SceneMagicType, AreaIds)
  if not self.MagicBanInfos then
    return false
  end
  local Info = self.MagicBanInfos[SceneMagicType]
  if not Info then
    return false
  end
  for _, AreaId in tpairs(AreaIds) do
    if Info.BanAreaIds[AreaId] then
      return true, AreaId
    end
  end
  return false
end

function AbilityBanManager:InsertRolePlayPropBan(areaId, banRolePlayProps, allRoleplayPropIds)
  if not self.RolePlayPropBanInfos then
    return
  end
  if not banRolePlayProps then
    return
  end
  if 0 == #banRolePlayProps then
    return
  end
  
  local function insert(rolePlayPropId)
    if not self.RolePlayPropBanInfos[rolePlayPropId] then
      self.RolePlayPropBanInfos[rolePlayPropId] = {
        Id = rolePlayPropId,
        BanAreaIds = {
          [areaId] = 0
        },
        BannedFlag = 0
      }
    else
      self.RolePlayPropBanInfos[rolePlayPropId].BanAreaIds[areaId] = table.getTableCount(self.RolePlayPropBanInfos[rolePlayPropId].BanAreaIds)
    end
    Log.Debug("AbilityBanManager:InsertRolePlayPropBan", rolePlayPropId, areaId)
  end
  
  for _, rolePlayPropId in pairs(banRolePlayProps) do
    if -1 == rolePlayPropId then
      if allRoleplayPropIds then
        for _, id in pairs(allRoleplayPropIds) do
          insert(id)
        end
      end
      break
    end
    insert(rolePlayPropId)
  end
end

function AbilityBanManager:CheckRolePlayPropOnEnterArea(areaId)
  if not self.RolePlayPropBanInfos then
    return
  end
  for _, rolePlayPropBanInfo in pairs(self.RolePlayPropBanInfos) do
    local bBannedBefore = rolePlayPropBanInfo.BannedFlag > 0
    local index = rolePlayPropBanInfo.BanAreaIds[areaId]
    if index then
      local flag = 1 << index
      if 0 == rolePlayPropBanInfo.BannedFlag & flag then
        rolePlayPropBanInfo.BannedFlag = rolePlayPropBanInfo.BannedFlag + flag
      end
    end
    local bBannedAfter = rolePlayPropBanInfo.BannedFlag > 0
    if bBannedBefore ~= bBannedAfter then
      self:OnRolePlayPropBannedChanged(rolePlayPropBanInfo)
    end
  end
end

function AbilityBanManager:CheckRolePlayPropOnExitArea(areaId)
  if not self.RolePlayPropBanInfos then
    return
  end
  for _, rolePlayPropBanInfo in pairs(self.RolePlayPropBanInfos) do
    local bBannedBefore = rolePlayPropBanInfo.BannedFlag > 0
    local index = rolePlayPropBanInfo.BanAreaIds[areaId]
    if index then
      local flag = 1 << index
      if rolePlayPropBanInfo.BannedFlag & flag then
        rolePlayPropBanInfo.BannedFlag = rolePlayPropBanInfo.BannedFlag - flag
      end
    end
    local bBannedAfter = rolePlayPropBanInfo.BannedFlag > 0
    if bBannedBefore ~= bBannedAfter then
      self:OnRolePlayPropBannedChanged(rolePlayPropBanInfo)
    end
  end
end

function AbilityBanManager:OnRolePlayPropBannedChanged(Info)
  Log.Debug("AbilityBanManager:OnRolePlayPropBannedChanged", Info.Id, Info.BannedFlag)
  _G.NRCEventCenter:DispatchEvent(SceneEvent.OnRolePlayPropsBanStateChanged, Info.Id, Info.BannedFlag > 0)
end

function AbilityBanManager:GetRolePlayPropsIsBan(id)
  if not self.RolePlayPropBanInfos then
    return false
  end
  local Info = self.RolePlayPropBanInfos[id]
  if not Info then
    return false
  end
  return Info.BannedFlag > 0
end

function AbilityBanManager:GetPropsIsBannedInArea(PropId, AreaId)
  if not self.RolePlayPropBanInfos then
    return false
  end
  local Info = self.RolePlayPropBanInfos[PropId]
  if not Info then
    return false
  end
  return Info.BanAreaIds[AreaId]
end

function AbilityBanManager:GetPropsIsBannedInAreas(PropId, AreaIds)
  if not self.RolePlayPropBanInfos then
    return false
  end
  local Info = self.RolePlayPropBanInfos[PropId]
  if not Info then
    return false
  end
  for _, AreaId in pairs(AreaIds) do
    if Info.BanAreaIds[AreaId] then
      return true, AreaId
    end
  end
  return false
end

function AbilityBanManager:GetPropsIsBannedInAreasTArray(PropId, AreaIds)
  if not self.RolePlayPropBanInfos then
    return false
  end
  local Info = self.RolePlayPropBanInfos[PropId]
  if not Info then
    return false
  end
  for _, AreaId in tpairs(AreaIds) do
    if Info.BanAreaIds[AreaId] then
      return true, AreaId
    end
  end
  return false
end

return AbilityBanManager
