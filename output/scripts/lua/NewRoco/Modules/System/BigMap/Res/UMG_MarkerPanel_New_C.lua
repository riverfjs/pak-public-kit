local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local UMG_MarkerPanel_New_C = _G.NRCViewBase:Extend("UMG_MarkerPanel_New_C")

function UMG_MarkerPanel_New_C:OnConstruct()
  self.MarkerTypeList = {
    {
      Type = ProtoEnum.WorldMapMarkType.ENUM.NormalMark,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMapStatic/Frames/img_MapMarker_Icon2_png.img_MapMarker_Icon2_png'"
    },
    {
      Type = ProtoEnum.WorldMapMarkType.ENUM.PetMark,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMapStatic/Frames/img_MapMarker_Icon1_png.img_MapMarker_Icon1_png'"
    }
  }
  self.data = self.module:GetData("BigMapModuleData")
  self.data:SetSelectMarkerType(nil)
  self.NormalMark = {}
  self.PetMark = {}
  self.MarkerTypeInfo = nil
  self.SelectMarker = nil
  self.IsRemove = false
  self.lockBtn = false
  self.MaxCustomPointNum = 0
  self:SetPanelBaseData()
  self:OnAddEventListener()
end

function UMG_MarkerPanel_New_C:OnDestruct()
end

function UMG_MarkerPanel_New_C:OnActive()
end

function UMG_MarkerPanel_New_C:OnDeactive()
end

function UMG_MarkerPanel_New_C:OnAddEventListener()
  self:AddButtonListener(self.MarkerBtn.btnLevelUp, self.OnMarkerBtn)
  self:AddButtonListener(self.RemoveBtn.btnLevelUp, self.OnRemoveBtn)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTraceBtn)
  self:RegisterEvent(self, BigMapModuleEvent.MarkerTypeSelectEvent, self.OnMarkerTypeSelectEvent)
  self:RegisterEvent(self, BigMapModuleEvent.MarkerSelectEvent, self.OnMarkerSelectEvent)
  self:RegisterEvent(self, BigMapModuleEvent.SetLockBtn, self.OnSetLockBtn)
end

function UMG_MarkerPanel_New_C:SetPanelBaseData()
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_CONF)
  local cfgDatas = cfgTable:GetAllDatas()
  for _, dataInfo in pairs(cfgDatas) do
    if dataInfo.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_NORMAL_POINT then
      table.insert(self.NormalMark, dataInfo)
    elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_PET_POINT then
      table.insert(self.PetMark, dataInfo)
    end
  end
  table.sort(self.NormalMark, function(a, b)
    return a.id < b.id
  end)
  table.sort(self.PetMark, function(a, b)
    return a.id < b.id
  end)
end

function UMG_MarkerPanel_New_C:SetPanelBaseInfo()
  local NewCustomPointList = self.data:GetNewCustomPointListByType(self.MarkerTypeInfo.Type)
  if self.MarkerTypeInfo.Type == ProtoEnum.WorldMapMarkType.ENUM.NormalMark then
    self.MaxCustomPointNum = _G.DataConfigManager:GetMapGlobalConfig("max_normal_point_num").num
    self.Text_1:SetText(LuaText.Map_Mark_Normal_Quantity)
  elseif self.MarkerTypeInfo.Type == ProtoEnum.WorldMapMarkType.ENUM.PetMark then
    self.MaxCustomPointNum = _G.DataConfigManager:GetMapGlobalConfig("max_pet_point_num").num
    self.Text_1:SetText(LuaText.Map_Mark_Pet_Quantity)
  end
  self.Text_2:SetText(string.format("%d/%d", #NewCustomPointList, self.MaxCustomPointNum))
end

function UMG_MarkerPanel_New_C:InitPanelData(_Data)
  self.MarkerInfo = _Data
  self.lockBtn = false
  self.data:SetSelectMarkerType(nil)
  self.InputBox.AllowContextMenu = false
  self:SetMarkerList()
  self:SetBtnInfo()
end

function UMG_MarkerPanel_New_C:OnPanelShow(_isShow)
  if _isShow then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
    self:PlayAnimation(self.open)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    if self.MarkerInfo.IsOnClickCustomMarker and not self.IsRemove then
      self:OnMarkerBtn()
      self.lockBtn = true
    end
    self:StopAllAnimations()
    self:PlayAnimation(self.close)
  end
end

function UMG_MarkerPanel_New_C:SetMarkerList()
  self.List_2:InitGridView(self.MarkerTypeList)
  local Index = 0
  if self.MarkerInfo.IsOnClickCustomMarker then
    if self.MarkerInfo.MarkerData.type == ProtoEnum.WorldMapMarkType.ENUM.NormalMark then
      Index = 0
    elseif self.MarkerInfo.MarkerData.type == ProtoEnum.WorldMapMarkType.ENUM.PetMark then
      Index = 1
    end
  else
    local NorMalPointNum = self.data:GetNewCustomPointListByType(ProtoEnum.WorldMapMarkType.ENUM.NormalMark)
    local PetPointNum = self.data:GetNewCustomPointListByType(ProtoEnum.WorldMapMarkType.ENUM.PetMark)
    local NorMalPointMaxNum = _G.DataConfigManager:GetMapGlobalConfig("max_normal_point_num").num
    local PetPointMaxNum = _G.DataConfigManager:GetMapGlobalConfig("max_pet_point_num").num
    if NorMalPointMaxNum <= #NorMalPointNum then
      Index = 1
    elseif PetPointMaxNum <= #PetPointNum then
      Index = 0
    end
  end
  self.List_2:SelectItemByIndex(Index)
end

function UMG_MarkerPanel_New_C:OnMarkerTypeSelectEvent(MarkerTypeInfo)
  self.MarkerTypeInfo = MarkerTypeInfo
  local MarkerList
  if MarkerTypeInfo.Type == ProtoEnum.WorldMapMarkType.ENUM.NormalMark then
    MarkerList = self.NormalMark
  elseif MarkerTypeInfo.Type == ProtoEnum.WorldMapMarkType.ENUM.PetMark then
    MarkerList = self.PetMark
  end
  self.dotList:InitGridView(MarkerList)
  local Index = 0
  if self.MarkerInfo.IsOnClickCustomMarker then
    Index = self:GetMarkerIndex(MarkerList)
  end
  self:SetPanelBaseInfo()
  local NewCustomPointList = self.data:GetNewCustomPointListByType(self.MarkerTypeInfo.Type)
  for i, Marker in ipairs(MarkerList) do
    local Item = self.dotList:GetItemByIndex(i - 1)
    if Item then
      local num = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNewCustomPointNumByMapCfgId, Marker.id)
      if Marker.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_PET_POINT and num > 0 then
        Item:SetNum(num)
      end
      if not self.MarkerInfo.IsOnClickCustomMarker or self.MarkerInfo.MarkerData.type ~= MarkerTypeInfo.Type then
        if #NewCustomPointList >= self.MaxCustomPointNum then
          Item:SetIsCanClick(false, num, Marker.map_show_type)
        else
          Item:SetIsCanClick(true, num, Marker.map_show_type)
        end
      else
        Item:SetIsCanClick(true, num, Marker.map_show_type)
      end
    end
  end
  if #NewCustomPointList < self.MaxCustomPointNum or self.MarkerInfo.IsOnClickCustomMarker then
    self.dotList:SelectItemByIndex(Index)
  end
end

function UMG_MarkerPanel_New_C:OnMarkerSelectEvent(_SelectMarker)
  self.SelectMarker = _SelectMarker
  self.MarkIcon:SetPath(_SelectMarker.world_map_NPCicon_des)
  if self.MarkerInfo.IsOnClickCustomMarker then
    self.InputBox:SetText(self.MarkerInfo.MarkerData.name)
  end
end

function UMG_MarkerPanel_New_C:GetMarkerIndex(MarkerList)
  for i, Marker in ipairs(MarkerList) do
    if Marker.id == self.MarkerInfo.MarkerData.world_map_cfg_id then
      return i - 1
    end
  end
  return 0
end

function UMG_MarkerPanel_New_C:SetBtnInfo()
  if self.MarkerInfo.IsOnClickCustomMarker then
    self.btnSwitcher:SetActiveWidgetIndex(1)
    if self.MarkerInfo.MarkerData.is_track then
      self.TraceBtn:SetBtnText(LuaText.umg_npcinfo_3)
    else
      self.TraceBtn:SetBtnText(LuaText.umg_npcinfo_1)
    end
  else
    self.btnSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_MarkerPanel_New_C:OnMarkerBtn()
  if self.lockBtn then
    return
  end
  if not self.MarkerTypeInfo then
    return
  end
  self.lockBtn = true
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401004, "UMG_MarkerPanel_C:OnClickMarkerBtn")
  local Name = self.InputBox:GetText()
  if self.MarkerInfo.IsOnClickCustomMarker then
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, self.MarkerInfo.MarkerData.mark_id, _G.ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK, self.SelectMarker, Name, self.MarkerInfo.SelectScenePos)
  else
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, nil, _G.ProtoEnum.MapMarkOpType.MMOT_ADD_MARK, self.SelectMarker, Name, self.MarkerInfo.SelectScenePos)
  end
end

function UMG_MarkerPanel_New_C:OnRemoveBtn()
  if self.lockBtn then
    return
  end
  self.IsRemove = true
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_MarkerPanel_C:OnClickRemoveBtn")
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, self.MarkerInfo.MarkerData.mark_id, _G.ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK)
end

function UMG_MarkerPanel_New_C:OnTraceBtn()
  if self.lockBtn then
    return
  end
  self.lockBtn = true
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, self.MarkerInfo.MarkerData.mark_id, 4, self.MarkerInfo.MarkerData, nil, nil, self.MarkerInfo.MarkerData.is_track)
  if self.MarkerInfo.IsOnClickCustomMarker then
    local Name = self.InputBox:GetText()
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, self.MarkerInfo.MarkerData.mark_id, _G.ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK, self.SelectMarker, Name, self.MarkerInfo.SelectScenePos)
  end
end

function UMG_MarkerPanel_New_C:OnAnimationFinished(Animation)
  if Animation == self.close then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MarkerPanel_New_C:OnSetLockBtn(_lockBtn)
  self.lockBtn = _lockBtn
end

return UMG_MarkerPanel_New_C
