local RolePlayModuleData = _G.NRCData:Extend("RolePlayModuleData")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")

local function GetRoleplayGroupInfo(Conf)
  local star = Conf.star
  if star then
    return star[1], star[2]
  end
  return nil, nil
end

local function BuildRolePlayItemConf(_rolePlayType, _id, _customData)
  local conf = _G.DataConfigManager:GetRoleplayBehaviorConf(_id)
  if conf then
    local isValidItem = false
    if _rolePlayType == RolePlayModuleDef.RolePlayType.Action then
      isValidItem = conf.behavior_type == Enum.BehaviorType.BT_EMONTIONAL_EMOTE or conf.behavior_type == Enum.BehaviorType.BT_INFORMATION_EMOTE
    elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Sound then
      isValidItem = conf.behavior_type == Enum.BehaviorType.BT_CALL
    elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
      isValidItem = true
    end
    if isValidItem then
      local skillResId = conf.male_skill_id or conf.female_skill_id
      isValidItem = not string.IsNilOrEmpty(skillResId)
    end
    if isValidItem then
      local _itemConf = {}
      _itemConf.sortId = conf.ui_order or 0
      _itemConf.type = _rolePlayType
      _itemConf.value = conf.id
      _itemConf.customData = _customData
      _itemConf.rpType = conf.RPbehavior_type
      local group, star = GetRoleplayGroupInfo(conf)
      _itemConf.group = group
      _itemConf.star = star
      return _itemConf
    end
  end
end

local function CompareRolePlayItemConf(a, b)
  if a.sortId == b.sortId then
    return a.value < b.value
  end
  return a.sortId < b.sortId
end

function RolePlayModuleData:Ctor()
  NRCData.Ctor(self)
  self.joystickProtectTime = _G.DataConfigManager:GetGlobalConfigByKeyType("roleplay_joystick_protect_time", _G.DataConfigManager.ConfigTableId.ROLE_GLOBAL_CONFIG).num
  self.newGetBehaviors = {}
  self.hiddenSuitTipsIds = {}
  self:BuildFashionIdToGoodsIdMap()
  self.newCollectSuit = {}
  self.nextPutPropTime = 0
  self.inPutPropNpcId = 0
  self.inRecycleNpcId = 0
  self.curPutPropNpcId = -1
  self.propItemConfMap = {}
  self:InitPropItemConf()
  self.nextFrequentlyTipsTime = 0
  self:BuildRolePlayItemConfGroup()
end

function RolePlayModuleData:BuildRolePlayItemConfGroup()
  local DataTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ROLEPLAY_BEHAVIOR_CONF):GetAllDatas()
  local GroupTable = {}
  for k, v in pairs(DataTable) do
    local GroupId, Star = GetRoleplayGroupInfo(v)
    if GroupId then
      local Group = GroupTable[GroupId]
      if not Group then
        Group = {}
        GroupTable[GroupId] = Group
        table.insert(Group, v)
      else
        local i = #Group
        while i > 1 do
          local j = i
          local Test = Group[j]
          local TestGroupId, TestStar = GetRoleplayGroupInfo(Test)
          if Star >= TestStar then
            break
          end
          i = i - 1
        end
        table.insert(Group, i, v)
      end
    end
  end
  self.RolePlayItemGroup = GroupTable
end

function RolePlayModuleData:GetGroupByRoleplayConf(Conf)
  if Conf then
    local GroupId = GetRoleplayGroupInfo(Conf)
    if GroupId then
      return self.RolePlayItemGroup[GroupId]
    end
  end
end

function RolePlayModuleData:GetGroupInfoByType(Type)
  local Conf = self:GetRolePlayConfByBehaviorType(Type)
  if Conf then
    return GetRoleplayGroupInfo(Conf)
  end
  return nil, nil
end

function RolePlayModuleData:CreateLockedRoleplayAction(Conf)
  local _itemConf = Conf and BuildRolePlayItemConf(RolePlayModuleDef.RolePlayType.Action, Conf.id)
  _itemConf.customData = {bLocked = true}
  return _itemConf
end

function RolePlayModuleData:GetDisplayRolePlayMap()
  local UsingTypeList = _G.DataModelMgr.PlayerDataModel:GetUsingRolePlayList()
  local AllTypeList = _G.DataModelMgr.PlayerDataModel:GetRolePlayList()
  local GroupToUsingMap = {}
  local DisplayTypeMap = {}
  for _, Type in pairs(UsingTypeList) do
    local Conf = self:GetRolePlayConfByBehaviorType(Type)
    if Conf then
      local GroupId = GetRoleplayGroupInfo(Conf)
      if GroupId then
        if GroupToUsingMap[GroupId] then
          Log.Error("logical error, duplicate type with same group used", Type, GroupId)
        end
        GroupToUsingMap[GroupId] = Conf
        DisplayTypeMap[Type] = Conf
      else
        Log.Error("invalid, cannot found group, but mark using", Type)
      end
    end
  end
  local DefaultGroupConfList = {}
  for _, Type in pairs(AllTypeList) do
    local Conf = self:GetRolePlayConfByBehaviorType(Type)
    if Conf then
      local GroupId = GetRoleplayGroupInfo(Conf)
      if GroupId then
        if not GroupToUsingMap[GroupId] then
          table.insert(DefaultGroupConfList, Conf)
        end
      else
        DisplayTypeMap[Type] = Conf
      end
    end
  end
  table.sort(DefaultGroupConfList, function(a, b)
    local _, Star1 = GetRoleplayGroupInfo(a)
    local _, Star2 = GetRoleplayGroupInfo(b)
    return Star1 < Star2
  end)
  for i = #DefaultGroupConfList, 1, -1 do
    local Conf = DefaultGroupConfList[i]
    local GroupId = GetRoleplayGroupInfo(Conf)
    local Using = GroupToUsingMap[GroupId]
    if not Using then
      local Type = Conf.RPbehavior_type
      GroupToUsingMap[GroupId] = Conf
      DisplayTypeMap[Type] = Conf
    end
  end
  return DisplayTypeMap
end

function RolePlayModuleData:IsRolePlayItemTypeUsingInGroup(Type)
  local UsingTypeList = _G.DataModelMgr.PlayerDataModel:GetUsingRolePlayList()
  if UsingTypeList then
    return Type and table.contains(UsingTypeList, Type)
  end
  return false
end

function RolePlayModuleData:InitPropItemConf()
  local allPropItemConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ROLEPLAY_PROP_CONF)
  for i, v in pairs(allPropItemConf) do
    self.propItemConfMap[i] = v
  end
end

function RolePlayModuleData:AddNewGetBehaviors(_id)
  if not self.newGetBehaviors[_id] then
    self.newGetBehaviors[_id] = true
    return true
  end
  return false
end

function RolePlayModuleData:GetRolePlayConfByBehaviorType(_type)
  if self.behaviorTypeQuery == nil then
    self.behaviorTypeQuery = {}
    local allRolePlayConf = _G.DataConfigManager:GetAllByName("ROLEPLAY_BEHAVIOR_CONF")
    for _, _conf in pairs(allRolePlayConf) do
      self.behaviorTypeQuery[_conf.RPbehavior_type] = _conf
    end
  end
  return _type and self.behaviorTypeQuery[_type]
end

function RolePlayModuleData:GetRolePlayData(_rolePlayType, _customData)
  local rolePlayItems = {}
  rolePlayItems.type = _rolePlayType
  if _rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo and fashionInfo.wardrobe_data then
      local curWardrobeIndex = (fashionInfo.current_wardrobe_index or 0) + 1
      for i, _v in ipairs(fashionInfo.wardrobe_data) do
        local bHasData = _v.wearing_item ~= nil and next(_v.wearing_item) or nil ~= _v.salon_item_wear_id and next(_v.salon_item_wear_id)
        if bHasData then
          local _itemConf = {}
          _itemConf.type = _rolePlayType
          _itemConf.value = _v
          _itemConf.suitType = "custom"
          _itemConf.wardrobeIndex = i
          _itemConf.bSelected = curWardrobeIndex == i
          table.insert(rolePlayItems, _itemConf)
        end
      end
    end
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
    local fashionRelaxData = _customData
    if fashionRelaxData then
      for petGid, relaxRolePlayId in pairs(fashionRelaxData) do
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
        local _itemConf = BuildRolePlayItemConf(_rolePlayType, relaxRolePlayId, petData)
        if _itemConf then
          table.insert(rolePlayItems, _itemConf)
        end
      end
      table.sort(rolePlayItems, CompareRolePlayItemConf)
    end
  elseif _rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    for i, conf in pairs(self.propItemConfMap) do
      if conf.is_initial_unlock then
        local _itemConf = {}
        _itemConf.type = _rolePlayType
        _itemConf.value = conf.id
        _itemConf.bSelected = conf.id == self.inPutPropNpcId or conf.id == self.curPutPropNpcId
        _itemConf.customData = {}
        _itemConf.customData.nextCanPlacePropsTime = self.nextPutPropTime
        table.insert(rolePlayItems, _itemConf)
      end
    end
    local _unlockRolePlays = _G.DataModelMgr.PlayerDataModel:GetRolePlayList()
    if _unlockRolePlays then
      for _, _unlockType in ipairs(_unlockRolePlays) do
        local unlockConf = self:GetRolePlayConfByBehaviorType(_unlockType)
        if unlockConf and unlockConf.behavior_type == Enum.BehaviorType.BT_PROP then
          local _itemConf = {}
          _itemConf.type = _rolePlayType
          _itemConf.value = unlockConf.id
          _itemConf.bSelected = unlockConf.id == self.inPutPropNpcId or unlockConf.id == self.curPutPropNpcId
          _itemConf.customData = {}
          _itemConf.customData.nextCanPlacePropsTime = self.nextPutPropTime
          table.insert(rolePlayItems, _itemConf)
        end
      end
    end
    table.sort(rolePlayItems, CompareRolePlayItemConf)
  else
    local rolePlayId = {}
    table.copy(self.newGetBehaviors, rolePlayId)
    local _unlockRolePlays = _G.DataModelMgr.PlayerDataModel:GetRolePlayList()
    if _unlockRolePlays then
      for _, _unlockType in ipairs(_unlockRolePlays) do
        local unlockConf = self:GetRolePlayConfByBehaviorType(_unlockType)
        if unlockConf then
          rolePlayId[unlockConf.id] = true
        end
      end
    end
    for _id, _ in pairs(rolePlayId) do
      local _itemConf = BuildRolePlayItemConf(_rolePlayType, _id)
      if _itemConf then
        table.insert(rolePlayItems, _itemConf)
      end
    end
    table.sort(rolePlayItems, CompareRolePlayItemConf)
  end
  return rolePlayItems
end

function RolePlayModuleData:BuildFashionIdToGoodsIdMap()
  local fashionGoodsTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NORMAL_SHOP_CONF)
  local fashionGoodsData = fashionGoodsTable:GetAllDatas()
  self.FashionIdToGoodsIdMap = {}
  for _, conf in pairs(fashionGoodsData) do
    self.FashionIdToGoodsIdMap[conf.item_id] = conf
  end
end

function RolePlayModuleData:AddHiddenSuitTipsId(suitId)
  if suitId then
    self.hiddenSuitTipsIds[suitId] = true
  end
end

function RolePlayModuleData:RemoveHiddenSuitTipsId(suitId)
  if suitId then
    self.hiddenSuitTipsIds[suitId] = nil
  end
end

function RolePlayModuleData:CheckAndRemoveHiddenSuitTipsId(suitId)
  if suitId and self.hiddenSuitTipsIds[suitId] then
    self.hiddenSuitTipsIds[suitId] = nil
    return true
  end
  return false
end

return RolePlayModuleData
