local UMG_OnlineTeammateTagItem_C = _G.NRCPanelBase:Extend("UMG_OnlineTeammateTagItem_C")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local OnlineConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()

local function GetNumberFromMapConf(Key, Default)
  local Conf = _G.DataConfigManager:GetMapGlobalConfig(Key)
  if not Conf then
    return Default
  end
  local Num = Conf.num
  if not Num then
    return Default
  end
  return Num
end

local XAxisFactor = GetNumberFromMapConf("hud_x_axis_scale", 70) / 100
local YAxisFactor = GetNumberFromMapConf("hud_y_axis_scale", 70) / 100
local TempScreenPos = UE4.FVector2D()
local TempViewportPos = UE4.FVector2D()
local TempDelta = UE4.FVector2D()
local TempOnPos = UE4.FVector2D()
local screenPos = UE4.FVector2D()
local viewportPos = UE4.FVector2D()
local deltaPos = UE4.FVector2D()
local ellipsePos = UE4.FVector2D()
UMG_OnlineTeammateTagItem_C.teammateIndex = 0
UMG_OnlineTeammateTagItem_C.teammateInfo = nil

function UMG_OnlineTeammateTagItem_C:OnActive()
  self:UpdateViewportInfo()
end

function UMG_OnlineTeammateTagItem_C:OnDeactive()
  self:ClearTeammateTag()
end

function UMG_OnlineTeammateTagItem_C:OnTick(InDeltaTime)
  if not self.tickTime then
    self.tickTime = 0
  end
  self.tickTime = self.tickTime + InDeltaTime
  if self.tickTime >= 1 then
    if self and UE4.UObject.IsValid(self) then
      if self.teammateInfo and self.teammateInfo.pos and self.teammateInfo.pos.pos then
        local shouldShow = self:ShouldShowTeammateTag()
        if shouldShow then
          self:SetVisibility(UE4.ESlateVisibility.Visible)
          self:UpdatePositionAndDirection()
        else
          self:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    self.tickTime = 0
  end
end

function UMG_OnlineTeammateTagItem_C:SetTeammateInfo(visitorInfo)
  if not visitorInfo then
    return
  end
  self.teammateInfo = visitorInfo
  if self.NRCSwitcher_0 then
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  end
  self:UpdatePositionAndDirection()
end

function UMG_OnlineTeammateTagItem_C:UpdateViewportInfo()
  local World = _G.UE4Helper.GetCurrentWorld()
  if not World then
    return
  end
  local Size = UE4.UWidgetLayoutLibrary.GetViewportSize(World)
  local Scale = UE4.UWidgetLayoutLibrary.GetViewportScale(World)
  self.DpiScaleY = 1
  self.ViewportCenter = Size / Scale / 2
  self.Axis = UE4.FVector2D(self.ViewportCenter.X * XAxisFactor, self.ViewportCenter.Y * YAxisFactor)
end

function UMG_OnlineTeammateTagItem_C:SetTeammateNumber(index)
  self.teammateIndex = index or 0
  if self.Distance then
    self.Teammate:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Distance:SetText(tostring(self.teammateIndex))
  end
end

function UMG_OnlineTeammateTagItem_C:ShouldShowTeammateTag()
  if not (self.teammateInfo and self.teammateInfo.pos) or not self.teammateInfo.pos.pos then
    return false
  end
  local myPos = self:GetPlayerPosition()
  if not myPos then
    return false
  end
  local distance = self:CalculateDistance(myPos, self.teammateInfo.pos)
  local showDistance = 1000
  for i = 1, #OnlineConf do
    if OnlineConf[i].key == "online_number_HUD_show_distance" then
      showDistance = OnlineConf[i].num
      break
    end
  end
  if distance > showDistance then
    return false
  end
  local isHeadHudVisible = self:IsTeammateHeadHudVisible()
  return not isHeadHudVisible
end

function UMG_OnlineTeammateTagItem_C:IsTeammateInViewport()
  if not (self.teammateInfo and self.teammateInfo.pos) or not self.teammateInfo.pos.pos then
    return false
  end
  if not self.ViewportCenter or not self.Axis then
    self:UpdateViewportInfo()
    if not self.ViewportCenter or not self.Axis then
      return false
    end
  end
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return false
  end
  local ctrl = player:GetUEController()
  if not ctrl then
    return false
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  if not World then
    return false
  end
  local teammateWorldPos = UE4.FVector(self.teammateInfo.pos.pos.x, self.teammateInfo.pos.pos.y, self.teammateInfo.pos.pos.z)
  local result = UE4.UNRCStatics.Abs_ProjectWorldToScreen(ctrl, teammateWorldPos, screenPos)
  if not result then
    return false
  end
  UE4.USlateBlueprintLibrary.ScreenToViewportConsiderBorder(World, screenPos, viewportPos)
  viewportPos:SubInto(self.ViewportCenter, deltaPos)
  local theta = math.atan(deltaPos.Y, deltaPos.X)
  FVector2DUtils.GetEllipseInplace(self.Axis, theta, ellipsePos)
  local CenterLength = deltaPos:SizeSquared()
  local CircleRadius = ellipsePos:SizeSquared()
  return CenterLength <= CircleRadius
end

function UMG_OnlineTeammateTagItem_C:CalculateDistance(pos1, pos2)
  if not (pos1 and pos2) or not pos2.pos then
    return 0
  end
  local dx = pos2.pos.x - pos1.X
  local dy = pos2.pos.y - pos1.Y
  local dz = pos2.pos.z - pos1.Z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function UMG_OnlineTeammateTagItem_C:UpdatePositionAndDirection()
  if not (self.teammateInfo and self.teammateInfo.pos) or not self.teammateInfo.pos.pos then
    return
  end
  if not self.ViewportCenter or not self.Axis then
    self:UpdateViewportInfo()
    if not self.ViewportCenter or not self.Axis then
      return
    end
  end
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local ctrl = player:GetUEController()
  if not ctrl then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  if not World then
    return
  end
  local teammateWorldPos = UE4.FVector(self.teammateInfo.pos.pos.x, self.teammateInfo.pos.pos.y, self.teammateInfo.pos.pos.z)
  local ScreenPos = TempScreenPos
  local ViewportPos = TempViewportPos
  local result = UE4.UNRCStatics.Abs_ProjectWorldToScreen(ctrl, teammateWorldPos, ScreenPos)
  UE4.USlateBlueprintLibrary.ScreenToViewportConsiderBorder(World, ScreenPos, ViewportPos)
  ViewportPos:SubInto(self.ViewportCenter, TempDelta)
  local delta = TempDelta
  local theta = math.atan(delta.Y, delta.X)
  if not result then
    theta = theta - math.pi
  end
  FVector2DUtils.GetEllipseInplace(self.Axis, theta, TempOnPos)
  local onPos = TempOnPos
  if result then
    local CenterLength = delta:SizeSquared()
    local CircleRadius = onPos:SizeSquared()
    if CenterLength > CircleRadius then
      onPos:AddInto(self.ViewportCenter, ViewportPos)
      self:UpdateArrowDirection(theta)
    else
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
  else
    onPos:AddInto(self.ViewportCenter, ViewportPos)
    self:UpdateArrowDirection(theta)
  end
  ViewportPos.X = ViewportPos.X * self.DpiScaleY
  ViewportPos.Y = ViewportPos.Y * self.DpiScaleY - 30
  self:SetPosition(ViewportPos)
end

function UMG_OnlineTeammateTagItem_C:GetPlayerPosition()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return nil
  end
  return player.viewObj:Abs_K2_GetActorLocation()
end

function UMG_OnlineTeammateTagItem_C:UpdateArrowDirection(theta)
  if not self.Arrow then
    return
  end
  local degrees = math.deg(theta) + 90
  self.Arrow:SetRenderTransformAngle(degrees)
end

function UMG_OnlineTeammateTagItem_C:SetPosition(position)
  if not self.Slot then
    return
  end
  self.Slot:SetPosition(position)
end

function UMG_OnlineTeammateTagItem_C:IsTeammateHeadHudVisible()
  if not self.teammateInfo or not self.teammateInfo.uin then
    return false
  end
  local teammatePlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.teammateInfo.uin)
  if not teammatePlayer or not teammatePlayer.viewObj then
    return false
  end
  local HeadWidget = teammatePlayer.viewObj.HeadWidget
  if not HeadWidget then
    return false
  end
  local HeadHud = HeadWidget:GetUserWidgetObject()
  if not HeadHud then
    return false
  end
  if not HeadHud.visible then
    return false
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  if not World then
    return false
  end
  local ViewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(World)
  local ViewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(World)
  local ActualViewportSize = ViewportSize / ViewportScale
  local hudGeometry = HeadHud:GetCachedGeometry()
  local hudSize = UE4.USlateBlueprintLibrary.GetLocalSize(hudGeometry)
  local _, hudLeftViewportPos = UE4.USlateBlueprintLibrary.LocalToViewport(World, hudGeometry, UE4.FVector2D(0, 0))
  local _, hudRightViewportPos = UE4.USlateBlueprintLibrary.LocalToViewport(World, hudGeometry, UE4.FVector2D(hudSize.X, 0))
  local _, hudBottomViewportPos = UE4.USlateBlueprintLibrary.LocalToViewport(World, hudGeometry, UE4.FVector2D(0, hudSize.Y))
  local isInViewport = hudLeftViewportPos.X <= ActualViewportSize.X and hudRightViewportPos.X >= 0 and hudBottomViewportPos.Y >= 0 and hudBottomViewportPos.Y <= ActualViewportSize.Y
  return isInViewport
end

function UMG_OnlineTeammateTagItem_C:ClearTeammateTag()
  self.teammateInfo = nil
  self.teammateIndex = 0
  if self.Distance then
    self.Distance:SetText("")
  end
  if self.Arrow then
    self.Arrow:SetRenderTransformAngle(0)
  end
end

return UMG_OnlineTeammateTagItem_C
