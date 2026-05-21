local RedPointUtils = NRCClass()

local function _DefaultFuc(poinData)
  if not poinData or type(poinData) ~= "string" then
    Log.Error("pointDataStr\228\184\186\231\169\186")
    return nil
  end
  local delimiter = "."
  local subValues = {}
  for subValue in string.gmatch(poinData, "([^" .. delimiter .. "]+)") do
    table.insert(subValues, subValue)
  end
  return subValues
end

local function _PetNewSkill(poinData)
  local delimiter = "."
  local subValues = {}
  for subValue in string.gmatch(poinData, "([^" .. delimiter .. "]+)") do
    table.insert(subValues, subValue)
  end
  return subValues
end

local _ReasonPointDataSplitFuncDic = {
  [Enum.RedPointReason.RPR_PET_NEW_SKILL] = _PetNewSkill
}

function RedPointUtils.GetSplitFuncByReason(reason)
  local func
  if not reason then
    func = _DefaultFuc
  else
    func = _ReasonPointDataSplitFuncDic[reason]
    func = func or _DefaultFuc
  end
  return func
end

local function _AdvCheckInReasonDic(reasonDic, extraKey, isRoot, ignoreRedPointDataList)
  local function CheckIgnoreRedPointDataMatch(pointinfoTable, reasonIgnoreRedPointDataList)
    local bMatch = false
    
    if reasonIgnoreRedPointDataList then
      bMatch = RedPointUtils.LooseTableContainsAny(pointinfoTable, reasonIgnoreRedPointDataList)
    end
    return bMatch
  end
  
  local function CheckDataHasNumInfo(splitPointData)
    local num
    for _, str in pairs(splitPointData) do
      local starIndex = str:find("%*[^%.]*$")
      if starIndex then
        local numberStr = str:sub(starIndex + 1)
        num = tonumber(numberStr)
      end
    end
    return num
  end
  
  local function CheckPointInfoMatchToExtraKey(pointInfoTable, extraKey, isRoot, reasonIgnoreRedPointDataList)
    local bMatch = true
    for i, value in ipairs(extraKey) do
      if value ~= pointInfoTable[i] then
        bMatch = false
        break
      end
    end
    if bMatch then
      local bIgnoreMatch = CheckIgnoreRedPointDataMatch(pointInfoTable, reasonIgnoreRedPointDataList)
      if not bIgnoreMatch then
        if isRoot then
          local num = CheckDataHasNumInfo(pointInfoTable)
          return true, num
        else
          return true
        end
      end
    end
    return false
  end
  
  local extraKeyIsNotTable = type(extraKey) ~= "table"
  for reason, data in pairs(reasonDic) do
    if extraKeyIsNotTable then
      local oriPointData = data.oriPointData
      for _, p in ipairs(oriPointData) do
        if p == extraKey then
          if ignoreRedPointDataList then
            if ignoreRedPointDataList[reason] then
              local bFind = false
              for _, ignorePointData in pairs(ignoreRedPointDataList[reason]) do
                if tonumber(p) and tonumber(p) == ignoreRedPointDataList then
                  bFind = true
                  break
                end
              end
              if not bFind then
                return true
              end
            end
          else
            return true
          end
        end
      end
    else
      local hasCheckData = false
      if data.splitPointData == nil then
        hasCheckData = true
        data.splitPointData = {}
        local pointData = data.oriPointData
        local splitFunc = data.splitFunc
        local flag = false
        local num
        for i, v in pairs(pointData) do
          data.splitPointData[i] = splitFunc(v)
          local pointInfoTable = data.splitPointData[i]
          if true ~= flag then
            local reasonIgnoreRedPointDataList
            if ignoreRedPointDataList then
              reasonIgnoreRedPointDataList = ignoreRedPointDataList[reason]
            end
            flag, num = CheckPointInfoMatchToExtraKey(pointInfoTable, extraKey, isRoot, reasonIgnoreRedPointDataList)
          end
        end
        if true == flag then
          return flag, num
        end
      end
      if false == hasCheckData then
        local splitPointData = data.splitPointData
        for _, pointInfoTable in pairs(splitPointData) do
          local reasonIgnoreRedPointDataList
          if ignoreRedPointDataList then
            reasonIgnoreRedPointDataList = ignoreRedPointDataList[reason]
          end
          local flag, num = CheckPointInfoMatchToExtraKey(pointInfoTable, extraKey, isRoot, reasonIgnoreRedPointDataList)
          if true == flag then
            return flag, num
          end
        end
      end
    end
  end
  return false
end

function RedPointUtils.GetAdvRedCountInReasonData(data, extraKey)
  local count = 0
  if type(extraKey) ~= "table" then
    local oriPointData = data.oriPointData
    for _, p in ipairs(oriPointData) do
      if p == extraKey then
        count = count + 1
      end
    end
  else
    if data.splitPointData == nil then
      data.splitPointData = {}
      local pointData = data.oriPointData
      do
        local splitFunc = data.splitFunc
        for i, v in pairs(pointData) do
          data.splitPointData[i] = splitFunc(v)
        end
      end
    end
    local splitPointData = data.splitPointData
    for _, p in pairs(splitPointData) do
      local bMatch = true
      for i, value in ipairs(extraKey) do
        if value ~= p[i] then
          bMatch = false
          break
        end
      end
      if bMatch then
        count = count + 1
      end
    end
  end
  return count
end

function RedPointUtils.AdvCheckIsRed(rpNode, extraKey, ignoreRedPointDataList)
  local isRed, num = _AdvCheckInReasonDic(rpNode.litUpReasonDic, extraKey, true)
  isRed = isRed or _AdvCheckInReasonDic(rpNode.popReasonDic, extraKey, false, ignoreRedPointDataList)
  return isRed, num
end

function RedPointUtils.AdvCheckIsRedByExtraKeyTable(rpNode, extraKeyTable, ignoreRedPointDataList)
  local isRed = false
  for i, extraKey in ipairs(extraKeyTable) do
    if RedPointUtils.AdvCheckIsRed(rpNode, extraKey, ignoreRedPointDataList) then
      isRed = true
      break
    end
  end
  return isRed
end

function RedPointUtils.LooseTableContainsAny(tableA, tableB)
  if type(tableA) ~= "table" or type(tableB) ~= "table" then
    return false
  end
  for _, valueA in pairs(tableA) do
    for _, valueB in pairs(tableB) do
      if type(valueA) == "string" and type(valueB) == "number" then
        if tonumber(valueA) == valueB then
          return true
        end
      elseif type(valueA) == "number" and type(valueB) == "string" then
        if valueA == tonumber(valueB) then
          return true
        end
      elseif valueA == valueB then
        return true
      end
    end
  end
  return false
end

function RedPointUtils.NumberInDotString(dotString, number)
  if type(dotString) ~= "string" or type(number) ~= "number" then
    return false
  end
  local numberStr = tostring(number)
  local parts = {}
  for part in string.gmatch(dotString, "([^%.]+)") do
    table.insert(parts, part)
  end
  for _, part in ipairs(parts) do
    if part == numberStr then
      return true
    end
  end
  return false
end

return RedPointUtils
