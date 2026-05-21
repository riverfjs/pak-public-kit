local LevelUpUIModuleEvent = reload("NewRoco.Modules.System.LevelUpUI.LevelUpUIModuleEvent")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local UMG_LevelUpRewards_C = _G.NRCPanelBase:Extend("UMG_LevelUpRewards_C")

function UMG_LevelUpRewards_C:OnConstruct()
  self.HasGotRewards:SetShowLockIcon(false)
  self.CantGetRewards:SetTitleTextColor("#c7494aFF")
  self.GetRewardsBtn:SetRedDotKey(33)
  self.GetRewardsTaskBtn:SetRedDotKey(34)
end

function UMG_LevelUpRewards_C:OnActive()
  self:OnAddEventListener()
end

function UMG_LevelUpRewards_C:OnDestruct()
end

function UMG_LevelUpRewards_C:InitWithData(param)
  self.clickable = true
  self.HandScrolling = false
  self.SelectedIndex = nil
  self.Title:SetText("\230\150\135\230\156\172\232\175\187\228\184\141\229\136\176")
  local CurrentLevel = _G.DataConfigManager:GetLocalizationConf("Camp_Magic_dengji")
  self.CurrentLevel:SetText(CurrentLevel and CurrentLevel.msg or "\230\150\135\230\156\172\232\175\187\228\184\141\229\136\176")
  local RewardPreview = _G.DataConfigManager:GetLocalizationConf("Camp_Magic_yulan")
  self.RewardPreview:SetText(RewardPreview and RewardPreview.msg or "\230\150\135\230\156\172\232\175\187\228\184\141\229\136\176")
  self.CanAnimTick = false
  self.RedPointAnimTimer = 8
  self.DeltaTime = 0
  self.CircleAnimTimer = 0.2
  self.DeltaTime1 = 0
  self.CanSelectAnimTick = false
  self.CanPlaySelectOutAnim = true
  self.uiData = param
  self:updatePanelInfo()
  self:OnAddEventListener()
  local selectIndex = self.levelList1:SelectItemByOffset(330)
  self.levelList1:SelectItemByIndex(selectIndex - 1)
  local num = self.LevelTipsList:GetItemCount()
  for i = 1, num do
    local item = self.LevelTipsList:GetItemByIndex(i - 1)
    item:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.uiData.roleExpAwards then
    local num1 = #self.uiData.roleExpAwards
    for i = 1, num1 do
      local item = self.awardListScroll:GetItemByIndex(i - 1)
      item:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_LevelUpRewards_C:OnActive(_param)
  self:OnAddEventListener()
end

function UMG_LevelUpRewards_C:OnDeactive()
end

function UMG_LevelUpRewards_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.GetRewardsBtn.btnLevelUp, self.OnBtnGetRewardsClick)
  self:AddButtonListener(self.GetRewardsTaskBtn.btnLevelUp, self.OnBtnGetTaskClick)
  self.levelList1.OnUserScrolled:Add(self, self.OnLevelListScrolled)
  self:RegisterEvent(self, LevelUpUIModuleEvent.LEVLEUP_Close_Mask, self.CloseMask)
end

function UMG_LevelUpRewards_C:OnLevelListScrolled(offset)
  self.HandScrolling = true
  self.DeltaTime = 0
  self.DeltaTime1 = 0
  self.CanSelectAnimTick = true
  if self.CanPlaySelectOutAnim then
    local num = self.levelList1:GetItemCount()
    for i = 1, num do
      local item = self.levelList1:GetItemByIndex(i - 1)
      if item.index == self.curSelectedIndex then
        item:StopAnimation(item.Circle_in)
        item:PlayAnimation(item.Circle_out)
        break
      end
    end
    self.CanPlaySelectOutAnim = false
  end
end

function UMG_LevelUpRewards_C:OnCloseBtnClick()
  if _G.GlobalConfig.DebugOpenUI then
    self:DoClose()
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_LevelUpRewards_C:OnCloseBtnClick")
  self.owner:SwitchToInfo()
end

function UMG_LevelUpRewards_C:refreshRewardsPanel(_param)
  self.uiData = _param
  self:updatePanelInfo()
end

function UMG_LevelUpRewards_C:GetTaskRewardForWorldLevel(worldLevel)
  local worldLevelConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
  local worldLevelConf
  for i, item in ipairs(worldLevelConfTable) do
    if item.world_level == worldLevel then
      worldLevelConf = item
    end
  end
  if nil == worldLevelConf then
    return {}
  end
  local taskId = worldLevelConf.update_task_id
  local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
  local RewardId = taskConf.Reward
  local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId, true)
  local TaskReward = {}
  if nil == RewardConf then
    return TaskReward
  end
  for i, item in ipairs(RewardConf.RewardItem) do
    table.insert(TaskReward, {
      level_reward_type = item.Type,
      level_reward_id = item.Id,
      level_reward_count = item.Count
    })
  end
  return TaskReward
end

function UMG_LevelUpRewards_C:GetRewardsDataById(RewardId)
  RewardId = RewardId or 0
  local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId, true)
  local TaskReward = {}
  if nil == RewardConf then
    return TaskReward
  end
  for i, item in ipairs(RewardConf.RewardItem) do
    table.insert(TaskReward, {
      level_reward_type = item.Type,
      level_reward_id = item.Id,
      level_reward_count = item.Count
    })
  end
  return TaskReward
end

function UMG_LevelUpRewards_C:SortItem(RewardsList)
  local SortRewardsList = {}
  for i, Reward in ipairs(RewardsList) do
    local GoodItem = {}
    GoodItem.id = Reward.level_reward_id
    GoodItem.type = Reward.level_reward_type
    GoodItem.num = Reward.level_reward_count
    GoodItem.level_reward_id = Reward.level_reward_id
    GoodItem.level_reward_type = Reward.level_reward_type
    GoodItem.level_reward_count = Reward.level_reward_count
    GoodItem.Sort = 0
    GoodItem.Quality = 0
    if Reward.level_reward_type == _G.ProtoEnum.GoodsType.GT_VITEM then
      GoodItem.Conf = _G.DataConfigManager:GetVisualItemConf(Reward.level_reward_id)
      GoodItem.Sort = GoodItem.Conf.sort_id
      GoodItem.Quality = GoodItem.Conf.item_quality
    elseif Reward.level_reward_type == _G.ProtoEnum.GoodsType.GT_PET then
      GoodItem.Sort = 0
      GoodItem.Conf = _G.DataConfigManager:GetPetbaseConf(Reward.level_reward_id)
      GoodItem.Quality = 0
    elseif Reward.level_reward_type == _G.ProtoEnum.GoodsType.GT_BAGITEM then
      GoodItem.Conf = _G.DataConfigManager:GetBagItemConf(Reward.level_reward_id)
      GoodItem.Sort = GoodItem.Conf.sort_id
      GoodItem.Quality = GoodItem.Conf.item_quality
    end
    SortRewardsList[i] = GoodItem
  end
  table.sort(SortRewardsList, function(a, b)
    if a.Quality ~= b.Quality then
      return a.Quality > b.Quality
    end
    if a.Sort < b.Sort then
      return a.Sort < b.Sort
    elseif a.Sort == b.Sort then
      local ANewSort = a.id
      local BNewSort = b.id
      if a.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        ANewSort = ANewSort + 9999999
      elseif b.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        BNewSort = BNewSort + 9999999
      end
      return ANewSort < BNewSort
    end
  end)
  return SortRewardsList
end

function UMG_LevelUpRewards_C:refreshLevelUpRewardsList(Data)
  self.uiData.roleExpAwards = {}
  if Data then
    local roleExpConf = Data.data
    if roleExpConf then
      if 1 == Data.type then
        self.uiData.roleExpAwards = roleExpConf.reward
      elseif 2 == Data.type then
        self.uiData.roleExpAwards = self:GetRewardsDataById(Data.data.world_level_reward_show)
      end
      local SortReward = self:SortItem(self.uiData.roleExpAwards)
      if 2 == Data.type then
        if SortReward and #SortReward > 0 then
          self.awardListScroll1:SetVisibility(UE4.ESlateVisibility.Visible)
          self.awardListScroll1:InitList(SortReward)
        else
          self.awardListScroll1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self.awardListScroll1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.awardListScroll:InitList(SortReward)
      end
      if 1 == Data.type and 2 == Data.awardState then
        for i, _ in ipairs(self.uiData.roleExpAwards) do
          local Item = self.awardListScroll:GetItemByIndex(i - 1)
          if Item then
            Item:SetAlreadyReceived()
          end
        end
      end
      local descList = {}
      local PlayerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
      if roleExpConf then
        if _G.BinDataUtils.IsPropertyExist(roleExpConf, "update_task_des") then
          if 1 == Data.awardState or 5 == Data.awardState then
            table.insert(descList, {
              content = roleExpConf.update_task_des,
              isLocked = true,
              isUpdateTaskDes = true,
              value = roleExpConf.title
            })
          else
            table.insert(descList, {
              content = roleExpConf.update_task_des,
              isLocked = false,
              isUpdateTaskDes = true,
              value = roleExpConf.title
            })
          end
        end
        if _G.BinDataUtils.IsPropertyExist(roleExpConf, "revival_desc") and #roleExpConf.revival_desc >= 1 then
          for _, i in pairs(roleExpConf.revival_desc) do
            local iconPath = i.up_icon
            local value
            if i.upvalue then
              value = i.upvalue
            end
            table.insert(descList, {
              content = i.desc,
              icon = iconPath,
              isLocked = PlayerLevel < Data.level,
              isUpdateTaskDes = false,
              value = value
            })
          end
        end
      end
      self.CanvasPanel_63:SetVisibility(#descList > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
      self.awardListScroll:SetVisibility(#descList > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
      self.LevelTipsList:InitGridView(descList)
    end
  end
end

function UMG_LevelUpRewards_C:changeRewardsBtnState(itemData)
  self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.GetRewardsTaskBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.HasGotRewards:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.GetRewardsBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.clickable = true
  if 1 == itemData.type then
    if 0 == itemData.awardState then
      self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CantGetRewards:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Low_2").msg)
      self.CantGetRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Low").msg)
    elseif 1 == itemData.awardState then
      self.GetRewardsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.GetRewardsBtn:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Conform").msg)
    elseif 2 == itemData.awardState then
      self.HasGotRewards:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.HasGotRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Get").msg)
    elseif 5 == itemData.awardState then
      self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CantGetRewards:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Low_2").msg)
      self.CantGetRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Lv_Low").msg)
    end
  elseif 2 == itemData.type then
    if 1 == itemData.awardState then
      self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CantGetRewards:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("Role_Award_Look_Last_Tips_2").msg)
      self.CantGetRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Look_Last_Tips").msg)
    elseif 2 == itemData.awardState then
      self.GetRewardsTaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.GetRewardsTaskBtn:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Task_Receive").msg)
    elseif 3 == itemData.awardState then
      self.HasGotRewards:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.HasGotRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Task_Get").msg)
    elseif 4 == itemData.awardState then
      self.HasGotRewards:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.HasGotRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Task_Complete").msg)
    elseif 5 == itemData.awardState then
      self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CantGetRewards:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("Role_Award_Look_Last_Tips_2").msg)
      self.CantGetRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Look_Last_Tips").msg)
    elseif 6 == itemData.awardState then
      self.CantGetRewards:SetVisibility(UE4.ESlateVisibility.Visible)
      self.CantGetRewards:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("online_task_unable_text").msg)
      self.CantGetRewards:SetBtnText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Look_Last_Tips").msg)
    end
  end
end

function UMG_LevelUpRewards_C:OnBtnGetRewardsClick()
  if self.owner.isPlayingAnimation then
    return
  end
  if not self.clickable then
    return
  end
  self.clickable = false
  self.DeltaTime = 0
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_LevelUpRewards_C:OnBtnGetRewardsClick")
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE, self.OnItemRewardsClose)
  self.Mask:SetVisibility(UE4.ESlateVisibility.Visible)
  _G.NRCModuleManager:DoCmd(LevelUpUIModuleCmd.SendGetLevelAwardReq, self.currentUiData.level)
end

function UMG_LevelUpRewards_C:CloseMask()
  self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LevelUpRewards_C:OnBtnGetTaskClick()
  if self.owner.isPlayingAnimation then
    return
  end
  if not self.clickable then
    return
  end
  self.DeltaTime = 0
  self.clickable = false
  local req = _G.ProtoMessage:newZoneWorldLevelTaskOpenReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_WORLD_LEVEL_TASK_OPEN_REQ, req, self, self.OnWorldLevelTaskOpenRsp, true, true)
end

function UMG_LevelUpRewards_C:OnWorldLevelTaskOpenRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.BackToWorldFast)
  else
    Log.Error("\228\187\187\229\138\161\230\142\165\229\143\150\229\164\177\232\180\165")
  end
end

function UMG_LevelUpRewards_C:OnItemRewardsClose()
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE)
end

function UMG_LevelUpRewards_C:updateLevelListInfo(_param)
  if nil == _param then
    return
  end
  table.insert(_param, 1, {awardState = -1, level = 0})
  table.insert(_param, 2, {awardState = -1, level = 0})
  table.insert(_param, {awardState = -1, level = 0})
  table.insert(_param, {awardState = -1, level = 0})
  table.insert(_param, {awardState = -1, level = 0})
  self.uiData = _param
  Log.Dump(_param, 2, "UMG_LevelUpRewards_C_addParam")
  if #_param > 0 then
    self.levelList1:InitList(_param)
    local num = self.levelList1:GetItemCount()
    for i = 1, num do
      local item = self.levelList1:GetItemByIndex(i - 1)
      if item.index == self.curSelectedIndex then
        item:PlayAnimation(item.Get)
        break
      end
    end
  else
  end
  if #_param > 0 then
    if self.SelectedIndex then
    else
      local minLevel = self:CalcMinIndex(_param)
      self.SelectedIndex = minLevel - 1
      if minLevel < 1 then
        self.levelList1:ScrollToIndex(minLevel, true)
      else
        self.levelList1:ScrollToIndex(minLevel - 1, true)
      end
    end
    self.uiData.lastIndex = 0
    self.SelectedIndex = self.uiData.lastIndex - 3
  end
end

function UMG_LevelUpRewards_C:OnTick(deltaTime)
  if self.CanAnimTick then
    self.DeltaTime = self.DeltaTime + deltaTime
    if self.DeltaTime >= self.RedPointAnimTimer then
      self.DeltaTime = 0
      local num = self.levelList1:GetItemCount()
      for i = 1, num do
        local item = self.levelList1:GetItemByIndex(i - 1)
        if item.index == self.curSelectedIndex then
          if item.NrcRedPoint:IsRed() then
            item.NrcRedPoint:PlayAnimation(item.NrcRedPoint.In)
          end
          break
        end
      end
    end
  end
  if self.CanSelectAnimTick then
    self.DeltaTime1 = self.DeltaTime1 + deltaTime
    if self.DeltaTime1 >= self.CircleAnimTimer then
      self.DeltaTime1 = 0
      self.CanSelectAnimTick = false
      local num = self.levelList1:GetItemCount()
      for i = 1, num do
        local item = self.levelList1:GetItemByIndex(i - 1)
        if item.index == self.curSelectedIndex and item.RenderTransform.Scale.x - 1.0 <= 0.1 and item.RenderTransform.Scale.x - 1.0 >= -0.1 then
          item:StopAnimation(item.Circle_out)
          item:PlayAnimation(item.Circle_in)
          self.CanPlaySelectOutAnim = true
          break
        end
        if i == num then
          self.CanSelectAnimTick = true
        end
      end
    end
  end
  if false == self.HandScrolling then
    self.levelList1:TempTick(deltaTime, 0)
  end
  local index = self.levelList1:SelectItemByOffset(330)
  if index ~= self.SelectedIndex and false == self.levelList1.bScrollBySelf then
    self.levelList1:SelectItemByIndex(index)
  end
  self.SelectedIndex = index
  self.HandScrolling = false
end

function UMG_LevelUpRewards_C:OnLevelListItemSelected(item, index)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1084, "UMG_LevelUpRewards_C:OnLevelListItemSelected")
  self.curSelectedIndex = index
  self:OnItemClick(index)
end

function UMG_LevelUpRewards_C:ChangeLevelListSelected(index)
  if self.CanPlaySelectOutAnim and index ~= self.curSelectedIndex then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_LevelUpIconTemplate_C:OnSelectionChange")
    local num = self.levelList1:GetItemCount()
    for i = 1, num do
      local item = self.levelList1:GetItemByIndex(i - 1)
      if item.index == self.curSelectedIndex then
        item:StopAnimation(item.Circle_in)
        item:PlayAnimation(item.Circle_out)
        break
      end
    end
    self.CanPlaySelectOutAnim = false
  end
  if index ~= self.curSelectedIndex then
    self.DeltaTime1 = 0
    self.CanSelectAnimTick = true
  end
  self.curSelectedIndex = index
  self:OnItemClick(index)
end

function UMG_LevelUpRewards_C:CalcMinIndex(_param)
  Log.Dump(_param, 2, "Calc_MinLevel")
  local minIndex
  local maxIndex = 3
  for i, v in ipairs(_param) do
    if 1 == v.type then
      if 1 == v.awardState then
        minIndex = i
      end
      if 1 == v.awardState or 2 == v.awardState then
        maxIndex = i
      end
    elseif 2 == v.type then
      if 2 == v.awardState then
        minIndex = i
      end
      if 2 == v.awardState or 3 == v.awardState or 4 == v.awardState then
        maxIndex = i
      end
    end
  end
  if nil == minIndex then
    minIndex = maxIndex
  end
  minIndex = minIndex - 2
  return minIndex
end

function UMG_LevelUpRewards_C:OnItemClick(index)
  self:refreshLevelUpRewardsList(self.uiData[index])
  self.DeltaTime = 0
  if index <= #self.uiData and index > 0 then
    self:changeRewardsBtnState(self.uiData[index])
    self:UpdateTitle(self.uiData[index])
    self.currentUiData = self.uiData[index]
  end
end

function UMG_LevelUpRewards_C:UpdateTitle(itemData)
  if 1 == itemData.type then
    self.Title:SetText(_G.DataConfigManager:GetLocalizationConf("Camp_TITLE_magic").msg)
  elseif 2 == itemData.type then
    self.Title:SetText(_G.DataConfigManager:GetLocalizationConf("Role_Award_Title").msg)
  end
end

function UMG_LevelUpRewards_C:updatePanelInfo()
  self:updateLevelListInfo(self.uiData)
  local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local levelText = 0
  if level < 10 then
    levelText = "0" .. level
  else
    levelText = level
  end
  self.SubTitle2:SetText(levelText)
end

function UMG_LevelUpRewards_C:OnAnimationFinished(Animation)
  if Animation == self.In then
    self.owner.isPlayingAnimation = false
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif Animation == self.Out then
    local num = self.LevelTipsList:GetItemCount()
    for i = 1, num do
      local item = self.LevelTipsList:GetItemByIndex(i - 1)
      item:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.uiData.roleExpAwards then
      local num1 = #self.uiData.roleExpAwards
      for i = 1, num1 do
        local item = self.awardListScroll:GetItemByIndex(i - 1)
        item:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanAnimTick = false
    self.owner:InfoPlayIn()
  end
end

return UMG_LevelUpRewards_C
