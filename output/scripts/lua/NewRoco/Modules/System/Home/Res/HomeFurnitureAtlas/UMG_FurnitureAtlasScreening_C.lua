local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local HomeEnum = require("NewRoco.Modules.System.Home.HomeEnum")
local UMG_FurnitureAtlasScreening_C = _G.NRCPanelBase:Extend("UMG_FurnitureAtlasScreening_C")

function UMG_FurnitureAtlasScreening_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self:OnAddEventListener()
  self.filterDescriptionWorkSpace = {}
end

function UMG_FurnitureAtlasScreening_C:GetBagModuleData()
  return self.module:GetData()
end

function UMG_FurnitureAtlasScreening_C:OnActive(InFilterTable, filterMode, specificSingleFirstTab, extraData)
  self:LoadAnimation(0)
  if filterMode == HomeEnum.FurnitureFilterMode.Bag or filterMode == HomeEnum.FurnitureFilterMode.BagDecompose then
    if nil ~= InFilterTable then
      Log.Error("UMG_FurnitureAtlasScreening_C:OnActive \232\131\140\229\140\133\232\135\170\229\183\177\230\156\137\229\141\149\228\184\128\229\173\152\229\130\168\239\188\140\228\184\141\232\166\129\228\188\160\229\133\165Table\239\188\140\228\184\141\228\188\154\228\189\191\231\148\168\231\154\132")
    end
    local BagModuleData = NRCModuleManager:GetModule("BagModule"):GetData()
    InFilterTable = BagModuleData and BagModuleData:GetFurnitureFilterTabMap() or {}
  elseif (filterMode == HomeEnum.FurnitureFilterMode.Craft or filterMode == HomeEnum.FurnitureFilterMode.Atlas) and nil == InFilterTable then
    Log.Error("UMG_FurnitureAtlasScreening_C:OnActive \233\153\164\228\186\134\232\131\140\229\140\133\232\135\170\229\183\177\230\156\137\229\141\149\228\184\128\229\173\152\229\130\168\228\189\141\231\189\174\239\188\140\229\133\182\228\187\150\231\154\132\232\176\131\231\148\168\230\150\185\229\191\133\233\161\187\228\188\160\229\133\165Table\228\187\165\228\190\155\230\149\176\230\141\174\232\191\148\229\155\158")
    InFilterTable = {}
  end
  self.filterMode = filterMode
  self.targetFilterTablePendingWrite = InFilterTable
  table.reset(self.filterDescriptionWorkSpace)
  if InFilterTable then
    for k, v in pairs(InFilterTable) do
      if v then
        self.filterDescriptionWorkSpace[k] = v
      end
    end
  end
  local Data = NRCModuleManager:GetModule("HomeModule"):GetData()
  local firstTabList = {}
  if Data and Data.GetFirstTabList then
    firstTabList = Data:GetFirstTabList()
  end
  local firstTabDataArray = {}
  local titleText = LuaText.furniture_filter_rule
  if filterMode == HomeEnum.FurnitureFilterMode.Bag then
    for i, tabConf in ipairs(firstTabList) do
      if tabConf and tabConf.is_bagpack_filter then
        table.insert(firstTabDataArray, {
          firstTabId = tabConf.id,
          firstTabItemIndex = #firstTabDataArray + 1,
          secondTabPickNum = 0,
          secondTabTotalCount = #(tabConf.sec_tab_array or {}),
          OnClick = FPartial(self.OnClickItem, self),
          extraData = extraData
        })
      end
    end
  elseif filterMode == HomeEnum.FurnitureFilterMode.BagDecompose then
    for i, tabConf in ipairs(firstTabList) do
      if tabConf and tabConf.is_bagpack_filter and tabConf.tab_icon_build_1 then
        table.insert(firstTabDataArray, {
          firstTabId = tabConf.id,
          firstTabItemIndex = #firstTabDataArray + 1,
          secondTabPickNum = 0,
          secondTabTotalCount = #(tabConf.sec_tab_array or {}),
          OnClick = FPartial(self.OnClickItem, self),
          extraData = extraData
        })
      end
    end
  elseif filterMode == HomeEnum.FurnitureFilterMode.Craft then
    local conf = _G.DataConfigManager:GetFurnitureClassificationConf(specificSingleFirstTab)
    if LuaText.furniture_filter_title and conf and conf.tab_name then
      titleText = string.format(LuaText.furniture_filter_title, conf.tab_name)
    end
    table.insert(firstTabDataArray, {
      bSingleFirstTab = true,
      firstTabId = specificSingleFirstTab,
      firstTabItemIndex = #firstTabDataArray + 1,
      secondTabPickNum = 0,
      secondTabTotalCount = #(conf and conf.sec_tab_array or {}),
      OnClick = FPartial(self.OnClickItem, self),
      extraData = extraData
    })
  elseif filterMode == HomeEnum.FurnitureFilterMode.Atlas then
    for i, tabConf in ipairs(firstTabList) do
      if tabConf and tabConf.is_handbook_filter then
        table.insert(firstTabDataArray, {
          firstTabId = tabConf.id,
          firstTabItemIndex = #firstTabDataArray + 1,
          secondTabPickNum = 0,
          secondTabTotalCount = #(tabConf.sec_tab_array or {}),
          OnClick = FPartial(self.OnClickItem, self),
          extraData = extraData
        })
      end
    end
  end
  self.firstTabDataArray = firstTabDataArray
  self.NRCGridView_59:InitGridView(firstTabDataArray)
  self.NRCGridView_59:RefreshGridViewLayout()
  local filterStore = self.filterDescriptionWorkSpace
  local firstTabTotalCount = self.NRCGridView_59:GetItemCount()
  for i = 1, firstTabTotalCount do
    local firstTabItem = self.NRCGridView_59:GetItemByIndex(i - 1)
    local firstTabData = self.firstTabDataArray[i]
    if firstTabItem and firstTabData then
      local secondTabPickNum = firstTabItem:DoSelectMultiSecondTab(filterStore) or 0
      firstTabData.secondTabPickNum = secondTabPickNum
    end
  end
  self:SetCommonPopUpInfo(titleText)
end

function UMG_FurnitureAtlasScreening_C:OnDeactive()
end

function UMG_FurnitureAtlasScreening_C:SetCommonPopUpInfo(titleText)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnReqClose
  CommonPopUpData.TitleText = titleText
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_FurnitureAtlasScreening_C:OnClickItem(firstTabItemIndex, secondTabItemIndex, Data, bSelect, userClick)
  if not (self.filterDescriptionWorkSpace and Data and Data.tabId) or not Data.firstTabId then
    return
  end
  local firstTabItem, firstTabData
  if firstTabItemIndex then
    firstTabItem = self.NRCGridView_59:GetItemByIndex(firstTabItemIndex - 1)
    firstTabData = self.firstTabDataArray and self.firstTabDataArray[firstTabItemIndex]
  end
  if not firstTabItem or not firstTabData then
    return
  end
  if not bSelect then
    return
  end
  local filterStore = self.filterDescriptionWorkSpace
  if -1 == Data.tabId then
    filterStore[Data.firstTabId] = not filterStore[Data.firstTabId]
    local conf = _G.DataConfigManager:GetFurnitureClassificationConf(Data.firstTabId)
    if filterStore[Data.firstTabId] then
      if conf and conf.sec_tab_array then
        for idx, secondTabId in ipairs(conf.sec_tab_array) do
          filterStore[secondTabId] = true
        end
        firstTabData.secondTabPickNum = #conf.sec_tab_array
      end
      firstTabItem:DoSelectAllSecondTab()
    else
      if conf and conf.sec_tab_array then
        for idx, secondTabId in ipairs(conf.sec_tab_array) do
          filterStore[secondTabId] = false
        end
      end
      firstTabData.secondTabPickNum = 0
      firstTabItem:DoUnSelectAllSecondTab()
    end
  else
    filterStore[Data.tabId] = not filterStore[Data.tabId]
    if filterStore[Data.tabId] then
      firstTabItem:DoSelectSecondTab(secondTabItemIndex)
      firstTabData.secondTabPickNum = firstTabData.secondTabPickNum + 1
      if firstTabData.secondTabPickNum == firstTabData.secondTabTotalCount then
        filterStore[Data.firstTabId] = true
        firstTabItem:DoSelectTheAllTab()
      end
    else
      firstTabItem:DoUnSelectSecondTab(secondTabItemIndex)
      firstTabData.secondTabPickNum = firstTabData.secondTabPickNum - 1
      if firstTabData.secondTabPickNum ~= firstTabData.secondTabTotalCount then
        filterStore[Data.firstTabId] = false
        firstTabItem:DoUnSelectTheAllTab()
      end
    end
  end
end

function UMG_FurnitureAtlasScreening_C:OnReqReset()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_FurnitureAtlasScreeningItem_C:OnItemSelected")
  self.filterDescriptionWorkSpace = {}
  local firstTabTotalCount = self.NRCGridView_59:GetItemCount()
  for i = 1, firstTabTotalCount do
    local firstTabItem = self.NRCGridView_59:GetItemByIndex(i - 1)
    if firstTabItem then
      firstTabItem:DoUnSelectAllSecondTab()
    end
  end
end

function UMG_FurnitureAtlasScreening_C:OnReqConfirm()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_FurnitureAtlasScreeningItem_C:OnItemSelected")
  if self.filterMode == HomeEnum.FurnitureFilterMode.Bag or self.filterMode == HomeEnum.FurnitureFilterMode.BagDecompose then
    local bagModule = NRCModuleManager:GetModule("BagModule")
    local Data = bagModule and bagModule:GetData()
    if Data and NRCModuleManager:GetModule("HomeModule"):GetData() then
      Data:SetFurnitureFilterTabMap(self.filterDescriptionWorkSpace)
      bagModule:DispatchEvent(BagModuleEvent.UpdateFilter)
    end
  elseif (self.filterMode == HomeEnum.FurnitureFilterMode.Craft or self.filterMode == HomeEnum.FurnitureFilterMode.Atlas) and self.targetFilterTablePendingWrite then
    table.reset(self.targetFilterTablePendingWrite)
    if self.filterDescriptionWorkSpace then
      for k, v in pairs(self.filterDescriptionWorkSpace) do
        if v then
          self.targetFilterTablePendingWrite[k] = v
        end
      end
    end
    self:DispatchEvent(HomeModuleEvent.UpdateFurnitureFilter)
  end
  self:OnReqClose()
end

function UMG_FurnitureAtlasScreening_C:OnReqClose()
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_FurnitureAtlasScreening_C:OnReqClose")
  self:LoadAnimation(2)
end

function UMG_FurnitureAtlasScreening_C:OnAnimationFinished(aim)
  if aim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_FurnitureAtlasScreening_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnReqReset)
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnReqConfirm)
end

return UMG_FurnitureAtlasScreening_C
