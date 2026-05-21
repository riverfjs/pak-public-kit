local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local HomeEnum = require("NewRoco/Modules/System/Home/HomeEnum")
local UMG_FurnitureAtlasPanel_C = _G.NRCPanelBase:Extend("UMG_FurnitureAtlasPanel_C")
local NumberFurniturePng = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_NumberFurniture_png.img_NumberFurniture_png'"

function UMG_FurnitureAtlasPanel_C:OnConstruct()
  self.ComboBox_White.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.curSortId = 1
  self.IsReversalSort = false
  self.bOpenAwardList = false
  self.bSelectItemAward = false
  self.selectedIndex = nil
  self.relatedFriendData = nil
  self.DropDownListData = nil
  self.furnitureData = nil
  self.bShowTestUMG = false
  self.bWaitReward = false
  self.tabFilterTable = {}
  self.workingListData = {}
  self:BindInputAction()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, false)
end

function UMG_FurnitureAtlasPanel_C:OnActive(listInfo)
  self:OnAddEventListener()
  local limitNum = self.module:GetData():GetFurnitureAtlasNum()
  self.UpperLimit:InitNum(0, limitNum, nil, true, NumberFurniturePng, nil, nil, true)
  local bagData = _G.NRCModuleManager:GetModule("BagModule"):GetData("BagModuleData")
  self.furnitureData = bagData:GetBagItemByLableType(Enum.ItemLableType.ILT_FURNITURE)
  local coinNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_FURNITURE_COIN)
  local moneyBtnData = {
    {
      moneyType = _G.Enum.VisualItem.VI_FURNITURE_COIN,
      sum = coinNum,
      IsShowBuyIcon = false
    }
  }
  self.MoneyBtn:InitGridView(moneyBtnData)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  CommonDropDownListData.DropDownListInfo = {}
  local localStrings = {
    _G.DataConfigManager:GetLocalizationConf("furniture_handbook_sort_id").msg,
    _G.DataConfigManager:GetLocalizationConf("furniture_handbook_sort_time").msg
  }
  for i = 1, 2 do
    local itemData = {}
    itemData.isHideRedDot = true
    itemData.name = localStrings[i]
    itemData.ComType = CommonBtnEnum.ComboBoxType.HomeFurniture
    table.insert(CommonDropDownListData.DropDownListInfo, itemData)
  end
  self.DropDownListData = CommonDropDownListData.DropDownListInfo
  CommonDropDownListData.DropDownListText = localStrings[1]
  CommonDropDownListData.Btn_LeftHandler = self.OpenFilterPanel
  CommonDropDownListData.Btn_RightHandler = self.OnClickReverse
  CommonDropDownListData.Call = self
  self.ComboBox_White:SetPanelInfo(CommonDropDownListData)
  self.ComboBox_White.OnPopupVisibilityChanged = _G.MakeWeakFunctor(self, self.SetGlobalBtn)
  self:InitPanel(listInfo)
end

function UMG_FurnitureAtlasPanel_C:InitPanel(listInfo)
  local num = 0
  local limitNum = 0
  for i, v in pairs(listInfo) do
    if 1 ~= v.reward_status then
      num = num + 1
    end
    limitNum = limitNum + 1
  end
  self.seedListDatas = table.new(limitNum, 0)
  self.workingListData = self.seedListDatas
  self.DisplayNumInTab = {}
  local weakTable = {}
  weakTable.__mode = "v"
  for i, v in pairs(listInfo) do
    table.insert(self.seedListDatas, v)
  end
  self:SortSeedList(self.seedListDatas)
  local HomeModuleData = HomeIndoorSandbox.Module:GetData()
  for i = 1, #self.seedListDatas do
    self.seedListDatas[i].parent = self
    setmetatable(self.seedListDatas[i], weakTable)
    local handbookConf = _G.DataConfigManager:GetFurnitureHandbookConf(self.seedListDatas[i].id)
    if handbookConf and handbookConf.furniture_id and HomeModuleData then
      local furnitureItemConf = _G.DataConfigManager:GetFurnitureItemConf(handbookConf.furniture_id)
      if furnitureItemConf and furnitureItemConf.classification then
        local tabId = furnitureItemConf.classification
        local firstTabId = HomeModuleData:GetFirstTabId(tabId)
        if tabId and firstTabId then
          if self.DisplayNumInTab[tabId] == nil then
            self.DisplayNumInTab[tabId] = 0
          end
          if self.DisplayNumInTab[firstTabId] == nil then
            self.DisplayNumInTab[firstTabId] = 0
          end
          self.DisplayNumInTab[tabId] = self.DisplayNumInTab[tabId] + 1
          if firstTabId ~= tabId then
            self.DisplayNumInTab[firstTabId] = self.DisplayNumInTab[firstTabId] + 1
          end
        end
      end
    end
  end
  self.SeedList:InitList(self.workingListData)
  self.SeedList:SelectItemByIndex(0)
  self.UpperLimit:InitNum(num, limitNum, nil, true, NumberFurniturePng, nil, nil, true)
  self.DetailPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_FurnitureAtlasPanel_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_FurnitureAtlasPanel_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_FurnitureAtlasPanel_C", self, HomeModuleEvent.OnComboBoxSelectChanged, self.OnComboBoxSelectChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_FurnitureAtlasPanel_C", self, HomeModuleEvent.GetMoreFriendDataByFurnitureId, self.GetMoreFriendData)
  _G.NRCEventCenter:RegisterEvent("UMG_FurnitureAtlasPanel_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  self:RegisterEvent(self, HomeModuleEvent.UpdateFurnitureFilter, self.OnFilterUpdate)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.AwardBtn, self.OnAwardBtnClicked)
  self:AddButtonListener(self.SynthesisBtn.btnLevelUp, self.OnSynthesisBtnClicked)
  self:AddButtonListener(self.CloseBtn_Global, self.OnCloseComboBox)
  self:AddButtonListener(self.CopyBtn1, self.CopeScale)
  self:AddButtonListener(self.CopyBtn2, self.CopeRotation)
  self:AddButtonListener(self.CloseBtn_L, self.CloseRewardPreview)
  self:AddButtonListener(self.CloseBtn_U, self.CloseRewardPreview)
  self:AddButtonListener(self.CloseBtn_R, self.CloseRewardPreview)
  self:AddButtonListener(self.CloseBtn_D, self.CloseRewardPreview)
  self.Slider_Up.OnValueChanged:Add(self, self.OnSliderUpChange)
  self.Slider_Down.OnValueChanged:Add(self, self.OnSliderDownChange)
  self.Slider_Right.OnValueChanged:Add(self, self.OnSliderRightChange)
end

function UMG_FurnitureAtlasPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, HomeModuleEvent.OnComboBoxSelectChanged, self.OnComboBoxSelectChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, HomeModuleEvent.GetMoreFriendDataByFurnitureId, self.GetMoreFriendData)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  self:UnRegisterEvent(self, HomeModuleEvent.UpdateFurnitureFilter, self.OnFilterUpdate)
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.AwardBtn)
  self:RemoveButtonListener(self.SynthesisBtn.btnLevelUp)
  self:RemoveButtonListener(self.CloseBtn_Global)
  self:RemoveButtonListener(self.CopyBtn1)
  self:RemoveButtonListener(self.CopyBtn2)
  self:RemoveButtonListener(self.CloseBtn_L)
  self:RemoveButtonListener(self.CloseBtn_U)
  self:RemoveButtonListener(self.CloseBtn_R)
  self:RemoveButtonListener(self.CloseBtn_D)
  self.Slider_Up.OnValueChanged:Remove(self, self.OnSliderUpChange)
  self.Slider_Down.OnValueChanged:Remove(self, self.OnSliderDownChange)
  self.Slider_Right.OnValueChanged:Remove(self, self.OnSliderRightChange)
end

function UMG_FurnitureAtlasPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_FurnitureAtlas")
  if mappingContext then
    mappingContext:BindAction("IA_FurnitureHandbook_Close", self, "OnPcClose")
    mappingContext:BindAction("IA_FurnitureHandbook_QuickClose", self, "OnPcClose")
  end
end

function UMG_FurnitureAtlasPanel_C:OnSliderUpChange(value)
  self.HomeFurniturePreview:ChangeScale(value / 10000)
end

function UMG_FurnitureAtlasPanel_C:OnSliderDownChange(value)
  self.HomeFurniturePreview:ChangeRotation(self.Slider_Right:GetValue(), -value)
end

function UMG_FurnitureAtlasPanel_C:OnSliderRightChange(value)
  self.HomeFurniturePreview:ChangeRotation(value, -self.Slider_Down:GetValue())
end

function UMG_FurnitureAtlasPanel_C:CopeScale()
  local stringScale = tostring(math.floor(self.Slider_Up:GetValue()))
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\229\183\178\231\187\143\230\139\183\232\180\157\231\188\169\230\148\190\228\191\161\230\129\175\239\188\154" .. stringScale)
  UE4.UNRCStatics.ClipboardCopy(stringScale)
end

function UMG_FurnitureAtlasPanel_C:CopeRotation()
  local stringRotation = math.floor(self.Slider_Right:GetValue()) .. ";" .. math.floor(-self.Slider_Down:GetValue())
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\229\183\178\231\187\143\230\139\183\232\180\157\230\151\139\232\189\172\228\191\161\230\129\175\239\188\154" .. stringRotation)
  UE4.UNRCStatics.ClipboardCopy(stringRotation)
end

function UMG_FurnitureAtlasPanel_C:OpenDebugPanel()
  local visibility = self.bShowTestUMG and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
  self.Slider_Up:SetVisibility(visibility)
  self.Slider_Down:SetVisibility(visibility)
  self.Slider_Right:SetVisibility(visibility)
  self.CopyBtn1:SetVisibility(visibility)
  self.CopyBtn2:SetVisibility(visibility)
end

function UMG_FurnitureAtlasPanel_C:InitSlider(handbook_id)
  local furnitureHandbookConf = _G.DataConfigManager:GetFurnitureHandbookConf(handbook_id)
  local angles = furnitureHandbookConf.Funiture_ui_handbook_angle
  local handbookAngle = string.split(angles, ";")
  self.Slider_Up:SetValue(furnitureHandbookConf.Funiture_ui_handbook_percentage)
  self.Slider_Down:SetValue(-tonumber(handbookAngle[2]))
  self.Slider_Right:SetValue(tonumber(handbookAngle[1]))
end

function UMG_FurnitureAtlasPanel_C:OnCloseButtonClicked()
  local mappingContext = self:GetInputMappingContext("IMC_FurnitureAtlas")
  if mappingContext then
    mappingContext:UnBindAction("IA_FurnitureHandbook_Close")
    mappingContext:UnBindAction("IA_FurnitureHandbook_QuickClose")
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008006, "UMG_FurnitureAtlasPanel_C:OnCloseButtonClicked")
  _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CloseFurnitureAtlasPanel)
end

function UMG_FurnitureAtlasPanel_C:OnPcClose()
  self:OnCloseButtonClicked()
end

function UMG_FurnitureAtlasPanel_C:OnItemSelected(_itemInst)
  if self.bNeedNewFriendData then
    self.furnitureIdToFriendListDic[self.furniture_id] = nil
    self.furnitureIdToPageAndFriendNum[self.furniture_id] = nil
    self.bNeedNewFriendData = nil
  end
  self.selectedIndex = _itemInst.index
  self.bSelectItemAward = 3 == _itemInst.itemData.reward_status
  self.RewardPreview:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bOpenAwardList = false
  self:SetRewardPreviewBtn(false)
  self:UpdateDetailPanel(_itemInst.itemData)
  self.RedDot:SetupKey(344, _itemInst.itemData.id)
  if self.bShowTestUMG then
    self:InitSlider(_itemInst.itemData.id)
  end
  self.handbook_id = _itemInst.itemData.id
end

function UMG_FurnitureAtlasPanel_C:SortDefault(listInfo)
  table.sort(listInfo, function(a, b)
    if 1 ~= a.reward_status and 1 == b.reward_status then
      return true
    elseif 1 == a.reward_status and 1 ~= b.reward_status then
      return false
    elseif self.IsReversalSort then
      return a.id > b.id
    else
      return a.id < b.id
    end
  end)
end

function UMG_FurnitureAtlasPanel_C:SortByTime(listInfo)
  table.sort(listInfo, function(a, b)
    if 1 ~= a.reward_status and 1 == b.reward_status then
      return true
    elseif 1 == a.reward_status and 1 ~= b.reward_status then
      return false
    elseif 1 ~= a.reward_status and 1 ~= b.reward_status then
      if self.IsReversalSort then
        return a.unlock_time < b.unlock_time
      else
        return a.unlock_time > b.unlock_time
      end
    elseif self.IsReversalSort then
      return a.id > b.id
    else
      return a.id < b.id
    end
  end)
end

function UMG_FurnitureAtlasPanel_C:SortSeedList(listInfo)
  if 1 == self.curSortId then
    self:SortDefault(listInfo)
  else
    self:SortByTime(listInfo)
  end
end

function UMG_FurnitureAtlasPanel_C:OnClickReverse()
  self.IsReversalSort = not self.IsReversalSort
  self:SetReverse()
  self:SortSeedList(self.workingListData)
  self.SeedList:InitList(self.workingListData)
  self.SeedList:SelectItemByIndex(0)
  if self.ComboBox_White.bShowList then
    self:OnCloseComboBox()
  end
end

function UMG_FurnitureAtlasPanel_C:SetReverse()
  if self.IsReversalSort then
    self.ComboBox_White.SortingBtn:SetRenderScale(UE4.FVector2D(-1, 1))
  else
    self.ComboBox_White.SortingBtn:SetRenderScale(UE4.FVector2D(-1, -1))
  end
end

function UMG_FurnitureAtlasPanel_C:OnComboBoxSelectChanged(selectIndex)
  if selectIndex == self.curSortId then
    return
  end
  self.curSortId = selectIndex
  self:SortSeedList(self.workingListData)
  self.SeedList:InitList(self.workingListData)
  self.SeedList:SelectItemByIndex(0)
  self.ComboBox_White:SelectItem(selectIndex, self.DropDownListData)
end

function UMG_FurnitureAtlasPanel_C:UpdateDetailPanel(itemData)
  local furnitureHandbookConf = _G.DataConfigManager:GetFurnitureHandbookConf(itemData.id)
  if not furnitureHandbookConf then
    Log.ErrorFormat("\228\184\186\228\187\128\228\185\136\230\178\161\230\156\137FurnitureHandbookConf%d\231\154\132\233\133\141\231\189\174", itemData.id)
    return
  end
  local furniture_id = furnitureHandbookConf.furniture_id
  self.furniture_id = furniture_id
  local furnitureItemConf = _G.DataConfigManager:GetFurnitureItemConf(furniture_id)
  self.SeedTitle:SetText(furnitureItemConf.name)
  if 1 ~= itemData.reward_status then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    local nums = self:GetFurnitureNums(furniture_id)
    self.SeedText:SetText(tostring(nums))
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
    self:SetRewardIcon(self.bSelectItemAward)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self:StopAnimation(self.Star_Loop)
  end
  local bNeedRotate = furnitureItemConf.type == _G.Enum.FurnitureType.FT_WALL_DECORATION
  local angles = furnitureHandbookConf.Funiture_ui_handbook_angle
  local handbookAngle = string.split(angles, ";")
  self.HomeFurniturePreview:SetPetPreview("Blueprint'" .. furnitureItemConf.model .. "'", furnitureHandbookConf.Funiture_ui_handbook_percentage / 10000, tonumber(handbookAngle[1]), tonumber(handbookAngle[2]), bNeedRotate)
  self.SyntheticNumber:SetText(furnitureItemConf.comfort)
  self.SeedDescription:SetText(_G.DataConfigManager:GetBagItemConf(furniture_id).description)
  local exchangeConf = _G.DataConfigManager:GetExchangeConf(furniture_id, true)
  if exchangeConf then
    self.SyntheticNumber_1:SetText(exchangeConf.cost_item[1].cost_goods_num)
  else
    self.SyntheticNumber_1:SetText(_G.LuaText.furniture_handbook_cannot_exchange)
  end
  if not self.furnitureIdToFriendListDic then
    self.furnitureIdToFriendListDic = {}
  end
  if not self.furnitureIdToPageAndFriendNum then
    self.furnitureIdToPageAndFriendNum = {}
  end
  if self.furnitureIdToFriendListDic[furniture_id] then
    self:SetRelatedFriendData(self.furnitureIdToFriendListDic[furniture_id])
  else
    self:SetRelatedFriendData({})
    if exchangeConf then
      self.NRCSwitcher_2:SetVisibility(UE4.ESlateVisibility.Hidden)
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendListForSpecifiedFurnitureId, furniture_id, 1, function(friendListForSpecifiedFurnitureId, totalFriendNum)
        self.NRCSwitcher_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if not friendListForSpecifiedFurnitureId then
          self.furnitureIdToFriendListDic[furniture_id] = {}
          return
        end
        if totalFriendNum > #friendListForSpecifiedFurnitureId then
          self.furnitureIdToPageAndFriendNum[furniture_id] = {}
          self.furnitureIdToPageAndFriendNum[furniture_id][2] = totalFriendNum
          self.furnitureIdToPageAndFriendNum[furniture_id][1] = 1
        end
        self:SetRelatedFriendData(friendListForSpecifiedFurnitureId)
        self.furnitureIdToFriendListDic[furniture_id] = friendListForSpecifiedFurnitureId
        self:UpdateFurnitureFriendInfo()
      end)
    else
      self.furnitureIdToFriendListDic[furniture_id] = {}
    end
  end
  self:UpdateFurnitureFriendInfo()
  if self.Text_Conditions then
    local ExchangeConf = DataConfigManager:GetExchangeConf(furniture_id, true)
    local RoomConf = ExchangeConf and DataConfigManager:GetRoomConf(ExchangeConf.furniture_build_level or 1)
    if RoomConf then
      local Display = string.format(LuaText.furniture_home_level_low, RoomConf and RoomConf.name)
      self.Text_Conditions:SetText(Display)
    else
      self.Text_Conditions:SetText("")
    end
  end
end

function UMG_FurnitureAtlasPanel_C:UpdateFurnitureFriendInfo()
  local exchangeConf = _G.DataConfigManager:GetExchangeConf(self.furniture_id, true)
  if exchangeConf then
    if 0 == self.totalFriendNum then
      self.NRCSwitcher_2:SetActiveWidgetIndex(1)
      self.FriendFurniture_1:SetText(_G.LuaText.furniture_handbook_friend_null)
    else
      table.sort(self.relatedFriendData, function(a, b)
        if a.online_state == b.online_state then
          if a.home_level == b.home_level then
            if a.uin < b.uin then
              return true
            else
              return false
            end
          elseif a.home_level > b.home_level then
            return true
          else
            return false
          end
        elseif a.online_state ~= ProtoEnum.PlayerOnlineState.ENUM.Logouted and b.online_state == ProtoEnum.PlayerOnlineState.ENUM.Logouted then
          return true
        else
          return false
        end
      end)
      self.FriendFurniture:SetText(string.format(_G.DataConfigManager:GetLocalizationConf("furniture_handbook_friend_forge").msg, self.totalFriendNum))
      self.NRCSwitcher_2:SetActiveWidgetIndex(0)
      local headNum = math.min(3, self.totalFriendNum)
      local friendsHead = {}
      for i = 1, headNum do
        local headData = {
          icon = self.relatedFriendData[i].card_icon_selected
        }
        table.insert(friendsHead, headData)
      end
      self.FriendHeadItem:InitGridView(friendsHead)
    end
  else
    self.NRCSwitcher_2:SetActiveWidgetIndex(1)
    self.FriendFurniture_1:SetText(_G.LuaText.furniture_handbook_cannot_exchange_tips)
  end
end

function UMG_FurnitureAtlasPanel_C:GetFurnitureNums(furniture_id)
  if self.furnitureData then
    for k, v in pairs(self.furnitureData) do
      if v.id == furniture_id then
        return v.num
      end
    end
  end
  return 0
end

function UMG_FurnitureAtlasPanel_C:SetRelatedFriendData(friendList, bFinish)
  local totalGet = #friendList
  local pageAndFriendNum = self.furnitureIdToPageAndFriendNum[self.furniture_id]
  self.totalFriendNum = pageAndFriendNum and pageAndFriendNum[2] or totalGet
  if pageAndFriendNum then
    local bNeedMore = totalGet < self.totalFriendNum and not bFinish
    for _, v in ipairs(friendList) do
      v.refreshIndex = bNeedMore and totalGet - 8 or nil
    end
    if not bNeedMore then
      self.furnitureIdToPageAndFriendNum[self.furniture_id] = nil
    end
  end
  self.relatedFriendData = friendList
end

function UMG_FurnitureAtlasPanel_C:SetRewardIcon(bReceived)
  if bReceived then
    self:StopAnimation(self.Star_Loop)
    self.Mask:SetRenderOpacity(1)
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Star_Loop, 0, 0)
  end
end

function UMG_FurnitureAtlasPanel_C:OnAwardBtnClicked()
  if self.bOpenAwardList then
    self:CloseRewardPreview()
    return
  end
  if self.bSelectItemAward or 1 == self.workingListData[self.selectedIndex].reward_status then
    local rewardData = _G.DataConfigManager:GetRewardConf(_G.DataConfigManager:GetFurnitureHandbookConf(self.workingListData[self.selectedIndex].id).reward_id).RewardItem
    local initRewardData = {}
    for i = 1, #rewardData do
      local data = {
        type = rewardData[i].Type,
        id = rewardData[i].Id,
        num = rewardData[i].Count,
        bMask = self.bSelectItemAward
      }
      table.insert(initRewardData, data)
    end
    self.Icon_List:InitGridView(initRewardData)
    self:PlayAnimation(self.Popup)
    self.RewardPreview:SetVisibility(UE4.ESlateVisibility.Visible)
    self.bOpenAwardList = true
    self:SetRewardPreviewBtn(true)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_FurnitureAtlasPanel_C:OnAwardBtnClicked")
  else
    if self.bWaitReward then
      return
    end
    local req = _G.ProtoMessage:newZoneHomeClaimUnlockedFurnitureRewardReq()
    req.handbook_id = self.workingListData[self.selectedIndex].id
    self.bWaitReward = true
    self.waitRewardItemData = self.workingListData[self.selectedIndex]
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_HOME_CLAIM_UNLOCKED_FURNITURE_REWARD_REQ, req, self, self.OnRewardReceived, false, true)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008040, "UMG_FurnitureAtlasPanel_C:OnAwardBtnClicked")
  end
end

function UMG_FurnitureAtlasPanel_C:OnSynthesisBtnClicked()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008005, "UMG_FurnitureAtlasPanel_C:OnSynthesisBtnClicked")
  _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenFriendFurniture, self.relatedFriendData, self.totalFriendNum)
end

function UMG_FurnitureAtlasPanel_C:OnRewardReceived(_rsp)
  self.bWaitReward = false
  if _rsp.ret_info and 0 == _rsp.ret_info.ret_code then
    local itemData = self.waitRewardItemData
    if itemData then
      itemData.reward_status = 3
      if self.handbook_id == itemData.id then
        self:SetRewardIcon(true)
        self:PlayAnimation(self.Get)
        self.bSelectItemAward = true
      end
      local conf = _G.DataConfigManager:GetFurnitureHandbookConf(itemData.id)
      if conf and conf.reward_id then
        local rewardData = (_G.DataConfigManager:GetRewardConf(conf.reward_id) or {}).RewardItem
        local popupInitData = {}
        for i = 1, #rewardData do
          local popupData = _G.ProtoMessage:newGoodsItem()
          popupData.id = rewardData[i].Id
          popupData.num = rewardData[i].Count
          popupData.type = rewardData[i].Type
          table.insert(popupInitData, popupData)
        end
        _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
      end
    end
    local coinNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_FURNITURE_COIN)
    local moneyBtnData = {
      {
        moneyType = _G.Enum.VisualItem.VI_FURNITURE_COIN,
        sum = coinNum,
        IsShowBuyIcon = false
      }
    }
    self.MoneyBtn:InitGridView(moneyBtnData)
  end
end

function UMG_FurnitureAtlasPanel_C:OnReconnectFinish()
  self.bWaitReward = false
end

function UMG_FurnitureAtlasPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Popup_Out then
    self.RewardPreview:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_FurnitureAtlasPanel_C:OnCloseComboBox()
  self.ComboBox_White:OnComboBtnClicked()
end

function UMG_FurnitureAtlasPanel_C:SetGlobalBtn(bShow)
  self.CloseBtn_Global:SetVisibility(bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if bShow and self.bOpenAwardList then
    self:CloseRewardPreview()
  end
end

function UMG_FurnitureAtlasPanel_C:SetRewardPreviewBtn(bShow)
  local visibilityState = bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
  self.CloseBtn_L:SetVisibility(visibilityState)
  self.CloseBtn_U:SetVisibility(visibilityState)
  self.CloseBtn_D:SetVisibility(visibilityState)
  self.CloseBtn_R:SetVisibility(visibilityState)
end

function UMG_FurnitureAtlasPanel_C:CloseRewardPreview()
  self:PlayAnimation(self.Popup_Out)
  self:SetRewardPreviewBtn(false)
  self.bOpenAwardList = false
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_FurnitureAtlasPanel_C:CloseRewardPreview")
end

function UMG_FurnitureAtlasPanel_C:GetMoreFriendData()
  if self.waitNewFriendData then
    return
  end
  self.waitNewFriendData = true
  local nextPage = self.furnitureIdToPageAndFriendNum[self.furniture_id][1] + 1
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendListForSpecifiedFurnitureId, self.furniture_id, nextPage, function(friendListForSpecifiedFurnitureId, totalFriendNum)
    if not friendListForSpecifiedFurnitureId then
      friendListForSpecifiedFurnitureId = {}
      self.bNeedNewFriendData = true
    end
    table.sort(friendListForSpecifiedFurnitureId, function(a, b)
      if a.online_state == b.online_state then
        if a.home_level == b.home_level then
          if a.uin < b.uin then
            return true
          else
            return false
          end
        elseif a.home_level > b.home_level then
          return true
        else
          return false
        end
      elseif a.online_state ~= ProtoEnum.PlayerOnlineState.ENUM.Logouted and b.online_state == ProtoEnum.PlayerOnlineState.ENUM.Logouted then
        return true
      else
        return false
      end
    end)
    local friendList = self.furnitureIdToFriendListDic[self.furniture_id]
    local uinList = {}
    for _, v in ipairs(friendList) do
      uinList[v.uin] = true
    end
    for _, v in ipairs(friendListForSpecifiedFurnitureId) do
      if uinList[v.uin] then
        self.bNeedNewFriendData = true
      else
        table.insert(friendList, v)
      end
    end
    self.furnitureIdToPageAndFriendNum[self.furniture_id][1] = nextPage
    local numPerPage = _G.DataConfigManager:GetHomeGlobalConfig("furniture_handbook_friendinformation_num").num
    local bFinish = totalFriendNum <= nextPage * numPerPage
    if totalFriendNum ~= self.totalFriendNum then
      self.bNeedNewFriendData = true
    end
    if bFinish then
      self.FriendFurniture:SetText(string.format(_G.DataConfigManager:GetLocalizationConf("furniture_handbook_friend_forge").msg, #friendList))
    end
    self:SetRelatedFriendData(friendList, bFinish)
    local friendPanel = self.module:GetPanel("FriendFurniturePopup")
    if friendPanel then
      friendPanel:RefreshFriendPanel(self.relatedFriendData)
    end
    self.waitNewFriendData = false
  end)
end

function UMG_FurnitureAtlasPanel_C:OpenFilterPanel()
  if _G.HomeModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenFurnitureFilterPanel, self.tabFilterTable, HomeEnum.FurnitureFilterMode.Atlas, nil, self.DisplayNumInTab)
  end
end

function UMG_FurnitureAtlasPanel_C:OnFilterUpdate()
  local bDoFilter = self:IsApplyFilter()
  if bDoFilter then
    self.ComboBox_White.ScreeningBtn:ChangeIconSelectState(2)
  else
    self.ComboBox_White.ScreeningBtn:ChangeIconSelectState(1)
  end
  self:FilterSeedList(self.workingListData)
  self:SetReverse()
  self:SortSeedList(self.workingListData)
  self.SeedList:InitList(self.workingListData)
  self.SeedList:SelectItemByIndex(0)
  if self.ComboBox_White.bShowList then
    self:OnCloseComboBox()
  end
end

function UMG_FurnitureAtlasPanel_C:FilterSeedList(listInfo)
  if self:IsApplyFilter() then
    self.workingListData = {}
    local HomeModuleData = HomeIndoorSandbox.Module:GetData()
    if not HomeModuleData then
      return
    end
    for idx, itemData in ipairs(self.seedListDatas) do
      if itemData then
        local furnitureHandBookConf = _G.DataConfigManager:GetFurnitureHandbookConf(itemData.id)
        if furnitureHandBookConf and furnitureHandBookConf.furniture_id then
          local furnitureItemConf = _G.DataConfigManager:GetFurnitureItemConf(furnitureHandBookConf.furniture_id)
          if furnitureItemConf and furnitureItemConf.classification then
            local tabId = furnitureItemConf.classification
            local bFilterToShow = self.tabFilterTable[tabId]
            if not bFilterToShow then
              local firstTabId = HomeModuleData:GetFirstTabId(tabId)
              if firstTabId then
                bFilterToShow = self.tabFilterTable[firstTabId]
              end
            end
            if bFilterToShow then
              table.insert(self.workingListData, itemData)
            end
          end
        end
      end
    end
  else
    self.workingListData = self.seedListDatas
  end
end

function UMG_FurnitureAtlasPanel_C:IsApplyFilter()
  return self.tabFilterTable and not not next(self.tabFilterTable)
end

return UMG_FurnitureAtlasPanel_C
