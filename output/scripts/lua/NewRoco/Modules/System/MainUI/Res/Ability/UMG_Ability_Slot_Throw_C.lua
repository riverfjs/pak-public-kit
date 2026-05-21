local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_Ability_Slot_Throw_C = Base:Extend("UMG_Ability_Slot_Throw_C")
local BallStateEnum = {
  CurBallHas = 0,
  CurBallEmpty = 1,
  AllBallEmpty = 3
}

function UMG_Ability_Slot_Throw_C:OnConstruct()
  Base.OnConstruct(self)
  self.ThrowItemInfo = {}
  self.ThrowItemType = -1
  self.RecycleSession = {}
  self.isInAimingState = false
  self.isEnterThrowing = false
  self.IsPress = false
  self._loopCheckEnter = false
  self.CanThrow = false
  self.GlobalBlockFlag = 0
  self.BlockGIDs = {}
  self.CurBallState = BallStateEnum.CurBallHas
  self.CanShowBallEmptyTips = true
  self._banList = {}
  local ride_pet_table = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  for _, v in pairs(ride_pet_table) do
    local throw_switch = v.throw_switch
    if throw_switch then
      self._banList[v.id] = true
    end
  end
  self._isRideThrowBlock = false
  self:OnAddEventListener()
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.localPlayer then
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_INTERRUPT_THROW, self.OnThrowInterrupt)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_Throw_C", self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  ScenePlayerInputManager.RegisterActionEvent("Alt", self, self.AltFocus)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_Throw_C", self, SceneEvent.PlayerBornFinish, self.ReBindPlayerEvents)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_THROW, self, self.RefreshView)
  UE4.FCycleCounter.Create("UMG_Ability_Slot_Throw_C:OnPlayerStatusChanged")
  _G.UpdateManager:Register(self)
  self:BindInputAction()
end

function UMG_Ability_Slot_Throw_C:OnDestruct()
  ScenePlayerInputManager.UnRegisterActionEvent("Alt", self, self.AltFocus)
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_INTERRUPT_THROW, self.OnThrowInterrupt)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
  end
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_THROW, self, self.RefreshView)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.ReBindPlayerEvents)
  _G.UpdateManager:UnRegister(self)
  self:UnBindInputAction()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
end

function UMG_Ability_Slot_Throw_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    local actions = {
      {
        name = "IA_ThrowStart",
        method = "ThrowStart"
      },
      {
        name = "IA_ThrowEnd",
        method = "ThrowEnd"
      },
      {
        name = "IA_ThrowCancel",
        method = "ThrowCancel"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
end

function UMG_Ability_Slot_Throw_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    local actions = {
      {
        name = "IA_ThrowStart"
      },
      {
        name = "IA_ThrowEnd"
      },
      {
        name = "IA_ThrowCancel"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
  end
end

function UMG_Ability_Slot_Throw_C:ThrowStart()
  if self.MouseLeftPressd or self.cancelThrow then
    return
  end
  self:OnMouseLeftKey(0)
end

function UMG_Ability_Slot_Throw_C:ThrowEnd()
  self:OnMouseLeftKey(1)
end

function UMG_Ability_Slot_Throw_C:OnLostFocus()
  self:OnMouseLeftKey(1, true)
end

function UMG_Ability_Slot_Throw_C:AltFocus(action_type)
  if 0 == action_type then
    self:OnMouseLeftKey(1, true)
  elseif 1 == action_type then
  end
end

function UMG_Ability_Slot_Throw_C:TopBlockImcChange(lastTopImc, newTopImc)
  if "IMC_MainUIDefault" == lastTopImc then
    self:OnMouseLeftKey(1, true)
  end
end

function UMG_Ability_Slot_Throw_C:ClearThrowCacheData()
  if self.IsPress then
    self.MouseLeftPressd = nil
    self.IsPress = false
    self.cancelThrow = true
    self._loopCheckEnter = false
    self:UnlockTouchLimit()
  end
end

function UMG_Ability_Slot_Throw_C:ThrowCancel(isPassiveCancel)
  if self.MouseLeftPressd then
    self.MouseLeftPressd = nil
    self.IsPress = false
    self._loopCheckEnter = false
    if not isPassiveCancel then
      self.cancelThrow = true
    end
    self:UnlockTouchLimit()
  end
end

function UMG_Ability_Slot_Throw_C:ReBindPlayerEvents()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
  end
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.localPlayer then
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
  else
    Log.Error("There is no LocalPlayer!!!")
  end
  self:RefreshView()
end

function UMG_Ability_Slot_Throw_C:BindAbility(abilityHelper)
  if self.ThrowItemType ~= _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    if self._pet then
      local recycleHelper = AbilityHelperManager.GetHelper(AbilityID.RECYCLE_THROW)
      if self._pet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
        self._abilityHelper = recycleHelper
      else
        self._abilityHelper = abilityHelper
      end
    else
      self._abilityHelper = abilityHelper
    end
  else
    local abilityID = 0
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.ThrowItemInfo.id, true)
    if not bagItemConf then
      Log.Error("BindMagicAbility BagItem is nil")
      return
    end
    local magicConf = _G.DataConfigManager:GetMagicBaseConf(bagItemConf.magic_id, true)
    if not magicConf then
      Log.Error("BindMagicAbility magicConf is nil")
      return
    end
    abilityID = magicConf.sceneability
    self.abilityID = abilityID
    self._abilityHelper = AbilityHelperManager.GetHelper(abilityID)
    if self._abilityHelper and self._abilityHelper.InitFromConf then
      self._abilityHelper:InitFromConf(self.ThrowItemInfo.id, magicConf.id, abilityID)
    end
  end
  self:RefreshView()
end

function UMG_Ability_Slot_Throw_C:RefreshView()
  if NRCEnv:IsLocalMode() then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    return
  end
  if -1 == self.ThrowItemType then
    if self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if not self.localPlayer then
    if self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_THROW) or _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_THROW)
  local isInTransform = self.localPlayer and self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
  local hide = self.ThrowItemType and self.ThrowItemType < 0 or isInTransform or bBan
  local player = self.localPlayer
  if player and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    if hide then
      if self.FoundationPCKey then
        self.FoundationPCKey:SetKeyVisibility(false)
      end
      if self.ParentPanel then
        self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      if self.FoundationPCKey then
        self.FoundationPCKey:SetKeyVisibility(true)
      end
      if self.ParentPanel then
        self.ParentPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
    self:SetVisibility(hide and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  end
  if self:IsPCMode() then
    local pcKey = self.ScrollPCKey
    if self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    pcKey:SetLeftClickMode()
    pcKey:SetKeyVisibility(true)
  else
    local pcKey = self.ScrollPCKey
    if self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    pcKey:SetKeyVisibility(false)
  end
  if not self._abilityHelper then
    self._isVisible = false
    return
  end
  self._isVisible = true
  local isBlock = self:IsBlock()
  local IconPath = self._abilityHelper:GetIcon(self.localPlayer, isBlock)
  if nil ~= IconPath and "" ~= IconPath then
    self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BP_UIIcon:SetPath(IconPath)
    local pressIcon = self._abilityHelper:GetPressIcon(self.localPlayer)
    if nil ~= pressIcon and "" ~= pressIcon then
      self.Image_Bg:SetPath(pressIcon)
    end
  else
    self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Image_Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not self.NeedPlayUnLockAnim or self._isVisible then
  end
end

function UMG_Ability_Slot_Throw_C:OnAddEventListener()
  self:RegisterEvent(self, MainUIModuleEvent.ClearThrowCacheData, self.ClearThrowCacheData)
  self:RegisterEvent(self, MainUIModuleEvent.ReThrowMagic, self.ReThrowMagic)
  self:RegisterEvent(self, MainUIModuleEvent.ReThrowEquipItem, self.ReThrowEquipItem)
  self:AddButtonListener(self.NRCButton_96, self.OnBallEmptyClick)
end

function UMG_Ability_Slot_Throw_C:OnStatusChanged(status, value, opCode)
  if not self._abilityHelper then
    return
  end
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetThrowHitTestInvisible, true, true)
  else
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetThrowHitTestInvisible, false, true)
  end
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetThrowHitTestInvisible, true, false)
  end
end

function UMG_Ability_Slot_Throw_C:OnThrowInterrupt()
  self:ThrowCancel(true)
  self.Btn_Slot:InterruptLongPress()
end

function UMG_Ability_Slot_Throw_C:OnSlotPressed(bind)
  local limit = self:CheckTouchLimit()
  if limit then
    return
  end
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:LockTouchLimit()
  self.IsPress = true
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListVisible, false)
  if self.press and not self:IsBlock() then
    self:PlayAnimation(self.press)
  end
  if self._abilityHelper.config.id == AbilityID.RECYCLE_THROW or self.localPlayer and self.localPlayer.viewObj.AimState then
    self._loopCheckEnter = true
  end
end

function UMG_Ability_Slot_Throw_C:OnSlotReleased(bind)
  if not self.IsPress then
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
    return
  end
  self.IsPress = false
  self.forbidMagicMsg = nil
  self:UnlockTouchLimit()
  if self._pet and _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") then
    local bInTaskFollow, Message = _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, self._pet.gid, 1)
    if bInTaskFollow then
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Message)
    end
  end
  if self._loopCheckEnter then
    self._loopCheckEnter = false
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
    return
  end
  self._loopCheckEnter = false
  if not self._abilityHelper then
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
    return
  end
  if GlobalConfig.TestMagicAbility or self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    if self._abilityHelper.GetBuff then
      if not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
        self:OnCastMagic()
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.CancelLockMagic)
        local buff = self._abilityHelper:GetBuff(self.localPlayer)
        if buff then
          buff:OnCastMagic()
        end
      end
    else
      Log.Error("UMG_Ability_Slot_Throw_C:OnSlotReleased, abilityHelper no Getbuff  abilityHelper id = " .. self._abilityHelper.config.id)
    end
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
    return
  end
  if self._abilityHelper.config.scene_ability_slot_cast_type == Enum.SceneAbilitySlotCastType.SASCT_PRESS then
    self.localPlayer.abilityComponent:StopAbility(false, self._abilityHelper.config.id)
  end
  if not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    self:OnCastThrowEntry(true)
    local dir = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAutoAimDirection)
    local aimNPC = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAutoAimNPC)
    local throwInfo = {
      isFast = true,
      ThrowItemType = self.ThrowItemType,
      ThrowItemInfo = self.ThrowItemInfo,
      Dir = dir,
      AutoAimNPC = aimNPC
    }
    self.localPlayer:SendEvent(PlayerModuleEvent.ON_SWITCH_THROW, throwInfo)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnSlotReleased")
  end
end

function UMG_Ability_Slot_Throw_C:OnSlotClicked(bind)
end

function UMG_Ability_Slot_Throw_C:OnCastThrowEntry(NeedErrorAudio)
  if not self._abilityHelper then
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    return
  end
  if self:IsBlock() and self._abilityHelper.config.id == AbilityID.AIM_THROW then
    if NeedErrorAudio then
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Ability_Slot_Throw_C:OnCastThrowEntry")
    end
    if self._abilityHelper:IsEnvBlock() then
      NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_ability_slot_throw_1)
    end
    return
  end
  local errorCode = self._abilityHelper:CanCastAbility(self.localPlayer)
  if errorCode == AbilityErrorCode.NO_ERROR then
    if self._abilityHelper.config.id == AbilityID.AIM_THROW then
      self.isEnterThrowing = true
      if self.localPlayer and self.localPlayer.viewObj and self.localPlayer.viewObj.BP_RideComponent then
        local rideComp = self.localPlayer.viewObj.BP_RideComponent
        local RidePet = rideComp.RidePet
        local ScenePet = rideComp.ScenePet
        if RidePet and ScenePet and ScenePet.config and self._banList[ScenePet.config.id] and RidePet.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_Walking then
          local helper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL_OFF)
          if helper then
            helper:HandleStatus(self.localPlayer, false, true)
          end
        end
      end
      local dir = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAutoAimDirection)
      local aimNPC = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAutoAimNPC)
      local throwInfo = {
        isFast = true,
        ThrowItemType = self.ThrowItemType,
        ThrowItemInfo = self.ThrowItemInfo,
        Dir = dir,
        AutoAimNPC = aimNPC
      }
      self._abilityHelper:HandleStatus(self.localPlayer, throwInfo)
      if self._abilityHelper.config.cooldown_type ~= ProtoEnum.SceneAbilityCooldownType.SCDT_FROMEND then
        self.lastCastTime = UE4.UGameplayStatics.GetAccurateRealTime(self)
      end
    elseif self._abilityHelper.config.id == AbilityID.RECYCLE_THROW then
      errorCode = self._abilityHelper:HandleStatus(self.localPlayer, self.RecycleSession)
    end
  end
end

function UMG_Ability_Slot_Throw_C:OnCastMagic()
  if not self._abilityHelper then
    self.CanThrow = false
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    self.CanThrow = false
    return
  end
  local bIsBlock, abilityErrorCode = self:IsBlock()
  if bIsBlock then
    if abilityErrorCode == AbilityErrorCode.DUNGEON_BAN then
      self:ShowTips(LuaText.TryCastMagic_WrongScene)
    elseif abilityErrorCode == AbilityErrorCode.AREA_BAN then
      self:ShowTips(LuaText.TryCastMagic_WrongScene)
    elseif abilityErrorCode == AbilityErrorCode.HOME_FORBID then
      self:ShowTips(LuaText.TryCastMagic_WrongScene)
    elseif abilityErrorCode == AbilityErrorCode.FUNC_BAN then
      self:ShowTips(LuaText.TryCastMagic_Create_LitteGame)
    elseif abilityErrorCode == AbilityErrorCode.GAME_BAN then
      self:ShowTips(LuaText.Error_Code_18320)
    elseif abilityErrorCode == AbilityErrorCode.BAG_ITEM_NOT_ENOUGH then
      if self.abilityID == AbilityID.MAGIC_VIDEO then
        self:ShowTips(LuaText.mark_video_lack_of_item)
      else
        self:ShowTips(LuaText.TryCastMagic_InsufficientMaterial)
      end
    elseif abilityErrorCode == AbilityErrorCode.VISIT_BAN then
      if self.abilityID == AbilityID.MAGIC_CREATE then
        local key = string.format("Error_Code_%d", ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_VISITOR_CANT_CREATE_MAGIC_NPC)
        self:ShowTips(LuaText[key])
      elseif self.abilityID == AbilityID.MAGIC_MESSAGE then
        local temp = _G.DataConfigManager:GetLocalizationConf("magic_message_multiplayer_fobbiden").msg
        self:ShowTips(temp)
      end
    elseif abilityErrorCode == AbilityErrorCode.SYSTEM_BAN then
      if self.abilityID == AbilityID.MAGIC_MESSAGE then
        local temp = _G.DataConfigManager:GetLocalizationConf("magic_message_ban_special_time").msg
        self:ShowTips(temp)
      end
    elseif abilityErrorCode == AbilityErrorCode.STORY_BAN then
      local temp = _G.DataConfigManager:GetLocalizationConf("magic_message_status_fobbiden").msg
      self:ShowTips(temp)
    end
    self.CanThrow = false
    return
  end
  local errorCode = self._abilityHelper:CanCastAbility(self.localPlayer)
  if errorCode == AbilityErrorCode.VITALITY_NOT_ENOUGH then
    self.CanThrow = false
    if MainUIModuleCmd then
      NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnDashAbilityVitalityDeficiency)
    end
  end
  if errorCode == AbilityErrorCode.NO_ERROR then
    self.CanThrow = true
    if not self._abilityHelper:GetBuff(self.localPlayer) then
      self._abilityHelper:HandleStatus(self.localPlayer)
    end
  end
end

function UMG_Ability_Slot_Throw_C:ShowTips(msg)
  if not msg then
    return
  end
  if self.IsPress then
    if self.forbidMagicMsg == msg then
      return
    end
    self.forbidMagicMsg = msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg, 0, nil, 5.0)
    return
  end
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg)
end

function UMG_Ability_Slot_Throw_C:OnCastBall()
  if not self._abilityHelper then
    self.CanThrow = false
    return
  end
  local caster = self.localPlayer
  if not caster.inputComponent:GetInputEnable() then
    self.CanThrow = false
    return
  end
  local bIsBlock, abilityErrorCode = self:IsBlock()
  if bIsBlock then
    if abilityErrorCode == AbilityErrorCode.DUNGEON_BAN then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.cant_cache_swim_and_fall)
    elseif abilityErrorCode == AbilityErrorCode.BAG_ITEM_NOT_ENOUGH then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.TryCastMagic_InsufficientMaterial)
    end
    self.CanThrow = false
    return
  end
  local errorCode = self._abilityHelper:CanCastAbility(self.localPlayer)
  if errorCode == AbilityErrorCode.VITALITY_NOT_ENOUGH then
    self.CanThrow = false
    if MainUIModuleCmd then
      NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnDashAbilityVitalityDeficiency)
    end
  end
  if errorCode == AbilityErrorCode.NO_ERROR then
    self.CanThrow = true
  end
end

function UMG_Ability_Slot_Throw_C:OnSlotLongPressed()
  if self._loopCheckEnter or self:IsBlock() then
    return
  end
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  if self._abilityHelper and self._abilityHelper.config.id == AbilityID.RECYCLE_THROW then
    return
  end
  self:TryEnterAimMode()
end

function UMG_Ability_Slot_Throw_C:TryEnterAimMode()
  if not self.MouseLeftPressd and self:IsPCMode() then
    return false
  end
  if not self.IsPress then
    return false
  end
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not self.localPlayer then
    return false
  end
  local CurrentVitra = self.localPlayer.vitalityComponent:GetCurVitality()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetCurrentVitra, CurrentVitra)
  if GlobalConfig.TestMagicAbility or self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    if self._abilityHelper.GetBuff then
      local buff = self._abilityHelper:GetBuff(self.localPlayer)
      if not buff then
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.InitHUDSimpleList, ProtoEnum.BagItemType.BI_MAGIC)
        self:OnCastMagic()
        if self.CanThrow then
          _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 1)
        end
        buff = self._abilityHelper:GetBuff(self.localPlayer)
        if buff then
          buff:SwitchAimState(true)
        end
      end
    else
      Log.Error("UMG_Ability_Slot_Throw_C:OnSlotReleased, abilityHelper no Getbuff  abilityHelper id = " .. self._abilityHelper.config.id)
    end
    return self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  elseif self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    self:OnCastBall()
    if self.CanThrow then
      _G.NRCModeManager:DoCmd(MainUIModuleCmd.InitBallList, ProtoEnum.BagItemType.BI_PET_BALL)
      _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 2)
    end
  end
  self:OnCastThrowEntry()
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    self:OnThrowCast()
  end
  local success = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING)
  if success and self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.PET then
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 3)
  end
  return success
end

function UMG_Ability_Slot_Throw_C:ReThrowMagic()
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CurrentVitra = self.localPlayer.vitalityComponent:GetCurVitality()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetCurrentVitra, CurrentVitra)
  local itemId = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedItemId)
  local bagItemConf
  if 0 ~= itemId then
    bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
  end
  if not bagItemConf then
    Log.Error("bagItemConf is nil")
    return
  end
  local abilityID = 0
  local magicConf = _G.DataConfigManager:GetMagicBaseConf(bagItemConf.magic_id, true)
  if not magicConf then
    Log.Error("BindMagicAbility magicConf is nil")
    return
  end
  abilityID = magicConf.sceneability
  self._abilityHelper = AbilityHelperManager.GetHelper(abilityID)
  if GlobalConfig.TestMagicAbility or self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    if self._abilityHelper.GetBuff then
      local buff = self._abilityHelper:GetBuff(self.localPlayer)
      if not buff then
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.InitHUDSimpleList, ProtoEnum.BagItemType.BI_MAGIC)
        self:OnCastMagic()
        if self.CanThrow then
          _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 1)
        end
      end
    else
      Log.Error("UMG_Ability_Slot_Throw_C:OnSlotReleased, abilityHelper no Getbuff  abilityHelper id = " .. self._abilityHelper.config.id)
    end
    return
  end
  self:OnCastThrowEntry()
  self:OnThrowCast()
end

function UMG_Ability_Slot_Throw_C:OnSlotLongPressReleased()
end

function UMG_Ability_Slot_Throw_C:SetPetSwitchShow(itemType, itemInfo, recycleState, session)
  local isBall = itemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM
  if table.isEmpty(itemInfo) and not isBall then
    return
  end
  local isThrowBallBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
  if isBall and isThrowBallBan then
    return
  end
  self.Petswitch:SetIcon(itemType, itemInfo)
  self.ThrowItemType = itemType
  self.ThrowItemInfo = itemInfo
  self.RecycleSession = session
  if itemType ~= _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    self:ChangeBallState()
  elseif itemInfo and itemInfo.id then
    if itemInfo.num > 0 then
      self:ChangeBallState(true, false)
    else
      self:ChangeBallState(true, true)
    end
  else
    self:ChangeBallState(false)
  end
  if self._pet and (itemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM or itemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC or self.localPlayer:GetPetByGid(itemInfo.gid) ~= self._pet) then
    self._pet:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
    self._pet:RemoveEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
    self._isBlock = false
    self._pet = nil
  end
  if not self._pet and itemType == _G.MainUIModuleEnum.MainUIChooseType.PET then
    self._pet = self.localPlayer:GetPetByGid(itemInfo.gid)
    if self._pet then
      self._pet:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
      self._pet:AddEventListener(self, PlayerModuleEvent.ON_THROW_RECYCLE_ENABLE_FORCE_SWITCH, self.RefreshView)
      self:OnPetStatusChanged(nil, nil, self._pet)
    end
  end
  if itemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
  end
  self:RefreshView()
end

function UMG_Ability_Slot_Throw_C:OnPetStatusChanged(status, value, pet)
  if pet and self._pet == pet then
    local recycleHelper = AbilityHelperManager.GetHelper(AbilityID.RECYCLE_THROW)
    local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
    if pet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
      self:BindAbility(recycleHelper)
    end
    if pet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_FRIENDRIDING then
      self:BindAbility(recycleHelper)
    end
    if pet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG then
      self:BindAbility(throwHelper)
    end
    local isBlock = pet:GetStatus() ~= ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG
    if self._abilityHelper.config.id == AbilityID.RECYCLE_THROW then
      isBlock = pet:GetStatus() ~= ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_SCENE and pet:GetStatus() ~= ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE
    end
    if self._isBlock ~= isBlock then
      self._isBlock = isBlock
      self:RefreshView()
    end
  end
end

function UMG_Ability_Slot_Throw_C:IsBlock()
  local abilityErrorCode
  if self._abilityHelper then
    local abilityIsBlock, _abilityErrorCode = self._abilityHelper:IsBlock(self.localPlayer, self._pet)
    abilityErrorCode = _abilityErrorCode
    if self._isAbilityBlock ~= abilityIsBlock then
      self._isAbilityBlock = abilityIsBlock
    end
  end
  if self.RecycleSession and self.RecycleSession.canBeRecycle ~= nil and self.RecycleSession.canBeRecycle == self._isBlock then
    self._isBlock = not self.RecycleSession.canBeRecycle
  end
  if self.localPlayer and self.localPlayer.viewObj and self.localPlayer.viewObj.BP_RideComponent then
    local rideComp = self.localPlayer.viewObj.BP_RideComponent
    local RidePet = rideComp.RidePet
    local ScenePet = rideComp.ScenePet
    if rideComp.bIsDoubleRide2p then
      self._isRideThrowBlock = true
    elseif nil == RidePet or nil == ScenePet then
      self._isRideThrowBlock = false
    elseif ScenePet.config and self._banList and nil ~= self._banList[ScenePet.config.id] then
      self._isRideThrowBlock = RidePet.CharacterMovement.MovementMode ~= UE.EMovementMode.MOVE_Walking
    else
      self._isRideThrowBlock = false
    end
  end
  local BlockFlag = 0 ~= self.GlobalBlockFlag or table.containsKey(self.BlockGIDs, self._pet and self._pet.gid or -1)
  local isThrowBallEmpty = false
  if self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    local EquipItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
    if not (EquipItem and EquipItem.num) or EquipItem.num <= 0 then
      local hasBall = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckHadUseBall)
      if not hasBall then
        isThrowBallEmpty = true
      end
    end
  end
  return self._isBlock or self._isAbilityBlock or self._isRideThrowBlock or BlockFlag or isThrowBallEmpty, abilityErrorCode
end

function UMG_Ability_Slot_Throw_C:OnThrowCast()
  self.isInAimingState = true
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ShowAutoLockIcon, false)
  local dir = 0
  local throwInfo = {
    isFast = false,
    ThrowItemType = self.ThrowItemType,
    ThrowItemInfo = self.ThrowItemInfo,
    Dir = dir,
    AutoAimNPC = nil
  }
  self.localPlayer:SendEvent(PlayerModuleEvent.ON_SWITCH_THROW, throwInfo)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, true)
  self.isEnterThrowing = false
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK_CHECK, true)
end

function UMG_Ability_Slot_Throw_C:OnPlayerStatusChanged(status, oldSubStatus, opCode, success, ...)
  UE4.FCycleCounter.Start("UMG_Ability_Slot_Throw_C:OnPlayerStatusChanged")
  if not self._abilityHelper then
    UE4.FCycleCounter.Stop()
    return
  end
  local isNowBlocked = self._abilityHelper:IsBlock(self.localPlayer)
  local isCorrect = false
  if status == ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING and not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    isCorrect = true
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_MAGIC and not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    isCorrect = true
  end
  if isCorrect then
    if not self.IsChangeMagicLimit then
      self:SwitchListToPet(success)
    else
      self.IsChangeMagicLimit = false
    end
  end
  if isNowBlocked ~= self._isAbilityBlock then
    self._isAbilityBlock = isNowBlocked
  end
  self:RefreshView()
  UE4.FCycleCounter.Stop()
end

function UMG_Ability_Slot_Throw_C:SwitchListToPet(success)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0, success)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
end

function UMG_Ability_Slot_Throw_C:OnTick(InDeltaTime)
  if not self.localPlayer then
    return
  end
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if self._tickTime == nil then
    self._tickTime = 0
  end
  self._tickTime = self._tickTime + InDeltaTime
  if self._tickTime > 0.5 then
    self._tickTime = 0
    self:RefreshView()
  end
  if self._loopCheckEnter then
    if not self.MouseLeftPressd and self:IsPCMode() then
      self._loopCheckEnter = false
    elseif not self.IsPress then
      self._loopCheckEnter = false
    end
  end
  if self._loopCheckEnter then
    if nil == self._loopCheckEnterTickTime then
      self._loopCheckEnterTickTime = 0.2
    end
    self._loopCheckEnterTickTime = self._loopCheckEnterTickTime + InDeltaTime
    if self._loopCheckEnterTickTime > 0.15 then
      self._loopCheckEnterTickTime = 0
      if self._abilityHelper.config.id == AbilityID.RECYCLE_THROW then
        if not self:IsBlock() then
          self:OnCastThrowEntry()
        end
      elseif self:TryEnterAimMode() then
        self._loopCheckEnter = false
      end
    end
  else
    self._loopCheckEnterTickTime = 0.2
  end
end

function UMG_Ability_Slot_Throw_C:OnMouseLeftKey(action_type, lostFocus)
  local isThrowItem = self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM
  if isThrowItem and self.CurBallState == BallStateEnum.AllBallEmpty then
    return
  end
  if 1 == action_type then
    if not self.MouseLeftPressd then
      self.cancelThrow = nil
      return
    end
  elseif self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_THROW)
  if bBan then
    Log.Error("UMG_Ability_Slot_Throw_C:OnMouseLeftKey PlayerFunctionBanType.PFBT_THROW is TRUE")
    return
  end
  if not self.localPlayer then
    Log.Error("UMG_Ability_Slot_Throw_C:OnMouseLeftKey Local player is nil")
    return
  end
  if self.localPlayer:GetUEController().bShowMouseCursor and not lostFocus then
    return
  end
  if isThrowItem and self.CurBallState == BallStateEnum.CurBallEmpty then
    if 0 == action_type then
      self:OnBallEmptyClick()
    end
    return
  end
  if 0 == action_type then
    if _G.FriendModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    end
    self.MouseLeftPressd = true
    self.Btn_Slot:OnPress()
    self:OnSlotPressed()
  else
    self.Btn_Slot:OnRelease()
    if self.MouseLeftPressd then
      self:OnSlotReleased()
      self.MouseLeftPressd = nil
    end
  end
end

function UMG_Ability_Slot_Throw_C:OpenOrCloseThrowIntPut(state)
end

function UMG_Ability_Slot_Throw_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Ability_Slot_Throw_C:CheckTouchLimit()
  local limit1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.IsSpecialSelectLimit, "SelectLimit1")
  local limit2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
  if limit1 or limit2 then
    return true
  end
  return false
end

function UMG_Ability_Slot_Throw_C:LockTouchLimit()
  local reason1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetSpecialSelectLimitReason, "SelectLimit1")
  if reason1 then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.SetSpecialSelectLimit, "SelectLimit1", reason1.THROW, true)
  end
  local reason2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").THROW
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", reason2)
end

function UMG_Ability_Slot_Throw_C:UnlockTouchLimit()
  local reason1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetSpecialSelectLimitReason, "SelectLimit1")
  if reason1 then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.SetSpecialSelectLimit, "SelectLimit1", reason1.THROW, false)
  end
  local reason2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").THROW
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", reason2)
end

function UMG_Ability_Slot_Throw_C:SetVisibility(InVisibility)
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_THROW)
  local isInTransform = false
  if self.localPlayer then
    isInTransform = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
  end
  local hide = isInTransform or bBan
  InVisibility = hide and UE4.ESlateVisibility.Collapsed or InVisibility
  self.Overridden.SetVisibility(self, InVisibility)
end

function UMG_Ability_Slot_Throw_C:ReThrowEquipItem()
  self.localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CurrentVitra = self.localPlayer.vitalityComponent:GetCurVitality()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetCurrentVitra, CurrentVitra)
  if self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.InitBallList, ProtoEnum.BagItemType.BI_PET_BALL)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 2)
  end
  if self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.PET then
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 3)
  end
  self:OnCastThrowEntry()
  self:OnThrowCast()
end

function UMG_Ability_Slot_Throw_C:SetBlockForReason(bBlock, Reason)
  Reason = Reason or _G.MainUIModuleEnum.AbilityBtnBlockReason.Any
  if bBlock then
    self.GlobalBlockFlag = self.GlobalBlockFlag | 1 << Reason
  else
    self.GlobalBlockFlag = self.GlobalBlockFlag & ~(1 << Reason)
  end
  self:RefreshView()
end

function UMG_Ability_Slot_Throw_C:SetPetThrowBlockForReason(bBlock, Gid, Reason)
  Reason = Reason or _G.MainUIModuleEnum.AbilityBtnBlockReason.Any
  if not self.BlockGIDs then
    self.BlockGIDs = {}
  end
  if bBlock then
    self.BlockGIDs[Gid] = (self.BlockGIDs[Gid] or 0) | 1 << Reason
  else
    if not self.BlockGIDs[Gid] then
      return
    end
    self.BlockGIDs[Gid] = self.BlockGIDs[Gid] & ~(1 << Reason)
    if 0 == self.BlockGIDs[Gid] then
      self.BlockGIDs[Gid] = nil
    end
  end
  self:RefreshView()
end

function UMG_Ability_Slot_Throw_C:ChangeBallState(isShow, isEmpty)
  if self.ThrowItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    if isShow then
      self.NRCImage_77:SetVisibility(UE4.ESlateVisibility.Visible)
      if isEmpty then
        self.CurBallState = BallStateEnum.CurBallEmpty
        self.NRCButton_96:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Btn_Slot:SetIsEnabled(false)
        self.Kong:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Petswitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.CurBallState = BallStateEnum.CurBallHas
        self.NRCButton_96:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_Slot:SetIsEnabled(true)
        self.Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Petswitch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      self.CurBallState = BallStateEnum.AllBallEmpty
      self.NRCButton_96:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage_77:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Petswitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Btn_Slot:SetIsEnabled(true)
    self.NRCButton_96:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_77:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Petswitch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Ability_Slot_Throw_C:OnBallEmptyClick()
  if self.CanShowBallEmptyTips then
    self.CanShowBallEmptyTips = false
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.cant_cache_no_ball_type, nil, nil, 2)
    self.DelayHandle = _G.DelayManager:DelaySeconds(2.0, function()
      self.CanShowBallEmptyTips = true
    end, self)
  end
end

function UMG_Ability_Slot_Throw_C:OnChangeMagicLimit()
  self.IsChangeMagicLimit = true
end

return UMG_Ability_Slot_Throw_C
