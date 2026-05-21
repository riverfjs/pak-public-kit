local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BP_BattlePetComponents_C = NRCClass:Extend("BP_BattlePetComponents_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")

function BP_BattlePetComponents_C:Initialize(Initializer)
  self:Reset()
  self.pet = Initializer and Initializer.pet
  self.buff_offset_z = 0
  self.botton_offset_z = 0
  local initState = {}
  initState.isDifferentColorsPet = false
  initState.isBuffShow = false
  self:SetState(initState)
end

function BP_BattlePetComponents_C:ReceiveBeginPlay()
  self.OperationIcon = self.Operation:GetUserWidgetObject().Icon
  self.CatchRateUIActor = self.CatchRate:GetUserWidgetObject()
  self.CatchRateUIActor:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ClickTipUIActor = self.ClickTipUI:GetUserWidgetObject()
  self.ClickTipUIActor:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPredictionUIActor = self.SkillPredictionUI:GetUserWidgetObject()
  self.SkillPredictionUIActor:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PopupUIFather = self.PopupUI:GetUserWidgetObject().PopUpFather
  self.PopupDamagePanel = self.PopupDamage:GetUserWidgetObject().PopUpFather
  self.CatchConsumeWidget = self.CatchConsumeUI:GetUserWidgetObject()
  self.PetEvolutionBubbleWidget = self.PetEvolutionBubbleUI:GetUserWidgetObject()
  self.CatchConsumeWidget:SetCatchTipTimeVisible(false)
  self.CatchConsumeWidget:ShowSelectSureKeyUI(false)
  self.CatchConsumeWidget:SetEffectVisible(false)
  self:HideCatchConsume(false)
  self:IsShowPetEvolutionBubbleUI(false)
  self.resonance_widget = self.ResonanceUI:GetUserWidgetObject()
  self.resonance_widget:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.DifferentColorsWidget = self.DifferentColorsUI:GetUserWidgetObject()
  local halfHeight = self.pet:GetHalfHeight()
  
  local function PutToBottom(target)
    local transform = target:GetRelativeTransform()
    local translation = transform.Translation
    translation.Z = translation.Z - halfHeight + 1
    transform.Translation = translation
    target:K2_SetRelativeTransform(transform, false, nil, false)
  end
  
  PutToBottom(self.SelectedOffset)
  PutToBottom(self.SelectMarkerOffset)
  self:InitBuff()
  self:ShowSelectMarker(false)
  self:ShowActiveState(false)
  self:ShowOperation(false)
  self:ShowSelectMarker3d(false)
  self.ClickTipUIOffset:K2_SetRelativeLocation(UE4.FVector(0, 0, 0), false, nil, false)
end

function BP_BattlePetComponents_C:InitBuff()
  self.BuffBoxWidget = self.BuffBox:GetUserWidgetObject()
  self.BuffBox2DWidget = self.BuffBox2D:GetUserWidgetObject()
  self:HideBuffs()
  self.BuffBoxWidget:BindPet(self.pet)
  self.BuffBox2DWidget:BindPet(self.pet)
  self:ShowBuffBoxMaterial()
end

function BP_BattlePetComponents_C:ShowBuffBoxMaterial()
  local battleType = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleType or 0
  local config = _G.DataConfigManager:GetBattleGlobalConfig("3dui_switch_on_battle_type")
  local isBattleType3d = false
  if config and config.numList then
    for _, id in pairs(config.numList) do
      if battleType == id then
        isBattleType3d = true
        break
      end
    end
  end
  self.is3dBuff = isBattleType3d
  self:UpdateCapsuleInfo()
  self.BuffBoxWidget = self.BuffBox:GetUserWidgetObject()
  self.BuffBox2DWidget = self.BuffBox2D:GetUserWidgetObject()
  if isBattleType3d then
    self:SetBuffBoxMaterial(true)
    self.BuffBoxWidget:SetShowType(_G.BattleConst.BuffIconShowType.WorldUI)
    self.BuffBox2DWidget:SetShowType(_G.BattleConst.BuffIconShowType.ScreenBtn)
  else
    self:SetBuffBoxMaterial(false)
    self.BuffBoxWidget:SetShowType(_G.BattleConst.BuffIconShowType.None)
    self.BuffBox2DWidget:SetShowType(_G.BattleConst.BuffIconShowType.ScreenBtnAndUI)
  end
end

function BP_BattlePetComponents_C:GetFootPos()
  local MeshComp = self.pet.model:GetComponentByClass(UE4.USkeletalMeshComponent)
  if MeshComp then
    local footPos = MeshComp:Abs_GetSocketLocation("locator_pos")
    return footPos
  else
    Log.Error("Pet has invalid mesh", self.pet.guid, "pet name = ", self.pet.card:GetName())
    return UE4.FVector(0, 0, 0)
  end
end

function BP_BattlePetComponents_C:GetRealHalfHeight()
  if self.pet.model then
    local centerPos = self.pet.model:Abs_K2_GetActorLocation()
    local footPos = self:GetFootPos()
    return math.abs(centerPos.Z - footPos.Z)
  else
    Log.Warning("Pet has invalid mode", self.pet.guid, "pet name = ", self.pet.card:GetName())
    return 0
  end
end

function BP_BattlePetComponents_C:GetSafeWidgetHeight()
  if self.pet.model then
    local centerPos = self.pet.model:Abs_K2_GetActorLocation()
    if self.pet.model.HeadWidget then
      return math.abs(centerPos.Z - self.pet.model.HeadWidget:K2_GetComponentLocation().Z)
    else
      local footPos = self:GetFootPos()
      return math.abs(centerPos.Z - footPos.Z)
    end
  end
  return 0
end

function BP_BattlePetComponents_C:UpdateCapsuleInfo()
  local radius = 50
  local areaRadius = 50
  local capsuleHalfHeight = 100
  if self.pet and self.pet.model then
    local CapsuleComponent = self.pet.model:GetComponentByClass(UE4.UCapsuleComponent)
    if CapsuleComponent then
      radius = CapsuleComponent:GetScaledCapsuleRadius()
      capsuleHalfHeight = CapsuleComponent:GetScaledCapsuleHalfHeight()
    end
    areaRadius = self:GetSafeWidgetHeight()
    if radius > areaRadius then
      areaRadius = radius
    elseif areaRadius > 2 * radius then
      areaRadius = 2 * radius
    end
  end
  local realRadius = radius
  local halfHeight = self:GetRealHalfHeight()
  local OffsetY, OffsetZ
  if BattleUtils.IsBeastTeam() or BattleUtils.IsBloodTeam() then
    local buffIconOffsetZ = 0
    if self.pet and self.pet.card and self.pet.card.config and self.pet.card.config.buff_icon_offset_z then
      buffIconOffsetZ = self.pet.card.config.buff_icon_offset_z
    end
    if 0 ~= buffIconOffsetZ then
      OffsetZ = buffIconOffsetZ
    elseif halfHeight <= 60 then
      OffsetZ = halfHeight * 5 / 9
    else
      OffsetZ = -halfHeight * 1 / 5
    end
  else
    OffsetZ = -halfHeight * 4 / 5
  end
  if realRadius >= 80 then
    OffsetY = 80
  else
    OffsetY = realRadius
  end
  local popupUIUseHalfHeight = halfHeight
  if popupUIUseHalfHeight > 75 then
    popupUIUseHalfHeight = 75
  end
  self:SetBuffBoxPos(0, OffsetY, OffsetZ)
  self:SetAreaRadius(areaRadius)
  self:SetPopupDamagePos(0, 0, popupUIUseHalfHeight * 1 / 6)
  self:SetPopupUIPos(0, 0, popupUIUseHalfHeight * 4 / 5)
  self.botton_offset_z = -20 - halfHeight
  self.buff_offset_z = math.min(-55 + OffsetZ, self.botton_offset_z)
  self:SetCatchConsumeUIPos(0, 0, self.botton_offset_z)
  self:SetCapsuleHalfHeight(capsuleHalfHeight)
  local transform = self.ResonanceUI:GetRelativeTransform()
  local translation = transform.Translation
  translation.Z = areaRadius
  transform.Translation = translation
  self.ResonanceUI:K2_SetRelativeTransform(transform, false, nil, false)
  self.DifferentColorsUI:K2_SetRelativeTransform(transform, false, nil, false)
end

function BP_BattlePetComponents_C:ShowActiveState(bShow)
  if self.ActiveFlag then
    self.ActiveFlag:SetVisibility(bShow)
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 ActiveFlag is nil!!!")
  end
end

function BP_BattlePetComponents_C:ShowOperation(bShow)
  if self.OperationIcon and UE4.UObject.IsValid(self.OperationIcon) then
    if bShow then
      self.OperationIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.OperationIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 OperationIcon is nil!!!")
  end
end

function BP_BattlePetComponents_C:ShowSelectMarker(bShow)
  if self.SelectMarker then
    self.SelectMarker:SetVisibility(bShow)
  end
end

function BP_BattlePetComponents_C:ShowSelectMarker3d(bShow)
  if self.SelectMarker3d then
    self.SelectMarker3d:SetVisibility(bShow)
  end
end

function BP_BattlePetComponents_C:ShowSelectMarker3dPC(bShow)
  if self.SelectMarker3dPC then
    self.SelectMarker3dPC:SetVisibility(bShow)
  end
end

function BP_BattlePetComponents_C:ChangeOperation(Path)
  if self.OperationIcon and UE4.UObject.IsValid(self.OperationIcon) then
    self.OperationIcon:SetPath(Path)
  end
end

function BP_BattlePetComponents_C:ShowSelectSureKeyUI(bShow)
  if self.CatchConsumeWidget then
    self.CatchConsumeWidget:ShowSelectSureKeyUI(bShow)
  end
end

function BP_BattlePetComponents_C:RefreshSelectSureKeyUI()
  if self.CatchConsumeWidget then
    self.CatchConsumeWidget:RefreshSelectSureKeyUI()
  end
end

function BP_BattlePetComponents_C:ShowClickTipUI(data)
  if self.ClickTipUIActor then
    self.ClickTipUIActor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    Log.Dump(self.ClickTipUI, 3, "BP_BattlePetComponents_C")
    self.ClickTipUIActor:SetData(data, self.pet)
  else
    Log.Error("zgx error there is no ClickTipUIActor")
  end
end

function BP_BattlePetComponents_C:HideClickTipUI()
  if self.ClickTipUIActor then
    self.ClickTipUIActor:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ClickTipUIActor.ownerPet = nil
  else
    Log.Error("zgx error there is no ClickTipUIActor")
  end
end

function BP_BattlePetComponents_C:ShowSkillPredictionUI()
  self.SkillPredictionUIActor:Show()
end

function BP_BattlePetComponents_C:HideSkillPredictionUI()
  if self.SkillPredictionUIActor and self.SkillPredictionUIActor.Hide then
    self.SkillPredictionUIActor:Hide()
  end
end

function BP_BattlePetComponents_C:UpdateSkillPredictionUI(info)
  if self.SkillPredictionUIActor then
    local data = {}
    data.info = info
    data.pet = self.pet
    local isSkillBubble = BattleUtils.IsTerritoryTrialBattle()
    data.isSkillBubble = isSkillBubble
    self.SkillPredictionUIActor:SetData(data)
  end
end

function BP_BattlePetComponents_C:ShowRestraint(skill)
  if self.CatchConsumeWidget then
    self.CatchConsumeWidget:SetEffectVisible(true)
    self.CatchConsumeWidget:ShowEffect(skill, self.pet)
  end
end

function BP_BattlePetComponents_C:HideRestraintUI()
  if self.CatchConsumeWidget and UE4.UObject.IsValid(self.CatchConsumeWidget) then
    self.CatchConsumeWidget:SetEffectVisible(false)
  end
end

function BP_BattlePetComponents_C:IsShowClickUI()
  if self.ClickTipUIActor then
    return self.ClickTipUIActor:IsVisible()
  else
    return false
  end
end

function BP_BattlePetComponents_C:PlayClickTipUI(Caller, CallBack)
  self.ClickTipUIActor:PlayClickAnim(Caller, CallBack)
end

function BP_BattlePetComponents_C:ShowCatchRate(rate)
  self.CatchRateUIActor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CatchRateUIActor:ShowRate(rate)
end

function BP_BattlePetComponents_C:HideCatchRate()
  self.CatchRateUIActor:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function BP_BattlePetComponents_C:ShowTipTime(time, operateType, params)
  if self.CatchConsumeWidget and self.CatchConsumeWidget.ShowTime then
    self.CatchConsumeWidget:SetCatchTipTimeVisible(true)
    self.CatchConsumeWidget:ShowTime(time, operateType, params)
    local buff_count = self.BuffBoxWidget:GetBuffInfos()
    if buff_count > 0 then
      self:SetCatchConsumeUIPos(0, 0, self.buff_offset_z)
    else
      self:SetCatchConsumeUIPos(0, 0, self.botton_offset_z)
    end
  else
    Log.Error("TipTime is gone")
    UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
  end
end

function BP_BattlePetComponents_C:HideTipTime()
  if self.CatchConsumeWidget and UE4.UObject.IsValid(self.CatchConsumeWidget) and not BattleUtils.IsBloodTeam() then
    self.CatchConsumeWidget:SetCatchTipTimeVisible(false)
  end
end

function BP_BattlePetComponents_C:HideBuffs()
  if self.BuffBox then
    local Widget = self.BuffBox:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
  if self.BuffBox2D then
    local Widget = self.BuffBox2D:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.isBuffShow = false
  self:SetState(nextState)
end

function BP_BattlePetComponents_C:ShowBuffs()
  if self.BuffBox then
    local Widget = self.BuffBox:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
  if self.BuffBox2D then
    local Widget = self.BuffBox2D:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.isBuffShow = true
  self:SetState(nextState)
end

function BP_BattlePetComponents_C:SetBuffsRenderOpacity(Num)
  if self.BuffBox then
    local Widget = self.BuffBox:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetRenderOpacity(Num)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
  if self.BuffBox2D then
    local Widget = self.BuffBox2D:GetUserWidgetObject()
    if Widget and Widget.HorizontalBox_26 then
      Widget.HorizontalBox_26:SetRenderOpacity(Num)
    else
      Log.Error("BuffBox is gone")
      UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
    end
  else
    Log.Error("\229\143\145\231\148\159\233\148\153\232\175\175 BuffBox is nil")
  end
end

function BP_BattlePetComponents_C:HideCatchConsume(_IsShow)
  if self.CatchConsumeWidget then
    self.CatchConsumeWidget:SetCatchConsumeVisible(_IsShow)
  else
    Log.Error("CatchConsumeUI is gone")
    UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
  end
end

function BP_BattlePetComponents_C:RefreshCatchConsumeInfo(itemType)
  self.CatchConsumeWidget:RefreshCatchConsumeInfo(itemType)
end

function BP_BattlePetComponents_C:CancelDelayShowBubbleId()
  if self.delayShowBubbleId then
    _G.DelayManager:CancelDelayById(self.delayShowBubbleId)
  end
  self.delayShowBubbleId = nil
end

function BP_BattlePetComponents_C:IsShowPetEvolutionBubbleUI(_IsShow)
  if self.PetEvolutionBubbleWidget then
    if _IsShow then
      self.PetEvolutionBubbleUI:SetVisibility(true)
      self:CancelDelayShowBubbleId()
      self.delayShowBubbleId = _G.DelayManager:DelayFrames(1, function()
        if self and UE.UObject.IsValid(self) then
          self.PetEvolutionBubbleWidget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end)
    else
      self.PetEvolutionBubbleWidget:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PetEvolutionBubbleUI:SetVisibility(false)
    end
  else
    Log.Error("PetEvolutionBubbleUI is gone")
    UE4.UNRCStatics.DumpFClassDesc("ABP_BattlePetComponents_C")
  end
end

function BP_BattlePetComponents_C:Reset()
  self:CancelDelayShowBubbleId()
  self.PopupUIFather = nil
  self.CatchConsumeWidget = nil
  self.CatchRateUIActor = nil
  self.ClickTipUIActor = nil
  self.SkillPredictionUIActor = nil
  self.BuffBoxWidget = nil
  self.BuffBox2DWidget = nil
  self.OperationIcon = nil
  self.pet = nil
  self.resonance_widget = nil
  self.DifferentColorsWidget = nil
end

function BP_BattlePetComponents_C:PreAddPopupDamageChildPanel()
  if not self.PopupUIFather or not UE4.UObject.IsValid(self.PopupUIFather) then
    return false
  end
  local widgets = self.PopupDamagePanel:GetAllChildren()
  if widgets then
    local widgetsTable = widgets:ToTable()
    if 0 == #widgetsTable then
      self.PopupDamage:SetVisibility(true)
      return true
    end
  end
  return false
end

function BP_BattlePetComponents_C:DeletePopupDamageChildPanel()
  if not self.PopupUIFather or not UE4.UObject.IsValid(self.PopupUIFather) then
    return
  end
  local widgets = self.PopupDamagePanel:GetAllChildren()
  local widgetsTable = widgets:ToTable()
  if 0 == #widgetsTable then
    self.PopupDamage:SetVisibility(false)
  end
end

function BP_BattlePetComponents_C:SetPopupWidgetVisibility(isShow)
  if not self.PopupUIFather or not UE4.UObject.IsValid(self.PopupUIFather) then
    return
  end
  local widgets = self.PopupDamagePanel:GetAllChildren()
  if widgets then
    local widgetsTable = widgets:ToTable()
    for _, umg in pairs(widgetsTable) do
      if isShow then
        umg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        umg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  self.PopupDamage:SetVisibility(false)
end

function BP_BattlePetComponents_C:GetValidPopupNormalPos(initPos)
  local LimitY = 60
  local minY = 15
  local curValueY = initPos.Y
  local curPosMap = {}
  local widgets = self.PopupUIFather:GetAllChildren()
  if widgets then
    local widgetsTable = widgets:ToTable()
    for _, umg in pairs(widgetsTable) do
      local pos1 = umg.Slot:GetPosition()
      curPosMap[pos1.Y] = true
    end
  end
  local count = 0
  while count <= 6 and curPosMap[curValueY] do
    curValueY = curValueY + minY
    initPos.X = initPos.X + 5
    goto lbl_39
    do break end
    ::lbl_39::
    if LimitY < curValueY then
      break
    end
    count = count + 1
  end
  if LimitY < curValueY then
    curValueY = math.random(15, LimitY - 5)
  end
  initPos.Y = curValueY
  return initPos
end

function BP_BattlePetComponents_C:PreAddPopupNormalChildPanel()
  if not self.PopupUIFather or not UE4.UObject.IsValid(self.PopupUIFather) then
    return false
  end
  local widgets = self.PopupUIFather:GetAllChildren()
  if widgets then
    local widgetsTable = widgets:ToTable()
    if 0 == #widgetsTable then
      self.PopupUI:SetVisibility(true)
      return true
    end
  end
  return false
end

function BP_BattlePetComponents_C:DeletePopupNormalChildPanel()
  if not self.PopupUIFather or not UE4.UObject.IsValid(self.PopupUIFather) then
    return
  end
  local widgets = self.PopupUIFather:GetAllChildren()
  local widgetsTable = widgets:ToTable()
  if 0 == #widgetsTable then
    self.PopupUI:SetVisibility(false)
  end
end

function BP_BattlePetComponents_C:PreAddBuffVisible()
  local buffCount = self.BuffBoxWidget:GetBuffInfos()
  if 0 == buffCount then
    if self.is3dBuff then
      self.BuffBox:SetVisibility(true)
    end
    self.BuffBox2D:SetVisibility(true)
    return true
  end
  return false
end

function BP_BattlePetComponents_C:AfterRemoveBuffVisible()
  if not UE.UObject.IsValid(self) then
    return
  end
  local buffCount = self.BuffBoxWidget:GetBuffInfos()
  if 0 == buffCount then
    self.BuffBox:SetVisibility(false)
    self.BuffBox2D:SetVisibility(false)
  end
end

function BP_BattlePetComponents_C:ShowResonance(skill_id)
  local player = BattleUtils.GetPlayerModel()
  if player then
    local controller = player:GetController()
    if controller and controller.PlayerCameraManager then
      local camera_location = controller.PlayerCameraManager:GetCameraLocation()
      local ui_location = self.ResonanceUI:K2_GetComponentLocation()
      local to_camera_vec = camera_location - ui_location
      to_camera_vec:Normalize()
      local look_at_rotation = UE.UKismetMathLibrary.MakeRotFromX(to_camera_vec)
      self.ResonanceUI:K2_SetWorldRotation(look_at_rotation, false, nil, false)
    end
  end
  self.resonance_widget:BindPet(self.pet)
  self.resonance_widget:Show(skill_id)
end

function BP_BattlePetComponents_C:ShowDifferentColors(isShow)
  local DifferentColorsWidget = self.DifferentColorsWidget
  if UE.UObject.IsValid(DifferentColorsWidget) then
    local props = {}
    props.isShow = isShow
    DifferentColorsWidget:SetProps(props)
  end
end

function BP_BattlePetComponents_C:SetIsDifferentColorsPet(isDifferentColorsPet)
  local _, nextState = self:GetCurrAndNextState()
  nextState.isDifferentColorsPet = isDifferentColorsPet
  self:SetState(nextState)
end

function BP_BattlePetComponents_C:OnComponentStateChanged(prevState, currState)
  local prevIsDifferentColorsPet = prevState and prevState.isDifferentColorsPet or false
  local currIsDifferentColorsPet = currState and currState.isDifferentColorsPet or false
  local prevIsBuffShow = prevState and prevState.isBuffShow or false
  local currIsBuffShow = currState and currState.isBuffShow or false
  local prevIsShowDifferentColors = prevIsDifferentColorsPet and prevIsBuffShow
  local currIsShowDifferentColors = currIsBuffShow and currIsDifferentColorsPet
  if prevIsShowDifferentColors ~= currIsShowDifferentColors then
    local isShowDifferentColors = currIsShowDifferentColors
    self:ShowDifferentColors(isShowDifferentColors)
    self:UpdateCapsuleInfo()
  end
end

function BP_BattlePetComponents_C:GetState()
  return self.state
end

function BP_BattlePetComponents_C:SetState(nextState)
  local currState = self:GetState() or {}
  self.state = nextState
  self:OnComponentStateChanged(currState, nextState)
end

function BP_BattlePetComponents_C:GetCurrAndNextState()
  local currState = self.state or {}
  local nextState = {}
  table.copy(currState, nextState)
  return currState, nextState
end

function BP_BattlePetComponents_C:IsFacingScreen()
  local player = BattleUtils.GetPlayerModel()
  if not player then
    return true
  end
  local controller = player:GetController()
  if not controller then
    return true
  end
  local camera_mgr = controller.PlayerCameraManager
  if not camera_mgr then
    return true
  end
  local camera_location = camera_mgr:GetCameraLocation()
  local actor_rotation = self:K2_GetActorRotation()
  local actor_forward_vec = actor_rotation:GetForwardVector()
  local actor_forward = UE4.FVector(actor_forward_vec.X, actor_forward_vec.Y, 0)
  actor_forward:Normalize()
  local to_camera_vec = camera_location - self:K2_GetActorLocation()
  local to_camera = UE4.FVector(to_camera_vec.X, to_camera_vec.Y, 0)
  to_camera:Normalize()
  local dot = UE.UKismetMathLibrary.Dot_VectorVector(actor_forward, to_camera)
  return dot > 0
end

return BP_BattlePetComponents_C
