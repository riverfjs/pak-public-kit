local UMG_Cooking_Equip_C = _G.NRCPanelBase:Extend("UMG_Cooking_Equip_C")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")

function UMG_Cooking_Equip_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Cooking_Equip_C:AddEventListener()
  self:AddButtonListener(self.EquipBtn_1.btnLevelUp, self.OnClickEquipButton)
  self:AddButtonListener(self.ChangeBtn.btnLevelUp, self.OnClickChangeBtn)
  self:AddButtonListener(self.DemountBtn.btnLevelUp, self.OnClickUnload)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BagModuleEvent.RefreshTypeItemInfo, self.RefreshUI)
  
  local function callback(caller, ...)
    self:OnEquipFoodChange(...)
  end
  
  self.module:RegisterEvent(self, HomeModuleEvent.OnEquipFoodChange, callback)
  _G.NRCEventCenter:RegisterEvent("UMG_Cooking_Equip_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function UMG_Cooking_Equip_C:OnEquipFoodChange(bEquip, itemId, itemNum)
  if bEquip then
    self.currentEquipId = itemId
  else
    self.currentEquipId = nil
  end
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OnCmdGetTypeBagItem, _G.Enum.BagItemType.BI_HOME_PET_FEED)
end

function UMG_Cooking_Equip_C:OnClickEquipButton()
  if self.cdTimer ~= nil then
    return
  else
    self.cdTimer = _G.TimerManager:CreateTimer(self, "UMG_Cooking_Equip", 0.5, nil, self.OnTimerEnd, 0.1)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Cooking_Equip_C:OnClickEquipButton")
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.OnCmdEquipFood, self.selectFoodItemId)
end

function UMG_Cooking_Equip_C:OnClickChangeBtn()
  if self.cdTimer ~= nil then
    return
  else
    self.cdTimer = _G.TimerManager:CreateTimer(self, "UMG_Cooking_Equip", 0.5, nil, self.OnTimerEnd, 0.1)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Cooking_Equip_C:OnClickChangeBtn")
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.OnCmdReplaceFood, self.selectFoodItemId)
end

function UMG_Cooking_Equip_C:OnClickUnload()
  if self.cdTimer ~= nil then
    return
  else
    self.cdTimer = _G.TimerManager:CreateTimer(self, "UMG_Cooking_Equip", 0.5, nil, self.OnTimerEnd, 0.1)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Cooking_Equip_C:OnClickUnload")
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.OnCmdUnLoadFood, self.selectFoodItemId)
end

function UMG_Cooking_Equip_C:OnTimerEnd()
  if self.cdTimer then
    _G.TimerManager:RemoveTimer(self.cdTimer)
    self.cdTimer = nil
  end
end

function UMG_Cooking_Equip_C:ShowIfHasFood(bHasFoodList)
  if bHasFoodList then
    self.CanvasPanel_125:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pocket:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(0)
  else
    self.Switcher:SetActiveWidgetIndex(1)
  end
end

function UMG_Cooking_Equip_C:OnActive(rsp)
  _G.NRCAudioManager:PlaySound2DAuto(41400007, "UMG_Cooking_Equip_C:OnActive")
  self:LoadAnimation(0)
  self.currentEquipId, _ = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdGetEquipFoodIdAndNum)
  if not self.uiData then
    self.uiData = {}
  end
  self:InitPopUpData()
  self:AddEventListener()
  Log.Dump(rsp, 5, "UMG_Cooking_Equip_C OnFoodInfoRsp")
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowIfHasFood(false)
    return
  end
  if 0 == #rsp.bag_info.item_list then
    Log.Error("UMG_Cooking_Equip_C OnFoodInfoRsp with on valid bag info")
    self:ShowIfHasFood(false)
    return
  end
  self:RefreshUI(rsp)
end

function UMG_Cooking_Equip_C:RefreshUI(rsp)
  local foodItemInfo = {}
  local bHasSelect = false
  for _, food in ipairs(rsp.bag_info.item_list) do
    if food.type == _G.Enum.BagItemType.BI_HOME_PET_FEED then
      local itemList = food.items
      if not itemList then
        Log.Error("UMG_Cooking_Equip_C OnFoodInfoRsp with on valid itemList")
        self:ShowIfHasFood(false)
        return
      end
      for _, item in ipairs(itemList) do
        if item.bag_item_flags ~= nil and 0 ~= item.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED then
          bHasSelect = true
          self.selectFoodItemId = item.id
        end
        if not _G.DataConfigManager:GetHomePetFeedConf(item.id) then
        else
          local confNeedTime = _G.DataConfigManager:GetHomePetFeedConf(item.id).need_time
          if item.num <= 0 then
          else
            table.insert(foodItemInfo, {
              Id = item.id,
              num = item.num,
              updateTime = item.update_time,
              caller = self,
              callback = self.OnFoodSelected,
              bEquipping = item.bag_item_flags ~= nil and 0 ~= item.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED,
              needTime = confNeedTime,
              itemType = _G.Enum.BagItemType.BI_HOME_PET_FEED
            })
            if not self.uiData then
              self.uiData = {}
            end
            self.uiData[item.id] = item.num
          end
        end
      end
    end
  end
  if 0 == #foodItemInfo then
    self:ShowIfHasFood(false)
    return
  end
  table.sort(foodItemInfo, function(a, b)
    if a.bEquipping == b.bEquipping then
      local bagItemConfA = _G.DataConfigManager:GetBagItemConf(a.Id)
      local bagItemConfB = _G.DataConfigManager:GetBagItemConf(b.Id)
      if not bagItemConfA or not bagItemConfB then
        return true
      end
      local sortIdA = bagItemConfA.sort_id
      local sortIdB = bagItemConfB.sort_id
      if sortIdA and sortIdB then
        return sortIdA < sortIdB
      else
        return a.Id < b.Id
      end
    else
      return a.bEquipping == true
    end
  end)
  self:ShowIfHasFood(true)
  self.FoodList_1:InitList(foodItemInfo)
  self.FoodList_1:SelectItemByIndex(0)
  self:UpdateDetailInfo()
end

function UMG_Cooking_Equip_C:OnFoodSelected(foodItemId, bSelected)
  if bSelected then
    self.selectFoodItemId = foodItemId
    self:UpdateDetailInfo()
    return true
  end
  return false
end

function UMG_Cooking_Equip_C:UpdateDetailInfo()
  local selectFoodItemId = self.selectFoodItemId
  if not selectFoodItemId then
    return
  end
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(selectFoodItemId)
  if not bagItemConf then
    return
  end
  self.FoodTitle_1:SetText(bagItemConf.name)
  self.FoodText_1:SetText(bagItemConf.type_desc)
  self.FoodDescription_1:SetText(bagItemConf.description)
  self.FoodIcon:SetPath(bagItemConf.big_icon)
  local num = self.uiData[selectFoodItemId]
  if nil ~= num then
    self.ItemNum:SetText(tostring(num))
    self.ItemNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ItemNum:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local homeFeedConf = _G.DataConfigManager:GetHomePetFeedConf(selectFoodItemId)
  if homeFeedConf then
    local need_time = homeFeedConf.need_time
    if need_time then
      local need_time_text = ""
      local need_hour = math.floor(need_time // 60)
      if need_hour >= 1 then
        need_time_text = string.format(LuaText.clear_plant_confirm_text_h, need_hour)
      else
        need_time_text = string.format(LuaText.clear_plant_confirm_text_m, need_time)
      end
      if not string.IsNilOrEmpty(need_time_text) then
        self.CareTextTime:SetText(need_time_text)
      end
    end
    local outputCoin = homeFeedConf.furniture_coin_num
    local outputHomeExp = homeFeedConf.home_exp_num
    self.OutputText_1:SetText(outputCoin or "")
    self.OutputText:SetText(outputHomeExp or "")
  end
  local selectItemConf = _G.DataConfigManager:GetBagItemConf(selectFoodItemId)
  local acquireStruct = {}
  if selectItemConf then
    for i = 1, #selectItemConf.acquire_struct do
      if nil ~= selectItemConf.acquire_struct[i].acquire_way_text then
        table.insert(acquireStruct, selectItemConf.acquire_struct[i])
      end
    end
  end
  self.AccessRoute:InitGridView(acquireStruct)
  local equippedItemId, _ = _G.NRCModuleManager:DoCmd(HomeModuleCmd.OnCmdGetEquipFoodIdAndNum)
  if equippedItemId then
    if equippedItemId == self.selectFoodItemId then
      self.NRCSwitcher_122:SetActiveWidgetIndex(2)
    else
      self.NRCSwitcher_122:SetActiveWidgetIndex(1)
    end
  else
    self.NRCSwitcher_122:SetActiveWidgetIndex(0)
  end
end

function UMG_Cooking_Equip_C:InitPopUpData()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = LuaText.home_pet_feed_title
  CommonPopUpData.Call = self
  CommonPopUpData.PopUpType = 2
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = self.ClosePanel
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Cooking_Equip_C:OnReconnectFinish()
  if self.cdTimer then
    _G.TimerManager:RemoveTimer(self.cdTimer)
    self.cdTimer = nil
  end
  local req = ProtoMessage:newZoneGetBagReq()
  req.type = _G.Enum.BagItemType.BI_HOME_PET_FEED
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, req, self, self.OnReconnectFinishUpdate)
end

function UMG_Cooking_Equip_C:OnReconnectFinishUpdate(rsp)
  Log.Dump(rsp, 5, "BagItemTypeList")
  for _, food in ipairs(rsp.bag_info.item_list) do
    if food.type == _G.Enum.BagItemType.BI_HOME_PET_FEED then
      local itemList = food.items
      if not itemList then
        Log.Error("UMG_Cooking_Equip_C OnFoodInfoRsp with on valid itemList")
        _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, nil, 0)
        self:DoClose()
        return
      end
      for _, item in ipairs(itemList) do
        if item.bag_item_flags ~= nil and 0 ~= item.bag_item_flags & ProtoEnum.BagItemFlag.HOMEPET_FOOD_EQUIPPED then
          local equipFoodNum = item.num
          local equipFoodId = item.id
          _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, equipFoodId, equipFoodNum)
          self:DoClose()
          return
        end
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, nil, 0)
  self:DoClose()
end

function UMG_Cooking_Equip_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002014, "UMG_Cooking_Equip_C:ClosePanel")
  self:LoadAnimation(2)
end

function UMG_Cooking_Equip_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Cooking_Equip_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.RefreshTypeItemInfo, self.RefreshUI)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  if self.module then
    self.module:UnRegisterEvent(self, HomeModuleEvent.OnEquipFoodChange)
  end
  if self.cdTimer then
    _G.TimerManager:RemoveTimer(self.cdTimer)
    self.cdTimer = nil
  end
end

return UMG_Cooking_Equip_C
