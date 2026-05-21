local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local UMG_ZoneTip_C = _G.NRCPanelBase:Extend("UMG_ZoneTip_C")

function UMG_ZoneTip_C:OnConstruct()
end

function UMG_ZoneTip_C:OnDestruct()
end

function UMG_ZoneTip_C:OnEnable()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ZoneTip_C:OnActive(zoneId, action)
  self.IsStop = false
end

function UMG_ZoneTip_C:IsShowPanel(_IsShowPanel)
  if _IsShowPanel then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ZoneTip_C:OnShowActivityZoneTip(desc)
  local name1 = desc
  if not name1 then
    self.ParentPanel:ConsumeNext()
    return
  end
  local name2 = ""
  local nameList = string.split(desc, "_")
  if nameList and #nameList > 1 then
    name1 = nameList[1]
    name2 = nameList[2]
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ParentPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SizeBox_61:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self:IsAnimationPlaying(self.In) then
    self.IsStop = true
    self:StopAnimation(self.In)
  elseif self:IsAnimationPlaying(self.In_2) then
    self.IsStop = true
    self:StopAnimation(self.In_2)
  elseif self:IsAnimationPlaying(self.In_0) then
    self.IsStop = true
    self:StopAnimation(self.In_0)
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local Font = self.zoneTitle.Font
  self.zoneTitle:SetText(name1)
  if not string.IsNilOrEmpty(name2) then
    self.Ununlocked:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Title:SetText(name2)
    _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_StartPlayMapTips)
    self:PlayAnimation(self.In_0)
  else
    self.Ununlocked:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Title:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.In)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1357, "UMG_ZoneTip_C:OnShowZoneTip")
  Font.Size = 58
  self.zoneTitle:SetFont(Font)
  _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_StartPlayMapTips)
  self:PlayAnimation(self.In_2)
end

function UMG_ZoneTip_C:OnShowEnterHomeZoneTip()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HomeTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.HomeTitle:SetText(HomeIndoorSandbox.Server.WorldData.HomeName or "")
  self.ComfortlevelTitle:SetText(tostring(HomeIndoorSandbox.Server.WorldData.HomeComfortLevel))
  self:PlayAnimation(self.In_home)
  _G.NRCAudioManager:PlaySound2DAuto(1357, "UMG_ZoneTip_C:OnShowEnterHomeZoneTip")
end

function UMG_ZoneTip_C:OnShowZoneTip(zoneId, action)
  if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.IsPlaying) then
    self.ParentPanel:ConsumeNext()
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ParentPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local funcConf = _G.DataConfigManager:GetAreaFuncConf(zoneId)
  local name1 = funcConf.name
  local subTitle
  local UnLock = false
  local IsShow = false
  if not name1 then
    self.ParentPanel:ConsumeNext()
  end
  if name1 and funcConf.broadcast_type == _G.Enum.AreaBroadcastType.ABT_NORMAL then
    local AreaConf = self:GetSecondAreaConf(zoneId)
    if AreaConf and action and action.bIsUnlocked == false then
      UnLock = true
    end
  elseif funcConf.broadcast_type == _G.Enum.AreaBroadcastType.ABT_DUNGEON then
    local DungeonConf = _G.DataConfigManager:GetDungeonConf(funcConf.world_map_name_scale)
    if DungeonConf then
      UnLock = true
      IsShow = true
      subTitle = DungeonConf.sub_name
    end
  elseif funcConf.broadcast_type == _G.Enum.AreaBroadcastType.ABT_PLANT then
    local homeInfo = FarmUtils.GetCurrentWorldHomeInfo()
    if homeInfo then
      name1 = string.format(name1, homeInfo.home_name)
      UnLock = false
      IsShow = true
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif funcConf.broadcast_type == _G.Enum.AreaBroadcastType.ABT_ACTIVITY then
    UnLock = true
    IsShow = true
    local worldMapActivityConf = NRCModuleManager:DoCmd(BigMapModuleCmd.GetWorldMapActivityConfByAreaFuncId, zoneId)
    if worldMapActivityConf then
      subTitle = worldMapActivityConf.activity_name
    end
  end
  if name1 and funcConf.broadcast_type ~= _G.Enum.AreaBroadcastType.ABT_NONE then
    if self:IsAnimationPlaying(self.In) then
      self.IsStop = true
      self:StopAnimation(self.In)
    elseif self:IsAnimationPlaying(self.In_2) then
      self.IsStop = true
      self:StopAnimation(self.In_2)
    elseif self:IsAnimationPlaying(self.In_0) then
      self.IsStop = true
      self:StopAnimation(self.In_0)
    end
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local Font = self.zoneTitle.Font
    self.zoneTitle:SetText(name1)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1357, "UMG_ZoneTip_C:OnShowZoneTip")
    if IsShow then
      self.Ununlocked:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Ununlocked:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.SizeBox_61:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if UnLock then
      Font.Size = 58
      self.zoneTitle:SetFont(Font)
      _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
      if subTitle then
        self.Title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Title:SetText(subTitle)
        _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_StartPlayMapTips)
        self:PlayAnimation(self.In_0)
      else
        self.Title:SetVisibility(UE4.ESlateVisibility.Collapsed)
        _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_StartPlayMapTips)
        self:PlayAnimation(self.In)
      end
    else
      self.Ununlocked:SetVisibility(UE4.ESlateVisibility.Collapsed)
      Font.Size = 58
      self.zoneTitle:SetFont(Font)
      _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_StartPlayMapTips)
      self:PlayAnimation(self.In_2)
    end
  end
end

function UMG_ZoneTip_C:GetSecondAreaConf(zoneId)
  local CampConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CAMP_CONF):GetAllDatas()
  local WeatherAreaId, AreaConf
  for i, Levelup in pairs(CampConf) do
    if zoneId == Levelup.broadcast_name_func_id then
      WeatherAreaId = Levelup.weather_func_id[1]
    end
  end
  if WeatherAreaId then
    AreaConf = _G.DataConfigManager:GetAreaFuncConf(WeatherAreaId)
  end
  return AreaConf
end

function UMG_ZoneTip_C:OnAnimationFinished(Animation)
  if Animation == self.In or Animation == self.In_2 or Animation == self.In_0 or Animation == self.In_home then
    if self.IsStop == false then
    else
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.ParentPanel and self.ParentPanel:IsPaused() then
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.zoneTitle:SetRenderOpacity(0)
    self.IsStop = false
    self.ParentPanel:ConsumeNext()
    _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.TopHud_EndPlayMapTips)
  end
  if Animation == self.In_home then
    self.HomeTips:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if Animation == self.In then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_ZoneTip_C:SetParent(parent)
  self.ParentPanel = parent
end

function UMG_ZoneTip_C:OnDeactive()
end

return UMG_ZoneTip_C
