local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local CompItemBase = _G.NRCPanelBase:Extend("CompItemBase")
local math_abs = math.abs

function CompItemBase:OnConstruct()
  _G.NRCModuleManager:GetModule("MainUIModule"):RegisterEvent(self, MainUIModuleEvent.ZoneInfoChange, self.OnZoneInfoChange)
  if self.CanvasTrack then
    self.CanvasTrack:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function CompItemBase:OnDestruct()
  _G.NRCModuleManager:GetModule("MainUIModule"):UnRegisterEvent(self, MainUIModuleEvent.ZoneInfoChange)
end

function CompItemBase:InitData()
  self:StopAllAnimations()
  self:SetUpOrDown()
  self:SetRightOrLeft()
  self:SetDistance()
  self:SetTrace(false)
  self.Slot:SetZOrder(0)
end

function CompItemBase:FinshCatchAnimation()
  return self.IsFinshCatchAnimation
end

function CompItemBase:SetZOrder()
end

function CompItemBase:PlayAnimationIn4()
  self:PlayAnimation(self.Light4_in)
  self:StopAnimationLoops()
end

function CompItemBase:PlayAnimationIn()
  self:PlayAnimation(self.In)
end

function CompItemBase:PlayAnimationLoop1()
  self:PlayAnimation(self.loop, 0, 0)
  if self.UMG_CompItem_Par1 then
    self.UMG_CompItem_Par1:PlayLoop1Animation()
  end
end

function CompItemBase:PlayAnimationLoop2()
  self:PlayAnimation(self.loop, 0, 0)
  if self.UMG_CompItem_Par1 then
    self.UMG_CompItem_Par1:PlayLoop2Animation()
  end
end

function CompItemBase:PlayAnimationLoop3()
  self:PlayAnimation(self.loop, 0, 0)
  if self.UMG_CompItem_Par1 then
    self.UMG_CompItem_Par1:PlayLoop3Animation()
  end
end

function CompItemBase:PlayAnimationLoop4()
  self:PlayAnimation(self.loop, 0, 0)
  if self.UMG_CompItem_Par1 then
    self.UMG_CompItem_Par1:PlayLoop4Animation()
  end
end

function CompItemBase:StopAnimationLoops()
  self:StopAnimation(self.loop)
  if self.UMG_CompItem_Par1 then
    self.UMG_CompItem_Par1:StopLoopAnimations()
  end
end

function CompItemBase:PlayAnimationOut()
  self:StopAnimationLoops()
  self:PlayAnimation(self.Out)
end

function CompItemBase:OnTaskClicked()
  self:PlayAnimation(self.flicker)
end

function CompItemBase:SetTrace(isTrace, isPlayAni, isPlayLoop)
  if isTrace then
    if isPlayLoop then
      if 1 == isPlayLoop then
        self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Play, BigMapModuleEnum.TraceAniType.TraceStart)
      end
    elseif isPlayAni then
      self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Play, BigMapModuleEnum.TraceAniType.TraceStart)
    else
      self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Play, BigMapModuleEnum.TraceAniType.TraceLoop)
    end
  else
    self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Stop, BigMapModuleEnum.TraceAniType.TraceLoop)
    self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Stop, BigMapModuleEnum.TraceAniType.TraceStart)
    if isPlayAni then
      self:HandleTraceAni(BigMapModuleEnum.TraceAniAction.Play, BigMapModuleEnum.TraceAniType.TraceEnd)
    end
  end
end

function CompItemBase:HandleTraceAni(traceAniAction, traceAniType)
  if not self.traceEffect then
    Log.ErrorFormat("CompItemBase:PlayTraceAni traceEffect is nil!!!, isShow = %s, traceAniType=%s", tostring(isShow), tostring(traceAniType))
    return
  end
  if not UE4.UObject.IsValid(self.traceEffect) or not self.traceEffect:IsA(UE4.UNRCWidgetLoader) then
    Log.ErrorFormat("CompItemBase:PlayTraceAni traceEffect is invalid!!!, isShow = %s, traceAniType=%s", tostring(isShow), tostring(traceAniType))
    return
  end
  local loaderPanel = self.traceEffect:GetPanel()
  if not loaderPanel and traceAniAction == BigMapModuleEnum.TraceAniAction.Stop then
    return
  end
  self.traceEffect:LoadPanel(nil, traceAniAction, traceAniType)
end

function CompItemBase:OnAnimationFinished(Animation)
  if Animation == self.open then
    if self.uiData.IsTrace then
      self:SetTrace(self.uiData.IsTrace)
    end
  elseif Animation == self.close then
    self:PlayAnimation(self.close, 0)
    self:PauseAnimation(self.close)
    if self.uiData.CurState == self.uiData.MapAreaState.CHANGE_TO_NPC then
      self:PlayAnimation(self.change_map)
      self:SetIcon()
    elseif self.uiData.CurState == self.uiData.MapAreaState.PET_SENSE then
      self.uiData:OpenPetSense()
    elseif self.uiData.CurState == self.uiData.MapAreaState.CLOSEING_PET_SENSE then
      self.uiData.CurState = self.uiData.MapAreaState.CLOSE_PET_SENSE
      self.uiData:SetIsShow(false)
    else
      self.uiData:CircleSelf()
    end
  elseif Animation == self.change_enlarge then
    if self.CanvasTrack_1 then
      self.CanvasTrack_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:PlayChangeSizeAni(true)
  elseif Animation == self.change_zoomout then
    if self.uiData.CurState == self.uiData.MapAreaState.CLOSEING_PET_SENSE then
      self:PlayAnimation(self.close)
    elseif self.uiData.CurState == self.uiData.MapAreaState.PET_SENSE then
      self.uiData:OpenPetSense()
    else
      self:PlayChangeSizeAni(true)
    end
  elseif Animation == self.change_map then
    self.uiData.CurState = self.uiData.MapAreaState.MAP_NPC
  elseif Animation == self.Light4_in then
    self:PlayAnimation(self.Light4_out)
  elseif Animation == self.Light4_out then
    self:PlayAnimation(self.Light4_loop, 0, 0)
    self:PlayAnimationLoop4()
  end
end

function CompItemBase:SetDistance(distance)
  if not self.Distance then
    return
  end
  if distance then
    distance = math.max(1, distance)
    if math_abs(self.lastDistance - distance) < 0.01 then
      return
    end
    self.lastDistance = distance
    self.Distance:SetText(math.round(distance))
    self.MeterText:GetParent():GetParent():SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.icon then
      local needSetAlpha = self.uiData:IsCathPet() and not self.IsWaitCahtAimEnd and self.uiData.WorldMapConfig
      if needSetAlpha then
        local alpha = 50 / distance
        if alpha < 0.5 then
          alpha = 0.5
        end
        self.icon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, alpha))
      end
    end
  else
    self.Distance:SetText("")
    self.MeterText:GetParent():GetParent():SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.lastDistance = 0
  end
end

function CompItemBase:SetIcon(Path)
  BigMapUtils.SetupDottedEdgeImage(self, self.NRCIcon, Path)
end

function CompItemBase:SetUpOrDown(param)
  if self.Up then
    if 1 == param then
      self.Up:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Up:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Error("zgx SetUpOrDown Up is nil!!!")
  end
  if self.Down then
    if 2 == param then
      self.Down:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Down:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Error("zgx SetUpOrDown Down is nil!!!")
  end
end

function CompItemBase:SetRightOrLeft(param)
  if self.Right then
    if 1 == param then
      self.Right:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Error("zgx SetRightOrLeft Right is nil!!!")
  end
  if self.Left then
    if 2 == param then
      self.Left:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Error("zgx SetRightOrLeft Left is nil!!!")
  end
end

function CompItemBase:SetIsShow(isShow)
  if isShow then
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:SetCommonIconVisibility()
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function CompItemBase:DoCircle()
  self:SetDistance()
end

function CompItemBase:PlayChangeSizeAni(isForce)
  if not isForce and (self:IsAnimationPlaying(self.change_zoomout) or self:IsAnimationPlaying(self.change_enlarge)) then
    return
  end
  if self.uiData.IsBig ~= self.IsPlayBig then
    self.IsPlayBig = self.uiData.IsBig
    if self.uiData.IsBig then
      self:PlayAnimation(self.change_enlarge)
    else
      self:PlayAnimation(self.change_zoomout)
    end
  end
end

local SetPosByCameraTempVector2D = UE4.FVector2D()

function CompItemBase:SetPosByCamera()
  local gap = self.uiData.Gap
  if self.uiData:IsCathPet() and self.IsWaitCahtAimEnd then
    gap = self.GapAim
  end
  SetPosByCameraTempVector2D:Set(gap * self.uiData.SpacePerAngle, 53)
  self.Slot:SetPosition(SetPosByCameraTempVector2D)
end

function CompItemBase:SetCommonIconVisibility()
  self:SetMapLayerIconVisibility()
  self:SetPetOwnerVisible()
end

function CompItemBase:SetMapLayerIconVisibility()
  self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self.EntranceCave or not self.uiData.WorldMapConfig then
    return
  end
  self.EntranceCave:SetPath(UEPath.MapLayerIcon)
  local iconLayerId = 0
  if self.uiData.WorldMapConfig.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_CUSTOMIZED_POINT then
    local layerId = self.uiData.layer_id
    if layerId and layerId > 0 then
      local layerConf = DataConfigManager:GetLayeredWorldMapConf(layerId)
      if layerConf and 0 ~= layerConf.area_func_id then
        iconLayerId = layerId
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  else
    local worldMapConf = self.uiData.WorldMapConfig
    local mapConfLayerId = 0
    if worldMapConf.layered_id and #worldMapConf.layered_id > 0 then
      mapConfLayerId = worldMapConf.layered_id[1]
    end
    if mapConfLayerId > 0 then
      iconLayerId = mapConfLayerId
      self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif self.uiData and self.uiData.layer_id and self.uiData.layer_id > 0 then
      iconLayerId = self.uiData.layer_id
      self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      local npcRefreshId = self.uiData.npc_refresh_id
      if nil == npcRefreshId or npcRefreshId <= 0 then
        return
      end
      local npcRefreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
      if not npcRefreshConf then
        return
      end
      local areaId = npcRefreshConf.refresh_param
      if nil == areaId or areaId <= 0 then
        return
      end
      local areaFuncId = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetAreaFuncIdByAreaId, areaId)
      if areaFuncId > 0 then
        local layerInfo = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetLayerInfoByAreaFuncId, areaFuncId)
        if layerInfo then
          iconLayerId = layerInfo.id
          self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
  end
  if iconLayerId > 0 then
    self:UpdateLayerIconColor(iconLayerId)
  end
end

function CompItemBase:UpdateLayerIconColor(iconLayerId)
  if not self.EntranceCave then
    return
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data then
    local curLayerId = bigMapModule.data:GetCurMapLayerId()
    local isSameLayer = curLayerId > 0 and curLayerId == iconLayerId
    local showHighlight = isSameLayer
    local isCamp = self.uiData.WorldMapConfig and self.uiData.WorldMapConfig.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_CAMP
    if isCamp and showHighlight then
      showHighlight = self.uiData.IsUnLock
    end
    if showHighlight then
      self.EntranceCave:SetPath(UEPath.selectPath)
    else
      self.EntranceCave:SetPath(UEPath.MapLayerIcon)
    end
  end
end

function CompItemBase:SetPetOwnerVisible()
  if not self.MutualVisits then
    return
  end
  self.MutualVisits:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local playerId = localPlayer:GetServerId()
    if self.uiData.ownerId and self.uiData.ownerId > 0 and self.uiData.ownerId ~= playerId then
      self.MutualVisits:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.EntranceCave then
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function CompItemBase:SetDottedEdgeEnabled(bEnable)
  if self.IsDottedEdgeEnabled ~= bEnable and self.NRCIcon then
    self.IsDottedEdgeEnabled = bEnable
    BigMapUtils.SetDottedEdgeEnabled(self, self.NRCIcon, bEnable)
  end
end

function CompItemBase:OnZoneInfoChange()
  self:SetCommonIconVisibility()
end

return CompItemBase
