require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local UMG_Ability_Slot_RideAbility_C = Base:Extend("UMG_Ability_Slot_RideAbility_C")
local CHECK_INTERVAL = 0.5
local JumpSlotPos = UE4.FVector2D(-377, -441)
local JumpSlotAlignment = UE4.FVector2D(0, 0)
local MainSlotPos = UE4.FVector2D(-309, -151)
local MainSlotAlignment = UE4.FVector2D(0.5, 0.5)

function UMG_Ability_Slot_RideAbility_C:OnConstruct()
  Base.OnConstruct(self)
  self._lastIsVisible = true
  self._curCheckInterval = CHECK_INTERVAL
  self.slotIndex = 3
  self.slotSubIndex = 3
  UE4.FCycleCounter.Create("UMG_Ability_Slot_RideAbility_C:OnPlayerStatusChanged")
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_RideAbility_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
end

function UMG_Ability_Slot_RideAbility_C:OnDestruct()
  Base.OnDestruct(self)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
end

function UMG_Ability_Slot_RideAbility_C:OnActive()
  self:ShowPetSwitch(false)
  if not self._activated then
    local caster = self.localPlayer
    if caster then
      caster.abilityComponent:AddEventListener(self, AbilityEvent.ON_BUFF_LOOP_BEGIN, self.OnLoopBegin)
      caster.abilityComponent:AddEventListener(self, AbilityEvent.ON_BUFF_LOOP_END, self.OnLoopEnd)
      caster.abilityComponent:AddEventListener(self, AbilityEvent.ON_ABILITY_CHANGED, self.RefreshView)
      caster:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.RefreshView)
    end
    self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.UpdateUi)
    self._activated = true
  end
  self:OnPlayerStatusChanged()
end

function UMG_Ability_Slot_RideAbility_C:OnDeactive()
  if self._activated then
    local caster = self.localPlayer
    if caster then
      caster.abilityComponent:RemoveEventListener(self, AbilityEvent.ON_BUFF_LOOP_BEGIN, self.OnLoopBegin)
      caster.abilityComponent:RemoveEventListener(self, AbilityEvent.ON_BUFF_LOOP_END, self.OnLoopEnd)
      caster.abilityComponent:RemoveEventListener(self, AbilityEvent.ON_ABILITY_CHANGED, self.RefreshView)
      caster:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.RefreshView)
    end
    self._activated = false
  end
end

function UMG_Ability_Slot_RideAbility_C:BindAbility(abilityHelper)
  Base.BindAbility(self, abilityHelper)
  local caster = self.localPlayer
  if self._abilityHelper then
    self._hasAbility = true
    if self._abilityHelper.GetHelper then
      self._curHelper = self._abilityHelper:GetHelper(caster)
    end
    self:RefreshView()
    _G.UpdateManager:Register(self)
  else
    self:UnbindAbility(abilityHelper)
  end
end

function UMG_Ability_Slot_RideAbility_C:UpdateUi(isAbilityAim)
  self.isAbilityAim = isAbilityAim
  self._isVisible = self._isVisible and not isAbilityAim
  local isFocus = not NRCEnv:IsLocalMode()
  if self._isVisible then
    self:BeforeSetVisible(true, isFocus)
  else
    self:BeforeSetVisible(false, isFocus)
  end
end

function UMG_Ability_Slot_RideAbility_C:UnbindAbility(abilityHelper)
  self._abilityHelper = nil
  self._hasAbility = false
  self:RefreshView()
  _G.UpdateManager:UnRegister(self)
end

function UMG_Ability_Slot_RideAbility_C:OnPlayerStatusChanged(status, value, opCode)
  local caster = self.localPlayer
  if not caster then
    return
  end
  local statusComponent = caster.statusComponent
  UE4.FCycleCounter.Start("UMG_Ability_Slot_RideAbility_C:OnPlayerStatusChanged")
  local newAbilityId = AbilityID.RIDE_ALL_MAIN
  if not self._hasAbility or self._abilityHelper.config.id ~= newAbilityId then
    local helper = AbilityHelperManager.GetHelper(newAbilityId)
    if nil ~= helper then
      if self._abilityHelper then
        local previousAbility = caster.abilityComponent:GetAbility(self._abilityHelper.config.id)
        if previousAbility and previousAbility:IsCasting() then
          previousAbility:Interrupt()
        end
      end
      self._abilityHelper = helper
      self:BindAbility(self._abilityHelper)
    end
  end
  if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    self._hasChangeEffect = status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    self:RefreshView()
  else
    self._hasChangeEffect = false
    self._isVisible = false
    self:BeforeSetVisible(false)
  end
  if not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) and (self:IsAnimationPlaying(self.Longpress_loop) or self:IsAnimationPlaying(self.Longpress_in)) then
    self:StopAnimation(self.Longpress_in)
    self:StopAnimation(self.Longpress_loop)
    self:PlayAnimation(self.Longpress_out)
  end
  UE4.FCycleCounter.Stop()
end

function UMG_Ability_Slot_RideAbility_C:RefreshView()
  if self.OnRefreshHandle then
    DelayManager:CancelDelayById(self.OnRefreshHandle)
    self.OnRefreshHandle = nil
  end
  self.OnRefreshHandle = DelayManager:DelayFrames(1, function()
    self.OnRefreshHandle = nil
    if not UE.UObject.IsValid(self) then
      return
    end
    self:InternalRefreshView()
  end)
end

function UMG_Ability_Slot_RideAbility_C:GetRelationTreePanelShow()
  if _G.RelationTreeCmd then
    return _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpeningRelationPanel)
  end
  return nil
end

function UMG_Ability_Slot_RideAbility_C:UIBan(FuncId)
  if FuncId == Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT then
    self.bInBanCondition = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow()
    self:RefreshView()
  end
end

function UMG_Ability_Slot_RideAbility_C:InternalRefreshView()
  local playChange = self._hasChangeEffect
  self._hasChangeEffect = false
  if not self._hasAbility then
    self._isVisible = false
    return
  end
  if self.isAbilityAim then
    self._isVisible = false
    return
  end
  if not self.localPlayer or not UE4.UObject.IsValid(self.localPlayer.viewObj) then
    return
  end
  local hasAim = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  if hasAim then
    self._isVisible = false
    self:BeforeSetVisible(false)
    return
  end
  local bBan = NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT)
  self._isVisible = not bBan
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO) then
    self._isVisible = false
    self:BeforeSetVisible(false)
    return
  end
  local UIBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP)
  if UIBan then
    self._isVisible = false
    self:BeforeSetVisible(false)
    return
  end
  local buff = self.localPlayer.buffComponent:GetBuff("Transform_Buff")
  local hasStatus = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
  local isInTransform = hasStatus and buff and not buff.MagicTransformConf.is_pet
  if self._isVisible ~= not isInTransform then
    self._isVisible = not isInTransform
    self:BeforeSetVisible(self._isVisible, true)
    if not self._isVisible then
      return
    end
  end
  self._isVisible = not bBan
  if self.localPlayer.viewObj.BP_RideComponent.bIsDoubleRide2p then
    self._isVisible = false
  end
  local IconPath = self:GetIcon()
  if nil ~= IconPath and "" ~= IconPath then
    self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local pressIcon = self:GetPressIcon()
    if nil ~= pressIcon and "" ~= pressIcon then
      self.Image_Bg:SetPath(pressIcon)
    end
    self.BP_UIIcon:SetPath(IconPath)
    if IconPath ~= self.oldIconPath then
      self.oldIconPath = IconPath
    end
    local activeType = self._abilityHelper:GetSkillActiveType(self.localPlayer)
    self:SetPcSlotText(activeType)
    if not self:IsPCMode() then
      local InFlyMode = false
      if activeType == Enum.SceneRideAllActiveType.SRAA_FLYUP then
        InFlyMode = true
      end
      if activeType == Enum.SceneRideAllActiveType.SRAA_CLIMBUP then
        InFlyMode = true
      end
      if activeType == Enum.SceneRideAllActiveType.SRAA_CLIMB_WATER_JUMP then
        InFlyMode = true
      end
      if not self.InFlyMode or InFlyMode ~= self.InFlyMode then
        self.InFlyMode = InFlyMode
        if InFlyMode then
          self.Slot:SetPosition(JumpSlotPos)
          self.Slot:SetAlignment(JumpSlotAlignment)
        else
          self.Slot:SetPosition(MainSlotPos)
          self.Slot:SetAlignment(MainSlotAlignment)
        end
      end
    end
  else
    if self._isVisible then
      self._hasChangeEffect = playChange
    end
    self._isVisible = false
    self:BeforeSetVisible(false, true)
    return
  end
  if self._isVisible then
    if playChange then
      self:PlayAnimation(self.Show_change)
    end
    self:BeforeSetVisible(true)
  else
    self:BeforeSetVisible(false)
  end
end

function UMG_Ability_Slot_RideAbility_C:SetPcSlotText(activeType)
  activeType = activeType or self._abilityHelper:GetSkillActiveType(self.localPlayer)
  local ia = "IA_PetRiddingSkillStart_OnPet"
  if activeType == Enum.SceneRideAllActiveType.SRAA_FLYUP then
    ia = "IA_SkyPetRiddingSkillStart_OnPet"
  end
  if SystemSettingModuleCmd then
    local pcKey = self.Text_PCKey
    if not _G.UE4Helper.IsPCMode() then
      pcKey = self.Text_PCKey
    elseif self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, ia)
    if "" ~= image then
      pcKey:SetImageMode(image)
    else
      pcKey:SetText(text)
    end
  end
end

function UMG_Ability_Slot_RideAbility_C:GetIcon()
  if self._abilityHelper then
    return self._abilityHelper:GetIcon(self.localPlayer)
  end
  return nil
end

function UMG_Ability_Slot_RideAbility_C:GetPressIcon()
  if self._abilityHelper then
    return self._abilityHelper:GetPressIcon(self.localPlayer)
  end
  return nil
end

function UMG_Ability_Slot_RideAbility_C:OnSlotPressed(bind)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(self.SoundID, "UMG_Ability_Slot_C:OnSlotPressed")
  local wasInLoopMode = self.curLoopId and -1 ~= self.curLoopId
  local errorCode = self:OnCast(true)
  if errorCode == AbilityErrorCode.NO_ERROR then
    if self:IsPCMode() then
      if self._abilityHelper.IsLongPressAbility and self._abilityHelper:IsLongPressAbility(self.localPlayer) then
        self:PlayAnimation(self.Longpress_in)
      elseif not wasInLoopMode then
        self:PlayAnimation(self.press)
      end
    elseif wasInLoopMode then
      Log.Error("[RideAbility] Already in loop mode, skip press animation")
    else
      self:PlayAnimation(self.press)
    end
  end
end

function UMG_Ability_Slot_RideAbility_C:OnSlotCanceled()
  if self:IsAnimationPlaying(self.Longpress_loop) or self:IsAnimationPlaying(self.Longpress_in) then
    self:StopAnimation(self.Longpress_in)
    self:StopAnimation(self.Longpress_loop)
    self:PlayAnimation(self.Longpress_out)
  end
end

function UMG_Ability_Slot_RideAbility_C:OnSlotReleased(bind)
  if self:IsAnimationPlaying(self.Longpress_loop) or self:IsAnimationPlaying(self.Longpress_in) then
    self:StopAnimation(self.Longpress_in)
    self:StopAnimation(self.Longpress_loop)
    self:PlayAnimation(self.Longpress_out)
  end
  if not self._hasAbility then
    return
  end
  self.localPlayer.abilityComponent:StopAbility(true, self._abilityHelper.config.id)
  self.localPlayer:SendEvent(PlayerModuleEvent.ON_MAIN_ABILITY_RELEASED)
end

function UMG_Ability_Slot_RideAbility_C:OnCast(isPress)
  if not self._hasAbility or not isPress then
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    return
  end
  local errorCode = self._abilityHelper:CanCastAbility(caster)
  if errorCode == AbilityErrorCode.NO_ERROR then
    self._abilityHelper:HandleStatus(caster)
    self.localPlayer.viewObj.WalkRun = false
  end
  if errorCode == AbilityErrorCode.VITALITY_NOT_ENOUGH and MainUIModuleCmd then
    NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnDashAbilityVitalityDeficiency)
  end
  if errorCode == AbilityErrorCode.TASK_AREA_BAN and self.localPlayer and self.localPlayer.ShowTaskAreaRideAllBanTips and isPress then
    self.localPlayer:ShowTaskAreaRideAllBanTips()
  end
  if errorCode ~= AbilityErrorCode.NO_ERROR then
    Log.Debug(AbilityErrorCode.ToString(errorCode))
  end
  return errorCode
end

function UMG_Ability_Slot_RideAbility_C:OnLoopBegin(abilityID, remainTime, reStart)
  if abilityID == self._abilityHelper.config.id then
    if reStart then
      self:PlayAnimationTimeRange(self.Anim_ProgressBar, 0, 1, 1, UE4.EUMGSequencePlayMode.Forward, 1 / remainTime)
      return
    end
    Log.Debug("UMG_Ability_Slot_RideAbility_C  Play Loop Effect AbilityID = " .. abilityID)
    self.curLoopId = abilityID
    self:StartLongPressMode()
    self.playProgressBar = false
    if remainTime and remainTime > 0 then
      self.playProgressBar = true
      self:StopAnimation(self.ProgressBar_out)
      self:PlayAnimation(self.ProgressBar_in)
      self.CanvasPanel_83:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimationTimeRange(self.Anim_ProgressBar, 0, 1, 1, UE4.EUMGSequencePlayMode.Forward, 1 / remainTime)
    end
  end
end

function UMG_Ability_Slot_RideAbility_C:OnLoopEnd(abilityID)
  if self.curLoopId == abilityID then
    Log.Debug("UMG_Ability_Slot_RideAbility_C  End Loop Effect AbilityID = " .. abilityID)
    if self.playProgressBar then
      self.playProgressBar = false
      self:StopAnimation(self.ProgressBar_in)
      self:PauseAnimation(self.Anim_ProgressBar)
      self:PlayAnimation(self.ProgressBar_out)
    end
    self:StopLongPressMode()
    self.curLoopId = -1
  else
    Log.Debug("UMG_Ability_Slot_RideAbility_C Stop id  = " .. abilityID)
  end
end

function UMG_Ability_Slot_RideAbility_C:OnTick(InDeltaTime)
  self:RefreshAbility(InDeltaTime)
end

function UMG_Ability_Slot_RideAbility_C:RefreshAbility(deltaTime)
  if self._hasAbility and self._abilityHelper.GetHelper and self.localPlayer then
    if not self._curCheckInterval then
      self._curCheckInterval = CHECK_INTERVAL
    end
    self._curCheckInterval = self._curCheckInterval - deltaTime
    if self._curCheckInterval < 0 then
      self._curCheckInterval = self._curCheckInterval + CHECK_INTERVAL
      local newHelper = self._abilityHelper:GetHelper(self.localPlayer)
      if newHelper then
        if not self._curHelper or self._curHelper.config.id ~= newHelper.config.id then
          self._curHelper = newHelper
          self:RefreshView()
        end
      elseif self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
        self:RefreshView()
      end
    end
  end
end

function UMG_Ability_Slot_RideAbility_C:StartLongPressMode()
  self:StopAnimation(self.inAnim)
  self:StopAnimation(self.outAnim)
  self:StopAnimation(self.loopAnim)
  self:PlayAnimation(self.inAnim)
end

function UMG_Ability_Slot_RideAbility_C:OnAnimationFinished(anim)
  if anim == self.inAnim then
    if self.loopAnim and not self:IsAnimationPlaying(self.loopAnim) then
      self:PlayAnimation(self.loopAnim, 0.0, 9999)
    end
  elseif anim == self.ProgressBar_out then
    self.CanvasPanel_83:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.Longpress_in and self.Longpress_loop and not self:IsAnimationPlaying(self.Longpress_loop) then
    self:PlayAnimation(self.Longpress_loop, 0.0, 9999)
  end
  Base.OnAnimationFinished(self, anim)
end

function UMG_Ability_Slot_RideAbility_C:StopLongPressMode()
  self:StopAnimation(self.inAnim)
  self:StopAnimation(self.outAnim)
  self:StopAnimation(self.loopAnim)
  self:StopAnimation(self.press)
  self:PlayAnimation(self.outAnim, 0, 1, UE4.EUMGSequencePlayMode.Forward, 0.33)
end

function UMG_Ability_Slot_RideAbility_C:PlayLoopAnim()
  self:StopAnimation(self.inAnim)
  self:StopAnimation(self.outAnim)
  self:StopAnimation(self.loopAnim)
  self:StopAnimation(self.press)
  self:PlayAnimation(self.loopAnim, 0.0, 9999)
end

function UMG_Ability_Slot_RideAbility_C:OnPCKey(action_type)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if not self.localPlayer then
    Log.Error("UMG_Ability_Slot_RideAbility_C:OnPCKey Local player is nil")
    return
  end
  if 0 == action_type then
    if _G.FriendModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    end
    self.Btn_Slot:OnPress()
    self:OnSlotPressed()
  else
    self.Btn_Slot:OnRelease()
    self:OnSlotReleased()
  end
end

function UMG_Ability_Slot_RideAbility_C:GetCanCast(isSky)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if not (self.localPlayer and self._abilityHelper) or not self._abilityHelper.GetSkillActiveType then
    return
  end
  local skillType = self._abilityHelper:GetSkillActiveType(self.localPlayer)
  if isSky then
    return skillType == Enum.SceneRideAllActiveType.SRAA_FLYUP
  end
  return skillType ~= Enum.SceneRideAllActiveType.SRAA_FLYUP
end

function UMG_Ability_Slot_RideAbility_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Ability_Slot_RideAbility_C:BeforeSetVisible(visible, isFocus)
  if not visible and self.ProgressBar_out and self:IsAnimationPlaying(self.ProgressBar_out) then
    self.CanvasPanel_83:setVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetVisible(visible, isFocus)
end

return UMG_Ability_Slot_RideAbility_C
