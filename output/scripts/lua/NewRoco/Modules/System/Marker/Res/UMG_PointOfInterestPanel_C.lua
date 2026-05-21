local MarkerEnum = require("NewRoco.Modules.Core.Marker.MarkerEnum")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MarkerModuleEvent = reload("NewRoco.Modules.Core.Marker.MarkerModuleEvent")
local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local UMG_PointOfInterestPanel_C = NRCViewBase:Extend("UMG_PointOfInterestPanel_C")

function UMG_PointOfInterestPanel_C:OnAddEventListener()
  Log.Debug("Track Marker UMG_PointOfInterestPanel_C:OnAddEventListener")
  NRCEventCenter:RegisterEvent("UMG_PointOfInterestPanel_C", self, MarkerModuleEvent.POI_REMOVE, self.StopTrack)
  NRCEventCenter:RegisterEvent("UMG_PointOfInterestPanel_C", self, MarkerModuleEvent.POI_UPDATE, self.UpdateTrack)
  NRCEventCenter:RegisterEvent("UMG_PointOfInterestPanel_C", self, SceneEvent.LoadMapStart, self.ClearCached)
  NRCEventCenter:RegisterEvent("UMG_PointOfInterestPanel_C", self, SceneEvent.PlayerBornFinish, self.UpdateCached)
end

function UMG_PointOfInterestPanel_C:OnDestruct()
  Log.Debug("Track Marker UMG_PointOfInterestPanel_C:OnRemoveEventListener")
  NRCEventCenter:UnRegisterEvent(self, MarkerModuleEvent.POI_REMOVE, self.StopTrack)
  NRCEventCenter:UnRegisterEvent(self, MarkerModuleEvent.POI_UPDATE, self.UpdateTrack)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.ClearCached)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.UpdateCached)
  if self.Items then
    for k, v in pairs(self.Items) do
      v:Destruct()
      v:ReleaseForce()
    end
    table.clear(self.Items)
  end
  NRCEventCenter:DispatchEvent(MarkerModuleEvent.OnPanelClosed)
end

function UMG_PointOfInterestPanel_C:UpdateTrack(tracker)
  if not tracker then
    return
  end
  local tracked = self.Items[tracker] ~= nil
  if tracked then
    return
  end
  self:AddPOI(tracker)
end

function UMG_PointOfInterestPanel_C:StopTrack(tracker)
  self:RemovePOI(tracker)
end

function UMG_PointOfInterestPanel_C:UpdateViewport()
  local Size = UE4.UWidgetLayoutLibrary.GetViewportSize(self.World)
  local Scale = UE4.UWidgetLayoutLibrary.GetViewportScale(self.World)
  self.ViewportCenter = Size / Scale / 2
  self.Axis = self.ViewportCenter * 0.7
end

function UMG_PointOfInterestPanel_C:UpdateCached()
  self.World = _G.UE4Helper.GetCurrentWorld()
  self.playerController = UE4.UGameplayStatics.GetPlayerController(self.World, 0)
  self.playerCameraManager = self:GetOwningPlayerCameraManager()
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:UpdateViewport()
end

function UMG_PointOfInterestPanel_C:ClearCached()
  self.World = false
  self.playerController = false
  self.playerCameraManager = false
  self.localPlayer = false
end

function UMG_PointOfInterestPanel_C:OnConstruct()
  Log.Debug("POI_Panel_Open")
  self.Items = {}
  self.DpiScaleY = 1
  self:UpdateCached()
  self.POIMin = _G.DataConfigManager:GetMapGlobalConfig("npc_guide_min").num
  self.POIMax = _G.DataConfigManager:GetMapGlobalConfig("npc_guide_max").num
  self.POIMin2 = _G.DataConfigManager:GetMapGlobalConfig("trigger_guide_min").num
  self.POIMax2 = _G.DataConfigManager:GetMapGlobalConfig("trigger_guide_max").num
  self:InitTrackers()
  self:OnAddEventListener()
  self:UpdateCanTick()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PointOfInterestPanel_C:InitTrackers()
  local Trackers = _G.NRCModeManager:DoCmd(MarkerModuleCmd.GetTrackers)
  if not Trackers then
    return
  end
  for _, Tracker in pairs(Trackers) do
    self:AddPOI(Tracker)
  end
end

function UMG_PointOfInterestPanel_C:AddPOI(Tracker)
  local POItem = self.Items[Tracker]
  if not POItem then
    POItem = UE4.UWidgetBlueprintLibrary.Create(self, self.PointOfInterest)
    self.TrackPanel:AddChildToCanvas(POItem)
    self.Items[Tracker] = POItem
    self:UpdateCanTick()
    POItem:SetTracker(Tracker)
    return
  end
  POItem:SetTracker(Tracker)
  self.Items[Tracker] = POItem
end

function UMG_PointOfInterestPanel_C:RemovePOI(Tracker)
  local POItem = self.Items[Tracker]
  if POItem then
    self.Items[Tracker] = nil
    self.TrackPanel:RemoveChild(POItem)
    self:UpdateCanTick()
    Log.DebugFormat("Remove POI Track")
  end
end

function UMG_PointOfInterestPanel_C:UpdateCanTick()
  for _, v in pairs(self.Items) do
    if v then
      _G.UpdateManager:Register(self)
      return
    end
  end
  _G.UpdateManager:UnRegister(self)
end

function UMG_PointOfInterestPanel_C:OnTick()
  if not self.localPlayer then
    return
  end
  self.hasItemShow = false
  self.playerPosition = self.localPlayer:GetActorLocationFrameCache()
  for _, v in pairs(self.Items) do
    self:TickItem(v)
  end
  if self.lastItemShow == nil or self.lastItemShow ~= self.hasItemShow then
    if self.hasItemShow then
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.lastItemShow = self.hasItemShow
  end
end

function UMG_PointOfInterestPanel_C:TickItem(item)
  if not self.playerController then
    return
  end
  if not self.World then
    return
  end
  if not item then
    return
  end
  if not UE.UObject.IsValid(item) then
    return
  end
  if not item:CheckValid() then
    item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local TargetPosition = item:GetPosition()
  local disSquare = (TargetPosition - self.playerPosition):SizeSquared()
  if item:GetSourceType() == MarkerEnum.SourceType.NPCCombination then
    if disSquare / 10000 > self.POIMax * self.POIMax or disSquare / 10000 < self.POIMin * self.POIMin then
      item:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
  elseif disSquare / 10000 > self.POIMax2 * self.POIMax2 or disSquare / 10000 < self.POIMin2 * self.POIMin2 then
    item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  item:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.hasItemShow = true
  local ScreenPos = UE4.FVector2D()
  local ViewportPos = UE4.FVector2D()
  local result = UE4.UNRCStatics.Abs_ProjectWorldToScreen(self.playerController, TargetPosition, ScreenPos)
  UE4.USlateBlueprintLibrary.ScreenToViewportConsiderBorder(self.World, ScreenPos, ViewportPos)
  local delta = ViewportPos - self.ViewportCenter
  local theta = math.atan(delta.Y, delta.X)
  if not result then
    theta = theta - math.pi
  end
  local onPos = FVector2DUtils.GetEllipse(self.Axis, theta)
  if result then
    local CenterLength = delta:SizeSquared()
    local CircleRadius = onPos:SizeSquared()
    if CenterLength > CircleRadius then
      ViewportPos = onPos + self.ViewportCenter
      item:UpdateArrow(theta)
    else
      item:ToggleArrow(false, math.sqrt(disSquare))
    end
  else
    ViewportPos = onPos + self.ViewportCenter
    item:UpdateArrow(theta)
  end
  ViewportPos.X = ViewportPos.X * self.DpiScaleY
  ViewportPos.Y = ViewportPos.Y * self.DpiScaleY
  item:SetPosition(ViewportPos)
  item:UpdateAnimation()
end

return UMG_PointOfInterestPanel_C
