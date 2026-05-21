local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipUtils = {}
TipUtils.TipSeqNum = 0
TipUtils.FlexibleDispatchPass = 0
local DebugLogEnableStatus = false

function TipUtils.SetDebugLogEnable(enable)
  DebugLogEnableStatus = enable
end

function TipUtils.DebugTipFlow(tag, tip)
  Log.DebugFormat("[TipTrace] %s tip=%s", tag, tip or "nil")
end

function TipUtils.DebugLog(format, ...)
  if not DebugLogEnableStatus then
    Log.DebugFormat(format, ...)
  else
    Log.ErrorFormat(format, ...)
  end
end

function TipUtils.MakeUniqueKey(_key1, _key2)
  local key1 = _key1 or 0
  local key2 = _key2 or 0
  local key = key1 << 32 | key2
  return key
end

function TipUtils.GetNextTipSeq()
  TipUtils.TipSeqNum = TipUtils.TipSeqNum + 1
  return TipUtils.TipSeqNum
end

function TipUtils.CreteTipsDisplayController(tipType, caller, initTipsView)
  local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
  return TipsDisplayController(tipType, caller, initTipsView)
end

local function FindConfigByTip(container, tip)
  if container and tip then
    local key1 = TipUtils.MakeUniqueKey(tip.tipType, tip.tipCustomType)
    local value = container[key1]
    if not value then
      local key2 = TipUtils.MakeUniqueKey(tip.tipType)
      value = container[key2]
    end
    return value
  end
end

local TipDisplayRegionConf = {
  [TipEnum.TipDisplayArea.Top] = {
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TopHudTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MonthlyCardDailyRewardTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskComplete),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskAccept),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.LeaderFight),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.DungeonStateCompleted),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.DungeonCompleted),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskSummary),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskReturnReward),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.SeasonBeginsTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.ActivityCommonOpenTips)
  },
  [TipEnum.TipDisplayArea.Bottom] = {
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.LobbyDownTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.RolePlayGetTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.NPCRosterTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.LegendaryTaskUnlockTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TeachingUnlockTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MusicCollectUnlockTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MonthlyCardDailyRewardTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskSummary),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskReturnReward),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.ReceiveBPGiftTips)
  },
  [TipEnum.TipDisplayArea.Left] = {
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MainPetTips)
  },
  [TipEnum.TipDisplayArea.Right] = {
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.HandbookTopic),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.Reward)
  },
  [TipEnum.TipDisplayArea.Center] = {
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskSummary),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MonthlyCardDailyRewardTips),
    TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskReturnReward)
  }
}

local function TipDisplayRegionConfPreHandle()
  local ret = {}
  for displayArea, keys in pairs(TipDisplayRegionConf) do
    for _, key in ipairs(keys) do
      local displayAreas = ret[key]
      if not displayAreas then
        displayAreas = {}
        ret[key] = displayAreas
      end
      table.insert(displayAreas, displayArea)
    end
  end
  return ret
end

local TipToDisplayRegionConf = TipDisplayRegionConfPreHandle()

function TipUtils.GetTipDisplayAreas(tip)
  return FindConfigByTip(TipToDisplayRegionConf, tip)
end

local function CreateTipDistributionConf(dispatchPass, immediatelyDispatch, fallbackConf)
  local conf = {}
  conf.dispatchPass = dispatchPass or TipUtils.FlexibleDispatchPass
  conf.immediatelyDispatch = immediatelyDispatch or false
  conf.fallbackConf = fallbackConf
  return conf
end

local DefaultTipDistributionConf = CreateTipDistributionConf(TipUtils.FlexibleDispatchPass, true)
local TipDistributionConfInCacheMode = {
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.LobbyDownTips, TipEnum.LobbyDownTipsType.BookPrompt)] = CreateTipDistributionConf(10),
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MainPetTips)] = CreateTipDistributionConf(10),
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.HandbookTopic)] = CreateTipDistributionConf(20),
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.Reward)] = CreateTipDistributionConf(30, false, true),
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TopHudTips, TipEnum.TopHudTipsType.ExpTips)] = CreateTipDistributionConf(40),
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TopHudTips, TipEnum.TopHudTipsType.BreakThroughTips)] = CreateTipDistributionConf(40)
}
local TipDistributionConfInNormalMode = {}

local function GetTipDistributionConfByKey(key, normalMode)
  local conf = TipDistributionConfInCacheMode[key]
  conf = normalMode and TipDistributionConfInNormalMode[key] or conf
  return conf
end

function TipUtils.GetTipDistributionConf(tip, normalMode)
  local conf = GetTipDistributionConfByKey(TipUtils.MakeUniqueKey(tip.tipType, tip.tipCustomType), normalMode)
  if not conf then
    local typeConf = GetTipDistributionConfByKey(TipUtils.MakeUniqueKey(tip.tipType), normalMode)
    if typeConf and typeConf.fallbackConf then
      conf = typeConf
    end
  end
  return conf or DefaultTipDistributionConf
end

function TipUtils.IsMutexRequiredTipPass(tipPass)
  return tipPass ~= TipUtils.FlexibleDispatchPass
end

local TipPriorityConf = {
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MonthlyCardDailyRewardTips)] = 0,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.SeasonBeginsTips)] = 1,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.ActivityCommonOpenTips)] = 2
}

function TipUtils.GetTipPriority(tip, distributionConf)
  local priority
  if distributionConf and distributionConf.immediatelyDispatch then
    priority = FindConfigByTip(TipPriorityConf, tip)
  end
  return priority or math.maxinteger
end

local function MergeTableDictValues(dst, src, mergeValueFunc)
  for _key, _value in pairs(src) do
    if not dst[_key] then
      dst[_key] = _value
    elseif mergeValueFunc then
      dst[_key] = mergeValueFunc(dst[_key], _value)
    end
  end
end

local function MergeTableArrayValues(dst, src)
  for _, _value in ipairs(src) do
    if not table.contains(dst, _value) then
      table.insert(dst, _value)
    end
  end
end

local TipMergeHandlers = {
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.Reward, TipEnum.PropTipsType.PlayerAddExp)] = function(dstOld, srcNew)
    if dstOld.tipCustomType == TipEnum.PropTipsType.PlayerAddExp and srcNew.tipCustomType == TipEnum.PropTipsType.PlayerAddExp then
      local srcNewExp = srcNew.customData
      local dstOldExp = dstOld.customData
      if srcNewExp.frameCnt == dstOldExp.frameCnt then
        local addExp = dstOldExp.newExp - dstOldExp.oldExp + (srcNewExp.newExp - srcNewExp.oldExp)
        local oldLevel = math.min(dstOldExp.oldLevel, srcNewExp.oldLevel)
        local newLevel = math.max(dstOldExp.newLevel, srcNewExp.newLevel)
        if oldLevel < newLevel then
          for i = oldLevel, newLevel - 1 do
            local levelExpConf = _G.DataConfigManager:GetRoleExpConf(i)
            if levelExpConf then
              addExp = addExp + levelExpConf.need_exp
            end
          end
        end
        dstOld.num = addExp
        return true
      end
    end
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TopHudTips, TipEnum.TopHudTipsType.ExpTips)] = function(dstOld, srcNew)
    if dstOld.tipCustomType == TipEnum.TopHudTipsType.ExpTips and srcNew.tipCustomType == TipEnum.TopHudTipsType.ExpTips then
      local srcNewExp = srcNew.customData
      local dstOldExp = dstOld.customData
      dstOldExp.oldExp = math.min(dstOldExp.oldExp, srcNewExp.oldExp)
      dstOldExp.newExp = math.max(dstOldExp.newExp, srcNewExp.newExp)
      dstOldExp.oldLevel = math.min(dstOldExp.oldLevel, srcNewExp.oldLevel)
      dstOldExp.newLevel = math.max(dstOldExp.newLevel, srcNewExp.newLevel)
      dstOldExp.addExp = dstOldExp.addExp + srcNewExp.addExp
      return true
    end
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.Reward, TipEnum.PropTipsType.GoodsItem)] = function(dstOld, srcNew)
    if dstOld.CmdID == srcNew.CmdID and dstOld.id == srcNew.id and srcNew.CmdID == _G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_TEACH_READED_RSP then
      dstOld.num = dstOld.num + srcNew.num
      return true
    end
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TeachingUnlockTips)] = function(dstOld, srcNew)
    local srcNewData = srcNew.customData
    local dstOldData = dstOld.customData
    local NewTipsTeachId = srcNewData.TeachId
    local NewTipPriority = srcNewData.priority or 99
    local OldTipsTeachId = dstOldData.TeachId
    local OldTipPriority = dstOldData.priority or 99
    if NewTipPriority ~= OldTipPriority then
      if NewTipPriority < OldTipPriority then
        dstOld.customData = srcNew.customData
      end
    elseif NewTipsTeachId > OldTipsTeachId then
      dstOld.customData = srcNew.customData
    end
    return true
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TopHudTips, TipEnum.TopHudTipsType.ZoneTips)] = function(dstOld, srcNew)
    dstOld.customData = srcNew.customData
    return true
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.HandbookTopic)] = function(dstOld, srcNew)
    local srcTopicTipData = srcNew.customData
    local dstTopicTipData = dstOld.customData
    return false
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MonthlyCardDailyRewardTips)] = function(dstOld, srcNew)
    local oldRewardItems = dstOld.customData
    local newRewardItems = srcNew.customData
    for _type, _itemsData in pairs(newRewardItems) do
      local _typeDict = oldRewardItems[_type]
      if nil ~= _typeDict then
        for _id, _num in pairs(_itemsData) do
          if nil ~= _typeDict[_id] then
            _typeDict[_id][1] = _typeDict[_id][1] + _num[1]
          else
            _typeDict[_id] = _num
          end
        end
      else
        oldRewardItems[_type] = _itemsData
      end
    end
    return true
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.TaskReturnReward)] = function(dstOld, srcNew)
    dstOld.customData = srcNew.customData
    return true
  end,
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.MainPetTips)] = function(dstOld, srcNew)
    local dstOldData = dstOld.customData
    local srcNewData = srcNew.customData
    local _, dstFirstItem = next(dstOldData)
    local _, srcFirstItem = next(srcNewData)
    if not dstFirstItem or not srcFirstItem then
      return false
    end
    if dstFirstItem.subType ~= srcFirstItem.subType then
      return false
    end
    local subType = dstFirstItem.subType
    for _gid, _srcItem in pairs(srcNewData) do
      local _dstItem = dstOldData[_gid]
      if not _dstItem then
        dstOldData[_gid] = _srcItem
      elseif subType == TipEnum.MainPetTipsType.Energy then
        _dstItem.subData.newEnergy = _srcItem.subData.newEnergy
        _dstItem.subData.reason = _srcItem.subData.reason
      elseif subType == TipEnum.MainPetTipsType.Exp then
        _dstItem.subData.new_exp = _srcItem.subData.new_exp
      elseif subType == TipEnum.MainPetTipsType.Level then
        _dstItem.subData.new_exp = _srcItem.subData.new_exp
        _dstItem.subData.new_level = _srcItem.subData.new_level
      elseif subType == TipEnum.MainPetTipsType.Skill then
        for _, _skill in ipairs(_srcItem.subData.skills) do
          table.insert(_dstItem.subData.skills, _skill)
        end
      elseif subType == TipEnum.MainPetTipsType.Medal then
        for _, _medal in ipairs(_srcItem.subData) do
          table.insert(_dstItem.subData, _medal)
        end
      end
    end
    return true
  end
}

function TipUtils.GetTipMergeHandler(tip)
  local key = TipUtils.MakeUniqueKey(tip.tipType, tip.tipCustomType)
  return TipMergeHandlers[key]
end

local TipSortHandlers = {
  [TipUtils.MakeUniqueKey(TipEnum.TipObjectType.Reward)] = function(a, b)
    if b.first and not a.first then
      return false
    end
    return true
  end
}

function TipUtils.GetTipSortHandler(tip)
  local key = TipUtils.MakeUniqueKey(tip.tipType, tip.tipCustomType)
  local handler = TipSortHandlers[key]
  if not handler then
    key = TipUtils.MakeUniqueKey(tip.tipType)
    handler = TipSortHandlers[key]
  end
  return handler
end

return TipUtils
