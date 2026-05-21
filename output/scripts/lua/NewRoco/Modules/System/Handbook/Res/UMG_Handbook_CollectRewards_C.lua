local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local UMG_Handbook_CollectRewards_C = _G.NRCPanelBase:Extend("UMG_Handbook_CollectRewards_C")

function UMG_Handbook_CollectRewards_C:OnActive(selectItemNum)
  self:OnAddEventListener()
  self:AddPcInputBlock()
  self.module = _G.NRCModuleManager:GetModule("HandbookModule")
  self.data = self.module:GetData("HandbookModuleData")
  self.HandbookInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().handbook
  self.handbookRewardConf = self:GetCurAreaHandbookRewardConfs()
  self.rewardPageDataDic = {}
  self.pageList = {}
  self.pageNum = 5
  self.jumpIndex = 0
  self.selectItemNum = selectItemNum
  self.RewardsItemList = {
    self.CollectRewards_Item,
    self.CollectRewards_Item_1,
    self.CollectRewards_Item_2,
    self.CollectRewards_Item_3,
    self.CollectRewards_Item_4
  }
  self.Prompt_2:SetText(_G.DataConfigManager:GetLocalizationConf("handbook_collect_num").msg)
  self:LoadAnimation(0)
  self:CreatPages()
  self:ShowPanel()
  local areaId = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookId)
  local areaHandbookConf = _G.DataConfigManager:GetAreaHandbook(areaId)
  if areaHandbookConf and areaHandbookConf.collect_reward_res then
    self.NRCImage_39:SetPath(areaHandbookConf.collect_reward_res)
  end
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetDisableRewardAnimationState, false)
  self:BindInputAction()
  self.bgProxy = _G.NRCModuleManager:DoCmd(TUIModuleCmd.PushBlackBackgroundWidgets, {
    self.Bg_1
  })
  self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, true)
end

function UMG_Handbook_CollectRewards_C:OnLogin()
  self.HandbookInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().handbook
  self:CreatPages()
  self:ShowPanel()
end

function UMG_Handbook_CollectRewards_C:GetCurAreaHandbookRewardConfs()
  return self.module:GetCurAreaHandbookRewardConfs()
end

function UMG_Handbook_CollectRewards_C:ShowPanel()
  if self.data.CollectedCount then
    local curCount = self.data.CollectedCount
    self.Quantity_1:SetText(curCount)
  end
  self.rewardPageDataDic = {}
  self:CreatPagesInfo()
  self:ShowPageBtn()
  if 0 ~= self.jumpIndex then
    self.curPageIndex = self.jumpIndex
  end
  self:DispatchEvent(HandbookModuleEvent.OnCollectRewardsToPage, self.curPageIndex)
end

function UMG_Handbook_CollectRewards_C:ShowPageList()
  local dataList = self.rewardPageDataDic[self.curPageIndex]
  local showTipsIdx
  if self.selectItemNum then
    showTipsIdx = self.pageNum - (self.curPageIndex * self.pageNum - self.selectItemNum)
    self.selectItemNum = nil
  end
  for i = 1, self.pageNum do
    if dataList and i <= #dataList then
      self.RewardsItemList[i]:SetVisibility(UE4.ESlateVisibility.Visible)
      self.RewardsItemList[i]:OnActive(dataList[i], dataList[i].Idx)
      if showTipsIdx and showTipsIdx == i then
        self.RewardsItemList[i]:ClickTips()
      end
    else
      self.RewardsItemList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Handbook_CollectRewards_C:CreatPagesInfo()
  local rewardToggle = {}
  if self.data:GetHandBookRewardStates() ~= nil then
    rewardToggle = self.data:GetHandBookRewardStates()
  end
  local curCount = 0
  if nil ~= self.data.CollectedCount then
    curCount = self.data.CollectedCount
    self.Quantity_1:SetText(curCount)
  end
  local count = math.ceil(#self.handbookRewardConf / self.pageNum)
  self.rewardPageDataDic = {}
  local showPackageCount = 0
  for i = 1, count do
    local start_index = (i - 1) * self.pageNum + 1
    local end_index = start_index + self.pageNum - 1
    for j = start_index, math.min(end_index, #self.handbookRewardConf) do
      if nil == self.rewardPageDataDic[i] then
        self.rewardPageDataDic[i] = {}
      end
      local IsCanReceive = curCount >= self.handbookRewardConf[j].handbook_number
      if IsCanReceive and false == rewardToggle[j] and 0 == showPackageCount then
        showPackageCount = i
      end
      local rewardData = {}
      rewardData.State = rewardToggle[j]
      rewardData.IsCanReceive = IsCanReceive
      rewardData.Data = self.handbookRewardConf[j]
      rewardData.Idx = j
      table.insert(self.rewardPageDataDic[i], rewardData)
    end
  end
  if self.selectItemNum then
    self.jumpIndex = math.ceil(self.selectItemNum / self.pageNum)
  elseif 0 ~= showPackageCount then
    self.jumpIndex = showPackageCount
  end
end

function UMG_Handbook_CollectRewards_C:CreatPages()
  local curNum = 0
  local count = 0
  if self.data.CollectedCount ~= nil then
    curNum = self.data.CollectedCount
  end
  for i = 1, #self.handbookRewardConf do
    if curNum < self.handbookRewardConf[i].handbook_number then
      break
    end
    count = i
  end
  local page = math.clamp(math.ceil(count / self.pageNum), 1, 10)
  for i = 1, page do
    self:CreatPageItem(i)
  end
  self.curPageIndex = page
end

function UMG_Handbook_CollectRewards_C:CreatPageItem(index)
  local infoWidget = UE4.UWidgetBlueprintLibrary.Create(self, self.pageItem)
  if infoWidget then
    local widgetSlot = self.HorizontalBox_0:AddChild(infoWidget)
    local Padding = UE4.FMargin()
    Padding.Right = 10
    Padding.Left = 10
    widgetSlot:SetPadding(Padding)
    infoWidget:Init(index)
    table.insert(self.pageList, index, infoWidget)
  end
  return infoWidget
end

function UMG_Handbook_CollectRewards_C:UpdateRewardList(_handbook)
  self:CreatPagesInfo()
  self:ShowPageList()
end

function UMG_Handbook_CollectRewards_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetCurChangeAwardStateIndex, 0)
  self:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(TUIModuleCmd.PopBlackBackgroundWidgets, self.bgProxy)
end

function UMG_Handbook_CollectRewards_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_Handbook_CollectRewards_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_Handbook_CollectRewards_C:OnAddEventListener()
  self:RegisterEvent(self, HandbookModuleEvent.OnCollectRewardsToPage, self.ChangeToPage)
  self:RegisterEvent(self, HandbookModuleEvent.OnUpdateRewardPanel, self.UpdateRewardList)
  self:RegisterEvent(self, HandbookModuleEvent.OnCollectRewardsClickIndex, self.OnClickItemIndex)
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE, self.OnShopTipsClose)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.Btnclose, self.OnClickCloseBtn)
  self:AddButtonListener(self.NRCButton_76, self.BackToPage)
  self:AddButtonListener(self.NRCButton, self.NextToPage)
  self:AddButtonListener(self.Button_70, self.CloseTips)
end

function UMG_Handbook_CollectRewards_C:CloseTips()
  for i = 1, #self.RewardsItemList do
    self.RewardsItemList[i]:CloseTips()
  end
end

function UMG_Handbook_CollectRewards_C:NextToPage()
  self.curPageIndex = math.clamp(self.curPageIndex + 1, 1, #self.pageList)
  self:ShowPageBtn()
  self:DispatchEvent(HandbookModuleEvent.OnCollectRewardsToPage, self.curPageIndex)
end

function UMG_Handbook_CollectRewards_C:BackToPage()
  self.curPageIndex = math.clamp(self.curPageIndex - 1, 1, #self.pageList)
  self:ShowPageBtn()
  self:DispatchEvent(HandbookModuleEvent.OnCollectRewardsToPage, self.curPageIndex)
end

function UMG_Handbook_CollectRewards_C:ChangeToPage(index)
  self.curPageIndex = index
  self:ShowPageBtn()
  for i = 1, #self.pageList do
    self.pageList[i]:ChangeToPage(index)
  end
  self:ShowPageList()
end

function UMG_Handbook_CollectRewards_C:OnClickItemIndex(index)
  for i = 1, #self.RewardsItemList do
    if self.RewardsItemList[i].uiData and self.RewardsItemList[i].uiData.Idx ~= index then
      self.RewardsItemList[i]:CloseTips()
    end
  end
end

function UMG_Handbook_CollectRewards_C:ShowPageBtn()
  if self.curPageIndex <= 1 then
    self.NRCButton_76:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCButton_76:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.curPageIndex >= #self.pageList then
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Handbook_CollectRewards_C:OnDestruct()
  self:UnRegisterEvent(self, HandbookModuleEvent.OnUpdateRewardPanel)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnCollectRewardsToPage)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnCollectRewardsClickIndex)
  self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, false)
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE, self.OnShopTipsClose)
end

function UMG_Handbook_CollectRewards_C:OnShopTipsClose()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetDisableRewardAnimationState, false)
end

function UMG_Handbook_CollectRewards_C:OnClickCloseBtn()
  self.CloseBtn.btnClose:SetIsEnabled(false)
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Plane_ExchangeVisits_C:OnActive")
  self:LoadAnimation(2)
end

function UMG_Handbook_CollectRewards_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DispatchEvent(HandbookModuleEvent.OnUpdateHandbookCover)
    self:DoClose()
  end
  if Animation == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Handbook_CollectRewards_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_HandbookCollectRewards")
  if mappingContext then
    mappingContext:BindAction("IA_CloseHandbookCollectRewards", self, "OnPcClose2")
  end
end

function UMG_Handbook_CollectRewards_C:OnPcClose2()
  self:OnClickCloseBtn()
end

return UMG_Handbook_CollectRewards_C
