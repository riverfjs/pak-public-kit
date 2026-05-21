local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AllSecondTabIconPath = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_TabIcon0_png.img_TabIcon0_png'"
local UMG_FurnitureAtlasScreeningItem2_C = Base:Extend("UMG_FurnitureAtlasScreeningItem2_C")

function UMG_FurnitureAtlasScreeningItem2_C:OnConstruct()
end

function UMG_FurnitureAtlasScreeningItem2_C:OnDestruct()
end

function UMG_FurnitureAtlasScreeningItem2_C:OnItemUpdate(_data, datalist, index)
  if not _data or not _data.firstTabId then
    return
  end
  self.uiData = _data
  local furnitureClassificationConf = _G.DataConfigManager:GetFurnitureClassificationConf(_data.firstTabId)
  local secondTabDataArray = {}
  if furnitureClassificationConf then
    self.NRCText_42:SetText(furnitureClassificationConf.tab_name)
    local extraData = _data.extraData
    local secondTabNum = #furnitureClassificationConf.sec_tab_array
    if not _data.bSingleFirstTab and (0 == secondTabNum or secondTabNum > 1) then
      table.insert(secondTabDataArray, {
        firstTabId = _data.firstTabId,
        firstTabItemIndex = _data.firstTabItemIndex,
        tabId = -1,
        text = LuaText.furniture_filter_all,
        iconPath = AllSecondTabIconPath,
        displayNum = extraData and extraData[_data.firstTabId],
        OnClick = _data.OnClick
      })
    end
    for idx, secondTabId in ipairs(furnitureClassificationConf.sec_tab_array) do
      local conf = _G.DataConfigManager:GetFurnitureClassificationConf(secondTabId)
      if conf and conf.tab_name and conf.tab_icon then
        table.insert(secondTabDataArray, {
          firstTabId = _data.firstTabId,
          firstTabItemIndex = _data.firstTabItemIndex,
          tabId = secondTabId,
          text = conf.tab_name,
          iconPath = conf.tab_icon,
          displayNum = extraData and extraData[secondTabId],
          OnClick = _data.OnClick
        })
      end
    end
  end
  if _data.bSingleFirstTab then
    self.NRCText_42:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Line1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCText_42:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Line1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.secondTabDataArray = secondTabDataArray
  self.FurnitureList:InitGridView(secondTabDataArray)
end

function UMG_FurnitureAtlasScreeningItem2_C:OnItemSelected(_bSelected)
end

function UMG_FurnitureAtlasScreeningItem2_C:OnDeactive()
end

function UMG_FurnitureAtlasScreeningItem2_C:DoSelectSecondTab(secondTabIndex)
  local secondTabItem = self.FurnitureList:GetItemByIndex(secondTabIndex - 1)
  if secondTabItem then
    secondTabItem:DoSelect()
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoUnSelectSecondTab(secondTabIndex)
  local secondTabItem = self.FurnitureList:GetItemByIndex(secondTabIndex - 1)
  if secondTabItem then
    secondTabItem:DoUnSelect()
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoSelectAllSecondTab()
  local ItemNum = self.FurnitureList:GetItemCount()
  for i = 1, ItemNum do
    local secondTabItem = self.FurnitureList:GetItemByIndex(i - 1)
    if secondTabItem then
      secondTabItem:DoSelect()
    end
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoUnSelectAllSecondTab()
  local ItemNum = self.FurnitureList:GetItemCount()
  for i = 1, ItemNum do
    local secondTabItem = self.FurnitureList:GetItemByIndex(i - 1)
    if secondTabItem then
      secondTabItem:DoUnSelect()
    end
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoSelectTheAllTab()
  local secondTabData = self.secondTabDataArray and self.secondTabDataArray[1]
  if secondTabData and -1 == secondTabData.tabId then
    self:DoSelectSecondTab(1)
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoUnSelectTheAllTab()
  local secondTabData = self.secondTabDataArray and self.secondTabDataArray[1]
  if secondTabData and -1 == secondTabData.tabId then
    self:DoUnSelectSecondTab(1)
  end
end

function UMG_FurnitureAtlasScreeningItem2_C:DoSelectMultiSecondTab(filterStore)
  if not filterStore or not self.uiData then
    return nil
  end
  local ItemNum = self.FurnitureList:GetItemCount()
  local pickNum = 0
  for i = 1, ItemNum do
    local secondTabItem = self.FurnitureList:GetItemByIndex(i - 1)
    local secondTabData = self.secondTabDataArray and self.secondTabDataArray[i]
    if secondTabItem and secondTabData then
      if -1 == secondTabData.tabId then
        if filterStore[self.uiData.firstTabId] then
          self:DoSelectSecondTab(1)
        end
      elseif filterStore[secondTabData.tabId] then
        self:DoSelectSecondTab(i)
        pickNum = pickNum + 1
      end
    end
  end
  return pickNum
end

return UMG_FurnitureAtlasScreeningItem2_C
