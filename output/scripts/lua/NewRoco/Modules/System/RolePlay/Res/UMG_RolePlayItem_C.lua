local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local UMG_RolePlayItem_C = Base:Extend("UMG_RolePlayItem_C")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local RolePlayModuleEvent = require("NewRoco.Modules.System.RolePlay.RolePlayModuleEvent")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")

function UMG_RolePlayItem_C:IsValidItem()
  return self.data and self.data.type and not not self.data.value
end

function UMG_RolePlayItem_C:OnConstruct()
  self.marqueeSpeed = 0.05
  self.bShouldEnableMarquee = false
  self.nextTriggerPropTime = 0
  _G.UpdateManager:Register(self)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnRolePlayPropsBanStateChanged, self.OnRolePlayPropsBanStateChanged)
end

function UMG_RolePlayItem_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
  self:ClearCountdownTime()
  _G.NRCEventCenter:UnRegisterEvent(self, RolePlayModuleEvent.ItemEraseRedPoint, self.CheckEraseRedPoint)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRolePlayPropsBanStateChanged, self.OnRolePlayPropsBanStateChanged)
  self:CancelDelayCheckShouldEnableMarquee()
end

function UMG_RolePlayItem_C:RefreshByRoleplaySelectReplace(Data)
  self.data = Data
  self:UpdateBehaviorConfItem()
  self:PlayAnimation(self.Refresh)
end

function UMG_RolePlayItem_C:OnItemUpdate(_data, datalist, index)
  local changeTab = not self.data or self.data.type ~= _data.type or self.data.value ~= _data.value
  self.index = index
  self.data = _data
  self.bLongPressEventTriggered = false
  if not self:IsValidItem() then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  self:StopAllAnimations()
  self:ClearCountdownTime()
  self:PlayAnimation(self.Normal)
  if changeTab then
    if _data.bSelected then
      self:PlayAnimation(self.Selected_in)
    else
      self:PlayAnimation(self.In)
    end
  elseif _data.bSelected then
    self:PlayAnimation(self.Selected_loop)
  else
    self:PlayAnimation(self.In, self.In:GetEndTime() - 0.02)
  end
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Parts:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetItemNameShow(_data.bSelected)
  self.Dazzling:UpdateState(false)
  self.Select_1:SetVisibility(_data.bSelected and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Select_2:SetVisibility(_data.bSelected and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if self.data.star then
    self.CanvasPanel_ActionClip:SetClipping(UE.EWidgetClipping.ClipToBounds)
    self.NRCImage_starbg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasPanel_ActionClip:SetClipping(UE.EWidgetClipping.Inherit)
    self.NRCImage_starbg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.StarRating1:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.StarRating2:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  local rolePlayType = _data and _data.type
  if rolePlayType == RolePlayModuleDef.RolePlayType.Sound then
    self:UpdateBehaviorConfItem()
    self.NRCSwitcher_85:SetActiveWidgetIndex(0)
  elseif rolePlayType == RolePlayModuleDef.RolePlayType.Action then
    self:UpdateBehaviorConfItem()
    self.NRCSwitcher_85:SetActiveWidgetIndex(1)
  elseif rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
    self:UpdateWardrobeConfItem()
    self.NRCSwitcher_85:SetActiveWidgetIndex(2)
  elseif rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
    self:UpdateBehaviorConfItem()
    self.NRCSwitcher_85:SetActiveWidgetIndex(3)
  elseif rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    self:UpdatePropConfItem()
    self.NRCSwitcher_85:SetActiveWidgetIndex(4)
    self.skipFunc_OnItemSelected = _data.bSelected
  end
  if rolePlayType ~= RolePlayModuleDef.RolePlayType.Suit then
    self.Parts:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not self.hasInit then
    self.hasInit = true
    _G.NRCEventCenter:RegisterEvent("UMG_RolePlayItem_C", self, RolePlayModuleEvent.ItemEraseRedPoint, self.CheckEraseRedPoint)
  end
  if 0 ~= self.index % 5 then
    local indexText = self.index % 5
    self.PCKey:SetText(indexText)
  else
    self.PCKey:SetText(5)
  end
end

function UMG_RolePlayItem_C:OpItem(opType)
  if "IsCanSelect" == opType then
    return not self:IsAnimationPlaying(self.In)
  end
end

function UMG_RolePlayItem_C:OnTick(deltaTime)
  if self.bShouldEnableMarquee and self.Name:GetVisibility() == UE4.ESlateVisibility.HitTestInvisible then
    local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_33)
    if not slot then
      return
    end
    local scrollBoxWidth = slot:GetSize().x
    local ScollEnd = self.ScrollBox_33:GetScrollOffsetOfEnd()
    local totalScrollEnd = ScollEnd + scrollBoxWidth
    self.marqueeProgress = (self.marqueeProgress or 0) + (self.marqueeSpeed or 50) * deltaTime * totalScrollEnd
    local half = totalScrollEnd * 0.5
    if half < self.marqueeProgress then
      self.marqueeProgress = self.marqueeProgress - half
    end
    self.marqueeProgress = math.min(self.marqueeProgress, half)
    self.ScrollBox_33:SetScrollOffset(self.marqueeProgress)
  end
end

function UMG_RolePlayItem_C:CalculateTextWidth(textComp, textContent)
  if not textComp then
    Log.Error("UMG_RolePlayItem_C textComp is nil")
    return
  end
  local textWidth = textComp:GetDesiredSize().X
  local Slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_33)
  if Slot then
    local scrollBoxWidth = Slot:GetSize().x
    if textWidth >= scrollBoxWidth then
      textComp:SetText(string.format("%s    %s    ", textContent, textContent))
      return true
    end
  end
  return false
end

function UMG_RolePlayItem_C:OnItemSelected(_bSelected)
  if not UE4.UObject.IsValid(self.Object) then
    Log.Error("UMG_RolePlayItem_C Object is nil")
    return
  end
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  local rolePlayType = self.data and self.data.type
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_RolePlayItem_C:OnItemSelected")
    if self.bIgnoreSelect then
      self.bIgnoreSelect = false
    elseif not self.bLongPressEventTriggered then
      if rolePlayType == RolePlayModuleDef.RolePlayType.Action or rolePlayType == RolePlayModuleDef.RolePlayType.Sound then
        self:SelectBehaviorConfItem()
      elseif rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
        self:SelectWardrobeConfItem()
      elseif rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
        self:SelectInteractiveConfItem()
      elseif rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
        if self.skipFunc_OnItemSelected then
          self.skipFunc_OnItemSelected = false
        else
          self:SelectFurnitureConfItem()
        end
      end
    end
    if self.BroadcastOnClicked then
      self:BroadcastOnClicked()
    end
    self:CheckEraseRedPoint()
  end
  if rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
  else
    self:SetItemNameShow(_bSelected)
    self:StopAllAnimations()
    self:PlayAnimation(_bSelected and self.Selected_in or self.Selected_out)
  end
end

function UMG_RolePlayItem_C:SetItemNameShow(isShow)
  self.isShow = isShow
  self:CancelDelayCheckShouldEnableMarquee()
  self.marqueeProgress = 0
  self.bShouldEnableMarquee = false
  if isShow then
    self.Name:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.ScrollBox_33:ScrollToStart()
    self.delayCheckShouldEnableMarqueeId = _G.DelayManager:DelaySeconds(0.2, self.DoDelayCheckShouldEnableMarquee, self)
    self.PCKey:SetKeyVisibility(false)
  else
    self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_RolePlayItem_C:OnDeactive()
end

function UMG_RolePlayItem_C:SetName(name)
  self.Name:SetText(name)
  self.origNameForMarquee = name
end

function UMG_RolePlayItem_C:CancelDelayCheckShouldEnableMarquee()
  if self.delayCheckShouldEnableMarqueeId then
    _G.DelayManager:CancelDelayById(self.delayCheckShouldEnableMarqueeId)
    self.delayCheckShouldEnableMarqueeId = nil
  end
end

function UMG_RolePlayItem_C:DoDelayCheckShouldEnableMarquee()
  self.delayCheckShouldEnableMarqueeId = nil
  if not self.isShow then
    return
  end
  local origNameForMarquee = self.origNameForMarquee
  if not origNameForMarquee then
    return
  end
  self.bShouldEnableMarquee = self:CalculateTextWidth(self.Name, origNameForMarquee)
end

function UMG_RolePlayItem_C:UpdateBehaviorConfItem()
  local conf = _G.DataConfigManager:GetRoleplayBehaviorConf(self.data and self.data.value or 0)
  if conf then
    self:SetName(conf.name_text)
    local rolePlayType = self.data and self.data.type
    if rolePlayType == RolePlayModuleDef.RolePlayType.Action then
      self.Action:SetPath(conf.icon_path)
    elseif rolePlayType == RolePlayModuleDef.RolePlayType.Sound then
      self.SoundIcon:SetPath(conf.icon_path)
    elseif rolePlayType == RolePlayModuleDef.RolePlayType.Interactive then
      local petData = self.data.customData
      if petData then
        self.Icon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
        self:SetName(petData.name)
      else
        self.Icon:SetIconPath(conf.icon_path)
      end
    end
    local star = self.data.star
    if star then
      self.CanvasPanel_ActionClip:SetClipping(UE.EWidgetClipping.ClipToBounds)
      self.NRCImage_starbg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if not star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif 1 == star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif 2 == star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_RolePlayItem_C:UpdateWardrobeConfItem()
  if self.data.suitType == "allCollect" then
    self:SetName(self.data.name)
    self.Skin:SetPath(self.data.iconPath)
    if self.data.tokenTime then
      self.RedDot:SetupKey(240, {
        self.data.suitID,
        self.data.tokenTime
      })
    end
    return
  end
  local wardrobeConf = self.data and self.data.value
  if wardrobeConf then
    local fashionItems = wardrobeConf.wearing_item
    local iconPath = AppearanceUtils.GetWardrobeIconPath(fashionItems)
    local isGlassItem, glassInfo = AppearanceUtils.GetWardrobeGlassInfo(fashionItems)
    local name = self.data.value.name
    if "" == name then
      name = LuaText.umg_appearance_suititem_1 .. self.data.wardrobeIndex
    end
    self:SetName(name)
    self.Skin:SetPath(iconPath or "")
    self.Dazzling:UpdateState(isGlassItem, glassInfo)
  end
end

function UMG_RolePlayItem_C:UpdatePropConfItem()
  local propId = self.data and self.data.value or 0
  local conf = _G.DataConfigManager:GetRoleplayPropConf(propId)
  if conf then
    self:SetName(conf.name_text)
    self.FurnitureIcon:SetPath(conf.icon_path)
    local nextPlaceTime = self.data.customData.nextCanPlacePropsTime
    local curTime = _G.ZoneServer:GetServerTime() / 1000
    local countdownTime = nextPlaceTime - curTime
    if countdownTime > 0 and countdownTime < 1000 then
      self:ClearCountdownTime()
      self.CountDownText:SetText(math.floor(countdownTime))
      self._timer = _G.TimerManager:CreateTimer(self, "UMG_RolePlayItem_C:UpdatePropConfItem" .. self.index, countdownTime, self.OnTimeUpdate, self.OnCountdownOver, 1)
      self.CountDown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Time_ten_in)
    else
      self.CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local bBanned = _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.IsRolePlayPropBanned, propId)
  bBanned = bBanned or _G.NRCModuleManager:DoCmd(_G.AreaAndZoneModuleCmd.CheckRolePlayPropsIsBan, propId)
  self:UpdatePropBanState(bBanned)
end

function UMG_RolePlayItem_C:ClearCountdownTime()
  if self._timer then
    _G.TimerManager:RemoveTimer(self._timer)
    self._timer = nil
  end
end

function UMG_RolePlayItem_C:OnTimeUpdate()
  local nextPlaceTime = self.data.customData.nextCanPlacePropsTime
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  local countdownTime = nextPlaceTime - curTime
  if countdownTime >= 0 then
    self.CountDownText:SetText(math.floor(countdownTime))
  end
end

function UMG_RolePlayItem_C:OnCountdownOver()
  self:ClearCountdownTime()
  self:PlayAnimation(self.Time_ten_out)
end

function UMG_RolePlayItem_C:SelectBehaviorConfItem()
  local data = self.data
  if not data then
    return
  end
  local executeParam = {}
  executeParam.type = data.type
  executeParam.id = data.value
  executeParam.statusParams = {}
  executeParam.statusParams.role_play_param = {}
  executeParam.statusParams.role_play_param.role_play_id = executeParam.id
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ExecuteRolePlay, executeParam)
end

function UMG_RolePlayItem_C:CanTriggerLongPress()
  return self.data and self.data.type == RolePlayModuleDef.RolePlayType.Action and self.data.star
end

function UMG_RolePlayItem_C:OnLongPressStartEvent(bSelected)
  _G.NRCModuleManager:GetModule("RolePlayModule"):DispatchEvent(RolePlayModuleEvent.OnPreBeginPopupPoseSelectPanel, bSelected)
end

function UMG_RolePlayItem_C:OnLongPressEvent()
  _G.NRCModuleManager:GetModule("RolePlayModule"):DispatchEvent(RolePlayModuleEvent.OnBeginPopupPoseSelectPanel, self.data, self.index)
end

function UMG_RolePlayItem_C:OnLongPressEndEvent()
  _G.NRCModuleManager:GetModule("RolePlayModule"):DispatchEvent(RolePlayModuleEvent.OnEndPopupPoseSelectPanel)
end

function UMG_RolePlayItem_C:SelectWardrobeConfItem()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_RolePlayItem_C:SelectWardrobeConfItem")
  if self.data.suitType == "allCollect" then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnWardrobeIndexChanged, nil, true, true, self.data.value.fashion_wear_id, self.data.suitID)
  else
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnWardrobeIndexChanged, self.data.wardrobeIndex, true)
  end
end

function UMG_RolePlayItem_C:SelectInteractiveConfItem()
  local itemConf = self.data
  if not itemConf or not itemConf.value then
    return
  end
  local petData = itemConf.customData
  if not petData or not petData.base_conf_id then
    return
  end
  local executeParam = {}
  executeParam.type = itemConf.type
  executeParam.id = itemConf.value
  executeParam.statusParams = {}
  executeParam.statusParams.role_play_param = {}
  executeParam.statusParams.role_play_param.role_play_id = executeParam.id
  executeParam.statusParams.role_play_param.pet_id = petData.base_conf_id
  executeParam.statusParams.role_play_param.mutation_type = petData.mutation_type
  executeParam.statusParams.role_play_param.nature = petData.nature
  executeParam.statusParams.role_play_param.glass_info = petData.glass_info
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ExecuteRolePlay, executeParam)
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.CloseMainPanel)
end

function UMG_RolePlayItem_C:SelectFurnitureConfItem()
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  if not self.nextTriggerPropTime then
    self.nextTriggerPropTime = 0
  end
  if curTime < self.nextTriggerPropTime then
    return
  end
  self.nextTriggerPropTime = curTime + 0.3
  local nextPlaceTime = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetNextPutPropTime)
  if curTime < nextPlaceTime then
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ShowPlaceFrequentlyTips)
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local npcId = self.data and self.data.value or 0
  local curPutPropId = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetCurPutPropNpcId)
  if curPutPropId > 0 then
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.SetInRecycleNpcId, curPutPropId)
    if Player and Player.playerToyComponent then
      Player.playerToyComponent:RecycleRolePlayProp(curPutPropId, _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN))
    end
    return
  end
  if self.data.disabled then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_ban)
    return
  end
  local propPlaceMode = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetPropPlaceMode)
  if 1 == propPlaceMode then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenPropPlacementPanel, self.data.value or 0)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.CloseMainPanel)
  else
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.RefreshNextPutPropTime, curTime)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.SetInPutPropNpcId, npcId)
    if Player and Player.playerToyComponent then
      Player.playerToyComponent:CreateRolePlayProp(npcId)
    end
  end
end

function UMG_RolePlayItem_C:OnAnimationFinished(anim)
  if self.data.bSelected then
    if anim == self.Selected_in then
      self:StartPlayLoopAnim()
    elseif anim == self.Refresh then
      self:StartPlayLoopAnim()
    end
  end
  if anim == self.Time_ten_in or anim == self.Time_ten_loop then
    if self._timer then
      self:PlayAnimation(self.Time_ten_loop)
    end
  elseif anim == self.Time_ten_out then
    self.CountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RolePlayItem_C:StartPlayLoopAnim()
  if self and UE4.UObject.IsValid(self) then
    self:PlayAnimation(self.Selected_loop, 0, 0)
  end
end

function UMG_RolePlayItem_C:CheckEraseRedPoint()
  if self.data.suitType == "allCollect" and self.RedDot and self.RedDot:IsRed() then
    self.RedDot:EraseRedPoint(true)
  end
end

function UMG_RolePlayItem_C:IgnoreNextSelectEvent()
  self.bIgnoreSelect = true
end

function UMG_RolePlayItem_C:OnRolePlayPropsBanStateChanged(id, bBanned)
  local data = self.data
  if not data then
    return
  end
  if data.type ~= RolePlayModuleDef.RolePlayType.PutProp then
    return
  end
  local propId = data.value
  if propId ~= id then
    return
  end
  Log.Debug("UMG_RolePlayItem_C:OnRolePlayPropsBanStateChanged", propId, bBanned)
  self:UpdatePropBanState(bBanned)
end

function UMG_RolePlayItem_C:UpdatePropBanState(bBanned)
  local npcId = self.data and self.data.value or 0
  local curPutPropId = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetCurPutPropNpcId)
  if bBanned and npcId ~= curPutPropId then
    self.CanvasForbid:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasForbid:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.data.disabled = bBanned
end

return UMG_RolePlayItem_C
