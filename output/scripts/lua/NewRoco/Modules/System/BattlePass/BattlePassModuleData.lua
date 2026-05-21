local BattlePassModuleData = _G.NRCData:Extend("BattlePassModuleData")

function BattlePassModuleData:Ctor()
  NRCData.Ctor(self)
  self.PetSelectTabIndex = 0
  self.PlayerBattlePassInfo = nil
  self.ActiveSelectTabIndex = 0
  self.ActiveSelectWeekIndex = 0
  self.ActiveWeekParaGraphId = 0
  self.ActivieTaskDic = {}
  self.AllTaskDic = {}
  self.RoutineTaskDic = nil
  self.AllTaskConf = nil
  self.PassRewardCfgs = nil
  local passRewardTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_REWARD_CONF)
  if passRewardTable then
    self.PassRewardCfgs = passRewardTable:GetAllDatas()
  end
  self.passThemeColorMap = {}
  self.LastTaskListInfo = {}
  self:InitThemeColorMap()
  self.CacheLevelUpData = nil
  self._anotherThemeFriendList = {}
  self._anotherThemeFriendCount = 0
  self._lastReqFriendThemeTime = 0
  self._anotherThemeFriendTempList = {}
end

function BattlePassModuleData:GetPetDatas()
  local datas = {}
  table.insert(datas, 3001)
  table.insert(datas, 3002)
  table.insert(datas, 3003)
  return datas
end

function BattlePassModuleData:GetPetSelectTabIndex()
  return self.PetSelectTabIndex
end

function BattlePassModuleData:SetPetSelectTabIndex(index)
  self.PetSelectTabIndex = index
end

function BattlePassModuleData:GetActiveSelectTabIndex()
  return self.ActiveSelectTabIndex
end

function BattlePassModuleData:SetActiveSelectTabIndex(index)
  self.ActiveSelectTabIndex = index
end

function BattlePassModuleData:GetActiveSelectWeekIndex()
  return self.ActiveSelectWeekIndex
end

function BattlePassModuleData:SetActiveSelectWeekIndex(index)
  self.ActiveSelectWeekIndex = index
end

function BattlePassModuleData:GetWeekParaGraphId()
  return self.ActiveWeekParaGraphId
end

function BattlePassModuleData:SetWeekParaGraphId(graph_id)
  self.ActiveWeekParaGraphId = graph_id
end

function BattlePassModuleData:GetThemeResPath()
  local battlePassInfo = self:GetPlayerBattlePassInfo()
  local theme_id = battlePassInfo.theme_id
  local path = "PaperSprite'/Game/NewRoco/Modules/System/BattlePass/Raw/Moonshine/Frames"
  if theme_id then
    local themeConf = _G.DataConfigManager:GetBattlePassThemeConf(theme_id)
    if themeConf then
      path = themeConf.theme_art_set
    end
  else
    Log.Error("GetThemeResPath theme_id is nil")
  end
  return path
end

function BattlePassModuleData:GetPlayerBattlePassInfo()
  if self.PlayerBattlePassInfo == nil then
    self.PlayerBattlePassInfo = {}
  end
  return self.PlayerBattlePassInfo
end

function BattlePassModuleData:SetPlayerBattlePassInfo(info)
  Log.Dump(info, 9, "#SetPlayerBattlePassInfo")
  self.PlayerBattlePassInfo = info.battle_pass_info
  if info.battle_pass_brief_info then
    self.PlayerBattlePassInfo.battle_pass_brief_info = info.battle_pass_brief_info
    self:SetPlayerBattlePassBriefInfo(info.battle_pass_brief_info)
  else
    self.PlayerBattlePassInfo.battle_pass_brief_info = self:GetPlayerBattlePassBriefInfo()
  end
  self:InitRoutineTaskDic()
end

function BattlePassModuleData:SetPlayerBattlePassBriefInfo(info)
  self.battle_pass_brief_info = info
end

function BattlePassModuleData:GetPlayerBattlePassBriefInfo()
  if self.battle_pass_brief_info == nil then
    self.battle_pass_brief_info = {}
    self.battle_pass_brief_info.gift_grade = _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE
  end
  return self.battle_pass_brief_info
end

function BattlePassModuleData:GetNextLevelNeedExp(themeId, nextLv)
  local themCfg = _G.DataConfigManager:GetBattlePassThemeConf(themeId)
  local reward_set_id = themCfg.reward_set_id
  local passRewardCfgs = self.PassRewardCfgs
  for _, cfg in ipairs(passRewardCfgs) do
    if cfg.belong_reward_set_id == reward_set_id and cfg.bp_level == nextLv then
      return cfg.need_exp
    end
  end
  return 0
end

function BattlePassModuleData:GetBpMaxLevel()
  local passCfg = _G.DataConfigManager:GetBattlePassConf(self.PlayerBattlePassInfo.battle_pass_id)
  if not passCfg then
    Log.Error("GetBpMaxLevel passCfg is nil ID is : ", self.PlayerBattlePassInfo.battle_pass_id)
    return nil
  end
  return passCfg.top_level
end

function BattlePassModuleData:GetBuyLevelGoodsShopId()
  return self:GetPaymentGlobalCfgNum("bp_buy_level_goods_shop_id")
end

function BattlePassModuleData:GetMaxWeekExp()
  return self:GetPaymentGlobalCfgNum("max_bp_exp_per_week")
end

function BattlePassModuleData:GetBuyLevelUnit()
  return self:GetPaymentGlobalCfgNum("bp_quick_buy_level_unit")
end

function BattlePassModuleData:GetProtectMaxLevel()
  return self:GetPaymentGlobalCfgNum("BP_max_level_protect")
end

function BattlePassModuleData:GetPaymentGlobalCfgNum(key)
  local cfg = _G.DataConfigManager:GetPaymentGlobalConfig(key)
  if cfg then
    return cfg.num
  end
  return 0
end

function BattlePassModuleData:IsPaid()
  local briefInfo = self.PlayerBattlePassInfo.battle_pass_brief_info
  if briefInfo and briefInfo.gift_grade then
    return briefInfo.gift_grade ~= _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE
  end
  return false
end

function BattlePassModuleData:InitRoutineTaskDic()
  if self.RoutineTaskDic == nil and self.PlayerBattlePassInfo and self.PlayerBattlePassInfo.battle_pass_id then
    local conf = _G.DataConfigManager:GetBattlePassConf(self.PlayerBattlePassInfo.battle_pass_id)
    self.RoutineTaskDic = {}
  end
end

function BattlePassModuleData:SetLastTaskListInfo(TaskInfo)
  if self.LastTaskListInfo == nil then
    self.LastTaskListInfo = {}
  end
  for _, v in pairs(TaskInfo) do
    self.LastTaskListInfo[v.id] = v
  end
end

function BattlePassModuleData:GetLastTaskListInfo()
  local listInfo = {}
  if self.LastTaskListInfo then
    for _, v in pairs(self.LastTaskListInfo) do
      table.insert(listInfo, v)
    end
  end
  return listInfo
end

function BattlePassModuleData:GetLastTaskState(taskId)
  if self.LastTaskListInfo and self.LastTaskListInfo[taskId] then
    return self.LastTaskListInfo[taskId].state
  end
  return nil
end

function BattlePassModuleData:SetPassAllTaskDic(taskList)
  for _, task in ipairs(taskList) do
    local taskId = task.id
    local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
    if taskConf then
      local taskType = taskConf.task_class
      if self.AllTaskDic[taskType] == nil then
        self.AllTaskDic[taskType] = {}
      end
      local endTime = self:GetWeekTaskEndTimeByTaskId(taskId)
      task.conf = taskConf
      task.end_time = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, endTime)
      self.AllTaskDic[taskType][taskId] = task
    else
      Log.Error(taskId, "bp\228\187\187\229\138\161\233\133\141\231\189\174\228\184\186\231\169\186\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165\228\184\128\228\184\139")
    end
  end
end

function BattlePassModuleData:ClearPassAllTaskDic()
  Log.Info("BattlePassModuleData:ClearPassAllTaskDic")
  self.AllTaskDic = {}
end

function BattlePassModuleData:GetPassTaskInfoById(task_id)
  for _, taskTypeList in pairs(self.AllTaskDic) do
    if taskTypeList[task_id] then
      return taskTypeList[task_id]
    end
  end
  return nil
end

function BattlePassModuleData:GetTasksByType(type)
  if self.AllTaskDic[type] == nil then
    return {}
  end
  local taskDic = self.AllTaskDic[type]
  local taskList = {}
  local routineDic = {}
  for _, taskInfo in pairs(taskDic) do
    if taskInfo.state ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSED then
      if self.RoutineTaskDic[taskInfo.id] then
        local progressive_task_id = self.RoutineTaskDic[taskInfo.id]
        if nil == routineDic[progressive_task_id] then
          routineDic[progressive_task_id] = {}
        end
        table.insert(routineDic[progressive_task_id], taskInfo)
      else
        table.insert(taskList, taskInfo)
      end
    end
  end
  for _, routineList in pairs(routineDic) do
    table.sort(routineList, function(a, b)
      return a.id < b.id
    end)
    for i = 1, #routineList do
      local taskId = routineList[i].id
      local taskInfo = self.AllTaskDic[type][taskId]
      if taskInfo.state ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        table.insert(taskList, taskInfo)
        break
      elseif #routineList == i then
        table.insert(taskList, taskInfo)
      end
    end
  end
  taskList = self:SortTaskList(taskList)
  return taskList
end

function BattlePassModuleData:SortTaskList(taskList)
  table.sort(taskList, function(a, b)
    if self:SortNum(a.state) == self:SortNum(b.state) then
      local taskModuleConf = _G.DataConfigManager:GetBattlePassTaskModuleConf(a.id)
      local taskModuleConfB = _G.DataConfigManager:GetBattlePassTaskModuleConf(b.id)
      if taskModuleConf and taskModuleConfB then
        return taskModuleConf.moduel_id < taskModuleConfB.moduel_id
      end
      return a.id < b.id
    else
      return self:SortNum(a.state) < self:SortNum(b.state)
    end
  end)
  return taskList
end

function BattlePassModuleData:GetRoutineTasks(paragraph_id)
  local confs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local routineTasks = {}
  for _, conf in pairs(confs) do
    if conf.paragraph_id == paragraph_id then
      table.insert(routineTasks, conf.id)
    end
  end
  return routineTasks
end

function BattlePassModuleData:SetPassActiveTaskDic(task)
  local taskConf = _G.DataConfigManager:GetTaskConf(task.id)
  if self.ActivieTaskDic[taskConf.paragraph_id] == nil then
    self.ActivieTaskDic[taskConf.paragraph_id] = {}
  end
  if taskConf.task_class == _G.Enum.TaskClassType.TCT_BP then
    self.ActivieTaskDic[taskConf.paragraph_id][task.id] = task
  end
end

function BattlePassModuleData:GetWeekTasks(paragraph_id)
  if self.ActivieTaskDic[paragraph_id] == nil then
    return {}
  end
  local groupDic = self.ActivieTaskDic[paragraph_id]
  local Tasks = {}
  for i, taskInfo in pairs(groupDic) do
    table.insert(Tasks, taskInfo)
  end
  table.sort(Tasks, function(a, b)
    if self:SortNum(a.state) == self:SortNum(b.state) then
      return a.id < b.id
    else
      return self:SortNum(a.state) < self:SortNum(b.state)
    end
  end)
  return Tasks
end

function BattlePassModuleData:GetWeekTaskEndTimeByTaskId(task_id)
  local battlePassConf = _G.DataConfigManager:GetBattlePassConf(self.PlayerBattlePassInfo.battle_pass_id)
  if battlePassConf then
    local bp_week_task = battlePassConf.bp_week_task
    local taskConf = _G.DataConfigManager:GetTaskConf(task_id)
    if taskConf then
      local paragraph_id = taskConf.paragraph_id
      for i = 1, #bp_week_task do
        local group_id = bp_week_task[i].task_set_id
        if group_id == paragraph_id then
          return bp_week_task[i].task_set_end_time
        end
      end
    end
  end
  return nil
end

function BattlePassModuleData:GetWeekIndexByTaskId(task_id)
  local index = -1
  local bp_week_task = _G.DataConfigManager:GetBattlePassConf(self.PlayerBattlePassInfo.battle_pass_id).bp_week_task
  for i = 1, #bp_week_task do
    local group_id = bp_week_task[i].task_set_id
    if self.ActivieTaskDic[group_id] then
      local isGroup = self.ActivieTaskDic[group_id][task_id] ~= nil
      if isGroup then
        index = i - 1
        return index
      end
    end
  end
  return index
end

function BattlePassModuleData:SortNum(state)
  local sortNum = 0
  if state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
    sortNum = 1
  elseif state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    sortNum = 2
  elseif state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    sortNum = 3
  else
    sortNum = 99
  end
  return sortNum
end

function BattlePassModuleData:GetAllFinshTaskIds()
  local taskIds = {}
  for key, typeTaskDic in pairs(self.AllTaskDic) do
    for key, task in pairs(typeTaskDic) do
      if task.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        table.insert(taskIds, task.id)
      end
    end
  end
  return taskIds
end

function BattlePassModuleData:GetWeekDoneState(paragraph_id)
  local tasks = self:GetWeekTasks(paragraph_id)
  local isDone = true
  for i, task in pairs(tasks) do
    if task.state ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      isDone = false
      break
    end
  end
  return isDone
end

function BattlePassModuleData:GetWeekWaitState(paragraph_id)
  local tasks = self:GetWeekTasks(paragraph_id)
  local isWait = false
  for i, task in pairs(tasks) do
    if task.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      isWait = true
      break
    end
  end
  return isWait
end

function BattlePassModuleData:GetBagItemCountByGoodsId(goodsId)
  if not goodsId or 0 == goodsId then
    return 0, nil
  end
  local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  if not goodsShopConf then
    Log.Warning("goodsShopConf is nil, goodsId:", goodsId)
    return 0, nil
  end
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(goodsShopConf.param)
  if not goodsConf then
    Log.Warning("goodsConf is nil, goodsId:", goodsId)
    return 0, nil
  end
  if goodsConf.Type == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, goodsConf.item_id)
    return bagItem and bagItem.num or 0, bagItem
  end
  if goodsConf.Type == _G.Enum.GoodsType.GT_VITEM then
    return _G.DataModelMgr.PlayerDataModel:GetVItemCount(goodsConf.item_id) or 0, nil
  end
  return 0, nil
end

function BattlePassModuleData:GetBattlePassGiftData(bp_id, theme_id, bp_grade, gender)
  local allGiftConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_GIFT_CONF):GetAllDatas()
  local giftDataList = {}
  local selectGiftConf
  for k, giftConf in pairs(allGiftConfList or {}) do
    if giftConf.bp_id == bp_id and giftConf.bp_theme == theme_id and giftConf.bp_grade == bp_grade and giftConf.gender == gender and giftConf.gift then
      for i = 1, #giftConf.gift do
        local giftItem = giftConf.gift[i]
        local itemData = {
          itemType = giftItem.type,
          itemId = giftItem.item_id,
          itemNum = giftItem.item_num,
          bShowNum = true,
          bShowTip = true,
          IsCanClick = true,
          numTextHexColor = "FFC65FFF"
        }
        table.insert(giftDataList, itemData)
      end
      selectGiftConf = giftConf
      break
    end
  end
  return giftDataList, selectGiftConf
end

function BattlePassModuleData:GetSubCouponCountByTheme(theme_id, bp_grade, gender)
  if not (theme_id and bp_grade) or not gender then
    Log.Warning("GetSubCouponCountByTheme: \229\143\130\230\149\176\228\184\141\229\174\140\230\149\180", theme_id, bp_grade, gender)
    return 0, nil
  end
  local curPassInfo = self:GetPlayerBattlePassInfo()
  if not curPassInfo or not curPassInfo.battle_pass_id then
    Log.Warning("GetSubCouponCountByTheme: \230\151\160\230\179\149\232\142\183\229\143\150\229\189\147\229\137\141\230\136\152\230\150\151\233\128\154\232\161\140\232\175\129\228\191\161\230\129\175")
    return 0, nil
  end
  local giftDataList, selectGiftConf = self:GetBattlePassGiftData(curPassInfo.battle_pass_id, theme_id, bp_grade, gender)
  if not selectGiftConf then
    Log.Warning("GetSubCouponCountByTheme: \230\151\160\230\179\149\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132\231\164\188\229\140\133\233\133\141\231\189\174", theme_id, bp_grade, gender)
    return 0, nil
  end
  local giftItemMainID = selectGiftConf.gift_item_main_id or 0
  if 0 == giftItemMainID then
    Log.Warning("GetSubCouponCountByTheme: \229\173\144\229\136\184\229\149\134\229\147\129ID\228\184\1860")
    return 0, nil
  end
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, giftItemMainID)
  local bagItemNum = bagItem and bagItem.num or 0
  Log.Debug("GetSubCouponCountByTheme: \228\184\187\233\162\152ID:", theme_id, "\230\161\163\228\189\141:", bp_grade, "\230\128\167\229\136\171:", gender, "\229\173\144\229\136\184\230\149\176\233\135\143:", bagItemNum)
  return bagItemNum, bagItem
end

function BattlePassModuleData:CanSwitchTheme()
  local curPassInfo = self:GetPlayerBattlePassInfo()
  if not (curPassInfo and curPassInfo.battle_pass_brief_info) or not curPassInfo.battle_pass_brief_info.gift_grade then
    Log.Warning("CanSwitchTheme: \230\151\160\230\179\149\232\142\183\229\143\150\229\189\147\229\137\141\233\128\154\232\161\140\232\175\129gift_grade")
    return false
  end
  if curPassInfo.battle_pass_brief_info.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE then
    return true
  end
  return false
end

function BattlePassModuleData:GetSubCouponItemIdsWithGoodsConf(goodsConf)
  if not goodsConf then
    Log.Error("GetSubCouponItemIdsWithGoodsConf: goodsConf is nil")
    return {}
  end
  local OutSubItemIds = {}
  if goodsConf.Type == _G.Enum.GoodsType.GT_REWARD then
    local rewardConf = _G.DataConfigManager:GetRewardConf(goodsConf.item_id)
    if rewardConf then
      for _, rewardItem in ipairs(rewardConf.RewardItem) do
        if rewardItem.type == _G.Enum.GoodsType.GT_BAGITEM then
          local bagItem = _G.DataConfigManager:GetBagItemConf(rewardItem.id)
          if bagItem and bagItem.type == _G.Enum.BagItemType.BI_BP_GIFT_SUB then
            table.insert(OutSubItemIds, bagItem.id)
          end
        end
      end
    end
  end
  if goodsConf.Type == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    if bagItem and bagItem.type == _G.Enum.BagItemType.BI_BP_GIFT_SUB then
      table.insert(OutSubItemIds, bagItem.id)
    end
  end
  return OutSubItemIds
end

function BattlePassModuleData:InitThemeColorMap()
  local allColorConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_UI_COLOR):GetAllDatas()
  if not allColorConf then
    Log.Warning("InitThemeColorMap: \230\151\160\230\179\149\232\142\183\229\143\150\228\184\187\233\162\152\233\162\156\232\137\178\233\133\141\231\189\174")
    return
  end
  if self.passThemeColorMap == nil then
    self.passThemeColorMap = {}
  end
  for _, conf in ipairs(allColorConf) do
    local umg_name = conf.umg_name
    local widget_name = conf.widget_name
    if self.passThemeColorMap[umg_name] == nil then
      self.passThemeColorMap[umg_name] = {}
    end
    if self.passThemeColorMap[umg_name][widget_name] == nil then
      self.passThemeColorMap[umg_name][widget_name] = {}
    end
    for _, color_conf in ipairs(conf.color_group) do
      table.insert(self.passThemeColorMap[umg_name][widget_name], {
        theme_id = color_conf.theme_id,
        color = color_conf.color,
        img_path = color_conf.img
      })
    end
  end
end

function BattlePassModuleData:ChangeThemeColor(PanelName, PanelInstane, theme_id)
  local passInfo = self:GetPlayerBattlePassInfo()
  if nil == passInfo then
    return
  end
  theme_id = theme_id or passInfo.theme_id
  if nil == theme_id then
    return
  end
  if nil == self.passThemeColorMap then
    self:InitThemeColorMap()
  end
  local widgetInfo = self.passThemeColorMap[PanelName]
  if widgetInfo then
    for widget_name, color_group in pairs(widgetInfo) do
      local Widget = PanelInstane[widget_name]
      if Widget then
        for _, color_conf in ipairs(color_group) do
          if color_conf.theme_id == theme_id then
            local color = color_conf.color
            if color and "" ~= color then
              if Widget.SetColorAndOpacity then
                local ColorText = string.format("#%s", color)
                Widget:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(ColorText))
              else
                Log.Warning("ChangeThemeColor: \230\142\167\228\187\182\230\178\161\230\156\137SetColorAndOpacity\230\150\185\230\179\149", PanelName, widget_name)
              end
            end
            local img_path = color_conf.img_path
            if img_path and "" ~= img_path then
              if Widget.SetPath then
                Widget:SetPath(img_path)
                break
              end
              Log.Warning("ChangeThemeColor: \230\142\167\228\187\182\230\178\161\230\156\137SetPath\230\150\185\230\179\149", PanelName, widget_name)
            end
            break
          end
        end
      else
        Log.Warning("ChangeThemeColor: \230\151\160\230\179\149\230\137\190\229\136\176\230\142\167\228\187\182,\232\175\183\229\156\168\232\147\157\229\155\190\228\184\173\230\154\180\233\156\178\229\143\152\233\135\143", PanelName, widget_name)
      end
    end
  else
    Log.Info("ChangeThemeColor: \230\151\160\230\179\149\230\137\190\229\136\176Panel", PanelName)
  end
end

function BattlePassModuleData:SetCacheLevelUpData(oldLv, newLv)
  self.CacheLevelUpData = {oldLv = oldLv, newLv = newLv}
end

function BattlePassModuleData:GetCacheLevelUpData()
  return self.CacheLevelUpData
end

function BattlePassModuleData:ClearCacheLevelUpData()
  self.CacheLevelUpData = nil
end

function BattlePassModuleData:GetAnotherThemeFriendList()
  return self._anotherThemeFriendList
end

function BattlePassModuleData:SetAnotherThemeFriendList(list)
  self._anotherThemeFriendList = list or {}
end

function BattlePassModuleData:GetAnotherThemeFriendCount()
  return self._anotherThemeFriendCount or 0
end

function BattlePassModuleData:SetAnotherThemeFriendCount(count)
  self._anotherThemeFriendCount = count or 0
end

function BattlePassModuleData:GetAnotherThemeFriendTempList()
  return self._anotherThemeFriendTempList
end

function BattlePassModuleData:ClearAnotherThemeFriendTempList()
  self._anotherThemeFriendTempList = {}
end

function BattlePassModuleData:AppendAnotherThemeFriendTempList(list)
  if list then
    for _, v in ipairs(list) do
      self._anotherThemeFriendTempList[#self._anotherThemeFriendTempList + 1] = v
    end
  end
end

function BattlePassModuleData:CanReqFriendTheme()
  local curTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local config = _G.DataConfigManager:GetBpGlobalConfig(7)
  local cdConfig = config and config.num or 0
  if cdConfig <= 0 then
    cdConfig = 10
    Log.Warning("CanReqFriendTheme: \230\151\160\230\179\149\232\142\183\229\143\150CD\233\133\141\231\189\174\239\188\140\228\189\191\231\148\168\233\187\152\232\174\164\229\128\18810\231\167\146")
  end
  if cdConfig <= curTime - self._lastReqFriendThemeTime then
    self._lastReqFriendThemeTime = curTime
    return true
  end
  return false
end

function BattlePassModuleData:GetAnotherThemePetId()
  local battlePassInfo = self:GetPlayerBattlePassInfo()
  if battlePassInfo and battlePassInfo.theme_id then
    local themeConf = _G.DataConfigManager:GetBattlePassThemeConf(battlePassInfo.theme_id)
    if themeConf and themeConf.another_pet_id then
      return themeConf.another_pet_id
    end
  end
  return 0
end

function BattlePassModuleData:GetAnotherThemePetName()
  local petId = self:GetAnotherThemePetId()
  if petId > 0 then
    local petConf = _G.DataConfigManager:GetPetbaseConf(petId)
    if petConf then
      return petConf.name or ""
    end
  end
  return ""
end

function BattlePassModuleData:GetAnotherThemePetIcon()
  local petId = self:GetAnotherThemePetId()
  if petId > 0 then
    local petConf = _G.DataConfigManager:GetPetbaseConf(petId)
    if petConf and petConf.model_conf then
      local modelConf = _G.DataConfigManager:GetModelConf(petConf.model_conf)
      if modelConf then
        return modelConf.icon or ""
      end
    end
  end
  return ""
end

function BattlePassModuleData:ResetReqFriendThemeCD()
  self._lastReqFriendThemeTime = 0
end

local function CompareBPFriendData(a, b)
  if a.online ~= b.online then
    return a.online
  end
  if a.unlocked_rel_node_num and b.unlocked_rel_node_num and a.unlocked_rel_node_num ~= b.unlocked_rel_node_num then
    return a.unlocked_rel_node_num > b.unlocked_rel_node_num
  end
  if a.level ~= b.level then
    return a.level > b.level
  end
  return a.uin < b.uin
end

function BattlePassModuleData:SortFriendList(friendList)
  if not friendList or 0 == #friendList then
    return friendList
  end
  table.sort(friendList, CompareBPFriendData)
  return friendList
end

return BattlePassModuleData
