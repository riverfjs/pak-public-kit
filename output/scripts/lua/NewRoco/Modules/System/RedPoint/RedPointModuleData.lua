local RedPointUtils = require("NewRoco.Modules.System.RedPoint.RedPointUtils")
local RedPointModuleData = _G.NRCData:Extend("RedPointModuleData")

function RedPointModuleData:Ctor()
  NRCData.Ctor(self)
  self.RedPointUIDic = {}
  self.InvalidPointDataList = {}
  self.InvalidedKeyAndExtraKeyTable = {}
end

function RedPointModuleData:InitFromPlayerData()
  if self.hasInitFromPlayerData then
    Log.Debug("\233\135\141\232\191\158\239\188\140\233\135\141\230\150\176\230\155\180\230\150\176\229\133\168\233\135\143\231\154\132\230\149\176\230\141\174")
  end
  local rpCfgs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.RED_POINT_CONF):GetAllDatas()
  self.rpCfgs = rpCfgs
  self.RedPointNodeDic = {}
  self.ReasonToRpNodesDic = {}
  local redPointNodeDic = self.RedPointNodeDic
  local reasonToRpNodesDic = self.ReasonToRpNodesDic
  for key, cfg in pairs(rpCfgs) do
    if nil == redPointNodeDic[key] then
      redPointNodeDic[key] = {}
    end
    redPointNodeDic[key].key = key
    redPointNodeDic[key].cfg = cfg
    redPointNodeDic[key].redCount = 0
    redPointNodeDic[key].litUpReasonDic = {}
    redPointNodeDic[key].litUpRootDic = {}
    redPointNodeDic[key].popReasonDic = {}
    redPointNodeDic[key].popFromDic = {}
    redPointNodeDic[key].redPointTypeTable = {}
    for _, child_id in ipairs(cfg.child_id) do
      if nil == redPointNodeDic[child_id] then
        redPointNodeDic[child_id] = {}
      end
      if not redPointNodeDic[child_id].parent then
        redPointNodeDic[child_id].parent = {}
        table.insert(redPointNodeDic[child_id].parent, redPointNodeDic[key])
      else
        table.insert(redPointNodeDic[child_id].parent, redPointNodeDic[key])
      end
    end
    for _, reason in ipairs(cfg.change_reason) do
      if nil == reasonToRpNodesDic[reason] then
        reasonToRpNodesDic[reason] = {}
      end
      table.insert(reasonToRpNodesDic[reason], redPointNodeDic[key])
    end
  end
  self:InitReasonToAffectedParentKeysMap()
  local redPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  if nil == redPointInfo then
    Log.Error("PlayerDataModel:GetRedPointInfo \229\144\142\231\171\175\230\178\161\230\156\137red_point_info\229\173\151\230\174\181")
    return
  end
  for _, group in ipairs(redPointInfo) do
    self:UpdateRedPointData(group.reason_type, group.point_data, true)
  end
  self.hasInitFromPlayerData = true
end

function RedPointModuleData:GetRedPointNodeDic()
  return self.RedPointNodeDic
end

function RedPointModuleData:GetReasonToRpNodesDic()
  return self.ReasonToRpNodesDic
end

function RedPointModuleData:InitReasonToAffectedParentKeysMap()
  local reasonToAffectedParentKeysMap = {}
  local redPointNodeDic = self.RedPointNodeDic
  local reasonToRpNodesDic = self.ReasonToRpNodesDic
  if not reasonToRpNodesDic or not redPointNodeDic then
    Log.Error("\231\186\162\231\130\185\230\149\176\230\141\174\230\156\170\229\136\157\229\167\139\229\140\150\239\188\140\232\175\183\229\133\136\232\176\131\231\148\168InitFromPlayerData")
    return reasonToAffectedParentKeysMap
  end
  local collectAllAncestorKeys = function(rpNode, keySet)
    if not (rpNode and rpNode.parent) or 0 == #rpNode.parent then
      return
    end
    for _, parentNode in ipairs(rpNode.parent) do
      local parentKey = parentNode.key
      if not keySet[parentKey] then
        keySet[parentKey] = true
        collectAllAncestorKeys(parentNode, keySet)
      end
    end
  end
  for reason, leafNodes in pairs(reasonToRpNodesDic) do
    local affectedParentKeySet = {}
    for _, leafNode in ipairs(leafNodes) do
      affectedParentKeySet[leafNode.key] = true
      collectAllAncestorKeys(leafNode, affectedParentKeySet)
    end
    reasonToAffectedParentKeysMap[reason] = affectedParentKeySet
  end
  self.ReasonToAffectedParentKeysMap = reasonToAffectedParentKeysMap
  return reasonToAffectedParentKeysMap
end

function RedPointModuleData:GetRedPointUIDic()
  return self.RedPointUIDic
end

function RedPointModuleData:RegRedPointUI(redPointUI)
  if nil == redPointUI then
    return
  end
  local rpNodeDic = self.RedPointNodeDic
  local rpUIDic = self.RedPointUIDic
  local key = redPointUI:GetKey()
  if nil == rpNodeDic or nil == rpNodeDic[key] then
    Log.Error("\230\179\168\229\134\140\228\186\134\228\184\170\233\133\141\231\189\174\233\135\140\230\178\161\230\156\137\231\154\132\231\186\162\231\130\185", key, redPointUI)
    return
  end
  if nil == rpUIDic[key] then
    rpUIDic[key] = {}
    WeakTable(rpUIDic[key])
  end
  redPointUI:SetRpNode(rpNodeDic[key])
  table.insert(rpUIDic[key], redPointUI)
end

function RedPointModuleData:UnRegRedPointUI(redPointUI)
  if nil == redPointUI then
    return
  end
  local rpUIDic = self.RedPointUIDic
  local key = redPointUI:GetKey()
  if nil == rpUIDic or nil == rpUIDic[key] then
    return
  end
  redPointUI:SetRpNode()
  local uis = rpUIDic[key]
  if uis and next(uis) then
    for k, ui in pairs(uis) do
      if ui == redPointUI then
        uis[k] = nil
      end
    end
  end
end

local function _UpdateOneRpNode(rpNode, reason, customPointData, isPopReason, fromKey, numInfo)
  if not isPopReason then
    rpNode.litUpReasonDic[reason] = customPointData
    rpNode.redPointTypeTable = {}
    local redpoint_type = rpNode.cfg.redpoint_type[1]
    table.insert(rpNode.redPointTypeTable, redpoint_type)
    rpNode.litUpRootDic = {}
    if customPointData and #customPointData.oriPointData > 0 then
      rpNode.litUpRootDic[reason] = rpNode.key
    end
    if numInfo and numInfo > 0 then
      rpNode.numInfoDic = rpNode.numInfoDic or {}
      rpNode.numInfoDic[reason] = numInfo
    elseif rpNode.numInfoDic then
      rpNode.numInfoDic[reason] = nil
    end
  else
    rpNode.popReasonDic[reason] = customPointData
    rpNode.popFromDic[reason] = fromKey
    rpNode.redPointTypeTable = {}
    if numInfo and numInfo > 0 then
      rpNode.popNumInfoDic = rpNode.popNumInfoDic or {}
      rpNode.popNumInfoDic[reason] = numInfo
    elseif rpNode.popNumInfoDic then
      rpNode.popNumInfoDic[reason] = nil
    end
    rpNode.litUpRootDic = {}
    local RedPointModule = NRCModuleManager:GetModule("RedPointModule")
    local RedPointNodeDic = RedPointModule.data:GetRedPointNodeDic()
    if RedPointNodeDic then
      for _, sonRedPointNodeKey in pairs(rpNode.popFromDic or {}) do
        if RedPointNodeDic[sonRedPointNodeKey] then
          local SonRedPointNode = RedPointNodeDic[sonRedPointNodeKey]
          if SonRedPointNode then
            for k, v in pairs(SonRedPointNode.litUpRootDic) do
              rpNode.litUpRootDic[k] = v
            end
          end
        end
      end
    end
  end
  local num = 0
  for _, p in pairs(rpNode.litUpReasonDic) do
    local pCount = p and #p.oriPointData or 0
    num = num + pCount
  end
  for _, p in pairs(rpNode.popReasonDic) do
    local pCount = p and #p.oriPointData or 0
    num = num + pCount
  end
  rpNode.redCount = num
  local totalNumInfo = 0
  if rpNode.numInfoDic then
    for _, nInfo in pairs(rpNode.numInfoDic) do
      totalNumInfo = totalNumInfo + (nInfo or 0)
    end
  end
  if rpNode.popNumInfoDic then
    for _, nInfo in pairs(rpNode.popNumInfoDic) do
      totalNumInfo = totalNumInfo + (nInfo or 0)
    end
  end
  rpNode.numInfo = totalNumInfo > 0 and totalNumInfo or nil
end

local function _contains(t, value)
  for _, v in pairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

local function _UpdatePointData(customPointData, newPointData, splitFunc)
  local a = customPointData.oriPointData
  local b = newPointData
  local splitPointData = customPointData.splitPointData
  for i = #a, 1, -1 do
    if not _contains(b, a[i]) then
      table.remove(a, i)
      if splitPointData and splitPointData[i] then
        table.remove(splitPointData, i)
      end
    end
  end
  for _, v in pairs(b) do
    if not _contains(a, v) then
      table.insert(a, v)
      if splitPointData then
        table.insert(splitPointData, splitFunc(v))
      end
    end
  end
end

function RedPointModuleData:UpdateRedPointData(reason, pointData, DataIsNewest)
  if nil == reason then
    return
  end
  self:CheckRedPointPlatform(pointData)
  local reasonToRpNodesDic = self.ReasonToRpNodesDic
  if nil == reasonToRpNodesDic then
    Log.Error("\231\186\162\231\130\185\229\142\159\229\155\160\229\173\151\229\133\184\231\188\186\229\164\177\239\188\140\233\157\158\230\173\163\229\184\184\230\131\133\229\134\181\239\188\140\232\175\183\232\129\148\231\179\187jobhaung")
    return
  end
  local rpNodes = reasonToRpNodesDic[reason]
  if nil == rpNodes then
    Log.Error("\230\137\190\228\184\141\229\136\176\232\191\153\228\184\170Reason\229\175\185\229\186\148\231\154\132\231\186\162\231\130\185\232\138\130\231\130\185, \230\163\128\230\159\165\228\184\139\232\161\168\233\135\140\231\154\132\229\143\182\229\173\144\232\138\130\231\130\185\230\156\137\230\178\161\230\156\137\233\133\141\228\184\138Reason", reason)
    return
  end
  local splitFunc = RedPointUtils.GetSplitFuncByReason(reason)
  if nil == pointData then
    pointData = {}
  end
  local numInfo = self:CheckPointDataHasNumInfo(pointData, reason)
  local customPointData = rpNodes[1].litUpReasonDic[reason]
  customPointData = {
    oriPointData = pointData,
    splitPointData = nil,
    splitFunc = splitFunc,
    DataIsNewest = DataIsNewest
  }
  for _, rpNode in ipairs(rpNodes) do
    _UpdateOneRpNode(rpNode, reason, customPointData, false, nil, numInfo)
    self:UpdateParentNode(rpNode, reason, customPointData, true, rpNode.key, true, numInfo)
  end
end

function RedPointModuleData:CheckRedPointPlatform(point_data)
  if not point_data then
    return
  end
  if not self.PLATFORM then
    self:SetPlatform()
  end
  for i, str in pairs(point_data) do
    local platformPattern = "#([0-9%|]+)"
    if type(str) == "string" then
      local platformInfo = str:match(platformPattern)
      if platformInfo then
        local platMatchFlag = false
        if platformInfo:match("^%d+$") then
          if self.PLATFORM == tonumber(platformInfo) then
            platMatchFlag = true
          end
        elseif platformInfo:match("^%d+%|.+$") then
          for numStr in platformInfo:gmatch("(%d+)") do
            if self.PLATFORM == tonumber(numStr) then
              platMatchFlag = true
              break
            end
          end
        end
        if false == platMatchFlag then
          point_data[i] = nil
        end
      end
    end
  end
end

function RedPointModuleData:SetPlatform()
  if RocoEnv.IS_EDITOR then
    self.PLATFORM = Enum.PlatType.PT_EDITOR
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    self.PLATFORM = Enum.PlatType.PT_PC
  elseif _G.RocoEnv.PLATFORM_ANDROID then
    self.PLATFORM = Enum.PlatType.PT_ANDROID
  elseif _G.RocoEnv.PLATFORM_OPENHARMONY then
    self.PLATFORM = Enum.PlatType.PT_HARMONY_OS
  elseif _G.RocoEnv.PLATFORM_IOS then
    self.PLATFORM = Enum.PlatType.PT_IOS
  end
end

function RedPointModuleData:CheckPointDataHasNumInfo(pointData, reason)
  local num = 0
  if not pointData then
    return
  end
  for i, str in pairs(pointData) do
    if type(str) == "string" then
      local starIndex = str:find("%*[^%.]*$")
      if starIndex then
        local numberStr = str:sub(starIndex + 1)
        num = num + tonumber(numberStr)
      end
    end
  end
  return num
end

function RedPointModuleData:UpdateParentNode(rpNode, reason, customPointData, isPopReason, fromKey, rootFlag, numInfo)
  if not rootFlag then
    _UpdateOneRpNode(rpNode, reason, customPointData, true, fromKey, numInfo)
  end
  local PopupPointData = customPointData
  if rpNode.parent and #rpNode.parent > 0 then
    for _, parent in ipairs(rpNode.parent) do
      self:UpdateParentNode(parent, reason, PopupPointData, true, rpNode.key, false, numInfo)
    end
  end
end

local function _PrintBytes(bytes)
  local t = {}
  for i = 1, #bytes do
    local b = string.byte(bytes, i)
    t[#t + 1] = string.format("%02X ", b)
    if 0 == i % 8 then
      t[#t + 1] = "\n"
    end
  end
  local s = table.concat(t, " ")
  Log.Error(s)
end

function RedPointModuleData:UpdatePlayerRedPointInfo(reason, pointData)
  if nil == reason then
    return
  end
  local redPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  if nil == redPointInfo then
    Log.Error("PlayerDataModel:GetRedPointInfo \229\144\142\231\171\175\230\178\161\230\156\137red_point_info\229\173\151\230\174\181")
    return
  end
  local found = false
  for _, group in ipairs(redPointInfo) do
    if group.reason_type == reason then
      group.point_data = pointData
      found = true
      break
    end
  end
  if not found then
    local t = {reason_type = reason, point_data = pointData}
    table.insert(redPointInfo, t)
  end
end

function RedPointModuleData:GetReasonPointData(reason)
  if nil == reason then
    return
  end
  local redPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  if nil == redPointInfo then
    Log.Error("PlayerDataModel:GetRedPointInfo \229\144\142\231\171\175\230\178\161\230\156\137red_point_info\229\173\151\230\174\181")
    return
  end
  for _, group in ipairs(redPointInfo) do
    if group.reason_type == reason then
      return group.point_data
    end
  end
end

function RedPointModuleData:InvalidPointData(key, extraKey, notRefreshUI)
  local rpNode = self.RedPointNodeDic[key]
  if not rpNode then
    Log.Error("\230\178\161\230\156\137\232\175\165\231\186\162\231\130\185\229\175\185\229\186\148\231\154\132key\239\188\140\230\151\160\230\149\136\229\140\150\229\164\177\232\180\165\239\188\140\232\175\183\231\161\174\232\174\164InvalidPoint\232\176\131\231\148\168\230\152\175\229\144\166\230\173\163\231\161\174")
    return
  end
  local ReasonDic
  if self:CheckRPNodeIsLeaf(rpNode) then
    ReasonDic = rpNode.litUpReasonDic
  else
    ReasonDic = rpNode.popReasonDic
  end
  if not self.InvalidPointDataList[key] then
    self.InvalidPointDataList[key] = {}
  end
  if not self.InvalidPointDataList[key].reasonTable then
    self.InvalidPointDataList[key].reasonTable = {}
  end
  if not self.InvalidedKeyAndExtraKeyTable[key] then
    self.InvalidedKeyAndExtraKeyTable[key] = {}
  end
  if nil == extraKey then
    self.InvalidedKeyAndExtraKeyTable[key].InvalidAllExtraKey = true
    for reason, pointdata in pairs(ReasonDic) do
      local hasDataChanged = false
      if pointdata.oriPointData and true == pointdata.DataIsNewest then
        if self:CalcuTableLength(pointdata.oriPointData) > 0 then
          hasDataChanged = true
        end
        self.InvalidPointDataList[key].reasonTable[reason] = table.deepCopy(pointdata.oriPointData)
        pointdata.DataIsNewest = false
      end
      if hasDataChanged then
        if notRefreshUI then
          NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointDataWithoutRefreshUI, reason, nil, false)
        else
          NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, reason, nil, false)
        end
      end
    end
  else
    self:SafeInsert(self.InvalidedKeyAndExtraKeyTable[key], extraKey)
    for reason, pointdata in pairs(ReasonDic) do
      local hasDataChanged = false
      if pointdata.oriPointData and self:CalcuTableLength(pointdata.oriPointData) > 0 then
        if true == pointdata.DataIsNewest then
          self.InvalidPointDataList[key].reasonTable[reason] = table.deepCopy(pointdata.oriPointData)
          pointdata.DataIsNewest = false
        end
        for i, pointDataStr in pairs(pointdata.oriPointData) do
          if self:CheckExtraKeyIsMatchPointDataStr(extraKey, pointDataStr) then
            pointdata.oriPointData[i] = nil
            hasDataChanged = true
          end
        end
      end
      if hasDataChanged then
        if notRefreshUI then
          NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointDataWithoutRefreshUI, reason, pointdata.oriPointData, false)
        else
          NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, reason, pointdata.oriPointData, false)
        end
      end
    end
  end
end

function RedPointModuleData:CalcuTableLength(table)
  local len = 0
  if table then
    for _, data in pairs(table) do
      len = len + 1
    end
  end
  return len
end

function RedPointModuleData:RecoverPointData(key, extraKey)
  if not key then
    Log.Error("key is not exit")
    return
  end
  if not (self.InvalidPointDataList and self.InvalidPointDataList[key] and self.InvalidPointDataList[key]) or not self.InvalidPointDataList[key].reasonTable then
    return
  end
  if nil == extraKey then
    self.InvalidedKeyAndExtraKeyTable[key] = nil
    for reason, data in pairs(self.InvalidPointDataList[key].reasonTable) do
      local rpNodes = self.ReasonToRpNodesDic[reason]
      local currentData = rpNodes and rpNodes[1] and rpNodes[1].litUpReasonDic[reason]
      local currentOriData = currentData and currentData.oriPointData
      local hasDataChanged = not self:CheckDeepEqualByContent(data, currentOriData)
      if hasDataChanged then
        NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, reason, data, true)
      end
      self.InvalidPointDataList[key].reasonTable[reason] = nil
    end
  else
    self:RemoveTableElementByContent(self.InvalidedKeyAndExtraKeyTable[key], extraKey)
    for reason, pointDataList in pairs(self.InvalidPointDataList[key].reasonTable) do
      local rpNodes = self.ReasonToRpNodesDic[reason]
      local customPointData = rpNodes[1].litUpReasonDic[reason]
      local hasDataChanged = false
      for j, pointData in pairs(pointDataList) do
        if self:CheckExtraKeyIsMatchPointDataStr(extraKey, pointData) and customPointData and nil == customPointData.oriPointData[j] then
          customPointData.oriPointData[j] = pointData
          hasDataChanged = true
        end
      end
      if hasDataChanged and customPointData then
        NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, reason, customPointData.oriPointData, true)
      end
    end
  end
end

function RedPointModuleData:CheckTableContainsSameContent(t, element)
  for _, v in pairs(t) do
    if self:CheckDeepEqualByContent(v, element) then
      return true
    end
  end
  return false
end

function RedPointModuleData:SafeInsert(t, element)
  if not self:CheckTableContainsSameContent(t, element) then
    table.insert(t, element)
    return true
  end
  return false
end

function RedPointModuleData:CheckDeepEqualByContent(t1, t2)
  if type(t1) ~= type(t2) then
    return false
  end
  if type(t1) ~= "table" then
    return t1 == t2
  end
  local t1_len, t2_len = 0, 0
  for _ in pairs(t1) do
    t1_len = t1_len + 1
  end
  for _ in pairs(t2) do
    t2_len = t2_len + 1
  end
  if t1_len ~= t2_len then
    return false
  end
  for k, v in pairs(t1) do
    if not self:CheckDeepEqualByContent(v, t2[k]) then
      return false
    end
  end
  return true
end

function RedPointModuleData:RemoveTableElementByContent(t, element)
  local to_remove = {}
  for k, v in pairs(t) do
    if self:CheckDeepEqualByContent(v, element) then
      table.insert(to_remove, k)
    end
  end
  for _, k in ipairs(to_remove) do
    t[k] = nil
  end
end

function RedPointModuleData:CheckExtraKeyIsMatchPointDataStr(extraKey, pointData)
  local splitFunc = RedPointUtils.GetSplitFuncByReason()
  local splitPointData = splitFunc(pointData)
  return self:isPrefixMatch(extraKey, splitPointData)
end

function RedPointModuleData:CheckRPNodeIsLeaf(rpNode)
  if not rpNode then
    return false
  end
  for reason, pointdata in pairs(rpNode.litUpReasonDic) do
    return true
  end
  return false
end

function RedPointModuleData:isPrefixMatch(A, B)
  if not A or not B then
    return false
  end
  if type(A) ~= "table" or type(B) ~= "table" then
    Log.Error("\230\156\137extraKey\228\184\141\230\152\175table\231\154\132\229\189\162\229\188\143\239\188\140\232\175\183\230\163\128\230\159\165extraKey\239\188\140\229\186\148\232\175\165\233\131\189\228\184\186table")
    return false
  end
  if #B < #A then
    return false
  end
  for i = 1, #A do
    if tostring(A[i]) ~= B[i] then
      return false
    end
  end
  return true
end

function RedPointModuleData:ReInvalidPointData(reason)
  local notRefreshUI = true
  for key, data in pairs(self.InvalidedKeyAndExtraKeyTable) do
    if self.ReasonToAffectedParentKeysMap and self.ReasonToAffectedParentKeysMap[reason] and self.ReasonToAffectedParentKeysMap[reason][key] then
      if data.InvalidAllExtraKey then
        self:InvalidPointData(key, nil, notRefreshUI)
      else
        for _, extraKey in pairs(data) do
          if type(extraKey) ~= "boolean" then
            self:InvalidPointData(key, extraKey, notRefreshUI)
          end
        end
      end
    end
  end
end

return RedPointModuleData
