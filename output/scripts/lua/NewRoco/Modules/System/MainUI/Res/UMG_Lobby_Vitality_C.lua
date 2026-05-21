require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local HelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local UMG_Lobby_Vitality_C = _G.NRCViewBase:Extend("UMG_Lobby_Vitality_C")
local LocalEnum = Enum
local LocalUE4Helper = UE4Helper
local DelayHideTime = 1
UMG_Lobby_Vitality_C.LayerColorEnum = {
  RED = 0,
  YELLOW = 1,
  GREEN = 2,
  BLUE = 3
}
local bitOffset = -1

local function GetBitOffset()
  bitOffset = bitOffset + 1
  return 1 << bitOffset
end

local PerformFlag = {}
PerformFlag.VisibleBaseCircle = {}
PerformFlag.VisibleBaseCircle[1] = GetBitOffset()
PerformFlag.VisibleBaseCircle[2] = GetBitOffset()
PerformFlag.VisibleBaseCircle[3] = GetBitOffset()
PerformFlag.VisibleBaseCircle[4] = GetBitOffset()
PerformFlag.VisibleChargingCircle = {}
PerformFlag.VisibleChargingCircle[1] = GetBitOffset()
PerformFlag.VisibleChargingCircle[2] = GetBitOffset()
PerformFlag.VisibleChargingCircle[3] = GetBitOffset()
PerformFlag.VisibleChargingCircle[4] = GetBitOffset()
PerformFlag.VisiblePreviewCircle = {}
PerformFlag.VisiblePreviewCircle[1] = GetBitOffset()
PerformFlag.VisiblePreviewCircle[2] = GetBitOffset()
PerformFlag.VisiblePreviewCircle[3] = GetBitOffset()
PerformFlag.VisiblePreviewCircle[4] = GetBitOffset()
PerformFlag.VitalityBuffActive = GetBitOffset()
PerformFlag.VitalityBuffWorking = GetBitOffset()
bitOffset = nil
GetBitOffset = nil
local InternalDesiredVisibleReason = {}
InternalDesiredVisibleReason.TopPriority = 10
InternalDesiredVisibleReason.HideFlag = 6
InternalDesiredVisibleReason.Throwing = 4
InternalDesiredVisibleReason.SocietyBuff = 3
InternalDesiredVisibleReason.Default = 1

function UMG_Lobby_Vitality_C:Initialize(Initializer)
  self._LastShowTime = 0
  self:SetCurPercent(1, true)
  self.DesiredVisibleFlag = {}
end

function UMG_Lobby_Vitality_C:OnConstruct()
  self.ConstructComplete = false
  self.FlagStorage = 0
  local curVitality, maxVitality, curConfig, curPetBaseId = self:GetCurAbilityVitality()
  self._lastFrameVitality = maxVitality
  self._LastVitalityConfig = 0
  self.CircleFillImage_0 = self.CircleFillImage_1
  self.statIcon = self.statIcon_1
  self.DpiScaleY = 1
  self.bFullAnimPlayed = false
  self:SetDesiredVisible(false, InternalDesiredVisibleReason.Default)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_OnDashAbilityVitalityDeficiency, self.OnDashAbilityVitalityDeficiency)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_OnSetVitalityShow, self.OnSetVitalityShow)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_OnSetVitalityHideFlag, self.OnSetVitalityHideFlag)
  self.module:RegisterEvent(self, MainUIModuleEvent.SetUiAlpha, self.ChangBG)
  _G.NRCEventCenter:RegisterEvent("UMG_Lobby_Vitality_C", self, _G.SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  self:UpdateVisibility(UE4.ESlateVisibility.Collapsed)
  self:InitCircleGroup()
  self:ReBindPlayer()
  self.ConstructComplete = true
end

function UMG_Lobby_Vitality_C:OnDestruct()
  if self.module then
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_OnDashAbilityVitalityDeficiency)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_OnSetVitalityShow)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_OnSetVitalityHideFlag)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.SetUiAlpha)
  else
    Log.Error("UMG_Lobby_Vitality_C:OnDestruct There is no Module!!!")
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
end

function UMG_Lobby_Vitality_C:ReBindPlayer()
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_INIT, self.StartPreview) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_INIT, self.StartPreview)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_BEGIN, self.StartReducingPreviewVitality) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_BEGIN, self.StartReducingPreviewVitality)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_END, self.StopPreview) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PRE_VITALITY_COST_END, self.StopPreview)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_COST, self.ChargeCost) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_COST, self.ChargeCost)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_BEGIN, self.StartCharging) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_BEGIN, self.StartCharging)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_FULL, self.ChargeFull) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_FULL, self.ChargeFull)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_END, self.ChargeEnd) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_CHARGE_VITALITY_END, self.ChargeEnd)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_VITALITY_BUFF_UPDATE, self.OnVitalityBuffUpdate) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_VITALITY_BUFF_UPDATE, self.OnVitalityBuffUpdate)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, self.OnVitalityBuffRangeStateUpdate) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, self.OnVitalityBuffRangeStateUpdate)
    end
    if not localPlayer:HasListener(self, PlayerModuleEvent.ON_VITALITY_SHAKE, self.OnVitalityShake) then
      localPlayer:AddEventListener(self, PlayerModuleEvent.ON_VITALITY_SHAKE, self.OnVitalityShake)
    end
    local bHasRecoverBuff = localPlayer.buffComponent and not not localPlayer.buffComponent:HasBuff("VitalityRecoverBuff")
    local bRecoverBuffPerformingNow = not not self:GetFlag(PerformFlag.VitalityBuffActive)
    if bHasRecoverBuff ~= bRecoverBuffPerformingNow then
      if bHasRecoverBuff then
        self:OnVitalityBuffUpdate(true)
      else
        self:OnVitalityBuffUpdate(false)
      end
    end
  else
    Log.Error("There is no LocalPlayer!!!")
  end
end

function UMG_Lobby_Vitality_C:OnTick(InDeltaTime)
  if not self.ConstructComplete then
    return
  end
  local curVitality, maxVitality, curConfig, curPetBaseId, bHadCostVitality, serverVitality, serverMaxVitality = self:GetCurAbilityVitality()
  local curTime = LocalUE4Helper.GetTime()
  local changeImmediately = false
  if self._LastVitalityConfig ~= curConfig then
    changeImmediately = true
    if curVitality == maxVitality then
      self:SetDesiredVisible(false, InternalDesiredVisibleReason.Default, true)
    end
  end
  if self._lastFramePercent ~= nil and curVitality > self._lastFrameVitality and curVitality == maxVitality and self.bFullAnimPlayed == false then
    self:PlayAnimation(self.Full)
  end
  if self._isShow and curTime - self._LastShowTime > DelayHideTime and curVitality == maxVitality then
    self:SetDesiredVisible(false, InternalDesiredVisibleReason.Default, true)
  elseif not self._isShow and curVitality < maxVitality then
    self:SetDesiredVisible(true, InternalDesiredVisibleReason.Default, true)
  end
  local percent = 1.0 * curVitality / maxVitality
  if percent < 0 then
    percent = 0
  end
  if percent > 1 then
    percent = 1
  end
  self:SetCurPercent(percent, changeImmediately)
  if self._curPercent ~= self._curTargetPercent then
    self._curPercent = LuaMathUtils.LerpWithMin(self._curPercent, self._curTargetPercent, 1, InDeltaTime)
  end
  local bHideForThrowing = false
  if self._lastFramePercent ~= nil and self._lastFramePercent ~= self._curPercent and curVitality ~= maxVitality or self:IsDesiredReasonWorking(InternalDesiredVisibleReason.SocietyBuff) then
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.statusComponent and not localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
      self:SetDesiredVisible(true, InternalDesiredVisibleReason.Default, true)
      if not self:IsDesiredReasonWorking(InternalDesiredVisibleReason.SocietyBuff) then
        self._LastShowTime = LocalUE4Helper.GetTime()
      end
    end
    if localPlayer and localPlayer.statusComponent and localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
      local abilityHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
      if abilityHelper and abilityHelper:GetThrowStat(localPlayer) == Enum.SceneThrowAbilityType.STAT_NORMAL then
        bHideForThrowing = true
        self:SetDesiredVisible(false, InternalDesiredVisibleReason.Throwing, true)
      end
    end
  end
  if not bHideForThrowing then
    self:SetDesiredVisible(nil, InternalDesiredVisibleReason.Throwing, true)
  end
  self._lastFrameVitality = curVitality
  self._lastFramePercent = self._curPercent
  self._LastVitalityConfig = curConfig
  self:UpdateSlotPosition()
  if GlobalConfig.ShowVitalityValue then
    self.VitalityValue:SetText(string.format("%d/%d,%d/%d", math.ceil(curVitality), math.ceil(maxVitality), math.ceil(serverVitality), math.ceil(serverMaxVitality)))
  end
  local circleData = self:CalcVitalityCircleData(InDeltaTime)
  local baseColorGrade1, baseColorGrade2 = self:DrawBaseCircle(circleData[1], circleData[2])
  local bTurnRed = 1 == baseColorGrade1 and 1 == baseColorGrade2
  self:DrawChargingCircle(circleData[3], circleData[4], bTurnRed)
  self:DrawPreviewCircle(circleData[5], circleData[6], bTurnRed)
  local bVitalityBuffWorking = false
  if self:GetFlag(PerformFlag.VitalityBuffActive) then
    if curVitality == maxVitality then
      bVitalityBuffWorking = bHadCostVitality
    else
      bVitalityBuffWorking = true
    end
  end
  if self:GetFlag(PerformFlag.VitalityBuffWorking) ~= bVitalityBuffWorking then
    if bVitalityBuffWorking then
      self:SetFlag(PerformFlag.VitalityBuffWorking)
      if not self:IsAnimationPlaying(self.Jiantou_In) and not self:IsAnimationPlaying(self.Jiantou_Out) then
        self.CanvasPanel_80:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.Jiantou_In)
      end
      if not self:IsAnimationPlaying(self.Jiantou_Loop) then
        self:PlayAnimation(self.Jiantou_Loop)
      end
    else
      self:ClearFlag(PerformFlag.VitalityBuffWorking)
      if not self:IsAnimationPlaying(self.Jiantou_In) and not self:IsAnimationPlaying(self.Jiantou_Out) then
        self:PlayAnimation(self.Jiantou_Out)
      end
    end
  end
end

local UpdateSlotPositionTempVector2D = UE4.FVector2D(0, 0)
local UpdateSlotPositionScreenPosCache = UE4.FVector2D(0, 0)
local UpdateSlotPositionViewportPosCache = UE4.FVector2D(0, 0)
local UpdateSlotPositionCameraRightVectorCache = UE4.FVector(0, 0, 0)
local UpdateSlotPositionCameraUpVectorCache = UE4.FVector(0, 0, 0)
local UpdateSlotPositionCameraForwardVectorCache = UE4.FVector(0, 0, 0)

function UMG_Lobby_Vitality_C:UpdateSlotPosition()
  if not self._isShow then
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  if not player.viewObj then
    return
  end
  local playerMesh = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  local offset = player.viewObj.Vitalityicon_Offset
  if self:IsPCMode() then
    offset.X = offset.X * 0.88
    offset.Y = offset.Y * 0.88
    offset.Z = offset.Z * 0.88
  end
  local cameraManager = player:GetUEController().playerCameraManager
  local playerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  local headLocation = playerMesh:Abs_GetSocketLocation("Root")
  local ScreenPos = UpdateSlotPositionScreenPosCache
  local CameraRotation = cameraManager:GetCameraRotation()
  UE4.UNRCStatics.GetRightVectorFromRotationInplace(CameraRotation, UpdateSlotPositionCameraRightVectorCache)
  UE4.UNRCStatics.GetUpVectorFromRotationInplace(CameraRotation, UpdateSlotPositionCameraUpVectorCache)
  UE4.UNRCStatics.GetForwardVectorFromRotationInplace(CameraRotation, UpdateSlotPositionCameraForwardVectorCache)
  local CameraRightVector = UpdateSlotPositionCameraRightVectorCache
  local CameraUpVector = UpdateSlotPositionCameraUpVectorCache
  local CameraForwardVector = UpdateSlotPositionCameraForwardVectorCache
  CameraRightVector:Mul(offset.X)
  CameraUpVector:Mul(offset.Y)
  CameraForwardVector:Mul(offset.Z)
  headLocation:Add(CameraRightVector)
  headLocation:Add(CameraUpVector)
  headLocation:Add(CameraForwardVector)
  local headPosition = headLocation
  UE4.UGameplayStatics.Abs_ProjectWorldToScreen(playerController, headPosition, ScreenPos)
  local ViewportPos = UpdateSlotPositionViewportPosCache
  UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), ScreenPos, ViewportPos)
  local x = math.clamp(ViewportPos.X, 312, 1248)
  local y = math.clamp(ViewportPos.Y, 120, 600)
  UpdateSlotPositionTempVector2D:Set(x * self.DpiScaleY, y * self.DpiScaleY)
  if self.Slot and UE.UObject.IsValid(self.Slot) then
    self.Slot:SetPosition(UpdateSlotPositionTempVector2D)
  end
end

function UMG_Lobby_Vitality_C:OnDashAbilityVitalityDeficiency()
  self:PlayAnimation(self.Not)
end

function UMG_Lobby_Vitality_C:SetCurPercent(Percent, immediately)
  self._curTargetPercent = Percent
  if immediately then
    self._curPercent = Percent
  end
end

function UMG_Lobby_Vitality_C:OnSetVitalityShow(IsShow)
  self:SetDesiredVisible(IsShow, InternalDesiredVisibleReason.Default)
end

function UMG_Lobby_Vitality_C:OnSetVitalityHideFlag(bHide)
  if bHide then
    self:SetDesiredVisible(not bHide, InternalDesiredVisibleReason.HideFlag)
  else
    self:SetDesiredVisible(nil, InternalDesiredVisibleReason.HideFlag)
  end
end

function UMG_Lobby_Vitality_C:SetShowHide(IsShow)
  if self._isShow == IsShow then
    return self._isShow
  end
  self._isShow = IsShow
  if IsShow then
    local curVitality, maxVitality, curConfig, curPetBaseId = self:GetCurAbilityVitality()
    self.RootCanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:UpdateVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.bFullAnimPlayed = false
    if GlobalConfig.ShowVitalityValue then
      self.VitalityValue:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.VitalityValue:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  else
    self.RootCanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:UpdateVisibility(UE4.ESlateVisibility.Collapsed)
    self:StopAnimation(self.Jiantou_Loop)
  end
  return self._isShow
end

function UMG_Lobby_Vitality_C:GetCurAbilityVitality()
  local RetCurVitality = 1
  local RetMaxVitality = 1
  local config = 0
  local petbaseId = -1
  local bHadCostVitality = false
  local serverVitality = 0
  local serverMaxVitality = 0
  local LocalPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if LocalPlayer and LocalPlayer.vitalityComponent then
    local vitalityComponent = LocalPlayer.vitalityComponent
    RetCurVitality = vitalityComponent:GetCurVitality()
    RetMaxVitality = vitalityComponent:GetMaxVitality()
    config = vitalityComponent:GetConfig().id
    bHadCostVitality = vitalityComponent:HasCostVitality()
    serverVitality, serverMaxVitality = vitalityComponent:GetServerVitality()
  end
  if RetCurVitality > RetMaxVitality then
    RetCurVitality = RetMaxVitality
  end
  return RetCurVitality, RetMaxVitality, config, petbaseId, bHadCostVitality, serverVitality, serverMaxVitality
end

function UMG_Lobby_Vitality_C:ChangBG()
  self.Image_2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.statIcon_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.statIcon_2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.CircleFillImage_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.CircleFillImage_2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self:StopAllAnimations()
end

function UMG_Lobby_Vitality_C:OnAnimationFinished(anim)
  if anim == self.Full then
    self.bFullAnimPlayed = false
  elseif self.Xuli_out == anim then
    self.ChargingAmount = 0
    self.Charging = false
  elseif self.Disappear == anim then
    if not self:GetFlag(PerformFlag.VitalityBuffActive) then
      self:SetDesiredVisible(nil, InternalDesiredVisibleReason.SocietyBuff)
      self.StickIOn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.Jiantou_Loop == anim then
    if self:GetFlag(PerformFlag.VitalityBuffWorking) then
      self:PlayAnimation(self.Jiantou_Loop)
    end
  elseif self.Jiantou_In == anim then
    if not self:GetFlag(PerformFlag.VitalityBuffWorking) then
      self:PlayAnimation(self.Jiantou_Out)
    end
  elseif self.Jiantou_Out == anim then
    if self:GetFlag(PerformFlag.VitalityBuffWorking) then
      self:PlayAnimation(self.Jiantou_In)
    else
      self.CanvasPanel_80:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

local MAX_VITALITY = 3600
local MIN_VITALITY = 0
local circleDataCache = {
  0,
  0,
  0,
  0,
  0,
  0
}

function UMG_Lobby_Vitality_C:CalcVitalityCircleData(InDeltaTime)
  local curVitality, maxVitality, curConfig, curPetBaseId = self:GetCurAbilityVitality()
  local previewAmount = self.PreviewAmount or 0
  if previewAmount > 0 and self.bReducingPreview then
    if self.PreviewReduceDuration > 0 then
      previewAmount = previewAmount * (self.PreviewReduceDuration - InDeltaTime) / self.PreviewReduceDuration
      self.PreviewAmount = previewAmount
      self.PreviewReduceDuration = self.PreviewReduceDuration - InDeltaTime
    else
      self.PreviewAmount = 0
      self.PreviewReduceDuration = 0
      self.bReducingPreview = false
    end
  end
  local previewCircleValue1 = curVitality
  local previewCircleValue2 = curVitality + previewAmount
  if maxVitality < previewCircleValue2 then
    previewCircleValue2 = maxVitality
    previewCircleValue1 = maxVitality - previewAmount
  end
  local baseCircleValue1 = 0
  local baseCircleValue2 = curVitality
  local chargingCircleValue1 = 0
  local chargingCircleValue2 = 0
  if self.Charging then
    local chargingAmount = self.ChargingAmount or 0
    chargingCircleValue1 = curVitality
    chargingCircleValue2 = curVitality + chargingAmount
    if maxVitality < chargingCircleValue2 then
      chargingCircleValue2 = maxVitality
      chargingCircleValue1 = maxVitality - chargingAmount
    end
  end
  local circleData = circleDataCache
  circleDataCache[1] = baseCircleValue1
  circleDataCache[2] = baseCircleValue2
  circleDataCache[3] = chargingCircleValue1
  circleDataCache[4] = chargingCircleValue2
  circleDataCache[5] = previewCircleValue1
  circleDataCache[6] = previewCircleValue2
  for idx, value in ipairs(circleData) do
    circleData[idx] = math.clamp(value, MIN_VITALITY, maxVitality)
  end
  return circleData
end

local bornVitalityMax = _G.DataConfigManager:GetRoleGlobalConfig("born_power_max").num
local vitalityPerCircle = _G.DataConfigManager:GetRoleGlobalConfig("born_power_increase_peer_max").num
local vitalityColorGrade = {
  0,
  200,
  bornVitalityMax,
  bornVitalityMax + vitalityPerCircle,
  bornVitalityMax + vitalityPerCircle * 2
}
local vitalityCircleLevel = {
  0,
  bornVitalityMax,
  bornVitalityMax + vitalityPerCircle,
  bornVitalityMax + vitalityPerCircle * 2
}

function UMG_Lobby_Vitality_C:DrawBaseCircle(value1, value2)
  if value2 <= value1 then
    self:UpdateCircleVisibility(self.BaseCircleImage, PerformFlag.VisibleBaseCircle)
  else
    local colorGrade1 = self:GetColorGrade(value1)
    local colorGrade2 = self:GetColorGrade(value2)
    if nil == colorGrade1 or nil == colorGrade2 then
      return
    end
    local percent1 = self:CalcCirclePercent(value1)
    local percent2 = self:CalcCirclePercent(value2)
    if colorGrade1 == colorGrade2 then
      local circleImage = self.BaseCircleImage[colorGrade1]
      if circleImage then
        circleImage:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage:SetFillAmount(percent2 - percent1)
      end
    else
      local circleImage1 = self.BaseCircleImage[colorGrade1]
      if circleImage1 then
        circleImage1:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage1:SetFillAmount(self:CalcCirclePercent(vitalityColorGrade[colorGrade1 + 1]) - percent1)
      end
      local circleImage2 = self.BaseCircleImage[colorGrade2]
      if circleImage2 then
        circleImage2:SetFillStartPercent(self:CalcStartFillPercent(0))
        circleImage2:SetFillAmount(percent2)
      end
      if colorGrade2 - colorGrade1 > 1 then
        for middleColorGrade = colorGrade1 + 1, colorGrade2 - 1 do
          local circleImage = self.BaseCircleImage[middleColorGrade]
          if circleImage then
            circleImage:SetFillStartPercent(self:CalcStartFillPercent(0))
            circleImage:SetFillAmount(self:CalcCirclePercent(vitalityColorGrade[middleColorGrade + 1]))
          end
        end
      end
    end
    self:UpdateCircleVisibility(self.BaseCircleImage, PerformFlag.VisibleBaseCircle, colorGrade1, colorGrade2)
    return colorGrade1, colorGrade2
  end
end

function UMG_Lobby_Vitality_C:DrawChargingCircle(value1, value2, bTurnRed)
  if value2 <= value1 then
    self:UpdateCircleVisibility(self.ChargingCircleImage, PerformFlag.VisibleChargingCircle)
  else
    if value2 - value1 > vitalityPerCircle then
      Log.Error("\230\132\143\230\150\153\228\185\139\229\164\150\231\154\132\230\131\133\229\134\181\239\188\140\230\140\137\233\129\147\231\144\134\231\137\185\230\174\138\232\137\178\231\142\175\228\184\141\229\186\148\232\175\165\229\135\186\231\142\176\232\137\178\231\142\175\232\140\131\229\155\180\232\182\133\232\191\135\229\141\149\228\184\170\231\142\175\231\154\132\230\128\187\230\149\176\229\128\1881200", value1, value2)
      value2 = value1 + vitalityPerCircle
    end
    local colorGrade1 = self:GetColorGrade(value1)
    local colorGrade2 = self:GetColorGrade(value2)
    if nil == colorGrade1 or nil == colorGrade2 then
      return
    end
    if bTurnRed then
      colorGrade1 = 1
      colorGrade2 = 1
    end
    local percent1 = self:CalcCirclePercent(value1)
    local percent2 = self:CalcCirclePercent(value2)
    if colorGrade1 == colorGrade2 then
      local circleImage = self.ChargingCircleImage[colorGrade1]
      if circleImage then
        circleImage:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage:SetFillAmount(percent2 - percent1)
      end
    else
      local circleImage1 = self.ChargingCircleImage[colorGrade1]
      if circleImage1 then
        circleImage1:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage1:SetFillAmount(self:CalcCirclePercent(vitalityColorGrade[colorGrade1 + 1]) - percent1)
      end
      local circleImage2 = self.ChargingCircleImage[colorGrade2]
      if circleImage2 then
        circleImage2:SetFillStartPercent(self:CalcStartFillPercent(0))
        circleImage2:SetFillAmount(percent2)
      end
    end
    self:UpdateCircleVisibility(self.ChargingCircleImage, PerformFlag.VisibleChargingCircle, colorGrade1, colorGrade2)
  end
end

function UMG_Lobby_Vitality_C:DrawPreviewCircle(value1, value2, bTurnRed)
  if value2 <= value1 then
    self:UpdateCircleVisibility(self.PreviewCircleImage, PerformFlag.VisiblePreviewCircle)
  else
    if value2 - value1 > vitalityPerCircle then
      Log.Error("\230\132\143\230\150\153\228\185\139\229\164\150\231\154\132\230\131\133\229\134\181\239\188\140\230\140\137\233\129\147\231\144\134\231\137\185\230\174\138\232\137\178\231\142\175\228\184\141\229\186\148\232\175\165\229\135\186\231\142\176\232\137\178\231\142\175\232\140\131\229\155\180\232\182\133\232\191\135\229\141\149\228\184\170\231\142\175\231\154\132\230\128\187\230\149\176\229\128\1881200", value1, value2)
      value2 = value1 + vitalityPerCircle
    end
    local colorGrade1 = self:GetColorGrade(value1)
    local colorGrade2 = self:GetColorGrade(value2)
    if nil == colorGrade1 or nil == colorGrade2 then
      return
    end
    if bTurnRed then
      colorGrade1 = 1
      colorGrade2 = 1
    end
    local percent1 = self:CalcCirclePercent(value1)
    local percent2 = self:CalcCirclePercent(value2)
    if colorGrade1 == colorGrade2 then
      local circleImage = self.PreviewCircleImage[colorGrade1]
      if circleImage then
        circleImage:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage:SetFillAmount(percent2 - percent1)
      end
    else
      local circleImage1 = self.PreviewCircleImage[colorGrade1]
      if circleImage1 then
        circleImage1:SetFillStartPercent(self:CalcStartFillPercent(percent1))
        circleImage1:SetFillAmount(self:CalcCirclePercent(vitalityColorGrade[colorGrade1 + 1]) - percent1)
      end
      local circleImage2 = self.PreviewCircleImage[colorGrade2]
      if circleImage2 then
        circleImage2:SetFillStartPercent(self:CalcStartFillPercent(0))
        circleImage2:SetFillAmount(percent2)
      end
    end
    self:UpdateCircleVisibility(self.PreviewCircleImage, PerformFlag.VisiblePreviewCircle, colorGrade1, colorGrade2)
  end
end

function UMG_Lobby_Vitality_C:StartPreview(previewAmount, reduceDuration)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.PreviewAmount = previewAmount or 0
  self.PreviewReduceDuration = reduceDuration or 0
end

function UMG_Lobby_Vitality_C:StopPreview()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.PreviewAmount = 0
  self.PreviewReduceDuration = 0
  self.bReducingPreview = false
end

function UMG_Lobby_Vitality_C:StartReducingPreviewVitality()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.bReducingPreview = true
end

function UMG_Lobby_Vitality_C:GetColorGrade(vitalityValue)
  local colorGrade
  if 0 == vitalityValue then
    return 1
  end
  for idx, colorGradeBoundary in ipairs(vitalityColorGrade) do
    if colorGradeBoundary < vitalityValue then
      colorGrade = idx
    else
      return colorGrade
    end
  end
  Log.Error("\230\132\143\230\150\153\228\185\139\229\164\150\231\154\132\230\131\133\229\134\181\239\188\140\230\140\137\233\129\147\231\144\134\228\184\141\229\186\148\232\175\165\232\182\133\229\135\186\232\175\165\232\140\131\229\155\180[0, 3600]", vitalityValue)
  return nil
end

local ZeroPercent = -0.125
local MaxStartFillPercent = 4

function UMG_Lobby_Vitality_C:CalcStartFillPercent(percent)
  local startFillPercent = (percent - ZeroPercent) * MaxStartFillPercent
  if startFillPercent > MaxStartFillPercent then
    startFillPercent = startFillPercent - MaxStartFillPercent
  end
  return startFillPercent
end

function UMG_Lobby_Vitality_C:CalcCirclePercent(vitalityValue)
  local circleLevel = 1
  if 0 == vitalityValue then
    circleLevel = 1
  end
  for idx, colorGradeBoundary in ipairs(vitalityCircleLevel) do
    if colorGradeBoundary < vitalityValue then
      circleLevel = idx
    else
      break
    end
  end
  local rawPercent = (vitalityValue - vitalityCircleLevel[circleLevel]) / vitalityPerCircle
  
  local function linearInterpolation(x)
    local segments = {
      0.088,
      0.176,
      0.25,
      0.323,
      0.435,
      0.5,
      0.588,
      0.676,
      0.75,
      0.823,
      0.935,
      1
    }
    local originalSegments = {
      0.08333333333333333,
      0.16666666666666666,
      0.25,
      0.3333333333333333,
      0.4166666666666667,
      0.5,
      0.5833333333333334,
      0.6666666666666666,
      0.75,
      0.8333333333333334,
      0.9166666666666666,
      1.0
    }
    if x <= 0 then
      return 0
    end
    if x >= 1 then
      return 1
    end
    for i = 1, #originalSegments do
      if 1 == i then
        if x <= originalSegments[i] then
          return segments[i] * (x / originalSegments[i])
        end
      elseif x > originalSegments[i - 1] and x <= originalSegments[i] then
        local a = originalSegments[i - 1]
        local b = originalSegments[i]
        local c = segments[i - 1]
        local d = segments[i]
        return c + (x - a) * (d - c) / (b - a)
      end
    end
    return x
  end
  
  return linearInterpolation(rawPercent)
end

function UMG_Lobby_Vitality_C:InitCircleGroup()
  self.BaseCircleImage = {
    self.Red,
    self.Yellow,
    self.Green,
    self.Blue
  }
  self.ChargingCircleImage = {
    self.Red_light,
    self.Yellow_light,
    self.Green_light,
    self.Blue_light
  }
  self.PreviewCircleImage = {
    self.Red_Shadow,
    self.Yellow_Shadow,
    self.Green_Shadow,
    self.Blue_Shadow
  }
  self:UpdateCircleVisibility(self.BaseCircleImage, PerformFlag.VisibleBaseCircle, nil, nil, true)
  self:UpdateCircleVisibility(self.ChargingCircleImage, PerformFlag.VisibleChargingCircle, nil, nil, true)
  self:UpdateCircleVisibility(self.PreviewCircleImage, PerformFlag.VisiblePreviewCircle, nil, nil, true)
  self.ChargingAmount = 0
end

function UMG_Lobby_Vitality_C:UpdateCircleVisibility(circleGroup, visibleCircleFlag, colorGrade1, colorGrade2, bForce)
  if nil == visibleCircleFlag then
    return
  end
  if nil == colorGrade1 then
    colorGrade1 = math.maxinteger
  end
  if nil == colorGrade2 then
    colorGrade2 = math.maxinteger
  end
  for idx, circleImage in ipairs(circleGroup) do
    if idx >= colorGrade1 and idx <= colorGrade2 then
      self:SetCircleVisibility(visibleCircleFlag[idx], circleImage, true, bForce)
    else
      self:SetCircleVisibility(visibleCircleFlag[idx], circleImage, false, bForce)
    end
  end
end

function UMG_Lobby_Vitality_C:SetCircleVisibility(flag, circleImage, bVisible, bForce)
  if self:GetFlag(flag) ~= bVisible or bForce then
    if bVisible then
      circleImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:SetFlag(flag)
    else
      circleImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:ClearFlag(flag)
    end
  end
end

function UMG_Lobby_Vitality_C:RevertChargeEndAnim()
  self:StopAnimation(self.Xuli_full_shine)
  self:StopAnimation(self.Xuli_out)
  for idx, circleImage in ipairs(self.ChargingCircleImage) do
    if circleImage then
      local dynamicMaterial = circleImage:GetDynamicMaterial()
      if dynamicMaterial then
        dynamicMaterial:SetScalarParameterValue("DissExp", 0)
      end
    end
  end
end

function UMG_Lobby_Vitality_C:SetFlag(flag)
  self.FlagStorage = self.FlagStorage | flag
end

function UMG_Lobby_Vitality_C:ClearFlag(flag)
  self.FlagStorage = self.FlagStorage & ~flag
end

function UMG_Lobby_Vitality_C:GetFlag(flag)
  return 0 ~= self.FlagStorage & flag
end

function UMG_Lobby_Vitality_C:StartCharging()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:RevertChargeEndAnim()
  self.ChargingAmount = 0
  self.Charging = true
end

function UMG_Lobby_Vitality_C:ChargeCost(chargingAmount)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.ChargingAmount = self.ChargingAmount + chargingAmount
end

function UMG_Lobby_Vitality_C:ChargeFull()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:PlayAnimation(self.Xuli_full_shine, 0, 0)
end

function UMG_Lobby_Vitality_C:ChargeEnd(bSuccess)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if bSuccess then
    self:StopAnimation(self.Xuli_full_shine)
    self:PlayAnimation(self.Xuli_out)
  else
    self.Charging = false
  end
end

function UMG_Lobby_Vitality_C:OnSceneLoaded()
  self:ReBindPlayer()
end

function UMG_Lobby_Vitality_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Lobby_Vitality_C:UpdateVisibility(visibility)
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnLobbyMainChildVisibilityChange, self, visibility)
end

function UMG_Lobby_Vitality_C:SetDesiredVisible(bShow, reason, bDontDoActualUpdate)
  if not reason or not self.DesiredVisibleFlag then
    return
  end
  self.DesiredVisibleFlag[reason] = bShow
  self:UpdateFinalDesiredVisible()
end

function UMG_Lobby_Vitality_C:IsDesiredReasonWorking(internalDesiredReason)
  return self.DesiredVisibleFlag[internalDesiredReason] ~= nil
end

function UMG_Lobby_Vitality_C:UpdateFinalDesiredVisible()
  local candidateShow = 0
  for _reason, _bShow in pairs(self.DesiredVisibleFlag) do
    if _reason > math.abs(candidateShow) then
      if _bShow then
        candidateShow = _reason
      else
        candidateShow = -_reason
      end
    end
  end
  self:SetShowHide(candidateShow > 0)
end

function UMG_Lobby_Vitality_C:OnVitalityBuffUpdate(bBuffStart)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if bBuffStart then
    self:SetDesiredVisible(true, InternalDesiredVisibleReason.SocietyBuff)
    self:SetFlag(PerformFlag.VitalityBuffActive)
    self:StopAnimation(self.Disappear)
    self:PlayAnimation(self.In)
    _G.NRCAudioManager:PlaySound2DAuto(40120001, "UMG_Lobby_Vitality_C:OnVitalityBuffUpdate_true")
    self.StickIOn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:ClearFlag(PerformFlag.VitalityBuffActive)
    self:StopAnimation(self.In)
    self:StopAnimation(self.Flash)
    self:PlayAnimation(self.Disappear)
    _G.NRCAudioManager:PlaySound2DAuto(40120002, "UMG_Lobby_Vitality_C:OnVitalityBuffUpdate_false")
  end
end

function UMG_Lobby_Vitality_C:OnVitalityBuffRangeStateUpdate(bLeaveRange)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if bLeaveRange then
    self:PlayAnimation(self.Flash, 0, 999)
    _G.NRCAudioManager:PlaySound2DAuto(40120003, "UMG_Lobby_Vitality_C:OnVitalityBuffRangeStateUpdate")
  else
    self:StopAnimation(self.Flash)
  end
end

function UMG_Lobby_Vitality_C:OnVitalityShake(bShake)
  if bShake then
    self:PlayAnimation(self.Doudong, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, true)
  elseif self:IsAnimationPlaying(self.Doudong) then
    self:StopAnimation(self.Doudong)
  end
end

return UMG_Lobby_Vitality_C
