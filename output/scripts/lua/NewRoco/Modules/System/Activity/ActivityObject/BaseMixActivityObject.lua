local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local BaseMixActivityObject = Base:Extend("BaseMixActivityObject")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TaskQueryHandler = require("NewRoco.Modules.System.Misc.TaskQueryHandler")

function BaseMixActivityObject:OnConstruct(_conf)
  self.mixCfg = _G.DataConfigManager:GetActivityMixConf(self:GetSinglePartId())
  self.judgeTaskQuery = TaskQueryHandler(self.mixCfg and self.mixCfg.must_do_task_judg)
  self:AddActivityExpiredCallback("BaseMixActivityExpired", nil, function()
    self:SendEvent(ActivityModuleEvent.OnBaseMixActivityExpired)
  end)
  self.HasLookTabRedPoint = false
  self.MixActivityData = nil
end

function BaseMixActivityObject:GetMixCfg()
  return self.mixCfg
end

function BaseMixActivityObject:GetSlotRedPointData(slotData, separator)
  if not slotData then
    return
  end
  
  local function SplitString(str, pattern)
    local result = {}
    if not string.IsNilOrEmpty(str) and not string.IsNilOrEmpty(pattern) then
      for match in string.gmatch(str, pattern) do
        result[#result + 1] = match
      end
    end
    return result
  end
  
  local sep = separator
  if not separator then
    sep = "[^%#]+"
  end
  return slotData.red_point_id, SplitString(slotData.red_point_rule, sep)
end

function BaseMixActivityObject:GetSlotName(option_id)
  local config = _G.DataConfigManager:GetActivityOptionConf(option_id, true)
  if not config then
    Log.Error("ActivityUtils.DoActivityOptionCmd: config not found! id=", option_id)
    return ""
  end
  return config.option_param1
end

function BaseMixActivityObject:DoOperate(index, bOption)
  if self:IsInProgress() then
    local slot = self.mixCfg.slot_group[index]
    if bOption then
      ActivityUtils.DoActivityOptionCmd(slot.option_id)
    elseif slot.slot_function_type == _G.Enum.ActiviyMixSlotFunciton.AMSF_ACTIVITY then
      local dropObject = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, slot.param, true)
      local getNum = 0
      if dropObject then
        getNum, _ = dropObject:GetAlreadyGetNum()
      end
      return getNum
    elseif slot.slot_function_type == _G.Enum.ActiviyMixSlotFunciton.AMSF_CHECK_VITEM then
      if slot.param and 0 ~= slot.param then
        return _G.DataModelMgr.PlayerDataModel:GetVItemCount(slot.param) or 0, _G.Enum.GoodsType.GT_VITEM
      end
    elseif slot.slot_function_type == _G.Enum.ActiviyMixSlotFunciton.AMSF_CHECK_BAGITEM and slot.param and 0 ~= slot.param then
      local item = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, slot.param)
      return item and item.num or 0, _G.Enum.GoodsType.GT_BAGITEM
    end
  end
end

function BaseMixActivityObject:GetTabRedPointCustomExtraKeyList()
  local extraKeyList = {}
  local mixCfg = self:GetMixCfg()
  if mixCfg then
    for _, slotData in ipairs(mixCfg.slot_group or {}) do
      local redPointId, redPointExtraKey = self:GetSlotRedPointData(slotData)
      if redPointId and next(redPointExtraKey) then
        for i, v in pairs(redPointExtraKey) do
          local _extraKeyList = string.Split(v, ";")
          for _, extraKey in ipairs(_extraKeyList) do
            table.insert(extraKeyList, {extraKey})
          end
        end
      end
    end
  end
  return extraKeyList
end

function BaseMixActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.MixActivityData = _updateData
  end
end

function BaseMixActivityObject:GetSlotRewardState(slot_function_type, slotIndex, id)
  if self.MixActivityData and self.MixActivityData.base_mix_data and self.MixActivityData.base_mix_data.slot_datas then
    local slotDataList = self.MixActivityData.base_mix_data.slot_datas
    local slotData = slotDataList[slotIndex]
    if slotData then
      if slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_TASK_REAWAD then
        return slotData.state
      else
        local slotPartData = slotData.slot_part_datas
        if slotPartData and slotPartData[id] then
          return slotPartData[id].state
        end
      end
    end
  end
end

return BaseMixActivityObject
