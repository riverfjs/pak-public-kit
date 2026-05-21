local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local HandbookModuleEnum = reload("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_HandBook_RegionalSelection_C = _G.NRCPanelBase:Extend("UMG_HandBook_RegionalSelection_C")

function UMG_HandBook_RegionalSelection_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_HandBook_RegionalSelection_C:OnActive(type)
  self.IsHide = true
  self.NRCText_166:SetText(LuaText.area_hb_entrance)
  self.module:UpdateSelectPageRedPoint()
  self:OnUpdateRegionalLocalRedPoint()
  self:InitPanel(type)
end

function UMG_HandBook_RegionalSelection_C:InitPanel(type)
  self.curPanelType = type
  local tableDatas = self:GetTableDatas()
  self.TabList1:InitGridView(tableDatas)
  if type == HandbookModuleEnum.SeasonHandbookTable.Photo then
    self.TabList1:SelectItemByIndex(1)
  else
    self.TabList1:SelectItemByIndex(0)
  end
end

function UMG_HandBook_RegionalSelection_C:OnDeactive()
end

function UMG_HandBook_RegionalSelection_C:OnAddEventListener()
  self:AddButtonListener(self.close_btn, self.OnClosePanel)
  self:AddButtonListener(self.BookButton, self.ClickChangeAreaBtn)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangeAreaSelectItem, self.OnChangeAreaData)
  self:RegisterEvent(self, HandbookModuleEvent.OnClickHandbookSeasonTable, self.OnClickHandbookSeasonTable)
  self:RegisterEvent(self, HandbookModuleEvent.OnUpdateRegionalLocalRedPoint, self.OnUpdateRegionalLocalRedPoint)
  self:RegisterEvent(self, HandbookModuleEvent.OnIsShowRegionalBtnMask, self.OnIsShowMask)
end

function UMG_HandBook_RegionalSelection_C:ClickChangeAreaBtn()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  if self.module:HasPanel("HandbookTrophy") then
    return
  end
  if self.IsHide then
    self:PlayAnimation(self.In)
    self.close_btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local panelType = HandbookModuleEnum.SeasonHandbookTable.Handbook
    if self.module:HasPanel("SeasonHandBookPhoto") then
      panelType = HandbookModuleEnum.SeasonHandbookTable.Photo
    end
    _G.NRCAudioManager:PlaySound2DAuto(1085, "UMG_Handbook1_C:ClickChangeAreaBtn")
    self.IsHide = false
    self:InitPanel(panelType)
  else
    self:OnClosePanel()
  end
end

function UMG_HandBook_RegionalSelection_C:UpdatePanel(type)
  self.curPanelType = type
  local datas = self:GetItemDatas(type)
  self.NRCScrollView_66:InitList(datas)
  self.NRCScrollView_66:SetItemCanClickChecker(self.CheckTabCanClick, self)
end

function UMG_HandBook_RegionalSelection_C:GetTableDatas()
  local data1 = {
    name = LuaText.area_handbook_entry,
    type = HandbookModuleEnum.SeasonHandbookTable.Handbook
  }
  local data2 = {
    name = LuaText.season_handbook_entry,
    type = HandbookModuleEnum.SeasonHandbookTable.Photo
  }
  return {data1, data2}
end

function UMG_HandBook_RegionalSelection_C:GetItemDatas(type)
  local datas = {}
  if type == HandbookModuleEnum.SeasonHandbookTable.Photo then
    local curTime = ActivityUtils.GetSvrTimestamp()
    local seasonConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_CONF):GetAllDatas()
    for _, conf in pairs(seasonConf or {}) do
      local startTime = ActivityUtils.ToTimestamp(conf.start_time)
      local seasonBookConf = _G.DataConfigManager:GetSeasonHandbookConf(conf.id)
      if curTime >= startTime then
        table.insert(datas, {type = type, conf = seasonBookConf})
      end
      table.sort(datas, function(a, b)
        return a.conf.id < b.conf.id
      end)
    end
  else
    local confs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.AREA_HANDBOOK)
    if confs then
      local areaConfs = confs:GetAllDatas()
      for key, value in pairs(areaConfs) do
        local data = {}
        data.conf = value
        data.type = type
        table.insert(datas, data)
      end
      table.sort(datas, function(a, b)
        return a.conf.sort_id < b.conf.sort_id
      end)
    end
  end
  return datas
end

function UMG_HandBook_RegionalSelection_C:OnChangeAreaData(areaItem)
  self:OnChangeAreaSelect(areaItem)
  self:OnClosePanel()
end

function UMG_HandBook_RegionalSelection_C:OnChangeAreaSelect(areaItem)
  for i = 1, self.NRCScrollView_66:GetItemCount() do
    local item = self.NRCScrollView_66:GetItemByIndex(i - 1)
    if item then
      item:UnSelectItem(areaItem)
    end
  end
end

function UMG_HandBook_RegionalSelection_C:OnClickHandbookSeasonTable(type)
  self:UpdatePanel(type)
  self:OnUpdateRegionalLocalRedPoint()
end

function UMG_HandBook_RegionalSelection_C:OnUpdateRegionalLocalRedPoint()
  if self.module and self.module.data and self.module.data.curSelectedSeasonHandbookData then
    local type = self.module.data.curSelectedSeasonHandbookData.type
    self.RedDot:SetupKey(125, {type})
  end
end

function UMG_HandBook_RegionalSelection_C:OnClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Handbook1_C:ClickChangeAreaBtn")
  self.IsHide = true
  self:PlayAnimation(self.Out)
  self.close_btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.curPanelType == HandbookModuleEnum.SeasonHandbookTable.Handbook then
  end
end

function UMG_HandBook_RegionalSelection_C:OnDestruct()
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangeAreaSelectItem)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnClickHandbookSeasonTable)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnUpdateRegionalLocalRedPoint)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnIsShowRegionalBtnMask)
end

function UMG_HandBook_RegionalSelection_C:OnIsShowMask(isShow)
  self.Mask:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.BookButton:SetVisibility(isShow and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Visible)
  if isShow and self.RedDot:IsRed() then
    self.RedPointMask:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.RedPointMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HandBook_RegionalSelection_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:ClearAllEnhancedInput()
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HandBook_RegionalSelection_C:BindInputAction()
  local priority = self.panel and self.panel.depth
  local mappingContext = self:AddInputMappingContext("IMC_HandBookRegionalSelection", priority)
  if mappingContext then
    mappingContext:BindAction("IA_CloseHandBookRegionalSelection", self, "OnPcClose2")
  end
end

function UMG_HandBook_RegionalSelection_C:OnPcClose2()
  self:OnClosePanel()
end

function UMG_HandBook_RegionalSelection_C:OnPcClose()
  self:OnClosePanel()
end

function UMG_HandBook_RegionalSelection_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  local isBan = false
  if userClick then
    local funcId
    if tabItem and tabItem.data and tabItem.data.type == HandbookModuleEnum.SeasonHandbookTable.Handbook and tabItem.data.conf and tabItem.data.conf.area_handbook_type then
      local type = tabItem.data.conf.area_handbook_type
      if type then
        if type == _G.ProtoEnum.AreaHandbookType.AHT_A1 then
          funcId = Enum.FunctionEntrance.FE_A1_HANDBOOK
        elseif type == _G.ProtoEnum.AreaHandbookType.AHT_A2 then
          funcId = Enum.FunctionEntrance.FE_A2_HANDBOOK
        elseif type == _G.ProtoEnum.AreaHandbookType.AHT_LEGEND then
          funcId = Enum.FunctionEntrance.FE_LEGEND_HANDBOOK
        end
      end
    end
    if funcId then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, funcId, true)
    end
    if isBan then
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_RegionalSelection_List_C:OnItemSelected")
    end
  end
  return not isBan
end

function UMG_HandBook_RegionalSelection_C:OnHidePanel(IsHide)
  if IsHide then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:InitPanel(self.curPanelType)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

return UMG_HandBook_RegionalSelection_C
